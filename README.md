# README Tabs (English / 한국어)

<details open>
<summary><strong>🇺🇸 English Version</strong></summary>

---

# GitHub Analyzer

**Powerful GitHub Repository Analysis Tool for AI/LLM**

A pure Dart package that analyzes GitHub repositories and automatically generates markdown documentation optimized for AI and LLM contexts.

## ✨ Key Features

- 🚀 **Fast & Efficient** - Optimized with isolate-based parallel processing
- 📦 **Dual Mode** - Supports both local directories and remote GitHub repositories
- 🎯 **LLM Optimized** - Generates compact context for AI models
- 🔄 **Incremental Updates** - Smart caching for fast re-analysis
- 🌐 **Cross-Platform** - Works on web, desktop, and mobile
- 🔒 **Private Repositories** - Access private repos with GitHub tokens
- ⚡ **Cache Control** - Explicitly enable/disable caching
- 🔑 **Explicit Token Management** - Direct token passing for better security

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  github_analyzer: ^0.2.0
```

Install:

```bash
dart pub get
```

or

```bash
dart pub add github_analyzer
```

## 🚀 Quick Start

### 1. Get GitHub Token (Optional but Recommended)

**How to get a token:**
1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens?type=beta)
2. Generate fine-grained token (recommended)
3. Set Contents: Read-only permission
4. Copy the token

### 2. Basic Usage (Public Repository)

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final result = await analyzeQuick(
    'https://github.com/flutter/flutter',
  );

  print('Files: ${result.statistics.totalFiles}');
  print('Lines: ${result.statistics.totalLines}');
  print('Language: ${result.metadata.language}');
}
```

### 3. Private Repository Analysis

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final result = await analyzeQuick(
    'https://github.com/your/private-repo',
    githubToken: 'ghp_your_token_here',
  );

  print('Files: ${result.statistics.totalFiles}');
}
```

### 4. Generate Markdown for LLM

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final outputPath = await analyzeForLLM(
    'https://github.com/your/repo',
    githubToken: 'ghp_your_token_here',
    outputDir: './analysis',
    maxFiles: 200,
  );

  print('Generated: $outputPath');
}
```

### 5. Advanced Usage

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final config = await GithubAnalyzerConfig.create(
    githubToken: 'ghp_your_token_here',
    excludePatterns: ['test/', 'docs/'],
    maxFileSize: 1024 * 1024,
    enableCache: true,
  );

  final analyzer = await GithubAnalyzer.create(config: config);

  final result = await analyzer.analyzeRemote(
    repositoryUrl: 'https://github.com/your/repo',
    useCache: false,
  );

  final contextService = ContextService();
  final outputPath = await contextService.generate(
    result,
    outputDir: './output',
    config: MarkdownConfig.compact,
  );

  print('Generated: $outputPath');
  await analyzer.dispose();
}
```

## ⚙️ Configuration Options

### Quick Analysis (Fast)

```dart
final config = await GithubAnalyzerConfig.quick(
  githubToken: 'your_token',
);
```

- ⚡ Fast speed
- 📄 Max 100 files
- 🚫 Cache disabled
- 🚫 Isolate disabled

### LLM Optimized (Balanced)

```dart
final config = await GithubAnalyzerConfig.forLLM(
  githubToken: 'your_token',
  maxFiles: 200,
);
```

- ⚖️ Balanced performance
- 📄 Custom file count
- ✅ Cache enabled
- ✅ Isolate enabled
- 🧪 Test files excluded

### Full Analysis (Comprehensive)

```dart
final config = await GithubAnalyzerConfig.create(
  githubToken: 'your_token',
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

### Use in Code

```dart
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'ghp_your_token_here',
);

final config = await GithubAnalyzerConfig.create(
  githubToken: 'ghp_your_token_here',
);
final analyzer = await GithubAnalyzer.create(config: config);
```

### Secure Token Management

```dart
import 'dart:io';

void main() async {
  final token = Platform.environment['GITHUB_TOKEN'];
  
  final result = await analyzeQuick(
    'https://github.com/user/repo',
    githubToken: token,
  );
}
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> analyze() async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'github_token');
  
  final result = await analyzeQuick(
    'https://github.com/user/repo',
    githubToken: token,
  );
}
```

## 🛠️ Convenience Functions

```dart
final result = await analyzeQuick('https://github.com/user/repo');

final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'your_token',
);

final outputPath = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'your_token',
  outputDir: './output',
  maxFiles: 100,
);

final result = await analyze(
  'https://github.com/user/repo',
  config: await GithubAnalyzerConfig.create(
    githubToken: 'your_token',
  ),
  verbose: true,
  useCache: false,
);
```

## 🔍 Troubleshooting

### 403 Forbidden Error

```dart
final result = await analyzeQuick(
  'https://github.com/user/repo',
  githubToken: 'ghp_your_token_here',
);
```

### 404 Not Found Error

Verify repository URL is correct and add GitHub token for private repos.

### Cache Not Respecting useCache: false

```dart
final result = await analyzer.analyze(
  'https://github.com/user/repo',
  useCache: false,
);
```

## 📝 Examples

Check out more examples in the `example/` directory.

## 📄 License

MIT License

---

</details>

<details>
<summary><strong>🇰🇷 한국어 버전</strong></summary>

---

# GitHub Analyzer

**AI/LLM을 위한 강력한 GitHub 저장소 분석 도구**

GitHub 저장소를 분석하고 AI 및 LLM 컨텍스트에 최적화된 마크다운 문서를 자동 생성하는 순수 Dart 패키지입니다.

## ✨ 주요 기능

- 🚀 **빠르고 효율적** - Isolate 기반 병렬 처리로 최적화
- 📦 **이중 모드** - 로컬 디렉토리 및 원격 GitHub 저장소 지원
- 🎯 **LLM 최적화** - AI 모델을 위한 간결한 컨텍스트 생성
- 🔄 **증분 업데이트** - 빠른 재분석을 위한 스마트 캐싱
- 🌐 **크로스 플랫폼** - 웹, 데스크톱, 모바일에서 작동
- 🔒 **비공개 저장소** - GitHub 토큰으로 비공개 저장소 접근
- ⚡ **캐시 제어** - 캐싱을 명시적으로 활성화/비활성화
- 🔑 **명시적 토큰 관리** - 보안 강화를 위한 직접 토큰 전달

## 📦 설치

`pubspec.yaml`에 추가:

```yaml
dependencies:
  github_analyzer: ^0.2.0
```

설치:

```bash
dart pub get
```

또는

```bash
dart pub add github_analyzer
```

## 🚀 빠른 시작

### 1. GitHub 토큰 발급 (선택사항이지만 권장)

**토큰 발급 방법:**
1. [GitHub Settings → Tokens](https://github.com/settings/tokens?type=beta) 방문
2. Fine-grained 토큰 생성 (권장)
3. Contents: Read-only 권한 설정
4. 토큰 복사

### 2. 기본 사용법 (공개 저장소)

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final result = await analyzeQuick(
    'https://github.com/flutter/flutter',
  );

  print('파일: ${result.statistics.totalFiles}');
  print('라인: ${result.statistics.totalLines}');
  print('언어: ${result.metadata.language}');
}
```

### 3. 비공개 저장소 분석

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final result = await analyzeQuick(
    'https://github.com/your/private-repo',
    githubToken: 'ghp_your_token_here',
  );

  print('파일: ${result.statistics.totalFiles}');
}
```

### 4. LLM용 마크다운 생성

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final outputPath = await analyzeForLLM(
    'https://github.com/your/repo',
    githubToken: 'ghp_your_token_here',
    outputDir: './analysis',
    maxFiles: 200,
  );

  print('생성됨: $outputPath');
}
```

### 5. 고급 사용법

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  final config = await GithubAnalyzerConfig.create(
    githubToken: 'ghp_your_token_here',
    excludePatterns: ['test/', 'docs/'],
    maxFileSize: 1024 * 1024,
    enableCache: true,
  );

  final analyzer = await GithubAnalyzer.create(config: config);

  final result = await analyzer.analyzeRemote(
    repositoryUrl: 'https://github.com/your/repo',
    useCache: false,
  );

  final contextService = ContextService();
  final outputPath = await contextService.generate(
    result,
    outputDir: './output',
    config: MarkdownConfig.compact,
  );

  print('생성됨: $outputPath');
  await analyzer.dispose();
}
```

