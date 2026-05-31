# TASK-004 测试用例 — 路由系统（go_router 17.2.3）

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-004（路由系统，go_router 17.2.3）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md)

---

## 测试范围

TASK-004 需交付以下文件：

| # | 文件 | 功能 | 测试覆盖 |
|---|------|------|:------:|
| 1 | `lib/router/app_router.dart` | GoRouter 配置 + 路由守卫 + URL 策略 | TC-001 ~ TC-028 |
| 2 | `lib/widgets/app_shell.dart` | 应用外壳（NavigationRail/BottomNav） | TC-007 ~ TC-009, TC-019 ~ TC-020 |
| 3 | 各占位页面 | LoginPage, RegisterPage, DashboardPage 等 | TC-001, TC-013 ~ TC-015（占位验证） |

---

## 路由配置速查

### 公开路由（无需认证）

| 路径 | 页面 | 说明 |
|------|------|------|
| `/login` | LoginPage | 登录页，初始路由 |
| `/register` | RegisterPage | 注册页 |

### 受保护路由（ShellRoute 包裹）

| 路径 | 页面 | 导航标签 |
|------|------|----------|
| `/dashboard` | DashboardPage | 首页 |
| `/workbenches` | WorkbenchListPage | 工作台 |
| `/workbenches/:id` | WorkbenchDetailPage | — |
| `/methods` | MethodListPage | 方法 |
| `/methods/:id/edit` | MethodEditPage | — |
| `/experiments` | ExperimentListPage | 试验 |
| `/experiments/new` | ExperimentCreatePage | — |
| `/experiments/:id` | ExperimentConsolePage | — |
| `/analysis` | AnalysisPage | 分析 |
| `/settings` | SettingsPage | 设置 |

### 受保护路由（非 ShellRoute 包裹，独立页面）

| 路径 | 页面 | 说明 |
|------|------|------|
| `/profile` | ProfilePage | 个人资料页，不需要 Shell |

### go_router 17.2.3 URL 策略

- **Web 模式**: `--web-url-strategy=path`（推荐），使用 `/login`、`/dashboard` 等无 `#` 的路径
- **Hash 模式**: 兼容性回退方案，使用 `/#/login`、`/#/dashboard`
- **测试验证点**: 确保 `GoRouter` 配置中正确设置了路径策略

---

## 一、路由配置测试

---

### TC-001: 所有路由路径正确注册

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（路由缺失导致页面不可达） |
| **类别** | 路由配置 / 完整性 |
| **关联验收标准** | 所有路由可访问（占位页面） |

**前置条件**：
- TASK-001 完成，`lib/main.dart` 和 `lib/app.dart` 骨架存在
- TASK-003 完成（AuthService 可注入，用于路由守卫的认证检查）
- `lib/router/app_router.dart` 已实现

**GoRouter 配置结构参考**：
```dart
final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) { /* 认证守卫逻辑 */ },
  routes: [
    // 公开路由
    GoRoute(path: '/login', ...),
    GoRoute(path: '/register', ...),
    // 受保护路由 (ShellRoute)
    ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
      GoRoute(path: '/dashboard', ...),
      GoRoute(path: '/workbenches', ...),
      GoRoute(path: '/workbenches/:id', ...),
      GoRoute(path: '/methods', ...),
      GoRoute(path: '/experiments', ...),
      GoRoute(path: '/experiments/new', ...),
      GoRoute(path: '/experiments/:id', ...),
      GoRoute(path: '/analysis', ...),
      GoRoute(path: '/settings', ...),
    ]),
    // 受保护独立页面（不带 Shell）
    GoRoute(path: '/profile', ...),
  ],
);
```

**测试步骤**：

1. 获取 `GoRouter` 实例的 `configuration.routes` 列表
2. 递归遍历所有路由，收集所有路径到一个集合中
3. 验证以下全部路径均已注册（使用 `GoRouter.of(context).routerDelegate.currentConfiguration` 或通过直接遍历 `routes`）：

**必须存在的路由路径**：

| # | 路径 | 页面类型 | 认证要求 |
|---|------|----------|:------:|
| 1 | `/login` | LoginPage | ❌ |
| 2 | `/register` | RegisterPage | ❌ |
| 3 | `/dashboard` | DashboardPage | ✅ |
| 4 | `/profile` | ProfilePage | ✅ |
| 5 | `/settings` | SettingsPage | ✅ |
| 6 | `/workbenches` | WorkbenchListPage | ✅ |
| 7 | `/workbenches/:id` | WorkbenchDetailPage | ✅ |
| 8 | `/methods` | MethodListPage | ✅ |
| 9 | `/methods/:id/edit` | MethodEditPage | ✅ |
| 10 | `/experiments` | ExperimentListPage | ✅ |
| 11 | `/experiments/new` | ExperimentCreatePage | ✅ |
| 12 | `/experiments/:id` | ExperimentConsolePage | ✅ |
| 13 | `/analysis` | AnalysisPage | ✅ |

**预期结果**：
- ✅ 上表全部 13 个路由路径均存在于路由配置中
- ✅ 每个路由有对应的 `builder` 函数，返回正确的页面 Widget
- ✅ 不存在路径冲突（两个路由匹配同一路径）
- ✅ `experiments/new` 路由位于 `experiments/:id` 之前，避免 `new` 被 `:id` 参数捕获

**失败判定**：
- ❌ 任一必需路径缺失
- ❌ 路由 builder 为 null 或返回非 Widget 类型
- ❌ `/experiments/new` 被 `/experiments/:id` 拦截（路由顺序错误）
- ❌ 两个公开路由不在 ShellRoute 内部

---

### TC-002: 路由参数正确解析（:id 参数）

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（深层链接和详情页依赖参数解析） |
| **类别** | 路由配置 / 参数解析 |
| **关联验收标准** | go_router 17.x 类型安全路径参数 |

**前置条件**：
- TC-001 通过（所有路由已注册）
- `WorkbenchDetailPage` 和 `ExperimentConsolePage` 的构造函数接收 `String id` 参数

**测试步骤**：

1. 使用 `GoRouter` 导航到 `/workbenches/550e8400-e29b-41d4-a716-446655440000`
2. 通过 `GoRouterState.pathParameters` 验证 `id` 值
3. 使用 `GoRouter` 导航到 `/workbenches/abc-123`
4. 验证 `id` = `"abc-123"`
5. 使用 `GoRouter` 导航到 `/experiments/660e8400-e29b-41d4-a716-446655440001`
6. 验证 `id` 值
7. 使用 `GoRouter` 导航到 `/methods/770e8400-e29b-41d4-a716-446655440002/edit`
8. 验证 `id` = `"770e8400-e29b-41d4-a716-446655440002"`

**测试参数矩阵**：

| 路径 | pathParameters 期望 |
|------|---------------------|
| `/workbenches/550e8400` | `{'id': '550e8400'}` |
| `/workbenches/abc-123` | `{'id': 'abc-123'}` |
| `/experiments/660e8400` | `{'id': '660e8400'}` |
| `/methods/770e8400/edit` | `{'id': '770e8400'}` |
| `/experiments/new` | `{}` 或 `{'id': 'new'}` — **不应将 `new` 解析为 `:id` 参数** |

