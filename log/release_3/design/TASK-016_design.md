# TASK-016 详细设计 — 设备树组件

> **作者**: sw-tom (Developer)
> **日期**: 2026-05-31
> **状态**: 已完成
> **关联任务**: TASK-016
> **参考文档**: [tasks.md](../tasks.md), [device_tree_spec.md](../ui/specifications/device_tree_spec.md), [TASK-007 设计](TASK-007_design.md)
> **实现文件**: `kayak-frontend/lib/widgets/device_tree.dart`

---

## 1. 概述

设备树组件 (DeviceTree) 是工作台详情页左侧面板的核心组件，以树形结构展示设备层级关系。支持展开/折叠、选中、上下文菜单、添加/编辑/删除设备等交互。

组件位于工作台详情页的 `Row` 布局左列（320px，可拖拽调整），右侧为设备详情面板。

### 核心功能

| # | 功能 | 说明 |
|---|------|------|
| 1 | 树形展示 | 递归渲染设备层级，支持多级嵌套 |
| 2 | 展开/折叠 | 带动画的节点展开/折叠，默认展开第一层 |
| 3 | 节点选中 | 高亮选中态，通知父组件切换右侧详情 |
| 4 | 状态指示 | 绿/灰/红状态圆点 + 协议图标 |
| 5 | 上下文菜单 | 编辑/添加子设备/删除操作 |
| 6 | 添加设备 | 触发 DeviceConfigDialog（TASK-017） |
| 7 | 加载/空/错误三态 | 统一通过 AsyncValueWidget 分发 |

---

## 2. 组件树 & 依赖关系

```
DeviceTree (ConsumerStatefulWidget)
├── Panel Header (Container, 56px)
│   ├── Title "设备" + Count Chip (Container badge)
│   └── IconButton "+" → DeviceConfigDialog
├── Divider
└── AsyncValueWidget<List<DeviceTreeNode>>  ← deviceTreeProvider
    ├── loadingBuilder → Skeleton (5 项占位)
    ├── emptyBuilder   → EmptyView (compact)
    └── dataBuilder    → ListView
        └── DeviceTreeNode (递归)
            ├── InkWell (点击/双击)
            ├── Row
            │   ├── Expand Icon (AnimatedRotation, 20px)
            │   ├── Protocol Icon (20px, memory/lan/cable)
            │   ├── Status Dot (_StatusDot, 8px)
            │   ├── Name (Text, Body Medium, ellipsis)
            │   └── Context Menu (_ContextMenuButton, PopupMenuButton)
            └── AnimatedSize (200ms easeInOut)
                └── Children (递归，缩进 24px/level)

_StatusDot              ← 纯展示组件，根据 status 映射颜色
_ContextMenuButton      ← PopupMenuButton，编辑/添加子设备/删除

依赖的外部组件：
├── DeviceConfigDialog  ← device_config_dialog.dart (TASK-017)
├── ConfirmDialog       ← confirm_dialog.dart (TASK-007)
├── EmptyView           ← empty_view.dart (TASK-007)
├── AsyncValueWidget    ← async_value_widget.dart (TASK-007)
├── Toast               ← toast.dart (TASK-007)
└── deviceTreeProvider  ← device_provider.dart (状态层)
```

---

## 3. 数据流 & 状态管理

### 3.1 数据模型

```
DeviceTreeNode {
  id: String               // 设备 ID
  workbenchId: String       // 所属工作台 ID
  parentId: String?         // 父设备 ID（null 为根节点）
  name: String              // 设备名称
  protocolType: ProtocolType // virtual/modbusTcp/modbusRtu/can/visa/mqtt
  protocolParams: Map?      // 协议参数
  manufacturer: String?     // 制造商（高级信息）
  model: String?            // 型号
  sn: String?               // 序列号
  status: String            // online/offline/error
  children: List<DeviceTreeNode>  // 子设备列表
  createdAt: DateTime
  updatedAt: DateTime
}
```

### 3.2 Provider 层次

```
deviceTreeProvider(workbenchId)
  → AsyncNotifierProvider.family
  → DeviceTreeNotifier.build()
      → DeviceService.listByWorkbench(workbenchId)
      → 平铺 List<Device> 转嵌套 List<DeviceTreeNode> (_buildTree)
```

**状态流转：**

```
AsyncLoading → AsyncData (List<DeviceTreeNode>) – 成功
AsyncLoading → AsyncError – 失败（网络/权限等）
```

设备树的刷新由以下触发器驱动：

| 操作 | 触发方式 |
|------|----------|
| 页面首次加载 | `DeviceTreeNotifier.build()` 自动调用 |
| 添加/编辑/删除设备后 | `DeviceTreeNotifier.refresh()` / `ref.invalidate(...)` |
| 手动刷新 | `ref.invalidate(deviceTreeProvider(wbId))` |

