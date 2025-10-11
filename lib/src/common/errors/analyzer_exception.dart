enum AnalyzerErrorCode {
  invalidUrl,
  repositoryNotFound,
  accessDenied,
  rateLimitExceeded,
  networkError,
  cacheError,
  analysisError,
  directoryNotFound,
  fileReadError,
  archiveError,
  configurationError,
}

class AnalyzerException implements Exception {
  final String message;
  final String? details;
  final AnalyzerErrorCode code;
  final StackTrace? stackTrace;

  AnalyzerException(
    this.message, {
    this.details,
    required this.code,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AnalyzerException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    buffer.write('\nError code: ${code.name}');
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}
