import 'dart:io';

import 'package:github_analyzer/github_analyzer.dart';

/// Comprehensive demo testing all GitHub Analyzer features
///
/// Tests:
/// 1. Local directory analysis
/// 2. Remote repository analysis (public)
/// 3. Metadata-only fetch (fast)
/// 4. Progress stream tracking
/// 5. LLM-optimized analysis
/// 6. Custom configuration
/// 7. Cache system
/// 8. Error handling
/// 9. Result serialization (JSON)
/// 10. Statistics validation
/// 11. File filtering
/// 12. Convenience functions
/// 13. Markdown generation
/// 14. Cache management
/// 15. Analyze and Generate
/// 16. Generate String
void main(List<String> args) async {
  print('🚀 GitHub Analyzer v0.1.5 - Comprehensive Feature Test\n');
  print('═══════════════════════════════════════════════════════\n');

  // Parse arguments
  final testMode = args.isNotEmpty ? args[0] : 'all';

  switch (testMode.toLowerCase()) {
    case 'local':
      await testLocalAnalysis();
      break;
    case 'remote':
      await testRemoteAnalysis();
      break;
    case 'metadata':
      await testMetadataOnly();
      break;
    case 'progress':
      await testProgressTracking();
      break;
    case 'llm':
      await testLLMOptimized();
      break;
    case 'config':
      await testCustomConfig();
      break;
    case 'cache':
      await testCacheSystem();
      break;
    case 'error':
      await testErrorHandling();
      break;
    case 'json':
      await testResultSerialization();
      break;
    case 'stats':
      await testStatisticsValidation();
      break;
    case 'filter':
      await testFileFiltering();
      break;
    case 'convenience':
      await testConvenienceFunctions();
      break;
    case 'markdown':
      await testMarkdownGeneration();
      break;
    case 'cachemgmt':
      await testCacheManagement();
      break;
    case 'generate':
      await testAnalyzeAndGenerate();
      break;
    case 'string':
      await testGenerateString();
      break;
    case 'all':
      await runAllTests();
      break;
    default:
      printUsage();
  }
}

void printUsage() {
  print('''
Usage: dart demo.dart [test_name]


Available tests:
  local       - Test local directory analysis
  remote      - Test remote repository analysis
  metadata    - Test metadata-only fetch (fast)
  progress    - Test progress stream tracking
  llm         - Test LLM-optimized analysis
  config      - Test custom configuration
  cache       - Test cache system
  error       - Test error handling
  json        - Test result serialization (JSON)
  stats       - Test statistics validation
  filter      - Test file filtering
  convenience - Test convenience functions
  markdown    - Test markdown generation
  cachemgmt   - Test cache management
  generate    - Test analyze and generate
  string      - Test generate string
  all         - Run all tests (default)


Examples:
  dart demo.dart
  dart demo.dart local
  dart demo.dart all
''');
}

/// Run all tests sequentially
Future<void> runAllTests() async {
  final tests = [
    ('Local Analysis', testLocalAnalysis),
    ('Remote Analysis', testRemoteAnalysis),
    ('Metadata Only', testMetadataOnly),
    ('Progress Tracking', testProgressTracking),
    ('LLM Optimized', testLLMOptimized),
    ('Custom Config', testCustomConfig),
    ('Cache System', testCacheSystem),
    ('Error Handling', testErrorHandling),
    ('Result Serialization', testResultSerialization),
    ('Statistics Validation', testStatisticsValidation),
    ('File Filtering', testFileFiltering),
    ('Convenience Functions', testConvenienceFunctions),
    ('Markdown Generation', testMarkdownGeneration),
    ('Cache Management', testCacheManagement),
    ('Analyze and Generate', testAnalyzeAndGenerate),
    ('Generate String', testGenerateString),
  ];

  var passed = 0;
  var failed = 0;

  for (var i = 0; i < tests.length; i++) {
    final (name, test) = tests[i];
    print('\n[${i + 1}/${tests.length}] Testing: $name');
    print('─' * 60);

    try {
      await test();
      passed++;
      print('✅ PASSED: $name\n');
    } catch (e, stackTrace) {
      failed++;
      print('❌ FAILED: $name');
      print('   Error: $e');
      print(
        '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n         ')}',
      );
    }

    // Small delay between tests
    await Future.delayed(const Duration(milliseconds: 500));
  }

  print('\n═══════════════════════════════════════════════════════');
  print('📊 Test Summary');
  print('═══════════════════════════════════════════════════════');
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');
  print('📈 Total:  ${tests.length}');
  print(
    '🎯 Success Rate: ${(passed / tests.length * 100).toStringAsFixed(1)}%\n',
  );
}