**预期结果**：
- ✅ `GoRouterState.pathParameters['id']` 返回正确的 UUID/字符串
- ✅ `/experiments/new` 路由优先匹配，不会将 `new` 解析为 `:id` 参数
- ✅ `/methods/:id/edit` 正确解析 `id` 参数
- ✅ 参数值包含特殊字符（如 `%20` 编码的空格）时正确解码

**失败判定**：
- ❌ `pathParameters['id']` 为 null
- ❌ URL 编码的参数未正确解码（如 `%20` 未被转为空格）
- ❌ `/experiments/new` 被 `/experiments/:id` 错误捕获（路由优先级错误）

---

### TC-003: 初始路由为 /login

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P0 — CRITICAL**（首次访问的路由入口） |
| **类别** | 路由配置 / 初始路由 |
| **关联验收标准** | 应用启动后未认证用户首先看到登录页 |

**前置条件**：
- `GoRouter` 配置 `initialLocation: '/login'`
- 认证状态为"未登录"

**测试步骤**：

1. 启动应用（或创建 `GoRouter` 实例，认证状态为 `false`）
2. 不传入任何初始路径
3. 验证 `GoRouter.of(context).routerDelegate.currentConfiguration` 中 `matches.last.matchedLocation` = `'/login'`
4. 验证渲染的页面为 `LoginPage`

**预期结果**：
- ✅ 初始路由 `/login`，渲染 `LoginPage`
- ✅ 如果 `initialLocation` 未设置，默认行为与 `/login` 一致

**失败判定**：
- ❌ 初始位置不是 `/login`（如直接跳转到 `/dashboard`）
- ❌ `GoRouter` 抛出路由未找到异常

---

### TC-004: 路由优先级验证 — 静态路由 > 参数路由

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — CRITICAL**（路由匹配正确性） |
| **类别** | 路由配置 / 优先级 |
| **关联验收标准** | 静态路径优先于参数化路径 |

**前置条件**：
- TC-001 通过

**测试步骤**：

1. 导航到 `/experiments/new`
2. 验证匹配的路由是 `ExperimentCreatePage`（builder 为 `ExperimentCreatePage`）
3. 验证 `pathParameters` 为空（不应包含 `id` 参数）
4. 导航到 `/experiments/abc-def-123`
5. 验证匹配的路由是 `/experiments/:id`（builder 为 `ExperimentConsolePage`）
6. 验证 `pathParameters['id']` = `'abc-def-123'`

**预期结果**：
- ✅ `/experiments/new` 匹配 ExperimentCreatePage（静态优先）
- ✅ `/experiments/<任意UUID>` 匹配 ExperimentConsolePage
- ✅ 路由顺序 `experiments/new` → `experiments/:id` 保证 `new` 不被 `:id` 捕获

**失败判定**：
- ❌ `/experiments/new` 导航到试验控制台页（被 `:id` 错误匹配）
- ❌ `pathParameters` 异常

---

## 二、认证守卫测试

---

### TC-005: 未登录用户访问受保护路由 → 重定向到 /login

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — CRITICAL**（系统安全基础） |
| **类别** | 路由守卫 / 未认证拦截 |
| **关联验收标准** | 认证守卫正确重定向 |

**前置条件**：
- `GoRouter` redirect 守卫配置完成
- 认证状态（`authState.isLoggedIn`） = `false`
- 使用 Provider/Riverpod 或其他方式可注入/切换认证状态

**测试步骤**：

对以下每个受保护路由执行测试：

| # | 路径 | 描述 |
|---|------|------|
| 1 | `/dashboard` | 首页仪表盘 |
| 2 | `/profile` | 个人资料页 |
| 3 | `/settings` | 设置页 |
| 4 | `/workbenches` | 工作台列表 |
| 5 | `/workbenches/123` | 工作台详情 |
| 6 | `/methods` | 方法列表 |
| 7 | `/methods/123/edit` | 方法编辑 |
| 8 | `/experiments` | 试验列表 |
| 9 | `/experiments/new` | 创建试验 |
| 10 | `/experiments/123` | 试验控制台 |
| 11 | `/analysis` | 数据分析 |

对于每个路径：
1. 直接导航到该路径（如通过 `context.go(protectedPath)` 或直接在浏览器输入 URL）
2. 验证路由发生了重定向
3. 验证最终渲染的页面为 `LoginPage`
4. 验证 `GoRouterState` 中 `matchedLocation` = `'/login'`

**预期结果**：
- ✅ 全部 11 个受保护路径均被重定向到 `/login`
- ✅ 未抛出异常或崩溃
- ✅ 重定向是即时发生的（用户不会短暂看到目标页面内容）

**失败判定**：
- ❌ 任一受保护路由在白屏/未登录状态下可访问（无重定向）
- ❌ 重定向目标不是 `/login`
- ❌ 重定向前页面内容短暂闪现（闪烁）

---

### TC-006: 已登录用户访问 /login → 重定向到 /dashboard

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 路由守卫 / 已认证保护 |
| **关联验收标准** | 登录态用户不应看到登录页 |

**前置条件**：
- 认证状态（`authState.isLoggedIn`） = `true`
- 应用已启动，用户已登录

**测试步骤**：

1. 在已登录状态下，使用 `context.go('/login')` 导航到登录页
2. 验证路由发生了重定向
3. 验证最终渲染的页面为 `DashboardPage`
4. 验证 `GoRouterState` 中 `matchedLocation` = `'/dashboard'`
5. 在浏览器地址栏直接输入 `/login` 并回车
6. 验证同样被重定向到 `/dashboard`

**预期结果**：
- ✅ 已登录用户访问 `/login` → 自动重定向到 `/dashboard`
- ✅ 渲染 `DashboardPage`（被 ShellRoute + AppShell 包裹）
- ✅ 浏览器地址栏 URL 更新为 `/dashboard`
- ✅ 无错误日志或异常

**失败判定**：
- ❌ 已登录用户仍能看到 LoginPage
- ❌ 重定向导致循环（`/login` → `/dashboard` → `/login` → ...）
- ❌ 重定向未更新浏览器地址栏 URL

---

### TC-007: 已登录用户正常访问所有受保护路由

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL**（核心功能可用性） |
| **类别** | 路由守卫 / 正常通行 |
| **关联验收标准** | 认证用户可访问所有路由 |

**前置条件**：
- 认证状态（`authState.isLoggedIn`） = `true`

**测试步骤**：

对 TC-005 中列出的每个受保护路由：
1. 使用 `context.go(protectedPath)` 导航
2. 验证没有发生重定向
3. 验证最终渲染的是正确的目标页面（非 LoginPage）
4. 验证 `GoRouterState` 中 `matchedLocation` 等于目标路径

**预期结果**：
- ✅ 全部 11 个受保护路由均可正常访问
- ✅ 每个路由渲染正确的占位页面 Widget
- ✅ redirect guard 返回 null（不触发重定向）

**失败判定**：
- ❌ 任一路由被错误重定向到 `/login`
- ❌ 渲染的页面类型错误
- ❌ 导航到受保护路由时抛出异常

---

### TC-008: 登录后返回原始目标页面（Return-to 机制）

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — CRITICAL**（用户体验核心功能） |
| **类别** | 路由守卫 / Return-to |
| **关联验收标准** | 登录后返回原始目标页面 |

**前置条件**：
- 认证状态初始为 `false`（未登录）
- `GoRouter` redirect 配置中保存了 `state.matchedLocation` 用于登录后返回

