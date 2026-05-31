# Release 3 任务分解 — Kayak 前端全面重写

> **作者**: sw-jerry (Software Architect)
> **日期**: 2026-05-31
> **状态**: Final
> **Release**: 3 (前端从零重写)

---

## 版本原则（CRITICAL）

**这是从零开始的重写项目，所有依赖直接使用最新稳定版本，不考虑任何 "当前版本" 或 "升级路径"。**

| # | 依赖 | **必须使用版本** | pubspec 约束 | 说明 |
|---|------|----------------|-------------|------|
| 1 | `flutter_riverpod` | **3.3.1** | `^3.3.1` | 新 Notifier API，代码生成 |
| 2 | `riverpod_annotation` | **3.x** | `^3.0.0` | 配套注解 |
| 3 | `go_router` | **17.2.3** | `^17.2.3` | StatefulShellRoute |
| 4 | `dio` | **5.9.2** | `^5.9.2` | Duration API |
| 5 | `web_socket_channel` | **3.0.3** | `^3.0.3` | Web 原生支持 |
| 6 | `flutter_secure_storage` | **10.3.1** | `^10.3.1` | RSA+AES 新加密 |
| 7 | `shared_preferences` | **2.5.5** | `^2.5.5` | 新 Async API |
| 8 | `freezed` | **3.2.5** | `^3.2.5` | sealed class |
| 9 | `freezed_annotation` | **3.x** | `^3.0.0` | 配套注解 |
| 10 | `json_annotation` | **4.12.0** | `^4.12.0` | 最新 |
| 11 | `fl_chart` | **1.2.0** | `^1.2.0` | 1.x 稳定 API |
| 12 | `intl` | **0.20.2** | `^0.20.2` | 显式声明 |
| 13 | `flutter_localizations` | SDK | SDK | 随 Flutter 3.19+ |
| 14 | `build_runner` | dev | 最新 | 代码生成 |
| 15 | `json_serializable` | dev | 最新 | JSON 生成 |
| 16 | `riverpod_generator` | dev | 最新 | Provider 生成 |
| 17 | `flutter_test` | dev | SDK | 测试 |
| 18 | `mocktail` / `mockito` | dev | 最新 | Mock 测试 |

---

## 开发过程要求

每个任务必须走完整 TDD 流程：

```
1. 测试用例 → 2. UI 设计 → 3. 详细设计 → 4. 开发 → 5. 代码审查 → 6. 测试执行
```

每个任务完成后生成截图（关键状态的 Widget 测试截图）。

---

## Sprint 1: 基础设施（1 周，7 个任务）

> **必须先完成**：所有后续 Sprint 依赖 Sprint 1 的输出。

---

### TASK-001: 项目初始化与依赖配置

| 属性 | 内容 |
|------|------|
| **ID** | TASK-001 |
| **优先级** | P0 — 阻塞所有后续任务 |
| **依赖** | 无 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 1 |

**描述**：

从零创建 `kayak-frontend/` 项目，配置 pubspec.yaml 使用上述所有最新稳定版本依赖。

**交付物**：
1. `kayak-frontend/` 目录结构（按照架构设计 §4 的目录树创建）
2. `pubspec.yaml` — 所有依赖为最新稳定版本（见上表）
3. `pubspec.lock` — 锁定后的依赖树（`flutter pub get` 生成的）
4. `analysis_options.yaml` — 严格 lint 规则（继承 `flutter_lints` + 自定义规则）
5. `lib/main.dart` — 最小入口（`ProviderScope` + `KayakApp` 骨架）
6. `lib/app.dart` — 最小 `MaterialApp.router` 骨架
7. `.github/workflows/ci.yml` — CI 流水线更新（前端部分适配新依赖）
8. `flutter pub get` 无错误，`flutter analyze` 零警告

**TDD 流程**：

1. **测试用例**：无业务逻辑测试，但需验证 `flutter pub get` 成功、`flutter analyze` 零警告
2. **详细设计**：确认 pubspec.yaml 中每个依赖的准确版本号
3. **开发**：创建项目骨架 + pubspec.yaml
4. **代码审查**：验证版本号与风险评估报告一致
5. **测试执行**：`flutter pub get && flutter analyze --fatal-infos`

**验收标准**：
- `flutter pub get` 无错误
- `flutter analyze --fatal-infos` 零警告
- 目录结构匹配架构设计 §4
- 所有依赖版本严格按上表

---

### TASK-002: 数据模型定义（freezed 3.2.5 + json_annotation 4.12.0）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-002 |
| **优先级** | P0 — 阻塞所有业务逻辑 |
| **依赖** | TASK-001 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 1 |

**描述**：

使用 freezed 3.2.5 的 `sealed class` 语法定义所有数据模型，使用 json_annotation 4.12.0 生成 JSON 序列化。模型必须覆盖后端 API 返回的所有字段。

