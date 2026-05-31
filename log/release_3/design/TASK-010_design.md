# TASK-010 详细设计：注册页面真实 UI

## 文档信息

| 属性 | 内容 |
|------|------|
| **任务 ID** | TASK-010 |
| **任务名称** | 注册页面真实 UI |
| **Sprint** | Sprint 2 — M1 认证与身份管理 |
| **依赖** | TASK-009 (登录页面 UI, 共享组件) |
| **设计参考** | `M1_auth_design.txt` (Figma 原型), `M1_auth_spec.md` (设计规格) |
| **日期** | 2026-05-31 |
| **状态** | 待评审 |

---

## 1. 页面概述

注册页面 (`/register`) 提供用户注册功能，包含邮箱、密码（带强度指示器）、用户名（选填）输入。

### 页面状态机

```
┌─────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  初始    │────▶│   输入邮箱    │────▶│   输入密码    │────▶│   输入用户    │
│  表单空  │     │              │     │  (实时强度)   │     │   名(选填)   │
└─────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                  │
                                                     ┌────────────┘
                                                     ▼
                                              ┌──────────────┐
                                              │   提交中      │
                                              │  Loading 状态 │
                                              └──────┬───────┘
                                                     │
                                           ┌──────────┴──────────┐
                                           ▼                     ▼
                                    ┌──────────────┐   ┌──────────────┐
                                    │   注册成功    │   │   注册失败    │
                                    │   自动登录    │   │   显示错误    │
                                    │   跳转首页    │   │   保留输入    │
                                    └──────────────┘   └──────────────┘
```

### 状态定义

| 状态 | 触发条件 | 视觉表现 | 交互限制 |
|------|----------|----------|----------|
| **初始** | 页面加载 | 表单清空，强度为空，按钮默认 | 无限制 |
| **输入中** | 用户输入 | 对应字段激活，Label 上浮 | 无限制 |
| **密码输入** | 密码框输入 | 强度指示器实时更新，要求列表更新 | 无限制 |
| **验证中** | 失去焦点 | 邮箱格式检查、用户名格式检查 | 无限制 |
| **就绪** | 邮箱+密码+确认密码均有效 | 按钮可用 | 无限制 |
| **提交中** | 点击注册 | 按钮显示 CircularProgressIndicator，输入框禁用 | 禁止所有输入 |
| **成功** | 后端返回 200 | 自动登录并重定向到 `/dashboard` | 无 |
| **错误** | 后端返回 4xx/5xx | 显示 ErrorView，保留输入 | 可重新输入 |

---

## 2. UI 组件树

```
Scaffold
 └── Center
      └── SingleChildScrollView
           └── ConstrainedBox (maxWidth: 420px)
                └── Form
                     └── Column
                          ├── Logo 区域
                          │    ├── Icon (science, 64px, Primary)
                          │    └── Text ("Kayak", headlineMedium)
                          │
                          ├── ErrorView (条件渲染: authState.hasError)
                          │    └── title: authState.error.toString()
                          │
                          ├── EmailField (邮箱输入框, 复用 auth_widgets)
                          │    └── 验证: 非空 + 邮箱格式
                          │
                          ├── PasswordField (密码输入框, 复用 auth_widgets)
                          │    └── 验证: 非空 + 长度 >= 6
                          │
                          ├── PasswordStrengthIndicator (新增组件)
                          │    ├── 4 段颜色条 (弱/中/良/强)
                          │    └── 要求检查列表 (4 项)
                          │
                          ├── PasswordField (确认密码输入框)
                          │    ├── 自定义 label: "确认密码"
                          │    └── 验证: 与密码一致
                          │
                          ├── UsernameField (用户名输入框)
                          │    ├── label: "用户名（选填）"
                          │    └── helper: "不填则使用邮箱前缀"
                          │
                          ├── RegisterButton (注册按钮)
                          │    ├── CircularProgressIndicator (isLoading 时显示)
                          │    └── onPressed: _handleRegister (isLoading + 验证未通过时禁用)
                          │
                          └── LoginLink (登录链接)
                               └── TextButton → navigate to /login
```

### 响应式布局

| 断点 | 范围 | 布局行为 |
|------|------|----------|
| Mobile | < 600px | 全屏填充，无卡片效果，24px padding |
| Tablet | 600px-1024px | 居中卡片 maxWidth 420px |
| Desktop | > 1024px | 居中卡片 maxWidth 420px |

---

## 3. 密码强度算法

### 评分规则

| 条件 | 得分 | 说明 |
|------|------|------|
| 长度 >= 6 | +0.25 | 基础长度要求 |
| 长度 >= 10 | +0.15 | 额外长度加分 |
| 包含大写字母 | +0.20 | `[A-Z]` |
| 包含数字 | +0.20 | `[0-9]` |
| 包含特殊字符 | +0.20 | `[!@#$%^&*(),.?":{}|<>]` |

### 等级映射

