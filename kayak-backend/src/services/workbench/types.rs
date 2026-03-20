//! 工作台服务类型定义

use crate::models::entities::workbench::{OwnerType, Workbench, WorkbenchStatus};
use uuid::Uuid;

/// 创建工作台实体
pub struct CreateWorkbenchEntity {
    pub name: String,
    pub description: Option<String>,
    pub owner_type: OwnerType,
    pub owner_id: Uuid,
}

/// 更新工作台实体
pub struct UpdateWorkbenchEntity {
    pub name: Option<String>,
    pub description: Option<String>,
    pub status: Option<WorkbenchStatus>,
}

/// 工作台DTO (用于API响应)
#[derive(Debug, Clone, serde::Serialize)]
pub struct WorkbenchDto {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub owner_type: OwnerType,
    pub owner_id: Uuid,
    pub status: WorkbenchStatus,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

impl From<Workbench> for WorkbenchDto {
    fn from(wb: Workbench) -> Self {
        Self {
            id: wb.id,
            name: wb.name,
            description: wb.description,
            owner_type: wb.owner_type,
            owner_id: wb.owner_id,
            status: wb.status,
            created_at: wb.created_at,
            updated_at: wb.updated_at,
        }
    }
}

/// 分页工作台DTO
#[derive(Debug, Clone, serde::Serialize)]
pub struct PagedWorkbenchDto {
    pub items: Vec<WorkbenchDto>,
    pub page: i64,
    pub size: i64,
    pub total: i64,
    pub total_pages: i64,
}

/// 列表查询参数
#[derive(Debug, Clone, serde::Deserialize)]
pub struct ListWorkbenchesQuery {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_size")]
    pub size: i64,
}

fn default_page() -> i64 {
    1
}
fn default_size() -> i64 {
    20
}
