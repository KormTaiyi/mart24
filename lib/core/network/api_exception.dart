import 'package:dio/dio.dart';

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;
  final Object? rawError;

  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.rawError,
  });

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;

    if (error.type == DioExceptionType.cancel) {
      return ApiException(
        message: 'Request cancelled.',
        type: ApiErrorType.cancelled,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'Request timed out. Please try again.',
        type: ApiErrorType.timeout,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'No internet connection.',
        type: ApiErrorType.network,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (statusCode == 401) {
      return ApiException(
        message: _extractMessage(error) ?? 'Unauthorized request.',
        type: ApiErrorType.unauthorized,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (statusCode == 403) {
      return ApiException(
        message: _extractMessage(error) ?? 'Forbidden request.',
        type: ApiErrorType.forbidden,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (statusCode == 404) {
      return ApiException(
        message: _extractMessage(error) ?? 'Resource not found.',
        type: ApiErrorType.notFound,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (statusCode == 409) {
      return ApiException(
        message: _extractMessage(error) ?? 'Conflict occurred.',
        type: ApiErrorType.conflict,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (statusCode == 422) {
      return ApiException(
        message: _extractMessage(error) ?? 'Validation failed.',
        type: ApiErrorType.validation,
        statusCode: statusCode,
        rawError: error,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        message: _extractMessage(error) ?? 'Server error. Please try again.',
        type: ApiErrorType.server,
        statusCode: statusCode,
        rawError: error,
      );
    }

    return ApiException(
      message: _extractMessage(error) ?? 'Unexpected API error occurred.',
      type: ApiErrorType.unknown,
      statusCode: statusCode,
      rawError: error,
    );
  }

  static String? _extractMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final Object? direct = data['message'] ?? data['error'] ?? data['detail'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final Object? errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final Object? first = errors.first;
        if (first is String && first.trim().isNotEmpty) {
          return first.trim();
        }
      }
    }

    return error.message;
  }

  @override
  String toString() {
    if (statusCode == null) {
      return 'ApiException(type: $type, message: $message)';
    }
    return 'ApiException(type: $type, statusCode: $statusCode, message: $message)';
  }
}
