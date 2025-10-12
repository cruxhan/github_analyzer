import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/constants.dart';
import 'package:github_analyzer/src/models/source_file.dart';
import 'package:glob/glob.dart';

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Matches a file path against a list of glob patterns using the `glob` package.
bool _matchesAnyPattern(String filePath, List<String> patterns) {
  final normalizedPath = path.normalize(filePath).replaceAll('\\', '/');
  for (final pattern in patterns) {
    if (Glob(pattern).matches(normalizedPath)) {
      return true;
    }
  }
  return false;
}

bool shouldExclude(String filePath, List<String>? excludePatterns) {
  return _matchesAnyPattern(
      filePath, excludePatterns ?? kDefaultExcludePatterns);
}

bool isBinaryFile(String filePath) {
  final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
  return kBinaryExtensions.contains(extension);
}

bool isConfigurationFile(String filePath) {
  return _matchesAnyPattern(filePath, kConfigurationPatterns);
}

bool isDocumentationFile(String filePath) {
  return _matchesAnyPattern(filePath, kDocumentationPatterns);
}

List<String> identifyMainFiles(List<SourceFile> files) {
  final mainFiles = <String>[];
  // ... (이하 동일)
  final mainPatterns = [
    'main.dart',
    'main.py',
    'main.js',
    'main.ts',
    'index.js',
    'index.ts',
    'app.js',
    'app.ts',
    'server.js',
    'server.ts',
    'Main.java',
    'main.go',
    'main.rs',
    'main.c',
    'main.cpp',
    'main.swift',
    'MainActivity.kt',
    'AppDelegate.swift',
  ];

  for (final file in files) {
    final fileName = path.basename(file.path);
    if (mainPatterns.contains(fileName)) {
      mainFiles.add(file.path);
    }
  }
  return mainFiles;
}

Map<String, List<String>> extractDependencies(List<SourceFile> files) {
  final dependencies = <String, List<String>>{};
  // ... (이하 동일)
  for (final file in files) {
    if (file.content == null) continue;
    final fileName = path.basename(file.path);
    final deps = <String>[];

    if (fileName == 'package.json') {
      deps.add('Node.js/npm');
    } else if (fileName == 'pubspec.yaml') {
      deps.add('Dart/pub');
    } else if (fileName == 'requirements.txt' || fileName == 'setup.py') {
      deps.add('Python/pip');
    } else if (fileName == 'Cargo.toml') {
      deps.add('Rust/cargo');
    } else if (fileName == 'go.mod') {
      deps.add('Go modules');
    } else if (fileName == 'pom.xml' || fileName == 'build.gradle') {
      deps.add('Java/Maven or Gradle');
    } else if (fileName == 'Gemfile') {
      deps.add('Ruby/bundler');
    } else if (fileName == 'composer.json') {
      deps.add('PHP/composer');
    }

    if (deps.isNotEmpty) {
      dependencies[file.path] = deps;
    }
  }
  return dependencies;
}

Future<String?> readFileContent(File file, int maxFileSize) async {
  // ... (이하 동일)
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
