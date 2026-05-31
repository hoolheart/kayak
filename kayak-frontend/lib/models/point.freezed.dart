// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Point {

 String get id;@JsonKey(name: 'device_id') String get deviceId; String get name;@JsonKey(name: 'data_type') String get dataType;@JsonKey(name: 'access_type') String get accessType; String? get unit;@JsonKey(name: 'min_value') double? get minValue;@JsonKey(name: 'max_value') double? get maxValue;@JsonKey(name: 'default_value') String? get defaultValue; String get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of Point
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointCopyWith<Point> get copyWith => _$PointCopyWithImpl<Point>(this as Point, _$identity);

  /// Serializes this Point to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Point&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.dataType, dataType) || other.dataType == dataType)&&(identical(other.accessType, accessType) || other.accessType == accessType)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.minValue, minValue) || other.minValue == minValue)&&(identical(other.maxValue, maxValue) || other.maxValue == maxValue)&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceId,name,dataType,accessType,unit,minValue,maxValue,defaultValue,status,createdAt,updatedAt);

@override
String toString() {
  return 'Point(id: $id, deviceId: $deviceId, name: $name, dataType: $dataType, accessType: $accessType, unit: $unit, minValue: $minValue, maxValue: $maxValue, defaultValue: $defaultValue, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PointCopyWith<$Res>  {
  factory $PointCopyWith(Point value, $Res Function(Point) _then) = _$PointCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'device_id') String deviceId, String name,@JsonKey(name: 'data_type') String dataType,@JsonKey(name: 'access_type') String accessType, String? unit,@JsonKey(name: 'min_value') double? minValue,@JsonKey(name: 'max_value') double? maxValue,@JsonKey(name: 'default_value') String? defaultValue, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$PointCopyWithImpl<$Res>
    implements $PointCopyWith<$Res> {
  _$PointCopyWithImpl(this._self, this._then);

  final Point _self;
  final $Res Function(Point) _then;

/// Create a copy of Point
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? deviceId = null,Object? name = null,Object? dataType = null,Object? accessType = null,Object? unit = freezed,Object? minValue = freezed,Object? maxValue = freezed,Object? defaultValue = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,dataType: null == dataType ? _self.dataType : dataType // ignore: cast_nullable_to_non_nullable
as String,accessType: null == accessType ? _self.accessType : accessType // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,minValue: freezed == minValue ? _self.minValue : minValue // ignore: cast_nullable_to_non_nullable
as double?,maxValue: freezed == maxValue ? _self.maxValue : maxValue // ignore: cast_nullable_to_non_nullable
as double?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Point].
extension PointPatterns on Point {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Point value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Point() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Point value)  $default,){
final _that = this;
switch (_that) {
case _Point():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Point value)?  $default,){
final _that = this;
switch (_that) {
case _Point() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'device_id')  String deviceId,  String name, @JsonKey(name: 'data_type')  String dataType, @JsonKey(name: 'access_type')  String accessType,  String? unit, @JsonKey(name: 'min_value')  double? minValue, @JsonKey(name: 'max_value')  double? maxValue, @JsonKey(name: 'default_value')  String? defaultValue,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Point() when $default != null:
return $default(_that.id,_that.deviceId,_that.name,_that.dataType,_that.accessType,_that.unit,_that.minValue,_that.maxValue,_that.defaultValue,_that.status,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'device_id')  String deviceId,  String name, @JsonKey(name: 'data_type')  String dataType, @JsonKey(name: 'access_type')  String accessType,  String? unit, @JsonKey(name: 'min_value')  double? minValue, @JsonKey(name: 'max_value')  double? maxValue, @JsonKey(name: 'default_value')  String? defaultValue,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Point():
return $default(_that.id,_that.deviceId,_that.name,_that.dataType,_that.accessType,_that.unit,_that.minValue,_that.maxValue,_that.defaultValue,_that.status,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'device_id')  String deviceId,  String name, @JsonKey(name: 'data_type')  String dataType, @JsonKey(name: 'access_type')  String accessType,  String? unit, @JsonKey(name: 'min_value')  double? minValue, @JsonKey(name: 'max_value')  double? maxValue, @JsonKey(name: 'default_value')  String? defaultValue,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Point() when $default != null:
return $default(_that.id,_that.deviceId,_that.name,_that.dataType,_that.accessType,_that.unit,_that.minValue,_that.maxValue,_that.defaultValue,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Point implements Point {
  const _Point({required this.id, @JsonKey(name: 'device_id') required this.deviceId, required this.name, @JsonKey(name: 'data_type') required this.dataType, @JsonKey(name: 'access_type') required this.accessType, this.unit, @JsonKey(name: 'min_value') this.minValue, @JsonKey(name: 'max_value') this.maxValue, @JsonKey(name: 'default_value') this.defaultValue, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);

@override final  String id;
@override@JsonKey(name: 'device_id') final  String deviceId;
@override final  String name;
@override@JsonKey(name: 'data_type') final  String dataType;
@override@JsonKey(name: 'access_type') final  String accessType;
@override final  String? unit;
@override@JsonKey(name: 'min_value') final  double? minValue;
@override@JsonKey(name: 'max_value') final  double? maxValue;
@override@JsonKey(name: 'default_value') final  String? defaultValue;
@override final  String status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of Point
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointCopyWith<_Point> get copyWith => __$PointCopyWithImpl<_Point>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Point&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.dataType, dataType) || other.dataType == dataType)&&(identical(other.accessType, accessType) || other.accessType == accessType)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.minValue, minValue) || other.minValue == minValue)&&(identical(other.maxValue, maxValue) || other.maxValue == maxValue)&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceId,name,dataType,accessType,unit,minValue,maxValue,defaultValue,status,createdAt,updatedAt);

