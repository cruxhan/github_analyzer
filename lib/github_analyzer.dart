/// A Dart package for analyzing GitHub repositories and generating comprehensive documentation.
///
/// This library provides a set of high-level functions for analyzing both local and remote
/// GitHub repositories, with built-in support for caching, parallel processing, and
/// progress tracking.
///
/// ## Features
///
/// - Analyze GitHub repositories (both public and private)
/// - Generate markdown documentation optimized for LLM context
/// - Support for incremental analysis with caching
/// - Progress tracking with real-time updates
/// - Automatic language detection and statistics
/// - Directory tree generation
/// - Dependency extraction
///
/// ## Example
///
/// ```
/// import 'package:github_analyzer/github_analyzer.dart';
///
/// void main() async {
///   // Basic analysis
///   final result = await analyze('https://github.com/user/repo');
///   print('Found ${result.files.length} files');
///
///   // Analysis with markdown generation
///   final markdown = await analyzeAndGenerate(
///     'https://github.com/user/repo',
///     outputDir: './output',
///   );
///
///   // Quick analysis with minimal output
///   final quickResult = await analyzeQuick('https://github.com/user/repo');
///
///   // LLM-optimized analysis
///   final llmContext = await analyzeForLLM(
///     'https://github.com/user/repo',
///     githubToken: 'your-github-token',
///     maxFiles: 200,
///   );
/// }
/// ```
library;

import 'dart:async';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/di/service_locator.dart';
import 'package:github_analyzer/src/github_analyzer.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/services/context_service.dart';
import 'package:github_analyzer/src/services/markdown_service.dart';

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
export 'src/services/context_service.dart';
export 'src/services/markdown_service.dart';

/// Analyzes a GitHub repository and returns comprehensive analysis results.
///
/// This is the primary function for analyzing repositories. It supports both
/// local directories and remote GitHub repositories (public and private).
///
/// ## Parameters
///
/// - [repositoryUrl]: The GitHub repository URL (e.g., 'https://github.com/user/repo')
///   or a local directory path.
/// - [config]: Optional analyzer configuration. If not provided, default settings
///   will be used.
/// - [progressCallback]: Optional callback to receive real-time progress updates
///   during analysis.
/// - [verbose]: Whether to enable verbose logging. Defaults to `false`.
/// - [useCache]: Whether to use cached results if available. If `null`, uses the
///   config's cache setting.
///
/// ## Returns
///
/// A [Future] that completes with an [AnalysisResult] containing:
/// - Repository metadata (name, description, languages, etc.)
/// - List of analyzed source files with content and metadata
/// - Statistics (total files, lines, size, language breakdown)
/// - Directory tree structure
/// - Main entry point files
/// - Detected dependencies
/// - Any errors encountered during analysis
///
/// ## Example
///
/// ```
/// // Basic analysis with default settings
/// final result = await analyze('https://github.com/user/repo');
/// print('Total files: ${result.files.length}');
/// print('Total lines: ${result.statistics.totalLines}');
///
/// // Analysis with custom configuration
/// final customConfig = await GithubAnalyzerConfig.create(
///   githubToken: 'your-token',
///   maxFileSize: 500 * 1024, // 500KB
///   enableCache: true,
/// );
///
/// final result = await analyze(
///   'https://github.com/user/private-repo',
///   config: customConfig,
///   verbose: true,
/// );
///
/// // Analysis with progress tracking
/// final result = await analyze(
///   'https://github.com/user/repo',
///   progressCallback: (progress) {
///     print('${progress.phase}: ${progress.message}');
///     print('Progress: ${(progress.progress * 100).toStringAsFixed(1)}%');
///   },
/// );
/// ```
///
/// ## Throws
///
/// - [AnalyzerException] if the repository cannot be accessed or analyzed.
/// - [ArgumentError] if the repository URL is invalid.
///
/// See also:
/// - [analyzeAndGenerate] for analysis with markdown generation
/// - [analyzeQuick] for fast analysis with minimal output
/// - [analyzeForLLM] for LLM-optimized analysis
Future<AnalysisResult> analyze(
  String repositoryUrl, {
  GithubAnalyzerConfig? config,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
  bool? useCache,
}) async {
  setupLogger(verbose: verbose);

  // Setup dependencies using DI container
  await setupDependencies(config: config);

  final analyzer = await GithubAnalyzer.create(config: config);

  StreamSubscription<AnalysisProgress>? progressSubscription;
  if (progressCallback != null) {
    progressSubscription = analyzer.progressStream.listen(progressCallback);
  }

  try {
    return await analyzer.analyze(repositoryUrl, useCache: useCache);
  } finally {
    await progressSubscription?.cancel();
    await analyzer.dispose();
  }
}

