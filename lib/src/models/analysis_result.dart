import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:github_analyzer/src/models/analysis_statistics.dart';
import 'package:github_analyzer/src/models/analysis_error.dart';

part 'analysis_result.freezed.dart';

/// Represents the result of a repository analysis.
@freezed
abstract class AnalysisResult with _$AnalysisResult {
  const AnalysisResult._(); // Private constructor for custom methods

  const factory AnalysisResult({
    required RepositoryMetadata metadata,
    required List<SourceFile> files,
    required AnalysisStatistics statistics,
    required List<String> mainFiles,
    required Map<String, List<String>> dependencies,
    @Default([]) List<AnalysisError> errors,
  }) = _AnalysisResult;

  /// Custom toString with concise result information
  @override
  String toString() {
    return 'AnalysisResult(repo: ${metadata.name}, files: ${files.length}, lines: ${statistics.totalLines}, errors: ${errors.length})';
  }

  /// Converts this instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'files': files.map((file) => file.toJson()).toList(),
      'statistics': statistics.toJson(),
      'mainFiles': mainFiles,
      'dependencies': dependencies,
      'errors': errors.map((error) => error.toJson()).toList(),
    };
  }

  /// Creates an instance of AnalysisResult from a JSON map.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      metadata: RepositoryMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      files: (json['files'] as List<dynamic>)
          .map((e) => SourceFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      statistics: AnalysisStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
      mainFiles: (json['mainFiles'] as List<dynamic>).cast<String>(),
      dependencies: (json['dependencies'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
      errors: json['errors'] != null
          ? (json['errors'] as List<dynamic>)
                .map((e) => AnalysisError.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}
