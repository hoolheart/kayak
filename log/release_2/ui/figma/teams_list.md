# Figma 原型 - 团队列表页面 (Team List Page)

**任务ID**: R2-S2-002-A  
**Figma 文件**: `kayak_r2_teams.fig` > Page: `Team List`  
**设计师**: sw-anna  
**日期**: 2026-05-11  
**状态**: 设计完成  
**适用范围**: Release 2 Sprint 2 — 团队管理前端  
**依赖规范**: `log/release_1/ui/design_spec_v2.md` (Release 1 全局设计规范 v2)  
**路由**: `/teams`

---

## 1. 设计目标

团队列表页面是用户查看和管理所属团队的入口。设计强调：
- **清晰的团队归属**: 一眼看到用户所属的所有团队及其角色
- **快速创建入口**: 明显的"创建团队"按钮，降低创建门槛
- **信息密度适中**: 卡片式布局，平衡信息展示与视觉舒适度
- **与个人空间区分**: 通过 AppBar 团队选择器明确当前上下文

---

## 2. 页面布局架构

### 2.1 主 Frame

```
Frame: "Team List Page - Desktop Light"
Width: 1440px
Height: 900px
Background: Surface Container Lowest #FAFAFA
Layout: Row (sidebar + content)

Frame: "Team List Page - Desktop Dark"
Width: 1440px
Height: 900px
Background: Surface #121212
Layout: Row (sidebar + content)
```

### 2.2 内容区域结构

```
Team List Page (within AppShell)
├── Sidebar (240px / 72px collapsed) — 复用现有组件
│   └── 新增导航项: "团队" (route: /teams, icon: groups)
├── Main Content Area (flex)
│   ├── Breadcrumb Navigation (48px height)
│   │   └── 首页 > 团队
│   └── Page Content (flex column, padding: 24px, gap: 16px)
│       ├── Page Header (56px)
│       │   ├── Page Title "团队管理" (Title Large)
│       │   └── Action: FilledButton "创建团队" (right-aligned)
│       ├── Content Area (flex)
│       │   ├── Team Grid (default view)
│       │   │   └── Team Cards (responsive grid)
│       │   └── Empty State (when no teams)
│       └── Loading State (skeleton cards)
```

---

## 3. 组件规格详解

### 3.1 页面头部 (Page Header)

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Height | 56px | 56px |
| Padding | 0 0 16px 0 | 0 0 16px 0 |
| Title | "团队管理", Title Large (22pt, 500) | 同左 |
| Title Color | On Surface #212121 | On Surface #F5F5F5 |
| Bottom Border | 1px Outline Variant #EEEEEE | 1px Outline Variant #333333 |
| Action Button | FilledButton "创建团队" + add icon | 同左 |

```
Component: Page Header
├── Title "团队管理" (Title Large)
└── Spacer
    └── FilledButton.icon
        ├── Icon: add, 18px
        ├── Label: "创建团队"
        └── Style: Primary Filled Button (compact)
```

---

### 3.2 团队卡片 (Team Card)

团队卡片复用现有 `Standard Card` 规范，尺寸和内容根据团队信息定制。

```
Component: Team Card
├── Card Container (hoverable)
│   ├── Top Section
│   │   ├── Team Icon Container
│   │   │   ├── Icon: groups, 28px
│   │   │   └── Background: Primary Container
│   │   ├── Team Info (Expanded)
│   │   │   ├── Team Name (Title Medium)
│   │   │   └── Member Count + Description (Body Small)
│   │   └── Role Badge
│   │       └── "Owner" / "Admin" / "Member" (Status Chip)
│   ├── Divider (1px, Outline Variant)
│   └── Bottom Section
│       ├── Created Date (Body Small, On Surface Variant)
│       └── Arrow Icon (chevron_right, 20px)
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Width | 100% (grid cell) | 100% |
| Height | 160px | 160px |
| Padding | 20px | 20px |
| Corner Radius | 16px | 16px |
| Fills | Surface #FFFFFF | Surface Container Low #1E1E1E |
| Border | 1px Outline Variant #EEEEEE | 1px Outline Variant #333333 |
| Shadow | None | None |
| Gap (internal) | 12px | 12px |

**团队图标容器**:

| 属性 | 值 |
|------|-----|
| Size | 56px × 56px |
| Background | Primary Container #BBDEFB (Light) / #1565C0 (Dark) |
| Icon Color | On Primary Container #1565C0 (Light) / #E3F2FD (Dark) |
| Corner Radius | 16px |

**角色徽章 (Role Badge)**:

| 角色 | 背景色 (Light) | 背景色 (Dark) | 文字色 | 边框 |
|------|---------------|---------------|--------|------|
| Owner | Primary Container #BBDEFB | Primary Container #1565C0 | On Primary Container | none |
| Admin | Tertiary Container #E0F7FA | Tertiary Container #006064 | On Tertiary Container | none |
| Member | Surface Container Highest #BDBDBD | Surface Container Highest #4D4D4D | On Surface | none |

Badge 样式:
- Height: 24px
- Padding: 4px 12px
- Corner Radius: 8px
- Text: Label Small (11pt, 500)

**悬停状态**:

| 属性 | 值 |
|------|-----|
| Border Color | Primary |
| Shadow | BoxShadow(blurRadius: 8, offset: Offset(0, 4), color: shadow.withAlpha(0.12)) |
| Transform | translateY(-2px) |
| Duration | 150ms |
| Curve | ease-in-out |

**按下状态**:

| 属性 | 值 |
|------|-----|
| Scale | 0.98 |
| Duration | 100ms |

---

### 3.3 团队网格布局 (Team Grid)

```
Component: Team Grid
└── GridView
    ├── CrossAxisCount: 3 (>= 1280px) / 2 (>= 900px) / 1 (< 900px)
    ├── MainAxisExtent: 160px
    ├── CrossAxisSpacing: 16px
    ├── MainAxisSpacing: 16px
    └── Padding: 0
