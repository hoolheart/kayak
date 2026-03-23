# S1-018: 设备与测点CRUD API - 详细设计文档

**任务ID**: S1-018  
**任务名称**: 设备与测点CRUD API (Device and Point CRUD API)  
**文档版本**: 1.0  
**创建日期**: 2026-03-23  
**状态**: Draft  
**依赖任务**: S1-013 (Workbench CRUD), S1-016 (Device/Point Models), S1-017 (Virtual Driver)  
**后续任务**: S1-019 (设备与测点管理UI)

---

## 1. 设计概述

### 1.1 设计目标

本文档定义设备和测点CRUD API的详细设计方案，实现：
- 设备增删改查RESTful API
- 测点增删改查RESTful API
- 测点值读写API（集成虚拟设备驱动）
- 设备树形结构支持
- 级联删除支持

### 1.2 设计原则

1. **依赖倒置原则 (DIP)**: 定义Repository和Service接口，具体实现依赖于抽象
2. **Repository模式**: 数据访问层抽象，支持单元测试时使用mock实现
3. **Service层分离**: 业务逻辑与API处理分离
4. **所有权验证**: 用户只能操作自己拥有的工作台下的设备

### 1.3 技术栈

| 组件 | 技术 |
|------|------|
| Web框架 | Axum |
| 数据库 | SQLite + sqlx |
| 认证 | JWT Bearer Token |
| 序列化 | serde + serde_json |
| 异步Runtime | Tokio |

---

## 2. 模块结构

### 2.1 文件组织

```
kayak-backend/src/
├── api/
│   ├── handlers/
│   │   ├── mod.rs
│   │   ├── device.rs      # [新增] 设备API处理器
│   │   └── point.rs       # [新增] 测点API处理器
│   └── routes.rs           # [修改] 添加设备/测点路由
├── db/
│   └── repository/
│       ├── mod.rs          # [修改] 添加device_repo和point_repo模块
│       ├── device_repo.rs  # [新增] 设备Repository实现
│       └── point_repo.rs   # [新增] 测点Repository实现
├── models/
│   └── entities/
│       ├── device.rs       # [已有] 设备实体
│       └── point.rs        # [已有] 测点实体
├── services/
│   ├── mod.rs              # [修改] 添加device和point服务模块
│   ├── device.rs           # [新增] 设备服务
│   └── point.rs            # [新增] 测点服务
└── lib.rs                  # [修改] 导出新模块
```

---

## 3. API接口定义

### 3.1 设备API

#### 3.1.1 创建设备

```
POST /api/v1/workbenches/{workbench_id}/devices
```

**请求头**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体** (CreateDeviceRequest):
```json
{
  "name": "Power Supply",
  "protocol_type": "virtual",
  "parent_id": null,
  "protocol_params": {
    "mode": "random",
    "min_value": 0.0,
    "max_value": 100.0
  },
  "manufacturer": "Acme Corp",
  "model": "PS-500",
  "sn": "SN12345"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 设备名称 |
| protocol_type | ProtocolType | 是 | 协议类型 |
| parent_id | UUID | 否 | 父设备ID（用于树形结构） |
| protocol_params | JSON | 否 | 协议参数（如VirtualConfig） |
| manufacturer | string | 否 | 制造商 |
| model | string | 否 | 型号 |
| sn | string | 否 | 序列号 |

**响应** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "workbench_id": "550e8400-e29b-41d4-a716-446655440001",
    "parent_id": null,
    "name": "Power Supply",
    "protocol_type": "virtual",
    "protocol_params": {...},
    "manufacturer": "Acme Corp",
    "model": "PS-500",
    "sn": "SN12345",
    "status": "offline",
    "created_at": "2026-03-23T10:00:00Z",
    "updated_at": "2026-03-23T10:00:00Z"
  }
}
```

#### 3.1.2 查询设备列表

```
GET /api/v1/workbenches/{workbench_id}/devices?page=1&size=10&parent_id=<uuid>
```

**Query参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码（默认1） |
| size | integer | 否 | 每页数量（默认10） |
| parent_id | UUID | 否 | 父设备ID过滤（为空则返回根设备） |

