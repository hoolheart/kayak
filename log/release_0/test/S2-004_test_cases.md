# S2-004: 试验数据查询API - 测试用例文档

**任务ID**: S2-004  
**任务名称**: 试验数据查询API (Experiment Data Query API)  
**文档版本**: 1.0  
**创建日期**: 2026-03-28  
**测试类型**: 单元测试、集成测试  
**技术栈**: Rust / Axum / sqlx / tokio / tempfile  
**依赖任务**: S2-002 (Experiment Model), S2-003 (Time-series Buffer)

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-004 任务的所有功能测试，包括：
1. **试验列表API** - 分页查询、筛选、排序
2. **试验详情API** - 获取单个试验完整信息
3. **测点历史数据API** - 时间范围过滤、历史数据查询
4. **数据文件下载API** - HDF5文件下载、完整性校验

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. GET /api/v1/points/{id}/history 支持时间过滤 | TC-HIST-001 ~ TC-HIST-010 | Integration |
| 2. 试验列表支持分页 | TC-EXP-API-001 ~ TC-EXP-API-010 | Integration |
| 3. 数据文件可下载 | TC-DOWN-001 ~ TC-DOWN-008 | Integration |

### 1.3 API 端点定义

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/experiments | 列出试验（分页） |
| GET | /api/v1/experiments/{id} | 获取试验详情 |
| GET | /api/v1/points/{id}/history | 获取测点历史数据 |
| GET | /api/v1/experiments/{id}/data-file | 下载试验数据文件 |

### 1.4 测试数据模型

