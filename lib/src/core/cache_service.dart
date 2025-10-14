import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:universal_io/io.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';

/// Manages caching of analysis results to avoid redundant computations
class CacheService {
  final String cacheDirectory;
  final Duration? maxAge;
  bool _isInitialized = false;

  CacheService({
    required this.cacheDirectory,
    this.maxAge,
  });

  /// Initializes the cache service by creating the cache directory if it doesn't exist
  Future<void> initialize() async {
    if (_isInitialized) return;

    final dir = Directory(cacheDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      logger.info('Cache directory created: $cacheDirectory');
    }
    _isInitialized = true;
  }

  /// Generates a cache key from repository URL and commit hash
  String _generateCacheKey(String repositoryUrl, String commitHash) {
    final input = '$repositoryUrl:$commitHash';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Retrieves a cached AnalysisResult if available and not expired
  Future<AnalysisResult?> get(String repositoryUrl, String commitHash) async {
    if (!_isInitialized) {
      throw AnalyzerException(
        'CacheService not initialized',
        code: AnalyzerErrorCode.cacheError,
      );
    }

    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    if (!await cacheFile.exists()) {
      logger.fine('Cache miss for $repositoryUrl (commit: $commitHash)');
      return null;
    }

    if (maxAge != null) {
      final stat = await cacheFile.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age > maxAge!) {
        logger.info('Cache expired for $repositoryUrl. Deleting.');
        await delete(repositoryUrl, commitHash);
        return null;
      }
    }

    try {
      final content = await cacheFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      logger.info('Cache hit for $repositoryUrl (commit: $commitHash)');
      return AnalysisResult.fromJson(json);
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
    if (!_isInitialized) {
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
    } catch (e, stackTrace) {
      logger.severe('Failed to write cache for $key', e, stackTrace);
      throw AnalyzerException(
        'Failed to write to cache',
        code: AnalyzerErrorCode.cacheError,
        details: e.toString(),
      );
    }
  }

  /// Deletes a specific entry from the cache
  Future<void> delete(String repositoryUrl, String commitHash) async {
    final key = _generateCacheKey(repositoryUrl, commitHash);
    final cacheFile = File('$cacheDirectory/$key.json');

    if (await cacheFile.exists()) {
      await cacheFile.delete();
      logger.info('Deleted cache for $key');
    }
  }

  /// Clears the entire cache directory
  Future<void> clear() async {
    final dir = Directory(cacheDirectory);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
      logger.info('Cache directory cleared.');
    }
  }

  /// Gets statistics about the cache
  Future<Map<String, dynamic>> getStatistics() async {
    final dir = Directory(cacheDirectory);
    if (!await dir.exists()) {
      return {'totalFiles': 0, 'totalSize': 0};
    }

    int totalFiles = 0;
    int totalSize = 0;

    await for (final entity in dir.list()) {
      if (entity is File) {
        totalFiles++;
        totalSize += await entity.length();
      }
    }

    return {
      'totalFiles': totalFiles,
      'totalSize': totalSize,
    };
  }
}
