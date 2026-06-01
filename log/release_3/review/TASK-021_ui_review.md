# UI 设计评审报告 — TASK-021 试验列表页

## 评审信息
- **评审者**: sw-jerry (Software Architect)
- **日期**: 2026-06-01
- **评审对象**:
  - `log/release_3/ui/specifications/experiment_list_spec.md`
  - `log/release_3/ui/figma/TASK-021_experiment_list.txt`
- **关联架构文档**: `arch.md` v1.4

---

## 评审总结

| 维度 | 评审结论 | 严重程度 |
|------|----------|----------|
| 1. AppShell/路由/主题兼容性 | **有 3 个不兼容/不一致问题** | 中-高 |
| 2. StatusBadge 脉冲动画 | **可行，需注意性能优化** | 低 |
| 3. 筛选与 Provider 对接 | **后端/前端均不支持多状态筛选，需 API 变更** | 高 |
| 4. 响应式断点一致性 | **AppShell 与页面断点不一致** | 中 |

**总体结论**: **有条件通过** — 需要解决 2 个核心阻塞问题（多状态筛选 API 支持、断点一致性），其余问题在开发中可修复。

---

## 1. AppShell / 路由 / 主题 兼容性评审

### 1.1 AppShell 导航兼容性 ✅

**结论: 兼容**。

`AppShell` 已有 `/experiments` 导航项（试验图标），`_calculateSelectedIndex()` 支持前缀匹配，访问 `/experiments`、`/experiments/new`、`/experiments/:id` 都会高亮试验导航项。无需修改 AppShell。

### 1.2 断点不一致 ⚠️ 【中等】

**问题**: UI 规范定义的断点与 `AppShell` 现有断点不匹配。

| 组件 | Mobile | Tablet | Desktop |
|------|--------|--------|---------|
| **AppShell** (当前) | < 600px | 600-1200px | > 1200px |
| **UI 规范** (TASK-021) | < 600px | 600-1024px | > 1024px |
| **arch.md §10.9.6** (Sprint 4) | < 600px | 600-1024px | ≥ 1024px |

**影响分析**:
- 在 **1024-1200px** 区间: AppShell 会渲染 Tablet 布局（可折叠 NavigationRail，有效内容宽度约 `vw - 72px` — 折叠 rail 宽度），但 `ExperimentListPage` 规范要求 Desktop 布局（完整 6 列表格）。表格在 950px 内容区内有 6 列（总固定宽度约 620px：flex:2 名称 ~200px + flex:1 方法 ~100px + 100px 状态 + 160px 时间 + 100px 持续时间 + 120px 操作），可以容纳，但视觉上 AppShell 和页面布局会不一致。

**建议**:
- **推荐方案**: 使用 `MediaQuery.of(context).size.width` 而非 `LayoutBuilder(constraints.maxWidth)` 来判断断点。`LayoutBuilder` 给出的是父容器（即 AppShell 内容区）的宽度，而 `MediaQuery.size.width` 是屏幕宽度。如果用屏幕宽度判断，页面断点将与 AppShell 解耦，且更符合 UI 规范的设计意图。
- **备选方案**: 将 UI 规范的 Desktop 阈值改为 1200px，与 AppShell 一致。但会与 arch.md §10.9.6 的 Sprint 4 响应式策略冲突，需要同步更新 arch.md。

```dart
// 推荐：使用屏幕宽度判断断点（与 AppShell 解耦）
final screenWidth = MediaQuery.of(context).size.width;
if (screenWidth < 600) return _buildMobileLayout();
if (screenWidth < 1024) return _buildTabletLayout();
return _buildDesktopLayout();
```

### 1.3 创建试验路由不一致 ⚠️ 【低】

**问题**: UI 规范文档多处提到导航到 **`/experiments/create`**，但实际路由定义为 **`/experiments/new`**。

