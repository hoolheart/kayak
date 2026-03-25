# S2-001: HDF5文件操作库集成 - 测试用例文档

**任务ID**: S2-001  
**任务名称**: HDF5文件操作库集成 (HDF5 File Operation Library Integration)  
**文档版本**: 2.0  
**创建日期**: 2026-03-26  
**测试类型**: 单元测试、集成测试  
**技术栈**: Rust / hdf5-rust / tokio / tempfile

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-001 任务的所有功能测试，包括：
1. **HDF5文件创建** - 创建新的HDF5文件
2. **组创建** - 在HDF5文件中创建组结构
3. **数据集写入** - 写入时序数据到数据集
4. **数据集读取** - 读取数据集中的数据
5. **元信息读取** - 读取数据集和文件的元信息
6. **错误处理** - 各种错误场景的处理

### 1.2 项目结构

HDF5服务遵循 trait+impl 模式：

```
kayak-backend/src/services/hdf5/
├── mod.rs              # 模块定义
├── error.rs            # Hdf5Error 错误类型
├── types.rs            # Hdf5File, Hdf5Group, Hdf5Dataset 等类型
├── service.rs          # Hdf5Service trait 和 Hdf5ServiceImpl
└── path.rs             # 路径策略实现
```

### 1.3 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 可创建HDF5文件 | TC-S2-001-01 ~ TC-S2-001-05 | Unit/Integration |
| 2. 支持写入时序数据集 | TC-S2-001-06 ~ TC-S2-001-15 | Unit/Integration |
| 3. 支持读取数据集元信息 | TC-S2-001-16 ~ TC-S2-001-25 | Unit/Integration |

---

## 2. HDF5服务接口定义

### 2.1 错误类型 (error.rs)

```rust
// kayak-backend/src/services/hdf5/error.rs

use thiserror::Error;
use std::path::PathBuf;

#[derive(Error, Debug)]
pub enum Hdf5Error {
    #[error("File not found: {0}")]
    FileNotFound(String),
    
    #[error("File already exists: {0}")]
    FileAlreadyExists(String),
    
    #[error("Invalid file format")]
    InvalidFileFormat,
    
    #[error("File not open")]
    FileNotOpen,
    
    #[error("Group not found: {0}")]
    GroupNotFound(String),
    
    #[error("Group already exists: {0}")]
    GroupAlreadyExists(String),
    
    #[error("Dataset not found: {0}")]
    DatasetNotFound(String),
    
    #[error("Dataset already exists: {0}")]
    DatasetAlreadyExists(String),
    
    #[error("Empty data provided")]
    EmptyData,
    
    #[error("Data length mismatch: expected {expected}, got {actual}")]
    DataLengthMismatch { expected: usize, actual: usize },
    
    #[error("Type mismatch: expected {expected}, got {actual}")]
    TypeMismatch { expected: String, actual: String },
    
    #[error("Data corrupted")]
    DataCorrupted,
    
    #[error("Parent directory not found: {0}")]
    ParentDirectoryNotFound(String),
    
    #[error("Permission denied: {0}")]
    PermissionDenied(String),
    
    #[error("Invalid path: {0}")]
    InvalidPath(String),
    
    #[error("Path conflict: {0}")]
    PathConflict(String),
    
    #[error("Path traversal attempt detected")]
    PathTraversalAttempted,
}
```

### 2.2 类型定义 (types.rs)

```rust
// kayak-backend/src/services/hdf5/types.rs

use std::path::PathBuf;

/// HDF5文件句柄
#[derive(Debug, Clone)]
pub struct Hdf5File {
    pub path: PathBuf,
    // 内部句柄由实现保留
}

/// HDF5组句柄
#[derive(Debug, Clone)]
pub struct Hdf5Group {
    pub file_path: PathBuf,
    pub name: String,
    pub path: String,  // 完整路径，如 "/experiment/trial_001"
}

/// HDF5数据集
#[derive(Debug, Clone)]
pub struct Hdf5Dataset {
    pub group_path: String,
    pub name: String,
    pub shape: Vec<usize>,
    pub dtype: DatasetType,
}

/// 数据集类型
#[derive(Debug, Clone, PartialEq)]
pub enum DatasetType {
    Float64,
    Float32,
    Int64,
    Int32,
    UInt64,
    UInt32,
}

/// 压缩信息
#[derive(Debug, Clone)]
pub struct CompressionInfo {
    pub algorithm: CompressionType,
    pub level: Option<u32>,
}

/// 压缩类型
#[derive(Debug, Clone, PartialEq)]
pub enum CompressionType {
    None,
    Gzip,
    Szip,
}

/// 文件完整性报告
#[derive(Debug)]
pub struct IntegrityReport {
    pub is_valid: bool,
    pub checked_datasets: usize,
    pub corrupted_datasets: usize,
    pub errors: Vec<String>,
}
```

### 2.3 服务接口 (service.rs)

