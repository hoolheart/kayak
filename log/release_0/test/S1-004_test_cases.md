# S1-004 测试用例文档
## API路由与错误处理框架

**任务ID**: S1-004  
**任务名称**: API路由与错误处理框架  
**文档版本**: 1.0  
**创建日期**: 2026-03-15  
**测试类型**: 单元测试、集成测试、API测试  

---

## 1. 测试范围

### 1.1 测试目标
本文档覆盖 S1-004 任务的所有验收标准，确保API路由与错误处理框架实现正确，包括统一的API响应格式、路由分层结构、全局错误处理和请求验证中间件。

### 1.2 验收标准映射

| 验收标准 | 测试用例ID | 测试类型 |
|---------|-----------|---------|
| 1. 所有API返回统一JSON格式 `{code, message, data}` | TC-S1-004-01 ~ TC-S1-004-03 | 单元测试/集成测试 |
| 2. 错误响应包含标准错误码 | TC-S1-004-04 ~ TC-S1-004-06 | 单元测试/集成测试 |
| 3. 请求参数验证失败返回400错误 | TC-S1-004-07 ~ TC-S1-004-09 | 集成测试 |

---

## 2. 测试用例详情

### 2.1 API响应格式测试

#### TC-S1-004-01: ApiResponse<T> 序列化测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-01 |
| **测试名称** | ApiResponse 成功响应序列化测试 |
| **测试类型** | 单元测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证ApiResponse<T>结构体能够正确序列化为统一JSON格式 |

**测试目标:** `kayak-backend/src/core/error.rs` 中的 `ApiResponse<T>`

**前置条件:**
1. Rust项目编译通过
2. serde序列化库已正确配置

**测试步骤:**

1. 创建成功响应
   ```rust
   let response = ApiResponse::success(json!({"id": 1, "name": "test"}));
   ```

2. 序列化为JSON字符串
   ```rust
   let json_str = serde_json::to_string(&response).unwrap();
   ```

3. 解析并验证结构
   ```rust
   let json: Value = serde_json::from_str(&json_str).unwrap();
   ```

**预期结果:**

| 字段 | 预期值 | 类型 |
|-----|--------|------|
| code | 200 | number |
| message | "success" | string |
| data | {"id": 1, "name": "test"} | object |
| timestamp | 存在且非空 | string (ISO 8601) |

**通过标准:**
- [ ] JSON包含所有必需字段: code, message, data
- [ ] code 为 200
- [ ] message 为 "success"
- [ ] data 包含原始数据
- [ ] timestamp 为有效的ISO 8601格式时间戳

