import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

/// Handles downloading of repository zip archives from GitHub.
class ZipDownloader {
  final IHttpClientManager httpClientManager;

  /// Creates an instance of [ZipDownloader].
  ZipDownloader({required this.httpClientManager});

  /// Downloads a repository as a byte array (Uint8List).
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
      // Dio is configured to throw exceptions for non-2xx status codes,
      // so we don't need to check for response.statusCode != 200 here.
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
      if (e is AnalyzerException) {
        rethrow;
      }
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

  /// Downloads a repository to a temporary local zip file.
  Future<String> downloadRepository({
    required String owner,
    required String repo,
    required String branch,
    String? token,
  }) async {
    try {
      final zipBytes = await downloadRepositoryAsBytes(
        owner: owner,
        repo: repo,
        branch: branch,
        token: token,
      );

      final tempDir = await Directory.systemTemp.createTemp('github_analyzer_');
      final zipPath = '${tempDir.path}/$repo-$branch.zip';
      final zipFile = File(zipPath);

      await zipFile.writeAsBytes(zipBytes);
      logger.info('Repository downloaded to: $zipPath');

      return zipPath;
    } catch (e, stackTrace) {
      if (e is AnalyzerException) {
        rethrow;
      }
      logger.severe('Failed to download repository.', e, stackTrace);
      throw AnalyzerException(
        'Failed to download repository',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
}
