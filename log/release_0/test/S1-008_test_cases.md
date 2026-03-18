# S1-008 测试用例文档
## 用户注册与登录API (User Registration and Login API)

**任务ID**: S1-008  
**任务名称**: 用户注册与登录API  
**文档版本**: 1.0  
**创建日期**: 2026-03-18  
**测试类型**: 单元测试、集成测试、API测试、安全测试

---

## 1. 测试范围

### 1.1 测试目标

本文档覆盖 S1-008 任务的所有验收标准，确保用户注册与登录API功能完整、安全可靠，包括：
- 用户注册功能（邮箱+密码）
- 用户登录功能（JWT Token机制）
- 密码加密存储（bcrypt）
- Token生成与验证（Access Token + Refresh Token）
- 完整的错误处理

### 1.2 验收标准映射

| 验收标准 | 测试用例ID | 测试类型 |
|---------|-----------|---------|
| 1. POST /api/v1/auth/register 成功创建用户 | TC-S1-008-01 ~ TC-S1-008-04 | 单元测试/API测试 |
| 2. POST /api/v1/auth/login 返回JWT Token | TC-S1-008-05 ~ TC-S1-008-09 | 单元测试/API测试 |
| 3. 密码不以明文存储 | TC-S1-008-10 ~ TC-S1-008-12 | 安全测试/单元测试 |

---

## 2. 测试用例详情

### 2.1 用户注册API测试

#### TC-S1-008-01: 用户注册成功 - 基本流程

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-01 |
| **测试名称** | 用户注册成功 - 基本流程 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用有效邮箱和密码可以成功注册新用户 |

**测试目标:** `POST /api/v1/auth/register`

**前置条件:**
1. 后端服务已启动并运行
2. 数据库连接正常，users表已创建
3. 待注册的邮箱在数据库中不存在

**测试步骤:**

1. 发送注册请求
   ```bash
   curl -X POST http://localhost:8080/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "SecurePass123!",
       "username": "TestUser"
     }'
   ```

2. 验证HTTP响应状态码

3. 验证响应体结构

4. 验证数据库中用户记录

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 201 Created | 用户创建成功 |
| code | 201 | 响应码 |
| message | 包含"created"或"成功" | 成功消息 |
| data.user.id | 有效的UUID格式 | 新生成的用户ID |
| data.user.email | test@example.com | 注册的邮箱 |
| data.user.username | TestUser | 用户名 |
| data.user.status | "active" | 用户状态 |
| password_hash | 非明文，bcrypt格式 | 数据库中验证 |

**通过标准:**
- [ ] HTTP状态码为 201
- [ ] 响应包含用户ID、邮箱、用户名
- [ ] 响应中不包含password字段
- [ ] 数据库中密码以bcrypt哈希存储
- [ ] 数据库中记录包含created_at和updated_at时间戳

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_register_user_success() {
    // Arrange
    let app = create_test_app().await;
    let register_req = json!({
        "email": "test@example.com",
        "password": "SecurePass123!",
        "username": "TestUser"
    });
    
    // Act
    let response = app
        .post("/api/v1/auth/register")
        .json(&register_req)
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::CREATED);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 201);
    assert!(body["data"]["user"]["id"].is_string());
    assert_eq!(body["data"]["user"]["email"], "test@example.com");
    assert_eq!(body["data"]["user"]["username"], "TestUser");
    assert!(!body["data"]["user"].get("password").is_some());
    
    // 验证数据库
    let user = get_user_from_db("test@example.com").await;
    assert!(verify_bcrypt_hash(&user.password_hash));
}
```

---

#### TC-S1-008-02: 用户注册失败 - 邮箱已存在

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-02 |
| **测试名称** | 用户注册失败 - 邮箱已存在 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用已存在的邮箱注册时返回409冲突错误 |

**前置条件:**
1. 用户 `existing@example.com` 已在数据库中存在
2. 后端服务正常运行

**测试步骤:**

1. 准备已存在用户的注册请求
   ```json
   {
     "email": "existing@example.com",
     "password": "NewPass123!",
     "username": "NewUser"
   }
   ```

2. 发送注册请求

3. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 409 Conflict |
| code | 409 |
| message | 包含"already exists"、"已存在"或"conflict" |

**通过标准:**
- [ ] HTTP状态码为 409
- [ ] 错误消息清晰说明邮箱已存在
- [ ] 数据库中现有用户数据未被修改

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_register_duplicate_email() {
    // Arrange - 先创建一个用户
    let app = create_test_app().await;
    create_test_user("existing@example.com", "password123").await;
    
    let register_req = json!({
        "email": "existing@example.com",
        "password": "NewPass123!",
        "username": "NewUser"
    });
    
    // Act
    let response = app
        .post("/api/v1/auth/register")
        .json(&register_req)
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::CONFLICT);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 409);
    assert!(body["message"].as_str().unwrap().to_lowercase().contains("exists"));
}
```

