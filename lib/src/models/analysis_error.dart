import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_error.freezed.dart';
part 'analysis_error.g.dart';

/// Represents an error that occurred during analysis.
@freezed
abstract class AnalysisError with _$AnalysisError {
  const factory AnalysisError({
    required String path,
    required String message,
    required DateTime timestamp,
    String? stackTrace,
  }) = _AnalysisError;

  /// Creates an instance of [AnalysisError] from a JSON map.
  factory AnalysisError.fromJson(Map<String, dynamic> json) =>
      _$AnalysisErrorFromJson(json);
}
