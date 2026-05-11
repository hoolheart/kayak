# Figma 原型 - 资源创建对话框更新 (Resource Creation Dialog)

**任务ID**: R2-S2-002-A  
**Figma 文件**: `kayak_r2_teams.fig` > Page: `Resource Creation`  
**设计师**: sw-anna  
**日期**: 2026-05-11  
**状态**: 设计完成  
**适用范围**: Release 2 Sprint 2 — 团队管理前端  
**依赖规范**: `log/release_1/ui/design_spec_v2.md` (Release 1 全局设计规范 v2)  
**影响范围**: 创建工作台、创建方法、创建试验对话框

---

## 1. 设计目标

资源创建对话框更新是在现有创建流程中增加"归属"选择，让用户决定资源是创建在个人空间还是团队空间。设计强调：
- **无缝集成**: 在现有对话框中自然添加归属选择，不破坏原有体验
- **上下文感知**: 默认选中当前工作空间，减少用户操作
- **权限提示**: 在团队空间创建时，提示用户团队成员将能访问
- **一致性**: 所有资源类型（工作台、方法、试验）使用相同的归属选择组件

---

## 2. 对话框布局更新

### 2.1 现有对话框结构

现有创建工作台对话框 (`create_workbench_dialog.md`):

```
Dialog: Create Workbench (Existing)
├── Title: "创建工作台"
├── Content
│   ├── TextField: "名称"
│   └── TextField: "描述"
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "创建"
```

### 2.2 更新后对话框结构

```
Dialog: Create Workbench (Updated)
├── Title: "创建工作台"
├── Content
│   ├── Ownership Section (NEW)
│   │   ├── Section Label: "归属" (Label Medium, On Surface Variant)
│   │   └── Radio Group
│   │       ├── Radio: "个人空间" (default if personal context)
│   │       └── Radio: "[Team Name]" (default if team context, disabled if no teams)
│   ├── Divider (NEW)
│   ├── TextField: "名称"
│   └── TextField: "描述"
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "创建"
```

---

## 3. 组件规格详解

### 3.1 归属选择区域 (Ownership Section)

```
Component: Ownership Selector
├── Section Label
│   └── "归属" (Label Medium, On Surface Variant)
└── Radio Group
    ├── Ownership Option: Personal
    │   ├── Radio (Material Radio)
    │   ├── Leading Icon: account_circle, 20px, Primary
    │   ├── Title: "个人空间" (Body Medium)
    │   └── Subtitle: "仅自己可见" (Body Small, On Surface Variant)
    └── Ownership Option: Team
        ├── Radio (Material Radio)
        ├── Leading Icon: groups, 20px, Primary
        ├── Title: "团队名称" (Body Medium)
        └── Subtitle: "团队成员可访问" (Body Small, On Surface Variant)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Section Padding | 0 0 16px 0 | 0 0 16px 0 |
| Section Gap | 8px | 8px |
| Option Height | 56px | 56px |
| Option Padding | 12px 0 | 12px 0 |
| Option Gap (internal) | 12px | 12px |
| Radio Size | 20px | 20px |
| Radio Active Color | Primary #1976D2 | Primary #90CAF9 |
| Icon Size | 20px | 20px |
| Icon Color | Primary | Primary |
| Title Style | Body Medium (14pt), On Surface | 同左 |
| Subtitle Style | Body Small (12pt), On Surface Variant | 同左 |

**选项布局**:

```
Option Item Layout:
┌─────────────────────────────────────────┐
│ ( )  [icon]  标题文字                     │
│            副标题文字                      │
└─────────────────────────────────────────┘
```

### 3.2 单选项状态

| 状态 | 视觉表现 | 说明 |
|------|---------|------|
| Unselected | Radio 空心圆，标准文字颜色 | 默认未选中 |
| Selected | Radio 实心圆 + 圆点，标题加粗 | 已选中 |
| Hover | 背景出现 4% Primary | 鼠标悬停 |
| Disabled | 38% 透明度 | 无法选择 |

**选中状态样式**:

| 属性 | 值 |
|------|-----|
| Radio Fill | Primary |
| Title FontWeight | w500 (加粗) |
| Background | Primary with 4% opacity |

### 3.3 团队选项禁用状态

当用户不属于任何团队时：

| 属性 | 值 |
|------|-----|
| Radio | Disabled |
| Title | "暂无团队" (Body Medium, On Surface Variant) |
| Subtitle | "加入或创建团队后可选择" (Body Small, On Surface Variant) |
| Opacity | 38% |
| Action | 显示 TextButton "去创建团队" (inline) |

---

### 3.4 多团队选择

当用户属于多个团队时，需要展开选择具体团队：

```
Component: Ownership Selector (Multiple Teams)
├── Section Label: "归属"
└── Radio Group
    ├── Option: Personal
    │   ├── Radio
    │   ├── Icon: account_circle
    │   ├── Title: "个人空间"
    │   └── Subtitle: "仅自己可见"
    └── Option: Team ( expandable )
        ├── Radio
        ├── Icon: groups
        ├── Title: "团队" (当未展开时)
        └── Subtitle: "选择一个团队"
        └── Expanded Team List (when Team radio selected)
            └── Team Sub-options
                ├── Sub-option: "研发团队"
                ├── Sub-option: "QA 测试团队"
                └── Sub-option: "产品团队"
