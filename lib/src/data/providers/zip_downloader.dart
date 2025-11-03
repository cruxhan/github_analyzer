import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

/// Downloads GitHub repository archives as ZIP files.
///
/// Supports both public and private repositories with automatic
/// fallback strategy for public repos.
class ZipDownloader {
  final IHttpClientManager httpClientManager;

  ZipDownloader({required this.httpClientManager});

  /// Downloads repository archive and returns raw bytes.
  ///
  /// For private repositories ([isPrivate] = true), GitHub API is required
  /// and fallback to public URL is prevented. For public repos, automatically
  /// falls back to public URL if API fails.
  ///
  /// [ref] can be branch name, tag, or commit SHA.
  Future<Uint8List> downloadRepositoryAsBytes({
    required String owner,
    required String repo,
    required String ref,
    String? token,
    bool isPrivate = false,
  }) async {
    logger.info(
      'Downloading repository: $owner/$repo@$ref (private: $isPrivate, hasToken: ${token != null && token.isNotEmpty})',
    );

    // Try GitHub API first if token is available
    if (token != null && token.isNotEmpty) {
      try {
        logger.info('Attempting download via GitHub API...');
        return await _downloadViaGitHubAPI(owner, repo, ref, token);
      } on AnalyzerException {
        rethrow;
      } catch (e, stackTrace) {
        logger.warning(
          'GitHub API download failed: ${e.runtimeType}',
          e,
          stackTrace,
        );

        // Prevent fallback for private repositories
        if (isPrivate) {
          logger.severe('Cannot fallback to public URL for private repository');
          throw AnalyzerException(
            'Failed to download private repository via GitHub API',
            code: AnalyzerErrorCode.accessDenied,
            details:
                'GitHub API download failed for private repository. '
                'Possible causes:\n'
                '1. Token lacks "contents" read permission\n'
                '2. Token does not have access to this repository\n'
                '3. Repository owner/name is incorrect\n\n'
                'Please check your GitHub token permissions at:\n'
                'https://github.com/settings/tokens\n\n'
                'Original error: $e',
            originalException: e,
            stackTrace: stackTrace,
          );
        }

        // Fallback to public URL for public repositories
        logger.info('Falling back to public URL for public repository');
      }
    } else if (isPrivate) {
      // Cannot access private repos without token
      throw AnalyzerException(
        'Cannot access private repository without token',
        code: AnalyzerErrorCode.accessDenied,
        details:
            'A GitHub token is required to access private repositories. '
            'Please provide a valid token with "contents" read permission.',
      );
    }

    // Fallback: use public GitHub URL (public repos only)
    logger.info('Attempting download via public URL...');
    return await _downloadViaPublicURL(owner, repo, ref, token);
  }

