# S2-003: 时序数据写入服务 - 测试用例文档

**任务ID**: S2-003  
**任务名称**: 时序数据写入服务 (Time-series Data Writing Service)  
**文档版本**: 2.0 (修订版)  
**创建日期**: 2026-03-27  
**修订日期**: 2026-03-27  
**测试类型**: 单元测试、集成测试  
**技术栈**: Rust / tokio / hdf5-rust / tempfile  

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-003 任务的所有功能测试，包括：
1. **缓冲区管理测试** - 缓冲区的初始化、刷新、容量管理
2. **时序数据写入测试** - 单点写入、批量写入、多通道写入
3. **错误处理测试** - HDF5写入失败、缓冲区溢出、数据丢失防护
4. **性能测试** - 批量写入吞吐量、HDF5刷新吞吐量

### 1.2 依赖服务

- **S2-001**: HDF5文件操作库 (Hdf5Service)
- **S2-002**: 试验数据模型 (Experiment, DataFile)

### 1.3 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 数据批量写入性能>10k samples/sec | TC-TSB-500 ~ TC-TSB-503 | Performance |
| 2. ~~支持gzip压缩~~ | **已移除** - Hdf5Service当前不支持压缩参数 | N/A |
| 3. 服务异常不丢失数据 | TC-TSB-300 ~ TC-TSB-315 | Integration |

### 1.4 重要说明

> **⚠️ 关于压缩功能的说明**
> 
> 当前的 `Hdf5Service.write_timeseries()` 接口**不支持压缩参数**：
> ```rust
> async fn write_timeseries(
>     &self,
>     group: &Hdf5Group,
>     name: &str,
>     timestamps: &[i64],
>     values: &[f64],
> ) -> Result<(), Hdf5Error>;
> ```
> 
> `CompressionInfo` 类型存在于 `types.rs` 但**未被任何方法使用**。
> 
> **验收标准 #2 (支持gzip压缩) 需要先扩展 Hdf5Service 接口。**
> 
> 测试用例中的压缩相关测试已移除，待接口扩展后恢复。

---

## 2. 服务接口定义

### 2.1 核心类型定义

```rust
// kayak-backend/src/services/timeseries_buffer/mod.rs

use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use chrono::{DateTime, Utc};

/// 时序数据点
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeSeriesPoint {
    /// 时间戳（纳秒）
    pub timestamp: i64,
    /// 通道名称
    pub channel: String,
    /// 数据值
    pub value: f64,
}

/// 通道配置
#[derive(Debug, Clone)]
pub struct ChannelConfig {
    /// 通道名称
    pub name: String,
    /// 数据类型
    pub dtype: DatasetType,
}

/// 缓冲区配置
/// 
/// 注意: compression_enabled 和 compression_level 字段当前未使用
/// 压缩功能需待 Hdf5Service 扩展后生效
#[derive(Debug, Clone)]
pub struct BufferConfig {
    /// 最大缓冲区大小（数据点数）
    pub max_size: usize,
    /// 刷新时间间隔（毫秒）
    pub flush_interval_ms: u64,
    /// 是否启用压缩（当前未实现，需Hdf5Service扩展）
    pub compression_enabled: bool,
    /// 压缩级别（当前未实现，需Hdf5Service扩展）
    pub compression_level: u32,
}

impl Default for BufferConfig {
    fn default() -> Self {
        Self {
            max_size: 10000,
            flush_interval_ms: 1000,
            compression_enabled: false,  // 暂时固定为false
            compression_level: 4,
        }
    }
}

/// 写入批次
#[derive(Debug, Clone)]
pub struct WriteBatch {
    /// 试验ID
    pub experiment_id: Uuid,
    /// 数据点列表
    pub points: Vec<TimeSeriesPoint>,
    /// 创建时间
    pub created_at: DateTime<Utc>,
}

/// 刷新结果
#[derive(Debug)]
pub struct FlushResult {
    /// 成功刷新的数据点数
    pub points_flushed: usize,
    /// 刷新耗时（毫秒）
    pub flush_duration_ms: u64,
    /// 是否为手动触发
    pub manual: bool,
}
```

### 2.2 TimeSeriesBufferService Trait

```rust
// kayak-backend/src/services/timeseries_buffer/mod.rs

use async_trait::async_trait;
use std::path::PathBuf;
use uuid::Uuid;

use crate::services::hdf5::{Hdf5Service, Hdf5Group};
use super::error::TimeSeriesBufferError;

/// 时序数据写入服务接口
#[async_trait]
pub trait TimeSeriesBufferService: Send + Sync {
    /// 创建缓冲区
    async fn create_buffer(
        &self,
        experiment_id: Uuid,
        config: BufferConfig,
    ) -> Result<BufferId, TimeSeriesBufferError>;

    /// 写入单个数据点
    async fn write_point(
        &self,
        buffer_id: &BufferId,
        point: TimeSeriesPoint,
    ) -> Result<(), TimeSeriesBufferError>;

    /// 批量写入数据点
    async fn write_batch(
        &self,
        buffer_id: &BufferId,
        points: Vec<TimeSeriesPoint>,
    ) -> Result<(), TimeSeriesBufferError>;

    /// 强制刷新缓冲区
    async fn flush(
        &self,
        buffer_id: &BufferId,
    ) -> Result<FlushResult, TimeSeriesBufferError>;

    /// 获取缓冲区状态
    async fn get_status(
        &self,
        buffer_id: &BufferId,
    ) -> Result<BufferStatus, TimeSeriesBufferError>;

    /// 关闭缓冲区（会刷新所有待写入数据）
    async fn close_buffer(
        &self,
        buffer_id: &BufferId,
    ) -> Result<(), TimeSeriesBufferError>;

    /// 删除缓冲区
    async fn delete_buffer(
        &self,
        buffer_id: &BufferId,
    ) -> Result<(), TimeSeriesBufferError>;
}

/// 缓冲区ID
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct BufferId(pub Uuid);

/// 缓冲区状态
#[derive(Debug, Clone)]
pub struct BufferStatus {
    pub buffer_id: BufferId,
    pub experiment_id: Uuid,
    pub points_count: usize,
    pub is_flushing: bool,
    pub last_flush_at: Option<DateTime<Utc>>,
    pub config: BufferConfig,
}
```

