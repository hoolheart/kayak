# S1-016: 设备与测点数据模型 - 测试用例文档

**任务ID**: S1-016  
**任务名称**: 设备与测点数据模型 (Device and Point Data Model)  
**文档版本**: 1.0  
**创建日期**: 2026-03-22  
**测试类型**: 单元测试 (Unit Tests)

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S1-016 任务的所有功能测试，包括：

1. **Device 数据模型测试**
   - 设备创建 (带/不带父设备)
   - 设备父子关系支持 (树形结构)
   - DeviceStatus 枚举
   - ProtocolType 枚举
   - Device → DeviceResponse DTO转换

2. **Point 数据模型测试**
   - 测点创建与设备关联
   - DataType 枚举 (Number/Integer/String/Boolean)
   - AccessType 枚举 (RO/WO/RW)
   - PointStatus 枚举
   - Point → PointResponse DTO转换

3. **边界情况测试**
   - None/null 字段处理
   - 枚举序列化/反序列化

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 支持设备父子关系 | TC-S1-016-01 ~ TC-S1-016-05 | Unit Test |
| 2. 测点支持RO/WO/RW访问类型 | TC-S1-016-10 ~ TC-S1-016-13 | Unit Test |
| 3. 支持多种数据类型(Number/Integer/String/Boolean) | TC-S1-016-14 ~ TC-S1-016-18 | Unit Test |
| 4. DTO转换正确性 | TC-S1-016-20 ~ TC-S1-016-23 | Unit Test |

### 1.3 测试环境要求

| 环境项 | 说明 |
|--------|------|
| **Rust版本** | 1.75+ |
| **测试框架** | Rust built-in `#[cfg(test)]` + `#[test]` |
| **依赖库** | chrono, serde, serde_json, uuid |
| **数据库** | 无 (纯数据模型测试) |

### 1.4 测试用例统计

| 类别 | 用例数量 | 优先级分布 |
|------|---------|-----------|
| 设备数据模型测试 | 10 | P0: 8, P1: 2 |
| 测点数据模型测试 | 12 | P0: 10, P1: 2 |
| DTO转换测试 | 6 | P0: 6 |
| 枚举序列化/反序列化测试 | 5 | P0: 4, P1: 1 |
| 边界值测试 | 3 | P0: 1, P1: 2 |
| **总计** | **31** | P0: 24, P1: 7 |

---

## 2. Device 数据模型测试 (TC-S1-016-01 ~ TC-S1-016-10)

### 2.1 设备创建测试

#### TC-S1-016-01: 创建设备（无父设备）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-01 |
| **测试名称** | 创建设备（无父设备）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | `Device::new(workbench_id, name, protocol_type, parent_id=None)` |
| **预期结果** | 1. `id` 为新生成的 UUID<br>2. `parent_id` 为 `None`<br>3. `status` 为 `DeviceStatus::Offline`<br>4. `created_at` 和 `updated_at` 为当前时间 |
| **测试代码** | ```rust<br>let device = Device::new(<br>    workbench_id,<br>    "Test Device".to_string(),<br>    ProtocolType::Virtual,<br>    None,<br>);<br>assert!(device.parent_id.is_none());<br>assert_eq!(device.status, DeviceStatus::Offline);<br>assert_eq!(device.name, "Test Device");<br>``` |

---

#### TC-S1-016-02: 创建设备（带父设备）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-02 |
| **测试名称** | 创建设备（带父设备）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 存在父设备 UUID |
| **输入** | `Device::new(workbench_id, name, protocol_type, parent_id=Some(parent_uuid))` |
| **预期结果** | 1. `id` 为新生成的 UUID<br>2. `parent_id` 为 `Some(parent_uuid)`<br>3. 其他字段正确设置 |
| **测试代码** | ```rust<br>let parent_id = Uuid::new_v4();<br>let device = Device::new(<br>    workbench_id,<br>    "Child Device".to_string(),<br>    ProtocolType::ModbusTcp,<br>    Some(parent_id),<br>);<br>assert_eq!(device.parent_id, Some(parent_id));<br>assert_ne!(device.id, parent_id);<br>``` |

---

#### TC-S1-016-03: 创建设备（验证UUID唯一性）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-03 |
| **测试名称** | 创建设备（验证UUID唯一性）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 连续创建多个设备 |
| **预期结果** | 每个设备的 `id` 都是唯一的 UUID |
| **测试代码** | ```rust<br>let device1 = Device::new(workbench_id, "Device 1".to_string(), ProtocolType::Virtual, None);<br>let device2 = Device::new(workbench_id, "Device 2".to_string(), ProtocolType::Virtual, None);<br>assert_ne!(device1.id, device2.id);<br>``` |

