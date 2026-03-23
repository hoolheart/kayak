# S1-018: 设备与测点CRUD API - 测试用例文档

**任务ID**: S1-018  
**任务名称**: 设备与测点CRUD API (Device and Point CRUD API)  
**文档版本**: 1.0  
**创建日期**: 2026-03-23  
**测试类型**: 集成测试 (Integration Tests)

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S1-018 任务的所有功能测试，包括：

1. **设备CRUD API测试**
   - 创建设备 API (POST /api/v1/workbenches/{workbench_id}/devices)
   - 设备列表查询 API (GET /api/v1/workbenches/{workbench_id}/devices) - 支持分页和树形结构
   - 设备详情查询 API (GET /api/v1/devices/{id})
   - 设备更新 API (PUT /api/v1/devices/{id})
   - 设备删除 API (DELETE /api/v1/devices/{id}) - 级联删除子设备和测点

2. **测点CRUD API测试**
   - 创建测点 API (POST /api/v1/devices/{device_id}/points)
   - 测点列表查询 API (GET /api/v1/devices/{device_id}/points)
   - 测点详情查询 API (GET /api/v1/points/{id})
   - 测点更新 API (PUT /api/v1/points/{id})
   - 测点删除 API (DELETE /api/v1/points/{id})

3. **测点值读写API测试**
   - 读取测点值 API (GET /api/v1/points/{id}/value) - 返回虚拟设备模拟数据
   - 写入测点值 API (PUT /api/v1/points/{id}/value) - 仅支持RW/WO类型

4. **授权与认证测试**
   - 用户权限验证
   - 跨用户访问控制

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 实现设备CRUD API | TC-S1-018-01 ~ TC-S1-018-15 | Integration Test |
| 2. 实现测点CRUD API | TC-S1-018-20 ~ TC-S1-018-35 | Integration Test |
| 3. 读取虚拟设备测点返回模拟数据 | TC-S1-018-40 ~ TC-S1-018-48 | Integration Test |
| 4. 支持设备树形结构 | TC-S1-018-49 ~ TC-S1-018-55 | Integration Test |
| 5. 分页查询支持 | TC-S1-018-08, TC-S1-018-22 | Integration Test |
| 6. 授权验证 | TC-S1-018-16 ~ TC-S1-018-19, TC-S1-018-36 ~ TC-S1-018-39 | Integration Test |

### 1.3 测试环境要求

| 环境项 | 说明 |
|--------|------|
| **技术栈** | Rust / Axum / SQLite / sqlx |
| **认证方式** | JWT Bearer Token |
| **依赖任务** | S1-013 (Workbench CRUD), S1-016 (Device/Point Models), S1-017 (Virtual Driver) |
| **测试框架** | Rust built-in `#[cfg(test)]` + `#[tokio::test]` |

### 1.4 测试用例统计

| 类别 | 用例数量 | 优先级分布 |
|------|---------|-----------|
| 设备CRUD测试 | 15 | P0: 12, P1: 3 |
| 测点CRUD测试 | 16 | P0: 13, P1: 3 |
| 测点值读写测试 | 9 | P0: 7, P1: 2 |
| 设备树形结构测试 | 7 | P0: 5, P1: 2 |
| 授权与错误处理测试 | 8 | P0: 6, P1: 2 |
| **总计** | **55** | P0: 43, P1: 12 |

---

## 2. 设备CRUD API测试 (TC-S1-018-01 ~ TC-S1-018-19)

### TC-S1-018-01: 成功创建设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-01 |
| **用例名称** | 成功创建设备 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，拥有指定workbench |
| **测试步骤** | 1. 发送POST请求到 /api/v1/workbenches/{workbench_id}/devices<br>2. 请求体包含name、protocol_type等必填字段 |
| **预期结果** | 返回201 Created，响应体包含创建的设备信息(id, name, protocol_type, status=Offline) |
| **自动化代码** | `let response = test_app.create_device(&token, workbench_id, "Test Device", ProtocolType::Virtual).await;`<br>`assert_eq!(response.status(), 201);`<br>`let device = response.json::<DeviceResponse>().await;`<br>`assert_eq!(device.name, "Test Device");`<br>`assert_eq!(device.status, DeviceStatus::Offline);` |

---

### TC-S1-018-02: 创建设备仅提供必填字段

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-02 |
| **用例名称** | 创建设备仅提供必填字段 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，拥有指定workbench |
| **测试步骤** | 1. 发送POST请求，仅提供name和protocol_type |
| **预期结果** | 返回201 Created，可选字段(manufacturer, model, sn等)为null |
| **自动化代码** | `let response = test_app.create_device_minimal(&token, workbench_id, "Minimal Device").await;`<br>`assert_eq!(response.status(), 201);`<br>`let device = response.json::<DeviceResponse>().await;`<br>`assert!(device.manufacturer.is_none());` |

---

