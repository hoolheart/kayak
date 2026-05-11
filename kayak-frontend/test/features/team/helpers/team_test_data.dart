/// Team test data helpers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kayak_frontend/features/team/models/team_context.dart';
import 'package:kayak_frontend/features/team/models/team_models.dart';
import 'package:kayak_frontend/features/team/models/team_role.dart';

/// Mock teams data
final mockTeams = [
  Team(
    id: 'team-001',
    name: '研发团队',
    description: '核心产品研发团队',
    memberCount: 12,
    createdAt: DateTime.parse('2026-01-15T00:00:00Z'),
    role: TeamRole.owner,
  ),
  Team(
    id: 'team-002',
    name: 'QA 测试团队',
    description: '质量保证与测试',
    memberCount: 5,
    createdAt: DateTime.parse('2026-02-20T00:00:00Z'),
    role: TeamRole.admin,
  ),
  Team(
    id: 'team-003',
    name: '产品团队',
    description: '产品设计与规划',
    memberCount: 8,
    createdAt: DateTime.parse('2026-03-10T00:00:00Z'),
    role: TeamRole.member,
  ),
];

/// Mock team detail
final mockTeamDetail = TeamDetail(
  id: 'team-001',
  name: '研发团队',
  description: '核心产品研发团队',
  ownerId: 'user-001',
  currentUserRole: TeamRole.owner,
  memberCount: 3,
  createdAt: DateTime.parse('2026-01-15T00:00:00Z'),
  updatedAt: DateTime.parse('2026-01-15T00:00:00Z'),
);

/// Mock members
final mockMembers = [
  TeamMember(
    id: 'user-001',
    userId: 'user-001',
    name: '张三',
    email: 'zhangsan@example.com',
    role: TeamRole.owner,
    joinedAt: DateTime.parse('2026-01-15T00:00:00Z'),
  ),
  TeamMember(
    id: 'user-002',
    userId: 'user-002',
    name: '李四',
    email: 'lisi@example.com',
    role: TeamRole.admin,
    joinedAt: DateTime.parse('2026-01-16T00:00:00Z'),
  ),
  TeamMember(
    id: 'user-003',
    userId: 'user-003',
    name: '王五',
    email: 'wangwu@example.com',
    role: TeamRole.member,
    joinedAt: DateTime.parse('2026-01-17T00:00:00Z'),
  ),
];

/// Mock contexts
final mockPersonalContext = const TeamContext.personal();
final mockTeamContext =
    TeamContext.team(id: 'team-001', name: '研发团队');

/// Async state helpers
final mockTeamListLoaded = AsyncData<List<Team>>(mockTeams);
final mockTeamListEmpty = AsyncData<List<Team>>([]);
final mockTeamListLoading = const AsyncLoading<List<Team>>();
final mockTeamListError = AsyncError<List<Team>>(
  '网络连接失败',
  StackTrace.empty,
);

final mockTeamDetailLoaded = AsyncData<TeamDetail>(mockTeamDetail);
final mockTeamDetailError403 = AsyncError<TeamDetail>(
  '没有权限访问该团队',
  StackTrace.empty,
);
final mockTeamDetailError404 = AsyncError<TeamDetail>(
  '团队不存在',
  StackTrace.empty,
);