**freezed 3.x 语法要求**：
```dart
// ✅ v3 语法：sealed class
@freezed
sealed class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? username,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

**交付物**：

| 文件 | 模型 | 对应后端 |
|------|------|----------|
| `lib/models/user.dart` | User | `GET /auth/me`, `GET /users/me` |
| `lib/models/workbench.dart` | Workbench | `GET /workbenches` |
| `lib/models/device.dart` | Device | `GET /devices/{id}` |
| `lib/models/point.dart` | Point, PointValue | `GET /points/{id}`, `GET /points/{id}/value` |
| `lib/models/method.dart` | Method | `GET /methods` |
| `lib/models/experiment.dart` | Experiment, ExperimentStatus, ExperimentMessage | `GET /experiments`, WS |
| `lib/models/team.dart` | Team | `GET /teams` (虽然 P2 排除，但模型保留) |
| `lib/models/common.dart` | ApiResponse\<T\>, PaginatedResponse\<T\>, AuthTokens | 统一响应格式 |
| `lib/models/protocol.dart` | ProtocolConfig (Virtual/ModbusTCP/ModbusRTU) | 设备协议配置 |

**要求**：
- 每个 `.dart` 源文件对应 `.freezed.dart` + `.g.dart` 生成文件
- `build_runner` 生成无错误
- 字段类型与后端 API 响应完全对齐（阅读后端代码确认）
- 使用 `@JsonKey` 处理 snake_case → camelCase 映射
- 所有日期字段使用 `DateTime` 类型
- 枚举类型使用 `enum` + `@JsonEnum`

**TDD 流程**：
1. **测试用例**：每个模型的 `fromJson` / `toJson` 验证（正常数据、缺失字段、类型错误）
2. **详细设计**：对照后端 API 响应格式，画出每个模型的字段映射表
3. **开发**：编写所有模型文件 + 运行 `build_runner build`
4. **代码审查**：验证字段对齐、JSON 映射正确
5. **测试执行**：全部 fromJson/toJson 测试通过

**验收标准**：
- `build_runner build` 无错误
- 所有模型 fromJson/toJson 单元测试通过
- 覆盖边界情况（null 字段、空列表、错误类型）
- `flutter analyze` 零警告

---

### TASK-003: API Client + Dio 配置（dio 5.9.2）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-003 |
| **优先级** | P0 — 阻塞所有 Service |
| **依赖** | TASK-002 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 1 |

**描述**：

基于 dio 5.9.2 构建 `ApiClient`，实现 Token 自动附加、401 自动刷新、统一错误处理。

**dio 5.9.2 API 要求**：
- 使用 `Duration` 类型的 timeout 参数（非 int）
- 使用 `DioException` 类型（非旧 `DioError`）
- 拦截器签名为新版 API

**交付物**：

1. **`lib/services/api_client.dart`** — Dio 实例 + BaseOptions
   ```dart
   BaseOptions(
     baseUrl: 'http://localhost:8080',
     connectTimeout: Duration(seconds: 10),
     receiveTimeout: Duration(seconds: 30),
     headers: {'Content-Type': 'application/json'},
   )
   ```

2. **`lib/services/auth_interceptor.dart`** — AuthInterceptor
   - `onRequest`: 自动附加 `Authorization: Bearer <token>`
   - `onError`: 检测 401 → 尝试 Refresh Token → 成功则重试原请求 → 失败则登出
   - Token 从 `flutter_secure_storage` 10.3.1 读取

3. **`lib/services/error_interceptor.dart`** — ErrorInterceptor
   - 将 `DioException` 映射为用户可读错误消息
   - 覆盖：400/401/403/404/409/422/500 + 网络错误
   - 错误消息写入 `l10n` ARB 文件（本任务先硬编码英文 + 中文，TASK-006 后迁移）

4. **`lib/utils/error_handler.dart`** — 错误码 → 用户消息映射表

5. **`lib/services/auth_service.dart`** — AuthService（Token 读写 + API 调用）
   - `login(email, password)` → AuthTokens
   - `register(email, password, username?)` → AuthTokens
   - `refresh()` → AuthTokens
   - `logout()` → void
   - `getMe()` → User
   - Token 存储使用 flutter_secure_storage 10.3.1

**TDD 流程**：
1. **测试用例**：
   - AuthInterceptor 正确附加 Token（mock storage）
   - AuthInterceptor 401 时刷新成功重试
   - AuthInterceptor 刷新失败时触发登出
   - ErrorInterceptor 各状态码映射正确
   - AuthService login/register/refresh 正常和异常流程
2. **详细设计**：拦截器流程图、Token 刷新流程图
3. **开发**：实现 ApiClient + 拦截器 + AuthService
4. **代码审查**：验证拦截器逻辑正确、Token 安全
5. **测试执行**：所有单元测试通过

**验收标准**：
- AuthInterceptor 单元测试：Token 附加 ✅、401 刷新 ✅、刷新失败登出 ✅
- ErrorInterceptor 单元测试：所有 HTTP 状态码映射正确
- AuthService 单元测试：login/register/refresh/logout 正常流程通过
- 无硬编码字符串（最终将迁移到 l10n）

---

### TASK-004: 路由系统（go_router 17.2.3）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-004 |
| **优先级** | P0 — 阻塞所有页面 |
| **依赖** | TASK-003 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 1 |

**描述**：

使用 go_router 17.2.3 构建声明式路由，实现认证守卫、深层链接、ShellRoute 导航框架。

**go_router 17.x API 要点**：
- 使用类型安全的 `TypedGoRoute` 或在 `GoRoute` 中使用 path 参数
- `StatefulShellRoute` 用于底部导航栏/侧边栏的嵌套路由
- `redirect` 守卫实现认证检查

**交付物**：

1. **`lib/router/app_router.dart`** — GoRouter 配置 + 路由守卫
   - 公开路由：`/login`, `/register`
   - 受保护路由（需认证）：`/`, `/profile`, `/settings`, `/workbenches`, `/workbenches/:id`, `/methods`, `/methods/:id/edit`, `/experiments`, `/experiments/new`, `/experiments/:id`, `/analysis`
   - `redirect`: 未认证 → `/login`；已认证在 `/login` → `/`
   - 登录后返回原目标页面（保存 `state.matchedLocation`）

2. **`lib/widgets/app_shell.dart`** — 应用外壳
   - 大屏 (>1200px): NavigationRail 左侧常驻
   - 中屏 (600-1200px): NavigationRail 可折叠
   - 小屏 (<600px): BottomNavigationBar 底部
   - 响应式使用 `LayoutBuilder`，不引入第三方库

**路由表（来自 PRD 附录 A）**：

| 路径 | 页面 | 认证 | 导航标签 |
|------|------|:---:|----------|
| `/login` | LoginPage | ❌ | — |
| `/register` | RegisterPage | ❌ | — |
| `/` | DashboardPage | ✅ | 首页 |
| `/profile` | ProfilePage | ✅ | — |
| `/settings` | SettingsPage | ✅ | 设置 |
| `/workbenches` | WorkbenchListPage | ✅ | 工作台 |
| `/workbenches/:id` | WorkbenchDetailPage | ✅ | — |
| `/methods` | MethodListPage | ✅ | 方法 |
| `/methods/:id/edit` | MethodEditPage | ✅ | — |
| `/experiments` | ExperimentListPage | ✅ | 试验 |
| `/experiments/new` | ExperimentCreatePage | ✅ | — |
| `/experiments/:id` | ExperimentConsolePage | ✅ | — |
| `/analysis` | AnalysisPage | ✅ | 分析 |

**TDD 流程**：
1. **测试用例**：
   - 未登录访问 `/workbenches` → 重定向 `/login`
   - 已登录访问 `/login` → 重定向 `/`
   - 登录后返回原始目标页面
   - ShellRoute 在所有设备宽度下正确渲染 AppShell
2. **详细设计**：路由跳转流程图
3. **开发**：实现 GoRouter + AppShell + 占位页面
4. **代码审查**：验证路由逻辑完整
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 认证守卫正确重定向
- 所有路由可访问（占位页面）
- AppShell 在三种宽度下正确渲染
- `flutter analyze` 零警告

---

### TASK-005: 主题系统（Material 3）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-005 |
| **优先级** | P0 — 阻塞所有页面的视觉一致性 |
| **依赖** | TASK-001 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 1 |

**描述**：

构建 Material 3 主题系统，支持浅色/深色/跟随系统三种模式。

**规格**：
- 主色：`#1976D2`（科技蓝）
- Material 3 `ColorScheme.fromSeed` 生成完整调色板
- 等宽字体：用于代码/日志区域
- ThemeNotifier 使用 `NotifierProvider` 管理（纯同步操作）

**交付物**：

1. **`lib/theme/colors.dart`** — 自定义颜色常量
2. **`lib/theme/typography.dart`** — 文字样式（等宽字体配置）
3. **`lib/theme/app_theme.dart`** — `lightTheme()` + `darkTheme()` + `ThemeData`
   - 使用 `ColorScheme.fromSeed(seedColor: Color(0xFF1976D2), brightness: ...)`
   - 按钮样式、输入框样式、卡片样式统一定义
   - AppBar、NavigationRail、BottomNavigationBar 主题

4. **`lib/providers/settings_provider.dart`** — ThemeNotifier + LocaleNotifier（同一文件）
   ```dart
   // Riverpod 3.x: 纯同步 Notifier
   class ThemeNotifier extends Notifier<ThemeMode> {
     ThemeMode build() => ThemeMode.system; // 默认跟随系统
     void setTheme(ThemeMode mode) { ... } // 持久化到 shared_preferences 2.5.5
   }
   ```

**TDD 流程**：
1. **测试用例**：
   - ThemeNotifier build() 默认返回 system
   - setTheme() 更新状态并持久化
   - lightTheme 和 darkTheme 的 primaryColor 均为 #1976D2
2. **详细设计**：色板色阶展示、组件主题规范
3. **开发**：实现 colors + typography + app_theme + ThemeNotifier
4. **代码审查**：验证颜色一致性
5. **测试执行**：单元测试通过 + 各页面截图验证

**验收标准**：
- 浅色/深色/跟随系统三模式切换
- 切换即时生效
- 所有 Material 3 组件使用统一色板
- 持久化到 shared_preferences

---

### TASK-006: 国际化框架（ARB + intl 0.20.2）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-006 |
| **优先级** | P0 — 所有面向用户的文本必须通过 l10n |
| **依赖** | TASK-005 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 1 |

**描述**：

使用 Flutter 官方 `flutter_localizations` + `intl` 0.20.2 构建国际化框架。默认语言为 English (`en`)，支持简体中文 (`zh`)。语言切换立即生效并持久化。

**关键约束**：TASK-005 中的 ThemeNotifier 已定义在 `settings_provider.dart` 中，本任务的 LocaleNotifier 应放在同一个文件。

**交付物**：

1. **`lib/l10n/app_en.arb`** — 英文翻译（默认/回退语言）
   - 涵盖所有接下来的 UI 任务需要的文本 key
   - 至少包含：通用操作（保存/取消/删除/确认）、错误消息、导航标签、表单标签

2. **`lib/l10n/app_zh.arb`** — 简体中文翻译
   - 与 en 的所有 key 一一对应

3. **`lib/l10n/app_localizations.dart`** — 生成文件（`flutter gen-l10n` 自动生成）

4. **`lib/providers/settings_provider.dart`** — 添加 LocaleNotifier
   ```dart
   // Riverpod 3.x 纯同步 Notifier
   class LocaleNotifier extends Notifier<Locale> {
     Locale build() => const Locale('en'); // 默认英文
     void setLocale(Locale locale) { ... }
   }
   ```
   - 持久化到 `shared_preferences` 2.5.5
   - 切换后整个应用即时更新

5. **`lib/app.dart`** — 接入 `MaterialApp.router` 的 `localizationsDelegates` 和 `supportedLocales`

**ARB 消息覆盖范围**（至少包含）：
- 通用：保存、取消、删除、确认、关闭、重试、加载中、暂无数据、网络错误
- 导航：首页、工作台、方法、试验、分析、设置、登录、注册
- 认证：邮箱、密码、用户名、登录、注册、登出、会话过期
- 工作台：创建工作台、编辑工作台、删除工作台、搜索工作台
- 设备：添加设备、编辑设备、删除设备、测试连接、连接、断开
- 测点：添加测点、编辑测点、删除测点、测点值
- 试验：创建试验、载入、开始、暂停、继续、停止、执行日志
- 错误：网络连接失败、登录过期、权限不足、服务器错误

