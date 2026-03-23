/// 测点数据模型
///
/// 定义测点的核心属性和序列化逻辑
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'point.freezed.dart';
part 'point.g.dart';

/// 测点模型
@freezed
class Point with _$Point {
  const factory Point({
    required String id,
    required String deviceId,
    required String name,
    required DataType dataType,
    required AccessType accessType,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
    required PointStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Point;

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
}

/// 数据类型枚举
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

/// 访问类型枚举
enum AccessType {
  @JsonValue('ro')
  ro,
  @JsonValue('wo')
  wo,
  @JsonValue('rw')
  rw,
}

/// 测点状态枚举
enum PointStatus {
  @JsonValue('active')
  active,
  @JsonValue('disabled')
  disabled,
}

/// 测点值模型
@freezed
class PointValue with _$PointValue {
  const factory PointValue({
    required String pointId,
    required dynamic value,
    required DateTime timestamp,
  }) = _PointValue;

  factory PointValue.fromJson(Map<String, dynamic> json) =>
      _$PointValueFromJson(json);
}
