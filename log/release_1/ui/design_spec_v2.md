# Kayak UI/UX 设计规范文档 v2

**版本**: 2.0  
**日期**: 2026-05-03  
**设计师**: sw-anna  
**项目**: Kayak 科学研究支持平台 - Release 1  
**更新说明**: 更新主色为科技蓝 #1976D2，完善组件规范，新增设备配置页特殊组件

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

### 2.1 主色调（科技蓝）

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Primary | `#1976D2` | `#90CAF9` | 主按钮、链接、选中状态 |
| On Primary | `#FFFFFF` | `#000000` | 主色上的文字 |
| Primary Container | `#BBDEFB` | `#1565C0` | 主色容器背景 |
| On Primary Container | `#1565C0` | `#E3F2FD` | 主色容器上的文字 |
| Primary Variant | `#1565C0` | `#64B5F6` | 悬停、按下状态 |

### 2.2 辅色调（中性灰）

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Secondary | `#546E7A` | `#90A4AE` | 次要按钮、标签 |
| On Secondary | `#FFFFFF` | `#000000` | 辅色上的文字 |
| Secondary Container | `#ECEFF1` | `#37474F` | 辅色容器背景 |
| On Secondary Container | `#37474F` | `#CFD8DC` | 辅色容器上的文字 |

### 2.3 第三色调（青色）

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Tertiary | `#00838F` | `#80DEEA` | 强调元素、特殊状态 |
| On Tertiary | `#FFFFFF` | `#000000` | 第三色上的文字 |
| Tertiary Container | `#E0F7FA` | `#006064` | 第三色容器背景 |
| On Tertiary Container | `#006064` | `#E0F7FA` | 第三色容器上的文字 |

### 2.4 语义色

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Success | `#2E7D32` | `#66BB6A` | 成功状态、通过 |
| Success Container | `#E8F5E9` | `#1B5E20` | 成功容器背景 |
| Warning | `#F57C00` | `#FFB74D` | 警告状态、注意 |
| Warning Container | `#FFF3E0` | `#E65100` | 警告容器背景 |
| Error | `#C62828` | `#EF5350` | 错误状态、失败 |
| Error Container | `#FFEBEE` | `#B71C1C` | 错误容器背景 |
| Info | `#1976D2` | `#90CAF9` | 信息提示 |
| Info Container | `#E3F2FD` | `#0D47A1` | 信息容器背景 |

### 2.5 中性色

| 角色 | 浅色主题 | 深色主题 | 用途 |
|------|---------|---------|------|
| Surface | `#FFFFFF` | `#121212` | 页面背景 |
| Surface Container Lowest | `#FAFAFA` | `#0A0A0A` | 最低层级容器 |
| Surface Container Low | `#F5F5F5` | `#1E1E1E` | 低层级容器 |
| Surface Container | `#EEEEEE` | `#2D2D2D` | 标准容器 |
| Surface Container High | `#E0E0E0` | `#3D3D3D` | 高层级容器 |
| Surface Container Highest | `#BDBDBD` | `#4D4D4D` | 最高层级容器 |
| On Surface | `#212121` | `#F5F5F5` | 表面上的主要文字 |
| On Surface Variant | `#757575` | `#9E9E9E` | 表面上的次要文字 |
| Outline | `#E0E0E0` | `#424242` | 边框、分割线 |
| Outline Variant | `#EEEEEE` | `#333333` | 次要边框 |

### 2.6 色彩使用规范

