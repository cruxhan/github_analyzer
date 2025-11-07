import 'dart:convert';

import 'package:universal_io/io.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/common/language_info.dart';
import 'package:github_analyzer/src/models/analysis_error.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';

class RepositoryAnalyzer {
  final GithubAnalyzerConfig config;
  final IsolatePool? isolatePool;
  final List<AnalysisError> _errors = [];

  RepositoryAnalyzer({required this.config, this.isolatePool});

  Future<List<SourceFile>> analyzeDirectory(String directoryPath) async {
    logger.info('Analyzing directory: $directoryPath');
    final dir = Directory(directoryPath);

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

    final shouldUseIsolatePool = _shouldUseIsolatePool(fileEntities.length);

    if (shouldUseIsolatePool && isolatePool != null) {
      logger.info('Auto-enabled isolate pool for ${fileEntities.length} files');
      return await _analyzeFilesInParallel(fileEntities, directoryPath);
    } else {
      return await _analyzeFilesSequentially(fileEntities, directoryPath);
    }
  }

  Future<List<SourceFile>> analyzeArchive(Archive archive) async {
    logger.info('Analyzing archive with ${archive.length} entries');

    try {
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

  Future<List<SourceFile>> _analyzeArchiveStreaming(Archive archive) async {
    final files = <SourceFile>[];
    String? rootPrefix;

    const batchSize = 50;
    final List<ArchiveFile> batch = [];

    for (final file in archive.files) {
      if (file.isFile) {
        rootPrefix ??= _detectRootPrefix(file.name);
        final relativePath = _stripRootPrefix(file.name, rootPrefix);

        if (shouldExclude(relativePath, config.effectiveExcludePatterns)) {
          continue;
        }

        batch.add(file);

        if (batch.length >= batchSize) {
          final processedFiles = await _processBatch(batch, rootPrefix);
          files.addAll(processedFiles);
          batch.clear();
        }
      }
    }

    if (batch.isNotEmpty) {
      final processedFiles = await _processBatch(batch, rootPrefix);
      files.addAll(processedFiles);
    }

    logger.info('Streaming analysis completed: ${files.length} files analyzed');
    return files;
  }

  Future<List<SourceFile>> _processBatch(
    List<ArchiveFile> batch,
    String? rootPrefix,
  ) async {
    final files = <SourceFile>[];

    for (final file in batch) {
      final relativePath = _stripRootPrefix(file.name, rootPrefix);

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
        _addError(relativePath, e, stackTrace);
      }
    }

    return files;
  }

  Future<List<SourceFile>> _analyzeArchiveInMemory(Archive archive) async {
    final files = <SourceFile>[];
    String? rootPrefix;

    for (final file in archive.files) {
      if (file.isFile) {
        rootPrefix ??= _detectRootPrefix(file.name);
        final relativePath = _stripRootPrefix(file.name, rootPrefix);

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
          _addError(relativePath, e, stackTrace);
        }
      }
    }

    logger.info('Archive analysis completed: ${files.length} files analyzed');
    return files;
  }

  bool _shouldUseIsolatePool(int fileCount) {
    if (!config.enableIsolatePool) return false;
    return fileCount >= config.autoIsolatePoolThreshold;
  }

  int _calculateArchiveSize(Archive archive) {
    int totalSize = 0;
    for (final file in archive.files) {
      if (file.isFile) {
        totalSize += file.size;
      }
    }
    return totalSize;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

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
        final result = _extractResult(results[i]);
        if (result.isError) {
          final relativePath = path.relative(
            fileEntities[i].path,
            from: basePath,
          );
          _addError(
            relativePath,
            Exception(result.errorMessage),
            StackTrace.fromString(result.stackTrace),
          );
        } else if (result.sourceFile != null) {
          files.add(result.sourceFile!);
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
        _addError(relativePath, e, stackTrace);
      }
    }
    return files;
  }

  static Future<dynamic> _analyzeFileInIsolate(
    Map<String, dynamic> args,
  ) async {
    final filePath = _extractString(args, 'filePath');
    final basePath = _extractString(args, 'basePath');
    final maxFileSize = _extractInt(args, 'maxFileSize');
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
      logger.warning(
        'File system error analyzing file: $relativePath',
        e,
        stackTrace,
      );
      return null;
    }
  }

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
        content = utf8.decode(file.content as List<int>, allowMalformed: true);
        lineCount = content.split('\n').length;
      } on FormatException catch (e) {
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

  String _stripRootPrefix(String filePath, String? rootPrefix) {
    if (rootPrefix == null || rootPrefix.isEmpty) {
      return filePath;
    }

    if (filePath.startsWith(rootPrefix) &&
        filePath.length > rootPrefix.length) {
      return filePath.substring(rootPrefix.length);
    }

    return filePath;
  }

  String _detectRootPrefix(String path) {
    final parts = path.split('/');
    return parts.length > 1 ? '${parts[0]}/' : '';
  }

  void _addError(String relativePath, Object e, StackTrace stackTrace) {
    logger.warning('Failed to analyze file: $relativePath', e, stackTrace);
    _errors.add(
      AnalysisError(
        path: relativePath,
        message: e.toString(),
        stackTrace: stackTrace.toString(),
        timestamp: DateTime.now(),
      ),
    );
  }

  List<AnalysisError> getErrors() => List.unmodifiable(_errors);

  void clearErrors() => _errors.clear();

  static String _extractString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    throw TypeError();
  }

  static int _extractInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    throw TypeError();
  }

  static _IsolateResult _extractResult(dynamic result) {
    if (result == null) {
      return _IsolateResult.empty();
    }
    if (result is Map) {
      final map = result as Map<String, dynamic>;
      if (map.containsKey('error')) {
        return _IsolateResult.error(
          map['error'] as String,
          map['stackTrace'] as String? ?? '',
        );
      } else {
        return _IsolateResult.success(SourceFile.fromJson(map));
      }
    }
    return _IsolateResult.empty();
  }
}

class _IsolateResult {
  final SourceFile? sourceFile;
  final String errorMessage;
  final String stackTrace;
  final bool isError;

  _IsolateResult({
    required this.sourceFile,
    required this.errorMessage,
    required this.stackTrace,
    required this.isError,
  });

  factory _IsolateResult.empty() => _IsolateResult(
    sourceFile: null,
    errorMessage: '',
    stackTrace: '',
    isError: false,
  );

  factory _IsolateResult.success(SourceFile file) => _IsolateResult(
    sourceFile: file,
    errorMessage: '',
    stackTrace: '',
    isError: false,
  );

  factory _IsolateResult.error(String error, String st) => _IsolateResult(
    sourceFile: null,
    errorMessage: error,
    stackTrace: st,
    isError: true,
  );
}
