import 'package:github_analyzer/src/common/constants.dart';
import 'package:github_analyzer/src/common/env_loader.dart';

/// Configuration class for the GithubAnalyzer
class GithubAnalyzerConfig {
  final String? githubToken;
  final List<String> excludePatterns;
  final List<String> includePatterns;
  final int maxFileSize;
  final bool enableCache;
  final String cacheDirectory;
  final Duration cacheDuration;
  final int maxConcurrentRequests;
  final bool enableIsolatePool;
  final int isolatePoolSize;
  final int maxRetries;
  final Duration retryDelay;
  final bool excludeGeneratedFiles;
  final int maxTotalFiles;
  final bool prioritizeImportantFiles;
  final bool autoLoadEnv;

  const GithubAnalyzerConfig._private({
    this.githubToken,
    required this.excludePatterns,
    this.includePatterns = const [],
    this.maxFileSize = kDefaultMaxFileSize,
    this.enableCache = true,
    required this.cacheDirectory,
    this.cacheDuration = kDefaultCacheDuration,
    this.maxConcurrentRequests = kDefaultMaxConcurrentRequests,
    this.enableIsolatePool = true,
    this.isolatePoolSize = 4,
    this.maxRetries = kDefaultMaxRetries,
    this.retryDelay = const Duration(seconds: 2),
    this.excludeGeneratedFiles = true,
    this.maxTotalFiles = 0,
    this.prioritizeImportantFiles = true,
    this.autoLoadEnv = true,
  });

  /// Creates a configuration instance with automatic .env loading
  static Future<GithubAnalyzerConfig> create({
    String? githubToken,
    List<String>? excludePatterns,
    List<String>? includePatterns,
    int maxFileSize = kDefaultMaxFileSize,
    bool enableCache = true,
    String? cacheDirectory,
    Duration cacheDuration = kDefaultCacheDuration,
    int maxConcurrentRequests = kDefaultMaxConcurrentRequests,
    bool enableIsolatePool = true,
    int? isolatePoolSize,
    int maxRetries = kDefaultMaxRetries,
    Duration retryDelay = const Duration(seconds: 2),
    bool excludeGeneratedFiles = true,
    int maxTotalFiles = 0,
    bool prioritizeImportantFiles = true,
    bool autoLoadEnv = true,
  }) async {
    // Auto-load .env file if enabled
    if (autoLoadEnv) {
      await EnvLoader.load();
    }

    // Use provided token or try to load from environment
    final effectiveToken = githubToken ?? EnvLoader.getGithubToken();

    final size = isolatePoolSize ?? 4;

    return GithubAnalyzerConfig._private(
      githubToken: effectiveToken,
      excludePatterns: excludePatterns ?? kDefaultExcludePatterns,
      includePatterns: includePatterns ?? const [],
      maxFileSize: maxFileSize,
      enableCache: enableCache,
      cacheDirectory: cacheDirectory ?? '.github_analyzer_cache',
      cacheDuration: cacheDuration,
      maxConcurrentRequests: maxConcurrentRequests,
      enableIsolatePool: enableIsolatePool,
      isolatePoolSize: size,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      excludeGeneratedFiles: excludeGeneratedFiles,
      maxTotalFiles: maxTotalFiles,
      prioritizeImportantFiles: prioritizeImportantFiles,
      autoLoadEnv: autoLoadEnv,
    );
  }

