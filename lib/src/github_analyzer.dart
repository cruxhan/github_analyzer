import 'dart:async';
import 'dart:io';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/data/services/cache_service.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/infrastructure/http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';

class GithubAnalyzer {
  final GithubAnalyzerConfig config;
  final AnalyzerLogger logger;

  late final HttpClientManager _httpClientManager;
  late final IGithubApiProvider _apiProvider;
  late final ZipDownloader _zipDownloader;
  late final LocalAnalyzerService _localAnalyzer;
  late final RemoteAnalyzerService _remoteAnalyzer;
  CacheService? _cacheService;
  IsolatePool? _isolatePool;

  final StreamController<AnalysisProgress> _progressController =
      StreamController.broadcast();

  Stream<AnalysisProgress> get progressStream => _progressController.stream;

  GithubAnalyzer({
    GithubAnalyzerConfig? config,
    HttpClientManager? httpClientManager,
    IGithubApiProvider? apiProvider,
    ZipDownloader? zipDownloader,
    LocalAnalyzerService? localAnalyzer,
    RemoteAnalyzerService? remoteAnalyzer,
    CacheService? cacheService,
    IsolatePool? isolatePool,
  }) : config = config ?? GithubAnalyzerConfig(),
       logger = AnalyzerLogger(verbose: config?.verbose ?? false) {
    _httpClientManager =
        httpClientManager ??
        HttpClientManager(
          logger: logger,
          requestTimeout: const Duration(seconds: 30),
          maxConcurrentRequests: this.config.maxConcurrentRequests,
          maxRetries: 3,
        );

    _apiProvider =
        apiProvider ??
        GithubApiProvider(
          token: this.config.githubToken,
          logger: logger,
          httpClientManager: _httpClientManager,
        );

    _zipDownloader =
        zipDownloader ??
        ZipDownloader(logger: logger, httpClientManager: _httpClientManager);

    if (this.config.enableCache) {
      _cacheService =
          cacheService ??
          CacheService(
            cacheDirectory: this.config.cacheDirectory,
            logger: logger,
            maxAge: this.config.cacheDuration,
          );
      _cacheService!.initialize();
    }

    if (this.config.enableIsolatePool) {
      _isolatePool =
          isolatePool ??
          IsolatePool(size: this.config.isolatePoolSize, logger: logger);
      _isolatePool!.initialize();
    }

    _localAnalyzer =
        localAnalyzer ??
        LocalAnalyzerService(config: this.config, logger: logger);

    _remoteAnalyzer =
        remoteAnalyzer ??
        RemoteAnalyzerService(
          config: this.config,
          logger: logger,
          apiProvider: _apiProvider,
          zipDownloader: _zipDownloader,
          cacheService: _cacheService,
          progressController: _progressController,
        );
  }

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

    final result = await _localAnalyzer.analyze(directoryPath);

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

  Future<AnalysisResult> analyzeRemote({
    required String repositoryUrl,
    String? branch,
    bool useCache = true,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');
    final result = await _remoteAnalyzer.analyze(
      repositoryUrl: repositoryUrl,
      branch: branch,
      useCache: useCache,
    );

    return result;
  }

  Future<AnalysisResult> analyze(String target, {String? branch}) async {
    // Basic check to differentiate between a URL and a local path.
    if (target.startsWith('http') || target.startsWith('git@')) {
      return await analyzeRemote(repositoryUrl: target, branch: branch);
    } else {
      return await analyzeLocal(target);
    }
  }

  Future<void> clearCache() async {
    if (_cacheService != null) {
      await _cacheService!.clear();
      logger.info('Cache cleared');
    }
  }

  Future<Map<String, dynamic>?> getCacheStatistics() async {
    return await _cacheService?.getStatistics();
  }

  Future<void> dispose() async {
    _progressController.close();
    _httpClientManager.dispose();
    _isolatePool?.dispose();
    if (_cacheService != null) {
      await _cacheService!.clear();
      final dir = Directory(config.cacheDirectory);
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
          logger.info('Cache directory removed: ${config.cacheDirectory}');
        } catch (e) {
          logger.error('Failed to delete cache directory: $e');
        }
      }
    }
    logger.info('GithubAnalyzer disposed');
  }
}
