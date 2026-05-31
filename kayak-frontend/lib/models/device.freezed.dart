// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Device {

 String get id;@JsonKey(name: 'workbench_id') String get workbenchId;@JsonKey(name: 'parent_id') String? get parentId; String get name;@JsonKey(name: 'protocol_type') ProtocolType get protocolType;@JsonKey(name: 'protocol_params') Map<String, dynamic>? get protocolParams; String? get manufacturer; String? get model; String? get sn; String get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCopyWith<Device> get copyWith => _$DeviceCopyWithImpl<Device>(this as Device, _$identity);

  /// Serializes this Device to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Device&&(identical(other.id, id) || other.id == id)&&(identical(other.workbenchId, workbenchId) || other.workbenchId == workbenchId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.protocolType, protocolType) || other.protocolType == protocolType)&&const DeepCollectionEquality().equals(other.protocolParams, protocolParams)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.sn, sn) || other.sn == sn)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workbenchId,parentId,name,protocolType,const DeepCollectionEquality().hash(protocolParams),manufacturer,model,sn,status,createdAt,updatedAt);

@override
String toString() {
  return 'Device(id: $id, workbenchId: $workbenchId, parentId: $parentId, name: $name, protocolType: $protocolType, protocolParams: $protocolParams, manufacturer: $manufacturer, model: $model, sn: $sn, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DeviceCopyWith<$Res>  {
  factory $DeviceCopyWith(Device value, $Res Function(Device) _then) = _$DeviceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'workbench_id') String workbenchId,@JsonKey(name: 'parent_id') String? parentId, String name,@JsonKey(name: 'protocol_type') ProtocolType protocolType,@JsonKey(name: 'protocol_params') Map<String, dynamic>? protocolParams, String? manufacturer, String? model, String? sn, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$DeviceCopyWithImpl<$Res>
    implements $DeviceCopyWith<$Res> {
  _$DeviceCopyWithImpl(this._self, this._then);

  final Device _self;
  final $Res Function(Device) _then;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workbenchId = null,Object? parentId = freezed,Object? name = null,Object? protocolType = null,Object? protocolParams = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? sn = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workbenchId: null == workbenchId ? _self.workbenchId : workbenchId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protocolType: null == protocolType ? _self.protocolType : protocolType // ignore: cast_nullable_to_non_nullable
as ProtocolType,protocolParams: freezed == protocolParams ? _self.protocolParams : protocolParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,sn: freezed == sn ? _self.sn : sn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Device].
extension DevicePatterns on Device {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Device value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Device() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Device value)  $default,){
final _that = this;
switch (_that) {
case _Device():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Device value)?  $default,){
final _that = this;
switch (_that) {
case _Device() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'workbench_id')  String workbenchId, @JsonKey(name: 'parent_id')  String? parentId,  String name, @JsonKey(name: 'protocol_type')  ProtocolType protocolType, @JsonKey(name: 'protocol_params')  Map<String, dynamic>? protocolParams,  String? manufacturer,  String? model,  String? sn,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that.id,_that.workbenchId,_that.parentId,_that.name,_that.protocolType,_that.protocolParams,_that.manufacturer,_that.model,_that.sn,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'workbench_id')  String workbenchId, @JsonKey(name: 'parent_id')  String? parentId,  String name, @JsonKey(name: 'protocol_type')  ProtocolType protocolType, @JsonKey(name: 'protocol_params')  Map<String, dynamic>? protocolParams,  String? manufacturer,  String? model,  String? sn,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Device():
return $default(_that.id,_that.workbenchId,_that.parentId,_that.name,_that.protocolType,_that.protocolParams,_that.manufacturer,_that.model,_that.sn,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'workbench_id')  String workbenchId, @JsonKey(name: 'parent_id')  String? parentId,  String name, @JsonKey(name: 'protocol_type')  ProtocolType protocolType, @JsonKey(name: 'protocol_params')  Map<String, dynamic>? protocolParams,  String? manufacturer,  String? model,  String? sn,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that.id,_that.workbenchId,_that.parentId,_that.name,_that.protocolType,_that.protocolParams,_that.manufacturer,_that.model,_that.sn,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Device implements Device {
  const _Device({required this.id, @JsonKey(name: 'workbench_id') required this.workbenchId, @JsonKey(name: 'parent_id') this.parentId, required this.name, @JsonKey(name: 'protocol_type') required this.protocolType, @JsonKey(name: 'protocol_params') final  Map<String, dynamic>? protocolParams, this.manufacturer, this.model, this.sn, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _protocolParams = protocolParams;
  factory _Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

@override final  String id;
@override@JsonKey(name: 'workbench_id') final  String workbenchId;
@override@JsonKey(name: 'parent_id') final  String? parentId;
@override final  String name;
@override@JsonKey(name: 'protocol_type') final  ProtocolType protocolType;
 final  Map<String, dynamic>? _protocolParams;
@override@JsonKey(name: 'protocol_params') Map<String, dynamic>? get protocolParams {
  final value = _protocolParams;
  if (value == null) return null;
  if (_protocolParams is EqualUnmodifiableMapView) return _protocolParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? manufacturer;
@override final  String? model;
@override final  String? sn;
@override final  String status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceCopyWith<_Device> get copyWith => __$DeviceCopyWithImpl<_Device>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Device&&(identical(other.id, id) || other.id == id)&&(identical(other.workbenchId, workbenchId) || other.workbenchId == workbenchId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.protocolType, protocolType) || other.protocolType == protocolType)&&const DeepCollectionEquality().equals(other._protocolParams, _protocolParams)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.sn, sn) || other.sn == sn)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workbenchId,parentId,name,protocolType,const DeepCollectionEquality().hash(_protocolParams),manufacturer,model,sn,status,createdAt,updatedAt);

