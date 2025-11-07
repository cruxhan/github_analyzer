import 'package:crypto/crypto.dart';
import 'package:universal_io/io.dart';
import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/common/language_info.dart';

class FileChange {
  final List<String> added;
  final List<String> modified;
  final List<String> deleted;

  FileChange({
    required this.added,
    required this.modified,
    required this.deleted,
  });

  bool get isEmpty => added.isEmpty && modified.isEmpty && deleted.isEmpty;

  int get length => added.length + modified.length + deleted.length;
}

class IncrementalAnalyzer {
  final GithubAnalyzerConfig config;
  final CacheService? cacheService;

  IncrementalAnalyzer({required this.config, this.cacheService});

  Future<AnalysisResult> analyze(
    String directoryPath, {
    required AnalysisResult previousResult,
  }) async {
    logger.info('Starting incremental analysis: $directoryPath');
    final changes = await _detectChanges(directoryPath, previousResult);

    if (changes.isEmpty) {
      logger.info('No changes detected, returning previous result');
      return previousResult;
    }

    logger.info('Changes detected: ${changes.length} files');
    logger.fine(
      'Added: ${changes.added.length}, Modified: ${changes.modified.length}, Deleted: ${changes.deleted.length}',
    );

    return await _analyzeChanges(directoryPath, previousResult, changes);
  }

  Future<AnalysisResult> analyzeWithCache(
    String directoryPath, {
    required AnalysisResult previousResult,
  }) async {
    if (cacheService == null || !config.enableFileCache) {
      return analyze(directoryPath, previousResult: previousResult);
    }

    logger.info('Starting incremental analysis with file-level cache');
    final changes = await _detectChanges(directoryPath, previousResult);

    if (changes.isEmpty) {
      logger.info('No changes detected, returning previous result');
      return previousResult;
    }

    return await _analyzeChangesWithCache(
      directoryPath,
      previousResult,
      changes,
    );
  }

  Future<AnalysisResult> _analyzeChangesWithCache(
    String directoryPath,
    AnalysisResult previousResult,
    FileChange changes,
  ) async {
    if (!cacheService!.isInitialized) {
      await cacheService!.initialize();
    }
    final fileMap = <String, SourceFile>{
      for (var f in previousResult.files) f.path: f,
    };

    final fileHashes = <String, String>{};
    for (final changedPath in [...changes.added, ...changes.modified]) {
      final file = File(path.join(directoryPath, changedPath));
      if (await file.exists()) {
        final content = await file.readAsBytes();
        final hash = sha256.convert(content).toString();
        fileHashes[changedPath] = hash;
      }
    }

    final cachedFiles = await cacheService!.batchGetFiles(fileHashes);
    logger.info('Loaded ${cachedFiles.length} files from cache');

    final filesToAnalyze = <String>[];
    for (final changedPath in [...changes.added, ...changes.modified]) {
      if (!cachedFiles.containsKey(changedPath)) {
        filesToAnalyze.add(changedPath);
      } else {
        fileMap[changedPath] = cachedFiles[changedPath]!;
      }
    }

    final newlyAnalyzed = <String, SourceFile>{};
    for (final changedPath in filesToAnalyze) {
      final file = File(path.join(directoryPath, changedPath));
      if (!await file.exists()) continue;

      try {
        final analyzed = await _analyzeFile(file, changedPath);
        if (analyzed != null) {
          fileMap[changedPath] = analyzed;
          newlyAnalyzed[changedPath] = analyzed;
        }
      } catch (e, stackTrace) {
        logger.warning('Failed to analyze file $changedPath', e, stackTrace);
      }
    }

    if (newlyAnalyzed.isNotEmpty) {
      final hashesForNewFiles = <String, String>{};
      for (final entry in newlyAnalyzed.entries) {
        if (fileHashes.containsKey(entry.key)) {
          hashesForNewFiles[entry.key] = fileHashes[entry.key]!;
        }
      }
      await cacheService!.batchSetFiles(hashesForNewFiles, newlyAnalyzed);
    }

    for (final deletedPath in changes.deleted) {
      fileMap.remove(deletedPath);
    }

    final allFiles = fileMap.values.toList();
    final statistics = AnalysisStatistics.fromSourceFiles(allFiles);
    final primaryLanguage = _getPrimaryLanguage(statistics);

    final updatedMetadata = previousResult.metadata.copyWith(
      language: primaryLanguage,
      languages: statistics.languageDistribution.keys.toList(),
      fileCount: allFiles.length,
    );

    return AnalysisResult(
      metadata: updatedMetadata,
      files: allFiles,
      statistics: statistics,
      mainFiles: identifyMainFiles(allFiles),
      dependencies: extractDependencies(allFiles),
      errors: previousResult.errors,
    );
  }

