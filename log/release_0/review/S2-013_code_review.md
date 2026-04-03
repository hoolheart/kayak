# S2-013 代码审查报告: 试验执行控制台页面

**审查人**: sw-jerry (Software Architect/Designer)  
**审查日期**: 2026-04-03  
**审查类型**: 代码审查 (Implementation vs Design)  
**审查范围**: 5个源文件 + 设计文档 + 测试用例对照

---

## 审查结论

**状态**: ❌ **NEEDS FIX** (存在Critical和Major级别问题，不可合并)

---

## 1. Critical Issues (必须修复)

### C-01: `loadExperiment` API 未传递参数

**文件**: `experiment_control_service.dart:37-45`  
**严重性**: Critical

设计文档 (§8.1) 明确要求 `loadExperiment` 传递 `method_id` 和 `parameters`：

```json
{
  "method_id": "method_001",
  "parameters": { "temperature_setpoint": 30.0, "sample_rate": 1000 }
}
```

但实现中只传递了 `method_id`：

```dart
// 当前实现
data: {'method_id': methodId},
// 缺少 parameters
```

**影响**: 用户配置的所有参数值在Load时被丢弃，试验将以默认参数运行，可能导致试验结果不正确。

**修复建议**:
```dart
Future<Experiment> loadExperiment(
    String experimentId, String methodId, Map<String, dynamic> parameters) async {
  final response = await _apiClient.post(
    '/api/v1/experiments/$experimentId/load',
    data: {'method_id': methodId, 'parameters': parameters},
  );
  ...
}
```

同时需要更新 `ExperimentConsoleNotifier.loadExperiment()` 调用处传递 `state.parameterValues`。

---

### C-02: 按钮状态逻辑与设计文档不一致

**文件**: `experiment_console_provider.dart:82-105`  
**严重性**: Critical

设计文档 (§6.1 按钮启用/禁用矩阵) 明确规定：

| 当前状态 | Load | Start | Pause | Resume | Stop |
|----------|------|-------|-------|--------|------|
| **IDLE** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **LOADED** | ❌ | ✅ | ❌ | ❌ | ❌ |
| **RUNNING** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **PAUSED** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **COMPLETED** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **ERROR** | ✅ | ❌ | ❌ | ❌ | ❌ |

当前实现存在以下偏差：

1. **`canStart` (line 88-91)**: 允许从 `paused` 状态 Start，但设计文档规定 PAUSED 状态下 Start 应禁用，应使用 Resume。
   ```dart
   // 当前 (错误)
   bool get canStart => experiment!.status == ExperimentStatus.loaded ||
       experiment!.status == ExperimentStatus.paused;
   // 应为
   bool get canStart => experiment!.status == ExperimentStatus.loaded;
   ```

2. **`canLoad` (line 83-85)**: 只允许 `idle` 状态 Load，但设计文档规定 `completed` 和 `aborted` 状态也应允许重新 Load。
   ```dart
   // 当前 (错误)
   bool get canLoad => ... && (experiment!.status == ExperimentStatus.idle);
   // 应为
   bool get canLoad => ... && (experiment!.status == ExperimentStatus.idle ||
       experiment!.status == ExperimentStatus.completed ||
       experiment!.status == ExperimentStatus.aborted);
   ```

**影响**: 用户可能从PAUSED状态误触发Start而非Resume，导致状态机异常；COMPLETED/ERROR状态下无法重新加载试验。

---

### C-03: `TextEditingController` 内存泄漏

**文件**: `experiment_console_page.dart:464-522`  
**严重性**: Critical

`_buildParameterInput` 方法中，每次build都创建新的 `TextEditingController`：

```dart
controller: TextEditingController(
  text: currentValue?.toString() ?? '',
),
```

这些控制器从未被 `dispose()`，导致内存泄漏。在参数频繁更新或页面长时间运行时，泄漏会累积。

**修复建议**: 将控制器提取为 `_ExperimentConsolePageState` 的成员变量，在 `dispose()` 中释放；或使用 `TextFormField` 配合 `onSaved` 替代手动管理控制器。

---

### C-04: WebSocket 重连策略不符合设计

**文件**: `experiment_ws_client.dart:174-181`  
**严重性**: Critical

设计文档 (§7.2 重连策略) 明确要求：
- **指数退避**: 1s → 2s → 4s → 8s → 16s → 30s(上限)
- **最大重试次数**: 10次，超过后进入 `failed` 状态
- **心跳保活**: 每30秒发送ping，60秒无pong判定断开

