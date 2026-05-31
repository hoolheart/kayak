# TASK-002 测试用例 — 数据模型定义

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-002（数据模型定义，freezed 3.2.5 + json_annotation 4.12.0）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md), [architecture_proposal.md](../design/architecture_proposal.md)

---

## 测试范围

TASK-002 需交付以下数据模型文件：

| # | 文件 | 包含模型 | 来源后端 |
|---|------|---------|----------|
| 1 | `lib/models/user.dart` | User | `GET /auth/me`, `GET /users/me` |
| 2 | `lib/models/workbench.dart` | Workbench, CreateWorkbenchRequest | `GET /workbenches` |
| 3 | `lib/models/device.dart` | Device, DeviceTreeNode | `GET /devices/{id}` |
| 4 | `lib/models/point.dart` | Point, PointValue | `GET /points/{id}`, `GET /points/{id}/value` |
| 5 | `lib/models/method.dart` | Method, MethodParameter | `GET /methods` |
| 6 | `lib/models/experiment.dart` | Experiment, ExperimentStatus, ExperimentMessage | `GET /experiments`, WS |
| 7 | `lib/models/team.dart` | Team | `GET /teams` |
| 8 | `lib/models/common.dart` | ApiResponse\<T\>, PaginatedResponse\<T\>, AuthTokens | 统一响应格式 |
| 9 | `lib/models/protocol.dart` | ProtocolConfig (sealed union) | 设备协议配置 |

---

## 后端 API 实际响应格式速查

> 所有测试数据（JSON payload）基于后端实际响应格式构造，snake_case 字段名、枚举值、时间格式均以后端代码为准。

### 公共响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": { ... },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

### 认证响应

