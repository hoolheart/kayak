//! TimeSeriesBuffer service error types

use thiserror::Error;

/// TimeSeriesBuffer service error types
#[derive(Error, Debug)]
pub enum TimeSeriesBufferError {
    #[error("Buffer not found: {0}")]
    BufferNotFound(String),

    #[error("Buffer already exists: {0}")]
    BufferAlreadyExists(String),

    #[error("Buffer full, pending flush")]
    BufferFull,

    #[error("Flush in progress")]
    FlushInProgress,

    #[error("HDF5 write error: {0}")]
    Hdf5WriteError(String),

    #[error("Data loss detected: {points} points lost")]
    DataLoss { points: usize },

    #[error("Invalid point: {0}")]
    InvalidPoint(String),

    #[error("Channel not configured: {0}")]
    ChannelNotConfigured(String),

    #[error("Write timeout after {timeout_ms}ms")]
    WriteTimeout { timeout_ms: u64 },

    #[error("Buffer closed")]
    BufferClosed,

    #[error("Overflow: buffer capacity exceeded")]
    Overflow,
}

/// From Hdf5Error to TimeSeriesBufferError conversion
impl From<crate::services::hdf5::Hdf5Error> for TimeSeriesBufferError {
    fn from(err: crate::services::hdf5::Hdf5Error) -> Self {
        TimeSeriesBufferError::Hdf5WriteError(err.to_string())
    }
}
