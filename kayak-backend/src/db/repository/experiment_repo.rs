//! Experiment Repository
//!
//! 提供试验实体的数据访问层

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

use crate::db::connection::DbPool;
use crate::models::entities::experiment::{Experiment, ExperimentStatus};

/// Controls how method_id should be updated during a state transition.
#[derive(Debug, Clone, Copy)]
pub enum MethodIdUpdate {
    /// Set method_id to a specific value (used by Load operation)
    Set(Uuid),
    /// Clear method_id (used by Reset operation)
    Clear,
    /// Do not change method_id (used by Start, Pause, Resume, Stop, etc.)
    Preserve,
}

/// Repository错误类型
#[derive(Debug, thiserror::Error)]
pub enum ExperimentRepositoryError {
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    
    #[error("Not found: {0}")]
    NotFound(Uuid),
}

/// Row structure for experiment queries
#[derive(Debug, FromRow)]
struct ExperimentRow {
    id: String,
    user_id: String,
    method_id: Option<String>,
    name: String,
    description: Option<String>,
    status: String,
    started_at: Option<String>,
    ended_at: Option<String>,
    created_at: String,
    updated_at: String,
}

impl ExperimentRow {
    fn to_experiment(&self) -> Experiment {
        let status = match self.status.as_str() {
            "IDLE" => ExperimentStatus::Idle,
            "LOADED" => ExperimentStatus::Loaded,
            "RUNNING" => ExperimentStatus::Running,
            "PAUSED" => ExperimentStatus::Paused,
            "COMPLETED" => ExperimentStatus::Completed,
            "ABORTED" => ExperimentStatus::Aborted,
            _ => ExperimentStatus::Idle,
        };

        Experiment {
            id: Uuid::parse_str(&self.id).unwrap_or_default(),
            user_id: Uuid::parse_str(&self.user_id).unwrap_or_default(),
            method_id: self.method_id.as_ref().and_then(|s| Uuid::parse_str(s).ok()),
            name: self.name.clone(),
            description: self.description.clone(),
            status,
            started_at: self.started_at.as_ref().and_then(|s| DateTime::parse_from_rfc3339(s).ok().map(|dt| dt.with_timezone(&Utc))),
            ended_at: self.ended_at.as_ref().and_then(|s| DateTime::parse_from_rfc3339(s).ok().map(|dt| dt.with_timezone(&Utc))),
            created_at: DateTime::parse_from_rfc3339(&self.created_at)
                .map(|dt| dt.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
            updated_at: DateTime::parse_from_rfc3339(&self.updated_at)
                .map(|dt| dt.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
        }
    }
}

/// ExperimentRepository trait
#[async_trait]
pub trait ExperimentRepository: Send + Sync {
    /// 根据ID查找试验
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Experiment>, ExperimentRepositoryError>;

    /// 根据用户ID查找试验列表
    async fn find_by_user_id(
        &self,
        user_id: Uuid,
    ) -> Result<Vec<Experiment>, ExperimentRepositoryError>;

    /// 分页查询试验
    async fn find_paged(
        &self,
        user_id: Option<Uuid>,
        status: Option<ExperimentStatus>,
        page: u32,
        size: u32,
    ) -> Result<(Vec<Experiment>, u64), ExperimentRepositoryError>;

    /// 创建试验
    async fn create(&self, experiment: &Experiment) -> Result<Experiment, ExperimentRepositoryError>;

    /// 更新试验
    async fn update(&self, experiment: &Experiment) -> Result<Experiment, ExperimentRepositoryError>;

    /// 删除试验
    async fn delete(&self, id: Uuid) -> Result<u64, ExperimentRepositoryError>;

    /// 更新试验状态
    #[deprecated(since = "0.2.0", note = "Use update_state() instead")]
    async fn update_status(
        &self,
        id: Uuid,
        status: ExperimentStatus,
    ) -> Result<Experiment, ExperimentRepositoryError>;

    /// Update experiment state with explicit control over method_id and timestamps.
    /// This is the primary method used by the state machine service.
    ///
    /// - `method_id`: Controls how method_id is updated (Set/Clear/Preserve)
    /// - `started_at`: If Some, sets the started_at timestamp
    /// - `ended_at`: If Some, sets the ended_at timestamp
    async fn update_state(
        &self,
        id: Uuid,
        status: ExperimentStatus,
        method_id: MethodIdUpdate,
        started_at: Option<DateTime<Utc>>,
        ended_at: Option<DateTime<Utc>>,
    ) -> Result<Experiment, ExperimentRepositoryError>;
}

/// Sqlx Experiment Repository implementation for SQLite
pub struct SqlxExperimentRepository {
    pool: DbPool,
}

impl SqlxExperimentRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ExperimentRepository for SqlxExperimentRepository {
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Experiment>, ExperimentRepositoryError> {
        let row: Option<ExperimentRow> = sqlx::query_as(
            r#"
            SELECT id, user_id, method_id, name, description, status,
                   started_at, ended_at, created_at, updated_at
            FROM experiments
            WHERE id = ?
            "#,
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| r.to_experiment()))
    }

    async fn find_by_user_id(
        &self,
        user_id: Uuid,
    ) -> Result<Vec<Experiment>, ExperimentRepositoryError> {
        let rows: Vec<ExperimentRow> = sqlx::query_as(
            r#"
            SELECT id, user_id, method_id, name, description, status,
                   started_at, ended_at, created_at, updated_at
            FROM experiments
            WHERE user_id = ?
            ORDER BY created_at DESC
            "#,
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|r| r.to_experiment()).collect())
    }