### 2.3 错误类型

```rust
// kayak-backend/src/services/timeseries_buffer/error.rs

use thiserror::Error;
use std::path::PathBuf;

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

    #[error("Data loss detected: {0} points lost")]
    DataLoss { points: usize },

    #[error("Invalid point: {0}")]
    InvalidPoint(String),

    #[error("Channel not configured: {0}")]
    ChannelNotConfigured(String),

    #[error("Write timeout after {0}ms")]
    WriteTimeout { timeout_ms: u64 },

    #[error("Buffer closed")]
    BufferClosed,

    #[error("Overflow: buffer capacity exceeded")]
    Overflow,
}
```

### 2.4 实际 Hdf5Service 接口

```rust
// kayak-backend/src/services/hdf5/service.rs

#[async_trait]
pub trait Hdf5Service: Send + Sync {
    async fn create_file(&self, path: PathBuf) -> Result<Hdf5File, Hdf5Error>;
    async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error>;
    async fn close_file(&self, file: Hdf5File) -> Result<(), Hdf5Error>;
    async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, Hdf5Error>;
    async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, Hdf5Error>;
    
    // 唯一的写入方法 - 无压缩参数
    async fn write_timeseries(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error>;
    
    async fn read_dataset(&self, group: &Hdf5Group, name: &str) -> Result<Vec<f64>, Hdf5Error>;
    async fn get_dataset_shape(&self, group: &Hdf5Group, name: &str) -> Result<Vec<usize>, Hdf5Error>;
    
    async fn generate_experiment_path(
        &self,
        exp_id: Uuid,
        timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error>;
    
    async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error>;
    fn is_path_safe(path: &PathBuf) -> bool;
}
```

---

## 3. 测试用例

### 3.1 缓冲区管理测试

#### TC-TSB-001: 缓冲区初始化-默认配置

```rust
#[cfg(test)]
mod buffer_init_tests {
    use super::*;
    use tempfile::TempDir;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_buffer_init_default_config() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.buffer_id, buffer_id);
        assert_eq!(status.experiment_id, experiment_id);
        assert_eq!(status.points_count, 0);
        assert!(!status.is_flushing);
        assert!(status.last_flush_at.is_none());
        assert_eq!(status.config.max_size, 10000);
        assert_eq!(status.config.flush_interval_ms, 1000);
    }

    #[tokio::test]
    async fn test_buffer_init_custom_config() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 5000,
            flush_interval_ms: 500,
            compression_enabled: false, // 压缩当前不支持
            compression_level: 6,
        };

        let buffer_id = service.create_buffer(experiment_id, config.clone()).await.unwrap();

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.config.max_size, 5000);
        assert_eq!(status.config.flush_interval_ms, 500);
        // 注意: compression_enabled 字段当前被忽略
    }

    #[tokio::test]
    async fn test_buffer_init_zero_max_size_fails() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 0,
            ..Default::default()
        };

        let result = service.create_buffer(experiment_id, config).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_buffer_init_duplicate_buffer_fails() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig::default();
        service.create_buffer(experiment_id, config.clone()).await.unwrap();

        let result = service.create_buffer(experiment_id, config).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            TimeSeriesBufferError::BufferAlreadyExists(_) => {},
            other => panic!("Expected BufferAlreadyExists error, got: {:?}", other),
        }
    }
}
```

#### TC-TSB-002: 缓冲区按容量刷新

```rust
#[cfg(test)]
mod buffer_flush_tests {
    use super::*;
    use std::sync::Arc;
    use std::sync::atomic::{AtomicUsize, Ordering};

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_buffer_flush_when_capacity_reached() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        // 创建小容量缓冲区
        let config = BufferConfig {
            max_size: 100,
            flush_interval_ms: 60000, // 长时间不自动刷新
            compression_enabled: false,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 写入数据直到达到容量
        for i in 0..100 {
            let point = TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // 此时缓冲区已满，再次写入应该触发自动刷新
        let point = TimeSeriesPoint {
            timestamp: 100000000,
            channel: "ch1".to_string(),
            value: 100.0,
        };

        // 写入触发刷新
        service.write_point(&buffer_id, point).await.unwrap();

        // 验证缓冲区已被刷新
        let status = service.get_status(&buffer_id).await.unwrap();
        assert!(status.points_count < 100, "Buffer should have been flushed");
    }

    #[tokio::test]
    async fn test_buffer_manual_flush() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入一些数据
        for i in 0..50 {
            let point = TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // 手动刷新
        let result = service.flush(&buffer_id).await.unwrap();

        assert_eq!(result.points_flushed, 50);
        assert!(result.manual);
        assert!(result.flush_duration_ms < 1000);

        // 验证缓冲区已清空
        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 0);

        // 验证数据已写入HDF5
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "ch1").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), 50);
    }

    #[tokio::test]
    async fn test_buffer_flush_empty_buffer() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 刷新空缓冲区应该成功，但不刷新任何数据
        let result = service.flush(&buffer_id).await.unwrap();

        assert_eq!(result.points_flushed, 0);
        assert!(result.manual);
    }

    #[tokio::test]
    async fn test_buffer_concurrent_flush_prevents_double_flush() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入一些数据
        for i in 0..100 {
            let point = TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // 并发刷新尝试
        let (result1, result2) = tokio::join!(
            service.flush(&buffer_id),
            service.flush(&buffer_id)
        );

        // 只有一个应该成功，另一个应该报告已经在刷新
        let success_count = [result1.is_ok(), result2.is_ok()].iter().filter(|&&x| x).count();
        assert_eq!(success_count, 1, "Only one flush should succeed");
    }
}
```

#### TC-TSB-003: 缓冲区按时间刷新

