// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TeamContext _$TeamContextFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'personal':
      return _Personal.fromJson(json);
    case 'team':
      return _Team.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'TeamContext',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$TeamContext {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() personal,
    required TResult Function(String id, String name) team,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? personal,
    TResult? Function(String id, String name)? team,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? personal,
    TResult Function(String id, String name)? team,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Personal value) personal,
    required TResult Function(_Team value) team,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Personal value)? personal,
    TResult? Function(_Team value)? team,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Personal value)? personal,
    TResult Function(_Team value)? team,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this TeamContext to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamContextCopyWith<$Res> {
  factory $TeamContextCopyWith(
          TeamContext value, $Res Function(TeamContext) then) =
      _$TeamContextCopyWithImpl<$Res, TeamContext>;
}

/// @nodoc
class _$TeamContextCopyWithImpl<$Res, $Val extends TeamContext>
    implements $TeamContextCopyWith<$Res> {
  _$TeamContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamContext
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PersonalImplCopyWith<$Res> {
  factory _$$PersonalImplCopyWith(
          _$PersonalImpl value, $Res Function(_$PersonalImpl) then) =
      __$$PersonalImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PersonalImplCopyWithImpl<$Res>
    extends _$TeamContextCopyWithImpl<$Res, _$PersonalImpl>
    implements _$$PersonalImplCopyWith<$Res> {
  __$$PersonalImplCopyWithImpl(
      _$PersonalImpl _value, $Res Function(_$PersonalImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamContext
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$PersonalImpl extends _Personal {
  const _$PersonalImpl({final String? $type})
      : $type = $type ?? 'personal',
        super._();

  factory _$PersonalImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'TeamContext.personal()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PersonalImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() personal,
    required TResult Function(String id, String name) team,
  }) {
    return personal();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? personal,
    TResult? Function(String id, String name)? team,
  }) {
    return personal?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? personal,
    TResult Function(String id, String name)? team,
    required TResult orElse(),
  }) {
    if (personal != null) {
      return personal();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Personal value) personal,
    required TResult Function(_Team value) team,
  }) {
    return personal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Personal value)? personal,
    TResult? Function(_Team value)? team,
  }) {
    return personal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Personal value)? personal,
    TResult Function(_Team value)? team,
    required TResult orElse(),
  }) {
    if (personal != null) {
      return personal(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalImplToJson(
      this,
    );
  }
}

abstract class _Personal extends TeamContext {
  const factory _Personal() = _$PersonalImpl;
  const _Personal._() : super._();

  factory _Personal.fromJson(Map<String, dynamic> json) =
      _$PersonalImpl.fromJson;
}

/// @nodoc
abstract class _$$TeamImplCopyWith<$Res> {
  factory _$$TeamImplCopyWith(
          _$TeamImpl value, $Res Function(_$TeamImpl) then) =
      __$$TeamImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$TeamImplCopyWithImpl<$Res>
    extends _$TeamContextCopyWithImpl<$Res, _$TeamImpl>
    implements _$$TeamImplCopyWith<$Res> {
  __$$TeamImplCopyWithImpl(_$TeamImpl _value, $Res Function(_$TeamImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$TeamImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamImpl extends _Team {
  const _$TeamImpl({required this.id, required this.name, final String? $type})
      : $type = $type ?? 'team',
        super._();

  factory _$TeamImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'TeamContext.team(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of TeamContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamImplCopyWith<_$TeamImpl> get copyWith =>
      __$$TeamImplCopyWithImpl<_$TeamImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() personal,
    required TResult Function(String id, String name) team,
  }) {
    return team(id, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? personal,
    TResult? Function(String id, String name)? team,
  }) {
    return team?.call(id, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? personal,
    TResult Function(String id, String name)? team,
    required TResult orElse(),
  }) {
    if (team != null) {
      return team(id, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Personal value) personal,
    required TResult Function(_Team value) team,
  }) {
    return team(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Personal value)? personal,
    TResult? Function(_Team value)? team,
  }) {
    return team?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Personal value)? personal,
    TResult Function(_Team value)? team,
    required TResult orElse(),
  }) {
    if (team != null) {
      return team(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamImplToJson(
      this,
    );
  }
}

abstract class _Team extends TeamContext {
  const factory _Team({required final String id, required final String name}) =
      _$TeamImpl;
  const _Team._() : super._();

  factory _Team.fromJson(Map<String, dynamic> json) = _$TeamImpl.fromJson;

  String get id;
  String get name;

  /// Create a copy of TeamContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamImplCopyWith<_$TeamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