### 3.3 组件内部状态

| 状态 | 类型 | 说明 |
|------|------|------|
| `_expandedIds` | `Set<String>` | 当前展开的节点 ID 集合 |
| `widget.selectedDeviceId` | `String?` | 父组件传入的选中 ID |

两种状态互斥影响：展开/折叠影响 children 列表的显隐，选中态影响节点高亮样式。

---

## 4. 交互逻辑

### 4.1 展开/折叠

```
用户点击 chevron_right 图标
  → _toggleExpand(nodeId)
  → setState 翻转 _expandedIds 中的节点
  → AnimatedRotation (0→0.25turn, 150ms easeOut)
  → AnimatedSize (0→child.height, 200ms easeInOut)
```

第一层节点通过 `initState` 中的 `ref.listen` 在数据加载后自动展开。

### 4.2 节点选中

```
用户点击节点 InkWell
  → widget.onDeviceSelected?.call(node.id)
  → 父组件更新 selectedDeviceId
  → 重建时该节点获得选中样式：
      - 背景: colorScheme.primary.withAlpha(20)  (8% opacity)
      - 左边框: 3px colorScheme.primary
      - 名称颜色: colorScheme.primary
      - Context Menu 出现
```

### 4.3 上下文菜单

```
Context Menu (PopupMenuButton, 180px, BorderRadius 8px)
├── 编辑设备 → _showEditDialog → DeviceConfigDialog(edit mode)
├── 添加子设备 → _showAddSubDialog → DeviceConfigDialog(with parentId)
├── PopupMenuDivider
└── 删除设备 → _showDeleteConfirm → ConfirmDialog(danger) → _handleDelete
```

菜单仅在节点选中时显示（`if (isSelected)`），通过 `more_vert` 图标触发。

### 4.4 删除流程

```
点击"删除" → ConfirmDialog 确认
  → 确认 → _handleDelete → deviceTreeNotifier.deleteDevice(node.id)
      → 后端调用 → 成功 → Toast.success + refresh()
      → 失败 → Toast.error 显示错误信息
```

### 4.5 添加/编辑流程

```
添加设备 → DeviceConfigDialog.show(mode: create)
添加子设备 → DeviceConfigDialog.show(mode: create, parentId: node.id)
编辑设备 → DeviceConfigDialog.show(mode: edit, device: node)
```

对话框关闭后由 Dialog 内部的 Provider 操作自动刷新设备树。

---

## 5. 视觉效果规格

| 元素 | 规格 |
|------|------|
| 面板宽度 | 320px（默认），min 240px，max 480px |
| 面板背景 | Surface |
| 面板边框 | 1px Outline Variant（右侧/底部） |
| 节点高度 | 40px |
| 缩进 | 24px per level |
| 节点间距 | horizontal 16px / right 8px |
| 选中背景 | Primary 8% opacity |
| 选中左边框 | 3px Primary |
| 悬停背景 | On Surface 4% |
| 状态圆点 | 8px, 圆形, 白色边框 1px |
| 展开动画 | 150ms rotation + 200ms size easeInOut |

---

## 6. 响应式适配

| 断点 | 行为 |
|------|------|
| > 1024px (Desktop) | 固定面板，可拖拽 Resize Handle |
| 600-1024px (Tablet) | 固定 280px |
| < 600px (Mobile) | Modal Drawer 滑入/滑出（250ms easeOut） |

当前实现采用固定面板，拖拽 Resize 和移动端 Drawer 为后续迭代。

---

## 7. 键盘导航（设计预留）

| 按键 | 行为 |
|------|------|
| ↑ / ↓ | 上下移动选中 |
| → | 展开节点 |
| ← | 折叠 / 回到父级 |
| Enter | 选中节点 |
| Delete | 删除确认 |

当前实现未包含键盘导航，键盘导航需要在父组件级别维护焦点索引。

---

## 8. 错误处理

| 场景 | 处理方式 |
|------|----------|
| 树加载失败 | AsyncError → ErrorView + 重试按钮 |
| 删除失败 | Toast.error 显示后端错误消息 |
| 网络失败 | ErrorView 显示网络错误，提供重试 |
| 空设备列表 | EmptyView 显示"暂无设备"图标和文案 |

---

## 9. 测试要点

- [ ] 树节点正确展示名称/状态圆点/协议图标
- [ ] 展开/折叠动画流畅，子节点正确显示/隐藏
- [ ] 选中态样式正确（背景 + 左边框 + 文字色）
- [ ] 状态圆点颜色映射正确（online=绿, offline=灰, error=红）
- [ ] 上下文菜单编辑/添加子设备/删除功能正常
- [ ] 删除确认对话框正确显示并执行删除
- [ ] 添加设备对话框正确触发
- [ ] 空状态/加载状态正确展示
- [ ] Light/Dark 主题正确适配
