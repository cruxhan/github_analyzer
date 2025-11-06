# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.9] - 2025-11-06

## Enhanced
- **Expanded exclude patterns** - Added comprehensive file exclusion patterns for platform-specific 
  builds (Android, iOS, Windows, Linux, macOS, Web), CI/CD caches, IDE configurations, and system 
  files to significantly reduce token consumption and improve analysis focus on user-written code.

## [0.1.7] - 2025-11-04
- **Added**

Added detailed DartDoc comments for all public API functions and main entrypoints to improve documentation quality and developer experience.

Enhanced dependency injection mechanism to properly propagate GitHub token across services, preventing token loss during analysis.

Improved error handling and logging during repository download and analysis phases.

Supported better markdown generation options for LLM-optimized outputs.

Added progress tracking callbacks to all analysis entry points for real-time status updates.

- **Fixed**

Fixed issue where GitHub token was not passed correctly leading to failed private repository downloads.

Resolved rare race condition during cache initialization that could cause stale data usage.

Fixed several null pointer exceptions in remote analysis code paths.

Addressed 404 errors on unexpected branch names with clearer error messages.

## [0.1.6] - 2025-11-03

### 🔥 Breaking Changes

#### **Removed Automatic .env Loading**
- **Removed:** Automatic `.env` file loading due to macOS sandbox restrictions
- **Changed:** Users must now explicitly pass `githubToken` parameter
- **Reason:** File system access in sandboxed environments (macOS apps) causes permission errors
- **Migration:** Pass tokens directly via parameters or use environment variables

**Before (v0.1.5 and earlier):**
```dart
// Token automatically loaded from .env file
final result = await analyzeForLLM('https://github.com/user/repo');
```

**After (v0.1.6+):**
```dart
// Token must be passed explicitly
final result = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'ghp_your_token_here',
);

// Or load from environment variables
import 'dart:io';
final token = Platform.environment['GITHUB_TOKEN'];
final result = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: token,
);
```

### 🐛 Critical Fixes

#### **Fixed Cache Respecting `useCache: false` Parameter**
- **Fixed:** Cache was being created even when `useCache: false` was explicitly set
- **Root Cause:** Cache save logic only checked `config.enableCache`, ignoring `useCache` parameter
- **Impact:** Users couldn't force fresh analysis without modifying config

**Technical Details:**
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

**Usage:**
```dart
// Now correctly bypasses cache
final result = await analyzer.analyze(
  'https://github.com/user/repo',
  useCache: false, // ✅ Cache won't be created
);
```

### 🗑️ Removed

- **EnvLoader**: Removed `src/common/env_loader.dart` (no longer exported)
- **Auto .env Loading**: Removed from `GithubAnalyzerConfig.create()`, `.quick()`, `.forLLM()`
- **Service Locator .env**: Removed automatic token loading from DI container

### ✨ Added

- **Explicit Token Passing**: All functions now support direct `githubToken` parameter
- **DartDoc Documentation**: Added comprehensive English documentation to all public APIs
- **Security Guidelines**: Added best practices for token management in README

### 📝 Documentation

- **Updated README**: Reflects new explicit token passing requirement
- **Security Section**: Added examples for environment variables and secure storage
- **Migration Guide**: Clear before/after examples for upgrading from v0.1.5

### 🔧 Configuration Changes

- **`autoLoadEnv` parameter**: Deprecated (kept for backward compatibility, no longer functional)
- **Token Source**: Users must provide tokens via:
  - Direct parameter passing
  - `Platform.environment['GITHUB_TOKEN']`
  - Secure storage (flutter_secure_storage)
  - Build-time environment variables

### 📊 Affected Functions

All convenience functions now require explicit token passing:
- `analyze()`
- `analyzeQuick(githubToken: token)`
- `analyzeForLLM(githubToken: token)`
- `analyzeAndGenerate()`

### ⚠️ Migration Required

**For Public Repositories:**
No changes needed - works without token.

