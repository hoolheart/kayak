/// API Exceptions
///
/// 定义认证和API相关的异常类型
library;

/// 认证异常
///
/// 当认证失败时抛出（如Token无效、过期等）
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Unauthorized']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// API异常
///
/// 当API请求失败时抛出
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