---

#### TC-S1-016-04: 创建设备（验证时间戳自动设置）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-04 |
| **测试名称** | 创建设备（验证时间戳自动设置）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | `Device::new()` |
| **预期结果** | 1. `created_at` 和 `updated_at` 已设置<br>2. 两者时间差小于1秒 |
| **测试代码** | ```rust<br>let before = Utc::now();<br>let device = Device::new(workbench_id, "Test".to_string(), ProtocolType::Virtual, None);<br>let after = Utc::now();<br>assert!(device.created_at >= before && device.created_at <= after);<br>assert!(device.updated_at >= before && device.updated_at <= after);<br>``` |

---

### 2.2 设备父子关系测试

#### TC-S1-016-05: 设备树形结构（三层）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-05 |
| **测试名称** | 设备树形结构（三层）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建 grandparent → parent → child 设备链 |
| **预期结果** | 1. grandparent 的 `parent_id` 为 `None`<br>2. parent 的 `parent_id` 为 `Some(grandparent.id)`<br>3. child 的 `parent_id` 为 `Some(parent.id)` |
| **测试代码** | ```rust<br>let grandparent = Device::new(workbench_id, "Grandparent".to_string(), ProtocolType::Virtual, None);<br>let parent = Device::new(workbench_id, "Parent".to_string(), ProtocolType::Virtual, Some(grandparent.id));<br>let child = Device::new(workbench_id, "Child".to_string(), ProtocolType::Virtual, Some(parent.id));<br>assert!(grandparent.parent_id.is_none());<br>assert_eq!(parent.parent_id, Some(grandparent.id));<br>assert_eq!(child.parent_id, Some(parent.id));<br>``` |

---

#### TC-S1-016-06: 设备兄弟关系测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-06 |
| **测试名称** | 设备兄弟关系测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 存在父设备 |
| **输入** | 创建两个子设备，拥有相同父设备 |
| **预期结果** | 1. 两个子设备的 `parent_id` 相同<br>2. 两个子设备的 `id` 不同 |
| **测试代码** | ```rust<br>let parent = Device::new(workbench_id, "Parent".to_string(), ProtocolType::Virtual, None);<br>let child1 = Device::new(workbench_id, "Child 1".to_string(), ProtocolType::Virtual, Some(parent.id));<br>let child2 = Device::new(workbench_id, "Child 2".to_string(), ProtocolType::Virtual, Some(parent.id));<br>assert_eq!(child1.parent_id, child2.parent_id);<br>assert_ne!(child1.id, child2.id);<br>``` |

---

#### TC-S1-016-07: 设备根节点（无父设备）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-07 |
| **测试名称** | 设备根节点（无父设备）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建顶级设备（无父设备） |
| **预期结果** | `parent_id` 为 `None` |
| **测试代码** | ```rust<br>let root = Device::new(workbench_id, "Root Device".to_string(), ProtocolType::Virtual, None);<br>assert!(root.parent_id.is_none());<br>``` |

---

### 2.3 设备枚举类型测试

#### TC-S1-016-08: ProtocolType 枚举所有变体测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-08 |
| **测试名称** | ProtocolType 枚举所有变体测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建使用每种 ProtocolType 的设备 |
| **预期结果** | 所有 ProtocolType 变体都可正常使用 |
| **测试代码** | ```rust<br>for protocol in &[<br>    ProtocolType::Virtual,<br>    ProtocolType::ModbusTcp,<br>    ProtocolType::ModbusRtu,<br>    ProtocolType::Can,<br>    ProtocolType::Visa,<br>    ProtocolType::Mqtt,<br>] {<br>    let device = Device::new(workbench_id, format!("{:?}", protocol), *protocol, None);<br>    assert_eq!(device.protocol_type, *protocol);<br>}<br>``` |

---

#### TC-S1-016-09: DeviceStatus 枚举所有变体测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-09 |
| **测试名称** | DeviceStatus 枚举所有变体测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 手动设置设备的 status 为每种状态 |
| **预期结果** | 所有 DeviceStatus 变体都可正常使用 |
| **测试代码** | ```rust<br>let mut device = Device::new(workbench_id, "Test".to_string(), ProtocolType::Virtual, None);<br>for status in &[DeviceStatus::Offline, DeviceStatus::Online, DeviceStatus::Error] {<br>    device.status = *status;<br>    assert_eq!(device.status, *status);<br>}<br>``` |