    async fn find_paged(
        &self,
        user_id: Option<Uuid>,
        status: Option<ExperimentStatus>,
        page: u32,
        size: u32,
    ) -> Result<(Vec<Experiment>, u64), ExperimentRepositoryError> {
        let offset = (page - 1) * size;

        // Build the query based on filters
        let (rows, total) = if let Some(uid) = user_id {
            let uid_str = uid.to_string();
            let status_str = status.map(|s| format!("{:?}", s).to_uppercase());

            if let Some(st) = status_str {
                // Filter by user_id and status
                let count_row: (i64,) = sqlx::query_as(
                    "SELECT COUNT(*) FROM experiments WHERE user_id = ? AND status = ?",
                )
                .bind(&uid_str)
                .bind(&st)
                .fetch_one(&self.pool)
                .await?;

                let rows: Vec<ExperimentRow> = sqlx::query_as(
                    r#"
                    SELECT id, user_id, method_id, name, description, status,
                           started_at, ended_at, created_at, updated_at
                    FROM experiments
                    WHERE user_id = ? AND status = ?
                    ORDER BY created_at DESC
                    LIMIT ? OFFSET ?
                    "#,
                )
                .bind(&uid_str)
                .bind(&st)
                .bind(size as i64)
                .bind(offset as i64)
                .fetch_all(&self.pool)
                .await?;

                (rows, count_row.0 as u64)
            } else {
                // Filter by user_id only
                let count_row: (i64,) = sqlx::query_as(
                    "SELECT COUNT(*) FROM experiments WHERE user_id = ?",
                )
                .bind(&uid_str)
                .fetch_one(&self.pool)
                .await?;

                let rows: Vec<ExperimentRow> = sqlx::query_as(
                    r#"
                    SELECT id, user_id, method_id, name, description, status,
                           started_at, ended_at, created_at, updated_at
                    FROM experiments
                    WHERE user_id = ?
                    ORDER BY created_at DESC
                    LIMIT ? OFFSET ?
                    "#,
                )
                .bind(&uid_str)
                .bind(size as i64)
                .bind(offset as i64)
                .fetch_all(&self.pool)
                .await?;

                (rows, count_row.0 as u64)
            }
        } else if let Some(st) = status {
            let status_str = format!("{:?}", st).to_uppercase();
            
            let count_row: (i64,) = sqlx::query_as(
                "SELECT COUNT(*) FROM experiments WHERE status = ?",
            )
            .bind(&status_str)
            .fetch_one(&self.pool)
            .await?;

            let rows: Vec<ExperimentRow> = sqlx::query_as(
                r#"
                SELECT id, user_id, method_id, name, description, status,
                       started_at, ended_at, created_at, updated_at
                FROM experiments
                WHERE status = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
                "#,
            )
            .bind(&status_str)
            .bind(size as i64)
            .bind(offset as i64)
            .fetch_all(&self.pool)
            .await?;

            (rows, count_row.0 as u64)
        } else {
            // No filters
            let count_row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM experiments")
                .fetch_one(&self.pool)
                .await?;

            let rows: Vec<ExperimentRow> = sqlx::query_as(
                r#"
                SELECT id, user_id, method_id, name, description, status,
                       started_at, ended_at, created_at, updated_at
                FROM experiments
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
                "#,
            )
            .bind(size as i64)
            .bind(offset as i64)
            .fetch_all(&self.pool)
            .await?;

            (rows, count_row.0 as u64)
        };

        Ok((rows.into_iter().map(|r| r.to_experiment()).collect(), total))
    }

