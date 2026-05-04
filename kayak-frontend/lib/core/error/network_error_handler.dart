import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_handler.dart';
import 'error_models.dart';

/// Network error handler
///
/// Monitors network connectivity status and handles network errors.
class NetworkErrorHandler {
  NetworkErrorHandler({
    required ErrorHandlerInterface errorHandler,
    Connectivity? connectivity,
  })  : _errorHandler = errorHandler,
        _connectivity = connectivity ?? Connectivity();
  final ErrorHandlerInterface _errorHandler;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  /// Current network connection status
  bool get isConnected => _isConnected;

  /// Network status change stream
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;
  final _connectivityStreamController = StreamController<bool>.broadcast();

  /// Initialize network monitoring
  Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _updateConnectivity(result);

    // Start listening for status changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );
  }

  /// Update connection status
  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    // Notify on status change
    if (wasConnected && !_isConnected) {
      // Connection lost
      _errorHandler.handleNetworkError(NetworkError.noConnection());
    } else if (!wasConnected && _isConnected) {
      // Connection restored
      final context = navigatorKey.currentContext;
      if (context != null) {
        Toast.showSuccess(
          context,
          title: '网络已恢复',
          message: '网络连接已恢复，请继续操作',
        );
      }
    }

    _connectivityStreamController.add(_isConnected);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityStreamController.close();
  }
}

/// Provider for network error handler
final networkErrorHandlerProvider = Provider<NetworkErrorHandler>((ref) {
  final handler = NetworkErrorHandler(
    errorHandler: ref.read(errorHandlerProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});

/// Provider for network connection status
final networkConnectedProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(networkErrorHandlerProvider);
  return handler.connectivityStream;
});

/// Provider for error handler
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

/// Network status Banner widget
///
/// Displays at the top of pages when network is disconnected.
class NetworkBanner extends ConsumerWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnectedAsync = ref.watch(networkConnectedProvider);

    return isConnectedAsync.when(
      data: (isConnected) {
        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Theme.of(context).colorScheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '网络连接已断开，部分功能可能不可用',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
