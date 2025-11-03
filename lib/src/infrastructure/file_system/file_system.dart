export 'file_system_interface.dart';

// Conditional import for platform-specific factory
import 'file_system_interface.dart';
import 'file_system_stub.dart'
    if (dart.library.io) 'file_system_io.dart'
    if (dart.library.html) 'file_system_web.dart';

/// Get platform-specific file system instance
IFileSystem getFileSystem() => createPlatformFileSystem();
