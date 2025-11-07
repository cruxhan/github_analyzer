import 'dart:async';

import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:github_analyzer/github_analyzer.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/common/utils/github_utils.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/common/utils/directory_tree_generator.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';

/// Analyzes remote GitHub repositories and generates code analysis results.
///
/// This service handles downloading, extracting, and analyzing repository
/// archives with optional caching and progress tracking.
class RemoteAnalyzerService {
  final GithubAnalyzerConfig config;
  final IGithubApiProvider apiProvider;
  final ZipDownloader zipDownloader;
  final CacheService? cacheService;
  final StreamController<AnalysisProgress>? progressController;

  RemoteAnalyzerService({
    required this.config,
    required this.apiProvider,
    required this.zipDownloader,
    this.cacheService,
    this.progressController,
  });

  /// Returns a copy of this service with updated fields.
  RemoteAnalyzerService copyWith({
    GithubAnalyzerConfig? config,
    IGithubApiProvider? apiProvider,
    ZipDownloader? zipDownloader,
    CacheService? cacheService,
    StreamController<AnalysisProgress>? progressController,
  }) {
    return RemoteAnalyzerService(
      config: config ?? this.config,
      apiProvider: apiProvider ?? this.apiProvider,
      zipDownloader: zipDownloader ?? this.zipDownloader,
      cacheService: cacheService ?? this.cacheService,
      progressController: progressController ?? this.progressController,
    );
  }

