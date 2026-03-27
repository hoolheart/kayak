//! HDF5 service implementation for hdf5 0.8
//!
//! Simplified implementation with core functionality:
//! - File creation and opening
//! - Group creation and retrieval
//! - Dataset creation and reading (f64 values)
//! - Get dataset shape

use async_trait::async_trait;
use std::path::PathBuf;
use std::sync::RwLock;
use std::collections::HashMap;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use ndarray::Array;

use super::error::Hdf5Error;
use super::types::*;
use super::path::PathStrategy;

/// HDF5 service interface
#[async_trait]
pub trait Hdf5Service: Send + Sync {
    /// Create HDF5 file (overwrite mode)
    async fn create_file(&self, path: PathBuf) -> Result<Hdf5File, Hdf5Error>;

    /// Open existing HDF5 file
    async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error>;

    /// Close HDF5 file
    async fn close_file(&self, file: Hdf5File) -> Result<(), Hdf5Error>;

    /// Create subgroup
    async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, Hdf5Error>;

    /// Get group by path
    async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, Hdf5Error>;

    /// Write timeseries dataset (timestamps + values)
    async fn write_timeseries(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error>;

    /// Read dataset (returns f64 values)
    async fn read_dataset(&self, group: &Hdf5Group, name: &str) -> Result<Vec<f64>, Hdf5Error>;

    /// Get dataset shape
    async fn get_dataset_shape(&self, group: &Hdf5Group, name: &str) -> Result<Vec<usize>, Hdf5Error>;

    /// Generate experiment data path
    async fn generate_experiment_path(
        &self,
        exp_id: Uuid,
        timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error>;

    /// Create file with auto-create parent directories
    async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error>;

    /// Check if path is safe (no path traversal)
    fn is_path_safe(&self, path: &PathBuf) -> bool;
}

/// HDF5 service implementation
pub struct Hdf5ServiceImpl {
    path_strategy: PathStrategy,
    file_handles: RwLock<HashMap<PathBuf, hdf5::File>>,
}

impl Hdf5ServiceImpl {
    /// Create new service instance
    pub fn new() -> Self {
        Self {
            path_strategy: PathStrategy::default(),
            file_handles: RwLock::new(HashMap::new()),
        }
    }

    /// Validate path safety
    fn validate_path(&self, path: &PathBuf) -> Result<(), Hdf5Error> {
        if !self.is_path_safe(path) {
            return Err(Hdf5Error::PathTraversalAttempted);
        }
        let path_str = path.to_string_lossy();
        if path_str.is_empty() {
            return Err(Hdf5Error::InvalidPath("Empty path".to_string()));
        }
        Ok(())
    }

    /// Validate timeseries data length consistency
    fn validate_timeseries_data(&self, timestamps: &[i64], values: &[f64]) -> Result<(), Hdf5Error> {
        if timestamps.is_empty() || values.is_empty() {
            return Err(Hdf5Error::EmptyData);
        }
        if timestamps.len() != values.len() {
            return Err(Hdf5Error::DataLengthMismatch {
                expected: timestamps.len(),
                actual: values.len(),
            });
        }
        Ok(())
    }
}

impl Default for Hdf5ServiceImpl {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Hdf5Service for Hdf5ServiceImpl {
    async fn create_file(&self, path: PathBuf) -> Result<Hdf5File, Hdf5Error> {
        let path_clone = path.clone();
        self.validate_path(&path_clone)?;

        if let Some(parent) = path_clone.parent() {
            if !parent.exists() {
                return Err(Hdf5Error::ParentDirectoryNotFound(
                    parent.to_string_lossy().to_string()
                ));
            }
        }

        let file = hdf5::File::create(&path_clone)
            .map_err(|_| Hdf5Error::InvalidFileFormat)?;

        self.file_handles.write()
            .map_err(|_| Hdf5Error::FileNotOpen)?
            .insert(path_clone.clone(), file);

        Ok(Hdf5File { path: path_clone })
    }

    async fn open_file(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error> {
        let path_clone = path.clone();
        self.validate_path(&path_clone)?;

        if !path_clone.exists() {
            return Err(Hdf5Error::FileNotFound(path_clone.to_string_lossy().to_string()));
        }

        let file = hdf5::File::open(&path_clone)
            .map_err(|_| Hdf5Error::InvalidFileFormat)?;

        self.file_handles.write()
            .map_err(|_| Hdf5Error::FileNotOpen)?
            .insert(path_clone.clone(), file);

        Ok(Hdf5File { path: path_clone })
    }

    async fn close_file(&self, file: Hdf5File) -> Result<(), Hdf5Error> {
        self.file_handles.write()
            .map_err(|_| Hdf5Error::FileNotOpen)?
            .remove(&file.path);
        Ok(())
    }

    async fn create_group(&self, parent: &Hdf5Group, name: &str) -> Result<Hdf5Group, Hdf5Error> {
        let file_path = parent.file_path.clone();
        let parent_path = &parent.path;
        let group_name = name.to_string();

        let file = hdf5::File::open(&file_path)
            .map_err(|_| Hdf5Error::FileNotOpen)?;

        let parent_path_str = if parent_path.is_empty() || parent_path == "/" {
            "/".to_string()
        } else {
            parent_path.clone()
        };

        let group = file.group(&parent_path_str)
            .map_err(|_| Hdf5Error::GroupNotFound(parent_path_str.clone()))?;

        let _new_group = group.create_group(&group_name)
            .map_err(|_| Hdf5Error::GroupAlreadyExists(format!("{}/{}", parent_path_str, group_name)))?;

        let full_path = if parent_path_str == "/" {
            format!("/{}", group_name)
        } else {
            format!("{}/{}", parent_path_str, group_name)
        };

        Ok(Hdf5Group {
            file_path,
            name: group_name,
            path: full_path,
        })
    }

    async fn get_group(&self, file: &Hdf5File, path: &str) -> Result<Hdf5Group, Hdf5Error> {
        let file_path = file.path.clone();
        let group_path = path.to_string();

        let hdf5_file = hdf5::File::open(&file_path)
            .map_err(|_| Hdf5Error::FileNotOpen)?;

        let _group = hdf5_file.group(&group_path)
            .map_err(|_| Hdf5Error::GroupNotFound(group_path.clone()))?;

        let name = group_path.split('/')
            .filter(|s| !s.is_empty())
            .last()
            .unwrap_or("")
            .to_string();

        Ok(Hdf5Group {
            file_path,
            name,
            path: group_path,
        })
    }

    async fn write_timeseries(
        &self,
        group: &Hdf5Group,
        name: &str,
        timestamps: &[i64],
        values: &[f64],
    ) -> Result<(), Hdf5Error> {
        self.validate_timeseries_data(timestamps, values)?;

        let file = hdf5::File::open(&group.file_path)
            .map_err(|_| Hdf5Error::FileNotOpen)?;

        let hdf5_group = file.group(&group.path)
            .map_err(|_| Hdf5Error::GroupNotFound(group.path.clone()))?;

        let n = timestamps.len();

        // Delete existing datasets if they exist
        if hdf5_group.link_exists(name) {
            hdf5_group.unlink(name).map_err(|_| Hdf5Error::DataCorrupted)?;
        }
        if hdf5_group.link_exists("timestamps") {
            hdf5_group.unlink("timestamps").map_err(|_| Hdf5Error::DataCorrupted)?;
        }

        // Create and write values dataset
        let values_dataset = hdf5_group
            .new_dataset::<f64>()
            .shape([n])
            .create(name)
            .map_err(|_| Hdf5Error::DatasetAlreadyExists(name.to_string()))?;

        values_dataset.write_raw(values)
            .map_err(|_| Hdf5Error::DataCorrupted)?;

        // Create and write timestamps dataset
        let ts_dataset = hdf5_group
            .new_dataset::<i64>()
            .shape([n])
            .create("timestamps")
            .map_err(|_| Hdf5Error::DatasetAlreadyExists("timestamps".to_string()))?;

        ts_dataset.write_raw(timestamps)
            .map_err(|_| Hdf5Error::DataCorrupted)?;

        Ok(())
    }

    async fn read_dataset(&self, group: &Hdf5Group, name: &str) -> Result<Vec<f64>, Hdf5Error> {
        let file = hdf5::File::open(&group.file_path)
            .map_err(|_| Hdf5Error::FileNotOpen)?;

        let hdf5_group = file.group(&group.path)
            .map_err(|_| Hdf5Error::GroupNotFound(group.path.clone()))?;

        let dataset = hdf5_group.dataset(name)
            .map_err(|_| Hdf5Error::DatasetNotFound(name.to_string()))?;

        let data: Array<f64, ndarray::Dim<[usize; 1]>> = dataset.read()
            .map_err(|_| Hdf5Error::DataCorrupted)?;

        Ok(data.into_raw_vec())
    }

    async fn get_dataset_shape(&self, group: &Hdf5Group, name: &str) -> Result<Vec<usize>, Hdf5Error> {
        let file = hdf5::File::open(&group.file_path)
            .map_err(|_| Hdf5Error::FileNotOpen)?;

        let hdf5_group = file.group(&group.path)
            .map_err(|_| Hdf5Error::GroupNotFound(group.path.clone()))?;

        let dataset = hdf5_group.dataset(name)
            .map_err(|_| Hdf5Error::DatasetNotFound(name.to_string()))?;

        Ok(dataset.shape())
    }

    async fn generate_experiment_path(
        &self,
        exp_id: Uuid,
        timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error> {
        self.path_strategy.generate_path(exp_id, timestamp)
    }

    async fn create_file_with_directories(&self, path: &PathBuf) -> Result<Hdf5File, Hdf5Error> {
        let path_clone = path.clone();

        if let Some(parent) = path_clone.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| {
                    if e.kind() == std::io::ErrorKind::PermissionDenied {
                        Hdf5Error::PermissionDenied(parent.to_string_lossy().to_string())
                    } else {
                        Hdf5Error::ParentDirectoryNotFound(parent.to_string_lossy().to_string())
                    }
                })?;
        }

        self.create_file(path_clone).await
    }

    fn is_path_safe(&self, path: &PathBuf) -> bool {
        let path_str = path.to_string_lossy();
        if path_str.contains("..") {
            return false;
        }
        if path_str.starts_with("/etc") || path_str.starts_with("/usr") {
            return false;
        }
        true
    }
}
