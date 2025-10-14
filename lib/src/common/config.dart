import 'package:github_analyzer/src/common/constants.dart';

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
  });

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
  }) {
    // Determine default isolate pool size based on platform
    final size = isolatePoolSize ?? _getDefaultIsolatePoolSize();

    return GithubAnalyzerConfig._private(
      githubToken: githubToken,
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
    );
  }

  /// Quick analysis factory for fast results
  factory GithubAnalyzerConfig.quick({
    String? githubToken,
    List<String>? excludePatterns,
  }) {
    return GithubAnalyzerConfig(
      githubToken: githubToken,
      excludePatterns: excludePatterns,
      enableCache: false,
      enableIsolatePool: false,
      maxTotalFiles: 100,
      excludeGeneratedFiles: true,
      prioritizeImportantFiles: true,
    );
  }

  /// Configuration optimized for LLM context generation
  factory GithubAnalyzerConfig.forLLM({
    String? githubToken,
    List<String>? excludePatterns,
    int maxFiles = 200,
  }) {
    return GithubAnalyzerConfig(
      githubToken: githubToken,
      excludePatterns: [
        ...kDefaultExcludePatterns,
        ...?excludePatterns,
        'test/',
        'tests/',
        '**test.dart',
        'example/',
      ],
      excludeGeneratedFiles: true,
      maxTotalFiles: maxFiles,
      prioritizeImportantFiles: true,
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

  /// Determine default isolate pool size based on platform
  static int _getDefaultIsolatePoolSize() {
    // For web platforms, use smaller pool size
    // This is a simple heuristic - adjust based on your needs
    return 4; // Default for all platforms
  }
}
