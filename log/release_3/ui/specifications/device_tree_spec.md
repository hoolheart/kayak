# TASK-016: 设备树组件 — UI 设计规范

> **路由**: `/workbenches/{id}` (工作台详情页左侧面板)  
> **依赖**: TASK-007 (可复用组件库)  
> **设计师**: sw-anna  
> **日期**: 2026-05-31

---

## 1. 页面布局

### 1.1 整体结构

```
WorkbenchDetailPage
├── AppBar (64px)
│   ├── Back Button + Title
│   └── Actions
├── Main Content (Row)
│   ├── DeviceTreePanel (320px, 可拖拽调整)
│   │   ├── Panel Header (56px)
│   │   │   ├── Title: "设备" + Count Chip
│   │   │   └── IconButton "+" 添加设备
│   │   ├── Tree Content (scrollable)
│   │   │   └── TreeNode × N
│   │   │       ├── [Expand Icon] [Protocol Icon] [Status Dot] [Name]
│   │   │       └── Children (indented 24px/level)
│   │   └── Resize Handle (4px)
│   └── DeviceDetailPanel (flex: 1)
└── ...
```

### 1.2 布局参数

| 属性 | 值 |
|------|-----|
| Panel Width | 320px（默认），min 240px，max 480px |
| Panel Background | Surface |
| Panel Border | 1px Outline Variant，右侧 |
| Tree Node Height | 40px |
| Indentation | 24px per level |

---

## 2. 组件规格

### 2.1 树节点 (DeviceTreeNode)

| 属性 | 值 |
|------|-----|
| Height | 40px |
| Padding | 水平 spaceMd (16px) |
| Layout | Row，gap: spaceSm (8px)，center |

**节点内容**：

| 元素 | 规格 |
|------|------|
| Expand Icon | 20px，有子设备时显示：`expand_more`/`chevron_right` |
| Protocol Icon | 20px，`memory`(Virtual)、`lan`(TCP)、`cable`(RTU) 等 |
| Status Dot | 8px 圆形，状态色见下表 |
| Name Label | Body Medium (14px)，单行省略 |
| Context Menu | `more_vert`，32px，悬停/选中时显示 |

**状态圆点颜色**：

| 状态 | Light | Dark |
|------|-------|------|
| online | Success `#2E7D32` | `#81C784` |
| offline | On Surface Variant | On Surface Variant |
| error | Error `#BA1A1A` | `#FFB4AB` |

### 2.2 节点状态

| 状态 | 背景 | 其他 |
|------|------|------|
| Default | 透明 | — |
| Hover | On Surface 4% | 显示 Context Menu |
| Selected | Primary 8%，左侧 3px Primary 边框 | Name 变 Primary 色 |
| Pressed | On Surface 8% | — |

### 2.3 展开/折叠

| 属性 | 值 |
|------|-----|
| Icon Rotation | 90°，150ms ease-out |
| Child Animation | 高度展开/收起，200ms ease-in-out |
| Default | 第一层展开，其余折叠 |

### 2.4 面板头部

| 属性 | 值 |
|------|-----|
| Height | 56px，bottom border 1px Outline Variant |
| Title | Title Small (14px, 500) + Count Chip |
| Add Button | IconButton `add`，32px，Primary |

### 2.5 空状态 / 加载

- **空状态**: EmptyView 紧凑型，`device_hub_outlined`，标题"暂无设备"
- **加载**: Skeleton 5 项占位（圆形 20px + 两行长条）

---

## 3. 交互状态

| 操作 | 触发 | 反馈 |
|------|------|------|
| 点击节点 | 选中，右侧显示详情 | 选中态 + 内容切换 |
| 点击展开图标 | 展开/折叠子设备 | 图标旋转 + 子列表动画 |
| 双击节点 | 展开/折叠（如有子设备） | 同上 |
| 右键/长按 | Context Menu | 弹出菜单：编辑/添加子设备/删除 |
| 点击 + | 打开添加设备对话框 | Dialog |
| 拖拽 Resize | 调整面板宽度 | 实时预览 |

**Context Menu**：宽 180px，圆角 8px，危险操作 Error 色。

**键盘导航**：↑↓ 移动选中，→ 展开，← 折叠/回父级，Enter 选中，Delete 删除确认。

---

## 4. 响应式适配

| 断点 | 面板行为 |
|------|----------|
| Desktop (> 1024px) | 固定 320px，可拖拽调整 |
| Tablet (600-1024px) | 固定 280px |
| Mobile (< 600px) | 左侧 Modal Drawer，滑入/滑出 |

---

## 5. 主题适配

| 元素 | Light | Dark |
|------|-------|------|
| Panel Background | Surface | Surface |
| Tree Node Hover | On Surface 4% | On Surface 4% |
| Tree Node Selected | Primary 8% | Primary 8% |
| Status Dot Border | #FFFFFF | Surface |

---

## 6. 动画参数

| 动画 | 时长 | 缓动 |
|------|------|------|
| 展开/折叠 | 200ms | ease-in-out |
| 图标旋转 | 150ms | ease-out |
| 选中切换 | 150ms | ease-out |
| Drawer 滑入 | 250ms | ease-out |

---

## 7. 设计 QA 检查项

- [ ] 节点正确显示：名称 + 状态圆点 + 协议图标
- [ ] 展开/折叠动画流畅
- [ ] 选中态：Primary 背景 + 左侧边框
- [ ] 状态圆点颜色正确（绿/灰/红）
- [ ] 空状态 / 加载状态正确
- [ ] 键盘导航 (↑↓←→ Enter Delete)
- [ ] 移动端 Drawer 手势
- [ ] Light/Dark 主题切换正确

---

**文档结束**