**TDD 流程**：
1. **测试用例**：
   - LocaleNotifier build() 默认 en
   - setLocale('zh') 更新并持久化
   - en ARB 的所有 key 在 zh ARB 中有对应
   - 回退到 en 当 key 缺失时
2. **详细设计**：ARB key 命名规范、翻译覆盖率检查清单
3. **开发**：编写 ARB 文件 + 运行 `flutter gen-l10n` + LocaleNotifier
4. **代码审查**：验证 en/zh 翻译质量、无遗漏 key
5. **测试执行**：Widget 测试验证中英文切换

**验收标准**：
- `flutter gen-l10n` 无错误
- en 和 zh 所有 key 一一对应
- 语言切换即时生效
- 持久化到 shared_preferences
- 回退语言为 en

---

### TASK-007: 可复用组件库

| 属性 | 内容 |
|------|------|
| **ID** | TASK-007 |
| **优先级** | P0 — 被所有页面使用 |
| **依赖** | TASK-006 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 1 |

**描述**：

构建项目级可复用组件，所有组件必须支持三态（Loading / Data+Empty / Error）并适配多语言。

**交付物**：

1. **`lib/widgets/async_value_widget.dart`** — 统一三态 Widget
   ```dart
   // 消费 AsyncValue<T>，自动切换 loading/error/data 状态
   class AsyncValueWidget<T> extends StatelessWidget {
     final AsyncValue<T> value;
     final Widget Function(T data) data;
     final Widget Function()? loading;
     final Widget Function(Object error, StackTrace? stack)? error;
     final Widget Function()? empty; // data 为空列表时
   }
   ```

2. **`lib/widgets/error_view.dart`** — 错误状态组件
   - 错误图标 + 用户可读错误消息
   - "重试"按钮（调用 onRetry 回调）
   - 不暴露技术细节

3. **`lib/widgets/empty_view.dart`** — 空状态组件
   - 居中图标 + 提示文字
   - 可选的操作按钮（如"创建第一个工作台"）
   - 使用 l10n 文本

4. **`lib/widgets/skeleton.dart`** — 骨架屏组件
   - `SkeletonCard` — 卡片骨架（带标题、描述行占位）
   - `SkeletonList` — 列表骨架（多行骨架卡）
   - `SkeletonTable` — 表格骨架（带行占位）
   - 使用 shimmer 动画或简单渐变动画

5. **`lib/widgets/confirm_dialog.dart`** — 确认对话框
   - 标题 + 描述消息 + 取消/确认按钮
   - 确认按钮支持 danger 样式（红色，用于删除操作）
   - 使用 l10n 文本

6. **`lib/widgets/toast.dart`** — Toast/SnackBar 工具
   - `showSuccess(message)`
   - `showError(message)`
   - `showInfo(message)`
   - 自动消失（3-5 秒）

**TDD 流程**：
1. **测试用例**：
   - AsyncValueWidget loading/error/data/empty 各状态
   - ConfirmDialog 显示和按钮回调
   - Skeleton 组件渲染尺寸正确
   - Toast 显示并自动消失
2. **详细设计**：每个组件的 API 接口
3. **开发**：实现所有组件
4. **代码审查**：验证三态完整、多语言覆盖
5. **测试执行**：Widget 测试 + 各状态截图

**验收标准**：
- 所有组件在 loading/error/data/empty 状态下正确渲染
- 所有文本通过 l10n 获取（无硬编码）
- 骨架屏与目标内容尺寸一致
- Widget 测试覆盖所有状态
- 截图：每组件每种状态至少 1 张

---

## Sprint 2: M1 认证与身份管理（1 周，4 个任务）

> **依赖 Sprint 1 全部完成**

---

### TASK-008: 认证 Service + Provider（完善）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-008 |
| **优先级** | P0 |
| **依赖** | TASK-003, TASK-006 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 2 |

**描述**：

在 TASK-003 中已创建基础 `AuthService`。本任务完善认证状态管理，包括会话持久化、Token 自动刷新、应用启动流程。

**交付物**：

1. **`lib/providers/auth_provider.dart`** — 认证 Provider（Riverpod 3.x AsyncNotifier）
   ```dart
   // 管理全局认证状态
   class AuthNotifier extends AsyncNotifier<User?> {
     Future<User?> build() => _checkAuth(); // 启动时检查 Token
     Future<void> login(String email, String password);
     Future<void> register(String email, String password, String? username);
     Future<void> refresh();
     Future<void> logout();
   }
   ```

2. **应用启动流程** — 编辑 `main.dart` / `app.dart`
   - 显示 Kayak Logo + "正在初始化..." 全屏加载
   - 检查本地 Token → 有效则获取用户信息 → 进入首页
   - Token 无效 → 跳转登录页
   - 加载超过 3 秒显示"正在连接服务器..."
   - 加载超过 10 秒显示"服务器连接超时" + 重试按钮

3. **Token 自动刷新机制**
   - Access Token 过期前 5 分钟自动刷新
   - 使用 `Timer.periodic` 在 AuthNotifier 中管理
   - Refresh Token 也过期 → 清除 Token → 重定向登录 → Toast "会话已过期"

4. **登出清理**
   - 清除 `flutter_secure_storage` 中所有 Token
   - 清除 `shared_preferences` 中登录相关缓存（如有）
   - 导航到 `/login`

**TDD 流程**：
1. **测试用例**：
   - 启动时 Token 有效 → 返回 User
   - Token 无效 → 返回 null → 触发路由重定向
   - login 成功 → 存储 Token → 返回 User
   - login 失败 → 抛出异常（含友好错误消息）
   - refresh 定时器正确触发
2. **详细设计**：认证状态机图、Token 刷新时序图
3. **开发**：实现 AuthNotifier + 启动流程 + 定时刷新
4. **代码审查**：验证 Token 安全、状态完整
5. **测试执行**：单元测试 + Widget 测试（启动流程）

**验收标准**：
- 登录后关闭浏览器重开 → 自动恢复登录状态
- Token 过期前自动刷新
- 刷新也过期 → 友好提示 + 重定向登录
- 登出清除所有本地数据

---

### TASK-009: 登录页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-009 |
| **优先级** | P0 |
| **依赖** | TASK-004, TASK-007, TASK-008 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 2 |

**描述**：

实现登录页面 UI。路由 `/login`。

**参考 PRD §M1 验收标准**。

**交付物**：

1. **`lib/pages/auth/login_page.dart`** — 登录页面
   - 邮箱输入框（带 label + 输入验证）
   - 密码输入框（带 label + 显示/隐藏切换）
   - "登录"按钮：
     - 邮箱或密码为空时视觉禁用
     - 点击后显示 loading 状态 + 输入框禁用
     - 登录失败：显示友好错误（"该邮箱尚未注册"/"密码错误"/"网络连接失败"）
   - "还没有账号？注册"链接 → `/register`
   - Kayak Logo + 应用名称
   - 居中卡片布局，响应式适配

2. **`lib/pages/auth/auth_widgets.dart`** — 认证模块共享组件
   - 密码输入框（带显示/隐藏切换）
   - 邮箱输入框（带格式验证）
   - 密码强度指示器（用于注册页）
   - 表单按钮（支持 loading 状态）

**TDD 流程**：
1. **测试用例**：
   - 空邮箱/密码时登录按钮禁用
   - 输入无效邮箱格式 → 验证提示
   - 输入有效凭据 → 导航到首页
   - 登录失败显示对应错误消息
   - "注册"链接跳转 `/register`
2. **详细设计**：页面布局草稿、错误消息映射表
3. **开发**：实现 LoginPage + 共享组件
4. **代码审查**：验证三态完整、错误消息友好
5. **测试执行**：Widget 测试 + 截图

**验收标准**（与 PRD M1 对齐）：
- 邮箱、密码为空时按钮禁用
- 登录失败显示具体原因（非技术错误）
- 登录成功后跳转首页
- 受保护页面重定向 → 登录后返回原页面
- 按钮 loading 状态下输入框禁用
- 截图：登录页（初始、loading、错误状态）

---

### TASK-010: 注册页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-010 |
| **优先级** | P0 |
| **依赖** | TASK-009 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 2 |

**描述**：

实现注册页面 UI。路由 `/register`。

**参考 PRD §M1 验收标准**。

**交付物**：

