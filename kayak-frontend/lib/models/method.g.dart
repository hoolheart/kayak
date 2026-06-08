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
  parameters: (json['parameters'] as List<dynamic>?)
      ?.map((e) => MethodParameter.fromJson(e as Map<String, dynamic>))
      .toList(),
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
  'parameters': instance.parameters,
};

MethodParameter _$MethodParameterFromJson(Map<String, dynamic> json) =>
    MethodParameter(
      key: json['key'] as String,
      type: json['type'] as String,
      label: json['label'] as String?,
      defaultValue: json['default_value'],
      isRequired: json['required'] as bool? ?? false,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      min: json['min'] as num?,
      max: json['max'] as num?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MethodParameterToJson(MethodParameter instance) =>
    <String, dynamic>{
      'key': instance.key,
      'type': instance.type,
      'label': instance.label,
      'default_value': instance.defaultValue,
      'required': instance.isRequired,
      'unit': instance.unit,
      'description': instance.description,
      'min': instance.min,
      'max': instance.max,
      'options': instance.options,
    };
