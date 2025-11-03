// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SourceFile _$SourceFileFromJson(Map<String, dynamic> json) => _SourceFile(
  path: json['path'] as String,
  content: json['content'] as String?,
  size: (json['size'] as num).toInt(),
  language: json['language'] as String?,
  isBinary: json['isBinary'] as bool,
  lineCount: (json['lineCount'] as num).toInt(),
  isSourceCode: json['isSourceCode'] as bool,
  isConfiguration: json['isConfiguration'] as bool,
  isDocumentation: json['isDocumentation'] as bool,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$SourceFileToJson(_SourceFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'content': instance.content,
      'size': instance.size,
      'language': instance.language,
      'isBinary': instance.isBinary,
      'lineCount': instance.lineCount,
      'isSourceCode': instance.isSourceCode,
      'isConfiguration': instance.isConfiguration,
      'isDocumentation': instance.isDocumentation,
      'timestamp': instance.timestamp.toIso8601String(),
    };