#### Experiment 实体
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Experiment {
    pub id: Uuid,
    pub user_id: Uuid,
    pub method_id: Option<Uuid>,
    pub name: String,
    pub description: Option<String>,
    pub status: ExperimentStatus,
    pub started_at: Option<DateTime<Utc>>,
    pub ended_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
```

#### Point History 响应
```rust
#[derive(Debug, Serialize, Deserialize)]
pub struct PointHistoryResponse {
    pub point_id: Uuid,
    pub channel: String,
    pub data: Vec<TimeSeriesDataPoint>,
    pub start_time: DateTime<Utc>,
    pub end_time: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TimeSeriesDataPoint {
    pub timestamp: i64,  // nanoseconds
    pub value: f64,
}
```

---

## 2. 试验列表API测试

### TC-EXP-API-001: 列出试验-默认分页

```rust
#[tokio::test]
async fn test_list_experiments_default_pagination() {
    // Setup: 创建测试服务器和客户端
    let (app, user_id) = setup_test_app().await;
    
    // 创建多个试验
    for i in 0..25 {
        create_test_experiment(&app, user_id, format!("试验{}", i)).await;
    }
    
    // 调用 API（无分页参数）
    let response = app.get("/api/v1/experiments")
        .await;
    
    // 验证：默认分页应该是 page=1, size=10
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    assert_eq!(body.items.len(), 10);        // 默认每页10条
    assert!(body.has_next);
    assert!(!body.has_prev);
    assert_eq!(body.page, 1);
    assert_eq!(body.total_items, 25);
    assert_eq!(body.total_pages, 3);
}
```

### TC-EXP-API-002: 列出试验-自定义分页参数

```rust
#[tokio::test]
async fn test_list_experiments_custom_pagination() {
    let (app, user_id) = setup_test_app().await;
    
    for i in 0..30 {
        create_test_experiment(&app, user_id, format!("试验{}", i)).await;
    }
    
    // 请求第2页，每页5条
    let response = app.get("/api/v1/experiments?page=2&size=5")
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    assert_eq!(body.items.len(), 5);
    assert!(body.has_next);
    assert!(body.has_prev);
    assert_eq!(body.page, 2);
    assert_eq!(body.total_items, 30);
    assert_eq!(body.total_pages, 6);
}
```

### TC-EXP-API-003: 列出试验-最后一页

```rust
#[tokio::test]
async fn test_list_experiments_last_page() {
    let (app, user_id) = setup_test_app().await;
    
    for i in 0..12 {
        create_test_experiment(&app, user_id, format!("试验{}", i)).await;
    }
    
    // 请求第2页（最后一页）
    let response = app.get("/api/v1/experiments?page=2&size=10")
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    assert_eq!(body.items.len(), 2);
    assert!(!body.has_next);   // 最后一页没有下一页
    assert!(body.has_prev);
}
```

### TC-EXP-API-004: 列出试验-空列表

```rust
#[tokio::test]
async fn test_list_experiments_empty() {
    let (app, user_id) = setup_test_app().await;
    
    // 不创建任何试验
    let response = app.get("/api/v1/experiments")
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    assert!(body.items.is_empty());
    assert!(!body.has_next);
    assert!(!body.has_prev);
    assert_eq!(body.total_items, 0);
}
```

### TC-EXP-API-005: 列出试验-无效分页参数

```rust
#[tokio::test]
async fn test_list_experiments_invalid_pagination() {
    let (app, _user_id) = setup_test_app().await;
    
    // page=0 应该失败
    let response = app.get("/api/v1/experiments?page=0")
        .await;
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    
    // page=-1 应该失败
    let response = app.get("/api/v1/experiments?page=-1")
        .await;
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    
    // size=0 应该失败
    let response = app.get("/api/v1/experiments?size=0")
        .await;
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    
    // size=1000 超过最大值应该失败
    let response = app.get("/api/v1/experiments?size=1000")
        .await;
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

### TC-EXP-API-006: 列出试验-按状态筛选

```rust
#[tokio::test]
async fn test_list_experiments_filter_by_status() {
    let (app, user_id) = setup_test_app().await;
    
    // 创建不同状态的试验
    let exp1 = create_test_experiment(&app, user_id, "试验1").await;
    let exp2 = create_test_experiment(&app, user_id, "试验2").await;
    let exp3 = create_test_experiment(&app, user_id, "试验3").await;
    
    // 更新状态
    update_experiment_status(&app, exp1.id, ExperimentStatus::Running).await;
    update_experiment_status(&app, exp2.id, ExperimentStatus::Completed).await;
    // exp3 保持 Idle
    
    // 按 Running 状态筛选
    let response = app.get("/api/v1/experiments?status=Running")
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    assert_eq!(body.items.len(), 1);
    assert_eq!(body.items[0].status, ExperimentStatus::Running);
}
```

### TC-EXP-API-007: 列出试验-按时间范围筛选

```rust
#[tokio::test]
async fn test_list_experiments_filter_by_time_range() {
    let (app, user_id) = setup_test_app().await;
    
    // 创建第一个试验
    let exp1 = create_test_experiment(&app, user_id, "试验1").await;
    let exp1_creation = exp1.created_at;
    
    // 等待一小段时间确保时间差
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
    
    // 创建第二个试验
    let exp2 = create_test_experiment(&app, user_id, "试验2").await;
    let exp2_creation = exp2.created_at;
    
    // 筛选时间在 exp1 创建后、exp2 创建前的试验（应只包含 exp1）
    let response = app.get(&format!(
        "/api/v1/experiments?created_after={}&created_before={}",
        exp1_creation.to_rfc3339(),
        exp2_creation.to_rfc3339()
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    // 应该只包含 exp1
    assert_eq!(body.total_items, 1, "Should only return 1 experiment created between the time range");
    assert_eq!(body.items[0].id, exp1.id);
}
```

### TC-EXP-API-008: 列出试验-组合筛选

```rust
#[tokio::test]
async fn test_list_experiments_combined_filters() {
    let (app, user_id) = setup_test_app().await;
    
    // 创建多个试验
    let exp1 = create_test_experiment(&app, user_id, "运行中试验").await;
    update_experiment_status(&app, exp1.id, ExperimentStatus::Running).await;
    
    let exp2 = create_test_experiment(&app, user_id, "已完成试验").await;
    update_experiment_status(&app, exp2.id, ExperimentStatus::Completed).await;
    
    create_test_experiment(&app, user_id, "空闲试验").await;
    
    // 组合筛选：status=Running 且分页
    let response = app.get("/api/v1/experiments?status=Running&page=1&size=5")
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    assert_eq!(body.items.len(), 1);
    assert_eq!(body.items[0].status, ExperimentStatus::Running);
}
```

### TC-EXP-API-009: 列出试验-排序验证

```rust
#[tokio::test]
async fn test_list_experiments_default_sort_order() {
    let (app, user_id) = setup_test_app().await;
    
    // 创建多个试验
    for i in 0..5 {
        create_test_experiment(&app, user_id, format!("试验{}", i)).await;
        tokio::time::sleep(tokio::time::Duration::from_millis(1)).await;
    }
    
    let response = app.get("/api/v1/experiments?page=1&size=10")
        .await;
    
    let body: PagedResponse<Experiment> = response.json().await;
    
    // 默认应该按 created_at 降序（最新的在前）
    for i in 0..body.items.len() - 1 {
        assert!(
            body.items[i].created_at >= body.items[i + 1].created_at,
            "Items should be sorted by created_at descending"
        );
    }
}
```

### TC-EXP-API-010: 列出试验-响应结构验证

```rust
#[tokio::test]
async fn test_list_experiments_response_structure() {
    let (app, user_id) = setup_test_app().await;
    
    create_test_experiment(&app, user_id, "测试试验").await;
    
    let response = app.get("/api/v1/experiments")
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: PagedResponse<Experiment> = response.json().await;
    
    // 验证响应结构
    assert!(body.items.iter().all(|exp| {
        exp.id != Uuid::nil() &&
        exp.name.len() > 0 &&
        exp.user_id == user_id &&
        exp.created_at <= exp.updated_at
    }));
}
```

---

## 3. 试验详情API测试

### TC-EXP-DETAIL-001: 获取试验详情-有效ID

```rust
#[tokio::test]
async fn test_get_experiment_detail_valid_id() {
    let (app, user_id) = setup_test_app().await;
    
    let created = create_test_experiment(&app, user_id, "测试试验").await;
    
    let response = app.get(&format!("/api/v1/experiments/{}", created.id))
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let experiment: Experiment = response.json().await;
    assert_eq!(experiment.id, created.id);
    assert_eq!(experiment.name, "测试试验");
    assert_eq!(experiment.user_id, user_id);
    assert!(experiment.description.is_none());
}
```

### TC-EXP-DETAIL-002: 获取试验详情-包含描述和状态

```rust
#[tokio::test]
async fn test_get_experiment_detail_with_optional_fields() {
    let (app, user_id) = setup_test_app().await;
    
    let created = create_test_experiment(&app, user_id, "完整试验").await;
    update_experiment_status(&app, created.id, ExperimentStatus::Running).await;
    
    let response = app.get(&format!("/api/v1/experiments/{}", created.id))
        .await;
    
    let experiment: Experiment = response.json().await;
    
    assert_eq!(experiment.status, ExperimentStatus::Running);
    assert!(experiment.started_at.is_some());
    assert!(experiment.ended_at.is_none());
}
```

### TC-EXP-DETAIL-003: 获取试验详情-不存在的ID

```rust
#[tokio::test]
async fn test_get_experiment_detail_not_found() {
    let (app, _user_id) = setup_test_app().await;
    
    let fake_id = Uuid::new_v4();
    let response = app.get(&format!("/api/v1/experiments/{}", fake_id))
        .await;
    
    assert_eq!(response.status(), StatusCode::NOT_FOUND);
    
    let error: ErrorResponse = response.json().await;
    assert!(error.message.contains("not found") || error.message.contains("不存在"));
}
```

### TC-EXP-DETAIL-004: 获取试验详情-无效UUID格式

```rust
#[tokio::test]
async fn test_get_experiment_detail_invalid_uuid() {
    let (app, _user_id) = setup_test_app().await;
    
    let response = app.get("/api/v1/experiments/invalid-uuid")
        .await;
    
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

### TC-EXP-DETAIL-005: 获取试验详情-包含关联数据文件

```rust
#[tokio::test]
async fn test_get_experiment_detail_with_data_files() {
    let (app, user_id) = setup_test_app().await;
    
    let experiment = create_test_experiment(&app, user_id, "测试试验").await;
    
    // 创建关联的数据文件
    create_data_file(&app, experiment.id, "/data/test.h5").await;
    
    let response = app.get(&format!("/api/v1/experiments/{}", experiment.id))
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: ExperimentDetailResponse = response.json().await;
    assert!(body.data_files.is_some());
    assert_eq!(body.data_files.unwrap().len(), 1);
}
```

---

## 4. 测点历史数据API测试

### TC-HIST-001: 获取测点历史-基本查询

```rust
#[tokio::test]
async fn test_get_point_history_basic() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    // 获取测点列表
    let points = get_experiment_points(&app, experiment_id).await;
    assert!(!points.is_empty());
    
    let point_id = points[0].id;
    
    // 查询该测点的历史数据
    let response = app.get(&format!("/api/v1/points/{}/history", point_id))
        .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let history: PointHistoryResponse = response.json().await;
    assert_eq!(history.point_id, point_id);
    assert!(!history.data.is_empty());
}
```

### TC-HIST-002: 获取测点历史-时间范围过滤

```rust
#[tokio::test]
async fn test_get_point_history_with_time_filter() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    // 全量数据的时间范围
    let full_response = app.get(&format!("/api/v1/points/{}/history", point_id))
        .await;
    let full_history: PointHistoryResponse = full_response.json().await;
    
    // 使用时间过滤（取后半段数据）
    let mid_timestamp = (full_history.start_time.timestamp_millis() + full_history.end_time.timestamp_millis()) / 2;
    let mid_time = DateTime::from_timestamp_millis(mid_timestamp).unwrap();
    
    let response = app.get(&format!(
        "/api/v1/points/{}/history?start_time={}",
        point_id,
        mid_time.to_rfc3339()
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let filtered_history: PointHistoryResponse = response.json().await;
    
    // 过滤后的数据点数量应该小于等于全量
    assert!(filtered_history.data.len() <= full_history.data.len());
}
```

### TC-HIST-003: 获取测点历史-完整时间范围

```rust
#[tokio::test]
async fn test_get_point_history_full_time_range() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    // 先获取全量数据以确定实际的时间范围
    let full_response = app.get(&format!(
        "/api/v1/points/{}/history",
        point_id
    ))
    .await;
    
    let full_history: PointHistoryResponse = full_response.json().await;
    assert!(!full_history.data.is_empty(), "Test requires existing data");
    
    // 使用实际数据的动态时间范围（扩展边界）
    let start_time = full_history.start_time - chrono::Duration::hours(1);
    let end_time = full_history.end_time + chrono::Duration::hours(1);
    
    let response = app.get(&format!(
        "/api/v1/points/{}/history?start_time={}&end_time={}",
        point_id,
        start_time.to_rfc3339(),
        end_time.to_rfc3339()
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let history: PointHistoryResponse = response.json().await;
    // 应该返回指定范围内的数据（至少应包含测试数据）
    assert!(!history.data.is_empty(), "Should return data within the time range");
    assert!(history.data.len() <= full_history.data.len(), "Filtered data should not exceed full data");
}
```

### TC-HIST-004: 获取测点历史-无效时间格式

```rust
#[tokio::test]
async fn test_get_point_history_invalid_time_format() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    // 无效的 start_time 格式
    let response = app.get(&format!(
        "/api/v1/points/{}/history?start_time=invalid-date",
        point_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

### TC-HIST-005: 获取测点历史-时间范围倒置

```rust
#[tokio::test]
async fn test_get_point_history_reversed_time_range() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    // start_time > end_time 应该失败
    let response = app.get(&format!(
        "/api/v1/points/{}/history?start_time=2024-12-01T00:00:00Z&end_time=2024-01-01T00:00:00Z",
        point_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

### TC-HIST-006: 获取测点历史-不存在的测点ID

```rust
#[tokio::test]
async fn test_get_point_history_not_found() {
    let (app, _experiment_id) = setup_test_app().await;
    
    let fake_point_id = Uuid::new_v4();
    let response = app.get(&format!("/api/v1/points/{}/history", fake_point_id))
        .await;
    
    assert_eq!(response.status(), StatusCode::NOT_FOUND);
}
```

### TC-HIST-007: 获取测点历史-响应数据结构验证

```rust
#[tokio::test]
async fn test_get_point_history_response_structure() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    let response = app.get(&format!("/api/v1/points/{}/history", point_id))
        .await;
    
    let history: PointHistoryResponse = response.json().await;
    
    // 验证响应结构
    assert!(history.point_id == point_id);
    assert!(history.channel.len() > 0);
    assert!(history.data.iter().all(|p| p.timestamp > 0));
    
    // 数据点应该按时间戳排序
    for i in 0..history.data.len() - 1 {
        assert!(
            history.data[i].timestamp <= history.data[i + 1].timestamp,
            "Data points should be sorted by timestamp"
        );
    }
}
```

### TC-HIST-008: 获取测点历史-空数据范围

```rust
#[tokio::test]
async fn test_get_point_history_empty_range() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    // 查询一个没有数据的遥远时间范围
    let response = app.get(&format!(
        "/api/v1/points/{}/history?start_time=2030-01-01T00:00:00Z&end_time=2030-01-02T00:00:00Z",
        point_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let history: PointHistoryResponse = response.json().await;
    assert!(history.data.is_empty());
}
```

### TC-HIST-009: 获取测点历史-分页支持

```rust
#[tokio::test]
async fn test_get_point_history_pagination() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    let point_id = points[0].id;
    
    // 获取第一页（使用 limit 参数）
    let response = app.get(&format!(
        "/api/v1/points/{}/history?limit=100",
        point_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let history: PointHistoryResponse = response.json().await;
    assert!(history.data.len() <= 100, "Should return at most limit number of data points");
}
```

### TC-HIST-010: 获取测点历史-多通道数据

```rust
#[tokio::test]
async fn test_get_point_history_multiple_channels() {
    let (app, experiment_id) = setup_experiment_with_multiple_channels().await;
    
    let points = get_experiment_points(&app, experiment_id).await;
    
    // 验证每个测点都有数据
    for point in points {
        let response = app.get(&format!("/api/v1/points/{}/history", point.id))
            .await;
        
        assert_eq!(response.status(), StatusCode::OK);
        
        let history: PointHistoryResponse = response.json().await;
        assert!(!history.data.is_empty(), "Channel {} should have data", history.channel);
    }
}
```

---

## 5. 数据文件下载API测试

### TC-DOWN-001: 下载数据文件-有效试验ID

```rust
#[tokio::test]
async fn test_download_data_file_valid_experiment() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    // 验证是 HDF5 文件
    let content_type = response.headers().get("content-type");
    assert!(content_type.is_some());
    
    // 验证有 Content-Disposition header
    let content_disposition = response.headers().get("content-disposition");
    assert!(content_disposition.is_some());
    
    // 读取文件内容
    let bytes = response.bytes().await.unwrap();
    assert!(!bytes.is_empty());
    
    // 验证是 HDF5 文件格式（魔数）
    assert_eq!(&bytes[0..4], b"\x89HDF");  // HDF5 文件魔数
}
```

### TC-DOWN-002: 下载数据文件-不存在的试验

```rust
#[tokio::test]
async fn test_download_data_file_not_found() {
    let (app, _user_id) = setup_test_app().await;
    
    let fake_id = Uuid::new_v4();
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        fake_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::NOT_FOUND);
}
```

### TC-DOWN-003: 下载数据文件-无关联数据文件

```rust
#[tokio::test]
async fn test_download_data_file_no_file_associated() {
    let (app, user_id) = setup_test_app().await;
    
    // 创建试验但不创建数据文件
    let experiment = create_test_experiment(&app, user_id, "无数据文件试验").await;
    
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment.id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::NOT_FOUND);
}
```

### TC-DOWN-004: 下载数据文件-文件完整性验证

```rust
#[tokio::test]
async fn test_download_data_file_integrity() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    // 获取测试数据的预期哈希（在测试夹具中预先计算）
    let expected_hash = get_test_hdf5_file_hash();
    
    // 下载文件
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let bytes = response.bytes().await.unwrap();
    
    // 计算下载文件的哈希
    let downloaded_hash = calculate_sha256(&bytes);
    
    assert_eq!(downloaded_hash, expected_hash, "File integrity check failed - hash mismatch");
}
```

### TC-DOWN-005: 下载数据文件-文件大小验证

```rust
#[tokio::test]
async fn test_download_data_file_size() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    // 获取测试数据的预期文件大小（在测试夹具中已知）
    let expected_size = get_test_hdf5_file_size();
    
    // 下载文件
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let bytes = response.bytes().await.unwrap();
    
    assert_eq!(
        bytes.len() as u64,
        expected_size,
        "Downloaded file size should match expected size"
    );
}
```

### TC-DOWN-006: 下载数据文件-无效试验ID格式

```rust
#[tokio::test]
async fn test_download_data_file_invalid_id_format() {
    let (app, _user_id) = setup_test_app().await;
    
    let response = app.get("/api/v1/experiments/invalid-id/data-file")
        .await;
    
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

### TC-DOWN-007: 下载数据文件-并发下载

```rust
#[tokio::test]
async fn test_download_data_file_concurrent() {
    let (app, experiment_id) = setup_experiment_with_hdf5_data().await;
    
    let url = format!("/api/v1/experiments/{}/data-file", experiment_id);
    
    // 并发发起多个下载请求
    let handles: Vec<_> = (0..5).map(|_| {
        let app = app.clone();
        tokio::spawn(async move {
            let response = app.get(&url).await;
            response.bytes().await.unwrap().len()
        })
    }).collect();
    
    let sizes: Vec<usize> = futures::future::join_all(handles)
        .await
        .into_iter()
        .collect();
    
    // 所有并发请求应该返回相同大小
    assert!(sizes.iter().all(|s| *s == sizes[0]));
}
```

### TC-DOWN-008: 下载数据文件-Streaming下载

```rust
#[tokio::test]
async fn test_download_data_file_streaming() {
    let (app, experiment_id) = setup_experiment_with_large_hdf5_data().await;
    
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment_id
    ))
    .await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    // 验证支持 Range 请求（分段下载）
    let range_response = app.get_with_headers(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment_id
    ), &[
        ("range", "bytes=0-1023")
    ])
    .await;
    
    // 大文件应该支持 Range 请求并返回 PARTIAL_CONTENT
    assert_eq!(
        range_response.status(),
        StatusCode::PARTIAL_CONTENT,
        "Large files should support Range requests for streaming"
    );
}
```

---

## 6. 错误处理与边界测试

### TC-ERR-001: 未授权访问

```rust
#[tokio::test]
async fn test_unauthorized_access() {
    let (app, _user_id) = setup_test_app().await;
    
    // 无 token 访问
    let response = app.get_without_auth("/api/v1/experiments")
        .await;
    
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}
```

### TC-ERR-002: 跨用户数据访问

```rust
#[tokio::test]
async fn test_cross_user_data_access() {
    let (app, user1_id) = setup_test_app().await;
    let (_, user2_id) = setup_test_app().await;
    
    // 用户1创建试验
    let experiment = create_test_experiment(&app, user1_id, "用户1试验").await;
    
    // 用户2尝试访问（使用用户2的token）
    let response = app.get_with_user_token(
        &format!("/api/v1/experiments/{}", experiment.id),
        user2_id
    )
    .await;
    
    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}
```

### TC-ERR-003: 服务器内部错误处理

```rust
#[tokio::test]
async fn test_server_error_handling() {
    let (app, experiment_id) = setup_broken_hdf5_app().await;
    
    let response = app.get(&format!(
        "/api/v1/experiments/{}/data-file",
        experiment_id
    ))
    .await;
    
    // 应该返回 500 Internal Server Error，而不是让程序崩溃
    assert!(matches!(
        response.status(),
        StatusCode::INTERNAL_SERVER_ERROR | StatusCode::SERVICE_UNAVAILABLE
    ));
}
```

---

## 7. 测试统计

| 类别 | 测试用例数 | 优先级 |
|------|-----------|--------|
| 试验列表API | 10 | P0 |
| 试验详情API | 5 | P0 |
| 测点历史API | 10 | P0 |
| 数据文件下载API | 8 | P0 |
| 错误处理与边界 | 3 | P1 |
| **总计** | **36** | |

### 7.1 优先级分类

| 优先级 | 定义 | 测试用例 |
|--------|------|---------|
| P0 | 核心功能，必须通过 | 30 |
| P1 | 重要功能，应该通过 | 6 |

---

## 8. 测试夹具辅助函数

### 8.1 测试夹具定义

```rust
// 测试夹具辅助函数

async fn setup_test_app() -> (TestApp, Uuid) {
    // 创建测试应用和用户
    let user_id = Uuid::new_v4();
    let app = create_test_app().await;
    (app, user_id)
}

async fn create_test_experiment(app: &TestApp, user_id: Uuid, name: &str) -> Experiment {
    let response = app.post("/api/v1/experiments")
        .json(&serde_json::json!({
            "user_id": user_id,
            "name": name
        }))
        .await;
    response.json().await
}

async fn setup_experiment_with_hdf5_data() -> (TestApp, Uuid) {
    // 创建带有 HDF5 数据的试验
}

async fn get_experiment_points(app: &TestApp, experiment_id: Uuid) -> Vec<Point> {
    let response = app.get(&format!("/api/v1/experiments/{}/points", experiment_id))
        .await;
    response.json().await
}
```

---

**文档结束**
