# S1-013 测试用例文档 - 工作台CRUD API

**版本**: 1.0  
**创建日期**: 2026-03-20  
**任务**: S1-013 工作台CRUD API  
**技术栈**: Rust / Axum / SQLite / sqlx

---

## 1. 测试概述

### 1.1 测试范围

本测试文档涵盖工作台CRUD API (S1-013) 的所有功能测试，包括：
- 工作台创建API (POST /api/v1/workbenches)
- 工作台列表查询API (GET /api/v1/workbenches) - 支持分页
- 工作台详情查询API (GET /api/v1/workbenches/{id})
- 工作台更新API (PUT /api/v1/workbenches/{id})
- 工作台删除API (DELETE /api/v1/workbenches/{id}) - 包含级联删除设备
- 工作台CRUD操作的认证与授权验证

### 1.2 测试环境

| 项目 | 说明 |
|------|------|
| **Rust SDK** | 1.75+ |
| **Web框架** | Axum 0.7 |
| **数据库** | SQLite 3 + sqlx |
| **认证方式** | JWT Bearer Token |
| **依赖任务** | S1-009 (JWT认证中间件), S1-003 (数据库Schema设计) |

### 1.3 API端点汇总

| 方法 | 端点 | 说明 | 认证要求 |
|------|------|------|----------|
| POST | /api/v1/workbenches | 创建工作台 | 必须 |
| GET | /api/v1/workbenches | 列表查询(分页) | 必须 |
| GET | /api/v1/workbenches/{id} | 详情查询 | 必须 |
| PUT | /api/v1/workbenches/{id} | 更新工作台 | 必须 |
| DELETE | /api/v1/workbenches/{id} | 删除工作台 | 必须 |

### 1.4 测试用例统计

| 类别 | 用例数量 |
|------|----------|
| 创建工作台测试 | 5 |
| 查询工作台测试 | 5 |
| 更新工作台测试 | 5 |
| 删除工作台测试 | 4 |
| 认证与授权测试 | 5 |
| 输入验证测试 | 5 |
| 级联删除测试 | 2 |
| 分页参数验证测试 | 4 |
| 边界值测试 | 4 |
| **总计** | **41** |

---

## 2. 创建工作台测试 (TC-S1-013-01 ~ TC-S1-013-05)

### TC-S1-013-01: 成功创建工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-01 |
| **用例名称** | 成功创建工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，获取有效JWT Token |
| **测试步骤** | 1. 发送POST请求到/api/v1/workbenches<br>2. 请求体包含name和description |
| **预期结果** | 返回201 Created，响应体包含创建的工作台信息(id, name, description, owner_id等) |
| **自动化代码** | `let response = test_app.create_workbench(&token, "Test WB", Some("desc")).await;`<br>`assert_eq!(response.status(), 201);`<br>`let wb = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(wb.name, "Test WB");` |

### TC-S1-013-02: 创建工作台仅提供必填字段

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-02 |
| **用例名称** | 创建工作台仅提供必填字段 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，获取有效JWT Token |
| **测试步骤** | 1. 发送POST请求，仅提供name字段<br>2. description为可选字段 |
| **预期结果** | 返回201 Created，description为null |
| **自动化代码** | `let response = test_app.create_workbench_minimal(&token, "Minimal WB").await;`<br>`assert_eq!(response.status(), 201);`<br>`let wb = response.json::<WorkbenchResponse>().await;`<br>`assert!(wb.description.is_none());` |

### TC-S1-013-03: 创建工作台设置所有者类型为用户

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-03 |
| **用例名称** | 创建工作台设置所有者类型为用户 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 创建工作台，指定owner_type为"user" |
| **预期结果** | 工作台创建成功，owner_type为user |
| **自动化代码** | `let response = test_app.create_workbench_with_owner_type(&token, "User WB", OwnerType::User).await;`<br>`let wb = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(wb.owner_type, OwnerType::User);` |

### TC-S1-013-04: 未提供名称时创建失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-04 |
| **用例名称** | 未提供名称时创建失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，不提供name字段 |
| **预期结果** | 返回400 Bad Request，错误信息提示name为必填 |
| **自动化代码** | `let response = test_app.create_workbench_no_name(&token).await;`<br>`assert_eq!(response.status(), 400);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.contains("name"));` |

### TC-S1-013-05: 未登录创建工作台失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-05 |
| **用例名称** | 未登录创建工作台失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 无Token |
| **测试步骤** | 1. 发送POST请求到/api/v1/workbenches，不带Authorization头 |
| **预期结果** | 返回401 Unauthorized |
| **自动化代码** | `let response = test_app.create_workbench_unauthenticated("Test WB").await;`<br>`assert_eq!(response.status(), 401);` |

---

## 3. 查询工作台测试 (TC-S1-013-06 ~ TC-S1-013-10)

### TC-S1-013-06: 获取工作台详情成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-06 |
| **用例名称** | 获取工作台详情成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在一个工作台 |
| **测试步骤** | 1. 获取已创建工作台的ID<br>2. 发送GET请求到/api/v1/workbenches/{id} |
| **预期结果** | 返回200 OK，响应体包含工作台完整信息 |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "Detail WB", None).await;`<br>`let response = test_app.get_workbench(&token, wb.id).await;`<br>`assert_eq!(response.status(), 200);`<br>`let detail = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(detail.id, wb.id);` |

### TC-S1-013-07: 获取不存在的工作台详情

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-07 |
| **用例名称** | 获取不存在的工作台详情 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 使用随机UUID发送GET请求 |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.get_workbench(&token, fake_id).await;`<br>`assert_eq!(response.status(), 404);` |

### TC-S1-013-08: 分页查询工作台列表-第一页

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-08 |
| **用例名称** | 分页查询工作台列表-第一页 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在多个工作台 |
| **测试步骤** | 1. 创建5个工作台<br>2. 发送GET /api/v1/workbenches?page=1&size=2 |
| **预期结果** | 返回200 OK，包含total、page、size、items字段<br>items包含2个工作台 |
| **自动化代码** | `let wbs = test_app.create_multiple_workbenches(&token, 5).await;`<br>`let response = test_app.list_workbenches(&token, 1, 2).await;`<br>`assert_eq!(response.status(), 200);`<br>`let page = response.json::<PagedWorkbenchResponse>().await;`<br>`assert_eq!(page.items.len(), 2);`<br>`assert_eq!(page.total, 5);`<br>`assert_eq!(page.page, 1);`<br>`assert_eq!(page.size, 2);` |

### TC-S1-013-09: 分页查询工作台列表-后续页

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-09 |
| **用例名称** | 分页查询工作台列表-后续页 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在多个工作台 |
| **测试步骤** | 1. 创建5个工作台<br>2. 发送GET /api/v1/workbenches?page=2&size=2 |
| **预期结果** | 返回200 OK，items包含第3-4个工作台 |
| **自动化代码** | `let wbs = test_app.create_multiple_workbenches(&token, 5).await;`<br>`let response = test_app.list_workbenches(&token, 2, 2).await;`<br>`let page = response.json::<PagedWorkbenchResponse>().await;`<br>`assert_eq!(page.items.len(), 2);`<br>`assert_eq!(page.page, 2);` |

### TC-S1-013-10: 分页查询-超出总页数

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-10 |
| **用例名称** | 分页查询-超出总页数 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在2个工作台 |
| **测试步骤** | 1. 创建2个工作台<br>2. 发送GET /api/v1/workbenches?page=10&size=10 |
| **预期结果** | 返回200 OK，items为空数组 |
| **自动化代码** | `let wbs = test_app.create_multiple_workbenches(&token, 2).await;`<br>`let response = test_app.list_workbenches(&token, 10, 10).await;`<br>`let page = response.json::<PagedWorkbenchResponse>().await;`<br>`assert!(page.items.is_empty());` |

---

## 4. 更新工作台测试 (TC-S1-013-11 ~ TC-S1-013-15)

### TC-S1-013-11: 成功更新工作台名称

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-11 |
| **用例名称** | 成功更新工作台名称 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在一个工作台 |
| **测试步骤** | 1. 获取工作台ID<br>2. 发送PUT请求，更新name字段 |
| **预期结果** | 返回200 OK，工作台name已更新 |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "Old Name", None).await;`<br>`let response = test_app.update_workbench(&token, wb.id, "New Name", None).await;`<br>`assert_eq!(response.status(), 200);`<br>`let updated = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(updated.name, "New Name");` |

### TC-S1-013-12: 成功更新工作台描述

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-12 |
| **用例名称** | 成功更新工作台描述 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在一个工作台 |
| **测试步骤** | 1. 获取工作台ID<br>2. 发送PUT请求，更新description字段 |
| **预期结果** | 返回200 OK，description已更新 |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "WB", None).await;`<br>`let response = test_app.update_workbench(&token, wb.id, "WB", Some("New desc")).await;`<br>`let updated = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(updated.description, Some("New desc".to_string()));` |

