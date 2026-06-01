# TASK-018: 测点列表/配置 UI — 设计规范

> **路由**: `/workbenches/{id}` (工作台详情页 — 设备详情面板内)  
> **依赖**: TASK-007 (可复用组件库)、TASK-016 (设备树)、TASK-017 (设备配置表单)  
> **设计师**: sw-anna  
> **日期**: 2026-06-01

---

## 目录

1. [设计令牌引用](#1-设计令牌引用)
2. [组件总览](#2-组件总览)
3. [PointListWidget — 测点列表](#3-pointlistwidget--测点列表)
4. [PointFormDialog — 添加/编辑测点对话框](#4-pointformdialog--添加编辑测点对话框)
5. [PointValueDisplay — 测点值显示组件](#5-pointvaluedisplay--测点值显示组件)
6. [交互行为汇总](#6-交互行为汇总)
7. [响应式适配方案](#7-响应式适配方案)
8. [主题适配](#8-主题适配)
9. [动画参数](#9-动画参数)
10. [设计 QA 检查项](#10-设计-qa-检查项)

---

## 1. 设计令牌引用

> 完整令牌定义见 `reusable_components_spec.md`。以下为本文档高频使用的令牌摘要。

### 颜色（Light / Dark）

| 语义 | Light | Dark |
|------|-------|------|
| Primary | `#1976D2` | `#90CAF9` |
| On Primary | `#FFFFFF` | `#003258` |
| Error | `#BA1A1A` | `#FFB4AB` |
| Success | `#2E7D32` | `#81C784` |
| Warning | `#ED6C02` | `#FFB74D` |
| Background | `#FDFCFF` | `#1A1C1E` |
| On Background | `#1A1C1E` | `#E2E2E6` |
| Surface | `#FFFFFF` | `#1A1C1E` |
| On Surface | `#1A1C1E` | `#E2E2E6` |
| On Surface Variant | `#43474E` | `#C4C6CF` |
| Outline | `#74777F` | `#8E9099` |
| Surface Variant | `#EFF3FA` | `#43474E` |

### 数据类型标签颜色

| 数据类型 | 背景色 (Light) | 文字色 | 背景色 (Dark) |
|----------|---------------|--------|---------------|
| Number | Primary at 12% | Primary | Primary at 20% |
| Integer | `#7B1FA2` at 12% | `#7B1FA2` | `#7B1FA2` at 20% |
| Boolean | Success at 12% | Success | Success at 20% |
| String | Warning at 12% | Warning | Warning at 20% |

### 间距

| 令牌 | 值 |
|------|-----|
| spaceXs | 4px |
| spaceSm | 8px |
| spaceMd | 16px |
| spaceLg | 24px |
| spaceXl | 32px |

### 排版

| 令牌 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| titleMedium | 16px | 500 | 24px | 面板标题、对话框标题 |
| bodyLarge | 16px | 400 | 24px | 正文、表格内容 |
| bodyMedium | 14px | 400 | 20px | 次要文本、标签 |
| labelLarge | 14px | 500 | 20px | 按钮文字 |
| labelMedium | 12px | 500 | 16px | 标签、角标 |

---

## 2. 组件总览

```
WorkbenchDetailPage (设备详情面板)
├── DeviceInfoSection (设备信息区)
│   ├── Protocol Icon + Name + Status
│   └── Protocol Params (动态)
├── Divider
├── PointListWidget (测点列表)
│   ├── Header (标题 + 计数 + 添加按钮)
│   ├── Content
│   │   ├── Loading → Skeleton (5行)
│   │   ├── Empty → EmptyView
│   │   ├── Error → ErrorView
│   │   └── Data → Table / CardList
│   │       ├── Table Row × N
│   │       │   ├── Name
│   │       │   ├── Type Chip
│   │       │   ├── Access Icon
│   │       │   ├── Unit
│   │       │   ├── PointValueDisplay
│   │       │   └── Actions (Edit/Delete)
│   │       └── (Mobile) Card × N
│   └── └── PointFormDialog (添加/编辑)
│           ├── Basic Fields
│           ├── Modbus Config (conditional)
│           └── Actions
└── ...
```

---

## 3. PointListWidget — 测点列表

### 3.1 整体布局

```
PointListWidget
├── Header (48px)
│   ├── Title + Count    (左)
│   └── [+ 添加测点]     (右)
├── Divider (1px)
└── Content Area
    ├── Loading → SkeletonTable (5 rows)
    ├── Empty → EmptyView
    ├── Error → ErrorView
    └── Data → DataTable / CardList
```

### 3.2 头部 (Header)

| 属性 | 值 |
|------|-----|
| 高度 | 48px |
| 内边距 | 水平 spaceMd (16px)，垂直 spaceSm (8px) |
| 背景 | 透明 |
| 布局 | Row, spaceBetween, center |

**左侧区域**:
- 标题: "测点列表" — Title Medium, On Background
- 计数: "共 12 个测点" — Body Medium, On Surface Variant, 左侧间距 spaceSm (8px)

**右侧区域**:
- 按钮: "+ 添加测点" — Filled Button, 高度 36px
- 图标: `Icons.add`, 18px
- 状态: 加载中禁用，数据状态可用

### 3.3 表格布局 (Desktop ≥1024px)

```
┌─────────────────────────────────────────────────────────────────┐
│ 名称          │ 类型  │ 权限 │ 单位 │ 当前值      │ 操作        │
├───────────────┼───────┼──────┼──────┼─────────────┼─────────────┤
│ 温度传感器     │ Number│  RO  │ °C   │ ● 25.33 °C  │ ✏️ 🗑️      │
│ 阀门状态       │ Bool  │  RW  │ —    │ ● 开启      │ ✏️ 🗑️      │
│ 压力值         │ Int   │  RO  │ MPa  │ ● 101 MPa   │ ✏️ 🗑️      │
└───────────────┴───────┴──────┴──────┴─────────────┴─────────────┘
```

**表格规格**:

| 属性 | 值 |
|------|-----|
| 表格类型 | DataTable (Flutter) |
| 行高 | 52px |
| 表头高度 | 48px |
| 表头背景 | Surface Variant at 50% |
| 表头文字 | Label Medium, On Surface Variant |
| 单元格内边距 | 水平 16px, 垂直 12px |
| 边框 | 水平分隔线 1px Outline at 30% |
| 对齐方式 | 名称(左) / 类型(中) / 权限(中) / 单位(中) / 当前值(左) / 操作(中) |

**列宽分配** (桌面端):

| 列 | 最小宽度 | 占比 |
|----|---------|------|
| 名称 | 120px | flex: 2 |
| 类型 | 80px | fixed |
| 权限 | 80px | fixed |
| 单位 | 60px | fixed |
| 当前值 | 120px | flex: 1.5 |
| 操作 | 100px | fixed |

**表格行交互状态**:

| 状态 | 视觉表现 |
|------|----------|
| 默认 | 背景透明 |
| Hover | 背景 On Surface at 4% |
| 选中 | 无（测点列表无单选状态） |
| 操作按钮显示 | Hover 行时显示，默认显示（桌面端始终显示） |

### 3.4 卡片布局 (Mobile <600px)

```
┌─────────────────────────────────────┐
│ 温度传感器                  Number  │
│                                     │
│ 权限: RO           单位: °C         │
│                                     │
│ ● 25.33 °C                 ✏️ 🗑️  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 阀门状态                   Boolean  │
│                                     │
│ 权限: RW           单位: —          │
│                                     │
│ ● 开启                     ✏️ 🗑️   │
└─────────────────────────────────────┘
```

**卡片规格**:

| 属性 | 值 |
|------|-----|
| 卡片间距 | spaceMd (16px) |
| 卡片内边距 | spaceMd (16px) |
| 卡片圆角 | radiusMedium (8px) |
| 卡片背景 | Surface |
| 卡片阴影 | Elevation 1 |
| 卡片边框 | 1px Outline at 20% (可选，Dark 模式推荐) |

**卡片内容布局**:
- 第一行: 名称 (Body Large, On Background) + 类型 Chip (右侧)
- 第二行: 权限标签 + 单位标签 (Body Medium, On Surface Variant)
- 第三行: PointValueDisplay (左) + 操作按钮 (右)
- 行间距: spaceSm (8px)

### 3.5 类型标签 (Type Chip)

| 数据类型 | 背景色 | 文字色 | 圆角 |
|----------|--------|--------|------|
| Number | Primary at 12% | Primary | radiusSmall (4px) |
| Integer | `#7B1FA2` at 12% | `#7B1FA2` | radiusSmall (4px) |
| Boolean | Success at 12% | Success | radiusSmall (4px) |
| String | Warning at 12% | Warning | radiusSmall (4px) |

**标签规格**:
- 内边距: 水平 8px, 垂直 2px
- 文字: Label Medium (12px)
- 高度: 20px

### 3.6 访问权限显示

| 权限 | 图标 | 文字 | 说明 |
|------|------|------|------|
| RO | `Icons.visibility` / `Icons.remove_red_eye` | 只读 | 灰色圆点 |
| WO | `Icons.edit_off` | 只写 | 橙色圆点 |
| RW | `Icons.sync_alt` | 读写 | 绿色圆点 |

**显示方式**:
- 桌面端: 图标 + 文字 (tooltip 显示全称)
- 移动端: 仅图标 (tooltip 显示全称)
- 图标尺寸: 16px
- 图标颜色: On Surface Variant

### 3.7 操作按钮

| 按钮 | 图标 | 尺寸 | Tooltip |
|------|------|------|---------|
| 编辑 | `Icons.edit_outlined` | 32px IconButton | l10n.edit |
| 删除 | `Icons.delete_outline` | 32px IconButton | l10n.delete |

**按钮规格**:
- 编辑按钮: Primary 色，hover 时背景 Primary at 8%
- 删除按钮: Error 色，hover 时背景 Error at 8%
- 触摸目标: 至少 44×44px (移动端)

### 3.8 三态设计

#### Loading 状态 (TC-PL-001)

```
┌─────────────────────────────────────────────────────┐
│ 测点列表                                  [+ 添加] │  ← 按钮禁用
├─────────────────────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │
└─────────────────────────────────────────────────────┘
```

- 显示 5 行骨架占位
- 每行包含 6 列的占位矩形
- 脉冲动画 (shimmer)
- 不显示计数文本
- 添加按钮禁用或隐藏

#### Empty 状态 (TC-PL-002)

```
┌─────────────────────────────────────────────────────┐
│ 测点列表                       共 0 个测点 [+ 添加] │
├─────────────────────────────────────────────────────┤
│                                                     │
│              [point_of_sale_outlined]               │
│                  48×48px                            │
│                                                     │
│           该设备下暂无测点                          │
│                                                     │
│         ┌──────────────────┐                        │
│         │ 添加第一个测点   │                        │
│         └──────────────────┘                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

- 图标: `Icons.point_of_sale_outlined` 或 `Icons.tune_outlined`
- 图标颜色: On Surface Variant at 60%
- 图标尺寸: 48px (桌面) / 40px (移动)
- 标题: "该设备下暂无测点" — Title Medium
- 按钮: "添加第一个测点" — Filled Button
- 顶部仍显示 "共 0 个测点"

#### Error 状态 (TC-PL-011)

```
┌─────────────────────────────────────────────────────┐
│ 测点列表                                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│              [error_outline]                        │
│                  48×48px                            │
│                                                     │
│              网络连接超时                           │
│                                                     │
│         ┌──────────────────┐                        │
│         │      重试        │                        │
│         └──────────────────┘                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

- 使用标准 ErrorView 组件
- 图标: `Icons.error_outline`, 48px
- 标题: 错误消息 — Title Medium
- 按钮: "重试" — Filled Button
- 点击重试重新加载列表

---

## 4. PointFormDialog — 添加/编辑测点对话框

### 4.1 整体布局

**桌面端 (≥600px)**:
```
┌─────────────────────────────────────────┐
│ 添加测点 / 编辑测点                 [×] │  ← Header (56px)
├─────────────────────────────────────────┤
│                                         │
│ 名称 *                          [______]│  ← Basic Info
│                                         │
│ 数据类型 *                     [▼ Number]│
│                                         │
│ 访问权限 *                        [▼ RO] │
│                                         │
│ 单位                            [______]│
│                                         │
│ 最小值                          [______]│
│                                         │
│ 最大值                          [______]│
│                                         │
│ 默认值                          [______]│
│                                         │
│ ──── Modbus 配置 ────                   │  ← ExpansionTile (Modbus only)
│                                         │
│ 寄存器类型              [▼ Holding Reg] │
│                                         │
│ 起始地址 *                      [______]│
│                                         │
│ 数据格式                 [▼ float32]    │
│                                         │
│          [取消]    [✓ 保存]             │  ← Actions
│                                         │
└─────────────────────────────────────────┘
```

**移动端 (<600px)**: 底部 Sheet，全宽，maxHeight 90%

### 4.2 对话框规格

| 属性 | 桌面端 | 移动端 |
|------|--------|--------|
| 宽度 | 560px | 100% |
| 最大高度 | 80vh | 90vh |
| 圆角 | radiusLarge (12px) | radiusLarge (顶部) |
| 背景 | Surface | Surface |
| 内边距 | spaceMd (16px) | spaceMd (16px) |

### 4.3 头部 (Header)

| 属性 | 值 |
|------|-----|
| 高度 | 56px |
| 标题 | "添加测点" / "编辑测点" — Title Medium |
| 关闭按钮 | `Icons.close`, 32px IconButton, 右侧 |
| 底部分隔线 | 1px Outline at 30% |

### 4.4 表单字段

**基础字段**:

| 字段 | 组件 | 标签 | 占位符 | 验证 | 必填 |
|------|------|------|--------|------|------|
| 名称 | TextFormField | 名称 * | 请输入测点名称 | 1-255 字符 | 是 |
| 数据类型 | DropdownButtonFormField | 数据类型 * | 请选择 | — | 是 |
| 访问权限 | DropdownButtonFormField | 访问权限 * | 请选择 | — | 是 |
| 单位 | TextFormField | 单位 | 例如: °C | 最长 32 字符 | 否 |
| 最小值 | TextFormField | 最小值 | — | 数字 | 否 |
| 最大值 | TextFormField | 最大值 | — | 数字, > min | 否 |
| 默认值 | TextFormField | 默认值 | — | 根据类型 | 否 |

**数据类型选项**:
- Number (浮点数)
- Integer (整数)
- Boolean (布尔值)
- String (字符串)

**访问权限选项**:
- RO (只读)
- WO (只写)
- RW (读写)

**表单字段间距**:
- 字段间垂直间距: spaceMd (16px)
- 标签与输入框间距: spaceXs (4px)

### 4.5 Modbus 配置区域 (条件显示)

**显示条件**: 当前设备协议类型为 Modbus TCP 或 Modbus RTU

**容器**: ExpansionTile，默认展开
- 标题: "Modbus 配置" — Body Medium, On Surface Variant
- 图标: `Icons.settings_ethernet`
- 分隔线: 上方 1px Outline at 30%

**Modbus 字段**:

| 字段 | 组件 | 标签 | 占位符 | 验证 | 必填 |
|------|------|------|--------|------|------|
| 寄存器类型 | DropdownButtonFormField | 寄存器类型 * | 请选择 | — | 是 (Modbus) |
| 起始地址 | TextFormField | 起始地址 * | 0-65535 | 0-65535 整数 | 是 (Modbus) |
| 数据格式 | DropdownButtonFormField | 数据格式 * | 请选择 | — | 是 (Modbus) |

**寄存器类型选项**:
- Coil
- Discrete Input
- Holding Register
- Input Register

**数据格式选项**:
- uint16
- int16
- float32
- uint32
- int32

### 4.6 操作按钮 (Actions)

| 属性 | 值 |
|------|-----|
| 区域高度 | 56px |
| 区域上边距 | spaceMd (16px) |
| 区域顶部边框 | 1px Outline at 30% |
| 对齐 | 右对齐 (桌面) / 居中对距 (移动) |
| 按钮间距 | spaceSm (8px) |

**按钮**:

| 按钮 | 样式 | 文本 | 说明 |
|------|------|------|------|
| 取消 | Text Button | 取消 | 关闭对话框，不保存 |
| 保存 | Filled Button | 保存 | 表单有效时启用 |

**保存按钮状态**:

| 状态 | 表现 |
|------|------|
| 禁用 | 必填字段未填或验证失败 |
| 可用 | 所有必填字段有效 |
| 加载中 | 显示 CircularProgressIndicator (20px)，禁用 |

### 4.7 表单验证与错误显示

**验证时机**:
- 单个字段: 失焦时验证
- 保存按钮: 实时根据表单状态更新

**错误显示**:
- 字段级: 红色下划线 + errorText
- 全局: 对话框内容区顶部红色横幅 (如网络错误)

**验证规则**:

| 字段 | 规则 | 错误消息 |
|------|------|----------|
| 名称 | 必填, 1-255 字符 | "请输入测点名称" / "名称不能超过 255 个字符" |
| 最大值 | 必须 > 最小值 | "最大值必须大于最小值" |
| 起始地址 | 0-65535 | "起始地址必须在 0-65535 之间" |

### 4.8 保存流程

1. 点击保存 → 按钮进入 loading 状态
2. 前端全字段验证 → 失败聚焦首个错误字段
3. 后端请求 POST/PUT
4. 成功 → Toast "测点已保存"，关闭对话框，刷新列表
5. 失败 → 显示错误，保留表单数据，按钮恢复可用

---

## 5. PointValueDisplay — 测点值显示组件

### 5.1 用途

嵌入在测点列表的"当前值"列中，显示测点的实时数值和状态。

### 5.2 布局

```
┌────────────────────┐
│ ● 25.33 °C         │  ← 正常
└────────────────────┘

┌────────────────────┐
│ ◐ 25.33 °C         │  ← 超时
└────────────────────┘

┌────────────────────┐
│ ● —                │  ← 异常
└────────────────────┘
```

### 5.3 状态指示

| 状态 | 图标 | 颜色 | Tooltip | 数值显示 |
|------|------|------|---------|----------|
| normal | `Icons.circle` (实心圆) | On Surface Variant | "正常" | 正常颜色 |
| timeout | `Icons.timelapse` 或 `Icons.circle` (半圆) | Tertiary / Warning | "超时" | 灰色或最后已知值 |
| error | `Icons.circle` (实心圆) | Error | "异常" | "—" 或错误提示 |

**状态图标规格**:
- 尺寸: 8px 圆形
- 位置: 数值左侧，间距 spaceSm (8px)
- 颜色: 见上表

### 5.4 数值格式化

| 数据类型 | 格式化规则 | 示例 |
|----------|-----------|------|
| Number | 保留 2 位小数 | 25.3256 → "25.33" |
| Integer | 无小数 | 101 → "101" |
| Boolean | 本地化文本 | true → "开启", false → "关闭" |
| String | 原样显示 | "Running" → "Running" |

**单位显示**:
- 单位存在时: 数值 + 空格 + 单位 (如 "25.33 °C")
- 单位不存在时: 仅数值 (如 "开启")

### 5.5 加载与错误状态

**加载中**:
- 显示骨架占位: 宽度 60px, 高度 16px, 圆角 4px
- shimmer 动画
- 不显示状态图标

**错误**:
- 数值显示 "—" (破折号)
- 状态图标显示灰色或错误样式
- Tooltip 显示错误信息
- 显示刷新按钮允许重试

### 5.6 刷新按钮

| 属性 | 值 |
|------|-----|
| 图标 | `Icons.refresh` |
| 尺寸 | 20px |
| 颜色 | Primary |
| 位置 | 数值右侧，间距 spaceMd (16px) |
| Tooltip | "刷新" |

**交互**:
- 点击后调用 `getValue` API
- 点击后图标旋转动画 (1s)
- 加载完成后停止旋转

---

## 6. 交互行为汇总

### 6.1 PointListWidget 交互

| 操作 | 触发 | 反馈 |
|------|------|------|
| 点击"+ 添加测点" | 打开添加对话框 | PointFormDialog (isEdit: false) |
| 点击"编辑" | 打开编辑对话框 | PointFormDialog (isEdit: true), 预填数据 |
| 点击"删除" | 打开确认对话框 | ConfirmDialog，标题包含测点名称 |
| 点击"刷新" | 刷新单个测点值 | 值更新，图标旋转 |
| Hover 行 | 背景色变化 | On Surface at 4% |
| 空状态点击"添加第一个测点" | 打开添加对话框 | 同上 |
| 错误状态点击"重试" | 重新加载列表 | 调用 listByDevice |

### 6.2 PointFormDialog 交互

| 操作 | 触发 | 反馈 |
|------|------|------|
| 字段失焦 | 单字段验证 | 红色 errorText (如有错误) |
| 输入名称 | 实时更新保存按钮 | 名称有效时按钮启用 |
| 切换数据类型 | 更新默认值格式 | 字段级联更新 |
| 点击保存 | 全局验证 + API 调用 | 按钮 loading，成功关闭+Toast |
| 点击取消 | 关闭对话框 | 无保存，数据丢失 |
| 点击遮罩 | 关闭对话框 (可配置) | 同上 |
| 按 Esc | 关闭对话框 | 同上 |
| 按 Enter | 提交表单 (保存按钮聚焦时) | 同点击保存 |

### 6.3 删除确认流程

```
点击删除
  → ConfirmDialog 弹出
    标题: "确定要删除测点「{name}」吗？"
    描述: "此操作不可撤销。"
    按钮: [取消] [删除(红色)]
    → 点击删除
      → 调用 delete API
      → 成功: Toast "测点已删除" + 列表刷新
      → 失败: Toast 错误消息 + 保持列表
```

---

## 7. 响应式适配方案

### 7.1 断点定义

| 断点 | 宽度范围 | 设备类型 |
|------|----------|----------|
| Mobile | < 600px | 手机 |
| Tablet | 600-1024px | 平板 |
| Desktop | > 1024px | 桌面 |

### 7.2 PointListWidget 响应式

| 断点 | 布局 | 表格/卡片 | 操作按钮 |
|------|------|-----------|----------|
| Desktop | 完整表格 | DataTable，6 列 | 始终可见 |
| Tablet | 完整表格 | DataTable，6 列 (可能横向滚动) | 始终可见 |
| Mobile | 卡片列表 | Card 垂直排列 | 卡片内显示 |

### 7.3 PointFormDialog 响应式

| 断点 | 样式 | 动画 |
|------|------|------|
| Desktop | 居中对话框，560px | 缩放淡入 |
| Mobile | 底部 Sheet，100% 宽 | 底部滑入 |

### 7.4 触摸目标尺寸

| 元素 | 最小尺寸 |
|------|----------|
| IconButton | 44×44px |
| FilledButton | 48px 高度 |
| 表格行操作区 | 44px 高度 |
| 卡片整体 | 可点击区域 ≥ 44px |

---

## 8. 主题适配

### 8.1 Light 主题

| 元素 | 颜色 |
|------|------|
| 面板背景 | Surface |
| 表格表头 | Surface Variant at 50% |
| 表格行 Hover | On Surface at 4% |
| 类型标签背景 | 见 1.2 节 |
| 对话框背景 | Surface |
| 输入框填充 | Surface Variant at 50% |
| 错误状态 | Error |

### 8.2 Dark 主题

| 元素 | 颜色 |
|------|------|
| 面板背景 | Surface |
| 表格表头 | Surface Variant at 30% |
| 表格行 Hover | On Surface at 8% |
| 类型标签背景 | 见 1.2 节 ( Dark 列) |
| 对话框背景 | Surface |
| 输入框填充 | Surface Variant at 30% |
| 错误状态 | Error |

---

## 9. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 表格行 Hover | 150ms | ease-out | 背景色变化 |
| 卡片 Hover | 150ms | ease-out | Elevation 提升 |
| 对话框进入 (桌面) | 200ms | ease-out | 缩放 + 淡入 |
| 对话框进入 (移动) | 250ms | ease-out | 底部滑入 |
| 对话框离开 | 150ms | ease-in | 反向 |
| 骨架 shimmer | 1.5s | linear | 循环 |
| 值刷新旋转 | 1s | linear | 图标旋转 |
| Toast 进入 | 300ms | ease-out | 滑入 + 淡入 |
| Toast 离开 | 200ms | ease-in | 滑出 + 淡出 |
| 列表刷新 | 200ms | ease-in-out | 骨架淡出，内容淡入 |
| 类型标签出现 | 150ms | ease-out | 缩放 |

---

## 10. 设计 QA 检查项

### 10.1 PointListWidget

- [ ] 头部显示正确：标题 + 计数 + 添加按钮
- [ ] Loading 状态显示 5 行骨架，按钮禁用
- [ ] Empty 状态显示图标 + 文本 + "添加第一个测点"按钮
- [ ] Error 状态显示 ErrorView 带重试按钮
- [ ] Data 状态表格显示 6 列：名称、类型、权限、单位、当前值、操作
- [ ] 类型标签颜色正确：Number-蓝、Integer-紫、Boolean-绿、String-橙
- [ ] 访问权限图标正确：RO-眼睛、WO-编辑禁止、RW-双向箭头
- [ ] 当前值显示数值 + 单位
- [ ] 操作按钮：编辑(Primary)、删除(Error)
- [ ] 行 Hover 效果正确
- [ ] 移动端转为卡片布局
- [ ] 空状态点击"添加第一个测点"打开对话框
- [ ] 删除按钮打开 ConfirmDialog

### 10.2 PointFormDialog

- [ ] 桌面端居中对话框 560px，移动端底部 Sheet
- [ ] 添加模式标题"添加测点"，编辑模式标题"编辑测点"
- [ ] 必填字段带 * 标记：名称、数据类型、访问权限
- [ ] Modbus 设备显示 Modbus 配置区域
- [ ] Virtual 设备不显示 Modbus 配置
- [ ] 编辑模式预填现有数据
- [ ] 保存按钮仅在表单有效时启用
- [ ] 保存时按钮显示 loading 状态
- [ ] 保存成功关闭对话框 + Toast
- [ ] 保存失败显示错误 + 保留表单
- [ ] 取消/关闭对话框不保存
- [ ] 字段验证错误显示正确

### 10.3 PointValueDisplay

- [ ] 正常状态：灰色圆点 + 数值
- [ ] 超时状态：橙色圆点 + 数值(灰色)
- [ ] 异常状态：红色圆点 + "—"
- [ ] 数值格式化正确：Number-2位小数、Integer-整数、Boolean-本地化、String-原样
- [ ] 单位存在时显示数值 + 单位
- [ ] 刷新按钮点击后旋转动画
- [ ] 加载中显示骨架占位

### 10.4 响应式

- [ ] Desktop (≥1024px): 完整表格，操作按钮始终可见
- [ ] Tablet (600-1024px): 表格，可能横向滚动
- [ ] Mobile (<600px): 卡片列表，触摸目标 ≥44px
- [ ] 对话框移动端为底部 Sheet

### 10.5 主题

- [ ] Light 主题颜色正确
- [ ] Dark 主题颜色正确
- [ ] 输入框样式随主题切换
- [ ] 表格行 Hover 在 Dark 模式下更明显

### 10.6 无障碍

- [ ] 所有按钮有 Tooltip
- [ ] 表单字段有 labelText 和 hintText
- [ ] 状态图标有 Tooltip 说明
- [ ] 键盘 Tab 导航顺序正确
- [ ] 对话框内焦点限制
- [ ] 屏幕阅读器正确朗读状态

---

## 附录 A: 组件依赖关系

```
PointListWidget
├── Header
│   ├── Title + Count
│   └── FilledButton (添加)
├── Content (AsyncValueWidget)
│   ├── Loading → SkeletonTable (5 rows × 6 cols)
│   ├── Empty → EmptyView (point_of_sale_outlined)
│   ├── Error → ErrorView (重试)
│   └── Data → Table / CardList
│       ├── TableRow / Card
│       │   ├── Name
│       │   ├── TypeChip
│       │   ├── AccessIcon
│       │   ├── Unit
│       │   ├── PointValueDisplay
│       │   └── ActionButtons
│       └── PointFormDialog (添加/编辑)
│           ├── Header
│           ├── FormFields
│           │   ├── Basic Fields
│           │   └── Modbus Config (ExpansionTile)
│           └── Actions
└── ConfirmDialog (删除确认)

PointValueDisplay
├── StatusDot (8px, 状态色)
├── FormattedValue (类型格式化)
├── Unit (可选)
└── RefreshButton (IconButton)
```

## 附录 B: 图标清单

| 图标 | 用途 | 尺寸 | 颜色 |
|------|------|------|------|
| `add` | 添加测点按钮 | 18px | On Primary |
| `edit_outlined` | 编辑按钮 | 20px | Primary |
| `delete_outline` | 删除按钮 | 20px | Error |
| `refresh` | 刷新值按钮 | 20px | Primary |
| `point_of_sale_outlined` | 空状态图标 | 48px | On Surface Variant |
| `error_outline` | 错误状态图标 | 48px | On Surface Variant |
| `visibility` | RO 权限 | 16px | On Surface Variant |
| `edit_off` | WO 权限 | 16px | On Surface Variant |
| `sync_alt` | RW 权限 | 16px | On Surface Variant |
| `circle` | 状态指示 | 8px | 状态色 |
| `close` | 关闭对话框 | 24px | On Surface |
| `settings_ethernet` | Modbus 配置 | 20px | On Surface Variant |
| `expand_more` | ExpansionTile | 24px | On Surface Variant |

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。

---

## 附录 C：国际化 Key 清单

以下是 TASK-018 需要新增的全部 l10n key，需同步添加到 `app_en.arb` 和 `app_zh.arb`：

| Key | English | 中文 |
|-----|---------|------|
| addFirstPoint | Add First Point | 添加第一个测点 |
| addPoint | Add Point | 添加测点 |
| pointAccessTypeLabel | Access | 访问权限 |
| pointAddressLabel | Start Address | 起始地址 |
| pointAddressRange | Address must be 0-65535 | 起始地址必须在 0-65535 之间 |
| pointColumnAccess | Access | 访问权限 |
| pointColumnAction | Actions | 操作 |
| pointColumnName | Name | 名称 |
| pointColumnType | Type | 类型 |
| pointColumnUnit | Unit | 单位 |
| pointColumnValue | Value | 当前值 |
| pointCount | {count} points | 共 {count} 个测点 |
| pointDataFormatLabel | Data Format | 数据格式 |
| pointDeleteConfirm | Delete point "{name}"? | 确定要删除测点「{name}」吗？ |
| pointDeleteSuccess | Point deleted | 测点已删除 |
| pointDeleteWarning | This action cannot be undone. | 此操作不可撤销。 |
| pointListEmpty | No points for this device | 该设备下暂无测点 |
| pointListTitle | Points | 测点列表 |
| pointModbusConfig | Modbus Configuration | Modbus 配置 |
| pointNameHint | Enter point name | 请输入测点名称 |
| pointNameLabel | Name | 名称 |
| pointNameRequired | Point name is required | 请输入测点名称 |
| pointNameTooLong | Name must not exceed 255 characters | 名称不能超过 255 个字符 |
| pointRangeInvalid | Max must be greater than min | 最大值必须大于最小值 |
| pointRegisterTypeLabel | Register Type | 寄存器类型 |
| pointSaveSuccess | Point saved | 测点已保存 |
| pointStatusError | Error | 异常 |
| pointStatusNormal | Normal | 正常 |
| pointStatusTimeout | Timeout | 超时 |
| pointUnitLabel | Unit | 单位 |
| refresh | Refresh | 刷新 |

> **注意**: `pointCount` 和 `pointDeleteConfirm` 包含 `{count}` 和 `{name}` 占位符，需在 ARB 中正确声明 `@placeholders`。

**修订记录**: 2026-06-01 — 根据 sw-jerry 评审意见 B-01 补充 l10n key 清单
