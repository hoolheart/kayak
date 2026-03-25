//! HDF5服务模块
//! 
//! 提供HDF5文件创建、组管理、数据集读写等功能

pub mod error;
pub mod path;
pub mod service;
pub mod types;

pub use error::Hdf5Error;
pub use path::{PathStrategy, PathStrategyConfig};
pub use service::{Hdf5Service, Hdf5ServiceImpl};
pub use types::{
    CompressionInfo,
    CompressionType,
    DatasetType,
    Hdf5Dataset,
    Hdf5File,
    Hdf5Group,
    IntegrityReport,
};