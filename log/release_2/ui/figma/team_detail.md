# Figma 原型 - 团队详情/设置页面 (Team Detail Page)

**任务ID**: R2-S2-002-A  
**Figma 文件**: `kayak_r2_teams.fig` > Page: `Team Detail`  
**设计师**: sw-anna  
**日期**: 2026-05-11  
**状态**: 设计完成  
**适用范围**: Release 2 Sprint 2 — 团队管理前端  
**依赖规范**: `log/release_1/ui/design_spec_v2.md` (Release 1 全局设计规范 v2)  
**路由**: `/teams/:id`

---

## 1. 设计目标

团队详情页面是管理特定团队信息和成员的核心界面。设计强调：
- **权限感知**: 根据用户角色（Owner/Admin/Member）动态显示/隐藏操作
- **信息分层**: 团队信息、成员管理、危险操作分区明确
- **安全操作**: 删除团队、移除成员等危险操作有明确的确认流程
- **与个人空间区分**: 明确当前处于团队上下文

---

## 2. 页面布局架构

### 2.1 主 Frame

```
Frame: "Team Detail Page - Desktop Light"
Width: 1440px
Height: 900px
Background: Surface Container Lowest #FAFAFA
Layout: Row (sidebar + content)

Frame: "Team Detail Page - Desktop Dark"
Width: 1440px
Height: 900px
Background: Surface #121212
Layout: Row (sidebar + content)
```

### 2.2 内容区域结构

```
Team Detail Page (within AppShell)
├── Sidebar (240px / 72px collapsed) — 复用现有组件
│   └── 高亮 "团队" 导航项
├── Main Content Area (flex)
│   ├── Breadcrumb Navigation (48px height)
│   │   └── 首页 > 团队 > [Team Name]
│   └── Page Content (flex column, padding: 24px, gap: 24px)
│       ├── Team Info Section
│       │   ├── Team Header Card
│       │   └── Team Stats Row
│       ├── Members Section
│       │   ├── Members Header
│       │   └── Members List
│       └── Danger Zone Section (Owner only)
│           ├── Delete Team
│           └── Leave Team
```

---

## 3. 组件规格详解

### 3.1 团队信息卡片 (Team Header Card)

```
Component: Team Header Card
├── Card Container
│   ├── Top Row
│   │   ├── Team Icon Container
│   │   │   ├── Icon: groups, 32px
│   │   │   └── Background: Primary Container
│   │   ├── Team Name & Description (Expanded)
│   │   │   ├── Team Name (Title Large, 22pt)
│   │   │   └── Team Description (Body Medium, On Surface Variant)
│   │   └── Edit Button (Owner/Admin only)
│   │       └── IconButton: edit, 20px
│   └── Bottom Row (Stats)
│       ├── Stat Item: "成员" + count
│       ├── Stat Item: "创建者" + creator name
│       └── Stat Item: "创建于" + date
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Width | 100% | 100% |
| Padding | 24px | 24px |
| Corner Radius | 16px | 16px |
| Fills | Surface #FFFFFF | Surface Container Low #1E1E1E |
| Border | 1px Outline Variant #EEEEEE | 1px Outline Variant #333333 |
| Shadow | None | None |

**团队图标容器**:

| 属性 | 值 |
|------|-----|
| Size | 64px × 64px |
| Background | Primary Container |
| Icon Color | On Primary Container |
| Corner Radius | 20px |

**统计项样式**:

| 属性 | 值 |
|------|-----|
| Label | Body Small, On Surface Variant |
| Value | Body Medium, On Surface, fontWeight: 500 |
| Gap between items | 32px |

**编辑按钮状态** (Owner/Admin):

| 属性 | 值 |
|------|-----|
| Type | IconButton |
| Icon | edit, 20px |
| Visible | Owner/Admin only |
| On Press | 打开编辑对话框 |

**编辑对话框**:

```
Dialog: Edit Team Info
├── Title: "编辑团队信息" (Headline Small)
├── Content
│   ├── TextField: "团队名称" (required)
│   └── TextField: "团队描述" (optional, maxLines: 3)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "保存"
```

| 属性 | 值 |
|------|-----|
| Width | 480px |
| Corner Radius | 28px (Standard Dialog) |
| Padding | 24px |

---

### 3.2 成员管理区域 (Members Section)

```
Component: Members Section
├── Section Header (56px)
│   ├── Title "团队成员" (Title Medium)
│   ├── Member Count Badge "12 人" (Label Medium, On Surface Variant)
│   └── Spacer
│       └── Invite Button (Owner/Admin only)
│           └── FilledButton.icon "邀请成员" + person_add
├── Divider
└── Members List
    └── Member List Items (scrollable)
