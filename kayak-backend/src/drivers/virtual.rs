//! 虚拟设备驱动实现

use std::collections::HashMap;
use std::sync::{Arc, Mutex, RwLock};
use uuid::Uuid;
use async_trait::async_trait;
use rand::{Rng, SeedableRng};
use serde::{Serialize, Deserialize};

pub use super::core::{PointValue, VirtualMode, DataType, AccessType, DeviceDriver, DriverError, VirtualConfigError};

/// 虚拟设备驱动配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VirtualConfig {
    /// 数据生成模式
    pub mode: VirtualMode,
    /// 数据类型
    pub data_type: DataType,
    /// 访问类型
    pub access_type: AccessType,
    /// 随机值下界（包含）
    pub min_value: f64,
    /// 随机值上界（不包含）
    pub max_value: f64,
    /// 固定值（Fixed模式下使用）
    pub fixed_value: PointValue,
    /// 采样间隔（毫秒）
    pub sample_interval_ms: u64,
}

impl Default for VirtualConfig {
    fn default() -> Self {
        Self {
            mode: VirtualMode::Random,
            data_type: DataType::Number,
            access_type: AccessType::RO,
            min_value: 0.0,
            max_value: 100.0,
            fixed_value: PointValue::Number(0.0),
            sample_interval_ms: 1000,
        }
    }
}

impl VirtualConfig {
    /// 验证配置有效性（静态方法）
    pub fn validate(config: &VirtualConfig) -> Result<(), VirtualConfigError> {
        if config.min_value >= config.max_value {
            return Err(VirtualConfigError::InvalidRange {
                min: config.min_value,
                max: config.max_value,
            });
        }
        Ok(())
    }

    /// 验证配置有效性（实例方法）
    pub fn validate_self(&self) -> Result<(), VirtualConfigError> {
        Self::validate(self)
    }
}

/// 虚拟设备驱动
///
/// 用于测试和模拟环境，支持多种数据生成模式。
pub struct VirtualDriver {
    config: VirtualConfig,
    connected: bool,
    /// 存储RW测点的用户写入值（使用Arc<Mutex<...>>提供Interior Mutability）
    point_values: Arc<Mutex<HashMap<Uuid, PointValue>>>,
    /// 用于生成随机数
    rng: Arc<RwLock<rand::rngs::StdRng>>,
    /// Sine/Ramp模式的起始时间
    start_time: Arc<RwLock<std::time::Instant>>,
}

// Standalone unsafe impl blocks for Send + Sync
// VirtualDriver contains Arc<RwLock<...>> which is Send + Sync when inner types are
unsafe impl Send for VirtualDriver {}
unsafe impl Sync for VirtualDriver {}

impl Default for VirtualDriver {
    fn default() -> Self {
        Self::new()
    }
}

impl VirtualDriver {
    /// 使用默认配置创建新驱动
    pub fn new() -> Self {
        Self {
            config: VirtualConfig::default(),
            connected: false,
            point_values: Arc::new(Mutex::new(HashMap::new())),
            rng: Arc::new(RwLock::new(rand::rngs::StdRng::from_entropy())),
            start_time: Arc::new(RwLock::new(std::time::Instant::now())),
        }
    }

    /// 使用指定配置创建驱动
    pub fn with_config(config: VirtualConfig) -> Result<Self, VirtualConfigError> {
        VirtualConfig::validate(&config)?;
        Ok(Self {
            config,
            connected: false,
            point_values: Arc::new(Mutex::new(HashMap::new())),
            rng: Arc::new(RwLock::new(rand::rngs::StdRng::from_entropy())),
            start_time: Arc::new(RwLock::new(std::time::Instant::now())),
        })
    }

    /// 获取当前配置引用
    pub fn get_config(&self) -> &VirtualConfig {
        &self.config
    }

    /// 根据模式生成值
    fn generate_value(&self) -> PointValue {
        match self.config.mode {
            VirtualMode::Random => self.generate_random(),
            VirtualMode::Fixed => self.config.fixed_value.clone(),
            VirtualMode::Sine => self.generate_sine(),
            VirtualMode::Ramp => self.generate_ramp(),
        }
    }

