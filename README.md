# GitHub Analyzer

[![pub version](https://img.shields.io/pub/v/github_analyzer.svg)](https://pub.dev/packages/github_analyzer)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible Dart package to analyze GitHub repositories. It can process both remote repositories via URL and local directories on your machine.

This tool is designed to extract comprehensive metadata, generate detailed statistics, and compile source code into a structured context, making it perfect for feeding into Large Language Models (LLMs) or for conducting code audits.

## ✨ Key Features

-   **Simple & Powerful API**: Analyze any public repository with a single function call. No complex setup required.
-   **Dual Analysis Modes**: Analyze repositories from a **remote GitHub URL** or a **local file path**.
-   **Comprehensive Reports**: Generates a detailed `AnalysisResult` object containing repository metadata, file-by-file analysis, language distribution, dependency detection, and more.
-   **Smart Caching**: Avoids re-analyzing unchanged remote repositories by using a commit-based caching system, saving time and API calls.
-   **High-Performance Scans**: Utilizes Dart Isolates for parallel processing of local files, ensuring fast and efficient analysis even on large codebases.
-   **Incremental Analysis**: For local repositories, it can perform an incremental analysis by comparing against a previous result, processing only the files that have been added, modified, or deleted.
-   **Real-time Progress**: Monitor the analysis progress through a callback, perfect for providing feedback in a UI or CLI.
-   **Customizable**: Fine-tune the analysis with a rich configuration object, or use dependency injection for complete control.

## 🚀 Getting Started

### 1. Installation

```bash
flutter pub add github_analyzer
```

Or add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  github_analyzer: ^0.0.4 # Replace with the latest version
```

Then, install it by running:

```bash
dart pub get
```

### 2. Basic Usage

Analyzing a remote repository is as simple as a single function call.

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  try {
    // 1. Analyze a repository with just one line of code.
    final result = await analyze(
      'https://github.com/flutter/flutter',
      // Optional: Get real-time progress updates.
      progressCallback: (progress) {
        final percentage = (progress.progress * 100).toStringAsFixed(1);
        print('[${progress.phase.name}] $percentage% - ${progress.message}');
      },
      // Optional: Enable verbose logging for debugging.
      verbose: true,
    );

    // 2. Use the results.
    print('\nAnalysis Complete!');
    print('Repository: ${result.metadata.fullName}');
    print('Primary Language: ${result.metadata.language}');
    print('Total Files Analyzed: ${result.files.length}');
    print('Total Lines of Code: ${result.statistics.totalLines}');

    // 3. Generate a detailed context file for LLMs or documentation.
    await ContextGenerator.generate(result, './flutter_analysis_context.md');
    print('\nContext file generated at ./flutter_analysis_context.md');

  } catch (e) {
    print('An error occurred during analysis: $e');
  }
}
```

## ⚙️ Advanced Usage

### Analyzing a Local Directory

To analyze a project on your local machine, simply provide the file path.

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // The top-level 'analyze' function works for local paths too.
  final result = await analyze('/path/to/your/project');
  print('Analysis of local directory complete!');
  print('Project Name: ${result.metadata.name}');
}
```

### Custom Configuration

For more control, you can pass a `GithubAnalyzerConfig` object to the `analyze` function.

```dart
final config = GithubAnalyzerConfig(
  // Provide a GitHub token for higher API rate limits
  githubToken: 'YOUR_GITHUB_TOKEN', // Recommended for frequent use

  // Exclude additional patterns from analysis
  excludePatterns: [
    ...kDefaultExcludePatterns, // It's good practice to keep the defaults
    '**/*.g.dart',
    '**/test_data/**',
  ],

  // Set max file size to 5MB
  maxFileSize: 5 * 1024 * 1024,

  // Disable caching if needed
  enableCache: false,
);

final result = await analyze(
  'https://github.com/your/repo',
  config: config,
);
```

### Full Control with Dependency Injection

For maximum flexibility (e.g., in a larger application or for extensive testing), you can construct the `GithubAnalyzer` class by manually creating and injecting its dependencies.

```dart
// 1. Create a configuration object.
final config = GithubAnalyzerConfig();

// 2. Manually create all service dependencies.
final httpClientManager = HttpClientManager();
final apiProvider = GithubApiProvider(httpClientManager: httpClientManager, token: config.githubToken);
// ... create other services like ZipDownloader, CacheService, etc.

// 3. Inject dependencies into the GithubAnalyzer constructor.
final analyzer = GithubAnalyzer(
  config: config,
  httpClientManager: httpClientManager,
  apiProvider: apiProvider,
  // ... inject all other required services
);

// 4. Use the analyzer instance.
final result = await analyzer.analyze('https://github.com/your/repo');

// 5. Remember to dispose of resources.
await analyzer.dispose();
```

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on the [GitHub issue tracker](https://github.com/cruxhan/github_analyzer/issues).

## 📄 License

This package is licensed under the **MIT License**. See the `LICENSE` file for details.