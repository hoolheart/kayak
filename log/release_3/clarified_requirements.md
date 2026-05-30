# 澄清需求文档 — Release 4

**版本**: 1.0  
**日期**: 2026-05-30  
**作者**: sw-camille (Product Owner)  
**状态**: 待用户确认

---

## 1. 问题发现过程

### 1.1 信息来源
- 用户试用反馈（6项严重问题）
- sw-prod 代码审查报告（4项根因分析）
- sw-camille 独立代码审查（深入验证）

### 1.2 分析方法
作为产品负责人，我需要从**用户视角**理解每一个问题——想象自己是一位科研人员，打开 Kayak 平台想管理实验设备时，实际经历了什么。

---

## 2. 用户旅程还原（共情分析）

### 2.1 用户首次使用 Kayak 的实际旅程

```
用户打开浏览器 → 看到登录页面 → 输入 admin@kayak.local / Admin123
→ 点击登录 → 看到 loading 转圈 1秒 → 登录按钮变绿（显示成功）
→ 但... 页面停留在登录页，没有跳转！

用户刷新页面 → 又回到登录页 → 再次登录 → 再次卡在登录页
→ 反复尝试 → 最终放弃
```

**用户感受**: "我明明登录成功了，为什么进不去？是不是系统坏了？"

**根因** (`login_form.dart` L91):
```dart
// TODO: 调用后端API进行登录    ← 这里！
// 模拟登录成功，直接跳转        ← 从未真正登录
Future.delayed(const Duration(seconds: 1), () {
  if (mounted) {
    ref.read(loginProvider.notifier).setSuccess();  // 只改了LoginProvider，没改AuthState!
  }
});
```

这段代码做了三件错误的事：
1. **从未调用 `AuthStateNotifier.login()`** — 后端的完整认证链路（`AuthApiService.login()` → 保存Token → `AuthState.authenticated()`）被完全绕过
2. **只设置了 `LoginProvider.status = success`** — 这是登录表单的局部状态，不是全局认证状态
3. **路由守卫检查的是 `authState.isAuthenticated`** — 这个值从未变成 `true`，所以 `GoRouter.redirect` 永远不会触发跳转

### 2.2 如果登录成功了，用户会经历什么

```
登录成功 → 进入 Dashboard → 看到欢迎信息 + 快捷操作卡片 + 统计概览
→ 点击"工作台" → 进入工作台列表 → 列表为空（因为没创建过）
→ 统计概览显示: 设备总数 "-"、试验总数 "-"、数据文件 "-"   ← 都是硬编码的占位符
→ 点击"试验" → 进入试验列表 → 同样为空
→ 点击右上角 → 找不到"退出登录"按钮 → 无法登出
→ 关闭浏览器标签页
```

**用户感受**: "界面看着还行，但数据全是空的，我也不知道怎么添加设备，而且居然没法退出登录？"

### 2.3 用户关闭标签页后重新打开

```
重新打开浏览器 → 访问 localhost:8080 → 显示登录页
→ 用户困惑: "我刚才不是登录过吗？怎么又要登录？"
→ 再次登录 → 还是卡住...
```

**根因**: `flutter_secure_storage` 在 Web HTTP localhost 环境下可能静默失败，Token 无法持久化。即使用户真的登录成功了，刷新页面也会丢失会话。

---

## 3. 已验证的问题清单

### 3.1 问题对照表（用户反馈 vs 代码根因）

