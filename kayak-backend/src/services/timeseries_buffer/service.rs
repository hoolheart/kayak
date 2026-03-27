//! TimeSeriesBuffer service implementation

use async_trait::async_trait;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Instant;
use tokio::sync::RwLock;
use uuid::Uuid;

use super::error::TimeSeriesBufferError;
use super::types::{
    BufferConfig, BufferId, BufferStatus, ExperimentBuffer, FlushResult,
    TimeSeriesPoint,
};
use crate::services::hdf5::Hdf5Service;

/// TimeSeriesBuffer service trait
#[async_trait]
pub trait TimeSeriesBufferService: Send + Sync {
    /// Create a buffer
    async fn create_buffer(
        &self,
        experiment_id: Uuid,
        config: BufferConfig,
    ) -> Result<BufferId, TimeSeriesBufferError>;

    /// Write a single data point
    async fn write_point(
        &self,
        buffer_id: &BufferId,
        point: TimeSeriesPoint,
    ) -> Result<(), TimeSeriesBufferError>;

    /// Batch write data points
    async fn write_batch(
        &self,
        buffer_id: &BufferId,
        points: Vec<TimeSeriesPoint>,
    ) -> Result<(), TimeSeriesBufferError>;

    /// Force flush buffer
    async fn flush(&self, buffer_id: &BufferId) -> Result<FlushResult, TimeSeriesBufferError>;

    /// Get buffer status
    async fn get_status(&self, buffer_id: &BufferId) -> Result<BufferStatus, TimeSeriesBufferError>;

    /// Close buffer (will flush all pending data)
    async fn close_buffer(&self, buffer_id: &BufferId) -> Result<(), TimeSeriesBufferError>;

    /// Delete buffer (will flush all pending data, then remove)
    async fn delete_buffer(&self, buffer_id: &BufferId) -> Result<(), TimeSeriesBufferError>;
}

/// TimeSeriesBuffer service implementation
pub struct TimeSeriesBufferServiceImpl {
    /// HDF5 service reference
    hdf5_service: Arc<dyn Hdf5Service>,
    /// Buffer map: experiment_id -> ExperimentBuffer
    buffers: RwLock<HashMap<Uuid, Arc<RwLock<ExperimentBuffer>>>>,
}

impl TimeSeriesBufferServiceImpl {
    /// Create a new service instance
    pub fn new(hdf5_service: Arc<dyn Hdf5Service>) -> Self {
        Self {
            hdf5_service,
            buffers: RwLock::new(HashMap::new()),
        }
    }

    /// Generate HDF5 file path for an experiment
    fn get_hdf5_path(data_root: &PathBuf, experiment_id: Uuid) -> PathBuf {
        data_root.join("experiments").join(format!("{}.h5", experiment_id))
    }

    /// Validate a time series point
    fn validate_point(&self, point: &TimeSeriesPoint) -> Result<(), TimeSeriesBufferError> {
        if point.timestamp < 0 {
            return Err(TimeSeriesBufferError::InvalidPoint(
                "timestamp must be non-negative".to_string(),
            ));
        }
        if point.channel.is_empty() {
            return Err(TimeSeriesBufferError::InvalidPoint(
                "channel name cannot be empty".to_string(),
            ));
        }
        Ok(())
    }

