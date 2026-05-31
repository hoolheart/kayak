// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Experiment _$ExperimentFromJson(Map<String, dynamic> json) => Experiment(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  methodId: json['method_id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  status: $enumDecode(_$ExperimentStatusEnumMap, json['status']),
  ownerType: json['owner_type'] as String,
  ownerId: json['owner_id'] as String,
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ExperimentToJson(Experiment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'method_id': instance.methodId,
      'name': instance.name,
      'description': instance.description,
      'status': _$ExperimentStatusEnumMap[instance.status]!,
      'owner_type': instance.ownerType,
      'owner_id': instance.ownerId,
      'started_at': instance.startedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$ExperimentStatusEnumMap = {
  ExperimentStatus.idle: 'IDLE',
  ExperimentStatus.loaded: 'LOADED',
  ExperimentStatus.running: 'RUNNING',
  ExperimentStatus.paused: 'PAUSED',
  ExperimentStatus.completed: 'COMPLETED',
  ExperimentStatus.aborted: 'ABORTED',
};
