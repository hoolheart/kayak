# TASK-020 详细设计评审报告

**评审人**: sw-jerry (Software Architect)
**日期**: 2026-06-01
**设计文件**: `log/release_3/design/TASK-020_design.md`
**结论**: 🔴 NEEDS_REVISION

---

## 评审摘要

| 类别 | 通过 | 需修改 | 严重 |
|------|:--:|:-----:|:---:|
| 架构合规 | 6 | 1 | 0 |
| 技术正确性 | 8 | 2 | 5 |
| 完整性 | 3 | 1 | 0 |
| **总计** | **17** | **4** | **5** |

**5 项严重问题**必须全部修复后方可进入实现阶段。

---

## 1. 架构合规性评审

### 1.1 ExperimentService 与 DeviceService 模式一致性 ✅

**通过**。设计遵循了 `DeviceService(ApiClient)` 的构造函数注入模式，`ApiResponse<T>.fromJson()` 解析模式，命名参数风格。第 9.1 节的一致性对比表准确。

**但有一处偏差需要确认**：控制操作返回 `ExperimentControlDto` 而非 `void`（DeviceService 的 `connect()`/`disconnect()` 返回 void）。这在 9.2 节有明确理由说明，设计决策合理。

### 1.2 ExperimentProvider 与 Riverpod 3.x 模式一致性 ✅

**通过**。`ExperimentListNotifier` 使用 `AutoDisposeAsyncNotifier<List<Experiment>>`，`ExperimentControlNotifier` 使用 `AutoDisposeAsyncNotifier.family<Experiment, String>`，与现有 `DeviceTreeNotifier`/`DeviceDetailNotifier` 模式完全一致。

`_isOperationInProgress` 防重复提交、`_mapError()` 错误映射、`state = AsyncLoading` → `state = AsyncData(...)` 的更新模式均与 `DeviceDetailNotifier` 一致。

### 1.3 WsService 独立生命周期设计 ✅

**通过**。WebSocket 是长连接，需要独立于 HTTP Service 的生命周期管理，单独抽取为 `WsService` 是合理的设计决策。`ConnectionState` 枚举（disconnected/connecting/connected/reconnecting/failed）完整覆盖所有连接场景。

### 1.4 数据流单向性 ✅

**通过**。数据流为 `Backend API → ExperimentService/WsService → Provider → UI`，方向单向。Widget 通过 `ref.watch(provider)` 读取状态，通过 `ref.read(provider.notifier)` 触发操作，符合 Riverpod 规范。

### 1.5 依赖注入设计 ✅

**通过**。`experimentServiceProvider` 注入 `apiClientProvider`，`wsServiceProvider` 作为无状态单例，均可通过 `overrideWithValue` 在测试中替换，可测试性良好。

### 1.6 ExperimentMessage 使用 Sealed Class + freezed ✅

**通过**。`@Freezed(unionKey: 'type')` 实现的 tagged union 模式，支持 `when`/`map` 模式匹配，类型安全且可扩展。

### 1.7 Provider 注册位置

**⚠️ 建议关注**：设计将 `experimentServiceProvider` 和 `wsServiceProvider` 注册在 `lib/providers/services.dart` 中。当前 `services.dart` 包含所有全局 Service Provider。如果后续 ExperimentService 本身需要额外的 Provider（如缓存、分页状态），建议考虑是否该 Provider 更适合放在 `experiment_provider.dart` 中。当前设计可行，但需保持一致。

---

## 2. 技术正确性评审

### 🔴 严重问题 1：`complete()` 和 `abort()` 端点在后端不存在

**位置**: Section 6.1 ExperimentService 第 492-497 行，Section 6.3.2 ExperimentControlNotifier，Section 3.1 验证矩阵

