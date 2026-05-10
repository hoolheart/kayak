# Figma 原型 - 分析页面 (Analysis Page)

**任务ID**: R2-S1-002-A  
**Figma 文件**: `kayak_r2.fig` > Page: `Analysis`  
**设计师**: sw-anna  
**日期**: 2026-05-10  
**状态**: 设计完成  
**适用范围**: Release 2 Sprint 1 — 时序数据可视化

---

## 1. 设计目标

分析页面是 Kayak 平台的时序数据可视化中心，用户通过该页面查看试验采集的历史数据。设计强调：
- **信息密度与可读性平衡**: 大面积图表区域 + 紧凑控制面板
- **专业科研工具感**: 清晰的坐标轴、精确的网格线、高对比度曲线
- **沉浸式数据探索**: 深色主题下图表采用更深背景，营造专注的分析氛围
- **高效操作流程**: 左侧控制面板一站式配置，右侧即时渲染

---

## 2. 页面布局架构

### 2.1 主 Frame

```
Frame: "Analysis Page - Desktop Light"
Width: 1440px
Height: 1080px
Background: Surface Container Lowest #FAFAFA
Layout: Row (sidebar + content), no scroll on page level

Frame: "Analysis Page - Desktop Dark"
Width: 1440px
Height: 1080px
Background: Surface #121212
Layout: Row (sidebar + content), no scroll on page level
```

### 2.2 内容区域结构

```
Analysis Page (within AppShell)
├── Sidebar (240px / 72px collapsed) — 复用现有组件
├── Main Content Area (flex)
│   ├── Breadcrumb Navigation (48px height)
│   │   └── 首页 > 分析
│   ├── Page Content (flex column, padding: 24px, gap: 16px)
│   │   ├── Page Header (56px)
│   │   │   ├── Page Title "数据分析" (Title Large)
│   │   │   └── Subtitle "查看试验时序数据" (Body Medium, On Surface Variant)
│   │   ├── Main Workspace (flex row, flex: 1, gap: 16px)
│   │   │   ├── Control Panel (320px fixed width)
│   │   │   │   ├── Experiment Selection Card
│   │   │   │   ├── Device & Point Selection Card
│   │   │   │   ├── Time Range Card
│   │   │   │   ├── Settings Card
│   │   │   │   └── Action Buttons
│   │   │   └── Chart Area (flex, flex column)
│   │   │       ├── Chart Toolbar (48px)
│   │   │       ├── Chart Canvas (flex: 1)
│   │   │       └── Chart Legend Bar (40px)
│   │   └── Data Preview Section (collapsible, max-height: 280px)
│   │       ├── Section Header
│   │       └── Data Table
```

---

## 3. 组件规格详解

### 3.1 页面头部 (Page Header)

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 56px | 56px |
| Padding | 0 0 8px 0 | 0 0 8px 0 |
| Title | "数据分析", Title Large (22pt, 500) | 同左 |
| Title Color | On Surface #212121 | On Surface #F5F5F5 |
| Subtitle | "查看试验时序数据", Body Medium (14pt, 400) | 同左 |
| Subtitle Color | On Surface Variant #757575 | On Surface Variant #9E9E9E |
| Bottom Border | 1px Outline Variant #EEEEEE | 1px Outline Variant #333333 |

---

### 3.2 控制面板 (Control Panel) — 320px 固定宽度

整体容器规格：

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Width | 320px (fixed) | 320px (fixed) |
| Height | 100% (fill parent) | 100% |
| Fills | Surface #FFFFFF | Surface Container Low #1E1E1E |
| Border Radius | 12px | 12px |
| Border | 1px Outline Variant #EEEEEE | 1px Outline Variant #333333 |
| Padding | 16px | 16px |
| Internal Gap | 16px | 16px |
| Shadow | None | None |
| Overflow | Vertical scroll (if content exceeds height) | 同左 |

#### 3.2.1 试验选择卡片 (Experiment Selection Card)

