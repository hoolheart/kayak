# TASK-002 详细设计 — 数据模型定义

## 1. 概述

### 1.1 目标
在 `kayak-frontend/lib/models/` 下创建 9 个数据模型文件，使用 freezed 3.2.5 sealed class 语法 + json_serializable，实现与后端 Rust API 完全对齐的 JSON 序列化/反序列化。

### 1.2 后端适配风险

| 风险 | 说明 | 处理方式 |
|------|------|---------|
| R1 | ExperimentStatus 后端使用 UPPERCASE 序列化 ("IDLE"/"LOADED"/"RUNNING"/"PAUSED"/"COMPLETED"/"ABORTED") | Dart enum 使用 `@JsonValue` 注解大写值 |
| R2 | Device 字段使用 protocol_type + protocol_params 而非 address/port | Device 模型按后端实际字段定义 |
| R3 | TokenResponse 含额外字段 token_type, expires_in, user | AuthTokens 可选字段包含 user |
| R4 | PagedResponse 含额外字段 has_next, has_prev | PagedResponse 包含这两个字段 |
| R5 | Experiment 含额外字段 owner_type, owner_id | Experiment 包含这两个字段 |
| R6 | Point 无 description 字段，含 metadata | Point 按后端无 description，有 metadata |

## 2. 模型定义

### 2.1 common.dart — 通用响应模型

**ApiResponse\<T\>**: 统一 API 响应包装
- code: int (必需) — HTTP 状态码
- message: String (必需) — 响应消息
- data: T? — 泛型数据负载
- timestamp: String? — ISO 8601 时间戳

**PaginatedResponse\<T\>**: 分页响应
- page: int (必需) — 当前页码
- size: int (必需) — 每页大小
- total: int (必需) — 总记录数
- items: List\<T\> (必需) — 数据项列表
- hasNext: bool (必需) — 是否有下一页
- hasPrev: bool (必需) — 是否有上一页

**AuthTokens**: 认证令牌
- accessToken: String (必需) — JWT 访问令牌
- refreshToken: String (必需) — 刷新令牌
- tokenType: String (必需) — Token 类型（"Bearer"）
- expiresIn: int (必需) — 过期时间（秒）
- user: User? — 关联用户信息

### 2.2 user.dart — 用户模型

**User**: 用户实体
- id: String (必需, UUID)
- email: String (必需)
- username: String? (可选)
- avatarUrl: String? (可选)
- status: String (必需)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

**LoginRequest**: 登录请求
- email: String (必需)
- password: String (必需)

**RegisterRequest**: 注册请求
- email: String (必需)
- password: String (必需)
- username: String? (可选)

### 2.3 workbench.dart — 工作台模型

**Workbench**: 工作台实体
- id: String (必需, UUID)
- name: String (必需)
- description: String? (可选)
- ownerType: String (必需)
- ownerId: String (必需, UUID)
- status: String (必需)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

**CreateWorkbenchRequest**: 创建工作台请求
- name: String (必需)
- description: String? (可选)
- ownerType: String (必需)

### 2.4 device.dart — 设备模型

**Device**: 设备实体
- id: String (必需, UUID)
- workbenchId: String (必需, UUID)
- parentId: String? (可选, UUID)
- name: String (必需)
- protocolType: String (必需, 对应 ProtocolType 枚举)
- protocolParams: Map\<String, dynamic\>? (可选)
- manufacturer: String? (可选)
- model: String? (可选)
- sn: String? (可选)
- status: String (必需)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

**DeviceTreeNode**: 设备树节点（递归结构）
- 同 Device 字段 + children: List\<DeviceTreeNode\> (必需, 默认空列表)

**ProtocolType**: 协议类型枚举
- virtual — "virtual"
- modbusTcp — "modbus_tcp"
- modbusRtu — "modbus_rtu"
- can — "can"
- visa — "visa"
- mqtt — "mqtt"

### 2.5 point.dart — 测点模型

**Point**: 测点实体
- id: String (必需, UUID)
- deviceId: String (必需, UUID)
- name: String (必需)
- dataType: String (必需, 对应 DataType 枚举)
- accessType: String (必需, 对应 AccessType 枚举)
- unit: String? (可选)
- minValue: double? (可选)
- maxValue: double? (可选)
- defaultValue: String? (可选)
- status: String (必需)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

**PointValue**: 测点值
- pointId: String (必需, UUID)
- value: dynamic? (可选)
- timestamp: String? (可选)