### TC-S1-018-03: 创建设备指定父设备(树形结构)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-03 |
| **用例名称** | 创建设备指定父设备(树形结构) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，workbench下存在父设备 |
| **测试步骤** | 1. 创建父设备<br>2. 发送POST请求，指定parent_id为父设备ID |
| **预期结果** | 返回201 Created，新设备parent_id指向父设备 |
| **自动化代码** | `let parent = test_app.create_device(&token, workbench_id, "Parent", ProtocolType::Virtual).await;`<br>`let response = test_app.create_device_with_parent(&token, workbench_id, "Child", parent.id).await;`<br>`assert_eq!(response.status(), 201);`<br>`let child = response.json::<DeviceResponse>().await;`<br>`assert_eq!(child.parent_id, Some(parent.id));` |

---

### TC-S1-018-04: 创建设备未提供名称失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-04 |
| **用例名称** | 创建设备未提供名称失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，不提供name字段 |
| **预期结果** | 返回400 Bad Request，错误信息提示name为必填 |
| **自动化代码** | `let response = test_app.create_device_no_name(&token, workbench_id).await;`<br>`assert_eq!(response.status(), 400);`<br>`let error = response.json::<ErrorResponse>().await;`<br>`assert!(error.message.contains("name"));` |

---

### TC-S1-018-05: 创建设备未提供protocol_type失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-05 |
| **用例名称** | 创建设备未提供protocol_type失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，不提供protocol_type字段 |
| **预期结果** | 返回400 Bad Request |
| **自动化代码** | `let response = test_app.create_device_no_protocol(&token, workbench_id, "Test").await;`<br>`assert_eq!(response.status(), 400);` |

---

### TC-S1-018-06: 创建设备指定无效workbench_id失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-06 |
| **用例名称** | 创建设备指定无效workbench_id失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求到不存在的workbench_id |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_wb_id = Uuid::new_v4();`<br>`let response = test_app.create_device(&token, fake_wb_id, "Test", ProtocolType::Virtual).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-07: 创建设备指定不存在的父设备失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-07 |
| **用例名称** | 创建设备指定不存在的父设备失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求，parent_id指向不存在的设备 |
| **预期结果** | 返回400 Bad Request或404 |
| **自动化代码** | `let fake_parent_id = Uuid::new_v4();`<br>`let response = test_app.create_device_with_parent(&token, workbench_id, "Test", fake_parent_id).await;`<br>`assert!(response.status() == 400 \|\| response.status() == 404);` |

---

### TC-S1-018-08: 分页查询设备列表-第一页

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-08 |
| **用例名称** | 分页查询设备列表-第一页 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，workbench下存在多个设备 |
| **测试步骤** | 1. 创建5个设备<br>2. 发送GET /api/v1/workbenches/{workbench_id}/devices?page=1&size=2 |
| **预期结果** | 返回200 OK，包含total、page、size、items字段<br>items包含2个设备 |
| **自动化代码** | `let devices = test_app.create_multiple_devices(&token, workbench_id, 5).await;`<br>`let response = test_app.list_devices(&token, workbench_id, 1, 2).await;`<br>`assert_eq!(response.status(), 200);`<br>`let page = response.json::<PagedDeviceResponse>().await;`<br>`assert_eq!(page.items.len(), 2);`<br>`assert_eq!(page.total, 5);` |

---

### TC-S1-018-09: 分页查询设备列表-第二页

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-09 |
| **用例名称** | 分页查询设备列表-第二页 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在多个设备 |
| **测试步骤** | 1. 创建5个设备<br>2. 发送GET /api/v1/workbenches/{workbench_id}/devices?page=2&size=2 |
| **预期结果** | 返回200 OK，items包含第3-4个设备 |
| **自动化代码** | `let response = test_app.list_devices(&token, workbench_id, 2, 2).await;`<br>`let page = response.json::<PagedDeviceResponse>().await;`<br>`assert_eq!(page.items.len(), 2);`<br>`assert_eq!(page.page, 2);` |

---

### TC-S1-018-10: 获取设备详情成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-10 |
| **用例名称** | 获取设备详情成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 创建设备<br>2. 发送GET /api/v1/devices/{id} |
| **预期结果** | 返回200 OK，响应体包含设备完整信息 |
| **自动化代码** | `let device = test_app.create_device(&token, workbench_id, "Detail Device", ProtocolType::Virtual).await;`<br>`let response = test_app.get_device(&token, device.id).await;`<br>`assert_eq!(response.status(), 200);`<br>`let detail = response.json::<DeviceResponse>().await;`<br>`assert_eq!(detail.id, device.id);` |

---

