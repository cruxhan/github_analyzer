import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/common/constants.dart';
import 'package:github_analyzer/src/models/source_file.dart';

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

bool shouldExclude(String filePath, List<String>? excludePatterns) {
  final patterns = excludePatterns ?? kDefaultExcludePatterns;
  final normalizedPath = filePath.replaceAll('\\', '/');

  for (final pattern in patterns) {
    if (_matchPattern(normalizedPath, pattern)) {
      return true;
    }
  }

  return false;
}

bool _matchPattern(String filePath, String pattern) {
  var p = pattern.replaceAll('\\', '/');

  p = p.replaceAllMapped(RegExp(r'[.+^${}()|[\]\\]'), (match) {
    return '\\${match.group(0)}';
  });

  p = p.replaceAll('**/', '__DOUBLESTAR__/');
  p = p.replaceAll('**', '__DOUBLESTAR__');
  p = p.replaceAll('*', '[^/]*');
  p = p.replaceAll('?', '[^/]');
  p = p.replaceAll('__DOUBLESTAR__/', '(.*/)?');
  p = p.replaceAll('__DOUBLESTAR__', '.*');

  final regexPattern = '^$p\$';

  try {
    final regex = RegExp(regexPattern);
    if (regex.hasMatch(filePath)) return true;
    if (regex.hasMatch('/$filePath')) return true;

    if (!pattern.contains('/')) {
      final parts = filePath.split('/');
      for (final part in parts) {
        if (RegExp('^${p.replaceAll('/', '')}\$').hasMatch(part)) {
          return true;
        }
      }
    }

    if (pattern.endsWith('/**')) {
      final dirPattern = p.replaceAll(RegExp(r'/\(\.\*/\)\?$'), '');
      if (RegExp('^$dirPattern(/|\$)').hasMatch(filePath)) {
        return true;
      }
    }

    return false;
  } catch (e) {
    return false;
  }
}

bool isBinaryFile(String filePath) {
  final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
  return kBinaryExtensions.contains(extension);
}

bool isConfigurationFile(String filePath) {
  final normalizedPath = filePath.replaceAll('\\', '/');
  for (final pattern in kConfigurationPatterns) {
    if (_matchSimplePattern(normalizedPath, pattern)) {
      return true;
    }
  }
  return false;
}

bool isDocumentationFile(String filePath) {
  final normalizedPath = filePath.replaceAll('\\', '/');
  for (final pattern in kDocumentationPatterns) {
    if (_matchSimplePattern(normalizedPath, pattern)) {
      return true;
    }
  }
  return false;
}

bool _matchSimplePattern(String filePath, String pattern) {
  final regexPattern = pattern
      .replaceAll('.', r'\.')
      .replaceAll('**', r'.*')
      .replaceAll('*', r'[^/]*');

  try {
    return RegExp('^$regexPattern\$').hasMatch(filePath);
  } catch (e) {
    return false;
  }
}

List<String> identifyMainFiles(List<SourceFile> files) {
  final mainFiles = <String>[];
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
