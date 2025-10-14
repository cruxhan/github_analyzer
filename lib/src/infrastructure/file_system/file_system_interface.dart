/// Abstract file system interface to enable platform-independent file operations
abstract class IFileSystem {
  /// Check if a directory exists
  Future<bool> directoryExists(String path);

  /// Create a directory (recursive)
  Future<void> createDirectory(String path);

  /// Write a string to a file (overwrites if exists)
  Future<void> writeFile(String path, String contents);

  /// Read a string from a file
  Future<String> readFile(String path);

  /// Check if the file exists
  Future<bool> fileExists(String path);

  /// List all files in a directory recursively
  Future<List<String>> listFilesRecursively(String directory);

  /// Delete a file or directory recursively
  Future<void> delete(String path);
}