---

#### TC-S1-016-10: 设备可选字段（None）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-10 |
| **测试名称** | 设备可选字段（None）测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 无 |
| **输入** | 创建设备后检查可选字段 |
| **预期结果** | 1. `protocol_params` 为 `None`<br>2. `manufacturer` 为 `None`<br>3. `model` 为 `None`<br>4. `sn` 为 `None` |
| **测试代码** | ```rust<br>let device = Device::new(workbench_id, "Test".to_string(), ProtocolType::Virtual, None);<br>assert!(device.protocol_params.is_none());<br>assert!(device.manufacturer.is_none());<br>assert!(device.model.is_none());<br>assert!(device.sn.is_none());<br>``` |

---

## 3. Point 数据模型测试 (TC-S1-016-11 ~ TC-S1-016-22)

### 3.1 测点创建测试

#### TC-S1-016-11: 创建测点（基本字段）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-11 |
| **测试名称** | 创建测点（基本字段）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 存在设备 UUID |
| **输入** | `Point::new(device_id, name, data_type, access_type)` |
| **预期结果** | 1. `id` 为新生成的 UUID<br>2. `device_id` 为传入的 device_id<br>3. `status` 为 `PointStatus::Active`<br>4. 其他可选字段为 `None` |
| **测试代码** | ```rust<br>let device_id = Uuid::new_v4();<br>let point = Point::new(<br>    device_id,<br>    "Temperature".to_string(),<br>    DataType::Number,<br>    AccessType::Ro,<br>);<br>assert_eq!(point.device_id, device_id);<br>assert_eq!(point.name, "Temperature");<br>assert_eq!(point.status, PointStatus::Active);<br>assert!(point.unit.is_none());<br>``` |

---

#### TC-S1-016-12: 创建多个测点（验证UUID唯一性）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-12 |
| **测试名称** | 创建多个测点（验证UUID唯一性）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 连续创建多个测点 |
| **预期结果** | 每个测点的 `id` 都是唯一的 UUID |
| **测试代码** | ```rust<br>let device_id = Uuid::new_v4();<br>let point1 = Point::new(device_id, "Point 1".to_string(), DataType::Number, AccessType::Ro);<br>let point2 = Point::new(device_id, "Point 2".to_string(), DataType::Integer, AccessType::Rw);<br>assert_ne!(point1.id, point2.id);<br>``` |

---

### 3.2 测点访问类型测试 (RO/WO/RW)

#### TC-S1-016-13: AccessType::Ro（只读）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-13 |
| **测试名称** | AccessType::Ro（只读）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建只读类型测点 |
| **预期结果** | `access_type` 为 `AccessType::Ro` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "Sensor Read".to_string(),<br>    DataType::Number,<br>    AccessType::Ro,<br>);<br>assert_eq!(point.access_type, AccessType::Ro);<br>``` |

---

#### TC-S1-016-14: AccessType::Wo（只写）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-14 |
| **测试名称** | AccessType::Wo（只写）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建只写类型测点 |
| **预期结果** | `access_type` 为 `AccessType::Wo` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "Control Write".to_string(),<br>    DataType::Boolean,<br>    AccessType::Wo,<br>);<br>assert_eq!(point.access_type, AccessType::Wo);<br>``` |

---

#### TC-S1-016-15: AccessType::Rw（读写）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-15 |
| **测试名称** | AccessType::Rw（读写）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建读写类型测点 |
| **预期结果** | `access_type` 为 `AccessType::Rw` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "Setting RW".to_string(),<br>    DataType::Integer,<br>    AccessType::Rw,<br>);<br>assert_eq!(point.access_type, AccessType::Rw);<br>``` |

---

### 3.3 测点数据类型测试

#### TC-S1-016-16: DataType::Number（浮点数）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-16 |
| **测试名称** | DataType::Number（浮点数）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建数值类型测点 |
| **预期结果** | `data_type` 为 `DataType::Number` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "Temperature".to_string(),<br>    DataType::Number,<br>    AccessType::Ro,<br>);<br>assert_eq!(point.data_type, DataType::Number);<br>``` |

---

