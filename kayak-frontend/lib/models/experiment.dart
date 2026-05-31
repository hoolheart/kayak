import 'package:freezed_annotation/freezed_annotation.dart';

part 'experiment.freezed.dart';
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
@freezed
class Experiment with _$Experiment {
  const factory Experiment({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'method_id') String? methodId,
    required String name,
    String? description,
    required ExperimentStatus status,
    @JsonKey(name: 'owner_type') required String ownerType,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'ended_at') DateTime? endedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Experiment;

  factory Experiment.fromJson(Map<String, dynamic> json) =>
      _$ExperimentFromJson(json);
}
