// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalysisError _$AnalysisErrorFromJson(Map<String, dynamic> json) =>
    _AnalysisError(
      path: json['path'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stackTrace: json['stackTrace'] as String?,
    );

Map<String, dynamic> _$AnalysisErrorToJson(_AnalysisError instance) =>
    <String, dynamic>{
      'path': instance.path,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'stackTrace': instance.stackTrace,
    };