1. **`lib/pages/auth/register_page.dart`** — 注册页面
   - 邮箱输入框（必填，复用 TASK-009 共享组件）
   - 密码输入框（必填，带密码强度指示器）
     - 弱（红色）：长度 < 8 或纯数字/字母
     - 中（橙色）：长度 ≥ 8 + 包含两种字符类型
     - 强（绿色）：长度 ≥ 8 + 包含三种以上字符类型
   - 用户名输入框（选填）
   - "注册"按钮：
     - 邮箱或密码为空时禁用
     - 点击后 loading 状态
   - 注册失败：显示具体原因（"该邮箱已注册"/"密码太短"）
   - 注册成功：Toast "注册成功" → 自动登录 → 跳转首页
   - "已有账号？登录"链接 → `/login`

**TDD 流程**：
1. **测试用例**：
   - 密码强度指示器各状态渲染
   - 空必填字段时按钮禁用
   - 注册成功 → 自动登录 → 跳转首页
   - 注册失败显示错误消息
   - "登录"链接跳转 `/login`
2. **详细设计**：密码强度算法、表单验证规则
3. **开发**：实现 RegisterPage
4. **代码审查**：验证表单验证逻辑、错误处理
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 密码强度实时提示
- 注册成功自动登录
- 注册失败显示具体原因
- 截图：注册页（初始、密码强度各状态、loading、错误状态）

---

### TASK-011: 个人资料页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-011 |
| **优先级** | P1（P0 任务的一部分） |
| **依赖** | TASK-009 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 2 |

**描述**：

实现个人资料页面 UI。路由 `/profile`。

**交付物**：

1. **`lib/pages/profile/profile_page.dart`** — 个人资料页
   - 显示当前用户信息：用户名、邮箱、注册时间
   - 编辑用户名：内联编辑或弹出对话框，调用 `PUT /users/me`
   - 修改密码：
     - 旧密码 + 新密码 + 确认新密码
     - 调用 `POST /users/me/password`
     - 成功 Toast "密码修改成功"
     - 失败显示具体原因
   - Loading/Error 状态处理

2. **`lib/services/user_service.dart`** — UserService
   - `getMe()` → User
   - `updateProfile(username)` → User
   - `changePassword(old, new)` → void

3. **`lib/providers/user_provider.dart`** — UserNotifier（或集成到 auth_provider）

**TDD 流程**：
1. **测试用例**：
   - 加载用户信息成功
   - 更新用户名成功
   - 修改密码成功/失败
   - 新密码与确认密码不一致 → 验证提示
2. **详细设计**：密码修改流程图
3. **开发**：实现 ProfilePage + UserService
4. **代码审查**：验证表单验证、安全
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 正确显示用户信息
- 用户名可编辑
- 密码修改有二次确认
- 截图：个人资料页（loading、loaded、编辑状态）

---

## Sprint 3: M4 工作台管理（1 周，3 个任务）

> **依赖 Sprint 2 完成（需要认证状态）**

---

### TASK-012: 工作台 Service + Provider

| 属性 | 内容 |
|------|------|
| **ID** | TASK-012 |
| **优先级** | P0 |
| **依赖** | TASK-003, TASK-008 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 3 |

**描述**：

实现工作台相关的 Service 和 State 管理。

**交付物**：

1. **`lib/services/workbench_service.dart`** — WorkbenchService
   - `list({page, pageSize, search})` → PaginatedResponse\<Workbench\>
   - `getById(id)` → Workbench
   - `create(name, description, ownerType?)` → Workbench
   - `update(id, name, description)` → Workbench
   - `delete(id)` → void

2. **`lib/providers/workbench_provider.dart`** — WorkbenchNotifier（Riverpod 3.x AsyncNotifier）
   - `WorkbenchListNotifier`：管理列表（加载、刷新、搜索、分页）
   - `WorkbenchDetailNotifier`：管理单个工作台详情（基于 id 参数）
   - Provider 通过 `ref.watch` 通信

**Provider 设计**：
```dart
// 列表 Provider
final workbenchListProvider = AsyncNotifierProvider<WorkbenchListNotifier, List<Workbench>>(
  WorkbenchListNotifier.new,
);

// 详情 Provider（family，按 id）
final workbenchDetailProvider = AsyncNotifierProvider.family<WorkbenchDetailNotifier, Workbench, String>(
  WorkbenchDetailNotifier.new,
);
```

**TDD 流程**：
1. **测试用例**：
   - 列表加载成功（正常数据、空数据、分页）
   - 创建成功 → 刷新列表
   - 更新成功 → 列表/详情同步更新
   - 删除成功 → 列表移除 + 确认对话框
   - 网络错误 → state.error
2. **详细设计**：Provider 依赖图、数据流图
3. **开发**：实现 WorkbenchService + Providers
4. **代码审查**：验证单一数据源、状态管理正确
5. **测试执行**：单元测试全部通过

**验收标准**：
- CRUD 全部流程走通（mock backend）
- 搜索和分页参数正确传递
- 创建/更新/删除后自动刷新列表
- 错误状态正确传播

---

### TASK-013: 工作台列表页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-013 |
| **优先级** | P0 |
| **依赖** | TASK-007, TASK-012 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 3 |

**描述**：

实现工作台列表页面 UI。路由 `/workbenches`。

**参考 PRD §M4 验收标准**。

**交付物**：

1. **`lib/pages/workbench/workbench_list_page.dart`** — 工作台列表页
   - 卡片网格布局（GridView）
   - 每张卡片：名称、描述摘要（2 行省略）、状态标签、创建时间（相对时间 + hover 精确时间）
   - 顶部搜索框：按名称实时过滤（调用后端参数）
   - 右上角"+ 新建工作台"按钮
   - 分页：底部"共 N 个工作台"，加载更多

2. **空状态**（首次使用）：
   - 居中插画 + "您还没有工作台"
   - 大按钮"创建第一个工作台"

3. **创建工作台对话框** — `lib/pages/workbench/workbench_create_dialog.dart`
   - 名称（必填，最长 255）
   - 描述（选填，多行）
   - 创建成功 → 关闭 → 刷新列表 → 新卡片高亮

4. **编辑工作台对话框** — 复用创建对话框，预填现有值

5. **删除确认** — 二次确认："确定要删除工作台「XXX」吗？..."
   - 使用 TASK-007 的 ConfirmDialog

**三态要求**：
- Loading：SkeletonCard 骨架屏（卡片占位）
- Error：ErrorView + "重新加载"按钮
- Empty：空状态引导
- Data：卡片网格

**TDD 流程**：
1. **测试用例**：
   - 加载中显示骨架屏（N 个卡片占位）
   - 有数据时显示卡片列表
   - 空数据时显示引导
   - 搜索过滤
   - 删除确认对话框
   - 创建成功刷新列表
2. **详细设计**：页面布局草稿（桌面/平板/手机）
3. **开发**：实现列表页 + 对话框 + 响应式布局
4. **代码审查**：验证三态完整、交互反馈
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 三态完整（loading/error/empty/data）
- 搜索实时过滤
- 分页正常工作
- 删除有二次确认
- 操作有反馈（Toast）
- 截图：列表（加载中、有数据、空数据、错误）、创建对话框、删除确认

---

### TASK-014: 工作台详情页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-014 |
| **优先级** | P0 |
| **依赖** | TASK-013 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 3 |

**描述**：

实现工作台详情页 UI。路由 `/workbenches/:id`。设备树区域先放占位（Sprint 4 实现）。

**参考 PRD §M4 验收标准（工作台详情页）**。

**交付物**：

1. **`lib/pages/workbench/workbench_detail_page.dart`** — 工作台详情页
   - 顶部信息区：工作台名称、描述、状态、创建时间
   - 右上角操作按钮：编辑、删除
   - 左侧：设备树占位区域（`Placeholder` + "设备树将在下一个 Sprint 实现"）
   - 右侧：设备详情面板占位
   - 响应式：大屏左右分栏，小屏上下堆叠

2. **编辑对话框** — 复用 TASK-013 的编辑对话框
3. **删除操作** — 二次确认 → 删除 → 返回列表

**三态要求**：
- Loading：骨架屏（信息区 + 设备树区）
- Error：ErrorView
- Data：信息区 + 占位区

**TDD 流程**：
1. **测试用例**：
   - 加载工作台详情
   - 编辑工作台名称/描述
   - 删除工作台 → 返回列表
   - 不存在的 id → 错误处理
2. **详细设计**：详情页布局草稿
3. **开发**：实现详情页
4. **代码审查**：验证布局适配
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 显示工作台完整信息
- 编辑/删除操作可用
- 设备树占位区存在
- 响应式布局
- 截图：详情页（loading、loaded、编辑对话框）

---

## Sprint 4: M5 设备管理 + M6 测点管理（1 周，5 个任务）

