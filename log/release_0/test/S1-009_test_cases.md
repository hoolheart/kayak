# S1-009 测试用例文档
## JWT认证中间件 (JWT Authentication Middleware)

**任务ID**: S1-009  
**任务名称**: JWT认证中间件  
**文档版本**: 1.0  
**创建日期**: 2026-03-19  
**测试类型**: 单元测试、集成测试、安全测试

---

## 1. 测试范围

### 1.1 测试目标

本文档覆盖 S1-009 任务的所有验收标准，确保JWT认证中间件功能完整、安全可靠，包括：
- Token提取与解析（从Authorization头部）
- Token验证（签名、过期时间、声明）
- 用户上下文注入到请求中
- 错误处理（401 Unauthorized）
- 与Axum路由中间件集成

### 1.2 验收标准映射

| 验收标准 | 测试用例ID | 测试类型 |
|---------|-----------|---------|
| 1. 受保护API需要有效Token才能访问 | TC-S1-009-01, TC-S1-009-08 ~ TC-S1-009-12 | 集成测试/API测试 |
| 2. Token过期返回401错误 | TC-S1-009-03, TC-S1-009-13 | 单元测试/集成测试 |
| 3. 无效Token返回401错误 | TC-S1-009-02, TC-S1-009-04 ~ TC-S1-009-07 | 单元测试/集成测试 |

---

## 2. 测试用例详情

### 2.1 Token提取与解析测试

#### TC-S1-009-01: 有效Token验证成功

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-01 |
| **测试名称** | 有效Token验证成功 |
| **测试类型** | 单元测试 / 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用有效的Access Token可以成功通过中间件认证 |

**测试目标:** JWT认证中间件验证逻辑

**前置条件:**
1. 后端服务已启动并运行
2. JWT密钥已配置且与Token生成时使用的一致
3. 存在有效的Access Token（未过期、正确签名）

**测试步骤:**

1. 生成一个有效的Access Token
   ```rust
   let token = generate_test_access_token(user_id, email);
   ```

2. 构造包含Authorization头部的请求
   ```
   Authorization: Bearer <valid_token>
   ```

3. 发送请求到受保护端点
   ```bash
   curl -X GET http://localhost:8080/api/v1/user/profile \
     -H "Authorization: Bearer <valid_token>"
   ```

4. 验证中间件处理结果

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 200 OK | 请求通过认证 |
| 请求上下文 | 包含用户信息 | user_id和email已注入 |
| 处理器访问 | 可以获取到当前用户 | 处理器能读取到用户上下文 |

**通过标准:**
- [ ] 中间件成功验证Token
- [ ] 请求上下文中注入正确的用户ID
- [ ] 请求上下文中注入正确的用户邮箱
- [ ] 后续处理器可以访问到注入的用户信息
- [ ] 响应状态码为200（假设业务逻辑正常）

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_valid_token_authentication() {
    // Arrange
    let app = create_test_app().await;
    let user_id = Uuid::new_v4();
    let email = "test@example.com";
    let token = generate_test_access_token(user_id, email);
    
    // Act
    let response = app
        .get("/api/v1/user/profile")
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    // 验证处理器可以访问到用户信息
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["data"]["user_id"], user_id.to_string());
    assert_eq!(body["data"]["email"], email);
}
```

---

#### TC-S1-009-02: 缺少Authorization头部

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-02 |
| **测试名称** | 缺少Authorization头部处理 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证缺少Authorization头部时返回401错误 |

**前置条件:**
1. 后端服务已启动并运行
2. 请求端点需要JWT认证

**测试步骤:**

1. 发送请求时不带Authorization头部
   ```bash
   curl -X GET http://localhost:8080/api/v1/user/profile
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"Unauthorized"、"未授权"或"missing token" |
| WWW-Authenticate | Bearer（可选） |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 错误消息明确指示缺少认证信息
- [ ] 不暴露任何内部实现细节
- [ ] 请求不会到达业务处理器

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_missing_authorization_header() {
    // Arrange
    let app = create_test_app().await;
    
    // Act - 不带Authorization头部发送请求
    let response = app
        .get("/api/v1/user/profile")
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 401);
    assert!(body["message"].as_str().unwrap().to_lowercase().contains("unauthorized")
        || body["message"].as_str().unwrap().contains("未授权"));
}
```

---

#### TC-S1-009-03: Token过期处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-03 |
| **测试名称** | Token过期返回401错误 |
| **测试类型** | 单元测试 / 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证过期的Token被拒绝并返回401错误 |

**前置条件:**
1. 生成一个已经过期的Token
2. 后端服务正常运行

**测试步骤:**

1. 生成过期Token（exp设置为过去时间）
   ```rust
   let expired_token = generate_expired_token(user_id, email);
   ```

2. 使用过期Token发送请求
   ```bash
   curl -X GET http://localhost:8080/api/v1/user/profile \
     -H "Authorization: Bearer <expired_token>"
   ```

3. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"expired"、"过期"或"Token expired" |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 错误消息明确指出Token已过期
- [ ] 请求被阻止，不执行业务逻辑

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_expired_token_rejected() {
    // Arrange
    let app = create_test_app().await;
    let user_id = Uuid::new_v4();
    let email = "test@example.com";
    
    // 生成一个5分钟前过期的Token
    let expired_token = generate_token_with_exp(
        user_id, 
        email, 
        Utc::now() - Duration::minutes(5)
    );
    
    // Act
    let response = app
        .get("/api/v1/user/profile")
        .header("Authorization", format!("Bearer {}", expired_token))
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 401);
    let msg = body["message"].as_str().unwrap().to_lowercase();
    assert!(msg.contains("expired") || msg.contains("过期"));
}
```

