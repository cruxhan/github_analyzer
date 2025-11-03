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

/// Analyzes a repository and returns the analysis result.
///
/// This is a convenience function that automatically handles dependency
/// initialization, analysis execution, and resource cleanup.
///
/// ## Parameters
///
/// * [repositoryUrl] - GitHub repository URL or local directory path
/// * [config] - Optional custom configuration. If not provided, uses defaults
/// * [progressCallback] - Optional callback to receive progress updates
/// * [verbose] - Enable verbose logging (default: false)
/// * [useCache] - Whether to use cached results. If null, uses config setting
///
/// ## Returns
///
/// [AnalysisResult] containing analyzed files, statistics, and metadata.
///
/// ## Example
///
/// ```
/// // Analyze with default settings
/// final result = await analyze('https://github.com/flutter/flutter');
///
/// // Analyze with custom config
/// final config = await GithubAnalyzerConfig.create(
///   githubToken: 'ghp_xxxxx',
///   maxTotalFiles: 500,
/// );
/// final result = await analyze(
///   'https://github.com/dart-lang/sdk',
///   config: config,
///   verbose: true,
/// );
///
/// // Analyze with progress tracking
/// final result = await analyze(
///   'https://github.com/flutter/samples',
///   progressCallback: (progress) {
///     print('${progress.phase}: ${(progress.progress * 100).toInt()}%');
///   },
/// );
/// ```
///
/// ## Resource Management
///
/// This function automatically disposes resources after analysis completes.
/// For long-running applications with multiple analyses, consider using
/// [GithubAnalyzer] class directly to reuse resources.
///
/// See also:
/// * [analyzeQuick] for fast analysis with optimized settings
/// * [analyzeForLLM] for LLM-optimized analysis with markdown output
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

  final analyzer = await GithubAnalyzer.create();
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

/// Analyzes a repository and generates markdown output in one step.
///
/// This convenience function performs analysis and immediately generates
/// a markdown file suitable for AI/LLM context. Combines [analyze] and
/// markdown generation into a single operation.
///
/// ## Parameters
///
/// * [repositoryUrl] - GitHub repository URL or local directory path
/// * [outputPath] - Optional specific file path for markdown output
/// * [outputDir] - Optional directory for output (uses default filename)
/// * [analyzerConfig] - Optional analyzer configuration
/// * [markdownConfig] - Markdown generation settings (default: standard)
/// * [progressCallback] - Optional callback for progress updates
/// * [verbose] - Enable verbose logging (default: false)
/// * [useCache] - Whether to use cached results
///
/// ## Returns
///
/// String containing the absolute path to the generated markdown file.
///
/// ## Example
///
/// ```
/// // Generate with default settings
/// final path = await analyzeAndGenerate(
///   'https://github.com/flutter/flutter',
/// );
/// print('Markdown saved to: $path');
///
/// // Generate with custom output path
/// final path = await analyzeAndGenerate(
///   'https://github.com/dart-lang/sdk',
///   outputPath: './docs/sdk_analysis.md',
/// );
///
/// // Generate with custom markdown config
/// final path = await analyzeAndGenerate(
///   'https://github.com/flutter/samples',
///   markdownConfig: MarkdownConfig.compact,
/// );
///
/// // Generate with progress tracking
/// final path = await analyzeAndGenerate(
///   'https://github.com/dart-lang/linter',
///   progressCallback: (progress) {
///     print('${progress.message}');
///   },
/// );
/// ```
///
/// ## Output Location
///
/// * If [outputPath] provided: Uses exact path
/// * If [outputDir] provided: Saves to directory with auto-generated filename
/// * If neither provided: Saves to current directory
///
/// ## Markdown Formats
///
/// * [MarkdownConfig.standard] - Full details with code samples
/// * [MarkdownConfig.compact] - Condensed format, smaller file size
/// * [MarkdownConfig.minimal] - Essential information only
///
/// See also:
/// * [analyze] for analysis without markdown generation
/// * [analyzeForLLM] for LLM-optimized analysis
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

  final analyzer = await GithubAnalyzer.create();
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