> **依赖 Sprint 3 完成（需要工作台详情页框架）**

---

### TASK-015: 设备 Service + Provider

| 属性 | 内容 |
|------|------|
| **ID** | TASK-015 |
| **优先级** | P0 |
| **依赖** | TASK-003, TASK-014 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 4 |

**描述**：

实现设备相关的 Service 和 State 管理。

**交付物**：

1. **`lib/services/device_service.dart`** — DeviceService
   - `listByWorkbench(wbId)` → List\<Device\>
   - `getById(id)` → Device
   - `create(wbId, name, parentId?, protocolConfig)` → Device
   - `update(id, name, protocolConfig)` → Device
   - `delete(id)` → void
   - `testConnection(id)` → ConnectionTestResult
   - `connect(id)` → void
   - `disconnect(id)` → void
   - `getStatus(id)` → DeviceStatus

2. **`lib/providers/device_provider.dart`** — DeviceNotifier
   - `DeviceTreeNotifier`：管理设备树（嵌套结构）
   - `DeviceDetailNotifier`：管理单个设备详情
   - 支持树节点的展开/折叠状态（UI 层本地状态，非业务缓存）

3. **`lib/models/protocol.dart`** — 协议配置模型
   - `VirtualConfig`（mode, dataType, min, max, interval）
   - `ModbusTcpConfig`（host, port, slaveId, timeout）
   - `ModbusRtuConfig`（serialPort, baudRate, dataBits, stopBits, parity, slaveId, timeout）
   - 使用 freezed 3.2.5 sealed union

**TDD 流程**：
1. **测试用例**：
   - 设备列表加载
   - 设备创建（三种协议）
   - 设备编辑、删除
   - 测试连接成功/失败
   - 连接/断开状态变更
2. **详细设计**：设备树数据结构、Provider 依赖图
3. **开发**：实现 DeviceService + Providers + ProtocolConfig
4. **代码审查**：验证协议配置序列化
5. **测试执行**：单元测试全部通过

**验收标准**：
- 三种协议配置可正确创建和序列化
- 测试连接返回正确状态
- 设备树构建正确（平铺列表 → 树结构）
- 所有 CRUD 操作正常

---

### TASK-016: 设备树组件 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-016 |
| **优先级** | P0 |
| **依赖** | TASK-015 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 4 |

**描述**：

实现设备树UI组件，替换 TASK-014 工作台详情页中的占位区域。

**参考 PRD §M5 验收标准（设备树）**。

**交付物**：

1. **`lib/widgets/device_tree.dart`** — 设备树组件（可复用，但先集成到工作台详情页）
   - 树形结构展示（使用 `TreeView` 或基于 `ExpansionTile` 构建）
   - 每个节点：设备名称 + 状态圆点（🟢在线/⚫离线/🔴错误）+ 协议类型图标
   - 点击节点 → 选中 → 右侧面板显示设备详情（emit 回调）
   - 展开/折叠箭头
   - 右键菜单或溢出菜单：编辑、添加子设备、删除
   - 空状态："该工作台下暂无设备" + "添加第一台设备"
   - "+ 添加设备"按钮

2. **修改 `lib/pages/workbench/workbench_detail_page.dart`**
   - 用 DeviceTree 替换占位区域
   - 右侧面板（暂用占位，TASK-017 实现设备详情 + TASK-019 实现测点列表）

3. **添加设备对话框** — `lib/pages/device/device_create_dialog.dart`
   - 名称（必填）
   - 父设备选择（可选，下拉框）
   - 协议类型选择（Virtual / Modbus TCP / Modbus RTU）
   - 协议配置动态表单（见 TASK-017）

**三态要求**：
- Loading：树骨架屏
- Error：错误 + 重试
- Empty：空状态引导
- Data：设备树

**TDD 流程**：
1. **测试用例**：
   - 空设备树显示引导
   - 有设备显示树结构（含层级）
   - 点击节点选中
   - 展开/折叠
   - 右键菜单操作
   - 状态圆点颜色正确
2. **详细设计**：树组件 API、点击事件流
3. **开发**：实现 DeviceTree + 修改详情页
4. **代码审查**：验证树构建正确、性能（虚拟滚动）
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 设备树正确展示嵌套关系
- 状态指示器实时反映后端数据
- 点击选中设备
- 右键菜单操作可用
- 空状态引导
- 截图：设备树（有设备、空状态、展开节点）

---

### TASK-017: 设备配置表单 UI（三种协议）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-017 |
| **优先级** | P0 |
| **依赖** | TASK-016 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 4 |

**描述**：

实现设备添加/编辑的协议配置动态表单，以及设备详情右侧面板。

**参考 PRD §M5 验收标准（添加设备、设备详情）**。

**交付物**：

1. **`lib/pages/device/device_config_form.dart`** — 协议配置动态表单
   - 根据协议类型动态显示配置字段

   **Virtual 协议**：
   - 虚拟模式下拉（Random/Fixed/Sine/Ramp）
   - 数据类型（Number/Integer）
   - 最小值、最大值
   - 更新间隔（毫秒）

   **Modbus TCP 协议**：
   - 主机地址（必填，IP/域名）
   - 端口号（默认 502）
   - 从站 ID（1-247）
   - 超时时间（毫秒，默认 3000）

   **Modbus RTU 协议**：
   - 串口选择（调用 `GET /system/serial-ports` 获取列表）
   - 波特率下拉（9600/19200/38400/57600/115200）
   - 数据位（7/8）
   - 停止位（1/2）
   - 校验位（None/Even/Odd）
   - 从站 ID（1-247）
   - 超时时间（毫秒，默认 3000）

2. **`lib/pages/device/device_detail_panel.dart`** — 设备详情右侧面板
   - 设备基本信息：名称、协议类型、状态
   - 协议配置摘要（只读）
   - 操作按钮组：测试连接、连接、断开连接
     - 按钮根据当前状态动态启用/禁用
     - 点击后有 loading 反馈
   - 测点管理区占位（TASK-019 实现）
   - 编辑/删除按钮

3. **`lib/services/protocol_service.dart`** — ProtocolService
   - `getProtocols()` → 支持的协议列表
   - `getSerialPorts()` → 可用串口列表

**TDD 流程**：
1. **测试用例**：
   - 选择 Virtual → 显示 Virtual 表单
   - 选择 Modbus TCP → 显示 TCP 表单
   - 各协议表单验证（必填字段、数值范围）
   - 测试连接按钮 → loading → 成功/失败 Toast
   - 连接/断开按钮状态切换
2. **详细设计**：三种协议表单字段映射、设备状态机
3. **开发**：实现配置表单 + 详情面板 + ProtocolService
4. **代码审查**：验证表单验证、状态管理
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 三种协议配置表单根据选择动态切换
- 表单验证正确（必填、范围）
- Modbus RTU 串口列表从后端加载
- 测试连接有 loading 反馈 + 结果 Toast
- 连接/断开按钮状态正确
- 截图：每种协议的配置表单、设备详情面板、测试连接结果

---

### TASK-018: 测点 Service + Provider

| 属性 | 内容 |
|------|------|
| **ID** | TASK-018 |
| **优先级** | P0 |
| **依赖** | TASK-015 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 4 |

**描述**：

实现测点相关的 Service 和 State 管理。

**交付物**：

1. **`lib/services/point_service.dart`** — PointService
   - `listByDevice(devId)` → List\<Point\>
   - `getById(id)` → Point
   - `create(devId, name, dataType, access, unit?, range?, description?, modbusConfig?)` → Point
   - `update(id, ...)` → Point
   - `delete(id)` → void
   - `getValue(id)` → PointValue
   - `setValue(id, value)` → void

2. **`lib/providers/point_provider.dart`** — PointListNotifier
   - 管理设备下的测点列表
   - 支持实时值刷新（可配置间隔）

**Modbus 测点额外字段**：
- 寄存器类型：Coil / Discrete Input / Holding Register / Input Register
- 起始地址（0-65535）
- 数据格式（uint16 / int16 / float32 等）

**TDD 流程**：
1. **测试用例**：
   - 测点列表加载
   - 测点创建（含 Modbus 字段）
   - 测点值读取
   - 测点值写入
   - 自动刷新
2. **详细设计**：测点配置数据结构
3. **开发**：实现 PointService + Provider
4. **代码审查**：验证 Modbus 字段序列化
5. **测试执行**：单元测试全部通过

**验收标准**：
- CRUD 全部流程走通
- Modbus 测点字段正确序列化
- 实时值读取和写入
- 错误状态正确

---

### TASK-019: 测点列表/配置 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-019 |
| **优先级** | P0 |
| **依赖** | TASK-017, TASK-018 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 4 |

