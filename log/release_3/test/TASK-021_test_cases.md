# TASK-021 测试用例 — 试验列表页面 UI

> **任务**: 试验列表页面 UI (`/experiments`)  
> **依赖**: TASK-020（ExperimentProvider 已就绪）  
> **PRD 章节**: M8 §试验列表验收标准  
> **设计参考**: TASK-020_design.md（Provider API、状态机、数据模型）  
> **作者**: sw-mike（Software Tester）  
> **日期**: 2026-06-01  
> **版本**: 1.0  
> **总计**: 56 项测试用例

---

## 目录

1. [页面加载与基础渲染 (TC-021-01 ~ TC-021-08)](#1-页面加载与基础渲染)
2. [表格数据展示 (TC-021-09 ~ TC-021-16)](#2-表格数据展示)
3. [StatusBadge 可复用组件 (TC-021-17 ~ TC-021-24)](#3-statusbadge-可复用组件)
4. [筛选功能 (TC-021-25 ~ TC-021-32)](#4-筛选功能)
5. [分页功能 (TC-021-33 ~ TC-021-38)](#5-分页功能)
6. [操作列与交互 (TC-021-39 ~ TC-021-45)](#6-操作列与交互)
7. [响应式布局 (TC-021-46 ~ TC-021-50)](#7-响应式布局)
8. [国际化与主题适配 (TC-021-51 ~ TC-021-54)](#8-国际化与主题适配)
9. [错误处理与边界条件 (TC-021-55 ~ TC-021-56)](#9-错误处理与边界条件)

---

## 测试环境

- **Flutter SDK**: 3.19+
- **目标平台**: Web（Chrome/Firefox/Safari）
- **测试框架**: `flutter_test`, `mocktail`
- **状态管理**: `flutter_riverpod` 3.3.1
- **Provider 依赖**: `experimentListProvider`（来自 TASK-020）

---

## 通用前置条件

| 项目 | 内容 |
|------|------|
| **认证** | 用户已登录（Token 有效） |
| **路由** | 当前位于 `/experiments` |
| **依赖 Provider** | `experimentListProvider` 已注册，返回 `AsyncValue<List<Experiment>>` |
| **依赖 Service** | `ExperimentService.list()` 可 mock |
| **l10n** | `AppLocalizations` 已加载，支持 en/zh |

---

## 1. 页面加载与基础渲染

### TC-021-01: 页面初始加载显示骨架屏

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-01 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-5: 加载状态；PRD 8.2: 三态覆盖 |

**前置条件**:
- `experimentListProvider` 返回 `AsyncLoading()`

**测试步骤**:
1. 渲染 `ExperimentListPage`
2. 等待 widget 树稳定

**预期结果**:
- [ ] 页面显示 `SkeletonTable` 骨架屏组件
- [ ] 骨架屏包含与表格列数一致的占位行（至少 5 行）
- [ ] 每行包含名称、方法、状态、开始时间、持续时间、操作的占位
- [ ] 骨架屏有 shimmer/渐变动画效果
- [ ] 筛选栏区域显示禁用状态的占位
- [ ] 分页区域不显示或显示占位
- [ ] 无真实数据行显示
- [ ] 控制台无异常

**测试数据**:
```dart
// Provider mock
when(() => mockExperimentService.list(any())).thenAnswer(
  (_) async => Future.delayed(const Duration(seconds: 5), () => mockPaginatedResponse),
);
```

---

### TC-021-02: 加载完成后显示数据表格

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-02 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 表格展示 |

**前置条件**:
- `experimentListProvider` 返回 `AsyncData([...experiments])`，包含 3 条记录

**测试步骤**:
1. 渲染 `ExperimentListPage`
2. 等待异步数据加载完成

**预期结果**:
- [ ] 骨架屏消失
- [ ] 显示 `DataTable` 或等效表格组件
- [ ] 表格头部包含：名称、方法、状态、开始时间、持续时间、操作
- [ ] 表格显示 3 行数据，每行对应一条试验记录
- [ ] 筛选栏可用（未禁用）
- [ ] 分页信息正确显示

**测试数据**:
```dart
final experiments = [
  Experiment(
    id: 'exp-001',
    name: '温度循环测试',
    methodId: 'method-001',
    status: ExperimentStatus.running,
    startedAt: DateTime(2026, 5, 31, 14, 30),
    createdAt: DateTime(2026, 5, 31, 10, 0),
    updatedAt: DateTime(2026, 5, 31, 14, 30),
  ),
  // ... 共 3 条
];
```

---

### TC-021-03: 空状态显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-03 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-5: 空状态；PRD 8.2: 三态覆盖 |

**前置条件**:
- `experimentListProvider` 返回 `AsyncData([])`（空列表）

**测试步骤**:
1. 渲染 `ExperimentListPage`
2. 等待异步数据加载完成

**预期结果**:
- [ ] 显示 `EmptyView` 空状态组件
- [ ] 显示空状态图标（如 `Icons.science_outlined` 或试验相关图标）
- [ ] 显示提示文本："暂无试验记录"（中文）/ "No experiments yet"（英文）
- [ ] 显示"创建试验"按钮或引导链接
- [ ] 无表格、无骨架屏、无错误提示
- [ ] 筛选栏可显示但应用筛选后仍为空

---

### TC-021-04: 加载错误状态显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-04 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-5: 错误状态；PRD 8.2: 三态覆盖 |

**前置条件**:
- `experimentListProvider` 返回 `AsyncError('网络连接超时', stackTrace)`

**测试步骤**:
1. 渲染 `ExperimentListPage`
2. 等待异步操作完成

**预期结果**:
- [ ] 显示 `ErrorView` 错误状态组件
- [ ] 显示错误图标
- [ ] 显示用户友好错误消息（非技术栈跟踪）
- [ ] 显示"重新加载"按钮
- [ ] 点击"重新加载"按钮触发 Provider 的 `refresh()` 方法
- [ ] 无表格、无骨架屏

---

### TC-021-05: 页面标题和导航标签正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-05 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 附录 A: 路由；TASK-004: AppShell |

**前置条件**:
- 页面在 `AppShell` 内渲染
- 当前路由为 `/experiments`

**测试步骤**:
1. 渲染包含 `AppShell` 的完整页面树
2. 检查 AppBar / NavigationRail 标题

**预期结果**:
- [ ] 页面标题为"试验"（中文）/ "Experiments"（英文）
- [ ] NavigationRail / BottomNavigationBar 的"试验"标签处于激活状态
- [ ] 导航图标为试验相关图标（如 `Icons.science`）

---

### TC-021-06: 右上角"创建试验"按钮存在

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-06 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-5: 创建入口 |

**前置条件**:
- 页面已加载完成

**测试步骤**:
1. 查找"创建试验"按钮（`FloatingActionButton` 或 `ElevatedButton`）
2. 点击按钮

**预期结果**:
- [ ] 页面右上角或显著位置显示"+ 创建试验"按钮
- [ ] 按钮文本通过 l10n 获取（非硬编码）
- [ ] 点击按钮导航到 `/experiments/new`
- [ ] 按钮在加载状态仍然可见（或可交互）

---

### TC-021-07: 页面加载时自动请求试验列表

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-07 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD 8.1: 数据驱动；TASK-020: Provider |

**前置条件**:
- `experimentListProvider` 已配置
- mock `ExperimentService.list()`

**测试步骤**:
1. 渲染 `ExperimentListPage`
2. 验证 `ExperimentService.list()` 被调用

**预期结果**:
- [ ] 页面渲染时自动调用 `ExperimentService.list()`
- [ ] 调用参数：page=1, size=10, 无筛选条件
- [ ] Provider 状态从 `AsyncLoading` 变为 `AsyncData` 或 `AsyncError`
- [ ] 不重复请求（build 时不多次调用）

---

### TC-021-08: 下拉刷新触发列表刷新

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-08 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 操作有反馈 |

**前置条件**:
- 页面已加载完成，显示数据
- mock `ExperimentService.list()` 支持多次调用

**测试步骤**:
1. 在表格区域执行下拉刷新手势（或点击刷新按钮）
2. 等待刷新完成

**预期结果**:
- [ ] 触发 `ExperimentListNotifier.refresh()`
- [ ] 刷新指示器显示（CircularProgressIndicator 等）
- [ ] `ExperimentService.list()` 被再次调用（page=1）
- [ ] 刷新完成后显示最新数据
- [ ] 保持当前筛选条件（如果有）

---

## 2. 表格数据展示

### TC-021-09: 表格列对齐

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-09 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 表格展示 |

**前置条件**:
- 页面加载完成，有数据

**测试步骤**:
1. 检查表格头部列
2. 检查每行数据列对齐

**预期结果**:
- [ ] 表格头部列顺序：名称 → 方法 → 状态 → 开始时间 → 持续时间 → 操作
- [ ] 每行数据与表头列对齐
- [ ] 名称列左对齐
- [ ] 状态列居中
- [ ] 时间列居中或右对齐
- [ ] 操作列右对齐

---

### TC-021-10: 试验名称显示正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-10 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 表格展示 |

**前置条件**:
- 有试验数据，名称包含中英文混合

**测试步骤**:
1. 检查每行的试验名称显示

**预期结果**:
- [ ] 正确显示试验名称（如"温度循环测试"）
- [ ] 超长名称截断显示（带省略号...）
- [ ] 名称不可为空时显示空字符串（非 null）
- [ ] 支持中英文混合名称

**测试数据**:
```dart
Experiment(name: '温度循环测试_V2'),
Experiment(name: 'a' * 100), // 超长名称
Experiment(name: ''), // 空名称（边界）
```

---

### TC-021-11: 方法名称显示正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-11 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 表格展示 |

**前置条件**:
- 试验数据包含 methodId

**测试步骤**:
1. 检查方法列显示

**预期结果**:
- [ ] 显示方法名称（需通过 `methodId` 关联 `Method` 模型或显示 ID）
- [ ] 如果方法信息需单独加载，显示加载状态或 ID
- [ ] 方法名称为空时显示"—"或空（非 null）

---

### TC-021-12: 开始时间格式化显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-12 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 开始时间；PRD 9.3: 日期格式 |

**前置条件**:
- 试验数据包含 `startedAt` 字段

**测试步骤**:
1. 检查开始时间列显示

**预期结果**:
- [ ] 英文环境：显示 `MM/DD/YYYY HH:MM` 格式（如 `05/31/2026 14:30`）
- [ ] 中文环境：显示 `YYYY-MM-DD HH:MM` 格式（如 `2026-05-31 14:30`）
- [ ] `startedAt` 为 null 时显示"—"或空（非"null"字符串）
- [ ] 时间使用 24 小时制

**测试数据**:
```dart
Experiment(startedAt: DateTime(2026, 5, 31, 14, 30)),
Experiment(startedAt: null), // 未开始
```

---

### TC-021-13: 持续时间计算和显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-13 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 持续时间 |

**前置条件**:
- 试验数据包含 `startedAt` 和 `endedAt`（或当前时间）

**测试步骤**:
1. 检查持续时间列显示

**预期结果**:
- [ ] RUNNING 状态：显示从开始时间到当前的持续时间（如 `02:15:32`）
- [ ] PAUSED 状态：显示已运行时间（暂停期间不计时）
- [ ] COMPLETED 状态：显示从开始到结束的总时长
- [ ] IDLE/LOADED 状态：显示"—"或空（尚未开始）
- [ ] 格式：`HH:MM:SS` 或简化为 `X 小时 Y 分钟`
- [ ] 持续时间为 0 时显示 `00:00:00` 或 "—"

**测试数据**:
```dart
Experiment(
  status: ExperimentStatus.running,
  startedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15, seconds: 32)),
),
Experiment(
  status: ExperimentStatus.completed,
  startedAt: DateTime(2026, 5, 31, 14, 0),
  endedAt: DateTime(2026, 5, 31, 16, 15, 32),
),
Experiment(status: ExperimentStatus.idle, startedAt: null),
```

---

### TC-021-14: 多条试验数据分页显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-14 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 表格展示；PRD M8-4: 分页 |

**前置条件**:
- `ExperimentService.list()` 返回 15 条记录（超过默认 pageSize=10）

**测试步骤**:
1. 渲染页面，等待加载
2. 检查显示的行数

**预期结果**:
- [ ] 首次加载显示 10 条记录（默认 pageSize）
- [ ] 表格显示 10 行数据
- [ ] 分页控件显示"共 15 条记录"
- [ ] 分页控件显示当前页码（1）
- [ ] "下一页"按钮可用
- [ ] "上一页"按钮禁用（第一页）

---

### TC-021-15: 表格行样式交替（斑马纹）

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-15 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | UI 规范：Material 3 |

**前置条件**:
- 有 3+ 行数据

**测试步骤**:
1. 检查表格行背景色

**预期结果**:
- [ ] 奇数行和偶数行有不同背景色（或遵循 Material 3 默认）
- [ ] 行高一致
- [ ] 行之间有分隔线或间距

---

### TC-021-16: 表格行悬停效果

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-16 |
| **优先级** | P1 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD 3.2: 交互反馈 |

**前置条件**:
- 有数据行

**测试步骤**:
1. 鼠标悬停在数据行上

**预期结果**:
- [ ] 行背景色变化（hover 状态）
- [ ] 鼠标指针变为手型（可点击区域）
- [ ] 操作列按钮在悬停时更明显

---

## 3. StatusBadge 可复用组件

### TC-021-17: StatusBadge 渲染各状态颜色

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-17 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-2: 状态颜色；TASK-021: StatusBadge 组件 |

**前置条件**:
- `StatusBadge` 组件独立可测试

**测试步骤**:
1. 渲染 `StatusBadge` 分别传入 6 种状态

**预期结果**:
| 状态 | 背景色 | 文字颜色 | 形状 |
|------|--------|----------|------|
| IDLE | 灰色（Grey） | 深色/白色 | 圆角矩形标签 |
| LOADED | 蓝色（Blue） | 白色 | 圆角矩形标签 |
| RUNNING | 绿色（Green） | 白色 | 圆角矩形标签 + 脉冲动画 |
| PAUSED | 橙色（Orange/Amber） | 深色 | 圆角矩形标签 |
| COMPLETED | 绿色（Green，深色/更饱和） | 白色 | 圆角矩形标签 |
| ABORTED | 红色（Red） | 白色 | 圆角矩形标签 |

- [ ] 每种状态的背景色正确（与 PRD 规范一致）
- [ ] 文字可读（对比度符合 WCAG AA）
- [ ] 标签形状为圆角矩形（非纯矩形）
- [ ] 标签大小一致

---

### TC-021-18: RUNNING 状态脉冲动画

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-18 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-2: RUNNING 绿+脉冲；TASK-021: StatusBadge |

**前置条件**:
- 渲染 `StatusBadge(status: ExperimentStatus.running)`

**测试步骤**:
1. 渲染 RUNNING 状态的 StatusBadge
2. 观察动画效果（使用 `tester.pump()` 多帧）

**预期结果**:
- [ ] RUNNING 状态显示绿色标签
- [ ] 标签有脉冲/呼吸动画效果（opacity 或 scale 变化）
- [ ] 动画循环播放（非单次）
- [ ] 动画流畅，不卡顿
- [ ] 其他状态无脉冲动画

---

### TC-021-19: StatusBadge 尺寸一致性

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-19 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | UI 规范：组件一致性 |

**前置条件**:
- 渲染所有状态的 StatusBadge

**测试步骤**:
1. 测量每种状态标签的尺寸

**预期结果**:
- [ ] 所有状态标签高度一致
- [ ] 标签内边距（padding）一致
- [ ] 文字字号一致
- [ ] 最小宽度确保文字可读（不挤压）

---

### TC-021-20: StatusBadge 文本内容

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-20 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-2: 状态标签；PRD 9: 国际化 |

**前置条件**:
- 切换 en/zh 语言

**测试步骤**:
1. 在英文环境下渲染所有状态的 StatusBadge
2. 在中文环境下渲染所有状态的 StatusBadge

**预期结果**:
| 状态 | 英文文本 | 中文文本 |
|------|----------|----------|
| IDLE | "Idle" | "空闲" |
| LOADED | "Loaded" | "已载入" |
| RUNNING | "Running" | "运行中" |
| PAUSED | "Paused" | "已暂停" |
| COMPLETED | "Completed" | "已完成" |
| ABORTED | "Aborted" | "已中止" |

- [ ] 所有文本通过 l10n 获取（非硬编码）
- [ ] 语言切换后文本立即更新

---

### TC-021-21: StatusBadge 在表格中正确显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-21 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 状态列 |

**前置条件**:
- 试验列表包含各种状态的试验

**测试步骤**:
1. 渲染试验列表
2. 检查每行的状态列

**预期结果**:
- [ ] 每行状态列显示 `StatusBadge`
- [ ] 状态颜色与试验实际状态匹配
- [ ] 状态文本正确
- [ ] RUNNING 状态的行显示脉冲动画
- [ ] 状态列居中对齐

---

### TC-021-22: StatusBadge 主题适配（浅色/深色）

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-22 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.3: 双主题；PRD 11.3-43: 主题正确 |

**前置条件**:
- 在浅色和深色主题下分别渲染

**测试步骤**:
1. 浅色主题下渲染 StatusBadge（所有状态）
2. 深色主题下渲染 StatusBadge（所有状态）

**预期结果**:
- [ ] 浅色主题：标签颜色与 PRD 规范一致
- [ ] 深色主题：标签颜色适当调整（保持可辨识度）
- [ ] 文字在两种主题下均可读
- [ ] 脉冲动画在两种主题下均可见

---

### TC-021-23: StatusBadge 可复用性验证

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-23 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | TASK-021: 可复用组件 |

**前置条件**:
- `StatusBadge` 组件已创建在 `lib/widgets/status_badge.dart`

**测试步骤**:
1. 检查组件文件位置
2. 检查组件 API
3. 在试验列表页外使用 StatusBadge

**预期结果**:
- [ ] 组件位于 `lib/widgets/status_badge.dart`
- [ ] 组件接受 `ExperimentStatus` 作为参数
- [ ] 组件不依赖试验列表上下文（纯展示组件）
- [ ] 组件可在其他页面（如试验控制台）复用
- [ ] 组件无业务逻辑（纯 UI）

---

### TC-021-24: StatusBadge 无障碍支持

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-24 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 无障碍 |

**前置条件**:
- 渲染 StatusBadge

**测试步骤**:
1. 检查 Semantics 属性

**预期结果**:
- [ ] StatusBadge 有正确的 `semanticLabel`
- [ ] 屏幕阅读器能朗读状态文本（如"运行中"）
- [ ] 颜色不是唯一的状态指示方式（有文字标签）
- [ ] 脉冲动画不影响屏幕阅读器

---

## 4. 筛选功能

### TC-021-25: 状态多选筛选

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-25 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8-3: 状态多选筛选；PRD 11.1-20: 试验筛选 |

**前置条件**:
- 试验列表有 6 条记录，各状态各 1 条
- 筛选栏显示状态多选控件

**测试步骤**:
1. 点击状态筛选控件
2. 勾选 RUNNING 和 PAUSED
3. 点击"应用筛选"

**预期结果**:
- [ ] 状态筛选控件为下拉/弹出式多选（如 FilterChip、CheckboxListTile）
- [ ] 勾选 RUNNING 和 PAUSED 后，表格只显示这两种状态的试验
- [ ] `ExperimentService.list()` 被调用，参数包含 `status` 筛选条件
- [ ] 筛选结果正确（只显示匹配的试验）
- [ ] 分页信息更新为筛选后的总数

---

### TC-021-26: 状态筛选全选和清空

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-26 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-3: 状态多选 |

**前置条件**:
- 状态筛选控件已打开

**测试步骤**:
1. 点击"全选"按钮
2. 点击"清空"按钮

**预期结果**:
- [ ] 全选：所有状态被勾选，表格显示全部试验
- [ ] 清空：所有状态被取消勾选
- [ ] 清空后表格显示全部试验（或提示"请选择筛选条件"）
- [ ] 筛选参数正确处理空列表（不传递 status 参数）

---

### TC-021-27: 时间范围筛选

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-27 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8-3: 时间范围选择器；PRD 11.1-20 |

**前置条件**:
- 试验数据包含不同创建时间
- 筛选栏显示日期范围选择器

**测试步骤**:
1. 点击开始日期选择器
2. 选择 2026-05-01
3. 点击结束日期选择器
4. 选择 2026-05-31
5. 点击"应用筛选"

**预期结果**:
- [ ] 显示日期选择器（`showDatePicker` 或自定义）
- [ ] 选择的日期正确显示在输入框
- [ ] `ExperimentService.list()` 被调用，参数包含 `createdAfter` 和 `createdBefore`
- [ ] 表格只显示创建时间在范围内的试验
- [ ] 日期格式符合当前语言设置

---

### TC-021-28: 时间范围筛选边界条件

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-28 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-3: 时间范围 |

**前置条件**:
- 时间范围选择器可用

**测试步骤**:
1. 只选择开始日期，不选结束日期
2. 只选择结束日期，不选开始日期
3. 选择开始日期 > 结束日期
4. 清除已选日期

**预期结果**:
| 场景 | 预期行为 |
|------|----------|
| 只选开始日期 | 筛选 `createdAfter` 之后的所有试验，无上限 |
| 只选结束日期 | 筛选 `createdBefore` 之前的所有试验，无下限 |
| 开始 > 结束 | 显示验证错误提示（"开始时间不能晚于结束时间"）或空结果 |
| 清除日期 | 取消时间筛选，显示全部试验 |

---

### TC-021-29: 组合筛选（状态 + 时间范围）

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-29 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8-3: 筛选栏 |

**前置条件**:
- 有试验数据，支持多种筛选条件

**测试步骤**:
1. 选择状态 = RUNNING
2. 选择时间范围 = 2026-05-01 至 2026-05-31
3. 点击"应用筛选"

**预期结果**:
- [ ] `ExperimentService.list()` 同时包含 `status` 和 `createdAfter`/`createdBefore` 参数
- [ ] 表格只显示同时满足两个条件的试验
- [ ] 筛选条件在 URL 中体现（可选，深层链接）
- [ ] 分页信息更新

---

### TC-021-30: 筛选结果为空

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-30 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-5: 空状态 |

**前置条件**:
- 筛选条件过于严格，无匹配数据

**测试步骤**:
1. 选择不存在的状态组合（如所有状态都不选）
2. 或选择无数据的时间范围

**预期结果**:
- [ ] 表格不显示数据行
- [ ] 显示空状态提示："无符合条件的试验"（区别于初始空状态）
- [ ] 显示"清除筛选"按钮
- [ ] 点击"清除筛选"恢复显示全部试验
- [ ] 分页信息显示"共 0 条记录"

---

### TC-021-31: 筛选条件持久化

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-31 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 用户体验 |

**前置条件**:
- 已应用筛选条件

**测试步骤**:
1. 应用筛选条件
2. 导航到其他页面
3. 返回试验列表页

**预期结果**:
- [ ] 筛选条件保持不变（或重置，需根据设计决定）
- [ ] 如果持久化：返回后仍显示筛选后的结果
- [ ] 如果重置：返回后显示全部数据

---

### TC-021-32: 筛选栏 UI 布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-32 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-3: 筛选栏 |

**前置条件**:
- 页面已加载

**测试步骤**:
1. 检查筛选栏布局

**预期结果**:
- [ ] 筛选栏位于表格上方
- [ ] 状态筛选和时间范围筛选水平排列（大屏）
- [ ] 筛选控件有清晰的标签
- [ ] "应用筛选"和"清除筛选"按钮可见
- [ ] 筛选栏在小屏下可垂直堆叠

---

## 5. 分页功能

### TC-021-33: 分页控件显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-33 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-4: 分页；PRD M8-5: 共 N 条记录 |

**前置条件**:
- 有 25 条试验数据，pageSize=10

**测试步骤**:
1. 加载页面
2. 检查分页控件

**预期结果**:
- [ ] 分页控件位于表格下方
- [ ] 显示"共 25 条记录"
- [ ] 显示当前页码（1）
- [ ] 显示总页数（3 页）
- [ ] "下一页"按钮可用
- [ ] "上一页"按钮禁用（第一页）
- [ ] 可跳转到指定页码（可选）

---

### TC-021-34: 分页导航

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-34 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8-4: 分页 |

**前置条件**:
- 有 25 条数据

**测试步骤**:
1. 点击"下一页"
2. 点击"上一页"
3. 点击页码 3

**预期结果**:
- [ ] 点击"下一页"：加载第 2 页数据，显示记录 11-20
- [ ] `ExperimentService.list(page: 2)` 被调用
- [ ] 点击"上一页"：加载第 1 页数据
- [ ] 点击页码 3：加载第 3 页数据，显示记录 21-25
- [ ] 当前页码高亮显示
- [ ] 表格滚动到顶部

---

### TC-021-35: 分页与筛选组合

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-35 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8-3/4: 筛选 + 分页 |

**前置条件**:
- 已应用状态筛选（如 RUNNING），筛选后共 15 条

**测试步骤**:
1. 应用状态筛选
2. 点击"下一页"

**预期结果**:
- [ ] 分页基于筛选后的总数（15 条，共 2 页）
- [ ] `ExperimentService.list()` 同时包含筛选参数和 page 参数
- [ ] 页面 2 显示筛选后的记录 11-15
- [ ] 清除筛选后分页恢复为总数 25

---

### TC-021-36: 分页边界条件

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-36 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-4: 分页 |

**前置条件**:
- 各种数据量场景

**测试步骤**:
1. 数据量 = 0
2. 数据量 = 5（< pageSize）
3. 数据量 = 10（= pageSize）
4. 数据量 = 11（> pageSize）

**预期结果**:
| 数据量 | 分页行为 |
|--------|----------|
| 0 | 不显示分页控件，或显示"共 0 条" |
| 5 | 显示"共 5 条"，不分页，下一页禁用 |
| 10 | 显示"共 10 条"，不分页，下一页禁用 |
| 11 | 显示"共 11 条"，2 页，下一页可用 |

---

### TC-021-37: 分页加载错误

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-37 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 错误处理 |

**前置条件**:
- 第 2 页加载时模拟网络错误

**测试步骤**:
1. 加载第 1 页成功
2. 点击"下一页"
3. 第 2 页请求失败

**预期结果**:
- [ ] 显示错误提示（Toast 或内联错误）
- [ ] 第 1 页数据仍显示（不清空）
- [ ] 提供重试机制
- [ ] 分页控件仍显示当前页为 1

---

### TC-021-38: 改变 pageSize

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-38 |
| **优先级** | P2 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-4: 分页 |

**前置条件**:
- 有 25 条数据
- 提供 pageSize 选择器（如 10/25/50）

**测试步骤**:
1. 选择 pageSize = 25

**预期结果**:
- [ ] 表格显示 25 条记录
- [ ] 分页变为 1 页
- [ ] `ExperimentService.list(size: 25)` 被调用
- [ ] pageSize 选择器可用（如果存在）

---

## 6. 操作列与交互

### TC-021-39: "进入控制台"按钮导航

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-39 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8-5: 进入控制台；PRD 附录 A: 路由 |

**前置条件**:
- 试验列表有数据

**测试步骤**:
1. 找到任意试验行的"进入控制台"按钮
2. 点击按钮

**预期结果**:
- [ ] 每行操作列显示"进入控制台"按钮或图标（如 `Icons.open_in_new`）
- [ ] 点击按钮导航到 `/experiments/{id}`
- [ ] 导航使用 `go_router`，URL 正确
- [ ] 按钮在加载状态不触发重复导航

---

### TC-021-40: "停止"按钮仅对 RUNNING/PAUSED 显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-40 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-5: 停止操作；PRD 3.1: 状态机 |

**前置条件**:
- 试验列表包含所有 6 种状态的试验

**测试步骤**:
1. 检查每行操作列

**预期结果**:
| 状态 | 停止按钮 |
|------|----------|
| IDLE | 不显示或禁用 |
| LOADED | 不显示或禁用 |
| RUNNING | 显示且可用 |
| PAUSED | 显示且可用 |
| COMPLETED | 不显示或禁用 |
| ABORTED | 不显示或禁用 |

- [ ] 只有 RUNNING 和 PAUSED 状态的行显示可用的"停止"按钮
- [ ] 其他状态的行不显示"停止"按钮或显示为禁用状态
- [ ] 按钮禁用状态有视觉区别（灰色、不可点击）

---

### TC-021-41: "停止"操作二次确认

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-41 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD 3.2: 不可逆操作需确认；PRD M8: 停止确认 |

**前置条件**:
- 有 RUNNING 状态的试验

**测试步骤**:
1. 点击 RUNNING 状态行的"停止"按钮

**预期结果**:
- [ ] 弹出 `ConfirmDialog` 确认对话框
- [ ] 对话框标题："确认停止"
- [ ] 对话框内容："确定要停止试验「XXX」吗？"
- [ ] 显示"取消"和"确认停止"按钮
- [ ] "确认停止"按钮为 danger 样式（红色）
- [ ] 点击"取消"关闭对话框，不执行停止操作
- [ ] 点击"确认停止"执行停止操作

---

### TC-021-42: "停止"操作成功反馈

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-42 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD 3.2: 操作有反馈 |

**前置条件**:
- 点击"确认停止"
- mock `ExperimentService.stop()` 返回成功

**测试步骤**:
1. 点击"停止" → 确认

**预期结果**:
- [ ] 停止请求发送：`POST /api/v1/experiments/{id}/stop`
- [ ] 按钮显示 loading 状态
- [ ] 成功后显示 Toast："试验已停止"
- [ ] 试验状态更新为 COMPLETED（或 LOADED，根据状态机）
- [ ] StatusBadge 颜色从绿色变为灰色/绿色（COMPLETED）
- [ ] "停止"按钮变为禁用/隐藏

---

### TC-021-43: "停止"操作失败反馈

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-43 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 操作有反馈；PRD 8.2: 错误处理 |

**前置条件**:
- mock `ExperimentService.stop()` 抛出异常

**测试步骤**:
1. 点击"停止" → 确认

**预期结果**:
- [ ] 请求失败
- [ ] 显示错误 Toast："停止失败：具体原因"
- [ ] 试验状态不变（仍为 RUNNING）
- [ ] "停止"按钮恢复可用状态
- [ ] 无页面崩溃

---

### TC-021-44: 行内点击跳转控制台

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-44 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD M8-1: 表格展示 |

**前置条件**:
- 有试验数据

**测试步骤**:
1. 点击试验名称（非按钮区域）

**预期结果**:
- [ ] 点击试验名称也导航到控制台（整行可点击）
- [ ] 或仅操作列按钮可点击（根据设计）
- [ ] 导航目标正确

---

### TC-021-45: 操作按钮防重复点击

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-45 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 操作有反馈；PRD 11.3-42: 防止重复提交 |

**前置条件**:
- 点击"停止"按钮

**测试步骤**:
1. 快速连续点击"停止"按钮 3 次

**预期结果**:
- [ ] 只有第一次点击有效
- [ ] 后续点击被忽略（按钮禁用或 loading 状态阻止）
- [ ] 只发送一次停止请求
- [ ] 防止重复操作导致的状态异常

---

## 7. 响应式布局

### TC-021-46: 大屏（>1200px）表格布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-46 |
| **优先级** | P0 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 响应式断点；PRD M8-1: 表格 |

**前置条件**:
- 视口宽度 > 1200px

**测试步骤**:
1. 在 1920x1080 视口下渲染页面

**预期结果**:
- [ ] 显示完整表格（所有列）
- [ ] 表格宽度自适应，无水平滚动
- [ ] 筛选栏水平排列
- [ ] 分页控件水平排列
- [ ] 导航为左侧 NavigationRail
- [ ] 操作列显示文本按钮（非仅图标）

---

### TC-021-47: 中屏（600-1200px）适配

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-47 |
| **优先级** | P0 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 响应式断点；PRD 10.2: 表格适配 |

**前置条件**:
- 视口宽度 = 900px

**测试步骤**:
1. 在 900px 宽度下渲染页面

**预期结果**:
- [ ] 表格显示所有列，但可能较紧凑
- [ ] 或隐藏次要列（如持续时间）
- [ ] 筛选栏可能垂直堆叠
- [ ] 导航为可折叠 NavigationRail
- [ ] 操作列显示图标按钮（节省空间）
- [ ] 无水平滚动条（或最小化）

---

### TC-021-48: 小屏（<600px）卡片布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-48 |
| **优先级** | P0 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 小屏；PRD 10.2: 表格转卡片；PRD M8-5: 小屏表格转卡片 |

**前置条件**:
- 视口宽度 = 375px（iPhone SE 尺寸）

**测试步骤**:
1. 在 375px 宽度下渲染页面

**预期结果**:
- [ ] 表格转为卡片列表（非表格布局）
- [ ] 每张卡片显示：名称、状态（StatusBadge）、开始时间
- [ ] 操作按钮在卡片底部或展开菜单中
- [ ] 筛选栏垂直堆叠
- [ ] 分页控件简化（上一页/下一页，可能无页码）
- [ ] 导航为底部 BottomNavigationBar
- [ ] 文本可读，无水平滚动
- [ ] 触摸目标最小 48x48dp

---

### TC-021-49: 小屏卡片展开详情

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-49 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 10.2: 小屏适配 |

**前置条件**:
- 小屏卡片布局

**测试步骤**:
1. 点击卡片展开/折叠详情

**预期结果**:
- [ ] 卡片可展开显示更多信息（方法、持续时间）
- [ ] 展开后显示操作按钮
- [ ] 再次点击折叠
- [ ] 或卡片直接进入控制台（无展开）

---

### TC-021-50: 响应式状态标签尺寸

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-50 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 10.2: 适应性要求 |

**前置条件**:
- 在不同屏幕尺寸下渲染 StatusBadge

**测试步骤**:
1. 检查大屏和小屏下的 StatusBadge

**预期结果**:
- [ ] 大屏：显示完整状态文本（如"运行中"）
- [ ] 小屏：可能显示缩写或仅颜色指示（根据设计）
- [ ] 标签不溢出容器
- [ ] 脉冲动画在小屏下仍可见

---

## 8. 国际化与主题适配

### TC-021-51: 中文界面文本正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-51 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 9: 国际化；PRD 11.3-39: 无硬编码文本 |

**前置条件**:
- 语言设置为中文（`Locale('zh')`）

**测试步骤**:
1. 在中文环境下渲染页面
2. 检查所有文本

**预期结果**:
- [ ] 页面标题："试验"
- [ ] 表格列头："名称"、"方法"、"状态"、"开始时间"、"持续时间"、"操作"
- [ ] 空状态："暂无试验记录"
- [ ] 按钮："创建试验"、"进入控制台"、"停止"
- [ ] 筛选标签："状态"、"时间范围"
- [ ] 分页："共 N 条记录"
- [ ] 错误消息：中文
- [ ] 无硬编码英文文本（ARB key 缺失除外）

---

### TC-021-52: 英文界面文本正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-52 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 9: 国际化 |

**前置条件**:
- 语言设置为英文（`Locale('en')`）

**测试步骤**:
1. 在英文环境下渲染页面

**预期结果**:
- [ ] 页面标题："Experiments"
- [ ] 表格列头："Name", "Method", "Status", "Start Time", "Duration", "Actions"
- [ ] 空状态："No experiments yet"
- [ ] 按钮："Create Experiment", "Open Console", "Stop"
- [ ] 筛选标签："Status", "Date Range"
- [ ] 分页："N records total"
- [ ] 日期格式：MM/DD/YYYY

---

### TC-021-53: 浅色主题适配

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-53 |
| **优先级** | P0 |
| **类型** | Screenshot Test |
| **关联需求** | PRD 3.3: 浅色主题；PRD 11.3-43: 主题正确 |

**前置条件**:
- 主题模式 = 浅色

**测试步骤**:
1. 在浅色主题下渲染页面（各种状态）
2. 截图对比

**预期结果**:
- [ ] 页面背景为浅色
- [ ] 表格行交替色可见
- [ ] StatusBadge 颜色正确（见 TC-021-17）
- [ ] 文字为深色，可读
- [ ] 按钮使用主色 #1976D2
- [ ] 无颜色反转错误

---

### TC-021-54: 深色主题适配

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-54 |
| **优先级** | P0 |
| **类型** | Screenshot Test |
| **关联需求** | PRD 3.3: 深色主题；PRD 11.3-43: 主题正确 |

**前置条件**:
- 主题模式 = 深色

**测试步骤**:
1. 在深色主题下渲染页面（各种状态）
2. 截图对比

**预期结果**:
- [ ] 页面背景为深色
- [ ] 表格行交替色可见（适配深色）
- [ ] StatusBadge 颜色适当调整（仍可辨识）
- [ ] 文字为浅色，可读
- [ ] 按钮颜色适配深色主题
- [ ] 脉冲动画在深色下可见
- [ ] 筛选控件、分页控件颜色正确

---

## 9. 错误处理与边界条件

### TC-021-55: 网络错误后重试

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-55 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD 3.2: 错误信息人性化；PRD 8.2: 错误状态 |

**前置条件**:
- 首次加载失败，重试成功

**测试步骤**:
1. mock `list()` 第一次抛出异常
2. 点击"重新加载"
3. mock `list()` 第二次返回成功数据

**预期结果**:
- [ ] 首次加载显示 ErrorView
- [ ] 错误消息友好："加载试验列表失败，请稍后重试"
- [ ] 点击"重新加载"触发 Provider 刷新
- [ ] 第二次加载显示数据表格
- [ ] 骨架屏在重试时短暂显示
- [ ] 重试次数无限制（或合理限制）

---

### TC-021-56: 试验数据字段缺失边界

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-021-56 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 8.2: 无假数据；PRD 3.2: 错误处理 |

**前置条件**:
- 后端返回字段不完整的数据

**测试步骤**:
1. 渲染包含字段缺失数据的页面

**预期结果**:
| 缺失字段 | 预期显示 |
|----------|----------|
| `name` = null | 显示空字符串或"未命名试验" |
| `methodId` = null | 显示"—"或"未选择方法" |
| `startedAt` = null | 显示"—" |
| `status` = null/未知 | 显示默认灰色 StatusBadge "未知" |

- [ ] 页面不崩溃
- [ ] 无 `null` 字符串显示
- [ ] 缺失字段不影响其他字段显示
- [ ] 异常数据记录仍显示在表格中

---

## 附录 A：测试数据工厂

```dart
/// 试验测试数据工厂
class ExperimentTestData {
  static Experiment running() => Experiment(
    id: 'exp-001',
    name: '温度循环测试',
    methodId: 'method-001',
    status: ExperimentStatus.running,
    startedAt: DateTime.now().subtract(const Duration(hours: 2)),
    createdAt: DateTime(2026, 5, 31, 10, 0),
    updatedAt: DateTime.now(),
  );

  static Experiment paused() => Experiment(
    id: 'exp-002',
    name: '压力测试',
    methodId: 'method-002',
    status: ExperimentStatus.paused,
    startedAt: DateTime(2026, 5, 30, 14, 0),
    createdAt: DateTime(2026, 5, 30, 10, 0),
    updatedAt: DateTime(2026, 5, 30, 16, 0),
  );

  static Experiment completed() => Experiment(
    id: 'exp-003',
    name: '振动测试',
    methodId: 'method-003',
    status: ExperimentStatus.completed,
    startedAt: DateTime(2026, 5, 29, 9, 0),
    createdAt: DateTime(2026, 5, 29, 8, 0),
    updatedAt: DateTime(2026, 5, 29, 12, 0),
  );

  static Experiment idle() => Experiment(
    id: 'exp-004',
    name: '待机试验',
    methodId: null,
    status: ExperimentStatus.idle,
    startedAt: null,
    createdAt: DateTime(2026, 5, 28, 10, 0),
    updatedAt: DateTime(2026, 5, 28, 10, 0),
  );

  static Experiment loaded() => Experiment(
    id: 'exp-005',
    name: '已载入试验',
    methodId: 'method-001',
    status: ExperimentStatus.loaded,
    startedAt: null,
    createdAt: DateTime(2026, 5, 27, 10, 0),
    updatedAt: DateTime(2026, 5, 27, 11, 0),
  );

  static Experiment aborted() => Experiment(
    id: 'exp-006',
    name: '异常终止试验',
    methodId: 'method-002',
    status: ExperimentStatus.aborted,
    startedAt: DateTime(2026, 5, 26, 10, 0),
    createdAt: DateTime(2026, 5, 26, 9, 0),
    updatedAt: DateTime(2026, 5, 26, 10, 30),
  );

  /// 生成 N 条试验数据
  static List<Experiment> generate(int count) {
    final statuses = ExperimentStatus.values;
    return List.generate(count, (i) {
      final status = statuses[i % statuses.length];
      return Experiment(
        id: 'exp-${i.toString().padLeft(3, '0')}',
        name: '试验 #${i + 1}',
        methodId: 'method-${i % 5}',
        status: status,
        startedAt: status == ExperimentStatus.idle || status == ExperimentStatus.loaded
            ? null
            : DateTime.now().subtract(Duration(hours: i)),
        createdAt: DateTime(2026, 5, 20 + (i % 10)),
        updatedAt: DateTime.now(),
      );
    });
  }
}

/// Mock PaginatedResponse
class MockPaginatedResponse {
  static PaginatedResponse<Experiment> of(
    List<Experiment> data, {
    int page = 1,
    int size = 10,
    int total = 0,
  }) {
    return PaginatedResponse<Experiment>(
      data: data,
      page: page,
      size: size,
      total: total > 0 ? total : data.length,
      hasNext: (page * size) < (total > 0 ? total : data.length),
    );
  }
}
```

---

## 附录 B：Widget 测试基础设施

```dart
/// 试验列表页面测试基类
class ExperimentListPageTestBase {
  late MockExperimentService mockExperimentService;
  late ProviderContainer container;

  setUp(() {
    mockExperimentService = MockExperimentService();
    container = ProviderContainer(
      overrides: [
        experimentServiceProvider.overrideWithValue(mockExperimentService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  /// 构建测试中的页面
  Widget buildTestWidget() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/experiments',
          routes: [
            GoRoute(
              path: '/experiments',
              builder: (context, state) => const ExperimentListPage(),
            ),
            GoRoute(
              path: '/experiments/new',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/experiments/:id',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'), // 或 Locale('en')
      ),
    );
  }
}
```

---

## 附录 C：截图检查清单

| # | 截图场景 | 分辨率 | 主题 | 语言 |
|---|----------|--------|------|------|
| 1 | 加载中（骨架屏） | 1920x1080 | 浅色 | 中文 |
| 2 | 加载中（骨架屏） | 375x667 | 浅色 | 中文 |
| 3 | 有数据（表格） | 1920x1080 | 浅色 | 中文 |
| 4 | 有数据（表格） | 1920x1080 | 深色 | 中文 |
| 5 | 有数据（表格） | 900x600 | 浅色 | 中文 |
| 6 | 有数据（卡片列表） | 375x667 | 浅色 | 中文 |
| 7 | 有数据（卡片列表） | 375x667 | 深色 | 中文 |
| 8 | 空状态 | 1920x1080 | 浅色 | 中文 |
| 9 | 空状态 | 1920x1080 | 浅色 | 英文 |
| 10 | 错误状态 | 1920x1080 | 浅色 | 中文 |
| 11 | 筛选状态展开 | 1920x1080 | 浅色 | 中文 |
| 12 | 分页控件 | 1920x1080 | 浅色 | 中文 |
| 13 | StatusBadge - 所有状态 | 800x400 | 浅色 | 中文 |
| 14 | StatusBadge - RUNNING 脉冲动画 | 800x400 | 浅色 | 中文 |
| 15 | 停止确认对话框 | 1920x1080 | 浅色 | 中文 |
| 16 | 各状态行操作列 | 1920x1080 | 浅色 | 中文 |

---

## 修订记录

| 日期 | 版本 | 修订人 | 修订说明 |
|------|------|--------|----------|
| 2026-06-01 | v1.0 | sw-mike | 初始版本，56 项测试用例，覆盖页面加载、表格展示、StatusBadge、筛选、分页、操作、响应式、国际化、错误处理 |

---

**状态**: 待评审  
**下一步**: 提交给 sw-tom 进行技术评审