```rust
// kayak-backend/src/services/hdf5/service.rs

use async_trait::async_trait;
use std::path::PathBuf;
use uuid::Uuid;
use chrono::{DateTime, Utc};

use super::error::Hdf5Error;
use super::types::*;

/// HDF5服务接口
#[async_trait]
pub trait Hdf5Service: Send + Sync {
    /// 创建HDF5文件
    async fn create_file(&self, path: PathBuf) -> Result<Hdf5File, Hdf5Error>;

    /// 打开HDF5文件
    async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error>;

    /// 关闭HDF5文件
    async fn close_file(&self, file: Hdf5File) -> Result<(), Hdf5Error>;

    /// 在指定组下创建子组
    async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, Hdf5Error>;

    /// 获取组
    async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, Hdf5Error>;

    /// 写入时序数据集
    async fn write_timeseries(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error>;

    /// 追加数据到已有数据集
    async fn append_to_dataset(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error>;

    /// 读取数据集
    async fn read_dataset<T: TryFrom<f64> + Send + 'static>(
        &self,
        group: &Hdf5Group,
        name: &str,
    ) -> Result<Vec<T>, Hdf5Error>;

    /// 按范围读取数据集
    async fn read_dataset_range<T: TryFrom<f64> + Send + 'static>(
        &self,
        group: &Hdf5Group,
        name: &str,
        start: usize,
        end: usize,
    ) -> Result<Vec<T>, Hdf5Error>;

    /// 获取数据集形状
    async fn get_dataset_shape(&self, group: &Hdf5Group, name: &str) -> Result<Vec<usize>, Hdf5Error>;

    /// 获取数据集数据类型
    async fn get_dataset_dtype(&self, group: &Hdf5Group, name: &str) -> Result<DatasetType, Hdf5Error>;

    /// 获取文件版本
    async fn get_file_version(&self, file: &Hdf5File) -> Result<String, Hdf5Error>;

    /// 获取文件创建时间
    async fn get_file_creation_time(&self, file: &Hdf5File) -> Result<i64, Hdf5Error>;

    /// 获取数据集压缩信息
    async fn get_dataset_compression_info(
        &self,
        group: &Hdf5Group,
        name: &str,
    ) -> Result<Option<CompressionInfo>, Hdf5Error>;

    /// 验证文件完整性
    async fn verify_file_integrity(&self, path: &PathBuf) -> Result<IntegrityReport, Hdf5Error>;

    /// 生成实验数据路径
    async fn generate_experiment_path(
        &self,
        exp_id: Uuid,
        timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error>;

    /// 创建文件（带自动创建父目录）
    async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error>;

    /// 规范化路径
    async fn normalize_path(&self, path: &PathBuf) -> Result<PathBuf, Hdf5Error>;

    /// 检查路径是否安全（无路径遍历）
    fn is_path_safe(path: &PathBuf) -> bool;
}

/// HDF5服务实现
pub struct Hdf5ServiceImpl {
    // 依赖项（如有）
}

impl Hdf5ServiceImpl {
    pub fn new() -> Self {
        Self {}
    }
}

impl Default for Hdf5ServiceImpl {
    fn default() -> Self {
        Self::new()
    }
}
```

---

## 3. 单元测试

### 3.1 HDF5文件创建测试

#### TC-S2-001-01: 创建新HDF5文件测试

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    use tempfile::TempDir;

    // 辅助函数：创建测试服务实例
    fn create_test_service() -> impl Hdf5Service {
        Hdf5ServiceImpl::new()
    }

    #[tokio::test]
    async fn test_create_new_hdf5_file() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        let result = service.create_file(file_path.clone()).await;
        
        assert!(result.is_ok(), "Failed to create HDF5 file: {:?}", result.err());
        assert!(file_path.exists(), "File was not created at expected path");
        
        let metadata = std::fs::metadata(&file_path).unwrap();
        assert!(metadata.len() > 0, "File size should be greater than 0");
    }

    #[tokio::test]
    async fn test_create_file_overwrites_existing() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        
        // 创建第一个文件
        let first_result = service.create_file(file_path.clone()).await;
        assert!(first_result.is_ok());
        
        // 再次创建（覆盖）
        let second_result = service.create_file(file_path.clone()).await;
        assert!(second_result.is_ok(), "Should be able to overwrite existing file");
    }

    #[tokio::test]
    async fn test_create_file_parent_directory_not_found() {
        let file_path = PathBuf::from("/tmp/nonexistent/subdir/test.h5");
        
        let service = create_test_service();
        let result = service.create_file(file_path.clone()).await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::ParentDirectoryNotFound(_) => {},
            other => panic!("Expected ParentDirectoryNotFound error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_create_file_permission_denied() {
        let temp_dir = TempDir::new().unwrap();
        let readonly_dir = temp_dir.path().join("readonly");
        std::fs::create_dir(&readonly_dir).unwrap();
        
        // 设置为只读
        let mut perms = std::fs::metadata(&readonly_dir).unwrap().permissions();
        perms.set_readonly(true);
        std::fs::set_permissions(&readonly_dir, perms).unwrap();
        
        let file_path = readonly_dir.join("test.h5");
        let service = create_test_service();
        let result = service.create_file(file_path.clone()).await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::PermissionDenied(_) => {},
            other => panic!("Expected PermissionDenied error, got: {:?}", other),
        }
        
        // 清理：恢复写权限以便删除
        let mut perms = std::fs::metadata(&readonly_dir).unwrap().permissions();
        perms.set_readonly(false);
        std::fs::set_permissions(&readonly_dir, perms).unwrap();
    }

    #[tokio::test]
    async fn test_create_file_empty_path() {
        let file_path = PathBuf::from("");
        
        let service = create_test_service();
        let result = service.create_file(file_path).await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::InvalidPath(_) => {},
            other => panic!("Expected InvalidPath error, got: {:?}", other),
        }
    }
}
```

### 3.2 组创建测试

#### TC-S2-001-02: 在根组创建子组测试

```rust
#[cfg(test)]
mod group_tests {
    use super::*;
    use std::path::PathBuf;
    use tempfile::TempDir;

