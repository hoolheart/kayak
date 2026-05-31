// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Point _$PointFromJson(Map<String, dynamic> json) => _Point(
  id: json['id'] as String,
  deviceId: json['device_id'] as String,
  name: json['name'] as String,
  dataType: json['data_type'] as String,
  accessType: json['access_type'] as String,
  unit: json['unit'] as String?,
  minValue: (json['min_value'] as num?)?.toDouble(),
  maxValue: (json['max_value'] as num?)?.toDouble(),
  defaultValue: json['default_value'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PointToJson(_Point instance) => <String, dynamic>{
  'id': instance.id,
  'device_id': instance.deviceId,
  'name': instance.name,
  'data_type': instance.dataType,
  'access_type': instance.accessType,
  'unit': instance.unit,
  'min_value': instance.minValue,
  'max_value': instance.maxValue,
  'default_value': instance.defaultValue,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

_PointValue _$PointValueFromJson(Map<String, dynamic> json) => _PointValue(
  pointId: json['point_id'] as String,
  value: json['value'],
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$PointValueToJson(_PointValue instance) =>
    <String, dynamic>{
      'point_id': instance.pointId,
      'value': instance.value,
      'timestamp': instance.timestamp,
    };
