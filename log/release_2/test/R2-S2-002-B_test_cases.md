# R2-S2-002-B 团队管理前端 — Widget 测试用例

**任务**: R2-S2-002-B 团队管理前端 Widget 测试用例设计  
**测试设计者**: sw-mike  
**日期**: 2026-05-11  
**被测模块**:
- `lib/features/team/screens/team_list_page.dart` (团队列表页)
- `lib/features/team/screens/team_detail_page.dart` (团队详情页)
- `lib/features/team/widgets/team_card.dart` (团队卡片)
- `lib/features/team/widgets/member_list_item.dart` (成员列表项)
- `lib/features/team/widgets/invite_member_dialog.dart` (邀请成员对话框)
- `lib/features/team/widgets/create_team_dialog.dart` (创建团队对话框)
- `lib/features/team/widgets/edit_team_dialog.dart` (编辑团队对话框)
- `lib/features/team/widgets/delete_team_dialog.dart` (删除团队确认对话框)
- `lib/features/team/widgets/leave_team_dialog.dart` (离开团队确认对话框)
- `lib/features/team/widgets/remove_member_dialog.dart` (移除成员确认对话框)
- `lib/features/team/widgets/danger_zone_card.dart` (危险区域卡片)
- `lib/features/team/widgets/team_selector.dart` (AppBar 团队选择器)
- `lib/features/team/widgets/ownership_selector.dart` (归属选择器)
- `lib/features/team/providers/team_list_provider.dart` (团队列表状态管理)
- `lib/features/team/providers/team_detail_provider.dart` (团队详情状态管理)
- `lib/features/team/providers/team_context_provider.dart` (当前团队上下文状态管理)

---

## 文档目录

