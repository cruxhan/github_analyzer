import 'package:freezed_annotation/freezed_annotation.dart';

part 'repository_metadata.freezed.dart';
part 'repository_metadata.g.dart';

/// Represents metadata about a GitHub repository.
@freezed
abstract class RepositoryMetadata with _$RepositoryMetadata {
  const RepositoryMetadata._(); // Private constructor for custom methods

  const factory RepositoryMetadata({
    required String name,
    String? fullName,
    String? description,
    @Default(false) bool isPrivate,
    String? defaultBranch,
    String? language,
    @Default([]) List<String> languages,
    @Default(0) int stars,
    @Default(0) int forks,
    @Default(0) int fileCount,
    String? commitSha,
    @Default('') String directoryTree,
  }) = _RepositoryMetadata;

  /// Custom toString with concise repository information
  @override
  String toString() {
    return 'RepositoryMetadata(name: $name, language: $language, stars: $stars, files: $fileCount)';
  }

  /// Creates an instance of [RepositoryMetadata] from a JSON map.
  factory RepositoryMetadata.fromJson(Map<String, dynamic> json) =>
      _$RepositoryMetadataFromJson(json);
}