#### TC-S1-016-17: DataType::Integer（整数）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-17 |
| **测试名称** | DataType::Integer（整数）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建整数类型测点 |
| **预期结果** | `data_type` 为 `DataType::Integer` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "Counter".to_string(),<br>    DataType::Integer,<br>    AccessType::Rw,<br>);<br>assert_eq!(point.data_type, DataType::Integer);<br>``` |

---

#### TC-S1-016-18: DataType::String（字符串）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-18 |
| **测试名称** | DataType::String（字符串）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建字符串类型测点 |
| **预期结果** | `data_type` 为 `DataType::String` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "Status Text".to_string(),<br>    DataType::String,<br>    AccessType::Ro,<br>);<br>assert_eq!(point.data_type, DataType::String);<br>``` |

---

#### TC-S1-016-19: DataType::Boolean（布尔值）测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-19 |
| **测试名称** | DataType::Boolean（布尔值）测点测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 创建布尔类型测点 |
| **预期结果** | `data_type` 为 `DataType::Boolean` |
| **测试代码** | ```rust<br>let point = Point::new(<br>    device_id,<br>    "On/Off".to_string(),<br>    DataType::Boolean,<br>    AccessType::Wo,<br>);<br>assert_eq!(point.data_type, DataType::Boolean);<br>``` |

---

### 3.4 测点状态测试

#### TC-S1-016-20: PointStatus 枚举所有变体测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-20 |
| **测试名称** | PointStatus 枚举所有变体测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 手动设置测点的 status |
| **预期结果** | 所有 PointStatus 变体都可正常使用 |
| **测试代码** | ```rust<br>let mut point = Point::new(device_id, "Test".to_string(), DataType::Number, AccessType::Ro);<br>for status in &[PointStatus::Active, PointStatus::Disabled] {<br>    point.status = *status;<br>    assert_eq!(point.status, *status);<br>}<br>``` |

---

### 3.5 测点边界值测试

#### TC-S1-016-21: 测点带数值范围测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-21 |
| **测试名称** | 测点带数值范围测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 无 |
| **输入** | 创建带 min_value 和 max_value 的测点 |
| **预期结果** | `min_value` 和 `max_value` 正确设置 |
| **测试代码** | ```rust<br>let mut point = Point::new(device_id, "Bounded".to_string(), DataType::Number, AccessType::Rw);<br>point.min_value = Some(0.0);<br>point.max_value = Some(100.0);<br>assert_eq!(point.min_value, Some(0.0));<br>assert_eq!(point.max_value, Some(100.0));<br>``` |

---

#### TC-S1-016-22: 测点带单位测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-22 |
| **测试名称** | 测点带单位测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 无 |
| **输入** | 创建带单位的测点 |
| **预期结果** | `unit` 正确设置 |
| **测试代码** | ```rust<br>let mut point = Point::new(device_id, "Temperature".to_string(), DataType::Number, AccessType::Ro);<br>point.unit = Some("°C".to_string());<br>assert_eq!(point.unit, Some("°C".to_string()));\n``` |

---

## 4. DTO 转换测试 (TC-S1-016-23 ~ TC-S1-016-26)

### 4.1 Device → DeviceResponse 转换测试

#### TC-S1-016-23: Device 转 DeviceResponse 测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-23 |
| **测试名称** | Device 转 DeviceResponse 测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | `DeviceResponse::from(device)` |
| **预期结果** | 1. 所有字段正确映射<br>2. `id`, `workbench_id`, `parent_id`, `name` 等完全一致<br>3. `created_at` 和 `updated_at` 正确映射 |
| **测试代码** | ```rust
let parent_id = Uuid::new_v4();
let device = Device::new(workbench_id, "Test Device".to_string(), ProtocolType::ModbusTcp, Some(parent_id));
let response = DeviceResponse::from(device.clone());
assert_eq!(response.id, device.id);
assert_eq!(response.workbench_id, device.workbench_id);
assert_eq!(response.parent_id, device.parent_id);
assert_eq!(response.name, device.name);
assert_eq!(response.protocol_type, device.protocol_type);
assert_eq!(response.status, device.status);
assert_eq!(response.created_at, device.created_at);
assert_eq!(response.updated_at, device.updated_at);
``` |

---

### 4.2 Point → PointResponse 转换测试

