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
- ⚡ **Cache Control** - Explicitly enable/disable caching
- 🔑 **Explicit Token Management** - Direct token passing for better security

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
  github_analyzer: ^0.1.9
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

**Why you need a token:**
- ✅ Access private repositories
- ✅ Increased API rate limit (60 → 5,000 req/hr)
- ✅ Prevent 403 errors

**How to get a token:**
1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens?type=beta)
2. Generate fine-grained token (recommended)
3. Set Contents: Read-only permission
4. Copy the token

### 2. Basic Usage (Public Repository)

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // Analyze a public repository
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
  // Analyze private repository with token
  final result = await analyzeQuick(
    'https://github.com/your/private-repo',
    githubToken: 'ghp_your_token_here', // Pass token explicitly
  );

  print('Files: ${result.statistics.totalFiles}');
}
```

### 4. Generate Markdown for LLM

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // LLM-optimized analysis and markdown generation
  final outputPath = await analyzeForLLM(
    'https://github.com/your/repo',
    githubToken: 'ghp_your_token_here', // For private repos
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
  // Create analyzer with custom config
  final config = await GithubAnalyzerConfig.create(
    githubToken: 'ghp_your_token_here', // Pass token explicitly
    excludePatterns: ['test/', 'docs/'],
    maxFileSize: 1024 * 1024, // 1MB
    enableCache: true,
  );

  final analyzer = await GithubAnalyzer.create(config: config);

  // Analyze remote repository (disable cache)
  final result = await analyzer.analyzeRemote(
    repositoryUrl: 'https://github.com/your/repo',
    useCache: false, // Always fetch latest data
  );

  // Generate compact markdown
  final contextService = ContextService();
  final outputPath = await contextService.generate(
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
final config = await GithubAnalyzerConfig.quick(
  githubToken: 'your_token', // Optional for public repos
);
```

- ⚡ Fast speed
- 📄 Max 100 files
- 🚫 Cache disabled
- 🚫 Isolate disabled

### LLM Optimized (Balanced)

```dart
final config = await GithubAnalyzerConfig.forLLM(
  githubToken: 'your_token', // Optional for public repos
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
  githubToken: 'your_token', // Optional for public repos
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
4. Copy token

### Classic Token

1. [Create token](https://github.com/settings/tokens)
2. Scopes: Check `repo`
3. Copy token

### Use in Code

```dart
// Option 1: Pass token to convenience functions
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'ghp_your_token_here',
);

// Option 2: Pass token via config
final config = await GithubAnalyzerConfig.create(
  githubToken: 'ghp_your_token_here',
);
final analyzer = await GithubAnalyzer.create(config: config);
```

### Secure Token Management

**Best practices:**

```dart
// 1. Load from environment variables
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
// 2. Load from secure storage (mobile/desktop)
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
// Quick analysis (public repo)
final result = await analyzeQuick('https://github.com/user/repo');

// Quick analysis (private repo)
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'your_token',
);

// LLM-optimized analysis + markdown generation
final outputPath = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'your_token', // Optional for public repos
  outputDir: './output',
  maxFiles: 100,
);

