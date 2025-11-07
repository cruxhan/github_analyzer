import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

class ZipDownloader {
  final IHttpClientManager httpClientManager;

  ZipDownloader({required this.httpClientManager});

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

    if (token != null && token.isNotEmpty) {
      try {
        logger.info('Attempting download via GitHub API');
        return await _downloadViaGitHubAPI(owner, repo, ref, token);
      } on AnalyzerException {
        rethrow;
      } catch (e, stackTrace) {
        logger.warning(
          'GitHub API download failed: ${e.runtimeType}',
          e,
          stackTrace,
        );

        if (isPrivate) {
          logger.severe('Cannot fallback to public URL for private repository');
          throw _buildException(
            'Failed to download private repository via GitHub API',
            AnalyzerErrorCode.accessDenied,
            'GitHub API download failed for private repository. '
                'Possible causes:\n'
                '1. Token lacks "contents" read permission\n'
                '2. Token does not have access to this repository\n'
                '3. Repository owner/name is incorrect\n\n'
                'Please check your GitHub token permissions at:\n'
                'https://github.com/settings/tokens\n\n'
                'Original error: $e',
            e,
            stackTrace,
          );
        }

        logger.info('Falling back to public URL for public repository');
      }
    } else if (isPrivate) {
      throw _buildException(
        'Cannot access private repository without token',
        AnalyzerErrorCode.accessDenied,
        'A GitHub token is required to access private repositories. '
            'Please provide a valid token with "contents" read permission.',
      );
    }

    logger.info('Attempting download via public URL');
    return await _downloadViaPublicURL(owner, repo, ref, token);
  }

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

      return _validateAndConvertResponse(response.data);
    } on DioException catch (e, stackTrace) {
      logger.severe('DioException details:', e, stackTrace);
      logger.severe('Response status: ${e.response?.statusCode}');
      logger.severe('Response headers: ${e.response?.headers}');
      logger.severe('Response data: ${e.response?.data}');

      return _handleDioException(e, stackTrace, owner, repo, ref, 'GitHub API');
    } on TypeError catch (e, stackTrace) {
      logger.severe('Type error in GitHub API response', e, stackTrace);
      throw _buildException(
        'Invalid data format in GitHub API response',
        AnalyzerErrorCode.analysisError,
        'Failed to convert response data to Uint8List',
        e,
        stackTrace,
      );
    }
  }

  Future<Uint8List> _downloadViaPublicURL(
    String owner,
    String repo,
    String ref,
    String? token,
  ) async {
    final url = _buildPublicUrl(owner, repo, ref);
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

      return _validateAndConvertResponse(response.data);
    } on DioException catch (e, stackTrace) {
      return _handleDioException(e, stackTrace, owner, repo, ref, 'public URL');
    } on TypeError catch (e, stackTrace) {
      logger.severe('Type error in public URL response', e, stackTrace);
      throw _buildException(
        'Invalid data format in public URL response',
        AnalyzerErrorCode.analysisError,
        'Failed to convert response data to Uint8List',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is AnalyzerException) rethrow;
      logger.severe('An unexpected error occurred', e, stackTrace);
      throw _buildException(
        'An unexpected error occurred while downloading repository',
        AnalyzerErrorCode.networkError,
        e.toString(),
        e,
        stackTrace,
      );
    }
  }

  String _buildPublicUrl(String owner, String repo, String ref) {
    final isCommitSha = RegExp(r'^[0-9a-f]{40}$').hasMatch(ref);
    if (isCommitSha) {
      return 'https://github.com/$owner/$repo/archive/$ref.zip';
    } else {
      return 'https://github.com/$owner/$repo/archive/refs/heads/$ref.zip';
    }
  }

  Uint8List _validateAndConvertResponse(dynamic data) {
    if (data is! List<int>) {
      throw _buildException(
        'Invalid response data type',
        AnalyzerErrorCode.analysisError,
        'Expected List<int>, got ${data.runtimeType}',
      );
    }
    return Uint8List.fromList(data);
  }

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
          throw _buildException(
            'Repository or ref not found: $owner/$repo@$ref',
            AnalyzerErrorCode.repositoryNotFound,
            'The repository or specified ref (branch/SHA) does not exist.',
            e,
            stackTrace,
          );
        case 403:
          final responseBody =
              e.response?.data?.toString() ?? 'No response body';
          throw _buildException(
            'Access forbidden',
            AnalyzerErrorCode.accessDenied,
            'GitHub returned 403 Forbidden. Possible causes:\n'
                '1. Token lacks required permissions (needs "contents" read access)\n'
                '2. Token does not have access to this repository\n'
                '3. API rate limit exceeded\n'
                '4. Repository is private and token is invalid\n\n'
                'Response: $responseBody\n\n'
                'Check your token at: https://github.com/settings/tokens',
            e,
            stackTrace,
          );
        case 401:
          throw _buildException(
            'Authentication failed',
            AnalyzerErrorCode.accessDenied,
            'Invalid or expired GitHub token',
            e,
            stackTrace,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          throw _buildException(
            'GitHub server error',
            AnalyzerErrorCode.networkError,
            'GitHub is experiencing issues (HTTP $statusCode). Please try again later.',
            e,
            stackTrace,
          );
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw _buildException(
          'Download timeout',
          AnalyzerErrorCode.networkError,
          'The download request timed out. The repository may be too large or network is slow.',
          e,
          stackTrace,
        );
      case DioExceptionType.connectionError:
        throw _buildException(
          'Connection error',
          AnalyzerErrorCode.networkError,
          'Failed to connect to GitHub. Check your network connection.',
          e,
          stackTrace,
        );
      case DioExceptionType.badCertificate:
        throw _buildException(
          'SSL certificate error',
          AnalyzerErrorCode.networkError,
          'Invalid SSL certificate',
          e,
          stackTrace,
        );
      case DioExceptionType.cancel:
        throw _buildException(
          'Download cancelled',
          AnalyzerErrorCode.networkError,
          'The download was cancelled',
          e,
          stackTrace,
        );
      default:
        throw _buildException(
          'Failed to download repository via $source',
          AnalyzerErrorCode.networkError,
          e.message ?? 'Unknown network error',
          e,
          stackTrace,
        );
    }
  }

  AnalyzerException _buildException(
    String title,
    AnalyzerErrorCode code,
    String details, [
    Object? originalException,
    StackTrace? stackTrace,
  ]) {
    return AnalyzerException(
      title,
      code: code,
      details: details,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

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
