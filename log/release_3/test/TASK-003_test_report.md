# TASK-003 测试报告 — API Client + Dio 配置

> **测试工程师**: sw-mike  
> **测试日期**: 2026-05-31  
> **代码审查**: sw-jerry (一轮 NEEDS_FIX 3 High + 3 Medium + 5 Low → 二轮复审 PASS)  
> **分支**: feature/frontend-rewrite  
> **提交**: 7a1c6c4 (Sprint 1 基础设施合并)  
> **关联文档**: [tasks.md](../tasks.md) | [TASK-003_test_cases.md](TASK-003_test_cases.md) | [TASK-003_review_recheck.md](../review/TASK-003_review_recheck.md)

---

## 1. 测试概要

| 指标 | 值 |
|------|-----|
| **总测试用例** | 30 (TC-001 ~ TC-030) |
| **已验证用例** | 30 |
| **通过** | 30 |
| **失败** | 0 |
| **跳过** | 0 |
| **通过率** | **100%** |
| **flutter analyze** | ✅ 零警告 |
| **代码审查** | ✅ 6/11 issues fixed (3 High + 3 Medium) |

---

## 2. 交付物清单

| # | 文件 | 主要功能 | 行数 | 状态 |
|---|------|---------|:---:|:---:|
| 1 | `lib/services/api_client.dart` | Dio 实例 + BaseOptions + HTTP 方法封装 | ~70 | ✅ |
| 2 | `lib/services/auth_interceptor.dart` | Token 自动附加 + 401 刷新 + 并发锁 | ~200 | ✅ |
| 3 | `lib/services/error_interceptor.dart` | DioException → 用户可读错误消息映射 | ~56 | ✅ |
| 4 | `lib/services/token_storage.dart` | flutter_secure_storage Token 读写 | ~44 | ✅ |
| 5 | `lib/services/auth_service.dart` | 认证 Service (login/register/refresh/logout/getMe) | ~170 | ✅ |

---

## 3. 基础配置测试

### TC-001: ApiClient 创建成功，BaseOptions 配置正确

| 配置项 | 期望值 | 实际值 | 状态 |
|--------|--------|--------|:---:|
| `baseUrl` | `'http://localhost:8080/api/v1'` | ✅ 正确 | ✅ |
| `connectTimeout` | `Duration(seconds: 10)` | ✅ `const Duration(seconds: 10)` | ✅ |
| `receiveTimeout` | `Duration(seconds: 10)` | ✅ `const Duration(seconds: 10)` | ✅ |
| `Content-Type` | `'application/json'` | ✅ 正确 | ✅ |
| DioException 类型 | `DioException` (非旧 `DioError`) | ✅ | ✅ |

> ✅ dio 5.9.2 Duration API 正确使用——所有 timeout 参数均为 `Duration` 类型（非 `int`），`DioException` 类型正确。

### TC-002: Dio 拦截器数量与顺序正确

| 位置 | 拦截器 | 类型 | 状态 |
|:---:|--------|------|:---:|
| 0 | AuthInterceptor | Token 附加/401 刷新 | ✅ |
| 1 | ErrorInterceptor | HTTP 错误 → 用户消息 | ✅ |
| 2 | LogInterceptor | 请求/响应日志 | ✅ |

| 验证项 | 结果 |
|--------|:---:|
| 拦截器数量 = 3 | ✅ |
| AuthInterceptor 在最前面（优先处理） | ✅ |
| ErrorInterceptor 在 Auth 之后 | ✅ |
| LogInterceptor 在最外层 | ✅ |
| 顺序符合设计文档要求 | ✅ |

### TC-003: ApiClient 依赖注入 AuthService 正确

| 验证项 | 结果 |
|--------|:---:|
| `AuthInterceptor` 持有的 `authService` 与传入一致 | ✅ |
| `AuthInterceptor.onRequest` 从 `AuthService` 获取 Token | ✅ |
| `AuthService` 为 null 时构造防御性报错 | ✅ |
| 无硬编码 Token 或内部新建 AuthService | ✅ |

---

## 4. AuthInterceptor — Token 附加

### TC-004: 有 Token 时自动附加 Authorization: Bearer

| 验证项 | 结果 |
|--------|:---:|
| `Authorization: Bearer <valid-token>` 存在 | ✅ |
| 已有请求头（Content-Type）未覆盖 | ✅ |
| Token 前缀 `"Bearer "` 格式正确 | ✅ |
| Token 为空时不添加 Authorization 头 | ✅ |

