//! HDF5服务数据类型

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// HDF5文件句柄
#[derive(Debug, Clone)]
pub struct Hdf5File {
    /// 文件路径
    pub path: PathBuf,
}

/// HDF5组句柄
#[derive(Debug, Clone)]
pub struct Hdf5Group {
    /// 所属文件路径
    pub file_path: PathBuf,
    /// 组名称
    pub name: String,
    /// 完整路径，如 "/experiment/trial_001"
    pub path: String,
}

/// HDF5数据集
#[derive(Debug, Clone)]
pub struct Hdf5Dataset {
    /// 所属组路径
    pub group_path: String,
    /// 数据集名称
    pub name: String,
    /// 数据形状
    pub shape: Vec<usize>,
    /// 数据类型
    pub dtype: DatasetType,
}

/// 数据集类型枚举
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
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
    /// 压缩算法类型
    pub algorithm: CompressionType,
    /// 压缩级别（可选）
    pub level: Option<u32>,
}

/// 压缩类型枚举
#[derive(Debug, Clone, PartialEq)]
pub enum CompressionType {
    None,
    Gzip,
    Szip,
}

/// 文件完整性报告
#[derive(Debug)]
pub struct IntegrityReport {
    /// 文件是否有效
    pub is_valid: bool,
    /// 已检查的数据集数量
    pub checked_datasets: usize,
    /// 损坏的数据集数量
    pub corrupted_datasets: usize,
    /// 错误列表
    pub errors: Vec<String>,
}
