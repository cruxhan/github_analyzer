# GitHub Analyzer

[![pub version](https://img.shields.io/pub/v/github_analyzer.svg)](https://pub.dev/packages/github_analyzer)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible Dart package to analyze GitHub repositories. It can process both remote repositories via URL and local directories on your machine.

This tool is designed to extract comprehensive metadata, generate detailed statistics, and compile source code into a structured context, making it perfect for feeding into Large Language Models (LLMs) or for conducting code audits.

## ✨ Key Features

-   **Dual Analysis Modes**: Analyze repositories from a **remote GitHub URL** or a **local file path** with a single, unified API.
-   **Comprehensive Reports**: Generates a detailed `AnalysisResult` object containing repository metadata, file-by-file analysis, language distribution, dependency detection, and more.
-   **Smart Caching**: Avoids re-analyzing unchanged remote repositories by using a commit-based caching system, saving time and API calls.
-   **High-Performance Local Scans**: Utilizes Dart Isolates for parallel processing of local files, ensuring fast and efficient analysis even on large codebases.
-   **Incremental Analysis**: For local repositories, it can perform an incremental analysis by comparing against a previous result, processing only the files that have been added, modified, or deleted.
-   **Real-time Progress**: Monitor the analysis progress through a `Stream`, perfect for providing feedback in a UI or CLI.
-   **Customizable Output**: Includes utility classes to generate analysis summaries in different formats, such as a comprehensive Markdown file (`ContextGenerator`) or a compact file set (`CfsWriter`) for LLMs.
-   **Configurable**: Fine-tune the analysis by setting custom exclusion patterns, max file size, cache duration, and more.

## 🚀 Getting Started

### 1. Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  github_analyzer: ^0.0.1
```

Then, install it by running:

```bash
dart pub get
```

### 2. Basic Usage

Here are a few examples of how to use the `github_analyzer`.

#### Analyzing a Remote Repository

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // Initialize the analyzer
  final analyzer = GithubAnalyzer();

  // Listen for progress updates
  analyzer.progressStream.listen((progress) {
    print('[${progress.phase.name}] ${progress.percentage.toStringAsFixed(1)}% - ${progress.message}');
  });

  try {
    // Analyze a remote repository
    final result = await analyzer.analyzeRemote(
      repositoryUrl: 'https://github.com/flutter/flutter',
    );

    // Print some results
    print('\nAnalysis Complete!');
    print('Repository: ${result.metadata.fullName}');
    print('Primary Language: ${result.metadata.language}');
    print('Total Files Analyzed: ${result.files.length}');
    print('Total Lines of Code: ${result.statistics.totalLines}');

    // Generate a detailed context file
    await ContextGenerator.generate(result, './flutter_analysis_context.md');
    print('\nContext file generated at ./flutter_analysis_context.md');

  } catch (e) {
    print('An error occurred during analysis: $e');
  } finally {
    // Clean up resources
    analyzer.dispose();
  }
}
```

#### Analyzing a Local Directory

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final analyzer = GithubAnalyzer();

  try {
    // Provide the path to your local project directory
    const String localPath = '/path/to/your/project';

    final result = await analyzer.analyzeLocal(localPath);

    print('Analysis Complete for local directory!');
    print('Project Name: ${result.metadata.name}');
    print('Total Files: ${result.statistics.totalFiles}');

    // You can also perform an incremental analysis
    // final updatedResult = await analyzer.analyzeLocal(localPath, previousResult: result);

  } catch (e) {
    print('An error occurred: $e');
  } finally {
    analyzer.dispose();
  }
}
```

## ⚙️ Configuration

You can customize the analyzer's behavior by passing a `GithubAnalyzerConfig` object during initialization.

```dart
final config = GithubAnalyzerConfig(
  // Provide a GitHub token for higher API rate limits
  githubToken: 'YOUR_GITHUB_TOKEN',
  
  // Exclude additional patterns from analysis
  excludePatterns: [
    ...kDefaultExcludePatterns, // Keep the defaults
    '**/*.g.dart',
    '**/test_data/**',
  ],

  // Set max file size to 5MB
  maxFileSize: 5 * 1024 * 1024,

  // Disable caching if needed
  enableCache: false,
);

final analyzer = GithubAnalyzer(config: config);
```

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on the [GitHub issue tracker](https://github.com/cruxhan/github_analyzer/issues).

## 📄 License

This package is licensed under the **MIT License**. See the `LICENSE` file for details.