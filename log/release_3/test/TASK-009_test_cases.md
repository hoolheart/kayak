# TASK-009 测试用例 — 登录页面 UI

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Approved
> **关联任务**: TASK-009（登录页面 UI）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md) §M1 认证, [M1_auth_spec.md](../ui/specifications/M1_auth_spec.md), [TASK-009_design.md](../design/TASK-009_design.md)

---

## 测试范围

TASK-009 实现登录页面 UI（路由 `/login`），包含邮箱/密码输入、表单验证、登录加载状态、错误显示、注册链接跳转、响应式布局。本文件覆盖约 15 个功能测试用例。

| # | 功能点 | 测试覆盖 |
|---|--------|:------:|
| 1 | 页面初始渲染 | TC-001 ~ TC-002 |
| 2 | Email 输入框 | TC-003 ~ TC-004 |
| 3 | Password 输入框 | TC-005 ~ TC-006 |
| 4 | 表单验证 | TC-007 ~ TC-008 |
| 5 | 登录提交 | TC-009 ~ TC-010 |
| 6 | 错误显示 | TC-011 ~ TC-012 |
| 7 | 注册链接 | TC-013 |
| 8 | Enter 键支持 | TC-014 |
| 9 | 响应式布局 | TC-015 ~ TC-017 |
| 10 | 国际化 | TC-018 ~ TC-019 |
| 11 | 主题适配 | TC-020 |
| 12 | 截图验证 | TC-G01 ~ TC-G03 |

---

## 依赖组件与 API

### 后端 API

| API | 方法 | 说明 |
|-----|------|------|
| `POST /api/v1/auth/login` | POST | 登录 (body: `email`, `password`) → AuthTokens |

### 前端组件

| 组件 | 文件 | 说明 |
|------|------|------|
| LoginPage | `lib/pages/auth/login_page.dart` | 目标页面 (~142 行) |
| EmailField | `lib/pages/auth/auth_widgets.dart` | 邮箱输入共享组件 |
| PasswordField | `lib/pages/auth/auth_widgets.dart` | 密码输入共享组件 |
| AuthSubmitButton | `lib/pages/auth/auth_widgets.dart` | 提交按钮共享组件 |
| AuthNotifier | `lib/providers/auth_provider.dart` | 认证状态管理 (TASK-008) |
| ErrorView | `lib/widgets/error_view.dart` | 错误展示组件 (TASK-007) |

### 路由

| 路由 | 页面 | 说明 |
|------|------|------|
| `/login` | LoginPage | 登录页面 |
| `/register` | RegisterPage | 注册页面（TASK-010） |

---

## 一、页面初始渲染（2 项）

### TC-001: 页面结构元素渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 页面渲染 / 结构 |
| **关联验收标准** | 显示邮箱输入框和密码输入框，带有清晰的 label |

**前置条件**：
- 应用已启动，未登录状态
- 路由 `/login`

**测试步骤**：
1. 导航到 `/login` 页面
2. 验证所有页面元素存在

**预期结果**：
- ✅ Kayak Logo（`Icons.science_outlined`, 64px）可见
- ✅ 应用标题 "Kayak" 可见（`headlineMedium`）
- ✅ 邮箱输入框 `EmailField` 渲染，带 label "Email"
- ✅ 密码输入框 `PasswordField` 渲染，带 label "Password"
- ✅ 登录按钮 `AuthSubmitButton` 渲染，文字 "Sign In"
- ✅ 注册链接 "Don't have an account? Register" 可见
- ✅ 错误提示区域初始时不可见（`authState.hasError == false`）
- ✅ 页面居中布局

**失败判定**：
- ❌ 任何必需元素缺失
- ❌ 页面布局错乱

---

### TC-002: 页面初始焦点

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | 交互 / 初始状态 |
| **关联验收标准** | 邮箱输入框自动获得焦点（桌面端） |

**前置条件**：
- 页面已加载
- 桌面视口（>600px）

**测试步骤**：
1. 导航到 `/login`
2. 无需任何操作

**预期结果**：
- ✅ 邮箱输入框获得焦点（光标闪烁）
- ✅ 键盘类型为 `TextInputType.emailAddress`
- ✅ 自动填充 hint 为 `AutofillHints.email`

