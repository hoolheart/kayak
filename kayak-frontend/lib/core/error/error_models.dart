/// Error severity levels
enum ErrorSeverity {
  info, // Information message
  warning, // Warning
  error, // Error
  critical, // Critical error
}

/// Network error types
enum NetworkErrorType {
  noConnection, // No network connection
  timeout, // Connection timeout
  serverError, // Server error
  unknown, // Unknown error
}

/// Application error base class
abstract class AppError {
  const AppError({
    required this.code,
    required this.message,
    required this.timestamp,
    required this.severity,
    this.metadata = const {},
  });
  final String code;
  final String message;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final Map<String, dynamic> metadata;

  @override
  String toString() => 'AppError($code): $message';
}

/// Field-level validation error
class FieldError {
  const FieldError({
    required this.field,
    required this.message,
    this.code,
  });

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field'] as String,
      message: json['message'] as String,
      code: json['code'] as String?,
    );
  }
  final String field;
  final String message;
  final String? code;

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      if (code != null) 'code': code,
    };
  }
}

/// API error
class ApiError extends AppError {
  const ApiError({
    required super.code,
    required super.message,
    required super.timestamp,
    required super.severity,
    super.metadata,
    this.statusCode,
    this.fieldErrors = const [],
    this.requestPath,
    this.requestMethod,
  });

  /// Create from HTTP status code
  factory ApiError.fromStatusCode({
    required int statusCode,
    required String message,
    String? requestPath,
    String? requestMethod,
  }) {
    final severity = switch (statusCode) {
      >= 500 => ErrorSeverity.error,
      >= 400 => ErrorSeverity.warning,
      _ => ErrorSeverity.info,
    };

    return ApiError(
      code: 'API_$statusCode',
      message: message,
      timestamp: DateTime.now(),
      severity: severity,
      statusCode: statusCode,
      requestPath: requestPath,
      requestMethod: requestMethod,
    );
  }
  final int? statusCode;
  final List<FieldError> fieldErrors;
  final String? requestPath;
  final String? requestMethod;

  /// Check if this is an authentication error (401/403)
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Check if this is a validation error (400)
  bool get isValidationError => statusCode == 400;

  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiError($statusCode, $code): $message at $requestPath';
}

/// Network error
class NetworkError extends AppError {
  const NetworkError({
    required super.code,
    required super.message,
    required super.timestamp,
    required super.severity,
    super.metadata,
    required this.type,
    this.isServerError = false,
  });

  /// Create no connection error
  factory NetworkError.noConnection() {
    return NetworkError(
      code: 'NETWORK_NO_CONNECTION',
      message: '网络连接已断开，请检查您的网络设置',
      timestamp: DateTime.now(),
      severity: ErrorSeverity.error,
      type: NetworkErrorType.noConnection,
    );
  }

  /// Create timeout error
  factory NetworkError.timeout() {
    return NetworkError(
      code: 'NETWORK_TIMEOUT',
      message: '请求超时，请稍后重试',
      timestamp: DateTime.now(),
      severity: ErrorSeverity.warning,
      type: NetworkErrorType.timeout,
    );
  }

  /// Create server error
  factory NetworkError.serverError() {
    return NetworkError(
      code: 'NETWORK_SERVER_ERROR',
      message: '服务器错误，请稍后重试',
      timestamp: DateTime.now(),
      severity: ErrorSeverity.error,
      type: NetworkErrorType.serverError,
      isServerError: true,
    );
  }
  final NetworkErrorType type;
  final bool isServerError;
}

/// Widget rendering error
class WidgetError extends AppError {
  const WidgetError({
    required super.code,
    required super.message,
    required super.timestamp,
    required super.severity,
    required this.widgetName,
    this.stackTrace,
    super.metadata,
  });
  final String widgetName;
  final String? stackTrace;

  @override
  String toString() => 'WidgetError($widgetName): $message';
}

/// Form validation error
class FormError extends AppError {
  const FormError({
    required super.code,
    required super.message,
    required super.timestamp,
    required super.severity,
    required this.field,
    this.errorCode,
    this.messages = const [],
    super.metadata,
  });
  final String field;
  final String? errorCode;
  final List<String> messages;
}
