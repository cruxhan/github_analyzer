/// Example demonstrating the usage of github_analyzer package
///
/// This example shows:
/// - Basic repository analysis
/// - LLM-optimized markdown generation
/// - Custom configuration
/// - Cache control
/// - Progress tracking
/// - Metadata-only fetch
/// - Convenience functions
///
/// ## Setup
///
/// For private repository access, set the GITHUB_TOKEN environment variable:
/// ```
/// export GITHUB_TOKEN=your_github_personal_access_token
/// dart run example/example.dart
/// ```
///
/// Or pass the token directly in code (not recommended for production):
/// ```
/// await analyzeForLLM(
///   'https://github.com/user/private-repo',
///   githubToken: 'your_token_here',
/// );
/// ```
import 'dart:io';
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  print('🚀 GitHub Analyzer v0.1.7 Examples\n');

  // Example 1: Quick Analysis
  await example1_quickAnalysis();

  // Example 2: LLM-Optimized Analysis with Markdown Generation
  await example2_llmOptimized();

  // Example 3: Advanced Configuration
  await example3_advancedConfig();

  // Example 4: Local Directory Analysis
  await example4_localAnalysis();

  // Example 5: Progress Tracking
  await example5_progressTracking();

  // Example 6: Metadata-Only Fetch
  await example6_metadataOnly();

  // Example 7: Markdown Generation
  await example7_markdownGeneration();

  // Example 8: Cache Management
  await example8_cacheManagement();
}

