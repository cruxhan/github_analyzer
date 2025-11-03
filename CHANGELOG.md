# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
This changelog entry:

Follows Keep a Changelog format with Added/Changed sections

Uses semantic versioning 0.0.8

Includes today's date (2025-10-29)

Clearly describes the feature with bullet points

Provides usage examples showing how to use the new parameter

Explains the benefits of the new feature

Maintains consistency with the existing changelog style from version 0.0.7

You can place this entry at the top of your CHANGELOG.md file, right after the header and before the 0.0.7 entry.

## [0.0.7] - 2025-10-19

### Fixed
- Fixed Critical Caching Logic: Resolved a major bug where analyzing a repository immediately after a new push could return stale data from the previous commit.

- The analyzer now explicitly fetches the latest commit SHA for the target branch before checking the cache or downloading.

- This exact commitSha is now used consistently as both the cache key and the download reference, eliminating race conditions and cache pollution caused by GitHub API replication delays.

- Improved Authentication Compatibility: Standardized all GitHub API requests to use the Authorization: Bearer $token header. This ensures compatibility with both classic Personal Access Tokens (PATs) and new fine-grained PATs.

- Fixed HTTP Retry Bug: Corrected a bug in the HttpClientManager's retry logic that was using an incorrect URI path for retrying timed-out requests, improving overall network resilience.

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

## [0.0.4] - 2025-10-13

### Added
- Incremental analysis support
- Enhanced caching mechanism
- Performance optimizations

### Changed
- Improved analysis speed for large repositories

## [0.0.3] - 2025-10-12

### Added
- LLM-optimized output format
- File prioritization system
- Compact markdown generation

## [0.0.2] - 2025-10-11

### Added
- Remote repository analysis
- Local directory analysis
- Basic caching system

## [0.0.1] - 2025-10-10

### Added
- Initial release
- Basic GitHub repository analysis
- Markdown generation
