# TASK-022: 试验创建流程 UI 设计规范

> **路由**: `/experiments/new`  
> **依赖**: TASK-007 (可复用组件库)、TASK-012 (WorkbenchService)、TASK-020 (ExperimentService)  
> **设计师**: sw-anna  
> **日期**: 2026-06-02  
> **状态**: 设计稿完成

---

## 1. 页面布局

### 1.1 整体结构

```
ExperimentCreatePage
├── AppBar (56px, 移动端 64px)
│   ├── Back Button (arrow_back) → 返回 /experiments
│   ├── Title: "创建试验" / "Create Experiment" (Title Large)
│   └── 无操作按钮（向导流程不展示右上角操作）
├── Stepper Header (固定顶部，卡片风格)
│   ├── 4 步水平 Stepper
│   │   ├── Step 1: "选择工作台" / "Select Workbench" (Icons.build_outlined)
│   │   ├── Step 2: "选择方法" / "Select Method" (Icons.science_outlined)
│   │   ├── Step 3: "配置参数" / "Configure Parameters" (Icons.tune_outlined)
│   │   └── Step 4: "确认创建" / "Confirm" (Icons.check_circle_outlined)
│   └── 步骤连接线（已完成段主色，未完成段灰色）
├── Content Area (flex: 1, 滚动区域)
│   ├── Step 1 Content: Workbench Selection
│   ├── Step 2 Content: Method Selection
│   ├── Step 3 Content: Parameter Configuration
│   └── Step 4 Content: Confirmation Preview
└── Bottom Navigation Bar (固定底部)
    ├── [上一步] (步骤 2-4 显示)
    ├── Spacer
    └── [下一步/创建试验] (根据步骤动态)
```

### 1.2 布局参数

| 属性 | 桌面端 | 移动端 |
|------|--------|--------|
| Page Background | Background color token | Background color token |
| Content Max Width | 960px（居中） | 100% |
| Content Padding | spaceLg (24px) | spaceMd (16px) |
| Stepper Padding | spaceMd (16px) vertical | spaceSm (12px) vertical |
| Bottom Bar Padding | spaceMd (16px) | spaceMd (16px) |
| Bottom Bar Height | 64px | 64px |
| Section Gap | spaceLg (24px) | spaceMd (16px) |

---

## 2. 步骤指示器 (Stepper)

### 2.1 Stepper 组件规格

使用 Material 3 `Stepper` 组件的自定义样式：

| 属性 | 值 |
|------|-----|
| Type | Horizontal |
| Background | Surface Container Low |
| Elevation | 0 |
| Border Radius | radiusLarge (12px) |
| Padding | spaceMd (16px) horizontal, spaceSm (12px) vertical |

### 2.2 步骤状态样式

| 状态 | 图标 | 颜色 | 文字样式 |
|------|------|------|----------|
| **未激活** | 步骤编号圆圈 | Outline color | Body Medium, On Surface Variant |
| **激活** | 步骤编号圆圈 | Primary Container fill + On Primary Container | Body Medium, On Surface, FontWeight.w600 |
| **已完成** | Icons.check_circle | Primary color | Body Medium, On Surface |
| **禁用** | 步骤编号圆圈 | On Surface Variant at 38% | Body Medium, On Surface Variant at 38% |

### 2.3 步骤连接线

| 状态 | 颜色 | 高度 |
|------|------|------|
| 已完成段 | Primary color | 2px |
| 未完成段 | Outline Variant | 1px |

### 2.4 步骤点击行为

| 点击目标 | 行为 |
|----------|------|
| 已完成步骤 | 可点击，跳转到对应步骤，已选数据保持 |
| 当前步骤 | 不可点击（已在当前） |
| 未完成步骤 | 不可点击（视觉禁用） |

---

## 3. 步骤 1 — 选择工作台

### 3.1 布局结构

```
Step 1 Content
├── Section Title: "选择工作台" (Title Medium)
├── Section Subtitle: "请选择一个工作台用于本次试验" (Body Small, On Surface Variant)
├── [Loading] → Skeleton Card Grid (3 个占位)
├── [Error]   → ErrorView + 重试按钮
├── [Empty]   → EmptyView (图标 + 引导 + 创建按钮)
└── [Data]    → Workbench Card Grid
```

