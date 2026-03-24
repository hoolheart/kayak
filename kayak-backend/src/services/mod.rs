//! 服务层模块
//!
//! 包含业务逻辑服务

pub mod device;
pub mod point;
pub mod user;
pub mod user_repo_adapter;
pub mod workbench;

pub use device::{
    CreateDeviceEntity, DeviceDto, DeviceError, DeviceService, DeviceServiceImpl, PagedDeviceDto,
    UpdateDeviceEntity,
};
pub use point::{
    CreatePointEntity, PagedPointDto, PointDto, PointError, PointService, PointServiceImpl,
    PointValueDto, UpdatePointEntity,
};
pub use user::{
    ChangePasswordRequest, UpdateUserEntity, UpdateUserRequest, UserDto, UserError, UserService,
    UserServiceImpl,
};
pub use user_repo_adapter::UserServiceRepositoryAdapter;
pub use workbench::{
    PagedWorkbenchDto, WorkbenchDto, WorkbenchError, WorkbenchService, WorkbenchServiceImpl,
};