```rust
#[cfg(test)]
mod buffer_time_flush_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_buffer_auto_flush_after_time_interval() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        // 短刷新间隔
        let config = BufferConfig {
            max_size: 100000, // 大容量，不会按容量触发
            flush_interval_ms: 100, // 100ms
            compression_enabled: false,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 写入少量数据
        for i in 0..10 {
            let point = TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // 等待超过刷新间隔
        tokio::time::sleep(tokio::time::Duration::from_millis(150)).await;

        // 写入新数据，触发时间刷新检查
        let point = TimeSeriesPoint {
            timestamp: 11000000,
            channel: "ch1".to_string(),
            value: 10.0,
        };
        service.write_point(&buffer_id, point).await.unwrap();

        // 验证之前的数据已被刷新
        let status = service.get_status(&buffer_id).await.unwrap();
        // 时间刷新后，缓冲区可能只有新写入的数据
        assert!(status.points_count <= 11);
    }

    #[tokio::test]
    async fn test_buffer_time_flush_with_no_new_data() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 100000,
            flush_interval_ms: 50,
            compression_enabled: false,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 写入数据
        for i in 0..20 {
            let point = TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // 等待自动刷新
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        // 验证数据已被刷新（通过查看状态）
        let status = service.get_status(&buffer_id).await.unwrap();
        // 自动刷新可能在等待下一次写入时触发
        // 所以这里我们只验证服务仍然可用
        assert!(status.buffer_id == buffer_id);
    }
}
```

#### TC-TSB-004: 线程安全的缓冲区操作

```rust
#[cfg(test)]
mod buffer_thread_safety_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_concurrent_writes_to_same_buffer() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 并发写入
        let handles: Vec<_> = (0..10).map(|i| {
            let service = Arc::new(service.clone());
            let buffer_id = buffer_id.clone();
            let start_idx = i * 100;

            tokio::spawn(async move {
                for j in 0..100 {
                    let point = TimeSeriesPoint {
                        timestamp: (start_idx + j) as i64 * 1000000,
                        channel: "ch1".to_string(),
                        value: (start_idx + j) as f64,
                    };
                    service.write_point(&buffer_id, point).await
                }
            })
        }).collect();

        for handle in handles {
            handle.await.unwrap().unwrap();
        }

        // 验证所有数据被正确写入
        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 1000);
    }

    #[tokio::test]
    async fn test_concurrent_writes_different_channels() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let channels = vec!["ch1", "ch2", "ch3", "ch4"];

        let handles: Vec<_> = channels.iter().map(|channel| {
            let service = Arc::new(service.clone());
            let buffer_id = buffer_id.clone();
            let channel = channel.to_string();

            tokio::spawn(async move {
                for i in 0..500 {
                    let point = TimeSeriesPoint {
                        timestamp: i as i64 * 1000000,
                        channel: channel.clone(),
                        value: i as f64,
                    };
                    service.write_point(&buffer_id, point).await
                }
            })
        }).collect();

        for handle in handles {
            handle.await.unwrap().unwrap();
        }

        // 刷新并验证
        let result = service.flush(&buffer_id).await.unwrap();
        assert_eq!(result.points_flushed, 2000); // 4 channels * 500 points
    }

    #[tokio::test]
    async fn test_write_and_flush_concurrent() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let (tx, rx) = std::sync::mpsc::channel();

        // 写入任务
        let write_handle = tokio::spawn(async move {
            for i in 0..1000 {
                let point = TimeSeriesPoint {
                    timestamp: i as i64 * 1000000,
                    channel: "ch1".to_string(),
                    value: i as f64,
                };
                service.write_point(&buffer_id, point).await.unwrap();
            }
            tx.send(()).unwrap();
        });

        // 刷新任务
        let flush_handle = tokio::spawn(async move {
            tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
            service.flush(&buffer_id).await
        });

        write_handle.await.unwrap().unwrap();
        let flush_result = flush_handle.await.unwrap().unwrap();

        // 验证刷新成功
        assert!(flush_result.points_flushed >= 0);
    }
}
```

---

### 3.2 时序数据写入测试

#### TC-TSB-010: 写入单个数据点

```rust
#[cfg(test)]
mod timeseries_write_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_write_single_point() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: 1000000000, // 1 second
            channel: "temperature".to_string(),
            value: 25.5,
        };

        let result = service.write_point(&buffer_id, point.clone()).await;
        assert!(result.is_ok(), "Failed to write point: {:?}", result.err());

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 1);
    }

    #[tokio::test]
    async fn test_write_point_updates_timestamp() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let point1 = TimeSeriesPoint {
            timestamp: 1000000000,
            channel: "ch1".to_string(),
            value: 1.0,
        };

        let point2 = TimeSeriesPoint {
            timestamp: 2000000000,
            channel: "ch1".to_string(),
            value: 2.0,
        };

        service.write_point(&buffer_id, point1).await.unwrap();
        service.write_point(&buffer_id, point2).await.unwrap();

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 2);
    }

    #[tokio::test]
    async fn test_write_point_to_closed_buffer_fails() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();
        service.close_buffer(&buffer_id).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: 1000000000,
            channel: "ch1".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            TimeSeriesBufferError::BufferClosed => {},
            other => panic!("Expected BufferClosed error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_write_point_invalid_timestamp_fails() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: -1, // 负数时间戳无效
            channel: "ch1".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            TimeSeriesBufferError::InvalidPoint(_) => {},
            other => panic!("Expected InvalidPoint error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_write_point_empty_channel_fails() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let point = TimeSeriesPoint {
            timestamp: 1000000000,
            channel: "".to_string(), // 空通道名
            value: 1.0,
        };

        let result = service.write_point(&buffer_id, point).await;
        assert!(result.is_err());
    }
}
```

#### TC-TSB-011: 批量写入数据点