```dart
// Flutter ColorScheme 配置示例 - 浅色主题
ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1976D2),
  brightness: Brightness.light,
  primary: const Color(0xFF1976D2),
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: const Color(0xFFBBDEFB),
  onPrimaryContainer: const Color(0xFF1565C0),
  secondary: const Color(0xFF546E7A),
  onSecondary: const Color(0xFFFFFFFF),
  secondaryContainer: const Color(0xFFECEFF1),
  onSecondaryContainer: const Color(0xFF37474F),
  tertiary: const Color(0xFF00838F),
  onTertiary: const Color(0xFFFFFFFF),
  tertiaryContainer: const Color(0xFFE0F7FA),
  onTertiaryContainer: const Color(0xFF006064),
  error: const Color(0xFFC62828),
  onError: const Color(0xFFFFFFFF),
  errorContainer: const Color(0xFFFFEBEE),
  onErrorContainer: const Color(0xFFB71C1C),
  surface: const Color(0xFFFFFFFF),
  onSurface: const Color(0xFF212121),
  surfaceContainerHighest: const Color(0xFFBDBDBD),
  onSurfaceVariant: const Color(0xFF757575),
  outline: const Color(0xFFE0E0E0),
  outlineVariant: const Color(0xFFEEEEEE),
);

// Flutter ColorScheme 配置示例 - 深色主题
ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF90CAF9),
  brightness: Brightness.dark,
  primary: const Color(0xFF90CAF9),
  onPrimary: const Color(0xFF000000),
  primaryContainer: const Color(0xFF1565C0),
  onPrimaryContainer: const Color(0xFFE3F2FD),
  secondary: const Color(0xFF90A4AE),
  onSecondary: const Color(0xFF000000),
  secondaryContainer: const Color(0xFF37474F),
  onSecondaryContainer: const Color(0xFFCFD8DC),
  tertiary: const Color(0xFF80DEEA),
  onTertiary: const Color(0xFF000000),
  tertiaryContainer: const Color(0xFF006064),
  onTertiaryContainer: const Color(0xFFE0F7FA),
  error: const Color(0xFFEF5350),
  onError: const Color(0xFF000000),
  errorContainer: const Color(0xFFB71C1C),
  onErrorContainer: const Color(0xFFFFEBEE),
  surface: const Color(0xFF121212),
  onSurface: const Color(0xFFF5F5F5),
  surfaceContainerHighest: const Color(0xFF4D4D4D),
  onSurfaceVariant: const Color(0xFF9E9E9E),
  outline: const Color(0xFF424242),
  outlineVariant: const Color(0xFF333333),
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

| 层级 | 字号 | 字重 | 行高 | 字间距 | 用途 |
|------|------|------|------|--------|------|
| Display Large | 57pt | w400 | 64pt | -0.25px | 欢迎页大标题 |
| Display Medium | 45pt | w400 | 52pt | 0px | 页面大标题 |
| Display Small | 36pt | w400 | 44pt | 0px | 区域大标题 |
| Headline Large | 32pt | w400 | 40pt | 0px | 模块标题 |
| Headline Medium | 28pt | w400 | 36pt | 0px | 卡片标题 |
| Headline Small | 24pt | w400 | 32pt | 0px | 对话框标题 |
| Title Large | 22pt | w500 | 28pt | 0px | 应用栏标题 |
| Title Medium | 16pt | w500 | 24pt | 0.15px | 列表项标题 |
| Title Small | 14pt | w500 | 20pt | 0.1px | 小标题 |
| Body Large | 16pt | w400 | 24pt | 0.5px | 主要正文 |
| Body Medium | 14pt | w400 | 20pt | 0.25px | 标准正文 |
| Body Small | 12pt | w400 | 16pt | 0.4px | 辅助文字 |
| Label Large | 14pt | w500 | 20pt | 0.1px | 按钮文字 |
| Label Medium | 12pt | w500 | 16pt | 0.5px | 标签文字 |
| Label Small | 11pt | w500 | 16pt | 0.5px | 小标签 |

### 3.3 字体使用规范

```dart
// Flutter TextTheme 配置
TextTheme textTheme = TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12, letterSpacing: -0.25),
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16, letterSpacing: 0),
  displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22, letterSpacing: 0),
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, height: 1.25, letterSpacing: 0),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, height: 1.29, letterSpacing: 0),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.27, letterSpacing: 0),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.15),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.5),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: 0.25),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0.4),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.5),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0.5),
);
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
| space-20 | 80px | 超大页面间距 |

### 4.2 组件间距

| 组件 | 内边距 | 外边距 |
|------|--------|--------|
| 卡片 | 16px-24px | 16px |
| 按钮 | 12px 24px | 8px |
| 输入框 | 12px 16px | 16px |
| 列表项 | 12px 16px | 0 |
| 对话框 | 24px | 0 |
| 应用栏 | 0 16px | 0 |
| 表单区域 | 24px | 16px |
| 协议参数卡片 | 20px | 16px |

---

## 5. 组件规范

### 5.1 按钮

