import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_handler.dart';
import 'error_models.dart';
import 'network_error_handler.dart';

/// Global error boundary widget
///
/// Catches widget rendering errors and displays a friendly error page.
class ErrorBoundary extends ConsumerWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.showDetails = false,
    this.showRetry = true,
  });
  final Widget child;

  /// Custom error builder function
  final Widget Function(
    BuildContext context,
    WidgetError error,
    StackTrace? stackTrace,
  )? errorBuilder;

  /// Whether to show error details
  final bool showDetails;

  /// Whether to show retry button
  final bool showRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryWidget(
      errorBuilder: errorBuilder,
      showDetails: showDetails,
      showRetry: showRetry,
      child: child,
    );
  }
}

class ErrorBoundaryWidget extends ConsumerStatefulWidget {
  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorBuilder,
    required this.showDetails,
    required this.showRetry,
  });
  final Widget child;
  final Widget Function(
    BuildContext context,
    WidgetError error,
    StackTrace? stackTrace,
  )? errorBuilder;
  final bool showDetails;
  final bool showRetry;

  @override
  ConsumerState<ErrorBoundaryWidget> createState() =>
      _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends ConsumerState<ErrorBoundaryWidget> {
  late final ErrorHandlerInterface _errorHandler;
  WidgetError? _currentError;
  StackTrace? _currentStackTrace;

  @override
  void initState() {
    super.initState();
    _errorHandler = ref.read(errorHandlerProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// Error handling method
  void _handleError(Object error, StackTrace stackTrace) {
    // Record error
    _errorHandler.handleWidgetError(
      WidgetError(
        code: 'WIDGET_ERROR',
        message: error.toString(),
        timestamp: DateTime.now(),
        severity: ErrorSeverity.critical,
        widgetName: 'Unknown',
        stackTrace: stackTrace.toString(),
      ),
    );

    setState(() {
      _currentError = WidgetError(
        code: 'WIDGET_ERROR',
        message: error.toString(),
        timestamp: DateTime.now(),
        severity: ErrorSeverity.critical,
        widgetName: 'Unknown',
        stackTrace: stackTrace.toString(),
      );
      _currentStackTrace = stackTrace;
    });
  }

  /// Reset error state
  void _resetError() {
    setState(() {
      _currentError = null;
      _currentStackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentError != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          _currentError!,
          _currentStackTrace,
        );
      }
      return _DefaultErrorPage(
        error: _currentError!,
        stackTrace: _currentStackTrace,
        showDetails: widget.showDetails,
        showRetry: widget.showRetry,
        onRetry: _resetError,
      );
    }

    return _ErrorCatch(
      onError: _handleError,
      child: widget.child,
    );
  }
}

/// Error catching widget that uses FlutterError.onError
class _ErrorCatch extends StatefulWidget {
  const _ErrorCatch({
    required this.child,
    required this.onError,
  });
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<_ErrorCatch> createState() => _ErrorCatchState();
}

class _ErrorCatchState extends State<_ErrorCatch> {
  void Function(FlutterErrorDetails)? _originalOnError;

  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
  }

  void _setupErrorHandling() {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  @override
  void dispose() {
    FlutterError.onError = _originalOnError;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Default error page widget
class _DefaultErrorPage extends StatelessWidget {
  const _DefaultErrorPage({
    required this.error,
    this.stackTrace,
    required this.showDetails,
    required this.showRetry,
    required this.onRetry,
  });
  final WidgetError error;
  final StackTrace? stackTrace;
  final bool showDetails;
  final bool showRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            // Error title
            Text(
              '出现了一些问题',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Error message
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (showDetails && stackTrace != null) ...[
              const SizedBox(height: 24),
              // Stack trace
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  stackTrace.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (showRetry) ...[
              const SizedBox(height: 24),
              // Retry button
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
