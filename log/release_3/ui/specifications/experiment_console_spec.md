# TASK-023: 试验控制台 UI 设计规范

> **路由**: `/experiments/:id`  
> **依赖**: TASK-007 (可复用组件库)、TASK-020 (WsService, ExperimentProvider)  
> **设计师**: sw-anna  
> **日期**: 2026-06-02  
> **状态**: 设计稿完成

---

## 目录

1. [页面布局](#1-页面布局)
2. [顶部栏 (AppBar)](#2-顶部栏-appbar)
3. [控制面板 (左侧)](#3-控制面板-左侧)
4. [执行日志区 (右侧)](#4-执行日志区-右侧)
5. [响应式适配](#5-响应式适配)
6. [主题适配](#6-主题适配)
7. [动画与交互](#7-动画与交互)
8. [状态矩阵](#8-状态矩阵)
9. [设计 QA 检查项](#9-设计-qa-检查项)

---

## 1. 页面布局

### 1.1 整体结构

```
ExperimentConsolePage
├── AppBar (56px desktop / 64px mobile)
│   ├── Back Button → 返回 /experiments
│   ├── Experiment Name + StatusBadge
│   └── WS Connection Indicator
├── Content Area (flex: 1, responsive)
│   ├── Control Panel (左侧/上方)
│   │   ├── Info Card (工作台、方法、创建时间)
│   │   ├── Control Buttons (载入/开始/暂停/继续/停止)
│   │   ├── Status Display (大字状态)
│   │   └── Timer (运行时长)
│   └── Log Viewer (右侧/下方)
│       ├── Log List (等宽字体，可滚动)
│       ├── Floating "New Logs" Button (条件显示)
│       └── Log Controls (筛选 + 清空)
└── Stop Confirm Dialog (条件弹出)
```

### 1.2 布局参数

| 属性 | 桌面端 (≥1200px) | 平板 (600-1200px) | 移动端 (<600px) |
|------|------------------|-------------------|-----------------|
| Page Background | Background color token | Background color token | Background color token |
| Content Layout | Row, 左右分栏 | Row, 左右分栏 | Column, 上下堆叠 |
| Control Panel Width | 38% (min 400px, max 520px) | 40% (min 320px) | 100% |
| Log Viewer Width | 62% (flex) | 60% (flex) | 100% |
| Panel Gap | spaceLg (24px) | spaceMd (16px) | spaceMd (16px) |
| Content Padding | spaceLg (24px) | spaceMd (16px) | spaceMd (16px) |
| Panel Padding | spaceLg (24px) | spaceMd (16px) | spaceMd (16px) |
| Panel Border Radius | radiusLarge (12px) | radiusLarge (12px) | radiusMedium (8px) |
| Panel Background | Surface | Surface | Surface |
| Panel Elevation | 1 | 1 | 0 (扁平) |

---

## 2. 顶部栏 (AppBar)

### 2.1 布局结构

```
AppBar (56px, Surface fill, bottom border 1px Outline Variant)
├── Row (mainAxisAlignment: spaceBetween)
│   ├── Left Group
│   │   ├── Back Button (IconButton: Icons.arrow_back, 48×48dp)
│   │   │   └── Tooltip: "返回列表" / "Back to list"
│   │   ├── SizedBox(width: spaceMd)
│   │   ├── Experiment Name (Title Medium, On Surface)
│   │   │   └── Max width: 400px, overflow: ellipsis
│   │   ├── SizedBox(width: spaceSm)
│   │   └── StatusBadge (StatusChip, 与状态对应)
│   │       └── 如: "RUNNING" (绿色 + 脉冲动画)
│   └── Right Group
│       ├── WS Connection Chip
│       │   ├── Connection Dot (10px, 圆形)
│       │   ├── SizedBox(width: spaceXs)
│       │   └── Connection Text (Body Small)
│       │       └── 如: "已连接" / "连接中..." / "已断开"
│       └── [Optional] Reconnect Button (TextButton, failed 状态显示)
```

### 2.2 返回按钮

| 属性 | 值 |
|------|-----|
| 图标 | `Icons.arrow_back` (24px) |
| 尺寸 | 48×48dp 触摸目标 |
| 颜色 | On Surface |
| Tooltip | "返回列表" / "Back to list" |
| 行为 | 导航到 `/experiments`，触发 WS disconnect |

### 2.3 试验名称

| 属性 | 值 |
|------|-----|
| 样式 | Title Medium, On Surface |
| 最大宽度 | 400px (桌面) / 200px (平板) / 120px (移动端，截断) |
| 溢出处理 | ellipsis |
| 右侧间距 | spaceSm (8px) |

### 2.4 状态徽章 (StatusBadge / StatusChip)

基于 Material `Chip` 组件自定义：

| 状态 | 文本 | 背景色 | 文字色 | 动画 |
|------|------|--------|--------|------|
| IDLE | IDLE | Surface Variant | On Surface Variant | 无 |
| LOADED | LOADED | Primary at 15% | Primary | 无 |
| RUNNING | RUNNING | Success at 15% | Success | **脉冲动画** |
| PAUSED | PAUSED | Warning at 15% | Warning | 无 |
| COMPLETED | COMPLETED | Success at 15% | Success | 无 |
| ABORTED | ABORTED | Error at 15% | Error | 无 |

**脉冲动画参数 (RUNNING 状态)：**
- 动画类型: 透明度 + 缩放呼吸
- 透明度: 1.0 → 0.6 → 1.0
- 缩放: 1.0 → 1.05 → 1.0
- 时长: 2000ms
- 缓动: ease-in-out
- 循环: 无限

### 2.5 WebSocket 连接指示器

| 连接状态 | 圆点颜色 | 文本 | 文本样式 |
|----------|----------|------|----------|
| disconnected | Error (🔴) | "已断开" / "Disconnected" | Body Small, Error |
| connecting | Warning (🟡) | "连接中..." / "Connecting..." | Body Small, Warning |
| connected | Success (🟢) | "已连接" / "Connected" | Body Small, Success |
| reconnecting | Warning (🟡) | "重连中(N/5)" / "Reconnecting (N/5)" | Body Small, Warning |
| failed | Error (🔴) | "连接失败" / "Connection failed" | Body Small, Error |

**圆点样式：**
- 尺寸: 10×10px
- 形状: 圆形
- 动画 (connecting/reconnecting): 闪烁动画，透明度 0.4 → 1.0 → 0.4，1000ms 循环

**手动重连按钮 (failed 状态)：**
- 样式: TextButton
- 文字: "重新连接" / "Reconnect"
- 图标: `Icons.refresh` (18px)
- 颜色: Primary

---

## 3. 控制面板 (左侧)

### 3.1 信息卡片 (Info Card)

```
Info Section (Surface Container Low, radiusLarge, padding: spaceLg)
├── Row 1: 工作台
│   ├── Label: "工作台" / "Workbench" (Body Small, On Surface Variant)
│   └── Value: "温度实验室" (Body Large, On Surface)
│       └── [Loading] → 骨架行 (60%宽度 shimmer)
│       └── [Error] → "—" 或 methodId 回显
├── Divider (1px Outline Variant, margin: spaceMd vertical)
├── Row 2: 方法
│   ├── Label: "方法" / "Method" (Body Small, On Surface Variant)
│   └── Value: "标准热循环" (Body Large, On Surface)
│       └── [Loading] → 骨架行
│       └── [Error] → "—"
├── Divider
└── Row 3: 创建时间
    ├── Label: "创建时间" / "Created" (Body Small, On Surface Variant)
    └── Value: "2026-06-02 09:30" (Body Medium, On Surface)
        └── 格式: YYYY-MM-DD HH:mm (中文) / MM/DD/YYYY HH:mm (英文)
```

**Row 样式参数：**

| 属性 | 值 |
|------|-----|
| 布局 | Column, crossAxisAlignment: start |
| Label-Value 间距 | spaceXs (4px) |
| 行间距 | spaceMd (16px) |
| Divider 间距 | spaceMd (16px) vertical |

### 3.2 控制按钮组 (Control Buttons)

```
Button Group (padding-top: spaceLg)
├── Row 1
│   ├── [载入] Button (load)
│   ├── SizedBox(width: spaceMd)
│   ├── [开始] Button (start)
│   ├── SizedBox(width: spaceMd)
│   └── [暂停] Button (pause)
└── Row 2 (padding-top: spaceMd)
    ├── [继续] Button (resume)
    ├── SizedBox(width: spaceMd)
    └── [停止] Button (stop - danger style)
```

**按钮规格：**

| 按钮 | 样式 | 正常色 | Loading 状态 |
|------|------|--------|--------------|
| 载入 | FilledButton | Primary | Primary + CircularProgressIndicator |
| 开始 | FilledButton | Primary | Primary + CircularProgressIndicator |
| 暂停 | FilledButton | Warning | Warning + CircularProgressIndicator |
| 继续 | FilledButton | Primary | Primary + CircularProgressIndicator |
| 停止 | FilledButton.tonal / 自定义 | Error Container / Error | Error + CircularProgressIndicator |

**按钮尺寸：**

| 属性 | 桌面端 | 移动端 |
|------|--------|--------|
| 高度 | 40px | 48px (最小触摸目标) |
| 最小宽度 | 100px | 80px |
| 内边距 | 0 16px | 0 12px |
| 圆角 | radiusMedium (8px) | radiusMedium (8px) |
| 图标尺寸 | 20px | 20px |
| 图标-文字间距 | spaceSm (8px) | spaceSm (8px) |

**按钮图标映射：**

| 按钮 | 图标 | 禁用图标 |
|------|------|----------|
| 载入 | `Icons.download` | `Icons.download` (38% opacity) |
| 开始 | `Icons.play_arrow` | `Icons.play_arrow` (38% opacity) |
| 暂停 | `Icons.pause` | `Icons.pause` (38% opacity) |
| 继续 | `Icons.play_arrow` | `Icons.play_arrow` (38% opacity) |
| 停止 | `Icons.stop` | `Icons.stop` (38% opacity) |

**停止按钮危险样式 (Danger Button)：**

| 属性 | 值 |
|------|-----|
| 背景色 | Error Container |
| 文字色 | On Error Container |
| 悬停背景 | Error at 12% opacity overlay |
| 按下背景 | Error at 24% opacity overlay |

### 3.3 状态显示 (Status Display)

```
Status Section (padding-top: spaceXl, center aligned)
├── Status Label: "状态" / "Status" (Body Small, On Surface Variant)
├── SizedBox(height: spaceSm)
├── Status Text: "RUNNING" (Display Small / Headline Small)
│   └── 颜色: 与状态对应 (见 3.4)
├── SizedBox(height: spaceXs)
└── Status Subtitle (条件显示)
    └── 如: "试验运行中" / "Experiment running" (Body Small, On Surface Variant)
```

**状态大字样式：**

| 属性 | 值 |
|------|-----|
| 字号 | 32px (桌面) / 28px (移动端) |
| 字重 | 600 (FontWeight.w600) |
| 字间距 | 0.5px |
| 对齐 | 居中 |

**终态提示文本 (COMPLETED/ABORTED)：**

| 状态 | 提示文本 |
|------|----------|
| COMPLETED | "试验已完成" / "Experiment completed" |
| ABORTED | "试验已中止" / "Experiment aborted" |

### 3.4 状态颜色映射

| 状态 | 状态大字颜色 | 标签背景 | 标签文字 |
|------|-------------|----------|----------|
| IDLE | On Surface Variant | Surface Variant | On Surface Variant |
| LOADED | Primary | Primary at 15% | Primary |
| RUNNING | Success | Success at 15% | Success |
| PAUSED | Warning | Warning at 15% | Warning |
| COMPLETED | Success | Success at 15% | Success |
| ABORTED | Error | Error at 15% | Error |

### 3.5 计时器 (Timer)

```
Timer Section (padding-top: spaceLg, center aligned)
├── Timer Label: "已运行" / "Elapsed" (Body Small, On Surface Variant)
├── SizedBox(height: spaceSm)
├── Timer Value: "02:15:32" (Monospace font, 36px/32px)
│   └── 颜色: On Surface
│   └── [PAUSED] → 颜色: On Surface Variant (冻结视觉提示)
│   └── [IDLE/LOADED 无 startedAt] → 不显示此区域
└── [Optional] Start Time
    └── "开始时间: 14:30" (Body Small, On Surface Variant)
```

**计时器样式参数：**

| 属性 | 值 |
|------|-----|
| 字体 | monospace (Roboto Mono 或系统等宽) |
| 字号 | 36px (桌面) / 32px (移动端) |
| 字重 | 500 |
| 字间距 | 2px (等宽数字不需要，但增加可读性) |
| 颜色 | On Surface (运行中), On Surface Variant (暂停/终态) |
| 格式 | HH:MM:SS (始终两位数，前导零) |

**计时器显示规则：**

| 状态 | 显示内容 | 是否实时更新 |
|------|----------|:------------:|
| IDLE | 不显示 | — |
| LOADED | 不显示 | — |
| RUNNING | 从 startedAt 计算，每秒更新 | ✅ |
| PAUSED | 冻结在暂停时刻的值 | ❌ |
| COMPLETED | 显示 endedAt - startedAt 固定值 | ❌ |
| ABORTED | 显示 endedAt - startedAt 固定值 或 "—" | ❌ |

### 3.6 完成/中止状态额外信息

```
Completed/Aborted Extra Info (padding-top: spaceMd)
├── Start Time Row
│   ├── Label: "开始时间" / "Started" (Body Small)
│   └── Value: "2026-06-02 14:30" (Body Medium)
├── End Time Row (padding-top: spaceSm)
│   ├── Label: "结束时间" / "Ended" (Body Small)
│   └── Value: "2026-06-02 14:45" (Body Medium)
└── Total Duration Row (padding-top: spaceSm)
    ├── Label: "总运行时长" / "Total Duration" (Body Small)
    └── Value: "00:15:30" (Body Medium, monospace)
```

---

## 4. 执行日志区 (右侧)

### 4.1 日志区整体结构

```
Log Viewer (Surface, radiusLarge, flex: 1)
├── Log List Area (flex: 1, Scrollable)
│   ├── [Empty] → Empty State
│   └── [Has Logs] → Log Entries (ListView.builder)
├── Floating "New Logs" Button (条件显示, bottom-right)
│   └── 如: "↓ 5 条新日志" / "↓ 5 new logs"
└── Log Control Bar (bottom, padding: spaceMd)
    ├── Level Filter Dropdown
    │   └── 选项: 全部 / INFO / WARN / ERROR / DEBUG
    ├── Spacer
    └── Clear Logs Button (TextButton)
```

### 4.2 日志区尺寸参数

| 属性 | 桌面端 | 移动端 |
|------|--------|--------|
| 最小高度 | 400px | 300px |
| 日志列表内边距 | spaceMd (16px) | spaceSm (12px) |
| 日志条目间距 | spaceXs (4px) | spaceXs (4px) |
| 控制栏高度 | 48px | 48px |
| 控制栏背景 | Surface Container Low | Surface Container Low |
| 控制栏顶部边框 | 1px Outline Variant | 1px Outline Variant |

### 4.3 日志条目 (Log Entry)

```
Log Entry (padding: spaceXs vertical)
├── Row (crossAxisAlignment: start)
│   ├── Level Tag
│   │   ├── Text: "[INFO]" (monospace, 13px)
│   │   └── 颜色: 与级别对应
│   ├── SizedBox(width: spaceSm)
│   ├── Timestamp
│   │   ├── Text: "14:30:01" (monospace, 13px)
│   │   └── 颜色: On Surface Variant
│   ├── SizedBox(width: spaceSm)
│   └── Message
│       ├── Text: "试验开始" (monospace, 13px)
│       └── 颜色: On Surface
│       └── 自动换行，缩进对齐
```

**日志条目样式参数：**

| 属性 | 值 |
|------|-----|
| 字体 | monospace (Roboto Mono 或系统等宽) |
| 字号 | 13px (桌面) / 12px (移动端) |
| 行高 | 20px |
| 字间距 | 0 |
| 内边距 | spaceXs (4px) vertical |

**日志级别颜色：**

| 级别 | 标签文本 | 标签背景 | 示例 |
|------|----------|----------|------|
| DEBUG | `[DEBUG]` | Surface Variant | 灰色文字，无背景 |
| INFO | `[INFO]` | Primary at 8% | 蓝色文字 |
| WARN | `[WARN]` | Warning at 8% | 橙色文字 |
| ERROR | `[ERROR]` | Error at 12% | 红色文字，可加粗 |

**级别标签样式：**

| 属性 | 值 |
|------|-----|
| 内边距 | 1px 6px |
| 圆角 | radiusSmall (4px) |
| 字重 | 500 (FontWeight.w500) |
| 最小宽度 | 52px (对齐用) |

**长消息处理：**
- 自动换行: `softWrap: true`
- 不显示水平滚动条
- 换行后缩进: 与第一行消息起始位置对齐 (使用 `Wrap` 或 `IntrinsicWidth` 实现)
- 最大行数: 无限制

### 4.4 空日志状态

```
Empty Log State (center, min-height: 200px)
├── Icon: `Icons.terminal_outlined` (40px, On Surface Variant at 40%)
├── SizedBox(height: spaceMd)
├── Text: "等待日志..." / "Waiting for logs..." (Body Medium, On Surface Variant)
└── Subtext: "试验开始后日志将显示在这里" / "Logs will appear when experiment starts"
    └── Body Small, On Surface Variant at 60%
```

### 4.5 浮动 "新日志" 按钮

| 属性 | 值 |
|------|-----|
| 位置 | 日志列表右下角，距边缘 spaceMd |
| 样式 | FilledButton.tonal 或 ElevatedButton |
| 背景 | Primary Container |
| 文字色 | On Primary Container |
| 图标 | `Icons.arrow_downward` (18px) |
| 文字 | "N 条新日志" / "N new logs" (Body Small) |
| 圆角 | radiusCircular (pill shape) |
| 阴影 | Elevation 2 |
| 进入动画 | 从下方滑入 + 淡入，200ms |
| 离开动画 | 向下滑出 + 淡出，150ms |
| 安全距离 | 距日志列表底部至少 56px (不遮挡最后一行) |

### 4.6 日志控制栏

```
Log Control Bar (height: 48px, Surface Container Low)
├── Level Filter
│   └── DropdownButton (compact)
│       ├── 当前值: "全部" / "All"
│       ├── 图标: `Icons.filter_list` (18px)
│       └── 选项列表: All, INFO, WARN, ERROR, DEBUG
├── Spacer
└── Clear Button (TextButton, compact)
    ├── 图标: `Icons.clear_all` (18px)
    └── 文字: "清空日志" / "Clear"
```

**筛选下拉框样式：**

| 属性 | 值 |
|------|-----|
| 高度 | 36px |
| 背景 | Surface |
| 边框 | 1px Outline |
| 圆角 | radiusSmall (4px) |
| 文字 | Body Small |
| 下拉菜单最大高度 | 240px |

**清空按钮状态：**

| 条件 | 状态 |
|------|------|
| 日志区为空 | 禁用 (38% opacity) |
| 日志区有内容 | 可用 |
| 点击后 | 日志清空，按钮变为禁用 |

---

## 5. 响应式适配

### 5.1 断点定义

| 断点 | 宽度 | 布局 | 控制面板 | 日志区 | 按钮排列 |
|------|------|------|----------|--------|----------|
| Desktop | ≥1200px | 左右分栏 Row | 左侧 38% | 右侧 62% | 水平双行 |
| Tablet | 600-1200px | 左右分栏 Row | 左侧 40% | 右侧 60% | 水平双行/换行 |
| Mobile | <600px | 上下堆叠 Column | 上方 | 下方 | Wrap 自适应 |

### 5.2 桌面端适配 (≥1200px)

- 左右分栏，间距 spaceLg (24px)
- 控制面板固定宽度 38%，最小 400px，最大 520px
- 按钮水平排列，双行
- 状态大字 32px
- 计时器 36px
- 日志区有足够宽度显示完整消息

### 5.3 平板适配 (600-1200px)

- 左右分栏，间距 spaceMd (16px)
- 控制面板占比 40%，最小 320px
- 按钮水平排列，空间不足时自动换行 (Wrap)
- 状态大字 28px
- 计时器 32px
- 试验名称最大宽度缩减至 200px

### 5.4 移动端适配 (<600px)

- **上下堆叠**: 控制面板在上方，日志区在下方
- 控制面板高度自适应，不要占满屏幕 (建议 max-height: 50vh)
- 按钮使用 `Wrap` 排列，自动换行
- 按钮全宽或至少 48px 高度 (Material 触摸目标)
- 状态大字 28px
- 计时器 32px
- 试验名称截断至 120px
- AppBar 高度 64px
- 日志区最小高度 300px
- 顶部栏: WS 状态可能只显示圆点 (省略文字)

### 5.5 超小屏适配 (<400px)

- 顶部栏试验名称可能只显示前 8 个字符 + "..."
- 按钮变为 2×3 网格排列
- WS 状态仅显示圆点
- 日志级别标签简化为单字母: D/I/W/E
- 计时器字号 28px

---

## 6. 主题适配

### 6.1 Light Theme

| 元素 | 颜色 |
|------|------|
| Page Background | Background (#FDFCFF) |
| Panel Background | Surface (#FFFFFF) |
| Panel Border | Outline Variant (#C4C6D0) |
| Info Card Background | Surface Container Low (#F1F4F9) |
| Status IDLE | On Surface Variant (#44474E) |
| Status LOADED | Primary (#1976D2) |
| Status RUNNING | Success (#2E7D32) |
| Status PAUSED | Warning (#ED6C02) |
| Status COMPLETED | Success (#2E7D32) |
| Status ABORTED | Error (#BA1A1A) |
| Log DEBUG | On Surface Variant (#44474E) |
| Log INFO | Primary (#1976D2) |
| Log WARN | Warning (#ED6C02) |
| Log ERROR | Error (#BA1A1A) |
| Timer Running | On Surface (#1A1C1E) |
| Timer Paused | On Surface Variant (#44474E) |
| Stop Button Background | Error Container (#FFDAD6) |
| Stop Button Text | On Error Container (#410002) |
| New Logs Button | Primary Container (#D1E4FF) |

### 6.2 Dark Theme

| 元素 | 颜色 |
|------|------|
| Page Background | Background (#1A1C1E) |
| Panel Background | Surface (#1A1C1E) |
| Panel Border | Outline Variant (#44474E) |
| Info Card Background | Surface Container Low (#1D2023) |
| Status IDLE | On Surface Variant (#C4C6CF) |
| Status LOADED | Primary Dark (#90CAF9) |
| Status RUNNING | Success Dark (#81C784) |
| Status PAUSED | Warning Dark (#FFB74D) |
| Status COMPLETED | Success Dark (#81C784) |
| Status ABORTED | Error Dark (#FFB4AB) |
| Log DEBUG | On Surface Variant (#C4C6CF) |
| Log INFO | Primary Dark (#90CAF9) |
| Log WARN | Warning Dark (#FFB74D) |
| Log ERROR | Error Dark (#FFB4AB) |
| Timer Running | On Surface (#E2E2E6) |
| Timer Paused | On Surface Variant (#C4C6CF) |
| Stop Button Background | Error Container Dark (#93000A) |
| Stop Button Text | On Error Container Dark (#FFDAD6) |
| New Logs Button | Primary Container Dark (#004A7F) |

---

## 7. 动画与交互

### 7.1 页面进入动画

| 元素 | 动画 | 时长 | 缓动 |
|------|------|------|------|
| 页面整体 | Fade + Slide from right | 250ms | ease-out |
| 控制面板 | Fade + Slide from left (50px) | 300ms | ease-out, delay 50ms |
| 日志区 | Fade + Slide from right (50px) | 300ms | ease-out, delay 100ms |

### 7.2 状态变更动画

| 变更 | 动画 | 时长 |
|------|------|------|
| 状态文字变化 | 淡出 (100ms) → 文字更新 → 淡入 (150ms) | 250ms total |
| 按钮启用/禁用 | 透明度渐变 200ms | 200ms |
| 状态标签颜色 | 颜色过渡 (ColorTween) | 200ms |
| 脉冲动画开始 | Scale 0.95 → 1.0 + Opacity 0 → 1 | 300ms |

### 7.3 按钮交互

| 状态 | 视觉 |
|------|------|
| Hover | Elevation +1, 背景色轻微加深 |
| Pressed | Scale 0.97, Elevation +2 |
| Loading | 文字淡出 (100ms) → CircularProgressIndicator 淡入 (100ms) |
| Disabled | 38% opacity, 无交互效果 |

### 7.4 日志区动画

| 动画 | 参数 |
|------|------|
| 新日志追加 | 条目从上方滑入 (translateY: -10px → 0), 150ms, ease-out |
| 自动滚动 | 平滑滚动到底部, 200ms, ease-out |
| 清空日志 | 所有条目同时淡出, 150ms, 然后列表重置 |
| 筛选切换 | 条目交叉淡入淡出, 150ms |
| 浮动按钮出现 | Slide from bottom (20px) + Fade, 200ms, ease-out |
| 浮动按钮消失 | Slide to bottom (20px) + Fade, 150ms, ease-in |

### 7.5 计时器动画

| 场景 | 动画 |
|------|------|
| 数字变化 | 无动画 (直接更新，秒级不需要平滑过渡) |
| 从隐藏到显示 | 淡入 200ms |
| RUNNING → PAUSED | 颜色过渡到 On Surface Variant, 300ms |
| PAUSED → RUNNING | 颜色过渡到 On Surface, 300ms |

### 7.6 确认对话框

**停止确认对话框 (ConfirmDialog 危险变体)：**

```
ConfirmDialog (Danger Variant)
├── Title: "确认停止试验?" / "Stop Experiment?"
│   └── Title Medium, On Surface
│   └── 前缀图标: `Icons.warning_amber` (20px, Error)
├── Description
│   └── "确定要停止当前试验吗？此操作不可撤销。"
│   └── Body Medium, On Surface Variant
├── Button Row
│   ├── [取消] TextButton (Primary)
│   └── [确认停止] FilledButton (Error background)
└── Scrim (Background at 60%)
```

| 属性 | 值 |
|------|-----|
| 对话框宽度 | min 320px, max 480px |
| 圆角 | radiusLarge (12px) |
| 进入动画 | 遮罩淡入 150ms + 对话框缩放淡入 200ms |
| 离开动画 | 反向 150ms |

---

## 8. 状态矩阵

### 8.1 六状态完整规格

| 状态 | 信息面板 | 可用按钮 | 状态显示 | 计时器 | 终态提示 |
|------|----------|----------|----------|--------|----------|
| **IDLE** | 完整信息 | 仅 载入 | IDLE (灰色) | 隐藏 | 无 |
| **LOADED** | 完整信息 | 仅 开始 | LOADED (蓝色) | 隐藏 | 无 |
| **RUNNING** | 完整信息 | 暂停 + 停止 | RUNNING (绿色+脉冲) | 实时递增 | 无 |
| **PAUSED** | 完整信息 | 继续 + 停止 | PAUSED (橙色) | 冻结 | 无 |
| **COMPLETED** | 完整信息 + 起止时间 | 全部禁用 | COMPLETED (绿色) | 固定总时长 | "试验已完成" |
| **ABORTED** | 完整信息 + 起止时间 + 错误消息 | 全部禁用 | ABORTED (红色) | 固定总时长 或 "—" | "试验已中止" |

### 8.2 按钮状态矩阵

| 当前状态 | 载入 | 开始 | 暂停 | 继续 | 停止 |
|---------|:--:|:--:|:--:|:--:|:--:|
| IDLE | ✅ | ❌ | ❌ | ❌ | ❌ |
| LOADED | ❌ | ✅ | ❌ | ❌ | ❌ |
| RUNNING | ❌ | ❌ | ✅ | ❌ | ✅ |
| PAUSED | ❌ | ❌ | ❌ | ✅ | ✅ |
| COMPLETED | ❌ | ❌ | ❌ | ❌ | ❌ |
| ABORTED | ❌ | ❌ | ❌ | ❌ | ❌ |

### 8.3 操作加载状态

点击任何控制按钮后：
1. 被点击按钮显示 CircularProgressIndicator (20px, 2px stroke)
2. 按钮文字隐藏或替换为 "处理中..."
3. **所有其他控制按钮同时禁用** (防重复提交)
4. 操作完成后，按钮恢复为对应状态的可用性

### 8.4 错误状态恢复

操作失败后：
1. 被点击按钮从 loading 恢复
2. 显示 Error Toast: "操作失败: {具体原因}"
3. 所有按钮恢复为当前状态对应可用性
4. 试验状态刷新为后端实际状态

---

## 9. 设计 QA 检查项

### 9.1 布局检查

- [ ] 桌面端: 左右分栏，比例约 38:62
- [ ] 平板端: 左右分栏，比例约 40:60
- [ ] 移动端: 上下堆叠，控制面板在上方
- [ ] 窗口大小变化时布局实时调整，无闪烁
- [ ] 控制面板和日志区都有圆角和背景色区分

### 9.2 顶部栏检查

- [ ] 返回按钮可点击，导航到 `/experiments`
- [ ] 试验名称显示正确，溢出时 ellipsis
- [ ] 状态徽章颜色与状态匹配
- [ ] RUNNING 状态徽章有脉冲动画
- [ ] WS 连接指示器颜色与连接状态匹配
- [ ] connecting/reconnecting 状态圆点有闪烁动画
- [ ] failed 状态显示手动重连按钮

### 9.3 控制面板检查

- [ ] 工作台、方法、创建时间正确显示
- [ ] 信息加载中显示骨架屏
- [ ] 按钮状态与当前状态匹配 (状态矩阵)
- [ ] 禁用按钮视觉正确 (38% opacity)
- [ ] 停止按钮使用危险样式 (Error Container)
- [ ] 状态大字正确显示，颜色正确
- [ ] RUNNING 状态大字无脉冲 (仅徽章脉冲)
- [ ] 计时器格式 HH:MM:SS，等宽字体
- [ ] RUNNING 时计时器每秒更新
- [ ] PAUSED 时计时器冻结
- [ ] IDLE/LOADED 时计时器隐藏
- [ ] COMPLETED/ABORTED 显示总时长和起止时间

### 9.4 日志区检查

- [ ] 等宽字体显示
- [ ] 日志级别颜色正确 (DEBUG灰/INFO蓝/WARN橙/ERROR红)
- [ ] 时间戳格式 HH:MM:SS
- [ ] 长消息自动换行，无水平滚动条
- [ ] 空日志显示空状态
- [ ] 新日志自动滚动到底部
- [ ] 手动上滚时显示 "新日志" 浮动按钮
- [ ] 点击浮动按钮平滑滚动到底部
- [ ] 筛选下拉框可用，切换后日志过滤正确
- [ ] 清空按钮清空所有日志 (非仅筛选可见)
- [ ] 空日志时清空按钮禁用

### 9.5 交互检查

- [ ] 点击控制按钮显示 loading，其他按钮禁用
- [ ] 操作失败显示 Error Toast
- [ ] 点击停止弹出确认对话框
- [ ] 确认对话框中 "确认停止" 为红色
- [ ] 取消对话框后状态不变
- [ ] 页面离开时 WS 断开
- [ ] 返回按钮导航正确

### 9.6 主题检查

- [ ] Light 主题所有颜色正确
- [ ] Dark 主题所有颜色正确
- [ ] 状态颜色在 Dark 主题下正确映射
- [ ] 日志颜色在 Dark 主题下可读
- [ ] 按钮危险样式在 Dark 主题下正确

### 9.7 响应式检查

- [ ] Mobile (<600px): 布局上下堆叠
- [ ] Mobile: 按钮 Wrap 排列，触摸目标 ≥48px
- [ ] Mobile: 试验名称截断正确
- [ ] Tablet: 左右分栏维持
- [ ] Desktop: 完整布局
- [ ] 所有状态下响应式表现一致

---

**文档结束**
