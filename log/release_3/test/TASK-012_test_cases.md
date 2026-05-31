# TASK-012 测试用例 — 工作台 Service + Provider

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待测试执行
> **关联任务**: TASK-012（工作台 Service + Provider）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md) §M4 工作台管理

---

## 测试范围

TASK-012 实现工作台相关的 Service 和 State 管理，包含以下验证要点：

| # | 功能点 | 测试覆盖 |
|---|--------|:------:|
| 1 | WorkbenchService.list() — 列表加载 | TC-S01 ~ TC-S05 |
| 2 | WorkbenchService.create() — 创建工作台 | TC-S06 ~ TC-S08 |
| 3 | WorkbenchService.getById() — 获取详情 | TC-S09 ~ TC-S10 |
| 4 | WorkbenchService.update() — 更新工作台 | TC-S11 ~ TC-S12 |
| 5 | WorkbenchService.delete() — 删除工作台 | TC-S13 ~ TC-S14 |
| 6 | WorkbenchListNotifier — 列表加载与刷新 | TC-P01 ~ TC-P07 |
| 7 | WorkbenchListNotifier — 搜索与分页 | TC-P08 ~ TC-P10 |
| 8 | WorkbenchListNotifier — 创建后刷新 | TC-P11 ~ TC-P12 |
| 9 | WorkbenchListNotifier — 错误处理 | TC-P13 ~ TC-P15 |
| 10 | WorkbenchDetailNotifier — 详情加载 | TC-P16 ~ TC-P19 |
| 11 | WorkbenchDetailNotifier — 更新操作 | TC-P20 ~ TC-P22 |
| 12 | WorkbenchDetailNotifier — 删除操作 | TC-P23 ~ TC-P25 |
| 13 | WorkbenchDetailNotifier — 错误处理 | TC-P26 ~ TC-P28 |

---

## 依赖组件

| 组件 | 文件 | 说明 |
|------|------|------|
| Workbench | `lib/models/workbench.dart` | 工作台数据模型 |
| CreateWorkbenchRequest | `lib/models/workbench.dart` | 创建工作台请求模型 |
| ApiClient | `lib/services/api_client.dart` | Dio HTTP 客户端 |
| PaginatedResponse | `lib/models/common.dart` | 分页响应通用模型 |
| FakeWorkbenchService | `test/helpers/fake_workbench_service.dart` | 测试用 Fake Service（待创建） |

---

## 后端 API 参考

| HTTP 方法 | 路径 | 说明 |
|-----------|------|------|
| `GET` | `/api/v1/workbenches` | 工作台列表（分页） |
| `POST` | `/api/v1/workbenches` | 创建工作台 |
| `GET` | `/api/v1/workbenches/{id}` | 工作台详情 |
| `PUT` | `/api/v1/workbenches/{id}` | 更新工作台 |
| `DELETE` | `/api/v1/workbenches/{id}` | 删除工作台 |

---

## Provider 设计（来自 tasks.md）

```dart
// 列表 Provider
final workbenchListProvider = AsyncNotifierProvider<WorkbenchListNotifier, List<Workbench>>(
  WorkbenchListNotifier.new,
);

// 详情 Provider（family，按 id）
final workbenchDetailProvider = AsyncNotifierProvider.family<WorkbenchDetailNotifier, Workbench, String>(
  WorkbenchDetailNotifier.new,
);
```

---

## 一、WorkbenchService 测试（14 项）

### 测试环境

- **Fake**: `FakeWorkbenchService` 实现 `WorkbenchService` 接口
- **MockApiClient**: 若 Service 直接依赖 ApiClient，可使用 Fake 包装层
- **测试数据**: 使用工厂方法创建标准测试 Workbench 对象

---

### 1.1 list() — 工作台列表加载

### TC-S01: list() 成功返回工作台列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-S01 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / list() |
| **关联验收标准** | CRUD 全部流程走通（mock backend） |

**前置条件**：
- FakeWorkbenchService 配置返回 3 条工作台记录

**测试步骤**：
1. 调用 `service.list()`
2. 验证返回的 `PaginatedResponse<Workbench>`

**预期结果**：
- ✅ 返回 `PaginatedResponse<Workbench>`，`items.length == 3`
- ✅ 每条记录包含 id, name, description, ownerType, ownerId, status, createdAt, updatedAt
- ✅ `pagination.total == 3`, `pagination.page == 1`
- ✅ Service 实际调用了 ApiClient.get()，路径为 `/api/v1/workbenches`

**失败判定**：
- ❌ 返回 null 或空列表（当有数据时）
- ❌ 未正确反序列化 Workbench 对象

---

### TC-S02: list() 返回空数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-S02 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / list() |
| **关联验收标准** | 空数据正确返回 |

**前置条件**：
- FakeWorkbenchService 配置返回空列表

**测试步骤**：
1. 调用 `service.list()`
2. 验证返回结果

**预期结果**：
- ✅ `items.isEmpty` 为 true
- ✅ `pagination.total == 0`
- ✅ 不抛出异常

**失败判定**：
- ❌ 空数据时抛出异常
- ❌ items 为 null 而非空列表

---

### TC-S03: list() 分页参数正确传递

| 属性 | 内容 |
|------|------|
| **ID** | TC-S03 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / list() |
| **关联验收标准** | 搜索和分页参数正确传递 |

**前置条件**：
- FakeWorkbenchService 可记录请求参数

**测试步骤**：
1. 调用 `service.list(page: 2, pageSize: 10)`
2. 验证 API 请求参数

**预期结果**：
- ✅ API 请求包含 query parameter `page=2`
- ✅ API 请求包含 query parameter `pageSize=10`（或 `page_size=10`）
- ✅ Service 正确将参数转换为 HTTP query parameters

**失败判定**：
- ❌ 分页参数未传递给 API
- ❌ 参数命名不匹配后端约定

---

### TC-S04: list() 搜索参数正确传递

| 属性 | 内容 |
|------|------|
| **ID** | TC-S04 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchService / list() |
| **关联验收标准** | 搜索和分页参数正确传递 |

**前置条件**：
- FakeWorkbenchService 可记录请求参数

**测试步骤**：
1. 调用 `service.list(search: 'test-workbench')`
2. 验证 API 请求参数

**预期结果**：
- ✅ API 请求包含 query parameter `search=test-workbench`
- ✅ 搜索参数支持中文字符，调用 `service.list(search: '测试工作台')` 时正确编码

**失败判定**：
- ❌ 搜索参数未编码或编码错误
- ❌ 搜索参数未传递给 API

---

### TC-S05: list() 网络错误时抛出异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-S05 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / list() / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置网络错误

**测试步骤**：
1. 调用 `service.list()`
2. 验证异常抛出

**预期结果**：
- ✅ 抛出 `DioException` 或自定义异常
- ✅ 异常携带用户可读的错误消息（如"网络连接失败"）
- ✅ 不返回 null（fail-fast）

**失败判定**：
- ❌ 网络错误时静默失败
- ❌ 返回 null 而不抛出异常
- ❌ 错误消息为原始技术错误

---

### 1.2 create() — 创建工作台

### TC-S06: create() 成功创建并返回 Workbench

| 属性 | 内容 |
|------|------|
| **ID** | TC-S06 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / create() |
| **关联验收标准** | CRUD 全部流程走通 |

**前置条件**：
- FakeWorkbenchService 配置创建成功

**测试步骤**：
1. 调用 `service.create(name: 'New WB', description: 'A new workbench', ownerType: 'personal', ownerId: 'user-1')`
2. 验证返回的 `Workbench` 对象

**预期结果**：
- ✅ 返回 `Workbench` 对象，name 为 `'New WB'`
- ✅ `description` 为 `'A new workbench'`
- ✅ `ownerType` 为 `'personal'`
- ✅ `ownerId` 为 `'user-1'`
- ✅ 自动生成 id（非空字符串）
- ✅ `status` 有默认值（如 `'active'`）
- ✅ `createdAt` 和 `updatedAt` 为有效 DateTime
- ✅ Service 调用 `POST /api/v1/workbenches`，请求体包含所有字段

**失败判定**：
- ❌ 返回 null 或不完整的 Workbench
- ❌ 请求体缺少必填字段

---

### TC-S07: create() 必填字段验证 — name 为空

| 属性 | 内容 |
|------|------|
| **ID** | TC-S07 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchService / create() / 输入验证 |
| **关联验收标准** | 输入验证 |

**前置条件**：
- FakeWorkbenchService 配置 400/422 错误

**测试步骤**：
1. 调用 `service.create(name: '', ownerType: 'personal', ownerId: 'user-1')`
2. 验证异常抛出

**预期结果**：
- ✅ 抛出异常，消息包含"请求参数有误"或"数据验证失败"
- ✅ 后端返回 400/422 状态码时正确映射为可读错误

**失败判定**：
- ❌ 空名称创建成功
- ❌ 无错误提示

---

### TC-S08: create() 网络错误时抛出异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-S08 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchService / create() / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置网络错误

**测试步骤**：
1. 调用 `service.create(name: 'New', ownerType: 'personal', ownerId: 'user-1')`
2. 验证异常抛出

**预期结果**：
- ✅ 抛出异常，不返回 null
- ✅ 异常消息为用户可读格式

---

### 1.3 getById() — 获取详情

### TC-S09: getById() 成功返回工作台详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-S09 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / getById() |
| **关联验收标准** | CRUD 全部流程走通 |

**前置条件**：
- FakeWorkbenchService 配置存在的工作台 id `'wb-1'`

**测试步骤**：
1. 调用 `service.getById('wb-1')`
2. 验证返回的 `Workbench` 对象

**预期结果**：
- ✅ 返回 `Workbench`，`id == 'wb-1'`
- ✅ 所有字段完整（name, description, ownerType, ownerId, status, createdAt, updatedAt）
- ✅ Service 调用 `GET /api/v1/workbenches/wb-1`

**失败判定**：
- ❌ 返回 null
- ❌ 返回的 Workbench 字段不完整

---

### TC-S10: getById() 资源不存在时抛出异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-S10 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / getById() / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置不存在的工作台 id `'nonexistent'`

**测试步骤**：
1. 调用 `service.getById('nonexistent')`
2. 验证异常抛出

**预期结果**：
- ✅ 抛出异常（404 Not Found）
- ✅ 异常消息包含"资源不存在"或类似文本
- ✅ 不返回 null（fail-fast）

**失败判定**：
- ❌ 返回 null 而不抛出异常
- ❌ 返回空的 Workbench 对象

---

### 1.4 update() — 更新工作台

### TC-S11: update() 成功更新并返回 Workbench

| 属性 | 内容 |
|------|------|
| **ID** | TC-S11 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / update() |
| **关联验收标准** | CRUD 全部流程走通 |

**前置条件**：
- FakeWorkbenchService 配置存在的工作台 id `'wb-1'`

**测试步骤**：
1. 调用 `service.update(id: 'wb-1', name: 'Updated Name', description: 'Updated description')`
2. 验证返回的 `Workbench` 对象

**预期结果**：
- ✅ 返回 `Workbench`，`name == 'Updated Name'`
- ✅ `description == 'Updated description'`
- ✅ `id` 保持不变（仍为 `'wb-1'`）
- ✅ `updatedAt` 晚于原始的 `updatedAt`
- ✅ Service 调用 `PUT /api/v1/workbenches/wb-1`，请求体包含更新的字段

**失败判定**：
- ❌ id 发生变化
- ❌ 未更新字段保持原样的字段丢失

---

### TC-S12: update() 部分更新（仅更新 name）

| 属性 | 内容 |
|------|------|
| **ID** | TC-S12 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchService / update() |
| **关联验收标准** | 更新操作灵活性 |

**前置条件**：
- FakeWorkbenchService 配置存在的工作台 id `'wb-1'`，原始 description 为 `'Old description'`

**测试步骤**：
1. 调用 `service.update(id: 'wb-1', name: 'New Name')`（不传 description）
2. 验证返回的 `Workbench` 对象

**预期结果**：
- ✅ `name == 'New Name'`
- ✅ `description` 保持原值（`'Old description'`）或为 null（取决于 API 行为）
- ✅ 请求体仅包含 name 字段（或 description 显式为 null）

**失败判定**：
- ❌ 未传的字段被错误覆盖为 null/空

---

### 1.5 delete() — 删除工作台

### TC-S13: delete() 成功删除不返回异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-S13 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchService / delete() |
| **关联验收标准** | CRUD 全部流程走通 |

**前置条件**：
- FakeWorkbenchService 配置存在的工作台 id `'wb-1'`

**测试步骤**：
1. 调用 `service.delete('wb-1')`
2. 验证无异常抛出

**预期结果**：
- ✅ 方法正常返回（void）
- ✅ 不抛出异常
- ✅ Service 调用 `DELETE /api/v1/workbenches/wb-1`

**失败判定**：
- ❌ 删除成功资源后抛出异常
- ❌ 方法返回非 void

---

### TC-S14: delete() 资源不存在时抛出异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-S14 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchService / delete() / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置不存在的工作台 id `'nonexistent'`

**测试步骤**：
1. 调用 `service.delete('nonexistent')`
2. 验证异常抛出

**预期结果**：
- ✅ 抛出 404 异常
- ✅ 异常消息包含"资源不存在"

**失败判定**：
- ❌ 删除不存在资源时静默成功

---

## 二、WorkbenchListProvider 测试（15 项）

### 测试环境

- **ProviderContainer**: 通过 `overrides` 注入 `FakeWorkbenchService`
- **FakeWorkbenchService**: 实现 `WorkbenchService` 接口，提供可控行为

---

### 2.1 列表加载与刷新

### TC-P01: build() 成功加载工作台列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-P01 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchListNotifier / build() |
| **关联验收标准** | 列表加载成功（正常数据） |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 返回 3 条记录
- ProviderContainer 已创建但尚未读取 provider

**测试步骤**：
1. 读取 `container.read(workbenchListProvider)` — 应处于 loading
2. 等待 `container.read(workbenchListProvider.future)` 完成
3. 验证最终状态

**预期结果**：
- ✅ 初始状态为 `AsyncLoading<List<Workbench>>`
- ✅ 加载完成后状态为 `AsyncData<List<Workbench>>`
- ✅ `state.value.length == 3`
- ✅ 每条记录是 `Workbench` 类型，包含 id, name
- ✅ `state.hasError == false`

**失败判定**：
- ❌ 加载完成后仍为 loading
- ❌ 列表为空（当数据存在时）
- ❌ 状态异常（hasError）

---

### TC-P02: build() 空数据时返回空列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-P02 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchListNotifier / build() |
| **关联验收标准** | 空数据正确处理 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 返回空列表

**测试步骤**：
1. 等待 `container.read(workbenchListProvider.future)` 完成
2. 验证状态

**预期结果**：
- ✅ `state` 为 `AsyncData<List<Workbench>>`
- ✅ `state.value.isEmpty` 为 true
- ✅ `state.hasError == false`
- ✅ UI 层可通过 `state.value.isEmpty` 判断空状态

**失败判定**：
- ❌ 空数据时状态为 error
- ❌ `state.value` 为 null 而非空列表

---

### TC-P03: refresh() 重新加载列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-P03 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchListNotifier / refresh() |
| **关联验收标准** | 创建/更新/删除后自动刷新列表 |

**前置条件**：
- FakeWorkbenchService 首次 `list()` 返回 1 条记录
- 手动更新 FakeWorkbenchService 使第二次 `list()` 返回 3 条记录

**测试步骤**：
1. 等待首次 load 完成（1 条记录）
2. 修改 Fake 数据为 3 条记录
3. 调用 `container.read(workbenchListProvider.notifier).refresh()`
4. 等待完成
5. 验证列表已更新

**预期结果**：
- ✅ 首次 `state.value.length == 1`
- ✅ 刷新后 `state.value.length == 3`
- ✅ 刷新期间状态短暂变为 `AsyncLoading`
- ✅ `list()` 被调用了两次

**失败判定**：
- ❌ refresh 后列表未更新
- ❌ 刷新期间无 loading 状态（UI 无法感知）

---

### TC-P04: refresh() 失败后保留原有数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-P04 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / refresh() / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 首次 `list()` 返回 2 条记录
- 后续 `list()` 调用抛出网络错误

**测试步骤**：
1. 等待首次 load 完成（2 条记录）
2. 修改 Fake 配置为网络错误
3. 调用 `refresh()`
4. 验证状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 原有数据不丢失（设计选择：①保持旧数据+error标志 或 ②清空+error）
  - 推荐：`state.value` 仍为原有 2 条记录（或通过 `AsyncValue` 保留）
- ✅ 错误消息为用户可读格式
- ✅ `list()` 被调用了两次

**失败判定**：
- ❌ 刷新失败后静默（无错误提示）
- ❌ 错误状态无用户可读消息

---

### TC-P05: 多次快速 refresh 防抖/去重

| 属性 | 内容 |
|------|------|
| **ID** | TC-P05 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | WorkbenchListNotifier / refresh() / 并发 |
| **关联验收标准** | 并发安全 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 有 100ms 延迟

**测试步骤**：
1. 等待首次 load 完成
2. 连续 3 次快速调用 `refresh()`
3. 验证 `list()` 仅被调用合理的次数

**预期结果**：
- ✅ 不会因并发导致状态混乱（如同时触发多个 refresh 时最后一个生效）
- ✅ 防并发调用（如前一次 refresh 未完成时忽略新请求）
- ✅ 最终状态为最新数据

**失败判定**：
- ❌ 并发导致数据错乱
- ❌ 状态在 data 和 error 之间反复横跳

---

### TC-P06: build() 时调用 service.list() 带默认分页参数

| 属性 | 内容 |
|------|------|
| **ID** | TC-P06 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / build() |
| **关联验收标准** | 分页参数正确传递 |

**前置条件**：
- FakeWorkbenchService 可记录 `list()` 的调用参数

**测试步骤**：
1. 等待 `container.read(workbenchListProvider.future)` 完成
2. 验证 `list()` 的调用参数

**预期结果**：
- ✅ `list()` 被调用，默认 `page: 1`
- ✅ 默认 `pageSize` 为合理值（如 20）
- ✅ `search` 参数为空字符串或 null

**失败判定**：
- ❌ 未传递分页参数
- ❌ 默认 pageSize 过大或过小（应 10-50 之间）

---

### TC-P07: loadMore() 加载下一页并追加数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-P07 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchListNotifier / 分页 |
| **关联验收标准** | 分页正常工作 |

**前置条件**：
- FakeWorkbenchService 配置 `list(page: 1)` 返回 10 条
- `list(page: 2)` 返回 5 条

**测试步骤**：
1. 等待首次 load 完成（10 条记录）
2. 调用 `container.read(workbenchListProvider.notifier).loadMore()`
3. 验证状态

**预期结果**：
- ✅ 首次加载后 `state.value.length == 10`
- ✅ `loadMore()` 后 `state.value.length == 15`
- ✅ `list(page: 2)` 被正确调用
- ✅ `loadMore()` 期间状态为 loading
- ✅ 记录按正确顺序追加（先加载的在前）

**失败判定**：
- ❌ loadMore 后列表被替换（而非追加）
- ❌ 分页参数未正确递增

---

### 2.2 搜索与分页

### TC-P08: search() 带搜索参数重新加载列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-P08 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / 搜索 |
| **关联验收标准** | 搜索实时过滤 |

**前置条件**：
- FakeWorkbenchService 首次 `list()` 返回完整 3 条
- `list(search: 'test')` 返回 1 条过滤结果

**测试步骤**：
1. 等待首次 load 完成（3 条记录）
2. 调用 `container.read(workbenchListProvider.notifier).search('test')`
3. 验证状态和调用参数

**预期结果**：
- ✅ 首次 `state.value.length == 3`
- ✅ `search('test')` 后 `state.value.length == 1`
- ✅ `list(search: 'test', page: 1)` 被调用（搜索时重置分页到第 1 页）
- ✅ 搜索期间状态为 loading

**失败判定**：
- ❌ 搜索后未重置分页
- ❌ 搜索结果追加到原列表（应替换）

---

### TC-P09: 清空搜索恢复完整列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-P09 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / 搜索 |
| **关联验收标准** | 搜索行为正确 |

**前置条件**：
- FakeWorkbenchService 配置可控搜索结果

**测试步骤**：
1. 加载完整列表
2. 执行 `search('test')` → 过滤结果
3. 执行 `search('')` → 清空搜索
4. 验证恢复完整列表

**预期结果**：
- ✅ `search('')` 重新加载不带搜索参数的完整列表
- ✅ 分页重置为第 1 页

**失败判定**：
- ❌ 清空搜索后仍然显示过滤结果
- ❌ 未重置分页

---

### TC-P10: 分页信息正确暴露

| 属性 | 内容 |
|------|------|
| **ID** | TC-P10 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | WorkbenchListNotifier / 分页 |
| **关联验收标准** | 分页正常工作 |

**前置条件**：
- FakeWorkbenchService 返回包含分页元数据

**测试步骤**：
1. 等待首次 load 完成
2. 检查 Notifier 是否暴露 `hasMore`, `totalCount`, `currentPage`

**预期结果**：
- ✅ Notifier 暴露 `hasMore` 属性（当 `pagination.total > currentPage * pageSize`）
- ✅ Notifier 暴露 `totalCount` 属性
- ✅ `hasMore == false` 时 `loadMore()` 不发送请求（或忽略）

**失败判定**：
- ❌ 无 hasMore 判断 → 可能发送无效请求
- ❌ 分页信息完全不可见

---

### 2.3 创建后刷新

### TC-P11: createWorkbench() 成功后自动刷新列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-P11 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchListNotifier / 创建后刷新 |
| **关联验收标准** | 创建成功 → 刷新列表 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 返回 2 条，`create()` 成功
- fakeService 可记录调用次数

**测试步骤**：
1. 等待首次 load 完成（2 条记录）
2. 调用 `container.read(workbenchListProvider.notifier).createWorkbench(name: 'New', description: 'Desc', ownerType: 'personal', ownerId: 'user-1')`
3. 等待完成
4. 验证列表已包含新记录

**预期结果**：
- ✅ `create()` 被调用，参数正确
- ✅ 创建后 `list()` 被重新调用（刷新）
- ✅ `state.value.length` 变为 3（2 原有 + 1 新增）
- ✅ 创建期间状态为 loading
- ✅ 创建成功后状态回到 data

**失败判定**：
- ❌ 创建后列表未刷新
- ❌ 新记录未出现在列表中

---

### TC-P12: createWorkbench() 失败时列表保持不变

| 属性 | 内容 |
|------|------|
| **ID** | TC-P12 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / 创建错误 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 返回 2 条，`create()` 抛出网络错误

**测试步骤**：
1. 等待首次 load 完成
2. 调用 `createWorkbench(name: 'New', ownerType: 'personal', ownerId: 'user-1')`
3. 验证状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 原有列表数据保留（或通过 error 状态携带原有数据引用）
- ✅ 错误消息用户可读
- ✅ `create()` 只被调用 1 次，未触发不必要的 `list()` 刷新

**失败判定**：
- ❌ 创建失败后错误地刷新列表
- ❌ 原有列表数据丢失

---

### 2.4 错误处理

### TC-P13: build() 失败时状态为 error

| 属性 | 内容 |
|------|------|
| **ID** | TC-P13 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchListNotifier / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 抛出 DioException（网络错误）

**测试步骤**：
1. 等待 `container.read(workbenchListProvider.future)` 完成（或 catch error）
2. 验证状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ `state.error` 不为 null
- ✅ 错误消息用户可读（如"网络连接失败"）
- ✅ ErrorInterceptor 的映射规则正确应用于消息

**失败判定**：
- ❌ 网络错误时状态为 data（空列表）而非 error
- ❌ 错误消息为原始异常信息

---

### TC-P14: build() 500 服务器错误时状态为 error

| 属性 | 内容 |
|------|------|
| **ID** | TC-P14 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 抛出 500 服务器错误

**测试步骤**：
1. 等待 build 完成
2. 验证错误状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 错误消息包含"服务器内部错误"或"服务暂时不可用"
- ✅ 不暴露技术细节（如 Stack Trace）

**失败判定**：
- ❌ 显示原始 DioException 字符串
- ❌ 状态为 data 而非 error

---

### TC-P15: 重试机制（retry）从 error 状态恢复

| 属性 | 内容 |
|------|------|
| **ID** | TC-P15 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchListNotifier / 错误恢复 |
| **关联验收标准** | 错误后可恢复 |

**前置条件**：
- FakeWorkbenchService 首次 `list()` 抛出错误
- 第二次 `list()` 返回正常数据（或 Notifier 提供 retry 方法）

**测试步骤**：
1. 等待首次 load 失败
2. 修复 Fake 使其返回数据
3. 调用 `retry()` 或重新触发 build
4. 验证状态恢复

**预期结果**：
- ✅ 如果 Notifier 提供 `retry()` 方法 → 调用后列表加载成功
- ✅ `state.hasError == false`
- ✅ `state.value` 为正常列表

**失败判定**：
- ❌ 无可用的恢复机制（用户只能刷新页面）
- ❌ retry 后仍显示错误

---

## 三、WorkbenchDetailProvider 测试（13 项）

### 测试环境

- **ProviderContainer**: 通过 `overrides` 注入 `FakeWorkbenchService`
- **Family Provider**: 使用 `workbenchDetailProvider('wb-1')` 获取特定工作台

---

### 3.1 详情加载

### TC-P16: build() 成功加载工作台详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-P16 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailNotifier / build() |
| **关联验收标准** | CRUD 全部流程走通 |

**前置条件**：
- FakeWorkbenchService 配置 `getById('wb-1')` 返回有效 Workbench
- ProviderContainer 已创建

**测试步骤**：
1. 读取 `container.read(workbenchDetailProvider('wb-1'))`
2. 等待 `container.read(workbenchDetailProvider('wb-1').future)` 完成
3. 验证最终状态

**预期结果**：
- ✅ 初始状态为 `AsyncLoading<Workbench>`
- ✅ 加载完成后为 `AsyncData<Workbench>`
- ✅ `state.value.id == 'wb-1'`
- ✅ `state.value.name` 为有效字符串
- ✅ `state.value.status` 为有效状态（如 `'active'`）
- ✅ Service 的 `getById('wb-1')` 被调用了 1 次

**失败判定**：
- ❌ 状态为 error
- ❌ 返回的 Workbench 字段不完整

---

### TC-P17: build() 非存在 ID 时状态为 error

| 属性 | 内容 |
|------|------|
| **ID** | TC-P17 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailNotifier / build() / 错误处理 |
| **关联验收标准** | 不存在的 id → 错误处理 |

**前置条件**：
- FakeWorkbenchService 配置 `getById('nonexistent')` 抛出 404

**测试步骤**：
1. 读取 `container.read(workbenchDetailProvider('nonexistent'))`
2. 等待完成
3. 验证状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 错误消息包含"资源不存在"或类似文本
- ✅ `state.value` 为 null（或保持上一个值）

**失败判定**：
- ❌ 返回 null 而非 error 状态
- ❌ 无错误消息

---

### TC-P18: 相同 ID 的 Provider 返回同一实例

| 属性 | 内容 |
|------|------|
| **ID** | TC-P18 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailNotifier / Provider 行为 |
| **关联验收标准** | Provider family 正确工作 |

**前置条件**：
- FakeWorkbenchService 配置 `getById('wb-1')` 返回有效 Workbench

**测试步骤**：
1. 读取 `container.read(workbenchDetailProvider('wb-1'))` 两次
2. 验证两次获取的 Provider 是同一实例

**预期结果**：
- ✅ 同一 family 参数返回同一 Provider 实例
- ✅ `getById('wb-1')` 仅被调用 1 次（缓存）

**失败判定**：
- ❌ 相同 id 每次读取都重新加载（无缓存）
- ❌ provider family 未正确实现

---

### TC-P19: 不同 ID 的 Provider 返回不同实例和数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-P19 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailNotifier / Provider 行为 |
| **关联验收标准** | Provider family 正确工作 |

**前置条件**：
- FakeWorkbenchService 配置 `getById('wb-1')` 和 `getById('wb-2')` 返回不同数据

**测试步骤**：
1. 读取 `container.read(workbenchDetailProvider('wb-1'))` 和 `container.read(workbenchDetailProvider('wb-2'))`
2. 等待两者都完成
3. 验证数据不同

**预期结果**：
- ✅ `workbenchDetailProvider('wb-1')` 返回 Workbench(id: 'wb-1')
- ✅ `workbenchDetailProvider('wb-2')` 返回 Workbench(id: 'wb-2')
- ✅ 两个 Provider 互不干扰
- ✅ `getById()` 被调用了 2 次（分别用 'wb-1' 和 'wb-2'）

**失败判定**：
- ❌ 不同 ID 返回相同数据
- ❌ 一个 Provider 的状态变化影响另一个

---

### 3.2 更新操作

### TC-P20: updateWorkbench() 成功更新并刷新详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-P20 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailNotifier / 更新 |
| **关联验收标准** | 更新成功 → 列表/详情同步更新 |

**前置条件**：
- FakeWorkbenchService 配置 `getById('wb-1')` 返回原始 Workbench(name: 'Original')
- `update('wb-1', name: 'Updated')` 返回更新后的 Workbench(name: 'Updated')

**测试步骤**：
1. 等待 workbenchDetailProvider('wb-1') 加载完成
2. 调用 `container.read(workbenchDetailProvider('wb-1').notifier).updateWorkbench(name: 'Updated')`
3. 等待完成
4. 验证详情已更新

**预期结果**：
- ✅ 初始 `state.value.name == 'Original'`
- ✅ 更新后 `state.value.name == 'Updated'`
- ✅ `update()` 被调用，参数为 `('wb-1', name: 'Updated')`
- ✅ 更新期间状态为 loading
- ✅ 更新完成状态回到 data

**失败判定**：
- ❌ 更新后详情未变化
- ❌ update 参数传递错误

---

### TC-P21: updateWorkbench() 部分字段更新

| 属性 | 内容 |
|------|------|
| **ID** | TC-P21 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailNotifier / 更新 |
| **关联验收标准** | 更新操作灵活性 |

**前置条件**：
- FakeWorkbenchService 配置原始 Workbench(name: 'Original', description: 'Old Desc')

**测试步骤**：
1. 等待详情加载完成
2. 调用 `updateWorkbench(name: 'New Name')`（仅更新 name）
3. 验证结果

**预期结果**：
- ✅ `state.value.name == 'New Name'`
- ✅ `state.value.description` 保持原值不变
- ✅ 请求体仅包含 name 字段

**失败判定**：
- ❌ 未更新的字段被重置

---

### TC-P22: updateWorkbench() 失败时不修改状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-P22 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailNotifier / 更新 / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `update()` 抛出网络错误

**测试步骤**：
1. 等待详情加载完成（当前 name: 'Original'）
2. 调用 `updateWorkbench(name: 'Updated')`
3. 验证状态

**预期结果**：
- ✅ `state.hasError == true`（或保持 loading后恢复原状）
- ✅ 原有数据保留（`state.value.name == 'Original'`）
- ✅ 错误消息用户可读

**失败判定**：
- ❌ 更新失败后详情被错误修改
- ❌ 静默失败无错误提示

---

### 3.3 删除操作

### TC-P23: deleteWorkbench() 成功删除并清理状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-P23 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailNotifier / 删除 |
| **关联验收标准** | 删除成功 → 列表移除 |

**前置条件**：
- FakeWorkbenchService 配置 `delete('wb-1')` 成功

**测试步骤**：
1. 等待详情加载完成
2. 调用 `container.read(workbenchDetailProvider('wb-1').notifier).deleteWorkbench()`
3. 验证状态

**预期结果**：
- ✅ `delete('wb-1')` 被调用
- ✅ 删除后 DetailNotifier 状态应反映删除完成
  - 方案A：返回 void / null，UI 层导航回列表
  - 方案B：状态变为 AsyncData(null) 或其他完成标志
- ✅ 删除期间状态为 loading

**失败判定**：
- ❌ 删除后仍显示已删除的工作台
- ❌ `delete()` 未被实际调用

---

### TC-P24: deleteWorkbench() 失败时保留详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-P24 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailNotifier / 删除 / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `delete('wb-1')` 抛出错误（403 Forbidden）

**测试步骤**：
1. 等待详情加载完成
2. 调用 `deleteWorkbench()`
3. 验证状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 错误消息包含"没有权限"或类似文本
- ✅ 详情数据保留（不丢失）

**失败判定**：
- ❌ 删除失败后详情页清空
- ❌ 无错误提示

---

### TC-P25: deleteWorkbench() 需二次确认（逻辑层面）

| 属性 | 内容 |
|------|------|
| **ID** | TC-P25 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | WorkbenchDetailNotifier / 设计约束 |
| **关联验收标准** | 删除有二次确认 |

**测试步骤**：
1. 验证 Notifier 的 `deleteWorkbench()` 方法不自动弹出确认对话框
2. 确认对话框由 UI 层在调用 `deleteWorkbench()` 之前弹出

**预期结果**：
- ✅ `deleteWorkbench()` 直接执行删除，不包含 UI 确认逻辑
- ✅ UI 层负责确认对话框 → 确认后调用 `deleteWorkbench()`

**说明**：
- 此为设计约束验证，确保关注点分离正确

---

### 3.4 错误处理

### TC-P26: build() 网络错误时状态为 error

| 属性 | 内容 |
|------|------|
| **ID** | TC-P26 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailNotifier / 错误处理 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `getById()` 抛出网络错误

**测试步骤**：
1. 读取 `container.read(workbenchDetailProvider('wb-1'))`
2. 等待完成
3. 验证状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 错误消息包含"网络"相关文本
- ✅ ErrorInterceptor 映射正确

**失败判定**：
- ❌ 网络错误时返回空 Workbench
- ❌ 错误消息为技术栈信息

---

### TC-P27: build() 401 未授权错误时状态为 error

| 属性 | 内容 |
|------|------|
| **ID** | TC-P27 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailNotifier / 错误处理 |
| **关联验收标准** | 认证相关错误处理 |

**前置条件**：
- FakeWorkbenchService 配置 `getById()` 抛出 401 错误

**测试步骤**：
1. 读取 provider
2. 验证错误状态

**预期结果**：
- ✅ `state.hasError == true`
- ✅ 错误消息包含"登录已过期"或"未授权"
- ✅ 上层（AuthInterceptor 或 AuthNotifier）会处理 Token 刷新

**失败判定**：
- ❌ 401 错误被静默
- ❌ 错误消息不准确

---

### TC-P28: 同一 Provider 在错误后重新读取仍为 error

| 属性 | 内容 |
|------|------|
| **ID** | TC-P28 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | WorkbenchDetailNotifier / 错误持久化 |
| **关联验收标准** | 错误状态正确传播 |

**前置条件**：
- FakeWorkbenchService 配置 `getById('wb-1')` 始终抛出错误

**测试步骤**：
1. 读取 `workbenchDetailProvider('wb-1')` → error
2. 再次读取同一个 provider → 仍为 error

**预期结果**：
- ✅ 两次读取状态一致（都为 error）
- ✅ 不会因为重新读取而重置为 loading 然后再次 error（避免闪烁）

**说明**：
- 取决于 Provider 行为：`AsyncNotifier` 默认会缓存错误，`autoDispose` 会影响生命周期

---

## 四、集成场景测试（6 项）

### TC-I01: 创建 → 列表自动刷新（跨 Provider 交互）

| 属性 | 内容 |
|------|------|
| **ID** | TC-I01 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 集成 / ListNotifier ↔ Service |
| **关联验收标准** | 创建成功 → 刷新列表 |

**前置条件**：
- WorkbenchListNotifier 和 WorkbenchService 通过 Provider 正常连接

**测试步骤**：
1. 等待 workbenchListProvider 初始加载（2 条记录）
2. 通过 `workbenchListProvider.notifier.createWorkbench(...)` 创建新工作台
3. 验证列表自动包含新记录

**预期结果**：
- ✅ 列表自动刷新（无需手动调用 refresh）
- ✅ 新记录出现在列表中

**失败判定**：
- ❌ 创建后列表未自动刷新
- ❌ 需要手动触发刷新

---

### TC-I02: 列表详情联动 — 从列表跳转详情后数据一致

| 属性 | 内容 |
|------|------|
| **ID** | TC-I02 |
| **优先级** | **P1 — HIGH** |
| **类别** | 集成 / ListNotifier ↔ DetailNotifier |
| **关联验收标准** | 列表和详情数据一致 |

**前置条件**：
- workbenchListProvider 已加载（含 Workbench(id: 'wb-1', name: 'Test')）
- workbenchDetailProvider('wb-1') 通过 Service 加载同一数据

**测试步骤**：
1. 验证列表中的 'wb-1' 数据
2. 加载 workbenchDetailProvider('wb-1')
3. 对比两者数据

**预期结果**：
- ✅ 列表中的数据和详情中的数据一致（相同 id 的数据）
- ✅ Detail 可能包含更完整的字段

**失败判定**：
- ❌ 列表和详情数据不一致

---

### TC-I03: 详情更新 → 列表应反映最新数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-I03 |
| **优先级** | **P1 — HIGH** |
| **类别** | 集成 / DetailNotifier → ListNotifier |
| **关联验收标准** | 更新成功 → 列表/详情同步更新 |

**前置条件**：
- workbenchListProvider 和 workbenchDetailProvider 同时存在

**测试步骤**：
1. 加载列表和详情
2. 通过 DetailNotifier 更新 name 为 'Updated'
3. 刷新列表
4. 验证列表中该 Workbench 的 name 也称为 'Updated'

**预期结果**：
- ✅ 列表刷新后 name 为 'Updated'
- ✅ 或 Detail 更新后自动通知 ListNotifier invalidate

**失败判定**：
- ❌ 详情更新后列表显示旧数据
- ❌ 列表和详情数据不同步

---

### TC-I04: 详情删除 → 列表移除该项

| 属性 | 内容 |
|------|------|
| **ID** | TC-I04 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 集成 / DetailNotifier → ListNotifier |
| **关联验收标准** | 删除成功 → 列表移除 |

**前置条件**：
- workbenchListProvider 已加载（含 3 条记录）
- workbenchDetailProvider('wb-1') 已加载

**测试步骤**：
1. 验证列表含 'wb-1'
2. 通过 DetailNotifier 删除 'wb-1'
3. 刷新列表
4. 验证 'wb-1' 不在列表中

**预期结果**：
- ✅ 列表刷新后 `state.value` 不包含 id='wb-1' 的记录
- ✅ `state.value.length` 减少 1
- ✅ 删除后 DetailNotifier 状态恰当（如标记为 deleted 或清空）

**失败判定**：
- ❌ 删除后列表中仍存在已删除的工作台
- ❌ 列表长度未变化

---

### TC-I05: 并发操作 — 同时加载列表和详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-I05 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 集成 / 并发 |
| **关联验收标准** | 并发安全 |

**前置条件**：
- FakeWorkbenchService 配置 `list()` 和 `getById()` 均有 50ms 延迟

**测试步骤**：
1. 同时读取 `workbenchListProvider` 和 `workbenchDetailProvider('wb-1')`
2. 等待两者都完成
3. 验证两者数据正确

**预期结果**：
- ✅ 两个 Provider 同时加载，互不阻塞
- ✅ 两者数据均正确
- ✅ 不会因并发导致状态错乱

**失败判定**：
- ❌ 一个 Provider 的加载阻塞另一个
- ❌ 并发导致数据错乱

---

### TC-I06: Provider dispose 后资源清理

| 属性 | 内容 |
|------|------|
| **ID** | TC-I06 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 集成 / 生命周期 |
| **关联验收标准** | 资源正确清理 |

**前置条件**：
- workbenchDetailProvider('wb-1') 已加载

**测试步骤**：
1. 加载 detail provider
2. 调用 `container.dispose()`
3. 验证所有 provider 被正确 dispose

**预期结果**：
- ✅ container.dispose() 不抛出异常
- ✅ 后续读取已 dispose 的 provider 应抛出 `StateError`（Riverpod 默认行为）
- ✅ 如果使用 `autoDispose`，未使用的 provider 自动清理

**失败判定**：
- ❌ dispose 时抛出异常
- ❌ 资源泄漏（定时器、订阅未取消）

---

## 五、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| WorkbenchService — list() | 5 | TC-S01 ~ TC-S05 |
| WorkbenchService — create() | 3 | TC-S06 ~ TC-S08 |
| WorkbenchService — getById() | 2 | TC-S09 ~ TC-S10 |
| WorkbenchService — update() | 2 | TC-S11 ~ TC-S12 |
| WorkbenchService — delete() | 2 | TC-S13 ~ TC-S14 |
| WorkbenchListNotifier — 加载与刷新 | 7 | TC-P01 ~ TC-P07 |
| WorkbenchListNotifier — 搜索与分页 | 3 | TC-P08 ~ TC-P10 |
| WorkbenchListNotifier — 创建后刷新 | 2 | TC-P11 ~ TC-P12 |
| WorkbenchListNotifier — 错误处理 | 3 | TC-P13 ~ TC-P15 |
| WorkbenchDetailNotifier — 详情加载 | 4 | TC-P16 ~ TC-P19 |
| WorkbenchDetailNotifier — 更新操作 | 3 | TC-P20 ~ TC-P22 |
| WorkbenchDetailNotifier — 删除操作 | 3 | TC-P23 ~ TC-P25 |
| WorkbenchDetailNotifier — 错误处理 | 3 | TC-P26 ~ TC-P28 |
| 集成场景测试 | 6 | TC-I01 ~ TC-I06 |
| **合计** | **48** | |

| 优先级分布 | 数量 | 占比 |
|-----------|:---:|:---:|
| P0 — CRITICAL | 21 | 44% |
| P1 — HIGH | 19 | 40% |
| P2 — MEDIUM | 8 | 16% |

---

## 六、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| 列表加载成功（正常数据、空数据、分页） | TC-S01 ~ TC-S03, TC-P01, TC-P02 |
| 创建成功 → 刷新列表 | TC-P11, TC-I01 |
| 更新成功 → 列表/详情同步更新 | TC-P20, TC-I03 |
| 删除成功 → 列表移除 + 确认对话框 | TC-P23, TC-I04 |
| 网络错误 → state.error | TC-S05, TC-P13, TC-P26 |
| CRUD 全部流程走通（mock backend） | TC-S01, TC-S06, TC-S09, TC-S11, TC-S13 |
| 搜索和分页参数正确传递 | TC-S03, TC-S04, TC-P06, TC-P08 |
| 创建/更新/删除后自动刷新列表 | TC-P11, TC-P20, TC-P23 |
| 错误状态正确传播 | TC-P13, TC-P14, TC-P17, TC-P22, TC-P24, TC-P26, TC-P27 |

---

## 七、FakeWorkbenchService 设计参考

测试用例依赖 `FakeWorkbenchService` 类，应遵循 `FakeAuthService` 的模式实现。以下为接口参考：

```dart
class FakeWorkbenchService implements WorkbenchService {
  // ========== 配置参数 ==========
  List<Workbench> listResult;
  PaginatedResponse<Workbench> paginatedResult;
  Workbench? getByIdResult;
  Workbench? createResult;
  Workbench? updateResult;
  
  bool listFails;
  bool createFails;
  bool getByIdFails;
  bool updateFails;
  bool deleteFails;
  bool networkError;
  int? serverStatusCode;
  Duration? delay;

  // ========== 可观测状态 ==========
  int listCallCount, createCallCount, getByIdCallCount,
      updateCallCount, deleteCallCount;
  Map<String, dynamic>? lastListParams;
  String? lastCreateName, lastCreateDescription, lastCreateOwnerType, lastCreateOwnerId;
  String? lastGetByIdArg, lastDeleteArg;
  String? lastUpdateId, lastUpdateName, lastUpdateDescription;
}
```

---

## 八、测试执行记录模板

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-S01 | | | ⬜ 待执行 | list 正常数据 |
| TC-S02 | | | ⬜ 待执行 | list 空数据 |
| TC-S03 | | | ⬜ 待执行 | list 分页参数 |
| TC-S04 | | | ⬜ 待执行 | list 搜索参数 |
| TC-S05 | | | ⬜ 待执行 | list 网络错误 |
| TC-S06 | | | ⬜ 待执行 | create 成功 |
| TC-S07 | | | ⬜ 待执行 | create 空 name |
| TC-S08 | | | ⬜ 待执行 | create 网络错误 |
| TC-S09 | | | ⬜ 待执行 | getById 成功 |
| TC-S10 | | | ⬜ 待执行 | getById 404 |
| TC-S11 | | | ⬜ 待执行 | update 成功 |
| TC-S12 | | | ⬜ 待执行 | update 部分更新 |
| TC-S13 | | | ⬜ 待执行 | delete 成功 |
| TC-S14 | | | ⬜ 待执行 | delete 404 |
| TC-P01 | | | ⬜ 待执行 | build 加载列表 |
| TC-P02 | | | ⬜ 待执行 | build 空列表 |
| TC-P03 | | | ⬜ 待执行 | refresh 重新加载 |
| TC-P04 | | | ⬜ 待执行 | refresh 失败保留数据 |
| TC-P05 | | | ⬜ 待执行 | 多次快速 refresh |
| TC-P06 | | | ⬜ 待执行 | 默认分页参数 |
| TC-P07 | | | ⬜ 待执行 | loadMore 追加 |
| TC-P08 | | | ⬜ 待执行 | search 搜索 |
| TC-P09 | | | ⬜ 待执行 | 清空搜索恢复 |
| TC-P10 | | | ⬜ 待执行 | 分页信息暴露 |
| TC-P11 | | | ⬜ 待执行 | 创建后刷新列表 |
| TC-P12 | | | ⬜ 待执行 | 创建失败列表不变 |
| TC-P13 | | | ⬜ 待执行 | build 网络错误 |
| TC-P14 | | | ⬜ 待执行 | build 500 错误 |
| TC-P15 | | | ⬜ 待执行 | retry 恢复 |
| TC-P16 | | | ⬜ 待执行 | detail build 加载 |
| TC-P17 | | | ⬜ 待执行 | detail 非存在 ID |
| TC-P18 | | | ⬜ 待执行 | 相同 ID 同实例 |
| TC-P19 | | | ⬜ 待执行 | 不同 ID 不同实例 |
| TC-P20 | | | ⬜ 待执行 | update 成功刷新 |
| TC-P21 | | | ⬜ 待执行 | update 部分字段 |
| TC-P22 | | | ⬜ 待执行 | update 失败保留 |
| TC-P23 | | | ⬜ 待执行 | delete 成功 |
| TC-P24 | | | ⬜ 待执行 | delete 失败 |
| TC-P25 | | | ⬜ 待执行 | delete 二次确认 |
| TC-P26 | | | ⬜ 待执行 | detail 网络错误 |
| TC-P27 | | | ⬜ 待执行 | detail 401 错误 |
| TC-P28 | | | ⬜ 待执行 | 错误持久化 |
| TC-I01 | | | ⬜ 待执行 | 创建→列表刷新 |
| TC-I02 | | | ⬜ 待执行 | 列表详情联动 |
| TC-I03 | | | ⬜ 待执行 | 详情更新→列表同步 |
| TC-I04 | | | ⬜ 待执行 | 详情删除→列表移除 |
| TC-I05 | | | ⬜ 待执行 | 并发操作 |
| TC-I06 | | | ⬜ 待执行 | dispose 资源清理 |

---

**文档状态**: ✅ 已完成
**下一步**: sw-tom 审查测试用例 → sw-mike 测试执行
**总用例数**: 48（28 Service + 28 Provider/集成 + 部分用例跨类别）
**具体分布**: Service 14 + ListProvider 15 + DetailProvider 13 + 集成 6 = 48
**文件路径**: `log/release_3/test/TASK-012_test_cases.md`
