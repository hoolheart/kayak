# S2-002: 试验数据模型与元信息管理 - 测试用例文档

**任务ID**: S2-002  
**任务名称**: 试验数据模型与元信息管理 (Experiment Data Model and Metadata Management)  
**文档版本**: 1.0  
**创建日期**: 2026-03-26  
**测试类型**: 单元测试、集成测试  
**技术栈**: Rust / sqlx / tokio / tempfile

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-002 任务的所有功能测试，包括：
1. **试验记录CRUD** - 创建、读取、更新、删除试验记录
2. **试验状态流转** - 状态机转换验证
3. **数据文件元信息管理** - HDF5文件路径记录
4. **查询与筛选** - 分页、过滤条件

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 试验记录包含完整元信息 | TC-EXP-001 ~ TC-EXP-012 | Unit/Integration |
| 2. 试验状态流转正确 | TC-EXP-020 ~ TC-EXP-032 | Unit |
| 3. 数据文件元信息表记录HDF5文件路径 | TC-EXP-040 ~ TC-EXP-050 | Unit/Integration |

---

## 2. 试验状态枚举

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum ExperimentStatus {
    /// 初始状态，试验未开始
    Idle,
    /// 试验正在运行
    Running,
    /// 试验暂停
    Paused,
    /// 试验正常结束
    Completed,
    /// 试验被中止
    Aborted,
}
```

### 2.1 有效状态转换

| 当前状态 | 允许目标状态 |
|---------|-------------|
| Idle | Running |
| Running | Paused, Completed, Aborted |
| Paused | Running, Aborted |
| Completed | (无 - 终态) |
| Aborted | (无 - 终态) |

---

## 3. 测试用例

### 3.1 试验记录CRUD测试

#### TC-EXP-001: 创建试验记录
```rust
#[tokio::test]
async fn test_create_experiment() {
    // 准备测试数据
    let user_id = Uuid::new_v4();
    let method_id = Some(Uuid::new_v4());
    let name = "测试试验".to_string();
    
    // 创建试验
    let experiment = experiment_service.create(CreateExperimentRequest {
        user_id,
        method_id,
        name: name.clone(),
        description: None,
    }).await.unwrap();
    
    // 验证结果
    assert_eq!(experiment.name, name);
    assert_eq!(experiment.user_id, user_id);
    assert_eq!(experiment.method_id, method_id);
    assert_eq!(experiment.status, ExperimentStatus::Idle);
    assert!(experiment.started_at.is_some());
    assert!(experiment.ended_at.is_none());
}
```

#### TC-EXP-002: 创建试验记录(含可选字段)
```rust
#[tokio::test]
async fn test_create_experiment_with_optional_fields() {
    let request = CreateExperimentRequest {
        user_id: Uuid::new_v4(),
        method_id: Some(Uuid::new_v4()),
        name: "完整试验".to_string(),
        description: Some("试验描述".to_string()),
    };
    
    let experiment = service.create(request).await.unwrap();
    
    assert!(experiment.description.is_some());
    assert_eq!(experiment.description.unwrap(), "试验描述");
}
```

#### TC-EXP-003: 创建试验记录-空名称失败
```rust
#[tokio::test]
async fn test_create_experiment_empty_name_fails() {
    let request = CreateExperimentRequest {
        user_id: Uuid::new_v4(),
        method_id: None,
        name: "".to_string(),
        description: None,
    };
    
    let result = service.create(request).await;
    assert!(result.is_err());
}
```

#### TC-EXP-004: 获取试验记录-有效ID
```rust
#[tokio::test]
async fn test_get_experiment_by_valid_id() {
    let created = service.create(CreateExperimentRequest { ... }).await.unwrap();
    
    let retrieved = service.get_by_id(created.id).await.unwrap();
    
    assert_eq!(retrieved.id, created.id);
    assert_eq!(retrieved.name, created.name);
}
```

#### TC-EXP-005: 获取试验记录-不存在ID
```rust
#[tokio::test]
async fn test_get_experiment_not_found() {
    let result = service.get_by_id(Uuid::new_v4()).await;
    
    assert!(result.is_err());
    match result.unwrap_err() {
        ExperimentError::NotFound(_) => {},
        _ => panic!("Expected NotFound error"),
    }
}
```

#### TC-EXP-006: 列出试验记录-分页
```rust
#[tokio::test]
async fn test_list_experiments_pagination() {
    // 创建多个试验
    for i in 0..15 {
        service.create(CreateExperimentRequest { name: format!("试验{}", i), .. }).await.unwrap();
    }
    
    // 第一页
    let page1 = service.list(ListExperimentsRequest {
        page: Some(1),
        size: Some(10),
        ..Default::default()
    }).await.unwrap();
    
    assert_eq!(page1.items.len(), 10);
    assert!(page1.has_next);
    assert!(!page1.has_prev);
    
    // 第二页
    let page2 = service.list(ListExperimentsRequest {
        page: Some(2),
        size: Some(10),
        ..Default::default()
    }).await.unwrap();
    
    assert_eq!(page2.items.len(), 5);
    assert!(!page2.has_next);
    assert!(page2.has_prev);
}
```

#### TC-EXP-007: 列出试验记录-按用户ID筛选
```rust
#[tokio::test]
async fn test_list_experiments_filter_by_user() {
    let user_id = Uuid::new_v4();
    
    // 创建属于该用户的试验
    service.create(CreateExperimentRequest { user_id, name: "用户1试验".to_string(), .. }).await.unwrap();
    service.create(CreateExperimentRequest { user_id, name: "用户1试验2".to_string(), .. }).await.unwrap();
    
    // 创建不属于该用户的试验
    service.create(CreateExperimentRequest { name: "其他用户试验".to_string(), .. }).await.unwrap();
    
    let result = service.list(ListExperimentsRequest {
        user_id: Some(user_id),
        ..Default::default()
    }).await.unwrap();
    
    assert_eq!(result.items.len(), 2);
    assert!(result.items.iter().all(|e| e.user_id == user_id));
}
```

#### TC-EXP-008: 列出试验记录-按状态筛选
```rust
#[tokio::test]
async fn test_list_experiments_filter_by_status() {
    let running = service.create(CreateExperimentRequest { name: "运行中".to_string(), .. }).await.unwrap();
    service.update_status(running.id, ExperimentStatus::Running).await.unwrap();
    
    service.create(CreateExperimentRequest { name: "已完成".to_string(), .. }).await.unwrap();
    
    let result = service.list(ListExperimentsRequest {
        status: Some(ExperimentStatus::Running),
        ..Default::default()
    }).await.unwrap();
    
    assert_eq!(result.items.len(), 1);
    assert_eq!(result.items[0].status, ExperimentStatus::Running);
}
```

---

### 3.2 试验状态流转测试

#### TC-EXP-020: 状态转换-Idle→Running
```rust
#[tokio::test]
async fn test_status_idle_to_running() {
    let experiment = service.create(CreateExperimentRequest { name: "测试".to_string(), .. }).await.unwrap();
    
    assert_eq!(experiment.status, ExperimentStatus::Idle);
    
    let updated = service.update_status(experiment.id, ExperimentStatus::Running).await.unwrap();
    
    assert_eq!(updated.status, ExperimentStatus::Running);
    assert!(updated.started_at.is_some());
}
```

#### TC-EXP-021: 状态转换-Running→Paused
```rust
#[tokio::test]
async fn test_status_running_to_paused() {
    let experiment = create_and_start().await;
    
    let updated = service.update_status(experiment.id, ExperimentStatus::Paused).await.unwrap();
    
    assert_eq!(updated.status, ExperimentStatus::Paused);
}
```

#### TC-EXP-022: 状态转换-Paused→Running
```rust
#[tokio::test]
async fn test_status_paused_to_running() {
    let experiment = create_and_start().await;
    service.update_status(experiment.id, ExperimentStatus::Paused).await.unwrap();
    
    let updated = service.update_status(experiment.id, ExperimentStatus::Running).await.unwrap();
    
    assert_eq!(updated.status, ExperimentStatus::Running);
}
```

#### TC-EXP-023: 状态转换-Running→Completed
```rust
#[tokio::test]
async fn test_status_running_to_completed() {
    let experiment = create_and_start().await;
    
    let updated = service.update_status(experiment.id, ExperimentStatus::Completed).await.unwrap();
    
    assert_eq!(updated.status, ExperimentStatus::Completed);
    assert!(updated.ended_at.is_some());
}
```

#### TC-EXP-024: 状态转换-Running→Aborted
```rust
#[tokio::test]
async fn test_status_running_to_aborted() {
    let experiment = create_and_start().await;
    
    let updated = service.update_status(experiment.id, ExperimentStatus::Aborted).await.unwrap();
    
    assert_eq!(updated.status, ExperimentStatus::Aborted);
    assert!(updated.ended_at.is_some());
}
```

#### TC-EXP-025: 状态转换-Paused→Aborted
```rust
#[tokio::test]
async fn test_status_paused_to_aborted() {
    let experiment = create_and_start().await;
    service.update_status(experiment.id, ExperimentStatus::Paused).await.unwrap();
    
    let updated = service.update_status(experiment.id, ExperimentStatus::Aborted).await.unwrap();
    
    assert_eq!(updated.status, ExperimentStatus::Aborted);
}
```

#### TC-EXP-030: 非法转换-Completed→任意状态
```rust
#[tokio::test]
async fn test_invalid_transition_from_completed() {
    let experiment = create_and_complete().await;
    
    let result = service.update_status(experiment.id, ExperimentStatus::Running).await;
    
    assert!(result.is_err());
    match result.unwrap_err() {
        ExperimentError::InvalidStatusTransition { from, to } => {
            assert_eq!(from, ExperimentStatus::Completed);
            assert_eq!(to, ExperimentStatus::Running);
        },
        _ => panic!("Expected InvalidStatusTransition error"),
    }
}
```

#### TC-EXP-031: 非法转换-Aborted→任意状态
```rust
#[tokio::test]
async fn test_invalid_transition_from_aborted() {
    let experiment = create_and_abort().await;
    
    let result = service.update_status(experiment.id, ExperimentStatus::Running).await;
    
    assert!(result.is_err());
}
```

#### TC-EXP-032: 非法转换-Idle→Paused(跳过Running)
```rust
#[tokio::test]
async fn test_invalid_transition_idle_to_paused() {
    let experiment = service.create(CreateExperimentRequest { name: "测试".to_string(), .. }).await.unwrap();
    
    let result = service.update_status(experiment.id, ExperimentStatus::Paused).await;
    
    assert!(result.is_err());
}
```

---

### 3.3 数据文件元信息测试

#### TC-EXP-040: 创建数据文件与试验关联
```rust
#[tokio::test]
async fn test_create_data_file_with_experiment() {
    let experiment = service.create(CreateExperimentRequest { name: "测试".to_string(), .. }).await.unwrap();
    
    let data_file = data_file_service.create(CreateDataFileRequest {
        experiment_id: Some(experiment.id),
        file_path: "/tmp/test.h5".to_string(),
        file_hash: Some("abc123".to_string()),
        source_type: DataFileSourceType::Hdf5,
        metadata: None,
    }).await.unwrap();
    
    assert_eq!(data_file.experiment_id, Some(experiment.id));
    assert_eq!(data_file.file_path, "/tmp/test.h5");
}
```

#### TC-EXP-041: 创建数据文件(无试验关联)
```rust
#[tokio::test]
async fn test_create_data_file_without_experiment() {
    let data_file = data_file_service.create(CreateDataFileRequest {
        experiment_id: None,
        file_path: "/tmp/general.h5".to_string(),
        file_hash: None,
        source_type: DataFileSourceType::Hdf5,
        metadata: None,
    }).await.unwrap();
    
    assert!(data_file.experiment_id.is_none());
}
```

#### TC-EXP-044: 按试验ID列出数据文件
```rust
#[tokio::test]
async fn test_list_data_files_by_experiment() {
    let experiment = service.create(CreateExperimentRequest { name: "测试".to_string(), .. }).await.unwrap();
    
    // 创建多个数据文件
    for i in 0..3 {
        data_file_service.create(CreateDataFileRequest {
            experiment_id: Some(experiment.id),
            file_path: format!("/tmp/test{}.h5", i),
            ..Default::default()
        }).await.unwrap();
    }
    
    let files = data_file_service.list_by_experiment(experiment.id).await.unwrap();
    
    assert_eq!(files.len(), 3);
}
```

#### TC-EXP-050: 删除试验时级联归档数据文件
```rust
#[tokio::test]
async fn test_delete_experiment_cascades_to_data_files() {
    let experiment = service.create(CreateExperimentRequest { name: "测试".to_string(), .. }).await.unwrap();
    
    data_file_service.create(CreateDataFileRequest {
        experiment_id: Some(experiment.id),
        file_path: "/tmp/test.h5",
        ..Default::default()
    }).await.unwrap();
    
    service.delete(experiment.id).await.unwrap();
    
    let files = data_file_service.list_by_experiment(experiment.id).await.unwrap();
    assert!(files.is_empty()); // 数据文件被归档
}
```

---

## 4. 测试统计

| 类别 | 数量 | 优先级 |
|------|------|--------|
| CRUD测试 | 12 | P0/P1 |
| 状态转换测试 | 9 | P0 |
| 数据文件测试 | 7 | P1 |
| 查询筛选测试 | 5 | P1 |
| 错误处理测试 | 5 | P1 |
| **总计** | **38** | |

---

**文档结束**