// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workbench.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Workbench _$WorkbenchFromJson(Map<String, dynamic> json) => _Workbench(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  ownerType: json['owner_type'] as String,
  ownerId: json['owner_id'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$WorkbenchToJson(_Workbench instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'owner_type': instance.ownerType,
      'owner_id': instance.ownerId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_CreateWorkbenchRequest _$CreateWorkbenchRequestFromJson(
  Map<String, dynamic> json,
) => _CreateWorkbenchRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  ownerType: json['owner_type'] as String,
  ownerId: json['owner_id'] as String,
);

Map<String, dynamic> _$CreateWorkbenchRequestToJson(
  _CreateWorkbenchRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'owner_type': instance.ownerType,
  'owner_id': instance.ownerId,
};
