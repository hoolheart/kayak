# Figma 原型 - Dashboard 首页 (Dashboard Page)

**Figma 文件**: `kayak_r1.fig` > Page: `Dashboard`  
**设计师**: sw-anna  
**日期**: 2026-05-03  
**状态**: 设计完成

---

## 1. 设计目标

Dashboard 是用户登录后的第一屏，提供研究活动的快速概览。设计强调清晰的信息分层：欢迎问候 → 快捷操作 → 最近工作台 → 统计概览，从上到下按重要程度递减排列。

---

## 2. Frame 结构

### 2.1 主 Frame

```
Frame: "Dashboard - Light"
Width: 1440px
Height: 1080px
Background: Surface #FFFFFF
Layout: Auto Layout (Column) with scroll
```

### 2.2 子 Frames

```
Dashboard
├── App Bar (1440 × 64)
│   ├── Menu Toggle Icon (24px)
│   ├── Page Title "首页" (Title Large)
│   ├── Spacer
│   ├── Notification Button (badge: 3)
│   └── User Avatar (32px circle)
├── Content Area (padding: 24px)
│   ├── Welcome Section (flex column)
│   │   ├── Greeting "早上好，用户名" (Title Large)
│   │   ├── Subtitle "这里是您今天的研究概览" (Body Large)
│   │   └── Time Display "14:30:25 · 2024-01-15 星期一" (Body Medium)
│   ├── Quick Actions (spacing: 16px)
│   │   ├── Card: 工作台 (workspace_premium)
│   │   ├── Card: 试验 (science)
│   │   ├── Card: 方法 (description)
│   │   └── Card: 数据文件 (folder)
│   ├── Recent Workbenches (spacing: 16px)
│   │   ├── Section Header: "最近工作台" + "查看全部 →"
│   │   ├── Card: 工作台 A
│   │   ├── Card: 工作台 B
│   │   ├── Card: 工作台 C
│   │   └── Card: 工作台 D
│   └── Statistics (spacing: 16px)
│       ├── Card: 工作台总数
│       ├── Card: 设备总数
│       ├── Card: 试验总数
│       └── Card: 数据文件
```

---

## 3. 组件规格

### 3.1 App Bar

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 64px | 64px |
| Fills | Primary #1976D2 | Surface Container High #3D3D3D |
| Shadow | Elevation 2 | Elevation 1 |
| Padding | 0 16px | 0 16px |
| Title | "首页", Title Large, #FFFFFF | #F5F5F5 |
| Icons | 24px, #FFFFFF | #F5F5F5 |

### 3.2 Welcome Section

| 属性 | 值 |
|------|-----|
| Width | 100% (fill) |
| Padding | 24px |
| Corner Radius | 16px |
| Fills | Surface Container Lowest |
| Stroke | None |
| Greeting Font | Title Large (22pt, 500) |
| Greeting Color | On Surface |
| Subtitle Font | Body Large (16pt, 400) |
| Subtitle Color | On Surface Variant |
| Time Display Font | Body Medium (14pt, 400) |
| Time Display Color | On Surface Variant |
| Time Display Alignment | Right |

### 3.3 Quick Action Card

| 属性 | 值 |
|------|-----|
| Width | 200px (fixed) |
| Height | 120px |
| Padding | 20px |
| Corner Radius | 16px |
| Fills | Surface |
| Stroke | 1px Outline Variant |
| Shadow | None |
| Icon Container | 48×48px, Primary Container, 12px radius |
| Icon | 24px, On Primary Container |
| Title | Title Medium (16pt, 500), On Surface |
| Description | Body Small (12pt, 400), On Surface Variant |
| Hover State | Stroke → Primary, Shadow Elevation 2, Y: -2px |

### 3.4 Recent Workbench Card

| 属性 | 值 |
|------|-----|
| Width | Fill (flex), min 260px |
| Height | 140px |
| Padding | 16px |
| Corner Radius | 12px |
| Fills | Surface |
| Stroke | 1px Outline Variant |
| Icon Container | 40×40px, Primary Container, 10px radius |
| Icon | 20px, On Primary Container |
| Title | Title Medium (16pt, 500), On Surface |
| Device Count | Body Small (12pt, 400), On Surface Variant |
| Status Chip | Bottom-left corner |

### 3.5 Statistics Card

| 属性 | 值 |
|------|-----|
| Width | Fill (flex) |
| Height | 88px |
| Padding | 20px |
| Corner Radius | 12px |
| Fills | Surface Container Low |
| Label | Label Medium (12pt, 500), On Surface Variant |
| Value | Headline Small (24pt, 400), On Surface |
| Growth Info | Body Small (12pt, 400), Variant |

---

## 4. 空状态设计

```
Component: Empty Workbenches State
├── Icon: workspace_premium, 48px, On Surface Variant
├── Title: "还没有工作台" (Title Medium)
├── Description: "创建第一个工作台开始管理您的设备" (Body Medium)
└── Button: Primary "创建工作台"
```

---

## 5. 原型交互

| 起点 | 交互 | 终点 | 动画 |
|------|------|------|------|
| Quick Action Card | Tap | Corresponding page | Push → 300ms |
| Workbench Card | Tap | Workbench Detail | Push → 300ms |
| "查看全部 →" | Tap | Workbench List | Push → 300ms |
| Notification Icon | Tap | Notification Panel | Dropdown, 150ms |
| User Avatar | Tap | User Menu | Dropdown, 150ms |
| Menu Toggle | Tap | Sidebar toggle | Expand/Collapse 200ms |

---

## 6. 主题变体

### Light Theme
- Background: #FFFFFF
- Welcome Section bg: #FAFAFA
- Quick Action Card bg: #FFFFFF
- Statistics Card bg: #F5F5F5

### Dark Theme
- Background: #121212
- Welcome Section bg: #0A0A0A
- Quick Action Card bg: #1E1E1E
- Statistics Card bg: #2D2D2D
- Primary: #90CAF9

---

## 7. 设计笔记

- 欢迎区域使用 Surface Container Lowest 背景与白色页面区分层次
- 问候语根据系统时间动态切换：早上好 (5-12)、下午好 (12-18)、晚上好 (18-5)
- 快捷操作卡片采用固定宽度 200px，确保每行4个对齐
- 最近工作台区使用flex布局自适应列数
- 统计数字加载时使用 500ms ease-out 动画递增