**失败判定**：
- ❌ 页面加载后无任何元素获得焦点
- ❌ 键盘类型不正确

---

## 二、Email 输入框（2 项）

### TC-003: Email 输入框交互状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P1 — HIGH** |
| **类别** | 输入框 / 状态 |

**前置条件**：
- 页面已加载

**测试步骤**：
1. 点击邮箱输入框 → 获得焦点
2. 输入 "user@example.com"
3. 点击其他区域 → 失去焦点
4. 验证 Hover 状态（鼠标悬停）
5. 验证 Focused 状态（Tab 进入）

**预期结果**：
- ✅ Default 状态：边框颜色 `Outline`，Label 颜色 `On Surface Variant`
- ✅ Hover 状态：边框颜色 `On Surface Variant`，背景略变
- ✅ Focus 状态：边框颜色 `Primary (#1976D2)`，边框宽度 2px，Label 上浮
- ✅ Filled 状态（有内容但失焦）：Label 保持上浮，边框 `Outline`
- ✅ 前缀图标为 `Icons.email_outlined` (24px)
- ✅ 前缀图标颜色：默认 `On Surface Variant`，聚焦时 `Primary`

**失败判定**：
- ❌ 各状态颜色与设计令牌不符
- ❌ Focus 状态下边框宽度未增加到 2px
- ❌ Label 未在输入时上浮

---

### TC-004: Email 格式验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P1 — HIGH** |
| **类别** | 输入框 / 验证 |

**前置条件**：
- 页面已加载

**测试步骤**：
1. 输入无效邮箱 "notanemail"
2. 提交表单（点击登录 or 按 Enter from password field）
3. 验证错误提示
4. 输入有效邮箱 "user@example.com"
5. 提交表单

**预期结果**：
- ✅ 无效邮箱提交 → 验证拦截，显示错误提示 "Please enter a valid email address"
- ✅ 错误提示显示在邮箱输入框下方
- ✅ 错误状态下输入框边框变为 `Error (#BA1A1A)`
- ✅ 输入框前景图标和 Label 变为 `Error` 颜色
- ✅ 有效邮箱提交 → 通过非空验证 → 进入下一步

**失败判定**：
- ❌ 无效邮箱可通过验证
- ❌ 错误提示不显示或位置不对
- ❌ 输入框边框颜色不切换

---

## 三、Password 输入框（2 项）

### TC-005: Password 输入框交互状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 输入框 / 状态 |

**前置条件**：
- 页面已加载

**测试步骤**：
1. 观察密码输入框默认状态
2. 输入文字 → 验证默认隐藏效果
3. 点击眼睛图标 → 验证显示效果
4. 再次点击 → 恢复隐藏

**预期结果**：
- ✅ 默认 `obscureText = true`（密码显示为 `•`）
- ✅ 前缀图标 `Icons.lock_outlined` (24px)
- ✅ Suffix 图标 `Icons.visibility_off_outlined` (24px) 显示
- ✅ 点击 visibility_off → 切换为 `Icons.visibility_outlined`，密码明文可见
- ✅ 再次点击 → 恢复 `visibility_off_outlined`，密码隐藏
- ✅ 密码切换不影响 `controller.text` 的值
- ✅ 密码切换 tooltip 国际化（en: "Show password" / "Hide password"；zh: "显示密码" / "隐藏密码"）

**失败判定**：
- ❌ 密码始终明文显示
- ❌ 切换图标无反应
- ❌ 切换后 tooltip 硬编码英文

---

### TC-006: Password tooltip 国际化

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 国际化 / 辅助功能 |
| **关联验收标准** | 所有文本通过 AppLocalizations 国际化 |
| **关联 Review Issue** | HIGH — 密码切换 tooltip 硬编码英文 |

**前置条件**：
- 应用支持 en 和 zh 语言
- 页面已加载

**测试步骤**：
1. 切换到英文（en）
2. 鼠标悬停在密码切换图标上 → 验证 tooltip
3. 切换密码为可见 → 悬停 → 验证 tooltip
4. 切换到中文（zh）
5. 重复步骤 2-3

