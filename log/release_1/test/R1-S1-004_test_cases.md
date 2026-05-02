# R1-S1-004 测试用例文档 - Modbus RTU 驱动

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S1-004 |
| 测试类型 | 单元测试 + 集成测试 |
| 测试范围 | Modbus RTU 驱动实现 (drivers/modbus/rtu.rs) |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-02 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [配置与连接测试](#2-配置与连接测试)
3. [帧格式与 CRC 测试](#3-帧格式与-crc-测试)
4. [读取操作测试](#4-读取操作测试)
5. [写入操作测试](#5-写入操作测试)
6. [错误处理测试](#6-错误处理测试)
7. [超时与重试测试](#7-超时与重试测试)
8. [测点映射测试](#8-测点映射测试)
9. [测试数据需求](#9-测试数据需求)
10. [测试环境](#10-测试环境)
11. [风险与假设](#11-风险与假设)
12. [测试用例汇总](#12-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证 Modbus RTU 驱动的正确性，确保：
- 驱动程序正确实现 `DriverLifecycle` 和 `DeviceDriver` traits
- 连接/断开串口操作正确工作
- RTU 帧格式正确 (slave_id + PDU + CRC16)
- CRC16 计算和验证正确
- 读取/写入操作与 TCP 驱动行为一致
- 超时和错误处理正确实现

### 1.2 RTU vs TCP 关键差异

| 特性 | Modbus TCP | Modbus RTU |
|------|------------|------------|
| 传输层 | TCP/IP | 串口 (RS-485/RS-232) |
| 帧头 | MBAP (7字节) | 无 (仅 slave_id) |
| 帧尾 | 无 | CRC16 (2字节) |
| 事务ID | 有 (2字节) | 无 (单主模式) |
| 从站地址 | Unit ID (MBAP中) | Slave ID (首字节) |
| 连接方式 | Socket连接 | 串口打开/关闭 |

### 1.3 RTU 帧格式

```
RTU 请求帧:
[Slave ID] [Function Code] [Data...N] [CRC16 Low] [CRC16 High]
   1 byte        1 byte        N bytes         1 byte          1 byte

RTU 响应帧:
[Slave ID] [Function Code] [Data...N] [CRC16 Low] [CRC16 High]
   1 byte        1 byte        N bytes         1 byte          1 byte

注意: CRC16 低字节在前，高字节在后
```

### 1.4 测试范围

| 模块 | 测试内容 |
|------|---------|
| 配置管理 | 串口参数配置 (波特率, 校验位, 停止位, 数据位) |
| 连接管理 | 串口打开/关闭, 无效端口处理 |
| 帧格式 | RTU 帧组装修复, CRC16 计算与验证 |
| 读取操作 | FC01/FC02/FC03/FC04 单点读取 |
| 写入操作 | FC05/FC06 单点写入 |
| 错误处理 | CRC 错误, 超时, 无效从站 ID |
| DriverAccess | read_point/write_point 与测点映射 |

---

## 2. 配置与连接测试

### TC-RTU-001: ModbusRtuConfig 默认配置

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-001 |
| **测试名称** | ModbusRtuConfig 默认配置 |
| **测试目的** | 验证 RTU 配置结构体的默认值正确 |
| **前置条件** | ModbusRtuConfig 已实现 |
| **测试步骤** | 1. 创建默认配置 `ModbusRtuConfig::default()`<br>2. 验证各字段默认值 |
| **预期结果** | port="/dev/ttyUSB0", baud=9600, parity='N', data_bits=8, stop_bits=1, slave_id=1, timeout_ms=3000 |
| **测试数据** | 默认配置 |
| **优先级** | P0 |

---

### TC-RTU-002: ModbusRtuConfig 自定义配置

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-002 |
| **测试名称** | ModbusRtuConfig 自定义配置 |
| **测试目的** | 验证可以创建自定义配置的 RTU 驱动 |
| **前置条件** | ModbusRtuConfig 已实现 |
| **测试步骤** | 1. 创建配置: port="/dev/ttyUSB1", baud=19200, parity='E', data_bits=8, stop_bits=1, slave_id=2<br>2. 创建驱动实例<br>3. 验证配置值 |
| **预期结果** | 配置值与创建时一致 |
| **测试数据** | 波特率: 19200, 校验: 偶校验, 从站ID: 2 |
| **优先级** | P0 |

---

### TC-RTU-003: ModbusRtuDriver 打开有效串口

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-003 |
| **测试名称** | ModbusRtuDriver 打开有效串口 |
| **测试目的** | 验证驱动能够成功打开有效的串口设备 |
| **前置条件** | ModbusRtuDriver 已实现, 存在可用串口设备 (或模拟串口) |
| **测试步骤** | 1. 创建 ModbusRtuDriver，配置有效串口<br>2. 调用 connect() 方法<br>3. 验证返回 Ok(())<br>4. 调用 is_connected() 验证返回 true |
| **预期结果** | 1. connect() 返回 Ok(())<br>2. is_connected() 返回 true |
| **测试数据** | port: "/dev/ttyUSB0" (或模拟串口) |
| **优先级** | P0 |

---

### TC-RTU-004: ModbusRtuDriver 打开无效串口

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-004 |
| **测试名称** | ModbusRtuDriver 打开无效串口 |
| **测试目的** | 验证驱动正确处理无效串口设备 |
| **前置条件** | ModbusRtuDriver 已实现 |
| **测试步骤** | 1. 创建 ModbusRtuDriver，配置无效串口路径<br>2. 调用 connect() 方法<br>3. 验证返回 Err |
| **预期结果** | connect() 返回 Err(DriverError::IoError 或类似错误) |
| **测试数据** | port: "/dev/ttyNONEXISTENT" |
| **优先级** | P0 |

---

### TC-RTU-005: ModbusRtuDriver 重复连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-005 |
| **测试名称** | ModbusRtuDriver 重复连接 |
| **测试目的** | 验证驱动在已连接状态下再次调用 connect() 的行为 |
| **前置条件** | ModbusRtuDriver 已实现并已连接 |
| **测试步骤** | 1. 创建并连接 ModbusRtuDriver<br>2. 再次调用 connect() 方法<br>3. 验证返回 Err(DriverError::AlreadyConnected) 或 Ok(()) |
| **预期结果** | 返回 Err(DriverError::AlreadyConnected) 或允许静默成功 |
| **测试数据** | 有效串口设备 |
| **优先级** | P1 |

---

### TC-RTU-006: ModbusRtuDriver 断开连接

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-006 |
| **测试名称** | ModbusRtuDriver 断开连接 |
| **测试目的** | 验证驱动能够正确断开串口连接 |
| **前置条件** | ModbusRtuDriver 已实现并已连接 |
| **测试步骤** | 1. 创建并连接 ModbusRtuDriver<br>2. 调用 disconnect() 方法<br>3. 验证返回 Ok(())<br>4. 验证 is_connected() 返回 false |
| **预期结果** | 1. disconnect() 返回 Ok(())<br>2. is_connected() 返回 false |
| **测试数据** | 有效串口设备 |
| **优先级** | P0 |

---

### TC-RTU-007: 串口参数验证 - 波特率

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-007 |
| **测试名称** | 串口参数验证 - 波特率 |
| **测试目的** | 验证驱动接受有效的标准波特率 |
| **前置条件** | ModbusRtuConfig 已实现 |
| **测试步骤** | 1. 测试标准波特率: 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200<br>2. 创建配置和驱动<br>3. 验证配置正确保存 |
| **预期结果** | 所有标准波特率都被接受并正确保存 |
| **测试数据** | 波特率列表: [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200] |
| **优先级** | P1 |

---

### TC-RTU-008: 串口参数验证 - 校验位

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-008 |
| **测试名称** | 串口参数验证 - 校验位 |
| **测试目的** | 验证驱动接受有效的校验位配置 |
| **前置条件** | ModbusRtuConfig 已实现 |
| **测试步骤** | 1. 测试校验位: None(N), Odd(O), Even(E)<br>2. 创建配置<br>3. 验证配置正确保存 |
| **预期结果** | 所有校验位配置都被接受 |
| **测试数据** | 校验位: 'N' (无), 'O' (奇), 'E' (偶) |
| **优先级** | P1 |

---

## 3. 帧格式与 CRC 测试

### TC-RTU-101: RTU 帧组装 - 基本结构

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-101 |
| **测试名称** | RTU 帧组装 - 基本结构 |
| **测试目的** | 验证 RTU 帧的基本结构 [slave_id, pdu..., crc16] |
| **前置条件** | ModbusRtuDriver 或帧组装方法已实现 |
| **测试步骤** | 1. 构造 PDU: ReadHoldingRegisters (0x03), 地址=0, 数量=1<br>2. 使用 slave_id=1 组装 RTU 帧<br>3. 验证帧结构 |
| **预期结果** | 帧格式: [0x01, 0x03, 0x00, 0x00, 0x00, 0x01, 0x**CRC**, 0x**CRC**]<br>长度: 8 字节 |
| **测试数据** | 功能码: 0x03, 地址: 0x0000, 数量: 1, 从站ID: 1 |
| **优先级** | P0 |

---

### TC-RTU-102: CRC16 计算验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-102 |
| **测试名称** | CRC16 计算验证 |
| **测试目的** | 验证 CRC16 计算正确性 |
| **前置条件** | CRC16 计算逻辑已实现 |
| **测试步骤** | 1. 构造已知数据: [0x01, 0x03, 0x00, 0x00, 0x00, 0x01]<br>2. 计算 CRC16<br>3. 验证结果 |
| **预期结果** | CRC16 = 0x840A (对于上述数据，低字节在前) |
| **测试数据** | 数据: [0x01, 0x03, 0x00, 0x00, 0x00, 0x01]<br>预期CRC: 0x840A (小端序) |
| **优先级** | P0 |

---

### TC-RTU-103: CRC16 验证 - 正确帧

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-103 |
| **测试名称** | CRC16 验证 - 正确帧 |
| **测试目的** | 验证驱动正确接受 CRC 正确的帧 |
| **前置条件** | CRC 验证逻辑已实现 |
| **测试步骤** | 1. 构造正确 CRC 的 RTU 响应帧<br>2. 调用帧验证方法<br>3. 验证返回 Ok(()) |
| **预期结果** | 帧验证通过 |
| **测试数据** | 完整RTU帧带正确CRC |
| **优先级** | P0 |

---

### TC-RTU-104: CRC16 验证 - 错误帧

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-104 |
| **测试名称** | CRC16 验证 - 错误帧 |
| **测试目的** | 验证驱动正确拒绝 CRC 错误的帧 |
| **前置条件** | CRC 验证逻辑已实现 |
| **测试步骤** | 1. 构造带错误 CRC 的 RTU 帧<br>2. 调用帧验证方法<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(ModbusError::FrameChecksumMismatch 或类似错误) |
| **测试数据** | 正确帧的CRC被篡改 |
| **优先级** | P0 |

---

### TC-RTU-105: CRC16 验证 - 帧截断

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-105 |
| **测试名称** | CRC16 验证 - 帧截断 |
| **测试目的** | 验证驱动正确处理被截断的帧 (缺少CRC字节) |
| **前置条件** | 帧解析逻辑已实现 |
| **测试步骤** | 1. 提供不完整的RTU帧 (缺少1个或2个CRC字节)<br>2. 调用帧解析方法<br>3. 验证返回 Err |
| **预期结果** | 返回 Err(ModbusError::IncompleteFrame 或类似错误) |
| **测试数据** | 帧缺少最后1-2字节 |
| **优先级** | P0 |

---

### TC-RTU-106: RTU 响应帧解析 - 成功

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-106 |
| **测试名称** | RTU 响应帧解析 - 成功 |
| **测试目的** | 验证驱动能正确解析有效的 RTU 响应帧 |
| **前置条件** | RTU 帧解析已实现 |
| **测试步骤** | 1. 构造有效 RTU 响应帧 (ReadHoldingRegisters, 值=0x1234)<br>2. 解析帧<br>3. 验证 slave_id, function_code, data, CRC |
| **预期结果** | 正确解析出 slave_id, function_code, data |
| **测试数据** | 响应: [0x01, 0x03, 0x02, 0x12, 0x34, 0xCRCL, 0xCRCH] |
| **优先级** | P0 |

---

### TC-RTU-107: RTU 响应帧解析 - 异常响应

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-107 |
| **测试名称** | RTU 响应帧解析 - 异常响应 |
| **测试目的** | 验证驱动能正确解析 RTU 异常响应 |
| **前置条件** | RTU 帧解析已实现 |
| **测试步骤** | 1. 构造 RTU 异常响应 (function_code | 0x80, exception_code)<br>2. 解析帧<br>3. 验证异常码 |
| **预期结果** | 识别为异常响应并返回正确异常码 |
| **测试数据** | 异常响应: [0x01, 0x83, 0x02, 0xCRCL, 0xCRCH] (IllegalDataAddress) |
| **优先级** | P0 |

---

### TC-RTU-108: RTU 帧字节序 - CRC 低字节在前

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-108 |
| **测试名称** | RTU 帧字节序 - CRC 低字节在前 |
| **测试目的** | 验证 RTU 帧中 CRC 的字节序 (低字节在前, 高字节在后) |
| **前置条件** | CRC 处理已实现 |
| **测试步骤** | 1. 构造测试数据<br>2. 计算 CRC16<br>3. 验证帧中 CRC 排列: [crc_low, crc_high] |
| **预期结果** | CRC 低字节在前，高字节在后 |
| **测试数据** | 标准 Modbus RTU 帧格式 |
| **优先级** | P0 |

---

## 4. 读取操作测试

### TC-RTU-201: read_point() 成功读取线圈 (FC01)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-201 |
| **测试名称** | read_point() 成功读取线圈 (FC01) |
| **测试目的** | 验证通过 point_id 正确读取线圈状态 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置已加载, 模拟从站响应 |
| **测试步骤** | 1. 创建并连接 ModbusRtuDriver<br>2. 配置测点: point_uuid -> ModbusAddress(0), FunctionCode::ReadCoils<br>3. 调用 read_point(point_uuid)<br>4. 验证返回 Ok(PointValue::Bool) |
| **预期结果** | 返回 Ok(PointValue::Bool) 包含正确的布尔值 |
| **测试数据** | 地址: 0x0000, 预期值: true 或 false |
| **优先级** | P0 |

---

### TC-RTU-202: read_point() 成功读取离散输入 (FC02)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-202 |
| **测试名称** | read_point() 成功读取离散输入 (FC02) |
| **测试目的** | 验证通过 point_id 正确读取离散输入状态 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置已加载 |
| **测试步骤** | 1. 配置测点: point_uuid -> ModbusAddress(0), FunctionCode::ReadDiscreteInputs<br>2. 调用 read_point(point_uuid)<br>3. 验证返回 Ok(PointValue::Bool) |
| **预期结果** | 返回 Ok(PointValue::Bool) |
| **测试数据** | 地址: 0x0000 |
| **优先级** | P0 |

---

### TC-RTU-203: read_point() 成功读取保持寄存器 (FC03)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-203 |
| **测试名称** | read_point() 成功读取保持寄存器 (FC03) |
| **测试目的** | 验证通过 point_id 正确读取保持寄存器 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置已加载 |
| **测试步骤** | 1. 配置测点: point_uuid -> ModbusAddress(0), FunctionCode::ReadHoldingRegisters<br>2. 调用 read_point(point_uuid)<br>3. 验证返回 Ok(PointValue::Integer) |
| **预期结果** | 返回 Ok(PointValue::Integer) 包含 u16 值 |
| **测试数据** | 地址: 0x0000, 预期值: 0x1234 |
| **优先级** | P0 |

---

### TC-RTU-204: read_point() 成功读取输入寄存器 (FC04)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-204 |
| **测试名称** | read_point() 成功读取输入寄存器 (FC04) |
| **测试目的** | 验证通过 point_id 正确读取输入寄存器 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置已加载 |
| **测试步骤** | 1. 配置测点: point_uuid -> ModbusAddress(0), FunctionCode::ReadInputRegisters<br>2. 调用 read_point(point_uuid)<br>3. 验证返回 Ok(PointValue::Integer) |
| **预期结果** | 返回 Ok(PointValue::Integer) |
| **测试数据** | 地址: 0x0000 |
| **优先级** | P0 |

---

### TC-RTU-205: read_point() 无效测点 ID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-205 |
| **测试名称** | read_point() 无效测点 ID |
| **测试目的** | 验证驱动正确处理未配置的测点 ID |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 调用 read_point(unknown_uuid)<br>2. 验证返回 Err |
| **预期结果** | 返回 Err(DriverError::InvalidValue 或类似错误) |
| **测试数据** | 未配置的 UUID |
| **优先级** | P0 |

---

### TC-RTU-206: read_point() 未连接状态

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-206 |
| **测试名称** | read_point() 未连接状态 |
| **测试目的** | 验证在未连接状态下读取返回合适错误 |
| **前置条件** | ModbusRtuDriver 已创建但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusRtuDriver<br>2. 调用 read_point(valid_uuid)<br>3. 验证返回 Err(DriverError::NotConnected) |
| **预期结果** | 返回 Err(DriverError::NotConnected) |
| **测试数据** | 任意有效测点 UUID |
| **优先级** | P0 |

---

### TC-RTU-207: read_point() 从站无响应 (超时)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-207 |
| **测试名称** | read_point() 从站无响应 (超时) |
| **测试目的** | 验证从站无响应时正确处理超时 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 从站未连接或无响应 |
| **测试步骤** | 1. 创建并连接 ModbusRtuDriver<br>2. 模拟从站无响应场景<br>3. 调用 read_point()<br>4. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 超时配置: 3秒 |
| **优先级** | P0 |

---

### TC-RTU-208: read_point() 多寄存器连续读取

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-208 |
| **测试名称** | read_point() 多寄存器连续读取 |
| **测试目的** | 验证 RTU 驱动能正确处理多寄存器读取 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置测点指向多寄存器地址<br>2. 调用 read_point()<br>3. 验证返回正确数值 |
| **预期结果** | 正确解析多字节响应 |
| **测试数据** | ReadHoldingRegisters 数量 > 1 |
| **优先级** | P1 |

---

## 5. 写入操作测试

### TC-RTU-301: write_point() 成功写入线圈 ON (FC05)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-301 |
| **测试名称** | write_point() 成功写入线圈 ON (FC05) |
| **测试目的** | 验证通过 point_id 正确写入单个线圈为 ON (0xFF00) |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置已加载 |
| **测试步骤** | 1. 配置测点: point_uuid -> ModbusAddress(0), FunctionCode::WriteSingleCoil<br>2. 调用 write_point(point_uuid, PointValue::Boolean(true))<br>3. 验证返回 Ok(()) |
| **预期结果** | write_point() 返回 Ok(()) |
| **测试数据** | 地址: 0x0000, 值: true (ON = 0xFF00) |
| **优先级** | P0 |

---

### TC-RTU-302: write_point() 成功写入线圈 OFF (FC05)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-302 |
| **测试名称** | write_point() 成功写入线圈 OFF (FC05) |
| **测试目的** | 验证通过 point_id 正确写入单个线圈为 OFF (0x0000) |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 调用 write_point(point_uuid, PointValue::Boolean(false))<br>2. 验证返回 Ok(()) |
| **预期结果** | write_point() 返回 Ok(()) |
| **测试数据** | 地址: 0x0000, 值: false (OFF = 0x0000) |
| **优先级** | P0 |

---

### TC-RTU-303: write_point() 成功写入保持寄存器 (FC06)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-303 |
| **测试名称** | write_point() 成功写入保持寄存器 (FC06) |
| **测试目的** | 验证通过 point_id 正确写入单个寄存器 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置测点: point_uuid -> ModbusAddress(0), FunctionCode::WriteSingleRegister<br>2. 调用 write_point(point_uuid, PointValue::Integer(0x1234))<br>3. 验证返回 Ok(()) |
| **预期结果** | write_point() 返回 Ok(()) |
| **测试数据** | 地址: 0x0000, 值: 0x1234 |
| **优先级** | P0 |

---

### TC-RTU-304: write_point() 写入只读测点 (离散输入)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-304 |
| **测试名称** | write_point() 写入只读测点 (离散输入) |
| **测试目的** | 验证驱动正确拒绝写入只读测点 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置为只读类型 |
| **测试步骤** | 1. 配置测点为 ReadDiscreteInputs 类型 (只读)<br>2. 调用 write_point()<br>3. 验证返回 Err(DriverError::ReadOnlyPoint) |
| **预期结果** | 返回 Err(DriverError::ReadOnlyPoint) |
| **测试数据** | 只读类型测点 |
| **优先级** | P0 |

---

### TC-RTU-305: write_point() 写入只读测点 (输入寄存器)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-305 |
| **测试名称** | write_point() 写入只读测点 (输入寄存器) |
| **测试目的** | 验证驱动正确拒绝写入只读测点 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 测点配置为只读类型 |
| **测试步骤** | 1. 配置测点为 ReadInputRegisters 类型 (只读)<br>2. 调用 write_point()<br>3. 验证返回 Err(DriverError::ReadOnlyPoint) |
| **预期结果** | 返回 Err(DriverError::ReadOnlyPoint) |
| **测试数据** | 只读类型测点 |
| **优先级** | P0 |

---

### TC-RTU-306: write_point() 无效测点 ID

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-306 |
| **测试名称** | write_point() 无效测点 ID |
| **测试目的** | 验证驱动正确处理未配置的测点 ID |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 调用 write_point(unknown_uuid, value)<br>2. 验证返回 Err |
| **预期结果** | 返回 Err |
| **测试数据** | 未配置的 UUID |
| **优先级** | P0 |

---

### TC-RTU-307: write_point() 未连接状态

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-307 |
| **测试名称** | write_point() 未连接状态 |
| **测试目的** | 验证在未连接状态下写入返回合适错误 |
| **前置条件** | ModbusRtuDriver 已创建但未连接 |
| **测试步骤** | 1. 创建未连接的 ModbusRtuDriver<br>2. 调用 write_point(valid_uuid, value)<br>3. 验证返回 Err(DriverError::NotConnected) |
| **预期结果** | 返回 Err(DriverError::NotConnected) |
| **测试数据** | 任意有效测点 UUID |
| **优先级** | P0 |

---

## 6. 错误处理测试

### TC-RTU-401: 从站返回 IllegalFunction (0x01) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-401 |
| **测试名称** | 从站返回 IllegalFunction 异常 |
| **测试目的** | 验证驱动正确处理非法功能异常 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 发送请求后模拟从站返回异常响应 0x81<br>2. 验证返回 Err |
| **预期结果** | 返回 Err 包含 IllegalFunction 描述 |
| **测试数据** | 异常响应: [slave_id, 0x81, 0x01, crc_low, crc_high] |
| **优先级** | P0 |

---

### TC-RTU-402: 从站返回 IllegalDataAddress (0x02) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-402 |
| **测试名称** | 从站返回 IllegalDataAddress 异常 |
| **测试目的** | 验证驱动正确处理非法数据地址异常 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 发送请求后模拟从站返回异常响应 0x82<br>2. 验证返回 Err |
| **预期结果** | 返回 Err 包含 IllegalDataAddress 描述 |
| **测试数据** | 异常响应: [slave_id, 0x82, 0x02, crc_low, crc_high] |
| **优先级** | P0 |

---

### TC-RTU-403: 从站返回 IllegalDataValue (0x03) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-403 |
| **测试名称** | 从站返回 IllegalDataValue 异常 |
| **测试目的** | 验证驱动正确处理非法数据值异常 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 发送请求后模拟从站返回异常响应 0x83<br>2. 验证返回 Err |
| **预期结果** | 返回 Err 包含 IllegalDataValue 描述 |
| **测试数据** | 异常响应: [slave_id, 0x83, 0x03, crc_low, crc_high] |
| **优先级** | P0 |

---

### TC-RTU-404: 从站返回 ServerDeviceFailure (0x04) 异常

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-404 |
| **测试名称** | 从站返回 ServerDeviceFailure 异常 |
| **测试目的** | 验证驱动正确处理服务器设备故障异常 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 模拟从站返回异常响应 0x84<br>2. 验证返回 Err |
| **预期结果** | 返回 Err 包含 ServerDeviceFailure 描述 |
| **测试数据** | 异常响应: [slave_id, 0x84, 0x04, crc_low, crc_high] |
| **优先级** | P1 |

---

### TC-RTU-405: 从站无响应 (超时)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-405 |
| **测试名称** | 从站无响应 (超时) |
| **测试目的** | 验证驱动正确处理从站无响应的情况 |
| **前置条件** | ModbusRtuDriver 已实现并连接, 从站未连接 |
| **测试步骤** | 1. 发送请求后不模拟从站响应<br>2. 等待超时<br>3. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 超时: 3秒 |
| **优先级** | P0 |

---

### TC-RTU-406: 响应 CRC 错误

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-406 |
| **测试名称** | 响应 CRC 错误 |
| **测试目的** | 验证驱动正确检测并拒绝 CRC 错误的响应 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 模拟从站返回正确格式但 CRC 错误的响应<br>2. 验证返回 Err |
| **预期结果** | 返回 Err(ModbusError::FrameChecksumMismatch) |
| **测试数据** | 正确格式但 CRC 被篡改的响应 |
| **优先级** | P0 |

---

### TC-RTU-407: 响应帧不完整

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-407 |
| **测试名称** | 响应帧不完整 |
| **测试目的** | 验证驱动正确处理响应数据不完整的情况 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 模拟从站返回部分数据后断开<br>2. 验证返回 Err |
| **预期结果** | 返回 Err(ModbusError::IncompleteFrame) |
| **测试数据** | 被截断的响应数据 |
| **优先级** | P1 |

---

### TC-RTU-408: 响应从站 ID 不匹配

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-408 |
| **测试名称** | 响应从站 ID 不匹配 |
| **测试目的** | 验证驱动正确检测响应中的从站 ID 与请求不匹配 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 请求 slave_id=1, 模拟响应 slave_id=2<br>2. 验证返回 Err 或忽略响应 |
| **预期结果** | 返回 Err 或请求超时 (根据实现) |
| **测试数据** | 请求: slave_id=1, 响应: slave_id=2 |
| **优先级** | P1 |

---

## 7. 超时与重试测试

### TC-RTU-501: 连接超时

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-501 |
| **测试名称** | 连接超时 |
| **测试目的** | 验证串口打开超时处理 |
| **前置条件** | ModbusRtuDriver 已实现 |
| **测试步骤** | 1. 配置连接到无效串口或模拟串口打开延迟<br>2. 调用 connect() 方法<br>3. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 超时配置: 3秒 |
| **优先级** | P1 |

---

### TC-RTU-502: 读取超时

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-502 |
| **测试名称** | 读取超时 |
| **测试目的** | 验证从站响应超时处理 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusRtuDriver<br>2. 模拟从站延迟响应 > 超时时间<br>3. 调用 read_point()<br>4. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 延迟: 4秒, 超时: 3秒 |
| **优先级** | P0 |

---

### TC-RTU-503: 写入超时

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-503 |
| **测试名称** | 写入超时 |
| **测试目的** | 验证写入操作超时处理 |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 创建并连接 ModbusRtuDriver<br>2. 模拟从站延迟响应 > 超时时间<br>3. 调用 write_point()<br>4. 验证返回 Err(DriverError::Timeout) |
| **预期结果** | 返回 Err(DriverError::Timeout) |
| **测试数据** | 延迟: 4秒, 超时: 3秒 |
| **优先级** | P1 |

---

## 8. 测点映射测试

### TC-RTU-601: DriverAccess 测点映射 - Coil

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-601 |
| **测试名称** | DriverAccess 测点映射 - Coil |
| **测试目的** | 验证 Coil 类型测点使用正确的功能码 (FC01) |
| **前置条件** | ModbusRtuDriver 已实现并连接, 多个测点已配置 |
| **测试步骤** | 1. 配置 Coil 类型测点<br>2. 读取测点<br>3. 验证发送 FC01 |
| **预期结果** | 发送的功能码为 0x01 (ReadCoils) |
| **测试数据** | RegisterType::Coil -> FC01 |
| **优先级** | P0 |

---

### TC-RTU-602: DriverAccess 测点映射 - DiscreteInput

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-602 |
| **测试名称** | DriverAccess 测点映射 - DiscreteInput |
| **测试目的** | 验证 DiscreteInput 类型测点使用正确的功能码 (FC02) |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置 DiscreteInput 类型测点<br>2. 读取测点<br>3. 验证发送 FC02 |
| **预期结果** | 发送的功能码为 0x02 (ReadDiscreteInputs) |
| **测试数据** | RegisterType::DiscreteInput -> FC02 |
| **优先级** | P0 |

---

### TC-RTU-603: DriverAccess 测点映射 - HoldingRegister

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-603 |
| **测试名称** | DriverAccess 测点映射 - HoldingRegister |
| **测试目的** | 验证 HoldingRegister 类型测点使用正确的功能码 (FC03) |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置 HoldingRegister 类型测点<br>2. 读取测点<br>3. 验证发送 FC03 |
| **预期结果** | 发送的功能码为 0x03 (ReadHoldingRegisters) |
| **测试数据** | RegisterType::HoldingRegister -> FC03 |
| **优先级** | P0 |

---

### TC-RTU-604: DriverAccess 测点映射 - InputRegister

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-604 |
| **测试名称** | DriverAccess 测点映射 - InputRegister |
| **测试目的** | 验证 InputRegister 类型测点使用正确的功能码 (FC04) |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置 InputRegister 类型测点<br>2. 读取测点<br>3. 验证发送 FC04 |
| **预期结果** | 发送的功能码为 0x04 (ReadInputRegisters) |
| **测试数据** | RegisterType::InputRegister -> FC04 |
| **优先级** | P0 |

---

### TC-RTU-605: DriverAccess 测点映射 - WriteSingleCoil

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-605 |
| **测试名称** | DriverAccess 测点映射 - WriteSingleCoil |
| **测试目的** | 验证写入 Coil 使用正确的功能码 (FC05) |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置 Coil 类型测点<br>2. 写入测点<br>3. 验证发送 FC05 |
| **预期结果** | 发送的功能码为 0x05 (WriteSingleCoil) |
| **测试数据** | Coil 写入 -> FC05 |
| **优先级** | P0 |

---

### TC-RTU-606: DriverAccess 测点映射 - WriteSingleRegister

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-606 |
| **测试名称** | DriverAccess 测点映射 - WriteSingleRegister |
| **测试目的** | 验证写入 HoldingRegister 使用正确的功能码 (FC06) |
| **前置条件** | ModbusRtuDriver 已实现并连接 |
| **测试步骤** | 1. 配置 HoldingRegister 类型测点<br>2. 写入测点<br>3. 验证发送 FC06 |
| **预期结果** | 发送的功能码为 0x06 (WriteSingleRegister) |
| **测试数据** | HoldingRegister 写入 -> FC06 |
| **优先级** | P0 |

---

## 9. 测试数据需求

### 9.1 串口配置测试数据

| 参数 | 有效值 | 说明 |
|------|--------|------|
| 波特率 | 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200 | 标准 RS-485 波特率 |
| 校验位 | 'N' (无), 'O' (奇), 'E' (偶) | Modbus 常用校验 |
| 数据位 | 8 | 标准 Modbus 数据位 |
| 停止位 | 1, 2 | 标准停止位 |
| 从站ID | 1-247 | 有效从站地址范围 |

### 9.2 Modbus 地址测试数据

| 地址 | 说明 |
|------|------|
| 0x0000 | 最小地址 |
| 0x0001 | 边界地址 |
| 0x7FFF | 中间地址 |
| 0xFFFF | 最大地址 |

### 9.3 CRC16 测试数据

| 数据 | 预期 CRC16 (低字节在前) |
|------|------------------------|
| [0x01, 0x03, 0x00, 0x00, 0x00, 0x01] | 0x840A |
| [0x01, 0x03, 0x00, 0x00, 0x00, 0x0A] | 0xC5CD |
| [0x01, 0x05, 0x00, 0x00, 0xFF, 0x00] | 0x8C3A |

### 9.4 RTU 帧格式测试数据

**ReadHoldingRegisters 请求** (地址0, 数量1):
```
[0x01] [0x03] [0x00] [0x00] [0x00] [0x01] [CRC_L] [CRC_H]
```

**ReadHoldingRegisters 响应** (值0x1234):
```
[0x01] [0x03] [0x02] [0x12] [0x34] [CRC_L] [CRC_H]
```

---

## 10. 测试环境

### 10.1 开发环境

| 项目 | 要求 |
|------|------|
| Rust 版本 | >= 1.75 |
| 测试框架 | 内置 test + tokio::test + mockall |
| 依赖 | tokio (async runtime), serialport 或自实现串口抽象 |
| 模拟工具 | Mock Serial Port 或模拟从站设备 |

### 10.2 测试命令

```bash
# 运行所有 Modbus RTU 驱动测试
cargo test --package kayak-backend --lib modbus::rtu

# 运行特定测试类别
cargo test --package kayak-backend --lib modbus::rtu::connection
cargo test --package kayak-backend --lib modbus::rtu::crc
cargo test --package kayak-backend --lib modbus::rtu::read
cargo test --package kayak-backend --lib modbus::rtu::write

# 运行带日志的测试
RUST_LOG=debug cargo test --package kayak-backend --lib modbus::rtu

# 生成测试覆盖率报告
cargo tarpaulin --out Html --package kayak-backend
```

### 10.3 依赖假设

| 依赖 | 说明 |
|------|------|
| tokio | 异步运行时 |
| serialport | 串口通信 (如使用外部 crate) |
| tokio::io::{AsyncReadExt, AsyncWriteExt} | 异步读写 |
| async-trait | async trait 支持 |
| uuid | 测点 UUID |

---

## 11. 风险与假设

### 11.1 测试假设

| 假设ID | 描述 |
|--------|------|
| ASM-RTU-101 | ModbusRtuDriver 将在 `drivers/modbus/rtu.rs` 中实现 |
| ASM-RTU-102 | 驱动程序将使用 tokio 作为异步运行时 |
| ASM-RTU-103 | 驱动程序将实现 DriverAccess 和 DriverLifecycle traits |
| ASM-RTU-104 | RTU 帧格式: [slave_id, pdu..., crc16] (无 MBAP) |
| ASM-RTU-105 | CRC16 使用标准 Modbus CRC (低字节在前) |
| ASM-RTU-106 | 连接配置将通过 ModbusRtuConfig 结构体传入 |
| ASM-RTU-107 | 测点配置通过 point_id -> (address, function_code, register_type) 映射表管理 |

### 11.2 测试风险

| 风险ID | 风险描述 | 缓解措施 |
|--------|---------|---------|
| RSK-RTU-101 | 串口设备在测试环境不可用 | 使用 mock 串口或软件模拟器 |
| RSK-RTU-102 | 串口权限问题导致测试失败 | 确保用户有串口访问权限或使用 mock |
| RSK-RTU-103 | 串口测试需要真实硬件 | 使用 USB-to-RS485 模拟器或软件模拟 |
| RSK-RTU-104 | CRC 计算实现依赖特定算法 | 验证标准 CRC16 参考实现 |

### 11.3 测试阻塞项

| 阻塞项 | 依赖 | 状态 |
|--------|------|------|
| ModbusRtuDriver 实现 | R1-S1-004-B (开发) | 待开发 |
| 串口模拟/测试工具 | 测试环境准备 | 待准备 |
| DriverAccess trait 定义 | R1-S1-001 (已完成) | 已完成 |

---

## 12. 测试用例汇总

| 测试ID | 测试名称 | 优先级 | 类型 | 状态 |
|--------|---------|--------|------|------|
| TC-RTU-001 | ModbusRtuConfig 默认配置 | P0 | 单元测试 | 待执行 |
| TC-RTU-002 | ModbusRtuConfig 自定义配置 | P0 | 单元测试 | 待执行 |
| TC-RTU-003 | ModbusRtuDriver 打开有效串口 | P0 | 集成测试 | 待执行 |
| TC-RTU-004 | ModbusRtuDriver 打开无效串口 | P0 | 集成测试 | 待执行 |
| TC-RTU-005 | ModbusRtuDriver 重复连接 | P1 | 集成测试 | 待执行 |
| TC-RTU-006 | ModbusRtuDriver 断开连接 | P0 | 集成测试 | 待执行 |
| TC-RTU-007 | 串口参数验证 - 波特率 | P1 | 单元测试 | 待执行 |
| TC-RTU-008 | 串口参数验证 - 校验位 | P1 | 单元测试 | 待执行 |
| TC-RTU-101 | RTU 帧组装 - 基本结构 | P0 | 单元测试 | 待执行 |
| TC-RTU-102 | CRC16 计算验证 | P0 | 单元测试 | 待执行 |
| TC-RTU-103 | CRC16 验证 - 正确帧 | P0 | 单元测试 | 待执行 |
| TC-RTU-104 | CRC16 验证 - 错误帧 | P0 | 单元测试 | 待执行 |
| TC-RTU-105 | CRC16 验证 - 帧截断 | P0 | 单元测试 | 待执行 |
| TC-RTU-106 | RTU 响应帧解析 - 成功 | P0 | 单元测试 | 待执行 |
| TC-RTU-107 | RTU 响应帧解析 - 异常响应 | P0 | 单元测试 | 待执行 |
| TC-RTU-108 | RTU 帧字节序 - CRC 低字节在前 | P0 | 单元测试 | 待执行 |
| TC-RTU-201 | read_point() 成功读取线圈 (FC01) | P0 | 集成测试 | 待执行 |
| TC-RTU-202 | read_point() 成功读取离散输入 (FC02) | P0 | 集成测试 | 待执行 |
| TC-RTU-203 | read_point() 成功读取保持寄存器 (FC03) | P0 | 集成测试 | 待执行 |
| TC-RTU-204 | read_point() 成功读取输入寄存器 (FC04) | P0 | 集成测试 | 待执行 |
| TC-RTU-205 | read_point() 无效测点 ID | P0 | 集成测试 | 待执行 |
| TC-RTU-206 | read_point() 未连接状态 | P0 | 单元测试 | 待执行 |
| TC-RTU-207 | read_point() 从站无响应 (超时) | P0 | 集成测试 | 待执行 |
| TC-RTU-208 | read_point() 多寄存器连续读取 | P1 | 集成测试 | 待执行 |
| TC-RTU-301 | write_point() 成功写入线圈 ON (FC05) | P0 | 集成测试 | 待执行 |
| TC-RTU-302 | write_point() 成功写入线圈 OFF (FC05) | P0 | 集成测试 | 待执行 |
| TC-RTU-303 | write_point() 成功写入保持寄存器 (FC06) | P0 | 集成测试 | 待执行 |
| TC-RTU-304 | write_point() 写入只读测点 (离散输入) | P0 | 集成测试 | 待执行 |
| TC-RTU-305 | write_point() 写入只读测点 (输入寄存器) | P0 | 集成测试 | 待执行 |
| TC-RTU-306 | write_point() 无效测点 ID | P0 | 集成测试 | 待执行 |
| TC-RTU-307 | write_point() 未连接状态 | P0 | 单元测试 | 待执行 |
| TC-RTU-401 | 从站返回 IllegalFunction (0x01) 异常 | P0 | 集成测试 | 待执行 |
| TC-RTU-402 | 从站返回 IllegalDataAddress (0x02) 异常 | P0 | 集成测试 | 待执行 |
| TC-RTU-403 | 从站返回 IllegalDataValue (0x03) 异常 | P0 | 集成测试 | 待执行 |
| TC-RTU-404 | 从站返回 ServerDeviceFailure (0x04) 异常 | P1 | 集成测试 | 待执行 |
| TC-RTU-405 | 从站无响应 (超时) | P0 | 集成测试 | 待执行 |
| TC-RTU-406 | 响应 CRC 错误 | P0 | 集成测试 | 待执行 |
| TC-RTU-407 | 响应帧不完整 | P1 | 集成测试 | 待执行 |
| TC-RTU-408 | 响应从站 ID 不匹配 | P1 | 集成测试 | 待执行 |
| TC-RTU-501 | 连接超时 | P1 | 集成测试 | 待执行 |
| TC-RTU-502 | 读取超时 | P0 | 集成测试 | 待执行 |
| TC-RTU-503 | 写入超时 | P1 | 集成测试 | 待执行 |
| TC-RTU-601 | DriverAccess 测点映射 - Coil | P0 | 单元测试 | 待执行 |
| TC-RTU-602 | DriverAccess 测点映射 - DiscreteInput | P0 | 单元测试 | 待执行 |
| TC-RTU-603 | DriverAccess 测点映射 - HoldingRegister | P0 | 单元测试 | 待执行 |
| TC-RTU-604 | DriverAccess 测点映射 - InputRegister | P0 | 单元测试 | 待执行 |
| TC-RTU-605 | DriverAccess 测点映射 - WriteSingleCoil | P0 | 单元测试 | 待执行 |
| TC-RTU-606 | DriverAccess 测点映射 - WriteSingleRegister | P0 | 单元测试 | 待执行 |

**总计: 50 个测试用例**

---

## 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2026-05-02 | sw-mike | 初始版本，包含 50 个 RTU 驱动测试用例 |

---

*本文档由 Kayak 项目测试团队维护。如有问题，请联系测试工程师。*