**响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "total": 25,
    "page": 1,
    "size": 10,
    "items": [...]
  }
}
```

#### 3.1.3 获取设备详情

```
GET /api/v1/devices/{id}
```

**响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "...",
    "workbench_id": "...",
    "parent_id": null,
    "name": "Power Supply",
    "protocol_type": "virtual",
    ...
  }
}
```

#### 3.1.4 更新设备

```
PUT /api/v1/devices/{id}
```

**请求体** (UpdateDeviceRequest):
```json
{
  "name": "Updated Name",
  "manufacturer": "New Manufacturer",
  "status": "online"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 否 | 设备名称 |
| manufacturer | string | 否 | 制造商 |
| model | string | 否 | 型号 |
| sn | string | 否 | 序列号 |
| protocol_params | JSON | 否 | 协议参数 |
| status | DeviceStatus | 否 | 设备状态 |

#### 3.1.5 删除设备

```
DELETE /api/v1/devices/{id}
```

**说明**: 执行级联删除，删除该设备及其所有子设备和测点

**响应** (204 No Content)

### 3.2 测点API

#### 3.2.1 创建测点

```
POST /api/v1/devices/{device_id}/points
```

**请求体** (CreatePointRequest):
```json
{
  "name": "Voltage",
  "data_type": "number",
  "access_type": "ro",
  "unit": "V",
  "min_value": 0.0,
  "max_value": 30.0,
  "default_value": "0.0"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 测点名称 |
| data_type | DataType | 是 | 数据类型 |
| access_type | AccessType | 是 | 访问类型 |
| unit | string | 否 | 单位 |
| min_value | number | 否 | 最小值 |
| max_value | number | 否 | 最大值 |
| default_value | string | 否 | 默认值（字符串格式） |

**响应** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "...",
    "device_id": "...",
    "name": "Voltage",
    "data_type": "number",
    "access_type": "ro",
    "unit": "V",
    "min_value": 0.0,
    "max_value": 30.0,
    "default_value": null,
    "status": "active",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

#### 3.2.2 查询测点列表

```
GET /api/v1/devices/{device_id}/points?page=1&size=10
```

**响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "total": 5,
    "page": 1,
    "size": 10,
    "items": [...]
  }
}
```

#### 3.2.3 获取测点详情

```
GET /api/v1/points/{id}
```

#### 3.2.4 更新测点

```
PUT /api/v1/points/{id}
```

**请求体** (UpdatePointRequest):
```json
{
  "name": "Updated Name",
  "unit": "mV",
  "min_value": 0.0,
  "max_value": 50.0,
  "default_value": "25.0",
  "status": "disabled"
}
```

#### 3.2.5 删除测点

```
DELETE /api/v1/points/{id}
```

**响应** (204 No Content)

### 3.3 测点值API

#### 3.3.1 读取测点值

```
GET /api/v1/points/{id}/value
```

**响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "point_id": "...",
    "value": 42.5,
    "timestamp": "2026-03-23T10:00:00Z"
  }
}
```

**说明**: 
- 对于虚拟设备，从VirtualDriver读取模拟数据
- 根据设备配置的VirtualConfig生成对应模式的值

#### 3.3.2 写入测点值

```
PUT /api/v1/points/{id}/value
```

**请求体**:
```json
{
  "value": 25.0
}
```

**响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

**错误响应** (400 Bad Request):
- 尝试写入RO类型测点返回错误

---

## 4. Repository层设计

### 4.1 DeviceRepository Trait

```rust
use async_trait::async_trait;
use uuid::Uuid;
use crate::models::entities::device::{Device, DeviceStatus};

#[async_trait]
pub trait DeviceRepository: Send + Sync {
    /// 创建设备
    async fn create(&self, device: &Device) -> Result<Device, DeviceRepositoryError>;
    
    /// 根据ID查询设备
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Device>, DeviceRepositoryError>;
    
    /// 根据工作台ID查询设备列表（分页）
    async fn find_by_workbench_id(
        &self, 
        workbench_id: Uuid, 
        page: i64, 
        size: i64
    ) -> Result<(Vec<Device>, i64), DeviceRepositoryError>;
    
    /// 根据工作台ID和父设备ID查询子设备
    async fn find_by_workbench_and_parent(
        &self,
        workbench_id: Uuid,
        parent_id: Option<Uuid>,
        page: i64,
        size: i64
    ) -> Result<(Vec<Device>, i64), DeviceRepositoryError>;
    
    /// 更新设备
    async fn update(
        &self, 
        id: Uuid, 
        name: Option<String>,
        protocol_params: Option<serde_json::Value>,
        manufacturer: Option<String>,
        model: Option<String>,
        sn: Option<String>,
        status: Option<DeviceStatus>
    ) -> Result<Device, DeviceRepositoryError>;
    
    /// 删除设备
    async fn delete(&self, id: Uuid) -> Result<(), DeviceRepositoryError>;
    
    /// 获取设备的所有子设备ID（递归）
    async fn find_all_descendant_ids(&self, id: Uuid) -> Result<Vec<Uuid>, DeviceRepositoryError>;
}

#[derive(Debug, thiserror::Error)]
pub enum DeviceRepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Not found")]
    NotFound,
}
```

