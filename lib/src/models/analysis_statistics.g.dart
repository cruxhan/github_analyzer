// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalysisStatistics _$AnalysisStatisticsFromJson(Map<String, dynamic> json) =>
    _AnalysisStatistics(
      totalFiles: (json['totalFiles'] as num?)?.toInt() ?? 0,
      totalLines: (json['totalLines'] as num?)?.toInt() ?? 0,
      totalSize: (json['totalSize'] as num?)?.toInt() ?? 0,
      languageDistribution:
          (json['languageDistribution'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      binaryFiles: (json['binaryFiles'] as num?)?.toInt() ?? 0,
      sourceFiles: (json['sourceFiles'] as num?)?.toInt() ?? 0,
      configFiles: (json['configFiles'] as num?)?.toInt() ?? 0,
      documentationFiles: (json['documentationFiles'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AnalysisStatisticsToJson(_AnalysisStatistics instance) =>
    <String, dynamic>{
      'totalFiles': instance.totalFiles,
      'totalLines': instance.totalLines,
      'totalSize': instance.totalSize,
      'languageDistribution': instance.languageDistribution,
      'binaryFiles': instance.binaryFiles,
      'sourceFiles': instance.sourceFiles,
      'configFiles': instance.configFiles,
      'documentationFiles': instance.documentationFiles,
    };
