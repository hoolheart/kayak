# Figma 原型 - 工作台详情页 (Workbench Detail Page)

**Figma 文件**: `kayak_r1.fig` > Page: `Workbench Detail`  
**设计师**: sw-anna  
**日期**: 2026-05-03  
**状态**: 设计完成

---

## 1. 设计目标

工作台详情页采用经典的左右分栏布局：左侧设备树用于快速导航和层级认知，右侧展示详细内容。设计关键是清晰的两栏视觉分隔和树形结构的可交互性。

---

## 2. Frame 结构

### 2.1 主 Frame

```
Frame: "Workbench Detail - Light"
Width: 1440px
Height: 1080px
Background: Surface #FFFFFF
```

### 2.2 子 Frames

```
Workbench Detail
├── App Bar (1440 × 64)
│   ├── Back Button (arrow_back, 24px)
│   ├── Title "工作台名称" (Title Large)
│   ├── Spacer
│   ├── Edit Button (Outlined, 36px)
│   ├── Delete Button (Outlined, Error, 36px)
│   └── More Menu Button (IconButton, more_vert)
├── Workbench Info Section (padding: 20px 24px)
│   ├── Icon Container (48×48, Primary Container)
│   ├── Workbench Name (Title Large)
│   ├── Status Chip (Online/Offline)
│   ├── Description (Body Medium, On Surface Variant)
│   └── Metadata "创建于 · 最后修改" (Body Small, On Surface Variant)
├── Main Content (flex row)
│   ├── Device Tree Panel (280px)
│   │   ├── Tree Header: "+ 添加设备" (Text Button)
│   │   └── Tree Nodes (Vertical List)
│   │       ├── Device Node: 温度传感器1
│   │       │   ├── Point: 测点1
│   │       │   └── Point: 测点2
│   │       ├── Device Node: 压力变送器A
│   │       │   ├── Point: 测点1
│   │       │   ├── Point: 测点2
│   │       │   └── Point: 测点3
│   │       └── Device Node: 流量计B
│   │           └── Point: 测点1
│   └── Right Content Area (flex)
│       ├── Tab Bar: [设备列表] [设置]
│       ├── [Tab: 设备列表]
│       │   └── Device List
│       │       ├── Device Card: 温度传感器1 (selected)
│       │       │   ├── Icon + Name + Protocol Chip + Connection Button
│       │       │   └── Point Table (expanded)
│       │       │       ├── Header: 名称 | 类型 | 值 | 单位 | 状态
│       │       │       └── Rows: × N data points
│       │       ├── Device Card: 压力变送器A (collapsed)
│       │       └── Device Card: 流量计B (collapsed)
│       └── [Tab: 设置]
│           └── Settings Panel
```

---

## 3. 组件规格

### 3.1 Workbench Info Section

| 属性 | 值 |
|------|-----|
| Width | 100% |
| Padding | 20px 24px |
| Corner Radius | 12px |
| Fills | Surface Container Low |
| Bottom Margin | 16px |
| Icon | 48×48px, Primary Container, 12px radius |
| Name | Title Large (22pt, 500), On Surface |
| Status | Chip, right-aligned |
| Description | Body Medium (14pt, 400), On Surface Variant |
| Metadata | Body Small (12pt, 400), On Surface Variant |

### 3.2 Device Tree Panel

| 属性 | 值 |
|------|-----|
| Width | 280px (fixed) |
| Fills | Surface |
| Right Border | 1px Outline Variant |
| Padding | 12px |
| **Tree Header** | |
| Add Button | Text Button, "添加设备", add icon, 40px |
| **Tree Node (Device)** | |
| Height | 40px |
| Padding | 8px 12px (left based on level) |
| Corner Radius | 8px |
| Icon | memory, 20px, Primary |
| Text | Title Small (14pt, 500), On Surface |
| Status Dot | 8px circle, Green/Red |
| Expand Icon | expand_more/expand_less, 20px |
| **Selected State** | Primary Container fill, On Primary Container text |
| **Hover State** | On Surface Variant 4% fill |
| **Tree Node (Point)** | |
| Height | 36px |
| Indent | +20px from parent |
| Icon | circle, 6px, On Surface Variant |
| Text | Body Medium (14pt, 400), On Surface |

### 3.3 Device List Card