```

**区域头部样式**:

| 属性 | 值 |
|------|-----|
| Height | 56px |
| Padding | 0 0 12px 0 |
| Title | Title Medium (16pt, 500) |
| Count Badge | Label Medium, On Surface Variant, padding: 4px 8px |

---

### 3.3 成员列表项 (Member List Item)

```
Component: Member List Item
├── ListTile Container
│   ├── Leading: Avatar
│   │   └── CircleAvatar (40px)
│   │       ├── Background: Primary Container
│   │       └── Text: "AB" (Label Large, On Primary Container) or Icon: person
│   ├── Title Row
│   │   ├── Member Name (Body Large, On Surface)
│   │   └── Role Badge (Status Chip)
│   │       └── "Owner" / "Admin" / "Member"
│   ├── Subtitle: Email (Body Medium, On Surface Variant)
│   └── Trailing Actions (Owner/Admin only, cannot act on Owner)
│       ├── IconButton: more_vert (opens menu)
│       └── Menu Items:
│           ├── "设为 Admin" (if Member)
│           ├── "降为 Member" (if Admin)
│           └── "移除成员" (error color)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 72px | 72px |
| Padding | 12px 16px | 12px 16px |
| Corner Radius | 12px | 12px |
| Background | Surface | Surface Container Low |
| Border | None | None |
| Hover Background | Surface Container Lowest #FAFAFA | darkSurfaceContainerLowest #0A0A0A |
| Divider | 1px Outline Variant (between items) | 同左 |

**头像样式**:

| 属性 | 值 |
|------|-----|
| Size | 40px × 40px |
| Background | Primary Container |
| Text Color | On Primary Container |
| Text Style | Label Large (14pt, 500) |
| Fallback Icon | person, 20px |

**角色徽章 (Member List 内)**:

| 角色 | 背景色 (Light) | 背景色 (Dark) | 文字色 | 样式 |
|------|---------------|---------------|--------|------|
| Owner | Primary Container #BBDEFB | Primary Container #1565C0 | On Primary Container | 无 |
| Admin | Tertiary Container #E0F7FA | Tertiary Container #006064 | On Tertiary Container | 无 |
| Member | Surface Container #EEEEEE | Surface Container #2D2D2D | On Surface Variant | 无 |

Badge 样式:
- Height: 20px
- Padding: 2px 8px
- Corner Radius: 6px
- Text: Label Small (11pt, 500)

**更多操作菜单 (PopupMenu)**:

```
PopupMenu Items:
├── ListTile: "设为 Admin"
│   ├── Icon: admin_panel_settings, 20px
│   └── Visible when: target is Member, current user is Owner/Admin
├── ListTile: "降为 Member"
│   ├── Icon: person, 20px
│   └── Visible when: target is Admin, current user is Owner
├── Divider
└── ListTile: "移除成员" (Destructive)
    ├── Icon: delete, 20px, Error color
    └── Text: Error color
    └── Visible when: current user is Owner/Admin, target is not Owner
```

**列表项悬停状态**:

| 属性 | 值 |
|------|-----|
| Background | Surface Container Lowest (Light) / darkSurfaceContainerLowest (Dark) |
| Duration | 100ms |

---

### 3.4 邀请成员按钮与对话框

**邀请按钮** (Owner/Admin only):

| 属性 | 值 |
|------|-----|
| Type | FilledButton.icon |
| Icon | person_add, 18px |
| Label | "邀请成员" |
| Style | Primary, compact |
| Visible | Owner/Admin only |

**邀请成员对话框**:

```
Dialog: Invite Member
├── Title: "邀请成员" (Headline Small)
├── Content
│   ├── TextField: "邮箱地址"
│   │   ├── Label: "邮箱地址"
│   │   ├── Hint: "请输入被邀请人的邮箱"
│   │   ├── Prefix Icon: email
│   │   └── Validation: 邮箱格式校验
│   └── SizedBox(height: 16)
│   └── Dropdown: "角色"
│       ├── Label: "角色"
│       ├── Value: "Member" (default)
│       └── Options:
│           ├── "Member" — 可以查看和创建资源
│           └── "Admin" — 可以管理团队成员和设置
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "发送邀请"
        └── Loading state: CircularProgressIndicator (16px)
```

