//! TimeSeriesBuffer service module
//!
//! This module provides time-series data buffering and batch writing services.
//!
//! # Features
//! - Buffer management per experiment/channel
//! - Capacity and time-based auto-flush
//! - HDF5 persistence
//! - Thread-safe operations
//!
//! # Architecture
//!
//! The service maintains in-memory buffers for each experiment. Data points are
//! stored in channels (one per measurement channel). When buffers reach capacity
//! or when the flush interval elapses, data is automatically written to HDF5
//! files.
//!
//! # Data Flow
//!
//! 1. `write_point` / `write_batch` - Data added to memory buffer
//! 2. Auto-flush triggers when capacity or time threshold reached
//! 3. `flush` - Manually trigger flush to HDF5
//! 4. `close_buffer` / `delete_buffer` - Final flush and cleanup

pub mod error;
pub mod service;
pub mod types;

pub use error::TimeSeriesBufferError;
pub use service::{TimeSeriesBufferService, TimeSeriesBufferServiceImpl};
pub use types::{
    BufferConfig, BufferId, BufferStatus, ChannelBuffer, ExperimentBuffer, FlushResult,
    TimeSeriesPoint,
};
