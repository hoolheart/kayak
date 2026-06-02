import 'package:json_annotation/json_annotation.dart';

part 'method.g.dart';

// ============================================================
// ParameterType — 参数类型枚举
// ============================================================

/// 支持的参数类型，用于动态表单输入控件映射。
enum ParameterType {
  @JsonValue('number')
  number,
  @JsonValue('integer')
  integer,
  @JsonValue('string')
  string,
  @JsonValue('boolean')
  boolean,
  @JsonValue('enum')
  enum_,
}

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
    this.parameters,
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

  /// 解析后的参数列表（可选）。
  /// 当后端返回结构化的参数列表时使用，优先于手动解析 [parameterSchema]。
  @JsonKey(name: 'parameters')
  final List<MethodParameter>? parameters;

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
    List<MethodParameter>? parameters,
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
      parameters: parameters ?? this.parameters,
    );
  }
}

// ============================================================
// MethodParameter — 方法参数定义
// ============================================================

/// 方法参数定义，用于动态生成参数配置表单。
///
/// 支持的参数类型：
/// - `number`: 数值（double），使用 TextFormField + 数字键盘
/// - `integer`: 整数，使用 TextFormField + 数字键盘
/// - `string`: 字符串，使用 TextFormField
/// - `boolean`: 布尔值，使用 Switch
/// - `enum`: 枚举选择，使用 DropdownButtonFormField
@JsonSerializable()
class MethodParameter {

  const MethodParameter({
    required this.key,
    required this.type,
    this.label,
    this.defaultValue,
    this.isRequired = false,
    this.unit,
    this.description,
    this.min,
    this.max,
    this.options,
  });

  factory MethodParameter.fromJson(Map<String, dynamic> json) =>
      _$MethodParameterFromJson(json);

  /// 参数键名（用于提交时的 key）。
  final String key;

  /// 参数类型：number / integer / string / boolean / enum。
  final String type;

  /// 显示标签（供 UI 展示的字段名）。
  final String? label;

  /// 默认值。
  @JsonKey(name: 'default_value')
  final Object? defaultValue;

  /// 是否必填。
  @JsonKey(name: 'required', defaultValue: false)
  final bool isRequired;

  /// 单位（如 °C、分钟、MPa）。
  final String? unit;

  /// 参数描述/帮助文本。
  final String? description;

  /// 最小值（仅 number/integer 类型）。
  final num? min;

  /// 最大值（仅 number/integer 类型）。
  final num? max;

  /// 可选值列表（仅 enum 类型）。
  final List<String>? options;

  Map<String, dynamic> toJson() => _$MethodParameterToJson(this);

  MethodParameter copyWith({
    String? key,
    String? type,
    String? label,
    Object? defaultValue,
    bool? isRequired,
    String? unit,
    String? description,
    num? min,
    num? max,
    List<String>? options,
  }) {
    return MethodParameter(
      key: key ?? this.key,
      type: type ?? this.type,
      label: label ?? this.label,
      defaultValue: defaultValue ?? this.defaultValue,
      isRequired: isRequired ?? this.isRequired,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      min: min ?? this.min,
      max: max ?? this.max,
      options: options ?? this.options,
    );
  }
}
