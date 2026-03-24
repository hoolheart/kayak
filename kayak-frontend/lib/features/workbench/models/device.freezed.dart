// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Device _$DeviceFromJson(Map<String, dynamic> json) {
  return _Device.fromJson(json);
}

/// @nodoc
mixin _$Device {
  String get id => throw _privateConstructorUsedError;
  String get workbenchId => throw _privateConstructorUsedError;
  String? get parentId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  ProtocolType get protocolType => throw _privateConstructorUsedError;
  Map<String, dynamic>? get protocolParams =>
      throw _privateConstructorUsedError;
  String? get manufacturer => throw _privateConstructorUsedError;
  String? get model => throw _privateConstructorUsedError;
  String? get sn => throw _privateConstructorUsedError;
  DeviceStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Device to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceCopyWith<Device> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceCopyWith<$Res> {
  factory $DeviceCopyWith(Device value, $Res Function(Device) then) =
      _$DeviceCopyWithImpl<$Res, Device>;
  @useResult
  $Res call(
      {String id,
      String workbenchId,
      String? parentId,
      String name,
      ProtocolType protocolType,
      Map<String, dynamic>? protocolParams,
      String? manufacturer,
      String? model,
      String? sn,
      DeviceStatus status,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$DeviceCopyWithImpl<$Res, $Val extends Device>
    implements $DeviceCopyWith<$Res> {
  _$DeviceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workbenchId = null,
    Object? parentId = freezed,
    Object? name = null,
    Object? protocolType = null,
    Object? protocolParams = freezed,
    Object? manufacturer = freezed,
    Object? model = freezed,
    Object? sn = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workbenchId: null == workbenchId
          ? _value.workbenchId
          : workbenchId // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      protocolType: null == protocolType
          ? _value.protocolType
          : protocolType // ignore: cast_nullable_to_non_nullable
              as ProtocolType,
      protocolParams: freezed == protocolParams
          ? _value.protocolParams
          : protocolParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      manufacturer: freezed == manufacturer
          ? _value.manufacturer
          : manufacturer // ignore: cast_nullable_to_non_nullable
              as String?,
      model: freezed == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      sn: freezed == sn
          ? _value.sn
          : sn // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DeviceStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceImplCopyWith<$Res> implements $DeviceCopyWith<$Res> {
  factory _$$DeviceImplCopyWith(
          _$DeviceImpl value, $Res Function(_$DeviceImpl) then) =
      __$$DeviceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String workbenchId,
      String? parentId,
      String name,
      ProtocolType protocolType,
      Map<String, dynamic>? protocolParams,
      String? manufacturer,
      String? model,
      String? sn,
      DeviceStatus status,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$DeviceImplCopyWithImpl<$Res>
    extends _$DeviceCopyWithImpl<$Res, _$DeviceImpl>
    implements _$$DeviceImplCopyWith<$Res> {
  __$$DeviceImplCopyWithImpl(
      _$DeviceImpl _value, $Res Function(_$DeviceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workbenchId = null,
    Object? parentId = freezed,
    Object? name = null,
    Object? protocolType = null,
    Object? protocolParams = freezed,
    Object? manufacturer = freezed,
    Object? model = freezed,
    Object? sn = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$DeviceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workbenchId: null == workbenchId
          ? _value.workbenchId
          : workbenchId // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      protocolType: null == protocolType
          ? _value.protocolType
          : protocolType // ignore: cast_nullable_to_non_nullable
              as ProtocolType,
      protocolParams: freezed == protocolParams
          ? _value._protocolParams
          : protocolParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      manufacturer: freezed == manufacturer
          ? _value.manufacturer
          : manufacturer // ignore: cast_nullable_to_non_nullable
              as String?,
      model: freezed == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      sn: freezed == sn
          ? _value.sn
          : sn // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DeviceStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceImpl implements _Device {
  const _$DeviceImpl(
      {required this.id,
      required this.workbenchId,
      this.parentId,
      required this.name,
      required this.protocolType,
      final Map<String, dynamic>? protocolParams,
      this.manufacturer,
      this.model,
      this.sn,
      required this.status,
      required this.createdAt,
      required this.updatedAt})
      : _protocolParams = protocolParams;

  factory _$DeviceImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceImplFromJson(json);

  @override
  final String id;
  @override
  final String workbenchId;
  @override
  final String? parentId;
  @override
  final String name;
  @override
  final ProtocolType protocolType;
  final Map<String, dynamic>? _protocolParams;
  @override
  Map<String, dynamic>? get protocolParams {
    final value = _protocolParams;
    if (value == null) return null;
    if (_protocolParams is EqualUnmodifiableMapView) return _protocolParams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? manufacturer;
  @override
  final String? model;
  @override
  final String? sn;
  @override
  final DeviceStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Device(id: $id, workbenchId: $workbenchId, parentId: $parentId, name: $name, protocolType: $protocolType, protocolParams: $protocolParams, manufacturer: $manufacturer, model: $model, sn: $sn, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workbenchId, workbenchId) ||
                other.workbenchId == workbenchId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.protocolType, protocolType) ||
                other.protocolType == protocolType) &&
            const DeepCollectionEquality()
                .equals(other._protocolParams, _protocolParams) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.sn, sn) || other.sn == sn) &&
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
      workbenchId,
      parentId,
      name,
      protocolType,
      const DeepCollectionEquality().hash(_protocolParams),
      manufacturer,
      model,
      sn,
      status,
      createdAt,
      updatedAt);

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceImplCopyWith<_$DeviceImpl> get copyWith =>
      __$$DeviceImplCopyWithImpl<_$DeviceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceImplToJson(
      this,
    );
  }
}

abstract class _Device implements Device {
  const factory _Device(
      {required final String id,
      required final String workbenchId,
      final String? parentId,
      required final String name,
      required final ProtocolType protocolType,
      final Map<String, dynamic>? protocolParams,
      final String? manufacturer,
      final String? model,
      final String? sn,
      required final DeviceStatus status,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$DeviceImpl;

  factory _Device.fromJson(Map<String, dynamic> json) = _$DeviceImpl.fromJson;

  @override
  String get id;
  @override
  String get workbenchId;
  @override
  String? get parentId;
  @override
  String get name;
  @override
  ProtocolType get protocolType;
  @override
  Map<String, dynamic>? get protocolParams;
  @override
  String? get manufacturer;
  @override
  String? get model;
  @override
  String? get sn;
  @override
  DeviceStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceImplCopyWith<_$DeviceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