**描述**：

实现设备详情面板中的测点列表和配置 UI。

**参考 PRD §M6 验收标准**。

**交付物**：

1. **`lib/pages/point/point_list_widget.dart`** — 测点列表（嵌入设备详情面板）
   - 表格形式：名称 / 类型 / 访问权限 / 单位 / 当前值 / 操作
   - 当前值列：显示实时数值（带单位），使用 `GET /points/{id}/value`
   - 空状态："该设备下暂无测点" + "添加第一个测点"
   - 顶部"共 N 个测点" + "+ 添加测点"
   - 操作列：编辑、删除按钮

2. **`lib/pages/point/point_form_dialog.dart`** — 添加/编辑测点对话框
   - 名称（必填，最长 255）
   - 数据类型（Number/Integer/Boolean/String）
   - 访问权限（RO/WO/RW）
   - 单位（选填）
   - 取值范围（选填：最小值、最大值）
   - 描述（选填）
   - Modbus 设备额外显示：
     - 寄存器类型下拉
     - 起始地址
     - 数据格式下拉

3. **修改 `lib/pages/device/device_detail_panel.dart`** — 集成测点列表
   - 替换测点管理区占位为实际 PointListWidget

4. **`lib/pages/point/point_value_display.dart`** — 测点值显示组件
   - 实时值 + 单位
   - 状态指示：正常（灰）/ 超时（橙）/ 异常（红）
   - 手动"刷新"按钮

**TDD 流程**：
1. **测试用例**：
   - 测点列表加载（有数据、空数据、错误）
   - 添加测点（普通 + Modbus）
   - 编辑测点
   - 删除测点二次确认
   - 实时值显示和刷新
2. **详细设计**：测点配置表单字段映射
3. **开发**：实现列表 + 表单 + 集成到设备面板
4. **代码审查**：验证 Modbus 字段、响应式表格
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 表格正确显示所有测点
- 实时值带单位显示
- Modbus 测点有额外配置字段
- 添加/编辑/删除操作可用
- 小屏表格转卡片列表
- 截图：测点列表（各种状态）、添加对话框、Modbus 配置

---

## Sprint 5: M8 试验执行控制台（1 周，4 个任务）

> **依赖 Sprint 4 完成（需要设备/测点数据）**

---

### TASK-020: 试验 Service + Provider（含 WebSocket）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-020 |
| **优先级** | P0 |
| **依赖** | TASK-003, TASK-012 |
| **预计工期** | 2 天 |
| **Sprint** | Sprint 5 |

**描述**：

实现试验相关的 Service、State 管理和 WebSocket 连接管理（web_socket_channel 3.0.3）。

**交付物**：

1. **`lib/services/experiment_service.dart`** — ExperimentService
   - `list({scope, status, startDate, endDate, page, pageSize})` → PaginatedResponse\<Experiment\>
   - `getById(id)` → Experiment
   - `create(params)` → Experiment
   - `load(id)` → void
   - `start(id)` → void
   - `pause(id)` → void
   - `resume(id)` → void
   - `stop(id)` → void
   - `getStatus(id)` → ExperimentStatus
   - `getHistory(id)` → List\<StatusChange\>
   - `queryData(id, params)` → TimeSeriesData

2. **`lib/services/ws_service.dart`** — WebSocket 连接管理（web_socket_channel 3.0.3）
   ```dart
   class WsService {
     // 连接 WebSocket，返回 Stream
     Stream<ExperimentMessage> connect(String experimentId);
     void disconnect();
     // 重连机制：指数退避 1s→2s→4s→8s，最多 5 次
   }
   ```
   - 连接：`ws://localhost:8080/ws/experiments/{id}`
   - 断开自动重连（指数退避）
   - 重连失败后手动重连

3. **`lib/providers/experiment_provider.dart`** — ExperimentNotifier
   - `ExperimentListNotifier`：试验列表 + 筛选 + 分页
   - `ExperimentControlNotifier`：单个试验的控制操作 + 状态管理
   - `ExperimentWsProvider`：通过 `StreamProvider` 消费 WebSocket 数据
   - WebSocket 消息分类处理：状态变更 → 更新控制面板 / 日志 → 追加日志区

**TDD 流程**：
1. **测试用例**：
   - 试验列表加载、筛选、分页
   - 创建试验成功
   - 各控制操作（load/start/pause/resume/stop）
   - WebSocket 连接 → 接收状态变更消息
   - WebSocket 连接 → 接收日志消息
   - WebSocket 断开 → 重连
   - 重连超过 5 次 → 手动重连按钮
2. **详细设计**：WebSocket 消息类型定义、状态机、重连流程图
3. **开发**：实现 ExperimentService + WsService + Providers
4. **代码审查**：验证 WebSocket 管理正确、状态同步
5. **测试执行**：单元测试 + Mock WebSocket 测试

**验收标准**：
- 试验 CRUD 和控制操作正常
- WebSocket 连接/断开管理正确
- 重连机制工作正常
- 状态变更和日志正确分发

---

### TASK-021: 试验列表页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-021 |
| **优先级** | P0 |
| **依赖** | TASK-020 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 5 |

**描述**：

实现试验列表页面 UI。路由 `/experiments`。

**参考 PRD §M8 验收标准（试验列表）**。

**交付物**：

1. **`lib/pages/experiment/experiment_list_page.dart`** — 试验列表页
   - 表格或卡片展示：
     - 名称 / 方法 / 状态（带颜色标签 + 动画）/ 开始时间 / 持续时间 / 操作
   - 状态颜色：
     - IDLE（灰）/ LOADED（蓝）/ RUNNING（绿+脉冲动画）/ PAUSED（橙）/ COMPLETED（绿）/ ERROR（红）
   - 筛选栏：状态多选 + 时间范围选择器
   - 分页：底部"共 N 条记录"
   - 操作列："进入控制台"（路由至 `/experiments/:id`）、"停止"（仅 RUNNING/PAUSED）
   - 右上角"+ 创建试验"按钮
   - 空状态："暂无试验记录"

2. **`lib/widgets/status_badge.dart`** — 状态标签组件（可复用）
   - 不同状态对应不同颜色和动画
   - RUNNING 状态带脉冲动画

**TDD 流程**：
1. **测试用例**：
   - 加载试验列表（loading/loaded/empty/error）
   - 状态筛选过滤
   - 时间范围筛选
   - 点击进入控制台
   - 停止操作（带确认）
2. **详细设计**：表格列定义、筛选器设计
3. **开发**：实现列表页 + StatusBadge
4. **代码审查**：验证筛选逻辑、响应式表格
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 表格正确显示所有列
- 状态颜色和动画正确
- 筛选功能工作
- 分页正常
- 小屏表格转卡片
- 截图：列表页（各种状态、筛选状态）

---

### TASK-022: 试验创建流程 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-022 |
| **优先级** | P0 |
| **依赖** | TASK-021 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 5 |

**描述**：

实现试验创建流程 UI。路由 `/experiments/new`。

**参考 PRD §M8 验收标准（创建试验流程）**。

**交付物**：

1. **`lib/pages/experiment/experiment_create_page.dart`** — 创建试验页

   **步骤 1：选择工作台**
   - 工作台列表（下拉或卡片选择）
   - 显示工作台名称 + 设备数量
   - 选中高亮
   - 加载状态：骨架屏
   - 空状态：引导创建第一个工作台

   **步骤 2：选择试验方法**
   - 方法列表（下拉或卡片选择）
   - 显示方法名 + 描述摘要
   - 选中高亮
   - 加载状态：骨架屏

   **步骤 3：配置参数**
   - 根据所选方法的参数表动态生成输入表单
   - 每个参数：参数名、类型、单位、描述、默认值
   - 用户可修改默认值
   - 参数验证（类型匹配、范围检查）

   **步骤 4：创建**
   - "创建"按钮：工作台和方法未选择时禁用
   - 创建成功 → Toast → 导航到 `/experiments/:id`

2. **`lib/services/method_service.dart`** — MethodService（为步骤 2 提供数据）
   - `list()` → List\<Method\>
   - `getById(id)` → Method

**TDD 流程**：
1. **测试用例**：
   - 步骤 1：工作台列表加载，选择高亮
   - 步骤 2：方法列表加载，选择高亮
   - 步骤 3：参数表单动态生成，默认值预填
   - 步骤 4：未选择时按钮禁用，创建成功跳转
   - 创建失败 Toast 错误消息
2. **详细设计**：步骤流程图、参数表单动态生成规则
3. **开发**：实现创建页面 + MethodService
4. **代码审查**：验证步骤流转、参数验证
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 三步流程完整走通
- 工作台/方法未选时创建按钮禁用
- 参数表单根据方法动态变化
- 创建成功后跳转控制台
- 截图：每个步骤的 UI 状态

