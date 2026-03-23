//! 测点仓库模块

use async_trait::async_trait;
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;
use crate::models::entities::point::{Point, PointStatus, DataType, AccessType};

/// 仓库错误类型
#[derive(Debug, thiserror::Error)]
pub enum PointRepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Not found")]
    NotFound,
}

/// 测点仓库 trait
#[async_trait]
pub trait PointRepository: Send + Sync {
    async fn create(&self, point: &Point) -> Result<Point, PointRepositoryError>;
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Point>, PointRepositoryError>;
    async fn find_by_device_id(
        &self,
        device_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Point>, i64), PointRepositoryError>;
    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        unit: Option<String>,
        min_value: Option<f64>,
        max_value: Option<f64>,
        default_value: Option<String>,
        status: Option<PointStatus>,
    ) -> Result<Point, PointRepositoryError>;
    async fn delete(&self, id: Uuid) -> Result<(), PointRepositoryError>;
    async fn delete_by_device_id(&self, device_id: Uuid) -> Result<(), PointRepositoryError>;
    async fn find_ids_by_device_id(&self, device_id: Uuid) -> Result<Vec<Uuid>, PointRepositoryError>;
}

/// SQLx测点仓库实现
#[derive(Clone)]
pub struct SqlxPointRepository {
    pool: SqlitePool,
}

impl SqlxPointRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[derive(Debug, FromRow)]
struct PointRow {
    id: String,
    device_id: String,
    name: String,
    data_type: String,
    access_type: String,
    unit: Option<String>,
    min_value: Option<f64>,
    max_value: Option<f64>,
    default_value: Option<String>,
    status: String,
    created_at: String,
    updated_at: String,
}

impl PointRow {
    fn to_entity(self) -> Point {
        Point {
            id: Uuid::parse_str(&self.id).unwrap(),
            device_id: Uuid::parse_str(&self.device_id).unwrap(),
            name: self.name,
            data_type: match self.data_type.as_str() {
                "number" => DataType::Number,
                "integer" => DataType::Integer,
                "string" => DataType::String,
                "boolean" => DataType::Boolean,
                _ => DataType::Number,
            },
            access_type: match self.access_type.as_str() {
                "ro" => AccessType::Ro,
                "wo" => AccessType::Wo,
                "rw" => AccessType::Rw,
                _ => AccessType::Ro,
            },
            unit: self.unit,
            min_value: self.min_value,
            max_value: self.max_value,
            default_value: self.default_value,
            status: match self.status.as_str() {
                "disabled" => PointStatus::Disabled,
                _ => PointStatus::Active,
            },
            metadata: None,
            created_at: chrono::DateTime::parse_from_rfc3339(&self.created_at)
                .unwrap()
                .with_timezone(&chrono::Utc),
            updated_at: chrono::DateTime::parse_from_rfc3339(&self.updated_at)
                .unwrap()
                .with_timezone(&chrono::Utc),
        }
    }
}

fn data_type_to_string(dt: DataType) -> &'static str {
    match dt {
        DataType::Number => "number",
        DataType::Integer => "integer",
        DataType::String => "string",
        DataType::Boolean => "boolean",
    }
}

fn access_type_to_string(at: AccessType) -> &'static str {
    match at {
        AccessType::Ro => "ro",
        AccessType::Wo => "wo",
        AccessType::Rw => "rw",
    }
}

fn point_status_to_string(status: PointStatus) -> &'static str {
    match status {
        PointStatus::Active => "active",
        PointStatus::Disabled => "disabled",
    }
}

#[async_trait]
impl PointRepository for SqlxPointRepository {
    async fn create(&self, point: &Point) -> Result<Point, PointRepositoryError> {
        sqlx::query(
            r#"
            INSERT INTO points (id, device_id, name, data_type, access_type, unit, min_value, max_value, default_value, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(point.id.to_string())
        .bind(point.device_id.to_string())
        .bind(&point.name)
        .bind(data_type_to_string(point.data_type))
        .bind(access_type_to_string(point.access_type))
        .bind(&point.unit)
        .bind(point.min_value)
        .bind(point.max_value)
        .bind(&point.default_value)
        .bind(point_status_to_string(point.status))
        .bind(point.created_at.to_rfc3339())
        .bind(point.updated_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

        Ok(point.clone())
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Point>, PointRepositoryError> {
        let row: Option<PointRow> = sqlx::query_as(
            "SELECT * FROM points WHERE id = ?",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| r.to_entity()))
    }

    async fn find_by_device_id(
        &self,
        device_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Point>, i64), PointRepositoryError> {
        let offset = (page - 1) * size;

        let count_row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM points WHERE device_id = ?",
        )
        .bind(device_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        let total = count_row.0;

        let rows: Vec<PointRow> = sqlx::query_as(
            "SELECT * FROM points WHERE device_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?",
        )
        .bind(device_id.to_string())
        .bind(size)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        let points = rows.into_iter().map(|r| r.to_entity()).collect();
        Ok((points, total))
    }

    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        unit: Option<String>,
        min_value: Option<f64>,
        max_value: Option<f64>,
        default_value: Option<String>,
        status: Option<PointStatus>,
    ) -> Result<Point, PointRepositoryError> {
        let mut updates = Vec::new();
        let mut values: Vec<String> = Vec::new();

        if let Some(ref n) = name {
            updates.push("name = ?");
            values.push(n.clone());
        }
        if let Some(ref u) = unit {
            updates.push("unit = ?");
            values.push(u.clone());
        }
        if let Some(mv) = min_value {
            updates.push("min_value = ?");
            values.push(mv.to_string());
        }
        if let Some(mv) = max_value {
            updates.push("max_value = ?");
            values.push(mv.to_string());
        }
        if let Some(ref d) = default_value {
            updates.push("default_value = ?");
            values.push(d.clone());
        }
        if let Some(st) = status {
            updates.push("status = ?");
            values.push(point_status_to_string(st).to_string());
        }

        if updates.is_empty() {
            return self
                .find_by_id(id)
                .await?
                .ok_or(PointRepositoryError::NotFound);
        }

        updates.push("updated_at = ?");
        values.push(chrono::Utc::now().to_rfc3339());

        let query = format!(
            "UPDATE points SET {} WHERE id = ?",
            updates.join(", ")
        );

        let mut q = sqlx::query(&query);
        for v in &values {
            q = q.bind(v);
        }
        q = q.bind(id.to_string());

        let result = q.execute(&self.pool).await?;

        if result.rows_affected() == 0 {
            return Err(PointRepositoryError::NotFound);
        }

        self.find_by_id(id)
            .await?
            .ok_or(PointRepositoryError::NotFound)
    }

    async fn delete(&self, id: Uuid) -> Result<(), PointRepositoryError> {
        let result = sqlx::query("DELETE FROM points WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(PointRepositoryError::NotFound);
        }

        Ok(())
    }

    async fn delete_by_device_id(&self, device_id: Uuid) -> Result<(), PointRepositoryError> {
        sqlx::query("DELETE FROM points WHERE device_id = ?")
            .bind(device_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn find_ids_by_device_id(&self, device_id: Uuid) -> Result<Vec<Uuid>, PointRepositoryError> {
        let rows: Vec<(String,)> = sqlx::query_as(
            "SELECT id FROM points WHERE device_id = ?",
        )
        .bind(device_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id,)| Uuid::parse_str(&id).unwrap())
            .collect())
    }
}