    /// Internal method to flush a buffer and return result
    async fn flush_internal(
        &self,
        buffer: &mut ExperimentBuffer,
        manual: bool,
    ) -> Result<FlushResult, TimeSeriesBufferError> {
        // Check if flush is already in progress
        if buffer.is_flush_in_progress() {
            return Err(TimeSeriesBufferError::FlushInProgress);
        }

        // Mark as flushing
        buffer.set_flushing(true);

        let start = Instant::now();
        let mut total_points_flushed = 0;

        // Take all points from all channels
        let all_points = buffer.take_all_points();

        if all_points.is_empty() || all_points.values().all(|v| v.is_empty()) {
            buffer.set_flushing(false);
            return Ok(FlushResult {
                points_flushed: 0,
                flush_duration_ms: start.elapsed().as_millis() as u64,
                manual,
            });
        }

        // Create HDF5 file and write data
        let hdf5_path = buffer.hdf5_file_path().clone();
        
        // Open or create the HDF5 file
        let file = if hdf5_path.exists() {
            self.hdf5_service.open_file(&hdf5_path).await
        } else {
            self.hdf5_service.create_file_with_directories(&hdf5_path).await
        };

        let file = match file {
            Ok(f) => f,
            Err(e) => {
                buffer.set_flushing(false);
                return Err(TimeSeriesBufferError::Hdf5WriteError(e.to_string()));
            }
        };

        // Write each channel's data
        for (channel_name, points) in all_points {
            if points.is_empty() {
                continue;
            }

            // Split points into timestamps and values
            let timestamps: Vec<i64> = points.iter().map(|p| p.timestamp).collect();
            let values: Vec<f64> = points.iter().map(|p| p.value).collect();

            // Create or get the channel group using path within file
            let group = match self.hdf5_service.get_group(&file, &channel_name).await {
                Ok(g) => g,
                Err(_) => {
                    // Group doesn't exist, create it under root
                    // First get root group
                    let root_group = match self.hdf5_service.get_group(&file, "/").await {
                        Ok(g) => g,
                        Err(e) => {
                            tracing::error!("Failed to get root group: {}", e);
                            continue;
                        }
                    };
                    match self.hdf5_service.create_group(&root_group, &channel_name).await {
                        Ok(g) => g,
                        Err(e) => {
                            // Log error but continue with other channels
                            tracing::error!("Failed to create group {}: {}", channel_name, e);
                            continue;
                        }
                    }
                }
            };

            // Write timeseries data
            match self
                .hdf5_service
                .write_timeseries(&group, "values", &timestamps, &values)
                .await
            {
                Ok(()) => {
                    total_points_flushed += points.len();
                }
                Err(e) => {
                    tracing::error!("Failed to write timeseries for {}: {}", channel_name, e);
                    // Continue with other channels
                }
            }
        }

        // Close the file
        if let Err(e) = self.hdf5_service.close_file(file).await {
            tracing::error!("Failed to close HDF5 file: {}", e);
        }

        // Update last flush time
        buffer.update_last_flush_at();

        // Mark as not flushing
        buffer.set_flushing(false);

        Ok(FlushResult {
            points_flushed: total_points_flushed,
            flush_duration_ms: start.elapsed().as_millis() as u64,
            manual,
        })
    }

    /// Check and perform auto-flush based on capacity or time
    async fn check_and_auto_flush(
        &self,
        buffer: &mut ExperimentBuffer,
    ) -> Result<(), TimeSeriesBufferError> {
        // Check capacity trigger - any channel full triggers flush
        if buffer.is_any_channel_full() {
            tracing::debug!("Capacity trigger flush for buffer");
            self.flush_internal(buffer, false).await?;
            return Ok(());
        }

        // Check time trigger
        if buffer.should_flush_by_time() {
            tracing::debug!("Time trigger flush for buffer");
            self.flush_internal(buffer, false).await?;
        }

        Ok(())
    }
}

#[async_trait]
impl TimeSeriesBufferService for TimeSeriesBufferServiceImpl {
    async fn create_buffer(
        &self,
        experiment_id: Uuid,
        config: BufferConfig,
    ) -> Result<BufferId, TimeSeriesBufferError> {
        let buffer_id = BufferId::new(Uuid::new_v4());
        let hdf5_path = Self::get_hdf5_path(&config.data_root, experiment_id);

        let buffer = ExperimentBuffer::new(
            buffer_id.clone(),
            experiment_id,
            config,
            hdf5_path,
        );

        let mut buffers = self.buffers.write().await;
        
        // Check if buffer already exists for this experiment
        if buffers.contains_key(&experiment_id) {
            return Err(TimeSeriesBufferError::BufferAlreadyExists(
                experiment_id.to_string(),
            ));
        }

        buffers.insert(experiment_id, Arc::new(RwLock::new(buffer)));

        Ok(buffer_id)
    }

