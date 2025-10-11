import 'package:dio/dio.dart';

/// Abstract interface for an HTTP client manager.
/// This allows for interchangeable HTTP client implementations.
abstract class IHttpClientManager {
  /// Performs a GET request.
  Future<Response> get(
    Uri uri, {
    Map<String, String>? headers,
    ResponseType? responseType,
  });

  /// Performs a POST request.
  Future<Response> post(Uri uri, {Map<String, String>? headers, Object? body});

  /// Disposes of the client's resources.
  void dispose();
}
