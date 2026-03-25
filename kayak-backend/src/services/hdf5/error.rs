//! HDF5服务错误类型

use thiserror::Error;

/// HDF5服务错误类型
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

/// From hdf5::Error to Hdf5Error conversion
impl From<hdf5::Error> for Hdf5Error {
    fn from(_err: hdf5::Error) -> Self {
        Hdf5Error::DataCorrupted
    }
}