当前实现：
```dart
void _scheduleReconnect() {
  _reconnectTimer?.cancel();
  _reconnectTimer = Timer(const Duration(seconds: 3), () { ... });
}
```

- 固定3秒间隔，无指数退避
- 无最大重试次数限制，会无限重连
- 无心跳机制
- 无 `WsConnectionState` 枚举（设计文档定义了 `disconnected/connecting/connected/reconnecting/failed` 五种状态）

**影响**: 网络不稳定时可能频繁重连消耗资源；长时间断网后无法通知用户需要手动重连；空闲连接可能因无心跳被代理/负载均衡器断开。

---

### C-05: `experimentId` 路由参数未使用

**文件**: `experiment_console_page.dart:16-18`  
**严重性**: Critical

`ExperimentConsolePage` 接收 `experimentId` 参数，但 `_setupWebSocket()` 和 `initialize()` 中从未使用该参数。设计文档 (§12 路由配置) 明确支持 `/experiments/:id/console` 路由。

当前实现是自动创建新试验，而非打开指定试验。

**影响**: 从试验列表点击"执行"导航到控制台时，无法打开对应试验。

---

## 2. Major Issues (应该修复)

### M-01: 缺少参数验证

**文件**: `experiment_console_page.dart:452-523`  
**严重性**: Major

设计文档 (§3.3 参数表单渲染规则) 要求：
- `number` 类型：必须为有效数字
- `integer` 类型：必须为整数，不含小数点
- `string` 类型：非空验证（如required）

当前实现：
- `number` 类型：`double.tryParse` 失败时静默忽略，不显示验证错误
- `integer` 类型：`int.tryParse` 失败时静默忽略，不显示验证错误
- 无 `min`/`max` 约束验证（测试数据中有 `min: -50, max: 200`）
- 无 `required` 验证
- 无字段级错误提示（设计文档要求"输入框下方红色文字"）

**修复建议**: 使用 `TextFormField` + `validator` 实现验证，或在 `onChanged` 中记录验证状态并显示错误提示。

---

### M-02: 缺少"重置为默认值"功能

**文件**: `experiment_console_page.dart`  
**严重性**: Major

设计文档 (§3.1 控制台页面布局) 明确要求参数配置区域包含 `[重置默认值]` 按钮。测试用例 TC-S2-013-FE-014 也验证此功能。

当前实现完全没有此按钮。

---

### M-03: 缺少空参数Schema提示

**文件**: `experiment_console_page.dart:386-388`  
**严重性**: Major

设计文档要求当 `parameterSchema.isEmpty` 时显示"此方法无需配置参数"。当前实现直接返回 `SizedBox.shrink()`，用户无法区分"无参数"和"参数区域未渲染"。

测试用例 TC-S2-013-FE-015 明确要求此提示。

---

### M-04: 缺少日志自动滚动功能

**文件**: `experiment_console_page.dart:526-576`  
**严重性**: Major

设计文档 (§13.1 日志窗口) 和测试用例 TC-S2-013-FE-033/034 要求：
- 新日志到达时自动滚动到底部
- 用户手动向上滚动时不自动滚动
- 显示"有新日志"提示

当前实现：
- 无 `autoScroll` 状态
- 无 `toggleAutoScroll` 方法
- 无手动滚动检测
- 无"有新日志"指示器
- `_logScrollController` 创建后从未调用 `jumpTo` 或 `animateTo`

---

### M-05: `selectMethod` 缺少状态检查

**文件**: `experiment_console_provider.dart:166-181`  
**严重性**: Major

设计文档 (§9.1 selectMethod) 要求：如果试验处于非 IDLE/COMPLETED/ABORTED 状态，应提示"请先停止当前试验再切换方法"。

当前实现直接切换方法，无任何状态检查。

**影响**: 用户可能在试验运行中切换方法，导致状态不一致。

---

### M-06: `copyWith` 的 `error` 字段无法清除

**文件**: `experiment_console_provider.dart:57-79`  
**严重性**: Major

设计文档 (§5.1) 的 `copyWith` 包含 `clearError` 标志：
```dart
error: clearError ? null : (error ?? this.error),
```

当前实现：
```dart
error: error,  // 如果传入 null，会将 error 设为 null（正确）
```

实际上当前实现中 `error` 参数默认值为 `null`（非命名参数），所以 `copyWith()` 不带 error 参数时会将 error 设为 null。这与设计文档的 `clearError` 标志行为不同——设计文档允许"保持原error不变"，而当前实现会在任何不带error的copyWith调用中清除error。

**修复建议**: 使用可区分"未传入"和"传入null"的模式，如 `Object? error = _unset`。

---

### M-07: 方法列表加载失败无处理

