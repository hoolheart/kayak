//! 工作台服务实现

use async_trait::async_trait;
use std::sync::Arc;
use uuid::Uuid;
use crate::models::entities::workbench::Workbench;
use crate::db::repository::workbench_repo::WorkbenchRepository;
use super::{WorkbenchError, WorkbenchDto, PagedWorkbenchDto, CreateWorkbenchEntity, UpdateWorkbenchEntity};

/// 工作台服务 trait
#[async_trait]
pub trait WorkbenchService: Send + Sync {
    async fn create_workbench(&self, owner_id: Uuid, req: CreateWorkbenchEntity) -> Result<WorkbenchDto, WorkbenchError>;
    async fn get_workbench(&self, user_id: Uuid, workbench_id: Uuid) -> Result<WorkbenchDto, WorkbenchError>;
    async fn list_workbenches(&self, user_id: Uuid, page: i64, size: i64) -> Result<PagedWorkbenchDto, WorkbenchError>;
    async fn update_workbench(&self, user_id: Uuid, workbench_id: Uuid, req: UpdateWorkbenchEntity) -> Result<WorkbenchDto, WorkbenchError>;
    async fn delete_workbench(&self, user_id: Uuid, workbench_id: Uuid) -> Result<(), WorkbenchError>;
}

/// 工作台服务实现
pub struct WorkbenchServiceImpl<R: WorkbenchRepository> {
    workbench_repo: Arc<R>,
}

impl<R: WorkbenchRepository> WorkbenchServiceImpl<R> {
    pub fn new(workbench_repo: Arc<R>) -> Self {
        Self { workbench_repo }
    }

    /// 验证用户是否拥有工作台
    async fn validate_ownership(&self, user_id: Uuid, workbench_id: Uuid) -> Result<(), WorkbenchError> {
        let workbench = self.workbench_repo.find_by_id(workbench_id).await
            .map_err(|e| WorkbenchError::Internal(e.to_string()))?;
        
        match workbench {
            Some(wb) if wb.owner_id == user_id => Ok(()),
            Some(_) => Err(WorkbenchError::AccessDenied),
            None => Err(WorkbenchError::NotFound),
        }
    }
}

#[async_trait]
impl<R: WorkbenchRepository> WorkbenchService for WorkbenchServiceImpl<R> {
    async fn create_workbench(&self, owner_id: Uuid, req: CreateWorkbenchEntity) -> Result<WorkbenchDto, WorkbenchError> {
        // Validation
        if req.name.is_empty() {
            return Err(WorkbenchError::ValidationError("Name is required".to_string()));
        }
        if req.name.len() > 255 {
            return Err(WorkbenchError::ValidationError("Name must be 1-255 characters".to_string()));
        }
        if let Some(ref desc) = req.description {
            if desc.len() > 1000 {
                return Err(WorkbenchError::ValidationError("Description must be at most 1000 characters".to_string()));
            }
        }

        let workbench = Workbench::new(
            req.name,
            req.description,
            req.owner_type,
            owner_id,
        );

        self.workbench_repo.create(&workbench).await
            .map_err(|e| WorkbenchError::Internal(e.to_string()))?;

        Ok(workbench.into())
    }

    async fn get_workbench(&self, user_id: Uuid, workbench_id: Uuid) -> Result<WorkbenchDto, WorkbenchError> {
        // Verify ownership first
        self.validate_ownership(user_id, workbench_id).await?;

        let workbench = self.workbench_repo.find_by_id(workbench_id).await
            .map_err(|e| WorkbenchError::Internal(e.to_string()))?;
        
        match workbench {
            Some(wb) => Ok(wb.into()),
            None => Err(WorkbenchError::NotFound),
        }
    }

    async fn list_workbenches(&self, user_id: Uuid, page: i64, size: i64) -> Result<PagedWorkbenchDto, WorkbenchError> {
        // Validate pagination
        if page < 1 {
            return Err(WorkbenchError::ValidationError("page must be >= 1".to_string()));
        }
        if size < 1 || size > 1000 {
            return Err(WorkbenchError::ValidationError("size must be 1-1000".to_string()));
        }

        let (workbenches, total) = self.workbench_repo.list_by_owner(user_id, page, size).await
            .map_err(|e| WorkbenchError::Internal(e.to_string()))?;

        let total_pages = (total as f64 / size as f64).ceil() as i64;

        Ok(PagedWorkbenchDto {
            items: workbenches.into_iter().map(|w| w.into()).collect(),
            page,
            size,
            total,
            total_pages,
        })
    }

    async fn update_workbench(&self, user_id: Uuid, workbench_id: Uuid, req: UpdateWorkbenchEntity) -> Result<WorkbenchDto, WorkbenchError> {
        // Verify ownership first
        self.validate_ownership(user_id, workbench_id).await?;

        // Validation
        if let Some(ref name) = req.name {
            if name.is_empty() {
                return Err(WorkbenchError::ValidationError("Name cannot be empty".to_string()));
            }
            if name.len() > 255 {
                return Err(WorkbenchError::ValidationError("Name must be 1-255 characters".to_string()));
            }
        }
        if let Some(ref desc) = req.description {
            if desc.len() > 1000 {
                return Err(WorkbenchError::ValidationError("Description must be at most 1000 characters".to_string()));
            }
        }

        let workbench = self.workbench_repo.update(workbench_id, req.name, req.description, req.status).await
            .map_err(|e| WorkbenchError::Internal(e.to_string()))?;

        Ok(workbench.into())
    }

    async fn delete_workbench(&self, user_id: Uuid, workbench_id: Uuid) -> Result<(), WorkbenchError> {
        // Verify ownership first
        self.validate_ownership(user_id, workbench_id).await?;

        self.workbench_repo.delete(workbench_id).await
            .map_err(|e| WorkbenchError::Internal(e.to_string()))?;

        Ok(())
    }
}