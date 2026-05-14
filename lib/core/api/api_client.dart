import 'dart:io';
import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._internal(String baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  factory ApiClient.instance({String? baseUrl}) {
    _instance ??= ApiClient._internal(baseUrl ?? ApiEndpoints.defaultBaseUrl);
    return _instance!;
  }

  static void reinitialize(String baseUrl) {
    _instance = ApiClient._internal(baseUrl);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);
}

// ── Interceptors ─────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API ERROR] ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}


class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException mapped;

    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        mapped = const NetworkException();
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        mapped = switch (status) {
          404          => const NotFoundException(),
          429          => const RateLimitException(),
          int s when s >= 500 => ServerException('Server error', s),
          _            => ServerException('Unexpected response', status),
        };
      case DioExceptionType.cancel:
        mapped = const NetworkException('Request cancelled');
      case DioExceptionType.badCertificate:
        mapped = const NetworkException('SSL certificate error');
      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          mapped = const NetworkException();
        } else {
          mapped = const ServerException('Unknown error');
        }
    }

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: mapped,
      type: err.type,
    ));
  }
}
