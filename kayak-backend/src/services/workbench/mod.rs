//! 工作台服务模块

mod service;
mod error;
mod types;

pub use error::WorkbenchError;
pub use types::{WorkbenchDto, PagedWorkbenchDto, CreateWorkbenchEntity, UpdateWorkbenchEntity, ListWorkbenchesQuery};
pub use service::{WorkbenchService, WorkbenchServiceImpl};

/// Re-export for convenience
pub use crate::db::repository::workbench_repo::{WorkbenchRepository, SqlxWorkbenchRepository};