# TASK-014: 工作台详情页 UI 设计规范

> **路由**: `/workbenches/{id}`  
> **依赖**: TASK-013 (工作台列表页)  
> **设计师**: sw-anna  
> **日期**: 2026-05-31  
> **状态**: 设计稿完成

---

## 1. 页面布局

### 1.1 整体结构

```
WorkbenchDetailPage
├── AppBar (64px)
│   ├── Back Button (arrow_back) → 返回列表
│   ├── Title: "工作台详情" (Title Large)
│   └── Actions: [编辑] [删除] IconButtons
├── Info Section (auto height)
│   ├── Icon Container (48×48, Primary Container)
│   ├── Name + Status Chip (Row)
│   ├── Description (Body Medium, On Surface Variant)
│   └── Metadata: "创建于 · 最后修改" (Body Small)
├── Main Content (flex: 1, Row/Column based on width)
│   ├── Left Panel: Device Tree Placeholder (280px fixed / 100% stacked)
│   │   ├── Header: "设备树" + TextButton "+ 添加设备"
│   │   └── Placeholder Content
│   └── Right Panel: Device Detail Placeholder (flex)
│       ├── Header: "设备详情"
│       └── Placeholder Content
└── (底部无固定元素)
```

### 1.2 布局参数

| 属性 | 值 |
|------|-----|
| Page Background | Background color token |
| Info Section Padding | spaceLg (24px) |
| Info Section Margin | spaceMd (16px) bottom |
| Info Section Fill | Surface Container Low |
| Info Section Radius | radiusLarge (12px) |
| Main Content Gap | spaceMd (16px) |

---

## 2. 组件规格

### 2.1 信息区 (Info Section)

| 属性 | 值 |
|------|-----|
| Width | 100% |
| Padding | spaceLg (24px) |
| Corner Radius | radiusLarge (12px) |
| Fills | Surface Container Low |
| Layout | Column, gap: spaceSm (8px) |

**内容元素**（从上到下）：

| 元素 | 规格 |
|------|------|
| 图标 | 48×48px, Primary Container fill, radiusMedium (8px) |
| 名称行 | Row: 名称 (Title Large, 22px, 500) + Status Chip |
| 名称 | On Surface, 单行 |
| 状态标签 | Chip: Online/Offline/Error 对应颜色 |
| 描述 | Body Medium (14px, 400), On Surface Variant, 多行 |
| 元数据 | Body Small (12px, 400), On Surface Variant |

### 2.2 状态标签 (Status Chip)

| 状态 | 背景色 | 文字色 | 说明 |
|------|--------|--------|------|
| Online | Success Container | On Success Container | 设备在线 |
| Offline | Surface Variant | On Surface Variant | 设备离线 |
| Error | Error Container | On Error Container | 有错误 |

### 2.3 占位区域 (Placeholder)

**设备树占位 (左侧面板)**：

| 属性 | 值 |
|------|-----|
| Width | 280px (desktop) / 100% (mobile) |
| Min Height | 400px |
| Fill | Surface with 4% opacity Pattern |
| Border | 1px Outline Variant (desktop right border) |
| Content | Centered: Icon + Text |
| Icon | `Icons.account_tree_outlined`, 48px, On Surface Variant |
| Title | "设备树" (Title Medium) |
| Description | "将在下一个 Sprint 实现" (Body Small) |
| Action | TextButton "+ 添加设备" (disabled style) |

**设备详情占位 (右侧面板)**：

| 属性 | 值 |
|------|-----|
| Width | flex: 1 (fill remaining) |
| Min Height | 400px |
| Fill | Surface |
| Content | Centered: Icon + Text |
| Icon | `Icons.memory`, 48px, On Surface Variant |
| Title | "设备详情" (Title Medium) |
| Description | "选择左侧设备查看详情" (Body Small) |

### 2.4 骨架屏 (Loading)

使用 TASK-007 Skeleton：

- **Info Section**: 圆形头像占位 (48px) + 2 行文字占位 + 1 行元数据占位
- **Tree Panel**: 树形列表骨架，5-6 个节点占位
- **Detail Panel**: 卡片骨架，标题 + 多行内容占位

---

## 3. 交互状态

### 3.1 页面级状态流转

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Loading │───→│  Data   │←───│  Error  │
└─────────┘    └─────────┘    └─────────┘
     │                              │
     │ (加载成功)                   │ (重试成功)
     └──────────────────────────────┘