```
Component: Experiment Selection
├── Card Header
│   ├── Icon: science, 20px, Primary
│   ├── Title "选择试验" (Title Small)
│   └── Optional: Status Chip (Completed/Running/Error)
├── Divider (1px, Outline Variant)
└── Content
    ├── Dropdown: "试验名称"
    │   ├── Placeholder: "请选择试验"
    │   ├── Trailing: arrow_drop_down, 24px
    │   └── Options: 试验列表（名称 + 状态 + 时间）
    └── Metadata (when selected)
        ├── Row: "状态" + Status Chip
        ├── Row: "开始时间" + Timestamp
        └── Row: "采样数" + Number
```

| 属性 | 值 |
|------|-----|
| Card Padding | 16px |
| Card Corner Radius | 12px |
| Card Fills | Surface Container Lowest #FAFAFA (Light) / darkSurfaceContainerLowest #0A0A0A (Dark) |
| Header Bottom Margin | 12px |
| Dropdown Height | 56px |
| Metadata Row Height | 32px |
| Metadata Label | Body Small, On Surface Variant |
| Metadata Value | Body Medium, On Surface |

#### 3.2.2 设备与测点选择卡片 (Device & Point Selection Card)

```
Component: Device & Point Selection
├── Card Header
│   ├── Icon: memory, 20px, Primary
│   └── Title "选择设备与测点" (Title Small)
├── Divider
├── Device Selector
│   └── Dropdown: "设备"
│       ├── Placeholder: "请选择设备"
│       └── Options: 设备列表（名称 + 协议图标）
└── Point Selector
    ├── Section Label "测点（最多4个）" (Label Medium)
    ├── Point List (max 4 items)
    │   ├── Checkbox List Item: 测点名称
    │   │   ├── Leading: Checkbox
    │   │   ├── Title: 测点名称 (Body Medium)
    │   │   └── Trailing: Unit label (Body Small, On Surface Variant)
    │   └── ... (repeat)
    └── Selected Count "已选择 2/4" (Label Small, Primary)
```

| 属性 | 值 |
|------|-----|
| Card Padding | 16px |
| Card Corner Radius | 12px |
| Card Fills | 同试验选择卡片 |
| Point List Max Height | 200px (scrollable) |
| Checkbox Size | 18px |
| List Item Height | 40px |
| List Item Padding | 8px 12px |
| Selected Indicator | 左侧 3px Primary 色条 |
| Disabled State (max reached) | 未选项透明度 38%，Checkbox disabled |

