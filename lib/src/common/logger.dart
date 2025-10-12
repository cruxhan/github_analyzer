import 'package:logging/logging.dart';

/// The root logger for the application.
final logger = Logger('GithubAnalyzer');

/// Sets up the logger for the application.
///
/// Configures the logging level and sets up a listener to print log records
/// to the console with a specific format.
///
/// If [verbose] is true, the log level is set to [Level.ALL], otherwise it
/// defaults to [Level.INFO].
void setupLogger({bool verbose = false}) {
  Logger.root.level = verbose ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
      '${record.time} [${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      print('  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('  Stack Trace:\n${record.stackTrace}');
    }
  });
}
