# 详细设计评审报告 — TASK-020

> **评审对象**: `log/release_3/design/TASK-020_design.md`（v1.1，sw-tom 修正 P0-5 后）
> **评审人**: sw-jerry (Software Architect)
> **评审日期**: 2026-06-01
> **评审类型**: 二次评审（初次评审 5 个 P0 已修正）

---

## 评审结论: CHANGES_REQUESTED ⚠️

- **P0 (Critical)**: 1 — `ExperimentControlDto` 与后端 JSON 响应不匹配
- **P1 (High)**: 2 — `StatusChange` 模型字段不匹配，`getStatus` 返回类型与后端不一致
- **P2 (Medium)**: 1 — `create()` 端点可能不存在
- **P3 (Low)**: 0

---

## P0 修正验证 ✅

以下 5 个 P0 问题已正确修正（v1.0 → v1.1）：

| P0 | 内容 | 验证结果 | 证据 |
|-----|------|----------|------|
| P0-1 | 移除 `complete()`/`abort()` | ✅ 通过 | ExperimentService(§2) 无 complete/abort；ControlNotifier(§6.3.2) 无对应方法；状态矩阵(§3.1) 中 COMPLETED/ABORTED 为终态 |
| P0-2 | 状态验证矩阵对齐后端状态机 | ✅ 通过 | 矩阵(§3.1) 与后端 `experiment_control.rs` 状态转换一致：IDLE→load, LOADED→start, RUNNING→pause/stop, PAUSED→resume/stop |
| P0-3 | 列表查询参数修正为 `createdAfter`/`createdBefore` | ✅ 通过 | list() 签名(§6.1) 使用 `createdAfter`/`createdBefore`；内部实现(§6.1.1) 序列化为 `created_after`/`created_before`，匹配后端 `ListExperimentsRequest` |
| P0-4 | `StatusChangeData` 补充 `experimentId` | ✅ 通过 | §7.5(行1032) `@JsonKey(name: 'experiment_id') required String experimentId` |
| P0-5 | 统一类图控制操作返回类型为 `Future<ExperimentControlDto>` | ✅ 通过 | 类图(§2) + 接口定义(§6.1) 中 load/start/pause/resume/stop 均返回 `Future<ExperimentControlDto>` |

---

## 新发现问题

### [P0-Critical] P0-C1: `ExperimentControlDto` 字段与后端 JSON 响应完全不一致

- **位置**: §7.6 (行1060-1086)
- **描述**:

  前端设计的 `ExperimentControlDto`：
  ```dart
  class ExperimentControlDto {
    @JsonKey(name: 'experiment_id') String experimentId;  // ❌ 后端无此字段
    @JsonKey(name: 'new_status') ExperimentStatus newStatus;  // ❌ 后端字段名是 "status"
    String operation;      // ❌ 后端无此字段
    DateTime? timestamp;   // ❌ 后端无此字段
    DateTime? startedAt;   // ⚠️ 后端是 String 类型
  }
  ```

  后端实际返回的 `ExperimentControlDto`（`experiment_control/mod.rs:108`）：
  ```rust
  pub struct ExperimentControlDto {
    pub id: String,             // 试验 ID
    pub name: String,           // 试验名称
    pub status: String,         // 状态字符串 "RUNNING"/"PAUSED" 等
    pub method_id: Option<String>,
    pub description: Option<String>,
    pub started_at: Option<String>,   // ISO8601 字符串
    pub ended_at: Option<String>,
    pub created_at: String,
    pub updated_at: String,
  }
  ```

  对比：
  | 前端期望字段 | 后端实际字段 | 匹配? |
  |------------|------------|------|
  | `experiment_id` | `id` | ❌ |
  | `new_status` (enum) | `status` (String) | ❌ 字段名+类型均不匹配 |
  | `operation` | — (不存在) | ❌ |
  | `timestamp` | — (不存在) | ❌ |
  | `startedAt` (DateTime?) | `started_at` (String?) | ❌ 类型不匹配 |

  **唯一正确的字段是 `startedAt` 的 JSON key `started_at`，但类型也需要从 `DateTime` 改为 `String?`（后端是 ISO8601 字符串）。**

