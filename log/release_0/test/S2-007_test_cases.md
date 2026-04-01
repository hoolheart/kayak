# S2-007: 试验方法数据模型与存储 - 测试用例文档

**任务ID**: S2-007  
**任务名称**: 试验方法数据模型与存储 (Experiment Method Data Model and Storage)  
**文档版本**: 2.0  
**创建日期**: 2026-04-01  
**测试类型**: 单元测试、集成测试  
**技术栈**: Rust / sqlx / tokio / Axum / reqwest

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-007 任务的所有功能测试，包括：
1. **Method实体模型测试** - 数据结构、序列化/反序列化
2. **MethodRepository CRUD测试** - 数据库层的增删改查
3. **MethodService业务逻辑测试** - 服务层业务规则验证
4. **API端点集成测试** - REST API的完整流程测试
5. **参数Schema验证测试** - 配置参数表Schema验证
6. **版本管理扩展点测试** - 预留扩展点验证

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 方法定义存储为JSON | TC-METHOD-001 ~ TC-METHOD-015, TC-METHOD-050 | Unit/Integration |
| 2. 支持配置参数表 | TC-METHOD-020 ~ TC-METHOD-032 | Unit |
| 3. 方法版本管理预留扩展点 | TC-METHOD-040 ~ TC-METHOD-045 | Unit |

### 1.3 项目技术规范

- **数据库**: SQLite with sqlx，使用 `?` 占位符（不是 `$1, $2`）
- **UUID处理**: 使用 `.bind(id.to_string())` 绑定UUID到SQL
- **API响应格式**: `SuccessResponse<T>` 结构为 `{ code, message, data, timestamp }`
- **分页响应**: `PagedResponse<T>` 结构为 `{ items, page, size, total, has_next, has_prev }`

---

## 2. Method数据模型定义

### 2.1 实体结构

```rust
/// 试验方法实体
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Method {
    /// 方法ID (UUID)
    pub id: Uuid,
    /// 方法名称
    pub name: String,
    /// 方法描述
    pub description: Option<String>,
    /// JSON格式的过程定义
    pub process_definition: serde_json::Value,
    /// 配置参数表Schema (JSON Schema格式)
    pub parameter_schema: serde_json::Value,
    /// 版本号 (预留扩展点)
    pub version: i32,
    /// 创建用户ID
    pub created_by: Uuid,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl Method {
    /// 创建新方法
    pub fn new(
        name: String,
        description: Option<String>,
        process_definition: serde_json::Value,
        parameter_schema: serde_json::Value,
        created_by: Uuid,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            name,
            description,
            process_definition,
            parameter_schema,
            version: 1,
            created_by,
            created_at: now,
            updated_at: now,
        }
    }
}
```

### 2.2 数据库Schema

```sql
CREATE TABLE methods (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    process_definition TEXT NOT NULL,
    parameter_schema TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    created_by TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX idx_methods_created_by ON methods(created_by);
```

### 2.3 过程定义JSON结构示例

```json
{
  "steps": [
    {
      "type": "Start",
      "name": "初始化",
      "duration_ms": 1000
    },
    {
      "type": "Read",
      "name": "读取测点",
      "device_id": "uuid-of-device",
      "point_id": "uuid-of-point",
      "interval_ms": 100
    },
    {
      "type": "Control",
      "name": "设置温度",
      "device_id": "uuid-of-device",
      "point_id": "uuid-of-point",
      "value": 25.0
    },
    {
      "type": "Delay",
      "name": "等待稳定",
      "duration_ms": 5000
    },
    {
      "type": "End",
      "name": "结束试验"
    }
  ]
}
```

### 2.4 参数Schema JSON结构示例

```json
{
  "type": "object",
  "properties": {
    "temperature": {
      "type": "number",
      "minimum": -40,
      "maximum": 120,
      "default": 25,
      "description": "目标温度 (°C)"
    },
    "duration": {
      "type": "integer",
      "minimum": 1,
      "maximum": 3600,
      "default": 60,
      "description": "持续时间 (秒)"
    },
    "sample_interval": {
      "type": "integer",
      "minimum": 10,
      "maximum": 60000,
      "default": 1000,
      "description": "采样间隔 (毫秒)"
    }
  },
  "required": ["temperature", "duration"]
}
```

---

## 3. 测试基础设施

### 3.1 测试数据库上下文

```rust
/// 测试数据库上下文 - 使用内存SQLite
pub struct TestDbContext {
    pub pool: DbPool,
    db_name: String,
}

impl TestDbContext {
    /// 创建新的测试数据库上下文
    pub async fn new() -> Self {
        let db_id = Uuid::new_v4().to_string();
        let db_url = format!("sqlite:file:{}?mode=memory&cache=shared", db_id);

        let pool = SqlitePool::connect(&db_url)
            .await
            .expect("Failed to create test database pool");

        // 运行迁移
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .expect("Failed to run migrations");

        Self { pool, db_name: db_id }
    }

    pub fn pool(&self) -> DbPool {
        self.pool.clone()
    }
}

/// 创建测试数据库池的辅助函数
async fn create_test_db() -> DbPool {
    TestDbContext::new().await.pool()
}
```

### 3.2 参数验证辅助函数

