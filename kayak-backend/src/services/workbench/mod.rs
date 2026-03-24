//! 工作台服务模块

mod error;
mod service;
mod types;

pub use error::WorkbenchError;
pub use service::{WorkbenchService, WorkbenchServiceImpl};
pub use types::{
    CreateWorkbenchEntity, ListWorkbenchesQuery, PagedWorkbenchDto, UpdateWorkbenchEntity,
    WorkbenchDto,
};

/// Re-export for convenience
pub use crate::db::repository::workbench_repo::{SqlxWorkbenchRepository, WorkbenchRepository};
