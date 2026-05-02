# Kayak UI/UX 设计规范文档

**版本**: 1.0  
**日期**: 2026-05-02  
**设计师**: sw-anna  
**项目**: Kayak 科学研究支持平台 - Release 1

---

## 1. 设计概述

### 1.1 品牌定位
Kayak 是面向科研人员的一站式试验仪器管理、实验过程设计、数据采集与分析平台。设计需体现：
- **专业性**: 科学研究领域的严谨与精确
- **科技感**: 现代、前沿的技术平台形象
- **易用性**: 降低科研人员的操作门槛

### 1.2 设计原则
1. **清晰的信息层次**: 重要信息突出，次要信息弱化
2. **一致的设计语言**: 全平台统一的视觉风格
3. **高效的交互流程**: 减少操作步骤，提高工作效率
4. **响应式适配**: 支持桌面端和 Web 模式

### 1.3 技术约束
- **框架**: Flutter 3.19+, Material Design 3
- **部署**: Web 模式优先 (`flutter build web`)
- **主题**: 支持浅色/深色主题切换
- **布局**: 桌面端为主 (>=1280px)，适配平板端 (>=768px)

---

## 2. 色彩系统

### 2.1 主色调

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Primary | `#2563EB` | `#60A5FA` | 主按钮、链接、选中状态 |
| On Primary | `#FFFFFF` | `#1E3A5F` | 主色上的文字 |
| Primary Container | `#DBEAFE` | `#1E40AF` | 主色容器背景 |
| On Primary Container | `#1E40AF` | `#BFDBFE` | 主色容器上的文字 |

### 2.2 辅色调

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Secondary | `#475569` | `#94A3B8` | 次要按钮、标签 |
| On Secondary | `#FFFFFF` | `#1E293B` | 辅色上的文字 |
| Secondary Container | `#E2E8F0` | `#334155` | 辅色容器背景 |
| On Secondary Container | `#334155` | `#CBD5E1` | 辅色容器上的文字 |

### 2.3 第三色调

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Tertiary | `#0891B2` | `#22D3EE` | 强调元素、特殊状态 |
| On Tertiary | `#FFFFFF` | `#164E63` | 第三色上的文字 |
| Tertiary Container | `#CFFAFE` | `#155E75` | 第三色容器背景 |
| On Tertiary Container | `#155E75` | `#A5F3FC` | 第三色容器上的文字 |

### 2.4 语义色

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Success | `#10B981` | `#34D399` | 成功状态、通过 |
| Warning | `#F59E0B` | `#FBBF24` | 警告状态、注意 |
| Error | `#EF4444` | `#F87171` | 错误状态、失败 |
| Info | `#3B82F6` | `#60A5FA` | 信息提示 |

### 2.5 中性色

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Surface | `#FFFFFF` | `#0F172A` | 页面背景 |
| Surface Container Lowest | `#FAFAFA` | `#0B1120` | 最低层级容器 |
| Surface Container Low | `#F1F5F9` | `#1E293B` | 低层级容器 |
| Surface Container | `#E2E8F0` | `#334155` | 标准容器 |
| Surface Container High | `#CBD5E1` | `#475569` | 高层级容器 |
| Surface Container Highest | `#94A3B8` | `#64748B` | 最高层级容器 |
| On Surface | `#0F172A` | `#F1F5F9` | 表面上的主要文字 |
| On Surface Variant | `#64748B` | `#94A3B8` | 表面上的次要文字 |
| Outline | `#CBD5E1` | `#475569` | 边框、分割线 |
| Outline Variant | `#E2E8F0` | `#334155` | 次要边框 |

### 2.6 色彩使用规范

```dart
// Flutter ColorScheme 配置示例
ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF2563EB),
  brightness: Brightness.light,
);

ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF60A5FA),
  brightness: Brightness.dark,
);
```

---

## 3. 字体系统

### 3.1 字体家族

- **主字体**: 系统默认无衬线字体
  - Android: Roboto
  - iOS/macOS: SF Pro
  - Web: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto

### 3.2 字体层级