---

### TASK-023: 试验控制台 UI（核心页面）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-023 |
| **优先级** | P0 |
| **依赖** | TASK-020, TASK-022 |
| **预计工期** | 2 天 |
| **Sprint** | Sprint 5 |

**描述**：

实现试验控制台页面 UI。路由 `/experiments/:id`。**这是整个应用最核心的页面。**

**参考 PRD §M8 验收标准（试验控制台）**。

**交付物**：

1. **`lib/pages/experiment/experiment_console_page.dart`** — 试验控制台

   布局结构：
   ```
   ┌────────────────────────────────────────────────────────┐
   │ ← 返回列表   试验名称 + 状态标签(脉冲动画)    WS: 🟢已连接│
   ├────────────────────────────────────────────────────────┤
   │  控制面板（左侧）           │  执行日志（右侧）          │
   │  ┌─────────────────────┐  │  ┌──────────────────────┐ │
   │  │ 工作台：XXX          │  │  │ [INFO] 14:30:01 ...   │ │
   │  │ 方法：XXX            │  │  │ [WARN] 14:31:15 ...   │ │
   │  │ 状态：RUNNING (大字)  │  │  │ [INFO] 14:32:00 ...   │ │
   │  │ 开始时间：14:30      │  │  │ ...                   │ │
   │  │ 已运行：02:15:32     │  │  │                       │ │
   │  │                     │  │  │  ↓ 新日志（浮动按钮）  │ │
   │  │ [载入][开始][暂停]   │  │  │                       │ │
   │  │ [继续][停止]         │  │  └──────────────────────┘ │
   │  └─────────────────────┘  │                            │
   └────────────────────────────────────────────────────────┘
   ```

2. **左侧控制面板**：
   - 试验信息摘要：工作台名、方法名、创建时间
   - 控制按钮组（根据当前状态动态启用/禁用）：
     - IDLE：载入按钮可用
     - LOADED：开始按钮可用
     - RUNNING：暂停、停止可用
     - PAUSED：继续、停止可用
     - COMPLETED/ERROR：全部禁用
   - 按钮防重复提交：点击后显示 loading
   - 停止按钮需二次确认
   - 当前状态大字显示 + 颜色标签
   - 运行时长计时器（RUNNING/PAUSED 状态实时更新）

3. **右侧执行日志区** — `lib/widgets/log_viewer.dart`（可复用组件）
   - 等宽字体（`monospace`）
   - 每条日志：级别标签（INFO/WARN/ERROR/DEBUG）+ 时间戳 + 消息
   - 颜色：INFO(蓝)/WARN(橙)/ERROR(红)/DEBUG(灰)
   - 自动滚动到底部（新日志推送时）
   - 用户手动上滚 → 右下角浮动"↓ 新日志"按钮
   - "清空日志"按钮
   - 日志级别筛选（显示/隐藏 DEBUG）

4. **WebSocket 管理**：
   - 进入页面 → 自动连接 WS
   - 连接状态指示：🟢已连接 / 🟡连接中 / 🔴已断开
   - 离开页面 → 断开连接
   - 断开自动重连（指数退避，TASK-020 已实现）
   - 通过 WS 接收：状态变更 → 更新控制面板 / 日志 → 追加日志区

5. **试验完成后**：
   - 显示试验详情：基本信息 + 状态变更历史时间线
   - 测点历史数据概览（可选）

**TDD 流程**：
1. **测试用例**：
   - 控制按钮根据状态正确启用/禁用
   - 各控制操作正确
   - 停止按钮二次确认
   - 日志实时追加、自动滚动
   - 手动滚动时浮动按钮出现
   - WS 连接状态指示器
   - WS 断开重连
   - 离开页面断开 WS
   - 计时器正确运行/暂停
2. **详细设计**：控制台布局图（三种宽度）、按钮状态映射表、日志渲染优化
3. **开发**：实现控制台 + LogViewer + WS 集成
4. **代码审查**：验证 WebSocket 生命周期、按钮状态逻辑、日志性能
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 控制按钮组根据状态正确启用/禁用
- 按钮点击 loading 反馈
- 状态实时更新（WS 推送）
- 日志实时推送 + 自动滚动
- WS 连接状态指示
- 运行计时器正确
- 停止有二次确认
- 小屏上下堆叠布局
- 截图：各状态下的控制台（IDLE/LOADED/RUNNING/PAUSED）、日志区

---

## Sprint 6: P1 模块（1 周，4 个任务）

> **依赖 Sprint 5 完成（需要完整的试验相关基础设施）**

---

### TASK-024: M2 首页仪表盘 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-024 |
| **优先级** | P1 |
| **依赖** | TASK-008, TASK-012, TASK-020 |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 6 |

**描述**：

实现首页仪表盘 UI。路由 `/`。

**参考 PRD §M2 验收标准**。

**交付物**：

1. **`lib/pages/dashboard/dashboard_page.dart`** — 首页仪表盘
   - 欢迎区域：
     - 根据时间段："早上好"/"下午好"/"晚上好"，加用户名
     - 显示当前日期
   - 快捷操作卡片（网格，4 个）：
     - 🧪 试验控制台 → `/experiments`
     - 📐 试验方法 → `/methods`
     - 🔧 工作台管理 → `/workbenches`
     - 📊 数据分析 → `/analysis`
   - 最近工作台（水平卡片列表，最近 4 个）
     - 每张：名称、设备数量、最近活动时间
     - 空状态：引导创建
   - 统计概览（数字卡片行）：
     - 工作台总数、设备总数、试验总数
     - **必须是后端真实数据，禁止"-"占位符**
     - 无数据时显示"0"

2. **`lib/services/dashboard_service.dart`** — DashboardService
   - 聚合多个后端数据用于仪表盘

**三态要求**：
- Loading：骨架屏（欢迎 + 卡片 + 统计）
- Error：错误 + 重试
- Data：完整内容

**TDD 流程**：
1. **测试用例**：
   - 欢迎信息根据时间段正确
   - 快捷入口点击跳转正确
   - 统计数据为真实数据
   - 空数据时显示"0"
   - 无工作台时最近工作台空状态
2. **详细设计**：仪表盘布局（三种宽度）
3. **开发**：实现 DashboardPage + DashboardService
4. **代码审查**：验证数据来源为后端真实数据
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 所有数据来自后端（非假数据）
- 统计数据为真实数值/0
- 快捷入口跳转正确
- 完整三态
- 截图：仪表盘（loading、loaded、空数据）

---

### TASK-025: M7 试验方法管理 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-025 |
| **优先级** | P1 |
| **依赖** | TASK-004, TASK-022（TASK-022 已创建 MethodService） |
| **预计工期** | 1.5 天 |
| **Sprint** | Sprint 6 |

**描述**：

实现试验方法管理页面 UI。路由 `/methods`、`/methods/:id/edit`。

**参考 PRD §M7 验收标准**。

**交付物**：

1. **`lib/pages/method/method_list_page.dart`** — 方法列表页
   - 卡片列表：名称、描述摘要（2 行）、参数数量、创建时间
   - 搜索框：按名称关键词
   - 空状态："暂无试验方法" + "创建第一个方法"
   - 每张卡片：编辑、删除操作
   - 右上角"+ 创建方法"

2. **`lib/pages/method/method_edit_page.dart`** — 创建/编辑方法页
   - 名称（必填，最长 255）
   - 描述（选填，多行）
   - 过程定义编辑器：
     - 等宽字体代码编辑器风格
     - JSON 格式的过程定义代码
     - 语法错误标红提示
   - 参数表管理：
     - 表格：参数名 / 类型 / 默认值 / 单位 / 描述 / 操作
     - "+ 添加参数" → 新行
     - 每行可编辑、删除
     - 类型：Number/Integer/Boolean/String
   - 操作按钮：
     - "验证"：调用 POST /methods/validate → Toast 结果
     - "保存"：调用 POST/PUT
     - 保存成功 → 跳回列表
   - 未保存变更提醒：离开时弹窗确认

3. **`lib/providers/method_provider.dart`** — MethodNotifier
   - `MethodListNotifier`
   - `MethodDetailNotifier`

**TDD 流程**：
1. **测试用例**：
   - 方法列表加载
   - 创建方法
   - 编辑方法
   - 删除方法二次确认
   - JSON 验证调用
   - 未保存离开提醒
