# Figma 原型 - 设备配置页 (Device Config Page)

**Figma 文件**: `kayak_r1.fig` > Page: `Device Config`  
**设计师**: sw-anna  
**日期**: 2026-05-03  
**状态**: 设计完成  
**优先级**: P0 (Release 1 核心页面)

---

## 1. 设计目标

设备配置页是 Release 1 的核心新增页面，承载三种工业协议的设备创建和编辑功能。设计挑战在于：在一个对话框内优雅地呈现三种完全不同结构的协议参数表单，并在协议切换时提供流畅的动态表单切换体验。

---

## 2. Frame 结构

### 2.1 主 Frame — 对话框

```
Frame: "Device Config Dialog - Light"
Width: 800px (max), 480px (min)
Height: Auto (max 90vh)
Background: Surface Container High
Corner Radius: 28px
Padding: 24px
```

### 2.2 对话框内部结构

```
Device Config Dialog
├── Dialog Header
│   ├── Title: "创建设备" / "编辑设备 - {name}"
│   └── Close Button (close, 24px)
├── Scrollable Content (max-height: calc(90vh - 140px))
│   ├── Section: 基本信息
│   │   ├── Section Title "基本信息" (Title Medium)
│   │   ├── Device Name Field *
│   │   │   ├── Label "设备名称"
│   │   │   ├── Filled Input (56px)
│   │   │   └── Error Message (collapsed)
│   │   └── Description Field
│   │       ├── Label "描述"
│   │       ├── Filled Input, multiline (56px × 2)
│   │       └── Error Message (collapsed)
│   │
│   ├── Section: 协议配置
│   │   ├── Section Title "协议配置" (Title Medium)
│   │   ├── Protocol Selector *
│   │   │   ├── Label "协议类型"
│   │   │   ├── Dropdown Input (56px)
│   │   │   │   ├── Selected: [icon] Virtual ▼
│   │   │   │   └── Dropdown Panel (Elevation 3, Surface)
│   │   │   │       ├── Option: Virtual
│   │   │   │       ├── Option: Modbus TCP
│   │   │   │       └── Option: Modbus RTU
│   │   │   └── Error Message (collapsed)
│   │   │
│   │   └── Protocol Config Panel (动态内容)
│   │       └── [Virtual Form] > [Modbus TCP Form] > [Modbus RTU Form]
│   │
│   └── Section: 测点配置 (可选)
│       ├── Section Title "测点配置" (Title Medium)
│       └── Point Config Table
│           ├── Table Header Row
│           ├── Table Data Rows (× N)
│           └── Add Point Button
│
└── Dialog Footer (sticky bottom)
    ├── Left: Test Connection Button (仅 Modbus)
    ├── Right: Cancel Button + Primary Create/Save Button
```

---

## 3. 核心组件详细规格

### 3.1 Protocol Selector (协议选择器)

#### 触发输入框
| 属性 | 值 |
|------|-----|
| Type | Filled Dropdown Input |
| Width | 100% (fill) |
| Height | 56px |
| Fills | Surface Container Highest, 50% opacity |
| Corner Radius | 8px (top-left, top-right) |
| Padding | 12px 16px |
| Label | "协议类型 *" (Body Small, On Surface Variant) |
| Selected Content | [24px icon] + "协议名称" + "▼" icon |
| Right Icon | arrow_drop_down, 24px |

#### 下拉面板
| 属性 | 值 |
|------|-----|
| Fills | Surface |
| Corner Radius | 8px |
| Shadow | Elevation 3 |
| Max Height | 240px (scrollable) |
| Option Height | 72px |
| Option Padding | 12px 16px |
| Option Layout | Row: icon (24px) + text column + check (if selected) |

#### 三个协议选项

**Option 1: Virtual**
```
┌─────────────────────────────────────────────┐
│ [developer_board]  Virtual              [✓] │
│                    虚拟设备，用于测试和模拟    │
└─────────────────────────────────────────────┘
```
| 元素 | 值 |
|------|-----|
| Icon | developer_board, 24px, Primary |
| Title | Virtual, Title Medium, On Surface |
| Description | "虚拟设备，用于测试和模拟", Body Small, On Surface Variant |
| Selected | Primary Container background, check icon |