#### TC-S1-016-25: Point 转 PointResponse 测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-25 |
| **测试名称** | Point 转 PointResponse 测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | `PointResponse::from(point)` |
| **预期结果** | 1. 所有字段正确映射<br>2. `id`, `device_id`, `name`, `data_type`, `access_type` 等完全一致 |
| **测试代码** | ```rust<br>let point = Point::new(device_id, "Temperature".to_string(), DataType::Number, AccessType::Ro);<br>let response = PointResponse::from(point.clone());<br>assert_eq!(response.id, point.id);<br>assert_eq!(response.device_id, point.device_id);<br>assert_eq!(response.name, point.name);<br>assert_eq!(response.data_type, point.data_type);<br>assert_eq!(response.access_type, point.access_type);<br>assert_eq!(response.status, point.status);\n``` |

---

#### TC-S1-016-26: PointResponse 序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-26 |
| **测试名称** | PointResponse 序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 将 PointResponse 序列化为 JSON |
| **预期结果** | JSON 包含所有必要字段，格式正确 |
| **测试代码** | ```rust<br>let point = Point::new(device_id, "Test Point".to_string(), DataType::Integer, AccessType::Rw);<br>let response = PointResponse::from(point);<br>let json = serde_json::to_string(&response).unwrap();<br>assert!(json.contains("\"id\""));\nassert!(json.contains("\"name\""));\nassert!(json.contains("\"data_type\""));\nassert!(json.contains("\"access_type\""));\n``` |

---

## 5. 枚举序列化/反序列化测试 (TC-S1-016-27 ~ TC-S1-016-30)

#### TC-S1-016-27: ProtocolType JSON 序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-27 |
| **测试名称** | ProtocolType JSON 序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 序列化 ProtocolType 为 JSON |
| **预期结果** | 使用 snake_case 格式 (如 `"virtual"`, `"modbus_tcp"`) |
| **测试代码** | ```rust<br>let json = serde_json::to_string(&ProtocolType::Virtual).unwrap();<br>assert_eq!(json, "\"virtual\"");\nlet json = serde_json::to_string(&ProtocolType::ModbusTcp).unwrap();<br>assert_eq!(json, "\"modbus_tcp\"");\n``` |

---

#### TC-S1-016-28: DataType JSON 序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-28 |
| **测试名称** | DataType JSON 序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 序列化 DataType 为 JSON |
| **预期结果** | 使用 snake_case 格式 (如 `"number"`, `"integer"`, `"string"`, `"boolean"`) |
| **测试代码** | ```rust<br>assert_eq!(serde_json::to_string(&DataType::Number).unwrap(), "\"number\"");\nassert_eq!(serde_json::to_string(&DataType::Integer).unwrap(), "\"integer\"");\nassert_eq!(serde_json::to_string(&DataType::String).unwrap(), "\"string\"");\nassert_eq!(serde_json::to_string(&DataType::Boolean).unwrap(), "\"boolean\"");\n``` |

---

#### TC-S1-016-29: AccessType JSON 序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-29 |
| **测试名称** | AccessType JSON 序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 序列化 AccessType 为 JSON |
| **预期结果** | 使用 snake_case 格式 (如 `"ro"`, `"wo"`, `"rw"`) |
| **测试代码** | ```rust<br>assert_eq!(serde_json::to_string(&AccessType::Ro).unwrap(), "\"ro\"");\nassert_eq!(serde_json::to_string(&AccessType::Wo).unwrap(), "\"wo\"");\nassert_eq!(serde_json::to_string(&AccessType::Rw).unwrap(), "\"rw\"");\n``` |

---

#### TC-S1-016-30: JSON 反序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-30 |
| **测试名称** | JSON 反序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 从 JSON 反序列化枚举 |
| **预期结果** | 反序列化成功，值正确 |
| **测试代码** | ```rust<br>let protocol: ProtocolType = serde_json::from_str("\"virtual\"").unwrap();<br>assert_eq!(protocol, ProtocolType::Virtual);\nlet data_type: DataType = serde_json::from_str("\"integer\"").unwrap();<br>assert_eq!(data_type, DataType::Integer);\nlet access: AccessType = serde_json::from_str("\"rw\"").unwrap();\nassert_eq!(access, AccessType::Rw);\n``` |

---

## 6. 新增测试用例 (TC-S1-016-31 ~ TC-S1-016-34)

### 6.1 DTO 反序列化测试