/// Test 1: Local directory analysis
Future<void> testLocalAnalysis() async {
  print('📁 Test: Local Directory Analysis\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist: $localPath');
    print('   Update path in demo.dart to test this feature\n');
    return;
  }

  final config = GithubAnalyzerConfig(enableIsolatePool: false);
  final analyzer = await GithubAnalyzer.create(config: config);

  print('Analyzing: $localPath');
  final stopwatch = Stopwatch()..start();
  final result = await analyzer.analyzeLocal(localPath);
  stopwatch.stop();

  print('✓ Analysis completed in ${stopwatch.elapsedMilliseconds}ms');
  print('✓ Files: ${result.statistics.totalFiles}');
  print('✓ Lines: ${result.statistics.totalLines}');
  print(
    '✓ Size: ${(result.statistics.totalSize / 1024).toStringAsFixed(2)} KB',
  );
  print('✓ Language: ${result.metadata.language}');

  await analyzer.dispose();
}

/// Test 2: Remote repository analysis
Future<void> testRemoteAnalysis() async {
  print('🌐 Test: Remote Repository Analysis\n');

  const repoUrl = 'https://github.com/flutter/samples';
  final analyzer = await GithubAnalyzer.create();

  print('Analyzing: $repoUrl (branch: main)');
  final stopwatch = Stopwatch()..start();
  final result = await analyzer.analyze(repoUrl, branch: 'main');
  stopwatch.stop();

  print('✓ Analysis completed in ${stopwatch.elapsedMilliseconds}ms');
  print('✓ Name: ${result.metadata.name}');
  print('✓ Stars: ${result.metadata.stars}');
  print('✓ Files: ${result.statistics.totalFiles}');
  print('✓ Language: ${result.metadata.language}');

  await analyzer.dispose();
}

/// Test 3: Metadata-only fetch (fast)
Future<void> testMetadataOnly() async {
  print('⚡ Test: Metadata-Only Fetch\n');

  const repoUrl = 'https://github.com/flutter/flutter';
  final analyzer = await GithubAnalyzer.create();

  print('Fetching metadata: $repoUrl');
  final stopwatch = Stopwatch()..start();
  final metadata = await analyzer.fetchMetadataOnly(repoUrl, branch: 'stable');
  stopwatch.stop();

  print('✓ Metadata fetched in ${stopwatch.elapsedMilliseconds}ms');
  print('✓ Name: ${metadata.name}');
  print('✓ Stars: ${metadata.stars}');
  print('✓ Forks: ${metadata.forks}');
  print('✓ Language: ${metadata.language}');
  print('✓ Files: ${metadata.fileCount}');

  await analyzer.dispose();
}

/// Test 4: Progress stream tracking
Future<void> testProgressTracking() async {
  print('📊 Test: Progress Stream Tracking\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist\n');
    return;
  }

  final analyzer = await GithubAnalyzer.create();
  var progressCount = 0;

  analyzer.progressStream.listen((progress) {
    progressCount++;
    if (progress.progress == 1.0) {
      print('✓ Progress: 100% - ${progress.message}');
    }
  });

  await analyzer.analyzeLocal(localPath);
  print('✓ Received $progressCount progress updates');

  await analyzer.dispose();
}

/// Test 5: LLM-optimized analysis
Future<void> testLLMOptimized() async {
  print('🤖 Test: LLM-Optimized Analysis\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist\n');
    return;
  }

  final config = await GithubAnalyzerConfig.forLLM(maxFiles: 100);
  final analyzer = await GithubAnalyzer.create(config: config);
  final result = await analyzer.analyzeLocal(localPath);

  print('✓ Total files: ${result.statistics.totalFiles}');
  print('✓ Source files: ${result.statistics.sourceFiles}');
  print('✓ Config files: ${result.statistics.configFiles}');
  print('✓ Documentation: ${result.statistics.documentationFiles}');
  print('✓ Binary files: ${result.statistics.binaryFiles}');

  await analyzer.dispose();
}