### TC-S1-018-11: 获取不存在的设备详情失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-11 |
| **用例名称** | 获取不存在的设备详情失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送GET请求到随机UUID |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.get_device(&token, fake_id).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-12: 成功更新设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-12 |
| **用例名称** | 成功更新设备 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 创建设备<br>2. 发送PUT请求更新name、manufacturer等字段 |
| **预期结果** | 返回200 OK，设备信息已更新 |
| **自动化代码** | `let device = test_app.create_device(&token, workbench_id, "Old Name", ProtocolType::Virtual).await;`<br>`let response = test_app.update_device(&token, device.id, "New Name", Some("New Manufacturer")).await;`<br>`assert_eq!(response.status(), 200);`<br>`let updated = response.json::<DeviceResponse>().await;`<br>`assert_eq!(updated.name, "New Name");` |

---

### TC-S1-018-13: 部分更新设备(只更新名称)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-13 |
| **用例名称** | 部分更新设备(只更新名称) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 创建设备(带manufacturer)<br>2. 发送PUT请求只更新name |
| **预期结果** | 返回200 OK，name已更新，manufacturer保持不变 |
| **自动化代码** | `let device = test_app.create_device_full(&token, workbench_id, "Name", Some("Old Manu")).await;`<br>`let response = test_app.update_device_name_only(&token, device.id, "New Name").await;`<br>`let updated = response.json::<DeviceResponse>().await;`<br>`assert_eq!(updated.name, "New Name");`<br>`assert_eq!(updated.manufacturer, Some("Old Manu".to_string()));` |

---

### TC-S1-018-14: 更新不存在的设备失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-14 |
| **用例名称** | 更新不存在的设备失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送PUT请求到随机UUID |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.update_device(&token, fake_id, "Name", None).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-15: 删除设备(级联删除子设备)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-15 |
| **用例名称** | 删除设备(级联删除子设备) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在父子设备关系 |
| **测试步骤** | 1. 创建父设备和子设备<br>2. 发送DELETE请求删除父设备 |
| **预期结果** | 返回204 No Content<br>父设备和子设备都被删除 |
| **自动化代码** | `let parent = test_app.create_device(&token, workbench_id, "Parent", ProtocolType::Virtual).await;`<br>`let child = test_app.create_device_with_parent(&token, workbench_id, "Child", parent.id).await;`<br>`let response = test_app.delete_device(&token, parent.id).await;`<br>`assert_eq!(response.status(), 204);`<br>`// 验证父设备和子设备都已删除`<br>`assert!(test_app.get_device(&token, parent.id).await.status() == 404);`<br>`assert!(test_app.get_device(&token, child.id).await.status() == 404);` |

---

### TC-S1-018-16: 删除设备(级联删除测点)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-16 |
| **用例名称** | 删除设备(级联删除测点) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备下存在测点 |
| **测试步骤** | 1. 创建设备和测点<br>2. 发送DELETE请求删除设备 |
| **预期结果** | 返回204 No Content<br>设备及其所有测点都被删除 |
| **自动化代码** | `let device = test_app.create_device(&token, workbench_id, "Device", ProtocolType::Virtual).await;`<br>`let point = test_app.create_point(&token, device.id, "Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.delete_device(&token, device.id).await;`<br>`assert_eq!(response.status(), 204);`<br>`assert!(test_app.get_point(&token, point.id).await.status() == 404);` |

---