| # | 用户反馈 | 代码审查发现的根因 | 严重程度 |
|---|---------|------------------|---------|
| 1 | 登录无法正常完成 | `login_form.dart:91` — 使用了模拟登录，从未调用真正的 `AuthStateNotifier.login()` | **🔴 Blocker** |
| 2 | 没有退出功能 | `AuthStateNotifier.logout()` 完整实现，但 **缺少 UI 入口**（无退出按钮） | **🔴 Blocker** |
| 3 | 重启应用仍在登录状态 | `flutter_secure_storage` 在 Web HTTP localhost 环境可能失败；但 TokenStorage 初始化逻辑完备，需验证 Web 环境下的实际行为 | **🟡 待验证** |
| 4 | 前端风格不美观 | 需用户具体说明；深色调/多语言结构完备，但**使用体验可能有问题** | **🟡 待澄清** |
| 5 | 主要功能有界面但无法使用 | **验真**: 设备管理/工作台/试验的后端服务（WorkbenchService、ExperimentService）已完整实现并连接 API。**但登录阻断了一切**。Dashboard 统计卡片显示硬编码 "-"（设备总数、试验总数、数据文件） | **🔴 间接 Blocker** |
| 6 | 没有模拟设备能力 | **验伪**: 后端 VirtualDriver 和 modbus-simulator 已实现。**但前端未提供创建虚拟设备的入口或引导**，用户不知道这些功能存在 | **🟡 功能暴露问题** |
| 7 | 用户手册无截图，与实际不符 | **验真**: `/docs/screenshots/` 为空目录；用户手册版本 1.0 仅覆盖 Release 1，缺失 Release 2 的团队管理、分析页面、Python SDK 等内容 | **🔴 Major** |

---

## 4. 深入分析

### 4.1 登录问题的完整链路

```
LoginForm._submitForm()
  ├── 表单验证(邮箱+密码) ✅
  ├── loginProvider.setLoading() ✅ (局部状态)
  ├── TODO: 调用后端API进行登录 ❌ (未实现)
  ├── Future.delayed 1秒 ❌ (模拟延迟)
  └── loginProvider.setSuccess() ❌ (只改了局部状态)
  
正确应该是:
LoginForm._submitForm()
  ├── 表单验证 ✅
  ├── authStateNotifier.login(email, password) ← 缺失!
  │   ├── AuthApiService.login() → 后端 POST /api/v1/auth/login
  │   ├── TokenStorage.saveTokens()
  │   ├── AuthState.authenticated(user, token) ← 触发全局状态变化
  │   └── GoRouter.redirect → authState.isAuthenticated=true → 跳转 /dashboard
  └── (成功)
```

**奇怪的事实**: `AuthStateNotifier.login()` 已经完整实现（第110-140行），`AuthApiService.login()` 也已经完整实现（第37-57行），后端 `POST /api/v1/auth/login` 也正常工作。**唯一的问题就是 LoginForm 没有调用它们。**

### 4.2 退出功能的完整链路

```
当前位置: AppShell 的 AppBar 或用户菜单
需要: 一个"退出登录"按钮或菜单项

缺失的UI入口:
┌─────────────────────────────────────────┐
│  Kayak   团队选择器 ▼    🔔  👤  [?]   │  ← 用户头像旁边应有下拉菜单
│                                          │     包含: 个人设置、退出登录
└─────────────────────────────────────────┘

现有实现:
- AuthStateNotifier.logout() → 清除Token → AuthState.initial()
- GoRouter.redirect → authState.isAuthenticated=false → 重定向到 /login
- 一切就绪，就差一个按钮
```

### 4.3 功能页面的实际可用性

我逐一检查了每个功能模块的后端服务和前端集成：