| 属性 | 值 |
|------|-----|
| Width | 480px |
| Corner Radius | 28px |
| Padding | 24px |
| Field Gap | 16px |

**邮箱输入框验证**:

| 状态 | 视觉表现 |
|------|---------|
| 未输入 | 标准样式 |
| 有效邮箱 | 右侧显示 check_circle, Success color |
| 无效邮箱 | 边框变 Error, 下方显示 "请输入有效的邮箱地址" |
| 已存在成员 | 边框变 Error, 下方显示 "该用户已是团队成员" |

**角色选择说明**:

```
Component: Role Selection Dropdown
├── Option: "Member"
│   ├── Title: "Member" (Body Medium)
│   └── Subtitle: "可以查看和创建资源" (Body Small, On Surface Variant)
└── Option: "Admin"
    ├── Title: "Admin" (Body Medium)
    └── Subtitle: "可以管理团队成员和设置" (Body Small, On Surface Variant)
```

---

### 3.5 危险操作区域 (Danger Zone)

危险操作区域使用特殊的视觉处理，与用户明确警示风险。

```
Component: Danger Zone
├── Section Header
│   ├── Icon: warning, 20px, Error color
│   └── Title "危险操作" (Title Medium, Error color)
├── Divider (Error color, 1px)
├── Danger Card: Delete Team (Owner only)
│   ├── Title "删除团队" (Title Small)
│   ├── Description "删除团队将永久移除所有团队数据和资源，此操作不可撤销。" (Body Small, On Surface Variant)
│   └── OutlinedButton: "删除团队" (Error color)
└── Danger Card: Leave Team (Member/Admin only)
    ├── Title "离开团队" (Title Small)
    ├── Description "离开团队后，您将失去对该团队资源的访问权限。" (Body Small, On Surface Variant)
    └── OutlinedButton: "离开团队" (Error color)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Section Background | Error Container #FFEBEE | Error Container #B71C1C |
| Section Border | 1px Error #C62828 | 1px Error #EF5350 |
| Corner Radius | 12px | 12px |
| Padding | 20px | 20px |
| Title Color | Error #C62828 | Error #EF5350 |
| Description Color | On Surface Variant | On Surface Variant |
| Button Style | OutlinedButton, Error color border + text |

**危险操作卡片样式**:

| 属性 | 值 |
|------|-----|
| Internal Gap | 16px |
| Title | Title Small (14pt, 500) |
| Description | Body Small (12pt) |
| Button Height | 36px |
| Button Padding | 0 16px |

**删除团队确认对话框**:

```
Dialog: Delete Team Confirmation
├── Icon: warning_amber, 48px, Error color
├── Title: "确认删除团队" (Headline Small)
├── Content
│   ├── Text: "确定要删除团队 [Team Name] 吗？" (Body Large)
│   └── Text: "此操作不可恢复，所有团队成员将失去访问权限，团队相关的所有资源将被删除。" (Body Medium, On Surface Variant)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "删除" (Error background)
        └── Loading state: CircularProgressIndicator (16px, white)
```

| 属性 | 值 |
|------|-----|
| Width | 480px |
| Icon Size | 48px |
| Icon Color | Error |
| Delete Button | FilledButton with Error background |

**离开团队确认对话框**:

```
Dialog: Leave Team Confirmation
├── Icon: logout, 48px, Warning color
├── Title: "确认离开团队" (Headline Small)
├── Content
│   ├── Text: "确定要离开团队 [Team Name] 吗？" (Body Large)
│   └── Text: "离开后将无法访问该团队的资源和数据。" (Body Medium, On Surface Variant)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "离开" (Warning background)
```

| 属性 | 值 |
|------|-----|
| Width | 480px |
| Icon Size | 48px |
| Icon Color | Warning |
| Leave Button | FilledButton with Warning background |

---

### 3.6 移除成员确认对话框

```
Dialog: Remove Member Confirmation
├── Icon: person_remove, 48px, Error color
├── Title: "确认移除成员" (Headline Small)
├── Content
│   ├── Text: "确定要将 [Member Name] 从团队中移除吗？" (Body Large)
│   └── Text: "该成员将失去对团队所有资源的访问权限。" (Body Medium, On Surface Variant)
└── Actions
    ├── TextButton: "取消"
    └── FilledButton: "移除" (Error background)