---

#### TC-S1-008-03: 用户注册失败 - 无效的邮箱格式

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-03 |
| **测试名称** | 用户注册失败 - 无效的邮箱格式验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统拒绝无效的邮箱格式 |

**测试数据表:**

| 邮箱值 | 预期结果 | 说明 |
|--------|---------|------|
| invalid-email | 400 Bad Request | 缺少@符号 |
| @example.com | 400 Bad Request | 缺少本地部分 |
| user@ | 400 Bad Request | 缺少域名 |
| user@@example.com | 400 Bad Request | 双@符号 |
| user@example | 400 Bad Request | 无效域名 |
| user name@example.com | 400 Bad Request | 包含空格 |

**测试步骤:**

1. 使用每个无效邮箱发送注册请求
2. 验证响应状态码和错误信息

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| code | 400 或 422 |
| errors[0].field | "email" |
| errors[0].message | 包含"Invalid email"或"邮箱格式错误" |

**通过标准:**
- [ ] 所有无效邮箱格式都被拒绝
- [ ] 返回明确的验证错误信息
- [ ] 数据库中未创建任何用户记录

---

#### TC-S1-008-04: 用户注册失败 - 密码强度不足

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-04 |
| **测试名称** | 用户注册失败 - 密码强度验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统拒绝不符合强度要求的密码 |

**测试数据表:**

| 密码值 | 预期结果 | 原因 |
|--------|---------|------|
| short | 400/422 | 太短 (< 8字符) |
| 12345678 | 400/422 | 全数字，无字母 |
| password | 400/422 | 太简单，常用词 |
| PASSWORD | 400/422 | 太简单，全大写 |
| (空字符串) | 400/422 | 空密码 |

**测试步骤:**

1. 使用每个弱密码发送注册请求
2. 验证响应状态码和错误信息

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| code | 400 或 422 |
| errors[0].field | "password" |
| errors[0].message | 包含密码强度要求说明 |

**通过标准:**
- [ ] 所有弱密码都被拒绝
- [ ] 返回明确的密码要求说明
- [ ] 满足最小长度要求（建议≥8字符）

---

#### TC-S1-008-05: 用户注册失败 - 缺少必填字段

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-05 |
| **测试名称** | 用户注册失败 - 缺少必填字段 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统要求所有必填字段 |

**测试数据:**

| 请求体 | 缺失字段 |
|--------|---------|
| `{"password": "pass123"}` | email |
| `{"email": "test@example.com"}` | password |
| `{}` | email, password |
| `{"email": "", "password": "pass123"}` | email (空值) |

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| code | 400 或 422 |
| errors | 包含缺失字段的验证错误 |

**通过标准:**
- [ ] 所有必填字段缺失场景都被拒绝
- [ ] 返回详细的字段级错误信息
- [ ] 多条验证错误同时返回

---

### 2.2 用户登录API测试

