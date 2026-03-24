// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Point _$PointFromJson(Map<String, dynamic> json) {
  return _Point.fromJson(json);
}

/// @nodoc
mixin _$Point {
  String get id => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DataType get dataType => throw _privateConstructorUsedError;
  AccessType get accessType => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  double? get minValue => throw _privateConstructorUsedError;
  double? get maxValue => throw _privateConstructorUsedError;
  String? get defaultValue => throw _privateConstructorUsedError;
  PointStatus get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Point to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointCopyWith<Point> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointCopyWith<$Res> {
  factory $PointCopyWith(Point value, $Res Function(Point) then) =
      _$PointCopyWithImpl<$Res, Point>;
  @useResult
  $Res call(
      {String id,
      String deviceId,
      String name,
      DataType dataType,
      AccessType accessType,
      String? unit,
      double? minValue,
      double? maxValue,
      String? defaultValue,
      PointStatus status,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$PointCopyWithImpl<$Res, $Val extends Point>
    implements $PointCopyWith<$Res> {
  _$PointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? name = null,
    Object? dataType = null,
    Object? accessType = null,
    Object? unit = freezed,
    Object? minValue = freezed,
    Object? maxValue = freezed,
    Object? defaultValue = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      dataType: null == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as DataType,
      accessType: null == accessType
          ? _value.accessType
          : accessType // ignore: cast_nullable_to_non_nullable
              as AccessType,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      minValue: freezed == minValue
          ? _value.minValue
          : minValue // ignore: cast_nullable_to_non_nullable
              as double?,
      maxValue: freezed == maxValue
          ? _value.maxValue
          : maxValue // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultValue: freezed == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PointStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointImplCopyWith<$Res> implements $PointCopyWith<$Res> {
  factory _$$PointImplCopyWith(
          _$PointImpl value, $Res Function(_$PointImpl) then) =
      __$$PointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String deviceId,
      String name,
      DataType dataType,
      AccessType accessType,
      String? unit,
      double? minValue,
      double? maxValue,
      String? defaultValue,
      PointStatus status,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$PointImplCopyWithImpl<$Res>
    extends _$PointCopyWithImpl<$Res, _$PointImpl>
    implements _$$PointImplCopyWith<$Res> {
  __$$PointImplCopyWithImpl(
      _$PointImpl _value, $Res Function(_$PointImpl) _then)
      : super(_value, _then);

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? name = null,
    Object? dataType = null,
    Object? accessType = null,
    Object? unit = freezed,
    Object? minValue = freezed,
    Object? maxValue = freezed,
    Object? defaultValue = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PointImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      dataType: null == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as DataType,
      accessType: null == accessType
          ? _value.accessType
          : accessType // ignore: cast_nullable_to_non_nullable
              as AccessType,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      minValue: freezed == minValue
          ? _value.minValue
          : minValue // ignore: cast_nullable_to_non_nullable
              as double?,
      maxValue: freezed == maxValue
          ? _value.maxValue
          : maxValue // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultValue: freezed == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PointStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointImpl implements _Point {
  const _$PointImpl(
      {required this.id,
      required this.deviceId,
      required this.name,
      required this.dataType,
      required this.accessType,
      this.unit,
      this.minValue,
      this.maxValue,
      this.defaultValue,
      required this.status,
      this.createdAt,
      this.updatedAt});

  factory _$PointImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointImplFromJson(json);

  @override
  final String id;
  @override
  final String deviceId;
  @override
  final String name;
  @override
  final DataType dataType;
  @override
  final AccessType accessType;
  @override
  final String? unit;
  @override
  final double? minValue;
  @override
  final double? maxValue;
  @override
  final String? defaultValue;
  @override
  final PointStatus status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Point(id: $id, deviceId: $deviceId, name: $name, dataType: $dataType, accessType: $accessType, unit: $unit, minValue: $minValue, maxValue: $maxValue, defaultValue: $defaultValue, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dataType, dataType) ||
                other.dataType == dataType) &&
            (identical(other.accessType, accessType) ||
                other.accessType == accessType) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.minValue, minValue) ||
                other.minValue == minValue) &&
            (identical(other.maxValue, maxValue) ||
                other.maxValue == maxValue) &&
            (identical(other.defaultValue, defaultValue) ||
                other.defaultValue == defaultValue) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      deviceId,
      name,
      dataType,
      accessType,
      unit,
      minValue,
      maxValue,
      defaultValue,
      status,
      createdAt,
      updatedAt);

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointImplCopyWith<_$PointImpl> get copyWith =>
      __$$PointImplCopyWithImpl<_$PointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointImplToJson(
      this,
    );
  }
}