### 3.2 工作台卡片 (SelectableWorkbenchCard)

基于现有 WorkbenchCard 扩展选中状态：

| 属性 | 值 |
|------|-----|
| Min Width | 240px |
| Padding | spaceMd (16px) |
| Corner Radius | radiusLarge (12px) |
| Layout | Column, gap: spaceSm (8px) |

**卡片内容**（从上到下）：

| 元素 | 规格 |
|------|------|
| 顶部行 | Row: 图标 (40px) + 名称 (Title Medium) + 选中标记 |
| 选中标记 | Icons.check_circle, 24px, Primary color（仅选中时显示） |
| 设备数量 | Body Small, On Surface Variant: "N 台设备" / "N devices" |
| 描述（如有） | Body Small, On Surface Variant, 2 行省略 |

**卡片状态**：

| 状态 | 视觉 |
|------|------|
| Default | Surface fill, 1px Outline Variant |
| Hover | Elevation 2, Stroke → Primary at 50% |
| Pressed | Elevation 1, Scale 0.98 |
| **Selected** | **Primary Container fill, 2px Primary stroke, 选中标记显示** |

### 3.3 骨架屏

使用 SkeletonType.card 的变体：

```
SelectableWorkbenchCard Skeleton (3 个)
├── 圆形占位 (40px)
├── 标题行占位 (60% 宽度)
├── 设备数量行占位 (40% 宽度)
└── 间距: spaceMd (16px)
```

### 3.4 空状态

```
EmptyView(
  icon: Icons.build_outlined,
  title: "您还没有工作台",
  description: "点击下方按钮创建您的第一个工作台",
  actionButton: ElevatedButton "创建第一个工作台" → /workbenches,
)
```

### 3.5 错误状态

```
ErrorView(
  title: "加载工作台列表失败",
  description: "请检查网络后点击重试",
  onRetry: () => ref.invalidate(workbenchListProvider),
)
```

---

## 4. 步骤 2 — 选择方法

### 4.1 布局结构

```
Step 2 Content
├── Section Title: "选择方法" (Title Medium)
├── Section Subtitle: "请选择一个试验方法" (Body Small, On Surface Variant)
├── [Loading] → Skeleton Card Grid
├── [Error]   → ErrorView
├── [Empty]   → EmptyView
└── [Data]    → Method Card Grid
```

### 4.2 方法卡片 (SelectableMethodCard)

| 属性 | 值 |
|------|-----|
| Min Width | 240px |
| Padding | spaceMd (16px) |
| Corner Radius | radiusLarge (12px) |
| Layout | Column, gap: spaceSm (8px) |

**卡片内容**（从上到下）：

| 元素 | 规格 |
|------|------|
| 顶部行 | Row: 图标 (40px, Primary Container) + 名称 (Title Medium) + 选中标记 |
| 选中标记 | Icons.check_circle, 24px, Primary color（仅选中时显示） |
| 描述 | Body Small, On Surface Variant, **最多 2 行**（超出截断带省略号） |
| 参数数量 | Body Small, On Surface Variant: "N 个参数" / "N parameters" |

**卡片状态**：

| 状态 | 视觉 |
|------|------|
| Default | Surface fill, 1px Outline Variant |
| Hover | Elevation 2, Stroke → Primary at 50% |
| Pressed | Elevation 1, Scale 0.98 |
| **Selected** | **Primary Container fill, 2px Primary stroke, 选中标记显示** |

### 4.3 空状态

```
EmptyView(
  icon: Icons.science_outlined,
  title: "暂无可用方法",
  description: "请先创建试验方法",
  actionButton: TextButton "前往方法管理" → /methods,
)
```

---

## 5. 步骤 3 — 配置参数

### 5.1 布局结构

```
Step 3 Content
├── Section Title: "配置参数" (Title Medium)
├── Section Subtitle: "请配置所选方法的参数" (Body Small, On Surface Variant)
├── [No Params] → Info Banner: "该方法无需配置参数"
└── [Has Params] → Dynamic Parameter Form
    ├── 参数字段 1
    ├── 参数字段 2
    └── ...
```

