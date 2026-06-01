# TASK-015 测试用例 — 设备 Service + Provider & 测点 Service + Provider

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待开发完成后执行
> **关联任务**: TASK-015（设备 Service + Provider）+ TASK-018（测点 Service + Provider）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md) §M5 设备管理, §M6 测点管理

---

## 测试范围

TASK-015 实现设备与测点相关的 Service 层和 State 管理层，包含以下组件：

| 组件 | 文件 | 角色 |
|------|------|------|
| DeviceService | `lib/services/device_service.dart` | 设备 CRUD + 连接管理 HTTP API 封装 |
| DeviceTreeNotifier | `lib/providers/device_provider.dart` | 设备树状态管理（平铺列表 → 树结构） |
| DeviceDetailNotifier | `lib/providers/device_provider.dart` | 单设备详情 + 操作状态管理 |
| PointService | `lib/services/point_service.dart` | 测点 CRUD + 值读写 HTTP API 封装 |
| PointListNotifier | `lib/providers/point_provider.dart` | 设备下测点列表 + 实时值状态管理 |

---

## 依赖组件与 API

### 后端 API（设备）

| API | 方法 | 说明 |
|-----|------|------|
| `GET /api/v1/devices` | GET | 设备列表（支持 `workbench_id` 查询参数筛选） |
| `POST /api/v1/devices` | POST | 添加设备 |
| `GET /api/v1/devices/{id}` | GET | 设备详情 |
| `PUT /api/v1/devices/{id}` | PUT | 更新设备 |
| `DELETE /api/v1/devices/{id}` | DELETE | 删除设备 |
| `POST /api/v1/devices/{id}/test-connection` | POST | 测试连接 |
| `POST /api/v1/devices/{id}/connect` | POST | 连接设备 |
| `POST /api/v1/devices/{id}/disconnect` | POST | 断开设备 |
| `GET /api/v1/devices/{id}/status` | GET | 设备状态 |

### 后端 API（测点）

| API | 方法 | 说明 |
|-----|------|------|
| `GET /api/v1/points` | GET | 测点列表（支持 `device_id` 查询参数筛选） |
| `POST /api/v1/points` | POST | 添加测点 |
| `GET /api/v1/points/{id}` | GET | 测点详情 |
| `PUT /api/v1/points/{id}` | PUT | 更新测点 |
| `DELETE /api/v1/points/{id}` | DELETE | 删除测点 |
| `GET /api/v1/points/{id}/value` | GET | 读取测点值 |
| `PUT /api/v1/points/{id}/value` | PUT | 写入测点值 |

### 已有数据模型

| 模型 | 文件 | 关键字段 |
|------|------|----------|
| Device | `lib/models/device.dart` | id, workbenchId, parentId, name, protocolType, protocolParams, status |
| DeviceTreeNode | `lib/models/device.dart` | 继承 Device + children 递归列表 |
| ProtocolType | `lib/models/device.dart` | virtual, modbusTcp, modbusRtu, can, visa, mqtt |
| Point | `lib/models/point.dart` | id, deviceId, name, dataType, accessType, unit, minValue, maxValue, status |
| PointValue | `lib/models/point.dart` | pointId, value, timestamp |
| DataType | `lib/models/point.dart` | number, integer, string, boolean |
| AccessType | `lib/models/point.dart` | ro, wo, rw |

### 已有基础设施

| 组件 | 文件 | 说明 |
|------|------|------|
| ApiClient | `lib/services/api_client.dart` | Dio HTTP 客户端（GET/POST/PUT/DELETE） |
| ApiResponse\<T\> | `lib/models/common.dart` | 统一 API 响应格式 `{code, message, data}` |
| apiClientProvider | `lib/providers/services.dart` | ApiClient 的 Riverpod Provider |

---

## 一、DeviceService 测试用例（12 项）

### TC-DS-001: 列出工作台下所有设备 — 正常数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 列表查询 |
| **关联验收标准** | 设备列表正确加载 |

**前置条件**：
- Mock ApiClient 返回设备列表 JSON
- 工作台 `wb-1` 下有 3 个设备（1 个根设备 + 2 个子设备）

**测试步骤**：
1. 调用 `DeviceService.listByWorkbench('wb-1')`
2. 验证 API 调用参数
3. 验证返回结果

**预期结果**：
- ✅ `ApiClient.get()` 被调用，path 为 `/api/v1/devices`
- ✅ queryParameters 包含 `workbench_id: 'wb-1'`
- ✅ 返回 `List<Device>`，长度为 3
- ✅ 每个 Device 的字段正确解析（id, name, protocolType, status 等）
- ✅ 子设备包含有效的 `parentId`

**失败判定**：
- ❌ 未传递 workbench_id 查询参数
- ❌ 返回数据解析失败
- ❌ 子设备 parentId 为 null

---

### TC-DS-002: 列出设备 — 空工作台

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceService / 边界情况 |
| **关联验收标准** | 空数据正确处理 |

**前置条件**：
- Mock ApiClient 返回空列表 `[]`

**测试步骤**：
1. 调用 `DeviceService.listByWorkbench('wb-empty')`
2. 验证返回结果

**预期结果**：
- ✅ 返回空列表 `[]`
- ✅ 不抛出异常
- ✅ ApiClient 正常调用

**失败判定**：
- ❌ 空数据时抛出异常
- ❌ 返回 null 而非空列表

---

### TC-DS-003: 列出设备 — 网络错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 错误处理 |
| **关联验收标准** | 网络错误正确传播 |

**前置条件**：
- Mock ApiClient.get() 抛出 `DioException`（connectionError 类型）

**测试步骤**：
1. 调用 `DeviceService.listByWorkbench('wb-1')`
2. 验证异常

**预期结果**：
- ✅ 抛出 `DioException`（Service 层不吞异常）
- ✅ 异常类型为 `connectionError`
- ✅ Provider 层可捕获并映射为用户可读消息

**失败判定**：
- ❌ Service 层捕获并吞掉异常
- ❌ 返回 null 掩盖错误

---

### TC-DS-004: 获取设备详情 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-004 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 详情查询 |
| **关联验收标准** | 设备详情正确加载 |

**前置条件**：
- Mock ApiClient 返回单设备 JSON

**测试步骤**：
1. 调用 `DeviceService.getById('dev-1')`
2. 验证 API 调用和返回值