#### TC-S1-008-06: 用户登录成功 - 返回JWT Token

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-06 |
| **测试名称** | 用户登录成功 - 返回JWT Token |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用正确的邮箱和密码可以成功登录并获取JWT Token |

**测试目标:** `POST /api/v1/auth/login`

**前置条件:**
1. 用户 `login@example.com` 已在数据库中存在，密码为 `CorrectPass123!`
2. 后端服务正常运行
3. JWT密钥已配置

**测试步骤:**

1. 发送登录请求
   ```bash
   curl -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "login@example.com",
       "password": "CorrectPass123!"
     }'
   ```

2. 验证响应状态码

3. 验证响应体包含Token

4. 验证Token格式和结构

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 200 OK | 登录成功 |
| code | 200 | 响应码 |
| data.access_token | 有效的JWT字符串 | 包含header.payload.signature |
| data.refresh_token | 有效的JWT字符串 | 刷新Token |
| data.expires_in | 数字 (如 3600) | Access Token过期时间（秒） |
| data.token_type | "Bearer" | Token类型 |
| data.user.id | 用户UUID | 用户ID |
| data.user.email | login@example.com | 用户邮箱 |

**通过标准:**
- [ ] HTTP状态码为 200
- [ ] 响应包含 access_token 和 refresh_token
- [ ] Access Token格式正确（三段base64）
- [ ] Token可以被成功解码验证
- [ ] 响应中包含用户信息（不含敏感字段）
- [ ] 响应中不包含password_hash

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_login_success() {
    // Arrange
    let app = create_test_app().await;
    let password = "CorrectPass123!";
    let email = "login@example.com";
    create_test_user_with_password(email, password).await;
    
    let login_req = json!({
        "email": email,
        "password": password
    });
    
    // Act
    let response = app
        .post("/api/v1/auth/login")
        .json(&login_req)
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 200);
    
    // 验证Token结构
    let access_token = body["data"]["access_token"].as_str().unwrap();
    assert!(is_valid_jwt_format(access_token));
    
    let refresh_token = body["data"]["refresh_token"].as_str().unwrap();
    assert!(is_valid_jwt_format(refresh_token));
    
    // 验证Token可解码
    let claims = decode_jwt(access_token).unwrap();
    assert_eq!(claims.sub, email);
    
    // 验证不包含敏感信息
    assert!(!body["data"].get("password").is_some());
    assert!(!body["data"].get("password_hash").is_some());
}
```

---

#### TC-S1-008-07: 用户登录失败 - 邮箱不存在

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-07 |
| **测试名称** | 用户登录失败 - 邮箱不存在 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证使用不存在的邮箱登录时返回401错误 |

**前置条件:**
1. 邮箱 `nonexistent@example.com` 在数据库中不存在
2. 后端服务正常运行

**测试步骤:**

1. 发送登录请求
   ```json
   {
     "email": "nonexistent@example.com",
     "password": "SomePass123!"
   }
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"Invalid credentials"、"认证失败"或类似（不暴露邮箱是否存在） |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 错误消息不泄露用户是否存在的信息
- [ ] 响应时间与存在用户时相近（防止时序攻击）

---

#### TC-S1-008-08: 用户登录失败 - 密码错误

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-08 |
| **测试名称** | 用户登录失败 - 密码错误 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用错误的密码登录时返回401错误 |

**前置条件:**
1. 用户 `user@example.com` 存在，实际密码为 `CorrectPass123!`
2. 后端服务正常运行

**测试步骤:**

