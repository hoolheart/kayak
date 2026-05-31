import 'package:freezed_annotation/freezed_annotation.dart';

part 'method.freezed.dart';
part 'method.g.dart';

// ============================================================
// Method — 试验方法实体
// ============================================================
@freezed
class Method with _$Method {
  const factory Method({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'process_definition')
    required Map<String, dynamic> processDefinition,
    @JsonKey(name: 'parameter_schema')
    required Map<String, dynamic> parameterSchema,
    required int version,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Method;

  factory Method.fromJson(Map<String, dynamic> json) => _$MethodFromJson(json);
}

// ============================================================
// MethodParameter — 方法参数
// ============================================================
@freezed
class MethodParameter with _$MethodParameter {
  const factory MethodParameter({
    required String key,
    required String type,
    String? label,
    @JsonKey(name: 'default_value') Object? defaultValue,
    @Default(false) @JsonKey(name: 'required') bool isRequired,
  }) = _MethodParameter;

  factory MethodParameter.fromJson(Map<String, dynamic> json) =>
      _$MethodParameterFromJson(json);
}
