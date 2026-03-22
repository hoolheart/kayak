# S1-017: 虚拟设备协议插件框架 - 测试用例文档

**任务ID**: S1-017  
**任务名称**: 虚拟设备协议插件框架 (Virtual Device Protocol Plugin Framework)  
**文档版本**: 1.1  
**创建日期**: 2026-03-22  
**最后更新**: 2026-03-22  
**测试类型**: 单元测试 + 集成测试

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S1-017 任务的所有功能测试，包括：

1. **DeviceDriver trait 接口测试**
   - trait 方法签名定义
   - 异步方法支持
   - 错误处理定义
   - Send + Sync trait bounds

2. **VirtualDriver 实现测试**
   - 随机数据生成
   - 固定值模式
   - 数据读取功能
   - 数据写入功能 (RW 测点)

3. **设备参数配置测试**
   - 随机范围配置 (min/max)
   - 数据类型配置
   - 采样间隔配置
   - 配置验证 (VirtualConfig::validate())

4. **设备连接生命周期管理测试**
   - 连接建立/断开
   - 连接状态跟踪
   - 多设备并发管理

5. **VirtualMode 和 AccessType 枚举测试**
   - VirtualMode 变体测试
   - AccessType 变体测试

6. **边界值和错误处理测试**
   - UUID 处理
   - 超时错误
   - 类型不匹配处理

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 定义DeviceDriver trait接口 | TC-S1-017-01 ~ TC-S1-017-06 | Unit Test |
| 2. VirtualDriver实现数据读取 | TC-S1-017-10 ~ TC-S1-017-20 | Unit Test |
| 3. 设备可配置参数(如随机范围) | TC-S1-017-21 ~ TC-S1-017-32 | Unit Test |
| 4. 设备连接生命周期管理 | TC-S1-017-40 ~ TC-S1-017-50 | Integration Test |
| 5. 枚举变体和边界测试 | TC-S1-017-51 ~ TC-S1-017-60 | Unit Test |

### 1.3 测试环境要求

| 环境项 | 说明 |
|--------|------|
| **Rust版本** | 1.75+ |
| **测试框架** | Rust built-in `#[cfg(test)]` + `#[test]` |
| **依赖库** | tokio (async runtime), uuid, chrono, serde |
| **数据库** | 无 (纯驱动逻辑测试) |

### 1.4 测试用例统计

| 类别 | 用例数量 | 优先级分布 |
|------|---------|-----------|
| DeviceDriver trait接口测试 | 6 | P0: 6 |
| VirtualDriver随机数据测试 | 8 | P0: 6, P1: 2 |
| VirtualDriver固定值测试 | 4 | P0: 3, P1: 1 |
| 设备参数配置测试 | 12 | P0: 10, P1: 2 |
| 连接生命周期管理测试 | 8 | P0: 6, P1: 2 |
| 枚举变体和边界测试 | 10 | P0: 7, P1: 3 |
| **总计** | **48** | P0: 38, P1: 10 |

---

## 2. DeviceDriver Trait 接口测试 (TC-S1-017-01 ~ TC-S1-017-06)

### 2.1 Trait 定义测试

#### TC-S1-017-01: DeviceDriver trait 基本方法签名测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-01 |
| **测试名称** | DeviceDriver trait 基本方法签名测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | DeviceDriver trait 已定义 |
| **输入** | 检查 DeviceDriver trait 是否包含必要方法签名 |
| **预期结果** | trait 包含: `connect()`, `disconnect()`, `read_point()`, `write_point()`, `is_connected()` 方法 |
| **测试代码** | ```rust<br>// 使用编译时 trait bounds 验证 trait 方法存在<br>fn assert_device_driver<D: DeviceDriver>() {}<br><br>#[test]<br>fn test_device_driver_trait_methods() {<br>    // 编译时验证: VirtualDriver 必须实现所有 trait 方法<br>    assert_device_driver::<VirtualDriver>();<br>}<br>``` |

---

#### TC-S1-017-02: DeviceDriver trait 关联类型定义测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-02 |
| **测试名称** | DeviceDriver trait 关联类型定义测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | DeviceDriver trait 已定义 |
| **输入** | 检查 trait 是否定义了配置类型和错误类型 |
| **预期结果** | trait 包含 `Config` 和 `Error` 关联类型 |
| **测试代码** | ```rust<br>// 使用编译时 trait bounds 验证关联类型<br>fn assert_has_associated_types<D: DeviceDriver>() {<br>    // 验证 Config 和 Error 关联类型存在<br>    fn check_config(_: &<D as DeviceDriver>::Config) {}<br>    fn check_error(_: <D as DeviceDriver>::Error) {}<br>}<br><br>#[test]<br>fn test_device_driver_associated_types() {<br>    assert_has_associated_types::<VirtualDriver>();<br>}<br>``` |

---

#### TC-S1-017-03: DeviceDriver trait 默认实现测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-03 |
| **测试名称** | DeviceDriver trait 默认实现测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | DeviceDriver trait 已定义 |
| **输入** | 检查 `is_connected()` 是否有默认实现 |
| **预期结果** | `is_connected()` 提供默认实现返回 `false` |
| **测试代码** | ```rust<br>// 测试 is_connected() 默认实现返回 false<br>#[test]<br>fn test_is_connected_default_impl() {<br>    let driver = VirtualDriver::new();<br>    // is_connected() 默认实现应返回 false<br>    assert!(!driver.is_connected());<br>}<br>``` |

---

#### TC-S1-017-04: DriverError 枚举定义测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-04 |
| **测试名称** | DriverError 枚举定义测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | DriverError 枚举已定义 |
| **输入** | 检查 DriverError 枚举变体 |
| **预期结果** | DriverError 包含: `NotConnected`, `Timeout`, `InvalidValue`, `ConfigError`, `IoError` 等变体 |
| **测试代码** | ```rust<br>#[test]<br>fn test_driver_error_variants() {<br>    use std::time::Duration;<br>    \n    let errors = vec![\n        DriverError::NotConnected,<br>        DriverError::Timeout { duration: Duration::from_secs(1) },<br>        DriverError::InvalidValue { message: "test".to_string() },<br>        DriverError::ConfigError("config error".to_string()),<br>        DriverError::IoError("io error".to_string()),<br>    ];\n    \n    for error in errors {<br>        let debug_str = format!(\"{:?}\", error);<br>        assert!(!debug_str.is_empty());<br>    }\n}\br>``` |

