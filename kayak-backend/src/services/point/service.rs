//! 测点服务实现

use async_trait::async_trait;
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repository::device_repo::{DeviceRepository, DeviceRepositoryError};
use crate::db::repository::point_repo::{PointRepository, PointRepositoryError};
use crate::db::repository::workbench_repo::WorkbenchRepository;
use crate::drivers::{DeviceManager, DriverError, PointValue};
use crate::engine::{DriverAccess, ExecutionError};
use crate::models::entities::point::{AccessType, Point};

use super::error::{CreatePointEntity, PointError, UpdatePointEntity};
use super::types::{PagedPointDto, PointDto, PointValueDto};

/// 测点服务接口
#[async_trait]
pub trait PointService: Send + Sync {
    /// 创建测点
    async fn create_point(
        &self,
        user_id: Uuid,
        entity: CreatePointEntity,
    ) -> Result<PointDto, PointError>;

    /// 获取测点详情
    async fn get_point(&self, user_id: Uuid, point_id: Uuid) -> Result<PointDto, PointError>;

    /// 查询测点列表
    async fn list_points(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<PagedPointDto, PointError>;

    /// 更新测点
    async fn update_point(
        &self,
        user_id: Uuid,
        point_id: Uuid,
        entity: UpdatePointEntity,
    ) -> Result<PointDto, PointError>;

    /// 删除测点
    async fn delete_point(&self, user_id: Uuid, point_id: Uuid) -> Result<(), PointError>;

    /// 读取测点值
    async fn read_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid,
    ) -> Result<PointValueDto, PointError>;

    /// 写入测点值
    async fn write_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid,
        value: PointValue,
    ) -> Result<(), PointError>;
}

/// 测点服务实现
pub struct PointServiceImpl {
    device_repo: Arc<dyn DeviceRepository>,
    point_repo: Arc<dyn PointRepository>,
    workbench_repo: Arc<dyn WorkbenchRepository>,
    device_manager: Arc<DeviceManager>,
}

impl PointServiceImpl {
    pub fn new(
        device_repo: Arc<dyn DeviceRepository>,
        point_repo: Arc<dyn PointRepository>,
        workbench_repo: Arc<dyn WorkbenchRepository>,
        device_manager: Arc<DeviceManager>,
    ) -> Self {
        Self {
            device_repo,
            point_repo,
            workbench_repo,
            device_manager,
        }
    }

    /// 验证用户是否拥有设备所属的工作台
    async fn verify_device_ownership(
        &self,
        user_id: Uuid,
        device_id: Uuid,
    ) -> Result<Uuid, PointError> {
        let device = self
            .device_repo
            .find_by_id(device_id)
            .await
            .map_err(|e| PointError::DatabaseError(e.to_string()))?;

        match device {
            Some(d) => {
                let workbench = self
                    .workbench_repo
                    .find_by_id(d.workbench_id)
                    .await
                    .map_err(|e| PointError::DatabaseError(e.to_string()))?;

                match workbench {
                    Some(wb) if wb.owner_id == user_id => Ok(d.workbench_id),
                    Some(_) => Err(PointError::AccessDenied),
                    None => Err(PointError::DeviceNotFound),
                }
            }
            None => Err(PointError::DeviceNotFound),
        }
    }

    /// 验证测点所有权
    async fn verify_point_ownership(
        &self,
        user_id: Uuid,
        point_id: Uuid,
    ) -> Result<Uuid, PointError> {
        let point = self
            .point_repo
            .find_by_id(point_id)
            .await
            .map_err(|e| PointError::DatabaseError(e.to_string()))?;

        match point {
            Some(p) => self.verify_device_ownership(user_id, p.device_id).await,
            None => Err(PointError::NotFound),
        }
    }

    /// 将Point转换为DTO
    fn to_dto(point: Point) -> PointDto {
        PointDto {
            id: point.id,
            device_id: point.device_id,
            name: point.name,
            data_type: point.data_type,
            access_type: point.access_type,
            unit: point.unit,
            min_value: point.min_value,
            max_value: point.max_value,
            default_value: point.default_value,
            status: point.status,
            created_at: point.created_at.to_rfc3339(),
            updated_at: point.updated_at.to_rfc3339(),
        }
    }
}

impl From<PointRepositoryError> for PointError {
    fn from(err: PointRepositoryError) -> Self {
        match err {
            PointRepositoryError::NotFound => PointError::NotFound,
            PointRepositoryError::Database(e) => PointError::DatabaseError(e.to_string()),
        }
    }
}

