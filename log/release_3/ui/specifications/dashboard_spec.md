# TASK-024: 首页仪表盘 UI — 设计规格文档

> **任务**: TASK-024 — M2 首页仪表盘 UI  
> **设计师**: sw-anna  
> **日期**: 2026-06-08  
> **版本**: 1.0  
> **状态**: 设计完成  
> **路由**: `/` (fallback) / `/dashboard`  
> **依赖**: TASK-008 (Auth Provider), TASK-012 (Workbench Provider), TASK-020 (Experiment Provider)

---

## 目录

1. [设计概述](#1-设计概述)
2. [页面结构](#2-页面结构)
3. [区域详细规格](#3-区域详细规格)
   - 3.1 欢迎区域
   - 3.2 快捷操作卡片
   - 3.3 统计概览
   - 3.4 最近工作台
4. [三态设计](#4-三态设计)
   - 4.1 骨架屏 (Loading)
   - 4.2 空状态 (Empty)
   - 4.3 错误状态 (Error)
5. [响应式布局](#5-响应式布局)
6. [主题适配](#6-主题适配)
7. [无障碍设计](#7-无障碍设计)
8. [动画与动效](#8-动画与动效)
9. [组件清单](#9-组件清单)
10. [设计 QA 检查项](#10-设计-qa-检查项)

---

## 1. 设计概述

### 1.1 设计目标

仪表盘是用户登录后的首个页面，承担"信息聚合 + 快捷入口"的双重职责：
- **信息聚合**: 一眼掌握核心资源数量（工作台、设备、试验）
- **快捷入口**: 快速进入四大高频功能模块
- **最近活动**: 快速访问最近操作的工作台

### 1.2 设计原则

1. **按区域独立容错**: 每个数据区域独立管理状态，单点失败不影响全局
2. **零数据友好**: 新用户首次进入时，通过引导而非空白页面帮助上手
3. **信息层级清晰**: 欢迎 → 快捷操作 → 统计 → 最近活动，视觉权重递减
4. **即时反馈**: 骨架屏 + 数字计数动画，减少等待焦虑

### 1.3 参考文档

- PRD §M2 验收标准
- 测试用例: `log/release_3/test/TASK-024_test_cases.md`
- 可复用组件库: `log/release_3/ui/specifications/reusable_components_spec.md`
- M1 认证设计: `log/release_3/ui/specifications/M1_auth_spec.md`

---

## 2. 页面结构

### 2.1 整体布局

```
┌─────────────────────────────────────────────────────────────────┐
│  AppShell (NavigationRail / BottomNavigationBar)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  欢迎区域                                                │   │
│  │  "早上好，Alice"                                         │   │
│  │  "2026年6月8日 星期一"                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐  │
│  │ 🧪 试验     │ │ 📐 方法     │ │ 🔧 工作台   │ │ 📊 分析     │  │
│  │ 控制台      │ │            │ │ 管理        │ │ 数据        │  │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  统计概览                                                │   │
│  │  ┌──────┐  ┌──────┐  ┌──────┐                          │   │
│  │  │ 5    │  │ 12   │  │ 8    │                          │   │
│  │  │工作台 │  │设备  │  │试验  │                          │   │
│  │  └──────┘  └──────┘  └──────┘                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  最近工作台                                      [查看全部]│   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐          │   │
│  │  │温度实验室│ │振动测试台│ │压力测试区│ │湿度实验室│          │   │
│  │  │5 台设备 │ │3 台设备 │ │4 台设备 │ │0 台设备 │          │   │
│  │  │3 天前  │ │1 周前  │ │2 周前  │ │1 个月前│          │   │
│  │  └────────┘ └────────┘ └────────┘ └────────┘          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 区域层级

| 层级 | 区域 | 数据依赖 | 容错策略 |
|------|------|----------|----------|
| 1 | 欢迎区域 | Auth Provider (缓存) | 回退为仅日期 |
| 2 | 快捷操作 | 静态内容 | 始终显示 |
| 3 | 统计概览 | Workbench/Experiment API | 本区域 ErrorView + 重试 |
| 4 | 最近工作台 | Workbench API | 本区域 ErrorView + 重试 |

---

## 3. 区域详细规格

### 3.1 欢迎区域 (Welcome Section)

#### 视觉规格

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   早上好，Alice                                          │  ← Headline Small
│   2026年6月8日 星期一                                    │  ← Body Large, On Surface Variant
│                                                         │
└─────────────────────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 布局 | 左对齐，Column |
| 内边距 | top: spaceXl (32px), bottom: spaceLg (24px) |
| 问候语 | Headline Small, On Surface |
| 日期 | Body Large, On Surface Variant |
| 日期上边距 | spaceSm (8px) |

#### 时间段问候语映射

| 时间段 (24h) | 中文 (zh) | 英文 (en) |
|:-----------:|-----------|-----------|
| 06:00-11:59 | 早上好 | Good morning |
| 12:00-17:59 | 下午好 | Good afternoon |
| 18:00-05:59 | 晚上好 | Good evening |

#### 日期格式

| 语言 | 格式 | 示例 |
|------|------|------|
| zh | `yyyy年M月d日 EEEE` | 2026年6月8日 星期一 |
| en | `EEEE, MMMM d, yyyy` | Monday, June 8, 2026 |

#### 用户名处理

| 场景 | 行为 |
|------|------|
| username 有值 | "{greeting}，{username}" |
| username 为空/null | "{greeting}"（不带逗号） |
| username 过长 | 省略号截断，max-width: 400px |

#### 交互状态

| 状态 | 表现 |
|------|------|
| 加载中 | 问候语: ShimmerBlock 200×32px, 日期: ShimmerBlock 160×20px |
| 加载完成 | 淡入动画 (200ms) |
| 语言切换 | 文本即时更新，无闪烁 |
| 时间变化 | 整点边界自动更新问候语 |

---

### 3.2 快捷操作卡片 (Quick Action Cards)

#### 视觉规格

```
┌────────────────────────┐
│  ┌──────────────────┐  │
│  │    🧪 (32px)     │  │  ← Icon, Primary
│  │   Primary        │  │     Container bg
│  │   Container      │  │
│  └──────────────────┘  │
│                        │
│  试验控制台             │  ← Title Medium, On Surface
│  管理和运行试验          │  ← Body Small, On Surface Variant
│                        │
└────────────────────────┘
```

#### 卡片规格

| 属性 | Desktop | Mobile |
|------|---------|--------|
| 背景 | Surface | Surface |
| 边框 | 1px Outline Variant | 1px Outline Variant |
| 圆角 | radiusLarge (12px) | radiusLarge (12px) |
| 内边距 | spaceLg (24px) | spaceMd (16px) |
| 图标容器 | 48×48px, radiusMedium | 40×40px, radiusMedium |
| 图标容器背景 | Primary Container | Primary Container |
| 图标尺寸 | 28px | 24px |
| 图标颜色 | Primary | Primary |
| 标题上边距 | spaceSm (8px) | spaceSm (8px) |
| 副标题上边距 | spaceXs (4px) | spaceXs (4px) |
| 最小高度 | 120px | 100px |
| 网格列数 | 4 列 | 2 列 |
| 间距 | spaceMd (16px) | spaceSm (8px) |

#### 四张卡片定义

| # | 图标 | 标题 (zh) | 标题 (en) | 副标题 (zh) | 副标题 (en) | 路由 |
|---|------|-----------|-----------|-------------|-------------|------|
| 1 | `Icons.biotech` | 试验控制台 | Experiment Console | 管理和运行试验 | Manage and run experiments | `/experiments` |
| 2 | `Icons.science` | 试验方法 | Methods | 配置标准方法 | Configure standard methods | `/methods` |
| 3 | `Icons.build` | 工作台管理 | Workbenches | 管理工作台和设备 | Manage workbenches and devices | `/workbenches` |
| 4 | `Icons.analytics` | 数据分析 | Data Analysis | 查看试验数据 | View experiment data | `/analysis` |

#### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **默认** | Surface, 1px Outline Variant, elevation 1 | 常态 |
| **Hover** | Elevation 2, 边框色 Primary at 30% | 鼠标悬停 |
| **Pressed** | Scale 0.98, Elevation 1 | 点击/触摸 |
| **Focus** | 2px Primary outline | 键盘聚焦 |
| **Disabled** | 38% opacity | 不可用（当前不适用） |

#### 无障碍

- `Semantics` label: "{title}，{subtitle}，点击进入"
- 键盘: Tab 切换焦点, Enter/Space 激活
- 触摸目标: 整张卡片 ≥ 48×48dp

---

### 3.3 统计概览 (Stats Overview)

#### 视觉规格

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │              │  │              │  │              │  │
│  │  🏗️ (28px)   │  │  💾 (28px)   │  │  🧪 (28px)   │  │
│  │              │  │              │  │              │  │
│  │     5        │  │     12       │  │     8        │  │  ← 48px, Primary
│  │              │  │              │  │              │  │
│  │   工作台      │  │   设备       │  │   试验       │  │  ← Body Medium
│  │              │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 统计卡片规格

| 属性 | Desktop | Mobile |
|------|---------|--------|
| 背景 | Surface Container Low | Surface Container Low |
| 圆角 | radiusLarge (12px) | radiusLarge (12px) |
| 内边距 | spaceLg (24px) | spaceMd (16px) |
| 最小高度 | 120px | 100px |
| 布局 | Column, 居中 | Column, 居中 |
| 图标尺寸 | 28px | 24px |
| 图标颜色 | On Surface Variant | On Surface Variant |
| 数字字号 | 48px | 36px |
| 数字颜色 | Primary | Primary |
| 数字字重 | FontWeight.w300 | FontWeight.w300 |
| 数字上边距 | spaceSm (8px) | spaceSm (8px) |
| 标签字号 | Body Medium | Body Small |
| 标签颜色 | On Surface Variant | On Surface Variant |
| 标签上边距 | spaceXs (4px) | spaceXs (4px) |

#### 三张统计卡片定义

| # | 图标 | 标签 (zh) | 标签 (en) | 数据源 |
|---|------|-----------|-----------|--------|
| 1 | `Icons.build_outlined` | 工作台 | Workbenches | `GET /api/v1/workbenches?page=1&size=1` → `total` |
| 2 | `Icons.memory_outlined` | 设备 | Devices | 聚合各工作台设备计数 |
| 3 | `Icons.biotech_outlined` | 试验 | Experiments | `GET /api/v1/experiments?page=1&size=1` → `total` |

#### 数字显示规则

| 场景 | 显示 |
|------|------|
| 正常值 (0-9999) | 原始数字，48px |
| 大值 (≥10000) | 千位分隔符 (如 "10,000")，36px |
| 零值 | "0"（**严禁 "-" 或 "—" 占位符**） |
| 加载中 | ShimmerBlock 48×48px |
| 错误 | ErrorView compact |

#### 数字计数动画

- **触发**: 数据加载完成后
- **效果**: 数字从 0 计数动画到目标值
- **时长**: 600ms
- **缓动**: ease-out (Curves.easeOutCubic)
- **大值优化**: 超过 1000 时，步长自适应加速

---

### 3.4 最近工作台 (Recent Workbenches)

#### 视觉规格

```
┌─────────────────────────────────────────────────────────┐
│  最近工作台                                    查看全部 → │
├─────────────────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │ 🏗️       │ │ 🏗️       │ │ 🏗️       │ │ 🏗️       │   │
│  │ 温度实验室 │ │ 振动测试台 │ │ 压力测试区 │ │ 湿度实验室 │   │
│  │ 5 台设备  │ │ 3 台设备  │ │ 4 台设备  │ │ 0 台设备  │   │
│  │ 3 天前   │ │ 1 周前   │ │ 2 周前   │ │ 1 个月前 │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
└─────────────────────────────────────────────────────────┘
```

#### 区域头部规格

| 属性 | 值 |
|------|-----|
| 布局 | Row, spaceBetween |
| 标题 | Title Large, On Surface |
| "查看全部" | Body Medium, Primary |
| "查看全部" 路由 | `/workbenches` |
| 下边距 | spaceMd (16px) |

#### 工作台卡片规格

| 属性 | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| 宽度 | 240px (固定) | 200px (固定) | 180px (固定) |
| 高度 | auto (min 100px) | auto | auto |
| 背景 | Surface | Surface | Surface |
| 边框 | 1px Outline Variant | 1px Outline Variant | 1px Outline Variant |
| 圆角 | radiusLarge (12px) | radiusLarge (12px) | radiusLarge (12px) |
| 内边距 | spaceMd (16px) | spaceMd (16px) | spaceSm (12px) |
| 图标 | build (24px) | build (24px) | build (20px) |
| 图标颜色 | On Surface Variant | On Surface Variant | On Surface Variant |
| 名称 | Title Medium | Title Medium | Body Large (14px) |
| 设备数 | Body Small | Body Small | Body Small |
| 更新时间 | Body Small, 60% opacity | Body Small, 60% | Body Small, 60% |
| 行间距 | spaceXs (4px) | spaceXs (4px) | spaceXs (4px) |

#### 卡片列表规格

| 属性 | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| 布局 | Row, 水平滚动 | Row, 水平滚动 | Row, 水平滚动 |
| 间距 | spaceMd (16px) | spaceMd (16px) | spaceSm (8px) |
| 最大显示 | 4 张 | 3 张 | 2-3 张 |
| 溢出 | 可水平滚动 | 可水平滚动 | 可水平滚动 |
| 滚动指示 | 无滚动条 (CSS overflow: hidden) | 同上 | 同上 |

#### 相对时间格式

| 时间差 | 中文 (zh) | 英文 (en) |
|--------|-----------|-----------|
| < 1 分钟 | 刚刚 | Just now |
| < 1 小时 | N 分钟前 | N minutes ago |
| < 24 小时 | N 小时前 | N hours ago |
| < 7 天 | N 天前 | N days ago |
| < 30 天 | N 周前 | N weeks ago |
| ≥ 30 天 | N 个月前 | N months ago |

> Hover 时 tooltip 显示精确时间: `yyyy-MM-dd HH:mm`

#### 空状态

```
┌─────────────────────────────────────────────────────────┐
│  最近工作台                                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│              [build_outlined] (40px)                    │
│                                                         │
│           还没有工作台                                   │
│      创建您的第一个工作台开始使用                         │
│                                                         │
│         ┌──────────────────┐                           │
│         │ 创建第一个工作台  │                           │
│         └──────────────────┘                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

使用 EmptyView compact 组件，CTA 按钮导航到 `/workbenches`。

---

## 4. 三态设计

### 4.1 骨架屏 (Loading State)

#### 整体骨架屏布局

```
Welcome Section:
  ├── ShimmerBlock: 200×32px (问候语)
  └── ShimmerBlock: 160×20px (日期, margin-top: 8px)

Quick Actions (4 cards):
  └── Each: 48×48px circle + 100×16px title + 80×14px subtitle

Stats Overview (3 cards):
  └── Each: 28×28px icon + 48×48px number + 60×16px label

Recent Workbenches (4 cards):
  └── Each: 240×100px card with 120×16px title + 80×14px line + 60×14px line
```

#### 各区域骨架屏规格

| 区域 | 骨架类型 | 数量 | 备注 |
|------|----------|------|------|
| 欢迎区域 | TextSkeleton | 2 行 | 问候语 + 日期 |
| 快捷操作 | CardSkeleton | 4 张 | 图标圆 + 标题 + 副标题 |
| 统计概览 | CardSkeleton | 3 张 | 图标 + 大数字 + 标签 |
| 最近工作台 | CardSkeleton | 4 张 | 标题 + 2 行描述 |

#### 骨架屏行为

- ** shimmer 动画**: 1.5s 循环, linear
- **完成过渡**: 骨架屏淡出 (200ms) → 内容淡入 (200ms)
- **区域独立**: 各区域骨架屏随各自数据就绪独立消失
- **prefers-reduced-motion**: 禁用 shimmer，显示静态占位色

### 4.2 空状态 (Empty State)

#### 适用场景

| 区域 | 空状态触发条件 | 展示内容 |
|------|---------------|----------|
| 统计概览 | total = 0 | 显示 "0"（不是空状态视图） |
| 最近工作台 | items = [] | EmptyView compact + CTA |

#### 最近工作台空状态规格

| 属性 | 值 |
|------|-----|
| 组件 | EmptyView (compact=true) |
| 图标 | `Icons.build_outlined` |
| 标题 | "还没有工作台" / "No workbenches yet" |
| 描述 | "创建您的第一个工作台开始使用" / "Create your first workbench to get started" |
| 操作按钮 | FilledButton, "创建第一个工作台" / "Create First Workbench" |
| 按钮路由 | `/workbenches` |
| 背景 | 透明（融入父容器） |

### 4.3 错误状态 (Error State)

#### 按区域独立容错

```
关键原则:
- 一个区域加载失败不影响其他区域正常渲染
- 每个失败区域有独立的 ErrorView + 重试按钮
- 错误消息使用用户可理解语言
- 严禁暴露技术细节 (如 "500 Internal Server Error")
```

#### 各区域错误规格

| 区域 | 错误标题 (zh) | 错误标题 (en) | 错误描述 (zh) | 错误描述 (en) | 重试行为 |
|------|--------------|---------------|---------------|---------------|----------|
| 统计概览 | 加载统计数据失败 | Failed to load statistics | 请检查网络后重试 | Please check your network and retry | 仅重新加载统计数据 |
| 最近工作台 | 加载工作台列表失败 | Failed to load workbenches | 请检查网络后重试 | Please check your network and retry | 仅重新加载工作台列表 |

#### 错误视图规格

| 属性 | 值 |
|------|-----|
| 组件 | ErrorView (compact=true) |
| 图标尺寸 | 32px |
| 标题 | Title Medium, On Surface |
| 描述 | Body Small, On Surface Variant |
| 重试按钮 | FilledButton, 高度 36px, "重试" / "Retry" |
| 背景 | 透明（融入父容器） |

#### 部分错误示例

```
Stats Overview (部分失败):
  ┌────────┐  ┌────────┐  ┌────────┐
  │   5    │  │   12   │  │ [Error]│  ← 试验统计加载失败
  │ 工作台  │  │  设备  │  │ 重试   │
  └────────┘  └────────┘  └────────┘
```

---

## 5. 响应式布局

### 5.1 断点定义

| 断点 | 名称 | 宽度范围 |
|------|------|----------|
| Mobile | 小屏 | < 600px |
| Tablet | 中屏 | 600px - 1200px |
| Desktop | 大屏 | > 1200px |

### 5.2 各断点布局

#### Desktop (> 1200px)

```
AppShell: NavigationRail extended (220px)
Content: max-width 1200px, centered, padding 32px

Welcome Section:
  - 左对齐
  - 问候语: Headline Small (24px)
  - 日期: Body Large (16px)

Quick Actions:
  - Grid: 4 列
  - Gap: 16px
  - 卡片: min-width 240px, padding 24px

Stats Overview:
  - Row: 3 列等分
  - Gap: 16px
  - 卡片: min-height 120px, padding 24px
  - 数字: 48px

Recent Workbenches:
  - 水平滚动 Row
  - 卡片: 240px width
  - 最多显示 4 张
  - Gap: 16px
```

#### Tablet (600-1200px)

```
AppShell: NavigationRail collapsed (72px) or toggle extended
Content: full width, padding 24px

Welcome Section:
  - 左对齐
  - 问候语: Headline Small (22px)
  - 日期: Body Large (16px)

Quick Actions:
  - Grid: 2 列
  - Gap: 16px
  - 卡片: padding 20px

Stats Overview:
  - Row: 3 列 (或 2+1 wrap)
  - Gap: 16px
  - 卡片: min-height 110px, padding 20px
  - 数字: 42px

Recent Workbenches:
  - 水平滚动 Row
  - 卡片: 200px width
  - 最多显示 3 张
  - Gap: 16px
```

#### Mobile (< 600px)

```
AppShell: BottomNavigationBar (6 items)
Content: full width, padding 16px

Welcome Section:
  - 左对齐
  - 问候语: Headline Small (20px)
  - 日期: Body Medium (14px)

Quick Actions:
  - Grid: 2 列
  - Gap: 8px
  - 卡片: padding 16px, compact
  - 图标: 24px, 容器 40×40px

Stats Overview:
  - Flex wrap, 3 列 (min-width 100px)
  - Gap: 8px
  - 卡片: min-height 100px, padding 16px
  - 数字: 36px

Recent Workbenches:
  - 水平滚动 Row
  - 卡片: 180px width
  - 最多显示 2-3 张
  - Gap: 8px
```

### 5.3 响应式速查表

| 元素 | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| 内容最大宽度 | 1200px | 100% | 100% |
| 水平内边距 | 32px | 24px | 16px |
| 快捷操作列数 | 4 | 2 | 2 |
| 快捷操作卡片内边距 | 24px | 20px | 16px |
| 统计卡片数字字号 | 48px | 42px | 36px |
| 最近工作台卡片宽 | 240px | 200px | 180px |
| 最近工作台间距 | 16px | 16px | 8px |

---

## 6. 主题适配

### 6.1 Light Theme

| 元素 | Light 颜色 |
|------|-----------|
| 页面背景 | Background (#FDFCFF) |
| 卡片背景 | Surface (#FFFFFF) |
| 统计卡片背景 | Surface Container Low (#F1F4F9) |
| 图标容器背景 | Primary Container (#D1E4FF) |
| 主色 | Primary (#1976D2) |
| 数字颜色 | Primary (#1976D2) |
| 文字颜色 | On Surface (#1A1C1E) |
| 次要文字 | On Surface Variant (#44474E) |
| 边框 | Outline Variant (#C4C6D0) |
| 错误 | Error (#BA1A1A) |

### 6.2 Dark Theme

| 元素 | Dark 颜色 |
|------|-----------|
| 页面背景 | Background (#1A1C1E) |
| 卡片背景 | Surface (#1A1C1E) |
| 统计卡片背景 | Surface Container Low (#1D2023) |
| 图标容器背景 | Primary Container (#004A7F) |
| 主色 | Primary (#90CAF9) |
| 数字颜色 | Primary (#90CAF9) |
| 文字颜色 | On Surface (#E3E2E6) |
| 次要文字 | On Surface Variant (#C4C6CF) |
| 边框 | Outline Variant (#44474E) |
| 错误 | Error (#FFB4AB) |

### 6.3 主题切换行为

- **即时切换**: 主题切换后所有颜色即时更新
- **无闪烁**: 使用 Flutter Theme.of(context) 自动传播
- **图标适配**: 所有图标使用 colorScheme 颜色，自动跟随主题

---

## 7. 无障碍设计

### 7.1 屏幕阅读器

| 元素 | 语义标签 |
|------|----------|
| 欢迎区域 | "欢迎区域，{greeting}，{username}，{date}" |
| 快捷卡片 | "{title}，{subtitle}，点击进入" |
| 统计卡片 | "{label}，数量 {number}" |
| 最近工作台卡片 | "{name}，{device_count}，最近活动 {updated_at}" |
| "查看全部" | "查看全部工作台" |
| 重试按钮 | "重试加载{区域名称}" |

### 7.2 键盘导航

| 元素 | 键盘支持 |
|------|----------|
| 快捷卡片 | Tab 聚焦, Enter/Space 激活 |
| 统计区域 | 非交互，跳过 Tab |
| 最近工作台卡片 | Tab 聚焦, Enter/Space 激活 |
| "查看全部" | Tab 聚焦, Enter 激活 |
| 重试按钮 | Tab 聚焦, Enter 激活 |

### 7.3 触摸目标

- 所有交互卡片: 最小 48×48dp 触摸目标
- 快捷卡片: 整张卡片可点击
- 最近工作台卡片: 整张卡片可点击
- 按钮: 最小 120×40dp

### 7.4 对比度

- 文字 On Surface: ≥ 4.5:1
- 大文字 (数字 48px): ≥ 3:1
- 图标 On Surface Variant: ≥ 3:1
- 边框 Outline Variant: ≥ 3:1

### 7.5 动效减弱

- `prefers-reduced-motion`: 禁用骨架屏 shimmer，显示静态占位
- 数字计数动画: 禁用，直接显示目标值
- 淡入淡出: 禁用，直接切换

---

## 8. 动画与动效

### 8.1 页面加载动画

```
Sequence:
  1. 骨架屏立即显示 (0ms)
  2. 各区域数据就绪后独立切换:
     - 骨架屏淡出 (200ms, ease-out)
     - 内容淡入 (200ms, ease-in)
  3. 数字计数动画 (600ms, ease-out, 仅 Desktop/Tablet)
```

### 8.2 微交互

| 交互 | 动画 | 时长 | 缓动 |
|------|------|------|------|
| 卡片 Hover | Elevation 1→2 | 150ms | ease-out |
| 卡片 Pressed | Scale 1.0→0.98 | 100ms | ease-in-out |
| 卡片 Focus | Outline 出现 | 100ms | ease-out |
| 数字计数 | 0→目标值 | 600ms | ease-out-cubic |
| 骨架屏 shimmer | 水平扫过 | 1.5s 循环 | linear |
| 内容淡入 | Opacity 0→1 | 200ms | ease-in |
| 骨架屏淡出 | Opacity 1→0 | 200ms | ease-out |

### 8.3 数字计数动画规格

```dart
// 伪代码
AnimatedCount(
  target: statValue,
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
  builder: (context, value, child) {
    return Text(
      NumberFormat('#,###').format(value),
      style: TextStyle(
        fontSize: value >= 10000 ? 36 : 48,
        fontWeight: FontWeight.w300,
        color: colorScheme.primary,
      ),
    );
  },
)
```

---

## 9. 组件清单

### 9.1 新增组件

| 组件名 | 用途 | 文件建议 |
|--------|------|----------|
| `WelcomeSection` | 欢迎区域（问候语 + 日期） | `pages/dashboard/widgets/welcome_section.dart` |
| `QuickActionCard` | 快捷操作卡片 | `pages/dashboard/widgets/quick_action_card.dart` |
| `QuickActionsGrid` | 快捷操作网格布局 | `pages/dashboard/widgets/quick_actions_grid.dart` |
| `StatCard` | 统计数字卡片 | `pages/dashboard/widgets/stat_card.dart` |
| `StatsOverview` | 统计概览行 | `pages/dashboard/widgets/stats_overview.dart` |
| `RecentWorkbenchCard` | 最近工作台卡片 | `pages/dashboard/widgets/recent_workbench_card.dart` |
| `RecentWorkbenchesSection` | 最近工作台区域 | `pages/dashboard/widgets/recent_workbenches_section.dart` |
| `DashboardSkeleton` | 仪表盘骨架屏 | `pages/dashboard/widgets/dashboard_skeleton.dart` |
| `GreetingText` | 时间段问候语 | `pages/dashboard/widgets/greeting_text.dart` |

### 9.2 复用组件

| 组件 | 来源 | 用途 |
|------|------|------|
| `Skeleton` | `widgets/skeleton.dart` | 加载占位 |
| `ErrorView` | `widgets/error_view.dart` | 错误展示 |
| `EmptyView` | `widgets/empty_view.dart` | 空状态引导 |
| `AsyncValueWidget` | `widgets/async_value_widget.dart` | 三态分发 |

### 9.3 数据模型

```dart
// Dashboard 页面状态
class DashboardState {
  final AsyncValue<DashboardData> data;
  final AsyncValue<List<WorkbenchSummary>> recentWorkbenches;
  
  const DashboardState({
    required this.data,
    required this.recentWorkbenches,
  });
}

class DashboardData {
  final String? username;
  final String? email;
  final int workbenchCount;
  final int deviceCount;
  final int experimentCount;
}

class WorkbenchSummary {
  final String id;
  final String name;
  final int? deviceCount;
  final DateTime updatedAt;
}
```

---

## 10. 设计 QA 检查项

### 10.1 视觉检查

- [ ] 所有颜色与 Design Token 完全一致
- [ ] Light/Dark 主题切换颜色正确
- [ ] 各区域间距符合 8px 网格系统
- [ ] 圆角一致（卡片 radiusLarge 12px）
- [ ] 阴影层级正确（默认 elevation 1, Hover elevation 2）
- [ ] 数字字体大小正确（48px/36px 根据值大小）
- [ ] 图标颜色正确（快捷卡片 Primary, 统计卡片 On Surface Variant）

### 10.2 交互检查

- [ ] 快捷卡片 Hover 有 elevation 提升
- [ ] 快捷卡片 Pressed 有 scale 动画
- [ ] 快捷卡片点击正确导航到对应页面
- [ ] 最近工作台卡片 Hover 有左边框高亮
- [ ] 数字计数动画流畅
- [ ] 骨架屏 shimmer 动画不卡顿
- [ ] 重试按钮点击后进入加载状态

### 10.3 三态检查

- [ ] 骨架屏包含所有区域占位
- [ ] 骨架屏完成后内容淡入
- [ ] 零值显示 "0" 而非 "-"
- [ ] 空状态显示 EmptyView + CTA
- [ ] 错误状态显示 ErrorView + 重试
- [ ] 区域独立容错：一个区域错误不影响其他区域
- [ ] 错误消息使用用户语言（非技术细节）

### 10.4 响应式检查

- [ ] Desktop (>1200px): 4 列快捷操作, 3 列统计, 4 张工作台卡片
- [ ] Tablet (600-1200px): 2 列快捷操作, 3 列统计, 3 张工作台卡片
- [ ] Mobile (<600px): 2 列快捷操作, flex 统计, 水平滚动工作台
- [ ] 所有内容无水平滚动（除工作台区域）
- [ ] 触摸目标 ≥ 48×48dp

### 10.5 主题检查

- [ ] Light 主题主色 #1976D2
- [ ] Dark 主题主色 #90CAF9
- [ ] Dark 主题卡片背景正确
- [ ] Dark 主题文字可读
- [ ] 主题切换无闪烁

### 10.6 多语言检查

- [ ] 中文问候语正确（早上好/下午好/晚上好）
- [ ] 英文问候语正确（Good morning/afternoon/evening）
- [ ] 日期格式跟随语言设置
- [ ] 所有 UI 文本可翻译
- [ ] 语言切换即时生效

### 10.7 无障碍检查

- [ ] 屏幕阅读器正确朗读各区域
- [ ] Tab 键可导航所有交互元素
- [ ] Enter/Space 可激活卡片和按钮
- [ ] 颜色对比度符合 WCAG AA
- [ ] prefers-reduced-motion 下禁用动画

---

## 附录

### A. 图标清单

| 图标 | 用途 | 尺寸 | 颜色 |
|------|------|------|------|
| biotech | 快捷卡片-试验控制台 | 28px | Primary |
| science | 快捷卡片-试验方法 | 28px | Primary |
| build | 快捷卡片-工作台管理 | 28px | Primary |
| analytics | 快捷卡片-数据分析 | 28px | Primary |
| build_outlined | 统计卡片-工作台 | 28px | On Surface Variant |
| memory_outlined | 统计卡片-设备 | 28px | On Surface Variant |
| biotech_outlined | 统计卡片-试验 | 28px | On Surface Variant |
| build_outlined | 最近工作台卡片 | 24px | On Surface Variant |
| error_outline_outlined | ErrorView 图标 | 32px | On Surface Variant |
| folder_open_outlined | EmptyView 图标 | 40px | On Surface Variant |
| arrow_forward | 查看全部箭头 | 16px | Primary |

### B. 动画参数汇总

| 动画 | 时长 | 缓动 | 组件 |
|------|------|------|------|
| Skeleton shimmer | 1.5s 循环 | linear | Skeleton |
| 内容淡入 | 200ms | ease-in | Dashboard |
| 骨架屏淡出 | 200ms | ease-out | Dashboard |
| 卡片 Hover elevation | 150ms | ease-out | QuickActionCard |
| 卡片 Pressed scale | 100ms | ease-in-out | QuickActionCard |
| 数字计数 | 600ms | ease-out-cubic | StatCard |
| 语言切换 | 即时 | — | WelcomeSection |

### C. 后端 API 依赖

| 数据 | API | 字段 |
|------|-----|------|
| 用户名 | `GET /api/v1/auth/me` | `username` |
| 工作台总数 | `GET /api/v1/workbenches?page=1&size=1` | `total` |
| 最近工作台 | `GET /api/v1/workbenches?page=1&size=4` | `items[0..3]` |
| 试验总数 | `GET /api/v1/experiments?page=1&size=1` | `total` |
| 设备总数 | 各工作台设备聚合 | 需前端累加 |

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。
