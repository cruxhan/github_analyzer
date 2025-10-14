import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:github_analyzer/src/models/analysis_result.dart';

/// Generates metadata JSON files from analysis results
class MetadataGenerator {
  /// Generates and writes metadata to a file
  static Future<void> generate(
    AnalysisResult result,
    String outputPath,
  ) async {
    final metadata = {
      'repository': {
        'name': result.metadata.name,
        'fullname': result.metadata.fullName,
        'description': result.metadata.description,
        'isprivate': result.metadata.isPrivate,
        'defaultbranch': result.metadata.defaultBranch,
        'language': result.metadata.language,
        'languages': result.metadata.languages,
        'stars': result.metadata.stars,
        'forks': result.metadata.forks,
      },
      'statistics': {
        'totalfiles': result.statistics.totalFiles,
        'totallines': result.statistics.totalLines,
        'totalsize': result.statistics.totalSize,
        'binaryfiles': result.statistics.binaryFiles,
        'sourcefiles': result.statistics.sourceFiles,
        'configfiles': result.statistics.configFiles,
        'documentationfiles': result.statistics.documentationFiles,
        'languagedistribution': result.statistics.languageDistribution,
      },
      'mainfiles': result.mainFiles,
      'dependencies': result.dependencies,
      'errors': result.errors.map((e) => e.toJson()).toList(),
      'generatedat': DateTime.now().toIso8601String(),
    };

    final file = File(outputPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
  }

  /// Generates metadata as a Map without writing to file
  static Map<String, dynamic> generateMap(AnalysisResult result) {
    return {
      'repository': {
        'name': result.metadata.name,
        'fullname': result.metadata.fullName,
        'description': result.metadata.description,
        'isprivate': result.metadata.isPrivate,
        'defaultbranch': result.metadata.defaultBranch,
        'language': result.metadata.language,
        'languages': result.metadata.languages,
        'stars': result.metadata.stars,
        'forks': result.metadata.forks,
      },
      'statistics': {
        'totalfiles': result.statistics.totalFiles,
        'totallines': result.statistics.totalLines,
        'totalsize': result.statistics.totalSize,
        'binaryfiles': result.statistics.binaryFiles,
        'sourcefiles': result.statistics.sourceFiles,
        'configfiles': result.statistics.configFiles,
        'documentationfiles': result.statistics.documentationFiles,
        'languagedistribution': result.statistics.languageDistribution,
      },
      'mainfiles': result.mainFiles,
      'dependencies': result.dependencies,
      'errors': result.errors.map((e) => e.toJson()).toList(),
      'generatedat': DateTime.now().toIso8601String(),
    };
  }
}