**详情**: 后端 `experiment_control_routes`（`routes.rs` 第 336-357 行）仅注册了以下端点：
- `POST /experiments/:id/load`
- `POST /experiments/:id/start`
- `POST /experiments/:id/pause`
- `POST /experiments/:id/resume`
- `POST /experiments/:id/stop`
- `GET /experiments/:id/status`
- `GET /experiments/:id/history`

**不存在** `complete` 和 `abort` 端点。PRD 附录 B 也未列出这两条端点。

**影响**:
- `ExperimentService.complete()` 和 `ExperimentService.abort()` 将调用不存在的端点
- `ExperimentControlNotifier.complete()` 和 `ExperimentControlNotifier.abort()` 无法工作
- 状态验证矩阵中 COMPLETED/ABORTED 终态的校验逻辑无后端支撑
- 测试用例 TC-EXP-019a、TC-EXP-019b、TC-PROV-016a、TC-PROV-016b 全部无法通过

**建议**: 
1. **方案 A（推荐）**：从设计中移除 `complete()` 和 `abort()` 方法，状态机只保留 `load/start/pause/resume/stop` 五个操作。COMPLETED 和 ABORTED 状态仅在列表/详情中作为只读状态展示（由后端直接设置）。
2. **方案 B**：如需保留 `complete`/`abort`，必须先在 Release 3 中向后端添加这两个端点。但这与 PRD "后端不做任何修改"的约束冲突。

### 🔴 严重问题 2：状态验证矩阵与后端状态机不一致

**位置**: Section 3.1 状态合法性校验矩阵

**详情**: 设计的校验矩阵与后端 `state_machine.rs` 的实际规则存在以下冲突：

| 行 | 设计矩阵 | 后端实际 | 差异 |
|-----|---------|---------|------|
| LOADED → load | ✅（重新载入不同方法） | ❌ | **后端仅允许 Idle→Loaded** |
| LOADED → abort | ✅ | ❌ | 后端仅允许 Running/Paused→Aborted |
| IDLE → abort | ✅ | ❌ | 后端仅允许 Running/Paused→Aborted |

后端 `StateMachine::transition()` 中：
- `Load` 仅匹配 `(Idle, Load) → Loaded`
- `Abort` 仅匹配 `(Running, Abort) | (Paused, Abort) → Aborted`
- `Complete` 仅匹配 `(Running, Complete) → Completed`

**影响**: 前端的 `_validateStateTransition()` 放行后端不允许的操作 → 用户操作后收到后端 400 错误 → 用户体验不一致。

**建议**: 将验证矩阵完全对齐后端（如果最终保留 abort/complete 后再更新；如果移除则同步删除相关行）。修正后的矩阵应为：

```
| 当前状态 \ 操作 | load | start | pause | resume | stop |
|-----------------|:----:|:-----:|:-----:|:------:|:----:|
| IDLE            |  ✅  |  ❌   |  ❌   |   ❌   |  ❌  |
| LOADED          |  ❌  |  ✅   |  ❌   |   ❌   |  ❌  |
| RUNNING         |  ❌  |  ❌   |  ✅   |   ❌   |  ✅  |
| PAUSED          |  ❌  |  ❌   |  ❌   |   ✅   |  ✅  |
| COMPLETED       |  ❌  |  ❌   |  ❌   |   ❌   |  ❌  |
| ABORTED         |  ❌  |  ❌   |  ❌   |   ❌   |  ❌  |
```

### 🔴 严重问题 3：列表查询参数与后端 API 不匹配

**位置**: Section 6.1 ExperimentService.list() 方法签名

**详情**: 后端 `ListExperimentsRequest`（`experiment_query.rs`）支持以下查询参数：
- `created_after`, `created_before` — 基于**创建时间**过滤
- `page`, `size` — 分页
- `status` — 状态筛选（单值，UPPERCASE）
- `scope` — 作用域（personal/team/all）

**不支持的参数**：
- ❌ `started_after`/`ended_before` — 后端无此参数，使用 `created_after`/`created_before`
- ❌ `search` — 后端无搜索关键词参数