**测试步骤**：

1. 在未登录状态下，尝试导航到 `/workbenches/550e8400`
2. 验证被重定向到 `/login`，且原始目标（`/workbenches/550e8400`）被保存
3. 模拟登录成功（`authState.isLoggedIn` 变为 `true`）
4. 验证自动导航到保存的原始目标 `/workbenches/550e8400`
5. 验证渲染的页面为 `WorkbenchDetailPage`，参数 `id` = `"550e8400"`

**Return-to 保存方式测试**：

| 方式 | 实现方法 | 测试验证点 |
|------|----------|-----------|
| **query param** | 重定向到 `/login?redirect=/workbenches/550e8400` | URL 中包含 `?redirect=...`，登录后读取并跳转 |
| **GoRouter state** | 使用 `state.extra` 或 `state.uri` 保存原始路径 | 登录后的回调能获取原始路径 |
| **Provider** | 登录前将目标路径存入 Provider/Notifier | 登录成功后从 Provider 读取并跳转 |

**预期结果**：
- ✅ 登录后被自动导航到原始目标页面（而非默认 `/dashboard`）
- ✅ 原始目标页面的所有参数（如 `:id`）被正确还原
- ✅ 如果原始目标是公开页面（如 `/register`），也正确处理
- ✅ 返回机制只触发一次（不会在后续导航中再次跳转）

**失败判定**：
- ❌ 登录后总是导航到 `/dashboard`（丢失原始目标）
- ❌ 原始目标参数丢失（如 uuid 变成 null）
- ❌ 返回机制在已登录状态下也触发（导致 `context.go` 总是跳到旧目标）

---

### TC-009: 已登录用户访问 /register → 重定向到 /dashboard

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P1 — HIGH**（逻辑一致性） |
| **类别** | 路由守卫 / 已认证保护 |
| **关联验收标准** | 已登录用户不应看到注册页 |

**前置条件**：
- 认证状态（`authState.isLoggedIn`） = `true`

**测试步骤**：

1. 在已登录状态下，使用 `context.go('/register')` 导航到注册页
2. 验证发生了重定向
3. 验证最终渲染的页面为 `DashboardPage`

**预期结果**：
- ✅ 已登录用户访问 `/register` → 自动重定向到 `/dashboard`
- ✅ 或者：守卫逻辑保持一致（如果设计为也重定向则是正确行为）
- ⚠️ 注意：部分应用允许已登录用户访问 `/register`（创建子账号场景）。本应用注册策略为自助注册，因此已登录用户也应被重定向

**失败判定**：
- ❌ 已登录用户仍能看到注册表单
- ❌ 重定向导致无限循环

---

### TC-010: 应用启动时 Token 有效 → 不触发守卫重定向

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P1 — HIGH**（启动流程正确性） |
| **类别** | 路由守卫 / 启动流程 |
| **关联验收标准** | 启动时 Token 有效则直接进入首页 |

**前置条件**：
- 本地存储存在有效的 Access Token
- 应用启动时认证状态初始化为"已登录"（或异步检查后变为"已登录"）
- `initialLocation: '/login'`

**测试步骤**：

1. 启动应用（模拟已存在有效 Token 的场景）
2. 验证 `GoRouter` 的 redirect 被触发
3. 验证因为用户已登录且在 `/login`，redirect 返回 `/dashboard`
4. 验证最终渲染 `DashboardPage`

**预期结果**：
- ✅ 应用启动后自动跳转到 `/dashboard`（不显示登录页）
- ✅ 没有短暂的登录页闪现
- ✅ 如果认证状态是异步检查的（如启动时 loading），应有合适的过渡处理

**失败判定**：
- ❌ 启动后停留在 `/login` 页面
- ❌ 先显示 `/login`，再快速跳转 `/dashboard`（视觉闪烁）
- ❌ 异步认证检查期间显示空白或错误

---

## 三、ShellRoute 与 AppShell 测试

---

### TC-011: ShellRoute 正确包裹所有受保护页面

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P0 — CRITICAL**（导航框架基础） |
| **类别** | ShellRoute / 结构 |
| **关联验收标准** | ShellRoute 正确嵌套，子路由共享 AppShell |

**前置条件**：
- TC-001 通过
- `AppShell` 组件已实现（至少包含占位 UI + `child` 插槽）
- `GoRouter` 使用 `ShellRoute`

**测试步骤**：

1. 遍历 ShellRoute 下的所有子路由（`/dashboard`, `/workbenches`, `/workbenches/:id`, `/methods`, `/methods/:id/edit`, `/experiments`, `/experiments/new`, `/experiments/:id`, `/analysis`, `/settings`）
2. 导航到每个子路由
3. 验证每个页面被 `AppShell` widget 包裹（通过 widget tree 层级验证）
4. 验证 `AppShell` 的 `child` 参数为对应的页面 Widget
5. 验证 `/login` 和 `/register` **不在** `AppShell` 中（无导航栏）

**ShellRoute 包裹关系验证**：

```dart
// 期望的 Widget 树结构
MaterialApp.router
└── AppShell                  // ShellRoute builder
    ├── NavigationRail / BottomNavigationBar
    └── child: 目标页面        // ShellRoute routes
```

**预期结果**：
- ✅ 全部 ShellRoute 子路由的页面均被 `AppShell` 包裹
- ✅ `/login` 和 `/register` 不在 `AppShell` 中
- ✅ `/profile` 需要确认：如 PRD 未要求导航栏，可不在 ShellRoute 内
- ✅ `AppShell` 的 `child` 在路由切换时正确更新

**失败判定**：
- ❌ ShellRoute 子路由未被 AppShell 包裹
- ❌ 公开路由（`/login`, `/register`）意外被 AppShell 包裹
- ❌ AppShell 的 child 不随路由切换更新

---

### TC-012: AppShell 包含导航栏组件

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P1 — HIGH**（导航可用性） |
| **类别** | AppShell / 导航 UI |
| **关联验收标准** | AppShell 包含导航栏 |

**前置条件**：
- TC-011 通过
- `AppShell` 已实现

**测试步骤**：

1. 导航到任意 ShellRoute 子路由（如 `/dashboard`）
2. 验证 `AppShell` 的 Widget 树中包含导航组件
3. 验证导航组件包含以下导航标签及其对应路径：

| 导航标签文字 | 对应路径 | 图标/描述 |
|-------------|----------|----------|
| 首页 | `/dashboard` | Home/Dashboard icon |
| 工作台 | `/workbenches` | Build/Workbench icon |
| 方法 | `/methods` | Science/Method icon |
| 试验 | `/experiments` | Experiment/Science icon |
| 分析 | `/analysis` | Analytics/Chart icon |
| 设置 | `/settings` | Settings/Gear icon |

4. 验证每个导航项在点击时触发正确的路由导航
5. 验证当前激活的导航项视觉高亮（与当前路由匹配）

**预期结果**：
- ✅ AppShell 包含全部 6 个导航入口
- ✅ 每个导航项点击导航到对应路径
- ✅ 当前页面标签视觉高亮
- ✅ 导航项有可访问标签（label/semanticLabel）

**失败判定**：
- ❌ 缺少任一导航标签
- ❌ 导航点击无效或导航到错误路径
- ❌ 当前路由与高亮标签不一致
- ❌ 缺少可访问性标签

