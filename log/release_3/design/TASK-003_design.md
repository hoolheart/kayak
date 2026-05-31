# TASK-003 详细设计 — API Client + Dio 配置

## 1. 概述

### 1.1 目标
基于 Dio 5.9.2 构建 `ApiClient`（HTTP 客户端），实现：
- Token 自动附加（`AuthInterceptor`）
- 401 自动刷新 Token（`AuthInterceptor` 并发锁）
- 统一错误处理（`ErrorInterceptor` 中文消息映射）
- Token 加密存储（`flutter_secure_storage` 10.3.1）
- 认证 Service（`AuthService`：login / register / refresh / logout / getMe）

### 1.2 依赖关系

```
TokenStorage (flutter_secure_storage 封装)
    ↑
AuthService (管理 Token，自身持有独立 Dio 用于认证 API)
    ↑
AuthInterceptor (从 AuthService 读取 Token，处理 401 刷新)
ErrorInterceptor (DioException → 中文错误消息)
    ↑
ApiClient (组合所有拦截器，业务 API 入口)
```

> **设计决策**: `AuthService` 持有独立的 Dio 实例（无 AuthInterceptor）用于认证端点调用（login/register/refresh/getMe），避免 `ApiClient` → `AuthInterceptor` → `AuthService` → `ApiClient` 的循环依赖。业务 API 通过 `ApiClient` 调用，自动携带 Token 并享受错误拦截。

### 1.3 后端 API 端点

| 方法 | 路径 | 用途 | 是否需要 Token |
|------|------|------|:---:|
| POST | `/api/v1/auth/login` | 登录 | ❌ |
| POST | `/api/v1/auth/register` | 注册 | ❌ |
| POST | `/api/v1/auth/refresh` | 刷新 Token | ❌（body 传 refresh_token） |
| GET | `/api/v1/auth/me` | 获取当前用户 | ✅ |

### 1.4 统一响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": { ... },
  "timestamp": "2026-05-31T10:30:00.000Z"
}
```

---

## 2. 类设计

### 2.1 TokenStorage

**职责**: 封装 `flutter_secure_storage`，提供 Token 的安全读写。

```
┌─────────────────────────────────┐
│          TokenStorage           │
├─────────────────────────────────┤
│ - _storage: FlutterSecureStorage│
├─────────────────────────────────┤
│ + saveTokens(access, refresh)   │
│ + getAccessToken(): String?     │
│ + getRefreshToken(): String?    │
│ + clearTokens()                 │
└─────────────────────────────────┘
```

- 使用 `flutter_secure_storage` 10.3.1 加密存储
- Key 命名: `access_token`, `refresh_token`
- Web 平台自动降级为 LocalStorage

### 2.2 ErrorInterceptor

**职责**: 拦截 `DioException`，将 HTTP 状态码和网络异常映射为用户可读的中文错误消息。

```
┌──────────────────────────────────┐
│          ErrorInterceptor        │
├──────────────────────────────────┤
│ (继承 Interceptor)               │
├──────────────────────────────────┤
│ + onError(err, handler)          │
│ - _mapError(err): String         │
└──────────────────────────────────┘
```

**消息映射表**:

| 条件 | 错误消息 |
|------|---------|
| HTTP 400 | `'请求参数有误，请检查输入'` |
| HTTP 401 | `'登录已过期，请重新登录'` |
| HTTP 403 | `'您没有权限执行此操作'` |
| HTTP 404 | `'请求的资源不存在或已被删除'` |
| HTTP 409 | `'资源冲突，可能已存在相同名称的记录'` |
| HTTP 422 | `'数据验证失败，请检查输入'` |
| HTTP 500/502/503 | `'服务器内部错误，请稍后重试'` |
| connectionTimeout / receiveTimeout / sendTimeout | `'连接超时，请检查网络'` |
| connectionError / unknown | `'网络错误，请检查连接'` |
| 其他未映射 | `'网络错误，请检查连接'`（兜底） |

### 2.3 AuthInterceptor

**职责**: 
1. `onRequest`: 自动附加 `Authorization: Bearer <token>` 请求头
2. `onError`: 检测 401 响应 → 并发锁 → 调用 `AuthService.tryRefresh()` → 刷新成功重试原请求 → 刷新失败清除 Token

```
┌───────────────────────────────────────┐
│           AuthInterceptor             │
├───────────────────────────────────────┤
│ - _authService: AuthService           │
│ - _isRefreshing: bool                 │
│ - _pendingRequests: List<PendingReq>  │
├───────────────────────────────────────┤
│ + onRequest(options, handler)         │
│ + onError(err, handler)               │
└───────────────────────────────────────┘
```

**401 刷新流程图**:

```
请求 → 服务器 401
    ↓
AuthInterceptor.onError
    ↓
请求路径包含 /auth/refresh? ──→ YES ──→ handler.next(err)，不处理
    ↓ NO