```rust
use jsonschema::JSONSchema;
use serde_json::Value;

/// 验证参数是否符合Schema
pub fn validate_parameters(
    schema: &Value,
    params: &Value,
) -> Result<(), ValidationError> {
    let compiled = JSONSchema::compile(schema)
        .map_err(|e| ValidationError::SchemaError(e.to_string()))?;
    
    let result = compiled.validate(params);
    
    if let Err(errors) = result {
        let msg = errors
            .map(|e| e.to_string())
            .collect::<Vec<_>>()
            .join("; ");
        Err(ValidationError::ValidationFailed(msg))
    } else {
        Ok(())
    }
}

/// 应用默认参数
pub fn apply_defaults(schema: &Value, params: &Value) -> Value {
    let mut result = params.clone();
    
    if let Some(properties) = schema.get("properties").and_then(|p| p.as_object()) {
        for (key, prop) in properties {
            if let Some(default) = prop.get("default") {
                if !result.get(key).is_some() {
                    result[key] = default.clone();
                }
            }
        }
    }
    
    result
}

#[derive(Debug)]
pub enum ValidationError {
    SchemaError(String),
    ValidationFailed(String),
}
```

### 3.3 API测试辅助函数

```rust
use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use tower::ServiceExt;
use crate::api::routes;

/// 创建测试应用
pub async fn create_test_app() -> TestApp {
    let app = routes();
    TestApp { app }
}

pub struct TestApp {
    app: axum::Router,
}

impl TestApp {
    pub async fn get(&self, path: &str, token: &str) -> Response {
        self.app
            .clone()
            .with_state(())
            .oneshot(
                Request::builder()
                    .method("GET")
                    .uri(path)
                    .header("Authorization", format!("Bearer {}", token))
                    .body(Body::empty())
                    .unwrap()
            )
            .await
            .unwrap()
    }

    pub async fn post(&self, path: &str, token: &str, body: String) -> Response {
        self.app
            .clone()
            .with_state(())
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri(path)
                    .header("Authorization", format!("Bearer {}", token))
                    .header("Content-Type", "application/json")
                    .body(Body::from(body))
                    .unwrap()
            )
            .await
            .unwrap()
    }

    pub async fn put(&self, path: &str, token: &str, body: String) -> Response {
        self.app
            .clone()
            .with_state(())
            .oneshot(
                Request::builder()
                    .method("PUT")
                    .uri(path)
                    .header("Authorization", format!("Bearer {}", token))
                    .header("Content-Type", "application/json")
                    .body(Body::from(body))
                    .unwrap()
            )
            .await
            .unwrap()
    }

    pub async fn delete(&self, path: &str, token: &str) -> Response {
        self.app
            .clone()
            .with_state(())
            .oneshot(
                Request::builder()
                    .method("DELETE")
                    .uri(path)
                    .header("Authorization", format!("Bearer {}", token))
                    .body(Body::empty())
                    .unwrap()
            )
            .await
            .unwrap()
    }

    pub fn address(&self) -> String {
        "http://localhost:3000".to_string()
    }
}

/// 创建测试用户并获取Token
pub async fn create_test_user_and_get_token() -> String {
    // 创建测试用户并生成JWT token
    // 具体实现依赖于认证系统
    "test_token_placeholder".to_string()
}

/// API响应包装结构
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub code: i32,
    pub message: String,
    pub data: T,
    pub timestamp: String,
}

/// 创建方法请求DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateMethodRequest {
    pub name: String,
    pub description: Option<String>,
    pub process_definition: serde_json::Value,
    pub parameter_schema: serde_json::Value,
}

/// 更新方法请求DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateMethodRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub process_definition: Option<serde_json::Value>,
    pub parameter_schema: Option<serde_json::Value>,
}

/// 方法响应DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MethodDto {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub process_definition: serde_json::Value,
    pub parameter_schema: serde_json::Value,
    pub version: i32,
    pub created_by: String,
    pub created_at: String,
    pub updated_at: String,
}

/// 通过API创建方法的辅助函数
pub async fn create_method_via_api(
    app: &TestApp,
    token: &str,
    name: &str,
    description: Option<&str>,
    process_definition: serde_json::Value,
    parameter_schema: serde_json::Value,
) -> MethodDto {
    let request = CreateMethodRequest {
        name: name.to_string(),
        description: description.map(|s| s.to_string()),
        process_definition,
        parameter_schema,
    };
    
    let response = app.post(
        "/api/v1/methods",
        token,
        serde_json::to_string(&request).unwrap(),
    ).await;
    
    assert_eq!(response.status(), StatusCode::CREATED);
    
    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let api_response: ApiResponse<MethodDto> = serde_json::from_slice(&body).unwrap();
    api_response.data
}

/// 验证方法请求的辅助函数
pub fn validate_method_request(request: &CreateMethodRequest) -> Result<(), String> {
    // 验证名称长度
    if request.name.is_empty() || request.name.len() > 255 {
        return Err("名称长度必须在1-255之间".to_string());
    }
    
    // 验证process_definition是有效JSON对象
    if !request.process_definition.is_object() {
        return Err("过程定义必须是JSON对象".to_string());
    }
    
    // 验证parameter_schema是有效JSON对象
    if !request.parameter_schema.is_object() {
        return Err("参数Schema必须是JSON对象".to_string());
    }
    
    Ok(())
}
```

---

## 4. 测试用例

