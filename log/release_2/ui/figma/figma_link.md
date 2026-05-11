# Figma 原型链接 - 团队管理前端 (R2-S2-002-A)

**项目**: Kayak 数据 acquisition 平台  
**任务ID**: R2-S2-002-A  
**设计师**: sw-anna  
**日期**: 2026-05-11  
**状态**: 设计完成

---

## Figma 文件信息

由于当前环境无法直接生成 `.fig` 二进制文件，设计文档以 Markdown 格式保存在以下位置，包含完整的 Figma 规格说明：

| 页面/组件 | 文档路径 | 说明 |
|---------|---------|------|
| 团队列表页 | `log/release_2/ui/figma/teams_list.md` | `/teams` 页面设计 |
| 团队详情页 | `log/release_2/ui/figma/team_detail.md` | `/teams/:id` 页面设计 |
| AppBar 团队选择器 | `log/release_2/ui/figma/appbar_team_selector.md` | 全局上下文切换组件 |
| 资源创建对话框 | `log/release_2/ui/figma/resource_creation.md` | 归属选择更新设计 |

## 设计规范文档

| 文档 | 路径 | 说明 |
|------|------|------|
| 团队管理 UI 设计规范 | `log/release_2/ui/specifications/team_management_ui_spec.md` | 完整设计规范 |

---

## 页面清单验证

### ✅ 1. 团队列表页面 (`/teams`)
**文档**: `teams_list.md`

- [x] 团队卡片网格布局（响应式 1/2/3 列）
- [x] 团队卡片：名称、描述、成员数、角色徽章
- [x] "创建团队"按钮
- [x] 空状态（无团队时）
- [x] 加载状态（骨架屏）
- [x] 错误状态
- [x] 浅色/深色主题

### ✅ 2. 团队详情/设置页面 (`/teams/:id`)
**文档**: `team_detail.md`

- [x] 团队信息卡片（名称、描述、统计信息）
- [x] 可编辑（Owner/Admin）
- [x] "删除团队"按钮（Owner only，带确认对话框）
- [x] "离开团队"按钮（Member/Admin，Owner 不可见）
- [x] 危险区域视觉设计（Error Container 背景）
- [x] 浅色/深色主题

### ✅ 3. 成员管理（团队详情页内）
**文档**: `team_detail.md` (Members Section)

- [x] 成员列表（头像、名称、邮箱、角色）
- [x] 角色徽章（Owner/Admin/Member 颜色区分）
- [x] "邀请成员"按钮（Owner/Admin）
- [x] "移除成员"按钮（Owner/Admin，不可移除 Owner）
- [x] 邀请对话框（邮箱输入 + 角色选择）
- [x] 角色变更操作（设为 Admin / 降为 Member）
- [x] 权限矩阵文档化

### ✅ 4. AppBar 团队选择器
**文档**: `appbar_team_selector.md`

- [x] AppBar 中的下拉选择器按钮
- [x] "个人空间"选项
- [x] 团队列表选项（带角色信息）
- [x] 当前选中标记
- [x] "创建新团队"快捷入口
- [x] 浅色/深色 AppBar 适配
- [x] 键盘导航支持

### ✅ 5. 资源创建对话框更新
**文档**: `resource_creation.md`

- [x] 归属选择区域（Radio 按钮组）
- [x] "个人空间"选项
- [x] "团队"选项（支持多团队展开）
- [x] 默认选中当前上下文
- [x] 团队权限提示信息
- [x] 无团队时的禁用状态
- [x] 适用于工作台/方法/试验创建

---

## 设计系统覆盖

### 色彩系统
- [x] 完整的浅色/深色主题色板
- [x] 角色徽章专用色（Owner/Admin/Member）
- [x] 危险区域专用色
- [x] 团队选择器专用色
- [x] 权限提示专用色
- [x] 与现有 `color_schemes.dart` 一致

### 字体系统
- [x] 复用现有 `AppTypography.textTheme`
- [x] 完整的字体使用映射表
- [x] 所有文本样式定义

### 组件规范
- [x] 团队卡片（含所有状态）
- [x] 成员列表项（含操作菜单）
- [x] AppBar 团队选择器（含下拉面板）
- [x] 归属选择器（Radio 组）
- [x] 危险区域卡片
- [x] 角色徽章（2 种尺寸）
- [x] 邀请成员对话框
- [x] 确认对话框（删除/离开/移除）

### 响应式断点
- [x] Desktop (>=1280px)
- [x] Tablet (>=768px and <1280px)
- [x] Mobile (<768px)

### 交互状态
- [x] Default / Hover / Focused / Pressed / Disabled / Selected / Loading / Error
- [x] 团队卡片状态矩阵
- [x] 成员列表项状态矩阵
- [x] 按钮状态矩阵

### 动画与动效
- [x] 页面级动画
- [x] 对话框动画
- [x] 微交互（悬停/按下/菜单/切换）
- [x] 缓动函数和时长定义

### 可访问性
- [x] WCAG 2.1 AA 对比度验证
- [x] 焦点指示定义
- [x] 屏幕阅读器标签
- [x] 键盘导航路径
- [x] 触摸目标尺寸

---

## 与现有代码的对应关系

| 设计文档 | 对应代码位置 | 说明 |
|---------|-------------|------|
| `teams_list.md` | `lib/features/team/screens/team_list_page.dart` (新) | 团队列表页面 |
| `team_detail.md` | `lib/features/team/screens/team_detail_page.dart` (新) | 团队详情页面 |
| `appbar_team_selector.md` | `lib/core/navigation/app_shell.dart` (修改) | AppBar 新增选择器 |
| `resource_creation.md` | `lib/features/workbench/widgets/create_workbench_dialog.dart` (修改) | 创建工作台对话框 |
| `resource_creation.md` | 方法/试验创建对话框 (修改) | 其他资源创建对话框 |

---

## 依赖的设计规范

- `log/release_1/ui/design_spec_v2.md` — Release 1 全局设计规范
- `kayak-frontend/lib/core/theme/app_theme.dart` — 应用主题配置
- `kayak-frontend/lib/core/theme/color_schemes.dart` — 颜色方案
- `kayak-frontend/lib/core/theme/app_typography.dart` — 字体排版

---

**文档结束**
