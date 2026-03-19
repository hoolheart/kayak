# S1-010 测试用例文档
## 用户个人信息管理API (User Profile Management API)

**任务ID**: S1-010  
**任务名称**: 用户个人信息管理API  
**文档版本**: 1.0  
**创建日期**: 2026-03-19  
**测试类型**: 单元测试、集成测试、API测试、安全测试

---

## 1. 测试范围

### 1.1 测试目标

本文档覆盖 S1-010 任务的所有验收标准，确保用户个人信息管理API功能完整、安全可靠，包括：
- 获取当前用户信息（GET /api/v1/users/me）
- 更新用户信息（PUT /api/v1/users/me）
- 修改密码（POST /api/v1/users/me/password）
- 认证与授权验证
- 输入验证与错误处理

### 1.2 验收标准映射

| 验收标准 | 测试用例ID | 测试类型 |
|---------|-----------|---------|
| 1. GET /api/v1/users/me 返回当前用户信息 | TC-S1-010-01 ~ TC-S1-010-06 | 单元测试/API测试 |
| 2. PUT /api/v1/users/me 更新用户信息 | TC-S1-010-07 ~ TC-S1-010-14 | 单元测试/API测试 |
| 3. POST /api/v1/users/me/password 修改密码需要验证旧密码 | TC-S1-010-15 ~ TC-S1-010-24 | 单元测试/API测试 |

---

## 2. 测试用例详情

### 2.1 获取当前用户信息API测试

#### TC-S1-010-01: 获取当前用户信息成功

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-01 |
| **测试名称** | 获取当前用户信息成功 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证已认证用户可以成功获取自己的用户信息 |

**测试目标:** `GET /api/v1/users/me`

**前置条件:**
1. 后端服务已启动并运行
2. 用户已注册并登录，拥有有效的Access Token
3. 用户信息在数据库中存在

**测试步骤:**

1. 发送获取用户信息请求
   ```bash
   curl -X GET http://localhost:8080/api/v1/users/me \
     -H "Authorization: Bearer <valid_access_token>"
   ```

2. 验证HTTP响应状态码

3. 验证响应体结构

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 200 OK | 请求成功 |
| code | 200 | 响应码 |
| data.user.id | 有效的UUID格式 | 用户ID |
| data.user.email | 注册邮箱 | 用户邮箱 |
| data.user.username | 用户名 | 用户名 |
| data.user.avatar | URL或null | 头像URL |
| data.user.status | "active" | 用户状态 |
| data.user.created_at | ISO8601时间格式 | 创建时间 |
| data.user.updated_at | ISO8601时间格式 | 更新时间 |

**通过标准:**
- [ ] HTTP状态码为 200
- [ ] 响应包含完整的用户信息
- [ ] 响应中不包含password、password_hash等敏感字段
- [ ] 用户ID与Token中的sub一致

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_get_current_user_success() {
    // Arrange
    let app = create_test_app().await;
    let (user, token) = create_authenticated_user(&app).await;
    
    // Act
    let response = app
        .get("/api/v1/users/me")
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 200);
    
    let user_data = &body["data"]["user"];
    assert_eq!(user_data["id"], user.id.to_string());
    assert_eq!(user_data["email"], user.email);
    assert_eq!(user_data["username"], user.username);
    assert_eq!(user_data["status"], "active");
    
    // 验证敏感字段不包含
    assert!(!user_data.get("password").is_some());
    assert!(!user_data.get("password_hash").is_some());
}
```

---

#### TC-S1-010-02: 未认证请求被拒绝

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-02 |
| **测试名称** | 未认证请求获取用户信息失败 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证未提供有效Token的请求被拒绝 |

**前置条件:**
1. 后端服务已启动并运行
2. 请求端点需要JWT认证

**测试步骤:**

1. 发送请求时不带Authorization头部
   ```bash
   curl -X GET http://localhost:8080/api/v1/users/me
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |
| message | 包含"Unauthorized"、"未授权"或"missing token" |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 错误消息明确指示缺少认证信息
- [ ] 不暴露任何用户信息

---

#### TC-S1-010-03: 无效Token被拒绝

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-03 |
| **测试名称** | 无效Token获取用户信息失败 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证使用无效Token的请求被拒绝 |

**测试数据表:**

