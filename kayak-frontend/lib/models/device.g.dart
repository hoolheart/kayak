// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Device _$DeviceFromJson(Map<String, dynamic> json) => _Device(
  id: json['id'] as String,
  workbenchId: json['workbench_id'] as String,
  parentId: json['parent_id'] as String?,
  name: json['name'] as String,
  protocolType: $enumDecode(_$ProtocolTypeEnumMap, json['protocol_type']),
  protocolParams: json['protocol_params'] as Map<String, dynamic>?,
  manufacturer: json['manufacturer'] as String?,
  model: json['model'] as String?,
  sn: json['sn'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DeviceToJson(_Device instance) => <String, dynamic>{
  'id': instance.id,
  'workbench_id': instance.workbenchId,
  'parent_id': instance.parentId,
  'name': instance.name,
  'protocol_type': _$ProtocolTypeEnumMap[instance.protocolType]!,
  'protocol_params': instance.protocolParams,
  'manufacturer': instance.manufacturer,
  'model': instance.model,
  'sn': instance.sn,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$ProtocolTypeEnumMap = {
  ProtocolType.virtual: 'virtual',
  ProtocolType.modbusTcp: 'modbus_tcp',
  ProtocolType.modbusRtu: 'modbus_rtu',
  ProtocolType.can: 'can',
  ProtocolType.visa: 'visa',
  ProtocolType.mqtt: 'mqtt',
};

_DeviceTreeNode _$DeviceTreeNodeFromJson(Map<String, dynamic> json) =>
    _DeviceTreeNode(
      id: json['id'] as String,
      workbenchId: json['workbench_id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      protocolType: $enumDecode(_$ProtocolTypeEnumMap, json['protocol_type']),
      protocolParams: json['protocol_params'] as Map<String, dynamic>?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      sn: json['sn'] as String?,
      status: json['status'] as String,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => DeviceTreeNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DeviceTreeNodeToJson(_DeviceTreeNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workbench_id': instance.workbenchId,
      'parent_id': instance.parentId,
      'name': instance.name,
      'protocol_type': _$ProtocolTypeEnumMap[instance.protocolType]!,
      'protocol_params': instance.protocolParams,
      'manufacturer': instance.manufacturer,
      'model': instance.model,
      'sn': instance.sn,
      'status': instance.status,
      'children': instance.children,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