---

#### TC-S1-009-04: 无效Token格式（非JWT格式）

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-04 |
| **测试名称** | 无效Token格式处理 |
| **测试类型** | 单元测试 / 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证非JWT格式的Token被拒绝 |

**测试数据表:**

| Token值 | 预期结果 | 说明 |
|---------|---------|------|
| `invalid-token` | 401 | 不是JWT格式 |
| `not.a.jwt` | 401 | 格式像JWT但内容无效 |
| `Bearer` | 401 | 只有前缀没有Token |
| `Bearer ` | 401 | 前缀后为空 |

**测试步骤:**

1. 使用各种无效Token格式发送请求
2. 验证每个请求的响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"Invalid token"或"token格式错误" |

**通过标准:**
- [ ] 所有无效格式的Token都被拒绝
- [ ] 返回一致的401错误
- [ ] 不泄露Token解析细节

---

#### TC-S1-009-05: 无效Token签名

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-05 |
| **测试名称** | Token签名验证失败 |
| **测试类型** | 单元测试 / 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用错误密钥签名的Token被拒绝 |

**测试步骤:**

1. 使用不同的密钥生成Token
   ```rust
   let wrong_key_token = generate_token_with_key(
       user_id, 
       email, 
       "wrong_secret_key"
   );
   ```

2. 使用错误签名的Token发送请求

3. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"Invalid token"或"签名验证失败" |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 签名验证失败不暴露使用的密钥信息
- [ ] 请求被阻止

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_invalid_token_signature() {
    // Arrange
    let app = create_test_app().await;
    let user_id = Uuid::new_v4();
    let email = "test@example.com";
    
    // 使用错误密钥生成Token
    let invalid_token = generate_token_with_key(
        user_id,
        email,
        "completely_wrong_secret_key_that_wont_match"
    );
    
    // Act
    let response = app
        .get("/api/v1/user/profile")
        .header("Authorization", format!("Bearer {}", invalid_token))
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 401);
}
```

---

#### TC-S1-009-06: Token声明缺失或无效

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-06 |
| **测试名称** | Token声明缺失或无效处理 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证缺少必需声明或声明值无效的Token被拒绝 |

**测试数据表:**

| 声明问题 | Token示例 | 预期结果 |
|---------|----------|---------|
| 缺少sub | 无用户ID的Token | 401 |
| 无效sub | sub不是有效UUID | 401 |
| 缺少email | 无email字段 | 401 |
| 无效token_type | type为"refresh"而非"access" | 401 |

**测试步骤:**

1. 构造各种声明有问题的Token
2. 验证每个Token的处理结果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 验证结果 | 所有无效Token都返回Err |
| 错误类型 | InvalidToken或InvalidTokenType |

**通过标准:**
- [ ] 缺少sub声明的Token被拒绝
- [ ] 无效UUID格式的sub被拒绝
- [ ] 使用Refresh Token作为Access Token被拒绝
- [ ] 返回明确的验证错误

**自动化测试代码:**

```rust
#[test]
fn test_token_with_missing_claims() {
    // Arrange
    let token_service = create_test_token_service();
    
    // 创建缺少sub的Token
    let token_without_sub = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
    
    // Act & Assert
    let result = token_service.verify_access_token(token_without_sub);
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), AuthError::InvalidToken));
}

