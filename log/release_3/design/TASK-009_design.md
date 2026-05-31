# TASK-009 详细设计：登录页面真实 UI

## 文档信息

| 属性 | 内容 |
|------|------|
| **任务 ID** | TASK-009 |
| **任务名称** | 登录页面真实 UI |
| **Sprint** | Sprint 2 — M1 认证与身份管理 |
| **依赖** | TASK-004 (路由系统), TASK-007 (可复用组件), TASK-008 (Auth Provider) |
| **设计参考** | `M1_auth_design.txt` (Figma 原型), `M1_auth_spec.md` (设计规格) |
| **日期** | 2026-05-31 |
| **状态** | 待评审 |

---

## 1. 页面概述

登录页面 (`/login`) 是 Kayak 平台的入口页面，提供邮箱+密码认证方式。

### 页面状态机

```
┌─────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  初始    │────▶│   输入邮箱    │────▶│   输入密码    │────▶│   点击登录    │
│  表单空  │     │              │     │              │     │              │
└─────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                  │
                                                     ┌────────────┘
                                                     ▼
                                              ┌──────────────┐
                                              │   提交中      │
                                              │  Loading 状态 │
                                              └──────┬───────┘
                                                     │
                                           ┌─────────┴──────────┐
                                           ▼                    ▼
                                    ┌──────────────┐   ┌──────────────┐
                                    │   登录成功    │   │   登录失败    │
                                    │   跳转首页    │   │   显示错误    │
                                    └──────────────┘   └──────────────┘
```

### 状态定义

| 状态 | 触发条件 | 视觉表现 | 交互限制 |
|------|----------|----------|----------|
| **初始** | 页面加载 | 表单清空，按钮默认，邮箱获得焦点 | 无限制 |
| **输入中** | 用户输入 | 对应字段激活，Label 上浮 | 无限制 |
| **就绪** | 邮箱+密码非空 | 按钮可点击 | 无限制 |
| **提交中** | 点击登录 | 按钮显示 CircularProgressIndicator，输入框禁用，注册链接禁用 | 禁止所有输入 |
| **成功** | 后端返回 200 | 自动重定向到 `/dashboard` | 无 |
| **错误** | 后端返回 4xx/5xx | 显示 ErrorView，密码清空 | 可重新输入 |

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
                          ├── EmailField (Email 输入框)
                          │    ├── TextEditingController
                          │    ├── InputDecoration (email_outlined prefix icon)
                          │    └── FormFieldValidator (非空验证)
                          │
                          ├── PasswordField (密码输入框)
                          │    ├── TextEditingController
                          │    ├── InputDecoration (lock_outlined prefix, visibility toggle suffix)
                          │    └── obscureText (可切换)
                          │
                          ├── LoginButton (登录按钮)
                          │    ├── CircularProgressIndicator (isLoading 时显示)
                          │    └── onPressed: _handleLogin (isLoading 时禁用)
                          │
                          └── RegisterLink (注册链接)
                               └── TextButton → navigate to /register
```

### 响应式布局

| 断点 | 范围 | 布局行为 |
|------|------|----------|
| Mobile | < 600px | 全屏填充，无卡片效果，24px padding |
| Tablet | 600px-1024px | 居中卡片 maxWidth 420px |
| Desktop | > 1024px | 居中卡片 maxWidth 420px |

---

## 3. 数据流

```
User Input
    │
    ▼
TextEditingController (本地状态)
    │
    ▼
Form.validate() (非空验证)
    │
    ▼  (验证通过)
_handleLogin()
    │
    ▼
ref.read(authProvider.notifier).login(email, password)
    │
    ├── AuthNotifier.login()
    │    ├── state = AsyncLoading()          → UI: 按钮 loading, 输入框禁用
    │    ├── authService.login(email, pw)    → API POST /api/v1/auth/login
    │    ├── 成功: state = AsyncData(user)   → UI: Router 重定向到 /dashboard
    │    └── 失败: state = AsyncError(msg)   → UI: ErrorView 显示错误
    │
    └── AuthNotifier 错误处理
         ├── DioException → 映射为友好消息
         ├── 400/401: "邮箱或密码错误"
         ├── 网络错误: "网络连接失败，请检查网络后重试"
         └── 5xx: "服务暂时不可用，请稍后再试"