| Token类型 | 预期结果 | 说明 |
|----------|---------|------|
| 过期Token | 401 | Token已过期 |
| 无效签名Token | 401 | 签名验证失败 |
| 格式错误Token | 401 | 非JWT格式 |
| Refresh Token充当Access Token | 401 | Token类型不匹配 |

**测试步骤:**

1. 使用各种无效Token发送请求
2. 验证每个请求的响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |

**通过标准:**
- [ ] 所有无效Token都被拒绝
- [ ] 返回一致的401错误

---

#### TC-S1-010-04: 用户信息字段完整性验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-04 |
| **测试名称** | 用户信息响应字段完整性验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证API返回所有必需的用户字段 |

**测试步骤:**

1. 注册并登录获取有效Token
2. 调用GET /api/v1/users/me
3. 验证响应数据结构

**预期结果:**

| 字段 | 类型 | 必需 | 说明 |
|-----|------|------|------|
| id | UUID | 是 | 用户唯一标识 |
| email | string | 是 | 用户邮箱 |
| username | string | 是 | 用户名 |
| avatar | string/null | 是 | 头像URL |
| status | string | 是 | 用户状态 |
| created_at | datetime | 是 | 创建时间 |
| updated_at | datetime | 是 | 更新时间 |

**通过标准:**
- [ ] 所有必需字段都存在
- [ ] 字段类型正确
- [ ] 时间格式为ISO8601

---

#### TC-S1-010-05: 用户不存在场景处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-05 |
| **测试名称** | 用户账户被删除后的处理 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证Token有效但用户已被删除时的处理 |

**前置条件:**
1. 用户Token仍在有效期内
2. 但该用户已被从数据库中删除

**测试步骤:**

1. 创建用户并获取Token
2. 从数据库中删除该用户
3. 使用原Token发送请求

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 或 404 |
| code | 401 或 404 |
| message | 包含"User not found"、"用户不存在"或"Unauthorized" |

**通过标准:**
- [ ] 不返回任何用户信息
- [ ] 错误消息不泄露用户状态细节

---

#### TC-S1-010-06: 并发获取用户信息

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-06 |
| **测试名称** | 并发请求获取用户信息 |
| **测试类型** | 性能测试 / 集成测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证系统在并发请求下的稳定性 |

**测试步骤:**

1. 创建测试用户和Token
2. 并发发送50个获取用户信息请求
3. 验证所有响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 成功率 | 100% |
| 响应时间 | < 200ms（平均值） |
| 无数据竞争 | 每个请求返回正确的用户信息 |

---

### 2.2 更新用户信息API测试

#### TC-S1-010-07: 更新用户名成功

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-07 |
| **测试名称** | 更新用户名成功 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证用户可以成功更新自己的用户名 |

**测试目标:** `PUT /api/v1/users/me`

**前置条件:**
1. 用户已认证并拥有有效Token
2. 用户信息在数据库中存在

**测试步骤:**

1. 发送更新用户信息请求
   ```bash
   curl -X PUT http://localhost:8080/api/v1/users/me \
     -H "Authorization: Bearer <valid_token>" \
     -H "Content-Type: application/json" \
     -d '{
       "username": "new_username"
     }'
   ```

2. 验证HTTP响应状态码

3. 验证数据库中用户名已更新

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 200 OK | 更新成功 |
| code | 200 | 响应码 |
| data.user.username | "new_username" | 更新后的用户名 |
| data.user.updated_at | 当前时间 | 反映更新时间 |

**通过标准:**
- [ ] HTTP状态码为 200
- [ ] 用户名已成功更新
- [ ] updated_at时间戳已更新
- [ ] 其他用户字段保持不变

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_update_username_success() {
    // Arrange
    let app = create_test_app().await;
    let (user, token) = create_authenticated_user(&app).await;
    let new_username = "updated_username_123";
    
    let update_req = json!({
        "username": new_username
    });
    
    // Act
    let response = app
        .put("/api/v1/users/me")
        .header("Authorization", format!("Bearer {}", token))
        .json(&update_req)
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["data"]["user"]["username"], new_username);
    
    // 验证数据库
    let updated_user = get_user_from_db(user.id).await;
    assert_eq!(updated_user.username, new_username);
}
```

---

#### TC-S1-010-08: 更新头像成功

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-08 |
| **测试名称** | 更新头像成功 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证用户可以成功更新头像URL |

**前置条件:**
1. 用户已认证并拥有有效Token
2. 头像URL需要是有效的URL格式

**测试步骤:**

1. 发送更新头像请求
   ```bash
   curl -X PUT http://localhost:8080/api/v1/users/me \
     -H "Authorization: Bearer <valid_token>" \
     -H "Content-Type: application/json" \
     -d '{
       "avatar": "https://example.com/avatar.jpg"
     }'
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 200 OK | 更新成功 |
| data.user.avatar | "https://example.com/avatar.jpg" | 新头像URL |

