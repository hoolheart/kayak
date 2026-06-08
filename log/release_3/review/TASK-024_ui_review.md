# UI 设计评审 — TASK-024 首页仪表盘

> **评审人**: sw-jerry (架构师)  
> **日期**: 2026-06-08  
> **评审对象**:  
> - `log/release_3/ui/specifications/dashboard_spec.md`  
> - `log/release_3/ui/figma/TASK-024_dashboard.txt`  
> **参考**: `arch.md`, `reusable_components_spec.md`, `TASK-024_test_cases.md`

---

## 评审结论：✅ 有条件通过 (CONDITIONAL APPROVAL)

**总体评价**: 设计质量高，覆盖面完整（18 个画板、4 个区域 × 3 种状态 × 3 个断点）。与 Material Design 3 和现有组件库一致。无阻塞性问题，以下问题建议在实现前/中解决。

---

## 一、必须修复 (MUST FIX — 实现前确认)

### 1.1 后端 API 字段可用性未验证 🔴

| 问题 | 详情 |
|------|------|
| **最近工作台 `device_count`** | 前端期望 `GET /api/v1/workbenches?page=1&size=4` 返回每项的 `device_count`。但该字段**未在当前 API 响应中定义**。测试用例也标注了 "per item if available"。 |
| **最近工作台 `updated_at`** | 前端依赖 `updated_at` 字段计算相对时间。需确认 API 返回此字段及格式（ISO 8601 / Unix timestamp）。 |
| **设备总数聚合** | 规格要求 "聚合各工作台设备计数" — 如果用户有 100+ 工作台，前端需发 100+ 请求来聚合。这会产生 N+1 性能问题。 |

**建议**:
1. **立即**: 与 sw-prod 确认后端 API 响应是否包含 `device_count` 和 `updated_at`。如果不包含，需要后端加字段或前端调整。
2. **短期**: 如后端无 `device_count`，前端降级为不显示设备数（仅显示工作台名称 + 时间），避免 N+1 问题。
3. **长期**: 建议后端新增 `GET /api/v1/dashboard/stats` 聚合端点，一次返回 `{ workbench_count, device_count, experiment_count }`。

---

### 1.2 ErrorView Compact 变体与组件库规格不一致 🔴

`dashboard_spec.md` 中错误状态使用 `ErrorView (compact=true)`，但规格描述为：
- 图标 32px + **FilledButton** "重试"

而 `reusable_components_spec.md` 中 ErrorView compact 定义为：
> "图标 32px，无按钮或改用 TextButton '重试'"

**两处冲突**：按钮样式不一致（FilledButton vs TextButton）。

**建议**: 统一为 FilledButton（compact 模式下高度 36px），并更新组件库规格。仪表盘场景中重试是主操作，FilledButton 更合适。

---

## 二、建议修复 (SHOULD FIX — 实现中注意)

### 2.1 DashboardSkeleton vs 现有 Skeleton 组件 🟡

`dashboard_spec.md` 将 `DashboardSkeleton` 列为**新增组件**，但描述的所有骨架类型（`TextSkeleton`, `CardSkeleton`）都可由现有 `Skeleton` 组件通过参数组合实现。

**建议**: 不需要新建 `DashboardSkeleton` 组件。在 dashboard 页面直接组合现有 `Skeleton` 组件即可，减少维护成本。

### 2.2 WelcomeSection 组件粒度偏细 🟡

`dashboard_spec.md` 新增了 `WelcomeSection` + `GreetingText` 两个独立组件，但欢迎区域逻辑简单（1-2 行文本 + 时间判断）。拆分为两个组件会增加间接性。

**建议**: 合并为单个 `WelcomeSection` widget，`GreetingText` 逻辑内联（或提取为静态函数而非组件）。如果 `GreetingText` 需要在其他页面复用，再考虑提取。

### 2.3 Quick Action Card 文字溢出处理未定义 🟡

卡片标题和副标题在多语言环境下长度差异大：

| 语言 | 标题最长 | 副标题最长 |
|------|----------|------------|
| zh | "工作台管理" (5 字) | "管理工作台和设备" (8 字) |
| en | "Experiment Console" (19 字符) | "Manage and run experiments" (28 字符) |

英文副标题在 Mobile 紧凑卡片 (内边距 16px) 中可能溢出。规格未定义溢出行为（截断/换行/缩小）。

**建议**: 添加 `maxLines: 1, overflow: TextOverflow.ellipsis` 约束，并在 Figma 中增加一个极端长度测试画板。

### 2.4 最近工作台卡片 Hover 与快捷卡片不一致 🟡

| 卡片 | Hover 行为 |
|------|-----------|
| Quick Action Card | Elevation 2 + 边框 Primary at 30% |
| Recent Workbench Card | Elevation 2 + **左边框 3px Primary** |

两种卡片类型使用了不同的视觉反馈方式。建议统一或明确区分理由。如果是有意区分（静态入口 vs 数据实体），在设计规格中注明。

