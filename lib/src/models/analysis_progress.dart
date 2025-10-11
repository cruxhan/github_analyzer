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
class AnalysisProgress {
  final AnalysisPhase phase;
  final double progress;
  final String? message;
  final String? currentFile;
  final int? processedFiles;
  final int? totalFiles;
  final DateTime timestamp;

  /// Creates a const instance of [AnalysisProgress].
  const AnalysisProgress({
    required this.phase,
    required this.progress,
    this.message,
    this.currentFile,
    this.processedFiles,
    this.totalFiles,
    required this.timestamp,
  });

  /// The progress as a percentage (0.0 to 100.0).
  double get percentage => (progress * 100).clamp(0.0, 100.0);

  /// Creates a copy of this progress object but with the given fields replaced.
  AnalysisProgress copyWith({
    AnalysisPhase? phase,
    double? progress,
    String? message,
    String? currentFile,
    int? processedFiles,
    int? totalFiles,
    DateTime? timestamp,
  }) {
    return AnalysisProgress(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      currentFile: currentFile ?? this.currentFile,
      processedFiles: processedFiles ?? this.processedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'progress': progress,
      'message': message,
      'current_file': currentFile,
      'processed_files': processedFiles,
      'total_files': totalFiles,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates an instance of [AnalysisProgress] from a JSON map.
  factory AnalysisProgress.fromJson(Map<String, dynamic> json) {
    return AnalysisProgress(
      phase: AnalysisPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => AnalysisPhase.initializing,
      ),
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String?,
      currentFile: json['current_file'] as String?,
      processedFiles: json['processed_files'] as int?,
      totalFiles: json['total_files'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

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
}
