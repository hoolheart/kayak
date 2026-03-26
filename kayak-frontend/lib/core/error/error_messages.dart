// Standardized error messages
//
// This module provides centralized error message templates
// for consistent user-facing error messages across the application.

// API error messages
class ApiErrorMessages {
  ApiErrorMessages._();

  /// Generic API error message
  static const String generic = '请求失败，请稍后重试';

  /// Validation error message
  static const String validationFailed = '验证失败';

  /// Authentication error message
  static const String authFailed = '认证失败，请重新登录';

  /// Authorization error message
  static const String forbidden = '您没有权限执行此操作';

  /// Not found error message
  static const String notFound = '请求的资源不存在';

  /// Server error message
  static const String serverError = '服务器错误，请稍后重试';

  /// Network error message
  static const String networkError = '网络连接异常，请检查网络设置';

  /// Timeout error message
  static const String timeout = '请求超时，请稍后重试';

  /// Unknown error message
  static const String unknown = '发生了未知错误';

  /// Get message by HTTP status code
  static String fromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 => validationFailed,
      401 => authFailed,
      403 => forbidden,
      404 => notFound,
      >= 500 => serverError,
      _ => generic,
    };
  }
}

/// Form validation error messages
class FormErrorMessages {
  FormErrorMessages._();

  /// Required field message
  static String required(String fieldName) => '$fieldName不能为空';

  /// Email format message
  static const String invalidEmail = '请输入有效的邮箱地址';

  /// Min length message
  static String minLength(String fieldName, int min) =>
      '$fieldName长度不能少于$min个字符';

  /// Max length message
  static String maxLength(String fieldName, int max) =>
      '$fieldName长度不能超过$max个字符';

  /// Pattern mismatch message
  static String pattern(String fieldName) => '$fieldName格式不正确';

  /// Match field message
  static String mismatch(String fieldName, String matchFieldName) =>
      '$fieldName与$matchFieldName不匹配';
}

/// Network error messages
class NetworkErrorMessages {
  NetworkErrorMessages._();

  /// No connection message
  static const String noConnection = '网络连接已断开，请检查您的网络设置';

  /// Connection restored message
  static const String connectionRestored = '网络连接已恢复';

  /// Timeout message
  static const String timeout = '请求超时，请稍后重试';

  /// Server error message
  static const String serverError = '服务器错误，请稍后重试';
}
