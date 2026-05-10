# R2-S1-001-B HDF5 时序数据查询 API 详细设计文档

**版本**: 1.0  
**日期**: 2026-05-10  
**状态**: Draft → Approved  
**任务编号**: R2-S1-001-B  
**关联 PRD**: `log/release_2/prd.md`  

---

## 目录

1. [概述](#1-概述)
2. [API 端点设计](#2-api-端点设计)
3. [模块结构](#3-模块结构)
4. [HDF5 读取方案](#4-hdf5-读取方案)
5. [LTTB 降采样算法](#5-lttb-降采样算法)
6. [与现有服务集成](#6-与现有服务集成)
7. [错误处理策略](#7-错误处理策略)
8. [数据库查询验证](#8-数据库查询验证)
9. [附录](#9-附录)

---

## 1. 概述

### 1.1 设计目标

本文档为 **R2-S1-001-B** 任务（HDF5 时序数据查询 API）提供详细的实现级设计指导。该 API 允许已认证用户通过 RESTful 接口查询已完成试验的时序数据，支持：

- 按试验、设备、测点三级维度定位数据
- 按 Unix 时间戳毫秒范围过滤数据
- LTTB (Largest Triangle Three Buckets) 视觉保真降采样
- 返回标准化 JSON 响应，集成前端图表组件

### 1.2 设计约束

| 约束项 | 要求 |
|--------|------|
| 语言/框架 | Rust 1.75+ / Axum 0.7 |
| HDF5 库 | `hdf5 = "0.8"` |
| 数值计算 | `ndarray = "0.15.6"` |
| 最大时间窗口 | 30 天（2,592,000,000 毫秒） |
| 最大测点数 | 50 个/请求 |
| 降采样范围 | 2 ~ 10,000 点 |
| 默认降采样 | 1,000 点 |
| 认证方式 | JWT Bearer Token (RequireAuth) |

### 1.3 数据流概览

```
┌─────────────┐     POST /api/v1/experiments/{id}/data/query     ┌─────────────┐
│  前端客户端  │ ────────────────────────────────────────────────▶ │  Axum Handler │
│  (Flutter)   │                                                   │  (验证+路由)   │
└─────────────┘                                                   └──────┬──────┘
                                                                          │
                                                                          ▼
                                                               ┌─────────────────────┐
                                                               │ ExperimentDataService│
                                                               │   (业务逻辑编排)      │
                                                               └──────────┬──────────┘
                                                                          │
                                    ┌─────────────────────────────────────┼─────────────────────────────────────┐
                                    │                                     │                                     │
                                    ▼                                     ▼                                     ▼
                         ┌─────────────────┐               ┌─────────────────────┐               ┌─────────────────────┐
                         │ SQLite 元数据验证 │               │   HDF5 文件读取      │               │   LTTB 降采样引擎    │
                         │ (试验存在性/状态) │               │  (时序数据切片提取)   │               │  (视觉保真降采样)    │
                         └─────────────────┘               └─────────────────────┘               └─────────────────────┘
```

---

## 2. API 端点设计

### 2.1 端点定义

```
POST /api/v1/experiments/{id}/data/query
```

**认证**: 需要 JWT Bearer Token（`RequireAuth` 提取器强制执行）  
**Content-Type**: `application/json`  
**Accept**: `application/json`  

### 2.2 路径参数

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `id` | UUID string | 是 | 试验唯一标识符（URL path parameter） |

### 2.3 请求 DTO

#### 2.3.1 `ExperimentDataQueryRequest`

文件位置: `kayak-backend/src/models/dto/experiment_data_query.rs`

```rust
/// Experiment data query request
#[derive(Debug, Deserialize)]
pub struct ExperimentDataQueryRequest {
    /// Target device ID (UUID string)
    pub device_id: String,

    /// Target point IDs (at least one, max 50 unique)
    pub point_ids: Vec<String>,

    /// Start timestamp (Unix epoch milliseconds, inclusive)
    pub start_time: i64,

    /// End timestamp (Unix epoch milliseconds, inclusive)
    pub end_time: i64,

    /// Downsample target point count (optional, default 1000, range 2-10000)
    pub downsample: Option<usize>,
}
```

#### 2.3.2 字段校验规则

| 字段 | 类型 | 必填 | 校验规则 | 错误信息 |
|------|------|------|----------|----------|
| `device_id` | string | 是 | 非空字符串 | `"device_id cannot be empty"` |
| `point_ids` | string[] | 是 | 长度 >= 1，去重后 <= 50 | `"point_ids cannot be empty"` / `"Maximum 50 unique point_ids allowed"` |
| `start_time` | i64 | 是 | 任意有效 i64 | — |
| `end_time` | i64 | 是 | 任意有效 i64 | — |
| `downsample` | usize | 否 | 2 <= value <= 10,000，默认 1000 | `"downsample must be at least 2"` / `"downsample must not exceed 10000"` |

**时间窗口校验**:

```rust
// start_time 必须早于或等于 end_time
if start_time > end_time {
    return Err(AppError::BadRequest("start_time must be before end_time".to_string()));
}

// 时间窗口不超过 30 天
let time_window = end_time - start_time;
let max_window = 30_i64 * 24 * 3600 * 1000; // 2,592,000,000 ms
if time_window > max_window {
    return Err(AppError::BadRequest("Query time range must not exceed 30 days".to_string()));
}
```

#### 2.3.3 JSON 请求示例

```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000",
  "point_ids": [
    "550e8400-e29b-41d4-a716-446655440001",
    "550e8400-e29b-41d4-a716-446655440002"
  ],
  "start_time": 1714521600000,
  "end_time": 1714607999000,
  "downsample": 1000
}
```

### 2.4 响应 DTO

#### 2.4.1 `ApiResponse<ExperimentDataResponse>`

使用全局统一响应包装器 `ApiResponse<T>`（定义于 `core::error` 模块）：

```rust
#[derive(Debug, Serialize)]
pub struct ApiResponse<T> {
    pub code: u16,
    pub message: String,
    pub data: T,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timestamp: Option<String>,
}
```

成功响应结构：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "device_id": "550e8400-e29b-41d4-a716-446655440000",
    "time_range": {
      "start_time": 1714521600000,
      "end_time": 1714607999000,
      "actual_start": 1714521600000,
      "actual_end": 1714607985000
    },
    "points": [
      {
        "point_id": "550e8400-e29b-41d4-a716-446655440001",
        "point_name": "Temperature",
        "unit": "°C",
        "data_type": "float64",
        "timestamps": [1714521600000, 1714521601000, ...],
        "values": [25.3, 25.4, ...],
        "count": 1000
      }
    ],
    "total_samples": 86400,
    "returned_samples": 1000,
    "downsampled": true
  },
  "timestamp": "2026-05-10T08:30:00Z"
}
```

#### 2.4.2 核心响应结构定义

文件位置: `kayak-backend/src/models/dto/experiment_data_query.rs`

```rust
/// Experiment data query response
#[derive(Debug, Serialize)]
pub struct ExperimentDataResponse {
    /// Experiment ID (UUID string)
    pub experiment_id: String,

    /// Device ID queried
    pub device_id: String,

    /// Query time range metadata
    pub time_range: TimeRangeMeta,

    /// Data series for each requested point
    pub points: Vec<PointDataSeries>,

    /// Total raw data points before downsampling (sum across all points)
    pub total_samples: usize,

    /// Returned data points after downsampling (sum across all points)
    pub returned_samples: usize,

    /// Whether downsampling was applied to any point
    pub downsampled: bool,
}

/// Time range metadata
#[derive(Debug, Serialize)]
pub struct TimeRangeMeta {
    /// Requested start time (Unix millis)
    pub start_time: i64,
    /// Requested end time (Unix millis)
    pub end_time: i64,
    /// Actual start time of returned data
    pub actual_start: i64,
    /// Actual end time of returned data
    pub actual_end: i64,
}

/// Data series for a single point
#[derive(Debug, Serialize)]
pub struct PointDataSeries {
    /// Point ID
    pub point_id: String,
    /// Point name (from HDF5 group attribute if available)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub point_name: Option<String>,
    /// Unit (from HDF5 group attribute if available)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<String>,
    /// Data type (from HDF5 group attribute if available)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data_type: Option<String>,
    /// Timestamps (Unix epoch milliseconds)
    pub timestamps: Vec<i64>,
    /// Values
    pub values: Vec<f64>,
    /// Number of data points in this series
    pub count: usize,
}
```

#### 2.4.3 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `experiment_id` | string | 被查询的试验 UUID |
| `device_id` | string | 被查询的设备 UUID |
| `time_range.start_time` | i64 | 请求的起始时间（毫秒） |
| `time_range.end_time` | i64 | 请求的结束时间（毫秒） |
| `time_range.actual_start` | i64 | 实际返回数据的最早时间戳 |
| `time_range.actual_end` | i64 | 实际返回数据的最晚时间戳 |
| `points` | array | 每个测点的时序数据数组 |
| `points[].point_id` | string | 测点 UUID |
| `points[].point_name` | string? | 测点名称（来自 HDF5 属性） |
| `points[].unit` | string? | 单位（来自 HDF5 属性） |
| `points[].data_type` | string? | 数据类型（来自 HDF5 属性） |
| `points[].timestamps` | i64[] | 时间戳数组（毫秒） |
| `points[].values` | f64[] | 数值数组 |
| `points[].count` | usize | 该测点返回的数据点数 |
| `total_samples` | usize | 所有测点原始数据总量 |
| `returned_samples` | usize | 所有测点返回数据总量（降采样后） |
| `downsampled` | bool | 是否对任一测点执行了降采样 |

### 2.5 错误码映射表

| HTTP 状态码 | AppError 变体 | 触发条件 |
|-------------|---------------|----------|
| 400 | `BadRequest` | 试验 ID 格式无效、device_id 为空、point_ids 为空或超 50 个、时间范围反向、时间窗口超 30 天、downsample 超出范围 |
| 401 | `Unauthorized` | 缺少或无效 JWT Token |
| 403 | `Forbidden` | 用户无权访问该试验（user_id 不匹配） |
| 404 | `NotFound` | 试验不存在、试验数据文件不存在、设备不存在、测点不存在 |
| 409 | `Conflict` | 试验仍在运行或暂停中（状态为 Running/Paused） |
| 422 | `ValidationError` | 请求体 JSON 结构不符合 DTO 定义 |
| 500 | `InternalError` | HDF5 文件打开失败、数据集读取失败、数据格式损坏 |
| 502 | `ExternalServiceError` | 不适用（本端点无外部依赖） |
| 503 | `ServiceUnavailable` | 数据库连接池耗尽 |

---

## 3. 模块结构

### 3.1 新增/修改文件清单

#### 3.1.1 模型层 (Models)

| 文件路径 | 类型 | 说明 |
|----------|------|------|
| `src/models/dto/experiment_data_query.rs` | 新增 | 请求/响应 DTO 定义 |

#### 3.1.2 API 处理器层 (Handlers)

| 文件路径 | 类型 | 说明 |
|----------|------|------|
| `src/api/handlers/experiment_data.rs` | 新增 | `query_experiment_data` 处理器 |
| `src/api/handlers/mod.rs` | 修改 | 导出 `experiment_data` 模块 |

#### 3.1.3 路由层 (Routes)

| 文件路径 | 类型 | 说明 |
|----------|------|------|
| `src/api/routes.rs` | 修改 | 注册 `POST /api/v1/experiments/{id}/data/query` 路由 |

#### 3.1.4 服务层 (Services)

| 文件路径 | 类型 | 说明 |
|----------|------|------|
| `src/services/experiment_data/mod.rs` | 新增 | `ExperimentDataService` trait + `ExperimentDataServiceImpl` |
| `src/services/lttb.rs` | 新增 | LTTB 降采样算法实现 |
| `src/services/mod.rs` | 修改 | 导出 `experiment_data` 和 `lttb` 模块 |

#### 3.1.5 HDF5 服务扩展 (HDF5 Service)

| 文件路径 | 类型 | 说明 |
|----------|------|------|
| `src/services/hdf5/service.rs` | 修改（如需） | 扩展 `Hdf5Service` trait 以支持读取接口 |

### 3.2 模块依赖关系

```
kayak-backend/src/
├── models/
│   └── dto/
│       └── experiment_data_query.rs      ← DTO 定义
│
├── api/
│   ├── routes.rs                          ← 路由注册
│   └── handlers/
│       └── experiment_data.rs             ← HTTP Handler
│
└── services/
    ├── mod.rs                              ← 模块导出
    ├── experiment_data/
    │   └── mod.rs                          ← ExperimentDataService
    └── lttb.rs                             ← LTTB 算法
```

### 3.3 路由注册代码

在 `src/api/routes.rs` 的 `experiment_data_routes` 函数中注册：

```rust
/// 试验数据查询路由组
fn experiment_data_routes(
    experiment_data_service: Arc<dyn ExperimentDataService>,
) -> Router<()> {
    Router::new().nest(
        "/api/v1/experiments",
        Router::new()
            .route(
                "/{id}/data/query",
                post(experiment_data::query_experiment_data),
            )
            .with_state(experiment_data_service),
    )
}
```

服务实例化（在 `create_router` 函数中）：

```rust
// 创建试验数据查询服务
let experiment_repo_for_data = SqlxExperimentRepository::new(pool.clone());
let data_root = std::env::var("KAYAK_DATA_DIR")
    .map(PathBuf::from)
    .unwrap_or_else(|_| PathBuf::from("./data"));
let experiment_data_service: Arc<dyn ExperimentDataService> =
    Arc::new(ExperimentDataServiceImpl::new(
        Arc::new(experiment_repo_for_data),
        data_root,
    ));
```

---

## 4. HDF5 读取方案

### 4.1 文件定位策略

HDF5 文件遵循 **固定路径约定**：

```
{data_root}/experiments/{experiment_id}.h5
```

其中 `data_root` 由环境变量 `KAYAK_DATA_DIR` 控制，默认为 `./data`。

示例：
```
./data/experiments/550e8400-e29b-41d4-a716-446655440000.h5
```

### 4.2 HDF5 内部结构

根据现有架构设计，HDF5 文件内部采用以下层次结构：

```
/{experiment_id}.h5
├── /{device_id_1}                    ← 设备组
│   ├── /{point_id_1}                 ← 测点组
│   │   ├── timestamps  (Dataset: i64[N])
│   │   └── values      (Dataset: f64[N])
│   │
│   └── /{point_id_2}
│       ├── timestamps  (Dataset: i64[M])
│       └── values      (Dataset: f64[M])
│
└── /{device_id_2}
    └── ...
```

**关键约定**：
- 每个测点对应一个 HDF5 Group，路径为 `/{device_id}/{point_id}`
- 每个测点 Group 内包含两个 Dataset：
  - `timestamps`: `i64` 类型数组，存储 Unix 毫秒时间戳
  - `values`: `f64` 类型数组，存储采样值
- 两个 Dataset 的长度必须严格一致（由写入时校验保证）
- 可选 Group 属性：`name`（测点名）、`unit`（单位）、`data_type`（数据类型）

### 4.3 数据集读取流程

#### 4.3.1 完整读取流程

```rust
fn read_point_data(
    &self,
    file_path: &Path,
    device_id: &str,
    point_id: &str,
    start_time: i64,
    end_time: i64,
) -> Result<(Vec<i64>, Vec<f64>, Option<String>, Option<String>, Option<String>), AppError> {
    // Step 1: 打开 HDF5 文件
    let file = hdf5::File::open(file_path).map_err(|e| {
        AppError::InternalError(format!("Failed to open HDF5 file: {}", e))
    })?;

    // Step 2: 定位测点组
    let group_path = format!("/{}/{}", device_id, point_id);
    let group = file.group(&group_path).map_err(|_| {
        AppError::NotFound(format!(
            "Point '{}' not found in device '{}'",
            point_id, device_id
        ))
    })?;

    // Step 3: 读取 timestamps 数据集
    let timestamps_ds = group.dataset("timestamps").map_err(|_| {
        AppError::InternalError("timestamps dataset not found".to_string())
    })?;

    // Step 4: 读取 values 数据集
    let values_ds = group.dataset("values").map_err(|_| {
        AppError::InternalError("values dataset not found".to_string())
    })?;

    let all_timestamps: Vec<i64> = timestamps_ds.read_raw().map_err(|e| {
        AppError::InternalError(format!("Failed to read timestamps: {}", e))
    })?;

    let all_values: Vec<f64> = values_ds.read_raw().map_err(|e| {
        AppError::InternalError(format!("Failed to read values: {}", e))
    })?;

    // Step 5: 长度一致性校验
    if all_timestamps.len() != all_values.len() {
        return Err(AppError::InternalError(
            "Dataset format error: timestamps and values length mismatch".to_string(),
        ));
    }

    // Step 6: 时间范围过滤（二分查找定位索引）
    let start_idx = all_timestamps
        .iter()
        .position(|&t| t >= start_time)
        .unwrap_or(all_timestamps.len());

    let end_idx = all_timestamps
        .iter()
        .rposition(|&t| t <= end_time)
        .map(|i| i + 1)
        .unwrap_or(0);

    if start_idx >= end_idx {
        return Ok((vec![], vec![], None, None, None));
    }

    let timestamps = all_timestamps[start_idx..end_idx].to_vec();
    let values = all_values[start_idx..end_idx].to_vec();

    // Step 7: 读取可选属性
    let point_name = Self::read_string_attr(&group, "name");
    let unit = Self::read_string_attr(&group, "unit");
    let data_type = Self::read_string_attr(&group, "data_type");

    Ok((timestamps, values, point_name, unit, data_type))
}
```

#### 4.3.2 时间范围过滤算法

使用线性扫描定位起始和结束索引（适用于已排序的时序数据）：

```rust
// 查找第一个 >= start_time 的索引
let start_idx = all_timestamps
    .iter()
    .position(|&t| t >= start_time)
    .unwrap_or(all_timestamps.len());

// 查找最后一个 <= end_time 的索引，然后 +1 作为结束边界（Rust 切片语义）
let end_idx = all_timestamps
    .iter()
    .rposition(|&t| t <= end_time)
    .map(|i| i + 1)
    .unwrap_or(0);
```

**复杂度分析**：
- 时间复杂度: O(N) 单次扫描（N 为测点总数据量）
- 空间复杂度: O(M)（M 为过滤后数据量，M <= N）
- 数据已按时间戳升序排列（由写入端保证），无需排序

**边界情况处理**：

| 场景 | start_idx | end_idx | 处理结果 |
|------|-----------|---------|----------|
| 所有数据在范围前 | `all_timestamps.len()` | 0 | `start_idx >= end_idx` → 返回空数组 |
| 所有数据在范围后 | 0 | 0 | `start_idx >= end_idx` → 返回空数组 |
| 部分数据在范围内 | > 0 | < N | 返回切片 `[start_idx..end_idx]` |
| 全部数据在范围内 | 0 | N | 返回全部数据 |

### 4.4 HDF5 属性读取

测点元数据通过 HDF5 Group 属性存储：

```rust
/// Attempt to read a string attribute from an HDF5 group
fn read_string_attr(group: &hdf5::Group, name: &str) -> Option<String> {
    group.attr(name).ok().and_then(|attr| {
        attr.read_scalar::<hdf5::types::VarLenUnicode>()
            .ok()
            .map(|s| s.to_string())
    })
}
```

**属性设计**：

| 属性名 | 类型 | 说明 | 可选 |
|--------|------|------|------|
| `name` | `VarLenUnicode` | 测点显示名称 | 是 |
| `unit` | `VarLenUnicode` | 物理单位 | 是 |
| `data_type` | `VarLenUnicode` | 数据类型描述 | 是 |

属性不存在时返回 `None`，响应 JSON 中通过 `#[serde(skip_serializing_if = "Option::is_none")]` 省略该字段。

---

## 5. LTTB 降采样算法

### 5.1 算法概述

**LTTB (Largest Triangle Three Buckets)** 是一种视觉保真降采样算法，由 Sveinn Steinarsson 于 2013 年提出。该算法在显著减少数据点数量的同时，最大程度保留原始数据的视觉特征（峰值、谷值、拐点等）。

**适用场景**：
- 原始数据量远大于前端图表像素宽度时
- 需要快速预览大规模时序数据时
- 网络传输带宽受限时

### 5.2 算法原理

1. **分桶 (Bucketing)**：将数据（除去首尾两点）分成 `threshold - 2` 个桶
2. **选点 (Point Selection)**：对每个桶，计算桶内每一点与前一个已选点、下一桶平均值构成的三角形面积
3. **最大面积点**：选择使三角形面积最大的点作为该桶的代表点
4. **保边**：始终保留首尾两点

三角形面积公式（叉积法，省略 0.5 系数）：

```
Area = |(ax - cx) * (by - ay) - (ax - bx) * (cy - ay)|
```

其中：
- `(ax, ay)`：前一个已选点
- `(bx, by)`：当前候选点
- `(cx, cy)`：下一桶的平均点（取中点近似）

### 5.3 Rust 实现

文件位置: `kayak-backend/src/services/lttb.rs`

```rust
//! LTTB (Largest Triangle Three Buckets) downsampling algorithm
//!
//! A visual-preserving time-series data downsampling algorithm.
//!
//! # Algorithm
//! - Divide data into `threshold` buckets
//! - Select points that maximize the triangle area with the previous selected point
//!   and the average of the next bucket
//! - Always preserve first and last points
//!
//! # Boundary Conditions
//! - If N < threshold: return all N points (no downsampling)
//! - If N == threshold: return all N points
//! - If N > threshold: return exactly `threshold` points

/// LTTB downsampler
pub struct LttbDownsampler;

impl LttbDownsampler {
    /// Execute LTTB downsampling
    ///
    /// # Arguments
    /// * `timestamps` - Array of timestamps (i64)
    /// * `values` - Array of values (f64)
    /// * `threshold` - Target number of points to return
    ///
    /// # Returns
    /// Tuple of (sampled_timestamps, sampled_values)
    pub fn downsample(
        timestamps: &[i64],
        values: &[f64],
        threshold: usize,
    ) -> (Vec<i64>, Vec<f64>) {
        let n = timestamps.len();

        // ===== 边界条件 1: 数据量不足，无需降采样 =====
        if n <= threshold {
            return (timestamps.to_vec(), values.to_vec());
        }

        let mut sampled_ts = Vec::with_capacity(threshold);
        let mut sampled_vals = Vec::with_capacity(threshold);

        // 桶大小计算（排除首尾两点后的数据分成 threshold - 2 桶）
        let bucket_size = (n - 2) as f64 / (threshold - 2) as f64;

        // ===== 第 1 步: 保留首点 =====
        sampled_ts.push(timestamps[0]);
        sampled_vals.push(values[0]);

        // 跟踪上一个已选点的原始索引
        let mut last_selected_original_idx: usize = 0;

        // ===== 第 2 步: 处理中间桶 =====
        for i in 1..(threshold - 1) {
            // 当前桶边界
            let bucket_start = ((i - 1) as f64 * bucket_size).floor() as usize + 1;
            let bucket_end = (i as f64 * bucket_size).floor() as usize + 1;
            let bucket_end = bucket_end.min(n - 1);

            // 下一桶（用于计算平均点/三角形顶点）
            let next_bucket_start = bucket_end;
            let next_bucket_end = ((i + 1) as f64 * bucket_size).floor() as usize + 1;
            let next_bucket_end = next_bucket_end.min(n - 1);

            // 下一桶的平均点（取中点作为三角形顶点）
            let avg_idx = next_bucket_start + (next_bucket_end - next_bucket_start) / 2;
            let avg_x = timestamps[avg_idx] as f64;
            let avg_y = values[avg_idx];

            // 在当前桶中寻找使三角形面积最大的点
            let mut max_area = -1.0;
            let mut max_idx = bucket_start;

            let last_x = timestamps[last_selected_original_idx] as f64;
            let last_y = values[last_selected_original_idx];

            for j in bucket_start..bucket_end {
                let area = Self::triangle_area(
                    last_x, last_y,
                    timestamps[j] as f64, values[j],
                    avg_x, avg_y,
                );
                if area > max_area {
                    max_area = area;
                    max_idx = j;
                }
            }

            sampled_ts.push(timestamps[max_idx]);
            sampled_vals.push(values[max_idx]);
            last_selected_original_idx = max_idx;
        }

        // ===== 第 3 步: 保留尾点 =====
        sampled_ts.push(timestamps[n - 1]);
        sampled_vals.push(values[n - 1]);

        (sampled_ts, sampled_vals)
    }

    /// Calculate triangle area using cross product formula
    ///
    /// Area = 0.5 * |cross(AB, AC)|
    ///      = 0.5 * |(ax-cx)*(by-ay) - (ax-bx)*(cy-ay)|
    ///
    /// We omit the 0.5 factor since we only compare relative areas.
    #[inline]
    fn triangle_area(ax: f64, ay: f64, bx: f64, by: f64, cx: f64, cy: f64) -> f64 {
        ((ax - cx) * (by - ay) - (ax - bx) * (cy - ay)).abs()
    }
}
```

### 5.4 边界条件详细说明

| 条件 | 输入 | 输出 | 说明 |
|------|------|------|------|
| 空数据 | `N = 0` | 空数组 | 直接返回空 |
| 单点数据 | `N = 1` | 保留 1 点 | 无法构成三角形，保留原始点 |
| 少量数据 | `N < threshold` | 全部 N 点 | 数据量已小于目标，无需降采样 |
| 刚好阈值 | `N == threshold` | 全部 N 点 | 无需降采样 |
| 常规降采样 | `N > threshold` | 恰好 `threshold` 点 | 首点 + (threshold-2) 中间点 + 尾点 |
| 最小阈值 | `threshold = 2` | 2 点 | 仅保留首尾两点 |

### 5.5 性能特征

| 指标 | 值 | 说明 |
|------|-----|------|
| 时间复杂度 | O(N) | N 为原始数据点数，单次线性遍历 |
| 空间复杂度 | O(threshold) | 输出缓冲区大小 |
| 数值稳定性 | 高 | 仅使用加减乘除，无除零风险 |
| 并发安全 | 是 | 纯函数，无共享状态 |

### 5.6 单元测试覆盖

```rust
#[cfg(test)]
mod tests {
    use super::*;

    /// 测试: 数据量小于阈值时不降采样
    #[test]
    fn test_lttb_no_downsample_n_less_than_threshold() {
        let ts = vec![1_i64, 2, 3, 4, 5];
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts, ts);
        assert_eq!(svals, vals);
    }

    /// 测试: 数据量等于阈值时不降采样
    #[test]
    fn test_lttb_no_downsample_n_equals_threshold() {
        let ts = vec![1_i64, 2, 3, 4, 5];
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 5);
        assert_eq!(sts, ts);
        assert_eq!(svals, vals);
    }

    /// 测试: 降采样后返回恰好 threshold 个点
    #[test]
    fn test_lttb_downsample_returns_exact_threshold() {
        let ts: Vec<i64> = (0..100).map(|i| i as i64).collect();
        let vals: Vec<f64> = (0..100).map(|i| i as f64).collect();
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts.len(), 10);
        assert_eq!(svals.len(), 10);
    }

    /// 测试: 始终保留首尾两点
    #[test]
    fn test_lttb_preserves_first_and_last() {
        let ts: Vec<i64> = (0..100).map(|i| i as i64 * 1000).collect();
        let vals: Vec<f64> = (0..100).map(|i| (i as f64).sin()).collect();
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts.first(), Some(&ts[0]));
        assert_eq!(sts.last(), Some(&ts[99]));
        assert_eq!(svals.first(), Some(&vals[0]));
        assert_eq!(svals.last(), Some(&vals[99]));
    }

    /// 测试: 最小阈值 (2) 仅保留首尾
    #[test]
    fn test_lttb_minimum_threshold() {
        let ts = vec![1_i64, 2, 3, 4, 5];
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 2);
        assert_eq!(sts.len(), 2);
        assert_eq!(svals.len(), 2);
        assert_eq!(sts[0], 1);
        assert_eq!(sts[1], 5);
    }

    /// 测试: 空输入
    #[test]
    fn test_lttb_empty_input() {
        let ts: Vec<i64> = vec![];
        let vals: Vec<f64> = vec![];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert!(sts.is_empty());
        assert!(svals.is_empty());
    }

    /// 测试: 单点输入
    #[test]
    fn test_lttb_single_point() {
        let ts = vec![42_i64];
        let vals = vec![2.71];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts.len(), 1);
        assert_eq!(svals.len(), 1);
        assert_eq!(sts[0], 42);
        assert_eq!(svals[0], 2.71);
    }
}
```

---

## 6. 与现有服务集成

### 6.1 架构层次关系

本功能涉及以下现有服务/组件的协作：

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        API Handler Layer                                     │
│  experiment_data::query_experiment_data()                                    │
│      ├── 解析 experiment_id (URL param)                                      │
│      ├── 校验 request body (ExperimentDataQueryRequest)                      │
│      └── 调用 ExperimentDataService                                          │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                     ExperimentDataService (Trait)                            │
│  query_experiment_data(exp_id, request, user_id) -> Result<Response>        │
│      ├── 数据库: 验证试验存在性与状态                                         │
│      ├── 权限:  验证用户所有权                                                │
│      ├── HDF5:  读取原始时序数据                                              │
│      └── LTTB:  执行降采样（如需要）                                          │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         │                         │                         │
         ▼                         ▼                         ▼
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│ ExperimentRepository│    │ hdf5::File (direct) │    │ LttbDownsampler     │
│ (sqlx/SQLite)   │    │ (hdf5 crate)        │    │ (pure function)     │
│                 │    │                     │    │                     │
│ find_by_id()    │    │ open()              │    │ downsample()        │
│                 │    │ group()             │    │                     │
│                 │    │ dataset()           │    │                     │
│                 │    │ read_raw()          │    │                     │
└─────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### 6.2 与 `Hdf5Service` 的关系

**当前设计决策**：直接调用 `hdf5` crate API 而非通过 `Hdf5Service` trait。

原因分析：
1. `Hdf5Service` trait（`src/services/hdf5/service.rs`）当前接口面向**写入场景**设计：
   - `create_file` / `open_file` / `close_file`
   - `write_timeseries`
   - `read_dataset`（仅返回 `Vec<f64>`，缺少时间戳和元数据）
   - `get_dataset_shape`

2. 本查询场景需要**细粒度的读取能力**：
   - 按时间范围切片读取（非全量读取）
   - 同时读取 `timestamps` 和 `values` 两个数据集
   - 读取 Group 属性（`name`, `unit`, `data_type`）

3. 直接调用 `hdf5::File` 避免通过 `Hdf5Service` trait 增加不必要的抽象层，减少一次内存拷贝和 trait object 分发开销。

**未来扩展建议**：
若后续有多个读取场景，可考虑扩展 `Hdf5Service` trait：

```rust
#[async_trait]
pub trait Hdf5Service: Send + Sync {
    // ... 现有接口 ...

    /// NEW: 读取时序数据切片
    async fn read_timeseries_slice(
        &self,
        file_path: &Path,
        device_id: &str,
        point_id: &str,
        start_time: i64,
        end_time: i64,
    ) -> Result<TimeseriesSlice, Hdf5Error>;
}
```

### 6.3 服务实现代码结构

```rust
pub struct ExperimentDataServiceImpl {
    experiment_repo: Arc<dyn ExperimentRepository>,
    data_root: PathBuf,
}

impl ExperimentDataServiceImpl {
    pub fn new(experiment_repo: Arc<dyn ExperimentRepository>, data_root: PathBuf) -> Self {
        Self { experiment_repo, data_root }
    }

    fn get_hdf5_path(&self, experiment_id: Uuid) -> PathBuf {
        self.data_root
            .join("experiments")
            .join(format!("{}.h5", experiment_id))
    }

    fn read_point_data(...) -> Result<...> { /* HDF5 读取逻辑 */ }
    fn read_string_attr(...) -> Option<String> { /* 属性读取 */ }
}

#[async_trait]
impl ExperimentDataService for ExperimentDataServiceImpl {
    async fn query_experiment_data(...) -> Result<ExperimentDataResponse, AppError> {
        // 1. 数据库验证
        // 2. 权限检查
        // 3. 状态检查
        // 4. HDF5 文件检查
        // 5. 逐测点读取 + 降采样
        // 6. 组装响应
    }
}
```

---

## 7. 错误处理策略

### 7.1 错误分层模型

采用三层错误转换模型：

```
底层错误                    中层错误                      顶层错误
(Layer 1)                  (Layer 2)                    (Layer 3)
┌──────────────┐          ┌──────────────────┐         ┌─────────────┐
│ hdf5::Error  │          │ AppError::NotFound│         │ HTTP 404    │
│ sqlx::Error  │ ──────▶  │ AppError::BadRequest│ ────▶ │ HTTP 400    │
│ io::Error    │  (From)  │ AppError::InternalError│ ──▶ │ HTTP 500    │
│ ...          │          │ ...              │         │ ...         │
└──────────────┘          └──────────────────┘         └─────────────┘
     │                           │                           │
     │                           │                           │
     ▼                           ▼                           ▼
  库内部错误                应用统一错误类型            Axum IntoResponse
```

### 7.2 错误转换实现

#### 7.2.1 `sqlx::Error` → `AppError`

已存在于 `core::error.rs`：

```rust
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => AppError::NotFound("Resource not found".to_string()),
            sqlx::Error::Database(db_err) => {
                if db_err.is_unique_violation() {
                    AppError::Conflict("Resource already exists".to_string())
                } else {
                    AppError::DatabaseError(db_err.to_string())
                }
            }
            sqlx::Error::PoolTimedOut => AppError::ServiceUnavailable,
            sqlx::Error::PoolClosed => AppError::ServiceUnavailable,
            _ => AppError::DatabaseError(err.to_string()),
        }
    }
}
```

#### 7.2.2 HDF5 错误 → `AppError`

在服务层直接映射：

```rust
let file = hdf5::File::open(&hdf5_path).map_err(|e| {
    AppError::InternalError(format!("Failed to open HDF5 file: {}", e))
})?;
```

#### 7.2.3 服务层显式错误映射

```rust
// 试验不存在
let experiment = self.experiment_repo
    .find_by_id(experiment_id)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?
    .ok_or_else(|| AppError::NotFound(format!("Experiment '{}' not found", experiment_id)))?;

// 权限不足
if experiment.user_id != user_id {
    return Err(AppError::Forbidden("Access denied to this experiment".to_string()));
}

// 试验仍在运行
if matches!(experiment.status, ExperimentStatus::Running | ExperimentStatus::Paused) {
    return Err(AppError::Conflict(format!(
        "Experiment is still running (status: {:?})",
        experiment.status
    )));
}

// 数据文件不存在
if !hdf5_path.exists() {
    return Err(AppError::NotFound("Experiment data file not found".to_string()));
}

// 设备不存在
if file.group(&device_group_path).is_err() {
    return Err(AppError::NotFound(format!(
        "Device '{}' not found in experiment",
        request.device_id
    )));
}
```

### 7.3 错误响应格式

统一错误响应（由 `AppError::into_response()` 自动生成）：

```json
// 400 Bad Request
{
  "code": 400,
  "message": "Bad request: start_time must be before end_time",
  "timestamp": "2026-05-10T08:30:00Z"
}

// 404 Not Found
{
  "code": 404,
  "message": "Resource not found: Experiment '550e8400...' not found",
  "timestamp": "2026-05-10T08:30:00Z"
}

// 422 Validation Error
{
  "code": 422,
  "message": "Validation error",
  "details": [
    {"field": "point_ids", "message": "cannot be empty"}
  ],
  "timestamp": "2026-05-10T08:30:00Z"
}

// 500 Internal Server Error
{
  "code": 500,
  "message": "Internal server error: Failed to open HDF5 file: ...",
  "timestamp": "2026-05-10T08:30:00Z"
}
```

### 7.4 日志记录策略

利用 `tracing` crate 进行结构化日志：

```rust
// 服务端错误（5xx）自动记录 error! 级别日志
if status.is_server_error() {
    error!(error = %self, "Server error occurred");
}

// 客户端错误（4xx）记录 debug! 级别日志
else {
    tracing::debug!(error = %self, "Client error occurred");
}
```

---

## 8. 数据库查询验证

### 8.1 试验状态验证流程

在允许查询 HDF5 数据之前，必须验证试验的元数据状态：

```
┌─────────────────┐
│  接收查询请求    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Step 1: 查询 SQLite 试验记录         │
│ SELECT * FROM experiments WHERE id = ?│
└────────┬────────────────────────────┘
         │
    ┌────┴────┐
    │ 记录存在? │
    └────┬────┘
   否 /  \ 是
      /    \
     ▼      ▼
┌────────┐  ┌─────────────────────────────┐
│ 404    │  │ Step 2: 验证所有权            │
│ NotFound│  │ experiment.user_id == user_id?│
└────────┘  └─────────────┬───────────────┘
                    ┌─────┴─────┐
                    │ 用户匹配?  │
                    └─────┬─────┘
                   否 /   \ 是
                      /     \
                     ▼       ▼
               ┌────────┐  ┌──────────────────────────────┐
               │ 403    │  │ Step 3: 验证试验状态            │
               │ Forbidden│  │ status ∈ {Idle, Loaded, Completed, Error}│
               └────────┘  └──────────────┬───────────────┘
                                    ┌─────┴─────┐
                                    │ 状态允许?  │
                                    └─────┬─────┘
                                   否 /   \ 是
                                      /     \
                                     ▼       ▼
                               ┌────────┐  ┌────────────────────────────┐
                               │ 409    │  │ Step 4: 检查 HDF5 文件存在性  │
                               │ Conflict│  │ {data_root}/experiments/{id}.h5│
                               └────────┘  └─────────────┬──────────────┘
                                                    ┌─────┴─────┐
                                                    │ 文件存在?  │
                                                    └─────┬─────┘
                                                   否 /   \ 是
                                                      /     \
                                                     ▼       ▼
                                               ┌────────┐  ┌──────────┐
                                               │ 404    │  │ 继续执行  │
                                               │ NotFound│  │ HDF5 读取 │
                                               └────────┘  └──────────┘
```

### 8.2 SQL 查询定义

#### 8.2.1 试验记录查询

```rust
// ExperimentRepository trait 方法
async fn find_by_id(&self, id: Uuid) -> Result<Option<Experiment>, sqlx::Error>;
```

对应 SQL（由 `sqlx::query_as!` 生成）：

```sql
SELECT id, method_id, user_id, parameters, status, started_at, ended_at, created_at
FROM experiments
WHERE id = $1;
```

#### 8.2.2 试验状态枚举

```rust
#[derive(Debug, Clone, PartialEq, sqlx::Type)]
#[sqlx(rename_all = "snake_case")]
pub enum ExperimentStatus {
    Idle,
    Loaded,
    Running,
    Paused,
    Completed,
    Error,
}
```

**允许查询的状态**：`Idle`, `Loaded`, `Completed`, `Error`  
**禁止查询的状态**：`Running`, `Paused`

原因：运行中和暂停中的试验数据可能被缓冲区并发写入，读取可能导致数据不一致或文件锁定冲突。

### 8.3 数据库实体结构

```rust
pub struct Experiment {
    pub id: Uuid,
    pub method_id: Option<Uuid>,
    pub user_id: Uuid,
    pub parameters: serde_json::Value,
    pub status: ExperimentStatus,
    pub started_at: Option<chrono::DateTime<chrono::Utc>>,
    pub ended_at: Option<chrono::DateTime<chrono::Utc>>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}
```

### 8.4 验证代码实现

```rust
// Step 1: 查找试验
let experiment = self
    .experiment_repo
    .find_by_id(experiment_id)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?
    .ok_or_else(|| AppError::NotFound(format!("Experiment '{}' not found", experiment_id)))?;

// Step 2: 验证所有权
if experiment.user_id != user_id {
    return Err(AppError::Forbidden(
        "Access denied to this experiment".to_string(),
    ));
}

// Step 3: 检查试验状态
if matches!(
    experiment.status,
    ExperimentStatus::Running | ExperimentStatus::Paused
) {
    return Err(AppError::Conflict(format!(
        "Experiment is still running (status: {:?})",
        experiment.status
    )));
}
```

---

## 9. 附录

### 9.1 依赖清单

```toml
[dependencies]
# 已有依赖
hdf5 = "0.8"
ndarray = "0.15.6"
async-trait = "0.1"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
uuid = { version = "1.6", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
axum = "0.7"
tokio = { version = "1.35", features = ["full"] }
sqlx = { version = "0.7", features = ["sqlite", "runtime-tokio", "uuid", "chrono", "json"] }
tracing = "0.1"
thiserror = "1.0"
```

### 9.2 完整请求/响应示例

#### 请求

```http
POST /api/v1/experiments/550e8400-e29b-41d4-a716-446655440000/data/query HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "device_id": "660e8400-e29b-41d4-a716-446655440001",
  "point_ids": [
    "770e8400-e29b-41d4-a716-446655440001",
    "770e8400-e29b-41d4-a716-446655440002"
  ],
  "start_time": 1714521600000,
  "end_time": 1714607999000,
  "downsample": 1000
}
```

#### 成功响应 (200 OK)

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "code": 200,
  "message": "success",
  "data": {
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "device_id": "660e8400-e29b-41d4-a716-446655440001",
    "time_range": {
      "start_time": 1714521600000,
      "end_time": 1714607999000,
      "actual_start": 1714521600000,
      "actual_end": 1714607985000
    },
    "points": [
      {
        "point_id": "770e8400-e29b-41d4-a716-446655440001",
        "point_name": "Temperature",
        "unit": "°C",
        "data_type": "float64",
        "timestamps": [1714521600000, 1714521601000, 1714521602000],
        "values": [25.3, 25.4, 25.5],
        "count": 3
      },
      {
        "point_id": "770e8400-e29b-41d4-a716-446655440002",
        "point_name": "Pressure",
        "unit": "kPa",
        "data_type": "float64",
        "timestamps": [1714521600000, 1714521601000, 1714521602000],
        "values": [101.325, 101.330, 101.335],
        "count": 3
      }
    ],
    "total_samples": 172800,
    "returned_samples": 2000,
    "downsampled": true
  },
  "timestamp": "2026-05-10T08:30:00Z"
}
```

#### 错误响应示例 (409 Conflict)

```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "code": 409,
  "message": "Conflict: Experiment is still running (status: Running)",
  "timestamp": "2026-05-10T08:30:00Z"
}
```

### 9.3 时区处理说明

- 所有时间戳统一使用 **Unix Epoch Milliseconds**（自 1970-01-01T00:00:00Z 起的毫秒数）
- 前端负责将本地时区时间转换为 UTC 毫秒时间戳
- 后端不执行任何时区转换，直接按数值比较
- 响应中的 `timestamp` 字段使用 RFC 3339 格式（UTC）

### 9.4 性能优化建议

1. **HDF5 数据集切片**: 当前实现读取完整数据集后内存切片。对于超大数据集（>100MB），应考虑使用 HDF5 hyperslab 选择进行磁盘级切片，减少内存占用。

2. **连接池复用**: `hdf5::File` 打开操作较昂贵，可考虑在 `ExperimentDataServiceImpl` 中引入文件句柄缓存（参考 `Hdf5ServiceImpl` 的 `file_handles: RwLock<HashMap<PathBuf, hdf5::File>>` 模式）。

3. **并行读取多测点**: 多个 `point_id` 的读取相互独立，可使用 `tokio::task::spawn_blocking` + `futures::future::join_all` 并行化。

4. **LTTB 提前截断**: 若已知时间范围后的数据量仍远超阈值，可先执行粗略时间过滤，再执行 LTTB。

### 9.5 安全注意事项

1. **路径遍历防护**: `experiment_id` 经 UUID 解析后使用，天然防止路径遍历。但 `device_id` 和 `point_id` 直接拼接到 HDF5 组路径中，需确保这些值来自可信来源（已由数据库验证保证）。

2. **资源限制**: 通过 `downsample` 上限（10,000）、`point_ids` 上限（50）、时间窗口上限（30 天）防止极端请求导致内存溢出。

3. **并发读取安全**: HDF5 1.10+ 支持单文件多读取者并发（SWMR 模式）。当前 `hdf5 = "0.8"` crate 依赖系统 HDF5 库版本，生产环境应确保 HDF5 库 >= 1.10。

---

*文档结束*
