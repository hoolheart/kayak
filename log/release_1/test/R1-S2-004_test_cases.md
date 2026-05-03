# R1-S2-004-A 测试用例文档 - 协议列表与串口扫描 API

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S2-004-A |
| 任务名称 | 协议列表与串口扫描 API |
| 测试类型 | API 接口测试（集成测试） |
| 测试范围 | `GET /api/v1/protocols`, `GET /api/v1/system/serial-ports` |
| 相关需求 | PRD 4.1.1, PRD 4.1.2 |
| 前端消费端 | `protocol_service.dart` (ProtocolInfo / SerialPort models) |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-03 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [协议列表 API 测试 (PT-001 ~ PT-013)](#2-协议列表-api-测试)
3. [串口扫描 API 测试 (SP-001 ~ SP-010)](#3-串口扫描-api-测试)
4. [错误处理测试 (ER-001 ~ ER-007)](#4-错误处理测试)
5. [边界与性能测试 (BP-001 ~ BP-004)](#5-边界与性能测试)
6. [测试环境与前提](#6-测试环境与前提)
7. [测试数据期望](#7-测试数据期望)
8. [风险评估](#8-风险评估)
9. [测试用例汇总](#9-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证两个后端 API 端点：
1. **`GET /api/v1/protocols`** — 返回系统支持的协议列表，包含每种协议的配置 Schema
2. **`GET /api/v1/system/serial-ports`** — 扫描并返回系统可用串口列表

验证点包括：
- 响应码和响应体结构符合 PRD 定义
- 数据完整性（字段齐全、类型正确、值合法）
- 与前端 `ProtocolInfo.fromJson` / `SerialPort.fromJson` 模型兼容
- 认证/鉴权正确执行
- HTTP 错误场景处理符合 REST 规范

### 1.2 被测接口

#### API 1: 获取协议列表

```
GET /api/v1/protocols
Authorization: Bearer {token}
```

**期望成功响应 (200):**
```json
{
  "code": 200,
  "data": [
    {
      "id": "virtual",
      "name": "Virtual",
      "description": "虚拟设备（用于测试）",
      "config_schema": { ... }
    },
    {
      "id": "modbus_tcp",
      "name": "Modbus TCP",
      "description": "Modbus TCP/IP 协议",
      "config_schema": { ... }
    },
    {
      "id": "modbus_rtu",
      "name": "Modbus RTU",
      "description": "Modbus RTU 串口协议",
      "config_schema": { ... }
    }
  ]
}
```

#### API 2: 获取可用串口列表

```
GET /api/v1/system/serial-ports
Authorization: Bearer {token}
```

**期望成功响应 (200):**
```json
{
  "code": 200,
  "data": [
    { "path": "/dev/ttyUSB0", "description": "USB Serial" },
    { "path": "/dev/ttyACM0", "description": "USB ACM" }
  ]
}
```

### 1.3 前端模型兼容性约束

基于 `protocol_config.dart`，后端响应必须满足：

| 模型类 | 必填字段 | 字段类型 |
|--------|---------|---------|
| `ProtocolInfo` | `id` | `String` (非空) |
| `ProtocolInfo` | `name` | `String` (非空) |
| `ProtocolInfo` | `description` | `String` |
| `ProtocolInfo` | `config_schema` | `Map<String, dynamic>` (不可为 null) |
| `SerialPort` | `path` | `String` (非空) |
| `SerialPort` | `description` | `String` |

> **注意**: 前端 `ProtocolInfo.fromJson` 对 `name`、`description`、`config_schema` 均有 fallback 默认值处理，但后端应保证数据完整性，避免前端收到空字符串/空对象。

---

## 2. 协议列表 API 测试

### PT-001: 正常请求返回协议列表

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-001 |
| **优先级** | P0 (Critical) |
| **类别** | 正常路径 / 冒烟测试 |
| **描述** | 已认证用户请求协议列表，应返回 200 且 data 为非空数组 |
| **前提条件** | 1. 后端服务运行中 2. 持有有效 JWT Token |
| **测试步骤** | 1. 携带 `Authorization: Bearer {valid_token}` 头，发送 `GET /api/v1/protocols` |
| **预期结果** | 1. HTTP 状态码 = 200<br>2. 响应体包含 `code: 200`<br>3. `data` 为数组且 `length >= 3`<br>4. Content-Type = `application/json` |
| **验证方式** | 自动化 / curl |

---

### PT-002: 响应包含全部三种协议 (Virtual, Modbus TCP, Modbus RTU)

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-002 |
| **优先级** | P0 (Critical) |
| **类别** | 正常路径 / 数据完整性 |
| **描述** | 验证协议列表包含三种协议的完整信息 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 发送请求 2. 从 `data` 中按 `id` 查找各协议 |
| **预期结果** | 1. 存在 `id=="virtual"` 的条目<br>2. 存在 `id=="modbus_tcp"` 的条目<br>3. 存在 `id=="modbus_rtu"` 的条目 |
| **验证方式** | 自动化 |

---

### PT-003: 协议条目数据结构验证（字段存在性与类型）

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-003 |
| **优先级** | P0 (Critical) |
| **类别** | 数据结构 |
| **描述** | 每个协议条目必须包含 `id`, `name`, `description`, `config_schema` 四个字段且类型正确 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 遍历响应 `data` 数组中的每一项 2. 验证各字段 |
| **预期结果** | 每一项满足：<br>- `id`: String 非空<br>- `name`: String 非空<br>- `description`: String 非空<br>- `config_schema`: Object (Map) 非 null |
| **验证方式** | 自动化 - JSON Schema 校验 |

---

### PT-004: Virtual 协议 config_schema 完整性

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-004 |
| **优先级** | P0 (Critical) |
| **类别** | 数据结构 / config_schema |
| **描述** | Virtual 协议的 config_schema 应包含所有必要配置字段定义 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 查找 `id=="virtual"` 条目 2. 检查 `config_schema` 内容 |
| **预期结果** | `config_schema` 至少包含以下字段的 schema 定义：<br>- `mode` (枚举: random/fixed/sine/ramp)<br>- `dataType` (枚举: number/integer/string/boolean)<br>- `accessType` (枚举: ro/wo/rw)<br>- `minValue` (数字)<br>- `maxValue` (数字)<br>- `fixedValue` (数字, 可选)<br>- `sampleInterval` (数字) |
| **验证方式** | 自动化 |

---

### PT-005: Modbus TCP 协议 config_schema 完整性

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-005 |
| **优先级** | P0 (Critical) |
| **类别** | 数据结构 / config_schema |
| **描述** | Modbus TCP 协议的 config_schema 应包含所有必要配置字段定义 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 查找 `id=="modbus_tcp"` 条目 2. 检查 `config_schema` |
| **预期结果** | `config_schema` 至少包含：<br>- `host` (字符串, IP地址格式)<br>- `port` (整数, 默认 502)<br>- `slave_id` (整数, 默认 1)<br>- `timeout_ms` (整数, 默认 5000)<br>- `connection_pool_size` (整数, 默认 4) |
| **验证方式** | 自动化 |

---

### PT-006: Modbus RTU 协议 config_schema 完整性

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-006 |
| **优先级** | P0 (Critical) |
| **类别** | 数据结构 / config_schema |
| **描述** | Modbus RTU 协议的 config_schema 应包含所有必要配置字段定义 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 查找 `id=="modbus_rtu"` 条目 2. 检查 `config_schema` |
| **预期结果** | `config_schema` 至少包含：<br>- `port` (字符串, 串口路径)<br>- `baud_rate` (整数, 枚举: 9600/19200/38400/57600/115200)<br>- `data_bits` (整数, 枚举: 7/8)<br>- `stop_bits` (整数, 枚举: 1/2)<br>- `parity` (字符串, 枚举: None/Even/Odd)<br>- `slave_id` (整数, 默认 1)<br>- `timeout_ms` (整数, 默认 1000) |
| **验证方式** | 自动化 |

---

### PT-007: config_schema 包含字段约束信息

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-007 |
| **优先级** | P1 (High) |
| **类别** | 数据结构 / config_schema |
| **描述** | 每个 config_schema 字段应包含 type、label、description、required 等元信息 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 遍历各协议的 config_schema 2. 检查每个字段定义的结构 |
| **预期结果** | 每个字段定义包含：<br>- `type`: 字段数据类型标识<br>- `label` 或 `name`: 人类可读名称<br>- `description` 或 `help`: 字段说明 |
| **验证方式** | 自动化 |

---

### PT-008: 响应体顶层结构验证

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-008 |
| **优先级** | P1 (High) |
| **类别** | 数据结构 |
| **描述** | 校验响应体顶层仅包含 `code` 和 `data` 字段 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 发送请求 2. 获取 JSON 根对象的所有 key |
| **预期结果** | 根对象仅包含 `code` 和 `data` 两个 key |
| **验证方式** | 自动化 |

---

### PT-009: 协议 ID 唯一性

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-009 |
| **优先级** | P1 (High) |
| **类别** | 数据完整性 |
| **描述** | 所有协议条目的 `id` 必须唯一，不可重复 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 提取所有 `id` 2. 检查是否有重复 |
| **预期结果** | `Set(data.map(e => e.id)).length === data.length` |
| **验证方式** | 自动化 |

---

### PT-010: 协议顺序稳定性

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-010 |
| **优先级** | P2 (Medium) |
| **类别** | 非功能性 |
| **描述** | 连续多次请求返回的协议顺序应一致，避免前端 UI 抖动 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 连续 3 次请求同一接口 2. 比较各次返回的 `data` 数组顺序 |
| **预期结果** | 三次请求中协议 ID 的排列顺序完全一致 |
| **验证方式** | 自动化 |

---

### PT-011: 响应时间在合理范围内

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-011 |
| **优先级** | P2 (Medium) |
| **类别** | 性能 |
| **描述** | 协议列表接口为静态数据查询，响应时间应 < 100ms |
| **前提条件** | 1. 后端服务运行中 2. 网络正常（本地或局域网） |
| **测试步骤** | 1. 预热请求 1 次 2. 连续发送 10 次请求，记录每次耗时 |
| **预期结果** | p95 响应时间 < 100ms |
| **验证方式** | 自动化 |

---

### PT-012: 不携带 Authorization 头返回 401

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-012 |
| **优先级** | P1 (High) |
| **类别** | 安全 / 认证 |
| **描述** | 未携带 Token 请求应被拦截 |
| **前提条件** | 后端认证中间件启用 |
| **测试步骤** | 1. 不携带 `Authorization` 头 2. 发送 `GET /api/v1/protocols` |
| **预期结果** | HTTP 状态码 = 401<br>响应体包含错误信息 |
| **验证方式** | 自动化 |

---

### PT-013: 携带无效/过期 Token 返回 401

| 属性 | 内容 |
|------|------|
| **测试ID** | PT-013 |
| **优先级** | P1 (High) |
| **类别** | 安全 / 认证 |
| **描述** | 无效或过期 Token 请求应被拒绝 |
| **前提条件** | 准备好一个已过期或格式错误的 JWT Token |
| **测试步骤** | 1. 携带 `Authorization: Bearer {invalid_token}` 头 2. 发送请求 |
| **预期结果** | HTTP 状态码 = 401<br>响应体包含适当的错误信息 |
| **验证方式** | 自动化 |

---

## 3. 串口扫描 API 测试

### SP-001: 正常请求返回串口列表

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-001 |
| **优先级** | P0 (Critical) |
| **类别** | 正常路径 / 冒烟测试 |
| **描述** | 已认证用户在可访问串口的系统中请求，应返回有效的串口列表 |
| **前提条件** | 1. 后端服务运行中 2. 持有有效 Token 3. 系统有可用串口（或模拟串口） |
| **测试步骤** | 1. 携带有效 Token 2. 发送 `GET /api/v1/system/serial-ports` |
| **预期结果** | 1. HTTP 状态码 = 200<br>2. 响应体 `code: 200`<br>3. `data` 为数组<br>4. 每个元素包含 `path` 和 `description` 字段 |
| **验证方式** | 自动化 |

---

### SP-002: 串口条目数据结构验证

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-002 |
| **优先级** | P0 (Critical) |
| **类别** | 数据结构 |
| **描述** | 验证每个串口条目的 `path` 和 `description` 字段类型和存在性 |
| **前提条件** | 同 SP-001 |
| **测试步骤** | 1. 遍历 `data` 数组 2. 检查每个元素 |
| **预期结果** | 每个元素满足：<br>- `path`: String 非空（如 `/dev/ttyUSB0` 或 `COM1`）<br>- `description`: String（可为空字符串） |
| **验证方式** | 自动化 |

---

### SP-003: 无可用串口时返回空数组

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-003 |
| **优先级** | P1 (High) |
| **类别** | 边界 / 空数据 |
| **描述** | 系统无可用串口时应返回空数组而非报错 |
| **前提条件** | 1. 运行环境无串口设备（如纯 Docker 容器、CI 环境）2. 持有有效 Token |
| **测试步骤** | 1. 在无串口环境中发送请求 |
| **预期结果** | 1. HTTP 状态码 = 200<br>2. `data` = `[]` (空数组)<br>3. 不应返回 500 或异常 |
| **验证方式** | 自动化（需在 CI/Docker 环境执行） |

---

### SP-004: 串口路径格式验证

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-004 |
| **优先级** | P2 (Medium) |
| **类别** | 数据完整性 |
| **描述** | 验证返回的串口路径符合所在平台的命名规范 |
| **前提条件** | 同 SP-001 |
| **测试步骤** | 1. 获取串口列表 2. 根据平台检查路径格式 |
| **预期结果** | Linux: 匹配 `/dev/tty(USB|ACM|S)\\d+`<br>macOS: 匹配 `/dev/(cu|tty)\\.(usbserial|usbmodem).*`<br>Windows: 匹配 `COM[1-9][0-9]*` |
| **验证方式** | 自动化 |

---

### SP-005: 串口 path 唯一性

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-005 |
| **优先级** | P1 (High) |
| **类别** | 数据完整性 |
| **描述** | 每个串口的 `path` 必须唯一，不可出现重复 |
| **前提条件** | 同 SP-001 |
| **测试步骤** | 1. 提取所有 `path` 2. 检查重复 |
| **预期结果** | `Set(data.map(e => e.path)).length === data.length` |
| **验证方式** | 自动化 |

---

### SP-006: 串口 description 非 null

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-006 |
| **优先级** | P2 (Medium) |
| **类别** | 数据完整性 |
| **描述** | 每个串口的 `description` 字段不能为 null（可为空字符串） |
| **前提条件** | 同 SP-001 |
| **测试步骤** | 1. 遍历所有条目 2. 检查 `description` 字段 |
| **预期结果** | 所有条目的 `description` 字段类型为 String（非 null） |
| **验证方式** | 自动化 |

---

### SP-007: 响应体顶层结构验证

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-007 |
| **优先级** | P1 (High) |
| **类别** | 数据结构 |
| **描述** | 校验响应体顶层仅包含 `code` 和 `data` |
| **前提条件** | 同 SP-001 |
| **测试步骤** | 1. 获取 JSON 根对象 keys |
| **预期结果** | 仅包含 `code` 和 `data` |
| **验证方式** | 自动化 |

---

### SP-008: 不携带 Authorization 头返回 401

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-008 |
| **优先级** | P1 (High) |
| **类别** | 安全 / 认证 |
| **描述** | 未认证用户请求串口列表应被拒绝 |
| **前提条件** | 认证中间件启用 |
| **测试步骤** | 1. 不携带 `Authorization` 头 2. 发送 `GET /api/v1/system/serial-ports` |
| **预期结果** | HTTP 状态码 = 401 |
| **验证方式** | 自动化 |

---

### SP-009: 携带无效 Token 返回 401

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-009 |
| **优先级** | P1 (High) |
| **类别** | 安全 / 认证 |
| **描述** | 无效 Token 请求串口列表应被拒绝 |
| **前提条件** | 准备好无效 Token |
| **测试步骤** | 1. 携带 `Authorization: Bearer {invalid_token}` 2. 发送请求 |
| **预期结果** | HTTP 状态码 = 401 |
| **验证方式** | 自动化 |

---

### SP-010: 串口扫描 API 响应时间

| 属性 | 内容 |
|------|------|
| **测试ID** | SP-010 |
| **优先级** | P2 (Medium) |
| **类别** | 性能 |
| **描述** | 串口扫描为系统级查询，响应时间应 < 500ms |
| **前提条件** | 同 SP-001 |
| **测试步骤** | 1. 预热 1 次 2. 连续发送 5 次请求，记录耗时 |
| **预期结果** | p95 响应时间 < 500ms（考虑串口枚举系统调用开销） |
| **验证方式** | 自动化 |

---

## 4. 错误处理测试

### ER-001: 错误的 HTTP 方法 (POST 协议列表)

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-001 |
| **优先级** | P1 (High) |
| **类别** | 错误处理 |
| **描述** | 对 GET-only 端点使用错误方法，应返回 405 Method Not Allowed |
| **前提条件** | 持有有效 Token |
| **测试步骤** | 1. 使用 POST 方法请求 `/api/v1/protocols` |
| **预期结果** | HTTP 状态码 = 405<br>响应包含适当的错误信息 |
| **验证方式** | 自动化 |

---

### ER-002: 错误的 HTTP 方法 (POST 串口列表)

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-002 |
| **优先级** | P1 (High) |
| **类别** | 错误处理 |
| **描述** | 对 GET-only 端点使用错误方法，应返回 405 |
| **前提条件** | 持有有效 Token |
| **测试步骤** | 1. 使用 POST 方法请求 `/api/v1/system/serial-ports` |
| **预期结果** | HTTP 状态码 = 405 |
| **验证方式** | 自动化 |

---

### ER-003: 不存在的 API 路径

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-003 |
| **优先级** | P2 (Medium) |
| **类别** | 错误处理 |
| **描述** | 请求不存在的 API 端点应返回 404 |
| **前提条件** | 持有有效 Token |
| **测试步骤** | 1. 请求 `GET /api/v1/protocol` (单数) 或 `/api/v1/protocols_v2` |
| **预期结果** | HTTP 状态码 = 404 |
| **验证方式** | 自动化 |

---

### ER-004: 请求体包含无关数据 (GET 请求不应有 body)

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-004 |
| **优先级** | P2 (Medium) |
| **类别** | 健壮性 |
| **描述** | 对 GET 接口附带请求体，服务器应忽略或返回成功，不应 crash |
| **前提条件** | 持有有效 Token |
| **测试步骤** | 1. GET `/api/v1/protocols` 附带 JSON body `{"foo": "bar"}` |
| **预期结果** | HTTP 状态码 = 200（忽略多余 body）或 400（拒绝），但不得 500 |
| **验证方式** | 自动化 |

---

### ER-005: 响应包含 CORS 头（Web 前端跨域）

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-005 |
| **优先级** | P1 (High) |
| **类别** | 跨域 / Web 部署 |
| **描述** | Web 前端需要后端支持 CORS，检查响应头 |
| **前提条件** | 后端 CORS 配置启用 |
| **测试步骤** | 1. 发送 OPTIONS 预检请求 2. 检查响应头 |
| **预期结果** | 1. `Access-Control-Allow-Origin` 设置正确<br>2. `Access-Control-Allow-Methods` 包含 GET, POST, OPTIONS<br>3. `Access-Control-Allow-Headers` 包含 Authorization, Content-Type |
| **验证方式** | 自动化 |

---

### ER-006: 超大 URL / 恶意查询参数

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-006 |
| **优先级** | P2 (Medium) |
| **类别** | 健壮性 / 安全 |
| **描述** | 携带超长查询参数或恶意字符不应导致服务崩溃 |
| **前提条件** | 持有有效 Token |
| **测试步骤** | 1. 请求 `GET /api/v1/protocols?foo={1000个字符}` 2. 检查响应 |
| **预期结果** | 服务正常返回 200（忽略未知参数）或 414 URI Too Long，但不得 500 |
| **验证方式** | 自动化 |

---

### ER-007: 并发请求压力测试

| 属性 | 内容 |
|------|------|
| **测试ID** | ER-007 |
| **优先级** | P2 (Medium) |
| **类别** | 并发 / 健壮性 |
| **描述** | 短时间内大量并发请求两个接口，服务不应崩溃或返回错误 |
| **前提条件** | 持有有效 Token |
| **测试步骤** | 1. 使用 20 并发同时请求协议列表<br>2. 使用 20 并发同时请求串口列表<br>3. 混合请求两个接口 |
| **预期结果** | 所有请求成功返回 200，无 500 错误 |
| **验证方式** | 自动化 |

---

## 5. 边界与性能测试

### BP-001: Content-Type 头正确

| 属性 | 内容 |
|------|------|
| **测试ID** | BP-001 |
| **优先级** | P1 (High) |
| **类别** | 响应头 |
| **描述** | 成功响应必须携带正确的 Content-Type |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 检查两个接口的响应头 `Content-Type` |
| **预期结果** | `Content-Type` = `application/json` (或 `application/json; charset=utf-8`) |
| **验证方式** | 自动化 |

---

### BP-002: 空 Token 格式（Bearer 后无内容）

| 属性 | 内容 |
|------|------|
| **测试ID** | BP-002 |
| **优先级** | P2 (Medium) |
| **类别** | 边界 / 安全 |
| **描述** | 提供格式错误的 Authorization 头 |
| **前提条件** | 认证中间件启用 |
| **测试步骤** | 1. 携带 `Authorization: Bearer ` (无 token) 2. 请求两个接口 |
| **预期结果** | HTTP 状态码 = 401 |
| **验证方式** | 自动化 |

---

### BP-003: 响应体非空字符集编码

| 属性 | 内容 |
|------|------|
| **测试ID** | BP-003 |
| **优先级** | P2 (Medium) |
| **类别** | 数据完整性 |
| **描述** | 中文描述字段（如"虚拟设备（用于测试）"）必须正确编码为 UTF-8 |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 检查协议列表的 `description` 字段 2. 验证中文字符正确渲染 |
| **预期结果** | 中文字符无乱码，编码格式为 UTF-8 |
| **验证方式** | 自动化 |

---

### BP-004: config_schema 不可为 null

| 属性 | 内容 |
|------|------|
| **测试ID** | BP-004 |
| **优先级** | P1 (High) |
| **类别** | 边界 / 前端兼容性 |
| **描述** | 前端 `ProtocolInfo.fromJson` 对 `config_schema` 有 null 回退，但后端不应返回 null |
| **前提条件** | 同 PT-001 |
| **测试步骤** | 1. 遍历所有协议的 `config_schema` 字段 |
| **预期结果** | 所有协议的 `config_schema` 不为 null，且为有效 Object |
| **验证方式** | 自动化 |

---

## 6. 测试环境与前提

### 6.1 环境要求

| 环境变量/组件 | 说明 |
|--------------|------|
| 后端服务 | `kayak-backend` 编译并运行（`cargo run`） |
| 数据库 | PostgreSQL 已初始化、Migration 已执行 |
| 认证系统 | 用户注册/登录可用，JWT 签发正常 |
| 测试工具 | curl / httpie / Python requests / k6 / Postman |

### 6.2 测试数据

| 数据项 | 说明 | 获取方式 |
|--------|------|---------|
| `valid_token` | 有效 JWT Token | 调用登录 API 获取 |
| `expired_token` | 已过期 JWT Token | 构造或等待过期 |
| `invalid_token` | 格式错误/签名无效 Token | 手动构造 |
| `malformed_token` | 随机字符串 | 任意生成 |

### 6.3 串口测试环境

| 平台 | 测试环境 | 串口可用性 |
|------|---------|-----------|
| Linux (CI) | Docker 容器 | 通常无串口 → 测试空数组场景 |
| Linux (dev) | 开发机 | 可能有 `/dev/ttyS*` |
| macOS (dev) | 开发机 | 通常无物理串口，空数组场景 |
| Windows (dev) | 开发机 | 可能有 `COM1` |

---

## 7. 测试数据期望

### 7.1 协议列表期望数据

```json
{
  "code": 200,
  "data": [
    {
      "id": "virtual",
      "name": "Virtual",
      "description": "虚拟设备（用于测试）",
      "config_schema": {
        "mode": {
          "type": "enum",
          "label": "模式",
          "description": "虚拟设备数据生成模式",
          "required": true,
          "values": ["random", "fixed", "sine", "ramp"]
        },
        "dataType": {
          "type": "enum",
          "label": "数据类型",
          "required": true,
          "values": ["number", "integer", "string", "boolean"]
        },
        "accessType": {
          "type": "enum",
          "label": "访问类型",
          "required": true,
          "values": ["ro", "wo", "rw"]
        },
        "minValue": {
          "type": "number",
          "label": "最小值",
          "required": true
        },
        "maxValue": {
          "type": "number",
          "label": "最大值",
          "required": true
        },
        "fixedValue": {
          "type": "number",
          "label": "固定值",
          "required": false
        },
        "sampleInterval": {
          "type": "number",
          "label": "采样间隔(ms)",
          "required": false,
          "default": 1000
        }
      }
    },
    {
      "id": "modbus_tcp",
      "name": "Modbus TCP",
      "description": "Modbus TCP/IP 协议",
      "config_schema": {
        "host": {
          "type": "string",
          "label": "主机地址",
          "description": "Modbus 从站 IP 地址",
          "required": true,
          "format": "ip-address"
        },
        "port": {
          "type": "integer",
          "label": "端口",
          "required": false,
          "default": 502,
          "min": 1,
          "max": 65535
        },
        "slave_id": {
          "type": "integer",
          "label": "从站ID",
          "required": false,
          "default": 1,
          "min": 1,
          "max": 247
        },
        "timeout_ms": {
          "type": "integer",
          "label": "超时时间(ms)",
          "required": false,
          "default": 5000
        },
        "connection_pool_size": {
          "type": "integer",
          "label": "连接池大小",
          "required": false,
          "default": 4
        }
      }
    },
    {
      "id": "modbus_rtu",
      "name": "Modbus RTU",
      "description": "Modbus RTU 串口协议",
      "config_schema": {
        "port": {
          "type": "string",
          "label": "串口",
          "description": "串口设备路径",
          "required": true
        },
        "baud_rate": {
          "type": "enum",
          "label": "波特率",
          "required": false,
          "default": 9600,
          "values": [9600, 19200, 38400, 57600, 115200]
        },
        "data_bits": {
          "type": "enum",
          "label": "数据位",
          "required": false,
          "default": 8,
          "values": [7, 8]
        },
        "stop_bits": {
          "type": "enum",
          "label": "停止位",
          "required": false,
          "default": 1,
          "values": [1, 2]
        },
        "parity": {
          "type": "enum",
          "label": "校验位",
          "required": false,
          "default": "None",
          "values": ["None", "Even", "Odd"]
        },
        "slave_id": {
          "type": "integer",
          "label": "从站ID",
          "required": false,
          "default": 1,
          "min": 1,
          "max": 247
        },
        "timeout_ms": {
          "type": "integer",
          "label": "超时时间(ms)",
          "required": false,
          "default": 1000
        }
      }
    }
  ]
}
```

### 7.2 串口列表期望数据

```json
{
  "code": 200,
  "data": [
    { "path": "/dev/ttyUSB0", "description": "USB Serial" },
    { "path": "/dev/ttyACM0", "description": "USB ACM" }
  ]
}
```

---

## 8. 风险评估

| 风险 | 影响 | 可能性 | 缓解措施 |
|------|------|--------|---------|
| 串口扫描在不同平台行为不一致 | 高 | 中 | 三平台 CI 验证，空数组回退 |
| `config_schema` 定义与实际驱动代码不一致 | 高 | 中 | 测试时对照 `protocol_config.dart` 模型验证 |
| 认证中间件未覆盖 `/api/v1/system/*` 路径 | 中 | 低 | PT-012/SP-008 显式测试 |
| 响应数据结构变更破坏前端 | 高 | 中 | 所有测试与前端的 `fromJson` 逻辑对齐 |
| Docker 环境无串口导致 500 | 中 | 中 | SP-003 验证空数组场景 |
| CORS 未配置导致 Web 前端无法调用 | 高 | 中 | ER-005 验证 CORS 头 |

---

## 9. 测试用例汇总

### 9.1 汇总表

| 测试ID | 测试名称 | 分类 | 优先级 | 端点 |
|--------|---------|------|--------|------|
| PT-001 | 正常请求返回协议列表 | 冒烟测试 | P0 | `/api/v1/protocols` |
| PT-002 | 响应包含全部三种协议 | 数据完整性 | P0 | `/api/v1/protocols` |
| PT-003 | 协议条目数据结构验证 | 数据结构 | P0 | `/api/v1/protocols` |
| PT-004 | Virtual 协议 config_schema 完整性 | config_schema | P0 | `/api/v1/protocols` |
| PT-005 | Modbus TCP 协议 config_schema 完整性 | config_schema | P0 | `/api/v1/protocols` |
| PT-006 | Modbus RTU 协议 config_schema 完整性 | config_schema | P0 | `/api/v1/protocols` |
| PT-007 | config_schema 包含字段约束信息 | config_schema | P1 | `/api/v1/protocols` |
| PT-008 | 响应体顶层结构验证 | 数据结构 | P1 | `/api/v1/protocols` |
| PT-009 | 协议 ID 唯一性 | 数据完整性 | P1 | `/api/v1/protocols` |
| PT-010 | 协议顺序稳定性 | 非功能性 | P2 | `/api/v1/protocols` |
| PT-011 | 响应时间在合理范围内 | 性能 | P2 | `/api/v1/protocols` |
| PT-012 | 不携带 Authorization 头返回 401 | 安全/认证 | P1 | `/api/v1/protocols` |
| PT-013 | 携带无效 Token 返回 401 | 安全/认证 | P1 | `/api/v1/protocols` |
| SP-001 | 正常请求返回串口列表 | 冒烟测试 | P0 | `/api/v1/system/serial-ports` |
| SP-002 | 串口条目数据结构验证 | 数据结构 | P0 | `/api/v1/system/serial-ports` |
| SP-003 | 无可用串口时返回空数组 | 边界/空数据 | P1 | `/api/v1/system/serial-ports` |
| SP-004 | 串口路径格式验证 | 数据完整性 | P2 | `/api/v1/system/serial-ports` |
| SP-005 | 串口 path 唯一性 | 数据完整性 | P1 | `/api/v1/system/serial-ports` |
| SP-006 | 串口 description 非 null | 数据完整性 | P2 | `/api/v1/system/serial-ports` |
| SP-007 | 响应体顶层结构验证 | 数据结构 | P1 | `/api/v1/system/serial-ports` |
| SP-008 | 不携带 Authorization 头返回 401 | 安全/认证 | P1 | `/api/v1/system/serial-ports` |
| SP-009 | 携带无效 Token 返回 401 | 安全/认证 | P1 | `/api/v1/system/serial-ports` |
| SP-010 | 串口扫描 API 响应时间 | 性能 | P2 | `/api/v1/system/serial-ports` |
| ER-001 | 错误 HTTP 方法 (POST 协议列表) | 错误处理 | P1 | `/api/v1/protocols` |
| ER-002 | 错误 HTTP 方法 (POST 串口列表) | 错误处理 | P1 | `/api/v1/system/serial-ports` |
| ER-003 | 不存在的 API 路径 | 错误处理 | P2 | 两者 |
| ER-004 | 请求体包含无关数据 | 健壮性 | P2 | 两者 |
| ER-005 | 响应包含 CORS 头 | 跨域/Web | P1 | 两者 |
| ER-006 | 超大 URL / 恶意查询参数 | 健壮性 | P2 | 两者 |
| ER-007 | 并发请求压力测试 | 并发 | P2 | 两者 |
| BP-001 | Content-Type 头正确 | 响应头 | P1 | 两者 |
| BP-002 | 空 Token 格式 | 边界/安全 | P2 | 两者 |
| BP-003 | UTF-8 中文编码正确 | 数据完整性 | P2 | `/api/v1/protocols` |
| BP-004 | config_schema 不可为 null | 边界 | P1 | `/api/v1/protocols` |

### 9.2 统计

| 指标 | 数值 |
|------|------|
| **总用例数** | **34** |
| 协议列表 API (PT) | 13 |
| 串口扫描 API (SP) | 10 |
| 错误处理 (ER) | 7 |
| 边界与性能 (BP) | 4 |
| P0 (Critical) 用例 | 8 |
| P1 (High) 用例 | 15 |
| P2 (Medium) 用例 | 11 |

### 9.3 自动化建议

| 测试类别 | 自动化方式 | 说明 |
|---------|-----------|------|
| 冒烟/数据完整性 | Rust `#[cfg(test)]` 集成测试 | `src/tests/api_protocols.rs` |
| config_schema 校验 | JSON Schema 对比 | 用 `TestData::expected_protocols()` 做 deep-equal |
| 认证测试 | 分别发送带/不带 Token 的请求 | HTTP client 集成测试 |
| 串口空数组 | Docker CI 环境 | 利用无串口环境 |
| 并发/压力 | k6 或 locust 脚本 | 可选 |
| CORS | 预检 OPTIONS 请求 | curl 脚本 |

---

**文档结束**
