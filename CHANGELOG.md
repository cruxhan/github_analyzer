# CHANGELOG Tabs (English / 한국어)

<details open>
<summary><strong>🇺🇸 English Version</strong></summary>

---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-07

### Added
- **Improved branch detection** - Automatic fallback to default branches when explicit branch fails
- **Remote analyzer service refactoring** - Better progress tracking and metadata handling

### Enhanced
- **Code refactoring** - Reduced codebase by ~40% through duplicate removal
- **Helper method extraction** - Added utility methods for common operations across services
- **Error handling consolidation** - Unified exception handling patterns
- **Validation logic integration** - Centralized parameter validation in config service
- **Method separation** - Improved code organization in LocalAnalyzerService

### Fixed
- **Type casting issue** - Fixed List<dynamic> to List<String> conversion in directory tree generation
- **Isolate pool serialization** - Improved error handling for function serialization failures

### Optimized
- **Cache service** - New helper methods for file operations (_fileExists, _isNotExpired, _readJsonFile)
- **IsolatePool** - Extracted message validation and result handling to separate methods
- **RemoteAnalyzerService** - Extracted URL building and exception creation to helpers
- **MarkdownService** - Streamlined content generation pipeline

### Documentation
- **All comments** - Converted to English with Dart doc style formatting
- **Public APIs** - Added comprehensive documentation for all core services


## [0.1.9] - 2025-11-06

### Enhanced
- **Expanded exclude patterns** - Added comprehensive file exclusion patterns for platform-specific builds (Android, iOS, Windows, Linux, macOS, Web), CI/CD caches, IDE configurations, and system files to significantly reduce token consumption and improve analysis focus on user-written code.

## [0.1.7] - 2025-11-04

### Added
- Added detailed DartDoc comments for all public API functions and main entrypoints
- Enhanced dependency injection mechanism to properly propagate GitHub token across services
- Improved error handling and logging during repository download and analysis phases
- Supported better markdown generation options for LLM-optimized outputs
- Added progress tracking callbacks to all analysis entry points for real-time status updates

### Fixed
- Fixed issue where GitHub token was not passed correctly leading to failed private repository downloads
- Resolved rare race condition during cache initialization
- Fixed several null pointer exceptions in remote analysis code paths
- Addressed 404 errors on unexpected branch names with clearer error messages

## [0.1.6] - 2025-11-03

### 🔥 Breaking Changes - Removed Automatic .env Loading

```dart
// Before (v0.1.5)
final result = await analyzeForLLM('https://github.com/user/repo');

// After (v0.1.6+)
final result = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'ghp_your_token_here',
);
```

### 🐛 Critical Fixes - Cache Respecting useCache: false

```dart
// Before (v0.1.5)
if (config.enableCache && cacheService != null) {
  await cacheService!.set(repositoryUrl, cacheKey, result);
}

// After (v0.1.6)
if (useCache && config.enableCache && cacheService != null) {
  await cacheService!.set(repositoryUrl, cacheKey, result);
}
```

### 🗑️ Removed
- EnvLoader: Removed `src/common/env_loader.dart`
- Auto .env Loading: Removed from `GithubAnalyzerConfig.create()`, `.quick()`, `.forLLM()`
- Service Locator .env: Removed automatic token loading from DI container

### ✨ Added
- **Explicit Token Passing**: All functions now support direct `githubToken` parameter
- **DartDoc Documentation**: Added comprehensive English documentation to all public APIs
- **Security Guidelines**: Added best practices for token management in README

### ⚠️ Migration Required

```dart
// Option 1: Environment variable
import 'dart:io';
final token = Platform.environment['GITHUB_TOKEN'];
final result = await analyzeForLLM(
  'https://github.com/user/private-repo',
  githubToken: token,
);

// Option 2: Secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final storage = FlutterSecureStorage();
final token = await storage.read(key: 'github_token');
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: token,
);

// Option 3: Config object
final config = await GithubAnalyzerConfig.create(
  githubToken: 'ghp_your_token',
);
final analyzer = await GithubAnalyzer.create(config: config);
```

### 🎯 Benefits
- ✅ **Better Security**: No file system access for sensitive data
- ✅ **Cross-Platform**: Works reliably on all platforms including sandboxed environments
- ✅ **Explicit Control**: Users have full control over token source
- ✅ **Flexibility**: Easy integration with various secret management solutions

---

## [0.1.5] - 2025-11-03

### 🔥 Critical Fixes - Private Repository Analysis

