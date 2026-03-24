//! 设备服务模块

pub mod error;
pub mod service;
pub mod types;

pub use error::{CreateDeviceEntity, DeviceError, UpdateDeviceEntity};
pub use service::{DeviceService, DeviceServiceImpl};
pub use types::{DeviceDto, PagedDeviceDto};
