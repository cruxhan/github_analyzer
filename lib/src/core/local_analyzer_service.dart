import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/core/incremental_analyzer.dart';
import 'package:path/path.dart' as path;

class LocalAnalyzerService {
  final GithubAnalyzerConfig config;
  final AnalyzerLogger logger;
  final RepositoryAnalyzer _repositoryAnalyzer;
  final IncrementalAnalyzer _incrementalAnalyzer;

  LocalAnalyzerService({
    required this.config,
    required this.logger,
    RepositoryAnalyzer? repositoryAnalyzer,
  }) : _repositoryAnalyzer =
           repositoryAnalyzer ??
           RepositoryAnalyzer(config: config, logger: logger),
       _incrementalAnalyzer = IncrementalAnalyzer(
         config: config,
         logger: logger,
       );

  Future<AnalysisResult> analyze(
    String directoryPath, {
    AnalysisResult? previousResult,
  }) async {
    logger.info('Starting local analysis: $directoryPath');

    if (previousResult != null) {
      logger.info(
        'Previous analysis result found, performing incremental analysis.',
      );
      try {
        final result = await _incrementalAnalyzer.analyze(
          directoryPath,
          previousResult: previousResult,
        );
        logger.info(
          'Incremental analysis completed: ${result.files.length} files analyzed',
        );
        return result;
      } catch (e) {
        logger.warning(
          'Incremental analysis failed: $e. Performing full analysis instead.',
        );
      }
    }

    logger.info('Performing full analysis.');
    final files = await _repositoryAnalyzer.analyzeDirectory(directoryPath);
    final statistics = AnalysisStatistics.fromSourceFiles(files);

    final primaryLanguage = statistics.languageDistribution.isEmpty
        ? null
        : statistics.languageDistribution.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

    final metadata = RepositoryMetadata(
      name: path.basename(directoryPath),
      fullName: path.basename(directoryPath),
      description: 'Local repository analysis',
      isPrivate: false,
      defaultBranch: null,
      language: primaryLanguage,
      languages: statistics.languageDistribution.keys.toList(),
      stars: 0,
      forks: 0,
      fileCount: files.length,
      commitSha: null,
      directoryTree: '',
    );

    final mainFiles = identifyMainFiles(files);
    final dependencies = extractDependencies(files);
    final errors = _repositoryAnalyzer.getErrors();

    logger.info(
      'Full local analysis completed: ${files.length} files analyzed',
    );

    return AnalysisResult(
      metadata: metadata,
      files: files,
      statistics: statistics,
      mainFiles: mainFiles,
      dependencies: dependencies,
      errors: errors,
    );
  }
}
