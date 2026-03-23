//! 设备服务实现

use std::sync::Arc;
use uuid::Uuid;
use async_trait::async_trait;

use crate::db::repository::device_repo::{DeviceRepository, DeviceRepositoryError};
use crate::db::repository::point_repo::PointRepository;
use crate::db::repository::workbench_repo::WorkbenchRepository;
use crate::drivers::{DeviceManager, VirtualDriver, VirtualConfig};
use crate::models::entities::device::{Device, ProtocolType};

use super::error::{CreateDeviceEntity, DeviceError, UpdateDeviceEntity};
use super::types::{DeviceDto, PagedDeviceDto};

/// 设备服务接口
#[async_trait]
pub trait DeviceService: Send + Sync {
    /// 创建设备
    async fn create_device(
        &self,
        user_id: Uuid,
        entity: CreateDeviceEntity,
    ) -> Result<DeviceDto, DeviceError>;
    
    /// 获取设备详情
    async fn get_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
    ) -> Result<DeviceDto, DeviceError>;
    
    /// 查询设备列表
    async fn list_devices(
        &self,
        user_id: Uuid,
        workbench_id: Uuid,
        parent_id: Option<Uuid>,
        page: i64,
        size: i64,
    ) -> Result<PagedDeviceDto, DeviceError>;
    
    /// 更新设备
    async fn update_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        entity: UpdateDeviceEntity,
    ) -> Result<DeviceDto, DeviceError>;
    
    /// 删除设备
    async fn delete_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
    ) -> Result<(), DeviceError>;
}

/// 设备服务实现
pub struct DeviceServiceImpl {
    device_repo: Arc<dyn DeviceRepository>,
    point_repo: Arc<dyn PointRepository>,
    workbench_repo: Arc<dyn WorkbenchRepository>,
    device_manager: Arc<DeviceManager>,
}

impl DeviceServiceImpl {
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

    /// 验证用户是否拥有工作台
    async fn verify_workbench_ownership(&self, user_id: Uuid, workbench_id: Uuid) -> Result<(), DeviceError> {
        let workbench = self.workbench_repo
            .find_by_id(workbench_id)
            .await
            .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
        
        match workbench {
            Some(wb) if wb.owner_id == user_id => Ok(()),
            Some(_) => Err(DeviceError::AccessDenied),
            None => Err(DeviceError::WorkbenchNotFound),
        }
    }

    /// 验证设备所属工作台的所有权
    async fn verify_device_ownership(&self, user_id: Uuid, device_id: Uuid) -> Result<Uuid, DeviceError> {
        let device = self.device_repo
            .find_by_id(device_id)
            .await
            .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
        
        match device {
            Some(d) => {
                self.verify_workbench_ownership(user_id, d.workbench_id).await?;
                Ok(d.workbench_id)
            }
            None => Err(DeviceError::NotFound),
        }
    }

    /// 检查循环引用
    async fn check_circular_reference(
        &self,
        device_id: Uuid,
        new_parent_id: Uuid,
    ) -> Result<bool, DeviceError> {
        if device_id == new_parent_id {
            return Ok(true);
        }
        
        let descendants = self.device_repo
            .find_all_descendant_ids(device_id)
            .await
            .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
        
        Ok(descendants.contains(&new_parent_id))
    }

    /// 将Device转换为DTO
    fn to_dto(device: Device) -> DeviceDto {
        DeviceDto {
            id: device.id,
            workbench_id: device.workbench_id,
            parent_id: device.parent_id,
            name: device.name,
            protocol_type: device.protocol_type,
            protocol_params: device.protocol_params,
            manufacturer: device.manufacturer,
            model: device.model,
            sn: device.sn,
            status: device.status,
            created_at: device.created_at.to_rfc3339(),
            updated_at: device.updated_at.to_rfc3339(),
        }
    }
}

impl From<DeviceRepositoryError> for DeviceError {
    fn from(err: DeviceRepositoryError) -> Self {
        match err {
            DeviceRepositoryError::NotFound => DeviceError::NotFound,
            DeviceRepositoryError::Database(e) => DeviceError::DatabaseError(e.to_string()),
        }
    }
}