| 模块 | 后端API | 前端服务层 | 前端UI | 实际可用性 |
|------|--------|-----------|--------|-----------|
| Dashboard | — | WorkbenchService 已集成 | ✅ 完整UI | ⚠️ 统计硬编码 "-" |
| 工作台列表 | ✅ /api/v1/workbenches | ✅ CRUD 完整 | ✅ 完整UI | ✅ (登录后可工作) |
| 工作台详情 | ✅ /api/v1/workbenches/:id | ✅ 完整 | ✅ 完整UI | ✅ |
| 设备管理 | ✅ /api/v1/devices | ✅ CRUD 完整 | ✅ 完整UI | ✅ |
| 测点管理 | ✅ /api/v1/points | ✅ CRUD 完整 | ✅ 完整UI | ✅ |
| 试验列表 | ✅ /api/v1/experiments | ✅ 查询/过滤 | ✅ 完整UI | ✅ |
| 试验控制台 | ✅ + WebSocket | ✅ 完整 | ✅ 1016行UI | ✅ (需先有试验) |
| 分析方法列表 | ✅ /api/v1/methods | ✅ 完整 | ✅ 完整UI | ✅ |
| 分析页面 | ✅ /data/query | ✅ 集成 | ✅ 完整UI | ⚠️ (需先有数据) |
| 团队管理 | ✅ 10个端点 | ✅ CRUD 完整 | ✅ 完整UI | ✅ |
| 设置页面 | — | — | ✅ 完整UI | ⚠️ (退出登录缺失) |

**结论**: 大部分功能**后端和前端服务层都已完成**，真正的阻塞因素是**登录无法完成**。一旦修复登录，用户就能正常使用工作台、设备、试验、方法、团队等功能。但以下具体问题仍需修复：
- Dashboard 统计卡片（设备总数、试验总数、数据文件）显示硬编码 `"-"`，未连接实际数据
- 分析页面需要先有试验数据才能使用
- 缺少引导用户创建虚拟设备的流程

### 4.4 Token 存储的 Web 兼容性

```dart
// token_storage.dart:42-62
static TokenStorageInterface create() {
  if (!kIsWeb) {
    // 桌面平台使用 SharedPreferences ← 这个分支是正确的
    ...
  }
  // Web 和移动平台使用 flutter_secure_storage ← Web 可能有问题!
  return SecureTokenStorage();
}
```

`flutter_secure_storage` 在 Web 上：
- 使用 `Window.localStorage` 作为后端
- 在 HTTP localhost 环境下**理论上可用**
- 但有不少已知的兼容性问题报告
- 建议：Web 环境也使用 `SharedPreferences` 作为降级方案

---

## 5. 需要用户澄清的问题

在制定 PRD 之前，以下问题需要用户明确回答。我按主题分组，并解释了每个问题的背景。

---

### 问卷 A: 登录体验

**A1. 登录成功后的目标页面**
登录成功后，您希望看到什么页面？
- [ ] A. Dashboard（当前设计: `/dashboard`）
- [ ] B. 工作台列表（直接进入工作区）
- [ ] C. 其他（请说明）

**A2. 会话保持偏好**
当您关闭浏览器标签页后重新打开，您希望：
- [ ] A. 自动恢复登录状态（无需重新输入密码）— 当前设计目标
- [ ] B. 需要重新登录（安全优先）
- [ ] C. 提供"记住我"选项，让用户选择

**A3. 登录失败的错误提示**
当前系统在登录失败时会在表单下方显示错误信息。您认为：
- [ ] A. 当前设计已满足需求
- [ ] B. 需要更具体的错误提示（如区分"用户不存在"和"密码错误"）
- [ ] C. 需要其他改进（请说明）

---

### 问卷 B: 退出登录

**B1. 退出登录按钮的位置**
您认为"退出登录"按钮最合适的位置是哪里？
- [ ] A. AppBar 右上角用户头像下拉菜单中（与个人设置并列）
- [ ] B. 侧边栏导航底部
- [ ] C. 设置页面中
- [ ] D. 以上都提供

**B2. 退出后的行为**
退出登录后，您希望：
- [ ] A. 停留在当前页面并显示"已退出登录"提示
- [ ] B. 自动跳转到登录页面
- [ ] C. 跳转到登录页面并显示"已安全退出"提示

---

### 问卷 C: 前端视觉设计

**C1. 具体的不满意之处**
您提到"前端风格不美观，深色调和多语言支持徒有其表"。请具体说明哪些方面不满意：
- [ ] A. 颜色搭配不协调
- [ ] B. 字体大小和排版不舒服
- [ ] C. 组件间距和布局不合理
- [ ] D. 深色主题下的对比度不足
- [ ] E. 多语言翻译质量差或有缺失
- [ ] F. 其他（请具体描述）

