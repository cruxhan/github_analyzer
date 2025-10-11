import 'package:github_analyzer/src/models/source_file.dart';

/// Represents statistical data from a repository analysis.
class AnalysisStatistics {
  final int totalFiles;
  final int totalLines;
  final int totalSize;
  final Map<String, int> languageDistribution;
  final int binaryFiles;
  final int sourceFiles;
  final int configFiles;
  final int documentationFiles;

  /// Creates a const instance of [AnalysisStatistics].
  const AnalysisStatistics({
    required this.totalFiles,
    required this.totalLines,
    required this.totalSize,
    required this.languageDistribution,
    required this.binaryFiles,
    required this.sourceFiles,
    required this.configFiles,
    required this.documentationFiles,
  });

  /// Creates a copy of this statistics object but with the given fields replaced.
  AnalysisStatistics copyWith({
    int? totalFiles,
    int? totalLines,
    int? totalSize,
    Map<String, int>? languageDistribution,
    int? binaryFiles,
    int? sourceFiles,
    int? configFiles,
    int? documentationFiles,
  }) {
    return AnalysisStatistics(
      totalFiles: totalFiles ?? this.totalFiles,
      totalLines: totalLines ?? this.totalLines,
      totalSize: totalSize ?? this.totalSize,
      languageDistribution: languageDistribution ?? this.languageDistribution,
      binaryFiles: binaryFiles ?? this.binaryFiles,
      sourceFiles: sourceFiles ?? this.sourceFiles,
      configFiles: configFiles ?? this.configFiles,
      documentationFiles: documentationFiles ?? this.documentationFiles,
    );
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'total_files': totalFiles,
      'total_lines': totalLines,
      'total_size': totalSize,
      'language_distribution': languageDistribution,
      'binary_files': binaryFiles,
      'source_files': sourceFiles,
      'config_files': configFiles,
      'documentation_files': documentationFiles,
    };
  }

  /// Creates an instance of [AnalysisStatistics] from a JSON map.
  factory AnalysisStatistics.fromJson(Map<String, dynamic> json) {
    return AnalysisStatistics(
      totalFiles: json['total_files'] as int? ?? 0,
      totalLines: json['total_lines'] as int? ?? 0,
      totalSize: json['total_size'] as int? ?? 0,
      languageDistribution:
          (json['language_distribution'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, v as int),
          ),
      binaryFiles: json['binary_files'] as int? ?? 0,
      sourceFiles: json['source_files'] as int? ?? 0,
      configFiles: json['config_files'] as int? ?? 0,
      documentationFiles: json['documentation_files'] as int? ?? 0,
    );
  }

  /// Creates an instance of [AnalysisStatistics] from a list of [SourceFile] objects.
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
}