### TC-S1-013-13: 更新不存在的工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-13 |
| **用例名称** | 更新不存在的工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 使用随机UUID发送PUT请求 |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.update_workbench(&token, fake_id, "Name", None).await;`<br>`assert_eq!(response.status(), 404);` |

### TC-S1-013-14: 更新其他用户的工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-14 |
| **用例名称** | 更新其他用户的工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A和用户B都已登录，用户A创建工作台 |
| **测试步骤** | 1. 用户A创建工作台WB1<br>2. 用户B尝试更新WB1 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let wb = test_app.create_workbench(&token_a, "A's WB", None).await;`<br>`let response = test_app.update_workbench(&token_b, wb.id, "Hacked", None).await;`<br>`assert_eq!(response.status(), 403);` |

### TC-S1-013-15: 部分更新-仅更新description保留name

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-15 |
| **用例名称** | 部分更新-仅更新description保留name |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在一个工作台 |
| **测试步骤** | 1. 创建工作台name="Original", description=Some("old")<br>2. 仅发送description更新请求 |
| **预期结果** | name保持"Original"，description更新为"new" |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "Original", Some("old")).await;`<br>`let response = test_app.update_workbench_partial(&token, wb.id, None, Some("new")).await;`<br>`let updated = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(updated.name, "Original");`<br>`assert_eq!(updated.description, Some("new".to_string()));` |

---

## 5. 删除工作台测试 (TC-S1-013-16 ~ TC-S1-013-19)

### TC-S1-013-16: 成功删除工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-16 |
| **用例名称** | 成功删除工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在一个工作台 |
| **测试步骤** | 1. 创建工作台<br>2. 发送DELETE请求<br>3. 验证工作台不再可查询 |
| **预期结果** | 返回204 No Content<br>再次查询返回404 |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "To Delete", None).await;`<br>`let response = test_app.delete_workbench(&token, wb.id).await;`<br>`assert_eq!(response.status(), 204);`<br>`let not_found = test_app.get_workbench(&token, wb.id).await;`<br>`assert_eq!(not_found.status(), 404);` |

### TC-S1-013-17: 删除不存在的工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-17 |
| **用例名称** | 删除不存在的工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 使用随机UUID发送DELETE请求 |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.delete_workbench(&token, fake_id).await;`<br>`assert_eq!(response.status(), 404);` |

### TC-S1-013-18: 删除其他用户的工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-18 |
| **用例名称** | 删除其他用户的工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A和用户B都已登录，用户A创建工作台 |
| **测试步骤** | 1. 用户A创建工作台WB1<br>2. 用户B尝试删除WB1 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let wb = test_app.create_workbench(&token_a, "A's WB", None).await;`<br>`let response = test_app.delete_workbench(&token_b, wb.id).await;`<br>`assert_eq!(response.status(), 403);` |

### TC-S1-013-19: 未登录删除工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-19 |
| **用例名称** | 未登录删除工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 无Token |
| **测试步骤** | 1. 发送DELETE请求，不带Authorization头 |
| **预期结果** | 返回401 Unauthorized |
| **自动化代码** | `let response = test_app.delete_workbench_unauthenticated(workbench_id).await;`<br>`assert_eq!(response.status(), 401);` |

---

## 6. 认证与授权测试 (TC-S1-013-20 ~ TC-S1-013-24)

### TC-S1-013-20: 无Token访问列表接口

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-20 |
| **用例名称** | 无Token访问列表接口 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 无Token |
| **测试步骤** | 1. 发送GET /api/v1/workbenches，不带Authorization头 |
| **预期结果** | 返回401 Unauthorized |
| **自动化代码** | `let response = test_app.list_workbenches_unauthenticated().await;`<br>`assert_eq!(response.status(), 401);` |

### TC-S1-013-21: 无效Token格式访问详情

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-21 |
| **用例名称** | 无效Token格式访问详情 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 无Token |
| **测试步骤** | 1. 发送GET请求，使用格式错误的Token |
| **预期结果** | 返回401 Unauthorized |
| **自动化代码** | `let response = test_app.get_workbench_with_invalid_token(workbench_id).await;`<br>`assert_eq!(response.status(), 401);` |

