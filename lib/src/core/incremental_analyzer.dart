import 'package:universal_io/io.dart';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/language_info.dart';

/// Represents the changes detected between two analysis runs
class FileChange {
  final List<String> added;
  final List<String> modified;
  final List<String> deleted;

  FileChange({
    required this.added,
    required this.modified,
    required this.deleted,
  });

  /// Returns true if no changes were detected
  bool get isEmpty => added.isEmpty && modified.isEmpty && deleted.isEmpty;

  /// Total number of changed files
  int get length => added.length + modified.length + deleted.length;
}

/// Performs incremental analysis by comparing current state with previous result
class IncrementalAnalyzer {
  final GithubAnalyzerConfig config;

  IncrementalAnalyzer({required this.config});

  /// Analyzes a local directory based on previous analysis result
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

  /// Analyzes only the changed files and merges with previous result
  Future<AnalysisResult> _analyzeChanges(
    String directoryPath,
    AnalysisResult previousResult,
    FileChange changes,
  ) async {
    final fileMap = <String, SourceFile>{
      for (var f in previousResult.files) f.path: f,
    };

    // Process added and modified files
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

    // Remove deleted files
    for (final deletedPath in changes.deleted) {
      fileMap.remove(deletedPath);
    }

    final allFiles = fileMap.values.toList();
    final statistics = AnalysisStatistics.fromSourceFiles(allFiles);

    final primaryLanguage = statistics.languageDistribution.isEmpty
        ? null
        : statistics.languageDistribution.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

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

  /// Analyzes a single file and returns SourceFile model
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
        // Treat as binary if reading fails
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

  /// Detects changes between current directory state and previous result
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

        if (shouldExclude(relativePath, config.excludePatterns)) {
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

    return FileChange(
      added: added,
      modified: modified,
      deleted: deleted,
    );
  }
}