---

### TC-013: 子路由切换时 AppShell 保持状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P0 — CRITICAL**（ShellRoute 核心功能） |
| **类别** | AppShell / 状态保持 |
| **关联验收标准** | 子路由切换时 AppShell 不被重建 |

**前置条件**：
- TC-011 通过
- 使用 `ShellRoute`（非普通 `GoRoute` 嵌套）
- `AppShell` 中有可观测的状态（如文本输入框、滚动位置、展开/折叠状态）

**测试步骤**：

1. 导航到 `/dashboard`（在 AppShell 中）
2. 在 AppShell 导航栏中执行可观测操作：
   - 对于 NavigationRail：展开/折叠侧边栏
   - 在导航栏中留下可观测状态（如输入框文字、滚动位置）
3. 使用导航栏切换到 `/workbenches`
4. 验证步骤 2 中的 AppShell 状态保持不变（侧边栏展开状态、输入框文字等未丢失）
5. 再次切换回 `/dashboard`
6. 验证 AppShell 状态仍然保持

**Widget Key 验证**：
- 使用 `find.byKey()` 验证 AppShell 的 `Key` 未改变
- 或在测试中通过 `tester.state<AppShellState>()` 验证状态保持

**预期结果**：
- ✅ AppShell widget 在子路由切换时不被重建
- ✅ AppShell 的内部状态（展开/折叠、滚动位置等）保持不变
- ✅ 仅 `child` 区域的内容随路由更新
- ✅ `GoRouter` ShellRoute 使用同一个 `builder` 实例

**失败判定**：
- ❌ 每次切换路由时 AppShell 被完全重建（NavigationRail 闪烁/状态丢失）
- ❌ 由于使用了非 `ShellRoute` 而导致状态丢失

---

### TC-014: AppShell 响应式布局 — 小屏 (<600px)

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P1 — HIGH**（移动端适配） |
| **类别** | AppShell / 响应式 |
| **关联验收标准** | AppShell 在三种宽度下正确渲染 |

**前置条件**：
- `AppShell` 使用 `LayoutBuilder` 实现响应式
- 断点定义：
  - 大屏 (>1200px): NavigationRail 左侧常驻
  - 中屏 (600-1200px): NavigationRail 可折叠
  - 小屏 (<600px): BottomNavigationBar 底部

**测试步骤**：

1. 设置测试环境窗口大小为 **360x640**（小屏手机）
2. 导航到 `/dashboard`
3. 验证以下行为：

**小屏 (<600px)**：
- ✅ 导航组件类型为 `BottomNavigationBar`（非 NavigationRail）
- ✅ 导航栏位于**屏幕底部**
- ✅ 导航栏高度约 56-64dp（符合 Material Design 规范）
- ✅ 所有 6 个导航项可见或使用"更多"菜单折叠
- ✅ 正文内容区域不受导航遮挡
- ✅ 无水平滚动条

**预期结果**：
- ✅ 小屏显示 BottomNavigationBar（底部导航栏）
- ✅ 导航项可正常点击
- ✅ 布局不溢出

**失败判定**：
- ❌ 小屏仍显示 NavigationRail（导致横向空间不足）
- ❌ 导航栏遮挡内容
- ❌ 出现横向滚动条

---

### TC-015: AppShell 响应式布局 — 中屏 (600-1200px)

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P1 — HIGH** |
| **类别** | AppShell / 响应式 |
| **关联验收标准** | 中屏下 NavigationRail 可折叠 |

**前置条件**：
- TC-014 相同

**测试步骤**：

1. 设置测试环境窗口大小为 **800x600**（平板/中屏）
2. 导航到 `/dashboard`
3. 验证以下行为：

**中屏 (600-1200px)**：
- ✅ 导航组件类型为 `NavigationRail`
- ✅ NavigationRail 默认状态为**可折叠**（窄模式，仅图标）
- ✅ 可通过按钮切换展开/折叠状态（展开时显示图标+文字）
- ✅ NavigationRail 位于**左侧**
- ✅ NavigationRail 的高度占满屏幕高度
- ✅ 折叠状态下图标可见、文字隐藏
- ✅ 展开后文字可见

**预期结果**：
- ✅ 中屏显示 NavigationRail（左侧导航栏）
- ✅ 支持展开/折叠
- ✅ 折叠状态仅显示图标

**失败判定**：
- ❌ 中屏使用了 BottomNavigationBar 或全宽 NavigationRail
- ❌ 展开/折叠功能异常

---

### TC-016: AppShell 响应式布局 — 大屏 (>1200px)

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P1 — HIGH** |
| **类别** | AppShell / 响应式 |
| **关联验收标准** | 大屏下 NavigationRail 常驻展开 |

**前置条件**：
- TC-014 相同

**测试步骤**：

1. 设置测试环境窗口大小为 **1440x900**（桌面大屏）
2. 导航到 `/dashboard`
3. 验证以下行为：

**大屏 (>1200px)**：
- ✅ 导航组件类型为 `NavigationRail`
- ✅ NavigationRail **常驻展开**状态（图标 + 文字标签）
- ✅ NavigationRail 宽度适中（约 200-256dp）
- ✅ 无折叠/展开按钮（或固定为展开状态）
- ✅ NavigationRail 位于**左侧**常驻

**预期结果**：
- ✅ 大屏显示完整展开的 NavigationRail
- ✅ NavigationRail 固定位置，不因内容滚动而移动

**失败判定**：
- ❌ 大屏下 NavigationRail 默认折叠
- ❌ NavigationRail 随页面内容滚动
- ❌ 横向上出现意外滚动条

---

### TC-017: 响应式断点切换时的平滑过渡

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P2 — MEDIUM**（体验优化） |
| **类别** | AppShell / 响应式过渡 |
| **关联验收标准** | 窗口调整大小时导航组件正确切换 |

**前置条件**：
- TC-014 ~ TC-016 通过

**测试步骤**：

1. 在桌面大屏模式下（1440px），确认显示 NavigationRail
2. 逐步缩小窗口到 **1000px**
3. 验证导航从展开变为可折叠
4. 继续缩小到 **500px**
5. 验证 NavigationRail 切换为 BottomNavigationBar
6. 再扩大窗口回 **1440px**
7. 验证导航从 BottomNavigationBar → NavigationRail 折叠 → NavigationRail 展开

**预期结果**：
- ✅ 断点切换时导航组件正确切换
- ✅ 不出现组件类型混合（如同时显示两个）
- ✅ 切换过程无视觉闪烁/跳动
- ✅ `LayoutBuilder` 的 `constraints.maxWidth` 精确匹配断点值

**失败判定**：
- ❌ 窗口调整过程中崩溃
- ❌ 断点边界附近频繁切换（需要防抖或滞后处理）
- ❌ 切换时有明显的布局跳动

---

## 四、深层链接测试

---

### TC-018: 深层链接 — 直接访问 /workbenches/:id

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P0 — CRITICAL**（深层链接核心功能） |
| **类别** | 深层链接 / workbenches |
| **关联验收标准** | 深层链接正确解析参数并渲染页面 |

**前置条件**：
- 认证状态 = `true`（已登录）
- TC-002 通过

**测试步骤**：

