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
  final bool autoLoadEnv;

  // 🆕 추가된 필드들
  final bool enableFileCache;
  final int autoIsolatePoolThreshold;
  final int streamingModeThreshold;

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
    // 🆕 추가된 기본값들
    this.enableFileCache = true,
    this.autoIsolatePoolThreshold = 100,
    this.streamingModeThreshold = 50 * 1024 * 1024, // 50MB
  });

  /// Validates configuration parameters
  static void _validateConfig({
    required int maxFileSize,
    required int maxConcurrentRequests,
    required int isolatePoolSize,
    required int maxRetries,
    required Duration retryDelay,
    required Duration cacheDuration,
    required int maxTotalFiles,
    required String cacheDirectory,
    required int autoIsolatePoolThreshold,
    required int streamingModeThreshold,
  }) {
    // Validate maxFileSize
    if (maxFileSize <= 0) {
      throw ArgumentError.value(
        maxFileSize,
        'maxFileSize',
        'Must be greater than 0',
      );
    }

    // Validate maxConcurrentRequests
    if (maxConcurrentRequests <= 0) {
      throw ArgumentError.value(
        maxConcurrentRequests,
        'maxConcurrentRequests',
        'Must be greater than 0',
      );
    }

    if (maxConcurrentRequests > 20) {
      throw ArgumentError.value(
        maxConcurrentRequests,
        'maxConcurrentRequests',
        'Must be 20 or less to avoid rate limiting',
      );
    }

    // Validate isolatePoolSize
    if (isolatePoolSize <= 0) {
      throw ArgumentError.value(
        isolatePoolSize,
        'isolatePoolSize',
        'Must be greater than 0',
      );
    }

    if (isolatePoolSize > 16) {
      throw ArgumentError.value(
        isolatePoolSize,
        'isolatePoolSize',
        'Must be 16 or less to avoid excessive resource usage',
      );
    }

    // Validate maxRetries
    if (maxRetries < 0) {
      throw ArgumentError.value(
        maxRetries,
        'maxRetries',
        'Must be 0 or greater',
      );
    }

    if (maxRetries > 10) {
      throw ArgumentError.value(
        maxRetries,
        'maxRetries',
        'Must be 10 or less to avoid excessive retries',
      );
    }

    // Validate retryDelay
    if (retryDelay.isNegative) {
      throw ArgumentError.value(
        retryDelay,
        'retryDelay',
        'Must not be negative',
      );
    }

    if (retryDelay.inSeconds > 60) {
      throw ArgumentError.value(
        retryDelay,
        'retryDelay',
        'Must be 60 seconds or less',
      );
    }

    // Validate cacheDuration
    if (cacheDuration.isNegative) {
      throw ArgumentError.value(
        cacheDuration,
        'cacheDuration',
        'Must not be negative',
      );
    }

    // Validate maxTotalFiles
    if (maxTotalFiles < 0) {
      throw ArgumentError.value(
        maxTotalFiles,
        'maxTotalFiles',
        'Must be 0 or greater (0 means unlimited)',
      );
    }

    // Validate cacheDirectory
    if (cacheDirectory.isEmpty) {
      throw ArgumentError.value(
        cacheDirectory,
        'cacheDirectory',
        'Must not be empty',
      );
    }

    if (cacheDirectory.contains('..')) {
      throw ArgumentError.value(
        cacheDirectory,
        'cacheDirectory',
        'Must not contain parent directory references (..)',
      );
    }

    // 🆕 Validate autoIsolatePoolThreshold
    if (autoIsolatePoolThreshold < 0) {
      throw ArgumentError.value(
        autoIsolatePoolThreshold,
        'autoIsolatePoolThreshold',
        'Must be 0 or greater',
      );
    }

    // 🆕 Validate streamingModeThreshold
    if (streamingModeThreshold <= 0) {
      throw ArgumentError.value(
        streamingModeThreshold,
        'streamingModeThreshold',
        'Must be greater than 0',
      );
    }
  }

  /// Creates a configuration instance (without .env auto-loading)
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
    bool autoLoadEnv = true, // ⚠️ Deprecated: kept for backward compatibility
    // 🆕 추가 파라미터들
    bool enableFileCache = true,
    int autoIsolatePoolThreshold = 100,
    int streamingModeThreshold = 50 * 1024 * 1024, // 50MB
  }) async {
    // ✅ .env 자동 로드 제거 (macOS 샌드박스 이슈)
    // 사용자가 githubToken 파라미터로 직접 전달해야 함

    final size = isolatePoolSize ?? 4;
    final effectiveCacheDir = cacheDirectory ?? '.github_analyzer_cache';

    // Validate configuration
    _validateConfig(
      maxFileSize: maxFileSize,
      maxConcurrentRequests: maxConcurrentRequests,
      isolatePoolSize: size,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      cacheDuration: cacheDuration,
      maxTotalFiles: maxTotalFiles,
      cacheDirectory: effectiveCacheDir,
      autoIsolatePoolThreshold: autoIsolatePoolThreshold,
      streamingModeThreshold: streamingModeThreshold,
    );

    return GithubAnalyzerConfig._private(
      githubToken: githubToken, // ✅ 파라미터로 전달된 값만 사용
      excludePatterns: excludePatterns ?? kDefaultExcludePatterns,
      includePatterns: includePatterns ?? const [],
      maxFileSize: maxFileSize,
      enableCache: enableCache,
      cacheDirectory: effectiveCacheDir,
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
      enableFileCache: enableFileCache,
      autoIsolatePoolThreshold: autoIsolatePoolThreshold,
      streamingModeThreshold: streamingModeThreshold,
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
    bool autoLoadEnv = false, // ⚠️ Deprecated: kept for backward compatibility
    // 🆕 추가 파라미터들
    bool enableFileCache = true,
    int autoIsolatePoolThreshold = 100,
    int streamingModeThreshold = 50 * 1024 * 1024,
  }) {
    // ✅ .env 로드 제거 - githubToken 파라미터만 사용
    final size = isolatePoolSize ?? 4;
    final effectiveCacheDir = cacheDirectory ?? '.github_analyzer_cache';

    // Validate configuration
    _validateConfig(
      maxFileSize: maxFileSize,
      maxConcurrentRequests: maxConcurrentRequests,
      isolatePoolSize: size,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      cacheDuration: cacheDuration,
      maxTotalFiles: maxTotalFiles,
      cacheDirectory: effectiveCacheDir,
      autoIsolatePoolThreshold: autoIsolatePoolThreshold,
      streamingModeThreshold: streamingModeThreshold,
    );

    return GithubAnalyzerConfig._private(
      githubToken: githubToken, // ✅ 파라미터로 전달된 값만 사용
      excludePatterns: excludePatterns ?? kDefaultExcludePatterns,
      includePatterns: includePatterns ?? const [],
      maxFileSize: maxFileSize,
      enableCache: enableCache,
      cacheDirectory: effectiveCacheDir,
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
      enableFileCache: enableFileCache,
      autoIsolatePoolThreshold: autoIsolatePoolThreshold,
      streamingModeThreshold: streamingModeThreshold,
    );
  }

  /// Quick analysis factory
  static Future<GithubAnalyzerConfig> quick({
    String? githubToken,
    List<String>? excludePatterns,
  }) async {
    // ✅ .env 자동 로드 제거

    return GithubAnalyzerConfig._private(
      githubToken: githubToken, // ✅ 파라미터로 전달된 값만 사용
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
      enableFileCache: false,
      autoIsolatePoolThreshold: 100,
      streamingModeThreshold: 50 * 1024 * 1024,
    );
  }

  /// LLM-optimized factory
  static Future<GithubAnalyzerConfig> forLLM({
    String? githubToken,
    List<String>? excludePatterns,
    int maxFiles = 200,
  }) async {
    // ✅ .env 자동 로드 제거

    // Validate maxFiles
    if (maxFiles < 0) {
      throw ArgumentError.value(maxFiles, 'maxFiles', 'Must be 0 or greater');
    }

    return GithubAnalyzerConfig._private(
      githubToken: githubToken, // ✅ 파라미터로 전달된 값만 사용
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
      enableFileCache: true,
      autoIsolatePoolThreshold: 100,
      streamingModeThreshold: 50 * 1024 * 1024,
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

  /// 🆕 Determine if streaming mode should be used based on archive size
  bool shouldUseStreamingMode({required int estimatedSize}) {
    return estimatedSize >= streamingModeThreshold;
  }

  /// Validates if the current configuration is valid
  bool get isValid {
    try {
      _validateConfig(
        maxFileSize: maxFileSize,
        maxConcurrentRequests: maxConcurrentRequests,
        isolatePoolSize: isolatePoolSize,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        cacheDuration: cacheDuration,
        maxTotalFiles: maxTotalFiles,
        cacheDirectory: cacheDirectory,
        autoIsolatePoolThreshold: autoIsolatePoolThreshold,
        streamingModeThreshold: streamingModeThreshold,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String toString() {
    return 'GithubAnalyzerConfig('
        'maxFileSize: $maxFileSize, '
        'maxConcurrentRequests: $maxConcurrentRequests, '
        'isolatePoolSize: $isolatePoolSize, '
        'maxRetries: $maxRetries, '
        'enableCache: $enableCache, '
        'maxTotalFiles: $maxTotalFiles, '
        'autoIsolatePoolThreshold: $autoIsolatePoolThreshold'
        ')';
  }
}
