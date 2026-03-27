//! TimeSeriesBuffer service data structures

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use uuid::Uuid;

/// TimeSeries data point
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeSeriesPoint {
    /// Timestamp (nanoseconds Unix timestamp)
    pub timestamp: i64,
    /// Channel name (corresponds to HDF5 group name)
    pub channel: String,
    /// Data value
    pub value: f64,
}

/// Buffer configuration
#[derive(Debug, Clone)]
pub struct BufferConfig {
    /// Maximum buffer size (number of data points)
    pub max_size: usize,
    /// Flush interval (milliseconds)
    pub flush_interval_ms: u64,
    /// Data root directory
    pub data_root: PathBuf,
    /// Whether compression is enabled (currently not implemented, requires Hdf5Service extension)
    pub compression_enabled: bool,
    /// Compression level (currently not implemented, requires Hdf5Service extension)
    pub compression_level: u32,
}

impl Default for BufferConfig {
    fn default() -> Self {
        Self {
            max_size: 10000,
            flush_interval_ms: 1000,
            data_root: PathBuf::from("./data"),
            compression_enabled: false,
            compression_level: 4,
        }
    }
}

/// Buffer ID
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct BufferId(pub Uuid);

impl BufferId {
    pub fn new(uuid: Uuid) -> Self {
        BufferId(uuid)
    }
}

/// Flush result
#[derive(Debug)]
pub struct FlushResult {
    /// Number of data points successfully flushed
    pub points_flushed: usize,
    /// Flush duration (milliseconds)
    pub flush_duration_ms: u64,
    /// Whether this was manually triggered
    pub manual: bool,
}

/// Buffer status
#[derive(Debug, Clone)]
pub struct BufferStatus {
    pub buffer_id: BufferId,
    pub experiment_id: Uuid,
    pub points_count: usize,
    pub is_flushing: bool,
    pub last_flush_at: Option<DateTime<Utc>>,
    pub config: BufferConfig,
}

/// Channel buffer
///
/// **Thread Safety**: Uses tokio::sync::Mutex to protect the points field,
/// ensuring that concurrent writes to the same channel are serialized.
pub struct ChannelBuffer {
    /// Channel name
    name: String,
    /// Data points list (sorted by timestamp)
    ///
    /// **Note**: This field is protected by an outer Mutex, not directly exposed to the outside.
    /// Access requires holding the lock.
    points: Vec<TimeSeriesPoint>,
    /// Last flush time
    last_flush_at: DateTime<Utc>,
}

impl ChannelBuffer {
    /// Create a new channel buffer
    pub fn new(name: String) -> Self {
        Self {
            name,
            points: Vec::new(),
            last_flush_at: Utc::now(),
        }
    }

    /// Add a data point (requires holding the lock)
    pub fn add_point_unsafe(&mut self, point: TimeSeriesPoint) {
        self.points.push(point);
    }

    /// Clear the buffer (requires holding the lock)
    pub fn clear_unsafe(&mut self) {
        self.points.clear();
        self.last_flush_at = Utc::now();
    }

    /// Get the number of data points (requires holding the lock)
    pub fn len_unsafe(&self) -> usize {
        self.points.len()
    }

    /// Check if buffer is empty
    pub fn is_empty(&self) -> bool {
        self.points.is_empty()
    }

    /// Get the channel name
    pub fn name(&self) -> &str {
        &self.name
    }

    /// Take all points and reset the buffer
    pub fn take_points(&mut self) -> Vec<TimeSeriesPoint> {
        let points = std::mem::take(&mut self.points);
        self.last_flush_at = Utc::now();
        points
    }

    /// Get last flush time
    pub fn last_flush_at(&self) -> DateTime<Utc> {
        self.last_flush_at
    }
}

/// Experiment buffer
///
/// **Thread Safety**: This structure is shared via Arc<Mutex<>>, and all methods require acquiring the lock before calling.
pub struct ExperimentBuffer {
    /// Buffer ID
    buffer_id: BufferId,
    /// Experiment ID
    experiment_id: Uuid,
    /// Channel buffer map: channel_name -> ChannelBuffer
    ///
    /// **Note**: Accessing this HashMap requires acquiring channels_lock
    channels: HashMap<String, ChannelBuffer>,
    /// Configuration
    config: BufferConfig,
    /// Whether a flush is in progress (flush mutex)
    is_flushing: bool,
    /// Whether the buffer has been closed
    is_closed: bool,
    /// Last flush time
    last_flush_at: Option<DateTime<Utc>>,
    /// HDF5 file path
    hdf5_file_path: PathBuf,
}

impl ExperimentBuffer {
    /// Create a new experiment buffer
    pub fn new(
        buffer_id: BufferId,
        experiment_id: Uuid,
        config: BufferConfig,
        hdf5_file_path: PathBuf,
    ) -> Self {
        Self {
            buffer_id,
            experiment_id,
            channels: HashMap::new(),
            config,
            is_flushing: false,
            is_closed: false,
            last_flush_at: None,
            hdf5_file_path,
        }
    }

