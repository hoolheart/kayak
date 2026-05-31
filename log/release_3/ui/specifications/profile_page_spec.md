# TASK-011: 个人资料页面 — 设计规格文档

## 文档信息

- **任务**: TASK-011 — 个人资料页面
- **页面**: `/profile`
- **目标平台**: Flutter Web（桌面优先，兼容平板、移动端）
- **设计系统**: Material Design 3
- **版本**: v1.0
- **日期**: 2025-05-31
- **状态**: 设计稿完成，等待评审
- **依赖设计令牌**: `M1_auth_spec.md`（颜色、间距、排版、阴影）
- **依赖组件库**: `reusable_components_spec.md`（Toast、ConfirmDialog、AsyncValueWidget）

---

## 目录

1. [用户流程](#用户流程)
2. [页面状态机](#页面状态机)
3. [页面布局](#页面布局)
4. [设计令牌引用](#设计令牌引用)
5. [组件规范](#组件规范)
6. [交互细节](#交互细节)
7. [响应式规范](#响应式规范)
8. [无障碍要求](#无障碍要求)
9. [设计 QA 检查项](#设计-qa-检查项)

---

## 用户流程

### 访问个人资料页

```
┌─────────┐     ┌─────────────────┐     ┌─────────────────┐
│  点击   │────▶│   加载用户信息   │────▶│   显示资料页    │
│用户头像 │     │  (AsyncValue)   │     │  默认: 只读视图  │
│(导航栏) │     │                 │     │                 │
└─────────┘     └─────────────────┘     └─────────────────┘
                                                  │
          ┌───────────────────────────────────────┼───────────────────────────────┐
          │                                       │                               │
  ┌───────▼────────┐                    ┌─────────▼─────────┐            ┌─────────▼─────────┐
  │  编辑用户名     │                    │   修改密码区域     │            │   加载/错误状态    │
  │                │                    │   (可展开)         │            │   (Skeleton/      │
  │ 1. 点击编辑按钮  │                    │                    │            │    ErrorView)      │
  │ 2. 输入新用户名  │                    │ 1. 点击展开        │            │                    │
  │ 3. 点击保存     │                    │ 2. 输入当前密码    │            │                    │
  │ 4. Toast 成功   │                    │ 3. 输入新密码      │            │                    │
  │    / 错误提示   │                    │ 4. 确认新密码      │            │                    │
  └────────────────┘                    │ 5. 点击保存        │            │                    │
                                        │ 6. Toast 成功      │            │                    │
                                        │    / 错误提示      │            │                    │
                                        └────────────────────┘            └────────────────────┘
```

**详细步骤：**

1. **用户通过导航栏头像菜单进入 `/profile`**
   - 页面加载，显示用户信息骨架屏（Skeleton）
   - 发送 GET `/api/v1/users/me` 请求
   - 等待后端响应

2. **数据加载成功**
   - 显示用户信息卡片（头像、用户名、邮箱、注册时间）
   - 用户名区域默认只读，显示编辑按钮
   - 密码修改区域默认收起

3. **用户编辑用户名**
   - 点击编辑按钮，用户名变为输入框
   - 输入框自动获得焦点，全选现有内容
   - 实时验证输入合法性
   - 点击保存按钮提交 PATCH `/api/v1/users/me`
   - 成功：显示成功 Toast，用户名更新，恢复只读状态
   - 失败：显示错误提示，保留输入框状态

4. **用户修改密码**
   - 点击密码区域展开按钮
   - 区域展开动画（高度展开 200ms）
   - 输入当前密码、新密码、确认新密码
   - 新密码实时强度检测（复用 M1 密码强度指示器）
   - 点击保存按钮提交 PATCH `/api/v1/users/me/password`
   - 成功：显示成功 Toast，区域自动收起，清空密码输入
   - 失败：显示字段级错误提示

5. **数据加载失败**
   - 显示 ErrorView，提供重试按钮
   - 重试后重新加载用户信息

---

## 页面状态机

### 页面级状态

| 状态 | 触发条件 | 视觉表现 | 交互限制 |
|------|----------|----------|----------|
| **加载中** | 页面初始化 | 显示 Skeleton 骨架屏 | 禁止所有编辑操作 |
| **只读** | 数据加载成功，无编辑操作 | 用户名只读，密码区域收起 | 可点击编辑/展开 |
| **编辑用户名** | 点击编辑按钮 | 用户名变为输入框，显示保存/取消 | 密码区域禁用 |
| **编辑密码** | 展开密码区域 | 密码区域展开，显示三个输入框 | 用户名区域禁用 |
| **同时编辑** | — | 不允许 | — |
| **保存中** | 点击保存按钮 | 按钮加载状态，对应区域禁用 | 禁止该区域输入 |
| **错误** | API 返回错误 | 显示错误 Alert 或字段错误 | 可修正后重试 |

### 用户名编辑子状态

| 状态 | 触发条件 | 视觉表现 |
|------|----------|----------|
| **初始** | 进入编辑模式 | 输入框显示当前用户名，全选 |
| **输入中** | 用户输入 | 实时验证，保存按钮可用性更新 |
| **无效** | 输入不满足规则 | 输入框 Error 状态，显示错误提示 |
| **提交中** | 点击保存 | 按钮 Loading，输入框禁用 |
| **成功** | API 返回 200 | Toast 成功，恢复只读，显示新用户名 |
| **失败** | API 返回错误 | 保留输入框，显示错误提示 |

### 密码修改子状态

| 状态 | 触发条件 | 视觉表现 |
|------|----------|----------|
| **收起** | 默认/修改成功 | 区域折叠，显示展开按钮 |
| **展开中** | 点击展开 | 高度动画展开 (200ms) |
| **展开** | 动画完成 | 显示三个密码输入框 |
| **输入中** | 用户输入 | 实时验证，强度指示器更新 |
| **无效** | 输入不满足规则 | 对应输入框 Error 状态 |
| **提交中** | 点击保存 | 按钮 Loading，输入框禁用 |
| **成功** | API 返回 200 | Toast 成功，区域收起，清空输入 |
| **失败** | API 返回错误 | 保留输入，显示字段/全局错误 |
| **收起中** | 点击收起/成功 | 高度动画收缩 (200ms) |

---

## 页面布局

### 整体结构

```
┌─────────────────────────────────────────────────────────────┐
│  App Bar                                                    │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │                                             │   │   │
│  │  │           ┌───────────────┐                 │   │   │
│  │  │           │   [Avatar]    │                 │   │   │
│  │  │           │   80×80px     │                 │   │   │
│  │  │           │   placeholder │                 │   │   │
│  │  │           └───────────────┘                 │   │   │
│  │  │                                             │   │   │
│  │  │         用户名 (只读/编辑)                   │   │   │
│  │  │         user@example.com                    │   │   │
│  │  │         注册于 2024-01-15                   │   │   │
│  │  │                                             │   │   │
│  │  │  ┌─────────────────────────────────────┐   │   │   │
│  │  │  │  修改密码 ▼                         │   │   │   │
│  │  │  │                                     │   │   │   │
│  │  │  │  [当前密码输入框]                    │   │   │   │
│  │  │  │  [新密码输入框]                      │   │   │   │
│  │  │  │  [确认新密码输入框]                  │   │   │   │
│  │  │  │  [密码强度指示器]                    │   │   │   │
│  │  │  │  [保存密码修改按钮]                  │   │   │   │
│  │  │  └─────────────────────────────────────┘   │   │   │
│  │  │                                             │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 布局层次

```dart
Scaffold
├── AppBar
│   ├── Leading: BackButton (if can pop)
│   ├── Title: "个人资料" (Title Large)
│   └── Actions: [] (空)
│
└── Body
    └── Center (桌面) / Align.topCenter (移动)
        └── SingleChildScrollView
            └── Padding (按断点)
                └── ConstrainedBox (maxWidth: 按断点)
                    └── Column
                        ├── SizedBox (顶部间距)
                        ├── UserInfoCard (用户信息卡片)
                        │   ├── AvatarSection (头像区)
                        │   ├── UserNameSection (用户名区)
                        │   ├── EmailDisplay (邮箱显示)
                        │   └── JoinDateDisplay (注册时间)
                        ├── SizedBox (间距)
                        ├── PasswordChangeSection (密码修改区)
                        │   ├── ExpansionTile (展开/收起)
                        │   │   ├── CurrentPasswordField
                        │   │   ├── NewPasswordField
                        │   │   ├── ConfirmPasswordField
                        │   │   ├── PasswordStrengthIndicator
                        │   │   └── SavePasswordButton
                        └── SizedBox (底部间距)
```

---

## 设计令牌引用

> 完整设计令牌定义见 `M1_auth_spec.md`。本文档仅列出页面特有或高频使用的令牌。

### 颜色（Light / Dark）

| 语义 | Light | Dark | 用途 |
|------|-------|------|------|
| Primary | `#1976D2` | `#90CAF9` | 保存按钮、编辑按钮、链接 |
| On Primary | `#FFFFFF` | `#003258` | 按钮文字 |
| Background | `#FDFCFF` | `#1A1C1E` | 页面背景 |
| On Background | `#1A1C1E` | `#E2E2E6` | 页面标题、主要文字 |
| Surface | `#FFFFFF` | `#1A1C1E` | 卡片背景 |
| On Surface | `#1A1C1E` | `#E2E2E6` | 卡片内主要文字 |
| On Surface Variant | `#43474E` | `#C4C6CF` | 次要文字、图标、辅助信息 |
| Surface Variant | `#EFF3FA` | `#43474E` | 头像背景、输入框背景 |
| Outline | `#74777F` | `#8E9099` | 边框、分割线 |
| Error | `#BA1A1A` | `#FFB4AB` | 错误状态 |
| Error Container | `#FFDAD6` | `#93000A` | 错误提示背景 |
| On Error Container | `#410002` | `#FFDAD6` | 错误提示文字 |
| Success | `#2E7D32` | `#81C784` | 成功提示 |

### 间距

| 令牌 | 值 | 用途 |
|------|-----|------|
| spaceXs | 4px | 图标与文字间距、紧凑间距 |
| spaceSm | 8px | 元素间小间距 |
| spaceMd | 16px | 卡片内边距、表单元素间距 |
| spaceLg | 24px | 区域间距 |
| spaceXl | 32px | 大区域间距 |
| spaceXxl | 48px | 页面顶部间距 |

### 排版

| 令牌 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| titleLarge | 22px | 400 | 28px | 页面标题（AppBar） |
| titleMedium | 16px | 500 | 24px | 区域标题、用户名 |
| bodyLarge | 16px | 400 | 24px | 邮箱、主要信息 |
| bodyMedium | 14px | 400 | 20px | 注册时间、辅助信息 |
| labelLarge | 14px | 500 | 20px | 按钮文字 |
| labelMedium | 12px | 500 | 16px | 标签、提示 |

### 圆角

| 令牌 | 值 | 用途 |
|------|-----|------|
| radiusSmall | 4px | 小元素、输入框 |
| radiusMedium | 8px | 按钮、卡片 |
| radiusLarge | 12px | 大卡片 |
| radiusXxlarge | 24px | 头像背景（圆形裁剪） |

---

## 组件规范

### 1. 用户信息卡片 (UserInfoCard)

#### 整体规格

| 属性 | 值 |
|------|-----|
| 容器 | Card (Material 3) |
| 背景 | Surface |
| 宽度 | 100%（在约束容器内） |
| 最大宽度 | 600px（桌面）/ 100%（移动） |
| 内边距 | spaceXl (32px) 桌面 / spaceLg (24px) 移动 |
| 圆角 | radiusLarge (12px) |
| 阴影 | elevation1 |
| 内容对齐 | 水平居中 |

#### 1.1 头像区域 (AvatarSection)

| 属性 | 值 |
|------|-----|
| 组件 | CircleAvatar |
| 尺寸 | 80×80px（桌面）/ 64×64px（移动） |
| 背景色 | Surface Variant |
| 前景图标 | Icons.person (48px 桌面 / 40px 移动) |
| 前景颜色 | On Surface Variant |
| 下边距 | spaceLg (24px) |
| 边框 | 2px solid Outline at 30% opacity |

**状态：**

| 状态 | 视觉表现 |
|------|----------|
| **默认** | 显示占位图标 |
| **Hover** | 边框颜色变为 Primary at 50% |
| **加载中** | 显示圆形 Skeleton 占位 |

#### 1.2 用户名区域 (UserNameSection)

**只读状态：**

| 属性 | 值 |
|------|-----|
| 布局 | Row，主居中对齐 |
| 用户名文字 | Title Medium, On Surface |
| 编辑按钮 | IconButton，Icons.edit_outlined (20px) |
| 编辑按钮颜色 | Primary |
| 编辑按钮左边距 | spaceSm (8px) |
| 编辑按钮触摸区域 | 48×48dp |

**编辑状态：**

| 属性 | 值 |
|------|-----|
| 布局 | Column |
| 输入框 | Outlined TextField（复用 M1 规格） |
| 输入框标签 | "用户名" |
| 输入框前缀图标 | Icons.person_outlined |
| 输入框宽度 | 100%（在卡片内） |
| 最大长度 | 30 字符 |
| 验证规则 | 3-30 字符，字母/数字/下划线/连字符 |
| 错误提示 | "用户名长度需在 3-30 字符之间，仅允许字母、数字、下划线、连字符" |
| 按钮行上边距 | spaceMd (16px) |
| 按钮行布局 | Row，右对齐 |
| 取消按钮 | Text Button，"取消" |
| 保存按钮 | Filled Button，"保存" |
| 按钮间距 | spaceSm (8px) |

**编辑状态交互：**

| 状态 | 视觉表现 |
|------|----------|
| **初始** | 输入框显示当前用户名，文字全选 |
| **输入中** | 实时验证，合法时保存按钮可用 |
| **无效** | 输入框 Error 状态，底部显示错误文字 |
| **提交中** | 保存按钮 Loading，输入框禁用 |
| **成功** | 淡出编辑区 (150ms)，淡入只读区 (150ms)，显示新用户名 |
| **取消** | 直接恢复只读状态，不做任何修改 |

#### 1.3 邮箱显示 (EmailDisplay)

| 属性 | 值 |
|------|-----|
| 布局 | Row，居中 |
| 图标 | Icons.email_outlined (16px) |
| 图标颜色 | On Surface Variant |
| 图标右边距 | spaceXs (4px) |
| 邮箱文字 | Body Large, On Surface Variant |
| 上边距 | spaceSm (8px) |

#### 1.4 注册时间显示 (JoinDateDisplay)

| 属性 | 值 |
|------|-----|
| 布局 | Row，居中 |
| 图标 | Icons.calendar_today_outlined (16px) |
| 图标颜色 | On Surface Variant |
| 图标右边距 | spaceXs (4px) |
| 时间文字 | Body Medium, On Surface Variant |
| 文字格式 | "注册于 YYYY-MM-DD" |
| 上边距 | spaceXs (4px) |

---

### 2. 密码修改区域 (PasswordChangeSection)

#### 整体规格

| 属性 | 值 |
|------|-----|
| 容器 | Card (Material 3) 或用户信息卡片的子区域 |
| 上边距 | spaceLg (24px) |
| 内边距 | 同用户信息卡片 |
| 圆角 | radiusLarge (12px) |
| 阴影 | elevation1 |

#### 2.1 展开/收起头部 (ExpansionHeader)

| 属性 | 值 |
|------|-----|
| 布局 | ListTile 或自定义 Row |
| 头部图标 | Icons.lock_outlined (24px) |
| 头部图标颜色 | On Surface Variant |
| 标题 | "修改密码" — Body Large, On Surface |
| 副标题 | "更改您的登录密码" — Body Medium, On Surface Variant |
| 展开图标 | Icons.expand_more / Icons.expand_less |
| 展开图标颜色 | On Surface Variant |
| 分割线 | 底部 1px Outline at 30%（展开时显示） |
| 触摸区域 | 整个头部区域 |

**状态：**

| 状态 | 视觉表现 |
|------|----------|
| **收起** | 显示头部，无内容区域 |
| **Hover** | 头部背景变为 Surface Variant at 50% |
| **展开中** | 图标旋转 180° (200ms)，内容区域高度展开 |
| **收起中** | 图标旋转 0° (200ms)，内容区域高度收缩 |
| **展开** | 显示完整表单 |

#### 2.2 密码输入框组

**当前密码输入框：**

| 属性 | 值 |
|------|-----|
| 样式 | Outlined TextField |
| 标签 | "当前密码" |
| 前缀图标 | Icons.lock_outlined |
| 后缀图标 | Icons.visibility_off_outlined / Icons.visibility_outlined |
| Obscure Text | true（默认） |
| 验证规则 | 非空 |
| 错误提示 | "请输入当前密码" |
| 上边距 | spaceMd (16px)（展开后第一个元素） |

**新密码输入框：**

| 属性 | 值 |
|------|-----|
| 样式 | Outlined TextField |
| 标签 | "新密码" |
| 前缀图标 | Icons.lock_outline |
| 后缀图标 | Icons.visibility_off_outlined / Icons.visibility_outlined |
| Obscure Text | true（默认） |
| 实时验证 | 密码强度检测（复用 M1 密码强度指示器） |
| 验证规则 | 至少 8 字符，至少 2 种字符类型 |
| 错误提示 | "密码长度至少 8 位，需包含字母和数字" |
| 上边距 | spaceMd (16px) |

**确认新密码输入框：**

| 属性 | 值 |
|------|-----|
| 样式 | Outlined TextField |
| 标签 | "确认新密码" |
| 前缀图标 | Icons.lock_outline |
| 后缀图标 | Icons.visibility_off_outlined / Icons.visibility_outlined |
| Obscure Text | true（默认） |
| 验证规则 | 必须与新密码一致 |
| 错误提示 | "两次输入的密码不一致" |
| 上边距 | spaceMd (16px) |

#### 2.3 密码强度指示器

> 复用 M1 认证页面的密码强度指示器组件。

| 属性 | 值 |
|------|-----|
| 位置 | 新密码输入框下方 |
| 上边距 | spaceSm (8px) |
| 规格 | 同 `M1_auth_spec.md` 密码强度指示器 |

**显示规则：**
- 新密码输入框有输入时显示
- 新密码输入框为空时隐藏

#### 2.4 保存密码按钮

| 属性 | 值 |
|------|-----|
| 样式 | Filled Button |
| 文字 | "保存密码修改" |
| 高度 | 48px |
| 宽度 | 100%（填满卡片宽度） |
| 上边距 | spaceLg (24px) |
| 下边距 | spaceMd (16px) |
| 禁用条件 | 任一输入框为空 / 新密码不符合规则 / 两次密码不一致 |

**状态：**

| 状态 | 视觉表现 |
|------|----------|
| **默认** | Primary 背景，不可用（禁用条件满足时） |
| **可用** | Primary 背景，可点击 |
| **Hover** | Primary Hover 色，elevation1 |
| **Pressed** | Primary Pressed 色，scale(0.98) |
| **提交中** | Loading 状态，CircularProgressIndicator (24px) |
| **成功** | 触发区域收起，显示成功 Toast |

---

### 3. 页面级反馈组件

#### 3.1 成功 Toast

| 属性 | 值 |
|------|-----|
| 类型 | Success Toast（复用 `reusable_components_spec.md`） |
| 文案（用户名） | "用户名修改成功" |
| 文案（密码） | "密码修改成功，请使用新密码登录" |
| 位置 | 桌面右上角 / 移动底部居中 |
| 自动消失 | 3 秒 |

#### 3.2 错误提示

**全局错误（Alert Banner）：**

| 属性 | 值 |
|------|-----|
| 类型 | Error Banner |
| 位置 | 用户信息卡片顶部 |
| 样式 | 同 `M1_auth_spec.md` Alert Banner |
| 文案（通用） | "操作失败，请稍后重试" |
| 文案（当前密码错误） | "当前密码不正确，请重新输入" |
| 文案（网络错误） | "网络连接异常，请检查网络后重试" |

**字段级错误：**

| 属性 | 值 |
|------|-----|
| 位置 | 对应输入框下方 |
| 样式 | Material TextField Error 状态 |
| 显示时机 | 失去焦点验证 + 提交时验证 |

#### 3.3 加载状态 (Skeleton)

| 属性 | 值 |
|------|-----|
| 类型 | 自定义 Profile Skeleton |
| 头像占位 | 圆形，80px，Surface Variant |
| 用户名占位 | 矩形，120×16px，radiusSmall |
| 邮箱占位 | 矩形，180×14px，radiusSmall |
| 注册时间占位 | 矩形，100×14px，radiusSmall |
| 间距 | 与真实布局一致 |
| 动画 | shimmer 效果 |

---

## 交互细节

### 编辑用户名交互

| 操作 | 行为 |
|------|------|
| **点击编辑按钮** | 1. 只读用户名淡出 (100ms)<br>2. 编辑输入框淡入 (150ms)<br>3. 输入框自动获得焦点<br>4. 现有用户名全选 |
| **输入框按 Enter** | 触发保存（如果输入合法） |
| **输入框按 Escape** | 取消编辑，恢复只读 |
| **点击取消按钮** | 立即恢复只读状态，不保存 |
| **点击保存按钮** | 1. 按钮进入 Loading<br>2. 发送 PATCH 请求<br>3. 成功：显示 Toast，恢复只读<br>4. 失败：显示错误，保留编辑状态 |
| **失去焦点（输入框外点击）** | 不做自动保存，保持编辑状态（防止误触丢失输入） |

### 密码区域交互

| 操作 | 行为 |
|------|------|
| **点击展开** | 1. 图标旋转 180° (200ms)<br>2. 内容区域高度从 0 展开到自适应 (200ms, ease-out)<br>3. 第一个输入框（当前密码）获得焦点 |
| **点击收起** | 1. 图标旋转 0° (200ms)<br>2. 内容区域高度收缩到 0 (200ms, ease-in)<br>3. 如果有未保存输入，弹出 ConfirmDialog 确认是否丢弃 |
| **新密码输入** | 实时更新密码强度指示器 |
| **点击保存** | 1. 完整验证三个输入框<br>2. 按钮 Loading<br>3. 发送 PATCH 请求<br>4. 成功：Toast + 收起区域 + 清空输入<br>5. 失败：显示错误提示 |
| **密码修改成功** | 1. 显示成功 Toast（提示使用新密码）<br>2. 区域自动收起<br>3. 所有密码输入框清空 |

### 确认对话框（密码区域收起时）

| 属性 | 值 |
|------|-----|
| 触发条件 | 密码区域有未保存输入时点击收起 |
| 标题 | "放弃修改？" |
| 描述 | "您有未保存的密码修改，确定要放弃吗？" |
| 取消按钮 | Text Button，"继续编辑" |
| 确认按钮 | Filled Button (Error 色)，"放弃" |
| 确认后行为 | 收起区域，清空所有密码输入 |

### 键盘导航

| 按键 | 行为 |
|------|------|
| **Tab** | 按逻辑顺序在可聚焦元素间移动 |
| **Shift+Tab** | 反向导航 |
| **Enter** | 触发当前聚焦按钮 / 提交表单 |
| **Escape** | 取消当前编辑模式 |

### 自动填充

| 字段 | Autofill Hint |
|------|---------------|
| 当前密码 | `AutofillHints.password` |
| 新密码 | `AutofillHints.newPassword` |
| 确认新密码 | `AutofillHints.newPassword` |

---

## 响应式规范

### 断点定义

复用 M1 断点：

```dart
static const double breakpointMobile = 600.0;
static const double breakpointTablet = 1024.0;
```

### 布局规则

#### Mobile (< 600px)

| 属性 | 值 |
|------|-----|
| 页面背景 | Background |
| 卡片 | 全宽，无外边距 |
| 卡片内边距 | spaceLg (24px) |
| 卡片圆角 | 0（全屏贴边）或 radiusMedium (8px)（如有边距） |
| 卡片阴影 | 无 |
| 头像尺寸 | 64×64px |
| 用户名字号 | titleMedium (16px) |
| 页面顶部间距 | spaceLg (24px) |
| 垂直对齐 | 顶部对齐 |
| 输入框宽度 | 100% |
| 按钮宽度 | 100% |

#### Tablet (600px - 1024px)

| 属性 | 值 |
|------|-----|
| 页面背景 | Background |
| 卡片 | 居中，maxWidth 560px |
| 卡片外边距 | 水平 spaceMd (16px) |
| 卡片内边距 | spaceXl (32px) |
| 卡片圆角 | radiusLarge (12px) |
| 卡片阴影 | elevation1 |
| 头像尺寸 | 72×72px |
| 用户名字号 | titleMedium (16px) |
| 页面顶部间距 | spaceXxl (48px) |
| 垂直对齐 | 顶部对齐（可滚动） |
| 输入框宽度 | 100% |
| 按钮宽度 | 100% |

#### Desktop (> 1024px)

| 属性 | 值 |
|------|-----|
| 页面背景 | Background |
| 卡片 | 居中，maxWidth 600px |
| 卡片外边距 | 无（居中） |
| 卡片内边距 | spaceXl (32px) |
| 卡片圆角 | radiusLarge (12px) |
| 卡片阴影 | elevation2 |
| 头像尺寸 | 80×80px |
| 用户名字号 | titleMedium (16px) |
| 页面顶部间距 | spaceXxl (48px) |
| 垂直对齐 | 顶部对齐（可滚动） |
| 输入框宽度 | 100% |
| 按钮宽度 | 100% |

### 响应式组件调整

| 组件 | Mobile | Tablet | Desktop |
|------|--------|--------|---------|
| 卡片最大宽度 | 100% | 560px | 600px |
| 卡片内边距 | 24px | 32px | 32px |
| 卡片圆角 | 0 | 12px | 12px |
| 卡片阴影 | 无 | Level 1 | Level 2 |
| 头像尺寸 | 64px | 72px | 80px |
| 头像下边距 | 16px | 20px | 24px |
| 表单元素间距 | 16px | 16px | 16px |
| 按钮高度 | 48px | 48px | 48px |
| 页面顶部间距 | 24px | 48px | 48px |
| 编辑按钮尺寸 | 20px | 20px | 20px |

---

## 无障碍要求

### WCAG 2.1 AA 合规

#### 对比度

| 元素 | 要求 | 实际 |
|------|------|------|
| 用户名文字 (On Surface) | 4.5:1 | ~15:1 |
| 邮箱/注册时间 (On Surface Variant) | 4.5:1 | ~7:1 |
| 输入框边框 (Outline) | 3:1 | ~4.5:1 |
| 按钮文字 (On Primary) | 4.5:1 | ~7:1 |
| 错误提示 | 4.5:1 | ~7:1 |

#### 键盘导航

- **Tab 顺序**: AppBar → 用户名编辑按钮 → 密码展开头部 → 当前密码 → 新密码 → 确认密码 → 保存按钮
- **焦点可见**: 2px Primary 色 outline，offset 2px
- **Escape 键**: 取消当前编辑模式
- **Enter 键**: 提交当前表单

#### 屏幕阅读器支持

| 元素 | ARIA 属性 / 语义 |
|------|-----------------|
| 页面标题 | `aria-label="个人资料"` |
| 头像 | `aria-label="用户头像"` |
| 用户名（只读） | `aria-label="用户名: {name}"` |
| 编辑按钮 | `aria-label="编辑用户名"` |
| 邮箱 | `aria-label="邮箱: {email}"` |
| 注册时间 | `aria-label="注册时间: {date}"` |
| 密码展开头部 | `aria-expanded="true/false"`, `aria-controls="password-section"` |
| 当前密码输入 | `aria-required="true"`, `autocomplete="current-password"` |
| 新密码输入 | `aria-required="true"`, `autocomplete="new-password"` |
| 确认密码输入 | `aria-required="true"`, `autocomplete="new-password"` |
| 密码强度 | `aria-live="polite"`, `aria-label="密码强度: {level}"` |
| 保存按钮 | `aria-busy="true"`（加载时） |
| 错误提示 | `role="alert"`, `aria-live="assertive"` |

#### 语义化 HTML

- 使用 `<main>` 包裹主要内容
- 使用 `<section>` 区分用户信息区和密码修改区
- 使用 `<h1>` 作为页面标题（或语义化标题结构）
- 表单区域使用 `<form>` 包裹

### 触控与手势

- **触摸目标**: 所有交互元素最小 48×48dp
  - 编辑按钮：48×48dp
  - 展开/收起头部：最小高度 48dp
  - 密码可见性切换：48×48dp
- **间距**: 相邻触摸目标间距至少 8px

### 动画与动效

- **prefers-reduced-motion**:
  - 禁用展开/收起动画，直接显示/隐藏
  - 禁用编辑/只读切换动画，直接切换
  - 禁用密码强度指示器动画，静态显示
  - 保留 Skeleton shimmer 静态显示（无动画）

---

## 设计 QA 检查项

### 视觉检查

- [ ] 颜色与 Design Token 完全一致
- [ ] 字号、字重、行高正确
- [ ] 间距符合 8px 网格系统
- [ ] 圆角一致（卡片 12px，输入框 8px，头像圆形）
- [ ] 阴影正确（按断点和状态）
- [ ] 图标尺寸和颜色正确
- [ ] 深色主题颜色正确
- [ ] 头像 placeholder 样式正确

### 交互检查

- [ ] 点击编辑按钮进入编辑模式，输入框自动聚焦
- [ ] 编辑模式下保存/取消按钮正确显示
- [ ] 保存按钮在输入无效时禁用
- [ ] 密码区域展开/收起动画流畅
- [ ] 密码强度指示器实时更新
- [ ] 两次密码不一致时显示错误
- [ ] 当前密码错误时显示正确错误提示
- [ ] 成功修改后显示 Toast 并自动收起区域
- [ ] 有未保存输入时收起区域弹出确认对话框
- [ ] 所有 Hover 状态正确
- [ ] 所有 Focus 状态正确（键盘 Tab 测试）
- [ ] 加载状态 Skeleton 显示正确

### 响应式检查

- [ ] Mobile 布局正确（< 600px）：卡片全宽，头像 64px
- [ ] Tablet 布局正确（600px - 1024px）：卡片 maxWidth 560px
- [ ] Desktop 布局正确（> 1024px）：卡片 maxWidth 600px
- [ ] 断点切换无闪烁
- [ ] 横屏/竖屏适配（移动端）

### 无障碍检查

- [ ] 键盘完整导航（Tab / Shift+Tab / Enter / Escape）
- [ ] 焦点指示器可见
- [ ] 屏幕阅读器正确朗读所有元素
- [ ] 对比度符合 WCAG AA
- [ ] 动画可被禁用（prefers-reduced-motion）
- [ ] 触摸目标最小 48dp

### 状态覆盖检查

- [ ] 页面加载中（Skeleton）
- [ ] 数据加载失败（ErrorView）
- [ ] 用户名只读状态
- [ ] 用户名编辑状态
- [ ] 用户名保存中
- [ ] 用户名保存成功
- [ ] 用户名保存失败
- [ ] 密码区域收起状态
- [ ] 密码区域展开状态
- [ ] 密码保存中
- [ ] 密码保存成功
- [ ] 密码保存失败（当前密码错误）
- [ ] 密码保存失败（网络错误）

---

## 附录

### A. 图标清单

| 图标 | 用途 | 尺寸 | 颜色 |
|------|------|------|------|
| person | 头像 placeholder | 48px (桌面) / 40px (移动) | On Surface Variant |
| edit_outlined | 编辑用户名按钮 | 20px | Primary |
| email_outlined | 邮箱前缀图标 | 16px | On Surface Variant |
| calendar_today_outlined | 注册时间前缀图标 | 16px | On Surface Variant |
| lock_outlined | 密码区域头部 / 密码输入框前缀 | 24px | On Surface Variant |
| expand_more | 展开密码区域 | 24px | On Surface Variant |
| expand_less | 收起密码区域 | 24px | On Surface Variant |
| visibility_off_outlined | 密码隐藏 | 24px | On Surface Variant |
| visibility_outlined | 密码显示 | 24px | On Surface Variant |
| check_circle | 密码要求已满足 | 16px | Primary |
| circle_outlined | 密码要求未满足 | 16px | On Surface Variant |

### B. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 400ms | ease-out | 淡入 + 上移 8px |
| 用户名编辑切换 | 150ms | ease-in-out | 淡入淡出 |
| 密码区域展开 | 200ms | ease-out | 高度展开 + 图标旋转 |
| 密码区域收起 | 200ms | ease-in | 高度收缩 + 图标旋转 |
| 按钮 Hover | 200ms | ease-out | 背景变化 |
| 按钮 Pressed | 100ms | ease-out | scale(0.98) |
| 输入框 Focus | 200ms | ease-out | 边框颜色/宽度 |
| Toast 进入 | 300ms | ease-out | 滑入 + 淡入 |
| Toast 离开 | 200ms | ease-in | 滑出 + 淡出 |
| Skeleton shimmer | 1.5s 循环 | linear | 光泽扫过 |
| 对话框进入 | 200ms | ease-out | 缩放淡入 |
| 对话框离开 | 150ms | ease-in | 缩放淡出 |

### C. API 交互参考

| 操作 | 方法 | 端点 | 请求体 | 成功码 |
|------|------|------|--------|--------|
| 获取用户信息 | GET | `/api/v1/users/me` | — | 200 |
| 更新用户名 | PATCH | `/api/v1/users/me` | `{"username": "..."}` | 200 |
| 修改密码 | PATCH | `/api/v1/users/me/password` | `{"current_password": "...", "new_password": "..."}` | 200 |

### D. 参考链接

- [Material Design 3 — Cards](https://m3.material.io/components/cards/overview)
- [Material Design 3 — Text Fields](https://m3.material.io/components/text-fields/overview)
- [Material Design 3 — Buttons](https://m3.material.io/components/buttons/overview)
- [Material Design 3 — Lists](https://m3.material.io/components/lists/overview)
- [M1 认证页面设计规格](./M1_auth_spec.md)
- [可复用组件库规格](./reusable_components_spec.md)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。