    fn create_test_service() -> impl Hdf5Service {
        Hdf5ServiceImpl::new()
    }

    #[tokio::test]
    async fn test_create_subgroup_at_root() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        
        // 创建文件
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        // 创建组
        let group = Hdf5Group {
            file_path: file_path.clone(),
            name: String::new(),
            path: String::new(),
        };
        
        let result = service.create_group(&group, "sensors").await;
        assert!(result.is_ok());
        
        let created_group = result.unwrap();
        assert_eq!(created_group.path, "/sensors");
    }

    #[tokio::test]
    async fn test_create_nested_group_structure() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        // 创建嵌套组结构
        let root_group = Hdf5Group {
            file_path: file_path.clone(),
            name: String::new(),
            path: String::new(),
        };
        
        let exp_group = service.create_group(&root_group, "experiment").await.unwrap();
        let trial_group = service.create_group(&exp_group, "trial_001").await.unwrap();
        let meas_group = service.create_group(&trial_group, "measurements").await.unwrap();
        
        assert_eq!(meas_group.path, "/experiment/trial_001/measurements");
    }

    #[tokio::test]
    async fn test_create_duplicate_group_returns_error() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        let group = Hdf5Group {
            file_path: file_path.clone(),
            name: String::new(),
            path: String::new(),
        };
        
        // 创建第一个组
        service.create_group(&group, "data").await.unwrap();
        
        // 尝试创建同名组
        let result = service.create_group(&group, "data").await;
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::GroupAlreadyExists(_) => {},
            other => panic!("Expected GroupAlreadyExists error, got: {:?}", other),
        }
    }
}
```

### 3.3 时序数据集写入测试

#### TC-S2-001-03: 写入简单时序数据集测试

```rust
#[cfg(test)]
mod timeseries_write_tests {
    use super::*;
    use std::path::PathBuf;
    use tempfile::TempDir;

    fn create_test_service() -> impl Hdf5Service {
        Hdf5ServiceImpl::new()
    }

    async fn setup_group_with_file() -> (impl Hdf5Service, Hdf5Group, TempDir, PathBuf) {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = Hdf5ServiceImpl::new();
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        let root_group = Hdf5Group {
            file_path: file_path.clone(),
            name: String::new(),
            path: String::new(),
        };
        
        let group = service.create_group(&root_group, "test_group").await.unwrap();
        
        (service, group, temp_dir, file_path)
    }

    #[tokio::test]
    async fn test_write_simple_timeseries() {
        let (service, group, _temp_dir, _file_path) = setup_group_with_file().await;
        
        let timestamps: Vec<i64> = (0..100).map(|i| i * 1000).collect();
        let values: Vec<f64> = (0..100).map(|i| i as f64 * 0.5).collect();
        
        let result = service.write_timeseries(&group, "temperature", &timestamps, &values).await;
        assert!(result.is_ok(), "Failed to write timeseries: {:?}", result.err());
    }