**预期结果**：
- ✅ en + 密码隐藏时 tooltip: "Show password"
- ✅ en + 密码显示时 tooltip: "Hide password"
- ✅ zh + 密码隐藏时 tooltip: "显示密码"
- ✅ zh + 密码显示时 tooltip: "隐藏密码"

**失败判定**：
- ❌ tooltip 始终显示英文
- ❌ tooltip 显示原始 key 而非翻译文本

---

## 四、表单验证（2 项）

### TC-007: 空字段提交验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 表单 / 验证 |
| **关联验收标准** | 邮箱、密码为空时按钮不可点击（视觉禁用） |

**前置条件**：
- 页面已加载
- 表单清空

**测试步骤**：
1. 不填邮箱和密码 → 点击登录
2. 只填邮箱 → 点击登录
3. 只填密码 → 点击登录

**预期结果**：
- ✅ 邮箱为空 + 密码为空 → 按钮 onSubmit → 表单验证拦截
  - 邮箱字段显示 "Email is required"
  - 密码字段显示 "Password is required"
- ✅ 仅邮箱为空 → 邮箱字段显示验证错误
- ✅ 仅密码为空 → 密码字段显示验证错误
- ✅ 验证错误后不发送 API 请求
- ✅ 各字段错误提示使用 l10n key（`emailRequired` / `passwordRequired`）

**失败判定**：
- ❌ 空字段可通过验证
- ❌ 验证提示硬编码英文
- ❌ 只有邮箱/密码之一为空时发送了 API 请求

---

### TC-008: 输入框在 Loading 状态下禁用

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 表单 / Loading |
| **关联验收标准** | 按钮 loading 状态下输入框禁用 |

**前置条件**：
- 已输入有效邮箱和密码

**测试步骤**：
1. 点击登录
2. 在 Loading 状态下尝试点击邮箱输入框
3. 在 Loading 状态下尝试点击密码输入框
4. 在 Loading 状态下尝试切换密码可见性
5. 在 Loading 状态下尝试点击注册链接

**预期结果**：
- ✅ Loading 时 EmailField `enabled: false`（视觉禁用，文字灰色）
- ✅ Loading 时 PasswordField `enabled: false`
- ✅ Loading 时密码切换按钮禁用
- ✅ Loading 时注册链接禁用（`onPressed: null` → 文字灰色）
- ✅ Loading 时不可修改输入框内容

**失败判定**：
- ❌ Loading 时仍可编辑输入框
- ❌ Loading 时注册链接可点击跳转

---

## 五、登录提交（2 项）

### TC-009: 登录成功流程

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 登录 / 成功 |
| **关联验收标准** | 登录成功后跳转首页 |

**前置条件**：
- 输入有效凭据（邮箱: "admin@kayak.local", 密码: "Admin123"）
- 后端 `POST /api/v1/auth/login` 返回 200 + AuthTokens

**测试步骤**：
1. 输入邮箱和密码
2. 点击登录
3. 观察 Loading 状态
4. 等待登录成功

**预期结果**：
- ✅ 点击登录 → 按钮显示 `CircularProgressIndicator`（24px, strokeWidth: 2.5）
- ✅ Loading 期间按钮不可点击
- ✅ Loading 期间输入框禁用
- ✅ API 调用 `POST /api/v1/auth/login` → body `{email, password}`
- ✅ 返回 200 → `AuthNotifier.state = AsyncData(User)`
- ✅ 路由守卫检测已登录 → 重定向到 `/` (首页)
- ✅ 如用户从受保护页重定向而来 → 登录后返回原页面

**失败判定**：
- ❌ 登录成功后未跳转
- ❌ 登录后的跳转丢失原目标页面
- ❌ Button 在 Loading 时没有正确的 spinner

---

### TC-010: 登录失败后密码清空

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 登录 / 失败处理 |
| **关联验收标准** | 登录失败显示具体原因（非技术错误） |
| **关联 Review Issue** | HIGH — 登录失败后密码未清空 |

**前置条件**：
- 输入错误密码（邮箱正确但密码错误）
- 后端返回 401 → AuthNotifier.state = AsyncError

