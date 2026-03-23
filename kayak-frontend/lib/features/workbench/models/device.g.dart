// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceImpl _$$DeviceImplFromJson(Map<String, dynamic> json) => _$DeviceImpl(
      id: json['id'] as String,
      workbenchId: json['workbenchId'] as String,
      parentId: json['parentId'] as String?,
      name: json['name'] as String,
      protocolType: $enumDecode(_$ProtocolTypeEnumMap, json['protocolType']),
      protocolParams: json['protocolParams'] as Map<String, dynamic>?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      sn: json['sn'] as String?,
      status: $enumDecode(_$DeviceStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DeviceImplToJson(_$DeviceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workbenchId': instance.workbenchId,
      'parentId': instance.parentId,
      'name': instance.name,
      'protocolType': _$ProtocolTypeEnumMap[instance.protocolType]!,
      'protocolParams': instance.protocolParams,
      'manufacturer': instance.manufacturer,
      'model': instance.model,
      'sn': instance.sn,
      'status': _$DeviceStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProtocolTypeEnumMap = {
  ProtocolType.virtual: 'virtual',
  ProtocolType.modbusTcp: 'modbus_tcp',
  ProtocolType.modbusRtu: 'modbus_rtu',
  ProtocolType.can: 'can',
  ProtocolType.visa: 'visa',
  ProtocolType.mqtt: 'mqtt',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.offline: 'offline',
  DeviceStatus.online: 'online',
  DeviceStatus.error: 'error',
};
