//! DriverAccess 适配器
//!
//! 将具体驱动实例适配为 DriverAccess trait 对象，供 StepExecutor 使用。
//! 此适配器在引擎内部创建，对外屏蔽具体驱动类型。
//!
//! # 技术债务 (TODO)
//! 当前实现绑定到 VirtualConfig/DriverError 关联类型。这是因为 DeviceManager
//! 当前只支持 VirtualDriver。未来添加其他驱动类型时，应重构 DeviceManager
//! 使其返回 `&dyn DriverAccess` 而非 `&dyn DeviceDriver`，从而完全解耦。

use uuid::Uuid;

use super::executor::DriverAccess;
use super::types::ExecutionError;
use crate::drivers::core::{DeviceDriver, PointValue};
use crate::drivers::r#virtual::VirtualConfig;
use crate::drivers::DriverError;

/// DriverAccess 适配器
///
/// 将 DeviceDriver trait 对象适配为 DriverAccess trait 对象。
/// 当前绑定到 VirtualConfig/DriverError 关联类型（S2-009 限制）。
pub struct DriverAccessAdapter<'a> {
    driver: &'a dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>,
}

impl<'a> DriverAccessAdapter<'a> {
    pub fn new(driver: &'a dyn DeviceDriver<Config = VirtualConfig, Error = DriverError>) -> Self {
        Self { driver }
    }
}

impl<'a> DriverAccess for DriverAccessAdapter<'a> {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        self.driver
            .read_point(point_id)
            .map_err(|e| ExecutionError::DriverError(e.to_string()))
    }

    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        self.driver
            .write_point(point_id, value)
            .map_err(|e| ExecutionError::DriverError(e.to_string()))
    }
}