abstract class _Point implements Point {
  const factory _Point(
      {required final String id,
      required final String deviceId,
      required final String name,
      required final DataType dataType,
      required final AccessType accessType,
      final String? unit,
      final double? minValue,
      final double? maxValue,
      final String? defaultValue,
      required final PointStatus status,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$PointImpl;

  factory _Point.fromJson(Map<String, dynamic> json) = _$PointImpl.fromJson;

  @override
  String get id;
  @override
  String get deviceId;
  @override
  String get name;
  @override
  DataType get dataType;
  @override
  AccessType get accessType;
  @override
  String? get unit;
  @override
  double? get minValue;
  @override
  double? get maxValue;
  @override
  String? get defaultValue;
  @override
  PointStatus get status;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointImplCopyWith<_$PointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PointValue _$PointValueFromJson(Map<String, dynamic> json) {
  return _PointValue.fromJson(json);
}

/// @nodoc
mixin _$PointValue {
  String get pointId => throw _privateConstructorUsedError;
  dynamic get value => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this PointValue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointValueCopyWith<PointValue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointValueCopyWith<$Res> {
  factory $PointValueCopyWith(
          PointValue value, $Res Function(PointValue) then) =
      _$PointValueCopyWithImpl<$Res, PointValue>;
  @useResult
  $Res call({String pointId, dynamic value, DateTime timestamp});
}

/// @nodoc
class _$PointValueCopyWithImpl<$Res, $Val extends PointValue>
    implements $PointValueCopyWith<$Res> {
  _$PointValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pointId = null,
    Object? value = freezed,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      pointId: null == pointId
          ? _value.pointId
          : pointId // ignore: cast_nullable_to_non_nullable
              as String,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as dynamic,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointValueImplCopyWith<$Res>
    implements $PointValueCopyWith<$Res> {
  factory _$$PointValueImplCopyWith(
          _$PointValueImpl value, $Res Function(_$PointValueImpl) then) =
      __$$PointValueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String pointId, dynamic value, DateTime timestamp});
}

/// @nodoc
class __$$PointValueImplCopyWithImpl<$Res>
    extends _$PointValueCopyWithImpl<$Res, _$PointValueImpl>
    implements _$$PointValueImplCopyWith<$Res> {
  __$$PointValueImplCopyWithImpl(
      _$PointValueImpl _value, $Res Function(_$PointValueImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pointId = null,
    Object? value = freezed,
    Object? timestamp = null,
  }) {
    return _then(_$PointValueImpl(
      pointId: null == pointId
          ? _value.pointId
          : pointId // ignore: cast_nullable_to_non_nullable
              as String,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as dynamic,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointValueImpl implements _PointValue {
  const _$PointValueImpl(
      {required this.pointId, required this.value, required this.timestamp});

  factory _$PointValueImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointValueImplFromJson(json);

  @override
  final String pointId;
  @override
  final dynamic value;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'PointValue(pointId: $pointId, value: $value, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointValueImpl &&
            (identical(other.pointId, pointId) || other.pointId == pointId) &&
            const DeepCollectionEquality().equals(other.value, value) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pointId,
      const DeepCollectionEquality().hash(value), timestamp);

  /// Create a copy of PointValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointValueImplCopyWith<_$PointValueImpl> get copyWith =>
      __$$PointValueImplCopyWithImpl<_$PointValueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointValueImplToJson(
      this,
    );
  }
}

abstract class _PointValue implements PointValue {
  const factory _PointValue(
      {required final String pointId,
      required final dynamic value,
      required final DateTime timestamp}) = _$PointValueImpl;

  factory _PointValue.fromJson(Map<String, dynamic> json) =
      _$PointValueImpl.fromJson;

  @override
  String get pointId;
  @override
  dynamic get value;
  @override
  DateTime get timestamp;

  /// Create a copy of PointValue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointValueImplCopyWith<_$PointValueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