#[async_trait]
impl DeviceService for DeviceServiceImpl {
    async fn create_device(
        &self,
        user_id: Uuid,
        entity: CreateDeviceEntity,
    ) -> Result<DeviceDto, DeviceError> {
        // 验证工作台所有权
        self.verify_workbench_ownership(user_id, entity.workbench_id).await?;

        // 如果指定了父设备，检查循环引用
        if let Some(parent_id) = entity.parent_id {
            // 验证父设备存在且属于同一工作台
            let parent = self.device_repo
                .find_by_id(parent_id)
                .await
                .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
            
            match parent {
                Some(p) if p.workbench_id == entity.workbench_id => {
                    // 检查循环引用
                    if self.check_circular_reference(parent_id, entity.workbench_id).await? {
                        return Err(DeviceError::CircularReference);
                    }
                }
                Some(_) => return Err(DeviceError::ValidationError(
                    "Parent device does not belong to the same workbench".to_string(),
                )),
                None => return Err(DeviceError::ValidationError(
                    "Parent device not found".to_string(),
                )),
            }
        }

        // 创建设备
        let device = Device::new(
            entity.workbench_id,
            entity.name,
            entity.protocol_type,
            entity.parent_id,
        );

        // 如果提供了可选字段，更新它们
        let mut device = device;
        device.protocol_params = entity.protocol_params.clone();
        device.manufacturer = entity.manufacturer;
        device.model = entity.model;
        device.sn = entity.sn;

        // 保存到数据库
        self.device_repo
            .create(&device)
            .await?;

        // 如果是虚拟设备，注册到DeviceManager
        if device.protocol_type == ProtocolType::Virtual {
            let config: VirtualConfig = entity.protocol_params
                .and_then(|p| serde_json::from_value(p).ok())
                .unwrap_or_default();
            
            let driver = VirtualDriver::with_config(config)
                .map_err(|e| DeviceError::ValidationError(e.to_string()))?;
            
            let _ = self.device_manager.register_device(device.id, driver);
        }

        Ok(Self::to_dto(device))
    }

    async fn get_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
    ) -> Result<DeviceDto, DeviceError> {
        let _workbench_id = self.verify_device_ownership(user_id, device_id).await?;
        
        let device = self.device_repo
            .find_by_id(device_id)
            .await?
            .ok_or(DeviceError::NotFound)?;

        Ok(Self::to_dto(device))
    }

    async fn list_devices(
        &self,
        user_id: Uuid,
        workbench_id: Uuid,
        parent_id: Option<Uuid>,
        page: i64,
        size: i64,
    ) -> Result<PagedDeviceDto, DeviceError> {
        // 验证工作台所有权
        self.verify_workbench_ownership(user_id, workbench_id).await?;

        let (devices, total) = if let Some(pid) = parent_id {
            self.device_repo
                .find_by_workbench_and_parent(workbench_id, Some(pid), page, size)
                .await
                .map_err(|e| DeviceError::DatabaseError(e.to_string()))?
        } else {
            self.device_repo
                .find_by_workbench_and_parent(workbench_id, None, page, size)
                .await
                .map_err(|e| DeviceError::DatabaseError(e.to_string()))?
        };

        Ok(PagedDeviceDto {
            total,
            page,
            size,
            items: devices.into_iter().map(Self::to_dto).collect(),
        })
    }

    async fn update_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        entity: UpdateDeviceEntity,
    ) -> Result<DeviceDto, DeviceError> {
        let _workbench_id = self.verify_device_ownership(user_id, device_id).await?;

        // 如果要更新parent_id，检查循环引用
        if let Some(_new_parent_id) = entity.status.as_ref().and_then(|_| entity.protocol_params.as_ref()) {
            // 这里简化处理，实际应该检查parent_id变化
        }

        let device = self.device_repo
            .update(
                device_id,
                entity.name,
                entity.protocol_params,
                entity.manufacturer,
                entity.model,
                entity.sn,
                entity.status,
            )
            .await?;

        Ok(Self::to_dto(device))
    }

    async fn delete_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
    ) -> Result<(), DeviceError> {
        let _workbench_id = self.verify_device_ownership(user_id, device_id).await?;

        // 获取所有子设备ID（递归）
        let all_device_ids = self.device_repo
            .find_all_descendant_ids(device_id)
            .await
            .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
        
        // 添加要删除的设备本身
        let mut all_ids = all_device_ids;
        all_ids.push(device_id);

        // 删除所有设备及其测点（从叶子到根）
        for dev_id in all_ids.iter().rev() {
            // 删除该设备的所有测点
            self.point_repo
                .delete_by_device_id(*dev_id)
                .await
                .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
            
            // 从DeviceManager注销虚拟设备
            let _ = self.device_manager.unregister_device(*dev_id);
            
            // 删除设备
            self.device_repo
                .delete(*dev_id)
                .await
                .map_err(|e| DeviceError::DatabaseError(e.to_string()))?;
        }

        Ok(())
    }
}