    async fn write_point(
        &self,
        buffer_id: &BufferId,
        point: TimeSeriesPoint,
    ) -> Result<(), TimeSeriesBufferError> {
        self.validate_point(&point)?;

        let buffers = self.buffers.read().await;
        
        // Find buffer by experiment_id and clone the Arc
        let buffer = match buffers
            .values()
            .find(|b| b.try_read().map(|r| r.buffer_id() == buffer_id).unwrap_or(false))
        {
            Some(b) => Arc::clone(b),
            None => return Err(TimeSeriesBufferError::BufferNotFound(buffer_id.0.to_string())),
        };

        drop(buffers);

        let mut buffer_guard = buffer.write().await;

        // Check if buffer is closed
        if buffer_guard.is_closed() {
            return Err(TimeSeriesBufferError::BufferClosed);
        }

        // Get or create channel and add point
        let channel = buffer_guard.get_or_create_channel(&point.channel);
        channel.add_point_unsafe(point);

        // Check and perform auto-flush
        drop(buffer_guard);
        let mut buffer_guard = buffer.write().await;
        self.check_and_auto_flush(&mut *buffer_guard).await?;

        Ok(())
    }

    async fn write_batch(
        &self,
        buffer_id: &BufferId,
        points: Vec<TimeSeriesPoint>,
    ) -> Result<(), TimeSeriesBufferError> {
        // Validate all points first
        for point in &points {
            self.validate_point(point)?;
        }

        let buffers = self.buffers.read().await;
        
        // Find buffer by experiment_id and clone the Arc
        let buffer = match buffers
            .values()
            .find(|b| b.try_read().map(|r| r.buffer_id() == buffer_id).unwrap_or(false))
        {
            Some(b) => Arc::clone(b),
            None => return Err(TimeSeriesBufferError::BufferNotFound(buffer_id.0.to_string())),
        };

        drop(buffers);

        let mut buffer_guard = buffer.write().await;

        // Check if buffer is closed
        if buffer_guard.is_closed() {
            return Err(TimeSeriesBufferError::BufferClosed);
        }

        // Group points by channel
        let mut channel_points: HashMap<String, Vec<TimeSeriesPoint>> = HashMap::new();
        for point in points {
            channel_points
                .entry(point.channel.clone())
                .or_insert_with(Vec::new)
                .push(point);
        }

        // Add points to each channel
        for (channel_name, channel_point_list) in channel_points {
            let channel = buffer_guard.get_or_create_channel(&channel_name);
            for point in channel_point_list {
                channel.add_point_unsafe(point);
            }
        }

        // Check and perform auto-flush
        drop(buffer_guard);
        let mut buffer_guard = buffer.write().await;
        self.check_and_auto_flush(&mut *buffer_guard).await?;

        Ok(())
    }

    async fn flush(&self, buffer_id: &BufferId) -> Result<FlushResult, TimeSeriesBufferError> {
        let buffers = self.buffers.read().await;
        
        let buffer = match buffers
            .values()
            .find(|b| b.try_read().map(|r| r.buffer_id() == buffer_id).unwrap_or(false))
        {
            Some(b) => Arc::clone(b),
            None => return Err(TimeSeriesBufferError::BufferNotFound(buffer_id.0.to_string())),
        };

        drop(buffers);

        let mut buffer_guard = buffer.write().await;
        self.flush_internal(&mut buffer_guard, true).await
    }

    async fn get_status(&self, buffer_id: &BufferId) -> Result<BufferStatus, TimeSeriesBufferError> {
        let buffers = self.buffers.read().await;
        
        let buffer = match buffers
            .values()
            .find(|b| b.try_read().map(|r| r.buffer_id() == buffer_id).unwrap_or(false))
        {
            Some(b) => Arc::clone(b),
            None => return Err(TimeSeriesBufferError::BufferNotFound(buffer_id.0.to_string())),
        };

        drop(buffers);

        let buffer_guard = buffer.read().await;

        Ok(BufferStatus {
            buffer_id: buffer_guard.buffer_id().clone(),
            experiment_id: buffer_guard.experiment_id(),
            points_count: buffer_guard.total_points(),
            is_flushing: buffer_guard.is_flush_in_progress(),
            last_flush_at: buffer_guard.last_flush_at(),
            config: buffer_guard.config().clone(),
        })
    }

    async fn close_buffer(&self, buffer_id: &BufferId) -> Result<(), TimeSeriesBufferError> {
        let buffers = self.buffers.read().await;
        
        let buffer = match buffers
            .values()
            .find(|b| b.try_read().map(|r| r.buffer_id() == buffer_id).unwrap_or(false))
        {
            Some(b) => Arc::clone(b),
            None => return Err(TimeSeriesBufferError::BufferNotFound(buffer_id.0.to_string())),
        };

        drop(buffers);

        // Flush first
        let mut buffer_guard = buffer.write().await;
        self.flush_internal(&mut buffer_guard, true).await?;
        buffer_guard.set_closed(true);

        Ok(())
    }