**通过标准:**
- [ ] HTTP状态码为 200
- [ ] 头像URL已成功更新
- [ ] URL格式正确

---

#### TC-S1-010-09: 同时更新用户名和头像

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-09 |
| **测试名称** | 同时更新多个字段成功 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证可以在一次请求中更新多个字段 |

**测试步骤:**

1. 发送包含多个字段的更新请求
   ```json
   {
     "username": "new_name",
     "avatar": "https://example.com/new_avatar.png"
   }
   ```

2. 验证所有字段都更新成功

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 200 OK |
| data.user.username | "new_name" |
| data.user.avatar | "https://example.com/new_avatar.png" |

**通过标准:**
- [ ] HTTP状态码为 200
- [ ] 所有指定字段都更新成功
- [ ] 未指定的字段保持不变

---

#### TC-S1-010-10: 未认证请求更新被拒绝

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-10 |
| **测试名称** | 未认证更新用户信息失败 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证未认证的更新请求被拒绝 |

**测试步骤:**

1. 发送更新请求不带Token
   ```bash
   curl -X PUT http://localhost:8080/api/v1/users/me \
     -H "Content-Type: application/json" \
     -d '{"username": "hacker"}'
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 用户信息未发生任何更改

---

#### TC-S1-010-11: 用户名格式验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-11 |
| **测试名称** | 用户名格式验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统正确验证用户名格式 |

**测试数据表:**

| 用户名 | 预期结果 | 说明 |
|--------|---------|------|
| "validuser123" | 200 | 字母数字组合 |
| "user-name" | 200或400 | 含连字符（根据策略） |
| "" (空字符串) | 400/422 | 空用户名 |
| "ab" | 400/422 | 太短（<3字符） |
| 超过50字符的长用户名 | 400/422 | 超出长度限制 |
| "user@name" | 400/422 | 包含特殊字符 |
| "user name" | 400/422 | 包含空格 |

**测试步骤:**

1. 使用每个测试用户名发送更新请求
2. 验证响应状态码和错误信息

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 无效用户名 | 400 或 422 |
| errors[0].field | "username" |
| 有效用户名 | 200 |

**通过标准:**
- [ ] 所有无效用户名格式都被拒绝
- [ ] 返回明确的验证错误

---

#### TC-S1-010-12: 头像URL格式验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-12 |
| **测试名称** | 头像URL格式验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证系统正确验证头像URL格式 |

**测试数据表:**

| 头像URL | 预期结果 | 说明 |
|---------|---------|------|
| "https://example.com/avatar.jpg" | 200 | 有效HTTPS URL |
| "http://example.com/avatar.png" | 200或400 | HTTP URL（根据策略） |
| "not-a-url" | 400/422 | 非URL格式 |
| "" (空字符串) | 400/422 | 空URL（如果允许null则200） |
| 超过2048字符的URL | 400/422 | URL过长 |

**测试步骤:**

1. 使用每个测试URL发送更新请求
2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 无效URL | 400 或 422 |
| 有效URL | 200 |

---

#### TC-S1-010-13: 用户名唯一性验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-13 |
| **测试名称** | 用户名唯一性验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证更新后的用户名不与现有用户重复 |

**前置条件:**
1. 用户A已存在，用户名为"taken_username"
2. 用户B已登录

**测试步骤:**

1. 用户B尝试将用户名改为"taken_username"
   ```json
   {
     "username": "taken_username"
   }
   ```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 409 Conflict 或 400 |
| message | 包含"already exists"、"已被使用"或"duplicate" |

**通过标准:**
- [ ] 返回409或400错误
- [ ] 错误消息明确说明用户名已被使用

---

#### TC-S1-010-14: 不可更新字段的处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-14 |
| **测试名称** | 不可更新字段的处理 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证用户不能通过更新接口修改受保护字段 |

**测试数据:**

| 请求包含的字段 | 预期结果 | 说明 |
|--------------|---------|------|
| email | 忽略或400 | 邮箱不可更改 |
| id | 忽略或400 | ID不可更改 |
| password | 忽略或400 | 密码需通过专门接口 |
| status | 忽略或400 | 状态不可由用户更改 |
| created_at | 忽略 | 创建时间不可更改 |
| role | 忽略或400 | 角色不可更改 |

**测试步骤:**

1. 发送包含敏感字段的更新请求
2. 验证这些字段未被修改

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 200（敏感字段被忽略）或 400（直接拒绝） |
| 敏感字段 | 未被修改或返回验证错误 |

**通过标准:**
- [ ] email字段未被修改
- [ ] id字段未被修改
- [ ] status字段未被修改
- [ ] password字段未被修改

---

### 2.3 修改密码API测试

#### TC-S1-010-15: 修改密码成功

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-15 |
| **测试名称** | 修改密码成功 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证用户可以成功使用旧密码修改新密码 |

**测试目标:** `POST /api/v1/users/me/password`

**前置条件:**
1. 用户已认证并拥有有效Token
2. 用户当前密码为 "OldPass123!"

**测试步骤:**

1. 发送修改密码请求
   ```bash
   curl -X POST http://localhost:8080/api/v1/users/me/password \
     -H "Authorization: Bearer <valid_token>" \
     -H "Content-Type: application/json" \
     -d '{
       "old_password": "OldPass123!",
       "new_password": "NewSecurePass456!"
     }'
   ```

2. 验证HTTP响应状态码

3. 验证新密码可以用于登录

**预期结果:**

| 检查项 | 预期值 | 说明 |
|-------|--------|------|
| HTTP状态码 | 200 OK | 修改成功 |
| code | 200 | 响应码 |
| message | 包含"success"、"成功"或"updated" | 成功消息 |

**通过标准:**
- [ ] HTTP状态码为 200
- [ ] 返回成功消息
- [ ] 新密码可以用于登录
- [ ] 旧密码不再有效

**自动化测试代码:**

```rust
#[tokio::test]
async fn test_change_password_success() {
    // Arrange
    let app = create_test_app().await;
    let (user, token) = create_authenticated_user(&app).await;
    let old_password = "OldPass123!";
    let new_password = "NewSecurePass456!";
    
    let change_req = json!({
        "old_password": old_password,
        "new_password": new_password
    });
    
    // Act
    let response = app
        .post("/api/v1/users/me/password")
        .header("Authorization", format!("Bearer {}", token))
        .json(&change_req)
        .send()
        .await;
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    let body: Value = response.json().await.unwrap();
    assert_eq!(body["code"], 200);
    
    // 验证新密码可以登录
    let login_response = app
        .post("/api/v1/auth/login")
        .json(&json!({
            "email": user.email,
            "password": new_password
        }))
        .send()
        .await;
    
    assert_eq!(login_response.status(), StatusCode::OK);
    
    // 验证旧密码不能再登录
    let old_login_response = app
        .post("/api/v1/auth/login")
        .json(&json!({
            "email": user.email,
            "password": old_password
        }))
        .send()
        .await;
    
    assert_eq!(old_login_response.status(), StatusCode::UNAUTHORIZED);
}
```

---

#### TC-S1-010-16: 旧密码错误

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-16 |
| **测试名称** | 旧密码错误导致修改失败 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证旧密码错误时修改密码请求被拒绝 |

**前置条件:**
1. 用户已认证并拥有有效Token
2. 用户当前密码为 "CorrectPass123!"

**测试步骤:**

1. 发送修改密码请求，使用错误的旧密码
   ```json
   {
     "old_password": "WrongPass123!",
     "new_password": "NewSecurePass456!"
   }
   ```

2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 401 |
| code | 400 或 401 |
| message | 包含"incorrect"、"wrong"、"旧密码"或"错误" |

**通过标准:**
- [ ] HTTP状态码为 400 或 401
- [ ] 错误消息明确指出旧密码错误
- [ ] 新密码未被设置
- [ ] 旧密码仍然有效

---

#### TC-S1-010-17: 新密码强度验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-17 |
| **测试名称** | 新密码强度验证 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证新密码必须满足强度要求 |

**测试数据表:**

| 新密码 | 预期结果 | 原因 |
|--------|---------|------|
| "short" | 400/422 | 太短 (< 8字符) |
| "12345678" | 400/422 | 全数字，无字母 |
| "password" | 400/422 | 太简单，常用词 |
| "PASSWORD" | 400/422 | 太简单，全大写 |
| "NewPass123!" | 200 | 符合强度要求 |
| (空字符串) | 400/422 | 空密码 |

**测试步骤:**

1. 使用每个测试密码发送修改请求
2. 验证响应

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 弱密码 | 400 或 422 |
| 错误消息 | 包含密码强度要求 |
| 强密码 | 200 |

**通过标准:**
- [ ] 所有弱密码都被拒绝
- [ ] 返回明确的密码要求说明
- [ ] 旧密码仍然有效（请求被拒绝）

---

#### TC-S1-010-18: 旧密码与新密码相同

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-18 |
| **测试名称** | 新旧密码相同被拒绝 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证新密码不能与旧密码相同 |

**测试步骤:**

1. 发送修改密码请求，新旧密码相同
   ```json
   {
     "old_password": "SamePass123!",
     "new_password": "SamePass123!"
   }
   ```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| message | 包含"same"、"相同"或"不能相同" |

**通过标准:**
- [ ] 请求被拒绝
- [ ] 错误消息明确说明原因

---

#### TC-S1-010-19: 缺少必填字段

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-19 |
| **测试名称** | 修改密码缺少必填字段 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证修改密码需要旧密码和新密码 |

**测试数据:**

| 请求体 | 缺失字段 |
|--------|---------|
| `{"new_password": "NewPass123!"}` | old_password |
| `{"old_password": "OldPass123!"}` | new_password |
| `{}` | old_password, new_password |

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 400 或 422 |
| errors | 包含缺失字段的验证错误 |

**通过标准:**
- [ ] 所有缺少字段的请求都被拒绝
- [ ] 返回详细的字段级错误

---

#### TC-S1-010-20: 未认证请求修改密码被拒绝

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-20 |
| **测试名称** | 未认证修改密码失败 |
| **测试类型** | 集成测试 / API测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证未认证的修改密码请求被拒绝 |

**测试步骤:**

1. 发送修改密码请求不带Token
   ```bash
   curl -X POST http://localhost:8080/api/v1/users/me/password \
     -H "Content-Type: application/json" \
     -d '{
       "old_password": "OldPass123!",
       "new_password": "NewPass123!"
     }'
   ```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 Unauthorized |
| code | 401 |

**通过标准:**
- [ ] HTTP状态码为 401
- [ ] 密码未被修改

---

#### TC-S1-010-21: 用户不存在场景

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-21 |
| **测试名称** | 用户不存在时修改密码 |
| **测试类型** | 集成测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证Token有效但用户已被删除时的处理 |

**前置条件:**
1. 用户Token仍在有效期内
2. 但该用户已被从数据库中删除

**测试步骤:**

1. 创建用户并获取Token
2. 从数据库中删除该用户
3. 使用原Token发送修改密码请求

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 401 或 404 |
| code | 401 或 404 |

**通过标准:**
- [ ] 请求被拒绝
- [ ] 不暴露任何用户信息

---

#### TC-S1-010-22: 修改密码后Token有效性

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-22 |
| **测试名称** | 修改密码后现有Token仍然有效 |
| **测试类型** | 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证修改密码不会使现有的Access Token失效 |

**前置条件:**
1. 用户已认证并拥有有效Token

**测试步骤:**

1. 记录当前Token
2. 修改密码
3. 使用原Token继续访问API

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 修改密码前Token | 有效 |
| 修改密码后Token | 仍然有效 |
| 新密码登录 | 有效 |

**通过标准:**
- [ ] 修改密码后现有Token仍然有效
- [ ] 新密码可以用于登录
- [ ] 旧密码不能用于登录

---

#### TC-S1-010-23: 密码修改后数据库验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-23 |
| **测试名称** | 密码修改后数据库验证 |
| **测试类型** | 安全测试 / 集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证密码在数据库中正确更新且安全存储 |

**测试步骤:**

1. 修改用户密码
2. 直接查询数据库
3. 验证存储的密码数据

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 数据库字段 | password_hash |
| 哈希格式 | bcrypt ($2b$) |
| 新密码哈希 | 与旧密码哈希不同 |
| 明文存储 | 不存在 |

**通过标准:**
- [ ] 密码以bcrypt格式存储
- [ ] 新旧密码哈希不同
- [ ] 数据库中不存在明文密码

---

#### TC-S1-010-24: 并发修改密码处理

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-010-24 |
| **测试名称** | 并发修改密码处理 |
| **测试类型** | 性能测试 / 集成测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证系统在并发修改密码请求下的稳定性 |

**测试步骤:**

1. 创建测试用户和Token
2. 并发发送10个修改密码请求（相同的新密码）
3. 验证最终密码状态

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 所有请求处理 | 完成（无panic） |
| 最终密码状态 | 唯一确定的值 |
| 无竞争条件 | 数据库一致 |

---

## 3. 授权测试场景

### 3.1 用户只能访问自己的数据

**场景描述:** 验证用户只能访问和修改自己的用户信息

**测试步骤:**

1. 用户A获取自己的用户信息
2. 用户A尝试修改用户B的信息（通过操控请求参数）
3. 用户B获取自己的用户信息

**通过标准:**
- [ ] 用户A只能获取自己的信息
- [ ] 用户A无法通过操控参数修改用户B的信息
- [ ] 用户B的信息未被影响

---

### 3.2 跨用户头像访问

**场景描述:** 验证用户可以查看其他用户的基本信息（仅限公开字段）

**测试步骤:**

1. 用户A设置头像
2. 用户B获取用户A的公开信息（如果有此接口）

**通过标准:**
- [ ] 用户可以查看其他用户的公开头像
- [ ] 无法查看其他用户的邮箱等私有信息

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

### 4.2 测试用户数据

```json
{
  "test_users": [
    {
      "email": "user1@example.com",
      "password": "UserPass123!",
      "username": "testuser1"
    },
    {
      "email": "user2@example.com",
      "password": "UserPass456!",
      "username": "testuser2"
    }
  ],
  "invalid_usernames": [
    "",
    "ab",
    "user@name",
    "user name"
  ],
  "invalid_avatar_urls": [
    "not-a-url",
    "ftp://example.com/file"
  ],
  "weak_passwords": [
    "short",
    "12345678",
    "password",
    "PASSWORD"
  ]
}
```

### 4.3 测试辅助函数

```rust
/// 创建已认证的测试用户
async fn create_authenticated_user(app: &TestApp) -> (TestUser, String) {
    let email = "test@example.com";
    let password = "TestPass123!";
    
    // 注册用户
    app.post("/api/v1/auth/register")
        .json(&json!({
            "email": email,
            "password": password,
            "username": "testuser"
        }))
        .send()
        .await;
    
    // 登录获取Token
    let login_response = app
        .post("/api/v1/auth/login")
        .json(&json!({
            "email": email,
            "password": password
        }))
        .send()
        .await;
    
    let body: Value = login_response.json().await.unwrap();
    let token = body["data"]["access_token"].as_str().unwrap().to_string();
    
    (TestUser { email: email.to_string() }, token)
}