- **影响**: 
  - 所有控制操作（load/start/pause/resume/stop）的返回值 JSON 反序列化将**全部失败**
  - `_executeControl()` 方法中（§6.3.3 行884-892）使用 `controlDto.newStatus` 和 `controlDto.startedAt` 更新状态，由于字段不存在将产生 **运行时错误**
  - 这是 **阻塞性问题**，必须修正才能进入实现阶段

- **建议**:

  ```dart
  @JsonSerializable()
  class ExperimentControlDto {
    @JsonKey(name: 'id')
    final String id;
    final String name;
    final String status;           // 后端返回 "RUNNING" 字符串
    @JsonKey(name: 'method_id')
    final String? methodId;
    final String? description;
    @JsonKey(name: 'started_at')
    final String? startedAt;       // ISO8601 字符串
    @JsonKey(name: 'ended_at')
    final String? endedAt;
    @JsonKey(name: 'created_at')
    final String createdAt;
    @JsonKey(name: 'updated_at')
    final String updatedAt;
  }
  ```

  相应地，`_executeControl` 方法需修改：
  ```dart
  // 需要用 status 字符串匹配枚举
  final newStatus = ExperimentStatus.values.firstWhere(
    (e) => e.name.toUpperCase() == controlDto.status,
  );
  // startedAt 是 String，需要 parse
  final startedAt = controlDto.startedAt != null 
    ? DateTime.parse(controlDto.startedAt!) 
    : current.startedAt;
  ```

- **状态**: OPEN

---

### [P1-High] P1-H1: `StatusChange` 模型字段与后端 `StateChangeLogDto` 不匹配

- **位置**: §7.2 (行929-955)
- **描述**:

  前端 `StatusChange`：
  ```dart
  class StatusChange {
    ExperimentStatus oldStatus;     // 对应后端 "previous_state"
    ExperimentStatus newStatus;     // 对应后端 "new_state"
    String operation;               // ✅ 匹配
    DateTime timestamp;             // ✅ 匹配（后端 String → DateTime parse）
    String? userId;                 // 对应后端 "user_id"
    String? reason;                 // ❌ 后端无此字段，后端用 "error_message"
  }
  // ❌ 缺少 experiment_id 字段
  ```

  后端 `StateChangeLogDto`（`experiment_control/mod.rs:94`）：
  ```rust
  pub struct StateChangeLogDto {
    pub id: String,
    pub experiment_id: String,       // ← 前端模型中不存在
    pub previous_state: String,      // ← 前端用 "oldStatus"
    pub new_state: String,           // ← 前端用 "newStatus"
    pub operation: String,
    pub user_id: String,
    pub timestamp: String,
    pub error_message: Option<String>,  // ← 前端用 "reason"，错误
  }
  ```

  **关键差异**：
  - 缺少 `experiment_id` → 缺少 `@JsonKey(name: 'experiment_id')`
  - `oldStatus` 应映射 `@JsonKey(name: 'previous_state')`
  - `newStatus` 应映射 `@JsonKey(name: 'new_state')`
  - `reason` → 应改为 `errorMessage`，映射 `@JsonKey(name: 'error_message')`

- **影响**: 获取试验历史记录（`GET /api/v1/experiments/{id}/history`）时 JSON 反序列化会静默丢失字段或失败

- **建议**:
  ```dart
  @JsonSerializable()
  class StatusChange {
    @JsonKey(name: 'id')
    final String? id;
    @JsonKey(name: 'experiment_id')
    final String? experimentId;
    @JsonKey(name: 'previous_state')
    final String oldStatus;
    @JsonKey(name: 'new_state')
    final String newStatus;
    final String operation;
    @JsonKey(name: 'user_id')
    final String? userId;
    final DateTime timestamp;
    @JsonKey(name: 'error_message')
    final String? errorMessage;
  }
  ```

  或者：保持现有字段名但确保 `@JsonKey` 正确映射，并补充缺失字段。

- **状态**: OPEN

---

### [P1-High] P1-H2: `ExperimentService.getStatus()` 返回类型不完整