// Custom config analysis
final result = await analyze(
  'https://github.com/user/repo',
  config: await GithubAnalyzerConfig.create(
    githubToken: 'your_token',
  ),
  verbose: true,
  useCache: false, // Disable cache
);
```

## 🔍 Troubleshooting

### 403 Forbidden Error

**Cause:** Missing or insufficient GitHub token permissions

**Solution:**
1. Ensure you're passing the token correctly:
   ```dart
   final result = await analyzeQuick(
     'https://github.com/user/repo',
     githubToken: 'ghp_your_token_here',
   );
   ```
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
- Pass GitHub token to increase limit to 5,000 req/hr:
  ```dart
  final result = await analyzeQuick(
    'https://github.com/user/repo',
    githubToken: 'your_token',
  );
  ```

### Cache Not Respecting useCache: false

**Fixed in v0.1.5:** Cache now correctly respects the `useCache` parameter.

```dart
// This will NOT create cache
final result = await analyzer.analyze(
  'https://github.com/user/repo',
  useCache: false,
);
```

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
3. **Token Security**: Never hardcode tokens - use environment variables or secure storage
4. **Performance Optimization**: Enable parallel processing with `enableIsolatePool: true`
5. **LLM Token Savings**: Use `MarkdownConfig.compact`
6. **Private Repos**: Always pass `githubToken` parameter explicitly

## 🆕 What's New in v0.1.7

- ✅ **Fixed:** Cache now respects `useCache: false` parameter
- ✅ **Changed:** Removed automatic .env loading for better security
- ✅ **Improved:** Explicit token passing via parameters
- ✅ **Fixed:** Private repository analysis with HTTP redirect support

---

**Made with ❤️ for the Dart & Flutter community**


# GitHub Analyzer

**AI/LLM을 위한 강력한 GitHub 저장소 분석 도구**

GitHub 저장소를 분석하고 AI 및 LLM 컨텍스트에 최적화된 마크다운 문서를 자동 생성하는 순수 Dart 패키지입니다. 코드 리뷰, 문서화, 프로젝트 온보딩을 AI 지원으로 가속화하세요.

[![pub package](https://img.shields.io/pub/v/github_analyzer.svg)](https://pub.dev/packages/github_analyzer)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## ✨ 주요 기능

- 🚀 **빠르고 효율적** - Isolate 기반 병렬 처리로 최적화
- 📦 **이중 모드** - 로컬 디렉토리 및 원격 GitHub 저장소 지원
- 🎯 **LLM 최적화** - AI 모델을 위한 간결한 컨텍스트 생성
- 🔄 **증분 업데이트** - 빠른 재분석을 위한 스마트 캐싱
- 🌐 **크로스 플랫폼** - 웹, 데스크톱, 모바일에서 작동
- 🔒 **비공개 저장소** - GitHub 토큰으로 비공개 저장소 접근
- ⚡ **캐시 제어** - 캐싱을 명시적으로 활성화/비활성화
- 🔑 **명시적 토큰 관리** - 보안 강화를 위한 직접 토큰 전달

## 🎯 사용 사례

- **AI 코드 리뷰** - ChatGPT/Claude에 전체 프로젝트 컨텍스트 제공
- **자동화된 문서** - 프로젝트 구조 및 기술 스택 자동 분석
- **온보딩** - 신입 팀원과 빠르게 프로젝트 개요 공유
- **CI/CD 통합** - 코드 변경 감지 및 자동 리포트 생성
- **프로젝트 비교** - 다양한 저장소의 구조 및 복잡성 비교

## 📦 설치

`pubspec.yaml`에 추가:

```yaml
dependencies:
  github_analyzer: ^0.1.5
```

설치:

```bash
dart pub get
```

## 🚀 빠른 시작

### 1. GitHub 토큰 발급 (선택사항이지만 권장)

**토큰이 필요한 이유:**
- ✅ 비공개 저장소 접근
- ✅ API 속도 제한 증가 (60 → 5,000 req/hr)
- ✅ 403 오류 방지

**토큰 발급 방법:**
1. [GitHub Settings → Tokens](https://github.com/settings/tokens?type=beta) 방문
2. Fine-grained 토큰 생성 (권장)
3. Contents: Read-only 권한 설정
4. 토큰 복사

### 2. 기본 사용법 (공개 저장소)

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // 공개 저장소 분석
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
  // 토큰으로 비공개 저장소 분석
  final result = await analyzeQuick(
    'https://github.com/your/private-repo',
    githubToken: 'ghp_your_token_here', // 토큰 명시적 전달
  );

  print('파일: ${result.statistics.totalFiles}');
}
```

### 4. LLM용 마크다운 생성