_isRefreshing = true? ──→ YES ──→ 加入 pending 队列，等待刷新完成
    ↓ NO
设置 _isRefreshing = true
    ↓
调用 _authService.tryRefresh()
    ↓
┌── 成功 ──→ 更新 Token → 重试原请求 + 重试 pending 队列 → handler.resolve
│
└── 失败 ──→ 调用 _authService.logout() → handler.next(err) → pending 全部 next(err)
    ↓
_isRefreshing = false, pending 队列清空
```

**并发锁说明**:
- 当第一个 401 触发刷新时，`_isRefreshing = true`
- 后续并发的 401 请求不触发新的刷新，而是加入 `_pendingRequests` 队列
- 刷新成功后，所有 pending 请求使用新 Token 依次重试
- 刷新失败后，所有 pending 请求和原请求都返回 401 错误

### 2.4 ApiClient

**职责**: Dio 实例的管理者和统一入口。

```
┌──────────────────────────────────┐
│            ApiClient             │
├──────────────────────────────────┤
│ - _dio: Dio                      │
├──────────────────────────────────┤
│ + get<T>(path, queryParameters)  │
│ + post<T>(path, data)            │
│ + put<T>(path, data)             │
│ + delete<T>(path)                │
└──────────────────────────────────┘
```

**BaseOptions 配置**:
```dart
BaseOptions(
  baseUrl: 'http://localhost:8080',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 10),
  headers: {'Content-Type': 'application/json'},
)
```

**拦截器顺序** (按注册顺序):
1. `AuthInterceptor` — 最先处理 Token 和 401 刷新
2. `ErrorInterceptor` — 在 Auth 之后处理错误映射
3. `LogInterceptor` — 最外层日志记录

### 2.5 AuthService

**职责**: 认证业务逻辑 + Token 生命周期管理。

```
┌────────────────────────────────────┐
│           AuthService              │
├────────────────────────────────────┤
│ - _authDio: Dio (独立，无拦截器)    │
│ - _storage: TokenStorage           │
│ - _accessToken: String?            │
│ - _refreshToken: String?           │
├────────────────────────────────────┤
│ + accessToken: String? (getter)    │
│ + initialize()                     │
│ + login(email, password): AuthTokens│
│ + register(email, password, name?) │
│ + tryRefresh(): bool               │
│ + getMe(): User                    │
│ + logout()                         │
└────────────────────────────────────┘
```

> **为什么 AuthService 使用独立 Dio**: 
> - 避免 `ApiClient` → `AuthInterceptor` → `AuthService` → `ApiClient` 的循环依赖
> - 认证端点无需 Token 或需要特殊处理（refresh 请求不能触发再次刷新）
> - `getMe()` 需要手动添加 Bearer Token，使用内存中的 `_accessToken`

---

## 3. 生命周期与构造顺序

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 创建 TokenStorage（无依赖）
  final tokenStorage = TokenStorage();
  
  // 2. 创建 AuthService（需要 TokenStorage + baseUrl）
  final authService = AuthService(
    baseUrl: 'http://localhost:8080',
    storage: tokenStorage,
  );
  await authService.initialize();
  
  // 3. 创建 ErrorInterceptor（无依赖）
  final errorInterceptor = ErrorInterceptor();
  
  // 4. 创建 AuthInterceptor（需要 AuthService）
  final authInterceptor = AuthInterceptor(authService);
  
  // 5. 创建 ApiClient（需要拦截器）
  final apiClient = ApiClient(
    baseUrl: 'http://localhost:8080',
    authInterceptor: authInterceptor,
    errorInterceptor: errorInterceptor,
  );
  
  // 6. 运行 App
  runApp(ProviderScope(child: KayakApp()));
}
```

---

## 4. 关键数据流

### 4.1 正常认证请求

```
用户操作 → Widget 点击登录
    → AuthService.login(email, password)
      → _authDio.post('/api/v1/auth/login', data)
        → 后端返回 200 + AuthTokens
      → 解析 ApiResponse<AuthTokens>
      → 更新内存 Token
      → TokenStorage.saveTokens()
    → 返回 AuthTokens
```

### 4.2 业务请求（带 Token）

```
Widget → ApiClient.get('/api/v1/workbenches')
    → _dio.get('/api/v1/workbenches')
      → AuthInterceptor.onRequest: 附加 Bearer Token
      → 后端返回 200
      → ErrorInterceptor: 无错误，直通
    → 返回 Response
```

### 4.3 Token 过期自动刷新

```
Widget → ApiClient.get('/api/v1/workbenches')
    → _dio.get(..., headers: {Authorization: Bearer expired-token})
    → 后端返回 401
      → AuthInterceptor.onError: 检测到 401
        → !_isRefreshing → 开始刷新
        → AuthService.tryRefresh()
          → _authDio.post('/api/v1/auth/refresh', {refresh_token: ...})
          → 后端返回 200 + 新 Token
          → 更新内存 + TokenStorage
        → 重试原请求（新 Token）
      → 后端返回 200 + 数据
    → Widget 收到正常响应（无感知）
```

