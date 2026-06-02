// ignore_for_file: sort_constructors_first

import 'package:json_annotation/json_annotation.dart';

part 'experiment.g.dart';

// ============================================================
// ExperimentStatus — 试验状态枚举（UPPERCASE 序列化）
// ============================================================
enum ExperimentStatus {
  @JsonValue('IDLE')
  idle,
  @JsonValue('LOADED')
  loaded,
  @JsonValue('RUNNING')
  running,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('ABORTED')
  aborted,
}

// ============================================================
// Experiment — 试验实体
// ============================================================
@JsonSerializable()
class Experiment {

  const Experiment({
    required this.id,
    required this.userId,
    this.methodId,
    required this.name,
    this.description,
    this.errorMessage,
    required this.status,
    required this.ownerType,
    required this.ownerId,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) =>
      _$ExperimentFromJson(json);
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'method_id')
  final String? methodId;
  final String name;
  final String? description;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  final ExperimentStatus status;
  @JsonKey(name: 'owner_type')
  final String ownerType;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  Map<String, dynamic> toJson() => _$ExperimentToJson(this);

  Experiment copyWith({
    String? id,
    String? userId,
    String? methodId,
    String? name,
    String? description,
    String? errorMessage,
    ExperimentStatus? status,
    String? ownerType,
    String? ownerId,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Experiment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      methodId: methodId ?? this.methodId,
      name: name ?? this.name,
      description: description ?? this.description,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// CreateExperimentRequest — 创建试验请求
// ============================================================

/// 创建试验请求体
///
/// 对应后端 CreateExperimentRequest：
/// - name（必填）：试验名称
/// - methodId（可选）：关联的方法 ID
/// - description（可选）：试验描述
/// - parameters（可选）：方法参数键值对
class CreateExperimentRequest {
  const CreateExperimentRequest({
    required this.name,
    this.methodId,
    this.description,
    this.parameters,
  });

  final String name;
  final String? methodId;
  final String? description;
  final Map<String, dynamic>? parameters;

  factory CreateExperimentRequest.fromJson(Map<String, dynamic> json) {
    return CreateExperimentRequest(
      name: json['name'] as String,
      methodId: json['method_id'] as String?,
      description: json['description'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'name': name};
    if (methodId != null) data['method_id'] = methodId;
    if (description != null) data['description'] = description;
    if (parameters != null && parameters!.isNotEmpty) {
      data['parameters'] = parameters;
    }
    return data;
  }
}

// ============================================================
// ExperimentControlDto — 控制操作响应 DTO
// ============================================================

/// 控制操作（load/start/pause/resume/stop）成功后返回的完整试验实体。
///
/// 与 [Experiment] 的区别：所有日期值为 String 类型（RFC 3339 格式），
/// 而 Experiment 解析为 DateTime。
class ExperimentControlDto {
  const ExperimentControlDto({
    required this.id,
    required this.name,
    required this.status,
    this.methodId,
    this.description,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String status; // e.g. "RUNNING" (UPPERCASE)
  final String? methodId;
  final String? description;
  final String? startedAt; // RFC 3339 string
  final String? endedAt; // RFC 3339 string
  final String createdAt; // RFC 3339 string
  final String updatedAt; // RFC 3339 string

  factory ExperimentControlDto.fromJson(Map<String, dynamic> json) {
    return ExperimentControlDto(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      methodId: json['method_id'] as String?,
      description: json['description'] as String?,
      startedAt: json['started_at'] as String?,
      endedAt: json['ended_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'method_id': methodId,
      'description': description,
      'started_at': startedAt,
      'ended_at': endedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// 将字符串状态映射为 [ExperimentStatus] 枚举。
  ExperimentStatus get statusEnum => ExperimentStatus.values.firstWhere(
    (e) => e.name.toUpperCase() == status,
    orElse: () => ExperimentStatus.idle,
  );

  bool get isRunning => status == 'RUNNING';
  bool get isPaused => status == 'PAUSED';
  bool get isLoaded => status == 'LOADED';
  bool get isIdle => status == 'IDLE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isAborted => status == 'ABORTED';
}

// ============================================================
// ExperimentStatusDto — 状态查询响应 DTO
// ============================================================

/// GET /api/v1/experiments/{id}/status 的响应 DTO。
///
/// 是 [ExperimentControlDto] 的子集，不包含 description 和 created_at。
class ExperimentStatusDto {
  const ExperimentStatusDto({
    required this.id,
    required this.name,
    required this.status,
    this.methodId,
    this.startedAt,
    this.endedAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String status; // e.g. "RUNNING" (UPPERCASE)
  final String? methodId;
  final String? startedAt;
  final String? endedAt;
  final String updatedAt;

  factory ExperimentStatusDto.fromJson(Map<String, dynamic> json) {
    return ExperimentStatusDto(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      methodId: json['method_id'] as String?,
      startedAt: json['started_at'] as String?,
      endedAt: json['ended_at'] as String?,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'method_id': methodId,
      'started_at': startedAt,
      'ended_at': endedAt,
      'updated_at': updatedAt,
    };
  }
}

// ============================================================
// StatusChange — 状态变更历史记录
// ============================================================

/// 试验状态变更日志条目。
///
/// 对应后端 StateChangeLogDto，记录试验生命周期中每次状态变更。
class StatusChange {
  const StatusChange({
    required this.id,
    required this.experimentId,
    required this.previousState,
    required this.newState,
    required this.operation,
    required this.userId,
    required this.timestamp,
    this.errorMessage,
  });

  final String id;
  final String experimentId;
  final String previousState; // e.g. "LOADED" (UPPERCASE)
  final String newState; // e.g. "RUNNING" (UPPERCASE)
  final String operation;
  final String userId;
  final String timestamp; // RFC 3339 string
  final String? errorMessage;

  factory StatusChange.fromJson(Map<String, dynamic> json) {
    return StatusChange(
      id: json['id'] as String,
      experimentId: json['experiment_id'] as String,
      previousState: json['previous_state'] as String,
      newState: json['new_state'] as String,
      operation: json['operation'] as String,
      userId: json['user_id'] as String,
      timestamp: json['timestamp'] as String,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'experiment_id': experimentId,
      'previous_state': previousState,
      'new_state': newState,
      'operation': operation,
      'user_id': userId,
      'timestamp': timestamp,
      'error_message': errorMessage,
    };
  }

  /// 便利方法：获取枚举形式的旧/新状态。
  ExperimentStatus get previousStatusEnum => _parseStatus(previousState);
  ExperimentStatus get newStatusEnum => _parseStatus(newState);

  static ExperimentStatus _parseStatus(String s) =>
      ExperimentStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == s,
        orElse: () => ExperimentStatus.idle,
      );
}

// ============================================================
// DataQueryParams — 数据查询参数
// ============================================================

/// 试验时序数据查询参数。
class DataQueryParams {
  const DataQueryParams({
    this.pointIds,
    this.startTime,
    this.endTime,
    this.downsample,
  });

  final List<String>? pointIds;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? downsample;

  factory DataQueryParams.fromJson(Map<String, dynamic> json) {
    return DataQueryParams(
      pointIds: (json['point_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      downsample: json['downsample'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (pointIds != null) data['point_ids'] = pointIds;
    if (startTime != null) {
      data['start_time'] = startTime!.toUtc().toIso8601String();
    }
    if (endTime != null) {
      data['end_time'] = endTime!.toUtc().toIso8601String();
    }
    if (downsample != null) data['downsample'] = downsample;
    return data;
  }
}

// ============================================================
// TimeSeriesData — 时序数据响应
// ============================================================

/// 试验时序数据查询响应。
class TimeSeriesData {
  const TimeSeriesData({
    required this.deviceId,
    required this.timestamps,
    required this.values,
  });

  final String deviceId;
  final List<DateTime> timestamps;
  final Map<String, List<double?>> values; // pointId → values[]

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) {
    return TimeSeriesData(
      deviceId: json['device_id'] as String,
      timestamps: (json['timestamps'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      values: (json['values'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((e) => e as double?)
              .toList(),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'timestamps': timestamps.map((e) => e.toUtc().toIso8601String()).toList(),
      'values': values.map(
        (key, value) => MapEntry(key, value.map((e) => e).toList()),
      ),
    };
  }
}
