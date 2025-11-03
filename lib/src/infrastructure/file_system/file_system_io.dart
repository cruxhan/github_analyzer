import 'package:universal_io/io.dart';
import 'file_system_interface.dart';

/// Implementation of IFileSystem using universal_io for native platforms
class IOFileSystem implements IFileSystem {
  @override
  Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  @override
  Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<void> writeFile(String path, String contents) async {
    final file = File(path);
    await file.writeAsString(contents, flush: true);
  }

  @override
  Future<String> readFile(String path) async {
    final file = File(path);
    return file.readAsString();
  }

  @override
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  @override
  Future<List<String>> listFilesRecursively(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    final List<String> files = [];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity.path);
      }
    }
    return files;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    final dir = Directory(path);

    if (await file.exists()) {
      await file.delete(recursive: true);
    } else if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// Factory function for IO platform
IFileSystem createPlatformFileSystem() => IOFileSystem();
