//! 数据文件实体模型
//!
//! 定义数据文件元信息表的数据结构和相关枚举

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 数据来源类型枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(rename = "TEXT")]
#[sqlx(rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum SourceType {
    /// 试验生成
    Experiment,
    /// 分析生成
    Analysis,
    /// 外部导入
    Import,
}

/// 数据文件状态枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(rename = "TEXT")]
#[sqlx(rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DataFileStatus {
    /// 正常
    Active,
    /// 已归档
    Archived,
    /// 已删除
    Deleted,
}

impl Default for DataFileStatus {
    fn default() -> Self {
        DataFileStatus::Active
    }
}

/// 数据文件实体
#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct DataFile {
    /// 文件ID (UUID)
    pub id: Uuid,
    /// 关联试验ID
    pub experiment_id: Option<Uuid>,
    /// 文件路径
    pub file_path: String,
    /// 文件哈希 (SHA-256)
    pub file_hash: String,
    /// 来源类型
    pub source_type: SourceType,
    /// 所有者类型
    pub owner_type: String,
    /// 所有者ID
    pub owner_id: Uuid,
    /// 数据大小 (字节)
    pub data_size_bytes: i64,
    /// 记录数量
    pub record_count: i32,
    /// 状态
    pub status: DataFileStatus,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl DataFile {
    /// 创建数据文件记录
    pub fn new(
        file_path: String,
        file_hash: String,
        source_type: SourceType,
        owner_type: String,
        owner_id: Uuid,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            experiment_id: None,
            file_path,
            file_hash,
            source_type,
            owner_type,
            owner_id,
            data_size_bytes: 0,
            record_count: 0,
            status: DataFileStatus::Active,
            created_at: now,
            updated_at: now,
        }
    }
}

/// 创建数据文件请求DTO
#[derive(Debug, Deserialize)]
pub struct CreateDataFileRequest {
    pub experiment_id: Option<Uuid>,
    pub file_path: String,
    pub file_hash: String,
    pub source_type: SourceType,
    pub owner_type: String,
    pub owner_id: Uuid,
    pub data_size_bytes: i64,
    pub record_count: i32,
}

/// 更新数据文件请求DTO
#[derive(Debug, Deserialize, Default)]
pub struct UpdateDataFileRequest {
    pub data_size_bytes: Option<i64>,
    pub record_count: Option<i32>,
    pub status: Option<DataFileStatus>,
}

/// 数据文件响应DTO
#[derive(Debug, Serialize)]
pub struct DataFileResponse {
    pub id: Uuid,
    pub experiment_id: Option<Uuid>,
    pub file_path: String,
    pub file_hash: String,
    pub source_type: SourceType,
    pub owner_type: String,
    pub owner_id: Uuid,
    pub data_size_bytes: i64,
    pub record_count: i32,
    pub status: DataFileStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<DataFile> for DataFileResponse {
    fn from(df: DataFile) -> Self {
        Self {
            id: df.id,
            experiment_id: df.experiment_id,
            file_path: df.file_path,
            file_hash: df.file_hash,
            source_type: df.source_type,
            owner_type: df.owner_type,
            owner_id: df.owner_id,
            data_size_bytes: df.data_size_bytes,
            record_count: df.record_count,
            status: df.status,
            created_at: df.created_at,
            updated_at: df.updated_at,
        }
    }
}