设计中使用了 `startedAfter`/`endedBefore` 和 `search`，与后端 API 不匹配。

**此外**：后端默认 `page_size` 是 **10**（`params.size.unwrap_or(10)`），设计中使用 20。建议前端使用与后端一致的默认值。

**建议**:
1. 将 `startedAfter` → `createdAfter`，`endedBefore` → `createdBefore`
2. 移除 `search` 参数（或确认后端是否计划支持）
3. 将默认 `size` 从 20 调整为与后端一致的 10

### 🔴 严重问题 4：WebSocket StatusChangeData 缺少 `experiment_id` 字段

**位置**: Section 7.5 StatusChangeData 类定义

**详情**: 后端 `WsMessage::StatusChange` 包含以下字段：
```rust
StatusChange {
    experiment_id: Uuid,
    old_status: String,
    new_status: String,
    operation: String,
    user_id: Uuid,
    timestamp: String,
}
```

序列化为 tagged union：`{"type":"status_change","data":{"experiment_id":"...","old_status":"...","new_status":"...","operation":"...","user_id":"...","timestamp":"..."}}`

但设计中的 `StatusChangeData` **缺少 `experiment_id` 字段**。

**影响**: JSON 反序列化时 `experiment_id` 字段被忽略，信息丢失。客户端无法通过消息自身验证该消息是否属于当前试验。

**建议**: 在 `StatusChangeData` 中补充 `experiment_id` 字段：
```dart
@Freezed()
class StatusChangeData with _$StatusChangeData {
  const factory StatusChangeData({
    @JsonKey(name: 'experiment_id') required String experimentId,
    @JsonKey(name: 'old_status') required ExperimentStatus oldStatus,
    @JsonKey(name: 'new_status') required ExperimentStatus newStatus,
    required String operation,
    required DateTime timestamp,
    @JsonKey(name: 'user_id') String? userId,
  }) = _StatusChangeData;
  // ...
}
```

### 🔴 严重问题 5：ExperimentService 控制操作返回类型不一致

**位置**: Section 6.1 ExperimentService 类图 vs 6.1.1 实现示例

**详情**: 
- 类图中控制方法返回 `Future<void>`（第 67-74 行）
- 内部实现代码返回 `ExperimentControlDto`（第 554-564 行）
- 类图中 `_executeControl` 的 call 参数类型为 `Future<ExperimentControlDto> Function()`（第 895 行）

后端所有控制端点（load/start/pause/resume/stop）都返回 `ApiResponse<ExperimentControlDto>`，因此 Service 应正确返回 DTO 以传递后端返回的状态信息。

同时，第 9.2 节的差异表声称"控制操作返回 DTO 而非 void"作为设计理由，但类图中仍标注为 `void`，矛盾需统一。

**建议**: 统一类图中的返回类型，所有控制操作（load/start/pause/resume/stop）返回 `Future<ExperimentControlDto>`。

### 中等问题 1：ExperimentListNotifier 未使用 AutoDisposeAsyncNotifier

**位置**: Section 6.3.1

**详情**: 类图（第 161 行）标注 `ExperimentListNotifier --|> AutoDisposeAsyncNotifier`，但 Section 5.2 的 Provider 定义写的是：
```dart
final experimentListProvider = AsyncNotifierProvider<
  AutoDisposeAsyncNotifier<List<Experiment>>,
  List<Experiment>
>(
  ExperimentListNotifier.new,
);
```

这里 `AutoDisposeAsyncNotifier` 出现在 `AsyncNotifierProvider` 的类型参数中但 Notifier 类 extends `AutoDisposeAsyncNotifier`。需要确认 Riverpod 3.x 的正确写法——`AsyncNotifierProvider` 期望 notifier 继承 `AsyncNotifier`，而非 `AutoDisposeAsyncNotifier`。要么使用 `AutoDisposeAsyncNotifierProvider`，要么 Notifier 继承 `AsyncNotifier`（不自动 dispose）。

