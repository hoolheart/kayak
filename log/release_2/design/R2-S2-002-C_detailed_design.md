# Detailed Design — Team Management Frontend (R2-S2-002-C)

**Task**: R2-S2-002-C — Team Management Frontend Detailed Design  
**Designer**: sw-jerry  
**Date**: 2026-05-11  
**Status**: Draft  
**Dependencies**:
- R2-S2-001-B (Backend API Design)
- R2-S2-002-A (UI Design Spec & Figma)
- R2-S2-002-B (Test Cases)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Page Routing](#2-page-routing)
3. [State Management Design](#3-state-management-design)
4. [Widget Tree](#4-widget-tree)
5. [API Integration](#5-api-integration)
6. [Permission System](#6-permission-system)
7. [Responsive Layout](#7-responsive-layout)
8. [Theme Integration](#8-theme-integration)
9. [Appendix](#9-appendix)

---

## 1. Overview

### 1.1 Purpose

This document provides the detailed technical design for the Team Management Frontend (R2-S2-002-C). It specifies the frontend architecture, state management, component hierarchy, API integration patterns, permission system, responsive layout strategy, and theme integration for all team-related UI features.

### 1.2 Design Principles

1. **Interface-Driven Development**: Define `TeamServiceInterface` before implementation
2. **Dependency Inversion**: UI depends on service interfaces, not concrete implementations
3. **Single Source of Truth**: `currentTeamContextProvider` is the sole authority for team context
4. **Reactive UI**: All team-dependent UIs automatically re-render when context changes
5. **Permission-First**: Every action UI checks permissions before rendering

### 1.3 Scope

| Component | Route | Description |
|-----------|-------|-------------|
| Team List Page | `/teams` | Grid of user's teams with role badges |
| Team Detail Page | `/teams/:id` | Team info, members, danger zone |
| AppBar Team Selector | Global | Context switcher in AppBar |
| Ownership Selector | Dialog | Resource creation ownership selection |

---

## 2. Page Routing

### 2.1 Route Definitions

```dart
/// Team management route constants
class TeamRoutes {
  TeamRoutes._();

  /// Team list page
  static const String list = '/teams';

  /// Team detail page
  static const String detail = '/teams/:id';

  /// Helper to build detail path
  static String detailPath(String teamId) => '/teams/$teamId';
}
```

### 2.2 Router Integration

Update `lib/core/router/app_router.dart` to add team routes within the existing `ShellRoute`:

```dart
ShellRoute(
  builder: (context, state, child) => AppShell(
    selectedRoute: state.uri.path,
    child: child,
  ),
  routes: [
    // ... existing routes ...

    // Team routes (NEW)
    GoRoute(
      path: '/teams',
      builder: (context, state) => const TeamListPage(),
    ),
    GoRoute(
      path: '/teams/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TeamDetailPage(teamId: id);
      },
    ),
  ],
)
```

### 2.3 Route Guards

Team detail page requires membership validation. Implement as a **widget-level guard** (not router-level, to allow graceful error UI):

```dart
/// Team detail page with automatic membership check
class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teamDetailProvider(teamId));

    return detailAsync.when(
      data: (detail) => _TeamDetailContent(detail: detail),
      loading: () => const TeamDetailSkeleton(),
      error: (error, _) => TeamErrorState(
        error: error,
        onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
      ),
    );
  }
}
```

**Guard Behavior**:

| Condition | HTTP Status | UI Behavior |
|-----------|-------------|-------------|
| User is member | 200 | Render detail page |
| User is not member | 403 | Show `TeamAccessDenied` widget |
| Team not found | 404 | Show `TeamNotFound` widget with link to `/teams` |
| Network error | — | Show `NetworkErrorState` with retry button |

### 2.4 Deep Linking

URL `/teams/team-001` directly navigates to the detail page. The provider auto-fetches team data on first watch.

```dart
// Deep link support: go_router handles path params automatically
// state.pathParameters['id'] is passed to TeamDetailPage constructor
```

### 2.5 Page Navigation Flow

```mermaid
flowchart TD
    A[Any Page] -->|Click 'Teams' in Sidebar| B[/teams]
    B -->|Click Team Card| C[/teams/:id]
    B -->|Click 'Create Team'| D[CreateTeamDialog]
    D -->|Success| B
    C -->|Click 'Edit'| E[EditTeamDialog]
    E -->|Save| C
    C -->|Click 'Invite'| F[InviteMemberDialog]
    F -->|Send| C
    C -->|Click 'Delete'| G[DeleteTeamDialog]
    G -->|Confirm| B
    C -->|Click 'Leave'| H[LeaveTeamDialog]
    H -->|Confirm| B
    C -->|Click 'Remove Member'| I[RemoveMemberDialog]
    I -->|Confirm| C
    C -->|Click Team in Breadcrumb| B
```

---

## 3. State Management Design

### 3.1 Architecture Overview

The team management frontend uses **Riverpod** with the following provider hierarchy:

```mermaid
flowchart TB
    subgraph Domain["Domain Layer"]
        TC[TeamContext]
        TR[TeamRole]
    end

    subgraph Service["Service Layer"]
        TSI[TeamServiceInterface]
    end

    subgraph Providers["Provider Layer"]
        CTP[currentTeamContextProvider<br/>StateNotifier&lt;TeamContext&gt;]
        TP[teamsProvider<br/>FutureProvider&lt;List&lt;Team&gt;&gt;]
        TDP[teamDetailProvider<br/>FutureProvider.family&lt;TeamDetail&gt;]
        MP[membersProvider<br/>FutureProvider.family&lt;List&lt;Member&gt;&gt;]
        IP[invitationsProvider<br/>FutureProvider.family&lt;List&lt;Invitation&gt;&gt;]
        TSIP[teamServiceProvider<br/>Provider&lt;TeamServiceInterface&gt;]
    end

    subgraph UI["UI Layer"]
        TL[TeamListPage]
        TD[TeamDetailPage]
        TS[TeamSelector]
        OS[OwnershipSelector]
    end

    TSI --> TSIP
    TSIP --> TP
    TSIP --> TDP
    TSIP --> MP
    TSIP --> IP

    CTP --> TP
    CTP --> TDP
    CTP --> MP
    CTP -.->|"team switch triggers"| OS

    TP --> TL
    TDP --> TD
    MP --> TD
    IP --> TD
    CTP --> TS
    TP --> TS
    TP --> OS
```

### 3.2 Provider Specifications

#### 3.2.1 `currentTeamContextProvider` — Current Team Context

```dart
/// Represents the current workspace context: personal or a specific team
@freezed
class TeamContext with _$TeamContext {
  const factory TeamContext.personal() = _Personal;
  const factory TeamContext.team({
    required String id,
    required String name,
  }) = _Team;

  const TeamContext._();

  bool get isPersonal => this is _Personal;
  String? get teamId => map(
        personal: (_) => null,
        team: (t) => t.id,
      );
}

/// StateNotifier for team context with persistence
class CurrentTeamContextNotifier extends StateNotifier<TeamContext> {
  CurrentTeamContextNotifier(this._storage) : super(const TeamContext.personal());
  final SharedPreferences _storage;

  static const _key = 'current_team_context';

  Future<void> initialize() async {
    final saved = _storage.getString(_key);
    if (saved != null) {
      try {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        state = TeamContext.fromJson(json);
      } catch (_) {
        state = const TeamContext.personal();
      }
    }
  }

  Future<void> switchToPersonal() async {
    state = const TeamContext.personal();
    await _storage.remove(_key);
  }

  Future<void> switchToTeam({required String id, required String name}) async {
    state = TeamContext.team(id: id, name: name);
    await _storage.setString(_key, jsonEncode(state.toJson()));
  }
}

/// Global provider for current team context
final currentTeamContextProvider =
    StateNotifierProvider<CurrentTeamContextNotifier, TeamContext>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrentTeamContextNotifier(prefs);
});
```

#### 3.2.2 `teamsProvider` — Team List

```dart
/// Team list provider - auto-refreshes when context changes
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final service = ref.watch(teamServiceProvider);
  return service.getMyTeams();
});
```

**Behavior**:
- Fetches on first watch
- Auto-refreshes when `teamServiceProvider` changes
- Manual refresh: `ref.invalidate(teamsProvider)`

#### 3.2.3 `teamDetailProvider` — Team Detail (Family)

```dart
/// Team detail provider - family keyed by team ID
final teamDetailProvider = FutureProvider.family<TeamDetail, String>((ref, teamId) async {
  final service = ref.watch(teamServiceProvider);
  return service.getTeamDetail(teamId);
});
```

**Behavior**:
- Keyed by `teamId` string
- Independent caching per team ID
- Auto-disposes when no longer watched

#### 3.2.4 `membersProvider` — Member List (Family)

```dart
/// Team members provider - family keyed by team ID
final membersProvider = FutureProvider.family<List<TeamMember>, String>((ref, teamId) async {
  final service = ref.watch(teamServiceProvider);
  return service.getTeamMembers(teamId);
});
```

#### 3.2.5 `invitationsProvider` — Invitations (Family)

```dart
/// Pending invitations provider - family keyed by team ID
final invitationsProvider = FutureProvider.family<List<Invitation>, String>((ref, teamId) async {
  final service = ref.watch(teamServiceProvider);
  return service.getPendingInvitations(teamId);
});
```

### 3.3 Provider Dependencies Diagram

```mermaid
flowchart LR
    subgraph Global["Global State"]
        CTP[currentTeamContextProvider]
        Auth[authStateProvider]
    end

    subgraph Service["Service Layer"]
        TS[teamServiceProvider]
    end

    subgraph Data["Data Providers"]
        TP[teamsProvider]
        TDP[teamDetailProvider]
        MP[membersProvider]
        IP[invitationsProvider]
    end

    subgraph Computed["Computed Providers"]
        CUR[currentUserRoleProvider]
        CP[canPerformActionProvider]
    end

    Auth --> TS
    TS --> TP
    TS --> TDP
    TS --> MP
    TS --> IP
    TDP --> CUR
    CUR --> CP
    CTP -.->|"triggers reload"| TP
```

### 3.4 Team Switch Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant TS as TeamSelector
    participant CTP as currentTeamContextProvider
    participant SP as teamsProvider
    participant RP as ResourceProviders
    participant UI as CurrentPage

    User->>TS: Select "研发团队"
    TS->>CTP: switchToTeam(id: 'team-001')
    CTP->>CTP: Update state to TeamContext.team()
    CTP->>CTP: Persist to SharedPreferences
    CTP-->>TS: State updated

    Note over TS: Dropdown closes, button<br/>label updates to "研发团队"

    TS->>SP: invalidate(teamsProvider)
    SP->>SP: Refetch team list

    TS->>RP: Invalidate all resource providers
    Note over RP: workbenches, methods,<br/>experiments providers
    RP->>RP: Refetch with new team context

    RP-->>UI: New data emitted
    UI->>UI: Rebuild with team-scoped resources
    TS-->>User: Snackbar: "已切换到 研发团队"
```

---

## 4. Widget Tree

### 4.1 Team List Page (`/teams`)

```
TeamListPage (ConsumerWidget)
├── AppShell (from ShellRoute)
│   ├── Sidebar (existing)
│   └── Content
│       ├── BreadcrumbNav ("首页 > 团队")
│       └── Padding (24px)
│           ├── PageHeader
│           │   ├── Text "团队管理" (Title Large)
│           │   └── FilledButton "创建团队"
│           └── Body
│               ├── teamsProvider.when
│               │   ├── loading: TeamListSkeleton
│               │   ├── error: NetworkErrorState
│               │   └── data: TeamListContent
│               │       ├── EmptyTeamListState (if empty)
│               │       └── TeamGrid
│               │           └── GridView
│               │               └── TeamCard (×N)
│               └── ResponsiveBuilder
│                   ├── Desktop: 3 columns
│                   ├── Tablet: 2 columns
│                   └── Mobile: 1 column + FAB
```

### 4.2 Team Detail Page (`/teams/:id`)

```
TeamDetailPage (ConsumerWidget, teamId param)
├── AppShell
│   └── Content
│       ├── BreadcrumbNav ("首页 > 团队 > [Name]")
│       └── teamDetailProvider.when
│           ├── loading: TeamDetailSkeleton
│           ├── error: TeamErrorState
│           └── data: TeamDetailContent
│               └── SingleChildScrollView
│                   ├── TeamHeaderCard
│                   │   ├── Row
│                   │   │   ├── TeamIcon (64px, Primary Container)
│                   │   │   ├── TeamInfo (name + description)
│                   │   │   └── EditButton (conditional)
│                   │   └── StatsRow
│                   │       ├── 成员: N
│                   │       ├── 创建者: Name
│                   │       └── 创建于: Date
│                   ├── MembersSection
│                   │   ├── SectionHeader
│                   │   │   ├── Title "团队成员"
│                   │   │   ├── CountBadge
│                   │   │   └── InviteButton (conditional)
│                   │   └── membersProvider.when
│                   │       ├── loading: MembersSkeleton
│                   │       └── data: MembersList
│                   │           └── MemberListItem (×N)
│                   │               ├── Avatar
│               │               │   ├── CircleAvatar (40px)
│               │               │   └── Initials or Icon
│               │               ├── TitleRow
│               │               │   ├── Name (Body Large)
│               │               │   └── RoleBadge (Chip)
│               │               ├── Subtitle: Email
│               │               └── Trailing: PopupMenuButton (conditional)
│               │                   ├── 设为 Admin
│               │                   ├── 降为 Member
│               │                   └── 移除成员 (Error)
│               └── DangerZoneSection (conditional)
│                   └── DangerZoneCard
│                       ├── DeleteTeamAction (Owner only)
│                       └── LeaveTeamAction (Admin/Member)
```

### 4.3 AppBar Team Selector

```
AppBarWithTeamSelector (ConsumerWidget)
├── AppBar
│   ├── Title Area
│   │   ├── Page Title (existing)
│   │   └── TeamSelectorButton (NEW)
│   │       ├── InkWell
│   │       │   ├── Leading Icon (account_circle / groups)
│   │       │   ├── Label Text ("个人空间" / team name)
│   │       │   └── Trailing Icon (arrow_drop_down)
│   │       └── PopupMenuButton<TeamContext>
│   │           └── DropdownPanel (280px)
│   │               ├── "当前工作空间" Header
│   │               ├── PersonalOption
│   │               │   ├── Icon: account_circle
│   │               │   ├── Title: "个人空间"
│   │               │   └── Trailing: check (if selected)
│   │               ├── Divider
│   │               ├── "我的团队" Header
│   │               ├── TeamOptions (scrollable, max 5)
│   │               │   └── TeamOptionItem (×N)
│   │               │       ├── Icon: groups
│   │               │       ├── Title: team name
│   │               │       ├── Subtitle: role
│   │               │       └── Trailing: check (if selected)
│   │               ├── "查看全部团队" Link (if >5)
│   │               ├── Divider
│   │               └── "创建新团队" Link
│   └── Existing Actions...
```

### 4.4 Ownership Selector (Dialog Component)

```
OwnershipSelector (ConsumerWidget)
└── Column
    ├── Label "归属" (Label Medium)
    └── RadioGroup<TeamContext>
        ├── OwnershipOption: Personal
        │   ├── Radio<TeamContext>
        │   ├── Icon: account_circle
        │   ├── Title: "个人空间"
        │   └── Subtitle: "仅自己可见"
        └── OwnershipOption: Team
            ├── Radio<TeamContext>
            ├── Icon: groups
            ├── Title: "团队名称" / "团队"
            └── Subtitle: "团队成员可访问"
            └── [Expanded Team Sub-options] (if multiple teams)
                └── TeamSubOption (×N)
                    ├── Dot indicator
                    └── Team name
        └── PermissionHint (if team selected)
            ├── Icon: info
            └── Text: "此资源将创建在 [Team]..."
```

---

## 5. API Integration

### 5.1 Service Interface

```dart
/// Team service interface - follows Interface-Driven Development
abstract class TeamServiceInterface {
  /// GET /api/v1/teams
  Future<List<Team>> getMyTeams();

  /// POST /api/v1/teams
  Future<Team> createTeam({required String name, String? description});

  /// GET /api/v1/teams/:id
  Future<TeamDetail> getTeamDetail(String teamId);

  /// PUT /api/v1/teams/:id
  Future<TeamDetail> updateTeam(
    String teamId, {
    required String name,
    String? description,
  });

  /// DELETE /api/v1/teams/:id
  Future<void> deleteTeam(String teamId);

  /// GET /api/v1/teams/:id/members
  Future<List<TeamMember>> getTeamMembers(String teamId);

  /// DELETE /api/v1/teams/:id/members/:userId
  Future<void> removeMember(String teamId, String userId);

  /// POST /api/v1/teams/:id/invitations
  Future<Invitation> inviteMember(
    String teamId, {
    required String email,
    required TeamRole role,
  });

  /// GET /api/v1/teams/:id/invitations (pending)
  Future<List<Invitation>> getPendingInvitations(String teamId);

  /// POST /api/v1/teams/:id/leave
  Future<void> leaveTeam(String teamId);
}
```

### 5.2 Service Implementation

```dart
/// Team service implementation using Dio
class TeamService implements TeamServiceInterface {
  TeamService(this._apiClient);
  final AuthenticatedApiClient _apiClient;

  @override
  Future<List<Team>> getMyTeams() async {
    final response = await _apiClient.get('/api/v1/teams');
    final data = response.data['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Team> createTeam({required String name, String? description}) async {
    final response = await _apiClient.post(
      '/api/v1/teams',
      data: {'name': name, 'description': description},
    );
    return Team.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ... other implementations
}

/// Provider for team service
final teamServiceProvider = Provider<TeamServiceInterface>((ref) {
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return TeamService(apiClient);
});
```

### 5.3 Error Handling

```dart
/// Team API error types
class TeamApiException implements Exception {
  TeamApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 422;
}
```

**Error Mapping**:

| HTTP Status | Error Type | User Message |
|-------------|------------|--------------|
| 400 | Bad Request | "请求参数错误" |
| 401 | Unauthorized | "登录已过期，请重新登录" |
| 403 | Forbidden | "没有权限执行此操作" |
| 404 | Not Found | "团队不存在" |
| 409 | Conflict | "团队名称已存在" / "用户已是成员" |
| 422 | Validation | "表单验证失败" (with field errors) |
| 500+ | Server Error | "服务器错误，请稍后重试" |

### 5.4 API Call Flow with Error Handling

```mermaid
sequenceDiagram
    autonumber
    participant UI as Widget
    participant P as Provider
    participant S as TeamService
    participant API as Backend API
    participant EH as ErrorHandler

    UI->>P: ref.watch(teamsProvider)
    P->>S: getMyTeams()
    S->>API: GET /api/v1/teams

    alt Success (200)
        API-->>S: {code: 200, data: {...}}
        S-->>P: List<Team>
        P-->>UI: AsyncData(teams)
        UI->>UI: Render team grid
    else Unauthorized (401)
        API-->>S: {code: 401, message: "Unauthorized"}
        S->>EH: throw TeamApiException("Unauthorized", statusCode: 401)
        EH->>EH: Clear tokens, redirect to login
        P-->>UI: AsyncError(unauthorized)
        UI->>UI: Show "登录已过期" + redirect
    else Forbidden (403)
        API-->>S: {code: 403, message: "Forbidden"}
        S->>EH: throw TeamApiException("Forbidden", statusCode: 403)
        P-->>UI: AsyncError(forbidden)
        UI->>UI: Show access denied state
    else Network Error
        API--xS: Connection timeout / no network
        S->>EH: throw TeamApiException("Network error")
        P-->>UI: AsyncError(network)
        UI->>UI: Show network error + retry button
    end

    UI->>P: ref.invalidate(teamsProvider)
    P->>P: Clear cache, re-fetch
```

### 5.5 Loading States

| Operation | Loading UI | Duration Estimate |
|-----------|-----------|-------------------|
| Team list fetch | Skeleton cards (3 items) | < 500ms |
| Team detail fetch | Header + member skeletons | < 500ms |
| Create team | Button shows CircularProgressIndicator | 200-800ms |
| Invite member | Button shows CircularProgressIndicator | 200-500ms |
| Delete team | Full-screen overlay + spinner | 300-1000ms |
| Team switch | Content area fade + Snackbar | Instant |

---

## 6. Permission System

### 6.1 Role Hierarchy

```dart
enum TeamRole {
  owner(3),
  admin(2),
  member(1);

  const TeamRole(this.level);
  final int level;

  bool satisfies(TeamRole required) => level >= required.level;
}
```

### 6.2 Permission Matrix

| Action | Owner | Admin | Member |
|--------|-------|-------|--------|
| View team info | ✅ | ✅ | ✅ |
| Edit team info | ✅ | ✅ | ❌ |
| Delete team | ✅ | ❌ | ❌ |
| Invite members | ✅ | ✅ | ❌ |
| Remove Member | ✅ | ✅ | ❌ |
| Remove Admin | ✅ | ❌ | ❌ |
| Remove Owner | ❌ | ❌ | ❌ |
| Leave team | ❌ | ✅ | ✅ |
| View member list | ✅ | ✅ | ✅ |

### 6.3 Frontend Permission Checks

```dart
/// Computed provider for current user's role in a team
final currentUserRoleProvider = Provider.family<TeamRole?, String>((ref, teamId) {
  final detailAsync = ref.watch(teamDetailProvider(teamId));
  return detailAsync.whenOrNull(
    data: (detail) => detail.currentUserRole,
  );
});

/// Helper extension for permission checks
extension TeamRolePermission on TeamRole {
  bool get canEditTeam => satisfies(TeamRole.admin);
  bool get canDeleteTeam => this == TeamRole.owner;
  bool get canInviteMembers => satisfies(TeamRole.admin);
  bool get canRemoveMembers => satisfies(TeamRole.admin);
  bool get canLeaveTeam => this != TeamRole.owner;
  bool get canManageMembers => satisfies(TeamRole.admin);
}
```

### 6.4 Conditional Widget Visibility

```dart
/// Example: Team detail page conditional rendering
class TeamDetailContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider(teamId));

    return Column(
      children: [
        TeamHeaderCard(
          // Edit button visible to Owner/Admin
          showEditButton: role?.canEditTeam ?? false,
        ),
        MembersSection(
          // Invite button visible to Owner/Admin
          showInviteButton: role?.canInviteMembers ?? false,
          // Member actions visible to Owner/Admin
          showMemberActions: role?.canManageMembers ?? false,
        ),
        // Danger zone only for those who can act
        if (role != null)
          DangerZoneSection(
            showDeleteTeam: role.canDeleteTeam,
            showLeaveTeam: role.canLeaveTeam,
          ),
      ],
    );
  }
}
```

### 6.5 Conditional Routing

```dart
/// Route guard for team detail - redirect if no access
class TeamDetailPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teamDetailProvider(teamId));

    return detailAsync.when(
      data: (detail) => TeamDetailContent(detail: detail),
      loading: () => const TeamDetailSkeleton(),
      error: (error, _) {
        if (error is TeamApiException && error.isForbidden) {
          return const TeamAccessDenied();
        }
        if (error is TeamApiException && error.isNotFound) {
          return TeamNotFound(onBack: () => context.go('/teams'));
        }
        return NetworkErrorState(
          error: error,
          onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        );
      },
    );
  }
}
```

---

## 7. Responsive Layout

### 7.1 Breakpoint Definitions

```dart
/// Responsive breakpoints
class Breakpoints {
  Breakpoints._();

  static const double mobile = 768;
  static const double tablet = 1280;
  static const double desktop = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}
```

### 7.2 Team List Page Responsive

| Element | Desktop (≥1280px) | Tablet (≥768px) | Mobile (<768px) |
|---------|-------------------|-----------------|-----------------|
| Sidebar | 240px expanded | 72px collapsed | Hidden (bottom nav) |
| Grid columns | 3 | 2 | 1 |
| Card width | ~380px | ~380px | 100% |
| Page padding | 24px | 16px | 12px |
| Create button | AppBar FilledButton | AppBar FilledButton | FAB |
| Card spacing | 16px | 16px | 12px |

```dart
class TeamGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (width >= 1280) {
      crossAxisCount = 3;
    } else if (width >= 768) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => TeamCard(team: teams[index]),
    );
  }
}
```

### 7.3 Team Detail Page Responsive

| Element | Desktop (≥1280px) | Tablet (≥768px) | Mobile (<768px) |
|---------|-------------------|-----------------|-----------------|
| Sidebar | 240px expanded | 72px collapsed | Hidden |
| Team icon | 64px | 64px | 48px |
| Member list | Full width | Full width | Full width |
| Danger zone | Full width | Full width | Vertical stack |
| Content padding | 24px | 16px | 12px |
| Popup menu | Standard PopupMenu | Standard PopupMenu | BottomSheet |

### 7.4 AppBar Selector Responsive

| Element | Desktop (≥1280px) | Tablet (≥768px) | Mobile (<768px) |
|---------|-------------------|-----------------|-----------------|
| Position | Title area | Title area | Actions area |
| Label | Full text | Full text | Icon only (or abbreviated) |
| Dropdown | 280px dropdown | 280px dropdown | Full-width BottomSheet |

---

## 8. Theme Integration

### 8.1 Theme Strategy

Team management UI fully integrates with the existing `AppTheme` (Material Design 3) and extends it with team-specific color tokens.

### 8.2 Team Color Tokens

```dart
/// Team-specific color tokens - adapts to current theme
class TeamColorTokens {
  const TeamColorTokens._();

  /// Get tokens based on current brightness
  static TeamColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? TeamColors.dark : TeamColors.light;
  }
}