/// Analyzes a repository and generates markdown documentation in one step.
///
/// This function combines repository analysis with markdown generation,
/// providing a convenient way to produce comprehensive documentation.
///
/// ## Parameters
///
/// - [repositoryUrl]: The GitHub repository URL or local directory path.
/// - [outputPath]: Optional specific file path for the output. If not provided,
///   the file will be saved in [outputDir] with an auto-generated name.
/// - [outputDir]: Directory where the markdown file should be saved. Defaults to
///   the current directory if not specified.
/// - [analyzerConfig]: Optional analyzer configuration for customizing the
///   analysis behavior.
/// - [markdownConfig]: Configuration for markdown generation. Defaults to
///   [MarkdownConfig.standard].
/// - [progressCallback]: Optional callback for progress updates.
/// - [verbose]: Whether to enable verbose logging. Defaults to `false`.
/// - [useCache]: Whether to use cached results if available.
///
/// ## Returns
///
/// A [Future] that completes with a [String] containing the path to the
/// generated markdown file.
///
/// ## Example
///
/// ```
/// // Basic usage with default settings
/// final outputPath = await analyzeAndGenerate(
///   'https://github.com/user/repo',
///   outputDir: './docs',
/// );
/// print('Documentation saved to: $outputPath');
///
/// // Custom markdown configuration
/// final customMarkdown = MarkdownConfig(
///   includeContent: true,
///   maxContentLength: 500,
///   includeStatistics: true,
///   includeDirectoryTree: true,
/// );
///
/// final outputPath = await analyzeAndGenerate(
///   'https://github.com/user/repo',
///   outputPath: './docs/README.md',
///   markdownConfig: customMarkdown,
/// );
///
/// // With custom analyzer config
/// final analyzerConfig = await GithubAnalyzerConfig.create(
///   githubToken: 'your-token',
///   maxFileSize: 1024 * 1024, // 1MB
/// );
///
/// final outputPath = await analyzeAndGenerate(
///   'https://github.com/user/private-repo',
///   outputDir: './output',
///   analyzerConfig: analyzerConfig,
///   markdownConfig: customMarkdown,
/// );
/// ```
///
/// ## Throws
///
/// - [AnalyzerException] if analysis fails.
/// - [FileSystemException] if the output directory cannot be accessed.
///
/// See also:
/// - [analyze] for analysis without markdown generation
/// - [analyzeForLLM] for LLM-optimized markdown output
Future<String> analyzeAndGenerate(
  String repositoryUrl, {
  String? outputPath,
  String? outputDir,
  GithubAnalyzerConfig? analyzerConfig,
  MarkdownConfig markdownConfig = MarkdownConfig.standard,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
  bool? useCache,
}) async {
  setupLogger(verbose: verbose);

  // Setup dependencies using DI container
  await setupDependencies(config: analyzerConfig);

  final analyzer = await GithubAnalyzer.create(config: analyzerConfig);

  StreamSubscription<AnalysisProgress>? progressSubscription;
  if (progressCallback != null) {
    progressSubscription = analyzer.progressStream.listen(progressCallback);
  }

  try {
    final result = await analyzer.analyze(repositoryUrl, useCache: useCache);

    // Use context service from DI container
    final contextService = getIt<ContextService>();
    return await contextService.generate(
      result,
      outputPath: outputPath,
      outputDir: outputDir,
      config: markdownConfig,
    );
  } finally {
    await progressSubscription?.cancel();
    await analyzer.dispose();
    await disposeDependencies();
  }
}