1. 使用错误密码发送登录请求
   ```json
   {
     "email": "user@example.com",
     "password": "WrongPass123!"
   }
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"Invalid credentials"、"认证失败"或类似 |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 错误消息不泄露是邮箱不存在还是密码错误
- [ ] 不返回Token

---

#### TC-S1-008-09: 用户登录失败 - 缺少必填字段

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-09 |
| **测试名称** | 用户登录失败 - 缺少必填字段 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证登录请求需要邮箱和密码 |

**测试数据:**

| 请求体 | 预期结果 |
|--------|---------|
| `{"email": "test@example.com"}` | 400/422 |
| `{"password": "pass123"}` | 400/422 |
| `{}` | 400/422 |

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| errors | 包含缺失字段的验证错误 |

---

### 2.3 JWT Token生成与验证测试

#### TC-S1-008-10: Access Token结构与内容验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-10 |
| **测试名称** | Access Token结构与内容验证 |
| **测试类型** | 单元测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证生成的Access Token结构正确、声明完整 |

**测试目标:** JWT Token生成逻辑

**测试步骤:**

1. 调用Token生成函数
2. 解码Token验证结构
3. 验证各声明字段

**预期结果:**

| 声明字段 | 预期值 | 说明 |
|---------|--------|------|
| header.alg | "HS256" | 签名算法 |
| header.typ | "JWT" | Token类型 |
| payload.sub | 用户ID或邮箱 | 主题/用户标识 |
| payload.iss | "kayak-api" | 签发者 |
| payload.aud | "kayak-client" | 接收者 |
| payload.iat | 当前时间戳 | 签发时间 |
| payload.exp | iat + expires_in | 过期时间 |
| payload.jti | UUID | Token唯一标识 |
| payload.type | "access" | Token类型标识 |

**通过标准:**
- [ ] Token格式为三段base64url编码，用`.`分隔
- [ ] 所有必需声明字段存在且有效
- [ ] exp时间大于iat时间
- [ ] 签名可以验证

**自动化测试代码:**

```rust
#[test]
fn test_access_token_structure() {
    // Arrange
    let user_id = Uuid::new_v4();
    let email = "test@example.com";
    let jwt_config = JwtConfig {
        secret: "test-secret".to_string(),
        access_token_expires: 3600,
        refresh_token_expires: 86400 * 7,
    };
    
    // Act
    let token = generate_access_token(user_id, email, &jwt_config).unwrap();
    
    // Assert
    let parts: Vec<&str> = token.split('.').collect();
    assert_eq!(parts.len(), 3);
    
    // 解码Header
    let header_json = base64_decode(parts[0]);
    let header: JwtHeader = serde_json::from_str(&header_json).unwrap();
    assert_eq!(header.alg, "HS256");
    assert_eq!(header.typ, "JWT");
    
    // 解码Payload
    let payload_json = base64_decode(parts[1]);
    let claims: TokenClaims = serde_json::from_str(&payload_json).unwrap();
    assert_eq!(claims.sub, user_id.to_string());
    assert_eq!(claims.iss, "kayak-api");
    assert_eq!(claims.aud, "kayak-client");
    assert_eq!(claims.token_type, "access");
    assert!(claims.exp > claims.iat);
    assert!(!claims.jti.is_empty());
}
```

---

#### TC-S1-008-11: Refresh Token结构与验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-11 |
| **测试名称** | Refresh Token结构与验证 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证生成的Refresh Token结构正确、过期时间更长 |

**预期结果:**

| 声明字段 | 预期值 | 说明 |
|---------|--------|------|
| payload.exp | iat + 7天 (或更长) | 比Access Token长 |
| payload.type | "refresh" | 标识为Refresh Token |
| payload.sub | 用户ID | 关联用户 |
| payload.jti | UUID | 唯一标识，用于撤销 |

**通过标准:**
- [ ] Refresh Token过期时间比Access Token长（建议7天或更长）
- [ ] type字段为"refresh"
- [ ] 可以用Refresh Token获取新的Access Token

---

#### TC-S1-008-12: Token过期验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-12 |
| **测试名称** | Token过期验证 |
| **测试类型** | 单元测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证过期Token被拒绝 |

**测试步骤:**

1. 生成一个立即过期的Token（exp为过去时间）
2. 尝试验证该Token
3. 验证验证失败

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 验证结果 | Error(TokenExpired) |
| 错误消息 | 包含"expired"或"过期" |

**通过标准:**
- [ ] 过期Token验证失败
- [ ] 返回明确的过期错误
- [ ] 在过期边缘的Token行为一致

**自动化测试代码:**

```rust
#[test]
fn test_expired_token_validation() {
    // Arrange - 创建一个已过期5分钟的Token
    let claims = TokenClaims {
        sub: "user-123".to_string(),
        iss: "kayak-api".to_string(),
        aud: "kayak-client".to_string(),
        iat: (Utc::now() - Duration::hours(2)).timestamp(),
        exp: (Utc::now() - Duration::minutes(5)).timestamp(),
        jti: Uuid::new_v4().to_string(),
        token_type: "access".to_string(),
    };
    
    let expired_token = generate_token_with_claims(&claims, &JWT_SECRET);
    
    // Act
    let result = validate_access_token(&expired_token, &JWT_SECRET);
    
    // Assert
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), JwtError::ExpiredSignature));
}
```

---

#### TC-S1-008-13: Token签名验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-13 |
| **测试名称** | Token签名验证 |
| **测试类型** | 单元测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证Token签名防止篡改 |

**测试数据表:**

| 篡改方式 | 预期结果 | 说明 |
|---------|---------|------|
| 修改payload中的sub字段 | 验证失败 | 篡改了用户ID |
| 修改payload中的exp字段 | 验证失败 | 试图延长过期时间 |
| 使用不同密钥签名 | 验证失败 | 密钥不匹配 |
| 截断签名部分 | 验证失败 | 格式错误 |

**通过标准:**
- [ ] 所有篡改的Token验证都失败
- [ ] 返回明确的签名错误
- [ ] 原始Token验证通过

---

#### TC-S1-008-14: Refresh Token换取Access Token

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-14 |
| **测试名称** | Refresh Token换取新Access Token |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证使用有效的Refresh Token可以获取新的Access Token |

**测试目标:** `POST /api/v1/auth/refresh`

**前置条件:**
1. 用户已登录，拥有有效的Refresh Token
2. Refresh Token未过期

**测试步骤:**

1. 发送刷新请求
   ```bash
   curl -X POST http://localhost:8080/api/v1/auth/refresh \
     -H "Content-Type: application/json" \
     -d '{
       "refresh_token": "valid.refresh.token"
     }'
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 200 OK |
| data.access_token | 新的Access Token |
| data.refresh_token | 新的Refresh Token（或原Token） |
| data.expires_in | Token有效期 |