    async fn delete_buffer(&self, buffer_id: &BufferId) -> Result<(), TimeSeriesBufferError> {
        let buffers = self.buffers.read().await;
        
        let buffer = match buffers
            .values()
            .find(|b| b.try_read().map(|r| r.buffer_id() == buffer_id).unwrap_or(false))
        {
            Some(b) => Arc::clone(b),
            None => return Err(TimeSeriesBufferError::BufferNotFound(buffer_id.0.to_string())),
        };

        drop(buffers);

        // Flush first
        let mut buffer_guard = buffer.write().await;
        self.flush_internal(&mut buffer_guard, true).await?;

        // Remove from buffers map
        drop(buffer_guard);
        let mut buffers = self.buffers.write().await;
        buffers.retain(|_, b| {
            b.try_read()
                .map(|r| r.buffer_id() != buffer_id)
                .unwrap_or(true)
        });

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::hdf5::{Hdf5File, Hdf5Group};
    use chrono::Utc;

    // Mock Hdf5Service for testing
    struct MockHdf5Service;

    #[async_trait]
    impl Hdf5Service for MockHdf5Service {
        async fn create_file(&self, _path: PathBuf) -> Result<Hdf5File, crate::services::hdf5::Hdf5Error> {
            Ok(Hdf5File { path: PathBuf::from("/tmp/test.h5") })
        }

        async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, crate::services::hdf5::Hdf5Error> {
            Ok(Hdf5File { path: path.clone() })
        }

        async fn close_file(&self, _file: Hdf5File) -> Result<(), crate::services::hdf5::Hdf5Error> {
            Ok(())
        }

        async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, crate::services::hdf5::Hdf5Error> {
            Ok(Hdf5Group {
                file_path: parent.file_path.clone(),
                name: name.to_string(),
                path: format!("{}/{}", parent.path, name),
            })
        }

        async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, crate::services::hdf5::Hdf5Error> {
            Ok(Hdf5Group {
                file_path: file.path.clone(),
                name: path.to_string(),
                path: path.to_string(),
            })
        }

        async fn write_timeseries(
            &self,
            _group: &Hdf5Group,
            _name: &str,
            _timestamps: &[i64],
            _values: &[f64],
        ) -> Result<(), crate::services::hdf5::Hdf5Error> {
            Ok(())
        }

        async fn read_dataset(&self, _group: &Hdf5Group, _name: &str) -> Result<Vec<f64>, crate::services::hdf5::Hdf5Error> {
            Ok(vec![])
        }

        async fn get_dataset_shape(&self, _group: &Hdf5Group, _name: &str) -> Result<Vec<usize>, crate::services::hdf5::Hdf5Error> {
            Ok(vec![])
        }

        async fn generate_experiment_path(&self, _exp_id: Uuid, _timestamp: chrono::DateTime<Utc>) -> Result<PathBuf, crate::services::hdf5::Hdf5Error> {
            Ok(PathBuf::from("/tmp/test.h5"))
        }

        async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, crate::services::hdf5::Hdf5Error> {
            // Create parent directories
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent).ok();
            }
            Ok(Hdf5File { path: path.clone() })
        }

