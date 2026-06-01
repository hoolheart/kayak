import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/experiment_message.dart';

/// WebSocket 连接状态
enum WsConnectionState {
  /// 已断开（初始/手动断开）
  disconnected,

  /// 首次连接中
  connecting,

  /// 已连接
  connected,

  /// 自动重连中
  reconnecting,

  /// 重连达到上限，已失败
  failed,
}

/// WsService — WebSocket 连接管理
///
/// 管理到后端的 WebSocket 连接，提供自动重连和消息解析。
///
/// 连接地址格式：`ws://localhost:8080/ws/experiments/{experimentId}?token={token}`
///
/// 自动重连采用指数退避策略：
/// - 第 1 次重连：1 秒
/// - 第 2 次重连：2 秒
/// - 第 3 次重连：4 秒
/// - 第 4 次重连：8 秒
/// - 第 5 次重连：8 秒（上限）
/// - 最多尝试 5 次重连
class WsService {
  /// 最大重连尝试次数
  static const int maxReconnectAttempts = 5;

  /// 最大重连延迟（上限）
  static const Duration maxReconnectDelay = Duration(seconds: 8);

  WebSocketChannel? _channel;
  StreamController<ExperimentMessage>? _controller;
  StreamController<WsConnectionState>? _connectionStateController;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _currentExperimentId;
  String? _currentToken;
  bool _disposed = false;

  /// 当前连接状态
  WsConnectionState _currentConnectionState = WsConnectionState.disconnected;

  /// 连接状态流
  ///
  /// 每次状态变化时发出新值。
  /// 使用 [currentConnectionState] 获取当前状态快照。
  Stream<WsConnectionState> get connectionState =>
      _connectionStateController?.stream ?? const Stream.empty();

  /// 当前连接状态（快照）
  WsConnectionState get currentConnectionState => _currentConnectionState;

  /// 当前重连尝试次数
  int get reconnectAttempts => _reconnectAttempts;

  /// 是否已建立 WebSocket 连接
  bool get isConnected =>
      _channel != null && _currentConnectionState == WsConnectionState.connected;

  /// 连接 WebSocket，返回消息流。
  ///
  /// [experimentId] 试验 ID
  /// [token] JWT Token（作为查询参数传递）
  /// 返回 [Stream]<[ExperimentMessage]> 消息流
  ///
  /// 如果已连接到相同 [experimentId]，返回现有流。
  /// 如果连接到不同 [experimentId]，先断开旧连接。
  Stream<ExperimentMessage> connect(
    String experimentId,
    String token,
  ) {
    // 如果已有相同 ID 的连接，直接返回现有流
    if (_currentExperimentId == experimentId &&
        _channel != null &&
        _controller != null &&
        !_controller!.isClosed) {
      return _controller!.stream;
    }

    // 如果有旧连接（不同 ID），先断开
    if (_channel != null) {
      disconnect();
    }

    _currentExperimentId = experimentId;
    _currentToken = token;
    _resetReconnect();

    // 创建状态流控制器（广播模式）
    _connectionStateController =
        StreamController<WsConnectionState>.broadcast();

    // 创建消息流控制器（广播模式，支持多订阅）
    _controller = StreamController<ExperimentMessage>.broadcast();

    // 开始连接
    _setConnectionState(WsConnectionState.connecting);

    _tryConnect(experimentId, token);

    return _controller!.stream;
  }

  /// 手动断开 WebSocket 连接。
  ///
  /// 关闭底层 WebSocket，取消待处理的重连定时器，重置内部状态。
  void disconnect() {
    _disposed = true;
    _cleanup();
    _setConnectionState(WsConnectionState.disconnected);
    _disposed = false; // 重置，允许后续重新连接
  }

  /// 手动重新连接（在 [WsConnectionState.failed] 状态下调用）。
  ///
  /// 重置重连计数器并重新建立连接。
  void reconnect() {
    if (_currentExperimentId == null || _currentToken == null) return;

    // 清理旧连接和定时器
    _cleanup();

    _resetReconnect();

    // 创建新的状态流控制器
    _connectionStateController =
        StreamController<WsConnectionState>.broadcast();

    // 创建新的 StreamController
    _controller = StreamController<ExperimentMessage>.broadcast();

    // 重新连接
    _setConnectionState(WsConnectionState.connecting);
    _tryConnect(_currentExperimentId!, _currentToken!);
  }

  // ================================================================
  // 内部方法
  // ================================================================

  /// 更新连接状态并发布到流。
  void _setConnectionState(WsConnectionState state) {
    _currentConnectionState = state;
    _connectionStateController?.add(state);
  }

  /// 计算下次重连延迟。
  ///
  /// 指数退避策略：2^(attempt-1) 秒，上限 8 秒。
  Duration _nextReconnectDelay() {
    final seconds = pow(2, _reconnectAttempts - 1).toInt();
    final capped = seconds > maxReconnectDelay.inSeconds
        ? maxReconnectDelay.inSeconds
        : seconds;
    return Duration(seconds: capped);
  }

  /// 尝试建立 WebSocket 连接。
  Future<void> _tryConnect(String experimentId, String token) async {
    try {
      final uri = Uri.parse('ws://localhost:8080/ws/experiments/$experimentId')
          .replace(queryParameters: {'token': token});

      _channel = WebSocketChannel.connect(uri);

      // 等待连接建立确认
      await _channel!.ready;

      // 如果已标记为 disposed（disconnect 在连接建立中被调用），清理并返回
      if (_disposed) {
        _cleanup();
        return;
      }

      // 连接成功
      _resetReconnect();
      _setConnectionState(WsConnectionState.connected);

      // 订阅消息流
      _channel!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: (Object error) {
          // 单条消息解析失败不关闭连接
          _controller?.addError(error);
        },
        cancelOnError: false, // 重要：不让单个错误关闭流
      );
    } catch (e) {
      // 连接建立失败，触发重连
      _onDone();
    }
  }

  /// 处理收到的消息。
  void _onMessage(dynamic message) {
    if (_controller == null || _controller!.isClosed) return;

    try {
      if (message is String) {
        final json = jsonDecode(message) as Map<String, dynamic>;
        final experimentMessage = ExperimentMessage.fromJson(json);
        _controller!.add(experimentMessage);
      }
    } catch (e) {
      // 解析失败不崩溃，也不关闭 Stream
      // 可选择在 onError 中报告
    }
  }

  /// 连接关闭处理。
  void _onDone() {
    _channel = null;

    if (_disposed) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      // 重连达到上限，标记为失败
      _setConnectionState(WsConnectionState.failed);
      _controller?.close();
      return;
    }

    // 启动重连
    _reconnectAttempts++;
    _setConnectionState(WsConnectionState.reconnecting);

    final delay = _nextReconnectDelay();
    _reconnectTimer = Timer(delay, () {
      if (!_disposed &&
          _currentExperimentId != null &&
          _currentToken != null) {
        _tryConnect(_currentExperimentId!, _currentToken!);
      }
    });
  }

  /// 重置重连计数器。
  void _resetReconnect() {
    _reconnectAttempts = 0;
  }

  /// 清理资源。
  ///
  /// 关闭 WebSocket、取消定时器、关闭 StreamController。
  void _cleanup() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      _channel?.sink.close();
    } catch (_) {
      // 忽略关闭时的异常
    }
    _channel = null;

    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;

    if (_connectionStateController != null &&
        !_connectionStateController!.isClosed) {
      _connectionStateController!.close();
    }
    _connectionStateController = null;
  }
}