```json
// POST /auth/login → ApiResponse<TokenResponse>
{
  "code": 200, "message": "success",
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "admin@kayak.local",
      "username": "Admin"
    }
  },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

### 后端枚举值对照表

| 后端枚举 | serde 序列化 | JSON 中出现值 |
|----------|------------|-------------|
| `ExperimentStatus` | `rename_all = "UPPERCASE"` | `"IDLE"`, `"LOADED"`, `"RUNNING"`, `"PAUSED"`, `"COMPLETED"`, `"ABORTED"` |
| `DeviceStatus` | `rename_all = "snake_case"` | `"offline"`, `"online"`, `"error"` |
| `ProtocolType` | `rename_all = "snake_case"` | `"virtual"`, `"modbus_tcp"`, `"modbus_rtu"`, `"can"`, `"visa"`, `"mqtt"` |
| `DataType` | `rename_all = "snake_case"` | `"number"`, `"integer"`, `"string"`, `"boolean"` |
| `AccessType` | `rename_all = "snake_case"` | `"ro"`, `"wo"`, `"rw"` |
| `PointStatus` | `rename_all = "snake_case"` | `"active"`, `"disabled"` |
| `OwnerType` | `rename_all = "snake_case"` | `"user"`, `"team"` |
| `WorkbenchStatus` | `rename_all = "snake_case"` | `"active"`, `"archived"`, `"deleted"` |

---

## 一、模型定义验证 — 静态分析

---

### TC-001: 所有模型文件存在且使用 @freezed 注解

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（阻塞所有业务逻辑） |
| **类别** | 模型定义验证 / 静态结构 |
| **关联验收标准** | `build_runner build` 无错误 |

**前置条件**：
- TASK-001 完成，`kayak-frontend/` 项目可用
- `pubspec.yaml` 中已配置 `freezed: ^3.2.5`, `freezed_annotation: ^3.0.0`, `json_annotation: ^4.12.0`

**测试步骤**：

1. 枚举 `lib/models/` 下所有 `.dart` 源文件（排除 `.freezed.dart` 和 `.g.dart`）
2. 逐一验证以下文件存在：

| # | 期望文件 | 期望模型 |
|---|---------|---------|
| 1 | `user.dart` | User |
| 2 | `workbench.dart` | Workbench, CreateWorkbenchRequest |
| 3 | `device.dart` | Device, DeviceTreeNode |
| 4 | `point.dart` | Point, PointValue |
| 5 | `method.dart` | Method, MethodParameter |
| 6 | `experiment.dart` | Experiment, ExperimentStatus, ExperimentMessage |
| 7 | `team.dart` | Team |
| 8 | `common.dart` | ApiResponse\<T\>, PaginatedResponse\<T\>, AuthTokens |
| 9 | `protocol.dart` | ProtocolConfig (sealed union) |

3. 检查每个模型类（sealed class）声明包含 `@freezed` 注解和 `with _$Xxx` mixin
4. 检查每个模型包含 `factory Xxx.fromJson(Map<String, dynamic> json)` 工厂方法

**预期结果**：
- ✅ 9 个源文件全部存在
- ✅ 所有模型类使用 `@freezed sealed class Xxx with _$Xxx` 语法
- ✅ 所有模型包含 `fromJson` 工厂方法
- ✅ `import 'package:freezed_annotation/freezed_annotation.dart'` 存在

**失败判定**：
- ❌ 任一模型文件缺失
- ❌ 使用旧版 `abstract class` 语法（非 sealed class）
- ❌ 模型未用 `@freezed` 注解
- ❌ 缺少 `fromJson` 工厂方法

---

### TC-002: 所有模型字段类型与后端对齐

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（字段不对齐会引发运行时反序列化崩溃） |
| **类别** | 模型定义验证 / 类型安全 |
| **关联验收标准** | 字段类型与后端 API 响应完全对齐 |

**前置条件**：
- TC-001 通过（所有模型文件存在）

**测试步骤**：

逐一对照后端实体字段与前端 freezed 模型字段：

#### 2.1 User 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| id | `Uuid` | `String` | `id` | 必需 |
| email | `String` | `String` | `email` | 必需 |
| username | `Option<String>` | `String?` | `username` | 可选 |
| avatar_url | `Option<String>` | `String?` | `avatarUrl` | 可选 |
| status | `String` | `String` | `status` | 必需 |
| created_at | `DateTime<Utc>` | `DateTime` | `createdAt` | 必需 |
| updated_at | `DateTime<Utc>` | `DateTime` | `updatedAt` | 必需 |

#### 2.2 Workbench 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| id | `Uuid` | `String` | `id` | 必需 |
| name | `String` | `String` | `name` | 必需 |
| description | `Option<String>` | `String?` | `description` | 可选 |
| owner_type | `OwnerType` | `String` | `ownerType` | 必需 |
| owner_id | `Uuid` | `String` | `ownerId` | 必需 |
| status | `WorkbenchStatus` | `String` | `status` | 必需 |
| created_at | `DateTime<Utc>` | `DateTime` | `createdAt` | 必需 |
| updated_at | `DateTime<Utc>` | `DateTime` | `updatedAt` | 必需 |

#### 2.3 Device 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| id | `Uuid` | `String` | `id` | 必需 |
| workbench_id | `Uuid` | `String` | `workbenchId` | 必需 |
| parent_id | `Option<Uuid>` | `String?` | `parentId` | 可选 |
| name | `String` | `String` | `name` | 必需 |
| protocol_type | `ProtocolType` | `String` | `protocolType` | 必需 |
| protocol_params | `Option<Value>` | `Map<String, dynamic>?` | `protocolParams` | 可选 |
| manufacturer | `Option<String>` | `String?` | `manufacturer` | 可选 |
| model | `Option<String>` | `String?` | `model` | 可选 |
| sn | `Option<String>` | `String?` | `sn` | 可选 |
| status | `DeviceStatus` | `String` | `status` | 必需 |
| created_at | `DateTime<Utc>` | `DateTime` | `createdAt` | 必需 |
| updated_at | `DateTime<Utc>` | `DateTime` | `updatedAt` | 必需 |

#### 2.4 Point 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| id | `Uuid` | `String` | `id` | 必需 |
| device_id | `Uuid` | `String` | `deviceId` | 必需 |
| name | `String` | `String` | `name` | 必需 |
| data_type | `DataType` | `String` | `dataType` | 必需 |
| access_type | `AccessType` | `String` | `accessType` | 必需 |
| unit | `Option<String>` | `String?` | `unit` | 可选 |
| min_value | `Option<f64>` | `double?` | `minValue` | 可选 |
| max_value | `Option<f64>` | `double?` | `maxValue` | 可选 |
| default_value | `Option<String>` | `String?` | `defaultValue` | 可选 |
| status | `PointStatus` | `String` | `status` | 必需 |
| created_at | `DateTime<Utc>` | `DateTime` | `createdAt` | 必需 |
| updated_at | `DateTime<Utc>` | `DateTime` | `updatedAt` | 必需 |

#### 2.5 Experiment 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| id | `Uuid` | `String` | `id` | 必需 |
| user_id | `Uuid` | `String` | `userId` | 必需 |
| method_id | `Option<Uuid>` | `String?` | `methodId` | 可选 |
| name | `String` | `String` | `name` | 必需 |
| description | `Option<String>` | `String?` | `description` | 可选 |
| status | `ExperimentStatus` | `ExperimentStatus` (enum) | `status` | 必需 |
| owner_type | `String` | `String` | `ownerType` | 必需 |
| owner_id | `Uuid` | `String` | `ownerId` | 必需 |
| started_at | `Option<DateTime<Utc>>` | `DateTime?` | `startedAt` | 可选 |
| ended_at | `Option<DateTime<Utc>>` | `DateTime?` | `endedAt` | 可选 |
| created_at | `DateTime<Utc>` | `DateTime` | `createdAt` | 必需 |
| updated_at | `DateTime<Utc>` | `DateTime` | `updatedAt` | 必需 |

#### 2.6 Method 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| id | `Uuid` | `String` | `id` | 必需 |
| name | `String` | `String` | `name` | 必需 |
| description | `Option<String>` | `String?` | `description` | 可选 |
| process_definition | `Value` | `Map<String, dynamic>` | `processDefinition` | 必需 |
| parameter_schema | `Value` | `Map<String, dynamic>` | `parameterSchema` | 必需 |
| version | `i32` | `int` | `version` | 必需 |
| created_by | `Uuid` | `String` | `createdBy` | 必需 |
| created_at | `DateTime<Utc>` | `DateTime` | `createdAt` | 必需 |
| updated_at | `DateTime<Utc>` | `DateTime` | `updatedAt` | 必需 |

#### 2.7 AuthTokens 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| access_token | `String` | `String` | `accessToken` | 必需 |
| refresh_token | `String` | `String` | `refreshToken` | 必需 |
| token_type | `String` | `String` | `tokenType` | 必需 |
| expires_in | `i64` | `int` | `expiresIn` | 必需 |

#### 2.8 ApiResponse\<T\> 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| code | `u16` | `int` | `code` | 必需 |
| message | `String` | `String` | `message` | 必需 |
| data | `T` | `T` | `data` | 必需 |
| timestamp | `Option<String>` | `String?` | `timestamp` | 可选 |

#### 2.9 PaginatedResponse\<T\> 模型

| 字段 | 后端类型 (Rust) | 前端期望类型 (Dart) | 字段名 | 必需/可选 |
|------|-----------------|-------------------|--------|:------:|
| page | `u32` | `int` | `page` | 必需 |
| size | `u32` | `int` | `size` | 必需 |
| total | `u64` | `int` | `total` | 必需 |
| items | `Vec<T>` | `List<T>` | `items` | 必需 |
| has_next | `bool` | `bool` | `hasNext` | 必需 |
| has_prev | `bool` | `bool` | `hasPrev` | 必需 |

**预期结果**：
- ✅ 每个字段的类型、必需性、JSON key（`@JsonKey(name: 'snake_case_name')`）与上表对齐
- ✅ 所有 UUID 字段使用 `String` 类型（非 `Uuid` 类）
- ✅ 所有日期字段使用 `DateTime` 类型
- ✅ 所有枚举使用对应的 Dart enum（非 `String`），并使用 `@JsonEnum` 注解

**失败判定**：
- ❌ 必需字段标记为可选（或反之）
- ❌ 字段类型错误（如日期用 String、UUID 未用 String）
- ❌ snake_case → camelCase 映射缺失或错误
- ❌ 后端已有的字段在前端模型中缺失

---

### TC-003: build_runner build 成功生成所有代码

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P0 — CRITICAL**（无生成文件则无序列化） |
| **类别** | 构建验证 / 代码生成 |
| **关联验收标准** | `build_runner build` 无错误 |

**前置条件**：
- 所有模型 `.dart` 源文件已编写完成
- `build_runner` 和 `freezed` dev dependencies 已配置

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 执行 `dart run build_runner build --delete-conflicting-outputs`
3. 检查退出码
4. 检查 stdout/stderr 是否有错误信息
5. 逐一验证以下生成文件存在：

| # | 源文件 | 期望生成文件 |
|---|-------|------------|
| 1 | `user.dart` | `user.freezed.dart`, `user.g.dart` |
| 2 | `workbench.dart` | `workbench.freezed.dart`, `workbench.g.dart` |
| 3 | `device.dart` | `device.freezed.dart`, `device.g.dart` |
| 4 | `point.dart` | `point.freezed.dart`, `point.g.dart` |
| 5 | `method.dart` | `method.freezed.dart`, `method.g.dart` |
| 6 | `experiment.dart` | `experiment.freezed.dart`, `experiment.g.dart` |
| 7 | `team.dart` | `team.freezed.dart`, `team.g.dart` |
| 8 | `common.dart` | `common.freezed.dart`, `common.g.dart` |
| 9 | `protocol.dart` | `protocol.freezed.dart`, `protocol.g.dart` |

6. 执行 `flutter analyze` 确认生成文件不产生 lint 警告/错误

**预期结果**：
- ✅ `dart run build_runner build` exit code = 0
- ✅ 无 "Conflicting outputs" 错误（`--delete-conflicting-outputs` 处理）
- ✅ 9 × 2 = 18 个生成文件全部存在
- ✅ `flutter analyze` （排除生成文件后）零警告
- ✅ stderr 无错误输出

**失败判定**：
- ❌ `build_runner` 失败（exit code ≠ 0）
- ❌ 任一 `.freezed.dart` 或 `.g.dart` 未生成
- ❌ 生成文件包含编译错误
- ❌ 生成文件被 analyzer 检查到错误（应被 `analysis_options.yaml` 的 `exclude` 过滤）

---

## 二、JSON 序列化测试

---

### TC-004: User.fromJson 正确解析后端 GET /auth/me 响应

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — CRITICAL**（认证流程核心模型） |
| **类别** | 序列化 / JSON → Dart 反序列化 |

**前置条件**：
- `user.freezed.dart` + `user.g.dart` 已生成
- 测试文件中有 `import 'package:kayak_frontend/models/user.dart'`

**测试数据 4.1 — 正常用户（完整字段）**：

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "admin@kayak.local",
  "username": "Admin",
  "avatar_url": "https://example.com/avatar.png",
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**测试步骤**：

1. 将上述 JSON 字符串解析为 `Map<String, dynamic>`
2. 调用 `User.fromJson(jsonMap)`
3. 断言所有字段值匹配

**预期结果**：
- ✅ `user.id` = `"550e8400-e29b-41d4-a716-446655440000"`
- ✅ `user.email` = `"admin@kayak.local"`
- ✅ `user.username` = `"Admin"`
- ✅ `user.avatarUrl` = `"https://example.com/avatar.png"`
- ✅ `user.status` = `"active"`
- ✅ `user.createdAt` 是 `DateTime` 类型，值为 `2026-05-31 10:30:00.000Z`
- ✅ `user.updatedAt` 是 `DateTime` 类型

**失败判定**：
- ❌ 反序列化抛出异常
- ❌ 字段值与预期不匹配
- ❌ `DateTime` 解析类型错误

---

**测试数据 4.2 — 最小用户（可选字段为 null）**：

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "email": "newuser@kayak.local",
  "username": null,
  "avatar_url": null,
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**预期结果**：
- ✅ `user.username` = `null`
- ✅ `user.avatarUrl` = `null`
- ✅ 反序列化不抛出异常

---

**测试数据 4.3 — User 包裹在 ApiResponse 中（完整路径测试）**：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "admin@kayak.local",
    "username": "Admin",
    "avatar_url": null,
    "status": "active",
    "created_at": "2026-05-31T10:30:00Z",
    "updated_at": "2026-05-31T10:30:00Z"
  },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

**预期结果**：
- ✅ `ApiResponse<User>.fromJson(jsonMap)` 成功
- ✅ `response.code` = 200
- ✅ `response.data` 是 `User` 类型
- ✅ `response.data.email` = `"admin@kayak.local"`

---

### TC-005: Workbench.toJson 正确生成请求体

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — CRITICAL**（所有 CRUD 操作依赖正确请求体） |
| **类别** | 序列化 / Dart → JSON 序列化 |

**前置条件**：
- `workbench.freezed.dart` + `workbench.g.dart` 已生成

**测试数据 5.1 — 创建工作台请求**：

```dart
// 构造 CreateWorkbenchRequest
final request = CreateWorkbenchRequest(
  name: 'My Lab',
  description: 'Temperature test bench',
  ownerType: 'user',
);

