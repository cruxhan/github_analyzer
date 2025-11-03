/// Defines the types of errors that can occur during analysis.
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

/// A custom exception class for handling errors within the analyzer.
///
/// This class standardizes error reporting by providing a consistent
/// structure that includes a message, detailed information, an error code,
/// and the original exception that was caught.
class AnalyzerException implements Exception {
  final String message;
  final String? details;
  final AnalyzerErrorCode code;
  final Object? originalException;
  final StackTrace? stackTrace;

  /// Creates an instance of [AnalyzerException].
  AnalyzerException(
    this.message, {
    this.details,
    required this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AnalyzerException [$code]: $message');
    if (details != null) {
      buffer.write('\n  Details: $details');
    }
    if (originalException != null) {
      buffer.write('\n  Original Exception: ${originalException.toString()}');
    }
    if (stackTrace != null) {
      buffer.write('\n  Stack Trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}