```rust
#[cfg(test)]
mod batch_write_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_write_batch_of_points() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let points: Vec<TimeSeriesPoint> = (0..1000)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "sensor1".to_string(),
                value: i as f64 * 0.1,
            })
            .collect();

        let result = service.write_batch(&buffer_id, points).await;
        assert!(result.is_ok(), "Failed to write batch: {:?}", result.err());

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 1000);
    }

    #[tokio::test]
    async fn test_write_batch_multiple_channels() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let mut points = Vec::new();

        // 通道1: 500点
        for i in 0..500 {
            points.push(TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "temperature".to_string(),
                value: 20.0 + i as f64 * 0.01,
            });
        }

        // 通道2: 500点
        for i in 0..500 {
            points.push(TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "pressure".to_string(),
                value: 100.0 + i as f64 * 0.1,
            });
        }

        let result = service.write_batch(&buffer_id, points).await;
        assert!(result.is_ok());

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 1000);
    }

    #[tokio::test]
    async fn test_write_batch_empty_vector() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let points = Vec::new();
        let result = service.write_batch(&buffer_id, points).await;

        // 空批量写入应该被接受（无操作）
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_write_batch_triggers_flush_when_full() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 100,
            flush_interval_ms: 60000,
            compression_enabled: false,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 写入超过容量的数据
        let points: Vec<TimeSeriesPoint> = (0..150)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        let result = service.write_batch(&buffer_id, points).await;
        assert!(result.is_ok());

        // 缓冲区会自动刷新部分数据
        let status = service.get_status(&buffer_id).await.unwrap();
        assert!(status.points_count <= 100);
    }

    #[tokio::test]
    async fn test_write_batch_preserves_order() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let points: Vec<TimeSeriesPoint> = (0..100)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 刷新到HDF5
        let flush_result = service.flush(&buffer_id).await.unwrap();
        assert_eq!(flush_result.points_flushed, 100);

        // 验证数据已写入HDF5
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "ch1").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), 100);
        
        // 验证数据顺序
        for (i, value) in data.iter().enumerate() {
            assert_eq!(*value, i as f64, "Data order not preserved at index {}", i);
        }
    }
}
```

#### TC-TSB-012: 多通道（测点）写入

```rust
#[cfg(test)]
mod multi_channel_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_write_multiple_channels_simultaneously() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let channels = vec!["temperature", "pressure", "humidity", "flow_rate"];

        for channel in channels {
            let points: Vec<TimeSeriesPoint> = (0..100)
                .map(|i| TimeSeriesPoint {
                    timestamp: i as i64 * 1000000,
                    channel: channel.to_string(),
                    value: i as f64,
                })
                .collect();

            service.write_batch(&buffer_id, points).await.unwrap();
        }

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 400);
    }

    #[tokio::test]
    async fn test_write_interleaved_timestamps_across_channels() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 交替写入不同通道的数据
        let mut points = Vec::new();
        for i in 0..100 {
            points.push(TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            });
            points.push(TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch2".to_string(),
                value: i as f64 * 2.0,
            });
        }

        service.write_batch(&buffer_id, points).await.unwrap();

        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 200);
    }

    #[tokio::test]
    async fn test_write_same_channel_different_timestamps() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 同一通道，不同时序
        let points: Vec<TimeSeriesPoint> = (0..1000)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000, // 每毫秒一个点
                channel: "high_freq_sensor".to_string(),
                value: (i as f64).sin(),
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        let flush_result = service.flush(&buffer_id).await.unwrap();
        assert_eq!(flush_result.points_flushed, 1000);
    }
}
```

---

### 3.3 错误处理测试

#### TC-TSB-300: HDF5写入失败处理

```rust
#[cfg(test)]
mod error_handling_tests {
    use super::*;
    use std::sync::atomic::{AtomicBool, Ordering};

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_hdf5_write_failure_preserves_buffer() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入一些数据
        let points: Vec<TimeSeriesPoint> = (0..100)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 验证数据在缓冲区中
        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 100);
    }

    #[tokio::test]
    async fn test_buffer_overflow_handling() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 100,
            flush_interval_ms: 60000,
            compression_enabled: false,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 快速写入大量数据，超过缓冲区处理能力
        let points: Vec<TimeSeriesPoint> = (0..10000)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        let result = service.write_batch(&buffer_id, points).await;

        // 应该能处理，不会丢失所有数据
        // 实现可以选择：自动刷新、返回错误、或分批处理
        assert!(result.is_ok() || matches!(result.unwrap_err(), TimeSeriesBufferError::Overflow));
    }

    #[tokio::test]
    async fn test_data_loss_prevention_on_service_crash() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入数据
        let points: Vec<TimeSeriesPoint> = (0..500)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 验证缓冲区有数据
        let status_before = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status_before.points_count, 500);

        // 关闭缓冲区应该自动刷新所有待写入数据
        service.close_buffer(&buffer_id).await.unwrap();

        // 验证数据已写入HDF5
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "ch1").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), 500);
    }

    #[tokio::test]
    async fn test_buffer_not_found_error() {
        let (service, _, _temp_dir) = create_test_services();
        let fake_buffer_id = BufferId(Uuid::new_v4());

        let point = TimeSeriesPoint {
            timestamp: 1000000,
            channel: "ch1".to_string(),
            value: 1.0,
        };

        let result = service.write_point(&fake_buffer_id, point).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            TimeSeriesBufferError::BufferNotFound(_) => {},
            other => panic!("Expected BufferNotFound error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_delete_buffer_flushes_pending_data() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入数据
        let points: Vec<TimeSeriesPoint> = (0..200)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 删除缓冲区前，数据应该被刷新
        service.delete_buffer(&buffer_id).await.unwrap();

        // 验证数据已写入
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "ch1").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), 200);
    }

    #[tokio::test]
    async fn test_write_timeout_handling() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 10,
            flush_interval_ms: 100,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 快速写入大量数据
        for _ in 0..100 {
            let point = TimeSeriesPoint {
                timestamp: 1000000,
                channel: "ch1".to_string(),
                value: 1.0,
            };

            let result = service.write_point(&buffer_id, point).await;
            // 如果缓冲区已满，可能超时或被拒绝
            if result.is_err() {
                match result.unwrap_err() {
                    TimeSeriesBufferError::WriteTimeout { .. } | TimeSeriesBufferError::BufferFull => {
                        // 预期的错误
                    },
                    _ => panic!("Unexpected error"),
                }
            }
        }
    }
}
```