#[test]
fn test_refresh_token_as_access_token() {
    // Arrange
    let token_service = create_test_token_service();
    let user_id = Uuid::new_v4();
    let email = "test@example.com";
    
    // 生成Refresh Token
    let pair = token_service.generate_token_pair(user_id, email).unwrap();
    
    // Act - 尝试用Refresh Token作为Access Token验证
    let result = token_service.verify_access_token(&pair.refresh_token);
    
    // Assert
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), AuthError::InvalidTokenType));
}
```

---

#### TC-S1-009-07: Bearer前缀处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-07 |
| **测试名称** | Bearer前缀处理 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证Authorization头部的Bearer前缀处理 |

**测试数据表:**

| Authorization头部值 | 预期结果 | 说明 |
|-------------------|---------|------|
| `Bearer <token>` | 200 | 标准格式 |
| `<token>` (无前缀) | 401 | 缺少Bearer前缀 |
| `bearer <token>` | 200或401 | 大小写敏感（根据实现） |
| `Basic <token>` | 401 | 错误的认证方案 |
| `Bearer<token>` (无空格) | 401 | 格式错误 |

**测试步骤:**

1. 使用不同的Authorization头部格式发送请求
2. 验证每种格式的响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 标准Bearer格式 | 200 OK |
| 无前缀或错误前缀 | 401 Unauthorized |
| 错误格式 | 401 Unauthorized |

**通过标准:**
- [ ] 标准`Bearer <token>`格式被正确解析
- [ ] 缺少Bearer前缀的请求被拒绝
- [ ] 使用错误的认证方案被拒绝

---

### 2.2 用户上下文注入测试

#### TC-S1-009-08: 用户上下文注入验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-08 |
| **测试名称** | 用户上下文注入验证 |
| **测试类型** | 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证成功认证后用户信息正确注入到请求上下文 |

**测试步骤:**

1. 创建有效的Access Token
2. 发送请求到测试端点（该端点返回当前用户信息）
3. 验证响应中包含正确的用户信息

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 注入的用户ID | 与Token中的sub一致 |
| 注入的用户邮箱 | 与Token中的email一致 |
| 处理器可访问 | 通过Extension提取用户信息 |

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_user_context_injection() {
    // Arrange
    let app = create_test_app().await;
    let user_id = Uuid::new_v4();
    let email = "test@example.com";
    let token = generate_test_access_token(user_id, email);
    
    // Act - 发送请求到返回当前用户信息的端点
    let response = app
        .get("/api/v1/auth/me")
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["data"]["id"], user_id.to_string());
    assert_eq!(body["data"]["email"], email);
}
```

---

#### TC-S1-009-09: 可选认证端点处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-09 |
| **测试名称** | 可选认证端点处理 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证某些端点可以不提供Token也能访问 |

**测试步骤:**

1. 发送请求到可选认证端点，不带Token
2. 验证响应
3. 使用有效Token发送请求到同一端点
4. 验证响应包含用户信息

**预期结果:**

| 检查项 | 不带Token | 带有效Token |
|-------|----------|------------|
| HTTP状态码 | 200 | 200 |
| 用户上下文 | None或默认值 | 包含用户信息 |
| 响应内容 | 公共数据 | 可能包含个性化数据 |

---

### 2.3 中间件集成测试

#### TC-S1-009-10: 中间件与Axum路由集成

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-10 |
| **测试名称** | 中间件与Axum路由集成 |
| **测试类型** | 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证中间件正确集成到Axum路由系统 |

**测试步骤:**

1. 创建带有认证中间件的路由
   ```rust
   Router::new()
       .route("/public", get(public_handler))
       .route("/protected", get(protected_handler))
       .route_layer(auth_middleware)
   ```

2. 测试公开端点（无需认证）
3. 测试受保护端点（需要认证）
4. 测试嵌套路由

**预期结果:**