| 总得分 | 等级 | 填充段数 | 颜色 | 文字标签 key |
|--------|------|----------|------|-------------|
| 0 | 空 | 0 | — | — |
| >0 ~ 0.25 | 弱 (Weak) | 1 | Error (#BA1A1A) | `passwordStrengthWeak` |
| 0.25 ~ 0.60 | 中 (Medium) | 2 | Warning (#ED6C02) | `passwordStrengthMedium` |
| 0.60 ~ 0.80 | 良 (Good) | 3 | Primary (#1976D2) | `passwordStrengthGood` |
| >0.80 | 强 (Strong) | 4 | Success (#2E7D32) | `passwordStrengthStrong` |

### 检查列表

| 检查项 | 条件 | 图标 (满足/未满足) |
|--------|------|-------------------|
| 至少 8 个字符 | password.length >= 8 | check_circle / circle_outlined |
| 包含大小写字母 | contains uppercase + contains lowercase | check_circle / circle_outlined |
| 包含数字 | contains `[0-9]` | check_circle / circle_outlined |
| 包含特殊字符 | contains `[!@#$%^&*(),.?":{}|<>]` | check_circle / circle_outlined |

---

## 4. 数据流

```
User Input
    │
    ▼
TextEditingControllers (本地状态)
    │
    ▼
Form.validate() (前端验证)
    │  ├── 邮箱: 非空 + 格式
    │  ├── 密码: 非空 + 长度 >= 6
    │  ├── 确认密码: 与密码一致
    │  └── 用户名: 可选，3-30 字符
    │
    ▼  (验证通过)
_handleRegister()
    │
    ▼
ref.read(authProvider.notifier).register(email, password, username?)
    │
    ├── AuthNotifier.register()
    │    ├── state = AsyncLoading()          → UI: 按钮 loading, 输入框禁用
    │    ├── authService.register(...)       → API POST /api/v1/auth/register
    │    ├── 成功: state = AsyncData(user)   → UI: Router 重定向到 /dashboard
    │    └── 失败: state = AsyncError(msg)   → UI: ErrorView 显示错误
    │
    └── 错误处理 (继承 AuthNotifier._mapError)
         ├── 409: "该邮箱已被注册"
         ├── 422: "输入数据格式不正确"
         ├── DioException → 映射为友好消息
         └── message.contains('already registered')
              → "该邮箱已被注册"
```

---

## 5. 新增/修改组件

### PasswordStrengthIndicator (新增到 auth_widgets.dart)

```dart
class PasswordStrengthIndicator extends StatelessWidget {
  final double strength; // 0.0 ~ 1.0
  final String password;
}
```

**视觉结构：**
```
┌──────────────────────────────────────┐
│  ■■■□  密码强度: 中                  │  ← 4段颜色条 + 标签
│                                      │
│  ✓ 至少 8 个字符                     │  ← 检查列表
│  ○ 包含大小写字母                    │
│  ✓ 包含数字                          │
│  ○ 包含特殊字符                      │
└──────────────────────────────────────┘
```

### 数据流中的密码强度

密码强度指示器是纯 UI 逻辑，使用 `_calculateStrength()` 方法在 `_RegisterPageState` 中实时计算，无需 Provider。

```
密码输入变化
    │
    ▼
setState(() { _passwordController.text changed })
    │
    ▼
build() 中调用 _calculateStrength(password)
    │
    ▼
PasswordStrengthIndicator(strength: calculatedStrength)
    │
    ▼
渲染 4 段颜色条 + 检查列表
```

---

## 6. 国际化 (AppLocalizations)

### 已有 key (可直接使用)

| Key | 英文 | 中文 |
|-----|------|------|
| `appTitle` | Kayak | Kayak |
| `register` | Register | 注册 |
| `email` | Email | 邮箱 |
| `emailHint` | Please enter your email | 请输入邮箱地址 |
| `emailRequired` | Email is required | 请输入邮箱地址 |
| `password` | Password | 密码 |
| `passwordHint` | Please enter your password | 请输入密码 |
| `passwordRequired` | Password is required | 请输入密码 |
| `username` | Username | 用户名 |
| `signIn` | Sign In | 登录 |

### 新增 key (需添加到 ARB 文件)

| Key | 英文 | 中文 |
|-----|------|------|
| `confirmPassword` | Confirm Password | 确认密码 |
| `confirmPasswordHint` | Please confirm your password | 请再次输入密码 |
| `passwordsDoNotMatch` | Passwords do not match | 两次密码输入不一致 |
| `usernameHint` | Set a display name | 设置一个显示名称 |
| `usernameHelper` | Leave blank to use email prefix | 不填则使用邮箱前缀作为用户名 |
| `hasAccount` | Already have an account? Login | 已有账号？立即登录 |
| `registrationSuccess` | Registration successful! | 注册成功！ |
| `passwordStrength` | Password strength | 密码强度 |
| `passwordStrengthWeak` | Weak | 弱 |
| `passwordStrengthMedium` | Medium | 中 |
| `passwordStrengthGood` | Good | 良 |
| `passwordStrengthStrong` | Strong | 强 |
| `passwordMinLength` | At least 8 characters | 至少 8 个字符 |
| `passwordUppercaseLowercase` | Contains uppercase & lowercase letters | 包含大小写字母 |
| `passwordNumber` | Contains a number | 包含数字 |
| `passwordSpecial` | Contains a special character | 包含特殊字符 |
| `usernameLengthError` | Username must be 3-30 characters | 用户名长度需在 3-30 字符之间 |
| `usernameInvalidChars` | Only letters, numbers, underscores and hyphens allowed | 仅允许字母、数字、下划线和连字符 |

---

## 7. 序列图

```
User                  RegisterPage                AuthNotifier              AuthService
 │                        │                            │                        │
 │  输入邮箱/密码/用户名   │                            │                        │
 │──────────────────────▶│                            │                        │
 │                        │                            │                        │
 │  密码强度实时计算       │                            │                        │
 │◀──────────────────────│                            │                        │
 │                        │                            │                        │
 │  点击注册              │                            │                        │
 │──────────────────────▶│                            │                        │
 │                        │  state = AsyncLoading()    │                        │
 │                        │───────────────────────────▶│                        │
 │                        │                            │                        │
 │   按钮显示 Loading     │                            │                        │
 │◀──────────────────────│                            │                        │
 │   输入框禁用           │                            │                        │
 │                        │                            │  register(...)         │
 │                        │                            │──────────────────────▶│
 │                        │                            │                        │ POST /api/v1/auth/register
 │                        │                            │                        │──────────────────▶
 │                        │                            │                        │
 │                        │                            │     ◀──────────────────│
 │                        │                            │     Token + User       │
 │                        │  state = AsyncData(user)   │                        │
 │                        │◀───────────────────────────│                        │
 │                        │                            │                        │
 │   重定向 /dashboard    │                            │                        │
 │◀──────────────────────│                            │                        │
 │                        │                            │                        │
 │   (OR 错误情况)        │                            │                        │
 │                        │  state = AsyncError(msg)   │                        │
 │                        │◀───────────────────────────│                        │
 │                        │                            │                        │
 │   显示 ErrorView       │                            │                        │
 │◀──────────────────────│                            │                        │
```

---

## 8. 共享组件新增设计 (auth_widgets.dart)

### PasswordStrengthIndicator

```dart
class PasswordStrengthIndicator extends StatelessWidget {
  final double strength;  // 0.0 ~ 1.0
  final String password;
}
```

| 属性 | 值 |
|------|-----|
| 段数 | 4 |
| 段高度 | 4px |
| 段圆角 | 2px |
| 段间距 | 4px |
| 空段颜色 | Surface Variant |
| 文字标签 | "密码强度: 弱/中/良/强" |
| 检查列表 | 4 项，带勾选/未勾选图标 |

---

## 9. 设计决策记录

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| Widget 类型 | ConsumerWidget / ConsumerStatefulWidget | **ConsumerStatefulWidget** | 需要 TextEditingControllers 和 Form 状态管理 |
| 密码强度计算 | 独立 Provider / 本地计算 | **本地 setState** | 纯 UI 逻辑，无需共享状态 |
| 确认密码验证 | Form validator / 提交时检查 | **Form validator + 提交时双重检查** | 提供即时视觉反馈 |
| 强度指示器位置 | 密码框下方 / 独立区域 | **密码框下方独立区域** | 视觉清晰，包含检查列表 |
| 密码强度段数 | 3 段 / 4 段 / 5 段 | **4 段** | 符合 Figma 设计，区分度好 |
| 用户名验证 | 提交时 / 实时 | **实时（失去焦点）+ 提交时** | 选填字段，减少干扰 |
| 错误展示 | Dialog / SnackBar / Inline ErrorView | **Inline ErrorView** | 与登录页一致，不阻断操作 |
| 注册成功行为 | 显示成功页 / 自动登录跳转 | **自动登录跳转首页** | 符合任务要求 (TASK-010 描述) |

---

## 10. 验收标准检查

- [x] 密码强度实时提示（4 段颜色条 + 文字标签 + 检查列表）
- [x] 注册成功自动登录并跳转首页
- [x] 注册失败显示具体原因
- [x] 确认密码与密码一致性验证
- [x] 邮箱验证（非空 + 格式）
- [x] 用户名（选填）验证
- [x] 按钮加载状态 + 输入框禁用
- [x] "已有账号？登录"链接跳转 `/login`
- [x] 与登录页面风格一致（Logo、布局、颜色、组件）
- [x] 所有文本通过 AppLocalizations 国际化
- [x] 响应式布局适配桌面/平板/移动端
- [x] `flutter analyze --fatal-infos` 零警告