### TC-S1-018-17: 未拥有workbench的用户创建设备失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-17 |
| **用例名称** | 未拥有workbench的用户创建设备失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A创建workbench，用户B未授权 |
| **测试步骤** | 1. 用户A创建workbench<br>2. 用户B尝试在用户A的workbench下创建设备 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let wb = test_app.create_workbench(&token_a, "WB", None).await;`<br>`let response = test_app.create_device(&token_b, wb.id, "Device", ProtocolType::Virtual).await;`<br>`assert_eq!(response.status(), 403);` |

---

### TC-S1-018-18: 未登录创建设备失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-18 |
| **用例名称** | 未登录创建设备失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 无Token |
| **测试步骤** | 1. 发送POST请求到 /api/v1/workbenches/{workbench_id}/devices，不带Authorization头 |
| **预期结果** | 返回401 Unauthorized |
| **自动化代码** | `let response = test_app.create_device_unauthenticated(workbench_id, "Device").await;`<br>`assert_eq!(response.status(), 401);` |

---

### TC-S1-018-19: 更新设备状态

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-19 |
| **用例名称** | 更新设备状态 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 创建设备<br>2. 发送PUT请求更新status为Online |
| **预期结果** | 返回200 OK，设备状态已更新 |
| **自动化代码** | `let device = test_app.create_device(&token, workbench_id, "Device", ProtocolType::Virtual).await;`<br>`let response = test_app.update_device_status(&token, device.id, DeviceStatus::Online).await;`<br>`assert_eq!(response.status(), 200);`<br>`let updated = response.json::<DeviceResponse>().await;`<br>`assert_eq!(updated.status, DeviceStatus::Online);` |

---

## 3. 测点CRUD API测试 (TC-S1-018-20 ~ TC-S1-018-39)

### TC-S1-018-20: 成功创建测点

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-20 |
| **用例名称** | 成功创建测点 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 创建设备<br>2. 发送POST请求到 /api/v1/devices/{device_id}/points |
| **预期结果** | 返回201 Created，响应体包含创建的测点信息 |
| **自动化代码** | `let device = test_app.create_device(&token, workbench_id, "Device", ProtocolType::Virtual).await;`<br>`let response = test_app.create_point(&token, device.id, "Temperature", DataType::Number, AccessType::RO).await;`<br>`assert_eq!(response.status(), 201);`<br>`let point = response.json::<PointResponse>().await;`<br>`assert_eq!(point.name, "Temperature");` |

---

### TC-S1-018-21: 创建测点支持所有数据类型

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-21 |
| **用例名称** | 创建测点支持所有数据类型 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 为每种DataType创建对应测点：Number、Integer、String、Boolean |
| **预期结果** | 所有测点创建成功，返回201 |
| **自动化代码** | `for dtype in [DataType::Number, DataType::Integer, DataType::String, DataType::Boolean] {`<br>`    let response = test_app.create_point(&token, device.id, &format!("Point_{:?}", dtype), dtype, AccessType::RO).await;`<br>`    assert_eq!(response.status(), 201);`<br>`}` |

---

### TC-S1-018-22: 分页查询测点列表

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-22 |
| **用例名称** | 分页查询测点列表 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备下存在多个测点 |
| **测试步骤** | 1. 创建5个测点<br>2. 发送GET /api/v1/devices/{device_id}/points?page=1&size=3 |
| **预期结果** | 返回200 OK，包含分页信息，items包含3个测点 |
| **自动化代码** | `let points = test_app.create_multiple_points(&token, device.id, 5).await;`<br>`let response = test_app.list_points(&token, device.id, 1, 3).await;`<br>`let page = response.json::<PagedPointResponse>().await;`<br>`assert_eq!(page.items.len(), 3);`<br>`assert_eq!(page.total, 5);` |

---

### TC-S1-018-23: 获取测点详情成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-23 |
| **用例名称** | 获取测点详情成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，测点存在 |
| **测试步骤** | 1. 创建设备和测点<br>2. 发送GET /api/v1/points/{id} |
| **预期结果** | 返回200 OK，响应体包含测点完整信息 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.get_point(&token, point.id).await;`<br>`assert_eq!(response.status(), 200);`<br>`let detail = response.json::<PointResponse>().await;`<br>`assert_eq!(detail.id, point.id);` |

---

### TC-S1-018-24: 获取不存在的测点详情失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-24 |
| **用例名称** | 获取不存在的测点详情失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送GET请求到随机UUID |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.get_point(&token, fake_id).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-25: 成功更新测点

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-25 |
| **用例名称** | 成功更新测点 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，测点存在 |
| **测试步骤** | 1. 创建设备和测点<br>2. 发送PUT请求更新name、unit等字段 |
| **预期结果** | 返回200 OK，测点信息已更新 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "Old Name", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.update_point(&token, point.id, "New Name", Some("°C")).await;`<br>`assert_eq!(response.status(), 200);`<br>`let updated = response.json::<PointResponse>().await;`<br>`assert_eq!(updated.name, "New Name");` |

---

### TC-S1-018-26: 更新测点更新min_value和max_value

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-26 |
| **用例名称** | 更新测点更新min_value和max_value |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，测点存在 |
| **测试步骤** | 1. 创建设备和测点<br>2. 发送PUT请求更新min_value和max_value |
| **预期结果** | 返回200 OK，范围已更新 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "Temp", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.update_point_range(&token, point.id, 0.0, 100.0).await;`<br>`let updated = response.json::<PointResponse>().await;`<br>`assert_eq!(updated.min_value, Some(0.0));`<br>`assert_eq!(updated.max_value, Some(100.0));` |

---

