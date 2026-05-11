// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonalImpl _$$PersonalImplFromJson(Map<String, dynamic> json) =>
    _$PersonalImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PersonalImplToJson(_$PersonalImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$TeamImpl _$$TeamImplFromJson(Map<String, dynamic> json) => _$TeamImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TeamImplToJson(_$TeamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'runtimeType': instance.$type,
    };