**文件**: `experiment_console_page.dart:197-221`  
**严重性**: Major

测试用例 TC-S2-013-FE-008 要求方法列表加载失败时显示错误提示和"重试"按钮。当前 `DropdownButtonFormField` 在 `availableMethods` 为空时显示空下拉列表，无错误提示。

---

### M-08: 空方法列表无提示

**文件**: `experiment_console_page.dart:206-211`  
**严重性**: Major

测试用例 TC-S2-013-FE-005 要求空方法列表时显示"暂无可用方法"提示和"创建方法"按钮。当前实现显示空下拉列表。

---

### M-09: WebSocket URL 构建方式不明确

**文件**: `experiment_console_page.dart:38-40`  
**严重性**: Major

`ExperimentWebSocketClient` 的 `connect` 方法接收完整 URL，但页面中 `_setupWebSocket()` 创建客户端后从未调用 `connect()`。WebSocket 连接的实际建立逻辑缺失。

```dart
void _setupWebSocket() {
  _wsClient = ExperimentWebSocketClient();
  ref.read(experimentConsoleProvider.notifier).setWebSocketClient(_wsClient!);
  // 缺少 _wsClient!.connect(url, experimentId: ...) 调用
  ...
}
```

**影响**: WebSocket 永远不会建立连接，所有实时推送功能失效。

---

### M-10: 参数表单未显示 description

**文件**: `experiment_console_page.dart:410-449`  
**严重性**: Major

设计文档 (§3.3) 和测试用例 TC-S2-013-FE-009 要求每个参数显示 `description` 作为提示文本。当前实现只显示参数 key（如 `temperature_setpoint`），不显示描述。

---

### M-11: `handleWsStatusChange` 中 `_statusLabel` 调用语法错误

**文件**: `experiment_console_provider.dart:309`  
**严重性**: Major

```dart
_addLog('info', '状态变更: ${_statusLabel(oldStatus)} -> $_statusLabel(status)');
```

`$_statusLabel(status)` 缺少花括号，应为 `${_statusLabel(status)}`。这会导致编译错误或输出字面字符串 `_statusLabel(status)`。

---

## 3. Minor Issues (建议修复)

### m-01: 缺少 DEBUG 日志级别颜色

**文件**: `experiment_console_page.dart:582-591`  
`_buildLogEntry` 只处理了 `error` 和 `warn` 级别，`debug` 级别应显示灰色（设计文档 §3.2）。

### m-02: RUNNING 状态无脉冲动画

**文件**: `experiment_console_page.dart:230-283`  
设计文档 (§3.2) 要求 RUNNING 状态带脉冲动画。当前实现为静态显示。

### m-03: 日志数量无上限

**文件**: `experiment_console_provider.dart:284-291`  
设计文档 (§13.1) 要求日志截断保留最近5000条。当前实现无限制，长时间运行会导致内存问题。

### m-04: 控制按钮无加载中指示器

**文件**: `experiment_console_page.dart:285-374`  
设计文档 (§6.2) 要求操作进行中时按钮显示 `CircularProgressIndicator`。当前实现在按钮旁边显示一个独立的 spinner，而非在按钮内部。

### m-05: 缺少状态冲突恢复逻辑

**文件**: `experiment_console_provider.dart`  
设计文档 (§10.3 状态冲突处理) 要求当API返回状态不允许错误时，调用 `GET /status` 同步后端状态。当前实现仅显示错误，不尝试同步。

### m-06: `ExperimentControlService` 接口签名与设计文档不一致

**文件**: `experiment_control_service.dart:14`  
设计文档中 `loadExperiment` 签名为 `(id, methodId, parameters)`，当前实现为 `(id, methodId)`（缺少 parameters）。

### m-07: 缺少 `reconnectWebSocket` 方法

**文件**: `experiment_console_provider.dart`  
设计文档 (§9.1) 要求 Notifier 暴露 `reconnectWebSocket()` 方法供用户手动触发重连。当前实现缺失。

### m-08: 参数输入框每次重建丢失光标位置

**文件**: `experiment_console_page.dart:464-522`  
由于 `TextEditingController` 在每次 build 时重新创建，用户输入时光标可能跳到末尾。

### m-09: 缺少国际化支持

所有用户可见文本均为硬编码中文字符串，未使用 `flutter_localizations` 或 i18n 框架。

### m-10: `ExperimentWebSocketClient` 的 StreamController 未处理 closed 状态

**文件**: `experiment_ws_client.dart:117-140`  
如果 `dispose()` 被调用后仍有事件尝试添加到已关闭的 StreamController，会抛出 `Bad state: Cannot add event after closing` 异常。

