# TASK-021 详细设计文档 — 试验列表页面

> **任务**: 试验列表页面 UI (`/experiments`)  
> **依赖**: TASK-020 (ExperimentProvider, ExperimentService)  
> **PRD 章节**: M8 §试验列表验收标准  
> **UI 规范**: `experiment_list_spec.md`  
> **Figma 原型**: `TASK-021_experiment_list.txt`  
> **作者**: sw-tom  
> **日期**: 2026-06-01

---

## 目录

1. [组件树](#1-组件树)
2. [组件接口设计](#2-组件接口设计)
3. [数据流设计](#3-数据流设计)
4. [状态管理](#4-状态管理)
5. [响应式布局策略](#5-响应式布局策略)
6. [国际化 keys](#6-国际化-keys)
7. [动画设计](#7-动画设计)

---

## 1. 组件树

```
ExperimentListPage (ConsumerStatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── Title: "experiments" (l10n)
│   │   └── Actions: FilledButton "createExperiment" → /experiments/new
│   └── Body: Column
│       ├── _FilterBar (ConsumerWidget)
│       │   ├── _StatusDropdown
│       │   │   └── DropdownButton<ExperimentStatus?>
│       │   ├── _DateRangePicker
│       │   │   ├── TextField (start) + DatePicker
│       │   │   ├── Text ("~")
│       │   │   └── TextField (end) + DatePicker
│       │   └── TextButton "resetFilter"
│       └── Expanded
│           └── AsyncValueWidget<List<Experiment>>
│               ├── [loading] → _SkeletonTable / _SkeletonCardList
│               ├── [error]   → ErrorView + retry
│               ├── [empty]   → _EmptyState / _FilteredEmptyState
│               └── [data]    → Column
│                   ├── Expanded
│                   │   ├── [>=600px] _ExperimentDataTable
│                   │   │   ├── DataTable (header + rows)
│                   │   │   └── Row → {Name, Method, StatusBadge, Time, Duration, Actions}
│                   │   └── [<600px] _ExperimentCardList
│                   │       └── ListView.builder
│                   │           └── _ExperimentCard
│                   │               ├── Header: name + StatusBadge
│                   │               ├── Info: method, start time, duration
│                   │               └── Actions: buttons
│                   └── _PaginationBar
│                       ├── Text "totalRecords: N"
│                       ├── PaginationControls (page numbers)
│                       └── PageSizeSelector (10/20/50)

StatusBadge (StatefulWidget) — 可复用组件
├── [IDLE]      Container: grey 12% bg + grey dot + "idle"
├── [LOADED]    Container: blue 12% bg + blue dot + "loaded"
├── [RUNNING]   Container: green 12% bg + pulse animation + "running"
├── [PAUSED]    Container: orange 12% bg + pause icon + "paused"
├── [COMPLETED] Container: green 12% bg + check icon + "completed"
└── [ABORTED]   Container: red 12% bg + close icon + "aborted"
```

---

## 2. 组件接口设计

### 2.1 StatusBadge

```dart
class StatusBadge extends StatefulWidget {
  const StatusBadge({
    super.key,
    required this.status,      // 试验状态枚举
    this.showIcon = true,       // 是否显示状态图标/圆点
    this.showPulse = true,     // RUNNING 是否显示脉冲动画
    this.onTap,                // 点击回调（可选）
    this.compact = false,      // 紧凑模式（小屏使用）
  });

  final ExperimentStatus status;
  final bool showIcon;
  final bool showPulse;
  final VoidCallback? onTap;
  final bool compact;
}
```

**颜色映射**:

| 状态 | Light 文字/图标色 | Light 背景色 | Dark 文字/图标色 | Dark 背景色 |
|------|------------------|-------------|------------------|-------------|
| IDLE | `#757575` | `rgba(117,117,117,0.12)` | `#BDBDBD` | `rgba(189,189,189,0.12)` |
| LOADED | `#1976D2` | `rgba(25,118,210,0.12)` | `#90CAF9` | `rgba(144,202,249,0.12)` |
| RUNNING | `#2E7D32` | `rgba(46,125,50,0.12)` | `#81C784` | `rgba(129,199,132,0.12)` |
| PAUSED | `#ED6C02` | `rgba(237,108,2,0.12)` | `#FFB74D` | `rgba(255,183,77,0.12)` |
| COMPLETED | `#2E7D32` | `rgba(46,125,50,0.12)` | `#81C784` | `rgba(129,199,132,0.12)` |
| ABORTED | `#BA1A1A` | `rgba(186,26,26,0.12)` | `#FFB4AB` | `rgba(255,180,171,0.12)` |

**RUNNING 脉冲动画参数**:
- 动画类型: `AnimationController` + `ScaleTransition` + `FadeTransition`
- 外层圆环: 8px → 16px, opacity 1 → 0
- 时长: 1.5s 循环, ease-out 缓动
- 使用 `SingleTickerProviderStateMixin`
- `prefers-reduced-motion` 时禁用

### 2.2 ExperimentListPage

```dart
class ExperimentListPage extends ConsumerStatefulWidget {
  const ExperimentListPage({super.key});
}
```

**内部状态**:
- `_statusFilter`: `ExperimentStatus?` — 当前选中状态 (null = 全部)
- `_startDate`: `DateTime?` — 筛选起始日期
- `_endDate`: `DateTime?` — 筛选结束日期
- `_currentPage`: `int` — 当前页码 (通过 notifier 同步)
- `_pageSize`: `int` — 每页条数 (10/20/50)

---

## 3. 数据流设计

### 3.1 数据获取

```
ExperimentListPage
  └── ref.watch(experimentListProvider)
        └── ExperimentListNotifier.build()
              └── ExperimentService.list(page, size, status, createdAfter, createdBefore)
                    └── GET /api/v1/experiments?page=1&size=10&status=RUNNING&...
                          └── PaginatedResponse<Experiment>
```

### 3.2 操作流程

**筛选操作**:
```
用户选择状态/日期
  → 更新本地状态变量 (_statusFilter, _startDate, _endDate)
  → 调用 ref.read(experimentListProvider.notifier).setFilter(...)
  → 内部重置 _currentPage = 1, 更新筛选参数
  → 触发 API 请求
  → AsyncValue 更新 → UI 刷新
```

**分页操作**:
```
用户点击页码 N
  → 调用 ref.read(experimentListProvider.notifier).goToPage(N)
  → 更新 _currentPage = N
  → 触发 API 请求
  → AsyncValue 更新 → UI 刷新
```

**停止试验**:
```
用户点击停止 → ConfirmDialog
  → 确认 → ref.read(experimentControlProvider(id).notifier).stop()
  → 成功 → Toast "experimentStopped" → 刷新列表
  → 失败 → Toast 错误信息
```

**刷新**:
```
用户下拉刷新 / 点击重试
  → ref.read(experimentListProvider.notifier).refresh()
  → 重置到第 1 页
  → 触发 API 请求
```

### 3.3 Provider 接口扩展

需要在 `ExperimentListNotifier` 中新增 `goToPage(int page)` 方法：

```dart
Future<void> goToPage(int page) async {
  _currentPage = page;
  state = const AsyncLoading();
  state = await AsyncValue.guard(build);
}

Future<void> setPageSize(int size) async {
  _pageSize = size;
  _currentPage = 1;
  state = const AsyncLoading();
  state = await AsyncValue.guard(build);
}
```

---

## 4. 状态管理

### 4.1 页面级三态

| 状态 | 条件 | UI 表现 |
|------|------|---------|
| Loading | `AsyncLoading` | Skeleton 骨架屏 (5行) |
| Loaded (有数据) | `AsyncData` + items.isNotEmpty | DataTable / Card List |
| Loaded (无数据) | `AsyncData` + items.isEmpty | EmptyView |
| Loaded (筛选无结果) | `AsyncData` + items.isEmpty + 有筛选条件 | EmptyView (筛选变体) |
| Error | `AsyncError` | ErrorView + 重试按钮 |

### 4.2 筛选栏交互状态

| 控件 | 可用条件 | 禁用条件 |
|------|---------|---------|
| 状态下拉 | 始终可用 | — |
| 日期选择器 | 始终可用 | — |
| 重置按钮 | 有筛选条件 | 无筛选条件 (隐藏) |
| 创建按钮 | 始终可用 | — |

### 4.3 操作按钮状态

| 操作 | 可用条件 | Loading 状态 |
|------|---------|-------------|
| 进入控制台 | items.isNotEmpty | — |
| 停止 (RUNNING) | status == running/paused | 按钮 loading → 防重复 |
| 停止 (其他) | ❌ 不显示 | — |

---

## 5. 响应式布局策略

| 断点 | 导航 | 列表形式 | 筛选栏 | 分页 |
|------|------|---------|--------|------|
| < 600px (Mobile) | BottomNavigationBar | 卡片列表 | 垂直堆叠 | 简化 (上一页/下一页) |
| 600-1200px (Tablet) | NavigationRail | 表格紧凑列 | 水平排列 | 标准 |
| > 1200px (Desktop) | NavigationRail | 表格全列 | 水平排列 | 标准 |

### Mobile 卡片布局要点:
- 使用 `ListView.builder` + `Card`
- 每张卡片: 名称(左) + StatusBadge(右) → 方法 → 开始时间 → 持续时间 → 操作按钮
- RUNNING 卡片顶部 3px 绿色边框
- 操作按钮: 图标+文字, 全宽或等分
- 创建按钮: AppBar IconButton + 底部全宽按钮

### Desktop 表格布局要点:
- 使用 `DataTable` 或自定义 `Table`
- 6列: 名称(flex:2) / 方法(flex:1) / 状态(100px) / 开始时间(160px) / 持续时间(100px) / 操作(120px)
- 行高 52px, 表头高 48px
- 斑马纹支持, hover 效果
- RUNNING 行微弱绿色背景
- 操作按钮: IconButton 组

---

## 6. 国际化 keys

### 6.1 新增英文 keys (`app_en.arb`)

| key | 值 |
|-----|-----|
| `statusIdle` | "Idle" |
| `statusLoaded` | "Loaded" |
| `statusRunning` | "Running" |
| `statusPaused` | "Paused" |
| `statusCompleted` | "Completed" |
| `statusAborted` | "Aborted" |
| `allStatuses` | "All Statuses" |
| `filterStatus` | "Status" |
| `filterDateRange` | "Date Range" |
| `resetFilter` | "Reset Filters" |
| `noExperiments` | "No experiments yet" |
| `noExperimentsHint` | "Create your first experiment to get started" |
| `createFirstExperiment` | "Create First Experiment" |
| `noFilteredResults` | "No matching experiments" |
| `noFilteredResultsHint` | "Try adjusting your filter criteria" |
| `clearFilter` | "Clear Filters" |
| `loadFailed` | "Failed to load experiments" |
| `loadFailedHint` | "Please check your connection and try again" |
| `totalRecords` | "{count} records total" |
| `pageLabel` | "Page" |
| `pageOf` | "Page {current} of {total}" |
| `recordsPerPage` | "Rows per page" |
| `columnName` | "Name" |
| `columnMethod` | "Method" |
| `columnStatus` | "Status" |
| `columnStartTime` | "Start Time" |
| `columnDuration` | "Duration" |
| `columnActions` | "Actions" |
| `openConsole` | "Open Console" |
| `stopExperiment` | "Stop" |
| `confirmStopTitle` | "Confirm Stop" |
| `confirmStopDesc` | "Are you sure you want to stop experiment "{name}"?" |
| `experimentStopped` | "Experiment stopped" |
| `stopFailed` | "Failed to stop experiment: {reason}" |
| `createExperiment` | "Create Experiment" |
| `durationFormat` | "{h}h {m}m {s}s" |
| `statusUnknown` | "Unknown" |
| `notStarted` | "—" |
| `methodNotSet` | "—" |

### 6.2 新增中文 keys (`app_zh.arb`)

| key | 值 |
|-----|-----|
| `statusIdle` | "空闲" |
| `statusLoaded` | "已载入" |
| `statusRunning` | "运行中" |
| `statusPaused` | "已暂停" |
| `statusCompleted` | "已完成" |
| `statusAborted` | "已中止" |
| `allStatuses` | "全部状态" |
| `filterStatus` | "状态" |
| `filterDateRange` | "时间范围" |
| `resetFilter` | "重置筛选" |
| `noExperiments` | "暂无试验" |
| `noExperimentsHint` | "点击下方按钮创建您的第一个试验" |
| `createFirstExperiment` | "创建第一个试验" |
| `noFilteredResults` | "没有符合条件的试验" |
| `noFilteredResultsHint` | "请尝试调整筛选条件" |
| `clearFilter` | "清除筛选条件" |
| `loadFailed` | "加载试验列表失败" |
| `loadFailedHint` | "请检查网络连接后点击重试" |
| `totalRecords` | "共 {count} 条记录" |
| `pageLabel` | "页码" |
| `pageOf` | "第 {current} 页，共 {total} 页" |
| `recordsPerPage` | "每页条数" |
| `columnName` | "名称" |
| `columnMethod` | "方法" |
| `columnStatus` | "状态" |
| `columnStartTime` | "开始时间" |
| `columnDuration` | "持续时间" |
| `columnActions` | "操作" |
| `openConsole` | "进入控制台" |
| `stopExperiment` | "停止" |
| `confirmStopTitle` | "确认停止" |
| `confirmStopDesc` | "确定要停止试验「{name}」吗？" |
| `experimentStopped` | "试验已停止" |
| `stopFailed` | "停止失败：{reason}" |
| `createExperiment` | "创建试验" |
| `durationFormat` | "{h}小时{m}分{s}秒" |
| `statusUnknown` | "未知" |
| `notStarted` | "—" |
| `methodNotSet` | "—" |

---

## 7. 动画设计

| 元素 | 动画类型 | 参数 |
|------|---------|------|
| StatusBadge RUNNING 脉冲 | ScaleTransition + FadeTransition | 1.5s 循环, ease-out |
| 页面进入 | FadeTransition | 200ms, ease-out |
| 表格行 hover | 背景色过渡 | 150ms, ease-out |
| Skeleton shimmer | ShaderMask 水平光泽 | 1.5s, linear |
| 筛选切换 | FilterBar FadeTransition | 200ms, ease-in-out |
| 分页切换 | 表格 FadeTransition | 300ms, ease-in-out |
| Dialog 进入 | Scale/Fade | 200ms, ease-out |
| Toast 滑入 | SlideTransition | 300ms, ease-out |

---

## 8. 组件文件结构

```
lib/
├── widgets/
│   └── status_badge.dart          # [新建] StatusBadge 可复用组件
├── pages/
│   └── experiment/
│       └── experiment_list_page.dart  # [重写] 试验列表页
├── providers/
│   └── experiment_provider.dart   # [扩展] 添加 goToPage/setPageSize 方法
└── l10n/
    ├── app_en.arb                 # [更新] 新增试验列表 keys
    └── app_zh.arb                 # [更新] 新增试验列表 keys
```

---

## 9. 错误处理策略

| 场景 | 错误显示 | 恢复操作 |
|------|---------|---------|
| 初始加载失败 | ErrorView "加载试验列表失败" + "重试" | 点击重试 → refresh() |
| 分页加载失败 | Toast "加载第 N 页失败" | 显示上一页数据, 可重试 |
| 停止操作失败 | Toast "停止失败: 原因" | 手动重试 |
| 字段缺失 | 显示默认值 ("—" 或空字符串) | 不阻塞页面 |
| 未知状态 | 灰色 StatusBadge "未知" | 仍显示在列表中 |

---

*设计文档结束*
