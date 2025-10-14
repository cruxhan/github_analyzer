/// Pattern matching utility to replace glob package for web compatibility
class PatternMatcher {
  /// Check if a path matches any of the given patterns
  static bool matchesAny(String path, List<String> patterns) {
    for (final pattern in patterns) {
      if (matches(path, pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a path matches a single pattern
  static bool matches(String path, String pattern) {
    final regexPattern = _convertGlobToRegex(pattern);
    return regexPattern.hasMatch(path);
  }

  /// Convert glob pattern to RegExp
  static RegExp _convertGlobToRegex(String pattern) {
    var regexStr = pattern;

    // Escape special regex characters except glob wildcards
    regexStr = regexStr.replaceAllMapped(
      RegExp(r'[.+^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );

    // Convert glob wildcards to regex
    regexStr = regexStr.replaceAll('**/', '(?:.*/)');
    regexStr = regexStr.replaceAll('**', '.*');
    regexStr = regexStr.replaceAll('*', '[^/]*');
    regexStr = regexStr.replaceAll('?', '[^/]');

    // Anchor the pattern
    regexStr = '^$regexStr\$';

    return RegExp(regexStr);
  }

  /// Check if a path should be excluded based on patterns
  static bool shouldExclude(String path, List<String> excludePatterns) {
    return matchesAny(path, excludePatterns);
  }

  /// Check if a path should be included based on patterns
  static bool shouldInclude(String path, List<String> includePatterns) {
    if (includePatterns.isEmpty) return true;
    return matchesAny(path, includePatterns);
  }

  /// Filter a list of paths based on include/exclude patterns
  static List<String> filterPaths(
    List<String> paths,
    List<String> includePatterns,
    List<String> excludePatterns,
  ) {
    return paths.where((path) {
      if (shouldExclude(path, excludePatterns)) return false;
      return shouldInclude(path, includePatterns);
    }).toList();
  }
}
