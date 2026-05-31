# TASK-004 详细设计 — 路由系统 (go_router 17.2.3)

## 1. 概述

### 1.1 目标
基于 go_router 17.2.3 构建 Kayak 前端路由系统，实现：
- 声明式路由配置（公开路由 + 受保护路由）
- ShellRoute 应用外壳（AppShell 响应式导航）
- 认证守卫（redirect 逻辑，TODO 占位待 TASK-008 完成）
- 11 个占位页面
- flutter analyze 零警告

### 1.2 依赖关系

```
main.dart
    ↓
KayakApp (ConsumerWidget, MaterialApp.router)
    ↓
routerProvider (Provider<GoRouter>)  ─── 依赖 ───→  authProvider (TASK-008)
    ↓
GoRouter
├── 公开路由: /login, /register
├── ShellRoute: AppShell (响应式导航外壳)
│   ├── DashboardPage      (/dashboard)
│   ├── WorkbenchListPage  (/workbenches)
│   ├── WorkbenchDetailPage(/workbenches/:id)
│   ├── MethodListPage     (/methods)
│   ├── MethodEditPage     (/methods/:id/edit)
│   ├── ExperimentListPage (/experiments)
│   ├── ExperimentCreatePage(/experiments/new)
│   ├── ExperimentConsolePage(/experiments/:id)
│   ├── AnalysisPage       (/analysis)
│   └── SettingsPage       (/settings)
└── errorBuilder: 404 页面
```

### 1.3 技术选型

| 项 | 选择 | 版本 | 理由 |
|---|------|------|------|
| 路由框架 | go_router | 17.2.3 | 声明式路由、ShellRoute、支持深层链接 |
| 状态管理 | flutter_riverpod | 3.3.1 | 与现有架构一致，routerProvider 注入 |
| 响应式 | LayoutBuilder | — | 根据父容器宽度自适应，无需 MediaQuery |
| 认证守卫 | GoRouter redirect | — | 声明式重定向逻辑 |

---

## 2. 路由配置

### 2.1 路由表

| 路径 | 页面 | 认证 | ShellRoute | 参数 |
|------|------|:----:|:----------:|------|
| `/login` | LoginPage | ❌ | ❌ | — |
| `/register` | RegisterPage | ❌ | ❌ | — |
| `/dashboard` | DashboardPage | ✅ | ✅ | — |
| `/workbenches` | WorkbenchListPage | ✅ | ✅ | — |
| `/workbenches/:id` | WorkbenchDetailPage | ✅ | ✅ | `id` |
| `/methods` | MethodListPage | ✅ | ✅ | — |
| `/methods/:id/edit` | MethodEditPage | ✅ | ✅ | `id` |
| `/experiments` | ExperimentListPage | ✅ | ✅ | — |
| `/experiments/new` | ExperimentCreatePage | ✅ | ✅ | — |
| `/experiments/:id` | ExperimentConsolePage | ✅ | ✅ | `id` |
| `/analysis` | AnalysisPage | ✅ | ✅ | — |
| `/settings` | SettingsPage | ✅ | ✅ | — |

### 2.2 路由优先级

静态路由优先于参数化路由，关键点：
- `/experiments/new` 必须在 `/experiments/:id` **之前**注册
- `/methods/:id/edit` 是两级路径，go_router 自动匹配

```
GoRouter 路由顺序（按优先级）：
1. /login                (公开)
2. /register             (公开)
3. ShellRoute:
   3.1 /dashboard
   3.2 /workbenches
   3.3 /workbenches/:id
   3.4 /methods
   3.5 /methods/:id/edit
   3.6 /experiments
   3.7 /experiments/new   ← 放在 :id 之前
   3.8 /experiments/:id   ← new 不会被 :id 捕获
   3.9 /analysis
   3.10 /settings
```

### 2.3 初始路由

```dart
initialLocation: '/login'
```

未认证用户启动应用后首先看到登录页。已认证用户通过 redirect 守卫自动跳转到 `/dashboard`。

### 2.4 认证守卫（TODO）

当前使用 TODO 标记，等 TASK-008 完成认证 Provider 后实现：

```dart
redirect: (context, state) {
  // TODO: 从 authProvider 获取认证状态
  // final loggedIn = ref.read(authProvider).isLoggedIn;
  final loggedIn = false; // 临时占位
  final onLogin = state.matchedLocation == '/login';
  final onRegister = state.matchedLocation == '/register';

  // 未登录 + 非公开页面 → 去登录
  if (!loggedIn && !onLogin && !onRegister) return '/login';

  // 已登录 + 公开页面 → 去首页
  if (loggedIn && (onLogin || onRegister)) return '/dashboard';

  // 其他情况 → 不重定向
  return null;
}
```

### 2.5 Error Builder（404 页面）

```dart
errorBuilder: (context, state) {
  return const NotFoundPage();
}
```

---

## 3. AppShell 响应式导航

### 3.1 响应式断点

