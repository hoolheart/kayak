//! Experiment query error types

use thiserror::Error;
use uuid::Uuid;

/// Experiment query errors
#[derive(Error, Debug)]
pub enum ExperimentQueryError {
    #[error("试验不存在: {0}")]
    NotFound(Uuid),

    #[error("无权限访问该试验: {0}")]
    AccessDenied(Uuid),

    #[error("无效的分页参数: {0}")]
    InvalidPagination(String),

    #[error("无效的查询条件: {0}")]
    InvalidQuery(String),

    #[error("数据库错误: {0}")]
    DatabaseError(#[from] sqlx::Error),

    #[error("内部错误: {0}")]
    Internal(String),
}

/// Point history errors
#[derive(Error, Debug)]
pub enum PointHistoryError {
    #[error("试验不存在: {0}")]
    ExperimentNotFound(Uuid),

    #[error("通道不存在: {0}")]
    ChannelNotFound(String),

    #[error("HDF5文件不存在: {0}")]
    Hdf5FileNotFound(String),

    #[error("HDF5读取错误: {0}")]
    Hdf5ReadError(String),

    #[error("无效的时间范围: {0}")]
    InvalidTimeRange(String),

    #[error("时间范围倒置: start_time > end_time")]
    TimeRangeReversed,

    #[error("数据量过大: {actual} points (max: {max})")]
    DataTooLarge { actual: usize, max: usize },
}

/// Data file errors
#[derive(Error, Debug)]
pub enum DataFileError {
    #[error("试验不存在: {0}")]
    ExperimentNotFound(Uuid),

    #[error("无权限访问该试验: {0}")]
    AccessDenied(Uuid),

    #[error("数据文件不存在")]
    DataFileNotFound,

    #[error("文件读取失败: {0}")]
    FileReadError(String),

    #[error("文件过大，无法流式传输: {0} bytes")]
    FileTooLarge(i64),
}