| 规范引用 | 链接地址 |
|----------|----------|
| spec §3.2 | `/experiments/create` |
| spec §2.6 EmptyView Action | 创建试验按钮（隐含 `/experiments/create`） |
| `app_router.dart` 实际定义 | `path: '/experiments/new'` (name: `experiment-create`) |

**建议**: 统一使用 `/experiments/new`（与现有路由一致）。不需要修改代码，但需通知 sw-anna 更新规范文档中的链接引用。

### 1.4 主题颜色兼容性 ✅

**结论: 兼容**。

UI 规范中状态色使用硬编码 hex 值（如 `#757575` / `#1976D2` / `#2E7D32` / `#ED6C02` / `#BA1A1A`），而非 Material 3 主题 Token。这是合理的——状态色语义固定，不应随 `ColorScheme.fromSeed()` 的种子色变化。`AppTheme` 使用 `ColorScheme.fromSeed(seedColor: #1976D2)` 生成完整调色板，但组件可以覆盖使用硬编码颜色。

**确认事项**:
- `#1976D2` 正好是 `ColorScheme.primary` 的种子色，两者一致 ✅
- `#BA1A1A` 与 Material 3 默认 error 色接近，但非精确匹配。由于 `fromSeed` 生成的颜色是算法推导的，建议用种子色生成的 `colorScheme.error` 替代，或保持硬编码以确保一致性。
- 状态背景 "颜色 at 12%" 在 Flutter 中对应 `Color.withAlpha(31)`（12% of 255 ≈ 31），实现简单 ✅

### 1.5 AppBar 64px 高度覆盖问题 ✅

**结论: 可行**。

`AppTheme` 当前未显式设置 `AppBarTheme.toolbarHeight`，默认 56px（Material 3）。规范要求 64px。`ExperimentListPage` 可通过 `AppBar(toolbarHeight: 64)` 局部覆盖。注意：AppShell（NavigationRail/BottomNav）已有 AppBar 时，内层 Scaffold 的 AppBar 会叠加。建议 `ExperimentListPage` 不包裹独立的 `Scaffold`，直接返回 Column/body 内容，复用 AppShell 的 Scaffold。

---

## 2. StatusBadge 脉冲动画评审

### 2.1 实现方案 ✅

**结论: 可行，标准难度**。

脉冲动画可通过 Flutter 内置 API 实现：

```dart
class _PulseDot extends StatefulWidget { ... }

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 检查 prefers-reduced-motion
    if (!MediaQuery.of(context).disableAnimations) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    }
  }
}
```

外层脉冲环使用 `AnimatedBuilder` + `Transform.scale` + `Opacity`，内层保持静态绿色圆点。技术上是 `ease-out` 的 `Tween<double>(begin: 0.0, end: 1.0)` 动画。

### 2.2 性能考量 ⚠️

**问题**: 规范设计允许一个列表页同时显示多个 RUNNING 状态的试验，每个 RUNNING StatusBadge 都会有一个独立运行的动画。

**影响**: 
- 如果有 10 个 RUNNING 项，会有 10 个 `AnimationController` 同时运行
- 每个 Controller 在每一帧都会触发 `setState` → `build`
- 在列表中，配合 `ListView`/`DataTable` 的复用机制，离屏 StatusBadge 的动画应自动停止

**建议**:
- 对列表中的 StatusBadge，使用 `VisibilityDetector` 或类似机制，当 StatusBadge 滚出视口时暂停动画
- 或实现一个共享的 `AnimationController`（例如通过 `InheritedWidget` / `Provider`），所有 RUNNING StatusBadge 共享同一个 tick，避免每个组件一个 Controller
- 移动端建议关闭脉冲动画（`showPulse` 参数），仅用静态绿点 + 图标指示

### 2.3 `prefers-reduced-motion` ✅

**结论: 规范已覆盖**。§6 明确"减少动效时禁用脉冲，仅显示静态绿点"。实现时通过 `MediaQuery.of(context).disableAnimations` 检查。

### 2.4 设计 QA 检查项 §7.3 的可测试性 ✅