@override
String toString() {
  return 'Point(id: $id, deviceId: $deviceId, name: $name, dataType: $dataType, accessType: $accessType, unit: $unit, minValue: $minValue, maxValue: $maxValue, defaultValue: $defaultValue, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PointCopyWith<$Res> implements $PointCopyWith<$Res> {
  factory _$PointCopyWith(_Point value, $Res Function(_Point) _then) = __$PointCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'device_id') String deviceId, String name,@JsonKey(name: 'data_type') String dataType,@JsonKey(name: 'access_type') String accessType, String? unit,@JsonKey(name: 'min_value') double? minValue,@JsonKey(name: 'max_value') double? maxValue,@JsonKey(name: 'default_value') String? defaultValue, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$PointCopyWithImpl<$Res>
    implements _$PointCopyWith<$Res> {
  __$PointCopyWithImpl(this._self, this._then);

  final _Point _self;
  final $Res Function(_Point) _then;

/// Create a copy of Point
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? deviceId = null,Object? name = null,Object? dataType = null,Object? accessType = null,Object? unit = freezed,Object? minValue = freezed,Object? maxValue = freezed,Object? defaultValue = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Point(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,dataType: null == dataType ? _self.dataType : dataType // ignore: cast_nullable_to_non_nullable
as String,accessType: null == accessType ? _self.accessType : accessType // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,minValue: freezed == minValue ? _self.minValue : minValue // ignore: cast_nullable_to_non_nullable
as double?,maxValue: freezed == maxValue ? _self.maxValue : maxValue // ignore: cast_nullable_to_non_nullable
as double?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$PointValue {

@JsonKey(name: 'point_id') String get pointId; Object? get value; String? get timestamp;
/// Create a copy of PointValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointValueCopyWith<PointValue> get copyWith => _$PointValueCopyWithImpl<PointValue>(this as PointValue, _$identity);

  /// Serializes this PointValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointValue&&(identical(other.pointId, pointId) || other.pointId == pointId)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pointId,const DeepCollectionEquality().hash(value),timestamp);

@override
String toString() {
  return 'PointValue(pointId: $pointId, value: $value, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $PointValueCopyWith<$Res>  {
  factory $PointValueCopyWith(PointValue value, $Res Function(PointValue) _then) = _$PointValueCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'point_id') String pointId, Object? value, String? timestamp
});




}
/// @nodoc
class _$PointValueCopyWithImpl<$Res>
    implements $PointValueCopyWith<$Res> {
  _$PointValueCopyWithImpl(this._self, this._then);

  final PointValue _self;
  final $Res Function(PointValue) _then;

/// Create a copy of PointValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pointId = null,Object? value = freezed,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
pointId: null == pointId ? _self.pointId : pointId // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PointValue].
extension PointValuePatterns on PointValue {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PointValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PointValue() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PointValue value)  $default,){
final _that = this;
switch (_that) {
case _PointValue():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PointValue value)?  $default,){
final _that = this;
switch (_that) {
case _PointValue() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'point_id')  String pointId,  Object? value,  String? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PointValue() when $default != null:
return $default(_that.pointId,_that.value,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'point_id')  String pointId,  Object? value,  String? timestamp)  $default,) {final _that = this;
switch (_that) {
case _PointValue():
return $default(_that.pointId,_that.value,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'point_id')  String pointId,  Object? value,  String? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _PointValue() when $default != null:
return $default(_that.pointId,_that.value,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PointValue implements PointValue {
  const _PointValue({@JsonKey(name: 'point_id') required this.pointId, this.value, this.timestamp});
  factory _PointValue.fromJson(Map<String, dynamic> json) => _$PointValueFromJson(json);

@override@JsonKey(name: 'point_id') final  String pointId;
@override final  Object? value;
@override final  String? timestamp;

/// Create a copy of PointValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointValueCopyWith<_PointValue> get copyWith => __$PointValueCopyWithImpl<_PointValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PointValue&&(identical(other.pointId, pointId) || other.pointId == pointId)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pointId,const DeepCollectionEquality().hash(value),timestamp);

@override
String toString() {
  return 'PointValue(pointId: $pointId, value: $value, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$PointValueCopyWith<$Res> implements $PointValueCopyWith<$Res> {
  factory _$PointValueCopyWith(_PointValue value, $Res Function(_PointValue) _then) = __$PointValueCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'point_id') String pointId, Object? value, String? timestamp
});




}
/// @nodoc
class __$PointValueCopyWithImpl<$Res>
    implements _$PointValueCopyWith<$Res> {
  __$PointValueCopyWithImpl(this._self, this._then);

  final _PointValue _self;
  final $Res Function(_PointValue) _then;

/// Create a copy of PointValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pointId = null,Object? value = freezed,Object? timestamp = freezed,}) {
  return _then(_PointValue(
pointId: null == pointId ? _self.pointId : pointId // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