```

| 断点 | CrossAxisCount | 卡片宽度 |
|------|---------------|---------|
| >= 1280px | 3 | ~380px |
| >= 900px | 2 | ~380px |
| < 900px | 1 | 100% |

---

### 3.4 空状态 (Empty State)

当用户没有加入任何团队时显示：

```
Component: Empty Team List State
├── Centered Content
│   ├── Icon: groups_outlined, 80px, On Surface Variant 40% opacity
│   ├── Title "暂无团队" (Headline Small, On Surface)
│   ├── Description "您还没有加入任何团队，创建一个新团队开始协作"
│   │   (Body Medium, On Surface Variant, max-width 400px, center-aligned)
│   └── Action: FilledButton.icon "创建团队"
│       ├── Icon: add
│       └── Label: "创建团队"
```

| 属性 | 值 (Light) | 值 (Dark) |
|------|-----------|----------|
| Icon Color | On Surface Variant 40% | On Surface Variant 40% |
| Title Color | On Surface | On Surface |
| Description Color | On Surface Variant | On Surface Variant |
| Background | Transparent | Transparent |

---

### 3.5 加载状态 (Loading State)

```
Component: Team List Loading
├── Skeleton Cards Grid (same layout as Team Grid)
│   └── Skeleton Card (3 items)
│       ├── Icon Placeholder (56px circle)
│       ├── Title Placeholder (120px × 16px)
│       └── Subtitle Placeholder (80px × 12px)
```

骨架屏样式:
- Background: Surface Container Highest with 30% opacity
- Animation: Shimmer (left-to-right gradient sweep)
- Duration: 1.5s, infinite

---

## 4. 状态设计

### 4.1 列表加载状态

```
State: Loading
├── Full page: Centered CircularProgressIndicator (48px)
└── Or: Skeleton cards (preferred)
```

### 4.2 列表错误状态

```
State: Error
├── Icon: error_outline, 64px, Error color
├── Title "加载失败" (Title Medium)
├── Description "无法获取团队列表，请检查网络连接后重试" (Body Medium)
└── Action: FilledButton "重试"
```

### 4.3 创建团队对话框触发

点击"创建团队"按钮后弹出对话框 (详见 `resource_creation.md` 中的 Create Team Dialog)。

---

## 5. 交互设计

### 5.1 卡片交互

| 交互 | 触发 | 行为 | 视觉反馈 | 动画 |
|------|------|------|---------|------|
| 悬停卡片 | 鼠标移入 | 准备点击 | 边框变 Primary, 上移 2px, 阴影提升 | 150ms ease-in-out |
| 按下卡片 | 鼠标按下 | 确认点击 | 缩放 0.98 | 100ms ease-out |
| 点击卡片 | 鼠标释放 | 导航到团队详情 | 页面路由跳转 /teams/:id | 页面过渡 300ms |
| 点击创建 | 点击按钮 | 打开创建对话框 | 对话框从中心缩放出现 | 200ms decelerate |

### 5.2 页面级交互

| 交互 | 触发 | 行为 | 视觉反馈 |
|------|------|------|---------|
| 下拉刷新 | 列表区域下拉 | 重新加载团队列表 | RefreshIndicator |
| AppBar 团队切换 | 点击 AppBar 选择器 | 切换到其他团队上下文 | 全局状态更新，内容区域刷新 |

---

## 6. 主题变体

### 6.1 浅色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 页面背景 | #FAFAFA | Surface Container Lowest |
| 卡片背景 | #FFFFFF | Surface |
| 卡片边框 | #EEEEEE | Outline Variant |
| 团队图标背景 | #BBDEFB | Primary Container |
| 团队图标颜色 | #1565C0 | On Primary Container |
| 主要文字 | #212121 | On Surface |
| 次要文字 | #757575 | On Surface Variant |
| Owner 徽章背景 | #BBDEFB | Primary Container |
| Admin 徽章背景 | #E0F7FA | Tertiary Container |
| Member 徽章背景 | #BDBDBD | Surface Container Highest |

### 6.2 深色主题

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 页面背景 | #121212 | Surface |
| 卡片背景 | #1E1E1E | Surface Container Low |
| 卡片边框 | #333333 | Outline Variant |
| 团队图标背景 | #1565C0 | Primary Container |
| 团队图标颜色 | #E3F2FD | On Primary Container |
| 主要文字 | #F5F5F5 | On Surface |
| 次要文字 | #9E9E9E | On Surface Variant |
| Owner 徽章背景 | #1565C0 | Primary Container |
| Admin 徽章背景 | #006064 | Tertiary Container |
| Member 徽章背景 | #4D4D4D | Surface Container Highest |

---

## 7. 响应式规则

### 7.1 桌面端 (>= 1280px)

- 侧边栏: 240px 展开
- 团队网格: 3 列
- 卡片间距: 16px
- 页面内边距: 24px

### 7.2 平板端 (>= 768px and < 1280px)

- 侧边栏: 72px 折叠（图标-only）
- 团队网格: 2 列
- 卡片间距: 16px
- 页面内边距: 16px

### 7.3 小屏 (< 768px)

- 侧边栏: 隐藏，底部导航
- 团队网格: 1 列
- 卡片间距: 12px
- 页面内边距: 12px
- "创建团队"按钮变为 FAB (FloatingActionButton)

---

## 8. 动画与动效

### 8.1 列表加载动画

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 卡片进入 | 200ms | decelerate | 卡片从下方淡入，stagger 50ms |
| 骨架屏闪烁 | 1500ms | linear | 无限循环 shimmer |
| 卡片悬停 | 150ms | ease-in-out | 上移 + 边框变色 + 阴影 |
| 卡片按下 | 100ms | ease-out | 缩放 0.98 |

### 8.2 页面过渡

| 动画 | 时长 | 缓动 | 说明 |
|------|------|------|------|
| 列表→详情 | 300ms | ease-in-out | 页面滑动 + 淡入 |
| 对话框出现 | 200ms | decelerate | 缩放 + 淡入 |
| 对话框消失 | 150ms | accelerate | 缩放 + 淡出 |

---

## 9. 设计笔记

### 9.1 关键设计决策

1. **卡片式布局**: 选择卡片而非表格，因为：
   - 团队数量通常较少（< 20），卡片更适合浏览
   - 卡片可以展示更丰富的信息（图标、描述、徽章）
   - 与现有工作台列表页面的卡片式布局保持一致

2. **角色徽章颜色区分**: 
   - Owner 使用 Primary Container（最突出）
   - Admin 使用 Tertiary Container（次突出）
   - Member 使用中性灰（最不突出）
   - 颜色编码符合 RBAC 权限层级

3. **16px 圆角卡片**: 比现有工作台卡片的 12px 更大，因为：
   - 团队卡片内容更简洁，更大的圆角显得更友好
   - 与"团队协作"的社交属性更匹配

### 9.2 可访问性考量

- 角色徽章不仅靠颜色区分，文字标签始终可见
- 卡片悬停状态有明显边框变化（不仅依赖颜色）
- 空状态提供明确的操作指引
- 所有交互元素触摸目标 >= 48x48dp

### 9.3 与现有设计的关系

- 页面布局复用现有 AppShell (Sidebar + Breadcrumb + Content)
- 卡片样式基于现有 `Standard Card` 规范扩展
- 空状态组件复用现有 `EmptyStateWidget` 模式
- 按钮复用现有按钮规范
- AppBar 新增团队选择器 (详见 `appbar_team_selector.md`)
- Sidebar 新增 "团队" 导航项，图标使用 `groups`

### 9.4 图标映射

| 功能 | 图标名称 | 来源 |
|------|---------|------|
| 团队导航 | groups | Material Symbols |
| 创建团队 | add | Material Symbols |
| 团队默认图标 | groups | Material Symbols |
| 成员数量 | people | Material Symbols |
| 空状态 | groups_outlined | Material Symbols |
| 进入详情 | chevron_right | Material Symbols |
| 设置 | settings | Material Symbols |
| 离开团队 | logout | Material Symbols |
| 删除团队 | delete | Material Symbols |

---

**文档结束**