```

---

## 4. 共享组件设计 (auth_widgets.dart)

### EmailField

```dart
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;
}
```

| 属性 | 值 |
|------|-----|
| Label | "Email" (国际化) |
| Prefix Icon | `Icons.email_outlined` (24px) |
| Keyboard Type | `TextInputType.emailAddress` |
| Autofill Hints | `AutofillHints.email` |
| 验证规则 | 非空 |

### PasswordField

```dart
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;
}
```

| 属性 | 值 |
|------|-----|
| Label | "Password" (国际化) |
| Prefix Icon | `Icons.lock_outlined` (24px) |
| Suffix Icon | 切换 `visibility` / `visibility_off` |
| Obscure Text | true (默认) |
| Autofill Hints | `AutofillHints.password` |
| 验证规则 | 非空 |

### AuthSubmitButton

```dart
class AuthSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
}
```

| 属性 | 值 |
|------|-----|
| Style | FilledButton (Material 3) |
| 高度 | 48px |
| 宽度 | 100% |
| 圆角 | 8px |
| Loading | CircularProgressIndicator (24px, strokeWidth: 2) |

---

## 5. 国际化 (AppLocalizations)

需要使用的本地化 key:

| Key | 英文 | 中文 |
|-----|------|------|
| `appTitle` | Kayak | Kayak |
| `login` | Login | 登录 |
| `email` | Email | 邮箱 |
| `emailHint` | Please enter your email | 请输入邮箱地址 |
| `password` | Password | 密码 |
| `passwordHint` | Please enter your password | 请输入密码 |
| `emailRequired` | Email is required | 请输入邮箱地址 |
| `passwordRequired` | Password is required | 请输入密码 |
| `loginError` | Invalid email or password | 邮箱或密码错误 |
| `networkError` | Network error, please check your connection | 网络连接失败，请检查网络后重试 |
| `noAccount` | Don't have an account? Register | 还没有账号？立即注册 |

> 注：`emailHint`, `passwordHint`, `emailRequired`, `passwordRequired`, `noAccount` 为新增 key，需添加到 ARB 文件。

---

## 6. 序列图

```
User                    LoginPage                    AuthNotifier              AuthService
 │                        │                              │                        │
 │  输入邮箱/密码          │                              │                        │
 │──────────────────────▶│                              │                        │
 │                        │                              │                        │
 │  点击登录              │                              │                        │
 │──────────────────────▶│                              │                        │
 │                        │  state = AsyncLoading()      │                        │
 │                        │─────────────────────────────▶│                        │
 │                        │                              │                        │
 │   按钮显示 Loading     │                              │                        │
 │◀──────────────────────│                              │                        │
 │   输入框禁用           │                              │                        │
 │                        │                              │  login(email, pw)      │
 │                        │                              │──────────────────────▶│
 │                        │                              │                        │ POST /api/v1/auth/login
 │                        │                              │                        │──────────────────▶
 │                        │                              │                        │
 │                        │                              │     ◀──────────────────│
 │                        │                              │     Token + User       │
 │                        │  state = AsyncData(user)     │                        │
 │                        │◀─────────────────────────────│                        │
 │                        │                              │                        │
 │   重定向 /dashboard    │                              │                        │
 │◀──────────────────────│                              │                        │
 │                        │                              │                        │
 │   (OR 错误情况)        │                              │                        │
 │                        │  state = AsyncError(msg)     │                        │
 │                        │◀─────────────────────────────│                        │
 │                        │                              │                        │
 │   显示 ErrorView       │                              │                        │
 │◀──────────────────────│                              │                        │
```

---

## 7. 设计决策记录

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| Widget 类型 | ConsumerWidget / ConsumerStatefulWidget | **ConsumerStatefulWidget** | 需要 TextEditingController 和 Form 状态管理 |
| 状态读取 | ref.watch(authProvider) | **ref.watch** | 实时响应认证状态变化 |
| Loading 指示 | 按钮内 CircularProgressIndicator / 全屏遮罩 | **按钮内** | 减少干扰，UX 更流畅 |
| 错误展示 | Dialog / SnackBar / Inline ErrorView | **Inline ErrorView** | 不阻断操作，用户可即时重试 |
| 密码切换 | StatefulWidget 内部状态 / Provider | **StatefulWidget setState** | 纯 UI 状态，无需 Provider |
| 表单验证 | 实时验证 / 提交时验证 | **提交时验证** | 登录表单简单，非空即可 |
| 响应式 | LayoutBuilder / MediaQuery | **MediaQuery** | 页面级响应，简单可靠 |

---

## 8. 验收标准检查

- [x] 邮箱、密码为空时按钮处于可点击状态（非空验证在提交时）
- [x] 登录失败显示具体原因（非技术错误）
- [x] 登录成功后跳转首页（由 Router 守卫处理）
- [x] 按钮 loading 状态下输入框禁用
- [x] 密码可显示/隐藏切换
- [x] 响应式布局适配桌面/平板/移动端
- [x] 所有文本通过 AppLocalizations 国际化
- [x] ErrorView 使用 TASK-007 组件
- [x] 注册链接跳转 `/register`
- [x] `flutter analyze --fatal-infos` 零警告
