import 'dart:async';

import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/local_analyzer_service.dart';
import 'package:github_analyzer/src/core/remote_analyzer_service.dart';
import 'package:github_analyzer/src/data/providers/github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/infrastructure/http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/isolate_pool.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';

/// Main analyzer class that orchestrates the repository analysis process.
///
/// [GithubAnalyzer] is the central component for analyzing both local and remote
/// repositories. It manages all dependencies, coordinates analysis services,
/// and provides progress tracking capabilities.
///
/// ## Features
///
/// * Analyzes local directories and remote GitHub repositories
/// * Supports both public and private repositories (with token)
/// * Real-time progress tracking via streams
/// * Optional result caching for performance
/// * Automatic resource management and cleanup
///
/// ## Usage
///
/// ```
/// // Create analyzer with default configuration
/// final analyzer = await GithubAnalyzer.create();
///
/// // Analyze a repository
/// final result = await analyzer.analyze('https://github.com/flutter/flutter');
///
/// // Clean up resources
/// await analyzer.dispose();
/// ```
///
/// See also:
/// * [GithubAnalyzerConfig] for configuration options
/// * [AnalysisResult] for the structure of analysis output
/// * [AnalysisProgress] for progress tracking details
class GithubAnalyzer {
  /// Configuration settings for the analyzer
  final GithubAnalyzerConfig config;

  /// HTTP client manager for network requests
  final IHttpClientManager httpClientManager;

  /// GitHub API provider for metadata and repository information
  final IGithubApiProvider apiProvider;

  /// ZIP downloader for fetching repository archives
  final ZipDownloader zipDownloader;

  /// Service for analyzing local directories
  final LocalAnalyzerService localAnalyzer;

  /// Service for analyzing remote GitHub repositories
  final RemoteAnalyzerService remoteAnalyzer;

  /// Optional cache service for storing analysis results
  final CacheService? cacheService;

  /// Optional isolate pool for parallel processing
  final IsolatePool? isolatePool;

  /// Progress event stream controller
  final StreamController<AnalysisProgress> _progressController =
      StreamController.broadcast();

  /// Stream of analysis progress updates.
  ///
  /// Subscribe to this stream to receive real-time progress notifications
  /// during analysis operations. Progress events include:
  /// * Current analysis phase (initializing, downloading, analyzing, etc.)
  /// * Completion percentage (0.0 to 1.0)
  /// * Status messages
  /// * Timestamps
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// analyzer.progressStream.listen((progress) {
  ///   print('Phase: ${progress.phase}');
  ///   print('Progress: ${(progress.progress * 100).toInt()}%');
  ///   print('Message: ${progress.message}');
  /// });
  ///
  /// await analyzer.analyze('https://github.com/dart-lang/sdk');
  /// ```
  Stream<AnalysisProgress> get progressStream => _progressController.stream;

  /// Creates an instance of [GithubAnalyzer].
  ///
  /// This constructor is typically not called directly. Use [create] factory
  /// method instead for automatic dependency setup.
  ///
  /// ## Parameters
  ///
  /// All parameters are required except [cacheService] and [isolatePool]:
  /// * [config] - Analyzer configuration settings
  /// * [httpClientManager] - HTTP client for network operations
  /// * [apiProvider] - GitHub API interface
  /// * [zipDownloader] - Repository archive downloader
  /// * [localAnalyzer] - Service for local directory analysis
  /// * [remoteAnalyzer] - Service for remote repository analysis
  /// * [cacheService] - Optional cache for results (null if caching disabled)
  /// * [isolatePool] - Optional isolate pool for parallel processing
  GithubAnalyzer({
    required this.config,
    required this.httpClientManager,
    required this.apiProvider,
    required this.zipDownloader,
    required this.localAnalyzer,
    required this.remoteAnalyzer,
    this.cacheService,
    this.isolatePool,
  });