## ⚙️ 설정 옵션

### 빠른 분석 (고속)

```dart
final config = await GithubAnalyzerConfig.quick(
  githubToken: 'your_token',
);
```

- ⚡ 빠른 속도
- 📄 최대 100개 파일
- 🚫 캐시 비활성화
- 🚫 Isolate 비활성화

### LLM 최적화 (균형)

```dart
final config = await GithubAnalyzerConfig.forLLM(
  githubToken: 'your_token',
  maxFiles: 200,
);
```

- ⚖️ 균형잡힌 성능
- 📄 사용자 정의 파일 수
- ✅ 캐시 활성화
- ✅ Isolate 활성화
- 🧪 테스트 파일 제외

### 전체 분석 (종합)

```dart
final config = await GithubAnalyzerConfig.create(
  githubToken: 'your_token',
  enableCache: true,
  enableIsolatePool: true,
  maxConcurrentRequests: 10,
);
```

- 🔍 상세 분석
- ♾️ 무제한 파일
- ⚡ 최대 동시성
- 💾 최적화된 캐싱

## 🔑 비공개 저장소 접근

### 코드에서 사용

```dart
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'ghp_your_token_here',
);

final config = await GithubAnalyzerConfig.create(
  githubToken: 'ghp_your_token_here',
);
final analyzer = await GithubAnalyzer.create(config: config);
```

### 토큰 안전 관리

```dart
import 'dart:io';

void main() async {
  final token = Platform.environment['GITHUB_TOKEN'];
  
  final result = await analyzeQuick(
    'https://github.com/user/repo',
    githubToken: token,
  );
}
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> analyze() async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'github_token');
  
  final result = await analyzeQuick(
    'https://github.com/user/repo',
    githubToken: token,
  );
}
```

## 🛠️ 편의 함수

```dart
final result = await analyzeQuick('https://github.com/user/repo');

final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'your_token',
);

final outputPath = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'your_token',
  outputDir: './output',
  maxFiles: 100,
);

final result = await analyze(
  'https://github.com/user/repo',
  config: await GithubAnalyzerConfig.create(
    githubToken: 'your_token',
  ),
  verbose: true,
  useCache: false,
);
```

## 🔍 문제 해결

### 403 Forbidden 오류

```dart
final result = await analyzeQuick(
  'https://github.com/user/repo',
  githubToken: 'ghp_your_token_here',
);
```

### 404 Not Found 오류

저장소 URL이 정확한지 확인하고 비공개 저장소에 대해 GitHub 토큰을 추가하세요.

### useCache: false를 무시하는 캐시

```dart
final result = await analyzer.analyze(
  'https://github.com/user/repo',
  useCache: false,
);
```

## 📝 예제

`example/` 디렉토리에서 더 많은 예제를 확인하세요.

## 📄 라이선스

MIT License

---

</details>
