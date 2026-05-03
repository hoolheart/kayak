# R1-S2-011-A 设备连接/断开管理 API 测试用例文档

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S2-011-A |
| 测试类型 | API 集成测试 + 单元测试 |
| 测试范围 | 设备连接/断开/状态查询 REST API |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-03 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [API 规格](#2-api-规格)
3. [连接测试 (CON)](#3-连接测试-con)
4. [断开测试 (DIS)](#4-断开测试-dis)
5. [状态查询测试 (STA)](#5-状态查询测试-sta)
6. [错误处理测试 (ERR)](#6-错误处理测试-err)
7. [幂等性与边界测试 (IDM)](#7-幂等性与边界测试-idm)
8. [多协议行为差异测试 (PRO)](#8-多协议行为差异测试-pro)
9. [测试数据需求](#9-测试数据需求)
10. [测试环境](#10-测试环境)
11. [风险与假设](#11-风险与假设)
12. [测试用例汇总](#12-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证设备连接/断开/状态查询 API 的正确性、幂等性和错误处理能力，确保：
- `POST /api/v1/devices/{id}/connect` 正确建立设备连接
- `POST /api/v1/devices/{id}/disconnect` 正确断开设备连接
- `GET /api/v1/devices/{id}/status` 正确返回设备连接状态
- 三种协议类型（Virtual、ModbusTCP、ModbusRTU）的行为符合各自驱动实现
- 幂等操作（重复连接/断开）返回合理结果
- 错误场景（设备不存在、未授权、驱动未注册等）返回正确的错误码

### 1.2 涉及的API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/v1/devices/{id}/connect` | 连接设备 |
| POST | `/api/v1/devices/{id}/disconnect` | 断开设备 |
| GET | `/api/v1/devices/{id}/status` | 查询设备连接状态 |

### 1.3 驱动连接行为对比（源自源码分析）

| 行为 | VirtualDriver | ModbusTcpDriver | ModbusRtuDriver |
|------|:---:|:---:|:---:|
| 重复连接（已连接状态） | 幂等返回 `Ok` | 返回 `Err(AlreadyConnected)` | 返回 `Err(AlreadyConnected)` |
| 断开未连接设备 | 幂等返回 `Ok` | 幂等返回 `Ok` | 幂等返回 `Ok` |
| 存在 `Connecting` 中间状态 | ❌ | ✅ | ✅ |
| 存在 `Error` 状态 | ❌ | ✅ | ✅ |
| 连接失败可能原因 | 无（总是成功） | 超时/IO错误/主机不可达 | 串口打开失败 |
| 状态类型 | `bool` | `DriverState` enum | `DriverState` enum |

### 1.4 设备状态（DeviceStatus）与驱动状态映射

| DeviceStatus | 含义 | 对应驱动状态 |
|:---:|------|------|
| `offline` | 离线/已断开 | `Disconnected` / `connected=false` |
| `online` | 在线/已连接 | `Connected` / `connected=true` |
| `error` | 错误 | `Error` / 连接失败 |

---

## 2. API 规格

### 2.1 连接设备

```
POST /api/v1/devices/{id}/connect
Authorization: Bearer <token>

Response (200):
{
  "code": 200,
  "message": "success",
  "data": {
    "status": "connected"
  },
  "timestamp": "2026-05-03T..."
}
```

### 2.2 断开设备

```
POST /api/v1/devices/{id}/disconnect
Authorization: Bearer <token>

Response (200):
{
  "code": 200,
  "message": "success",
  "data": {
    "status": "disconnected"
  },
  "timestamp": "2026-05-03T..."
}
```

### 2.3 查询设备连接状态

```
GET /api/v1/devices/{id}/status
Authorization: Bearer <token>

Response (200):
{
  "code": 200,
  "message": "success",
  "data": {
    "status": "connected" | "disconnected" | "error"
  },
  "timestamp": "2026-05-03T..."
}
```

---

## 3. 连接测试 (CON)

### CON-01: Virtual 设备连接成功

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-01 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 已创建 Virtual 协议设备（id=`<virtual_device_id>`）<br>2. 设备存在于数据库且已注册到 DeviceManager<br>3. 设备当前为 `offline` 状态<br>4. 用户已登录，拥有有效 token<br>5. 用户是该设备所属工作台的所有者 |
| **测试步骤** | 1. 发送 `POST /api/v1/devices/<virtual_device_id>/connect`<br>2. 检查 HTTP 状态码<br>3. 检查响应体 JSON 结构<br>4. 调用 `GET /api/v1/devices/<virtual_device_id>/status` 确认状态变化 |
| **预期结果** | 1. HTTP 200<br>2. `response.code` = 200<br>3. `response.data.status` = `"connected"`<br>4. 后续状态查询返回 `status: "connected"`<br>5. 驱动内部 `is_connected()` 返回 `true` |
| **测试数据** | Virtual 设备（默认配置：Random模式，Number类型，RO） |

### CON-02: Modbus TCP 设备连接成功

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-02 |
| **优先级** | Critical |
| **测试类型** | API 集成测试（需模拟设备） |
| **前置条件** | 1. 已创建 Modbus TCP 协议设备（host=127.0.0.1, port=1502, slave_id=1）<br>2. **Modbus TCP 模拟设备已在目标端口运行**<br>3. 设备已注册到 DeviceManager<br>4. 设备当前为 `offline` 状态<br>5. 用户已认证 |
| **测试步骤** | 1. 确保 Modbus TCP 模拟设备在 127.0.0.1:1502 运行<br>2. 发送 `POST /api/v1/devices/<modbus_tcp_id>/connect`<br>3. 检查 HTTP 状态码和响应体<br>4. 调用 `GET /api/v1/devices/<modbus_tcp_id>/status` 确认 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"connected"`<br>3. TCP 连接已建立（可通过对模拟设备发送读请求验证）<br>4. `DriverState` = `Connected` |
| **测试数据** | Modbus TCP 设备（127.0.0.1:1502, slave_id=1, timeout_ms=3000） |

### CON-03: Modbus RTU 设备连接成功

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-03 |
| **优先级** | Critical |
| **测试类型** | API 集成测试（需虚拟串口） |
| **前置条件** | 1. 已创建 Modbus RTU 协议设备（port=`<虚拟串口路径>`, baud_rate=9600, data_bits=8, stop_bits=1, parity=None）<br>2. **Modbus RTU 模拟设备已在虚拟串口对端运行**<br>3. 设备已注册到 DeviceManager<br>4. 设备当前为 `offline` 状态<br>5. 用户已认证 |
| **测试步骤** | 1. 使用 `socat` 或 `pty` 创建虚拟串口对<br>2. 启动 Modbus RTU 模拟设备在串口对的一端<br>3. 发送 `POST /api/v1/devices/<modbus_rtu_id>/connect`<br>4. 检查响应 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"connected"`<br>3. 串口已成功打开<br>4. `DriverState` = `Connected` |
| **测试数据** | Modbus RTU 设备（虚拟串口, baud_rate=9600, 8N1, slave_id=1, timeout_ms=3000） |

### CON-04: 连接断开后重新连接

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-04 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual/Modbus设备已创建<br>2. 设备当前为 `offline` 状态 |
| **测试步骤** | 1. 发送 connect 请求（第1次）→ 成功<br>2. 发送 disconnect 请求 → 成功<br>3. 发送 connect 请求（第2次）→ 检查结果 |
| **预期结果** | 1. 第1次 connect: HTTP 200, status=`"connected"`<br>2. disconnect: HTTP 200, status=`"disconnected"`<br>3. 第2次 connect: HTTP 200, status=`"connected"` |
| **测试数据** | 对三种协议类型各执行一次 |

### CON-05: 连接过程中再连接（Virtual - 幂等）

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-05 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册<br>2. 设备已执行一次成功 connect |
| **测试步骤** | 1. 发送 connect（第1次）→ 确保成功<br>2. 立即发送 connect（第2次，设备已连接）<br>3. 检查响应 |
| **预期结果** | 1. 第1次 connect: HTTP 200, status=`"connected"`<br>2. 第2次 connect: HTTP 200, status=`"connected"`（Virtual驱动幂等，重复连接返回成功）<br>3. 设备保持连接状态 |
| **测试数据** | Virtual 设备 |

### CON-06: 连接过程中再连接（Modbus TCP - 拒绝重复）

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-06 |
| **优先级** | High |
| **测试类型** | API 集成测试（需模拟设备） |
| **前置条件** | 1. Modbus TCP 设备已注册，模拟设备运行中<br>2. 设备已成功连接一次 |
| **测试步骤** | 1. 发送 connect（第1次）→ 成功<br>2. 发送 connect（第2次，设备已连接）<br>3. 检查响应 |
| **预期结果** | 1. 第1次 connect: HTTP 200, status=`"connected"`<br>2. 第2次 connect: **应返回错误**（DriverError::AlreadyConnected）<br>&nbsp;&nbsp;&nbsp;&nbsp;或后端将其转为 HTTP 409 Conflict<br>3. 设备保持连接状态，不应创建新TCP连接 |
| **测试数据** | Modbus TCP 设备 |

### CON-07: 连接过程中再连接（Modbus RTU - 拒绝重复）

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-07 |
| **优先级** | High |
| **测试类型** | API 集成测试（需虚拟串口） |
| **前置条件** | 1. Modbus RTU 设备已注册，模拟设备运行中<br>2. 设备已成功连接一次 |
| **测试步骤** | 1. 发送 connect（第1次）→ 成功<br>2. 发送 connect（第2次，设备已连接）<br>3. 检查响应 |
| **预期结果** | 1. 第1次 connect: HTTP 200<br>2. 第2次 connect: 返回错误（DriverError::AlreadyConnected）<br>&nbsp;&nbsp;&nbsp;&nbsp;或后端将其转为 HTTP 409 Conflict<br>3. 串口不应重复打开 |
| **测试数据** | Modbus RTU 设备 |

### CON-08: 连接失败 - Modbus TCP 目标不可达

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-08 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已注册<br>2. 配置的 host/port 无服务运行（如 127.0.0.1:19999） |
| **测试步骤** | 1. 发送 `POST /api/v1/devices/<modbus_tcp_id>/connect`<br>2. 检查 HTTP 状态码和响应体<br>3. 调用 `GET /api/v1/devices/<modbus_tcp_id>/status` 确认状态 |
| **预期结果** | 1. HTTP 非200（建议 503 Service Unavailable 或 502 Bad Gateway）<br>2. 响应体包含错误信息<br>3. 状态查询返回 `status: "error"`<br>4. `DriverState` = `Error` |
| **测试数据** | Modbus TCP 设备（连接不可达地址，如 192.0.2.1:19999，timeout_ms=1000） |

### CON-09: 连接超时 - Modbus TCP

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-09 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已注册<br>2. 配置极短超时（如 timeout_ms=100）<br>3. 目标主机不可达或防火墙丢弃连接 |
| **测试步骤** | 1. 发送 connect 请求<br>2. 等待超时<br>3. 检查响应和状态 |
| **预期结果** | 1. HTTP 非200（超时错误）<br>2. 错误信息中包含 "timeout" 或 "Timeout"<br>3. 状态查询返回 `status: "error"`<br>4. `DriverState` = `Error` |
| **测试数据** | Modbus TCP 设备（192.0.2.1:80, timeout_ms=100） |

### CON-10: 连接失败 - Modbus RTU 串口不存在

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-10 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus RTU 设备已注册<br>2. 配置不存在的串口路径（如 `/dev/no_such_port_xyz`） |
| **测试步骤** | 1. 发送 connect 请求<br>2. 检查错误响应 |
| **预期结果** | 1. HTTP 非200<br>2. 错误信息包含串口错误描述<br>3. 状态查询返回 `status: "error"` |
| **测试数据** | Modbus RTU 设备（port="/dev/no_such_port_xyz"） |

### CON-11: 三种协议设备并行连接

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-11 |
| **优先级** | Medium |
| **测试类型** | API 集成测试（并发） |
| **前置条件** | 1. 三个不同协议的设备均已创建并注册<br>2. Modbus TCP/RTU 模拟设备运行中 |
| **测试步骤** | 1. 使用异步方式同时向三个设备发送 connect 请求<br>2. 验证每个设备独立连接成功<br>3. 检测是否存在锁竞争或死锁 |
| **预期结果** | 1. 三个连接均成功（HTTP 200）<br>2. 每个设备状态独立，互不影响<br>3. 无死锁或连接串扰<br>4. DeviceManager 的 RwLock 正常释放 |
| **测试数据** | Virtual + Modbus TCP + Modbus RTU 设备各一个 |

### CON-12: 快速连续连接-断开-连接

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-12 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual设备已注册<br>2. 设备当前断开 |
| **测试步骤** | 1. connect → 检查状态<br>2. disconnect → 检查状态<br>3. connect → 检查状态<br>4. 不等待，立即重复以上循环5次 |
| **预期结果** | 1. 每次 connect 后状态为 "connected"<br>2. 每次 disconnect 后状态为 "disconnected"<br>3. 无竞态条件导致的异常状态 |
| **测试数据** | Virtual 设备 |

---

## 4. 断开测试 (DIS)

### DIS-01: Virtual 设备断开成功

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-01 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册<br>2. 设备当前为 "connected" 状态<br>3. 用户已认证 |
| **测试步骤** | 1. 发送 `POST /api/v1/devices/<device_id>/disconnect`<br>2. 检查 HTTP 状态码<br>3. 检查响应体 JSON 结构<br>4. 调用 `GET /api/v1/devices/<device_id>/status` 确认状态变化 |
| **预期结果** | 1. HTTP 200<br>2. `response.code` = 200<br>3. `response.data.status` = `"disconnected"`<br>4. 后续状态查询返回 `status: "disconnected"`<br>5. 驱动内部 `is_connected()` 返回 `false` |
| **测试数据** | Virtual 设备（先connect再disconnect） |

### DIS-02: Modbus TCP 设备断开成功

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-02 |
| **优先级** | Critical |
| **测试类型** | API 集成测试（需模拟设备） |
| **前置条件** | 1. Modbus TCP 设备已注册，模拟设备运行中<br>2. 设备已连接成功 |
| **测试步骤** | 1. 发送 disconnect 请求<br>2. 检查响应和状态<br>3. 验证 TCP 连接已关闭（可通过 lsof/netstat 或尝试发送读请求确认） |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"disconnected"`<br>3. `DriverState` = `Disconnected`<br>4. TcpStream 已释放 |
| **测试数据** | Modbus TCP 设备 |

### DIS-03: Modbus RTU 设备断开成功

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-03 |
| **优先级** | Critical |
| **测试类型** | API 集成测试（需虚拟串口） |
| **前置条件** | 1. Modbus RTU 设备已注册，模拟设备运行中<br>2. 设备已连接成功 |
| **测试步骤** | 1. 发送 disconnect 请求<br>2. 检查响应和状态<br>3. 验证串口已释放 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"disconnected"`<br>3. `DriverState` = `Disconnected`<br>4. SerialStream 已释放 |
| **测试数据** | Modbus RTU 设备 |

### DIS-04: 断开未连接的设备（幂等性）

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-04 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual/ModbusTCP/ModbusRTU 设备已注册<br>2. 设备当前为 `disconnected` 状态（从未连接过，或刚断开） |
| **测试步骤** | 1. 确保设备状态为 disconnected<br>2. 发送 disconnect 请求<br>3. 检查响应和状态 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"disconnected"`<br>3. 操作应幂等返回成功（所有三种驱动都实现为幂等） |
| **测试数据** | 对三种协议类型各执行一次 |

### DIS-05: 断开后再断开（双重断开）

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-05 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 设备已连接<br>2. 执行一次 disconnect |
| **测试步骤** | 1. connect → 成功<br>2. disconnect（第1次）→ 成功<br>3. disconnect（第2次）→ 检查 |
| **预期结果** | 1. 第1次 disconnect: HTTP 200, status=`"disconnected"`<br>2. 第2次 disconnect: HTTP 200, status=`"disconnected"`（幂等） |
| **测试数据** | Virtual 设备 |

### DIS-06: Modbus TCP 断开时设备无响应

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-06 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已连接状态<br>2. 模拟设备已崩溃/停止（但 TCP 连接可能仍存在） |
| **测试步骤** | 1. connect 成功后，杀死模拟设备进程<br>2. 不等待超时，立即发送 disconnect<br>3. 检查响应 |
| **预期结果** | 1. HTTP 200（disconnect 应总是成功，因为只清理本地状态）<br>2. 本地 DriverState 变为 Disconnected<br>3. TcpStream 资源被释放（即使远端已关闭） |
| **测试数据** | Modbus TCP 设备 |

### DIS-07: 三种协议设备并行断开

| 字段 | 内容 |
|------|------|
| **测试ID** | DIS-07 |
| **优先级** | Low |
| **测试类型** | API 集成测试（并发） |
| **前置条件** | 1. 三个不同协议的设备均已连接<br>2. 模拟设备运行中 |
| **测试步骤** | 1. 并发发送三个设备的 disconnect 请求<br>2. 验证每个设备独立断开 |
| **预期结果** | 1. 三个断开均成功<br>2. 每个设备状态为 disconnected<br>3. 无死锁 |
| **测试数据** | Virtual + Modbus TCP + Modbus RTU 设备各一个 |

---

## 5. 状态查询测试 (STA)

### STA-01: 查询离线设备状态

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-01 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册<br>2. 设备从未连接，当前为 `disconnected` 状态<br>3. 用户已认证 |
| **测试步骤** | 1. 发送 `GET /api/v1/devices/<device_id>/status`<br>2. 检查 HTTP 状态码<br>3. 检查响应体 JSON 结构 |
| **预期结果** | 1. HTTP 200<br>2. `response.code` = 200<br>3. `response.data.status` = `"disconnected"` |
| **测试数据** | Virtual 设备（新建未连接） |

### STA-02: 查询已连接设备状态

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-02 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册<br>2. 设备已成功 connect<br>3. 用户已认证 |
| **测试步骤** | 1. connect 成功后立即发送 status 查询<br>2. 检查响应 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"connected"` |
| **测试数据** | Virtual 设备 |

### STA-03: 查询断开后设备状态

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-03 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册<br>2. 设备经历了 connect → disconnect 流程 |
| **测试步骤** | 1. connect → 成功<br>2. disconnect → 成功<br>3. 发送 status 查询 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"disconnected"` |
| **测试数据** | Virtual 设备 |

### STA-04: 查询连接失败后的错误状态

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-04 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已注册<br>2. 连接失败（目标不可达） |
| **测试步骤** | 1. 发送 connect 到不可达目标 → 失败<br>2. 发送 status 查询 |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"error"`<br>3. 可选：响应体中包含错误原因描述 |
| **测试数据** | Modbus TCP 设备（不可达地址） |

### STA-05: 查询 Modbus TCP 连接中的状态

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-05 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已注册<br>2. 目标主机可达但响应慢（如设置极长超时） |
| **测试步骤** | 1. 发送 connect 请求（不等待完成）<br>2. 在连接进行中，立即发送 status 查询<br>3. 检查响应 |
| **预期结果** | 1. 状态查询返回 `"connecting"` 或 `"disconnected"`（取决于实现是否暴露 Connecting 状态）<br>2. 至少不应返回 `"connected"` |
| **测试数据** | Modbus TCP 设备（超时=30s，慢速/防火墙目标） |

### STA-06: 查询错误后恢复正常的设备状态

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-06 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已注册<br>2. 之前连接失败导致 error 状态 |
| **测试步骤** | 1. connect 不可达 → error<br>2. 验证 status = "error"<br>3. 启动模拟设备<br>4. connect → 成功<br>5. status 查询 |
| **预期结果** | 1. 步骤2: status = `"error"`<br>2. 步骤5: status = `"connected"`<br>3. 状态可从 error 恢复为 connected |
| **测试数据** | Modbus TCP 设备 |

### STA-07: 三种协议设备状态独立

| 字段 | 内容 |
|------|------|
| **测试ID** | STA-07 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 三种协议设备均已注册<br>2. Virtual 已连接，Modbus TCP 已连接，Modbus RTU 断开 |
| **测试步骤** | 1. 依次查询三个设备的 status |
| **预期结果** | 1. Virtual: `"connected"`<br>2. Modbus TCP: `"connected"`<br>3. Modbus RTU: `"disconnected"`<br>4. 状态互不干扰 |
| **测试数据** | 三种设备各一个 |

---

## 6. 错误处理测试 (ERR)

### ERR-01: 设备不存在

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-01 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 用户已认证<br>2. 使用一个不存在的 UUID（从未创建的设备） |
| **测试步骤** | 1. 发送 `POST /api/v1/devices/<non_existent_uuid>/connect`<br>2. 发送 `POST /api/v1/devices/<non_existent_uuid>/disconnect`<br>3. 发送 `GET /api/v1/devices/<non_existent_uuid>/status` |
| **预期结果** | 1. 三个请求均返回 HTTP 404<br>2. 响应体包含 "not found" 或 "设备不存在" 等信息<br>3. `response.code` 应为非200错误码 |
| **测试数据** | `uuid::Uuid::new_v4()` 生成的随机 UUID |

### ERR-02: 未授权访问（非所有者）

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-02 |
| **优先级** | Critical |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 用户A创建了设备<br>2. 用户B登录，获取token<br>3. 用户B不是设备所属工作台的所有者 |
| **测试步骤** | 1. 用户B发送 connect/disconnect/status 请求到用户A的设备<br>2. 检查三个接口的响应 |
| **预期结果** | 1. 三个请求均返回 HTTP 403 Forbidden<br>2. 响应体包含 "Access denied" 信息 |
| **测试数据** | 两个不同用户的设备 |

### ERR-03: 未认证访问（无Token）

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-03 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 存在有效设备<br>2. 不提供 Authorization header |
| **测试步骤** | 1. 发送 connect/disconnect/status 请求（无 Authorization header） |
| **预期结果** | 1. 三个请求均返回 HTTP 401 Unauthorized |
| **测试数据** | 任意有效设备 ID |

### ERR-04: 无效Token

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-04 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 使用伪造或过期的 JWT token |
| **测试步骤** | 1. 使用无效 token 发送 connect/disconnect/status 请求 |
| **预期结果** | 1. HTTP 401 Unauthorized<br>2. 响应体包含 token 无效信息 |
| **测试数据** | Authorization: Bearer invalid_token_xyz |

### ERR-05: 驱动未注册到 DeviceManager

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-05 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 设备存在于数据库，但未注册到 DeviceManager（如非Virtual协议设备当前未自动注册）<br>2. 或设备已从 DeviceManager 被 unregister |
| **测试步骤** | 1. 发送 connect 请求 |
| **预期结果** | 1. HTTP 404 或 500（取决于后端如何处理缺失驱动）<br>2. 不应 panic 或 crash<br>3. 返回有意义的错误信息 |
| **测试数据** | 数据库存在但 DeviceManager 中不存在的设备 ID |

### ERR-06: 无效的 UUID 格式

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-06 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 不需要 |
| **测试步骤** | 1. 使用非 UUID 格式的字符串作为设备 ID 发送请求<br>&nbsp;&nbsp;例如：`POST /api/v1/devices/not-a-valid-uuid/connect` |
| **预期结果** | 1. HTTP 400 Bad Request<br>2. 响应体包含路径参数格式错误信息 |
| **测试数据** | `"not-a-valid-uuid"` |

### ERR-07: 请求体包含意外数据（connect/disconnect）

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-07 |
| **优先级** | Low |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 有效设备 ID<br>2. 用户已认证 |
| **测试步骤** | 1. 发送 `POST /api/v1/devices/<id>/connect` 并附带 JSON body<br>&nbsp;&nbsp;例如：`{"force": true}`<br>2. 发送 `POST /api/v1/devices/<id>/disconnect` 并附带 JSON body |
| **预期结果** | 1. 应忽略多余 body 正常处理，或返回 400<br>2. 不应 crash 或产生异常行为 |
| **测试数据** | 有效设备 ID + 多余 JSON body |

### ERR-08: Modbus TCP 连接超时（已连接状态不变）

| 字段 | 内容 |
|------|------|
| **测试ID** | ERR-08 |
| **优先级** | High |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Modbus TCP 设备已成功连接<br>2. 模拟设备正常运行 |
| **测试步骤** | 1. connect 成功<br>2. 状态 = connected<br>3. 关闭模拟设备（TCP 连接可能残留）<br>4. 尝试读取操作会失败<br>5. 再次查询 status |
| **预期结果** | 1. 连接断开后的状态查询结果取决于实现<br>2. 如果驱动检测到断连，状态应为 `"error"`<br>3. 如果驱动未检测，可能仍显示 `"connected"`<br>&nbsp;&nbsp;&nbsp;&nbsp;（文档应记录此行为） |
| **测试数据** | Modbus TCP 设备 |

---

## 7. 幂等性与边界测试 (IDM)

### IDM-01: Virtual 连接幂等性（连续3次connect）

| 字段 | 内容 |
|------|------|
| **测试ID** | IDM-01 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册<br>2. 设备初始为 disconnected |
| **测试步骤** | 1. connect（第1次）<br>2. connect（第2次）<br>3. connect（第3次）<br>4. 查询状态 |
| **预期结果** | 1. 三次 connect 均返回 HTTP 200<br>2. 状态始终为 `"connected"`<br>3. VirtualDriver 将重复连接视为幂等成功 |
| **测试数据** | Virtual 设备 |

### IDM-02: 断开幂等性（连续3次disconnect）

| 字段 | 内容 |
|------|------|
| **测试ID** | IDM-02 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 设备已连接或已断开 |
| **测试步骤** | 1. disconnect（第1次）<br>2. disconnect（第2次）<br>3. disconnect（第3次）<br>4. 查询状态 |
| **预期结果** | 1. 三次 disconnect 均返回 HTTP 200<br>2. 状态始终为 `"disconnected"` |
| **测试数据** | Virtual 设备 |

### IDM-03: 新建设备的初始状态

| 字段 | 内容 |
|------|------|
| **测试ID** | IDM-03 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 刚创建设备（未执行任何连接操作） |
| **测试步骤** | 1. 创建设备后立即查询 status |
| **预期结果** | 1. HTTP 200<br>2. `response.data.status` = `"disconnected"` |
| **测试数据** | Virtual 设备（新建） |

### IDM-04: 连接后无需等待即可查询状态

| 字段 | 内容 |
|------|------|
| **测试ID** | IDM-04 |
| **优先级** | Low |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. Virtual 设备已注册 |
| **测试步骤** | 1. 发送 connect 请求，获得响应后立即发送 status 查询（无延迟） |
| **预期结果** | 1. status 查询返回 `"connected"`<br>2. 状态变化应该是同步的 |
| **测试数据** | Virtual 设备 |

### IDM-05: 删除设备后无法连接

| 字段 | 内容 |
|------|------|
| **测试ID** | IDM-05 |
| **优先级** | Medium |
| **测试类型** | API 集成测试 |
| **前置条件** | 1. 设备已创建<br>2. 设备已从数据库和 DeviceManager 删除 |
| **测试步骤** | 1. 删除设备<br>2. 使用已删除设备的 ID 发送 connect 请求 |
| **预期结果** | 1. HTTP 404 Not Found |
| **测试数据** | 已删除的设备 ID |

---

## 8. 多协议行为差异测试 (PRO)

### PRO-01: Virtual vs Modbus TCP 重复连接行为对比

| 字段 | 内容 |
|------|------|
| **测试ID** | PRO-01 |
| **优先级** | High |
| **测试类型** | 对比测试 |
| **前置条件** | 1. Virtual 设备 + Modbus TCP 设备均已连接<br>2. Modbus TCP 模拟设备运行中 |
| **测试步骤** | 1. 对 Virtual 设备发送第2次 connect → 检查<br>2. 对 Modbus TCP 设备发送第2次 connect → 检查 |
| **预期结果** | 1. Virtual: HTTP 200（幂等）<br>2. Modbus TCP: HTTP 非200（AlreadyConnected错误）<br>3. 确认行为差异在文档中有明确说明 |
| **测试数据** | Virtual + Modbus TCP 设备 |

### PRO-02: 三种协议连接成功响应格式一致性

| 字段 | 内容 |
|------|------|
| **测试ID** | PRO-02 |
| **优先级** | Medium |
| **测试类型** | 对比测试 |
| **前置条件** | 1. 三种协议设备均可成功连接<br>2. 模拟设备运行中 |
| **测试步骤** | 1. 分别连接三种设备，收集 connect 响应<br>2. 对比响应 JSON 结构和字段 |
| **预期结果** | 1. 三种设备的 connect 成功响应格式完全一致<br>2. `code` = 200<br>3. `data.status` = `"connected"`<br>4. 均包含 timestamp |
| **测试数据** | 三种协议设备各一个 |

### PRO-03: 三种协议断开成功响应格式一致性

| 字段 | 内容 |
|------|------|
| **测试ID** | PRO-03 |
| **优先级** | Medium |
| **测试类型** | 对比测试 |
| **前置条件** | 1. 三种协议设备均已连接 |
| **测试步骤** | 1. 分别断开三种设备，收集 disconnect 响应<br>2. 对比响应格式 |
| **预期结果** | 1. 三种设备的 disconnect 成功响应格式完全一致<br>2. `code` = 200<br>3. `data.status` = `"disconnected"` |
| **测试数据** | 三种协议设备各一个 |

### PRO-04: 三种协议状态查询响应格式一致性

| 字段 | 内容 |
|------|------|
| **测试ID** | PRO-04 |
| **优先级** | Medium |
| **测试类型** | 对比测试 |
| **前置条件** | 1. 三种协议设备处于不同状态 |
| **测试步骤** | 1. 分别查询三种设备的 status<br>2. 对比响应格式 |
| **预期结果** | 1. 三种设备的 status 查询成功响应格式完全一致<br>2. `code` = 200<br>3. `data.status` 为有效的状态字符串 |
| **测试数据** | 三种协议设备各一个 |

---

## 9. 测试数据需求

### 9.1 测试设备

| 序号 | 设备名称 | 协议类型 | 配置 | 用途 |
|:---:|------|:---:|------|------|
| 1 | TestVirtualDevice | Virtual | 默认配置（Random/Number/RO/0-100） | 通用连接/断开/状态测试 |
| 2 | TestModbusTcpDevice | ModbusTCP | host=127.0.0.1, port=1502, slave_id=1, timeout_ms=3000 | ModbusTCP 连接测试 |
| 3 | TestModbusTcpUnreachable | ModbusTCP | host=192.0.2.1, port=19999, timeout_ms=100 | 连接失败测试 |
| 4 | TestModbusRtuDevice | ModbusRTU | port=<虚拟串口>, baud=9600, 8N1, slave_id=1 | ModbusRTU 连接测试 |
| 5 | TestModbusRtuBadPort | ModbusRTU | port=/dev/no_such_port, baud=9600 | 错误处理测试 |

### 9.2 测试用户

| 序号 | 用户名 | 角色 | 用途 |
|:---:|------|------|------|
| 1 | owner_user | 设备所有者 | 正常连接/断开操作 |
| 2 | other_user | 非所有者 | 权限验证测试 |
| 3 | (未认证) | - | 认证测试 |

### 9.3 模拟设备

| 协议 | 启动方式 | 用途 |
|------|------|------|
| Modbus TCP | `cargo run --bin modbus-simulator -- --tcp --port 1502` | CON-02, CON-11 等 |
| Modbus RTU | `cargo run --bin modbus-simulator -- --rtu --port <pty_master>` | CON-03, CON-11 等 |

### 9.4 虚拟串口创建（macOS/Linux）

```bash
# macOS
socat -d -d pty,raw,echo=0 pty,raw,echo=0
# 输出: /dev/ttys001 <-> /dev/ttys002

# Linux
socat -d -d pty,raw,echo=0 pty,raw,echo=0
# 输出: /dev/pts/3 <-> /dev/pts/4
```

---

## 10. 测试环境

### 10.1 软件要求

| 软件 | 版本要求 | 说明 |
|------|------|------|
| Rust | 1.80+ | 编译和运行后端 |
| PostgreSQL | 14+ | 数据库 |
| socat | 任意 | 虚拟串口创建 |
| curl/httpie | 任意 | 手动 API 测试 |

### 10.2 环境变量

```bash
# 后端配置
export DATABASE_URL="postgres://kayak:kayak@localhost:5432/kayak_test"
export JWT_ACCESS_SECRET="test_access_secret_key_for_testing"
export JWT_REFRESH_SECRET="test_refresh_secret_key_for_testing"
export KAYAK_SERVE_STATIC="../kayak-frontend/build/web"
```

### 10.3 启动顺序

1. 启动 PostgreSQL
2. 运行数据库迁移
3. 启动后端: `cargo run`
4. （如需 Modbus 测试）启动模拟设备
5. 执行测试

---

## 11. 风险与假设

### 11.1 假设

| 假设ID | 内容 | 影响 |
|:---:|------|------|
| A1 | connect/disconnect/status API 已实现为 REST 端点 | 若未实现，需先开发 |
| A2 | DeviceManager 通过 DeviceService 访问，线程安全 | 若存在竞态条件，并发测试暴露 |
| A3 | Virtual 设备在 create_device 时自动注册到 DeviceManager | CON-01 依赖此行为 |
| A4 | Modbus TCP/RTU 设备在 create_device 时也会注册（或需显式注册） | 若未注册，CON-02/CON-03 失败 |
| A5 | 认证中间件 RequireAuth 已应用于这三个端点 | ERR-02/ERR-03 依赖中间件正确工作 |
| A6 | Modbus TCP/RTU 模拟设备可独立运行 | CON-02/CON-03 依赖模拟设备 |
| A7 | 虚拟串口工具（socat）可在测试环境中使用 | CON-03 依赖虚拟串口 |

### 11.2 风险

| 风险ID | 内容 | 严重性 | 缓解措施 |
|:---:|------|:---:|------|
| R1 | Virtual 和 Modbus 连接的幂等性行为不一致 | Medium | 通过 PRO-01 明确记录差异，API层考虑统一处理 |
| R2 | Modbus 模拟设备不稳定导致测试不可靠 | High | 添加健康检查/重试机制；优先实现 Virtual 测试 |
| R3 | 虚拟串口在 CI 环境中不可用 | Medium | Modbus RTU 测试在 CI 中标记为 skip，手动测试补充 |
| R4 | connect/disconnect API 尚未实现 | High | 测试用例设计先于实现，为 TDD 提供依据 |
| R5 | 并发测试可能暴露 RwLock 瓶颈 | Low | 通过 CON-11 提前验证 |

---

## 12. 测试用例汇总

### 12.1 按类别统计

| 类别 | 用例数 | Critical | High | Medium | Low |
|------|:---:|:---:|:---:|:---:|:---:|
| 3. 连接测试 (CON) | 12 | 3 | 5 | 3 | 1 |
| 4. 断开测试 (DIS) | 7 | 3 | 1 | 2 | 1 |
| 5. 状态查询测试 (STA) | 7 | 3 | 1 | 3 | 0 |
| 6. 错误处理测试 (ERR) | 8 | 2 | 4 | 1 | 1 |
| 7. 幂等性测试 (IDM) | 5 | 0 | 0 | 3 | 2 |
| 8. 协议差异测试 (PRO) | 4 | 0 | 1 | 3 | 0 |
| **总计** | **43** | **11** | **12** | **15** | **5** |

### 12.2 按协议覆盖

| 协议 | 连接测试 | 断开测试 | 状态测试 | 错误测试 |
|------|:---:|:---:|:---:|:---:|
| Virtual | CON-01/04/05/11/12 | DIS-01/04/05/07 | STA-01/02/03/07 | - |
| Modbus TCP | CON-02/04/06/08/09/11 | DIS-02/04/06/07 | STA-04/05/06/07 | ERR-08 |
| Modbus RTU | CON-03/04/07/10/11 | DIS-03/04/07 | STA-07 | - |
| 通用/协议无关 | - | - | - | ERR-01~07 |

### 12.3 按接口覆盖

| API 端点 | 正向用例 | 错误用例 | 总计 |
|------|:---:|:---:|:---:|
| `POST /devices/{id}/connect` | CON-01~12 | ERR-01~08 | 20 |
| `POST /devices/{id}/disconnect` | DIS-01~07 | ERR-01~07 | 14 |
| `GET /devices/{id}/status` | STA-01~07 | ERR-01~07 | 14 |

### 12.4 执行建议

1. **优先执行 Critical 用例**（11个）：确保核心功能可用
2. **Virtual 优先于 Modbus**：Virtual 不依赖外部模拟设备，可立即执行
3. **Modbus 测试需模拟设备**：先确认模拟设备可正常启动，再执行相关用例
4. **并发测试独立运行**：避免与其他测试的时序干扰
5. **RTU 测试条件性执行**：检查虚拟串口可用性，不可用时跳过

---

**文档结束**