### 4.1 Method模型序列化/反序列化测试

#### TC-METHOD-001: Method实体JSON序列化
```rust
#[tokio::test]
async fn test_method_serialization() {
    let method = Method::new(
        "温度循环试验".to_string(),
        Some("测试温度循环过程".to_string()),
        serde_json::json!({
            "steps": [{"type": "Start", "name": "开始"}]
        }),
        serde_json::json!({
            "type": "object",
            "properties": {
                "temperature": {"type": "number", "default": 25}
            }
        }),
        Uuid::new_v4(),
    );
    
    let json = serde_json::to_string(&method).unwrap();
    assert!(json.contains("温度循环试验"));
    assert!(json.contains("process_definition"));
    assert!(json.contains("parameter_schema"));
}
```

#### TC-METHOD-002: Method实体JSON反序列化
```rust
#[tokio::test]
async fn test_method_deserialization() {
    let json = r#"{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "温度循环试验",
        "description": "测试温度循环过程",
        "process_definition": {"steps": [{"type": "Start"}]},
        "parameter_schema": {"type": "object"},
        "version": 1,
        "created_by": "550e8400-e29b-41d4-a716-446655440001",
        "created_at": "2026-04-01T00:00:00Z",
        "updated_at": "2026-04-01T00:00:00Z"
    }"#;
    
    let method: Method = serde_json::from_str(json).unwrap();
    
    assert_eq!(method.name, "温度循环试验");
    assert_eq!(method.version, 1);
    assert!(method.description.is_some());
}
```

#### TC-METHOD-003: 复杂过程定义序列化
```rust
#[tokio::test]
async fn test_complex_process_definition_serialization() {
    let process_def = serde_json::json!({
        "steps": [
            {
                "type": "Start",
                "name": "初始化设备",
                "duration_ms": 2000
            },
            {
                "type": "Control",
                "name": "设置温度",
                "device_id": "device-uuid",
                "point_id": "temp-point-uuid",
                "value": 85.5,
                "condition": null
            },
            {
                "type": "Delay",
                "name": "等待温度稳定",
                "duration_ms": 10000
            },
            {
                "type": "Read",
                "name": "读取数据",
                "device_id": "device-uuid",
                "point_ids": ["point1", "point2", "point3"],
                "interval_ms": 500,
                "count": 100
            },
            {
                "type": "End",
                "name": "结束试验"
            }
        ],
        "metadata": {
            "author": "test_user",
            "version": "1.0"
        }
    });
    
    let json = serde_json::to_string(&process_def).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
    
    assert_eq!(parsed["steps"].as_array().unwrap().len(), 5);
    assert_eq!(parsed["steps"][1]["value"], 85.5);
}
```

#### TC-METHOD-004: 参数Schema序列化验证
```rust
#[tokio::test]
async fn test_parameter_schema_serialization() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {
                "type": "number",
                "minimum": -40,
                "maximum": 120,
                "default": 25,
                "description": "目标温度 (°C)"
            },
            "duration": {
                "type": "integer",
                "minimum": 1,
                "maximum": 3600,
                "default": 60
            },
            "enabled": {
                "type": "boolean",
                "default": true
            }
        },
        "required": ["temperature", "duration"]
    });
    
    let json = serde_json::to_string(&schema).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
    
    assert_eq!(parsed["properties"]["temperature"]["minimum"], -40);
    assert_eq!(parsed["properties"]["temperature"]["maximum"], 120);
    assert!(parsed["required"].as_array().unwrap().contains(&serde_json::json!("temperature")));
}
```

#### TC-METHOD-005: 创建Method实体
```rust
#[tokio::test]
async fn test_method_new() {
    let user_id = Uuid::new_v4();
    let method = Method::new(
        "标准温度试验".to_string(),
        Some("用于常规温度测试".to_string()),
        serde_json::json!({"steps": []}),
        serde_json::json!({"type": "object"}),
        user_id,
    );
    
    assert_eq!(method.name, "标准温度试验");
    assert_eq!(method.created_by, user_id);
    assert_eq!(method.version, 1);
    assert!(method.description.is_some());
    assert!(method.id != Uuid::nil());
}
```

#### TC-METHOD-006: Method实体UUID生成
```rust
#[tokio::test]
async fn test_method_id_uniqueness() {
    let methods: Vec<Method> = (0..100)
        .map(|_| {
            Method::new(
                "test".to_string(),
                None,
                serde_json::json!({}),
                serde_json::json!({}),
                Uuid::new_v4(),
            )
        })
        .collect();
    
    let ids: HashSet<Uuid> = methods.iter().map(|m| m.id).collect();
    assert_eq!(ids.len(), 100); // All unique
}
```

---

### 4.2 MethodRepository CRUD测试

#### TC-METHOD-010: 创建方法-基本字段
```rust
#[tokio::test]
async fn test_method_repo_create_basic() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "基础试验方法".to_string(),
        Some("描述信息".to_string()),
        serde_json::json!({"steps": [{"type": "Start"}]}),
        serde_json::json!({"type": "object", "properties": {}}),
        user_id,
    );
    
    let created = repo.create(&method).await.unwrap();
    
    assert_eq!(created.name, "基础试验方法");
    assert_eq!(created.id, method.id);
    assert_eq!(created.version, 1);
}
```

