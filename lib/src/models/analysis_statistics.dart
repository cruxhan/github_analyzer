import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:github_analyzer/src/models/source_file.dart';

part 'analysis_statistics.freezed.dart';
part 'analysis_statistics.g.dart';

/// Represents statistical data from a repository analysis.
@Freezed(toJson: true) // ⬅️ 추가
abstract class AnalysisStatistics with _$AnalysisStatistics {
  const AnalysisStatistics._();

  const factory AnalysisStatistics({
    @Default(0) int totalFiles,
    @Default(0) int totalLines,
    @Default(0) int totalSize,
    @Default({}) Map<String, int> languageDistribution,
    @Default(0) int binaryFiles,
    @Default(0) int sourceFiles,
    @Default(0) int configFiles,
    @Default(0) int documentationFiles,
  }) = _AnalysisStatistics;

  factory AnalysisStatistics.fromSourceFiles(List<SourceFile> files) {
    int totalLines = 0;
    int totalSize = 0;
    int binaryFiles = 0;
    int sourceFiles = 0;
    int configFiles = 0;
    int documentationFiles = 0;
    final languageDistribution = <String, int>{};

    for (final file in files) {
      totalLines += file.lineCount;
      totalSize += file.size;
      if (file.isBinary) binaryFiles++;
      if (file.isSourceCode) sourceFiles++;
      if (file.isConfiguration) configFiles++;
      if (file.isDocumentation) documentationFiles++;

      if (file.language != null && file.language!.isNotEmpty) {
        languageDistribution[file.language!] =
            (languageDistribution[file.language!] ?? 0) + 1;
      }
    }

    return AnalysisStatistics(
      totalFiles: files.length,
      totalLines: totalLines,
      totalSize: totalSize,
      languageDistribution: languageDistribution,
      binaryFiles: binaryFiles,
      sourceFiles: sourceFiles,
      configFiles: configFiles,
      documentationFiles: documentationFiles,
    );
  }

  @override
  String toString() {
    return 'AnalysisStatistics(files: $totalFiles, lines: $totalLines, size: $totalSize)';
  }

  factory AnalysisStatistics.fromJson(Map<String, dynamic> json) =>
      _$AnalysisStatisticsFromJson(json);
}
