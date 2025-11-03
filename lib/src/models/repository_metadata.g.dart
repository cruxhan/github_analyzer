// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RepositoryMetadata _$RepositoryMetadataFromJson(Map<String, dynamic> json) =>
    _RepositoryMetadata(
      name: json['name'] as String,
      fullName: json['fullName'] as String?,
      description: json['description'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      defaultBranch: json['defaultBranch'] as String?,
      language: json['language'] as String?,
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      forks: (json['forks'] as num?)?.toInt() ?? 0,
      fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
      commitSha: json['commitSha'] as String?,
      directoryTree: json['directoryTree'] as String? ?? '',
    );

Map<String, dynamic> _$RepositoryMetadataToJson(_RepositoryMetadata instance) =>
    <String, dynamic>{
      'name': instance.name,
      'fullName': instance.fullName,
      'description': instance.description,
      'isPrivate': instance.isPrivate,
      'defaultBranch': instance.defaultBranch,
      'language': instance.language,
      'languages': instance.languages,
      'stars': instance.stars,
      'forks': instance.forks,
      'fileCount': instance.fileCount,
      'commitSha': instance.commitSha,
      'directoryTree': instance.directoryTree,
    };