**预期结果**：
- ✅ `ApiClient.get()` 被调用，path 为 `/api/v1/devices/dev-1`
- ✅ 返回 `Device` 对象，id 为 `dev-1`
- ✅ 所有字段正确解析（protocolType, protocolParams, status 等）

**失败判定**：
- ❌ Device 解析失败
- ❌ protocolType 枚举映射错误

---

### TC-DS-005: 获取设备详情 — 设备不存在（404）

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 错误处理 |
| **关联验收标准** | 404 错误正确传播 |

**前置条件**：
- Mock ApiClient.get() 抛出 `DioException`（404）

**测试步骤**：
1. 调用 `DeviceService.getById('non-existent')`

**预期结果**：
- ✅ 抛出 `DioException`，statusCode 为 404
- ✅ Provider 层可捕获并显示"设备不存在"

**失败判定**：
- ❌ Service 层吞掉异常返回 null
- ❌ 404 与其他错误无法区分

---

### TC-DS-006: 创建设备 — Virtual 协议成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 创建 |
| **关联验收标准** | 三种协议设备均可创建 |

**前置条件**：
- Mock ApiClient.post() 返回新设备 JSON

**测试步骤**：
1. 调用 `DeviceService.create()`，传入：
   - `workbenchId: 'wb-1'`
   - `name: 'Virtual Sensor'`
   - `protocolType: ProtocolType.virtual`
   - `protocolParams: {'mode': 'random', 'data_type': 'number', 'min': 0, 'max': 100, 'interval': 1000}`
2. 验证请求体和返回值

**预期结果**：
- ✅ `ApiClient.post()` 被调用，path 为 `/api/v1/devices`
- ✅ 请求体包含：`workbench_id`, `name`, `protocol_type: 'virtual'`, `protocol_params`
- ✅ 返回创建的 `Device` 对象
- ✅ 返回设备的 protocolParams 与传入一致

**失败判定**：
- ❌ protocolParams 序列化错误
- ❌ 返回设备缺少 id

---

### TC-DS-007: 创建设备 — Modbus TCP 协议成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 创建 |
| **关联验收标准** | Modbus TCP 设备可创建 |

**前置条件**：
- Mock ApiClient.post() 返回新设备 JSON

**测试步骤**：
1. 调用 `DeviceService.create()`，传入：
   - `workbenchId: 'wb-1'`
   - `name: 'Modbus TCP Device'`
   - `protocolType: ProtocolType.modbusTcp`
   - `protocolParams: {'host': '192.168.1.100', 'port': 502, 'slave_id': 1, 'timeout': 3000}`

**预期结果**：
- ✅ 请求体 `protocol_type` 为 `'modbus_tcp'`
- ✅ `protocol_params` 包含 host, port, slave_id, timeout
- ✅ 返回设备正确

**失败判定**：
- ❌ modbus_tcp 序列化为错误字符串
- ❌ protocolParams 整数字段变为字符串

---

### TC-DS-008: 创建设备 — Modbus RTU 协议成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-008 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 创建 |
| **关联验收标准** | Modbus RTU 设备可创建 |

**前置条件**：
- Mock ApiClient.post() 返回新设备 JSON

**测试步骤**：
1. 调用 `DeviceService.create()`，传入：
   - `workbenchId: 'wb-1'`
   - `name: 'Modbus RTU Device'`
   - `protocolType: ProtocolType.modbusRtu`
   - `protocolParams: {'serial_port': '/dev/ttyUSB0', 'baud_rate': 9600, 'data_bits': 8, 'stop_bits': 1, 'parity': 'none', 'slave_id': 1, 'timeout': 3000}`

**预期结果**：
- ✅ 请求体 `protocol_type` 为 `'modbus_rtu'`
- ✅ `protocol_params` 包含 serial_port, baud_rate, data_bits 等
- ✅ 返回设备正确

**失败判定**：
- ❌ modbus_rtu 序列化为错误字符串
- ❌ baud_rate 等整数字段序列化错误

---

### TC-DS-009: 创建设备 — 包含子设备（parentId）

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-009 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceService / 创建 |
| **关联验收标准** | 支持父子设备层级 |

**前置条件**：
- Mock ApiClient.post() 返回新设备 JSON（含 parentId）

**测试步骤**：
1. 调用 `DeviceService.create()` 创建子设备：
   - `workbenchId: 'wb-1'`
   - `parentId: 'dev-root'`
   - `name: 'Child Sensor'`
   - `protocolType: ProtocolType.virtual`
   - `protocolParams: {'mode': 'fixed', 'data_type': 'number', 'min': 0, 'max': 50, 'interval': 500}`

**预期结果**：
- ✅ 请求体包含 `parent_id: 'dev-root'`
- ✅ 返回设备 `parentId` 为 `'dev-root'`

**失败判定**：
- ❌ parentId 未包含在请求体中
- ❌ 子设备创建但 parentId 丢失

---

### TC-DS-010: 更新设备 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-010 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 更新 |
| **关联验收标准** | 设备信息可编辑 |

**前置条件**：
- Mock ApiClient.put() 返回更新后设备 JSON

**测试步骤**：
1. 调用 `DeviceService.update('dev-1', {'name': 'Updated Sensor', 'protocol_params': {'mode': 'sine'}})`

**预期结果**：
- ✅ `ApiClient.put()` 被调用，path 为 `/api/v1/devices/dev-1`
- ✅ 请求体包含 `name` 和 `protocol_params`
- ✅ 返回更新后 `Device`，name 为 `'Updated Sensor'`
- ✅ 支持部分更新（只传递变更字段）

**失败判定**：
- ❌ 请求体包含不必要的字段
- ❌ 返回设备未反映更新

---

### TC-DS-011: 更新设备 — 设备不存在（404）

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-011 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceService / 错误处理 |
| **关联验收标准** | 404 错误正确传播 |

**前置条件**：
- Mock ApiClient.put() 抛出 `DioException`（404）

**测试步骤**：
1. 调用 `DeviceService.update('non-existent', {'name': 'X'})`

**预期结果**：
- ✅ 抛出 `DioException`，statusCode 为 404

**失败判定**：
- ❌ Service 层吞掉异常

---

### TC-DS-012: 删除设备 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-012 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 删除 |
| **关联验收标准** | 设备可删除 |

**前置条件**：
- Mock ApiClient.delete() 正常返回

**测试步骤**：
1. 调用 `DeviceService.delete('dev-1')`

