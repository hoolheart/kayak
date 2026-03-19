//! 用户服务错误类型
//!
//! 定义用户操作相关的错误类型

use crate::core::error::{AppError, FieldError};
use thiserror::Error;

/// 用户服务错误类型
#[derive(Debug, Error)]
pub enum UserError {
    #[error("User not found")]
    UserNotFound,

    #[error("Username already exists")]
    UsernameAlreadyExists,

    #[error("Invalid old password")]
    InvalidOldPassword,

    #[error("Password too weak: {0}")]
    WeakPassword(String),

    #[error("New password cannot be the same as old password")]
    PasswordSameAsOld,

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Internal error: {0}")]
    Internal(String),
}

impl From<UserError> for AppError {
    fn from(err: UserError) -> Self {
        match err {
            UserError::UserNotFound => AppError::NotFound(err.to_string()),
            UserError::UsernameAlreadyExists => AppError::Conflict(err.to_string()),
            UserError::InvalidOldPassword => AppError::BadRequest(err.to_string()),
            UserError::WeakPassword(msg) => {
                AppError::validation_error(vec![FieldError::new("new_password", msg)])
            }
            UserError::PasswordSameAsOld => AppError::BadRequest(err.to_string()),
            UserError::ValidationError(msg) => AppError::BadRequest(msg),
            UserError::Internal(msg) => AppError::InternalError(msg),
        }
    }
}
