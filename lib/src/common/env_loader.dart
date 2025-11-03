import 'package:universal_io/io.dart';
import 'package:path/path.dart' as p;
import 'package:github_analyzer/src/common/logger.dart';

/// Loads environment variables from .env file automatically
class EnvLoader {
  static bool _isLoaded = false;
  static final Map<String, String> _envVariables = {};

  /// Loads .env file if not already loaded
  static Future<void> load() async {
    if (_isLoaded) return;

    try {
      // ✅ 프로젝트 루트에서 .env 파일 찾기
      final envFile = await _findEnvFile();

      if (envFile == null) {
        logger.fine('No .env file found');
        _isLoaded = true;
        return;
      }

      final lines = await envFile.readAsLines();

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

      logger.fine('.env file loaded successfully from: ${envFile.path}');
      _isLoaded = true;
    } catch (e, stackTrace) {
      logger.warning('Error loading .env file', e, stackTrace);
      _isLoaded = true;
    }
  }

  /// ✅ 프로젝트 루트의 .env 파일을 찾습니다
  ///
  /// 1. 현재 작업 디렉토리에서 .env 파일 확인
  /// 2. 없으면 상위 디렉토리로 최대 10단계까지 탐색
  /// 3. .env 파일 발견 시 pubspec.yaml 또는 .git 존재 여부로 프로젝트 루트 검증
  static Future<File?> _findEnvFile() async {
    // 1. 현재 디렉토리에서 먼저 확인
    var currentDir = Directory.current;
    var envFile = File(p.join(currentDir.path, '.env'));

    if (await envFile.exists()) {
      return envFile;
    }

    // 2. 상위 디렉토리로 올라가면서 찾기 (최대 10단계)
    for (var i = 0; i < 10; i++) {
      currentDir = currentDir.parent;

      // 루트에 도달하면 중단
      if (currentDir.path == '/' || currentDir.path == currentDir.parent.path) {
        break;
      }

      envFile = File(p.join(currentDir.path, '.env'));

      if (await envFile.exists()) {
        // pubspec.yaml이나 .git이 있는지 확인 (프로젝트 루트 여부)
        final hasPubspec = await File(
          p.join(currentDir.path, 'pubspec.yaml'),
        ).exists();
        final hasGit = await Directory(
          p.join(currentDir.path, '.git'),
        ).exists();

        // 프로젝트 루트로 판단되면 반환
        if (hasPubspec || hasGit) {
          return envFile;
        }
      }
    }

    return null;
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
