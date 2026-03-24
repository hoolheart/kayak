//! 设备仓库模块

use async_trait::async_trait;
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;
use crate::models::entities::device::{Device, DeviceStatus, ProtocolType};

/// 仓库错误类型
#[derive(Debug, thiserror::Error)]
pub enum DeviceRepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Not found")]
    NotFound,
}

/// 设备仓库 trait
#[async_trait]
#[allow(clippy::too_many_arguments)]
pub trait DeviceRepository: Send + Sync {
    async fn create(&self, device: &Device) -> Result<Device, DeviceRepositoryError>;
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Device>, DeviceRepositoryError>;
    async fn find_by_workbench_id(
        &self,
        workbench_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Device>, i64), DeviceRepositoryError>;
    async fn find_by_workbench_and_parent(
        &self,
        workbench_id: Uuid,
        parent_id: Option<Uuid>,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Device>, i64), DeviceRepositoryError>;
    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        protocol_params: Option<serde_json::Value>,
        manufacturer: Option<String>,
        model: Option<String>,
        sn: Option<String>,
        status: Option<DeviceStatus>,
    ) -> Result<Device, DeviceRepositoryError>;
    async fn delete(&self, id: Uuid) -> Result<(), DeviceRepositoryError>;
    async fn find_all_descendant_ids(&self, id: Uuid) -> Result<Vec<Uuid>, DeviceRepositoryError>;
    async fn find_children(&self, parent_id: Uuid) -> Result<Vec<Device>, DeviceRepositoryError>;
}

/// SQLx设备仓库实现
#[derive(Clone)]
pub struct SqlxDeviceRepository {
    pool: SqlitePool,
}

impl SqlxDeviceRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[derive(Debug, FromRow)]
struct DeviceRow {
    id: String,
    workbench_id: String,
    parent_id: Option<String>,
    name: String,
    protocol_type: String,
    protocol_params: Option<String>,
    manufacturer: Option<String>,
    model: Option<String>,
    sn: Option<String>,
    status: String,
    created_at: String,
    updated_at: String,
}