### 5.2 动态参数表单

表单根据所选方法的 `parameterSchema` 动态生成字段。每个参数字段的布局：

```
Parameter Field
├── Label Row
│   ├── 参数标签 (label ?? key)
│   ├── 必填标记 * (仅 required=true 时显示，Error color)
│   └── 单位 (unit, Body Small, On Surface Variant)
├── Input Widget (根据类型)
├── Helper Text (description, Body Small, On Surface Variant)
└── Error Text (验证错误时显示, Body Small, Error color)
```

### 5.3 参数输入控件映射

| 参数类型 | Dart 类型 | 输入控件 | 键盘类型 | 验证规则 |
|----------|-----------|----------|----------|----------|
| `number` | `double` | `TextFormField` | `TextInputType.numberWithOptions(decimal: true)` | 数值格式、min/max |
| `integer` | `int` | `TextFormField` | `TextInputType.number` | 整数格式、min/max |
| `string` | `String` | `TextFormField` | `TextInputType.text` | 长度限制（如有） |
| `boolean` | `bool` | `Switch` / `Checkbox` | N/A | 无 |
| `enum` | `String` | `DropdownButtonFormField` | N/A | 选项必须在列表中 |

### 5.4 参数字段样式

| 属性 | 值 |
|------|-----|
| Field Padding | spaceMd (16px) vertical |
| Label Style | Body Medium, On Surface, FontWeight.w500 |
| Required Mark | " *", Error color, Body Medium |
| Unit Style | Body Small, On Surface Variant |
| Helper Text | Body Small, On Surface Variant |
| Error Text | Body Small, Error color |
| Input Decoration | Outlined border, radiusMedium (8px) |

### 5.5 验证规则

| 规则 | 行为 | 错误文本 |
|------|------|----------|
| 必填项为空 | 显示错误 | "此字段为必填项" / "This field is required" |
| 数值超出范围 | 显示错误 | "不能小于 {min}" / "Cannot be less than {min}" |
| 数值超出范围 | 显示错误 | "不能大于 {max}" / "Cannot be greater than {max}" |
| 整数输入小数 | 显示错误 | "必须为整数" / "Must be an integer" |
| 类型不匹配 | 拒绝输入或显示错误 | "格式不正确" / "Invalid format" |

### 5.6 无参数方法

```
Info Banner
├── Icon: Icons.info_outline, Primary color
├── Text: "该方法无需配置参数" / "No parameters required"
└── Subtext: "点击下一步继续" / "Click Next to continue"
```

---

## 6. 步骤 4 — 确认预览

### 6.1 布局结构

```
Step 4 Content
├── Section Title: "确认创建" (Title Medium)
├── Section Subtitle: "请确认以下信息无误" (Body Small, On Surface Variant)
├── Summary Card (Surface Container Low)
│   ├── 工作台信息 Section
│   │   ├── Label: "工作台" (Body Small, On Surface Variant)
│   │   └── Value: 工作台名称 (Body Large, On Surface)
│   ├── Divider
│   ├── 方法信息 Section
│   │   ├── Label: "试验方法" (Body Small, On Surface Variant)
│   │   └── Value: 方法名称 (Body Large, On Surface)
│   ├── Divider
│   └── 参数配置 Section (如有)
│       ├── Label: "参数配置" (Body Small, On Surface Variant)
│       └── Parameter List
│           ├── 参数 1: 名称 = 值 (Body Medium)
│           ├── 参数 2: 名称 = 值
│           └── ...
└── Warning Text (Body Small, On Surface Variant)
    └── "创建后试验将立即开始运行"
```

### 6.2 摘要卡片样式

| 属性 | 值 |
|------|-----|
| Background | Surface Container Low |
| Padding | spaceLg (24px) |
| Corner Radius | radiusLarge (12px) |
| Section Gap | spaceMd (16px) |
| Divider | 1px Outline Variant |

### 6.3 参数摘要列表