**场景 A: 正常 UUID**：
1. 直接导航到 `/workbenches/550e8400-e29b-41d4-a716-446655440000`
2. 验证渲染 `WorkbenchDetailPage`
3. 验证 `pathParameters['id']` = `"550e8400-e29b-41d4-a716-446655440000"`

**场景 B: 短 ID**：
1. 导航到 `/workbenches/123`
2. 验证渲染 `WorkbenchDetailPage`
3. 验证 `id` = `"123"`

**场景 C: 含特殊字符的 ID**：
1. 导航到 `/workbenches/test%20wb`
2. 验证 `id` 被正确解码为 `"test wb"`

**场景 D: 未登录状态**：
1. 认证状态 = `false`
2. 直接导航到 `/workbenches/abc`
3. 验证被重定向到 `/login`
4. 登录后验证返回 `/workbenches/abc`

**预期结果**：
- ✅ 场景 A/B/C：正确解析 id 参数并渲染对应页面
- ✅ 场景 D：认证守卫正确拦截
- ✅ URL 中的特殊字符被正确解码（`%20` → 空格）

**失败判定**：
- ❌ 参数解析错误
- ❌ 未登录时直接显示详情页（未触发守卫）

---

### TC-019: 深层链接 — 直接访问 /experiments/:id

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 深层链接 / experiments |
| **关联验收标准** | experiment id 正确解析 |

**前置条件**：
- 认证状态 = `true`
- TC-002 通过

**测试步骤**：

1. 直接导航到 `/experiments/660e8400-e29b-41d4-a716-446655440001`
2. 验证渲染 `ExperimentConsolePage`
3. 验证 `pathParameters['id']` = `"660e8400-e29b-41d4-a716-446655440001"`
4. 导航到 `/experiments/new`
5. 验证渲染 `ExperimentCreatePage`（非 ExperimentConsolePage）

**预期结果**：
- ✅ `/experiments/:id` 正确解析
- ✅ `/experiments/new` 优先匹配
- ✅ UUID 作为 id 正确传递

**失败判定**：
- ❌ `/experiments/new` 匹配了 `:id` 路由
- ❌ id 参数为 null

---

### TC-020: 深层链接 — 直接访问 /methods/:id/edit

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P1 — HIGH** |
| **类别** | 深层链接 / methods |
| **关联验收标准** | 多段路径参数正确解析 |

**前置条件**：
- 认证状态 = `true`
- TC-002 通过

**测试步骤**：

1. 直接导航到 `/methods/770e8400-e29b-41d4-a716-446655440002/edit`
2. 验证渲染 `MethodEditPage`
3. 验证 `pathParameters['id']` = `"770e8400-e29b-41d4-a716-446655440002"`
4. 验证页面显示了二级路径 `edit` 匹配正确

**预期结果**：
- ✅ `/methods/:id/edit` 路径正确匹配
- ✅ `id` 参数正确解析
- ✅ `edit` 后缀正确匹配（不成为参数的一部分）

**失败判定**：
- ❌ 路径不匹配（路由配置中缺少 `/methods/:id/edit`）
- ❌ `id` 参数包含了 `/edit` 后缀

---

### TC-021: 无效路由 → 404 页面

| 属性 | 内容 |
|------|------|
| **ID** | TC-021 |
| **优先级** | **P0 — CRITICAL**（错误处理基础） |
| **类别** | 深层链接 / 404 |
| **关联验收标准** | 无效路由显示 404 或友好提示页面 |

**前置条件**：
- GoRouter 配置了错误页面（`errorBuilder` 或 `errorPageBuilder`）或默认错误处理
- 认证状态任意（未认证时守卫可能处理）

**测试步骤**：

1. 尝试导航到不存在路由，如：
   - `/nonexistent`
   - `/workbenches/123/extra-segment`（多级路径）
   - `/api/v1/auth/login`（后端 API 路径，不应存在前端路由）
   - `/random/xyz/abc`

2. 验证每个无效路径的行为

**场景 A: 未登录 + 无效路由**：
- 导航到 `/invalid/path`
- 预期：先触发认证守卫 → 重定向到 `/login`
- 或者：显示 404 页面（如果 404 页面不需要认证）

**场景 B: 已登录 + 无效路由**：
- 导航到 `/invalid/path`
- 预期：显示 404 页面或友好错误提示
- 404 页面应包含："页面未找到"提示 + "返回首页"链接

**预期结果**：
- ✅ 所有无效路由不导致应用崩溃（白屏/异常）
- ✅ 显示明确的 404 或错误页面（非空白页）
- ✅ 404 页面提供导航回有效页面的入口
- ✅ GoRouter 的 `errorBuilder` 或 ShellRoute 的 `errorBuilder` 正确配置

**失败判定**：
- ❌ 无效路由导致白屏或未处理的异常
- ❌ 404 页面包含技术错误信息（如堆栈跟踪）
- ❌ 404 页面没有返回导航的入口

---

### TC-022: 深层链接 + 认证守卫组合场景

| 属性 | 内容 |
|------|------|
| **ID** | TC-022 |
| **优先级** | **P1 — HIGH**（深层链接+认证综合场景） |
| **类别** | 深层链接 / 认证结合 |
| **关联验收标准** | 深层链接在未登录时保存路径，登录后恢复 |

**测试步骤**：

**场景: 外部链接 → 认证 → 目标页**：
1. 用户从外部点击链接 `https://kayak.local/workbenches/abc-123`
2. 应用启动，认证状态 = `false`
3. 验证被重定向到 `/login`
4. 用户登录成功后
5. 验证自动导航到 `/workbenches/abc-123`
6. 验证 `WorkbenchDetailPage` 接收 `id = "abc-123"`

**场景: 深层链接指向公开页面**：
1. 用户直接访问 `/register`（已登录）
2. 验证被重定向到 `/dashboard`

**预期结果**：
- ✅ 深层链接 → 302 登录 → 登录后回到目标
- ✅ 目标页面完整参数保留
- ✅ 公开页面深层链接也正确工作

**失败判定**：
- ❌ 深层链接的目标参数在认证流程中丢失
- ❌ 登录后跳转到默认页面而非深层链接目标

---

## 五、导航方法测试

---

### TC-023: context.go() 正确导航

| 属性 | 内容 |
|------|------|
| **ID** | TC-023 |
| **优先级** | **P0 — CRITICAL**（导航基础） |
| **类别** | 导航方法 / go() |
| **关联验收标准** | context.go() 正确更新路由 |

**前置条件**：
- 认证状态 = `true`（已登录）
- 已在某个起始页面（如 `/dashboard`）

**测试步骤**：

1. 在 `/dashboard` 页面中调用 `context.go('/workbenches')`
2. 验证当前路由变为 `/workbenches`
3. 验证渲染 `WorkbenchListPage`
4. 在 `/workbenches` 页面中调用 `context.go('/experiments')`
5. 验证当前路由变为 `/experiments`
6. 验证渲染 `ExperimentListPage`

**go() 与 push() 的区别验证**：
- `context.go('/pageA')` → 替换当前路由栈
- 调用 `context.go('/pageB')` → 替换 `/pageA`
- 验证后退按钮不会回到 `/pageA`（栈中只有 `/pageB`）

**预期结果**：
- ✅ `context.go(path)` 导航到目标页面
- ✅ 路由栈被替换（不可用 `pop()` 返回原来的页面）
- ✅ `context.go()` 可以用于 Tab 切换（导航栏切换不产生历史栈）