impl DeviceRow {
    #[allow(clippy::wrong_self_convention)]
    fn to_entity(self) -> Device {
        Device {
            id: Uuid::parse_str(&self.id).unwrap(),
            workbench_id: Uuid::parse_str(&self.workbench_id).unwrap(),
            parent_id: self.parent_id.map(|s| Uuid::parse_str(&s).unwrap()),
            name: self.name,
            protocol_type: match self.protocol_type.as_str() {
                "virtual" => ProtocolType::Virtual,
                "modbus_tcp" => ProtocolType::ModbusTcp,
                "modbus_rtu" => ProtocolType::ModbusRtu,
                "can" => ProtocolType::Can,
                "visa" => ProtocolType::Visa,
                "mqtt" => ProtocolType::Mqtt,
                _ => ProtocolType::Virtual,
            },
            protocol_params: self.protocol_params.and_then(|s| serde_json::from_str(&s).ok()),
            manufacturer: self.manufacturer,
            model: self.model,
            sn: self.sn,
            status: match self.status.as_str() {
                "online" => DeviceStatus::Online,
                "error" => DeviceStatus::Error,
                _ => DeviceStatus::Offline,
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

fn protocol_type_to_string(pt: ProtocolType) -> &'static str {
    match pt {
        ProtocolType::Virtual => "virtual",
        ProtocolType::ModbusTcp => "modbus_tcp",
        ProtocolType::ModbusRtu => "modbus_rtu",
        ProtocolType::Can => "can",
        ProtocolType::Visa => "visa",
        ProtocolType::Mqtt => "mqtt",
    }
}

fn device_status_to_string(status: DeviceStatus) -> &'static str {
    match status {
        DeviceStatus::Online => "online",
        DeviceStatus::Offline => "offline",
        DeviceStatus::Error => "error",
    }
}

#[async_trait]
impl DeviceRepository for SqlxDeviceRepository {
    async fn create(&self, device: &Device) -> Result<Device, DeviceRepositoryError> {
        let protocol_params = device
            .protocol_params
            .as_ref()
            .map(|p| serde_json::to_string(p).unwrap_or_default());

        sqlx::query(
            r#"
            INSERT INTO devices (id, workbench_id, parent_id, name, protocol_type, protocol_params, manufacturer, model, sn, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(device.id.to_string())
        .bind(device.workbench_id.to_string())
        .bind(device.parent_id.map(|id| id.to_string()))
        .bind(&device.name)
        .bind(protocol_type_to_string(device.protocol_type))
        .bind(protocol_params)
        .bind(&device.manufacturer)
        .bind(&device.model)
        .bind(&device.sn)
        .bind(device_status_to_string(device.status))
        .bind(device.created_at.to_rfc3339())
        .bind(device.updated_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

        Ok(device.clone())
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Device>, DeviceRepositoryError> {
        let row: Option<DeviceRow> = sqlx::query_as(
            "SELECT * FROM devices WHERE id = ?",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| r.to_entity()))
    }

    async fn find_by_workbench_id(
        &self,
        workbench_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Device>, i64), DeviceRepositoryError> {
        let offset = (page - 1) * size;

        let count_row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM devices WHERE workbench_id = ?",
        )
        .bind(workbench_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        let total = count_row.0;

        let rows: Vec<DeviceRow> = sqlx::query_as(
            "SELECT * FROM devices WHERE workbench_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?",
        )
        .bind(workbench_id.to_string())
        .bind(size)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        let devices = rows.into_iter().map(|r| r.to_entity()).collect();
        Ok((devices, total))
    }

    async fn find_by_workbench_and_parent(
        &self,
        workbench_id: Uuid,
        parent_id: Option<Uuid>,
        page: i64,
        size: i64,
    ) -> Result<(Vec<Device>, i64), DeviceRepositoryError> {
        let offset = (page - 1) * size;

        let (count_query, items_query) = if parent_id.is_some() {
            (
                "SELECT COUNT(*) FROM devices WHERE workbench_id = ? AND parent_id = ?",
                "SELECT * FROM devices WHERE workbench_id = ? AND parent_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?",
            )
        } else {
            (
                "SELECT COUNT(*) FROM devices WHERE workbench_id = ? AND parent_id IS NULL",
                "SELECT * FROM devices WHERE workbench_id = ? AND parent_id IS NULL ORDER BY created_at DESC LIMIT ? OFFSET ?",
            )
        };

        let total: i64 = if let Some(pid) = parent_id {
            let row: (i64,) = sqlx::query_as(count_query)
                .bind(workbench_id.to_string())
                .bind(pid.to_string())
                .fetch_one(&self.pool)
                .await?;
            row.0
        } else {
            let row: (i64,) = sqlx::query_as(count_query)
                .bind(workbench_id.to_string())
                .fetch_one(&self.pool)
                .await?;
            row.0
        };

        let rows: Vec<DeviceRow> = if let Some(pid) = parent_id {
            sqlx::query_as(items_query)
                .bind(workbench_id.to_string())
                .bind(pid.to_string())
                .bind(size)
                .bind(offset)
                .fetch_all(&self.pool)
                .await?
        } else {
            sqlx::query_as(items_query)
                .bind(workbench_id.to_string())
                .bind(size)
                .bind(offset)
                .fetch_all(&self.pool)
                .await?
        };

        let devices = rows.into_iter().map(|r| r.to_entity()).collect();
        Ok((devices, total))
    }

    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        protocol_params: Option<serde_json::Value>,
        manufacturer: Option<String>,
        model: Option<String>,
        sn: Option<String>,
        status: Option<DeviceStatus>,
    ) -> Result<Device, DeviceRepositoryError> {
        let mut updates = Vec::new();
        let mut values: Vec<String> = Vec::new();

        if let Some(ref n) = name {
            updates.push("name = ?");
            values.push(n.clone());
        }
        if let Some(ref p) = protocol_params {
            updates.push("protocol_params = ?");
            values.push(serde_json::to_string(p).unwrap_or_default());
        }
        if let Some(ref m) = manufacturer {
            updates.push("manufacturer = ?");
            values.push(m.clone());
        }
        if let Some(ref m) = model {
            updates.push("model = ?");
            values.push(m.clone());
        }
        if let Some(ref s) = sn {
            updates.push("sn = ?");
            values.push(s.clone());
        }
        if let Some(st) = status {
            updates.push("status = ?");
            values.push(device_status_to_string(st).to_string());
        }

        if updates.is_empty() {
            return self
                .find_by_id(id)
                .await?
                .ok_or(DeviceRepositoryError::NotFound);
        }

        updates.push("updated_at = ?");
        values.push(chrono::Utc::now().to_rfc3339());

        let query = format!(
            "UPDATE devices SET {} WHERE id = ?",
            updates.join(", ")
        );

        let mut q = sqlx::query(&query);
        for v in &values {
            q = q.bind(v);
        }
        q = q.bind(id.to_string());

        let result = q.execute(&self.pool).await?;

        if result.rows_affected() == 0 {
            return Err(DeviceRepositoryError::NotFound);
        }

        self.find_by_id(id)
            .await?
            .ok_or(DeviceRepositoryError::NotFound)
    }

    async fn delete(&self, id: Uuid) -> Result<(), DeviceRepositoryError> {
        let result = sqlx::query("DELETE FROM devices WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(DeviceRepositoryError::NotFound);
        }

        Ok(())
    }

    async fn find_all_descendant_ids(&self, id: Uuid) -> Result<Vec<Uuid>, DeviceRepositoryError> {
        let mut descendants = Vec::new();
        let mut to_process = vec![id];

        while let Some(current_id) = to_process.pop() {
            let children: Vec<DeviceRow> = sqlx::query_as(
                "SELECT * FROM devices WHERE parent_id = ?",
            )
            .bind(current_id.to_string())
            .fetch_all(&self.pool)
            .await?;

            for child in children {
                let child_id = Uuid::parse_str(&child.id).unwrap();
                descendants.push(child_id);
                to_process.push(child_id);
            }
        }

        Ok(descendants)
    }

    async fn find_children(&self, parent_id: Uuid) -> Result<Vec<Device>, DeviceRepositoryError> {
        let rows: Vec<DeviceRow> = sqlx::query_as(
            "SELECT * FROM devices WHERE parent_id = ?",
        )
        .bind(parent_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|r| r.to_entity()).collect())
    }
}