/// Team color values
class TeamColors {
  const TeamColors({
    required this.ownerBadgeBg,
    required this.ownerBadgeText,
    required this.adminBadgeBg,
    required this.adminBadgeText,
    required this.memberBadgeBg,
    required this.memberBadgeText,
    required this.dangerZoneBg,
    required this.dangerZoneBorder,
    required this.dangerZoneTitle,
    required this.permissionHintBg,
    required this.permissionHintBorder,
    required this.permissionHintIcon,
  });

  // Light theme colors
  static const light = TeamColors(
    ownerBadgeBg: Color(0xFFBBDEFB),
    ownerBadgeText: Color(0xFF1565C0),
    adminBadgeBg: Color(0xFFE0F7FA),
    adminBadgeText: Color(0xFF006064),
    memberBadgeBg: Color(0xFFEEEEEE),
    memberBadgeText: Color(0xFF757575),
    dangerZoneBg: Color(0xFFFFEBEE),
    dangerZoneBorder: Color(0xFFC62828),
    dangerZoneTitle: Color(0xFFC62828),
    permissionHintBg: Color(0xFFE3F2FD),
    permissionHintBorder: Color(0xFF1976D2),
    permissionHintIcon: Color(0xFF1976D2),
  );

  // Dark theme colors
  static const dark = TeamColors(
    ownerBadgeBg: Color(0xFF1565C0),
    ownerBadgeText: Color(0xFFE3F2FD),
    adminBadgeBg: Color(0xFF006064),
    adminBadgeText: Color(0xFFE0F7FA),
    memberBadgeBg: Color(0xFF2D2D2D),
    memberBadgeText: Color(0xFF9E9E9E),
    dangerZoneBg: Color(0xFFB71C1C),
    dangerZoneBorder: Color(0xFFEF5350),
    dangerZoneTitle: Color(0xFFEF5350),
    permissionHintBg: Color(0xFF0D47A1),
    permissionHintBorder: Color(0xFF90CAF9),
    permissionHintIcon: Color(0xFF90CAF9),
  );