/// Performs a quick analysis with optimized settings for fast results.
///
/// This function uses pre-configured settings optimized for speed, making it
/// ideal for getting quick insights into a repository without comprehensive
/// analysis. It has reduced output and faster processing compared to the
/// standard [analyze] function.
///
/// ## Parameters
///
/// - [repositoryUrl]: The GitHub repository URL or local directory path.
/// - [githubToken]: Optional GitHub personal access token for accessing private
///   repositories or increasing API rate limits.
/// - [progressCallback]: Optional callback for progress updates.
/// - [useCache]: Whether to use cached results if available.
///
/// ## Returns
///
/// A [Future] that completes with an [AnalysisResult] containing basic
/// repository information and statistics.
///
/// ## Example
///
/// ```
/// // Quick analysis of a public repository
/// final result = await analyzeQuick('https://github.com/user/repo');
/// print('Languages: ${result.statistics.languageDistribution.keys.join(", ")}');
///
/// // Quick analysis of a private repository
/// final result = await analyzeQuick(
///   'https://github.com/user/private-repo',
///   githubToken: 'your-github-token',
/// );
/// print('Total files: ${result.files.length}');
///
/// // With progress tracking
/// final result = await analyzeQuick(
///   'https://github.com/user/repo',
///   progressCallback: (progress) {
///     print('${progress.phase}: ${(progress.progress * 100).toFixed(0)}%');
///   },
/// );
/// ```
///
/// ## Performance
///
/// This function is optimized for speed by:
/// - Reducing the number of files analyzed
/// - Limiting content depth
/// - Using aggressive caching
/// - Skipping detailed statistics
///
/// ## Throws
///
/// - [AnalyzerException] if the repository cannot be accessed.
///
/// See also:
/// - [analyze] for comprehensive analysis with full options
/// - [analyzeForLLM] for LLM-optimized output
Future<AnalysisResult> analyzeQuick(
  String repositoryUrl, {
  String? githubToken,
  void Function(AnalysisProgress)? progressCallback,
  bool? useCache,
}) async {
  setupLogger(verbose: false);

  // Setup dependencies using DI container
  final config = await GithubAnalyzerConfig.quick(githubToken: githubToken);
  await setupDependencies(config: config);

  final analyzer = await GithubAnalyzer.create(config: config);

  StreamSubscription<AnalysisProgress>? progressSubscription;
  if (progressCallback != null) {
    progressSubscription = analyzer.progressStream.listen(progressCallback);
  }

  try {
    return await analyzer.analyze(repositoryUrl, useCache: useCache);
  } finally {
    await progressSubscription?.cancel();
    await analyzer.dispose();
  }
}

