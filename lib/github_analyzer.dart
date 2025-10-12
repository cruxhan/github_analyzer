library;

import 'dart:async';

import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/data/providers/github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/github_analyzer.dart';
import 'package:github_analyzer/src/infrastructure/http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';

export 'src/common/config.dart';
export 'src/common/errors/analyzer_exception.dart';
export 'src/common/logger.dart';
// Public API Exports
export 'src/github_analyzer.dart' show GithubAnalyzer;
// Domain Models
export 'src/models/analysis_error.dart';
export 'src/models/analysis_progress.dart';
export 'src/models/analysis_result.dart';
export 'src/models/analysis_statistics.dart';
export 'src/models/repository_metadata.dart';
export 'src/models/source_file.dart';
// Utilities
export 'src/common/utils/cfs_writer.dart';
export 'src/common/utils/context_generator.dart';
export 'src/common/utils/metadata_generator.dart';

/// Analyzes a GitHub repository from a URL with a single function call.
///
/// This is the simplest way to use the package. It automatically handles all
/// setup and teardown, including dependency injection and resource disposal.
///
/// A [config] can be optionally provided for advanced customization.
/// A [progressCallback] can be provided to listen for [AnalysisProgress] updates.
///
/// Example:
/// ```dart
/// final result = await analyze('[https://github.com/user/repo](https://github.com/user/repo)');
/// print('Analyzed ${result.files.length} files.');
/// ```
Future<AnalysisResult> analyze(
  String repositoryUrl, {
  GithubAnalyzerConfig? config,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
}) async {
  setupLogger(verbose: verbose);

  // Use the provided config or create a default one.
  final effectiveConfig = config ?? GithubAnalyzerConfig();

  // Create all necessary services.
  final httpClientManager = HttpClientManager();
  final apiProvider = GithubApiProvider(
    httpClientManager: httpClientManager,
    token: effectiveConfig.githubToken,
  );
  final zipDownloader = ZipDownloader(httpClientManager: httpClientManager);
  final cacheService = effectiveConfig.enableCache
      ? CacheService(
          cacheDirectory: effectiveConfig.cacheDirectory,
          maxAge: effectiveConfig.cacheDuration,
        )
      : null;
  final isolatePool = effectiveConfig.enableIsolatePool
      ? IsolatePool(size: effectiveConfig.isolatePoolSize)
      : null;
  final localAnalyzer = LocalAnalyzerService(config: effectiveConfig);
  final remoteAnalyzer = RemoteAnalyzerService(
    config: effectiveConfig,
    apiProvider: apiProvider,
    zipDownloader: zipDownloader,
    cacheService: cacheService,
  );

  final analyzer = GithubAnalyzer(
    config: effectiveConfig,
    httpClientManager: httpClientManager,
    apiProvider: apiProvider,
    zipDownloader: zipDownloader,
    localAnalyzer: localAnalyzer,
    remoteAnalyzer: remoteAnalyzer,
    cacheService: cacheService,
    isolatePool: isolatePool,
  );

  StreamSubscription<AnalysisProgress>? progressSubscription;
  if (progressCallback != null) {
    progressSubscription = analyzer.progressStream.listen(progressCallback);
  }

  try {
    return await analyzer.analyze(repositoryUrl);
  } finally {
    await progressSubscription?.cancel();
    await analyzer.dispose();
  }
}