  /// Downloads via GitHub API (supports private repos, branches, and commit SHAs).
  Future<Uint8List> _downloadViaGitHubAPI(
    String owner,
    String repo,
    String ref,
    String token,
  ) async {
    final url = 'https://api.github.com/repos/$owner/$repo/zipball/$ref';
    final uri = Uri.parse(url);
    final headers = {
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $token',
      'X-GitHub-Api-Version': '2022-11-28',
    };

    try {
      logger.fine('GitHub API URL: $url');
      logger.fine('Authorization: Bearer ${token.substring(0, 10)}...');

      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      logger.info(
        'Repository downloaded via GitHub API successfully (${response.data.length} bytes)',
      );

      final data = response.data;
      if (data is! List<int>) {
        throw AnalyzerException(
          'Invalid response data type from GitHub API',
          code: AnalyzerErrorCode.analysisError,
          details: 'Expected List<int>, got ${data.runtimeType}',
        );
      }

      return Uint8List.fromList(data);
    } on DioException catch (e, stackTrace) {
      logger.severe('DioException details:', e, stackTrace);
      logger.severe('Response status: ${e.response?.statusCode}');
      logger.severe('Response headers: ${e.response?.headers}');
      logger.severe('Response data: ${e.response?.data}');

      return _handleDioException(e, stackTrace, owner, repo, ref, 'GitHub API');
    } on TypeError catch (e, stackTrace) {
      logger.severe('Type error in GitHub API response', e, stackTrace);
      throw AnalyzerException(
        'Invalid data format in GitHub API response',
        code: AnalyzerErrorCode.analysisError,
        details: 'Failed to convert response data to Uint8List',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Downloads via public GitHub URL (branch-based or commit SHA URL).
  Future<Uint8List> _downloadViaPublicURL(
    String owner,
    String repo,
    String ref,
    String? token,
  ) async {
    // Different URL formats for commit SHAs vs branches
    final isCommitSha = RegExp(r'^[0-9a-f]{40}$').hasMatch(ref);
    final String url;
    if (isCommitSha) {
      url = 'https://github.com/$owner/$repo/archive/$ref.zip';
    } else {
      url = 'https://github.com/$owner/$repo/archive/refs/heads/$ref.zip';
    }

    final uri = Uri.parse(url);
    final headers = {
      'Accept': 'application/zip',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      logger.fine('Public URL: $url');
      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.bytes,
      );
      logger.info(
        'Repository downloaded via public URL successfully (${response.data.length} bytes)',
      );

      final data = response.data;
      if (data is! List<int>) {
        throw AnalyzerException(
          'Invalid response data type from public URL',
          code: AnalyzerErrorCode.analysisError,
          details: 'Expected List<int>, got ${data.runtimeType}',
        );
      }

      return Uint8List.fromList(data);
    } on DioException catch (e, stackTrace) {
      return _handleDioException(e, stackTrace, owner, repo, ref, 'public URL');
    } on TypeError catch (e, stackTrace) {
      logger.severe('Type error in public URL response', e, stackTrace);
      throw AnalyzerException(
        'Invalid data format in public URL response',
        code: AnalyzerErrorCode.analysisError,
        details: 'Failed to convert response data to Uint8List',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is AnalyzerException) rethrow;
      logger.severe('An unexpected error occurred', e, stackTrace);
      throw AnalyzerException(
        'An unexpected error occurred while downloading repository',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handles DioException and converts to appropriate AnalyzerException.
  Never _handleDioException(
    DioException e,
    StackTrace stackTrace,
    String owner,
    String repo,
    String ref,
    String source,
  ) {
    logger.severe('Failed to download via $source', e, stackTrace);

    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 404:
          throw AnalyzerException(
            'Repository or ref not found: $owner/$repo@$ref',
            code: AnalyzerErrorCode.repositoryNotFound,
            details:
                'The repository or specified ref (branch/SHA) does not exist.',
            originalException: e,
            stackTrace: stackTrace,
          );
        case 403:
          final responseBody =
              e.response?.data?.toString() ?? 'No response body';
          throw AnalyzerException(
            'Access forbidden to $owner/$repo',
            code: AnalyzerErrorCode.accessDenied,
            details:
                'GitHub returned 403 Forbidden. Possible causes:\n'
                '1. Token lacks required permissions (needs "contents" read access)\n'
                '2. Token does not have access to this repository\n'
                '3. API rate limit exceeded\n'
                '4. Repository is private and token is invalid\n\n'
                'Response: $responseBody\n\n'
                'Check your token at: https://github.com/settings/tokens',
            originalException: e,
            stackTrace: stackTrace,
          );
        case 401:
          throw AnalyzerException(
            'Authentication failed',
            code: AnalyzerErrorCode.accessDenied,
            details: 'Invalid or expired GitHub token',
            originalException: e,
            stackTrace: stackTrace,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          throw AnalyzerException(
            'GitHub server error',
            code: AnalyzerErrorCode.networkError,
            details:
                'GitHub is experiencing issues (HTTP $statusCode). Please try again later.',
            originalException: e,
            stackTrace: stackTrace,
          );
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw AnalyzerException(
          'Download timeout',
          code: AnalyzerErrorCode.networkError,
          details:
              'The download request timed out. The repository may be too large or network is slow.',
          originalException: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        throw AnalyzerException(
          'Connection error',
          code: AnalyzerErrorCode.networkError,
          details:
              'Failed to connect to GitHub. Check your network connection.',
          originalException: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badCertificate:
        throw AnalyzerException(
          'SSL certificate error',
          code: AnalyzerErrorCode.networkError,
          details: 'Invalid SSL certificate',
          originalException: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.cancel:
        throw AnalyzerException(
          'Download cancelled',
          code: AnalyzerErrorCode.networkError,
          details: 'The download was cancelled',
          originalException: e,
          stackTrace: stackTrace,
        );
      default:
        throw AnalyzerException(
          'Failed to download repository via $source',
          code: AnalyzerErrorCode.networkError,
          details: e.message ?? 'Unknown network error',
          originalException: e,
          stackTrace: stackTrace,
        );
    }
  }

  /// Deprecated: Use [downloadRepositoryAsBytes] instead.
  @Deprecated('Use downloadRepositoryAsBytes for in-memory processing')
  Future<String> downloadRepository({
    required String owner,
    required String repo,
    required String ref,
    String? token,
  }) async {
    throw UnsupportedError(
      'downloadRepository is not supported. Use downloadRepositoryAsBytes instead.',
    );
  }
}
