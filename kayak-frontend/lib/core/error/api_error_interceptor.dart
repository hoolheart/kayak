import 'package:dio/dio.dart';

import 'error_handler.dart';
import 'error_messages.dart';
import 'error_models.dart';

/// Dio error interceptor
///
/// Captures all API errors and transforms them into unified ApiError format.
class ApiErrorInterceptor extends Interceptor {
  ApiErrorInterceptor({required this.errorHandler});
  final ErrorHandlerInterface errorHandler;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = _parseDioError(err);
    errorHandler.handleApiError(apiError);
    handler.next(err);
  }

  /// Parse DioException into ApiError
  ApiError _parseDioError(DioException err) {
    final timestamp = DateTime.now();
    ErrorSeverity severity;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        severity = ErrorSeverity.warning;
        break;
      case DioExceptionType.connectionError:
        severity = ErrorSeverity.error;
        break;
      default:
        severity = ErrorSeverity.error;
    }

    // Try to parse response data for field errors
    List<FieldError> fieldErrors = [];
    if (err.response?.data != null && err.response?.data is Map) {
      final data = err.response!.data as Map<String, dynamic>;
      if (data.containsKey('errors') && data['errors'] is List) {
        fieldErrors = (data['errors'] as List)
            .map((e) => FieldError.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // Extract message from response or error
    final String message = _extractMessage(err);

    return ApiError(
      code: 'API_${err.response?.statusCode ?? 'UNKNOWN'}',
      message: message,
      timestamp: timestamp,
      severity: severity,
      statusCode: err.response?.statusCode,
      fieldErrors: fieldErrors,
      requestPath: err.requestOptions.path,
      requestMethod: err.requestOptions.method,
    );
  }

  /// Extract error message from DioException
  String _extractMessage(DioException err) {
    // Try to get message from response data
    if (err.response?.data != null && err.response?.data is Map) {
      final data = err.response!.data as Map<String, dynamic>;
      if (data.containsKey('message') && data['message'] is String) {
        return data['message'] as String;
      }
      if (data.containsKey('error') && data['error'] is String) {
        return data['error'] as String;
      }
    }

    // Fallback to status code based messages
    if (err.response?.statusCode != null) {
      return ApiErrorMessages.fromStatusCode(err.response!.statusCode!);
    }

    // Fallback to DioException message
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkErrorMessages.timeout;
      case DioExceptionType.sendTimeout:
        return NetworkErrorMessages.timeout;
      case DioExceptionType.receiveTimeout:
        return NetworkErrorMessages.timeout;
      case DioExceptionType.connectionError:
        return NetworkErrorMessages.noConnection;
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return err.message ?? ApiErrorMessages.unknown;
    }
  }
}
