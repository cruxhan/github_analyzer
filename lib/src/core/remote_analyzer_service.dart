import 'dart:async';
import 'package:archive/archive.dart';
import 'package:github_analyzer/github_analyzer.dart';

// Internal-only imports that aren't exported
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/common/utils/github_utils.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/common/utils/directory_tree_generator.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';

/// Service responsible for analyzing remote GitHub repositories.
///
/// It handles fetching repository metadata, downloading the archive,
/// analyzing the contents, and managing the cache.
class RemoteAnalyzerService {
  final GithubAnalyzerConfig config;
  final IGithubApiProvider apiProvider;
  final ZipDownloader zipDownloader;
  final CacheService? cacheService;
  final StreamController<AnalysisProgress>? progressController;

  /// Creates an instance of [RemoteAnalyzerService].
  RemoteAnalyzerService({
    required this.config,
    required this.apiProvider,
    required this.zipDownloader,
    this.cacheService,
    this.progressController,
  });

  /// Creates a copy of this service with the given fields replaced.
  /// This is useful for modifying the service's behavior, such as providing
  /// a progress controller for a specific analysis run.
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

  /// Analyzes a remote repository.
  Future<AnalysisResult> analyze({
    required String repositoryUrl,
    String? branch,
    bool useCache = true,
  }) async {
    logger.info('Starting remote analysis: $repositoryUrl');
    _emitProgress(
      AnalysisProgress(
        phase: AnalysisPhase.initializing,
        progress: 0.0,
        message: 'Initializing analysis',
        timestamp: DateTime.now(),
      ),
    );

    // Parse and validate GitHub URL
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
      // ✅ 토큰이 있을 때만 메타데이터 가져오기 시도
      RepositoryMetadata? metadata;
      String? commitSha;
      String targetBranch = branch ?? 'main'; // 기본값

      if (config.githubToken != null && config.githubToken!.isNotEmpty) {
        _emitProgress(
          AnalysisProgress(
            phase: AnalysisPhase.initializing,
            progress: 0.1,
            message: 'Fetching repository metadata',
            timestamp: DateTime.now(),
          ),
        );

        try {
          // 1. Get metadata (primarily for default branch)
          metadata = await apiProvider.getRepositoryMetadata(owner, repo);

          // 2. Determine the target branch to analyze
          targetBranch = branch ?? metadata.defaultBranch ?? 'main';

          _emitProgress(
            AnalysisProgress(
              phase: AnalysisPhase.initializing,
              progress: 0.15,
              message: 'Fetching commit SHA for branch $targetBranch',
              timestamp: DateTime.now(),
            ),
          );

          // 3. Get the exact commit SHA for that branch
          commitSha = await apiProvider.getCommitShaForBranch(
            owner,
            repo,
            targetBranch,
          );

          logger.info('Using commit SHA: $commitSha for branch: $targetBranch');
        } catch (e, stackTrace) {
          logger.warning(
            'Failed to fetch metadata (token may be invalid), falling back to public ZIP download',
            e,
            stackTrace,
          );
          // 메타데이터 가져오기 실패 시 null로 유지하고 계속 진행
          metadata = null;
          commitSha = null;
        }
      } else {
        logger.info(
          'No GitHub token provided, skipping metadata fetch and using public ZIP download',
        );
      }

      // 4. Check cache (use commitSha if available, otherwise use branch name)
      final cacheKey = commitSha ?? '$owner-$repo-$targetBranch';
      final repositoryUrl = 'https://github.com/$owner/$repo';

      if (useCache && config.enableCache && cacheService != null) {
        _emitProgress(
          AnalysisProgress(
            phase: AnalysisPhase.initializing,
            progress: 0.2,
            message: 'Checking cache',
            timestamp: DateTime.now(),
          ),
        );

        final cachedResult = await cacheService!.get(repositoryUrl, cacheKey);
        if (cachedResult != null) {
          logger.info('Cache hit for $cacheKey');
          _emitProgress(
            AnalysisProgress(
              phase: AnalysisPhase.completed,
              progress: 1.0,
              message: 'Analysis completed (from cache)',
              timestamp: DateTime.now(),
            ),
          );
          return cachedResult;
        }

        logger.info('Cache miss for $cacheKey');
      }

      // 5. Download repository archive
      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.downloading,
          progress: 0.3,
          message: 'Downloading repository archive',
          timestamp: DateTime.now(),
        ),
      );

      final archiveBytes = await zipDownloader.downloadRepositoryAsBytes(
        owner: owner,
        repo: repo,
        ref: commitSha ?? targetBranch,
        token: config.githubToken,
        isPrivate: metadata?.isPrivate ?? false,
      );

      logger.info('Archive downloaded: ${archiveBytes.length} bytes');

      // 6. Extract and analyze
      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.extracting,
          progress: 0.5,
          message: 'Extracting archive',
          timestamp: DateTime.now(),
        ),
      );

      final archive = ZipDecoder().decodeBytes(archiveBytes);
      logger.info('Archive extracted: ${archive.files.length} files');

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.analyzing,
          progress: 0.6,
          message: 'Analyzing files',
          timestamp: DateTime.now(),
        ),
      );

      final repositoryAnalyzer = RepositoryAnalyzer(config: config);
      final files = await repositoryAnalyzer.analyzeArchive(archive);

      logger.info('Files analyzed: ${files.length}');

      // 7. Generate statistics and metadata
      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.analyzing,
          progress: 0.9,
          message: 'Generating statistics',
          timestamp: DateTime.now(),
        ),
      );

      final statistics = AnalysisStatistics.fromSourceFiles(files);
      final primaryLanguage = statistics.languageDistribution.isEmpty
          ? null
          : statistics.languageDistribution.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;

      // ✅ 메타데이터가 없으면 기본값으로 생성
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

      final mainFiles = identifyMainFiles(files);
      final dependencies = extractDependencies(files);
      final errors = repositoryAnalyzer.getErrors();

      final result = AnalysisResult(
        metadata: finalMetadata,
        files: files,
        statistics: statistics,
        mainFiles: mainFiles,
        dependencies: dependencies,
        errors: errors,
      );

      // 8. Cache the result
      if (useCache && config.enableCache && cacheService != null) {
        await cacheService!.set(repositoryUrl, cacheKey, result);
        logger.info('Result cached with key: $cacheKey');
      }

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.completed,
          progress: 1.0,
          message: 'Analysis completed successfully',
          timestamp: DateTime.now(),
        ),
      );

      logger.info('Remote analysis completed: ${files.length} files');
      return result;
    } catch (e, stackTrace) {
      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.error,
          progress: 0.0,
          message: 'Analysis failed: $e',
          timestamp: DateTime.now(),
        ),
      );

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

  /// Emits a progress update if a progress controller is available
  void _emitProgress(AnalysisProgress progress) {
    progressController?.add(progress);
  }
}