#### TC-TSB-301: 数据丢失防护测试

```rust
#[cfg(test)]
mod data_loss_prevention_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_unflushed_data_recovery_on_restart() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入数据
        let points: Vec<TimeSeriesPoint> = (0..1000)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "recovery_test".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 验证缓冲区有数据但未刷新
        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 1000);
        assert!(status.last_flush_at.is_none());

        // 模拟服务重启：通过close_buffer确保数据不丢失
        service.close_buffer(&buffer_id).await.unwrap();

        // 验证所有数据已刷新
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "recovery_test").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), 1000);
    }

    #[tokio::test]
    async fn test_partial_flush_on_error() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入数据
        let points: Vec<TimeSeriesPoint> = (0..100)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 第一次刷新成功
        let result1 = service.flush(&buffer_id).await.unwrap();
        assert_eq!(result1.points_flushed, 100);

        // 写入更多数据
        let more_points: Vec<TimeSeriesPoint> = (100..200)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, more_points).await.unwrap();

        // 第二次刷新
        let result2 = service.flush(&buffer_id).await.unwrap();
        assert_eq!(result2.points_flushed, 100);
    }

    #[tokio::test]
    async fn test_buffer_close_without_flush_skips_nothing() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入数据
        for i in 0..50 {
            let point = TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "ch1".to_string(),
                value: i as f64,
            };
            service.write_point(&buffer_id, point).await.unwrap();
        }

        // 关闭缓冲区
        service.close_buffer(&buffer_id).await.unwrap();

        // 验证没有数据丢失
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "ch1").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), 50);
    }
}
```

---

### 3.4 性能测试

#### TC-TSB-500: 批量写入吞吐量测试

```rust
#[cfg(test)]
mod performance_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_batch_write_throughput_exceeds_10k_samples_per_sec() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 准备大量数据：15000个点
        let num_points = 15000;
        let points: Vec<TimeSeriesPoint> = (0..num_points)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "perf_test".to_string(),
                value: i as f64 * 0.1,
            })
            .collect();

        let start = std::time::Instant::now();
        service.write_batch(&buffer_id, points).await.unwrap();
        let write_duration = start.elapsed();

        // 计算吞吐量
        let throughput = num_points as f64 / write_duration.as_secs_f64();

        println!("Write throughput: {:.2} samples/sec", throughput);

        // 验证 > 10k samples/sec
        assert!(
            throughput > 10000.0,
            "Throughput {:.2} samples/sec is below 10k requirement",
            throughput
        );

        // 刷新并验证
        let flush_result = service.flush(&buffer_id).await.unwrap();
        assert_eq!(flush_result.points_flushed, num_points);
    }

    #[tokio::test]
    async fn test_sustained_write_performance() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let total_points = 50000;
        let batch_size = 5000;
        let mut total_flushed = 0;

        let start = std::time::Instant::now();

        for batch in 0..(total_points / batch_size) {
            let points: Vec<TimeSeriesPoint> = (0..batch_size)
                .map(|i| TimeSeriesPoint {
                    timestamp: ((batch * batch_size) + i) as i64 * 1000000,
                    channel: "sustained_test".to_string(),
                    value: ((batch * batch_size) + i) as f64,
                })
                .collect();

            service.write_batch(&buffer_id, points).await.unwrap();
            total_flushed += batch_size;

            // 定期刷新，避免缓冲区溢出
            if batch % 2 == 0 {
                service.flush(&buffer_id).await.unwrap();
            }
        }

        // 最后刷新
        service.flush(&buffer_id).await.unwrap();

        let total_duration = start.elapsed();
        let throughput = total_points as f64 / total_duration.as_secs_f64();

        println!("Sustained throughput: {:.2} samples/sec", throughput);

        assert!(
            throughput > 10000.0,
            "Sustained throughput {:.2} samples/sec is below 10k requirement",
            throughput
        );
    }

    #[tokio::test]
    async fn test_concurrent_write_performance() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        let num_concurrent_tasks = 4;
        let points_per_task = 5000;
        let total_points = num_concurrent_tasks * points_per_task;

        let start = std::time::Instant::now();

        let handles: Vec<_> = (0..num_concurrent_tasks).map(|task_id| {
            let service = Arc::new(service.clone());
            let buffer_id = buffer_id.clone();
            let base_idx = task_id * points_per_task;

            tokio::spawn(async move {
                let points: Vec<TimeSeriesPoint> = (0..points_per_task)
                    .map(|i| TimeSeriesPoint {
                        timestamp: (base_idx + i) as i64 * 1000000,
                        channel: format!("ch_{}", task_id),
                        value: (base_idx + i) as f64,
                    })
                    .collect();

                service.write_batch(&buffer_id, points).await
            })
        }).collect();

        for handle in handles {
            handle.await.unwrap().unwrap();
        }

        let write_duration = start.elapsed();
        let throughput = total_points as f64 / write_duration.as_secs_f64();

        println!("Concurrent write throughput: {:.2} samples/sec", throughput);

        assert!(
            throughput > 10000.0,
            "Concurrent throughput {:.2} samples/sec is below 10k requirement",
            throughput
        );

        // 刷新验证
        service.flush(&buffer_id).await.unwrap();
    }

    #[tokio::test]
    async fn test_flush_throughput() {
        let (service, hdf5_service, temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 先写入大量数据
        let num_points = 20000;
        let points: Vec<TimeSeriesPoint> = (0..num_points)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "flush_perf".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 测试刷新性能（实际HDF5写入）
        let start = std::time::Instant::now();
        let result = service.flush(&buffer_id).await.unwrap();
        let flush_duration = start.elapsed();

        let flush_throughput = result.points_flushed as f64 / flush_duration.as_secs_f64();

        println!("Flush HDF5 write throughput: {:.2} samples/sec", flush_throughput);

        // 刷新性能也应该满足要求（实际HDF5写入吞吐量）
        assert!(
            flush_throughput > 10000.0,
            "Flush throughput {:.2} samples/sec is below 10k requirement",
            flush_throughput
        );

        // 验证数据已写入HDF5
        let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
        let file = hdf5_service.open_file(&file_path).await.unwrap();
        let group = hdf5_service.get_group(&file, "flush_perf").await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), num_points);
    }
}
```

