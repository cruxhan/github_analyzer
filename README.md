GitHub Analyzer
A comprehensive GitHub repository analyzer for Dart that generates detailed markdown documentation optimized for AI/LLM context.

[![pub package](https://img.shields.io/pub/vhttps://img.shields.

Features
🚀 Fast & Efficient: Optimized analysis with isolate-based parallel processing

📦 Dual Mode: Analyze both local directories and remote GitHub repositories

🎯 LLM-Optimized: Generate compact, AI-ready documentation

🔄 Incremental Updates: Smart caching for faster re-analysis

🌐 Web Compatible: Works on all platforms including web

🔒 Private Repositories: Full support for private repos with GitHub tokens

🔑 Auto .env Loading: Automatic GitHub token loading from .env files

Installation
Add this to your package's pubspec.yaml file:

yaml dependencies: github_analyzer: ^0.0.6

Then run:

bash dart pub get

Quick Start
1. Setup (Optional but Recommended)
Create a .env file in your project root:

env GITHUB_TOKEN=your_github_token_here

Why use a token?

Access private repositories

Higher API rate limits (5,000 vs 60 requests/hour)

No 403 errors

Getting a token:

Go to GitHub Settings → Tokens

Generate new token (Fine-grained recommended)

Set permissions: Contents: Read-only

Copy token to .env file

2. Basic Usage
```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
// Analyze a repository (token auto-loaded from .env)
final result = await analyzeQuick(
'https://github.com/flutter/flutter',
);

print('Files: ${result.statistics.totalFiles}');
print('Lines: ${result.statistics.totalLines}');
}
```

3. Advanced Usage
```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
// Create analyzer with auto .env loading
final analyzer = await GithubAnalyzer.create();

// Analyze remote repository
final result = await analyzer.analyzeRemote(
repositoryUrl: 'https://github.com/your/repo',
);

// Generate LLM-optimized markdown
final outputPath = await ContextGenerator.generate(
result,
outputDir: './output',
config: MarkdownConfig.compact,
);

print('Generated: $outputPath');

// Cleanup
await analyzer.dispose();
}
```

4. Custom Configuration
```dart
// Create custom config
final config = await GithubAnalyzerConfig.create(
githubToken: 'your_token', // Or auto-load from .env
excludePatterns: ['test/', 'docs/'],
maxFileSize: 1024 * 1024, // 1MB
enableCache: true,
);

// Use with analyzer
final analyzer = await GithubAnalyzer.create(config: config);
```

Configuration Options
Quick Analysis (Fast, Limited)
dart final config = await GithubAnalyzerConfig.quick();

LLM-Optimized (Balanced)
dart final config = await GithubAnalyzerConfig.forLLM(maxFiles: 200);

Full Analysis (Comprehensive)
dart final config = await GithubAnalyzerConfig.create( enableCache: true, enableIsolatePool: true, maxConcurrentRequests: 10, );

Private Repository Access
Using Fine-grained Tokens (Recommended)
Create token: https://github.com/settings/tokens?type=beta

Repository access: Select "Only select repositories" and choose your repos

Permissions: Set Contents: Read-only

Save to .env:
env GITHUB_TOKEN=github_pat_xxxxxxxxxxxxx

Using Classic Tokens
Create token: https://github.com/settings/tokens

Scopes: Check repo (Full control of private repositories)

Save to .env:
env GITHUB_TOKEN=ghp_xxxxxxxxxxxxx

Manual Token Usage
```dart
final config = await GithubAnalyzerConfig.create(
githubToken: 'your_token_here',
);

final analyzer = await GithubAnalyzer.create(config: config);
```

Convenience Functions
```dart
// Quick analysis
final result = await analyzeQuick('https://github.com/user/repo');

// LLM-optimized analysis with markdown generation
final outputPath = await analyzeForLLM(
'https://github.com/user/repo',
outputDir: './output',
maxFiles: 100,
);

// Full analysis with custom config
final result = await analyze(
'https://github.com/user/repo',
config: await GithubAnalyzerConfig.create(),
verbose: true,
);
```

Output Formats
Compact (LLM-friendly)
dart final config = MarkdownConfig.compact;

Minimal formatting

No statistics

Optimized for token count

Standard (Balanced)
dart final config = MarkdownConfig.standard;

Includes statistics

Code blocks

Directory tree

Detailed (Comprehensive)
dart final config = MarkdownConfig.detailed;

Full statistics

Language distribution

Dependency analysis

Platform Support
Platform	Local Analysis	Remote Analysis	Cache	Isolates
Native (Desktop/Mobile)	✅	✅	✅	✅
Web	❌	✅	⚠️ *	❌
*Web uses browser storage instead of file system

Examples
See the example directory for complete examples:

demo.dart - Comprehensive demo with performance metrics

Basic usage examples

Custom configuration examples

Troubleshooting
403 Forbidden Error
Cause: Missing or insufficient GitHub token permissions.

Solution:

Verify token in .env file exists

For Fine-grained tokens: Check repository access settings

For Classic tokens: Ensure repo scope is enabled

Test token: curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

404 Not Found Error
Cause: Repository doesn't exist, is private without token, or wrong branch name.

Solution:

Verify repository URL is correct

Add GitHub token for private repos

Check default branch name (might be master instead of main)

Rate Limit Exceeded
Cause: GitHub API rate limit (60 requests/hour without token).

Solution:

Add GitHub token to .env file

With token: 5,000 requests/hour

License
MIT License - see LICENSE file for details.

Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

Changelog
See CHANGELOG.md for a detailed history of changes.

Links
pub.dev package

GitHub repository

Issue tracker