**失败判定**：
- ❌ `context.go()` 导航到错误页面
- ❌ 路由未更新（停留在当前页）
- ❌ `context.go()` 的行为与 `context.push()` 混淆

---

### TC-024: context.push() 正确导航并保留历史

| 属性 | 内容 |
|------|------|
| **ID** | TC-024 |
| **优先级** | **P0 — CRITICAL**（详情页导航基础） |
| **类别** | 导航方法 / push() |
| **关联验收标准** | context.push() 添加到导航栈 |

**前置条件**：
- 认证状态 = `true`
- 当前页面为 `/workbenches`（列表页）

**测试步骤**：

1. 在 `/workbenches` 页面中调用 `context.push('/workbenches/550e8400-e29b-41d4-a716-446655440000')`
2. 验证当前路由变为 `/workbenches/550e8400-e29b-41d4-a716-446655440000`
3. 验证渲染 `WorkbenchDetailPage`
4. 验证 `context.canPop()` = `true`
5. 调用 `context.pop()`
6. 验证回到 `/workbenches` 列表页
7. 验证列表页状态保持（如滚动位置、搜索文本等）

**预期结果**：
- ✅ `context.push(path)` 导航到目标页面并添加历史记录
- ✅ `context.canPop()` 返回 true
- ✅ `context.pop()` 回到上一页
- ✅ 上一页的状态被保持

**失败判定**：
- ❌ `push()` 后 `canPop()` 返回 false
- ❌ `pop()` 回到错误页面
- ❌ `push()` 行为与 `go()` 相同（替换而非添加）

---

### TC-025: context.pop() 正确返回上一页

| 属性 | 内容 |
|------|------|
| **ID** | TC-025 |
| **优先级** | **P0 — CRITICAL**（基础导航操作） |
| **类别** | 导航方法 / pop() |
| **关联验收标准** | context.pop() 从导航栈移除当前路由 |

**前置条件**：
- 已通过 `push()` 到达子页面（如从 `/workbenches` push 到 `/workbenches/abc`）
- 导航栈不为空

**测试步骤**：

1. 当前页面为 `/workbenches/abc`（通过 push 到达）
2. 调用 `context.pop()`
3. 验证回到 `/workbenches`
4. 验证 `WorkbenchDetailPage` 被销毁（dispose 被调用）
5. 在根页面（如 `/dashboard`）上调用 `context.pop()`
6. 验证不抛出异常（或 `canPop()` 返回 false，避免调用）

**边界测试**：
- **连续 push/pop**：push A → push B → push C → pop → pop → pop，验证每步返回正确页面
- **pop 到非预期页面**：push A → go B → pop，验证行为（go 后栈被替换，pop 可能回到更早的页面或触发 404）

**预期结果**：
- ✅ `context.pop()` 正确返回上一页
- ✅ 当前页面的 `dispose()` 方法被调用
- ✅ 在根页面尝试 `pop()` 不会崩溃（`canPop()` 防护）
- ✅ 连续 push/pop 正确管理导航栈

**失败判定**：
- ❌ `pop()` 后在错误页面
- ❌ 根页面 `pop()` 崩溃
- ❌ `pop()` 后之前页面的状态丢失（如列表被重建）

---

### TC-026: 浏览器前进/后退按钮同步

| 属性 | 内容 |
|------|------|
| **ID** | TC-026 |
| **优先级** | **P1 — HIGH**（Web 平台兼容性） |
| **类别** | 导航方法 / 浏览器集成 |
| **关联验收标准** | 浏览器导航按钮与 GoRouter 同步 |
| **前置条件**：
- 运行在 Web 模式（Chrome/Firefox）
- URL 路径策略为 `--web-url-strategy=path`（无 `#`）

**测试步骤**：

1. 导航到 `/dashboard` → `/workbenches` → `/workbenches/abc`（通过 push/push）
2. 点击浏览器**后退**按钮
3. 验证回到 `/workbenches`
4. 再次点击浏览器**后退**按钮
5. 验证回到 `/dashboard`
6. 点击浏览器**前进**按钮
7. 验证回到 `/workbenches`
8. 再次点击**前进**
9. 验证回到 `/workbenches/abc`

**认证场景**：
- 在未登录时从 `/login` 后退，验证不发生错误
- 登录后浏览器的后退按钮不会回到 `/login`

**预期结果**：
- ✅ 浏览器后退/前进按钮与 GoRouter 导航栈完全同步
- ✅ URL 地址栏正确更新
- ✅ 在登录页后退不会退回受保护页面（认证守卫生效）

**失败判定**：
- ❌ 浏览器后退导致认证守卫失效（可看到受保护页面）
- ❌ URL 更新但页面内容不更新
- ❌ 前进/后退导致崩溃或空白页

---

### TC-027: context.pushNamed() / context.goNamed() 命名路由导航

| 属性 | 内容 |
|------|------|
| **ID** | TC-027 |
| **优先级** | **P2 — MEDIUM**（如果使用了命名路由） |
| **类别** | 导航方法 / 命名路由 |
| **关联验收标准** | 命名路由导航正确（如使用） |

**前置条件**：
- 如果 `GoRoute` 配置了 `name` 属性（如 `name: 'workbench-detail'`）

**测试步骤**：

1. 使用 `context.pushNamed('workbench-detail', pathParameters: {'id': 'abc'})` 导航
2. 验证导航到 `/workbenches/abc`
3. 验证 `pathParameters['id']` = `'abc'`

**命名路由配置示例**（如使用）：
```dart
GoRoute(
  name: 'workbench-detail',
  path: '/workbenches/:id',
  builder: (_, state) => WorkbenchDetailPage(id: state.pathParameters['id']!),
)
```

**预期结果**：
- ✅ 命名路由导航与对应路径导航行为一致
- ✅ `pathParameters` 正确传递
- ✅ 未找到命名路由时抛出明确错误

**失败判定**：
- ❌ 命名路由未找到（name 不匹配）
- ❌ 参数传递错误

---

### TC-028: context.replace() 替换当前路由

| 属性 | 内容 |
|------|------|
| **ID** | TC-028 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 导航方法 / replace() |
| **关联验收标准** | replace 替换当前路由，不增加导航栈 |

**前置条件**：
- 当前页面为 `/workbenches/old-id`
- 需要在编辑后替换为新的 `/workbenches/new-id`

**测试步骤**：

1. 在 `/workbenches/old-id` 页面调用 `context.replace('/workbenches/new-id')`
2. 验证当前路由变为 `/workbenches/new-id`
3. 验证 `canPop()` 仍为 `true`（导航栈大小不变）
4. 调用 `pop()`
5. 验证回到 `/workbenches`（而非 `/workbenches/old-id`）

**预期结果**：
- ✅ `context.replace()` 替换当前路由，不改变导航栈大小
- ✅ 替换后 URL 更新
- ✅ `pop()` 回到替换前的上一页

**失败判定**：
- ❌ replace 后 `canPop()` 变为 false
- ❌ replace 未生效

---

## 六、边界与负向测试

---

### TC-029: 空路径参数 / 特殊字符参数

| 属性 | 内容 |
|------|------|
| **ID** | TC-029 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 边界测试 / 参数格式 |

**前置条件**：
- TC-001, TC-002 通过

**测试步骤**：

