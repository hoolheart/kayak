//! 试验方法Repository错误
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MethodRepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Method not found")]
    NotFound,
}
