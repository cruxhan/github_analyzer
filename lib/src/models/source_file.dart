/// Represents a single source file in the repository.
class SourceFile {
  final String path;
  final String? content;
  final int size;
  final String? language;
  final bool isBinary;
  final int lineCount;
  final bool isSourceCode;
  final bool isConfiguration;
  final bool isDocumentation;
  final DateTime timestamp; // Added for incremental analysis

  /// Creates a const instance of [SourceFile].
  const SourceFile({
    required this.path,
    this.content,
    required this.size,
    this.language,
    required this.isBinary,
    required this.lineCount,
    required this.isSourceCode,
    required this.isConfiguration,
    required this.isDocumentation,
    required this.timestamp,
  });

  /// Creates a copy of this source file but with the given fields replaced.
  SourceFile copyWith({
    String? path,
    String? content,
    int? size,
    String? language,
    bool? isBinary,
    int? lineCount,
    bool? isSourceCode,
    bool? isConfiguration,
    bool? isDocumentation,
    DateTime? timestamp,
  }) {
    return SourceFile(
      path: path ?? this.path,
      content: content ?? this.content,
      size: size ?? this.size,
      language: language ?? this.language,
      isBinary: isBinary ?? this.isBinary,
      lineCount: lineCount ?? this.lineCount,
      isSourceCode: isSourceCode ?? this.isSourceCode,
      isConfiguration: isConfiguration ?? this.isConfiguration,
      isDocumentation: isDocumentation ?? this.isDocumentation,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'content': content,
      'size': size,
      'language': language,
      'is_binary': isBinary,
      'line_count': lineCount,
      'is_source_code': isSourceCode,
      'is_configuration': isConfiguration,
      'is_documentation': isDocumentation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates an instance of [SourceFile] from a JSON map.
  factory SourceFile.fromJson(Map<String, dynamic> json) {
    return SourceFile(
      path: json['path'] as String,
      content: json['content'] as String?,
      size: json['size'] as int? ?? 0,
      language: json['language'] as String?,
      isBinary: json['is_binary'] as bool? ?? false,
      lineCount: json['line_count'] as int? ?? 0,
      isSourceCode: json['is_source_code'] as bool? ?? false,
      isConfiguration: json['is_configuration'] as bool? ?? false,
      isDocumentation: json['is_documentation'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  String toString() {
    return 'SourceFile(path: $path, size: $size, language: $language, lines: $lineCount)';
  }
}