**预期结果**：
- ✅ `ApiClient.delete()` 被调用，path 为 `/api/v1/devices/dev-1`
- ✅ 正常返回 void（不抛异常）

**失败判定**：
- ❌ 成功删除后抛异常
- ❌ API path 错误

---

### TC-DS-013: 测试连接 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-013 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 连接管理 |
| **关联验收标准** | 测试连接返回正确状态 |

**前置条件**：
- Mock ApiClient 返回连接测试成功 JSON

**测试步骤**：
1. 调用 `DeviceService.testConnection('dev-1')`

**预期结果**：
- ✅ `ApiClient.post()` 被调用，path 为 `/api/v1/devices/dev-1/test-connection`
- ✅ 返回连接测试结果（如 `{'success': true, 'latency_ms': 15}`）
- ✅ 结果包含成功标志和延迟信息

**失败判定**：
- ❌ 不返回测试结果
- ❌ API path 错误

---

### TC-DS-014: 测试连接 — 失败

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-014 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 连接管理 |
| **关联验收标准** | 连接失败显示具体原因 |

**前置条件**：
- Mock ApiClient 返回连接失败 JSON 或抛出异常

**测试步骤**：
1. 模拟连接超时场景
2. 调用 `DeviceService.testConnection('dev-1')`

**预期结果**：
- ✅ 返回失败结果（如 `{'success': false, 'error': 'Connection timeout'}`）
- ✅ 或抛出 `DioException`（由 Provider 层映射）
- ✅ 错误信息包含具体原因（超时/拒绝/无响应）

**失败判定**：
- ❌ 失败时返回成功标志
- ❌ 错误信息为空

---

### TC-DS-015: 连接设备 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-015 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 连接管理 |
| **关联验收标准** | 连接/断开状态变更 |

**前置条件**：
- Mock ApiClient.post() 正常返回

**测试步骤**：
1. 调用 `DeviceService.connect('dev-1')`

**预期结果**：
- ✅ `ApiClient.post()` 被调用，path 为 `/api/v1/devices/dev-1/connect`
- ✅ 正常返回 void

**失败判定**：
- ❌ API path 错误
- ❌ 连接请求体包含多余数据

---

### TC-DS-016: 断开设备 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-016 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceService / 连接管理 |
| **关联验收标准** | 断开功能正常 |

**前置条件**：
- Mock ApiClient.post() 正常返回

**测试步骤**：
1. 调用 `DeviceService.disconnect('dev-1')`

**预期结果**：
- ✅ `ApiClient.post()` 被调用，path 为 `/api/v1/devices/dev-1/disconnect`
- ✅ 正常返回 void

**失败判定**：
- ❌ API path 错误

---

### TC-DS-017: 获取设备状态 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DS-017 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceService / 状态查询 |
| **关联验收标准** | 设备状态可查询 |

**前置条件**：
- Mock ApiClient 返回设备状态 JSON（如 `{'status': 'online'}`）

**测试步骤**：
1. 调用 `DeviceService.getStatus('dev-1')`

**预期结果**：
- ✅ `ApiClient.get()` 被调用，path 为 `/api/v1/devices/dev-1/status`
- ✅ 返回状态字符串（如 `'online'`, `'offline'`, `'error'`）

**失败判定**：
- ❌ 状态解析错误
- ❌ API path 错误

---

## 二、DeviceProvider 测试用例（11 项）

### TC-DP-001: DeviceTreeNotifier.build — 加载设备树（平铺 → 树结构）

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceTreeNotifier |
| **关联验收标准** | 设备树构建正确（平铺列表 → 树结构） |

**前置条件**：
- Mock DeviceService.listByWorkbench 返回 5 个设备：
  - dev-root (parentId: null)
  - dev-child1 (parentId: dev-root)
  - dev-child2 (parentId: dev-root)
  - dev-grandchild (parentId: dev-child1)
  - dev-solo (parentId: null)

**测试步骤**：
1. 创建 ProviderContainer，注入 mock DeviceService
2. 读取 `deviceTreeProvider('wb-1')` 状态
3. 等待 build 完成
4. 验证返回的树结构

**预期结果**：
- ✅ 状态为 `AsyncData<List<DeviceTreeNode>>`
- ✅ 返回 2 个根节点：dev-root, dev-solo
- ✅ dev-root.children 包含 2 个子节点
- ✅ dev-child1.children 包含 1 个孙节点
- ✅ 树结构正确反映 parentId 关系
- ✅ 每个 DeviceTreeNode 的 children 字段正确填充

**失败判定**：
- ❌ 返回平铺列表而非树结构
- ❌ 树结构层级错误
- ❌ 子节点的 parentId 与父节点 id 不匹配

---

### TC-DP-002: DeviceTreeNotifier — 空工作台

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceProvider / DeviceTreeNotifier |
| **关联验收标准** | 空数据正确处理 |

**前置条件**：
- Mock DeviceService.listByWorkbench 返回空列表 `[]`

**测试步骤**：
1. 创建 ProviderContainer
2. 读取 `deviceTreeProvider('wb-empty')` 状态

**预期结果**：
- ✅ 状态为 `AsyncData<List<DeviceTreeNode>>`
- ✅ 返回空列表 `[]`
- ✅ 不抛出异常

**失败判定**：
- ❌ 空数据时状态为 error
- ❌ 返回 null

---

### TC-DP-003: DeviceTreeNotifier — 网络错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceTreeNotifier |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- Mock DeviceService.listByWorkbench 抛出 `DioException`（connectionError）

**测试步骤**：
1. 创建 ProviderContainer
2. 读取 `deviceTreeProvider('wb-1')` 状态

**预期结果**：
- ✅ 状态为 `AsyncError`
- ✅ 错误信息为用户可读消息（如"网络连接失败，请检查网络后重试"）
- ✅ 不暴露技术细节（DioException stack trace）

**失败判定**：
- ❌ 错误信息为技术细节
- ❌ 状态停留在 loading

---

### TC-DP-004: DeviceTreeNotifier.refresh — 刷新设备树

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-004 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceProvider / DeviceTreeNotifier |
| **关联验收标准** | 刷新后重新加载数据 |

**前置条件**：
- DeviceTreeNotifier 已 build 成功（3 个设备）
- Mock 更新为下次调用返回 5 个设备

**测试步骤**：
1. 读取初始状态（3 个设备）
2. 调用 `ref.read(deviceTreeProvider('wb-1').notifier).refresh()`
3. 验证状态变化