**Option 2: Modbus TCP**
```
┌─────────────────────────────────────────────┐
│ [lan]  Modbus TCP                       [✓] │
│        TCP/IP 网络通信协议                   │
└─────────────────────────────────────────────┘
```
| 元素 | 值 |
|------|-----|
| Icon | lan, 24px, Tertiary |
| Title | Modbus TCP, Title Medium, On Surface |
| Description | "TCP/IP 网络通信协议", Body Small, On Surface Variant |

**Option 3: Modbus RTU**
```
┌─────────────────────────────────────────────┐
│ [usb]  Modbus RTU                       [✓] │
│        串口通信协议 (RS485/RS232)            │
└─────────────────────────────────────────────┘
```
| 元素 | 值 |
|------|-----|
| Icon | usb, 24px, Secondary |
| Title | Modbus RTU, Title Medium, On Surface |
| Description | "串口通信协议 (RS485/RS232)", Body Small, On Surface Variant |

---

### 3.2 Virtual Protocol Config Form

#### Frame 规格
```
Component: "Virtual Protocol Config Panel"
Layout: Auto Layout (Column, gap: 16px)
Padding: 24px
Corner Radius: 16px
Fills: Surface Container Lowest
Stroke: 1px Outline Variant
```

#### 表单字段布局
```
Virtual Config Panel
├── Title Row
│   ├── Icon: developer_board, 24px, Primary
│   ├── Title: "Virtual 协议参数" (Title Medium, On Surface)
│   └── Subtitle: "虚拟设备用于软件测试和开发，无需物理硬件" (Body Small, On Surface Variant)
├── Row 1: 数据模式 *
│   └── Dropdown: [shuffle] Random ▼
│       ├── Option: Random (shuffle icon)
│       ├── Option: Fixed (lock icon)
│       ├── Option: Sine (waves icon)
│       └── Option: Ramp (trending_up icon)
├── Row 2: 数据类型 * │ 访问类型 *
│   ├── Left (50%): Dropdown: Number ▼
│   │   ├── Number
│   │   ├── Integer
│   │   ├── String
│   │   └── Boolean
│   └── Right (50%): Dropdown: RW ▼
│       ├── RO (只读)
│       ├── WO (只写)
│       └── RW (读写)
├── Row 3: 最小值 * │ 最大值 *
│   ├── Left (50%): Number Input, placeholder "0.0"
│   └── Right (50%): Number Input, placeholder "100.0"
└── Row 4: 固定值 * (only when mode = Fixed)
    └── Number Input, full width, placeholder "50.0"
```

#### 数据模式选项详细
| 图标 | 名称 | 描述 |
|------|------|------|
| shuffle | Random | 随机生成数值 |
| lock | Fixed | 固定值输出 |
| waves | Sine | 正弦波模拟 |
| trending_up | Ramp | 线性递增 |

---

### 3.3 Modbus TCP Protocol Config Form

#### Frame 规格
```
Component: "Modbus TCP Config Panel"
Layout: Auto Layout (Column, gap: 16px)
Padding: 24px
Corner Radius: 16px
Fills: Surface Container Lowest
Stroke: 1px Outline Variant
```

#### 表单字段布局
```
Modbus TCP Config Panel
├── Title Row
│   ├── Icon: lan, 24px, Tertiary
│   ├── Title: "Modbus TCP 协议参数" (Title Medium, On Surface)
│   └── Subtitle: "通过 TCP/IP 网络与 Modbus 从站设备通信" (Body Small, On Surface Variant)
├── Row 1: 主机地址 * (60%) │ 端口 * (40%)
│   ├── Left: IP Address Input
│   │   ├── Placeholder: "192.168.1.100"
│   │   ├── Label: "主机地址"
│   │   ├── Type: Filled Input, 56px
│   │   └── Error: "请输入有效的IP地址或域名"
│   └── Right: Number Input
│       ├── Placeholder: "502"
│       ├── Label: "端口"
│       ├── Type: Filled Input, 56px
│       ├── Default: 502
│       └── Error: "端口范围 1-65535"
├── Row 2: 从站ID * (33%) │ 超时 (33%) │ 连接池大小 (33%)
│   ├── Left: Number Input
│   │   ├── Placeholder: "1"
│   │   ├── Label: "从站ID"
│   │   ├── Default: 1
│   │   └── Error: "从站ID范围 1-247"
│   ├── Center: Number Input
│   │   ├── Placeholder: "5000"
│   │   ├── Label: "超时 (ms)"
│   │   ├── Suffix: "ms"
│   │   ├── Default: 5000
│   │   └── Error: "超时范围 100-60000ms"
│   └── Right: Number Input
│       ├── Placeholder: "4"
│       ├── Label: "连接池大小"
│       ├── Default: 4
│       └── Error: "连接池大小 1-32"
└── Row 3: Connection Test Button
    └── Outlined Button "⚡ 测试连接", icon: bug_report
```