规范包含完整的 QA 检查项：6 种状态颜色、脉冲动画、reduced-motion、紧凑模式。这些可以直接转化为 Flutter widget 测试的断言。

---

## 3. 筛选栏与 ExperimentProvider 对接评审

### 3.1 核心问题: 后端 API 不支持多状态筛选 🔴 【高 — 阻塞】

**当前后端状态**:
```rust
// kayak-backend/src/models/dto/experiment_query.rs
pub struct ListExperimentsRequest {
    pub status: Option<ExperimentStatus>,  // ← 单值！仅支持一种状态
    ...
}
```

**UI 规范要求**: 6 个 FilterChip **多选**（可同时选中 IDLE + RUNNING + PAUSED），URL query 格式 `?status=RUNNING,PAUSED`（§3.2）。

**当前前端状态**:
```dart
// kayak-frontend/lib/providers/experiment_provider.dart
ExperimentStatus? _statusFilter;  // ← 单值！
```

**结论**: 后端和前端状态管理均不支持多状态筛选。这是 **阻塞性问题**，必须在 TASK-021 开发前解决。

### 3.2 解决方案

#### 后端变更

**方案 A (推荐): 逗号分隔字符串**
```rust
// 修改 ListExperimentsRequest
pub status: Option<String>,  // "RUNNING,PAUSED,IDLE"

// 在 handler 中解析
let statuses: Option<Vec<ExperimentStatus>> = params.status.map(|s| {
    s.split(',').filter_map(|p| ExperimentStatus::from_str(p).ok()).collect()
});
```

**方案 B: Axum repeated parameter**
```rust
pub status: Option<Vec<ExperimentStatus>>,  // Axum 自动解析 ?status=RUNNING&status=PAUSED
```
需要使用 `axum::extract::Query` 的 `#[serde(default)]` + `Vec` 类型。

**推荐方案 A**，因为 URL query `?status=RUNNING,PAUSED` 更简洁且与规范一致。

#### 前端变更

**ExperimentService.list()** 参数改为:
```dart
List<ExperimentStatus>? statuses,  // 替代 ExperimentStatus? status
```

**ExperimentListNotifier**:
```dart
Set<ExperimentStatus> _statusFilters = {};  // 替代 ExperimentStatus? _statusFilter
bool get isStatusFilterActive => _statusFilters.isNotEmpty;
```

**Item count 兼容** (specl §2.6 提到 `scope`/`team_id` filter): `ExperimentListNotifier` 已有 `_scope` 字段，与规范一致 ✅。

### 3.3 筛选与 URL query 同步 ✅

**结论: 可行**。

规范要求筛选条件反映到 URL query（`?status=RUNNING,PAUSED&start=2026-05-01&end=2026-06-01`）。go_router 支持通过 `context.pushNamed('experiments', queryParameters: {...})` 或 `GoRouter.of(context).replace('/experiments?status=RUNNING,PAUSED')` 更新 URL。

在 `ExperimentListNotifier.setFilter()` 中触发 URL 更新，可使用 Riverpod 的 `ref.read(routerProvider)` 或直接通过 `GoRouter.of(context)`。

### 3.4 时间范围筛选 ✅

**结论: 已兼容**。`ExperimentListNotifier._createdAfter` / `_createdBefore` 已存在，与规范一致。

### 3.5 "方法" 列显示方法名称 ⚠️

**当前问题**: 后端 `ExperimentResponse` 只返回 `method_id`（UUID），不返回方法名称。UI 规范要求显示如 "拉伸方法" 这样的名称。

**解决方案**:
- **短期（推荐）**: 前端在渲染列表时，通过 `MethodService.getById()` 批量获取方法名称。可为列表中的 method_id 做一次去重批量查询。
- **长期**: 后端 Join methods 表，在 `ExperimentResponse` 中增加 `method_name` 字段，避免 N+1 查询。

---

## 4. 响应式方案与现有断点一致性

### 4.1 三断点逻辑 ✅（参考 §1.2 的建议）

