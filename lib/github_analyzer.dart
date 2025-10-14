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
import 'package:github_analyzer/src/common/utils/context_generator.dart';
import 'package:github_analyzer/src/common/utils/markdown_generator.dart';

export 'src/common/config.dart';
export 'src/common/errors/analyzer_exception.dart';
export 'src/common/logger.dart';
export 'src/github_analyzer.dart' show GithubAnalyzer;
export 'src/models/analysis_error.dart';
export 'src/models/analysis_progress.dart';
export 'src/models/analysis_result.dart';
export 'src/models/analysis_statistics.dart';
export 'src/models/repository_metadata.dart';
export 'src/models/source_file.dart';
export 'src/common/utils/context_generator.dart';
export 'src/common/utils/markdown_generator.dart';

/// Analyzes a repository and returns the analysis result
Future<AnalysisResult> analyze(
  String repositoryUrl, {
  GithubAnalyzerConfig? config,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
}) async {
  setupLogger(verbose: verbose);

  final effectiveConfig = config ?? GithubAnalyzerConfig();

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

/// Analyzes a repository and generates markdown output in one step
Future<String> analyzeAndGenerate(
  String repositoryUrl, {
  String? outputPath,
  String? outputDir,
  GithubAnalyzerConfig? analyzerConfig,
  MarkdownConfig markdownConfig = MarkdownConfig.standard,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
}) async {
  final result = await analyze(
    repositoryUrl,
    config: analyzerConfig,
    progressCallback: progressCallback,
    verbose: verbose,
  );

  return await ContextGenerator.generate(
    result,
    outputPath: outputPath,
    outputDir: outputDir,
    config: markdownConfig,
  );
}

/// Quick analysis with optimized settings for fast results
Future<AnalysisResult> analyzeQuick(
  String repositoryUrl, {
  String? githubToken,
  void Function(AnalysisProgress)? progressCallback,
}) async {
  return await analyze(
    repositoryUrl,
    config: GithubAnalyzerConfig.quick(githubToken: githubToken),
    progressCallback: progressCallback,
  );
}

/// Analysis optimized for LLM context generation
Future<String> analyzeForLLM(
  String repositoryUrl, {
  String? outputPath,
  String? outputDir,
  String? githubToken,
  int maxFiles = 200,
  MarkdownConfig markdownConfig = MarkdownConfig.standard,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
}) async {
  final result = await analyze(
    repositoryUrl,
    config: GithubAnalyzerConfig.forLLM(
      githubToken: githubToken,
      maxFiles: maxFiles,
    ),
    progressCallback: progressCallback,
    verbose: verbose,
  );

  return await ContextGenerator.generate(
    result,
    outputPath: outputPath,
    outputDir: outputDir,
    config: markdownConfig,
  );
}