```

**展开的团队列表**:

| 属性 | 值 |
|------|-----|
| Indent | 32px (Radio + Icon 宽度) |
| Background | Surface Container Lowest #FAFAFA (Light) / darkSurfaceContainerLowest #0A0A0A (Dark) |
| Corner Radius | 8px |
| Padding | 8px |
| Gap | 4px |

**子选项样式**:

| 属性 | 值 |
|------|-----|
| Height | 40px |
| Padding | 8px 12px |
| Leading | Circle (8px), Primary, filled if selected |
| Title | Body Medium, On Surface |
| Selected Background | Primary Container |
| Hover Background | Surface Container |

---

### 3.5 权限提示 (Team Context)

当选择团队归属时，显示提示信息：

```
Component: Team Permission Hint
├── Container
│   ├── Icon: info, 16px, Info color
│   ├── Text: "此资源将创建在 [Team Name] 中，团队成员根据其角色拥有相应权限。"
│   │   (Body Small, On Surface Variant)
│   └── Optional Link: "了解团队权限 →" (TextButton, compact)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Info Container #E3F2FD | Info Container #0D47A1 |
| Border | 1px Info #1976D2 | 1px Info #90CAF9 |
| Corner Radius | 8px | 8px |
| Padding | 12px 16px | 12px 16px |
| Icon Color | Info #1976D2 | Info #90CAF9 |
| Text Color | On Surface Variant | On Surface Variant |
| Margin Top | 8px | 8px |

---

## 4. 各资源类型应用

### 4.1 创建工作台对话框

```
Dialog: Create Workbench
├── Title: "创建工作台"
├── Content (Width: 480px)
│   ├── Ownership Section
│   │   ├── Label: "归属"
│   │   ├── Radio: "个人空间"
│   │   └── Radio: "[当前团队]"
│   ├── Permission Hint (if team selected)
│   ├── Divider
│   ├── TextField: "名称" (required)
│   └── TextField: "描述" (optional)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "创建"
```

### 4.2 创建方法对话框

```
Dialog: Create Method
├── Title: "创建方法"
├── Content (Width: 480px)
│   ├── Ownership Section
│   │   ├── Label: "归属"
│   │   ├── Radio: "个人空间"
│   │   └── Radio: "[当前团队]"
│   ├── Permission Hint (if team selected)
│   ├── Divider
│   ├── TextField: "名称" (required)
│   └── TextField: "描述" (optional)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "创建"
```

### 4.3 创建试验对话框

```
Dialog: Create Experiment
├── Title: "创建试验"
├── Content (Width: 480px)
│   ├── Ownership Section
│   │   ├── Label: "归属"
│   │   ├── Radio: "个人空间"
│   │   └── Radio: "[当前团队]"
│   ├── Permission Hint (if team selected)
│   ├── Divider
│   ├── TextField: "名称" (required)
│   ├── TextField: "描述" (optional)
│   └── Dropdown: "关联工作台" (optional)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "创建"
```

---

## 5. 状态设计

### 5.1 默认选中状态

| 当前上下文 | 默认选中 | 说明 |
|-----------|---------|------|
| Personal | "个人空间" | 用户正在个人空间工作 |
| Team A | "Team A" | 用户正在 Team A 上下文工作 |

### 5.2 无团队状态

```
State: No Teams
├── Radio: "个人空间" (selected, enabled)
├── Radio: "团队" (disabled)
│   ├── Title: "暂无团队"
│   └── Subtitle: "加入或创建团队后可选择"
└── Inline Action: TextButton "去创建团队 →"
```

### 5.3 单团队状态

```
State: Single Team
├── Radio: "个人空间" (enabled)
└── Radio: "研发团队" (enabled)
    └── Subtitle: "Owner"
```

### 5.4 多团队状态

```
State: Multiple Teams
├── Radio: "个人空间" (enabled)
└── Radio: "团队" (enabled, expandable)
    └── Subtitle: "3 个团队"
    └── Expanded:
        ├── "研发团队" (sub-option)
        ├── "QA 测试团队" (sub-option)
        └── "产品团队" (sub-option)
```

---

## 6. 交互设计

### 6.1 归属选择交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 选择个人 | 点击 Radio | 选中个人空间 | Radio 填充，提示信息隐藏 |
| 选择团队 | 点击 Radio | 选中团队 | Radio 填充，提示信息出现 |
| 展开团队列表 | 点击团队 Radio (多团队时) | 显示子选项 | 列表展开动画 |
| 选择子团队 | 点击子选项 | 选中具体团队 | 子选项高亮 |
| 悬停选项 | 鼠标移入 | 准备选择 | 背景出现 |

### 6.2 对话框交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 打开对话框 | 点击创建按钮 | 显示对话框 | 对话框从中心缩放出现 |
| 归属变更 | 选择不同归属 | 更新表单状态 | 提示信息显示/隐藏 |
| 提交表单 | 点击创建 | 验证并提交 | 按钮 Loading 状态 |
| 取消 | 点击取消 | 关闭对话框 | 对话框消失 |

