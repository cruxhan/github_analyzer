/// Represents metadata about a GitHub repository.
class RepositoryMetadata {
  final String name;
  final String? fullName;
  final String? description;
  final bool isPrivate;
  final String? defaultBranch;
  final String? language;
  final List<String> languages;
  final int stars;
  final int forks;
  final int fileCount;
  final String? commitSha;
  final String directoryTree;

  /// Creates a const instance of [RepositoryMetadata].
  const RepositoryMetadata({
    required this.name,
    this.fullName,
    this.description,
    required this.isPrivate,
    this.defaultBranch,
    this.language,
    required this.languages,
    required this.stars,
    required this.forks,
    required this.fileCount,
    this.commitSha,
    required this.directoryTree,
  });

  /// Creates a copy of this metadata object but with the given fields replaced.
  RepositoryMetadata copyWith({
    String? name,
    String? fullName,
    String? description,
    bool? isPrivate,
    String? defaultBranch,
    String? language,
    List<String>? languages,
    int? stars,
    int? forks,
    int? fileCount,
    String? commitSha,
    String? directoryTree,
  }) {
    return RepositoryMetadata(
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      isPrivate: isPrivate ?? this.isPrivate,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      language: language ?? this.language,
      languages: languages ?? this.languages,
      stars: stars ?? this.stars,
      forks: forks ?? this.forks,
      fileCount: fileCount ?? this.fileCount,
      commitSha: commitSha ?? this.commitSha,
      directoryTree: directoryTree ?? this.directoryTree,
    );
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'full_name': fullName,
      'description': description,
      'is_private': isPrivate,
      'default_branch': defaultBranch,
      'language': language,
      'languages': languages,
      'stars': stars,
      'forks': forks,
      'file_count': fileCount,
      'commit_sha': commitSha,
      'directory_tree': directoryTree,
    };
  }

  /// Creates an instance of [RepositoryMetadata] from a JSON map.
  factory RepositoryMetadata.fromJson(Map<String, dynamic> json) {
    return RepositoryMetadata(
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String?,
      description: json['description'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      defaultBranch: json['default_branch'] as String?,
      language: json['language'] as String?,
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stars: json['stars'] as int? ?? 0,
      forks: json['forks'] as int? ?? 0,
      fileCount: json['file_count'] as int? ?? 0,
      commitSha: json['commit_sha'] as String?,
      directoryTree: json['directory_tree'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'RepositoryMetadata(name: $name, language: $language, stars: $stars, files: $fileCount)';
  }
}
