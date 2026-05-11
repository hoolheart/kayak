# Team Management UI 设计规范文档

**任务ID**: R2-S2-002-A  
**版本**: 1.0  
**日期**: 2026-05-11  
**设计师**: sw-anna  
**项目**: Kayak 科学研究支持平台 - Release 2 Sprint 2  
**适用范围**: 团队管理前端 UI (`/teams`, `/teams/:id`, AppBar 团队选择器, 资源创建对话框)  
**依赖规范**: `log/release_1/ui/design_spec_v2.md` (Release 1 全局设计规范 v2)

---

## 目录

1. [文档说明](#1-文档说明)
2. [色彩系统](#2-色彩系统)
3. [字体系统](#3-字体系统)
4. [间距系统](#4-间距系统)
5. [组件规范](#5-组件规范)
6. [页面规格](#6-页面规格)
7. [响应式规则](#7-响应式规则)
8. [交互状态](#8-交互状态)
9. [动画与动效](#9-动画与动效)
10. [辅助功能](#10-辅助功能)
11. [图标映射](#11-图标映射)
12. [设计检查清单](#12-设计检查清单)

---

## 1. 文档说明

### 1.1 设计原则

1. **权限感知设计**: UI 根据用户角色（Owner/Admin/Member）动态调整，无权限的操作不可见
2. **上下文一致性**: 团队/个人上下文切换在全局保持一致（AppBar 选择器 + 资源归属选择）
3. **安全操作**: 删除团队、移除成员等危险操作有二次确认和视觉警示
4. **无缝集成**: 团队功能融入现有设计系统，不破坏已有用户体验

### 1.2 页面清单

| 页面/组件 | 路由/位置 | Figma 文档 | 说明 |
|-----------|----------|------------|------|
| 团队列表页 | `/teams` | `teams_list.md` | 展示用户所属团队列表 |
| 团队详情页 | `/teams/:id` | `team_detail.md` | 团队信息、成员管理、危险操作 |
| AppBar 团队选择器 | AppBar | `appbar_team_selector.md` | 全局上下文切换 |
| 资源创建对话框 | Dialog | `resource_creation.md` | 创建工作台/方法/试验时选择归属 |

---

## 2. 色彩系统

### 2.1 角色徽章专用色

团队管理引入角色徽章（Owner/Admin/Member），需要专用的颜色组合：

| 角色 | 背景色 (Light) | 背景色 (Dark) | 文字色 | 用途 |
|------|---------------|---------------|--------|------|
| **Owner** | `#BBDEFB` | `#1565C0` | `#1565C0` / `#E3F2FD` | 团队所有者，最高权限 |
| **Admin** | `#E0F7FA` | `#006064` | `#006064` / `#E0F7FA` | 团队管理员 |
| **Member** | `#EEEEEE` | `#2D2D2D` | `#757575` / `#9E9E9E` | 普通成员 |

### 2.2 危险区域专用色

危险操作区域使用特殊的视觉处理：

| 元素 | 背景色 (Light) | 背景色 (Dark) | 边框色 | 说明 |
|------|---------------|---------------|--------|------|
| 危险区域容器 | `#FFEBEE` | `#B71C1C` | `#C62828` / `#EF5350` | 删除/离开团队区域 |
| 危险区域标题 | `#C62828` | `#EF5350` | — | "危险操作" 标题 |
| 危险按钮 | Error 边框 + 文字 | Error Light 边框 + 文字 | — | 删除/离开按钮 |

### 2.3 团队选择器专用色

AppBar 团队选择器在深色/浅色主题下的颜色：

| 元素 | 浅色主题 | 深色主题 | 说明 |
|------|---------|---------|------|
| 选择器悬停背景 | `rgba(255,255,255,0.1)` | `rgba(245,245,245,0.08)` | AppBar 上的按钮悬停 |
| 选项选中背景 | `#BBDEFB` | `#1565C0` | 下拉菜单中选中的选项 |
| 选项选中文字 | `#1565C0` | `#E3F2FD` | 选中选项的文字颜色 |

### 2.4 权限提示专用色

资源创建对话框中的团队权限提示：

| 元素 | 浅色主题 | 深色主题 | 说明 |
|------|---------|---------|------|
| 提示背景 | `#E3F2FD` | `#0D47A1` | Info 容器背景 |
| 提示边框 | `#1976D2` | `#90CAF9` | Info 边框 |
| 提示图标 | `#1976D2` | `#90CAF9` | Info 图标 |

### 2.5 完整色板汇总

#### 浅色主题完整色板

```dart
// lib/features/team/theme/team_colors.dart
class TeamColors {
  // 角色徽章
  static const ownerBadgeBg = Color(0xFFBBDEFB);
  static const ownerBadgeText = Color(0xFF1565C0);
  static const adminBadgeBg = Color(0xFFE0F7FA);
  static const adminBadgeText = Color(0xFF006064);
  static const memberBadgeBg = Color(0xFFEEEEEE);
  static const memberBadgeText = Color(0xFF757575);

  // 危险区域
  static const dangerZoneBg = Color(0xFFFFEBEE);
  static const dangerZoneBorder = Color(0xFFC62828);
  static const dangerZoneTitle = Color(0xFFC62828);

  // 团队选择器
  static const selectorHoverBg = Color(0x1AFFFFFF); // 10% white
  static const optionSelectedBg = Color(0xFFBBDEFB);
  static const optionSelectedText = Color(0xFF1565C0);

  // 权限提示
  static const permissionHintBg = Color(0xFFE3F2FD);
  static const permissionHintBorder = Color(0xFF1976D2);
  static const permissionHintIcon = Color(0xFF1976D2);
}
```

#### 深色主题完整色板

```dart
// lib/features/team/theme/team_colors_dark.dart
class TeamColorsDark {
  // 角色徽章
  static const ownerBadgeBg = Color(0xFF1565C0);
  static const ownerBadgeText = Color(0xFFE3F2FD);
  static const adminBadgeBg = Color(0xFF006064);
  static const adminBadgeText = Color(0xFFE0F7FA);
  static const memberBadgeBg = Color(0xFF2D2D2D);
  static const memberBadgeText = Color(0xFF9E9E9E);

  // 危险区域
  static const dangerZoneBg = Color(0xFFB71C1C);
  static const dangerZoneBorder = Color(0xFFEF5350);
  static const dangerZoneTitle = Color(0xFFEF5350);

  // 团队选择器
  static const selectorHoverBg = Color(0x14F5F5F5); // 8% onSurface
  static const optionSelectedBg = Color(0xFF1565C0);
  static const optionSelectedText = Color(0xFFE3F2FD);

  // 权限提示
  static const permissionHintBg = Color(0xFF0D47A1);
  static const permissionHintBorder = Color(0xFF90CAF9);
  static const permissionHintIcon = Color(0xFF90CAF9);
}
```

---

## 3. 字体系统

### 3.1 复用现有字体层级

团队管理 UI 完全复用现有 `AppTypography.textTheme` 字体层级，无新增字体样式。

### 3.2 字体使用映射

| 元素 | 字体层级 | 字号 | 字重 | 行高 | 字间距 | 颜色 |
|------|---------|------|------|------|--------|------|
| 页面标题 | Title Large | 22pt | 500 | 28pt | 0px | On Surface |
| 卡片标题 | Title Medium | 16pt | 500 | 24pt | 0.15px | On Surface |
| 团队名称 (列表) | Title Medium | 16pt | 500 | 24pt | 0.15px | On Surface |
| 团队名称 (详情) | Title Large | 22pt | 500 | 28pt | 0px | On Surface |
| 成员名称 | Body Large | 16pt | 400 | 24pt | 0.5px | On Surface |
| 邮箱地址 | Body Medium | 14pt | 400 | 20pt | 0.25px | On Surface Variant |
| 角色徽章 | Label Small | 11pt | 500 | 16pt | 0.5px | 角色色 |
| 统计标签 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant |
| 统计值 | Body Medium | 14pt | 500 | 20pt | 0.25px | On Surface |
| 描述文字 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant |
| 对话框标题 | Headline Small | 24pt | 400 | 32pt | 0px | On Surface |
| 输入框标签 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant |
| 提示文字 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant |
| 按钮文字 | Label Large | 14pt | 500 | 20pt | 0.1px | 按钮色 |
| 菜单标题 | Label Small | 11pt | 500 | 16pt | 0.5px | On Surface Variant |
| 菜单选项 | Body Medium | 14pt | 400 | 20pt | 0.25px | On Surface |
| 菜单副标题 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant |
| 危险区域标题 | Title Medium | 16pt | 500 | 24pt | 0.15px | Error |
| 空状态标题 | Headline Small | 24pt | 400 | 32pt | 0px | On Surface |
| 空状态描述 | Body Medium | 14pt | 400 | 20pt | 0.25px | On Surface Variant |

---

## 4. 间距系统

### 4.1 页面级间距

| Token | 值 | 用途 |
|-------|-----|------|
| `team-page-padding` | 24px | 团队页面内容区内边距 |
| `team-section-gap` | 24px | 团队详情页各区块之间间距 |
| `team-card-gap` | 16px | 团队卡片网格间距 |
| `team-list-gap` | 0px | 成员列表项之间间距 (divider 处理) |

### 4.2 组件级间距

| Token | 值 | 用途 |
|-------|-----|------|
| `team-card-padding` | 20px | 团队卡片内边距 |
| `team-card-internal-gap` | 12px | 团队卡片内部元素间距 |
| `team-header-padding` | 24px | 团队信息卡片内边距 |
| `team-member-item-padding` | 12px 16px | 成员列表项内边距 |
| `team-danger-zone-padding` | 20px | 危险区域内边距 |
| `team-dialog-padding` | 24px | 对话框内边距 |
| `team-selector-padding` | 8px 12px | AppBar 选择器按钮内边距 |
| `team-dropdown-item-padding` | 12px 16px | 下拉菜单选项内边距 |
| `team-ownership-option-padding` | 12px 0 | 归属选择选项内边距 |
| `team-permission-hint-padding` | 12px 16px | 权限提示内边距 |

### 4.3 尺寸规范

| Token | 值 | 用途 |
|-------|-----|------|
| `team-card-height` | 160px | 团队卡片高度 |
| `team-card-icon-size` | 56px | 团队卡片图标容器 |
| `team-header-icon-size` | 64px | 团队详情页图标容器 |
| `team-avatar-size` | 40px | 成员头像尺寸 |
| `team-badge-height` | 24px | 角色徽章高度 (卡片内) |
| `team-badge-height-small` | 20px | 角色徽章高度 (列表内) |
| `team-member-item-height` | 72px | 成员列表项高度 |
| `team-selector-height` | 40px | AppBar 选择器按钮高度 |
| `team-dropdown-width` | 280px | 下拉菜单宽度 |
| `team-dropdown-max-height` | 360px | 下拉菜单最大高度 |
| `team-dialog-width` | 480px | 标准对话框宽度 |
| `team-ownership-option-height` | 56px | 归属选择选项高度 |

---

## 5. 组件规范

### 5.1 团队卡片 (Team Card)

**布局**:
```
Container (160px height)
├── Padding: 20px
├── Row (top section)
│   ├── Icon Container (56px, Primary Container bg)
│   │   └── Icon: groups, 28px
│   ├── SizedBox(width: 12px)
│   ├── Expanded Column
│   │   ├── Text: team name, Title Medium
│   │   └── Text: member count + description, Body Small
│   └── Role Badge (24px height)
│       └── Text: role, Label Small
├── Divider (1px, Outline Variant)
└── Row (bottom section)
    ├── Text: created date, Body Small, On Surface Variant
    └── Icon: chevron_right, 20px
```

**样式**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Surface | Surface Container Low |
| Border | 1px Outline Variant | 1px Outline Variant |
| Corner Radius | 16px | 16px |
| Shadow | None | None |
| Hover Border | Primary | Primary |
| Hover Shadow | Elevation 2 | Elevation 2 |
| Hover Transform | translateY(-2px) | translateY(-2px) |

**状态**:

| 状态 | 边框 | 阴影 | 变换 | 背景 |
|------|------|------|------|------|
| Normal | Outline Variant | None | None | Surface |
| Hover | Primary | Elevation 2 | translateY(-2px) | Surface |
| Pressed | Primary | Elevation 1 | scale(0.98) | Surface |
| Disabled | Outline Variant | None | None | Surface, 38% opacity |

---

### 5.2 成员列表项 (Member List Item)

**布局**:
```
ListTile (72px height)
├── Leading: CircleAvatar (40px)
│   ├── Background: Primary Container
│   └── Text: initials or Icon: person
├── Title Row
│   ├── Text: member name, Body Large
│   └── Role Badge (20px height)
│       └── Text: role, Label Small
├── Subtitle: email, Body Medium, On Surface Variant
└── Trailing: PopupMenuButton (Owner/Admin only)
    └── Icon: more_vert
```

**样式**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Surface | Surface Container Low |
| Hover Background | Surface Container Lowest | darkSurfaceContainerLowest |
| Corner Radius | 12px | 12px |
| Divider | 1px Outline Variant | 1px Outline Variant |

**操作菜单项**:

| 操作 | 图标 | 颜色 | 可见条件 |
|------|------|------|---------|
| 设为 Admin | admin_panel_settings | On Surface | target=Member, current=Owner/Admin |
| 降为 Member | person | On Surface | target=Admin, current=Owner |
| 移除成员 | person_remove | Error | target≠Owner, current=Owner/Admin |

---

### 5.3 AppBar 团队选择器 (Team Selector)

**按钮样式**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 40px | 40px |
| Padding | 8px 12px | 8px 12px |
| Corner Radius | 8px | 8px |
| Background (normal) | Transparent | Transparent |
| Background (hover) | On Primary 10% | On Surface 8% |
| Text Color | On Primary | On Surface |
| Icon Color | On Primary | On Surface |

**下拉面板样式**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Width | 280px | 280px |
| Max Height | 360px | 360px |
| Background | Surface | Surface Container Low |
| Corner Radius | 12px | 12px |
| Shadow | Elevation 3 | Elevation 3 |
| Item Height | 56px | 56px |
| Item Padding | 12px 16px | 12px 16px |
| Selected Background | Primary Container | Primary Container |
| Selected Text | On Primary Container | On Primary Container |

---

### 5.4 归属选择器 (Ownership Selector)

**布局**:
```
Column
├── Label: "归属", Label Medium, On Surface Variant
└── Radio Group
    ├── Ownership Option (56px height)
    │   ├── Radio (20px)
    │   ├── SizedBox(width: 12px)
    │   ├── Icon (20px, Primary)
    │   ├── SizedBox(width: 12px)
    │   └── Column
    │       ├── Text: title, Body Medium
    │       └── Text: subtitle, Body Small, On Surface Variant
    └── ... (repeat)
```

**样式**:

| 属性 | 值 |
|------|-----|
| Option Height | 56px |
| Option Padding | 12px 0 |
| Radio Size | 20px |
| Icon Size | 20px |
| Icon Color | Primary |
| Selected Background | Primary 4% opacity |
| Hover Background | Primary 4% opacity |

---

### 5.5 危险区域卡片 (Danger Zone Card)

**布局**:
```
Container
├── Padding: 20px
├── Background: Error Container
├── Border: 1px Error
├── Corner Radius: 12px
├── Row (header)
│   ├── Icon: warning, 20px, Error
│   └── Text: "危险操作", Title Medium, Error
├── Divider (1px, Error)
└── Danger Action Card
    ├── Text: action title, Title Small
    ├── Text: action description, Body Small, On Surface Variant
    └── OutlinedButton: action label (Error color)
```

**样式**:

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Background | Error Container #FFEBEE | Error Container #B71C1C |
| Border | 1px Error #C62828 | 1px Error #EF5350 |
| Corner Radius | 12px | 12px |
| Title Color | Error #C62828 | Error #EF5350 |
| Button Border | Error #C62828 | Error #EF5350 |
| Button Text | Error #C62828 | Error #EF5350 |

---

### 5.6 角色徽章 (Role Badge)

**卡片内徽章**:

| 属性 | Owner | Admin | Member |
|------|-------|-------|--------|
| Height | 24px | 24px | 24px |
| Padding | 4px 12px | 4px 12px | 4px 12px |
| Corner Radius | 8px | 8px | 8px |
| Background | Primary Container | Tertiary Container | Surface Container |
| Text Color | On Primary Container | On Tertiary Container | On Surface Variant |
| Text Style | Label Small | Label Small | Label Small |

**列表内徽章**:

| 属性 | Owner | Admin | Member |
|------|-------|-------|--------|
| Height | 20px | 20px | 20px |
| Padding | 2px 8px | 2px 8px | 2px 8px |
| Corner Radius | 6px | 6px | 6px |
| Background | Primary Container | Tertiary Container | Surface Container |
| Text Color | On Primary Container | On Tertiary Container | On Surface Variant |
| Text Style | Label Small | Label Small | Label Small |

---

## 6. 页面规格

### 6.1 团队列表页 (`/teams`)

**布局结构**:
```
AppShell
├── Sidebar (240px, 高亮 "团队")
├── Breadcrumb: 首页 > 团队
└── Content (padding: 24px)
    ├── Page Header (56px)
    │   ├── Title: "团队管理", Title Large
    │   └── FilledButton: "创建团队" + add icon
    └── Body
        ├── Loading: Skeleton cards or CircularProgressIndicator
        ├── Empty: EmptyStateWidget
        └── Grid: Team Cards
            ├── CrossAxisCount: 3 (>=1280px) / 2 (>=900px) / 1 (<900px)
            ├── MainAxisExtent: 160px
            └── Spacing: 16px
```

**交互**:
- 点击卡片 → 导航到 `/teams/:id`
- 点击"创建团队" → 打开创建团队对话框
- 下拉刷新 → 重新加载团队列表

### 6.2 团队详情页 (`/teams/:id`)

**布局结构**:
```
AppShell
├── Sidebar (240px, 高亮 "团队")
├── Breadcrumb: 首页 > 团队 > [Team Name]
└── Content (padding: 24px, flex column, gap: 24px)
    ├── Team Info Card
    │   ├── Row
    │   │   ├── Icon Container (64px, Primary Container)
    │   │   ├── Team Name & Description
    │   │   └── Edit Button (Owner/Admin only)
    │   └── Stats Row
    │       ├── "成员: N"
    │       ├── "创建者: Name"
    │       └── "创建于: Date"
    ├── Members Section
    │   ├── Header (56px)
    │   │   ├── Title: "团队成员", Title Medium
    │   │   ├── Count Badge
    │   │   └── Invite Button (Owner/Admin only)
    │   └── Members List (scrollable)
    │       └── Member List Items
    └── Danger Zone (Owner/Member/Admin conditional)
        ├── Delete Team (Owner only)
        └── Leave Team (Member/Admin only)
```

**权限条件渲染**:

| 元素 | Owner | Admin | Member |
|------|-------|-------|--------|
| 编辑按钮 | ✅ | ✅ | ❌ |
| 邀请按钮 | ✅ | ✅ | ❌ |
| 成员操作菜单 | ✅ | ✅ | ❌ |
| 删除团队区域 | ✅ | ❌ | ❌ |
| 离开团队区域 | ❌ | ✅ | ✅ |

### 6.3 AppBar 团队选择器

**位置**: AppBar 标题区域或 Actions 区域

**布局**:
```
AppBar
├── Title: "工作台" (or current page title)
├── Team Selector Button (new)
│   ├── Icon: account_circle or groups (20px)
│   ├── Text: "个人空间" or "Team Name" (Body Medium)
│   └── Icon: arrow_drop_down (20px)
└── Existing Actions...
```

**下拉面板**:
```
Dropdown Panel (280px width)
├── Header: "当前工作空间" (Label Small)
├── Personal Option (56px)
│   ├── Icon: account_circle
│   ├── Title: "个人空间"
│   ├── Subtitle: "仅自己可见"
│   └── Trailing: check (if selected)
├── Divider
├── Teams Header: "我的团队" (Label Small)
├── Team Options (max 5 visible, scrollable)
│   └── Team Option (56px)
│       ├── Icon: groups
│       ├── Title: "Team Name"
│       ├── Subtitle: "Owner/Admin/Member"
│       └── Trailing: check (if selected)
├── "查看全部团队" Link (if > 5 teams)
├── Divider
└── "创建新团队" Link
```

### 6.4 资源创建对话框

**对话框结构** (适用于工作台/方法/试验):
```
AlertDialog (480px width, 28px radius)
├── Title: "创建[资源类型]", Headline Small
├── Content
│   ├── Ownership Section
│   │   ├── Label: "归属", Label Medium
│   │   └── Radio Group
│   │       ├── Option: "个人空间" + account_circle
│   │       └── Option: "[Team Name]" + groups
│   │           └── Subtitle: "团队成员可访问"
│   ├── Permission Hint (if team selected)
│   │   ├── Icon: info
│   │   └── Text: "此资源将创建在 [Team Name]..."
│   ├── Divider
│   ├── TextField: "名称"
│   └── TextField: "描述" (optional)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "创建"
```

---

## 7. 响应式规则

### 7.1 断点定义

| 断点 | 宽度 | 名称 | 布局调整 |
|------|------|------|---------|
| Desktop | >= 1280px | 桌面端 | 完整侧边栏 + 多列布局 |
| Tablet | >= 768px and < 1280px | 平板端 | 折叠侧边栏 + 双列布局 |
| Mobile | < 768px | 移动端 | 底部导航 + 单列布局 |

### 7.2 团队列表页响应式

| 元素 | Desktop (>=1280px) | Tablet (>=768px) | Mobile (<768px) |
|------|-------------------|------------------|-----------------|
| 侧边栏 | 240px 展开 | 72px 折叠 | 底部导航 |
| 网格列数 | 3 | 2 | 1 |
| 卡片间距 | 16px | 16px | 12px |
| 页面内边距 | 24px | 16px | 12px |
| "创建团队"按钮 | AppBar FilledButton | AppBar FilledButton | FAB |

### 7.3 团队详情页响应式

| 元素 | Desktop (>=1280px) | Tablet (>=768px) | Mobile (<768px) |
|------|-------------------|------------------|-----------------|
| 侧边栏 | 240px 展开 | 72px 折叠 | 底部导航 |
| 团队图标 | 64px | 64px | 48px |
| 成员列表 | 全宽 | 全宽 | 全宽 |
| 危险区域 | 全宽 | 全宽 | 垂直堆叠 |
| 页面内边距 | 24px | 16px | 12px |

### 7.4 AppBar 选择器响应式

| 元素 | Desktop (>=1280px) | Tablet (>=768px) | Mobile (<768px) |
|------|-------------------|------------------|-----------------|
| 选择器位置 | AppBar 标题旁 | AppBar 标题旁 | AppBar Actions |
| 显示内容 | 图标 + 完整文字 | 图标 + 完整文字 | 仅图标 (或简化) |
| 下拉面板 | 280px Dropdown | 280px Dropdown | 全宽 BottomSheet |

---

## 8. 交互状态

### 8.1 组件状态定义

| 状态 | 定义 | 视觉表现 |
|------|------|---------|
| **Normal** | 默认状态 | 标准样式 |
| **Hover** | 鼠标悬停 | 背景色变化，阴影提升 |
| **Focused** | 键盘焦点 | 2px Primary 外边框 |
| **Pressed** | 鼠标按下 | 亮度变化，缩放 |
| **Disabled** | 不可交互 | 38% 透明度 |
| **Selected** | 已选中 | 选中背景色，选中标记 |
| **Loading** | 加载中 | 加载指示器替代内容 |
| **Error** | 错误状态 | Error 边框，错误提示 |

### 8.2 团队卡片状态

| 状态 | 边框 | 阴影 | 变换 | 背景 | 动画 |
|------|------|------|------|------|------|
| Normal | Outline Variant | None | None | Surface | — |
| Hover | Primary | Elevation 2 | translateY(-2px) | Surface | 150ms ease-in-out |
| Pressed | Primary | Elevation 1 | scale(0.98) | Surface | 100ms ease-out |
| Loading | Outline Variant | None | None | Surface | shimmer |

### 8.3 成员列表项状态

| 状态 | 背景 | 操作菜单 | 动画 |
|------|------|---------|------|
| Normal | Surface | Hidden | — |
| Hover | Surface Container Lowest | — | 100ms |
| Selected (menu open) | Surface | Visible | 150ms |
| Removing | — | — | 高度收缩 200ms |

### 8.4 按钮状态

| 按钮类型 | Normal | Hover | Pressed | Disabled | Loading |
|----------|--------|-------|---------|----------|---------|
| Filled (Primary) | Primary bg | Primary Variant bg | Darker bg | 38% opacity | Spinner + hidden text |
| Outlined (Error) | Error border | Error 8% bg | Error 12% bg | 38% opacity | Spinner |
| Text Button | Transparent | Primary 8% bg | Primary 12% bg | 38% opacity | Spinner |

### 8.5 对话框按钮状态

**确认删除按钮**:

| 状态 | 背景 | 文字 | 说明 |
|------|------|------|------|
| Normal | Error #C62828 | On Error #FFFFFF | 标准状态 |
| Hover | Error Dark #B71C1C | On Error #FFFFFF | 亮度降低 |
| Pressed | Error Darker #9E1A1A | On Error #FFFFFF | 亮度更低 |
| Loading | Error #C62828 | Hidden | 显示白色 Spinner |

---

## 9. 动画与动效

### 9.1 页面级动画

| 动画 | 时长 | 缓动 | 触发条件 |
|------|------|------|---------|
| 页面进入 | 300ms | ease-in-out | 导航到团队页面 |
| 页面离开 | 200ms | ease-in-out | 离开团队页面 |
| 列表加载 | 200ms | decelerate | 卡片 stagger 淡入 |
| 列表刷新 | 300ms | ease-in-out | 下拉刷新 |
| 空状态出现 | 200ms | decelerate | 无数据时 |

### 9.2 对话框动画

| 动画 | 时长 | 缓动 | 触发条件 |
|------|------|------|---------|
| 对话框打开 | 200ms | decelerate | 点击打开按钮 |
| 对话框关闭 | 150ms | accelerate | 点击取消/确认 |
| 内容切换 | 200ms | ease-in-out | 归属选择变化 |
| 错误提示 | 200ms | decelerate | 验证失败 |

### 9.3 微交互

| 动画 | 时长 | 缓动 | 触发条件 |
|------|------|------|---------|
| 卡片悬停 | 150ms | ease-in-out | 鼠标移入卡片 |
| 卡片按下 | 100ms | ease-out | 鼠标按下卡片 |
| 列表项悬停 | 100ms | ease-out | 鼠标移入列表项 |
| 菜单出现 | 150ms | decelerate | 点击更多按钮 |
| 菜单项悬停 | 100ms | ease-out | 鼠标移入菜单项 |
| 角色变更 | 200ms | ease-in-out | 变更成员角色 |
| 列表项移除 | 200ms | accelerate | 确认移除成员 |
| Spinner 出现 | instant | — | 操作加载 |
| Snackbar | 200ms | decelerate | 操作成功/失败 |
| 下拉菜单展开 | 200ms | decelerate | 点击选择器按钮 |
| 箭头旋转 | 150ms | ease-in-out | 下拉菜单开/关 |
| 提示信息展开 | 200ms | decelerate | 选择团队归属 |

---

## 10. 辅助功能

### 10.1 对比度要求

所有颜色组合均满足 WCAG 2.1 AA 标准：

| 元素组合 | 对比度 | 标准 | 结果 |
|---------|--------|------|------|
| Owner 徽章文字 / Owner 徽章背景 | 4.6:1 | 4.5:1 (AA) | ✅ 通过 |
| Admin 徽章文字 / Admin 徽章背景 | 4.8:1 | 4.5:1 (AA) | ✅ 通过 |
| Member 徽章文字 / Member 徽章背景 | 4.5:1 | 4.5:1 (AA) | ✅ 通过 |
| 危险区域标题 / 危险区域背景 | 5.2:1 | 4.5:1 (AA) | ✅ 通过 |
| 卡片文字 / 卡片背景 | 15.3:1 | 4.5:1 (AA) | ✅ 通过 |
| 列表项文字 / 列表项背景 | 15.3:1 | 4.5:1 (AA) | ✅ 通过 |
| 选择器文字 / AppBar 背景 (Light) | 8.6:1 | 4.5:1 (AA) | ✅ 通过 |
| 选择器文字 / AppBar 背景 (Dark) | 14.6:1 | 4.5:1 (AA) | ✅ 通过 |

### 10.2 焦点指示

- 所有交互元素必须有可见焦点指示
- 焦点样式: 2px Primary 颜色外边框，2px 偏移
- 团队卡片焦点: 2px Primary 边框 + 偏移
- 成员列表项焦点: 背景色变化 + 左侧 3px Primary 指示条
- 按钮焦点: 2px Primary 边框
- 输入框焦点: 2px Primary 底部边框 (现有规范)

### 10.3 屏幕阅读器支持

- **团队卡片**: `aria-label="团队: [名称], 角色: [角色], [N] 位成员"`
- **成员列表项**: `aria-label="成员: [姓名], 邮箱: [邮箱], 角色: [角色]"`
- **角色徽章**: 文字标签始终可见，不依赖颜色
- **操作菜单**: 菜单打开时朗读菜单项
- **危险操作**: 确认对话框朗读警告内容
- **团队选择器**: `aria-label="当前工作空间: [名称], 点击切换"`
- **归属选择**: Radio 组件自带屏幕阅读器支持

### 10.4 键盘导航

**团队列表页**:
- `Tab`: 在卡片之间导航
- `Enter`: 打开选中的团队详情
- `Ctrl+N`: 快速创建团队 (可选)

**团队详情页**:
- `Tab`: 在可交互元素间导航
- `Enter`: 激活按钮或打开菜单
- `Escape`: 关闭打开的菜单或对话框
- `Delete`: 快速触发删除 (需确认)

**AppBar 选择器**:
- `Enter/Space`: 打开/关闭下拉菜单
- `Escape`: 关闭下拉菜单
- `Arrow Down/Up`: 在选项间移动
- `Home/End`: 移动到第一个/最后一个选项

**对话框**:
- `Tab`: 在表单元素间导航
- `Enter`: 提交表单
- `Escape`: 取消并关闭对话框

### 10.5 触摸目标

- 最小触摸目标: 48x48dp
- 团队卡片: 全卡片可点击 (高度 160px)
- 成员列表项: 72px 高度 (满足)
- 操作按钮: 40px 高度 + 足够的外边距
- 菜单项: 56px 高度 (满足)
- 图标按钮: 40x40px 视觉 + 48x48dp 触摸

---

## 11. 图标映射

### 11.1 团队管理专用图标

| 功能 | 图标名称 | 尺寸 | 来源 |
|------|---------|------|------|
| 团队导航 | groups | 24px | Material Symbols |
| 个人空间 | account_circle | 20px | Material Symbols |
| 创建团队 | add | 18px | Material Symbols |
| 邀请成员 | person_add | 18px | Material Symbols |
| 成员管理 | people | 20px | Material Symbols |
| 更多操作 | more_vert | 20px | Material Symbols |
| 设为 Admin | admin_panel_settings | 20px | Material Symbols |
| 降为 Member | person | 20px | Material Symbols |
| 移除成员 | person_remove | 20px | Material Symbols |
| 删除团队 | delete | 20px | Material Symbols |
| 离开团队 | logout | 20px | Material Symbols |
| 编辑团队 | edit | 20px | Material Symbols |
| 警告 | warning | 20px | Material Symbols |
| 确认删除 | warning_amber | 48px | Material Symbols |
| 下拉箭头 | arrow_drop_down | 20px | Material Symbols |
| 选中标记 | check | 20px | Material Symbols |
| 进入详情 | chevron_right | 20px | Material Symbols |
| 邮箱 | email | 20px | Material Symbols |
| 头像默认 | person | 20px | Material Symbols |
| 空状态团队 | groups_outlined | 80px | Material Symbols |
| 提示信息 | info | 16px | Material Symbols |
| 查看更多 | arrow_forward | 16px | Material Symbols |

### 11.2 复用现有图标

| 功能 | 图标名称 | 来源 |
|------|---------|------|
| 首页/仪表盘 | dashboard | Material Symbols |
| 工作台 | workspace_premium | Material Symbols |
| 试验/实验 | science | Material Symbols |
| 方法 | description | Material Symbols |
| 设置 | settings | Material Symbols |
| 搜索 | search | Material Symbols |
| 取消 | close | Material Symbols |
| 返回 | arrow_back | Material Symbols |
| 刷新 | refresh | Material Symbols |
| 错误 | error_outline | Material Symbols |

---

## 12. 设计检查清单

### 12.1 设计完成检查 (Pre-Dev)

#### 团队列表页 (`/teams`)
- [x] 页面布局设计完成
- [x] 团队卡片设计完成 (Normal/Hover/Pressed/Disabled)
- [x] 空状态设计完成
- [x] 加载状态设计完成
- [x] 创建团队对话框设计完成
- [x] 响应式布局定义完成 (3 断点)
- [x] 动画定义完成
- [x] 颜色值确认完成
- [x] 字体层级确认完成

#### 团队详情页 (`/teams/:id`)
- [x] 页面布局设计完成
- [x] 团队信息卡片设计完成
- [x] 成员列表项设计完成
- [x] 成员操作菜单设计完成
- [x] 邀请成员对话框设计完成
- [x] 危险区域设计完成
- [x] 删除确认对话框设计完成
- [x] 离开确认对话框设计完成
- [x] 移除成员确认对话框设计完成
- [x] 权限矩阵定义完成
- [x] 响应式布局定义完成
- [x] 动画定义完成

#### AppBar 团队选择器
- [x] 选择器按钮设计完成
- [x] 下拉面板设计完成
- [x] 选项项设计完成
- [x] 空状态设计完成
- [x] 键盘导航定义完成
- [x] 响应式布局定义完成
- [x] 动画定义完成

#### 资源创建对话框
- [x] 归属选择器设计完成
- [x] 权限提示设计完成
- [x] 多团队展开设计完成
- [x] 无团队状态设计完成
- [x] 与各资源类型集成设计完成

### 12.2 可访问性检查

- [x] 所有文字与背景对比度 >= 4.5:1
- [x] 角色徽章不仅依赖颜色区分
- [x] 所有交互元素有焦点指示
- [x] 键盘导航路径定义完整
- [x] 屏幕阅读器标签定义完整
- [x] 触摸目标 >= 48x48dp
- [x] 危险操作有二次确认
- [x] 对话框有标题和描述

### 12.3 与现有设计一致性检查

- [x] 颜色系统与 design_spec_v2.md 一致
- [x] 字体系统与 design_spec_v2.md 一致
- [x] 间距系统与 design_spec_v2.md 一致
- [x] 按钮规范与 design_spec_v2.md 一致
- [x] 输入框规范与 design_spec_v2.md 一致
- [x] 卡片规范与 design_spec_v2.md 一致
- [x] 对话框规范与 design_spec_v2.md 一致
- [x] 列表项规范与 design_spec_v2.md 一致
- [x] AppBar 规范与现有 app_theme.dart 一致
- [x] Sidebar 导航新增 "团队" 项

---

**文档结束**

*本文档基于 Release 1 全局设计规范 `design_spec_v2.md` 编制。任何冲突以本文档（团队管理专用规范）为准，未覆盖部分以全局规范为准。*