**预期结果**：
- ✅ refresh 期间状态为 `AsyncLoading`
- ✅ refresh 完成后状态为 `AsyncData`，包含 5 个设备
- ✅ DeviceService.listByWorkbench 被再次调用
- ✅ 树结构根据新数据重新构建

**失败判定**：
- ❌ refresh 后数据未更新
- ❌ 旧数据仍保留

---

### TC-DP-005: DeviceDetailNotifier.build — 加载单设备详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceDetailNotifier |
| **关联验收标准** | 设备详情正确加载 |

**前置条件**：
- Mock DeviceService.getById('dev-1') 返回有效 Device

**测试步骤**：
1. 创建 ProviderContainer
2. 读取 `deviceDetailProvider('dev-1')` 状态

**预期结果**：
- ✅ 状态为 `AsyncData<Device>`
- ✅ device.id 为 `'dev-1'`
- ✅ 所有字段正确（name, protocolType, protocolParams, status）

**失败判定**：
- ❌ Device 解析错误
- ❌ 状态为 error

---

### TC-DP-006: DeviceDetailNotifier — 设备不存在

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceDetailNotifier |
| **关联验收标准** | 404 错误处理 |

**前置条件**：
- Mock DeviceService.getById('non-existent') 抛出 404 DioException

**测试步骤**：
1. 读取 `deviceDetailProvider('non-existent')` 状态

**预期结果**：
- ✅ 状态为 `AsyncError`
- ✅ 错误消息可读（如"请求的资源不存在"）
- ✅ 错误消息中包含 404 语义

**失败判定**：
- ❌ 错误消息为技术细节
- ❌ 404 消息与其他错误无法区分

---

### TC-DP-007: DeviceDetailNotifier.createDevice — 创建后刷新树

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceDetailNotifier |
| **关联验收标准** | 创建后自动刷新设备树 |

**前置条件**：
- Mock DeviceService.create() 成功
- DeviceTreeNotifier 已加载

**测试步骤**：
1. 调用 `deviceDetailNotifier.createDevice(wbId: 'wb-1', name: 'New Device', protocolType: ProtocolType.virtual, protocolParams: {...})`
2. 验证创建调用
3. 验证设备树自动刷新

**预期结果**：
- ✅ `DeviceService.create()` 被调用
- ✅ 创建成功后自动触发 `deviceTreeProvider('wb-1')` 刷新
- ✅ 创建成功后状态表示操作完成
- ✅ 新设备出现在设备树中

**失败判定**：
- ❌ 创建成功但设备树未刷新
- ❌ 创建请求参数错误

---

### TC-DP-008: DeviceDetailNotifier.createDevice — 创建失败

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-008 |
| **优先级** | **P1 — HIGH** |
| **类别** | DeviceProvider / DeviceDetailNotifier |
| **关联验收标准** | 创建失败有明确反馈 |

**前置条件**：
- Mock DeviceService.create() 抛出异常（409 名称冲突）

**测试步骤**：
1. 调用 createDevice
2. 验证错误状态

**预期结果**：
- ✅ 状态转为 `AsyncError`
- ✅ 错误消息可读（如"资源冲突"）
- ✅ 设备树保持原有数据不变

**失败判定**：
- ❌ 创建失败但状态未反映
- ❌ 错误消息不可读

---

### TC-DP-009: DeviceDetailNotifier.updateDevice — 更新成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceDetailNotifier |
| **关联验收标准** | 设备信息可编辑 |

**前置条件**：
- DeviceDetailNotifier 已加载设备 'dev-1'
- Mock DeviceService.update() 返回更新后 Device

**测试步骤**：
1. 调用 `deviceDetailNotifier.updateDevice({'name': 'Updated Name'})`
2. 验证状态

**预期结果**：
- ✅ `DeviceService.update('dev-1', {'name': 'Updated Name'})` 被调用
- ✅ 状态更新为 `AsyncData`，name 为 `'Updated Name'`
- ✅ 更新后设备树同步更新（如适用）

**失败判定**：
- ❌ 更新后状态仍为旧数据
- ❌ 部分更新时覆盖了未传递的字段

---

### TC-DP-010: DeviceDetailNotifier.deleteDevice — 删除成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-010 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / DeviceDetailNotifier |
| **关联验收标准** | 删除后列表移除 |

**前置条件**：
- DeviceDetailNotifier 已加载设备 'dev-1'
- Mock DeviceService.delete() 成功

**测试步骤**：
1. 调用 `deviceDetailNotifier.deleteDevice()`
2. 验证状态

**预期结果**：
- ✅ `DeviceService.delete('dev-1')` 被调用
- ✅ 删除成功后状态为 `AsyncLoading`（UI 层导航回列表）
- ✅ 设备树自动刷新，移除该设备

**失败判定**：
- ❌ 删除成功但设备树仍有该设备
- ❌ 删除后状态错误

---

### TC-DP-011: DeviceDetailNotifier — testConnection / connect / disconnect 状态流转

| 属性 | 内容 |
|------|------|
| **ID** | TC-DP-011 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | DeviceProvider / 连接管理 |
| **关联验收标准** | 连接/断开/测试连接状态正确 |

**前置条件**：
- DeviceDetailNotifier 已加载设备
- Mock 各连接 API 均成功

**测试步骤**：
1. 调用 `testConnection()` → 验证 loading → 验证成功结果
2. 调用 `connect()` → 验证 loading → 状态变为"在线"
3. 调用 `disconnect()` → 验证 loading → 状态变为"离线"
4. 调用 `testConnection()` 失败（mock 超时）

**预期结果**：
- ✅ testConnection 期间状态反映 loading（按钮禁用）
- ✅ testConnection 成功后显示结果 Toast
- ✅ connect 成功后设备 status 更新为 `'online'`
- ✅ disconnect 成功后设备 status 更新为 `'offline'`
- ✅ testConnection 失败时显示具体错误原因
- ✅ 各操作互斥（连接中不可测试连接等）

**失败判定**：
- ❌ 操作无 loading 反馈
- ❌ 状态变更不反映到 UI 状态
- ❌ 操作未互斥

---

## 三、PointService 测试用例（9 项）

### TC-PS-001: 列出设备下所有测点 — 正常数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 列表查询 |
| **关联验收标准** | 测点列表正确加载 |

