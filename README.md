# GitHub Analyzer

**Powerful GitHub Repository Analysis Tool for AI/LLM**

A pure Dart package that analyzes GitHub repositories and automatically generates markdown documentation optimized for AI and LLM contexts. Accelerate code reviews, documentation, and project onboarding with AI assistance.

[![pub package](https://img.shields.io/pub/v/github_analyzer.svg)](https://pub.dev/packages/github_analyzer)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## ✨ Key Features

- 🚀 **Fast & Efficient** - Optimized with isolate-based parallel processing
- 📦 **Dual Mode** - Supports both local directories and remote GitHub repositories
- 🎯 **LLM Optimized** - Generates compact context for AI models
- 🔄 **Incremental Updates** - Smart caching for fast re-analysis
- 🌐 **Cross-Platform** - Works on web, desktop, and mobile
- 🔒 **Private Repositories** - Access private repos with GitHub tokens
- 🔑 **Auto Environment Setup** - Automatically loads tokens from .env files
- ⚡ **Cache Control** - Explicitly enable/disable caching

## 🎯 Use Cases

- **AI Code Review** - Provide full project context to ChatGPT/Claude
- **Automated Documentation** - Auto-analyze project structure and tech stack
- **Onboarding** - Quickly share project overview with new team members
- **CI/CD Integration** - Detect code changes and generate automatic reports
- **Project Comparison** - Compare structure and complexity of multiple repositories

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  github_analyzer: ^0.1.5
```

Install:

```bash
dart pub get
```

## 🚀 Quick Start

### 1. Environment Setup (Optional but Recommended)

Create a `.env` file in your project root:

```env
GITHUB_TOKEN=your_github_token_here
```

**Why you need a token:**
- ✅ Access private repositories
- ✅ Increased API rate limit (60 → 5,000 req/hr)
- ✅ Prevent 403 errors

**How to get a token:**
1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens?type=beta)
2. Generate fine-grained token (recommended)
3. Set Contents: Read-only permission
4. Copy to .env file

### 2. Basic Usage

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // Analyze a repository (token auto-loaded from .env)
  final result = await analyzeQuick(
    'https://github.com/flutter/flutter',
  );

  print('Files: ${result.statistics.totalFiles}');
  print('Lines: ${result.statistics.totalLines}');
  print('Language: ${result.metadata.language}');
}
```

### 3. Generate Markdown for LLM

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // LLM-optimized analysis and markdown generation
  final outputPath = await analyzeForLLM(
    'https://github.com/your/repo',
    outputDir: './analysis',
    maxFiles: 200,
  );

  print('Generated: $outputPath');
}
```

### 4. Advanced Usage

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // Create analyzer with custom config
  final config = await GithubAnalyzerConfig.create(
    githubToken: 'your_token', // or auto-load from .env
    excludePatterns: ['test/', 'docs/'],
    maxFileSize: 1024 * 1024, // 1MB
    enableCache: true,
  );

  final analyzer = await GithubAnalyzer.create(config: config);

  // Analyze remote repository (disable cache)
  final result = await analyzer.analyzeRemote(
    repositoryUrl: 'https://github.com/your/repo',
    useCache: false, // always fetch latest data
  );

  // Generate compact markdown
  final outputPath = await ContextGenerator.generate(
    result,
    outputDir: './output',
    config: MarkdownConfig.compact,
  );

  print('Generated: $outputPath');

  // Clean up resources
  await analyzer.dispose();
}
```

## ⚙️ Configuration Options

### Quick Analysis (Fast)

```dart
final config = await GithubAnalyzerConfig.quick();
```

- ⚡ Fast speed
- 📄 Max 100 files
- 🚫 Cache disabled
- 🚫 Isolate disabled

### LLM Optimized (Balanced)

```dart
final config = await GithubAnalyzerConfig.forLLM(maxFiles: 200);
```

- ⚖️ Balanced performance
- 📄 Custom file count
- ✅ Cache enabled
- ✅ Isolate enabled
- 🧪 Test files excluded

### Full Analysis (Comprehensive)

```dart
final config = await GithubAnalyzerConfig.create(
  enableCache: true,
  enableIsolatePool: true,
  maxConcurrentRequests: 10,
);
```

- 🔍 Detailed analysis
- ♾️ Unlimited files
- ⚡ Maximum concurrency
- 💾 Optimized caching

## 🔑 Private Repository Access

### Fine-grained Token (Recommended)

1. [Create token](https://github.com/settings/tokens?type=beta)
2. Repository access: Select "Only select repositories"
3. Permissions: Contents: Read-only
4. Save to .env:

```env
GITHUB_TOKEN=github_pat_xxxxxxxxxxxxx
```

### Classic Token

1. [Create token](https://github.com/settings/tokens)
2. Scopes: Check `repo`
3. Save to .env:

```env
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
```

### Use in Code

```dart
final config = await GithubAnalyzerConfig.create(
  githubToken: 'your_token_here',
);

final analyzer = await GithubAnalyzer.create(config: config);
```

## 📤 Output Formats

### Compact (LLM Friendly)

```dart
final config = MarkdownConfig.compact;
```

- Minimal formatting
- No statistics
- Token count optimized

### Standard (Balanced)

```dart
final config = MarkdownConfig.standard;
```

- Includes statistics
- Code blocks
- Directory tree

### Detailed (Comprehensive)

```dart
final config = MarkdownConfig.detailed;
```

- Full statistics
- Language distribution
- Dependency analysis

## 🌍 Platform Support

| Platform | Local Analysis | Remote Analysis | Cache | Isolates |
|----------|----------------|-----------------|-------|----------|
| Desktop  | ✅ | ✅ | ✅ | ✅ |
| Mobile   | ✅ | ✅ | ✅ | ✅ |
| Web      | ❌ | ✅ | ⚠️* | ❌ |

*Web uses browser storage instead of file system

## 🛠️ Convenience Functions

```dart
// Quick analysis
final result = await analyzeQuick('https://github.com/user/repo');

// LLM-optimized analysis + markdown generation
final outputPath = await analyzeForLLM(
  'https://github.com/user/repo',
  outputDir: './output',
  maxFiles: 100,
);

// Custom config analysis
final result = await analyze(
  'https://github.com/user/repo',
  config: await GithubAnalyzerConfig.create(),
  verbose: true,
  useCache: false, // disable cache
);
```

## 🔍 Troubleshooting

### 403 Forbidden Error

**Cause:** Missing or insufficient GitHub token permissions

**Solution:**
1. Check token exists in .env file
2. Fine-grained token: Verify repository access settings
3. Classic token: Ensure `repo` scope is enabled
4. Test token: `curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user`

### 404 Not Found Error

**Cause:** Repository doesn't exist, is private without token, or wrong branch name

**Solution:**
1. Verify repository URL is correct
2. Add GitHub token for private repos
3. Check default branch name (main vs master)

### Rate Limit Exceeded

**Cause:** GitHub API rate limit (60 req/hr without token)

**Solution:**
- Add GitHub token to .env file
- With token: 5,000 req/hr

## 📝 Examples

Check out more examples in the `example/` directory:

- `demo.dart` - Comprehensive demo with performance metrics
- Basic usage examples
- Custom configuration examples

## 🤝 Contributing

Contributions are always welcome! Feel free to submit Pull Requests.

### Development Setup

```bash
# Clone repository
git clone https://github.com/cruxhan/github_analyzer.git

# Install dependencies
dart pub get

# Run tests
dart test
```

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🔗 Links

- [pub.dev Package](https://pub.dev/packages/github_analyzer)
- [GitHub Repository](https://github.com/cruxhan/github_analyzer)
- [Issue Tracker](https://github.com/cruxhan/github_analyzer/issues)
- [Changelog](CHANGELOG.md)

## 💡 Usage Tips

1. **Large Repositories**: Limit file count with `maxFiles` parameter
2. **Cache Management**: Use `useCache: false` to always fetch latest data
3. **Token Management**: Keep tokens safe using .env files
4. **Performance Optimization**: Enable parallel processing with `enableIsolatePool: true`
5. **LLM Token Savings**: Use `MarkdownConfig.compact`

---

**Made with ❤️ for the Dart & Flutter community**