### 4.2 PointRepository Trait

```rust
use async_trait::async_trait;
use uuid::Uuid;
use crate::models::entities::point::{Point, PointStatus, DataType, AccessType};

#[async_trait]
pub trait PointRepository: Send + Sync {
    /// 创建测点
    async fn create(&self, point: &Point) -> Result<Point, PointRepositoryError>;
    
    /// 根据ID查询测点
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Point>, PointRepositoryError>;
    
    /// 根据设备ID查询测点列表（分页）
    async fn find_by_device_id(
        &self,
        device_id: Uuid,
        page: i64,
        size: i64
    ) -> Result<(Vec<Point>, i64), PointRepositoryError>;
    
    /// 更新测点
    async fn update(
        &self,
        id: Uuid,
        name: Option<String>,
        unit: Option<String>,
        description: Option<String>,
        min_value: Option<f64>,
        max_value: Option<f64>,
        default_value: Option<String>,
        status: Option<PointStatus>
    ) -> Result<Point, PointRepositoryError>;
    
    /// 删除测点
    async fn delete(&self, id: Uuid) -> Result<(), PointRepositoryError>;
    
    /// 根据设备ID删除所有测点
    async fn delete_by_device_id(&self, device_id: Uuid) -> Result<(), PointRepositoryError>;
    
    /// 获取设备的所有测点ID
    async fn find_ids_by_device_id(&self, device_id: Uuid) -> Result<Vec<Uuid>, PointRepositoryError>;
}

#[derive(Debug, thiserror::Error)]
pub enum PointRepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Not found")]
    NotFound,
}
```

---

## 5. Service层设计

### 5.1 DeviceService Trait

```rust
use uuid::Uuid;
use crate::models::entities::device::{Device, DeviceStatus, ProtocolType};
use crate::drivers::VirtualConfig;

pub struct CreateDeviceEntity {
    pub workbench_id: Uuid,
    pub name: String,
    pub protocol_type: ProtocolType,
    pub parent_id: Option<Uuid>,
    pub protocol_params: Option<VirtualConfig>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
}

pub struct UpdateDeviceEntity {
    pub name: Option<String>,
    pub protocol_params: Option<VirtualConfig>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
    pub status: Option<DeviceStatus>,
}

pub struct PagedDeviceDto {
    pub total: i64,
    pub page: i64,
    pub size: i64,
    pub items: Vec<DeviceDto>,
}

pub struct DeviceDto {
    pub id: Uuid,
    pub workbench_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub name: String,
    pub protocol_type: ProtocolType,
    pub protocol_params: Option<serde_json::Value>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
    pub status: DeviceStatus,
    pub created_at: String,
    pub updated_at: String,
}

#[async_trait]
pub trait DeviceService: Send + Sync {
    /// 创建设备
    async fn create_device(
        &self,
        user_id: Uuid,
        entity: CreateDeviceEntity
    ) -> Result<DeviceDto, DeviceServiceError>;
    
    /// 获取设备详情
    async fn get_device(
        &self,
        user_id: Uuid,
        device_id: Uuid
    ) -> Result<DeviceDto, DeviceServiceError>;
    
    /// 查询设备列表
    async fn list_devices(
        &self,
        user_id: Uuid,
        workbench_id: Uuid,
        parent_id: Option<Uuid>,
        page: i64,
        size: i64
    ) -> Result<PagedDeviceDto, DeviceServiceError>;
    
    /// 更新设备
    async fn update_device(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        entity: UpdateDeviceEntity
    ) -> Result<DeviceDto, DeviceServiceError>;
    
    /// 删除设备（级联删除子设备和测点）
    async fn delete_device(
        &self,
        user_id: Uuid,
        device_id: Uuid
    ) -> Result<(), DeviceServiceError>;
}

#[derive(Debug, thiserror::Error)]
pub enum DeviceServiceError {
    #[error("Not found")]
    NotFound,
    
    #[error("Access denied")]
    AccessDenied,
    
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("Invalid parent: circular reference detected")]
    CircularReference,
    
    #[error("Internal error: {0}")]
    InternalError(String),
}
```