**For Private Repositories:**
```dart
// Option 1: Environment variable
import 'dart:io';
final token = Platform.environment['GITHUB_TOKEN'];

final result = await analyzeForLLM(
  'https://github.com/user/private-repo',
  githubToken: token,
);

// Option 2: Secure storage (Flutter)
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

### 🔥 Critical Fixes

#### **Fixed Private Repository Analysis Failure** 
Private repositories now work seamlessly without requiring explicit token parameters in function calls. The root cause was DI container not detecting token changes between consecutive `analyzeForLLM()` calls.

### ✨ Key Changes

#### 1. **HTTP Client Manager** - HTTP Redirect Support
- Added `followRedirects: true`
- Added `maxRedirects: 5`
- **Why:** GitHub API uses 302 redirects for ZIP downloads. Without this, all downloads failed immediately.

```dart
BaseOptions(
  connectTimeout: requestTimeout,
  receiveTimeout: requestTimeout,
  sendTimeout: requestTimeout,
  followRedirects: true,  // ✅ NEW
  maxRedirects: 5,         // ✅ NEW
)
```

#### 2. **Zip Downloader** - Private Repository Detection
- Added `isPrivate` parameter to `downloadRepositoryAsBytes()`
- Prevents public URL fallback for private repos
- Forces GitHub API usage when repository is private

```dart
Future<Uint8List> downloadRepositoryAsBytes({
  required String owner,
  required String repo,
  required String ref,
  String? token,
  bool isPrivate = false,  // ✅ NEW
})
```

#### 3. **Remote Analyzer Service** - Metadata Propagation
- Now passes `metadata?.isPrivate` to ZipDownloader
- Communicates repository visibility status through call chain

```dart
final isPrivate = metadata?.isPrivate ?? false;
return await zipDownloader.downloadRepositoryAsBytes(
  owner: owner,
  repo: repo,
  ref: ref,
  token: githubToken,
  isPrivate: isPrivate,  // ✅ NEW
);
```

#### 4. **Service Locator** - Token Change Detection (CRITICAL FIX) ⚡
- Detects when GitHub token changes between function calls
- Automatically reinitializes DI container with new token
- **This was THE ROOT CAUSE** of private repository failures

```dart
// ✅ NEW: Detect token changes
if (config != null && getIt.isRegistered<GithubAnalyzerConfig>()) {
  final existingConfig = getIt<GithubAnalyzerConfig>();
  
  // Reinitialize only if token changed
  if (existingConfig.githubToken != config.githubToken) {
    await getIt.reset();
  } else {
    return; // Token same, skip reinitialization
  }
}
```

### 🎯 Results

**Before:** Private repositories returned 404 even with valid token  
**After:** All repository types work automatically

| Repository Type | Status | Auto-Token | Files |
|-----------------|--------|-----------|-------|
| Public | ✅ | Yes | 249+ |
| Public (with token) | ✅ | Yes | 49+ |
| Private (with token) | ✅ | Yes | 121+ |

### ✅ User Experience

No code changes needed. Simply create `.env` file:

```env
GITHUB_TOKEN=your_token_here
```

Then use normally:

```dart
await analyzeForLLM(
  'https://github.com/private/repo.git',
  outputDir: './output',
);
// ✅ Token auto-loaded from .env, private repo analyzed successfully!
```

### 🔧 Technical Details

- HTTP redirects now automatically followed (eliminates 302 errors)
- Private repositories detected via GitHub API metadata
- DI container intelligently reinitializes on token changes
- Token detection prevents unnecessary container resets
- Backward compatible - all existing code continues working

### 📊 Testing

All scenarios now pass:
- ✅ Public repos without token
- ✅ Public repos with token  
- ✅ Private repos with token (auto-loaded)
- ✅ Multiple consecutive analyses with mixed repository types

---

## [0.1.4] - 2025-11-03

### Fixed

- **Fixed EnvLoader project root detection**: `EnvLoader` now automatically searches for `.env` file in the project root instead of only the current working directory
  - Added `_findEnvFile()` method that traverses up to 10 parent directories to locate `.env`
  - Validates project root by checking for `pubspec.yaml` or `.git` to prevent loading `.env` from unrelated parent directories
  - Resolves issue where Flutter apps and other platforms failed to load `.env` because the working directory differed from the project root
  - Improved logging to show the full path of loaded `.env` file for better debugging

### Changed

- Enhanced `EnvLoader.load()` to use the new project root detection logic
- Updated log message to display: `.env file loaded successfully from: {path}` instead of just `.env file loaded successfully`
- Made `EnvLoader` more robust for multi-platform deployments (macOS, iOS, Android, web)

### Impact

Users no longer need to manually pass GitHub tokens via environment variables. The package will now automatically find and load the `.env` file from the project root, even when running Flutter apps that execute from different working directories.

**Example:**
```log
Before: 404 error (token not loaded because .env not found)
After: ✅ Private repository analyzed successfully (token auto-loaded from project root)
```

---

## [0.1.3] - 2025-11-03

### 🔥 Critical Fixes

- **Fixed JSON serialization/deserialization bug**: Resolved `type '_RepositoryMetadata' is not a subtype of type 'Map<String, dynamic>'` error in `AnalysisResult.fromJson()` by implementing custom serialization logic for nested Freezed models

- **Fixed `toJson()` method**: Added manual implementation to properly serialize nested objects (`RepositoryMetadata`, `SourceFile`, `AnalysisStatistics`, `AnalysisError`)

### ✨ Improvements

- **Enhanced demo coverage**: Added 3 new comprehensive tests (Convenience Functions, Markdown Generation, Cache Management) bringing total test coverage to 14/14
- **Updated example.dart**: Migrated to v0.1.2 API including new methods (`fetchMetadataOnly()`, `getCacheStatistics()`, `clearCache()`)
- **Improved test reliability**: All 14 tests now pass consistently with 100% success rate

### 🛠️ Technical Details

The serialization issue was caused by `json_serializable` not properly handling nested Freezed models during deserialization. The fix manually implements `fromJson()` and `toJson()` methods to explicitly call the respective methods on nested objects:

```dart
// Before (auto-generated, broken)
factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
_$AnalysisResultFromJson(json);