**DataType**: 数据类型枚举
- number — "number"
- integer — "integer"
- string — "string"
- boolean — "boolean"

**AccessType**: 访问类型枚举
- ro — "ro"
- wo — "wo"
- rw — "rw"

### 2.6 method.dart — 方法模型

**Method**: 试验方法实体
- id: String (必需, UUID)
- name: String (必需)
- description: String? (可选)
- processDefinition: Map\<String, dynamic\> (必需)
- parameterSchema: Map\<String, dynamic\> (必需)
- version: int (必需)
- createdBy: String (必需, UUID)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

**MethodParameter**: 方法参数
- key: String (必需)
- type: String (必需)
- label: String? (可选)
- defaultValue: dynamic? (可选)
- required: bool (必需, 默认 false)

### 2.7 experiment.dart — 试验模型

**Experiment**: 试验实体
- id: String (必需, UUID)
- userId: String (必需, UUID)
- methodId: String? (可选, UUID)
- name: String (必需)
- description: String? (可选)
- status: ExperimentStatus (必需)
- ownerType: String (必需)
- ownerId: String (必需, UUID)
- startedAt: DateTime? (可选)
- endedAt: DateTime? (可选)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

**ExperimentStatus**: 试验状态枚举（UPPERCASE 序列化）
- idle — "IDLE"
- loaded — "LOADED"
- running — "RUNNING"
- paused — "PAUSED"
- completed — "COMPLETED"
- aborted — "ABORTED"

### 2.8 team.dart — 团队模型

**Team**: 团队实体
- id: String (必需, UUID)
- name: String (必需)
- description: String? (可选)
- ownerId: String (必需, UUID)
- createdAt: DateTime (必需)
- updatedAt: DateTime (必需)

### 2.9 protocol.dart — 协议配置密封联合

**ProtocolConfig** (sealed union): 设备协议配置的密封联合类型

- VirtualConfig: type=virtual, mode, dataType, min, max, intervalMs
- ModbusTcpConfig: type=modbus_tcp, host, port, slaveId, timeoutMs
- ModbusRtuConfig: type=modbus_rtu, serialPort, baudRate, dataBits, stopBits, parity, slaveId, timeoutMs

## 3. JSON 映射规则

### 3.1 字段名映射
所有字段使用 `@JsonKey(name: 'snake_case_name')` 将 Dart camelCase 映射到 JSON snake_case。

### 3.2 枚举序列化
- ExperimentStatus: 使用 `@JsonValue` 显式注解 UPPERCASE 值
- 其他枚举: 使用 `@JsonValue` 显式注解 snake_case 值

### 3.3 日期格式
DateTime 字段使用 ISO 8601 格式，由 json_serializable 默认支持。

## 4. 文件清单

| # | 文件 | 包含模型 |
|---|------|---------|
| 1 | `lib/models/common.dart` | ApiResponse\<T\>, PaginatedResponse\<T\>, AuthTokens |
| 2 | `lib/models/user.dart` | User, LoginRequest, RegisterRequest |
| 3 | `lib/models/workbench.dart` | Workbench, CreateWorkbenchRequest |
| 4 | `lib/models/device.dart` | Device, DeviceTreeNode, ProtocolType |
| 5 | `lib/models/point.dart` | Point, PointValue, DataType, AccessType |
| 6 | `lib/models/method.dart` | Method, MethodParameter |
| 7 | `lib/models/experiment.dart` | Experiment, ExperimentStatus |
| 8 | `lib/models/team.dart` | Team |
| 9 | `lib/models/protocol.dart` | ProtocolConfig, VirtualConfig, ModbusTcpConfig, ModbusRtuConfig |

## 5. 技术决策

### 5.1 GenericArgumentFactories
ApiResponse\<T\> 和 PaginatedResponse\<T\> 需要使用 `genericArgumentFactories: true` 以支持泛型反序列化。

### 5.2 Recursive Types
DeviceTreeNode 包含 `List<DeviceTreeNode> children` 递归引用，freezed 3.x + json_serializable 原生支持。

### 5.3 AuthTokens.user
AuthTokens 中包含 `user` (User?) 可选字段，同时满足 TC-014（无 user 场景）和 TC-018（含 user 场景）。

### 5.4 CreateWorkbenchRequest
该模型仅用于 API 请求（toJson），不需要 fromJson 工厂方法。
