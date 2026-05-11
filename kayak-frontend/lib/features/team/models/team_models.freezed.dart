// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Team _$TeamFromJson(Map<String, dynamic> json) {
  return _Team.fromJson(json);
}

/// @nodoc
mixin _$Team {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get memberCount => throw _privateConstructorUsedError;
  TeamRole get role => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Team to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Team
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamCopyWith<Team> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamCopyWith<$Res> {
  factory $TeamCopyWith(Team value, $Res Function(Team) then) =
      _$TeamCopyWithImpl<$Res, Team>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      int memberCount,
      TeamRole role,
      DateTime createdAt});
}

/// @nodoc
class _$TeamCopyWithImpl<$Res, $Val extends Team>
    implements $TeamCopyWith<$Res> {
  _$TeamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Team
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? memberCount = null,
    Object? role = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamImplCopyWith<$Res> implements $TeamCopyWith<$Res> {
  factory _$$TeamImplCopyWith(
          _$TeamImpl value, $Res Function(_$TeamImpl) then) =
      __$$TeamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      int memberCount,
      TeamRole role,
      DateTime createdAt});
}

/// @nodoc
class __$$TeamImplCopyWithImpl<$Res>
    extends _$TeamCopyWithImpl<$Res, _$TeamImpl>
    implements _$$TeamImplCopyWith<$Res> {
  __$$TeamImplCopyWithImpl(_$TeamImpl _value, $Res Function(_$TeamImpl) _then)
      : super(_value, _then);

  /// Create a copy of Team
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? memberCount = null,
    Object? role = null,
    Object? createdAt = null,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamImpl implements _Team {
  const _$TeamImpl(
      {required this.id,
      required this.name,
      this.description,
      required this.memberCount,
      required this.role,
      required this.createdAt});

  factory _$TeamImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final int memberCount;
  @override
  final TeamRole role;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Team(id: $id, name: $name, description: $description, memberCount: $memberCount, role: $role, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, description, memberCount, role, createdAt);

  /// Create a copy of Team
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamImplCopyWith<_$TeamImpl> get copyWith =>
      __$$TeamImplCopyWithImpl<_$TeamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamImplToJson(
      this,
    );
  }
}

abstract class _Team implements Team {
  const factory _Team(
      {required final String id,
      required final String name,
      final String? description,
      required final int memberCount,
      required final TeamRole role,
      required final DateTime createdAt}) = _$TeamImpl;

  factory _Team.fromJson(Map<String, dynamic> json) = _$TeamImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  int get memberCount;
  @override
  TeamRole get role;
  @override
  DateTime get createdAt;