### TC-005: 无 Token 时不添加 Authorization 头

| 验证项 | 结果 |
|--------|:---:|
| `getAccessToken()` 返回 null → 无 Authorization 头 | ✅ |
| `getAccessToken()` 返回空字符串 → 无 Authorization 头 | ✅ |
| 请求正常发送，无异常 | ✅ |
| Content-Type 等默认头保持正常 | ✅ |

---

## 5. AuthInterceptor — 401 刷新机制

### TC-006: 401 时自动调用 Refresh Token

| 步骤 | 预期 | 结果 |
|------|------|:---:|
| 请求受保护资源 → 返回 401 | AuthInterceptor.onError 触发 | ✅ |
| 检测 statusCode = 401 | 调用 `AuthService.refresh()` | ✅ |
| refresh 请求体 | `{"refresh_token": "<token>"}` | ✅ |
| refresh 调用次数 | 1 次（非递归死循环） | ✅ |
| refresh 请求不与自身拦截器冲突 | 绕过 AuthInterceptor | ✅ |

### TC-007: Refresh 成功后自动重试原请求

| 步骤 | 预期 | 结果 |
|------|------|:---:|
| 第 1 次请求 → 401 | 触发 refresh | ✅ |
| refresh 成功 → 新 Token 写入 | `saveTokens` 被调用 | ✅ |
| 重试请求 Authorization | `Bearer <new-access-token>` | ✅ |
| 最终响应 | 200 + 正确数据 | ✅ |
| 用户端无感知 | 透明处理 | ✅ |
| 原请求参数 (query/body) | 重试时保留 | ✅ |

### TC-008: Refresh 失败时清除 Token 并通知状态变更

| 步骤 | 预期 | 结果 |
|------|------|:---:|
| 401 → refresh → refresh 也失败 | `clearTokens()` 被调用 | ✅ |
| Access/Refresh Token | 双双清除 | ✅ |
| 认证状态变更通知 | 发出（上层可监听到） | ✅ |
| 异常信息 | 用户友好（"会话已过期"） | ✅ |
| 不会死循环 | refresh 失败后不再尝试 refresh | ✅ |

### TC-009: 并发 401 请求的刷新锁 (Token Refresh Lock)

| 验证项 | 预期 | 结果 |
|--------|------|:---:|
| 3 个请求同时返回 401 | `refresh()` 调用 1 次 | ✅ |
| 后续 2 个请求等待 | 等待 refresh 完成 | ✅ |
| 3 个请求最终 | 全部重试成功 (200) | ✅ |
| 无请求因"刷新中"直接失败 | 全部等待 | ✅ |
| 无死锁 | 超时/异常路径正确释放锁 | ✅ |

---

## 6. ErrorInterceptor — HTTP 状态码映射

### TC-010 ~ TC-017: 错误消息映射表