#### TC-S1-016-31: DeviceResponse JSON 反序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-31 |
| **测试名称** | DeviceResponse JSON 反序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 从 JSON 字符串反序列化为 DeviceResponse |
| **预期结果** | 反序列化成功，所有字段值正确 |
| **测试代码** | ```rust
let json = r#"{"id":"...","workbench_id":"...","name":"Test","protocol_type":"virtual","status":"offline"}"#;
let response: DeviceResponse = serde_json::from_str(json).unwrap();
assert_eq!(response.name, "Test");
assert_eq!(response.protocol_type, ProtocolType::Virtual);
```

---

#### TC-S1-016-32: PointResponse JSON 反序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-32 |
| **测试名称** | PointResponse JSON 反序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 从 JSON 字符串反序列化为 PointResponse |
| **预期结果** | 反序列化成功，所有字段值正确 |
| **测试代码** | ```rust
let json = r#"{"id":"...","device_id":"...","name":"Temp","data_type":"number","access_type":"ro"}"#;
let response: PointResponse = serde_json::from_str(json).unwrap();
assert_eq!(response.name, "Temp");
assert_eq!(response.data_type, DataType::Number);
```

---

### 6.2 设备可选字段测试

#### TC-S1-016-33: 设备可选字段（带值）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-33 |
| **测试名称** | 设备可选字段（带值）测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 无 |
| **输入** | 设置设备的所有可选字段 |
| **预期结果** | 1. `protocol_params` 为 `Some(...)`<br>2. `manufacturer` 为 `Some(...)`<br>3. `model` 为 `Some(...)`<br>4. `sn` 为 `Some(...)` |
| **测试代码** | ```rust
let mut device = Device::new(workbench_id, "Test".to_string(), ProtocolType::ModbusTcp, None);
device.manufacturer = Some("Acme Corp".to_string());
device.model = Some("Model-X".to_string());
device.sn = Some("SN12345".to_string());
device.protocol_params = Some(json!({"host": "192.168.1.1", "port": 502}));
assert_eq!(device.manufacturer, Some("Acme Corp".to_string()));
assert_eq!(device.model, Some("Model-X".to_string()));
assert_eq!(device.sn, Some("SN12345".to_string()));
assert!(device.protocol_params.is_some());
```

---

### 6.3 状态枚举反序列化测试

#### TC-S1-016-34: DeviceStatus/PointStatus JSON 反序列化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-34 |
| **测试名称** | DeviceStatus/PointStatus JSON 反序列化测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 从 JSON 反序列化 DeviceStatus 和 PointStatus |
| **预期结果** | 反序列化成功，枚举值正确 |
| **测试代码** | ```rust
let status1: DeviceStatus = serde_json::from_str("\"online\"").unwrap();
assert_eq!(status1, DeviceStatus::Online);
let status2: DeviceStatus = serde_json::from_str("\"error\"").unwrap();
assert_eq!(status2, DeviceStatus::Error);
let point_status: PointStatus = serde_json::from_str("\"disabled\"").unwrap();
assert_eq!(point_status, PointStatus::Disabled);
```

---

### 6.4 边界值测试

#### TC-S1-016-35: 测点数值范围边界（min > max）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-016-35 |
| **测试名称** | 测点数值范围边界（min > max）测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 无 |
| **输入** | 设置 min_value > max_value |
| **预期结果** | 1. min_value 和 max_value 都被设置<br>2. 业务层应拒绝或处理这种非法配置 |
| **测试代码** | ```rust
let mut point = Point::new(device_id, "Test".to_string(), DataType::Number, AccessType::Rw);
point.min_value = Some(100.0);
point.max_value = Some(0.0);
// 验证值被设置（业务验证应在服务层进行）
assert_eq!(point.min_value, Some(100.0));
assert_eq!(point.max_value, Some(0.0));
```

---

## 7. 测试覆盖矩阵

| 验收标准 | TC覆盖 | 测试类型 |
|---------|--------|---------|
| 1. 支持设备父子关系 | TC-S1-016-01 ~ TC-S1-016-07 | Unit Test |
| 2. 测点支持RO/WO/RW访问类型 | TC-S1-016-13 ~ TC-S1-016-15 | Unit Test |
| 3. 支持多种数据类型(Number/Integer/String/Boolean) | TC-S1-016-16 ~ TC-S1-016-19 | Unit Test |
| 4. DTO转换正确性 | TC-S1-016-23 ~ TC-S1-016-26, TC-S1-016-31, TC-S1-016-32 | Unit Test |
| 5. 枚举序列化/反序列化 | TC-S1-016-27 ~ TC-S1-016-30, TC-S1-016-34 | Unit Test |
| 6. 可选字段处理 | TC-S1-016-10, TC-S1-016-33 | Unit Test |
| 7. 边界值处理 | TC-S1-016-21, TC-S1-016-35 | Unit Test |