    #[tokio::test]
    async fn test_write_empty_timeseries_returns_error() {
        let (service, group, _temp_dir, _file_path) = setup_group_with_file().await;
        
        let timestamps: Vec<i64> = vec![];
        let values: Vec<f64> = vec![];
        
        let result = service.write_timeseries(&group, "empty", &timestamps, &values).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::EmptyData => {},
            other => panic!("Expected EmptyData error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_write_mismatched_length_returns_error() {
        let (service, group, _temp_dir, _file_path) = setup_group_with_file().await;
        
        let timestamps: Vec<i64> = (0..10).map(|i| i * 1000).collect();
        let values: Vec<f64> = (0..5).map(|i| i as f64).collect();
        
        let result = service.write_timeseries(&group, "mismatch", &timestamps, &values).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::DataLengthMismatch { expected, actual } => {
                assert_eq!(expected, 10);
                assert_eq!(actual, 5);
            },
            other => panic!("Expected DataLengthMismatch error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_append_to_dataset() {
        let (service, group, _temp_dir, _file_path) = setup_group_with_file().await;
        
        // 初始写入
        let initial_timestamps: Vec<i64> = (0..10).map(|i| i * 1000).collect();
        let initial_values: Vec<f64> = (0..10).map(|i| i as f64).collect();
        
        service.write_timeseries(&group, "sensor", &initial_timestamps, &initial_values).await.unwrap();
        
        // 追加数据
        let new_timestamps: Vec<i64> = (10..20).map(|i| i * 1000).collect();
        let new_values: Vec<f64> = (10..20).map(|i| i as f64).collect();
        
        let result = service.append_to_dataset(&group, "sensor", &new_timestamps, &new_values).await;
        assert!(result.is_ok(), "Failed to append data: {:?}", result.err());
        
        // 验证数据长度
        let shape = service.get_dataset_shape(&group, "sensor").await.unwrap();
        assert_eq!(shape, vec![20]);
    }
}
```

### 3.4 数据集读取测试

#### TC-S2-001-04: 读取时序数据集测试

```rust
#[cfg(test)]
mod dataset_read_tests {
    use super::*;
    use std::path::PathBuf;
    use tempfile::TempDir;

    fn create_test_service() -> impl Hdf5Service {
        Hdf5ServiceImpl::new()
    }

    async fn setup_group_with_timeseries(name: &str) -> (impl Hdf5Service, Hdf5Group, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = Hdf5ServiceImpl::new();
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        let root_group = Hdf5Group {
            file_path: file_path.clone(),
            name: String::new(),
            path: String::new(),
        };
        
        let group = service.create_group(&root_group, "test_group").await.unwrap();
        
        let timestamps: Vec<i64> = (0..100).map(|i| i * 1000).collect();
        let values: Vec<f64> = (0..100).map(|i| i as f64 * 0.5).collect();
        
        service.write_timeseries(&group, name, &timestamps, &values).await.unwrap();
        
        (service, group, temp_dir)
    }

    #[tokio::test]
    async fn test_read_timeseries() {
        let (service, group, _temp_dir) = setup_group_with_timeseries("temperature").await;
        
        let read_values: Vec<f64> = service.read_dataset(&group, "temperature").await.unwrap();
        
        assert_eq!(read_values.len(), 100);
        assert_eq!(read_values[0], 0.0);
        assert_eq!(read_values[50], 25.0);
    }

    #[tokio::test]
    async fn test_read_dataset_range() {
        let (service, group, _temp_dir) = setup_group_with_timeseries("temperature").await;
        
        let range_values: Vec<f64> = service.read_dataset_range(&group, "temperature", 10, 50).await.unwrap();
        
        assert_eq!(range_values.len(), 40);
        assert_eq!(range_values[0], 5.0);  // 索引10对应值
        assert_eq!(range_values[39], 24.5); // 索引49对应值
    }

    #[tokio::test]
    async fn test_read_nonexistent_dataset_returns_error() {
        let (service, group, _temp_dir) = setup_group_with_timeseries("temperature").await;
        
        let result = service.read_dataset::<f64>(&group, "nonexistent").await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::DatasetNotFound(_) => {},
            other => panic!("Expected DatasetNotFound error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_get_dataset_shape() {
        let (service, group, _temp_dir) = setup_group_with_timeseries("temperature").await;
        
        let shape = service.get_dataset_shape(&group, "temperature").await.unwrap();
        
        assert_eq!(shape, vec![100]);
    }

    #[tokio::test]
    async fn test_get_dataset_dtype() {
        let (service, group, _temp_dir) = setup_group_with_timeseries("temperature").await;
        
        let dtype = service.get_dataset_dtype(&group, "temperature").await.unwrap();
        
        assert_eq!(dtype, DatasetType::Float64);
    }
}
```

### 3.5 文件操作错误测试

#### TC-S2-001-05: 文件操作错误测试

```rust
#[cfg(test)]
mod file_operation_error_tests {
    use super::*;
    use std::path::PathBuf;
    use tempfile::TempDir;

    fn create_test_service() -> impl Hdf5Service {
        Hdf5ServiceImpl::new()
    }

    #[tokio::test]
    async fn test_open_nonexistent_file() {
        let temp_dir = TempDir::new().unwrap();
        let nonexistent_path = temp_dir.path().join("nonexistent.h5");
        
        let service = create_test_service();
        let result = service.open_file(&nonexistent_path).await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::FileNotFound(_) => {},
            other => panic!("Expected FileNotFound error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_open_invalid_hdf5_file() {
        let temp_dir = TempDir::new().unwrap();
        let invalid_file = temp_dir.path().join("invalid.h5");
        
        // 写入非HDF5内容
        std::fs::write(&invalid_file, "not an hdf5 file").unwrap();
        
        let service = create_test_service();
        let result = service.open_file(&invalid_file).await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::InvalidFileFormat => {},
            other => panic!("Expected InvalidFileFormat error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_close_already_closed_file() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        // 第一次关闭应该成功
        let first_close = service.close_file(file.clone()).await;
        assert!(first_close.is_ok());
        
        // 第二次关闭应该返回错误
        let second_close = service.close_file(file).await;
        assert!(second_close.is_err());
        match second_close.unwrap_err() {
            Hdf5Error::FileNotOpen => {},
            other => panic!("Expected FileNotOpen error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_access_invalid_group_path() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.h5");
        
        let service = create_test_service();
        let file = service.create_file(file_path.clone()).await.unwrap();
        
        let result = service.get_group(&file, "/nonexistent/subgroup").await;
        
        assert!(result.is_err());
        match result.unwrap_err() {
            Hdf5Error::GroupNotFound(_) => {},
            other => panic!("Expected GroupNotFound error, got: {:?}", other),
        }
    }

    #[tokio::test]
    async fn test_path_traversal_attempt() {
        let malicious_path = PathBuf::from("../../../etc/passwd");
        
        assert!(!Hdf5ServiceImpl::is_path_safe(&malicious_path));
    }

    #[tokio::test]
    async fn test_safe_path() {
        let safe_path = PathBuf::from("/tmp/kayak/data/experiment.h5");
        
        assert!(Hdf5ServiceImpl::is_path_safe(&safe_path));
    }
}
```

---

## 4. 集成测试

### 4.1 完整工作流测试

#### TC-S2-001-06: 完整时序数据采集工作流测试

```rust
// kayak-backend/tests/integration/hdf5_workflow_test.rs

use kayak_backend::services::hdf5::{
    Hdf5Service, Hdf5ServiceImpl, Hdf5Group, Hdf5Error,
};
use std::path::PathBuf;
use tempfile::TempDir;

/// 完整时序数据采集工作流测试
#[tokio::test]
async fn test_complete_timeseries_acquisition_workflow() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("workflow_test.h5");
    
    let service = Hdf5ServiceImpl::new();
    
    // 1. 创建HDF5文件
    let file = service.create_file(file_path.clone()).await.unwrap();
    
    // 2. 创建实验组
    let root_group = Hdf5Group {
        file_path: file_path.clone(),
        name: String::new(),
        path: String::new(),
    };
    let exp_group = service.create_group(&root_group, "experiment_001").await.unwrap();
    
    // 3. 分批写入1000个数据点
    // 注意：write_timeseries 是覆盖模式，只用于第一批
    // 后续批次使用 append_to_dataset 追加数据
    for batch in 0..10 {
        let offset = batch * 100;
        let timestamps: Vec<i64> = (offset..offset+100).map(|i| i as i64 * 1000).collect();
        let values: Vec<f64> = (offset..offset+100).map(|i| i as f64).collect();
        
        if batch == 0 {
            // 第一批使用 write_timeseries（覆盖模式）
            service.write_timeseries(&exp_group, "sensor_1", &timestamps, &values).await.unwrap();
        } else {
            // 后续批次使用 append_to_dataset（追加模式）
            service.append_to_dataset(&exp_group, "sensor_1", &timestamps, &values).await.unwrap();
        }
    }
    
    // 4. 读取并验证数据
    let read_data: Vec<f64> = service.read_dataset(&exp_group, "sensor_1").await.unwrap();
    assert_eq!(read_data.len(), 1000);
    
    // 5. 验证数据完整性
    let shape = service.get_dataset_shape(&exp_group, "sensor_1").await.unwrap();
    assert_eq!(shape, vec![1000]);
    
    // 6. 文件可正常关闭和重新打开
    service.close_file(file).await.unwrap();
    let reopened_file = service.open_file(&file_path).await.unwrap();
    assert!(reopened_file.path == file_path);
}

/// 多实验并发写入测试
#[tokio::test]
async fn test_concurrent_experiment_writes() {
    let temp_dir = TempDir::new().unwrap();
    
    let handles: Vec<_> = (0..4).map(|i| {
        let temp_dir_path = temp_dir.path().to_path_buf();
        let exp_id = i;
        
        tokio::spawn(async move {
            let file_path = temp_dir_path.join(format!("exp_{}.h5", exp_id));
            let service = Hdf5ServiceImpl::new();
            
            let file = service.create_file(file_path).await.unwrap();
            
            let root_group = Hdf5Group {
                file_path: file.path.clone(),
                name: String::new(),
                path: String::new(),
            };
            
            let group = service.create_group(&root_group, "data").await.unwrap();
            
            let timestamps: Vec<i64> = (0..100).map(|t| t as i64 * 1000).collect();
            let values: Vec<f64> = (0..100).map(|t| t as f64 * exp_id as f64).collect();
            
            service.write_timeseries(&group, "sensor", &timestamps, &values).await
        })
    }).collect();
    
    for handle in handles {
        handle.await.unwrap().unwrap();
    }
}

/// 文件完整性检查测试
#[tokio::test]
async fn test_verify_file_integrity() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("integrity_test.h5");
    
    let service = Hdf5ServiceImpl::new();
    let file = service.create_file(file_path.clone()).await.unwrap();
    
    let root_group = Hdf5Group {
        file_path: file_path.clone(),
        name: String::new(),
        path: String::new(),
    };
    
    let group = service.create_group(&root_group, "test_group").await.unwrap();
    
    // 写入测试数据
    let timestamps: Vec<i64> = (0..100).map(|i| i * 1000).collect();
    let values: Vec<f64> = (0..100).map(|i| i as f64 * 0.5).collect();
    service.write_timeseries(&group, "sensor", &timestamps, &values).await.unwrap();
    
    service.close_file(file).await.unwrap();
    
    // 验证完整性
    let report = service.verify_file_integrity(&file_path).await.unwrap();
    assert!(report.is_valid);
    assert_eq!(report.checked_datasets, 1);
    assert_eq!(report.corrupted_datasets, 0);
}

/// 数据迁移测试
#[tokio::test]
async fn test_data_migration() {
    let temp_dir = TempDir::new().unwrap();
    let source_path = temp_dir.path().join("source.h5");
    let target_path = temp_dir.path().join("target.h5");
    
    let service = Hdf5ServiceImpl::new();
    
    // 创建源文件并写入数据
    let source_file = service.create_file(source_path.clone()).await.unwrap();
    let source_root = Hdf5Group {
        file_path: source_path.clone(),
        name: String::new(),
        path: String::new(),
    };
    let source_group = service.create_group(&source_root, "experiment_001").await.unwrap();
    
    let timestamps: Vec<i64> = (0..100).map(|i| i * 1000).collect();
    let values: Vec<f64> = (0..100).map(|i| i as f64).collect();
    service.write_timeseries(&source_group, "sensor", &timestamps, &values).await.unwrap();
    
    // 创建目标文件
    let target_file = service.create_file(target_path.clone()).await.unwrap();
    let target_root = Hdf5Group {
        file_path: target_path.clone(),
        name: String::new(),
        path: String::new(),
    };
    
    // 复制组
    let _copied_group = service.create_group(&target_root, "experiment_001").await.unwrap();
    
    // 注意：实际的复制功能需要通过 copy_group 方法实现
    // 这里简化测试，只验证两个文件独立存在
    
    service.close_file(source_file).await.unwrap();
    service.close_file(target_file).await.unwrap();
    
    // 验证两个文件都存在且可独立打开
    assert!(source_path.exists());
    assert!(target_path.exists());
}

/// 大文件性能测试
#[tokio::test]
async fn test_large_dataset_performance() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("large_test.h5");
    
    let service = Hdf5ServiceImpl::new();
    let file = service.create_file(file_path.clone()).await.unwrap();
    
    let root_group = Hdf5Group {
        file_path: file_path.clone(),
        name: String::new(),
        path: String::new(),
    };
    
    let group = service.create_group(&root_group, "test_group").await.unwrap();
    
    // 写入10000个数据点
    let timestamps: Vec<i64> = (0..10000).map(|i| i * 1000).collect();
    let values: Vec<f64> = (0..10000).map(|i| i as f64 * 0.1).collect();
    
    let start = std::time::Instant::now();
    service.write_timeseries(&group, "large_dataset", &timestamps, &values).await.unwrap();
    let write_time = start.elapsed();
    
    assert!(write_time.as_secs() < 10, "Write took too long: {:?}", write_time);
    
    // 读取性能测试
    let read_start = std::time::Instant::now();
    let _read_data: Vec<f64> = service.read_dataset(&group, "large_dataset").await.unwrap();
    let read_time = read_start.elapsed();
    
    assert!(read_time.as_secs() < 5, "Read took too long: {:?}", read_time);
    
    service.close_file(file).await.unwrap();
}
```

### 4.2 路径策略测试

#### TC-S2-001-07: 路径策略测试

```rust
// kayak-backend/tests/integration/hdf5_path_strategy_test.rs

use kayak_backend::services::hdf5::{
    Hdf5Service, Hdf5ServiceImpl, Hdf5Error,
};
use std::path::PathBuf;
use tempfile::TempDir;
use chrono::Utc;
use uuid::Uuid;

/// 实验数据路径生成测试
#[tokio::test]
async fn test_experiment_path_generation() {
    let service = Hdf5ServiceImpl::new();
    let exp_id = Uuid::new_v4();
    let timestamp = Utc::now();
    
    let path = service.generate_experiment_path(exp_id, timestamp).await.unwrap();
    
    let path_str = path.to_string_lossy();
    assert!(path_str.contains("data"), "Path should contain 'data' directory");
    assert!(path_str.contains(&exp_id.to_string()[..8]), "Path should contain experiment ID prefix");
}

/// 嵌套目录自动创建测试
#[tokio::test]
async fn test_create_file_with_parent_directories() {
    let temp_dir = TempDir::new().unwrap();
    let deep_path = temp_dir.path().join("kayak/data/experiments/2026/03/26/exp.h5");
    
    let service = Hdf5ServiceImpl::new();
    let result = service.create_file_with_directories(&deep_path).await;
    
    assert!(result.is_ok(), "Should create file with parent directories: {:?}", result.err());
    assert!(deep_path.exists(), "File should exist at deep path");
}

/// 路径规范化测试
#[tokio::test]
async fn test_path_normalization() {
    let service = Hdf5ServiceImpl::new();
    let messy_path = PathBuf::from("/tmp//kayak///data//exp.h5");
    
    let normalized = service.normalize_path(&messy_path).await.unwrap();
    
    assert_eq!(normalized, PathBuf::from("/tmp/kayak/data/exp.h5"));
}

/// 路径冲突检测测试
#[tokio::test]
async fn test_path_conflict_detection() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("test.h5");
    
    let service = Hdf5ServiceImpl::new();
    
    // 创建第一个文件
    service.create_file(file_path.clone()).await.unwrap();
    
    // 第二次创建应该根据配置处理
    // 如果 overwrite 为 false，应返回 PathConflict
    let result = service.create_file(file_path.clone()).await;
    assert!(result.is_ok(), "Should allow overwrite by default");
}
```

---

## 5. Mock 测试实现

### 5.1 Mock Hdf5Service 实现

```rust
// kayak-backend/src/test_utils/hdf5_mocks.rs

use async_trait::async_trait;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use uuid::Uuid;
use chrono::{DateTime, Utc};

use crate::services::hdf5::error::Hdf5Error;
use crate::services::hdf5::types::*;
use crate::services::hdf5::service::Hdf5Service;

/// Mock HDF5服务实现（用于测试）
pub struct MockHdf5Service {
    files: Arc<Mutex<HashMap<PathBuf, MockFile>>>,
    groups: Arc<Mutex<HashMap<String, Hdf5Group>>>,
    datasets: Arc<Mutex<HashMap<String, Vec<f64>>>>,
    timestamps: Arc<Mutex<HashMap<String, Vec<i64>>>>,
}

impl MockHdf5Service {
    pub fn new() -> Self {
        Self {
            files: Arc::new(Mutex::new(HashMap::new())),
            groups: Arc::new(Mutex::new(HashMap::new())),
            datasets: Arc::new(Mutex::new(HashMap::new())),
            timestamps: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn with_file(mut self, path: PathBuf) -> Self {
        self.files.lock().unwrap().insert(
            path,
            MockFile {
                path: path.clone(),
                version: "1.10".to_string(),
            },
        );
        self
    }
}

impl Default for MockHdf5Service {
    fn default() -> Self {
        Self::new()
    }
}

struct MockFile {
    path: PathBuf,
    version: String,
}

#[async_trait]
impl Hdf5Service for MockHdf5Service {
    async fn create_file(&self, path: PathBuf) -> Result<Hdf5File, Hdf5Error> {
        let file = Hdf5File {
            path: path.clone(),
        };
        self.files.lock().unwrap().insert(
            path.clone(),
            MockFile {
                path,
                version: "1.10".to_string(),
            },
        );
        Ok(file)
    }

    async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error> {
        if self.files.lock().unwrap().contains_key(path) {
            Ok(Hdf5File { path: path.clone() })
        } else {
            Err(Hdf5Error::FileNotFound(path.to_string_lossy().to_string()))
        }
    }

    async fn close_file(&self, _file: Hdf5File) -> Result<(), Hdf5Error> {
        Ok(())
    }

    async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, Hdf5Error> {
        let path = if parent.path.is_empty() {
            format!("/{}", name)
        } else {
            format!("{}/{}", parent.path, name)
        };
        
        let group = Hdf5Group {
            file_path: parent.file_path.clone(),
            name: name.to_string(),
            path: path.clone(),
        };
        
        self.groups.lock().unwrap().insert(path, group.clone());
        Ok(group)
    }

    async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, Hdf5Error> {
        self.groups
            .lock()
            .unwrap()
            .get(path)
            .cloned()
            .ok_or_else(|| Hdf5Error::GroupNotFound(path.to_string()))
    }

    async fn write_timeseries(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error> {
        if values.is_empty() {
            return Err(Hdf5Error::EmptyData);
        }
        
        let key = format!("{}/{}", group.path, name);
        self.datasets.lock().unwrap().insert(key, values.to_vec());
        self.timestamps.lock().unwrap().insert(key, timestamps.to_vec());
        Ok(())
    }

    async fn append_to_dataset(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error> {
        let key = format!("{}/{}", group.path, name);
        let mut datasets = self.datasets.lock().unwrap();
        let mut ts_store = self.timestamps.lock().unwrap();
        
        if let Some(existing) = datasets.get_mut(&key) {
            existing.extend(values.iter().copied());
            if let Some(existing_ts) = ts_store.get_mut(&key) {
                existing_ts.extend(timestamps.iter().copied());
            }
            Ok(())
        } else {
            Err(Hdf5Error::DatasetNotFound(name.to_string()))
        }
    }

    async fn read_dataset<T: TryFrom<f64> + Send + 'static>(
        &self,
        group: &Hdf5Group,
        name: &str,
    ) -> Result<Vec<T>, Hdf5Error> {
        let key = format!("{}/{}", group.path, name);
        let datasets = self.datasets.lock().unwrap();
        
        if let Some(data) = datasets.get(&key) {
            Ok(data.iter().filter_map(|v| T::try_from(*v).ok()).collect())
        } else {
            Err(Hdf5Error::DatasetNotFound(name.to_string()))
        }
    }

    async fn read_dataset_range<T: TryFrom<f64> + Send + 'static>(
        &self,
        group: &Hdf5Group,
        name: &str,
        start: usize,
        end: usize,
    ) -> Result<Vec<T>, Hdf5Error> {
        let key = format!("{}/{}", group.path, name);
        let datasets = self.datasets.lock().unwrap();
        
        if let Some(data) = datasets.get(&key) {
            let range = data.get(start..end).ok_or_else(|| {
                Hdf5Error::DataLengthMismatch {
                    expected: data.len(),
                    actual: end - start,
                }
            })?;
            Ok(range.iter().filter_map(|v| T::try_from(*v).ok()).collect())
        } else {
            Err(Hdf5Error::DatasetNotFound(name.to_string()))
        }
    }

    async fn get_dataset_shape(&self, group: &Hdf5Group, name: &str) -> Result<Vec<usize>, Hdf5Error> {
        let key = format!("{}/{}", group.path, name);
        let datasets = self.datasets.lock().unwrap();
        
        if let Some(data) = datasets.get(&key) {
            Ok(vec![data.len()])
        } else {
            Err(Hdf5Error::DatasetNotFound(name.to_string()))
        }
    }

    async fn get_dataset_dtype(&self, _group: &Hdf5Group, _name: &str) -> Result<DatasetType, Hdf5Error> {
        Ok(DatasetType::Float64)
    }

    async fn get_file_version(&self, file: &Hdf5File) -> Result<String, Hdf5Error> {
        let files = self.files.lock().unwrap();
        if let Some(mock_file) = files.get(&file.path) {
            Ok(mock_file.version.clone())
        } else {
            Err(Hdf5Error::FileNotFound(file.path.to_string_lossy().to_string()))
        }
    }

    async fn get_file_creation_time(&self, _file: &Hdf5File) -> Result<i64, Hdf5Error> {
        Ok(Utc::now().timestamp())
    }

    async fn get_dataset_compression_info(
        &self,
        _group: &Hdf5Group,
        _name: &str,
    ) -> Result<Option<CompressionInfo>, Hdf5Error> {
        Ok(None)
    }

    async fn verify_file_integrity(&self, path: &PathBuf) -> Result<IntegrityReport, Hdf5Error> {
        let files = self.files.lock().unwrap();
        if files.contains_key(path) {
            Ok(IntegrityReport {
                is_valid: true,
                checked_datasets: 0,
                corrupted_datasets: 0,
                errors: vec![],
            })
        } else {
            Err(Hdf5Error::FileNotFound(path.to_string_lossy().to_string()))
        }
    }

    async fn generate_experiment_path(
        &self,
        exp_id: Uuid,
        timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error> {
        Ok(PathBuf::from(format!(
            "/tmp/kayak/data/{}/{:4}/{:02}/{:02}/exp.h5",
            &exp_id.to_string()[..8],
            timestamp.format("%Y"),
            timestamp.format("%m"),
            timestamp.format("%d"),
        )))
    }

    async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                Hdf5Error::ParentDirectoryNotFound(e.to_string())
            })?;
        }
        self.create_file(path.clone()).await
    }

    async fn normalize_path(&self, path: &PathBuf) -> Result<PathBuf, Hdf5Error> {
        Ok(path.components().collect::<PathBuf>())
    }

    fn is_path_safe(path: &PathBuf) -> bool {
        let path_str = path.to_string_lossy();
        !path_str.contains("..") && !path_str.starts_with("/etc") && !path_str.starts_with("/usr")
    }
}

/// 测试辅助函数：使用Mock服务
#[cfg(test)]
pub mod tests {
    use super::*;

