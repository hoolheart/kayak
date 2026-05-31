// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'method.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Method {

 String get id; String get name; String? get description;@JsonKey(name: 'process_definition') Map<String, dynamic> get processDefinition;@JsonKey(name: 'parameter_schema') Map<String, dynamic> get parameterSchema; int get version;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of Method
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MethodCopyWith<Method> get copyWith => _$MethodCopyWithImpl<Method>(this as Method, _$identity);

  /// Serializes this Method to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Method&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.processDefinition, processDefinition)&&const DeepCollectionEquality().equals(other.parameterSchema, parameterSchema)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(processDefinition),const DeepCollectionEquality().hash(parameterSchema),version,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'Method(id: $id, name: $name, description: $description, processDefinition: $processDefinition, parameterSchema: $parameterSchema, version: $version, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MethodCopyWith<$Res>  {
  factory $MethodCopyWith(Method value, $Res Function(Method) _then) = _$MethodCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description,@JsonKey(name: 'process_definition') Map<String, dynamic> processDefinition,@JsonKey(name: 'parameter_schema') Map<String, dynamic> parameterSchema, int version,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$MethodCopyWithImpl<$Res>
    implements $MethodCopyWith<$Res> {
  _$MethodCopyWithImpl(this._self, this._then);

  final Method _self;
  final $Res Function(Method) _then;

/// Create a copy of Method
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? processDefinition = null,Object? parameterSchema = null,Object? version = null,Object? createdBy = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,processDefinition: null == processDefinition ? _self.processDefinition : processDefinition // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,parameterSchema: null == parameterSchema ? _self.parameterSchema : parameterSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Method].
extension MethodPatterns on Method {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Method value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Method() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Method value)  $default,){
final _that = this;
switch (_that) {
case _Method():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Method value)?  $default,){
final _that = this;
switch (_that) {
case _Method() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description, @JsonKey(name: 'process_definition')  Map<String, dynamic> processDefinition, @JsonKey(name: 'parameter_schema')  Map<String, dynamic> parameterSchema,  int version, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Method() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.processDefinition,_that.parameterSchema,_that.version,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description, @JsonKey(name: 'process_definition')  Map<String, dynamic> processDefinition, @JsonKey(name: 'parameter_schema')  Map<String, dynamic> parameterSchema,  int version, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Method():
return $default(_that.id,_that.name,_that.description,_that.processDefinition,_that.parameterSchema,_that.version,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description, @JsonKey(name: 'process_definition')  Map<String, dynamic> processDefinition, @JsonKey(name: 'parameter_schema')  Map<String, dynamic> parameterSchema,  int version, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Method() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.processDefinition,_that.parameterSchema,_that.version,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Method implements Method {
  const _Method({required this.id, required this.name, this.description, @JsonKey(name: 'process_definition') required final  Map<String, dynamic> processDefinition, @JsonKey(name: 'parameter_schema') required final  Map<String, dynamic> parameterSchema, required this.version, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _processDefinition = processDefinition,_parameterSchema = parameterSchema;
  factory _Method.fromJson(Map<String, dynamic> json) => _$MethodFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
 final  Map<String, dynamic> _processDefinition;
@override@JsonKey(name: 'process_definition') Map<String, dynamic> get processDefinition {
  if (_processDefinition is EqualUnmodifiableMapView) return _processDefinition;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_processDefinition);
}

 final  Map<String, dynamic> _parameterSchema;
@override@JsonKey(name: 'parameter_schema') Map<String, dynamic> get parameterSchema {
  if (_parameterSchema is EqualUnmodifiableMapView) return _parameterSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_parameterSchema);
}

@override final  int version;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of Method
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MethodCopyWith<_Method> get copyWith => __$MethodCopyWithImpl<_Method>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MethodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Method&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._processDefinition, _processDefinition)&&const DeepCollectionEquality().equals(other._parameterSchema, _parameterSchema)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_processDefinition),const DeepCollectionEquality().hash(_parameterSchema),version,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'Method(id: $id, name: $name, description: $description, processDefinition: $processDefinition, parameterSchema: $parameterSchema, version: $version, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MethodCopyWith<$Res> implements $MethodCopyWith<$Res> {
  factory _$MethodCopyWith(_Method value, $Res Function(_Method) _then) = __$MethodCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description,@JsonKey(name: 'process_definition') Map<String, dynamic> processDefinition,@JsonKey(name: 'parameter_schema') Map<String, dynamic> parameterSchema, int version,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$MethodCopyWithImpl<$Res>
    implements _$MethodCopyWith<$Res> {
  __$MethodCopyWithImpl(this._self, this._then);

  final _Method _self;
  final $Res Function(_Method) _then;

/// Create a copy of Method
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? processDefinition = null,Object? parameterSchema = null,Object? version = null,Object? createdBy = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Method(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,processDefinition: null == processDefinition ? _self._processDefinition : processDefinition // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,parameterSchema: null == parameterSchema ? _self._parameterSchema : parameterSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MethodParameter {

 String get key; String get type; String? get label;@JsonKey(name: 'default_value') Object? get defaultValue;@JsonKey(name: 'required') bool get isRequired;
/// Create a copy of MethodParameter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MethodParameterCopyWith<MethodParameter> get copyWith => _$MethodParameterCopyWithImpl<MethodParameter>(this as MethodParameter, _$identity);

  /// Serializes this MethodParameter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MethodParameter&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,type,label,const DeepCollectionEquality().hash(defaultValue),isRequired);

@override
String toString() {
  return 'MethodParameter(key: $key, type: $type, label: $label, defaultValue: $defaultValue, isRequired: $isRequired)';
}


}

/// @nodoc
abstract mixin class $MethodParameterCopyWith<$Res>  {
  factory $MethodParameterCopyWith(MethodParameter value, $Res Function(MethodParameter) _then) = _$MethodParameterCopyWithImpl;
@useResult
$Res call({
 String key, String type, String? label,@JsonKey(name: 'default_value') Object? defaultValue,@JsonKey(name: 'required') bool isRequired
});




}
/// @nodoc
class _$MethodParameterCopyWithImpl<$Res>
    implements $MethodParameterCopyWith<$Res> {
  _$MethodParameterCopyWithImpl(this._self, this._then);

  final MethodParameter _self;
  final $Res Function(MethodParameter) _then;

/// Create a copy of MethodParameter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? type = null,Object? label = freezed,Object? defaultValue = freezed,Object? isRequired = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue ,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MethodParameter].
extension MethodParameterPatterns on MethodParameter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MethodParameter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MethodParameter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MethodParameter value)  $default,){
final _that = this;
switch (_that) {
case _MethodParameter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MethodParameter value)?  $default,){
final _that = this;
switch (_that) {
case _MethodParameter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String type,  String? label, @JsonKey(name: 'default_value')  Object? defaultValue, @JsonKey(name: 'required')  bool isRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MethodParameter() when $default != null:
return $default(_that.key,_that.type,_that.label,_that.defaultValue,_that.isRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String type,  String? label, @JsonKey(name: 'default_value')  Object? defaultValue, @JsonKey(name: 'required')  bool isRequired)  $default,) {final _that = this;
switch (_that) {
case _MethodParameter():
return $default(_that.key,_that.type,_that.label,_that.defaultValue,_that.isRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String type,  String? label, @JsonKey(name: 'default_value')  Object? defaultValue, @JsonKey(name: 'required')  bool isRequired)?  $default,) {final _that = this;
switch (_that) {
case _MethodParameter() when $default != null:
return $default(_that.key,_that.type,_that.label,_that.defaultValue,_that.isRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MethodParameter implements MethodParameter {
  const _MethodParameter({required this.key, required this.type, this.label, @JsonKey(name: 'default_value') this.defaultValue, @JsonKey(name: 'required') this.isRequired = false});
  factory _MethodParameter.fromJson(Map<String, dynamic> json) => _$MethodParameterFromJson(json);

@override final  String key;
@override final  String type;
@override final  String? label;
@override@JsonKey(name: 'default_value') final  Object? defaultValue;
@override@JsonKey(name: 'required') final  bool isRequired;

/// Create a copy of MethodParameter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MethodParameterCopyWith<_MethodParameter> get copyWith => __$MethodParameterCopyWithImpl<_MethodParameter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MethodParameterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MethodParameter&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,type,label,const DeepCollectionEquality().hash(defaultValue),isRequired);

@override
String toString() {
  return 'MethodParameter(key: $key, type: $type, label: $label, defaultValue: $defaultValue, isRequired: $isRequired)';
}


}

/// @nodoc
abstract mixin class _$MethodParameterCopyWith<$Res> implements $MethodParameterCopyWith<$Res> {
  factory _$MethodParameterCopyWith(_MethodParameter value, $Res Function(_MethodParameter) _then) = __$MethodParameterCopyWithImpl;
@override @useResult
$Res call({
 String key, String type, String? label,@JsonKey(name: 'default_value') Object? defaultValue,@JsonKey(name: 'required') bool isRequired
});




}
/// @nodoc
class __$MethodParameterCopyWithImpl<$Res>
    implements _$MethodParameterCopyWith<$Res> {
  __$MethodParameterCopyWithImpl(this._self, this._then);

  final _MethodParameter _self;
  final $Res Function(_MethodParameter) _then;

/// Create a copy of MethodParameter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? type = null,Object? label = freezed,Object? defaultValue = freezed,Object? isRequired = null,}) {
  return _then(_MethodParameter(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue ,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