---

## 7. 自动化测试代码示例

### 7.1 设备模型测试文件

```rust
// kayak-backend/src/models/entities/device_test.rs

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use uuid::Uuid;

    // TC-S1-016-01: 创建设备（无父设备）测试
    #[test]
    fn test_create_device_without_parent() {
        let workbench_id = Uuid::new_v4();
        let device = Device::new(
            workbench_id,
            "Test Device".to_string(),
            ProtocolType::Virtual,
            None,
        );
        
        assert!(device.parent_id.is_none());
        assert_eq!(device.status, DeviceStatus::Offline);
        assert_eq!(device.name, "Test Device");
        assert_eq!(device.protocol_type, ProtocolType::Virtual);
    }

    // TC-S1-016-02: 创建设备（带父设备）测试
    #[test]
    fn test_create_device_with_parent() {
        let workbench_id = Uuid::new_v4();
        let parent_id = Uuid::new_v4();
        let device = Device::new(
            workbench_id,
            "Child Device".to_string(),
            ProtocolType::ModbusTcp,
            Some(parent_id),
        );
        
        assert_eq!(device.parent_id, Some(parent_id));
        assert_ne!(device.id, parent_id);
    }

    // TC-S1-016-03: 验证UUID唯一性
    #[test]
    fn test_device_uuid_uniqueness() {
        let workbench_id = Uuid::new_v4();
        let device1 = Device::new(workbench_id, "Device 1".to_string(), ProtocolType::Virtual, None);
        let device2 = Device::new(workbench_id, "Device 2".to_string(), ProtocolType::Virtual, None);
        assert_ne!(device1.id, device2.id);
    }

    // TC-S1-016-05: 设备树形结构（三层）测试
    #[test]
    fn test_device_tree_structure() {
        let workbench_id = Uuid::new_v4();
        let grandparent = Device::new(workbench_id, "Grandparent".to_string(), ProtocolType::Virtual, None);
        let parent = Device::new(workbench_id, "Parent".to_string(), ProtocolType::Virtual, Some(grandparent.id));
        let child = Device::new(workbench_id, "Child".to_string(), ProtocolType::Virtual, Some(parent.id));
        
        assert!(grandparent.parent_id.is_none());
        assert_eq!(parent.parent_id, Some(grandparent.id));
        assert_eq!(child.parent_id, Some(parent.id));
    }

    // TC-S1-016-08: ProtocolType 枚举所有变体测试
    #[test]
    fn test_protocol_type_variants() {
        let workbench_id = Uuid::new_v4();
        for protocol in &[
            ProtocolType::Virtual,
            ProtocolType::ModbusTcp,
            ProtocolType::ModbusRtu,
            ProtocolType::Can,
            ProtocolType::Visa,
            ProtocolType::Mqtt,
        ] {
            let device = Device::new(workbench_id, format!("{:?}", protocol), *protocol, None);
            assert_eq!(device.protocol_type, *protocol);
        }
    }

    // TC-S1-016-23: Device 转 DeviceResponse 测试
    #[test]
    fn test_device_to_response() {
        let workbench_id = Uuid::new_v4();
        let device = Device::new(workbench_id, "Test Device".to_string(), ProtocolType::Virtual, None);
        let response = DeviceResponse::from(device.clone());
        
        assert_eq!(response.id, device.id);
        assert_eq!(response.workbench_id, device.workbench_id);
        assert_eq!(response.name, device.name);
        assert_eq!(response.protocol_type, device.protocol_type);
    }
}
```

### 7.2 测点模型测试文件

