// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Method _$MethodFromJson(Map<String, dynamic> json) => Method(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  processDefinition: json['process_definition'] as Map<String, dynamic>,
  parameterSchema: json['parameter_schema'] as Map<String, dynamic>,
  version: (json['version'] as num).toInt(),
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MethodToJson(Method instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'process_definition': instance.processDefinition,
  'parameter_schema': instance.parameterSchema,
  'version': instance.version,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

MethodParameter _$MethodParameterFromJson(Map<String, dynamic> json) =>
    MethodParameter(
      key: json['key'] as String,
      type: json['type'] as String,
      label: json['label'] as String?,
      defaultValue: json['default_value'],
      isRequired: json['required'] as bool? ?? false,
    );

Map<String, dynamic> _$MethodParameterToJson(MethodParameter instance) =>
    <String, dynamic>{
      'key': instance.key,
      'type': instance.type,
      'label': instance.label,
      'default_value': instance.defaultValue,
      'required': instance.isRequired,
    };
