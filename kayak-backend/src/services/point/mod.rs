//! 测点服务模块

pub mod error;
pub mod service;
pub mod types;

pub use error::{PointError, CreatePointEntity, UpdatePointEntity};
pub use service::{PointService, PointServiceImpl};
pub use types::{PointDto, PagedPointDto, PointValueDto};
