import 'package:github_analyzer/src/models/repository_metadata.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/models/analysis_error.dart';

/// Represents the result of a repository analysis.
class AnalysisResult {
  final RepositoryMetadata metadata;
  final List<SourceFile> files;
  final AnalysisStatistics statistics;
  final List<String> mainFiles;
  final Map<String, List<String>> dependencies;
  final List<AnalysisError> errors;

  /// Creates an instance of [AnalysisResult].
  const AnalysisResult({
    required this.metadata,
    required this.files,
    required this.statistics,
    required this.mainFiles,
    required this.dependencies,
    this.errors = const [],
  });

  /// Creates a copy of this result but with the given fields replaced with the new values.
  AnalysisResult copyWith({
    RepositoryMetadata? metadata,
    List<SourceFile>? files,
    AnalysisStatistics? statistics,
    List<String>? mainFiles,
    Map<String, List<String>>? dependencies,
    List<AnalysisError>? errors,
  }) {
    return AnalysisResult(
      metadata: metadata ?? this.metadata,
      files: files ?? this.files,
      statistics: statistics ?? this.statistics,
      mainFiles: mainFiles ?? this.mainFiles,
      dependencies: dependencies ?? this.dependencies,
      errors: errors ?? this.errors,
    );
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'files': files.map((f) => f.toJson()).toList(),
      'statistics': statistics.toJson(),
      'main_files': mainFiles,
      'dependencies': dependencies,
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates an instance of [AnalysisResult] from a JSON map.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      metadata: RepositoryMetadata.fromJson(
        (json['metadata'] as Map<String, dynamic>?) ?? {},
      ),
      files: ((json['files'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SourceFile.fromJson)
          .toList(),
      statistics: AnalysisStatistics.fromJson(
        (json['statistics'] as Map<String, dynamic>?) ?? {},
      ),
      mainFiles: ((json['main_files'] as List<dynamic>?) ?? [])
          .whereType<String>()
          .toList(),
      dependencies: ((json['dependencies'] as Map<String, dynamic>?) ?? {}).map(
        (k, v) => MapEntry(
          k,
          ((v as List<dynamic>?) ?? []).whereType<String>().toList(),
        ),
      ),
      errors: ((json['errors'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnalysisError.fromJson)
          .toList(),
    );
  }

  @override
  String toString() {
    return 'AnalysisResult(repo: ${metadata.name}, files: ${files.length}, lines: ${statistics.totalLines}, errors: ${errors.length})';
  }
}