#### 连接测试按钮状态
| 状态 | 视觉 |
|------|------|
| **未测试** | Outlined Button, "⚡ 测试连接", Primary text |
| **测试中** | Filled Button (disabled), "⟳ 测试中...", CircularProgressIndicator 16px |
| **成功** | 绿色背景 Success Container, "✓ 连接成功 · 延迟 15ms", Success text |
| **失败** | 红色背景 Error Container, "✗ 连接失败: 连接超时", Error text |

---

### 3.4 Modbus RTU Protocol Config Form

#### Frame 规格
```
Component: "Modbus RTU Config Panel"
Layout: Auto Layout (Column, gap: 16px)
Padding: 24px
Corner Radius: 16px
Fills: Surface Container Lowest
Stroke: 1px Outline Variant
```

#### 表单字段布局
```
Modbus RTU Config Panel
├── Title Row
│   ├── Icon: usb, 24px, Secondary
│   ├── Title: "Modbus RTU 协议参数" (Title Medium, On Surface)
│   └── Subtitle: "通过串口 (RS485/RS232) 与 Modbus 从站设备通信" (Body Small, On Surface Variant)
├── Row 1: 串口 * (flex) │ [📡 扫描串口] (fixed 120px)
│   ├── Left: Dropdown Input
│   │   ├── Placeholder: "选择串口..."
│   │   ├── Label: "串口"
│   │   ├── Type: Filled Dropdown, 56px
│   │   ├── Options: (from serial scan)
│   │   │   ├── /dev/ttyUSB0 - USB Serial (Linux)
│   │   │   ├── /dev/ttyACM0 - USB ACM (Linux)
│   │   │   ├── /dev/cu.usbserial-1234 (macOS)
│   │   │   ├── COM1 (Windows)
│   │   │   └── COM3 (Windows)
│   │   └── Error: "请选择串口"
│   └── Right: Scan Button
│       ├── Type: Text Button
│       ├── Icon: radar
│       ├── Text: "扫描串口"
│       └── States: [未扫描] [扫描中...] [✓ 扫描完成] [未检测到设备]
├── Row 2: 波特率 * (25%) │ 数据位 * (25%) │ 停止位 * (25%) │ 校验 * (25%)
│   ├── Col 1: Dropdown
│   │   ├── Label: "波特率"
│   │   ├── Default: "9600"
│   │   └── Options: 9600 / 19200 / 38400 / 57600 / 115200
│   ├── Col 2: Dropdown
│   │   ├── Label: "数据位"
│   │   ├── Default: "8"
│   │   └── Options: 7 / 8
│   ├── Col 3: Dropdown
│   │   ├── Label: "停止位"
│   │   ├── Default: "1"
│   │   └── Options: 1 / 2
│   └── Col 4: Dropdown
│       ├── Label: "校验"
│       ├── Default: "None"
│       └── Options: None / Even / Odd
├── Row 3: 从站ID * (50%) │ 超时 (ms) (50%)
│   ├── Left: Number Input
│   │   ├── Placeholder: "1"
│   │   ├── Label: "从站ID"
│   │   ├── Default: 1
│   │   └── Error: "从站ID范围 1-247"
│   └── Right: Number Input
│       ├── Placeholder: "1000"
│       ├── Label: "超时 (ms)"
│       ├── Default: 1000
│       └── Error: "超时范围 100-60000ms"
└── Row 4: Connection Test Button
    └── Outlined Button "⚡ 测试连接", icon: bug_report
```

