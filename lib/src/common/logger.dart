// ignore_for_file: avoid_print

enum LogLevel { debug, info, warning, error }

class AnalyzerLogger {
  final bool verbose;
  final LogLevel minLevel;

  AnalyzerLogger({this.verbose = false, this.minLevel = LogLevel.info});

  void debug(String message) {
    if (verbose && _shouldLog(LogLevel.debug)) {
      _log('DEBUG', message);
    }
  }

  void info(String message) {
    if (_shouldLog(LogLevel.info)) {
      _log('INFO', message);
    }
  }

  void warning(String message) {
    if (_shouldLog(LogLevel.warning)) {
      _log('WARNING', message);
    }
  }

  void error(String message) {
    if (_shouldLog(LogLevel.error)) {
      _log('ERROR', message);
    }
  }

  bool _shouldLog(LogLevel level) {
    return level.index >= minLevel.index;
  }

  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();

    print('[$timestamp] [$level] $message');
  }
}
