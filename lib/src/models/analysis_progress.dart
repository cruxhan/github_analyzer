import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_progress.freezed.dart';
part 'analysis_progress.g.dart';

/// Represents the different phases of the analysis process.
enum AnalysisPhase {
  initializing,
  downloading,
  extracting,
  analyzing,
  processing,
  generating,
  caching,
  completed,
  error,
}

/// Represents the progress of a repository analysis.
@freezed
abstract class AnalysisProgress with _$AnalysisProgress {
  const AnalysisProgress._();

  const factory AnalysisProgress({
    required AnalysisPhase phase,
    required double progress,
    String? message,
    String? currentFile,
    int? processedFiles,
    int? totalFiles,
    required DateTime timestamp,
  }) = _AnalysisProgress;

  /// The progress as a percentage (0.0 to 100.0).
  double get percentage => (progress * 100).clamp(0.0, 100.0);

  /// Custom toString with progress details
  @override
  String toString() {
    final buffer = StringBuffer('AnalysisProgress(phase: ${phase.name}');
    buffer.write(', progress: ${percentage.toStringAsFixed(1)}%');

    if (processedFiles != null && totalFiles != null) {
      buffer.write(', files: $processedFiles/$totalFiles');
    }

    if (currentFile != null) {
      buffer.write(', current: $currentFile');
    }

    buffer.write(')');
    return buffer.toString();
  }

  factory AnalysisProgress.fromJson(Map<String, dynamic> json) =>
      _$AnalysisProgressFromJson(json);
}