```dart
// HTTP Redirect Support
BaseOptions(
  connectTimeout: requestTimeout,
  receiveTimeout: requestTimeout,
  sendTimeout: requestTimeout,
  followRedirects: true,  // ✅ NEW
  maxRedirects: 5,         // ✅ NEW
)

// Token Change Detection
if (config != null && getIt.isRegistered<GithubAnalyzerConfig>()) {
  final existingConfig = getIt<GithubAnalyzerConfig>();
  if (existingConfig.githubToken != config.githubToken) {
    await getIt.reset();
  }
}
```

### 🎯 Results

| Repository Type | Status | Auto-Token | Files |
|-----------------|--------|-----------|-------|
| Public | ✅ | Yes | 249+ |
| Public (with token) | ✅ | Yes | 49+ |
| Private (with token) | ✅ | Yes | 121+ |

### ✅ Usage

```dart
await analyzeForLLM(
  'https://github.com/private/repo.git',
  outputDir: './output',
);
// ✅ Token auto-loaded, private repo analyzed!
```

---

## [0.1.4] - 2025-11-03

### Fixed
- **Fixed EnvLoader project root detection**: Now automatically searches for `.env` file in the project root
- Added `_findEnvFile()` method traversing up to 10 parent directories
- Validates project root by checking for `pubspec.yaml` or `.git`

---

## [0.1.3] - 2025-11-03

### 🔥 Critical Fixes - JSON Serialization

```dart
// Before (broken)
factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
  _$AnalysisResultFromJson(json);

// After (working)
factory AnalysisResult.fromJson(Map<String, dynamic> json) {
  return AnalysisResult(
    metadata: RepositoryMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    files: (json['files'] as List<dynamic>)
      .map((e) => SourceFile.fromJson(e as Map<String, dynamic>))
      .toList(),
    statistics: AnalysisStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
  );
}
```

### Added
- **New `fetchMetadataOnly()` method**: Lightweight metadata retrieval (1-3 seconds)

```dart
final metadata = await analyzer.fetchMetadataOnly('https://github.com/flutter/flutter');
```

---

## [0.0.8] - 2025-10-29

### Added - Explicit Cache Control

```dart
// Disable cache for specific analysis
final result = await analyzeQuick(
  'https://github.com/flutter/flutter',
  useCache: false,
);

// Or with advanced API
final analyzer = await GithubAnalyzer.create();
final result = await analyzer.analyzeRemote(
  repositoryUrl: 'https://github.com/your/repo',
  useCache: false,
);
```

---

## [0.0.7] - 2025-10-19

### Fixed
- Fixed Critical Caching Logic: No more stale data after repository push
- Improved Authentication Compatibility: Standardized all GitHub API requests
- Fixed HTTP Retry Bug: Corrected URI path for retrying timed-out requests

---

## [0.0.6] - 2025-10-15

### Added
- **Automatic `.env` file loading**: GitHub tokens automatically loaded from `.env` files
- **EnvLoader utility**: New `EnvLoader` class for seamless environment variable management
- **Private repository support**: Enhanced ZIP downloader with GitHub API fallback

### Changed
- **Breaking**: `GithubAnalyzerConfig.quick()` and `GithubAnalyzerConfig.forLLM()` are now async

---

## [0.0.5] - 2025-10-14

### Added
- Web platform support with conditional compilation
- `universal_io` package integration for cross-platform compatibility

---

## [0.0.4] - 2025-10-13

### Added
- Incremental analysis support
- Enhanced caching mechanism
- Performance optimizations

---

## [0.0.3] - 2025-10-12

### Added
- LLM-optimized output format
- File prioritization system
- Compact markdown generation

---

## [0.0.2] - 2025-10-11

### Added
- Remote repository analysis
- Local directory analysis
- Basic caching system

---

## [0.0.1] - 2025-10-10

### Added
- Initial release
- Basic GitHub repository analysis
- Markdown generation

---

</details>

<details>
<summary><strong>🇰🇷 한국어 버전</strong></summary>

---

# 변경 로그