// After (manual implementation, working)
factory AnalysisResult.fromJson(Map<String, dynamic> json) {
return AnalysisResult(
metadata: RepositoryMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
files: (json['files'] as List<dynamic>)
.map((e) => SourceFile.fromJson(e as Map<String, dynamic>))
.toList(),
statistics: AnalysisStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
// ... other fields
);
}
```

### Added
- **New `fetchMetadataOnly()` method**: Lightweight metadata retrieval (1-3 seconds, API-only, no file download)

  ```dart
  final metadata = await analyzer.fetchMetadataOnly('https://github.com/flutter/flutter');
  ```

- **Configuration validation system**: All config values validated at creation time to prevent runtime errors
  - `maxFileSize` must be > 0
  - `maxConcurrentRequests` range: 1-20
  - `isolatePoolSize` range: 1-16
  - `maxRetries` range: 0-10
  - `retryDelay` max: 60 seconds

- **New configuration options**:
  - `enableFileCache`: File-level caching control (default: true)
  - `autoIsolatePoolThreshold`: Auto-enable parallel processing at N files (default: 100)
  - `streamingModeThreshold`: Archive size threshold for streaming mode (default: 50MB)
  - `shouldUseStreamingMode()`: Dynamic streaming decision method

- **Security: Token masking**: GitHub tokens automatically masked in logs
  - Before: `ghp_reallyLongTokenHere123456789xyz9`
  - After: `ghp_real...xyz9`
  - Added `SensitiveLogger` utility class
  - Tokens no longer exposed in debug logs or `toString()` output

- **Comprehensive demo.dart**: 7 example scenarios covering all features

### Fixed
- Missing config fields: `enableFileCache`, `autoIsolatePoolThreshold`, `streamingModeThreshold`
- Undefined `AnalyzerErrorCode.invalidInput` - replaced with `AnalyzerErrorCode.invalidUrl`
- Improved error handling in `fetchMetadataOnly()` for invalid repository URLs
- Enhanced validation error messages with clear constraints

### Changed
- **BREAKING**: All Freezed models now require `abstract` keyword (Freezed 3.0.0 compatibility)
  ```dart
  // Before
  @freezed
  class AnalysisError with _$AnalysisError { }

  // After
  @freezed
  abstract class AnalysisError with _$AnalysisError { }
  ```

- Enhanced `toString()` output for `GithubAnalyzerConfig` with masked tokens
- `GithubAnalyzer` now includes progress tracking for metadata fetching
- Configuration validation throws descriptive `ArgumentError` for invalid values

### Migration Required

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Breaking Changes
1. **Freezed models**: All model classes require `abstract` or `sealed` keyword
2. **Configuration validation**: Invalid config values now throw `ArgumentError` at creation time
3. **Regenerate files**: All `.freezed.dart` and `.g.dart` files must be regenerated

### Performance Improvements
- Metadata-only fetching reduces API calls and response time (10-60s → 1-3s)
- Auto-enable isolate pool based on file count threshold
- Streaming mode for archives over 50MB reduces memory usage

### Models Updated (Freezed 3.0.0)
- `AnalysisError`
- `AnalysisProgress`
- `AnalysisResult`
- `AnalysisStatistics`
- `RepositoryMetadata`
- `SourceFile`

All models now provide:
- Automatic `copyWith()`
- Automatic `toJson()` / `fromJson()`
- Automatic `==` and `hashCode`
- Immutability by default
- 68% less boilerplate code

---

## [0.0.8] - 2025-10-29

### Added
- **Explicit cache control parameter**: Added `useCache` parameter to all analysis functions
  - `analyze()` function now accepts `useCache` parameter
  - `analyzeQuick()` function now accepts `useCache` parameter  
  - `analyzeForLLM()` function now accepts `useCache` parameter
  - `analyzeAndGenerate()` function now accepts `useCache` parameter
  - `GithubAnalyzer.analyze()` method now accepts `useCache` parameter
  - `GithubAnalyzer.analyzeRemote()` method now accepts `useCache` parameter

### Changed
- Cache behavior can now be explicitly controlled at the function call level
- When `useCache` is not specified, the default value from `GithubAnalyzerConfig.enableCache` is used
- When `useCache` is explicitly set to `false`, cache is bypassed regardless of config settings

### Usage Example
```dart
// Disable cache for a specific analysis
final result = await analyzeQuick(
'https://github.com/flutter/flutter',
useCache: false, // Always fetch fresh data
);

