/// Utility class for safely logging sensitive data
class SensitiveLogger {
  /// Masks a GitHub token by showing only first and last 4 characters
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return 'null';
    if (token.length <= 8) return '****';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  /// Masks a URL by removing sensitive query parameters
  static String maskUrl(String? url) {
    if (url == null || url.isEmpty) return 'null';
    try {
      final uri = Uri.parse(url);
      // Remove token from query parameters
      final filteredParams = Map<String, String>.from(uri.queryParameters)
        ..remove('token')
        ..remove('access_token')
        ..remove('api_key');

      return uri
          .replace(
            queryParameters: filteredParams.isEmpty ? null : filteredParams,
          )
          .toString();
    } catch (_) {
      return url;
    }
  }

  /// Masks authorization headers
  static Map<String, dynamic> maskHeaders(Map<String, dynamic> headers) {
    final masked = Map<String, dynamic>.from(headers);
    if (masked.containsKey('Authorization')) {
      final auth = masked['Authorization'] as String?;
      if (auth != null) {
        masked['Authorization'] = _maskAuthHeader(auth);
      }
    }
    return masked;
  }

  /// Masks individual authorization header
  static String _maskAuthHeader(String authHeader) {
    // Format: "Bearer <token>" or "Basic <credentials>"
    final parts = authHeader.split(' ');
    if (parts.length == 2) {
      return '${parts[0]} ${maskToken(parts[1])}';
    }
    return '****';
  }

  /// Masks a path that might contain tokens
  static String maskPath(String? path) {
    if (path == null || path.isEmpty) return 'null';
    return maskUrl(path);
  }
}