| 端点 | 认证要求 | 不带Token | 带有效Token |
|-----|---------|----------|------------|
| /public | 无 | 200 | 200 |
| /protected | 有 | 401 | 200 |
| /nested/api | 有 | 401 | 200 |

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_middleware_routing_integration() {
    // Arrange
    let app = create_test_app_with_routes().await;
    let token = generate_test_access_token(Uuid::new_v4(), "test@example.com");
    
    // Act & Assert - 公开端点
    let response = app.get("/public").send().await;
    assert_eq!(response.status(), StatusCode::OK);
    
    // Act & Assert - 受保护端点无Token
    let response = app.get("/protected").send().await;
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    
    // Act & Assert - 受保护端点有Token
    let response = app
        .get("/protected")
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await;
    assert_eq!(response.status(), StatusCode::OK);
}
```

---

#### TC-S1-009-11: 多层中间件执行顺序

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-11 |
| **测试名称** | 多层中间件执行顺序 |
| **测试类型** | 集成测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证认证中间件在正确的时机执行 |

**测试步骤:**

1. 配置多层中间件栈
   ```rust
   router
       .layer(trace_layer)
       .layer(auth_layer)
       .layer(timeout_layer)
   ```

2. 发送无效Token请求
3. 验证中间件执行顺序和日志

**预期结果:**

| 检查项 | 预期行为 |
|-------|---------|
| 执行顺序 | 按Axum layer规则执行 |
| 认证失败 | 在请求到达业务逻辑前阻止 |
| 错误响应 | 正确通过错误处理中间件 |

---

### 2.4 错误处理与边界情况

#### TC-S1-009-12: Token篡改检测

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-12 |
| **测试名称** | Token篡改检测 |
| **测试类型** | 安全测试 / 单元测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证Token被篡改后被正确检测并拒绝 |

**测试数据表:**

| 篡改方式 | 示例 | 预期结果 |
|---------|------|---------|
| 修改payload | 更改user_id | 401 |
| 修改exp | 延长过期时间 | 401 |
| 删除签名 | 截断Token | 401 |
| 替换签名 | 使用其他Token的签名 | 401 |
| Base64解码修改 | 修改后重新编码 | 401 |

**测试步骤:**

1. 生成有效Token
2. 以各种方式篡改Token
3. 验证每个篡改Token都被拒绝

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| 错误类型 | InvalidToken |
| 信息泄露 | 不泄露篡改的具体方式 |

**自动化测试代码:**

```rust
#[test]
fn test_token_tampering_detection() {
    let token_service = create_test_token_service();
    let user_id = Uuid::new_v4();
    let pair = token_service.generate_token_pair(user_id, "test@example.com").unwrap();
    
    // 测试1: 修改payload中的user_id
    let mut parts: Vec<&str> = pair.access_token.split('.').collect();
    let mut payload = base64_decode(parts[1]);
    payload = payload.replace(&user_id.to_string(), &Uuid::new_v4().to_string());
    parts[1] = &base64_encode(&payload);
    let tampered_token = parts.join(".");
    
    let result = token_service.verify_access_token(&tampered_token);
    assert!(result.is_err());
    
    // 测试2: 延长过期时间
    // ... 类似测试
}
```

---

#### TC-S1-009-13: Token边缘时间处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-13 |
| **测试名称** | Token边缘时间处理 |
| **测试类型** | 单元测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证Token在过期边界的行为 |

**测试数据表:**

| 过期时间 | 相对于当前 | 预期结果 |
|---------|-----------|---------|
| exp = now + 1秒 | 1秒后过期 | 当前有效，1秒后无效 |
| exp = now - 1秒 | 1秒前过期 | 无效 |
| exp = now | 恰好现在 | 可能无效（实现依赖） |
| exp = i64::MAX | 永不过期 | 有效（但不推荐） |

**测试步骤:**

1. 生成不同过期时间的Token
2. 验证Token状态

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 即将过期的Token | 在过期前有效 |
| 刚刚过期的Token | 无效 |
| 长期Token | 有效 |

---

#### TC-S1-009-14: 并发请求处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-14 |
| **测试名称** | 并发Token验证请求处理 |
| **测试类型** | 性能测试 / 集成测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证中间件在高并发下正确处理Token验证 |

**测试步骤:**

1. 生成多个有效Token（模拟不同用户）
2. 并发发送100个请求
3. 验证所有请求的响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 成功率 | 100% |
| 响应时间 | < 100ms（平均值） |
| 无竞争条件 | 无数据竞争或panic |

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_concurrent_token_validation() {
    let app = create_test_app().await;
    let mut handles = vec![];
    
    for i in 0..100 {
        let token = generate_test_access_token(
            Uuid::new_v4(), 
            &format!("user{}@example.com", i)
        );
        let app_clone = app.clone();
        
        let handle = tokio::spawn(async move {
            app_clone
                .get("/api/v1/user/profile")
                .header("Authorization", format!("Bearer {}", token))
                .send()
                .await
        });
        handles.push(handle);
    }
    
    for handle in handles {
        let response = handle.await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }
}
```