  /// Factory method to create a [GithubAnalyzer] with automatic dependency setup.
  ///
  /// This is the recommended way to create a [GithubAnalyzer] instance. It
  /// automatically initializes all required dependencies including HTTP client,
  /// API provider, cache service, and isolate pool based on configuration.
  ///
  /// ## Parameters
  ///
  /// * [config] - Optional custom configuration. If not provided, creates
  /// default config with standard settings.
  ///
  /// ## Returns
  ///
  /// Fully initialized [GithubAnalyzer] instance ready for use.
  ///
  /// ## Example
  ///
  /// ```
  /// // With default configuration
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// // With custom configuration (provide token explicitly)
  /// final customConfig = await GithubAnalyzerConfig.create(
  ///   githubToken: 'ghp_xxxxx',
  ///   maxTotalFiles: 500,
  ///   enableCache: true,
  /// );
  /// final analyzer = await GithubAnalyzer.create(config: customConfig);
  /// ```
  ///
  /// ## Initialization Process
  ///
  /// 1. Creates HTTP client manager with retry logic
  /// 2. Initializes GitHub API provider with authentication
  /// 3. Sets up ZIP downloader for repository archives
  /// 4. Configures cache service (if enabled)
  /// 5. Initializes isolate pool for parallel processing (if enabled)
  /// 6. Creates analyzer services for local and remote analysis
  static Future<GithubAnalyzer> create({GithubAnalyzerConfig? config}) async {
    final effectiveConfig = config ?? await GithubAnalyzerConfig.create();

    // Create HTTP client manager with configured timeouts and retry logic
    final httpClientManager = HttpClientManager(
      requestTimeout: const Duration(seconds: 30),
      maxConcurrentRequests: effectiveConfig.maxConcurrentRequests,
      maxRetries: effectiveConfig.maxRetries,
    );

    // Create API provider with GitHub authentication
    final apiProvider = GithubApiProvider(
      httpClientManager: httpClientManager,
      token: effectiveConfig.githubToken,
    );

    // Create ZIP downloader for fetching repository archives
    final zipDownloader = ZipDownloader(httpClientManager: httpClientManager);

    // Create cache service if caching is enabled
    CacheService? cacheService;
    if (effectiveConfig.enableCache) {
      cacheService = CacheService(
        cacheDirectory: effectiveConfig.cacheDirectory,
        maxAge: effectiveConfig.cacheDuration,
      );
    }

    // Create isolate pool for parallel processing if enabled
    IsolatePool? isolatePool;
    if (effectiveConfig.enableIsolatePool) {
      isolatePool = IsolatePool(size: effectiveConfig.isolatePoolSize);
      await isolatePool.initialize();
    }

    // Create repository analyzer with optional isolate pool
    final repositoryAnalyzer = RepositoryAnalyzer(
      config: effectiveConfig,
      isolatePool: isolatePool,
    );

    // Create local analyzer service for directory analysis
    final localAnalyzer = LocalAnalyzerService(
      config: effectiveConfig,
      repositoryAnalyzer: repositoryAnalyzer,
    );

    // Create remote analyzer service for GitHub repositories
    final remoteAnalyzer = RemoteAnalyzerService(
      config: effectiveConfig,
      apiProvider: apiProvider,
      zipDownloader: zipDownloader,
      cacheService: cacheService,
    );

    return GithubAnalyzer(
      config: effectiveConfig,
      httpClientManager: httpClientManager,
      apiProvider: apiProvider,
      zipDownloader: zipDownloader,
      localAnalyzer: localAnalyzer,
      remoteAnalyzer: remoteAnalyzer,
      cacheService: cacheService,
      isolatePool: isolatePool,
    );
  }

  /// Analyzes a local directory.
  ///
  /// Scans a local file system directory and analyzes all source code files
  /// within it. This method does not require network access or GitHub token.
  ///
  /// ## Parameters
  ///
  /// * [directoryPath] - Absolute or relative path to the directory to analyze
  ///
  /// ## Returns
  ///
  /// [AnalysisResult] containing:
  /// * List of analyzed source files with content
  /// * Code statistics (LOC, file types, etc.)
  /// * Identified main files and dependencies
  /// * Directory structure
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// // Analyze current directory
  /// final result = await analyzer.analyzeLocal('.');
  ///
  /// // Analyze specific project
  /// final result = await analyzer.analyzeLocal('/path/to/project');
  ///
  /// print('Files analyzed: ${result.statistics.totalFiles}');
  /// print('Total lines: ${result.statistics.totalLines}');
  /// ```
  ///
  /// ## Progress Tracking
  ///
  /// Emits progress updates via [progressStream] during analysis.
  ///
  /// ## Throws
  ///
  /// * [AnalyzerException] if the directory doesn't exist or cannot be read
  Future<AnalysisResult> analyzeLocal(String directoryPath) async {
    logger.info('Starting local analysis: $directoryPath');

    _progressController.add(
      AnalysisProgress(
        phase: AnalysisPhase.initializing,
        progress: 0.0,
        message: 'Starting local analysis',
        timestamp: DateTime.now(),
      ),
    );

    final result = await localAnalyzer.analyze(directoryPath);

    _progressController.add(
      AnalysisProgress(
        phase: AnalysisPhase.completed,
        progress: 1.0,
        message: 'Local analysis completed',
        timestamp: DateTime.now(),
      ),
    );

    return result;
  }

