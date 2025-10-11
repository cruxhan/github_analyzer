import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

/// An HTTP client manager using the dio package for robust networking.
/// It handles retries, timeouts, and concurrent requests automatically.
class HttpClientManager implements IHttpClientManager {
  final AnalyzerLogger logger;
  final Dio _dio;

  HttpClientManager({
    required this.logger,
    Duration requestTimeout = const Duration(seconds: 30),
    int maxConcurrentRequests = 10,
    int maxRetries = 3,
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: requestTimeout,
           receiveTimeout: requestTimeout,
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.debug('Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.debug('Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          logger.warning('Request Error: ${e.message}');
          // Simple retry logic, dio has more advanced retry packages if needed.
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            logger.info('Retrying request due to timeout...');
            try {
              final response = await _dio.request(
                e.requestOptions.path,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                ),
              );
              return handler.resolve(response);
            } catch (err) {
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
    // Adjust the pool manager for concurrent requests
    (_dio.httpClientAdapter as dynamic).createHttpClient = () {
      final client = HttpClient();
      client.maxConnectionsPerHost = maxConcurrentRequests;
      return client;
    };
  }

  @override
  Future<Response> get(
    Uri uri, {
    Map<String, String>? headers,
    ResponseType? responseType,
  }) async {
    try {
      final response = await _dio.getUri(
        uri,
        options: Options(headers: headers, responseType: responseType),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to GET $uri: ${e.message}');
    }
  }

  @override
  Future<Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await _dio.postUri(
        uri,
        data: body,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to POST $uri: ${e.message}');
    }
  }

  @override
  void dispose() {
    _dio.close();
    logger.info('HttpClientManager disposed');
  }
}