### TC-S1-013-22: 过期Token访问接口

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-22 |
| **用例名称** | 过期Token访问接口 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 使用过期Token |
| **测试步骤** | 1. 使用已过期的JWT Token发送请求 |
| **预期结果** | 返回401 Unauthorized，message包含"expired" |
| **自动化代码** | `let expired_token = generate_expired_token();`<br>`let response = test_app.list_workbenches_with_token(&expired_token).await;`<br>`assert_eq!(response.status(), 401);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.to_lowercase().contains("expired"));` |

### TC-S1-013-23: 用户只能看到自己的工作台

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-23 |
| **用例名称** | 用户只能看到自己的工作台 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A和用户B都已登录，各创建工作台 |
| **测试步骤** | 1. 用户A创建工作台WB_A<br>2. 用户B创建工作台WB_B<br>3. 用户A查询列表 |
| **预期结果** | 返回200 OK，items只包含WB_A，不包含WB_B |
| **自动化代码** | `let wb_a = test_app.create_workbench(&token_a, "A's WB", None).await;`<br>`let wb_b = test_app.create_workbench(&token_b, "B's WB", None).await;`<br>`let response = test_app.list_workbenches(&token_a, 1, 10).await;`<br>`let page = response.json::<PagedWorkbenchResponse>().await;`<br>`let ids: Vec<Uuid> = page.items.iter().map(|w| w.id).collect();`<br>`assert!(ids.contains(&wb_a.id));`<br>`assert!(!ids.contains(&wb_b.id));` |

### TC-S1-013-24: 用户只能访问自己的工作台详情

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-24 |
| **用例名称** | 用户只能访问自己的工作台详情 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A和用户B都已登录，用户A创建工作台 |
| **测试步骤** | 1. 用户A创建工作台WB<br>2. 用户B尝试获取WB详情 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let wb = test_app.create_workbench(&token_a, "A's WB", None).await;`<br>`let response = test_app.get_workbench(&token_b, wb.id).await;`<br>`assert_eq!(response.status(), 403);` |

---

## 7. 输入验证测试 (TC-S1-013-25 ~ TC-S1-013-29)

### TC-S1-013-25: 创建工作台名称为空字符串

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-25 |
| **用例名称** | 创建工作台名称为空字符串 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，name为空字符串"" |
| **预期结果** | 返回400 Bad Request |
| **自动化代码** | `let response = test_app.create_workbench(&token, "", None).await;`<br>`assert_eq!(response.status(), 400);` |

### TC-S1-013-26: 创建工作台名称超长

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-26 |
| **用例名称** | 创建工作台名称超长 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，name超过255字符 |
| **预期结果** | 返回400 Bad Request，错误信息提示name过长 |
| **自动化代码** | `let long_name = "a".repeat(256);`<br>`let response = test_app.create_workbench(&token, &long_name, None).await;`<br>`assert_eq!(response.status(), 400);` |

### TC-S1-013-27: 创建工作台描述超长

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-27 |
| **用例名称** | 创建工作台描述超长 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，description超过1000字符 |
| **预期结果** | 返回400 Bad Request |
| **自动化代码** | `let long_desc = "desc".repeat(300);`<br>`let response = test_app.create_workbench(&token, "Valid Name", Some(&long_desc)).await;`<br>`assert_eq!(response.status(), 400);` |

### TC-S1-013-28: 更新工作台名称为空

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-28 |
| **用例名称** | 更新工作台名称为空 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在一个工作台 |
| **测试步骤** | 1. 发送PUT请求，name设为空字符串 |
| **预期结果** | 返回400 Bad Request |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "Valid", None).await;`<br>`let response = test_app.update_workbench(&token, wb.id, "", None).await;`<br>`assert_eq!(response.status(), 400);` |

### TC-S1-013-29: 无效的owner_type值

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-29 |
| **用例名称** | 无效的owner_type值 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，owner_type设为无效值"invalid" |
| **预期结果** | 返回400 Bad Request |
| **自动化代码** | `let response = test_app.create_workbench_invalid_owner_type(&token, "invalid").await;`<br>`assert_eq!(response.status(), 400);` |

---

## 8. 级联删除测试 (TC-S1-013-30 ~ TC-S1-013-31)