---

## 4. Positive Observations

1. **接口驱动设计**: `ExperimentControlServiceInterface` 抽象接口定义良好，便于测试和替换实现。
2. **Riverpod 使用正确**: `StateNotifierProvider` 模式使用规范，依赖注入通过 `ref.watch` 实现。
3. **Stop 确认对话框**: 实现了二次确认，防止误操作（符合 TC-S2-013-FE-025）。
4. **日志级别颜色区分**: ERROR/WARN/INFO 有不同颜色显示。
5. **时间戳格式化**: 日志条目包含格式化的时间戳。
6. **错误状态页面**: 实现了友好的错误状态和重试按钮。
7. **WebSocket 消息容错**: `_handleMessage` 中对 malformed JSON 做了 try-catch 保护。
8. **Experiment 模型完整**: `Experiment` 实体包含完整的 CRUD 操作和 `copyWith` 方法。
9. **控制操作防重复**: `isControlling` 标志防止操作进行中重复点击。

---

## 5. 架构偏离总结

| 设计文档要求 | 当前实现 | 偏离程度 |
|-------------|---------|---------|
| 独立 Widget 组件 (MethodSelector, ParameterForm, ControlButtonGroup, StatusIndicator, LogWindow) | 所有 UI 内联在单页面中 | 高 |
| `WsConnectionState` 枚举 (5种状态) | 简单 `bool wsConnected` | 高 |
| `LogLevel` 枚举 | 原始字符串 | 中 |
| `WsMessage` 基类 + 子类 | 独立的 `WsStatusChange`/`WsLogEntry` 类 | 低 |
| 指数退避重连 (1s→30s, 最大10次) | 固定3秒，无上限 | 高 |
| 心跳保活 (30s ping) | 无 | 高 |
| `clearError` 标志 | 无 | 中 |
| `autoScroll` 状态 | 无 | 中 |
| `currentOperation` 字段 | 无 | 中 |
| 参数验证 + 字段级错误 | 无 | 高 |

---

## 6. 测试用例覆盖评估

| 测试类别 | 用例数 | 当前覆盖 | 缺失 |
|---------|--------|---------|------|
| 页面布局与初始化 (FE-001~003) | 3 | 部分 | 主题适配未验证 |
| 方法选择器 (FE-004~008) | 5 | 部分 | 空列表/加载失败处理缺失 |
| 参数配置表单 (FE-009~015) | 7 | 部分 | 验证/重置/空schema提示缺失 |
| 控制按钮组 (FE-016~026) | 11 | 部分 | 按钮状态逻辑有偏差 |
| 状态显示 (FE-027~029) | 3 | 部分 | 脉冲动画/错误详情缺失 |
| 实时日志窗口 (FE-030~036) | 7 | 部分 | 自动滚动/性能优化缺失 |
| WebSocket连接管理 (FE-037~042) | 6 | 部分 | 重连策略/心跳缺失 |
| 后端API集成 (BE-001~016) | 16 | 部分 | 参数传递缺失 |
| WebSocket实时推送 (WS-001~013) | 13 | 部分 | 认证失败/心跳/重连缺失 |
| 边缘情况 (EDGE-001~016) | 16 | 部分 | 多项缺失 |
| 集成测试 (INT-001~004) | 4 | 部分 | 端到端流程不完整 |

**估计覆盖率**: ~40% (基于功能实现完整度)

---

## 7. 修复优先级建议

### P0 (阻塞合并):
1. **C-01**: 修复 `loadExperiment` 参数传递
2. **C-02**: 修正按钮状态逻辑
3. **C-03**: 修复 `TextEditingController` 内存泄漏
4. **C-05**: 实现 `experimentId` 路由参数支持
5. **M-09**: 补全 WebSocket 连接建立逻辑
6. **M-11**: 修复 `_statusLabel` 字符串插值语法错误

### P1 (合并前修复):
1. **C-04**: 实现指数退避重连 + 最大重试次数
2. **M-01**: 添加参数验证
3. **M-02**: 添加"重置为默认值"按钮
4. **M-04**: 实现日志自动滚动
5. **M-05**: 添加 `selectMethod` 状态检查
6. **M-07/M-08**: 处理方法列表空状态和加载失败

### P2 (后续迭代):
1. **m-01~m-10**: 各项 Minor 问题
2. 心跳保活机制
3. 脉冲动画
4. 日志截断 (5000条上限)
5. 状态冲突恢复逻辑
6. 国际化支持

---

**审查人签名**: sw-jerry  
**审查完成时间**: 2026-04-03