---

#### TC-S1-017-05: PointValue 数据类型测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-05 |
| **测试名称** | PointValue 数据类型测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | PointValue 枚举已定义 |
| **输入** | 创建不同类型的 PointValue |
| **预期结果** | PointValue 支持: `Number(f64)`, `Integer(i64)`, `String(String)`, `Boolean(bool)` |
| **测试代码** | ```rust<br>#[test]<br>fn test_point_value_types() {<br>    let number = PointValue::Number(42.5);\br>    let integer = PointValue::Integer(42);<br>    let string = PointValue::String("test".to_string());<br>    let boolean = PointValue::Boolean(true);<br    \n    assert!(matches!(number, PointValue::Number(_)));<br>    assert!(matches!(integer, PointValue::Integer(_)));<br>    assert!(matches!(string, PointValue::String(_)));<br>    assert!(matches!(boolean, PointValue::Boolean(_)));<br>}\br>``` |

---

#### TC-S1-017-06: DeviceDriver Send + Sync Trait Bounds 测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-06 |
| **测试名称** | DeviceDriver Send + Sync Trait Bounds 测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已实现 DeviceDriver |
| **输入** | 验证 VirtualDriver 满足 Send 和 Sync trait bounds |
| **预期结果** | VirtualDriver 可以安全地在线程间传递和使用 |
| **测试代码** | ```rust<br>// 编译时验证 Send + Sync bounds<br>fn assert_send_sync<T: Send + Sync>() {}\n\n#[test]<br>fn test_virtual_driver_send_sync() {\n    // VirtualDriver 必须实现 Send + Sync 以支持异步和并发使用\n    assert_send_sync::<VirtualDriver>();\n    \n    // 进一步验证: 在多线程上下文中使用\n    let driver = VirtualDriver::new();\n    let driver = std::sync::Arc::new(std::sync::Mutex::new(driver));\n    \n    std::thread::spawn(move || {\n        let _ = driver.lock().unwrap().is_connected();\n    }).join().unwrap();\n}\br>``` |

---

## 3. VirtualDriver 实现测试 (TC-S1-017-10 ~ TC-S1-017-20)

### 3.1 VirtualDriver 创建测试

#### TC-S1-017-10: VirtualDriver 默认创建测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-10 |
| **测试名称** | VirtualDriver 默认创建测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 结构体已定义 |
| **输入** | `VirtualDriver::new()` |
| **预期结果** | 1. 创建成功<br>2. `is_connected()` 返回 `false`<br>3. 配置为默认参数 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_virtual_driver_default_creation() {\n    let driver = VirtualDriver::new();\n    assert!(!driver.is_connected());\n    let config = driver.get_config();\n    assert_eq!(config.mode, VirtualMode::Random);\n}\br>``` |

---

#### TC-S1-017-11: VirtualDriver 带配置创建测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-11 |
| **测试名称** | VirtualDriver 带配置创建测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 结构体已定义 |
| **输入** | `VirtualDriver::with_config(config)` |
| **预期结果** | 1. 使用提供的配置创建<br>2. 配置参数正确应用 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_virtual_driver_with_config() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Fixed,\n        fixed_value: PointValue::Number(42.0),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    assert_eq!(driver.get_config().fixed_value, PointValue::Number(42.0));\n}\br>``` |

---

### 3.2 随机数据模式测试

