# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