/// Example 1: Quick analysis with minimal configuration
///
/// This demonstrates the simplest way to analyze a public repository.
/// No GitHub token is required for public repositories.
Future<void> example1_quickAnalysis() async {
  print('📝 Example 1: Quick Analysis\n');

  try {
    // Analyze a public repository quickly (no token needed)
    final result = await analyzeQuick('https://github.com/dart-lang/sdk');

    print('✅ Analysis completed!');
    print('   Repository: ${result.metadata.fullName}');
    print('   Files: ${result.statistics.totalFiles}');
    print('   Lines: ${result.statistics.totalLines}');
    print('   Language: ${result.metadata.language}');
    print('   Size: ${_formatBytes(result.statistics.totalSize)}');
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 2: Generate LLM-optimized markdown documentation
///
/// This demonstrates how to generate markdown documentation optimized for
/// Large Language Models (LLMs). The output is structured and comprehensive.
///
/// For private repositories, set the GITHUB_TOKEN environment variable:
/// ```
/// export GITHUB_TOKEN=ghp_your_token_here
/// dart run example/example.dart
/// ```
/// Example 2: LLM-Optimized Analysis with Markdown Generation
Future<void> example2_llmOptimized() async {
  print('📝 Example 2: LLM-Optimized Analysis\n');

  try {
    final token = Platform.environment['GITHUB_TOKEN'];

    if (token == null || token.isEmpty) {
      print('ℹ️  No GITHUB_TOKEN found. Analyzing public repository only.');
    }

    final outputPath = await analyzeForLLM(
      'https://github.com/flutter/packages',
      githubToken: token,
      outputDir: './output',
      maxFiles: 50,
      markdownConfig: MarkdownConfig.compact,
      verbose: true,
    );

    print('✅ Markdown generated: $outputPath');
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 3: Advanced configuration with cache control
///
/// This demonstrates how to create a custom analyzer configuration with
/// specific settings for file exclusion, caching, and performance tuning.
Future<void> example3_advancedConfig() async {
  print('📝 Example 3: Advanced Configuration\n');

  try {
    // Load GitHub token from environment variable
    final token = Platform.environment['GITHUB_TOKEN'];

    // Create custom configuration
    final config = await GithubAnalyzerConfig.create(
      githubToken: token, // Optional: for private repos or higher rate limits
      excludePatterns: [
        'test/**',
        'example/**',
        '*.g.dart',
        '*.freezed.dart',
        'build/**',
        '.dart_tool/**',
      ],
      maxFileSize: 500 * 1024, // 500KB max per file
      enableCache: true,
      enableFileCache: true,
      maxTotalFiles: 100,
      maxConcurrentRequests: 10,
    );

    // Create analyzer instance with custom config
    final analyzer = await GithubAnalyzer.create(config: config);

    // Analyze with custom config
    final result = await analyzer.analyze(
      'https://github.com/dart-lang/lints',
      useCache: false, // Disable cache for this specific request
    );

    print('✅ Analysis completed!');
    print('   Repository: ${result.metadata.fullName}');
    print('   Files analyzed: ${result.statistics.sourceFiles}');
    print('   Config files: ${result.statistics.configFiles}');
    print('   Main files: ${result.mainFiles.join(", ")}');
    print('   Dependencies: ${result.dependencies.keys.length}');
    print('');

    // Don't forget to dispose
    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 4: Analyze local directory
///
/// This demonstrates how to analyze a local directory instead of a
/// remote GitHub repository.
Future<void> example4_localAnalysis() async {
  print('📝 Example 4: Local Directory Analysis\n');

  try {
    // Create analyzer with default config
    final analyzer = await GithubAnalyzer.create();

    // Analyze a local directory (e.g., the lib directory of this package)
    final result = await analyzer.analyzeLocal('./lib');

    print('✅ Local analysis completed!');
    print('   Total files: ${result.statistics.totalFiles}');
    print('   Source files: ${result.statistics.sourceFiles}');
    print(
      '   Languages: ${result.statistics.languageDistribution.keys.join(", ")}',
    );
    print('   Size: ${_formatBytes(result.statistics.totalSize)}');
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 5: Track analysis progress
///
/// This demonstrates how to track the progress of a repository analysis
/// in real-time using the progress stream.
Future<void> example5_progressTracking() async {
  print('📝 Example 5: Progress Tracking\n');

  try {
    final analyzer = await GithubAnalyzer.create();

    // Listen to progress stream for real-time updates
    analyzer.progressStream.listen((progress) {
      final percentage = (progress.progress * 100).toStringAsFixed(0);
      print('   ⏳ ${progress.phase.name}: $percentage% - ${progress.message}');
    });

    final result = await analyzer.analyze('https://github.com/flutter/samples');

    print('✅ Analysis completed with progress tracking!');
    print('   Files: ${result.statistics.totalFiles}');
    print('   Lines: ${result.statistics.totalLines}');
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 6: Metadata-only fetch (fast, no file analysis)
///
/// This demonstrates how to quickly fetch repository metadata without
/// analyzing the actual file contents. This is much faster and useful
/// when you only need basic information.
Future<void> example6_metadataOnly() async {
  print('📝 Example 6: Metadata-Only Fetch\n');

  try {
    // Load token for accessing private repos or avoiding rate limits
    final token = Platform.environment['GITHUB_TOKEN'];

    final config = await GithubAnalyzerConfig.create(githubToken: token);
    final analyzer = await GithubAnalyzer.create(config: config);

    // Fetch only metadata without analyzing files
    final metadata = await analyzer.fetchMetadataOnly(
      'https://github.com/flutter/flutter',
      branch: 'stable',
    );

    print('✅ Metadata fetched!');
    print('   Repository: ${metadata.fullName}');
    print('   Description: ${metadata.description}');
    print('   Stars: ${metadata.stars}');
    print('   Forks: ${metadata.forks}');
    print('   Language: ${metadata.language}');
    print('   Default Branch: ${metadata.defaultBranch}');
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 7: Markdown generation from analysis result
Future<void> example7_markdownGeneration() async {
  print('📝 Example 7: Markdown Generation\n');

  try {
    final analyzer = await GithubAnalyzer.create();

    final result = await analyzer.analyze(
      'https://github.com/dart-lang/lints',
    );

    // Generate markdown using ContextService (saves to file)
    final contextService = ContextService();
    final outputPath = await contextService.generate(
      result,
      outputDir: './output',
      config: MarkdownConfig.standard,
    );

    print('✅ Markdown file saved to: $outputPath');

    // Or generate markdown string using MarkdownService
    final markdownService = MarkdownService();
    final markdown = markdownService.generate(
      result,
      config: MarkdownConfig.compact,
    );

    print('✅ Markdown string generated: ${markdown.length} characters');
    print('   Preview (first 200 chars):');
    print(
      '   ${markdown.substring(0, markdown.length > 200 ? 200 : markdown.length)}...',
    );
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 8: Cache management
///
/// This demonstrates how to work with the built-in caching system to
/// improve performance for repeated analyses.
Future<void> example8_cacheManagement() async {
  print('📝 Example 8: Cache Management\n');

  try {
    final config = GithubAnalyzerConfig(
      enableCache: true,
      enableFileCache: true,
      cacheDuration: Duration(hours: 24),
    );
    final analyzer = await GithubAnalyzer.create(config: config);

    // Get cache statistics before analysis
    final statsBefore = await analyzer.getCacheStatistics();
    print('📊 Cache stats before: ${statsBefore ?? "No cache data"}');

    // First analysis (will be cached)
    print('⏳ Running first analysis (will be cached)...');
    await analyzer.analyze('https://github.com/dart-lang/lints');
    print('✅ First analysis completed (cached)');

    // Second analysis (will use cache, much faster)
    print('⏳ Running second analysis (should use cache)...');
    await analyzer.analyze('https://github.com/dart-lang/lints');
    print('✅ Second analysis completed (from cache)');

    // Get cache statistics after
    final statsAfter = await analyzer.getCacheStatistics();
    print('📊 Cache stats after: ${statsAfter ?? "No cache data"}');

    // Clear cache
    await analyzer.clearCache();
    print('🗑️  Cache cleared successfully');
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Helper function to format bytes into human-readable format
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