**测试步骤**：
1. 输入邮箱 "admin@kayak.local" + 错误密码 "WrongPassword"
2. 点击登录
3. 等待错误返回
4. 验证密码输入框状态
5. 验证邮箱输入框状态

**预期结果**：
- ✅ 登录失败 → 显示 ErrorView（compact 模式，无重试按钮）
- ✅ 错误消息为用户友好文本（如 "Invalid email or password"，非技术细节）
- ✅ **密码输入框被清空**（符合设计规格要求）
- ✅ 邮箱输入框保留原值（不清空）
- ✅ 按钮 loading 状态恢复
- ✅ 输入框重新启用

**失败判定**：
- ❌ 登录失败后密码仍保留在输入框中
- ❌ 邮箱输入框被错误清空
- ❌ 错误消息为技术细节（如 "DioException: 401"）
- ❌ 按钮卡在 Loading 状态

---

## 六、错误显示（2 项）

### TC-011: ErrorView 渲染和交互

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P1 — HIGH** |
| **类别** | 错误显示 |
| **关联验收标准** | 登录失败显示具体原因（非技术错误） |

**前置条件**：
- AuthNotifier.state = AsyncError

**测试步骤**：
1. 触发登录错误（401 邮箱或密码错误）
2. 验证 ErrorView 渲染
3. 触发网络错误（连接超时）
4. 验证 ErrorView 渲染

**预期结果 — 401 错误**：
- ✅ ErrorView 以 compact 模式渲染（`compact: true`）
- ✅ 不显示重试按钮（`showRetry: false`）
- ✅ 错误消息："Invalid email or password"（en）/ "邮箱或密码错误"（zh）
- ✅ 错误图标可见（`Icons.error_outline`）
- ✅ ErrorView 在表单顶部、Logo 下方显示
- ✅ 显示/隐藏有高度动画

**预期结果 — 网络错误**：
- ✅ 错误消息："Network connection failed"（en）/ "网络连接失败"（zh）

**失败判定**：
- ❌ 错误消息为原始 DioException 字符串
- ❌ ErrorView 挡住输入框
- ❌ 无动画直接闪现

---

### TC-012: 错误状态后重新输入

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P1 — HIGH** |
| **类别** | 错误恢复 |

**前置条件**：
- 登录失败，密码已清空，ErrorView 可见

**测试步骤**：
1. 登录失败后，重新输入密码
2. 点击登录
3. 模拟登录成功

**预期结果**：
- ✅ 重新输入后 ErrorView 消失（AuthNotifier 状态从 AsyncError 变为 AsyncLoading）
- ✅ 可正常重新登录
- ✅ 登录成功 → 跳转首页

**失败判定**：
- ❌ 错误后无法重新提交
- ❌ ErrorView 一直显示不消失
- ❌ 重新输入后表单仍禁用

---

## 七、注册链接（1 项）

### TC-013: 注册链接导航

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 导航 |
| **关联验收标准** | "注册"链接跳转 `/register` |

**前置条件**：
- 登录页面已渲染

**测试步骤**：
1. 点击 "Don't have an account? Register" 链接
2. 验证导航行为
3. 从注册页返回 → 验证登录页状态

**预期结果**：
- ✅ 点击链接 → 导航到 `/register`
- ✅ 链接使用 TextButton（非普通文字）
- ✅ 链接颜色为 Primary
- ✅ 链接有 Hover 效果（下划线 + 背景色）
- ✅ 从 `/register` 返回 → 回到 `/login`，表单状态保持
- ✅ 链接在 Loading 状态下禁用（`onPressed: null`）
- ✅ 中文环境下显示 "还没有账号？立即注册"

**失败判定**：
- ❌ 点击无导航
- ❌ 导航到错误路由
- ❌ Loading 时链接可点击
- ❌ 中文环境下仍显示英文

---

## 八、Enter 键支持（1 项）

### TC-014: Enter 键提交

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 键盘交互 |
| **关联 Review Issue** | HIGH — 缺少 Enter 键提交支持 |

**前置条件**：
- 页面已加载
- 桌面端（有物理键盘）

**测试步骤**：
1. 在邮箱输入框按 Enter
2. 在密码输入框按 Enter