### TC-S1-018-27: 更新不存在的测点失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-27 |
| **用例名称** | 更新不存在的测点失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送PUT请求到随机UUID |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.update_point(&token, fake_id, "Name", None).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-28: 成功删除测点

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-28 |
| **用例名称** | 成功删除测点 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，测点存在 |
| **测试步骤** | 1. 创建设备和测点<br>2. 发送DELETE请求到 /api/v1/points/{id} |
| **预期结果** | 返回204 No Content，测点已删除 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.delete_point(&token, point.id).await;`<br>`assert_eq!(response.status(), 204);`<br>`assert!(test_app.get_point(&token, point.id).await.status() == 404);` |

---

### TC-S1-018-29: 删除不存在的测点失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-29 |
| **用例名称** | 删除不存在的测点失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送DELETE请求到随机UUID |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.delete_point(&token, fake_id).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-30: 创建设备下第一个测点(无设备ID)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-30 |
| **用例名称** | 创建设备下第一个测点 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，设备存在但无测点 |
| **测试步骤** | 1. 创建设备<br>2. 发送POST请求创建设备的第一个测点 |
| **预期结果** | 返回201 Created，测点创成功 |
| **自动化代码** | `let device = test_app.create_device(&token, workbench_id, "Device", ProtocolType::Virtual).await;`<br>`let response = test_app.create_point(&token, device.id, "First Point", DataType::Number, AccessType::RO).await;`<br>`assert_eq!(response.status(), 201);` |

---

### TC-S1-018-31: 创建测点设置默认值

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-31 |
| **用例名称** | 创建测点设置默认值 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 发送POST请求，指定default_value字段 |
| **预期结果** | 返回201 Created，default_value已保存 |
| **自动化代码** | `let response = test_app.create_point_with_default(&token, device.id, "Point", DataType::Number, AccessType::RW, Some(json!(25.0))).await;`<br>`let point = response.json::<PointResponse>().await;`<br>`assert_eq!(point.default_value, Some(json!(25.0)));` |

---

### TC-S1-018-32: 创建测点验证范围设置

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-32 |
| **用例名称** | 创建测点验证范围设置 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 发送POST请求，指定min_value、max_value |
| **预期结果** | 返回201 Created，范围已保存 |
| **自动化代码** | `let response = test_app.create_point_with_range(&token, device.id, "Temp", DataType::Number, AccessType::RO, 0.0, 100.0).await;`<br>`let point = response.json::<PointResponse>().await;`<br>`assert_eq!(point.min_value, Some(0.0));`<br>`assert_eq!(point.max_value, Some(100.0));` |

---

### TC-S1-018-33: 创建测点未提供设备ID失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-33 |
| **用例名称** | 创建测点未提供设备ID失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送POST请求到无效的device_id |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_device_id = Uuid::new_v4();`<br>`let response = test_app.create_point(&token, fake_device_id, "Point", DataType::Number, AccessType::RO).await;`<br>`assert_eq!(response.status(), 404);` |

---

### TC-S1-018-34: 创建设置测点状态为Disabled

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-34 |
| **用例名称** | 创建设置测点状态为Disabled |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，设备存在 |
| **测试步骤** | 1. 发送POST请求，指定status为Disabled |
| **预期结果** | 返回201 Created，测点状态为Disabled |
| **自动化代码** | `let response = test_app.create_point_with_status(&token, device.id, "Point", DataType::Number, AccessType::RO, PointStatus::Disabled).await;`<br>`let point = response.json::<PointResponse>().await;`<br>`assert_eq!(point.status, PointStatus::Disabled);` |

---

### TC-S1-018-35: 更新测点状态

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-35 |
| **用例名称** | 更新测点状态 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，测点存在 |
| **测试步骤** | 1. 创建设置status为Disabled的测点<br>2. 发送PUT请求更新status为Active |
| **预期结果** | 返回200 OK，状态已更新 |
| **自动化代码** | `let point = test_app.create_point_with_status(&token, device.id, "Point", DataType::Number, AccessType::RO, PointStatus::Disabled).await;`<br>`let response = test_app.update_point_status(&token, point.id, PointStatus::Active).await;`<br>`let updated = response.json::<PointResponse>().await;`<br>`assert_eq!(updated.status, PointStatus::Active);` |

---

### TC-S1-018-36: 未拥有设备的用户创建测点失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-36 |
| **用例名称** | 未拥有设备的用户创建测点失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A创建设备，用户B未授权 |
| **测试步骤** | 1. 用户A创建设备<br>2. 用户B尝试在用户A的设备下创建测点 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let device = test_app.create_device(&token_a, workbench_id, "Device", ProtocolType::Virtual).await;`<br>`let response = test_app.create_point(&token_b, device.id, "Point", DataType::Number, AccessType::RO).await;`<br>`assert_eq!(response.status(), 403);` |

---

### TC-S1-018-37: 未登录创建测点失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-37 |
| **用例名称** | 未登录创建测点失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 无Token |
| **测试步骤** | 1. 发送POST请求，不带Authorization头 |
| **预期结果** | 返回401 Unauthorized |
| **自动化代码** | `let response = test_app.create_point_unauthenticated(device.id, "Point").await;`<br>`assert_eq!(response.status(), 401);` |

---

### TC-S1-018-38: 未授权用户获取测点详情失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-38 |
| **用例名称** | 未授权用户获取测点详情失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A创建设备和测点，用户B未授权 |
| **测试步骤** | 1. 用户A创建设备和测点<br>2. 用户B尝试获取该测点详情 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let point = test_app.create_point(&token_a, device.id, "Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.get_point(&token_b, point.id).await;`<br>`assert_eq!(response.status(), 403);` |

---