1. [测试策略与范围](#一测试策略与范围)
2. [测试数据设计](#二测试数据设计)
3. [Mock 与辅助函数](#三mock-与辅助函数)
4. [团队列表页测试](#四团队列表页测试)
5. [团队详情页测试](#五团队详情页测试)
6. [成员管理测试](#六成员管理测试)
7. [AppBar 团队选择器测试](#七appbar-团队选择器测试)
8. [资源创建归属选择测试](#八资源创建归属选择测试)
9. [权限矩阵 UI 测试](#九权限矩阵-ui-测试)
10. [错误状态测试](#十错误状态测试)
11. [响应式布局测试](#十一响应式布局测试)
12. [用例汇总表](#十二用例汇总表)

---

## 一、测试策略与范围

### 1.1 测试类型

本次测试为 **Flutter Widget 测试**，使用 `flutter_test` 框架，结合 `mocktail` 进行 API 客户端模拟，结合 `flutter_riverpod` 的 `ProviderScope` 进行状态管理注入。

### 1.2 测试范围

| 范围项 | 包含 | 不包含 |
|--------|------|--------|
| 团队列表页渲染 | ✅ 卡片网格、空状态、加载状态 | ❌ 下拉刷新手势（需集成测试） |
| 团队详情页渲染 | ✅ 信息卡、成员列表、危险区域 | ❌ 页面转场动画 |
| 成员管理交互 | ✅ 邀请、移除、角色显示 | ❌ 角色变更（设为Admin/降为Member）— P1功能 |
| 创建/编辑/删除团队 | ✅ 对话框表单、验证、确认 | ❌ 后端实际调用（mock层验证） |
| AppBar 团队选择器 | ✅ 下拉渲染、选项切换 | ❌ 全局状态同步后的页面重定向 |
| 资源归属选择 | ✅ Radio选项、权限提示、默认选中 | ❌ 实际资源创建提交 |
| 权限矩阵 UI | ✅ 根据角色显示/隐藏按钮 | ❌ 后端权限拦截验证（已在 R2-S2-001 覆盖） |
| 错误状态 | ✅ 网络错误、403、404 UI表现 | ❌ 错误恢复重试逻辑的后端验证 |
| 响应式布局 | ✅ 桌面/平板/移动端断点 | ❌ 实际设备测试（使用 `TestApp.sized` 模拟） |

### 1.3 测试环境

- **测试框架**: `flutter_test` + `mocktail`
- **状态管理**: `flutter_riverpod` (使用 `ProviderScope` override)
- **路由**: `go_router` (使用 `MockGoRouter` 或 `navigatorKey` 验证导航)
- **屏幕尺寸**:  
  - 桌面端: 1440×1080 (>=1280px)  
  - 平板端: 1024×768 (>=768px)  
  - 移动端: 375×667 (<768px)
- **Flutter 版本**: 3.19+

---

## 二、测试数据设计

### 2.1 模拟团队数据

```dart
/// 团队角色枚举
enum TeamRole { owner, admin, member }

/// 团队列表数据
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

/// 单个团队详情数据
final mockTeamDetail = TeamDetail(
  id: 'team-001',
  name: '研发团队',
  description: '核心产品研发团队',
  createdAt: DateTime.parse('2026-01-15T00:00:00Z'),
  creator: User(id: 'user-001', name: '张三', email: 'zhangsan@example.com'),
  memberCount: 3,
  currentUserRole: TeamRole.owner,
);

/// 团队成员数据
final mockMembers = [
  TeamMember(
    id: 'user-001',
    name: '张三',
    email: 'zhangsan@example.com',
    role: TeamRole.owner,
    avatarUrl: null,
  ),
  TeamMember(
    id: 'user-002',
    name: '李四',
    email: 'lisi@example.com',
    role: TeamRole.admin,
    avatarUrl: null,
  ),
  TeamMember(
    id: 'user-003',
    name: '王五',
    email: 'wangwu@example.com',
    role: TeamRole.member,
    avatarUrl: null,
  ),
];

/// 空团队列表
final mockEmptyTeams = <Team>[];

/// 当前用户（Owner角色）
final mockCurrentUserOwner = User(
  id: 'user-001',
  name: '张三',
  email: 'zhangsan@example.com',
);

/// 当前用户（Admin角色）
final mockCurrentUserAdmin = User(
  id: 'user-002',
  name: '李四',
  email: 'lisi@example.com',
);

/// 当前用户（Member角色）
final mockCurrentUserMember = User(
  id: 'user-003',
  name: '王五',
  email: 'wangwu@example.com',
);
```

### 2.2 模拟状态数据

```dart
/// 团队列表 Provider 状态
final mockTeamListLoaded = AsyncData<List<Team>>(mockTeams);
final mockTeamListEmpty = AsyncData<List<Team>>([]);
final mockTeamListLoading = const AsyncLoading<List<Team>>();
final mockTeamListError = AsyncError<List<Team>>(
  '网络连接失败',
  StackTrace.empty,
);

/// 团队详情 Provider 状态
final mockTeamDetailLoaded = AsyncData<TeamDetail>(mockTeamDetail);
final mockTeamDetailLoading = const AsyncLoading<TeamDetail>();
final mockTeamDetailError403 = AsyncError<TeamDetail>(
  '没有权限访问该团队',
  StackTrace.empty,
);
final mockTeamDetailError404 = AsyncError<TeamDetail>(
  '团队不存在',
  StackTrace.empty,
);

/// 当前团队上下文
final mockPersonalContext = TeamContext.personal();
final mockTeamContext = TeamContext.team(id: 'team-001', name: '研发团队');
```

---

## 三、Mock 与辅助函数

### 3.1 通用 Mock Provider Override

```dart
/// 构建带 Mock Provider 的测试应用
Widget buildTeamListPage({
  required AsyncValue<List<Team>> teamListState,
  TeamContext? currentContext,
  User? currentUser,
  Size? size,
}) {
  return TestApp.withProvider(
    size: size,
    overrides: [
      teamListProvider.overrideWith((ref) => teamListState),
      teamContextProvider.overrideWith((ref) => currentContext ?? mockPersonalContext),
      currentUserProvider.overrideWith((ref) => currentUser ?? mockCurrentUserOwner),
    ],
    child: const TeamListPage(),
  );
}

/// 构建带 Mock Provider 的团队详情页
Widget buildTeamDetailPage({
  required AsyncValue<TeamDetail> detailState,
  required AsyncValue<List<TeamMember>> membersState,
  required TeamRole currentUserRole,
  Size? size,
}) {
  return TestApp.withProvider(
    size: size,
    overrides: [
      teamDetailProvider('team-001').overrideWith((ref) => detailState),
      teamMembersProvider('team-001').overrideWith((ref) => membersState),
      currentUserRoleProvider('team-001').overrideWith((ref) => currentUserRole),
    ],
    child: const TeamDetailPage(teamId: 'team-001'),
  );
}

/// 构建带 Mock Provider 的归属选择器
Widget buildOwnershipSelector({
  required List<Team> userTeams,
  required TeamContext initialContext,
}) {
  return TestApp.withProvider(
    overrides: [
      teamListProvider.overrideWith((ref) => AsyncData(userTeams)),
      teamContextProvider.overrideWith((ref) => initialContext),
    ],
    child: const OwnershipSelector(),
  );
}
```

### 3.2 通用断言辅助函数

```dart
/// 验证角色徽章存在且样式正确
void expectRoleBadge(WidgetTester tester, TeamRole role, {bool inList = false}) {
  final badgeFinder = find.widgetWithText(Chip, role.label);
  expect(badgeFinder, findsOneWidget);
  
  final chip = tester.widget<Chip>(badgeFinder);
  // 验证背景色符合设计规范
  switch (role) {
    case TeamRole.owner:
      expect(chip.backgroundColor, equals(TeamColors.ownerBadgeBg));
      break;
    case TeamRole.admin:
      expect(chip.backgroundColor, equals(TeamColors.adminBadgeBg));
      break;
    case TeamRole.member:
      expect(chip.backgroundColor, equals(TeamColors.memberBadgeBg));
      break;
  }
}

/// 验证危险区域存在
void expectDangerZone(WidgetTester tester, {bool exists = true}) {
  final dangerFinder = find.byType(DangerZoneCard);
  if (exists) {
    expect(dangerFinder, findsOneWidget);
    // 验证危险区域标题
    expect(find.text('危险操作'), findsOneWidget);
  } else {
    expect(dangerFinder, findsNothing);
  }
}

/// 验证编辑按钮可见性
void expectEditButton(WidgetTester tester, {bool visible = true}) {
  final editFinder = find.byIcon(Icons.edit);
  if (visible) {
    expect(editFinder, findsOneWidget);
  } else {
    expect(editFinder, findsNothing);
  }
}
```

---

## 四、团队列表页测试

### TC-TEAM-UI-001: 团队列表 — 有数据时正确渲染卡片网格

- **Description**: 验证当用户有多个团队时，团队列表页以网格形式正确渲染所有团队卡片，每张卡片显示名称、描述、成员数和角色徽章。
- **Widget Under Test**: `TeamListPage` + `TeamCard`
- **Priority**: P0
- **Preconditions**:
  1. 用户已登录且属于 3 个团队（Owner/Admin/Member）。
  2. `teamListProvider` 返回 `AsyncData(mockTeams)`。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamListPage(teamListState: mockTeamListLoaded));`
  2. `await tester.pumpAndSettle();`
  3. 查找页面标题 "团队管理"。
  4. 查找 "创建团队" 按钮。
  5. 遍历 mockTeams，验证每个团队名称文本存在。
  6. 验证每个卡片的角色徽章存在且颜色正确。
  7. 验证成员数量文本存在。
- **Expected Results**:
  1. ✅ 页面标题 "团队管理" 显示 1 处。
  2. ✅ "创建团队" FilledButton 存在。
  3. ✅ 3 张团队卡片渲染（`find.byType(TeamCard)` 找到 3 个）。
  4. ✅ "研发团队" 卡片包含 Owner 徽章（背景色 `#BBDEFB` 浅色 / `#1565C0` 深色）。
  5. ✅ "QA 测试团队" 卡片包含 Admin 徽章（背景色 `#E0F7FA` 浅色 / `#006064` 深色）。
  6. ✅ "产品团队" 卡片包含 Member 徽章（背景色 `#EEEEEE` 浅色 / `#2D2D2D` 深色）。
  7. ✅ 每张卡片底部显示创建日期和右箭头图标。
  8. ✅ 桌面端（1440px）网格为 3 列布局。

```dart
testWidgets('TC-TEAM-UI-001: 团队列表有数据时正确渲染', (tester) async {
  await tester.pumpWidget(
    buildTeamListPage(teamListState: mockTeamListLoaded),
  );
  await tester.pumpAndSettle();

  // 验证页面标题和创建按钮
  expect(find.text('团队管理'), findsOneWidget);
  expect(find.widgetWithText(FilledButton, '创建团队'), findsOneWidget);

  // 验证 3 张卡片
  expect(find.byType(TeamCard), findsNWidgets(3));

  // 验证每个团队名称
  for (final team in mockTeams) {
    expect(find.text(team.name), findsOneWidget);
  }

  // 验证角色徽章存在
  expect(find.text('Owner'), findsOneWidget);
  expect(find.text('Admin'), findsOneWidget);
  expect(find.text('Member'), findsOneWidget);

  // 验证成员数量
  expect(find.text('12 位成员'), findsOneWidget);
  expect(find.text('5 位成员'), findsOneWidget);
  expect(find.text('8 位成员'), findsOneWidget);
});
```

---

### TC-TEAM-UI-002: 团队列表 — 空状态时显示空状态组件

- **Description**: 验证当用户没有加入任何团队时，页面显示空状态组件（大图标 + 标题 + 描述 + 创建按钮），不显示网格。
- **Widget Under Test**: `TeamListPage` + `EmptyTeamListState`
- **Priority**: P0
- **Preconditions**:
  1. 用户已登录但没有任何团队。
  2. `teamListProvider` 返回 `AsyncData([])`。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamListPage(teamListState: mockTeamListEmpty));`
  2. `await tester.pumpAndSettle();`
  3. 查找空状态图标 `groups_outlined`。
  4. 查找 "暂无团队" 文本。
  5. 查找描述文本。
  6. 查找 "创建团队" 按钮。
  7. 验证没有 `TeamCard` 渲染。
- **Expected Results**:
  1. ✅ `find.byType(TeamCard)` 返回 0。
  2. ✅ 空状态图标 `groups_outlined` 存在（80px，On Surface Variant 40% 透明度）。
  3. ✅ "暂无团队" 文本存在（Headline Small, 24pt）。
  4. ✅ "您还没有加入任何团队，创建一个新团队开始协作" 描述文本存在（Body Medium）。
  5. ✅ 空状态区域中央有 "创建团队" FilledButton。

```dart
testWidgets('TC-TEAM-UI-002: 团队列表空状态', (tester) async {
  await tester.pumpWidget(
    buildTeamListPage(teamListState: mockTeamListEmpty),
  );
  await tester.pumpAndSettle();

  // 不显示卡片
  expect(find.byType(TeamCard), findsNothing);

  // 空状态组件
  expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
  expect(find.text('暂无团队'), findsOneWidget);
  expect(
    find.text('您还没有加入任何团队，创建一个新团队开始协作'),
    findsOneWidget,
  );
  expect(find.widgetWithText(FilledButton, '创建团队'), findsOneWidget);
});
```

---

### TC-TEAM-UI-003: 团队卡片 — 点击卡片导航到详情页

- **Description**: 验证点击团队卡片触发导航到 `/teams/:id` 路由。
- **Widget Under Test**: `TeamCard`
- **Priority**: P0
- **Preconditions**:
  1. 团队列表已加载。
  2. 使用 `MockGoRouter` 注入到 widget 树中。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamListPage(teamListState: mockTeamListLoaded));`
  2. `await tester.pumpAndSettle();`
  3. 点击 "研发团队" 卡片。
  4. `await tester.pumpAndSettle();`
- **Expected Results**:
  1. ✅ `mockGoRouter.push('/teams/team-001')` 被调用 1 次。
  2. ✅ 卡片悬停时边框变为 Primary，Y 轴上移 2px（需 `tester.hover` 或拖动模拟）。

```dart
testWidgets('TC-TEAM-UI-003: 点击卡片导航到详情页', (tester) async {
  final mockRouter = MockGoRouter();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamListProvider.overrideWith((ref) => mockTeamListLoaded),
        goRouterProvider.overrideWithValue(mockRouter),
      ],
      child: const MaterialApp(home: TeamListPage()),
    ),
  );
  await tester.pumpAndSettle();

  // 点击研发团队卡片
  await tester.tap(find.text('研发团队'));
  await tester.pumpAndSettle();

  // 验证导航被触发
  verify(() => mockRouter.push('/teams/team-001')).called(1);
});
```

---

### TC-TEAM-UI-004: 创建团队 — 表单验证（名称必填、最大长度）

- **Description**: 验证创建团队对话框的表单验证逻辑：名称不能为空、不能超过 255 字符、描述可选。
- **Widget Under Test**: `CreateTeamDialog`
- **Priority**: P0
- **Preconditions**:
  1. 用户已登录。
  2. 对话框已通过点击 "创建团队" 按钮打开。
- **Steps**:
  1. `await tester.pumpWidget(TestApp.light(child: const CreateTeamDialog()));`
  2. 直接点击 "创建" 按钮（名称留空）。
  3. 验证错误提示。
  4. 在名称输入框输入超过 255 字符的字符串。
  5. 验证错误提示。
  6. 输入有效名称 "新团队"。
  7. 验证错误提示消失，"创建" 按钮变为可用。
  8. 输入描述（256 字符）。
  9. 验证描述无长度限制错误（或根据设计验证）。
- **Expected Results**:
  1. ✅ 名称留空时点击创建，显示 "团队名称不能为空"。
  2. ✅ 名称超过 255 字符时，显示 "团队名称不能超过 255 个字符"。
  3. ✅ 有效名称输入后，错误提示消失。
  4. ✅ 描述字段为可选，留空不报错。
  5. ✅ 表单验证通过时，"创建" 按钮为 enabled 状态。

```dart
testWidgets('TC-TEAM-UI-004: 创建团队表单验证', (tester) async {
  await tester.pumpWidget(
    TestApp.light(child: const CreateTeamDialog()),
  );
  await tester.pumpAndSettle();

  // 步骤 2: 直接点击创建，名称留空
  await tester.tap(find.widgetWithText(FilledButton, '创建'));
  await tester.pumpAndSettle();
  expect(find.text('团队名称不能为空'), findsOneWidget);

  // 步骤 4: 输入超长名称
  final longName = 'A' * 256;
  await tester.enterText(
    WidgetFinderHelpers.findTextFieldByLabel('团队名称'),
    longName,
  );
  await tester.pumpAndSettle();
  expect(find.text('团队名称不能超过 255 个字符'), findsOneWidget);

  // 步骤 6: 输入有效名称
  await tester.enterText(
    WidgetFinderHelpers.findTextFieldByLabel('团队名称'),
    '新团队',
  );
  await tester.pumpAndSettle();
  expect(find.text('团队名称不能为空'), findsNothing);
  expect(find.text('团队名称不能超过 255 个字符'), findsNothing);

  // 验证创建按钮可用（无禁用样式）
  final createButton = tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, '创建'),
  );
  expect(createButton.onPressed, isNotNull);
});
```

---

## 五、团队详情页测试

### TC-TEAM-UI-005: 团队详情页 — 正确渲染团队信息和成员列表

- **Description**: 验证团队详情页加载成功后，正确显示团队信息卡（名称、描述、创建者、创建时间、成员数）和成员列表。
- **Widget Under Test**: `TeamDetailPage`
- **Priority**: P0
- **Preconditions**:
  1. 用户已登录，是 team-001 的 Owner。
  2. `teamDetailProvider` 返回 `AsyncData(mockTeamDetail)`。
  3. `teamMembersProvider` 返回 `AsyncData(mockMembers)`。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamDetailPage(...));`
  2. `await tester.pumpAndSettle();`
  3. 验证面包屑导航包含团队名称。
  4. 验证团队名称 "研发团队" 以 Title Large 样式显示。
  5. 验证描述 "核心产品研发团队" 显示。
  6. 验证统计行："成员: 3"、"创建者: 张三"、"创建于: 2026-01-15"。
  7. 验证成员列表有 3 项。
  8. 验证每个成员的头像、名称、邮箱、角色徽章。
- **Expected Results**:
  1. ✅ 面包屑 "首页 > 团队 > 研发团队" 存在。
  2. ✅ 团队名称 "研发团队" 以 Title Large (22pt, 500) 渲染。
  3. ✅ 描述文本存在。
  4. ✅ 成员统计 "成员: 3" 存在。
  5. ✅ 创建者 "创建者: 张三" 存在。
  6. ✅ 成员列表渲染 3 个 `MemberListItem`。
  7. ✅ 张三的列表项包含 Owner 徽章（20px 高度）。
  8. ✅ 王五的列表项包含 Member 徽章。

```dart
testWidgets('TC-TEAM-UI-005: 团队详情页正确渲染', (tester) async {
  await tester.pumpWidget(
    buildTeamDetailPage(
      detailState: mockTeamDetailLoaded,
      membersState: AsyncData(mockMembers),
      currentUserRole: TeamRole.owner,
    ),
  );
  await tester.pumpAndSettle();

  // 验证团队名称和描述
  expect(find.text('研发团队'), findsWidgets); // 可能在面包屑和标题中多处
  expect(find.text('核心产品研发团队'), findsOneWidget);

  // 验证统计信息
  expect(find.text('成员: 3'), findsOneWidget);
  expect(find.text('创建者: 张三'), findsOneWidget);

  // 验证成员列表
  expect(find.byType(MemberListItem), findsNWidgets(3));
  expect(find.text('张三'), findsOneWidget);
  expect(find.text('李四'), findsOneWidget);
  expect(find.text('王五'), findsOneWidget);

  // 验证角色徽章
  expect(find.text('Owner'), findsOneWidget);
  expect(find.text('Admin'), findsOneWidget);
  expect(find.text('Member'), findsOneWidget);
});
```

---

### TC-TEAM-UI-006: 编辑团队 — 对话框打开、修改名称和描述、保存

- **Description**: 验证 Owner/Admin 可以打开编辑对话框，修改团队名称和描述，点击保存后对话框关闭。
- **Widget Under Test**: `TeamDetailPage` + `EditTeamDialog`
- **Priority**: P0
- **Preconditions**:
  1. 用户是团队 Owner。
  2. 团队详情已加载。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamDetailPage(currentUserRole: TeamRole.owner));`
  2. `await tester.pumpAndSettle();`
  3. 点击编辑图标按钮（`Icons.edit`）。
  4. 验证编辑对话框打开，标题 "编辑团队信息"。
  5. 验证名称输入框预填充 "研发团队"。
  6. 验证描述输入框预填充 "核心产品研发团队"。
  7. 清除名称，输入 "研发团队（已更名）"。
  8. 清除描述，输入 "新的描述"。
  9. 点击 "保存"。
  10. 验证对话框关闭（`find.byType(EditTeamDialog)` 返回 0）。
- **Expected Results**:
  1. ✅ 编辑按钮（`Icons.edit`）可见。
  2. ✅ 点击后对话框标题 "编辑团队信息" 出现。
  3. ✅ 名称输入框预填充原名称。
  4. ✅ 描述输入框预填充原描述。
  5. ✅ 修改后点击保存，对话框关闭。
  6. ✅ 保存按钮触发 `teamService.updateTeam` 调用（mock验证）。

```dart
testWidgets('TC-TEAM-UI-006: 编辑团队信息', (tester) async {
  final mockService = MockTeamService();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamDetailProvider('team-001').overrideWith((ref) => mockTeamDetailLoaded),
        teamMembersProvider('team-001').overrideWith((ref) => AsyncData(mockMembers)),
        currentUserRoleProvider('team-001').overrideWith((ref) => TeamRole.owner),
        teamServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: TeamDetailPage(teamId: 'team-001')),
    ),
  );
  await tester.pumpAndSettle();

  // 点击编辑按钮
  await tester.tap(find.byIcon(Icons.edit));
  await tester.pumpAndSettle();

  // 验证对话框
  expect(find.text('编辑团队信息'), findsOneWidget);
  
  // 验证预填充值
  final nameField = WidgetFinderHelpers.findTextFieldByLabel('团队名称');
  expect(tester.widget<TextField>(nameField).controller?.text, '研发团队');

  // 修改名称
  await tester.enterText(nameField, '研发团队（已更名）');
  await tester.pumpAndSettle();

  // 点击保存
  await tester.tap(find.widgetWithText(FilledButton, '保存'));
  await tester.pumpAndSettle();

  // 验证对话框关闭
  expect(find.text('编辑团队信息'), findsNothing);
  
  // 验证服务调用
  verify(() => mockService.updateTeam(
    'team-001',
    name: '研发团队（已更名）',
  )).called(1);
});
```

---

### TC-TEAM-UI-007: 删除团队 — 危险区域显示、确认对话框、确认删除

- **Description**: 验证 Owner 可以看到删除团队的危险区域，点击后弹出确认对话框，确认后调用删除 API。
- **Widget Under Test**: `TeamDetailPage` + `DangerZoneCard` + `DeleteTeamDialog`
- **Priority**: P0
- **Preconditions**:
  1. 用户是团队 Owner。
  2. 团队详情已加载。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamDetailPage(currentUserRole: TeamRole.owner));`
  2. `await tester.pumpAndSettle();`
  3. 验证危险区域存在，包含 "危险操作" 标题（Error 颜色）。
  4. 验证 "删除团队" OutlinedButton 存在（Error 边框和文字）。
  5. 点击 "删除团队" 按钮。
  6. 验证确认对话框出现：
     - 图标 `warning_amber`（48px，Error 颜色）。
     - 标题 "确认删除团队"。
     - 内容包含团队名称。
     - "取消" TextButton + "删除" Error FilledButton。
  7. 点击 "删除"。
  8. 验证 `teamService.deleteTeam('team-001')` 被调用。
  9. 验证导航回 `/teams`。
- **Expected Results**:
  1. ✅ 危险区域背景为 Error Container（`#FFEBEE` 浅色 / `#B71C1C` 深色）。
  2. ✅ "危险操作" 标题颜色为 Error（`#C62828` 浅色 / `#EF5350` 深色）。
  3. ✅ 删除确认对话框正确渲染所有元素。
  4. ✅ 确认后调用删除 API 并导航回列表页。

```dart
testWidgets('TC-TEAM-UI-007: 删除团队确认流程', (tester) async {
  final mockService = MockTeamService();
  final mockRouter = MockGoRouter();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamDetailProvider('team-001').overrideWith((ref) => mockTeamDetailLoaded),
        teamMembersProvider('team-001').overrideWith((ref) => AsyncData(mockMembers)),
        currentUserRoleProvider('team-001').overrideWith((ref) => TeamRole.owner),
        teamServiceProvider.overrideWithValue(mockService),
        goRouterProvider.overrideWithValue(mockRouter),
      ],
      child: const MaterialApp(home: TeamDetailPage(teamId: 'team-001')),
    ),
  );
  await tester.pumpAndSettle();

  // 验证危险区域
  expect(find.byType(DangerZoneCard), findsOneWidget);
  expect(find.text('危险操作'), findsOneWidget);
  expect(find.widgetWithText(OutlinedButton, '删除团队'), findsOneWidget);

  // 点击删除按钮
  await tester.tap(find.widgetWithText(OutlinedButton, '删除团队'));
  await tester.pumpAndSettle();

  // 验证确认对话框
  expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  expect(find.text('确认删除团队'), findsOneWidget);
  expect(find.text('确定要删除团队 研发团队 吗？'), findsOneWidget);

  // 点击确认删除
  await tester.tap(find.widgetWithText(FilledButton, '删除'));
  await tester.pumpAndSettle();

  // 验证 API 调用和导航
  verify(() => mockService.deleteTeam('team-001')).called(1);
  verify(() => mockRouter.go('/teams')).called(1);
});
```

---

### TC-TEAM-UI-008: 离开团队 — 确认对话框、确认离开

- **Description**: 验证 Admin/Member 可以看到离开团队按钮，点击后弹出确认对话框，确认后调用离开 API。
- **Widget Under Test**: `TeamDetailPage` + `LeaveTeamDialog`
- **Priority**: P0
- **Preconditions**:
  1. 用户是团队 Admin（非 Owner）。
  2. 团队详情已加载。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamDetailPage(currentUserRole: TeamRole.admin));`
  2. `await tester.pumpAndSettle();`
  3. 验证危险区域存在，但不包含 "删除团队"。
  4. 验证 "离开团队" OutlinedButton 存在。
  5. 点击 "离开团队"。
  6. 验证确认对话框：
     - 图标 `logout`（48px，Warning 颜色）。
     - 标题 "确认离开团队"。
     - "离开" Warning FilledButton。
  7. 点击 "离开"。
  8. 验证 `teamService.leaveTeam('team-001')` 被调用。
- **Expected Results**:
  1. ✅ Admin 用户看到 "离开团队" 按钮，不看到 "删除团队"。
  2. ✅ 确认对话框使用 Warning 颜色（区别于删除的 Error 颜色）。
  3. ✅ 确认后调用离开 API。

```dart
testWidgets('TC-TEAM-UI-008: Admin 离开团队确认流程', (tester) async {
  final mockService = MockTeamService();
  
  await tester.pumpWidget(
    buildTeamDetailPage(
      detailState: mockTeamDetailLoaded,
      membersState: AsyncData(mockMembers),
      currentUserRole: TeamRole.admin,
    ),
  );
  await tester.pumpAndSettle();

  // 验证危险区域有离开按钮，无删除按钮
  expect(find.byType(DangerZoneCard), findsOneWidget);
  expect(find.widgetWithText(OutlinedButton, '离开团队'), findsOneWidget);
  expect(find.widgetWithText(OutlinedButton, '删除团队'), findsNothing);

  // 点击离开
  await tester.tap(find.widgetWithText(OutlinedButton, '离开团队'));
  await tester.pumpAndSettle();

  // 验证对话框
  expect(find.byIcon(Icons.logout), findsOneWidget);
  expect(find.text('确认离开团队'), findsOneWidget);

  // 点击确认
  await tester.tap(find.widgetWithText(FilledButton, '离开'));
  await tester.pumpAndSettle();

  // 验证 API 调用
  verify(() => mockService.leaveTeam('team-001')).called(1);
});
```

---

## 六、成员管理测试

### TC-TEAM-UI-009: 成员列表 — 正确渲染所有成员及其角色

- **Description**: 验证成员列表正确渲染每个成员的头像、名称、邮箱和角色徽章。
- **Widget Under Test**: `MembersList` + `MemberListItem`
- **Priority**: P0
- **Preconditions**:
  1. 团队详情已加载。
  2. 成员列表有 3 人（Owner/Admin/Member）。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamDetailPage(...));`
  2. `await tester.pumpAndSettle();`
  3. 查找成员列表区域标题 "团队成员"。
  4. 查找成员数量徽章 "3 人"。
  5. 遍历 mockMembers，验证每个成员名称、邮箱存在。
  6. 验证每个成员的角色徽章正确（Owner 为 Primary Container 背景等）。
  7. 验证头像为 CircleAvatar（40px），无头像时显示姓名首字母。
- **Expected Results**:
  1. ✅ "团队成员" 标题存在（Title Medium）。
  2. ✅ "3 人" 数量徽章存在。
  3. ✅ 每个 `MemberListItem` 高度为 72px。
  4. ✅ 每个成员名称以 Body Large (16pt) 显示。
  5. ✅ 每个成员邮箱以 Body Medium (14pt, On Surface Variant) 显示。
  6. ✅ 角色徽章高度 20px（列表内），圆角 6px。

```dart
testWidgets('TC-TEAM-UI-009: 成员列表正确渲染', (tester) async {
  await tester.pumpWidget(
    buildTeamDetailPage(
      detailState: mockTeamDetailLoaded,
      membersState: AsyncData(mockMembers),
      currentUserRole: TeamRole.owner,
    ),
  );
  await tester.pumpAndSettle();

  // 验证区域标题
  expect(find.text('团队成员'), findsOneWidget);
  expect(find.text('3 人'), findsOneWidget);

  // 验证每个成员
  for (final member in mockMembers) {
    expect(find.text(member.name), findsOneWidget);
    expect(find.text(member.email), findsOneWidget);
  }

  // 验证成员列表项数量
  expect(find.byType(MemberListItem), findsNWidgets(3));

  // 验证头像
  expect(find.byType(CircleAvatar), findsNWidgets(3));
});
```

---

### TC-TEAM-UI-010: 邀请成员 — 对话框打开、邮箱验证、角色选择、发送

- **Description**: 验证 Owner/Admin 可以打开邀请对话框，输入邮箱时实时验证格式，选择角色，点击发送。
- **Widget Under Test**: `InviteMemberDialog`
- **Priority**: P0
- **Preconditions**:
  1. 用户是团队 Owner。
- **Steps**:
  1. `await tester.pumpWidget(TestApp.light(child: const InviteMemberDialog(teamId: 'team-001')));`
  2. 验证对话框标题 "邀请成员"。
  3. 验证邮箱输入框存在，前缀图标 `email`。
  4. 验证角色下拉框默认选中 "Member"。
  5. 输入无效邮箱 "not-an-email"。
  6. 验证显示 "请输入有效的邮箱地址"。
  7. 清除后输入有效邮箱 "newuser@example.com"。
  8. 验证右侧显示 `check_circle`（Success 颜色）。
  9. 切换角色为 "Admin"。
  10. 点击 "发送邀请"。
  11. 验证 `teamService.inviteMember(...)` 被正确调用。
- **Expected Results**:
  1. ✅ 对话框标题 "邀请成员" 存在（Headline Small）。
  2. ✅ 邮箱输入框有 `email` 前缀图标。
  3. ✅ 无效邮箱显示错误提示，边框变 Error 色。
  4. ✅ 有效邮箱显示 `check_circle` 图标。
  5. ✅ 角色下拉选项包含 Member 和 Admin。
  6. ✅ 发送按钮触发邀请 API。

```dart
testWidgets('TC-TEAM-UI-010: 邀请成员对话框', (tester) async {
  final mockService = MockTeamService();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamServiceProvider.overrideWithValue(mockService),
      ],
      child: TestApp.light(
        child: const InviteMemberDialog(teamId: 'team-001'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // 验证对话框结构
  expect(find.text('邀请成员'), findsOneWidget);
  expect(find.byIcon(Icons.email), findsOneWidget);

  // 输入无效邮箱
  await tester.enterText(
    WidgetFinderHelpers.findTextFieldByLabel('邮箱地址'),
    'not-an-email',
  );
  await tester.pumpAndSettle();
  expect(find.text('请输入有效的邮箱地址'), findsOneWidget);

  // 输入有效邮箱
  await tester.enterText(
    WidgetFinderHelpers.findTextFieldByLabel('邮箱地址'),
    'newuser@example.com',
  );
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.check_circle), findsOneWidget);

  // 选择 Admin 角色
  await tester.tap(find.byType(DropdownButton<TeamRole>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Admin').last);
  await tester.pumpAndSettle();

  // 点击发送
  await tester.tap(find.widgetWithText(FilledButton, '发送邀请'));
  await tester.pumpAndSettle();

  // 验证 API 调用
  verify(() => mockService.inviteMember(
    teamId: 'team-001',
    email: 'newuser@example.com',
    role: TeamRole.admin,
  )).called(1);
});
```

---

### TC-TEAM-UI-011: 移除成员 — 操作菜单、确认对话框、确认移除

- **Description**: 验证 Owner/Admin 可以点击成员列表项的更多按钮，选择移除成员，弹出确认对话框并确认。
- **Widget Under Test**: `MemberListItem` + `RemoveMemberDialog`
- **Priority**: P0
- **Preconditions**:
  1. 用户是团队 Owner。
  2. 成员列表已加载。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamDetailPage(currentUserRole: TeamRole.owner));`
  2. `await tester.pumpAndSettle();`
  3. 验证王五（Member）的列表项有 `more_vert` 按钮。
  4. 验证张三（Owner）的列表项没有 `more_vert` 按钮。
  5. 点击王五列表项的 `more_vert`。
  6. 验证 PopupMenu 出现，包含 "设为 Admin"、"移除成员"（Error 颜色）。
  7. 点击 "移除成员"。
  8. 验证确认对话框：
     - 图标 `person_remove`（48px，Error）。
     - 标题 "确认移除成员"。
     - 内容包含 "王五"。
  9. 点击 "移除"。
  10. 验证 `teamService.removeMember('team-001', 'user-003')` 被调用。
- **Expected Results**:
  1. ✅ Owner 的列表项没有操作菜单。
  2. ✅ 非 Owner 成员有 `more_vert` 按钮。
  3. ✅ PopupMenu 中 "移除成员" 文字和图标为 Error 颜色。
  4. ✅ 确认对话框正确渲染。
  5. ✅ 确认后调用移除 API。

```dart
testWidgets('TC-TEAM-UI-011: 移除成员确认流程', (tester) async {
  final mockService = MockTeamService();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamDetailProvider('team-001').overrideWith((ref) => mockTeamDetailLoaded),
        teamMembersProvider('team-001').overrideWith((ref) => AsyncData(mockMembers)),
        currentUserRoleProvider('team-001').overrideWith((ref) => TeamRole.owner),
        teamServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: TeamDetailPage(teamId: 'team-001')),
    ),
  );
  await tester.pumpAndSettle();

  // 获取所有 more_vert 按钮（Owner 不应该有）
  final menuButtons = find.byIcon(Icons.more_vert);
  expect(menuButtons, findsNWidgets(2)); // Admin 和 Member 各一个

  // 点击王五的 more_vert（最后一个）
  await tester.tap(menuButtons.last);
  await tester.pumpAndSettle();

  // 验证菜单项
  expect(find.text('设为 Admin'), findsOneWidget);
  expect(find.text('移除成员'), findsOneWidget);

  // 点击移除
  await tester.tap(find.text('移除成员'));
  await tester.pumpAndSettle();

  // 验证确认对话框
  expect(find.byIcon(Icons.person_remove), findsOneWidget);
  expect(find.text('确认移除成员'), findsOneWidget);
  expect(find.textContaining('王五'), findsOneWidget);

  // 确认移除
  await tester.tap(find.widgetWithText(FilledButton, '移除'));
  await tester.pumpAndSettle();

  // 验证 API 调用
  verify(() => mockService.removeMember('team-001', 'user-003')).called(1);
});
```

---

## 七、AppBar 团队选择器测试

### TC-TEAM-UI-012: AppBar 团队选择器 — 下拉菜单正确渲染个人空间和团队列表

- **Description**: 验证点击 AppBar 团队选择器按钮后，下拉菜单正确渲染个人空间选项和团队列表选项。
- **Widget Under Test**: `TeamSelector` + `TeamSelectorDropdown`
- **Priority**: P0
- **Preconditions**:
  1. 用户已登录，属于 3 个团队，当前在个人空间上下文。
  2. `teamListProvider` 返回 `AsyncData(mockTeams)`。
  3. `teamContextProvider` 返回 `TeamContext.personal()`。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamSelector());`
  2. `await tester.pumpAndSettle();`
  3. 验证选择器按钮显示 "个人空间" + `account_circle` 图标 + `arrow_drop_down`。
  4. 点击选择器按钮。
  5. 验证下拉面板展开（宽度 280px）。
  6. 验证 "当前工作空间" 头部标签存在。
  7. 验证 "个人空间" 选项存在，有 `check` 标记（因为当前选中）。
  8. 验证 "我的团队" 头部标签存在。
  9. 验证 3 个团队选项存在，每个显示团队名称和角色副标题。
  10. 验证 "创建新团队" 链接存在。
- **Expected Results**:
  1. ✅ 选择器按钮高度 40px，圆角 8px。
  2. ✅ 下拉面板宽度 280px，最大高度 360px。
  3. ✅ 个人空间选项有 `check` 图标（选中状态）。
  4. ✅ 团队选项显示名称和角色（如 "Owner"/"Admin"/"Member"）。
  5. ✅ 选中项背景为 Primary Container，文字为 On Primary Container。

```dart
testWidgets('TC-TEAM-UI-012: 团队选择器下拉菜单渲染', (tester) async {
  await tester.pumpWidget(
    TestApp.withProvider(
      overrides: [
        teamListProvider.overrideWith((ref) => mockTeamListLoaded),
        teamContextProvider.overrideWith((ref) => mockPersonalContext),
      ],
      child: const MaterialApp(home: Scaffold(appBar: AppBarWithTeamSelector())),
    ),
  );
  await tester.pumpAndSettle();

  // 验证选择器按钮
  expect(find.text('个人空间'), findsOneWidget);
  expect(find.byIcon(Icons.account_circle), findsOneWidget);
  expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

  // 点击展开
  await tester.tap(find.text('个人空间'));
  await tester.pumpAndSettle();

  // 验证下拉面板内容
  expect(find.text('当前工作空间'), findsOneWidget);
  expect(find.text('我的团队'), findsOneWidget);
  
  // 个人空间有选中标记
  final personalOption = find.ancestor(
    of: find.text('个人空间'),
    matching: find.byType(ListTile),
  );
  expect(find.descendant(of: personalOption, matching: find.byIcon(Icons.check)), findsOneWidget);

  // 验证团队选项
  expect(find.text('研发团队'), findsOneWidget);
  expect(find.text('QA 测试团队'), findsOneWidget);
  expect(find.text('产品团队'), findsOneWidget);

  // 验证角色副标题
  expect(find.text('Owner'), findsWidgets);
  expect(find.text('Admin'), findsWidgets);
  expect(find.text('Member'), findsWidgets);

  // 创建新团队链接
  expect(find.text('创建新团队'), findsOneWidget);
});
```

---

### TC-TEAM-UI-013: 团队切换 — 选择团队后上下文更新

- **Description**: 验证在下拉菜单中选择团队后，团队上下文状态更新，选择器按钮显示新选中的团队名称。
- **Widget Under Test**: `TeamSelector`
- **Priority**: P0
- **Preconditions**:
  1. 用户已登录，属于多个团队。
  2. 当前上下文为个人空间。
- **Steps**:
  1. `await tester.pumpWidget(buildTeamSelector());`
  2. `await tester.pumpAndSettle();`
  3. 点击选择器按钮展开下拉菜单。
  4. 点击 "研发团队" 选项。
  5. `await tester.pumpAndSettle();`
  6. 验证下拉菜单关闭。
  7. 验证选择器按钮现在显示 "研发团队" + `groups` 图标。
  8. 验证 `teamContextProvider` 状态更新为 `TeamContext.team('team-001')`。
- **Expected Results**:
  1. ✅ 下拉菜单关闭。
  2. ✅ 按钮文字从 "个人空间" 变为 "研发团队"。
  3. ✅ 按钮图标从 `account_circle` 变为 `groups`。
  4. ✅ Provider 状态被更新（通过 mock 回调或状态读取验证）。

```dart
testWidgets('TC-TEAM-UI-013: 切换团队上下文', (tester) async {
  final contextNotifier = StateNotifier<TeamContext>();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamListProvider.overrideWith((ref) => mockTeamListLoaded),
        teamContextProvider.overrideWith((ref) => mockPersonalContext),
      ],
      child: const MaterialApp(home: Scaffold(appBar: AppBarWithTeamSelector())),
    ),
  );
  await tester.pumpAndSettle();

  // 初始为个人空间
  expect(find.text('个人空间'), findsOneWidget);

  // 展开下拉菜单
  await tester.tap(find.text('个人空间'));
  await tester.pumpAndSettle();

  // 选择研发团队
  await tester.tap(find.text('研发团队'));
  await tester.pumpAndSettle();

  // 验证下拉关闭，按钮文字更新
  expect(find.text('当前工作空间'), findsNothing); // 下拉已关闭
  expect(find.text('研发团队'), findsOneWidget);
  expect(find.byIcon(Icons.groups), findsOneWidget);
  expect(find.byIcon(Icons.account_circle), findsNothing);
});
```

---

## 八、资源创建归属选择测试

### TC-TEAM-UI-014: 资源创建对话框 — 归属选择器默认选中当前上下文

- **Description**: 验证在创建工作台/方法/试验对话框中，归属选择器默认选中当前团队上下文，且可以切换到个人空间。
- **Widget Under Test**: `OwnershipSelector` (内嵌于 `CreateWorkbenchDialog` 等)
- **Priority**: P0
- **Preconditions**:
  1. 用户当前在 "研发团队" 团队上下文。
  2. 用户属于 2 个团队。
- **Steps**:
  1. `await tester.pumpWidget(buildOwnershipSelector(userTeams: mockTeams.sublist(0, 2), initialContext: mockTeamContext));`
  2. `await tester.pumpAndSettle();`
  3. 验证归属区域标签 "归属" 存在。
  4. 验证 "研发团队" Radio 被默认选中（实心圆）。
  5. 验证权限提示信息出现："此资源将创建在 研发团队 中..."
  6. 点击 "个人空间" Radio。
  7. 验证 "研发团队" Radio 变为未选中。
  8. 验证权限提示消失。
  9. 验证 "个人空间" Radio 变为选中。
- **Expected Results**:
  1. ✅ 默认选中与当前上下文一致的选项。
  2. ✅ 选择团队时显示权限提示（Info Container 背景 `#E3F2FD` / `#0D47A1`，边框 `#1976D2` / `#90CAF9`）。
  3. ✅ 选择个人空间时权限提示隐藏。
  4. ✅ Radio 切换时标题文字加粗（FontWeight.w500）。
  5. ✅ 选中选项背景有 4% Primary 透明度。

```dart
testWidgets('TC-TEAM-UI-014: 归属选择默认选中当前上下文', (tester) async {
  await tester.pumpWidget(
    TestApp.withProvider(
      overrides: [
        teamListProvider.overrideWith((ref) => AsyncData(mockTeams.sublist(0, 2))),
        teamContextProvider.overrideWith((ref) => mockTeamContext),
      ],
      child: const OwnershipSelector(),
    ),
  );
  await tester.pumpAndSettle();

  // 验证标签
  expect(find.text('归属'), findsOneWidget);

  // 验证研发团队默认选中（通过 Radio 选中状态）
  final radios = tester.widgetList<Radio<TeamContext>>(find.byType(Radio<TeamContext>));
  expect(radios.length, 2);
  expect(radios.last.groupValue, equals(mockTeamContext));

  // 验证权限提示
  expect(find.byIcon(Icons.info), findsOneWidget);
  expect(
    find.textContaining('此资源将创建在 研发团队'),
    findsOneWidget,
  );

  // 切换到个人空间
  await tester.tap(find.text('个人空间'));
  await tester.pumpAndSettle();

  // 验证权限提示消失
  expect(find.byIcon(Icons.info), findsNothing);
});
```

---

## 九、权限矩阵 UI 测试

### TC-TEAM-UI-015: 权限矩阵 — 根据角色正确显示/隐藏操作按钮

- **Description**: 验证团队详情页根据当前用户的角色（Owner/Admin/Member）正确显示或隐藏编辑按钮、邀请按钮、成员操作菜单、删除区域、离开区域。
- **Widget Under Test**: `TeamDetailPage`（条件渲染逻辑）
- **Priority**: P0
- **Preconditions**:
  1. 同一个团队详情，分别测试 Owner/Admin/Member 三种角色的视图。
- **Steps**:
  1. **Owner 视图**: `buildTeamDetailPage(currentUserRole: TeamRole.owner)`
     - 验证编辑按钮存在。
     - 验证邀请按钮存在。
     - 验证成员操作菜单存在（对非 Owner 成员）。
     - 验证删除团队区域存在。
     - 验证离开团队区域不存在。
  2. **Admin 视图**: `buildTeamDetailPage(currentUserRole: TeamRole.admin)`
     - 验证编辑按钮存在。
     - 验证邀请按钮存在。
     - 验证成员操作菜单存在（对 Member）。
     - 验证删除团队区域不存在。
     - 验证离开团队区域存在。
  3. **Member 视图**: `buildTeamDetailPage(currentUserRole: TeamRole.member)`
     - 验证编辑按钮不存在。
     - 验证邀请按钮不存在。
     - 验证成员操作菜单不存在。
     - 验证删除团队区域不存在。
     - 验证离开团队区域存在。
- **Expected Results**:

| UI 元素 | Owner | Admin | Member |
|---------|-------|-------|--------|
| 编辑按钮 | ✅ 可见 | ✅ 可见 | ❌ 不可见 |
| 邀请按钮 | ✅ 可见 | ✅ 可见 | ❌ 不可见 |
| 成员操作菜单 | ✅ 可见 | ✅ 可见 | ❌ 不可见 |
| 删除团队区域 | ✅ 可见 | ❌ 不可见 | ❌ 不可见 |
| 离开团队区域 | ❌ 不可见 | ✅ 可见 | ✅ 可见 |

```dart
group('TC-TEAM-UI-015: 权限矩阵 UI 条件渲染', () {
  Future<void> testRoleVisibility(
    WidgetTester tester,
    TeamRole role, {
    required bool expectEdit,
    required bool expectInvite,
    required bool expectMemberMenu,
    required bool expectDeleteZone,
    required bool expectLeaveZone,
  }) async {
    await tester.pumpWidget(
      buildTeamDetailPage(
        detailState: mockTeamDetailLoaded,
        membersState: AsyncData(mockMembers),
        currentUserRole: role,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), expectEdit ? findsOneWidget : findsNothing);
    expect(find.widgetWithText(FilledButton, '邀请成员'), expectInvite ? findsOneWidget : findsNothing);
    expect(find.byIcon(Icons.more_vert), expectMemberMenu ? findsWidgets : findsNothing);
    expect(find.widgetWithText(OutlinedButton, '删除团队'), expectDeleteZone ? findsOneWidget : findsNothing);
    expect(find.widgetWithText(OutlinedButton, '离开团队'), expectLeaveZone ? findsOneWidget : findsNothing);
  }

  testWidgets('Owner 角色可见性', (tester) async {
    await testRoleVisibility(
      tester, TeamRole.owner,
      expectEdit: true,
      expectInvite: true,
      expectMemberMenu: true,
      expectDeleteZone: true,
      expectLeaveZone: false,
    );
  });

  testWidgets('Admin 角色可见性', (tester) async {
    await testRoleVisibility(
      tester, TeamRole.admin,
      expectEdit: true,
      expectInvite: true,
      expectMemberMenu: true,
      expectDeleteZone: false,
      expectLeaveZone: true,
    );
  });

  testWidgets('Member 角色可见性', (tester) async {
    await testRoleVisibility(
      tester, TeamRole.member,
      expectEdit: false,
      expectInvite: false,
      expectMemberMenu: false,
      expectDeleteZone: false,
      expectLeaveZone: true,
    );
  });
});
```

---

## 十、错误状态测试

### TC-TEAM-UI-016: 错误状态 — 网络错误、403 无权限、404 团队不存在

- **Description**: 验证团队列表和详情页在各种错误状态下的 UI 表现：网络错误显示重试按钮，403 显示无权限提示，404 显示不存在提示。
- **Widget Under Test**: `TeamListPage` + `TeamDetailPage` + 错误状态组件
- **Priority**: P0
- **Preconditions**:
  1. 模拟各种错误状态的 Provider 返回值。
- **Steps**:
  1. **网络错误（列表页）**:
     - `teamListProvider` 返回 `AsyncError('网络连接失败')`。
     - 验证错误图标 `error_outline`（64px）存在。
     - 验证 "加载失败" 标题存在。
     - 验证 "无法获取团队列表，请检查网络连接后重试" 描述存在。
     - 验证 "重试" FilledButton 存在。
     - 点击 "重试"，验证 Provider 的 `refresh` 被触发。
  2. **403 无权限（详情页）**:
     - `teamDetailProvider` 返回 403 错误。
     - 验证 "没有权限访问该团队" 提示存在。
     - 验证返回按钮存在。
  3. **404 团队不存在（详情页）**:
     - `teamDetailProvider` 返回 404 错误。
     - 验证 "团队不存在" 提示存在。
     - 验证 "返回团队列表" 按钮存在。
- **Expected Results**:
  1. ✅ 网络错误时显示完整的错误状态组件（图标 + 标题 + 描述 + 重试按钮）。
  2. ✅ 403 错误时显示权限不足提示，不渲染团队信息。
  3. ✅ 404 错误时显示不存在提示，提供返回列表的导航。
  4. ✅ 点击重试触发重新加载。

```dart
group('TC-TEAM-UI-016: 错误状态 UI', () {
  testWidgets('团队列表网络错误', (tester) async {
    await tester.pumpWidget(
      buildTeamListPage(teamListState: mockTeamListError),
    );
    await tester.pumpAndSettle();

    // 验证错误状态组件
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('无法获取团队列表，请检查网络连接后重试'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '重试'), findsOneWidget);

    // 不显示卡片和空状态
    expect(find.byType(TeamCard), findsNothing);
    expect(find.byIcon(Icons.groups_outlined), findsNothing);
  });

  testWidgets('团队详情 403 无权限', (tester) async {
    await tester.pumpWidget(
      buildTeamDetailPage(
        detailState: mockTeamDetailError403,
        membersState: const AsyncLoading(),
        currentUserRole: TeamRole.member,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有权限访问该团队'), findsOneWidget);
    expect(find.byType(TeamHeaderCard), findsNothing);
    expect(find.byType(MembersList), findsNothing);
  });

  testWidgets('团队详情 404 不存在', (tester) async {
    await tester.pumpWidget(
      buildTeamDetailPage(
        detailState: mockTeamDetailError404,
        membersState: const AsyncLoading(),
        currentUserRole: TeamRole.member,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('团队不存在'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '返回团队列表'), findsOneWidget);
  });
});
```

---

## 十一、响应式布局测试

### TC-TEAM-UI-017: 响应式 — 桌面端 3 列、平板端 2 列、移动端 1 列

- **Description**: 验证团队列表页在不同屏幕宽度下的网格列数响应式变化。
- **Widget Under Test**: `TeamListPage` 网格布局
- **Priority**: P1
- **Preconditions**:
  1. 3 个团队数据已加载。
- **Steps**:
  1. 桌面端 (1440px): `TestApp.sized(size: const Size(1440, 1080), child: TeamListPage())`
     - 验证 GridView 的 `crossAxisCount` 为 3。
  2. 平板端 (1024px): `TestApp.sized(size: const Size(1024, 768))`
     - 验证 `crossAxisCount` 为 2。
  3. 移动端 (375px): `TestApp.sized(size: const Size(375, 667))`
     - 验证 `crossAxisCount` 为 1。
     - 验证 "创建团队" 按钮变为 FAB（浮动操作按钮）。
- **Expected Results**:
  1. ✅ >= 1280px: 3 列网格。
  2. ✅ >= 768px && < 1280px: 2 列网格。
  3. ✅ < 768px: 1 列网格，创建按钮为 FAB。

```dart
group('TC-TEAM-UI-017: 响应式布局', () {
  Future<int> getGridCrossAxisCount(WidgetTester tester) async {
    final gridView = tester.widget<GridView>(find.byType(GridView));
    final sliverGrid = gridView.childrenDelegate as SliverChildListDelegate;
    // 或者通过布局约束推断
    return gridView.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount
        ? (gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount
        : 0;
  }

  testWidgets('桌面端 3 列', (tester) async {
    await tester.pumpWidget(
      TestApp.sized(
        size: const Size(1440, 1080),
        child: ProviderScope(
          overrides: [teamListProvider.overrideWith((ref) => mockTeamListLoaded)],
          child: const TeamListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(await getGridCrossAxisCount(tester), 3);
  });

  testWidgets('平板端 2 列', (tester) async {
    await tester.pumpWidget(
      TestApp.sized(
        size: const Size(1024, 768),
        child: ProviderScope(
          overrides: [teamListProvider.overrideWith((ref) => mockTeamListLoaded)],
          child: const TeamListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(await getGridCrossAxisCount(tester), 2);
  });

  testWidgets('移动端 1 列 + FAB', (tester) async {
    await tester.pumpWidget(
      TestApp.sized(
        size: const Size(375, 667),
        child: ProviderScope(
          overrides: [teamListProvider.overrideWith((ref) => mockTeamListLoaded)],
          child: const TeamListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(await getGridCrossAxisCount(tester), 1);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '创建团队'), findsNothing);
  });
});
```

---

## 十二、用例汇总表

### 12.1 测试用例汇总

| 用例 ID | 描述 | Widget Under Test | 优先级 | 所属组件 | 状态 |
|---------|------|-------------------|--------|----------|------|
| TC-TEAM-UI-001 | 团队列表有数据时正确渲染卡片网格 | `TeamListPage` + `TeamCard` | P0 | 团队列表页 | 待执行 |
| TC-TEAM-UI-002 | 团队列表空状态 | `TeamListPage` + `EmptyTeamListState` | P0 | 团队列表页 | 待执行 |
| TC-TEAM-UI-003 | 点击卡片导航到详情页 | `TeamCard` | P0 | 团队列表页 | 待执行 |
| TC-TEAM-UI-004 | 创建团队表单验证 | `CreateTeamDialog` | P0 | 团队列表页 | 待执行 |
| TC-TEAM-UI-005 | 团队详情页正确渲染 | `TeamDetailPage` | P0 | 团队详情页 | 待执行 |
| TC-TEAM-UI-006 | 编辑团队信息 | `EditTeamDialog` | P0 | 团队详情页 | 待执行 |
| TC-TEAM-UI-007 | 删除团队确认流程 | `DeleteTeamDialog` | P0 | 团队详情页 | 待执行 |
| TC-TEAM-UI-008 | 离开团队确认流程 | `LeaveTeamDialog` | P0 | 团队详情页 | 待执行 |
| TC-TEAM-UI-009 | 成员列表正确渲染 | `MembersList` + `MemberListItem` | P0 | 成员管理 | 待执行 |
| TC-TEAM-UI-010 | 邀请成员对话框 | `InviteMemberDialog` | P0 | 成员管理 | 待执行 |
| TC-TEAM-UI-011 | 移除成员确认流程 | `RemoveMemberDialog` | P0 | 成员管理 | 待执行 |
| TC-TEAM-UI-012 | AppBar 选择器下拉菜单渲染 | `TeamSelector` | P0 | AppBar 选择器 | 待执行 |
| TC-TEAM-UI-013 | 切换团队上下文 | `TeamSelector` | P0 | AppBar 选择器 | 待执行 |
| TC-TEAM-UI-014 | 归属选择默认选中当前上下文 | `OwnershipSelector` | P0 | 资源创建对话框 | 待执行 |
| TC-TEAM-UI-015 | 权限矩阵 UI 条件渲染 | `TeamDetailPage` | P0 | 权限矩阵 | 待执行 |
| TC-TEAM-UI-016 | 错误状态 UI（网络/403/404） | `TeamListPage` + `TeamDetailPage` | P0 | 错误处理 | 待执行 |
| TC-TEAM-UI-017 | 响应式布局（3/2/1 列） | `TeamListPage` | P1 | 响应式布局 | 待执行 |

### 12.2 UI 组件覆盖矩阵

| UI 组件 | 覆盖用例 | 覆盖状态 |
|---------|----------|----------|
| **团队列表页 (`/teams`)** | TC-TEAM-UI-001 ~ 004, 016, 017 | ✅ 完全覆盖 |
| **团队详情页 (`/teams/:id`)** | TC-TEAM-UI-005 ~ 008, 015, 016 | ✅ 完全覆盖 |
| **成员管理** | TC-TEAM-UI-009 ~ 011 | ✅ 完全覆盖 |
| **AppBar 团队选择器** | TC-TEAM-UI-012 ~ 013 | ✅ 完全覆盖 |
| **资源创建归属选择** | TC-TEAM-UI-014 | ✅ 完全覆盖 |

### 12.3 需求追踪矩阵

| 需求场景 | 对应用例 ID | 优先级 |
|----------|-------------|--------|
| 团队列表渲染 with data | TC-TEAM-UI-001 | P0 |
| 团队列表 empty state | TC-TEAM-UI-002 | P0 |
| 团队卡片 interactions | TC-TEAM-UI-003 | P0 |
| 创建团队 form validation | TC-TEAM-UI-004 | P0 |
| 团队详情页 rendering | TC-TEAM-UI-005 | P0 |
| 编辑团队 form | TC-TEAM-UI-006 | P0 |
| 删除团队 confirmation | TC-TEAM-UI-007 | P0 |
| 离开团队 confirmation | TC-TEAM-UI-008 | P0 |
| 成员列表 rendering | TC-TEAM-UI-009 | P0 |
| 邀请成员 dialog | TC-TEAM-UI-010 | P0 |
| 移除成员 confirmation | TC-TEAM-UI-011 | P0 |
| AppBar 团队 selector dropdown | TC-TEAM-UI-012 | P0 |
| 团队 switch interaction | TC-TEAM-UI-013 | P0 |
| 资源创建 ownership selection | TC-TEAM-UI-014 | P0 |
| 权限-based UI (hide/show buttons) | TC-TEAM-UI-015 | P0 |
| 错误状态 (network/403/404) | TC-TEAM-UI-016 | P0 |

---

## 十三、测试执行注意事项

### 13.1 依赖 Mock 列表

| 依赖 | Mock 类名 | 用途 |
|------|-----------|------|
| TeamService | `MockTeamService` | 模拟团队 API 调用 |
| GoRouter | `MockGoRouter` | 模拟路由导航 |
| TeamListProvider | Provider override | 模拟列表状态 |
| TeamDetailProvider | Provider override | 模拟详情状态 |
| TeamMembersProvider | Provider override | 模拟成员列表状态 |
| TeamContextProvider | Provider override | 模拟当前上下文 |
| CurrentUserRoleProvider | Provider override | 模拟当前用户角色 |

### 13.2 主题测试建议

建议在深色主题下复跑以下核心用例，验证颜色符合设计规范：
- TC-TEAM-UI-001（角色徽章深色色值）
- TC-TEAM-UI-007（危险区域深色色值）
- TC-TEAM-UI-012（选择器选中项深色色值）
- TC-TEAM-UI-014（权限提示深色色值）

使用 `TestApp.dark(...)` 包装被测 Widget。

### 13.3 动画处理

部分组件包含动画（对话框展开 200ms、卡片悬停 150ms），测试中需要：
- 打开/关闭对话框后调用 `await tester.pumpAndSettle()`
- 状态切换动画后调用 `await tester.pump(const Duration(milliseconds: 250))`

### 13.4 辅助测试文件规划

建议创建以下测试文件：

```
test/features/team/
├── team_list_page_test.dart          # TC-TEAM-UI-001 ~ 004, 016, 017
├── team_detail_page_test.dart        # TC-TEAM-UI-005 ~ 008, 015
├── member_management_test.dart       # TC-TEAM-UI-009 ~ 011
├── team_selector_test.dart           # TC-TEAM-UI-012 ~ 013
├── ownership_selector_test.dart      # TC-TEAM-UI-014
├── helpers/
│   ├── team_test_data.dart           # 模拟数据
│   └── team_test_helpers.dart        # 断言辅助函数
└── mocks/
    └── mock_team_service.dart        # MockTeamService
```

---

**文档结束**

*本文档基于 Figma 原型 `log/release_2/ui/figma/` 和 UI 设计规范 `log/release_2/ui/specifications/team_management_ui_spec.md` 编制。测试用例覆盖所有 5 个 UI 组件的 16 个核心场景。*