**C2. 设计参考**
您是否有心仪的设计风格或参考产品？如果有，请提供名称或截图。

**C3. 是否需要完整的 UI 重新设计**
- [ ] A. 当前框架可以接受，只需调整配色/字体/间距等
- [ ] B. 需要全新的视觉设计（由设计师出 Figma 原型）
- [ ] C. 不确定，建议先出设计方案供评审

---

### 问卷 D: 功能可用性

**D1. 登录修复后的功能验证优先级**
一旦登录修复，以下功能将恢复可用。请确认您的验证优先级（1=最高，5=最低）：
- [ ] 工作台管理（创建/编辑/删除工作台）
- [ ] 设备管理（添加虚拟设备/Modbus设备）
- [ ] 试验管理（创建试验方法、执行试验）
- [ ] 数据分析（查看试验数据图表）
- [ ] 团队管理（创建团队、邀请成员）

**D2. Dashboard 统计信息**
Dashboard 目前显示"设备总数"、"试验总数"、"数据文件"等统计，但都是占位符 "-"。您希望：
- [ ] A. 连接后端真实数据，显示实时统计
- [ ] B. 在当前阶段可以接受占位符，后续再完善
- [ ] C. 不想看到这些统计卡片，可以删除

---

### 问卷 E: 模拟设备

**E1. 创建虚拟设备的方式**
系统已有 Virtual Driver 但用户不易发现。您认为应该如何帮助用户创建测试设备：
- [ ] A. 首次进入工作台时显示引导提示："还没有设备？点击这里创建一个虚拟设备"
- [ ] B. 提供一个"快速开始"功能，一键创建带有虚拟设备的示例工作台
- [ ] C. 两者都需要
- [ ] D. 其他（请说明）

**E2. 后端 modbus-simulator**
后端已有 `cargo run --bin modbus-simulator` 命令行工具。您是否需要：
- [ ] A. 不需要，虚拟设备已足够
- [ ] B. 需要，但只需命令行工具即可
- [ ] C. 需要在前端提供一键启动/停止模拟器的功能

---

### 问卷 F: 用户手册

**F1. 用户手册的覆盖范围**
当前用户手册（v1.0）仅覆盖 Release 1 功能。您希望更新到：
- [ ] A. 仅覆盖当前可正常使用的功能（Release 1 + Release 2 已实现的团队/分析/SDK）
- [ ] B. 覆盖包括本 Release 4 修复后的所有功能
- [ ] C. 先修复功能，再更新手册

**F2. 截图要求**
用户手册需要多少截图：
- [ ] A. 每个主要页面一张截图（约10-15张）
- [ ] B. 关键操作流程配截图（登录→Dashboard→创建工作台→添加设备→执行试验）
- [ ] C. 越多越好，详细展示每个功能

**F3. 用户手册的语言**
- [ ] A. 仅中文
- [ ] B. 中文 + 英文双语
- [ ] C. 中文 + 英文 + 法文三语

---

### 问卷 G: 范围边界

**G1. 本 Release 4 的时间预期**
- [ ] A. 尽快修复（1周内），只解决 Blocker 问题（登录、退出、Token存储）
- [ ] B. 标准节奏（2周），修复 Blocker + Major + 用户手册 + 前端视觉优化
- [ ] C. 完整修复（3-4周），包含以上所有 + UI 重新设计

**G2. 是否需要 sw-anna 进行 UI 重新设计**
- [ ] A. 是，需要专业 UI 设计师重新设计全部页面
- [ ] B. 否，当前 Material Design 3 框架可以使用，只需微调
- [ ] C. 部分重新设计（请说明哪些页面最需要）

---

## 6. 已明确的需求（无需用户回答）

以下需求已经通过代码审查明确，可以直接写入 PRD：

