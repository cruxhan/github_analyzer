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
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  print('🚀 GitHub Analyzer v0.1.2 Examples\n');

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
Future<void> example1_quickAnalysis() async {
  print('📝 Example 1: Quick Analysis\n');

  try {
    // Analyze a repository quickly
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
Future<void> example2_llmOptimized() async {
  print('📝 Example 2: LLM-Optimized Analysis\n');

  try {
    // Generate markdown file optimized for AI/LLM context
    final outputPath = await analyzeForLLM(
      'https://github.com/dart-lang/http',
      outputDir: './output',
      maxFiles: 50,
      markdownConfig: MarkdownConfig.compact,
    );

    print('✅ Markdown generated: $outputPath');
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 3: Advanced configuration with cache control
Future<void> example3_advancedConfig() async {
  print('📝 Example 3: Advanced Configuration\n');

  try {
    // Create custom configuration
    final config = await GithubAnalyzerConfig.create(
      githubToken: null, // Will auto-load from .env if exists
      excludePatterns: ['test/**', 'example/**', '*.g.dart', '*.freezed.dart'],
      maxFileSize: 500 * 1024, // 500KB
      enableCache: true,
      enableFileCache: true,
      maxTotalFiles: 100,
      maxConcurrentRequests: 10,
    );

    // Create analyzer instance
    final analyzer = await GithubAnalyzer.create(config: config);

    // Analyze with custom config
    final result = await analyzer.analyze(
      'https://github.com/dart-lang/lints',
      useCache: false, // Disable cache for this request
    );

    print('✅ Analysis completed!');
    print('   Repository: ${result.metadata.fullName}');
    print('   Files analyzed: ${result.statistics.sourceFiles}');
    print('   Config files: ${result.statistics.configFiles}');
    print('   Main files: ${result.mainFiles.join(", ")}');
    print('');

    // Don't forget to dispose
    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 4: Analyze local directory
Future<void> example4_localAnalysis() async {
  print('📝 Example 4: Local Directory Analysis\n');

  try {
    // Create analyzer with default config
    final analyzer = await GithubAnalyzer.create();

    // Analyze a local directory
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
Future<void> example5_progressTracking() async {
  print('📝 Example 5: Progress Tracking\n');

  try {
    final analyzer = await GithubAnalyzer.create();

    // Listen to progress stream
    analyzer.progressStream.listen((progress) {
      final percentage = (progress.progress * 100).toStringAsFixed(0);
      print('   ⏳ ${progress.phase.name}: $percentage% - ${progress.message}');
    });

    final result = await analyzer.analyze('https://github.com/flutter/samples');

    print('✅ Analysis completed with progress tracking!');
    print('   Files: ${result.statistics.totalFiles}');
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 6: Metadata-only fetch (fast, no file analysis)
Future<void> example6_metadataOnly() async {
  print('📝 Example 6: Metadata-Only Fetch\n');

  try {
    final analyzer = await GithubAnalyzer.create();

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
    final result = await analyzer.analyze('https://github.com/dart-lang/http');

    // Generate markdown using ContextService
    final contextService = ContextService();
    final outputPath = await contextService.generate(
      result,
      outputDir: './output',
      config: MarkdownConfig.standard,
    );

    print('✅ Markdown saved to: $outputPath');

    // Or generate markdown string using MarkdownService
    final markdownService = MarkdownService();
    final markdown = markdownService.generate(
      result,
      config: MarkdownConfig.compact,
    );

    print('✅ Markdown generated: ${markdown.length} characters');
    print('');

    await analyzer.dispose();
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Example 8: Cache management
Future<void> example8_cacheManagement() async {
  print('📝 Example 8: Cache Management\n');

  try {
    final config = GithubAnalyzerConfig(
      enableCache: true,
      enableFileCache: true,
      cacheDuration: Duration(hours: 24),
    );
    final analyzer = await GithubAnalyzer.create(config: config);

    // Get cache statistics
    final statsBefore = await analyzer.getCacheStatistics();
    print('📊 Cache stats before: ${statsBefore ?? "No cache data"}');

    // Analyze something (will be cached)
    await analyzer.analyze('https://github.com/dart-lang/lints');
    print('✅ Analysis completed (cached)');

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

/// Helper function to format bytes
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
