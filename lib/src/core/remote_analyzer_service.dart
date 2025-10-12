import 'dart:async';
import 'package:archive/archive.dart';
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/utils/directory_tree_generator.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/common/utils/github_utils.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/data/providers/zip_downloader.dart';
import 'package:github_analyzer/src/core/cache_service.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/models/analysis_progress.dart';

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
      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.initializing,
          progress: 0.1,
          message: 'Fetching repository metadata',
          timestamp: DateTime.now(),
        ),
      );

      final metadata = await apiProvider.getRepositoryMetadata(owner, repo);
      final targetBranch = branch ?? metadata.defaultBranch ?? 'main';
      final commitSha = metadata.commitSha;

      if (commitSha == null) {
        logger.warning(
          'Could not determine commit SHA. Caching will be disabled.',
        );
        useCache = false;
      }

      if (useCache && cacheService != null && commitSha != null) {
        _emitProgress(
          AnalysisProgress(
            phase: AnalysisPhase.initializing,
            progress: 0.2,
            message: 'Checking cache',
            timestamp: DateTime.now(),
          ),
        );

        final cached = await cacheService!.get(repositoryUrl, commitSha);
        if (cached != null) {
          logger.info('Using cached result');
          _emitProgress(
            AnalysisProgress(
              phase: AnalysisPhase.completed,
              progress: 1.0,
              message: 'Loaded from cache',
              timestamp: DateTime.now(),
            ),
          );
          return cached;
        }
      }

      logger.info('Downloading repository as ZIP (branch: $targetBranch)');
      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.downloading,
          progress: 0.3,
          message: 'Downloading repository archive',
          timestamp: DateTime.now(),
        ),
      );

      final zipBytes = await zipDownloader.downloadRepositoryAsBytes(
        owner: owner,
        repo: repo,
        branch: targetBranch,
        token: config.githubToken,
      );

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.extracting,
          progress: 0.5,
          message: 'Extracting archive',
          timestamp: DateTime.now(),
        ),
      );

      logger.info('Archive downloaded, analyzing from memory...');
      final archive = ZipDecoder().decodeBytes(zipBytes);

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.analyzing,
          progress: 0.6,
          message: 'Analyzing files',
          timestamp: DateTime.now(),
        ),
      );

      final repositoryAnalyzer = RepositoryAnalyzer(
        config: config,
      );

      final files = await repositoryAnalyzer.analyzeArchive(archive);
      final filePaths = files.map((f) => f.path).toList();
      final directoryTree = DirectoryTreeGenerator.generate(filePaths);

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.processing,
          progress: 0.8,
          message: 'Processing analysis results',
          timestamp: DateTime.now(),
        ),
      );

      final statistics = AnalysisStatistics.fromSourceFiles(files);
      final mainFiles = identifyMainFiles(files);
      final dependencies = extractDependencies(files);
      final errors = repositoryAnalyzer.getErrors();

      final result = AnalysisResult(
        metadata: metadata.copyWith(
          fileCount: files.length,
          languages: statistics.languageDistribution.keys.toList(),
          directoryTree: directoryTree,
        ),
        files: files,
        statistics: statistics,
        mainFiles: mainFiles,
        dependencies: dependencies,
        errors: errors,
      );

      if (useCache && cacheService != null && commitSha != null) {
        _emitProgress(
          AnalysisProgress(
            phase: AnalysisPhase.caching,
            progress: 0.9,
            message: 'Caching results',
            timestamp: DateTime.now(),
          ),
        );
        await cacheService!.set(repositoryUrl, commitSha, result);
      }

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.completed,
          progress: 1.0,
          message: 'Analysis completed',
          timestamp: DateTime.now(),
        ),
      );

      logger.info('Remote analysis completed: ${files.length} files analyzed');
      return result;
    } catch (e, stackTrace) {
      logger.severe('Remote analysis failed.', e, stackTrace);

      _emitProgress(
        AnalysisProgress(
          phase: AnalysisPhase.error,
          progress: 0.0,
          message: 'Analysis failed: ${e.toString()}',
          timestamp: DateTime.now(),
        ),
      );

      if (e is AnalyzerException) {
        rethrow;
      }

      throw AnalyzerException(
        'Remote analysis failed',
        code: AnalyzerErrorCode.analysisError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _emitProgress(AnalysisProgress progress) {
    if (progressController != null && !progressController!.isClosed) {
      progressController!.add(progress);
    }
  }
}