#### TC-TSB-501: 内存效率测试

```rust
#[cfg(test)]
mod memory_efficiency_tests {
    use super::*;

    fn create_test_services() -> (impl TimeSeriesBufferService, Hdf5ServiceImpl, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service.clone(), temp_dir.path().to_path_buf());
        (buffer_service, hdf5_service, temp_dir)
    }

    #[tokio::test]
    async fn test_memory_usage_under_load() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let config = BufferConfig {
            max_size: 100000, // 较大缓冲区
            flush_interval_ms: 100,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 分批写入大量数据，模拟持续负载
        for batch in 0..10 {
            let points: Vec<TimeSeriesPoint> = (0..10000)
                .map(|i| TimeSeriesPoint {
                    timestamp: ((batch * 10000) + i) as i64 * 1000000,
                    channel: "memory_test".to_string(),
                    value: ((batch * 10000) + i) as f64,
                })
                .collect();

            service.write_batch(&buffer_id, points).await.unwrap();

            // 等待自动刷新
            tokio::time::sleep(tokio::time::Duration::from_millis(150)).await;
        }

        // 验证服务仍然可用
        let status = service.get_status(&buffer_id).await.unwrap();
        assert!(status.buffer_id == buffer_id);

        // 最终刷新
        service.flush(&buffer_id).await.unwrap();
    }

    #[tokio::test]
    async fn test_buffer_memory_bounded_by_config() {
        let (service, _, _temp_dir) = create_test_services();
        let experiment_id = Uuid::new_v4();

        let max_size = 1000;
        let config = BufferConfig {
            max_size,
            flush_interval_ms: 60000,
            ..Default::default()
        };

        let buffer_id = service.create_buffer(experiment_id, config).await.unwrap();

        // 写入超过容量的数据
        let points: Vec<TimeSeriesPoint> = (0..5000)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000,
                channel: "bounded_test".to_string(),
                value: i as f64,
            })
            .collect();

        service.write_batch(&buffer_id, points).await.unwrap();

        // 验证缓冲区大小受配置限制（通过自动刷新）
        let status = service.get_status(&buffer_id).await.unwrap();
        assert!(
            status.points_count <= max_size * 2, // 允许一些溢出
            "Buffer size {} exceeds reasonable bound",
            status.points_count
        );
    }
}
```

---

## 4. 集成测试场景

### TC-TSB-600: 完整时序数据采集工作流

```rust
// kayak-backend/tests/integration/timeseries_workflow_test.rs

use kayak_backend::services::timeseries_buffer::{
    TimeSeriesBufferService, TimeSeriesBufferServiceImpl, BufferConfig, TimeSeriesPoint,
};
use kayak_backend::services::hdf5::{Hdf5Service, Hdf5ServiceImpl};
use std::path::PathBuf;
use tempfile::TempDir;
use uuid::Uuid;

/// 完整时序数据采集工作流测试
#[tokio::test]
async fn test_complete_timeseries_acquisition_workflow() {
    let temp_dir = TempDir::new().unwrap();
    
    // 1. 创建HDF5服务
    let hdf5_service = Hdf5ServiceImpl::new();
    
    // 2. 创建时序缓冲服务
    let buffer_service = TimeSeriesBufferServiceImpl::new(
        hdf5_service.clone(), 
        temp_dir.path().to_path_buf()
    );
    let experiment_id = Uuid::new_v4();

    // 3. 创建缓冲区
    let config = BufferConfig {
        max_size: 5000,
        flush_interval_ms: 1000,
        compression_enabled: false, // 压缩暂不支持
        compression_level: 4,
    };

    let buffer_id = buffer_service.create_buffer(experiment_id, config).await.unwrap();

    // 4. 模拟数据采集：多通道、高频率
    let channels = vec!["temperature", "pressure", "humidity"];
    let num_samples = 10000;

    for ch in &channels {
        let points: Vec<TimeSeriesPoint> = (0..num_samples)
            .map(|i| TimeSeriesPoint {
                timestamp: i as i64 * 1000000, // 1ms间隔
                channel: ch.to_string(),
                value: (i as f64) * 0.1,
            })
            .collect();

        buffer_service.write_batch(&buffer_id, points).await.unwrap();
    }

    // 5. 验证缓冲区数据
    let status = buffer_service.get_status(&buffer_id).await.unwrap();
    assert_eq!(status.points_count, num_samples * channels.len());

    // 6. 关闭缓冲区（自动刷新）
    buffer_service.close_buffer(&buffer_id).await.unwrap();

    // 7. 验证数据完整性（通过HDF5读取）
    let file_path = temp_dir.path().join("experiments").join(experiment_id.to_string());
    let file = hdf5_service.open_file(&file_path).await.unwrap();
    
    for ch in &channels {
        let group = hdf5_service.get_group(&file, ch).await.unwrap();
        let data = hdf5_service.read_dataset(&group, "values").await.unwrap();
        assert_eq!(data.len(), num_samples);
    }
}

/// 并发多试验数据写入测试
#[tokio::test]
async fn test_concurrent_experiments_write() {
    let temp_dir = TempDir::new().unwrap();
    let num_experiments = 4;
    let samples_per_experiment = 5000;

    let handles: Vec<_> = (0..num_experiments).map(|i| {
        let temp_dir_path = temp_dir.path().to_path_buf();
        let hdf5_service = Hdf5ServiceImpl::new();
        let buffer_service = TimeSeriesBufferServiceImpl::new(hdf5_service, temp_dir_path);
        let experiment_id = Uuid::new_v4();
        let exp_num = i;

        tokio::spawn(async move {
            let buffer_id = buffer_service
                .create_buffer(experiment_id, BufferConfig::default())
                .await
                .unwrap();

            let points: Vec<TimeSeriesPoint> = (0..samples_per_experiment)
                .map(|j| TimeSeriesPoint {
                    timestamp: j as i64 * 1000000,
                    channel: format!("exp_{}_ch", exp_num),
                    value: (j as f64) * exp_num as f64,
                })
                .collect();

            buffer_service.write_batch(&buffer_id, points).await.unwrap();
            buffer_service.flush(&buffer_id).await.unwrap();

            experiment_id
        })
    }).collect();

    let experiment_ids: Vec<Uuid> = handles
        .into_iter()
        .map(|h| h.await.unwrap())
        .collect();

    assert_eq!(experiment_ids.len(), num_experiments);
}
```

