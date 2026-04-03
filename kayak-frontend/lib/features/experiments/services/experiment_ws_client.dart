/// WebSocket client for experiment real-time updates
///
/// Manages WebSocket connection for experiment status and log updates
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket connection states (C-04 fix)
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// WebSocket message types
enum WsMessageType {
  statusChange,
  log,
  error,
  unknown,
}

/// WebSocket log entry
class WsLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;

  const WsLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  factory WsLogEntry.fromJson(Map<String, dynamic> json) {
    return WsLogEntry(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
    );
  }
}

/// WebSocket status change
class WsStatusChange {
  final String experimentId;
  final String oldStatus;
  final String newStatus;
  final String operation;
  final DateTime timestamp;

  const WsStatusChange({
    required this.experimentId,
    required this.oldStatus,
    required this.newStatus,
    required this.operation,
    required this.timestamp,
  });

  factory WsStatusChange.fromJson(Map<String, dynamic> json) {
    return WsStatusChange(
      experimentId: json['experiment_id'] as String? ?? '',
      oldStatus: json['old_status'] as String? ?? '',
      newStatus: json['new_status'] as String? ?? '',
      operation: json['operation'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// WebSocket client for experiment updates
class ExperimentWebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<WsStatusChange>.broadcast();
  final _logController = StreamController<WsLogEntry>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // C-04 fix: Use WsConnectionState enum with exponential backoff and max retries
  WsConnectionState _connectionState = WsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _baseDelaySeconds = 1;
  static const int _maxDelaySeconds = 30;

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _wsUrl;
  String? _experimentId;

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _heartbeatTimeout = Duration(seconds: 60);
  DateTime? _lastPongReceived;

  /// Stream of raw messages
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of status changes
  Stream<WsStatusChange> get statusChanges => _statusController.stream;

  /// Stream of log entries
  Stream<WsLogEntry> get logEntries => _logController.stream;

  /// Stream of errors
  Stream<String> get errors => _errorController.stream;

  /// Stream of connection status (keeps backward compatibility - true if connected)
  Stream<bool> get connectionStatus => _connectionController.stream;

  /// Current connection state (C-04 fix)
  WsConnectionState get connectionState => _connectionState;

  /// Whether the client is currently connected (backward compatibility)
  bool get isConnected => _connectionState == WsConnectionState.connected;

  /// Connect to WebSocket server
  Future<void> connect(String url, {String? experimentId}) async {
    _wsUrl = url;
    _experimentId = experimentId;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_wsUrl == null) return;

    _connectionState = WsConnectionState.connecting;
    _notifyConnectionStatus();

    try {
      await _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl!));
      _connectionState = WsConnectionState.connected;
      _reconnectAttempts = 0; // Reset on successful connection
      _notifyConnectionStatus();
      _startHeartbeat();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _connectionState = WsConnectionState.reconnecting;
          _notifyConnectionStatus();
          _errorController.add(error.toString());
          _scheduleReconnect();
        },
        onDone: () {
          _connectionState = WsConnectionState.reconnecting;
          _notifyConnectionStatus();
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _connectionState = WsConnectionState.reconnecting;
      _notifyConnectionStatus();
      _errorController.add(e.toString());
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> json;
      if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        json = data;
      } else {
        return;
      }

      // Handle pong response for heartbeat
      final type = json['type'] as String? ?? '';
      if (type == 'pong') {
        _lastPongReceived = DateTime.now();
        return;
      }

      _messageController.add(json);

      switch (type) {
        case 'status_change':
          _statusController.add(WsStatusChange.fromJson(json));
          break;
        case 'log':
          _logController.add(WsLogEntry.fromJson(json));
          break;
        case 'error':
          _errorController.add(json['message'] as String? ?? 'Unknown error');
          break;
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  /// C-04 fix: Exponential backoff reconnect with max attempts
  void _scheduleReconnect() {
    // Check if max attempts reached
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _connectionState = WsConnectionState.failed;
      _notifyConnectionStatus();
      _errorController.add(
          'WebSocket connection failed after $_maxReconnectAttempts attempts');
      return;
    }

    _reconnectTimer?.cancel();

    // Calculate delay with exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (capped)
    final delaySeconds = (_baseDelaySeconds * (1 << _reconnectAttempts))
        .clamp(1, _maxDelaySeconds);
    _reconnectAttempts++;

    _connectionState = WsConnectionState.reconnecting;
    _notifyConnectionStatus();

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_wsUrl != null && _connectionState != WsConnectionState.failed) {
        _doConnect();
      }
    });
  }

  /// C-04 fix: Heartbeat mechanism
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _lastPongReceived = DateTime.now();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_connectionState != WsConnectionState.connected) {
        timer.cancel();
        return;
      }

      // Check if we received pong within timeout
      if (_lastPongReceived != null) {
        final elapsed = DateTime.now().difference(_lastPongReceived!);
        if (elapsed > _heartbeatTimeout) {
          // Connection is stale, force reconnect
          _connectionState = WsConnectionState.reconnecting;
          _notifyConnectionStatus();
          _scheduleReconnect();
          timer.cancel();
          return;
        }
      }

      // Send ping
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        // Ignore send errors
      }
    });
  }

  void _notifyConnectionStatus() {
    _connectionController.add(_connectionState == WsConnectionState.connected);
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _channel?.sink.close();
    _connectionState = WsConnectionState.disconnected;
    _channel = null;
    _notifyConnectionStatus();
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    _logController.close();
    _errorController.close();
    _connectionController.close();
  }
}
