import 'package:json_annotation/json_annotation.dart';

part 'method.g.dart';

// ============================================================
// Method — 试验方法实体
// ============================================================
@JsonSerializable()
class Method {

  const Method({
    required this.id,
    required this.name,
    this.description,
    required this.processDefinition,
    required this.parameterSchema,
    required this.version,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Method.fromJson(Map<String, dynamic> json) => _$MethodFromJson(json);
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'process_definition')
  final Map<String, dynamic> processDefinition;
  @JsonKey(name: 'parameter_schema')
  final Map<String, dynamic> parameterSchema;
  final int version;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  Map<String, dynamic> toJson() => _$MethodToJson(this);

  Method copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? processDefinition,
    Map<String, dynamic>? parameterSchema,
    int? version,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Method(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      processDefinition: processDefinition ?? this.processDefinition,
      parameterSchema: parameterSchema ?? this.parameterSchema,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// MethodParameter — 方法参数
// ============================================================
@JsonSerializable()
class MethodParameter {

  const MethodParameter({
    required this.key,
    required this.type,
    this.label,
    this.defaultValue,
    this.isRequired = false,
  });

  factory MethodParameter.fromJson(Map<String, dynamic> json) =>
      _$MethodParameterFromJson(json);
  final String key;
  final String type;
  final String? label;
  @JsonKey(name: 'default_value')
  final Object? defaultValue;
  @JsonKey(name: 'required', defaultValue: false)
  final bool isRequired;
  Map<String, dynamic> toJson() => _$MethodParameterToJson(this);

  MethodParameter copyWith({
    String? key,
    String? type,
    String? label,
    Object? defaultValue,
    bool? isRequired,
  }) {
    return MethodParameter(
      key: key ?? this.key,
      type: type ?? this.type,
      label: label ?? this.label,
      defaultValue: defaultValue ?? this.defaultValue,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}
