/// Represents an error that occurred during analysis.
class AnalysisError {
  final String path;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;

  /// Creates a const instance of [AnalysisError].
  const AnalysisError({
    required this.path,
    required this.message,
    required this.timestamp,
    this.stackTrace,
  });

  /// Creates a copy of this error but with the given fields replaced with the new values.
  AnalysisError copyWith({
    String? path,
    String? message,
    DateTime? timestamp,
    String? stackTrace,
  }) {
    return AnalysisError(
      path: path ?? this.path,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'stack_trace': stackTrace,
    };
  }

  /// Creates an instance of [AnalysisError] from a JSON map.
  factory AnalysisError.fromJson(Map<String, dynamic> json) {
    return AnalysisError(
      path: json['path'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stackTrace: json['stack_trace'] as String?,
    );
  }

  @override
  String toString() {
    return 'AnalysisError(path: $path, message: $message, timestamp: $timestamp)';
  }
}