### TC-S1-013-30: 删除工作台级联删除设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-30 |
| **用例名称** | 删除工作台级联删除设备 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，工作台包含设备 |
| **测试步骤** | 1. 创建工作台WB<br>2. 在WB下创建设备D1和D2<br>3. 删除工作台WB<br>4. 验证设备D1和D2也被删除 |
| **预期结果** | DELETE返回204<br>查询设备D1和D2返回404 |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "WB with Devices", None).await;`<br>`let d1 = test_app.create_device(&token, wb.id, "Device 1").await;`<br>`let d2 = test_app.create_device(&token, wb.id, "Device 2").await;`<br>`test_app.delete_workbench(&token, wb.id).await;`<br>`let d1_status = test_app.get_device(&token, d1.id).await.status();`<br>`let d2_status = test_app.get_device(&token, d2.id).await.status();`<br>`assert_eq!(d1_status, 404);`<br>`assert_eq!(d2_status, 404);` |

### TC-S1-013-31: 删除工作台级联删除嵌套设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-31 |
| **用例名称** | 删除工作台级联删除嵌套设备 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，工作台包含嵌套设备结构 |
| **测试步骤** | 1. 创建工作台WB<br>2. 创建父设备P和子设备C(C的parent_id=P)<br>3. 删除工作台WB<br>4. 验证父设备P和子设备C都被删除 |
| **预期结果** | 父设备P和子设备C都被级联删除 |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "WB with Nested", None).await;`<br>`let parent = test_app.create_device(&token, wb.id, "Parent").await;`<br>`let child = test_app.create_child_device(&token, wb.id, parent.id, "Child").await;`<br>`test_app.delete_workbench(&token, wb.id).await;`<br>`let p_status = test_app.get_device(&token, parent.id).await.status();`<br>`let c_status = test_app.get_device(&token, child.id).await.status();`<br>`assert_eq!(p_status, 404);`<br>`assert_eq!(c_status, 404);` |

---

## 9. 分页参数验证测试 (TC-S1-013-32 ~ TC-S1-013-35)

### TC-S1-013-32: 分页size为负数

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-32 |
| **用例名称** | 分页size为负数 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在工作台 |
| **测试步骤** | 1. 发送GET /api/v1/workbenches?page=1&size=-1 |
| **预期结果** | 返回400 Bad Request，错误信息提示size必须为正数 |
| **自动化代码** | `let response = test_app.list_workbenches(&token, 1, -1).await;`<br>`assert_eq!(response.status(), 400);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.contains("size"));` |

### TC-S1-013-33: 分页size为零

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-33 |
| **用例名称** | 分页size为零 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在工作台 |
| **测试步骤** | 1. 发送GET /api/v1/workbenches?page=1&size=0 |
| **预期结果** | 返回400 Bad Request，错误信息提示size必须大于0 |
| **自动化代码** | `let response = test_app.list_workbenches(&token, 1, 0).await;`<br>`assert_eq!(response.status(), 400);` |

### TC-S1-013-34: 分页size为极大值

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-34 |
| **用例名称** | 分页size为极大值 |
| **测试类型** | Integration Test |
| **优先级** | P2 |
| **前置条件** | 用户已登录，存在工作台 |
| **测试步骤** | 1. 发送GET /api/v1/workbenches?page=1&size=1000000 |
| **预期结果** | 返回200 OK，items包含所有工作台（或按系统限制处理） |
| **自动化代码** | `let response = test_app.list_workbenches(&token, 1, 1000000).await;`<br>`assert_eq!(response.status(), 200);`<br>`let page = response.json::<PagedWorkbenchResponse>().await;`<br>`assert_eq!(page.size, 1000000);` |

### TC-S1-013-35: 分页page为负数

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-35 |
| **用例名称** | 分页page为负数 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在工作台 |
| **测试步骤** | 1. 发送GET /api/v1/workbenches?page=-1&size=10 |
| **预期结果** | 返回400 Bad Request，错误信息提示page必须为正数 |
| **自动化代码** | `let response = test_app.list_workbenches(&token, -1, 10).await;`<br>`assert_eq!(response.status(), 400);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.contains("page"));` |

---

## 10. 边界值测试 (TC-S1-013-39 ~ TC-S1-013-42)

