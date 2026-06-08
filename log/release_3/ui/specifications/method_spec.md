# TASK-025: 方法列表 + 编辑页 UI 设计规范

> **路由**: `/methods`（列表）、`/methods/:id/edit`（创建/编辑）  
> **依赖**: TASK-007（可复用组件库）  
> **设计师**: sw-anna  
> **日期**: 2026-06-08  
> **状态**: 设计稿完成

---

## 目录

1. [页面布局](#1-页面布局)
   - 1.1 MethodListPage 整体结构
   - 1.2 MethodEditPage 整体结构
2. [组件规格](#2-组件规格)
   - 2.1 方法卡片（MethodCard）
   - 2.2 搜索栏（SearchBar）
   - 2.3 空状态 / 加载 / 错误
   - 2.4 基本信息表单（BasicInfoSection）
   - 2.5 JSON 过程定义编辑器（JsonEditor）
   - 2.6 参数表（ParameterTable）
   - 2.7 参数编辑对话框（ParameterDialog）
   - 2.8 底部操作栏（BottomActionBar）
   - 2.9 未保存更改对话框
3. [交互状态](#3-交互状态)
4. [响应式适配](#4-响应式适配)
5. [主题适配](#5-主题适配)
6. [动画参数](#6-动画参数)
7. [设计 QA 检查项](#7-设计-qa-检查项)

---

## 1. 页面布局

### 1.1 MethodListPage 整体结构

```
MethodListPage
├── AppBar (64px)
│   ├── Title: "方法" (Title Large)
│   └── Primary Button: "+ 新建方法" (高度 40px)
├── Search Bar (最小 56px)
│   └── Search TextField + 清除按钮
├── Content Area (padding: spaceMd 16px)
│   ├── [Loading] → Skeleton Card Grid (按断点 3/4/6 张)
│   ├── [Error]   → ErrorView + 重试按钮
│   ├── [Empty]   → EmptyView (图标 + 引导 + 新建按钮)
│   ├── [SearchEmpty] → EmptyView (search_off 图标 + 清除搜索)
│   └── [Data]    → Responsive Card Grid (桌面 3 列 / 平板 2 列 / 移动 1 列)
└── (无分页，当前设计一次性加载全部方法，未来可扩展)
```

### 1.2 MethodEditPage 整体结构

```
MethodEditPage
├── AppBar (64px)
│   ├── Back Button (Icons.arrow_back)
│   ├── Title: "新建方法" / "编辑方法" (Title Large)
│   └── Actions: [验证状态标签] [保存按钮]
├── Body (Scrollable, max-width 960px 居中)
│   ├── Section 1: 基本信息
│   │   ├── 方法名称 * (TextFormField)
│   │   └── 方法描述 (TextFormField, multiline)
│   ├── Section 2: 过程定义 (JSON)
│   │   ├── Section Header (标题 + 验证徽章)
│   │   ├── JsonEditor (行号 + 等宽字体 + 语法标红)
│   │   └── Validation Message
│   ├── Section 3: 参数列表
│   │   ├── Section Header (标题 + "+ 添加参数" 按钮)
│   │   ├── ParameterTable (桌面) / ParameterCardList (移动)
│   │   └── Parameter Empty State
│   └── Bottom Action Bar (粘性底部或表单末尾)
│       ├── [验证] Outlined Button
│       └── [保存] Filled Button (未有效/未改动时禁用)
└── UnsavedChangesDialog (离开页面前触发)
```

### 1.3 布局参数

| 属性 | 值 |
|------|-----|
| Page Background | Background color token |
| Content Padding | spaceMd (16px)，桌面可扩展至 spaceLg (24px) |
| List Max Width | 无限制（卡片网格流体） |
| Edit Form Max Width | 960px 居中（桌面），100%（移动） |
| Section Spacing | spaceLg (24px) |
| 卡片网格间距 | spaceMd (16px) |

---

## 2. 组件规格

### 2.1 方法卡片（MethodCard）

#### 用途

列表页核心展示单元，汇总方法的关键元信息，支持点击进入编辑。

#### 视觉结构

```
┌─────────────────────────────────────────┐
│ 方法名称                     [编辑] [删除]│  ← Header
│                                         │
│ 这是一段方法的描述，最多显示两行，        │  ← Description
│ 超出部分以省略号结尾...                   │
│                                         │
│ ┌────────┐           创建于 2026-05-31  │  ← Footer
│ │ 5 参数 │           14:30             │
│ └────────┘                              │
└─────────────────────────────────────────┘
```

#### 卡片规格

| 属性 | 值 |
|------|-----|
| 背景 | Surface Container Highest（与全局 CardTheme 一致） |
| 圆角 | radiusLarge (12px) |
| 内边距 | spaceMd (16px) |
| 阴影 | Elevation 1（默认），Elevation 2（Hover） |
| 最小高度 | 136px |
| 点击热区 | 整张卡片除操作按钮外均可点击 |

#### 卡片内容

| 元素 | 样式 |
|------|------|
| 方法名称 | Title Medium (16px, 500)，On Background，单行省略 |
| 描述摘要 | Body Medium (14px, 400)，On Surface Variant，最多 2 行，溢出省略 |
| 参数数量 | AssistChip，高度 28px，Label Small (11px)，Primary 容器色 |
| 创建时间 | Body Small (12px)，On Surface Variant，右对齐 |
| 操作按钮 | IconButton (编辑：`Icons.edit_outlined`，删除：`Icons.delete_outlined`) |

#### 参数数量徽章

```
┌──────────┐
│  tune    │  5 参数
│  16px    │
└──────────┘
```

| 属性 | 值 |
|------|-----|
| 组件 | AssistChip |
| 高度 | 28px |
| 图标 | `Icons.tune`，16px，On Primary Container |
| 文字 | Label Small，On Primary Container |
| 背景 | Primary Container |
| 图标与文字间距 | 4px |

#### 卡片状态

| 状态 | 视觉表现 |
|------|----------|
| **Default** | Elevation 1，Surface Container Highest |
| **Hover** | Elevation 2，背景 On Surface 4% 叠加 |
| **Pressed** | Elevation 1，Scale 0.995 |
| **Focused** | 2px Primary 外框（键盘 Tab 导航） |

#### 操作按钮交互

| 按钮 | 图标 | 颜色 | 触发 |
|------|------|------|------|
| 编辑 | `edit_outlined` | Primary | 导航到 `/methods/{id}/edit` |
| 删除 | `delete_outlined` | Error | 弹出 ConfirmDialog 危险确认 |

---

### 2.2 搜索栏（SearchBar）

#### 布局结构

```
┌──────────────────────────────────────────────────────────────────────┐
│ [search] 搜索方法名称或描述...                            [clear]   │
└──────────────────────────────────────────────────────────────────────┘
```

#### 搜索栏规格

| 属性 | 值 |
|------|-----|
| 容器背景 | Surface |
| 内边距 | spaceMd (16px) |
| 底部边框 | 1px Outline Variant |
| 输入框 | Outlined TextField，高度 48px |
| 前缀图标 | `Icons.search`，20px，On Surface Variant |
| 后缀图标 | `Icons.clear`，20px（有内容时显示） |
| 占位文字 | "搜索方法名称或描述"，Body Medium，On Surface Variant 60% |
| 圆角 | radiusMedium (8px) |

#### 交互

| 操作 | 反馈 |
|------|------|
| 输入关键词 | 本地实时过滤方法列表（debounce 200ms） |
| 点击清除 | 清空搜索框，恢复完整列表 |
| 搜索无结果 | 显示 SearchEmpty 状态 |
| 空搜索框 | 显示完整列表或原始 Empty 状态 |

---

### 2.3 空状态 / 加载 / 错误

#### 2.3.1 原始空状态

使用 EmptyView 组件：

| 属性 | 值 |
|------|-----|
| 图标 | `Icons.science_outlined`，48px |
| 标题 | "暂无方法" |
| 描述 | "点击下方按钮创建您的第一个方法" |
| 操作按钮 | Filled Button "创建第一个方法" |

#### 2.3.2 搜索无结果状态

| 属性 | 值 |
|------|-----|
| 图标 | `Icons.search_off`，48px |
| 标题 | "未找到匹配的方法" |
| 描述 | "请尝试其他关键词" |
| 操作按钮 | Text Button "清除搜索" |

#### 2.3.3 加载状态

使用 Skeleton 组件（type: card）：

| 属性 | 值 |
|------|-----|
| 占位卡片数 | 移动端 3 张 / 平板 4 张 / 桌面 6 张 |
| 卡片骨架结构 | 标题行 + 2 行描述 + 底部徽章/日期 |
| 动画 | Skeleton shimmer，1.5s 循环 |
| 新建按钮 | 禁用，38% 不透明度 |

#### 2.3.4 错误状态

使用 ErrorView 组件：

| 属性 | 值 |
|------|-----|
| 图标 | `Icons.error_outline_outlined`，48px |
| 标题 | "加载方法列表失败" |
| 描述 | "请检查网络连接后点击重试" |
| 操作按钮 | Filled Button "重试" |

---

### 2.4 基本信息表单（BasicInfoSection）

#### 布局结构

```
┌──────────────────────────────────────────────────────────────────────┐
│ 基本信息                                                             │  ← Section Title
├──────────────────────────────────────────────────────────────────────┤
│ 方法名称 *                                                           │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 拉伸强度测试方法                                                   │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ 方法描述                                                             │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 用于测试材料在标准拉伸条件下的力       │
│ │ 学性能指标。                                                         │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

#### Section 标题规格

| 属性 | 值 |
|------|-----|
| 文字 | "基本信息" / "过程定义 (JSON)" / "参数列表" |
| 样式 | Title Small (14px, 500)，On Background |
| 下边距 | spaceSm (8px) |

#### 名称输入框

| 属性 | 值 |
|------|-----|
| 标签 | "方法名称 *" |
| 必填 | 是 |
| 最大长度 | 64 字符 |
| 验证规则 | 非空、去首尾空格后不少于 2 字符 |
| 错误提示 | "请输入方法名称（至少 2 个字符）" |
| 组件 | TextFormField (Outlined) |

#### 描述输入框

| 属性 | 值 |
|------|-----|
| 标签 | "方法描述" |
| 必填 | 否 |
| 最大长度 | 256 字符 |
| 行数 | min 2 行，max 3 行 |
| 组件 | TextFormField (Outlined, multiline) |

---

### 2.5 JSON 过程定义编辑器（JsonEditor）

#### 用途

供用户直接编辑方法的过程定义 JSON。要求等宽字体、行号、语法标红（错误高亮）。

#### 视觉结构

```
┌──────────────────────────────────────────────────────────────────────┐
│ 过程定义 (JSON)                              [✓ JSON 格式正确]      │  ← Header
├──────────────────────────────────────────────────────────────────────┤
│  1 │ {                                                              │
│  2 │   "steps": [                                                   │
│  3 │     {                                                          │
│  4 │       "type": "hold",                                          │
│  5 │       "duration": 300                                          │
│  6 │     },                                                         │
│  7 │     {                                                          │
│  8 │       "type": "ramp",                                          │
│  9 │       "target": 100.0                                          │
│ 10 │     }                                                          │
│ 11 │   ]                                                            │
│ 12 │ }                                                              │
├──────────────────────────────────────────────────────────────────────┤
│ 行数: 12 | 字符数: 187                                               │  ← Footer
└──────────────────────────────────────────────────────────────────────┘
```

#### 编辑器容器规格

| 属性 | 值 |
|------|-----|
| 背景 | Surface Container Highest |
| 圆角 | radiusLarge (12px) |
| 边框 | 1px Outline Variant |
| Focus 边框 | 2px Primary |
| 最小高度 | 240px |
| 最大高度 | 480px（超出滚动） |
| 内边距 | 0（编辑器自身处理） |

#### 行号区（Gutter）

| 属性 | 值 |
|------|-----|
| 宽度 | 48px 固定（随位数自适配最小 40px） |
| 背景 | Surface Variant at 30% |
| 文字 | 等宽字体，12px，On Surface Variant 60% |
| 对齐 | 右对齐，右内边距 12px |
| 当前行高亮 | Primary Container at 30%（光标所在行） |

#### 编辑区

| 属性 | 值 |
|------|-----|
| 字体 | 等宽字体（优先 `Roboto Mono`，回退 `ui-monospace, monospace`） |
| 字号 | 14px |
| 行高 | 20px |
| 字重 | 400 |
| 文字颜色 | On Surface |
| 光标颜色 | Primary |
| 选中背景 | Primary at 30% |
| Tab 宽度 | 2 个空格（软空格） |

#### 语法高亮（最小集）

| Token | 颜色 (Light) | 颜色 (Dark) |
|-------|--------------|-------------|
| Key（对象键） | Primary (`#1976D2`) | Primary (`#90CAF9`) |
| String | Success (`#2E7D32`) | Success (`#81C784`) |
| Number | Secondary / Tertiary (`#006780`) | Secondary (`#5DD4FC`) |
| Boolean / null | Warning (`#ED6C02`) | Warning (`#FFB74D`) |
| Bracket / punctuation | On Surface Variant |
| 注释（如支持） | On Surface Variant 60% |

#### 错误高亮

| 状态 | 视觉表现 |
|------|----------|
| **JSON 语法无效** | 错误行背景 Error at 8%，错误 token 下方红色波浪线 |
| **错误提示条** | Footer 左侧显示 Error icon + "JSON 格式错误：第 X 行，..." |
| **Header 徽章** | 无效时显示 Error 色 "JSON 格式错误" Chip |
| **保存影响** | JSON 无效时禁用保存按钮 |

#### Footer 规格

| 属性 | 值 |
|------|-----|
| 高度 | 36px |
| 背景 | Surface Variant at 20% |
| 左侧 | 行数 + 字符数统计，Label Small |
| 右侧 | 验证状态（Valid: 绿色勾选 + "JSON 格式正确" / Invalid: 红色错误图标 + 错误信息） |

#### Header 验证徽章

| 状态 | 样式 |
|------|------|
| Valid | `Icons.check_circle`，Success 色，文字 "JSON 格式正确" |
| Invalid | `Icons.error`，Error 色，文字 "JSON 格式错误" |
| Neutral（未编辑/空） | 不显示徽章 |

---

### 2.6 参数表（ParameterTable）

#### 用途

管理方法的输入参数定义（CRUD）。参数用于动态生成试验配置表单。

#### 桌面端表格结构

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ 参数键      │ 显示标签  │ 类型   │ 必填 │ 默认值   │ 单位 │ 描述      │ 操作      │
├─────────────┼───────────┼────────┼──────┼──────────┼──────┼───────────┼───────────┤
│ load        │ 载荷      │ 数值   │ 是   │ 0.0      │ kN   │ 初始载荷  │ [编] [删] │
│ duration    │ 保持时间  │ 整数   │ 否   │ 300      │ s    │ 保持时长  │ [编] [删] │
│ sample_id   │ 样品编号  │ 字符串 │ 是   │ —        │ —    │ 样品标识  │ [编] [删] │
│ use_filter  │ 启用滤波  │ 布尔   │ 否   │ true     │ —    │ 是否滤波  │ [编] [删] │
│ mode        │ 运行模式  │ 枚举   │ 是   │ standard │ —    │ 工作模式  │ [编] [删] │
└─────────────┴───────────┴────────┴──────┴──────────┴──────┴───────────┴───────────┘
```

#### 列定义

| 列名 | 宽度 | 对齐 | 内容 |
|------|------|------|------|
| 参数键 | 120px | 左对齐 | Body Medium，等宽字体推荐 |
| 显示标签 | 120px | 左对齐 | Body Medium |
| 类型 | 80px | 居中 | TypeChip |
| 必填 | 64px | 居中 | Switch（只读展示）或 勾选图标 |
| 默认值 | 120px | 左对齐 | Body Medium，On Surface Variant |
| 单位 | 80px | 左对齐 | Body Small，On Surface Variant |
| 描述 | flex: 1 | 左对齐 | Body Small，On Surface Variant，单行省略 |
| 操作 | 80px | 右对齐 | IconButton 组 |

#### 参数类型徽章（TypeChip）

| 类型 | 显示文字 | 颜色 |
|------|----------|------|
| number | 数值 | Primary Container，On Primary Container |
| integer | 整数 | Primary Container，On Primary Container |
| string | 字符串 | Tertiary Container，On Tertiary Container |
| boolean | 布尔 | Secondary Container，On Secondary Container |
| enum | 枚举 | Success Container，On Success Container |

#### 表格状态

| 状态 | 视觉表现 |
|------|----------|
| Default | 透明背景 |
| Hover | On Surface 4% 背景 |
| 聚焦行 | Primary 8% 背景 |

#### 操作按钮

| 按钮 | 图标 | 颜色 | 触发 |
|------|------|------|------|
| 编辑 | `Icons.edit_outlined` | Primary | 打开 ParameterDialog（编辑模式） |
| 删除 | `Icons.delete_outlined` | Error | ConfirmDialog 确认后删除 |

#### 移动端参数卡片

```
┌─────────────────────────────────────────┐
│ 载荷 (load)                  [编] [删]  │
│                                         │
│ 类型: 数值                必填: ●       │
│ 默认值: 0.0             单位: kN        │
│ 描述: 初始载荷大小                       │
└─────────────────────────────────────────┘
```

---

### 2.7 参数编辑对话框（ParameterDialog）

#### 用途

添加/编辑单个方法参数。字段根据参数类型动态显示。

#### 桌面端对话框布局

```
┌─────────────────────────────────────────────┐
│ 添加参数                          [X]       │
├─────────────────────────────────────────────┤
│ 参数键 *                                      │
│ ┌─────────────────────────────────────────┐ │
│ │ load                                    │ │
│ └─────────────────────────────────────────┘ │
│                                              │
│ 显示标签                                      │
│ ┌─────────────────────────────────────────┐ │
│ │ 载荷                                    │ │
│ └─────────────────────────────────────────┘ │
│                                              │
│ 参数类型 *         是否必填                   │
│ ┌──────────────┐   ┌─────────────────────┐  │
│ │ 数值       ▼ │   │  [ ] 必填           │  │
│ └──────────────┘   └─────────────────────┘  │
│                                              │
│ 单位                                          │
│ ┌─────────────────────────────────────────┐ │
│ │ kN                                      │ │
│ └─────────────────────────────────────────┘ │
│                                              │
│ 最小值            最大值                      │
│ ┌──────────┐      ┌──────────┐              │
│ │ 0.0      │      │ 1000.0   │              │
│ └──────────┘      └──────────┘              │
│                                              │
│ 默认值                                        │
│ ┌─────────────────────────────────────────┐ │
│ │ 0.0                                     │ │
│ └─────────────────────────────────────────┘ │
│                                              │
│ 描述                                          │
│ ┌─────────────────────────────────────────┐ │
│ │ 初始载荷大小                            │ │
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│          [取消]    [保存]                   │
└─────────────────────────────────────────────┘
```

#### 对话框规格

| 属性 | 值 |
|------|-----|
| 宽度 | 桌面：560px / 移动：100% 贴底 Sheet |
| 圆角 | radiusLarge (12px) / 移动：顶部 16px |
| 标题 | Title Medium |
| 内边距 | spaceLg (24px) |
| 按钮区 | 右对齐，间距 spaceSm (8px) |

#### 字段规格

| 字段 | 必填 | 组件 | 规则 |
|------|------|------|------|
| 参数键 | 是 | TextFormField | 仅允许 `a-zA-Z0-9_`，首字符不能为数字，唯一性校验 |
| 显示标签 | 否 | TextFormField | 默认等于参数键 |
| 参数类型 | 是 | DropdownButtonFormField | 选项：number / integer / string / boolean / enum |
| 是否必填 | 否 | SwitchListTile | 默认 false |
| 单位 | 否 | TextFormField | 仅 number/integer 类型显示 |
| 最小值 | 否 | TextFormField (number) | 仅 number/integer 类型显示 |
| 最大值 | 否 | TextFormField (number) | 仅 number/integer 类型显示，需 >= 最小值 |
| 枚举选项 | 否 | Chip Input | 仅 enum 类型显示，至少 1 项 |
| 默认值 | 否 | 动态控件 | 根据类型变化：number/integer/string 用 TextField；boolean 用 Switch；enum 用 Dropdown |
| 描述 | 否 | TextFormField (multiline) | max 128 字符 |

#### 动态字段显示规则

```
if type in [number, integer]:
    显示：单位、最小值、最大值
    默认值输入框限制为数字键盘
elif type == boolean:
    默认值显示为 Switch
    隐藏：单位、最小值、最大值、枚举选项
elif type == enum:
    显示：枚举选项（Chip Input）
    默认值显示为 Dropdown（选项来自枚举选项）
    隐藏：单位、最小值、最大值
else (string):
    隐藏：单位、最小值、最大值、枚举选项
```

#### 验证规则

| 规则 | 错误提示 |
|------|----------|
| 参数键非空 | "请输入参数键" |
| 参数键格式 | "参数键只能包含字母、数字和下划线，且不能以数字开头" |
| 参数键唯一 | "参数键已存在" |
| 最小值 <= 最大值 | "最大值不能小于最小值" |
| 默认值在范围内 | "默认值必须在最小值和最大值之间" |
| enum 至少 1 个选项 | "枚举类型至少需要一个选项" |
| 默认值匹配类型 | "默认值格式与参数类型不符" |

---

### 2.8 底部操作栏（BottomActionBar）

#### 布局结构

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                         [验证] [保存] │
└──────────────────────────────────────────────────────────────────────┘
```

#### 规格

| 属性 | 值 |
|------|-----|
| 位置 | 表单末尾（桌面）/ 粘性底部（移动） |
| 高度 | 64px |
| 背景 | Surface |
| 顶部边框 | 1px Outline Variant |
| 内边距 | 水平 spaceMd (16px) |
| 对齐 | 右对齐，按钮间距 spaceSm (8px) |

#### 按钮状态

| 按钮 | 默认 | 验证失败 | 未改动 | 保存中 |
|------|------|----------|--------|--------|
| 验证 | Outlined，Primary | 可用 | 可用 | 显示加载指示器 |
| 保存 | Filled，Primary | 禁用 | 禁用 | 显示加载指示器，文字变 "保存中..." |

---

### 2.9 未保存更改对话框

#### 用途

用户尝试离开编辑页时，若存在未保存更改，阻断并提示。

#### 视觉结构

```
            ┌─────────────────────────────────────────┐
            │  有未保存的更改                         │
            │                                         │
            │  离开此页面将丢失未保存的更改。         │
            │  是否继续？                             │
            │                                         │
            │  [留在页面]        [继续离开]           │
            └─────────────────────────────────────────┘
```

#### 规格

| 属性 | 值 |
|------|-----|
| 类型 | ConfirmDialog |
| 标题 | "有未保存的更改" |
| 描述 | "离开此页面将丢失未保存的更改。是否继续？" |
| 主按钮 | "留在页面"（Filled，Primary） |
| 次按钮 | "继续离开"（Text Button） |
| 触发条件 | 表单 dirty == true 且用户点击返回/导航到其它页面/刷新 |

---

## 3. 交互状态

### 3.1 方法列表页状态流转

```
初始加载
  → Loading (Skeleton Card Grid)
    → 成功
      → 有数据 → Data (Card Grid)
      → 无数据 → Empty
    → 失败 → Error (ErrorView)

搜索操作
  Data ──(搜索无结果)──→ SearchEmpty
  SearchEmpty ──(清除搜索)──→ Data / Empty
```

### 3.2 方法编辑页状态流转

```
进入页面
  → 新建：空白表单，Neutral 验证状态
  → 编辑：API 加载 → Skeleton（页面级）→ 回填数据 → Valid 验证状态

编辑过程
  任何字段变化 → dirty = true
  JSON 输入变化 → 触发语法校验（debounce 500ms）
  参数表变化 → dirty = true

验证操作
  → 客户端校验名称/JSON/参数
  → 通过：Header 徽章变 Valid，Footer 显示 "JSON 格式正确"
  → 失败：Header 徽章变 Invalid，Footer 显示具体错误，保存禁用

保存操作
  → 点击保存
  → 再次全量校验
  → 校验失败：Inline error + Toast Error
  → 校验通过：API 调用 → Loading → 成功 Toast + 导航回列表
  → API 失败：Toast Error，保留表单状态

离开页面
  dirty == true → 弹出 UnsavedChangesDialog
  dirty == false → 直接离开
```

### 3.3 操作交互矩阵

| 操作 | 触发 | 反馈 |
|------|------|------|
| 点击新建方法 | 列表页 AppBar | 导航到 `/methods/new/edit` |
| 点击卡片 | 列表页卡片 | 导航到 `/methods/{id}/edit` |
| 搜索输入 | SearchBar | 实时过滤，debounce 200ms |
| 清除搜索 | SearchBar 清除图标 | 清空输入，恢复完整列表 |
| 编辑方法 | 卡片编辑按钮 | 同上 |
| 删除方法 | 卡片删除按钮 | ConfirmDialog → API → Toast → 刷新列表 |
| 添加参数 | 编辑页 "+ 添加参数" | 打开 ParameterDialog（新增模式） |
| 编辑参数 | 表格/卡片编辑按钮 | 打开 ParameterDialog（编辑模式） |
| 删除参数 | 表格/卡片删除按钮 | ConfirmDialog → 从列表移除 |
| 验证 | 底部 "验证" 按钮 | 全量校验，更新徽章和 Footer |
| 保存 | 底部 "保存" 按钮 | 校验 → API → Toast → 返回列表 |
| 返回/离开 | AppBar 返回或浏览器返回 | dirty 时弹出 UnsavedChangesDialog |

---

## 4. 响应式适配

### 4.1 断点定义

| 断点 | 宽度 | 列表布局 | 编辑页布局 | 参数对话框 |
|------|------|----------|------------|------------|
| Mobile | < 600px | 1 列卡片 | 全宽，底部粘性操作栏 | Bottom Sheet |
| Tablet | 600-1024px | 2 列卡片 | 全宽/留边距 | 居中 Dialog |
| Desktop | > 1024px | 3 列卡片 | max-width 960px 居中 | 居中 Dialog |

### 4.2 列表页响应式详情

**Mobile (< 600px):**
- 新建按钮简化为 AppBar IconButton (`Icons.add`)
- 搜索框全宽
- 卡片单列，全宽
- 操作按钮在卡片内显示为 IconButton

**Tablet (600-1024px):**
- 新建按钮显示为 Filled Button
- 卡片 2 列网格
- 卡片内边距保持 16px

**Desktop (> 1024px):**
- 卡片 3 列网格，最大列宽 400px
- 网格间距 16px
- 页面内容区两侧留白随屏幕扩展

### 4.3 编辑页响应式详情

**Mobile (< 600px):**
- 表单区 padding 16px
- Section 标题左对齐，字号不变
- JSON Editor 最小高度 200px
- 底部操作栏粘性定位，保存/验证按钮全宽或等分
- 参数表变为 ParameterCardList

**Tablet/Desktop:**
- 表单区 max-width 960px 居中
- 左右 padding 24px-48px
- 底部操作栏位于表单末尾，右对齐
- 参数表使用 DataTable

---

## 5. 主题适配

### 5.1 颜色

| 元素 | Light Theme | Dark Theme |
|------|------------|------------|
| Page Background | Background (#FDFCFF) | Background (#1A1C1E) |
| Surface | Surface (#FFFFFF) | Surface (#1A1C1E) |
| Card Background | Surface Container Highest | Surface Container Highest (Dark) |
| Section Title | On Background | On Background |
| Divider | Outline Variant | Outline Variant |
| Editor Background | Surface Container Highest | Surface Container Highest |
| Gutter Background | Surface Variant 30% | Surface Variant 30% |
| Gutter Text | On Surface Variant 60% | On Surface Variant 60% |
| Valid Badge | Success | Success |
| Invalid Badge | Error | Error |
| Error Underline | Error | Error |
| Error Row BG | Error 8% | Error 8% |

### 5.2 参数类型徽章颜色

| 类型 | Light 背景 | Light 文字 | Dark 背景 | Dark 文字 |
|------|-----------|------------|-----------|-----------|
| number / integer | Primary Container | On Primary Container | Primary Container Dark | On Primary Container Dark |
| string | Tertiary Container | On Tertiary Container | Tertiary Container Dark | On Tertiary Container Dark |
| boolean | Secondary Container | On Secondary Container | Secondary Container Dark | On Secondary Container Dark |
| enum | Success Container | On Success Container | Success Container Dark | On Success Container Dark |

---

## 6. 动画参数

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面进入 | 200ms | ease-out | Fade + Slide |
| 卡片 Hover | 150ms | ease-out | Elevation 变化 |
| 卡片进入（列表加载） | 200ms stagger 30ms | ease-out | 依次淡入 |
| 搜索过滤 | 200ms | ease-in-out | 列表 Fade + 新结果 Fade In |
| Skeleton shimmer | 1.5s 循环 | linear | 光泽扫过 |
| JSON 验证反馈 | 200ms | ease-out | Header 徽章切换 |
| 错误行高亮 | 150ms | ease-out | 背景色过渡 |
| Dialog 进入 | 200ms | ease-out | Scale/Fade（桌面）/ 底部滑入（移动） |
| Dialog 离开 | 150ms | ease-in | 反向 |
| Toast | 300ms | ease-out | 滑入 |
| 参数表行删除 | 200ms | ease-in | 高度收缩 + Fade |
| 未保存对话框弹出 | 200ms | ease-out | 遮罩淡入 + 对话框缩放 |

---

## 7. 设计 QA 检查项

### 7.1 通用检查

- [ ] 所有颜色与 Design Token 完全一致
- [ ] Light/Dark 主题切换颜色正确
- [ ] 组件间距符合 8px 网格系统
- [ ] 圆角一致（按组件规范）
- [ ] 阴影层级正确
- [ ] 动画时长和缓动符合规范

### 7.2 方法列表页检查

- [ ] 三态完整：Loading (Skeleton) / Error (ErrorView) / Empty (EmptyView) / Data (Card Grid)
- [ ] 搜索栏实时过滤有效（debounce 200ms）
- [ ] 搜索无结果时显示 SearchEmpty 状态
- [ ] 卡片内容完整：名称、描述（2 行）、参数数量、创建时间
- [ ] 卡片 Hover 提升 Elevation
- [ ] 编辑/删除按钮可操作
- [ ] 删除方法前弹出 ConfirmDialog
- [ ] 新建方法导航正确
- [ ] 空状态有引导操作（创建按钮）

### 7.3 方法编辑页检查

- [ ] 新建/编辑标题正确切换
- [ ] 基本信息表单字段完整（名称必填、描述多行）
- [ ] JSON 编辑器使用等宽字体
- [ ] JSON 编辑器显示行号
- [ ] JSON 语法错误时标红（错误行背景 + 波浪线 + Footer 提示）
- [ ] JSON 正确时显示绿色验证徽章
- [ ] 参数表 CRUD 完整
- [ ] 参数类型徽章颜色正确
- [ ] 参数编辑对话框字段根据类型动态显示/隐藏
- [ ] 参数键唯一性校验
- [ ] 底部保存按钮在未校验通过/未改动时禁用
- [ ] 验证按钮触发全量校验

### 7.4 响应式检查

- [ ] Mobile (< 600px): 列表 1 列卡片，编辑页全宽，参数对话框为 Bottom Sheet
- [ ] Tablet (600-1024px): 列表 2 列，编辑页留边距
- [ ] Desktop (> 1024px): 列表 3 列，编辑页 max-width 960px 居中
- [ ] 移动端 JSON 编辑器高度自适应，仍可滚动

### 7.5 无障碍检查

- [ ] 所有输入框有正确的 Label
- [ ] JSON 编辑器错误信息可被屏幕阅读器朗读
- [ ] 参数表可通过键盘 Tab 导航
- [ ] 操作按钮有 Tooltip/aria-label
- [ ] 未保存更改对话框焦点锁定在对话框内
- [ ] 颜色对比度符合 WCAG AA
- [ ] 减少动效设置下禁用所有过渡动画

---

## 修订记录

### Rev.1 — 2026-06-08 (sw-anna)
**初始版本**
- 定义方法列表页卡片网格布局、搜索、三态
- 定义方法编辑页表单、JSON 编辑器、参数表 CRUD、未保存提示
- 对齐既有 Material 3 设计系统和 TASK-007 可复用组件

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。