| 属性 | 值 |
|------|-----|
| Layout | Column, gap: spaceSm (8px) |
| Item Layout | Row: 参数名 (Body Medium) + " = " + 参数值 (Body Medium, Primary color) |
| Boolean 值 | "开启" / "关闭" 或 "On" / "Off" |
| Enum 值 | 显示选中的选项文本 |

---

## 7. 底部导航栏

### 7.1 布局结构

```
Bottom Navigation Bar (固定在内容区底部)
├── Padding: spaceMd (16px) horizontal
├── [上一步] Button (OutlinedButton, 步骤 2-4)
│   ├── Icon: Icons.arrow_back
│   └── Text: "上一步" / "Back"
├── Spacer
└── [下一步/创建] Button (FilledButton)
    ├── 步骤 1-3: Icon: Icons.arrow_forward + Text: "下一步" / "Next"
    └── 步骤 4: Icon: Icons.add + Text: "创建试验" / "Create Experiment"
```

### 7.2 按钮状态

| 场景 | 上一步 | 下一步/创建 |
|------|--------|-------------|
| 步骤 1 | 隐藏 | 禁用（未选工作台）/ 启用（已选） |
| 步骤 2 | 启用 | 禁用（未选方法）/ 启用（已选） |
| 步骤 3 | 启用 | 禁用（验证失败）/ 启用（验证通过） |
| 步骤 4 | 启用 | 禁用（创建中）/ 启用（可创建） |

### 7.3 创建按钮 Loading 状态

```
创建按钮 Loading:
├── 按钮禁用
├── 按钮内显示 CircularProgressIndicator (20px, strokeWidth: 2)
└── 按钮文字替换为 "创建中..." / "Creating..."
```

---

## 8. 响应式适配

### 8.1 断点定义

| 断点 | 宽度 | Stepper 样式 | 卡片列数 | 参数表单 | 底部按钮 |
|------|------|-------------|----------|----------|----------|
| Mobile | < 600px | 简化（数字+短标签） | 1 列 | 单列 | 全宽堆叠 |
| Tablet | 600-1200px | 完整标签 | 2 列 | 单列 | 并排 |
| Desktop | > 1200px | 完整标签+图标 | 2-3 列 | 双列 | 并排 |

### 8.2 移动端适配 (< 600px)

- **Stepper**: 简化为数字圆圈 + 短标签（如"工作台"而非"选择工作台"），步骤间连接线缩短
- **卡片**: 单列全宽，减少 padding 至 spaceSm (12px)
- **参数表单**: 单列，标签在输入框上方全宽显示
- **底部按钮**: 全宽堆叠排列，上一步在下，下一步在上
- **内容区**: 全宽，padding spaceMd (16px)
- **摘要卡片**: 全宽，参数列表垂直排列

### 8.3 平板适配 (600-1200px)

- **Stepper**: 完整标签，水平排列
- **卡片**: 2 列网格
- **参数表单**: 单列或双列（根据字段数量）
- **底部按钮**: 并排，宽度自适应
- **内容区**: 居中，最大宽度 600px

### 8.4 桌面端适配 (> 1200px)

- **Stepper**: 完整标签 + 图标，水平排列
- **卡片**: 2-3 列网格（根据可用宽度自适应）
- **参数表单**: 双列或三列（使用 Wrap + ConstrainedBox）
- **底部按钮**: 并排，位于内容区下方右侧
- **内容区**: 居中，最大宽度 960px

---

## 9. 主题适配

### 9.1 Light Theme

