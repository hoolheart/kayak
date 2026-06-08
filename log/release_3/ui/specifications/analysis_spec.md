# TASK-026: 数据分析与可视化 UI — 设计规格文档

> **任务**: TASK-026 — M9 数据分析与可视化  
> **设计师**: sw-anna  
> **日期**: 2026-06-08  
> **版本**: 1.0  
> **状态**: 设计完成  
> **路由**: `/analysis`  
> **依赖**: TASK-020 (试验 Provider + WebSocket), TASK-005 (主题系统), TASK-007 (可复用组件库)  
> **技术栈**: fl_chart 1.2.0

---

## 目录

1. [设计概述](#1-设计概述)
2. [页面结构](#2-页面结构)
3. [区域详细规格](#3-区域详细规格)
   - 3.1 控制面板（左侧）
   - 3.2 图表区域（右侧）
   - 3.3 数据表格（底部可选）
4. [三态设计](#4-三态设计)
5. [交互规格](#5-交互规格)
6. [响应式布局](#6-响应式布局)
7. [主题适配](#7-主题适配)
8. [无障碍设计](#8-无障碍设计)
9. [动画与动效](#9-动画与动效)
10. [组件清单](#10-组件清单)
11. [设计 QA 检查项](#11-设计-qa-检查项)

---

## 1. 设计概述

### 1.1 设计目标

数据分析页是科研团队查看和分析试验时序数据的核心工具页面，承担以下职责：
- **数据探索**: 从已完成/中止的试验中选择数据，查看时序趋势
- **多维度对比**: 在同一图表中叠加多条测点曲线，分析关联性
- **交互式分析**: 支持缩放、平移、悬停查看细节
- **数据导出**: 通过数据表格查看降采样后的具体数值

### 1.2 设计原则

1. **专业数据分析体验**: 参考 Grafana / InfluxDB 等数据可视化工具的成熟交互模式
2. **渐进式配置**: 用户按"试验 → 设备 → 测点"的层级逐步筛选，每一层只有满足条件才解锁下一步
3. **即时反馈**: 选择后立即更新下游选项，加载时显示明确进度
4. **空间效率**: 控制面板紧凑但可访问，图表区域最大化利用可用空间

### 1.3 参考文档

- PRD §M9 数据分析与可视化
- 测试用例: `log/release_3/test/TASK-026_test_cases.md`
- 可复用组件库: `log/release_3/ui/specifications/reusable_components_spec.md`

---

## 2. 页面结构

### 2.1 整体布局（Desktop >1200px）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AppShell (NavigationRail)                                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │ 控制面板          │  │ 图表区域                          │ 图例(上)    │ │
│  │ (~350px 固定宽)   │  │                                  │             │ │
│  │                   │  │   ┌──────────────────────────────┐              │ │
│  │ 试验选择 [▼]      │  │   │                              │              │ │
│  │ 设备选择 [▼]      │  │   │      时序折线图              │              │ │
│  │                   │  │   │                              │              │ │
│  │ 测点选择:         │  │   │   Y轴                          │              │ │
│  │  ○ 🔴 温度(℃)    │  │   │      〰️〰️〰️                │              │ │
│  │  ● 🟢 压力(Pa)   │  │   │   X轴 时间                   │              │ │
│  │  ● 🔵 湿度(%)    │  │   │                              │              │ │
│  │  ○ 🟡 流量(m³/h) │  │   └──────────────────────────────┘              │ │
│  │  (最多4条)        │  │                                  │             │ │
│  │                   │  └─────────────────────────────────────────────────┘ │
│  │ 时间范围:         │                                                   │
│  │ [1h] [24h] [全部] │  ┌─────────────────────────────────────────────────┐│
│  │ 自定义: [起] [止] │  │ 数据表格（可选，显示/隐藏开关控制）              ││
│  │                   │  │ 时间戳 | 温度(℃) | 压力(Pa) | ...               ││
│  │ 降采样: ──●───    │  └─────────────────────────────────────────────────┘│
│  │        100 10000  │                                                   │
│  │                   │                                                   │
│  │ [加载数据] [重置] │                                                   │
│  │ 数据表格: ○ 显示  │                                                   │
│  │            ● 隐藏 │                                                   │
│  └──────────────────┘                                                   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 区域层级

| 层级 | 区域 | 宽度 | 数据依赖 | 三态 |
|------|------|------|----------|------|
| 1 | 控制面板 | 350px (桌面), 全宽 (移动) | 试验/设备/测点 API | 独立三态 |
| 2 | 图表区域 | flex 剩余空间 | 时序数据查询 API | Loading/Data/Error/Empty |
| 3 | 数据表格 | 全宽 (条件显示) | 时序数据 (同图表) | 跟随图表数据 |

### 2.3 状态流

```
用户到达 /analysis
  → 自动加载试验列表 (筛选 completed/aborted)
  → 用户选择试验
    → 级联加载设备列表
    → 用户选择设备
      → 级联加载测点列表
      → 用户勾选测点 (最多4个)
        → 用户选择时间范围
        → 用户调整降采样
        → 点击"加载数据"
          → 调用 POST /experiments/{id}/data/query
          → 渲染图表 + 数据表格
```

---

## 3. 区域详细规格

### 3.1 控制面板（Control Panel）

#### 3.1.1 容器规格

| 属性 | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| 宽度 | 350px 固定 | 280px 固定 | 100% |
| 高度 | 100vh - AppBar | 100vh - AppBar | auto (自适应) |
| 背景 | Surface | Surface | Surface |
| 右边框 | 1px Outline Variant | 1px Outline Variant | 无 (下边框) |
| 内边距 | spaceMd (16px) | spaceMd (16px) | spaceSm (12px) |
| 滚动 | 垂直滚动 (overflow-y: auto) | 同上 | 无 |
| 层级 | 固定定位或 Flex 子项 | 同上 | 垂直堆叠 |

#### 3.1.2 试验选择（Experiment Dropdown）

**视觉规格:**

```
┌─────────────────────────────────┐
│ 试验                             │  ← Label Medium, On Surface Variant
│ ┌─────────────────────────────┐ │
│ │ 🔽 请选择试验                │ │  ← DropdownButtonFormField
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 标签 | "试验" / "Experiment" |
| 占位符 | "请选择试验" / "Select an experiment" |
| 组件 | DropdownButtonFormField2 |
| 下拉项高度 | 56px |
| 下拉项内边距 | horizontal: 16px, vertical: 12px |

**下拉项内容:**

```
┌─────────────────────────────────────────┐
│ 温度循环测试              [已完成]       │  ← 名称 + 状态标签
│ 2026-06-07 14:30 ~ 2026-06-07 16:45    │  ← 时间范围，Body Small
└─────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 名称 | Body Medium, On Surface |
| 状态标签 | Chip 样式，背景色根据状态 |
| 状态颜色 | COMPLETED: Success / ABORTED: Warning |
| 时间 | Body Small, On Surface Variant |
| 状态标签尺寸 | 高度 20px, padding: 0 8px, 字号 11px |

**过滤规则:**
- 仅显示 status = `COMPLETED` 或 `ABORTED` 的试验
- RUNNING / IDLE / LOADED / PAUSED 状态的试验不显示
- 按创建时间倒序排列

**状态:**

| 状态 | 表现 |
|------|------|
| 加载中 | 显示 Skeleton: 48×16px (标签) + 全宽×56px (输入框占位) |
| 加载完成 | 下拉框可用，显示试验列表 |
| 加载失败 | 显示 ErrorView compact + 重试按钮 |
| 空数据 | 下拉框禁用，显示 "暂无已完成或中止的试验" |

#### 3.1.3 设备选择（Device Dropdown）

**视觉规格:**

```
┌─────────────────────────────────┐
│ 设备                             │
│ ┌─────────────────────────────┐ │
│ │ 🔽 请选择设备                │ │  ← 未选试验时禁用
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 标签 | "设备" / "Device" |
| 占位符 (未选试验) | "请先选择试验" / "Select experiment first" |
| 占位符 (已选试验) | "请选择设备" / "Select a device" |
| 禁用状态 | 38% opacity, 不可点击 |

**状态:**

| 状态 | 表现 |
|------|------|
| 未选试验 | 禁用，placeholder "请先选择试验" |
| 加载中 | 显示 Skeleton + loading indicator |
| 加载完成 | 下拉框可用，显示设备列表 |
| 空数据 | 显示 "该工作台下暂无设备" |
| 错误 | ErrorView compact + 重试 |

**级联行为:**
- 切换试验 → 设备下拉框重置（清空选中）
- 切换试验 → 测点列表清空
- 切换试验 → 图表数据清空

#### 3.1.4 测点选择（Point Checkboxes）

**视觉规格:**

```
┌─────────────────────────────────┐
│ 测点 (最多选择 4 条)             │  ← Label Medium
│                                 │
│  ○  🔴 温度 (℃)                 │  ← Checkbox + ColorDot + Name + Unit
│  ●  🟢 压力 (Pa)                │
│  ●  🔵 湿度 (%)                 │
│  ○  🟡 流量 (m³/h)              │
│  ○  🟣 转速 (rpm)               │  ← 超过4条选中后禁用
│                                 │
│  已选择: 2/4                     │  ← 计数提示
└─────────────────────────────────┘
```

**颜色指示圆点:**

| 属性 | 值 |
|------|-----|
| 尺寸 | 10×10px, 圆形 |
| 边框 | 1px solid, 颜色同背景 but 20% darker |
| 颜色分配 | 固定配色方案，按顺序分配 |

**配色方案（Light/Dark）:**

| # | Light | Dark | 使用场景 |
|---|-------|------|----------|
| 1 | #E53935 (红) | #EF5350 | 温度相关 |
| 2 | #43A047 (绿) | #66BB6A | 压力相关 |
| 3 | #1E88E5 (蓝) | #42A5F5 | 湿度/流量 |
| 4 | #FB8C00 (橙) | #FFA726 | 其他 |
| 5 | #8E24AA (紫) | #AB47BC | 备用 |
| 6 | #00ACC1 (青) | #26C6DA | 备用 |

**复选框规格:**

| 属性 | 值 |
|------|-----|
| 组件 | Checkbox (Material) |
| 密度 | CheckboxThemeData.visualDensity: compact |
| 标签 | Body Medium, On Surface |
| 单位 | Body Small, On Surface Variant, 括号包裹 |
| 行高 | 40px |
| 行内边距 | horizontal: 0, vertical: 4px |

**数量限制:**
- 最多同时选中 4 个测点
- 选中 4 个后，其余复选框禁用 (灰色，不可点击)
- 禁用项 hover 显示 tooltip: "最多同时选择 4 条曲线"
- 取消选中后，禁用项恢复可用

**状态:**

| 状态 | 表现 |
|------|------|
| 未选设备 | 显示 placeholder "请先选择设备" / 或空区域 |
| 加载中 | Skeleton: 4 行占位 |
| 加载完成 | 显示测点复选框列表 |
| 空数据 | "该设备下暂无测点" |
| 错误 | ErrorView compact + 重试 |

#### 3.1.5 时间范围选择（Time Range）

**视觉规格:**

```
┌─────────────────────────────────┐
│ 时间范围                         │
│ ┌────┐ ┌─────┐ ┌────┐           │
│ │1小时│ │24小时│ │全部│           │  ← ToggleButtons / SegmentedButton
│ └────┘ └─────┘ └────┘           │
│                                 │
│ 自定义:                          │
│ ┌──────────────┐ ┌──────────────┐│
│ │ 📅 开始时间   │ │ 📅 结束时间   ││  ← DateTimePicker (显示时隐藏预设)
│ └──────────────┘ └──────────────┘│
└─────────────────────────────────┘
```

**预设按钮规格:**

| 属性 | 值 |
|------|-----|
| 组件 | SegmentedButton (Material 3) |
| 高度 | 36px |
| 选项 | "1小时" / "24小时" / "全部" |
| 英文 | "1h" / "24h" / "All" |
| 选中 | Filled style, Primary color |
| 未选 | Outlined style |

**自定义时间选择器:**

| 属性 | 值 |
|------|-----|
| 组件 | DateTimePicker / 自定义输入 |
| 触发 | 点击输入框弹出 DatePicker + TimePicker |
| 格式 | `yyyy-MM-dd HH:mm` |
| 默认值 | 开始: 试验开始时间 / 结束: 现在 |
| 验证 | 开始时间必须早于结束时间 |

**交互逻辑:**
- 选择预设 → 自定义选择器隐藏/禁用
- 点击自定义输入框 → 预设按钮取消选中
- 时间范围变化 → "加载数据"按钮状态更新

**验证错误:**

| 错误 | 提示消息 | 处理 |
|------|----------|------|
| 开始 > 结束 | "开始时间必须早于结束时间" | 禁用加载按钮，红色提示文字 |
| 范围 > 30天 | "查询时间范围不能超过30天" | 同上 |
| 未来时间 | "开始/结束时间不能是未来时间" | 同上 |

#### 3.1.6 降采样滑块（Downsample Slider）

**视觉规格:**

```
┌─────────────────────────────────┐
│ 降采样                           │
│ 当前: 1,000 点                   │  ← Label Medium + 数值显示
│                                 │
│ ──────●───────────────          │  ← Slider
│ 100              10,000          │  ← 范围标记
└─────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 组件 | Slider (Material) |
| 范围 | 100 ~ 10,000 |
| 默认值 | 1,000 |
| 步长 | 对数刻度 (视觉均匀分布) |
| 标签 | "降采样" / "Downsample" |
| 数值显示 | "{value} 点" / "{value} points" |
| 数值位置 | 滑块下方或右侧 |

**对数刻度实现:**
- 滑块使用线性 0-1 映射到对数值
- 实际值 = 100 × 10^(slider_value × 2)
- 显示值取整到最接近的 100

#### 3.1.7 操作按钮（Action Buttons）

**视觉规格:**

```
┌─────────────────────────────────┐
│                                 │
│ ┌─────────────────────────────┐ │
│ │      🔄 加载数据            │ │  ← FilledButton (Primary)
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      重置视图               │ │  ← OutlinedButton
│ └─────────────────────────────┘ │
│                                 │
│ 数据表格                        │
│ ○ 显示  ● 隐藏                 │  ← Switch / Radio
│                                 │
└─────────────────────────────────┘
```

**"加载数据"按钮:**

| 属性 | 值 |
|------|-----|
| 样式 | FilledButton, Primary |
| 高度 | 48px |
| 全宽 | 100% |
| 图标 | `Icons.refresh` / `Icons.sync` |
| 启用条件 | 试验 && 设备 && 至少1个测点 已选 |
| 加载状态 | 显示 CircularProgressIndicator (20px) + "加载中..." |
| 加载禁用 | 防止重复点击 |

**"重置视图"按钮:**

| 属性 | 值 |
|------|-----|
| 样式 | OutlinedButton |
| 高度 | 40px |
| 全宽 | 100% |
| 启用条件 | 图表已加载数据 |
| 功能 | 恢复图表默认缩放级别和位置 |

**数据表格开关:**

| 属性 | 值 |
|------|-----|
| 组件 | Switch (Material) |
| 标签 | "数据表格" / "Data Table" |
| 默认 | false (隐藏) |
| 启用条件 | 图表已加载数据 |

#### 3.1.8 控制面板分隔线

各控制组之间使用 Divider (1px, Outline Variant at 50%) 分隔：
- 试验选择 → 设备选择
- 设备选择 → 测点选择
- 测点选择 → 时间范围
- 时间范围 → 降采样
- 降采样 → 操作按钮

---

### 3.2 图表区域（Chart Area）

#### 3.2.1 容器规格

| 属性 | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| 宽度 | flex: 1 (剩余全部宽度) | flex: 1 | 100% |
| 高度 | 100% - 数据表格高度 | 同上 | 400px (最小) |
| 背景 | Surface / Surface Container Low | 同上 | 同上 |
| 内边距 | spaceMd (16px) | spaceSm (12px) | spaceSm (12px) |
| 边框 | 无 | 无 | 无 |

#### 3.2.2 图表图例（Legend）

**视觉规格:**

```
┌─────────────────────────────────────────────────────────────────┐
│  🔴 温度(℃)   🟢 压力(Pa)   🔵 湿度(%)   🟡 流量(m³/h)         │
└─────────────────────────────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 位置 | 图表上方或右侧 (自适应) |
| 布局 | Wrap / Row |
| 每项 | ColorBox (12×12px) + 测点名称 + 单位 |
| 间距 | spaceMd (16px) 水平 |
| 字号 | Body Small |
| 颜色 | On Surface |

**交互:**
- 点击图例项 → 隐藏/显示对应曲线
- 隐藏状态: 图例项变灰 (38% opacity), 文字加删除线
- 再次点击 → 恢复显示

#### 3.2.3 时序折线图（fl_chart 1.2.0）

**LineChartData 配置:**

| 属性 | 值 |
|------|-----|
| 组件 | LineChart (fl_chart) |
| 动画 | 加载时 300ms 淡入 |
| 网格线 | FlGridData: 水平可见, 垂直可见, 颜色 Outline Variant |
| 边框 | FlBorderData: 四边显示, 颜色 Outline |
| 背景 | 透明 (跟随容器 Surface) |
| 最小内边距 | 左侧 60px (Y轴), 底部 40px (X轴), 上/右 16px |

**X 轴（时间轴）:**

| 属性 | 值 |
|------|-----|
| 组件 | FlTitlesData (bottom) |
| 格式 | 同日: `HH:mm:ss` / 跨日: `MM-dd HH:mm` |
| 旋转 | 0° (水平) |
| 间隔 | fl_chart 自动计算 |
| 标签 | Body Small, On Surface Variant |
| 避免重叠 | fl_chart 自动隐藏重叠标签 |

**Y 轴（数值轴）:**

| 属性 | 值 |
|------|-----|
| 组件 | FlTitlesData (left) |
| 格式 | 自动范围 (min - padding ~ max + padding) |
| 标签 | Body Small, On Surface Variant |
| 单位标注 | 第一个选中测点的单位，显示在轴标题 |
| 多测点 | 共用同一个 Y 轴 (或每个测点独立 Y 轴，视实现) |

**曲线样式:**

| 属性 | 值 |
|------|-----|
| 线宽 | 2px |
| 数据点 | 小圆点 (半径 3px), 超过 500 点时隐藏点 |
| 颜色 | 使用测点分配的颜色 |
| 曲线类型 | LineChartBarData.isCurved = false (折线) |
| 填充 | 无填充 (仅线条) |

**触摸交互:**

| 属性 | 值 |
|------|-----|
| 组件 | LineTouchData |
| 悬停线 | 垂直虚线，颜色 Primary at 30% |
| 提示框 | 自定义 tooltip |
| 触摸模式 | TouchMode.all (多点) |

**Tooltip 规格:**

```
┌───────────────────────────────────┐
│  14:30:05                         │  ← 时间, Title Medium
│  ─────────────────────────────    │
│  🔴 温度: 23.50 ℃                 │  ← 每项: 颜色点 + 名称 + 值 + 单位
│  🟢 压力: 1013.25 Pa              │
│  🔵 湿度: 45.20 %                 │
└───────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 背景 | Surface, elevation 2, 圆角 8px |
| 内边距 | 12px 16px |
| 时间 | Title Medium, On Surface |
| 数据项 | Body Small, On Surface |
| 值 | 加粗, 使用对应曲线颜色 |
| 最大宽度 | 280px |
| 位置 | 跟随鼠标，智能避让边界 |

**缩放和平移:**

| 交互 | 行为 |
|------|------|
| 滚轮向上 | X轴放大 (显示更短时间范围) |
| 滚轮向下 | X轴缩小 (显示更长时间范围) |
| 拖拽 | 平移图表 (左右移动时间范围) |
| 缩放中心 | 鼠标位置 |
| 平移限制 | 不能超出数据范围 |

#### 3.2.4 图表状态

| 状态 | 表现 |
|------|------|
| **初始空状态** | 显示 EmptyView: 图标 `Icons.show_chart`, 标题 "请选择试验、设备和测点后加载数据" |
| **加载中** | 显示 Skeleton (图表区域占位) + CircularProgressIndicator 居中，文字 "正在加载数据..." |
| **数据就绪** | 渲染 LineChart，300ms 淡入 |
| **无数据** | EmptyView: 图标 `Icons.inbox`, 标题 "所选范围内无数据" |
| **错误** | ErrorView: 图标 `Icons.error_outline`, 标题 "加载数据失败", 描述 + 重试按钮 |

---

### 3.3 数据表格（Data Table）

#### 3.3.1 容器规格

| 属性 | 值 |
|------|-----|
| 高度 | 250px (固定), 可配置 |
| 背景 | Surface |
| 边框 | 顶部 1px Outline Variant |
| 显示控制 | Switch 切换 |
| 动画 | 展开/收起 200ms, ease-in-out |

#### 3.3.2 表格规格

```
┌──────────────┬─────────────┬─────────────┬─────────────┐
│ 时间戳        │ 温度(℃)     │ 压力(Pa)    │ 湿度(%)     │  ← 表头: 固定, Surface Variant 背景
├──────────────┼─────────────┼─────────────┼─────────────┤
│ 14:30:01     │ 23.50       │ 1013.25     │ 45.20       │
│ 14:30:02     │ 23.51       │ 1013.27     │ 45.18       │
│ ...          │             │             │             │
└──────────────┴─────────────┴─────────────┴─────────────┘
```

| 属性 | 值 |
|------|-----|
| 组件 | DataTable / Table |
| 表头背景 | Surface Variant |
| 表头文字 | Label Medium, On Surface, 加粗 |
| 行高 | 48px |
| 行交替色 | 无 (或 Surface / Surface Container Low 交替) |
| 时间列 | `HH:mm:ss` 格式 |
| 数值列 | 固定 2 位小数 |
| 单位 | 在列标题中显示 |
| 对齐 | 时间左对齐, 数值右对齐 |
| 滚动 | 垂直滚动 (表头 sticky) |

#### 3.3.3 空数据表格

- 未加载数据时，表格区域不显示
- 加载后无数据: 显示 "无数据" 居中提示

---

## 4. 三态设计

### 4.1 控制面板三态

**试验列表:**

| 状态 | UI |
|------|-----|
| Loading | Skeleton (2 行: 标签 + 下拉框占位) |
| Data | Dropdown 可用，显示试验选项 |
| Empty | Dropdown 禁用，显示 "暂无已完成或中止的试验" |
| Error | ErrorView compact + 重试 |

**设备列表:**

| 状态 | UI |
|------|-----|
| Loading (级联) | 下拉框显示 loading spinner |
| Data | Dropdown 可用 |
| Empty | "该工作台下暂无设备" |
| Error | ErrorView compact |

**测点列表:**

| 状态 | UI |
|------|-----|
| Loading | Skeleton (4 行复选框占位) |
| Data | 复选框列表 |
| Empty | "该设备下暂无测点" |
| Error | ErrorView compact |

### 4.2 图表区域三态

| 状态 | UI | 截图 |
|------|-----|------|
| **初始 (Idle)** | EmptyView + 引导提示 | TC-G04 |
| **加载中** | Skeleton + CircularProgressIndicator + "正在加载数据..." | TC-G05 |
| **有数据** | LineChart 渲染，图例显示 | TC-G01 / TC-G02 |
| **无数据** | EmptyView "所选范围内无数据" | — |
| **错误** | ErrorView + 重试按钮 | TC-G06 |

---

## 5. 交互规格

### 5.1 级联更新流

```
用户选择试验
  → 触发设备列表加载 (AsyncValue.loading)
  → 清空已选设备、测点、图表数据
  → 设备列表就绪 → Dropdown 可用

用户选择设备
  → 触发测点列表加载
  → 清空已选测点、图表数据
  → 测点列表就绪 → 复选框可用

用户勾选/取消测点
  → 更新已选测点列表
  → 检查"加载数据"按钮启用状态
  → 如果已加载图表 → 保持现状 (不自动刷新)
```

### 5.2 按钮启用条件

| 按钮 | 启用条件 |
|------|----------|
| "加载数据" | 试验 != null && 设备 != null && 测点.length >= 1 |
| "重置视图" | 图表已加载数据 |
| "数据表格" Switch | 图表已加载数据 |

### 5.3 图表交互

| 交互 | 触发 | 效果 |
|------|------|------|
| 悬停 | 鼠标进入图表数据区 | 显示垂直虚线 + Tooltip |
| 滚轮放大 | 滚轮向上 | X轴范围缩小 (以鼠标为中心) |
| 滚轮缩小 | 滚轮向下 | X轴范围扩大 |
| 拖拽平移 | 按住左键拖动 | 移动 X轴范围 |
| 图例点击 | 点击图例项 | 隐藏/显示对应曲线 |
| 双击 | 双击图表 | 重置到默认视图 |

### 5.4 错误处理

| 后端错误 | 前端提示 | 处理方式 |
|----------|----------|----------|
| 400 参数无效 | "请求参数无效" | Toast Error |
| 400 时间顺序 | "开始时间必须早于结束时间" | 内联提示 + 禁用按钮 |
| 400 超30天 | "查询时间范围不能超过30天" | 同上 |
| 400 未来时间 | "开始/结束时间不能是未来时间" | 同上 |
| 404 试验不存在 | "试验不存在" | ErrorView |
| 404 设备不存在 | "设备不存在" | ErrorView |
| 409 未完成 | "该试验尚未完成，无法查询数据" | Toast Warning |
| 500 服务器错误 | "服务器错误，请稍后重试" | ErrorView + 重试 |

---

## 6. 响应式布局

### 6.1 断点定义

| 断点 | 名称 | 宽度范围 |
|------|------|----------|
| Mobile | 小屏 | < 600px |
| Tablet | 中屏 | 600px - 1200px |
| Desktop | 大屏 | > 1200px |

### 6.2 各断点布局

#### Desktop (> 1200px)

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│  ┌──────────────┐  ┌────────────────────────────────────────┐ │
│  │              │  │                                        │ │
│  │  控制面板     │  │  图表区域                              │ │
│  │  350px 固定   │  │  flex: 1                               │ │
│  │              │  │                                        │ │
│  │  (可垂直滚动) │  │                                        │ │
│  │              │  └────────────────────────────────────────┘ │
│  │              │  ┌────────────────────────────────────────┐ │
│  │              │  │ 数据表格 (可选, 高度 250px)            │ │
│  └──────────────┘  └────────────────────────────────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- 左右分栏
- 控制面板固定宽度 350px
- 图表区域自适应剩余宽度
- 数据表格全宽在图表下方

#### Tablet (600-1200px)

```
┌──────────────────────────────────────────────────┐
│                                                  │
│  ┌──────────┐  ┌──────────────────────────────┐ │
│  │控制面板   │  │ 图表区域                      │ │
│  │280px     │  │                              │ │
│  │固定      │  │                              │ │
│  └──────────┘  └──────────────────────────────┘ │
│  ┌─────────────────────────────────────────────┐│
│  │ 数据表格 (可选)                              ││
│  └─────────────────────────────────────────────┘│
│                                                  │
└──────────────────────────────────────────────────┘
```

- 左右分栏，控制面板 280px
- 图表区域自适应
- 测点复选框可能换行显示

#### Mobile (< 600px)

```
┌──────────────────────────────────────┐
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 控制面板 (全宽, 可折叠)         │ │
│  │ [试验 ▼] [设备 ▼]              │ │
│  │ 测点: ○○○○ (Wrap 布局)         │ │
│  │ [1h][24h][全部]                │ │
│  │ [加载数据]                     │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 图表区域                        │ │
│  │ (高度 400px 固定)              │ │
│  │                                │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 数据表格 (可选, 可横向滚动)     │ │
│  └────────────────────────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

- 上下堆叠布局
- 控制面板全宽，可能可折叠
- 图表区域最小高度 400px
- 测点复选框使用 Wrap 布局 (水平换行)
- 数据表格可横向滚动

### 6.3 响应式组件调整

| 组件 | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| 控制面板 | 固定左侧, 350px | 固定左侧, 280px | 顶部全宽 |
| 图表高度 | 自适应 | 自适应 | 400px 最小 |
| 测点复选框 | 垂直列表 | 垂直列表 | Wrap (2列) |
| 时间预设按钮 | SegmentedButton (3项) | 同上 | 可能换行或改为下拉 |
| 操作按钮 | 垂直堆叠 | 垂直堆叠 | 水平并排 |
| 图例位置 | 图表上方 | 图表上方 | 图表上方, 可折叠 |
| 数据表格 | 全宽, 250px 高 | 全宽, 200px 高 | 全宽, 200px 高, 横向滚动 |

---

## 7. 主题适配

### 7.1 Light Theme

| 元素 | 颜色 |
|------|------|
| 页面背景 | Background (#FDFCFF) |
| 控制面板背景 | Surface (#FFFFFF) |
| 图表背景 | Surface / Surface Container Low |
| 图表网格线 | Outline Variant (#C4C6D0) |
| 坐标轴标签 | On Surface Variant (#44474E) |
| 曲线颜色 | 见 3.1.4 配色方案 (Light) |
| 提示框背景 | Surface (#FFFFFF), elevation 2 |
| 提示框文字 | On Surface (#1A1C1E) |
| 数据表格表头 | Surface Variant (#EFF3FA) |
| 数据表格行 | Surface (#FFFFFF) |
| 加载中骨架 | Surface Variant at 50% |

### 7.2 Dark Theme

| 元素 | 颜色 |
|------|------|
| 页面背景 | Background (#1A1C1E) |
| 控制面板背景 | Surface (#1A1C1E) |
| 图表背景 | Surface / Surface Container Low (#1D2023) |
| 图表网格线 | Outline Variant (#44474E) |
| 坐标轴标签 | On Surface Variant (#C4C6CF) |
| 曲线颜色 | 见 3.1.4 配色方案 (Dark) — 提亮 |
| 提示框背景 | Surface (#1A1C1E), elevation 2 |
| 提示框文字 | On Surface (#E3E2E6) |
| 数据表格表头 | Surface Variant (#43474E) |
| 数据表格行 | Surface (#1A1C1E) |
| 加载中骨架 | Surface Variant at 50% |

### 7.3 主题切换行为

- **即时更新**: 主题切换后图表颜色立即更新 (不需要重新加载数据)
- **颜色动态获取**: 使用 `Theme.of(context).colorScheme` 获取当前主题颜色
- **曲线颜色稳定**: 测点颜色分配不受主题切换影响 (但会根据主题选择 Light/Dark 变体)
- **网格/标签跟随**: 坐标轴、网格线、标签颜色自动跟随主题

---

## 8. 无障碍设计

### 8.1 屏幕阅读器

| 元素 | 语义标签 |
|------|----------|
| 控制面板 | "数据分析控制面板" |
| 试验下拉框 | "试验选择，{当前选中或未选}" |
| 设备下拉框 | "设备选择，{当前选中或未选}" |
| 测点复选框 | "测点 {名称}，单位 {unit}，颜色 {颜色描述}，{选中/未选中}" |
| 时间预设按钮 | "时间范围，{当前选中选项}" |
| 降采样滑块 | "降采样，当前 {值} 点，范围 100 到 10000" |
| 加载数据按钮 | "加载数据按钮，{启用/禁用}" |
| 图表区域 | "时序数据图表，{N} 条曲线" |
| 图例项 | "{测点名称} 曲线，点击隐藏或显示" |
| 数据表格 | "数据表格，{N} 行数据" |

### 8.2 键盘导航

| 元素 | 键盘支持 |
|------|----------|
| 下拉框 | Tab 聚焦, Space/Enter 展开, 方向键选择 |
| 复选框 | Tab 聚焦, Space 切换 |
| 滑块 | Tab 聚焦, 方向键调整 |
| 按钮 | Tab 聚焦, Enter/Space 激活 |
| 图表 | 无法键盘操作 (需鼠标/触摸) |

### 8.3 触摸目标

- 下拉框: 最小 48×48dp
- 复选框: 最小 48×48dp (含标签区域)
- 按钮: 最小 120×48dp
- 滑块 thumb: 最小 24×24dp, 触摸区域 48×48dp

### 8.4 对比度

- 图表曲线 vs 背景: ≥ 3:1 (大元素)
- 坐标轴标签 vs 背景: ≥ 4.5:1
- 控制面板文字 vs 背景: ≥ 4.5:1
- 禁用状态: ≥ 3:1

### 8.5 动效减弱

- `prefers-reduced-motion`:
  - 图表加载动画: 禁用，直接显示
  - 数据表格展开/收起: 禁用，直接切换
  - Tooltip: 禁用淡入淡出
  - 骨架屏: 禁用 shimmer

---

## 9. 动画与动效

### 9.1 页面加载

```
Sequence:
  1. 控制面板骨架屏 (0ms, 立即)
  2. 试验列表加载完成后:
     - 骨架屏淡出 (150ms)
     - Dropdown 淡入 (150ms)
  3. 图表区域显示 EmptyView (无动画)
```

### 9.2 级联加载动画

| 触发 | 动画 | 时长 | 缓动 |
|------|------|------|------|
| 选择试验 | 设备下拉框显示 loading spinner | 即时 | — |
| 设备列表就绪 | 下拉框内容淡入 | 150ms | ease-in |
| 选择设备 | 测点区域显示骨架 | 即时 | — |
| 测点列表就绪 | 复选框列表淡入 | 150ms | ease-in |

### 9.3 图表加载

| 触发 | 动画 | 时长 | 缓动 |
|------|------|------|------|
| 点击"加载数据" | 按钮进入 loading 状态 | 即时 | — |
| 数据返回 | Skeleton 淡出 (150ms) → LineChart 淡入 (300ms) | 300ms | ease-out |
| 图表首次渲染 | 线条从左到右绘制 (可选) | 500ms | ease-out |

### 9.4 微交互

| 交互 | 动画 | 时长 | 缓动 |
|------|------|------|------|
| 复选框选中 | Checkbox 勾选动画 | 150ms | ease-in-out |
| 图例点击 | 透明度变化 + 删除线 | 150ms | ease-out |
| Tooltip 显示 | 淡入 + 轻微上移 | 100ms | ease-out |
| Tooltip 隐藏 | 淡出 | 50ms | ease-in |
| 按钮 Hover | Elevation 提升 | 150ms | ease-out |
| 按钮 Pressed | Scale 0.98 | 100ms | ease-in-out |
| 数据表格展开 | 高度动画 | 200ms | ease-in-out |

---

## 10. 组件清单

### 10.1 新增组件

| 组件名 | 用途 | 文件建议 |
|--------|------|----------|
| `AnalysisPage` | 数据分析主页 | `lib/pages/analysis/analysis_page.dart` |
| `ControlPanel` | 左侧控制面板 | `lib/pages/analysis/widgets/control_panel.dart` |
| `ExperimentDropdown` | 试验选择下拉框 | `lib/pages/analysis/widgets/experiment_dropdown.dart` |
| `DeviceDropdown` | 设备选择下拉框 | `lib/pages/analysis/widgets/device_dropdown.dart` |
| `PointCheckboxList` | 测点复选框列表 | `lib/pages/analysis/widgets/point_checkbox_list.dart` |
| `TimeRangeSelector` | 时间范围选择器 | `lib/pages/analysis/widgets/time_range_selector.dart` |
| `DownsampleSlider` | 降采样滑块 | `lib/pages/analysis/widgets/downsample_slider.dart` |
| `ChartArea` | 图表区域容器 | `lib/pages/analysis/widgets/chart_area.dart` |
| `TimeSeriesChart` | 时序折线图 (fl_chart) | `lib/widgets/time_series_chart.dart` |
| `ChartLegend` | 图表图例 | `lib/pages/analysis/widgets/chart_legend.dart` |
| `ChartTooltip` | 悬停提示框 | `lib/pages/analysis/widgets/chart_tooltip.dart` |
| `DataTablePanel` | 数据表格面板 | `lib/pages/analysis/widgets/data_table_panel.dart` |
| `AnalysisSkeleton` | 分析页骨架屏 | `lib/pages/analysis/widgets/analysis_skeleton.dart` |

### 10.2 复用组件

| 组件 | 来源 | 用途 |
|------|------|------|
| `ErrorView` | `widgets/error_view.dart` | 错误展示 |
| `EmptyView` | `widgets/empty_view.dart` | 空状态引导 |
| `Skeleton` | `widgets/skeleton.dart` | 加载占位 |
| `AsyncValueWidget` | `widgets/async_value_widget.dart` | 三态分发 |
| `Toast` | `widgets/toast.dart` | 操作反馈 |

### 10.3 数据模型

```dart
// 分析页面状态
class AnalysisState {
  final AsyncValue<List<ExperimentSummary>> experiments;
  final String? selectedExperimentId;
  final AsyncValue<List<DeviceSummary>> devices;
  final String? selectedDeviceId;
  final AsyncValue<List<PointSummary>> points;
  final List<String> selectedPointIds;
  final TimeRange timeRange;
  final int downsample;
  final AsyncValue<ChartData> chartData;
  final bool showDataTable;
  final bool isLoadingData;
  
  const AnalysisState({
    required this.experiments,
    this.selectedExperimentId,
    required this.devices,
    this.selectedDeviceId,
    required this.points,
    this.selectedPointIds = const [],
    required this.timeRange,
    this.downsample = 1000,
    required this.chartData,
    this.showDataTable = false,
    this.isLoadingData = false,
  });
}

class TimeRange {
  final TimeRangePreset? preset;
  final DateTime? customStart;
  final DateTime? customEnd;
  
  const TimeRange.preset(this.preset)
    : customStart = null,
      customEnd = null;
      
  const TimeRange.custom(this.customStart, this.customEnd)
    : preset = null;
}

enum TimeRangePreset { oneHour, twentyFourHours, all }

class ChartData {
  final String experimentId;
  final String deviceId;
  final List<PointData> points;
  final int totalSamples;
  final int returnedSamples;
}

class PointData {
  final String pointId;
  final String pointName;
  final String unit;
  final String dataType;
  final List<DateTime> timestamps;
  final List<double?> values;
  final Color color;
}
```

---

## 11. 设计 QA 检查项

### 11.1 视觉检查

- [ ] 所有颜色与 Design Token 完全一致
- [ ] Light/Dark 主题切换颜色正确
- [ ] 图表曲线颜色鲜明，与背景对比度足够
- [ ] 网格线颜色不抢眼但可见
- [ ] 控制面板分隔线一致
- [ ] 各区域间距符合 8px 网格系统
- [ ] 圆角一致 (radiusMedium 8px)

### 11.2 交互检查

- [ ] 级联更新: 选择试验 → 设备列表更新 → 测点列表更新
- [ ] 测点最多选择 4 个限制生效
- [ ] 超过4个后禁用未选项，取消后恢复
- [ ] "加载数据"按钮仅在条件满足时启用
- [ ] 按钮 loading 状态正确
- [ ] 图表缩放/平移流畅
- [ ] 悬停提示框显示正确
- [ ] 图例点击隐藏/显示曲线
- [ ] 数据表格展开/收起正常

### 11.3 三态检查

- [ ] 试验列表: Loading → Data → Empty → Error
- [ ] 设备列表: Loading → Data → Empty → Error
- [ ] 测点列表: Loading → Data → Empty → Error
- [ ] 图表: Empty → Loading → Data → Error
- [ ] 错误状态有重试按钮
- [ ] 加载状态有明确指示

### 11.4 响应式检查

- [ ] Desktop (>1200px): 左右分栏, 控制面板 350px
- [ ] Tablet (600-1200px): 左右分栏, 控制面板 280px
- [ ] Mobile (<600px): 上下堆叠, 全宽
- [ ] 图表自适应容器大小
- [ ] 数据表格小屏可横向滚动
- [ ] 触摸目标 ≥ 48×48dp

### 11.5 主题检查

- [ ] Light 主题图表颜色正确
- [ ] Dark 主题图表颜色正确 (曲线提亮)
- [ ] 主题切换后图表即时更新
- [ ] 坐标轴标签跟随主题
- [ ] 网格线跟随主题

### 11.6 无障碍检查

- [ ] 屏幕阅读器正确朗读各控件
- [ ] Tab 键可导航所有交互元素
- [ ] Enter/Space 可激活按钮和复选框
- [ ] 颜色对比度符合 WCAG AA
- [ ] prefers-reduced-motion 下禁用动画

### 11.7 性能检查

- [ ] 10,000 数据点渲染时间 < 2 秒
- [ ] 缩放/平移操作流畅
- [ ] 页面不冻结
- [ ] 骨架屏 shimmer 不卡顿

---

## 附录

### A. 图标清单

| 图标 | 用途 | 尺寸 | 颜色 |
|------|------|------|------|
| `show_chart` | 图表空状态 | 48px | On Surface Variant |
| `inbox` | 无数据状态 | 48px | On Surface Variant |
| `error_outline` | 错误状态 | 48px | On Surface Variant |
| `refresh` / `sync` | 加载数据按钮 | 20px | On Primary |
| `calendar_today` | 时间选择器 | 16px | On Surface Variant |
| `table_chart` | 数据表格开关 | 20px | On Surface Variant |
| `zoom_out_map` | 重置视图按钮 | 20px | Primary |
| `timeline` | 测点列表空状态 | 40px | On Surface Variant |

### B. 动画参数汇总

| 动画 | 时长 | 缓动 | 组件 |
|------|------|------|------|
| 骨架屏 shimmer | 1.5s 循环 | linear | Skeleton |
| 内容淡入 | 150ms | ease-in | Dropdown/Checkbox |
| 图表淡入 | 300ms | ease-out | LineChart |
| Tooltip 显示 | 100ms | ease-out | Tooltip |
| Tooltip 隐藏 | 50ms | ease-in | Tooltip |
| 按钮 Hover | 150ms | ease-out | Button |
| 按钮 Pressed | 100ms | ease-in-out | Button |
| 表格展开/收起 | 200ms | ease-in-out | DataTablePanel |
| 复选框勾选 | 150ms | ease-in-out | Checkbox |

### C. 后端 API 依赖

| 数据 | API | 字段 |
|------|-----|------|
| 试验列表 | `GET /api/v1/experiments` | `items[].id, name, status, created_at` |
| 设备列表 | `GET /api/v1/workbenches/{wb_id}/devices` | `items[].id, name` |
| 测点列表 | `GET /api/v1/devices/{dev_id}/points` | `items[].id, name, unit, data_type` |
| 时序数据 | `POST /api/v1/experiments/{id}/data/query` | 见 PRD §M9 |

### D. 测试用例映射

| 设计项 | 覆盖测试用例 |
|--------|-------------|
| 试验选择 | TC-001 ~ TC-005 |
| 设备选择 | TC-006 ~ TC-010 |
| 测点选择 | TC-011 ~ TC-016 |
| 时间范围 | TC-017 ~ TC-022 |
| 降采样+按钮 | TC-023 ~ TC-028 |
| 图表渲染 | TC-029 ~ TC-034 |
| 图表交互 | TC-035 ~ TC-039 |
| 数据表格 | TC-040 ~ TC-044 |
| 状态处理 | TC-045 ~ TC-049 |
| 主题适配 | TC-050 ~ TC-053 |
| 响应式 | TC-058 ~ TC-061 |

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。