**预期结果**：
- ✅ 邮箱输入框按 Enter → 焦点移动到密码输入框
  - EmailField 的 `textInputAction` 为 `TextInputAction.next`
  - `onFieldSubmitted` → `FocusScope.of(context).nextFocus()`
- ✅ 密码输入框按 Enter → 触发登录
  - PasswordField 的 `textInputAction` 为 `TextInputAction.done`
  - `onFieldSubmitted` → 调用 `_handleLogin()`
- ✅ 邮箱为空时按 Enter → 不移焦，显示验证错误
- ✅ 密码为空时按 Enter → 不提交，显示验证错误

**失败判定**：
- ❌ 邮箱按 Enter 无反应
- ❌ 密码按 Enter 不提交
- ❌ 空字段按 Enter 仍提交（应被验证拦截）

---

## 九、响应式布局（3 项）

### TC-015: 移动端适配（< 600px）

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / Mobile |

**测试步骤**：
1. 将视口宽度设为 375px（iPhone 尺寸）
2. 验证布局

**预期结果**：
- ✅ 页面背景为 Surface，无卡片容器
- ✅ 内容水平 padding 24px，垂直居中
- ✅ Logo 图标 56px（移动端规格）
- ✅ 标题字号 28px（`headlineMedium`）
- ✅ `SingleChildScrollView` 可滚动（键盘弹出时）
- ✅ 无横向滚动条
- ✅ 按钮和输入框全宽

**失败判定**：
- ❌ 移动端有横向滚动条
- ❌ Logo 图标过大（64px）
- ❌ 键盘弹出时页面不可滚动

---

### TC-016: 平板适配（600-1024px）

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / Tablet |

**测试步骤**：
1. 将视口宽度设为 768px（iPad 尺寸）
2. 验证布局

**预期结果**：
- ✅ 页面背景为 Background
- ✅ 内容居中于约束容器，`maxWidth: 420px`
- ✅ Logo 图标 64px
- ✅ 整体视觉：卡片式居中布局

**失败判定**：
- ❌ 内容撑满全屏（应居中）
- ❌ 内容宽度超过 420px

---

### TC-017: 桌面适配（> 1024px）

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / Desktop |

**测试步骤**：
1. 将视口宽度设为 1440px
2. 验证布局

**预期结果**：
- ✅ 内容居中，`maxWidth: 480px`
- ✅ Logo 图标 64px
- ✅ 标题字号 36px（设计规格桌面端要求，实际可能为 28px `headlineMedium`—需确认实现）
- ✅ 整体视觉良好

**失败判定**：
- ❌ 桌面端内容过窄（如 420px 而非 480px）

---

## 十、国际化（2 项）

### TC-018: 英文（en）环境下所有文本正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 国际化 / en |
| **关联验收标准** | 所有文本通过 AppLocalizations 国际化 |

**前置条件**：
- 语言设置为 English (en)

**测试步骤**：
1. 渲染登录页面（en 环境）
2. 检查所有可见文本

**预期结果**：

| 元素 | 预期英文文本 | 对应 l10n key |
|------|------------|-------------|
| 应用标题 | "Kayak" | `appTitle` |
| 邮箱 label | "Email" | `email` |
| 邮箱 hint | "Please enter your email" | `emailHint` |
| 密码 label | "Password" | `password` |
| 密码 hint | "Please enter your password" | `passwordHint` |
| 登录按钮 | "Sign In" | `signIn` |
| 注册链接 | "Don't have an account? Register" | `noAccount` |
| 邮箱为空错误 | "Email is required" | `emailRequired` |
| 密码为空错误 | "Password is required" | `passwordRequired` |
| 登录失败错误 | "Invalid email or password" | `loginError` |
| 密码显示 tooltip | "Show password" | `showPassword` |
| 密码隐藏 tooltip | "Hide password" | `hidePassword` |

**失败判定**：
- ❌ 任何元素显示原始 key（如 `@@appTitle`）而非翻译文本

---

### TC-019: 中文（zh）环境下所有文本正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 国际化 / zh |

**前置条件**：
- 语言设置为简体中文 (zh)

**测试步骤**：
1. 切换到中文
2. 检查所有可见文本

**预期结果**：