| 属性 | 值 |
|------|-----|
| Width | 100% (fill) |
| Padding | 12px 16px |
| Corner Radius | 12px |
| Fills | Surface |
| Stroke | 1px Outline Variant |
| Bottom Margin | 8px |
| **Header Row** | |
| Device Icon | 40×40px, Primary Container, 10px radius |
| Device Name | Title Medium (16pt, 500), On Surface |
| Protocol Chip | Protocol type chip |
| Connection Button | Outlined, 32px height |
| More Button | IconButton, more_vert, 32px |
| **Expanded: Point Table** | |
| Table Header | Surface Container Low, 40px height |
| Table Row | 44px height |
| Columns | 名称(150) | 类型(100) | 值(100) | 单位(80) | 状态(80) |
| Status Dot | 8px circle, Success/Warning/Error |
| Value Font | Body Medium, On Surface, monospace |

### 3.4 Tab Bar

| 属性 | 值 |
|------|-----|
| Height | 48px |
| Fills | Surface Container Lowest |
| Tab Item Height | 48px |
| Tab Item Padding | 12px 24px |
| Active Tab | Bottom border 2px Primary, Primary text |
| Inactive Tab | Transparent bottom, On Surface Variant text |
| Tab Font | Label Large (14pt, 500) |

---

## 4. 状态设计

### 4.1 设备树节点状态

```
Device Node States:
├── Default: Transparent, On Surface text
├── Hover: On Surface Variant 4% fill
├── Selected: Primary Container fill, On Primary Container text
├── Selected + Hover: Primary Container 80% opacity
├── Expanded: expand_less icon, children visible
└── Collapsed: expand_more icon, children hidden
```

### 4.2 连接状态

```
Connection States:
├── Connected: Green dot, "已连接", Outlined Button "断开"
├── Disconnected: Red dot, "未连接", Outlined Button "连接"
├── Connecting: Loading spinner, "连接中...", Button disabled
├── Error: Red dot, "连接失败", Outlined Button "重试"
└── Testing: Loading spinner, "测试中...", Button disabled
```

### 4.3 测点值状态

```
Point Value States:
├── Normal: Static value text
├── Updated: Value pulse highlight (Primary Container 500ms)
├── Warning: Warning color dot + value
├── Error: Error color dot + value
├── Disconnected: Gray dot, value "--"
└── Loading: Skeleton placeholder
```

---

## 5. 空状态设计

### 5.1 无设备状态

```
Component: "No Devices"
├── Icon: memory, 64px, On Surface Variant
├── Title: "暂无设备"
├── Description: "点击左侧「添加设备」按钮开始配置"
└── Button: Primary "添加设备"
```

### 5.2 无测点状态

```
Component: "No Points" (in device card)
├── Icon: sensors, 48px, On Surface Variant
├── Title: "该设备暂无测点"
├── Description: "为设备添加测点以开始采集数据"
└── Button: Text "添加测点"
```

---

## 6. 原型交互

| 起点 | 交互 | 终点 | 动画 |
|------|------|------|------|
| Device Tree Node | Tap | Select + expand/collapse | 150ms |
| Device List Card | Tap | Toggle expand point table | 150ms expand |
| Connection Button | Tap | Connect/Disconnect device | Button state change |
| Add Device (+) | Tap | Device Config Dialog | Dialog 200ms |
| Edit Button | Tap | Edit Workbench Dialog | Dialog 200ms |
| Delete Button | Tap | Delete Confirm Dialog | Dialog 200ms |
| More Menu | Tap | Context Menu | Dropdown 150ms |
| Tab: 设备列表 | Tap | Show device list | Fade 150ms |
| Tab: 设置 | Tap | Show settings panel | Fade 150ms |
| Point Row | Tap | Point Detail View | Push → 300ms |

---

## 7. 主题变体

| 元素 | Light Theme | Dark Theme |
|------|------------|------------|
| Page Background | #FFFFFF | #121212 |
| Info Section | #F5F5F5 | #1E1E1E |
| Tree Panel | #FFFFFF | #121212 |
| Tree Panel Border | #EEEEEE | #333333 |
| Device Card | #FFFFFF | #1E1E1E |
| Card Stroke | #EEEEEE | #333333 |
| Point Table Header | #F5F5F5 | #2D2D2D |
| Table Row Even | #FAFAFA | #1A1A1A |

---

## 8. 设计笔记

- 左侧设备树固定宽度 280px，右侧内容区自适应
- 选中设备时树节点和设备列表同时高亮
- 测点值更新时使用 500ms 的背景闪烁提示
- 列表中的设备卡片可展开/折叠测点表格
- 连接按钮状态实时反映设备连接情况
- 设置 Tab 用于工作台级别的配置（非本次 Release 1 重点）
