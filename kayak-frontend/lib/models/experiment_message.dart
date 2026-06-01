// ============================================================
// ExperimentMessage — WebSocket 消息密封类（tagged union）
// ============================================================

/// WebSocket 消息（tagged union，按 `type` 字段区分）。
///
/// 对应后端 WsMessage 枚举：
/// - `type: "status_change"` → [ExperimentMessage.statusChange]
/// - `type: "error"` → [ExperimentMessage.wsError]
sealed class ExperimentMessage {
  const ExperimentMessage();

  /// 创建状态变更消息。
  const factory ExperimentMessage.statusChange(StatusChangeData data) =
      StatusChangeMessage;

  /// 创建错误消息。
  const factory ExperimentMessage.wsError(WsErrorData data) = WsErrorMessage;

  /// 从 JSON Map 解析消息。
  ///
  /// [json] 必须包含 `type` 字段。
  /// 如果 `type` 未知，抛出 [FormatException]。
  factory ExperimentMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'status_change':
        return ExperimentMessage.statusChange(
          StatusChangeData.fromJson(
            json['data'] as Map<String, dynamic>,
          ),
        );
      case 'error':
        return ExperimentMessage.wsError(
          WsErrorData.fromJson(
            json['data'] as Map<String, dynamic>,
          ),
        );
      default:
        throw FormatException('Unknown ExperimentMessage type: $type');
    }
  }

  /// 将消息序列化为 JSON Map。
  Map<String, dynamic> toJson();
}

// ============================================================
// StatusChangeMessage — 状态变更消息
// ============================================================

/// [ExperimentMessage.statusChange] 的具体实现。
class StatusChangeMessage implements ExperimentMessage {
  const StatusChangeMessage(this.data);

  final StatusChangeData data;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'status_change',
    'data': data.toJson(),
  };
}

// ============================================================
// WsErrorMessage — 错误消息
// ============================================================

/// [ExperimentMessage.wsError] 的具体实现。
class WsErrorMessage implements ExperimentMessage {
  const WsErrorMessage(this.data);

  final WsErrorData data;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'error',
    'data': data.toJson(),
  };
}

// ============================================================
// StatusChangeData — 状态变更数据
// ============================================================

/// 对应后端 WsMessage::StatusChange 的 data 字段。
///
/// ```json
/// {
///   "experiment_id": "550e8400-...",
///   "old_status": "LOADED",
///   "new_status": "RUNNING",
///   "operation": "start",
///   "user_id": "user-001",
///   "timestamp": "2026-06-01T10:30:00+00:00"
/// }
/// ```
class StatusChangeData {
  StatusChangeData({
    required this.experimentId,
    required this.oldStatus,
    required this.newStatus,
    required this.operation,
    required this.userId,
    required this.timestamp,
  });

  /// 从 JSON Map 反序列化。
  factory StatusChangeData.fromJson(Map<String, dynamic> json) {
    return StatusChangeData(
      experimentId: json['experiment_id'] as String,
      oldStatus: json['old_status'] as String,
      newStatus: json['new_status'] as String,
      operation: json['operation'] as String,
      userId: json['user_id'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  final String experimentId;
  final String oldStatus; // e.g. "LOADED" (UPPERCASE string)
  final String newStatus; // e.g. "RUNNING" (UPPERCASE string)
  final String operation;
  final String userId;
  final String timestamp;

  Map<String, dynamic> toJson() => {
    'experiment_id': experimentId,
    'old_status': oldStatus,
    'new_status': newStatus,
    'operation': operation,
    'user_id': userId,
    'timestamp': timestamp,
  };
}

// ============================================================
// WsErrorData — WebSocket 错误数据
// ============================================================

/// 对应后端 WsMessage::Error 的 data 字段。
///
/// ```json
/// {
///   "experiment_id": "550e8400-...",
///   "error": "Sensor timeout",
///   "code": 1001
/// }
/// ```
class WsErrorData {
  WsErrorData({
    required this.experimentId,
    required this.error,
    required this.code,
  });

  /// 从 JSON Map 反序列化。
  factory WsErrorData.fromJson(Map<String, dynamic> json) {
    return WsErrorData(
      experimentId: json['experiment_id'] as String,
      error: json['error'] as String,
      code: (json['code'] as num).toInt(),
    );
  }

  final String experimentId;
  final String error;
  final int code;

  Map<String, dynamic> toJson() => {
    'experiment_id': experimentId,
    'error': error,
    'code': code,
  };
}