| 元素 | 预期中文文本 |
|------|------------|
| 应用标题 | "Kayak" |
| 邮箱 label | "邮箱" |
| 邮箱 hint | "请输入邮箱地址" |
| 密码 label | "密码" |
| 密码 hint | "请输入密码" |
| 登录按钮 | "登录" |
| 注册链接 | "还没有账号？立即注册" |
| 邮箱为空错误 | "请输入邮箱地址" |
| 密码为空错误 | "请输入密码" |
| 登录失败错误 | "邮箱或密码错误" |
| 密码显示 tooltip | "显示密码" |
| 密码隐藏 tooltip | "隐藏密码" |

**失败判定**：
- ❌ 中文环境下任何文本仍为英文

---

## 十一、主题适配（1 项）

### TC-020: Light/Dark 主题切换

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P1 — HIGH** |
| **类别** | 主题 |

**测试步骤**：
1. 浅色主题下渲染登录页面
2. 深色主题下渲染登录页面
3. 对比颜色

**预期结果 — Light Theme**：

| 元素 | 预期颜色 |
|------|---------|
| 页面背景 | `Background (#FDFCFF)` |
| 文字 | `On Background (#1A1C1E)` |
| 输入框背景 | `Surface (#FFFFFF)` |
| 输入框边框 | `Outline (#74777F)` |
| 登录按钮背景 | `Primary (#1976D2)` |
| 按钮文字 | `On Primary (#FFFFFF)` |
| ErrorView 背景 | `Error Container (#FFDAD6)` |
| ErrorView 文字 | `On Error Container (#410002)` |

**预期结果 — Dark Theme**：

| 元素 | 预期颜色 |
|------|---------|
| 页面背景 | `Background (#1A1C1E)` |
| 文字 | `On Background (#E2E2E6)` |
| 输入框背景 | `Surface (#1A1C1E)` |
| 登录按钮背景 | `Primary (#90CAF9)` |
| 按钮文字 | `On Primary (#003258)` |

**预期结果**：
- ✅ 所有颜色跟随主题切换
- ✅ 文字在深色背景上可读
- ✅ ErrorView 在深浅主题下均有足够对比度

**失败判定**：
- ❌ 深色主题下文字不可见
- ❌ 主题切换后颜色不变

---

## 十二、截图验证（3 项）

### TC-G01: 截图 — 登录页初始状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-G01 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 截图验证 |

**测试步骤**：
1. 桌面视口 (1440×900) 渲染登录页面初始状态
2. 截图
3. 与 Figma 原型对比

**预期结果**：
- ✅ 表单居中完整渲染
- ✅ Logo + 标题 + 邮箱框 + 密码框 + 登录按钮 + 注册链接
- ✅ 与设计稿偏差在容忍范围内

---

### TC-G02: 截图 — 登录页 Loading 状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-G02 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 截图验证 |

**测试步骤**：
1. 填写邮箱和密码
2. 点击登录进入 Loading 状态
3. 截图

**预期结果**：
- ✅ 按钮显示 CircularProgressIndicator（24px）
- ✅ 输入框视觉禁用（灰色文字）
- ✅ 注册链接禁用（灰色）
- ✅ 与设计规范一致

---

### TC-G03: 截图 — 登录页 Error 状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-G03 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 截图验证 |

**测试步骤**：
1. 输入邮箱和错误密码
2. 提交 → 等待错误返回
3. 截图

**预期结果**：
- ✅ ErrorView（compact）在表单顶部显示
- ✅ 错误消息为用户友好文本
- ✅ 密码输入框已清空
- ✅ 邮箱输入框保留原值
- ✅ 按钮恢复正常状态

---

## 十三、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| 页面渲染 | 2 | TC-001 ~ TC-002 |
| Email 输入框 | 2 | TC-003 ~ TC-004 |
| Password 输入框 | 2 | TC-005 ~ TC-006 |
| 表单验证 | 2 | TC-007 ~ TC-008 |
| 登录提交 | 2 | TC-009 ~ TC-010 |
| 错误显示 | 2 | TC-011 ~ TC-012 |
| 注册链接 | 1 | TC-013 |
| Enter 键 | 1 | TC-014 |
| 响应式布局 | 3 | TC-015 ~ TC-017 |
| 国际化 | 2 | TC-018 ~ TC-019 |
| 主题适配 | 1 | TC-020 |
| 截图验证 | 3 | TC-G01 ~ TC-G03 |
| **合计** | **23** | |

