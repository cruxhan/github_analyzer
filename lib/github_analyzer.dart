library;

// Public API Exports
export 'src/github_analyzer.dart';

// Configuration and Logging
export 'src/common/config.dart';
export 'src/common/logger.dart';
export 'src/common/errors/analyzer_exception.dart';

// Domain Models
export 'src/models/analysis_result.dart';
export 'src/models/analysis_progress.dart';
export 'src/models/analysis_error.dart';
export 'src/models/analysis_statistics.dart';
export 'src/models/repository_metadata.dart';
export 'src/models/source_file.dart';

// Utilities
export 'src/common/utils/metadata_generator.dart';
export 'src/common/utils/cfs_writer.dart';
export 'src/common/utils/context_generator.dart';
