// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) => Point(
  id: json['id'] as String,
  deviceId: json['device_id'] as String,
  name: json['name'] as String,
  dataType: $enumDecode(_$DataTypeEnumMap, json['data_type']),
  accessType: $enumDecode(_$AccessTypeEnumMap, json['access_type']),
  unit: json['unit'] as String?,
  minValue: (json['min_value'] as num?)?.toDouble(),
  maxValue: (json['max_value'] as num?)?.toDouble(),
  defaultValue: json['default_value'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{
  'id': instance.id,
  'device_id': instance.deviceId,
  'name': instance.name,
  'data_type': _$DataTypeEnumMap[instance.dataType]!,
  'access_type': _$AccessTypeEnumMap[instance.accessType]!,
  'unit': instance.unit,
  'min_value': instance.minValue,
  'max_value': instance.maxValue,
  'default_value': instance.defaultValue,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$DataTypeEnumMap = {
  DataType.number: 'number',
  DataType.integer: 'integer',
  DataType.string: 'string',
  DataType.boolean: 'boolean',
};

const _$AccessTypeEnumMap = {
  AccessType.ro: 'ro',
  AccessType.wo: 'wo',
  AccessType.rw: 'rw',
};

PointValue _$PointValueFromJson(Map<String, dynamic> json) => PointValue(
  pointId: json['point_id'] as String,
  value: json['value'],
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$PointValueToJson(PointValue instance) =>
    <String, dynamic>{
      'point_id': instance.pointId,
      'value': instance.value,
      'timestamp': instance.timestamp,
    };
