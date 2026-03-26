import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/core/error/error_models.dart';

void main() {
  group('ErrorSeverity', () {
    test('should have correct values', () {
      expect(ErrorSeverity.values.length, 4);
      expect(ErrorSeverity.info.index, 0);
      expect(ErrorSeverity.warning.index, 1);
      expect(ErrorSeverity.error.index, 2);
      expect(ErrorSeverity.critical.index, 3);
    });
  });

  group('NetworkErrorType', () {
    test('should have correct values', () {
      expect(NetworkErrorType.values.length, 4);
      expect(NetworkErrorType.noConnection.index, 0);
      expect(NetworkErrorType.timeout.index, 1);
      expect(NetworkErrorType.serverError.index, 2);
      expect(NetworkErrorType.unknown.index, 3);
    });
  });

  group('AppError', () {
    test('toString should return formatted error', () {
      final error = ApiError(
        code: 'API_400',
        message: 'Bad request',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.warning,
        statusCode: 400,
      );

      expect(error.toString().contains('Bad request'), true);
    });
  });

  group('ApiError', () {
    test('isAuthError returns true for 401', () {
      final error = ApiError(
        code: 'API_401',
        message: 'Unauthorized',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.error,
        statusCode: 401,
      );

      expect(error.isAuthError, true);
    });

    test('isAuthError returns true for 403', () {
      final error = ApiError(
        code: 'API_403',
        message: 'Forbidden',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.error,
        statusCode: 403,
      );

      expect(error.isAuthError, true);
    });

    test('isAuthError returns false for 400', () {
      final error = ApiError(
        code: 'API_400',
        message: 'Bad request',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.warning,
        statusCode: 400,
      );

      expect(error.isAuthError, false);
    });

    test('isValidationError returns true for 400', () {
      final error = ApiError(
        code: 'API_400',
        message: 'Bad request',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.warning,
        statusCode: 400,
      );

      expect(error.isValidationError, true);
    });

    test('isServerError returns true for 500', () {
      final error = ApiError(
        code: 'API_500',
        message: 'Server error',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.error,
        statusCode: 500,
      );

      expect(error.isServerError, true);
    });

    test('isServerError returns true for 503', () {
      final error = ApiError(
        code: 'API_503',
        message: 'Service unavailable',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.error,
        statusCode: 503,
      );

      expect(error.isServerError, true);
    });

    test('isServerError returns false for 400', () {
      final error = ApiError(
        code: 'API_400',
        message: 'Bad request',
        timestamp: DateTime.now(),
        severity: ErrorSeverity.warning,
        statusCode: 400,
      );

      expect(error.isServerError, false);
    });
  });

  group('NetworkError', () {
    test('noConnection factory creates correct error', () {
      final error = NetworkError.noConnection();

      expect(error.type, NetworkErrorType.noConnection);
      expect(error.severity, ErrorSeverity.error);
      expect(error.message.contains('网络'), true);
    });

    test('timeout factory creates correct error', () {
      final error = NetworkError.timeout();

      expect(error.type, NetworkErrorType.timeout);
      expect(error.severity, ErrorSeverity.warning);
      expect(error.message.contains('超时'), true);
    });

    test('serverError factory creates correct error', () {
      final error = NetworkError.serverError();

      expect(error.type, NetworkErrorType.serverError);
      expect(error.severity, ErrorSeverity.error);
      expect(error.isServerError, true);
    });
  });

  group('FieldError', () {
    test('fromJson creates correct FieldError', () {
      final json = {
        'field': 'email',
        'message': 'Invalid email',
        'code': 'INVALID_EMAIL',
      };

      final error = FieldError.fromJson(json);

      expect(error.field, 'email');
      expect(error.message, 'Invalid email');
      expect(error.code, 'INVALID_EMAIL');
    });

    test('toJson creates correct map', () {
      const error = FieldError(
        field: 'email',
        message: 'Invalid email',
        code: 'INVALID_EMAIL',
      );

      final json = error.toJson();

      expect(json['field'], 'email');
      expect(json['message'], 'Invalid email');
      expect(json['code'], 'INVALID_EMAIL');
    });
  });
}