    /// 生成随机值
    fn generate_random(&self) -> PointValue {
        let mut rng = self.rng.write().unwrap();
        match self.config.data_type {
            DataType::Number => {
                let r: f64 = rng.gen_range(self.config.min_value..self.config.max_value);
                PointValue::Number(r)
            }
            DataType::Integer => {
                let min_i = self.config.min_value as i64;
                let max_i = self.config.max_value as i64;
                let r: i64 = rng.gen_range(min_i..max_i);
                PointValue::Integer(r)
            }
            DataType::String => {
                // 生成随机字符串
                let len: usize = rng.gen_range(4..12);
                let chars: String = (0..len)
                    .map(|_| {
                        let idx = rng.gen_range(0..26);
                        (b'a' + idx) as char
                    })
                    .collect();
                PointValue::String(chars)
            }
            DataType::Boolean => {
                let r: bool = rng.gen();
                PointValue::Boolean(r)
            }
        }
    }

    /// 生成正弦波值
    fn generate_sine(&self) -> PointValue {
        let start = *self.start_time.read().unwrap();
        let elapsed = start.elapsed().as_secs_f64();
        let period = 2.0 * std::f64::consts::PI;
        let normalized = (elapsed * period / 10.0).sin(); // 10秒一个周期
        let value = normalized * (self.config.max_value - self.config.min_value) / 2.0
            + (self.config.max_value + self.config.min_value) / 2.0;
        PointValue::Number(value)
    }

    /// 生成斜坡值（线性递增，到达最大值后重置）
    fn generate_ramp(&self) -> PointValue {
        let start = *self.start_time.read().unwrap();
        let elapsed = start.elapsed().as_secs_f64();
        let range = self.config.max_value - self.config.min_value;
        let period = 10.0; // 10秒一个周期
        let value = (elapsed % period) / period * range + self.config.min_value;
        PointValue::Number(value)
    }
}

#[async_trait]
impl DeviceDriver for VirtualDriver {
    type Config = VirtualConfig;
    type Error = DriverError;

    async fn connect(&mut self) -> Result<(), Self::Error> {
        if self.connected {
            // 重复连接视为成功（幂等操作）
            return Ok(());
        }
        self.connected = true;
        *self.start_time.write().unwrap() = std::time::Instant::now();
        Ok(())
    }

    async fn disconnect(&mut self) -> Result<(), Self::Error> {
        self.connected = false;
        Ok(())
    }

    fn read_point(&self, point_id: Uuid) -> Result<PointValue, Self::Error> {
        if !self.connected {
            return Err(DriverError::NotConnected);
        }

        // 如果是RW测点且有用户写入的值，返回写入的值
        let point_values = self.point_values.lock().unwrap();
        if let Some(value) = point_values.get(&point_id) {
            return Ok(value.clone());
        }

        Ok(self.generate_value())
    }

    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), Self::Error> {
        if !self.connected {
            return Err(DriverError::NotConnected);
        }

        if self.config.access_type == AccessType::RO {
            return Err(DriverError::ReadOnlyPoint);
        }

        // 类型检查
        match (&self.config.data_type, &value) {
            (DataType::Number, PointValue::Number(_)) => {}
            (DataType::Number, PointValue::Integer(n)) => {
                let mut point_values = self.point_values.lock().unwrap();
                point_values.insert(point_id, PointValue::Number(*n as f64));
                return Ok(());
            }
            (DataType::Integer, PointValue::Integer(_)) => {}
            (DataType::String, PointValue::String(_)) => {}
            (DataType::Boolean, PointValue::Boolean(_)) => {}
            _ => {
                return Err(DriverError::InvalidValue {
                    message: format!("Type mismatch: expected {:?}, got {:?}", self.config.data_type, value)
                });
            }
        }

        let mut point_values = self.point_values.lock().unwrap();
        point_values.insert(point_id, value);
        Ok(())
    }

    fn is_connected(&self) -> bool {
        self.connected
    }
}