**通过标准:**
- [ ] 返回新的Access Token
- [ ] 新的Token与原Token不同
- [ ] 新的Token有效且可解码

---

#### TC-S1-008-15: 无效的Refresh Token

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-15 |
| **测试名称** | 无效的Refresh Token处理 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统拒绝无效的Refresh Token |

**测试数据表:**

| Refresh Token值 | 预期结果 | 说明 |
|----------------|---------|------|
| 过期Token | 401 | Token已过期 |
| 无效签名Token | 401 | 签名验证失败 |
| 已撤销Token | 401 | Token已被列入黑名单 |
| 非Refresh类型Token | 401 | 使用了Access Token |
| 格式错误Token | 400/401 | 不是有效的JWT格式 |

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 或 400 |
| message | 包含"invalid"、"expired"或"无效" |

---

### 2.4 密码加密测试

#### TC-S1-008-16: 密码bcrypt哈希验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-16 |
| **测试名称** | 密码bcrypt哈希验证 |
| **测试类型** | 单元测试 / 安全测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证密码使用bcrypt正确哈希存储，不存储明文 |

**测试目标:** 密码哈希生成和验证逻辑

**测试步骤:**

1. 生成bcrypt哈希
2. 验证哈希格式
3. 验证原始密码匹配
4. 验证错误密码不匹配

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| 哈希格式 | $2b$[cost]$[salt+hash] | bcrypt标准格式 |
| 哈希长度 | 60字符 | bcrypt标准长度 |
| 明文存储 | 不存在 | 数据库中无password列 |
| 相同密码不同哈希 | 是 | bcrypt自动加盐 |
| cost因子 | ≥12 | 建议的工作因子 |

