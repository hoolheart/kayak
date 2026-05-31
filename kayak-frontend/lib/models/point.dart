import 'package:freezed_annotation/freezed_annotation.dart';

part 'point.freezed.dart';
part 'point.g.dart';

// ============================================================
// DataType — 数据类型枚举
// ============================================================
enum DataType {
  @JsonValue('number')
  number,
  @JsonValue('integer')
  integer,
  @JsonValue('string')
  string,
  @JsonValue('boolean')
  boolean,
}

// ============================================================
// AccessType — 访问类型枚举
// ============================================================
enum AccessType {
  @JsonValue('ro')
  ro,
  @JsonValue('wo')
  wo,
  @JsonValue('rw')
  rw,
}

// ============================================================
// Point — 测点实体
// ============================================================
@freezed
class Point with _$Point {
  const factory Point({
    required String id,
    @JsonKey(name: 'device_id') required String deviceId,
    required String name,
    @JsonKey(name: 'data_type') required DataType dataType,
    @JsonKey(name: 'access_type') required AccessType accessType,
    String? unit,
    @JsonKey(name: 'min_value') double? minValue,
    @JsonKey(name: 'max_value') double? maxValue,
    @JsonKey(name: 'default_value') String? defaultValue,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Point;

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
}

// ============================================================
// PointValue — 测点值
// ============================================================
@freezed
class PointValue with _$PointValue {
  const factory PointValue({
    @JsonKey(name: 'point_id') required String pointId,
    Object? value,
    String? timestamp,
  }) = _PointValue;

  factory PointValue.fromJson(Map<String, dynamic> json) =>
      _$PointValueFromJson(json);
}
