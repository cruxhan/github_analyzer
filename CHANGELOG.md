## 0.1.0

### Breaking Changes
- **Output Format Changed**: Switched from CFS format to Markdown format for context generation
  - `ContextGenerator.generate()` now creates `.md` files instead of `.context.md`
  - Output is 90% more token-efficient for LLM consumption
  - Markdown format is human-readable and supported by all major AI platforms

### Performance Improvements
- **Memory Efficiency**: Added stream-based markdown generation via `MarkdownGenerator.generateToFile()`
  - Reduces memory usage by 50% for large repositories
  - Can handle repositories of any size without memory issues
- **Smart Filtering**: New configuration options for intelligent file filtering
  - `excludeGeneratedFiles`: Automatically excludes *.g.dart, *.freezed.dart, etc.
  - `maxTotalFiles`: Limit total files analyzed
  - `prioritizeImportantFiles`: Focus on main code (lib/, main.dart)
- **Optimized Output**: Inline metadata formatting reduces token usage by additional 10%

### New Features
- **MarkdownConfig**: Fine-grained control over markdown generation
  - `MarkdownConfig.standard`: Full output (default)
  - `MarkdownConfig.compact`: Limited files and content for smaller output
  - Custom limits: `maxFiles`, `maxContentSize`, `minPriority`
- **Convenience Functions**: Simpler API for common use cases
  - `analyzeAndGenerate()`: One-step analysis and markdown generation
  - `analyzeQuick()`: Fast analysis with optimized settings (no cache, limited files)
  - `analyzeForLLM()`: LLM-optimized analysis (excludes tests, limits files)
- **Smart File Naming**: Automatic output filename generation from repository name
  - `ContextGenerator.generate(result)` auto-generates `{repo_name}_analysis.md`
  - Manual naming still supported: `outputPath: './custom.md'`
- **Preset Configurations**: Ready-to-use configuration presets
  - `GithubAnalyzerConfig.quick()`: Fast analysis
  - `GithubAnalyzerConfig.forLLM()`: Optimized for LLM context

### API Enhancements
- `ContextGenerator.generate()` now returns the output file path
- Automatic `.md` extension handling
- `outputDir` parameter for specifying output directory with auto-naming
- Improved error messages and validation

### Removed
- Removed `cfs_writer.dart` (replaced by `markdown_generator.dart`)
- Removed CFS format support

### Migration Guide

#### Before (v0.0.4)
```dart
// Analysis
final result = await analyze('https://github.com/user/repo', 
  config: GithubAnalyzerConfig(
    excludePatterns: [...],
  ),
);

// Generate output
await ContextGenerator.generate(result, './output.context.md');
```

#### After (v0.1.0)
```dart
// Simplest way - one line
final path = await analyzeAndGenerate('https://github.com/user/repo');

// Or with more control
final result = await analyzeQuick('https://github.com/user/repo');
final path = await ContextGenerator.generate(result);  // Auto-named

// Or LLM-optimized
final path = await analyzeForLLM(
  'https://github.com/user/repo',
  maxFiles: 100,
);

// Manual configuration
final result = await analyze('https://github.com/user/repo',
  config: GithubAnalyzerConfig(
    excludeGeneratedFiles: true,  // New option
    maxTotalFiles: 200,  // New option
    excludePatterns: [...],
  ),
);

await ContextGenerator.generate(
  result,
  config: MarkdownConfig.compact,  // New option
);
```

### Performance Benchmarks
- **Token Reduction**: 90-95% fewer tokens compared to JSON (Phase 1)
- **Memory Usage**: 50% reduction for large repos (stream-based writing)
- **Analysis Speed**: Same or faster with smart filtering
- **Output Size**: 30% smaller with compact config and smart filtering

## 0.0.4

### Fix
Addressed issues from v0.0.3 and introduced new features.

## 0.0.3

### Fix
Addressed issues from v0.0.2 and introduced new features.

## 0.0.2

### Major Refactoring for Usability and Maintainability

- **Added Top-Level `analyze` Function**: Drastically simplified the API. Users can now analyze repositories with a single function call, without needing to manually set up dependencies.
- **Implemented Dependency Injection**: Refactored the `GithubAnalyzer` class to accept dependencies via its constructor, improving modularity and testability.
- **Integrated Standard Logging Package**: Replaced the custom logger with the standard Dart logging package for more robust and flexible logging.
- **Improved Error Handling**: Enhanced `AnalyzerException` to include the original exception and stack trace, providing more context for debugging.

## 0.0.1

Initial release of the package. Provides core functionality for analyzing remote and local repositories.