#### TC-METHOD-011: 创建方法-存储复杂JSON
```rust
#[tokio::test]
async fn test_method_repo_create_with_complex_json() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let process_def = serde_json::json!({
        "steps": [
            {"type": "Start", "name": "开始", "duration_ms": 1000},
            {"type": "Read", "name": "读取", "interval_ms": 100, "count": 10},
            {"type": "Control", "name": "控制", "value": 50.0},
            {"type": "Delay", "name": "延迟", "duration_ms": 5000},
            {"type": "End", "name": "结束"}
        ],
        "loops": 3
    });
    
    let param_schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {
                "type": "number",
                "minimum": -20,
                "maximum": 100,
                "default": 25
            },
            "pressure": {
                "type": "number",
                "minimum": 0,
                "maximum": 1000,
                "default": 101.325
            }
        },
        "required": ["temperature"]
    });
    
    let method = Method::new(
        "复杂过程方法".to_string(),
        None,
        process_def,
        param_schema,
        user_id,
    );
    
    let created = repo.create(&method).await.unwrap();
    
    // 验证JSON存储正确
    let retrieved = repo.find_by_id(created.id).await.unwrap().unwrap();
    assert_eq!(retrieved.process_definition["loops"], 3);
    assert_eq!(retrieved.process_definition["steps"].as_array().unwrap().len(), 5);
    assert_eq!(retrieved.parameter_schema["properties"]["temperature"]["default"], 25);
}
```

#### TC-METHOD-012: 按ID获取方法-存在
```rust
#[tokio::test]
async fn test_method_repo_find_by_id_exists() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "测试方法".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let found = repo.find_by_id(method.id).await.unwrap();
    
    assert!(found.is_some());
    let m = found.unwrap();
    assert_eq!(m.id, method.id);
    assert_eq!(m.name, "测试方法");
}
```

#### TC-METHOD-013: 按ID获取方法-不存在
```rust
#[tokio::test]
async fn test_method_repo_find_by_id_not_exists() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    
    let found = repo.find_by_id(Uuid::new_v4()).await.unwrap();
    
    assert!(found.is_none());
}
```

#### TC-METHOD-014: 列表查询-分页
```rust
#[tokio::test]
async fn test_method_repo_list_pagination() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    // 创建20个方法
    for i in 0..20 {
        let method = Method::new(
            format!("方法{}", i),
            None,
            serde_json::json!({}),
            serde_json::json!({}),
            user_id,
        );
        repo.create(&method).await.unwrap();
    }
    
    // 第一页
    let (items, total) = repo.list_by_user(user_id, 1, 10).await.unwrap();
    assert_eq!(items.len(), 10);
    assert_eq!(total, 20);
    
    // 第二页
    let (items, total) = repo.list_by_user(user_id, 2, 10).await.unwrap();
    assert_eq!(items.len(), 10);
    assert_eq!(total, 20);
}
```

#### TC-METHOD-015: 列表查询-按创建者筛选
```rust
#[tokio::test]
async fn test_method_repo_list_filter_by_user() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    
    let user1 = Uuid::new_v4();
    let user2 = Uuid::new_v4();
    
    // 用户1创建5个方法
    for i in 0..5 {
        let method = Method::new(
            format!("用户1方法{}", i), 
            None, 
            serde_json::json!({}), 
            serde_json::json!({}), 
            user1
        );
        repo.create(&method).await.unwrap();
    }
    
    // 用户2创建3个方法
    for i in 0..3 {
        let method = Method::new(
            format!("用户2方法{}", i), 
            None, 
            serde_json::json!({}), 
            serde_json::json!({}), 
            user2
        );
        repo.create(&method).await.unwrap();
    }
    
    let (user1_methods, _) = repo.list_by_user(user1, 1, 100).await.unwrap();
    let (user2_methods, _) = repo.list_by_user(user2, 1, 100).await.unwrap();
    
    assert_eq!(user1_methods.len(), 5);
    assert_eq!(user2_methods.len(), 3);
}
```

#### TC-METHOD-016: 更新方法-名称
```rust
#[tokio::test]
async fn test_method_repo_update_name() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "原名称".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let updated = repo.update(method.id, Some("新名称".to_string()), None, None, None).await.unwrap();
    
    assert_eq!(updated.name, "新名称");
    assert_eq!(updated.id, method.id);
}
```

#### TC-METHOD-017: 更新方法-描述
```rust
#[tokio::test]
async fn test_method_repo_update_description() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "方法".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let updated = repo.update(method.id, None, Some("新描述".to_string()), None, None).await.unwrap();
    
    assert_eq!(updated.description, Some("新描述".to_string()));
}
```

#### TC-METHOD-018: 更新方法-过程定义
```rust
#[tokio::test]
async fn test_method_repo_update_process_definition() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let original_def = serde_json::json!({"steps": [{"type": "Start"}]});
    let method = Method::new(
        "方法".to_string(), 
        None, 
        original_def, 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let new_def = serde_json::json!({"steps": [{"type": "Start"}, {"type": "End"}]});
    let updated = repo.update(method.id, None, None, Some(new_def), None).await.unwrap();
    
    assert_eq!(updated.process_definition["steps"].as_array().unwrap().len(), 2);
}
```