/// Analyzes a repository and generates markdown optimized for LLM context.
///
/// This function is specifically designed for generating documentation that
/// works well with Large Language Models (LLMs). It produces structured,
/// comprehensive markdown output with optimal formatting for AI consumption.
///
/// ## Features
///
/// - Optimized file selection based on importance
/// - Structured output with clear sections
/// - Includes repository metadata, statistics, and file contents
/// - Respects token limits with configurable [maxFiles]
/// - Supports both public and private repositories
///
/// ## Parameters
///
/// - [repositoryUrl]: The GitHub repository URL to analyze.
/// - [outputPath]: Optional specific file path for the output markdown file.
/// - [outputDir]: Directory where the markdown file should be saved.
/// - [githubToken]: GitHub personal access token for accessing private repositories
///   and avoiding API rate limits. Highly recommended for production use.
/// - [maxFiles]: Maximum number of files to include in the output. Defaults to 200.
///   Helps control the output size for LLM token limits.
/// - [markdownConfig]: Configuration for markdown generation. Defaults to
///   [MarkdownConfig.standard].
/// - [progressCallback]: Optional callback for real-time progress updates.
/// - [verbose]: Whether to enable verbose logging. Defaults to `false`.
/// - [useCache]: Whether to use cached results if available.
///
/// ## Returns
///
/// A [Future] that completes with a [String] containing the path to the
/// generated markdown file.
///
/// ## Example
///
/// ```
/// // Basic LLM-optimized analysis
/// final outputPath = await analyzeForLLM(
///   'https://github.com/user/repo',
///   outputDir: './llm-context',
/// );
/// print('LLM context saved to: $outputPath');
///
/// // Analysis with GitHub token for private repos
/// final outputPath = await analyzeForLLM(
///   'https://github.com/user/private-repo',
///   githubToken: 'ghp_your_github_token',
///   outputDir: './output',
/// );
///
/// // Custom file limit and output path
/// final outputPath = await analyzeForLLM(
///   'https://github.com/user/large-repo',
///   githubToken: 'your-token',
///   maxFiles: 100,
///   outputPath: './context/repo-summary.md',
/// );
///
/// // With progress tracking
/// final outputPath = await analyzeForLLM(
///   'https://github.com/user/repo',
///   githubToken: 'your-token',
///   progressCallback: (progress) {
///     print('[${progress.phase}] ${progress.message}');
///   },
/// );
/// ```
///
/// ## Output Format
///
/// The generated markdown includes:
/// - Repository metadata (name, description, languages, stars, etc.)
/// - Comprehensive statistics (files, lines, size, language breakdown)
/// - Directory tree structure
/// - Main entry point files
/// - Dependencies
/// - Full content of important files (up to [maxFiles])
///
/// ## Best Practices
///
/// - Always provide a [githubToken] for production use to avoid rate limits
/// - Adjust [maxFiles] based on your LLM's context window size
/// - Use caching (default) for repeated analyses of the same repository
/// - Enable [verbose] logging during development for debugging
///
/// ## Throws
///
/// - [AnalyzerException] if the repository cannot be accessed or analyzed.
/// - [ArgumentError] if [maxFiles] is less than 0.
/// - [FileSystemException] if the output directory cannot be accessed.
///
/// See also:
/// - [analyze] for basic analysis without markdown generation
/// - [analyzeAndGenerate] for standard markdown output
/// - [analyzeQuick] for fast, minimal analysis
Future<String> analyzeForLLM(
  String repositoryUrl, {
  String? outputPath,
  String? outputDir,
  String? githubToken,
  int maxFiles = 200,
  MarkdownConfig markdownConfig = MarkdownConfig.standard,
  void Function(AnalysisProgress)? progressCallback,
  bool verbose = false,
  bool? useCache,
}) async {
  setupLogger(verbose: verbose);

  // Setup dependencies using DI container
  final config = await GithubAnalyzerConfig.forLLM(
    githubToken: githubToken,
    maxFiles: maxFiles,
  );

  await setupDependencies(config: config);

  final analyzer = await GithubAnalyzer.create(config: config);

  StreamSubscription<AnalysisProgress>? progressSubscription;
  if (progressCallback != null) {
    progressSubscription = analyzer.progressStream.listen(progressCallback);
  }

  try {
    final result = await analyzer.analyze(repositoryUrl, useCache: useCache);

    // Use context service from DI container
    final contextService = getIt<ContextService>();
    return await contextService.generate(
      result,
      outputPath: outputPath,
      outputDir: outputDir,
      config: markdownConfig,
    );
  } finally {
    await progressSubscription?.cancel();
    await analyzer.dispose();
    await disposeDependencies();
  }
}
