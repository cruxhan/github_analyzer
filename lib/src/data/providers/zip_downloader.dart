import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/common/errors/analyzer_exception.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

class ZipDownloader {
  final AnalyzerLogger logger;
  final IHttpClientManager httpClientManager;

  ZipDownloader({required this.logger, required this.httpClientManager});

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

      if (response.statusCode == 404) {
        throw AnalyzerException(
          'Repository or branch not found: $owner/$repo@$branch',
          code: AnalyzerErrorCode.repositoryNotFound,
          details: 'The repository or specified branch does not exist',
        );
      } else if (response.statusCode != 200) {
        throw AnalyzerException(
          'Failed to download repository',
          code: AnalyzerErrorCode.networkError,
          // Corrected: use statusMessage
          details: 'Status: ${response.statusCode} ${response.statusMessage}',
        );
      }

      logger.info('Repository downloaded as bytes successfully');
      // Corrected: use response.data and cast
      return Uint8List.fromList(response.data as List<int>);
    } catch (e) {
      if (e is AnalyzerException) {
        rethrow;
      }
      logger.error('Failed to download repository as bytes: $e');
      throw AnalyzerException(
        'Failed to download repository as bytes',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
      );
    }
  }

  Future<String> downloadRepository({
    required String owner,
    required String repo,
    required String branch,
    String? token,
  }) async {
    logger.info('Downloading repository: $owner/$repo (branch: $branch)');

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

      if (response.statusCode == 404) {
        throw AnalyzerException(
          'Repository or branch not found: $owner/$repo@$branch',
          code: AnalyzerErrorCode.repositoryNotFound,
          details: 'The repository or specified branch does not exist',
        );
      } else if (response.statusCode != 200) {
        throw AnalyzerException(
          'Failed to download repository',
          code: AnalyzerErrorCode.networkError,
          // Corrected: use statusMessage
          details: 'Status: ${response.statusCode} ${response.statusMessage}',
        );
      }

      final tempDir = await Directory.systemTemp.createTemp('github_analyzer_');
      final zipPath = '${tempDir.path}/$repo-$branch.zip';
      final zipFile = File(zipPath);

      // Corrected: use response.data and cast
      await zipFile.writeAsBytes(response.data as List<int>);
      logger.info('Repository downloaded to: $zipPath');

      return zipPath;
    } catch (e) {
      if (e is AnalyzerException) {
        rethrow;
      }
      logger.error('Failed to download repository: $e');
      throw AnalyzerException(
        'Failed to download repository',
        code: AnalyzerErrorCode.networkError,
        details: e.toString(),
      );
    }
  }
}
