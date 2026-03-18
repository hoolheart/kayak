//! 认证模块错误定义
//!
//! 定义认证相关的特定错误类型

use thiserror::Error;

/// 认证错误类型
#[derive(Debug, Error)]
pub enum AuthError {
    /// 用户已存在
    #[error("User already exists")]
    UserAlreadyExists,

    /// 用户不存在
    #[error("User not found")]
    UserNotFound,

    /// 密码错误
    #[error("Invalid password")]
    InvalidPassword,

    /// Token无效
    #[error("Invalid token")]
    InvalidToken,

    /// Token已过期
    #[error("Token expired")]
    TokenExpired,

    /// Token类型错误
    #[error("Invalid token type")]
    InvalidTokenType,

    /// 用户被禁用
    #[error("User account is inactive")]
    InactiveUser,

    /// 密码哈希错误
    #[error("Password hashing error: {0}")]
    HashingError(String),
}

impl From<AuthError> for crate::core::error::AppError {
    fn from(err: AuthError) -> Self {
        match err {
            AuthError::UserAlreadyExists => crate::core::error::AppError::Conflict(err.to_string()),
            AuthError::UserNotFound => crate::core::error::AppError::NotFound(err.to_string()),
            AuthError::InvalidPassword | AuthError::InvalidToken => {
                crate::core::error::AppError::Unauthorized(err.to_string())
            }
            AuthError::TokenExpired => crate::core::error::AppError::Unauthorized(err.to_string()),
            AuthError::InvalidTokenType => {
                crate::core::error::AppError::BadRequest(err.to_string())
            }
            AuthError::InactiveUser => crate::core::error::AppError::Forbidden(err.to_string()),
            AuthError::HashingError(msg) => crate::core::error::AppError::InternalError(msg),
        }
    }
}
