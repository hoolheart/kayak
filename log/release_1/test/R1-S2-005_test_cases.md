# R1-S2-005-A 设备连接测试 API 测试用例

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S2-005-A |
| 测试类型 | API 集成测试 + 边界测试 + 错误处理测试 |
| 测试范围 | `POST /api/v1/devices/{id}/test-connection` 端点 |
| 依赖模块 | DeviceService, DeviceManager, DriverFactory, DriverLifecycle |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-03 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [Virtual 设备连接测试](#2-virtual-设备连接测试)
3. [Modbus TCP 连接测试](#3-modbus-tcp-连接测试)
4. [Modbus RTU 连接测试](#4-modbus-rtu-连接测试)
5. [错误处理测试](#5-错误处理测试)
6. [安全与边界测试](#6-安全与边界测试)
7. [测试数据需求](#7-测试数据需求)
8. [测试环境](#8-测试环境)
9. [风险与假设](#9-风险与假设)
10. [测试用例汇总](#10-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证 `POST /api/v1/devices/{id}/test-connection` API 端点的正确性，确保：

- 设备连接测试成功返回 `{ code: 200, data: { connected: true, message: "...", latency_ms: N } }`
- 设备连接测试失败返回 `{ code: 200, data: { connected: false, error: "..." } }`
  或适当的错误响应（如 404, 400, 403）
- 三种协议类型（Virtual、Modbus TCP、Modbus RTU）的连接测试均正确工作
- 错误处理覆盖设备不存在、无效配置、超时、认证失败等场景
- 延迟测量准确且合理（Virtual < 10ms，Modbus TCP < 100ms，Modbus RTU < 200ms）

### 1.2 API 规格

```
POST /api/v1/devices/{id}/test-connection

Headers:
  Authorization: Bearer <token>
  Content-Type: application/json

Request body (可选 - 可覆盖设备存储的配置):
{
  "host": "192.168.1.100",
  "port": 502,
  "slave_id": 1,
  "timeout_ms": 5000
}

成功响应 (200):
{
  "code": 200,
  "message": "success",
  "data": {
    "connected": true,
    "message": "Connection successful",
    "latency_ms": 15
  }
}

失败响应 (200 - 连接失败但API正常):
{
  "code": 200,
  "message": "success",
  "data": {
    "connected": false,
    "error": "Connection timeout after 5s"
  }
}

错误响应 (4xx/5xx):
{
  "code": 404,
  "message": "Resource not found: Device not found",
  "timestamp": "2026-05-03T10:00:00Z"
}
```

### 1.3 涉及的架构组件

```
┌──────────────────────────────────────────────────────┐
│  POST /api/v1/devices/{id}/test-connection           │
│  device.rs  handler  (device::test_connection)       │
├──────────────────────────────────────────────────────┤
│  DeviceService  trait                                │
│  ├─ verify_device_ownership(user_id, device_id)      │
│  ├─ 获取设备配置 (protocol_type, protocol_params)     │
│  └─ test_connection(device_id, config)               │
├──────────────────────────────────────────────────────┤
│  DriverFactory                                       │
│  ├─ ProtocolType::Virtual   → VirtualDriver          │
│  ├─ ProtocolType::ModbusTcp → ModbusTcpDriver        │
│  └─ ProtocolType::ModbusRtu → ModbusRtuDriver        │
├──────────────────────────────────────────────────────┤
│  DriverLifecycle trait                               │
│  ├─ connect()   → Result<(), DriverError>            │
│  ├─ disconnect() → Result<(), DriverError>           │
│  └─ is_connected() → bool                            │
└──────────────────────────────────────────────────────┘
```

**注意**: 当前 `DriverFactory::create()` 仅实现了 `ProtocolType::Virtual`，Modbus TCP/RTU 返回 `ConfigError("Protocol ... not yet implemented")`。这些测试用例覆盖实现后的预期行为。

### 1.4 测试策略

- **集成测试**: 通过 HTTP 请求调用实际 API 端点
- **模拟设备**: VirtualDriver 可直接创建，Modbus TCP/RTU 需要模拟器
- **边界测试**: 超时边界、空配置、大延迟
- **安全测试**: 未认证访问、跨用户设备访问
- **错误注入**: 通过网络条件模拟（如 iptables、串口不可用）

---

## 2. Virtual 设备连接测试

### TC-V01: Virtual 设备连接成功 - 默认配置

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-V01 |
| **优先级** | P0 |
| **测试类型** | 集成测试 |
| **前置条件** | 1. 已创建 Workbench（用户拥有）<br>2. 已创建 Virtual 类型 Device（使用默认配置）<br>3. 已获取有效 JWT Token |
| **测试步骤** | 1. 发送 `POST /api/v1/devices/{device_id}/test-connection`<br>2. 请求体为空 `{}` 或不发送（使用设备已存储配置）<br>3. 检查响应状态码和 JSON 结构 |
| **预期结果** | HTTP 200<br>`data.connected` = `true`<br>`data.latency_ms` >= 0 且 < 50ms<br>`data.message` 包含 "successful" 或类似文本 |
| **断言** | `assert_eq!(response.status(), 200);`<br>`assert!(body.data.connected);`<br>`assert!(body.data.latency_ms < 50);` |
| **备注** | VirtualDriver.connect() 是内存操作，延迟应极低 |

### TC-V02: Virtual 设备连接成功 - 自定义配置（Random 模式）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-V02 |
| **优先级** | P0 |
| **测试类型** | 集成测试 |
| **前置条件** | 1. 已创建 Virtual 类型 Device，protocol_params 包含自定义配置 |
| **测试步骤** | 1. 创建设备时提供如下 protocol_params：<br>`{"mode":"Random","data_type":"Number","access_type":"RW","min_value":0.0,"max_value":100.0,"sample_interval_ms":500}`<br>2. 发送 `POST /api/v1/devices/{device_id}/test-connection`<br>3. 验证响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `true`<br>`data.latency_ms` >= 0 |
| **断言** | `assert!(body.data.connected);`<br>`assert!(body.data.latency_ms >= 0);` |

### TC-V03: Virtual 设备连接成功 - Fixed 模式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-V03 |
| **优先级** | P1 |
| **测试类型** | 集成测试 |
| **前置条件** | Virtual 设备配置为 Fixed 模式，`fixed_value` = 42.0 |
| **测试步骤** | 1. 创建 Fixed 模式 Virtual 设备<br>2. 发送连接测试请求<br>3. 验证连接成功 |
| **预期结果** | HTTP 200，connected = true |
| **备注** | 验证 Fixed 模式下配置解析正确，不影响连接逻辑 |

### TC-V04: Virtual 设备重复连接测试（幂等性）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-V04 |
| **优先级** | P1 |
| **测试类型** | 集成测试 |
| **前置条件** | 已创建 Virtual 类型 Device |
| **测试步骤** | 1. 发送第一次 `test-connection` 请求<br>2. 发送第二次 `test-connection` 请求<br>3. 验证两次均返回成功 |
| **预期结果** | 两次请求均返回 HTTP 200<br>`data.connected` = `true`（两次）<br>第二次不应返回 AlreadyConnected 错误 |
| **断言** | `assert!(first_response.data.connected);`<br>`assert!(second_response.data.connected);` |
| **备注** | VirtualDriver.connect() 对重复连接实现幂等（直接返回 Ok） |

### TC-V05: Virtual 设备连接后状态验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-V05 |
| **优先级** | P1 |
| **测试类型** | 集成测试 |
| **前置条件** | Virtual 设备已创建 |
| **测试步骤** | 1. 请求连接测试<br>2. 验证连接成功<br>3. 通过 GET /api/v1/devices/{id} 获取设备状态<br>4. 验证设备状态是否更新为 Online |
| **预期结果** | 连接测试后设备 status 变为 `online` |
| **备注** | 取决于具体实现是否更新设备状态（PRD 未明确，建议测试后清理） |

### TC-V06: Virtual 设备连接 - 空 protocol_params

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-V06 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | 设备 protocol_params 为 null/None |
| **测试步骤** | 1. 创建 Virtual 设备时不提供 protocol_params<br>2. 发送 test-connection 请求（不附带 body）<br>3. 验证响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `true`（使用 VirtualConfig::default()） |
| **备注** | VirtualConfig::default() 提供有效默认值 |

---

## 3. Modbus TCP 连接测试

### TC-MTCP01: Modbus TCP 连接成功（连接模拟器）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP01 |
| **优先级** | P0 |
| **测试类型** | 集成测试 |
| **前置条件** | 1. Modbus TCP 模拟器运行在 `127.0.0.1:1502`<br>2. 已创建 ModbusTcp 类型 Device，protocol_params: `{"host":"127.0.0.1","port":1502,"slave_id":1,"timeout_ms":5000}`<br>3. 有效 JWT Token |
| **测试步骤** | 1. 启动 Modbus TCP 模拟器<br>2. 发送 `POST /api/v1/devices/{device_id}/test-connection`<br>3. 使用设备存储的配置<br>4. 验证响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `true`<br>`data.message` 包含 "successful"<br>`data.latency_ms` >= 0 且 < 100ms（局域网延迟期望） |
| **断言** | `assert_eq!(response.status(), 200);`<br>`assert!(body.data.connected);`<br>`assert!(body.data.latency_ms < 100)` |
| **备注** | PRD 要求 Modbus TCP 单次响应 < 100ms |

### TC-MTCP02: Modbus TCP 连接成功 - 带请求体覆盖配置

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP02 |
| **优先级** | P1 |
| **测试类型** | 集成测试 |
| **前置条件** | 1. 模拟器运行在 `127.0.0.1:1502`<br>2. 设备已有默认配置（可能 host 不同） |
| **测试步骤** | 1. 发送请求，body 包含正确的连接参数：<br>`{"host":"127.0.0.1","port":1502,"slave_id":1}`<br>2. 验证使用请求体配置而非设备存储配置 |
| **预期结果** | HTTP 200，connected = true |
| **备注** | 请求体临时覆盖设备配置，不持久化 |

### TC-MTCP03: Modbus TCP 连接失败 - 主机不可达

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP03 |
| **优先级** | P0 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 已创建 ModbusTcp 类型 Device，host 为不可达地址 |
| **测试步骤** | 1. 设备配置 host = `"192.0.2.1"`（TEST-NET-1，不可路由）<br>2. 发送 test-connection 请求<br>3. 超时时间设为 2000ms<br>4. 验证响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含超时相关描述<br>`data.latency_ms` ≈ timeout_ms |
| **断言** | `assert_eq!(response.status(), 200);`<br>`assert!(!body.data.connected);`<br>`assert!(body.data.error.contains("timeout")` 或 `"unreachable")` |

### TC-MTCP04: Modbus TCP 连接失败 - 端口无服务（Connection Refused）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP04 |
| **优先级** | P0 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 设备配置指向 localhost 未监听的端口 |
| **测试步骤** | 1. 设备配置 host = `"127.0.0.1"`, port = `19999`（确认无服务监听）<br>2. 发送 test-connection 请求<br>3. 验证错误响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "refused" 或 "Connection refused" 或 IoError 描述 |
| **断言** | `assert!(!body.data.connected);`<br>`assert!(body.data.error.len() > 0);` |

### TC-MTCP05: Modbus TCP 连接失败 - 无效从站 ID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP05 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | 1. Modbus TCP 模拟器运行<br>2. 模拟器只响应 slave_id=1 |
| **测试步骤** | 1. 设备配置 slave_id = `247`（最大值但模拟器不响应）<br>2. 或使用 slave_id = `0`（广播地址，可能不支持）<br>3. 发送 test-connection 请求<br>4. 验证响应 |
| **预期结果** | 取决于模拟器行为：<br>- 若模拟器拒绝未知 slave_id：返回 connected=false<br>- 若模拟器忽略 slave_id：返回 connected=true |
| **备注** | 此用例验证从站ID匹配逻辑 |

### TC-MTCP06: Modbus TCP 连接成功 - 自定义端口

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP06 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | Modbus TCP 模拟器运行在非标准端口 `2502` |
| **测试步骤** | 1. 设备配置 port = `2502`<br>2. 发送 test-connection 请求<br>3. 验证连接成功 |
| **预期结果** | HTTP 200，connected = true |
| **备注** | 验证非标准端口配置正确传递 |

### TC-MTCP07: Modbus TCP 连接失败 - 超时配置过短

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MTCP07 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | Modbus TCP 模拟器有 200ms 处理延迟 |
| **测试步骤** | 1. 设备配置 timeout_ms = `100`（远小于模拟器响应时间）<br>2. 发送 test-connection 请求<br>3. 验证超时响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "timeout"<br>`data.latency_ms` >= 100 |

---

## 4. Modbus RTU 连接测试

### TC-MRTU01: Modbus RTU 连接成功（连接模拟器 - 虚拟串口对）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU01 |
| **优先级** | P0 |
| **测试类型** | 集成测试 |
| **前置条件** | 1. Modbus RTU 模拟器运行（使用虚拟串口对，如 socat 创建）<br>2. 已创建 ModbusRtu 类型 Device，protocol_params: `{"port":"/tmp/vmodbus0","baud_rate":9600,"data_bits":8,"stop_bits":1,"parity":"None","slave_id":1,"timeout_ms":1000}`<br>3. 有效 JWT Token |
| **测试步骤** | 1. 创建虚拟串口对：`socat -d -d PTY,link=/tmp/vmodbus0 PTY,link=/tmp/vmodbus1`<br>2. 启动 RTU 模拟器连接 `/tmp/vmodbus1`<br>3. 发送 `POST /api/v1/devices/{device_id}/test-connection`<br>4. 验证连接成功 |
| **预期结果** | HTTP 200<br>`data.connected` = `true`<br>`data.latency_ms` >= 0 且 < 200ms（9600 波特率） |
| **断言** | `assert!(body.data.connected);`<br>`assert!(body.data.latency_ms < 200);` |
| **备注** | PRD 要求 Modbus RTU 9600 波特率下响应 < 200ms |

### TC-MRTU02: Modbus RTU 连接成功 - 不同波特率（115200）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU02 |
| **优先级** | P1 |
| **测试类型** | 集成测试 |
| **前置条件** | Modbus RTU 模拟器配置为 115200 波特率 |
| **测试步骤** | 1. 设备配置 baud_rate = `115200`<br>2. 发送 test-connection 请求<br>3. 验证低延迟连接 |
| **预期结果** | HTTP 200<br>`data.connected` = `true`<br>`data.latency_ms` < 50ms（高波特率） |
| **备注** | 验证所有 PRD 定义的波特率（9600/19200/38400/57600/115200）均可用 |

### TC-MRTU03: Modbus RTU 连接成功 - Even 校验

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU03 |
| **优先级** | P1 |
| **测试类型** | 集成测试 |
| **前置条件** | Modbus RTU 模拟器配置 Even 校验 |
| **测试步骤** | 1. 设备配置 parity = `"Even"`<br>2. 发送 test-connection 请求<br>3. 验证连接成功 |
| **预期结果** | HTTP 200，connected = true |
| **备注** | 验证 PRD 所有校验模式（None/Even/Odd） |

### TC-MRTU04: Modbus RTU 连接失败 - 串口不存在

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU04 |
| **优先级** | P0 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 设备配置指向不存在的串口 |
| **测试步骤** | 1. 设备配置 port = `"/dev/ttyUSB999"`（确认不存在）<br>2. 发送 test-connection 请求<br>3. 验证错误响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "not found" 或 "No such file" 或 "port not available" |
| **断言** | `assert!(!body.data.connected);`<br>`assert!(body.data.error.len() > 0);` |

### TC-MRTU05: Modbus RTU 连接失败 - 波特率不匹配

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU05 |
| **优先级** | P1 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 1. Modbus RTU 模拟器运行在 9600 波特率<br>2. 设备配置为 19200 波特率 |
| **测试步骤** | 1. 设备配置 baud_rate = `19200`（模拟器为 9600）<br>2. 发送 test-connection 请求<br>3. 验证连接失败或 CRC 错误 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "timeout" 或 "CRC" 或 "no response" |

### TC-MRTU06: Modbus RTU 连接失败 - 无设备应答

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU06 |
| **优先级** | P1 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 串口存在但无 Modbus 设备连接 |
| **测试步骤** | 1. 设备配置指向真实串口但有物理连接但无设备应答<br>2. 或使用虚拟串口只有一端打开<br>3. 发送 test-connection 请求 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "timeout" 或 "no response" |

### TC-MRTU07: Modbus RTU 连接成功 - 不同数据位/停止位组合

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-MRTU07 |
| **优先级** | P2 |
| **测试类型** | 边界测试 |
| **前置条件** | 模拟器配置 data_bits=7, stop_bits=2 |
| **测试步骤** | 1. 设备配置 data_bits = `7`, stop_bits = `2`<br>2. 发送 test-connection 请求<br>3. 验证连接成功 |
| **预期结果** | HTTP 200，connected = true |
| **备注** | 覆盖 PRD 所有配置组合候选 |

---

## 5. 错误处理测试

### TC-ERR01: 设备不存在 - 无效 UUID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR01 |
| **优先级** | P0 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 有效 JWT Token |
| **测试步骤** | 1. 使用随机 UUID 作为 device_id<br>2. 发送 `POST /api/v1/devices/{random_uuid}/test-connection`<br>3. 验证 404 响应 |
| **预期结果** | HTTP 404<br>`code` = 404<br>`message` 包含 "not found" |
| **断言** | `assert_eq!(response.status(), 404);`<br>`assert!(body.message.contains("not found"));` |

### TC-ERR02: 请求超时 - Virtual 设备模拟

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR02 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | 使用低超时值（通过请求体传入） |
| **测试步骤** | 1. 对 Virtual 设备发送 test-connection<br>2. 请求体传入 timeout_ms = `0` 或 `1`<br>3. 验证行为 |
| **预期结果** | 两种可能：<br>- 若超时切断了 connect 操作：返回 connected=false<br>- 若 Virtual 连接无视超时：返回 connected=true<br>需与 sw-tom 确认行为后确定 |
| **备注** | 此测试用于验证超时机制的边界行为 |

### TC-ERR03: 无效配置 - Virtual 设备 min >= max

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR03 |
| **优先级** | P1 |
| **测试类型** | 错误处理测试 |
| **前置条件** | Virtual 设备配置为 min_value >= max_value |
| **测试步骤** | 1. 设备 protocol_params 包含 `"min_value": 100.0, "max_value": 50.0`<br>2. 发送 test-connection 请求<br>3. 验证错误响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "Invalid range" 或配置验证错误描述 |
| **备注** | VirtualConfig::validate 会检查此条件 |

### TC-ERR04: 无效配置 - Modbus TCP 缺少 host

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR04 |
| **优先级** | P0 |
| **测试类型** | 错误处理测试 |
| **前置条件** | ModbusTcp 设备 protocol_params 缺少必需字段 |
| **测试步骤** | 1. 设备 protocol_params = `{"port": 502}`（缺少 host）<br>2. 发送 test-connection 请求<br>3. 验证错误响应 |
| **预期结果** | HTTP 200 或 HTTP 400<br>`data.connected` = `false`<br>`data.error` 包含 "host" 或配置验证错误 |
| **备注** | 若实现层面先做配置验证，可能返回 400 |

### TC-ERR05: 无效配置 - Modbus RTU 非法波特率

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR05 |
| **优先级** | P1 |
| **测试类型** | 错误处理测试 |
| **前置条件** | ModbusRtu 设备配置 baud_rate 为不支持的值 |
| **测试步骤** | 1. 设备 protocol_params 包含 `"baud_rate": 99999`<br>2. 发送 test-connection 请求<br>3. 验证错误响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "baud_rate" 或 "Invalid" |

### TC-ERR06: 请求体格式错误 - 非法 JSON

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR06 |
| **优先级** | P1 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 有效设备和 Token |
| **测试步骤** | 1. 发送 test-connection 请求<br>2. Content-Type = application/json<br>3. Body = `{invalid json}`<br>4. 验证 400 响应 |
| **预期结果** | HTTP 400<br>`code` = 400<br>`message` 包含 parse error 相关信息 |
| **备注** | axum Json extractor 自动处理 JSON 解析错误 |

### TC-ERR07: 未认证访问

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR07 |
| **优先级** | P0 |
| **测试类型** | 安全测试 |
| **前置条件** | 设备已存在 |
| **测试步骤** | 1. 不发送 Authorization header<br>2. 发送 test-connection 请求<br>3. 验证 401 响应 |
| **预期结果** | HTTP 401<br>`code` = 401<br>`message` 包含 "Unauthorized" |
| **断言** | `assert_eq!(response.status(), 401);` |

### TC-ERR08: 跨用户设备访问（Forbidden）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR08 |
| **优先级** | P0 |
| **测试类型** | 安全测试 |
| **前置条件** | 1. User A 创建设备<br>2. User B 已登录且有 Token |
| **测试步骤** | 1. 使用 User B 的 Token<br>2. 发送 test-connection 请求到 User A 的设备<br>3. 验证 403 响应 |
| **预期结果** | HTTP 403<br>`code` = 403<br>`message` 包含 "Forbidden" 或 "Access denied" |
| **断言** | `assert_eq!(response.status(), 403);` |

### TC-ERR09: 不支持的协议类型

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR09 |
| **优先级** | P1 |
| **测试类型** | 错误处理测试 |
| **前置条件** | 设备 protocol_type 为 Can/Visa/Mqtt（尚未实现） |
| **测试步骤** | 1. 直接插入数据库：protocol_type = `"can"`<br>2. 发送 test-connection 请求<br>3. 验证错误响应 |
| **预期结果** | HTTP 200<br>`data.connected` = `false`<br>`data.error` 包含 "not yet implemented" 或类似 |
| **备注** | DriverFactory::create 对未实现协议返回 ConfigError |

### TC-ERR10: 请求体超大内容

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-ERR10 |
| **优先级** | P2 |
| **测试类型** | 边界测试 |
| **前置条件** | 有效设备和 Token |
| **测试步骤** | 1. 发送 test-connection 请求<br>2. Body 为超大 JSON (如 10MB)<br>3. 验证响应 |
| **预期结果** | HTTP 413 或 400<br>拒绝处理过大的请求体 |

---

## 6. 安全与边界测试

### TC-SEC01: 无效 JWT Token

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-SEC01 |
| **优先级** | P1 |
| **测试类型** | 安全测试 |
| **前置条件** | N/A |
| **测试步骤** | 1. 发送 Authorization: Bearer invalid_token<br>2. 验证 401 响应 |
| **预期结果** | HTTP 401 |

### TC-SEC02: 过期 JWT Token

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-SEC02 |
| **优先级** | P1 |
| **测试类型** | 安全测试 |
| **前置条件** | 生成已过期的 Token |
| **测试步骤** | 1. 使用过期 Token<br>2. 发送 test-connection 请求<br>3. 验证 401 响应 |
| **预期结果** | HTTP 401<br>`message` 包含 "expired" |

### TC-SEC03: SQL 注入 - device_id 路径参数

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-SEC03 |
| **优先级** | P1 |
| **测试类型** | 安全测试 |
| **前置条件** | 有效 Token |
| **测试步骤** | 1. 发送请求到 `POST /api/v1/devices/1' OR '1'='1/test-connection`<br>2. 验证不会被解释为 SQL |
| **预期结果** | HTTP 400 或 404<br>UUID 解析失败，返回错误 |
| **备注** | UUID 类型解析会自动拒绝非 UUID 输入 |

### TC-BND01: latency_ms 不是负数

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-BND01 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | 任何设备连接成功 |
| **测试步骤** | 1. 发送 test-connection 请求<br>2. 验证 latency_ms >= 0 |
| **预期结果** | `data.latency_ms` >= 0（绝对不会为负数） |

### TC-BND02: 响应包含所有必需字段

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-BND02 |
| **优先级** | P0 |
| **测试类型** | 结构验证 |
| **前置条件** | 任何设备连接测试 |
| **测试步骤** | 1. 发送 test-connection 请求<br>2. 验证成功响应的 JSON 结构完整性 |
| **预期结果** | 成功时：`data` 包含 `connected` (bool), `message` (string), `latency_ms` (number)<br>失败时：`data` 包含 `connected` (bool=false), `error` (string) |

### TC-BND03: message 字段不为空

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-BND03 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |
| **前置条件** | 连接成功 |
| **测试步骤** | 1. 验证 message 字段非空字符串 |
| **预期结果** | `data.message.len() > 0` |

### TC-BND04: 并发请求 - 同一设备多次连接测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-BND04 |
| **优先级** | P2 |
| **测试类型** | 并发测试 |
| **前置条件** | Virtual 设备 |
| **测试步骤** | 1. 同时发送 5 个 test-connection 请求<br>2. 验证所有请求均返回成功或适当错误 |
| **预期结果** | 所有请求返回 HTTP 200<br>至少一个 connected = true<br>无 500 错误 |

---

## 7. 测试数据需求

### 7.1 测试用户

| 用户 | 用途 |
|------|------|
| `test_user_a` (owner) | 拥有 Workbench 和设备的所有者 |
| `test_user_b` (intruder) | 无权限访问的另一个用户 |

### 7.2 测试 Workbench

| Workbench | 用途 |
|-----------|------|
| `wb-virt-001` | 包含 Virtual 设备 |
| `wb-modbus-tcp-001` | 包含 Modbus TCP 设备 |
| `wb-modbus-rtu-001` | 包含 Modbus RTU 设备 |

### 7.3 测试设备配置

**Virtual 设备 (DEV-V01)**:
```json
{
  "mode": "Random",
  "data_type": "Number",
  "access_type": "RO",
  "min_value": 0.0,
  "max_value": 100.0,
  "sample_interval_ms": 1000
}
```

**Virtual 设备 - Fixed 模式 (DEV-V02)**:
```json
{
  "mode": "Fixed",
  "data_type": "Number",
  "access_type": "RW",
  "min_value": 0.0,
  "max_value": 100.0,
  "fixed_value": { "Number": 42.0 },
  "sample_interval_ms": 500
}
```

**Virtual 设备 - 空配置 (DEV-V03)**:
```json
null
```

**Modbus TCP 设备 (DEV-MTCP01)**:
```json
{
  "host": "127.0.0.1",
  "port": 1502,
  "slave_id": 1,
  "timeout_ms": 5000,
  "connection_pool_size": 4
}
```

**Modbus TCP 设备 - 不可达 (DEV-MTCP02)**:
```json
{
  "host": "192.0.2.1",
  "port": 502,
  "slave_id": 1,
  "timeout_ms": 2000
}
```

**Modbus TCP 设备 - 缺少 host (DEV-MTCP03)**:
```json
{
  "port": 502,
  "slave_id": 1
}
```

**Modbus RTU 设备 (DEV-MRTU01)**:
```json
{
  "port": "/tmp/vmodbus0",
  "baud_rate": 9600,
  "data_bits": 8,
  "stop_bits": 1,
  "parity": "None",
  "slave_id": 1,
  "timeout_ms": 1000
}
```

**Modbus RTU 设备 - 串口不存在 (DEV-MRTU02)**:
```json
{
  "port": "/dev/ttyUSB999",
  "baud_rate": 9600,
  "data_bits": 8,
  "stop_bits": 1,
  "parity": "None",
  "slave_id": 1,
  "timeout_ms": 1000
}
```

### 7.4 模拟器要求

| 模拟器 | 说明 |
|--------|------|
| Modbus TCP Simulator | 监听 `127.0.0.1:1502`，支持 slave_id=1，响应 Read Holding Registers (FC 0x03) |
| Modbus RTU Simulator | 通过虚拟串口对 `/tmp/vmodbus0` ↔ `/tmp/vmodbus1` 通信，9600-8-N-1 |

### 7.5 测试工具

| 工具 | 用途 |
|------|------|
| `curl` / `httpie` | 手动发送 HTTP 请求 |
| `socat` | 创建虚拟串口对（Linux/macOS） |
| `cargo test` | 运行 Rust 集成测试 |
| `iptables` / `pf` | 模拟网络故障（超时场景） |

---

## 8. 测试环境

### 8.1 软件环境

| 组件 | 版本/要求 |
|------|----------|
| OS | macOS 14+ / Linux (Ubuntu 22.04+) |
| Rust | 1.80+ |
| axum | 0.7.x |
| PostgreSQL | 16+ |
| Flutter | 3.24+ (前端配合测试) |
| socat | 用于虚拟串口 |
| Modbus TCP Simulator | R1-SIM-001 产物 |
| Modbus RTU Simulator | R1-SIM-002 产物 |

### 8.2 测试数据库

- 每次测试运行使用独立数据库或事务回滚
- 测试数据通过 fixtures 自动创建
- 测试完成后清理所有测试数据

### 8.3 网络条件

| 测试场景 | 网络条件 |
|----------|---------|
| Virtual 连接 | localhost |
| Modbus TCP 成功 | localhost（模拟器） |
| Modbus TCP 超时 | 使用 TEST-NET 地址 (192.0.2.0/24) |
| Modbus TCP 拒绝 | localhost 未监听端口 |
| Modbus RTU | 虚拟串口对 |

---

## 9. 风险与假设

### 9.1 假设

| 编号 | 假设 | 影响 |
|------|------|------|
| A1 | `test-connection` 端点使用 RequireAuth 中间件 | 所有测试需要有效 Token |
| A2 | 连接测试不持久化连接状态（断开后恢复原状） | 不影响设备持久状态 |
| A3 | Modbus TCP/RTU 模拟器已在 R1-SIM-001/002 实现 | 集成测试可运行 |
| A4 | 请求体配置覆盖仅用于本次测试，不持久化到数据库 | 不修改设备配置 |
| A5 | VirtualDriver 连接总是成功（内存操作） | TC-V04 幂等性测试可验证 |
| A6 | 测试数据库通过 migrate 预填充 schema | fixtures 可正常插入 |

### 9.2 风险

| 编号 | 风险 | 缓解 |
|------|------|------|
| R1 | Modbus 模拟器尚未完成（阻塞集成测试） | 暂时跳过 TC-MTCP01~07 和 TC-MRTU01~07，先验证 Virtual |
| R2 | 串口模拟在某些 CI 环境不可用 | 使用 `#[ignore]` 标记需要真实串口的测试 |
| R3 | 超时测试在 CI 环境中不稳定（受 CPU 调度影响） | 使用宽松的断言（>= timeout_ms 而非精确值） |
| R4 | 并发测试可能出现竞态条件 | 使用 tokio::test 并设置合理超时 |

---

## 10. 测试用例汇总

### 10.1 优先级分布

| 优先级 | 数量 | 说明 |
|--------|------|------|
| P0 | 13 | 核心功能 + 关键错误场景 |
| P1 | 20 | 边界场景 + 安全测试 + 扩展覆盖 |
| P2 | 4 | 扩展覆盖 + 性能边界 |
| **总计** | **37** | |

### 10.2 分类统计

| 分类 | 用例数 | 用例ID |
|------|--------|--------|
| Virtual 连接测试 | 6 | TC-V01 ~ TC-V06 |
| Modbus TCP 连接测试 | 7 | TC-MTCP01 ~ TC-MTCP07 |
| Modbus RTU 连接测试 | 7 | TC-MRTU01 ~ TC-MRTU07 |
| 错误处理测试 | 10 | TC-ERR01 ~ TC-ERR10 |
| 安全测试 | 3 | TC-SEC01 ~ TC-SEC03 |
| 边界测试 | 4 | TC-BND01 ~ TC-BND04 |
| **总计** | **37** | |

### 10.3 完整用例列表

| ID | 分类 | 优先级 | 描述 |
|----|------|--------|------|
| TC-V01 | Virtual | P0 | Virtual 设备连接成功 - 默认配置 |
| TC-V02 | Virtual | P0 | Virtual 设备连接成功 - 自定义 Random 配置 |
| TC-V03 | Virtual | P1 | Virtual 设备连接成功 - Fixed 模式 |
| TC-V04 | Virtual | P1 | Virtual 设备重复连接（幂等性） |
| TC-V05 | Virtual | P1 | Virtual 设备连接后状态验证 |
| TC-V06 | Virtual | P1 | Virtual 设备连接 - 空 protocol_params |
| TC-MTCP01 | Modbus TCP | P0 | TCP 连接成功（模拟器） |
| TC-MTCP02 | Modbus TCP | P1 | TCP 连接成功 - 请求体覆盖配置 |
| TC-MTCP03 | Modbus TCP | P0 | TCP 连接失败 - 主机不可达 |
| TC-MTCP04 | Modbus TCP | P0 | TCP 连接失败 - 端口拒绝 |
| TC-MTCP05 | Modbus TCP | P1 | TCP 连接失败 - 无效从站 ID |
| TC-MTCP06 | Modbus TCP | P1 | TCP 连接成功 - 自定义端口 |
| TC-MTCP07 | Modbus TCP | P1 | TCP 连接失败 - 超时配置过短 |
| TC-MRTU01 | Modbus RTU | P0 | RTU 连接成功（虚拟串口对） |
| TC-MRTU02 | Modbus RTU | P1 | RTU 连接成功 - 115200 波特率 |
| TC-MRTU03 | Modbus RTU | P1 | RTU 连接成功 - Even 校验 |
| TC-MRTU04 | Modbus RTU | P0 | RTU 连接失败 - 串口不存在 |
| TC-MRTU05 | Modbus RTU | P1 | RTU 连接失败 - 波特率不匹配 |
| TC-MRTU06 | Modbus RTU | P1 | RTU 连接失败 - 无设备应答 |
| TC-MRTU07 | Modbus RTU | P2 | RTU 连接成功 - 不同数据位/停止位 |
| TC-ERR01 | 错误处理 | P0 | 设备不存在 - 无效 UUID |
| TC-ERR02 | 错误处理 | P1 | 请求超时边界 - Virtual 设备 |
| TC-ERR03 | 错误处理 | P1 | 无效配置 - min >= max |
| TC-ERR04 | 错误处理 | P0 | 无效配置 - 缺少 host |
| TC-ERR05 | 错误处理 | P1 | 无效配置 - 非法波特率 |
| TC-ERR06 | 错误处理 | P1 | 请求体格式错误 - 非法 JSON |
| TC-ERR07 | 错误处理 | P0 | 未认证访问 |
| TC-ERR08 | 错误处理 | P0 | 跨用户设备访问 |
| TC-ERR09 | 错误处理 | P1 | 不支持的协议类型 |
| TC-ERR10 | 错误处理 | P2 | 请求体超大内容 |
| TC-SEC01 | 安全 | P1 | 无效 JWT Token |
| TC-SEC02 | 安全 | P1 | 过期 JWT Token |
| TC-SEC03 | 安全 | P1 | SQL 注入防护 - path 参数 |
| TC-BND01 | 边界 | P1 | latency_ms 非负数 |
| TC-BND02 | 边界 | P0 | 响应结构完整性 |
| TC-BND03 | 边界 | P1 | message 字段非空 |
| TC-BND04 | 边界 | P2 | 并发请求（同一设备） |

---

## 附录A: 与其他模块的关联

### A.1 下游消费方

- **前端 `ConnectionTestWidget`**: 消费此 API 返回值渲染连接测试按钮和结果
  - `ConnectionTestState.idle` → 初始状态
  - `ConnectionTestState.testing` → 请求发送中
  - `ConnectionTestState.success` → `data.connected == true`
  - `ConnectionTestState.failed` → `data.connected == false`
  - `message` 字段 → 显示为结果消息
  - `latencyMs` 字段 → 显示延迟信息

### A.2 验证前端对齐

| API 响应字段 | Widget 属性 | 对齐状态 |
|-------------|------------|---------|
| `data.connected` (bool) | `ConnectionTestState.success/failed` | ✅ 对齐 |
| `data.message` (string) | `ConnectionTestWidget.message` | ✅ 对齐 |
| `data.latency_ms` (int) | `ConnectionTestWidget.latencyMs` | ✅ 对齐 |
| `data.error` (string, 失败时) | `ConnectionTestWidget.message` (失败状态) | ⚠️ 字段名不同：API 用 `error`，前端用 `message`。需确认：失败时返回 `error` 还是 `message`？ |

> **与 sw-tom 确认**: PRD 失败响应使用 `error` 字段：`{ connected: false, error: "..." }`。
> 但前端 `ConnectionTestWidget` 在所有状态下使用 `message` 参数。
> 建议统一：成功时返回 `message`，失败时也返回 `message`（不使用 `error` 字段），
> 或在前端映射 `error` → `message`。

---

## 附录B: 响应结构完整枚举

### B.1 成功连接
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "connected": true,
    "message": "Connection successful",
    "latency_ms": 15
  },
  "timestamp": "2026-05-03T10:00:00Z"
}
```

### B.2 连接失败（API正常）
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "connected": false,
    "error": "Connection timeout after 5s",
    "latency_ms": 5000
  },
  "timestamp": "2026-05-03T10:00:00Z"
}
```
> 注意：失败时 `latency_ms` 反映的是直到超时/失败的实际耗时，可选。

### B.3 设备不存在
```json
{
  "code": 404,
  "message": "Resource not found: Device not found",
  "timestamp": "2026-05-03T10:00:00Z"
}
```

### B.4 未认证
```json
{
  "code": 401,
  "message": "Unauthorized",
  "timestamp": "2026-05-03T10:00:00Z"
}
```

### B.5 禁止访问
```json
{
  "code": 403,
  "message": "Forbidden: Access denied",
  "timestamp": "2026-05-03T10:00:00Z"
}
```

### B.6 请求体非法
```json
{
  "code": 400,
  "message": "Bad request: ...",
  "timestamp": "2026-05-03T10:00:00Z"
}
```

---

**文档结束**
