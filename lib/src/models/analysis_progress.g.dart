// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalysisProgress _$AnalysisProgressFromJson(Map<String, dynamic> json) =>
    _AnalysisProgress(
      phase: $enumDecode(_$AnalysisPhaseEnumMap, json['phase']),
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String?,
      currentFile: json['currentFile'] as String?,
      processedFiles: (json['processedFiles'] as num?)?.toInt(),
      totalFiles: (json['totalFiles'] as num?)?.toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$AnalysisProgressToJson(_AnalysisProgress instance) =>
    <String, dynamic>{
      'phase': _$AnalysisPhaseEnumMap[instance.phase]!,
      'progress': instance.progress,
      'message': instance.message,
      'currentFile': instance.currentFile,
      'processedFiles': instance.processedFiles,
      'totalFiles': instance.totalFiles,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$AnalysisPhaseEnumMap = {
  AnalysisPhase.initializing: 'initializing',
  AnalysisPhase.downloading: 'downloading',
  AnalysisPhase.extracting: 'extracting',
  AnalysisPhase.analyzing: 'analyzing',
  AnalysisPhase.processing: 'processing',
  AnalysisPhase.generating: 'generating',
  AnalysisPhase.caching: 'caching',
  AnalysisPhase.completed: 'completed',
  AnalysisPhase.error: 'error',
};
