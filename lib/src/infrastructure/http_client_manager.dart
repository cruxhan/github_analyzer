import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'package:github_analyzer/src/common/logger.dart';
import 'package:github_analyzer/src/infrastructure/interfaces/i_http_client_manager.dart';

/// An HTTP client manager using the dio package for robust networking.
/// It handles retries, timeouts, and concurrent requests automatically.
class HttpClientManager implements IHttpClientManager {
  final Dio _dio;
  final int _maxRetries;
  int _retryCount = 0;

  /// Creates an instance of [HttpClientManager].
  HttpClientManager({
    Duration requestTimeout = const Duration(seconds: 30),
    int maxConcurrentRequests = 10,
    int maxRetries = 3,
  }) : _maxRetries = maxRetries,
       _dio = Dio(
         BaseOptions(
           connectTimeout: requestTimeout,
           receiveTimeout: requestTimeout,
           sendTimeout: requestTimeout,
           followRedirects: true, // ✅ 리디렉션 자동 따라가기
           maxRedirects: 5, // ✅ 최대 5번까지 리디렉션 허용
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.finer('Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.finer('Response: ${response.statusCode}');
          _retryCount = 0; // Reset retry count on success
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          logger.warning('Request Error: ${e.message}', e, e.stackTrace);

          if (_shouldRetry(e) && _retryCount < _maxRetries) {
            _retryCount++;
            logger.info(
              'Retrying request (attempt $_retryCount/$_maxRetries) due to ${e.type.name}...',
            );

            try {
              final delay = Duration(
                milliseconds: 1000 * (1 << (_retryCount - 1)),
              );
              await Future.delayed(delay);

              final response = await _dio.request(
                e.requestOptions.path,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                  responseType: e.requestOptions.responseType,
                  followRedirects: true, // ✅ 재시도 시에도 리디렉션 허용
                  maxRedirects: 5,
                ),
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );

              _retryCount = 0;
              return handler.resolve(response);
            } on DioException catch (retryError) {
              logger.warning(
                'Retry failed (attempt $_retryCount): ${retryError.message}',
              );
              if (_retryCount >= _maxRetries) {
                logger.severe(
                  'Max retries ($_maxRetries) exceeded for ${e.requestOptions.uri}',
                );
              }
              return handler.next(retryError);
            } catch (retryError, stackTrace) {
              logger.severe(
                'Unexpected error during retry',
                retryError,
                stackTrace,
              );
              return handler.next(e);
            }
          }

          return handler.next(e);
        },
      ),
    );

    _configureHttpClient(maxConcurrentRequests);
  }

  /// 타입 안전한 HttpClient 설정
  void _configureHttpClient(int maxConcurrentRequests) {
    try {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.maxConnectionsPerHost = maxConcurrentRequests;
          client.connectionTimeout = const Duration(seconds: 30);
          client.idleTimeout = const Duration(seconds: 15);
          return client;
        };
        logger.fine(
          'HTTP client configured with $maxConcurrentRequests max connections per host',
        );
      } else {
        logger.warning(
          'HTTP adapter is not IOHttpClientAdapter (${adapter.runtimeType}). '
          'Skipping client configuration.',
        );
      }
    } catch (e, stackTrace) {
      logger.warning('Failed to configure HTTP client adapter', e, stackTrace);
    }
  }

  /// 재시도 여부 판단
  bool _shouldRetry(DioException e) {
    const retryableTypes = {
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.connectionError,
    };

    if (retryableTypes.contains(e.type)) {
      return true;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    if (statusCode == 429) {
      return true;
    }

    return false;
  }

  @override
  Future<Response> get(
    Uri uri, {
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      final response = await _dio.getUri(
        uri,
        options: Options(
          headers: headers,
          responseType: responseType ?? ResponseType.json,
          followRedirects: true, // ✅ GET 요청에서도 리디렉션 허용
          maxRedirects: 5,
        ),
      );
      return response;
    } on DioException {
      rethrow;
    } on TypeError catch (e, stackTrace) {
      logger.severe('Type error in GET request', e, stackTrace);
      throw DioException(
        requestOptions: RequestOptions(path: uri.toString()),
        error: e,
        stackTrace: stackTrace,
        type: DioExceptionType.unknown,
        message: 'Type error occurred: ${e.toString()}',
      );
    } catch (e, stackTrace) {
      logger.severe('Unexpected error in GET request', e, stackTrace);
      throw DioException(
        requestOptions: RequestOptions(path: uri.toString()),
        error: e,
        stackTrace: stackTrace,
        type: DioExceptionType.unknown,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  @override
  Future<Response> post(
    Uri uri, {
    Map<String, dynamic>? headers,
    Object? body,
  }) async {
    try {
      final response = await _dio.postUri(
        uri,
        data: body,
        options: Options(
          headers: headers,
          followRedirects: true, // ✅ POST 요청에서도 리디렉션 허용
          maxRedirects: 5,
        ),
      );
      return response;
    } on DioException {
      rethrow;
    } on TypeError catch (e, stackTrace) {
      logger.severe('Type error in POST request', e, stackTrace);
      throw DioException(
        requestOptions: RequestOptions(path: uri.toString(), method: 'POST'),
        error: e,
        stackTrace: stackTrace,
        type: DioExceptionType.unknown,
        message: 'Type error occurred: ${e.toString()}',
      );
    } catch (e, stackTrace) {
      logger.severe('Unexpected error in POST request', e, stackTrace);
      throw DioException(
        requestOptions: RequestOptions(path: uri.toString(), method: 'POST'),
        error: e,
        stackTrace: stackTrace,
        type: DioExceptionType.unknown,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _dio.close();
    logger.info('HttpClientManager disposed');
  }
}