**建议**: 确认 `ExperimentListNotifier` 是否应使用 `AsyncNotifier`（无 autoDispose，因为列表 Provider 生命周期与路由无关）或 `AutoDisposeAsyncNotifierProvider`。对比现有 `DeviceTreeNotifier` 使用 `AsyncNotifier`。

### 中等问题 2：WebSocket Token 作为查询参数传递的安全考量

**位置**: Section 6.2.1 第 687-688 行

**详情**: 设计通过 URL 查询参数传递 JWT Token：
```dart
final uri = Uri.parse('ws://localhost:8080/ws/experiments/$experimentId')
    .replace(queryParameters: {'token': token});
```

但后端 `experiment_ws.rs` 使用的是 `RequireAuth` 提取器从 HTTP Authorization header 提取 Token，而不是从查询参数。WebSocket 升级请求的 header 在握手阶段可用。

**建议**: 
1. 确认后端 WebSocket 是否实际通过查询参数接收 Token（检查 `RequireAuth` 在 WS handler 中的行为）
2. 如果后端通过 Header 认证，WebSocket 连接时不应在 URL 中拼 Token
3. 如果后端确实通过查询参数，则当前设计正确但需要文档化该决策

### 轻微问题 1：`_onDone()` 中重连计数器递增时机

**位置**: Section 6.2.1 第 747-764 行

**详情**: `_onDone()` 中先递增 `reconnectAttempts`（第 757 行），再检查是否 `>= maxReconnectAttempts`（第 751 行）。首次连接失败时计数器从 0→1，这意味着：
- 首次连接失败 = attempt 1
- 第 1 次重连失败 = attempt 2 → delay = pow(2, 1) = 2s ❌（应该是 1s）
- ...

`_nextReconnectDelay()` 使用 `pow(2, _reconnectAttempts - 1)`，但首次失败后 `_reconnectAttempts=1`，算出的 delay = pow(2, 0) = 1s ✅。这其实是正确的！

但 `_tryConnect()` 第 683 行判断 `_reconnectAttempts > 0` 来区分 `reconnecting` 和 `connecting` 状态，这里逻辑正确。

仔细验证：
- 首次 connect → `_tryConnect` → `_reconnectAttempts=0` → state=connecting ✅
- 首次失败 → `_onDone` → `_reconnectAttempts=1` → delay=pow(2,0)=1s ✅
- 重连1 → `_tryConnect` → `_reconnectAttempts=1>0` → state=reconnecting ✅
- 重连1失败 → `_onDone` → `_reconnectAttempts=2` → delay=pow(2,1)=2s ✅
- 重连2失败 → `_onDone` → `_reconnectAttempts=3` → delay=pow(2,2)=4s ✅
- 重连3失败 → `_onDone` → `_reconnectAttempts=4` → delay=pow(2,3)=8s ✅
- 重连4失败 → `_onDone` → `_reconnectAttempts=5` → delay=pow(2,4)=16s→capped=8s ✅
- 重连5失败 → `_onDone` → `_reconnectAttempts=6` >= 5 → state=failed ❌

问题在于：当 `_reconnectAttempts=5` 时，重连到上限（5次），不应该再尝试第5次重连。修正：在第 751 行检查 `reconnectAttempts >= maxReconnectAttempts` 应在递增**之前**，或者改为 `> maxReconnectAttempts`。

当前逻辑：首次失败后 `reconnectAttempts=1`，进入重连循环；在第5次 `_onDone` 时 `reconnectAttempts` 从5→6，然后检查 `>= 5` → 进入 failed。但此时**已经执行了5次重连**（attempts 1-5各一次），符合"最多5次重连"的需求。

**结论**：此问题实际不存在。重连次数逻辑正确。将此项降为已确认无问题。

---

## 3. 完整性评审

### 3.1 测试用例覆盖 ✅

**通过**。设计覆盖了 87 个测试用例的核心需求（ExperimentService 30 + WsService 21 + Provider 33 + 集成 3），服务的每个方法、Provider 的每个状态、WebSocket 的每个场景都有对应设计。

### 3.2 数据模型完整性 ✅

**通过**。6 个新增模型（`CreateExperimentRequest`, `StatusChange`, `DataQueryParams`, `TimeSeriesData`, `ExperimentMessage`, `ExperimentControlDto`）定义完整，包含 `@JsonSerializable`/`@Freezed` 注解和序列化配置。

### 3.3 依赖关系清晰 ✅

**通过**。Section 8 的依赖图清晰，现有代码复用列表完整，`services.dart` 新增注册代码明确。

### 3.4 WebSocket URL 构建 ℹ️

**信息**：WebSocket URL 硬编码为 `ws://localhost:8080`。在生产部署中需要使用与 HTTP API 相同的 Base URL 构建。建议 WsService 接收一个 `baseUrl` 或从配置中读取主机名，而非硬编码 `localhost`。当前开发阶段可接受。

---

## 4. 附加建议

### 4.1 考虑使用 `BehaviorSubject` 替代裸 `StreamController` 存放连接状态

设计使用 `BehaviorSubject<ConnectionState>`（第 607 行），这是好的实践——新订阅者可以立即获取当前状态。当前 `web_socket_channel` 包不直接暴露 RxDart。建议确认项目是否已依赖 `rxdart`，或使用 `StreamController.broadcast()` + 手动缓存最新值。

### 4.2 `experimentWsProvider` 的 `ref.onDispose` 与多个 Widget 同时 watch 的场景

当多个 Widget 同时 watch `experimentWsProvider('exp-123')` 时，Riverpod 的 autoDispose 机制会在**所有**订阅者都 dispose 后才触发 `ref.onDispose`。这意味着如果 ExperimentConsolePage 离开后立即重新进入（在 autoDispose 延迟内），不会重复断开/重连。当前设计依赖于此行为，应确认 autoDispose 延迟是否符合预期。

### 4.3 `ExperimentControlNotifier._executeControl` 错误恢复不完整

Section 6.3.3 的 `_executeControl` 在失败后将状态设为 `AsyncError`，但未恢复 `experiment.status`。如果在 `AsyncError` 状态下 UI 需要展示当前状态标签，`state.valueOrNull?.status` 仍为操作前状态（因为 `state = AsyncError(...)` 覆盖了 `AsyncData`）。这是正确的行为，因为操作失败不应改变本地状态。但需要确认 UI 从 `AsyncError` 中能正确提取之前的实验数据。

---

## 5. 审批结论

🔴 **NEEDS_REVISION** — 5 项严重问题必须修复后方可通过。

### 必须修复（P0 - 阻塞实现）：

| # | 问题 | 严重程度 |
|---|------|:------:|
| 1 | 移除 `complete()`/`abort()` 或在后端实现对应端点 | 🔴 |
| 2 | 状态验证矩阵对齐后端状态机 | 🔴 |
| 3 | 列表查询参数对齐后端 API（`created_after`/`created_before`，移除 `search`） | 🔴 |
| 4 | `StatusChangeData` 补充 `experiment_id` 字段 | 🔴 |
| 5 | 统一控制操作返回类型为 `ExperimentControlDto` | 🔴 |

### 建议修复（P1）：

| # | 问题 |
|---|------|
| 6 | 确认 Riverpod Provider 类型声明（AutoDispose vs 非 AutoDispose） |
| 7 | 确认 WebSocket Token 传递方式与后端一致 |

### 评审人签字

**sw-jerry**  
Software Architect  
2026-06-01

---

## 6. 终审结论（v2.0 设计再审）

**终审人**: sw-jerry (Software Architect)  
**终审日期**: 2026-06-01  
**被审版本**: v2.0  

### P0-C1 专项验证：ExperimentControlDto 对齐后端实际返回格式