### 5.2 PointService Trait

```rust
use uuid::Uuid;
use crate::models::entities::point::{Point, PointStatus, DataType, AccessType};
use crate::drivers::PointValue;

pub struct CreatePointEntity {
    pub device_id: Uuid,
    pub name: String,
    pub data_type: DataType,
    pub access_type: AccessType,
    pub unit: Option<String>,
    pub description: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
}

pub struct UpdatePointEntity {
    pub name: Option<String>,
    pub unit: Option<String>,
    pub description: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
    pub status: Option<PointStatus>,
}

pub struct PagedPointDto {
    pub total: i64,
    pub page: i64,
    pub size: i64,
    pub items: Vec<PointDto>,
}

pub struct PointDto {
    pub id: Uuid,
    pub device_id: Uuid,
    pub name: String,
    pub data_type: DataType,
    pub access_type: AccessType,
    pub unit: Option<String>,
    pub description: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
    pub status: PointStatus,
    pub created_at: String,
    pub updated_at: String,
}

pub struct PointValueDto {
    pub point_id: Uuid,
    pub value: PointValue,
    pub timestamp: String,
}

#[async_trait]
pub trait PointService: Send + Sync {
    /// 创建测点
    async fn create_point(
        &self,
        user_id: Uuid,
        entity: CreatePointEntity
    ) -> Result<PointDto, PointServiceError>;
    
    /// 获取测点详情
    async fn get_point(
        &self,
        user_id: Uuid,
        point_id: Uuid
    ) -> Result<PointDto, PointServiceError>;
    
    /// 查询测点列表
    async fn list_points(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        page: i64,
        size: i64
    ) -> Result<PagedPointDto, PointServiceError>;
    
    /// 更新测点
    async fn update_point(
        &self,
        user_id: Uuid,
        point_id: Uuid,
        entity: UpdatePointEntity
    ) -> Result<PointDto, PointServiceError>;
    
    /// 删除测点
    async fn delete_point(
        &self,
        user_id: Uuid,
        point_id: Uuid
    ) -> Result<(), PointServiceError>;
    
    /// 读取测点值
    async fn read_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid
    ) -> Result<PointValueDto, PointServiceError>;
    
    /// 写入测点值
    async fn write_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid,
        value: PointValue
    ) -> Result<(), PointServiceError>;
}

#[derive(Debug, thiserror::Error)]
pub enum PointServiceError {
    #[error("Not found")]
    NotFound,
    
    #[error("Access denied")]
    AccessDenied,
    
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("Read only point")]
    ReadOnlyPoint,
    
    #[error("Device not connected")]
    DeviceNotConnected,
    
    #[error("Internal error: {0}")]
    InternalError(String),
}
```

---

## 6. Handler层设计

### 6.1 Device Handler

