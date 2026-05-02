# R1-S1-001 测试用例文档

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S1-001 |
| 测试类型 | 单元测试 + 集成测试 |
| 测试范围 | DeviceManager 泛型消除重构 |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-02 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [DriverWrapper 测试](#2-driverwrapper-测试)
3. [DeviceManager 重构测试](#3-devicemanager-重构测试)
4. [异构驱动测试](#4-异构驱动测试)
5. [向后兼容性测试](#5-向后兼容性测试)
6. [并发安全测试](#6-并发安全测试)
7. [测试数据需求](#7-测试数据需求)
8. [测试环境](#8-测试环境)
9. [风险与假设](#9-风险与假设)

---

## 1. 测试概述

### 1.1 测试目标

验证 DeviceManager 泛型消除重构的正确性，确保：
- `DriverWrapper` 能够统一封装多种驱动类型
- `DeviceManager` 能够存储和管理异构驱动
- 现有 `VirtualDriver` 功能不受影响
- `DriverAccessAdapter` 适配器正常工作
- 并发场景下线程安全

### 1.2 测试范围

| 组件 | 测试内容 |
|------|---------|
| `drivers/wrapper.rs` | DriverWrapper 创建、DriverAccess/DriverLifecycle trait 实现 |
| `drivers/manager.rs` | DeviceManager 注册/注销/获取/连接/断开 |
| `drivers/virtual.rs` | VirtualDriver 向后兼容 |
| `engine/adapter.rs` | DriverAccessAdapter 适配 |
| `engine/step_engine.rs` | StepEngine 执行试验 |
| `services/point/service.rs` | PointService 读写测点 |

### 1.3 测试策略

- **单元测试**：每个组件独立测试，使用 mock/stub 隔离依赖
- **集成测试**：组件间交互测试，验证端到端流程
- **并发测试**：多线程场景验证线程安全

---

## 2. DriverWrapper 测试

### TC-001: DriverWrapper 使用 VirtualDriver 创建

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-001 |
| **测试名称** | DriverWrapper 使用 VirtualDriver 创建 |
| **测试目的** | 验证 DriverWrapper 能够使用 VirtualDriver 正确创建 |
| **前置条件** | VirtualDriver 已实现，DriverWrapper::new_virtual 方法可用 |
| **测试步骤** | 1. 创建 VirtualDriver 实例（使用默认配置）<br>2. 调用 DriverWrapper::new_virtual(driver) 创建 DriverWrapper<br>3. 验证返回的 DriverWrapper 不为空 |
| **预期结果** | 1. DriverWrapper 创建成功<br>2. 内部 AnyDriver::Virtual 变体包含传入的 VirtualDriver |
| **测试数据** | VirtualDriver::new() |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_driver_wrapper_create_with_virtual() {
    let virtual_driver = VirtualDriver::new();
    let wrapper = DriverWrapper::new_virtual(virtual_driver);
    // wrapper 应成功创建
    assert!(matches!(wrapper.inner, AnyDriver::Virtual(_)));
}
```

---

### TC-002: DriverWrapper 实现 DriverAccess trait

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-002 |
| **测试名称** | DriverWrapper 实现 DriverAccess trait |
| **测试目的** | 验证 DriverWrapper 正确实现 DriverAccess trait，提供统一的测点读写接口 |
| **前置条件** | DriverWrapper 已创建，VirtualDriver 已连接 |
| **测试步骤** | 1. 创建 VirtualDriver 并包装为 DriverWrapper<br>2. 连接驱动（调用 connect）<br>3. 通过 DriverAccess trait 读取测点<br>4. 通过 DriverAccess trait 写入测点 |
| **预期结果** | 1. read_point 返回 PointValue<br>2. write_point 成功执行不返回错误<br>3. 读写操作均通过 DriverAccess trait 接口完成 |
| **测试数据** | point_id = Uuid::new_v4(), value = PointValue::Number(42.0) |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_driver_wrapper_implements_driver_access() {
    let mut wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    wrapper.connect().await.unwrap();
    
    let point_id = Uuid::new_v4();
    let value = PointValue::Number(42.0);
    
    // 测试 write_point
    DriverAccess::write_point(&wrapper, point_id, value.clone()).unwrap();
    
    // 测试 read_point
    let read_value = DriverAccess::read_point(&wrapper, point_id).unwrap();
    assert_eq!(read_value, value);
}
```

---

### TC-003: DriverWrapper 实现 DriverLifecycle trait

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-003 |
| **测试名称** | DriverWrapper 实现 DriverLifecycle trait |
| **测试目的** | 验证 DriverWrapper 正确实现 DriverLifecycle trait，提供连接/断开/状态查询功能 |
| **前置条件** | DriverWrapper 已创建 |
| **测试步骤** | 1. 创建 DriverWrapper<br>2. 调用 is_connected()，验证初始状态为 false<br>3. 调用 connect()<br>4. 调用 is_connected()，验证状态为 true<br>5. 调用 disconnect()<br>6. 调用 is_connected()，验证状态为 false |
| **预期结果** | 1. 初始状态：is_connected() == false<br>2. connect() 后：is_connected() == true<br>3. disconnect() 后：is_connected() == false |
| **测试数据** | 无 |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_driver_wrapper_implements_driver_lifecycle() {
    let mut wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    
    // 初始未连接
    assert!(!wrapper.is_connected());
    
    // 连接
    wrapper.connect().await.unwrap();
    assert!(wrapper.is_connected());
    
    // 断开
    wrapper.disconnect().await.unwrap();
    assert!(!wrapper.is_connected());
}
```

---

### TC-004: DriverWrapper 读取测点值（Virtual 模式）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-004 |
| **测试名称** | DriverWrapper 读取测点值（Virtual 模式） |
| **测试目的** | 验证 DriverWrapper 通过 DriverAccess trait 读取 VirtualDriver 测点值 |
| **前置条件** | DriverWrapper 已创建并连接 |
| **测试步骤** | 1. 创建 Fixed 模式的 VirtualDriver<br>2. 包装为 DriverWrapper 并连接<br>3. 使用 DriverAccess::read_point 读取测点<br>4. 验证返回值与固定值一致 |
| **预期结果** | 1. read_point 返回 Ok(PointValue)<br>2. 返回值等于配置的 fixed_value |
| **测试数据** | VirtualConfig { mode: Fixed, fixed_value: PointValue::Number(123.45), .. } |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_driver_wrapper_read_point_virtual_fixed() {
    let config = VirtualConfig {
        mode: VirtualMode::Fixed,
        fixed_value: PointValue::Number(123.45),
        ..Default::default()
    };
    let driver = VirtualDriver::with_config(config).unwrap();
    let mut wrapper = DriverWrapper::new_virtual(driver);
    wrapper.connect().await.unwrap();
    
    let point_id = Uuid::new_v4();
    let value = DriverAccess::read_point(&wrapper, point_id).unwrap();
    
    assert_eq!(value, PointValue::Number(123.45));
}
```

---

### TC-005: DriverWrapper 写入测点值（Virtual 模式）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-005 |
| **测试名称** | DriverWrapper 写入测点值（Virtual 模式） |
| **测试目的** | 验证 DriverWrapper 通过 DriverAccess trait 写入 VirtualDriver 测点值，并能正确读取回写入的值 |
| **前置条件** | DriverWrapper 已创建并连接，测点配置为 RW 访问类型 |
| **测试步骤** | 1. 创建 RW 模式的 VirtualDriver<br>2. 包装为 DriverWrapper 并连接<br>3. 使用 DriverAccess::write_point 写入值<br>4. 使用 DriverAccess::read_point 读取同一测点<br>5. 验证读取值等于写入值 |
| **预期结果** | 1. write_point 返回 Ok(())<br>2. read_point 返回写入的值 |
| **测试数据** | point_id = Uuid::new_v4(), value = PointValue::Integer(999) |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_driver_wrapper_write_point_virtual_rw() {
    let config = VirtualConfig {
        access_type: AccessType::RW,
        ..Default::default()
    };
    let driver = VirtualDriver::with_config(config).unwrap();
    let mut wrapper = DriverWrapper::new_virtual(driver);
    wrapper.connect().await.unwrap();
    
    let point_id = Uuid::new_v4();
    let write_value = PointValue::Integer(999);
    
    DriverAccess::write_point(&wrapper, point_id, write_value.clone()).unwrap();
    let read_value = DriverAccess::read_point(&wrapper, point_id).unwrap();
    
    assert_eq!(read_value, write_value);
}
```

---

### TC-006: DriverWrapper 连接/断开生命周期

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-006 |
| **测试名称** | DriverWrapper 连接/断开生命周期 |
| **测试目的** | 验证 DriverWrapper 的生命周期管理：连接、重复连接、断开、重复断开 |
| **前置条件** | DriverWrapper 已创建 |
| **测试步骤** | 1. 创建 DriverWrapper<br>2. 调用 connect()，验证成功<br>3. 再次调用 connect()，验证幂等（成功或 AlreadyConnected 错误）<br>4. 调用 disconnect()，验证成功<br>5. 再次调用 disconnect()，验证幂等 |
| **预期结果** | 1. 首次 connect() 返回 Ok(())<br>2. 重复 connect() 根据实现返回 Ok(()) 或 Err(DriverError::AlreadyConnected)<br>3. disconnect() 返回 Ok(())<br>4. 重复 disconnect() 返回 Ok(()) |
| **测试数据** | 无 |
| **优先级** | P1 |

---

### TC-007: DriverWrapper 错误转换（DriverError -> ExecutionError）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-007 |
| **测试名称** | DriverWrapper 错误转换（DriverError -> ExecutionError） |
| **测试目的** | 验证 DriverWrapper 在实现 DriverAccess 时，能将 VirtualDriver 的 DriverError 正确转换为 ExecutionError |
| **前置条件** | DriverWrapper 已创建但未连接 |
| **测试步骤** | 1. 创建 DriverWrapper（不连接）<br>2. 调用 DriverAccess::read_point<br>3. 验证返回 Err(ExecutionError)<br>4. 验证错误消息包含 "not connected" 或类似信息 |
| **预期结果** | 1. read_point 返回 Err(ExecutionError::DriverError(_))<br>2. 错误信息反映原始 DriverError::NotConnected |
| **测试数据** | point_id = Uuid::new_v4() |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_driver_wrapper_error_conversion() {
    let wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    // 不连接，直接读取
    let point_id = Uuid::new_v4();
    let result = DriverAccess::read_point(&wrapper, point_id);
    
    assert!(result.is_err());
    match result.unwrap_err() {
        ExecutionError::DriverError(msg) => {
            assert!(msg.contains("not connected") || msg.contains("NotConnected"));
        }
        _ => panic!("Expected ExecutionError::DriverError"),
    }
}
```

---

## 3. DeviceManager 重构测试

### TC-008: DeviceManager 注册 DriverWrapper

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-008 |
| **测试名称** | DeviceManager 注册 DriverWrapper |
| **测试目的** | 验证重构后的 DeviceManager 能够注册 DriverWrapper 类型的设备 |
| **前置条件** | DeviceManager 已创建，DriverWrapper 可用 |
| **测试步骤** | 1. 创建 DeviceManager<br>2. 创建 DriverWrapper（包装 VirtualDriver）<br>3. 调用 register_device(id, wrapper)<br>4. 验证注册成功 |
| **预期结果** | 1. register_device 返回 Ok(())<br>2. device_count() 返回 1 |
| **测试数据** | device_id = Uuid::new_v4() |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_device_manager_register_driver_wrapper() {
    let manager = DeviceManager::new();
    let device_id = Uuid::new_v4();
    let wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    
    let result = manager.register_device(device_id, wrapper);
    assert!(result.is_ok());
    assert_eq!(manager.device_count(), 1);
}
```

---

### TC-009: DeviceManager 注销 DriverWrapper

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-009 |
| **测试名称** | DeviceManager 注销 DriverWrapper |
| **测试目的** | 验证 DeviceManager 能够注销已注册的 DriverWrapper |
| **前置条件** | DeviceManager 已注册一个设备 |
| **测试步骤** | 1. 注册一个 DriverWrapper<br>2. 调用 unregister_device(id)<br>3. 验证注销成功<br>4. 验证 device_count() 返回 0 |
| **预期结果** | 1. unregister_device 返回 Ok(())<br>2. device_count() 返回 0 |
| **测试数据** | device_id = Uuid::new_v4() |
| **优先级** | P0 |

---

### TC-010: DeviceManager 获取已注册设备

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-010 |
| **测试名称** | DeviceManager 获取已注册设备 |
| **测试目的** | 验证 DeviceManager 能够获取已注册的 DriverWrapper 设备，并通过 DriverAccess trait 访问 |
| **前置条件** | DeviceManager 已注册一个设备 |
| **测试步骤** | 1. 注册一个 DriverWrapper<br>2. 调用 get_device(id)<br>3. 验证返回 Some(Arc<RwLock<DriverWrapper>>)<br>4. 获取读锁，验证可通过 DriverAccess trait 调用 read_point |
| **预期结果** | 1. get_device 返回 Some(...)<br>2. 获取的驱动可调用 DriverAccess 方法 |
| **测试数据** | device_id = Uuid::new_v4() |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_device_manager_get_device() {
    let manager = DeviceManager::new();
    let device_id = Uuid::new_v4();
    let wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    manager.register_device(device_id, wrapper).unwrap();
    
    let device_opt = manager.get_device(device_id);
    assert!(device_opt.is_some());
    
    let device_lock = device_opt.unwrap();
    let device = device_lock.read().unwrap();
    // 验证可以调用 DriverAccess 方法
    let point_id = Uuid::new_v4();
    let result = device.read_point(point_id);
    // 未连接，应返回错误
    assert!(result.is_err());
}
```

---

### TC-011: DeviceManager 连接所有设备

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-011 |
| **测试名称** | DeviceManager 连接所有设备 |
| **测试目的** | 验证 DeviceManager::connect_all 能够并行连接所有已注册设备 |
| **前置条件** | DeviceManager 已注册多个 DriverWrapper 设备 |
| **测试步骤** | 1. 注册 3 个 DriverWrapper（均包装 VirtualDriver）<br>2. 调用 connect_all().await<br>3. 验证返回结果包含 3 个 Ok 项<br>4. 验证所有设备 is_connected() == true |
| **预期结果** | 1. connect_all 返回 Vec<Result<Uuid, (Uuid, DriverError)>>，长度为 3<br>2. 所有结果均为 Ok(device_id)<br>3. 所有设备状态为已连接 |
| **测试数据** | 3 个不同的 device_id |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_device_manager_connect_all() {
    let manager = DeviceManager::new();
    let ids: Vec<_> = (0..3).map(|_| Uuid::new_v4()).collect();
    
    for id in &ids {
        let wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
        manager.register_device(*id, wrapper).unwrap();
    }
    
    let results = manager.connect_all().await;
    assert_eq!(results.len(), 3);
    
    for (i, result) in results.iter().enumerate() {
        assert!(result.is_ok());
        assert_eq!(result.as_ref().unwrap(), &ids[i]);
    }
    
    // 验证所有设备已连接
    for id in &ids {
        let device = manager.get_device(*id).unwrap();
        let driver = device.read().unwrap();
        assert!(driver.is_connected());
    }
}
```

---

### TC-012: DeviceManager 断开所有设备

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-012 |
| **测试名称** | DeviceManager 断开所有设备 |
| **测试目的** | 验证 DeviceManager::disconnect_all 能够并行断开所有已注册设备 |
| **前置条件** | DeviceManager 已注册多个设备，且均已连接 |
| **测试步骤** | 1. 注册 3 个设备<br>2. 调用 connect_all() 连接所有设备<br>3. 调用 disconnect_all().await<br>4. 验证返回结果包含 3 个 Ok 项<br>5. 验证所有设备 is_connected() == false |
| **预期结果** | 1. disconnect_all 返回 Vec<Result<Uuid, (Uuid, DriverError)>>，长度为 3<br>2. 所有结果均为 Ok(device_id)<br>3. 所有设备状态为未连接 |
| **测试数据** | 3 个不同的 device_id |
| **优先级** | P0 |

---

### TC-013: DeviceManager 设备计数

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-013 |
| **测试名称** | DeviceManager 设备计数 |
| **测试目的** | 验证 DeviceManager::device_count 正确反映已注册设备数量 |
| **前置条件** | DeviceManager 已创建 |
| **测试步骤** | 1. 验证初始 device_count() == 0<br>2. 注册 1 个设备，验证 device_count() == 1<br>3. 注册第 2 个设备，验证 device_count() == 2<br>4. 注销 1 个设备，验证 device_count() == 1<br>5. 注销所有设备，验证 device_count() == 0 |
| **预期结果** | device_count() 始终等于当前已注册设备数量 |
| **测试数据** | 2 个不同的 device_id |
| **优先级** | P1 |

---

### TC-014: DeviceManager 重复注册处理

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-014 |
| **测试名称** | DeviceManager 重复注册处理 |
| **测试目的** | 验证 DeviceManager 对重复注册同一 ID 的处理行为 |
| **前置条件** | DeviceManager 已注册一个设备 |
| **测试步骤** | 1. 注册一个设备（id = uuid1）<br>2. 再次使用相同 id 注册另一个设备<br>3. 验证返回错误 |
| **预期结果** | 1. 第二次注册返回 Err(DriverError::ConfigError(_))<br>2. device_count() 仍为 1<br>3. 原始设备未被覆盖 |
| **测试数据** | device_id = Uuid::new_v4() |
| **优先级** | P1 |

---

### TC-015: DeviceManager 注销不存在设备处理

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-015 |
| **测试名称** | DeviceManager 注销不存在设备处理 |
| **测试目的** | 验证 DeviceManager 对注销不存在设备的处理行为 |
| **前置条件** | DeviceManager 已创建 |
| **测试步骤** | 1. 调用 unregister_device 传入未注册的 ID<br>2. 验证返回错误 |
| **预期结果** | 返回 Err(DriverError::ConfigError(_))，消息包含 "not found" |
| **测试数据** | device_id = Uuid::new_v4()（未注册） |
| **优先级** | P1 |

---

## 4. 异构驱动测试

### TC-016: 同时注册 Virtual 和 Modbus TCP 驱动

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-016 |
| **测试名称** | 同时注册 Virtual 和 Modbus TCP 驱动 |
| **测试目的** | 验证 DeviceManager 能够同时存储和管理不同类型的驱动（Virtual + Modbus TCP） |
| **前置条件** | ModbusTcpDriver 已实现，DriverWrapper::new_modbus_tcp 可用 |
| **测试步骤** | 1. 创建 VirtualDriver 并包装为 DriverWrapper<br>2. 创建 ModbusTcpDriver 并包装为 DriverWrapper<br>3. 将两个设备注册到同一个 DeviceManager<br>4. 验证 device_count() == 2<br>5. 分别获取两个设备并验证类型 |
| **预期结果** | 1. 两个设备均注册成功<br>2. device_count() == 2<br>3. 获取的设备均可通过 DriverAccess trait 访问 |
| **测试数据** | virtual_id = Uuid::new_v4(), modbus_id = Uuid::new_v4() |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_device_manager_register_heterogeneous_drivers() {
    let manager = DeviceManager::new();
    let virtual_id = Uuid::new_v4();
    let modbus_id = Uuid::new_v4();
    
    // 注册 Virtual 驱动
    let virtual_wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    manager.register_device(virtual_id, virtual_wrapper).unwrap();
    
    // 注册 Modbus TCP 驱动
    let modbus_config = ModbusTcpConfig {
        host: "127.0.0.1".to_string(),
        port: 1502,
        slave_id: 1,
        timeout_ms: 5000,
    };
    let modbus_driver = ModbusTcpDriver::new(modbus_config).unwrap();
    let modbus_wrapper = DriverWrapper::new_modbus_tcp(modbus_driver);
    manager.register_device(modbus_id, modbus_wrapper).unwrap();
    
    assert_eq!(manager.device_count(), 2);
    
    // 验证两个设备都可获取
    assert!(manager.get_device(virtual_id).is_some());
    assert!(manager.get_device(modbus_id).is_some());
}
```

---

### TC-017: 异构驱动的 connect_all 测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-017 |
| **测试名称** | 异构驱动的 connect_all 测试 |
| **测试目的** | 验证 connect_all 能够正确连接异构驱动（部分成功、部分失败场景） |
| **前置条件** | DeviceManager 注册了 Virtual 和 Modbus TCP 驱动，Modbus TCP 目标不可达 |
| **测试步骤** | 1. 注册 VirtualDriver（本地，可连接）<br>2. 注册 ModbusTcpDriver（指向不可达地址）<br>3. 调用 connect_all().await<br>4. 验证结果：Virtual 成功，Modbus TCP 失败 |
| **预期结果** | 1. Virtual 设备连接成功（Ok(id)）<br>2. Modbus TCP 设备连接失败（Err((id, DriverError))）<br>3. 结果 Vec 长度为 2 |
| **测试数据** | ModbusTcpConfig { host: "192.0.2.1"(TEST-NET-1), port: 502, .. } |
| **优先级** | P0 |

---

### TC-018: 异构驱动的 disconnect_all 测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-018 |
| **测试名称** | 异构驱动的 disconnect_all 测试 |
| **测试目的** | 验证 disconnect_all 能够正确断开所有已连接的异构驱动 |
| **前置条件** | DeviceManager 注册了 Virtual 和 Modbus TCP 驱动，且均已连接 |
| **测试步骤** | 1. 注册并连接两种驱动<br>2. 调用 disconnect_all().await<br>3. 验证所有设备断开成功 |
| **预期结果** | 1. disconnect_all 返回所有 Ok(id)<br>2. 所有设备 is_connected() == false |
| **测试数据** | 2 个设备（Virtual + Modbus TCP） |
| **优先级** | P0 |

---

### TC-019: 从 DeviceManager 获取不同类型驱动并调用 DriverAccess

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-019 |
| **测试名称** | 从 DeviceManager 获取不同类型驱动并调用 DriverAccess |
| **测试目的** | 验证通过 DeviceManager 获取的异构驱动均可通过统一的 DriverAccess trait 接口访问 |
| **前置条件** | DeviceManager 注册了 Virtual 和 Modbus TCP 驱动，且均已连接 |
| **测试步骤** | 1. 注册并连接 Virtual 和 Modbus TCP 驱动<br>2. 分别获取两个设备<br>3. 对两个设备分别调用 DriverAccess::read_point<br>4. 验证两个设备均返回正确的 PointValue |
| **预期结果** | 1. Virtual 驱动返回生成的虚拟值<br>2. Modbus TCP 驱动返回从模拟设备读取的值<br>3. 两个调用均通过相同的 DriverAccess trait 接口 |
| **测试数据** | 2 个 point_id，分别对应两种驱动 |
| **优先级** | P0 |

---

## 5. 向后兼容性测试

### TC-020: VirtualDriver 继续正常工作（DeviceDriver trait）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-020 |
| **测试名称** | VirtualDriver 继续正常工作（DeviceDriver trait） |
| **测试目的** | 验证重构后 VirtualDriver 的 DeviceDriver trait 实现不受影响 |
| **前置条件** | VirtualDriver 已实现 DeviceDriver trait |
| **测试步骤** | 1. 创建 VirtualDriver<br>2. 验证 DeviceDriver::connect 正常工作<br>3. 验证 DeviceDriver::read_point 正常工作<br>4. 验证 DeviceDriver::write_point 正常工作<br>5. 验证 DeviceDriver::disconnect 正常工作 |
| **预期结果** | 所有 DeviceDriver trait 方法行为与重构前一致 |
| **测试数据** | VirtualConfig::default() |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_virtual_driver_backward_compatibility() {
    let mut driver = VirtualDriver::new();
    
    // 测试 DeviceDriver trait 方法
    driver.connect().await.unwrap();
    assert!(driver.is_connected());
    
    let point_id = Uuid::new_v4();
    let value = driver.read_point(point_id).unwrap();
    assert!(matches!(value, PointValue::Number(_)));
    
    driver.write_point(point_id, PointValue::Number(42.0)).unwrap();
    
    driver.disconnect().await.unwrap();
    assert!(!driver.is_connected());
}
```

---

### TC-021: 现有 PointService 读写测点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-021 |
| **测试名称** | 现有 PointService 读写测点测试 |
| **测试目的** | 验证 PointService 在 DeviceManager 重构后仍能正确读写测点 |
| **前置条件** | PointServiceImpl 已创建，DeviceManager 已注册设备，测点已创建 |
| **测试步骤** | 1. 创建 DeviceManager 并注册 VirtualDriver（包装为 DriverWrapper）<br>2. 创建 PointServiceImpl<br>3. 调用 read_point_value<br>4. 调用 write_point_value<br>5. 验证读写结果正确 |
| **预期结果** | 1. read_point_value 返回正确的 PointValueDto<br>2. write_point_value 成功执行<br>3. 无编译错误（API 签名兼容） |
| **测试数据** | user_id = Uuid::new_v4(), point_id = Uuid::new_v4() |
| **优先级** | P0 |

---

### TC-022: 现有 StepEngine 执行试验测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-022 |
| **测试名称** | 现有 StepEngine 执行试验测试 |
| **测试目的** | 验证 StepEngine 在 DeviceManager 重构后仍能正确执行试验过程 |
| **前置条件** | StepEngine 已创建，DeviceManager 已注册设备并连接 |
| **测试步骤** | 1. 创建 DeviceManager 并注册 VirtualDriver（包装为 DriverWrapper）<br>2. 连接设备<br>3. 创建 StepEngine<br>4. 执行包含 Start/Read/Delay/End 的过程定义<br>5. 验证执行成功 |
| **预期结果** | 1. engine.execute() 返回 Ok(ExecutionContext)<br>2. context.status == ExecutionStatus::Completed<br>3. 日志记录正确<br>4. 变量存储正确 |
| **测试数据** | 标准试验过程定义（Start -> Read -> Delay -> End） |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_step_engine_backward_compatibility() {
    let manager = Arc::new(DeviceManager::new());
    let device_id = Uuid::new_v4();
    let driver = VirtualDriver::new();
    manager.register_device(device_id, DriverWrapper::new_virtual(driver)).unwrap();
    
    // 连接设备
    {
        let device = manager.get_device(device_id).unwrap();
        let mut driver = device.write().unwrap();
        driver.connect().await.unwrap();
    }
    
    let engine = StepEngine::new(manager, None);
    let process_def = ProcessDefinition {
        version: "1.0".to_string(),
        steps: vec![
            StepDefinition::Start { id: "s1".to_string(), name: "Start".to_string() },
            StepDefinition::Read { id: "r1".to_string(), name: "Read".to_string(), point_id: Uuid::new_v4().to_string(), target_var: "temp".to_string() },
            StepDefinition::End { id: "e1".to_string(), name: "End".to_string() },
        ],
    };
    
    let result = engine.execute(&process_def, device_id).await;
    assert!(result.is_ok());
    let ctx = result.unwrap();
    assert_eq!(ctx.status, ExecutionStatus::Completed);
}
```

---

### TC-023: DriverAccessAdapter 适配测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-023 |
| **测试名称** | DriverAccessAdapter 适配测试 |
| **测试目的** | 验证重构后的 DriverAccessAdapter 能够正确适配 DriverWrapper 的 DriverAccess 实现 |
| **前置条件** | DriverAccessAdapter 已重构为引用 dyn DriverAccess |
| **测试步骤** | 1. 创建 DriverWrapper 并连接<br>2. 获取 DriverWrapper 的引用<br>3. 创建 DriverAccessAdapter::new(&wrapper)<br>4. 通过适配器调用 read_point 和 write_point<br>5. 验证操作成功 |
| **预期结果** | 1. DriverAccessAdapter 创建成功<br>2. read_point/write_point 通过适配器正确转发到 DriverWrapper<br>3. 无编译错误（适配器签名已更新） |
| **测试数据** | point_id = Uuid::new_v4(), value = PointValue::Number(42.0) |
| **优先级** | P0 |

**Rust 测试代码示例**：
```rust
#[tokio::test]
async fn test_driver_access_adapter() {
    let mut wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
    wrapper.connect().await.unwrap();
    
    let adapter = DriverAccessAdapter::new(&wrapper);
    
    let point_id = Uuid::new_v4();
    let value = PointValue::Number(42.0);
    
    adapter.write_point(point_id, value.clone()).unwrap();
    let read_value = adapter.read_point(point_id).unwrap();
    
    assert_eq!(read_value, value);
}
```

---

## 6. 并发安全测试

### TC-024: 多线程注册设备

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-024 |
| **测试名称** | 多线程注册设备 |
| **测试目的** | 验证 DeviceManager 在多线程并发注册设备时的线程安全性 |
| **前置条件** | DeviceManager 已创建，支持多线程访问 |
| **测试步骤** | 1. 创建 DeviceManager 的 Arc 引用<br>2. 启动 10 个线程，每个线程注册 10 个设备<br>3. 等待所有线程完成<br>4. 验证 device_count() == 100 |
| **预期结果** | 1. 所有线程完成无 panic<br>2. device_count() == 100<br>3. 无数据竞争或死锁 |
| **测试数据** | 100 个不同的 device_id |
| **优先级** | P1 |

**Rust 测试代码示例**：
```rust
#[test]
fn test_concurrent_register_devices() {
    let manager = Arc::new(DeviceManager::new());
    let mut handles = vec![];
    
    for thread_id in 0..10 {
        let manager_clone = Arc::clone(&manager);
        let handle = std::thread::spawn(move || {
            for i in 0..10 {
                let id = Uuid::new_v4();
                let wrapper = DriverWrapper::new_virtual(VirtualDriver::new());
                manager_clone.register_device(id, wrapper).unwrap();
            }
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    assert_eq!(manager.device_count(), 100);
}
```

---

### TC-025: 多线程读取测点

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-025 |
| **测试名称** | 多线程读取测点 |
| **测试目的** | 验证多线程并发读取同一设备的测点时线程安全 |
| **前置条件** | DeviceManager 已注册设备并已连接 |
| **测试步骤** | 1. 注册并连接一个 VirtualDriver<br>2. 启动 20 个线程，每个线程读取同一测点 100 次<br>3. 等待所有线程完成<br>4. 验证无 panic、无数据竞争 |
| **预期结果** | 1. 所有线程完成无 panic<br>2. 所有 read_point 调用返回 Ok(_)<br>3. 无死锁 |
| **测试数据** | point_id = Uuid::new_v4() |
| **优先级** | P1 |

---

### TC-026: connect_all 并发执行

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-026 |
| **测试名称** | connect_all 并发执行 |
| **测试目的** | 验证 connect_all 在并发场景下的正确性（同时调用多次 connect_all） |
| **前置条件** | DeviceManager 已注册多个设备 |
| **测试步骤** | 1. 注册 5 个设备<br>2. 启动 3 个异步任务，每个任务同时调用 connect_all<br>3. 等待所有任务完成<br>4. 验证所有设备最终状态为已连接 |
| **预期结果** | 1. 所有 connect_all 调用完成<br>2. 所有设备 is_connected() == true<br>3. 无死锁或 panic |
| **测试数据** | 5 个不同的 device_id |
| **优先级** | P1 |

---

## 7. 测试数据需求

### 7.1 设备配置数据

| 配置项 | 值 | 说明 |
|--------|-----|------|
| VirtualConfig::mode | Random / Fixed / Sine / Ramp | 覆盖所有模式 |
| VirtualConfig::data_type | Number / Integer / String / Boolean | 覆盖所有类型 |
| VirtualConfig::access_type | RO / WO / RW | 覆盖所有访问类型 |
| VirtualConfig::min_value | 0.0 | 最小值 |
| VirtualConfig::max_value | 100.0 | 最大值 |
| VirtualConfig::fixed_value | PointValue::Number(42.0) | 固定值 |

### 7.2 Modbus TCP 配置数据

| 配置项 | 值 | 说明 |
|--------|-----|------|
| host | "127.0.0.1" | 本地地址 |
| port | 1502 | 测试端口（非标准 502） |
| slave_id | 1 | 从站ID |
| timeout_ms | 5000 | 超时时间 |

### 7.3 测点数据

| 测点ID | 数据类型 | 访问类型 | 说明 |
|--------|---------|---------|------|
| Uuid::new_v4() | Number | RW | 标准测点 |
| Uuid::new_v4() | Integer | RO | 只读测点 |
| Uuid::new_v4() | Boolean | RW | 布尔测点 |

---

## 8. 测试环境

### 8.1 开发环境

| 项目 | 要求 |
|------|------|
| Rust 版本 | >= 1.75 |
| tokio | 支持 async/await |
| 测试框架 | 内置 test + tokio::test |

### 8.2 测试命令

```bash
# 运行所有测试
cargo test

# 运行特定测试
cargo test test_driver_wrapper
cargo test test_device_manager
cargo test test_backward_compatibility

# 运行并发测试
cargo test test_concurrent -- --test-threads=1

# 生成测试覆盖率报告
cargo tarpaulin --out Html
```

---

## 9. 风险与假设

### 9.1 测试假设

| 假设ID | 描述 |
|--------|------|
| ASM-001 | ModbusTcpDriver 在测试时可用（即使为 stub/mock） |
| ASM-002 | DriverWrapper::new_modbus_tcp 方法在重构后可用 |
| ASM-003 | DriverAccess trait 在重构后保持不变（或向后兼容） |
| ASM-004 | DeviceManager 的 API 签名变化仅限于存储类型 |

### 9.2 测试风险

| 风险ID | 风险描述 | 缓解措施 |
|--------|---------|---------|
| RSK-001 | ModbusTcpDriver 尚未实现，异构测试无法执行 | 使用 mock/stub 替代，或标记为待执行 |
| RSK-002 | 重构后编译错误导致测试无法运行 | 先验证 cargo check，再执行测试 |
| RSK-003 | 并发测试在 CI 环境不稳定 | 增加重试机制，降低并发线程数 |

### 9.3 测试阻塞项

| 阻塞项 | 依赖 | 状态 |
|--------|------|------|
| DriverWrapper 实现 | R1-S1-001-C | 待开发 |
| DeviceManager 重构 | R1-S1-001-C | 待开发 |
| DriverAccessAdapter 重构 | R1-S1-001-C | 待开发 |
| ModbusTcpDriver 实现 | R1-S1-004-C | 待开发（可用 mock 替代） |

---

## 10. 测试用例汇总

| 测试ID | 测试名称 | 优先级 | 类型 | 状态 |
|--------|---------|--------|------|------|
| TC-001 | DriverWrapper 使用 VirtualDriver 创建 | P0 | 单元测试 | 待执行 |
| TC-002 | DriverWrapper 实现 DriverAccess trait | P0 | 单元测试 | 待执行 |
| TC-003 | DriverWrapper 实现 DriverLifecycle trait | P0 | 单元测试 | 待执行 |
| TC-004 | DriverWrapper 读取测点值（Virtual 模式） | P0 | 单元测试 | 待执行 |
| TC-005 | DriverWrapper 写入测点值（Virtual 模式） | P0 | 单元测试 | 待执行 |
| TC-006 | DriverWrapper 连接/断开生命周期 | P1 | 单元测试 | 待执行 |
| TC-007 | DriverWrapper 错误转换 | P0 | 单元测试 | 待执行 |
| TC-008 | DeviceManager 注册 DriverWrapper | P0 | 单元测试 | 待执行 |
| TC-009 | DeviceManager 注销 DriverWrapper | P0 | 单元测试 | 待执行 |
| TC-010 | DeviceManager 获取已注册设备 | P0 | 单元测试 | 待执行 |
| TC-011 | DeviceManager 连接所有设备 | P0 | 集成测试 | 待执行 |
| TC-012 | DeviceManager 断开所有设备 | P0 | 集成测试 | 待执行 |
| TC-013 | DeviceManager 设备计数 | P1 | 单元测试 | 待执行 |
| TC-014 | DeviceManager 重复注册处理 | P1 | 单元测试 | 待执行 |
| TC-015 | DeviceManager 注销不存在设备 | P1 | 单元测试 | 待执行 |
| TC-016 | 同时注册 Virtual 和 Modbus TCP | P0 | 集成测试 | 待执行 |
| TC-017 | 异构驱动的 connect_all | P0 | 集成测试 | 待执行 |
| TC-018 | 异构驱动的 disconnect_all | P0 | 集成测试 | 待执行 |
| TC-019 | 获取不同类型驱动并调用 DriverAccess | P0 | 集成测试 | 待执行 |
| TC-020 | VirtualDriver 向后兼容 | P0 | 回归测试 | 待执行 |
| TC-021 | PointService 读写测点 | P0 | 回归测试 | 待执行 |
| TC-022 | StepEngine 执行试验 | P0 | 回归测试 | 待执行 |
| TC-023 | DriverAccessAdapter 适配 | P0 | 回归测试 | 待执行 |
| TC-024 | 多线程注册设备 | P1 | 并发测试 | 待执行 |
| TC-025 | 多线程读取测点 | P1 | 并发测试 | 待执行 |
| TC-026 | connect_all 并发执行 | P1 | 并发测试 | 待执行 |

---

## 11. 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2026-05-02 | sw-mike | 初始版本，包含 26 个测试用例 |

---

*本文档由 Kayak 项目测试团队维护。如有问题，请联系测试工程师。*
