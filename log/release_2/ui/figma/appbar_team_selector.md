# Figma 原型 - AppBar 团队选择器 (AppBar Team Selector)

**任务ID**: R2-S2-002-A  
**Figma 文件**: `kayak_r2_teams.fig` > Page: `AppBar Team Selector`  
**设计师**: sw-anna  
**日期**: 2026-05-11  
**状态**: 设计完成  
**适用范围**: Release 2 Sprint 2 — 团队管理前端  
**依赖规范**: `log/release_1/ui/design_spec_v2.md` (Release 1 全局设计规范 v2)  
**位置**: AppBar 标题区域右侧（或左侧，根据布局）

---

## 1. 设计目标

AppBar 团队选择器是全局上下文切换的核心组件，让用户在不离开当前页面的情况下快速切换"个人"和"团队"工作空间。设计强调：
- **上下文感知**: 明确显示当前所在的工作空间
- **快速切换**: 一键切换，无需页面跳转
- **全局影响**: 切换后影响所有资源创建和列表视图
- **最小干扰**: 不占用过多 AppBar 空间

---

## 2. 组件位置

### 2.1 AppBar 布局更新

```
AppBar (existing)
├── Leading (optional back button)
├── Title Area
│   ├── Page Title (e.g., "工作台")
│   └── Team Selector (NEW) — positioned right of title or in actions
├── Actions
│   ├── [Existing actions...]
│   └── [Team Selector could be here]
└── Bottom (optional TabBar)
```

**推荐位置**: AppBar 标题右侧，通过垂直分隔线与标题分隔。

```
Title Area:
┌─────────────────────────────────────────┐
│ 工作台  │  ▼ 个人空间                    │
│         │  ▼ 研发团队                    │
│         │  ▼ QA 测试团队                 │
└─────────────────────────────────────────┘
```

---

## 3. 组件规格详解

### 3.1 团队选择器按钮 (Team Selector Button)

```
Component: Team Selector Button
├── Container (InkWell)
│   ├── Leading Icon
│   │   └── Icon: account_circle (Personal) / groups (Team), 20px
│   ├── Label Text
│   │   └── "个人空间" or "团队名称" (Body Medium)
│   └── Trailing Icon
│       └── Icon: arrow_drop_down, 20px
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 40px | 40px |
| Padding | 8px 12px | 8px 12px |
| Corner Radius | 8px | 8px |
| Background | Transparent (normal) / Primary Container 10% (hover) | 同左 |
| Leading Icon Color | On Primary | On Primary (Light) / On Surface (Dark) |
| Label Color | On Primary | On Primary (Light) / On Surface (Dark) |
| Trailing Icon Color | On Primary 70% | On Primary 70% (Light) / On Surface 70% (Dark) |
| Gap (icon to text) | 8px | 8px |
| Gap (text to arrow) | 4px | 4px |

**浅色主题 AppBar 上下文**:

| 属性 | 值 |
|------|-----|
| AppBar Background | Primary #1976D2 |
| Selector Text Color | On Primary #FFFFFF |
| Selector Icon Color | On Primary #FFFFFF |
| Hover Background | On Primary with 10% opacity |

**深色主题 AppBar 上下文**:

| 属性 | 值 |
|------|-----|
| AppBar Background | Surface Container High #3D3D3D |
| Selector Text Color | On Surface #F5F5F5 |
| Selector Icon Color | On Surface #F5F5F5 |
| Hover Background | On Surface with 8% opacity |

---

### 3.2 下拉菜单面板 (Team Selector Dropdown)

```
Component: Team Selector Dropdown
├── Dropdown Panel
│   ├── Current Context Header (optional)
│   │   └── "当前工作空间" (Label Small, On Surface Variant)
│   ├── Personal Option
│   │   ├── Leading: account_circle, 20px, Primary
│   │   ├── Title: "个人空间" (Body Medium)
│   │   ├── Subtitle: "仅自己可见" (Body Small, On Surface Variant)
│   │   └── Trailing: check (if selected)
│   ├── Divider
│   ├── Teams Header
│   │   └── "我的团队" (Label Small, On Surface Variant)
│   ├── Team Options (scrollable, max 5 items visible)
│   │   └── Team Option Item
│   │       ├── Leading: groups, 20px, Primary
│   │       ├── Title: "团队名称" (Body Medium)
│   │       ├── Subtitle: "Owner" / "Admin" / "Member" (Body Small, On Surface Variant)
│   │       └── Trailing: check (if selected)
│   ├── Divider (if has more teams)
│   ├── "查看更多团队" Link (if teams > 5)
│   │   └── TextButton "查看全部团队 →"
│   └── Divider
│   └── Create Team Link (bottom)
│       └── TextButton.icon "创建新团队" + add
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Panel Width | 280px | 280px |
| Panel Max Height | 360px | 360px |
| Panel Background | Surface #FFFFFF | Surface Container Low #1E1E1E |
| Panel Corner Radius | 12px | 12px |
| Panel Shadow | Elevation 3 | Elevation 3 (darker) |
| Panel Padding | 8px 0 | 8px 0 |
| Item Height | 56px | 56px |
| Item Padding | 12px 16px | 12px 16px |
| Item Hover Background | Surface Container Lowest #FAFAFA | darkSurfaceContainerLowest #0A0A0A |
| Item Selected Background | Primary Container #BBDEFB | Primary Container #1565C0 |
| Header Padding | 8px 16px | 8px 16px |
| Header Text | Label Small, On Surface Variant | 同左 |
| Divider | 1px Outline Variant | 同左 |