@override
String toString() {
  return 'Device(id: $id, workbenchId: $workbenchId, parentId: $parentId, name: $name, protocolType: $protocolType, protocolParams: $protocolParams, manufacturer: $manufacturer, model: $model, sn: $sn, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DeviceCopyWith<$Res> implements $DeviceCopyWith<$Res> {
  factory _$DeviceCopyWith(_Device value, $Res Function(_Device) _then) = __$DeviceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'workbench_id') String workbenchId,@JsonKey(name: 'parent_id') String? parentId, String name,@JsonKey(name: 'protocol_type') ProtocolType protocolType,@JsonKey(name: 'protocol_params') Map<String, dynamic>? protocolParams, String? manufacturer, String? model, String? sn, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$DeviceCopyWithImpl<$Res>
    implements _$DeviceCopyWith<$Res> {
  __$DeviceCopyWithImpl(this._self, this._then);

  final _Device _self;
  final $Res Function(_Device) _then;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workbenchId = null,Object? parentId = freezed,Object? name = null,Object? protocolType = null,Object? protocolParams = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? sn = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Device(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workbenchId: null == workbenchId ? _self.workbenchId : workbenchId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protocolType: null == protocolType ? _self.protocolType : protocolType // ignore: cast_nullable_to_non_nullable
as ProtocolType,protocolParams: freezed == protocolParams ? _self._protocolParams : protocolParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,sn: freezed == sn ? _self.sn : sn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$DeviceTreeNode {

 String get id;@JsonKey(name: 'workbench_id') String get workbenchId;@JsonKey(name: 'parent_id') String? get parentId; String get name;@JsonKey(name: 'protocol_type') ProtocolType get protocolType;@JsonKey(name: 'protocol_params') Map<String, dynamic>? get protocolParams; String? get manufacturer; String? get model; String? get sn; String get status; List<DeviceTreeNode> get children;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of DeviceTreeNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceTreeNodeCopyWith<DeviceTreeNode> get copyWith => _$DeviceTreeNodeCopyWithImpl<DeviceTreeNode>(this as DeviceTreeNode, _$identity);

  /// Serializes this DeviceTreeNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceTreeNode&&(identical(other.id, id) || other.id == id)&&(identical(other.workbenchId, workbenchId) || other.workbenchId == workbenchId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.protocolType, protocolType) || other.protocolType == protocolType)&&const DeepCollectionEquality().equals(other.protocolParams, protocolParams)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.sn, sn) || other.sn == sn)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.children, children)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workbenchId,parentId,name,protocolType,const DeepCollectionEquality().hash(protocolParams),manufacturer,model,sn,status,const DeepCollectionEquality().hash(children),createdAt,updatedAt);

@override
String toString() {
  return 'DeviceTreeNode(id: $id, workbenchId: $workbenchId, parentId: $parentId, name: $name, protocolType: $protocolType, protocolParams: $protocolParams, manufacturer: $manufacturer, model: $model, sn: $sn, status: $status, children: $children, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DeviceTreeNodeCopyWith<$Res>  {
  factory $DeviceTreeNodeCopyWith(DeviceTreeNode value, $Res Function(DeviceTreeNode) _then) = _$DeviceTreeNodeCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'workbench_id') String workbenchId,@JsonKey(name: 'parent_id') String? parentId, String name,@JsonKey(name: 'protocol_type') ProtocolType protocolType,@JsonKey(name: 'protocol_params') Map<String, dynamic>? protocolParams, String? manufacturer, String? model, String? sn, String status, List<DeviceTreeNode> children,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$DeviceTreeNodeCopyWithImpl<$Res>
    implements $DeviceTreeNodeCopyWith<$Res> {
  _$DeviceTreeNodeCopyWithImpl(this._self, this._then);

  final DeviceTreeNode _self;
  final $Res Function(DeviceTreeNode) _then;

/// Create a copy of DeviceTreeNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workbenchId = null,Object? parentId = freezed,Object? name = null,Object? protocolType = null,Object? protocolParams = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? sn = freezed,Object? status = null,Object? children = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workbenchId: null == workbenchId ? _self.workbenchId : workbenchId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protocolType: null == protocolType ? _self.protocolType : protocolType // ignore: cast_nullable_to_non_nullable
as ProtocolType,protocolParams: freezed == protocolParams ? _self.protocolParams : protocolParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,sn: freezed == sn ? _self.sn : sn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<DeviceTreeNode>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceTreeNode].
extension DeviceTreeNodePatterns on DeviceTreeNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceTreeNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceTreeNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceTreeNode value)  $default,){
final _that = this;
switch (_that) {
case _DeviceTreeNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceTreeNode value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceTreeNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'workbench_id')  String workbenchId, @JsonKey(name: 'parent_id')  String? parentId,  String name, @JsonKey(name: 'protocol_type')  ProtocolType protocolType, @JsonKey(name: 'protocol_params')  Map<String, dynamic>? protocolParams,  String? manufacturer,  String? model,  String? sn,  String status,  List<DeviceTreeNode> children, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceTreeNode() when $default != null:
return $default(_that.id,_that.workbenchId,_that.parentId,_that.name,_that.protocolType,_that.protocolParams,_that.manufacturer,_that.model,_that.sn,_that.status,_that.children,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'workbench_id')  String workbenchId, @JsonKey(name: 'parent_id')  String? parentId,  String name, @JsonKey(name: 'protocol_type')  ProtocolType protocolType, @JsonKey(name: 'protocol_params')  Map<String, dynamic>? protocolParams,  String? manufacturer,  String? model,  String? sn,  String status,  List<DeviceTreeNode> children, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DeviceTreeNode():
return $default(_that.id,_that.workbenchId,_that.parentId,_that.name,_that.protocolType,_that.protocolParams,_that.manufacturer,_that.model,_that.sn,_that.status,_that.children,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'workbench_id')  String workbenchId, @JsonKey(name: 'parent_id')  String? parentId,  String name, @JsonKey(name: 'protocol_type')  ProtocolType protocolType, @JsonKey(name: 'protocol_params')  Map<String, dynamic>? protocolParams,  String? manufacturer,  String? model,  String? sn,  String status,  List<DeviceTreeNode> children, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DeviceTreeNode() when $default != null:
return $default(_that.id,_that.workbenchId,_that.parentId,_that.name,_that.protocolType,_that.protocolParams,_that.manufacturer,_that.model,_that.sn,_that.status,_that.children,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceTreeNode implements DeviceTreeNode {
  const _DeviceTreeNode({required this.id, @JsonKey(name: 'workbench_id') required this.workbenchId, @JsonKey(name: 'parent_id') this.parentId, required this.name, @JsonKey(name: 'protocol_type') required this.protocolType, @JsonKey(name: 'protocol_params') final  Map<String, dynamic>? protocolParams, this.manufacturer, this.model, this.sn, required this.status, final  List<DeviceTreeNode> children = const [], @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _protocolParams = protocolParams,_children = children;
  factory _DeviceTreeNode.fromJson(Map<String, dynamic> json) => _$DeviceTreeNodeFromJson(json);

@override final  String id;
@override@JsonKey(name: 'workbench_id') final  String workbenchId;
@override@JsonKey(name: 'parent_id') final  String? parentId;
@override final  String name;
@override@JsonKey(name: 'protocol_type') final  ProtocolType protocolType;
 final  Map<String, dynamic>? _protocolParams;
@override@JsonKey(name: 'protocol_params') Map<String, dynamic>? get protocolParams {
  final value = _protocolParams;
  if (value == null) return null;
  if (_protocolParams is EqualUnmodifiableMapView) return _protocolParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? manufacturer;
@override final  String? model;
@override final  String? sn;
@override final  String status;
 final  List<DeviceTreeNode> _children;
@override@JsonKey() List<DeviceTreeNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of DeviceTreeNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceTreeNodeCopyWith<_DeviceTreeNode> get copyWith => __$DeviceTreeNodeCopyWithImpl<_DeviceTreeNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceTreeNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceTreeNode&&(identical(other.id, id) || other.id == id)&&(identical(other.workbenchId, workbenchId) || other.workbenchId == workbenchId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.protocolType, protocolType) || other.protocolType == protocolType)&&const DeepCollectionEquality().equals(other._protocolParams, _protocolParams)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.sn, sn) || other.sn == sn)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workbenchId,parentId,name,protocolType,const DeepCollectionEquality().hash(_protocolParams),manufacturer,model,sn,status,const DeepCollectionEquality().hash(_children),createdAt,updatedAt);

@override
String toString() {
  return 'DeviceTreeNode(id: $id, workbenchId: $workbenchId, parentId: $parentId, name: $name, protocolType: $protocolType, protocolParams: $protocolParams, manufacturer: $manufacturer, model: $model, sn: $sn, status: $status, children: $children, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DeviceTreeNodeCopyWith<$Res> implements $DeviceTreeNodeCopyWith<$Res> {
  factory _$DeviceTreeNodeCopyWith(_DeviceTreeNode value, $Res Function(_DeviceTreeNode) _then) = __$DeviceTreeNodeCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'workbench_id') String workbenchId,@JsonKey(name: 'parent_id') String? parentId, String name,@JsonKey(name: 'protocol_type') ProtocolType protocolType,@JsonKey(name: 'protocol_params') Map<String, dynamic>? protocolParams, String? manufacturer, String? model, String? sn, String status, List<DeviceTreeNode> children,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$DeviceTreeNodeCopyWithImpl<$Res>
    implements _$DeviceTreeNodeCopyWith<$Res> {
  __$DeviceTreeNodeCopyWithImpl(this._self, this._then);

  final _DeviceTreeNode _self;
  final $Res Function(_DeviceTreeNode) _then;

/// Create a copy of DeviceTreeNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workbenchId = null,Object? parentId = freezed,Object? name = null,Object? protocolType = null,Object? protocolParams = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? sn = freezed,Object? status = null,Object? children = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DeviceTreeNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workbenchId: null == workbenchId ? _self.workbenchId : workbenchId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protocolType: null == protocolType ? _self.protocolType : protocolType // ignore: cast_nullable_to_non_nullable
as ProtocolType,protocolParams: freezed == protocolParams ? _self._protocolParams : protocolParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,sn: freezed == sn ? _self.sn : sn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<DeviceTreeNode>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