| TC | HTTP 状态码 / 异常类型 | 期望消息 | 结果 |
|:--:|--------|------|:---:|
| TC-010 | `400 Bad Request` | `'请求参数有误，请检查输入'` | ✅ |
| TC-011 | `401 Unauthorized` | `'登录已过期，请重新登录'` | ✅ |
| TC-012 | `403 Forbidden` | `'您没有权限执行此操作'` | ✅ |
| TC-013 | `404 Not Found` | `'请求的资源不存在或已被删除'` | ✅ |
| — | `409 Conflict` | `'资源冲突，可能已存在相同名称的记录'` | ✅ |
| — | `422 Unprocessable Entity` | `'数据验证失败，请检查输入'` | ✅ |
| TC-014 | `500 Internal Server Error` | `'服务器内部错误，请稍后重试'` | ✅ |
| — | `502 Bad Gateway` | `'服务器内部错误，请稍后重试'` | ✅ |
| — | `503 Service Unavailable` | `'服务器内部错误，请稍后重试'` | ✅ |
| TC-015 | `connectionTimeout` | `'连接超时，请检查网络'` | ✅ |
| TC-015 | `receiveTimeout` | `'连接超时，请检查网络'` | ✅ |
| TC-015 | `sendTimeout` | `'连接超时，请检查网络'` | ✅ |
| TC-016 | `connectionError` | `'网络错误，请检查连接'` | ✅ |
| TC-016 | `unknown` (网络异常) | `'网络错误，请检查连接'` | ✅ |
| TC-017 | 未映射状态码 (badResponse) | `'请求失败，服务器返回错误状态码'` | ✅ (issue #4 fixed) |

**全部 9 个 HTTP 状态码 + 5 个 DioExceptionType 的映射验证通过。**

---

## 7. HTTP 方法测试

### TC-018 ~ TC-021: HTTP 方法覆盖

| TC | 方法 | 验证点 | 结果 |
|:--:|:----:|------|:---:|
| TC-018 | **GET** | 200 + JSON 解析正确 | ✅ |
| TC-019 | **POST** | JSON Body 正确编码，Content-Type 正确 | ✅ |
| TC-020 | **PUT** | 请求方法 = PUT，Body 正确 | ✅ |
| TC-021 | **DELETE** | 请求方法 = DELETE，无 body | ✅ |
| — | **PATCH** | 请求方法 = PATCH (code review issue #9 fixed) | ✅ |

**全部 5 种 HTTP 方法验证通过。**

---

## 8. 响应解析测试

### TC-022: ApiResponse\<T\> 成功响应解析

| 验证项 | 结果 |
|--------|:---:|
| `ApiResponse<User>.fromJson()` 成功 | ✅ |
| `response.code` = 200 | ✅ |
| `response.data` 是 `User` 类型 (非 `dynamic`) | ✅ |
| `response.data.email` 正确 | ✅ |
| `timestamp` 正确解析 | ✅ |
| 泛型未丢失 | ✅ |

### TC-023: 错误响应正确抛出异常

| 验证项 | 结果 |
|--------|:---:|
| 400 响应 → 用户可读消息 | ✅ |
| 异常类型保留 `statusCode` | ✅ |
| 后端 `message` 可通过 response 访问 | ✅ |
| 不会因后端消息格式异常而二次崩溃 | ✅ |

### TC-024: 空响应 / 204 No Content 正确处理

| 场景 | 状态码 | Body | 结果 |
|------|:---:|------|:---:|
| A | 204 | 空 | ✅ data 为 null |
| B | 200 | `""` | ✅ 不抛 JSON 异常 |
| C | 200 | `"null"` | ✅ 解析为 null |

---

## 9. 集成场景测试

### TC-025: 完整 Token 刷新流程集成测试

| 步骤 | 描述 | 结果 |
|:---:|------|:---:|
| 1 | 发起请求 (带过期 Token) | ✅ |
| 2 | 后端返回 401 | ✅ |
| 3 | AuthInterceptor 触发 refresh | ✅ |
| 4 | Refresh 请求体 `{"refresh_token": "..."}` | ✅ |
| 5 | 重试原请求 (带新 Token) | ✅ |
| 6 | 后端返回 200 + 数据 | ✅ |
| 7 | 新 Token 持久化 | ✅ |

**全流程 7 步全部通过，用户无感知。**

### TC-026: AuthService 认证流程集成测试

| 操作 | 预期 | 结果 |
|------|------|:---:|
| `login()` | Token 存储 + 返回 AuthTokens | ✅ |
| `getMe()` | 返回 User | ✅ |
| `refresh()` | Token 更新 + 存储 | ✅ |
| `logout()` | 清除所有本地 Token | ✅ |
| 登录失败 | 抛出异常 (友好消息) | ✅ |

### TC-027: flutter_secure_storage 读写兼容性

| 操作 | 验证 | 结果 |
|------|------|:---:|
| `saveTokens(...)` | `read('access_token')` = 写入值 | ✅ |
| | `read('refresh_token')` = 写入值 | ✅ |
| | `read('token_type')` = `"Bearer"` | ✅ |
| | `read('expires_in')` = `"3600"` | ✅ |
| `clearTokens()` | 所有值 = null | ✅ |
| Web 平台 | 降级为 Local Storage 可用 | ✅ |

---

## 10. 边界与负向测试

### TC-028: baseUrl 非法输入处理

| 场景 | 预期 | 结果 |
|------|------|:---:|
| `baseUrl: 'localhost:8080'` (缺 scheme) | 构造/请求时报错 | ✅ |
| `baseUrl: ''` (空字符串) | Dio 抛出明确异常 | ✅ |
| `baseUrl: null` | 构造时尽早报错 | ✅ |

### TC-029: Token 特殊字符处理

| Token 内容 | 验证点 | 结果 |
|-----------|--------|:---:|
| 包含空格 `"abc def"` | 不被拆分为多行 | ✅ |
| 包含换行 `"line1\nline2"` | 无 HTTP 头注入 | ✅ |
| 包含中文 `"测试token123"` | 正常发出请求 | ✅ |

### TC-030: dio 5.9.2 Duration API 正确使用

| 检查项 | 结果 |
|--------|:---:|
| `connectTimeout` 为 `Duration` 类型 | ✅ |
| `receiveTimeout` 为 `Duration` 类型 | ✅ |
| 未使用旧 `DioError` 名称 | ✅ |
| `flutter analyze` 无类型错误 | ✅ |

---

## 11. 代码审查修复验证 (1st → 2nd Review)

> 代码审查 11 个问题中 7 个直接修复，4 个 Low 接受延迟。二轮复审 **PASS**。

| # | 问题 | 严重度 | 修复 | 复审 |
|---|------|:---:|------|:---:|
| 1 | `async void` 反模式 | **High** | ✅ `void → Future<void>` onError 签名 | ✅ |
| 2 | 每次 retry 创建新 `Dio()` | **High** | ✅ 注入共享 Dio 实例 + null 防御 | ✅ |
| 3 | 重试失败传递原始 401 错误 | **High** | ✅ 传递真实 `DioException` / 包装非 Dio 异常 | ✅ |
| 4 | badResponse 兜底消息不准确 | Medium | ✅ 改为 `'请求失败，服务器返回错误状态码'` | ✅ |
| 5 | `_retryWithNewToken` 重复代码 | Medium | ✅ 提取 `_retrySingleRequest` 方法 | ✅ |
| 6 | `tryRefresh()` 吞异常 | Medium | ✅ 添加 `print` 日志（标注后续接 logger） | ✅ |
| 7 | `_failAllPending` 无异常处理 | Low | ⬜ 接受延迟 | — |
| 8 | `BaseOptions` 重复定义 | Low | ⬜ 接受延迟 | — |
| 9 | 缺少 `patch` 方法 | Low | ✅ 已添加 | ✅ |
| 10 | `error_handler.dart` 未交付 | Low | ⬜ 接受延迟（已合并到 error_interceptor） | — |
| 11 | `_dio` 使用 `late final` | Low | ⬜ 接受延迟（当前无风险） | — |

---

## 12. 静态分析验证

| 属性 | 值 |
|------|-----|
| **命令** | `flutter analyze --fatal-infos` |
| **退出码** | 0 |
| **error** | 0 |
| **warning** | 0 |
| **结论** | ✅ **零警告、零错误** |

---

## 13. 测试执行记录

| ID | 类别 | 优先级 | 描述 | 结果 |
|----|------|:---:|------|:---:|
| TC-001 | 基础配置 | P0-CRITICAL | ApiClient 创建 + BaseOptions | ✅ PASS |
| TC-002 | 基础配置 | P0-CRITICAL | 拦截器数量与顺序 | ✅ PASS |
| TC-003 | 基础配置 | P1-HIGH | AuthService 依赖注入 | ✅ PASS |
| TC-004 | AuthIntcptr | P0-CRITICAL | Token 附加 Bearer | ✅ PASS |
| TC-005 | AuthIntcptr | P1-HIGH | 无 Token 不附加 | ✅ PASS |
| TC-006 | AuthIntcptr | P0-CRITICAL | 401 触发 Refresh | ✅ PASS |
| TC-007 | AuthIntcptr | P0-CRITICAL | Refresh 成功后重试 | ✅ PASS |
| TC-008 | AuthIntcptr | P0-CRITICAL | Refresh 失败清除 Token | ✅ PASS |
| TC-009 | AuthIntcptr | P1-HIGH | 并发 401 刷新锁 | ✅ PASS |
| TC-010 | ErrorIntcptr | P0-CRITICAL | 400 错误消息 | ✅ PASS |
| TC-011 | ErrorIntcptr | P0-CRITICAL | 401 错误消息 | ✅ PASS |
| TC-012 | ErrorIntcptr | P0-CRITICAL | 403 错误消息 | ✅ PASS |
| TC-013 | ErrorIntcptr | P0-CRITICAL | 404 错误消息 | ✅ PASS |
| TC-014 | ErrorIntcptr | P1-HIGH | 500 错误消息 | ✅ PASS |
| TC-015 | ErrorIntcptr | P1-HIGH | 连接超时消息 | ✅ PASS |
| TC-016 | ErrorIntcptr | P1-HIGH | 无网络消息 | ✅ PASS |
| TC-017 | ErrorIntcptr | P0-CRITICAL | 所有 HTTP 状态码覆盖 (9+5) | ✅ PASS |
| TC-018 | HTTP 方法 | P1-HIGH | GET 请求 | ✅ PASS |
| TC-019 | HTTP 方法 | P1-HIGH | POST 请求 | ✅ PASS |
| TC-020 | HTTP 方法 | P2-MEDIUM | PUT 请求 | ✅ PASS |
| TC-021 | HTTP 方法 | P2-MEDIUM | DELETE 请求 | ✅ PASS |
| TC-022 | 响应解析 | P0-CRITICAL | ApiResponse\<User\> 解析 | ✅ PASS |
| TC-023 | 响应解析 | P0-CRITICAL | 错误响应异常处理 | ✅ PASS |
| TC-024 | 响应解析 | P2-MEDIUM | 204/空响应处理 | ✅ PASS |
| TC-025 | 集成测试 | P0-CRITICAL | Token 刷新完整流程 | ✅ PASS |
| TC-026 | 集成测试 | P0-CRITICAL | AuthService 集成流程 | ✅ PASS |
| TC-027 | 集成测试 | P1-HIGH | SecureStorage 读写 | ✅ PASS |
| TC-028 | 边界 | P2-MEDIUM | baseUrl 非法输入 | ✅ PASS |
| TC-029 | 边界 | P2-MEDIUM | Token 特殊字符 | ✅ PASS |
| TC-030 | 版本兼容 | P0-CRITICAL | dio 5.9.2 Duration API | ✅ PASS |

---

## 14. 可追溯性矩阵

| 验收标准 (tasks.md) | 对应测试 | 结果 |
|-------------------|---------|:---:|
| `AuthInterceptor` Token 附加 ✅ | TC-004, TC-005 | ✅ |
| `AuthInterceptor` 401 刷新 ✅ | TC-006, TC-007 | ✅ |
| `AuthInterceptor` 刷新失败登出 ✅ | TC-008 | ✅ |
| `ErrorInterceptor` 所有 HTTP 状态码映射正确 | TC-010 ~ TC-017 | ✅ |
| `AuthService` login/register/refresh/logout 正常流程 | TC-026 | ✅ |
| dio 5.9.2 Duration API 正确使用 | TC-001, TC-030 | ✅ |
| `DioException` 类型（非旧 `DioError`） | TC-030 | ✅ |
| Token 从 `flutter_secure_storage` 10.3.1 读取 | TC-027 | ✅ |
| 拦截器签名为新版 API | TC-002 | ✅ |

---

## 15. 结论

| 判定 | **PASS** |
|------|:--------:|
| **通过测试数** | **30 / 30 (100%)** |
| **失败测试数** | 0 |
| **flutter analyze** | ✅ 零警告 |
| **代码审查** | ✅ 7/11 issues fixed (3 High + 3 Medium + 1 Low), 复审 PASS |
| **拦截器** | AuthInterceptor / ErrorInterceptor / LogInterceptor 全部就绪 |
| **Token 刷新** | 401 自动刷新 + 并发锁 + 刷新失败安全退出 |
| **HTTP 方法** | GET/POST/PUT/DELETE/PATCH 5 种全覆盖 |
| **错误映射** | 9 种 HTTP 状态码 + 5 种 DioExceptionType 全覆盖 |

**TASK-003 API Client + Dio 配置：测试全部通过，达到验收标准。**  
ApiClient 基础配置正确，拦截器注册顺序符合设计要求（Auth → Error → Log）。Token 刷新机制完整实现 401 自动刷新、并发锁、刷新失败安全退出。所有 HTTP 状态码和网络异常均映射为用户可读中文消息。代码审查中的 3 个 High + 3 个 Medium 问题已在提交 `7a1c6c4` 中正确修复。API 通信层已就绪，可安全进入 TASK-004（路由系统）。

---

> **下一步**: TASK-004 路由系统 (go_router 17.2.3)——测试用例见 [TASK-004_test_cases.md](TASK-004_test_cases.md)
