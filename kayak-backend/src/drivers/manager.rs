//! 设备管理器实现

use futures::future::join_all;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use uuid::Uuid;

pub use super::core::{DeviceDriver, DriverError};
pub use super::r#virtual::VirtualConfig;

/// 设备管理器
///
/// 负责管理所有设备的生命周期，支持批量操作。
///
/// # 存储设计说明
///
/// 设备存储使用 `Arc<RwLock<dyn DeviceDriver>>` 而不是简单的 `Arc<dyn DeviceDriver>`，
/// 这是因为 `DeviceDriver` trait 的 `connect()` 和 `disconnect()` 方法需要 `&mut self`。
///
/// 通过将每个驱动包装在 `RwLock` 中，我们可以：
/// 1. 通过 `Arc<RwLock<...>>` 提供安全的共享访问
/// 2. 使用 `.write().unwrap()` 获取 `&mut dyn DeviceDriver` 来调用需要可变引用的方法
/// 3. 保持线程安全性，同时支持可变操作
#[allow(clippy::type_complexity)]
pub struct DeviceManager {
    devices: Arc<
        RwLock<
            HashMap<
                Uuid,
                Arc<RwLock<dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>>>,
            >,
        >,
    >,
}

#[allow(clippy::await_holding_lock)]
impl DeviceManager {
    /// 创建新的设备管理器
    pub fn new() -> Self {
        Self {
            devices: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// 注册设备
    ///
    /// # Arguments
    /// * `id` - 设备唯一标识
    /// * `driver` - 设备驱动实例
    pub fn register_device<
        D: DeviceDriver<Config = VirtualConfig, Error = DriverError> + 'static,
    >(
        &self,
        id: Uuid,
        driver: D,
    ) -> Result<(), DriverError> {
        let mut devices = self.devices.write().unwrap();
        if devices.contains_key(&id) {
            return Err(DriverError::ConfigError(format!(
                "Device {} already registered",
                id
            )));
        }
        // 将驱动包装在 RwLock 中以支持可变访问
        devices.insert(id, Arc::new(RwLock::new(driver)));
        Ok(())
    }

    /// 注销设备
    pub fn unregister_device(&self, id: Uuid) -> Result<(), DriverError> {
        let mut devices = self.devices.write().unwrap();
        if devices.remove(&id).is_none() {
            return Err(DriverError::ConfigError(format!("Device {} not found", id)));
        }
        Ok(())
    }

    /// 获取设备驱动引用
    ///
    /// 返回 `Arc<RwLock<dyn DeviceDriver>>` 以允许调用者获取可变访问权限。
    /// 使用者需要通过锁来调用 `connect()` 或 `disconnect()` 等需要 `&mut self` 的方法。
    ///
    /// # Example
    /// ```ignore
    /// if let Some(driver_lock) = manager.get_device(id) {
    ///     let mut driver = driver_lock.write().unwrap();
    ///     driver.connect().await?;
    /// }
    /// ```
    pub fn get_device(
        &self,
        id: Uuid,
    ) -> Option<Arc<RwLock<dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>>>> {
        let devices = self.devices.read().unwrap();
        devices.get(&id).cloned()
    }

    /// 连接所有已注册设备
    ///
    /// 遍历所有已注册的设备并尝试连接它们。
    /// 使用 `join_all` 并行执行所有连接操作。
    pub async fn connect_all(&self) -> Vec<Result<Uuid, (Uuid, DriverError)>> {
        let device_locks: Vec<_> = {
            let devices = self.devices.read().unwrap();
            devices
                .iter()
                .map(|(id, driver_lock)| (*id, Arc::clone(driver_lock)))
                .collect()
        };

        let futures = device_locks.into_iter().map(
            |(id, driver_lock): (
                Uuid,
                Arc<RwLock<dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>>>,
            )| async move {
                // 获取可变访问权限
                let mut driver = driver_lock.write().unwrap();
                match driver.connect().await {
                    Ok(()) => Ok(id),
                    Err(e) => Err((id, e)),
                }
            },
        );

        join_all(futures).await
    }

    /// 断开所有设备连接
    ///
    /// 遍历所有已注册的设备并断开连接。
    /// 使用 `join_all` 并行执行所有断开操作。
    pub async fn disconnect_all(&self) -> Vec<Result<Uuid, (Uuid, DriverError)>> {
        let device_locks: Vec<_> = {
            let devices = self.devices.read().unwrap();
            devices
                .iter()
                .map(|(id, driver_lock)| (*id, Arc::clone(driver_lock)))
                .collect()
        };

        let futures = device_locks.into_iter().map(
            |(id, driver_lock): (
                Uuid,
                Arc<RwLock<dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>>>,
            )| async move {
                // 获取可变访问权限
                let mut driver = driver_lock.write().unwrap();
                match driver.disconnect().await {
                    Ok(()) => Ok(id),
                    Err(e) => Err((id, e)),
                }
            },
        );

        join_all(futures).await
    }

    /// 获取已注册设备数量
    pub fn device_count(&self) -> usize {
        self.devices.read().unwrap().len()
    }
}

impl Default for DeviceManager {
    fn default() -> Self {
        Self::new()
    }
}
