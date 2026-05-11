// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamImpl _$$TeamImplFromJson(Map<String, dynamic> json) => _$TeamImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: (json['memberCount'] as num).toInt(),
      role: $enumDecode(_$TeamRoleEnumMap, json['role']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TeamImplToJson(_$TeamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'memberCount': instance.memberCount,
      'role': _$TeamRoleEnumMap[instance.role]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TeamRoleEnumMap = {
  TeamRole.owner: 'owner',
  TeamRole.admin: 'admin',
  TeamRole.member: 'member',
};

_$TeamDetailImpl _$$TeamDetailImplFromJson(Map<String, dynamic> json) =>
    _$TeamDetailImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      currentUserRole: $enumDecode(_$TeamRoleEnumMap, json['currentUserRole']),
      memberCount: (json['memberCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TeamDetailImplToJson(_$TeamDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'ownerId': instance.ownerId,
      'currentUserRole': _$TeamRoleEnumMap[instance.currentUserRole]!,
      'memberCount': instance.memberCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$TeamMemberImpl _$$TeamMemberImplFromJson(Map<String, dynamic> json) =>
    _$TeamMemberImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: $enumDecode(_$TeamRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$$TeamMemberImplToJson(_$TeamMemberImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'role': _$TeamRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
    };

_$InvitationImpl _$$InvitationImplFromJson(Map<String, dynamic> json) =>
    _$InvitationImpl(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      email: json['email'] as String,
      code: json['code'] as String,
      role: $enumDecode(_$TeamRoleEnumMap, json['role']),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$InvitationImplToJson(_$InvitationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'email': instance.email,
      'code': instance.code,
      'role': _$TeamRoleEnumMap[instance.role]!,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$TeamUserImpl _$$TeamUserImplFromJson(Map<String, dynamic> json) =>
    _$TeamUserImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$$TeamUserImplToJson(_$TeamUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };
