import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:universal_io/io.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/source_file.dart';

/// Manages caching of analysis results to avoid redundant computations
class CacheService {
  final String cacheDirectory;
  final Duration? maxAge;
  bool isInitialized = false;

  CacheService({required this.cacheDirectory, this.maxAge});

  /// Initializes the cache service by creating the cache directory if it doesn't exist
  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      final dir = Directory(cacheDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        logger.info('Cache directory created: $cacheDirectory');
      }

      // Create file-level cache subdirectory
      final fileCacheDir = Directory('$cacheDirectory/files');
      if (!await fileCacheDir.exists()) {
        await fileCacheDir.create(recursive: true);
        logger.info('File-level cache directory created');
      }

      isInitialized = true;
    } on FileSystemException catch (e, stackTrace) {
      // FileSystemException includes PathAccessException as a subtype
      logger.severe('Failed to initialize cache directory', e, stackTrace);

      // Check if it's a permission issue specifically
      final isPermissionError =
          e.osError?.errorCode == 13 || // Unix: Permission denied
          e.osError?.errorCode == 5; // Windows: Access denied

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
        'Failed to initialize cache service',
        code: AnalyzerErrorCode.cacheError,
        details: 'Cannot create cache directory: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
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

  /// Generates a cache key from repository URL and commit hash
  String _generateCacheKey(String repositoryUrl, String commitHash) {
    final input = '$repositoryUrl:$commitHash';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Generates a cache key for individual file
  String _generateFileCacheKey(String filePath, String contentHash) {
    final input = '$filePath:$contentHash';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Retrieves a cached AnalysisResult if available and not expired
  Future<AnalysisResult?> get(String repositoryUrl, String commitHash) async {
    if (!isInitialized) {
      throw AnalyzerException(
        'CacheService not initialized',
        code: AnalyzerErrorCode.cacheError,
      );
    }

    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    try {
      if (!await cacheFile.exists()) {
        logger.fine('Cache miss for $repositoryUrl (commit: $commitHash)');
        return null;
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error checking cache file existence', e, stackTrace);
      return null;
    }

    // Check if cache is expired
    if (maxAge != null) {
      try {
        final stat = await cacheFile.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age > maxAge!) {
          logger.info('Cache expired for $repositoryUrl. Deleting.');
          await delete(repositoryUrl, commitHash);
          return null;
        }
      } on FileSystemException catch (e, stackTrace) {
        logger.warning('Error checking cache file age', e, stackTrace);
        // Continue to try reading the file
      }
    }

    // Read and parse cache file
    try {
      final content = await cacheFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      logger.info('Cache hit for $repositoryUrl (commit: $commitHash)');
      return AnalysisResult.fromJson(json);
    } on FileSystemException catch (e, stackTrace) {
      logger.warning(
        'File system error reading cache file for $key. Deleting.',
        e,
        stackTrace,
      );
      await delete(repositoryUrl, commitHash);
      return null;
    } on FormatException catch (e, stackTrace) {
      logger.warning(
        'JSON parse error for cache file $key. Deleting. Error: $e',
        e,
        stackTrace,
      );
      await delete(repositoryUrl, commitHash);
      return null;
    } on TypeError catch (e, stackTrace) {
      logger.warning(
        'Type error deserializing cache for $key. Deleting.',
        e,
        stackTrace,
      );
      await delete(repositoryUrl, commitHash);
      return null;
    } catch (e, stackTrace) {
      logger.warning(
        'Failed to read or parse cache file for $key. Deleting. Error: $e',
        e,
        stackTrace,
      );
      await delete(repositoryUrl, commitHash);
      return null;
    }
  }

  /// Saves an AnalysisResult to the cache
  Future<void> set(
    String repositoryUrl,
    String commitHash,
    AnalysisResult result,
  ) async {
    if (!isInitialized) {
      throw AnalyzerException(
        'CacheService not initialized',
        code: AnalyzerErrorCode.cacheError,
      );
    }

    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    try {
      final json = jsonEncode(result.toJson());
      await cacheFile.writeAsString(json);
      logger.info('Saved cache for $repositoryUrl (commit: $commitHash)');
    } on FileSystemException catch (e, stackTrace) {
      logger.severe('File system error writing cache for $key', e, stackTrace);
      throw AnalyzerException(
        'Failed to write to cache',
        code: AnalyzerErrorCode.cacheError,
        details: 'File system error: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on JsonUnsupportedObjectError catch (e, stackTrace) {
      logger.severe('JSON serialization error for cache $key', e, stackTrace);
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
        'Failed to write to cache',
        code: AnalyzerErrorCode.cacheError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Retrieves a cached file analysis if available
  Future<SourceFile?> getFile(String filePath, String contentHash) async {
    if (!isInitialized) {
      throw AnalyzerException(
        'CacheService not initialized',
        code: AnalyzerErrorCode.cacheError,
      );
    }

    final key = _generateFileCacheKey(filePath, contentHash);
    final cacheFile = File('$cacheDirectory/files/$key.json');

    try {
      if (!await cacheFile.exists()) {
        logger.fine('File cache miss for $filePath');
        return null;
      }

      if (maxAge != null) {
        final stat = await cacheFile.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age > maxAge!) {
          logger.fine('File cache expired for $filePath. Deleting.');
          await deleteFile(filePath, contentHash);
          return null;
        }
      }

      final content = await cacheFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      logger.fine('File cache hit for $filePath');
      return SourceFile.fromJson(json);
    } on FileSystemException catch (e, stackTrace) {
      logger.warning(
        'File system error reading file cache for $key. Deleting.',
        e,
        stackTrace,
      );
      await deleteFile(filePath, contentHash);
      return null;
    } on FormatException catch (e, stackTrace) {
      logger.warning(
        'JSON parse error for file cache $key. Deleting.',
        e,
        stackTrace,
      );
      await deleteFile(filePath, contentHash);
      return null;
    } catch (e, stackTrace) {
      logger.warning(
        'Failed to read or parse file cache for $key. Deleting. Error: $e',
        e,
        stackTrace,
      );
      await deleteFile(filePath, contentHash);
      return null;
    }
  }

  /// Saves a file analysis to the cache
  Future<void> setFile(
    String filePath,
    String contentHash,
    SourceFile sourceFile,
  ) async {
    if (!isInitialized) {
      throw AnalyzerException(
        'CacheService not initialized',
        code: AnalyzerErrorCode.cacheError,
      );
    }

    final key = _generateFileCacheKey(filePath, contentHash);
    final cacheFile = File('$cacheDirectory/files/$key.json');

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
      // Don't throw - file-level cache failures shouldn't break analysis
    } on JsonUnsupportedObjectError catch (e, stackTrace) {
      logger.warning(
        'JSON serialization error for file cache $key',
        e,
        stackTrace,
      );
      // Don't throw
    } catch (e, stackTrace) {
      logger.warning('Failed to write file cache for $key', e, stackTrace);
      // Don't throw - file-level cache failures shouldn't break analysis
    }
  }

  /// Retrieves multiple files from cache
  Future<Map<String, SourceFile>> getFiles(
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
        // Skip this file if error occurs
        logger.fine('Error loading file from cache: ${entry.key}');
      }
    }

    if (cachedFiles.isNotEmpty) {
      logger.info('Retrieved ${cachedFiles.length} files from cache');
    }

    return cachedFiles;
  }

  /// Saves multiple files to cache
  Future<void> setFiles(
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
          // Continue saving other files even if one fails
          logger.fine('Error saving file to cache: ${entry.key}');
        }
      }
    }

    if (savedCount > 0) {
      logger.info('Saved $savedCount files to cache');
    }
  }

  /// Deletes a specific entry from the cache
  Future<void> delete(String repositoryUrl, String commitHash) async {
    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    try {
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        logger.info('Deleted cache for $key');
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error deleting cache file $key', e, stackTrace);
      // Don't throw - deletion failure is not critical
    }
  }

  /// Deletes a specific file cache entry
  Future<void> deleteFile(String filePath, String contentHash) async {
    final key = _generateFileCacheKey(filePath, contentHash);
    final cacheFile = File('$cacheDirectory/files/$key.json');

    try {
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        logger.fine('Deleted file cache for $key');
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error deleting file cache $key', e, stackTrace);
      // Don't throw
    }
  }

  /// Clears the entire cache directory
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
            // Continue deleting other entries
          }
        }
        logger.info('Cache directory cleared.');
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

  /// Clears only file-level cache
  Future<void> clearFileCache() async {
    final dir = Directory('$cacheDirectory/files');

    try {
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } on FileSystemException catch (e) {
            logger.warning(
              'Error deleting file cache entry: ${entity.path} - ${e.message}',
            );
            // Continue deleting other entries
          }
        }
        logger.info('File-level cache cleared.');
      }
    } on FileSystemException catch (e, stackTrace) {
      logger.warning('Error clearing file cache directory', e, stackTrace);
      // Don't throw - not critical
    }
  }

  /// Gets statistics about the cache
  Future<Map<String, dynamic>> getStatistics() async {
    final dir = Directory(cacheDirectory);

    try {
      if (!await dir.exists()) {
        return {
          'totalFiles': 0,
          'totalSize': 0,
          'fileLevelCacheCount': 0,
          'fileLevelCacheSize': 0,
        };
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

            // Check if it's a file-level cache
            if (entity.path.contains('/files/')) {
              fileLevelCacheCount++;
              fileLevelCacheSize += size;
            }
          } on FileSystemException catch (e) {
            logger.fine(
              'Error getting file size: ${entity.path} - ${e.message}',
            );
            // Continue counting other files
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
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'fileLevelCacheCount': 0,
        'fileLevelCacheSize': 0,
      };
    }
  }
}