#### TC-METHOD-019: 更新方法-参数Schema
```rust
#[tokio::test]
async fn test_method_repo_update_parameter_schema() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let original_schema = serde_json::json!({"type": "object"});
    let method = Method::new(
        "方法".to_string(), 
        None, 
        serde_json::json!({}), 
        original_schema, 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let new_schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {"type": "number", "default": 25}
        }
    });
    let updated = repo.update(method.id, None, None, None, Some(new_schema)).await.unwrap();
    
    assert_eq!(updated.parameter_schema["properties"]["temperature"]["default"], 25);
}
```

#### TC-METHOD-020: 删除方法-存在
```rust
#[tokio::test]
async fn test_method_repo_delete_exists() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "待删除".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let result = repo.delete(method.id).await;
    assert!(result.is_ok());
    
    let found = repo.find_by_id(method.id).await.unwrap();
    assert!(found.is_none());
}
```

#### TC-METHOD-021: 删除方法-不存在
```rust
#[tokio::test]
async fn test_method_repo_delete_not_exists() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    
    let result = repo.delete(Uuid::new_v4()).await;
    
    assert!(result.is_err());
    match result.unwrap_err() {
        MethodRepositoryError::NotFound => {},
        _ => panic!("Expected NotFound error"),
    }
}
```

---

### 4.3 参数Schema验证测试

#### TC-METHOD-022: 验证必填参数
```rust
#[tokio::test]
async fn test_validate_required_parameters() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {"type": "number"},
            "duration": {"type": "integer"}
        },
        "required": ["temperature", "duration"]
    });
    
    // 缺少必填参数
    let params = serde_json::json!({"temperature": 25});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
    
    // 包含所有必填参数
    let params = serde_json::json!({"temperature": 25, "duration": 60});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
}
```

#### TC-METHOD-023: 验证数值范围-最小值
```rust
#[tokio::test]
async fn test_validate_number_minimum() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {
                "type": "number",
                "minimum": -40,
                "maximum": 120
            }
        }
    });
    
    // 低于最小值
    let params = serde_json::json!({"temperature": -50});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
    
    // 在范围内
    let params = serde_json::json!({"temperature": 25});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
}
```

#### TC-METHOD-024: 验证数值范围-最大值
```rust
#[tokio::test]
async fn test_validate_number_maximum() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {
                "type": "number",
                "minimum": -40,
                "maximum": 120
            }
        }
    });
    
    // 超过最大值
    let params = serde_json::json!({"temperature": 150});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
    
    // 在范围内
    let params = serde_json::json!({"temperature": 100});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
}
```

#### TC-METHOD-025: 验证整数类型
```rust
#[tokio::test]
async fn test_validate_integer_type() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "count": {"type": "integer"}
        }
    });
    
    // 浮点数应失败
    let params = serde_json::json!({"count": 10.5});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
    
    // 整数应成功
    let params = serde_json::json!({"count": 10});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
}
```

#### TC-METHOD-026: 验证布尔类型
```rust
#[tokio::test]
async fn test_validate_boolean_type() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "enabled": {"type": "boolean"}
        }
    });
    
    let params = serde_json::json!({"enabled": true});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
    
    let params = serde_json::json!({"enabled": false});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
    
    // 字符串应失败
    let params = serde_json::json!({"enabled": "true"});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
}
```

#### TC-METHOD-027: 验证字符串类型
```rust
#[tokio::test]
async fn test_validate_string_type() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "name": {"type": "string"}
        }
    });
    
    let params = serde_json::json!({"name": "test"});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
    
    // 数字应失败
    let params = serde_json::json!({"name": 123});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
}
```

#### TC-METHOD-028: 使用默认参数填充
```rust
#[tokio::test]
async fn test_apply_default_parameters() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {
                "type": "number",
                "default": 25
            },
            "duration": {
                "type": "integer",
                "default": 60
            }
        }
    });
    
    let params = serde_json::json!({});
    let filled = apply_defaults(&schema, &params);
    
    assert_eq!(filled["temperature"], 25);
    assert_eq!(filled["duration"], 60);
}
```

#### TC-METHOD-029: 默认参数不覆盖显式值
```rust
#[tokio::test]
async fn test_defaults_do_not_override_explicit() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "temperature": {"type": "number", "default": 25}
        }
    });
    
    let params = serde_json::json!({"temperature": 50});
    let filled = apply_defaults(&schema, &params);
    
    assert_eq!(filled["temperature"], 50); // 不是默认的25
}
```

#### TC-METHOD-030: 复杂嵌套参数验证
```rust
#[tokio::test]
async fn test_validate_nested_parameters() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "config": {
                "type": "object",
                "properties": {
                    "timeout": {"type": "integer", "minimum": 0},
                    "retry": {"type": "integer", "minimum": 0, "maximum": 5}
                }
            }
        }
    });
    
    let params = serde_json::json!({
        "config": {
            "timeout": 30,
            "retry": 3
        }
    });
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
    
    // 嵌套参数超范围
    let params = serde_json::json!({
        "config": {
            "timeout": 30,
            "retry": 10
        }
    });
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
}
```

#### TC-METHOD-031: 数组类型参数验证
```rust
#[tokio::test]
async fn test_validate_array_parameters() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "devices": {
                "type": "array",
                "items": {"type": "string"}
            }
        }
    });
    
    let params = serde_json::json!({"devices": ["device1", "device2"]});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
    
    // 数组元素类型错误
    let params = serde_json::json!({"devices": [1, 2]});
    let result = validate_parameters(&schema, &params);
    assert!(result.is_err());
}
```