/// Quick analysis with optimized settings for fast results.
///
/// This function uses performance-optimized settings to analyze repositories
/// quickly. Ideal for quick inspections or when full analysis is not needed.
///
/// ## Optimizations
///
/// * Cache disabled (always fresh analysis)
/// * Isolate pool disabled (simpler processing)
/// * Maximum 100 files analyzed
/// * Smaller isolate pool size (2 workers)
///
/// ## Parameters
///
/// * [repositoryUrl] - GitHub repository URL or local directory path
/// * [githubToken] - Optional GitHub personal access token for private repos
/// * [progressCallback] - Optional callback for progress updates
/// * [useCache] - Whether to use cache (default: false for quick mode)
///
/// ## Returns
///
/// [AnalysisResult] with up to 100 most important files analyzed.
///
/// ## Example
///
/// ```
/// // Quick public repository analysis
/// final result = await analyzeQuick(
///   'https://github.com/flutter/samples',
/// );
///
/// // Quick private repository analysis
/// final result = await analyzeQuick(
///   'https://github.com/myorg/private-repo',
///   githubToken: 'ghp_xxxxx',
/// );
///
/// // With progress tracking
/// final result = await analyzeQuick(
///   'https://github.com/dart-lang/sdk',
///   progressCallback: (progress) {
///     print('Phase: ${progress.phase}');
///   },
/// );
/// ```
///
/// ## Performance
///
/// Typically 2-5x faster than standard analysis, depending on repository size.
///
/// ## Limitations
///
/// * Analyzes maximum 100 files (prioritizes important files)
/// * No persistent caching
/// * Less parallel processing
///
/// See also:
/// * [analyze] for full-featured analysis
/// * [analyzeForLLM] for LLM-optimized analysis
Future<AnalysisResult> analyzeQuick(
  String repositoryUrl, {
  String? githubToken,
  void Function(AnalysisProgress)? progressCallback,
  bool? useCache,
}) async {
  setupLogger(verbose: false);

  // Setup dependencies using DI container
  await setupDependencies(
    config: await GithubAnalyzerConfig.quick(githubToken: githubToken),
  );

  final analyzer = await GithubAnalyzer.create();
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

/// Analysis optimized for LLM context generation.
///
/// This function analyzes a repository with settings optimized for AI/LLM
/// consumption and automatically generates a markdown file. It excludes
/// test files and generated code to focus on core implementation.
///
/// ## LLM Optimizations
///
/// * Excludes test directories and files
/// * Excludes example code
/// * Excludes generated files (*.g.dart, *.freezed.dart, etc.)
/// * Prioritizes main implementation files
/// * Configurable file limit (default: 200)
/// * Auto-generates markdown suitable for LLM context
///
/// ## Parameters
///
/// * [repositoryUrl] - GitHub repository URL or local directory path
/// * [outputPath] - Optional specific file path for markdown output
/// * [outputDir] - Optional directory for output
/// * [githubToken] - GitHub personal access token (required for private repos)
/// * [maxFiles] - Maximum number of files to analyze (default: 200)
/// * [markdownConfig] - Markdown generation settings (default: standard)
/// * [progressCallback] - Optional callback for progress updates
/// * [verbose] - Enable verbose logging (default: false)
/// * [useCache] - Whether to use cached results
///
/// ## Returns
///
/// String containing the absolute path to the generated markdown file.
///
/// ## Example
///
/// ```
/// // Analyze public repository for LLM
/// final path = await analyzeForLLM(
///   'https://github.com/flutter/flutter',
/// );
///
/// // Analyze private repository
/// final path = await analyzeForLLM(
///   'https://github.com/myorg/private-repo',
///   githubToken: 'ghp_xxxxx',
/// );
///
/// // Analyze with custom file limit
/// final path = await analyzeForLLM(
///   'https://github.com/dart-lang/sdk',
///   maxFiles: 500,
/// );
///
/// // Analyze with custom output
/// final path = await analyzeForLLM(
///   'https://github.com/flutter/samples',
///   outputPath: './context/flutter_samples.md',
///   markdownConfig: MarkdownConfig.compact,
/// );
///
/// // With progress tracking
/// final path = await analyzeForLLM(
///   'https://github.com/dart-lang/linter',
///   progressCallback: (progress) {
///     print('[${(progress.progress * 100).toInt()}%] ${progress.message}');
///   },
/// );
/// ```
///
/// ## Excluded Patterns
///
/// Automatically excludes:
/// * `test/`, `tests/` directories
/// * `**_test.dart` files
/// * `example/` directory
/// * Generated files (*.g.dart, *.freezed.dart, etc.)
///
/// ## Output Format
///
/// Generated markdown includes:
/// * Repository metadata and statistics
/// * Source code with syntax highlighting
/// * File structure and dependencies
/// * Optimized for token efficiency
///
/// ## Use Cases
///
/// * Preparing repository context for ChatGPT/Claude
/// * Code review assistance
/// * Documentation generation
/// * Architecture analysis
///
/// See also:
/// * [analyze] for standard analysis
/// * [analyzeQuick] for fast analysis
/// * [analyzeAndGenerate] for custom markdown generation
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
  await setupDependencies(
    config: await GithubAnalyzerConfig.forLLM(
      githubToken: githubToken,
      maxFiles: maxFiles,
    ),
  );

  final analyzer = await GithubAnalyzer.create();
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