```rust
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::entities::device::{CreateDeviceRequest, UpdateDeviceRequest};
use crate::services::device::{
    DeviceService, DeviceDto, PagedDeviceDto, CreateDeviceEntity, UpdateDeviceEntity, 
    DeviceServiceError,
};
use crate::services::point::{ListPointsQuery, PointDto, PagedPointDto};

type AppState = Arc<dyn DeviceService>;

/// POST /api/v1/workbenches/{workbench_id}/devices
pub async fn create_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(workbench_id): Path<Uuid>,
    Json(req): Json<CreateDeviceRequest>,
) -> Result<Json<ApiResponse<DeviceDto>>, AppError> {
    let entity = CreateDeviceEntity {
        workbench_id,
        name: req.name,
        protocol_type: req.protocol_type,
        parent_id: req.parent_id,
        protocol_params: req.protocol_params,
        manufacturer: req.manufacturer,
        model: req.model,
        sn: req.sn,
    };

    let device = handler.create_device(user_ctx.user_id, entity)
        .await
        .map_err(|e| match e {
            DeviceServiceError::NotFound => AppError::NotFound("Workbench not found".to_string()),
            DeviceServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceServiceError::ValidationError(msg) => AppError::BadRequest(msg),
            DeviceServiceError::CircularReference => AppError::BadRequest("Circular reference detected".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::created(device)))
}

/// GET /api/v1/workbenches/{workbench_id}/devices
pub async fn list_devices(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(workbench_id): Path<Uuid>,
    Query(query): Query<ListDevicesQuery>,
) -> Result<Json<ApiResponse<PagedDeviceDto>>, AppError> {
    let result = handler.list_devices(
        user_ctx.user_id,
        workbench_id,
        query.parent_id,
        query.page,
        query.size,
    )
    .await
    .map_err(|e| match e {
        DeviceServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
        _ => AppError::InternalError(e.to_string()),
    })?;

    Ok(Json(ApiResponse::success(result)))
}

/// GET /api/v1/devices/{id}
pub async fn get_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<DeviceDto>>, AppError> {
    let device = handler.get_device(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceServiceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(device)))
}

/// PUT /api/v1/devices/{id}
pub async fn update_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdateDeviceRequest>,
) -> Result<Json<ApiResponse<DeviceDto>>, AppError> {
    let entity = UpdateDeviceEntity {
        name: req.name,
        protocol_params: req.protocol_params,
        manufacturer: req.manufacturer,
        model: req.model,
        sn: req.sn,
        status: req.status,
    };

    let device = handler.update_device(user_ctx.user_id, id, entity)
        .await
        .map_err(|e| match e {
            DeviceServiceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceServiceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(device)))
}

/// DELETE /api/v1/devices/{id}
pub async fn delete_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    handler.delete_device(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceServiceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(StatusCode::NO_CONTENT)
}

#[derive(Debug, Deserialize)]
pub struct ListDevicesQuery {
    pub page: Option<i64>,
    pub size: Option<i64>,
    pub parent_id: Option<Uuid>,
}
```

### 6.2 Point Handler

```rust
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::entities::point::{CreatePointRequest, UpdatePointRequest, WritePointValueRequest};
use crate::services::point::{
    PointService, PointDto, PagedPointDto, CreatePointEntity, UpdatePointEntity,
    PointServiceError, PointValueDto,
};
use crate::drivers::PointValue;

type AppState = Arc<dyn PointService>;

/// POST /api/v1/devices/{device_id}/points
pub async fn create_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(device_id): Path<Uuid>,
    Json(req): Json<CreatePointRequest>,
) -> Result<Json<ApiResponse<PointDto>>, AppError> {
    let entity = CreatePointEntity {
        device_id,
        name: req.name,
        data_type: req.data_type,
        access_type: req.access_type,
        unit: req.unit,
        description: req.description,
        min_value: req.min_value,
        max_value: req.max_value,
        default_value: req.default_value,
    };

    let point = handler.create_point(user_ctx.user_id, entity)
        .await
        .map_err(|e| match e {
            PointServiceError::NotFound => AppError::NotFound("Device not found".to_string()),
            PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointServiceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::created(point)))
}

/// GET /api/v1/devices/{device_id}/points
pub async fn list_points(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(device_id): Path<Uuid>,
    Query(query): Query<ListPointsQuery>,
) -> Result<Json<ApiResponse<PagedPointDto>>, AppError> {
    let result = handler.list_points(
        user_ctx.user_id,
        device_id,
        query.page,
        query.size,
    )
    .await
    .map_err(|e| match e {
        PointServiceError::NotFound => AppError::NotFound("Device not found".to_string()),
        PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
        _ => AppError::InternalError(e.to_string()),
    })?;

    Ok(Json(ApiResponse::success(result)))
}

/// GET /api/v1/points/{id}
pub async fn get_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<PointDto>>, AppError> {
    let point = handler.get_point(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            PointServiceError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(point)))
}

/// PUT /api/v1/points/{id}
pub async fn update_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdatePointRequest>,
) -> Result<Json<ApiResponse<PointDto>>, AppError> {
    let entity = UpdatePointEntity {
        name: req.name,
        unit: req.unit,
        description: req.description,
        min_value: req.min_value,
        max_value: req.max_value,
        default_value: req.default_value,
        status: req.status,
    };

    let point = handler.update_point(user_ctx.user_id, id, entity)
        .await
        .map_err(|e| match e {
            PointServiceError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointServiceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(point)))
}

/// DELETE /api/v1/points/{id}
pub async fn delete_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    handler.delete_point(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            PointServiceError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(StatusCode::NO_CONTENT)
}

/// GET /api/v1/points/{id}/value
pub async fn read_point_value(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<PointValueDto>>, AppError> {
    let value = handler.read_point_value(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            PointServiceError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointServiceError::DeviceNotConnected => AppError::BadRequest("Device not connected".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(value)))
}

/// PUT /api/v1/points/{id}/value
pub async fn write_point_value(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<WritePointValueRequest>,
) -> Result<Json<ApiResponse<()>>, AppError> {
    handler.write_point_value(user_ctx.user_id, id, req.value)
        .await
        .map_err(|e| match e {
            PointServiceError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointServiceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointServiceError::ReadOnlyPoint => AppError::BadRequest("Point is read-only".to_string()),
            PointServiceError::DeviceNotConnected => AppError::BadRequest("Device not connected".to_string()),
            PointServiceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(())))
}

#[derive(Debug, Deserialize)]
pub struct ListPointsQuery {
    pub page: Option<i64>,
    pub size: Option<i64>,
}
```

