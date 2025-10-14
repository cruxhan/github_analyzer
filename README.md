# GitHub Analyzer

[![pub version](https://img.shields.io/pub/v/github_analyzer.svg)](https://pub.dev/packages/github_analyzer)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible Dart package to analyze GitHub repositories. It can process both remote repositories via URL and local directories on your machine. This tool is designed to extract comprehensive metadata, generate detailed statistics, and compile source code into a structured markdown context, making it perfect for feeding into Large Language Models (LLMs) or for conducting code audits.

## Key Features

- **Simple & Powerful API**: Analyze any public repository with a single function call. No complex setup required.
- **Dual Analysis Modes**: Analyze repositories from a remote GitHub URL or a local file path.
- **Comprehensive Reports**: Generates a detailed `AnalysisResult` object containing repository metadata, file-by-file analysis, language distribution, dependency detection, and more.
- **Smart Caching**: Avoids re-analyzing unchanged remote repositories by using a commit-based caching system, saving time and API calls.
- **High-Performance Scans**: Utilizes Dart Isolates for parallel processing of local files, ensuring fast and efficient analysis even on large codebases.
- **Incremental Analysis**: For local repositories, it can perform an incremental analysis by comparing against a previous result, processing only the files that have been added, modified, or deleted.
- **Real-time Progress**: Monitor the analysis progress through a callback, perfect for providing feedback in a UI or CLI.
- **Markdown Output**: Generates optimized markdown format that is 90% more token-efficient than JSON, perfect for AI context.
- **Smart Filtering**: Automatically excludes generated files, with configurable limits and priorities.
- **Memory Efficient**: Stream-based markdown generation for handling large repositories.
- **Customizable**: Fine-tune the analysis with a rich configuration object, or use dependency injection for complete control.

## Getting Started

### 1. Installation

```bash
dart pub add github_analyzer
```

Or add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  github_analyzer: ^0.1.0
```

Then install it by running:

```bash
dart pub get
```

### 2. Basic Usage

#### Simplest Way - One Line

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // Analyze and generate markdown in one step
  final outputPath = await analyzeAndGenerate(
    'https://github.com/flutter/flutter',
  );
  
  print('✅ Analysis saved to: $outputPath');
}
```

#### Quick Analysis (Optimized for Speed)

```dart
void main() async {
  // Fast analysis with optimized settings
  final result = await analyzeQuick('https://github.com/dart-lang/sdk');
  
  print('Repository: ${result.metadata.fullName}');
  print('Files: ${result.statistics.totalFiles}');
}
```

#### LLM-Optimized Analysis

```dart
void main() async {
  // Optimized for LLM context with automatic filtering
  final outputPath = await analyzeForLLM(
    'https://github.com/your/repo',
    maxFiles: 100,  // Limit to most important 100 files
    markdownConfig: MarkdownConfig.compact,  // Compact output
  );
  
  print('LLM context ready: $outputPath');
}
```

### 3. Standard Usage with Progress

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  try {
    // Analyze with progress tracking
    final result = await analyze(
      'https://github.com/flutter/flutter',
      
      progressCallback: (progress) {
        final percentage = (progress.progress * 100).toStringAsFixed(1);
        print('${progress.phase.name} $percentage% - ${progress.message}');
      },
      
      verbose: true,
    );
    
    print('✅ Analysis Complete!');
    print('Repository: ${result.metadata.fullName}');
    print('Primary Language: ${result.metadata.language}');
    print('Total Files: ${result.files.length}');
    print('Total Lines: ${result.statistics.totalLines}');
    
    // Generate markdown with auto-naming
    final outputPath = await ContextGenerator.generate(result);
    print('📄 Markdown saved to: $outputPath');
    
  } catch (e) {
    print('❌ An error occurred: $e');
  }
}
```

## Advanced Usage

### Custom Configuration

For more control, use `GithubAnalyzerConfig`:

```dart
final config = GithubAnalyzerConfig(
  githubToken: 'YOUR_GITHUB_TOKEN',
  
  // Smart filtering options
  excludeGeneratedFiles: true,  // Auto-exclude *.g.dart, etc.
  maxTotalFiles: 500,  // Limit total files analyzed
  prioritizeImportantFiles: true,  // Focus on main code
  
  // Additional exclude patterns
  excludePatterns: [
    ...kDefaultExcludePatterns,
    '*.g.dart',
    'test_data/**',
  ],
  
  maxFileSize: 5 * 1024 * 1024,  // 5MB limit
  enableCache: true,
  enableIsolatePool: true,
);

final result = await analyze(
  'https://github.com/your/repo',
  config: config,
);
```

### Preset Configurations

```dart
// Quick analysis (no cache, limited files)
final quickConfig = GithubAnalyzerConfig.quick(
  githubToken: 'YOUR_TOKEN',
);

// LLM-optimized (excludes tests, examples, max 200 files)
final llmConfig = GithubAnalyzerConfig.forLLM(
  githubToken: 'YOUR_TOKEN',
  maxFiles: 200,
);
```

### Markdown Generation Options

```dart
// Standard output (all content)
await ContextGenerator.generate(
  result,
  config: MarkdownConfig.standard,
);

// Compact output (limited files and content)
await ContextGenerator.generate(
  result,
  config: MarkdownConfig.compact,
);

// Custom output
await ContextGenerator.generate(
  result,
  config: MarkdownConfig(
    maxFiles: 100,  // Limit to 100 files
    maxContentSize: 50000,  // Truncate large files
    includeBinaryStats: false,
    includeErrors: false,
  ),
);

// Specify output location
await ContextGenerator.generate(
  result,
  outputPath: './my_analysis.md',
  // or use outputDir to auto-generate filename
  outputDir: './output',
);
```

### Analyzing Local Directories

```dart
// Works the same way
final result = await analyze('/path/to/your/project');

// Or quick local analysis
final result = await analyzeQuick('/path/to/your/project');
```

### Memory-Efficient Large Repository Handling

For very large repositories, use streaming generation:

```dart
final result = await analyze('https://github.com/large/repo');

// Directly write to file without loading full content in memory
await MarkdownGenerator.generateToFile(
  result,
  './large_repo_analysis.md',
  config: MarkdownConfig(
    maxFiles: 200,
    maxContentSize: 100000,
  ),
);
```

## Output Format

The package generates markdown output with the following structure:

```markdown
# Repository Name

## Repository Information
**Repository:** `owner/repo`
**Language:** Dart | **Stars:** 1234 | **Forks:** 567

## Statistics
- **Total Files:** 150
- **Total Lines:** 25000
- **Source Files:** 120

## Directory Structure
`
lib/
  src/
    models/
    services/
`

## Language Distribution
- **Dart:** 120 files (80.0%)
- **YAML:** 15 files (10.0%)

## Source Code
### lib/main.dart
`dart
// Full source code with syntax highlighting
`
```

### Performance Characteristics

- **Token Efficiency**: 90% reduction compared to JSON format
- **Memory Usage**: Stream-based generation handles repositories of any size
- **Speed**: Parallel processing with automatic optimization
- **Smart Filtering**: Automatically excludes generated files and low-priority content

## API Summary

### Quick Functions

- `analyzeAndGenerate()` - Analyze and create markdown in one step
- `analyzeQuick()` - Fast analysis with optimized settings
- `analyzeForLLM()` - LLM-optimized with automatic filtering

### Core Functions

- `analyze()` - Standard analysis with full control
- `ContextGenerator.generate()` - Generate markdown from result
- `MarkdownGenerator.generateToFile()` - Memory-efficient file generation

### Configuration

- `GithubAnalyzerConfig.quick()` - Fast analysis preset
- `GithubAnalyzerConfig.forLLM()` - LLM-optimized preset
- `MarkdownConfig.standard` - Full output
- `MarkdownConfig.compact` - Compact output

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on the [GitHub issue tracker](https://github.com/cruxhan/github_analyzer/issues).

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