1. 尝试导航到 `/workbenches/`（末尾斜杠，id 为空）
2. 导航到 `/workbenches/%20`（仅空格 id）
3. 导航到 `/workbenches/<script>alert(1)</script>`（XSS 尝试）
4. 导航到 `/workbenches/../../../etc/passwd`（路径遍历尝试）

**预期结果**：
- ✅ 空 id 或空白 id 应由路由层或页面层处理（显示"资源不存在"或 404）
- ✅ XSS/路径遍历字符串不产生安全问题
- ✅ id 参数原样传递（URL 编码），由后端/业务逻辑验证
- ✅ 不会因参数格式异常而崩溃

**失败判定**：
- ❌ 空 id 参数导致应用崩溃
- ❌ XSS 负载在页面上被执行
- ❌ 路径遍历访问了不该访问的文件

---

### TC-030: 路由守卫重定向死循环保护

| 属性 | 内容 |
|------|------|
| **ID** | TC-030 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 边界测试 / 死循环保护 |
| **关联验收标准** | 路由守卫不会产生无限重定向 |

**前置条件**：
- `redirect` 守卫逻辑正确

**测试步骤**：

1. 验证 redirect 逻辑没有循环路径：

**检查项**：
```
❌ 禁止: 已登录 + /login → /login（循环）
❌ 禁止: 未登录 + /login → /workbenches → /login（循环）
❌ 禁止: 已登录 + /workbenches → /login → /dashboard → /login（循环）
```

2. 在测试中模拟高频率路由变化（如快速切换登录状态）
3. 验证 GoRouter 能处理且不进入无限循环

**Redirect 函数逻辑验证**（静态分析）：
```dart
redirect: (context, state) {
  final loggedIn = authState.isLoggedIn;
  final onLogin = state.matchedLocation == '/login';
  final onRegister = state.matchedLocation == '/register';

  // 情况 1: 未登录 + 非公开页面 → 去登录
  if (!loggedIn && !onLogin && !onRegister) return '/login';
  
  // 情况 2: 已登录 + 公开页面 → 去首页
  if (loggedIn && (onLogin || onRegister)) return '/dashboard';
  
  // 情况 3: 其他所有情况 → 不重定向
  return null;
}
```

**预期结果**：
- ✅ 所有状态变换路径都有唯一的 redirect 目标，不会循环
- ✅ GoRouter 在重定向超过一定次数后（如 5 次）自动停止（go_router 内置保护）
- ✅ redirect 函数中使用了 `state.matchedLocation` 而非 `state.fullPath`（避免重复前缀）

**失败判定**：
- ❌ redirect 逻辑存在循环路径
- ❌ 浏览器报"重定向次数过多"错误

---

### TC-031: 并发导航请求

| 属性 | 内容 |
|------|------|
| **ID** | TC-031 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 边界测试 / 并发安全 |

**前置条件**：
- 多个导航请求可能同时触发（如快速双击导航按钮）

**测试步骤**：

1. 在短时间内连续触发多次 `context.go()` 或 `context.push()` 调用
2. 验证每次导航最终到达目标页面
3. 验证不发生崩溃或未处理的异常

**示例场景**：
- 快速双击导航栏"工作台"按钮 → 应导航到 `/workbenches`（不报错）
- 在路由切换过程中再次触发导航 → 应正确处理（取消前一个或排队）

**预期结果**：
- ✅ 并发导航请求不导致崩溃
- ✅ 最终路由状态一致（到达最后请求的路径）
- ✅ 不出现多个页面叠加的 UI 异常

**失败判定**：
- ❌ 并发导航导致崩溃
- ❌ 路由状态不一致

---

### TC-032: 浏览器刷新 (F5) 时路由正确恢复

| 属性 | 内容 |
|------|------|
| **ID** | TC-032 |
| **优先级** | **P1 — HIGH**（Web 平台关键场景） |
| **类别** | 边界测试 / 浏览器刷新 |
| **关联验收标准** | 刷新页面后保持在当前路由 |

**前置条件**：
- 运行在 Web 模式
- `--web-url-strategy=path`

**测试步骤**：

1. 导航到 `/workbenches`
2. 刷新浏览器页面（模拟 F5 或地址栏回车）
3. 验证：
   - 如果已登录 → 停留在 `/workbenches`
   - 如果未登录 → 重定向到 `/login`，但 URL 保持/TODO
4. 导航到 `/workbenches/abc-123`
5. 刷新浏览器
6. 验证参数 `id=abc-123` 被正确恢复
7. 在 `/login` 页面刷新
8. 验证停留在 `/login`

**预期结果**：
- ✅ 刷新后路由路径正确恢复
- ✅ 路由参数保留（深层链接参数不丢失）
- ✅ 认证状态正确（已登录则恢复页面，未登录则触发守卫）
- ✅ 不出现短暂 404 或空白页面

**失败判定**：
- ❌ 刷新后跳到不同页面
- ❌ 刷新后参数丢失
- ❌ 刷新导致 404

---

## 七、测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | 全部路由路径注册 |
| TC-002 | | | ⬜ 待执行 | 路由参数解析 |
| TC-003 | | | ⬜ 待执行 | 初始路由 /login |
| TC-004 | | | ⬜ 待执行 | 静态路由优先级 |
| TC-005 | | | ⬜ 待执行 | 未登录拦截 (11 路径) |
| TC-006 | | | ⬜ 待执行 | 已登录跳过登录页 |
| TC-007 | | | ⬜ 待执行 | 已登录正常访问 |
| TC-008 | | | ⬜ 待执行 | Return-to 机制 |
| TC-009 | | | ⬜ 待执行 | 已登录跳转/register |
| TC-010 | | | ⬜ 待执行 | 启动时 Token 有效 |
| TC-011 | | | ⬜ 待执行 | ShellRoute 包裹验证 |
| TC-012 | | | ⬜ 待执行 | AppShell 导航组件 |
| TC-013 | | | ⬜ 待执行 | ShellRoute 状态保持 |
| TC-014 | | | ⬜ 待执行 | 小屏响应式 (<600px) |
| TC-015 | | | ⬜ 待执行 | 中屏响应式 (600-1200px) |
| TC-016 | | | ⬜ 待执行 | 大屏响应式 (>1200px) |
| TC-017 | | | ⬜ 待执行 | 断点平滑过渡 |
| TC-018 | | | ⬜ 待执行 | 深层链接 workbenches/:id |
| TC-019 | | | ⬜ 待执行 | 深层链接 experiments/:id |
| TC-020 | | | ⬜ 待执行 | 深层链接 methods/:id/edit |
| TC-021 | | | ⬜ 待执行 | 404 页面 |
| TC-022 | | | ⬜ 待执行 | 深层链接+认证组合 |
| TC-023 | | | ⬜ 待执行 | context.go() 导航 |
| TC-024 | | | ⬜ 待执行 | context.push() 导航 |
| TC-025 | | | ⬜ 待执行 | context.pop() 返回 |
| TC-026 | | | ⬜ 待执行 | 浏览器前进/后退 |
| TC-027 | | | ⬜ 待执行 | 命名路由导航 |
| TC-028 | | | ⬜ 待执行 | context.replace() |
| TC-029 | | | ⬜ 待执行 | 特殊字符参数 |
| TC-030 | | | ⬜ 待执行 | 重定向死循环保护 |
| TC-031 | | | ⬜ 待执行 | 并发导航安全 |
| TC-032 | | | ⬜ 待执行 | 浏览器刷新恢复 |

