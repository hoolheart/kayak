//! 用户服务模块
//!
//! 提供用户信息管理和密码修改功能

pub mod error;
pub mod service;
pub mod types;

pub use error::UserError;
pub use service::{UserService, UserServiceImpl, UserDto, UpdateUserRequest, ChangePasswordRequest};
pub use types::UpdateUserEntity;
