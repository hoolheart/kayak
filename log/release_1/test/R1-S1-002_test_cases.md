# R1-S1-002 测试用例文档

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S1-002 |
| 测试类型 | 单元测试 |
| 测试范围 | Modbus 核心数据类型与错误定义 |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-02 |
| 版本 | 1.1 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [FunctionCode 测试](#2-functioncode-测试)
3. [ModbusAddress 测试](#3-modbusaddress-测试)
4. [ModbusValue 测试](#4-modbusvalue-测试)
5. [RegisterType 测试](#5-registertype-测试)
6. [ModbusError 测试](#6-modbuserror-测试)
7. [序列化/反序列化测试](#7-序列化反序列化测试)
8. [测试数据需求](#8-测试数据需求)
9. [测试环境](#9-测试环境)
10. [风险与假设](#10-风险与假设)
11. [测试用例汇总](#11-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证 Modbus 核心数据类型和错误定义的正确性，确保：
- `FunctionCode` 枚举包含所有有效的 Modbus 功能码
- `ModbusAddress` 类型正确验证地址范围 (0x0000-0xFFFF)
- `ModbusValue` 类型正确处理不同数据类型的转换和边界
- `RegisterType` 枚举覆盖所有寄存器类型
- `ModbusError` 正确映射 Modbus 异常码并能转换为 DriverError
- MBAP 和 PDU 序列化/反序列化正确工作

### 1.2 测试范围

| 类型 | 测试内容 |
|------|---------|
| `FunctionCode` | 有效功能码 (01,02,03,04,05,06,15,16)，无效功能码拒绝 |
| `ModbusAddress` | 有效地址范围 (0x0000-0xFFFF)，边界值，无效值拒绝 |
| `ModbusValue` | Coil(bool)、DiscreteInput(bool)、HoldingRegister(u16)、InputRegister(u16) |
| `RegisterType` | Coil、DiscreteInput、HoldingRegister、InputRegister |
| `ModbusError` | 异常码映射 (01-04, IllegalFunction 等)，到 DriverError 转换 |
| MBAP/PDU | 帧解析、帧构建、字节序处理 |

### 1.3 测试策略

- **单元测试**：每个类型独立测试，验证构造、转换、边界条件
- **序列化测试**：验证字节流与结构体之间的转换正确性
- **错误场景测试**：验证无效输入被正确拒绝并返回合适的错误

---

## 2. FunctionCode 测试

### TC-001: FunctionCode 有效功能码创建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-001 |
| **测试名称** | FunctionCode 有效功能码创建 |
| **测试目的** | 验证 FunctionCode 能够正确创建所有有效的 Modbus 功能码 |
| **前置条件** | FunctionCode 枚举已定义 |
| **测试步骤** | 1. 尝试创建 FunctionCode::ReadCoils (0x01)<br>2. 尝试创建 FunctionCode::ReadDiscreteInputs (0x02)<br>3. 尝试创建 FunctionCode::ReadHoldingRegisters (0x03)<br>4. 尝试创建 FunctionCode::ReadInputRegisters (0x04)<br>5. 尝试创建 FunctionCode::WriteSingleCoil (0x05)<br>6. 尝试创建 FunctionCode::WriteSingleRegister (0x06)<br>7. 尝试创建 FunctionCode::WriteMultipleCoils (0x0F)<br>8. 尝试创建 FunctionCode::WriteMultipleRegisters (0x10) |
| **预期结果** | 1. 所有 8 个功能码均创建成功<br>2. 每个功能码的 code() 方法返回正确的 u8 值 |
| **测试数据** | 功能码: 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x0F, 0x10 |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_function_code_valid_codes() {
    assert_eq!(FunctionCode::ReadCoils.code(), 0x01);
    assert_eq!(FunctionCode::ReadDiscreteInputs.code(), 0x02);
    assert_eq!(FunctionCode::ReadHoldingRegisters.code(), 0x03);
    assert_eq!(FunctionCode::ReadInputRegisters.code(), 0x04);
    assert_eq!(FunctionCode::WriteSingleCoil.code(), 0x05);
    assert_eq!(FunctionCode::WriteSingleRegister.code(), 0x06);
    assert_eq!(FunctionCode::WriteMultipleCoils.code(), 0x0F);
    assert_eq!(FunctionCode::WriteMultipleRegisters.code(), 0x10);
}
```

---

### TC-002: FunctionCode 无效功能码拒绝

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-002 |
| **测试名称** | FunctionCode 无效功能码拒绝 |
| **测试目的** | 验证 FunctionCode 正确拒绝无效的功能码值 |
| **前置条件** | FunctionCode::new(u8) 方法已实现 |
| **测试步骤** | 1. 尝试使用 0x00 创建 FunctionCode<br>2. 尝试使用 0x09 创建 FunctionCode<br>3. 尝试使用 0x7F 创建 FunctionCode<br>4. 尝试使用 0xFF 创建 FunctionCode |
| **预期结果** | 1. 每次尝试均返回 Err<br>2. 错误类型为 ModbusError::IllegalFunction 或 InvalidFunctionCode |
| **测试数据** | 无效功能码: 0x00, 0x09, 0x7F, 0xFF |
| **优先级** | P0 |

**说明**：
- 0x00 不是有效的 Modbus 功能码
- 0x07 (Report Slave ID) 和 0x08 (Diagnostic) 是有效的 Modbus 诊断功能码，在本项目范围外
- 0x11 (17 decimal, Report Slave ID) 也是有效的 Modbus 功能码
- 0x7F 和 0xFF 超出有效范围

**Rust 测试代码示例**：
```rust
#[test]
fn test_function_code_invalid_codes() {
    // 0x00 is not valid, 0x09, 0x7F, 0xFF are outside supported range
    let invalid_codes = [0x00, 0x09, 0x7F, 0xFF];
    for code in invalid_codes {
        let result = FunctionCode::new(code);
        assert!(result.is_err(), "Code {:02x} should be rejected", code);
    }
}
```

---

### TC-003: FunctionCode::from_u8 转换

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-003 |
| **测试名称** | FunctionCode::from_u8 转换 |
| **测试目的** | 验证 FunctionCode 可以从 u8 值正确转换 |
| **前置条件** | FunctionCode 实现 From<u8> trait |
| **测试步骤** | 1. 使用 From trait 将 0x01 转换为 FunctionCode<br>2. 使用 From trait 将 0x10 转换为 FunctionCode<br>3. 验证转换结果正确 |
| **预期结果** | 1. 转换成功返回对应的 FunctionCode 变体<br>2. 转换失败返回 None 或错误 |
| **测试数据** | 0x01 -> ReadCoils, 0x10 -> WriteMultipleRegisters |
| **优先级** | P1 |

---

### TC-004: FunctionCode 代码匹配性

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-004 |
| **测试名称** | FunctionCode 代码匹配性 |
| **测试目的** | 验证每个 FunctionCode 变体匹配其对应的 Modbus 协议规范 |
| **前置条件** | FunctionCode 枚举已正确定义 |
| **测试步骤** | 1. 验证 ReadCoils (0x01) 返回布尔值数组<br>2. 验证 WriteSingleCoil (0x05) 接受单个布尔值<br>3. 验证 ReadHoldingRegisters (0x03) 返回 u16 数组<br>4. 验证 WriteMultipleRegisters (0x10) 接受 u16 数组<br>5. 验证 ReadDiscreteInputs (0x02) 返回布尔值数组<br>6. 验证 ReadInputRegisters (0x04) 返回 u16 数组 |
| **预期结果** | 每个功能码的行为符合 Modbus 协议规范：<br>- 读取类功能返回数组类型<br>- 写入类功能接受对应数据类型 |
| **测试数据** | 按功能码类型分类验证 |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_function_code_return_types() {
    // Read functions should return Vec<u16> or similar collection
    let read_holding = FunctionCode::ReadHoldingRegisters;
    assert_eq!(read_holding.code(), 0x03);
    // Verify the function is categorized as read-type

    let read_input = FunctionCode::ReadInputRegisters;
    assert_eq!(read_input.code(), 0x04);

    // Write functions accept data
    let write_multi = FunctionCode::WriteMultipleRegisters;
    assert_eq!(write_multi.code(), 0x10);
}
```

---

## 3. ModbusAddress 测试

### TC-005: ModbusAddress 有效地址范围

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-005 |
| **测试名称** | ModbusAddress 有效地址范围 |
| **测试目的** | 验证 ModbusAddress 正确接受 0x0000-0xFFFF 范围内的所有地址 |
| **前置条件** | ModbusAddress::new(u16) 方法已实现 |
| **测试步骤** | 1. 使用 0x0000 创建地址<br>2. 使用 0x0001 创建地址<br>3. 使用 0x7FFF 创建地址<br>4. 使用 0x8000 创建地址<br>5. 使用 0xFFFF 创建地址 |
| **预期结果** | 1. 所有地址创建成功<br>2. value() 方法返回正确的 u16 值 |
| **测试数据** | 边界地址: 0x0000, 0x0001, 0x7FFF, 0x8000, 0xFFFF |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_address_valid_range() {
    let addresses = [0x0000u16, 0x0001, 0x7FFF, 0x8000, 0xFFFF];
    for addr in addresses {
        let result = ModbusAddress::new(addr);
        assert!(result.is_ok(), "Address {:04x} should be valid", addr);
        assert_eq!(result.unwrap().value(), addr);
    }
}
```

---

### TC-006: ModbusAddress 最小地址

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-006 |
| **测试名称** | ModbusAddress 最小地址 |
| **测试目的** | 验证 ModbusAddress 正确处理最小地址 0x0000 |
| **前置条件** | ModbusAddress 已实现 |
| **测试步骤** | 1. 创建 ModbusAddress::new(0)<br>2. 验证 value() 返回 0 |
| **预期结果** | 1. 创建成功<br>2. 值为 0 |
| **测试数据** | 0x0000 |
| **优先级** | P1 |

---

### TC-007: ModbusAddress 最大地址

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-007 |
| **测试名称** | ModbusAddress 最大地址 |
| **测试目的** | 验证 ModbusAddress 正确处理最大地址 0xFFFF |
| **前置条件** | ModbusAddress 已实现 |
| **测试步骤** | 1. 创建 ModbusAddress::new(65535)<br>2. 验证 value() 返回 65535 |
| **预期结果** | 1. 创建成功<br>2. 值为 65535 |
| **测试数据** | 0xFFFF |
| **优先级** | P1 |

---

### TC-008: ModbusAddress 越界拒绝

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-008 |
| **测试名称** | ModbusAddress 越界拒绝 |
| **测试目的** | 验证 ModbusAddress 正确拒绝超出 0x0000-0xFFFF 范围的值 |
| **前置条件** | ModbusAddress::new(u32) 或类似方法已实现 |
| **测试步骤** | 1. 尝试使用 0x10000 创建地址<br>2. 尝试使用 0x1FFFF 创建地址<br>3. 尝试使用 u32::MAX 创建地址 |
| **预期结果** | 1. 所有超范围地址均被拒绝<br>2. 返回 InvalidAddress 或 AddressOutOfRange 错误 |
| **测试数据** | 超范围值: 65536, 131071, u32::MAX |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_address_out_of_range() {
    let out_of_range = [0x10000u32, 0x1FFFF, u32::MAX];
    for addr in out_of_range {
        let result = ModbusAddress::new(addr);
        assert!(result.is_err(), "Address {} should be rejected", addr);
    }
}
```

---

### TC-009: ModbusAddress serde 序列化

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-009 |
| **测试名称** | ModbusAddress serde 序列化 |
| **测试目的** | 验证 ModbusAddress 可以正确序列化和反序列化 |
| **前置条件** | ModbusAddress 实现 Serialize 和 Deserialize |
| **测试步骤** | 1. 创建 ModbusAddress(0x1234)<br>2. 序列化为 JSON<br>3. 反序列化回 ModbusAddress<br>4. 验证值一致 |
| **预期结果** | 1. 序列化成功<br>2. 反序列化后值与原始值一致 |
| **测试数据** | 0x1234 |
| **优先级** | P1 |

---

## 4. ModbusValue 测试

### TC-010: ModbusValue Coil 类型创建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-010 |
| **测试名称** | ModbusValue Coil 类型创建 |
| **测试目的** | 验证 ModbusValue 可以正确创建 Coil 类型 (布尔值) |
| **前置条件** | ModbusValue 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusValue::Coil(true)<br>2. 创建 ModbusValue::Coil(false)<br>3. 验证 as_bool() 返回正确值 |
| **预期结果** | 1. 创建成功<br>2. as_bool() 返回对应的布尔值 |
| **测试数据** | Coil(true), Coil(false) |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_value_coil() {
    let coil_on = ModbusValue::Coil(true);
    let coil_off = ModbusValue::Coil(false);

    assert_eq!(coil_on.as_bool(), Some(true));
    assert_eq!(coil_off.as_bool(), Some(false));
}
```

---

### TC-011: ModbusValue DiscreteInput 类型创建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-011 |
| **测试名称** | ModbusValue DiscreteInput 类型创建 |
| **测试目的** | 验证 ModbusValue 可以正确创建 DiscreteInput 类型 (布尔值) |
| **前置条件** | ModbusValue 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusValue::DiscreteInput(true)<br>2. 创建 ModbusValue::DiscreteInput(false)<br>3. 验证 as_bool() 返回正确值 |
| **预期结果** | 1. 创建成功<br>2. as_bool() 返回对应的布尔值 |
| **测试数据** | DiscreteInput(true), DiscreteInput(false) |
| **优先级** | P0 |

---

### TC-012: ModbusValue HoldingRegister 类型创建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-012 |
| **测试名称** | ModbusValue HoldingRegister 类型创建 |
| **测试目的** | 验证 ModbusValue 可以正确创建 HoldingRegister 类型 (u16) |
| **前置条件** | ModbusValue 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusValue::HoldingRegister(0)<br>2. 创建 ModbusValue::HoldingRegister(32768)<br>3. 创建 ModbusValue::HoldingRegister(65535)<br>4. 验证 as_u16() 返回正确值 |
| **预期结果** | 1. 创建成功<br>2. as_u16() 返回正确的 u16 值 |
| **测试数据** | HoldingRegister: 0, 32768, 65535 |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_value_holding_register() {
    let hr_min = ModbusValue::HoldingRegister(0);
    let hr_mid = ModbusValue::HoldingRegister(32768);
    let hr_max = ModbusValue::HoldingRegister(65535);

    assert_eq!(hr_min.as_u16(), Some(0));
    assert_eq!(hr_mid.as_u16(), Some(32768));
    assert_eq!(hr_max.as_u16(), Some(65535));
}
```

---

### TC-013: ModbusValue InputRegister 类型创建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-013 |
| **测试名称** | ModbusValue InputRegister 类型创建 |
| **测试目的** | 验证 ModbusValue 可以正确创建 InputRegister 类型 (u16) |
| **前置条件** | ModbusValue 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusValue::InputRegister(0)<br>2. 创建 ModbusValue::InputRegister(65535)<br>3. 验证 as_u16() 返回正确值 |
| **预期结果** | 1. 创建成功<br>2. as_u16() 返回正确的 u16 值 |
| **测试数据** | InputRegister: 0, 65535 |
| **优先级** | P0 |

---

### TC-014: ModbusValue 类型不匹配访问

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-014 |
| **测试名称** | ModbusValue 类型不匹配访问 |
| **测试目的** | 验证 ModbusValue 访问器对类型不匹配时返回 None |
| **前置条件** | ModbusValue 各种类型已定义 |
| **测试步骤** | 1. 创建 ModbusValue::Coil(true)<br>2. 调用 as_u16()，验证返回 None<br>3. 创建 ModbusValue::HoldingRegister(100)<br>4. 调用 as_bool()，验证返回 None |
| **预期结果** | 1. Coil 调用 as_u16() 返回 None<br>2. HoldingRegister 调用 as_bool() 返回 None |
| **测试数据** | Coil(true), HoldingRegister(100) |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_value_type_mismatch() {
    let coil = ModbusValue::Coil(true);
    let hr = ModbusValue::HoldingRegister(100);

    assert_eq!(coil.as_u16(), None);  // Coil doesn't have u16 value
    assert_eq!(hr.as_bool(), None);   // Register doesn't have bool value
}
```

---

### TC-015: ModbusValue 边界值测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-015 |
| **测试名称** | ModbusValue 边界值测试 |
| **测试目的** | 验证 ModbusValue 处理 u16 边界值 0 和 65535 |
| **前置条件** | ModbusValue 已定义 |
| **测试步骤** | 1. 创建 HoldingRegister(0)，验证值<br>2. 创建 HoldingRegister(65535)，验证值<br>3. 对 InputRegister 同样测试 |
| **预期结果** | 1. 边界值 0 和 65535 均正确处理<br>2. 值不发生溢出或截断 |
| **测试数据** | 0, 65535 |
| **优先级** | P1 |

---

### TC-016: ModbusValue serde 序列化

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-016 |
| **测试名称** | ModbusValue serde 序列化 |
| **测试目的** | 验证 ModbusValue 可以正确序列化和反序列化 |
| **前置条件** | ModbusValue 实现 Serialize 和 Deserialize |
| **测试步骤** | 1. 创建 ModbusValue::Coil(true)<br>2. 序列化为 JSON<br>3. 反序列化回 ModbusValue<br>4. 验证值一致 |
| **预期结果** | 序列化/反序列化后值不变 |
| **测试数据** | Coil(true), HoldingRegister(0x1234) |
| **优先级** | P1 |

---

## 5. RegisterType 测试

### TC-017: RegisterType 所有变体

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-017 |
| **测试名称** | RegisterType 所有变体 |
| **测试目的** | 验证 RegisterType 枚举包含所有四种寄存器类型 |
| **前置条件** | RegisterType 枚举已定义 |
| **测试步骤** | 1. 验证 RegisterType::Coil 存在<br>2. 验证 RegisterType::DiscreteInput 存在<br>3. 验证 RegisterType::HoldingRegister 存在<br>4. 验证 RegisterType::InputRegister 存在 |
| **预期结果** | 所有四种寄存器类型均可用 |
| **测试数据** | Coil, DiscreteInput, HoldingRegister, InputRegister |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_register_type_variants() {
    use RegisterType::*;
    let variants = [Coil, DiscreteInput, HoldingRegister, InputRegister];
    assert_eq!(variants.len(), 4);
}
```

---

### TC-018: RegisterType 与 FunctionCode 关联

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-018 |
| **测试名称** | RegisterType 与 FunctionCode 关联 |
| **测试目的** | 验证每种 RegisterType 对应正确的 FunctionCode |
| **前置条件** | RegisterType 和 FunctionCode 均已定义 |
| **测试步骤** | 1. 验证 Coil -> FunctionCode::ReadCoils/WriteSingleCoil/WriteMultipleCoils<br>2. 验证 DiscreteInput -> FunctionCode::ReadDiscreteInputs<br>3. 验证 HoldingRegister -> FunctionCode::ReadHoldingRegisters/WriteSingleRegister/WriteMultipleRegisters<br>4. 验证 InputRegister -> FunctionCode::ReadInputRegisters |
| **预期结果** | 每个 RegisterType 正确映射到对应的 FunctionCode(s) |
| **测试数据** | 按寄存器类型验证对应的功能码 |
| **优先级** | P1 |

---

### TC-019: RegisterType serde 序列化

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-019 |
| **测试名称** | RegisterType serde 序列化 |
| **测试目的** | 验证 RegisterType 可以正确序列化和反序列化 |
| **前置条件** | RegisterType 实现 Serialize 和 Deserialize |
| **测试步骤** | 1. 创建 RegisterType::HoldingRegister<br>2. 序列化为 JSON<br>3. 反序列化回 RegisterType<br>4. 验证值一致 |
| **预期结果** | 序列化/反序列化后值不变 |
| **测试数据** | HoldingRegister |
| **优先级** | P1 |

---

## 6. ModbusError 测试

### TC-020: ModbusError 异常码映射 - IllegalFunction

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-020 |
| **测试名称** | ModbusError 异常码映射 - IllegalFunction |
| **测试目的** | 验证 ModbusError 正确映射 Modbus 异常码 01 (非法功能) |
| **前置条件** | ModbusError 枚举已定义，包含 IllegalFunction 变体 |
| **测试步骤** | 1. 创建 ModbusError::IllegalFunction<br>2. 验证 error_code() 返回 1 或 0x01<br>3. 验证 to_driver_error() 转换为 DriverError::InvalidValue |
| **预期结果** | 1. error_code() 返回 1<br>2. 转换为合适的 DriverError |
| **测试数据** | IllegalFunction |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_error_illegal_function() {
    let error = ModbusError::IllegalFunction;
    assert_eq!(error.error_code(), 0x01);

    let driver_error: DriverError = error.into();
    assert!(matches!(driver_error, DriverError::InvalidValue(_)));
}
```

---

### TC-021: ModbusError 异常码映射 - IllegalDataAddress

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-021 |
| **测试名称** | ModbusError 异常码映射 - IllegalDataAddress |
| **测试目的** | 验证 ModbusError 正确映射 Modbus 异常码 02 (非法数据地址) |
| **前置条件** | ModbusError 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusError::IllegalDataAddress<br>2. 验证 error_code() 返回 2<br>3. 验证转换为 DriverError::InvalidValue |
| **预期结果** | 1. error_code() 返回 2<br>2. 转换为 DriverError::InvalidValue |
| **测试数据** | IllegalDataAddress |
| **优先级** | P0 |

---

### TC-022: ModbusError 异常码映射 - IllegalDataValue

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-022 |
| **测试名称** | ModbusError 异常码映射 - IllegalDataValue |
| **测试目的** | 验证 ModbusError 正确映射 Modbus 异常码 03 (非法数据值) |
| **前置条件** | ModbusError 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusError::IllegalDataValue<br>2. 验证 error_code() 返回 3 |
| **预期结果** | error_code() 返回 3 |
| **测试数据** | IllegalDataValue |
| **优先级** | P0 |

---

### TC-023: ModbusError 异常码映射 - ServerDeviceFailure

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-023 |
| **测试名称** | ModbusError 异常码映射 - ServerDeviceFailure |
| **测试目的** | 验证 ModbusError 正确映射 Modbus 异常码 04 (从站设备故障) |
| **前置条件** | ModbusError 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusError::ServerDeviceFailure<br>2. 验证 error_code() 返回 4 |
| **预期结果** | error_code() 返回 4 |
| **测试数据** | ServerDeviceFailure |
| **优先级** | P0 |

---

### TC-024: ModbusError Acknowledge 异常码

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-024 |
| **测试名称** | ModbusError Acknowledge 异常码 |
| **测试目的** | 验证 ModbusError 正确映射 Modbus 异常码 05 (确认) |
| **前置条件** | ModbusError 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusError::Acknowledge<br>2. 验证 error_code() 返回 5 |
| **预期结果** | error_code() 返回 5 |
| **测试数据** | Acknowledge |
| **优先级** | P1 |

---

### TC-025: ModbusError ServerBusy 异常码

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-025 |
| **测试名称** | ModbusError ServerBusy 异常码 |
| **测试目的** | 验证 ModbusError 正确映射 Modbus 异常码 06 (服务器忙) |
| **前置条件** | ModbusError 枚举已定义 |
| **测试步骤** | 1. 创建 ModbusError::ServerBusy<br>2. 验证 error_code() 返回 6 |
| **预期结果** | error_code() 返回 6 |
| **测试数据** | ServerBusy |
| **优先级** | P1 |

---

### TC-026: ModbusError 转换为 DriverError

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-026 |
| **测试名称** | ModbusError 转换为 DriverError |
| **测试目的** | 验证 ModbusError 可以正确转换为 DriverError |
| **前置条件** | ModbusError 实现 Into<DriverError> 或 From<ModbusError> for DriverError |
| **测试步骤** | 1. 将 IllegalFunction 转换为 DriverError<br>2. 将 IllegalDataAddress 转换为 DriverError |
| **预期结果** | 每种 ModbusError 转换为合适的 DriverError 变体 |
| **测试数据** | IllegalFunction, IllegalDataAddress |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_error_to_driver_error() {
    let illegal_func: DriverError = ModbusError::IllegalFunction.into();
    assert!(matches!(illegal_func, DriverError::InvalidValue(_)));

    let illegal_addr: DriverError = ModbusError::IllegalDataAddress.into();
    assert!(matches!(illegal_addr, DriverError::InvalidValue(_)));
}
```

---

### TC-026a: ModbusError Timeout 通信错误

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-026a |
| **测试名称** | ModbusError Timeout 通信错误 |
| **测试目的** | 验证 ModbusError::Timeout 正确表示通信超时错误（不是 Modbus 异常码） |
| **前置条件** | ModbusError 枚举已定义，包含 Timeout 变体 |
| **测试步骤** | 1. 创建 ModbusError::Timeout<br>2. 验证 timeout() 方法返回 true 或 error_code() 返回特定值<br>3. 将 Timeout 转换为 DriverError<br>4. 验证转换为 DriverError::Timeout |
| **预期结果** | 1. Timeout 是通信错误，不是 Modbus 协议异常码<br>2. 正确转换为 DriverError::Timeout |
| **测试数据** | Timeout |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_error_timeout() {
    // Timeout is a communication error, NOT a Modbus exception code (01-08)
    let timeout = ModbusError::Timeout;
    assert!(timeout.is_timeout());

    // Convert to DriverError
    let driver_err: DriverError = timeout.into();
    assert!(matches!(driver_err, DriverError::Timeout(_)));
}
```

---

### TC-027: ModbusError From u8 构造

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-027 |
| **测试名称** | ModbusError From u8 构造 |
| **测试目的** | 验证 ModbusError 可以从原始异常码 u8 值创建 |
| **前置条件** | ModbusError 实现 From<u8> |
| **测试步骤** | 1. 使用 ModbusError::from(0x01) 创建<br>2. 使用 ModbusError::from(0x04) 创建<br>3. 验证结果正确 |
| **预期结果** | 1. 0x01 -> IllegalFunction<br>2. 0x04 -> ServerDeviceFailure |
| **测试数据** | 0x01, 0x04 |
| **优先级** | P1 |

---

### TC-028: ModbusError Invalid 异常码

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-028 |
| **测试名称** | ModbusError Invalid 异常码 |
| **测试目的** | 验证 ModbusError 正确处理超出有效范围 (01-04, 05-08) 的异常码 |
| **前置条件** | ModbusError 实现 From<u8> |
| **测试步骤** | 1. 使用 0x00 创建 ModbusError<br>2. 使用 0x09 创建 ModbusError<br>3. 使用 0xFF 创建 ModbusError |
| **预期结果** | 1. 0x00 -> Unknown 或 Invalid<br>2. 0x09 -> Unknown 或 Invalid<br>3. 0xFF -> Unknown 或 Invalid |
| **测试数据** | 0x00, 0x09, 0xFF |
| **优先级** | P1 |

---

## 7. 序列化/反序列化测试

### TC-029: MBAP 头部解析 - 有效帧

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-029 |
| **测试名称** | MBAP 头部解析 - 有效帧 |
| **测试目的** | 验证 MBAP (Modbus Application Protocol) 头部可以正确解析 |
| **前置条件** | MbapHeader 结构体和 parse 方法已实现 |
| **测试步骤** | 1. 创建标准 MBAP 头部字节序列<br>2. 调用 MbapHeader::parse() 解析<br>3. 验证解析结果：transaction_id, protocol_id, length, unit_id |
| **预期结果** | 1. 解析成功返回 MbapHeader<br>2. 各字段值正确 |
| **测试数据** | [0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01] (transaction=1, protocol=0, length=6, unit=1) |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_mbap_header_parse_valid() {
    let data = [0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01];
    let header = MbapHeader::parse(&data).unwrap();

    assert_eq!(header.transaction_id, 1);
    assert_eq!(header.protocol_id, 0);
    assert_eq!(header.length, 6);
    assert_eq!(header.unit_id, 1);
}
```

---

### TC-030: MBAP 头部构建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-030 |
| **测试名称** | MBAP 头部构建 |
| **测试目的** | 验证 MbapHeader 可以正确构建为字节序列 |
| **前置条件** | MbapHeader 实现了 to_bytes 或 serialize 方法 |
| **测试步骤** | 1. 创建 MbapHeader { transaction_id: 1, protocol_id: 0, length: 6, unit_id: 1 }<br>2. 调用 to_bytes() 方法<br>3. 验证返回的字节序列正确 |
| **预期结果** | to_bytes() 返回 [0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01] |
| **测试数据** | transaction=1, protocol=0, length=6, unit=1 |
| **优先级** | P0 |

---

### TC-031: MBAP 头部解析 - 无效长度

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-031 |
| **测试名称** | MBAP 头部解析 - 无效长度 |
| **测试目的** | 验证 MBAP 解析正确拒绝长度字段不一致的数据 |
| **前置条件** | MbapHeader::parse 已实现 |
| **测试步骤** | 1. 准备 MBAP 数据，长度字段为 5 但实际为 6<br>2. 调用 parse() 解析<br>3. 验证返回错误 |
| **预期结果** | parse() 返回 Err(InvalidMbapLength 或类似错误) |
| **测试数据** | [0x00, 0x01, 0x00, 0x00, 0x00, 0x05, 0x01, 0x03, 0x00] (声明长度5但实际更长) |
| **优先级** | P1 |

---

### TC-032: MBAP 头部解析 - 数据太短

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-032 |
| **测试名称** | MBAP 头部解析 - 数据太短 |
| **测试目的** | 验证 MBAP 解析正确拒绝数据不足的情况 |
| **前置条件** | MbapHeader::parse 已实现 |
| **测试步骤** | 1. 提供只有 5 字节的数据（MBAP 头部需要 7 字节）<br>2. 调用 parse() 解析 |
| **预期结果** | parse() 返回 Err(IncompleteMbap 或类似错误) |
| **测试数据** | [0x00, 0x01, 0x00, 0x00, 0x00] (只有5字节) |
| **优先级** | P0 |

---

### TC-033: PDU 解析 - ReadHoldingRegisters 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-033 |
| **测试名称** | PDU 解析 - ReadHoldingRegisters 请求 |
| **测试目的** | 验证 PDU 可以正确解析 ReadHoldingRegisters (0x03) 请求 |
| **前置条件** | Pdu 结构体和 parse 方法已实现 |
| **测试步骤** | 1. 创建 ReadHoldingRegisters 请求字节序列: [0x03, 0x00, 0x00, 0x00, 0x0A]<br>2. 调用 Pdu::parse() 解析<br>3. 验证 function_code, start_address, quantity |
| **预期结果** | 1. function_code == FunctionCode::ReadHoldingRegisters<br>2. start_address == 0<br>3. quantity == 10 |
| **测试数据** | [0x03, 0x00, 0x00, 0x00, 0x0A] |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_parse_read_holding_registers() {
    let data = [0x03, 0x00, 0x00, 0x00, 0x0A];
    let pdu = Pdu::parse(&data).unwrap();

    assert_eq!(pdu.function_code, FunctionCode::ReadHoldingRegisters);
    assert_eq!(pdu.data[..2], [0x00, 0x00]);  // start address
    assert_eq!(pdu.data[2..4], [0x00, 0x0A]); // quantity
}
```

---

### TC-034: PDU 构建 - ReadHoldingRegisters 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-034 |
| **测试名称** | PDU 构建 - ReadHoldingRegisters 请求 |
| **测试目的** | 验证可以正确构建 ReadHoldingRegisters PDU |
| **前置条件** | PduBuilder 或 Pdu::new_read_holding_registers 已实现 |
| **测试步骤** | 1. 调用 Pdu::read_holding_registers(0, 10)<br>2. 获取生成的字节序列<br>3. 验证字节序列正确 |
| **预期结果** | 返回 [0x03, 0x00, 0x00, 0x00, 0x0A] |
| **测试数据** | start_address=0, quantity=10 |
| **优先级** | P0 |

---

### TC-035: PDU 解析 - ReadCoils 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-035 |
| **测试名称** | PDU 解析 - ReadCoils 请求 |
| **测试目的** | 验证 PDU 可以正确解析 ReadCoils (0x01) 请求 |
| **前置条件** | Pdu 解析已实现 |
| **测试步骤** | 1. 创建 ReadCoils 请求字节序列: [0x01, 0x00, 0x00, 0x00, 0x19]<br>2. 调用 Pdu::parse() 解析<br>3. 验证解析结果 |
| **预期结果** | function_code == ReadCoils, start_address == 0, quantity == 25 |
| **测试数据** | [0x01, 0x00, 0x00, 0x00, 0x19] |
| **优先级** | P0 |

---

### TC-036: PDU 解析 - WriteSingleRegister 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-036 |
| **测试名称** | PDU 解析 - WriteSingleRegister 请求 |
| **测试目的** | 验证 PDU 可以正确解析 WriteSingleRegister (0x06) 请求 |
| **前置条件** | Pdu 解析已实现 |
| **测试步骤** | 1. 创建 WriteSingleRegister 请求字节序列: [0x06, 0x00, 0x01, 0x03, 0xE8]<br>2. 调用 Pdu::parse() 解析<br>3. 验证 address == 1, value == 1000 |
| **预期结果** | function_code == WriteSingleRegister, address == 1, value == 1000 |
| **测试数据** | [0x06, 0x00, 0x01, 0x03, 0xE8] |
| **优先级** | P0 |

---

### TC-037: PDU 解析 - 异常响应

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-037 |
| **测试名称** | PDU 解析 - 异常响应 |
| **测试目的** | 验证 PDU 可以正确解析 Modbus 异常响应 (功能码 + 0x80) |
| **前置条件** | Pdu 解析已实现 |
| **测试步骤** | 1. 创建异常响应字节序列: [0x83, 0x02] (ReadHoldingRegisters + IllegalDataAddress)<br>2. 调用 Pdu::parse() 解析<br>3. 验证 is_error() == true, error_code == 2 |
| **预期结果** | 1. is_error() 返回 true<br>2. 对应的 ModbusError 为 IllegalDataAddress |
| **测试数据** | [0x83, 0x02] |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_parse_error_response() {
    let data = [0x83, 0x02];  // 0x03 + 0x80 = 0x83, exception code 0x02
    let pdu = Pdu::parse(&data).unwrap();

    assert!(pdu.is_error());
    assert_eq!(pdu.exception_code(), Some(0x02));
}
```

---

### TC-038: PDU 构建 - WriteMultipleRegisters

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-038 |
| **测试名称** | PDU 构建 - WriteMultipleRegisters |
| **测试目的** | 验证可以正确构建 WriteMultipleRegisters PDU |
| **前置条件** | PduBuilder 或类似方法已实现 |
| **测试步骤** | 1. 调用 Pdu::write_multiple_registers(0, &[0x1234, 0x5678])<br>2. 验证生成的字节序列正确<br>3. 验证 byte_count 和 register_count 正确 |
| **预期结果** | PDU 包含正确的功能码、起始地址、数量、字节计数和寄存器值 |
| **测试数据** | start_address=0, registers=[0x1234, 0x5678] |
| **预期字节序列** | [0x10, 0x00, 0x00, 0x00, 0x02, 0x04, 0x12, 0x34, 0x56, 0x78]<br>含义: 功能码0x10, 起始地址0x0000, 寄存器数量0x0002, 字节计数0x04, 寄存器值0x1234, 0x5678 |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_build_write_multiple_registers() {
    let pdu = Pdu::write_multiple_registers(0, &[0x1234, 0x5678]);
    let bytes = pdu.to_bytes();

    // [0x10, 0x00, 0x00, 0x00, 0x02, 0x04, 0x12, 0x34, 0x56, 0x78]
    assert_eq!(bytes, [
        0x10,                      // function code: WriteMultipleRegisters
        0x00, 0x00,                // start address: 0
        0x00, 0x02,                // quantity: 2 registers
        0x04,                      // byte count: 4 bytes (2 registers * 2 bytes)
        0x12, 0x34,                // register 1: 0x1234
        0x56, 0x78,                // register 2: 0x5678
    ]);
}
```

---

### TC-039: PDU 解析 - 数据不完整

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-039 |
| **测试名称** | PDU 解析 - 数据不完整 |
| **测试目的** | 验证 PDU 解析正确拒绝数据不完整的情况 |
| **前置条件** | Pdu::parse 已实现 |
| **测试步骤** | 1. 提供只有部分字节的 PDU 数据<br>2. 调用 parse() 解析 |
| **预期结果** | parse() 返回 Err(ParseError::IncompleteData 或类似错误) |
| **错误类型** | ParseError::IncompleteData |
| **测试数据** | [0x03, 0x00] (不完整的 ReadHoldingRegisters，需要5字节但只有2字节) |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_parse_incomplete_data() {
    let data = [0x03, 0x00]; // Incomplete - ReadHoldingRegisters needs 5 bytes
    let result = Pdu::parse(&data);

    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ParseError::IncompleteData));
}
```

---

### TC-040: PDU 与 MBAP 组装

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-040 |
| **测试名称** | PDU 与 MBAP 组装 |
| **测试目的** | 验证完整的 Modbus TCP 帧 (MBAP + PDU) 可以正确组装 |
| **前置条件** | MbapHeader 和 Pdu 均已实现 |
| **测试步骤** | 1. 创建 MbapHeader<br>2. 创建 Pdu<br>3. 调用 assemble() 或类似方法<br>4. 验证返回完整的字节序列 |
| **预期结果** | 返回包含 MBAP (7字节) + PDU 的完整帧 |
| **测试数据** | 标准 ReadHoldingRegisters 帧 |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_modbus_frame_assemble() {
    let header = MbapHeader::new(1, 0, 6, 1);
    let pdu = Pdu::read_holding_registers(0, 10);
    let frame = ModbusFrame::assemble(header, pdu);

    assert_eq!(frame.len(), 7 + 5);  // MBAP + PDU
    assert_eq!(&frame[0..7], &[0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01]);
}
```

---

### TC-041: PDU 解析 - ReadDiscreteInputs 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-041 |
| **测试名称** | PDU 解析 - ReadDiscreteInputs 请求 |
| **测试目的** | 验证 PDU 可以正确解析 ReadDiscreteInputs (0x02) 请求 |
| **前置条件** | Pdu 解析已实现 |
| **测试步骤** | 1. 创建 ReadDiscreteInputs 请求字节序列: [0x02, 0x00, 0x00, 0x00, 0x10]<br>2. 调用 Pdu::parse() 解析<br>3. 验证 function_code, start_address, quantity |
| **预期结果** | 1. function_code == FunctionCode::ReadDiscreteInputs<br>2. start_address == 0<br>3. quantity == 16 |
| **测试数据** | [0x02, 0x00, 0x00, 0x00, 0x10] (start_address=0, quantity=16) |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_parse_read_discrete_inputs() {
    let data = [0x02, 0x00, 0x00, 0x00, 0x10];
    let pdu = Pdu::parse(&data).unwrap();

    assert_eq!(pdu.function_code, FunctionCode::ReadDiscreteInputs);
    assert_eq!(pdu.data[..2], [0x00, 0x00]);  // start address
    assert_eq!(pdu.data[2..4], [0x00, 0x10]); // quantity = 16
}
```

---

### TC-042: PDU 解析 - ReadInputRegisters 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-042 |
| **测试名称** | PDU 解析 - ReadInputRegisters 请求 |
| **测试目的** | 验证 PDU 可以正确解析 ReadInputRegisters (0x04) 请求 |
| **前置条件** | Pdu 解析已实现 |
| **测试步骤** | 1. 创建 ReadInputRegisters 请求字节序列: [0x04, 0x00, 0x00, 0x00, 0x08]<br>2. 调用 Pdu::parse() 解析<br>3. 验证 function_code, start_address, quantity |
| **预期结果** | 1. function_code == FunctionCode::ReadInputRegisters<br>2. start_address == 0<br>3. quantity == 8 |
| **测试数据** | [0x04, 0x00, 0x00, 0x00, 0x08] (start_address=0, quantity=8) |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_parse_read_input_registers() {
    let data = [0x04, 0x00, 0x00, 0x00, 0x08];
    let pdu = Pdu::parse(&data).unwrap();

    assert_eq!(pdu.function_code, FunctionCode::ReadInputRegisters);
    assert_eq!(pdu.data[..2], [0x00, 0x00]);  // start address
    assert_eq!(pdu.data[2..4], [0x00, 0x08]); // quantity = 8
}
```

---

### TC-043: PDU 解析 - WriteMultipleCoils 请求

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-043 |
| **测试名称** | PDU 解析 - WriteMultipleCoils 请求 |
| **测试目的** | 验证 PDU 可以正确解析 WriteMultipleCoils (0x0F) 请求 |
| **前置条件** | Pdu 解析已实现 |
| **测试步骤** | 1. 创建 WriteMultipleCoils 请求字节序列: [0x0F, 0x00, 0x00, 0x00, 0x10, 0x02, 0xCD, 0x01]<br>2. 调用 Pdu::parse() 解析<br>3. 验证 function_code, start_address, quantity, byte_count |
| **预期结果** | 1. function_code == FunctionCode::WriteMultipleCoils<br>2. start_address == 0<br>3. quantity == 16<br>4. byte_count == 2 |
| **测试数据** | [0x0F, 0x00, 0x00, 0x00, 0x10, 0x02, 0xCD, 0x01] (start_address=0, quantity=16, byte_count=2, coils=0xCD01) |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_pdu_parse_write_multiple_coils() {
    let data = [0x0F, 0x00, 0x00, 0x00, 0x10, 0x02, 0xCD, 0x01];
    let pdu = Pdu::parse(&data).unwrap();

    assert_eq!(pdu.function_code, FunctionCode::WriteMultipleCoils);
    assert_eq!(pdu.data[..2], [0x00, 0x00]);  // start address
    assert_eq!(pdu.data[2..4], [0x00, 0x10]); // quantity = 16
    assert_eq!(pdu.data[4], 0x02);            // byte count
}
```

---

### TC-044: PDU 构建 - WriteMultipleCoils

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-044 |
| **测试名称** | PDU 构建 - WriteMultipleCoils |
| **测试目的** | 验证可以正确构建 WriteMultipleCoils PDU |
| **前置条件** | PduBuilder 或类似方法已实现 |
| **测试步骤** | 1. 调用 Pdu::write_multiple_coils(0, &[true, false, true, true, false, true, true, false])<br>2. 验证生成的字节序列正确<br>3. 验证 byte_count 和 coil_count 正确 |
| **预期结果** | PDU 包含正确的功能码、起始地址、数量、字节计数和线圈值 |
| **测试数据** | start_address=0, coils=[true, false, true, true, false, true, true, false] (8 coils, 1 byte) |
| **预期字节序列** | [0x0F, 0x00, 0x00, 0x00, 0x08, 0x01, 0xCD] |
| **优先级** | P1 |

---

## 8. 测试数据需求

### 8.1 FunctionCode 测试数据

| 功能码 | 名称 | 用途 |
|--------|------|------|
| 0x01 | ReadCoils | 读取线圈 |
| 0x02 | ReadDiscreteInputs | 读取离散输入 |
| 0x03 | ReadHoldingRegisters | 读取保持寄存器 |
| 0x04 | ReadInputRegisters | 读取输入寄存器 |
| 0x05 | WriteSingleCoil | 写单个线圈 |
| 0x06 | WriteSingleRegister | 写单个寄存器 |
| 0x0F | WriteMultipleCoils | 写多个线圈 |
| 0x10 | WriteMultipleRegisters | 写多个寄存器 |

### 8.2 ModbusAddress 测试数据

| 地址 | 说明 |
|------|------|
| 0x0000 | 最小地址 |
| 0x0001 | 边界地址 |
| 0x7FFF | 中间地址 |
| 0x8000 | 中间地址 |
| 0xFFFF | 最大地址 |

### 8.3 ModbusValue 测试数据

| 类型 | 测试值 | 说明 |
|------|--------|------|
| Coil | true, false | 布尔值 |
| DiscreteInput | true, false | 布尔值 |
| HoldingRegister | 0, 32768, 65535 | u16 边界值 |
| InputRegister | 0, 65535 | u16 边界值 |

### 8.4 ModbusError 测试数据

| 异常码 | 名称 | 说明 |
|--------|------|------|
| 0x01 | IllegalFunction | 非法功能码 |
| 0x02 | IllegalDataAddress | 非法数据地址 |
| 0x03 | IllegalDataValue | 非法数据值 |
| 0x04 | ServerDeviceFailure | 从站设备故障 |
| 0x05 | Acknowledge | 确认 |
| 0x06 | ServerBusy | 服务器忙 |
| 0x08 | MemoryParityError | 内存奇偶校验错误 |

---

## 9. 测试环境

### 9.1 开发环境

| 项目 | 要求 |
|------|------|
| Rust 版本 | >= 1.75 |
| 测试框架 | 内置 test + tokio::test |
| 依赖 | 无外部依赖（可使用 mockall 进行 mock） |

### 9.2 测试命令

```bash
# 运行所有测试
cargo test --package kayak-backend --lib modbus

# 运行特定类型测试
cargo test --package kayak-backend --lib modbus::types
cargo test --package kayak-backend --lib modbus::error

# 运行序列化测试
cargo test --package kayak-backend --lib modbus::serialization

# 生成测试覆盖率报告
cargo tarpaulin --out Html --package kayak-backend
```

---

## 10. 风险与假设

### 10.1 测试假设

| 假设ID | 描述 |
|--------|------|
| ASM-001 | Modbus 类型将在 `drivers/modbus/types.rs` 中定义 |
| ASM-002 | ModbusError 将在 `drivers/modbus/error.rs` 中定义 |
| ASM-003 | MBAP/PDU 解析将在 `drivers/modbus/frame.rs` 中定义 |
| ASM-004 | 所有类型实现 serde Serialize/Deserialize |
| ASM-005 | ModbusError 实现 Into<DriverError> 转换 |

### 10.2 测试风险

| 风险ID | 风险描述 | 缓解措施 |
|--------|---------|---------|
| RSK-001 | 类型定义与测试假设不一致 | 先获取详细设计文档 |
| RSK-002 | 序列化格式与预期不同 | 验证 serde 属性配置 |
| RSK-003 | MBAP/PDU 格式实现不完整 | 先设计后实现 |

### 10.3 测试阻塞项

| 阻塞项 | 依赖 | 状态 |
|--------|------|------|
| 详细设计文档 | R1-S1-002-B | 待开发 |
| 类型实现 | R1-S1-002-C | 待开发 |

---

## 11. 测试用例汇总

| 测试ID | 测试名称 | 优先级 | 类型 | 状态 |
|--------|---------|--------|------|------|
| TC-001 | FunctionCode 有效功能码创建 | P0 | 单元测试 | 待执行 |
| TC-002 | FunctionCode 无效功能码拒绝 | P0 | 单元测试 | 待执行 |
| TC-003 | FunctionCode::from_u8 转换 | P1 | 单元测试 | 待执行 |
| TC-004 | FunctionCode 代码匹配性 | P1 | 单元测试 | 待执行 |
| TC-005 | ModbusAddress 有效地址范围 | P0 | 单元测试 | 待执行 |
| TC-006 | ModbusAddress 最小地址 | P1 | 单元测试 | 待执行 |
| TC-007 | ModbusAddress 最大地址 | P1 | 单元测试 | 待执行 |
| TC-008 | ModbusAddress 越界拒绝 | P0 | 单元测试 | 待执行 |
| TC-009 | ModbusAddress serde 序列化 | P1 | 单元测试 | 待执行 |
| TC-010 | ModbusValue Coil 类型创建 | P0 | 单元测试 | 待执行 |
| TC-011 | ModbusValue DiscreteInput 类型创建 | P0 | 单元测试 | 待执行 |
| TC-012 | ModbusValue HoldingRegister 类型创建 | P0 | 单元测试 | 待执行 |
| TC-013 | ModbusValue InputRegister 类型创建 | P0 | 单元测试 | 待执行 |
| TC-014 | ModbusValue 类型不匹配访问 | P1 | 单元测试 | 待执行 |
| TC-015 | ModbusValue 边界值测试 | P1 | 单元测试 | 待执行 |
| TC-016 | ModbusValue serde 序列化 | P1 | 单元测试 | 待执行 |
| TC-017 | RegisterType 所有变体 | P0 | 单元测试 | 待执行 |
| TC-018 | RegisterType 与 FunctionCode 关联 | P1 | 单元测试 | 待执行 |
| TC-019 | RegisterType serde 序列化 | P1 | 单元测试 | 待执行 |
| TC-020 | ModbusError 异常码映射 - IllegalFunction | P0 | 单元测试 | 待执行 |
| TC-021 | ModbusError 异常码映射 - IllegalDataAddress | P0 | 单元测试 | 待执行 |
| TC-022 | ModbusError 异常码映射 - IllegalDataValue | P0 | 单元测试 | 待执行 |
| TC-023 | ModbusError 异常码映射 - ServerDeviceFailure | P0 | 单元测试 | 待执行 |
| TC-024 | ModbusError Acknowledge 异常码 | P1 | 单元测试 | 待执行 |
| TC-025 | ModbusError ServerBusy 异常码 | P1 | 单元测试 | 待执行 |
| TC-026 | ModbusError 转换为 DriverError | P0 | 单元测试 | 待执行 |
| TC-026a | ModbusError Timeout 通信错误 | P0 | 单元测试 | 待执行 |
| TC-027 | ModbusError From u8 构造 | P1 | 单元测试 | 待执行 |
| TC-028 | ModbusError Invalid 异常码 | P1 | 单元测试 | 待执行 |
| TC-029 | MBAP 头部解析 - 有效帧 | P0 | 单元测试 | 待执行 |
| TC-030 | MBAP 头部构建 | P0 | 单元测试 | 待执行 |
| TC-031 | MBAP 头部解析 - 无效长度 | P1 | 单元测试 | 待执行 |
| TC-032 | MBAP 头部解析 - 数据太短 | P0 | 单元测试 | 待执行 |
| TC-033 | PDU 解析 - ReadHoldingRegisters 请求 | P0 | 单元测试 | 待执行 |
| TC-034 | PDU 构建 - ReadHoldingRegisters 请求 | P0 | 单元测试 | 待执行 |
| TC-035 | PDU 解析 - ReadCoils 请求 | P0 | 单元测试 | 待执行 |
| TC-036 | PDU 解析 - WriteSingleRegister 请求 | P0 | 单元测试 | 待执行 |
| TC-037 | PDU 解析 - 异常响应 | P0 | 单元测试 | 待执行 |
| TC-038 | PDU 构建 - WriteMultipleRegisters | P0 | 单元测试 | 待执行 |
| TC-039 | PDU 解析 - 数据不完整 | P1 | 单元测试 | 待执行 |
| TC-040 | PDU 与 MBAP 组装 | P0 | 单元测试 | 待执行 |
| TC-041 | PDU 解析 - ReadDiscreteInputs 请求 | P1 | 单元测试 | 待执行 |
| TC-042 | PDU 解析 - ReadInputRegisters 请求 | P1 | 单元测试 | 待执行 |
| TC-043 | PDU 解析 - WriteMultipleCoils 请求 | P1 | 单元测试 | 待执行 |
| TC-044 | PDU 构建 - WriteMultipleCoils | P1 | 单元测试 | 待执行 |

---

## 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2026-05-02 | sw-mike | 初始版本，包含 40 个测试用例 |
| 1.1 | 2026-05-02 | sw-mike | 修复 sw-tom 发现的问题：<br>- TC-002: 更正无效功能码列表，移除 0x07/0x08/0x11（为有效 Modbus 诊断功能码）<br>- TC-004: 增加验证 ReadHoldingRegisters 返回 u16 数组的步骤<br>- TC-026a: 新增 ModbusError::Timeout 专用测试用例<br>- TC-038: 添加 WriteMultipleRegisters 预期字节序列<br>- TC-039: 指定预期错误类型 ParseError::IncompleteData<br>- 新增 TC-041/042/043/044: 添加 ReadDiscreteInputs/ReadInputRegisters/WriteMultipleCoils PDU 解析测试 |

---

*本文档由 Kayak 项目测试团队维护。如有问题，请联系测试工程师。*