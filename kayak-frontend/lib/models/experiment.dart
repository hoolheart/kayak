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
