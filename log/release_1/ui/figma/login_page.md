# Figma 原型 - 登录页 (Login Page)

**Figma 文件**: `kayak_r1.fig` > Page: `Login`  
**设计师**: sw-anna  
**日期**: 2026-05-03  
**状态**: 设计完成

---

## 1. 设计目标

登录页作为平台的入口，需要在第一眼就传递出 Kayak 品牌的专业性和科技感。设计采用居中卡片布局，视觉重心集中在登录表单区域，配合简洁的品牌标识和微妙的背景纹理。

---

## 2. Frame 结构

### 2.1 主 Frame

```
Frame: "Login Page - Light"
Width: 1440px
Height: 900px
Background: Surface #FFFFFF
Layout: Auto Layout (Column, Center)
```

```
Frame: "Login Page - Dark"
Width: 1440px
Height: 900px
Background: Surface #121212
Layout: Auto Layout (Column, Center)
```

### 2.2 子 Frames

```
Login Page
├── Login Card (440px × auto)
│   ├── Logo Area
│   │   ├── Icon Container (72×72, Primary Container, radius: 16px)
│   │   │   └── science icon (48px, On Primary Container)
│   │   ├── Title "KAYAK" (Headline Small, On Surface)
│   │   └── Subtitle "科学研究支持平台" (Body Medium, On Surface Variant)
│   ├── Email Field
│   │   ├── Label "邮箱地址" (Body Small)
│   │   ├── Input Container (Filled, 56px height)
│   │   └── Error Message (hidden by default)
│   ├── Password Field
│   │   ├── Label "密码" (Body Small)
│   │   ├── Input Container (Filled, 56px height)
│   │   ├── Visibility Toggle Icon
│   │   └── Error Message (hidden by default)
│   ├── Login Button (Primary, full width, 48px)
│   │   ├── Default State
│   │   ├── Loading State
│   │   └── Disabled State
│   ├── Register Link (Body Medium)
│   └── Error Banner (hidden by default)
```

---

## 3. 组件规格

### 3.1 Login Card

| 属性 | 值 |
|------|-----|
| Width | 440px |
| Padding | 40px 32px |
| Corner Radius | 28px |
| Fills | Surface Container Low |
| Stroke | None |
| Shadow (Light) | Y: 3, Blur: 6, rgba(0,0,0,0.08) |
| Shadow (Dark) | Y: 2, Blur: 4, rgba(0,0,0,0.32) |

### 3.2 Logo Icon Container

| 属性 | 值 |
|------|-----|
| Width / Height | 72px × 72px |
| Corner Radius | 16px (rounded) |
| Fills | Primary Container |
| Icon | `science` (Material Symbols Rounded) |
| Icon Size | 48px |
| Icon Color | On Primary Container |
| Shadow | Elevation 1 |

### 3.3 标题 "KAYAK"

| 属性 | 值 |
|------|-----|
| Font Family | Roboto / system-ui |
| Font Size | 24pt |
| Font Weight | Regular (400) |
| Line Height | 32pt (1.33) |
| Letter Spacing | 4px (uppercase effect) |
| Text Color | On Surface |
| Text Align | Center |
| Top Margin | 24px |

### 3.4 副标题

| 属性 | 值 |
|------|-----|
| Font Size | 14pt |
| Font Weight | Regular (400) |
| Line Height | 20pt (1.43) |
| Text Color | On Surface Variant |
| Text Align | Center |
| Top Margin | 8px |

### 3.5 Email Input Field

| 属性 | 值 |
|------|-----|
| Container Height | 56px |
| Container Fills | Surface Container Highest, 50% opacity |
| Container Radius | 8px (top), 4px (bottom) - Filled style |
| Padding | 12px 16px |
| Label Text | "邮箱地址" |
| Label Font | Body Small (12pt, 400) |
| Label Color | On Surface Variant |
| Input Text Font | Body Medium (14pt, 400) |
| Placeholder | "user@example.com" |
| Icon (prefix) | email, 20px, On Surface Variant |
| Top Margin | 32px (from title area) |