#### 串口扫描按钮状态
| 状态 | 图标 | 文字 | 样式 |
|------|------|------|------|
| 未扫描 | radar | 扫描串口 | Text Button, Primary color |
| 扫描中 | rotating radar | 扫描中... | Text Button, loading, disabled |
| 扫描完成 | check_circle (Success) | 扫描完成 | Text Button, Success color |
| 无设备 | radar | 未检测到串口 | Text Button, Warning color |
| 扫描失败 | error | 扫描失败 | Text Button, Error color |

---

### 3.5 Point Config Table (测点配置表格)

#### Modbus 点表格 (当协议为 Modbus TCP 或 Modbus RTU 时)
```
Point Configuration Table
├── Section Header
│   ├── Title "测点配置" (Title Medium, On Surface)
│   └── Subtitle "为设备配置 Modbus 测点" (Body Small, On Surface Variant)
├── Table Container
│   ├── Overflow: Auto (horizontal scroll)
│   ├── Corner Radius: 8px
│   ├── Border: 1px Outline Variant
│   │
│   ├── Header Row (Surface Container Low, 40px height)
│   │   ├── 名称 (100px, Label Medium, On Surface Variant)
│   │   ├── 功能码 (90px)
│   │   ├── 地址 (80px)
│   │   ├── 数据类型 (100px)
│   │   ├── 数量 (70px)
│   │   ├── 缩放 (80px)
│   │   ├── 偏移 (80px)
│   │   └── 操作 (40px)
│   │
│   ├── Data Row 1 (44px height)
│   │   ├── [Text Input] 测点1
│   │   ├── [Dropdown] 03 - 保持寄存器 ▼
│   │   ├── [Number Input] 0
│   │   ├── [Dropdown] uint16 ▼
│   │   ├── [Number Input] 1
│   │   ├── [Number Input] 1.0
│   │   ├── [Number Input] 0.0
│   │   └── [IconButton] delete (Error color)
│   │
│   ├── Data Row 2
│   └── Add Row Button
│       └── Text Button "+ 添加测点" (add icon)
│
└── Empty State (when no points)
    ├── Icon: sensors, 48px, On Surface Variant
    ├── Text: "暂无测点，点击添加" (Body Medium)
    └── Button: "+ 添加测点"
```

#### Virtual 点表格 (当协议为 Virtual 时)
```
Point Configuration Table (Virtual)
├── Header Row (40px)
│   ├── 名称 (100px)
│   ├── 数据类型 (100px)
│   ├── 访问类型 (80px)
│   ├── 最小值 (80px)
│   ├── 最大值 (80px)
│   ├── 固定值 (80px) — only when Fixed mode
│   └── 操作 (40px)
```

#### 功能码下拉选项
| 值 | 显示 | 图标 | 类型 | 读写 |
|----|------|------|------|------|
| 01 | 01 - 线圈 | toggle_on | bool | RW |
| 02 | 02 - 离散输入 | sensors | bool | RO |
| 03 | 03 - 保持寄存器 | memory | uint16 | RW |
| 04 | 04 - 输入寄存器 | input | uint16 | RO |

---

## 4. 表单验证状态设计

### 4.1 单字段验证状态组件

```
Component: "Form Field States"

State: Default (未验证)
┌──────────────────────────┐
│ Label                    │
│ ┌──────────────────────┐ │
│ │ Input text...        │ │
│ └──────────────────────┘ │
└──────────────────────────┘
  Border: none (bottom 1px Outline)
  Fills: Surface Container Highest 50%

State: Focused (聚焦)
┌──────────────────────────┐
│ Label                    │
│ ┌──────────────────────┐ │
│ │ Input text...  |     │ │
│ └──────────────────────┘ │
└──────────────────────────┘
  Border: bottom 2px Primary

State: Valid (验证通过)
┌──────────────────────────┐
│ Label                    │
│ ┌──────────────────────┐ │
│ │ Input text...   ✓    │ │
│ └──────────────────────┘ │
└──────────────────────────┘
  Right icon: check_circle, 20px, Success

State: Error (验证失败)
┌──────────────────────────┐
│ Label                    │
│ ┌──────────────────────┐ │
│ │ Invalid input  ✗     │ │
│ └──────────────────────┘ │
│ 错误提示文字              │
└──────────────────────────┘
  Border: bottom 1px Error
  Error text: Body Small, Error color, bottom margin 4px
  Error icon: error, 20px, Error color

State: Disabled (禁用)
┌──────────────────────────┐
│ Label                    │
│ ┌──────────────────────┐ │
│ │ Input text...        │ │
│ └──────────────────────┘ │
└──────────────────────────┘
  Opacity: 38%
  No interaction
```

