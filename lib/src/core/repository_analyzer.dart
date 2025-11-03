import 'package:universal_io/io.dart';
import 'dart:convert';
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

/// Analyzes repository files from a local directory or memory archive
class RepositoryAnalyzer {
  final GithubAnalyzerConfig config;
  final IsolatePool? isolatePool;
  final List<AnalysisError> _errors = [];

  RepositoryAnalyzer({
    required this.config,
    this.isolatePool,
  });

  /// Analyzes a directory recursively to extract source files
  Future<List<SourceFile>> analyzeDirectory(String directoryPath) async {
    logger.info('Analyzing directory: $directoryPath');
    final dir = Directory(directoryPath);

    // Check directory existence with proper error handling
    try {
      if (!await dir.exists()) {
        throw AnalyzerException(
          'Directory not found: $directoryPath',
          code: AnalyzerErrorCode.directoryNotFound,
        );
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.severe('File system error checking directory', e, stackTrace);
      throw AnalyzerException(
        'Cannot access directory: $directoryPath',
        code: AnalyzerErrorCode.directoryNotFound,
        details: 'File system error: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
      );
    }

    // Collect all files in the directory
    final fileEntities = <File>[];
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: directoryPath);
          if (shouldExclude(relativePath, config.effectiveExcludePatterns)) {
            continue;
          }
          fileEntities.add(entity);
        }
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.severe('Error scanning directory', e, stackTrace);
      throw AnalyzerException(
        'Failed to scan directory: $directoryPath',
        code: AnalyzerErrorCode.analysisError,
        details: 'File system error: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
      );
    }

    logger.info('Found ${fileEntities.length} files to analyze');

    // Auto-enable isolate pool based on file count
    final shouldUseIsolatePool = _shouldUseIsolatePool(fileEntities.length);

    if (shouldUseIsolatePool && isolatePool != null) {
      logger.info('Auto-enabled isolate pool for ${fileEntities.length} files');
      return await _analyzeFilesInParallel(fileEntities, directoryPath);
    } else {
      return await _analyzeFilesSequentially(fileEntities, directoryPath);
    }
  }

  /// Analyzes an archive in memory
  Future<List<SourceFile>> analyzeArchive(Archive archive) async {
    logger.info('Analyzing archive with ${archive.length} entries');

    try {
      // Calculate estimated size for streaming decision
      final estimatedSize = _calculateArchiveSize(archive);
      final useStreaming = config.shouldUseStreamingMode(
        estimatedSize: estimatedSize,
      );

      if (useStreaming) {
        logger.info(
          'Using streaming mode for large archive (${_formatBytes(estimatedSize)})',
        );
        return await _analyzeArchiveStreaming(archive);
      } else {
        return await _analyzeArchiveInMemory(archive);
      }
    } on ArchiveException catch (e, stackTrace) {
      logger.severe('Archive processing error', e, stackTrace);
      throw AnalyzerException(
        'Failed to process archive',
        code: AnalyzerErrorCode.analysisError,
        details: 'Archive is corrupted or invalid: ${e.toString()}',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on OutOfMemoryError catch (e, stackTrace) {
      logger.severe('Out of memory while processing archive', e, stackTrace);
      throw AnalyzerException(
        'Out of memory',
        code: AnalyzerErrorCode.analysisError,
        details:
            'The archive is too large to process. Try with a smaller repository.',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Streaming analysis for large archives (processes in batches)
  Future<List<SourceFile>> _analyzeArchiveStreaming(Archive archive) async {
    final files = <SourceFile>[];
    String? rootPrefix;

    // Process files in batches to avoid memory pressure
    const batchSize = 50;
    final List<ArchiveFile> batch = [];

    for (final file in archive.files) {
      if (file.isFile) {
        rootPrefix ??= _detectRootPrefix(file.name);
        var relativePath = file.name;

        if (rootPrefix.isNotEmpty &&
            relativePath.startsWith(rootPrefix) &&
            relativePath.length > rootPrefix.length) {
          relativePath = relativePath.substring(rootPrefix.length);
        }

        if (shouldExclude(relativePath, config.effectiveExcludePatterns)) {
          continue;
        }

        batch.add(file);

        // Process batch when full
        if (batch.length >= batchSize) {
          final processedFiles = await _processBatch(batch, rootPrefix);
          files.addAll(processedFiles);
          batch.clear();
        }
      }
    }

    // Process remaining files
    if (batch.isNotEmpty) {
      final processedFiles = await _processBatch(batch, rootPrefix);
      files.addAll(processedFiles);
    }

    logger.info('Streaming analysis completed: ${files.length} files analyzed');
    return files;
  }

  /// Process a batch of archive files
  Future<List<SourceFile>> _processBatch(
    List<ArchiveFile> batch,
    String? rootPrefix,
  ) async {
    final files = <SourceFile>[];

    for (final file in batch) {
      var relativePath = file.name;

      if (rootPrefix != null &&
          rootPrefix.isNotEmpty &&
          relativePath.startsWith(rootPrefix) &&
          relativePath.length > rootPrefix.length) {
        relativePath = relativePath.substring(rootPrefix.length);
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
          'Failed to analyze archive file: $relativePath',
          e,
          stackTrace,
        );
        _errors.add(
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

  /// Standard in-memory archive analysis
  Future<List<SourceFile>> _analyzeArchiveInMemory(Archive archive) async {
    final files = <SourceFile>[];
    String? rootPrefix;

    for (final file in archive.files) {
      if (file.isFile) {
        rootPrefix ??= _detectRootPrefix(file.name);
        var relativePath = file.name;

        if (rootPrefix.isNotEmpty &&
            relativePath.startsWith(rootPrefix) &&
            relativePath.length > rootPrefix.length) {
          relativePath = relativePath.substring(rootPrefix.length);
        }

        if (shouldExclude(relativePath, config.effectiveExcludePatterns)) {
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
            'Failed to analyze archive file: $relativePath',
            e,
            stackTrace,
          );
          _errors.add(
            AnalysisError(
              path: relativePath,
              message: e.toString(),
              stackTrace: stackTrace.toString(),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    }

    logger.info('Archive analysis completed: ${files.length} files analyzed');
    return files;
  }

  /// Determine if isolate pool should be used
  bool _shouldUseIsolatePool(int fileCount) {
    // If explicitly disabled, respect that
    if (!config.enableIsolatePool) return false;

    // Check auto-enable threshold
    return fileCount >= config.autoIsolatePoolThreshold;
  }

  /// Calculate total archive size
  int _calculateArchiveSize(Archive archive) {
    int totalSize = 0;
    for (final file in archive.files) {
      if (file.isFile) {
        totalSize += file.size;
      }
    }
    return totalSize;
  }

  /// Format bytes for logging
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Analyzes files in parallel using isolate pool
  Future<List<SourceFile>> _analyzeFilesInParallel(
    List<File> fileEntities,
    String basePath,
  ) async {
    logger.info('Analyzing files in parallel with isolate pool');
    final args = fileEntities.map((entity) {
      return {
        'filePath': entity.path,
        'basePath': basePath,
        'maxFileSize': config.maxFileSize,
      };
    }).toList();

    try {
      final results = await isolatePool!.executeAll(
        _analyzeFileInIsolate,
        args,
      );

      final files = <SourceFile>[];
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result is Map) {
          if (result.containsKey('error')) {
            final relativePath = path.relative(
              fileEntities[i].path,
              from: basePath,
            );
            _errors.add(
              AnalysisError(
                path: relativePath,
                message: result['error'] as String,
                stackTrace: result['stackTrace'] as String?,
                timestamp: DateTime.now(),
              ),
            );
          } else {
            // Type-safe conversion from Map<dynamic, dynamic> to Map<String, dynamic>
            files.add(SourceFile.fromJson(
              Map<String, dynamic>.from(result),
            ));
          }
        }
      }
      return files;
    } catch (e, stackTrace) {
      logger.warning(
        'Parallel analysis failed, falling back to sequential',
        e,
        stackTrace,
      );
      return await _analyzeFilesSequentially(fileEntities, basePath);
    }
  }

  /// Analyzes files sequentially
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
        logger.warning('Failed to analyze file: ${entity.path}', e, stackTrace);
        _errors.add(
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

  /// Isolate worker function for parallel file analysis
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
          // Treat as binary if reading fails
          return _createFileModelFromData(
            relativePath,
            stat.size,
            null,
            true,
            0,
            stat.modified,
          ).toJson();
        }
      }

      return _createFileModelFromData(
        relativePath,
        stat.size,
        content,
        isBinary,
        lineCount,
        stat.modified,
      ).toJson();
    } catch (e, stackTrace) {
      return {
        'path': relativePath,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
    }
  }

  /// Analyzes a single file from the file system
  Future<SourceFile?> _analyzeFile(
    File file,
    String relativePath,
    int maxFileSize,
  ) async {
    try {
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
        } on FileSystemException catch (e) {
          // Failed to read file as text - treat as binary
          logger.warning(
            'Failed to read file as text (treating as binary): $relativePath - ${e.message}',
          );
          return _createFileModelFromData(
            relativePath,
            stat.size,
            null,
            true,
            0,
            stat.modified,
          );
        } on FormatException catch (e) {
          // Encoding error - treat as binary
          logger.warning(
            'Encoding error reading file (treating as binary): $relativePath - ${e.message}',
          );
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
    } on FileSystemException catch (e, stackTrace) {
      // File system error (e.g., permission denied, file deleted)
      logger.warning(
        'File system error analyzing file: $relativePath',
        e,
        stackTrace,
      );
      return null; // Skip this file
    }
  }

  /// Analyzes a single file from an archive
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
    final timestamp = DateTime.now();

    if (!isBinary) {
      try {
        content = utf8.decode(
          file.content as List<int>,
          allowMalformed: true,
        );
        lineCount = content.split('\n').length;
      } on FormatException catch (e) {
        // UTF-8 decode failed - treat as binary
        logger.finer(
          'UTF-8 decode failed for archive file (treating as binary): $relativePath - ${e.message}',
        );
        return _createFileModel(
          relativePath,
          file.size,
          null,
          true,
          0,
          timestamp,
        );
      } on TypeError catch (e) {
        // Type error processing content
        logger.warning(
          'Type error processing archive file content: $relativePath',
          e,
        );
        return _createFileModel(
          relativePath,
          file.size,
          null,
          true,
          0,
          timestamp,
        );
      } catch (e) {
        logger.finer(
          'Failed to read archive file as text (treating as binary): $relativePath ($e)',
        );
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

  /// Creates a SourceFile model from analyzed data
  static SourceFile _createFileModelFromData(
    String relativePath,
    int size,
    String? content,
    bool isBinary,
    int lineCount,
    DateTime timestamp,
  ) {
    final language = detectLanguage(relativePath);
    final isSrc = language != null && !isBinary;
    final isConfig = isConfigurationFile(relativePath);
    final isDoc = isDocumentationFile(relativePath);

    return SourceFile(
      path: relativePath,
      content: content,
      size: size,
      language: language,
      isBinary: isBinary,
      lineCount: lineCount,
      isSourceCode: isSrc,
      isConfiguration: isConfig,
      isDocumentation: isDoc,
      timestamp: timestamp,
    );
  }

  /// Creates a SourceFile model
  static SourceFile _createFileModel(
    String relativePath,
    int size,
    String? content,
    bool isBinary,
    int lineCount,
    DateTime timestamp,
  ) {
    return _createFileModelFromData(
      relativePath,
      size,
      content,
      isBinary,
      lineCount,
      timestamp,
    );
  }

  /// Detects the root prefix in archive entries
  String _detectRootPrefix(String path) {
    final parts = path.split('/');
    return parts.length > 1 ? '${parts[0]}/' : '';
  }

  /// Gets all errors that occurred during analysis
  List<AnalysisError> getErrors() => List.unmodifiable(_errors);

  /// Clears all errors
  void clearErrors() => _errors.clear();
}