- **位置**: §6.1 (行480), §2 类图行73
- **描述**:

  ```dart
  Future<ExperimentStatus> getStatus(String id);
  ```

  后端 `GET /api/v1/experiments/{id}/status` 返回：
  ```rust
  pub struct ExperimentStatusDto {
    pub id: String,
    pub name: String,
    pub status: String,
    pub method_id: Option<String>,
    pub started_at: Option<String>,
    pub ended_at: Option<String>,
    pub updated_at: String,
  }
  ```

  后端返回的是 **完整 DTO**（包含 id/name/status 等），而不仅仅是 `ExperimentStatus` 枚举。返回类型应与后端 `ApiResponse<ExperimentStatusDto>` 对应。

- **影响**: 如果调用方只需要 status 字符串，该方法可以工作（只需从响应中提取 `.status`），但如果需要其他字段则会丢失信息。

- **建议**: 两种方案：
  - A) 改为返回完整 DTO：`Future<_ExperimentStatusDto> getStatus(String id)`，新增一个 DTO 类
  - B) 当前实现内部处理：从完整响应中提取 status 并映射为枚举（低级处理）

  推荐 A，保持与后端 API 完全对应。

- **状态**: OPEN

---

### [P2-Medium] P2-M1: `create()` 对应的后端端点可能存在

- **位置**: §6.1 行462, §2 类图行67
- **描述**:

  ```dart
  Future<Experiment> create(CreateExperimentRequest request);
  ```

  后端路由中没有 `POST /api/v1/experiments` 端点。现有的实验列表 GET 端点来自 `ExperimentQueryService`，控制端点来自 `ExperimentControlService`，数据端点来自 `ExperimentDataService`。**未发现创建实验的 POST 路由**。

  如果这是前端主动需求但后端未提供，则此方法将永远返回 404。

- **影响**: 如果 `POST /api/v1/experiments` 确实不存在，调用 `create()` 将失败

- **建议**: 
  1. 确认后端是否有创建实验的端点（可能在 `POST /api/v1/experiments` 或通过工作台创建）
  2. 如果不存在，暂时移除此方法或标记为 `[PENDING-BACKEND]`
  3. 如果实验是通过其他机制创建（如工作台操作），更新设计文档说明

- **状态**: OPEN

---

## 架构一致性检查

| 检查项 | 结果 | 说明 |
|--------|------|------|
| 遵循 arch.md 分层架构 | ✅ | Service → Provider → UI 清晰分层 |
| 接口先于实现定义 | ✅ | WsService/ExperimentService 接口明确 |
| DDD 聚合根 | ✅ | Experiment 作为聚合根，ExperimentControlNotifier 管理其生命周期 |
| SOLID 原则 | ✅ | SRP 职责分离，DIP 通过构造注入 |
| 与现有代码模式一致 | ✅ | AsyncNotifierProvider、AutoDispose、命名参数等与现有模式一致 |
| WebSocket 重连策略 | ✅ | 指数退避 1/2/4/8/8，最多 5 次，设计合理 |

---

## WebSocket 相关验证

| 检查项 | 结果 | 说明 |
|--------|------|------|
| WS 端点 `ws://host/ws/experiments/{id}` | ✅ | 匹配后端 `routes.rs:417` |
| token 查询参数传递 | ✅ | 后端 WS handler 通过查询参数接收 |
| 消息 type 字段解析 | ✅ | `status_change` / `error` 解析逻辑正确 |
| 重连重试上限为 5 次 | ✅ | `maxReconnectAttempts = 5` |
| dispose 时自动清理 | ✅ | `ref.onDispose()` + `disconnect()` |
| cancelOnError: false | ✅ | 防止单条消息错误导致流关闭 |

---

## 总结

**5 个 P0 修正全部验证通过。** sw-tom 的修正准确、完整。

但在二次评审中发现了 **1 个 P0 Critical + 2 个 P1 High + 1 个 P2 Medium** 新问题，最严重的是 P0-C1（`ExperimentControlDto` 与后端 JSON 完全不匹配），必须修正后才能进入实现阶段。

### 必须修正才能 APPROVED

- **P0-C1** (Blocker): `ExperimentControlDto` 字段对齐后端 `ExperimentControlDto`

### 建议修正

- **P1-H1**: `StatusChange` 字段对齐后端 `StateChangeLogDto`
- **P1-H2**: `getStatus()` 返回类型对齐后端 `ExperimentStatusDto`
- **P2-M1**: 确认 `create()` 端点存在性

---

## 二次评审结论

结论: ❌ CHANGES_REQUESTED — P0-C1 为阻塞性问题，修正后可 APPROVED