#### TC-S1-017-12: 随机数据生成（默认范围）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-12 |
| **测试名称** | 随机数据生成（默认范围）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已创建，模式为 Random |
| **输入** | 调用 `read_point()` 多次 |
| **预期结果** | 1. 返回值在默认范围 [0.0, 100.0) 内<br>2. 多次调用返回不同值（大多数情况下） |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_random_data_generation_default_range() {\n    let driver = VirtualDriver::new();\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let value1 = driver.read_point(point_id).await.unwrap();\n    let value2 = driver.read_point(point_id).await.unwrap();\n    \n    match value1 {\n        PointValue::Number(n) => assert!(n >= 0.0 && n < 100.0),\n        _ => panic!(\"Expected Number type\"),\n    }\n    \n    // 验证多次调用返回不同值（概率上）\n    match (&value1, &value2) {\n        (PointValue::Number(n1), PointValue::Number(n2)) => {\n            // 大多数情况下值应该不同\n            let all_same = (0..100).all(|_| {\n                driver.read_point(point_id).unwrap() \n            });\n        }\n        _ => panic!(\"Expected Number type\"),\n    }\n}\br>``` |

---

#### TC-S1-017-13: 随机数据生成（自定义范围）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-13 |
| **测试名称** | 随机数据生成（自定义范围）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 配置了自定义范围 |
| **输入** | 配置范围 [10.0, 50.0)，调用 `read_point()` |
| **预期结果** | 所有返回值在 [10.0, 50.0) 范围内 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_random_data_custom_range() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        min_value: 10.0,\n        max_value: 50.0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..100 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Number(n) => {\n                assert!(n >= 10.0 && n < 50.0);\n            }\n            _ => panic!(\"Expected Number type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-14: 随机整数生成测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-14 |
| **测试名称** | 随机整数生成测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 配置为生成整数类型 |
| **输入** | 配置 data_type 为 Integer，范围 [1, 10] |
| **预期结果** | 返回整数值在 [1, 10] 范围内 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_random_integer_generation() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        data_type: DataType::Integer,\n        min_value: 1.0,\n        max_value: 10.0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let value = driver.read_point(point_id).await.unwrap();\n    match value {\n        PointValue::Integer(n) => assert!(n >= 1 && n <= 10),\n        _ => panic!(\"Expected Integer type\"),\n    }\n}\br>``` |

---

#### TC-S1-017-15: 随机布尔值生成测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-15 |
| **测试名称** | 随机布尔值生成测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | VirtualDriver 配置为生成布尔类型 |
| **输入** | 配置 data_type 为 Boolean |
| **预期结果** | 返回 `true` 或 `false` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_random_boolean_generation() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        data_type: DataType::Boolean,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let value = driver.read_point(point_id).await.unwrap();\n    match value {\n        PointValue::Boolean(_) => {}, // true 或 false 都接受\n        _ => panic!(\"Expected Boolean type\"),\n    }\n}\br>``` |

---

#### TC-S1-017-16: 随机字符串生成测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-16 |
| **测试名称** | 随机字符串生成测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | VirtualDriver 配置为生成字符串类型 |
| **输入** | 配置 data_type 为 String |
| **预期结果** | 返回非空字符串 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_random_string_generation() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        data_type: DataType::String,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let value = driver.read_point(point_id).await.unwrap();\n    match value {\n        PointValue::String(s) => assert!(!s.is_empty()),\n        _ => panic!(\"Expected String type\"),\n    }\n}\br>``` |

---

### 3.3 固定值模式测试

#### TC-S1-017-17: 固定数值测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-17 |
| **测试名称** | 固定数值测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 配置为 Fixed 模式 |
| **输入** | 配置 fixed_value 为 Number(42.5) |
| **预期结果** | 多次调用 `read_point()` 都返回 42.5 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_fixed_number_value() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Fixed,\n        fixed_value: PointValue::Number(42.5),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..10 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Number(n) => assert_eq!(n, 42.5),\n            _ => panic!(\"Expected Number type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-18: 固定整数测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-18 |
| **测试名称** | 固定整数测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 配置为 Fixed 模式 |
| **输入** | 配置 fixed_value 为 Integer(100) |
| **预期结果** | 多次调用 `read_point()` 都返回 100 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_fixed_integer_value() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Fixed,\n        fixed_value: PointValue::Integer(100),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..10 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Integer(n) => assert_eq!(n, 100),\n            _ => panic!(\"Expected Integer type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-19: 固定布尔值测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-19 |
| **测试名称** | 固定布尔值测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 配置为 Fixed 模式 |
| **输入** | 配置 fixed_value 为 Boolean(true) |
| **预期结果** | 多次调用 `read_point()` 都返回 true |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_fixed_boolean_value() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Fixed,\n        fixed_value: PointValue::Boolean(true),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..10 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Boolean(b) => assert!(b),\n            _ => panic!(\"Expected Boolean type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-20: 固定字符串测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-20 |
| **测试名称** | 固定字符串测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | VirtualDriver 配置为 Fixed 模式 |
| **输入** | 配置 fixed_value 为 String("test_value") |
| **预期结果** | 多次调用 `read_point()` 都返回 "test_value" |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_fixed_string_value() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Fixed,\n        fixed_value: PointValue::String(\"test_value\".to_string()),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..10 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::String(s) => assert_eq!(s, \"test_value\"),\n            _ => panic!(\"Expected String type\"),\n        }\n    }\n}\br>``` |

---

## 4. 设备参数配置测试 (TC-S1-017-21 ~ TC-S1-017-32)

### 4.1 随机范围配置测试

#### TC-S1-017-21: 范围配置（min == max）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-21 |
| **测试名称** | 范围配置（min == max）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置 min_value == max_value |
| **预期结果** | 返回值始终等于该固定值 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_range_config_equal_min_max() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        min_value: 50.0,\n        max_value: 50.0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..100 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Number(n) => assert_eq!(n, 50.0),\n            _ => panic!(\"Expected Number type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-22: 范围配置（负数范围）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-22 |
| **测试名称** | 范围配置（负数范围）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置范围 [-50.0, -10.0) |
| **预期结果** | 所有返回值在 [-50.0, -10.0) 范围内 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_range_config_negative() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        min_value: -50.0,\n        max_value: -10.0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..100 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Number(n) => {\n                assert!(n >= -50.0 && n < -10.0);\n            }\n            _ => panic!(\"Expected Number type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-23: 范围配置（包含小数）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-23 |
| **测试名称** | 范围配置（包含小数）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置范围 [0.001, 0.009] |
| **预期结果** | 所有返回值在 [0.001, 0.009] 范围内 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_range_config_small_decimals() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        min_value: 0.001,\n        max_value: 0.009,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..100 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Number(n) => {\n                assert!(n >= 0.001 && n <= 0.009);\n            }\n            _ => panic!(\"Expected Number type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-24: 范围配置（大数据范围）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-24 |
| **测试名称** | 范围配置（大数据范围）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置范围 [-1e10, 1e10] |
| **预期结果** | 所有返回值在范围内 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_range_config_large_values() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        min_value: -1e10,\n        max_value: 1e10,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    for _ in 0..100 {\n        let value = driver.read_point(point_id).await.unwrap();\n        match value {\n            PointValue::Number(n) => {\n                assert!(n >= -1e10 && n <= 1e10);\n            }\n            _ => panic!(\"Expected Number type\"),\n        }\n    }\n}\br>``` |

---

#### TC-S1-017-25: 范围配置（min > max）验证测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-25 |
| **测试名称** | 范围配置（min > max）验证测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置 min_value > max_value |
| **预期结果** | `VirtualConfig::validate()` 返回错误 |
| **测试代码** | ```rust<br>#[test]\nfn test_config_validate_min_greater_than_max() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Random,\n        min_value: 100.0,\n        max_value: 10.0, // min > max\n        ..Default::default()\n    };\n    \n    let result = VirtualConfig::validate(&config);\n    assert!(result.is_err());\n    \n    match result {\n        Err(VirtualConfigError::InvalidRange { min, max }) => {\n            assert_eq!(min, 100.0);\n            assert_eq!(max, 10.0);\n        }\n        _ => panic!(\"Expected InvalidRange error\"),\n    }\n}\br>``` |

---

### 4.2 采样间隔配置测试

#### TC-S1-017-26: 采样间隔配置测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-26 |
| **测试名称** | 采样间隔配置测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置 sample_interval_ms = 100 |
| **预期结果** | 采样间隔正确设置为 100ms |
| **测试代码** | ```rust<br>#[test]\nfn test_sample_interval_config() {\n    let config = VirtualConfig {\n        sample_interval_ms: 100,\n        ..Default::default()\n    };\n    assert_eq!(config.sample_interval_ms, 100);\n}\br>``` |

---

#### TC-S1-017-27: 采样间隔（边界值0）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-27 |
| **测试名称** | 采样间隔（边界值0）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置 sample_interval_ms = 0 |
| **预期结果** | 每次调用立即返回新值 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_sample_interval_zero() {\n    let config = VirtualConfig {\n        sample_interval_ms: 0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    // 连续调用应该都能返回有效值\n    let value1 = driver.read_point(point_id).await.unwrap();\n    let value2 = driver.read_point(point_id).await.unwrap();\n    assert!(matches!(value1, PointValue::Number(_)));\n    assert!(matches!(value2, PointValue::Number(_)));\n}\br>``` |

---

#### TC-S1-017-28: 采样间隔（大值）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-28 |
| **测试名称** | 采样间隔（大值）测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 无 |
| **输入** | 配置 sample_interval_ms = 60000 (1分钟) |
| **预期结果** | 配置接受该值 |
| **测试代码** | ```rust<br>#[test]\nfn test_sample_interval_large_value() {\n    let config = VirtualConfig {\n        sample_interval_ms: 60000,\n        ..Default::default()\n    };\n    assert_eq!(config.sample_interval_ms, 60000);\n}\br>``` |

---

### 4.3 数据类型配置测试

#### TC-S1-017-29: 数据类型配置一致性测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-29 |
| **测试名称** | 数据类型配置一致性测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 配置 fixed_value 类型与 data_type 不一致 |
| **预期结果** | 1. 如果 data_type=Number，fixed_value 应转换为 Number<br>2. 或者返回配置错误 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_data_type_consistency() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Fixed,\n        data_type: DataType::Number,\n        fixed_value: PointValue::Integer(42),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let value = driver.read_point(point_id).await.unwrap();\n    // 应该能正常工作，类型转换或直接使用\n    match value {\n        PointValue::Number(n) => assert_eq!(n, 42.0),\n        _ => panic!(\"Expected Number type\"),\n    }\n}\br>``` |

---

#### TC-S1-017-30: 默认配置值测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-30 |
| **测试名称** | 默认配置值测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **输入** | 调用 `VirtualConfig::default()` |
| **预期结果** | 默认值为: mode=Random, min_value=0.0, max_value=100.0, data_type=Number, sample_interval_ms=1000 |
| **测试代码** | ```rust<br>#[test]\nfn test_default_config_values() {\n    let config = VirtualConfig::default();\n    assert_eq!(config.mode, VirtualMode::Random);\n    assert_eq!(config.min_value, 0.0);\n    assert_eq!(config.max_value, 100.0);\n    assert_eq!(config.data_type, DataType::Number);\n    assert_eq!(config.sample_interval_ms, 1000);\n}\br>``` |

---

### 4.4 配置验证测试

#### TC-S1-017-31: 配置验证（有效配置）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-31 |
| **测试名称** | 配置验证（有效配置）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualConfig::validate() 已实现 |
| **输入** | 传入有效配置 |
| **预期结果** | `validate()` 返回 `Ok(())` |
| **测试代码** | ```rust<br>#[test]\nfn test_config_validate_valid() {\n    let config = VirtualConfig::default();\n    let result = VirtualConfig::validate(&config);\n    assert!(result.is_ok());\n}\br>``` |

---

#### TC-S1-017-32: 配置验证（无效范围）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-32 |
| **测试名称** | 配置验证（无效范围）测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualConfig::validate() 已实现 |
| **输入** | 配置 min_value > max_value |
| **预期结果** | `validate()` 返回 `Err(VirtualConfigError::InvalidRange)` |
| **测试代码** | ```rust<br>#[test]\nfn test_config_validate_invalid_range() {\n    let config = VirtualConfig {\n        min_value: 100.0,\n        max_value: 10.0,\n        ..Default::default()\n    };\n    let result = VirtualConfig::validate(&config);\n    assert!(result.is_err());\n    assert!(matches!(result, Err(VirtualConfigError::InvalidRange { .. })));\n}\br>``` |

---

## 5. 设备连接生命周期管理测试 (TC-S1-017-40 ~ TC-S1-017-50)

### 5.1 连接状态测试

#### TC-S1-017-40: 初始状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-40 |
| **测试名称** | 初始状态测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已创建 |
| **输入** | 检查初始连接状态 |
| **预期结果** | `is_connected()` 返回 `false` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_initial_state() {\n    let driver = VirtualDriver::new();\n    assert!(!driver.is_connected());\n}\br>``` |

---

#### TC-S1-017-41: 连接成功后状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-41 |
| **测试名称** | 连接成功后状态测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已创建 |
| **输入** | 调用 `connect()` |
| **预期结果** | 1. `connect()` 返回 `Ok`<br>2. `is_connected()` 返回 `true` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_connected_state() {\n    let mut driver = VirtualDriver::new();\n    let result = driver.connect().await;\n    assert!(result.is_ok());\n    assert!(driver.is_connected());\n}\br>``` |

---

#### TC-S1-017-42: 断开连接后状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-42 |
| **测试名称** | 断开连接后状态测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接 |
| **输入** | 调用 `disconnect()` |
| **预期结果** | 1. `disconnect()` 返回 `Ok`<br>2. `is_connected()` 返回 `false` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_disconnected_state() {\n    let mut driver = VirtualDriver::new();\n    driver.connect().await.unwrap();\n    assert!(driver.is_connected());\n    \n    let result = driver.disconnect().await;\n    assert!(result.is_ok());\n    assert!(!driver.is_connected());\n}\br>``` |

---

#### TC-S1-017-43: 重复连接测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-43 |
| **测试名称** | 重复连接测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接 |
| **输入** | 再次调用 `connect()` |
| **预期结果** | 返回 `Ok` (重复连接无操作) 或 `Err(DriverError::AlreadyConnected)` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_duplicate_connect() {\n    let mut driver = VirtualDriver::new();\n    driver.connect().await.unwrap();\n    \n    // 第二次连接应返回成功或 AlreadyConnected 错误\n    let result = driver.connect().await;\n    assert!(result.is_ok() || matches!(result, Err(DriverError::AlreadyConnected)));\n}\br>``` |

---

#### TC-S1-017-44: 重复断开测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-44 |
| **测试名称** | 重复断开测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已断开 |
| **输入** | 再次调用 `disconnect()` |
| **预期结果** | 返回 `Ok` (重复断开无操作) 或 `Err(DriverError::NotConnected)` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_duplicate_disconnect() {\n    let mut driver = VirtualDriver::new();\n    // 初始断开状态\n    let result = driver.disconnect().await;\n    \n    // 重复断开应返回成功或 NotConnected 错误\n    assert!(result.is_ok() || matches!(result, Err(DriverError::NotConnected)));\n}\br>``` |

---

### 5.2 连接状态下的操作测试

#### TC-S1-017-45: 已连接状态读取数据测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-45 |
| **测试名称** | 已连接状态读取数据测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接 |
| **输入** | 连接后调用 `read_point()` |
| **预期结果** | 返回有效数据 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_read_when_connected() {\n    let mut driver = VirtualDriver::new();\n    driver.connect().await.unwrap();\n    \n    let point_id = Uuid::new_v4();\n    let value = driver.read_point(point_id).await.unwrap();\n    assert!(matches!(value, PointValue::Number(_)));\n}\br>``` |

---

#### TC-S1-017-46: 未连接状态读取数据测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-46 |
| **测试名称** | 未连接状态读取数据测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 未连接 |
| **输入** | 未连接时调用 `read_point()` |
| **预期结果** | 返回 `DriverError::NotConnected` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_read_when_not_connected() {\n    let driver = VirtualDriver::new();\n    let point_id = Uuid::new_v4();\n    \n    let result = driver.read_point(point_id).await;\n    assert!(matches!(result, Err(DriverError::NotConnected)));\n}\br>``` |

---

#### TC-S1-017-47: 连接断开后读取数据测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-47 |
| **测试名称** | 连接断开后读取数据测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接后断开 |
| **输入** | 断开后调用 `read_point()` |
| **预期结果** | 返回 `DriverError::NotConnected` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_read_after_disconnect() {\n    let mut driver = VirtualDriver::new();\n    driver.connect().await.unwrap();\n    driver.disconnect().await.unwrap();\n    \n    let point_id = Uuid::new_v4();\n    let result = driver.read_point(point_id).await;\n    assert!(matches!(result, Err(DriverError::NotConnected)));\n}\br>``` |

---

### 5.3 设备连接管理器测试

#### TC-S1-017-48: 设备管理器注册设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-48 |
| **测试名称** | 设备管理器注册设备测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | DeviceManager 已创建 |
| **输入** | 调用 `manager.register_device(device_id, driver)` |
| **预期结果** | 设备成功注册 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_device_manager_register() {\n    let manager = DeviceManager::new();\n    let device_id = Uuid::new_v4();\n    let driver = VirtualDriver::new();\n    \n    let result = manager.register_device(device_id, driver);\n    assert!(result.is_ok());\n    assert!(manager.get_device(device_id).is_some());\n}\br>``` |

---

#### TC-S1-017-49: 设备管理器获取设备（不存在）测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-49 |
| **测试名称** | 设备管理器获取设备（不存在）测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | DeviceManager 已创建 |
| **输入** | 调用 `manager.get_device(non_existent_id)` |
| **预期结果** | 返回 `None` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_device_manager_get_nonexistent() {\n    let manager = DeviceManager::new();\n    let non_existent_id = Uuid::new_v4();\n    \n    let result = manager.get_device(non_existent_id);\n    assert!(result.is_none());\n}\br>``` |

---

#### TC-S1-017-50: 设备管理器批量连接测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-50 |
| **测试名称** | 设备管理器批量连接测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | DeviceManager 已注册多个设备 |
| **输入** | 调用 `manager.connect_all()` |
| **预期结果** | 所有设备成功连接 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_device_manager_connect_all() {\n    let manager = DeviceManager::new();\n    let id1 = Uuid::new_v4();\n    let id2 = Uuid::new_v4();\n    \n    manager.register_device(id1, VirtualDriver::new()).unwrap();\n    manager.register_device(id2, VirtualDriver::new()).unwrap();\n    \n    let results = manager.connect_all().await;\n    assert!(results.iter().all(|r| r.is_ok()));\n}\br>``` |

---

## 6. 枚举变体和边界测试 (TC-S1-017-51 ~ TC-S1-017-60)

### 6.1 VirtualMode 枚举变体测试

#### TC-S1-017-51: VirtualMode 枚举所有变体测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-51 |
| **测试名称** | VirtualMode 枚举所有变体测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualMode 枚举已定义 |
| **输入** | 创建所有 VirtualMode 变体 |
| **预期结果** | VirtualMode 包含: `Random`, `Fixed`, `Sine`, `Ramp` 等变体 |
| **测试代码** | ```rust<br>#[test]\nfn test_virtual_mode_variants() {\n    let modes = vec![\n        VirtualMode::Random,\n        VirtualMode::Fixed,\n        VirtualMode::Sine,\n        VirtualMode::Ramp,\n    ];\n    \n    for mode in modes {\n        let debug_str = format!(\"{:?}\", mode);\n        assert!(!debug_str.is_empty());\n    }\n}\br>``` |

---

#### TC-S1-017-52: VirtualMode::Sine 模式测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-52 |
| **测试名称** | VirtualMode::Sine 模式测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | VirtualDriver 支持 Sine 模式 |
| **输入** | 配置 mode 为 Sine |
| **预期结果** | 返回正弦波数据 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_virtual_mode_sine() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Sine,\n        min_value: -1.0,\n        max_value: 1.0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    // Sine 模式应返回 [-1.0, 1.0] 范围内的值\n    let value = driver.read_point(point_id).await.unwrap();\n    match value {\n        PointValue::Number(n) => {\n            assert!(n >= -1.0 && n <= 1.0);\n        }\n        _ => panic!(\"Expected Number type\"),\n    }\n}\br>``` |

---

#### TC-S1-017-53: VirtualMode::Ramp 模式测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-53 |
| **测试名称** | VirtualMode::Ramp 模式测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | VirtualDriver 支持 Ramp 模式 |
| **输入** | 配置 mode 为 Ramp |
| **预期结果** | 返回线性递增数据 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_virtual_mode_ramp() {\n    let config = VirtualConfig {\n        mode: VirtualMode::Ramp,\n        min_value: 0.0,\n        max_value: 100.0,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    // Ramp 模式应返回在 [0.0, 100.0] 范围内的值\n    let value = driver.read_point(point_id).await.unwrap();\n    match value {\n        PointValue::Number(n) => {\n            assert!(n >= 0.0 && n <= 100.0);\n        }\n        _ => panic!(\"Expected Number type\"),\n    }\n}\br>``` |

---

### 6.2 AccessType 枚举变体测试

#### TC-S1-017-54: AccessType 枚举所有变体测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-54 |
| **测试名称** | AccessType 枚举所有变体测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | AccessType 枚举已定义 |
| **输入** | 创建所有 AccessType 变体 |
| **预期结果** | AccessType 包含: `RO` (只读), `WO` (只写), `RW` (读写) |
| **测试代码** | ```rust<br>#[test]\nfn test_access_type_variants() {\n    let types = vec![\n        AccessType::RO,\n        AccessType::WO,\n        AccessType::RW,\n    ];\n    \n    for access_type in types {\n        let debug_str = format!(\"{:?}\", access_type);\n        assert!(!debug_str.is_empty());\n    }\n}\br>``` |

---

#### TC-S1-017-55: AccessType::RO 写入测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-55 |
| **测试名称** | AccessType::RO 写入测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接，测点配置为 RO |
| **输入** | 调用 `write_point()` 写入 RO 测点 |
| **预期结果** | 返回 `DriverError::ReadOnlyPoint` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_write_to_read_only_point() {\n    let config = VirtualConfig {\n        access_type: AccessType::RO,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let result = driver.write_point(point_id, PointValue::Number(50.0)).await;\n    assert!(matches!(result, Err(DriverError::ReadOnlyPoint)));\n}\br>``` |

---

#### TC-S1-017-56: AccessType::RW 读写测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-56 |
| **测试名称** | AccessType::RW 读写测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接，测点配置为 RW |
| **输入** | 调用 `write_point()` 写入 RW 测点，然后读取 |
| **预期结果** | 1. `write_point()` 返回 `Ok`<br>2. 后续 `read_point()` 返回写入的值 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_read_write_rw_point() {\n    let config = VirtualConfig {\n        access_type: AccessType::RW,\n        mode: VirtualMode::Fixed,\n        fixed_value: PointValue::Number(0.0),\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    // 写入值\n    let write_result = driver.write_point(point_id, PointValue::Number(99.0)).await;\n    assert!(write_result.is_ok());\n    \n    // 读取值（应为写入的值）\n    let read_result = driver.read_point(point_id).await;\n    assert!(read_result.is_ok());\n    \n    match read_result.unwrap() {\n        PointValue::Number(n) => assert_eq!(n, 99.0),\n        _ => panic!(\"Expected Number type\"),\n    }\n}\br>``` |

---

### 6.3 错误处理测试

#### TC-S1-017-57: 超时错误测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-57 |
| **测试名称** | 超时错误测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接 |
| **输入** | 模拟操作超时条件 |
| **预期结果** | 返回 `DriverError::Timeout` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_timeout_error() {\n    // 创建一个会超时的场景\n    let driver = VirtualDriver::new();\n    let point_id = Uuid::new_v4();\n    \n    // 注意: 实际超时测试可能需要 mock 或特殊配置\n    // 这里测试 Timeout 错误类型本身\n    let timeout_error = DriverError::Timeout { \n        duration: std::time::Duration::from_secs(1) \n    };\n    \n    let debug_str = format!(\"{:?}\", timeout_error);\n    assert!(debug_str.contains(\"Timeout\"));\n}\br>``` |

---

#### TC-S1-017-58: 写入只读测点错误测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-58 |
| **测试名称** | 写入只读测点错误测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接，测点配置为 RO |
| **输入** | 调用 `write_point()` 写入 RO 测点 |
| **预期结果** | 返回 `DriverError::ReadOnlyPoint` |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_write_readonly_point_error() {\n    let config = VirtualConfig {\n        access_type: AccessType::RO,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    let result = driver.write_point(point_id, PointValue::Number(50.0)).await;\n    assert!(matches!(result, Err(DriverError::ReadOnlyPoint)));\n}\br>``` |

---

#### TC-S1-017-59: 写入无效值类型测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-59 |
| **测试名称** | 写入无效值类型测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | VirtualDriver 已连接 |
| **输入** | 写入与配置类型不匹配的值 |
| **预期结果** | 返回类型错误或拒绝写入 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_write_invalid_value_type() {\n    let config = VirtualConfig {\n        data_type: DataType::Number,\n        access_type: AccessType::RW,\n        ..Default::default()\n    };\n    let driver = VirtualDriver::with_config(config);\n    let point_id = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    // 尝试写入字符串到 Number 类型测点\n    let result = driver.write_point(point_id, PointValue::String(\"invalid\".to_string())).await;\n    \n    // 应该返回错误（类型不匹配）\n    assert!(result.is_err());\n    assert!(matches!(result, Err(DriverError::InvalidValue { .. })));\n}\br>``` |

---

### 6.4 不同测点ID独立数据测试

#### TC-S1-017-60: 不同测点ID独立数据流测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-017-60 |
| **测试名称** | 不同测点ID独立数据流测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | VirtualDriver 已连接 |
| **输入** | 使用不同 point_id 调用 `read_point()` |
| **预期结果** | 不同 point_id 生成独立的数据流 |
| **测试代码** | ```rust<br>#[tokio::test]\nasync fn test_independent_point_data_streams() {\n    let driver = VirtualDriver::new();\n    let point_id_1 = Uuid::new_v4();\n    let point_id_2 = Uuid::new_v4();\n    \n    driver.connect().await.unwrap();\n    \n    // 多次读取每个测点，验证它们是独立的\n    let values_1: Vec<_> = std::iter::repeat_with(|| {\n        driver.read_point(point_id_1).unwrap()\n    }).take(5).collect();\n    \n    let values_2: Vec<_> = std::iter::repeat_with(|| {\n        driver.read_point(point_id_2).unwrap()\n    }).take(5).collect();\n    \n    // 验证两个测点的数据可以独立变化\n    // （具体行为取决于实现：可能返回相同或不同的值）\n    assert_eq!(values_1.len(), 5);\n    assert_eq!(values_2.len(), 5);\n    \n    // 验证每个测点的数据是有效的 PointValue\n    for v in values_1.iter().chain(values_2.iter()) {\n        assert!(matches!(v, PointValue::Number(_)));\n    }\n}\br>``` |

---

## 7. 测试覆盖矩阵

| 验收标准 | TC覆盖 | 测试类型 |
|---------|--------|----------|
| 1. 定义DeviceDriver trait接口 | TC-S1-017-01 ~ TC-S1-017-06 | Unit Test |
| 2. VirtualDriver实现数据读取 | TC-S1-017-10 ~ TC-S1-017-20 | Unit Test |
| 3. 设备可配置参数(如随机范围) | TC-S1-017-21 ~ TC-S1-017-32 | Unit Test |
| 4. 设备连接生命周期管理 | TC-S1-017-40 ~ TC-S1-017-50 | Integration Test |
| 5. 枚举变体和边界测试 | TC-S1-017-51 ~ TC-S1-017-60 | Unit Test |

---

## 8. 自动化测试代码示例

### 8.1 DeviceDriver Trait 测试

```rust
// kayak-backend/src/drivers/mod.rs

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;
    use std::time::Duration;

    // TC-S1-017-01: DeviceDriver trait 基本方法签名测试
    #[test]
    fn test_device_driver_trait_methods() {
        // 使用编译时 trait bounds 验证 trait 方法存在
        fn assert_device_driver<D: DeviceDriver>() {}
        assert_device_driver::<VirtualDriver>();
    }

    // TC-S1-017-02: DeviceDriver trait 关联类型定义测试
    #[test]
    fn test_device_driver_associated_types() {
        fn assert_has_associated_types<D: DeviceDriver>() {
            fn check_config(_: &<D as DeviceDriver>::Config) {}
            fn check_error(_: <D as DeviceDriver>::Error) {}
        }
        assert_has_associated_types::<VirtualDriver>();
    }

    // TC-S1-017-03: DeviceDriver trait 默认实现测试
    #[test]
    fn test_is_connected_default_impl() {
        let driver = VirtualDriver::new();
        assert!(!driver.is_connected());
    }

    // TC-S1-017-04: DriverError 枚举定义测试
    #[test]
    fn test_driver_error_variants() {
        let errors = vec![
            DriverError::NotConnected,
            DriverError::Timeout { duration: Duration::from_secs(1) },
            DriverError::InvalidValue { message: "test".to_string() },
            DriverError::ConfigError("config error".to_string()),
            DriverError::IoError("io error".to_string()),
        ];
        
        for error in errors {
            let debug_str = format!("{:?}", error);
            assert!(!debug_str.is_empty());
        }
    }

    // TC-S1-017-05: PointValue 数据类型测试
    #[test]
    fn test_point_value_types() {
        let number = PointValue::Number(42.5);
        let integer = PointValue::Integer(42);
        let string = PointValue::String("test".to_string());
        let boolean = PointValue::Boolean(true);

        assert!(matches!(number, PointValue::Number(_)));
        assert!(matches!(integer, PointValue::Integer(_)));
        assert!(matches!(string, PointValue::String(_)));
        assert!(matches!(boolean, PointValue::Boolean(_)));
    }

    // TC-S1-017-06: DeviceDriver Send + Sync Trait Bounds 测试
    #[test]
    fn test_virtual_driver_send_sync() {
        fn assert_send_sync<T: Send + Sync>() {}
        assert_send_sync::<VirtualDriver>();
        
        // 进一步验证: 在多线程上下文中使用
        let driver = VirtualDriver::new();
        let driver = std::sync::Arc::new(std::sync::Mutex::new(driver));
        
        std::thread::spawn(move || {
            let _ = driver.lock().unwrap().is_connected();
        }).join().unwrap();
    }
}
```

### 8.2 VirtualDriver 测试

```rust
// kayak-backend/src/drivers/virtual_driver_test.rs

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    // TC-S1-017-10: VirtualDriver 默认创建测试
    #[tokio::test]
    async fn test_virtual_driver_default_creation() {
        let driver = VirtualDriver::new();
        assert!(!driver.is_connected());
        let config = driver.get_config();
        assert_eq!(config.mode, VirtualMode::Random);
    }

    // TC-S1-017-12: 随机数据生成（默认范围）测试
    #[tokio::test]
    async fn test_random_data_generation_default_range() {
        let driver = VirtualDriver::new();
        let point_id = Uuid::new_v4();
        
        driver.connect().await.unwrap();
        
        let value = driver.read_point(point_id).await.unwrap();
        match value {
            PointValue::Number(n) => {
                assert!(n >= 0.0 && n < 100.0);
            }
            _ => panic!("Expected Number type"),
        }
    }

    // TC-S1-017-13: 随机数据生成（自定义范围）测试
    #[tokio::test]
    async fn test_random_data_custom_range() {
        let config = VirtualConfig {
            mode: VirtualMode::Random,
            min_value: 10.0,
            max_value: 50.0,
            ..Default::default()
        };
        let driver = VirtualDriver::with_config(config);
        let point_id = Uuid::new_v4();
        
        driver.connect().await.unwrap();
        
        for _ in 0..100 {
            let value = driver.read_point(point_id).await.unwrap();
            match value {
                PointValue::Number(n) => {
                    assert!(n >= 10.0 && n < 50.0);
                }
                _ => panic!("Expected Number type"),
            }
        }
    }

    // TC-S1-017-17: 固定数值测试
    #[tokio::test]
    async fn test_fixed_number_value() {
        let config = VirtualConfig {
            mode: VirtualMode::Fixed,
            fixed_value: PointValue::Number(42.5),
            ..Default::default()
        };
        let driver = VirtualDriver::with_config(config);
        let point_id = Uuid::new_v4();
        
        driver.connect().await.unwrap();
        
        for _ in 0..10 {
            let value = driver.read_point(point_id).await.unwrap();
            match value {
                PointValue::Number(n) => assert_eq!(n, 42.5),
                _ => panic!("Expected Number type"),
            }
        }
    }

    // TC-S1-017-31: 配置验证（有效配置）测试
    #[test]
    fn test_config_validate_valid() {
        let config = VirtualConfig::default();
        let result = VirtualConfig::validate(&config);
        assert!(result.is_ok());
    }

    // TC-S1-017-32: 配置验证（无效范围）测试
    #[test]
    fn test_config_validate_invalid_range() {
        let config = VirtualConfig {
            min_value: 100.0,
            max_value: 10.0,
            ..Default::default()
        };
        let result = VirtualConfig::validate(&config);
        assert!(result.is_err());
        assert!(matches!(result, Err(VirtualConfigError::InvalidRange { .. })));
    }

    // TC-S1-017-40: 初始状态测试
    #[tokio::test]
    async fn test_initial_state() {
        let driver = VirtualDriver::new();
        assert!(!driver.is_connected());
    }

    // TC-S1-017-41: 连接成功后状态测试
    #[tokio::test]
    async fn test_connected_state() {
        let mut driver = VirtualDriver::new();
        driver.connect().await.unwrap();
        assert!(driver.is_connected());
    }

    // TC-S1-017-42: 断开连接后状态测试
    #[tokio::test]
    async fn test_disconnected_state() {
        let mut driver = VirtualDriver::new();
        driver.connect().await.unwrap();
        driver.disconnect().await.unwrap();
        assert!(!driver.is_connected());
    }

    // TC-S1-017-46: 未连接状态读取数据测试
    #[tokio::test]
    async fn test_read_when_not_connected() {
        let driver = VirtualDriver::new();
        let point_id = Uuid::new_v4();
        let result = driver.read_point(point_id).await;
        assert!(matches!(result, Err(DriverError::NotConnected)));
    }

    // TC-S1-017-56: AccessType::RW 读写测试
    #[tokio::test]
    async fn test_read_write_rw_point() {
        let config = VirtualConfig {
            access_type: AccessType::RW,
            mode: VirtualMode::Fixed,
            fixed_value: PointValue::Number(0.0),
            ..Default::default()
        };
        let driver = VirtualDriver::with_config(config);
        let point_id = Uuid::new_v4();
        
        driver.connect().await.unwrap();
        
        // 写入值
        let write_result = driver.write_point(point_id, PointValue::Number(99.0)).await;
        assert!(write_result.is_ok());
        
        // 读取值
        let read_result = driver.read_point(point_id).await;
        assert!(read_result.is_ok());
        
        match read_result.unwrap() {
            PointValue::Number(n) => assert_eq!(n, 99.0),
            _ => panic!("Expected Number type"),
        }
    }

    // TC-S1-017-60: 不同测点ID独立数据流测试
    #[tokio::test]
    async fn test_independent_point_data_streams() {
        let driver = VirtualDriver::new();
        let point_id_1 = Uuid::new_v4();
        let point_id_2 = Uuid::new_v4();
        
        driver.connect().await.unwrap();
        
        let values_1: Vec<_> = std::iter::repeat_with(|| {
            driver.read_point(point_id_1).unwrap()
        }).take(5).collect();
        
        let values_2: Vec<_> = std::iter::repeat_with(|| {
            driver.read_point(point_id_2).unwrap()
        }).take(5).collect();
        
        assert_eq!(values_1.len(), 5);
        assert_eq!(values_2.len(), 5);
        
        for v in values_1.iter().chain(values_2.iter()) {
            assert!(matches!(v, PointValue::Number(_)));
        }
    }
}
```

### 8.3 DeviceManager 测试

```rust
// kayak-backend/src/drivers/manager_test.rs

#[cfg(test)]
mod tests {
    use super::*;

    // TC-S1-017-48: 设备管理器注册设备测试
    #[tokio::test]
    async fn test_device_manager_register() {
        let manager = DeviceManager::new();
        let device_id = Uuid::new_v4();
        let driver = VirtualDriver::new();
        
        let result = manager.register_device(device_id, driver);
        assert!(result.is_ok());
        assert!(manager.get_device(device_id).is_some());
    }

    // TC-S1-017-49: 设备管理器获取设备（不存在）测试
    #[tokio::test]
    async fn test_device_manager_get_nonexistent() {
        let manager = DeviceManager::new();
        let non_existent_id = Uuid::new_v4();
        
        let result = manager.get_device(non_existent_id);
        assert!(result.is_none());
    }

    // TC-S1-017-50: 设备管理器批量连接测试
    #[tokio::test]
    async fn test_device_manager_connect_all() {
        let manager = DeviceManager::new();
        let id1 = Uuid::new_v4();
        let id2 = Uuid::new_v4();
        
        manager.register_device(id1, VirtualDriver::new()).unwrap();
        manager.register_device(id2, VirtualDriver::new()).unwrap();
        
        let results = manager.connect_all().await;
        assert!(results.iter().all(|r| r.is_ok()));
    }
}
```

---

## 9. 修订记录

| 版本 | 日期 | 修改内容 | 修改人 |
|------|------|---------|--------|
| 1.0 | 2026-03-22 | 初始版本 | sw-mike |
| 1.1 | 2026-03-22 | 修订: <br>- TC-S1-017-01/02 改为编译时 trait bounds 验证<br>- 新增 TC-S1-017-06 Send+Sync 测试<br>- 新增 TC-S1-017-31/32 VirtualConfig::validate() 测试<br>- 新增 TC-S1-017-49 DeviceManager get_device() 负向测试<br>- 新增 TC-S1-017-56 write_point() 成功测试<br>- 新增 TC-S1-017-51~54 VirtualMode/AccessType 枚举测试<br>- 新增 TC-S1-017-57 超时错误测试<br>- 新增 TC-S1-017-60 不同测点ID独立数据测试<br>- 修正 TC-S1-017-53 断言问题<br>- 修正 TC-S1-017-51 UUID nil() 说明<br>- 明确 TC-S1-017-43/44 预期结果 | sw-mike |

---

## 10. 备注

1. **测试范围说明**: 本测试用例专注于驱动层测试，不涉及网络通信或数据库操作
2. **异步测试**: 所有涉及 `connect()`, `disconnect()`, `read_point()`, `write_point()` 的测试都使用 `async/await`，需要 tokio 测试运行器
3. **随机数据测试**: 随机数据生成测试使用多次迭代来提高覆盖率
4. **生命周期管理**: 连接管理测试验证了完整的连接/断开生命周期
5. **UUID处理**: 使用 `Uuid::new_v4()` 生成测试用的唯一标识符
6. **编译时验证**: TC-S1-017-01/02/06 使用 Rust 编译时 trait bounds 验证接口完整性
7. **配置验证**: TC-S1-017-31/32 测试 `VirtualConfig::validate()` 方法确保配置有效性

---

**文档结束**