---

## 7. 路由注册

```rust
/// 设备路由组
fn device_routes(
    device_service: Arc<dyn DeviceService>,
    point_service: Arc<dyn PointService>,
) -> Router {
    Router::new()
        // 设备路由
        .route("/", post(device::create_device))
        .route("/", get(device::list_devices))
        .route("/{id}", get(device::get_device))
        .route("/{id}", put(device::update_device))
        .route("/{id}", delete(device::delete_device))
        // 测点路由（嵌套在设备下）
        .route("/{device_id}/points", post(point::create_point))
        .route("/{device_id}/points", get(point::list_points))
        .with_state((device_service, point_service))
}

/// 测点路由组（独立路径）
fn point_routes(point_service: Arc<dyn PointService>) -> Router {
    Router::new()
        .route("/{id}", get(point::get_point))
        .route("/{id}", put(point::update_point))
        .route("/{id}", delete(point::delete_point))
        // 测点值路由（使用扁平路径，point_id唯一标识）
        .route("/{id}/value", get(point::read_point_value))
        .route("/{id}/value", put(point::write_point_value))
        .with_state(point_service)
}
```

---

## 8. 错误处理策略

### 8.1 错误码映射

| ServiceError | HTTP Status | Error Code |
|--------------|-------------|------------|
| NotFound | 404 | RESOURCE_NOT_FOUND |
| AccessDenied | 403 | ACCESS_DENIED |
| ValidationError | 400 | VALIDATION_ERROR |
| CircularReference | 400 | CIRCULAR_REFERENCE |
| ReadOnlyPoint | 400 | READ_ONLY_POINT |
| DeviceNotConnected | 400 | DEVICE_NOT_CONNECTED |
| InternalError | 500 | INTERNAL_ERROR |

### 8.2 循环引用检测

在创建设备或更新设备时，检测parent_id是否会导致循环引用：

```rust
/// 检查parent_id是否会导致循环引用
async fn check_circular_reference(
    &self,
    device_id: Uuid,
    new_parent_id: Uuid
) -> Result<bool, DeviceServiceError> {
    // 如果将设备A的parent设置为设备B，需要检查B是否在A的子树中
    let descendants = self.device_repo.find_all_descendant_ids(device_id).await?;
    Ok(descendants.contains(&new_parent_id))
}
```

---

## 9. 级联删除策略

### 9.1 删除设备时的级联操作

1. 获取设备的所有子设备ID（递归）
2. 获取所有子设备的测点ID
3. 删除所有测点
4. 删除所有子设备（递归）
5. 删除当前设备

