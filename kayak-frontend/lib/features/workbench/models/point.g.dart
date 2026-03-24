// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointImpl _$$PointImplFromJson(Map<String, dynamic> json) => _$PointImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      dataType: $enumDecode(_$DataTypeEnumMap, json['dataType']),
      accessType: $enumDecode(_$AccessTypeEnumMap, json['accessType']),
      unit: json['unit'] as String?,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      defaultValue: json['defaultValue'] as String?,
      status: $enumDecode(_$PointStatusEnumMap, json['status']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PointImplToJson(_$PointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'name': instance.name,
      'dataType': _$DataTypeEnumMap[instance.dataType]!,
      'accessType': _$AccessTypeEnumMap[instance.accessType]!,
      'unit': instance.unit,
      'minValue': instance.minValue,
      'maxValue': instance.maxValue,
      'defaultValue': instance.defaultValue,
      'status': _$PointStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
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

const _$PointStatusEnumMap = {
  PointStatus.active: 'active',
  PointStatus.disabled: 'disabled',
};

_$PointValueImpl _$$PointValueImplFromJson(Map<String, dynamic> json) =>
    _$PointValueImpl(
      pointId: json['pointId'] as String,
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$PointValueImplToJson(_$PointValueImpl instance) =>
    <String, dynamic>{
      'pointId': instance.pointId,
      'value': instance.value,
      'timestamp': instance.timestamp.toIso8601String(),
    };