```

### 3.2 操作按钮交互

| 操作 | 触发 | 反馈 |
|------|------|------|
| 点击编辑 | 弹出编辑对话框 | 复用 TASK-013 创建/编辑对话框 |
| 点击删除 | 弹出确认对话框 | ConfirmDialog → 删除后返回列表 |
| 点击返回 | 返回工作台列表 | 页面 Pop 动画 300ms |

### 3.3 编辑对话框

复用 TASK-013 的创建/编辑对话框：

```
Dialog: "编辑工作台"
├── 名称 * (TextField, pre-filled)
├── 描述 (TextField, pre-filled, multiline)
└── [取消] [保存]
```

### 3.4 删除确认

```
ConfirmDialog (危险变体):
Title: "删除工作台？"
Description: "确定要删除工作台「{name}」吗？此操作不可撤销，工作台下所有设备和数据将被永久删除。"
Buttons: [取消] [确认删除] (Error color)
```

**删除后行为**：
- 成功 → Toast "工作台已删除" → 自动返回列表页 `/workbenches`
- 失败 → Toast 显示错误原因

---

## 4. 响应式适配

### 4.1 桌面端 (> 1024px)

```
┌─────────────────────────────────────────────────────┐
│ AppBar                                              │
├─────────────────────────────────────────────────────┤
│ Info Section                                        │
├──────────────────┬──────────────────────────────────┤
│                  │                                  │
│  Device Tree     │    Device Detail Panel           │
│  (280px fixed)   │    (flex: 1)                     │
│                  │                                  │
│                  │                                  │
└──────────────────┴──────────────────────────────────┘
```

- 左右分栏，固定间距 spaceMd (16px)
- 左侧面板固定宽度 280px，右侧自适应

### 4.2 平板端 (600-1024px)

```
┌─────────────────────────────────┐
│ AppBar                          │
├─────────────────────────────────┤
│ Info Section                    │
├─────────────────────────────────┤
│ Device Tree (可折叠)            │
├─────────────────────────────────┤
│ Device Detail Panel             │
└─────────────────────────────────┘
```

- 上下堆叠布局
- 设备树区域可折叠/展开（默认展开）
- 折叠按钮在设备树标题栏右侧

### 4.3 移动端 (< 600px)

```
┌─────────────────────┐
│ AppBar (含返回)     │
├─────────────────────┤
│ Info Section        │
├─────────────────────┤
│ [设备树 ▼]          │ ← 可折叠 Section
├─────────────────────┤
│ Device Detail       │
└─────────────────────┘
```

- AppBar: 标题缩短，操作按钮收入 Overflow Menu
- 信息区: 减少 padding 至 spaceMd (16px)
- 设备树: 默认折叠，点击展开
- 详情面板: 全宽

---

## 5. 主题适配

| 元素 | Light Theme | Dark Theme |
|------|------------|------------|
| Page Background | Background (#FDFCFF) | Background (#1A1C1E) |
| Info Section | Surface Container Low | Surface Container Low |
| Tree Panel | Surface | Surface |
| Tree Panel Border | Outline Variant | Outline Variant |
| Detail Panel | Surface | Surface |
| Placeholder Icon | On Surface Variant 60% | On Surface Variant 60% |
| Placeholder Text | On Surface Variant | On Surface Variant |

---

## 6. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 200ms | ease-out | Fade + Slide |
| 编辑 Dialog | 200ms | ease-out | Scale/Fade |
| 设备树展开/折叠 | 200ms | ease-in-out | Height animation |
| 骨架屏淡出 | 200ms | ease-in-out | 数据加载完成后 |
| Toast 进入 | 300ms | ease-out | Slide + Fade |

---

## 7. 与后续 Sprint 的衔接

### 7.1 Sprint 4 设备树 (TASK-016)

- 替换左侧占位区域为实际 DeviceTree 组件
- DeviceTree 组件规格：
  - 树形结构展示设备层级
  - 节点：设备名 + 状态圆点 + 协议图标
  - 展开/折叠箭头
  - 点击选中 → 右侧面板显示设备详情

### 7.2 Sprint 4 设备详情 (TASK-017)

- 替换右侧占位区域为实际 DeviceDetailPanel
- 显示设备基本信息 + 协议配置 + 操作按钮

---

## 8. 设计 QA 检查项

- [ ] 三态完整：Loading (Skeleton) / Error (ErrorView) / Data (Info + Placeholders)
- [ ] 信息区显示：名称、描述、状态、创建时间
- [ ] 编辑/删除操作可用
- [ ] 删除后返回列表页
- [ ] 设备树占位区存在且样式正确
- [ ] 响应式：桌面左右分栏 / 移动端上下堆叠
- [ ] Light/Dark 主题颜色正确
- [ ] 所有文本通过 l10n (无硬编码)
- [ ] 不存在的 id → 404 错误处理
- [ ] 返回按钮正确导航到列表页

---

**文档结束**