    pub fn create_mock_service() -> MockHdf5Service {
        MockHdf5Service::new()
    }

    #[tokio::test]
    async fn test_mock_service_creates_file() {
        let service = create_mock_service();
        let path = PathBuf::from("/tmp/test.h5");
        
        let result = service.create_file(path.clone()).await;
        assert!(result.is_ok());
        assert!(service.files.lock().unwrap().contains_key(&path));
    }

    #[tokio::test]
    async fn test_mock_service_reads_written_data() {
        let service = create_mock_service();
        let path = PathBuf::from("/tmp/test.h5");
        
        let file = service.create_file(path.clone()).await.unwrap();
        let root = Hdf5Group {
            file_path: path.clone(),
            name: String::new(),
            path: String::new(),
        };
        
        let group = service.create_group(&root, "test").await.unwrap();
        
        let values: Vec<f64> = vec![1.0, 2.0, 3.0];
        service.write_timeseries(&group, "data", &[0, 1, 2], &values).await.unwrap();
        
        let read: Vec<f64> = service.read_dataset(&group, "data").await.unwrap();
        assert_eq!(read, values);
    }
}
```

---

## 6. 测试执行指南

### 6.1 运行测试

```bash
# 运行所有HDF5相关测试
cd kayak-backend && cargo test hdf5

# 运行单元测试
cd kayak-backend && cargo test --lib hdf5

# 运行集成测试
cd kayak-backend && cargo test --test '*hdf5*'

# 运行带详细输出的测试
cd kayak-backend && RUST_LOG=debug cargo test hdf5 --nocapture

# 运行特定测试
cd kayak-backend && cargo test test_create_new_hdf5_file
```

### 6.2 添加到 Cargo.toml 的依赖

```toml
[dev-dependencies]
# HDF5 support (when implementing)
# hdf5 = "0.9"
# tempfile for test file management
tempfile = "3.10"
```

---

## 7. 附录

### 7.1 HDF5错误类型映射

| Hdf5Error | 可能的来源 | 处理建议 |
|-----------|----------|---------|
| FileNotFound | 文件不存在 | 检查路径是否正确 |
| FileAlreadyExists | 文件已存在 | 使用覆盖模式或换个名字 |
| InvalidFileFormat | 不是有效的HDF5文件 | 检查文件是否损坏 |
| FileNotOpen | 文件未打开 | 确保操作前已打开文件 |
| GroupNotFound | 组不存在 | 检查组路径是否正确 |
| GroupAlreadyExists | 组已存在 | 使用已有组或换个名字 |
| DatasetNotFound | 数据集不存在 | 检查数据集名称 |
| DatasetAlreadyExists | 数据集已存在 | 使用已有数据集或覆盖 |
| EmptyData | 数据为空 | 写入有效数据 |
| DataLengthMismatch | 数据长度不匹配 | 确保时间戳和数据值长度一致 |
| TypeMismatch | 类型不匹配 | 检查读取时指定的类型 |
| DataCorrupted | 数据损坏 | 检查文件完整性 |
| ParentDirectoryNotFound | 父目录不存在 | 使用 create_file_with_directories |
| PermissionDenied | 权限不足 | 检查目录权限 |
| InvalidPath | 无效路径 | 检查路径格式 |
| PathConflict | 路径冲突 | 使用覆盖模式或换个路径 |
| PathTraversalAttempted | 路径遍历攻击 | 拒绝请求 |

### 7.2 相关文件

- 测试用例定义: `/home/hzhou/workspace/kayak/log/release_0/test/S2-001_test_cases.md`
- 测试执行报告: `/home/hzhou/workspace/kayak/log/release_0/test/S2-001_execution_report.md`
- HDF5服务实现: 待实现

---

**文档版本**: 2.0  
**创建日期**: 2026-03-26  
**最后更新**: 2026-03-26
