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
      if (token != null) 'Authorization': 'token $token',
    };

    try {
      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.json,
      );

      final json = response.data as Map<String, dynamic>;

      // The following API calls are best-effort. If they fail, we proceed
      // with the data we have.

      final languages = await _fetchLanguages(owner, repo, headers);
      final commitSha = await _fetchCommitSha(
        owner,
        repo,
        json['default_branch'] as String? ?? 'main',
        headers,
      );

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
        commitSha: commitSha,
        fileCount: 0, // Populated later.
        directoryTree: '', // Populated later.
      );
    } on DioException catch (e, stackTrace) {
      logger.severe('Failed to fetch repository metadata.', e, stackTrace);
      if (e.response?.statusCode == 404) {
        throw AnalyzerException(
          'Repository not found: $owner/$repo',
          code: AnalyzerErrorCode.repositoryNotFound,
          details: 'The repository does not exist or is not accessible.',
          originalException: e,
        );
      } else if (e.response?.statusCode == 403) {
        throw AnalyzerException(
          'Access forbidden.',
          code: AnalyzerErrorCode.accessDenied,
          details: 'Check your token permissions or rate limits.',
          originalException: e,
        );
      }
      throw AnalyzerException(
        'Failed to fetch repository metadata due to a network error.',
        code: AnalyzerErrorCode.networkError,
        details: e.message,
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
    } catch (e, stackTrace) {
      logger.warning(
        'Could not fetch repository languages. Proceeding without it.',
        e,
        stackTrace,
      );
    }
    return [];
  }

  Future<String?> _fetchCommitSha(
    String owner,
    String repo,
    String defaultBranch,
    Map<String, String> headers,
  ) async {
    try {
      final branchInfoUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/branches/$defaultBranch',
      );
      final branchResponse = await httpClientManager.get(
        branchInfoUri,
        headers: headers,
        responseType: ResponseType.json,
      );
      if (branchResponse.statusCode == 200) {
        final branchJson = branchResponse.data as Map<String, dynamic>;
        return branchJson['commit']?['sha'] as String?;
      }
    } catch (e, stackTrace) {
      logger.warning(
        'Could not fetch branch information for $defaultBranch. Proceeding without commit SHA.',
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