```rust
// kayak-backend/src/models/entities/point_test.rs

#[cfg(test)]
mod tests {
    use super::*;

    // TC-S1-016-11: 创建测点（基本字段）测试
    #[test]
    fn test_create_point_basic() {
        let device_id = Uuid::new_v4();
        let point = Point::new(
            device_id,
            "Temperature".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        
        assert_eq!(point.device_id, device_id);
        assert_eq!(point.name, "Temperature");
        assert_eq!(point.data_type, DataType::Number);
        assert_eq!(point.access_type, AccessType::Ro);
        assert_eq!(point.status, PointStatus::Active);
    }

    // TC-S1-016-13: AccessType::Ro 测试
    #[test]
    fn test_access_type_ro() {
        let point = Point::new(
            Uuid::new_v4(),
            "Sensor".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        assert_eq!(point.access_type, AccessType::Ro);
    }

    // TC-S1-016-14: AccessType::Wo 测试
    #[test]
    fn test_access_type_wo() {
        let point = Point::new(
            Uuid::new_v4(),
            "Control".to_string(),
            DataType::Boolean,
            AccessType::Wo,
        );
        assert_eq!(point.access_type, AccessType::Wo);
    }

    // TC-S1-016-15: AccessType::Rw 测试
    #[test]
    fn test_access_type_rw() {
        let point = Point::new(
            Uuid::new_v4(),
            "Setting".to_string(),
            DataType::Integer,
            AccessType::Rw,
        );
        assert_eq!(point.access_type, AccessType::Rw);
    }

    // TC-S1-016-16 ~ TC-S1-016-19: 所有数据类型测试
    #[test]
    fn test_all_data_types() {
        let device_id = Uuid::new_v4();
        
        let point_number = Point::new(device_id, "Number".to_string(), DataType::Number, AccessType::Ro);
        assert_eq!(point_number.data_type, DataType::Number);
        
        let point_integer = Point::new(device_id, "Integer".to_string(), DataType::Integer, AccessType::Ro);
        assert_eq!(point_integer.data_type, DataType::Integer);
        
        let point_string = Point::new(device_id, "String".to_string(), DataType::String, AccessType::Ro);
        assert_eq!(point_string.data_type, DataType::String);
        
        let point_boolean = Point::new(device_id, "Boolean".to_string(), DataType::Boolean, AccessType::Ro);
        assert_eq!(point_boolean.data_type, DataType::Boolean);
    }

    // TC-S1-016-25: Point 转 PointResponse 测试
    #[test]
    fn test_point_to_response() {
        let device_id = Uuid::new_v4();
        let point = Point::new(device_id, "Temperature".to_string(), DataType::Number, AccessType::Ro);
        let response = PointResponse::from(point.clone());
        
        assert_eq!(response.id, point.id);
        assert_eq!(response.device_id, point.device_id);
        assert_eq!(response.name, point.name);
        assert_eq!(response.data_type, point.data_type);
        assert_eq!(response.access_type, point.access_type);
    }

    // TC-S1-016-28: DataType JSON 序列化测试
    #[test]
    fn test_data_type_serialization() {
        assert_eq!(serde_json::to_string(&DataType::Number).unwrap(), "\"number\"");
        assert_eq!(serde_json::to_string(&DataType::Integer).unwrap(), "\"integer\"");
        assert_eq!(serde_json::to_string(&DataType::String).unwrap(), "\"string\"");
        assert_eq!(serde_json::to_string(&DataType::Boolean).unwrap(), "\"boolean\"");
    }

    // TC-S1-016-29: AccessType JSON 序列化测试
    #[test]
    fn test_access_type_serialization() {
        assert_eq!(serde_json::to_string(&AccessType::Ro).unwrap(), "\"ro\"");
        assert_eq!(serde_json::to_string(&AccessType::Wo).unwrap(), "\"wo\"");
        assert_eq!(serde_json::to_string(&AccessType::Rw).unwrap(), "\"rw\"");
    }

    // TC-S1-016-30: JSON 反序列化测试
    #[test]
    fn test_json_deserialization() {
        let protocol: ProtocolType = serde_json::from_str("\"virtual\"").unwrap();
        assert_eq!(protocol, ProtocolType::Virtual);
        
        let data_type: DataType = serde_json::from_str("\"integer\"").unwrap();
        assert_eq!(data_type, DataType::Integer);
        
        let access: AccessType = serde_json::from_str("\"rw\"").unwrap();
        assert_eq!(access, AccessType::Rw);
    }
}
```

---

## 8. 备注

1. **测试范围说明**: 本测试用例专注于数据模型层测试，不涉及数据库持久化操作
2. **DTO转换**: Device → DeviceResponse 和 Point → PointResponse 的转换是核心测试点
3. **枚举测试**: 所有枚举类型的序列化/反序列化必须正确处理 snake_case 格式
4. **父子关系**: 设备嵌套深度没有限制，树形结构支持任意层级
5. **UUID生成**: 使用 `Uuid::new_v4()` 生成唯一标识符

---

**文档结束**
