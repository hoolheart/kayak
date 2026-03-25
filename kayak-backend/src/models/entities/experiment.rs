//! 试验实体模型
//!
//! 定义试验数据结构和相关枚举

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 试验状态枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum ExperimentStatus {
    /// 初始状态，试验未开始
    Idle,
    /// 试验正在运行
    Running,
    /// 试验暂停
    Paused,
    /// 试验正常结束
    Completed,
    /// 试验被中止
    Aborted,
}

impl Default for ExperimentStatus {
    fn default() -> Self {
        ExperimentStatus::Idle
    }
}

/// 试验实体
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Experiment {
    /// 试验ID (UUID)
    pub id: Uuid,
    /// 创建用户ID
    pub user_id: Uuid,
    /// 关联方法ID (可选)
    pub method_id: Option<Uuid>,
    /// 试验名称
    pub name: String,
    /// 试验描述
    pub description: Option<String>,
    /// 试验状态
    pub status: ExperimentStatus,
    /// 开始时间
    pub started_at: Option<DateTime<Utc>>,
    /// 结束时间
    pub ended_at: Option<DateTime<Utc>>,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl Experiment {
    /// 创建新试验
    pub fn new(user_id: Uuid, name: String) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            user_id,
            method_id: None,
            name,
            description: None,
            status: ExperimentStatus::Idle,
            started_at: None,
            ended_at: None,
            created_at: now,
            updated_at: now,
        }
    }

    /// 检查状态转换是否有效
    pub fn can_transition_to(&self, new_status: ExperimentStatus) -> bool {
        match (self.status, new_status) {
            // Idle 可以转到 Running
            (ExperimentStatus::Idle, ExperimentStatus::Running) => true,
            // Running 可以转到 Paused, Completed, Aborted
            (ExperimentStatus::Running, ExperimentStatus::Paused) => true,
            (ExperimentStatus::Running, ExperimentStatus::Completed) => true,
            (ExperimentStatus::Running, ExperimentStatus::Aborted) => true,
            // Paused 可以转到 Running, Aborted
            (ExperimentStatus::Paused, ExperimentStatus::Running) => true,
            (ExperimentStatus::Paused, ExperimentStatus::Aborted) => true,
            // 终态不能转换
            (ExperimentStatus::Completed, _) => false,
            (ExperimentStatus::Aborted, _) => false,
            // 其他情况无效
            _ => false,
        }
    }
}

/// 创建试验请求
#[derive(Debug, Deserialize)]
pub struct CreateExperimentRequest {
    pub user_id: Uuid,
    pub method_id: Option<Uuid>,
    pub name: String,
    pub description: Option<String>,
}

/// 更新试验请求
#[derive(Debug, Deserialize)]
pub struct UpdateExperimentRequest {
    pub name: Option<String>,
    pub description: Option<String>,
}

/// 更新试验状态请求
#[derive(Debug, Deserialize)]
pub struct UpdateStatusRequest {
    pub status: ExperimentStatus,
}

/// 试验响应
#[derive(Debug, Serialize)]
pub struct ExperimentResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub method_id: Option<Uuid>,
    pub name: String,
    pub description: Option<String>,
    pub status: ExperimentStatus,
    pub started_at: Option<DateTime<Utc>>,
    pub ended_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<Experiment> for ExperimentResponse {
    fn from(e: Experiment) -> Self {
        Self {
            id: e.id,
            user_id: e.user_id,
            method_id: e.method_id,
            name: e.name,
            description: e.description,
            status: e.status,
            started_at: e.started_at,
            ended_at: e.ended_at,
            created_at: e.created_at,
            updated_at: e.updated_at,
        }
    }
}

/// 列出试验请求
#[derive(Debug, Deserialize, Default)]
pub struct ListExperimentsRequest {
    pub user_id: Option<Uuid>,
    pub status: Option<ExperimentStatus>,
    pub method_id: Option<Uuid>,
    pub started_after: Option<DateTime<Utc>>,
    pub started_before: Option<DateTime<Utc>>,
    pub page: Option<u32>,
    pub size: Option<u32>,
}

/// 分页响应
#[derive(Debug, Serialize)]
pub struct PagedResponse<T> {
    pub items: Vec<T>,
    pub page: u32,
    pub size: u32,
    pub total: u64,
    pub has_next: bool,
    pub has_prev: bool,
}
