// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workbench.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Workbench {

 String get id; String get name; String? get description;@JsonKey(name: 'owner_type') String get ownerType;@JsonKey(name: 'owner_id') String get ownerId; String get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of Workbench
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkbenchCopyWith<Workbench> get copyWith => _$WorkbenchCopyWithImpl<Workbench>(this as Workbench, _$identity);

  /// Serializes this Workbench to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Workbench&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.ownerType, ownerType) || other.ownerType == ownerType)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,ownerType,ownerId,status,createdAt,updatedAt);

@override
String toString() {
  return 'Workbench(id: $id, name: $name, description: $description, ownerType: $ownerType, ownerId: $ownerId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkbenchCopyWith<$Res>  {
  factory $WorkbenchCopyWith(Workbench value, $Res Function(Workbench) _then) = _$WorkbenchCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description,@JsonKey(name: 'owner_type') String ownerType,@JsonKey(name: 'owner_id') String ownerId, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$WorkbenchCopyWithImpl<$Res>
    implements $WorkbenchCopyWith<$Res> {
  _$WorkbenchCopyWithImpl(this._self, this._then);

  final Workbench _self;
  final $Res Function(Workbench) _then;

/// Create a copy of Workbench
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? ownerType = null,Object? ownerId = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,ownerType: null == ownerType ? _self.ownerType : ownerType // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Workbench].
extension WorkbenchPatterns on Workbench {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Workbench value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Workbench() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Workbench value)  $default,){
final _that = this;
switch (_that) {
case _Workbench():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Workbench value)?  $default,){
final _that = this;
switch (_that) {
case _Workbench() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description, @JsonKey(name: 'owner_type')  String ownerType, @JsonKey(name: 'owner_id')  String ownerId,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Workbench() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.ownerType,_that.ownerId,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description, @JsonKey(name: 'owner_type')  String ownerType, @JsonKey(name: 'owner_id')  String ownerId,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Workbench():
return $default(_that.id,_that.name,_that.description,_that.ownerType,_that.ownerId,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description, @JsonKey(name: 'owner_type')  String ownerType, @JsonKey(name: 'owner_id')  String ownerId,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Workbench() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.ownerType,_that.ownerId,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Workbench implements Workbench {
  const _Workbench({required this.id, required this.name, this.description, @JsonKey(name: 'owner_type') required this.ownerType, @JsonKey(name: 'owner_id') required this.ownerId, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _Workbench.fromJson(Map<String, dynamic> json) => _$WorkbenchFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'owner_type') final  String ownerType;
@override@JsonKey(name: 'owner_id') final  String ownerId;
@override final  String status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of Workbench
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkbenchCopyWith<_Workbench> get copyWith => __$WorkbenchCopyWithImpl<_Workbench>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkbenchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Workbench&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.ownerType, ownerType) || other.ownerType == ownerType)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,ownerType,ownerId,status,createdAt,updatedAt);

@override
String toString() {
  return 'Workbench(id: $id, name: $name, description: $description, ownerType: $ownerType, ownerId: $ownerId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkbenchCopyWith<$Res> implements $WorkbenchCopyWith<$Res> {
  factory _$WorkbenchCopyWith(_Workbench value, $Res Function(_Workbench) _then) = __$WorkbenchCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description,@JsonKey(name: 'owner_type') String ownerType,@JsonKey(name: 'owner_id') String ownerId, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$WorkbenchCopyWithImpl<$Res>
    implements _$WorkbenchCopyWith<$Res> {
  __$WorkbenchCopyWithImpl(this._self, this._then);

  final _Workbench _self;
  final $Res Function(_Workbench) _then;

/// Create a copy of Workbench
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? ownerType = null,Object? ownerId = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Workbench(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,ownerType: null == ownerType ? _self.ownerType : ownerType // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CreateWorkbenchRequest {

 String get name; String? get description;@JsonKey(name: 'owner_type') String get ownerType;@JsonKey(name: 'owner_id') String get ownerId;
/// Create a copy of CreateWorkbenchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateWorkbenchRequestCopyWith<CreateWorkbenchRequest> get copyWith => _$CreateWorkbenchRequestCopyWithImpl<CreateWorkbenchRequest>(this as CreateWorkbenchRequest, _$identity);

  /// Serializes this CreateWorkbenchRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateWorkbenchRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.ownerType, ownerType) || other.ownerType == ownerType)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,ownerType,ownerId);

@override
String toString() {
  return 'CreateWorkbenchRequest(name: $name, description: $description, ownerType: $ownerType, ownerId: $ownerId)';
}


}

/// @nodoc
abstract mixin class $CreateWorkbenchRequestCopyWith<$Res>  {
  factory $CreateWorkbenchRequestCopyWith(CreateWorkbenchRequest value, $Res Function(CreateWorkbenchRequest) _then) = _$CreateWorkbenchRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? description,@JsonKey(name: 'owner_type') String ownerType,@JsonKey(name: 'owner_id') String ownerId
});




}
/// @nodoc
class _$CreateWorkbenchRequestCopyWithImpl<$Res>
    implements $CreateWorkbenchRequestCopyWith<$Res> {
  _$CreateWorkbenchRequestCopyWithImpl(this._self, this._then);

  final CreateWorkbenchRequest _self;
  final $Res Function(CreateWorkbenchRequest) _then;

/// Create a copy of CreateWorkbenchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? ownerType = null,Object? ownerId = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,ownerType: null == ownerType ? _self.ownerType : ownerType // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateWorkbenchRequest].
extension CreateWorkbenchRequestPatterns on CreateWorkbenchRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateWorkbenchRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateWorkbenchRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateWorkbenchRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreateWorkbenchRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateWorkbenchRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreateWorkbenchRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? description, @JsonKey(name: 'owner_type')  String ownerType, @JsonKey(name: 'owner_id')  String ownerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateWorkbenchRequest() when $default != null:
return $default(_that.name,_that.description,_that.ownerType,_that.ownerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? description, @JsonKey(name: 'owner_type')  String ownerType, @JsonKey(name: 'owner_id')  String ownerId)  $default,) {final _that = this;
switch (_that) {
case _CreateWorkbenchRequest():
return $default(_that.name,_that.description,_that.ownerType,_that.ownerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? description, @JsonKey(name: 'owner_type')  String ownerType, @JsonKey(name: 'owner_id')  String ownerId)?  $default,) {final _that = this;
switch (_that) {
case _CreateWorkbenchRequest() when $default != null:
return $default(_that.name,_that.description,_that.ownerType,_that.ownerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateWorkbenchRequest implements CreateWorkbenchRequest {
  const _CreateWorkbenchRequest({required this.name, this.description, @JsonKey(name: 'owner_type') required this.ownerType, @JsonKey(name: 'owner_id') required this.ownerId});
  factory _CreateWorkbenchRequest.fromJson(Map<String, dynamic> json) => _$CreateWorkbenchRequestFromJson(json);

@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'owner_type') final  String ownerType;
@override@JsonKey(name: 'owner_id') final  String ownerId;

/// Create a copy of CreateWorkbenchRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateWorkbenchRequestCopyWith<_CreateWorkbenchRequest> get copyWith => __$CreateWorkbenchRequestCopyWithImpl<_CreateWorkbenchRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateWorkbenchRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateWorkbenchRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.ownerType, ownerType) || other.ownerType == ownerType)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,ownerType,ownerId);

@override
String toString() {
  return 'CreateWorkbenchRequest(name: $name, description: $description, ownerType: $ownerType, ownerId: $ownerId)';
}


}

/// @nodoc
abstract mixin class _$CreateWorkbenchRequestCopyWith<$Res> implements $CreateWorkbenchRequestCopyWith<$Res> {
  factory _$CreateWorkbenchRequestCopyWith(_CreateWorkbenchRequest value, $Res Function(_CreateWorkbenchRequest) _then) = __$CreateWorkbenchRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description,@JsonKey(name: 'owner_type') String ownerType,@JsonKey(name: 'owner_id') String ownerId
});




}
/// @nodoc
class __$CreateWorkbenchRequestCopyWithImpl<$Res>
    implements _$CreateWorkbenchRequestCopyWith<$Res> {
  __$CreateWorkbenchRequestCopyWithImpl(this._self, this._then);

  final _CreateWorkbenchRequest _self;
  final $Res Function(_CreateWorkbenchRequest) _then;

/// Create a copy of CreateWorkbenchRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? ownerType = null,Object? ownerId = null,}) {
  return _then(_CreateWorkbenchRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,ownerType: null == ownerType ? _self.ownerType : ownerType // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