#### TC-METHOD-032: 空Schema允许任意参数
```rust
#[tokio::test]
async fn test_empty_schema_allows_anything() {
    let schema = serde_json::json!({});
    let params = serde_json::json!({"any": "value", "number": 123, "nested": {"a": 1}});
    
    let result = validate_parameters(&schema, &params);
    assert!(result.is_ok());
}
```

---

### 4.4 版本管理扩展点测试

#### TC-METHOD-040: 方法初始版本为1
```rust
#[tokio::test]
async fn test_method_initial_version() {
    let method = Method::new(
        "测试方法".to_string(),
        None,
        serde_json::json!({}),
        serde_json::json!({}),
        Uuid::new_v4(),
    );
    
    assert_eq!(method.version, 1);
}
```

#### TC-METHOD-041: 版本字段存在于数据库
```rust
#[tokio::test]
async fn test_method_version_stored_in_db() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "版本测试".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    let retrieved = repo.find_by_id(method.id).await.unwrap().unwrap();
    assert_eq!(retrieved.version, 1);
}
```

#### TC-METHOD-042: 版本更新预留扩展点
```rust
#[tokio::test]
async fn test_version_update_extension_point() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "版本测试".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    // 更新时版本应可更新（预留扩展点）
    let updated = repo.update_version(method.id, 2).await.unwrap();
    assert_eq!(updated.version, 2);
}
```

#### TC-METHOD-043: 版本号连续性验证
```rust
#[tokio::test]
async fn test_version_number_sequential() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "版本测试".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    // 模拟多次版本更新
    for v in 2..=5 {
        let updated = repo.update_version(method.id, v).await.unwrap();
        assert_eq!(updated.version, v);
    }
}
```

#### TC-METHOD-044: 版本历史查询扩展点
```rust
#[tokio::test]
async fn test_version_history_query_extension() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "版本历史".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    
    // 预留扩展点：版本历史查询接口存在
    // 注意：当前版本可能未实现完整历史功能，但接口应存在
    let versions = repo.list_versions(method.id).await;
    // 验证返回结果（即使为空列表也应成功）
    assert!(versions.is_ok());
}
```

#### TC-METHOD-045: 方法克隆创建新版本扩展点
```rust
#[tokio::test]
async fn test_method_clone_creates_new_version() {
    let original = Method::new(
        "原始方法".to_string(),
        Some("描述".to_string()),
        serde_json::json!({"steps": [{"type": "Start"}]}),
        serde_json::json!({"properties": {}}),
        Uuid::new_v4(),
    );
    
    // 预留扩展点：手动创建新版本（当前实现方式）
    let cloned = Method::new(
        original.name.clone(),
        original.description.clone(),
        original.process_definition.clone(),
        original.parameter_schema.clone(),
        original.created_by,
    );
    
    // 验证克隆方法保持相同内容但有不同ID
    assert_eq!(cloned.name, original.name);
    assert_eq!(cloned.description, original.description);
    assert_eq!(cloned.process_definition, original.process_definition);
    assert_eq!(cloned.parameter_schema, original.parameter_schema);
    assert_ne!(cloned.id, original.id); // 新ID
    assert_eq!(cloned.created_by, original.created_by);
}
```

---

### 4.5 API端点集成测试

#### TC-METHOD-050: POST /api/v1/methods - 创建方法
```rust
#[tokio::test]
async fn test_api_create_method() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    let request = CreateMethodRequest {
        name: "API测试方法".to_string(),
        description: Some("通过API创建".to_string()),
        process_definition: serde_json::json!({
            "steps": [{"type": "Start"}, {"type": "End"}]
        }),
        parameter_schema: serde_json::json!({
            "type": "object",
            "properties": {
                "temperature": {"type": "number", "default": 25}
            }
        }),
    };
    
    let body = serde_json::to_string(&request).unwrap();
    let response = app.post("/api/v1/methods", &token, body).await;
    
    assert_eq!(response.status(), StatusCode::CREATED);
    
    let body_bytes = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let api_response: SuccessResponse<MethodDto> = serde_json::from_slice(&body_bytes).unwrap();
    
    assert_eq!(api_response.data.name, "API测试方法");
    assert_eq!(api_response.data.version, 1);
    assert_eq!(api_response.code, 200);
}
```

#### TC-METHOD-051: POST /api/v1/methods - 无认证失败
```rust
#[tokio::test]
async fn test_api_create_method_unauthorized() {
    let app = create_test_app().await;
    
    let request = CreateMethodRequest {
        name: "测试方法".to_string(),
        description: None,
        process_definition: serde_json::json!({}),
        parameter_schema: serde_json::json!({}),
    };
    
    let body = serde_json::to_string(&request).unwrap();
    let response = app.post("/api/v1/methods", "", body).await;
    
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}
```

