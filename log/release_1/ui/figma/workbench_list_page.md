# Figma 原型 - 工作台列表页 (Workbench List Page)

**Figma 文件**: `kayak_r1.fig` > Page: `Workbench List`  
**设计师**: sw-anna  
**日期**: 2026-05-03  
**状态**: 设计完成

---

## 1. 设计目标

工作台列表页展示用户所有工作台，支持网格和列表双视图切换。设计重点是不同视图下的信息呈现差异，以及清晰的空状态、搜索无结果状态设计。

---

## 2. Frame 结构

### 2.1 主 Frame

```
Frame: "Workbench List - Light"
Width: 1440px
Height: 1080px
Background: Surface #FFFFFF
```

### 2.2 视图子 Frames

```
Workbench List
├── App Bar (1440 × 64)
│   ├── Back Button (arrow_back, 24px)
│   ├── Title "工作台" (Title Large)
│   ├── Spacer
│   ├── Grid View Toggle (⊞, selected)
│   ├── List View Toggle (≡)
│   └── Add Button (+) (Primary)
├── Content Area (padding: 24px)
│   ├── Search & Filter Bar
│   │   ├── Search Input (Filled)
│   │   ├── Filter Dropdown "状态筛选"
│   │   └── Sort Dropdown "排序方式"
│   ├── [Grid View] Grid Container (4 columns, gap: 16px)
│   │   ├── Workbench Card 1
│   │   ├── Workbench Card 2
│   │   ├── Workbench Card 3
│   │   └── Workbench Card 4
│   ├── [List View] Data Table (hidden in grid)
│   │   ├── Table Header
│   │   │   ├── 图标 (48px)
│   │   │   ├── 名称 (200px)
│   │   │   ├── 描述 (240px)
│   │   │   ├── 设备数 (80px)
│   │   │   ├── 状态 (100px)
│   │   │   ├── 创建时间 (100px)
│   │   │   └── 操作 (80px)
│   │   └── Table Rows (× N)
│   └── Create Button Area
│       └── Primary Button "+ 创建工作台" (fixed bottom)
│
├── Empty State (conditional)
└── No Results State (conditional)
```

---

## 3. 组件规格

### 3.1 Search & Filter Bar

| 属性 | 值 |
|------|-----|
| Container Height | 56px |
| Search Input Width | 60% (flex) |
| Search Input Fills | Surface Container Highest, 50% opacity |
| Search Icon | search, 20px, On Surface Variant |
| Placeholder | "搜索工作台..." |
| Filter Button | Outlined, 36px height, "筛选 ▼" |
| Sort Button | Outlined, 36px height, "排序 ▼" |
| Bar Bottom Margin | 20px |

### 3.2 Grid View Workbench Card

| 属性 | 值 |
|------|-----|
| Width | 280px (min) |
| Height | 200px |
| Padding | 20px |
| Corner Radius | 16px |
| Fills | Surface |
| Stroke | 1px Outline Variant |
| Layout | Auto Layout (Column, gap: 12px) |
| **Content** | |
| Icon Container | 56×56px, Primary Container, 16px radius |
| Icon | workspace_premium, 28px, On Primary Container |
| Title | Title Medium (16pt, 500), On Surface |
| Description | Body Small (12pt, 400), On Surface Variant, 2-line clamp |
| Bottom Row | |
| Device Count + Chip | Label Medium, On Surface Variant |
| Edit Button | IconButton, edit, 32px |
| Delete Button | IconButton, delete, 32px, Error color |
| **Hover** | Stroke → Primary, Elevation 2, Y: -2px |

### 3.3 List View Table Header

| 属性 | 值 |
|------|-----|
| Height | 48px |
| Fills | Surface Container Low |
| Font | Label Medium (12pt, 500), On Surface Variant |
| Border Bottom | 1px Outline Variant |
| Columns: | 图标 48px | 名称 200px | 描述 240px | 设备数 80px | 状态 100px | 时间 100px | 操作 80px |

### 3.4 List View Table Row

| 属性 | 值 |
|------|-----|
| Height | 56px |
| Fills | Surface (odd), Surface Container Lowest (even) |
| Border Bottom | 1px Outline Variant |
| **Content** | |
| Icon | 36×36px circle, Primary Container |
| Name | Title Medium (16pt, 500), On Surface |
| Description | Body Small (12pt, 400), On Surface Variant, single-line |
| Device Count | Body Medium (14pt), On Surface Variant |
| Status | Chip component |
| Time | Body Small, On Surface Variant |
| Actions | IconButton edit + delete, 32px |
| **Hover** | Background → Surface Container Lowest (4% opacity) |