impl From<DeviceRepositoryError> for PointError {
    fn from(err: DeviceRepositoryError) -> Self {
        match err {
            DeviceRepositoryError::NotFound => PointError::DeviceNotFound,
            DeviceRepositoryError::Database(e) => PointError::DatabaseError(e.to_string()),
        }
    }
}

impl From<DriverError> for PointError {
    fn from(err: DriverError) -> Self {
        match err {
            DriverError::NotConnected => PointError::DeviceNotConnected,
            DriverError::ReadOnlyPoint => PointError::ReadOnlyPoint,
            DriverError::InvalidValue { message } => PointError::ValidationError(message),
            _ => PointError::DatabaseError(err.to_string()),
        }
    }
}

impl From<ExecutionError> for PointError {
    fn from(_err: ExecutionError) -> Self {
        PointError::DeviceNotConnected
    }
}

#[async_trait]
impl PointService for PointServiceImpl {
    async fn create_point(
        &self,
        user_id: Uuid,
        entity: CreatePointEntity,
    ) -> Result<PointDto, PointError> {
        // 验证设备所有权
        self.verify_device_ownership(user_id, entity.device_id)
            .await?;

        // 创建测点
        let mut point = Point::new(
            entity.device_id,
            entity.name,
            entity.data_type,
            entity.access_type,
        );

        point.unit = entity.unit;
        point.min_value = entity.min_value;
        point.max_value = entity.max_value;
        point.default_value = entity.default_value;

        self.point_repo.create(&point).await?;

        Ok(Self::to_dto(point))
    }

    async fn get_point(&self, user_id: Uuid, point_id: Uuid) -> Result<PointDto, PointError> {
        let _workbench_id = self.verify_point_ownership(user_id, point_id).await?;

        let point = self
            .point_repo
            .find_by_id(point_id)
            .await?
            .ok_or(PointError::NotFound)?;

        Ok(Self::to_dto(point))
    }

    async fn list_points(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<PagedPointDto, PointError> {
        // 验证设备所有权
        self.verify_device_ownership(user_id, device_id).await?;

        let (points, total) = self
            .point_repo
            .find_by_device_id(device_id, page, size)
            .await
            .map_err(|e| PointError::DatabaseError(e.to_string()))?;

        Ok(PagedPointDto {
            total,
            page,
            size,
            items: points.into_iter().map(Self::to_dto).collect(),
        })
    }

    async fn update_point(
        &self,
        user_id: Uuid,
        point_id: Uuid,
        entity: UpdatePointEntity,
    ) -> Result<PointDto, PointError> {
        let _workbench_id = self.verify_point_ownership(user_id, point_id).await?;

        let point = self
            .point_repo
            .update(
                point_id,
                entity.name,
                entity.unit,
                entity.min_value,
                entity.max_value,
                entity.default_value,
                entity.status,
            )
            .await?;

        Ok(Self::to_dto(point))
    }

    async fn delete_point(&self, user_id: Uuid, point_id: Uuid) -> Result<(), PointError> {
        let _workbench_id = self.verify_point_ownership(user_id, point_id).await?;

        self.point_repo.delete(point_id).await?;

        Ok(())
    }

    async fn read_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid,
    ) -> Result<PointValueDto, PointError> {
        let _workbench_id = self.verify_point_ownership(user_id, point_id).await?;

        let point = self
            .point_repo
            .find_by_id(point_id)
            .await?
            .ok_or(PointError::NotFound)?;

        // 获取设备驱动
        let driver_arc = self
            .device_manager
            .get_device(point.device_id)
            .ok_or(PointError::DeviceNotConnected)?;

        // 直接同步调用（read_point 现在是同步方法）
        let value = {
            let driver = driver_arc.lock().await;
            driver.read_point(point_id)?
        };

        Ok(PointValueDto {
            point_id,
            value,
            timestamp: chrono::Utc::now().to_rfc3339(),
        })
    }

    async fn write_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid,
        value: PointValue,
    ) -> Result<(), PointError> {
        let _workbench_id = self.verify_point_ownership(user_id, point_id).await?;

        let point = self
            .point_repo
            .find_by_id(point_id)
            .await?
            .ok_or(PointError::NotFound)?;

        // 检查访问类型
        if point.access_type == AccessType::Ro {
            return Err(PointError::ReadOnlyPoint);
        }

        // 获取设备驱动
        let driver_arc = self
            .device_manager
            .get_device(point.device_id)
            .ok_or(PointError::DeviceNotConnected)?;

        // 直接同步调用（write_point 现在是同步方法）
        {
            let driver = driver_arc.lock().await;
            driver.write_point(point_id, value)?;
        }

        Ok(())
    }
}