**前置条件**：
- Mock ApiClient 返回 3 个测点的 JSON 列表

**测试步骤**：
1. 调用 `PointService.listByDevice('dev-1')`
2. 验证 API 调用和返回值

**预期结果**：
- ✅ `ApiClient.get()` 被调用，path 为 `/api/v1/points`
- ✅ queryParameters 包含 `device_id: 'dev-1'`
- ✅ 返回 `List<Point>`，长度为 3
- ✅ 每个 Point 字段正确解析（id, name, dataType, accessType, unit 等）

**失败判定**：
- ❌ 未传递 device_id 查询参数
- ❌ 返回数据解析失败

---

### TC-PS-002: 列出测点 — 空设备

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointService / 边界情况 |
| **关联验收标准** | 空数据正确处理 |

**前置条件**：
- Mock ApiClient 返回空列表 `[]`

**测试步骤**：
1. 调用 `PointService.listByDevice('dev-empty')`

**预期结果**：
- ✅ 返回空列表 `[]`
- ✅ 不抛出异常

**失败判定**：
- ❌ 空数据时抛异常
- ❌ 返回 null

---

### TC-PS-003: 列出测点 — 网络错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-003 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointService / 错误处理 |
| **关联验收标准** | 网络错误正确传播 |

**前置条件**：
- Mock ApiClient.get() 抛出 `DioException`（connectionError）

**测试步骤**：
1. 调用 `PointService.listByDevice('dev-1')`

**预期结果**：
- ✅ 抛出 `DioException`
- ✅ Service 层不吞异常

**失败判定**：
- ❌ Service 层捕获并吞掉异常

---

### TC-PS-004: 获取测点详情 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-004 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 详情查询 |
| **关联验收标准** | 测点详情正确加载 |

**前置条件**：
- Mock ApiClient 返回单测点 JSON

**测试步骤**：
1. 调用 `PointService.getById('pt-1')`

**预期结果**：
- ✅ `ApiClient.get()` 被调用，path 为 `/api/v1/points/pt-1`
- ✅ 返回 `Point` 对象，id 为 `'pt-1'`
- ✅ 所有字段正确解析（dataType → DataType 枚举，accessType → AccessType 枚举）

**失败判定**：
- ❌ DataType/AccessType 枚举映射错误
- ❌ Point 解析失败

---

### TC-PS-005: 创建测点 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 创建 |
| **关联验收标准** | 测点可创建 |

**前置条件**：
- Mock ApiClient.post() 返回新测点 JSON

**测试步骤**：
1. 调用 `PointService.create()`，传入：
   - `deviceId: 'dev-1'`
   - `name: 'Temperature'`
   - `dataType: DataType.number`
   - `accessType: AccessType.ro`
   - `unit: '°C'`
   - `minValue: -50.0, maxValue: 150.0`

**预期结果**：
- ✅ `ApiClient.post()` 被调用，path 为 `/api/v1/points`
- ✅ 请求体包含：`device_id`, `name`, `data_type: 'number'`, `access_type: 'ro'`, `unit`, `min_value`, `max_value`
- ✅ 返回创建的 `Point` 对象
- ✅ 可选字段（unit, minValue, maxValue）正确序列化

**失败判定**：
- ❌ dataType/accessType 枚举序列化错误
- ❌ minValue/maxValue 类型错误（integer vs double）
- ❌ 返回 Point 缺少 id

---

### TC-PS-006: 创建测点 — 含 defaultValue

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-006 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointService / 创建 |
| **关联验收标准** | defaultValue 字段正确 |

**前置条件**：
- Mock ApiClient.post() 返回新测点 JSON

**测试步骤**：
1. 创建测点时传入 `defaultValue: '25.0'`

**预期结果**：
- ✅ 请求体包含 `default_value: '25.0'`
- ✅ 返回值包含 `defaultValue: '25.0'`

**失败判定**：
- ❌ defaultValue 丢失或序列化错误

---

### TC-PS-007: 更新测点 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 更新 |
| **关联验收标准** | 测点可编辑 |

**前置条件**：
- Mock ApiClient.put() 返回更新后测点 JSON

**测试步骤**：
1. 调用 `PointService.update('pt-1', {'name': 'Updated Temp', 'unit': 'K'})`

**预期结果**：
- ✅ `ApiClient.put()` 被调用，path 为 `/api/v1/points/pt-1`
- ✅ 请求体包含 `name` 和 `unit`
- ✅ 返回更新后 `Point`
- ✅ 支持部分更新

**失败判定**：
- ❌ 返回 Point 未反映更新

---

### TC-PS-008: 删除测点 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-008 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 删除 |
| **关联验收标准** | 测点可删除 |

**前置条件**：
- Mock ApiClient.delete() 正常返回

**测试步骤**：
1. 调用 `PointService.delete('pt-1')`

**预期结果**：
- ✅ `ApiClient.delete()` 被调用，path 为 `/api/v1/points/pt-1`
- ✅ 正常返回 void

**失败判定**：
- ❌ 成功删除后抛异常
- ❌ API path 错误

---

### TC-PS-009: 读取测点值 — 成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 值读写 |
| **关联验收标准** | 测点值可读取 |

**前置条件**：
- Mock ApiClient 返回 PointValue JSON：`{'point_id': 'pt-1', 'value': 25.3, 'timestamp': '2026-05-31T10:00:00Z'}`

**测试步骤**：
1. 调用 `PointService.getValue('pt-1')`

**预期结果**：
- ✅ `ApiClient.get()` 被调用，path 为 `/api/v1/points/pt-1/value`
- ✅ 返回 `PointValue` 对象
- ✅ `pointId` 为 `'pt-1'`
- ✅ `value` 为 `25.3`
- ✅ `timestamp` 正确解析

**失败判定**：
- ❌ PointValue 解析错误
- ❌ API path 错误
- ❌ value 未解析

---

### TC-PS-010: 写入测点值 — 成功（RW 测点）

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-010 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointService / 值读写 |
| **关联验收标准** | 测点值可写入 |

**前置条件**：
- Mock ApiClient.put() 正常返回
- 测点 accessType 为 `rw`

**测试步骤**：
1. 调用 `PointService.setValue('pt-rw', 100.5)`

**预期结果**：
- ✅ `ApiClient.put()` 被调用，path 为 `/api/v1/points/pt-rw/value`
- ✅ 请求体包含 `value: 100.5`
- ✅ 正常返回 void