2. **详细设计**：JSON 编辑器、参数表设计
3. **开发**：实现列表页 + 编辑页 + MethodNotifier
4. **代码审查**：验证 JSON 验证、表单逻辑
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- CRUD 完整
- JSON 编辑器可用（语法高亮/错误提示）
- 参数表 CRUD
- 验证功能
- 未保存提醒
- 截图：方法列表、方法编辑页

---

### TASK-026: M9 数据分析与可视化 UI（fl_chart 1.2.0）

| 属性 | 内容 |
|------|------|
| **ID** | TASK-026 |
| **优先级** | P1 |
| **依赖** | TASK-020, TASK-005 |
| **预计工期** | 2 天 |
| **Sprint** | Sprint 6 |

**描述**：

使用 fl_chart 1.2.0 实现数据分析与可视化页面 UI。路由 `/analysis`。

**fl_chart 1.x API 要点**：
- `FlSpot` 参数顺序可能调整
- 触摸回调签名变更
- 图表组件构造函数参数调整
- `LineChart`、`LineChartData`、`LineChartBarData` 等类

**参考 PRD §M9 验收标准**。

**交付物**：

1. **`lib/pages/analysis/analysis_page.dart`** — 数据分析页
   - 左边控制面板 + 右侧图表区

2. **控制面板**（左侧）：
   - 试验选择下拉框（已完成/有数据的试验）
   - 设备选择下拉框（根据试验过滤）
   - 测点复选框列表（根据设备过滤，最多 4 条曲线）
     - 每条带颜色指示圆点
   - 时间范围：
     - 预设：最近 1 小时 / 24 小时 / 全部
     - 自定义日期时间范围
   - 降采样滑块：100-10,000，默认 1,000
   - "加载数据"按钮
   - "重置视图"按钮
   - 数据表格开关

3. **图表区域**（右侧）— 使用 fl_chart 1.2.0：
   - 时序折线图：
     - X 轴：时间（自动格式 HH:mm:ss 或 MM-dd HH:mm）
     - Y 轴：数值（含单位）
     - 多条曲线不同颜色
     - 图例：测点名称 + 颜色，点击隐藏/显示
   - 交互：
     - 鼠标悬停 → 数据提示框
     - 滚轮缩放 X 轴
     - 拖拽平移
     - 双指缩放（移动端）
   - 主题适配：自动跟随浅色/深色
   - 状态：空（未加载）、加载中、错误、无数据

4. **数据表格**（可选底部面板）：
   - 时间戳 / 测点1值 / 测点2值 / ...
   - 数值格式化 + 单位
   - 垂直滚动

5. **`lib/services/analysis_service.dart`** — AnalysisService
   - `loadChartData(experimentId, pointIds, timeRange, downsample)` → TimeSeriesData
   - 调用 `POST /experiments/{id}/data/query`

6. **`lib/widgets/time_series_chart.dart`** — 时序图表可复用组件
   - 封装 fl_chart 1.2.0 LineChart
   - 适配深色/浅色主题

**TDD 流程**：
1. **测试用例**：
   - 试验选择下拉 → 设备列表更新
   - 设备选择 → 测点列表更新
   - 测点超过 4 个时复选框限制
   - 加载数据 → 图表渲染
   - 降采样参数正确传递
   - 深色主题下图表颜色正确
   - 数据表格显示
2. **详细设计**：图表配置、降采样算法（前端仅传参）
3. **开发**：实现 AnalysisPage + TimeSeriesChart + AnalysisService
4. **代码审查**：验证 fl_chart 1.x API 使用正确、图表渲染
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 试验 → 设备 → 测点级联选择
- 图表正确渲染时序数据
- 多条曲线颜色不同
- 缩放、平移、悬停提示
- 主题跟随深浅色
- 数据表格可切换
- 截图：图表（有数据、空状态、加载中、深色主题）

---

### TASK-027: M10 设置页面 UI

| 属性 | 内容 |
|------|------|
| **ID** | TASK-027 |
| **优先级** | P1 |
| **依赖** | TASK-005, TASK-006 |
| **预计工期** | 1 天 |
| **Sprint** | Sprint 6 |

**描述**：

实现设置页面 UI。路由 `/settings`。

**参考 PRD §M10 验收标准**。

**交付物**：

1. **`lib/pages/settings/settings_page.dart`** — 设置页
   - 分组列表：

   **外观**：
   - 主题切换：跟随系统 / 浅色 / 深色（SegmentedButton 或 Radio）
   - 选择立即生效

   **语言**：
   - 语言切换：English / 中文（下拉选择）
   - 切换立即生效

   **关于**：
   - 应用名称：Kayak
   - 版本：3.0.0
   - 描述："Kayak — 科学研究支持平台"
   - 技术信息：Flutter + Rust

2. **集成到 AppShell 导航**：
   - 底部添加"设置"入口（齿轮图标）

**TDD 流程**：
1. **测试用例**：
   - 主题切换 → 页面立即变化
   - 语言切换 → 页面文字立即变化
   - 设置持久化 → 重新打开保持
2. **详细设计**：设置页分组布局
3. **开发**：实现 SettingsPage + 导航集成
4. **代码审查**：验证即时生效、持久化
5. **测试执行**：Widget 测试 + 截图

**验收标准**：
- 主题切换即时生效
- 语言切换即时生效
- 设置持久化
- 截图：设置页（浅色/深色、英文/中文）

---

## 附录 A：任务依赖图

```
Sprint 1: 基础设施（7 tasks）
─────────────────────────────
TASK-001 (项目初始化)
  ├── TASK-002 (数据模型)
  ├── TASK-005 (主题系统)
  │     └── TASK-006 (国际化) ──┐
  └── TASK-003 (API Client)     │
        ├── TASK-004 (路由)      │
        └── TASK-007 (组件库) ◄──┘

Sprint 2: M1 认证（4 tasks）
─────────────────────────────
TASK-008 (Auth Provider) ◄── TASK-003, TASK-006
  ├── TASK-009 (登录页) ◄── TASK-004, TASK-007, TASK-008
  │     └── TASK-010 (注册页)
  └── TASK-011 (个人资料)

Sprint 3: M4 工作台（3 tasks）
─────────────────────────────
TASK-012 (工作台 Provider) ◄── TASK-003, TASK-008
  └── TASK-013 (工作台列表页) ◄── TASK-007, TASK-012
        └── TASK-014 (工作台详情页)

Sprint 4: M5 设备 + M6 测点（5 tasks）
───────────────────────────────────────
TASK-015 (设备 Provider) ◄── TASK-003, TASK-014
  ├── TASK-016 (设备树 UI)
  │     └── TASK-017 (设备配置表单 + 详情面板)
  └── TASK-018 (测点 Provider)
        └── TASK-019 (测点列表 UI) ◄── TASK-017, TASK-018

Sprint 5: M8 试验控制台（4 tasks）
───────────────────────────────────
TASK-020 (试验 Provider + WS) ◄── TASK-003, TASK-012
  ├── TASK-021 (试验列表页)
  ├── TASK-022 (试验创建流程)
  └── TASK-023 (试验控制台) ◄── TASK-020, TASK-022

Sprint 6: P1 模块（4 tasks）
─────────────────────────────
TASK-024 (仪表盘) ◄── TASK-008, TASK-012, TASK-020
TASK-025 (方法管理) ◄── TASK-004, TASK-022
TASK-026 (数据分析) ◄── TASK-020, TASK-005
TASK-027 (设置页) ◄── TASK-005, TASK-006
```

---

## 附录 B：统计摘要

| 指标 | 数值 |
|------|------|
| **总任务数** | 27 |
| **Sprint 数** | 6 |
| **预计总工期** | 6 周 |
| **P0 任务数** | 19 |
| **P1 任务数** | 8 |
| **关键路径** | TASK-001 → 002 → 003 → 008 → 012 → 015 → 020 → 023（约 5 周） |

---

## 附录 C：风险与缓解

| 风险 | 影响任务 | 缓解措施 |
|------|----------|----------|
| go_router 17.x API 与 13.x 差异大 | TASK-004 | 直接查阅 17.x 官方文档，此为从零开发无需迁移 |
| Riverpod 3.x Notifier API 陌生 | TASK-008, TASK-012 | 先写测试验证 Notifier 行为，参考官方示例 |
| freezed 3.x sealed class 语法 | TASK-002 | 首个模型写完整后再批量生成其余模型 |
| web_socket_channel 3.x 变更 | TASK-020 | 查阅 CHANGELOG，编写独立测试验证 |
| fl_chart 1.x API 变更 | TASK-026 | 在本地创建独立 demo 验证图表 API 后再集成 |
| flutter_secure_storage 10.x 加密 | TASK-003 | 新项目无迁移问题，直接使用新 API |

---

> **下一步**: 创建 `log/release_3/sprint_board.md`