### 3.6 Password Input Field

| 属性 | 值 |
|------|-----|
| Same as Email | plus: |
| Icon (prefix) | lock, 20px, On Surface Variant |
| Icon (suffix) | visibility / visibility_off (toggle), 24px |
| Top Margin | 16px |

### 3.7 Login Button

| 属性 | 值 |
|------|-----|
| Height | 48px |
| Width | 100% (fill container) |
| Corner Radius | 8px |
| Fills | Primary #1976D2 |
| Text | "登录" |
| Text Font | Label Large (14pt, 500) |
| Text Color | On Primary #FFFFFF |
| Top Margin | 24px |

### 3.8 Register Link

| 属性 | 值 |
|------|-----|
| Font Size | 14pt |
| Text | "还没有账号？" + "立即注册" |
| Text Color | On Surface Variant + Primary |
| Text Align | Center |
| Top Margin | 20px |

---

## 4. 状态变体

### 4.1 初始状态 (Default)
- 邮箱输入框自动聚焦
- 密码输入框为空
- 登录按钮可用

### 4.2 输入错误状态
- 邮箱错误: 边框变 Error #C62828, 下方红色提示 "请输入有效的邮箱地址"
- 密码错误: 边框变 Error #C62828, 下方红色提示 "密码至少需要6个字符"

### 4.3 加载状态 (Loading)
- 登录按钮文字消失
- 按钮中央显示 CircularProgressIndicator (20px, On Primary 颜色)
- 两个输入框变为 Disabled 状态 (38% 透明度)

### 4.4 登录失败状态
- 卡片顶部显示错误横幅
  - 背景: Error Container
  - 文字: On Error Container
  - 图标: error, 20px
  - 文字内容: "邮箱或密码错误，请重试"

### 4.5 会话过期状态
- 卡片顶部显示警告横幅
  - 背景: Warning Container
  - 文字: On Warning Container
  - 图标: warning, 20px
  - 文字内容: "会话已过期，请重新登录"

---

## 5. 原型交互 (Prototype Links)

| 起点 | 交互 | 终点 | 动画 |
|------|------|------|------|
| Login Button (valid) | Tap | Dashboard | Dissolve 300ms |
| Register Link | Tap | Register Page | Push → 300ms |
| Password Toggle | Tap | Show/Hide password | Instant |

---

## 6. 主题变体

### Light Theme
- Background: #FFFFFF
- Card: Surface Container Low #F5F5F5
- Input fills: #EEEEEE at 50%
- Shadow: rgba(0,0,0,0.08)
- Text primary: #212121
- Text secondary: #757575

### Dark Theme
- Background: #121212
- Card: Surface Container Low #1E1E1E
- Input fills: #2D2D2D
- Shadow: rgba(0,0,0,0.32)
- Text primary: #F5F5F5
- Text secondary: #9E9E9E
- Primary: #90CAF9 (vs #1976D2 in light)

---

## 7. 响应式变体

### Desktop (≥1280px)
- Card width: 440px
- Card padding: 40px 32px
- Card centered in viewport

### Tablet (≥768px)
- Card width: 400px
- Card padding: 32px 24px
- Card centered in viewport

### Mobile (<768px)
- Full width (minus 32px margin)
- Card padding: 24px 16px
- Reduced spacing

---

## 8. 设计笔记

- Logo 图标使用 50% rounded corners (16px radius on 72px square) 创造独特的 "squircle" 外观
- 标题 "KAYAK" 使用 4px 字间距营造品牌感
- 卡片圆角 28px 为全平台统一大圆角风格
- 输入框使用 Material 3 Filled 风格 (top corners rounded, bottom corners square)
- 考虑在背景中添加微妙的科技感纹理/图案（如电路板线条、数据流动粒子）- 待后续迭代