**自动化测试代码:**

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_api_response_success_serialization() {
        // Arrange
        let data = json!({"id": 1, "name": "test"});
        
        // Act
        let response = ApiResponse::success(data.clone());
        let json_str = serde_json::to_string(&response).unwrap();
        let json: serde_json::Value = serde_json::from_str(&json_str).unwrap();
        
        // Assert
        assert_eq!(json["code"], 200);
        assert_eq!(json["message"], "success");
        assert_eq!(json["data"], data);
        assert!(json["timestamp"].as_str().is_some());
        assert!(!json["timestamp"].as_str().unwrap().is_empty());
    }
}
```

---

#### TC-S1-004-02: ApiResponse 自定义消息测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-02 |
| **测试名称** | ApiResponse 自定义消息成功响应测试 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证ApiResponse支持自定义成功消息 |

**测试步骤:**

1. 创建带自定义消息的成功响应
   ```rust
   let response = ApiResponse::success_with_message(
       json!({"created": true}),
       "User created successfully"
   );
   ```

2. 验证响应格式

**预期结果:**

| 字段 | 预期值 |
|-----|--------|
| code | 200 |
| message | "User created successfully" |
| data.created | true |

**通过标准:**
- [ ] message 字段为自定义消息内容
- [ ] 其他字段保持正常

**自动化测试代码:**

```rust
#[test]
fn test_api_response_custom_message() {
    // Arrange
    let data = json!({"created": true});
    let custom_msg = "User created successfully";
    
    // Act
    let response = ApiResponse::success_with_message(data, custom_msg);
    let json: serde_json::Value = serde_json::to_value(&response).unwrap();
    
    // Assert
    assert_eq!(json["code"], 200);
    assert_eq!(json["message"], custom_msg);
    assert_eq!(json["data"]["created"], true);
}
```

---

#### TC-S1-004-03: ApiResponse::created 响应测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-03 |
| **测试名称** | ApiResponse 创建成功响应测试 (201) |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证ApiResponse支持201 Created状态码 |

**测试步骤:**

1. 创建201响应
   ```rust
   let response = ApiResponse::created(json!({"id": 123}));
   ```

**预期结果:**

| 字段 | 预期值 |
|-----|--------|
| code | 201 |
| message | "created" |
| data.id | 123 |

**通过标准:**
- [ ] code 为 201
- [ ] message 为 "created"
- [ ] timestamp 字段存在

**自动化测试代码:**

```rust
#[test]
fn test_api_response_created() {
    // Arrange
    let data = json!({"id": 123});
    
    // Act
    let response = ApiResponse::created(data);
    let json: serde_json::Value = serde_json::to_value(&response).unwrap();
    
    // Assert
    assert_eq!(json["code"], 201);
    assert_eq!(json["message"], "created");
    assert_eq!(json["data"]["id"], 123);
    assert!(json["timestamp"].is_string());
}
```

---

### 2.2 错误处理测试

#### TC-S1-004-04: AppError 到 HTTP 状态码映射测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-04 |
| **测试名称** | AppError 状态码映射测试 |
| **测试类型** | 单元测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证所有AppError变体映射到正确的HTTP状态码 |

**测试目标:** `kayak-backend/src/core/error.rs` 中的 `AppError::status_code()`

**测试步骤:**

1. 创建各类AppError实例
2. 调用 status_code() 方法
3. 验证返回的HTTP状态码

**测试数据表:**

| AppError变体 | 期望HTTP状态码 | 错误类别 |
|-------------|---------------|---------|
| BadRequest | 400 | 客户端错误 |
| Unauthorized | 401 | 客户端错误 |
| Forbidden | 403 | 客户端错误 |
| NotFound | 404 | 客户端错误 |
| MethodNotAllowed | 405 | 客户端错误 |
| RequestTimeout | 408 | 客户端错误 |
| Conflict | 409 | 客户端错误 |
| ValidationError | 422 | 客户端错误 |
| UnsupportedMediaType | 415 | 客户端错误 |
| PayloadTooLarge | 413 | 客户端错误 |
| CorsError | 403 | 客户端错误 |
| InternalError | 500 | 服务器错误 |
| DatabaseError | 500 | 服务器错误 |
| ConfigError | 500 | 服务器错误 |
| ExternalServiceError | 502 | 服务器错误 |
| ServiceUnavailable | 503 | 服务器错误 |
| GatewayTimeout | 504 | 服务器错误 |

**通过标准:**
- [ ] 所有4xx错误映射到正确的客户端错误状态码
- [ ] 所有5xx错误映射到正确的服务器错误状态码
- [ ] status_code() 方法返回 StatusCode 类型

**自动化测试代码:**

```rust
#[test]
fn test_app_error_status_code_mapping() {
    // 4xx 客户端错误
    assert_eq!(
        AppError::BadRequest("test".to_string()).status_code(),
        StatusCode::BAD_REQUEST
    );
    assert_eq!(
        AppError::Unauthorized("test".to_string()).status_code(),
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(
        AppError::Forbidden("test".to_string()).status_code(),
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        AppError::NotFound("test".to_string()).status_code(),
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        AppError::MethodNotAllowed.status_code(),
        StatusCode::METHOD_NOT_ALLOWED
    );
    assert_eq!(
        AppError::RequestTimeout.status_code(),
        StatusCode::REQUEST_TIMEOUT
    );
    assert_eq!(
        AppError::Conflict("test".to_string()).status_code(),
        StatusCode::CONFLICT
    );
    assert_eq!(
        AppError::ValidationError { fields: vec![] }.status_code(),
        StatusCode::UNPROCESSABLE_ENTITY
    );
    assert_eq!(
        AppError::UnsupportedMediaType.status_code(),
        StatusCode::UNSUPPORTED_MEDIA_TYPE
    );
    assert_eq!(
        AppError::PayloadTooLarge.status_code(),
        StatusCode::PAYLOAD_TOO_LARGE
    );
    assert_eq!(
        AppError::CorsError("test".to_string()).status_code(),
        StatusCode::FORBIDDEN
    );
    
    // 5xx 服务器错误
    assert_eq!(
        AppError::InternalError("test".to_string()).status_code(),
        StatusCode::INTERNAL_SERVER_ERROR
    );
    assert_eq!(
        AppError::DatabaseError("test".to_string()).status_code(),
        StatusCode::INTERNAL_SERVER_ERROR
    );
    assert_eq!(
        AppError::ConfigError("test".to_string()).status_code(),
        StatusCode::INTERNAL_SERVER_ERROR
    );
    assert_eq!(
        AppError::ExternalServiceError("test".to_string()).status_code(),
        StatusCode::BAD_GATEWAY
    );
    assert_eq!(
        AppError::ServiceUnavailable.status_code(),
        StatusCode::SERVICE_UNAVAILABLE
    );
    assert_eq!(
        AppError::GatewayTimeout.status_code(),
        StatusCode::GATEWAY_TIMEOUT
    );
}
```

---

#### TC-S1-004-05: 错误响应格式测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-05 |
| **测试名称** | 错误响应JSON格式测试 |
| **测试类型** | 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证错误响应符合统一JSON格式 `{code, message, details?, timestamp}` |

**测试步骤:**

1. 触发一个业务错误 (如 NotFound)
2. 将错误转换为响应
3. 验证响应JSON结构

**预期结果:**

| 字段 | 类型 | 必需 | 说明 |
|-----|------|------|------|
| code | number | 是 | HTTP状态码 (如 404) |
| message | string | 是 | 错误描述 |
| details | array | 否 | 字段级错误详情（仅ValidationError） |
| timestamp | string | 是 | ISO 8601格式时间戳 |

**通过标准:**
- [ ] 错误响应包含 code 字段（与HTTP状态码一致）
- [ ] 错误响应包含 message 字段
- [ ] 错误响应包含 timestamp 字段（ISO 8601格式）
- [ ] ValidationError 包含 details 字段（字段级错误数组）

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_error_response_format() {
    // Arrange
    let error = AppError::NotFound("User not found".to_string());
    
    // Act - 转换为响应
    let response = error.into_response();
    let body = axum::body::to_bytes(response.into_body(), usize::MAX).await.unwrap();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    
    // Assert
    assert!(json["code"].is_number());
    assert_eq!(json["code"], 404);
    assert!(json["message"].is_string());
    assert!(json["message"].as_str().unwrap().contains("User not found"));
    assert!(json["timestamp"].is_string());
}

#[tokio::test]
async fn test_validation_error_response_format() {
    // Arrange
    let fields = vec![
        FieldError::new("email", "Invalid email format"),
        FieldError::new("password", "Password too short"),
    ];
    let error = AppError::ValidationError { fields };
    
    // Act
    let response = error.into_response();
    let body = axum::body::to_bytes(response.into_body(), usize::MAX).await.unwrap();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    
    // Assert
    assert_eq!(json["code"], 422);
    assert!(json["details"].is_array());
    assert_eq!(json["details"].as_array().unwrap().len(), 2);
    assert_eq!(json["details"][0]["field"], "email");
    assert_eq!(json["details"][0]["message"], "Invalid email format");
}
```

---

#### TC-S1-004-06: 错误类型转换测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-06 |
| **测试名称** | 第三方错误到AppError转换测试 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证各类第三方错误能正确转换为AppError |

**测试覆盖的错误类型:**
- std::io::Error
- config::ConfigError
- serde_json::Error
- axum::extract::rejection::JsonRejection
- axum::extract::rejection::QueryRejection
- sqlx::Error

**测试步骤:**

1. 创建各类第三方错误
2. 调用 From 转换
3. 验证转换后的AppError类型

**通过标准:**
- [ ] io::Error 转换为 InternalError
- [ ] ConfigError 转换为 ConfigError
- [ ] serde_json::Error 转换为 BadRequest
- [ ] JsonRejection 转换为 BadRequest（带具体原因）
- [ ] QueryRejection 转换为 BadRequest
- [ ] sqlx::Error::RowNotFound 转换为 NotFound
- [ ] sqlx::Error 唯一约束冲突 转换为 Conflict
- [ ] sqlx::Error 连接池超时 转换为 ServiceUnavailable

**自动化测试代码:**

```rust
#[test]
fn test_io_error_conversion() {
    let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "file not found");
    let app_err: AppError = io_err.into();
    assert!(matches!(app_err, AppError::InternalError(_)));
}

#[test]
fn test_serde_json_error_conversion() {
    let json_err = serde_json::from_str::<serde_json::Value>("{invalid}").unwrap_err();
    let app_err: AppError = json_err.into();
    assert!(matches!(app_err, AppError::BadRequest(_)));
    assert!(app_err.to_string().contains("JSON"));
}

#[test]
fn test_sqlx_error_conversion() {
    // 模拟 RowNotFound
    let sqlx_err = sqlx::Error::RowNotFound;
    let app_err: AppError = sqlx_err.into();
    assert!(matches!(app_err, AppError::NotFound(_)));
}
```

---

### 2.3 请求验证测试

#### TC-S1-004-07: 字段验证错误测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-07 |
| **测试名称** | 请求参数字段验证测试 |
| **测试类型** | 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证请求参数验证失败返回422错误和字段级错误详情 |

**测试步骤:**

1. 定义带验证规则的请求DTO
2. 发送包含无效数据的请求
3. 验证响应

**测试数据:**

```json
{
  "email": "invalid-email",
  "password": "123",
  "age": -5
}
```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 422 |
| code | 422 |
| details | 数组，包含多个字段错误 |
| details[0].field | "email" |
| details[0].message | 包含"Invalid"或"邮箱" |

**通过标准:**
- [ ] 验证失败返回 HTTP 422
- [ ] 错误响应包含 details 数组
- [ ] 每个字段错误包含 field 和 message
- [ ] 所有无效字段都在 details 中报告

---

#### TC-S1-004-08: JSON解析错误测试 (400)

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-08 |
| **测试名称** | 无效JSON请求体测试 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证无效JSON请求返回400错误 |

**测试步骤:**

1. 发送包含无效JSON的请求
   ```bash
   curl -X POST http://localhost:8080/api/v1/test \
     -H "Content-Type: application/json" \
     -d "{invalid json}"
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 |
| code | 400 |
| message | 包含"JSON"或"parse" |

**通过标准:**
- [ ] 无效JSON返回 HTTP 400
- [ ] 错误消息说明JSON解析失败

---

#### TC-S1-004-09: 缺失Content-Type测试 (400)

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-09 |
| **测试名称** | 缺失JSON Content-Type测试 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证缺少Content-Type头时返回400错误 |

**测试步骤:**

1. 发送不带Content-Type头的JSON请求
   ```bash
   curl -X POST http://localhost:8080/api/v1/test \
     -d '{"test": "value"}'
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 |
| message | 包含"content type"或"Content-Type" |

**通过标准:**
- [ ] 缺失Content-Type返回 HTTP 400
- [ ] 错误消息提示缺少Content-Type

---

### 2.4 路由结构测试

#### TC-S1-004-10: API路由分层结构测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-10 |
| **测试名称** | API v1路由命名空间测试 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证API路由正确使用 /api/v1 前缀 |

**测试目标:** `kayak-backend/src/api/routes.rs` 中的路由定义

**测试步骤:**

1. 访问非API端点
   ```bash
   curl http://localhost:8080/health
   ```

2. 访问API端点（带v1前缀）
   ```bash
   curl http://localhost:8080/api/v1/some-endpoint
   ```

3. 验证路由组织

**预期结果:**

| 端点 | 预期响应 |
|-----|---------|
| /health | 200 OK (健康检查) |
| /api/v1/... | 按具体API实现响应 |

**通过标准:**
- [ ] 健康检查端点不在 /api/v1 命名空间下
- [ ] API路由使用 /api/v1 前缀
- [ ] 路由层级结构清晰

---

#### TC-S1-004-11: 404错误处理测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-11 |
| **测试名称** | 未找到资源错误处理测试 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证访问不存在端点时返回统一格式的404错误 |

**测试目标:** `kayak-backend/src/api/middleware/error.rs` 中的 `not_found_handler`

**测试步骤:**

1. 访问不存在的端点
   ```bash
   curl -s http://localhost:8080/api/v1/nonexistent-endpoint-xyz
   ```

2. 验证响应格式

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 404 |
| code | 404 |
| message | 包含"not found"或"未找到" |
| timestamp | 存在且为ISO 8601格式 |

**通过标准:**
- [ ] 返回 HTTP 404
- [ ] 错误响应格式统一（包含code, message, timestamp）
- [ ] 消息清晰说明资源未找到

---

### 2.5 中间件测试

#### TC-S1-004-12: 错误处理中间件日志记录测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-004-12 |
| **测试名称** | 错误处理中间件日志记录测试 |
| **测试类型** | 集成测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证错误处理中间件正确记录客户端和服务器错误 |

**测试目标:** `kayak-backend/src/api/middleware/error.rs` 中的 `error_handler`

**测试步骤:**

1. 触发一个服务器错误 (5xx)
2. 触发一个客户端错误 (4xx, 非404)
3. 检查日志输出

**预期结果:**

| 错误类型 | 日志级别 | 预期输出 |
|---------|---------|---------|
| 服务器错误 (5xx) | ERROR | 包含错误详情、请求路径、状态码 |
| 客户端错误 (4xx) | WARN | 包含警告信息、请求路径、状态码 |
| 404错误 | 无 | 不记录日志 |

**通过标准:**
- [ ] 服务器错误记录ERROR级别日志
- [ ] 客户端错误记录WARN级别日志
- [ ] 日志包含请求方法和路径
- [ ] 日志包含HTTP状态码

---

## 3. 集成测试场景

### 3.1 完整错误处理流程测试

**场景描述:** 验证从错误发生到响应返回的完整流程

**测试步骤:**

1. 启动后端服务
2. 发送触发各类错误的请求:
   - 无效JSON → 400
   - 不存在的资源 → 404
   - 无效参数 → 422
   - 无效端点 → 404
3. 验证所有错误响应格式统一
4. 检查日志记录

**预期结果:**
- 所有错误返回统一格式的JSON响应
- 状态码正确
- 服务器错误记录ERROR日志

---

### 3.2 路由中间件组合测试

**场景描述:** 验证多个中间件协同工作

**测试步骤:**

1. 发送正常请求，验证中间件链正常工作
2. 验证错误处理中间件捕获和处理错误
3. 验证响应格式中间件统一响应格式

**预期结果:**
- 正常请求正确响应
- 错误被正确捕获和转换
- 所有响应格式一致

---

## 4. 测试数据需求

### 4.1 环境要求

| 需求项 | 规格 |
|-------|------|
| Rust版本 | >= 1.75.0 |
| 后端服务 | 已启动并运行 |
| 可用端口 | 8080 |
| 依赖库 | serde, axum, tower-http, sqlx |

### 4.2 依赖工具

| 工具 | 用途 | 安装命令 |
|-----|------|---------|
| curl | API测试 | `apt install curl` |
| cargo | 测试执行 | Rust自带 |
| jq | JSON验证 | `apt install jq` |

---

## 5. 缺陷报告模板

### 5.1 缺陷严重程度定义

| 级别 | 定义 | 示例 |
|-----|------|------|
| P0 (Critical) | API响应格式不统一或错误处理失败 | 成功响应缺少code字段 |
| P1 (High) | 错误状态码映射错误或验证失败 | 400错误返回500状态码 |
| P2 (Medium) | 日志记录不完整或消息不清晰 | 错误日志缺少请求路径 |
| P3 (Low) | 代码风格或优化建议 | 错误消息格式不一致 |

### 5.2 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-004-XX  
**关联测试用例**: TC-S1-004-XX  
**严重程度**: [P0/P1/P2/P3]  
**发现日期**: YYYY-MM-DD  
**报告人**: [姓名]

### 问题描述
[详细描述问题现象]

### 复现步骤
1. [步骤1]
2. [步骤2]
3. [步骤3]

### 预期结果
[描述预期的正确行为]

### 实际结果
[描述实际观察到的行为]

### 环境信息
- Rust版本: [版本号]
- 后端版本: [commit hash]

### 附件
- [日志文件]
- [请求/响应示例]
```

---

## 6. 测试执行记录

### 6.1 执行历史

| 日期 | 版本 | 执行人 | 结果 | 备注 |
|-----|------|-------|------|------|
| | | | | |

### 6.2 测试覆盖矩阵

| 测试ID | 描述 | 执行次数 | 通过次数 | 失败次数 | 通过率 |
|-------|------|---------|---------|---------|-------|
| TC-S1-004-01 | ApiResponse成功响应序列化 | 0 | 0 | 0 | - |
| TC-S1-004-02 | ApiResponse自定义消息测试 | 0 | 0 | 0 | - |
| TC-S1-004-03 | ApiResponse创建响应测试 | 0 | 0 | 0 | - |
| TC-S1-004-04 | AppError状态码映射 | 0 | 0 | 0 | - |
| TC-S1-004-05 | 错误响应格式 | 0 | 0 | 0 | - |
| TC-S1-004-06 | 错误类型转换 | 0 | 0 | 0 | - |
| TC-S1-004-07 | 字段验证错误 | 0 | 0 | 0 | - |
| TC-S1-004-08 | JSON解析错误 | 0 | 0 | 0 | - |
| TC-S1-004-09 | 缺失Content-Type | 0 | 0 | 0 | - |
| TC-S1-004-10 | API路由分层 | 0 | 0 | 0 | - |
| TC-S1-004-11 | 404错误处理 | 0 | 0 | 0 | - |
| TC-S1-004-12 | 错误中间件日志 | 0 | 0 | 0 | - |

---

## 7. 附录

### 7.1 参考文档

- [Axum错误处理文档](https://docs.rs/axum/latest/axum/error_handling/index.html)
- [Serde序列化文档](https://serde.rs/)
- [Tower HTTP中间件](https://docs.rs/tower-http/)
- [S1-004设计文档](./design/S1-004_api_error_framework_design.md)

### 7.2 相关代码文件

| 文件路径 | 描述 |
|---------|------|
| `kayak-backend/src/core/error.rs` | 错误类型和响应结构定义 |
| `kayak-backend/src/api/routes.rs` | 路由定义 |
| `kayak-backend/src/api/middleware/error.rs` | 错误处理中间件 |

### 7.3 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|-------|---------|
| 1.0 | 2026-03-15 | QA | 初始版本 |

---

**文档结束**
