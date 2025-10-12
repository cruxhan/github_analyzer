import 'dart:async';
import 'dart:io';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';

/// The main class for analyzing GitHub repositories.
///
/// This class coordinates the analysis process for both local and remote
/// repositories by delegating tasks to specialized services. It is configured
/// via a [GithubAnalyzerConfig] object and reports progress through a stream.
///
/// Dependencies are injected through the constructor to promote modularity
/// and testability.
class GithubAnalyzer {
  final GithubAnalyzerConfig config;
  final IHttpClientManager httpClientManager;
  final IGithubApiProvider apiProvider;
  final ZipDownloader zipDownloader;
  final CacheService? cacheService;
  final IsolatePool? isolatePool;
  final LocalAnalyzerService localAnalyzer;
  final RemoteAnalyzerService remoteAnalyzer;

  final StreamController<AnalysisProgress> _progressController =
      StreamController.broadcast();

  /// A stream of [AnalysisProgress] updates.
  Stream<AnalysisProgress> get progressStream => _progressController.stream;

  /// Creates an instance of [GithubAnalyzer].
  ///
  /// All service dependencies must be provided. This allows for flexible
  /// configuration and easy mocking for tests.
  GithubAnalyzer({
    required this.config,
    required this.httpClientManager,
    required this.apiProvider,
    required this.zipDownloader,
    required this.localAnalyzer,
    required this.remoteAnalyzer,
    this.cacheService,
    this.isolatePool,
  }) {
    // Initialize services that require it
    cacheService?.initialize();
    isolatePool?.initialize();
  }

  /// Analyzes a local directory.
  Future<AnalysisResult> analyzeLocal(String directoryPath) async {
    logger.info('Starting local analysis: $directoryPath');

    _progressController.add(
      AnalysisProgress(
        phase: AnalysisPhase.initializing,
        progress: 0.0,
        message: 'Starting local analysis',
        timestamp: DateTime.now(),
      ),
    );

    final result = await localAnalyzer.analyze(directoryPath);

    _progressController.add(
      AnalysisProgress(
        phase: AnalysisPhase.completed,
        progress: 1.0,
        message: 'Local analysis completed',
        timestamp: DateTime.now(),
      ),
    );

    return result;
  }

  /// Analyzes a remote repository from a URL.
  Future<AnalysisResult> analyzeRemote({
    required String repositoryUrl,
    String? branch,
    bool useCache = true,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');
    // Pass the progress controller to the remote analyzer service
    final remoteServiceWithProgress = remoteAnalyzer.copyWith(
      progressController: _progressController,
    );
    final result = await remoteServiceWithProgress.analyze(
      repositoryUrl: repositoryUrl,
      branch: branch,
      useCache: useCache,
    );

    return result;
  }

  /// Analyzes a target which can be either a local path or a remote URL.
  Future<AnalysisResult> analyze(String target, {String? branch}) async {
    // Basic check to differentiate between a URL and a local path.
    if (target.startsWith('http') || target.startsWith('git@')) {
      return await analyzeRemote(repositoryUrl: target, branch: branch);
    } else {
      return await analyzeLocal(target);
    }
  }

  /// Clears the cache if it is enabled.
  Future<void> clearCache() async {
    if (cacheService != null) {
      await cacheService!.clear();
      logger.info('Cache cleared');
    }
  }

  /// Gets statistics about the cache.
  Future<Map<String, dynamic>?> getCacheStatistics() async {
    return await cacheService?.getStatistics();
  }

  /// Disposes all resources used by the analyzer.
  Future<void> dispose() async {
    _progressController.close();
    httpClientManager.dispose();
    isolatePool?.dispose();
    if (cacheService != null) {
      final dir = Directory(config.cacheDirectory);
      if (await dir.exists()) {
        try {
          // This recursively deletes the directory and all its contents,
          // making the separate `clear()` call redundant.
          await dir.delete(recursive: true);
          logger.info('Cache directory removed: ${config.cacheDirectory}');
        } catch (e, stackTrace) {
          logger.severe('Failed to delete cache directory.', e, stackTrace);
        }
      }
    }
    logger.info('GithubAnalyzer disposed');
  }
}
