//! 工作台服务错误类型

use thiserror::Error;

/// 工作台服务错误类型
#[derive(Debug, Error)]
pub enum WorkbenchError {
    #[error("Workbench not found")]
    NotFound,

    #[error("Access denied: you do not own this workbench")]
    AccessDenied,

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Internal error: {0}")]
    Internal(String),
}

impl From<sqlx::Error> for WorkbenchError {
    fn from(err: sqlx::Error) -> Self {
        WorkbenchError::Internal(err.to_string())
    }
}