---

#### TC-S1-009-15: 大负载Token处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-15 |
| **测试名称** | 大负载Token处理 |
| **测试类型** | 安全测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证系统对超大Token的处理 |

**测试步骤:**

1. 构造超大Authorization头部（>8KB）
2. 发送请求
3. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 401 |
| 无崩溃 | 系统正常响应 |
| 无内存泄漏 | 资源正确释放 |

---

### 2.5 单元测试场景

#### TC-S1-009-16: Token提取器单元测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-16 |
| **测试名称** | Token提取器单元测试 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 独立测试Token从Header的提取逻辑 |

**测试场景:**

| 输入 | 预期输出 |
|-----|---------|
| `Bearer token123` | Some("token123") |
| `bearer token123` | Some("token123") 或 None |
| `Bearer` | None |
| (空字符串) | None |
| `Basic dXNlcjpwYXNz` | None |

**自动化测试代码:**

```rust
#[test]
fn test_token_extraction() {
    // 有效Bearer token
    let result = extract_token("Bearer valid_token");
    assert_eq!(result, Some("valid_token"));
    
    // 缺少token
    let result = extract_token("Bearer ");
    assert_eq!(result, None);
    
    // 只有Bearer
    let result = extract_token("Bearer");
    assert_eq!(result, None);
    
    // 错误的scheme
    let result = extract_token("Basic dXNlcjpwYXNz");
    assert_eq!(result, None);
    
    // 空字符串
    let result = extract_token("");
    assert_eq!(result, None);
}
```

---

#### TC-S1-009-17: Token验证器单元测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-17 |
| **测试名称** | Token验证器单元测试 |
| **测试类型** | 单元测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 独立测试Token验证逻辑 |

**测试场景:**

| 场景 | 预期结果 |
|-----|---------|
| 有效Token | Ok(claims) |
| 过期Token | Err(TokenExpired) |
| 无效签名 | Err(InvalidToken) |
| 无效格式 | Err(InvalidToken) |
| 错误Token类型 | Err(InvalidTokenType) |

---

#### TC-S1-009-18: 用户上下文Extension测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-009-18 |
| **测试名称** | 用户上下文Extension测试 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 测试用户上下文在Axum Extension中的存取 |

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_user_context_extension() {
    use axum::extract::Extension;
    
    let user_context = UserContext {
        user_id: Uuid::new_v4(),
        email: "test@example.com".to_string(),
    };
    
    let handler = |Extension(ctx): Extension<UserContext>| async move {
        assert_eq!(ctx.email, "test@example.com");
        StatusCode::OK
    };
    
    let app = Router::new()
        .route("/test", get(handler))
        .layer(Extension(user_context));
    
    let response = app.get("/test").send().await;
    assert_eq!(response.status(), StatusCode::OK);
}
```

---

## 3. 安全测试场景

### 3.1 Token重放攻击防护

**场景描述:** 验证捕获的Token不能在被吊销或过期后继续使用

**测试步骤:**
1. 生成有效Token
2. 使用Token成功访问API
3. 等待Token过期
4. 再次使用同一Token

**通过标准:**
- [ ] 过期后的Token被拒绝
- [ ] 返回401错误

### 3.2 时钟回拨攻击防护

**场景描述:** 验证系统对客户端时钟回拨的防护

**测试步骤:**
1. 生成Token（有效期15分钟）
2. 客户端时钟回拨1小时
3. 发送请求

**通过标准:**
- [ ] 服务器以服务器时间为准验证Token
- [ ] Token仍按服务器时间过期

### 3.3 敏感信息泄露测试

**场景描述:** 验证错误响应不泄露敏感信息

**测试数据:**
| 场景 | 检查项 | 预期 |
|-----|--------|------|
| 无效Token | 响应内容 | 不包含内部实现细节 |
| 验证失败 | 错误消息 | 通用错误消息 |
| 调试模式 | 生产环境 | 不显示堆栈跟踪 |

---

## 4. 测试数据需求

### 4.1 环境要求

| 需求项 | 规格 |
|-------|------|
| Rust版本 | >= 1.75.0 |
| 后端服务 | 已启动并运行 |
| 数据库 | SQLite或PostgreSQL（可选） |
| JWT密钥 | 测试密钥已配置 |
| 可用端口 | 8080 |

### 4.2 测试辅助函数

```rust
/// 创建测试JWT Token
fn generate_test_access_token(user_id: Uuid, email: &str) -> String {
    let service = JwtTokenService::new(
        "test_access_secret".to_string(),
        "test_refresh_secret".to_string(),
    );
    service.generate_token_pair(user_id, email).unwrap().access_token
}

