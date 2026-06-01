# TASK-021: 试验列表页 UI 设计规范

> **路由**: `/experiments`  
> **依赖**: TASK-007 (可复用组件库)  
> **设计师**: sw-anna  
> **日期**: 2026-06-01  
> **状态**: 设计稿完成

---

## 目录

1. [页面布局](#1-页面布局)
2. [组件规格](#2-组件规格)
   - 2.1 StatusBadge — 状态标签
   - 2.2 ExperimentListPage — 试验列表页
   - 2.3 筛选栏 (FilterBar)
   - 2.4 数据表格 (Desktop Table)
   - 2.5 卡片列表 (Mobile Card List)
   - 2.6 分页器 (Pagination)
   - 2.7 空状态 / 加载 / 错误
3. [交互状态](#3-交互状态)
4. [响应式适配](#4-响应式适配)
5. [主题适配](#5-主题适配)
6. [动画参数](#6-动画参数)
7. [设计 QA 检查项](#7-设计-qa-检查项)

---

## 1. 页面布局

### 1.1 整体结构

```
ExperimentListPage
├── AppBar (64px)
│   ├── Title: "试验" (Title Large)
│   └── Primary Button: "+ 创建试验" (高度 40px)
├── Filter Bar (自适应高度, 最小 56px)
│   ├── Status Filter: 状态下拉选择器 (DropdownButton)
│   └── Time Range Picker: 日期范围选择
├── Content Area (padding: spaceMd 16px)
│   ├── [Loading] → Skeleton Table (5 行占位)
│   ├── [Error]   → ErrorView + 重试按钮
│   ├── [Empty]   → EmptyView (图标 + 引导 + 创建按钮)
│   └── [Data]    → DataTable (桌面) / Card List (移动)
└── Pagination Bar (48px)
    └── Page controls + "共 N 条"
```

### 1.2 布局参数

| 属性 | 值 |
|------|-----|
| Page Background | Background color token |
| Content Padding | spaceMd (16px) |
| Content Max Width | 无限制（流体布局） |
| 表格区最小高度 | 300px（保证空/错误状态垂直居中） |

---

## 2. 组件规格

### 2.1 StatusBadge — 状态标签（可复用组件）

#### 用途

用于在试验列表、详情页、设备树等场景中统一展示试验状态。StatusBadge 是独立组件，可被任何需要展示试验状态的地方引用。

#### 6 种状态定义

| 状态 | 颜色 (Light) | 颜色 (Dark) | 容器背景 | 图标 | 说明 |
|------|-------------|-------------|----------|------|------|
| **IDLE** | `#757575` | `#BDBDBD` | On Surface Variant at 12% | — | 空闲，未开始 |
| **LOADED** | `#1976D2` | `#90CAF9` | Primary at 12% | — | 已加载配置 |
| **RUNNING** | `#2E7D32` | `#81C784` | Success at 12% | `Icons.play_arrow` (12px) | 运行中，带脉冲动画 |
| **PAUSED** | `#ED6C02` | `#FFB74D` | Warning at 12% | `Icons.pause` (12px) | 已暂停 |
| **COMPLETED** | `#2E7D32` | `#81C784` | Success at 12% | `Icons.check` (12px) | 已完成 |
| **ABORTED** | `#BA1A1A` | `#FFB4AB` | Error at 12% | `Icons.close` (12px) | 已终止 |

#### 视觉规格

```
┌────────────────────────────┐
│  ● 运行中                   │  ← RUNNING 状态示例
│  ↑ 脉冲动画圆点              │
│  文字: Body Small, 12px      │
└────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 容器高度 | 24px（固定） |
| 容器内边距 | 水平 8px，垂直 0 |
| 圆角 | radiusSmall (4px) |
| 布局 | Row，gap: 4px，center |
| 状态圆点 | 8px 圆形，状态色 |
| 状态图标 | 12px，状态色（RUNNING/PAUSED/COMPLETED/ABORTED） |
| 文字 | Body Small (12px, 500)，状态色 |
| 最小宽度 | 48px |

#### RUNNING 脉冲动画

```
脉冲效果：
┌──────────────────────────────────┐
│  ●●● 运行中                      │
│  ↑ 外层圆环放大 + 透明度衰减      │
│  内层保持实色圆点                 │
└──────────────────────────────────┘
```

| 动画参数 | 值 |
|----------|-----|
| 动画类型 | 缩放 + 透明度 |
| 外层圆环 | 从 8px → 16px，opacity 1 → 0 |
| 动画时长 | 1.5s 循环 |
| 缓动函数 | ease-out |
| 触发条件 | status == RUNNING |
| 减少动效 | prefers-reduced-motion 时禁用脉冲，仅显示静态绿点 |

#### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **默认** | 标准状态标签 | 常规显示 |
| **Hover** | 背景色加深 4% | 鼠标悬停（如可点击） |
| **Pressed** | Scale 0.95 | 点击（如用于筛选） |
| **Disabled** | 38% 不透明度 | 禁用状态 |

#### 响应式

| 断点 | 标签高度 | 文字 | 圆点 |
|------|----------|------|------|
| Mobile (< 600px) | 20px | 10px | 6px |
| Tablet/Desktop (> 600px) | 24px | 12px | 8px |

#### 组件接口（参考）

```dart
StatusBadge(
  status: ExperimentStatus.running,  // 必填
  showIcon: true,                   // 是否显示图标，默认 true
  showPulse: true,                  // RUNNING 是否脉冲，默认 true
  onTap: () => filterByStatus(),    // 可选，点击回调
  compact: false,                   // 紧凑模式（用于小空间）
)
```

---

### 2.2 ExperimentListPage — 试验列表页

#### 2.2.1 页面头部 (AppBar)

| 属性 | 值 |
|------|-----|
| 高度 | 64px |
| 背景 | Surface |
| 底部边框 | 1px Outline Variant |
| 标题 | "试验"，Title Large (22px, 400)，On Background |
| 创建按钮 | Filled Button，高 40px，"+ 创建试验" |
| 按钮图标 | `Icons.add`，20px |

#### 2.2.2 筛选栏 (FilterBar)

**布局结构**:

```
┌──────────────┐  ┌──────────────────────┐  ┌──────┐
│ 全部状态     ▼  │  开始 ~ 结束          │  │ 重置 │
├──────────────┤  ├──────────────────────┤  └──────┘
│ 全部状态      │  │  日期范围选择器       │
│ IDLE         │  └──────────────────────┘
│ LOADED       │
│ RUNNING      │
│ PAUSED       │
│ COMPLETED    │
│ ABORTED      │
└──────────────┘
```

| 属性 | 值 |
|------|-----|
| 容器背景 | Surface |
| 内边距 | spaceMd (16px) |
| 底部边框 | 1px Outline Variant |
| 标签 | "状态" / "时间"，Label Medium (12px, 500)，On Surface Variant |
| 状态筛选 | DropdownButton，单选 |
| 时间选择器 | Outlined TextField，带日历图标，宽 140px |
| 重置按钮 | Text Button "重置筛选"，右侧对齐 |

**DropdownButton 规格**:

| 属性 | 值 |
|------|-----|
| 宽度 | 140px |
| 高度 | 40px |
| 圆角 | radiusSmall (4px) |
| 边框 | 1px Outline Variant |
| 背景 | Surface |
| 文字 | Body Medium (14px)，On Surface |
| 下拉图标 | `Icons.arrow_drop_down`，20px，On Surface Variant |

**下拉选项列表**:

| 选项 | 显示文字 | 样式 |
|------|----------|------|
| 全部状态 | "全部状态" | Body Medium，On Surface |
| IDLE | "空闲" | 左侧 8px 灰色圆点 + "空闲" |
| LOADED | "已加载" | 左侧 8px 蓝色圆点 + "已加载" |
| RUNNING | "运行中" | 左侧 8px 绿色圆点 + "运行中" |
| PAUSED | "已暂停" | 左侧 8px 橙色圆点 + "已暂停" |
| COMPLETED | "已完成" | 左侧 8px 绿色圆点 + "已完成" |
| ABORTED | "已终止" | 左侧 8px 红色圆点 + "已终止" |

**下拉菜单样式**:
- 宽度：与 DropdownButton 同宽 (140px)
- 背景：Surface
- 圆角：radiusSmall (4px)
- 阴影：Elevation 2
- 选项高度：40px
- Hover：On Surface 4% 背景
- 选中项：Primary 8% 背景

**时间选择器交互**:
- 点击字段：打开日期选择对话框 (DatePicker)
- 日期格式：YYYY-MM-DD
- 结束日期 ≥ 开始日期（无效时显示错误提示）
- 选择后自动触发筛选

---

### 2.3 数据表格 (Desktop Table)

**表格结构**:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ 名称          │ 方法      │ 状态      │ 开始时间           │ 持续时间  │ 操作   │
├───────────────┼───────────┼───────────┼────────────────────┼───────────┼────────┤
│ 材料拉伸测试   │ 拉伸方法   │ ● 运行中   │ 2026-05-31 10:00   │ 00:32:15  │ ▶ ⏸ ✕ │
│ 温度循环实验   │ 循环方法   │ ● 已完成   │ 2026-05-30 14:20   │ 02:15:00  │ 📊 🗑️ │
│ 压力阈值测试   │ 阈值方法   │ ● 已暂停   │ 2026-05-30 09:00   │ 00:45:30  │ ▶ ✕   │
│ 新试验配置     │ —         │ ● 空闲     │ —                  │ —         │ ✏️ 🗑️ │
│ 振动耐久测试   │ 耐久方法   │ ● 已终止   │ 2026-05-29 16:00   │ 00:10:20  │ 🗑️   │
└──────────────────────────────────────┴───────────┴────────────────────┴───────────┴────────┘
```

**列定义**:

| 列名 | 宽度 | 对齐 | 内容 |
|------|------|------|------|
| 名称 | flex: 2 | 左对齐 | Body Medium (14px)，单行省略，最大宽度 240px |
| 方法 | flex: 1 | 左对齐 | Body Medium，On Surface Variant，"—" 表示未设置 |
| 状态 | 100px | 左对齐 | StatusBadge 组件 |
| 开始时间 | 160px | 左对齐 | Body Medium，YYYY-MM-DD HH:mm 格式，"—" 表示未开始 |
| 持续时间 | 100px | 右对齐 | Body Medium，HH:mm:ss 格式，运行中实时更新 |
| 操作 | 120px | 右对齐 | IconButton 组 |

**表头规格**:

| 属性 | 值 |
|------|-----|
| 高度 | 48px |
| 背景 | Surface Variant at 50% |
| 文字 | Label Medium (12px, 500)，On Surface Variant |
| 底部边框 | 1px Outline Variant |

**行规格**:

| 属性 | 值 |
|------|-----|
| 高度 | 52px |
| 背景 | 透明（奇偶行可交替 Surface Variant at 4%） |
| 底部边框 | 1px Outline Variant at 50% |
| 内边距 | 水平 16px |

**行状态**:

| 状态 | 视觉表现 |
|------|----------|
| Default | 透明背景 |
| Hover | On Surface 4% 背景 |
| Selected | Primary 8% 背景，左侧 3px Primary 边框 |
| RUNNING 行 | 微弱绿色背景 tint (Success at 4%) |

**操作按钮定义**:

| 试验状态 | 可用操作 | 图标 | 颜色 |
|----------|----------|------|------|
| IDLE | 编辑、删除 | `edit`, `delete` | Primary, Error |
| LOADED | 启动、编辑、删除 | `play_arrow`, `edit`, `delete` | Success, Primary, Error |
| RUNNING | 暂停、停止 | `pause`, `stop` | Warning, Error |
| PAUSED | 继续、停止 | `play_arrow`, `stop` | Success, Error |
| COMPLETED | 查看报告、删除 | `assessment`, `delete` | Primary, Error |
| ABORTED | 删除 | `delete` | Error |

**操作按钮交互**:
- IconButton，32px
- Hover: 背景色变化（对应状态色 8%）
- Tooltip: 显示操作名称
- 点击后：如需要二次确认，弹出 ConfirmDialog

---

### 2.4 卡片列表 (Mobile Card List)

**卡片结构**:

```
┌─────────────────────────────────────────┐
│ 材料拉伸测试                 ● 运行中    │  ← 名称 + StatusBadge
│                                         │
│ 方法: 拉伸方法                           │  ← 方法
│                                         │
│ 开始: 2026-05-31 10:00                  │  ← 开始时间
│ 持续: 00:32:15                          │  ← 持续时间
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ▶ 暂停    ⏹ 停止                   │ │  ← 操作按钮
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**卡片规格**:

| 属性 | 值 |
|------|-----|
| 背景 | Surface |
| 圆角 | radiusMedium (8px) |
| 内边距 | spaceMd (16px) |
| 间距 | spaceMd (16px)（卡片之间） |
| 阴影 | Elevation 1 |

**卡片内容**:

| 元素 | 样式 |
|------|------|
| 头部行 | Row，space-between，名称 + StatusBadge |
| 名称 | Body Large (16px, 500)，On Background，单行省略 |
| 信息行 | Body Medium (14px)，On Surface Variant，行间距 4px |
| 操作区 | Row，操作按钮（图标 + 文字），间距 8px |
| 操作按钮 | 高度 36px，圆角 8px，图标 + 文字 |

**卡片状态**:

| 状态 | 视觉表现 |
|------|----------|
| Default | Elevation 1 |
| Hover/Pressed | Elevation 2，背景 On Surface 4% |
| RUNNING | 顶部 3px 绿色边框 (Success) |

---

### 2.5 分页器 (Pagination)

```
┌────────────────────────────────────────────────────────────────────┐
│  共 47 条    <  1  2  3  ...  5  >    每页 10 条  [▼]             │
└────────────────────────────────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 高度 | 48px |
| 背景 | Surface |
| 顶部边框 | 1px Outline Variant |
| 内边距 | 水平 spaceMd (16px) |
| 总条数 | Body Medium (14px)，On Surface Variant，左侧 |
| 页码 | TextButton 组，当前页 Primary 背景，其他 Transparent |
| 前后页 | IconButton (`chevron_left` / `chevron_right`) |
| 每页条数 | DropdownButton，选项: 10, 20, 50 |
| 对齐 | 两端对齐（总数左，页码中，条数右） |

**分页交互**:

| 操作 | 反馈 |
|------|------|
| 点击页码 | 加载对应页数据，表格顶部显示线性进度条 |
| 切换每页条数 | 重置到第 1 页 |
| 上一页/下一页 | 边界时禁用按钮 |

---

### 2.6 空状态 (Empty State)

使用 TASK-007 EmptyView 组件：

| 属性 | 值 |
|------|-----|
| Icon | `Icons.science_outlined`，48px |
| Title | "暂无试验" (l10n) |
| Description | "点击下方按钮创建您的第一个试验" |
| Action | Filled Button "创建第一个试验" |

**有筛选条件时的空状态**:

| 属性 | 值 |
|------|-----|
| Icon | `Icons.filter_list_off`，48px |
| Title | "没有符合条件的试验" |
| Description | "请尝试调整筛选条件" |
| Action | Text Button "清除筛选条件" |

---

### 2.7 加载状态 (Loading)

使用 TASK-007 Skeleton 组件：

**桌面端 — 表格骨架**:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │ ▓▓▓▓▓▓ │
└──────────────────────────────────────────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 行数 | 5 行 |
| 列数 | 6 列（与表格一致） |
| 占位高度 | 16px |
| 动画 | Skeleton shimmer，1.5s 循环 |

**移动端 — 卡片骨架**:

- CardSkeleton，显示 3 张占位卡片
- 每张包含：标题行 + 3 行信息 + 操作区占位

---

### 2.8 错误状态 (Error)

使用 TASK-007 ErrorView 组件：

| 属性 | 值 |
|------|-----|
| Icon | `Icons.error_outline_outlined`，48px |
| Title | "加载试验列表失败" |
| Description | "请检查网络连接后点击重试" |
| Action | Filled Button "重试" |
| onRetry | 重新调用试验列表 API |

---

## 3. 交互状态

### 3.1 页面级状态流转

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Loading │───→│  Empty  │───→│  Data   │←───│  Error  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │                              │              │
     │ (有数据)                     │ (删除全部)   │ (重试成功)
     └──────────────────────────────┘              │
                                                   │
                                              (重试失败)
                                                   │
                                              保持 Error

筛选变化:
Data ──(筛选无结果)──→ Empty (带"清除筛选"按钮)
Empty ──(清除筛选)──→ Data / Empty (原始空状态)
```

### 3.2 操作交互

| 操作 | 触发 | 反馈 |
|------|------|------|
| 点击创建试验 | AppBar 按钮 | 导航到创建页 `/experiments/create` |
| 状态筛选 | 选择 Dropdown 选项 | 实时筛选，表格刷新，URL query 更新 (?status=RUNNING) |
| 时间筛选 | 选择日期范围 | 实时筛选，表格刷新 |
| 重置筛选 | 点击"重置筛选" | 清除所有筛选（状态恢复为"全部状态"），显示全部数据 |
| 点击行 | 表格行/卡片 | 导航到详情页 `/experiments/{id}` |
| 启动试验 | 点击 ▶ | ConfirmDialog "确认启动试验？" → API → Toast |
| 暂停试验 | 点击 ⏸ | ConfirmDialog "确认暂停试验？" → API → Toast |
| 停止/终止 | 点击 ⏹ | ConfirmDialog "确认终止试验？此操作不可撤销" → API → Toast |
| 删除试验 | 点击 🗑️ | ConfirmDialog（危险变体）→ API → Toast |
| 切换页码 | 点击页码 | 顶部线性进度条 + 表格更新 |

### 3.3 试验状态操作矩阵

| 当前状态 | 可执行操作 | 操作后状态 |
|----------|-----------|-----------|
| IDLE | 编辑、删除 | — |
| LOADED | 启动、编辑、删除 | RUNNING |
| RUNNING | 暂停、停止 | PAUSED / ABORTED |
| PAUSED | 继续、停止 | RUNNING / ABORTED |
| COMPLETED | 查看报告、删除 | — |
| ABORTED | 删除 | — |

---

## 4. 响应式适配

### 4.1 断点定义

| 断点 | 宽度 | 表格/卡片 | 筛选栏 | 分页 |
|------|------|-----------|--------|------|
| Mobile | < 600px | 卡片列表 | 垂直堆叠 | 简化 |
| Tablet | 600-1024px | 表格（紧凑列） | 水平排列 | 标准 |
| Desktop | > 1024px | 表格（全列） | 水平排列 | 标准 |

### 4.2 移动端适配详情

**AppBar**:
- "创建试验" 按钮简化为 IconButton (`Icons.add`)
- 标题保持 "试验"

**筛选栏**:
- 状态筛选：DropdownButton，全宽
- 时间选择器：垂直堆叠，全宽
- 重置按钮：全宽，位于筛选区底部

**卡片列表**:
- 单列，全宽
- 卡片内边距减少至 spaceSm (12px)
- 操作按钮：图标 + 文字，全宽或等分

**分页**:
- 简化页码显示（仅上一页/下一页 + 当前页/总页）
- 每页条数选择器隐藏或移至底部菜单

### 4.3 平板适配

- 表格显示全部列，但列宽压缩
- 筛选栏水平排列，但允许换行
- 分页标准显示

---

## 5. 主题适配

### 5.1 颜色

| 元素 | Light Theme | Dark Theme |
|------|------------|------------|
| Page Background | Background (#FDFCFF) | Background (#1A1C1E) |
| Surface | Surface (#FFFFFF) | Surface (#1A1C1E) |
| Table Header BG | Surface Variant 50% | Surface Variant 50% |
| Table Row Hover | On Surface 4% | On Surface 4% |
| Table Row Selected | Primary 8% | Primary 8% |
| RUNNING Row Tint | Success 4% | Success 4% |
| Card Border | Outline Variant | Outline Variant |
| Divider | Outline Variant | Outline Variant |

### 5.2 状态颜色（汇总）

| 状态 | Light 文字/圆点 | Light 背景 | Dark 文字/圆点 | Dark 背景 |
|------|----------------|------------|----------------|-----------|
| IDLE | `#757575` | `rgba(117,117,117,0.12)` | `#BDBDBD` | `rgba(189,189,189,0.12)` |
| LOADED | `#1976D2` | `rgba(25,118,210,0.12)` | `#90CAF9` | `rgba(144,202,249,0.12)` |
| RUNNING | `#2E7D32` | `rgba(46,125,50,0.12)` | `#81C784` | `rgba(129,199,132,0.12)` |
| PAUSED | `#ED6C02` | `rgba(237,108,2,0.12)` | `#FFB74D` | `rgba(255,183,77,0.12)` |
| COMPLETED | `#2E7D32` | `rgba(46,125,50,0.12)` | `#81C784` | `rgba(129,199,132,0.12)` |
| ABORTED | `#BA1A1A` | `rgba(186,26,26,0.12)` | `#FFB4AB` | `rgba(255,180,171,0.12)` |

---

## 6. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 200ms | ease-out | Fade + Slide |
| 表格行 Hover | 150ms | ease-out | 背景色过渡 |
| 行选中 | 150ms | ease-out | 左侧边框 + 背景色 |
| StatusBadge 脉冲 | 1.5s | ease-out | 循环，RUNNING 专属 |
| 筛选切换 | 200ms | ease-in-out | 表格 Fade + 新数据 Fade In |
| 分页切换 | 300ms | ease-in-out | 表格 Fade，顶部进度条 |
| 卡片 Hover | 150ms | ease-out | Elevation 变化 |
| Dialog 进入 | 200ms | ease-out | Scale/Fade |
| Dialog 离开 | 150ms | ease-in | 反向 |
| Skeleton shimmer | 1.5s | linear | 循环 |
| Toast | 300ms | ease-out | 滑入 |

---

## 7. 设计 QA 检查项

### 7.1 通用检查

- [ ] 所有颜色与 Design Token 完全一致
- [ ] Light/Dark 主题切换颜色正确
- [ ] 组件间距符合 8px 网格系统
- [ ] 圆角一致（按组件规范）
- [ ] 阴影层级正确
- [ ] 动画时长和缓动符合规范

### 7.2 页面级检查

- [ ] 三态完整：Loading (Skeleton) / Error (ErrorView) / Empty (EmptyView) / Data (Table/Card)
- [ ] 筛选栏：状态下拉单选正确（全部/空闲/已加载/运行中/已暂停/已完成/已终止）
- [ ] 时间范围选择器：日期格式正确，范围验证正确
- [ ] 重置筛选按钮功能正常
- [ ] 分页器：页码、总条数、每页条数正确
- [ ] 创建试验按钮导航正确
- [ ] 空状态有引导操作（创建按钮）

### 7.3 StatusBadge 检查

- [ ] 6 种状态颜色正确（灰/蓝/绿/橙/绿/红）
- [ ] RUNNING 状态带脉冲动画
- [ ] 脉冲动画在 prefers-reduced-motion 下禁用
- [ ] 文字、圆点、图标颜色一致
- [ ] 紧凑模式在小空间显示正常

### 7.4 表格检查

- [ ] 6 列完整：名称、方法、状态、开始时间、持续时间、操作
- [ ] 表头固定，内容滚动
- [ ] 行 Hover 背景变化
- [ ] 操作按钮根据状态动态显示
- [ ] 持续时间实时更新（RUNNING 状态）
- [ ] 名称/方法过长时正确省略

### 7.5 卡片检查

- [ ] 信息完整：名称、方法、状态、时间、持续时间、操作
- [ ] RUNNING 卡片顶部绿色边框
- [ ] 操作按钮根据状态动态显示
- [ ] 触摸目标 ≥ 44px

### 7.6 响应式检查

- [ ] Mobile (< 600px): 卡片列表，简化分页
- [ ] Tablet (600-1024px): 紧凑表格
- [ ] Desktop (> 1024px): 完整表格
- [ ] 移动端筛选栏垂直堆叠

### 7.7 无障碍检查

- [ ] 表格行可键盘导航（Tab/Shift+Tab）
- [ ] 操作按钮有 aria-label
- [ ] StatusBadge 有状态说明（屏幕阅读器）
- [ ] 脉冲动画尊重 prefers-reduced-motion
- [ ] 颜色对比度符合 WCAG AA
- [ ] 状态下拉有正确的 aria-label 和 aria-expanded 状态

---

## 修订记录

### Rev.1 — 2026-06-01 (sw-anna)
**B1 阻塞修正：状态筛选从多选 FilterChips 改为单选 DropdownButton**

**原因**: 后端 `ListExperimentsRequest.status` 当前仅支持单值查询（`?status=RUNNING`），UI 设计中的多选 chips 无法直接对接。

**变更内容**:
1. **§1.1 页面布局**: Filter Bar 描述从"6 状态多选 Chips"改为"状态下拉选择器 (DropdownButton)"
2. **§2.2.2 筛选栏**: 完整重写——从 FilterChip 组改为 DropdownButton 单选，增加下拉选项样式、下拉菜单样式规格
3. **§3.2 操作交互**: 状态筛选从"点击 FilterChip"改为"选择 Dropdown 选项"，URL query 从多值改为单值
4. **§4.2 移动端适配**: 状态筛选从"水平滚动 Chip 组"改为"DropdownButton"
5. **§7.2 QA 检查项**: 筛选栏检查项从"6 种状态多选"改为"状态下拉单选"
6. **§7.7 无障碍检查**: 从 Chip 的 aria-pressed 改为 Dropdown 的 aria-label/aria-expanded

**后续迭代**: 后端支持多选后，可恢复为 FilterChips 多选设计。

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。
