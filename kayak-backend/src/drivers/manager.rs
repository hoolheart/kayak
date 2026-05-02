//! 设备管理器实现
//!
//! 管理所有设备的生命周期，支持异构驱动类型。
//! 使用 DriverWrapper 统一封装所有驱动类型，消除泛型硬编码。

use futures::future::join_all;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use uuid::Uuid;

use super::error::DriverError;
use super::lifecycle::DriverLifecycle;
use super::wrapper::DriverWrapper;

/// 设备管理器
///
/// 负责管理所有设备的生命周期，支持批量操作。
/// 存储 `Arc<RwLock<DriverWrapper>>`，支持异构驱动类型。
pub struct DeviceManager {
    devices: Arc<RwLock<HashMap<Uuid, Arc<RwLock<DriverWrapper>>>>>,
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
    /// * `driver` - 设备驱动包装器（DriverWrapper）
    pub fn register_device(
        &self,
        id: Uuid,
        driver: DriverWrapper,
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
    /// 返回 `Arc<RwLock<DriverWrapper>>`，可直接作为 DriverAccess 使用。
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
    ) -> Option<Arc<RwLock<DriverWrapper>>> {
        let devices = self.devices.read().unwrap();
        devices.get(&id).cloned()
    }

    /// 连接所有已注册设备
    ///
    /// 遍历所有已注册的设备并尝试连接它们。
    /// 使用 `join_all` 并行执行所有连接操作。
    pub async fn connect_all(
        &self,
    ) -> Vec<Result<Uuid, (Uuid, DriverError)>> {
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
                Arc<RwLock<DriverWrapper>>,
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
    pub async fn disconnect_all(
        &self,
    ) -> Vec<Result<Uuid, (Uuid, DriverError)>> {
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
                Arc<RwLock<DriverWrapper>>,
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::factory::DriverFactory;

    #[test]
    fn test_register_and_get_device() {
        let manager = DeviceManager::new();
        let id = Uuid::new_v4();
        let driver = DriverFactory::create_virtual_default();

        manager.register_device(id, driver).unwrap();
        assert_eq!(manager.device_count(), 1);

        let retrieved = manager.get_device(id);
        assert!(retrieved.is_some());
    }

    #[test]
    fn test_unregister_device() {
        let manager = DeviceManager::new();
        let id = Uuid::new_v4();
        let driver = DriverFactory::create_virtual_default();

        manager.register_device(id, driver).unwrap();
        manager.unregister_device(id).unwrap();
        assert_eq!(manager.device_count(), 0);
    }

    #[test]
    fn test_register_duplicate_device() {
        let manager = DeviceManager::new();
        let id = Uuid::new_v4();
        let driver1 = DriverFactory::create_virtual_default();
        let driver2 = DriverFactory::create_virtual_default();

        manager.register_device(id, driver1).unwrap();
        let result = manager.register_device(id, driver2);
        assert!(result.is_err());
    }
}
