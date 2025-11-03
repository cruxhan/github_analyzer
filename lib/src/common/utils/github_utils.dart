Map<String, String>? parseGitHubUrl(String url) {
  final patterns = [
    RegExp(r'https?://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$'),
    RegExp(r'git@github\.com:([^/]+)/([^/]+?)(?:\.git)?$'),
    RegExp(r'([^/]+)/([^/]+)$'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(url);
    if (match != null) {
      return {
        'owner': match.group(1)!,
        'repo': match.group(2)!.replaceAll('.git', ''),
      };
    }
  }

  return null;
}

String normalizeGitHubUrl(String url) {
  final parsed = parseGitHubUrl(url);
  if (parsed == null) {
    throw ArgumentError('Invalid GitHub URL: $url');
  }
  return 'https://github.com/${parsed['owner']}/${parsed['repo']}';
}

bool isValidGitHubUrl(String url) {
  return parseGitHubUrl(url) != null;
}
