import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'error_models.dart';

/// Logger for error module
final _errorLogger = Logger(level: Level.warning);

/// Error state containing current error and history
class ErrorState {
  const ErrorState({
    this.currentError,
    this.isNetworkConnected = true,
    this.errorHistory = const [],
  });
  final AppError? currentError;
  final bool isNetworkConnected;
  final List<AppError> errorHistory;

  ErrorState copyWith({
    AppError? currentError,
    bool? isNetworkConnected,
    List<AppError>? errorHistory,
    bool clearCurrentError = false,
  }) {
    return ErrorState(
      currentError:
          clearCurrentError ? null : (currentError ?? this.currentError),
      isNetworkConnected: isNetworkConnected ?? this.isNetworkConnected,
      errorHistory: errorHistory ?? this.errorHistory,
    );
  }
}

/// Central error handling service interface
abstract class ErrorHandlerInterface {
  /// Error state stream
  Stream<ErrorState> get errorStateStream;

  /// Current error state
  ErrorState get currentState;

  /// Handle API error
  void handleApiError(ApiError error);

  /// Handle network error
  void handleNetworkError(NetworkError error);

  /// Handle form error
  void handleFormError(FormError error);

  /// Handle widget error
  void handleWidgetError(WidgetError error);

  /// Clear current error
  void clearError();

  /// Clear all error history
  void clearErrorHistory();
}

/// Toast helper for showing error messages
///
/// This is a simplified version that will be replaced when S2-016 (Global UI Components) is merged.
class Toast {
  Toast._();

  /// Show success toast
  static void showSuccess(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      color: Colors.green,
    );
  }

  /// Show error toast
  static void showError(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.error_outline,
      color: Colors.red,
    );
  }

  /// Show warning toast
  static void showWarning(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.warning_amber_outlined,
      color: Colors.orange,
    );
  }

  /// Show info toast
  static void showInfo(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline,
      color: Colors.blue,
    );
  }

  static void _showToast(
    BuildContext context, {
    required String title,
    String? message,
    required IconData icon,
    required Color color,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (message != null)
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.78),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Central error handling service implementation
class ErrorHandler implements ErrorHandlerInterface {
  ErrorState _state = const ErrorState();
  final _errorController = StreamController<ErrorState>.broadcast();

  @override
  Stream<ErrorState> get errorStateStream => _errorController.stream;

  @override
  ErrorState get currentState => _state;

  @override
  void handleApiError(ApiError error) {
    _emitError(error);

    // Auth errors are handled by route guard, don't show toast
    if (error.isAuthError) {
      return;
    }

    // Validation errors are handled by FormErrorDisplay, don't show toast
    if (error.isValidationError && error.fieldErrors.isNotEmpty) {
      return;
    }

    // Show toast for other errors
    final context = _getContext();
    if (context != null) {
      Toast.showError(
        context,
        title: _getErrorTitle(error),
        message: error.message,
      );
    }
  }

  @override
  void handleNetworkError(NetworkError error) {
    _emitError(error);

    // Don't show toast for server errors
    if (!error.isServerError) {
      final context = _getContext();
      if (context != null) {
        Toast.showError(
          context,
          title: '网络错误',
          message: error.message,
        );
      }
    }
  }

  @override
  void handleFormError(FormError error) {
    _emitError(error);
  }

  @override
  void handleWidgetError(WidgetError error) {
    _emitError(error);
    // Widget errors don't show toast, the ErrorBoundary handles the UI
  }

  @override
  void clearError() {
    _emitState(_state.copyWith(clearCurrentError: true));
  }

  @override
  void clearErrorHistory() {
    _emitState(_state.copyWith(errorHistory: []));
  }

  void _emitError(AppError error) {
    final newHistory = [..._state.errorHistory, error];
    // Keep only the last 10 error records
    final trimmedHistory = newHistory.length > 10
        ? newHistory.sublist(newHistory.length - 10)
        : newHistory;

    _emitState(
      _state.copyWith(
        currentError: error,
        errorHistory: trimmedHistory,
      ),
    );
  }

  void _emitState(ErrorState state) {
    _state = state;
    _errorController.add(state);
  }

  String _getErrorTitle(ApiError error) {
    if (error.isValidationError) return '验证失败';
    if (error.isServerError) return '服务器错误';
    if (error.isAuthError) return '认证失败';
    return '请求失败';
  }

  /// Get the current navigator context
  /// Returns null if no context is available
  BuildContext? _getContext() {
    // This is a simplified implementation
    // In production, you would use a global key to get the context
    try {
      return navigatorKey.currentContext;
    } catch (e) {
      // Log the error for debugging but return null to gracefully degrade
      _errorLogger.e('Error getting navigator context', error: e);
      return null;
    }
  }
}

/// Global navigator key for toast context access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
