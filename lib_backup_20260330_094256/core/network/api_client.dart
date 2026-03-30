import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/network/api_exception.dart';

typedef AccessTokenProvider = Future<String?> Function();
typedef RefreshTokenHandler = Future<String?> Function();

class ApiClient {
  static const String _refreshRetryKey = 'auth.retryAfterRefresh';

  ApiClient._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    _setupInterceptors();
  }

  static final ApiClient instance = ApiClient._internal();

  final Dio _dio;
  AccessTokenProvider? _accessTokenProvider;
  RefreshTokenHandler? _refreshTokenHandler;
  Future<String?>? _activeRefreshRequest;

  Dio get dio => _dio;

  void configure({
    String? baseUrl,
    AccessTokenProvider? accessTokenProvider,
    RefreshTokenHandler? refreshTokenHandler,
  }) {
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _dio.options.baseUrl = baseUrl.trim();
    }

    if (accessTokenProvider != null) {
      _accessTokenProvider = accessTokenProvider;
    }

    if (refreshTokenHandler != null) {
      _refreshTokenHandler = refreshTokenHandler;
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final String? token = await _resolveAccessToken();
          final bool hasAuthHeader = options.headers['Authorization'] != null;

          if (!hasAuthHeader && token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('[API] ${options.method} ${options.uri}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] <-- ${response.statusCode} ${response.requestOptions.uri}',
            );
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          if (_shouldAttemptTokenRefresh(error)) {
            final String? refreshedAccessToken = await _refreshAccessToken();
            if (refreshedAccessToken != null &&
                refreshedAccessToken.trim().isNotEmpty) {
              try {
                final RequestOptions requestOptions = error.requestOptions;
                final Map<String, dynamic> retryHeaders = <String, dynamic>{
                  ...requestOptions.headers,
                  'Authorization': 'Bearer ${refreshedAccessToken.trim()}',
                };
                final Map<String, dynamic> retryExtra = <String, dynamic>{
                  ...requestOptions.extra,
                  _refreshRetryKey: true,
                };

                final Response<dynamic> retryResponse = await _dio
                    .request<dynamic>(
                      requestOptions.path,
                      data: requestOptions.data,
                      queryParameters: requestOptions.queryParameters,
                      cancelToken: requestOptions.cancelToken,
                      onReceiveProgress: requestOptions.onReceiveProgress,
                      onSendProgress: requestOptions.onSendProgress,
                      options: Options(
                        method: requestOptions.method,
                        headers: retryHeaders,
                        responseType: requestOptions.responseType,
                        contentType: requestOptions.contentType,
                        followRedirects: requestOptions.followRedirects,
                        listFormat: requestOptions.listFormat,
                        receiveDataWhenStatusError:
                            requestOptions.receiveDataWhenStatusError,
                        extra: retryExtra,
                        validateStatus: requestOptions.validateStatus,
                        requestEncoder: requestOptions.requestEncoder,
                        responseDecoder: requestOptions.responseDecoder,
                        sendTimeout: requestOptions.sendTimeout,
                        receiveTimeout: requestOptions.receiveTimeout,
                      ),
                    );

                handler.resolve(retryResponse);
                return;
              } on DioException catch (retryError) {
                if (kDebugMode) {
                  debugPrint(
                    '[API] RETRY ERROR ${retryError.response?.statusCode} ${retryError.requestOptions.uri}',
                  );
                }
                handler.next(retryError);
                return;
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
              '[API] ERROR ${error.response?.statusCode} ${error.requestOptions.uri}',
            );
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _resolveAccessToken() async {
    if (_accessTokenProvider == null) {
      return null;
    }

    try {
      return await _accessTokenProvider!.call();
    } catch (_) {
      return null;
    }
  }

  bool _shouldAttemptTokenRefresh(DioException error) {
    if (_refreshTokenHandler == null) {
      return false;
    }

    if (error.response?.statusCode != 401) {
      return false;
    }

    final RequestOptions requestOptions = error.requestOptions;
    if (requestOptions.extra[_refreshRetryKey] == true) {
      return false;
    }

    final String path = requestOptions.path;
    if (path.contains(ApiEndpoints.refreshToken) || path.contains('/auth/')) {
      return false;
    }

    return true;
  }

  Future<String?> _refreshAccessToken() async {
    final Future<String?>? inFlight = _activeRefreshRequest;
    if (inFlight != null) {
      return inFlight;
    }

    final RefreshTokenHandler? handler = _refreshTokenHandler;
    if (handler == null) {
      return null;
    }

    final Future<String?> refreshFuture = handler();
    _activeRefreshRequest = refreshFuture;
    try {
      return await refreshFuture;
    } catch (_) {
      return null;
    } finally {
      if (identical(_activeRefreshRequest, refreshFuture)) {
        _activeRefreshRequest = null;
      }
    }
  }
}
