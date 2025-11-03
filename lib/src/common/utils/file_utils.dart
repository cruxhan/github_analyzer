import 'package:universal_io/io.dart';
import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/constants.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:glob/glob.dart';

/// Formats file size in bytes to a human-readable string
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Checks if a file path matches any of the given patterns
bool matchesAnyPattern(String filePath, List<String> patterns) {
  final normalizedPath = path.normalize(filePath).replaceAll('\\', '/');

  for (final pattern in patterns) {
    if (Glob(pattern).matches(normalizedPath)) {
      return true;
    }
  }

  return false;
}

/// Checks if a file should be excluded based on exclude patterns
bool shouldExclude(String filePath, List<String>? excludePatterns) {
  return matchesAnyPattern(
    filePath,
    excludePatterns ?? kDefaultExcludePatterns,
  );
}

/// Checks if a file is binary based on its extension
bool isBinaryFile(String filePath) {
  final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
  return kBinaryExtensions.contains(extension);
}

/// Checks if a file is a configuration file
bool isConfigurationFile(String filePath) {
  final fileName = path.basename(filePath).toLowerCase();
  final extension = path.extension(fileName).replaceAll('.', '');

  if (kConfigurationFileNames.contains(fileName)) {
    return true;
  }

  return kConfigurationExtensions.contains(extension);
}

/// Checks if a file is a documentation file
bool isDocumentationFile(String filePath) {
  final fileNameWithExt = path.basename(filePath).toLowerCase();
  final extension = path.extension(fileNameWithExt).replaceAll('.', '');
  final fileNameWithoutExt = path.basenameWithoutExtension(fileNameWithExt);

  if (kDocumentationFileNames.contains(fileNameWithoutExt) ||
      kDocumentationFileNames.contains(fileNameWithExt)) {
    return true;
  }

  return kDocumentationExtensions.contains(extension);
}

/// Identifies main entry point files from a list of source files
List<String> identifyMainFiles(List<SourceFile> files) {
  final mainFiles = <String>[];

  for (final file in files) {
    final fileName = path.basename(file.path);
    if (kMainFilePatterns.contains(fileName)) {
      mainFiles.add(file.path);
    }
  }

  return mainFiles;
}

/// Extracts dependency information from source files
Map<String, List<String>> extractDependencies(List<SourceFile> files) {
  final dependencies = <String, List<String>>{};

  for (final file in files) {
    if (file.content == null) continue;

    final fileName = path.basename(file.path);
    List<String>? deps;

    switch (fileName) {
      case 'package.json':
        deps = ['Node.js/npm'];
        break;
      case 'pubspec.yaml':
        deps = ['Dart/pub'];
        break;
      case 'requirements.txt':
      case 'setup.py':
        deps = ['Python/pip'];
        break;
      case 'Cargo.toml':
        deps = ['Rust/cargo'];
        break;
      case 'go.mod':
        deps = ['Go modules'];
        break;
      case 'pom.xml':
      case 'build.gradle':
        deps = ['Java/Maven or Gradle'];
        break;
      case 'Gemfile':
        deps = ['Ruby/bundler'];
        break;
      case 'composer.json':
        deps = ['PHP/composer'];
        break;
    }

    if (deps != null) {
      dependencies[file.path] = deps;
    }
  }

  return dependencies;
}

/// Reads file content if it's within the size limit
Future<String?> readFileContent(File file, int maxFileSize) async {
  final stat = await file.stat();

  if (stat.size > maxFileSize) {
    return null;
  }

  try {
    return await file.readAsString();
  } catch (e) {
    return null;
  }
}
