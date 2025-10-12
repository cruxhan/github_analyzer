import 'dart:io';
import 'dart:convert';
import 'package:github_analyzer/src/common/constants.dart';

/// Configuration class for the GithubAnalyzer.
///
/// This class holds all the settings that control the behavior of the analysis,
/// such as API tokens, file exclusion patterns, cache settings, and concurrency
/// limits.
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

  /// Creates an instance of [GithubAnalyzerConfig].
  GithubAnalyzerConfig({
    this.githubToken,
    List<String>? excludePatterns,
    this.includePatterns = const [],
    this.maxFileSize = kDefaultMaxFileSize,
    this.enableCache = true,
    String? cacheDirectory,
    this.cacheDuration = kDefaultCacheDuration,
    this.maxConcurrentRequests = kDefaultMaxConcurrentRequests,
    this.enableIsolatePool = true,
    int? isolatePoolSize,
    this.maxRetries = kDefaultMaxRetries,
    this.retryDelay = const Duration(seconds: 2),
  })  : excludePatterns = excludePatterns ?? kDefaultExcludePatterns,
        cacheDirectory = cacheDirectory ?? '.github_analyzer_cache',
        isolatePoolSize = isolatePoolSize ?? (Platform.numberOfProcessors);

  /// Creates a [GithubAnalyzerConfig] from a JSON file.
  factory GithubAnalyzerConfig.fromFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Config file not found: $path');
    }
    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return GithubAnalyzerConfig.fromJson(json);
  }

  /// Creates a [GithubAnalyzerConfig] from a JSON map.
  factory GithubAnalyzerConfig.fromJson(Map<String, dynamic> json) {
    return GithubAnalyzerConfig(
      githubToken: json['githubToken'] as String?,
      excludePatterns: (json['excludePatterns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      includePatterns: (json['includePatterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxFileSize: json['maxFileSize'] as int? ?? kDefaultMaxFileSize,
      enableCache: json['enableCache'] as bool? ?? true,
      cacheDirectory:
          json['cacheDirectory'] as String? ?? '.github_analyzer_cache',
      cacheDuration: json['cacheDuration'] != null
          ? Duration(seconds: json['cacheDuration'] as int)
          : kDefaultCacheDuration,
      maxConcurrentRequests: json['maxConcurrentRequests'] as int? ??
          kDefaultMaxConcurrentRequests,
      enableIsolatePool: json['enableIsolatePool'] as bool? ?? true,
      isolatePoolSize:
          json['isolatePoolSize'] as int? ?? Platform.numberOfProcessors,
      maxRetries: json['max_retries'] as int? ?? kDefaultMaxRetries,
      retryDelay: json['retry_delay_seconds'] != null
          ? Duration(seconds: json['retry_delay_seconds'] as int)
          : const Duration(seconds: 2),
    );
  }

  /// Converts this config object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'githubToken': githubToken,
      'excludePatterns': excludePatterns,
      'includePatterns': includePatterns,
      'maxFileSize': maxFileSize,
      'enableCache': enableCache,
      'cacheDirectory': cacheDirectory,
      'cacheDuration': cacheDuration.inSeconds,
      'maxConcurrentRequests': maxConcurrentRequests,
      'enableIsolatePool': enableIsolatePool,
      'isolatePoolSize': isolatePoolSize,
      'max_retries': maxRetries,
      'retry_delay_seconds': retryDelay.inSeconds,
    };
  }

  /// Creates a copy of this config object with the given fields replaced.
  GithubAnalyzerConfig copyWith({
    String? githubToken,
    List<String>? excludePatterns,
    List<String>? includePatterns,
    int? maxFileSize,
    bool? enableCache,
    String? cacheDirectory,
    Duration? cacheDuration,
    int? maxConcurrentRequests,
    bool? enableIsolatePool,
    int? isolatePoolSize,
    int? maxRetries,
    Duration? retryDelay,
  }) {
    return GithubAnalyzerConfig(
      githubToken: githubToken ?? this.githubToken,
      excludePatterns: excludePatterns ?? this.excludePatterns,
      includePatterns: includePatterns ?? this.includePatterns,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      enableCache: enableCache ?? this.enableCache,
      cacheDirectory: cacheDirectory ?? this.cacheDirectory,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      maxConcurrentRequests:
          maxConcurrentRequests ?? this.maxConcurrentRequests,
      enableIsolatePool: enableIsolatePool ?? this.enableIsolatePool,
      isolatePoolSize: isolatePoolSize ?? this.isolatePoolSize,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}