    async fn create(&self, experiment: &Experiment) -> Result<Experiment, ExperimentRepositoryError> {
        let status_str = format!("{:?}", experiment.status).to_uppercase();

        sqlx::query(
            r#"
            INSERT INTO experiments (id, user_id, method_id, name, description, status,
                                     started_at, ended_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(experiment.id.to_string())
        .bind(experiment.user_id.to_string())
        .bind(experiment.method_id.map(|m| m.to_string()))
        .bind(&experiment.name)
        .bind(&experiment.description)
        .bind(&status_str)
        .bind(experiment.started_at)
        .bind(experiment.ended_at)
        .bind(experiment.created_at)
        .bind(experiment.updated_at)
        .execute(&self.pool)
        .await?;

        Ok(experiment.clone())
    }

    async fn update(&self, experiment: &Experiment) -> Result<Experiment, ExperimentRepositoryError> {
        let status_str = format!("{:?}", experiment.status).to_uppercase();

        sqlx::query(
            r#"
            UPDATE experiments
            SET user_id = ?, method_id = ?, name = ?, description = ?,
                status = ?, started_at = ?, ended_at = ?, updated_at = ?
            WHERE id = ?
            "#,
        )
        .bind(experiment.user_id.to_string())
        .bind(experiment.method_id.map(|m| m.to_string()))
        .bind(&experiment.name)
        .bind(&experiment.description)
        .bind(&status_str)
        .bind(experiment.started_at)
        .bind(experiment.ended_at)
        .bind(experiment.updated_at)
        .bind(experiment.id.to_string())
        .execute(&self.pool)
        .await?;

        Ok(experiment.clone())
    }

    async fn delete(&self, id: Uuid) -> Result<u64, ExperimentRepositoryError> {
        let result = sqlx::query("DELETE FROM experiments WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected())
    }

    #[allow(deprecated)]
    async fn update_status(
        &self,
        id: Uuid,
        status: ExperimentStatus,
    ) -> Result<Experiment, ExperimentRepositoryError> {
        let status_str = format!("{:?}", status).to_uppercase();
        let now = Utc::now();

        sqlx::query(
            r#"
            UPDATE experiments
            SET status = ?, updated_at = ?
            WHERE id = ?
            "#,
        )
        .bind(&status_str)
        .bind(now)
        .bind(id.to_string())
        .execute(&self.pool)
        .await?;

        self.find_by_id(id)
            .await?
            .ok_or(ExperimentRepositoryError::NotFound(id))
    }

    async fn update_state(
        &self,
        id: Uuid,
        status: ExperimentStatus,
        method_id: MethodIdUpdate,
        started_at: Option<DateTime<Utc>>,
        ended_at: Option<DateTime<Utc>>,
    ) -> Result<Experiment, ExperimentRepositoryError> {
        let status_str = format!("{:?}", status).to_uppercase();
        let now = Utc::now();

        // First, get the current experiment to determine method_id handling
        let current = self.find_by_id(id).await?
            .ok_or(ExperimentRepositoryError::NotFound(id))?;

        // Determine the new method_id based on the update type
        let new_method_id = match method_id {
            MethodIdUpdate::Set(uuid) => Some(uuid),
            MethodIdUpdate::Clear => None,
            MethodIdUpdate::Preserve => current.method_id,
        };

        // Determine started_at and ended_at
        // If the caller provides a value, use it; otherwise preserve existing
        let final_started_at = match started_at {
            Some(dt) => Some(dt),
            None => current.started_at,
        };
        let final_ended_at = match ended_at {
            Some(dt) => Some(dt),
            None => current.ended_at,
        };

        sqlx::query(
            r#"
            UPDATE experiments
            SET status = ?, method_id = ?, started_at = ?, ended_at = ?, updated_at = ?
            WHERE id = ?
            "#,
        )
        .bind(&status_str)
        .bind(new_method_id.map(|u| u.to_string()))
        .bind(final_started_at)
        .bind(final_ended_at)
        .bind(now)
        .bind(id.to_string())
        .execute(&self.pool)
        .await?;

        self.find_by_id(id)
            .await?
            .ok_or(ExperimentRepositoryError::NotFound(id))
    }
}
