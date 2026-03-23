//! 服务层模块
//!
//! 包含业务逻辑服务

pub mod user;
pub mod user_repo_adapter;
pub mod workbench;
pub mod device;
pub mod point;

pub use user::{UserService, UserServiceImpl, UserError, UpdateUserEntity, UserDto, UpdateUserRequest, ChangePasswordRequest};
pub use user_repo_adapter::UserServiceRepositoryAdapter;
pub use workbench::{WorkbenchService, WorkbenchServiceImpl, WorkbenchError, WorkbenchDto, PagedWorkbenchDto};
pub use device::{DeviceService, DeviceServiceImpl, DeviceError, CreateDeviceEntity, UpdateDeviceEntity, DeviceDto, PagedDeviceDto};
pub use point::{PointService, PointServiceImpl, PointError, CreatePointEntity, UpdatePointEntity, PointDto, PagedPointDto, PointValueDto};