```

| 属性 | 值 |
|------|-----|
| Width | 480px |
| Icon Size | 48px |
| Icon Color | Error |
| Remove Button | FilledButton with Error background |

---

## 4. 权限矩阵与UI可见性

### 4.1 操作权限表

| UI 元素 | Owner | Admin | Member |
|---------|-------|-------|--------|
| 编辑团队信息 | ✅ | ✅ | ❌ |
| 邀请成员 | ✅ | ✅ | ❌ |
| 移除成员 | ✅ | ✅ | ❌ (不能移除 Owner) |
| 修改成员角色 | ✅ | ✅ | ❌ |
| 删除团队 | ✅ | ❌ | ❌ |
| 离开团队 | ❌ | ✅ | ✅ |
| 查看成员列表 | ✅ | ✅ | ✅ |
| 查看团队信息 | ✅ | ✅ | ✅ |

### 4.2 条件渲染规则

```dart
// 编辑按钮可见性
bool showEditButton = userRole == TeamRole.owner || userRole == TeamRole.admin;

// 邀请按钮可见性
bool showInviteButton = userRole == TeamRole.owner || userRole == TeamRole.admin;

// 成员操作菜单可见性
bool showMemberActions = (userRole == TeamRole.owner || userRole == TeamRole.admin) 
    && targetMember.role != TeamRole.owner;