---

## 7. 主题变体

### 7.1 浅色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 对话框背景 | #FFFFFF | Surface Container High |
| 选项背景 (悬停) | rgba(25,118,210,0.04) | Primary 4% |
| 选项背景 (选中) | rgba(25,118,210,0.04) | Primary 4% |
| Radio 选中 | #1976D2 | Primary |
| Radio 未选中 | #757575 | On Surface Variant |
| 图标颜色 | #1976D2 | Primary |
| 标题文字 | #212121 | On Surface |
| 副标题文字 | #757575 | On Surface Variant |
| 提示背景 | #E3F2FD | Info Container |
| 提示边框 | #1976D2 | Info |
| 分割线 | #EEEEEE | Outline Variant |

### 7.2 深色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 对话框背景 | #3D3D3D | Surface Container High |
| 选项背景 (悬停) | rgba(144,202,249,0.04) | Primary 4% |
| 选项背景 (选中) | rgba(144,202,249,0.04) | Primary 4% |
| Radio 选中 | #90CAF9 | Primary |
| Radio 未选中 | #9E9E9E | On Surface Variant |
| 图标颜色 | #90CAF9 | Primary |
| 标题文字 | #F5F5F5 | On Surface |
| 副标题文字 | #9E9E9E | On Surface Variant |
| 提示背景 | #0D47A1 | Info Container Dark |
| 提示边框 | #90CAF9 | Info Light |
| 分割线 | #333333 | Outline Variant |

---

## 8. 响应式规则

### 8.1 桌面端 (>= 1280px)

- 对话框宽度: 480px
- 归属选项水平排列 (Radio + Icon + Text)
- 多团队展开列表在选项下方

### 8.2 平板端 (>= 768px and < 1280px)

- 对话框宽度: 480px
- 与桌面端相同

### 8.3 小屏 (< 768px)

- 对话框宽度: 100% (全屏对话框)
- 归属选项垂直排列
- 多团队展开列表全宽

---

## 9. 动画与动效

### 9.1 归属选择动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| Radio 选中 | 150ms | ease-in-out | 圆点从中心放大 |
| 选项悬停 | 100ms | ease-out | 背景色淡入 |
| 提示出现 | 200ms | decelerate | 高度从 0 展开 + 淡入 |
| 提示消失 | 150ms | accelerate | 高度收缩 + 淡出 |
| 团队列表展开 | 200ms | decelerate | 高度变化 + 子选项淡入 |

### 9.2 对话框动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 对话框出现 | 200ms | decelerate | 缩放 + 淡入 |
| 对话框消失 | 150ms | accelerate | 缩放 + 淡出 |
| 按钮 Loading | instant | — | 文字替换为 Spinner |

---

## 10. 设计笔记

### 10.1 关键设计决策

1. **使用 Radio 而非 Dropdown**:
   - 归属选择只有 2-3 个选项，Radio 更直观
   - 减少一次点击（Dropdown 需要点击展开）
   - 所有选项可见，用户一目了然

2. **归属选择放在表单最上方**:
   - 这是最高层级的决策，影响资源的归属
   - 放在名称/描述之前，符合从上到下填写表单的习惯
   - 与 "先选择上下文，再创建内容" 的心理模型一致

3. **默认选中当前上下文**:
   - 如果用户在团队 A 的上下文中点击"创建"，默认选中团队 A
   - 减少 90% 场景下的用户操作
   - 用户仍然可以手动切换到个人空间

4. **权限提示信息**:
   - 当选择团队时显示提示，让用户意识到资源的可见性
   - 避免用户误将敏感资源创建在团队中
   - 使用 Info 级别的提示（非 Warning），不阻碍操作

5. **多团队时使用子选项**:
   - 避免 Radio 列表过长
   - 先选择"团队"类别，再选择具体团队
   - 与"个人 vs 团队"的二元选择保持一致

### 10.2 可访问性考量

- Radio 组件使用 Flutter 原生 Radio，支持屏幕阅读器
- 选项有明确的标签和描述
- 提示信息使用 info 图标，色盲用户也能识别
- 键盘导航: Tab 在选项间移动，Space 选中

### 10.3 与现有设计的关系

- 对话框复用现有 `Standard Dialog` 规范 (28px 圆角)
- 输入框复用现有 `Filled Text Field` 规范
- Radio 复用 Material Design 3 Radio 组件
- 按钮复用现有按钮规范
- 新增归属选择区域为本次扩展

### 10.4 图标映射

| 功能 | 图标名称 | 来源 |
|------|---------|------|
| 个人空间 | account_circle | Material Symbols |
| 团队 | groups | Material Symbols |
| 提示信息 | info | Material Symbols |
| 创建 | add | Material Symbols |
| 了解更多 | arrow_forward | Material Symbols |

### 10.5 后端字段映射

```dart
// 创建请求体新增字段
{
  "name": "工作台名称",
  "description": "描述",
  "ownership": {
    "type": "personal" | "team",
    "team_id": "uuid" // 当 type 为 team 时必填
  }
}
```

---

**文档结束**