// Or with advanced API
final analyzer = await GithubAnalyzer.create();
final result = await analyzer.analyzeRemote(
repositoryUrl: 'https://github.com/your/repo',
useCache: false,
);
```

### Benefits
- Users can now force fresh data fetching when needed
- Useful for CI/CD pipelines that require latest repository state
- Provides flexibility without requiring config changes

---

## [0.0.7] - 2025-10-19

### Fixed
- Fixed Critical Caching Logic: Resolved a major bug where analyzing a repository immediately after a new push could return stale data from the previous commit.

- The analyzer now explicitly fetches the latest commit SHA for the target branch before checking the cache or downloading.

- This exact commitSha is now used consistently as both the cache key and the download reference, eliminating race conditions and cache pollution caused by GitHub API replication delays.

- Improved Authentication Compatibility: Standardized all GitHub API requests to use the Authorization: Bearer $token header. This ensures compatibility with both classic Personal Access Tokens (PATs) and new fine-grained PATs.

- Fixed HTTP Retry Bug: Corrected a bug in the HttpClientManager's retry logic that was using an incorrect URI path for retrying timed-out requests, improving overall network resilience.

---

## [0.0.6] - 2025-10-15

### Added
- **Automatic `.env` file loading**: GitHub tokens are now automatically loaded from `.env` files
- **EnvLoader utility**: New `EnvLoader` class for seamless environment variable management
- **Private repository support**: Enhanced ZIP downloader with GitHub API fallback for private repositories
- **Async configuration factories**: All `GithubAnalyzerConfig` factory methods now support async `.env` loading
- **GithubAnalyzer.create()**: New factory method with automatic dependency injection and `.env` loading

### Changed
- **Breaking**: `GithubAnalyzerConfig.quick()` and `GithubAnalyzerConfig.forLLM()` are now async
- **Breaking**: Removed synchronous config factories in favor of async versions
- **Improved**: ZIP downloader now tries GitHub API first for private repos, then falls back to public URL
- **Enhanced**: Token authentication now works seamlessly with Fine-grained Personal Access Tokens

### Fixed
- Fixed private repository access with Fine-grained GitHub tokens
- Fixed 403 errors when accessing private repositories
- Fixed token not being passed correctly to ZIP download endpoints
- Improved error messages for repository access issues

### Documentation
- Added comprehensive Fine-grained Token setup guide
- Updated README with `.env` file usage examples
- Added troubleshooting section for private repository access

---

## [0.0.5] - 2025-10-14

### Added
- Web platform support with conditional compilation
- `universal_io` package integration for cross-platform compatibility
- Comprehensive file system abstraction layer

### Changed
- Migrated from `dart:io` to `universal_io` for web compatibility
- Improved error handling for platform-specific features

### Fixed
- Web platform compilation errors
- File system access issues on web

---

## [0.0.4] - 2025-10-13

### Added
- Incremental analysis support
- Enhanced caching mechanism
- Performance optimizations

### Changed
- Improved analysis speed for large repositories

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


# 변경 로그

이 프로젝트의 모든 주목할 만한 변경사항은 이 파일에 문서화됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)를 기반으로 하며,
이 프로젝트는 [의미있는 버전 관리](https://semver.org/spec/v2.0.0.html)를 따릅니다.

## [0.1.6] - 2025-11-03

### 🔥 주요 변경사항 (Breaking Changes)

#### **자동 .env 로드 제거**
- **제거됨:** macOS 샌드박스 제한으로 인한 자동 `.env` 파일 로드 제거
- **변경:** 사용자는 이제 `githubToken` 파라미터를 명시적으로 전달해야 함
- **사유:** 샌드박스 환경(macOS 앱)에서 파일 시스템 접근으로 인한 권한 오류
- **마이그레이션:** 파라미터로 토큰을 직접 전달하거나 환경 변수 사용

**이전 (v0.1.5 이전):**
```dart
// .env 파일에서 토큰 자동 로드
final result = await analyzeForLLM('https://github.com/user/repo');
```

**이후 (v0.1.6+):**
```dart
// 토큰을 명시적으로 전달해야 함
final result = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: 'ghp_your_token_here',
);

