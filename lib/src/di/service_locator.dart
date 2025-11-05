import 'package:get_it/get_it.dart';

import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/incremental_analyzer.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/data/providers/github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/infrastructure/http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/services/context_service.dart';
import 'package:github_analyzer/src/services/markdown_service.dart';

/// Service locator instance
final getIt = GetIt.instance;

/// Initializes all dependencies for the github analyzer
Future<void> setupDependencies({GithubAnalyzerConfig? config}) async {
  // ✅ 새 config가 제공되고 이미 등록되어 있으면 재초기화
  if (config != null && getIt.isRegistered<GithubAnalyzerConfig>()) {
    final existingConfig = getIt<GithubAnalyzerConfig>();

    // ✅ 토큰이 다르면 전체 재초기화
    if (existingConfig.githubToken != config.githubToken) {
      await getIt.reset();
    } else {
      // 토큰이 같으면 재초기화 불필요
      return;
    }
  } else if (getIt.isRegistered<GithubAnalyzerConfig>()) {
    // config가 없고 이미 초기화되어 있으면 그대로 사용
    return;
  }

  // Register configuration
  final effectiveConfig = config ?? await GithubAnalyzerConfig.create();
  getIt.registerSingleton<GithubAnalyzerConfig>(effectiveConfig);

  // Register HTTP client manager
  getIt.registerLazySingleton<IHttpClientManager>(
    () => HttpClientManager(
      requestTimeout: const Duration(seconds: 30),
      maxConcurrentRequests: effectiveConfig.maxConcurrentRequests,
      maxRetries: effectiveConfig.maxRetries,
    ),
  );

  // Register GitHub API provider
  getIt.registerLazySingleton<IGithubApiProvider>(
    () => GithubApiProvider(
      httpClientManager: getIt<IHttpClientManager>(),
      token: effectiveConfig.githubToken,
    ),
  );

  // Register ZIP downloader
  getIt.registerLazySingleton<ZipDownloader>(
    () => ZipDownloader(httpClientManager: getIt<IHttpClientManager>()),
  );

  // Register cache service if enabled
  if (effectiveConfig.enableCache) {
    final cacheService = CacheService(
      cacheDirectory: effectiveConfig.cacheDirectory,
      maxAge: effectiveConfig.cacheDuration,
    );
    // await cacheService.initialize();
    getIt.registerSingleton<CacheService>(cacheService);
  }

  // Register isolate pool if enabled
  if (effectiveConfig.enableIsolatePool) {
    final isolatePool = IsolatePool(size: effectiveConfig.isolatePoolSize);
    await isolatePool.initialize();
    getIt.registerSingleton<IsolatePool>(isolatePool);
  }

  // Register repository analyzer
  getIt.registerLazySingleton<RepositoryAnalyzer>(
    () => RepositoryAnalyzer(
      config: getIt<GithubAnalyzerConfig>(),
      isolatePool: getIt.isRegistered<IsolatePool>()
          ? getIt<IsolatePool>()
          : null,
    ),
  );

  // Register incremental analyzer with cache service
  getIt.registerLazySingleton<IncrementalAnalyzer>(
    () => IncrementalAnalyzer(
      config: getIt<GithubAnalyzerConfig>(),
      cacheService: getIt.isRegistered<CacheService>()
          ? getIt<CacheService>()
          : null,
    ),
  );

  // Register local analyzer service
  getIt.registerLazySingleton<LocalAnalyzerService>(
    () => LocalAnalyzerService(
      config: getIt<GithubAnalyzerConfig>(),
      repositoryAnalyzer: getIt<RepositoryAnalyzer>(),
    ),
  );

  // Register remote analyzer service
  getIt.registerLazySingleton<RemoteAnalyzerService>(
    () => RemoteAnalyzerService(
      config: getIt<GithubAnalyzerConfig>(),
      apiProvider: getIt<IGithubApiProvider>(),
      zipDownloader: getIt<ZipDownloader>(),
      cacheService: getIt.isRegistered<CacheService>()
          ? getIt<CacheService>()
          : null,
    ),
  );

  // Register context service
  getIt.registerLazySingleton<ContextService>(() => ContextService());

  // Register markdown service
  getIt.registerLazySingleton<MarkdownService>(() => MarkdownService());
}

/// Disposes all registered dependencies
Future<void> disposeDependencies() async {
  if (getIt.isRegistered<IsolatePool>()) {
    getIt<IsolatePool>().dispose();
  }

  if (getIt.isRegistered<IHttpClientManager>()) {
    getIt<IHttpClientManager>().dispose();
  }

  await getIt.reset();
}