| 层级 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| Display Large | 57pt | w400 | 64pt | 欢迎页大标题 |
| Display Medium | 45pt | w400 | 52pt | 页面大标题 |
| Display Small | 36pt | w400 | 44pt | 区域大标题 |
| Headline Large | 32pt | w400 | 40pt | 模块标题 |
| Headline Medium | 28pt | w400 | 36pt | 卡片标题 |
| Headline Small | 24pt | w400 | 32pt | 对话框标题 |
| Title Large | 22pt | w500 | 28pt | 应用栏标题 |
| Title Medium | 16pt | w500 | 24pt | 列表项标题 |
| Title Small | 14pt | w500 | 20pt | 小标题 |
| Body Large | 16pt | w400 | 24pt | 主要正文 |
| Body Medium | 14pt | w400 | 20pt | 标准正文 |
| Body Small | 12pt | w400 | 16pt | 辅助文字 |
| Label Large | 14pt | w500 | 20pt | 按钮文字 |
| Label Medium | 12pt | w500 | 16pt | 标签文字 |
| Label Small | 11pt | w500 | 16pt | 小标签 |

### 3.3 字体使用规范

```dart
// Flutter TextTheme 配置
textTheme: TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12),
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16),
  displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, height: 1.25),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, height: 1.29),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.33),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.27),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
),
```

---

## 4. 间距系统

### 4.1 基础间距

基于 8pt 网格系统：

| Token | 值 | 用途 |
|-------|-----|------|
| space-0 | 0 | 无间距 |
| space-1 | 4px | 极小间距 |
| space-2 | 8px | 小间距 |
| space-3 | 12px | 中小间距 |
| space-4 | 16px | 标准间距 |
| space-5 | 20px | 中间距 |
| space-6 | 24px | 中大间距 |
| space-8 | 32px | 大间距 |
| space-10 | 40px | 超大间距 |
| space-12 | 48px | 极大间距 |
| space-16 | 64px | 页面级间距 |

### 4.2 组件间距

| 组件 | 内边距 | 外边距 |
|------|--------|--------|
| 卡片 | 16px-24px | 16px |
| 按钮 | 12px 24px | 8px |
| 输入框 | 12px 16px | 16px |
| 列表项 | 12px 16px | 0 |
| 对话框 | 24px | 0 |
| 应用栏 | 0 16px | 0 |

---

## 5. 组件规范

### 5.1 按钮

#### Primary Button
- 背景: Primary color
- 文字: On Primary color
- 圆角: 8px
- 内边距: 12px 24px
- 高度: 40px
- 状态:
  - Normal: 标准色
  - Hover: 亮度 +10%
  - Pressed: 亮度 -10%
  - Disabled: 透明度 38%

#### Secondary Button
- 背景: Secondary Container color
- 文字: On Secondary Container color
- 圆角: 8px
- 内边距: 12px 24px
- 高度: 40px

#### Outlined Button
- 背景: Transparent
- 边框: 1px Outline color
- 文字: Primary color
- 圆角: 8px
- 内边距: 12px 24px

#### Text Button
- 背景: Transparent
- 文字: Primary color
- 内边距: 8px 16px

### 5.2 输入框

#### Standard Input
- 背景: Surface Container Highest with 50% opacity
- 边框: None (enabled), 2px Primary (focused), 1px Error (error)
- 圆角: 8px
- 内边距: 12px 16px
- 高度: 48px
- 标签: Body Small, On Surface Variant
- 提示文字: Body Medium, On Surface Variant with 60% opacity

#### Dropdown Input
- 同 Standard Input
- 右侧: 下拉箭头图标

### 5.3 卡片

#### Standard Card
- 背景: Surface color
- 边框: 1px Outline Variant
- 圆角: 12px
- 阴影: None (elevation 0)
- 内边距: 16px-24px

#### Elevated Card
- 背景: Surface color
- 圆角: 12px
- 阴影: Elevation 1
- 内边距: 16px-24px

### 5.4 表格

#### Data Table
- 表头背景: Surface Container Low
- 表头文字: Title Small, On Surface
- 行高: 52px
- 行分隔线: 1px Outline Variant
- 选中行背景: Primary Container with 50% opacity
- 悬停行背景: Surface Container Lowest

### 5.5 对话框

#### Standard Dialog
- 背景: Surface Container High
- 圆角: 28px
- 内边距: 24px
- 最大宽度: 560px
- 标题: Headline Small
- 内容: Body Medium
- 按钮区: 右对齐，间距 8px

### 5.6 侧边栏

