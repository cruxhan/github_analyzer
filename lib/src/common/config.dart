import 'package:github_analyzer/src/common/constants.dart';

/// Configuration for repository analyzer behavior and performance tuning.
///
/// Controls analysis settings, caching, concurrency, resource limits,
/// and optimization options. Create instances using factory constructors
/// like [create], [quick], or [forLLM] for preset configurations.

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
    this.enableFileCache = true,
    this.autoIsolatePoolThreshold = 100,
    this.streamingModeThreshold = 50 * 1024 * 1024,
  });

  /// Validates all configuration parameters for correctness.
  ///
  /// Throws [ArgumentError] if any parameter is invalid.
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
    _validatePositive(maxFileSize, 'maxFileSize');
    _validateRange(maxConcurrentRequests, 'maxConcurrentRequests', 1, 20);
    _validateRange(isolatePoolSize, 'isolatePoolSize', 1, 16);
    _validateRange(maxRetries, 'maxRetries', 0, 10);
    _validateNonNegative(retryDelay.inSeconds, 'retryDelay', 60);
    _validateNonNegative(cacheDuration.inSeconds, 'cacheDuration');
    _validateNonNegative(maxTotalFiles, 'maxTotalFiles');
    _validateNonEmpty(cacheDirectory, 'cacheDirectory');
    _validateNotContains(cacheDirectory, '..', 'cacheDirectory');
    _validateNonNegative(autoIsolatePoolThreshold, 'autoIsolatePoolThreshold');
    _validatePositive(streamingModeThreshold, 'streamingModeThreshold');
  }

  /// Validates that value is positive (> 0).
  static void _validatePositive(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'Must be greater than 0');
    }
  }

  /// Validates that value is in the specified range [min, max].
  static void _validateRange(int value, String name, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'Must be between $min and $max');
    }
  }

  /// Validates that value is non-negative and within max seconds.
  static void _validateNonNegative(
    int seconds,
    String name, [
    int? maxSeconds,
  ]) {
    if (seconds < 0) {
      throw ArgumentError.value(seconds, name, 'Must not be negative');
    }
    if (maxSeconds != null && seconds > maxSeconds) {
      throw ArgumentError.value(
        seconds,
        name,
        'Must be $maxSeconds seconds or less',
      );
    }
  }

  /// Validates that string is not empty.
  static void _validateNonEmpty(String value, String name) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty');
    }
  }

  /// Validates that string does not contain forbidden characters.
  static void _validateNotContains(
    String value,
    String forbidden,
    String name,
  ) {
    if (value.contains(forbidden)) {
      throw ArgumentError.value(value, name, 'Must not contain "$forbidden"');
    }
  }

  /// Creates default configuration with custom parameters.
  ///
  /// Validates all parameters and returns a configured instance.
  /// Use preset factories [quick] or [forLLM] for common configurations.
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
    bool enableFileCache = true,
    int autoIsolatePoolThreshold = 100,
    int streamingModeThreshold = 50 * 1024 * 1024,
  }) async {
    final size = isolatePoolSize ?? 4;
    final effectiveCacheDir = cacheDirectory ?? '.github_analyzer_cache';

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
      githubToken: githubToken,
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

  /// Synchronous factory for quick configuration without async overhead.
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
    bool enableFileCache = true,
    int autoIsolatePoolThreshold = 100,
    int streamingModeThreshold = 50 * 1024 * 1024,
  }) {
    final size = isolatePoolSize ?? 4;
    final effectiveCacheDir = cacheDirectory ?? '.github_analyzer_cache';

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
      githubToken: githubToken,
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

  /// Preset configuration optimized for fast analysis.
  ///
  /// Disables caching and parallelization for speed.
  /// Limits file count to 100.
  static Future<GithubAnalyzerConfig> quick({
    String? githubToken,
    List<String>? excludePatterns,
  }) async {
    return GithubAnalyzerConfig._private(
      githubToken: githubToken,
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

  /// Preset configuration optimized for LLM context generation.
  ///
  /// Enables caching and parallelization with customizable file limit.
  /// Excludes test and example directories by default.
  static Future<GithubAnalyzerConfig> forLLM({
    String? githubToken,
    List<String>? excludePatterns,
    int maxFiles = 200,
  }) async {
    if (maxFiles < 0) {
      throw ArgumentError.value(maxFiles, 'maxFiles', 'Must be 0 or greater');
    }

    return GithubAnalyzerConfig._private(
      githubToken: githubToken,
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

  /// Returns effective exclude patterns including generated file patterns.
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

  /// Determines if streaming mode should be used based on estimated size.
  bool shouldUseStreamingMode({required int estimatedSize}) {
    return estimatedSize >= streamingModeThreshold;
  }

  /// Checks if configuration is valid without throwing errors.
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
