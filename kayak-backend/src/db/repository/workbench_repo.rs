//! 工作台仓库模块

use crate::models::entities::workbench::{OwnerType, Workbench, WorkbenchStatus};
use async_trait::async_trait;
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;

/// 仓库错误类型
#[derive(Debug, thiserror::Error)]
pub enum WorkbenchRepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Not found")]
    NotFound,
}

/// 工作台仓库 trait
#[async_trait]
pub trait WorkbenchRepository: Send + Sync {
    async fn create(&self, workbench: &Workbench) -> Result<Workbench, WorkbenchRepositoryError>;
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Workbench>, WorkbenchRepositoryError>;
    async fn list_by_owner(
        &self,
        owner_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Workbench>, i64), WorkbenchRepositoryError>;
    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        description: Option<String>,
        status: Option<WorkbenchStatus>,
    ) -> Result<Workbench, WorkbenchRepositoryError>;
    async fn delete(&self, id: Uuid) -> Result<(), WorkbenchRepositoryError>;
}

/// SQLx工作台仓库实现
#[derive(Clone)]
pub struct SqlxWorkbenchRepository {
    pool: SqlitePool,
}

impl SqlxWorkbenchRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[derive(Debug, FromRow)]
struct WorkbenchRow {
    id: String,
    name: String,
    description: Option<String>,
    owner_type: String,
    owner_id: String,
    status: String,
    created_at: String,
    updated_at: String,
}

impl WorkbenchRow {
    #[allow(clippy::wrong_self_convention)]
    fn to_entity(self) -> Workbench {
        Workbench {
            id: Uuid::parse_str(&self.id).unwrap(),
            name: self.name,
            description: self.description,
            owner_type: match self.owner_type.as_str() {
                "team" => OwnerType::Team,
                _ => OwnerType::User,
            },
            owner_id: Uuid::parse_str(&self.owner_id).unwrap(),
            status: match self.status.as_str() {
                "archived" => WorkbenchStatus::Archived,
                "deleted" => WorkbenchStatus::Deleted,
                _ => WorkbenchStatus::Active,
            },
            created_at: chrono::DateTime::parse_from_rfc3339(&self.created_at)
                .unwrap()
                .with_timezone(&chrono::Utc),
            updated_at: chrono::DateTime::parse_from_rfc3339(&self.updated_at)
                .unwrap()
                .with_timezone(&chrono::Utc),
        }
    }
}

#[async_trait]
impl WorkbenchRepository for SqlxWorkbenchRepository {
    async fn create(&self, workbench: &Workbench) -> Result<Workbench, WorkbenchRepositoryError> {
        let owner_type = match workbench.owner_type {
            OwnerType::User => "user",
            OwnerType::Team => "team",
        };
        let status = match workbench.status {
            WorkbenchStatus::Active => "active",
            WorkbenchStatus::Archived => "archived",
            WorkbenchStatus::Deleted => "deleted",
        };

        sqlx::query(
            r#"
            INSERT INTO workbenches (id, name, description, owner_type, owner_id, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(workbench.id.to_string())
        .bind(&workbench.name)
        .bind(&workbench.description)
        .bind(owner_type)
        .bind(workbench.owner_id.to_string())
        .bind(status)
        .bind(workbench.created_at.to_rfc3339())
        .bind(workbench.updated_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

        Ok(workbench.clone())
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Workbench>, WorkbenchRepositoryError> {
        let row: Option<WorkbenchRow> =
            sqlx::query_as("SELECT * FROM workbenches WHERE id = ? AND status != 'deleted'")
                .bind(id.to_string())
                .fetch_optional(&self.pool)
                .await?;

        Ok(row.map(|r| r.to_entity()))
    }

    async fn list_by_owner(
        &self,
        owner_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Workbench>, i64), WorkbenchRepositoryError> {
        let offset = (page - 1) * size;

        // Get total count
        let count_row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM workbenches WHERE owner_id = ? AND status != 'deleted'",
        )
        .bind(owner_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        let total = count_row.0;

        // Get items
        let rows: Vec<WorkbenchRow> = sqlx::query_as(
            "SELECT * FROM workbenches WHERE owner_id = ? AND status != 'deleted' ORDER BY created_at DESC LIMIT ? OFFSET ?"
        )
        .bind(owner_id.to_string())
        .bind(size)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        let workbenches = rows.into_iter().map(|r| r.to_entity()).collect();
        Ok((workbenches, total))
    }

    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        description: Option<String>,
        status: Option<WorkbenchStatus>,
    ) -> Result<Workbench, WorkbenchRepositoryError> {
        // Build dynamic update query
        let mut updates = Vec::new();
        let mut values: Vec<String> = Vec::new();

        if let Some(ref n) = name {
            updates.push("name = ?");
            values.push(n.clone());
        }
        if let Some(ref d) = description {
            updates.push("description = ?");
            values.push(d.clone());
        }
        if let Some(s) = status {
            let status_str = match s {
                WorkbenchStatus::Active => "active",
                WorkbenchStatus::Archived => "archived",
                WorkbenchStatus::Deleted => "deleted",
            };
            updates.push("status = ?");
            values.push(status_str.to_string());
        }

        if updates.is_empty() {
            // No updates, just return the current workbench
            return self
                .find_by_id(id)
                .await?
                .ok_or(WorkbenchRepositoryError::NotFound);
        }

        updates.push("updated_at = ?");
        values.push(chrono::Utc::now().to_rfc3339());

        let query = format!(
            "UPDATE workbenches SET {} WHERE id = ? AND status != 'deleted'",
            updates.join(", ")
        );

        let mut q = sqlx::query(&query);
        for v in &values {
            q = q.bind(v);
        }
        q = q.bind(id.to_string());

        let result = q.execute(&self.pool).await?;

        if result.rows_affected() == 0 {
            return Err(WorkbenchRepositoryError::NotFound);
        }

        self.find_by_id(id)
            .await?
            .ok_or(WorkbenchRepositoryError::NotFound)
    }

    async fn delete(&self, id: Uuid) -> Result<(), WorkbenchRepositoryError> {
        // First check if workbench exists and is not already deleted
        let workbench = self.find_by_id(id).await?;
        if workbench.is_none() {
            return Err(WorkbenchRepositoryError::NotFound);
        }

        // Hard delete - cascade will handle device/point deletion via FK CASCADE
        // S1-003 schema defines:
        // - devices.workbench_id REFERENCES workbenches(id) ON DELETE CASCADE
        // - points.device_id REFERENCES devices(id) ON DELETE CASCADE
        // - devices.parent_id REFERENCES devices(id) ON DELETE CASCADE
        sqlx::query("DELETE FROM workbenches WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }
}