  Future<AnalysisResult> _analyzeChanges(
    String directoryPath,
    AnalysisResult previousResult,
    FileChange changes,
  ) async {
    final fileMap = <String, SourceFile>{
      for (var f in previousResult.files) f.path: f,
    };

    for (final changedPath in [...changes.added, ...changes.modified]) {
      final file = File(path.join(directoryPath, changedPath));
      if (!await file.exists()) continue;

      try {
        final analyzed = await _analyzeFile(file, changedPath);
        if (analyzed != null) {
          fileMap[changedPath] = analyzed;
        }
      } catch (e, stackTrace) {
        logger.warning('Failed to analyze file $changedPath', e, stackTrace);
      }
    }

    for (final deletedPath in changes.deleted) {
      fileMap.remove(deletedPath);
    }

    final allFiles = fileMap.values.toList();
    final statistics = AnalysisStatistics.fromSourceFiles(allFiles);
    final primaryLanguage = _getPrimaryLanguage(statistics);

    final updatedMetadata = previousResult.metadata.copyWith(
      language: primaryLanguage,
      languages: statistics.languageDistribution.keys.toList(),
      fileCount: allFiles.length,
    );

    return AnalysisResult(
      metadata: updatedMetadata,
      files: allFiles,
      statistics: statistics,
      mainFiles: identifyMainFiles(allFiles),
      dependencies: extractDependencies(allFiles),
      errors: previousResult.errors,
    );
  }

  Future<SourceFile?> _analyzeFile(File file, String relativePath) async {
    final stat = await file.stat();
    if (stat.size > config.maxFileSize) {
      logger.finer('Skipping large file in incremental scan: $relativePath');
      return null;
    }

    final isBinary = isBinaryFile(relativePath);
    String? content;
    int lineCount = 0;

    if (!isBinary) {
      try {
        content = await file.readAsString();
        lineCount = content.split('\n').length;
      } catch (e) {
        logger.finer(
          'Failed to read file as text in incremental scan: $relativePath, error: $e',
        );
        return SourceFile(
          path: relativePath,
          content: null,
          size: stat.size,
          language: null,
          isBinary: true,
          lineCount: 0,
          isSourceCode: false,
          isConfiguration: isConfigurationFile(relativePath),
          isDocumentation: isDocumentationFile(relativePath),
          timestamp: stat.modified,
        );
      }
    }

    final language = detectLanguage(relativePath);
    return SourceFile(
      path: relativePath,
      content: content,
      size: stat.size,
      language: language,
      isBinary: isBinary,
      lineCount: lineCount,
      isSourceCode: language != null && !isBinary,
      isConfiguration: isConfigurationFile(relativePath),
      isDocumentation: isDocumentationFile(relativePath),
      timestamp: stat.modified,
    );
  }

  Future<FileChange> _detectChanges(
    String directoryPath,
    AnalysisResult previousResult,
  ) async {
    final added = <String>[];
    final modified = <String>[];
    final dir = Directory(directoryPath);

    if (!await dir.exists()) {
      throw Exception('Directory not found: $directoryPath');
    }

    final previousFilesMap = <String, SourceFile>{
      for (var f in previousResult.files) f.path: f,
    };

    final currentFilePaths = <String>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: directoryPath);
        if (shouldExclude(relativePath, config.effectiveExcludePatterns)) {
          continue;
        }

        currentFilePaths.add(relativePath);
        final previousFile = previousFilesMap[relativePath];
        final stat = await entity.stat();

        if (previousFile == null) {
          added.add(relativePath);
        } else if (stat.modified.isAfter(previousFile.timestamp) ||
            stat.size != previousFile.size) {
          modified.add(relativePath);
        }
      }
    }

    final deleted = previousFilesMap.keys
        .toSet()
        .difference(currentFilePaths.toSet())
        .toList();

    return FileChange(added: added, modified: modified, deleted: deleted);
  }

  String? _getPrimaryLanguage(AnalysisStatistics statistics) {
    if (statistics.languageDistribution.isEmpty) {
      return null;
    }

    return statistics.languageDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