  /// Synchronous factory (without auto-load)
  factory GithubAnalyzerConfig({
    String? githubToken,
    List<String>? excludePatterns,
    List<String>? includePatterns,
    int maxFileSize = kDefaultMaxFileSize,
    bool enableCache = true,
    String? cacheDirectory,
    Duration cacheDuration = kDefaultCacheDuration,
    int maxConcurrentRequests = kDefaultMaxConcurrentRequests,
    bool enableIsolatePool = true,
    int? isolatePoolSize,
    int maxRetries = kDefaultMaxRetries,
    Duration retryDelay = const Duration(seconds: 2),
    bool excludeGeneratedFiles = true,
    int maxTotalFiles = 0,
    bool prioritizeImportantFiles = true,
    bool autoLoadEnv = false,
  }) {
    // Try to load from already loaded env
    final effectiveToken = githubToken ?? EnvLoader.get('GITHUB_TOKEN');
    final size = isolatePoolSize ?? 4;

    return GithubAnalyzerConfig._private(
      githubToken: effectiveToken,
      excludePatterns: excludePatterns ?? kDefaultExcludePatterns,
      includePatterns: includePatterns ?? const [],
      maxFileSize: maxFileSize,
      enableCache: enableCache,
      cacheDirectory: cacheDirectory ?? '.github_analyzer_cache',
      cacheDuration: cacheDuration,
      maxConcurrentRequests: maxConcurrentRequests,
      enableIsolatePool: enableIsolatePool,
      isolatePoolSize: size,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      excludeGeneratedFiles: excludeGeneratedFiles,
      maxTotalFiles: maxTotalFiles,
      prioritizeImportantFiles: prioritizeImportantFiles,
      autoLoadEnv: autoLoadEnv,
    );
  }

  /// Quick analysis factory
  static Future<GithubAnalyzerConfig> quick({
    String? githubToken,
    List<String>? excludePatterns,
  }) async {
    await EnvLoader.load();
    final effectiveToken = githubToken ?? EnvLoader.getGithubToken();

    return GithubAnalyzerConfig._private(
      githubToken: effectiveToken,
      excludePatterns: excludePatterns ?? kDefaultExcludePatterns,
      includePatterns: const [],
      maxFileSize: kDefaultMaxFileSize,
      enableCache: false,
      cacheDirectory: '.github_analyzer_cache',
      cacheDuration: kDefaultCacheDuration,
      maxConcurrentRequests: kDefaultMaxConcurrentRequests,
      enableIsolatePool: false,
      isolatePoolSize: 2,
      maxRetries: kDefaultMaxRetries,
      retryDelay: const Duration(seconds: 2),
      excludeGeneratedFiles: true,
      maxTotalFiles: 100,
      prioritizeImportantFiles: true,
      autoLoadEnv: true,
    );
  }

  /// LLM-optimized factory
  static Future<GithubAnalyzerConfig> forLLM({
    String? githubToken,
    List<String>? excludePatterns,
    int maxFiles = 200,
  }) async {
    await EnvLoader.load();
    final effectiveToken = githubToken ?? EnvLoader.getGithubToken();

    return GithubAnalyzerConfig._private(
      githubToken: effectiveToken,
      excludePatterns: [
        ...kDefaultExcludePatterns,
        ...?excludePatterns,
        'test/',
        'tests/',
        '**test.dart',
        'example/',
      ],
      includePatterns: const [],
      maxFileSize: kDefaultMaxFileSize,
      enableCache: true,
      cacheDirectory: '.github_analyzer_cache',
      cacheDuration: kDefaultCacheDuration,
      maxConcurrentRequests: kDefaultMaxConcurrentRequests,
      enableIsolatePool: true,
      isolatePoolSize: 4,
      maxRetries: kDefaultMaxRetries,
      retryDelay: const Duration(seconds: 2),
      excludeGeneratedFiles: true,
      maxTotalFiles: maxFiles,
      prioritizeImportantFiles: true,
      autoLoadEnv: true,
    );
  }

  /// Get effective exclude patterns including generated files
  List<String> get effectiveExcludePatterns {
    if (!excludeGeneratedFiles) return excludePatterns;

    return [
      ...excludePatterns,
      '**.g.dart',
      '**.freezed.dart',
      '**.gr.dart',
      '**.config.dart',
      '**.pb.dart',
      '**.pbenum.dart',
      '**.pbgrpc.dart',
      '**.pbjson.dart',
    ];
  }
}