| ID | 需求描述 | 根因 | 修复方向 |
|----|---------|------|---------|
| FR-AUTH-001 | 登录表单必须调用真正的后端API进行认证 | `login_form.dart:91` 使用模拟登录 | 将 `LoginForm._submitForm()` 改为调用 `authStateNotifier.login()` |
| FR-AUTH-002 | 用户必须能够退出登录 | `logout()` 方法存在但无UI入口 | 在 AppBar 用户菜单中添加"退出登录"按钮 |
| FR-AUTH-003 | Web环境下Token必须能可靠持久化 | `flutter_secure_storage` 在Web可能不可靠 | Web环境使用 SharedPreferences 作为降级存储 |
| FR-DASH-001 | Dashboard统计须连接后端真实数据 | 统计卡片硬编码 "-" | 添加设备/试验/数据文件计数的API调用 |
| FR-DOCS-001 | 用户手册须包含截图并覆盖Release 2功能 | `/screenshots/` 为空；手册版本落后 | 为每个主要页面截图；更新手册至当前版本 |
| FR-ONBOARD-001 | 新用户应有创建虚拟设备的引导 | 无引导流程 | 添加首次使用的引导提示或快速开始功能 |

---

## 7. 附录：完整的登录问题技术分析

### 当前代码流程 vs 正确流程

```
【当前流程 (BUG)】
LoginForm._submitForm()
  → 表单验证 ✅
  → loginProvider.setLoading() ← 局部状态
  → Future.delayed(1秒) ← 模拟延迟
  → loginProvider.setSuccess() ← 仅改LoginState.status
  → 路由守卫检查 authStateProvider → isAuthenticated = false
  → ❌ 不触发跳转，停留在 /login

【正确流程 (修复后)】
LoginForm._submitForm()
  → 表单验证 ✅
  → ref.read(authStateNotifierProvider).login(email, password)
      → AuthApiService.login() → POST /api/v1/auth/login → 后端验证
      → TokenStorage.saveTokens() → 持久化Token
      → state = AuthState.authenticated(user, token)
      → isAuthenticated = true ✅
  → GoRouter.redirect 检测到 isAuthenticated = true
  → ✅ 跳转到 /dashboard

【退出流程 (修复后)】
用户点击"退出登录"按钮
  → authStateNotifier.logout()
      → TokenStorage.clearTokens() → 清除持久化的Token
      → state = AuthState.initial()
      → isAuthenticated = false
  → GoRouter.redirect 检测到 isAuthenticated = false
  → ✅ 跳转到 /login
```

---

## 8. 下一步

请用户审阅以上分析并回答 **问卷 A-G** 中的问题。收到回答后，我将制定完整的 PRD。

**请注意**: 即使没有用户回答，以上"已明确的需求"部分（第6节）已足够开始修复核心 Blocker 问题。非 Blocker 的需求方向和优先级取决于用户的问卷回答。

---

**文档结束**

*本澄清需求文档基于以下代码审查建立:*
- `kayak-frontend/lib/features/auth/widgets/login_form.dart` (L91 — 模拟登录Bug)
- `kayak-frontend/lib/core/auth/auth_notifier.dart` (完整实现但未被调用)
- `kayak-frontend/lib/core/auth/auth_api_service.dart` (完整API集成)
- `kayak-frontend/lib/core/auth/token_storage.dart` (Web兼容性问题)
- `kayak-frontend/lib/core/router/app_router.dart` (路由守卫逻辑完整)
- `kayak-frontend/lib/core/auth/providers.dart` (Provider配置完整)
- `kayak-frontend/lib/features/dashboard/screens/dashboard_screen.dart` (统计硬编码)
- `kayak-frontend/lib/features/workbench/services/workbench_service.dart` (服务层完整)
- `kayak-frontend/lib/features/experiments/services/experiment_service.dart` (服务层完整)
- `docs/user-manual/user_manual.md` (版本落后，无截图)
- `docs/screenshots/` (空目录)
