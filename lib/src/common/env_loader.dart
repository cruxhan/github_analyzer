import 'package:universal_io/io.dart';
import 'package:github_analyzer/src/common/logger.dart';

/// Loads environment variables from .env file automatically
class EnvLoader {
  static bool _isLoaded = false;
  static final Map<String, String> _envVariables = {};

  /// Loads .env file if not already loaded
  static Future<void> load() async {
    if (_isLoaded) return;

    try {
      final file = File('.env');

      if (!await file.exists()) {
        logger.fine('No .env file found');
        _isLoaded = true;
        return;
      }

      final lines = await file.readAsLines();

      for (final line in lines) {
        final trimmed = line.trim();

        // Skip comments and empty lines
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        // Parse KEY=VALUE
        final separatorIndex = trimmed.indexOf('=');
        if (separatorIndex == -1) continue;

        final key = trimmed.substring(0, separatorIndex).trim();
        final rawValue = trimmed.substring(separatorIndex + 1).trim();

        // Clean the value
        final cleanValue = _cleanValue(rawValue);

        // Store in cache
        _envVariables[key] = cleanValue;

        // Set environment variable
        try {
          Platform.environment[key] = cleanValue;
        } catch (e) {
          // Platform.environment might be immutable on some platforms
          logger.finer('Cannot modify Platform.environment: $e');
        }
      }

      logger.fine('.env file loaded successfully');
      _isLoaded = true;
    } catch (e, stackTrace) {
      logger.warning('Error loading .env file', e, stackTrace);
      _isLoaded = true;
    }
  }

  /// Cleans the value by removing quotes and inline comments
  static String _cleanValue(String value) {
    if (value.isEmpty) return value;

    String result = value;

    // Remove inline comments (but not if inside quotes)
    final commentIndex = _findCommentIndex(result);
    if (commentIndex != -1) {
      result = result.substring(0, commentIndex).trim();
    }

    // Remove surrounding quotes (must match)
    if (result.length >= 2) {
      final firstChar = result[0];
      final lastChar = result[result.length - 1];

      // Check if wrapped in matching quotes
      if ((firstChar == '"' && lastChar == '"') ||
          (firstChar == "'" && lastChar == "'")) {
        result = result.substring(1, result.length - 1);

        // Unescape escaped quotes inside
        if (firstChar == '"') {
          result = result.replaceAll(r'\"', '"');
        } else {
          result = result.replaceAll(r"\'", "'");
        }
      }
    }

    return result;
  }

  /// Finds the index of a comment that's not inside quotes
  static int _findCommentIndex(String value) {
    bool inDoubleQuotes = false;
    bool inSingleQuotes = false;
    bool escaped = false;

    for (int i = 0; i < value.length; i++) {
      final char = value[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"' && !inSingleQuotes) {
        inDoubleQuotes = !inDoubleQuotes;
      } else if (char == "'" && !inDoubleQuotes) {
        inSingleQuotes = !inSingleQuotes;
      } else if (char == '#' && !inDoubleQuotes && !inSingleQuotes) {
        return i;
      }
    }

    return -1;
  }

  /// Gets an environment variable from .env or system environment
  static String? get(String key) {
    // Try internal cache first
    if (_envVariables.containsKey(key)) {
      return _envVariables[key];
    }

    // Fallback to Platform.environment
    return Platform.environment[key];
  }

  /// Gets GITHUB_TOKEN specifically
  static String? getGithubToken() {
    return get('GITHUB_TOKEN');
  }

  /// Checks if a specific key exists
  static bool has(String key) {
    return _envVariables.containsKey(key) ||
        Platform.environment.containsKey(key);
  }

  /// Gets all loaded environment variables (from .env only)
  static Map<String, String> get all => Map.unmodifiable(_envVariables);

  /// Resets the loader state (for testing)
  static void reset() {
    _isLoaded = false;
    _envVariables.clear();
  }
}