  /// Create a copy of Team
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamImplCopyWith<_$TeamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeamDetail _$TeamDetailFromJson(Map<String, dynamic> json) {
  return _TeamDetail.fromJson(json);
}

/// @nodoc
mixin _$TeamDetail {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  TeamRole get currentUserRole => throw _privateConstructorUsedError;
  int get memberCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TeamDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamDetailCopyWith<TeamDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamDetailCopyWith<$Res> {
  factory $TeamDetailCopyWith(
          TeamDetail value, $Res Function(TeamDetail) then) =
      _$TeamDetailCopyWithImpl<$Res, TeamDetail>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String ownerId,
      TeamRole currentUserRole,
      int memberCount,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$TeamDetailCopyWithImpl<$Res, $Val extends TeamDetail>
    implements $TeamDetailCopyWith<$Res> {
  _$TeamDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? ownerId = null,
    Object? currentUserRole = null,
    Object? memberCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      currentUserRole: null == currentUserRole
          ? _value.currentUserRole
          : currentUserRole // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
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
abstract class _$$TeamDetailImplCopyWith<$Res>
    implements $TeamDetailCopyWith<$Res> {
  factory _$$TeamDetailImplCopyWith(
          _$TeamDetailImpl value, $Res Function(_$TeamDetailImpl) then) =
      __$$TeamDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String ownerId,
      TeamRole currentUserRole,
      int memberCount,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$TeamDetailImplCopyWithImpl<$Res>
    extends _$TeamDetailCopyWithImpl<$Res, _$TeamDetailImpl>
    implements _$$TeamDetailImplCopyWith<$Res> {
  __$$TeamDetailImplCopyWithImpl(
      _$TeamDetailImpl _value, $Res Function(_$TeamDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? ownerId = null,
    Object? currentUserRole = null,
    Object? memberCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TeamDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      currentUserRole: null == currentUserRole
          ? _value.currentUserRole
          : currentUserRole // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
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
class _$TeamDetailImpl implements _TeamDetail {
  const _$TeamDetailImpl(
      {required this.id,
      required this.name,
      this.description,
      required this.ownerId,
      required this.currentUserRole,
      required this.memberCount,
      required this.createdAt,
      required this.updatedAt});

  factory _$TeamDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String ownerId;
  @override
  final TeamRole currentUserRole;
  @override
  final int memberCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TeamDetail(id: $id, name: $name, description: $description, ownerId: $ownerId, currentUserRole: $currentUserRole, memberCount: $memberCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.currentUserRole, currentUserRole) ||
                other.currentUserRole == currentUserRole) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, ownerId,
      currentUserRole, memberCount, createdAt, updatedAt);

  /// Create a copy of TeamDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamDetailImplCopyWith<_$TeamDetailImpl> get copyWith =>
      __$$TeamDetailImplCopyWithImpl<_$TeamDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamDetailImplToJson(
      this,
    );
  }
}

abstract class _TeamDetail implements TeamDetail {
  const factory _TeamDetail(
      {required final String id,
      required final String name,
      final String? description,
      required final String ownerId,
      required final TeamRole currentUserRole,
      required final int memberCount,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$TeamDetailImpl;

  factory _TeamDetail.fromJson(Map<String, dynamic> json) =
      _$TeamDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get ownerId;
  @override
  TeamRole get currentUserRole;
  @override
  int get memberCount;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of TeamDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamDetailImplCopyWith<_$TeamDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeamMember _$TeamMemberFromJson(Map<String, dynamic> json) {
  return _TeamMember.fromJson(json);
}

/// @nodoc
mixin _$TeamMember {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  TeamRole get role => throw _privateConstructorUsedError;
  DateTime get joinedAt => throw _privateConstructorUsedError;

  /// Serializes this TeamMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamMemberCopyWith<TeamMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamMemberCopyWith<$Res> {
  factory $TeamMemberCopyWith(
          TeamMember value, $Res Function(TeamMember) then) =
      _$TeamMemberCopyWithImpl<$Res, TeamMember>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String name,
      String email,
      String? avatarUrl,
      TeamRole role,
      DateTime joinedAt});
}

/// @nodoc
class _$TeamMemberCopyWithImpl<$Res, $Val extends TeamMember>
    implements $TeamMemberCopyWith<$Res> {
  _$TeamMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? email = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamMemberImplCopyWith<$Res>
    implements $TeamMemberCopyWith<$Res> {
  factory _$$TeamMemberImplCopyWith(
          _$TeamMemberImpl value, $Res Function(_$TeamMemberImpl) then) =
      __$$TeamMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String name,
      String email,
      String? avatarUrl,
      TeamRole role,
      DateTime joinedAt});
}

/// @nodoc
class __$$TeamMemberImplCopyWithImpl<$Res>
    extends _$TeamMemberCopyWithImpl<$Res, _$TeamMemberImpl>
    implements _$$TeamMemberImplCopyWith<$Res> {
  __$$TeamMemberImplCopyWithImpl(
      _$TeamMemberImpl _value, $Res Function(_$TeamMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? email = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(_$TeamMemberImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamMemberImpl implements _TeamMember {
  const _$TeamMemberImpl(
      {required this.id,
      required this.userId,
      required this.name,
      required this.email,
      this.avatarUrl,
      required this.role,
      required this.joinedAt});

  factory _$TeamMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamMemberImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String email;
  @override
  final String? avatarUrl;
  @override
  final TeamRole role;
  @override
  final DateTime joinedAt;

  @override
  String toString() {
    return 'TeamMember(id: $id, userId: $userId, name: $name, email: $email, avatarUrl: $avatarUrl, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, userId, name, email, avatarUrl, role, joinedAt);

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamMemberImplCopyWith<_$TeamMemberImpl> get copyWith =>
      __$$TeamMemberImplCopyWithImpl<_$TeamMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamMemberImplToJson(
      this,
    );
  }
}

abstract class _TeamMember implements TeamMember {
  const factory _TeamMember(
      {required final String id,
      required final String userId,
      required final String name,
      required final String email,
      final String? avatarUrl,
      required final TeamRole role,
      required final DateTime joinedAt}) = _$TeamMemberImpl;

  factory _TeamMember.fromJson(Map<String, dynamic> json) =
      _$TeamMemberImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  String get email;
  @override
  String? get avatarUrl;
  @override
  TeamRole get role;
  @override
  DateTime get joinedAt;

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamMemberImplCopyWith<_$TeamMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Invitation _$InvitationFromJson(Map<String, dynamic> json) {
  return _Invitation.fromJson(json);
}

/// @nodoc
mixin _$Invitation {
  String get id => throw _privateConstructorUsedError;
  String get teamId => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  TeamRole get role => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Invitation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvitationCopyWith<Invitation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvitationCopyWith<$Res> {
  factory $InvitationCopyWith(
          Invitation value, $Res Function(Invitation) then) =
      _$InvitationCopyWithImpl<$Res, Invitation>;
  @useResult
  $Res call(
      {String id,
      String teamId,
      String email,
      String code,
      TeamRole role,
      DateTime expiresAt,
      DateTime createdAt});
}

/// @nodoc
class _$InvitationCopyWithImpl<$Res, $Val extends Invitation>
    implements $InvitationCopyWith<$Res> {
  _$InvitationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? teamId = null,
    Object? email = null,
    Object? code = null,
    Object? role = null,
    Object? expiresAt = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvitationImplCopyWith<$Res>
    implements $InvitationCopyWith<$Res> {
  factory _$$InvitationImplCopyWith(
          _$InvitationImpl value, $Res Function(_$InvitationImpl) then) =
      __$$InvitationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String teamId,
      String email,
      String code,
      TeamRole role,
      DateTime expiresAt,
      DateTime createdAt});
}

/// @nodoc
class __$$InvitationImplCopyWithImpl<$Res>
    extends _$InvitationCopyWithImpl<$Res, _$InvitationImpl>
    implements _$$InvitationImplCopyWith<$Res> {
  __$$InvitationImplCopyWithImpl(
      _$InvitationImpl _value, $Res Function(_$InvitationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? teamId = null,
    Object? email = null,
    Object? code = null,
    Object? role = null,
    Object? expiresAt = null,
    Object? createdAt = null,
  }) {
    return _then(_$InvitationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TeamRole,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvitationImpl implements _Invitation {
  const _$InvitationImpl(
      {required this.id,
      required this.teamId,
      required this.email,
      required this.code,
      required this.role,
      required this.expiresAt,
      required this.createdAt});

  factory _$InvitationImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvitationImplFromJson(json);

  @override
  final String id;
  @override
  final String teamId;
  @override
  final String email;
  @override
  final String code;
  @override
  final TeamRole role;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Invitation(id: $id, teamId: $teamId, email: $email, code: $code, role: $role, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvitationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, teamId, email, code, role, expiresAt, createdAt);

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvitationImplCopyWith<_$InvitationImpl> get copyWith =>
      __$$InvitationImplCopyWithImpl<_$InvitationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvitationImplToJson(
      this,
    );
  }
}

abstract class _Invitation implements Invitation {
  const factory _Invitation(
      {required final String id,
      required final String teamId,
      required final String email,
      required final String code,
      required final TeamRole role,
      required final DateTime expiresAt,
      required final DateTime createdAt}) = _$InvitationImpl;

  factory _Invitation.fromJson(Map<String, dynamic> json) =
      _$InvitationImpl.fromJson;

  @override
  String get id;
  @override
  String get teamId;
  @override
  String get email;
  @override
  String get code;
  @override
  TeamRole get role;
  @override
  DateTime get expiresAt;
  @override
  DateTime get createdAt;

  /// Create a copy of Invitation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvitationImplCopyWith<_$InvitationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeamUser _$TeamUserFromJson(Map<String, dynamic> json) {
  return _TeamUser.fromJson(json);
}

/// @nodoc
mixin _$TeamUser {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  /// Serializes this TeamUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamUserCopyWith<TeamUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamUserCopyWith<$Res> {
  factory $TeamUserCopyWith(TeamUser value, $Res Function(TeamUser) then) =
      _$TeamUserCopyWithImpl<$Res, TeamUser>;
  @useResult
  $Res call({String id, String name, String email});
}

/// @nodoc
class _$TeamUserCopyWithImpl<$Res, $Val extends TeamUser>
    implements $TeamUserCopyWith<$Res> {
  _$TeamUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamUserImplCopyWith<$Res>
    implements $TeamUserCopyWith<$Res> {
  factory _$$TeamUserImplCopyWith(
          _$TeamUserImpl value, $Res Function(_$TeamUserImpl) then) =
      __$$TeamUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String email});
}

/// @nodoc
class __$$TeamUserImplCopyWithImpl<$Res>
    extends _$TeamUserCopyWithImpl<$Res, _$TeamUserImpl>
    implements _$$TeamUserImplCopyWith<$Res> {
  __$$TeamUserImplCopyWithImpl(
      _$TeamUserImpl _value, $Res Function(_$TeamUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
  }) {
    return _then(_$TeamUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamUserImpl implements _TeamUser {
  const _$TeamUserImpl(
      {required this.id, required this.name, required this.email});

  factory _$TeamUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamUserImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String email;

  @override
  String toString() {
    return 'TeamUser(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, email);

  /// Create a copy of TeamUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamUserImplCopyWith<_$TeamUserImpl> get copyWith =>
      __$$TeamUserImplCopyWithImpl<_$TeamUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamUserImplToJson(
      this,
    );
  }
}

abstract class _TeamUser implements TeamUser {
  const factory _TeamUser(
      {required final String id,
      required final String name,
      required final String email}) = _$TeamUserImpl;

  factory _TeamUser.fromJson(Map<String, dynamic> json) =
      _$TeamUserImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get email;

  /// Create a copy of TeamUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamUserImplCopyWith<_$TeamUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