// 또는 환경 변수에서 로드
import 'dart:io';
final token = Platform.environment['GITHUB_TOKEN'];
final result = await analyzeForLLM(
  'https://github.com/user/repo',
  githubToken: token,
);
```

### 🐛 치명적 버그 수정

#### **useCache: false 파라미터 존중 수정**
- **수정됨:** `useCache: false`를 명시적으로 설정했을 때도 캐시가 생성되던 문제
- **근본 원인:** 캐시 저장 로직이 `config.enableCache`만 확인하고 `useCache` 파라미터 무시
- **영향:** 사용자가 설정 수정 없이 강제로 새 분석을 실행할 수 없음

**기술 세부사항:**
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

**사용법:**
```dart
// 이제 올바르게 캐시가 생성되지 않음
final result = await analyzer.analyze(
  'https://github.com/user/repo',
  useCache: false, // ✅ 캐시가 생성되지 않음
);
```

### 🗑️ 제거됨

- **EnvLoader**: `src/common/env_loader.dart` 제거 (더 이상 내보내지 않음)
- **자동 .env 로드**: `GithubAnalyzerConfig.create()`, `.quick()`, `.forLLM()`에서 제거
- **Service Locator .env**: DI 컨테이너의 자동 토큰 로드 제거

### ✨ 추가됨

- **명시적 토큰 전달**: 모든 함수가 이제 직접 `githubToken` 파라미터 지원
- **DartDoc 문서화**: 모든 공개 API에 포괄적인 영어 문서 추가
- **보안 가이드라인**: README에 토큰 관리 모범 사례 추가

### 📝 문서화

- **README 업데이트**: 새로운 명시적 토큰 전달 요구사항 반영
- **보안 섹션**: 환경 변수 및 보안 저장소 사용 예제 추가
- **마이그레이션 가이드**: v0.1.5에서 업그레이드하기 위한 명확한 이전/이후 예제

### 🔧 설정 변경사항

- **`autoLoadEnv` 파라미터**: 더 이상 사용되지 않음 (하위 호환성을 위해 유지되지만 기능 없음)
- **토큰 소스**: 사용자는 다음을 통해 토큰 제공해야 함:
  - 직접 파라미터 전달
  - `Platform.environment['GITHUB_TOKEN']`
  - 보안 저장소 (flutter_secure_storage)
  - 빌드 타임 환경 변수

### 📊 영향을 받는 함수

모든 편의 함수는 이제 명시적 토큰 전달 필요:
- `analyze()`
- `analyzeQuick(githubToken: token)`
- `analyzeForLLM(githubToken: token)`
- `analyzeAndGenerate()`

### ⚠️ 마이그레이션 필수

**공개 저장소의 경우:**
변경 사항 없음 - 토큰 없이 작동합니다.

**비공개 저장소의 경우:**
```dart
// 옵션 1: 환경 변수
import 'dart:io';
final token = Platform.environment['GITHUB_TOKEN'];

final result = await analyzeForLLM(
  'https://github.com/user/private-repo',
  githubToken: token,
);

// 옵션 2: 보안 저장소 (Flutter)
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

### 🔥 치명적 버그 수정

#### **비공개 저장소 분석 실패 수정** 
비공개 저장소가 이제 함수 호출 간 `analyzeForLLM()` 연속 호출 시 DI 컨테이너가 토큰 변경을 감지하지 못하는 근본 원인을 해결하여 명시적 토큰 파라미터 없이 원활하게 작동합니다.

### ✨ 주요 변경사항

#### 1. **HTTP 클라이언트 관리자** - HTTP 리다이렉트 지원
- `followRedirects: true` 추가
- `maxRedirects: 5` 추가
- **이유:** GitHub API는 ZIP 다운로드에 302 리다이렉트 사용. 없으면 모든 다운로드 즉시 실패.

```dart
BaseOptions(
  connectTimeout: requestTimeout,
  receiveTimeout: requestTimeout,
  sendTimeout: requestTimeout,
  followRedirects: true,  // ✅ 신규
  maxRedirects: 5,         // ✅ 신규
)
```

#### 2. **Zip 다운로더** - 비공개 저장소 감지
- `downloadRepositoryAsBytes()`에 `isPrivate` 파라미터 추가
- 비공개 저장소에 대한 공개 URL 폴백 방지
- 저장소가 비공개일 때 GitHub API 사용 강제

```dart
Future<Uint8List> downloadRepositoryAsBytes({
  required String owner,
  required String repo,
  required String ref,
  String? token,
  bool isPrivate = false,  // ✅ 신규
})
```

#### 3. **원격 분석기 서비스** - 메타데이터 전파
- 이제 ZipDownloader에 `metadata?.isPrivate` 전달
- 호출 체인을 통해 저장소 가시성 상태 통신

```dart
final isPrivate = metadata?.isPrivate ?? false;
return await zipDownloader.downloadRepositoryAsBytes(
  owner: owner,
  repo: repo,
  ref: ref,
  token: githubToken,
  isPrivate: isPrivate,  // ✅ 신규
);
```

#### 4. **Service Locator** - 토큰 변경 감지 (치명적 버그 수정) ⚡
- 함수 호출 간 GitHub 토큰 변경 감지
- 새 토큰으로 DI 컨테이너 자동 재초기화
- **이것이 비공개 저장소 실패의 근본 원인**

```dart
// ✅ 신규: 토큰 변경 감지
if (config != null && getIt.isRegistered<GithubAnalyzerConfig>()) {
  final existingConfig = getIt<GithubAnalyzerConfig>();
  
  // 토큰이 변경된 경우에만 재초기화
  if (existingConfig.githubToken != config.githubToken) {
    await getIt.reset();
  } else {
    return; // 토큰 동일, 재초기화 스킵
  }
}
```

### 🎯 결과