이 프로젝트의 모든 주목할 만한 변경사항은 이 파일에 문서화됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)를 기반으로 하며,
이 프로젝트는 [의미있는 버전 관리](https://semver.org/spec/v2.0.0.html)를 따릅니다.

## [1.0.0] - 2025-11-07

### 추가 기능
- **향상된 브런치 감지** - 명시적 브런치 실패 시 기본 브런치로 자동 폴백
- **원격 분석 서비스 리팩토링** - 향상된 진행률 추적 및 메타데이터 처리

### 개선 사항
- **코드 리팩토링** - 중복 제거를 통해 코드베이스 약 40% 축소
- **헬퍼 메서드 추출** - 서비스 전반에서 공통 작업을 위한 유틸리티 메서드 추가
- **에러 처리 통합** - 예외 처리 패턴 통일
- **검증 로직 통합** - 설정 서비스에서 파라미터 검증 중앙화
- **메서드 분리** - LocalAnalyzerService의 코드 조직 개선

### 버그 수정
- **타입 캐스팅 문제** - 디렉토리 트리 생성에서 List<dynamic>을 List<String>으로 변환하는 문제 수정
- **Isolate 풀 직렬화** - 함수 직렬화 실패 시 에러 처리 개선

### 최적화
- **캐시 서비스** - 파일 작업을 위한 새로운 헬퍼 메서드 추가 (_fileExists, _isNotExpired, _readJsonFile)
- **IsolatePool** - 메시지 검증 및 결과 처리를 별도 메서드로 추출
- **RemoteAnalyzerService** - URL 빌드 및 예외 생성을 헬퍼로 추출
- **MarkdownService** - 콘텐츠 생성 파이프라인 간소화

### 문서화
- **모든 주석** - Dart doc 스타일 형식으로 영문으로 변환
- **공개 API** - 모든 핵심 서비스에 대한 포괄적인 문서화 추가


## [0.1.9] - 2025-11-06

### 개선
- **exclude 패턴 대폭 강화** - 플랫폼별 빌드 파일(Android, iOS, Windows, Linux, macOS, Web), CI/CD 캐시, IDE 설정, 시스템 파일 등을 포함한 포괄적인 제외 패턴 추가.

## [0.1.7] - 2025-11-04

### 추가됨
- 모든 공개 API 함수에 상세한 DartDoc 주석 추가
- GitHub 토큰을 서비스 전반에 걸쳐 올바르게 전파하도록 의존성 주입 메커니즘 강화
- 저장소 다운로드 및 분석 단계 중 오류 처리 및 로깅 개선
- LLM 최적화 출력을 위한 더 나은 마크다운 생성 옵션 지원
- 모든 분석 엔트리포인트에 실시간 상태 업데이트를 위한 진행률 추적 콜백 추가

### 수정됨
- GitHub 토큰이 올바르게 전달되지 않아 비공개 저장소 다운로드 실패하는 문제 수정
- 캐시 초기화 중 오래된 데이터 사용으로 인한 드문 레이스 컨디션 해결
- 원격 분석 코드 경로에서 여러 null 포인터 예외 수정
- 예상치 못한 브랜치명에 대한 404 오류를 더 명확한 오류 메시지로 해결

## [0.1.6] - 2025-11-03

### 🔥 주요 변경사항 - 자동 .env 로드 제거

```dart
// 이전 (v0.1.5)
final result = await analyzeForLLM('https://github.com/user/repo');

// 이후 (v0.1.6+)
final result = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'ghp_your_token_here',
);
```

### 🐛 치명적 버그 수정 - useCache: false 파라미터 존중

```dart
// 이전 (v0.1.5)
if (config.enableCache && cacheService != null) {
  await cacheService!.set(repositoryUrl, cacheKey, result);
}

// 이후 (v0.1.6)
if (useCache && config.enableCache && cacheService != null) {
  await cacheService!.set(repositoryUrl, cacheKey, result);
}
```

### 🗑️ 제거됨
- EnvLoader: `src/common/env_loader.dart` 제거
- 자동 .env 로드: `GithubAnalyzerConfig.create()`, `.quick()`, `.forLLM()`에서 제거
- Service Locator .env: DI 컨테이너의 자동 토큰 로드 제거

### ✨ 추가됨
- **명시적 토큰 전달**: 모든 함수가 이제 직접 `githubToken` 파라미터 지원
- **DartDoc 문서화**: 모든 공개 API에 포괄적인 영어 문서 추가
- **보안 가이드라인**: README에 토큰 관리 모범 사례 추가

### ⚠️ 마이그레이션 필수

```dart
// 옵션 1: 환경 변수
import 'dart:io';
final token = Platform.environment['GITHUB_TOKEN'];
final result = await analyzeForLLM(
  'https://github.com/user/private-repo',
  githubToken: token,
);

// 옵션 2: 보안 저장소
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final storage = FlutterSecureStorage();
final token = await storage.read(key: 'github_token');
final result = await analyzeQuick(
  'https://github.com/user/private-repo',
  githubToken: token,
);

// 옵션 3: 설정 객체
final config = await GithubAnalyzerConfig.create(
  githubToken: 'ghp_your_token',
);
final analyzer = await GithubAnalyzer.create(config: config);
```

### 🎯 장점
- ✅ **더 나은 보안**: 민감한 데이터에 대한 파일 시스템 접근 없음
- ✅ **크로스 플랫폼**: 샌드박스 환경을 포함한 모든 플랫폼에서 안정적으로 작동
- ✅ **명시적 제어**: 사용자가 토큰 소스에 대한 완전한 제어 가능
- ✅ **유연성**: 다양한 비밀 관리 솔루션과 쉬운 통합

---

## [0.1.5] - 2025-11-03

### 🔥 치명적 버그 수정 - 비공개 저장소 분석

```dart
// HTTP 리다이렉트 지원
BaseOptions(
  connectTimeout: requestTimeout,
  receiveTimeout: requestTimeout,
  sendTimeout: requestTimeout,
  followRedirects: true,  // ✅ 신규
  maxRedirects: 5,         // ✅ 신규
)

// 토큰 변경 감지
if (config != null && getIt.isRegistered<GithubAnalyzerConfig>()) {
  final existingConfig = getIt<GithubAnalyzerConfig>();
  if (existingConfig.githubToken != config.githubToken) {
    await getIt.reset();
  }
}
```

### 🎯 결과

| 저장소 유형 | 상태 | 자동 토큰 | 파일 |
|-----------|------|---------|------|
| 공개 | ✅ | 예 | 249+ |
| 공개 (토큰 포함) | ✅ | 예 | 49+ |
| 비공개 (토큰 포함) | ✅ | 예 | 121+ |

### ✅ 사용법

```dart
await analyzeForLLM(
  'https://github.com/private/repo.git',
  outputDir: './output',
);
// ✅ .env에서 토큰 자동 로드, 비공개 저장소 성공!
```

---

## [0.1.4] - 2025-11-03

### 수정됨
- **EnvLoader 프로젝트 루트 감지 수정**: 이제 프로젝트 루트에서 `.env` 파일 자동 검색
- 최대 10개 부모 디렉토리까지 트래버스하는 `_findEnvFile()` 메서드 추가
- `pubspec.yaml` 또는 `.git` 확인으로 프로젝트 루트 검증

---

## [0.1.3] - 2025-11-03

### 🔥 치명적 버그 수정 - JSON 직렬화

```dart
// 이전 (손상됨)
factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
  _$AnalysisResultFromJson(json);

// 이후 (작동함)
factory AnalysisResult.fromJson(Map<String, dynamic> json) {
  return AnalysisResult(
    metadata: RepositoryMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    files: (json['files'] as List<dynamic>)
      .map((e) => SourceFile.fromJson(e as Map<String, dynamic>))
      .toList(),
    statistics: AnalysisStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
  );
}
```

### 추가됨
- **새로운 `fetchMetadataOnly()` 메서드**: 가벼운 메타데이터 조회 (1-3초)

```dart
final metadata = await analyzer.fetchMetadataOnly('https://github.com/flutter/flutter');
```

---

## [0.0.8] - 2025-10-29

### 추가됨 - 명시적 캐시 제어

```dart
// 특정 분석에 대해 캐시 비활성화
final result = await analyzeQuick(
  'https://github.com/flutter/flutter',
  useCache: false,
);

// 또는 고급 API 사용
final analyzer = await GithubAnalyzer.create();
final result = await analyzer.analyzeRemote(
  repositoryUrl: 'https://github.com/your/repo',
  useCache: false,
);
```

---

## [0.0.7] - 2025-10-19

### 수정됨
- 치명적 캐싱 로직 수정: 저장소 푸시 후 오래된 데이터 반환 없음
- 인증 호환성 개선: 모든 GitHub API 요청 표준화
- HTTP 재시도 버그 수정: 시간 초과 요청 재시도 URI 경로 수정

---

## [0.0.6] - 2025-10-15

### 추가됨
- **자동 `.env` 파일 로드**: GitHub 토큰이 `.env` 파일에서 자동으로 로드됨
- **EnvLoader 유틸리티**: 원활한 환경 변수 관리를 위한 새로운 `EnvLoader` 클래스
- **비공개 저장소 지원**: 비공개 저장소를 위한 GitHub API 폴백이 있는 향상된 ZIP 다운로더

### 변경됨
- **주요 변경**: `GithubAnalyzerConfig.quick()` 및 `GithubAnalyzerConfig.forLLM()`은 이제 비동기

---

## [0.0.5] - 2025-10-14

### 추가됨
- 조건부 컴파일을 포함한 웹 플랫폼 지원
- `universal_io` 패키지 통합으로 크로스 플랫폼 호환성

---

## [0.0.4] - 2025-10-13

### 추가됨
- 증분 분석 지원
- 강화된 캐싱 메커니즘
- 성능 최적화

---

## [0.0.3] - 2025-10-12

### 추가됨
- LLM 최적화 출력 형식
- 파일 우선순위 지정 시스템
- 간결한 마크다운 생성

---

## [0.0.2] - 2025-10-11

### 추가됨
- 원격 저장소 분석
- 로컬 디렉토리 분석
- 기본 캐싱 시스템

---

## [0.0.1] - 2025-10-10

### 추가됨
- 초기 릴리스
- 기본 GitHub 저장소 분석
- 마크다운 생성

---

</details>
```