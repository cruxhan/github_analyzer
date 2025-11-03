import 'dart:async';
import 'file_system_interface.dart';

/// In-memory file system implementation for web platforms
class WebFileSystem implements IFileSystem {
  final Map<String, String> _files = {};
  final Map<String, Set<String>> _directories = {};

  @override
  Future<bool> directoryExists(String path) async {
    return _directories.containsKey(path);
  }

  @override
  Future<void> createDirectory(String path) async {
    if (!_directories.containsKey(path)) {
      _directories[path] = <String>{};
    }
  }

  @override
  Future<void> writeFile(String path, String contents) async {
    _files[path] = contents;

    final idx = path.lastIndexOf('/');
    if (idx != -1) {
      final dir = path.substring(0, idx);
      _directories.putIfAbsent(dir, () => <String>{});
      _directories[dir]!.add(path);
    }
  }

  @override
  Future<String> readFile(String path) async {
    final content = _files[path];
    if (content == null) {
      throw Exception('File not found: $path');
    }
    return content;
  }

  @override
  Future<bool> fileExists(String path) async {
    return _files.containsKey(path);
  }

  @override
  Future<List<String>> listFilesRecursively(String directory) async {
    if (!_directories.containsKey(directory)) return [];

    final result = <String>[];
    void collectFiles(String dirPath) {
      if (_directories.containsKey(dirPath)) {
        for (final filePath in _directories[dirPath]!) {
          result.add(filePath);
        }
      }
    }

    collectFiles(directory);
    return result;
  }

  @override
  Future<void> delete(String path) async {
    _files.remove(path);

    final idx = path.lastIndexOf('/');
    if (idx != -1) {
      final dir = path.substring(0, idx);
      _directories[dir]?.remove(path);
      if ((_directories[dir]?.isEmpty ?? false)) {
        _directories.remove(dir);
      }
    }
  }
}

/// Factory function for Web platform
IFileSystem createPlatformFileSystem() => WebFileSystem();