    /// Get or create a channel buffer
    pub fn get_or_create_channel(&mut self, channel_name: &str) -> &mut ChannelBuffer {
        self.channels
            .entry(channel_name.to_string())
            .or_insert_with(|| ChannelBuffer::new(channel_name.to_string()))
    }

    /// Check if a channel exists
    pub fn has_channel(&self, channel_name: &str) -> bool {
        self.channels.contains_key(channel_name)
    }

    /// Get total points count across all channels
    pub fn total_points(&self) -> usize {
        self.channels.values().map(|ch| ch.len_unsafe()).sum()
    }

    /// Check if any channel has reached max size
    pub fn is_any_channel_full(&self) -> bool {
        self.channels
            .values()
            .any(|ch| ch.len_unsafe() >= self.config.max_size)
    }

    /// Check if time since last flush exceeds interval
    pub fn should_flush_by_time(&self) -> bool {
        if let Some(last_flush) = self.last_flush_at {
            let elapsed = Utc::now()
                .signed_duration_since(last_flush)
                .num_milliseconds() as u64;
            elapsed >= self.config.flush_interval_ms && self.total_points() > 0
        } else {
            // Never flushed but has data - should flush
            self.total_points() > 0
        }
    }

    /// Get buffer ID
    pub fn buffer_id(&self) -> &BufferId {
        &self.buffer_id
    }

    /// Get experiment ID
    pub fn experiment_id(&self) -> Uuid {
        self.experiment_id
    }

    /// Get HDF5 file path
    pub fn hdf5_file_path(&self) -> &PathBuf {
        &self.hdf5_file_path
    }

    /// Check if buffer is closed
    pub fn is_closed(&self) -> bool {
        self.is_closed
    }

    /// Check if flush is in progress
    pub fn is_flush_in_progress(&self) -> bool {
        self.is_flushing
    }

    /// Set flush in progress flag
    pub fn set_flushing(&mut self, flushing: bool) {
        self.is_flushing = flushing;
    }

    /// Set closed flag
    pub fn set_closed(&mut self, closed: bool) {
        self.is_closed = closed;
    }

    /// Update last flush time
    pub fn update_last_flush_at(&mut self) {
        self.last_flush_at = Some(Utc::now());
    }

    /// Get config
    pub fn config(&self) -> &BufferConfig {
        &self.config
    }

    /// Get last flush time
    pub fn last_flush_at(&self) -> Option<DateTime<Utc>> {
        self.last_flush_at
    }

    /// Get all channel names
    pub fn channel_names(&self) -> Vec<String> {
        self.channels.keys().cloned().collect()
    }

    /// Take all points from all channels, grouped by channel name
    pub fn take_all_points(&mut self) -> HashMap<String, Vec<TimeSeriesPoint>> {
        let mut result = HashMap::new();
        for (name, channel) in self.channels.iter_mut() {
            result.insert(name.clone(), channel.take_points());
        }
        result
    }

    /// Clear all channels
    pub fn clear_all_channels(&mut self) {
        for channel in self.channels.values_mut() {
            channel.clear_unsafe();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_channel_buffer_basic_operations() {
        let mut channel = ChannelBuffer::new("test_channel".to_string());

        assert!(channel.is_empty());
        assert_eq!(channel.len_unsafe(), 0);

        channel.add_point_unsafe(TimeSeriesPoint {
            timestamp: 1000,
            channel: "test_channel".to_string(),
            value: 1.0,
        });

        assert_eq!(channel.len_unsafe(), 1);
        assert!(!channel.is_empty());
    }

    #[test]
    fn test_experiment_buffer_get_or_create_channel() {
        let config = BufferConfig::default();
        let mut buffer = ExperimentBuffer::new(
            BufferId::new(Uuid::new_v4()),
            Uuid::new_v4(),
            config,
            PathBuf::from("/tmp/test.h5"),
        );

        assert!(!buffer.has_channel("channel1"));

        buffer.get_or_create_channel("channel1");
        assert!(buffer.has_channel("channel1"));

        // Getting existing channel should not create duplicate
        buffer.get_or_create_channel("channel1");
        assert_eq!(buffer.channels.len(), 1);
    }

    #[test]
    fn test_experiment_buffer_total_points() {
        let config = BufferConfig::default();
        let mut buffer = ExperimentBuffer::new(
            BufferId::new(Uuid::new_v4()),
            Uuid::new_v4(),
            config,
            PathBuf::from("/tmp/test.h5"),
        );

        assert_eq!(buffer.total_points(), 0);

        buffer
            .get_or_create_channel("ch1")
            .add_point_unsafe(TimeSeriesPoint {
                timestamp: 1000,
                channel: "ch1".to_string(),
                value: 1.0,
            });
        buffer
            .get_or_create_channel("ch2")
            .add_point_unsafe(TimeSeriesPoint {
                timestamp: 2000,
                channel: "ch2".to_string(),
                value: 2.0,
            });

        assert_eq!(buffer.total_points(), 2);
    }
}
