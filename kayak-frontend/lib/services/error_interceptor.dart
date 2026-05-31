import 'package:dio/dio.dart';

/// ErrorInterceptor — 统一错误处理拦截器
///
/// 将 DioException 中的 HTTP 状态码和网络异常类型映射为
/// 用户可读的中文错误消息。
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _mapError(err);

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        message: message,
        type: err.type,
        response: err.response,
        error: err.error,
      ),
    );
  }

  /// 将 DioException 映射为用户可读的中文错误消息
  String _mapError(DioException err) {
    // HTTP 状态码映射（优先级最高）
    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      final message = _statusCodeMessages[statusCode];
      if (message != null) return message;
    }

    // 网络异常类型映射
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => '连接超时，请检查网络',
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => '网络错误，请检查连接',
      // badResponse 通常有 statusCode，但若不在状态码映射表中则使用此兜底
      DioExceptionType.badResponse => '请求失败，服务器返回错误状态码',
      // 兜底
      _ => '网络错误，请检查连接',
    };
  }
}

/// HTTP 状态码 → 中文错误消息映射表
const Map<int, String> _statusCodeMessages = {
  400: '请求参数有误，请检查输入',
  401: '登录已过期，请重新登录',
  403: '您没有权限执行此操作',
  404: '请求的资源不存在或已被删除',
  409: '资源冲突，可能已存在相同名称的记录',
  422: '数据验证失败，请检查输入',
  500: '服务器内部错误，请稍后重试',
  502: '服务器内部错误，请稍后重试',
  503: '服务器内部错误，请稍后重试',
};
