# TASK-023 测试用例文档 — 试验控制台 UI

> **任务**: 试验控制台 UI（核心页面）
> **测试者**: sw-mike
> **日期**: 2026-06-02
> **版本**: 1.0
> **关联设计**: `log/release_3/design/TASK-020_design.md` (WsService, ExperimentProvider)
> **PRD 章节**: M8 试验执行控制台

---

## 目录

1. [测试范围与目标](#1-测试范围与目标)
2. [测试环境](#2-测试环境)
3. [页面布局与渲染测试](#3-页面布局与渲染测试)
4. [控制面板 — 信息展示测试](#4-控制面板--信息展示测试)
5. [控制面板 — 状态显示测试](#5-控制面板--状态显示测试)
6. [控制面板 — 按钮状态矩阵测试](#6-控制面板--按钮状态矩阵测试)
7. [控制面板 — 定时器测试](#7-控制面板--定时器测试)
8. [控制面板 — 停止确认与按钮反馈测试](#8-控制面板--停止确认与按钮反馈测试)
9. [执行日志显示测试](#9-执行日志显示测试)
10. [执行日志自动滚动测试](#10-执行日志自动滚动测试)
11. [执行日志筛选与清空测试](#11-执行日志筛选与清空测试)
12. [WebSocket 连接管理测试](#12-websocket-连接管理测试)
13. [WebSocket 消息处理测试](#13-websocket-消息处理测试)
14. [WebSocket 断线重连测试](#14-websocket-断线重连测试)
15. [导航与生命周期测试](#15-导航与生命周期测试)
16. [边界情况与错误处理测试](#16-边界情况与错误处理测试)
17. [响应式布局测试](#17-响应式布局测试)
18. [完成/中止状态与历史时间线测试](#18-完成终止状态与历史时间线测试)
19. [测试覆盖矩阵](#19-测试覆盖矩阵)
20. [Mock 规范](#20-mock-规范)

---

## 1. 测试范围与目标

### 1.1 测试组件

| 组件 | 文件路径 | 类型 |
|------|----------|------|
| ExperimentConsolePage | `lib/pages/experiment/experiment_console_page.dart` | 页面 Widget |
| LogViewerWidget | `lib/widgets/log_viewer.dart` | 可复用 Widget |
| ExperimentControlNotifier | `lib/providers/experiment_provider.dart` | AsyncNotifier |
| WsService | `lib/services/ws_service.dart` | Service |
| experimentConnectionStateProvider | `lib/providers/experiment_provider.dart` | StreamProvider |

### 1.2 测试目标

- 验证控制台五状态全生命周期的 UI 正确性（IDLE / LOADED / RUNNING / PAUSED / COMPLETED / ABORTED）
- 验证控制按钮组在各状态下启用/禁用的正确性
- 验证运行时长计时器的正确性（RUNNING 实时递增 / PAUSED 冻结 / 格式 HH:MM:SS）
- 验证执行日志（LogViewer）的渲染、自动滚动、筛选、清空功能
- 验证 WebSocket 连接生命周期（进入连接 / 离开断开 / 自动重连 / 手动重连）
- 验证 WebSocket 消息分发（状态变更 → 更新控制面板 / 日志消息 → 追加日志区）
- 验证停止二次确认、按钮防重复提交
- 验证响应式布局（大屏左右分栏 / 小屏上下堆叠）
- 验证边界和错误处理（无效 ID、网络错误、空数据）

### 1.3 状态枚举（ExperimentStatus）

| 值 | 显示名 | 标签颜色 | 动画 |
|:--|:--|:--|:--|
| `idle` | IDLE | 灰色 | 无 |
| `loaded` | LOADED | 蓝色 | 无 |
| `running` | RUNNING | 绿色 | **脉冲动画** |
| `paused` | PAUSED | 橙色 | 无 |
| `completed` | COMPLETED | 绿色 | 无 |
| `aborted` | ABORTED | 红色 | 无 |

### 1.4 状态 → 按钮可用性映射

| 当前状态 | 载入 | 开始 | 暂停 | 继续 | 停止 |
|---------|:---:|:---:|:---:|:---:|:---:|
| IDLE | ✅ | ❌ | ❌ | ❌ | ❌ |
| LOADED | ❌ | ✅ | ❌ | ❌ | ❌ |
| RUNNING | ❌ | ❌ | ✅ | ❌ | ✅ |
| PAUSED | ❌ | ❌ | ❌ | ✅ | ✅ |
| COMPLETED | ❌ | ❌ | ❌ | ❌ | ❌ |
| ABORTED | ❌ | ❌ | ❌ | ❌ | ❌ |

### 1.5 WebSocket 连接状态枚举

| 值 | 显示 | 图标 |
|:--|:--|:--|
| `disconnected` | 已断开 | 🔴 |
| `connecting` | 连接中... | 🟡 |
| `connected` | 已连接 | 🟢 |
| `reconnecting` | 重连中(N/5)... | 🟡 |
| `failed` | 连接失败 | 🔴 + 手动重连按钮 |

---

## 2. 测试环境

### 2.1 依赖版本

| 依赖 | 版本 |
|------|------|
| flutter_riverpod | ^3.3.1 |
| web_socket_channel | ^3.0.3 |
| mocktail | latest |
| flutter_test | SDK |

### 2.2 Mock 对象

- `MockExperimentService` — ExperimentService（Provider 测试隔离）
- `MockWsService` — WsService（WS 行为模拟）
- `MockStreamController` — 模拟 WebSocket 消息流
- `MockConnectionStateController` — 模拟连接状态流

### 2.3 测试数据

```dart
// 标准试验对象（RUNNING 状态）
const testExperiment = Experiment(
  id: 'exp-001',
  userId: 'user-001',
  methodId: 'method-001',
  name: '温度循环测试',
  description: '标准热循环测试',
  status: ExperimentStatus.running,
  ownerType: 'personal',
  ownerId: 'user-001',
  startedAt: '2026-06-02T10:00:00+00:00',
  endedAt: null,
  createdAt: '2026-06-02T09:30:00+00:00',
  updatedAt: '2026-06-02T10:30:00+00:00',
);

// 标准日志条目
const testLogEntry = ExperimentLogEntry(
  level: LogLevel.info,
  timestamp: '10:30:01',
  message: '试验开始',
);
```

---

## 3. 页面布局与渲染测试

### TC-PAGE-001: 页面初始加载 Loading 状态
- **前置条件**: ExperimentControlNotifier 处于 `AsyncLoading` 状态
- **操作**: 打开路由 `/experiments/exp-001`
- **预期结果**:
  1. 显示加载指示器（骨架屏或 `CircularProgressIndicator`）
  2. 页面结构（header + 左右分栏）的骨架占位可见
  3. 不产生任何错误日志

### TC-PAGE-002: 页面数据加载成功 — 渲染完整布局
- **前置条件**: ExperimentControlNotifier 返回 `AsyncData(testExperiment)`，WS 已连接
- **操作**: 打开路由 `/experiments/exp-001`
- **预期结果**:
  1. **顶部栏**：显示返回按钮"← 返回列表"、试验名称"温度循环测试"、状态标签"RUNNING"（绿色+脉冲动画）、WS 连接指示"🟢已连接"
  2. **左侧**：控制面板渲染（工作台名、方法名、控制按钮组、状态大字、计时器）
  3. **右侧**：执行日志区渲染（日志列表 + 底部控制栏）
  4. 左右布局使用分栏（大屏并排）

### TC-PAGE-003: 页面渲染缺失 `methodId` 的试验
- **前置条件**: Experiment 对象 `methodId = null`
- **操作**: 打开路由 `/experiments/exp-002`
- **预期结果**:
  1. 控制面板中"方法"显示为"—"或"未指定"
  2. 控制按钮"载入"可用（IDLE 状态）
  3. 其他元素正常渲染

### TC-PAGE-004: 页面渲染缺失 `startedAt` 的试验
- **前置条件**: Experiment 对象 `startedAt = null`，状态为 RUNNING
- **操作**: 打开路由 `/experiments/exp-003`
- **预期结果**:
  1. 控制面板"开始时间"显示为"—"
  2. 计时器从 00:00:00 开始（没有有效起始时间时）
  3. 其他元素正常渲染

### TC-PAGE-005: 页面渲染无 description 的试验
- **前置条件**: Experiment 对象 `description = null`
- **操作**: 打开路由 `/experiments/exp-004`
- **预期结果**:
  1. 不在控制面板显示描述行（或显示"—"）
  2. 其他元素正常渲染

---

## 4. 控制面板 — 信息展示测试

### TC-CP-INFO-001: 控制面板显示试验基本信息
- **前置条件**: Experiment 数据完整（含 workbenchName 和 methodName）
- **操作**: 查看控制面板
- **预期结果**:
  1. 显示"工作台：温度实验室"（或对应名称）
  2. 显示"方法：标准热循环"（或对应名称）
  3. 显示"创建时间：2026-06-02 09:30"
  4. 以上信息来自 Experiment 对象（或通过 API 扩展获取）

### TC-CP-INFO-002: 控制面板显示 Workbench 名称加载中
- **前置条件**: Experiment 已加载但 workbench 名称异步加载中
- **操作**: 查看控制面板
- **预期结果**:
  1. "工作台"栏显示加载指示器（小骨架或省略号动画）
  2. 加载完成后显示实际名称

### TC-CP-INFO-003: 控制面板显示 Method 名称加载失败
- **前置条件**: Experiment 已加载但 method 详情请求失败
- **操作**: 查看控制面板
- **预期结果**:
  1. "方法"栏显示 methodId 或"—"（优雅降级）
  2. 不会因 method 加载失败而阻止整个控制面板渲染

---

## 5. 控制面板 — 状态显示测试

### TC-CP-STATUS-001: IDLE 状态显示 — 灰色标签 + 无动画
- **前置条件**: Experiment.status = `ExperimentStatus.idle`
- **操作**: 查看控制面板状态区域
- **预期结果**:
  1. 状态文字大字显示"IDLE"
  2. 状态标签背景色为灰色（如 `Colors.grey`）
  3. 无脉冲动画
  4. 标题栏状态标签同样为灰色

### TC-CP-STATUS-002: LOADED 状态显示 — 蓝色标签 + 无动画
- **前置条件**: Experiment.status = `ExperimentStatus.loaded`
- **操作**: 查看控制面板状态区域
- **预期结果**:
  1. 状态文字大字显示"LOADED"
  2. 状态标签背景色为蓝色（如 `Colors.blue`）
  3. 无脉冲动画

### TC-CP-STATUS-003: RUNNING 状态显示 — 绿色标签 + 脉冲动画
- **前置条件**: Experiment.status = `ExperimentStatus.running`
- **操作**: 查看控制面板状态区域
- **预期结果**:
  1. 状态文字大字显示"RUNNING"
  2. 状态标签背景色为绿色（如 `Colors.green`）
  3. **标题栏和左侧面板中的状态标签均带脉冲动画**（持续缩放/透明度变化）
  4. 脉冲动画循环运行，不停止

### TC-CP-STATUS-004: PAUSED 状态显示 — 橙色标签 + 无动画
- **前置条件**: Experiment.status = `ExperimentStatus.paused`
- **操作**: 查看控制面板状态区域
- **预期结果**:
  1. 状态文字大字显示"PAUSED"
  2. 状态标签背景色为橙色（如 `Colors.orange`）
  3. 无脉冲动画

### TC-CP-STATUS-005: COMPLETED 状态显示 — 绿色标签 + 无动画
- **前置条件**: Experiment.status = `ExperimentStatus.completed`
- **操作**: 查看控制面板状态区域
- **预期结果**:
  1. 状态文字大字显示"COMPLETED"
  2. 状态标签背景色为绿色
  3. 无脉冲动画（与 RUNNING 绿色区分）
  4. 可能带有一个完成图标（如 ✓）

### TC-CP-STATUS-006: ABORTED 状态显示 — 红色标签 + 无动画
- **前置条件**: Experiment.status = `ExperimentStatus.aborted`
- **操作**: 查看控制面板状态区域
- **预期结果**:
  1. 状态文字大字显示"ABORTED"
  2. 状态标签背景色为红色（如 `Colors.red`）
  3. 无脉冲动画
  4. 可能带有一个警告图标

---

## 6. 控制面板 — 按钮状态矩阵测试

### TC-CP-BTN-001: IDLE 状态 — 仅"载入"按钮可用
- **前置条件**: Experiment.status = `ExperimentStatus.idle`
- **操作**: 查看控制按钮组
- **预期结果**:
  1. "载入"按钮：**可用**（Enabled）
  2. "开始"按钮：**禁用**（Disabled / greyed out）
  3. "暂停"按钮：**禁用**
  4. "继续"按钮：**禁用**
  5. "停止"按钮：**禁用**
  6. 禁用按钮视觉上有灰色/降低透明度效果

### TC-CP-BTN-002: LOADED 状态 — 仅"开始"按钮可用
- **前置条件**: Experiment.status = `ExperimentStatus.loaded`
- **操作**: 查看控制按钮组
- **预期结果**:
  1. "载入"按钮：**禁用**
  2. "开始"按钮：**可用**
  3. "暂停"按钮：**禁用**
  4. "继续"按钮：**禁用**
  5. "停止"按钮：**禁用**

### TC-CP-BTN-003: RUNNING 状态 — "暂停"和"停止"可用
- **前置条件**: Experiment.status = `ExperimentStatus.running`
- **操作**: 查看控制按钮组
- **预期结果**:
  1. "载入"按钮：**禁用**
  2. "开始"按钮：**禁用**
  3. "暂停"按钮：**可用**
  4. "继续"按钮：**禁用**
  5. "停止"按钮：**可用**（通常是红色/危险风格）

### TC-CP-BTN-004: PAUSED 状态 — "继续"和"停止"可用
- **前置条件**: Experiment.status = `ExperimentStatus.paused`
- **操作**: 查看控制按钮组
- **预期结果**:
  1. "载入"按钮：**禁用**
  2. "开始"按钮：**禁用**
  3. "暂停"按钮：**禁用**
  4. "继续"按钮：**可用**
  5. "停止"按钮：**可用**

### TC-CP-BTN-005: COMPLETED 状态 — 全部按钮禁用
- **前置条件**: Experiment.status = `ExperimentStatus.completed`
- **操作**: 查看控制按钮组
- **预期结果**:
  1. 全部五个按钮**禁用**
  2. 可能显示"试验已完成"的提示文字

### TC-CP-BTN-006: ABORTED 状态 — 全部按钮禁用
- **前置条件**: Experiment.status = `ExperimentStatus.aborted`
- **操作**: 查看控制按钮组
- **预期结果**:
  1. 全部五个按钮**禁用**
  2. 可能显示"试验已中止"的提示文字

### TC-CP-BTN-007: 状态转换时按钮实时更新
- **前置条件**: 当前状态 RUNNING，WS 收到 `status_change: RUNNING → PAUSED`
- **操作**: 观察控制按钮组更新
- **预期结果**:
  1. "暂停"按钮立即变为禁用
  2. "继续"按钮立即变为可用
  3. "停止"按钮保持可用
  4. 状态标签立即从 RUNNING（绿色+脉冲）变为 PAUSED（橙色+无脉冲）

### TC-CP-BTN-008: 操作进行中时按钮禁用（防重复提交）
- **前置条件**: 用户点击"暂停"按钮，操作正在进行
- **操作**: 在操作完成前再次点击任何控制按钮
- **预期结果**:
  1. 操作进行中时所有控制按钮**不可点击**
  2. 被点击的按钮显示加载状态（spinner）
  3. 操作完成后按钮恢复正常状态

### TC-CP-BTN-009: 操作失败后按钮恢复可用
- **前置条件**: 用户点击"开始"按钮，操作因网络错误失败
- **操作**: 等待操作失败
- **预期结果**:
  1. 按钮从加载状态恢复为可用状态
  2. 显示错误 Toast 消息
  3. 其他按钮也恢复为当前状态对应的启用/禁用

---

## 7. 控制面板 — 定时器测试

### TC-CP-TIMER-001: RUNNING 状态 — 定时器从 startedAt 开始计时
- **前置条件**: Experiment.startedAt = `2026-06-02T10:00:00`，当前时间模拟为 `10:05:30`
- **操作**: 查看"已运行"定时器
- **预期结果**:
  1. 显示格式 `HH:MM:SS`，内容 `00:05:30`
  2. 每秒钟递增一次
  3. 小时/分钟/秒正确进位（60 秒 → 1 分钟）

### TC-CP-TIMER-002: RUNNING 状态 — 定时器超过 1 小时显示
- **前置条件**: Experiment.startedAt 为 1 小时 30 分 15 秒前
- **操作**: 查看定时器
- **预期结果**:
  1. 显示 `01:30:15`（而不是 `90:15` 或 `01:30:XX` 不完整）
  2. 继续每秒递增

### TC-CP-TIMER-003: PAUSED 状态 — 定时器冻结不动
- **前置条件**: 试验从 RUNNING 变为 PAUSED，暂停时定时器显示 `00:05:30`
- **操作**: 等待 5 秒后查看定时器
- **预期结果**:
  1. 定时器仍显示 `00:05:30`（不递增）
  2. 其余页面元素正常渲染

### TC-CP-TIMER-004: PAUSED→RUNNING — 定时器从冻结点恢复
- **前置条件**: PAUSED 时定时器冻结在 `00:05:30`，点击"继续"
- **操作**: 等待 3 秒后查看定时器
- **预期结果**:
  1. 定时器从 `00:05:30` 继续递增 → `00:05:33`
  2. 而非从 `startedAt` 重新计算

### TC-CP-TIMER-005: IDLE 状态 — 定时器不显示
- **前置条件**: Experiment.status = `ExperimentStatus.idle`，startedAt = null
- **操作**: 查看控制面板
- **预期结果**:
  1. "已运行"区域不显示（或显示"—"）
  2. 不会出现 `00:00:00` 或负数

### TC-CP-TIMER-006: LOADED 状态 — 定时器不显示
- **前置条件**: Experiment.status = `ExperimentStatus.loaded`，startedAt = null
- **操作**: 查看控制面板
- **预期结果**:
  1. "已运行"区域不显示（或显示"—"）
  2. 不会出现计时器

### TC-CP-TIMER-007: COMPLETED 状态 — 显示最终运行时长（冻结）
- **前置条件**: Experiment.startedAt 与 endedAt 差值为 `00:15:30`
- **操作**: 查看控制面板
- **预期结果**:
  1. 显示"已运行：00:15:30"或"总运行时长：00:15:30"
  2. 定时器不递增（终态）

### TC-CP-TIMER-008: startedAt 的本地化处理
- **前置条件**: Experiment.startedAt 为 UTC 时间 `2026-06-02T10:00:00+00:00`，用户时区为 UTC+8
- **操作**: 查看定时器和时间显示
- **预期结果**:
  1. 计时器基于 UTC 时间差计算（不受时区影响）
  2. "开始时间"显示为本地时间格式 `18:00`（或 `2026-06-02 18:00`）

### TC-CP-TIMER-009: 计时器在页面不可见时停止更新
- **前置条件**: 试验 RUNNING，计时器正常递增
- **操作**: 导航到其他页面（控制台页面被替换）
- **预期结果**:
  1. 离开页面后计时器 Timer 被取消
  2. 没有控制台日志输出
  3. 回退到控制台时重新开始计时

---

## 8. 控制面板 — 停止确认与按钮反馈测试

### TC-CP-STOP-001: 停止按钮点击 — 弹出确认对话框
- **前置条件**: Experiment.status = `ExperimentStatus.running`
- **操作**: 点击"停止"按钮
- **预期结果**:
  1. 弹出确认对话框
  2. 对话框包含标题（如"确认停止"）和内容（如"确定要停止当前试验吗？此操作不可撤销。"）
  3. 对话框包含"取消"和"确认停止"两个按钮
  4. "确认停止"按钮使用危险（红色）样式

### TC-CP-STOP-002: 停止确认对话框 — 点击取消
- **前置条件**: 停止确认对话框已弹出
- **操作**: 点击"取消"按钮
- **预期结果**:
  1. 对话框关闭
  2. 试验状态不变（仍为 RUNNING）
  3. 控制按钮状态不变
  4. 不发送停止请求

### TC-CP-STOP-003: 停止确认对话框 — 点击确认
- **前置条件**: 停止确认对话框已弹出
- **操作**: 点击"确认停止"按钮
- **预期结果**:
  1. 对话框关闭
  2. "停止"按钮显示 loading 状态
  3. 调用 `ExperimentControlNotifier.stop()`
  4. 停止成功后状态更新为 COMPLETED/LOADED
  5. 显示成功 Toast

### TC-CP-STOP-004: PAUSED 状态停止也需确认
- **前置条件**: Experiment.status = `ExperimentStatus.paused`
- **操作**: 点击"停止"按钮
- **预期结果**:
  1. 弹出确认对话框（与 RUNNING 时相同）
  2. 确认后执行停止操作

### TC-CP-STOP-005: 停止操作失败 — 显示错误
- **前置条件**: 后端返回停止失败错误
- **操作**: 在确认对话框中点击"确认停止"
- **预期结果**:
  1. 对话框关闭
  2. 停止按钮显示 loading 后恢复
  3. Toast 显示具体错误消息（如"停止操作失败：服务器内部错误"）
  4. 试验状态保持 RUNNING/PAUSED 不变

### TC-CP-FEEDBACK-001: "载入"按钮点击 — 正常流程
- **前置条件**: Experiment.status = `ExperimentStatus.idle`，已选择 methodId
- **操作**: 点击"载入"按钮
- **预期结果**:
  1. 按钮显示 loading 动画
  2. 调用 `ExperimentControlNotifier.load(methodId: 'method-001')`
  3. 成功后状态变为 LOADED，按钮更新
  4. 显示成功 Toast："试验方法已载入"

### TC-CP-FEEDBACK-002: "开始"按钮点击 — 正常流程
- **前置条件**: Experiment.status = `ExperimentStatus.loaded`
- **操作**: 点击"开始"按钮
- **预期结果**:
  1. 按钮显示 loading 动画
  2. 调用 `ExperimentControlNotifier.start()`
  3. 成功后状态变为 RUNNING
  4. 定时器开始计时
  5. 按钮组更新（暂停、停止可用）

### TC-CP-FEEDBACK-003: "暂停"按钮点击 — 正常流程
- **前置条件**: Experiment.status = `ExperimentStatus.running`
- **操作**: 点击"暂停"按钮
- **预期结果**:
  1. 按钮显示 loading 动画
  2. 调用 `ExperimentControlNotifier.pause()`
  3. 成功后状态变为 PAUSED
  4. 定时器冻结
  5. 按钮组更新（继续、停止可用）

### TC-CP-FEEDBACK-004: "继续"按钮点击 — 正常流程
- **前置条件**: Experiment.status = `ExperimentStatus.paused`
- **操作**: 点击"继续"按钮
- **预期结果**:
  1. 按钮显示 loading 动画
  2. 调用 `ExperimentControlNotifier.resume()`
  3. 成功后状态变为 RUNNING
  4. 定时器恢复计时
  5. 按钮组更新（暂停、停止可用）

### TC-CP-FEEDBACK-005: 按钮点击 — 后端返回 HTTP 错误
- **前置条件**: 点击"开始"按钮，后端返回 409（状态冲突）
- **操作**: 观察页面反应
- **预期结果**:
  1. Toast 显示用户可读错误消息（如"试验状态冲突，请刷新后重试"）
  2. 按钮从 loading 恢复
  3. 试验状态刷新为后端实际状态

### TC-CP-FEEDBACK-006: 按钮点击 — 网络连接失败
- **前置条件**: 点击"暂停"按钮，网络断开
- **操作**: 观察页面反应
- **预期结果**:
  1. Toast 显示"网络连接失败，请检查网络后重试"
  2. 按钮从 loading 恢复
  3. 不崩溃

---

## 9. 执行日志显示测试

### TC-LOG-DISPLAY-001: 日志使用等宽字体
- **前置条件**: 日志区有若干条日志
- **操作**: 检查日志文本的字体
- **预期结果**:
  1. 日志文本使用等宽字体（`monospace` / `fontFamily: 'monospace'`）
  2. 每行日志字符对齐

### TC-LOG-DISPLAY-002: 日志级别 INFO — 蓝色标签
- **前置条件**: 日志流中包含 INFO 级别日志
- **操作**: 查看日志区
- **预期结果**:
  1. 日志级别标签显示"INFO"
  2. 标签/文本颜色为蓝色（如 `Colors.blue[700]` 或 `Colors.blue`）
  3. 格式为 `[INFO] HH:MM:SS 消息内容`

### TC-LOG-DISPLAY-003: 日志级别 WARN — 橙色标签
- **前置条件**: 日志流中包含 WARN 级别日志
- **操作**: 查看日志区
- **预期结果**:
  1. 日志级别标签显示"WARN"
  2. 标签/文本颜色为橙色（如 `Colors.orange`）
  3. 格式为 `[WARN] HH:MM:SS 消息内容`

### TC-LOG-DISPLAY-004: 日志级别 ERROR — 红色标签
- **前置条件**: 日志流中包含 ERROR 级别日志
- **操作**: 查看日志区
- **预期结果**:
  1. 日志级别标签显示"ERROR"
  2. 标签/文本颜色为红色（如 `Colors.red`）
  3. ERROR 日志可能有额外强调样式（如背景高亮）

### TC-LOG-DISPLAY-005: 日志级别 DEBUG — 灰色标签
- **前置条件**: 日志流中包含 DEBUG 级别日志
- **操作**: 查看日志区
- **预期结果**:
  1. 日志级别标签显示"DEBUG"
  2. 标签/文本颜色为灰色（如 `Colors.grey`）
  3. 格式与 INFO/WARN/ERROR 一致

### TC-LOG-DISPLAY-006: 时间戳格式 HH:MM:SS
- **前置条件**: 日志区有日志
- **操作**: 检查时间戳格式
- **预期结果**:
  1. 每条日志包含时间戳
  2. 格式为 `HH:MM:SS`（如 `14:30:01`）
  3. 时间戳紧跟在级别标签后面
  4. 日志按时间先后排列（先进先显示）

### TC-LOG-DISPLAY-007: 日志消息跨行显示
- **前置条件**: 一条日志消息较长（超过一行宽）
- **操作**: 查看日志区
- **预期结果**:
  1. 长消息在日志区宽度边界处**自动换行**（不溢出）
  2. 不出现水平滚动条
  3. 折行后缩进与第一行对齐（方便阅读）

### TC-LOG-DISPLAY-008: 空日志初始状态
- **前置条件**: 刚进入控制台，尚未收到任何日志
- **操作**: 查看日志区
- **预期结果**:
  1. 日志区为空或有提示文字（如"等待日志..."或"暂无日志"）
  2. 不显示空白的异常状态

### TC-LOG-DISPLAY-009: 大量日志渲染性能
- **前置条件**: 日志流中已有 1000+ 条日志
- **操作**: 继续接收新日志，观察滚动性能
- **预期结果**:
  1. 界面不卡顿
  2. Web 端帧率 ≥ 30fps
  3. 建议使用 `ListView.builder` + `itemCount` 虚拟滚动
  4. 限制最大可见日志数量（如保留最近 1000 条）

### TC-LOG-DISPLAY-010: 从 ExperimentService.getHistory() 轮询获取日志并追加
- **前置条件**: 后端不通过 WebSocket 发送 log 类型消息；日志通过 `ExperimentService.getHistory()` 接口轮询获取，日志区已有 3 条日志
- **操作**: 轮询周期到达，`getHistory()` 返回一批新日志条目
- **预期结果**:
  1. 新日志**追加到列表末尾**（非列表头部，去重已存在的日志）
  2. 新日志按级别显示正确的颜色
  3. 自动滚动到最底部（如果滚动条在底部）
  4. 轮询间隔建议 2-5 秒，不影响用户操作

---

## 10. 执行日志自动滚动测试

### TC-LOG-SCROLL-001: 用户在底部 — 新日志自动滚动
- **前置条件**: 滚动条在日志区最底部
- **操作**: WS 推送一条新日志
- **预期结果**:
  1. 自动滚动到新的最底部
  2. 最新日志始终可见
  3. 滚动过程平滑（无跳动）

### TC-LOG-SCROLL-002: 用户手动上滚 — 不自动滚动
- **前置条件**: 用户向上滚动查看历史日志（不在底部）
- **操作**: WS 推送 5 条新日志
- **预期结果**:
  1. **不自动滚动**到底部（保持当前滚动位置）
  2. 5 条新日志在不可见区域正常追加
  3. 右下角出现"↓ 新日志"浮动按钮

### TC-LOG-SCROLL-003: 浮动按钮 — 显示"↓ 新日志"
- **前置条件**: 用户向上滚动到历史日志区域，又有新日志追加
- **操作**: 观察日志区右下角
- **预期结果**:
  1. 出现一个浮动按钮"↓ 新日志"（或"↓ 回到最新"）
  2. 按钮不遮挡日志内容
  3. 可能带有新日志数量提示（如"↓ 5 条新日志"）

### TC-LOG-SCROLL-004: 点击浮动按钮 — 滚动到底部
- **前置条件**: 浮动按钮"↓ 新日志"已显示
- **操作**: 点击浮动按钮
- **预期结果**:
  1. 日志区平滑滚动到底部
  2. 最新日志可见
  3. 浮动按钮消失
  4. 之后新日志继续自动滚动

### TC-LOG-SCROLL-005: 用户手动滚回底部 — 浮动按钮消失
- **前置条件**: 用户向上滚动，浮动按钮显示
- **操作**: 用户手动滚回底部
- **预期结果**:
  1. 浮动按钮消失
  2. 之后新日志继续自动滚动

### TC-LOG-SCROLL-006: 浮动按钮不影响用户选择/复制
- **前置条件**: 浮动按钮显示，用户试图选中部分日志文本
- **操作**: 鼠标拖拽选择日志文本
- **预期结果**:
  1. 浮动按钮不响应鼠标选择事件
  2. 日志文本可正常选中和复制
  3. 浮动按钮位置不遮挡最后一行日志（留有安全距离）

---

## 11. 执行日志筛选与清空测试

### TC-LOG-FILTER-001: 默认显示所有级别
- **前置条件**: 日志区有 INFO、WARN、ERROR、DEBUG 各级别日志
- **操作**: 进入控制台，未修改筛选设置
- **预期结果**:
  1. 所有级别的日志均显示
  2. 筛选控件显示为"全部"或所有级别都被选中

### TC-LOG-FILTER-002: 筛选仅显示 INFO
- **前置条件**: 日志区有 INFO、WARN、ERROR、DEBUG 日志
- **操作**: 在筛选器中选择仅 "INFO"
- **预期结果**:
  1. 仅显示 INFO 级别的日志条目
  2. WARN、ERROR、DEBUG 日志被隐藏
  3. 筛选后日志列表立即更新（不延迟）

### TC-LOG-FILTER-003: 筛选显示 INFO + WARN
- **前置条件**: 日志区有 INFO、WARN、ERROR 日志
- **操作**: 选择 INFO 和 WARN
- **预期结果**:
  1. 显示 INFO 和 WARN 日志
  2. ERROR 和 DEBUG 被隐藏

### TC-LOG-FILTER-004: 筛选切换后新日志遵守筛选规则
- **前置条件**: 当前筛选为"仅 INFO"
- **操作**: WS 推送一条 WARN 日志
- **预期结果**:
  1. WARN 日志**不在日志区显示**（但后台已追加）
  2. 当筛选切换为"全部"或"WARN"时该日志可见

### TC-LOG-FILTER-005: 筛选不影响"清空日志"按钮行为
- **前置条件**: 当前筛选为"仅 INFO"，日志区只显示 INFO 日志
- **操作**: 点击"清空日志"
- **预期结果**:
  1. **所有级别的日志都被清空**（不只是当前筛选可见的）
  2. 切换筛选后也没有任何日志

### TC-LOG-FILTER-006: 筛选多选 — 取消所有级别
- **前置条件**: 日志区有日志
- **操作**: 取消所有级别筛选（或多选框中取消全部勾选）
- **预期结果**:
  1. 日志区显示为空（或显示"无日志匹配筛选条件"）
  2. 不应崩溃

### TC-LOG-CLEAR-001: 点击"清空日志"按钮
- **前置条件**: 日志区有 50 条日志
- **操作**: 点击日志区底部的"清空日志"按钮
- **预期结果**:
  1. 所有日志条目被清除
  2. 日志区显示为空/初始状态
  3. 如果有浮动按钮，浮动按钮消失

### TC-LOG-CLEAR-002: 清空后新日志正常追加
- **前置条件**: 日志区已清空
- **操作**: WS 推送新日志
- **预期结果**:
  1. 新日志正常追加到空的日志区
  2. 自动滚动恢复正常

### TC-LOG-CLEAR-003: 清空按钮在空日志时禁用或不可见
- **前置条件**: 日志区为空
- **操作**: 查看日志区底部
- **预期结果**:
  1. "清空日志"按钮禁用（灰色）或不显示
  2. 避免无效点击

---

## 12. WebSocket 连接管理测试

### TC-WS-CONN-001: 进入控制台自动连接 WebSocket
- **前置条件**: 用户已登录，有 valid token
- **操作**: 导航到路由 `/experiments/exp-001`
- **预期结果**:
  1. 控制台自动调用 `WsService.connect(experimentId, token)`
  2. 连接状态指示从"连接中..."开始
  3. 连接成功后状态变为"🟢已连接"

### TC-WS-CONN-002: 连接状态显示 — 🟢已连接
- **前置条件**: WS 连接成功
- **操作**: 查看页面顶部栏
- **预期结果**:
  1. 右上角显示 WebSocket 状态区域
  2. 状态指示器和文字"🟢已连接"（绿色指示器）
  3. 格式如 `WS: 🟢已连接`

### TC-WS-CONN-003: 连接状态显示 — 🟡连接中
- **前置条件**: WS 正在尝试建立连接
- **操作**: 查看页面顶部栏
- **预期结果**:
  1. 显示"🟡连接中..."（黄色指示器）
  2. 可能需要显示超时后降级为"🔴已断开"

### TC-WS-CONN-004: 连接状态显示 — 🔴已断开
- **前置条件**: WS 连接意外断开（非手动）
- **操作**: 查看页面顶部栏
- **预期结果**:
  1. 显示"🔴已断开"（红色指示器）
  2. 可能显示"自动重连中..."

### TC-WS-CONN-005: 离开控制台自动断开 WebSocket
- **前置条件**: 用户正在控制台，WS 已连接
- **操作**: 导航到其他页面（如返回列表 `/experiments`）
- **预期结果**:
  1. `experimentWsProvider` 执行 `ref.onDispose`
  2. `WsService.disconnect()` 被调用
  3. WebSocket 连接被关闭
  4. 不再接收消息

### TC-WS-CONN-006: 同一试验 ID 不重复连接
- **前置条件**: WS 已连接到 `exp-001`
- **操作**: Provider 重建（如热重载），再次 watch `experimentWsProvider('exp-001')`
- **预期结果**:
  1. `WsService.connect()` 检测到已有相同 ID 的连接，不新建
  2. 返回现有消息流
  3. 没有额外的 WebSocket 连接建立

### TC-WS-CONN-007: 不同试验 ID 切换连接
- **前置条件**: WS 已连接到 `exp-001`
- **操作**: 导航到 `/experiments/exp-002`（不同试验）
- **预期结果**:
  1. 旧连接 `exp-001` 被断开
  2. 新连接 `exp-002` 被建立
  3. 日志区重置为空
  4. 控制面板显示新试验信息

---

## 13. WebSocket 消息处理测试

### TC-WS-MSG-001: 接收状态变更消息 → 更新控制面板
- **前置条件**: 试验为 LOADED 状态，WS 已连接
- **操作**: WS 发送 `status_change` 消息（old_status: LOADED, new_status: RUNNING）
- **预期结果**:
  1. ExperimentControlNotifier 状态更新为 RUNNING
  2. 控制面板状态标签从 LOADED（蓝色）变为 RUNNING（绿色+脉冲）
  3. 按钮组更新：暂停、停止可用
  4. 定时器开始计时
  5. 日志区追加一条 INFO 日志（如"[INFO] 试验状态变更：LOADED → RUNNING"）

### TC-WS-MSG-002: 接收状态变更消息 → 相同多实例同步
- **前置条件**: 同一试验由其他用户或后端操作变更状态
- **操作**: WS 推送 `status_change: RUNNING → PAUSED`（由其他用户操作）
- **预期结果**:
  1. 控制面板自动更新为 PAUSED
  2. 按钮组更新
  3. 定时器冻结
  4. 可能会有提示（如"试验已被 user-002 暂停"）

### TC-WS-MSG-003: 接收错误消息 → 显示通知
- **前置条件**: WS 已连接
- **操作**: WS 发送 `error` 消息（error: "Sensor timeout", code: 1001）
- **预期结果**:
  1. 日志区追加一条 ERROR 日志（如"[ERROR] Sensor timeout (code: 1001)"）
  2. 可能弹出 SnackBar / Toast 通知
  3. 试验状态可能根据错误类型自动变更

### TC-WS-MSG-004: 接收格式错误的消息 → 不影响连接
- **前置条件**: WS 已连接
- **操作**: WS 发送无效 JSON 字符串或缺少 `type` 字段的消息
- **预期结果**:
  1. 该条消息被忽略/丢弃
  2. WebSocket 连接**不断开**
  3. 日志区不追加该条消息
  4. 后续正常消息继续接收和处理

### TC-WS-MSG-005: 接收未知 type 的消息 → 忽略不崩溃
- **前置条件**: WS 已连接
- **操作**: WS 发送 `{"type": "unknown_type", "data": {}}`
- **预期结果**:
  1. 消息被忽略
  2. 页面不崩溃
  3. 不产生未处理的错误

### TC-WS-MSG-006: 大量消息快速到达 — 不丢失
- **前置条件**: WS 已连接
- **操作**: 一次推送 100 条日志消息（模拟高频日志）
- **预期结果**:
  1. 100 条消息全部被处理
  2. 日志区显示所有 100 条日志
  3. 自动滚动到底部
  4. UI 不卡顿

---

## 14. WebSocket 断线重连测试

### TC-WS-RECON-001: 断线自动重连 — 第一次成功
- **前置条件**: WS 已连接
- **操作**: 服务器断开连接（模拟 `_onDone`）
- **预期结果**:
  1. 连接状态变为"🟡重连中(1/5)..."
  2. 约 1 秒后尝试重连
  3. 重连成功 → 状态变为"🟢已连接"
  4. 重连计数器重置

### TC-WS-RECON-002: 断线自动重连 — 指数退避
- **前置条件**: WS 已断开，开始自动重连
- **操作**: 记录每次重连尝试的间隔
- **预期结果**:
  1. 第 1 次重连：约 1 秒后
  2. 第 2 次重连：约 2 秒后（距上次）
  3. 第 3 次重连：约 4 秒后
  4. 第 4 次重连：约 8 秒后
  5. 第 5 次重连：约 8 秒后（上限）
  6. 连接状态显示如"🟡重连中(3/5)..."

### TC-WS-RECON-003: 重连期间后续重连成功
- **前置条件**: 第 2 次重连成功
- **操作**: 观察重连流程
- **预期结果**:
  1. 计数器重置为 0
  2. 状态变为"🟢已连接"
  3. 停止后续重连尝试
  4. 重连期间可能丢失的消息不再恢复（后端不保证重发）

### TC-WS-RECON-004: 重连达到上限（5 次失败）
- **前置条件**: 5 次重连尝试均失败
- **操作**: 等待重连上限到达
- **预期结果**:
  1. 连接状态变为"🔴连接失败"
  2. 显示手动"重新连接"按钮
  3. 自动重连停止
  4. 日志区可能显示一条 ERROR 日志"WebSocket 连接失败"

### TC-WS-RECON-005: 手动重连按钮 — 用户点击
- **前置条件**: WS 处于 `failed` 状态，显示"重新连接"按钮
- **操作**: 点击"重新连接"按钮
- **预期结果**:
  1. 重连计数器重置为 0
  2. 状态变为"🟡连接中..."
  3. 调用 `WsService.reconnect()` 发起新连接
  4. 如果成功 → "🟢已连接"；如果失败 → 重新开始自动重连

### TC-WS-RECON-006: 手动断开不触发自动重连
- **前置条件**: WS 已连接
- **操作**: 用户离开页面 → `disconnect()` 被调用
- **预期结果**:
  1. 连接关闭
  2. **不触发自动重连**（因为设置了 `_disposed = true`）
  3. 连接状态为 `disconnected`

### TC-WS-RECON-007: 重连期间用户离开页面 → 取消重连
- **前置条件**: WS 正在自动重连（第 2 次尝试）
- **操作**: 导航离开控制台页面
- **预期结果**:
  1. 重连 Timer 被取消
  2. WsService 清理资源
  3. 不会在离开后继续尝试重连

---

## 15. 导航与生命周期测试

### TC-NAV-001: 通过 URL 直接访问有效试验 ID
- **前置条件**: 用户已登录，试验 `exp-001` 存在
- **操作**: 在地址栏输入 `/experiments/exp-001`
- **预期结果**:
  1. 页面加载试验详情
  2. 控制面板显示正确信息
  3. WS 自动连接

### TC-NAV-002: 通过 URL 访问无效试验 ID
- **前置条件**: 试验 `exp-999` 不存在
- **操作**: 访问 `/experiments/exp-999`
- **预期结果**:
  1. 显示错误视图（"试验未找到"或"无效的试验 ID"）
  2. 不尝试连接 WS（或连接后收到错误即断开）
  3. 提供返回列表的导航选项

### TC-NAV-003: 从试验列表点击"进入控制台"
- **前置条件**: 用户在试验列表页，有一条 RUNNING 状态的试验
- **操作**: 点击该试验的"进入控制台"操作
- **预期结果**:
  1. 导航到 `/experiments/{id}`
  2. 控制台显示该试验的详情
  3. WS 自动连接
  4. 返回按钮可回到列表

### TC-NAV-004: 点击顶部"← 返回列表"
- **前置条件**: 用户在控制台页面
- **操作**: 点击左上角"← 返回列表"按钮
- **预期结果**:
  1. 导航到 `/experiments`（试验列表）
  2. WS 连接断开
  3. 计时器 Timer 取消

### TC-NAV-005: 浏览器后退/前进按钮
- **前置条件**: 用户从列表 → 控制台 → 点击浏览器后退
- **操作**: 使用浏览器后退按钮
- **预期结果**:
  1. 回到试验列表页
  2. WS 断开
  3. 再使用前进按钮 → 回到控制台 → 重新连接 WS，重新加载试验详情

### TC-NAV-006: 页面卸载时资源清理
- **前置条件**: 用户在控制台，各种 Timer/Stream 活跃
- **操作**: 关闭浏览器标签页（或模拟 `dispose`）
- **预期结果**:
  1. WS 连接关闭
  2. 计时器 Timer 取消
  3. StreamSubscription 取消
  4. 无内存泄漏

### TC-NAV-007: 从创建试验流程进入控制台
- **前置条件**: 用户刚完成 TASK-022 的创建试验流程
- **操作**: 创建成功后自动跳转
- **预期结果**:
  1. 导航到 `/experiments/{new_id}`
  2. 新试验状态为 IDLE
  3. 控制面板显示"载入"按钮可用
  4. WS 连接建立

---

## 16. 边界情况与错误处理测试

### TC-EDGE-001: Experiment 加载失败（网络错误）
- **前置条件**: `ExperimentControlNotifier.build()` 抛出网络异常
- **操作**: 访问 `/experiments/exp-001`
- **预期结果**:
  1. 使用 `AsyncValueWidget` 显示错误视图
  2. 错误视图包含用户可读错误消息
  3. 提供"重试"按钮
  4. 点击"重试"重新加载

### TC-EDGE-002: Experiment 加载失败（404 试验不存在）
- **前置条件**: 后端返回 404
- **操作**: 访问 `/experiments/exp-999`
- **预期结果**:
  1. 显示"试验未找到"错误视图
  2. 可导航返回列表

### TC-EDGE-003: Experiment 加载失败（403 无权限）
- **前置条件**: 用户无权访问该试验
- **操作**: 访问他人试验的 URL
- **预期结果**:
  1. 显示"无权访问该试验"错误视图
  2. 提供返回列表的选项

### TC-EDGE-004: WS 连接失败（Token 无效）
- **前置条件**: Token 已过期或无效
- **操作**: 访问控制台
- **预期结果**:
  1. WS 连接尝试失败
  2. 连接状态变为"🔴连接失败"
  3. 显示手动重连按钮
  4. 页面控制面板仍正常渲染（操作按钮可能部分可用）

### TC-EDGE-005: WS 连接超时
- **前置条件**: 后端 WebSocket 服务不可用
- **操作**: 访问控制台
- **预期结果**:
  1. 连接状态首先显示"🟡连接中..."
  2. 一定时间后超时，进入重连逻辑
  3. 超时不应阻塞页面加载

### TC-EDGE-006: 在 LOADED 状态点击已禁用的"载入"按钮
- **前置条件**: Experiment.status = `ExperimentStatus.loaded`
- **操作**: 尝试通过开发者工具启用"载入"按钮并点击
- **预期结果**:
  1. `ExperimentControlNotifier.load()` 中的 `_validateStateTransition` 抛错
  2. 不会发送无效的 HTTP 请求
  3. 前端捕获错误并显示提示

### TC-EDGE-007: 同时收到 WS 状态变更和应用内操作完成
- **前置条件**: 用户点击"暂停"，WS 几乎同时推送状态变更
- **操作**: 观察最终状态
- **预期结果**:
  1. 状态最终一致（PAUSED）
  2. 不出现状态来回跳动
  3. 日志不重复

### TC-EDGE-008: WS 消息在控制面板未加载完成时到达
- **前置条件**: ExperimentControlNotifier 仍在 loading
- **操作**: WS 推送一条 `status_change` 消息
- **预期结果**:
  1. 消息被缓存或在加载完成后处理
  2. 不崩溃
  3. 最终状态正确

### TC-EDGE-009: 页面长时间闲置后恢复
- **前置条件**: 控制台页 30 分钟未操作（浏览器标签页可能被挂起）
- **操作**: 重新激活标签页
- **预期结果**:
  1. WS 可能已断开，触发自动重连
  2. 重连后状态正确同步
  3. 定时器恢复（如果还是 RUNNING 状态）

### TC-EDGE-010: 空 experimented_at 且 startedAt 也为 null 的 COMPLETED 试验
- **前置条件**: Experiment: status=completed, startedAt=null, endedAt=null
- **操作**: 查看控制面板
- **预期结果**:
  1. 显示"已运行"为"—"或"不适用"
  2. 不崩溃

---

## 17. 响应式布局测试

### TC-RESP-001: 大屏幕布局 — 左右分栏（>=1200px）
- **前置条件**: 屏幕宽度 ≥ 1200px
- **操作**: 查看控制台布局
- **预期结果**:
  1. 控制面板在左侧，执行日志在右侧
  2. 左右分栏并排显示
  3. 控制面板约占 35-40% 宽度
  4. 日志区约占 60-65% 宽度
  5. 左右之间有适当间距

### TC-RESP-002: 中等屏幕布局 — 仍左右分栏（600-1200px）
- **前置条件**: 屏幕宽度在 600-1200px
- **操作**: 查看控制台布局
- **预期结果**:
  1. 仍为左右分栏，但比例可能调整
  2. 控制面板可能缩小或按钮换行
  3. 所有元素仍可访问

### TC-RESP-003: 小屏幕布局 — 上下堆叠（<600px）
- **前置条件**: 屏幕宽度 < 600px
- **操作**: 查看控制台布局
- **预期结果**:
  1. 控制面板在上方，执行日志在下方
  2. 垂直滚动整页
  3. 控制面板高度合理（不要占满屏幕）
  4. 日志区有足够高度

### TC-RESP-004: 小屏幕 — 顶部栏自适应
- **前置条件**: 屏幕宽度 < 400px
- **操作**: 查看顶部栏
- **预期结果**:
  1. 返回按钮保留
  2. 试验名称可能截断或缩小字号
  3. WS 状态指示器保留
  4. 元素不重叠

### TC-RESP-005: 小屏幕 — 控制按钮自适应
- **前置条件**: 屏幕宽度 < 400px
- **操作**: 查看控制按钮组
- **预期结果**:
  1. 按钮可能从水平排列变为二维网格
  2. 或使用 `Wrap` widget 自动换行
  3. 所有按钮触摸目标 ≥ 48x48px（Material Design 标准）

### TC-RESP-006: 窗口大小变化后布局实时调整
- **前置条件**: 大屏幕初始状态
- **操作**: 拖动浏览器窗口宽度从 1400px → 400px
- **预期结果**:
  1. 在 ~1200px 左右布局保持不变
  2. 在 ~600px 时左右分栏切换为上下堆叠
  3. 切换过程平滑，无闪烁
  4. 所有状态保持（不重新加载）

---

## 18. 完成/中止状态与历史时间线测试

### TC-COMP-001: COMPLETED 状态 — 显示试验详情面板
- **前置条件**: Experiment.status = `ExperimentStatus.completed`
- **操作**: 查看控制台
- **预期结果**:
  1. 控制按钮全部禁用
  2. 可能显示"试验已完成"标签
  3. 显示试验基本信息（名称、方法、开始/结束时间）
  4. 可选：显示状态变更历史时间线

### TC-COMP-002: COMPLETED 状态 — 显示最终运行时长
- **前置条件**: Experiment: status=completed, startedAt 与 endedAt 差值 15:30
- **操作**: 查看控制面板
- **预期结果**:
  1. 显示"总运行时长：00:15:30"（冻结不变）
  2. 或"开始时间"和"结束时间"都显示

### TC-COMP-003: ABORTED 状态 — 显示中止信息
- **前置条件**: Experiment.status = `ExperimentStatus.aborted`
- **操作**: 查看控制台
- **预期结果**:
  1. 控制按钮全部禁用
  2. 显示"试验已中止"标签（红色）
  3. 如有 error_message 则显示

### TC-COMP-004: 状态变更历史时间线显示
- **前置条件**: Experiment 有完整状态历史（IDLE→LOADED→RUNNING→PAUSED→RUNNING→COMPLETED）
- **操作**: 查看历史时间线区域
- **预期结果**:
  1. 每个状态变更显示为一条记录
  2. 记录包含：旧状态 → 新状态、操作人、时间戳
  3. 时间线按时间倒序或正序排列
  4. 每条记录带状态颜色标识
  5. 格式如："14:30 LOADED → RUNNING · start · user-001"

### TC-COMP-005: 状态变更历史为空
- **前置条件**: Experiment 刚创建，还没有任何状态变更
- **操作**: 查看历史时间线
- **预期结果**:
  1. 显示"暂无状态变更记录"或空状态
  2. 不显示空白区域异常

### TC-COMP-006: 从完成试验跳转到分析页面
- **前置条件**: Experiment 已完成，有测点数据
- **操作**: 点击"查看数据分析"或类似链接
- **预期结果**:
  1. 导航到 `/analysis` 页面（或带参数的数据分析页）
  2. 预选该试验为数据来源

---

## 19. 测试覆盖矩阵

### 19.1 需求覆盖

| PRD 需求 | 测试用例 |
|----------|----------|
| 控制面板试验信息摘要 | TC-CP-INFO-001, TC-CP-INFO-002, TC-CP-INFO-003 |
| 控制按钮状态映射（5 状态 × 5 按钮） | TC-CP-BTN-001 至 TC-CP-BTN-009 |
| 状态标签颜色 + 脉冲动画 | TC-CP-STATUS-001 至 TC-CP-STATUS-006 |
| 运行时长计时器 | TC-CP-TIMER-001 至 TC-CP-TIMER-009 |
| 停止按钮二次确认 | TC-CP-STOP-001 至 TC-CP-STOP-005 |
| 按钮 loading + 防重复 | TC-CP-BTN-008, TC-CP-BTN-009, TC-CP-FEEDBACK-001 至 006 |
| 等宽字体日志显示 | TC-LOG-DISPLAY-001 |
| 日志级别颜色（INFO/WARN/ERROR/DEBUG） | TC-LOG-DISPLAY-002 至 005 |
| 日志时间戳 HH:MM:SS | TC-LOG-DISPLAY-006 |
| 自动滚动到底部 | TC-LOG-SCROLL-001 |
| 手动滚动锁定 + 浮动按钮 | TC-LOG-SCROLL-002 至 006 |
| 日志级别筛选 | TC-LOG-FILTER-001 至 006 |
| 清空日志 | TC-LOG-CLEAR-001 至 003 |
| WS 自动连接/离开断开 | TC-WS-CONN-001 至 005 |
| WS 连接状态指示 🟢🟡🔴 | TC-WS-CONN-002 至 004 |
| WS 自动重连 + 指数退避 | TC-WS-RECON-001 至 007 |
| WS 消息分发 | TC-WS-MSG-001 至 006 |
| 响应式布局 | TC-RESP-001 至 006 |
| 试验完成/中止状态 | TC-COMP-001 至 003 |
| 状态变更历史时间线 | TC-COMP-004, TC-COMP-005 |
| 创建试验后进入控制台 | TC-NAV-007 |

### 19.2 状态覆盖

| 状态 | 信息 | 按钮 | 定时器 | 布局 |
|------|:--:|:--:|:--:|:--:|
| IDLE | ✅ | ✅ | ✅ | ✅ |
| LOADED | ✅ | ✅ | ✅ | ✅ |
| RUNNING | ✅ | ✅ | ✅ | ✅ |
| PAUSED | ✅ | ✅ | ✅ | ✅ |
| COMPLETED | ✅ | ✅ | ✅ | ✅ |
| ABORTED | ✅ | ✅ | ✅ | ✅ |

### 19.3 连接状态覆盖

| 连接状态 | 覆盖 |
|----------|:--:|
| connecting | ✅ |
| connected | ✅ |
| reconnecting | ✅ |
| failed | ✅ |
| disconnected | ✅ |

### 19.4 统计

| 类别 | 数量 |
|------|-----|
| 测试用例总数 | **117** |
| 页面布局与渲染 | 5 |
| 控制面板 — 信息展示 | 3 |
| 控制面板 — 状态显示 | 6 |
| 控制面板 — 按钮状态矩阵 | 9 |
| 控制面板 — 定时器 | 9 |
| 控制面板 — 停止确认与反馈 | 11 |
| 执行日志显示 | 10 |
| 执行日志自动滚动 | 6 |
| 执行日志筛选与清空 | 9 |
| WS 连接管理 | 7 |
| WS 消息处理 | 6 |
| WS 断线重连 | 7 |
| 导航与生命周期 | 7 |
| 边界情况与错误处理 | 10 |
| 响应式布局 | 6 |
| 完成/中止与历史 | 6 |

---

## 20. Mock 规范

### 20.1 MockExperimentService

```dart
class MockExperimentService extends Mock implements ExperimentService {
  MockExperimentService() {
    // 默认行为：getById 返回 testExperiment
    when(() => getById(any())).thenAnswer(
      (_) async => testExperiment,
    );
  }
}
```

### 20.2 MockWsService

```dart
class MockWsService extends Mock implements WsService {
  final _messageController = StreamController<ExperimentMessage>.broadcast();
  final _connectionStateController = StreamController<WsConnectionState>.broadcast();

  MockWsService() {
    when(() => connect(any(), any())).thenAnswer((_) {
      Timer(const Duration(milliseconds: 100), () {
        _connectionStateController.add(WsConnectionState.connected);
      });
      return _messageController.stream;
    });

    when(() => disconnect()).thenAnswer((_) {
      _connectionStateController.add(WsConnectionState.disconnected);
    });

    when(() => get connectionState).thenAnswer(
      (_) => _connectionStateController.stream,
    );

    when(() => get currentConnectionState).thenReturn(
      WsConnectionState.connected,
    );
  }

  void simulateMessage(ExperimentMessage msg) {
    _messageController.add(msg);
  }

  void simulateDisconnect() {
    _connectionStateController.add(WsConnectionState.reconnecting);
  }

  void simulateReconnectSuccess() {
    _connectionStateController.add(WsConnectionState.connected);
  }

  void dispose() {
    _messageController.close();
    _connectionStateController.close();
  }
}
```

### 20.3 Widget Test 包裹方式

```dart
Widget createTestApp({required String experimentId, Widget? child}) {
  return ProviderScope(
    overrides: [
      experimentControlProvider(experimentId).overrideWith(
        (ref, id) => ExperimentControlNotifier(id)..state = AsyncData(testExperiment),
      ),
      experimentWsProvider(experimentId).overrideWith(
        (ref, id) => mockWsService.connect(id, 'test-token'),
      ),
      experimentConnectionStateProvider(experimentId).overrideWith(
        (ref, id) => Stream.value(WsConnectionState.connected),
      ),
      experimentServiceProvider.overrideWithValue(mockExperimentService),
      wsServiceProvider.overrideWithValue(mockWsService),
    ],
    child: MaterialApp(
      home: ExperimentConsolePage(id: experimentId),
    ),
  );
}
```

### 20.4 Golden / Screenshot 测试覆盖

建议为以下关键状态创建 golden 测试：

| 状态 | 亮度 | 说明 |
|------|:--:|------|
| IDLE | Light | 初始状态，载入按钮可用 |
| LOADED | Light | 方法已载入，开始按钮可用 |
| RUNNING | Light | 运行中，定时器 + 脉冲动画 |
| PAUSED | Light | 暂停中，定时器冻结 |
| COMPLETED | Light | 完成，按钮全禁用 |
| ABORTED | Light | 中止，按钮全禁用 |
| RUNNING | Dark | 深色主题验证 |

---

## 附录 A：日志条目数据结构（建议）

```dart
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

class ExperimentLogEntry {
  final LogLevel level;
  final String timestamp; // "HH:MM:SS"
  final String message;

  const ExperimentLogEntry({
    required this.level,
    required this.timestamp,
    required this.message,
  });

  Color get color {
    switch (level) {
      case LogLevel.info: return Colors.blue;
      case LogLevel.warn: return Colors.orange;
      case LogLevel.error: return Colors.red;
      case LogLevel.debug: return Colors.grey;
    }
  }
}
```

---

## 附录 B：计时器实现注意事项

1. 计时器必须使用 `Timer.periodic(Duration(seconds: 1), ...)` 每秒更新
2. 使用 `DateTime.now().difference(startedAt)` 计算时长
3. PAUSED 状态下取消 Timer
4. 页面 dispose 时必须 `timer?.cancel()`
5. COMPLETED 状态使用 `endedAt - startedAt` 固定时长
6. 格式化使用 `Duration` 的 `inHours`、`inMinutes.remainder(60)`、`inSeconds.remainder(60)`
7. 显示用 `HH:MM:SS`，需要自行补零（如 `00:05:03`）

---

## 附录 C：按钮组扁平结构 vs 分组结构

建议采用以下分组以提高可读性：
```
[ 载入 ]  [ 开始 ]
[ 暂停 ]  [ 继续 ]  [ 停止 ]
```
或 `Wrap` 横向布局。每个按钮需指定 `onPressed` 回调（null 时为禁用）。

---

---

## 21. 代码审查结论

### 评审信息

| 项目 | 内容 |
|------|------|
| **任务** | TASK-023 试验控制台 UI |
| **测试者** | sw-mike |
| **评审者** | sw-tom (Software Developer) |
| **日期** | 2026-06-02 |
| **版本** | 1.0 |
| **实际测试用例数** | 117（§19.4 统计表已修正为 117） |

### 评审标准 ✅

| 标准 | 结果 | 说明 |
|------|:----:|------|
| 覆盖 PRD 要求 | ✅ | M8 试验执行控制台全部需求覆盖 |
| 覆盖所有 6 种状态 | ✅ | IDLE/LOADED/RUNNING/PAUSED/COMPLETED/ABORTED |
| 覆盖所有 5 种 WS 连接状态 | ✅ | connecting/connected/reconnecting/failed/disconnected |
| 测试用例结构清晰 | ✅ | 前置条件+操作+预期结果 |
| Mock 规范完整可用 | ✅ | 第 20 节提供了完整 Mock 类定义 |
| 与 TASK-020 设计对齐 | ✅ | 状态矩阵、WS 枚举、计时器行为一致 |

### 待确认事项 🔶

| # | 事项 | 类型 | 状态 | 责任人 |
|:-:|------|:----:|:----:|:------|
| 1 | §19.4 统计表显示"76"，实际应有"117" | ✅ 已修正 | 已确认 | sw-mike |
| 2 | TC-LOG-DISPLAY-010 假设 WS 推送日志消息，但 TASK-020 设计未定义 `ExperimentMessage.log` 类型 → 改为从 `ExperimentService.getHistory()` 轮询 | ✅ 已修正 | 已确认 | sw-mike |
| 3 | TC-CP-FEEDBACK-006 硬编码中文文本 `"网络连接失败，请检查网络后重试"`，建议改为引用 l10n key | 🔶 建议 | 可选择 | sw-mike |
| 4 | TC-LOG-DISPLAY-009 帧率断言难以 Widget 测试自动化，建议标注为性能测试 | 🔶 建议 | 可选择 | sw-mike |
| 5 | TC-EDGE-009（30 分钟闲置）自动化难度高，建议明确测试策略 | 🔶 建议 | 可选择 | sw-mike |

### 总体结论 ✅

**APPROVED** — 测试用例质量优秀，覆盖全面、结构清晰、预期结果精确。以上 5 个事项中，#1 和 #2 需在实现前确认，#3-#5 为可选建议可在开发过程中处理。

> **下一步**: 由 sw-tom 进行详细设计，然后开发实现。测试用例已批准，无需修改。


修订完成: ✅