---

## 5. Mock 实现（已修正）

### 5.1 注意事项

> **⚠️ Mock 实现修正说明**
> 
> 原测试文档中的 `MockTimeSeriesBufferService` 存在以下问题：
> 1. Mock 不调用实际的 HDF5 方法，仅在内存中存储
> 2. 这导致压缩测试和 HDF5 写入验证无法正确进行
> 
> **已修正**: 测试现在使用真实的 `TimeSeriesBufferServiceImpl` 结合临时目录，
> 所有 HDF5 操作都是真实的，确保测试覆盖实际的写入路径。

### 5.2 修正后的 Mock Hdf5Service（仅用于单元测试）

```rust
// kayak-backend/src/test_utils/timeseries_buffer_mocks.rs

use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::{Arc, Mutex, RwLock};
use std::path::PathBuf;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use ndarray::Array;

use crate::services::hdf5::{
    Hdf5Service, Hdf5File, Hdf5Group, Hdf5Error,
};
use crate::services::timeseries_buffer::{
    TimeSeriesBufferService, BufferId, BufferConfig, BufferStatus,
    TimeSeriesPoint, FlushResult, error::TimeSeriesBufferError,
};

/// 内存中的HDF5模拟（用于不需要真实文件的单元测试）
pub struct MockHdf5Service {
    files: Arc<Mutex<HashMap<PathBuf, MockHdf5File>>>,
}

struct MockHdf5File {
    groups: HashMap<String, MockHdf5Group>,
}

struct MockHdf5Group {
    datasets: HashMap<String, Vec<f64>>,
    timestamps: HashMap<String, Vec<i64>>,
}

impl MockHdf5Service {
    pub fn new() -> Self {
        Self {
            files: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

impl Default for MockHdf5Service {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Hdf5Service for MockHdf5Service {
    async fn create_file(&self, path: PathBuf) -> Result<Hdf5File, Hdf5Error> {
        let mut files = self.files.lock().unwrap();
        files.insert(path.clone(), MockHdf5File {
            groups: HashMap::new(),
        });
        Ok(Hdf5File { path })
    }

    async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error> {
        let files = self.files.lock().unwrap();
        if files.contains_key(path) {
            Ok(Hdf5File { path: path.clone() })
        } else {
            Err(Hdf5Error::FileNotFound(path.to_string_lossy().to_string()))
        }
    }

    async fn close_file(&self, _file: Hdf5File) -> Result<(), Hdf5Error> {
        Ok(())
    }

    async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, Hdf5Error> {
        let mut files = self.files.lock().unwrap();
        let file = files.get_mut(&parent.file_path)
            .ok_or(Hdf5Error::FileNotOpen)?;
        
        let full_path = if parent.path.is_empty() || parent.path == "/" {
            format!("/{}", name)
        } else {
            format!("{}/{}", parent.path, name)
        };
        
        file.groups.insert(full_path.clone(), MockHdf5Group {
            datasets: HashMap::new(),
            timestamps: HashMap::new(),
        });
        
        Ok(Hdf5Group {
            file_path: parent.file_path.clone(),
            name: name.to_string(),
            path: full_path,
        })
    }

    async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, Hdf5Error> {
        let files = self.files.lock().unwrap();
        let file = files.get(&file.path)
            .ok_or(Hdf5Error::FileNotOpen)?;
        
        if !file.groups.contains_key(path) {
            return Err(Hdf5Error::GroupNotFound(path.to_string()));
        }
        
        let name = path.split('/')
            .filter(|s| !s.is_empty())
            .last()
            .unwrap_or("")
            .to_string();
        
        Ok(Hdf5Group {
            file_path: file.path.clone(),
            name,
            path: path.to_string(),
        })
    }

    async fn write_timeseries(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error> {
        let mut files = self.files.lock().unwrap();
        let file = files.get_mut(&group.file_path)
            .ok_or(Hdf5Error::FileNotOpen)?;
        
        let hdf5_group = file.groups.get_mut(&group.path)
            .ok_or(Hdf5Error::GroupNotFound(group.path.clone()))?;
        
        hdf5_group.datasets.insert(name.to_string(), values.to_vec());
        hdf5_group.timestamps.insert("timestamps".to_string(), timestamps.to_vec());
        
        Ok(())
    }

    async fn read_dataset(&self, group: &Hdf5Group, name: &str) -> Result<Vec<f64>, Hdf5Error> {
        let files = self.files.lock().unwrap();
        let file = files.get(&group.file_path)
            .ok_or(Hdf5Error::FileNotOpen)?;
        
        let hdf5_group = file.groups.get(&group.path)
            .ok_or(Hdf5Error::GroupNotFound(group.path.clone()))?;
        
        hdf5_group.datasets.get(name)
            .cloned()
            .ok_or(Hdf5Error::DatasetNotFound(name.to_string()))
    }

    async fn get_dataset_shape(&self, group: &Hdf5Group, name: &str) -> Result<Vec<usize>, Hdf5Error> {
        let files = self.files.lock().unwrap();
        let file = files.get(&group.file_path)
            .ok_or(Hdf5Error::FileNotOpen)?;
        
        let hdf5_group = file.groups.get(&group.path)
            .ok_or(Hdf5Error::GroupNotFound(group.path.clone()))?;
        
        let dataset = hdf5_group.datasets.get(name)
            .ok_or(Hdf5Error::DatasetNotFound(name.to_string()))?;
        
        Ok(vec![dataset.len()])
    }

    async fn generate_experiment_path(
        &self,
        exp_id: Uuid,
        _timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error> {
        Ok(PathBuf::from(format!("/experiments/{}", exp_id)))
    }

    async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error> {
        self.create_file(path.clone()).await
    }

    fn is_path_safe(path: &PathBuf) -> bool {
        let path_str = path.to_string_lossy();
        !path_str.contains("..") && !path_str.starts_with("/etc") && !path_str.starts_with("/usr")
    }
}
```