---

## 4. 状态设计

### 4.1 空状态 (Empty State)

```
Component: "Empty Workbench"
├── Icon: workspace_premium, 64px, On Surface Variant
├── Title: "暂无工作台" (Title Medium, On Surface)
├── Description: "点击下方按钮创建您的工作台" (Body Medium, On Surface Variant)
└── Button: Primary "创建工作台"
```

### 4.2 搜索无结果 (No Search Results)

```
Component: "No Search Results"
├── Icon: search_off, 64px, On Surface Variant
├── Title: "未找到匹配的工作台" (Title Medium, On Surface)
├── Description: "尝试使用不同的关键词搜索" (Body Medium, On Surface Variant)
└── Button: Text "清除搜索"
```

### 4.3 加载状态 (Loading)

```
Component: "Loading Workbenches"
├── Skeleton Cards (× 4)
│   ├── Skeleton circle (56×56)
│   ├── Skeleton text (title, 160px)
│   ├── Skeleton text (description, 200px)
│   └── Skeleton text (count, 80px)
```

---

## 5. 原型交互

| 起点 | 交互 | 终点 | 动画 |
|------|------|------|------|
| Card / Row | Tap | Workbench Detail Page | Push → 300ms |
| Grid Toggle | Tap | Switch to Grid View | Instant switch |
| List Toggle | Tap | Switch to List View | Instant switch |
| Edit Icon | Tap | Edit Workbench Dialog | Dialog 200ms |
| Delete Icon | Tap | Confirmation Dialog | Dialog 200ms |
| + Button (App Bar) | Tap | Create Workbench Dialog | Dialog 200ms |
| 搜索输入 | Typing | Filter list (300ms debounce) | Content filter |
| 筛选按钮 | Tap | Filter Dropdown | Dropdown 150ms |
| 排序按钮 | Tap | Sort Dropdown | Dropdown 150ms |
| Create Button (bottom) | Tap | Create Workbench Dialog | Dialog 200ms |

---

## 6. 对话框设计

### 6.1 创建工作台对话框

```
Dialog: "Create Workbench"
Width: 480px
├── Title: "创建工作台"
├── Close Button: close, 24px
├── Content:
│   ├── 名称 * (Text Input)
│   └── 描述 (Text Input, multiline)
└── Actions:
    ├── Text Button "取消"
    └── Primary Button "创建"
```

### 6.2 编辑工作台对话框

```
Dialog: "Edit Workbench"
Width: 480px
├── Title: "编辑工作台"
├── Content:
│   ├── 名称 * (Text Input, pre-filled)
│   └── 描述 (Text Input, pre-filled)
└── Actions:
    ├── Text Button "取消"
    └── Primary Button "保存"
```

### 6.3 删除确认对话框

```
Dialog: "Delete Workbench"
Width: 400px
├── Icon: warning, 48px, Warning color
├── Title: "确认删除"
├── Content: "确定要删除工作台「{name}」吗？此操作不可撤销，工作台下所有设备和数据将被永久删除。"
└── Actions:
    ├── Text Button "取消"
    └── Primary Button "确认删除" (Error color fill)
```

---

## 7. 主题变体

| 元素 | Light Theme | Dark Theme |
|------|------------|------------|
| Page Background | #FFFFFF | #121212 |
| Card Background | #FFFFFF | #1E1E1E |
| Card Stroke | #EEEEEE | #333333 |
| Search Fill | #EEEEEE (50%) | #2D2D2D |
| Table Header | #F5F5F5 | #2D2D2D |
| Table Row Even | #FAFAFA | #1A1A1A |
| Card Hover Shadow | rgba(0,0,0,0.08) | rgba(0,0,0,0.32) |

---

## 8. 设计笔记

- 网格卡片默认 4 列布局（≥1280px），响应式缩减
- 卡片悬停时 translateY -2px 配合阴影提升创造 "浮起" 效果
- 列表视图行交替背景色提高可读性
- 删除按钮使用 Error 颜色警示
- App Bar 的创建按钮使用 Primary (+) 样式，底部也有创建按钮方便长列表滚动后操作