#### Navigation Sidebar
- 宽度: 240px (展开), 72px (折叠)
- 背景: Surface Container Low
- 边框: 1px Outline Variant (右侧)
- 导航项高度: 48px
- 导航项圆角: 12px
- 选中状态: Secondary Container background
- 图标大小: 24px

---

## 6. 图标系统

### 6.1 图标库
- **主图标库**: Material Symbols (Rounded style)
- **备用图标库**: Material Design Icons Flutter

### 6.2 图标尺寸

| 尺寸 | 用途 |
|------|------|
| 16px | 内联图标、小按钮 |
| 20px | 标签图标 |
| 24px | 标准图标、导航项 |
| 32px | 大按钮、卡片图标 |
| 48px | 功能图标、空状态 |

### 6.3 常用图标映射

| 功能 | 图标名称 |
|------|---------|
| 首页/仪表盘 | dashboard |
| 工作台 | workspace_premium |
| 试验/实验 | science |
| 方法 | description |
| 设置 | settings |
| 用户 | person |
| 添加 | add |
| 编辑 | edit |
| 删除 | delete |
| 保存 | save |
| 刷新 | refresh |
| 搜索 | search |
| 连接 | link |
| 断开 | link_off |
| 运行 | play_arrow |
| 停止 | stop |
| 暂停 | pause |
| 成功 | check_circle |
| 警告 | warning |
| 错误 | error |
| 信息 | info |

---

## 7. 动效规范

### 7.1 过渡动画

| 动画 | 时长 | 缓动函数 |
|------|------|---------|
| 页面切换 | 300ms | ease-in-out |
| 侧边栏展开/折叠 | 200ms | ease-in-out |
| 对话框出现 | 150ms | decelerate |
| 对话框消失 | 100ms | accelerate |
| 按钮按下 | 100ms | ease-out |
| 卡片悬停 | 150ms | ease-in-out |
| Toast 出现 | 200ms | decelerate |
| Toast 消失 | 150ms | accelerate |

### 7.2 微交互

- **按钮悬停**: 亮度变化 + 阴影提升
- **卡片悬停**: 轻微上移 (translateY -2px) + 阴影提升
- **输入框聚焦**: 边框颜色变化 + 标签上浮
- **列表项选中**: 背景色变化 + 左侧指示条
- **加载状态**: 循环动画，避免闪烁

---

## 8. 布局规范

### 8.1 页面结构

```
┌─────────────────────────────────────────────────────────────┐
│  App Bar (64px height)                                      │
├──────────┬──────────────────────────────────────────────────┤
│          │  Breadcrumb Navigation (48px height)             │
│ Sidebar  ├──────────────────────────────────────────────────┤
│ (240px)  │                                                  │
│          │  Content Area                                    │
│          │  (padding: 24px)                                 │
│          │                                                  │
│          │                                                  │
└──────────┴──────────────────────────────────────────────────┘
```

### 8.2 响应式断点

| 断点 | 宽度 | 布局调整 |
|------|------|---------|
| Desktop | >=1280px | 完整侧边栏 + 内容区 |
| Tablet | >=768px | 折叠侧边栏 + 内容区 |
| Mobile | <768px | 底部导航 + 全宽内容 |

### 8.3 内容区最大宽度

- 标准内容: 100% (自适应)
- 表单内容: max-width 800px, 居中
- 表格内容: 100% (水平滚动)

---

## 9. 状态规范

### 9.1 组件状态

| 状态 | 视觉表现 |
|------|---------|
| Normal | 标准样式 |
| Hover | 亮度 +10%, 阴影提升 |
| Focused | 2px Primary 边框 |
| Pressed | 亮度 -10% |
| Disabled | 透明度 38%, 无交互 |
| Selected | Primary Container 背景 |
| Error | Error 颜色边框 + 错误提示 |

### 9.2 加载状态

- **按钮加载**: 显示 CircularProgressIndicator (16px), 文字隐藏
- **页面加载**: 全屏骨架屏或 CircularProgressIndicator
- **数据加载**: 列表项骨架屏
- **操作加载**: 遮罩层 + CircularProgressIndicator

### 9.3 空状态

- 图标: 48px, On Surface Variant 颜色
- 标题: Title Medium, On Surface
- 描述: Body Medium, On Surface Variant
- 操作按钮: Primary Button (可选)

---

**文档结束**
