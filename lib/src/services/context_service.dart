import 'package:path/path.dart' as path;
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/services/markdown_service.dart';
import 'package:github_analyzer/src/infrastructure/file_system/file_system.dart';

/// Service for generating context output files from analysis results
/// 
/// This service handles the business logic of creating and managing
/// context files, using platform-independent file system operations.
class ContextService {
  final IFileSystem _fs = getFileSystem();

  /// Generates a markdown file from the analysis result with automatic naming
  /// 
  /// Parameters:
  /// - [result]: The analysis result to generate context from
  /// - [outputPath]: Optional specific output file path
  /// - [outputDir]: Optional output directory (defaults to current directory)
  /// - [config]: Markdown generation configuration
  /// 
  /// Returns the path to the generated file
  Future<String> generate(
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

    final markdownService = MarkdownService();
    await markdownService.generateToFile(result, filePath, config: config);
    return filePath;
  }

  /// Generates a markdown string from the analysis result
  /// 
  /// Parameters:
  /// - [result]: The analysis result to generate context from
  /// - [config]: Markdown generation configuration
  /// 
  /// Returns the generated markdown as a string
  String generateString(
    AnalysisResult result, {
    MarkdownConfig config = MarkdownConfig.standard,
  }) {
    final markdownService = MarkdownService();
    return markdownService.generate(result, config: config);
  }

  /// Resolves the output path with smart defaults
  String _resolveOutputPath(
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
  String _generateFileName(AnalysisResult result) {
    var name = result.metadata.name;
    // Clean the name for file system
    name = name.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    name = name.replaceAll(RegExp(r'_+'), '_');
    return '${name}_analysis.md';
  }

  /// Ensures the file has .md extension
  String _ensureMarkdownExtension(String filePath) {
    if (!filePath.endsWith('.md')) {
      return '$filePath.md';
    }
    return filePath;
  }
}