/// 生成过期Token
fn generate_expired_token(user_id: Uuid, email: &str) -> String {
    // 创建过去时间的Token
    generate_token_with_exp(user_id, email, Utc::now() - Duration::hours(1))
}

/// 生成指定过期时间的Token
fn generate_token_with_exp(user_id: Uuid, email: &str, exp: DateTime<Utc>) -> String {
    use jsonwebtoken::{encode, EncodingKey, Header};
    
    let claims = JwtClaims {
        sub: user_id.to_string(),
        email: email.to_string(),
        token_type: "access".to_string(),
        exp: exp.timestamp(),
        iat: (exp - Duration::hours(1)).timestamp(),
    };
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret("test_access_secret".as_bytes()),
    ).unwrap()
}

/// 创建带认证中间件的测试应用
async fn create_test_app_with_auth() -> TestApp {
    let app = create_test_app().await;
    // 配置认证中间件...
    app
}
```

### 4.3 测试Token数据

```json
{
  "valid_token": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@example.com",
    "expires_in": "15m"
  },
  "expired_token": {
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "email": "expired@example.com",
    "expired_at": "2024-01-01T00:00:00Z"
  },
  "invalid_tokens": [
    "invalid.token.format",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature",
    "not_a_jwt_at_all"
  ]
}
```

---

## 5. 测试执行记录

### 5.1 执行历史

| 日期 | 版本 | 执行人 | 结果 | 备注 |
|-----|------|-------|------|------|
| | | | | |

### 5.2 测试覆盖矩阵

| 测试ID | 描述 | 测试类型 | 执行次数 | 通过次数 | 失败次数 | 通过率 |
|-------|------|---------|---------|---------|---------|-------|
| TC-S1-009-01 | 有效Token验证成功 | 单元/集成 | 0 | 0 | 0 | - |
| TC-S1-009-02 | 缺少Authorization头部 | 集成 | 0 | 0 | 0 | - |
| TC-S1-009-03 | Token过期处理 | 单元/集成 | 0 | 0 | 0 | - |
| TC-S1-009-04 | 无效Token格式 | 单元/集成 | 0 | 0 | 0 | - |
| TC-S1-009-05 | 无效Token签名 | 单元/集成 | 0 | 0 | 0 | - |
| TC-S1-009-06 | Token声明缺失或无效 | 单元 | 0 | 0 | 0 | - |
| TC-S1-009-07 | Bearer前缀处理 | 集成 | 0 | 0 | 0 | - |
| TC-S1-009-08 | 用户上下文注入 | 集成 | 0 | 0 | 0 | - |
| TC-S1-009-09 | 可选认证端点 | 集成 | 0 | 0 | 0 | - |
| TC-S1-009-10 | 中间件路由集成 | 集成 | 0 | 0 | 0 | - |
| TC-S1-009-11 | 多层中间件顺序 | 集成 | 0 | 0 | 0 | - |
| TC-S1-009-12 | Token篡改检测 | 安全/单元 | 0 | 0 | 0 | - |
| TC-S1-009-13 | 边缘时间处理 | 单元 | 0 | 0 | 0 | - |
| TC-S1-009-14 | 并发请求处理 | 性能/集成 | 0 | 0 | 0 | - |
| TC-S1-009-15 | 大负载Token处理 | 安全 | 0 | 0 | 0 | - |
| TC-S1-009-16 | Token提取器单元测试 | 单元 | 0 | 0 | 0 | - |
| TC-S1-009-17 | Token验证器单元测试 | 单元 | 0 | 0 | 0 | - |
| TC-S1-009-18 | 用户上下文Extension | 单元 | 0 | 0 | 0 | - |

---

## 6. 缺陷报告模板

### 6.1 缺陷严重程度定义

| 级别 | 定义 | 示例 |
|-----|------|------|
| P0 (Critical) | 安全漏洞或核心功能失效 | Token验证被绕过、上下文注入失败 |
| P1 (High) | 主要功能缺陷 | 有效Token被拒绝、错误Token被接受 |
| P2 (Medium) | 次要功能缺陷 | 错误消息不清晰、边界情况处理不完善 |
| P3 (Low) | 优化建议 | 性能优化、日志完善 |

### 6.2 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-009-XX  
**关联测试用例**: TC-S1-009-XX  
**严重程度**: [P0/P1/P2/P3]  
**安全相关**: [是/否]  
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
- JWT库版本: [版本号]

### 附件
- [请求/响应示例]
- [日志文件]
```