/// Test 6: Custom configuration
Future<void> testCustomConfig() async {
  print('⚙️  Test: Custom Configuration\n');

  final config = GithubAnalyzerConfig(
    maxFileSize: 500 * 1024, // 500 KB
    maxTotalFiles: 50,
    enableCache: true,
    enableIsolatePool: false,
    excludePatterns: ['*.lock', '*.log', 'node_modules/**'],
    includePatterns: ['lib/**', 'src/**'],
    prioritizeImportantFiles: true,
    excludeGeneratedFiles: true,
  );

  print('✓ Max file size: ${config.maxFileSize / 1024} KB');
  print('✓ Max total files: ${config.maxTotalFiles}');
  print('✓ Cache enabled: ${config.enableCache}');
  print('✓ Isolate pool: ${config.enableIsolatePool}');
  print('✓ Exclude patterns: ${config.excludePatterns.length}');
  print('✓ Include patterns: ${config.includePatterns.length}');

  final analyzer = await GithubAnalyzer.create(config: config);
  print('✓ Analyzer created with custom config');

  await analyzer.dispose();
}

/// Test 7: Cache system
Future<void> testCacheSystem() async {
  print('💾 Test: Cache System\n');

  const repoUrl = 'https://github.com/flutter/samples';
  final config = GithubAnalyzerConfig(enableCache: true, enableFileCache: true);
  final analyzer = await GithubAnalyzer.create(config: config);

  // First analysis (cold - will cache)
  print('First analysis (cold)...');
  final stopwatch1 = Stopwatch()..start();
  await analyzer.analyze(repoUrl, branch: 'main');
  stopwatch1.stop();
  print('✓ Cold: ${stopwatch1.elapsedMilliseconds}ms');

  // Second analysis (warm - from cache)
  print('Second analysis (warm)...');
  final stopwatch2 = Stopwatch()..start();
  await analyzer.analyze(repoUrl, branch: 'main');
  stopwatch2.stop();
  print('✓ Warm: ${stopwatch2.elapsedMilliseconds}ms');

  final speedup =
      (stopwatch1.elapsedMilliseconds / stopwatch2.elapsedMilliseconds);
  print('✓ Cache speedup: ${speedup.toStringAsFixed(2)}x');

  await analyzer.dispose();
}

/// Test 8: Error handling
Future<void> testErrorHandling() async {
  print('🛡️  Test: Error Handling\n');

  final analyzer = await GithubAnalyzer.create();
  var errorsCaught = 0;

  // Test 1: Invalid URL
  try {
    await analyzer.analyze('not-a-valid-url');
  } catch (e) {
    errorsCaught++;
    print('✓ Caught invalid URL error');
  }

  // Test 2: Non-existent repo
  try {
    await analyzer.analyze(
      'https://github.com/invalid/repo-does-not-exist-123456',
    );
  } catch (e) {
    errorsCaught++;
    print('✓ Caught non-existent repo error');
  }

  // Test 3: Invalid branch
  try {
    await analyzer.analyze(
      'https://github.com/flutter/flutter',
      branch: 'branch-does-not-exist-123456',
    );
  } catch (e) {
    errorsCaught++;
    print('✓ Caught invalid branch error');
  }

  print('✓ Total errors caught: $errorsCaught/3');

  await analyzer.dispose();
}