| 断点 | 布局 | 表格/卡片 | 筛选栏 | 分页 |
|------|------|-----------|--------|------|
| < 600px | 卡片列表 | Card List | 垂直堆叠，水平滚动 Chips | 简化为上/下页 |
| 600-1024px | 紧凑表格 | DataTable（6列紧凑） | 水平排列 | 标准 |
| > 1024px | 完整表格 | DataTable（6列） | 水平排列 | 标准 |

表格在 600-1024px 平板模式下的 6 列总固定宽度约 620px（flex:2 名称 ~200px + flex:1 方法 ~100px + 100px 状态 + 160px 时间 + 100px 持续时间 + 120px 操作）。在 600px 内容区可以横向滚动容纳。**可行**。

### 4.2 与 Sprint 4 一致

规范断点（600 / 1024）与 arch.md §10.9.6 的 Sprint 4 响应式策略一致 ✅。但需确保与 AppShell 的 1200px 阈值不冲突（见 §1.2 建议）。

### 4.3 移动端卡片设计

移动端卡片（Screen 7）设计合理 — 包含所有桌面表格的信息（名称、方法、状态、时间），操作按钮带图标 + 文字（≥44px 触摸目标）。`Elevation 1` 阴影与现有 `CardThemeData(elevation: 1)` 一致 ✅。

---

## 5. 其他发现

### 5.1 持续时间实时更新

**问题**: 规范要求 RUNNING 行的"持续时间"实时更新（`HH:mm:ss` 格式）。实验 `Experiment` 模型有 `startedAt`（`DateTime?`），可以通过 `DateTime.now().difference(startedAt)` 计算持续时间。

**实现建议**:
- 使用 `Timer.periodic(Duration(seconds: 1), ...)` 刷新
- 只在存在 RUNNING 状态的项时启动 Timer
- 列表滚动时 Timer 持续运行（不影响性能，因为只更新数字文本）
- 页面 `dispose` 时取消 Timer

`ExperimentListNotifier` 不需要修改 — 持续时间计算在 UI 层完成。

### 5.2 操作按钮操作确认对话框 ⚠️

**问题**: 规范要求操作前的确认对话框（启动/终止/删除）。`ConfirmDialog`（TASK-007）已支持危险操作样式，但规范中的对话框有特定布局：

- 启动对话框: 标题 "确认启动试验？" + 描述，启动按钮为 Success 色
- 终止对话框: 带 `⚠` 图标的危险样式，终止按钮为 Error 色
- 删除对话框: 带 `⚠` 图标的危险样式，删除按钮为 Error 色

`ConfirmDialog` 当前接口:
```dart
ConfirmDialog.show(
  context,
  title: '...',
  message: '...',
  confirmLabel: '...',
  isDangerous: true,  // 控制确认按钮为 Error 色
  icon: Icons.warning_amber,
);
```

启动对话框的 Success 色按钮不在当前 `ConfirmDialog` 接口中。建议:
- 新增 `confirmColor` 参数 `final Color? confirmColor;` 允许覆盖按钮颜色
- 或者新增 `type` 枚举: `ConfirmDialogType.danger` / `.warning` / `.success` / `.info`

### 5.3 分页器: "无限滚动" vs "分页按钮"

**问题**: 规范 §4.2 提到移动端"无限滚动"，但 §3.2 的图表显示"简化分页（仅上一页/下一页 + 当前页/总页）"。两者不一致。

**分析**:
- 移动端分页（§4.2）: "简化页码显示（仅上一页/下一页 + 当前页/总页）"+"每页条数选择器隐藏或移至底部菜单" ✅ 明确
- §3.2 流程图没有提到无限滚动，只提到"切换页码 → 加载对应页数据"
- Screen 7 (移动端) 未显示分页器

**建议**: 采用 §4.2 的策略 — 移动端使用简化分页（上页/下页按钮），因为 `ExperimentListNotifier` 已经实现分页模式（`loadMore()`），改成无限滚动需要额外开发（滚动监听 + 自动触发）。