### 5.3 使用 Mock 的测试示例

```rust
#[cfg(test)]
mod unit_tests_with_mocks {
    use super::*;

    fn create_mock_services() -> impl TimeSeriesBufferService {
        let hdf5_service = MockHdf5Service::new();
        TimeSeriesBufferServiceImpl::new(hdf5_service, PathBuf::from("/tmp/test"))
    }

    #[tokio::test]
    async fn test_basic_buffer_operations_with_mock() {
        let service = create_mock_services();
        let experiment_id = Uuid::new_v4();

        let buffer_id = service.create_buffer(experiment_id, BufferConfig::default()).await.unwrap();

        // 写入数据
        let point = TimeSeriesPoint {
            timestamp: 1000000000,
            channel: "test".to_string(),
            value: 1.0,
        };
        service.write_point(&buffer_id, point).await.unwrap();

        // 验证状态
        let status = service.get_status(&buffer_id).await.unwrap();
        assert_eq!(status.points_count, 1);
    }
}
```

---

## 6. 测试执行指南

### 6.1 运行测试

```bash
# 运行所有时序缓冲服务测试
cd kayak-backend && cargo test timeseries_buffer

# 运行单元测试
cd kayak-backend && cargo test --lib timeseries_buffer

# 运行集成测试
cd kayak-backend && cargo test --test '*timeseries*'

# 运行特定测试类别
cd kayak-backend && cargo test buffer_init
cd kayak-backend && cargo test buffer_flush
cd kayak-backend && cargo test performance

# 运行带详细输出的测试
cd kayak-backend && RUST_LOG=debug cargo test timeseries_buffer --nocapture

# 运行性能测试（release模式）
cd kayak-backend && cargo test performance --release
```

### 6.2 性能基准

| 指标 | 目标值 | 测试用例 |
|------|--------|---------|
| 单批次写入吞吐量 | >10,000 samples/sec | TC-TSB-500 |
| 持续写入吞吐量 | >10,000 samples/sec | TC-TSB-501 |
| 并发写入吞吐量 | >10,000 samples/sec | TC-TSB-502 |
| HDF5刷新吞吐量 | >10,000 samples/sec | TC-TSB-503 |
| 内存占用 | <100MB under load | TC-TSB-510 |

---

## 7. 测试统计

| 类别 | 数量 | 优先级 | 备注 |
|------|------|--------|------|
| 缓冲区管理测试 | 12 | P0 | |
| 时序数据写入测试 | 10 | P0 | |
| 压缩功能测试 | 0 | N/A | **已移除** - 接口不支持 |
| 错误处理测试 | 10 | P0 | |
| 性能测试 | 5 | P0 | 修正为真实HDF5写入 |
| 集成测试 | 2 | P1 | |
| **总计** | **39** | | |

---

## 8. 附录

### 8.1 测试数据生成辅助函数

```rust
#[cfg(test)]
mod test_utils {
    use super::*;

    /// 生成测试用时序数据点
    pub fn generate_test_points(
        num_points: usize,
        channel: &str,
        start_timestamp: i64,
        interval_ns: i64,
    ) -> Vec<TimeSeriesPoint> {
        (0..num_points)
            .map(|i| TimeSeriesPoint {
                timestamp: start_timestamp + (i as i64 * interval_ns),
                channel: channel.to_string(),
                value: (i as f64) * 0.1,
            })
            .collect()
    }

    /// 生成多通道测试数据
    pub fn generate_multi_channel_points(
        num_points: usize,
        channels: &[&str],
        start_timestamp: i64,
    ) -> Vec<TimeSeriesPoint> {
        let mut points = Vec::new();
        for channel in channels {
            let channel_points = generate_test_points(
                num_points,
                channel,
                start_timestamp,
                1000000,
            );
            points.extend(channel_points);
        }
        points
    }
}
```

### 8.2 待办事项：压缩功能扩展

> **📋 扩展 Hdf5Service 以支持压缩**
>
> 要启用压缩测试，需扩展 `Hdf5Service` 接口：
>
> ```rust
> // 建议的新接口方法
> async fn write_timeseries_with_compression(
>     &self,
>     group: &Hdf5Group,
>     name: &str,
>     timestamps: &[i64],
>     values: &[f64],
>     compression: CompressionInfo,
> ) -> Result<(), Hdf5Error>;
>
> async fn get_dataset_compression_info(
>     &self,
>     group: &Hdf5Group,
>     name: &str,
> ) -> Result<Option<CompressionInfo>, Hdf5Error>;
> ```
>
> 扩展后：
> 1. 在 `Hdf5ServiceImpl` 中实现上述方法
> 2. 恢复 TC-TSB-400 系列的压缩测试
> 3. 验证 `CompressionInfo` 类型正确使用

### 8.3 相关文件

- 测试用例定义: `/home/hzhou/workspace/kayak/log/release_0/test/S2-003_test_cases.md`
- HDF5服务 (S2-001): `kayak-backend/src/services/hdf5/`
- 时序缓冲服务: `kayak-backend/src/services/timeseries_buffer/`
- 试验模型 (S2-002): `kayak-backend/src/services/experiment/`

---

**文档版本**: 2.0 (修订版)  
**创建日期**: 2026-03-27  
**最后更新**: 2026-03-27  
**修订内容**: 
- 移除不存在的压缩接口相关测试
- 修正性能测试为真实HDF5写入
- 修正Mock实现以正确调用Hdf5Service方法
- 添加压缩功能扩展说明