  final Color ownerBadgeBg;
  final Color ownerBadgeText;
  final Color adminBadgeBg;
  final Color adminBadgeText;
  final Color memberBadgeBg;
  final Color memberBadgeText;
  final Color dangerZoneBg;
  final Color dangerZoneBorder;
  final Color dangerZoneTitle;
  final Color permissionHintBg;
  final Color permissionHintBorder;
  final Color permissionHintIcon;
}
```

### 8.3 Role Badge Colors

```dart
/// Role badge widget with theme-aware colors
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.size = BadgeSize.normal});
  final TeamRole role;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = TeamColorTokens.of(context);
    final (bg, fg) = switch (role) {
      TeamRole.owner => (colors.ownerBadgeBg, colors.ownerBadgeText),
      TeamRole.admin => (colors.adminBadgeBg, colors.adminBadgeText),
      TeamRole.member => (colors.memberBadgeBg, colors.memberBadgeText),
    };

    return Chip(
      label: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: size == BadgeSize.small ? 11 : 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: bg,
      padding: size == BadgeSize.small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size == BadgeSize.small ? 6 : 8),
      ),
      side: BorderSide.none,
    );
  }
}
```

### 8.4 Danger Zone Colors

```dart
/// Danger zone card with theme-aware error colors
class DangerZoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = TeamColorTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.dangerZoneBg,
        border: Border.all(color: colors.dangerZoneBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: colors.dangerZoneTitle, size: 20),
              const SizedBox(width: 8),
              Text(
                '危险操作',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.dangerZoneTitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Divider(color: colors.dangerZoneBorder),
          // Danger actions...
        ],
      ),
    );
  }
}
```

### 8.5 Theme Integration Checklist

| Element | Light Theme | Dark Theme | Dynamic |
|---------|-------------|------------|---------|
| Team cards | Surface white | Surface Container Low | ✅ via ThemeData |
| Role badges | Custom tokens (see 8.2) | Custom tokens (see 8.2) | ✅ via TeamColorTokens |
| Danger zone | Error Container | Error Container (dark) | ✅ via TeamColorTokens |
| AppBar selector | On Primary | On Surface | ✅ via AppBarTheme |
| Permission hint | Info Container | Info Container (dark) | ✅ via TeamColorTokens |
| Member list hover | Surface Container Lowest | darkSurfaceContainerLowest | ✅ via ThemeData |

---

## 9. Appendix

### 9.1 Data Models

```dart
/// Team list item model
@freezed
class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    String? description,
    required int memberCount,
    required TeamRole role,
    required DateTime createdAt,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}