#### TC-METHOD-052: POST /api/v1/methods - 空名称失败
```rust
#[tokio::test]
async fn test_api_create_method_empty_name_fails() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    let request = CreateMethodRequest {
        name: "".to_string(),
        description: None,
        process_definition: serde_json::json!({}),
        parameter_schema: serde_json::json!({}),
    };
    
    let body = serde_json::to_string(&request).unwrap();
    let response = app.post("/api/v1/methods", &token, body).await;
    
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

#### TC-METHOD-053: GET /api/v1/methods - 列表查询
```rust
#[tokio::test]
async fn test_api_list_methods() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    // 创建多个方法
    for i in 0..5 {
        create_method_via_api(&app, &token, format!("方法{}", i)).await;
    }
    
    let response = app.get("/api/v1/methods?page=1&size=10", &token).await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body_bytes = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let api_response: SuccessResponse<PagedResponse<MethodDto>> = serde_json::from_slice(&body_bytes).unwrap();
    
    assert!(api_response.data.items.len() >= 5);
    assert_eq!(api_response.code, 200);
}
```

#### TC-METHOD-054: GET /api/v1/methods/{id} - 获取单个方法
```rust
#[tokio::test]
async fn test_api_get_method() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    let created = create_method_via_api(&app, &token, "待获取方法".to_string()).await;
    
    let path = format!("/api/v1/methods/{}", created.id);
    let response = app.get(&path, &token).await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body_bytes = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let api_response: SuccessResponse<MethodDto> = serde_json::from_slice(&body_bytes).unwrap();
    
    assert_eq!(api_response.data.id, created.id);
    assert_eq!(api_response.data.name, "待获取方法");
    assert_eq!(api_response.code, 200);
}
```

#### TC-METHOD-055: GET /api/v1/methods/{id} - 不存在返回404
```rust
#[tokio::test]
async fn test_api_get_method_not_found() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    let path = format!("/api/v1/methods/{}", Uuid::new_v4());
    let response = app.get(&path, &token).await;
    
    assert_eq!(response.status(), StatusCode::NOT_FOUND);
}
```

#### TC-METHOD-056: PUT /api/v1/methods/{id} - 更新方法
```rust
#[tokio::test]
async fn test_api_update_method() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    let created = create_method_via_api(&app, &token, "原名称".to_string()).await;
    
    let update_request = UpdateMethodRequest {
        name: Some("更新后名称".to_string()),
        description: None,
        process_definition: None,
        parameter_schema: None,
    };
    
    let body = serde_json::to_string(&update_request).unwrap();
    let path = format!("/api/v1/methods/{}", created.id);
    let response = app.put(&path, &token, body).await;
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body_bytes = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let api_response: SuccessResponse<MethodDto> = serde_json::from_slice(&body_bytes).unwrap();
    
    assert_eq!(api_response.data.name, "更新后名称");
    assert_eq!(api_response.code, 200);
}
```

#### TC-METHOD-057: DELETE /api/v1/methods/{id} - 删除方法
```rust
#[tokio::test]
async fn test_api_delete_method() {
    let app = create_test_app().await;
    let token = create_test_user_and_get_token().await;
    
    let created = create_method_via_api(&app, &token, "待删除".to_string()).await;
    
    let path = format!("/api/v1/methods/{}", created.id);
    let response = app.delete(&path, &token).await;
    
    assert_eq!(response.status(), StatusCode::NO_CONTENT);
    
    // 验证已删除
    let get_response = app.get(&path, &token).await;
    assert_eq!(get_response.status(), StatusCode::NOT_FOUND);
}
```

#### TC-METHOD-058: DELETE /api/v1/methods/{id} - 无权限删除他人方法失败
```rust
#[tokio::test]
async fn test_api_delete_method_no_permission() {
    let app = create_test_app().await;
    let token1 = create_test_user_and_get_token().await;
    let token2 = create_test_user_and_get_token().await;
    
    let created = create_method_via_api(&app, &token1, "用户1的方法".to_string()).await;
    
    // 用户2尝试删除用户1的方法
    let path = format!("/api/v1/methods/{}", created.id);
    let response = app.delete(&path, &token2).await;
    
    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}