### TC-S1-018-39: 未授权用户删除测点失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-39 |
| **用例名称** | 未授权用户删除测点失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户A创建设备和测点，用户B未授权 |
| **测试步骤** | 1. 用户A创建设备和测点<br>2. 用户B尝试删除该测点 |
| **预期结果** | 返回403 Forbidden |
| **自动化代码** | `let point = test_app.create_point(&token_a, device.id, "Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.delete_point(&token_b, point.id).await;`<br>`assert_eq!(response.status(), 403);` |

---

## 4. 测点值读写API测试 (TC-S1-018-40 ~ TC-S1-018-48)

### TC-S1-018-40: 读取虚拟设备测点值(Random模式)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-40 |
| **用例名称** | 读取虚拟设备测点值(Random模式) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，虚拟设备存在，设备配置为Random模式 |
| **测试步骤** | 1. 创建设备，配置VirtualConfig mode=Random<br>2. 创建测点<br>3. 发送GET请求到 /api/v1/points/{id}/value |
| **预期结果** | 返回200 OK，value在min_value和max_value范围内随机生成 |
| **自动化代码** | `let device = test_app.create_virtual_device_with_config(&token, workbench_id, "Random Device", VirtualConfig { mode: VirtualMode::Random, min_value: 0.0, max_value: 100.0, .. }).await;`<br>`let point = test_app.create_point(&token, device.id, "Random Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.read_point_value(&token, point.id).await;`<br>`assert_eq!(response.status(), 200);`<br>`let value = response.json::<PointValueResponse>().await;`<br>`assert!(value.value.as_f64() >= 0.0 && value.value.as_f64() <= 100.0);` |

---

### TC-S1-018-41: 读取虚拟设备测点值(Fixed模式)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-41 |
| **用例名称** | 读取虚拟设备测点值(Fixed模式) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，虚拟设备配置为Fixed模式 |
| **测试步骤** | 1. 创建设备，配置VirtualConfig mode=Fixed, fixed_value=42.0<br>2. 创建测点<br>3. 读取测点值 |
| **预期结果** | 返回200 OK，value始终为42.0 |
| **自动化代码** | `let device = test_app.create_virtual_device_with_config(&token, workbench_id, "Fixed Device", VirtualConfig { mode: VirtualMode::Fixed, fixed_value: json!(42.0), .. }).await;`<br>`let point = test_app.create_point(&token, device.id, "Fixed Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.read_point_value(&token, point.id).await;`<br>`let value = response.json::<PointValueResponse>().await;`<br>`assert_eq!(value.value, json!(42.0));` |

---

### TC-S1-018-42: 读取虚拟设备测点值(Sine模式)

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-42 |
| **用例名称** | 读取虚拟设备测点值(Sine模式) |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，虚拟设备配置为Sine模式 |
| **测试步骤** | 1. 创建设备，配置VirtualConfig mode=Sine<br>2. 创建测点<br>3. 多次读取测点值，验证值呈正弦波形 |
| **预期结果** | 返回200 OK，值在范围内周期性变化 |
| **自动化代码** | `let device = test_app.create_virtual_device_with_config(&token, workbench_id, "Sine Device", VirtualConfig { mode: VirtualMode::Sine, min_value: 0.0, max_value: 100.0, .. }).await;`<br>`let point = test_app.create_point(&token, device.id, "Sine Point", DataType::Number, AccessType::RO).await;`<br>`// 读取多次，验证波形`<br>`let values: Vec<f64> = (0..10).map(|_| {`<br>`    let resp = test_app.read_point_value(&token, point.id).await;`<br>`    resp.json::<PointValueResponse>().await.value.as_f64().unwrap()`<br>`}).collect();`<br>`// 验证值在范围内`<br>`for v in &values { assert!(*v >= 0.0 && *v <= 100.0); }` |

---

### TC-S1-018-43: 读取RO类型测点值成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-43 |
| **用例名称** | 读取RO类型测点值成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，RO类型测点存在 |
| **测试步骤** | 1. 创建AccessType=RO的测点<br>2. 读取测点值 |
| **预期结果** | 返回200 OK，成功读取值 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "RO Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.read_point_value(&token, point.id).await;`<br>`assert_eq!(response.status(), 200);` |

---

### TC-S1-018-44: 读取RW类型测点值成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-44 |
| **用例名称** | 读取RW类型测点值成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，RW类型测点存在 |
| **测试步骤** | 1. 创建AccessType=RW的测点<br>2. 读取测点值 |
| **预期结果** | 返回200 OK，成功读取值 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "RW Point", DataType::Number, AccessType::RW).await;`<br>`let response = test_app.read_point_value(&token, point.id).await;`<br>`assert_eq!(response.status(), 200);` |

---

### TC-S1-018-45: 写入WO类型测点值成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-45 |
| **用例名称** | 写入WO类型测点值成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，WO类型测点存在 |
| **测试步骤** | 1. 创建AccessType=WO的测点<br>2. 发送PUT请求写入值 |
| **预期结果** | 返回200 OK，写入成功 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "WO Point", DataType::Number, AccessType::WO).await;`<br>`let response = test_app.write_point_value(&token, point.id, json!(50.0)).await;`<br>`assert_eq!(response.status(), 200);` |

