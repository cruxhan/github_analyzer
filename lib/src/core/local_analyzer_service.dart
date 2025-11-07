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

/// Analyzes local file directories with optional incremental analysis.
///
/// Supports both full and incremental analysis modes. Falls back to full
/// analysis if incremental analysis fails.
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

  /// Analyzes a local directory with optional incremental mode.
  ///
  /// If [previousResult] is provided, attempts incremental analysis. Falls back
  /// to full analysis on failure. Returns comprehensive analysis result with
  /// files, statistics, metadata, and dependencies.
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

  /// Attempts incremental analysis, returns null if it fails.
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

  /// Performs full analysis of the directory.
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

  /// Builds repository metadata from analysis data.
  RepositoryMetadata _buildMetadata(
    String directoryPath,
    List<dynamic> files,
    AnalysisStatistics statistics,
  ) {
    final primaryLanguage = _getPrimaryLanguage(statistics);

    // ✅ 수정: List<dynamic>을 List<String>으로 변환
    final filePaths = files.map((f) => f.path as String).toList();

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

  /// Extracts primary (most used) language from statistics.
  String? _getPrimaryLanguage(AnalysisStatistics statistics) {
    if (statistics.languageDistribution.isEmpty) return null;

    return statistics.languageDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