#### Primary Button
- 背景: Primary color
- 文字: On Primary color
- 圆角: 8px (Rounded corners)
- 内边距: 12px 24px
- 高度: 40px
- 字重: w500
- 状态:
  - Normal: 标准色
  - Hover: Primary Variant 颜色，Elevation 2
  - Pressed: Primary Variant 颜色，Elevation 4
  - Disabled: On Surface 颜色，透明度 38%
  - Loading: 显示 CircularProgressIndicator (16px)，文字隐藏

#### Secondary Button
- 背景: Secondary Container color
- 文字: On Secondary Container color
- 圆角: 8px
- 内边距: 12px 24px
- 高度: 40px
- 字重: w500
- 状态:
  - Normal: 标准色
  - Hover: Secondary color，文字 On Secondary
  - Pressed: Secondary color 亮度 -10%
  - Disabled: On Surface 颜色，透明度 38%

#### Outlined Button
- 背景: Transparent
- 边框: 1px Outline color
- 文字: Primary color
- 圆角: 8px
- 内边距: 12px 24px
- 高度: 40px
- 字重: w500
- 状态:
  - Normal: 标准样式
  - Hover: Primary color at 8% opacity 背景
  - Pressed: Primary color at 12% opacity 背景
  - Disabled: On Surface 颜色，透明度 38%

#### Text Button
- 背景: Transparent
- 文字: Primary color
- 内边距: 8px 16px
- 字重: w500
- 状态:
  - Normal: 标准样式
  - Hover: Primary color at 8% opacity 背景
  - Pressed: Primary color at 12% opacity 背景

#### Icon Button
- 尺寸: 40px x 40px
- 图标: 24px
- 圆角: 50% (圆形)
- 状态:
  - Normal: Transparent
  - Hover: On Surface Variant at 8% opacity 背景
  - Pressed: On Surface Variant at 12% opacity 背景

#### Floating Action Button (FAB)
- 尺寸: 56px x 56px
- 背景: Primary Container color
- 图标: 24px, On Primary Container color
- 圆角: 16px
- 阴影: Elevation 3
- 状态:
  - Normal: 标准样式
  - Hover: Elevation 4
  - Pressed: Elevation 6

### 5.2 输入框

#### Standard Input (Filled Text Field)
- 背景: Surface Container Highest with 50% opacity
- 边框: None (enabled), 2px Primary (focused), 1px Error (error)
- 圆角: 8px (top-left, top-right)
- 内边距: 12px 16px
- 高度: 56px
- 标签: Body Small, On Surface Variant
- 提示文字: Body Medium, On Surface Variant with 60% opacity
- 状态:
  - Normal: 标准样式
  - Focused: 2px Primary 边框，标签上浮
  - Error: 1px Error 边框，Error 颜色提示文字
  - Disabled: 38% 透明度

#### Outlined Input (Outlined Text Field)
- 背景: Transparent
- 边框: 1px Outline color (enabled), 2px Primary (focused), 1px Error (error)
- 圆角: 8px
- 内边距: 12px 16px
- 高度: 56px
- 状态:
  - Normal: 标准样式
  - Focused: 2px Primary 边框，标签上浮
  - Error: 1px Error 边框
  - Disabled: 38% 透明度

#### Dropdown Input (协议选择器等)
- 同 Standard Input 样式
- 右侧: 下拉箭头图标 (24px)
- 下拉面板:
  - 背景: Surface color
  - 圆角: 8px
  - 阴影: Elevation 2
  - 选项高度: 48px
  - 选项内边距: 12px 16px
  - 选中项: Primary Container 背景
  - 悬停项: On Surface Variant at 4% opacity

#### Number Input
- 同 Standard Input
- 右侧: 增减按钮 (可选)
- 键盘: 数字键盘
- 验证: 实时验证范围

#### IP Address Input
- 同 Standard Input
- 占位符: "192.168.1.1"
- 验证: IP格式或域名格式
- 错误提示: "请输入有效的IP地址或域名"

### 5.3 卡片

#### Standard Card
- 背景: Surface color
- 边框: 1px Outline Variant
- 圆角: 12px
- 阴影: None (elevation 0)
- 内边距: 16px-24px
- 状态:
  - Normal: 标准样式
  - Hover: Elevation 1, 边框变 Primary color
  - Pressed: Elevation 2

