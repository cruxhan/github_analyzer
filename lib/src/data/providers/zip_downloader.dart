import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

/// Handles downloading of repository zip archives from GitHub
class ZipDownloader {
  final IHttpClientManager httpClientManager;

  ZipDownloader({required this.httpClientManager});

  /// Downloads a repository as a byte array (Uint8List)
  Future<Uint8List> downloadRepositoryAsBytes({
    required String owner,
    required String repo,
    required String branch,
    String? token,
  }) async {
    logger.info(
      'Downloading repository as bytes: $owner/$repo (branch: $branch)',
    );

    // Try GitHub API first (supports private repositories)
    if (token != null && token.isNotEmpty) {
      try {
        return await _downloadViaGitHubAPI(owner, repo, branch, token);
      } catch (e) {
        logger.warning('GitHub API download failed, trying public URL: $e');
        // Fall back to public URL if API fails
      }
    }

    // Fall back to public GitHub URL
    return await _downloadViaPublicURL(owner, repo, branch, token);
  }

  /// Downloads via GitHub API (supports private repos)
  Future<Uint8List> _downloadViaGitHubAPI(
    String owner,
    String repo,
    String branch,
    String token,
  ) async {
    final url = 'https://api.github.com/repos/$owner/$repo/zipball/$branch';
    final uri = Uri.parse(url);

    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $token',
      'X-GitHub-Api-Version': '2022-11-28',
    };

    try {
      logger.fine('Downloading via GitHub API: $url');
      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      logger.info('Repository downloaded via GitHub API successfully');
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 404) {
        throw AnalyzerException(
          'Repository or branch not found: $owner/$repo@$branch',
          code: AnalyzerErrorCode.repositoryNotFound,
          details: 'The repository or specified branch does not exist.',
          originalException: e,
        );
      }

      logger.severe('Failed to download via GitHub API', e, stackTrace);
      throw AnalyzerException(
        'Failed to download repository via GitHub API',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Downloads via public GitHub URL
  Future<Uint8List> _downloadViaPublicURL(
    String owner,
    String repo,
    String branch,
    String? token,
  ) async {
    final url =
        'https://github.com/$owner/$repo/archive/refs/heads/$branch.zip';
    final uri = Uri.parse(url);

    final headers = <String, String>{
      'Accept': 'application/zip',
      if (token != null) 'Authorization': 'token $token',
    };

    try {
      logger.fine('Downloading via public URL: $url');
      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      logger.info('Repository downloaded via public URL successfully');
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 404) {
        throw AnalyzerException(
          'Repository or branch not found: $owner/$repo@$branch',
          code: AnalyzerErrorCode.repositoryNotFound,
          details: 'The repository or specified branch does not exist.',
          originalException: e,
        );
      }

      logger.severe('Failed to download via public URL', e, stackTrace);
      throw AnalyzerException(
        'Failed to download repository',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
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

  /// Downloads a repository to a temporary local zip file
  /// Note: This method is not available on web platforms
  Future<String> downloadRepository({
    required String owner,
    required String repo,
    required String branch,
    String? token,
  }) async {
    throw UnsupportedError(
      'downloadRepository is not supported. Use downloadRepositoryAsBytes instead.',
    );
  }
}