**이전:** 유효한 토큰에도 불구하고 비공개 저장소가 404 반환  
**이후:** 모든 저장소 유형이 자동으로 작동

| 저장소 유형 | 상태 | 자동 토큰 | 파일 |
|-----------|------|---------|------|
| 공개 | ✅ | 예 | 249+ |
| 공개 (토큰 포함) | ✅ | 예 | 49+ |
| 비공개 (토큰 포함) | ✅ | 예 | 121+ |

### ✅ 사용자 경험

코드 변경 필요 없음. 간단히 `.env` 파일 생성:

```env
GITHUB_TOKEN=your_token_here
```

그 다음 정상적으로 사용:

```dart
await analyzeForLLM(
  'https://github.com/private/repo.git',
  outputDir: './output',
);
// ✅ .env에서 토큰 자동 로드, 비공개 저장소 성공적으로 분석!
```

### 🔧 기술 세부사항

- HTTP 리다이렉트 이제 자동 팔로우 (302 오류 제거)
- GitHub API 메타데이터를 통해 비공개 저장소 감지
- DI 컨테이너가 토큰 변경 시 지능적으로 재초기화
- 토큰 감지로 불필요한 컨테이너 재설정 방지
- 하위 호환성 유지 - 기존 코드 계속 작동

### 📊 테스팅

모든 시나리오 이제 통과:
- ✅ 토큰 없는 공개 저장소
- ✅ 토큰 있는 공개 저장소
- ✅ 토큰 있는 비공개 저장소 (자동 로드)
- ✅ 혼합 저장소 유형의 다중 연속 분석

---

## [0.1.4] - 2025-11-03

### 수정됨

- **EnvLoader 프로젝트 루트 감지 수정**: `EnvLoader`는 이제 현재 작업 디렉토리만 확인하는 대신 프로젝트 루트에서 `.env` 파일을 자동 검색합니다
  - `.env`를 찾기 위해 최대 10개 부모 디렉토리까지 트래버스하는 `_findEnvFile()` 메서드 추가
  - `pubspec.yaml` 또는 `.git` 확인으로 프로젝트 루트 검증하여 무관한 부모 디렉토리의 `.env` 로드 방지
  - Flutter 앱 및 기타 플랫폼이 작업 디렉토리가 프로젝트 루트와 다를 때 `.env` 로드 실패하는 문제 해결
  - 더 나은 디버깅을 위해 로드된 `.env` 파일의 전체 경로를 표시하는 로그 개선

### 변경됨

- `.env` 로드 로직을 새로운 프로젝트 루트 감지 방식 사용하도록 강화
- 로그 메시지를 다음으로 업데이트: `.env file loaded successfully from: {path}` (기존 `.env file loaded successfully` 대체)
- 멀티 플랫폼 배포(macOS, iOS, Android, 웹)에 대해 `EnvLoader` 더 강화

### 영향

사용자는 더 이상 환경 변수를 통해 GitHub 토큰을 수동으로 전달할 필요가 없습니다. 작업 디렉토리가 프로젝트 루트와 다른 경우에도 패키지가 프로젝트 루트에서 `.env` 파일을 자동으로 찾고 로드합니다. 예를 들어 Flutter 앱 실행 시.

**예제:**
```log
이전: 404 오류 (.env를 찾지 못해 토큰 로드 안 됨)
이후: ✅ 비공개 저장소 성공적으로 분석 (프로젝트 루트에서 토큰 자동 로드)
```

---

## [0.1.3] - 2025-11-03

### 🔥 치명적 버그 수정

- **JSON 직렬화/역직렬화 버그 수정**: `AnalysisResult.fromJson()`에서 중첩된 Freezed 모델에 대한 사용자 정의 직렬화 로직을 구현하여 `type '_RepositoryMetadata' is not a subtype of type 'Map<String, dynamic>'` 오류 해결

- **`toJson()` 메서드 수정**: 중첩된 객체(`RepositoryMetadata`, `SourceFile`, `AnalysisStatistics`, `AnalysisError`)를 올바르게 직렬화하기 위한 수동 구현 추가

### ✨ 개선사항

- **데모 커버리지 강화**: 3개의 새로운 종합 테스트 추가(편의 함수, 마크다운 생성, 캐시 관리)하여 총 테스트 커버리지를 14/14로 향상
- **example.dart 업데이트**: v0.1.2 API로 마이그레이션 완료, 새로운 메서드 포함(`fetchMetadataOnly()`, `getCacheStatistics()`, `clearCache()`)
- **테스트 신뢰성 개선**: 모든 14개 테스트 이제 100% 성공률로 일관되게 통과

### 🛠️ 기술 세부사항

직렬화 문제는 `json_serializable`이 역직렬화 중 중첩된 Freezed 모델을 올바르게 처리하지 않아 발생했습니다. 수정사항은 중첩된 객체에서 각각의 메서드를 명시적으로 호출하기 위해 `fromJson()` 및 `toJson()` 메서드를 수동 구현합니다:

```dart
// 이전 (자동 생성, 손상됨)
factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
_$AnalysisResultFromJson(json);

// 이후 (수동 구현, 작동함)
factory AnalysisResult.fromJson(Map<String, dynamic> json) {
return AnalysisResult(
metadata: RepositoryMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
files: (json['files'] as List<dynamic>)
.map((e) => SourceFile.fromJson(e as Map<String, dynamic>))
.toList(),
statistics: AnalysisStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
// ... 기타 필드
);
}
```

### 추가됨
- **새로운 `fetchMetadataOnly()` 메서드**: 가벼운 메타데이터 조회 (1-3초, API만, 파일 다운로드 없음)

  ```dart
  final metadata = await analyzer.fetchMetadataOnly('https://github.com/flutter/flutter');
  ```

- **설정 검증 시스템**: 모든 설정값을 생성 시점에 검증하여 런타임 오류 방지
  - `maxFileSize` > 0 이어야 함
  - `maxConcurrentRequests` 범위: 1-20
  - `isolatePoolSize` 범위: 1-16
  - `maxRetries` 범위: 0-10
  - `retryDelay` 최대: 60초

- **새로운 설정 옵션**:
  - `enableFileCache`: 파일 수준 캐싱 제어 (기본값: true)
  - `autoIsolatePoolThreshold`: N개 파일에서 병렬 처리 자동 활성화 (기본값: 100)
  - `streamingModeThreshold`: 스트리밍 모드 아카이브 크기 임계값 (기본값: 50MB)
  - `shouldUseStreamingMode()`: 동적 스트리밍 결정 메서드

- **보안: 토큰 마스킹**: GitHub 토큰이 로그에서 자동으로 마스킹됨
  - 이전: `ghp_reallyLongTokenHere123456789xyz9`
  - 이후: `ghp_real...xyz9`
  - `SensitiveLogger` 유틸리티 클래스 추가
  - 토큰이 더 이상 디버그 로그나 `toString()` 출력에 노출되지 않음

- **종합 demo.dart**: 모든 기능을 다루는 7가지 예제 시나리오

### 수정됨
- 누락된 설정 필드: `enableFileCache`, `autoIsolatePoolThreshold`, `streamingModeThreshold`
- 정의되지 않은 `AnalyzerErrorCode.invalidInput` - `AnalyzerErrorCode.invalidUrl`로 교체
- 유효하지 않은 저장소 URL에 대해 `fetchMetadataOnly()`의 오류 처리 개선
- 명확한 제약 조건이 있는 검증 오류 메시지 향상

### 변경됨
- **주요 변경**: 모든 Freezed 모델은 이제 `abstract` 키워드 필요 (Freezed 3.0.0 호환성)
  ```dart
  // 이전
  @freezed
  class AnalysisError with _$AnalysisError { }

  // 이후
  @freezed
  abstract class AnalysisError with _$AnalysisError { }
  ```

- `GithubAnalyzerConfig`의 `toString()` 출력 향상 (마스킹된 토큰 포함)
- `GithubAnalyzer`는 이제 메타데이터 조회에 대한 진행 상황 추적 포함
- 설정 검증이 유효하지 않은 값에 대해 설명적인 `ArgumentError` 던짐

### 마이그레이션 필수

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### 주요 변경사항
1. **Freezed 모델**: 모든 모델 클래스에 `abstract` 또는 `sealed` 키워드 필요
2. **설정 검증**: 유효하지 않은 설정값이 생성 시점에 `ArgumentError` 던짐
3. **파일 재생성**: 모든 `.freezed.dart` 및 `.g.dart` 파일을 재생성해야 함

### 성능 개선
- 메타데이터 전용 조회로 API 호출 및 응답 시간 단축 (10-60s → 1-3s)
- 파일 수 임계값을 기반으로 isolate 풀 자동 활성화
- 50MB 이상 아카이브에 대한 스트리밍 모드로 메모리 사용량 감소

### 업데이트된 모델 (Freezed 3.0.0)
- `AnalysisError`
- `AnalysisProgress`
- `AnalysisResult`
- `AnalysisStatistics`
- `RepositoryMetadata`
- `SourceFile`

모든 모델이 이제 제공하는 기능:
- 자동 `copyWith()`
- 자동 `toJson()` / `fromJson()`
- 자동 `==` 및 `hashCode`
- 기본적으로 불변성
- 68% 보일러플레이트 코드 감소

---

## [0.0.8] - 2025-10-29

### 추가됨
- **명시적 캐시 제어 파라미터**: 모든 분석 함수에 `useCache` 파라미터 추가
  - `analyze()` 함수는 이제 `useCache` 파라미터 허용
  - `analyzeQuick()` 함수는 이제 `useCache` 파라미터 허용
  - `analyzeForLLM()` 함수는 이제 `useCache` 파라미터 허용
  - `analyzeAndGenerate()` 함수는 이제 `useCache` 파라미터 허용
  - `GithubAnalyzer.analyze()` 메서드는 이제 `useCache` 파라미터 허용
  - `GithubAnalyzer.analyzeRemote()` 메서드는 이제 `useCache` 파라미터 허용

