# DeviceManager 泛型消除方案 - 架构设计

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S1-001 |
| 作者 | sw-jerry (Software Architect) |
| 日期 | 2026-05-02 |
| 状态 | 设计完成 |
| 版本 | 1.0 |

---

## 目录

1. [问题分析](#1-问题分析)
2. [方案对比](#2-方案对比)
3. [选型决策](#3-选型决策)
4. [详细设计](#4-详细设计)
5. [代码示例](#5-代码示例)
6. [迁移计划](#6-迁移计划)
7. [风险与缓解](#7-风险与缓解)

---

## 1. 问题分析

### 1.1 当前问题

当前 `DeviceManager` 和 `DriverAccessAdapter` 硬编码绑定到 `VirtualConfig` 和 `DriverError`：

```rust
// DeviceManager 硬编码关联类型
pub struct DeviceManager {
    devices: Arc<RwLock<HashMap<Uuid, Arc<RwLock<dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>>>>>>,
}

// DriverAccessAdapter 同样硬编码
pub struct DriverAccessAdapter<'a> {
    driver: &'a dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>,
}
```

### 1.2 核心矛盾

`DeviceDriver` trait 使用**关联类型**（Associated Types）定义 `Config` 和 `Error`：

```rust
#[async_trait]
pub trait DeviceDriver: Send + Sync {
    type Config: Send + Sync;
    type Error: Send + Sync + std::fmt::Debug + std::fmt::Display + From<DriverError>;
    // ...
}
```

这导致每个实现 `DeviceDriver` 的类型都有**不同的 trait 类型**：
- `VirtualDriver` → `dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>`
- `ModbusTcpDriver` → `dyn DeviceDriver<Config = ModbusTcpConfig, Error = ModbusError>`
- `CanDriver` → `dyn DeviceDriver<Config = CanConfig, Error = CanError>`

这些是不同的类型，无法存储在同一个 `HashMap` 中。

### 1.3 需求约束

| 约束 | 说明 |
|------|------|
| 异构存储 | 同一 DeviceManager 同时管理多种驱动类型 |
| 类型安全 | 尽量减少运行时类型转换（downcast） |
| 向后兼容 | VirtualDriver 继续正常工作 |
| DriverAccess 集成 | 引擎通过 DriverAccess trait 访问设备 |
| 生命周期管理 | 支持 connect/disconnect 等需要 `&mut self` 的操作 |

---

## 2. 方案对比

### 方案A：消除 DeviceDriver 的关联类型

**思路**：将 `Config` 和 `Error` 从关联类型改为方法参数，或使用统一的 Config/Error 类型。

```rust
// 方案A-1: 统一 Error 类型
#[async_trait]
pub trait DeviceDriver: Send + Sync {
    async fn connect(&mut self) -> Result<(), DriverError>;
    async fn disconnect(&mut self) -> Result<(), DriverError>;
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, DriverError>;
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), DriverError>;
    fn is_connected(&self) -> bool;
}

// 方案A-2: 配置通过构造时传入，不从 trait 暴露
#[async_trait]
pub trait DeviceDriver: Send + Sync {
    // Config 不在 trait 中，由具体实现通过构造函数接收
    async fn connect(&mut self) -> Result<(), DriverError>;
    // ...
}
```

**优点**：
- 实现简单，无需类型擦除
- DeviceManager 可直接存储 `dyn DeviceDriver`
- 零运行时开销

**缺点**：
- 丢失了驱动特定的配置类型信息
- 驱动特定错误信息丢失（需统一到 DriverError）
- 违反了"每个驱动有自己的配置和错误类型"的设计意图
- 需要修改所有现有驱动实现

**评估**：❌ **不推荐** - 过度简化，损失了类型系统的表达能力。

---

### 方案B：使用 DriverAccess trait 作为存储类型

**思路**：DeviceManager 存储 `Arc<RwLock<dyn DriverAccess>>`，connect/disconnect 通过单独的管理接口处理。

```rust
// DriverAccess 保持不变（已经是对象安全的）
pub trait DriverAccess: Send + Sync {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError>;
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError>;
}

// DeviceManager 存储 DriverAccess
type ManagedDriver = Arc<RwLock<dyn DriverAccess>>;

pub struct DeviceManager {
    devices: Arc<RwLock<HashMap<Uuid, ManagedDriver>>>,
}
```

**问题**：`DriverAccess` 不包含 `connect`/`disconnect`/`is_connected` 方法。需要额外设计生命周期管理接口。

**扩展设计**：

```rust
// 生命周期管理 trait
#[async_trait]
pub trait DriverLifecycle: Send + Sync {
    async fn connect(&mut self) -> Result<(), DriverError>;
    async fn disconnect(&mut self) -> Result<(), DriverError>;
    fn is_connected(&self) -> bool;
}

// 组合 trait（仅用于内部存储）
pub trait ManagedDevice: DriverAccess + DriverLifecycle {}

// DeviceManager 存储组合类型
type ManagedDriver = Arc<RwLock<dyn ManagedDevice>>;
```

**优点**：
- 与引擎的 DriverAccess 集成自然
- DeviceManager 完全解耦于具体驱动类型
- 类型安全，无需运行时转换

**缺点**：
- 需要拆分 DeviceDriver trait
- 需要为每个驱动实现两个 trait（DriverAccess + DriverLifecycle）
- 现有 VirtualDriver 需要重构

**评估**：⚠️ **部分可行** - 需要较大重构，但架构清晰。

---

### 方案C：类型擦除 + 工厂模式（推荐）

**思路**：定义统一的 `DriverWrapper` 结构体，内部使用 enum 存储具体驱动，提供统一的访问接口。

```rust
// 统一驱动类型枚举
pub enum AnyDriver {
    Virtual(VirtualDriver),
    ModbusTcp(ModbusTcpDriver),
    ModbusRtu(ModbusRtuDriver),
    Can(CanDriver),
    Visa(VisaDriver),
    Mqtt(MqttDriver),
}

// DriverWrapper 提供统一接口
pub struct DriverWrapper {
    inner: AnyDriver,
}

impl DriverAccess for DriverWrapper { ... }
impl DriverLifecycle for DriverWrapper { ... }
```

**优点**：
- 类型安全（编译时检查所有驱动类型）
- 无运行时 downcast 开销
- 扩展新驱动类型时，只需在 enum 中添加变体
- DeviceManager 完全统一

**缺点**：
- 添加新驱动需要修改 enum（违反开闭原则）
- enum 大小由最大变体决定（内存开销）

**评估**：✅ **推荐** - 在 Rust 中，enum 是实现类型擦除的惯用方式，性能优异且类型安全。

---

### 方案D：trait object 类型擦除（Box<dyn Any>）

**思路**：使用 `Box<dyn Any>` 存储驱动，运行时 downcast。

```rust
pub struct DriverWrapper {
    inner: Box<dyn Any + Send + Sync>,
    // 通过函数指针表实现接口分发
    vtable: DriverVTable,
}

struct DriverVTable {
    read_point: unsafe fn(*const (), Uuid) -> Result<PointValue, DriverError>,
    write_point: unsafe fn(*const (), Uuid, PointValue) -> Result<(), DriverError>,
    // ...
}
```

**优点**：
- 完全动态，添加新驱动无需修改 wrapper
- 符合开闭原则

**缺点**：
- 需要手动实现 vtable（复杂且容易出错）
- 运行时 downcast 有性能开销
- 类型安全性降低
- 需要 unsafe 代码

**评估**：❌ **不推荐** - 过于复杂，unsafe 代码增加维护成本。

---

## 3. 选型决策

### 3.1 决策矩阵

| 评估维度 | 权重 | 方案A | 方案B | 方案C | 方案D |
|---------|------|-------|-------|-------|-------|
| 类型安全 | 高 | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 实现复杂度 | 高 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 性能 | 中 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 可扩展性 | 高 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 向后兼容 | 高 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 与引擎集成 | 高 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **综合评分** | | 3.2 | 3.9 | **4.5** | 3.4 |

### 3.2 最终选择：方案C（类型擦除 + enum）

选择理由：

1. **Rust 惯用法**：在 Rust 中，enum 是实现代数数据类型（ADT）和类型擦除的标准方式
2. **零成本抽象**：enum 分发是编译时确定的，无运行时开销
3. **类型安全**：所有驱动类型在编译时已知，无需 downcast
4. **与 DriverAccess 自然集成**：`DriverWrapper` 可直接实现 `DriverAccess`
5. **向后兼容**：`VirtualDriver` 作为 enum 变体继续工作

### 3.3 架构原则遵循

| 原则 | 体现 |
|------|------|
| **单一职责（SRP）** | `DriverWrapper` 只负责类型擦除，`DeviceManager` 只负责生命周期管理 |
| **开闭原则（OCP）** | 新驱动通过扩展 enum 变体添加（虽然需要修改 enum，但修改范围集中） |
| **里氏替换（LSP）** | 所有驱动通过统一接口访问，行为一致 |
| **接口隔离（ISP）** | `DriverAccess` 和 `DriverLifecycle` 分离，引擎只依赖 `DriverAccess` |
| **依赖倒置（DIP）** | `StepEngine` 依赖 `DriverAccess` trait，不依赖具体驱动 |

---

## 4. 详细设计

### 4.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                         │
├─────────────────────────────────────────────────────────────────┤
│  API Handlers  │  Experiment Service  │  Device Service         │
├─────────────────────────────────────────────────────────────────┤
│                        DeviceManager                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  HashMap<Uuid, Arc<RwLock<DriverWrapper>>>               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │   │
│  │  │ DriverWrapper │  │ DriverWrapper │  │ DriverWrapper │   │   │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │   │
│  │  │ │AnyDriver │ │  │ │AnyDriver │ │  │ │AnyDriver │ │   │   │
│  │  │ │::Virtual │ │  │ │::Modbus  │ │  │ │::Can     │ │   │   │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  DriverWrapper  implements  DriverAccess + DriverLifecycle       │
├─────────────────────────────────────────────────────────────────┤
│  VirtualDriver │ ModbusTcpDriver │ CanDriver │ ...              │
│  (DeviceDriver trait)                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      StepEngine (执行引擎)                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  execute(process_def, device_id)                         │   │
│  │    └──> device_manager.get_device(device_id)             │   │
│  │         └──> DriverAccessAdapter::new(&driver)           │   │
│  │              └──> &dyn DriverAccess                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 核心组件设计

#### 4.2.1 统一错误类型 `DriverError`

保持现有的 `DriverError`，但扩展以支持驱动特定错误：

```rust
/// 设备驱动错误类型
#[derive(Debug, Clone)]
pub enum DriverError {
    NotConnected,
    AlreadyConnected,
    Timeout { duration: Duration },
    InvalidValue { message: String },
    ReadOnlyPoint,
    ConfigError(String),
    IoError(String),
    // 新增：驱动特定错误（保留原始错误信息）
    DriverSpecific { driver_type: String, message: String },
}
```

#### 4.2.2 统一配置类型 `DriverConfig`

```rust
/// 驱动配置枚举
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "protocol_type", rename_all = "snake_case")]
pub enum DriverConfig {
    Virtual(VirtualConfig),
    ModbusTcp(ModbusTcpConfig),
    ModbusRtu(ModbusRtuRtuConfig),
    Can(CanConfig),
    Visa(VisaConfig),
    Mqtt(MqttConfig),
}
```

#### 4.2.3 统一驱动枚举 `AnyDriver`

```rust
/// 统一驱动类型枚举
/// 
/// 所有设备驱动的类型擦除包装。使用 enum 而非 trait object 的原因：
/// 1. 编译时分发，零运行时开销
/// 2. 类型安全，无需 downcast
/// 3. Rust 惯用的 ADT 实现方式
pub enum AnyDriver {
    Virtual(VirtualDriver),
    ModbusTcp(ModbusTcpDriver),
    ModbusRtu(ModbusRtuDriver),
    Can(CanDriver),
    Visa(VisaDriver),
    Mqtt(MqttDriver),
}
```

#### 4.2.4 驱动包装器 `DriverWrapper`

```rust
/// 驱动包装器
///
/// 为 AnyDriver 提供统一接口，实现 DriverAccess 和 DriverLifecycle。
/// 这是 DeviceManager 实际存储的类型。
pub struct DriverWrapper {
    inner: AnyDriver,
}

impl DriverWrapper {
    pub fn new_virtual(driver: VirtualDriver) -> Self {
        Self { inner: AnyDriver::Virtual(driver) }
    }
    
    pub fn new_modbus_tcp(driver: ModbusTcpDriver) -> Self {
        Self { inner: AnyDriver::ModbusTcp(driver) }
    }
    
    // ... 其他构造函数
}

// 实现 DriverLifecycle（连接管理）
#[async_trait]
impl DriverLifecycle for DriverWrapper {
    async fn connect(&mut self) -> Result<(), DriverError> {
        match &mut self.inner {
            AnyDriver::Virtual(d) => d.connect().await.map_err(Into::into),
            AnyDriver::ModbusTcp(d) => d.connect().await.map_err(Into::into),
            // ...
        }
    }
    
    async fn disconnect(&mut self) -> Result<(), DriverError> {
        match &mut self.inner {
            AnyDriver::Virtual(d) => d.disconnect().await.map_err(Into::into),
            AnyDriver::ModbusTcp(d) => d.disconnect().await.map_err(Into::into),
            // ...
        }
    }
    
    fn is_connected(&self) -> bool {
        match &self.inner {
            AnyDriver::Virtual(d) => d.is_connected(),
            AnyDriver::ModbusTcp(d) => d.is_connected(),
            // ...
        }
    }
}

// 实现 DriverAccess（引擎访问接口）
impl DriverAccess for DriverWrapper {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        match &self.inner {
            AnyDriver::Virtual(d) => d.read_point(point_id).map_err(Into::into),
            AnyDriver::ModbusTcp(d) => d.read_point(point_id).map_err(Into::into),
            // ...
        }
    }
    
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        match &self.inner {
            AnyDriver::Virtual(d) => d.write_point(point_id, value).map_err(Into::into),
            AnyDriver::ModbusTcp(d) => d.write_point(point_id, value).map_err(Into::into),
            // ...
        }
    }
}
```

#### 4.2.5 重构后的 DeviceManager

```rust
/// 设备管理器
///
/// 管理所有设备的生命周期，支持异构驱动类型。
pub struct DeviceManager {
    devices: Arc<RwLock<HashMap<Uuid, Arc<RwLock<DriverWrapper>>>>>,
}

impl DeviceManager {
    pub fn new() -> Self { ... }
    
    /// 注册设备（接受 DriverWrapper）
    pub fn register_device(&self, id: Uuid, driver: DriverWrapper) -> Result<(), DriverError> { ... }
    
    /// 获取设备（返回 DriverWrapper，可直接作为 DriverAccess 使用）
    pub fn get_device(&self, id: Uuid) -> Option<Arc<RwLock<DriverWrapper>>> { ... }
    
    /// 连接所有设备
    pub async fn connect_all(&self) -> Vec<Result<Uuid, (Uuid, DriverError)>> { ... }
    
    /// 断开所有设备
    pub async fn disconnect_all(&self) -> Vec<Result<Uuid, (Uuid, DriverError)>> { ... }
}
```

#### 4.2.6 重构后的 DriverAccessAdapter

```rust
/// DriverAccess 适配器
///
/// 将 DriverWrapper 的引用适配为 DriverAccess trait 对象。
/// 由于 DriverWrapper 已经实现了 DriverAccess，此适配器可大幅简化。
pub struct DriverAccessAdapter<'a> {
    driver: &'a dyn DriverAccess,
}

impl<'a> DriverAccessAdapter<'a> {
    pub fn new(driver: &'a dyn DriverAccess) -> Self {
        Self { driver }
    }
}

impl<'a> DriverAccess for DriverAccessAdapter<'a> {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        self.driver.read_point(point_id)
    }
    
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        self.driver.write_point(point_id, value)
    }
}
```

> **注意**：实际上，由于 `DriverWrapper` 直接实现了 `DriverAccess`，`DriverAccessAdapter` 可以进一步简化甚至移除。保留它是为了保持与现有引擎代码的兼容性，并允许未来添加额外的适配逻辑（如日志、 metrics 等）。

### 4.3 模块结构

```
src/drivers/
├── mod.rs              # 模块导出
├── core.rs             # 核心类型：PointValue, DataType, AccessType, VirtualMode
├── error.rs            # 错误类型：DriverError, VirtualConfigError
├── config.rs           # 统一配置：DriverConfig, VirtualConfig, ModbusTcpConfig, ...
├── traits.rs           # Trait 定义：DeviceDriver, DriverAccess, DriverLifecycle
├── wrapper.rs          # 类型擦除：AnyDriver, DriverWrapper
├── manager.rs          # 设备管理器：DeviceManager
├── factory.rs          # 驱动工厂：DriverFactory（根据 ProtocolType 创建驱动）
├── virtual.rs          # 虚拟驱动：VirtualDriver
├── modbus_tcp.rs       # Modbus TCP 驱动（未来）
├── modbus_rtu.rs       # Modbus RTU 驱动（未来）
├── can.rs              # CAN 驱动（未来）
├── visa.rs             # VISA 驱动（未来）
└── mqtt.rs             # MQTT 驱动（未来）
```

### 4.4 驱动工厂

```rust
/// 驱动工厂
///
/// 根据 ProtocolType 和配置创建对应的 DriverWrapper。
/// 这是创建驱动的唯一入口，集中管理驱动实例化逻辑。
pub struct DriverFactory;

impl DriverFactory {
    /// 创建驱动
    pub fn create(protocol: ProtocolType, config: DriverConfig) -> Result<DriverWrapper, DriverError> {
        match (protocol, config) {
            (ProtocolType::Virtual, DriverConfig::Virtual(cfg)) => {
                let driver = VirtualDriver::with_config(cfg)
                    .map_err(|e| DriverError::ConfigError(e.to_string()))?;
                Ok(DriverWrapper::new_virtual(driver))
            }
            (ProtocolType::ModbusTcp, DriverConfig::ModbusTcp(cfg)) => {
                let driver = ModbusTcpDriver::new(cfg)?;
                Ok(DriverWrapper::new_modbus_tcp(driver))
            }
            // ...
            _ => Err(DriverError::ConfigError(
                format!("Protocol type {:?} does not match config type", protocol)
            )),
        }
    }
    
    /// 从 Device 实体创建驱动
    pub fn from_device(device: &Device) -> Result<DriverWrapper, DriverError> {
        let config: DriverConfig = serde_json::from_value(
            device.protocol_params.clone().unwrap_or(serde_json::Value::Null)
        ).map_err(|e| DriverError::ConfigError(e.to_string()))?;
        
        Self::create(device.protocol_type, config)
    }
}
```

---

## 5. 代码示例

### 5.1 完整的核心代码

```rust
// ==================== src/drivers/traits.rs ====================

use async_trait::async_trait;
use uuid::Uuid;

use super::core::PointValue;
use super::error::DriverError;
use crate::engine::types::ExecutionError;

/// 设备驱动生命周期管理 trait
///
/// 定义连接、断开等需要可变访问的操作。
#[async_trait]
pub trait DriverLifecycle: Send + Sync {
    async fn connect(&mut self) -> Result<(), DriverError>;
    async fn disconnect(&mut self) -> Result<(), DriverError>;
    fn is_connected(&self) -> bool;
}

/// 设备测点访问 trait
///
/// 为引擎提供统一的测点读写接口。
/// 与 engine::executor::DriverAccess 保持一致。
pub trait PointAccess: Send + Sync {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError>;
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError>;
}

/// 设备驱动核心 trait（保留给具体驱动实现）
///
/// 具体驱动（VirtualDriver, ModbusTcpDriver 等）实现此 trait。
/// 通过 DriverWrapper 类型擦除后，对外暴露 DriverLifecycle + PointAccess。
#[async_trait]
pub trait DeviceDriver: Send + Sync + DriverLifecycle + PointAccess {
    type Config: Send + Sync;
    type Error: Send + Sync + std::fmt::Debug + std::fmt::Display + From<DriverError>;
    
    fn from_config(config: Self::Config) -> Result<Self, Self::Error> where Self: Sized;
}
```

```rust
// ==================== src/drivers/wrapper.rs ====================

use async_trait::async_trait;
use uuid::Uuid;

use super::core::PointValue;
use super::error::DriverError;
use super::traits::{DriverLifecycle, PointAccess};
use super::virtual::VirtualDriver;
use crate::engine::types::ExecutionError;

/// 统一驱动类型枚举
pub enum AnyDriver {
    Virtual(VirtualDriver),
    // 未来扩展：
    // ModbusTcp(ModbusTcpDriver),
    // ModbusRtu(ModbusRtuDriver),
    // Can(CanDriver),
    // Visa(VisaDriver),
    // Mqtt(MqttDriver),
}

/// 驱动包装器
///
/// 为所有驱动类型提供统一接口。
pub struct DriverWrapper {
    inner: AnyDriver,
}

impl DriverWrapper {
    pub fn new_virtual(driver: VirtualDriver) -> Self {
        Self { inner: AnyDriver::Virtual(driver) }
    }
    
    // 未来扩展：
    // pub fn new_modbus_tcp(driver: ModbusTcpDriver) -> Self { ... }
}

#[async_trait]
impl DriverLifecycle for DriverWrapper {
    async fn connect(&mut self) -> Result<(), DriverError> {
        match &mut self.inner {
            AnyDriver::Virtual(d) => {
                <VirtualDriver as DriverLifecycle>::connect(d).await
            }
        }
    }
    
    async fn disconnect(&mut self) -> Result<(), DriverError> {
        match &mut self.inner {
            AnyDriver::Virtual(d) => {
                <VirtualDriver as DriverLifecycle>::disconnect(d).await
            }
        }
    }
    
    fn is_connected(&self) -> bool {
        match &self.inner {
            AnyDriver::Virtual(d) => d.is_connected(),
        }
    }
}

impl PointAccess for DriverWrapper {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        match &self.inner {
            AnyDriver::Virtual(d) => d.read_point(point_id).map_err(|e| {
                ExecutionError::DriverError(e.to_string())
            }),
        }
    }
    
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        match &self.inner {
            AnyDriver::Virtual(d) => d.write_point(point_id, value).map_err(|e| {
                ExecutionError::DriverError(e.to_string())
            }),
        }
    }
}
```

```rust
// ==================== src/drivers/manager.rs ====================

use futures::future::join_all;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use uuid::Uuid;

use super::error::DriverError;
use super::traits::DriverLifecycle;
use super::wrapper::DriverWrapper;

pub struct DeviceManager {
    devices: Arc<RwLock<HashMap<Uuid, Arc<RwLock<DriverWrapper>>>>>,
}

impl DeviceManager {
    pub fn new() -> Self {
        Self {
            devices: Arc::new(RwLock::new(HashMap::new())),
        }
    }
    
    pub fn register_device(&self, id: Uuid, driver: DriverWrapper) -> Result<(), DriverError> {
        let mut devices = self.devices.write().unwrap();
        if devices.contains_key(&id) {
            return Err(DriverError::ConfigError(format!(
                "Device {} already registered", id
            )));
        }
        devices.insert(id, Arc::new(RwLock::new(driver)));
        Ok(())
    }
    
    pub fn unregister_device(&self, id: Uuid) -> Result<(), DriverError> {
        let mut devices = self.devices.write().unwrap();
        if devices.remove(&id).is_none() {
            return Err(DriverError::ConfigError(format!("Device {} not found", id)));
        }
        Ok(())
    }
    
    pub fn get_device(&self, id: Uuid) -> Option<Arc<RwLock<DriverWrapper>>> {
        let devices = self.devices.read().unwrap();
        devices.get(&id).cloned()
    }
    
    pub async fn connect_all(&self) -> Vec<Result<Uuid, (Uuid, DriverError)>> {
        let device_locks: Vec<_> = {
            let devices = self.devices.read().unwrap();
            devices.iter().map(|(id, driver_lock)| (*id, Arc::clone(driver_lock))).collect()
        };
        
        let futures = device_locks.into_iter().map(|(id, driver_lock)| async move {
            let mut driver = driver_lock.write().unwrap();
            match driver.connect().await {
                Ok(()) => Ok(id),
                Err(e) => Err((id, e)),
            }
        });
        
        join_all(futures).await
    }
    
    pub async fn disconnect_all(&self) -> Vec<Result<Uuid, (Uuid, DriverError)>> {
        let device_locks: Vec<_> = {
            let devices = self.devices.read().unwrap();
            devices.iter().map(|(id, driver_lock)| (*id, Arc::clone(driver_lock))).collect()
        };
        
        let futures = device_locks.into_iter().map(|(id, driver_lock)| async move {
            let mut driver = driver_lock.write().unwrap();
            match driver.disconnect().await {
                Ok(()) => Ok(id),
                Err(e) => Err((id, e)),
            }
        });
        
        join_all(futures).await
    }
    
    pub fn device_count(&self) -> usize {
        self.devices.read().unwrap().len()
    }
}

impl Default for DeviceManager {
    fn default() -> Self {
        Self::new()
    }
}
```

```rust
// ==================== src/engine/adapter.rs ====================

use uuid::Uuid;

use super::executor::DriverAccess;
use super::types::ExecutionError;
use crate::drivers::core::PointValue;

/// DriverAccess 适配器
///
/// 将 PointAccess trait 对象适配为 DriverAccess trait 对象。
/// 由于 DriverWrapper 已实现 PointAccess，此适配器提供了一层薄包装。
pub struct DriverAccessAdapter<'a> {
    driver: &'a dyn DriverAccess,
}

impl<'a> DriverAccessAdapter<'a> {
    pub fn new(driver: &'a dyn DriverAccess) -> Self {
        Self { driver }
    }
}

impl<'a> DriverAccess for DriverAccessAdapter<'a> {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        self.driver.read_point(point_id)
    }
    
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        self.driver.write_point(point_id, value)
    }
}
```

### 5.2 使用示例

```rust
use kayak_backend::drivers::*;
use kayak_backend::engine::*;
use std::sync::Arc;
use uuid::Uuid;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 创建设备管理器
    let manager = Arc::new(DeviceManager::new());
    
    // 注册虚拟设备
    let virtual_id = Uuid::new_v4();
    let virtual_driver = VirtualDriver::new();
    manager.register_device(virtual_id, DriverWrapper::new_virtual(virtual_driver))?;
    
    // 未来：注册 Modbus TCP 设备
    // let modbus_id = Uuid::new_v4();
    // let modbus_config = ModbusTcpConfig { host: "192.168.1.1".to_string(), port: 502 };
    // let modbus_driver = ModbusTcpDriver::new(modbus_config)?;
    // manager.register_device(modbus_id, DriverWrapper::new_modbus_tcp(modbus_driver))?;
    
    // 连接所有设备
    let results = manager.connect_all().await;
    for result in results {
        match result {
            Ok(id) => println!("Device {} connected", id),
            Err((id, e)) => eprintln!("Failed to connect device {}: {}", id, e),
        }
    }
    
    // 使用引擎执行过程
    let engine = StepEngine::new(manager.clone(), None);
    let process_def = ProcessDefinition::from_json_str(r#"{"version":"1.0","steps":[...]}"#)?;
    let context = engine.execute(&process_def, virtual_id).await?;
    
    println!("Execution completed: {:?}", context.status);
    
    // 断开所有设备
    manager.disconnect_all().await;
    
    Ok(())
}
```

---

## 6. 迁移计划

### 6.1 迁移步骤

#### Step 1: 创建新的 trait 和类型（1天）

1. 创建 `src/drivers/traits.rs`：
   - 定义 `DriverLifecycle` trait
   - 定义 `PointAccess` trait
   - 修改 `DeviceDriver` trait（继承 DriverLifecycle + PointAccess）

2. 创建 `src/drivers/wrapper.rs`：
   - 定义 `AnyDriver` enum
   - 定义 `DriverWrapper` struct
   - 实现 `DriverLifecycle` for `DriverWrapper`
   - 实现 `PointAccess` for `DriverWrapper`

3. 创建 `src/drivers/config.rs`：
   - 定义 `DriverConfig` enum
   - 移动 `VirtualConfig` 到该文件

#### Step 2: 重构 DeviceManager（0.5天）

1. 修改 `src/drivers/manager.rs`：
   - 将存储类型改为 `Arc<RwLock<DriverWrapper>>`
   - 更新 `register_device` 签名
   - 更新 `get_device` 返回类型
   - 更新 `connect_all` / `disconnect_all`

#### Step 3: 重构 DriverAccessAdapter（0.5天）

1. 修改 `src/engine/adapter.rs`：
   - 将 `driver` 字段类型改为 `&'a dyn DriverAccess`
   - 移除对 `VirtualConfig` 和 `DriverError` 的硬编码依赖

#### Step 4: 重构 VirtualDriver（0.5天）

1. 修改 `src/drivers/virtual.rs`：
   - 实现 `DriverLifecycle` for `VirtualDriver`
   - 实现 `PointAccess` for `VirtualDriver`
   - 保留 `DeviceDriver` 实现（用于向后兼容）

#### Step 5: 更新模块导出和依赖（0.5天）

1. 修改 `src/drivers/mod.rs`：
   - 导出新的 trait 和类型
   - 保持向后兼容的导出

2. 修改 `src/engine/mod.rs`：
   - 更新导出

#### Step 6: 更新 StepEngine（0.5天）

1. 修改 `src/engine/step_engine.rs`：
   - 更新 `get_device` 调用
   - 更新 `DriverAccessAdapter::new` 调用

#### Step 7: 更新测试（1天）

1. 更新所有使用 DeviceManager 的测试
2. 更新所有使用 DriverAccessAdapter 的测试
3. 确保所有测试通过

#### Step 8: 代码审查和合并（0.5天）

1. 进行代码审查
2. 修复发现的问题
3. 合并到主分支

### 6.2 时间估算

| 步骤 | 工作量 | 依赖 |
|------|--------|------|
| Step 1: 创建新 trait 和类型 | 1天 | 无 |
| Step 2: 重构 DeviceManager | 0.5天 | Step 1 |
| Step 3: 重构 DriverAccessAdapter | 0.5天 | Step 1 |
| Step 4: 重构 VirtualDriver | 0.5天 | Step 1 |
| Step 5: 更新模块导出 | 0.5天 | Step 1-4 |
| Step 6: 更新 StepEngine | 0.5天 | Step 2, 3 |
| Step 7: 更新测试 | 1天 | Step 1-6 |
| Step 8: 审查和合并 | 0.5天 | Step 7 |
| **总计** | **5天** | |

### 6.3 向后兼容策略

1. **VirtualDriver 保持不变**：
   - 继续实现 `DeviceDriver` trait
   - 现有代码无需修改

2. **DeviceManager API 变化**：
   ```rust
   // 旧代码（不再工作）
   manager.register_device(id, VirtualDriver::new())?;
   
   // 新代码
   manager.register_device(id, DriverWrapper::new_virtual(VirtualDriver::new()))?;
   ```

3. **提供便捷方法**（可选）：
   ```rust
   impl DeviceManager {
       /// 便捷方法：直接注册虚拟驱动
       pub fn register_virtual_device(&self, id: Uuid, driver: VirtualDriver) -> Result<(), DriverError> {
           self.register_device(id, DriverWrapper::new_virtual(driver))
       }
   }
   ```

### 6.4 迁移检查清单

- [ ] 新 trait 和类型创建完成
- [ ] DeviceManager 重构完成
- [ ] DriverAccessAdapter 重构完成
- [ ] VirtualDriver 实现新 trait
- [ ] 模块导出更新完成
- [ ] StepEngine 更新完成
- [ ] 所有单元测试通过
- [ ] 所有集成测试通过
- [ ] 代码审查完成
- [ ] 文档更新完成

---

## 7. 风险与缓解

### 7.1 风险矩阵

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|----------|
| enum 变体膨胀 | 中 | 中 | 使用 `#[repr(C)]` 和 `Box` 减少内存占用；或未来迁移到方案D |
| 添加新驱动需修改 enum | 高 | 低 | 修改范围集中（仅 wrapper.rs），影响可控 |
| 编译时间增加 | 低 | 低 | enum match 分发是编译时优化，无显著影响 |
| 测试覆盖率下降 | 中 | 高 | 确保所有现有测试更新并通过；添加新驱动的单元测试 |
| 与现有代码冲突 | 中 | 中 | 分步骤迁移，每步验证；使用 feature flag 控制 |

### 7.2 设计决策记录（ADR）

#### ADR-001: 使用 enum 而非 trait object 进行类型擦除

**背景**：DeviceManager 需要存储异构驱动类型。

**决策**：使用 `AnyDriver` enum 进行类型擦除。

**原因**：
1. Rust enum 是零成本抽象，编译时分发
2. 类型安全，无需运行时 downcast
3. 与 `DriverWrapper` 结合，提供统一接口

**替代方案**：使用 `Box<dyn Any>` + vtable（方案D），但过于复杂且需要 unsafe。

**后果**：
- 正面：高性能、类型安全、代码清晰
- 负面：添加新驱动需要修改 enum（违反开闭原则，但在 Rust 中是可接受的权衡）

---

## 8. 附录

### 8.1 术语表

| 术语 | 定义 |
|------|------|
| 类型擦除（Type Erasure） | 将具体类型隐藏为统一接口的技术 |
| 关联类型（Associated Type） | Rust trait 中定义的占位符类型，由实现者指定 |
| 对象安全（Object Safe） | trait 可以作为 `dyn Trait` 使用的特性 |
| ADT（Algebraic Data Type） | 代数数据类型，Rust enum 是其具体实现 |

### 8.2 参考文档

- [Rust Book - Enums](https://doc.rust-lang.org/book/ch06-00-enums.html)
- [Rust Reference - Trait Objects](https://doc.rust-lang.org/reference/types/trait-object.html)
- [Rust API Guidelines - Type Safety](https://rust-lang.github.io/api-guidelines/type-safety.html)

---

## 9. 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2026-05-02 | sw-jerry | 初始版本 |

---

*本文档由 Kayak 项目架构团队维护。如有问题，请联系项目架构师。*