```rust
async fn delete_device_cascade(
    &self,
    device_id: Uuid
) -> Result<(), DeviceServiceError> {
    // 1. 获取所有子孙设备ID
    let all_device_ids = self.get_all_descendant_ids(device_id);
    all_device_ids.push(device_id);
    
    // 2. 获取所有测点ID
    for device_id in &all_device_ids {
        let point_ids = self.point_repo.find_ids_by_device_id(*device_id).await?;
        // 3. 删除所有测点
        for point_id in point_ids {
            self.point_repo.delete(point_id).await?;
        }
    }
    
    // 4. 删除所有设备（从叶子到根）
    for device_id in all_device_ids.iter().rev() {
        self.device_repo.delete(*device_id).await?;
    }
    
    Ok(())
}
```

### 9.2 SQLite外键级联

数据库schema中已经配置了CASCADE：
```sql
CREATE TABLE devices (
    ...
    parent_id TEXT REFERENCES devices(id) ON DELETE CASCADE,
    ...
);

CREATE TABLE points (
    ...
    device_id TEXT REFERENCES devices(id) ON DELETE CASCADE,
    ...
);
```

---

## 10. 虚拟设备驱动集成

### 10.1 设备创建时注册到DeviceManager

```rust
impl DeviceServiceImpl {
    async fn create_device(
        &self,
        user_id: Uuid,
        entity: CreateDeviceEntity
    ) -> Result<DeviceDto, DeviceServiceError> {
        // ... 验证和创建逻辑 ...
        
        let device = Device::new(...);
        self.device_repo.create(&device).await?;
        
        // 如果是虚拟设备，注册到DeviceManager
        if device.protocol_type == ProtocolType::Virtual {
            let config = entity.protocol_params.unwrap_or_default();
            let driver = VirtualDriver::with_config(config)
                .map_err(|e| DeviceServiceError::ValidationError(e.to_string()))?;
            self.device_manager.register_device(device.id, driver);
        }
        
        Ok(device.into())
    }
}
```

### 10.2 测点值读写

```rust
impl PointServiceImpl {
    async fn read_point_value(
        &self,
        user_id: Uuid,
        point_id: Uuid
    ) -> Result<PointValueDto, PointServiceError> {
        let point = self.get_point_entity(point_id).await?;
        let device = self.get_device_entity(point.device_id).await?;
        
        // 获取设备驱动
        let driver_lock = self.device_manager.get_device(device.id)
            .ok_or(PointServiceError::DeviceNotConnected)?;
        
        let driver = driver_lock.read().unwrap();
        
        // 读取测点值
        let value = driver.read_point(point_id).await
            .map_err(|e| PointServiceError::InternalError(e.to_string()))?;
        
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
        value: PointValue
    ) -> Result<(), PointServiceError> {
        let point = self.get_point_entity(point_id).await?;
        
        // 检查访问类型
        if point.access_type == AccessType::RO {
            return Err(PointServiceError::ReadOnlyPoint);
        }
        
        let device = self.get_device_entity(point.device_id).await?;
        
        let driver_lock = self.device_manager.get_device(device.id)
            .ok_or(PointServiceError::DeviceNotConnected)?;
        
        let driver = driver_lock.read().unwrap();
        
        driver.write_point(point_id, value).await
            .map_err(|e| PointServiceError::InternalError(e.to_string()))?;
        
        Ok(())
    }
}
```

---

## 11. 验收标准映射

| 验收标准 | 实现内容 | 对应模块 |
|---------|---------|---------|
| 1. 实现PRD 2.1.4中的设备、测点相关API | 完整的设备CRUD和测点CRUD | DeviceHandler, PointHandler |
| 2. 读取虚拟设备测点返回模拟数据 | VirtualDriver.read_point集成 | PointService |
| 3. 设备支持嵌套创建 | parent_id树形结构支持 | DeviceRepository, DeviceService |

---

## 12. 依赖说明

### 12.1 新增依赖

无需新增依赖，使用现有依赖：
- sqlx: 数据库访问
- serde: 序列化
- uuid: UUID生成
- chrono: 时间处理
- thiserror: 错误处理
- async_trait: 异步trait支持

### 12.2 现有模块依赖

```
DeviceService ──> DeviceRepository (trait)
           ──> PointRepository (trait)
           ──> DeviceManager
           ──> WorkbenchRepository (验证所有权)

PointService ──> PointRepository (trait)
           ──> DeviceRepository (验证所有权)
           ──> DeviceManager
```

---

**文档结束**