# R1-S1-003 测试用例文档 (驱动部分)

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S1-003 |
| 测试类型 | 单元测试 + 集成测试 |
| 测试范围 | Modbus TCP 驱动实现 (drivers/modbus/tcp.rs) - 仅驱动部分，模拟设备见 R1-S1-004 |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-02 |
| 版本 | 1.1 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [连接管理测试](#2-连接管理测试)
3. [读取操作测试](#3-读取操作测试)
4. [写入操作测试](#4-写入操作测试)
5. [错误处理测试](#5-错误处理测试)
6. [MBAP/PDU 解析测试](#6-mbappdu-解析测试)
7. [并发与超时测试](#7-并发与超时测试)
8. [DriverAccess trait 测试](#8-driveraccess-trait-测试)
9. [测试数据需求](#9-测试数据需求)
10. [测试环境](#10-测试环境)
11. [风险与假设](#11-风险与假设)
12. [测试用例汇总](#12-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证 Modbus TCP 驱动的正确性，确保：
- 驱动程序正确实现 `DriverAccess` trait (包含 `read_point(point_id: Uuid)` 和 `write_point(point_id: Uuid, value: PointValue)`)
- 连接/断开连接操作正确工作
- 内部映射机制正确 (point_id -> Modbus address)
- 错误处理涵盖 Modbus 异常码 (01-08) 和通信错误
- MBAP/PDU 解析和组装正确工作
- 超时和重试机制正确实现

### 1.2 重要说明 - API 设计

**关键**：驱动程序通过 `DriverAccess` trait 提供高级 API：
- `read_point(point_id: Uuid) -> Result<PointValue>`: 根据测点 UUID 读取值，驱动内部映射到 Modbus 地址
- `write_point(point_id: Uuid, value: PointValue) -> Result<()>`: 根据测点 UUID 写入值，驱动内部映射到 Modbus 地址

驱动程序内部维护测点配置映射表 (point_id -> ModbusAddress, FunctionCode, ValueType)。测试用例应验证驱动正确完成这一映射过程。

### 1.3 测试范围

| 模块 | 测试内容 |
|------|---------|
| 连接管理 | TCP 连接建立、断开、重复连接、无效地址 |
| 读取操作 | 通过 read_point() 读取各类测点 (线圈、离散输入、保持寄存器、输入寄存器) |
| 写入操作 | 通过 write_point() 写入各类测点 (线圈、保持寄存器) |
| 错误处理 | 服务器异常响应、连接断开、超时、无效响应、测点未找到 |
| MBAP/PDU | MBAP 头部解析、PDU 组装、事务 ID 匹配 |
| Trait 实现 | DriverAccess::read_point/write_point, DriverLifecycle::connect/disconnect/is_connected |
| 内部映射 | point_id 到 Modbus address 的正确映射 |

### 1.4 测试策略

- **单元测试**：使用 mock TCP 流验证协议逻辑
- **集成测试**：连接真实或模拟的 Modbus TCP 服务器
- **边界测试**：验证数量限制 (coils: 1-2000, discrete inputs: 1-2000, registers: 1-125)
- **错误注入**：模拟网络错误、服务器异常响应

---

## 2. 连接管理测试

### TC-101: ModbusTcpDriver 连接成功

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-101 |
| **测试名称** | ModbusTcpDriver 连接成功 |
| **测试目的** | 验证驱动能够成功连接到有效的 Modbus TCP 服务器 |
| **前置条件** | ModbusTcpDriver 已实现，存在可用的模拟服务器 |
| **测试步骤** | 1. 创建 ModbusTcpDriver 实例，配置有效地址和端口<br>2. 调用 connect() 方法<br>3. 验证返回 Ok(())<br>4. 调用 is_connected() 验证返回 true |
| **预期结果** | 1. connect() 返回 Ok(())<br>2. is_connected() 返回 true |
| **测试数据** | host: "127.0.0.1", port: 1502, unit_id: 1 |
| **优先级** | P0 |

---

### TC-102: ModbusTcpDriver 连接无效地址

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-102 |
| **测试名称** | ModbusTcpDriver 连接无效地址 |
| **测试目的** | 验证驱动正确处理无效地址连接失败 |
| **前置条件** | ModbusTcpDriver 已实现 |
| **测试步骤** | 1. 创建 ModbusTcpDriver 实例，配置无效地址<br>2. 调用 connect() 方法<br>3. 验证返回 Err |
| **预期结果** | connect() 返回 Err(DriverError::IoError 或 ConnectionFailed) |
| **测试数据** | host: "192.0.2.1" (TEST-NET-1, 不可路由), port: 1502 |
| **优先级** | P0 |

---

### TC-103: ModbusTcpDriver 连接拒绝

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-103 |
| **测试名称** | ModbusTcpDriver 连接拒绝 |
| **测试目的** | 验证驱动正确处理连接被拒绝的情况 |
| **前置条件** | ModbusTcpDriver 已实现，没有服务监听目标端口 |
| **测试步骤** | 1. 创建 ModbusTcpDriver 实例，连接到没有服务监听的端口<br>2. 调用 connect() 方法<br>3. 验证返回 Err |
| **预期结果** | connect() 返回 Err(DriverError::IoError("Connection refused")) |
| **测试数据** | host: "127.0.0.1", port: 1503 (无服务) |
| **优先级** | P0 |

---

### TC-104: ModbusTcpDriver 重复连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-104 |
| **测试名称** | ModbusTcpDriver 重复连接 |
| **测试目的** | 验证驱动在已连接状态下再次调用 connect() 的行为 |
| **前置条件** | ModbusTcpDriver 已实现并已连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 再次调用 connect() 方法<br>3. 验证返回 Err(DriverError::AlreadyConnected) 或 Ok(()) |
| **预期结果** | 返回 Err(DriverError::AlreadyConnected) 或根据实现允许静默成功 |
| **测试数据** | host: "127.0.0.1", port: 1502 |
| **优先级** | P1 |

---

### TC-105: ModbusTcpDriver 断开连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-105 |
| **测试名称** | ModbusTcpDriver 断开连接 |
| **测试目的** | 验证驱动能够正确断开连接 |
| **前置条件** | ModbusTcpDriver 已实现并已连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 调用 disconnect() 方法<br>3. 验证返回 Ok(())<br>4. 验证 is_connected() 返回 false |
| **预期结果** | 1. disconnect() 返回 Ok(())<br>2. is_connected() 返回 false |
| **测试数据** | host: "127.0.0.1", port: 1502 |
| **优先级** | P0 |

---

### TC-106: ModbusTcpDriver 未连接时断开

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-106 |
| **测试名称** | ModbusTcpDriver 未连接时断开 |
| **测试目的** | 验证驱动在未连接状态下调用 disconnect() 的行为 |
| **前置条件** | ModbusTcpDriver 已实现但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusTcpDriver<br>2. 调用 disconnect() 方法<br>3. 验证返回 Err(DriverError::NotConnected) 或 Ok(()) |
| **预期结果** | 返回 Err(DriverError::NotConnected) 或 Ok(()) (实现决定) |
| **测试数据** | host: "127.0.0.1", port: 1502 |
| **优先级** | P1 |

---

## 3. 读取操作测试

### TC-201: read_point() 成功读取线圈测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-201 |
| **测试名称** | read_point() 成功读取线圈测点 (FC01) |
| **测试目的** | 验证驱动能够通过 point_id 正确读取线圈状态 |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置已加载，模拟服务器线圈地址 0 已设置 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射: point_uuid -> ModbusAddress(0), FunctionCode::ReadCoils<br>3. 调用 read_point(point_uuid)<br>4. 验证返回 Ok(PointValue::Bool(true/false)) |
| **预期结果** | 返回 Ok(PointValue::Bool) 包含布尔值 |
| **测试数据** | point_uuid: UUID, ModbusAddress: 0x0000 |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_read_point_coil_success() {
    let config = PointConfig {
        point_id: uuid!("550e8400-e29b-41d4-a716-446655440000"),
        address: ModbusAddress::new(0),
        function_code: FunctionCode::ReadCoils,
        value_type: ValueType::Coil,
    };
    let mut driver = ModbusTcpDriver::new("127.0.0.1:1502".parse().unwrap(), 1);
    driver.configure_points(vec![config]).unwrap();
    driver.connect().await.unwrap();

    let result = driver.read_point(uuid!("550e8400-e29b-41d4-a716-446655440000")).await;
    assert!(result.is_ok());
    assert!(matches!(result.unwrap(), PointValue::Bool(_)));
}
```

---

### TC-202: read_point() 成功读取离散输入测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-202 |
| **测试名称** | read_point() 成功读取离散输入测点 (FC02) |
| **测试目的** | 验证驱动能够通过 point_id 正确读取离散输入状态 |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置已加载 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射: point_uuid -> ModbusAddress(0), FunctionCode::ReadDiscreteInputs<br>3. 调用 read_point(point_uuid)<br>4. 验证返回 Ok(PointValue::Bool) |
| **预期结果** | 返回 Ok(PointValue::Bool) 包含布尔值 |
| **测试数据** | point_uuid: UUID, ModbusAddress: 0x0000 |
| **优先级** | P0 |

---

### TC-203: read_point() 成功读取保持寄存器测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-203 |
| **测试名称** | read_point() 成功读取保持寄存器测点 (FC03) |
| **测试目的** | 验证驱动能够通过 point_id 正确读取保持寄存器 |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置已加载 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射: point_uuid -> ModbusAddress(0), FunctionCode::ReadHoldingRegisters<br>3. 调用 read_point(point_uuid)<br>4. 验证返回 Ok(PointValue::U16) |
| **预期结果** | 返回 Ok(PointValue::U16) 包含 u16 值 |
| **测试数据** | point_uuid: UUID, ModbusAddress: 0x0000 |
| **优先级** | P0 |

---

### TC-204: read_point() 成功读取输入寄存器测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-204 |
| **测试名称** | read_point() 成功读取输入寄存器测点 (FC04) |
| **测试目的** | 验证驱动能够通过 point_id 正确读取输入寄存器 |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置已加载 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射: point_uuid -> ModbusAddress(0), FunctionCode::ReadInputRegisters<br>3. 调用 read_point(point_uuid)<br>4. 验证返回 Ok(PointValue::U16) |
| **预期结果** | 返回 Ok(PointValue::U16) 包含 u16 值 |
| **测试数据** | point_uuid: UUID, ModbusAddress: 0x0000 |
| **优先级** | P0 |

---

### TC-205: read_point() 无效测点 ID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-205 |
| **测试名称** | read_point() 无效测点 ID |
| **测试目的** | 验证驱动正确处理未配置的测点 ID |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 调用 read_point(unknown_uuid)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(PointError::NotFound 或 DriverError::InvalidPoint) |
| **测试数据** | unknown_uuid: 不在配置中的 UUID |
| **优先级** | P0 |

---

### TC-206: read_point() 读取时 Modbus 地址无效

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-206 |
| **测试名称** | read_point() 读取时 Modbus 地址无效 |
| **测试目的** | 验证驱动正确处理服务器返回的非法地址异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置指向无效地址 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射指向地址 0xFFFF<br>3. 调用 read_point(point_uuid)<br>4. 验证返回 Err 或服务器返回 IllegalDataAddress 异常 |
| **预期结果** | 返回 Err 包含 IllegalDataAddress 或 InvalidAddress 描述 |
| **测试数据** | point_uuid: UUID, ModbusAddress: 0xFFFF |
| **优先级** | P1 |

---

### TC-207: read_point() 离散输入数量超限 (超过 2000)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-207 |
| **测试名称** | read_point() 离散输入数量超限 |
| **测试目的** | 验证驱动内部正确拒绝超过最大允许数量的请求 (ReadDiscreteInputs max: 2000) |
| **前置条件** | ModbusTcpDriver 已实现 |
| **测试步骤** | 1. 验证驱动在内部请求 ReadDiscreteInputs 时数量不超过 2000<br>2. 如果驱动支持批量读取，验证边界检查 |
| **预期结果** | 驱动正确处理边界，或返回 Err(DriverError::InvalidValue) |
| **测试数据** | ReadDiscreteInputs 最大数量: 2000 |
| **优先级** | P0 |

---

### TC-208: read_point() 输入寄存器数量超限 (超过 125)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-208 |
| **测试名称** | read_point() 输入寄存器数量超限 |
| **测试目的** | 验证驱动内部正确拒绝超过最大允许数量的请求 (ReadInputRegisters max: 125) |
| **前置条件** | ModbusTcpDriver 已实现 |
| **测试步骤** | 1. 验证驱动在内部请求 ReadInputRegisters 时数量不超过 125<br>2. 如果驱动支持批量读取，验证边界检查 |
| **预期结果** | 驱动正确处理边界，或返回 Err(DriverError::InvalidValue) |
| **测试数据** | ReadInputRegisters 最大数量: 125 |
| **优先级** | P0 |

---

### TC-209: read_point() 读取操作未连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-209 |
| **测试名称** | read_point() 读取操作未连接 |
| **测试目的** | 验证驱动在未连接状态下调用读取操作的行为 |
| **前置条件** | ModbusTcpDriver 已创建但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusTcpDriver<br>2. 调用 read_point(valid_uuid)<br>3. 验证返回 Err(DriverError::NotConnected) |
| **预期结果** | 返回 Err(DriverError::NotConnected) |
| **测试数据** | valid_uuid: 任意有效 UUID |
| **优先级** | P0 |

---

## 4. 写入操作测试

### TC-301: write_point() 成功写入线圈测点 ON

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-301 |
| **测试名称** | write_point() 成功写入线圈测点 ON (FC05) |
| **测试目的** | 验证驱动能够通过 point_id 正确写入单个线圈为 ON (0xFF00) |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置已加载 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射: point_uuid -> ModbusAddress(0), FunctionCode::WriteSingleCoil<br>3. 调用 write_point(point_uuid, PointValue::Bool(true))<br>4. 验证返回 Ok(()) |
| **预期结果** | write_point() 返回 Ok(()) |
| **测试数据** | point_uuid: UUID, 值: true |
| **优先级** | P0 |

---

### TC-302: write_point() 成功写入线圈测点 OFF

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-302 |
| **测试名称** | write_point() 成功写入线圈测点 OFF (FC05) |
| **测试目的** | 验证驱动能够通过 point_id 正确写入单个线圈为 OFF (0x0000) |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 调用 write_point(point_uuid, PointValue::Bool(false))<br>3. 验证返回 Ok(()) |
| **预期结果** | write_point() 返回 Ok(()) |
| **测试数据** | point_uuid: UUID, 值: false |
| **优先级** | P0 |

---

### TC-303: write_point() 成功写入保持寄存器测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-303 |
| **测试名称** | write_point() 成功写入保持寄存器测点 (FC06) |
| **测试目的** | 验证驱动能够通过 point_id 正确写入单个寄存器 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射: point_uuid -> ModbusAddress(0), FunctionCode::WriteSingleRegister<br>3. 调用 write_point(point_uuid, PointValue::U16(0x1234))<br>4. 验证返回 Ok(()) |
| **预期结果** | write_point() 返回 Ok(()) |
| **测试数据** | point_uuid: UUID, 值: 0x1234 |
| **优先级** | P0 |

---

### TC-304: write_point() 写入只读测点 (离散输入)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-304 |
| **测试名称** | write_point() 写入只读测点 (离散输入) |
| **测试目的** | 验证驱动正确拒绝写入只读测点 (ReadDiscreteInputs 类型) |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置为只读类型 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点为 ReadDiscreteInputs 类型 (只读)<br>3. 调用 write_point()<br>4. 验证返回 Err |
| **预期结果** | 返回 Err(DriverError::ReadOnlyPoint) |
| **测试数据** | 只读类型测点 |
| **优先级** | P0 |

---

### TC-305: write_point() 写入只读测点 (输入寄存器)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-305 |
| **测试名称** | write_point() 写入只读测点 (输入寄存器) |
| **测试目的** | 验证驱动正确拒绝写入只读测点 (ReadInputRegisters 类型) |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置为只读类型 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点为 ReadInputRegisters 类型 (只读)<br>3. 调用 write_point()<br>4. 验证返回 Err |
| **预期结果** | 返回 Err(DriverError::ReadOnlyPoint) |
| **测试数据** | 只读类型测点 |
| **优先级** | P0 |

---

### TC-306: write_point() 无效测点 ID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-306 |
| **测试名称** | write_point() 无效测点 ID |
| **测试目的** | 验证驱动正确处理未配置的测点 ID |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 调用 write_point(unknown_uuid, value)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(PointError::NotFound 或 DriverError::InvalidPoint) |
| **测试数据** | unknown_uuid: 不在配置中的 UUID |
| **优先级** | P0 |

---

### TC-307: write_point() 写入操作未连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-307 |
| **测试名称** | write_point() 写入操作未连接 |
| **测试目的** | 验证驱动在未连接状态下调用写入操作的行为 |
| **前置条件** | ModbusTcpDriver 已创建但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusTcpDriver<br>2. 调用 write_point(valid_uuid, value)<br>3. 验证返回 Err(DriverError::NotConnected) |
| **预期结果** | 返回 Err(DriverError::NotConnected) |
| **测试数据** | valid_uuid: 任意有效 UUID |
| **优先级** | P0 |

---

### TC-308: write_point() WriteSingleCoil 内部验证数量必须为 1

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-308 |
| **测试名称** | write_point() WriteSingleCoil 内部验证 |
| **测试目的** | 验证驱动内部使用 FC05 (WriteSingleCoil) 时数量必须为 1，不能批量写入 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 配置测点为 WriteSingleCoil 类型<br>2. 调用 write_point() 验证使用 FC05<br>3. 验证驱动不会尝试批量写入 (FC15) |
| **预期结果** | 驱动内部使用 FC05，发送 [0x05, addr_high, addr_low, 0xFF, 0x00] |
| **测试数据** | WriteSingleCoil 功能码: 0x05 |
| **优先级** | P1 |

---

### TC-309: write_point() WriteSingleRegister 内部验证数量必须为 1

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-309 |
| **测试名称** | write_point() WriteSingleRegister 内部验证 |
| **测试目的** | 验证驱动内部使用 FC06 (WriteSingleRegister) 时数量必须为 1，不能批量写入 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 配置测点为 WriteSingleRegister 类型<br>2. 调用 write_point() 验证使用 FC06<br>3. 验证驱动不会尝试批量写入 (FC16) |
| **预期结果** | 驱动内部使用 FC06，发送 [0x06, addr_high, addr_low, value_high, value_low] |
| **测试数据** | WriteSingleRegister 功能码: 0x06 |
| **优先级** | P1 |

---

## 5. 错误处理测试

### TC-401: 服务器返回 IllegalFunction (0x01) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-401 |
| **测试名称** | 服务器返回 IllegalFunction 异常 |
| **测试目的** | 验证驱动正确处理服务器返回的非法功能异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接，模拟服务器返回异常 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 发送请求后模拟服务器返回 0x81 (异常码 01)<br>3. 验证返回 Err(DriverError::IllegalFunction) |
| **预期结果** | 返回 Err 包含 IllegalFunction 描述 |
| **测试数据** | 异常响应: [0x81, 0x01] |
| **优先级** | P0 |

---

### TC-402: 服务器返回 IllegalDataAddress (0x02) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-402 |
| **测试名称** | 服务器返回 IllegalDataAddress 异常 |
| **测试目的** | 验证驱动正确处理非法数据地址异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接，模拟服务器返回异常 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 发送请求后模拟服务器返回 0x82 (异常码 02)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err 包含 IllegalDataAddress 描述 |
| **测试数据** | 异常响应: [0x82, 0x02] |
| **优先级** | P0 |

---

### TC-403: 服务器返回 IllegalDataValue (0x03) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-403 |
| **测试名称** | 服务器返回 IllegalDataValue 异常 |
| **测试目的** | 验证驱动正确处理非法数据值异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器返回 0x83 (异常码 03)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err 包含 IllegalDataValue 描述 |
| **测试数据** | 异常响应: [0x83, 0x03] |
| **优先级** | P0 |

---

### TC-404: 服务器返回 ServerDeviceFailure (0x04) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-404 |
| **测试名称** | 服务器返回 ServerDeviceFailure 异常 |
| **测试目的** | 验证驱动正确处理服务器设备故障异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器返回 0x84 (异常码 04)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err 包含 ServerDeviceFailure 描述 |
| **测试数据** | 异常响应: [0x84, 0x04] |
| **优先级** | P1 |

---

### TC-405: 服务器返回 Acknowledge (0x05) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-405 |
| **测试名称** | 服务器返回 Acknowledge 异常 |
| **测试目的** | 验证驱动正确处理确认异常 (服务器忙但已接受) |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器返回 0x85 (异常码 05)<br>3. 验证返回 Err 或根据实现等待 |
| **预期结果** | 返回 Err 包含 Acknowledge 描述 |
| **测试数据** | 异常响应: [0x85, 0x05] |
| **优先级** | P1 |

---

### TC-406: 服务器返回 ServerBusy (0x06) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-406 |
| **测试名称** | 服务器返回 ServerBusy 异常 |
| **测试目的** | 验证驱动正确处理服务器忙异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器返回 0x86 (异常码 06)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err 包含 ServerBusy 描述 |
| **测试数据** | 异常响应: [0x86, 0x06] |
| **优先级** | P1 |

---

### TC-407: 服务器返回 MemoryParityError (0x08) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-407 |
| **测试名称** | 服务器返回 MemoryParityError 异常 |
| **测试目的** | 验证驱动正确处理内存奇偶校验错误异常 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器返回 0x88 (异常码 08)<br>3. 验证返回 Err |
| **预期结果** | 返回 Err 包含 MemoryParityError 描述 |
| **测试数据** | 异常响应: [0x88, 0x08] |
| **优先级** | P1 |

---

### TC-408: 服务器无响应 (连接断开)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-408 |
| **测试名称** | 服务器无响应 |
| **测试目的** | 验证驱动正确处理服务器无响应的情况 |
| **前置条件** | ModbusTcpDriver 已实现并连接，模拟服务器关闭连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器关闭连接<br>3. 调用 read_point()<br>4. 验证返回 Err |
| **预期结果** | 返回 Err(DriverError::IoError 或 RemoteHostClosedConnection) |
| **测试数据** | 无响应场景 |
| **优先级** | P0 |

---

### TC-409: 接收数据不完整

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-409 |
| **测试名称** | 接收数据不完整 |
| **测试目的** | 验证驱动正确处理接收数据不完整的情况 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器返回部分数据后断开<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(DriverError::IoError) 或 IncompleteFrame 错误 |
| **测试数据** | 部分响应数据 |
| **优先级** | P1 |

---

### TC-410: 响应事务 ID 不匹配

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-410 |
| **测试名称** | 响应事务 ID 不匹配 |
| **测试目的** | 验证驱动正确处理响应事务 ID 与请求不匹配的情况 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 发送请求 (transaction_id=1)<br>3. 模拟服务器返回 transaction_id=2 的响应<br>4. 验证返回 Err |
| **预期结果** | 返回 Err (TransactionIdMismatch 或类似错误) |
| **测试数据** | 请求 TID=1, 响应 TID=2 |
| **优先级** | P0 |

---

## 6. MBAP/PDU 解析测试

### TC-501: MBAP 头部解析 - 有效帧

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-501 |
| **测试名称** | MBAP 头部解析 - 有效帧 |
| **测试目的** | 验证驱动能够正确解析有效的 MBAP 头部 |
| **前置条件** | ModbusTcpDriver 内部 MBAP 解析已实现 |
| **测试步骤** | 1. 创建有效 MBAP 帧: [0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01]<br>2. 调用 MBAP 解析方法<br>3. 验证解析结果 |
| **预期结果** | transaction_id=1, protocol_id=0, length=6, unit_id=1 |
| **测试数据** | [0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01] |
| **优先级** | P0 |

---

### TC-502: MBAP 头部解析 - 无效协议 ID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-502 |
| **测试名称** | MBAP 头部解析 - 无效协议 ID |
| **测试目的** | 验证驱动正确拒绝无效协议 ID 的帧 |
| **前置条件** | ModbusTcpDriver 内部 MBAP 解析已实现 |
| **测试步骤** | 1. 创建 MBAP 帧，protocol_id != 0: [0x00, 0x01, 0x00, 0x01, 0x00, 0x06, 0x01]<br>2. 调用 MBAP 解析方法<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(MbapError) - 协议 ID 必须是 0 |
| **测试数据** | [0x00, 0x01, 0x00, 0x01, 0x00, 0x06, 0x01] |
| **优先级** | P0 |

---

### TC-503: MBAP 头部解析 - 无效长度

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-503 |
| **测试名称** | MBAP 头部解析 - 无效长度 |
| **测试目的** | 验证驱动正确拒绝无效长度字段的帧 |
| **前置条件** | ModbusTcpDriver 内部 MBAP 解析已实现 |
| **测试步骤** | 1. 创建 MBAP 帧，length=0: [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01]<br>2. 调用 MBAP 解析方法<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(MbapError) - length 必须 >= 1 |
| **测试数据** | [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01] |
| **优先级** | P0 |

---

### TC-504: MBAP 头部解析 - 数据太短

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-504 |
| **测试名称** | MBAP 头部解析 - 数据太短 |
| **测试目的** | 验证驱动正确拒绝数据不足的帧 |
| **前置条件** | ModbusTcpDriver 内部 MBAP 解析已实现 |
| **测试步骤** | 1. 提供只有 5 字节的数据<br>2. 调用 MBAP 解析方法<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(IncompleteFrame) - 需要 7 字节 |
| **测试数据** | [0x00, 0x01, 0x00, 0x00, 0x00] |
| **优先级** | P0 |

---

### TC-505: PDU 组装 - ReadHoldingRegisters 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-505 |
| **测试名称** | PDU 组装 - ReadHoldingRegisters 请求 |
| **测试目的** | 验证驱动能够正确组装 ReadHoldingRegisters PDU |
| **前置条件** | ModbusTcpDriver 内部 PDU 组装已实现 |
| **测试步骤** | 1. 调用 PDU 组装方法 (如 build_read_holding_registers)<br>2. 验证生成的字节序列 |
| **预期结果** | 生成 [0x03, 0x00, 0x00, 0x00, 0x0A] (地址=0, 数量=10) |
| **测试数据** | 功能码: 0x03, 地址: 0, 数量: 10 |
| **优先级** | P0 |

---

### TC-506: 完整帧组装 (MBAP + PDU)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-506 |
| **测试名称** | 完整帧组装 |
| **测试目的** | 验证驱动能够正确组装完整的 Modbus TCP 帧 |
| **前置条件** | ModbusTcpDriver 内部帧组装已实现 |
| **测试步骤** | 1. 创建 MBAP 头部和 PDU<br>2. 调用帧组装方法<br>3. 验证返回完整帧 |
| **预期结果** | 返回包含 MBAP (7字节) + PDU 的完整字节序列 |
| **测试数据** | 标准 ReadHoldingRegisters 帧 |
| **优先级** | P0 |

---

## 7. 并发与超时测试

### TC-601: 连接超时

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-601 |
| **测试名称** | 连接超时 |
| **测试目的** | 验证驱动正确处理连接超时 |
| **前置条件** | ModbusTcpDriver 已实现，超时配置为 5 秒 |
| **测试步骤** | 1. 配置连接到不可达主机<br>2. 调用 connect() 方法<br>3. 验证在超时时间内返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) 且耗时接近配置的超时时间 |
| **测试数据** | host: "192.0.2.1", port: 1502, timeout: 5s |
| **优先级** | P0 |

---

### TC-602: 读取超时

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-602 |
| **测试名称** | 读取超时 |
| **测试目的** | 验证驱动正确处理读取操作超时 |
| **前置条件** | ModbusTcpDriver 已实现并连接，读取超时配置为 3 秒 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器延迟响应 > 3 秒<br>3. 调用 read_point()<br>4. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 延迟: 4 秒, 超时: 3 秒 |
| **优先级** | P0 |

---

### TC-603: 写入超时

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-603 |
| **测试名称** | 写入超时 |
| **测试目的** | 验证驱动正确处理写入操作超时 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 模拟服务器延迟响应 > 超时时间<br>3. 调用 write_point()<br>4. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 延迟: 4 秒, 超时: 3 秒 |
| **优先级** | P1 |

---

### TC-604: 连接重试机制与退避策略

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-604 |
| **测试名称** | 连接重试机制与退避策略 |
| **测试目的** | 验证驱动的自动重试机制及退避策略 (指数退避/固定间隔) |
| **前置条件** | ModbusTcpDriver 已实现重试机制 |
| **测试步骤** | 1. 首次连接失败 (模拟服务器未启动)<br>2. 验证驱动按配置的重试次数和退避策略进行重试<br>   - 记录每次重试的时间戳<br>   - 验证重试间隔符合配置的退避策略 (如: 1s, 2s, 4s 指数退避 或 固定 1s 间隔)<br>3. 如果重试成功，验证最终连接成功 |
| **预期结果** | 根据配置进行重试:<br>- 重试次数: 配置值 (如 3 次)<br>- 重试间隔: 符合退避策略 (指数退避或固定间隔)<br>- 最终成功或返回最终错误 |
| **测试数据** | 首次失败，第二次成功后连接成功<br>退避策略配置示例: initial_delay=1s, max_delay=10s, multiplier=2.0 |
| **优先级** | P1 |

---

### TC-605: 并发读取请求的事务 ID 正确性

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-605 |
| **测试名称** | 并发读取请求的事务 ID 正确性 |
| **测试目的** | 验证驱动在处理并发读取请求时，每个请求的事务 ID 唯一且响应能正确匹配 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 同时发起 10 个 read_point() 调用<br>3. 验证:<br>   - 每个请求的事务 ID 不同 (递增唯一)<br>   - 驱动能正确将响应与原始请求匹配<br>   - 所有请求都成功完成或正确报告错误 |
| **预期结果** | - 事务 ID 唯一递增 (无重复)<br>- 每个响应能正确匹配到对应的请求<br>- 所有请求返回 Ok 或错误 (无请求混淆) |
| **测试数据** | 10 个并发 read_point() 请求 |
| **优先级** | P1 |

---

## 8. DriverAccess trait 测试

### TC-701: DriverAccess read_point 成功

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-701 |
| **测试名称** | DriverAccess read_point 成功 |
| **测试目的** | 验证 DriverAccess trait 的 read_point 方法正确实现 |
| **前置条件** | ModbusTcpDriver 实现 DriverAccess trait，测点已配置 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射 (point_id -> address, function_code)<br>3. 调用 read_point(point_id)<br>4. 验证返回 Ok(PointValue) |
| **预期结果** | 返回 Ok(PointValue::Number/Bool 或对应类型) |
| **测试数据** | 测点 UUID 和对应的 Modbus 地址 |
| **优先级** | P0 |

---

### TC-702: DriverAccess write_point 成功

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-702 |
| **测试名称** | DriverAccess write_point 成功 |
| **测试目的** | 验证 DriverAccess trait 的 write_point 方法正确实现 |
| **前置条件** | ModbusTcpDriver 实现 DriverAccess trait，测点已配置 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置测点映射<br>3. 调用 write_point(point_id, value)<br>4. 验证返回 Ok(()) |
| **预期结果** | 返回 Ok(()) |
| **测试数据** | 测点 UUID 和 ModbusValue |
| **优先级** | P0 |

---

### TC-703: DriverAccess read_point 未连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-703 |
| **测试名称** | DriverAccess read_point 未连接 |
| **测试目的** | 验证 read_point 在未连接时返回合适错误 |
| **前置条件** | ModbusTcpDriver 已实现但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusTcpDriver<br>2. 调用 read_point(point_id)<br>3. 验证返回 Err(DriverError::NotConnected) |
| **预期结果** | 返回 Err(DriverError::NotConnected) |
| **测试数据** | 任意测点 UUID |
| **优先级** | P0 |

---

### TC-704: DriverAccess write_point 未连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-704 |
| **测试名称** | DriverAccess write_point 未连接 |
| **测试目的** | 验证 write_point 在未连接时返回合适错误 |
| **前置条件** | ModbusTcpDriver 已实现但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusTcpDriver<br>2. 调用 write_point(point_id, value)<br>3. 验证返回 Err(DriverError::NotConnected) |
| **预期结果** | 返回 Err(DriverError::NotConnected) |
| **测试数据** | 任意测点 UUID 和值 |
| **优先级** | P0 |

---

### TC-705: DriverAccess read_point 无效测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-705 |
| **测试名称** | DriverAccess read_point 无效测点 |
| **测试目的** | 验证读取未配置的测点时返回合适错误 |
| **前置条件** | ModbusTcpDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 使用未配置的 point_id 调用 read_point()<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(DriverError::InvalidValue 或 PointError::NotFound) |
| **测试数据** | 任意未配置的 UUID |
| **优先级** | P1 |

---

### TC-706: DriverAccess write_point 只读测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-706 |
| **测试名称** | DriverAccess write_point 只读测点 |
| **测试目的** | 验证写入只读测点时返回合适错误 |
| **前置条件** | ModbusTcpDriver 已实现并连接，测点配置为只读 |
| **测试步骤** | 1. 创建并连接 ModbusTcpDriver<br>2. 配置只读测点 (如 DiscreteInput 或 InputRegister)<br>3. 调用 write_point()<br>4. 验证返回 Err(DriverError::ReadOnlyPoint) |
| **预期结果** | 返回 Err(DriverError::ReadOnlyPoint) |
| **测试数据** | 只读类型测点 |
| **优先级** | P0 |

---

### TC-707: DriverAccess 测点映射验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-707 |
| **测试名称** | DriverAccess 测点映射验证 |
| **测试目的** | 验证驱动正确将 point_id 映射到正确的 Modbus 地址和功能码 |
| **前置条件** | ModbusTcpDriver 已实现并连接，多个测点已配置 |
| **测试步骤** | 1. 配置多个测点映射到不同 Modbus 地址<br>2. 依次读取每个测点<br>3. 验证驱动发送正确的功能码和地址 |
| **预期结果** | - Coil 测点使用 FC01<br>- DiscreteInput 测点使用 FC02<br>- HoldingRegister 测点使用 FC03<br>- InputRegister 测点使用 FC04<br>- WriteSingleCoil 使用 FC05<br>- WriteSingleRegister 使用 FC06 |
| **测试数据** | 多种类型测点配置 |
| **优先级** | P0 |

---

## 9. 测试数据需求

### 9.1 Modbus 地址测试数据

| 地址 | 说明 |
|------|------|
| 0x0000 | 最小地址 |
| 0x0001 | 边界地址 |
| 0x7FFF | 中间地址 |
| 0x8000 | 中间地址 |
| 0xFFFF | 最大地址 |

### 9.2 Modbus 数量限制

| 操作类型 | 最小值 | 最大值 | 说明 |
|---------|--------|--------|------|
| ReadCoils | 1 | 2000 | 位操作 |
| ReadDiscreteInputs | 1 | 2000 | 位操作 (新增边界验证) |
| ReadHoldingRegisters | 1 | 125 | 字操作 |
| ReadInputRegisters | 1 | 125 | 字操作 (新增边界验证) |
| WriteSingleCoil | 1 | 1 | 固定为 1 (新增验证) |
| WriteSingleRegister | 1 | 1 | 固定为 1 (新增验证) |
| WriteMultipleCoils | 1 | 1968 | 位操作 |
| WriteMultipleRegisters | 1 | 123 | 字操作 |

### 9.3 异常码测试数据

| 异常码 | 名称 | 说明 |
|--------|------|------|
| 0x01 | IllegalFunction | 非法功能码 |
| 0x02 | IllegalDataAddress | 非法数据地址 |
| 0x03 | IllegalDataValue | 非法数据值 |
| 0x04 | ServerDeviceFailure | 从站设备故障 |
| 0x05 | Acknowledge | 确认 |
| 0x06 | ServerBusy | 服务器忙 |
| 0x08 | MemoryParityError | 内存奇偶校验错误 |

### 9.4 超时与重试测试数据

| 配置项 | 值 |
|--------|-----|
| 连接超时 | 5 秒 |
| 读取超时 | 3 秒 |
| 写入超时 | 3 秒 |
| 重试次数 | 3 次 |
| 重试退避策略 | 指数退避 (1s, 2s, 4s) 或固定间隔 |

---

## 10. 测试环境

### 10.1 开发环境

| 项目 | 要求 |
|------|------|
| Rust 版本 | >= 1.75 |
| 测试框架 | 内置 test + tokio::test + mockall |
| 依赖 | tokio (async runtime), tokio-modbus 或自实现 |
| 模拟工具 | 自定义 mock TcpStream 或模拟 Modbus 服务器 |

### 10.2 测试命令

```bash
# 运行所有 Modbus TCP 驱动测试
cargo test --package kayak-backend --lib modbus::tcp

# 运行特定测试类别
cargo test --package kayak-backend --lib modbus::tcp::connection
cargo test --package kayak-backend --lib modbus::tcp::read
cargo test --package kayak-backend --lib modbus::tcp::write

# 运行带日志的测试
RUST_LOG=debug cargo test --package kayak-backend --lib modbus::tcp

# 运行集成测试 (需要模拟服务器)
cargo test --package kayak-backend --lib modbus::tcp -- --ignored

# 生成测试覆盖率报告
cargo tarpaulin --out Html --package kayak-backend
```

### 10.3 依赖假设

| 依赖 | 说明 |
|------|------|
| tokio | 异步运行时 |
| tokio::net::TcpStream | TCP 连接 |
| tokio::io::{AsyncReadExt, AsyncWriteExt} | 异步读写 |
| async-trait | async trait 支持 |
| uuid | 测点 UUID |

---

## 11. 风险与假设

### 11.1 测试假设

| 假设ID | 描述 |
|--------|------|
| ASM-101 | ModbusTcpDriver 将在 `drivers/modbus/tcp.rs` 中实现 |
| ASM-102 | 驱动程序将使用 tokio 作为异步运行时 |
| ASM-103 | 驱动程序将实现 DriverAccess 和 DriverLifecycle traits |
| ASM-104 | 内部将使用 MbapHeader 和 Pdu 进行协议封装 |
| ASM-105 | 连接配置将通过 ModbusTcpConfig 结构体传入 |
| ASM-106 | 测点配置通过 point_id -> (address, function_code, value_type) 映射表管理 |

### 11.2 测试风险

| 风险ID | 风险描述 | 缓解措施 |
|--------|---------|---------|
| RSK-101 | 网络环境不稳定导致测试随机失败 | 使用 mock TCP 流进行单元测试 |
| RSK-102 | 模拟服务器实现与真实服务器行为差异 | 集成测试使用真实 TCP 服务器 |
| RSK-103 | 超时测试耗时过长 | 使用较短的超时时间或 mock 时间 |
| RSK-104 | 并发测试竞争条件 | 使用同步机制确保测试可重复 |

### 11.3 测试阻塞项

| 阻塞项 | 依赖 | 状态 |
|--------|------|------|
| ModbusTcpDriver 实现 | R1-S1-003-B (开发) | 待开发 |
| 模拟 Modbus TCP 服务器 | R1-S1-004 (模拟设备) | 待开发 |
| DriverAccess trait 定义 | R1-S1-001 (已完成) | 已完成 |

---

## 12. 测试用例汇总

| 测试ID | 测试名称 | 优先级 | 类型 | 状态 |
|--------|---------|--------|------|------|
| TC-101 | ModbusTcpDriver 连接成功 | P0 | 集成测试 | 待执行 |
| TC-102 | ModbusTcpDriver 连接无效地址 | P0 | 集成测试 | 待执行 |
| TC-103 | ModbusTcpDriver 连接拒绝 | P0 | 集成测试 | 待执行 |
| TC-104 | ModbusTcpDriver 重复连接 | P1 | 集成测试 | 待执行 |
| TC-105 | ModbusTcpDriver 断开连接 | P0 | 集成测试 | 待执行 |
| TC-106 | ModbusTcpDriver 未连接时断开 | P1 | 单元测试 | 待执行 |
| TC-201 | read_point() 成功读取线圈测点 (FC01) | P0 | 集成测试 | 待执行 |
| TC-202 | read_point() 成功读取离散输入测点 (FC02) | P0 | 集成测试 | 待执行 |
| TC-203 | read_point() 成功读取保持寄存器测点 (FC03) | P0 | 集成测试 | 待执行 |
| TC-204 | read_point() 成功读取输入寄存器测点 (FC04) | P0 | 集成测试 | 待执行 |
| TC-205 | read_point() 无效测点 ID | P0 | 集成测试 | 待执行 |
| TC-206 | read_point() 读取时 Modbus 地址无效 | P1 | 集成测试 | 待执行 |
| TC-207 | read_point() 离散输入数量超限 (新增) | P0 | 单元测试 | 待执行 |
| TC-208 | read_point() 输入寄存器数量超限 (新增) | P0 | 单元测试 | 待执行 |
| TC-209 | read_point() 读取操作未连接 | P0 | 单元测试 | 待执行 |
| TC-301 | write_point() 成功写入线圈测点 ON (FC05) | P0 | 集成测试 | 待执行 |
| TC-302 | write_point() 成功写入线圈测点 OFF (FC05) | P0 | 集成测试 | 待执行 |
| TC-303 | write_point() 成功写入保持寄存器测点 (FC06) | P0 | 集成测试 | 待执行 |
| TC-304 | write_point() 写入只读测点 (离散输入) | P0 | 集成测试 | 待执行 |
| TC-305 | write_point() 写入只读测点 (输入寄存器) | P0 | 集成测试 | 待执行 |
| TC-306 | write_point() 无效测点 ID | P0 | 集成测试 | 待执行 |
| TC-307 | write_point() 写入操作未连接 | P0 | 单元测试 | 待执行 |
| TC-308 | write_point() WriteSingleCoil 内部验证 (新增) | P1 | 单元测试 | 待执行 |
| TC-309 | write_point() WriteSingleRegister 内部验证 (新增) | P1 | 单元测试 | 待执行 |
| TC-401 | 服务器返回 IllegalFunction (0x01) 异常 | P0 | 集成测试 | 待执行 |
| TC-402 | 服务器返回 IllegalDataAddress (0x02) 异常 | P0 | 集成测试 | 待执行 |
| TC-403 | 服务器返回 IllegalDataValue (0x03) 异常 | P0 | 集成测试 | 待执行 |
| TC-404 | 服务器返回 ServerDeviceFailure (0x04) 异常 | P1 | 集成测试 | 待执行 |
| TC-405 | 服务器返回 Acknowledge (0x05) 异常 | P1 | 集成测试 | 待执行 |
| TC-406 | 服务器返回 ServerBusy (0x06) 异常 | P1 | 集成测试 | 待执行 |
| TC-407 | 服务器返回 MemoryParityError (0x08) 异常 | P1 | 集成测试 | 待执行 |
| TC-408 | 服务器无响应 (连接断开) | P0 | 集成测试 | 待执行 |
| TC-409 | 接收数据不完整 | P1 | 集成测试 | 待执行 |
| TC-410 | 响应事务 ID 不匹配 | P0 | 集成测试 | 待执行 |
| TC-501 | MBAP 头部解析 - 有效帧 | P0 | 单元测试 | 待执行 |
| TC-502 | MBAP 头部解析 - 无效协议 ID | P0 | 单元测试 | 待执行 |
| TC-503 | MBAP 头部解析 - 无效长度 | P0 | 单元测试 | 待执行 |
| TC-504 | MBAP 头部解析 - 数据太短 | P0 | 单元测试 | 待执行 |
| TC-505 | PDU 组装 - ReadHoldingRegisters 请求 | P0 | 单元测试 | 待执行 |
| TC-506 | 完整帧组装 (MBAP + PDU) | P0 | 单元测试 | 待执行 |
| TC-601 | 连接超时 | P0 | 集成测试 | 待执行 |
| TC-602 | 读取超时 | P0 | 集成测试 | 待执行 |
| TC-603 | 写入超时 | P1 | 集成测试 | 待执行 |
| TC-604 | 连接重试机制与退避策略 (更新) | P1 | 集成测试 | 待执行 |
| TC-605 | 并发读取请求的事务 ID 正确性 (更新) | P1 | 集成测试 | 待执行 |
| TC-701 | DriverAccess read_point 成功 | P0 | 单元测试 | 待执行 |
| TC-702 | DriverAccess write_point 成功 | P0 | 单元测试 | 待执行 |
| TC-703 | DriverAccess read_point 未连接 | P0 | 单元测试 | 待执行 |
| TC-704 | DriverAccess write_point 未连接 | P0 | 单元测试 | 待执行 |
| TC-705 | DriverAccess read_point 无效测点 | P1 | 单元测试 | 待执行 |
| TC-706 | DriverAccess write_point 只读测点 | P0 | 单元测试 | 待执行 |
| TC-707 | DriverAccess 测点映射验证 (新增) | P0 | 单元测试 | 待执行 |

---

## 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2026-05-02 | sw-mike | 初始版本，包含 60 个测试用例 |
| 1.1 | 2026-05-02 | sw-mike | 修复 issues:<br>- API 命名改为 read_point/write_point<br>- 新增边界测试 (TC-207, TC-208, TC-308, TC-309)<br>- 更新 TC-604 重试机制描述<br>- 更新 TC-605 并发事务 ID 验证<br>- 新增 TC-707 测点映射验证<br>- 文档说明驱动与模拟设备分离 |

---

*本文档由 Kayak 项目测试团队维护。如有问题，请联系测试工程师。*