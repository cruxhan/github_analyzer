import 'package:path/path.dart' as p;

/// Generates a textual representation of a directory tree from a list of file paths.
///
/// This utility is useful for providing a high-level overview of the
/// repository structure, which can be beneficial for context in LLMs.
class DirectoryTreeGenerator {
  /// Generates a directory tree string from a list of file paths.
  ///
  /// The [paths] should be relative paths from the repository root.
  /// The [maxDepth] parameter can be used to limit the depth of the tree.
  static String generate(List<String> paths, {int? maxDepth}) {
    if (paths.isEmpty) {
      return '';
    }

    // Use a map to represent the directory structure as a tree.
    final Map<String, dynamic> tree = {};

    for (final path in paths) {
      final parts = p.split(path);
      Map<String, dynamic> currentNode = tree;
      for (final part in parts) {
        currentNode = currentNode.putIfAbsent(part, () => <String, dynamic>{});
      }
    }

    final buffer = StringBuffer();
    _buildTree(buffer, tree, '', true, maxDepth, 0);
    return buffer.toString();
  }

  static void _buildTree(
    StringBuffer buffer,
    Map<String, dynamic> node,
    String prefix,
    bool isLast,
    int? maxDepth,
    int currentDepth,
  ) {
    if (maxDepth != null && currentDepth > maxDepth) {
      return;
    }

    final sortedKeys = node.keys.toList()..sort();
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final childNode = node[key] as Map<String, dynamic>;
      final isCurrentLast = i == sortedKeys.length - 1;

      buffer.write(prefix);
      buffer.write(isCurrentLast ? '└── ' : '├── ');
      buffer.writeln(key);

      final newPrefix = prefix + (isCurrentLast ? '    ' : '│   ');
      if (childNode.isNotEmpty) {
        _buildTree(
          buffer,
          childNode,
          newPrefix,
          isCurrentLast,
          maxDepth,
          currentDepth + 1,
        );
      }
    }
  }
}