/// Test 9: Result serialization (JSON)
Future<void> testResultSerialization() async {
  print('📦 Test: Result Serialization (JSON)\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist\n');
    return;
  }

  final analyzer = await GithubAnalyzer.create();
  final result = await analyzer.analyzeLocal(localPath);

  // Test JSON serialization
  final json = result.toJson();
  print('✓ Serialized to JSON');
  print('✓ JSON keys: ${json.keys.length}');
  print('✓ Has metadata: ${json.containsKey('metadata')}');
  print('✓ Has statistics: ${json.containsKey('statistics')}');
  print('✓ Has files: ${json.containsKey('files')}');

  // Test deserialization
  final deserialized = AnalysisResult.fromJson(json);
  print('✓ Deserialized from JSON');
  print(
    '✓ Files match: ${deserialized.statistics.totalFiles == result.statistics.totalFiles}',
  );
  print(
    '✓ Lines match: ${deserialized.statistics.totalLines == result.statistics.totalLines}',
  );

  await analyzer.dispose();
}

/// Test 10: Statistics validation
Future<void> testStatisticsValidation() async {
  print('📊 Test: Statistics Validation\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist\n');
    return;
  }

  final analyzer = await GithubAnalyzer.create();
  final result = await analyzer.analyzeLocal(localPath);
  final stats = result.statistics;

  // Validate statistics
  final totalFilesValid = stats.totalFiles > 0;
  final fileCategoriesValid =
      (stats.sourceFiles +
          stats.configFiles +
          stats.documentationFiles +
          stats.binaryFiles) <=
      stats.totalFiles;
  final sizeValid = stats.totalSize > 0;
  final linesValid = stats.totalLines > 0;
  final languagesValid = stats.languageDistribution.isNotEmpty;

  print('✓ Total files valid: $totalFilesValid (${stats.totalFiles})');
  print('✓ File categories valid: $fileCategoriesValid');
  print(
    '✓ Size valid: $sizeValid (${(stats.totalSize / 1024).toStringAsFixed(2)} KB)',
  );
  print('✓ Lines valid: $linesValid (${stats.totalLines})');
  print(
    '✓ Languages valid: $languagesValid (${stats.languageDistribution.length} languages)',
  );

  await analyzer.dispose();
}

/// Test 11: File filtering
Future<void> testFileFiltering() async {
  print('🔍 Test: File Filtering\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist\n');
    return;
  }

  // Test with different filter patterns
  final config1 = GithubAnalyzerConfig(
    includePatterns: ['lib/**'],
    excludePatterns: ['**/*.g.dart', '**/*.freezed.dart'],
  );

  final analyzer1 = await GithubAnalyzer.create(config: config1);
  final result1 = await analyzer1.analyzeLocal(localPath);

  print('✓ With lib/** filter:');
  print('   Files: ${result1.statistics.totalFiles}');

  await analyzer1.dispose();

  // Test with different exclusions
  final config2 = GithubAnalyzerConfig(
    excludePatterns: ['test/**', '**/.dart_tool/**'],
    excludeGeneratedFiles: true,
  );

  final analyzer2 = await GithubAnalyzer.create(config: config2);
  final result2 = await analyzer2.analyzeLocal(localPath);

  print('✓ With test/** excluded:');
  print('   Files: ${result2.statistics.totalFiles}');

  await analyzer2.dispose();

  print('✓ Filtering works correctly');
}

/// Test 12: Convenience functions
Future<void> testConvenienceFunctions() async {
  print('🚀 Test: Convenience Functions\n');

  // Test analyze()
  print('Testing analyze()...');
  final result1 = await analyze(
    'https://github.com/dart-lang/sdk',
    branch: 'main',
    useCache: false,
  );
  print('✓ analyze() works: ${result1.metadata.name}');

  // Test analyzeQuick()
  print('Testing analyzeQuick()...');
  final result2 = await analyzeQuick(
    'https://github.com/dart-lang/sdk',
    branch: 'main',
  );
  print('✓ analyzeQuick() works: ${result2.statistics.totalFiles} files');

  // Test analyzeForLLM()
  print('Testing analyzeForLLM()...');
  final outputPath = await analyzeForLLM(
    'https://github.com/dart-lang/sdk',
    branch: 'main',
    outputDir: './test_output',
    maxFiles: 50,
  );
  print('✓ analyzeForLLM() works: $outputPath');

  // Clean up test output
  final testDir = Directory('./test_output');
  if (await testDir.exists()) {
    await testDir.delete(recursive: true);
    print('✓ Cleaned up test output directory');
  }
}