/// 验证用户信息响应结构
fn validate_user_response(user_data: &Value) {
    assert!(user_data["id"].is_string());
    assert!(user_data["email"].is_string());
    assert!(user_data["username"].is_string());
    assert!(user_data["status"].is_string());
    assert!(user_data["created_at"].is_string());
    assert!(user_data["updated_at"].is_string());
    
    // 验证敏感字段不存在
    assert!(!user_data.get("password").is_some());
    assert!(!user_data.get("password_hash").is_some());
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
| TC-S1-010-01 | 获取当前用户信息成功 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-02 | 未认证请求被拒绝 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-03 | 无效Token被拒绝 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-04 | 用户信息字段完整性 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-05 | 用户不存在场景 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-06 | 并发获取用户信息 | 性能测试 | 0 | 0 | 0 | - |
| TC-S1-010-07 | 更新用户名成功 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-08 | 更新头像成功 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-09 | 同时更新多个字段 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-10 | 未认证更新被拒绝 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-11 | 用户名格式验证 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-12 | 头像URL格式验证 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-13 | 用户名唯一性验证 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-14 | 不可更新字段处理 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-15 | 修改密码成功 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-16 | 旧密码错误 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-17 | 新密码强度验证 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-18 | 新旧密码相同 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-19 | 缺少必填字段 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-20 | 未认证修改密码 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-21 | 用户不存在场景 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-22 | 修改后Token有效性 | 集成测试 | 0 | 0 | 0 | - |
| TC-S1-010-23 | 数据库密码验证 | 安全测试 | 0 | 0 | 0 | - |
| TC-S1-010-24 | 并发修改密码 | 性能测试 | 0 | 0 | 0 | - |

---

## 6. 缺陷报告模板

### 6.1 缺陷严重程度定义

| 级别 | 定义 | 示例 |
|-----|------|------|
| P0 (Critical) | 安全漏洞或核心功能失效 | 密码修改绕过、无认证访问 |
| P1 (High) | 主要功能缺陷 | 更新失败、验证不完整 |
| P2 (Medium) | 次要功能缺陷 | 错误消息不清晰、边界情况 |
| P3 (Low) | 优化建议 | 性能问题、日志不完善 |

### 6.2 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-010-XX  
**关联测试用例**: TC-S1-010-XX  
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
```

---

## 7. 附录

### 7.1 参考文档

| 文档 | 说明 |
|------|------|
| [S1-008 用户注册与登录API测试](./S1-008_test_cases.md) | Token生成和认证相关测试 |
| [S1-009 JWT认证中间件测试](./S1-009_test_cases.md) | JWT中间件相关测试 |
| [S1-003 数据库Schema设计](./design/S1-003_design.md) | users表结构定义 |
| [OWASP密码存储备忘单](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html) | 密码安全最佳实践 |

### 7.2 相关代码文件

| 文件路径 | 描述 |
|---------|------|
| `kayak-backend/src/api/handlers/users.rs` | 用户信息处理器 |
| `kayak-backend/src/api/handlers/auth.rs` | 认证处理器 |
| `kayak-backend/src/services/user_service.rs` | 用户服务 |
| `kayak-backend/src/models/entities/user.rs` | 用户实体 |
| `kayak-backend/src/core/security/password.rs` | 密码哈希工具 |

### 7.3 推荐实现结构

```rust
// kayak-backend/src/api/handlers/users.rs

/// GET /api/v1/users/me - 获取当前用户信息
async fn get_current_user(
    Extension(user_ctx): Extension<UserContext>,
) -> impl IntoResponse {
    let user = user_service::get_user_by_id(user_ctx.user_id)
        .await
        .map_err(|_| StatusCode::NOT_FOUND)?;
    
    Json(json!({
        "code": 200,
        "data": {
            "user": {
                "id": user.id,
                "email": user.email,
                "username": user.username,
                "avatar": user.avatar,
                "status": user.status,
                "created_at": user.created_at,
                "updated_at": user.updated_at
            }
        }
    }))
}

/// PUT /api/v1/users/me - 更新当前用户信息
async fn update_current_user(
    Extension(user_ctx): Extension<UserContext>,
    Json(payload): Json<UpdateUserRequest>,
) -> impl IntoResponse {
    // 验证更新字段
    let updates = payload.validate()?;
    
    let user = user_service::update_user(user_ctx.user_id, updates)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Json(json!({
        "code": 200,
        "data": { "user": user }
    }))
}

/// POST /api/v1/users/me/password - 修改密码
async fn change_password(
    Extension(user_ctx): Extension<UserContext>,
    Json(payload): Json<ChangePasswordRequest>,
) -> impl IntoResponse {
    // 验证旧密码
    let user = user_service::get_user_by_id(user_ctx.user_id)
        .await
        .map_err(|_| StatusCode::NOT_FOUND)?;
    
    if !password::verify(&payload.old_password, &user.password_hash)? {
        return Err(StatusCode::BAD_REQUEST);
    }
    
    // 验证新密码强度
    payload.new_password.validate()?;
    
    // 更新密码
    let new_hash = password::hash(&payload.new_password)?;
    user_service::update_password(user_ctx.user_id, new_hash)
        .await?;
    
    Json(json!({
        "code": 200,
        "message": "Password updated successfully"
    }))
}
```

### 7.4 测试执行优先级

| 优先级 | 测试ID范围 | 说明 |
|-------|-----------|------|
| 必须首先执行 | TC-S1-010-01 ~ TC-S1-010-03 | 核心认证测试 |
| 第二优先级 | TC-S1-010-07 ~ TC-S1-010-10 | 更新功能测试 |
| 第三优先级 | TC-S1-010-15 ~ TC-S1-010-20 | 密码修改功能测试 |
| 第四优先级 | 其他 | 边界情况和性能测试 |

### 7.5 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|-------|---------|
| 1.0 | 2026-03-19 | sw-mike | 初始版本创建 |

---

**文档结束**