**通过标准:**
- [ ] 所有密码都以bcrypt哈希存储
- [ ] 哈希格式符合bcrypt标准
- [ ] 正确密码验证通过
- [ ] 错误密码验证失败
- [ ] 相同密码每次生成的哈希不同（随机盐）

**自动化测试代码:**

```rust
#[test]
fn test_password_bcrypt_hashing() {
    // Arrange
    let password = "MySecurePassword123!";
    
    // Act - 生成哈希
    let hash1 = bcrypt_hash(password).unwrap();
    let hash2 = bcrypt_hash(password).unwrap();
    
    // Assert - 格式验证
    assert!(hash1.starts_with("$2b$"));
    assert_eq!(hash1.len(), 60);
    
    // 相同密码，不同哈希（因为随机盐）
    assert_ne!(hash1, hash2);
    
    // 正确密码验证通过
    assert!(bcrypt_verify(password, &hash1).unwrap());
    assert!(bcrypt_verify(password, &hash2).unwrap());
    
    // 错误密码验证失败
    assert!(!bcrypt_verify("WrongPassword", &hash1).unwrap());
    
    // cost因子验证
    let cost = bcrypt::DEFAULT_COST;
    assert!(cost >= 12);
}
```

---

#### TC-S1-008-17: 数据库中无密码明文存储

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-17 |
| **测试名称** | 数据库中无密码明文存储验证 |
| **测试类型** | 安全测试 / 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证数据库中不存在明文密码 |

**测试步骤:**

