import 'dart:async';

import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/data/providers/github_api_provider.dart';
import 'package:github_analyzer/src/infrastructure/http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

/// Orchestrates the repository analysis process for local and remote repositories.
///
/// [GithubAnalyzer] is the central component that manages all analysis services,
/// handles dependency injection, and provides progress tracking. Supports both
/// local directory and remote GitHub repository analysis with optional caching
/// and parallel processing.
class GithubAnalyzer {
  final GithubAnalyzerConfig config;
  final IHttpClientManager httpClientManager;
  final IGithubApiProvider apiProvider;
  final ZipDownloader zipDownloader;
  final LocalAnalyzerService localAnalyzer;
  final RemoteAnalyzerService remoteAnalyzer;
  final CacheService? cacheService;
  final IsolatePool? isolatePool;
  final StreamController<AnalysisProgress> _progressController =
      StreamController.broadcast();

  /// Stream of real-time progress updates during analysis.
  ///
  /// Emits [AnalysisProgress] events containing phase, progress percentage,
  /// and status messages. Use this to display progress feedback to users.
  Stream<AnalysisProgress> get progressStream => _progressController.stream;

  GithubAnalyzer({
    required this.config,
    required this.httpClientManager,
    required this.apiProvider,
    required this.zipDownloader,
    required this.localAnalyzer,
    required this.remoteAnalyzer,
    this.cacheService,
    this.isolatePool,
  });

  /// Creates a [GithubAnalyzer] with automatic dependency initialization.
  ///
  /// Sets up all required services including HTTP client, API provider, cache,
  /// and isolate pool based on configuration. This is the recommended way to
  /// create an analyzer instance.
  static Future<GithubAnalyzer> create({GithubAnalyzerConfig? config}) async {
    final effectiveConfig = config ?? await GithubAnalyzerConfig.create();

    final httpClientManager = HttpClientManager(
      requestTimeout: const Duration(seconds: 30),
      maxConcurrentRequests: effectiveConfig.maxConcurrentRequests,
      maxRetries: effectiveConfig.maxRetries,
    );

    final apiProvider = GithubApiProvider(
      httpClientManager: httpClientManager,
      token: effectiveConfig.githubToken,
    );

    final zipDownloader = ZipDownloader(httpClientManager: httpClientManager);

    CacheService? cacheService;
    if (effectiveConfig.enableCache) {
      cacheService = CacheService(
        cacheDirectory: effectiveConfig.cacheDirectory,
        maxAge: effectiveConfig.cacheDuration,
      );
    }

    IsolatePool? isolatePool;
    if (effectiveConfig.enableIsolatePool) {
      isolatePool = IsolatePool(size: effectiveConfig.isolatePoolSize);
      await isolatePool.initialize();
    }

    final repositoryAnalyzer = RepositoryAnalyzer(
      config: effectiveConfig,
      isolatePool: isolatePool,
    );

    final localAnalyzer = LocalAnalyzerService(
      config: effectiveConfig,
      repositoryAnalyzer: repositoryAnalyzer,
    );

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

  /// Analyzes a local directory recursively.
  ///
  /// Scans all files in the directory and returns comprehensive analysis
  /// including file list, statistics, and dependencies.
  Future<AnalysisResult> analyzeLocal(String directoryPath) async {
    logger.info('Starting local analysis: $directoryPath');
    _emitProgress(0.0, 'Starting local analysis', AnalysisPhase.initializing);

    final result = await localAnalyzer.analyze(directoryPath);

    _emitProgress(1.0, 'Local analysis completed', AnalysisPhase.completed);
    return result;
  }

  /// Analyzes a remote GitHub repository.
  ///
  /// Downloads and analyzes the specified repository. Supports both public
  /// and private repositories with automatic branch detection or explicit
  /// branch specification.
  Future<AnalysisResult> analyzeRemote({
    required String repositoryUrl,
    String? branch,
    bool? useCache,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');

    final remoteServiceWithProgress = remoteAnalyzer.copyWith(
      progressController: _progressController,
    );

    final effectiveUseCache = useCache ?? config.enableCache;

    final result = await remoteServiceWithProgress.analyze(
      repositoryUrl: repositoryUrl,
      branch: branch,
      useCache: effectiveUseCache,
    );

    return result;
  }

  /// Analyzes a target (auto-detects local path or remote URL).
  ///
  /// Automatically routes to [analyzeLocal] or [analyzeRemote] based on
  /// whether target is a URL or local path.
  Future<AnalysisResult> analyze(
    String target, {
    String? branch,
    bool? useCache,
  }) async {
    if (target.startsWith('http') || target.startsWith('git')) {
      return await analyzeRemote(
        repositoryUrl: target,
        branch: branch,
        useCache: useCache,
      );
    } else {
      return await analyzeLocal(target);
    }
  }

  /// Fetches only repository metadata without file analysis.
  ///
  /// Lightweight operation that queries GitHub API for basic repository
  /// information. Useful for quick metadata lookups without full analysis.
  Future<RepositoryMetadata> fetchMetadataOnly(
    String repositoryUrl, {
    String? branch,
  }) async {
    logger.info('Fetching metadata only: $repositoryUrl');
    _emitProgress(
      0.0,
      'Fetching repository metadata',
      AnalysisPhase.initializing,
    );

    try {
      final uri = Uri.parse(repositoryUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        throw AnalyzerException(
          'Invalid repository URL format. Expected: https://github.com/owner/repo',
          code: AnalyzerErrorCode.invalidUrl,
          details: 'URL must contain owner and repository name',
        );
      }

      final owner = pathSegments[0];
      final repo = pathSegments[1].replaceAll('.git', '');

      logger.fine('Parsed repository: $owner/$repo');

      _emitProgress(0.5, 'Querying GitHub API', AnalysisPhase.downloading);

      var metadata = await apiProvider.getRepositoryMetadata(owner, repo);

      if (branch != null) {
        logger.fine('Fetching commit SHA for branch: $branch');

        final commitSha = await apiProvider.getCommitShaForBranch(
          owner,
          repo,
          branch,
        );

        metadata = metadata.copyWith(
          commitSha: commitSha,
          defaultBranch: branch,
        );
      }

      _emitProgress(
        1.0,
        'Metadata fetched successfully',
        AnalysisPhase.completed,
      );
      logger.info('Metadata fetched successfully: ${metadata.name}');
      return metadata;
    } catch (e, stackTrace) {
      _emitProgress(0.0, 'Failed to fetch metadata: $e', AnalysisPhase.error);

      if (e is AnalyzerException) {
        rethrow;
      }

      logger.severe('Failed to fetch metadata', e, stackTrace);
      throw AnalyzerException(
        'Failed to fetch repository metadata',
        code: AnalyzerErrorCode.analysisError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clears all cached analysis results.
  Future<void> clearCache() async {
    if (cacheService != null) {
      await cacheService!.clear();
      logger.info('Cache cleared');
    }
  }

  /// Returns cache statistics or null if caching is disabled.
  Future<Map<String, dynamic>?> getCacheStatistics() async {
    return await cacheService?.getStatistics();
  }

  /// Disposes all resources and closes streams.
  ///
  /// Must be called when analyzer is no longer needed to prevent resource leaks.
  Future<void> dispose() async {
    _progressController.close();
    httpClientManager.dispose();
    isolatePool?.dispose();
    logger.info('GithubAnalyzer disposed');
  }

  /// Emits a progress update with the specified parameters.
  void _emitProgress(double progress, String message, AnalysisPhase phase) {
    _progressController.add(
      AnalysisProgress(
        phase: phase,
        progress: progress,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }
}
