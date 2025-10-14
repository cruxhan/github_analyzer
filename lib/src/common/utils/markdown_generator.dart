import 'package:github_analyzer/src/models/analysis_result.dart';
import 'package:github_analyzer/src/infrastructure/file_system/file_system.dart';

/// Configuration for markdown generation
class MarkdownConfig {
  final int? maxFiles;
  final int? maxContentSize;
  final bool includeBinaryStats;
  final bool includeErrors;
  final int? minPriority;

  const MarkdownConfig({
    this.maxFiles,
    this.maxContentSize,
    this.includeBinaryStats = true,
    this.includeErrors = true,
    this.minPriority,
  });

  static const standard = MarkdownConfig();

  static const compact = MarkdownConfig(
    maxFiles: 50,
    maxContentSize: 50000,
    includeBinaryStats: false,
  );
}

/// Generates markdown formatted output from analysis results
class MarkdownGenerator {
  static final IFileSystem _fs = getFileSystem();

  /// Generates and writes markdown directly to a file asynchronously
  static Future<void> generateToFile(
    AnalysisResult result,
    String outputPath, {
    MarkdownConfig config = MarkdownConfig.standard,
  }) async {
    final buffer = StringBuffer();

    _writeHeaderSync(buffer, result);
    _writeMetadataSync(buffer, result);
    _writeStatisticsSync(buffer, result, config);
    _writeDirectoryTreeSync(buffer, result);
    _writeLanguageDistributionSync(buffer, result);
    _writeMainFilesSync(buffer, result);
    _writeDependenciesSync(buffer, result);

    if (config.includeErrors) {
      _writeErrorsSync(buffer, result);
    }

    _writeSourceCodeSync(buffer, result, config);

    await _fs.writeFile(outputPath, buffer.toString());
  }

  /// Generates markdown string synchronously
  static String generate(
    AnalysisResult result, {
    MarkdownConfig config = MarkdownConfig.standard,
  }) {
    final buffer = StringBuffer();

    _writeHeaderSync(buffer, result);
    _writeMetadataSync(buffer, result);
    _writeStatisticsSync(buffer, result, config);
    _writeDirectoryTreeSync(buffer, result);
    _writeLanguageDistributionSync(buffer, result);
    _writeMainFilesSync(buffer, result);
    _writeDependenciesSync(buffer, result);

    if (config.includeErrors) {
      _writeErrorsSync(buffer, result);
    }

    _writeSourceCodeSync(buffer, result, config);

    return buffer.toString();
  }

  // Synchronous helpers for building markdown content

  static void _writeHeaderSync(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln('# ${result.metadata.name}');
    buffer.writeln();

    if (result.metadata.description != null &&
        result.metadata.description!.isNotEmpty) {
      buffer.writeln(result.metadata.description);
      buffer.writeln();
    }
  }

  static void _writeMetadataSync(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln('## Repository Information');
    buffer.writeln();

    final meta = result.metadata;
    if (meta.fullName != null) {
      buffer.writeln('**Repository:** `${meta.fullName}`');
    }

    final info = <String>[];
    if (meta.language != null) info.add('**Language:** ${meta.language}');
    if (meta.stars > 0) info.add('**Stars:** ${meta.stars}');
    if (meta.forks > 0) info.add('**Forks:** ${meta.forks}');

    if (info.isNotEmpty) {
      buffer.writeln(info.join(' | '));
    }

    buffer.writeln();
  }

  static void _writeStatisticsSync(
    StringBuffer buffer,
    AnalysisResult result,
    MarkdownConfig config,
  ) {
    buffer.writeln('## Statistics');
    buffer.writeln();

    final stats = result.statistics;
    buffer.writeln('- **Total Files:** ${stats.totalFiles}');
    buffer.writeln('- **Total Lines:** ${stats.totalLines}');
    buffer.writeln('- **Total Size:** ${_formatBytes(stats.totalSize)}');
    buffer.writeln('- **Source Files:** ${stats.sourceFiles}');

    if (config.includeBinaryStats && stats.binaryFiles > 0) {
      buffer.writeln('- **Binary Files:** ${stats.binaryFiles}');
    }

    buffer.writeln();
  }

  static void _writeDirectoryTreeSync(
    StringBuffer buffer,
    AnalysisResult result,
  ) {
    if (result.metadata.directoryTree.isEmpty) return;

    buffer.writeln('## Directory Structure');
    buffer.writeln();
    buffer.writeln('```');
    buffer.writeln(result.metadata.directoryTree);
    buffer.writeln('```');
    buffer.writeln();
  }

  static void _writeLanguageDistributionSync(
    StringBuffer buffer,
    AnalysisResult result,
  ) {
    if (result.statistics.languageDistribution.isEmpty) return;

    buffer.writeln('## Language Distribution');
    buffer.writeln();

    final sorted = result.statistics.languageDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted.take(10)) {
      final percentage =
          (entry.value / result.statistics.totalFiles * 100).toStringAsFixed(1);
      buffer.writeln('- **${entry.key}:** ${entry.value} files ($percentage%)');
    }

    buffer.writeln();
  }

  static void _writeMainFilesSync(StringBuffer buffer, AnalysisResult result) {
    if (result.mainFiles.isEmpty) return;

    buffer.writeln('## Main Entry Points');
    buffer.writeln();

    for (final file in result.mainFiles) {
      buffer.writeln('- `$file`');
    }

    buffer.writeln();
  }

  static void _writeDependenciesSync(
    StringBuffer buffer,
    AnalysisResult result,
  ) {
    if (result.dependencies.isEmpty) return;

    buffer.writeln('## Dependencies');
    buffer.writeln();

    for (final entry in result.dependencies.entries) {
      if (entry.value.isEmpty) continue;

      buffer.writeln('**${entry.key}:**');
      for (final dep in entry.value) {
        buffer.writeln('- $dep');
      }
      buffer.writeln();
    }
  }

  static void _writeErrorsSync(StringBuffer buffer, AnalysisResult result) {
    if (result.errors.isEmpty) return;

    buffer.writeln('## Analysis Errors');
    buffer.writeln();

    for (final error in result.errors) {
      buffer.writeln('- **${error.path}:** ${error.message}');
    }

    buffer.writeln();
  }

  static void _writeSourceCodeSync(
    StringBuffer buffer,
    AnalysisResult result,
    MarkdownConfig config,
  ) {
    buffer.writeln('## Source Code');
    buffer.writeln();

    var sourceFiles = result.files
        .where(
            (f) => f.isSourceCode && f.content != null && f.content!.isNotEmpty)
        .toList();

    if (config.minPriority != null) {
      sourceFiles = sourceFiles.where((f) {
        if (f.path.startsWith('lib/')) return true;
        if (f.path.contains('main.dart')) return true;
        return false;
      }).toList();
    }

    if (config.maxFiles != null && sourceFiles.length > config.maxFiles!) {
      sourceFiles = sourceFiles.take(config.maxFiles!).toList();
      buffer.writeln(
          '> **Note:** Showing ${config.maxFiles} of ${result.files.length} files');
      buffer.writeln();
    }

    for (final file in sourceFiles) {
      buffer.writeln('### ${file.path}');
      buffer.writeln();

      var content = file.content!;

      if (config.maxContentSize != null &&
          content.length > config.maxContentSize!) {
        content = content.substring(0, config.maxContentSize!);
        content += '\n\n// ... truncated ...';
      }

      final language = file.language ?? '';
      buffer.writeln('```$language');
      buffer.writeln(content);
      buffer.writeln('```');
      buffer.writeln();
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
