import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/config.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';
import 'package:github_analyzer/src/core/repository_analyzer.dart';
import 'package:github_analyzer/src/core/incremental_analyzer.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/common/utils/directory_tree_generator.dart';

class LocalAnalyzerService {
  final GithubAnalyzerConfig config;
  final RepositoryAnalyzer repositoryAnalyzer;
  final IncrementalAnalyzer incrementalAnalyzer;

  LocalAnalyzerService({
    required this.config,
    RepositoryAnalyzer? repositoryAnalyzer,
  }) : repositoryAnalyzer =
           repositoryAnalyzer ?? RepositoryAnalyzer(config: config),
       incrementalAnalyzer = IncrementalAnalyzer(config: config);

  Future<AnalysisResult> analyze(
    String directoryPath, {
    AnalysisResult? previousResult,
  }) async {
    logger.info('Starting local analysis: $directoryPath');

    if (previousResult != null) {
      logger.info('Attempting incremental analysis');
      final result = await _tryIncrementalAnalysis(
        directoryPath,
        previousResult,
      );
      if (result != null) return result;
    }

    logger.info('Performing full analysis');
    return await _performFullAnalysis(directoryPath);
  }

  Future<AnalysisResult?> _tryIncrementalAnalysis(
    String directoryPath,
    AnalysisResult previousResult,
  ) async {
    try {
      final result = await incrementalAnalyzer.analyze(
        directoryPath,
        previousResult: previousResult,
      );
      logger.info(
        'Incremental analysis completed: ${result.files.length} files',
      );
      return result;
    } catch (e, stackTrace) {
      logger.warning(
        'Incremental analysis failed, falling back to full analysis',
        e,
        stackTrace,
      );
      return null;
    }
  }

  Future<AnalysisResult> _performFullAnalysis(String directoryPath) async {
    final files = await repositoryAnalyzer.analyzeDirectory(directoryPath);
    final statistics = AnalysisStatistics.fromSourceFiles(files);
    final metadata = _buildMetadata(directoryPath, files, statistics);

    logger.info('Full analysis completed: ${files.length} files');

    return AnalysisResult(
      metadata: metadata,
      files: files,
      statistics: statistics,
      mainFiles: identifyMainFiles(files),
      dependencies: extractDependencies(files),
      errors: repositoryAnalyzer.getErrors(),
    );
  }

  RepositoryMetadata _buildMetadata(
    String directoryPath,
    List<dynamic> files,
    AnalysisStatistics statistics,
  ) {
    final primaryLanguage = _getPrimaryLanguage(statistics);
    final filePaths = _extractFilePaths(files);

    return RepositoryMetadata(
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
      directoryTree: DirectoryTreeGenerator.generate(filePaths),
    );
  }

  String? _getPrimaryLanguage(AnalysisStatistics statistics) {
    if (statistics.languageDistribution.isEmpty) return null;

    return statistics.languageDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<String> _extractFilePaths(List<dynamic> files) {
    return files.map((f) => f.path as String).toList();
  }
}
