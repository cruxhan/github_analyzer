import 'dart:io';
import 'dart:convert';
import 'package:github_analyzer/src/models/analysis_result.dart';

class MetadataGenerator {
  static Future<void> generate(AnalysisResult result, String outputPath) async {
    final metadata = {
      'repository': {
        'name': result.metadata.name,
        'full_name': result.metadata.fullName,
        'description': result.metadata.description,
        'is_private': result.metadata.isPrivate,
        'default_branch': result.metadata.defaultBranch,
        'language': result.metadata.language,
        'languages': result.metadata.languages,
        'stars': result.metadata.stars,
        'forks': result.metadata.forks,
      },
      'statistics': {
        'total_files': result.statistics.totalFiles,
        'total_lines': result.statistics.totalLines,
        'total_size': result.statistics.totalSize,
        'binary_files': result.statistics.binaryFiles,
        'source_files': result.statistics.sourceFiles,
        'config_files': result.statistics.configFiles,
        'documentation_files': result.statistics.documentationFiles,
        'language_distribution': result.statistics.languageDistribution,
      },
      'main_files': result.mainFiles,
      'dependencies': result.dependencies,
      'errors': result.errors.map((e) => e.toJson()).toList(),
      'generated_at': DateTime.now().toIso8601String(),
    };

    final file = File(outputPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
  }

  static Map<String, dynamic> generateMap(AnalysisResult result) {
    return {
      'repository': {
        'name': result.metadata.name,
        'full_name': result.metadata.fullName,
        'description': result.metadata.description,
        'is_private': result.metadata.isPrivate,
        'default_branch': result.metadata.defaultBranch,
        'language': result.metadata.language,
        'languages': result.metadata.languages,
        'stars': result.metadata.stars,
        'forks': result.metadata.forks,
      },
      'statistics': {
        'total_files': result.statistics.totalFiles,
        'total_lines': result.statistics.totalLines,
        'total_size': result.statistics.totalSize,
        'binary_files': result.statistics.binaryFiles,
        'source_files': result.statistics.sourceFiles,
        'config_files': result.statistics.configFiles,
        'documentation_files': result.statistics.documentationFiles,
        'language_distribution': result.statistics.languageDistribution,
      },
      'main_files': result.mainFiles,
      'dependencies': result.dependencies,
      'errors': result.errors.map((e) => e.toJson()).toList(),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}
