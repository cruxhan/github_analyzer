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

    final url =
        'https://github.com/$owner/$repo/archive/refs/heads/$branch.zip';
    final uri = Uri.parse(url);

    final headers = <String, String>{
      'Accept': 'application/zip',
      if (token != null) 'Authorization': 'token $token',
    };

    try {
      final response = await httpClientManager.get(
        uri,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      // Dio is configured to throw exceptions for non-2xx status codes
      logger.info('Repository downloaded as bytes successfully');
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

      logger.severe('Failed to download repository as bytes.', e, stackTrace);
      throw AnalyzerException(
        'Failed to download repository as bytes',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is AnalyzerException) rethrow;

      logger.severe('An unexpected error occurred.', e, stackTrace);
      throw AnalyzerException(
        'An unexpected error occurred while downloading repository as bytes.',
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
