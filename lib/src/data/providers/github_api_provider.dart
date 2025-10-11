import 'package:dio/dio.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_github_api_provider.dart';
import 'package:github_analyzer/src/models/repository_metadata.dart';

class GithubApiProvider implements IGithubApiProvider {
  final String? token;
  final AnalyzerLogger logger;
  final IHttpClientManager httpClientManager;

  GithubApiProvider({
    this.token,
    required this.logger,
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

      if (response.statusCode == 404) {
        throw AnalyzerException(
          'Repository not found: $owner/$repo',
          code: AnalyzerErrorCode.repositoryNotFound,
          details: 'The repository does not exist or is not accessible',
        );
      } else if (response.statusCode == 403) {
        throw AnalyzerException(
          'Access forbidden',
          code: AnalyzerErrorCode.accessDenied,
          details: 'Check your token permissions or rate limits',
        );
      } else if (response.statusCode != 200) {
        throw AnalyzerException(
          'Failed to fetch repository metadata',
          code: AnalyzerErrorCode.networkError,
          details: 'Status: ${response.statusCode}, Body: ${response.data}',
        );
      }

      final json = response.data as Map<String, dynamic>;

      final languagesUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/languages',
      );
      final languagesResponse = await httpClientManager.get(
        languagesUri,
        headers: headers,
        responseType: ResponseType.json,
      );

      final languages = <String>[];
      if (languagesResponse.statusCode == 200) {
        final languagesJson = languagesResponse.data as Map<String, dynamic>;
        languages.addAll(languagesJson.keys);
      }

      final defaultBranch = json['default_branch'] as String? ?? 'main';
      final branchInfoUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/branches/$defaultBranch',
      );
      String? commitSha;
      try {
        final branchResponse = await httpClientManager.get(
          branchInfoUri,
          headers: headers,
          responseType: ResponseType.json,
        );
        if (branchResponse.statusCode == 200) {
          final branchJson = branchResponse.data as Map<String, dynamic>;
          commitSha = branchJson['commit']?['sha'] as String?;
        }
      } catch (e) {
        logger.warning(
          'Could not fetch branch information for $defaultBranch. Proceeding without commit SHA.',
        );
      }

      return RepositoryMetadata(
        name: json['name'] as String,
        fullName: json['full_name'] as String?,
        description: json['description'] as String?,
        isPrivate: json['private'] as bool? ?? false,
        defaultBranch: defaultBranch,
        language: json['language'] as String?,
        languages: languages,
        stars: json['stargazers_count'] as int? ?? 0,
        forks: json['forks_count'] as int? ?? 0,
        commitSha: commitSha,
        // These are populated later in the analysis process
        fileCount: 0,
        directoryTree: '',
      );
    } catch (e) {
      if (e is AnalyzerException) {
        rethrow;
      }
      throw AnalyzerException(
        'Failed to fetch repository metadata',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    // HttpClientManager is disposed by the GithubAnalyzer class
  }
}