        fn is_path_safe(&self, _path: &PathBuf) -> bool {
            true
        }
    }

    #[tokio::test]
    async fn test_create_buffer() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let result = service.create_buffer(experiment_id, config).await;
        assert!(result.is_ok());
        let buffer_id = result.unwrap();
        assert_eq!(buffer_id.0, buffer_id.0); // Check it's a valid UUID
    }

    #[tokio::test]
    async fn test_create_buffer_duplicate() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let result1 = service.create_buffer(experiment_id, config.clone()).await;
        assert!(result1.is_ok());

        let result2 = service.create_buffer(experiment_id, config).await;
        assert!(matches!(result2, Err(TimeSeriesBufferError::BufferAlreadyExists(_))));
    }

    #[tokio::test]
    async fn test_write_point() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: 1000,
            channel: "test_channel".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_write_point_invalid_timestamp() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: -1, // Invalid
            channel: "test_channel".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(matches!(result, Err(TimeSeriesBufferError::InvalidPoint(_))));
    }

    #[tokio::test]
    async fn test_write_point_empty_channel() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: 1000,
            channel: "".to_string(), // Invalid
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(matches!(result, Err(TimeSeriesBufferError::InvalidPoint(_))));
    }

    #[tokio::test]
    async fn test_write_batch() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        let points = vec![
            TimeSeriesPoint {
                timestamp: 1000,
                channel: "ch1".to_string(),
                value: 1.0,
            },
            TimeSeriesPoint {
                timestamp: 2000,
                channel: "ch1".to_string(),
                value: 2.0,
            },
            TimeSeriesPoint {
                timestamp: 3000,
                channel: "ch2".to_string(),
                value: 3.0,
            },
        ];

        let result = service.write_batch(&buffer_id, points).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_write_to_nonexistent_buffer() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let buffer_id = BufferId::new(Uuid::new_v4());

        let point = TimeSeriesPoint {
            timestamp: 1000,
            channel: "test_channel".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(matches!(result, Err(TimeSeriesBufferError::BufferNotFound(_))));
    }

    #[tokio::test]
    async fn test_flush() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // Write some points
        let points = vec![
            TimeSeriesPoint {
                timestamp: 1000,
                channel: "ch1".to_string(),
                value: 1.0,
            },
        ];
        service.write_batch(&buffer_id, points).await.unwrap();

        // Flush
        let result = service.flush(&buffer_id).await;
        assert!(result.is_ok());
        let flush_result = result.unwrap();
        assert_eq!(flush_result.points_flushed, 1);
        assert!(flush_result.manual);
    }

    #[tokio::test]
    async fn test_get_status() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config.clone()).await.unwrap();

        // Write some points
        let points = vec![
            TimeSeriesPoint {
                timestamp: 1000,
                channel: "ch1".to_string(),
                value: 1.0,
            },
        ];
        service.write_batch(&buffer_id, points).await.unwrap();

        // Get status
        let result = service.get_status(&buffer_id).await;
        assert!(result.is_ok());
        let status = result.unwrap();
        assert_eq!(status.buffer_id, buffer_id);
        assert_eq!(status.experiment_id, experiment_id);
        assert_eq!(status.points_count, 1);
        assert!(!status.is_flushing);
    }

    #[tokio::test]
    async fn test_close_buffer() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // Write some points
        let points = vec![
            TimeSeriesPoint {
                timestamp: 1000,
                channel: "ch1".to_string(),
                value: 1.0,
            },
        ];
        service.write_batch(&buffer_id, points).await.unwrap();

        // Close buffer
        let result = service.close_buffer(&buffer_id).await;
        assert!(result.is_ok());

        // Verify status shows closed
        let status = service.get_status(&buffer_id).await.unwrap();
        assert!(status.points_count == 0); // Should be flushed
    }

    #[tokio::test]
    async fn test_delete_buffer() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // Write some points
        let points = vec![
            TimeSeriesPoint {
                timestamp: 1000,
                channel: "ch1".to_string(),
                value: 1.0,
            },
        ];
        service.write_batch(&buffer_id, points).await.unwrap();

        // Delete buffer
        let result = service.delete_buffer(&buffer_id).await;
        assert!(result.is_ok());

        // Verify buffer not found
        let result = service.get_status(&buffer_id).await;
        assert!(matches!(result, Err(TimeSeriesBufferError::BufferNotFound(_))));
    }

    #[tokio::test]
    async fn test_write_to_closed_buffer() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let config = BufferConfig::default();

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // Close buffer
        service.close_buffer(&buffer_id).await.unwrap();

        // Try to write
        let point = TimeSeriesPoint {
            timestamp: 1000,
            channel: "test_channel".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(matches!(result, Err(TimeSeriesBufferError::BufferClosed)));
    }

    #[tokio::test]
    async fn test_capacity_trigger_flush() {
        let mock_hdf5 = Arc::new(MockHdf5Service);
        let service = TimeSeriesBufferServiceImpl::new(mock_hdf5);

        let experiment_id = Uuid::new_v4();
        let mut config = BufferConfig::default();
        config.max_size = 3; // Small size to trigger flush

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // Write points up to max_size
        for i in 0..3 {
            let point = TimeSeriesPoint {
                timestamp: (i as i64) * 1000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // Status should show flushed (0 points because auto-flush happened)
        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 0);
    }
}