---

### TC-S1-018-46: 写入RW类型测点值成功

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-46 |
| **用例名称** | 写入RW类型测点值成功 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，RW类型测点存在 |
| **测试步骤** | 1. 创建AccessType=RW的测点<br>2. 发送PUT请求写入值<br>3. 读取值验证 |
| **预期结果** | 返回200 OK，写入后读取返回相同值 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "RW Point", DataType::Number, AccessType::RW).await;`<br>`test_app.write_point_value(&token, point.id, json!(75.0)).await;`<br>`let read_resp = test_app.read_point_value(&token, point.id).await;`<br>`let value = read_resp.json::<PointValueResponse>().await;`<br>`assert_eq!(value.value, json!(75.0));` |

---

### TC-S1-018-47: 写入RO类型测点值失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-47 |
| **用例名称** | 写入RO类型测点值失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，RO类型测点存在 |
| **测试步骤** | 1. 创建AccessType=RO的测点<br>2. 发送PUT请求写入值 |
| **预期结果** | 返回400 Bad Request，错误提示RO类型不可写 |
| **自动化代码** | `let point = test_app.create_point(&token, device.id, "RO Point", DataType::Number, AccessType::RO).await;`<br>`let response = test_app.write_point_value(&token, point.id, json!(50.0)).await;`<br>`assert_eq!(response.status(), 400);` |

---

### TC-S1-018-48: 读取不存在的测点值失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-48 |
| **用例名称** | 读取不存在的测点值失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送GET请求到随机UUID的测点值 |
| **预期结果** | 返回404 Not Found |
| **自动化代码** | `let fake_id = Uuid::new_v4();`<br>`let response = test_app.read_point_value(&token, fake_id).await;`<br>`assert_eq!(response.status(), 404);` |

---

## 5. 设备树形结构测试 (TC-S1-018-49 ~ TC-S1-018-55)

### TC-S1-018-49: 创建多层嵌套设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-49 |
| **用例名称** | 创建多层嵌套设备 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 创建根设备<br>2. 创建子设备(level=1)<br>3. 创建子设备的子设备(level=2) |
| **预期结果** | 所有层级设备创建成功，父子关系正确 |
| **自动化代码** | `let root = test_app.create_device(&token, wb, "Root", ProtocolType::Virtual).await;`<br>`let level1 = test_app.create_device_with_parent(&token, wb, "Level1", root.id).await;`<br>`let level2 = test_app.create_device_with_parent(&token, wb, "Level2", level1.id).await;`<br>`assert_eq!(level2.parent_id, Some(level1.id));` |

---

### TC-S1-018-50: 查询设备列表返回树形结构

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-50 |
| **用例名称** | 查询设备列表返回树形结构 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在父子设备关系 |
| **测试步骤** | 1. 创建父子设备<br>2. 发送GET /api/v1/workbenches/{workbench_id}/devices |
| **预期结果** | 返回200 OK，设备列表包含父子设备，parent_id正确 |
| **自动化代码** | `let root = test_app.create_device(&token, wb, "Root", ProtocolType::Virtual).await;`<br>`let child = test_app.create_device_with_parent(&token, wb, "Child", root.id).await;`<br>`let response = test_app.list_devices(&token, wb, 1, 10).await;`<br>`let page = response.json::<PagedDeviceResponse>().await;`<br>`assert!(page.items.iter().any(|d| d.id == root.id && d.parent_id.is_none()));`<br>`assert!(page.items.iter().any(|d| d.id == child.id && d.parent_id == Some(root.id)));` |

---

### TC-S1-018-51: 删除父设备级联删除所有子设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-51 |
| **用例名称** | 删除父设备级联删除所有子设备 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在多层嵌套设备 |
| **测试步骤** | 1. 创建3层嵌套设备<br>2. 删除根设备 |
| **预期结果** | 返回204 No Content，所有层级设备都被删除 |
| **自动化代码** | `let root = test_app.create_device(&token, wb, "Root", ProtocolType::Virtual).await;`<br>`let l1 = test_app.create_device_with_parent(&token, wb, "L1", root.id).await;`<br>`let l2 = test_app.create_device_with_parent(&token, wb, "L2", l1.id).await;`<br>`test_app.delete_device(&token, root.id).await;`<br>`assert!(test_app.get_device(&token, root.id).await.status() == 404);`<br>`assert!(test_app.get_device(&token, l1.id).await.status() == 404);`<br>`assert!(test_app.get_device(&token, l2.id).await.status() == 404);` |

---

### TC-S1-018-52: 通过parent_id过滤查询设备列表

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-52 |
| **用例名称** | 通过parent_id过滤查询设备列表 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，存在父子设备关系 |
| **测试步骤** | 1. 创建多个子设备<br>2. 发送GET /api/v1/workbenches/{workbench_id}/devices?parent_id={parent_id} |
| **预期结果** | 返回200 OK，只返回指定父设备的子设备 |
| **自动化代码** | `let parent = test_app.create_device(&token, wb, "Parent", ProtocolType::Virtual).await;`<br>`let child1 = test_app.create_device_with_parent(&token, wb, "Child1", parent.id).await;`<br>`let child2 = test_app.create_device_with_parent(&token, wb, "Child2", parent.id).await;`<br>`let response = test_app.list_devices_with_parent_filter(&token, wb, parent.id, 1, 10).await;`<br>`let page = response.json::<PagedDeviceResponse>().await;`<br>`assert_eq!(page.items.len(), 2);`<br>`assert!(page.items.iter().all(|d| d.parent_id == Some(parent.id)));` |

---

### TC-S1-018-53: 创建循环引用父设备失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-53 |
| **用例名称** | 创建循环引用父设备失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 创建设备A<br>2. 尝试将设备A的parent_id设置为自己 |
| **预期结果** | 返回400 Bad Request |
| **自动化代码** | `let device = test_app.create_device(&token, wb, "Device", ProtocolType::Virtual).await;`<br>`let response = test_app.create_device_with_parent(&token, wb, "Self Ref", device.id).await;`<br>`assert!(response.status() == 400 || response.status() == 409);` |

---

### TC-S1-018-54: 创建跨层循环引用失败

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-54 |
| **用例名称** | 创建跨层循环引用失败 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，存在父子设备A->B |
| **测试步骤** | 1. 创建设备A和设备B(A是B的父设备)<br>2. 尝试将A的parent_id设置为B |
| **预期结果** | 返回400 Bad Request或409 Conflict |
| **自动化代码** | `let a = test_app.create_device(&token, wb, "A", ProtocolType::Virtual).await;`<br>`let b = test_app.create_device_with_parent(&token, wb, "B", a.id).await;`<br>`let response = test_app.update_device_parent(&token, a.id, b.id).await;`<br>`assert!(response.status() == 400 \|\| response.status() == 409);` |

---

### TC-S1-018-55: 设备树删除保留兄弟设备

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-018-55 |
| **用例名称** | 设备树删除保留兄弟设备 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录，同一父下有多个子设备 |
| **测试步骤** | 1. 创建父设备<br>2. 创建两个子设备A和B<br>3. 删除子设备A |
| **预期结果** | 返回204 No Content，子设备A已删除，B保留，父设备保留 |
| **自动化代码** | `let parent = test_app.create_device(&token, wb, "Parent", ProtocolType::Virtual).await;`<br>`let child_a = test_app.create_device_with_parent(&token, wb, "A", parent.id).await;`<br>`let child_b = test_app.create_device_with_parent(&token, wb, "B", parent.id).await;`<br>`test_app.delete_device(&token, child_a.id).await;`<br>`assert!(test_app.get_device(&token, child_a.id).await.status() == 404);`<br>`assert!(test_app.get_device(&token, child_b.id).await.status() == 200);`<br>`assert!(test_app.get_device(&token, parent.id).await.status() == 200);` |

---

## 6. 附录

### 6.1 错误码说明

| 错误码 | 说明 |
|--------|------|
| 400 Bad Request | 请求参数错误或缺少必填字段 |
| 401 Unauthorized | 未提供认证信息或Token无效 |
| 403 Forbidden | 用户无权访问该资源 |
| 404 Not Found | 资源不存在 |
| 409 Conflict | 资源冲突(如循环引用) |
| 500 Internal Server Error | 服务器内部错误 |

### 6.2 测试数据结构

**PagedDeviceResponse**:
```json
{
  "total": 10,
  "page": 1,
  "size": 10,
  "items": [...]
}
```

**DeviceResponse**:
```json
{
  "id": "uuid",
  "workbench_id": "uuid",
  "parent_id": "uuid or null",
  "name": "string",
  "protocol_type": "Virtual|ModbusTcp|...",
  "protocol_params": {},
  "manufacturer": "string or null",
  "model": "string or null",
  "sn": "string or null",
  "status": "Offline|Online|Error",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

**PointResponse**:
```json
{
  "id": "uuid",
  "device_id": "uuid",
  "name": "string",
  "data_type": "Number|Integer|String|Boolean",
  "access_type": "RO|WO|RW",
  "unit": "string or null",
  "description": "string or null",
  "min_value": "number or null",
  "max_value": "number or null",
  "default_value": "any or null",
  "status": "Active|Disabled",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

**PointValueResponse**:
```json
{
  "point_id": "uuid",
  "value": "any",
  "timestamp": "datetime"
}
```

---

**文档结束**