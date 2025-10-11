import 'dart:io';
import 'package:github_analyzer/src/models/analysis_result.dart';

class ContextGenerator {
  static Future<void> generate(AnalysisResult result, String outputPath) async {
    final buffer = StringBuffer();

    buffer.writeln('# Repository Context: ${result.metadata.name}');
    buffer.writeln();
    buffer.writeln('## Overview');
    buffer.writeln(
      'Description: ${result.metadata.description ?? 'No description'}',
    );
    buffer.writeln(
      'Primary Language: ${result.metadata.language ?? 'Unknown'}',
    );
    buffer.writeln('Stars: ${result.metadata.stars}');
    buffer.writeln('Forks: ${result.metadata.forks}');
    buffer.writeln();

    buffer.writeln('## Statistics');
    buffer.writeln('- Total Files: ${result.statistics.totalFiles}');
    buffer.writeln('- Total Lines: ${result.statistics.totalLines}');
    buffer.writeln('- Source Files: ${result.statistics.sourceFiles}');
    buffer.writeln('- Configuration Files: ${result.statistics.configFiles}');
    buffer.writeln(
      '- Documentation Files: ${result.statistics.documentationFiles}',
    );
    buffer.writeln();

    buffer.writeln('## Language Distribution');
    final sorted = result.statistics.languageDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      final percentage = (entry.value / result.statistics.totalFiles * 100)
          .toStringAsFixed(1);
      buffer.writeln('- ${entry.key}: ${entry.value} files ($percentage%)');
    }
    buffer.writeln();

    if (result.mainFiles.isNotEmpty) {
      buffer.writeln('## Main Entry Points');
      for (final file in result.mainFiles) {
        buffer.writeln('- $file');
      }
      buffer.writeln();
    }

    if (result.dependencies.isNotEmpty) {
      buffer.writeln('## Dependencies');
      for (final entry in result.dependencies.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.join(', ')}');
      }
      buffer.writeln();
    }

    if (result.errors.isNotEmpty) {
      buffer.writeln('## Analysis Errors (${result.errors.length})');
      for (final error in result.errors) {
        buffer.writeln('- ${error.path}: ${error.message}');
      }
      buffer.writeln();
    }

    buffer.writeln('## Source Code');
    buffer.writeln();

    final sourceFiles = result.files
        .where((f) => f.isSourceCode && f.content != null)
        .toList();

    for (final file in sourceFiles) {
      buffer.writeln('### ${file.path}');
      buffer.writeln();
      buffer.writeln('```');
      buffer.writeln(file.content);
      buffer.writeln('```');
      buffer.writeln();
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsString(buffer.toString());
  }

  static String generateString(AnalysisResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Repository Context: ${result.metadata.name}');
    buffer.writeln();
    buffer.writeln('## Overview');
    buffer.writeln(
      'Description: ${result.metadata.description ?? 'No description'}',
    );
    buffer.writeln(
      'Primary Language: ${result.metadata.language ?? 'Unknown'}',
    );
    buffer.writeln('Stars: ${result.metadata.stars}');
    buffer.writeln('Forks: ${result.metadata.forks}');
    buffer.writeln();

    buffer.writeln('## Statistics');
    buffer.writeln('- Total Files: ${result.statistics.totalFiles}');
    buffer.writeln('- Total Lines: ${result.statistics.totalLines}');
    buffer.writeln('- Source Files: ${result.statistics.sourceFiles}');
    buffer.writeln('- Configuration Files: ${result.statistics.configFiles}');
    buffer.writeln(
      '- Documentation Files: ${result.statistics.documentationFiles}',
    );
    buffer.writeln();

    buffer.writeln('## Language Distribution');
    final sorted = result.statistics.languageDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      final percentage = (entry.value / result.statistics.totalFiles * 100)
          .toStringAsFixed(1);
      buffer.writeln('- ${entry.key}: ${entry.value} files ($percentage%)');
    }
    buffer.writeln();

    if (result.mainFiles.isNotEmpty) {
      buffer.writeln('## Main Entry Points');
      for (final file in result.mainFiles) {
        buffer.writeln('- $file');
      }
      buffer.writeln();
    }

    if (result.dependencies.isNotEmpty) {
      buffer.writeln('## Dependencies');
      for (final entry in result.dependencies.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.join(', ')}');
      }
      buffer.writeln();
    }

    if (result.errors.isNotEmpty) {
      buffer.writeln('## Analysis Errors (${result.errors.length})');
      for (final error in result.errors) {
        buffer.writeln('- ${error.path}: ${error.message}');
      }
      buffer.writeln();
    }

    buffer.writeln('## Source Code');
    buffer.writeln();

    final sourceFiles = result.files
        .where((f) => f.isSourceCode && f.content != null)
        .toList();

    for (final file in sourceFiles) {
      buffer.writeln('### ${file.path}');
      buffer.writeln();
      buffer.writeln('```');
      buffer.writeln(file.content);
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
