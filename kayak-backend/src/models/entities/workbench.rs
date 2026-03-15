//! 工作台实体模型
//!
//! 定义工作台表的数据结构和相关枚举

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 所有者类型枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(rename = "TEXT")]
#[sqlx(rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum OwnerType {
    /// 个人用户
    User,
    /// 团队
    Team,
}

/// 工作台状态枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(rename = "TEXT")]
#[sqlx(rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum WorkbenchStatus {
    /// 正常
    Active,
    /// 已归档
    Archived,
    /// 已删除
    Deleted,
}

impl Default for WorkbenchStatus {
    fn default() -> Self {
        WorkbenchStatus::Active
    }
}

/// 工作台实体
#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct Workbench {
    /// 工作台ID (UUID)
    pub id: Uuid,
    /// 工作台名称
    pub name: String,
    /// 描述
    pub description: Option<String>,
    /// 所有者类型
    pub owner_type: OwnerType,
    /// 所有者ID (用户ID或团队ID)
    pub owner_id: Uuid,
    /// 状态
    pub status: WorkbenchStatus,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl Workbench {
    /// 创建新工作台
    pub fn new(
        name: String,
        description: Option<String>,
        owner_type: OwnerType,
        owner_id: Uuid,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            name,
            description,
            owner_type,
            owner_id,
            status: WorkbenchStatus::Active,
            created_at: now,
            updated_at: now,
        }
    }
}

/// 创建工作台请求DTO
#[derive(Debug, Deserialize)]
pub struct CreateWorkbenchRequest {
    pub name: String,
    pub description: Option<String>,
    pub owner_type: OwnerType,
    pub owner_id: Uuid,
}

/// 更新工作台请求DTO
#[derive(Debug, Deserialize, Default)]
pub struct UpdateWorkbenchRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub status: Option<WorkbenchStatus>,
}

/// 工作台响应DTO
#[derive(Debug, Serialize)]
pub struct WorkbenchResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub owner_type: OwnerType,
    pub owner_id: Uuid,
    pub status: WorkbenchStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<Workbench> for WorkbenchResponse {
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
