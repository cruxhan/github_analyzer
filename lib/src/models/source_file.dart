import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_file.freezed.dart';
part 'source_file.g.dart';

/// Represents a single source file in the repository.
@freezed
abstract class SourceFile with _$SourceFile {
  const SourceFile._(); // Private constructor for custom methods

  const factory SourceFile({
    required String path,
    String? content,
    required int size,
    String? language,
    required bool isBinary,
    required int lineCount,
    required bool isSourceCode,
    required bool isConfiguration,
    required bool isDocumentation,
    required DateTime timestamp,
  }) = _SourceFile;

  /// Custom toString with concise file information
  @override
  String toString() {
    return 'SourceFile(path: $path, size: $size, language: $language, lines: $lineCount)';
  }

  /// Creates an instance of [SourceFile] from a JSON map.
  factory SourceFile.fromJson(Map<String, dynamic> json) =>
      _$SourceFileFromJson(json);
}