#### Elevated Card
- 背景: Surface color
- 圆角: 12px
- 阴影: Elevation 1
- 内边距: 16px-24px
- 状态:
  - Normal: 标准样式
  - Hover: Elevation 3
  - Pressed: Elevation 5

#### Protocol Config Card (设备配置页专用)
- 背景: Surface Container Lowest
- 边框: 1px Outline Variant
- 圆角: 16px
- 内边距: 24px
- 标题区:
  - 图标: 24px, Primary color
  - 标题: Title Medium, On Surface
  - 副标题: Body Small, On Surface Variant
- 内容区:
  - 表单字段间距: 16px (横向), 20px (纵向)
  - 字段标签: Body Small, On Surface Variant
  - 必填标记: * Error color
- 状态:
  - Normal: 标准样式
  - Active: 边框变 Primary color, Elevation 1
  - Error: 边框变 Error color

#### Form Section Card (表单分区)
- 背景: Surface
- 边框: None
- 圆角: 12px
- 内边距: 20px
- 标题: Title Medium, On Surface
- 分隔线: 1px Outline Variant (标题下方)
- 内容间距: 16px

### 5.4 表格

#### Data Table
- 表头背景: Surface Container Low
- 表头文字: Title Small, On Surface
- 表头高度: 48px
- 行高: 52px
- 行分隔线: 1px Outline Variant
- 选中行背景: Primary Container with 50% opacity
- 悬停行背景: Surface Container Lowest
- 空状态:
  - 图标: 48px, On Surface Variant
  - 标题: Title Medium, On Surface
  - 描述: Body Medium, On Surface Variant

#### Compact Data Table (测点列表)
- 表头背景: Surface Container Low
- 表头文字: Label Medium, On Surface
- 表头高度: 40px
- 行高: 44px
- 行分隔线: 1px Outline Variant
- 单元格内边距: 8px 12px

### 5.5 对话框

#### Standard Dialog
- 背景: Surface Container High
- 圆角: 28px
- 内边距: 24px
- 最大宽度: 560px
- 标题: Headline Small, On Surface
- 内容: Body Medium, On Surface
- 按钮区: 右对齐，间距 8px

#### Large Dialog (设备配置)
- 背景: Surface Container High
- 圆角: 28px
- 内边距: 24px
- 最大宽度: 800px
- 最大高度: 90vh
- 标题: Headline Small, On Surface
- 内容区: 可滚动
- 按钮区: 右对齐，间距 8px
- 底部阴影: 渐变遮罩 (内容溢出时)

#### Confirmation Dialog
- 背景: Surface Container High
- 圆角: 28px
- 内边距: 24px
- 最大宽度: 400px
- 图标: 48px, Warning color (可选)
- 标题: Headline Small, On Surface
- 内容: Body Medium, On Surface
- 按钮: Text Button (取消) + Primary Button (确认)

### 5.6 侧边栏

#### Navigation Sidebar
- 宽度: 240px (展开), 72px (折叠)
- 背景: Surface Container Low
- 边框: 1px Outline Variant (右侧)
- 导航项高度: 48px
- 导航项圆角: 12px
- 导航项内边距: 12px 16px
- 选中状态:
  - 背景: Secondary Container
  - 文字: On Secondary Container
  - 图标: On Secondary Container
- 悬停状态:
  - 背景: On Surface Variant at 8% opacity
- 图标大小: 24px
- 文字: Label Large, On Surface

### 5.7 Chip 组件

#### Status Chip
- 高度: 28px
- 圆角: 8px (Rounded corners)
- 内边距: 4px 12px
- 文字: Label Small
- 状态变体:
  - Online: Success Container 背景, Success 文字
  - Offline: Error Container 背景, Error 文字
  - Warning: Warning Container 背景, Warning 文字
  - Info: Info Container 背景, Info 文字
  - Default: Surface Container 背景, On Surface Variant 文字

#### Protocol Chip
- 同 Status Chip
- 变体:
  - Virtual: Primary Container 背景, On Primary Container 文字
  - Modbus TCP: Tertiary Container 背景, On Tertiary Container 文字
  - Modbus RTU: Secondary Container 背景, On Secondary Container 文字

### 5.8 进度指示器

