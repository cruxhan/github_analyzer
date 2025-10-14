import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/common/utils/markdown_generator.dart';
import 'package:github_analyzer/src/infrastructure/file_system/file_system.dart';

/// Generates context output files from analysis results using platform-independent file system
class ContextGenerator {
  static final IFileSystem _fs = getFileSystem();

  /// Generates a markdown file from the analysis result with automatic naming
  static Future<String> generate(
    AnalysisResult result, {
    String? outputPath,
    String? outputDir,
    MarkdownConfig config = MarkdownConfig.standard,
  }) async {
    final filePath = _resolveOutputPath(result, outputPath, outputDir);

    // Ensure output directory exists
    final dirPath = path.dirname(filePath);
    final dirExists = await _fs.directoryExists(dirPath);
    if (!dirExists) {
      await _fs.createDirectory(dirPath);
    }

    await MarkdownGenerator.generateToFile(result, filePath, config: config);

    return filePath;
  }

  /// Generates a markdown string from the analysis result
  static String generateString(
    AnalysisResult result, {
    MarkdownConfig config = MarkdownConfig.standard,
  }) {
    return MarkdownGenerator.generate(result, config: config);
  }

  /// Resolves the output path with smart defaults
  static String _resolveOutputPath(
    AnalysisResult result,
    String? outputPath,
    String? outputDir,
  ) {
    if (outputPath != null) {
      return _ensureMarkdownExtension(outputPath);
    }

    final dir = outputDir ?? '.';
    final fileName = _generateFileName(result);

    return path.join(dir, fileName);
  }

  /// Generates a clean file name from repository metadata
  static String _generateFileName(AnalysisResult result) {
    var name = result.metadata.name;

    // Clean the name for file system
    name = name.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    name = name.replaceAll(RegExp(r'_+'), '_');

    return '${name}_analysis.md';
  }

  /// Ensures the file has .md extension
  static String _ensureMarkdownExtension(String filePath) {
    if (!filePath.endsWith('.md')) {
      return '$filePath.md';
    }
    return filePath;
  }
}