  /// Analyzes a remote repository at the specified [repositoryUrl].
  ///
  /// The [branch] parameter specifies which branch to analyze. If omitted,
  /// the repository's default branch is used with token, or automatic
  /// fallback branches are tried without token.
  ///
  /// Returns cached results if [useCache] is true and a valid cache exists.
  /// Throws [AnalyzerException] if the analysis fails.
  Future<AnalysisResult> analyze({
    required String repositoryUrl,
    String? branch,
    bool useCache = true,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');
    _emitProgress(0.0, 'Initializing analysis', AnalysisPhase.initializing);

    final parsedUrl = parseGitHubUrl(repositoryUrl);
    if (parsedUrl == null) {
      throw AnalyzerException(
        'Invalid GitHub URL: $repositoryUrl',
        code: AnalyzerErrorCode.invalidUrl,
        details: 'Expected format: https://github.com/owner/repo',
      );
    }

    final owner = parsedUrl['owner']!;
    final repo = parsedUrl['repo']!;

    try {
      final branchInfo = await _resolveBranchAndMetadata(owner, repo, branch);
      final targetBranch = branchInfo['branch'] as String;
      final metadata = branchInfo['metadata'] as RepositoryMetadata?;
      final commitSha = branchInfo['commitSha'] as String?;

      final cacheResult = await _checkCache(
        repositoryUrl,
        owner,
        repo,
        targetBranch,
        commitSha,
        useCache,
      );
      if (cacheResult != null) return cacheResult;

      _emitProgress(
        0.3,
        'Downloading repository archive',
        AnalysisPhase.downloading,
      );
      final archiveBytes = await zipDownloader.downloadRepositoryAsBytes(
        owner: owner,
        repo: repo,
        ref: commitSha ?? targetBranch,
        token: config.githubToken,
        isPrivate: metadata?.isPrivate ?? false,
      );
      logger.info('Archive downloaded: ${archiveBytes.length} bytes');

      _emitProgress(0.5, 'Extracting archive', AnalysisPhase.extracting);
      final archive = ZipDecoder().decodeBytes(archiveBytes);
      logger.info('Archive extracted: ${archive.files.length} files');

      _emitProgress(0.6, 'Analyzing files', AnalysisPhase.analyzing);
      final repositoryAnalyzer = RepositoryAnalyzer(config: config);
      final files = await repositoryAnalyzer.analyzeArchive(archive);
      logger.info('Files analyzed: ${files.length}');

      _emitProgress(0.9, 'Generating statistics', AnalysisPhase.analyzing);
      final result = await _buildAnalysisResult(
        metadata,
        files,
        repositoryAnalyzer,
        owner,
        repo,
        targetBranch,
        commitSha,
      );

      await _cacheResult(
        repositoryUrl,
        owner,
        repo,
        targetBranch,
        commitSha,
        result,
        useCache,
      );

      _emitProgress(
        1.0,
        'Analysis completed successfully',
        AnalysisPhase.completed,
      );
      logger.info('Remote analysis completed: ${files.length} files');
      return result;
    } catch (e, stackTrace) {
      _emitProgress(0.0, 'Analysis failed: $e', AnalysisPhase.error);

      if (e is AnalyzerException) {
        rethrow;
      }

      throw AnalyzerException(
        'Remote analysis failed for $repositoryUrl',
        code: AnalyzerErrorCode.analysisError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Resolves the target branch and retrieves repository metadata.
  ///
  /// Uses GitHub API if [config.githubToken] is available, otherwise
  /// attempts automatic branch detection from a predefined list.
  Future<Map<String, dynamic>> _resolveBranchAndMetadata(
    String owner,
    String repo,
    String? branch,
  ) async {
    RepositoryMetadata? metadata;
    String? commitSha;
    String targetBranch = branch ?? 'main';

    if (config.githubToken != null && config.githubToken!.isNotEmpty) {
      _emitProgress(
        0.1,
        'Fetching repository metadata',
        AnalysisPhase.initializing,
      );

      try {
        metadata = await apiProvider.getRepositoryMetadata(owner, repo);
        targetBranch = branch ?? metadata.defaultBranch ?? 'main';

        _emitProgress(
          0.15,
          'Fetching commit SHA for branch $targetBranch',
          AnalysisPhase.initializing,
        );
        commitSha = await apiProvider.getCommitShaForBranch(
          owner,
          repo,
          targetBranch,
        );

        logger.info('Using commit SHA: $commitSha for branch: $targetBranch');
      } catch (e, stackTrace) {
        logger.warning(
          'Failed to fetch metadata, falling back to public ZIP download',
          e,
          stackTrace,
        );
        metadata = null;
        commitSha = null;
      }
    } else if (branch == null) {
      logger.info(
        'No GitHub token provided, attempting automatic branch detection',
      );
      targetBranch = await _tryFallbackBranches(owner, repo);
    }

    return {
      'branch': targetBranch,
      'metadata': metadata,
      'commitSha': commitSha,
    };
  }

  /// Checks the cache and returns cached result if available.
  ///
  /// Returns null if caching is disabled, cache is uninitialized, or no
  /// valid cached result exists.
  Future<AnalysisResult?> _checkCache(
    String repositoryUrl,
    String owner,
    String repo,
    String targetBranch,
    String? commitSha,
    bool useCache,
  ) async {
    if (!useCache || !config.enableCache || cacheService == null) {
      return null;
    }

    if (!cacheService!.isInitialized) {
      await cacheService!.initialize();
    }

    _emitProgress(0.2, 'Checking cache', AnalysisPhase.initializing);

    final cacheKey = commitSha ?? '$owner-$repo-$targetBranch';
    final cachedResult = await cacheService!.get(repositoryUrl, cacheKey);

    if (cachedResult != null) {
      logger.info('Cache hit for $cacheKey');
      _emitProgress(
        1.0,
        'Analysis completed (from cache)',
        AnalysisPhase.completed,
      );
      return cachedResult;
    }

    logger.info('Cache miss for $cacheKey');
    return null;
  }

  /// Builds the analysis result from extracted files and metadata.
  ///
  /// Generates statistics, identifies primary language, and creates
  /// repository metadata.
  Future<AnalysisResult> _buildAnalysisResult(
    RepositoryMetadata? metadata,
    List<SourceFile> files,
    RepositoryAnalyzer repositoryAnalyzer,
    String owner,
    String repo,
    String targetBranch,
    String? commitSha,
  ) async {
    final statistics = AnalysisStatistics.fromSourceFiles(files);
    final primaryLanguage = _getPrimaryLanguage(statistics);

    final finalMetadata =
        metadata?.copyWith(
          language: primaryLanguage,
          languages: statistics.languageDistribution.keys.toList(),
          fileCount: files.length,
          commitSha: commitSha,
        ) ??
        RepositoryMetadata(
          name: repo,
          fullName: '$owner/$repo',
          description: 'Public repository (analyzed without token)',
          isPrivate: false,
          defaultBranch: targetBranch,
          language: primaryLanguage,
          languages: statistics.languageDistribution.keys.toList(),
          stars: 0,
          forks: 0,
          fileCount: files.length,
          commitSha: commitSha,
          directoryTree: DirectoryTreeGenerator.generate(
            files.map((f) => f.path).toList(),
          ),
        );

    return AnalysisResult(
      metadata: finalMetadata,
      files: files,
      statistics: statistics,
      mainFiles: identifyMainFiles(files),
      dependencies: extractDependencies(files),
      errors: repositoryAnalyzer.getErrors(),
    );
  }

  /// Saves the analysis result to cache with appropriate cache key.
  Future<void> _cacheResult(
    String repositoryUrl,
    String owner,
    String repo,
    String targetBranch,
    String? commitSha,
    AnalysisResult result,
    bool useCache,
  ) async {
    if (!useCache || !config.enableCache || cacheService == null) {
      return;
    }

    final cacheKey = commitSha ?? '$owner-$repo-$targetBranch';
    await cacheService!.set(repositoryUrl, cacheKey, result);
    logger.info('Result cached with key: $cacheKey');
  }

  /// Returns the most frequently used language in the statistics.
  String? _getPrimaryLanguage(AnalysisStatistics statistics) {
    if (statistics.languageDistribution.isEmpty) {
      return null;
    }

    return statistics.languageDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Attempts to detect repository's default branch without authentication.
  ///
  /// Tries main, master, develop, development, and trunk in order.
  /// Returns the first branch that exists, or 'main' if all fail.
  Future<String> _tryFallbackBranches(String owner, String repo) async {
    final branches = ['main', 'master', 'develop', 'development', 'trunk'];

    logger.info('Attempting to detect default branch from fallback list');

    for (final branchName in branches) {
      try {
        logger.fine('Trying branch: $branchName');

        final url =
            'https://github.com/$owner/$repo/archive/refs/heads/$branchName.zip';
        final uri = Uri.parse(url);

        try {
          final response = await zipDownloader.httpClientManager.get(
            uri,
            responseType: ResponseType.bytes,
          );

          if (response.statusCode == 200) {
            logger.info('✓ Found branch: $branchName');
            return branchName;
          }
        } catch (e) {
          logger.fine('Branch $branchName check failed: $e');
          continue;
        }
      } catch (e) {
        logger.fine('Branch $branchName failed: $e');
        continue;
      }
    }

    logger.warning('All fallback branches failed, using main as default');
    return 'main';
  }

  /// Emits a progress update with the specified progress level and message.
  void _emitProgress(double progress, String message, AnalysisPhase phase) {
    progressController?.add(
      AnalysisProgress(
        phase: phase,
        progress: progress,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }
}