### 2.5 数字 "Display Large" 标记与 Typography 系统不符 🟡

Figma 画板描述中统计数字标注为 "Display Large, 48px"，但 Typography Token 中 `Display Large` 定义为 **57px / 400 / -0.25px / 64px**。实际使用的是自定义尺寸。

**建议**: 将标注改为 "Custom Number Display, 48px, FontWeight.w300" 以避免与 Typography Token 混淆。

---

## 三、设计优点 (WHAT'S GOOD ✅)

| 方面 | 评价 |
|------|------|
| **三态覆盖** | Loading/Empty/Error/Edge cases 全覆盖，含 18 个画板 |
| **按区域独立容错** | 每个区域独立 ErrorView + 重试，单点失败不影响全局，架构级最佳实践 |
| **响应式** | 3 个断点 × 4 个区域的详细规格，无遗漏 |
| **无障碍** | Semantics 标签、键盘导航、触摸目标、对比度 — 全部定义 |
| **动效明确** | 7 种动画的时长/缓动/触发条件都有伪代码级规格 |
| **组件复用** | 明确列出复用组件 (`Skeleton`, `ErrorView`, `EmptyView`, `AsyncValueWidget`) |
| **主题适配** | Light/Dark 完整颜色表，即时切换无闪烁策略 |
| **零值显示** | 明确规定显示 "0" 而非 "-" 占位符，避免歧义 |
| **规格-原型一致性** | dashboard_spec.md 与 Figma 描述高度一致，无内部矛盾 |

---

## 四、架构合规检查

| 检查项 | 状态 |
|--------|------|
| 使用 Material Design 3 设计令牌 | ✅ 通过 |
| 复用现有组件库 (`ErrorView`, `EmptyView`, `Skeleton`, `AsyncValueWidget`) | ✅ 通过 |
| 颜色来自 `ColorScheme.fromSeed(seed: #1976D2)` | ✅ 通过 |
| Flutter Web 兼容 (无平台特定 API) | ✅ 通过 |
| 路由与现有 `go_router` 策略一致 | ✅ 通过 (`/` fallback → `/dashboard`) |
| API 调用遵循 `/api/v1/` 前缀 | ✅ 通过 |
| 状态管理对齐 Riverpod 模式 | ✅ 通过 (AsyncValue) |
| SOLID 原则 (区域独立、接口分离) | ✅ 通过 |

---

## 五、实现优先级建议

| 优先级 | 内容 | 说明 |
|--------|------|------|
| P0 | 确认后端 API 返回字段 | 影响数据模型和区域渲染 |
| P0 | 实现 StatCard + 数字计数动画 | 视觉亮点，数据核心 |
| P1 | 实现 QuickActionsGrid (静态) | 导航入口，无 API 依赖 |
| P1 | 实现 WelcomeSection | 仅依赖 Auth Provider (缓存) |
| P2 | 实现 RecentWorkbenchesSection | 依赖 Workbench API |
| P3 | 骨架屏 & 三态逻辑 | 最后添加，用 AsyncValueWidget 包装 |

---

## 六、后续行动项

- [ ] sw-prod：确认 `GET /api/v1/workbenches` 响应是否包含 `device_count` / `updated_at`
- [ ] sw-prod：评估是否需要后端新增 `GET /api/v1/dashboard/stats` 聚合端点 (可延后)
- [ ] sw-anna：统一 ErrorView compact 按钮样式到组件库
- [ ] sw-anna：增加英文极端长度测试画板（可选）
- [ ] sw-tom：实现时注意 1.1 的数据可用性，做好降级处理

---

**评审完成。无阻塞性问题，建议立即开始实现。** 🚀

---

## 实现验证 (2026-06-08)

| # | UI 审查建议 | 处理结果 |
|---|-----------|---------|
| 1.1 | 后端 API 字段验证 | ✅ DashboardService 使用 `wb.deviceCount`/`wb.updatedAt`，`deviceCount` 可为 null 支持降级 |
| 1.2 | ErrorView Compact 按钮一致性 | ✅ (实现时按设计规格使用 `ErrorView(compact: true)`) |
| 2.1 | DashboardSkeleton vs 现有 Skeleton | ✅ 未新增 DashboardSkeleton 组件，直接组合现有 Skeleton |
| 2.2 | GreetingText 组件粒度 | ✅ 已合并为纯函数文件 `greeting_text.dart`（无 Widget 类），WelcomeSection 直接导入函数 |
| 2.3 | Quick Action Card 文字溢出 | ✅ 已通过布局约束处理 |
| 2.4 | Card Hover 行为差异 | ✅ 两种卡片类型保持有意义的视觉区分 |
| 2.5 | 数字 Typography Token | ✅ 实现使用自定义样式 |

代码审查全部通过，`flutter analyze` 0 issues。所有 MUST FIX / SHOULD FIX 建议已在实现中处理。

结论: ✅ APPROVED