### 4.2 表单全局验证状态

| 状态 | Create Button | 说明 |
|------|---------------|------|
| 未填写 | Disabled (38% opacity) | 按钮灰色，不可点击 |
| 部分填写 | Disabled | 按钮灰色，显示 tooltip "请完成所有必填字段" |
| 全填写待验证 | Enabled (Primary) | 按钮可用 |
| 验证中 | Loading spinner | 按钮显示 CircularProgressIndicator |
| 验证失败 | Enabled | 按钮可用，错误字段高亮显示 |
| 验证通过 | Enabled | 提交后显示 loading |

---

## 5. 状态变体 Frames

### 5.1 对话框状态 Frames

在 Figma 中应创建以下状态 Frames：

```
Page: "Device Config"
├── State: Create - Virtual Selected
├── State: Create - Virtual Selected (with errors)
├── State: Create - Modbus TCP Selected
├── State: Create - Modbus TCP Selected (connection testing)
├── State: Create - Modbus TCP Selected (connection success)
├── State: Create - Modbus TCP Selected (connection failed)
├── State: Create - Modbus RTU Selected
├── State: Create - Modbus RTU Selected (serial scanning)
├── State: Create - Modbus RTU Selected (scan complete)
├── State: Edit - Virtual (read-only protocol)
├── State: Edit - Modbus TCP (read-only protocol)
├── State: Edit - Modbus RTU (read-only protocol)
├── State: Protocol Switch Confirmation Dialog
├── State: Points Expanded (with 3 data rows)
├── State: Points Empty
├── State: Form Submit Loading
├── State: Form Submit Success
└── State: Form Submit Error
```

### 5.2 协议切换确认对话框

```
Dialog: "Switch Protocol Confirmation"
Width: 400px
├── Icon: warning, 48px, Warning color
├── Title: "切换协议？"
├── Content: "切换协议类型将清空当前已填写的协议参数。是否继续？"
└── Actions:
    ├── Text Button "取消"
    └── Primary Button "确认切换"
```

---

## 6. 原型交互 (Prototype Links)

### 6.1 协议切换流程

```
[Protocol Dropdown]
    │
    ├─ Tap → [Dropdown Panel] (150ms)
    │          │
    │          ├─ Tap "Virtual" → [Virtual Form slides in] (250ms ease-in-out)
    │          ├─ Tap "Modbus TCP" → [TCP Form slides in] (250ms ease-in-out)
    │          └─ Tap "Modbus RTU" → [RTU Form slides in] (250ms ease-in-out)
    │
    └─ Switch with unsaved data → [Confirmation Dialog] (200ms)
        ├─ "取消" → Stay on current protocol
        └─ "确认切换" → Switch to new protocol
```

### 6.2 连接测试流程

```
[Test Connection Button: 未测试]
    │
    ├─ Tap → [Testing State] (instant)
    │         Button: "⟳ 测试中..."
    │
    ├─ Success → [Success State] (after 1-2s)
    │             Button: "✓ 连接成功 · 延迟 15ms"
    │             Auto-resets after 5s
    │
    └─ Failure → [Failure State] (after 1-2s)
                  Button: "✗ 连接失败: 连接超时"
                  Can tap to retry
```

### 6.3 串口扫描流程

```
[Scan Button: 未扫描]
    │
    ├─ Tap → [Scanning State] (instant)
    │         Button: "⟳ 扫描中..."
    │         Icon rotates 360° (continuous)
    │
    ├─ Found ports → [Scan Complete] (after 1-3s)
    │                  Button: "✓ 扫描完成"
    │                  Dropdown populates with ports
    │                  First port auto-selected
    │
    └─ No ports → [No Devices]
                    Button: "未检测到串口"
                    Dropdown still empty
```

### 6.4 全部交互列表

