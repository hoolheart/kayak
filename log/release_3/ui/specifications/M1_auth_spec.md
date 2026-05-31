# M1 认证与身份管理 — 设计规格文档

## 文档信息

- **模块**: M1 — 认证与身份管理
- **页面**: 登录页 (`/login`)、注册页 (`/register`)
- **目标平台**: Flutter Web（桌面优先，兼容平板）
- **设计系统**: Material Design 3
- **版本**: v1.0
- **日期**: 2025-05-31
- **状态**: 设计稿完成，等待评审

---

## 目录

1. [用户流程](#用户流程)
2. [页面状态机](#页面状态机)
3. [设计令牌](#设计令牌)
4. [组件规范](#组件规范)
5. [交互细节](#交互细节)
6. [响应式规范](#响应式规范)
7. [无障碍要求](#无障碍要求)
8. [设计 QA 检查项](#设计-qa-检查项)

---

## 用户流程

### 登录流程

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  访问   │────▶│   输入邮箱   │────▶│   输入密码   │────▶│   点击登录   │
│ /login  │     │             │     │             │     │             │
└─────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                               │
                          ┌────────────────────────────────────┘
                          │
              ┌───────────▼───────────┐
              │      验证中...        │
              │   (加载状态 500ms+)   │
              └───────────┬───────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
      ┌───────▼───────┐       ┌───────▼───────┐
      │   登录成功     │       │   登录失败     │
      │   JWT Token   │       │   显示错误     │
      └───────┬───────┘       └───────┬───────┘
              │                       │
      ┌───────▼───────┐       ┌───────▼───────┐
      │  重定向到      │       │  保留输入      │
      │  /dashboard   │       │  密码清空      │
      └───────────────┘       └───────────────┘
```

**详细步骤：**

1. **用户访问 `/login`**
   - 页面加载，显示登录表单
   - 邮箱输入框自动获得焦点（桌面端）
   - 浏览器自动填充提示（如果用户已保存凭据）

2. **用户输入邮箱**
   - 实时格式验证（失去焦点时）
   - 非法格式显示错误提示
   - 自动补全域名建议（可选）

3. **用户输入密码**
   - 默认隐藏显示
   - 可点击眼睛图标切换显示/隐藏
   - 无实时验证（登录时统一验证）

4. **用户点击登录按钮**
   - 按钮进入加载状态
   - 输入框禁用
   - 发送 POST `/api/v1/auth/login` 请求
   - 等待后端响应

5. **登录成功**
   - 保存 JWT Token 到本地存储
   - 设置 Authorization Header
   - 重定向到 `/dashboard`
   - 显示欢迎消息（可选）

6. **登录失败**
   - 显示错误提示（不暴露具体失败原因）
   - 清空密码输入框
   - 密码输入框获得焦点
   - 用户可重新输入

### 注册流程

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  访问   │────▶│   输入邮箱   │────▶│   输入密码   │────▶│ 输入用户名   │
│/register│     │             │     │  (实时强度)  │     │   (选填)    │
└─────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                               │
                          ┌────────────────────────────────────┘
                          │
              ┌───────────▼───────────┐
              │      点击注册         │
              │   表单完整验证        │
              └───────────┬───────────┘
                          │
              ┌───────────▼───────────┐
              │      提交中...        │
              │   (加载状态 500ms+)   │
              └───────────┬───────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
      ┌───────▼───────┐       ┌───────▼───────┐
      │   注册成功     │       │   注册失败     │
      │   显示成功页   │       │   显示错误     │
      └───────┬───────┘       └───────┬───────┘
              │                       │
      ┌───────▼───────┐       ┌───────▼───────┐
      │ 发送验证邮件   │       │  保留输入      │
      │ 引导前往登录   │       │  高亮错误字段  │
      └───────────────┘       └───────────────┘
```

**详细步骤：**

1. **用户访问 `/register`**
   - 页面加载，显示注册表单
   - 邮箱输入框自动获得焦点

2. **用户输入邮箱**
   - 实时格式验证（失去焦点时）
   - 检查邮箱是否已被注册（可选，失去焦点时）
   - 非法格式或已注册显示错误

3. **用户输入密码**
   - 实时密码强度计算
   - 密码强度指示器实时更新
   - 密码要求检查列表实时更新
   - 可切换显示/隐藏

4. **用户输入用户名（选填）**
   - 无强制验证
   - 长度限制：3-30 字符
   - 非法字符提示

5. **用户点击注册按钮**
   - 完整表单验证
   - 按钮进入加载状态
   - 发送 POST `/api/v1/auth/register` 请求

6. **注册成功**
   - 显示成功状态页面
   - 提示验证邮件已发送
   - 提供前往登录页链接
   - 提供重新发送邮件选项

7. **注册失败**
   - 显示具体错误原因
   - 高亮相关字段
   - 保留其他正确输入

---

## 页面状态机

### 登录页状态

| 状态 | 触发条件 | 视觉表现 | 交互限制 |
|------|----------|----------|----------|
| **初始** | 页面加载 | 表单清空，按钮默认 | 无限制 |
| **输入中** | 用户输入任意字段 | 对应字段激活，Label 上浮 | 无限制 |
| **验证中** | 失去焦点（邮箱） | 显示验证状态（可选） | 无限制 |
| **就绪** | 所有必填项有效 | 按钮从禁用变为可用 | 无限制 |
| **提交中** | 点击登录按钮 | 按钮加载，输入框禁用 | 禁止所有输入 |
| **成功** | 后端返回 200 | 短暂显示成功，重定向 | 无 |
| **错误** | 后端返回 4xx/5xx | 显示错误 Alert，密码清空 | 可重新输入 |
| **网络错误** | 请求超时/断开 | 网络错误提示，保留输入 | 可重试 |

### 注册页状态

| 状态 | 触发条件 | 视觉表现 | 交互限制 |
|------|----------|----------|----------|
| **初始** | 页面加载 | 表单清空，密码强度为空 | 无限制 |
| **输入中** | 用户输入任意字段 | 对应字段激活 | 无限制 |
| **密码输入** | 密码框输入 | 强度指示器更新，要求列表更新 | 无限制 |
| **验证中** | 失去焦点（邮箱） | 邮箱格式检查 | 无限制 |
| **就绪** | 所有必填项有效且密码强度≥中 | 按钮可用 | 无限制 |
| **提交中** | 点击注册按钮 | 按钮加载，输入框禁用 | 禁止所有输入 |
| **成功** | 后端返回 201 | 显示成功页面 | 无 |
| **错误** | 后端返回 4xx/5xx | 显示错误 Alert | 可修正后重试 |

---

## 设计令牌

### 颜色令牌 (Light Theme)

```dart
// Primary
static const Color primary = Color(0xFF1976D2);
static const Color onPrimary = Color(0xFFFFFFFF);
static const Color primaryContainer = Color(0xFFD1E4FF);
static const Color onPrimaryContainer = Color(0xFF001D36);

// Secondary
static const Color secondary = Color(0xFF00639A);
static const Color onSecondary = Color(0xFFFFFFFF);
static const Color secondaryContainer = Color(0xFFCEE5FF);
static const Color onSecondaryContainer = Color(0xFF001D33);

// Background & Surface
static const Color background = Color(0xFFFDFCFF);
static const Color onBackground = Color(0xFF1A1C1E);
static const Color surface = Color(0xFFFFFFFF);
static const Color onSurface = Color(0xFF1A1C1E);
static const Color surfaceVariant = Color(0xFFEFF3FA);
static const Color onSurfaceVariant = Color(0xFF43474E);

// Outline
static const Color outline = Color(0xFF74777F);
static const Color outlineVariant = Color(0xFFC4C6CF);

// Error
static const Color error = Color(0xFFBA1A1A);
static const Color onError = Color(0xFFFFFFFF);
static const Color errorContainer = Color(0xFFFFDAD6);
static const Color onErrorContainer = Color(0xFF410002);

// Functional
static const Color success = Color(0xFF2E7D32);
static const Color warning = Color(0xFFED6C02);
static const Color info = Color(0xFF0288D1);
```

### 颜色令牌 (Dark Theme)

```dart
// Primary
static const Color primaryDark = Color(0xFF90CAF9);
static const Color onPrimaryDark = Color(0xFF003258);
static const Color primaryContainerDark = Color(0xFF00497D);
static const Color onPrimaryContainerDark = Color(0xFFD1E4FF);

// Background & Surface
static const Color backgroundDark = Color(0xFF1A1C1E);
static const Color onBackgroundDark = Color(0xFFE2E2E6);
static const Color surfaceDark = Color(0xFF1A1C1E);
static const Color onSurfaceDark = Color(0xFFE2E2E6);
static const Color surfaceVariantDark = Color(0xFF43474E);
static const Color onSurfaceVariantDark = Color(0xFFC4C6CF);

// Error
static const Color errorDark = Color(0xFFFFB4AB);
static const Color onErrorDark = Color(0xFF690005);
static const Color errorContainerDark = Color(0xFF93000A);
static const Color onErrorContainerDark = Color(0xFFFFDAD6);
```

### 间距令牌

```dart
// Base unit
static const double spaceUnit = 8.0;

// Spacing scale
static const double spaceXs = 4.0;    // 0.5 unit
static const double spaceSm = 8.0;    // 1 unit
static const double spaceMd = 16.0;   // 2 units
static const double spaceLg = 24.0;   // 3 units
static const double spaceXl = 32.0;   // 4 units
static const double spaceXxl = 48.0;  // 6 units

// Card padding
static const double cardPaddingMobile = 24.0;
static const double cardPaddingTablet = 40.0;
static const double cardPaddingDesktop = 48.0;

// Card max width
static const double cardMaxWidthMobile = double.infinity;
static const double cardMaxWidthTablet = 420.0;
static const double cardMaxWidthDesktop = 480.0;
```

### 排版令牌

```dart
// Font family
static const String fontFamily = 'Roboto';

// Type scale
static const TextStyle displaySmall = TextStyle(
  fontSize: 36.0,
  fontWeight: FontWeight.w400,
  height: 44.0 / 36.0,
  letterSpacing: 0,
);

static const TextStyle headlineMedium = TextStyle(
  fontSize: 28.0,
  fontWeight: FontWeight.w400,
  height: 36.0 / 28.0,
  letterSpacing: 0,
);

static const TextStyle titleLarge = TextStyle(
  fontSize: 22.0,
  fontWeight: FontWeight.w400,
  height: 28.0 / 22.0,
  letterSpacing: 0,
);

static const TextStyle titleMedium = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w500,
  height: 24.0 / 16.0,
  letterSpacing: 0.15,
);

static const TextStyle bodyLarge = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w400,
  height: 24.0 / 16.0,
  letterSpacing: 0.5,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.w400,
  height: 20.0 / 14.0,
  letterSpacing: 0.25,
);

static const TextStyle labelLarge = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.w500,
  height: 20.0 / 14.0,
  letterSpacing: 0.1,
);

static const TextStyle labelMedium = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.w500,
  height: 16.0 / 12.0,
  letterSpacing: 0.5,
);
```

### 形状令牌

```dart
// Border radius
static const double radiusSmall = 4.0;
static const double radiusMedium = 8.0;
static const double radiusLarge = 12.0;
static const double radiusXlarge = 16.0;
static const double radiusXxlarge = 24.0;

// Card radius
static const double cardRadiusMobile = 0.0;
static const double cardRadiusTablet = 20.0;
static const double cardRadiusDesktop = 24.0;
```

### 阴影令牌

```dart
// Elevation shadows
static const List<BoxShadow> elevation0 = [];

static const List<BoxShadow> elevation1 = [
  BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 3.0,
    offset: Offset(0, 1),
  ),
];

static const List<BoxShadow> elevation2 = [
  BoxShadow(
    color: Color(0x28000000),
    blurRadius: 8.0,
    offset: Offset(0, 3),
  ),
];
```

---

## 组件规范

### 1. Logo 组件

#### 尺寸规格

| 属性 | 桌面端 | 平板 | 移动端 |
|------|--------|------|--------|
| 图标尺寸 | 64×64px | 64×64px | 56×56px |
| 图标下边距 | 16px | 16px | 12px |
| 标题字号 | 36px (Display Small) | 28px (Headline Medium) | 28px (Headline Medium) |
| 标题字重 | 400 | 400 | 400 |
| 标题颜色 | On Background | On Background | On Background |
| 副标题字号 | 14px (Body Medium) | 14px | 14px |
| 副标题颜色 | On Surface Variant | On Surface Variant | On Surface Variant |
| 副标题上边距 | 4px | 4px | 4px |
| 整体下边距 | 48px | 40px | 32px |

#### 图标设计

- **形状**: 抽象船桨/波浪图形
- **颜色**: Primary
- **风格**: 线框/填充混合，简洁几何
- **圆角**: 8px（如果是圆角矩形背景）
- **背景**: 可选，Primary Container 色圆形背景，图标本身 Primary 色

---

### 2. 文本输入框 (Outlined TextField)

#### 通用规格

| 属性 | 值 |
|------|-----|
| 样式 | Outlined (Material 3) |
| 高度 | 56px |
| 宽度 | 100%（填满容器） |
| 圆角 | 8px (所有角) |
| 背景 | Surface |
| 内边距 | 水平 16px，垂直 16px |

#### 状态样式

| 状态 | 边框颜色 | 边框宽度 | Label 颜色 | 背景 |
|------|----------|----------|------------|------|
| Default | Outline (#74777F) | 1px | On Surface Variant | Surface |
| Hover | On Surface Variant | 1px | On Surface Variant | Surface Variant |
| Focused | Primary (#1976D2) | 2px | Primary | Surface |
| Error | Error (#BA1A1A) | 2px | Error | Surface |
| Disabled | On Surface at 38% | 1px | On Surface at 38% | Surface Variant at 38% |
| Filled | Outline | 1px | Primary | Surface |

#### 邮箱输入框

| 属性 | 值 |
|------|-----|
| Label | "邮箱地址" |
| Hint | "请输入邮箱地址" |
| Prefix Icon | Icons.email_outlined (24px) |
| Prefix Icon 颜色 | On Surface Variant (默认) / Primary (聚焦) |
| Keyboard Type | emailAddress |
| Autofill | email |
| 验证规则 | 标准邮箱正则表达式 |
| 错误提示 | "请输入有效的邮箱地址" |
| 必填标记 | 无（默认必填，通过验证体现） |

#### 密码输入框

| 属性 | 值 |
|------|-----|
| Label | "密码" |
| Hint | "请输入密码" |
| Prefix Icon | Icons.lock_outlined (24px) |
| Suffix Icon | Icons.visibility_off_outlined / Icons.visibility_outlined |
| Suffix Icon 颜色 | On Surface Variant |
| Suffix Icon 触摸区域 | 48×48dp（最小） |
| Obscure Text | true（默认） |
| Keyboard Type | visiblePassword（显示时） |
| 验证规则 | 非空即可（登录时验证） |
| 错误提示 | "密码不能为空"（前端）/ "邮箱或密码错误"（后端） |

#### 用户名输入框（注册页）

| 属性 | 值 |
|------|-----|
| Label | "用户名" |
| Label 后缀 | "(选填)" — Label Medium, On Surface Variant |
| Hint | "设置一个显示名称" |
| Prefix Icon | Icons.person_outlined (24px) |
| Helper Text | "不填则使用邮箱前缀作为用户名" |
| Helper Text 颜色 | On Surface Variant |
| 验证规则 | 3-30 字符，仅允许字母、数字、下划线、连字符 |
| 错误提示 | "用户名长度需在 3-30 字符之间" |

---

### 3. 按钮 (FilledButton)

#### 主按钮规格（登录/注册）

| 属性 | 值 |
|------|-----|
| 样式 | Filled Button (Material 3) |
| 高度 | 48px |
| 宽度 | 100%（填满容器） |
| 圆角 | 8px |
| 背景 | Primary |
| 文字颜色 | On Primary |
| 文字样式 | Label Large (14px, Medium) |
| 内边距 | 水平 24px，垂直 12px |
| 阴影 | Level 0（默认）/ Level 1（Hover） |
| 禁用背景 | On Surface at 12% |
| 禁用文字 | On Surface at 38% |

#### 按钮状态详细

| 状态 | 背景 | 文字 | 阴影 | 变换 | 交互 |
|------|------|------|------|------|------|
| Default | Primary | On Primary | none | none | 可点击 |
| Hover | Primary (Hover: HSL 亮度 +8%) | On Primary | elevation1 | none | 可点击 |
| Pressed | Primary (Pressed: HSL 亮度 -8%) | On Primary | elevation2 | scale(0.98) | 触发动作 |
| Disabled | On Surface at 12% | On Surface at 38% | none | none | 不可点击 |
| Loading | Primary | — | none | none | 不可点击 |
| Focused | Primary | On Primary | none | none | 显示 2px Primary Container 轮廓 |

#### 加载状态

- **指示器**: CircularProgressIndicator
- **尺寸**: 24px 直径
- **线宽**: 2.5px
- **颜色**: On Primary
- **位置**: 按钮中央，替换文字
- **按钮尺寸**: 保持不变（48px 高）
- **过渡**: 文字淡出 (150ms) → 指示器淡入 (150ms)

---

### 4. 密码强度指示器

#### 视觉规格

| 属性 | 值 |
|------|-----|
| 类型 | 分段水平条 |
| 段数 | 4 |
| 总宽度 | 100%（填满容器） |
| 段高度 | 4px |
| 段圆角 | 2px |
| 段间距 | 4px |
| 背景色（空段） | Surface Variant |

#### 强度等级

| 等级 | 条件 | 填充段数 | 颜色 | 文字标签 |
|------|------|----------|------|----------|
| 空 | 无输入 | 0 | — | — |
| 弱 | 仅满足 1 项 | 1 | Error (#BA1A1A) | "密码强度: 弱" |
| 中 | 满足 2 项 | 2 | Warning (#ED6C02) | "密码强度: 中" |
| 良 | 满足 3 项 | 3 | Primary (#1976D2) | "密码强度: 良" |
| 强 | 满足 4 项 | 4 | Success (#2E7D32) | "密码强度: 强" |

#### 密码要求列表

| 属性 | 值 |
|------|-----|
| 项目符号 | Icons.check_circle / Icons.circle_outlined (16px) |
| 已满足颜色 | Primary |
| 未满足颜色 | On Surface Variant |
| 文字样式 | Body Medium (14px) |
| 文字颜色 | On Surface Variant |
| 项间距 | 8px |
| 上边距 | 12px |

#### 检查项

1. 至少 8 个字符
2. 包含大小写字母
3. 包含数字
4. 包含特殊字符 (!@#$%^&*等)

---

### 5. 链接文本

| 属性 | 值 |
|------|-----|
| 样式 | Text Button |
| 文字样式 | Body Medium (14px) |
| 默认颜色 | Primary |
| Hover 颜色 | Primary |
| Hover 下划线 | 1px solid Primary |
| Hover 背景 | Primary at 8% opacity |
| Pressed 背景 | Primary at 12% opacity |
| 最小触摸区域 | 48×48dp |
| 对齐方式 | 居中 |

---

### 6. 错误提示 (Alert Banner)

#### 内联 Alert 规格

| 属性 | 值 |
|------|-----|
| 类型 | Material Banner / 自定义 Alert |
| 背景色 | Error Container |
| 文字颜色 | On Error Container |
| 图标 | Icons.error_outline (20px) |
| 图标颜色 | On Error Container |
| 圆角 | 8px |
| 内边距 | 12px 16px |
| 图标与文字间距 | 12px |
| 文字样式 | Body Medium (14px) |
| 动画进入 | 高度展开 200ms + 淡入 150ms |
| 动画离开 | 高度收缩 200ms + 淡出 100ms |
| 下边距 | 16px（与第一个输入框间距） |

#### 错误文案规范

- **登录失败**: "邮箱或密码错误，请检查后重试"（不暴露具体是邮箱还是密码错误）
- **邮箱格式错误**: "请输入有效的邮箱地址"
- **密码为空**: "请输入密码"
- **网络错误**: "网络连接异常，请检查网络后重试"
- **服务器错误**: "服务暂时不可用，请稍后再试"
- **邮箱已注册**: "该邮箱已被注册，请直接登录"
- **注册失败**: "注册失败，请稍后再试"

---

### 7. 成功状态（注册页）

#### 成功页面规格

| 属性 | 值 |
|------|-----|
| 布局 | 垂直居中 |
| 成功图标 | Icons.check_circle (64px) |
| 图标颜色 | Success |
| 标题 | "注册成功!" — Title Large (22px), On Background |
| 欢迎文字 | "欢迎加入 Kayak" — Body Large (16px) |
| 说明文字 | "验证邮件已发送至 user@example.com" — Body Medium |
| 说明文字2 | "请查收邮件并点击链接完成验证" — Body Medium |
| 主按钮 | "前往登录页面" — Filled Button |
| 次要操作 | "重新发送验证邮件" — Text Button |
| 间距 | 图标下 24px，标题下 8px，说明间 4px，按钮上 32px |

---

## 交互细节

### 输入验证时机

| 字段 | 前端验证时机 | 后端验证 | 验证内容 |
|------|-------------|----------|----------|
| 邮箱 | 失去焦点 + 提交时 | 登录/注册时 | 格式、是否存在 |
| 密码 | 实时（强度）+ 提交时 | 登录/注册时 | 非空、强度（注册） |
| 用户名 | 失去焦点 + 提交时 | 注册时 | 长度、非法字符 |

### 键盘行为

| 场景 | 行为 |
|------|------|
| 邮箱输入框按 Enter | 焦点移动到密码输入框 |
| 密码输入框按 Enter | 触发登录/注册 |
| 用户名输入框按 Enter | 触发注册 |
| Tab 导航 | 按逻辑顺序移动焦点 |
| Shift+Tab | 反向导航 |
| Escape | 清除错误提示（如果存在） |

### 自动填充

| 字段 | Autofill Hint |
|------|---------------|
| 邮箱 | `AutofillHints.email` |
| 密码 | `AutofillHints.password` |
| 用户名 | `AutofillHints.username` |

### 加载状态处理

- **按钮**: 显示 CircularProgressIndicator，文字隐藏
- **输入框**: 禁用（disabled），文字保持可见
- **链接**: 禁用，颜色变为 On Surface at 38%
- **页面**: 无遮罩层（避免过度阻断）
- **超时**: 15 秒后自动恢复，显示网络错误提示

### 错误恢复

- **登录错误**: 清空密码，密码框获得焦点
- **注册错误**: 保留所有输入，高亮错误字段
- **网络错误**: 保留所有输入，显示重试按钮
- **验证错误**: 字段级别错误提示，不阻断其他操作

### 页面切换动画

- **登录 ↔ 注册**: 
  - 类型: 淡入淡出 + 轻微水平滑动
  - 时长: 300ms
  - 缓动: ease-in-out
  - 新页面从右侧滑入，旧页面向左滑出

---

## 响应式规范

### 断点定义

```dart
// Breakpoints
static const double breakpointMobile = 600.0;
static const double breakpointTablet = 1024.0;
```

### 布局规则

#### Mobile (< 600px)

| 属性 | 值 |
|------|-----|
| 页面背景 | Surface |
| 卡片 | 无卡片，全屏 |
| 内边距 | 水平 24px，垂直 32px |
| Logo 尺寸 | 56×56px |
| 标题字号 | 28px |
| 输入框宽度 | 100% |
| 按钮宽度 | 100% |
| 圆角 | 0 |
| 阴影 | 无 |

#### Tablet (600px - 1024px)

| 属性 | 值 |
|------|-----|
| 页面背景 | Background |
| 卡片 | 居中，最大宽度 420px |
| 内边距 | 40px |
| Logo 尺寸 | 64×64px |
| 标题字号 | 28px |
| 输入框宽度 | 100%（在卡片内） |
| 按钮宽度 | 100% |
| 圆角 | 20px |
| 阴影 | elevation1 |

#### Desktop (> 1024px)

| 属性 | 值 |
|------|-----|
| 页面布局 | 左右分栏（可选） |
| 左侧 | 50% 宽度，装饰区域 |
| 右侧 | 50% 宽度，表单区域 |
| 卡片 | 居中，最大宽度 480px |
| 内边距 | 48px |
| Logo 尺寸 | 64×64px |
| 标题字号 | 36px |
| 输入框宽度 | 100%（在卡片内） |
| 按钮宽度 | 100% |
| 圆角 | 24px |
| 阴影 | elevation2 |
| 左侧装饰 | Primary 渐变背景 + 品牌插画 |

### 响应式组件调整

| 组件 | Mobile | Tablet | Desktop |
|------|--------|--------|---------|
| 卡片内边距 | 24px | 40px | 48px |
| 卡片圆角 | 0 | 20px | 24px |
| 卡片阴影 | 无 | Level 1 | Level 2 |
| Logo 下方间距 | 32px | 40px | 48px |
| 表单元素间距 | 16px | 20px | 24px |
| 按钮高度 | 48px | 48px | 48px |
| 页面最小高度 | 100vh | 100vh | 100vh |
| 垂直对齐 | 顶部（32px padding） | 居中 | 居中 |

---

## 无障碍要求

### WCAG 2.1 AA 合规要求

#### 对比度

| 元素 | 要求 | 实际 |
|------|------|------|
| 正文文字 (On Background) | 4.5:1 | ~15:1 |
| 大号文字 (Display Small) | 3:1 | ~15:1 |
| 按钮文字 (On Primary) | 4.5:1 | ~7:1 |
| 输入框边框 (Outline) | 3:1 | ~4.5:1 |
| 错误文字 (On Error Container) | 4.5:1 | ~7:1 |
| 禁用文字 | 无强制要求 | 2.1:1 |

#### 键盘导航

- **Tab 顺序**: 逻辑顺序，从左上到右下
- **焦点可见**: 2px Primary 色 outline，offset 2px
- **焦点陷阱**: 无（不在模态框中）
- **快捷操作**: Enter 提交表单，Escape 清除错误

#### 屏幕阅读器支持

| 元素 | ARIA 属性 |
|------|-----------|
| Logo | `aria-label="Kayak 科学研究数据采集平台"` |
| 邮箱输入 | `aria-required="true"`, `aria-describedby="email-error"` |
| 密码输入 | `aria-required="true"`, `aria-describedby="password-error"` |
| 密码切换按钮 | `aria-label="显示密码"` / `aria-label="隐藏密码"` |
| 登录按钮 | `aria-label="登录"`, 加载时 `aria-busy="true"` |
| 错误提示 | `role="alert"`, `aria-live="assertive"` |
| 密码强度 | `aria-live="polite"`, `aria-label="密码强度: 弱"` |
| 注册链接 | `aria-label="还没有账号？立即注册"` |

#### 语义化 HTML

- 使用 `<main>` 包裹主要内容
- 使用 `<form>` 包裹表单
- 使用 `<label>` 关联输入框（Material 内部实现）
- 使用 `<h1>` 作为页面标题
- 错误提示使用 `role="alert"`

### 触控与手势

- **触摸目标**: 所有交互元素最小 48×48dp
- **间距**: 相邻触摸目标间距至少 8px
- **手势**: 无复杂手势要求

### 动画与动效

- **prefers-reduced-motion**: 
  - 禁用所有过渡动画
  - 加载指示器使用静态图标
  - 页面切换无动画
  - 错误提示即时显示

### 颜色无关性

- 错误状态不仅依赖颜色，还包含图标和文字
- 密码强度不仅依赖颜色，还有文字标签
- 焦点状态不仅依赖颜色，还有 outline

---

## 设计 QA 检查项

### 视觉检查

- [ ] 颜色与 Design Token 完全一致
- [ ] 字号、字重、行高正确
- [ ] 间距符合 8px 网格系统
- [ ] 圆角一致（输入框 8px，卡片按断点）
- [ ] 阴影正确（按断点和状态）
- [ ] 图标尺寸和颜色正确
- [ ] 深色主题颜色正确

### 交互检查

- [ ] 所有 Hover 状态正确
- [ ] 所有 Focus 状态正确（键盘 Tab 测试）
- [ ] 所有 Pressed/Active 状态正确
- [ ] 禁用状态正确
- [ ] 加载状态正确
- [ ] 错误状态正确
- [ ] 输入框 Label 上浮动画正确
- [ ] 密码显示/隐藏切换正确
- [ ] 密码强度指示器实时更新

### 响应式检查

- [ ] Mobile 布局正确（< 600px）
- [ ] Tablet 布局正确（600px - 1024px）
- [ ] Desktop 布局正确（> 1024px）
- [ ] 断点切换无闪烁
- [ ] 横屏/竖屏适配（移动端）

### 无障碍检查

- [ ] 键盘完整导航
- [ ] 焦点指示器可见
- [ ] 屏幕阅读器正确朗读所有元素
- [ ] 对比度符合 WCAG AA
- [ ] 动画可被禁用（prefers-reduced-motion）
- [ ] 触摸目标最小 48dp

### 跨浏览器/平台

- [ ] Chrome（桌面）
- [ ] Firefox（桌面）
- [ ] Safari（桌面）
- [ ] Chrome（Android）
- [ ] Safari（iOS）
- [ ] Edge（桌面）

---

## 附录

### A. 图标清单

| 图标 | 用途 | 尺寸 | 颜色 |
|------|------|------|------|
| kayak_logo | 品牌 Logo | 56/64px | Primary |
| email_outlined | 邮箱输入前缀 | 24px | On Surface Variant/Primary |
| lock_outlined | 密码输入前缀 | 24px | On Surface Variant/Primary |
| person_outlined | 用户名输入前缀 | 24px | On Surface Variant/Primary |
| visibility_off_outlined | 密码隐藏 | 24px | On Surface Variant |
| visibility_outlined | 密码显示 | 24px | On Surface Variant |
| error_outline | 错误提示 | 20px | On Error Container |
| check_circle | 密码要求已满足 | 16px | Primary |
| circle_outlined | 密码要求未满足 | 16px | On Surface Variant |
| check_circle | 注册成功 | 64px | Success |
| login | 登录按钮（可选） | 18px | On Primary |
| app_registration | 注册按钮（可选） | 18px | On Primary |

### B. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 400ms | ease-out (cubic-bezier(0, 0, 0.2, 1)) | 淡入 + 上移 |
| 错误提示进入 | 200ms | ease-in-out | 高度展开 |
| 错误提示内容淡入 | 150ms | ease-out | 内容透明度 |
| 错误提示离开 | 200ms | ease-in-out | 高度收缩 |
| 按钮 Hover | 200ms | ease-out | 背景变化 |
| 按钮 Pressed | 100ms | ease-out | scale(0.98) |
| 输入框 Focus | 200ms | ease-out | 边框颜色/宽度 |
| 密码强度段 | 300ms | ease-out | 宽度展开 |
| 页面切换 | 300ms | ease-in-out | 淡入淡出 + 滑动 |
| 加载指示器 | infinite | linear | 旋转 |

### C. 参考链接

- [Material Design 3 — Text Fields](https://m3.material.io/components/text-fields/overview)
- [Material Design 3 — Buttons](https://m3.material.io/components/buttons/overview)
- [Material Design 3 — Color System](https://m3.material.io/styles/color/the-color-system/key-colors-tones)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Kayak Brand Guidelines](./brand_guidelines.md)（如存在）

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。