| 元素 | 颜色 |
|------|------|
| Page Background | Background (#FDFCFF) |
| Stepper Background | Surface Container Low |
| Card Background | Surface |
| Selected Card | Primary Container |
| Selected Card Border | Primary (2px) |
| Bottom Bar Background | Surface |
| Summary Card | Surface Container Low |
| Input Border (Default) | Outline |
| Input Border (Focused) | Primary (2px) |
| Input Border (Error) | Error |

### 9.2 Dark Theme

| 元素 | 颜色 |
|------|------|
| Page Background | Background (#1A1C1E) |
| Stepper Background | Surface Container Low |
| Card Background | Surface |
| Selected Card | Primary Container |
| Selected Card Border | Primary (2px) |
| Bottom Bar Background | Surface |
| Summary Card | Surface Container Low |
| Input Border (Default) | Outline |
| Input Border (Focused) | Primary (2px) |
| Input Border (Error) | Error |

---

## 10. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 200ms | ease-out | Fade + Slide from right |
| 步骤切换 | 300ms | ease-in-out | Fade + Slide horizontal |
| 卡片 Hover | 150ms | ease-out | Elevation + Stroke color |
| 卡片 Pressed | 100ms | ease-in-out | Scale 0.98 |
| 卡片选中 | 200ms | ease-out | Background color + Border |
| 骨架屏 shimmer | 1.5s | linear | 循环 |
| 步骤完成标记 | 300ms | ease-out | Scale bounce (编号 → 勾选) |
| 错误提示出现 | 200ms | ease-out | Slide down + Fade |
| Toast 进入 | 300ms | ease-out | Slide + Fade |
| 按钮 Loading | 150ms | ease-in-out | 文字淡出 + Indicator 淡入 |

---

## 11. 交互状态流转

### 11.1 页面级状态流转

```
页面加载
    │
    ▼
Step 1: 加载工作台列表
    │
    ├── [Loading] → Skeleton
    ├── [Error]   → ErrorView + 重试
    ├── [Empty]   → EmptyView + 引导
    └── [Data]    → Workbench Cards
              │
              ▼
        选择工作台 → 下一步启用
              │
              ▼
Step 2: 加载方法列表
    │
    ├── [Loading] → Skeleton
    ├── [Error]   → ErrorView + 重试
    ├── [Empty]   → EmptyView + 引导
    └── [Data]    → Method Cards
              │
              ▼
        选择方法 → 下一步启用
              │
              ▼
Step 3: 参数配置
    │
    ├── [No Params] → Info Banner
    └── [Has Params] → Dynamic Form
              │
              ▼
        验证通过 → 下一步启用
              │
              ▼
Step 4: 确认预览
    │
    └── 点击创建
              │
              ├── [Loading] → 按钮 Loading
              ├── [Success] → Toast + 跳转 /experiments/{id}
              └── [Error]   → Toast 错误 + 保持页面
```

### 11.2 步骤导航状态

| 条件 | 步骤 1 | 步骤 2 | 步骤 3 | 步骤 4 |
|------|--------|--------|--------|--------|
| 初始状态 | 激活 | 禁用 | 禁用 | 禁用 |
| 选工作台后 | 完成 | 激活 | 禁用 | 禁用 |
| 选方法后 | 完成 | 完成 | 激活 | 禁用 |
| 参数配置后 | 完成 | 完成 | 完成 | 激活 |

---

## 12. 设计 QA 检查项

- [ ] 四步 Stepper 完整显示，步骤标签正确
- [ ] 步骤 1 未完成时步骤 2-4 禁用
- [ ] 步骤 1: 三态完整（Loading/Error/Empty/Data）
- [ ] 步骤 1: 选中工作台高亮（Primary Container + 勾选标记）
- [ ] 步骤 2: 三态完整
- [ ] 步骤 2: 选中方法高亮
- [ ] 步骤 2: 方法描述最多 2 行截断
- [ ] 步骤 3: 参数表单根据方法动态生成
- [ ] 步骤 3: 4 种参数类型输入控件正确
- [ ] 步骤 3: 默认值预填
- [ ] 步骤 3: 验证规则生效（范围、类型、必填）
- [ ] 步骤 3: 无参数方法显示 Info Banner
- [ ] 步骤 4: 摘要信息完整（工作台、方法、参数）
- [ ] 步骤 4: 创建按钮禁用/启用状态正确
- [ ] 创建成功 Toast + 跳转
- [ ] 创建失败 Toast + 保持页面
- [ ] 响应式: Mobile/Tablet/Desktop 布局正确
- [ ] Light/Dark 主题颜色正确
- [ ] 所有文本通过 l10n（无硬编码）
- [ ] 已完成步骤可点击返回
- [ ] 返回后已选数据保持
- [ ] 底部导航按钮状态正确

---

**文档结束**