  /// Analyzes a remote GitHub repository from URL.
  ///
  /// Downloads and analyzes a repository hosted on GitHub. Supports both
  /// public and private repositories (private requires valid GitHub token).
  ///
  /// ## Parameters
  ///
  /// * [repositoryUrl] - Full GitHub repository URL
  /// (e.g., 'https://github.com/owner/repo' or 'https://github.com/owner/repo.git')
  /// * [branch] - Optional specific branch to analyze. If not provided,
  /// uses the repository's default branch (usually 'main' or 'master')
  /// * [useCache] - Whether to use cached results if available. If null,
  /// uses the value from config (default: true)
  ///
  /// ## Returns
  ///
  /// [AnalysisResult] with comprehensive repository analysis including:
  /// * Repository metadata (stars, forks, language, description)
  /// * All source files with content
  /// * Code statistics and metrics
  /// * Dependency information
  /// * Commit SHA of analyzed version
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// // Analyze default branch
  /// final result = await analyzer.analyzeRemote(
  ///   repositoryUrl: 'https://github.com/flutter/flutter',
  /// );
  ///
  /// // Analyze specific branch
  /// final result = await analyzer.analyzeRemote(
  ///   repositoryUrl: 'https://github.com/dart-lang/sdk',
  ///   branch: 'stable',
  /// );
  ///
  /// // Force fresh analysis (ignore cache)
  /// final result = await analyzer.analyzeRemote(
  ///   repositoryUrl: 'https://github.com/flutter/samples',
  ///   useCache: false,
  /// );
  /// ```
  ///
  /// ## Private Repositories
  ///
  /// For private repositories, provide your GitHub token in config:
  /// ```
  /// final config = await GithubAnalyzerConfig.create(
  ///   githubToken: 'ghp_xxxxx',
  /// );
  /// final analyzer = await GithubAnalyzer.create(config: config);
  /// ```
  ///
  /// ## Caching
  ///
  /// Analysis results are cached by commit SHA. Subsequent analyses of the
  /// same commit return cached results instantly without re-downloading or
  /// re-processing.
  ///
  /// ## Progress Tracking
  ///
  /// Subscribe to [progressStream] to receive updates during:
  /// * Metadata fetching
  /// * Repository download
  /// * Archive extraction
  /// * File analysis
  ///
  /// ## Throws
  ///
  /// * [AnalyzerException] if the URL is invalid, repository not found,
  /// access denied, or network error occurs
  Future<AnalysisResult> analyzeRemote({
    required String repositoryUrl,
    String? branch,
    bool? useCache,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');

    // Pass progress controller to remote analyzer service for tracking
    final remoteServiceWithProgress = remoteAnalyzer.copyWith(
      progressController: _progressController,
    );

    // Use config's enableCache if useCache is not explicitly provided
    final effectiveUseCache = useCache ?? config.enableCache;

    final result = await remoteServiceWithProgress.analyze(
      repositoryUrl: repositoryUrl,
      branch: branch,
      useCache: effectiveUseCache,
    );

    return result;
  }

  /// Analyzes a target automatically detecting type (local path or remote URL).
  ///
  /// This convenience method automatically determines whether the target is a
  /// local directory path or a remote GitHub URL, then calls the appropriate
  /// analysis method.
  ///
  /// ## Parameters
  ///
  /// * [target] - Either:
  ///   * Local directory path (relative or absolute)
  ///   * GitHub repository URL (https:// or git://)
  /// * [branch] - Optional branch name (only for remote repositories)
  /// * [useCache] - Whether to use cache (only for remote repositories)
  ///
  /// ## Returns
  ///
  /// [AnalysisResult] from either local or remote analysis.
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// // Auto-detect and analyze remote repository
  /// final result1 = await analyzer.analyze(
  ///   'https://github.com/flutter/flutter',
  /// );
  ///
  /// // Auto-detect and analyze local directory
  /// final result2 = await analyzer.analyze('./my-project');
  ///
  /// // Works with .git suffix
  /// final result3 = await analyzer.analyze(
  ///   'https://github.com/dart-lang/sdk.git',
  /// );
  /// ```
  ///
  /// ## Detection Logic
  ///
  /// URLs starting with 'http' or 'git' are treated as remote repositories.
  /// Everything else is treated as local paths.
  ///
  /// ## Throws
  ///
  /// * [AnalyzerException] on analysis errors (see [analyzeLocal] and [analyzeRemote])
  Future<AnalysisResult> analyze(
    String target, {
    String? branch,
    bool? useCache,
  }) async {
    // Auto-detect between URL and local path
    if (target.startsWith('http') || target.startsWith('git')) {
      return await analyzeRemote(
        repositoryUrl: target,
        branch: branch,
        useCache: useCache,
      );
    } else {
      return await analyzeLocal(target);
    }
  }

  /// Fetches only repository metadata without downloading or analyzing files.
  ///
  /// This is a lightweight operation that queries only the GitHub API for
  /// basic repository information such as name, description, stars, language,
  /// etc. No files are downloaded, making this much faster than full analysis.
  ///
  /// Useful when you need quick repository information without full analysis.
  ///
  /// ## Parameters
  ///
  /// * [repositoryUrl] - GitHub repository URL
  /// * [branch] - Optional specific branch. If provided, also fetches the
  /// commit SHA for that branch
  ///
  /// ## Returns
  ///
  /// [RepositoryMetadata] containing:
  /// * Repository name and full name
  /// * Description
  /// * Primary language
  /// * Stars and forks count
  /// * Whether repository is private
  /// * Default branch name
  /// * Commit SHA (if branch specified)
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// // Fetch basic metadata
  /// final metadata = await analyzer.fetchMetadataOnly(
  ///   'https://github.com/flutter/flutter',
  /// );
  ///
  /// print('Name: ${metadata.name}');
  /// print('Stars: ${metadata.stars}');
  /// print('Language: ${metadata.language}');
  /// print('Private: ${metadata.isPrivate}');
  ///
  /// // Fetch metadata with specific branch info
  /// final metadata = await analyzer.fetchMetadataOnly(
  ///   'https://github.com/dart-lang/sdk',
  ///   branch: 'stable',
  /// );
  /// print('Commit SHA: ${metadata.commitSha}');
  /// ```
  ///
  /// ## Requirements
  ///
  /// * Requires valid GitHub token (public repos: optional, private repos: required)
  /// * Network connection to GitHub API
  ///
  /// ## Performance
  ///
  /// This operation typically completes in <1 second for public repositories,
  /// making it ideal for quick repository information lookups.
  ///
  /// ## Progress Tracking
  ///
  /// Emits minimal progress updates via [progressStream]:
  /// * Initializing (0%)
  /// * Querying GitHub API (50%)
  /// * Completed (100%)
  ///
  /// ## Throws
  ///
  /// * [AnalyzerException] if:
  ///   * URL format is invalid
  ///   * Repository not found (404)
  ///   * Access denied (403) - check token permissions
  ///   * Network error or API rate limit exceeded
  Future<RepositoryMetadata> fetchMetadataOnly(
    String repositoryUrl, {
    String? branch,
  }) async {
    logger.info('Fetching metadata only: $repositoryUrl');

    // Emit initial progress
    _progressController.add(
      AnalysisProgress(
        phase: AnalysisPhase.initializing,
        progress: 0.0,
        message: 'Fetching repository metadata',
        timestamp: DateTime.now(),
      ),
    );

    try {
      // Parse repository URL to extract owner and repo name
      final uri = Uri.parse(repositoryUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        throw AnalyzerException(
          'Invalid repository URL format. Expected: https://github.com/owner/repo',
          code: AnalyzerErrorCode.invalidUrl,
          details: 'URL must contain owner and repository name',
        );
      }

      final owner = pathSegments[0];
      final repo = pathSegments[1].replaceAll('.git', '');

      logger.fine('Parsed repository: $owner/$repo');

      // Fetch metadata from GitHub API
      _progressController.add(
        AnalysisProgress(
          phase: AnalysisPhase.downloading,
          progress: 0.5,
          message: 'Querying GitHub API',
          timestamp: DateTime.now(),
        ),
      );

      final metadata = await apiProvider.getRepositoryMetadata(owner, repo);

      // If branch is specified, fetch commit SHA for that branch
      if (branch != null) {
        logger.fine('Fetching commit SHA for branch: $branch');

        final commitSha = await apiProvider.getCommitShaForBranch(
          owner,
          repo,
          branch,
        );

        // Update metadata with commit SHA and branch info
        final updatedMetadata = metadata.copyWith(
          commitSha: commitSha,
          defaultBranch: branch,
        );

        _progressController.add(
          AnalysisProgress(
            phase: AnalysisPhase.completed,
            progress: 1.0,
            message: 'Metadata fetched successfully',
            timestamp: DateTime.now(),
          ),
        );

        logger.info('Metadata fetched successfully: ${updatedMetadata.name}');
        return updatedMetadata;
      }

      _progressController.add(
        AnalysisProgress(
          phase: AnalysisPhase.completed,
          progress: 1.0,
          message: 'Metadata fetched successfully',
          timestamp: DateTime.now(),
        ),
      );

      logger.info('Metadata fetched successfully: ${metadata.name}');
      return metadata;
    } catch (e, stackTrace) {
      _progressController.add(
        AnalysisProgress(
          phase: AnalysisPhase.error,
          progress: 0.0,
          message: 'Failed to fetch metadata: $e',
          timestamp: DateTime.now(),
        ),
      );

      if (e is AnalyzerException) {
        rethrow;
      }

      logger.severe('Failed to fetch metadata', e, stackTrace);
      throw AnalyzerException(
        'Failed to fetch repository metadata',
        code: AnalyzerErrorCode.analysisError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clears all cached analysis results.
  ///
  /// Removes all cached repository analysis data from disk. This forces
  /// subsequent analyses to perform fresh downloads and processing.
  ///
  /// This method has no effect if caching is disabled in configuration.
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// // Clear all cached results
  /// await analyzer.clearCache();
  ///
  /// // Next analysis will fetch fresh data
  /// final result = await analyzer.analyze(
  ///   'https://github.com/flutter/flutter',
  /// );
  /// ```
  ///
  /// ## When to Clear Cache
  ///
  /// * After updating dependencies or analyzer code
  /// * When repository has been updated but commit SHA hasn't changed
  /// * To troubleshoot cache-related issues
  /// * When running out of disk space
  Future<void> clearCache() async {
    if (cacheService != null) {
      await cacheService!.clear();
      logger.info('Cache cleared');
    }
  }

  /// Retrieves cache statistics.
  ///
  /// Returns information about the current cache state including:
  /// * Number of cached entries
  /// * Total cache size in bytes
  /// * Oldest and newest cache entries
  /// * Hit/miss statistics (if available)
  ///
  /// ## Returns
  ///
  /// Map containing cache statistics, or null if caching is disabled.
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// final stats = await analyzer.getCacheStatistics();
  /// if (stats != null) {
  ///   print('Cached entries: ${stats['count']}');
  ///   print('Total size: ${stats['totalSize']} bytes');
  /// }
  /// ```
  Future<Map<String, dynamic>?> getCacheStatistics() async {
    return await cacheService?.getStatistics();
  }

  /// Disposes all resources and cleans up.
  ///
  /// Releases all resources including:
  /// * Closes progress stream controller
  /// * Disposes HTTP client connections
  /// * Shuts down isolate pool
  ///
  /// **Important:** Always call this method when done using the analyzer
  /// to prevent resource leaks.
  ///
  /// ## Example
  ///
  /// ```
  /// final analyzer = await GithubAnalyzer.create();
  ///
  /// try {
  ///   final result = await analyzer.analyze('https://github.com/flutter/flutter');
  ///   // Use result...
  /// } finally {
  ///   await analyzer.dispose(); // Always dispose
  /// }
  /// ```
  ///
  /// ## Resource Cleanup
  ///
  /// * Closes progress stream (no more events will be emitted)
  /// * Terminates all HTTP connections
  /// * Stops all isolate workers
  /// * Releases file handles
  ///
  /// After calling dispose, the analyzer instance should not be used anymore.
  Future<void> dispose() async {
    _progressController.close();
    httpClientManager.dispose();
    isolatePool?.dispose();
    logger.info('GithubAnalyzer disposed');
  }
}