```dart
import 'package:github_analyzer/github_analyzer.dart';

void main() async {
  // LLM 최적화 분석 및 마크다운 생성
  final outputPath = await analyzeForLLM(
    'https://github.com/your/repo',
    githubToken: 'ghp_your_token_here', // 비공개 저장소의 경우
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
  // 사용자 정의 설정으로 분석기 생성
  final config = await GithubAnalyzerConfig.create(
    githubToken: 'ghp_your_token_here', // 토큰 명시적 전달
    excludePatterns: ['test/', 'docs/'],
    maxFileSize: 1024 * 1024, // 1MB
    enableCache: true,
  );

  final analyzer = await GithubAnalyzer.create(config: config);

  // 원격 저장소 분석 (캐시 비활성화)
  final result = await analyzer.analyzeRemote(
    repositoryUrl: 'https://github.com/your/repo',
    useCache: false, // 항상 최신 데이터 가져오기
  );

  // 간결한 마크다운 생성
  final contextService = ContextService();
  final outputPath = await contextService.generate(
    result,
    outputDir: './output',
    config: MarkdownConfig.compact,
  );

  print('생성됨: $outputPath');

  // 리소스 정리
  await analyzer.dispose();
}
```

## ⚙️ 설정 옵션

### 빠른 분석 (고속)

```dart
final config = await GithubAnalyzerConfig.quick(
  githubToken: 'your_token', // 공개 저장소는 선택사항
);
```

- ⚡ 빠른 속도
- 📄 최대 100개 파일
- 🚫 캐시 비활성화
- 🚫 Isolate 비활성화

### LLM 최적화 (균형)

```dart
final config = await GithubAnalyzerConfig.forLLM(
  githubToken: 'your_token', // 공개 저장소는 선택사항
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
  githubToken: 'your_token', // 공개 저장소는 선택사항
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

### Fine-grained 토큰 (권장)

1. [토큰 생성](https://github.com/settings/tokens?type=beta)
2. Repository access: "Only select repositories" 선택
3. Permissions: Contents: Read-only 설정
4. 토큰 복사

### 클래식 토큰

1. [토큰 생성](https://github.com/settings/tokens)
2. Scopes: `repo` 체크
3. 토큰 복사

### 코드에서 사용

```dart
// 옵션 1: 편의 함수에 토큰 전달
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'ghp_your_token_here',
);

// 옵션 2: 설정을 통해 토큰 전달
final config = await GithubAnalyzerConfig.create(
  githubToken: 'ghp_your_token_here',
);
final analyzer = await GithubAnalyzer.create(config: config);
```

### 토큰 안전 관리

**모범 사례:**

```dart
// 1. 환경 변수에서 로드
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
// 2. 보안 저장소에서 로드 (모바일/데스크톱)
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

## 📤 출력 형식

### 간결한 형식 (LLM 친화적)

```dart
final config = MarkdownConfig.compact;
```

- 최소 포맷팅
- 통계 없음
- 토큰 수 최적화

### 표준 형식 (균형)

```dart
final config = MarkdownConfig.standard;
```

- 통계 포함
- 코드 블록
- 디렉토리 트리

### 상세 형식 (종합)

```dart
final config = MarkdownConfig.detailed;
```

- 전체 통계
- 언어 분포
- 의존성 분석

## 🌍 플랫폼 지원

| 플랫폼 | 로컬 분석 | 원격 분석 | 캐시 | Isolates |
|------|---------|---------|------|----------|
| 데스크톱 | ✅ | ✅ | ✅ | ✅ |
| 모바일 | ✅ | ✅ | ✅ | ✅ |
| 웹 | ❌ | ✅ | ⚠️* | ❌ |

*웹은 브라우저 저장소 사용

## 🛠️ 편의 함수

