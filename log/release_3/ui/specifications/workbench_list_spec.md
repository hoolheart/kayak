# TASK-013: 工作台列表页 UI 设计规范

> **路由**: `/workbenches`  
> **依赖**: TASK-007 (可复用组件库)、TASK-012 (工作台 Service)  
> **设计师**: sw-anna  
> **日期**: 2026-05-31  
> **状态**: 设计稿完成

---

## 1. 页面布局

### 1.1 整体结构

```
WorkbenchListPage
├── AppBar (64px)
│   ├── Title: "工作台" (Title Large)
│   └── Primary Button: "+ 新建" (高度 40px)
├── Search Bar (56px)
│   ├── Search Input (fill 60% width)
│   └── Search Icon (20px, On Surface Variant)
├── Content Area (padding: spaceMd 16px)
│   ├── [Loading] → Skeleton Card Grid (3-4 列占位)
│   ├── [Error]   → ErrorView + 重试按钮
│   ├── [Empty]   → EmptyView (图标 + 引导 + 创建按钮)
│   └── [Data]    → Workbench Card Grid
└── Pagination Bar (48px, optional)
    └── "共 N 个工作台" + Load More
```

### 1.2 布局参数

| 属性 | 值 |
|------|-----|
| Page Background | Background color token |
| Content Padding | spaceMd (16px) |
| Content Max Width | 无限制（流体布局） |
| Grid Gap | spaceMd (16px) |

---

## 2. 组件规格

### 2.1 工作台卡片 (WorkbenchCard)

| 属性 | 值 |
|------|-----|
| Min Width | 280px |
| Height | Auto (min 180px) |
| Padding | spaceMd (16px) |
| Corner Radius | radiusLarge (12px) |
| Fills | Surface color |
| Stroke | 1px Outline Variant |
| Layout | Column, gap: spaceSm (8px) |

**卡片内容**（从上到下）：

| 元素 | 规格 |
|------|------|
| 状态标签 | Chip 组件，右上角对齐 |
| 名称 | Title Medium (16px, 500), On Surface, 单行省略 |
| 描述 | Body Small (12px, 400), On Surface Variant, 2 行省略 |
| 分隔线 | 1px Outline Variant, margin: spaceSm 0 |
| 底部行 | Row: 创建时间 (Body Small, On Surface Variant) + 操作按钮 |
| 操作按钮 | IconButton ×2 (编辑 `edit`, 删除 `delete`), 32px |

**卡片状态**：

| 状态 | 视觉 |
|------|------|
| Default | Surface fill, 1px Outline Variant |
| Hover | Elevation 2, Stroke → Primary color, translateY -2px |
| Pressed | Elevation 1, Scale 0.98 |
| Selected | Primary Container fill (创建后高亮 2 秒) |

### 2.2 搜索栏

| 属性 | 值 |
|------|-----|
| Height | 56px |
| Search Input Width | 100% (mobile) / 60% (desktop) |
| Input Fill | Surface Variant at 50% |
| Placeholder | "搜索工作台..." (l10n) |
| Icon | `Icons.search`, 20px |
| Debounce | 300ms |

### 2.3 空状态 (Empty State)

使用 TASK-007 EmptyView 组件：

| 属性 | 值 |
|------|-----|
| Icon | `Icons.folder_open_outlined`, 48px |
| Title | "您还没有工作台" (l10n) |
| Description | "点击下方按钮创建您的第一个工作台" |
| Action | Filled Button "创建第一个工作台" |

### 2.4 骨架屏 (Loading)

使用 TASK-007 Skeleton 组件：

