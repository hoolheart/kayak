import 'package:json_annotation/json_annotation.dart';

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
@JsonSerializable()
class Point {

  const Point({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.dataType,
    required this.accessType,
    this.unit,
    this.minValue,
    this.maxValue,
    this.defaultValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
  final String id;
  @JsonKey(name: 'device_id')
  final String deviceId;
  final String name;
  @JsonKey(name: 'data_type')
  final DataType dataType;
  @JsonKey(name: 'access_type')
  final AccessType accessType;
  final String? unit;
  @JsonKey(name: 'min_value')
  final double? minValue;
  @JsonKey(name: 'max_value')
  final double? maxValue;
  @JsonKey(name: 'default_value')
  final String? defaultValue;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  Map<String, dynamic> toJson() => _$PointToJson(this);

  Point copyWith({
    String? id,
    String? deviceId,
    String? name,
    DataType? dataType,
    AccessType? accessType,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Point(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      dataType: dataType ?? this.dataType,
      accessType: accessType ?? this.accessType,
      unit: unit ?? this.unit,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      defaultValue: defaultValue ?? this.defaultValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// PointValue — 测点值
// ============================================================
@JsonSerializable()
class PointValue {

  const PointValue({
    required this.pointId,
    this.value,
    this.timestamp,
  });

  factory PointValue.fromJson(Map<String, dynamic> json) =>
      _$PointValueFromJson(json);
  @JsonKey(name: 'point_id')
  final String pointId;
  final Object? value;
  final String? timestamp;
  Map<String, dynamic> toJson() => _$PointValueToJson(this);

  PointValue copyWith({
    String? pointId,
    Object? value,
    String? timestamp,
  }) {
    return PointValue(
      pointId: pointId ?? this.pointId,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