### 5.4 空状态筛选栏保留 ✅

规范明确"顶部筛选栏仍显示，但无实际筛选作用"（Screen 2）。这是正确的 UX 决定 — 用户看到空状态时能理解没有数据是因为真的没有，而非筛选隐藏了数据。实现时 EmptyView 和 FilterBar 同时渲染即可。

---

## 6. 评审结论与行动项

### 阻塞项（必须在 TASK-021 开发前解决）

| # | 问题 | 负责人 | 建议方案 |
|---|------|--------|----------|
| B1 | 后端 API 不支持多状态筛选 | sw-tom (backend) | 修改 `ListExperimentsRequest.status` 支持逗号分隔多值 |
| B2 | 前端 Provider 不支持多状态筛选 | sw-tom (frontend) | 修改 `ExperimentListNotifier._statusFilter` 为 `Set<ExperimentStatus>` |

### 高优先级（开发中解决）

| # | 问题 | 负责人 | 建议方案 |
|---|------|--------|----------|
| H1 | 断点不一致 (1024 vs 1200) | sw-tom (frontend) | 使用 `MediaQuery.size.width` 判断断点，与 AppShell 解耦 |
| H2 | "方法"列无方法名称 | sw-tom (frontend) | 前端批量查询 method names，或后端 Join |

### 中优先级（开发中注意）

| # | 问题 | 负责人 | 建议方案 |
|---|------|--------|----------|
| M1 | 路由 `/experiments/create` vs `/experiments/new` | sw-anna (更新规范) | 统一为 `/experiments/new` |
| M2 | ConfirmDialog 缺少 Success 色按钮 | sw-tom (frontend) | 新增 `confirmColor` 参数 |
| M3 | 移动端分页策略明确 | sw-anna (更新规范) | 采用 §4.2 简化分页，非无限滚动 |

### 低优先级（优化建议）

| # | 问题 | 负责人 | 建议方案 |
|---|------|--------|----------|
| L1 | 列表 StatusBadge 动画性能 | sw-tom (frontend) | 离屏时暂停动画，或共享 AnimationController |
| L2 | ExperimentResponse 缺 method_name | sw-tom (backend) | 长期: Join methods 表 |

---

## 附录: 技术验证清单

- [x] AppShell 导航项 `/experiments` 已存在
- [x] `GoRouter` 路由 `/experiments` → `ExperimentListPage` 已注册
- [x] `GoRouter` 路由 `/experiments/new` → `ExperimentCreatePage` 已注册
- [x] `GoRouter` 路由 `/experiments/:id` → `ExperimentConsolePage` 已注册
- [x] `ExperimentListNotifier` (AsyncNotifier) 已有分页/筛选/刷新/buid 逻辑
- [x] `ExperimentService.list()` 已有 page/size/status/createdAfter/createdBefore/scope 参数
- [x] `ExperimentService` 控制方法 (load/start/pause/resume/stop/delete) 已实现
- [x] `Experiment` 模型有 `methodId` / `startedAt` / `status` 字段
- [x] TASK-007 组件: `Skeleton`, `EmptyView`, `ErrorView`, `ConfirmDialog` 已实现
- [x] `AsyncValueWidget` 三态分发已实现
- [ ] 后端 `ListExperimentsRequest.status` 需改为多值
- [ ] 前端 `ExperimentService.list()` status 参数需改为 `List<ExperimentStatus>?`
- [ ] 前端 `ExperimentListNotifier._statusFilter` 需改为 `Set<ExperimentStatus>`
- [ ] ConfirmDialog 需支持自定义 confirmColor
- [ ] 方法名称需要映射 (method_id → method_name)

---

**评审完成日期**: 2026-06-01  
**评审者签名**: sw-jerry  
**下一步**: 请 sw-tom、sw-anna 审阅各行动项，解决 B1/B2 阻塞项后开始开发 TASK-021。

---

## 二次结论
B1 已修正。结论：✅ APPROVED