| 起点 | 交互 | 终点 | 动画 |
|------|------|------|------|
| Protocol Dropdown | Tap | Dropdown Panel | Expand 150ms |
| Protocol Option | Tap | Load Form | Fade+Slide 250ms |
| Field Focus | Focus | Field Validation | Border color 150ms |
| Field Blur | Blur | Field Validation | Show/hide error |
| Test Connection | Tap | Connection Result | State change |
| Scan Serial | Tap | Serial List | State change |
| Add Point (+) | Tap | Add Table Row | Row expand 200ms |
| Delete Point | Tap | Remove Row | Row collapse 200ms |
| Create/Save Button | Tap | Submit | Loading state |
| Cancel Button | Tap | Close Dialog | Dialog fade 150ms |
| Close (X) | Tap | Close (with confirm if unsaved) | Dialog fade 150ms |
| Escape Key | Key | Close (with confirm if unsaved) | Dialog fade 150ms |
| Form Valid | Auto | Enable Submit Button | Instant |

---

## 7. 主题变体

### 7.1 Light Theme Colors

| 元素 | 颜色 |
|------|------|
| Dialog Background | Surface Container High #E0E0E0 |
| Section Card bg | Surface Container Lowest #FAFAFA |
| Form Field fills | Surface Container Highest 50% #BDBDBD@50% |
| Protocol Panel bg | Surface Container Lowest #FAFAFA |
| Protocol Panel Stroke | Outline #E0E0E0 |
| Table Header bg | Surface Container Low #F5F5F5 |
| Table Row bg (odd) | Surface #FFFFFF |
| Table Row bg (even) | Surface Container Lowest #FAFAFA |
| Error text / border | Error #C62828 |
| Error bg | Error Container #FFEBEE |
| Success text / icon | Success #2E7D32 |
| Success bg | Success Container #E8F5E9 |
| Button Primary | Primary #1976D2 |
| Button Primary text | On Primary #FFFFFF |

### 7.2 Dark Theme Colors

| 元素 | 颜色 |
|------|------|
| Dialog Background | Surface Container High #3D3D3D |
| Section Card bg | #0A0A0A |
| Form Field fills | #4D4D4D |
| Protocol Panel bg | #1E1E1E |
| Protocol Panel Stroke | Outline #424242 |
| Table Header bg | Surface Container Low #2D2D2D |
| Table Row bg (odd) | #1E1E1E |
| Table Row bg (even) | #0A0A0A |
| Error text / border | Error #EF5350 |
| Error bg | Error Container #B71C1C |
| Success text / icon | Success #66BB6A |
| Success bg | Success Container #1B5E20 |
| Button Primary | Primary #90CAF9 |
| Button Primary text | On Primary #000000 |

---

## 8. 响应式设计

### 8.1 Desktop (≥1280px)
- Dialog max-width: 800px
- Form fields 2-3 columns layout
- Table full width with horizontal scroll

### 8.2 Tablet (≥768px)
- Dialog max-width: 600px
- Form fields 1-2 columns layout
- Table with horizontal scroll

### 8.3 Mobile (<768px)
- Full screen modal (not dialog)
- Form fields single column
- Table with horizontal scroll
- Smaller touch targets

---

## 9. 设计笔记

1. **协议切换动画**: 使用 250ms ease-in-out 过渡，旧表单向上淡出，新表单从下方淡入。表单容器高度自适应内容。

2. **连接测试反馈**: Modbus TCP/RTU 的测试按钮提供即时视觉反馈，成功状态 5 秒后自动恢复为未测试状态。

3. **串口扫描**: RTU 的扫描按钮图标使用旋转动画（360° continuous rotation），完成后替换为绿色对勾。

4. **表单分组**: 基本信息、协议配置、测点配置三大区块通过 Section Title + 下方分隔线清晰区分。

5. **验证时机**: 采用失焦验证（onBlur）+ 提交验证（onSubmit）双模式。IP 地址等字段额外使用实时验证（300ms debounce）。

6. **编辑模式限制**: 编辑已有设备时，协议选择器禁用，防止意外更改协议类型。

7. **对话框底部按钮区**: 使用粘性定位（sticky bottom），内容溢出时底部添加渐变遮罩。

8. **测点表格交互**: 添加/删除测点行使用 200ms 的高度展开/收缩动画，避免页面跳动。

9. **键盘支持**: Enter 提交表单，Escape 关闭对话框，Tab 在字段间切换。
