import 'package:dio/dio.dart';

import 'error_handler.dart';
import 'error_models.dart';

/// Dio error interceptor
///
/// Captures all API errors and transforms them into unified ApiError format.
class ApiErrorInterceptor extends Interceptor {
  final ErrorHandlerInterface errorHandler;

  ApiErrorInterceptor({required this.errorHandler});

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
      final statusCode = err.response!.statusCode!;
      return switch (statusCode) {
        400 => '请求参数错误',
        401 => '认证已过期，请重新登录',
        403 => '没有权限访问此资源',
        404 => '请求的资源不存在',
        >= 500 => '服务器错误，请稍后重试',
        _ => '请求失败',
      };
    }

    // Fallback to DioException message
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送请求超时';
      case DioExceptionType.receiveTimeout:
        return '接收响应超时';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return err.message ?? '请求失败';
    }
  }
}