// 危险区域可见性
bool showDeleteTeam = userRole == TeamRole.owner;
bool showLeaveTeam = userRole != TeamRole.owner;
```

---

## 5. 状态设计

### 5.1 页面加载状态

```
State: Loading
├── Team Header Skeleton (64px icon + 2 lines)
├── Members Section Skeleton (3-5 list items)
└── Danger Zone hidden until loaded
```

### 5.2 页面错误状态

```
State: Error
├── Icon: error_outline, 64px, Error color
├── Title "加载失败" (Title Medium)
├── Description "无法获取团队信息" (Body Medium)
└── FilledButton "重试"
```

### 5.3 空成员列表状态

理论上不存在（至少 Owner 在列表中），但防御性设计：

```
State: Empty Members
├── Icon: people_outline, 48px, On Surface Variant
├── Title "暂无成员" (Title Medium)
└── Description "邀请成员加入团队" (Body Medium)
```

---

## 6. 交互设计

### 6.1 成员列表交互

| 交互 | 触发 | 行为 | 视觉反馈 | 动画 |
|------|------|------|---------|------|
| 悬停成员项 | 鼠标移入 | 准备操作 | 背景高亮 | 100ms |
| 点击更多 | 点击 more_vert | 打开操作菜单 | PopupMenu 出现 | 150ms decelerate |
| 角色变更 | 选择角色选项 | 更新成员角色 | Snackbar 提示成功 | 即时 |
| 移除成员 | 选择移除 | 显示确认对话框 | 对话框出现 | 200ms |
| 确认移除 | 点击确认 | 移除成员，更新列表 | 列表项收缩消失 | 200ms |

### 6.2 团队信息交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 点击编辑 | 点击 edit 按钮 | 打开编辑对话框 | 对话框出现 |
| 保存信息 | 点击保存 | 更新团队信息 | 对话框关闭，Snackbar 提示 |

### 6.3 危险操作交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 点击删除 | 点击删除按钮 | 打开确认对话框 | 对话框出现，Error 图标 |
| 确认删除 | 点击确认 | 删除团队，导航到 /teams | 页面过渡 |
| 点击离开 | 点击离开按钮 | 打开确认对话框 | 对话框出现，Warning 图标 |
| 确认离开 | 点击确认 | 离开团队，导航到 /teams | 页面过渡 |

---

## 7. 主题变体

### 7.1 浅色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 页面背景 | #FAFAFA | Surface Container Lowest |
| 卡片背景 | #FFFFFF | Surface |
| 成员列表项背景 | #FFFFFF | Surface |
| 成员列表项悬停 | #FAFAFA | Surface Container Lowest |
| 危险区域背景 | #FFEBEE | Error Container |
| 危险区域边框 | #C62828 | Error |
| 危险区域标题 | #C62828 | Error |
| Owner 徽章 | #BBDEFB / #1565C0 | Primary Container |
| Admin 徽章 | #E0F7FA / #006064 | Tertiary Container |
| Member 徽章 | #EEEEEE / #757575 | Surface Container |

### 7.2 深色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 页面背景 | #121212 | Surface |
| 卡片背景 | #1E1E1E | Surface Container Low |
| 成员列表项背景 | #1E1E1E | Surface Container Low |
| 成员列表项悬停 | #0A0A0A | darkSurfaceContainerLowest |
| 危险区域背景 | #B71C1C | Error Container Dark |
| 危险区域边框 | #EF5350 | Error Light |
| 危险区域标题 | #EF5350 | Error Light |
| Owner 徽章 | #1565C0 / #E3F2FD | Primary Container |
| Admin 徽章 | #006064 / #E0F7FA | Tertiary Container |
| Member 徽章 | #2D2D2D / #9E9E9E | Surface Container |

---

## 8. 响应式规则

### 8.1 桌面端 (>= 1280px)

- 侧边栏: 240px 展开
- 内容区最大宽度: 100%
- 成员列表: 全宽
- 危险区域: 全宽

### 8.2 平板端 (>= 768px and < 1280px)

- 侧边栏: 72px 折叠
- 内容区内边距: 16px
- 团队信息卡片: 全宽
- 成员列表: 全宽

### 8.3 小屏 (< 768px)

- 侧边栏: 隐藏
- 内容区内边距: 12px
- 团队图标: 48px (缩小)
- 成员操作菜单: 全宽底部 Sheet 替代 PopupMenu
- 危险区域: 垂直堆叠

---

## 9. 动画与动效

### 9.1 页面级动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 页面加载 | 300ms | ease-in-out | 内容淡入 |
| 列表项进入 | 200ms | decelerate | stagger 50ms |
| 列表项移除 | 200ms | accelerate | 高度收缩到 0 |
| 对话框出现 | 200ms | decelerate | 缩放 + 淡入 |
| 对话框消失 | 150ms | accelerate | 缩放 + 淡出 |

### 9.2 微交互

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 成员项悬停 | 100ms | ease-out | 背景色变化 |
| 菜单出现 | 150ms | decelerate | 缩放 + 淡入 |
| 角色变更 | 200ms | ease-in-out | 徽章颜色过渡 |
| Snackbar | 200ms | decelerate | 从底部滑入 |

---

## 10. 设计笔记

### 10.1 关键设计决策

1. **危险区域使用 Error Container 背景**:
   - 明显的视觉警示，让用户意识到下方操作有风险
   - 与常规设置区域形成强烈对比
   - 符合业界惯例（GitHub、Vercel 等均采用此模式）

2. **成员列表使用 ListTile 而非表格**:
   - 成员数量通常较少（< 50）
   - 头像 + 名称的展示更人性化
   - 与 Material Design 3 的列表规范一致

3. **Owner 不能离开团队**:
   - 必须先转让所有权或删除团队
   - UI 上直接隐藏"离开团队"按钮，而非禁用
   - 避免用户困惑

4. **不能移除 Owner**:
   - UI 上不显示 Owner 的操作菜单
   - 后端也有相同的保护逻辑
   - 防止团队陷入无 Owner 状态

### 10.2 可访问性考量

- 角色徽章不仅靠颜色区分，文字标签始终可见
- 危险操作有二次确认对话框
- 删除/移除操作使用 Error 色，离开使用 Warning 色
- 所有按钮有明确的文字标签
- 对话框有标题和描述，便于屏幕阅读器

### 10.3 与现有设计的关系

- 页面布局复用现有 AppShell
- 卡片样式基于现有 `Standard Card` 规范
- 对话框复用现有 `Standard Dialog` 规范 (28px 圆角)
- 列表项基于现有 `ListTile` 主题
- 按钮复用现有按钮规范
- 危险操作对话框复用 `DeleteConfirmationDialog` 模式并扩展

### 10.4 图标映射

| 功能 | 图标名称 | 来源 |
|------|---------|------|
| 团队导航 | groups | Material Symbols |
| 编辑团队 | edit | Material Symbols |
| 邀请成员 | person_add | Material Symbols |
| 成员管理 | people | Material Symbols |
| 更多操作 | more_vert | Material Symbols |
| 设为 Admin | admin_panel_settings | Material Symbols |
| 降为 Member | person | Material Symbols |
| 移除成员 | person_remove | Material Symbols |
| 删除团队 | delete | Material Symbols |
| 离开团队 | logout | Material Symbols |
| 警告 | warning | Material Symbols |
| 确认删除 | warning_amber | Material Symbols |
| 确认离开 | logout | Material Symbols |
| 邮箱 | email | Material Symbols |
| 头像默认 | person | Material Symbols |

---

**文档结束**
