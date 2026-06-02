import 'package:dio/dio.dart';

import '../generated/app_localizations.dart';

/// Shared error mapping utility.
///
/// Maps [DioException]s and other errors to localized user-readable strings.
/// Use [map] when you have access to [AppLocalizations] (from a widget context),
/// and [mapFallback] in provider/notifier code where context is not available.
class ErrorMapping {
  /// Maps an error to a localized message using [AppLocalizations].
  static String map(AppLocalizations loc, Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return loc.networkError;

        case DioExceptionType.badResponse:
          return _mapStatusCode(loc, error.response?.statusCode);

        default:
          return loc.errorDefault;
      }
    }

    return error.toString();
  }

  /// Maps an HTTP status code to a localized message.
  static String _mapStatusCode(AppLocalizations loc, int? statusCode) {
    switch (statusCode) {
      case 400:
        return loc.errorBadRequest;
      case 401:
        return loc.sessionExpired;
      case 403:
        return loc.errorForbidden;
      case 404:
        return loc.errorNotFound;
      case 409:
        return loc.errorConflict;
      case 422:
        return loc.errorValidation;
      case 500:
      case 502:
      case 503:
        return loc.errorServer;
      default:
        return '${loc.errorDefault} (code: $statusCode)';
    }
  }

  /// Fallback English mapping for provider/notifier layer
  /// where [AppLocalizations] is not available.
  static String mapFallback(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'Network error, please check your connection and try again';

        case DioExceptionType.badResponse:
          return _mapStatusCodeFallback(error.response?.statusCode);

        default:
          return 'Operation failed, please try again';
      }
    }

    return error.toString();
  }

  static String _mapStatusCodeFallback(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request parameters, please check your input';
      case 401:
        return 'Session expired, please login again';
      case 403:
        return "You don't have permission to perform this action";
      case 404:
        return 'Requested resource not found';
      case 409:
        return 'Resource conflict, please check for duplicates';
      case 422:
        return 'Data validation failed, please check your input';
      case 500:
      case 502:
      case 503:
        return 'Service temporarily unavailable, please try again later';
      default:
        return 'Operation failed, please try again (code: $statusCode)';
    }
  }

  /// Checks whether an error should trigger provider invalidation.
  ///
  /// Returns true for non-transient errors where the provider state
  /// is likely out of sync with the backend.
  static bool shouldInvalidate(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      // 401/403: auth changed; 404: resource deleted; 409: state mismatch
      return statusCode == 401 ||
          statusCode == 403 ||
          statusCode == 404 ||
          statusCode == 409;
    }
    return false;
  }
}