**选项项样式**:

```
Option Item Layout:
┌─────────────────────────────────────────┐
│ [icon]  标题文字              [check]   │
│         副标题文字                        │
└─────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| Leading Icon Size | 20px |
| Leading Icon Color | Primary |
| Title | Body Medium (14pt), On Surface |
| Subtitle | Body Small (12pt), On Surface Variant |
| Trailing Check Icon | check, 20px, Primary |
| Gap (icon to text) | 12px |

**选中项样式**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Primary Container #BBDEFB | Primary Container #1565C0 |
| Title Color | On Primary Container #1565C0 | On Primary Container #E3F2FD |
| Subtitle Color | On Primary Container with 70% opacity | On Primary Container with 70% opacity |
| Icon Color | On Primary Container | On Primary Container |

**底部链接样式**:

| 属性 | 值 |
|------|-----|
| Padding | 12px 16px |
| Text Style | Body Medium, Primary color |
| Icon Size | 18px |
| Hover Background | Primary with 8% opacity |

---

### 3.3 空状态（无团队）

```
Component: Team Selector Empty
├── Personal Option (always present)
├── Divider
├── Teams Header: "我的团队" (Label Small)
├── Empty State
│   ├── Icon: groups_outlined, 32px, On Surface Variant 40%
│   ├── Text "暂无团队" (Body Medium, On Surface Variant)
│   └── TextButton "创建团队"
└── Divider
```

| 属性 | 值 |
|------|-----|
| Empty Area Padding | 24px |
| Empty Area Alignment | Center |
| Icon Color | On Surface Variant 40% |
| Text Color | On Surface Variant |

---

## 4. 状态设计

### 4.1 选择器按钮状态

| 状态 | 视觉表现 | 说明 |
|------|---------|------|
| Normal | 透明背景，标准文字颜色 | 默认状态 |
| Hover | 背景色 8-10% 透明度 | 鼠标悬停 |
| Pressed | 背景色 12% 透明度，缩放 0.98 | 鼠标按下 |
| Open | 背景色 10% 透明度，箭头旋转 180° | 菜单展开 |
| Loading | 显示 CircularProgressIndicator (16px) | 正在切换上下文 |

### 4.2 下拉菜单状态

| 状态 | 视觉表现 | 说明 |
|------|---------|------|
| Closed | 不可见 | 默认状态 |
| Opening | 缩放 + 淡入 | 菜单展开动画 |
| Opened | 完全可见，可交互 | 菜单已展开 |
| Closing | 缩放 + 淡出 | 菜单关闭动画 |

---

## 5. 交互设计

### 5.1 按钮交互

| 交互 | 触发 | 行为 | 视觉反馈 | 动画 |
|------|------|------|---------|------|
| 悬停按钮 | 鼠标移入 | 准备点击 | 背景出现 | 100ms ease-out |
| 按下按钮 | 鼠标按下 | — | 背景加深，缩放 | 100ms ease-out |
| 点击按钮 | 鼠标释放 | 打开/关闭下拉菜单 | 箭头旋转 | 150ms ease-in-out |
| 点击外部 | 点击页面其他区域 | 关闭下拉菜单 | 菜单消失 | 150ms |

### 5.2 菜单项交互

| 交互 | 触发 | 行为 | 视觉反馈 | 动画 |
|------|------|------|---------|------|
| 悬停选项 | 鼠标移入选项 | 准备选择 | 背景高亮 | 100ms |
| 点击选项 | 点击选项 | 切换上下文 | 选项高亮，菜单关闭 | 200ms |
| 点击创建 | 点击"创建团队" | 导航到 /teams 或打开对话框 | 菜单关闭 | 200ms |
| 点击查看全部 | 点击"查看全部" | 导航到 /teams | 菜单关闭，页面过渡 | 300ms |

### 5.3 上下文切换流程

```
User Flow: Switch Context
├── User clicks Team Selector Button
│   └── Dropdown menu opens
├── User selects a team (or Personal)
│   ├── Dropdown closes
│   ├── Button updates to show new selection
│   ├── Global team context state updates
│   ├── AppBar title may update (if applicable)
│   ├── Current page content refreshes
│   │   └── Show loading indicator if needed
│   └── Snackbar: "已切换到 [Team Name]"
└── User continues working in new context
```

### 5.4 键盘交互

| 按键 | 行为 |
|------|------|
| Enter / Space | 打开/关闭下拉菜单 |
| Escape | 关闭下拉菜单 |
| Arrow Down | 菜单内向下移动焦点 |
| Arrow Up | 菜单内向上移动焦点 |
| Home | 移动到第一个选项 |
| End | 移动到最后一个选项 |
| Tab | 关闭菜单，移动到下一个焦点 |

---

## 6. 主题变体

### 6.1 浅色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| AppBar 背景 | #1976D2 | Primary |
| 选择器文字 | #FFFFFF | On Primary |
| 选择器图标 | #FFFFFF | On Primary |
| 选择器悬停背景 | rgba(255,255,255,0.1) | On Primary 10% |
| 下拉面板背景 | #FFFFFF | Surface |
| 选项悬停背景 | #FAFAFA | Surface Container Lowest |
| 选项选中背景 | #BBDEFB | Primary Container |
| 选项选中文字 | #1565C0 | On Primary Container |
| 分隔线 | #EEEEEE | Outline Variant |

### 6.2 深色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| AppBar 背景 | #3D3D3D | Surface Container High |
| 选择器文字 | #F5F5F5 | On Surface |
| 选择器图标 | #F5F5F5 | On Surface |
| 选择器悬停背景 | rgba(245,245,245,0.08) | On Surface 8% |
| 下拉面板背景 | #1E1E1E | Surface Container Low |
| 选项悬停背景 | #0A0A0A | darkSurfaceContainerLowest |
| 选项选中背景 | #1565C0 | Primary Container |
| 选项选中文字 | #E3F2FD | On Primary Container |
| 分隔线 | #333333 | Outline Variant |

---

## 7. 响应式规则

### 7.1 桌面端 (>= 1280px)

- 选择器位于 AppBar 标题区域
- 显示完整标签: "个人空间" 或 "团队名称"
- 下拉面板宽度: 280px
- 图标 + 文字完整显示

### 7.2 平板端 (>= 768px and < 1280px)

- 选择器位于 AppBar 标题区域
- 显示完整标签
- 下拉面板宽度: 280px

### 7.3 小屏 (< 768px)

- 选择器可能移至 AppBar Actions 区域
- 考虑显示简化标签或仅图标
- 下拉面板宽度: 100% (全宽底部 Sheet)
- 团队列表使用 BottomSheet 替代 Dropdown

---

## 8. 动画与动效

### 8.1 下拉菜单动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 菜单打开 | 200ms | decelerate | 从按钮下方展开，scaleY 0→1 + opacity 0→1 |
| 菜单关闭 | 150ms | accelerate | 收缩，scaleY 1→0 + opacity 1→0 |
| 箭头旋转 | 150ms | ease-in-out | 0° → 180° (打开) / 180° → 0° (关闭) |
| 选项悬停 | 100ms | ease-out | 背景色变化 |

### 8.2 上下文切换动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 按钮标签更新 | instant | — | 文字直接替换 |
| 页面内容刷新 | 200ms | ease-in-out | 内容区域淡入淡出 |
| Snackbar 出现 | 200ms | decelerate | 从底部滑入 |

---

## 9. 设计笔记

### 9.1 关键设计决策

1. **选择器放在 AppBar 标题旁**:
   - 最显眼的位置，用户随时知道当前上下文
   - 与 Google Workspace、Notion 等产品的模式一致
   - 比放在 Sidebar 或设置中更容易发现

2. **个人空间始终作为第一个选项**:
   - 明确区分"个人"和"团队"两种模式
   - 用户总有回退到个人空间的路径
   - 与现有个人工作台/试验/方法资源兼容

3. **下拉菜单显示角色信息**:
   - 用户在选择团队时就知道自己的权限
   - 避免切换到团队后发现权限不足
   - 在选项副标题中显示角色

4. **限制下拉菜单高度**:
   - 最多显示 5 个团队 + 个人空间
   - 超过时显示"查看全部"链接
   - 避免菜单过长影响可用性

5. **切换上下文后保持当前页面**:
   - 例如用户在 /workbenches 切换到团队，仍然留在 /workbenches
   - 但列表内容刷新为团队的资源
   - 提供连续的工作流体验

### 9.2 可访问性考量

- 按钮有明确的 aria-label: "当前工作空间：[名称]，点击切换"
- 下拉菜单支持完整的键盘导航
- 选中项有 check 图标，不仅靠背景色区分
- 菜单项有足够的高度 (56px)，易于点击
- 角色信息在副标题中可读

### 9.3 与现有设计的关系

- AppBar 复用现有 AppBarTheme 配置
- 下拉面板复用 Menu 组件样式
- 选项项复用 ListTile 样式
- 按钮交互复用现有 IconButton + Text 模式
- 需要更新 AppBar leading/title 布局以容纳选择器

### 9.4 图标映射

| 功能 | 图标名称 | 来源 |
|------|---------|------|
| 个人空间 | account_circle | Material Symbols |
| 团队 | groups | Material Symbols |
| 下拉箭头 | arrow_drop_down | Material Symbols |
| 选中标记 | check | Material Symbols |
| 创建团队 | add | Material Symbols |
| 查看更多 | arrow_forward | Material Symbols |

### 9.5 实现要点

```dart
// 伪代码示意
class TeamSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TeamContext>(
      offset: const Offset(0, 40),
      child: _TeamSelectorButton(),
      itemBuilder: (context) => [
        // Personal option
        PopupMenuItem(
          value: TeamContext.personal(),
          child: _ContextOption(
            icon: Icons.account_circle,
            title: '个人空间',
            subtitle: '仅自己可见',
            isSelected: currentContext.isPersonal,
          ),
        ),
        const PopupMenuDivider(),
        // Team options
        ...teams.map((team) => PopupMenuItem(
          value: TeamContext.team(team),
          child: _ContextOption(
            icon: Icons.groups,
            title: team.name,
            subtitle: team.role.name,
            isSelected: currentContext.teamId == team.id,
          ),
        )),
      ],
      onSelected: (context) => switchTeamContext(context),
    );
  }
}
```

---

**文档结束**
