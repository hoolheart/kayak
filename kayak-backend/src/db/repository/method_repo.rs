//! 试验方法Repository
//!
//! 提供试验方法的数据库操作

use crate::db::repository::method_error::MethodRepositoryError;
use crate::models::entities::Method;
use async_trait::async_trait;
use sqlx::{Pool, Sqlite};
use uuid::Uuid;

#[async_trait]
pub trait MethodRepository: Send + Sync {
    async fn create(&self, method: &Method) -> Result<Method, MethodRepositoryError>;
    async fn get_by_id(&self, id: Uuid) -> Result<Option<Method>, MethodRepositoryError>;
    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        description: Option<String>,
        process_definition: Option<serde_json::Value>,
        parameter_schema: Option<serde_json::Value>,
    ) -> Result<Method, MethodRepositoryError>;
    async fn delete(&self, id: Uuid) -> Result<(), MethodRepositoryError>;
    async fn list_by_user(
        &self,
        user_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Method>, i64), MethodRepositoryError>;
}

pub struct SqlxMethodRepository {
    pool: Pool<Sqlite>,
}

impl SqlxMethodRepository {
    pub fn new(pool: Pool<Sqlite>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl MethodRepository for SqlxMethodRepository {
    async fn create(&self, method: &Method) -> Result<Method, MethodRepositoryError> {
        sqlx::query(
            r#"
            INSERT INTO methods (id, name, description, process_definition, parameter_schema, version, created_by, created_at, updated_at)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
            "#,
        )
        .bind(method.id.to_string())
        .bind(&method.name)
        .bind(&method.description)
        .bind(method.process_definition.to_string())
        .bind(method.parameter_schema.to_string())
        .bind(method.version)
        .bind(method.created_by.to_string())
        .bind(method.created_at)
        .bind(method.updated_at)
        .execute(&self.pool)
        .await?;

        Ok(method.clone())
    }

    async fn get_by_id(&self, id: Uuid) -> Result<Option<Method>, MethodRepositoryError> {
        let method = sqlx::query_as::<_, MethodRow>(
            r#"
            SELECT id, name, description, process_definition, parameter_schema, version, created_by, created_at, updated_at
            FROM methods
            WHERE id = ?1
            "#,
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?
        .map(|row| row.into());

        Ok(method)
    }

    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        description: Option<String>,
        process_definition: Option<serde_json::Value>,
        parameter_schema: Option<serde_json::Value>,
    ) -> Result<Method, MethodRepositoryError> {
        // First check if the method exists
        let existing = self.get_by_id(id).await?;
        if existing.is_none() {
            return Err(MethodRepositoryError::NotFound);
        }
        let mut method = existing.unwrap();

        // Apply updates
        if let Some(n) = name {
            method.name = n;
        }
        if let Some(d) = description {
            method.description = Some(d);
        }
        if let Some(pd) = process_definition {
            method.process_definition = pd;
        }
        if let Some(ps) = parameter_schema {
            method.parameter_schema = ps;
        }
        method.updated_at = chrono::Utc::now();

        sqlx::query(
            r#"
            UPDATE methods
            SET name = ?1, description = ?2, process_definition = ?3, parameter_schema = ?4, updated_at = ?5
            WHERE id = ?6
            "#,
        )
        .bind(&method.name)
        .bind(&method.description)
        .bind(method.process_definition.to_string())
        .bind(method.parameter_schema.to_string())
        .bind(method.updated_at)
        .bind(id.to_string())
        .execute(&self.pool)
        .await?;

        Ok(method)
    }

    async fn delete(&self, id: Uuid) -> Result<(), MethodRepositoryError> {
        let result = sqlx::query("DELETE FROM methods WHERE id = ?1")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(MethodRepositoryError::NotFound);
        }
        Ok(())
    }

    async fn list_by_user(
        &self,
        user_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Method>, i64), MethodRepositoryError> {
        let offset = (page - 1) * size;

        let methods = sqlx::query_as::<_, MethodRow>(
            r#"
            SELECT id, name, description, process_definition, parameter_schema, version, created_by, created_at, updated_at
            FROM methods
            WHERE created_by = ?1
            ORDER BY created_at DESC
            LIMIT ?2 OFFSET ?3
            "#,
        )
        .bind(user_id.to_string())
        .bind(size)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?
        .into_iter()
        .map(|row| row.into())
        .collect();

        let total: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM methods WHERE created_by = ?1"
        )
        .bind(user_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        Ok((methods, total.0))
    }
}

// Internal row type for sqlx
#[derive(sqlx::FromRow)]
struct MethodRow {
    id: String,
    name: String,
    description: Option<String>,
    process_definition: String,
    parameter_schema: String,
    version: i32,
    created_by: String,
    created_at: chrono::DateTime<chrono::Utc>,
    updated_at: chrono::DateTime<chrono::Utc>,
}

impl From<MethodRow> for Method {
    fn from(row: MethodRow) -> Self {
        Method {
            id: Uuid::parse_str(&row.id).unwrap_or_default(),
            name: row.name,
            description: row.description,
            process_definition: serde_json::from_str(&row.process_definition).unwrap_or_default(),
            parameter_schema: serde_json::from_str(&row.parameter_schema).unwrap_or_default(),
            version: row.version,
            created_by: Uuid::parse_str(&row.created_by).unwrap_or_default(),
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}