#### Circular Progress Indicator
- 尺寸: 16px (按钮内), 24px (卡片内), 48px (页面加载)
- 颜色: Primary
- 线宽: 3px

#### Linear Progress Indicator
- 高度: 4px
- 颜色: Primary
- 背景: Surface Container Highest

### 5.9 Snackbar / Toast

- 背景: On Surface (浅色) / Surface Container High (深色)
- 圆角: 8px
- 内边距: 12px 16px
- 文字: Body Medium, On Surface (浅色) / On Surface (深色)
- 操作按钮: Text Button
- 位置: 底部居中
- 最大宽度: 400px
- 显示时长: 3-5秒
- 出现动画: 从底部滑入 200ms
- 消失动画: 向底部滑出 150ms

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

| 功能 | 图标名称 | 分类 |
|------|---------|------|
| 首页/仪表盘 | dashboard | 导航 |
| 工作台 | workspace_premium | 导航 |
| 试验/实验 | science | 导航 |
| 方法 | description | 导航 |
| 设置 | settings | 导航 |
| 用户 | person | 导航 |
| 添加 | add | 操作 |
| 编辑 | edit | 操作 |
| 删除 | delete | 操作 |
| 保存 | save | 操作 |
| 刷新 | refresh | 操作 |
| 搜索 | search | 操作 |
| 连接 | link | 设备 |
| 断开 | link_off | 设备 |
| 运行 | play_arrow | 试验 |
| 停止 | stop | 试验 |
| 暂停 | pause | 试验 |
| 成功 | check_circle | 状态 |
| 警告 | warning | 状态 |
| 错误 | error | 状态 |
| 信息 | info | 状态 |
| 设备 | memory | 设备 |
| 测点 | sensors | 设备 |
| 协议 | settings_ethernet | 设备 |
| 串口 | usb | 设备 |
| 网络 | lan | 设备 |
| 虚拟 | developer_board | 设备 |
| 随机 | shuffle | Virtual |
| 固定 | lock | Virtual |
| 正弦 | waves | Virtual |
| 斜坡 | trending_up | Virtual |
| 展开 | expand_more | 树形 |
| 折叠 | expand_less | 树形 |
| 更多 | more_vert | 菜单 |
| 关闭 | close | 操作 |
| 返回 | arrow_back | 导航 |
| 前进 | arrow_forward | 导航 |
| 上传 | upload | 操作 |
| 下载 | download | 操作 |
| 复制 | content_copy | 操作 |
| 粘贴 | content_paste | 操作 |
| 撤销 | undo | 操作 |
| 重做 | redo | 操作 |
| 测试 | bug_report | 操作 |
| 扫描 | radar | 操作 |

---

## 7. 动效规范

### 7.1 过渡动画

| 动画 | 时长 | 缓动函数 | 说明 |
|------|------|---------|------|
| 页面切换 | 300ms | ease-in-out | 淡入淡出 + 轻微滑动 |
| 侧边栏展开/折叠 | 200ms | ease-in-out | 宽度变化 |
| 对话框出现 | 200ms | decelerate | 缩放 + 淡入 |
| 对话框消失 | 150ms | accelerate | 缩放 + 淡出 |
| 按钮按下 | 100ms | ease-out | 缩放 0.98 |
| 卡片悬停 | 150ms | ease-in-out | 上移 + 阴影 |
| Toast 出现 | 200ms | decelerate | 从底部滑入 |
| Toast 消失 | 150ms | accelerate | 向底部滑出 |
| 协议表单切换 | 250ms | ease-in-out | 高度变化 + 淡入淡出 |
| 下拉菜单展开 | 150ms | decelerate | 缩放 + 淡入 |
| 列表项添加 | 200ms | decelerate | 高度从0展开 |
| 列表项删除 | 200ms | accelerate | 高度收缩到0 |

### 7.2 微交互

- **按钮悬停**: 亮度变化 + 阴影提升
- **卡片悬停**: 轻微上移 (translateY -2px) + 阴影提升
- **输入框聚焦**: 边框颜色变化 + 标签上浮
- **列表项选中**: 背景色变化 + 左侧指示条 (3px Primary)
- **加载状态**: 循环动画，避免闪烁
- **协议切换**: 当前表单淡出，新表单淡入，高度自适应
- **表单验证**: 错误提示从下方滑入，成功提示绿色对勾

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
| Desktop | >=1280px | 完整侧边栏 (240px) + 内容区 |
| Tablet | >=768px | 折叠侧边栏 (72px) + 内容区 |
| Mobile | <768px | 底部导航 + 全宽内容 |