已验证后端 `ExperimentControlDto`（`mod.rs:108-118`）与设计 v2.0 第 7.6 节定义：

| 后端字段 | 后端类型 | 设计字段 | 设计类型 | 状态 |
|---------|---------|---------|---------|:--:|
| `id` | `String` | `id` | `String` | ✅ |
| `name` | `String` | `name` | `String` | ✅ |
| `status` | `String` | `status` | `String` | ✅ |
| `method_id` | `Option<String>` | `methodId` | `String?` | ✅ |
| `description` | `Option<String>` | `description` | `String?` | ✅ |
| `started_at` | `Option<String>` | `startedAt` | `String?` | ✅ |
| `ended_at` | `Option<String>` | `endedAt` | `String?` | ✅ |
| `created_at` | `String` | `createdAt` | `String` | ✅ |
| `updated_at` | `String` | `updatedAt` | `String` | ✅ |

同时验证了：

- **`ExperimentStatusDto`**: 7 个字段全部对齐（id/name/status/methodId/startedAt/endedAt/updatedAt）✅
- **`StatusChange`** (← `StateChangeLogDto`): 8 个字段全部对齐（含 `experimentId`）✅
- **WebSocket `StatusChangeData`** (← `WsMessage::StatusChange`): 6 个字段全部对齐（含 `experimentId`）✅
- **WebSocket `WsErrorData`** (← `WsMessage::Error`): 3 个字段全部对齐 ✅
- **API 响应封装**: 所有端点均正确使用 `ApiResponse<T>.fromJson()` 解析（`data` 字段为对应 DTO）✅
- **JSON tagged union 格式**: `serde(tag="type", content="data")` ↔ freezed `@Freezed(unionKey: 'type')` 对应正确 ✅

### P0 问题闭环确认

| # | 原始 P0 问题 | v2.0 状态 | 验证依据 |
|---|-------------|:------:|---------|
| P0-1 | 移除 `complete()`/`abort()` | ✅ 已关闭 | 设计全文无 `complete`/`abort` 方法 |
| P0-2 | 验证矩阵对齐后端 | ✅ 已关闭 | Section 3.1 矩阵与 `state_machine.rs` 完全一致 |
| P0-3 | 查询参数对齐后端 | ✅ 已关闭 | `createdAfter`/`createdBefore`，`size=10`，无 `search` |
| P0-4 | `StatusChangeData` 补充 `experimentId` | ✅ 已关闭 | Section 7.5 lines 1178-1179 包含 `experimentId` |
| P0-5 | 控制操作返回类型统一 | ✅ 已关闭 | 类图 + 实现代码统一返回 `ExperimentControlDto` |

### 终审结论

结论: ✅ **APPROVED**

设计 v2.0 已完全对齐后端 API 的实际返回格式，所有 5 项 P0 问题已修复并验证通过。ExperimentControlDto 与后端 9 个字段一一对应，ExperimentStatusDto、StatusChange、WebSocket 消息格式均与后端源代码一致。

**遗留关注项（实现阶段处理，不阻塞设计审批）**：

| 项 | 描述 | 优先级 |
|----|------|:----:|
| WS-TOKEN | WebSocket Token 通过 query parameter 传递，但后端认证中间件仅从 `Authorization` header 提取（`BearerTokenExtractor`）。Flutter Web 浏览器 WebSocket API 无法设置自定义 header，需在后端 WS 路由中添加 query parameter token 支持或在 WS handler 内手动解析 token | P1 |
| WS-URL | WebSocket URL 硬编码 `ws://localhost:8080`，生产部署需使用可配置的 Base URL | P2 |
| FORMAT | Section 6.1.1 中 `getHistory` / `load` 方法的代码片段缺少 `` ```dart `` 开启标记（Markdown 渲染问题，不影响设计内容） | P3 |

后两项已在原始评审中记录，不再重复展开。

### 终审签字

**sw-jerry**  
Software Architect  
2026-06-01