### 4.4 并发 401 刷新锁

```
请求 A  → 401 → 触发 refresh (_isRefreshing = true)
请求 B  → 401 → _isRefreshing=true → 加入 pending 队列
请求 C  → 401 → _isRefreshing=true → 加入 pending 队列

refresh 完成 → 重试 A → 重试 B → 重试 C → 全部 resolve
```

---

## 5. 接口定义

### 5.1 ApiClient HTTP 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `get<T>` | `(String path, {Map<String, dynamic>? queryParameters}) → Future<Response<T>>` | GET 请求 |
| `post<T>` | `(String path, {dynamic data}) → Future<Response<T>>` | POST 请求 |
| `put<T>` | `(String path, {dynamic data}) → Future<Response<T>>` | PUT 请求 |
| `delete<T>` | `(String path) → Future<Response<T>>` | DELETE 请求 |

### 5.2 AuthService API

| 方法 | 签名 | 说明 |
|------|------|------|
| `initialize` | `() → Future<void>` | 从 TokenStorage 读取 Token 到内存 |
| `login` | `(String email, String password) → Future<AuthTokens>` | 登录 |
| `register` | `(String email, String password, String? username) → Future<AuthTokens>` | 注册 |
| `tryRefresh` | `() → Future<bool>` | 尝试刷新 Token，成功返回 true |
| `getMe` | `() → Future<User>` | 获取当前用户信息 |
| `logout` | `() → Future<void>` | 清除内存和存储中的 Token |

---

## 6. 文件清单

| # | 文件 | 包含 |
|---|------|------|
| 1 | `lib/services/token_storage.dart` | `TokenStorage` 类 |
| 2 | `lib/services/error_interceptor.dart` | `ErrorInterceptor` 类 |
| 3 | `lib/services/auth_interceptor.dart` | `AuthInterceptor` + `_PendingRequest` 类 |
| 4 | `lib/services/api_client.dart` | `ApiClient` 类 |
| 5 | `lib/services/auth_service.dart` | `AuthService` 类 |

---

## 7. 与测试用例的追溯

| 测试用例 | 测试内容 | 涉及类 | 设计要点 |
|---------|---------|--------|---------|
| TC-001 | ApiClient BaseOptions 配置 | ApiClient | Duration API, Content-Type |
| TC-002 | 拦截器数量与顺序 | ApiClient | Auth → Error → Log |
| TC-003 | AuthService 依赖注入 | ApiClient, AuthInterceptor | 构造时传入 AuthService |
| TC-004 | Token 附加 Bearer | AuthInterceptor | onRequest 检查 accessToken |
| TC-005 | 无 Token 不附加 | AuthInterceptor | null/空值时跳过 |
| TC-006 | 401 触发 Refresh | AuthInterceptor | onError 检测 401 |
| TC-007 | Refresh 成功重试 | AuthInterceptor | resolve + 重试 |
| TC-008 | Refresh 失败清除 Token | AuthInterceptor, AuthService | logout + 清除 |
| TC-009 | 并发刷新锁 | AuthInterceptor | _pendingRequests 队列 |
| TC-010~TC-017 | Error 映射 | ErrorInterceptor | 完整状态码覆盖 |
| TC-018~TC-021 | HTTP 方法 | ApiClient | GET/POST/PUT/DELETE |
| TC-022~TC-024 | 响应解析 | ApiClient | 泛型 + 空响应 |
| TC-025~TC-027 | 集成场景 | AuthService + 全部 | 完整流程 |
| TC-028~TC-030 | 边界/负向 | ApiClient | baseUrl 校验, Duration API |

---

## 8. 技术决策

| # | 决策 | 理由 |
|---|------|------|
| D1 | `AuthService` 使用独立 Dio | 避免循环依赖；认证端点不需要全部拦截器 |
| D2 | Token 双缓存（内存 + SecureStorage） | 内存用于快速读取，SecureStorage 用于持久化 |
| D3 | 并发刷新锁使用 `_isRefreshing` flag + `_pendingRequests` 队列 | 防止多个 401 同时触发多次刷新 |
| D4 | `ErrorInterceptor` 不覆盖原始 `DioException` 的类型和状态码 | 保留原始信息供上层更细粒度的判断 |
| D5 | 硬编码中文错误消息 | TASK-006（国际化）完成后迁移到 l10n ARB 文件 |
| D6 | Dio 5.9.2 Duration API | `connectTimeout: Duration(seconds: 10)` 非旧版 `int` 类型 |
| D7 | `DioException` 类型 | Dio 5.x 废弃 `DioError`，必须使用新类型 |