```

---

### 4.6 边界情况与错误处理测试

#### TC-METHOD-060: JSON解析失败-无效JSON
```rust
#[tokio::test]
async fn test_invalid_json_process_definition() {
    // 无效JSON应该在API层被拒绝，不会到达验证函数
    // 这个测试验证API层正确处理无效JSON
    let app = create_test_app().await;
    let token = create_test_user_and_get_token(&app).await;
    
    // 直接发送无效JSON字符串到API
    let response = app.post("/api/v1/methods", &token, "invalid json".to_string()).await;
    
    // 应该返回400 Bad Request
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

#### TC-METHOD-061: 空过程定义
```rust
#[tokio::test]
async fn test_empty_process_definition() {
    let request = CreateMethodRequest {
        name: "测试方法".to_string(),
        description: None,
        process_definition: serde_json::json!({}),
        parameter_schema: serde_json::json!({}),
    };
    
    // 空对象应该被接受（作为有效JSON）
    let result = validate_method_request(&request);
    assert!(result.is_ok());
}
```

#### TC-METHOD-062: 超长方法名称
```rust
#[tokio::test]
async fn test_method_name_max_length() {
    let request = CreateMethodRequest {
        name: "A".repeat(256), // 超过255字符
        description: None,
        process_definition: serde_json::json!({}),
        parameter_schema: serde_json::json!({}),
    };
    
    let result = validate_method_request(&request);
    assert!(result.is_err());
}
```

#### TC-METHOD-063: 特殊字符在名称中
```rust
#[tokio::test]
async fn test_method_name_special_characters() {
    let request = CreateMethodRequest {
        name: "测试方法 (v1.0) - 示例".to_string(),
        description: None,
        process_definition: serde_json::json!({}),
        parameter_schema: serde_json::json!({}),
    };
    
    let result = validate_method_request(&request);
    assert!(result.is_ok());
}
```

#### TC-METHOD-064: 并发创建相同名称方法
```rust
#[tokio::test]
async fn test_concurrent_create_same_name() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let name = "并发测试方法".to_string();
    
    // 并发创建5个同名方法
    let results: Vec<Result<Method, _>> = futures::future::join_all(
        (0..5).map(|_| {
            let method = Method::new(
                name.clone(),
                None,
                serde_json::json!({}),
                serde_json::json!({}),
                user_id,
            );
            repo.create(&method)
        })
    ).await;
    
    // 应该全部成功（名称不作为唯一约束）
    let success_count = results.iter().filter(|r| r.is_ok()).count();
    assert_eq!(success_count, 5);
}
```

#### TC-METHOD-065: 数据库连接失败处理
```rust
#[tokio::test]
async fn test_database_connection_failure() {
    // 创建一个已关闭的连接池
    let pool = create_test_db().await;
    pool.close().await;
    
    let repo = SqlxMethodRepository::new(pool);
    let method = Method::new(
        "测试".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        Uuid::new_v4()
    );
    
    let result = repo.create(&method).await;
    assert!(result.is_err());
}
```

#### TC-METHOD-066: 更新已删除方法
```rust
#[tokio::test]
async fn test_update_deleted_method() {
    let pool = create_test_db().await;
    let repo = SqlxMethodRepository::new(pool);
    let user_id = Uuid::new_v4();
    
    let method = Method::new(
        "测试".to_string(), 
        None, 
        serde_json::json!({}), 
        serde_json::json!({}), 
        user_id
    );
    repo.create(&method).await.unwrap();
    repo.delete(method.id).await.unwrap();
    
    let result = repo.update(method.id, Some("新名称".to_string()), None, None, None).await;
    assert!(result.is_err());
}
```

#### TC-METHOD-067: 超大JSON过程定义
```rust
#[tokio::test]
async fn test_large_process_definition() {
    let large_steps: Vec<serde_json::Value> = (0..1000)
        .map(|i| {
            serde_json::json!({
                "type": "Delay",
                "name": format!("步骤{}", i),
                "duration_ms": 100 * i
            })
        })
        .collect();
    
    let process_def = serde_json::json!({
        "steps": large_steps,
        "metadata": {
            "total_steps": 1000,
            "estimated_duration_ms": 50000
        }
    });
    
    let json_str = serde_json::to_string(&process_def).unwrap();
    assert!(json_str.len() > 50000); // 验证确实是大对象
    
    let request = CreateMethodRequest {
        name: "大型过程定义".to_string(),
        description: None,
        process_definition: process_def,
        parameter_schema: serde_json::json!({}),
    };
    
    let result = validate_method_request(&request);
    assert!(result.is_ok());
}
```

---

## 5. 测试统计

| 类别 | 数量 | 优先级 |
|------|------|--------|
| 模型序列化测试 | 6 | P0 |
| Repository CRUD测试 | 12 | P0 |
| 参数Schema验证测试 | 11 | P0 |
| 版本管理扩展点测试 | 6 | P1 |
| API端点集成测试 | 9 | P0 |
| 边界情况与错误处理测试 | 8 | P1 |
| **总计** | **52** | |

---

## 6. 测试数据模板

### 6.1 标准过程定义模板

```json
{
  "steps": [
    {
      "type": "Start",
      "name": "开始试验",
      "duration_ms": 1000
    },
    {
      "type": "Read",
      "name": "预热读取",
      "device_id": "{{device_id}}",
      "point_ids": ["{{point_id}}"],
      "interval_ms": 500,
      "count": 10
    },
    {
      "type": "Control",
      "name": "设置目标值",
      "device_id": "{{device_id}}",
      "point_id": "{{control_point_id}}",
      "value": "{{target_value}}"
    },
    {
      "type": "Delay",
      "name": "等待稳定",
      "duration_ms": "{{stabilization_time}}"
    },
    {
      "type": "Read",
      "name": "数据采集",
      "device_id": "{{device_id}}",
      "point_ids": ["{{point_id}}"],
      "interval_ms": "{{sample_interval}}",
      "count": "{{sample_count}}"
    },
    {
      "type": "End",
      "name": "结束试验"
    }
  ]
}
```

### 6.2 标准参数Schema模板

```json
{
  "type": "object",
  "properties": {
    "temperature": {
      "type": "number",
      "minimum": -40,
      "maximum": 200,
      "default": 25,
      "description": "目标温度 (°C)"
    },
    "duration": {
      "type": "integer",
      "minimum": 1,
      "maximum": 7200,
      "default": 60,
      "description": "持续时间 (秒)"
    },
    "sample_interval": {
      "type": "integer",
      "minimum": 10,
      "maximum": 60000,
      "default": 1000,
      "description": "采样间隔 (毫秒)"
    },
    "enabled": {
      "type": "boolean",
      "default": true,
      "description": "是否启用该配置"
    }
  },
  "required": ["temperature", "duration"]
}
```

---

**文档结束**