| 断点 | 宽度 | 导航组件 | 行为 |
|------|------|---------|------|
| 小屏 | < 600px | BottomNavigationBar | 底部固定导航栏 |
| 中屏 | 600-1200px | NavigationRail | 左侧可折叠（默认折叠） |
| 大屏 | > 1200px | NavigationRail | 左侧常驻展开 |

### 3.2 导航项

| 标签 | 图标 | 路径 | 顺序 |
|------|------|------|:---:|
| 首页 | Icons.dashboard | `/dashboard` | 1 |
| 工作台 | Icons.build | `/workbenches` | 2 |
| 方法 | Icons.science | `/methods` | 3 |
| 试验 | Icons.biotech | `/experiments` | 4 |
| 分析 | Icons.analytics | `/analysis` | 5 |
| 设置 | Icons.settings | `/settings` | 6 |

### 3.3 Widget 树

```
AppShell (ConsumerWidget)
└── LayoutBuilder
    ├── < 600px:  Scaffold
    │   ├── body: child (页面内容)
    │   └── bottomNavigationBar: BottomNavigationBar
    │       └── NavigationDestination × 6
    ├── 600-1200px: Row
    │   ├── NavigationRail (可折叠)
    │   │   └── NavigationRailDestination × 6
    │   └── Expanded(child: child)
    └── > 1200px: Row
        ├── NavigationRail (常驻展开)
        │   └── NavigationRailDestination × 6
        └── Expanded(child: child)
```

### 3.4 当前路由高亮

根据 `GoRouterState.of(context).matchedLocation` 确定当前激活的导航项。

---

## 4. 占位页面

11 个占位页面，每个继承 `ConsumerWidget`，使用 `Scaffold` + `Center` + `Text` 显示页面名称。

| 页面 | 文件路径 | 构造函数 |
|------|---------|----------|
| LoginPage | `lib/pages/auth/login_page.dart` | `const LoginPage()` |
| RegisterPage | `lib/pages/auth/register_page.dart` | `const RegisterPage()` |
| DashboardPage | `lib/pages/dashboard/dashboard_page.dart` | `const DashboardPage()` |
| WorkbenchListPage | `lib/pages/workbench/workbench_list_page.dart` | `const WorkbenchListPage()` |
| WorkbenchDetailPage | `lib/pages/workbench/workbench_detail_page.dart` | `WorkbenchDetailPage({required String id})` |
| MethodListPage | `lib/pages/method/method_list_page.dart` | `const MethodListPage()` |
| MethodEditPage | `lib/pages/method/method_edit_page.dart` | `MethodEditPage({String? id})` |
| ExperimentListPage | `lib/pages/experiment/experiment_list_page.dart` | `const ExperimentListPage()` |
| ExperimentCreatePage | `lib/pages/experiment/experiment_create_page.dart` | `const ExperimentCreatePage()` |
| ExperimentConsolePage | `lib/pages/experiment/experiment_console_page.dart` | `ExperimentConsolePage({required String id})` |
| AnalysisPage | `lib/pages/analysis/analysis_page.dart` | `const AnalysisPage()` |
| SettingsPage | `lib/pages/settings/settings_page.dart` | `const SettingsPage()` |

---

## 5. app.dart 更新

将 `MaterialApp` 替换为 `MaterialApp.router`：

- `theme`: 使用 Material 3 + `ColorScheme.fromSeed`，`seedColor: Color(0xFF1976D2)`，浅色主题
- `darkTheme`: 使用 Material 3 + `ColorScheme.fromSeed`，`seedColor: Color(0xFF1976D2)`，深色主题
- `routerConfig`: 从 `routerProvider` 获取

---

## 6. 与测试用例的对照

| 测试用例 | 覆盖点 | 设计验证 |
|----------|--------|---------|
| TC-001 | 13 个路由正确注册 | 路由表包含全部 12 个（不含 /profile）+ errorBuilder |
| TC-002 | `:id` 参数正确解析 | WorkbenchDetailPage / ExperimentConsolePage / MethodEditPage 接收 id |
| TC-003 | 初始路由为 `/login` | `initialLocation: '/login'` |
| TC-004 | 静态 > 参数路由 | `/experiments/new` 在 `/experiments/:id` 之前 |
| TC-005~010 | 认证守卫 | redirect 逻辑，当前 TODO |
| TC-011~013 | ShellRoute + AppShell | ShellRoute 包裹 10 个子路由 |
| TC-014~017 | 响应式布局 | LayoutBuilder 三断点 |
| TC-018~020 | 深层链接 | pathParameters 正确传递 |
| TC-021 | 404 页面 | errorBuilder |
| TC-023~028 | 导航方法 | go_router 原生支持 |
| TC-029~032 | 边界测试 | go_router 内置保护 |

---

## 7. 实施计划

1. 创建详细设计文档 ✅（当前）
2. 创建占位页面文件（11 个 ConsumerWidget）
3. 创建 404 页面
4. 创建 `app_router.dart`（GoRouter 配置 + routerProvider）
5. 创建 `app_shell.dart`（AppShell 响应式导航）
6. 更新 `app.dart`（MaterialApp.router）
7. 运行 `flutter analyze` 验证零警告
8. 创建测试文件参考（可选）
9. 提交代码