---

## 八、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| 路由配置测试 | 4 | TC-001 ~ TC-004 |
| 认证守卫测试 | 6 | TC-005 ~ TC-010 |
| ShellRoute / AppShell 测试 | 7 | TC-011 ~ TC-017 |
| 深层链接测试 | 5 | TC-018 ~ TC-022 |
| 导航方法测试 | 6 | TC-023 ~ TC-028 |
| 边界与负向测试 | 4 | TC-029 ~ TC-032 |
| **合计** | **32** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 15 |
| P1 — HIGH | 11 |
| P2 — MEDIUM | 6 |

---

## 九、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| 认证守卫正确重定向 | TC-005, TC-006, TC-007, TC-009, TC-010 |
| 登录后返回原始目标页面 | TC-008, TC-022 |
| 所有路由可访问（占位页面） | TC-001, TC-007 |
| AppShell 在三种宽度下正确渲染 | TC-014, TC-015, TC-016 |
| ShellRoute 正确嵌套 | TC-011, TC-013 |
| `go_router` 17.2.3 API 使用 | TC-001 ~ TC-032（全部使用新版 API） |
| `initialLocation: '/login'` | TC-003, TC-010 |
| URL 路径策略（path 模式） | TC-026, TC-032 |
| NavigationRail / BottomNavigationBar | TC-012, TC-014 ~ TC-017 |
| 响应式使用 `LayoutBuilder` | TC-014 ~ TC-017 |
| `flutter analyze` 零警告 | TC-030（死循环逻辑分析） |

---

## 十、附录 A：测试架构参考

### A.1 GoRouter 测试策略

对于 GoRouter 的 Widget 测试，推荐使用 `MaterialApp.router` 包裹并注入测试路由：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 创建测试用 GoRouter，支持注入认证状态
GoRouter createTestRouter({required bool isLoggedIn}) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final onLogin = state.matchedLocation == '/login';
      final onRegister = state.matchedLocation == '/register';

      if (!isLoggedIn && !onLogin && !onRegister) return '/login';
      if (isLoggedIn && (onLogin || onRegister)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const PlaceholderWidget(label: 'Login'),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const PlaceholderWidget(label: 'Register'),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const PlaceholderWidget(label: 'Dashboard'),
          ),
          GoRoute(
            path: '/workbenches',
            builder: (_, __) => const PlaceholderWidget(label: 'Workbenches'),
          ),
          GoRoute(
            path: '/workbenches/:id',
            builder: (_, state) => PlaceholderWidget(
              label: 'Workbench ${state.pathParameters['id']}',
            ),
          ),
          // ... 其他路由
        ],
      ),
    ],
  );
}

/// 测试帮助函数：验证重定向
Future<void> expectRedirect({
  required WidgetTester tester,
  required bool isLoggedIn,
  required String fromPath,
  required String expectedToPath,
}) async {
  final router = createTestRouter(isLoggedIn: isLoggedIn);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
  ));
  router.go(fromPath);
  await tester.pumpAndSettle();
  
  expect(router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
      equals(expectedToPath));
}
```

### A.2 AppShell 响应式测试

```dart
/// 设置自定义窗口大小用于响应式测试
void setTestSurfaceSize({required double width, required double height}) {
  // 使用 tester.binding.setSurfaceSize 设置模拟窗口大小
  // 然后使用 LayoutBuilder 验证导航组件类型
}

/// 验证导航组件类型
Finder expectNavigationRail() => find.byType(NavigationRail);
Finder expectBottomNavigationBar() => find.byType(BottomNavigationBar);
```

### A.3 路由参数测试

```dart
/// 验证深层链接参数解析
Future<void> testDeepLink({
  required WidgetTester tester,
  required bool isLoggedIn,
  required String path,
  required Map<String, String> expectedParams,
}) async {
  final router = createTestRouter(isLoggedIn: isLoggedIn);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.go(path);
  await tester.pumpAndSettle();

  final state = router.routerDelegate.currentConfiguration.matches.last;
  for (final entry in expectedParams.entries) {
    expect(state.pathParameters[entry.key], equals(entry.value));
  }
}
```

### A.4 测试文件组织

```
kayak-frontend/test/
├── router/
│   ├── app_router_test.dart           # TC-001 ~ TC-004, TC-030
│   ├── auth_guard_test.dart           # TC-005 ~ TC-010
│   ├── shell_route_test.dart          # TC-011 ~ TC-013
│   ├── responsive_appshell_test.dart  # TC-014 ~ TC-017
│   ├── deep_link_test.dart            # TC-018 ~ TC-022
│   └── navigation_methods_test.dart   # TC-023 ~ TC-028, TC-031
├── widgets/
│   └── app_shell_test.dart            # TC-012 独立测试
└── helpers/
    ├── test_router.dart               # createTestRouter(), PlaceholderWidget
    └── auth_state_stub.dart           # 可注入的认证状态
```

---

## 十一、附录 B：路由守卫状态机

```
                    ┌──────────────────────┐
                    │     应用启动          │
                    │  initialLocation:     │
                    │     /login            │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │  认证状态检查         │
                    └──────┬──────┬───────┘
                           │      │
                    已登录  │      │  未登录
                           │      │
              ┌────────────▼──┐ ┌─▼──────────────────┐
              │ 在 /login?    │ │ 在 /login 或        │
              │ 或 /register? │ │ /register?          │
              └──┬────────┬───┘ └──┬─────────┬───────┘
                 │是      │否      │是       │否
                 │        │        │         │
            ┌────▼───┐ ┌──▼───┐ ┌──▼──┐ ┌───▼──────────┐
            │重定向到 │ │允许   │ │允许 │ │重定向到 /login│
            │/dashboard│ │访问   │ │访问 │ │(保存原始路径) │
            └─────────┘ └──────┘ └─────┘ └──────────────┘

所有状态: return null → 允许访问当前路由
          return <path> → 重定向到新路径
```

---

## 十二、后端风险点标记 🚨

| # | 风险点 | 描述 | 影响 |
|---|--------|------|------|
| **R1** | 应用启动时认证状态异步 | 启动时需异步检查 Token 有效性，期间路由已初始化。需确保 redirect 正确处理 "加载中" 状态 | 如果 "检查中" 状态被当作 "未登录"，可能导致已登录用户先被重定向到 /login，再跳回 /dashboard（视觉闪烁） |
| **R2** | Web URL 策略兼容性 | `--web-url-strategy=path` 需要服务器配置 URL 重写（SPA 回退）。后端已在 `kayak-backend` 中配置 SPA fallback | 如果后端 fallback 未正确配置，深层链接直接访问会返回后端 404 |
| **R3** | ShellRoute + 独立页面 | `/profile` 页面在 tasks.md 中是受保护页面但不在导航栏中。需决定是否也放入 ShellRoute 还是独立 GoRoute | 如果放入 ShellRoute 但不配置导航栏高亮，可能导致导航状态不一致 |

---

**文档状态**: ✅ 已完成  
**下一步**: 提交 sw-tom 进行测试用例审查  
**总用例数**: 32  
**文件路径**: `log/release_3/test/TASK-004_test_cases.md`