### TC-S1-013-39: 更新description为null

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-39 |
| **用例名称** | 更新description为null |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，工作台description有值 |
| **测试步骤** | 1. 创建工作台description=Some("original")<br>2. 发送PUT请求，description设为null |
| **预期结果** | 返回200 OK，description变为null |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "WB", Some("original")).await;`<br>`let response = test_app.update_workbench(&token, wb.id, "WB", None).await;`<br>`let updated = response.json::<WorkbenchResponse>().await;`<br>`assert!(updated.description.is_none());` |

### TC-S1-013-40: 更新description为空字符串

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-40 |
| **用例名称** | 更新description为空字符串 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，工作台存在 |
| **测试步骤** | 1. 创建工作台description=Some("original")<br>2. 发送PUT请求，description设为空字符串"" |
| **预期结果** | 返回200 OK，description变为空字符串（不同于null） |
| **自动化代码** | `let wb = test_app.create_workbench(&token, "WB", Some("original")).await;`<br>`let response = test_app.update_workbench(&token, wb.id, "WB", Some("")).await;`<br>`let updated = response.json::<WorkbenchResponse>().await;`<br>`assert_eq!(updated.description, Some("".to_string()));` |

### TC-S1-013-41: 创建工作台name为纯空白字符

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-41 |
| **用例名称** | 创建工作台name为纯空白字符 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，name为"   "（纯空格） |
| **预期结果** | 返回400 Bad Request，错误信息提示name不能为空白 |
| **自动化代码** | `let response = test_app.create_workbench(&token, "   ", None).await;`<br>`assert_eq!(response.status(), 400);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.contains("name"));` |

### TC-S1-013-42: 无效的status值

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-013-42 |
| **用例名称** | 无效的status值 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，status设为无效值"invalid_status" |
| **预期结果** | 返回400 Bad Request，错误信息提示status无效 |
| **自动化代码** | `let response = test_app.create_workbench_with_status(&token, "Valid Name", "invalid_status").await;`<br>`assert_eq!(response.status(), 400);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.to_lowercase().contains("status"));` |

---

## 11. 测试覆盖率矩阵

| 验收标准 | 相关测试用例 |
|----------|--------------|
| **API端点实现** | TC-S1-013-01, TC-S1-013-06, TC-S1-013-08, TC-S1-013-11, TC-S1-013-16 |
| **列表分页支持** | TC-S1-013-08, TC-S1-013-09, TC-S1-013-10 |
| **分页参数验证** | TC-S1-013-32, TC-S1-013-33, TC-S1-013-34, TC-S1-013-35 |
| **删除工作台级联删除设备** | TC-S1-013-30, TC-S1-013-31 |
| **认证要求** | TC-S1-013-05, TC-S1-013-19, TC-S1-013-20, TC-S1-013-21, TC-S1-013-22 |
| **用户授权(只能访问自己的)** | TC-S1-013-14, TC-S1-013-18, TC-S1-013-23, TC-S1-013-24 |
| **输入验证** | TC-S1-013-04, TC-S1-013-25, TC-S1-013-26, TC-S1-013-27, TC-S1-013-28, TC-S1-013-29 |
| **边界值测试** | TC-S1-013-39, TC-S1-013-40, TC-S1-013-41, TC-S1-013-42 |
| **错误处理** | TC-S1-013-07, TC-S1-013-13, TC-S1-013-17 |

---

## 12. 缺陷报告模板

当测试失败时，使用以下模板报告缺陷：

```markdown
## 缺陷报告

**缺陷ID**: BUG-S1-013-XX
**严重级别**: P0/P1/P2/P3
**测试用例**: TC-S1-013-XX
**摘要**: 
**步骤**:
1. 
2. 
**预期结果**: 
**实际结果**: 
**屏幕截图/日志**: 
**环境**: 
```

---

## 13. API响应格式

### 12.1 成功响应

**创建成功 (201)**:
```json
{
  "code": 201,
  "message": "Workbench created successfully",
  "data": {
    "id": "uuid",
    "name": "Workbench Name",
    "description": "description or null",
    "owner_type": "user",
    "owner_id": "uuid",
    "status": "active",
    "created_at": "2026-03-20T10:00:00Z",
    "updated_at": "2026-03-20T10:00:00Z"
  }
}
```

**查询成功 (200)** - 详情:
```json
{
  "code": 200,
  "message": "Success",
  "data": { ... }
}
```

**分页列表 (200)**:
```json
{
  "code": 200,
  "message": "Success",
  "data": {
    "items": [...],
    "total": 10,
    "page": 1,
    "size": 2
  }
}
```

**删除成功 (204)**: 无响应体

### 12.2 错误响应

**400 Bad Request**:
```json
{
  "code": 400,
  "message": "Validation error: name is required"
}
```

**401 Unauthorized**:
```json
{
  "code": 401,
  "message": "Authentication required"
}
```

**403 Forbidden**:
```json
{
  "code": 403,
  "message": "Access denied"
}
```

**404 Not Found**:
```json
{
  "code": 404,
  "message": "Workbench not found"
}
```

---

**文档结束**

(End of file - total 602 lines)