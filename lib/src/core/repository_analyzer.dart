import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/language_info.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/models/analysis_error.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:path/path.dart' as path;

/// Analyzes the repository files from a local directory or a memory archive.
class RepositoryAnalyzer {
  final GithubAnalyzerConfig config;
  final IsolatePool? isolatePool;
  final List<AnalysisError> errors = [];

  /// Creates an instance of [RepositoryAnalyzer].
  RepositoryAnalyzer({
    required this.config,
    this.isolatePool,
  });

  /// Analyzes a directory recursively to extract source files.
  Future<List<SourceFile>> analyzeDirectory(String directoryPath) async {
    logger.info('Analyzing directory: $directoryPath');

    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      throw AnalyzerException(
        'Directory not found: $directoryPath',
        code: AnalyzerErrorCode.directoryNotFound,
      );
    }

    final fileEntities = <File>[];
    try {
      final entities = dir.list(recursive: true);
      await for (final entity in entities) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: directoryPath);
          if (shouldExclude(relativePath, config.excludePatterns)) {
            logger.finer('Excluded by pattern: $relativePath');
            continue;
          }
          fileEntities.add(entity);
        }
      }
    } catch (e, stackTrace) {
      logger.severe('Error listing directory contents.', e, stackTrace);
    }

    final files = await _processFiles(fileEntities, directoryPath);

    logger.info(
      'Analysis completed: ${files.length} files, ${errors.length} errors',
    );
    return files;
  }

  /// Analyzes an in-memory archive to extract source files.
  Future<List<SourceFile>> analyzeArchive(Archive archive) async {
    logger.info('Analyzing archive from memory...');
    final files = <SourceFile>[];
    String? baseDir;

    if (archive.isNotEmpty && archive.first.name.contains('/')) {
      baseDir = archive.first.name.split('/').first;
    }

    // IsolatePool can't be used here easily because ArchiveFile is not directly sendable.
    // We'll process it sequentially for now.
    final archiveFiles = archive.where((f) => f.isFile).toList();

    for (final file in archiveFiles) {
      final relativePath =
          (baseDir != null && file.name.startsWith('$baseDir/'))
              ? file.name.substring(baseDir.length + 1)
              : file.name;

      if (relativePath.isEmpty ||
          shouldExclude(relativePath, config.excludePatterns)) {
        logger.finer('Excluded by pattern: $relativePath');
        continue;
      }

      try {
        final sourceFile = await _analyzeArchiveFile(
          file,
          relativePath,
          config.maxFileSize,
        );
        if (sourceFile != null) {
          files.add(sourceFile);
        }
      } catch (e, stackTrace) {
        logger.warning(
            'Failed to analyze archive file ${file.name}', e, stackTrace);
        errors.add(
          AnalysisError(
            path: relativePath,
            message: e.toString(),
            stackTrace: stackTrace.toString(),
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    logger.info(
      'Archive analysis completed: ${files.length} files, ${errors.length} errors',
    );
    return files;
  }

  /// Processes a list of file entities, using isolates if available.
  Future<List<SourceFile>> _processFiles(
    List<File> fileEntities,
    String basePath,
  ) async {
    if (isolatePool != null && fileEntities.length > 50) {
      // Using IsolatePool for a larger number of files
      logger.info(
        'Using isolate pool for parallel analysis of ${fileEntities.length} files.',
      );

      final fileDataForIsolates = fileEntities.map((file) {
        return {
          'filePath': file.path,
          'basePath': basePath,
          'maxFileSize': config.maxFileSize,
        };
      }).toList();

      final results = await isolatePool!.executeAll(
        _analyzeFileInIsolate,
        fileDataForIsolates,
      );

      final files = <SourceFile>[];
      for (var result in results) {
        if (result is SourceFile) {
          files.add(result);
        } else if (result is Map<String, String>) {
          errors.add(
            AnalysisError(
              path: result['path']!,
              message: result['error']!,
              stackTrace: result['stackTrace'],
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      return files;
    } else {
      return _analyzeFilesSequentially(fileEntities, basePath);
    }
  }

  /// Analyzes a list of files sequentially.
  Future<List<SourceFile>> _analyzeFilesSequentially(
    List<File> fileEntities,
    String basePath,
  ) async {
    final files = <SourceFile>[];
    for (final entity in fileEntities) {
      final relativePath = path.relative(entity.path, from: basePath);
      try {
        final sourceFile = await _analyzeFile(
          entity,
          relativePath,
          config.maxFileSize,
        );
        if (sourceFile != null) {
          files.add(sourceFile);
        }
      } catch (e, stackTrace) {
        logger.warning('Failed to analyze file ${entity.path}', e, stackTrace);
        errors.add(
          AnalysisError(
            path: relativePath,
            message: e.toString(),
            stackTrace: stackTrace.toString(),
            timestamp: DateTime.now(),
          ),
        );
      }
    }
    return files;
  }

  /// Static entry point for isolate execution.
  static Future<dynamic> _analyzeFileInIsolate(
    Map<String, dynamic> args,
  ) async {
    final String filePath = args['filePath'];
    final String basePath = args['basePath'];
    final int maxFileSize = args['maxFileSize'];
    final File file = File(filePath);

    final relativePath = path.relative(filePath, from: basePath);

    try {
      final stat = await file.stat();
      if (stat.size > maxFileSize) {
        return null; // Skip large files
      }

      final isBinary = isBinaryFile(relativePath);
      String? content;
      int lineCount = 0;
      if (!isBinary) {
        try {
          content = await file.readAsString();
          lineCount = content.split('\n').length;
        } catch (e) {
          // Not a text file, treat as binary
          return _createFileModelFromData(
            relativePath,
            stat.size,
            null,
            true,
            0,
            stat.modified,
          );
        }
      }
      return _createFileModelFromData(
        relativePath,
        stat.size,
        content,
        isBinary,
        lineCount,
        stat.modified,
      );
    } catch (e, stackTrace) {
      return {
        'path': relativePath,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
    }
  }

  /// Analyzes a single `ArchiveFile`.
  Future<SourceFile?> _analyzeArchiveFile(
    ArchiveFile file,
    String relativePath,
    int maxFileSize,
  ) async {
    if (file.size > maxFileSize) {
      logger.finer('Excluded large file: $relativePath');
      return null;
    }

    final isBinary = isBinaryFile(relativePath);
    String? content;
    int lineCount = 0;
    final timestamp =
        DateTime.now(); // Archive files don't have a reliable modified time

    if (!isBinary) {
      try {
        content = utf8.decode(file.content as List<int>, allowMalformed: true);
        lineCount = content.split('\n').length;
      } catch (e) {
        logger.finer('Failed to read archive file as text $relativePath: $e');
        // Treat as binary if decoding fails
        return _createFileModel(
          relativePath,
          file.size,
          null,
          true,
          0,
          timestamp,
        );
      }
    }

    return _createFileModel(
      relativePath,
      file.size,
      content,
      isBinary,
      lineCount,
      timestamp,
    );
  }

  /// Analyzes a single `File`.
  Future<SourceFile?> _analyzeFile(
    File file,
    String relativePath,
    int maxFileSize,
  ) async {
    final stat = await file.stat();
    if (stat.size > maxFileSize) {
      logger.finer('Excluded large file: $relativePath');
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
        logger.finer('Failed to read file as text $relativePath: $e');
        // Treat as binary if decoding fails
        return _createFileModel(
          relativePath,
          stat.size,
          null,
          true,
          0,
          stat.modified,
        );
      }
    }
    return _createFileModel(
      relativePath,
      stat.size,
      content,
      isBinary,
      lineCount,
      stat.modified,
    );
  }

  /// Helper to create a SourceFile instance. (For instance methods)
  SourceFile _createFileModel(
    String path,
    int size,
    String? content,
    bool isBinary,
    int lineCount,
    DateTime timestamp,
  ) {
    final language = detectLanguage(path);
    return SourceFile(
      path: path,
      content: content,
      size: size,
      language: language,
      isBinary: isBinary,
      lineCount: lineCount,
      isSourceCode: language != null && !isBinary,
      isConfiguration: isConfigurationFile(path),
      isDocumentation: isDocumentationFile(path),
      timestamp: timestamp,
    );
  }

  /// Helper to create a SourceFile instance. (For static/isolate methods)
  static SourceFile _createFileModelFromData(
    String path,
    int size,
    String? content,
    bool isBinary,
    int lineCount,
    DateTime timestamp,
  ) {
    final language = detectLanguage(path);
    return SourceFile(
      path: path,
      content: content,
      size: size,
      language: language,
      isBinary: isBinary,
      lineCount: lineCount,
      isSourceCode: language != null && !isBinary,
      isConfiguration: isConfigurationFile(path),
      isDocumentation: isDocumentationFile(path),
      timestamp: timestamp,
    );
  }

  /// Returns an unmodifiable list of errors encountered during analysis.
  List<AnalysisError> getErrors() => List.unmodifiable(errors);

  /// Clears the list of errors.
  void clearErrors() => errors.clear();
}