---

## 7. 附录

### 7.1 参考文档

| 文档 | 说明 |
|------|------|
| [S1-008 用户注册与登录API测试](./S1-008_test_cases.md) | Token生成相关测试 |
| [JWT RFC 7519](https://tools.ietf.org/html/rfc7519) | JWT标准规范 |
| [Axum中间件文档](https://docs.rs/axum/latest/axum/middleware/index.html) | Axum中间件实现指南 |
| [Tower HTTP](https://docs.rs/tower-http/) | Tower HTTP中间件 |
| [jsonwebtoken crate](https://docs.rs/jsonwebtoken/) | JWT Rust库文档 |

### 7.2 相关代码文件

| 文件路径 | 描述 |
|---------|------|
| `kayak-backend/src/auth/middleware.rs` | JWT认证中间件（待实现） |
| `kayak-backend/src/auth/services.rs` | Token服务实现 |
| `kayak-backend/src/auth/traits.rs` | 认证相关trait定义 |
| `kayak-backend/src/api/middleware/mod.rs` | 中间件模块 |
| `kayak-backend/src/core/error.rs` | 错误类型定义 |

### 7.3 推荐实现结构

```rust
// kayak-backend/src/auth/middleware.rs

use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
    http::StatusCode,
};

/// 认证中间件
pub async fn auth_middleware<S>(
    State(token_service): State<Arc<dyn TokenService>>,
    mut request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // 1. 从Authorization头部提取Token
    let token = extract_bearer_token(&request)?;
    
    // 2. 验证Token
    let claims = token_service.verify_access_token(&token)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;
    
    // 3. 注入用户上下文到请求
    let user_context = UserContext {
        user_id: claims.sub,
        email: claims.email,
    };
    request.extensions_mut().insert(user_context);
    
    // 4. 继续处理请求
    Ok(next.run(request).await)
}

/// 从请求中提取Bearer Token
fn extract_bearer_token(request: &Request) -> Result<String, StatusCode> {
    let auth_header = request
        .headers()
        .get(http::header::AUTHORIZATION)
        .ok_or(StatusCode::UNAUTHORIZED)?;
    
    let auth_str = auth_header
        .to_str()
        .map_err(|_| StatusCode::UNAUTHORIZED)?;
    
    if !auth_str.starts_with("Bearer ") {
        return Err(StatusCode::UNAUTHORIZED);
    }
    
    let token = auth_str[7..].to_string();
    if token.is_empty() {
        return Err(StatusCode::UNAUTHORIZED);
    }
    
    Ok(token)
}

/// 用户上下文结构
#[derive(Debug, Clone)]
pub struct UserContext {
    pub user_id: Uuid,
    pub email: String,
}
```

### 7.4 测试执行优先级

| 优先级 | 测试ID范围 | 说明 |
|-------|-----------|------|
| 必须首先执行 | TC-S1-009-01 ~ TC-S1-009-08 | 核心功能测试 |
| 第二优先级 | TC-S1-009-09 ~ TC-S1-009-13 | 边界情况测试 |
| 第三优先级 | TC-S1-009-14 ~ TC-S1-009-18 | 性能与安全测试 |

### 7.5 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|-------|---------|
| 1.0 | 2026-03-19 | sw-mike | 初始版本创建 |

---

**文档结束**
