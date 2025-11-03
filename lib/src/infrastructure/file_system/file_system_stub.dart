import 'file_system_interface.dart';

/// Stub implementation for unsupported platforms (fallback)
class StubFileSystem implements IFileSystem {
  @override
  Future<void> createDirectory(String path) {
    throw UnsupportedError('File system is not supported on this platform');
  }

  @override
  Future<void> delete(String path) {
    throw UnsupportedError('File system is not supported on this platform');
  }

  @override
  Future<String> readFile(String path) {
    throw UnsupportedError('File system is not supported on this platform');
  }

  @override
  Future<List<String>> listFilesRecursively(String directory) {
    throw UnsupportedError('File system is not supported on this platform');
  }

  @override
  Future<bool> directoryExists(String path) {
    throw UnsupportedError('File system is not supported on this platform');
  }

  @override
  Future<bool> fileExists(String path) {
    throw UnsupportedError('File system is not supported on this platform');
  }

  @override
  Future<void> writeFile(String path, String contents) {
    throw UnsupportedError('File system is not supported on this platform');
  }
}

/// Factory function for Stub platform
IFileSystem createPlatformFileSystem() => StubFileSystem();