**失败判定**：
- ❌ value 序列化错误（字符串 vs 数字）
- ❌ API path 错误

---

### TC-PS-011: 写入测点值 — 只读测点返回错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-PS-011 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointService / 错误处理 |
| **关联验收标准** | 只读测点写入被拒绝 |

**前置条件**：
- Mock ApiClient.put() 抛出 `DioException`（403 Forbidden）
- 测点 accessType 为 `ro`

**测试步骤**：
1. 调用 `PointService.setValue('pt-ro', 50.0)`

**预期结果**：
- ✅ 抛出 `DioException`，statusCode 为 403
- ✅ Provider 层可映射为"只读测点不可写入"

**失败判定**：
- ❌ Service 层吞掉异常
- ❌ 403 被错误映射

---

## 四、PointProvider 测试用例（8 项）

### TC-PP-001: PointListNotifier.build — 加载测点列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 测点列表正确加载 |

**前置条件**：
- Mock PointService.listByDevice('dev-1') 返回 3 个 Point

**测试步骤**：
1. 创建 ProviderContainer，注入 mock PointService
2. 读取 `pointListProvider('dev-1')` 状态

**预期结果**：
- ✅ 状态为 `AsyncData<List<Point>>`
- ✅ 列表长度为 3
- ✅ 每个 Point 字段正确
- ✅ PointService.listByDevice('dev-1') 被调用一次

**失败判定**：
- ❌ 状态为 error
- ❌ 列表解析错误

---

### TC-PP-002: PointListNotifier — 空设备

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 空数据正确处理 |

**前置条件**：
- Mock PointService.listByDevice('dev-empty') 返回空列表

**测试步骤**：
1. 读取 `pointListProvider('dev-empty')` 状态

**预期结果**：
- ✅ 状态为 `AsyncData<List<Point>>`
- ✅ 返回空列表 `[]`

**失败判定**：
- ❌ 空数据时状态为 error

---

### TC-PP-003: PointListNotifier — 网络错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-003 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- Mock PointService.listByDevice 抛出 `DioException`

**测试步骤**：
1. 读取 `pointListProvider('dev-1')` 状态

**预期结果**：
- ✅ 状态为 `AsyncError`
- ✅ 错误消息为用户可读消息
- ✅ 包含 403/404/500 等状态码的语义化映射

**失败判定**：
- ❌ 错误消息为技术细节
- ❌ 状态停留在 loading

---

### TC-PP-004: PointListNotifier.refresh — 刷新测点列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-004 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 刷新后重新加载数据 |

**前置条件**：
- PointListNotifier 已 build 成功（3 个测点）
- Mock 更新为下次返回 5 个测点

**测试步骤**：
1. 读取初始状态
2. 调用 `ref.read(pointListProvider('dev-1').notifier).refresh()`

**预期结果**：
- ✅ refresh 期间状态为 `AsyncLoading`
- ✅ refresh 完成后状态为 `AsyncData`，包含 5 个测点
- ✅ PointService.listByDevice 被再次调用

**失败判定**：
- ❌ refresh 后数据未更新

---

### TC-PP-005: PointListNotifier.createPoint — 创建成功并刷新

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 创建后列表刷新 |

**前置条件**：
- Mock PointService.create() 成功
- PointListNotifier 已加载 3 个测点

**测试步骤**：
1. 调用 `pointListNotifier.createPoint(deviceId: 'dev-1', name: 'Pressure', dataType: DataType.number, accessType: AccessType.rw, unit: 'MPa')`
2. 验证状态

**预期结果**：
- ✅ `PointService.create()` 被调用，参数正确
- ✅ 创建成功后自动 refresh 列表
- ✅ 新测点出现在列表中
- ✅ 状态从 loading → data

**失败判定**：
- ❌ 创建成功但列表未刷新
- ❌ 创建参数错误

---

### TC-PP-006: PointListNotifier.createPoint — 创建失败

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-006 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 创建失败有反馈 |

**前置条件**：
- Mock PointService.create() 抛出异常（422 验证失败）

**测试步骤**：
1. 调用 createPoint
2. 验证状态

**预期结果**：
- ✅ 状态转为 `AsyncError`
- ✅ 错误消息映射为用户可读（如"数据验证失败，请检查输入"）
- ✅ 原有列表数据不变

**失败判定**：
- ❌ 创建失败但列表数据丢失
- ❌ 错误消息不可读

---

### TC-PP-007: PointListNotifier.deletePoint — 删除成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointProvider / PointListNotifier |
| **关联验收标准** | 删除后列表更新 |

**前置条件**：
- Mock PointService.delete('pt-1') 成功
- PointListNotifier 已加载 3 个测点

**测试步骤**：
1. 调用 `pointListNotifier.deletePoint('pt-1')`

**预期结果**：
- ✅ `PointService.delete('pt-1')` 被调用
- ✅ 删除成功后列表自动刷新
- ✅ 列表从 3 个变为 2 个
- ✅ 被删除测点不再出现

**失败判定**：
- ❌ 删除成功但列表仍有该测点
- ❌ 删除后列表未刷新

---

### TC-PP-008: PointListNotifier — 批量读取测点值

| 属性 | 内容 |
|------|------|
| **ID** | TC-PP-008 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointProvider / 值管理 |
| **关联验收标准** | 批量读取测点当前值 |

**前置条件**：
- PointListNotifier 已加载 3 个测点
- Mock PointService.getValue() 对每个测点返回不同值

**测试步骤**：
1. 调用 `pointListNotifier.refreshValues()`
2. 验证每个测点的值被读取

**预期结果**：
- ✅ 对每个测点调用 `PointService.getValue(pointId)`
- ✅ 值以 Map 形式存储（pointId → PointValue）
- ✅ 状态中可获取每个测点的当前值
- ✅ 读取过程中不阻塞列表渲染

**失败判定**：
- ❌ 单个测点值读取失败导致全部中断
- ❌ 值未正确关联到对应测点

---

## 五、Service 设计合规性测试（3 项）

### TC-ARCH-001: DeviceService 遵循 ApiClient 模式

| 属性 | 内容 |
|------|------|
| **ID** | TC-ARCH-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 架构合规 |
| **关联验收标准** | DeviceService 与 WorkbenchService 架构一致 |

**前置条件**：
- DeviceService 源码可审查

**测试步骤**：
1. 审查 DeviceService 类结构