| 优先级分布 | 数量 | 占比 |
|-----------|:---:|:---:|
| P0 — CRITICAL | 12 | 52% |
| P1 — HIGH | 11 | 48% |

---

## 十四、可追溯性矩阵

| 验收标准（来自 tasks.md §TASK-009） | 对应测试用例 |
|-----------------------------------|------------|
| 邮箱、密码为空时按钮禁用 | TC-007, TC-008 |
| 登录失败显示具体原因（非技术错误） | TC-010, TC-011 |
| 登录成功后跳转首页 | TC-009 |
| 受保护页面重定向 → 登录后返回原页面 | TC-009 |
| 按钮 loading 状态下输入框禁用 | TC-008 |
| 密码可显示/隐藏切换 | TC-005, TC-006 |

| 设计规格检查项（来自 M1_auth_spec.md） | 对应测试用例 |
|---------------------------------------|------------|
| 邮箱输入框带 label + 输入验证 | TC-003, TC-004 |
| 密码输入框带 label + 显示/隐藏切换 | TC-005, TC-006 |
| 登录按钮三种状态（Default/Hover/Pressed/Disabled/Loading） | TC-009 |
| Loading 指示器 24px, strokeWidth 2.5 | TC-009 |
| 错误提示内联 Alert 规格 | TC-011 |
| 注册链接 TextButton 导航 | TC-013 |
| Enter 键提交（Email→移焦, Password→提交） | TC-014 |
| 响应式三断点 | TC-015, TC-016, TC-017 |
| Light/Dark 主题颜色 | TC-020 |
| 设计 QA 检查 — 密码清空（登录失败） | TC-010 |

| Review Issue | 对应测试用例 |
|-------------|------------|
| HIGH #1: 密码切换 tooltip 国际化 | TC-006 |
| HIGH #2: 登录失败后密码未清空 | TC-010 |
| HIGH #3: 缺少 Enter 键提交支持 | TC-014 |

---

## 十五、测试执行记录模板

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | 页面结构元素 |
| TC-002 | | | ⬜ 待执行 | 初始焦点 |
| TC-003 | | | ⬜ 待执行 | Email 交互状态 |
| TC-004 | | | ⬜ 待执行 | Email 格式验证 |
| TC-005 | | | ⬜ 待执行 | Password 交互状态 |
| TC-006 | | | ⬜ 待执行 | Password tooltip 国际化 |
| TC-007 | | | ⬜ 待执行 | 空字段验证 |
| TC-008 | | | ⬜ 待执行 | Loading 禁用 |
| TC-009 | | | ⬜ 待执行 | 登录成功 |
| TC-010 | | | ⬜ 待执行 | 登录失败清空密码 |
| TC-011 | | | ⬜ 待执行 | ErrorView 渲染 |
| TC-012 | | | ⬜ 待执行 | 错误后重新输入 |
| TC-013 | | | ⬜ 待执行 | 注册链接 |
| TC-014 | | | ⬜ 待执行 | Enter 键提交 |
| TC-015 | | | ⬜ 待执行 | 移动端适配 |
| TC-016 | | | ⬜ 待执行 | 平板适配 |
| TC-017 | | | ⬜ 待执行 | 桌面适配 |
| TC-018 | | | ⬜ 待执行 | en 国际化 |
| TC-019 | | | ⬜ 待执行 | zh 国际化 |
| TC-020 | | | ⬜ 待执行 | Light/Dark 主题 |
| TC-G01 | | | ⬜ 待执行 | 截图：初始状态 |
| TC-G02 | | | ⬜ 待执行 | 截图：Loading |
| TC-G03 | | | ⬜ 待执行 | 截图：Error |

---

**文档状态**: ✅ 已完成
**下一步**: sw-tom 审查测试用例 → sw-mike 测试执行
**总用例数**: 23（20 功能 + 3 截图）
**文件路径**: `log/release_3/test/TASK-009_test_cases.md`
