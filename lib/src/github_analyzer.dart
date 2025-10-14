import 'dart:async';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/data/providers/github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/infrastructure/http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';

/// Main class for analyzing GitHub repositories
/// Coordinates local and remote repository analysis
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

  /// Stream of analysis progress updates
  Stream<AnalysisProgress> get progressStream => _progressController.stream;

  /// Creates a GithubAnalyzer instance with all dependencies
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

  /// Creates a GithubAnalyzer with automatic .env loading and dependency injection
  static Future<GithubAnalyzer> create({
    GithubAnalyzerConfig? config,
  }) async {
    // Create config with auto .env loading if not provided
    final effectiveConfig = config ?? await GithubAnalyzerConfig.create();

    // Create HTTP client manager
    final httpClientManager = HttpClientManager(
      requestTimeout: Duration(seconds: 30),
      maxConcurrentRequests: effectiveConfig.maxConcurrentRequests,
      maxRetries: effectiveConfig.maxRetries,
    );

    // Create API provider
    final apiProvider = GithubApiProvider(
      httpClientManager: httpClientManager,
      token: effectiveConfig.githubToken,
    );

    // Create ZIP downloader
    final zipDownloader = ZipDownloader(
      httpClientManager: httpClientManager,
    );

    // Create cache service if enabled
    CacheService? cacheService;
    if (effectiveConfig.enableCache) {
      cacheService = CacheService(
        cacheDirectory: effectiveConfig.cacheDirectory,
        maxAge: effectiveConfig.cacheDuration,
      );
      await cacheService.initialize();
    }

    // Create isolate pool if enabled
    IsolatePool? isolatePool;
    if (effectiveConfig.enableIsolatePool) {
      isolatePool = IsolatePool(size: effectiveConfig.isolatePoolSize);
      await isolatePool.initialize();
    }

    // Create repository analyzer
    final repositoryAnalyzer = RepositoryAnalyzer(
      config: effectiveConfig,
      isolatePool: isolatePool,
    );

    // Create local analyzer service
    final localAnalyzer = LocalAnalyzerService(
      config: effectiveConfig,
      repositoryAnalyzer: repositoryAnalyzer,
    );

    // Create remote analyzer service
    final remoteAnalyzer = RemoteAnalyzerService(
      config: effectiveConfig,
      apiProvider: apiProvider,
      zipDownloader: zipDownloader,
      cacheService: cacheService,
    );

    return GithubAnalyzer(
      config: effectiveConfig,
      httpClientManager: httpClientManager,
      apiProvider: apiProvider,
      zipDownloader: zipDownloader,
      localAnalyzer: localAnalyzer,
      remoteAnalyzer: remoteAnalyzer,
      cacheService: cacheService,
      isolatePool: isolatePool,
    );
  }

  /// Analyzes a local directory
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

  /// Analyzes a remote repository from URL
  Future<AnalysisResult> analyzeRemote({
    required String repositoryUrl,
    String? branch,
    bool useCache = true,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');

    // Pass progress controller to remote analyzer service
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

  /// Analyzes a target (auto-detects local path or remote URL)
  Future<AnalysisResult> analyze(String target, {String? branch}) async {
    // Basic check to differentiate between URL and local path
    if (target.startsWith('http') || target.startsWith('git')) {
      return await analyzeRemote(
        repositoryUrl: target,
        branch: branch,
      );
    } else {
      return await analyzeLocal(target);
    }
  }

  /// Clears the cache if enabled
  Future<void> clearCache() async {
    if (cacheService != null) {
      await cacheService!.clear();
      logger.info('Cache cleared');
    }
  }

  /// Gets cache statistics
  Future<Map<String, dynamic>?> getCacheStatistics() async {
    return await cacheService?.getStatistics();
  }

  /// Disposes all resources
  Future<void> dispose() async {
    _progressController.close();
    httpClientManager.dispose();
    isolatePool?.dispose();
    logger.info('GithubAnalyzer disposed');
  }
}
