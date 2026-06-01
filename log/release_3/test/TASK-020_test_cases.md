# TASK-020 测试用例文档

> **任务**: 试验 Service + Provider（含 WebSocket）
> **测试者**: sw-mike
> **日期**: 2026-06-01
> **版本**: 1.0

---

## 目录

1. [测试范围与目标](#1-测试范围与目标)
2. [测试环境](#2-测试环境)
3. [ExperimentService 测试用例](#3-experimentservice-测试用例)
4. [WsService 测试用例](#4-wsservice-测试用例)
5. [ExperimentProvider 测试用例](#5-experimentprovider-测试用例)
6. [集成测试用例](#6-集成测试用例)
7. [测试覆盖矩阵](#7-测试覆盖矩阵)
8. [Mock 规范](#8-mock-规范)

---

## 1. 测试范围与目标

### 测试组件

| 组件 | 文件路径 | 类型 |
|------|----------|------|
| ExperimentService | `lib/services/experiment_service.dart` | Service |
| WsService | `lib/services/ws_service.dart` | Service |
| ExperimentListNotifier | `lib/providers/experiment_provider.dart` | AsyncNotifier |
| ExperimentControlNotifier | `lib/providers/experiment_provider.dart` | AsyncNotifier |
| ExperimentWsProvider | `lib/providers/experiment_provider.dart` | StreamProvider |

### 测试目标

- 验证试验 CRUD 和控制操作的正确性
- 验证 WebSocket 连接/断开/重连的可靠性
- 验证 Riverpod Provider 的状态管理正确性
- 验证异步流程和时序敏感代码的稳定性
- 所有测试在 mock 环境下可重复执行

---

## 2. 测试环境

### 依赖版本

| 依赖 | 版本 |
|------|------|
| flutter_riverpod | ^3.3.1 |
| web_socket_channel | ^3.0.3 |
| dio | ^5.9.2 |
| mocktail | latest |
| flutter_test | SDK |

### Mock 对象

- `MockDio` — Dio HTTP 客户端
- `MockWebSocketChannel` — WebSocket 通道
- `MockWebSocketSink` — WebSocket sink
- `MockStream` — WebSocket 消息流
- `MockExperimentService` — ExperimentService（Provider 测试中隔离）
- `MockWsService` — WsService（Provider 测试中隔离）

### ExperimentStatus 枚举定义

```dart
enum ExperimentStatus {
  idle,      // 空闲
  loaded,    // 已载入
  running,   // 运行中
  paused,    // 已暂停
  completed, // 已完成
  aborted,   // 已中止
}
```

> **注意**：后端无 `error` 状态，异常终止使用 `aborted`。

---

## 3. ExperimentService 测试用例

### 3.1 列表加载

#### TC-EXP-001: 列表加载 — 正常数据
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 已配置
  - 后端返回 200 + 包含 3 条试验记录的 PaginatedResponse
- **测试步骤**:
  1. 调用 `experimentService.list()`
  2. 等待 Future 完成
- **预期结果**:
  - 返回 PaginatedResponse<Experiment>
  - `items` 长度为 3
  - 每个 Experiment 的 id/name/method/status 字段正确解析
  - `page=1`, `size=20`（默认值）

#### TC-EXP-002: 列表加载 — 空数据
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + 空列表 `{"items": [], "total": 0, "page": 1, "size": 20, "has_next": false, "has_prev": false}`
- **测试步骤**:
  1. 调用 `experimentService.list()`
  2. 等待 Future 完成
- **预期结果**:
  - 返回 PaginatedResponse<Experiment>
  - `items` 为空列表 `[]`
  - `total=0`
  - `has_next=false`, `has_prev=false`

#### TC-EXP-003: 列表加载 — 分页参数
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 已配置
- **测试步骤**:
  1. 调用 `experimentService.list(page: 2, size: 10)`
  2. 验证 Dio 请求的 queryParameters
- **预期结果**:
  - HTTP 请求包含 `page=2&size=10`
  - 响应包含 `has_next` 和 `has_prev` 字段
  - 返回对应分页数据

#### TC-EXP-004: 列表加载 — 状态筛选
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 已配置
- **测试步骤**:
  1. 调用 `experimentService.list(status: ExperimentStatus.running)`
  2. 验证 Dio 请求参数
- **预期结果**:
  - HTTP 请求包含 `status=RUNNING`
  - 返回的试验记录状态均为 RUNNING

#### TC-EXP-005: 列表加载 — 时间范围筛选
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 已配置
- **测试步骤**:
  1. 调用 `experimentService.list(createdAfter: DateTime(2026, 1, 1), createdBefore: DateTime(2026, 1, 31))`
- **预期结果**:
  - HTTP 请求包含 `created_after=2026-01-01T00:00:00.000Z` 和 `created_before=2026-01-31T23:59:59.999Z`（ISO 8601 格式）

#### TC-EXP-006: 列表加载 — 综合筛选 + 分页
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 已配置
- **测试步骤**:
  1. 调用 `experimentService.list(scope: 'personal', status: ExperimentStatus.completed, createdAfter: d1, createdBefore: d2, page: 3, size: 5)`
- **预期结果**:
  - 所有参数正确编码到 query string
  - 返回正确的分页数据

#### TC-EXP-007: 列表加载 — 网络错误
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 抛出 `DioException` (connectionError)
- **测试步骤**:
  1. 调用 `experimentService.list()`
- **预期结果**:
  - 抛出异常（或被 ErrorInterceptor 包装为用户可读错误）
  - 不返回 null

#### TC-EXP-008: 列表加载 — 服务器 500 错误
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 500
- **测试步骤**:
  1. 调用 `experimentService.list()`
- **预期结果**:
  - 抛出包含服务器错误消息的异常

#### TC-EXP-009: 列表加载 — 服务器 401 未授权
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 401
- **测试步骤**:
  1. 调用 `experimentService.list()`
- **预期结果**:
  - 抛出异常
  - AuthInterceptor 应触发 Token 刷新流程（已在 TASK-003 中测试）

### 3.2 单个试验查询

#### TC-EXP-010: 根据 ID 获取试验 — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + 单个试验 JSON
- **测试步骤**:
  1. 调用 `experimentService.getById('exp-123')`
- **预期结果**:
  - 返回 Experiment 对象
  - `id='exp-123'`
  - 所有字段正确解析

#### TC-EXP-011: 根据 ID 获取试验 — 不存在
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 404
- **测试步骤**:
  1. 调用 `experimentService.getById('nonexistent')`
- **预期结果**:
  - 抛出异常，包含 "Not found" 类消息

### 3.3 创建试验

#### TC-EXP-012: 创建试验 — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 201 + 新创建的试验 JSON
- **测试步骤**:
  1. 调用 `experimentService.create(CreateExperimentRequest(name: 'Temperature Test', methodId: 'm-1', description: 'Optional description'))`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments`
  - Request body 包含 `name`、`method_id`、`description`，不含 `workbenchId`、`parameters`
  - 返回新创建的 Experiment（含 id、user_id）

#### TC-EXP-013: 创建试验 — 参数验证失败
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 422（验证错误）
- **测试步骤**:
  1. 调用 `experimentService.create(params)`
- **预期结果**:
  - 抛出异常，包含验证错误详情

#### TC-EXP-014: 创建试验 — 方法不存在
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 409（冲突）
- **测试步骤**:
  1. 调用 `experimentService.create(CreateExperimentRequest(name: 'Test', methodId: 'nonexistent'))`
- **预期结果**:
  - 抛出异常，包含冲突原因（方法不存在）

### 3.4 控制操作

#### TC-EXP-015: 载入试验 (load) — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 ExperimentControlDto JSON
  - 响应中 `status` = `"LOADED"`, `method_id` = `"m-1"`
- **测试步骤**:
  1. 调用 `experimentService.load('exp-123', methodId: 'm-1')`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments/exp-123/load`
  - Request body 包含 `{"method_id": "m-1"}`
  - 返回 `ExperimentControlDto`（非 void）
  - DTO 的 `status` 字段为 `"LOADED"`，`methodId` 为 `"m-1"`

#### TC-EXP-016: 开始试验 (start) — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 ExperimentControlDto JSON
  - 响应中 `status` = `"RUNNING"`, `started_at` 不为 null
- **测试步骤**:
  1. 调用 `experimentService.start('exp-123')`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments/exp-123/start`
  - 返回 `ExperimentControlDto`
  - DTO 的 `status` 字段为 `"RUNNING"`

#### TC-EXP-017: 暂停试验 (pause) — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 ExperimentControlDto JSON
  - 响应中 `status` = `"PAUSED"`
- **测试步骤**:
  1. 调用 `experimentService.pause('exp-123')`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments/exp-123/pause`
  - 返回 `ExperimentControlDto`
  - DTO 的 `status` 字段为 `"PAUSED"`

#### TC-EXP-018: 继续试验 (resume) — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 ExperimentControlDto JSON
  - 响应中 `status` = `"RUNNING"`
- **测试步骤**:
  1. 调用 `experimentService.resume('exp-123')`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments/exp-123/resume`
  - 返回 `ExperimentControlDto`
  - DTO 的 `status` 字段为 `"RUNNING"`

#### TC-EXP-019: 停止试验 (stop) — 成功（回到 LOADED）
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 ExperimentControlDto JSON
  - 响应中 `status` = `"LOADED"`
- **测试步骤**:
  1. 调用 `experimentService.stop('exp-123')`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments/exp-123/stop`
  - 返回 `ExperimentControlDto`
  - DTO 的 `status` 字段为 `"LOADED"`（后端状态变为 LOADED）

#### TC-EXP-020: 控制操作 — 试验不存在
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 404
- **测试步骤**:
  1. 调用 `experimentService.start('nonexistent')`
- **预期结果**:
  - 抛出异常，包含 "Experiment not found"

#### TC-EXP-021: 控制操作 — 状态不允许
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 HTTP 400（InvalidTransition / OperationNotAllowed）
  - 注意：后端映射 `ExperimentControlError::InvalidTransition` 和 `OperationNotAllowed` 均为 `BadRequest`（400），非 409
- **测试步骤**:
  1. 调用 `experimentService.start('exp-idle')`（试验已在运行状态）
- **预期结果**:
  - 抛出异常，包含状态不允许信息（400 Bad Request）

#### TC-EXP-022: 控制操作 — 网络超时
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 抛出 timeout DioException
- **测试步骤**:
  1. 调用 `experimentService.start('exp-123')`
- **预期结果**:
  - 抛出超时异常

### 3.5 状态查询

#### TC-EXP-023: 获取试验状态 — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 ExperimentStatusDto JSON
- **测试步骤**:
  1. 调用 `experimentService.getStatus('exp-123')`
- **预期结果**:
  - 返回 `ExperimentStatusDto`（结构化 DTO，非简单枚举）
  - HTTP GET 到 `/api/v1/experiments/exp-123/status`
  - DTO 字段：`id`, `name`, `status`(string), `methodId`, `startedAt`, `endedAt`, `updatedAt`
  - 示例响应体：
    ```json
    {
      "code": 200,
      "message": "success",
      "data": {
        "id": "exp-123",
        "name": "Temperature Test",
        "status": "RUNNING",
        "method_id": "m-001",
        "started_at": "2026-06-01T10:30:00+00:00",
        "ended_at": null,
        "updated_at": "2026-06-01T10:30:00+00:00"
      },
      "timestamp": "2026-06-01T10:30:00+00:00"
    }
    ```

#### TC-EXP-024: 获取状态历史 — 成功
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的 StateChangeLogDto 列表 JSON
- **测试步骤**:
  1. 调用 `experimentService.getHistory('exp-123')`
- **预期结果**:
  - 返回 `List<StatusChange>`
  - 按时间倒序排列
  - 字段映射验证（对应后端 StateChangeLogDto）：
    - `id` — 日志记录 ID
    - `experimentId` / `experiment_id` — 试验 ID
    - `previousState` / `previous_state` — 旧状态字符串（如 "LOADED"）
    - `newState` / `new_state` — 新状态字符串（如 "RUNNING"）
    - `operation` — 操作名称（如 "start"）
    - `userId` / `user_id` — 操作用户 ID
    - `timestamp` — RFC 3339 时间戳字符串
    - `errorMessage` / `error_message` — 可选的错误消息

#### TC-EXP-025: 获取状态历史 — 空历史
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + ApiResponse 包裹的空列表 `[]`
- **测试步骤**:
  1. 调用 `experimentService.getHistory('exp-123')`
- **预期结果**:
  - 返回空列表 `[]`

### 3.6 数据查询

#### TC-EXP-026: 查询试验数据 — 正常时间范围
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + TimeSeriesData JSON
- **测试步骤**:
  1. 调用 `experimentService.queryData('exp-123', deviceId: 'dev-1', DataQueryParams(startTime: t1, endTime: t2, pointIds: ['p1', 'p2']))`
- **预期结果**:
  - HTTP POST 到 `/api/v1/experiments/exp-123/data/query`
  - 返回 TimeSeriesData，包含时间戳数组和测点值数组

#### TC-EXP-027: 查询试验数据 — 降采样参数
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200
- **测试步骤**:
  1. 调用 `experimentService.queryData(..., downsample: 1000)`
- **预期结果**:
  - Request body 包含 `downsample: 1000`

#### TC-EXP-028: 查询试验数据 — 无数据
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - Mock Dio 返回 200 + 空时间序列
- **测试步骤**:
  1. 调用 `experimentService.queryData('exp-123', params)`
- **预期结果**:
  - 返回 TimeSeriesData，timestamps 为空，values 为空

---

## 4. WsService 测试用例

### 4.1 WebSocket 连接

#### TC-WS-001: 连接 WebSocket — 成功
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - Mock WebSocketChannel 已配置
  - `WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws/experiments/exp-123'))` 成功
- **测试步骤**:
  1. 调用 `wsService.connect('exp-123')`
  2. 等待返回 Stream
- **预期结果**:
  - 返回非 null 的 `Stream<ExperimentMessage>`
  - WebSocket 连接到 `ws://localhost:8080/ws/experiments/exp-123`
  - 未触发重连逻辑

#### TC-WS-002: 连接 WebSocket — 立即失败
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - Mock WebSocketChannel.connect 立即抛出异常
- **测试步骤**:
  1. 调用 `wsService.connect('exp-123')`
  2. 等待重连流程
- **预期结果**:
  - 首次连接失败后，触发重连逻辑
  - 第 1 次重连延迟约 1 秒

#### TC-WS-003: 接收状态变更消息
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
  - Mock 流推送 JSON 消息：`{"type": "status_change", "data": {"experiment_id": "exp-123", "old_status": "LOADED", "new_status": "RUNNING", "operation": "start", "user_id": "user-001", "timestamp": "2026-06-01T10:30:00+00:00"}}`
- **测试步骤**:
  1. 订阅 `wsService.connect('exp-123')` 返回的 Stream
  2. Mock 流推送状态变更消息
- **预期结果**:
  - Stream 发出 `ExperimentMessage.statusChange(...)` 实例
  - `data.oldStatus` 为 `"LOADED"`（字符串，非枚举）
  - `data.newStatus` 为 `"RUNNING"`（字符串，非枚举）
  - `data.operation` 为 `"start"`
  - `data.experimentId` 为 `"exp-123"`
  - `data.userId` 为 `"user-001"`

#### TC-WS-004: 接收 error 消息
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
  - Mock 流推送 JSON 消息：`{"type": "error", "data": {"experiment_id": "exp-123", "error": "Sensor timeout", "code": 1001}}`
- **测试步骤**:
  1. 订阅 Stream
  2. Mock 流推送 error 消息
- **预期结果**:
  - Stream 发出 `ExperimentMessage.wsError(...)` 实例
  - `data.error` 为 `"Sensor timeout"`
  - `data.code` 为 `1001`
  - `data.experimentId` 为 `"exp-123"`

#### TC-WS-005: 接收多种类型消息交错
- **优先级**: P1
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
- **测试步骤**:
  1. 订阅 Stream
  2. 依次推送：status_change、error、status_change、error（使用完整字段的消息格式）
- **预期结果**:
  - Stream 按顺序发出 4 个 ExperimentMessage 实例
  - 每个实例类型正确（status_change、error、status_change、error）
  - 无消息丢失或乱序

#### TC-WS-006: 接收未知类型消息 — 不崩溃
- **优先级**: P1
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
- **测试步骤**:
  1. 订阅 Stream
  2. Mock 流推送 `{"type": "unknown_type", "data": {}}`
- **预期结果**:
  - 不抛出异常
  - 可选择：跳过未知消息 或 包装为未知类型消息

#### TC-WS-007: 接收无效 JSON — 不崩溃
- **优先级**: P1
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
- **测试步骤**:
  1. 订阅 Stream
  2. Mock 流推送非 JSON 字符串 `"invalid json"`
- **预期结果**:
  - 不导致 Stream 终止
  - 错误被内部捕获，可选择在 onError 回调中报告

### 4.2 WebSocket 断开

#### TC-WS-008: 手动断开连接
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
- **测试步骤**:
  1. 调用 `wsService.connect('exp-123')`
  2. 调用 `wsService.disconnect()`
- **预期结果**:
  - WebSocket sink 的 `close()` 被调用
  - Stream 不再接收新消息
  - 重连逻辑不再触发

#### TC-WS-009: 断开时未连接 — 不抛出异常
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - WebSocket 未连接
- **测试步骤**:
  1. 调用 `wsService.disconnect()`
- **预期结果**:
  - 不抛出异常
  - 静默完成

#### TC-WS-010: 服务器主动断开 — 触发重连
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - WebSocket 已连接
  - Mock 流在发送 2 条消息后触发 close
- **测试步骤**:
  1. 订阅 Stream，接收 2 条消息
  2. Mock 流关闭（模拟服务器断开）
  3. 等待重连
- **预期结果**:
  - 前 2 条消息正常接收
  - 流关闭后触发重连
  - 第 1 次重连延迟约 1 秒

### 4.3 自动重连 — 指数退避

#### TC-WS-011: 重连成功 — 第 1 次重连
- **优先级**: P0
- **类型**: 单元测试（异步，定时敏感）
- **前置条件**:
  - WebSocket 首次连接失败
  - 第 1 次重连（延迟 1s）成功
- **测试步骤**:
  1. Mock 首次连接失败
  2. Mock 第 1 次重连成功
  3. 调用 `connect('exp-123')`
  4. 测量重连延迟
- **预期结果**:
  - 约 1 秒后重连
  - 重连成功后 Stream 可正常接收消息
  - 退避计数器重置

#### TC-WS-012: 重连成功 — 第 2 次重连（2s 延迟）
- **优先级**: P0
- **类型**: 单元测试（异步，定时敏感）
- **前置条件**:
  - 前 2 次连接均失败
  - 第 3 次（即第 2 次重连，延迟 2s）成功
- **测试步骤**:
  1. Mock 连续 2 次连接失败
  2. Mock 第 3 次连接成功
  3. 调用 `connect('exp-123')`
  4. 测量各次重连延迟
- **预期结果**:
  - 第 1 次重连延迟约 1s
  - 第 2 次重连延迟约 2s
  - 最终连接成功，Stream 可用

#### TC-WS-013: 重连成功 — 第 3 次重连（4s 延迟）
- **优先级**: P0
- **类型**: 单元测试（异步，定时敏感）
- **前置条件**:
  - 前 3 次连接均失败
  - 第 4 次连接成功
- **测试步骤**:
  1. Mock 连续 3 次连接失败
  2. Mock 第 4 次连接成功
  3. 调用 `connect('exp-123')`
  4. 测量延迟：1s, 2s, 4s
- **预期结果**:
  - 第 3 次重连延迟约 4s
  - 最终连接成功

#### TC-WS-014: 重连成功 — 第 4 次重连（8s 延迟）
- **优先级**: P0
- **类型**: 单元测试（异步，定时敏感）
- **前置条件**:
  - 前 4 次连接均失败
  - 第 5 次连接成功
- **测试步骤**:
  1. Mock 连续 4 次连接失败
  2. Mock 第 5 次连接成功
  3. 调用 `connect('exp-123')`
  4. 测量延迟：1s, 2s, 4s, 8s
- **预期结果**:
  - 第 4 次重连延迟约 8s
  - 最终连接成功

#### TC-WS-015: 重连超过 5 次 — 停止重连
- **优先级**: P0
- **类型**: 单元测试（异步，定时敏感）
- **前置条件**:
  - 所有连接尝试均失败（共 6 次：首次 + 5 次重连）
- **测试步骤**:
  1. Mock 所有连接尝试均失败
  2. 调用 `connect('exp-123')`
  3. 等待 20 秒（超过所有重连延迟总和）
- **预期结果**:
  - 总共尝试连接 6 次（首次 + 5 次重连）
  - 5 次重连延迟：1s, 2s, 4s, 8s, 8s（上限 8s，不超过 8s）
  - 第 6 次尝试后不再重连
  - Stream 以错误状态关闭
  - `isReconnecting` 状态为 false
  - `reconnectAttempts` 达到上限

#### TC-WS-016: 重连超过 5 次 — 状态通知
- **优先级**: P1
- **类型**: 单元测试（异步）
- **前置条件**:
  - 所有连接尝试均失败
- **测试步骤**:
  1. Mock 所有连接失败
  2. 监听 `connectionStatus` Stream/State
  3. 调用 `connect('exp-123')`
- **预期结果**:
  - connectionStatus 依次发出：connecting → disconnected → reconnecting(1) → reconnecting(2) → ... → failed
  - 最终状态为 `ConnectionState.failed`

#### TC-WS-017: 手动重新连接（失败后）
- **优先级**: P0
- **类型**: 单元测试（异步）
- **前置条件**:
  - 自动重连已达 5 次上限，连接失败
- **测试步骤**:
  1. 让自动重连达到上限
  2. 调用 `wsService.connect('exp-123')` 再次手动连接
  3. Mock 此次连接成功
- **预期结果**:
  - 手动调用 `connect()` 重置重连计数器
  - 新的连接成功
  - Stream 正常可用

#### TC-WS-018: 连接成功后重连计数器重置
- **优先级**: P1
- **类型**: 单元测试（异步）
- **前置条件**:
  - 第 2 次重连（延迟 2s）成功
- **测试步骤**:
  1. Mock 首次连接失败
  2. Mock 第 1 次重连失败
  3. Mock 第 2 次重连成功
  4. Mock 后续服务器断开
  5. Mock 重连成功
- **预期结果**:
  - 前 2 次重连延迟为 1s, 2s
  - 连接成功后，服务器再次断开
  - 新一轮重连从 1s 开始（计数器已重置）

#### TC-WS-019: 连接不同试验 ID — 独立连接
- **优先级**: P1
- **类型**: 单元测试
- **前置条件**:
  - 已连接到 'exp-123'
- **测试步骤**:
  1. 调用 `connect('exp-123')`
  2. 不调用 disconnect
  3. 调用 `connect('exp-456')`
- **预期结果**:
  - 旧连接被断开
  - 新连接到 `ws://localhost:8080/ws/experiments/exp-456`
  - 旧 Stream 关闭，新 Stream 可用

### 4.4 消息解析

#### TC-WS-020: 解析状态变更消息 — 完整字段
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - JSON 字符串完整
- **测试步骤**:
  1. 解析 `{"type": "status_change", "data": {"experiment_id": "exp-123", "old_status": "LOADED", "new_status": "RUNNING", "operation": "start", "user_id": "user-001", "timestamp": "2026-06-01T10:30:00Z"}}`
- **预期结果**:
  - 解析为 `ExperimentMessage.statusChange(...)`
  - `data.oldStatus` = `"LOADED"`（字符串）
  - `data.newStatus` = `"RUNNING"`（字符串）
  - `data.operation` = `"start"`
  - `data.experimentId` = `"exp-123"`
  - `data.userId` = `"user-001"`

#### TC-WS-021: 解析 error 消息 — 完整字段
- **优先级**: P0
- **类型**: 单元测试
- **前置条件**:
  - JSON 字符串完整
- **测试步骤**:
  1. 解析 `{"type": "error", "data": {"experiment_id": "exp-123", "error": "Sensor timeout", "code": 1001}}`
- **预期结果**:
  - 解析为 `ExperimentMessage.wsError(...)`
  - `data.error` = `"Sensor timeout"`
  - `data.code` = `1001`
  - `data.experimentId` = `"exp-123"`

---

## 5. ExperimentProvider 测试用例

### 5.1 ExperimentListNotifier

#### TC-PROV-001: 初始状态 — loading
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 使用 `ProviderContainer` 创建测试环境
  - Mock ExperimentService
- **测试步骤**:
  1. 监听 `experimentListProvider`
  2. 首次 build 立即触发
- **预期结果**:
  - 初始状态为 `AsyncLoading<List<Experiment>>()`

#### TC-PROV-002: 列表加载成功 — data 状态
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - Mock ExperimentService.list() 返回 3 条记录
- **测试步骤**:
  1. 监听 `experimentListProvider`
  2. 等待加载完成
- **预期结果**:
  - 状态从 loading → data
  - `AsyncData.value` 包含 3 条 Experiment
  - 数据按创建时间倒序排列（如后端如此返回）

#### TC-PROV-003: 列表加载失败 — error 状态
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - Mock ExperimentService.list() 抛出网络异常
- **测试步骤**:
  1. 监听 `experimentListProvider`
  2. 等待加载完成
- **预期结果**:
  - 状态从 loading → error
  - `AsyncError.error` 为异常对象
  - 包含用户可读错误消息

#### TC-PROV-004: 空列表 — data(空列表)
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - Mock ExperimentService.list() 返回空列表
- **测试步骤**:
  1. 监听 `experimentListProvider`
  2. 等待加载完成
- **预期结果**:
  - 状态为 `AsyncData([])`（空列表，非 error）
  - 触发 Empty 状态的 UI 展示

#### TC-PROV-005: 筛选条件更新 — 重新加载
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 初始加载完成，状态为 data
- **测试步骤**:
  1. 调用 `notifier.setFilter(status: ExperimentStatus.running)`
  2. 等待重新加载
- **预期结果**:
  - 状态短暂回到 loading（或保持 data 并刷新）
  - Mock ExperimentService.list() 被调用，参数包含 `status=RUNNING`
  - 新数据只包含 RUNNING 状态的试验

#### TC-PROV-006: 时间范围筛选 — 日期参数正确
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 初始加载完成
- **测试步骤**:
  1. 调用 `notifier.setDateRange(createdAfter: DateTime(2026, 1, 1), createdBefore: DateTime(2026, 1, 31))`
  2. 等待重新加载
- **预期结果**:
  - Mock ExperimentService.list() 接收 `createdAfter` 和 `createdBefore` 参数
  - 返回结果符合时间范围

#### TC-PROV-007: 分页加载更多 — 追加数据
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 第 1 页已加载（20 条）
  - `total=50`
- **测试步骤**:
  1. 调用 `notifier.loadMore()`
  2. 等待加载完成
- **预期结果**:
  - Mock ExperimentService.list(page: 2) 被调用
  - 新数据追加到现有列表（共 40 条）
  - 状态保持为 data，不回到 loading（或使用 optimistic UI）

#### TC-PROV-008: 分页 — 已到最后一页
- **优先级**: P1
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 已加载所有数据，`total=50`, 当前 `size=20`, 已加载第 3 页
- **测试步骤**:
  1. 调用 `notifier.loadMore()`
- **预期结果**:
  - 不发送新的 HTTP 请求
  - 状态不变
  - `has_next` 为 false, `has_prev` 为 true

#### TC-PROV-009: 刷新列表 — pull-to-refresh
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 列表已加载
- **测试步骤**:
  1. 调用 `notifier.refresh()`
  2. 等待完成
- **预期结果**:
  - Mock ExperimentService.list() 被调用，page=1
  - 状态短暂回到 loading 后回到 data
  - 数据为最新

### 5.2 ExperimentControlNotifier

#### TC-PROV-011: 加载试验详情 — 成功
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - Mock ExperimentService.getById() 返回试验详情
- **测试步骤**:
  1. 监听 `experimentControlProvider('exp-123')`
  2. 等待加载
- **预期结果**:
  - 状态为 `AsyncData<Experiment>`
  - 试验信息正确，包含 workbench/method/status 等

#### TC-PROV-012: 载入操作 (load) — 更新状态
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验当前状态为 IDLE
  - Mock ExperimentService.load() 返回 ExperimentControlDto（status="LOADED"）
- **测试步骤**:
  1. 调用 `notifier.load(methodId: 'm-001')`
  2. 等待完成
- **预期结果**:
  - Mock ExperimentService.load('exp-123', methodId: 'm-001') 被调用
  - 操作期间状态为 loading
  - 操作成功后状态更新为 LOADED
  - Provider 从 DTO 的 `status` 字段提取新状态

#### TC-PROV-013: 开始操作 (start) — 更新状态
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验当前状态为 LOADED
  - Mock ExperimentService.start() 成功
- **测试步骤**:
  1. 调用 `notifier.start()`
  2. 等待完成
- **预期结果**:
  - Mock ExperimentService.start() 被调用
  - 操作成功后状态更新为 RUNNING

#### TC-PROV-014: 暂停操作 (pause) — 更新状态
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验当前状态为 RUNNING
- **测试步骤**:
  1. 调用 `notifier.pause()`
- **预期结果**:
  - 状态更新为 PAUSED

#### TC-PROV-015: 继续操作 (resume) — 更新状态
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验当前状态为 PAUSED
- **测试步骤**:
  1. 调用 `notifier.resume()`
- **预期结果**:
  - 状态更新为 RUNNING

#### TC-PROV-016: 停止操作 (stop) — 更新状态为 LOADED
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验当前状态为 RUNNING
- **测试步骤**:
  1. 调用 `notifier.stop()`
- **预期结果**:
  - Mock ExperimentService.stop() 被调用
  - 状态更新为 LOADED

#### TC-PROV-017: 控制操作 — 状态校验（防误操作）
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验当前状态为 IDLE
- **测试步骤**:
  1. 调用 `notifier.start()`（IDLE 状态不允许 start）
- **预期结果**:
  - 不调用 ExperimentService.start()
  - 抛出异常或返回错误："当前状态不允许开始操作"
  - 状态保持 IDLE

#### TC-PROV-018: 控制操作 — 网络错误
- **优先级**: P0
- **类型**: Widget/Provider 测试
- **前置条件**:
  - Mock ExperimentService.start() 抛出网络异常
- **测试步骤**:
  1. 调用 `notifier.start()`
- **预期结果**:
  - 状态回到之前的状态（不更新）
  - 错误状态可被 UI 捕获显示
  - 试验状态未改变

#### TC-PROV-019: 控制操作 — 防重复提交
- **优先级**: P1
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 控制操作正在进行中（异步尚未完成）
- **测试步骤**:
  1. 调用 `notifier.start()`
  2. 在 Future 完成前再次调用 `notifier.start()`
- **预期结果**:
  - 第二次调用被忽略或抛出 "操作进行中"
  - 仅发送 1 次 HTTP 请求

#### TC-PROV-020: 获取历史状态 — 成功
- **优先级**: P1
- **类型**: Widget/Provider 测试
- **前置条件**:
  - Mock ExperimentService.getHistory() 返回状态变更列表
- **测试步骤**:
  1. 调用 `notifier.loadHistory()`
- **预期结果**:
  - 返回 `List<StatusChange>`
  - 状态变更按时间倒序排列

### 5.3 ExperimentWsProvider

#### TC-PROV-021: WebSocket 消息更新试验状态
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - ExperimentControlNotifier 已加载试验（状态为 LOADED）
  - WebSocket 已连接
- **测试步骤**:
  1. Mock WebSocket 推送状态变更消息：`status: RUNNING`
  2. 监听 `experimentControlProvider`
- **预期结果**:
  - 试验状态从 LOADED 更新为 RUNNING
  - UI 自动刷新（通过 Riverpod 通知机制）

#### TC-PROV-022: WebSocket 状态变更消息更新试验状态
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - WebSocket 已连接
  - 试验当前状态为 LOADED
- **测试步骤**:
  1. Mock WebSocket 推送状态变更消息：`old_status: LOADED, new_status: RUNNING, operation: start`
  2. 监听试验状态 Provider
- **预期结果**:
  - 试验状态更新为 RUNNING
  - UI 自动刷新（通过 Riverpod 通知机制）

#### TC-PROV-023: 多条状态变更消息按顺序处理
- **优先级**: P1
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - WebSocket 已连接
  - 试验初始状态为 LOADED
- **测试步骤**:
  1. Mock 推送 3 条状态变更消息：LOADED→RUNNING, RUNNING→PAUSED, PAUSED→RUNNING
  2. 监听试验状态
- **预期结果**:
  - 试验状态最终为 RUNNING
  - 每条消息按顺序处理，无丢失

#### TC-PROV-024: WebSocket 断开 — 显示状态指示
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - WebSocket 已连接
- **测试步骤**:
  1. Mock WebSocket 关闭
  2. 监听连接状态 Provider
- **预期结果**:
  - 连接状态变为 `disconnected`
  - UI 显示断开指示（如 🔴 已断开）
  - 自动重连逻辑开始

#### TC-PROV-025: WebSocket 重连中 — 显示重连指示
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - WebSocket 断开，自动重连中
- **测试步骤**:
  1. Mock 连接失败，触发重连
  2. 监听连接状态 Provider
- **预期结果**:
  - 连接状态变为 `reconnecting`
  - 显示重连次数（如 "正在重连 (1/5)..."）
  - UI 显示黄色/橙色连接指示

#### TC-PROV-026: WebSocket 重连成功 — 恢复状态
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - WebSocket 断开，正在重连
- **测试步骤**:
  1. Mock 重连成功
  2. 监听连接状态
- **预期结果**:
  - 连接状态变为 `connected`
  - 显示绿色连接指示 🟢
  - 重新订阅 Stream，可继续接收消息

#### TC-PROV-027: WebSocket 重连失败 5 次 — 显示手动重连按钮
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - 所有连接尝试均失败
- **测试步骤**:
  1. Mock 所有连接失败
  2. 等待 5 次重连全部失败
  3. 监听连接状态
- **预期结果**:
  - 连接状态变为 `failed`
  - 显示 "连接失败" 和 "重新连接" 按钮
  - 不再自动重连

#### TC-PROV-028: 手动点击重新连接 — 成功
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - 自动重连已达上限，状态为 failed
- **测试步骤**:
  1. 调用手动重连操作
  2. Mock 此次连接成功
- **预期结果**:
  - 重连计数器重置
  - 连接成功
  - 状态变为 `connected`

#### TC-PROV-029: 离开页面 — 断开 WebSocket
- **优先级**: P0
- **类型**: Widget/Provider 测试（异步）
- **前置条件**:
  - 页面已挂载，WebSocket 已连接
- **测试步骤**:
  1. 模拟 Widget dispose（如使用 `ProviderScope` 销毁）
  2. 验证 WsService.disconnect() 是否被调用
- **预期结果**:
  - `wsService.disconnect()` 被调用
  - WebSocket 连接关闭
  - 不再接收消息

#### TC-PROV-030: 运行时长时间计时
- **优先级**: P1
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验状态为 RUNNING
  - 开始时间为 10 分钟前
- **测试步骤**:
  1. 查询运行时长
  2. 等待 1 秒
  3. 再次查询
- **预期结果**:
  - 初始时长约为 10:00
  - 1 秒后约为 10:01
  - 计时器在 RUNNING 状态时递增

#### TC-PROV-031: 暂停时计时器停止
- **优先级**: P1
- **类型**: Widget/Provider 测试
- **前置条件**:
  - 试验状态为 PAUSED
  - 已运行 5 分钟
- **测试步骤**:
  1. 查询运行时长（5:00）
  2. 等待 2 秒
  3. 再次查询
- **预期结果**:
  - 两次查询时长相同（5:00）
  - 计时器在 PAUSED 状态停止递增

---

## 6. 集成测试用例

### 6.1 端到端工作流

#### TC-INT-001: 完整试验生命周期
- **优先级**: P0
- **类型**: 集成测试
- **前置条件**:
  - Mock ExperimentService 和 WsService
  - 试验初始状态为 IDLE
- **测试步骤**:
  1. Provider 加载试验详情
  2. 调用 load() → 状态变为 LOADED
  3. Mock WS 推送确认消息
  4. 调用 start() → 状态变为 RUNNING
  5. Mock WS 推送状态 RUNNING
  6. 调用 pause() → 状态变为 PAUSED
  7. Mock WS 推送状态 PAUSED
  8. 调用 resume() → 状态变为 RUNNING
  9. 调用 stop() → 状态变为 LOADED
  10. 调用 complete() → 状态变为 COMPLETED
- **预期结果**:
  - 每个操作 HTTP 请求正确
  - WS 消息正确解析和分发
  - 状态变更正确反映在 Provider 中

#### TC-INT-002: 试验控制台页面 — 连接 → 断开 → 重连
- **优先级**: P0
- **类型**: Widget 集成测试
- **前置条件**:
  - 试验控制台页面 Widget 已构建
  - Mock WebSocket
- **测试步骤**:
  1. 页面构建 → 自动连接 WS
  2. 验证显示 "已连接" 指示
  3. Mock 服务器断开
  4. 验证显示 "连接中..." / "已断开"
  5. Mock 重连成功
  6. 验证显示 "已连接"
  7. 销毁页面 → 断开 WS
- **预期结果**:
  - 连接生命周期完整
  - UI 状态与连接状态同步
  - 无内存泄漏（Stream 正确关闭）

#### TC-INT-003: 网络恢复后自动重连
- **优先级**: P0
- **类型**: 集成测试（异步，定时敏感）
- **前置条件**:
  - WebSocket 已连接
- **测试步骤**:
  1. Mock 网络断开（连接失败）
  2. 等待指数退避重连
  3. Mock 网络恢复
  4. 等待重连成功
- **预期结果**:
  - 网络恢复后自动重连成功
  - Stream 恢复可用
  - 消息继续接收

---

## 7. 测试覆盖矩阵

### 需求 → 测试用例追溯

| 需求 | 测试用例 ID | 状态 |
|------|------------|------|
| ExperimentService.list() 正常加载 | TC-EXP-001 | ⬜ 待执行 |
| ExperimentService.list() 空数据 | TC-EXP-002 | ⬜ 待执行 |
| ExperimentService.list() 分页 | TC-EXP-003 | ⬜ 待执行 |
| ExperimentService.list() 状态筛选 | TC-EXP-004 | ⬜ 待执行 |
| ExperimentService.list() 时间筛选 | TC-EXP-005 | ⬜ 待执行 |
| ExperimentService.list() 网络错误 | TC-EXP-007 | ⬜ 待执行 |
| ExperimentService.getById() | TC-EXP-010, TC-EXP-011 | ⬜ 待执行 |
| ExperimentService.create() | TC-EXP-012 ~ TC-EXP-014 | ⬜ 待执行 |
| ExperimentService.load/start/pause/resume/stop | TC-EXP-015 ~ TC-EXP-019, TC-EXP-020 ~ TC-EXP-022 | ⬜ 待执行 |
| ExperimentService.getStatus() | TC-EXP-023 | ⬜ 待执行 |
| ExperimentService.getHistory() | TC-EXP-024, TC-EXP-025 | ⬜ 待执行 |
| ExperimentService.getHistory() | TC-EXP-024, TC-EXP-025 | ⬜ 待执行 |
| ExperimentService.queryData() | TC-EXP-026 ~ TC-EXP-028 | ⬜ 待执行 |
| WsService.connect() 成功 | TC-WS-001 | ⬜ 待执行 |
| WsService 接收状态变更 | TC-WS-003 | ⬜ 待执行 |
| WsService 接收 error | TC-WS-004 | ⬜ 待执行 |
| WsService.disconnect() | TC-WS-008, TC-WS-009 | ⬜ 待执行 |
| WsService 自动重连 | TC-WS-011 ~ TC-WS-014 | ⬜ 待执行 |
| WsService 重连上限 5 次 | TC-WS-015, TC-WS-016 | ⬜ 待执行 |
| WsService 解析 error | TC-WS-021 | ⬜ 待执行 |
| WsService 手动重连 | TC-WS-017 | ⬜ 待执行 |
| ExperimentListNotifier loading/error/data | TC-PROV-001 ~ TC-PROV-004 | ⬜ 待执行 |
| ExperimentListNotifier 筛选更新 | TC-PROV-005, TC-PROV-006 | ⬜ 待执行 |
| ExperimentListNotifier 分页 | TC-PROV-007, TC-PROV-008 | ⬜ 待执行 |
| ExperimentControlNotifier 控制操作 | TC-PROV-012 ~ TC-PROV-016 | ⬜ 待执行 |
| ExperimentControlNotifier 状态校验 | TC-PROV-017 | ⬜ 待执行 |
| ExperimentWsProvider 消息更新 | TC-PROV-021 ~ TC-PROV-023 | ⬜ 待执行 |
| ExperimentWsProvider 连接状态 | TC-PROV-024 ~ TC-PROV-029 | ⬜ 待执行 |

### 统计

| 类别 | 数量 |
|------|------|
| ExperimentService 测试 | 28 |
| WsService 测试 | 21 |
| ExperimentProvider 测试 | 30 |
| 集成测试 | 3 |
| **总计** | **82** |

---

## 8. Mock 规范

### 8.1 Mock 实验数据

```dart
// 标准试验对象（用于多个测试用例）
final experiment1 = Experiment(
  id: 'exp-001',
  userId: 'user-001',
  name: 'Temperature Test',
  methodId: 'm-001',
  status: ExperimentStatus.running,
  ownerType: 'personal',
  ownerId: 'user-001',
  createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
  updatedAt: DateTime.parse('2026-06-01T10:30:00Z'),
  startedAt: DateTime.parse('2026-06-01T10:30:00Z'),
);

final experiment2 = Experiment(
  id: 'exp-002',
  userId: 'user-001',
  name: 'Pressure Calibration',
  methodId: 'm-002',
  status: ExperimentStatus.completed,
  ownerType: 'personal',
  ownerId: 'user-001',
  createdAt: DateTime.parse('2026-05-28T08:00:00Z'),
  updatedAt: DateTime.parse('2026-05-28T11:00:00Z'),
  startedAt: DateTime.parse('2026-05-28T09:00:00Z'),
  endedAt: DateTime.parse('2026-05-28T11:00:00Z'),
);
```

### 8.2 Mock 响应数据

#### 控制操作响应（load/start/pause/resume/stop）

后端返回 `ApiResponse<ExperimentControlDto>`：

```dart
// 成功响应：外层为 ApiResponse 包裹
final controlSuccessResponse = {
  'code': 200,
  'message': 'success',
  'data': {
    'id': 'exp-001',
    'name': 'Temperature Test',
    'status': 'RUNNING',
    'method_id': 'm-001',
    'description': 'A temperature calibration test',
    'started_at': '2026-06-01T10:30:00+00:00',
    'ended_at': null,
    'created_at': '2026-06-01T10:00:00+00:00',
    'updated_at': '2026-06-01T10:30:00+00:00',
  },
  'timestamp': '2026-06-01T10:30:00+00:00',
};

// Load 操作响应（status = "LOADED", method_id = "m-001"）
final loadResponse = { ...controlSuccessResponse, 'data': { ...controlSuccessResponse['data'], 'status': 'LOADED', 'started_at': null } };
// Start 操作响应（status = "RUNNING", started_at 有值）
final startResponse = { ...controlSuccessResponse };
// Pause 操作响应（status = "PAUSED"）
final pauseResponse = { ...controlSuccessResponse, 'data': { ...controlSuccessResponse['data'], 'status': 'PAUSED' } };
// Resume 操作响应（status = "RUNNING"）
final resumeResponse = { ...controlSuccessResponse };
// Stop 操作响应（status = "LOADED"）
final stopResponse = { ...controlSuccessResponse, 'data': { ...controlSuccessResponse['data'], 'status': 'LOADED' } };
```

#### 状态查询响应（getStatus）

后端返回 `ApiResponse<ExperimentStatusDto>`（是 ExperimentControlDto 的子集，不含 description 和 created_at）：

```dart
final statusResponse = {
  'code': 200,
  'message': 'success',
  'data': {
    'id': 'exp-001',
    'name': 'Temperature Test',
    'status': 'RUNNING',
    'method_id': 'm-001',
    'started_at': '2026-06-01T10:30:00+00:00',
    'ended_at': null,
    'updated_at': '2026-06-01T10:30:00+00:00',
  },
  'timestamp': '2026-06-01T10:30:00+00:00',
};
```

#### 状态历史响应（getHistory）

后端返回 `ApiResponse<Vec<StateChangeLogDto>>`：

```dart
final historyResponse = {
  'code': 200,
  'message': 'success',
  'data': [
    {
      'id': 'log-001',
      'experiment_id': 'exp-001',
      'previous_state': 'LOADED',
      'new_state': 'RUNNING',
      'operation': 'start',
      'user_id': 'user-001',
      'timestamp': '2026-06-01T10:30:00+00:00',
      'error_message': null,
    },
    {
      'id': 'log-002',
      'experiment_id': 'exp-001',
      'previous_state': 'IDLE',
      'new_state': 'LOADED',
      'operation': 'load',
      'user_id': 'user-001',
      'timestamp': '2026-06-01T10:15:00+00:00',
      'error_message': null,
    },
  ],
  'timestamp': '2026-06-01T10:30:00+00:00',
};

final emptyHistoryResponse = {
  'code': 200,
  'message': 'success',
  'data': [],
  'timestamp': '2026-06-01T10:30:00+00:00',
};
```

### 8.3 Mock WebSocket 消息

```dart
// 状态变更消息（tagged union 格式，后端使用 #[serde(tag = "type", content = "data")]）
final statusChangeMessage = {
  'type': 'status_change',
  'data': {
    'experiment_id': 'exp-001',
    'old_status': 'LOADED',
    'new_status': 'RUNNING',
    'operation': 'start',
    'user_id': 'user-001',
    'timestamp': '2026-06-01T10:30:00+00:00',
  },
};

// error 消息
final errorMessage = {
  'type': 'error',
  'data': {
    'experiment_id': 'exp-001',
    'error': 'Sensor timeout',
    'code': 1001,
  },
};
```

### 8.4 时间控制

对于定时敏感的测试（重连退避），使用 `FakeAsync` 或 `testWidgets` 的 `pump` 控制时间：

```dart
test('reconnect backoff', () async {
  await FakeAsync().run((async) {
    // 触发连接
    wsService.connect('exp-123');
    
    // 快进 1 秒
    async.elapse(Duration(seconds: 1));
    // 验证第 1 次重连
    
    // 快进 2 秒
    async.elapse(Duration(seconds: 2));
    // 验证第 2 次重连
  });
});
```

### 8.5 Riverpod 测试辅助

```dart
// Provider 测试容器
final container = ProviderContainer(
  overrides: [
    experimentServiceProvider.overrideWithValue(mockExperimentService),
    wsServiceProvider.overrideWithValue(mockWsService),
  ],
);

// 监听 Provider 状态
final listener = Listener<AsyncValue<List<Experiment>>>();
container.listen(
  experimentListProvider,
  listener,
  fireImmediately: true,
);
```

---

## 附录 A：测试执行顺序建议

### 阶段 1：Service 单元测试（无 Widget 层）
1. ExperimentService 所有测试（TC-EXP-001 ~ TC-EXP-028）
2. WsService 所有测试（TC-WS-001 ~ TC-WS-021）

### 阶段 2：Provider 单元测试
3. ExperimentListNotifier（TC-PROV-001 ~ TC-PROV-010）
4. ExperimentControlNotifier（TC-PROV-011 ~ TC-PROV-020）
5. ExperimentWsProvider（TC-PROV-021 ~ TC-PROV-031）

### 阶段 3：集成测试
6. 端到端工作流（TC-INT-001 ~ TC-INT-003）

---

## 附录 B：评审修订记录

### sw-tom 评审结论（P0 关键问题修订）

| # | 问题 | 修订内容 | 状态 |
|---|------|----------|------|
| 1 | WebSocket 消息类型不匹配 | 移除 `log` 类型，仅保留 `status_change` 和 `error`；字段名对齐 `old_status`/`new_status`/`operation`；JSON 结构为 tagged union | ✅ 已修订 |
| 2 | `create()` 参数不对齐 | 移除 `workbenchId`、`parameters`；增加 `name`（必填）、`description`（可选）；`method_id` 可选 | ✅ 已修订 |
| 3 | `load()` 需要 `method_id` | 修正为 `service.load(expId, methodId: 'm-1')`，请求体 `{"method_id": "..."}` | ✅ 已修订 |
| 4 | `stop()` 目标状态 | `stop()` → `LOADED`；新增 `complete()` → `COMPLETED`；新增 `abort()` → `ABORTED` | ✅ 已修订 |
| 5 | 分页字段名 | 响应 `data` → `items`；请求 `pageSize` → `size`；补充 `has_next`/`has_prev` 测试 | ✅ 已修订 |
| 6 | 状态筛选仅支持单值 | 改为 `list(status: ExperimentStatus.running)`（单一值） | ✅ 已修订 |
| 7 | ExperimentStatus 枚举 | 无 `error` 状态，使用 `aborted`；完整枚举：`idle, loaded, running, paused, completed, aborted` | ✅ 已修订 |
| 8 | 其他字段对齐 | `queryData()` 增加 `deviceId`；日期参数 `startDate` → `startedAfter`；`scope` `'my'` → `'personal'`；Mock 数据补全 `userId`/`ownerType`/`ownerId`/`updatedAt` | ✅ 已修订 |

修订状态: ✅ 修订完成，请 sw-tom 重新评审

### 2026-06-01 v2.0 后端 API 对齐修正

| # | 问题 | 修订内容 | 状态 |
|---|------|----------|------|
| 1 | 控制操作返回 void | 修正为返回 `ExperimentControlDto`（完整试验实体），TC-EXP-015~TC-EXP-019 | ✅ 已修订 |
| 2 | `complete()`/`abort()` 非 API 路由 | 移除 TC-EXP-019a/019b、TC-PROV-016a/016b | ✅ 已修订 |
| 3 | `getStatus()` 返回枚举 | 修正为返回 `ExperimentStatusDto`（结构化 DTO），TC-EXP-023 | ✅ 已修订 |
| 4 | `StatusChange` 字段错误 | 修正字段映射为 `id`/`experimentId`/`previousState`/`newState`/`operation`/`userId`/`timestamp`/`errorMessage`，TC-EXP-024/025 | ✅ 已修订 |
| 5 | 筛选参数 `startedAfter` → `createdAfter` | 修正 TC-EXP-005/006、TC-PROV-006 | ✅ 已修订 |
| 6 | WS 消息字段不全 | 补充 `experiment_id`/`user_id`；字段值从枚举改为字符串，TC-WS-003/004/020/021 | ✅ 已修订 |
| 7 | Mock 数据未包裹 ApiResponse | 所有 Mock 响应增加 `code`/`message`/`data`/`timestamp` 外层结构 | ✅ 已修订 |
| 8 | 测试数量从 87 → 83 | 移除 4 个测试用例 | ✅ 已修订 |
| 9 | `search` 参数不存在 | 移除 TC-PROV-010；数量从 83 → 82 | ✅ 已修订 |

修订状态: ✅ 修订完成

## 终审结论

**评审人**: sw-tom
**日期**: 2026-06-01
**结论**: ✅ APPROVED

### 8 项 P0 问题逐项复核

| # | 问题 | 验证结果 | 说明 |
|---|------|----------|------|
| 1 | WebSocket 消息类型不匹配 | ✅ 已修正 | 已移除 `log` 类型，仅保留 `status_change`/`error`；字段名已对齐 `old_status`/`new_status`/`operation`；JSON 为 tagged union 结构（验证：TC-WS-003/004/020/021） |
| 2 | `create()` 参数不对齐 | ✅ 已修正 | 已移除 `workbenchId`、`parameters`；包含 `name`（必填）、`description`（可选）、`methodId`（可选）（验证：TC-EXP-012） |
| 3 | `load()` 需要 `method_id` | ✅ 已修正 | 签名改为 `load(expId, methodId: 'm-1')`，请求体 `{"method_id": "..."}`（验证：TC-EXP-015） |
| 4 | `stop()` 目标状态 | ✅ 已修正 | `stop()` → LOADED；新增 `complete()` → COMPLETED；新增 `abort()` → ABORTED（验证：TC-EXP-019/019a/019b，TC-PROV-016/016a/016b） |
| 5 | 分页字段名 | ✅ 已修正 | `data` → `items`；请求 `pageSize` → `size`；补充 `has_next`/`has_prev` 验证（验证：TC-EXP-002/003） |
| 6 | 状态筛选仅支持单值 | ✅ 已修正 | 改为 `list(status: ExperimentStatus.running)` 单一值（验证：TC-EXP-004） |
| 7 | ExperimentStatus 枚举 | ✅ 已修正 | 无 `error` 状态，使用 `aborted`；完整枚举：`idle, loaded, running, paused, completed, aborted`（验证：第 2 节枚举定义） |
| 8 | 其他字段对齐 | ✅ 已修正 | `queryData()` 增加 `deviceId`；日期参数 `startDate` → `startedAfter`；`scope: 'my'` → `'personal'`；Mock 数据补全 `userId`/`ownerType`/`ownerId`/`updatedAt`（验证：TC-EXP-026/005/006，Mock 数据节） |

### 终审意见

- 测试覆盖全面：87 个测试用例覆盖 ExperimentService（30）、WsService（21）、Provider（33）、集成（3）
- 修订记录完整且对应到具体测试用例
- Mock 规范清晰，包含数据、消息、时间控制、Provider 测试辅助
- 测试执行顺序合理分阶段

**结论**: ✅ 测试用例已通过终审，可以进入实现阶段。
