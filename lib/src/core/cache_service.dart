import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:universal_io/io.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';

class CacheService {
  final String cacheDirectory;
  final Duration? maxAge;
  bool isInitialized = false;

  static const String _fileCacheSubdir = 'files';

  CacheService({required this.cacheDirectory, this.maxAge});

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      final dir = Directory(cacheDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        logger.info('Cache directory created: $cacheDirectory');
      }

      final fileCacheDir = Directory('$cacheDirectory/$_fileCacheSubdir');
      if (!await fileCacheDir.exists()) {
        await fileCacheDir.create(recursive: true);
        logger.info('File-level cache directory created');
      }

      isInitialized = true;
    } on FileSystemException catch (e, stackTrace) {
      _throwCacheError(
        'Failed to initialize cache service',
        'Cannot create cache directory: ${e.message}',
        e,
        stackTrace,
        _isPermissionError(e),
      );
    } catch (e, stackTrace) {
      logger.severe('Unexpected error initializing cache', e, stackTrace);
      throw AnalyzerException(
        'Failed to initialize cache service',
        code: AnalyzerErrorCode.cacheError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  String _generateCacheKey(String repositoryUrl, String commitHash) {
    final input = '$repositoryUrl:$commitHash';
    return sha256.convert(utf8.encode(input)).toString();
  }

  String _generateFileCacheKey(String filePath, String contentHash) {
    final input = '$filePath:$contentHash';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<AnalysisResult?> get(String repositoryUrl, String commitHash) async {
    _checkInitialized();

    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    if (!await _fileExists(cacheFile)) {
      logger.fine('Cache miss for $repositoryUrl (commit: $commitHash)');
      return null;
    }

    if (!await _isNotExpired(cacheFile, key)) {
      await delete(repositoryUrl, commitHash);
      return null;
    }

    return await _readJsonFile<AnalysisResult>(
      cacheFile,
      key,
      (json) => AnalysisResult.fromJson(json),
      () => delete(repositoryUrl, commitHash),
    );
  }

  Future<void> set(
    String repositoryUrl,
    String commitHash,
    AnalysisResult result,
  ) async {
    _checkInitialized();

    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    await _writeJsonFile(
      cacheFile,
      key,
      result.toJson(),
      'Failed to write to cache',
      'repository analysis',
    );

    logger.info('Saved cache for $repositoryUrl (commit: $commitHash)');
  }

  Future<SourceFile?> getFile(String filePath, String contentHash) async {
    _checkInitialized();

    final key = _generateFileCacheKey(filePath, contentHash);
    final cacheFile = File('$cacheDirectory/$_fileCacheSubdir/$key.json');

    if (!await _fileExists(cacheFile)) {
      logger.fine('File cache miss for $filePath');
      return null;
    }

    if (!await _isNotExpired(cacheFile, key)) {
      await deleteFile(filePath, contentHash);
      return null;
    }

    return await _readJsonFile<SourceFile>(
      cacheFile,
      key,
      (json) => SourceFile.fromJson(json),
      () => deleteFile(filePath, contentHash),
    );
  }

  Future<void> setFile(
    String filePath,
    String contentHash,
    SourceFile sourceFile,
  ) async {
    _checkInitialized();

    final key = _generateFileCacheKey(filePath, contentHash);
    final cacheFile = File('$cacheDirectory/$_fileCacheSubdir/$key.json');

    try {
      final json = jsonEncode(sourceFile.toJson());
      await cacheFile.writeAsString(json);
      logger.fine('Saved file cache for $filePath');
    } on FileSystemException catch (e, stackTrace) {
      logger.warning(
        'File system error writing file cache for $key',
        e,
        stackTrace,
      );
    } on JsonUnsupportedObjectError catch (e, stackTrace) {
      logger.warning(
        'JSON serialization error for file cache $key',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      logger.warning('Failed to write file cache for $key', e, stackTrace);
    }
  }

  Future<Map<String, SourceFile>> batchGetFiles(
    Map<String, String> filePathsToHashes,
  ) async {
    final cachedFiles = <String, SourceFile>{};

    for (final entry in filePathsToHashes.entries) {
      try {
        final cached = await getFile(entry.key, entry.value);
        if (cached != null) {
          cachedFiles[entry.key] = cached;
        }
      } catch (e) {
        logger.fine('Error loading file from cache: ${entry.key}');
      }
    }

    if (cachedFiles.isNotEmpty) {
      logger.info('Retrieved ${cachedFiles.length} files from cache');
    }

    return cachedFiles;
  }

  Future<void> batchSetFiles(
    Map<String, String> filePathsToHashes,
    Map<String, SourceFile> sourceFiles,
  ) async {
    int savedCount = 0;

    for (final entry in sourceFiles.entries) {
      final contentHash = filePathsToHashes[entry.key];
      if (contentHash != null) {
        try {
          await setFile(entry.key, contentHash, entry.value);
          savedCount++;
        } catch (e) {
          logger.fine('Error saving file to cache: ${entry.key}');
        }
      }
    }

    if (savedCount > 0) {
      logger.info('Saved $savedCount files to cache');
    }
  }

  Future<void> delete(String repositoryUrl, String commitHash) async {
    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    await _safeDelete(cacheFile, key, 'repository');
  }

  Future<void> deleteFile(String filePath, String contentHash) async {
    final key = _generateFileCacheKey(filePath, contentHash);
    final cacheFile = File('$cacheDirectory/$_fileCacheSubdir/$key.json');

    await _safeDelete(cacheFile, key, 'file');
  }

  Future<void> clear() async {
    final dir = Directory(cacheDirectory);

    try {
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } on FileSystemException catch (e) {
            logger.warning(
              'Error deleting cache entry: ${entity.path} - ${e.message}',
            );
          }
        }
        logger.info('Cache directory cleared');
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.severe('Error clearing cache directory', e, stackTrace);
      throw AnalyzerException(
        'Failed to clear cache',
        code: AnalyzerErrorCode.cacheError,
        details: 'File system error: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearFileCache() async {
    final dir = Directory('$cacheDirectory/$_fileCacheSubdir');

    try {
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } on FileSystemException catch (e) {
            logger.warning(
              'Error deleting file cache entry: ${entity.path} - ${e.message}',
            );
          }
        }
        logger.info('File-level cache cleared');
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error clearing file cache directory', e, stackTrace);
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final dir = Directory(cacheDirectory);

    try {
      if (!await dir.exists()) {
        return _emptyStatistics();
      }

      int totalFiles = 0;
      int totalSize = 0;
      int fileLevelCacheCount = 0;
      int fileLevelCacheSize = 0;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            totalFiles++;
            totalSize += size;

            if (entity.path.contains('/$_fileCacheSubdir/')) {
              fileLevelCacheCount++;
              fileLevelCacheSize += size;
            }
          } on FileSystemException catch (e) {
            logger.fine(
              'Error getting file size: ${entity.path} - ${e.message}',
            );
          }
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'fileLevelCacheCount': fileLevelCacheCount,
        'fileLevelCacheSize': fileLevelCacheSize,
      };
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error getting cache statistics', e, stackTrace);
      return _emptyStatistics();
    }
  }

  Future<bool> _fileExists(File file) async {
    try {
      return await file.exists();
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error checking file existence', e, stackTrace);
      return false;
    }
  }

  Future<bool> _isNotExpired(File cacheFile, String key) async {
    if (maxAge == null) return true;

    try {
      final stat = await cacheFile.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age > maxAge!) {
        logger.info('Cache expired for $key. Deleting');
        return false;
      }
      return true;
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error checking cache age', e, stackTrace);
      return true;
    }
  }

  Future<T?> _readJsonFile<T>(
    File cacheFile,
    String key,
    T Function(Map<String, dynamic>) parser,
    Future<void> Function() onCorrupted,
  ) async {
    try {
      final content = await cacheFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return parser(json);
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('File system error reading cache for $key', e, stackTrace);
      await onCorrupted();
      return null;
    } on FormatException catch (e, stackTrace) {
      logger.warning('JSON parse error for cache $key', e, stackTrace);
      await onCorrupted();
      return null;
    } on TypeError catch (e, stackTrace) {
      logger.warning('Type error deserializing cache $key', e, stackTrace);
      await onCorrupted();
      return null;
    } catch (e, stackTrace) {
      logger.warning('Failed to read or parse cache $key', e, stackTrace);
      await onCorrupted();
      return null;
    }
  }

  Future<void> _writeJsonFile(
    File cacheFile,
    String key,
    dynamic data,
    String title,
    String context,
  ) async {
    try {
      final json = jsonEncode(data);
      await cacheFile.writeAsString(json);
    } on FileSystemException catch (e, stackTrace) {
      logger.severe('File system error writing cache for $key', e, stackTrace);
      throw AnalyzerException(
        title,
        code: AnalyzerErrorCode.cacheError,
        details: 'File system error: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on JsonUnsupportedObjectError catch (e, stackTrace) {
      logger.severe(
        'JSON serialization error for $context cache',
        e,
        stackTrace,
      );
      throw AnalyzerException(
        'Failed to serialize analysis result',
        code: AnalyzerErrorCode.cacheError,
        details: 'Cannot serialize object: ${e.cause}',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      logger.severe('Failed to write cache for $key', e, stackTrace);
      throw AnalyzerException(
        title,
        code: AnalyzerErrorCode.cacheError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _safeDelete(File cacheFile, String key, String type) async {
    try {
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        logger.info('Deleted $type cache for $key');
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error deleting $type cache $key', e, stackTrace);
    }
  }

  bool _isPermissionError(FileSystemException e) {
    return e.osError?.errorCode == 13 || e.osError?.errorCode == 5;
  }

  Never _throwCacheError(
    String title,
    String details,
    FileSystemException e,
    StackTrace stackTrace,
    bool isPermissionError,
  ) {
    if (isPermissionError) {
      throw AnalyzerException(
        'Permission denied',
        code: AnalyzerErrorCode.cacheError,
        details:
            'Cannot access cache directory: ${e.message}\n'
            'Please check directory permissions.',
        originalException: e,
        stackTrace: stackTrace,
      );
    }

    throw AnalyzerException(
      title,
      code: AnalyzerErrorCode.cacheError,
      details: details,
      originalException: e,
      stackTrace: stackTrace,
    );
  }

  Map<String, dynamic> _emptyStatistics() {
    return {
      'totalFiles': 0,
      'totalSize': 0,
      'fileLevelCacheCount': 0,
      'fileLevelCacheSize': 0,
    };
  }

  void _checkInitialized() {
    if (!isInitialized) {
      throw AnalyzerException(
        'CacheService not initialized',
        code: AnalyzerErrorCode.cacheError,
      );
    }
  }
}
