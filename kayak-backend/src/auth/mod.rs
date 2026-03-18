//! 认证模块
//!
//! 提供用户注册、登录、JWT Token管理等功能

pub mod dtos;
pub mod error;
pub mod handlers;
pub mod middleware;
pub mod services;
pub mod traits;
pub mod user_repo_adapter;

pub use dtos::*;
pub use error::AuthError;
pub use handlers::*;
pub use middleware::*;
pub use services::*;
pub use traits::*;
pub use user_repo_adapter::*;