/// Test 13: Markdown generation
Future<void> testMarkdownGeneration() async {
  print('📄 Test: Markdown Generation\n');

  final localPath = '/Users/macbook/Desktop/project/vibe_code';
  if (!await Directory(localPath).exists()) {
    print('⚠️  Skipped: Directory does not exist\n');
    return;
  }

  final analyzer = await GithubAnalyzer.create();
  final result = await analyzer.analyzeLocal(localPath);

  // Test ContextService
  print('Testing ContextService...');
  final contextService = ContextService();
  final outputPath = await contextService.generate(
    result,
    outputDir: './test_output',
    config: MarkdownConfig.compact,
  );
  print('✓ ContextService generated: $outputPath');

  // Test MarkdownService
  print('Testing MarkdownService...');
  final markdownService = MarkdownService();
  final markdown = markdownService.generate(
    result,
    config: MarkdownConfig.standard,
  );
  print('✓ MarkdownService generated ${markdown.length} characters');

  await analyzer.dispose();

  // Clean up test output
  final testDir = Directory('./test_output');
  if (await testDir.exists()) {
    await testDir.delete(recursive: true);
    print('✓ Cleaned up test output directory');
  }
}

/// Test 14: Cache management
Future<void> testCacheManagement() async {
  print('🗄️  Test: Cache Management\n');

  final config = GithubAnalyzerConfig(enableCache: true);
  final analyzer = await GithubAnalyzer.create(config: config);

  // Get cache statistics before
  final statsBefore = await analyzer.getCacheStatistics();
  print('✓ Cache stats before: ${statsBefore ?? "null"}');

  // Analyze something to create cache
  await analyzer.analyze('https://github.com/flutter/samples', branch: 'main');
  print('✓ Analysis completed (cache created)');

  // Get cache statistics after
  final statsAfter = await analyzer.getCacheStatistics();
  print('✓ Cache stats after: ${statsAfter ?? "null"}');

  // Clear cache
  await analyzer.clearCache();
  print('✓ Cache cleared successfully');

  await analyzer.dispose();
}

/// Test 15: Analyze and generate in one call
Future<void> testAnalyzeAndGenerate() async {
  print('🔗 Test: analyzeAndGenerate()\n');

  try {
    final sw = Stopwatch()..start();

    final outputPath = await analyzeAndGenerate(
      'https://github.com/dart-lang/lints',
      branch: 'main',
      outputDir: './test_output',
      markdownConfig: MarkdownConfig.compact,
      useCache: false,
    );

    sw.stop();

    print('✓ Analysis and generation completed in ${sw.elapsedMilliseconds}ms');
    print('✓ Output file: $outputPath');

    // Verify file exists
    final file = File(outputPath);
    final exists = await file.exists();
    print('✓ File exists: $exists');

    if (exists) {
      final size = await file.length();
      print('✓ File size: ${(size / 1024).toStringAsFixed(2)} KB');
    }

    // Clean up
    final testDir = Directory('./test_output');
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
      print('✓ Cleanup completed');
    }
  } catch (e, stackTrace) {
    print('❌ Error in analyzeAndGenerate: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Test 16: Generate markdown string without file
Future<void> testGenerateString() async {
  print('📝 Test: ContextService.generateString()\n');

  GithubAnalyzer? analyzer;
  try {
    final sw = Stopwatch()..start();

    analyzer = await GithubAnalyzer.create();
    final result = await analyzer.analyzeLocal('./lib');

    final contextService = ContextService();
    final markdown = contextService.generateString(
      result,
      config: MarkdownConfig.compact,
    );

    sw.stop();

    print('✓ String generation completed in ${sw.elapsedMilliseconds}ms');
    print('✓ Generated markdown: ${markdown.length} characters');
    print(
      '✓ Contains metadata: ${markdown.contains('## Repository Information')}',
    );
    print('✓ Contains statistics: ${markdown.contains('## Statistics')}');
    print(
      '✓ Contains directory tree: ${markdown.contains('## Directory Structure')}',
    );
  } catch (e, stackTrace) {
    print('❌ Error in generateString: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  } finally {
    await analyzer?.dispose();
  }
}
