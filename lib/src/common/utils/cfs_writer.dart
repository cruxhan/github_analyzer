import 'dart:io';
import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/common/utils/file_utils.dart';

/// A writer for the Compact File Set (CFS) format.
/// This format is designed for efficient processing by AI models.
class CfsWriter {
  /// Writes the analysis result to a file in CFS format.
  static Future<void> write(AnalysisResult result, String outputPath) async {
    final buffer = StringBuffer();

    // Write metadata section
    _writeMetadata(buffer, result);

    // Write statistics section
    _writeStatistics(buffer, result);

    // Write file content section
    _writeFiles(buffer, result);

    // Write errors section if any
    if (result.errors.isNotEmpty) {
      _writeErrors(buffer, result);
    }

    final file = File(outputPath);
    await file.writeAsString(buffer.toString());
  }

  /// Writes the repository metadata to the buffer.
  static void _writeMetadata(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln('[CFS_METADATA]');
    buffer.writeln('repo_name: ${result.metadata.name}');
    buffer.writeln(
      'description: ${_escapeValue(result.metadata.description ?? '')}',
    );
    buffer.writeln('language: ${result.metadata.language ?? 'Unknown'}');
    buffer.writeln('stars: ${result.metadata.stars}');
    buffer.writeln('forks: ${result.metadata.forks}');
    buffer.writeln();
  }

  /// Writes the analysis statistics to the buffer.
  static void _writeStatistics(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln('[CFS_STATISTICS]');
    buffer.writeln('total_files: ${result.statistics.totalFiles}');
    buffer.writeln('total_lines: ${result.statistics.totalLines}');
    buffer.writeln(
      'total_size: ${formatFileSize(result.statistics.totalSize)}',
    );
    buffer.writeln('source_files: ${result.statistics.sourceFiles}');
    buffer.writeln('config_files: ${result.statistics.configFiles}');
    buffer.writeln(
      'documentation_files: ${result.statistics.documentationFiles}',
    );

    // Write language distribution
    final sortedLanguages =
        result.statistics.languageDistribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedLanguages) {
      final percentage = (entry.value / result.statistics.totalFiles * 100)
          .toStringAsFixed(1);
      buffer.writeln('lang_${entry.key}: ${entry.value} ($percentage%)');
    }
    buffer.writeln();
  }

  /// Writes the source files to the buffer.
  static void _writeFiles(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln('[CFS_FILES]');
    for (final file in result.files) {
      // Skip binary files or files without content
      if (file.isBinary || file.content == null || file.content!.isEmpty) {
        continue;
      }
      buffer.writeln('--- file: ${file.path}');
      buffer.writeln(file.content);
    }
    buffer.writeln();
  }

  /// Writes any analysis errors to the buffer.
  static void _writeErrors(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln('[CFS_ERRORS]');
    for (final error in result.errors) {
      buffer.writeln(
        '${error.timestamp.toIso8601String()} | ${error.path} | ${_escapeValue(error.message)}',
      );
    }
    buffer.writeln();
  }

  /// Escapes values that might contain newlines.
  static String _escapeValue(String value) {
    return value.replaceAll('\n', '\\n').replaceAll('\r', '');
  }
}