1. 注册一个新用户，密码为 `TestPassword123!`
2. 直接查询数据库中的用户记录
3. 验证存储的密码字段

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 数据库表结构 | 只有password_hash列 |
| password_hash值 | 60字符bcrypt哈希 |
| 明文搜索 | 找不到"TestPassword123!" |

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_no_plaintext_password_in_db() {
    // Arrange
    let app = create_test_app().await;
    let password = "TestPassword123!";
    let email = "security@example.com";
    
    // Act - 注册用户
    let register_req = json!({
        "email": email,
        "password": password,
        "username": "SecurityTest"
    });
    
    app.post("/api/v1/auth/register")
        .json(&register_req)
        .send()
        .await;
    
    // Assert - 直接查询数据库
    let row: (String,) = sqlx::query_as(
        "SELECT password_hash FROM users WHERE email = ?"
    )
    .bind(email)
    .fetch_one(&app.db_pool)
    .await
    .unwrap();
    
    let stored_hash = row.0;
    
    // 验证不是明文
    assert_ne!(stored_hash, password);
    
    // 验证是bcrypt格式
    assert!(stored_hash.starts_with("$2b$"));
    assert_eq!(stored_hash.len(), 60);
    
    // 验证可以解密（密码正确）
    assert!(bcrypt_verify(password, &stored_hash).unwrap());
}
```

---

#### TC-S1-008-18: API响应中不包含密码

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-18 |
| **测试名称** | API响应中不包含密码信息 |
| **测试类型** | 安全测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证所有API响应都不包含密码或密码哈希 |

**测试范围:**
- 注册API响应
- 登录API响应
- 用户信息API响应
- 错误响应

**预期结果:**

| API端点 | 检查项 | 预期值 |
|---------|-------|--------|
| POST /register | 响应体中password字段 | 不存在 |
| POST /register | 响应体中password_hash字段 | 不存在 |
| POST /login | 响应体中password字段 | 不存在 |
| POST /login | 响应体中password_hash字段 | 不存在 |
| GET /me | 响应体中password_hash字段 | 不存在 |

---

### 2.5 错误处理测试

#### TC-S1-008-19: 无效的JSON请求体

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-19 |
| **测试名称** | 无效的JSON请求体处理 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统正确处理无效的JSON请求 |

**测试数据:**

| 请求体 | Content-Type | 预期结果 |
|--------|-------------|---------|
| `{invalid json}` | application/json | 400 Bad Request |
| (空) | application/json | 400 Bad Request |
| `{"email": "test"` | application/json | 400 Bad Request |
| 有效JSON | (missing) | 400 Bad Request |

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 |
| message | 包含"JSON"、"parse"或"格式" |

---

#### TC-S1-008-20: 过长的输入字段

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-008-20 |
| **测试名称** | 过长的输入字段处理 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证系统对超长输入的边界处理 |

**测试数据:**

| 字段 | 测试值长度 | 预期结果 |
|------|-----------|---------|
| email | 256+字符 | 400/422 |
| password | 128+字符 | 400/422 |
| username | 100+字符 | 400/422 |

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| 无崩溃/异常 | 系统正常响应 |

---

## 3. 安全测试场景

### 3.1 SQL注入防护测试

**场景描述:** 尝试在输入中注入SQL代码

**测试数据:**

| 字段 | 注入尝试 | 预期结果 |
|------|---------|---------|
| email | `' OR '1'='1` | 被拒绝，作为普通字符串处理 |
| email | `test@example.com'; DROP TABLE users; --` | 被拒绝 |
| password | `' OR 1=1 --` | 被拒绝 |

**通过标准:**
- [ ] 所有注入尝试都被安全处理
- [ ] 数据库结构未被破坏
- [ ] 返回预期的验证错误

### 3.2 时序攻击防护测试

**场景描述:** 验证系统对时序攻击的防护

**测试步骤:**

1. 使用存在的邮箱和错误密码登录，记录响应时间
2. 使用不存在的邮箱登录，记录响应时间
3. 比较两次响应时间差异

**通过标准:**
- [ ] 两次响应时间差异 < 50ms（或统计上不显著）
- [ ] 不会泄露用户是否存在的信息

### 3.3 暴力破解防护

**场景描述:** 测试系统对暴力破解攻击的防护能力

**测试步骤:**

1. 对同一邮箱快速发送多个错误密码的登录请求（如10次/秒）
2. 观察系统响应

**预期结果:**

| 检查项 | 预期行为 |
|-------|---------|
| 速率限制 | 在N次失败后启用延迟或锁定 |
| 错误响应 | 仍然返回401，但响应变慢 |
| 账户锁定（可选） | 在多次失败后暂时锁定账户 |

---

## 4. 测试数据需求

### 4.1 环境要求

| 需求项 | 规格 |
|-------|------|
| Rust版本 | >= 1.75.0 |
| 后端服务 | 已启动并运行 |
| 数据库 | SQLite或PostgreSQL（测试用） |
| JWT密钥 | 已配置测试密钥 |
| 可用端口 | 8080 |

### 4.2 依赖工具

| 工具 | 用途 | 安装命令 |
|-----|------|---------|
| curl | API测试 | `apt install curl` |
| cargo | 测试执行 | Rust自带 |
| jq | JSON验证 | `apt install jq` |
| bc（可选） | 时序测试 | `apt install bc` |

### 4.3 测试用户数据

```json
{
  "valid_users": [
    {
      "email": "test1@example.com",
      "password": "SecurePass123!",
      "username": "TestUser1"
    },
    {
      "email": "test2@example.com",
      "password": "AnotherPass456!",
      "username": "TestUser2"
    }
  ],
  "invalid_emails": [
    "invalid-email",
    "@example.com",
    "user@",
    "user@@example.com"
  ],
  "weak_passwords": [
    "short",
    "12345678",
    "password",
    "PASSWORD"
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
| TC-S1-008-01 | 用户注册成功 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-02 | 邮箱已存在 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-03 | 无效邮箱格式 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-04 | 密码强度不足 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-05 | 缺少必填字段 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-06 | 登录成功 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-07 | 邮箱不存在 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-08 | 密码错误 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-09 | 登录缺少字段 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-10 | Access Token结构 | 单元测试 | 0 | 0 | 0 | - |
| TC-S1-008-11 | Refresh Token结构 | 单元测试 | 0 | 0 | 0 | - |
| TC-S1-008-12 | Token过期验证 | 单元测试 | 0 | 0 | 0 | - |
| TC-S1-008-13 | Token签名验证 | 单元测试 | 0 | 0 | 0 | - |
| TC-S1-008-14 | Refresh换取Access | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-15 | 无效Refresh Token | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-16 | bcrypt哈希 | 单元测试 | 0 | 0 | 0 | - |
| TC-S1-008-17 | 无明文密码存储 | 安全测试 | 0 | 0 | 0 | - |
| TC-S1-008-18 | API响应无密码 | 安全测试 | 0 | 0 | 0 | - |
| TC-S1-008-19 | 无效JSON处理 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-008-20 | 超长字段处理 | 集成测试 | 0 | 0 | 0 | - |

---

## 6. 缺陷报告模板

### 6.1 缺陷严重程度定义

| 级别 | 定义 | 示例 |
|-----|------|------|
| P0 (Critical) | 安全漏洞或核心功能失效 | 密码明文存储、Token伪造 |
| P1 (High) | 主要功能缺陷 | 登录失败、注册失败 |
| P2 (Medium) | 次要功能缺陷 | 错误消息不清晰、验证不完整 |
| P3 (Low) | 优化建议 | 性能问题、日志不完善 |

### 6.2 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-008-XX  
**关联测试用例**: TC-S1-008-XX  
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
- 数据库: [SQLite/PostgreSQL]

### 附件
- [请求/响应示例]
- [日志文件]
- [截图]
```

---

## 7. 附录

### 7.1 参考文档

| 文档 | 说明 |
|------|------|
| [S1-003 数据库Schema设计](./design/S1-003_design.md) | users表结构定义 |
| [S1-004 API框架设计](./design/S1-004_design.md) | 错误处理和响应格式 |
| [JWT RFC 7519](https://tools.ietf.org/html/rfc7519) | JWT标准规范 |
| [bcrypt](https://en.wikipedia.org/wiki/Bcrypt) | 密码哈希算法 |
| [OWASP认证备忘单](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) | 安全最佳实践 |

### 7.2 相关代码文件

| 文件路径 | 描述 |
|---------|------|
| `kayak-backend/src/api/handlers/auth.rs` | 认证处理器 |
| `kayak-backend/src/services/auth_service.rs` | 认证服务 |
| `kayak-backend/src/models/entities/user.rs` | 用户实体 |
| `kayak-backend/src/core/security/jwt.rs` | JWT工具 |
| `kayak-backend/src/core/security/password.rs` | 密码工具 |

### 7.3 测试辅助函数

```rust
// 测试辅助函数示例

/// 创建测试应用实例
async fn create_test_app() -> TestApp {
    // 初始化测试数据库和配置
}

/// 创建测试用户
async fn create_test_user(email: &str, password: &str) -> User {
    // 在测试数据库中创建用户
}

/// 验证JWT格式
fn is_valid_jwt_format(token: &str) -> bool {
    let parts: Vec<&str> = token.split('.').collect();
    parts.len() == 3 && parts.iter().all(|p| !p.is_empty())
}

/// 解码JWT（仅用于测试验证）
fn decode_jwt(token: &str) -> Result<TokenClaims, JwtError> {
    // 使用测试密钥解码Token
}

/// 验证bcrypt哈希格式
fn verify_bcrypt_hash(hash: &str) -> bool {
    hash.starts_with("$2b$") && hash.len() == 60
}
```

### 7.4 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|-------|---------|
| 1.0 | 2026-03-18 | sw-mike | 初始版本创建 |

---

**文档结束**