**曲线颜色预分配**（选择测点时自动分配，在列表项右侧显示色块）：
- 曲线 1: Primary (#1976D2 / #90CAF9)
- 曲线 2: Tertiary (#00838F / #80DEEA)
- 曲线 3: Error (#C62828 / #EF5350)
- 曲线 4: Success (#2E7D32 / #66BB6A)

#### 3.2.3 时间范围卡片 (Time Range Card)

```
Component: Time Range Selection
├── Card Header
│   ├── Icon: schedule, 20px, Primary
│   └── Title "时间范围" (Title Small)
├── Divider
├── Preset Buttons Row
│   ├── Text Button: "最近1小时"
│   ├── Text Button: "最近24小时"
│   └── Text Button: "全部"
├── Divider (dashed, optional)
├── Custom Range
│   ├── Start Time Input (DateTime Picker)
│   │   ├── Label: "开始时间"
│   │   ├── Placeholder: "YYYY-MM-DD HH:mm"
│   │   └── Trailing: calendar_today icon
│   └── End Time Input (DateTime Picker)
│       ├── Label: "结束时间"
│       ├── Placeholder: "YYYY-MM-DD HH:mm"
│       └── Trailing: calendar_today icon
└── Range Info
    └── "时间跨度: 2小时 15分钟" (Body Small, On Surface Variant)
```

| 属性 | 值 |
|------|-----|
| Card Padding | 16px |
| Card Corner Radius | 12px |
| Card Fills | 同试验选择卡片 |
| Preset Buttons Gap | 8px |
| Preset Button Height | 32px |
| Preset Button Style | Text Button, compact padding (8px 12px) |
| Active Preset Button | Primary Container 背景, On Primary Container 文字 |
| Time Input Height | 56px |
| Time Input Gap | 12px |

#### 3.2.4 设置卡片 (Settings Card)

```
Component: Chart Settings
├── Card Header
│   ├── Icon: tune, 20px, Primary
│   └── Title "图表设置" (Title Small)
├── Divider
├── Downsample Setting
│   ├── Label "降采样点数" (Body Medium)
│   ├── Slider
│   │   ├── Min: 100
│   │   ├── Max: 10000
│   │   ├── Step: 100
│   │   └── Default: 1000
│   └── Value Display "1000" (Label Medium, Primary)
├── Divider
├── Toggle: "显示数据表格"
│   ├── Label "显示数据表格"
│   └── Switch (default: off)
└── Toggle: "自动刷新"
    ├── Label "自动刷新"
    └── Switch (default: off, disabled when experiment not running)
```

| 属性 | 值 |
|------|-----|
| Card Padding | 16px |
| Card Corner Radius | 12px |
| Card Fills | 同试验选择卡片 |
| Slider Track Height | 4px |
| Slider Active Color | Primary |
| Slider Inactive Color | Surface Container Highest |
| Slider Thumb Size | 20px |
| Slider Thumb Color | Primary |
| Switch Active Track | Primary |
| Switch Inactive Track | Outline |
| Setting Row Height | 48px |
| Setting Row Padding | 0 8px |

#### 3.2.5 操作按钮区 (Action Buttons)

```
Component: Action Buttons
├── Primary Button: "加载数据"
│   ├── Icon: refresh, 20px
│   ├── Text: "加载数据"
│   └── Full Width
└── Secondary Button: "重置视图"
    ├── Icon: restart_alt, 20px
    ├── Text: "重置视图"
    └── Full Width
```

| 属性 | 值 |
|------|-----|
| Button Height | 40px |
| Button Full Width | 288px (320px - 2×16px padding) |
| Button Gap | 12px |
| Primary Button | Filled Button 样式 |
| Secondary Button | Outlined Button 样式 |
| Loading State | CircularProgressIndicator (16px) + "加载中..." |

---

### 3.3 图表展示区 (Chart Area)

整体容器规格：

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Width | flex (fill remaining space) | flex |
| Height | 100% (fill parent) | 100% |
| Layout | Flex column | 同左 |
| Fills | Surface #FFFFFF | darkSurfaceContainerLowest #0A0A0A |
| Border Radius | 12px | 12px |
| Border | 1px Outline Variant #EEEEEE | 1px Outline Variant #333333 |
| Shadow | None | None |

**关键设计决策**: 深色主题下图表区域使用 `#0A0A0A`（比页面背景 `#121212` 更深），形成"画布"效果，增强数据可视化沉浸感。浅色主题下使用纯白 `#FFFFFF`，保持打印友好和明亮对比。

#### 3.3.1 图表工具栏 (Chart Toolbar)

```
Component: Chart Toolbar
├── Left Group
│   ├── IconButton: zoom_in (放大)
│   ├── IconButton: zoom_out (缩小)
│   ├── IconButton: pan_tool (平移模式切换)
│   └── IconButton: cursor (光标模式切换)
├── Center Group (optional, shows current view range)
│   └── "2024-05-01 08:00 ~ 2024-05-01 10:00" (Body Small, On Surface Variant)
└── Right Group
    ├── IconButton: fullscreen (全屏)
    ├── IconButton: save (导出图片)
    └── IconButton: settings (图表配置)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 48px | 48px |
| Padding | 0 16px | 0 16px |
| Fills | Surface Container Lowest #FAFAFA (Light) / #1A1A1A (Dark) | 同左 |
| Bottom Border | 1px Outline Variant | 同左 |
| IconButton Size | 40×40px | 40×40px |
| Icon Size | 20px | 20px |
| Icon Color | On Surface Variant | On Surface Variant |
| Active Mode Icon | Primary color background circle (Primary Container) | 同左 |
| Divider (groups) | 1px vertical, Outline Variant, height 24px | 同左 |

#### 3.3.2 图表画布 (Chart Canvas)

```
Component: Chart Canvas
├── Y-Axis (Left, 56px width)
│   ├── Axis Line (1px, Outline Variant)
│   ├── Tick Labels (Body Small, On Surface Variant)
│   └── Grid Lines extending to right
├── Chart Plot Area (flex)
│   ├── Grid Lines (horizontal + vertical)
│   ├── Curve Lines (1-4 lines)
│   ├── Data Points (optional, on hover or sparse data)
│   └── Crosshair Cursor (on hover)
│       ├── Vertical Line (1px dashed, On Surface Variant)
│       ├── Horizontal Line (1px dashed, per curve, curve color)
│       └── Tooltip
└── Y-Axis (Right, optional, 56px width, when multi-axis needed)
```

**图表画布背景颜色**:
- Light Theme: `#FFFFFF` (Surface)
- Dark Theme: `#0A0A0A` (darkSurfaceContainerLowest)

**网格线规格**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Horizontal Grid | 1px, #EEEEEE (Outline Variant) | 1px, #1E1E1E (darkSurfaceContainerLow) |
| Vertical Grid | 1px, #EEEEEE (Outline Variant) | 1px, #1E1E1E (darkSurfaceContainerLow) |
| Grid Style | Solid | Solid |
| Major Grid (every 5th) | 1px, #E0E0E0 (Outline) | 1px, #2D2D2D (darkSurfaceContainer) |

**坐标轴文字**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| X-Axis Labels | Body Small (12pt), On Surface Variant #757575 | Body Small, On Surface Variant #9E9E9E |
| Y-Axis Labels | Body Small (12pt), On Surface Variant #757575 | Body Small, On Surface Variant #9E9E9E |
| Axis Title | Label Medium (12pt, 500), On Surface Variant | Label Medium, On Surface Variant |
| Tick Length | 4px | 4px |
| Tick Color | Outline Variant | Outline Variant |

**曲线规格**:

| 曲线 | Light 颜色 | Dark 颜色 | 线宽 | 点样式 |
|------|-----------|----------|------|--------|
| 曲线 1 | #1976D2 (Primary) | #90CAF9 (Primary) | 2px | 无 / hover 显示 6px 圆点 |
| 曲线 2 | #00838F (Tertiary) | #80DEEA (Tertiary) | 2px | 无 / hover 显示 6px 圆点 |
| 曲线 3 | #C62828 (Error) | #EF5350 (Error Light) | 2px | 无 / hover 显示 6px 圆点 |
| 曲线 4 | #2E7D32 (Success) | #66BB6A (Success Light) | 2px | 无 / hover 显示 6px 圆点 |

**十字光标 (Crosshair)**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Vertical Line | 1px dashed, On Surface Variant 50% opacity | 1px dashed, On Surface Variant 50% opacity |
| Horizontal Lines | 1px dotted, respective curve color 50% opacity | 1px dotted, respective curve color 50% opacity |
| Intersection Point | 6px circle, curve color, 2px white/dark border | 6px circle, curve color, 2px dark border |

**数据提示框 (Tooltip)**:

```
Component: Chart Tooltip
├── Header
│   └── Timestamp "2024-05-01 08:30:15.234" (Label Medium, On Surface)
├── Divider
└── Data Rows (1-4 rows)
    ├── Row
    │   ├── Color Dot (8px circle, curve color)
    │   ├── Point Name "Temperature" (Body Small, On Surface)
    │   ├── Value "25.34" (Body Medium, On Surface, monospace)
    │   └── Unit "°C" (Body Small, On Surface Variant)
    └── ... (repeat for each visible curve)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Surface Container High #E0E0E0 | Surface Container High #3D3D3D |
| Border Radius | 8px | 8px |
| Border | 1px Outline | 1px Outline |
| Shadow | Elevation 2 | Elevation 2 (darker) |
| Padding | 12px 16px | 12px 16px |
| Min Width | 180px | 180px |
| Max Width | 280px | 280px |
| Position | Follow cursor, offset (16px, 16px) | 同左 |
| Arrow | 8px triangle pointing to cursor | 同左 |

#### 3.3.3 图例栏 (Chart Legend Bar)

```
Component: Chart Legend Bar
├── Legend Items (horizontal scroll or wrap)
│   ├── Legend Item 1
│   │   ├── Color Line (20px × 3px, curve color, 2px radius)
│   │   ├── Point Name "Temperature" (Body Small, On Surface)
│   │   ├── Unit "°C" (Body Small, On Surface Variant)
│   │   └── Current Value "25.34" (Label Medium, curve color, monospace)
│   ├── Legend Item 2
│   └── ... (up to 4)
└── Spacer / Optional Stats
    └── "数据点数: 1,000 | 时间跨度: 2h" (Body Small, On Surface Variant)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 40px | 40px |
| Padding | 0 16px | 0 16px |
| Fills | Surface Container Lowest #FAFAFA (Light) / #1A1A1A (Dark) | 同左 |
| Top Border | 1px Outline Variant | 1px Outline Variant |
| Legend Item Gap | 24px | 24px |
| Legend Item Height | 32px | 32px |
| Legend Item Padding | 4px 8px | 4px 8px |
| Legend Item Hover | Surface Container 背景, 4px radius | 同左 |
| Hidden Legend Item | Color Line + Text: 38% opacity, Strikethrough text | 同左 |
| Hidden Indicator | Text "(已隐藏)" (Label Small, On Surface Variant) | 同左 |

**图例交互**:
- **点击**: 切换对应曲线的显示/隐藏
- **Hover**: 图例项背景高亮，对应曲线加粗（线宽 3px）
- **双击**: 仅显示该曲线（隐藏其他）
- **Ctrl/Cmd + 点击**: 多选显示模式

---

### 3.4 数据预览区 (Data Preview Section)

该区域为可折叠面板，默认收起，通过控制面板中的"显示数据表格"开关控制。

```
Component: Data Preview Section
├── Section Header (40px)
│   ├── Icon: table_chart, 20px, Primary
│   ├── Title "数据预览" (Title Small)
│   ├── Spacer
│   └── IconButton: expand_less / expand_more (折叠切换)
└── Data Table (max-height: 240px, scrollable)
    ├── Table Header (sticky)
    │   ├── Column: "时间戳" (160px)
    │   ├── Column: "测点1" (flex, min 100px)
    │   ├── Column: "测点2" (flex, min 100px)
    │   └── ... (up to 4 columns)
    └── Table Rows
        ├── Row 1: Timestamp | Value1 | Value2 | ...
        ├── Row 2: ...
        └── ... (up to 100 rows preview)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Max Height | 280px (expanded) | 280px |
| Fills | Surface #FFFFFF | Surface Container Low #1E1E1E |
| Border Radius | 12px | 12px |
| Border | 1px Outline Variant | 1px Outline Variant |
| Header Fills | Surface Container Low #F5F5F5 | darkSurfaceContainerLow #1E1E1E |
| Header Text | Label Medium (12pt, 500), On Surface | 同左 |
| Header Height | 40px | 40px |
| Row Height | 36px | 36px |
| Row Even BG | Surface Container Lowest #FAFAFA | #1A1A1A |
| Row Odd BG | Surface #FFFFFF | Surface Container Low #1E1E1E |
| Row Hover BG | Surface Container #EEEEEE | darkSurfaceContainer #2D2D2D |
| Cell Text | Body Small (12pt), On Surface | 同左 |
| Cell Padding | 8px 12px | 8px 12px |
| Timestamp Font | Body Small, monospace | 同左 |
| Value Font | Body Small, monospace, right-aligned | 同左 |
| Scrollbar | 8px width, Primary color thumb | 同左 |

---

## 4. 状态设计

### 4.1 空状态 (Empty State)

当未选择试验或试验无数据时显示：

```
Component: Empty Chart State
├── Centered Content
│   ├── Icon: insert_chart_outlined, 64px, On Surface Variant 30% opacity
│   ├── Title "暂无数据" (Title Medium, On Surface Variant)
│   ├── Description
│   │   "请选择试验并加载数据以查看时序图表"
│   │   (Body Medium, On Surface Variant, 60% opacity)
│   └── Action: Text Button "选择试验" (optional, auto-scrolls to experiment selector)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Surface #FFFFFF | darkSurfaceContainerLowest #0A0A0A |
| Icon Color | On Surface Variant 30% | On Surface Variant 30% |
| Title Color | On Surface Variant | On Surface Variant |
| Description Color | On Surface Variant 60% | On Surface Variant 60% |

### 4.2 加载状态 (Loading State)

数据加载过程中：

```
Component: Chart Loading State
├── Centered Content
│   ├── CircularProgressIndicator (48px, Primary)
│   ├── Title "正在加载数据..." (Title Medium, On Surface Variant)
│   └── Description "正在从 HDF5 文件读取时序数据" (Body Small, On Surface Variant, 60% opacity)
├── Progress Bar (optional, for large files)
│   └── LinearProgressIndicator (4px, full width at bottom)
```

| 属性 | 值 |
|------|-----|
| Background | 同图表画布背景 |
| Spinner Size | 48px |
| Spinner Color | Primary |
| Progress Bar Height | 4px |
| Progress Bar Color | Primary |
| Progress Bar Track | Surface Container Highest |

### 4.3 错误状态 (Error State)

数据加载失败时：

```
Component: Chart Error State
├── Centered Content
│   ├── Icon: error_outline, 64px, Error color
│   ├── Title "数据加载失败" (Title Medium, Error color)
│   ├── Description "无法读取试验数据文件，请检查文件是否存在或稍后重试"
│   │   (Body Medium, On Surface Variant, max-width 400px, center-aligned)
│   └── Actions
│       ├── Outlined Button: "重试"
│       └── Text Button: "查看详情" (shows error details in Snackbar)
```

| 属性 | 值 |
|------|-----|
| Background | 同图表画布背景 |
| Icon Color | Error |
| Title Color | Error |
| Description Color | On Surface Variant |

### 4.4 无数据状态 (No Data Within Range)

选定时间范围内无数据点：

```
Component: No Data In Range State
├── Centered Content
│   ├── Icon: search_off, 48px, On Surface Variant
│   ├── Title "所选时间范围内无数据" (Title Medium, On Surface Variant)
│   ├── Description "请调整时间范围或选择其他试验"
│   │   (Body Medium, On Surface Variant, 60% opacity)
│   └── Action: Text Button "调整时间范围"
```

---

## 5. 交互设计

### 5.1 图表交互

| 交互 | 触发 | 行为 | 视觉反馈 | 动画 |
|------|------|------|---------|------|
| 滚轮缩放 | 鼠标滚轮在图表区域 | X轴时间范围缩放，以鼠标位置为中心 | 网格和曲线平滑重绘 | 100ms ease-out |
| 拖拽平移 | 按住左键左右拖动 | 平移时间轴视图 | 曲线随鼠标移动 | 实时 |
| 光标跟随 | 鼠标在图表区域移动 | 显示十字光标和数据提示框 | 提示框跟随鼠标，虚线显示 | 实时 |
| 光标离开 | 鼠标离开图表区域 | 隐藏十字光标和提示框 | 淡出 | 150ms |
| 双击复位 | 双击图表区域 | 恢复初始视图范围 | 平滑动画回到初始状态 | 300ms ease-in-out |
| 工具栏缩放 | 点击 zoom_in / zoom_out | 以视图中心为基准缩放 | 按钮按下态 + 图表缩放 | 100ms |
| 图例点击 | 点击图例项 | 切换曲线显示/隐藏 | 图例项变灰 + 曲线淡出 | 200ms |
| 图例双击 | 双击图例项 | 仅显示该曲线 | 其他曲线隐藏，选中曲线保持 | 200ms |
| 图例悬停 | 悬停图例项 | 对应曲线高亮 | 曲线线宽从 2px 变为 3px | 150ms |

### 5.2 控制面板交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 试验选择 | Dropdown 选择 | 加载试验元数据，填充设备和测点列表 | Dropdown 关闭，卡片内容更新 |
| 设备选择 | Dropdown 选择 | 加载该设备的测点列表 | 测点列表刷新 |
| 测点选择 | Checkbox 点击 | 添加/移除测点，更新已选计数 | Checkbox 状态变化，右侧色块显示 |
| 最大测点限制 | 尝试选择第5个 | 阻止选择，显示提示 | Checkbox 不可点击，显示 Snackbar "最多选择4个测点" |
| 预设时间 | 点击预设按钮 | 自动计算时间范围并填充输入框 | 按钮变为 Active 状态 |
| 自定义时间 | 输入或选择日期 | 更新自定义时间范围 | 输入框内容更新，预设按钮取消 Active |
| 加载数据 | 点击"加载数据" | 调用后端 API，获取数据 | 按钮变为 Loading 状态，图表区域显示 Loading |
| 重置视图 | 点击"重置视图" | 图表恢复初始 X/Y 范围 | 图表平滑动画复位 |
| 显示表格 | Switch 切换 | 展开/折叠数据预览区 | 区域高度动画变化 200ms |

### 5.3 数据预览区交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 表头点击 | 点击列标题 | 按该列排序（时间升序/降序） | 表头显示排序图标 |
| 行悬停 | 悬停表格行 | 高亮该行 | 行背景变化 |
| 行点击 | 点击表格行 | 在图表上高亮对应时间点 | 图表上显示垂直参考线 |
| 折叠切换 | 点击展开/折叠按钮 | 收起/展开数据表格区域 | 高度动画 |

---

## 6. 主题变体

### 6.1 浅色主题 (Light Theme)

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 页面背景 | #FAFAFA | Surface Container Lowest |
| 控制面板背景 | #FFFFFF | Surface |
| 控制卡片背景 | #FAFAFA | Surface Container Lowest |
| 图表画布背景 | #FFFFFF | Surface |
| 图表工具栏背景 | #FAFAFA | Surface Container Lowest |
| 图例栏背景 | #FAFAFA | Surface Container Lowest |
| 数据表格背景 | #FFFFFF | Surface |
| 网格线 | #EEEEEE | Outline Variant |
| 主要文字 | #212121 | On Surface |
| 次要文字 | #757575 | On Surface Variant |
| 曲线 1 | #1976D2 | Primary |
| 曲线 2 | #00838F | Tertiary |
| 曲线 3 | #C62828 | Error |
| 曲线 4 | #2E7D32 | Success |
| 光标线 | #757575 50% | On Surface Variant 半透明 |
| 提示框背景 | #E0E0E0 | Surface Container High |

### 6.2 深色主题 (Dark Theme)

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 页面背景 | #121212 | Surface |
| 控制面板背景 | #1E1E1E | Surface Container Low |
| 控制卡片背景 | #0A0A0A | darkSurfaceContainerLowest |
| 图表画布背景 | #0A0A0A | darkSurfaceContainerLowest |
| 图表工具栏背景 | #1A1A1A | 自定义深色 |
| 图例栏背景 | #1A1A1A | 自定义深色 |
| 数据表格背景 | #1E1E1E | Surface Container Low |
| 网格线 | #1E1E1E | darkSurfaceContainerLow |
| 主要文字 | #F5F5F5 | On Surface |
| 次要文字 | #9E9E9E | On Surface Variant |
| 曲线 1 | #90CAF9 | Primary (dark) |
| 曲线 2 | #80DEEA | Tertiary (dark) |
| 曲线 3 | #EF5350 | Error Light |
| 曲线 4 | #66BB6A | Success Light |
| 光标线 | #9E9E9E 50% | On Surface Variant 半透明 |
| 提示框背景 | #3D3D3D | darkSurfaceContainerHigh |

### 6.3 主题切换动画

- 全局主题切换时，图表区域背景色过渡 300ms ease-in-out
- 曲线颜色同步切换
- 网格线颜色同步切换
- 文本颜色同步切换

---

## 7. 响应式规则

### 7.1 桌面端 (>= 1280px) — 主要目标

- 侧边栏: 240px 展开
- 控制面板: 320px 固定
- 图表区域: 剩余全部空间
- 数据表格: 全宽显示

### 7.2 平板端 (>= 768px and < 1280px)

- 侧边栏: 72px 折叠（图标-only）
- 控制面板: 280px 固定（减小内边距和间距）
- 图表区域: 剩余全部空间
- 数据表格: 全宽显示

### 7.3 窗口缩小 (< 1280px) 时的布局调整

| 元素 | 调整 |
|------|------|
| 控制面板 | 保持 320px，但内部 padding 从 16px 减至 12px |
| 图例栏 | 从水平排列变为垂直折叠下拉 |
| 数据预览 | 默认收起 |
| 工具栏 | 隐藏文字标签，仅显示图标 |
| 提示框 | 最大宽度从 280px 减至 200px |

---

## 8. 动画与动效

### 8.1 图表相关动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 曲线绘制 | 800ms | ease-out | 首次加载时曲线从左到右绘制 |
| 数据刷新 | 300ms | ease-in-out | 旧数据淡出，新数据淡入 |
| 缩放/平移 | 实时 | linear | 60fps 流畅交互 |
| 视图复位 | 400ms | ease-in-out | 平滑回到初始范围 |
| 提示框出现 | 100ms | decelerate | 淡入 + 轻微上移 |
| 提示框消失 | 80ms | accelerate | 淡出 |
| 曲线隐藏/显示 | 200ms | ease-in-out | 透明度变化 + 线宽变化 |

### 8.2 控制面板动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 卡片展开 | 200ms | decelerate | 内容区域高度变化 |
| 测点列表加载 | 150ms | ease-out | 列表项淡入 |
| 按钮 Loading | instant | - | 图标替换为 spinner |
| 数据表格展开 | 200ms | ease-in-out | 高度从 0 到 max-height |

---

## 9. 设计笔记

### 9.1 关键设计决策

1. **图表深色背景**: 深色主题下图表画布使用 `#0A0A0A`（比页面 `#121212` 更深），这是为了：
   - 减少视觉疲劳，长时间数据分析更友好
   - 增强曲线对比度，亮色曲线在深色背景上更突出
   - 营造"专业分析工具"的心理暗示

2. **控制面板固定宽度 320px**: 选择此宽度是因为：
   - 足够容纳中文标签 + 输入框 + 边距
   - 在 1280px 最小宽度下，图表区域仍有 720px 空间（1280 - 240 sidebar - 320 panel - 16 gap）
   - 与 Material Design 3 的NavigationDrawer宽度（360px max）接近

3. **4条曲线上限**: 基于人眼同时追踪彩色线条的认知负荷研究，4条是舒适上限。超过时建议分屏查看。

4. **降采样滑块默认 1000**: 与后端默认 downsample 参数对齐，确保前后端默认值一致。

### 9.2 可访问性考量

- 所有4条曲线不仅靠颜色区分，hover时显示名称标签
- 图例支持键盘导航（Tab 切换，Enter/Space 切换显示）
- 图表区域支持键盘缩放（+/- 键）
- 颜色对比度满足 WCAG 2.1 AA（曲线颜色在深色/浅色背景下均通过 3:1 对比度）
- 提示框内容可被屏幕阅读器读取（aria-label 等效实现）

### 9.3 与现有设计的关系

- 控制面板卡片样式复用现有 `Standard Card` 规范（圆角 12px，边框 1px Outline Variant）
- 输入框复用现有 `Filled Text Field` 规范
- 按钮复用现有按钮规范
- 数据表格复用现有 `Compact Data Table` 规范
- AppBar、Sidebar、Breadcrumb 完全复用现有组件
- 分析页面在 Sidebar 导航中新增 "分析" 项，图标使用 `analytics`

### 9.4 图标映射

| 功能 | 图标名称 | 来源 |
|------|---------|------|
| 分析页面导航 | analytics | Material Symbols |
| 试验选择 | science | Material Symbols |
| 设备选择 | memory | Material Symbols |
| 时间范围 | schedule | Material Symbols |
| 图表设置 | tune | Material Symbols |
| 放大 | zoom_in | Material Symbols |
| 缩小 | zoom_out | Material Symbols |
| 平移模式 | pan_tool | Material Symbols |
| 光标模式 | mouse | Material Symbols |
| 全屏 | fullscreen | Material Symbols |
| 导出 | save / download | Material Symbols |
| 刷新/加载 | refresh | Material Symbols |
| 重置视图 | restart_alt | Material Symbols |
| 数据表格 | table_chart | Material Symbols |
| 无数据 | search_off | Material Symbols |
| 错误 | error_outline | Material Symbols |

---

**文档结束**