### 8.3 内容区最大宽度

- 标准内容: 100% (自适应)
- 表单内容: max-width 800px, 居中
- 表格内容: 100% (水平滚动)
- 对话框: max-width 560px (标准), 800px (大对话框)

---

## 9. 状态规范

### 9.1 组件状态

| 状态 | 视觉表现 |
|------|---------|
| Normal | 标准样式 |
| Hover | 亮度 +10%, 阴影提升 |
| Focused | 2px Primary 边框 |
| Pressed | 亮度 -10%, 缩放 0.98 |
| Disabled | 透明度 38%, 无交互 |
| Selected | Primary Container 背景 |
| Error | Error 颜色边框 + 错误提示 |
| Loading | 加载指示器替代内容 |

### 9.2 加载状态

- **按钮加载**: 显示 CircularProgressIndicator (16px), 文字隐藏
- **页面加载**: 全屏骨架屏或 CircularProgressIndicator
- **数据加载**: 列表项骨架屏
- **操作加载**: 遮罩层 + CircularProgressIndicator
- **协议切换加载**: 表单区域显示骨架屏

### 9.3 空状态

- 图标: 48px, On Surface Variant 颜色
- 标题: Title Medium, On Surface
- 描述: Body Medium, On Surface Variant
- 操作按钮: Primary Button (可选)

### 9.4 表单验证状态

| 状态 | 视觉表现 |
|------|---------|
| 未验证 | 标准样式 |
| 验证中 | 输入框右侧显示 CircularProgressIndicator (16px) |
| 验证通过 | 输入框右侧显示 check_circle (20px, Success color) |
| 验证失败 | 输入框边框变 Error color，下方显示错误提示 |
| 必填未填 | 标签旁显示 * (Error color)，提交时提示 |

---

## 10. 设备配置页特殊组件规范

### 10.1 协议选择器 (Protocol Selector)

#### 外观
- 类型: Dropdown Input
- 宽度: 100% (父容器)
- 高度: 56px
- 选项列表:
  - 每项高度: 64px (含描述)
  - 图标: 24px, Primary color
  - 协议名称: Title Medium, On Surface
  - 协议描述: Body Small, On Surface Variant
  - 分隔线: 1px Outline Variant (选项间)

#### 选项内容
| 协议 | 图标 | 名称 | 描述 |
|------|------|------|------|
| Virtual | developer_board | Virtual | 虚拟设备（用于测试和模拟） |
| Modbus TCP | lan | Modbus TCP | TCP/IP 网络通信协议 |
| Modbus RTU | usb | Modbus RTU | 串口通信协议 |

#### 交互
- 选择后: 动态加载对应协议表单，动画 250ms
- 切换时: 清除当前协议表单数据（需确认）
- 禁用: 编辑模式下不可切换协议

### 10.2 协议参数表单容器

#### 外观
- 背景: Surface Container Lowest
- 边框: 1px Outline Variant
- 圆角: 16px
- 内边距: 24px
- 标题: Title Medium + 协议图标
- 动画: 高度自适应，内容淡入

### 10.3 测点配置表格 (Point Config Table)

#### 外观
- 表头: Surface Container Low 背景
- 列: 名称 | 功能码 | 地址 | 类型 | 缩放 | 偏移 | 操作
- 行高: 44px
- 添加按钮: Text Button, add icon
- 删除按钮: IconButton, delete icon, Error color
- 空状态: "暂无测点，点击添加"

#### 字段说明
| 字段 | 输入类型 | 宽度 | 验证 |
|------|---------|------|------|
| 名称 | Text Input | 120px | 必填, 2-30字符 |
| 功能码 | Dropdown | 100px | 必填, 1/2/3/4 |
| 地址 | Number Input | 80px | 必填, 0-65535 |
| 类型 | Dropdown | 100px | 必填 |
| 缩放 | Number Input | 80px | 数字 |
| 偏移 | Number Input | 80px | 数字 |
| 操作 | IconButton | 40px | - |