- **CardSkeleton**: 网格布局，显示与目标卡片相同数量的占位
- 桌面 4 列 → 4 个骨架卡
- 平板 2 列 → 2 个骨架卡
- 手机 1 列 → 3 个骨架卡（纵向）

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
```

### 3.2 卡片交互

| 操作 | 触发 | 反馈 |
|------|------|------|
| 点击卡片 | 导航到详情页 `/workbenches/{id}` | 页面 Push 动画 300ms |
| 点击编辑 | 弹出编辑对话框 | Dialog 200ms |
| 点击删除 | 弹出确认对话框 | ConfirmDialog |
| 搜索输入 | 300ms debounce 后调用后端 | 列表实时过滤 |

### 3.3 创建/编辑对话框

```
Dialog: "创建工作台" / "编辑工作台"
Width: 480px (desktop) / 100% (mobile bottom sheet)
├── Title: "创建工作台" (Title Medium)
├── Close Button: IconButton (close)
├── Content (padding: spaceMd)
│   ├── 名称 * (TextField)
│   │   └── Label: "名称", Hint: "请输入工作台名称"
│   └── 描述 (TextField, multiline, maxLines: 3)
│       └── Label: "描述（选填）"
└── Actions (padding: spaceMd, right-aligned)
    ├── TextButton "取消"
    └── FilledButton "创建" (名称非空时启用)
```

**表单验证**：
- 名称：必填，最长 255 字符
- 描述：选填
- 提交时：名称空 → 显示错误提示 "请输入工作台名称"

### 3.4 删除确认

使用 TASK-007 ConfirmDialog（危险变体）：

```
Title: "删除工作台？"
Description: "确定要删除工作台「{name}」吗？此操作不可撤销，工作台下所有设备和数据将被永久删除。"
Buttons: [取消] [确认删除] (Error color)
```

---

## 4. 响应式适配

### 4.1 断点定义

| 断点 | 宽度 | 网格列数 | 卡片宽度 |
|------|------|----------|----------|
| Mobile | < 600px | 1 列 | 100% |
| Tablet | 600-1024px | 2 列 | calc(50% - 8px) |
| Desktop Small | 1024-1280px | 3 列 | calc(33.33% - 11px) |
| Desktop Large | > 1280px | 4 列 | calc(25% - 12px) |

### 4.2 移动端适配

- AppBar: "新建" 按钮简化为 IconButton (`Icons.add`)
- 搜索栏: 全宽，去掉左右 margin
- 卡片: 全宽单列，减少 padding 至 spaceSm (12px)
- 对话框: 转为底部 Sheet (BottomSheet)，高度自适应
- 骨架屏: 单列，显示 3 个占位

### 4.3 平板适配

- 网格 2 列
- 卡片保持标准尺寸
- 对话框居中，宽度 480px

---

## 5. 主题适配

| 元素 | Light Theme | Dark Theme |
|------|------------|------------|
| Page Background | Background (#FDFCFF) | Background (#1A1C1E) |
| Card Background | Surface (#FFFFFF) | Surface (#1A1C1E) |
| Card Stroke | Outline Variant | Outline Variant |
| Card Hover Shadow | rgba(0,0,0,0.08) | rgba(0,0,0,0.32) |
| Search Fill | Surface Variant 50% | Surface Variant 50% |
| Empty Icon | On Surface Variant 60% | On Surface Variant 60% |

---

## 6. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 200ms | ease-out | Fade + Slide |
| 卡片 Hover | 150ms | ease-out | Elevation + translateY |
| 卡片 Pressed | 100ms | ease-in-out | Scale |
| Dialog 进入 | 200ms | ease-out | Scale/Fade (桌面), Slide (移动) |
| Dialog 离开 | 150ms | ease-in | 反向 |
| Skeleton shimmer | 1.5s | linear | 循环 |
| 列表刷新 | 300ms | ease-in-out | 新卡片 Fade In |

---

## 7. 设计 QA 检查项

- [ ] 三态完整：Loading (Skeleton) / Error (ErrorView) / Empty (EmptyView) / Data (Grid)
- [ ] 搜索实时过滤，300ms debounce
- [ ] 卡片 Hover 效果：Elevation + Stroke 变色 + translateY
- [ ] 创建后新卡片高亮 2 秒 (Primary Container)
- [ ] 删除二次确认对话框
- [ ] 响应式：1/2/3/4 列自适应
- [ ] Light/Dark 主题颜色正确
- [ ] 移动端对话框转为 BottomSheet
- [ ] 所有文本通过 l10n (无硬编码)
- [ ] 按钮 loading 状态禁用输入

---

**文档结束**
