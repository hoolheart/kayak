//! 结果类型别名
//!
//! 为应用提供统一的结果类型

use crate::core::error::AppError;

/// 应用结果类型
pub type Result<T> = std::result::Result<T, AppError>;