/// Team detail model
@freezed
class TeamDetail with _$TeamDetail {
  const factory TeamDetail({
    required String id,
    required String name,
    String? description,
    required String ownerId,
    required TeamRole currentUserRole,
    required int memberCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamDetail;

  factory TeamDetail.fromJson(Map<String, dynamic> json) =>
      _$TeamDetailFromJson(json);
}

/// Team member model
@freezed
class TeamMember with _$TeamMember {
  const factory TeamMember({
    required String id,
    required String userId,
    required String name,
    required String email,
    String? avatarUrl,
    required TeamRole role,
    required DateTime joinedAt,
  }) = _TeamMember;

  factory TeamMember.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberFromJson(json);
}

/// Invitation model
@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required String id,
    required String teamId,
    required String email,
    required String code,
    required TeamRole role,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) = _Invitation;

  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);
}
```

### 9.2 Directory Structure

```
kayak-frontend/lib/
├── features/
│   └── team/
│       ├── models/
│       │   ├── team.dart                    # Team, TeamDetail, TeamMember
│       │   ├── team.freezed.dart            # Generated
│       │   ├── team.g.dart                  # Generated
│       │   ├── team_context.dart            # TeamContext
│       │   └── team_role.dart               # TeamRole enum
│       ├── providers/
│       │   ├── team_list_provider.dart      # teamsProvider
│       │   ├── team_detail_provider.dart    # teamDetailProvider
│       │   ├── team_members_provider.dart   # membersProvider
│       │   ├── team_invitations_provider.dart # invitationsProvider
│       │   └── team_context_provider.dart   # currentTeamContextProvider
│       ├── services/
│       │   ├── team_service_interface.dart  # TeamServiceInterface
│       │   └── team_service.dart            # TeamService implementation
│       ├── screens/
│       │   ├── team_list_page.dart          # /teams
│       │   └── team_detail_page.dart        # /teams/:id
│       ├── widgets/
│       │   ├── team_card.dart               # Team card component
│       │   ├── team_grid.dart               # Responsive grid
│       │   ├── team_header_card.dart        # Detail page header
│       │   ├── members_list.dart            # Members section
│       │   ├── member_list_item.dart        # Single member row
│       │   ├── role_badge.dart              # Role badge chip
│       │   ├── danger_zone_card.dart        # Danger zone section
│       │   ├── team_selector.dart           # AppBar selector button
│       │   ├── team_selector_dropdown.dart  # Dropdown panel
│       │   ├── ownership_selector.dart      # Dialog ownership radio
│       │   ├── create_team_dialog.dart      # Create team dialog
│       │   ├── edit_team_dialog.dart        # Edit team dialog
│       │   ├── invite_member_dialog.dart    # Invite dialog
│       │   ├── delete_team_dialog.dart      # Delete confirmation
│       │   ├── leave_team_dialog.dart       # Leave confirmation
│       │   ├── remove_member_dialog.dart    # Remove confirmation
│       │   ├── empty_team_list_state.dart   # Empty state
│       │   ├── team_error_state.dart        # Error state
│       │   └── team_list_skeleton.dart      # Loading skeleton
│       └── theme/
│           └── team_colors.dart             # TeamColorTokens
├── core/
│   └── router/
│       └── app_router.dart                  # Add /teams, /teams/:id routes
└── ...
```

### 9.3 Key Provider Summary

| Provider | Type | Purpose | Key |
|----------|------|---------|-----|
| `currentTeamContextProvider` | StateNotifierProvider | Global team context | — |
| `teamsProvider` | FutureProvider | List of user's teams | — |
| `teamDetailProvider` | FutureProvider.family | Team detail by ID | teamId |
| `membersProvider` | FutureProvider.family | Members by team ID | teamId |
| `invitationsProvider` | FutureProvider.family | Pending invitations | teamId |
| `currentUserRoleProvider` | Provider.family | Current user's role | teamId |
| `teamServiceProvider` | Provider | TeamService instance | — |

### 9.4 Verification Checklist

#### Pages/Components Coverage

| Requirement | Status | Location in Doc |
|-------------|--------|-----------------|
| `/teams` — Team List Page | ✅ Covered | §4.1, §7.2 |
| `/teams/:id` — Team Detail Page | ✅ Covered | §4.2, §7.3 |
| AppBar team selector | ✅ Covered | §4.3, §7.4 |
| Resource creation dialog update | ✅ Covered | §4.4 |

#### State Management Coverage

| Requirement | Status | Location in Doc |
|-------------|--------|-----------------|
| `currentTeamContextProvider` | ✅ Covered | §3.2.1 |
| `teamsProvider` | ✅ Covered | §3.2.2 |
| `teamDetailProvider` | ✅ Covered | §3.2.3 |
| `membersProvider` | ✅ Covered | §3.2.4 |
| `invitationsProvider` | ✅ Covered | §3.2.5 |

#### Key Behaviors Coverage

| Requirement | Status | Location in Doc |
|-------------|--------|-----------------|
| Team switch reloads resources | ✅ Covered | §3.4 (sequence diagram) |
| Permission-based UI | ✅ Covered | §6 |
| Real-time member list updates | ✅ Covered | §3.2.4, §5.1 |
| Form validation | ✅ Covered | §5.3 (validation errors) |

#### Design Requirements Coverage

| Requirement | Status | Location in Doc |
|-------------|--------|-----------------|
| Page Routing | ✅ Covered | §2 |
| State Management Design | ✅ Covered | §3 |
| Widget Tree | ✅ Covered | §4 |
| API Integration | ✅ Covered | §5 |
| Permission System | ✅ Covered | §6 |
| Responsive Layout | ✅ Covered | §7 |
| Theme Integration | ✅ Covered | §8 |

#### Mermaid Diagrams Coverage

| Required Diagram | Status | Location in Doc |
|-----------------|--------|-----------------|
| State management architecture | ✅ Included | §3.1, §3.3 |
| Page navigation flow | ✅ Included | §2.5 |
| Team switch sequence | ✅ Included | §3.4 |
| API call flow with error handling | ✅ Included | §5.4 |

---

**Document End**

*This detailed design follows the Interface-Driven Development and SOLID principles. All UI components depend on abstractions (`TeamServiceInterface`) rather than concrete implementations. State management uses Riverpod with clear provider hierarchies. The design is fully consistent with the backend API (R2-S2-001-B), UI spec (R2-S2-002-A), and test cases (R2-S2-002-B).*