```dart
// 빠른 분석 (공개 저장소)
final result = await analyzeQuick('https://github.com/user/repo');

// 빠른 분석 (비공개 저장소)
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: 'your_token',
);

// LLM 최적화 분석 + 마크다운 생성
final outputPath = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'your_token', // 공개 저장소는 선택사항
  outputDir: './output',
  maxFiles: 100,
);

// 사용자 정의 설정 분석
final result = await analyze(
  'https://github.com/user/repo',
  config: await GithubAnalyzerConfig.create(
    githubToken: 'your_token',
  ),
  verbose: true,
  useCache: false, // 캐시 비활성화
);
```

## 🔍 문제 해결

### 403 Forbidden 오류

**원인:** 누락되었거나 불충분한 GitHub 토큰 권한

**해결책:**
1. 토큰을 올바르게 전달하는지 확인:
   ```dart
   final result = await analyzeQuick(
     'https://github.com/user/repo',
     githubToken: 'ghp_your_token_here',
   );
   ```
2. Fine-grained 토큰: 저장소 접근 설정 확인
3. 클래식 토큰: `repo` 범위 활성화 확인
4. 토큰 테스트: `curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user`

### 404 Not Found 오류

**원인:** 저장소가 없음, 토큰 없이 비공개 저장소 접근, 잘못된 브랜치명

**해결책:**
1. 저장소 URL 정확성 확인
2. 비공개 저장소에 GitHub 토큰 추가
3. 기본 브랜치명 확인 (main vs master)

### Rate Limit 초과

**원인:** GitHub API 속도 제한 (토큰 없음: 60 req/hr)

**해결책:**
- GitHub 토큰을 전달하여 한도 증가 (5,000 req/hr):
  ```dart
  final result = await analyzeQuick(
    'https://github.com/user/repo',
    githubToken: 'your_token',
  );
  ```

### useCache: false를 무시하는 캐시

**v0.1.5에서 수정됨:** 캐시가 `useCache` 파라미터를 올바르게 인식합니다.

```dart
// 이제 캐시를 생성하지 않습니다
final result = await analyzer.analyze(
  'https://github.com/user/repo',
  useCache: false,
);
```

## 📝 예제

`example/` 디렉토리에서 더 많은 예제를 확인하세요:

- `demo.dart` - 성능 메트릭스를 포함한 종합 데모
- 기본 사용 예제
- 사용자 정의 설정 예제

## 🤝 기여하기

기여는 항상 환영합니다! Pull Request를 자유롭게 제출하세요.

### 개발 환경 설정

```bash
# 저장소 복제
git clone https://github.com/cruxhan/github_analyzer.git

# 의존성 설치
dart pub get

# 테스트 실행
dart test
```

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일 참조

## 🔗 링크

- [pub.dev 패키지](https://pub.dev/packages/github_analyzer)
- [GitHub 저장소](https://github.com/cruxhan/github_analyzer)
- [이슈 추적](https://github.com/cruxhan/github_analyzer/issues)
- [변경 로그](CHANGELOG.md)

## 💡 사용 팁

1. **대규모 저장소**: `maxFiles` 파라미터로 파일 수 제한
2. **캐시 관리**: 최신 데이터를 위해 `useCache: false` 사용
3. **토큰 보안**: 환경 변수 또는 보안 저장소 사용
4. **성능 최적화**: `enableIsolatePool: true`로 병렬 처리 활성화
5. **LLM 토큰 절약**: `MarkdownConfig.compact` 사용
6. **비공개 저장소**: 항상 `githubToken` 파라미터 명시적 전달

## 🆕 v0.1.5의 새 기능

- ✅ **수정됨:** `useCache: false` 파라미터 캐시 존중
- ✅ **변경됨:** 보안 강화를 위해 자동 .env 로드 제거
- ✅ **개선됨:** 파라미터를 통한 명시적 토큰 전달
- ✅ **수정됨:** HTTP 리다이렉트 지원 추가

---

**Dart & Flutter 커뮤니티를 위해 ❤️ 으로 만들어졌습니다**