// 期望生成的 JSON
final expectedJson = {
  'name': 'My Lab',
  'description': 'Temperature test bench',
  'owner_type': 'user',
};
```

**测试步骤**：

1. 构造 `CreateWorkbenchRequest` 实例
2. 调用 `request.toJson()`
3. 断言生成的 Map 与期望 JSON 匹配

**预期结果**：
- ✅ `toJson()` 返回的 `Map` 使用 snake_case key
- ✅ `name` = `"My Lab"`
- ✅ `description` = `"Temperature test bench"`
- ✅ `owner_type` = `"user"`
- ✅ 无多余字段（如 `id`、`status` 等后端自动生成的字段不应出现在请求体中）

**失败判定**：
- ❌ JSON key 使用 camelCase（非 snake_case）
- ❌ 包含了请求体中不应有的字段
- ❌ 可选字段 `null` 时在 JSON 中出现（除非使用 `includeIfNull: true`）

---

**测试数据 5.2 — Workbench 从 JSON 反序列化**：

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "name": "My Lab",
  "description": "Temperature test bench",
  "owner_type": "user",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**预期结果**：
- ✅ `workbench.id` = `"770e8400-e29b-41d4-a716-446655440002"`
- ✅ `workbench.name` = `"My Lab"`
- ✅ `workbench.ownerType` = `"user"`
- ✅ `workbench.status` = `"active"`
- ✅ `workbench.createdAt` 是 `DateTime` 类型

---

### TC-006: 嵌套对象与递归结构序列化（DeviceTreeNode）

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P1 — HIGH**（设备树是核心 UI 组件的数据源） |
| **类别** | 序列化 / 嵌套结构 |

**前置条件**：
- `device.freezed.dart` + `device.g.dart` 已生成
- `DeviceTreeNode` 模型定义支持递归子节点

**测试数据**：

```json
{
  "id": "880e8400-e29b-41d4-a716-446655440003",
  "workbench_id": "770e8400-e29b-41d4-a716-446655440002",
  "parent_id": null,
  "name": "Main Controller",
  "protocol_type": "modbus_tcp",
  "protocol_params": {
    "host": "192.168.1.1",
    "port": 502,
    "slave_id": 1,
    "timeout_ms": 3000
  },
  "manufacturer": "Siemens",
  "model": "S7-1200",
  "sn": "SN12345",
  "status": "online",
  "children": [
    {
      "id": "990e8400-e29b-41d4-a716-446655440004",
      "workbench_id": "770e8400-e29b-41d4-a716-446655440002",
      "parent_id": "880e8400-e29b-41d4-a716-446655440003",
      "name": "Temperature Sensor",
      "protocol_type": "virtual",
      "protocol_params": null,
      "manufacturer": null,
      "model": null,
      "sn": null,
      "status": "online",
      "children": []
    }
  ],
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**测试步骤**：

1. 将上述 JSON 反序列化为 `DeviceTreeNode`
2. 验证根节点字段
3. 验证子节点字段
4. 验证协议参数嵌套结构

**预期结果**：
- ✅ `node.name` = `"Main Controller"`
- ✅ `node.protocolType` = `"modbus_tcp"`
- ✅ `node.protocolParams["host"]` = `"192.168.1.1"`
- ✅ `node.protocolParams["port"]` = `502`
- ✅ `node.children` 长度为 1
- ✅ `node.children[0].name` = `"Temperature Sensor"`
- ✅ `node.children[0].parentId` = `"880e8400-e29b-41d4-a716-446655440003"`
- ✅ `node.children[0].children` 为空列表

**失败判定**：
- ❌ 子节点反序列化失败
- ❌ `protocol_params` 为 null 时抛出异常
- ❌ 递归引用导致栈溢出
- ❌ 子节点 `parentId` 与父节点 `id` 不匹配（数据本身如此）

---

### TC-007: 枚举类型正确映射

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL**（枚举值不对齐导致状态判断错误） |
| **类别** | 序列化 / 枚举映射 |

**前置条件**：
- 所有模型文件已生成
- 各枚举定义使用了 `@JsonEnum` 或自定义 `@JsonValue`

**测试数据 — ExperimentStatus 枚举**：

| JSON 值 (UPPERCASE) | 期望 Dart 枚举值 |
|---------------------|----------------|
| `"IDLE"` | `ExperimentStatus.idle` |
| `"LOADED"` | `ExperimentStatus.loaded` |
| `"RUNNING"` | `ExperimentStatus.running` |
| `"PAUSED"` | `ExperimentStatus.paused` |
| `"COMPLETED"` | `ExperimentStatus.completed` |
| `"ABORTED"` | `ExperimentStatus.aborted` |

> **关键风险**：后端 `ExperimentStatus` 使用 `rename_all = "UPPERCASE"` 序列化，前端必须适配大写的 JSON 值。

**测试数据 — ProtocolType 枚举**：

| JSON 值 (snake_case) | 期望 Dart 枚举值 |
|---------------------|----------------|
| `"virtual"` | `ProtocolType.virtual` |
| `"modbus_tcp"` | `ProtocolType.modbusTcp` |
| `"modbus_rtu"` | `ProtocolType.modbusRtu` |

**测试数据 — AccessType 枚举**：

| JSON 值 | 期望 Dart 枚举值 |
|---------|----------------|
| `"ro"` | `AccessType.ro` |
| `"wo"` | `AccessType.wo` |
| `"rw"` | `AccessType.rw` |

**测试数据 — DataType 枚举**：

| JSON 值 | 期望 Dart 枚举值 |
|---------|----------------|
| `"number"` | `DataType.number` |
| `"integer"` | `DataType.integer` |
| `"string"` | `DataType.string` |
| `"boolean"` | `DataType.boolean` |

**测试步骤**：

1. 对每个枚举，使用包含枚举值的完整 JSON 文档反序列化
2. 断言枚举字段值匹配
3. 将 Dart 模型 `toJson()` 后，验证枚举值序列化回原来的 JSON 格式

**预期结果**：
- ✅ 所有枚举值从 JSON 正确反序列化
- ✅ `toJson()` 输出的枚举值与后端期望的 JSON 值一致
- ✅ `ExperimentStatus.IDLE` → 写入试验JSON中含 `"status": "IDLE"`（大写）
- ✅ `DataType.number` → 写入测点JSON中含 `"data_type": "number"`

**失败判定**：
- ❌ `"IDLE"` 反序列化失败（大写不匹配）
- ❌ `"running"` 值被接受但实际后端发送 `"RUNNING"`
- ❌ 序列化后枚举值与后端不一致（如输出 `running` 而后期望 `RUNNING`）

---

### TC-008: DateTime ISO 8601 格式解析

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P1 — HIGH**（所有模型都含时间戳） |
| **类别** | 序列化 / 时间格式 |

**前置条件**：
- 所有包含 `DateTime` 字段的模型已生成

**测试数据**：

| # | JSON 中的时间字符串 | 期望 DateTime | 说明 |
|---|-------------------|--------------|------|
| 1 | `"2026-05-31T10:30:00Z"` | `2026-05-31 10:30:00.000Z` | 标准 ISO 8601 UTC |
| 2 | `"2026-05-31T10:30:00.123Z"` | `2026-05-31 10:30:00.123Z` | 带毫秒 |
| 3 | `"2026-05-31T10:30:00.123456Z"` | `2026-05-31 10:30:00.123456Z` | 带微秒 |
| 4 | `null` | `null` | 可选字段为 null |

**测试步骤**：

1. 构造包含以上时间值的 Experiment JSON
2. 反序列化为 `Experiment`
3. 断言 `startedAt`、`endedAt`、`createdAt` 等字段正确解析

**预期结果**：
- ✅ `DateTime` 解析支持标准 ISO 8601 格式
- ✅ 毫秒/微秒精度正确保留
- ✅ 可选时间字段为 null 时不抛出异常
- ✅ `toJson()` 输出符合 ISO 8601 格式

**失败判定**：
- ❌ 时间字符串解析抛出 `FormatException`
- ❌ 毫秒/微秒被截断或丢失
- ❌ null 时间字段导致解析失败

---

## 三、不可变性测试

---

### TC-009: freezed 对象不可变

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P1 — HIGH**（不可变性是 freezed 核心保证） |
| **类别** | 不可变性 / 语言特性 |

**前置条件**：
- 所有 freezed 模型已生成

**测试步骤**：

1. 通过 `User.fromJson(...)` 创建一个 User 实例
2. 尝试修改 `user.email = "new@email.com"`（应在编译期被阻止）
3. 验证以下不能在运行期执行（编译期错误）：

```dart
// 以下代码不应编译通过
final user = User.fromJson(json);
user.email = 'hacked@email.com'; // ❌ 编译错误
user.id = 'new-id';                // ❌ 编译错误
```

**预期结果**：
- ✅ 所有字段是 `final`，编译期阻止直接赋值
- ✅ Dart 分析器报告错误（如果尝试修改）
- ✅ 唯一修改方式是使用 `copyWith`

**失败判定**：
- ❌ 字段可被直接赋值（非 final）
- ❌ 存在 setter 方法
- ❌ 使用 `@unfreezed` 而非 `@freezed` 注解（除非有明确理由）

---

### TC-010: copyWith 方法正常工作

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P1 — HIGH**（Immutable 状态更新的唯一途径） |
| **类别** | 不可变性 / copyWith |

**前置条件**：
- 所有 freezed 模型已生成
- 测试文件已导入所有模型

**测试步骤**：

1. 创建一个 User 实例（含 `username: "OldName"`）
2. 调用 `user.copyWith(username: "NewName")`
3. 验证：
   - 新实例 `.username` = `"NewName"`
   - 原实例 `.username` 仍为 `"OldName"`（不可变）
   - 其他字段值不变

```dart
final oldUser = User(
  id: '1', email: 'test@test.com', username: 'OldName',
  avatarUrl: null, status: 'active',
  createdAt: DateTime.now(), updatedAt: DateTime.now(),
);

final newUser = oldUser.copyWith(username: 'NewName');

expect(newUser.username, 'NewName');
expect(oldUser.username, 'OldName');  // 原实例不变
expect(newUser.id, oldUser.id);       // 未修改字段相同
expect(newUser.email, oldUser.email);
```

**扩展测试**：

| # | copyWith 场景 | 验证点 |
|---|-------------|--------|
| 1 | `copyWith(username: null)` | `username` 变为 null |
| 2 | `copyWith()` | 返回相等但不相同的实例 |
| 3 | `workbench.copyWith(name: 'New', description: null)` | 同时修改多字段 |
| 4 | `experiment.copyWith(status: ExperimentStatus.running)` | 枚举字段 copyWith |

**预期结果**：
- ✅ `copyWith` 返回新实例
- ✅ 原实例不受影响
- ✅ 未指定的字段保持原值
- ✅ 显式传入 null 将字段设为 null（freezed v3 默认行为）
- ✅ `copyWith()` 无参数调用返回 `==` 相等的不同实例

**失败判定**：
- ❌ `copyWith` 修改了原实例
- ❌ `copyWith` 未实现（生成失败）
- ❌ 传入 null 不生效（需要 `@Default` 保护时另论）

---

## 四、边界与负向测试

---

### TC-011: 空 JSON 对象处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 边界测试 |

**测试数据**：

```json
{}
```

**测试步骤**：

1. 对每个模型分别尝试用空 JSON `{}` 调用 `fromJson`
2. 记录哪些模型需要 `required` 字段而有意义地失败
3. 验证错误信息清晰（如 "Missing required field: id" 类似信息）

**预期结果**：
- ❌ 所有模型的 `fromJson({})` 应失败（因为都有 required 字段）
- ✅ 错误信息包含缺失字段名称（而非泛化的 `type 'Null' is not a subtype`）
- ✅ 可选字段占多数的模型（如 `UpdateUserRequest`）若存在应可正确处理空对象

**失败判定**（反预期）：
- ❌ 空 JSON 反序列化成功（绕过了必需字段检查）
- ❌ 抛出泛化异常且无字段名提示

---

### TC-012: null 字段、类型错误和缺失字段处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P1 — HIGH**（防御后端 API 变更） |
| **类别** | 边界测试 |

**测试数据 12.1 — 可选字段为 null**：

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "admin@kayak.local",
  "username": null,
  "avatar_url": null,
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**预期结果**：
- ✅ `username` = `null`，`avatarUrl` = `null`
- ✅ 反序列化成功不抛异常

---

**测试数据 12.2 — 类型错误（id 是数字而非字符串）**：

```json
{
  "id": 12345,
  "email": "admin@kayak.local",
  "username": null,
  "avatar_url": null,
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**预期结果**：
- ❌ 抛出异常（`type 'int' is not a subtype of type 'String'` 或类似）
- ✅ 异常在 `fromJson` 调用处抛出（而非静默失败）

---

**测试数据 12.3 — 缺失必需字段**：

```json
{
  "email": "admin@kayak.local",
  "username": "Admin",
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z"
}
```

**预期结果**：
- ❌ 抛出异常（缺失 `id` 字段）
- ✅ 错误信息可识别缺失字段

---

**测试数据 12.4 — 多余未知字段（后端新增字段）**：

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "admin@kayak.local",
  "username": "Admin",
  "avatar_url": null,
  "status": "active",
  "created_at": "2026-05-31T10:30:00Z",
  "updated_at": "2026-05-31T10:30:00Z",
  "future_field": "this field does not exist yet"
}
```

**预期结果**：
- ✅ 反序列化成功（未知字段被忽略/不引发错误）— 这是 `json_serializable` 默认行为
- ✅ 已知字段正确解析
- ⚠️ 如果 `json_serializable` 配置了 `disallowUnrecognizedKeys: true`，则抛出异常

---

### TC-013: PaginatedResponse 泛型正确工作

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P1 — HIGH**（列表分页是通用模式） |
| **类别** | 序列化 / 泛型 |

**前置条件**：
- `common.dart` 中 `PaginatedResponse<T>` 已定义
- 至少一个实体模型（如 `Workbench`）已定义

**测试数据 — PaginatedResponse\<Workbench\>**：

```json
{
  "page": 1,
  "size": 10,
  "total": 42,
  "has_next": true,
  "has_prev": false,
  "items": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "name": "Lab 1",
      "description": "First lab",
      "owner_type": "user",
      "owner_id": "550e8400-e29b-41d4-a716-446655440000",
      "status": "active",
      "created_at": "2026-05-31T10:30:00Z",
      "updated_at": "2026-05-31T10:30:00Z"
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440003",
      "name": "Lab 2",
      "description": "Second lab",
      "owner_type": "user",
      "owner_id": "550e8400-e29b-41d4-a716-446655440000",
      "status": "archived",
      "created_at": "2026-05-30T08:00:00Z",
      "updated_at": "2026-05-30T08:00:00Z"
    }
  ]
}
```

**测试步骤**：

1. 将 JSON 反序列化为 `PaginatedResponse<Workbench>`
2. 验证分页元数据
3. 验证 items 列表中的每个元素是 `Workbench` 类型

**预期结果**：
- ✅ `response.page` = `1`
- ✅ `response.size` = `10`
- ✅ `response.total` = `42`
- ✅ `response.hasNext` = `true`
- ✅ `response.hasPrev` = `false`
- ✅ `response.items.length` = `2`
- ✅ `response.items[0]` 是 `Workbench` 且 `name` = `"Lab 1"`
- ✅ `response.items[1]` 是 `Workbench` 且 `name` = `"Lab 2"`

**测试数据 — 空列表**：

```json
{
  "page": 1,
  "size": 10,
  "total": 0,
  "has_next": false,
  "has_prev": false,
  "items": []
}
```

**预期结果**：
- ✅ `response.total` = `0`
- ✅ `response.items` = `[]`（空列表非 null）
- ✅ `response.hasNext` = `false`

**失败判定**：
- ❌ items 反序列化为 `List<dynamic>` 而非 `List<Workbench>`
- ❌ 空列表被反序列化为 null
- ❌ 泛型类型擦除导致 items 元素类型丢失

---

### TC-014: AuthTokens 序列化/反序列化双向验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P0 — CRITICAL**（登录流程核心模型） |
| **类别** | 序列化 / 双向验证 |

**测试数据 — 登录成功响应（含内嵌 User）**：

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**测试步骤**：

1. 将 JSON 反序列化为 `AuthTokens`
2. 验证所有字段
3. 将 `AuthTokens` 实例 `toJson()`
4. 再将 `toJson()` 输出反序列化为新的 `AuthTokens`
5. 验证两次反序列化的实例相等

**预期结果**：
- ✅ `authTokens.accessToken` = `"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
- ✅ `authTokens.refreshToken` = `"dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."`
- ✅ `authTokens.tokenType` = `"Bearer"`
- ✅ `authTokens.expiresIn` = `3600`
- ✅ `toJson()` → `fromJson()` 往返后相等

**失败判定**：
- ❌ `toJson()` 输出包含 camelCase key（应为 `access_token` / `refresh_token`）
- ❌ 往返后 `expires_in` 变成 String 类型

---

### TC-015: 设备状态枚举覆盖所有值

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P1 — HIGH**（状态不全会导致 UI 异常） |
| **类别** | 边界测试 / 枚举覆盖 |

**测试数据**：

```json
[
  { "status": "offline" },
  { "status": "online" },
  { "status": "error" }
]
```

**测试步骤**：

1. 构造三个设备 device JSON，status 分别为 `"offline"`, `"online"`, `"error"`
2. 逐一反序列化
3. 验证每个状态的枚举值映射正确

**预期结果**：
- ✅ `DeviceStatus`（或 String 字段）接受所有三个值
- ✅ 对后端可能返回但前端尚未支持的值（如未来新增 `Degraded`），不应崩溃（保守策略）

**失败判定**：
- ❌ 合法枚举值反序列化失败
- ❌ 未知枚举值导致整个模型解析崩溃（理想情况应降级为默认值或 String 透传）

---

### TC-016: ExperimentStatus 涵盖所有后端可能值

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P0 — CRITICAL**（试验状态是核心业务逻辑） |
| **类别** | 边界测试 / 枚举覆盖 |

**测试数据**：

| JSON `status` 值 | Dart 期望 |
|------------------|----------|
| `"IDLE"` | `ExperimentStatus.idle` |
| `"LOADED"` | `ExperimentStatus.loaded` |
| `"RUNNING"` | `ExperimentStatus.running` |
| `"PAUSED"` | `ExperimentStatus.paused` |
| `"COMPLETED"` | `ExperimentStatus.completed` |
| `"ABORTED"` | `ExperimentStatus.aborted` |

> ⚠️ 关键：后端使用 `rename_all = "UPPERCASE"`，JSON 中为 `"IDLE"` 而非 `"idle"`。

**测试步骤**：

1. 对每个状态值，构造最小 Experiment JSON
2. 反序列化
3. 断言状态枚举匹配

**预期结果**：
- ✅ 6 个状态值均可正确反序列化
- ✅ 枚举定义使用 `@JsonEnum` 并配置大写映射
- ✅ `toJson()` 输出大写状态值（与后端对齐）

**失败判定**：
- ❌ `"IDLE"` 大写值反序列化失败（使用了默认的 camelCase 映射）
- ❌ 缺失任一状态枚举值（如 `Aborted`）

---

### TC-017: ProtocolConfig sealed union 正确序列化三种协议

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P1 — HIGH**（设备配置是核心功能） |
| **类别** | 序列化 / sealed class |

**前置条件**：
- `protocol.dart` 中使用 freezed 3.2.5 sealed union 定义三种协议配置

**测试数据 17.1 — VirtualConfig**：

```json
{
  "type": "virtual",
  "mode": "random",
  "data_type": "number",
  "min": 0.0,
  "max": 100.0,
  "interval_ms": 1000
}
```

**测试数据 17.2 — ModbusTcpConfig**：

```json
{
  "type": "modbus_tcp",
  "host": "192.168.1.1",
  "port": 502,
  "slave_id": 1,
  "timeout_ms": 3000
}
```

**测试数据 17.3 — ModbusRtuConfig**：

```json
{
  "type": "modbus_rtu",
  "serial_port": "/dev/ttyUSB0",
  "baud_rate": 9600,
  "data_bits": 8,
  "stop_bits": 1,
  "parity": "none",
  "slave_id": 1,
  "timeout_ms": 3000
}
```

**测试步骤**：

1. 对三种配置分别反序列化
2. 验证 freezed sealed class 能根据 `type` 字段正确分发到不同子类型
3. 向下转型验证各子类型特有字段

**预期结果**：
- ✅ `ProtocolConfig` sealed union 三种子类型均可正确反序列化
- ✅ `when()` / `map()` 方法可正确匹配各子类型
- ✅ `toJson()` 包含 `type` 字段用于子类型标识
- ✅ `VirtualConfig.dataType` = `"number"`
- ✅ `ModbusTcpConfig.port` = `502`
- ✅ `ModbusRtuConfig.baudRate` = `9600`

**失败判定**：
- ❌ sealed union 无法根据 `type` 字段分发
- ❌ 子类型特有字段缺失
- ❌ `toJson()` 不包含子类型标识字段

---

## 五、集成 / 业务场景测试

---

### TC-018: 完整登录流程 — 请求 → 响应模型链

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 集成测试 / 完整流程 |

**测试描述**：模拟从发送登录请求到接收响应的完整模型链。

**步骤 1: 构造 LoginRequest**：

```dart
final loginReq = LoginRequest(
  email: 'admin@kayak.local',
  password: 'Admin123',
);
final loginReqJson = loginReq.toJson();
// 期望: { "email": "admin@kayak.local", "password": "Admin123" }
```

**步骤 2: 模拟后端响应**：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "admin@kayak.local",
      "username": "Admin"
    }
  },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

**步骤 3: 反序列化响应**：

```dart
final response = ApiResponse<AuthTokens>.fromJson(jsonMap);
```

**预期结果**：
- ✅ `LoginRequest.toJson()` 字段使用 snake_case
- ✅ `ApiResponse<AuthTokens>` 反序列化成功
- ✅ `response.data.accessToken` 非空
- ✅ `response.data.refreshToken` 非空
- ✅ Token 可在后续请求中作为 Bearer header 使用

---

### TC-019: 完整实验生命周期 — 状态流转模型链

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P1 — HIGH** |
| **类别** | 集成测试 / 状态流转 |

**测试描述**：验证试验在各个状态下的 JSON 都可正确反序列化。

**测试数据 — 各状态下的 Experiment JSON**：

| 状态 | started_at | ended_at |
|------|-----------|----------|
| IDLE | null | null |
| LOADED | null | null |
| RUNNING | "2026-05-31T10:30:00Z" | null |
| PAUSED | "2026-05-31T10:30:00Z" | null |
| COMPLETED | "2026-05-31T10:30:00Z" | "2026-05-31T12:45:00Z" |
| ABORTED | "2026-05-31T10:30:00Z" | "2026-05-31T10:35:00Z" |

**预期结果**：
- ✅ 所有状态均可反序列化
- ✅ IDLE/LOADED 状态的 `startedAt` = `null`
- ✅ COMPLETED/ABORTED 状态的 `endedAt` 非 null
- ✅ `toJson()` 输出中枚举值为大写

---

### TC-020: flatten analyze 零警告（生成后）

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P0 — HIGH**（任务硬性验收标准） |
| **类别** | 静态分析 |
| **关联验收标准** | `flutter analyze` 零警告 |

**前置条件**：
- TC-003 通过（`build_runner build` 成功）
- `analysis_options.yaml` 已配置排除生成文件

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 执行 `flutter analyze`
3. 检查退出码
4. 统计 `error` 和 `warning` 级别诊断
5. 验证排除规则正确（生成文件不参与分析）

**预期结果**：
- ✅ exit code = 0
- ✅ `error` 数量 = 0
- ✅ `warning` 数量 = 0
- ✅ 生成文件被正确排除（`analysis_options.yaml` 中的 `exclude` 生效）

**失败判定**：
- ❌ 存在任何 `error` 或 `warning`
- ❌ 生成文件分析报错（排除规则不生效）
- ❌ 存在 `unused_import` 等 lint 警告

---

## 六、测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | 模型文件存在性检查 |
| TC-002 | | | ⬜ 待执行 | 字段类型对齐检查 |
| TC-003 | | | ⬜ 待执行 | build_runner 代码生成 |
| TC-004 | | | ⬜ 待执行 | User JSON 反序列化 |
| TC-005 | | | ⬜ 待执行 | Workbench 请求体序列化 |
| TC-006 | | | ⬜ 待执行 | DeviceTreeNode 嵌套序列化 |
| TC-007 | | | ⬜ 待执行 | 枚举类型映射 |
| TC-008 | | | ⬜ 待执行 | DateTime ISO 8601 解析 |
| TC-009 | | | ⬜ 待执行 | freezed 不可变性 |
| TC-010 | | | ⬜ 待执行 | copyWith 方法 |
| TC-011 | | | ⬜ 待执行 | 空 JSON 对象处理 |
| TC-012 | | | ⬜ 待执行 | null/类型错误/缺失字段 |
| TC-013 | | | ⬜ 待执行 | PaginatedResponse 泛型 |
| TC-014 | | | ⬜ 待执行 | AuthTokens 双向验证 |
| TC-015 | | | ⬜ 待执行 | 设备状态枚举覆盖 |
| TC-016 | | | ⬜ 待执行 | ExperimentStatus 枚举覆盖 |
| TC-017 | | | ⬜ 待执行 | ProtocolConfig sealed union |
| TC-018 | | | ⬜ 待执行 | 完整登录流程模型链 |
| TC-019 | | | ⬜ 待执行 | 完整试验生命周期模型链 |
| TC-020 | | | ⬜ 待执行 | flutter analyze 零警告 |

---

## 七、后端风险点标记 🚨

> 以下是在对照后端代码时发现的与任务描述不一致之处，测试执行时需特别注意。

| # | 风险点 | 描述 | 影响 |
|---|--------|------|------|
| **R1** | `ExperimentStatus` 大写序列化 | 后端使用 `rename_all = "UPPERCASE"`，JSON 值为 `"IDLE"` 而非 `"idle"`。任务描述中的枚举列表为 `idle, loaded, running, paused, completed, error`，但后端实际为 `Idle, Loaded, Running, Paused, Completed, Aborted`（**无 error，有 Aborted**） | 前端枚举定义必须匹配 UPPERCASE 序列化，且状态列表需包含 Aborted 而非 error |
| **R2** | 后端已弃用旧状态机 | `Experiment.can_transition_to()` 已标记 `#[deprecated]`，实际使用 `StateMachine::is_allowed()` | 前端状态流转逻辑应与后端 StateMachine 规则对齐 |
| **R3** | Device 模型有额外字段 | 任务描述中 Device 字段包含 `address`, `port`, `virtualParameters`，但后端实际 Device 模型使用 `protocol_type` + `protocol_params` (JSON Value) + `manufacturer`/`model`/`sn` | 前端 Device 模型应与后端 DeviceResponse 对齐，使用 protocol_type/protocol_params 结构 |
| **R4** | TokenResponse 包含 user 子对象 | 任务描述中 AuthTokens 仅含 accessToken + refreshToken，但后端 `TokenResponse` 还包含 `token_type`, `expires_in`, `user` (UserAuthInfo) | 前端 AuthTokens 模型需要包含这 3 个额外字段 |
| **R5** | Point 模型字段差异 | 任务描述中 Point 含 `description` 字段，但后端 Point 模型无此字段，取而代之的是 `metadata` (JSON Value) | 前端 Point 模型应与后端对齐（无 description，建议添加 metadata） |
| **R6** | PagedResponse 兼容性 | 后端 `PagedResponse` 的 `size` 字段类型是 `u32`（Dart: int），且比任务描述多 `has_next` / `has_prev` | 前端需包含 `has_next`/`has_prev` 字段 |
| **R7** | Experiment 新增字段 | 后端 Experiment 有 `owner_type` (String) + `owner_id` (Uuid) 字段，以及 `started_at`/`ended_at` (Optional) | 前端模型需包含这些字段 |

**建议**：在执行测试前与 sw-tom 确认风险点，尤其是 R1（ExperimentStatus 枚举值差异），避免返工。

---

## 八、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| `build_runner build` 无错误 | TC-003 |
| 所有模型 fromJson/toJson 单元测试通过 | TC-004 ~ TC-019 |
| 覆盖边界情况（null 字段、空列表、错误类型） | TC-011, TC-012, TC-013 |
| `flutter analyze` 零警告 | TC-020 |
| 字段类型与后端 API 响应完全对齐 | TC-002, R1-R7 |
| 所有日期字段使用 `DateTime` 类型 | TC-002, TC-008 |
| 枚举类型使用 `enum` + `@JsonEnum` | TC-007, TC-015, TC-016 |
| 使用 `@JsonKey` 处理 snake_case → camelCase | TC-002, TC-005 |

---

## 九、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| 静态结构验证 | 3 | TC-001 ~ TC-003 |
| JSON 序列化 | 15 | TC-004 ~ TC-008（含子场景）, TC-013, TC-014, TC-017 |
| 不可变性验证 | 2 | TC-009, TC-010 |
| 边界和负向测试 | 5 | TC-011, TC-012（含子场景）, TC-015, TC-016 |
| 集成场景测试 | 2 | TC-018, TC-019 |
| 静态分析验证 | 1 | TC-020 |
| **合计** | **20** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 9 |
| P0 — HIGH | 4 |
| P1 — HIGH | 6 |
| P2 — MEDIUM | 1 |

---

## 十、附录：Dart 测试代码骨架

> 以下骨架代码供 sw-tom 开发时参考，sw-mike 在测试执行阶段会运行这些测试。

### 基础测试结构

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/models/user.dart';
import 'package:kayak_frontend/models/common.dart';

void main() {
  group('User Model', () {
    test('fromJson parses complete user', () {
      final json = jsonDecode('''
        {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "email": "admin@kayak.local",
          "username": "Admin",
          "avatar_url": "https://example.com/avatar.png",
          "status": "active",
          "created_at": "2026-05-31T10:30:00Z",
          "updated_at": "2026-05-31T10:30:00Z"
        }
      ''') as Map<String, dynamic>;

      final user = User.fromJson(json);

      expect(user.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(user.email, 'admin@kayak.local');
      expect(user.username, 'Admin');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.status, 'active');
      expect(user.createdAt, isA<DateTime>());
    });

    test('fromJson handles null optional fields', () {
      final json = jsonDecode('''
        {
          "id": "660e8400-e29b-41d4-a716-446655440001",
          "email": "newuser@kayak.local",
          "username": null,
          "avatar_url": null,
          "status": "active",
          "created_at": "2026-05-31T10:30:00Z",
          "updated_at": "2026-05-31T10:30:00Z"
        }
      ''') as Map<String, dynamic>;

      final user = User.fromJson(json);

      expect(user.username, isNull);
      expect(user.avatarUrl, isNull);
    });

    test('copyWith creates new instance', () {
      final user = User(
        id: '1',
        email: 'test@test.com',
        username: 'OldName',
        avatarUrl: null,
        status: 'active',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final updated = user.copyWith(username: 'NewName');

      expect(updated.username, 'NewName');
      expect(user.username, 'OldName'); // original unchanged
      expect(updated.id, user.id);       // other fields preserved
    });
  });

  group('ApiResponse', () {
    test('ApiResponse<User> deserializes correctly', () {
      final json = jsonDecode('''
        {
          "code": 200,
          "message": "success",
          "data": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "admin@kayak.local",
            "username": "Admin",
            "avatar_url": null,
            "status": "active",
            "created_at": "2026-05-31T10:30:00Z",
            "updated_at": "2026-05-31T10:30:00Z"
          },
          "timestamp": "2026-05-31T10:30:00.000Z"
        }
      ''') as Map<String, dynamic>;

      final response = ApiResponse<User>.fromJson(
        json,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );

      expect(response.code, 200);
      expect(response.data, isA<User>());
      expect(response.data!.email, 'admin@kayak.local');
    });
  });
}
```

> **注意**：泛型 `fromJson` 的 API 设计取决于实际实现（factory + generic 函数参数 或 `JsonConverter`）。以上骨架为示意性质。

---

**文档状态**: ✅ 已完成  
**下一步**: 提交 sw-tom 进行测试用例审查（sw-tom 检查测试逻辑是否与 freezed 3.2.5 的 sealed class API 对齐）
