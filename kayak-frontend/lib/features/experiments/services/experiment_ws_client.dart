/// WebSocket client for experiment real-time updates
///
/// Manages WebSocket connection for experiment status and log updates
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

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

  bool _isConnected = false;
  Timer? _reconnectTimer;
  String? _wsUrl;
  String? _experimentId;

  /// Stream of raw messages
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of status changes
  Stream<WsStatusChange> get statusChanges => _statusController.stream;

  /// Stream of log entries
  Stream<WsLogEntry> get logEntries => _logController.stream;

  /// Stream of errors
  Stream<String> get errors => _errorController.stream;

  /// Stream of connection status
  Stream<bool> get connectionStatus => _connectionController.stream;

  /// Whether the client is currently connected
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect(String url, {String? experimentId}) async {
    _wsUrl = url;
    _experimentId = experimentId;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_wsUrl == null) return;

    try {
      await _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl!));
      _isConnected = true;
      _connectionController.add(true);

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _isConnected = false;
          _connectionController.add(false);
          _errorController.add(error.toString());
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
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

      _messageController.add(json);

      final type = json['type'] as String? ?? '';
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

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_wsUrl != null) {
        _doConnect();
      }
    });
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _isConnected = false;
    _channel = null;
    _connectionController.add(false);
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
