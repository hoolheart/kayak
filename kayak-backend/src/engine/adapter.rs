//! DriverAccess 适配器
//!
//! 将具体驱动实例适配为 DriverAccess trait 对象，供 StepExecutor 使用。
//! 此适配器在引擎内部创建，对外屏蔽具体驱动类型。

use uuid::Uuid;

use super::executor::DriverAccess;
use super::types::ExecutionError;
use crate::drivers::core::{DeviceDriver, DriverError, PointValue};

/// DriverAccess 适配器
///
/// 将具体驱动实例适配为 DriverAccess trait 对象，供 StepExecutor 使用。
/// 此适配器在引擎内部创建，对外屏蔽具体驱动类型。
pub struct DriverAccessAdapter<'a> {
    driver: &'a dyn DeviceDriver<
        Config = crate::drivers::r#virtual::VirtualConfig,
        Error = DriverError,
    >,
}

impl<'a> DriverAccessAdapter<'a> {
    pub fn new(
        driver: &'a dyn DeviceDriver<
            Config = crate::drivers::r#virtual::VirtualConfig,
            Error = DriverError,
        >,
    ) -> Self {
        Self { driver }
    }
}

impl<'a> DriverAccess for DriverAccessAdapter<'a> {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        self.driver
            .read_point(point_id)
            .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string()))
    }

    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        self.driver
            .write_point(point_id, value)
            .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string()))
    }
}