### 10.4 连接测试按钮

#### 外观
- 类型: Outlined Button
- 图标: bug_report
- 文字: "测试连接"
- 状态:
  - 未测试: 标准 Outlined Button
  - 测试中: 显示 CircularProgressIndicator, 文字 "测试中..."
  - 成功: 图标变 check_circle, 文字 "连接成功", Success color
  - 失败: 图标变 error, 文字 "连接失败", Error color

### 10.5 串口扫描按钮

#### 外观
- 类型: Text Button
- 图标: radar
- 文字: "扫描串口"
- 位置: 串口选择框右侧
- 状态:
  - 未扫描: 标准 Text Button
  - 扫描中: 图标旋转动画, 文字 "扫描中..."
  - 完成: 图标变 check_circle, 文字 "扫描完成"

---

## 11. 深色/浅色主题完整规范

### 11.1 主题切换

- 切换方式: 设置页开关 / 系统跟随
- 切换动画: 全局过渡 300ms
- 存储: 本地存储用户偏好

### 11.2 浅色主题 (Light Theme)

- 页面背景: Surface (#FFFFFF)
- 卡片背景: Surface (#FFFFFF)
- 侧边栏背景: Surface Container Low (#F5F5F5)
- 应用栏背景: Primary (#1976D2)
- 应用栏文字: On Primary (#FFFFFF)
- 主要文字: On Surface (#212121)
- 次要文字: On Surface Variant (#757575)
- 边框: Outline (#E0E0E0)
- 分割线: Outline Variant (#EEEEEE)
- 阴影: 黑色，透明度 8%-32%

### 11.3 深色主题 (Dark Theme)

- 页面背景: Surface (#121212)
- 卡片背景: Surface Container Low (#1E1E1E)
- 侧边栏背景: Surface Container (#2D2D2D)
- 应用栏背景: Surface Container High (#3D3D3D)
- 应用栏文字: On Surface (#F5F5F5)
- 主要文字: On Surface (#F5F5F5)
- 次要文字: On Surface Variant (#9E9E9E)
- 边框: Outline (#424242)
- 分割线: Outline Variant (#333333)
- 阴影: 黑色，透明度 16%-48%

### 11.4 主题对比表

| 元素 | 浅色主题 | 深色主题 |
|------|---------|---------|
| 页面背景 | #FFFFFF | #121212 |
| 卡片背景 | #FFFFFF | #1E1E1E |
| 输入框背景 | #F5F5F5 | #2D2D2D |
| 选中背景 | #BBDEFB | #1565C0 |
| 悬停背景 | #EEEEEE | #333333 |
| 禁用背景 | #E0E0E0 | #424242 |
| 成功背景 | #E8F5E9 | #1B5E20 |
| 警告背景 | #FFF3E0 | #E65100 |
| 错误背景 | #FFEBEE | #B71C1C |
| 信息背景 | #E3F2FD | #0D47A1 |
| 主按钮 | #1976D2 | #90CAF9 |
| 主按钮文字 | #FFFFFF | #000000 |
| 次按钮 | #546E7A | #90A4AE |
| 边框 | #E0E0E0 | #424242 |
| 分割线 | #EEEEEE | #333333 |
| 阴影颜色 | rgba(0,0,0,0.08) | rgba(0,0,0,0.24) |

---

## 12. 辅助功能 (Accessibility)

### 12.1 对比度

- 正文文字与背景: 最低 4.5:1
- 大号文字与背景: 最低 3:1
- 交互元素与背景: 最低 3:1
- 所有颜色组合均通过 WCAG 2.1 AA 标准

### 12.2 焦点指示

- 所有交互元素必须有可见焦点指示
- 焦点样式: 2px Primary 颜色外边框
- 焦点偏移: 2px
- 键盘导航: Tab 键顺序合理

### 12.3 屏幕阅读器

- 所有图标必须有语义标签
- 表单字段必须有标签关联
- 动态内容变化必须有 ARIA 通知
- 对话框必须有标题和描述

### 12.4 触摸目标

- 最小触摸目标: 48x48dp
- 按钮间距: 最小 8px
- 图标按钮: 40x40dp (视觉) + 48x48dp (触摸)

---

**文档结束**