**预期结果**：
- ✅ 构造函数接收 `ApiClient` 参数
- ✅ 所有方法通过 `_client.get/post/put/delete` 调用 API
- ✅ 返回类型使用具体模型（Device, List<Device>）
- ✅ 不直接创建 Dio 实例
- ✅ 异常不捕获（由 ErrorInterceptor 和 Provider 处理）
- ✅ 方法签名清晰，参数类型明确

**失败判定**：
- ❌ 直接使用 Dio 绕过 ApiClient
- ❌ Service 层捕获并吞掉异常
- ❌ 返回类型使用 `dynamic` 或 `Map`

---

### TC-ARCH-002: PointService 遵循 ApiClient 模式

| 属性 | 内容 |
|------|------|
| **ID** | TC-ARCH-002 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 架构合规 |
| **关联验收标准** | PointService 与 WorkbenchService 架构一致 |

**前置条件**：
- PointService 源码可审查

**测试步骤**：
1. 审查 PointService 类结构

**预期结果**：
- ✅ 构造函数接收 `ApiClient` 参数
- ✅ 所有方法通过 `_client.get/post/put/delete` 调用 API
- ✅ 使用 `data_type` / `access_type` 等 JSON key 映射
- ✅ getValue 返回 `PointValue`，setValue 返回 `void`
- ✅ 异常不捕获

**失败判定**：
- ❌ 直接使用 Dio 绕过 ApiClient
- ❌ 方法名与 API 不一致
- ❌ JSON 序列化手动拼接

---

### TC-ARCH-003: Provider 遵循 Riverpod 3.x AsyncNotifier 模式

| 属性 | 内容 |
|------|------|
| **ID** | TC-ARCH-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 架构合规 |
| **关联验收标准** | Provider 与 WorkbenchListNotifier 模式一致 |

**前置条件**：
- DeviceTreeNotifier / DeviceDetailNotifier / PointListNotifier 源码可审查

**测试步骤**：
1. 审查 DeviceTreeNotifier
2. 审查 DeviceDetailNotifier
3. 审查 PointListNotifier

**预期结果**：
- ✅ DeviceTreeNotifier 继承 `AsyncNotifier<List<DeviceTreeNode>>`
- ✅ DeviceDetailNotifier 继承 `AsyncNotifier<Device>`，使用 family 模式
- ✅ PointListNotifier 继承 `AsyncNotifier<List<Point>>`，使用 family 模式
- ✅ build() 方法定义初始加载逻辑
- ✅ 使用 `ref.read(serviceProvider)` 获取 Service
- ✅ 状态通过 `AsyncValue.guard()` 或 try/catch 管理
- ✅ 错误映射为用户可读消息（复用 _mapError 模式）
- ✅ Provider 声明使用 `AsyncNotifierProvider` 或 `.family`

**失败判定**：
- ❌ 使用旧版 StateNotifier
- ❌ 业务逻辑与 UI 混合
- ❌ 错误消息未映射

---

## 六、Provider 服务注册测试（2 项）

### TC-REG-001: DeviceService 和 PointService 注册到 providers/services.dart

| 属性 | 内容 |
|------|------|
| **ID** | TC-REG-001 |
| **优先级** | **P1 — HIGH** |
| **类别** | 服务注册 |
| **关联验收标准** | Service Provider 正确注册 |

**前置条件**：
- `lib/providers/services.dart` 包含新注册

**测试步骤**：
1. 审查 `services.dart` 
2. 验证 deviceServiceProvider 定义
3. 验证 pointServiceProvider 定义

**预期结果**：
- ✅ `deviceServiceProvider` 使用 `Provider<DeviceService>`
- ✅ `pointServiceProvider` 使用 `Provider<PointService>`
- ✅ 依赖 `apiClientProvider`
- ✅ 可通过 `ref.read(deviceServiceProvider)` 获取实例

**失败判定**：
- ❌ Service Provider 未注册
- ❌ 使用错误的 Provider 类型

---

### TC-REG-002: DeviceProvider 和 PointProvider 可被其他 Provider 引用

| 属性 | 内容 |
|------|------|
| **ID** | TC-REG-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | Provider 互联 |
| **关联验收标准** | Provider 可互操作 |

**前置条件**：
- 所有 Provider 已注册

**测试步骤**：
1. 在 test ProviderContainer 中：
   - 读取 `deviceTreeProvider('wb-1')`
   - 读取 `deviceDetailProvider('dev-1')`
   - 读取 `pointListProvider('dev-1')`
2. 验证 Provider 可互相访问

**预期结果**：
- ✅ 各 Provider 在同一个 Container 中可正常访问
- ✅ deviceDetailNotifier 创建后可触发 deviceTreeNotifier 刷新
- ✅ pointListNotifier 刷新后 deviceDetailNotifier 不受影响
- ✅ 无循环依赖

**失败判定**：
- ❌ Provider 间存在循环依赖
- ❌ 跨 Provider 操作导致状态不一致

---

## 七、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| DeviceService | 12 | TC-DS-001 ~ TC-DS-012（不含 TC-DS-013~017） |
| DeviceService（连接管理） | 5 | TC-DS-013 ~ TC-DS-017 |
| DeviceProvider | 11 | TC-DP-001 ~ TC-DP-011 |
| PointService | 11 | TC-PS-001 ~ TC-PS-011 |
| PointProvider | 8 | TC-PP-001 ~ TC-PP-008 |
| 架构合规 | 3 | TC-ARCH-001 ~ TC-ARCH-003 |
| Provider 注册 | 2 | TC-REG-001 ~ TC-REG-002 |
| **合计** | **52** | |

*注：依据 tasks.md 和 PRD 要求，TASK-015 覆盖 DeviceService + DeviceProvider + PointService + PointProvider，实际约 50 个用例。*

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 28 |
| P1 — HIGH | 24 |

---

## 八、可追溯性矩阵

### TASK-015 验收标准（来自 tasks.md）

| 验收标准 | 对应测试用例 |
|---------|------------|
| 三种协议配置可正确创建和序列化 | TC-DS-006, TC-DS-007, TC-DS-008 |
| 测试连接返回正确状态 | TC-DS-013, TC-DS-014, TC-DP-011 |
| 设备树构建正确（平铺列表 → 树结构） | TC-DP-001, TC-DP-004 |
| 所有 CRUD 操作正常 | TC-DS-001~012, TC-DP-005~010 |