### 변경됨
- 함수 호출 레벨에서 캐시 동작을 명시적으로 제어 가능
- `useCache`를 지정하지 않으면 `GithubAnalyzerConfig.enableCache`의 기본값 사용
- `useCache`를 명시적으로 `false`로 설정하면 설정 관계없이 캐시 무시

### 사용 예제
```dart
// 특정 분석에 대해 캐시 비활성화
final result = await analyzeQuick(
'https://github.com/flutter/flutter',
useCache: false, // 항상 최신 데이터 가져오기
);

// 또는 고급 API 사용
final analyzer = await GithubAnalyzer.create();
final result = await analyzer.analyzeRemote(
repositoryUrl: 'https://github.com/your/repo',
useCache: false,
);
```

### 장점
- 사용자는 필요할 때 강제로 최신 데이터 조회 가능
- CI/CD 파이프라인이 최신 저장소 상태 필요할 때 유용
- 설정 변경 없이 유연성 제공

---

## [0.0.7] - 2025-10-19

### 수정됨
- 치명적 캐싱 로직 수정: 새 푸시 직후 저장소를 분석할 때 이전 커밋의 오래된 데이터를 반환할 수 있는 주요 버그 해결

- 분석기는 이제 캐시 확인 또는 다운로드 전에 대상 브랜치의 최신 커밋 SHA를 명시적으로 조회

- 이 정확한 commitSha는 이제 캐시 키 및 다운로드 참조로 일관되게 사용되어 GitHub API 복제 지연으로 인한 레이스 컨디션 및 캐시 오염 제거

- 인증 호환성 개선: 모든 GitHub API 요청을 Authorization: Bearer $token 헤더로 표준화. 클래식 개인 액세스 토큰(PAT) 및 새로운 세분화된 PAT 모두와의 호환성 보장

- HTTP 재시도 버그 수정: HttpClientManager의 재시도 로직에서 시간 초과 요청을 재시도할 때 잘못된 URI 경로를 사용하던 버그 수정, 전반적인 네트워크 복원력 개선

---

## [0.0.6] - 2025-10-15

### 추가됨
- **자동 `.env` 파일 로드**: GitHub 토큰이 이제 `.env` 파일에서 자동으로 로드됨
- **EnvLoader 유틸리티**: 원활한 환경 변수 관리를 위한 새로운 `EnvLoader` 클래스
- **비공개 저장소 지원**: 비공개 저장소를 위한 GitHub API 폴백이 있는 향상된 ZIP 다운로더
- **비동기 설정 팩토리**: 모든 `GithubAnalyzerConfig` 팩토리 메서드가 이제 비동기 `.env` 로드 지원
- **GithubAnalyzer.create()**: 자동 의존성 주입 및 `.env` 로드를 사용한 새로운 팩토리 메서드

### 변경됨
- **주요 변경**: `GithubAnalyzerConfig.quick()` 및 `GithubAnalyzerConfig.forLLM()`은 이제 비동기
- **주요 변경**: 비동기 버전 선택으로 동기 설정 팩토리 제거
- **개선**: ZIP 다운로더는 이제 비공개 저장소를 위해 먼저 GitHub API를 시도한 후 공개 URL로 폴백
- **향상**: 토큰 인증이 이제 세분화된 개인 액세스 토큰과 원활하게 작동

### 수정됨
- 세분화된 GitHub 토큰으로 비공개 저장소 접근 수정
- 비공개 저장소 접근 시 403 오류 수정
- ZIP 다운로드 엔드포인트에 토큰이 올바르게 전달되지 않는 문제 수정
- 저장소 접근 문제에 대한 오류 메시지 개선

### 문서화
- 종합적인 세분화된 토큰 설정 가이드 추가
- `.env` 파일 사용 예제로 README 업데이트
- 비공개 저장소 접근에 대한 문제 해결 섹션 추가

---

## [0.0.5] - 2025-10-14

### 추가됨
- 조건부 컴파일을 포함한 웹 플랫폼 지원
- 크로스 플랫폼 호환성을 위한 `universal_io` 패키지 통합
- 종합적인 파일 시스템 추상화 계층

### 변경됨
- 웹 호환성을 위해 `dart:io`에서 `universal_io`로 마이그레이션
- 플랫폼 특화 기능에 대한 오류 처리 개선

### 수정됨
- 웹 플랫폼 컴파일 오류
- 웹의 파일 시스템 접근 문제

---

## [0.0.4] - 2025-10-13

### 추가됨
- 증분 분석 지원
- 강화된 캐싱 메커니즘
- 성능 최적화

### 변경됨
- 대규모 저장소에 대한 분석 속도 개선

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
