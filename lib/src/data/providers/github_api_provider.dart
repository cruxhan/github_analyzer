import 'package:dio/dio.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';

/// Provides access to the GitHub API for fetching repository metadata.
class GithubApiProvider implements IGithubApiProvider {
  final String? token;
  final IHttpClientManager httpClientManager;

  /// Creates an instance of [GithubApiProvider].
  GithubApiProvider({
    this.token,
    required this.httpClientManager,
  });

  @override
  Future<RepositoryMetadata> getRepositoryMetadata(
    String owner,
    String repo,
  ) async {
    logger.info('Fetching repository metadata: $owner/$repo');
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo');
    final headers = {
      'Accept': 'application/vnd.github.v3+json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.json,
      );

      final json = response.data as Map<String, dynamic>;
      final languages = await _fetchLanguages(owner, repo, headers);

      return RepositoryMetadata(
        name: json['name'] as String,
        fullName: json['full_name'] as String?,
        description: json['description'] as String?,
        isPrivate: json['private'] as bool? ?? false,
        defaultBranch: json['default_branch'] as String? ?? 'main',
        language: json['language'] as String?,
        languages: languages,
        stars: json['stargazers_count'] as int? ?? 0,
        forks: json['forks_count'] as int? ?? 0,
        commitSha: null,
        fileCount: 0,
        directoryTree: '',
      );
    } on DioException catch (e, stackTrace) {
      return _handleDioException(e, stackTrace, owner, repo);
    } on FormatException catch (e, stackTrace) {
      // 🆕 JSON 파싱 에러 처리
      logger.severe('Failed to parse repository metadata JSON.', e, stackTrace);
      throw AnalyzerException(
        'Invalid JSON response from GitHub API',
        code: AnalyzerErrorCode.analysisError,
        details: 'The API response could not be parsed: ${e.message}',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on TypeError catch (e, stackTrace) {
      // 🆕 타입 에러 처리
      logger.severe(
          'Type error while processing repository metadata.', e, stackTrace);
      throw AnalyzerException(
        'Unexpected data structure in API response',
        code: AnalyzerErrorCode.analysisError,
        details: 'The API response structure was not as expected',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      logger.severe('An unexpected error occurred.', e, stackTrace);
      throw AnalyzerException(
        'An unexpected error occurred while fetching repository metadata.',
        code: AnalyzerErrorCode.analysisError,
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 🆕 DioException 세분화 처리
  Never _handleDioException(
    DioException e,
    StackTrace stackTrace,
    String owner,
    String repo,
  ) {
    logger.severe('DioException occurred while fetching repository metadata.',
        e, stackTrace);

    // HTTP 상태 코드별 처리
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 404:
          throw AnalyzerException(
            'Repository not found: $owner/$repo',
            code: AnalyzerErrorCode.repositoryNotFound,
            details: 'The repository does not exist or is not accessible.',
            originalException: e,
            stackTrace: stackTrace,
          );
        case 403:
          throw AnalyzerException(
            'Access forbidden to $owner/$repo',
            code: AnalyzerErrorCode.accessDenied,
            details: 'Check your token permissions or rate limits. '
                'You may have exceeded the API rate limit.',
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
                'GitHub API is experiencing issues (HTTP $statusCode). Please try again later.',
            originalException: e,
            stackTrace: stackTrace,
          );
      }
    }

    // DioException 타입별 처리
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw AnalyzerException(
          'Request timeout',
          code: AnalyzerErrorCode.networkError,
          details:
              'The request to GitHub API timed out. Check your network connection.',
          originalException: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        throw AnalyzerException(
          'Connection error',
          code: AnalyzerErrorCode.networkError,
          details:
              'Failed to connect to GitHub API. Check your network connection.',
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
          'Request cancelled',
          code: AnalyzerErrorCode.networkError,
          details: 'The request was cancelled',
          originalException: e,
          stackTrace: stackTrace,
        );
      default:
        throw AnalyzerException(
          'Failed to fetch repository metadata',
          code: AnalyzerErrorCode.networkError,
          details: e.message ?? 'Unknown network error',
          originalException: e,
          stackTrace: stackTrace,
        );
    }
  }

  Future<List<String>> _fetchLanguages(
    String owner,
    String repo,
    Map<String, String> headers,
  ) async {
    try {
      final languagesUri =
          Uri.parse('https://api.github.com/repos/$owner/$repo/languages');
      final languagesResponse = await httpClientManager.get(
        languagesUri,
        headers: headers,
        responseType: ResponseType.json,
      );

      if (languagesResponse.statusCode == 200) {
        final languagesJson = languagesResponse.data as Map<String, dynamic>;
        return languagesJson.keys.toList();
      }
    } on DioException catch (e, stackTrace) {
      // 🆕 구체적 에러 로깅
      logger.warning(
        'Could not fetch repository languages (${e.type.name}). Proceeding without it.',
        e,
        stackTrace,
      );
    } on FormatException catch (e, stackTrace) {
      logger.warning(
        'Failed to parse languages JSON. Proceeding without it.',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      logger.warning(
        'Unexpected error fetching languages. Proceeding without it.',
        e,
        stackTrace,
      );
    }

    return [];
  }

  @override
  Future<String?> getCommitShaForBranch(
    String owner,
    String repo,
    String branch,
  ) async {
    final headers = {
      'Accept': 'application/vnd.github.v3+json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final branchInfoUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/branches/$branch',
      );
      final branchResponse = await httpClientManager.get(
        branchInfoUri,
        headers: headers,
        responseType: ResponseType.json,
      );

      if (branchResponse.statusCode == 200) {
        final branchJson = branchResponse.data as Map<String, dynamic>;
        final sha = branchJson['commit']?['sha'] as String?;

        if (sha != null) {
          logger.info('Found commit SHA $sha for branch $branch');
        } else {
          logger.warning('Could not find commit SHA in branch response.');
        }

        return sha;
      }
    } on DioException catch (e, stackTrace) {
      // 🆕 구체적 에러 타입 로깅
      logger.warning(
        'Could not fetch branch information for $branch (${e.type.name}). Proceeding without commit SHA.',
        e,
        stackTrace,
      );
    } on FormatException catch (e, stackTrace) {
      logger.warning(
        'Failed to parse branch JSON for $branch. Proceeding without commit SHA.',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      logger.warning(
        'Unexpected error fetching branch $branch. Proceeding without commit SHA.',
        e,
        stackTrace,
      );
    }

    return null;
  }

  @override
  void dispose() {
    // HttpClientManager is disposed by the GithubAnalyzer class
  }
}
