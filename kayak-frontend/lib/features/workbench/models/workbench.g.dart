// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workbench.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkbenchImpl _$$WorkbenchImplFromJson(Map<String, dynamic> json) =>
    _$WorkbenchImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      ownerType: json['ownerType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WorkbenchImplToJson(_$WorkbenchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'ownerId': instance.ownerId,
      'ownerType': instance.ownerType,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$PagedWorkbenchResponseImpl _$$PagedWorkbenchResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$PagedWorkbenchResponseImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => Workbench.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$$PagedWorkbenchResponseImplToJson(
        _$PagedWorkbenchResponseImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'size': instance.size,
    };

_$CreateWorkbenchRequestImpl _$$CreateWorkbenchRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CreateWorkbenchRequestImpl(
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerType: json['ownerType'] as String?,
    );

Map<String, dynamic> _$$CreateWorkbenchRequestImplToJson(
        _$CreateWorkbenchRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'ownerType': instance.ownerType,
    };

_$UpdateWorkbenchRequestImpl _$$UpdateWorkbenchRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$UpdateWorkbenchRequestImpl(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$UpdateWorkbenchRequestImplToJson(
        _$UpdateWorkbenchRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };
