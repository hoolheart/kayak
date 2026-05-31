# TASK-003 测试用例 — API Client + Dio 配置

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-003（API Client + Dio 配置，dio 5.9.2）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md), [TASK-002_test_cases.md](TASK-002_test_cases.md)

---

## 测试范围

TASK-003 需交付以下文件：

| # | 文件 | 功能 | 测试覆盖 |
|---|------|------|:------:|
| 1 | `lib/services/api_client.dart` | Dio 实例 + BaseOptions 配置 | TC-001 ~ TC-003 |
| 2 | `lib/services/auth_interceptor.dart` | 自动 Token 附加 + 401 刷新 | TC-004 ~ TC-009 |
| 3 | `lib/services/auth_service.dart` | 认证 Service（login/register/refresh/logout/getMe） | TC-001 ~ TC-009（集成） |
| 4 | `lib/services/error_interceptor.dart` | HTTP 异常 → 用户可读消息 | TC-010 ~ TC-016 |
| 5 | `lib/utils/error_handler.dart` | 错误码 → 消息映射表 | TC-010 ~ TC-016 |

---

## 后端 API 实际格式速查

> 测试中 Mock 的请求/响应格式必须与后端完全一致。

### Token 刷新请求

```json
POST /api/v1/auth/refresh
Content-Type: application/json
Body: { "refresh_token": "<token>" }
```

### Token 刷新响应（成功）

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "admin@kayak.local",
      "username": "Admin"
    }
  },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

### 全局响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": { ... },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

> **错误响应**: 即使是错误状态（4xx/5xx），后端也返回上述格式，`code` 为对应的 HTTP 状态码。

---

## 一、基础配置测试

---

### TC-001: ApiClient 创建成功，BaseOptions 配置正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（阻塞所有 API 调用） |
| **类别** | 基础配置 / 初始化 |
| **关联验收标准** | `ApiClient` 正确初始化，可发起请求 |

**前置条件**：
- TASK-002 完成，`kayak-frontend/` 项目中已存在数据模型
- `pubspec.yaml` 中已配置 `dio: ^5.9.2`
- `lib/services/api_client.dart` 已实现

**测试步骤**：

1. 导入 `ApiClient` 类
2. 创建 `ApiClient` 实例，传入 `baseUrl: 'http://localhost:8080/api/v1'` 和 `AuthService`
3. 验证 `ApiClient` 实例成功创建，不抛出异常
4. 检查内部 `Dio` 实例的 `BaseOptions`：
   - `baseUrl` = `'http://localhost:8080/api/v1'`
   - `connectTimeout` = `Duration(seconds: 10)`
   - `receiveTimeout` = `Duration(seconds: 10)`
   - `headers['Content-Type']` = `'application/json'`

**预期结果**：
- ✅ `ApiClient` 构造成功，无异常
- ✅ `_dio.options.baseUrl` = `'http://localhost:8080/api/v1'`
- ✅ `_dio.options.connectTimeout` = `Duration(seconds: 10)`
- ✅ `_dio.options.receiveTimeout` = `Duration(seconds: 10)`
- ✅ `_dio.options.headers['Content-Type']` = `'application/json'`

**失败判定**：
- ❌ `ApiClient` 构造抛出异常（如空 baseUrl、AuthService null 等）
- ❌ baseUrl 未包含 `/api/v1` 前缀
- ❌ 超时配置错误（若使用旧版 `int` 类型则 CI 不通过）

---

### TC-002: Dio 拦截器数量与顺序正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（拦截器顺序影响 Token 刷新和错误处理） |
| **类别** | 基础配置 / 拦截器注册 |
| **关联验收标准** | 三个拦截器均正确注册 |

**前置条件**：
- TC-001 通过（`ApiClient` 创建成功）
- `AuthInterceptor`、`ErrorInterceptor`、`LogInterceptor` 类已定义

**测试步骤**：

1. 创建 `ApiClient` 实例
2. 获取内部 `Dio` 实例的 `interceptors` 列表
3. 验证拦截器数量 = 3
4. 验证拦截器类型和顺序：
   - 第 0 个 = `AuthInterceptor` 实例
   - 第 1 个 = `ErrorInterceptor` 实例
   - 第 2 个 = `LogInterceptor` 实例

**预期结果**：
- ✅ `interceptors.length` = 3
- ✅ 第 0 个是 `AuthInterceptor`（优先处理 Token）
- ✅ 第 1 个是 `ErrorInterceptor`（在 Auth 之后处理错误）
- ✅ 第 2 个是 `LogInterceptor`（在最外层记录日志）

**失败判定**：
- ❌ 拦截器个数 ≠ 3
- ❌ `AuthInterceptor` 不在最前面（会导致 401 先被 ErrorInterceptor 拦截而非触发刷新）
- ❌ 任一拦截器类型不匹配（如用了 `InterceptorsWrapper` 替代专用类）

---

### TC-003: ApiClient 依赖注入 AuthService 正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P1 — HIGH** |
| **类别** | 基础配置 / 依赖注入 |
| **关联验收标准** | AuthService 正确传递给 AuthInterceptor |

**前置条件**：
- TC-001 通过
- `AuthService` 有至少一个方法（如 `getToken()`）

**测试步骤**：

1. 创建一个 Mock `AuthService`（真实 mock 对象或 fake 实现）
2. 用该 Mock 创建 `ApiClient`
3. 通过反射或测试辅助方法，验证 `AuthInterceptor` 内部持有的 `AuthService` 引用与传入的为同一实例
4. 在 Mock `AuthService` 上设置可观测的副作用（如设置 `getToken()` 返回特定值）
5. 通过 `AuthInterceptor` 发起一次请求，验证 Token 取自该 Mock `AuthService`

**预期结果**：
- ✅ `AuthInterceptor` 持有的 `authService` 引用与传入 `ApiClient` 的一致
- ✅ `AuthInterceptor.onRequest` 能够从该 `AuthService` 获取 Token
- ✅ AuthService 为 null 时构造应抛出异常（防御性编程）

**失败判定**：
- ❌ AuthInterceptor 不从注入的 AuthService 获取 Token（硬编码或内部新建）
- ❌ AuthService 为 null 时未报错（导致运行时 NPE）

---

## 二、AuthInterceptor 测试

---

### TC-004: 有 Token 时请求头自动附加 Authorization: Bearer

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — CRITICAL**（所有受保护 API 依赖此行为） |
| **类别** | AuthInterceptor / Token 附加 |
| **关联验收标准** | Token 附加 ✅ |

**前置条件**：
- `AuthService` Mock 设置 `getAccessToken()` 返回 `"valid-access-token-abc123"`
- `ApiClient` 已创建并注入该 Mock AuthService
- 使用 `flutter_secure_storage` 10.3.1 存储 Token 的场景已覆盖（通过 Mock AuthService）

**测试步骤**：

1. 使用 `ApiClient` 发起一次 GET 请求（如 `get('/test')`）
2. 在 `AuthInterceptor.onRequest` 执行后，验证 `RequestOptions.headers` 中包含：

```
Authorization: Bearer valid-access-token-abc123
```

3. 验证原始 `Content-Type: application/json` 头仍保留

**预期结果**：
- ✅ `options.headers['Authorization']` = `'Bearer valid-access-token-abc123'`
- ✅ 已有的请求头未被覆盖
- ✅ 如果 Token 带空格/换行符，应在使用前 trim

**失败判定**：
- ❌ `Authorization` 头缺失
- ❌ Token 前缀不是 `"Bearer "`（如 `"bearer"` 小写、缺少空格等）
- ❌ Token 值为空字符串时仍然添加了 `Authorization` 头

---

### TC-005: 无 Token 时不添加 Authorization 头

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P1 — HIGH**（避免无效认证头发送） |
| **类别** | AuthInterceptor / Token 缺失 |
| **关联验收标准** | 无 Token 时不附加 |

**前置条件**：
- `AuthService` Mock 设置 `getAccessToken()` 返回 `null` 或空字符串

**测试步骤**：

1. 使用 `ApiClient` 发起一次 GET 请求
2. 验证最终 `RequestOptions.headers` 中 `Authorization` 键不存在

**预期结果**：
- ✅ `options.headers['Authorization']` = `null`（不存在该键）
- ✅ 请求正常发送，不因 Token 缺失而抛出异常
- ✅ `Content-Type: application/json` 等默认头保持正常

**失败判定**：
- ❌ 空值仍然发送了 `Authorization: Bearer null` 或 `Authorization: Bearer `
- ❌ Token 为 null 时 AuthInterceptor 本身抛出异常

---

### TC-006: 401 时自动调用 Refresh Token

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — CRITICAL**（核心会话续期功能） |
| **类别** | AuthInterceptor / 401 刷新 |
| **关联验收标准** | 401 刷新 ✅ |

**前置条件**：
- `AuthService` Mock 配置：
  - `getAccessToken()` 返回 `"expired-token"`
  - `getRefreshToken()` 返回 `"valid-refresh-token"`
  - `refresh()` 模拟成功的刷新调用，返回新的 `AuthTokens`
  - `saveTokens(AuthTokens)` 可观测（记录被调用）
- Mock HTTP 服务器配置：对受保护接口返回 401
- `POST /api/v1/auth/refresh` 请求成功返回 200 + 新 Token

**测试步骤**：

1. 使用 `ApiClient` 发起 GET 请求到受保护资源
2. 服务器返回 HTTP 401
3. 验证 `AuthInterceptor.onError` 被触发
4. 验证 `StatusError` 或对应的 `DioException` 中 `response?.statusCode` = 401
5. 验证 `AuthService.refresh()` 被调用（且仅被调用一次）
6. 验证 refresh 调用时请求体为 `{"refresh_token": "valid-refresh-token"}`

**预期结果**：
- ✅ 收到 401 响应后，调用了 `AuthService.refresh()`
- ✅ refresh 请求使用了正确的 Refresh Token
- ✅ refresh 只调用了 **1 次**（非递归或死循环）
- ✅ refresh 请求本身不被 AuthInterceptor 拦截处理（refresh 接口无需认证）

**失败判定**：
- ❌ 401 时不触发 refresh（直接抛出异常或静默失败）
- ❌ 对 refresh 请求本身也发起 refresh → 无限循环
- ❌ refresh 时使用了空 Token
- ❌ 调用了 `refresh()` 超过 1 次（同一次 401）

---

### TC-007: Refresh 成功后自动重试原请求

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL**（用户无感知 Token 刷新） |
| **类别** | AuthInterceptor / 重试机制 |
| **关联验收标准** | 401 刷新成功重试 ✅ |

**前置条件**：
- TC-006 的 Mock 配置
- `AuthService.refresh()` 成功返回新的 `AuthTokens`（`new-access-token`, `new-refresh-token`）
- Mock HTTP 服务器配置：
  - 第 1 次 GET 请求 → 返回 401
  - 第 2 次 GET 请求（重试）→ 返回 200 + `{"code": 200, "message": "success", "data": {...}, "timestamp": "..."}`
- 使用 `interceptors` + error handler 机制

**测试步骤**：

1. 使用 `ApiClient` 发起 GET 请求到受保护资源
2. 第 1 次请求：服务器返回 401 → AuthInterceptor 触发 refresh
3. refresh 成功 → 新 Token 写入 `AuthService`
4. 验证原请求被重试（retry），且重试时的请求头携带新 Token：

```
Authorization: Bearer new-access-token
```

5. 验证最终 `Response.statusCode` = 200
6. 验证 `AuthService.saveTokens()` 被调用且收到新的 AuthTokens

**预期结果**：
- ✅ 最终响应 statusCode = 200
- ✅ 最终返回的是重试后的成功响应（非 401）
- ✅ 重试请求的 `Authorization` 头使用了刷新后的新 Token
- ✅ 新 Token 被持久化（`saveTokens` 被调用）
- ✅ 用户端代码无需任何 401 处理（完全由拦截器透明处理）

**失败判定**：
- ❌ 重试请求仍使用旧 Token → 再次 401
- ❌ 新 Token 未持久化
- ❌ 原始请求的参数（query params、body）在重试时丢失
- ❌ 最终返回 401 而非 200

---

### TC-008: Refresh 失败时清除 Token 并通知状态变更

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — CRITICAL**（会话过期后必须安全退出） |
| **类别** | AuthInterceptor / 刷新失败 |
| **关联验收标准** | 刷新失败登出 ✅ |

**前置条件**：
- `AuthService` Mock 配置：
  - `refresh()` 失败（抛出异常，如 403/401 "Refresh token expired"）
  - `clearTokens()` 可观测
- `AuthService` 暴露认证状态变更通知（如 `Stream`/回调/Provider 更新）

**测试步骤**：

1. 使用 `ApiClient` 发起 GET 请求到受保护资源
2. 服务器返回 401
3. AuthInterceptor 调用 `AuthService.refresh()`
4. refresh 失败（Refresh Token 也过期/无效）
5. 验证以下操作被执行：
   - ✅ `AuthService.clearTokens()` 被调用（清除 `flutter_secure_storage` 中的 Token）
   - ✅ 认证状态被设置为"未认证"/User 变为 null
   - ✅ 抛出适当的异常（可被上层路由守卫捕获，重定向到 `/login`）
6. 验证不会进入无限循环（refresh 失败后不再尝试 refresh）

**预期结果**：
- ✅ `clearTokens()` 被调用（且仅一次）
- ✅ Access Token 和 Refresh Token 均从本地存储中清除
- ✅ 认证状态变更通知已发出（上层可监听并触发路由重定向或 Toast）
- ✅ 最终抛出的异常信息包含友好提示（如"会话已过期，请重新登录"）

**失败判定**：
- ❌ refresh 失败后未清除 Token（残留无效 Token 在 secure storage）
- ❌ Token 清除后未通知状态变更（UI 仍显示已登录）
- ❌ refresh 失败后再次尝试 refresh（死循环）
- ❌ 硬编码重定向到 `/login`（应由路由层处理，拦截器不应直接操作路由）

---

### TC-009: 并发 401 请求的刷新锁（Token Refresh Lock）

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P1 — HIGH**（多请求并发时避免重复刷新） |
| **类别** | AuthInterceptor / 并发控制 |
| **关联验收标准** | 同一 Token 仅刷新一次 |

**前置条件**：
- `AuthService.refresh()` 模拟为异步操作（延迟 500ms 后完成）
- 执行情况：使用同一个 `ApiClient` 实例**同时**（或几乎同时）发起 3 个请求
- 3 个请求均返回 401

**测试步骤**：

1. 同时发出 3 个 GET 请求（使用 `Future.wait` 或并行 `Future`）
2. 所有 3 个请求返回 401
3. 验证 `AuthService.refresh()` 被调用的次数：

**预期结果**：
- ✅ `AuthService.refresh()` 被调用 **恰好 1 次**（而非 3 次）
- ✅ 第一个 401 触发 refresh，后续 2 个 401 等待 refresh 完成后使用新 Token 重试
- ✅ 最终 3 个请求全部成功重试（返回 200）
- ✅ 没有请求因 "Token 正在刷新中" 而直接失败

**失败判定**：
- ❌ `refresh()` 被调用 3 次（缺乏锁机制）
- ❌ 并发请求中部分请求直接失败而未重试
- ❌ 锁机制导致死锁（所有请求卡住）

---

## 三、ErrorInterceptor 测试

---

### TC-010: 400 状态码 — 请求参数错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P0 — CRITICAL**（表单验证反馈的关键通道） |
| **类别** | ErrorInterceptor / HTTP 400 |
| **关联验收标准** | 所有 HTTP 状态码映射正确 |

**前置条件**：
- `ApiClient` 已创建，`ErrorInterceptor` 已注册
- Mock HTTP 服务器返回：

```json
HTTP 400 Bad Request
{
  "code": 400,
  "message": "Validation failed for field 'email'",
  "data": null,
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

**测试步骤**：

1. 使用 `ApiClient` 发起 POST 请求，传入无效数据
2. 服务器返回 400
3. 在 `ErrorInterceptor.onError` 中验证变换后的错误信息
4. 验证用户最终收到的异常消息

**预期结果**：
- ✅ 错误消息 = `'请求参数有误，请检查输入'`
- ✅ 后端原始 `message` 字段内容不会被直接暴露给用户
- ✅ `DioException` 或自定义异常类型正确传播，上层可捕获

**额外验证 — 后端返回精细错误时**：

如后端 `message` 中携带字段级错误信息（如 `"email: invalid format"`），前端应：
- ⚠️ 如 l10n 框架尚未完成，临时保留后端详细消息供开发调试使用
- ⚠️ 理想情况：前端映射为更友好的通用消息

**失败判定**：
- ❌ 400 返回的错误消息与其他状态码消息混淆（如返回了 500 的消息）
- ❌ 抛出原始 JSON 而非用户可读消息
- ❌ 异常未被正确抛出（被静默吞掉）

---

### TC-011: 401 状态码 — 登录已过期

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ErrorInterceptor / HTTP 401 |
| **关联验收标准** | 所有 HTTP 状态码映射正确 |

**前置条件**：
- Mock HTTP 服务器返回：

```json
HTTP 401 Unauthorized
{
  "code": 401,
  "message": "Authentication required",
  "data": null,
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

> **注意**：此测试验证 ErrorInterceptor 在 AuthInterceptor 未成功刷新或 refresh 本身返回 401 时的错误消息处理。

**测试步骤**：

1. 直接使用 `ErrorInterceptor` 测试（绕过 AuthInterceptor），或模拟刷新失败后的 401 响应
2. 验证错误消息

**预期结果**：
- ✅ 错误消息 = `'登录已过期，请重新登录'`
- ✅ 消息明确告知用户需要重新登录

**失败判定**：
- ❌ 错误消息与技术细节（用户看不到"expired"、"invalid"等字样）

---

### TC-012: 403 状态码 — 权限不足

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ErrorInterceptor / HTTP 403 |

**前置条件**：
- Mock HTTP 服务器返回 403

**测试步骤**：

1. 使用 `ApiClient` 发起请求到无权限的资源
2. 验证错误消息

**预期结果**：
- ✅ 错误消息 = `'您没有权限执行此操作'`

**失败判定**：
- ❌ 错误消息与技术细节

---

### TC-013: 404 状态码 — 资源不存在

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ErrorInterceptor / HTTP 404 |

**前置条件**：
- Mock HTTP 服务器返回 404

**测试步骤**：

1. 使用 `ApiClient` 发起 GET 请求到不存在的资源
2. 验证错误消息

**预期结果**：
- ✅ 错误消息 = `'请求的资源不存在或已被删除'`

**失败判定**：
- ❌ 错误消息与技术细节

---

### TC-014: 500 状态码 — 服务器内部错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P1 — HIGH** |
| **类别** | ErrorInterceptor / HTTP 500 |

**前置条件**：
- Mock HTTP 服务器返回 500

**测试步骤**：

1. 使用 `ApiClient` 发起请求
2. 服务器返回 500
3. 验证错误消息

**预期结果**：
- ✅ 错误消息 = `'服务器内部错误，请稍后重试'`
- ✅ 后端 500 的具体错误（如 stack trace）不被暴露

**失败判定**：
- ❌ 暴露了后端错误细节
- ❌ 500 的消息与其他状态码混淆

---

### TC-015: 连接超时 — 正确错误消息

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P1 — HIGH**（网络故障场景） |
| **类别** | ErrorInterceptor / 网络异常 |

**前置条件**：
- Mock HTTP 服务器配置为 accept 连接但不返回响应（模拟 timeout）
- 或使用 `DioException` 直接构造 `DioExceptionType.connectionTimeout` 类型的异常

**测试步骤**：

1. 使用 `ApiClient` 发起请求到慢响应/无响应端点
2. 请求因超时而失败
3. 验证 `ErrorInterceptor.onError` 处理的异常类型
4. 验证错误消息

**预期结果**：
- ✅ 错误消息 = `'连接超时，请检查网络'`
- ✅ `DioExceptionType.connectionTimeout` 和 `DioExceptionType.receiveTimeout` 应有区分
- ✅ 超时错误不会触发 AuthInterceptor 的 refresh 逻辑（不是 401）

**失败判定**：
- ❌ 超时异常未被 `ErrorInterceptor` 正确分类处理
- ❌ 错误消息为英文技术描述（`"Connection timeout"`）

---

### TC-016: 无网络 / DNS 解析失败 — 正确错误消息

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P1 — HIGH** |
| **类别** | ErrorInterceptor / 网络异常 |

**前置条件**：
- 使用 `DioException` 直接构造：
  - 类型 1：`DioExceptionType.connectionError`（连接被拒绝）
  - 类型 2：`DioExceptionType.unknown` + socket exception

**测试步骤**：

1. 分别模拟两种网络异常场景
2. 验证 `ErrorInterceptor` 生成的错误消息

**预期结果**：
- ✅ 连接拒绝 → `'网络错误，请检查连接'` 或 `'连接超时，请检查网络'`
- ✅ DNS 解析失败 / 无网络 → `'网络错误，请检查连接'`
- ✅ "其他未知异常" → `'网络错误，请检查连接'`（通用兜底消息）

**类型匹配测试**：

| `DioExceptionType` | 期望消息 |
|---|---|
| `connectionTimeout` | `'连接超时，请检查网络'` |
| `receiveTimeout` | `'连接超时，请检查网络'` |
| `sendTimeout` | `'连接超时，请检查网络'` |
| `connectionError` | `'网络错误，请检查连接'` |
| `unknown` | `'网络错误，请检查连接'` |

**失败判定**：
- ❌ 网络异常抛出了 400/500 等 HTTP 错误消息（异常类型区分错误）
- ❌ 网络异常直接透传原始系统异常信息

---

### TC-017: ErrorInterceptor 覆盖所有指定 HTTP 状态码

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ErrorInterceptor / 完整覆盖 |
| **关联验收标准** | 所有 HTTP 状态码映射正确 |

**前置条件**：
- `ErrorInterceptor` 或 `ErrorHandler` 已实现
- `lib/utils/error_handler.dart` 中存在状态码→消息的映射表

**测试步骤**：

对以下每个 HTTP 状态码，构造对应的 `DioException`（带 `response`），验证返回的消息：

| HTTP 状态码 | 期望错误消息 | 说明 |
|:----------:|-------------|------|
| **400** | `'请求参数有误，请检查输入'` | 客户端请求格式错误 |
| **401** | `'登录已过期，请重新登录'` | 未认证/Token 失效 |
| **403** | `'您没有权限执行此操作'` | 已认证但无权限 |
| **404** | `'请求的资源不存在或已被删除'` | 资源未找到 |
| **409** | `'资源冲突，可能已存在相同名称的记录'` | 创建/更新冲突 |
| **422** | `'数据验证失败，请检查输入'` | 请求参数语义错误 |
| **500** | `'服务器内部错误，请稍后重试'` | 服务端错误 |
| **502** | `'服务器内部错误，请稍后重试'` | Bad Gateway |
| **503** | `'服务器内部错误，请稍后重试'` | 服务不可用 |

**额外测试 — 未覆盖的状态码**：

| HTTP 状态码 | 期望行为 |
|:----------:|----------|
| 418 | 应返回通用消息或后端 message（非崩溃） |
| 429 | 应识别为频率限制（如果后端支持），否则为通用消息 |

**预期结果**：
- ✅ 上表所有 9 个状态码均有明确的消息映射
- ✅ 未映射的状态码不导致崩溃，返回有意义的兜底消息
- ✅ 每条消息是用户可理解的（不含技术术语）

**失败判定**：
- ❌ 任一状态码缺少映射（返回 null/空字符串/技术错误）
- ❌ 未映射状态码导致抛出 `NullPointerException`
- ❌ 错误消息与预期不一致

---

## 四、HTTP 方法测试

---

### TC-018: GET 请求成功返回数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P1 — HIGH** |
| **类别** | HTTP 方法 / GET |
| **关联验收标准** | Dio 5.9.2 Duration API 正确使用 |

**前置条件**：
- Mock HTTP 服务器返回：

```json
HTTP 200 OK
{
  "code": 200,
  "message": "success",
  "data": { "test": "value" },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

1. 使用 `ApiClient` 发起 GET 请求到 `/test`
2. 验证响应：

**预期结果**：
- ✅ `response.statusCode` = 200
- ✅ `response.data` 正确解析为 `Map<String, dynamic>`
- ✅ `response.data['code']` = 200
- ✅ 请求方法为 GET

**失败判定**：
- ❌ 请求失败（非本测试场景）
- ❌ 响应数据丢失

---

### TC-019: POST 请求成功发送 JSON Body 并返回数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P1 — HIGH** |
| **类别** | HTTP 方法 / POST |

**前置条件**：
- Mock HTTP 服务器配置验证 POST body 内容
- 使用 `ApiClient.post('/test', data: {'key': 'value'})` 发送请求

**测试步骤**：

1. 使用 `ApiClient` 发起 POST 请求
2. 验证请求发出时：
   - 方法 = POST
   - `Content-Type: application/json`
   - Body = `{"key": "value"}`
3. 验证服务器返回的响应

**预期结果**：
- ✅ POST 方法正确
- ✅ JSON body 正确编码（`Map<String, dynamic>` → `application/json`）
- ✅ 响应正确返回

**失败判定**：
- ❌ POST body 未序列化为 JSON（仍为 Dart Map 类型，未 encode）
- ❌ `Content-Type` 不正确

---

### TC-020: PUT 请求成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | HTTP 方法 / PUT |

**前置条件**：
- Mock HTTP 服务器配置验证 PUT body 内容

**测试步骤**：

1. 使用 `ApiClient.put('/test/1', data: {'name': 'updated'})` 发送请求
2. 验证请求方法 = PUT，body 正确

**预期结果**：
- ✅ 请求方法 = PUT
- ✅ Body 正确

---

### TC-021: DELETE 请求成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-021 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | HTTP 方法 / DELETE |

**前置条件**：
- Mock HTTP 服务器配置验证 DELETE 无 body

**测试步骤**：

1. 使用 `ApiClient.delete('/test/1')` 发送请求
2. 验证请求方法 = DELETE
3. 验证 DELETE 请求不发送 body（或 body 为空）

**预期结果**：
- ✅ 请求方法 = DELETE
- ✅ 成功返回 200 或 204

---

## 五、响应解析测试

---

### TC-022: 成功响应解析为 ApiResponse\<T\>

| 属性 | 内容 |
|------|------|
| **ID** | TC-022 |
| **优先级** | **P0 — CRITICAL**（所有 API 调用依赖此解析） |
| **类别** | 响应解析 / 泛型 |
| **关联验收标准** | ApiResponse 泛型正确工作（依赖 TASK-002 的 `ApiResponse<T>` 模型） |

**前置条件**：
- TASK-002 `ApiResponse<T>` 和 `User` 模型已实现
- Mock HTTP 服务器返回：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "admin@kayak.local",
    "username": "Admin",
    "avatar_url": null,
    "status": "active",
    "created_at": "2026-05-31T10:30:00Z",
    "updated_at": "2026-05-31T10:30:00Z"
  },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

**测试步骤**：

1. 使用 `ApiClient` 发起 GET 请求
2. 将响应解析为 `ApiResponse<User>`
3. 验证：
   - `response.code` = 200
   - `response.message` = `"success"`
   - `response.data.email` = `"admin@kayak.local"`
   - `response.data` 是 `User` 类型

**预期结果**：
- ✅ `ApiResponse<User>` 正确反序列化
- ✅ 泛型 `data` 字段为 `User` 类型（非 `Map<String, dynamic>`）
- ✅ `timestamp` 正确解析（可选字段）
- ✅ 所有 `User` 字段正确映射

**失败判定**：
- ❌ `data` 字段类型擦除（泛型丢失，变成 `Map<String, dynamic>`）
- ❌ `data` 为 `null` 时抛出异常（如果后端 data 为 null）
- ❌ JSON 解析失败

---

### TC-023: 错误响应正确抛出异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-023 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 响应解析 / 错误处理 |

**前置条件**：
- Mock HTTP 服务器返回：

```json
HTTP 400 Bad Request
{
  "code": 400,
  "message": "Validation failed for field 'email'",
  "data": null,
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

**测试步骤**：

1. 使用 `ApiClient` 发起请求
2. 服务器返回 400
3. 验证：
   - ErrorInterceptor 将异常转换为用户可读消息
   - 异常类型为 `DioException` 或自定义异常
   - 原始 HTTP 状态码可查询
   - 异常消息不暴露后端技术细节

**预期结果**：
- ✅ 最终抛出的异常消息 = `'请求参数有误，请检查输入'`（用户可读）
- ✅ 异常类型保留 `statusCode` 信息（用于更细粒度的判断）
- ✅ 后端 `message` 字段可通过 `.response?.data?['message']` 访问（用于调试）
- ✅ 不会因为后端的异常消息格式（如 `message` 为 null）而二次崩溃

**失败判定**：
- ❌ 异常消息直接展示后端返回的 `"Validation failed for field 'email'"` （未经用户友好化）
- ❌ 后端响应的 JSON 解析失败导致抛出 `FormatException`（未正确处理格式）

---

### TC-024: 空响应 / 204 No Content 正确处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-024 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 响应解析 / 边界 |
| **关联验收标准** | 空响应不崩溃 |

**前置条件**：
- Mock HTTP 服务器返回：
  - 场景 A：HTTP 204（无 body）
  - 场景 B：HTTP 200 + body 为 `""` 空字符串
  - 场景 C：HTTP 200 + body 为 `"null"`

**测试步骤**：

1. 分别使用 `ApiClient` 发起 3 次请求
2. 验证每种空响应场景的处理

**预期结果**：

| 场景 | 状态码 | Body | 期望行为 |
|------|:------:|------|----------|
| A | 204 | 空 | 返回成功，`data` 为 null |
| B | 200 | `""` | 不抛出 JSON 解析异常（按空响应处理） |
| C | 200 | `"null"` | 解析为 null data |

- ✅ 空响应不抛出未捕获的异常
- ✅ 204 No Content 被 Dio 正常处理（`response.data` 可能为 null 或空字符串）
- ✅ `ApiResponse` 的 `data` 字段可为 null

**失败判定**：
- ❌ 空 body 导致 JSON 解析崩溃
- ❌ 204 响应抛出异常（应视为正常响应）

---

## 六、集成场景测试

---

### TC-025: 完整 Token 刷新流程集成测试

| 属性 | 内容 |
|------|------|
| **ID** | TC-025 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 集成测试 / 完整流程 |

**测试描述**：模拟完整的 Token 过期 → 刷新 → 重试流程。

**测试步骤**：

```
Step 1: 准备
  - AuthService 存有 validRefreshToken = "ref-abc-123"
  - AuthService 存有 expiredAccessToken = "exp-xyz-456"
  - 创建 ApiClient(应设置好 AuthInterceptor)
  
Step 2: 发起请求
  - GET /api/v1/workbenches
  - 请求头携带 Authorization: Bearer exp-xyz-456
  
Step 3: 后端返回 401
  - HTTP 401 {"code": 401, "message": "Token expired", ...}
  
Step 4: AuthInterceptor 触发 Refresh
  - POST /api/v1/auth/refresh
  - Body: {"refresh_token": "ref-abc-123"}
  - 响应: {"code": 200, "data": {"access_token": "new-acc-789", "refresh_token": "new-ref-012", "token_type": "Bearer", "expires_in": 3600, ...}}
  
Step 5: 重试原请求
  - GET /api/v1/workbenches (retry)
  - 请求头携带 Authorization: Bearer new-acc-789
  
Step 6: 后端返回 200
  - {"code": 200, "data": [...workbenches...], ...}
  
Step 7: 验证
  - AuthService 中 accessToken = "new-acc-789"
  - AuthService 中 refreshToken = "new-ref-012"
  - 最终返回的 response.data 包含工作台列表
  - 最终 response.statusCode = 200
```

**预期结果**：
- ✅ 步骤 2-6 全部按序正确执行
- ✅ 最终获得正确的数据（200 + workbench list）
- ✅ Token 被更新并持久化
- ✅ 用户无感知整个过程

**失败判定**：
- ❌ 流程中任一步出错
- ❌ 最终 Token 未更新
- ❌ 重试的请求使用了旧 Token

---

### TC-026: AuthService 登录/注册/登出流程集成测试

| 属性 | 内容 |
|------|------|
| **ID** | TC-026 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 集成测试 / AuthService |

**测试描述**：验证 `AuthService` 的完整 CRUD 流程。

**测试步骤**：

```
Step 1: login
  - POST /api/v1/auth/login
  - Body: {"email": "admin@kayak.local", "password": "Admin123"}
  - 响应: ApiResponse<TokenResponse> (access_token, refresh_token, token_type, expires_in, user)

Step 2: 验证 Token 已存储
  - AuthService.getAccessToken() 返回有效 token
  - AuthService.getRefreshToken() 返回有效 refresh token
  
Step 3: getMe
  - GET /api/v1/auth/me
  - 响应: ApiResponse<User>
  
Step 4: refresh
  - POST /api/v1/auth/refresh
  - Body: {"refresh_token": "<refresh_token>"}
  - Token 更新后存储

Step 5: logout
  - AuthService.logout()
  - AuthService.getAccessToken() 返回 null
  - AuthService.getRefreshToken() 返回 null
  - 所有本地 Token 被清除
```

**预期结果**：
- ✅ login 成功后，两个 Token 都存储在 `flutter_secure_storage`
- ✅ `getMe()` 返回 User 对象
- ✅ `refresh()` 更新 Token 并存储
- ✅ `logout()` 清除所有本地 Token
- ✅ login 失败时抛出异常（含友好错误消息）

**失败判定**：
- ❌ Token 未存储/存储位置错误
- ❌ logout 后残留 Token 数据
- ❌ login 成功但 getMe 失败

---

### TC-027: flutter_secure_storage 10.3.1 读写兼容性

| 属性 | 内容 |
|------|------|
| **ID** | TC-027 |
| **优先级** | **P1 — HIGH** |
| **类别** | 集成测试 / 存储 |

**测试描述**：验证 `flutter_secure_storage` 10.3.1 的存储/读取/删除操作。

**测试步骤**：

1. 调用 `AuthService.saveTokens(AuthTokens(accessToken: "a", refreshToken: "r", tokenType: "Bearer", expiresIn: 3600))`
2. 验证：
   - `read(key: 'access_token')` = `"a"`
   - `read(key: 'refresh_token')` = `"r"`
   - `read(key: 'token_type')` = `"Bearer"`
   - `read(key: 'expires_in')` = `"3600"`
3. 调用 `AuthService.clearTokens()`
4. 验证所有 key 返回 null

**预期结果**：
- ✅ 在支持的平台上（Android/iOS/Web）正确存储和读取
- ✅ `clearTokens` 后所有值为 null
- ✅ 存储操作不抛出异常（所有平台）

**平台注意事项**：
- **Web**: `flutter_secure_storage` 在 Web 上使用浏览器的 Local Storage 或 IndexedDB，功能降级
- **Linux**: 需要 `libsecret-1-dev`
- CI 环境中可能需要特殊处理（mock 或集成测试跳过）

**失败判定**：
- ❌ 写入后读取不到
- ❌ 清除后仍可读取

---

## 七、边界与负向测试

---

### TC-028: baseUrl 不含 scheme 时的处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-028 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 边界测试 / BaseOptions |

**测试描述**：验证 baseUrl 非法输入时的防御性处理。

**测试步骤**：

1. 尝试创建 `ApiClient(baseUrl: 'localhost:8080')`  （缺少 `http://`）
2. 尝试创建 `ApiClient(baseUrl: '')`（空字符串）
3. 尝试创建 `ApiClient(baseUrl: null)`（null 值）

**预期结果**：
- ❌（场景 1）缺少 scheme 时 `ApiClient` 构造应失败或 Dio 在首次请求时报错
- ❌（场景 2）空字符串 baseUrl → Dio 抛出明确的异常（非运行时崩溃）
- ❌（场景 3）null baseUrl → 构造时应尽早报错（如 assert 或 throw ArgumentError）

**失败判定**：
- ❌ 非法 baseUrl 导致静默失败（请求发到错误地址且无提示）
- ❌ 构造阶段不报错，但运行时崩溃信息不明确

---

### TC-029: Token 包含特殊字符时的处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-029 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 边界测试 / Token 格式 |

**测试描述**：验证 Token 值包含特殊字符时头部正确编码。

**测试步骤**：

1. Mock `AuthService.getAccessToken()` 返回含有特殊字符的 Token：
   - Token A: 包含空格 → `"abc def ghi"`
   - Token B: 包含换行 → `"line1\nline2"`
   - Token C: 包含中文 → `"测试token123"`

2. 发起请求并验证请求头

**预期结果**：
- ✅ Token 值不应被截断或错误编码
- ⚠️ 理想情况：Token 应在使用前 trim（去除头尾空格）
- ✅ 请求仍能正常发出（不代表后端会接受这些 Token）

**失败判定**：
- ❌ Token 中有空格导致 `Authorization` 头被拆分为多行
- ❌ Token 中有换行符导致 HTTP 头注入

---

### TC-030: dio 5.9.2 Duration API 正确使用

| 属性 | 内容 |
|------|------|
| **ID** | TC-030 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 版本兼容性 / dio 5.9.2 API |
| **关联验收标准** | 使用 Duration 类型的 timeout 参数（非 int） |

**测试描述**：确保没有使用 dio 旧版 `int` timeout API。

**前置条件**：
- `lib/services/api_client.dart` 已实现
- `pubspec.yaml` 约束为 `dio: ^5.9.2`

**测试步骤**：

1. 运行 `flutter analyze`
2. 如果 dio 旧版 API 仍被使用，analyzer 会报告类型错误

**需要检查的代码模式**：

```dart
// ❌ 旧版 API（dio 4.x）— 应禁止
BaseOptions(
  connectTimeout: 10000,    // int
  receiveTimeout: 30000,    // int
)

// ✅ 新版 API（dio 5.x）— 应使用
BaseOptions(
  connectTimeout: Duration(seconds: 10),   // Duration
  receiveTimeout: Duration(seconds: 30),    // Duration
)
```

**预期结果**：
- ✅ `connectTimeout` 类型为 `Duration`（非 `int`）
- ✅ `receiveTimeout` 类型为 `Duration`（非 `int`）
- ✅ `flutter analyze` 无类型错误
- ✅ 代码中使用 `DioException` 而非 `DioError`

**失败判定**：
- ❌ 使用 `int` 作为 timeout 参数
- ❌ 引用 `DioError`（dio 4.x 已弃用名称）
- ❌ `flutter analyze` 报告 dio 相关类型错误

---

## 八、测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | ApiClient 创建 + BaseOptions |
| TC-002 | | | ⬜ 待执行 | 拦截器数量与顺序 |
| TC-003 | | | ⬜ 待执行 | AuthService 依赖注入 |
| TC-004 | | | ⬜ 待执行 | Token 附加 Bearer |
| TC-005 | | | ⬜ 待执行 | 无 Token 不附加 |
| TC-006 | | | ⬜ 待执行 | 401 触发 Refresh |
| TC-007 | | | ⬜ 待执行 | Refresh 成功后重试 |
| TC-008 | | | ⬜ 待执行 | Refresh 失败清除 Token |
| TC-009 | | | ⬜ 待执行 | 并发 401 刷新锁 |
| TC-010 | | | ⬜ 待执行 | 400 错误消息 |
| TC-011 | | | ⬜ 待执行 | 401 错误消息 |
| TC-012 | | | ⬜ 待执行 | 403 错误消息 |
| TC-013 | | | ⬜ 待执行 | 404 错误消息 |
| TC-014 | | | ⬜ 待执行 | 500 错误消息 |
| TC-015 | | | ⬜ 待执行 | 连接超时消息 |
| TC-016 | | | ⬜ 待执行 | 无网络消息 |
| TC-017 | | | ⬜ 待执行 | 所有 HTTP 状态码覆盖 |
| TC-018 | | | ⬜ 待执行 | GET 请求 |
| TC-019 | | | ⬜ 待执行 | POST 请求 |
| TC-020 | | | ⬜ 待执行 | PUT 请求 |
| TC-021 | | | ⬜ 待执行 | DELETE 请求 |
| TC-022 | | | ⬜ 待执行 | ApiResponse<User> 解析 |
| TC-023 | | | ⬜ 待执行 | 错误响应异常处理 |
| TC-024 | | | ⬜ 待执行 | 204/空响应处理 |
| TC-025 | | | ⬜ 待执行 | Token 刷新完整流程 |
| TC-026 | | | ⬜ 待执行 | AuthService 集成流程 |
| TC-027 | | | ⬜ 待执行 | SecureStorage 读写 |
| TC-028 | | | ⬜ 待执行 | baseUrl 非法输入 |
| TC-029 | | | ⬜ 待执行 | Token 特殊字符 |
| TC-030 | | | ⬜ 待执行 | dio 5.9.2 Duration API |

---

## 九、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| 基础配置测试 | 3 | TC-001 ~ TC-003 |
| AuthInterceptor 测试 | 6 | TC-004 ~ TC-009 |
| ErrorInterceptor 测试 | 8 | TC-010 ~ TC-017 |
| HTTP 方法测试 | 4 | TC-018 ~ TC-021 |
| 响应解析测试 | 3 | TC-022 ~ TC-024 |
| 集成场景测试 | 3 | TC-025 ~ TC-027 |
| 边界与负向测试 | 3 | TC-028 ~ TC-030 |
| **合计** | **30** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 12 |
| P1 — HIGH | 12 |
| P2 — MEDIUM | 6 |

---

## 十、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| `AuthInterceptor` Token 附加 ✅ | TC-004, TC-005 |
| `AuthInterceptor` 401 刷新 ✅ | TC-006, TC-007 |
| `AuthInterceptor` 刷新失败登出 ✅ | TC-008 |
| `ErrorInterceptor` 所有 HTTP 状态码映射正确 | TC-010 ~ TC-017 |
| `AuthService` login/register/refresh/logout 正常流程通过 | TC-026 |
| dio 5.9.2 Duration API 正确使用 | TC-001, TC-030 |
| `DioException` 类型（非旧 `DioError`） | TC-030 |
| 拦截器签名为新版 API | TC-002, TC-006 |
| Token 从 `flutter_secure_storage` 10.3.1 读取 | TC-027 |
| 无硬编码字符串（最终将迁移到 l10n） | TC-010 ~ TC-017（硬编码中文为临时接受） |

---

## 十一、附录：Mock 测试架构参考

> 以下架构建议供 sw-tom 开发时参考，确保测试可行性。

### A. AuthService 的 Mock / Fake 接口

为了使 AuthInterceptor 可测试，`AuthService` 应设计为可注入的抽象或提供 Fake 实现：

```dart
/// 推荐：AuthService 使用抽象接口
abstract class AuthService {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens(AuthTokens tokens);
  Future<void> clearTokens();
  Future<AuthTokens> refresh();
  Future<AuthTokens> login(String email, String password);
  Future<AuthTokens> register(String email, String password, String? username);
  Future<User> getMe();
  Future<void> logout();
}

/// 测试用 Fake
class FakeAuthService implements AuthService {
  String? _accessToken;
  String? _refreshToken;
  int _refreshCallCount = 0;
  bool _refreshSucceeds = true;

  int get refreshCallCount => _refreshCallCount;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<AuthTokens> refresh() async {
    _refreshCallCount++;
    if (!_refreshSucceeds) throw Exception('Refresh token expired');
    final newTokens = AuthTokens(
      accessToken: 'new-access-token',
      refreshToken: 'new-refresh-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
    );
    await saveTokens(newTokens);
    return newTokens;
  }
  // ... 其他方法
}
```

### B. Dio Mock 策略

推荐使用 `dio` 的 `HttpClientAdapter` 进行 Mock，而非 Mock Dio 本身：

```dart
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

/// 自定义 Adapter 用于 Mock HTTP 响应
class MockAdapter implements HttpClientAdapter {
  final Map<String, (int statusCode, Map<String, dynamic> body)> _routes;

  MockAdapter(this._routes);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.path;
    final method = options.method;
    final key = '$method $path';

    if (_routes.containsKey(key)) {
      final (statusCode, body) = _routes[key]!;
      return ResponseBody.fromString(
        jsonEncode(body),
        statusCode,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'code': 404, 'message': 'Not found', 'data': null}),
      404,
    );
  }

  @override
  void close({bool force = false}) {}
}
```

### C. 测试组织建议

```
kayak-frontend/test/
├── services/
│   ├── api_client_test.dart          # TC-001 ~ TC-003, TC-028 ~ TC-030
│   ├── auth_interceptor_test.dart    # TC-004 ~ TC-009
│   ├── auth_service_test.dart        # TC-025 ~ TC-027
│   ├── error_interceptor_test.dart   # TC-010 ~ TC-017
│   └── http_methods_test.dart        # TC-018 ~ TC-024
└── helpers/
    ├── fake_auth_service.dart        # FakeAuthService
    └── mock_http_adapter.dart        # MockAdapter
```

---

## 十二、后端风险点标记 🚨

| # | 风险点 | 描述 | 影响 |
|---|--------|------|------|
| **R1** | `POST /auth/refresh` 需要 request body 含 `refresh_token` | 后端 `TokenRefreshRequest` 使用 JSON body 中的 `refresh_token` 字段。前端必须在 refresh 调用中发送此字段 | 如果仅用 Authorization 头传 Refresh Token，refresh 将失败 |
| **R2** | `TokenResponse` 包含 `user` 子对象 | 后端 refresh/login 响应中 `data.user` 包含用户信息（id + email + username）。前端 `AuthTokens` 模型需包含 `user` 字段 | 如果 `AuthTokens` 未包含 `user` 字段，JSON 反序列化将失败（TASK-002 需覆盖） |
| **R3** | `expires_in` 单位为秒 | 后端 `expires_in` 为秒（数值如 3600），前端 Token 过期检测预留 5 分钟提前量时需注意单位 | 误将秒当毫秒处理将导致提前刷新时间计算错误 |
| **R4** | Web 平台 `flutter_secure_storage` 降级 | `flutter_secure_storage` 在 Web 上使用非安全存储，Token 可能被 XSS 获取 | Web 部署安全需要额外考虑 CSP 和 HTTPS |

---

**文档状态**: ✅ 已完成  
**下一步**: 提交 sw-tom 进行测试用例审查  
**总用例数**: 30  
**文件路径**: `log/release_3/test/TASK-003_test_cases.md`