### TASK-018 验收标准（来自 tasks.md）

| 验收标准 | 对应测试用例 |
|---------|------------|
| CRUD 全部流程走通 | TC-PS-001~008, TC-PP-001~007 |
| Modbus 测点字段正确序列化 | TC-PS-005（含 dataType/accessType 枚举序列化） |
| 实时值读取和写入 | TC-PS-009, TC-PS-010, TC-PP-008 |
| 错误状态正确 | TC-PS-003, TC-PS-011, TC-PP-003, TC-PP-006 |

### PRD §M5 设备管理

| 验收标准 | 对应测试用例 |
|---------|------------|
| 树形结构展示工作台下所有设备及其父子关系 | TC-DP-001 |
| 设备信息可编辑 | TC-DP-009, TC-DS-010 |
| 设备可删除 | TC-DP-010, TC-DS-012 |
| 根据协议类型配置设备通信参数 | TC-DS-006, TC-DS-007, TC-DS-008 |
| 测试设备连接状态 | TC-DS-013, TC-DS-014, TC-DP-011 |
| 查看设备在线/离线状态 | TC-DS-017, TC-DP-011 |

### PRD §M6 测点管理

| 验收标准 | 对应测试用例 |
|---------|------------|
| 为设备添加测点配置 | TC-PS-005, TC-PP-005 |
| 配置测点的名称、数据类型、单位、范围 | TC-PS-005, TC-PS-006 |
| 查看测点的实时数值 | TC-PS-009, TC-PP-008 |
| 编辑或删除测点配置 | TC-PS-007, TC-PS-008, TC-PP-007 |
| 批量查看同一设备下所有测点当前值 | TC-PP-008 |

---

## 九、测试执行记录模板

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-DS-001 | | | ⬜ 待执行 | 列出设备 — 正常 |
| TC-DS-002 | | | ⬜ 待执行 | 列出设备 — 空 |
| TC-DS-003 | | | ⬜ 待执行 | 列出设备 — 错误 |
| TC-DS-004 | | | ⬜ 待执行 | 设备详情 — 成功 |
| TC-DS-005 | | | ⬜ 待执行 | 设备详情 — 404 |
| TC-DS-006 | | | ⬜ 待执行 | 创建 Virtual |
| TC-DS-007 | | | ⬜ 待执行 | 创建 Modbus TCP |
| TC-DS-008 | | | ⬜ 待执行 | 创建 Modbus RTU |
| TC-DS-009 | | | ⬜ 待执行 | 创建子设备 |
| TC-DS-010 | | | ⬜ 待执行 | 更新设备 — 成功 |
| TC-DS-011 | | | ⬜ 待执行 | 更新设备 — 404 |
| TC-DS-012 | | | ⬜ 待执行 | 删除设备 |
| TC-DS-013 | | | ⬜ 待执行 | 测试连接 — 成功 |
| TC-DS-014 | | | ⬜ 待执行 | 测试连接 — 失败 |
| TC-DS-015 | | | ⬜ 待执行 | 连接设备 |
| TC-DS-016 | | | ⬜ 待执行 | 断开设备 |
| TC-DS-017 | | | ⬜ 待执行 | 设备状态 |
| TC-DP-001 | | | ⬜ 待执行 | 设备树构建 |
| TC-DP-002 | | | ⬜ 待执行 | 空设备树 |
| TC-DP-003 | | | ⬜ 待执行 | 设备树错误 |
| TC-DP-004 | | | ⬜ 待执行 | 刷新设备树 |
| TC-DP-005 | | | ⬜ 待执行 | 设备详情加载 |
| TC-DP-006 | | | ⬜ 待执行 | 设备不存在 |
| TC-DP-007 | | | ⬜ 待执行 | 创建设备刷新树 |
| TC-DP-008 | | | ⬜ 待执行 | 创建失败 |
| TC-DP-009 | | | ⬜ 待执行 | 更新设备 |
| TC-DP-010 | | | ⬜ 待执行 | 删除设备 |
| TC-DP-011 | | | ⬜ 待执行 | 连接状态流转 |
| TC-PS-001 | | | ⬜ 待执行 | 列出测点 — 正常 |
| TC-PS-002 | | | ⬜ 待执行 | 列出测点 — 空 |
| TC-PS-003 | | | ⬜ 待执行 | 列出测点 — 错误 |
| TC-PS-004 | | | ⬜ 待执行 | 测点详情 |
| TC-PS-005 | | | ⬜ 待执行 | 创建测点 |
| TC-PS-006 | | | ⬜ 待执行 | 创建测点 defaultVal |
| TC-PS-007 | | | ⬜ 待执行 | 更新测点 |
| TC-PS-008 | | | ⬜ 待执行 | 删除测点 |
| TC-PS-009 | | | ⬜ 待执行 | 读测点值 |
| TC-PS-010 | | | ⬜ 待执行 | 写测点值 |
| TC-PS-011 | | | ⬜ 待执行 | 只读测点写入错误 |
| TC-PP-001 | | | ⬜ 待执行 | 测点列表加载 |
| TC-PP-002 | | | ⬜ 待执行 | 空测点列表 |
| TC-PP-003 | | | ⬜ 待执行 | 测点列表错误 |
| TC-PP-004 | | | ⬜ 待执行 | 刷新测点列表 |
| TC-PP-005 | | | ⬜ 待执行 | 创建测点刷新 |
| TC-PP-006 | | | ⬜ 待执行 | 创建测点失败 |
| TC-PP-007 | | | ⬜ 待执行 | 删除测点刷新 |
| TC-PP-008 | | | ⬜ 待执行 | 批量读取值 |
| TC-ARCH-001 | | | ⬜ 待执行 | DeviceService 合规 |
| TC-ARCH-002 | | | ⬜ 待执行 | PointService 合规 |
| TC-ARCH-003 | | | ⬜ 待执行 | Provider 合规 |
| TC-REG-001 | | | ⬜ 待执行 | Service 注册 |
| TC-REG-002 | | | ⬜ 待执行 | Provider 互联 |

---

**文档状态**: ✅ 已完成  
**下一步**: 提交 sw-tom 审查 → TASK-015 开发完成 → sw-mike 测试执行  
**总用例数**: 52（17 DeviceService + 11 DeviceProvider + 11 PointService + 8 PointProvider + 3 架构 + 2 注册）  
**文件路径**: `log/release_3/test/TASK-015_test_cases.md`
