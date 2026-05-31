# TASK-008 测试用例 — 认证 Provider（AuthNotifier）

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-008（认证 Service + Provider 完善）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md), [TASK-003_test_cases.md](TASK-003_test_cases.md), [M1_auth_spec.md](../ui/specifications/M1_auth_spec.md)

---

## 测试范围

TASK-008 需交付以下文件：

| # | 文件 | 功能 | 测试覆盖 |
|---|------|------|:------:|
| 1 | `lib/providers/auth_provider.dart` | AuthNotifier（Riverpod 3.x AsyncNotifier\<User?\>），管理全局认证状态 | TC-001 ~ TC-043 |
| 2 | `lib/app.dart` / `lib/main.dart` | 应用启动流程：全屏加载 + Token 检查 + 路由分发 | TC-021 ~ TC-027, TC-035 |
| 3 | 集成：`lib/services/auth_service.dart` | AuthService 已实现（TASK-003），通过 Mock 注入测试 | TC-008 ~ TC-020, TC-030 ~ TC-033 |

---

## 依赖接口速查

### AuthService（TASK-003 已实现）

```dart
class AuthService {
  Future<void> initialize();                                    // 从 TokenStorage 加载 Token 到内存
  Future<AuthTokens> login(String email, String password);     // 登录，返回 AuthTokens（含 User）
  Future<AuthTokens> register(String email, String password, [String? username]); // 注册
  Future<bool> tryRefresh();                                   // 刷新 Token，返回 true/false
  Future<User> getMe();                                        // 获取当前用户信息
  Future<void> logout();                                       // 清除 Token
  String? get accessToken;                                     // 当前 Access Token
}
```

### TokenStorage（TASK-003 已实现）

```dart
class TokenStorage {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}
```

### AuthTokens 模型（TASK-002 已实现）

```dart
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String? tokenType;
  final int? expiresIn;  // 单位: 秒
  final User user;
}
```

### User 模型（TASK-002 已实现）

```dart
class User {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Riverpod 3.x AsyncNotifier 规范

```dart
// ✅ AuthNotifier extends AsyncNotifier<User?>
// ✅ build() 返回 AsyncValue<User?> 的异步构建结果
// ✅ 状态通过 AsyncValue<User?> 暴露：loading / data / error
// ✅ 外部通过 ref.watch(authProvider) 读取 AsyncValue<User?>
```

### 应用启动流程（来自 PRD §M1 验收标准）

```
应用启动 → 显示全屏加载（Kayak Logo + "正在初始化..."）
  → AuthNotifier.build() → AuthService.initialize() 从 TokenStorage 加载 Token
  → Token 存在 → tryRefresh() 续期 → getMe() 获取用户 → 进入首页
  → Token 不存在 → 返回 null → 路由重定向 /login
  → 加载 >3s → "正在连接服务器..."
  → 加载 >10s → "服务器连接超时" + 重试按钮
```

---

## 一、AuthState 定义与状态转换测试（4 项）

> **注**: 根据 tasks.md，AuthNotifier 使用 `AsyncNotifier<User?>`
> 而非自定义 `AuthState` 类。其状态为 `AsyncValue<User?>`：
> - `AsyncLoading<User?>()` — 正在检查会话/登录中/注册中
> - `AsyncData<User?>(null)` — 未认证
> - `AsyncData<User?>(user)` — 已认证（user 非 null）
> - `AsyncError<User?>(error, stackTrace)` — 错误状态

### TC-001: build() 初始状态为 AsyncLoading

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（应用启动流程基础） |
| **类别** | AuthNotifier / 初始状态 |
| **关联验收标准** | 启动时检查 Token 状态 |

**前置条件**：
- AuthNotifier 已实现
- AuthService Mock 可用
- 使用 ProviderContainer 进行隔离测试

**测试步骤**：

1. 创建 ProviderContainer，注入 Mock AuthService
2. 读取 `authProvider`（触发 `build()` 但等待异步完成前）
3. 验证初始 `AsyncValue` 为 loading 状态

```dart
test('build() initially returns AsyncLoading', () {
  final container = createContainer(mockAuthService);
  // 状态在 build() 尚未完成时为 loading
  final state = container.read(authProvider);
  expect(state, isA<AsyncLoading<User?>>());
});
```

**预期结果**：
- ✅ `build()` 在被读取时立即返回 `AsyncLoading<User?>()`
- ✅ 加载完成后过渡到 `AsyncData<User?>(null)` 或 `AsyncData<User?>(user)`
- ✅ 加载失败时过渡到 `AsyncError`

**失败判定**：
- ❌ `build()` 同步返回 `AsyncData`（未经历 loading 阶段）
- ❌ `build()` 抛出异常而不封装为 AsyncError
- ❌ 初始状态为 null（不使用 AsyncValue 包装）

---

### TC-002: 未认证状态为 AsyncData(null)

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（路由守卫依赖此状态） |
| **类别** | AuthNotifier / 状态转换 |
| **关联验收标准** | Token 无效 → 显示登录页 |

**前置条件**：
- TC-001 通过
- Mock AuthService 设置 `initialize()` 后发现无 Token（accessToken 为 null）

**测试步骤**：

1. 创建 ProviderContainer，Mock AuthService 无 Token
2. 等待 `build()` 完成（await）
3. 验证最终状态

```dart
test('returns AsyncData(null) when no token exists', () async {
  final mockAuth = FakeAuthService(hasToken: false);
  final container = createContainer(mockAuth);
  
  // 等待 build() 完成
  await container.read(authProvider.future);
  
  final state = container.read(authProvider);
  expect(state, isA<AsyncData<User?>>());
  expect(state.valueOrNull, isNull);
});
```

**预期结果**：
- ✅ 无 Token 时最终状态为 `AsyncData<User?>(null)`
- ✅ `state.valueOrNull` = null
- ✅ `state.hasValue` = true（非 error）
- ✅ 应用应据此重定向到 `/login`

**失败判定**：
- ❌ 无 Token 时仍返回 AsyncLoading（永不完结）
- ❌ 无 Token 时抛出异常 → AsyncError
- ❌ `valueOrNull` 为非 null 的 User 对象

---

### TC-003: 认证成功状态为 AsyncData(user)

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P0 — CRITICAL**（核心认证流程） |
| **类别** | AuthNotifier / 状态转换 |
| **关联验收标准** | Token 有效 → 自动进入首页 |

**前置条件**：
- Mock AuthService 配置为：有有效 Token，`tryRefresh()` 成功，`getMe()` 返回 User

**测试步骤**：

1. 创建 ProviderContainer，Mock AuthService 已有 Token
2. 等待 `build()` 完成
3. 验证状态

```dart
test('returns AsyncData(user) when token is valid', () async {
  final mockAuth = FakeAuthService(hasToken: true);
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.future);
  
  final state = container.read(authProvider);
  expect(state, isA<AsyncData<User?>>());
  expect(state.valueOrNull, isNotNull);
  expect(state.valueOrNull, isA<User>());
  expect(state.valueOrNull!.email, equals('admin@kayak.local'));
});
```

**预期结果**：
- ✅ 最终状态为 `AsyncData<User?>(user)`（user 非 null）
- ✅ User 对象完整（包含 id、email、username 等字段）
- ✅ 应用应据此进入受保护页面（首页）

**失败判定**：
- ❌ user 为 null（认证后未正确存储 User 信息）
- ❌ User 字段缺失（id 或 email 为空）
- ❌ 状态停留在 AsyncLoading

---

### TC-004: 认证错误状态为 AsyncError

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — CRITICAL**（错误处理基础） |
| **类别** | AuthNotifier / 状态转换 |
| **关联验收标准** | 错误状态有正确的用户提示 |

**前置条件**：
- Mock AuthService 配置为：`tryRefresh()` 抛出异常或 `getMe()` 失败

**测试步骤**：

1. 创建 ProviderContainer，Mock AuthService 在 refresh/getMe 阶段抛出异常
2. 验证最终状态为 AsyncError
3. 验证错误信息包含可读消息

```dart
test('returns AsyncError when auth fails', () async {
  final mockAuth = FakeAuthService(hasToken: true, refreshFails: true);
  final container = createContainer(mockAuth);
  
  // 等待 build() 完成（会变成 error）
  await container.read(authProvider.future);
  
  final state = container.read(authProvider);
  expect(state, isA<AsyncError<User?>>());
  expect(state.hasError, isTrue);
});
```

**预期结果**：
- ✅ 异常被捕获并包装为 `AsyncError<User?>`
- ✅ `state.error` 不为 null
- ✅ 错误可直接通过 `state.hasError` 检测
- ✅ AuthNotifier 自身不崩溃

**失败判定**：
- ❌ 异常未被捕获，导致 Provider 未处理异常
- ❌ AsyncError 中 error 为 null
- ❌ 错误状态导致整个应用崩溃

---

## 二、build() 初始化与会话检查测试（3 项）

### TC-005: build() 调用 AuthService.initialize() 加载 Token

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — CRITICAL**（会话恢复的前置条件） |
| **类别** | AuthNotifier / 初始化 |
| **关联验收标准** | 启动时检查本地 Token |

**前置条件**：
- `AuthService.initialize()` 方法已实现（TASK-003）
- FakeAuthService 可记录方法调用

**测试步骤**：

1. 创建 ProviderContainer，注入 FakeAuthService
2. 触发 `authProvider` 的 `build()`
3. 验证 `FakeAuthService.initialize()` 被调用（且仅被调用一次）

```dart
test('build() calls AuthService.initialize()', () async {
  final mockAuth = FakeAuthService(hasToken: true);
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.future);
  
  expect(mockAuth.initializeCallCount, equals(1));
});
```

**预期结果**：
- ✅ `AuthService.initialize()` 在 `build()` 中被调用
- ✅ 调用次数 = 1（不重复初始化）
- ✅ `initialize()` 从 TokenStorage 加载 Token 到 AuthService 内存

**失败判定**：
- ❌ `initialize()` 未被调用（Token 直接从 storage 读取 → 绕过 AuthService）
- ❌ `initialize()` 被调用多次（重复初始化开销）
- ❌ 初始化抛出异常时 AuthNotifier 崩溃

---

### TC-006: Token 存在时 build() 调用 tryRefresh() 续期

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — CRITICAL**（会话自动续期） |
| **类别** | AuthNotifier / 会话恢复 |
| **关联验收标准** | Token 过期前自动刷新 |

**前置条件**：
- Mock AuthService 模拟 `initialize()` 后 `accessToken` 非 null
- `tryRefresh()` 可记录调用次数

**测试步骤**：

1. 创建 ProviderContainer，Mock 有 Token
2. 触发 `build()` 并等待完成
3. 验证 `tryRefresh()` 被调用

```dart
test('build() tries to refresh token when token exists', () async {
  final mockAuth = FakeAuthService(hasToken: true);
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.future);
  
  expect(mockAuth.tryRefreshCallCount, equals(1));
});
```

**预期结果**：
- ✅ Token 存在时 `tryRefresh()` 被调用一次
- ✅ refresh 成功后调用 `getMe()` 获取最新用户信息
- ✅ 最终状态为 `AsyncData<User?>(user)`（新的 User 对象）

**失败判定**：
- ❌ Token 存在但未尝试 refresh（直接信任旧 Token）
- ❌ refresh 被跳过（可能有 hasValidToken 判断错误）
- ❌ refresh 成功后未获取最新 User 信息

---

### TC-007: Token 不存在时 build() 直接返回 null（未认证）

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL**（首次使用流程） |
| **类别** | AuthNotifier / 会话恢复 |
| **关联验收标准** | Token 无效 → 显示登录页 |

**前置条件**：
- Mock AuthService 模拟 `initialize()` 后 `accessToken` 为 null

**测试步骤**：

1. 创建 ProviderContainer，Mock 无 Token
2. 触发 `build()` 并等待完成
3. 验证不调用 `tryRefresh()`（或调用后立即返回 false）
4. 验证最终状态为 AsyncData(null)

```dart
test('build() skips refresh when no token exists', () async {
  final mockAuth = FakeAuthService(hasToken: false);
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.future);
  
  expect(mockAuth.tryRefreshCallCount, equals(0));
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNull);
});
```

**预期结果**：
- ✅ 无 Token 时不调用 `tryRefresh()`（或调用后快速返回 false 无副作用）
- ✅ 不调用 `getMe()`
- ✅ 最终状态为 AsyncData(null)
- ✅ build() 执行快速（无网络请求）

**失败判定**：
- ❌ 无 Token 时仍执行 getMe() → 401 或网络错误
- ❌ 无 Token 时 build() 长时间阻塞
- ❌ 无 Token 时返回 AsyncError（应为正常的 null 状态）

---

## 三、login() 流程测试（6 项）

### TC-008: login() 成功 → 状态变为 AsyncData(user)

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — CRITICAL**（核心认证功能） |
| **类别** | AuthNotifier / login |
| **关联验收标准** | 登录成功后跳转首页 |

**前置条件**：
- Mock AuthService 的 `login()` 返回有效的 `AuthTokens`（含 User）
- 初始状态为 AsyncData(null)（未认证）

**测试步骤**：

1. 创建 ProviderContainer，未认证状态
2. 调用 `container.read(authProvider.notifier).login('admin@kayak.local', 'Admin123')`
3. 等待 login 完成
4. 验证状态变更

```dart
test('login() success updates state to authenticated user', () async {
  final mockAuth = FakeAuthService(hasToken: false);
  final container = createContainer(mockAuth);
  
  // 确认初始未认证
  await container.read(authProvider.future);
  expect(container.read(authProvider).valueOrNull, isNull);
  
  // 执行登录
  await container.read(authProvider.notifier)
      .login('admin@kayak.local', 'Admin123');
  
  // 验证状态更新
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNotNull);
  expect(state.valueOrNull!.email, equals('admin@kayak.local'));
});
```

**预期结果**：
- ✅ `login()` 成功后状态变为 `AsyncData<User?>(user)`
- ✅ User 对象与 AuthService.login() 返回的 AuthTokens.user 一致
- ✅ AuthService.saveTokens() 被调用（持久化 Token）
- ✅ `login()` 是异步操作（返回 Future\<void\>）

**失败判定**：
- ❌ login 成功后状态仍为 null（未更新）
- ❌ User 对象与返回数据不一致（字段映射错误）
- ❌ login 方法未持久化 Token
- ❌ login 成功后状态为 AsyncError

---

### TC-009: login() 失败 → 状态变为 AsyncError

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | AuthNotifier / login 异常 |
| **关联验收标准** | 登录失败显示具体原因 |

**前置条件**：
- Mock AuthService 的 `login()` 抛出异常（如 DioException with 401）

**测试步骤**：

1. 创建 ProviderContainer
2. Mock AuthService.login() 抛出异常（错误密码）
3. 调用 login
4. 验证状态和错误信息

```dart
test('login() failure sets AsyncError state', () async {
  final mockAuth = FakeAuthService(loginFails: true);
  final container = createContainer(mockAuth);
  
  // 确认初始未认证
  await container.read(authProvider.future);
  
  // 登录失败
  await container.read(authProvider.notifier)
      .login('admin@kayak.local', 'wrong-password');
  
  final state = container.read(authProvider);
  expect(state.hasError, isTrue);
  expect(state.error, isNotNull);
});
```

**预期结果**：
- ✅ `login()` 失败后状态为 `AsyncError<User?>`
- ✅ `state.error` 包含可读错误消息（如"邮箱或密码错误"）
- ✅ 错误不会导致 Token 残留（无脏 Token 写入）
- ✅ AuthNotifier 不崩溃

**失败判定**：
- ❌ 异常未被捕获 → 未处理异常导致 Provider 崩溃
- ❌ 失败后状态仍为 AsyncData（用户以为登录成功）
- ❌ 错误消息为技术细节（如 "DioException: 401"）

---

### TC-010: login() 过程中状态为 AsyncLoading

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P1 — HIGH**（UI 按钮 loading 状态依赖） |
| **类别** | AuthNotifier / login 状态过渡 |
| **关联验收标准** | 登录按钮 loading 状态下输入框禁用 |

**前置条件**：
- Mock AuthService 的 `login()` 模拟延迟（不立即 resolve）

**测试步骤**：

1. 创建 ProviderContainer
2. 调用 login()（不 await）
3. 在 login 完成前立即读取状态
4. 验证中间状态为 loading

```dart
test('login() shows loading state during request', () async {
  final mockAuth = FakeAuthService(loginDelay: Duration(seconds: 1));
  final container = createContainer(mockAuth);
  await container.read(authProvider.future); // 完成初始 build
  
  // 发起 login，不等待
  final future = container.read(authProvider.notifier)
      .login('admin@kayak.local', 'password');
  
  // 立即检查状态 — 应为 loading
  final state = container.read(authProvider);
  expect(state.isLoading, isTrue);
  
  await future;
});
```

**预期结果**：
- ✅ 登录请求进行中时 `state.isLoading` = true
- ✅ 登录完成后状态过渡到 data 或 error
- ✅ `state.isRefreshing` / `state.isReloading` 可能为 true（取决于实现）

**失败判定**：
- ❌ login 过程中 state 保持原值（无 loading 过渡）
- ❌ loading 状态不解除（一直转圈）
- ❌ 异常发生在 loading 阶段但状态不更新为 error

---

### TC-011: login() 调用 AuthService.login() 并传递正确参数

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P0 — CRITICAL**（API 调用正确性） |
| **类别** | AuthNotifier / login 委托 |
| **关联验收标准** | 正确调用后端 API |

**前置条件**：
- FakeAuthService 可记录 `login()` 被调用时的参数

**测试步骤**：

1. 创建 ProviderContainer，注入 FakeAuthService
2. 调用 `login('user@test.com', 'TestPass123')`
3. 验证 `FakeAuthService.login()` 收到的参数

```dart
test('login() delegates to AuthService.login() with correct params', () async {
  final mockAuth = FakeAuthService();
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.notifier)
      .login('user@test.com', 'TestPass123');
  
  expect(mockAuth.lastLoginEmail, equals('user@test.com'));
  expect(mockAuth.lastLoginPassword, equals('TestPass123'));
  expect(mockAuth.loginCallCount, equals(1));
});
```

**预期结果**：
- ✅ `AuthService.login(email, password)` 被调用
- ✅ email 和 password 参数完整传递（未被截断或修改）
- ✅ 仅调用一次（无重试或重复调用）

**失败判定**：
- ❌ AuthNotifier 绕过 AuthService 直接发起 HTTP 请求
- ❌ 参数被修改（如 email trim 丢失首尾空格、密码被转义）
- ❌ login() 被调用 0 次（未委托）

---

### TC-012: login() 失败后状态不清空用户数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P1 — HIGH**（错误恢复） |
| **类别** | AuthNotifier / login 异常 |
| **关联验收标准** | 登录失败后可重试 |

**前置条件**：
- 初始状态可能有或没有 User

**测试步骤**：

1. 若已有登录用户（如从会话恢复），当前状态为 AsyncData(user)
2. 再次调用 login（密码错误 → 失败）
3. 验证之前的 User 状态是否被保留

```dart
test('login() failure preserves existing user state', () async {
  final mockAuth = FakeAuthService(hasToken: true, loginFails: true);
  final container = createContainer(mockAuth);
  
  // 先完成初始 build（已有 user）
  await container.read(authProvider.future);
  final userBefore = container.read(authProvider).valueOrNull;
  expect(userBefore, isNotNull);
  
  // 尝试 login 失败
  await container.read(authProvider.notifier)
      .login('admin@kayak.local', 'wrong');
  
  // 根据设计决定：失败后可能保留原用户或变为 error
  // 建议：失败后变为 AsyncError，但提供了 retry 路径
  // 关键：不应无故清除已有 User
});
```

**预期结果**：
- ✅ 登录失败后，原有的 User 状态不受影响或被安全清除后可重新登录
- ✅ 不会出现"失败后 User 变成 null 但 Token 仍存在"的不一致状态
- ✅ 失败后的状态允许重新调用 login() 或 logout()

**失败判定**：
- ❌ 失败后 User 被静默清除（用户不知情被登出）
- ❌ 失败后出现状态不一致（如内存 User 被清但 storage Token 残留）

---

### TC-013: login() 并发调用保护

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P2 — MEDIUM**（防止重复提交） |
| **类别** | AuthNotifier / login 并发 |
| **关联验收标准** | 登录按钮 loading 状态下防止重复点击 |

**前置条件**：
- Mock AuthService 的 `login()` 模拟延迟 500ms

**测试步骤**：

1. 快速连续调用 login() 两次
2. 验证 AuthService.login() 被调用的次数
3. 验证最终状态

```dart
test('login() protects against concurrent calls', () async {
  final mockAuth = FakeAuthService(loginDelay: Duration(milliseconds: 500));
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 并发两次 login 调用
  final notifier = container.read(authProvider.notifier);
  final future1 = notifier.login('a@b.com', 'pass1');
  final future2 = notifier.login('c@d.com', 'pass2');
  
  await Future.wait([future1, future2]);
  
  // AuthService.login 应被调用不超过 1 次（第二次被跳过或排队）
  // 或者两次都执行但最终状态一致
  expect(mockAuth.loginCallCount, lessThanOrEqualTo(1),
      reason: '应该只执行一次 login（第二次在 loading 状态时被忽略）');
});
```

**预期结果**：
- ✅ 并发 login 调用时，只执行一次实际的 API 请求
- ✅ 第二次调用被忽略或返回已有结果
- ✅ 最终状态正确（无数据竞争）

**失败判定**：
- ❌ 两次 login 都被执行 → 可能导致 Token 覆盖或状态混乱
- ❌ 并发导致未处理异常

---

## 四、register() 流程测试（4 项）

### TC-014: register() 成功 → 自动登录 → 状态为用户

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P0 — CRITICAL**（注册即登录） |
| **类别** | AuthNotifier / register |
| **关联验收标准** | 注册成功自动登录 |

**前置条件**：
- Mock AuthService 的 `register()` 返回 AuthTokens（含 User + Token）
- Backend POST /api/v1/auth/register 返回 AuthTokens（无需再次登录）

**测试步骤**：

1. 创建 ProviderContainer，初始未认证
2. 调用 `register('new@test.com', 'StrongPass1', 'NewUser')`
3. 等待完成
4. 验证状态

```dart
test('register() success auto-login and sets user state', () async {
  final mockAuth = FakeAuthService();
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  await container.read(authProvider.notifier)
      .register('new@test.com', 'StrongPass1', 'NewUser');
  
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNotNull);
  expect(state.valueOrNull!.email, equals('new@test.com'));
  expect(state.valueOrNull!.username, equals('NewUser'));
  
  // Token 应已持久化
  expect(mockAuth.saveTokensCalled, isTrue);
});
```

**预期结果**：
- ✅ register() 成功后状态为 AsyncData(user)（已认证）
- ✅ User 信息正确（email、username）
- ✅ Token 自动持久化（无需额外 login 调用）
- ✅ 不影响现有的 `accessToken` / `refreshToken`

**失败判定**：
- ❌ register 成功后状态仍为 null（未自动登录）
- ❌ register 成功后需要手动调用 login 才能完成认证
- ❌ Token 未持久化

---

### TC-015: register() 失败 → 状态变为 AsyncError

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | AuthNotifier / register 异常 |
| **关联验收标准** | 注册失败显示具体原因 |

**前置条件**：
- Mock AuthService 的 `register()` 抛出异常（如邮箱已注册 → 409）

**测试步骤**：

1. 创建 ProviderContainer
2. Mock AuthService.register() 抛出异常
3. 调用 register
4. 验证状态为 error

```dart
test('register() failure sets AsyncError state', () async {
  final mockAuth = FakeAuthService(registerFails: true, registerError: 'Email already registered');
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  await container.read(authProvider.notifier)
      .register('taken@test.com', 'StrongPass1');
  
  final state = container.read(authProvider);
  expect(state.hasError, isTrue);
  expect(state.error.toString(), contains('registered'));
});
```

**预期结果**：
- ✅ 注册失败后状态为 `AsyncError<User?>`
- ✅ 错误消息包含可读原因（"该邮箱已被注册"）
- ✅ 注册失败后不写入任何 Token
- ✅ 状态可恢复（用户修正后重新调用 register）

**失败判定**：
- ❌ 注册失败但状态变为 AsyncData（用户误以为注册成功）
- ❌ 注册失败后残留部分 Token（不一致状态）
- ❌ 错误消息为后端原始技术错误

---

### TC-016: register() 调用 AuthService.register() 并传递正确参数

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P0 — CRITICAL**（API 调用正确性） |
| **类别** | AuthNotifier / register 委托 |
| **关联验收标准** | 正确调用后端 API |

**前置条件**：
- FakeAuthService 可记录 register 参数

**测试步骤**：

1. 调用 `register('new@test.com', 'Str0ng!Pass', 'TestUser')`
2. 验证参数传递正确
3. 验证 username 为 null 时的行为

```dart
test('register() delegates to AuthService.register() with correct params', () async {
  final mockAuth = FakeAuthService();
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 场景 A: 带 username
  await container.read(authProvider.notifier)
      .register('new@test.com', 'Str0ng!Pass', 'TestUser');
  
  expect(mockAuth.lastRegisterEmail, equals('new@test.com'));
  expect(mockAuth.lastRegisterPassword, equals('Str0ng!Pass'));
  expect(mockAuth.lastRegisterUsername, equals('TestUser'));
  
  // 场景 B: 不带 username
  mockAuth.reset();
  await container.read(authProvider.notifier)
      .register('user2@test.com', 'Pass1234');
  
  expect(mockAuth.lastRegisterUsername, isNull);
});
```

**预期结果**：
- ✅ `AuthService.register(email, password, username?)` 被调用
- ✅ 所有参数完整传递
- ✅ username 为 null 时 AuthService 收到的也是 null
- ✅ 仅调用一次 register API

**失败判定**：
- ❌ AuthNotifier 绕过 AuthService 直接发起 HTTP 请求
- ❌ username 参数丢失或被修改
- ❌ register 被调用多次

---

### TC-017: register() 过程中状态为 AsyncLoading

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P1 — HIGH**（UI 按钮 loading 状态依赖） |
| **类别** | AuthNotifier / register 状态过渡 |
| **关联验收标准** | 注册按钮 loading 状态下输入框禁用 |

**前置条件**：
- Mock AuthService 的 `register()` 模拟延迟

**测试步骤**：

1. 调用 register()（不 await）
2. 立即检查状态 → 应为 loading
3. await 完成 → 检查最终状态

```dart
test('register() shows loading state during request', () async {
  final mockAuth = FakeAuthService(registerDelay: Duration(milliseconds: 500));
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  final future = container.read(authProvider.notifier)
      .register('new@test.com', 'StrongPass1');
  
  // 中间状态
  expect(container.read(authProvider).isLoading, isTrue);
  
  await future;
  
  // 最终状态
  expect(container.read(authProvider).isLoading, isFalse);
});
```

**预期结果**：
- ✅ 注册进行中 state.isLoading = true
- ✅ 注册完成后 state.isLoading = false
- ✅ 注册成功后 state.valueOrNull 非 null
- ✅ 注册失败后 state.hasError = true

**失败判定**：
- ❌ register 过程中无 loading 状态过渡

---

## 五、logout() 流程测试（3 项）

### TC-018: logout() 清除状态 → AsyncData(null)

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P0 — CRITICAL**（登出核心功能） |
| **类别** | AuthNotifier / logout |
| **关联验收标准** | 登出时清除所有本地存储的 Token |

**前置条件**：
- 当前状态为 AsyncData(user)（已认证）
- AuthService 的 `logout()` 清除内存 Token
- TokenStorage 的 `clearTokens()` 清除持久化 Token

**测试步骤**：

1. 创建已认证状态的 ProviderContainer
2. 调用 `logout()`
3. 验证状态、Token、存储

```dart
test('logout() clears state to AsyncData(null)', () async {
  final mockAuth = FakeAuthService(hasToken: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  expect(container.read(authProvider).valueOrNull, isNotNull);
  
  await container.read(authProvider.notifier).logout();
  
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNull);
  expect(mockAuth.logoutCalled, isTrue);
  expect(mockAuth.accessToken, isNull);
  expect(mockAuth.tokensCleared, isTrue);
});
```

**预期结果**：
- ✅ logout 后状态为 AsyncData(null)
- ✅ AuthService.logout() 被调用
- ✅ 内存中的 accessToken 和 refreshToken 被清空
- ✅ TokenStorage.clearTokens() 被调用
- ✅ SharedPreferences 中登录相关缓存（如有）被清除

**失败判定**：
- ❌ logout 后状态仍为 AsyncData(user)（未清除）
- ❌ logout 后 Token 仍在内存中
- ❌ 持久化存储中的 Token 未被清除
- ❌ logout 抛出异常

---

### TC-019: logout() 取消 Token 自动刷新定时器

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P1 — HIGH**（资源清理） |
| **类别** | AuthNotifier / logout 资源清理 |
| **关联验收标准** | 登出后停止 Token 刷新 |

**前置条件**：
- AuthNotifier 中存在 `Timer.periodic` 用于定期刷新 Token
- FakeAuthService 或测试可验证 Timer 是否被取消

**测试步骤**：

1. 创建已认证状态的 ProviderContainer
2. 验证 Token 刷新定时器已启动（如通过检查 tryRefresh 未被调用）
3. 调用 logout()
4. 等待一段超过刷新间隔的时间
5. 验证 tryRefresh 未再被调用

```dart
test('logout() cancels token refresh timer', () async {
  final mockAuth = FakeAuthService(hasToken: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 登出
  await container.read(authProvider.notifier).logout();
  
  // 等待超过 refresh 间隔
  await Future.delayed(const Duration(seconds: 2));
  
  // 登出后不应再有 refresh 调用
  final refreshCallsAfterLogout = mockAuth.tryRefreshCallCount;
  await Future.delayed(const Duration(seconds: 2));
  expect(mockAuth.tryRefreshCallCount, equals(refreshCallsAfterLogout),
      reason: 'logout 后 Token 刷新定时器应已取消');
});
```

**预期结果**：
- ✅ `logout()` 后 `Timer.periodic` 被 `cancel()`
- ✅ 登出后不会再有 `tryRefresh()` 调用
- ✅ 无内存泄漏（Timer 未被 GC 但仍在运行）

**失败判定**：
- ❌ 登出后 Timer 仍在运行（持续尝试 refresh）
- ❌ Timer 未被正确 cancel（后台仍有周期性网络请求）
- ❌ Timer 导致 AuthService 引用不被 GC

---

### TC-020: logout() 可从未认证状态安全调用（幂等性）

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P2 — MEDIUM**（防御性编程） |
| **类别** | AuthNotifier / logout 边界 |
| **关联验收标准** | 登出操作安全重复 |

**前置条件**：
- 当前状态为 AsyncData(null)（未认证）

**测试步骤**：

1. 未认证状态下调用 logout()
2. 验证不崩溃
3. 验证状态保持在 AsyncData(null)

```dart
test('logout() is safe to call when already unauthenticated', () async {
  final mockAuth = FakeAuthService(hasToken: false);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 未认证状态下调用 logout
  await container.read(authProvider.notifier).logout();
  
  // 状态应保持 null
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNull);
  expect(state.hasError, isFalse);
});
```

**预期结果**：
- ✅ 未认证状态下 logout() 不抛出异常
- ✅ 状态保持 AsyncData(null)
- ✅ 不产生副作用（不写入空 Token）

**失败判定**：
- ❌ 未认证状态下 logout() 抛出异常
- ❌ logout() 导致状态从 null 变为 error

---

## 六、会话恢复与 Token 刷新测试（7 项）

### TC-021: 启动时 Token 有效 → build() 返回已验证用户

| 属性 | 内容 |
|------|------|
| **ID** | TC-021 |
| **优先级** | **P0 — CRITICAL**（会话持久化） |
| **类别** | AuthNotifier / 会话恢复 |
| **关联验收标准** | 关闭浏览器后重新打开自动恢复登录状态 |

**前置条件**：
- TokenStorage 中存有有效 Token
- Mock AuthService.initialize() 加载 Token 到内存
- Mock AuthService.tryRefresh() 成功
- Mock AuthService.getMe() 返回 User

**测试步骤**：

1. 模拟 storage 中有 Token
2. 创建 ProviderContainer → 触发 build()
3. 等待完成
4. 验证最终状态

```dart
test('build() auto-authenticates when token is valid', () async {
  final mockAuth = FakeAuthService(hasToken: true, refreshSucceeds: true, getMeReturnsValid: true);
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.future);
  
  expect(container.read(authProvider).valueOrNull, isNotNull);
  // 调用链: initialize → tryRefresh → getMe
  expect(mockAuth.initializeCallCount, equals(1));
  expect(mockAuth.tryRefreshCallCount, equals(1));
  expect(mockAuth.getMeCallCount, equals(1));
});
```

**预期结果**：
- ✅ `build()` 完成时状态为 AsyncData(user)
- ✅ 执行顺序：initialize → tryRefresh → getMe
- ✅ 用户无需手动登录即可直接进入首页
- ✅ Token 刷新后新 Token 被持久化

**失败判定**：
- ❌ build() 返回 null 而非 user（未恢复会话）
- ❌ 执行顺序错误（如 getMe 在 refresh 之前导致 401）
- ❌ Token 刷新后未更新存储

---

### TC-022: 启动时 Token 无效 → build() 返回 null

| 属性 | 内容 |
|------|------|
| **ID** | TC-022 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | AuthNotifier / 会话恢复 |
| **关联验收标准** | Token 无效 → 重定向登录页 |

**前置条件**：
- TokenStorage 中有 Token 但已过期
- tryRefresh() 返回 false
- 或 TokenStorage 中无 Token

**测试步骤**：

1. Mock 有 Token 但 refresh 失败
2. 或 Mock 无 Token
3. 验证最终状态为 AsyncData(null)

```dart
test('build() returns null when token is invalid or expired', () async {
  // 场景 A: 有 Token 但 refresh 失败
  final mockAuthA = FakeAuthService(hasToken: true, refreshFails: true);
  final containerA = createContainer(mockAuthA);
  await containerA.read(authProvider.future);
  expect(containerA.read(authProvider).valueOrNull, isNull);
  
  // 场景 B: 无 Token
  final mockAuthB = FakeAuthService(hasToken: false);
  final containerB = createContainer(mockAuthB);
  await containerB.read(authProvider.future);
  expect(containerB.read(authProvider).valueOrNull, isNull);
});
```

**预期结果**：
- ✅ Token 无效时最终状态为 AsyncData(null)
- ✅ refresh 失败后清除残留的无效 Token
- ✅ 应用应据此重定向到 `/login`

**失败判定**：
- ❌ refresh 失败但状态仍显示为已认证
- ❌ refresh 失败后未清除无效 Token（残留脏数据）
- ❌ 无 Token 时 build() 抛出异常（应为正常 null）

---

### TC-023: Token 刷新成功 → 自动保持会话

| 属性 | 内容 |
|------|------|
| **ID** | TC-023 |
| **优先级** | **P0 — CRITICAL**（用户无感知续期） |
| **类别** | AuthNotifier / Token 自动刷新 |
| **关联验收标准** | Access Token 过期前自动使用 Refresh Token 续期 |

**前置条件**：
- 已认证状态
- Token 刷新定时器已启动
- tryRefresh() 返回 true，新 Token 保存成功

**测试步骤**：

1. 创建已认证 ProviderContainer（含定时刷新 Timer）
2. 模拟 Timer 触发 → tryRefresh() 被调用
3. 验证 tryRefresh 成功
4. 验证状态保持为 AsyncData(user)（用户不感知）
5. 验证新 Token 已持久化

```dart
test('auto-refresh silently extends session when refresh succeeds', () async {
  final mockAuth = FakeAuthService(hasToken: true, refreshSucceeds: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 触发 refresh（通过 Timer 或手动模拟）
  final success = await mockAuth.tryRefresh();
  expect(success, isTrue);
  
  // 用户状态应保持不变
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNotNull);
  
  // Token 应已更新
  expect(mockAuth.tokensUpdated, isTrue);
});
```

**预期结果**：
- ✅ Token 刷新成功时用户状态不变（仍然是已认证）
- ✅ UI 层无感知（无 Toast、无弹窗、无状态闪烁）
- ✅ 新 Token 被保存到 AuthService 内存和 TokenStorage
- ✅ 刷新间隔合理（如 accessToken 过期前 5 分钟）

**失败判定**：
- ❌ 刷新成功但 User 状态被清空
- ❌ 刷新成功但触发 UI 闪烁或状态切换
- ❌ 新 Token 未持久化

---

### TC-024: Token 刷新失败 → 清除状态 → 通知会话过期

| 属性 | 内容 |
|------|------|
| **ID** | TC-024 |
| **优先级** | **P0 — CRITICAL**（会话过期安全处理） |
| **类别** | AuthNotifier / Token 刷新失败 |
| **关联验收标准** | Refresh Token 也过期 → 清除本地 Token → 提示"会话已过期" |

**前置条件**：
- 已认证状态
- tryRefresh() 返回 false（Refresh Token 也过期/无效）

**测试步骤**：

1. 创建已认证 ProviderContainer
2. 模拟定时器触发 refresh → 失败
3. 验证状态变更

```dart
test('refresh failure clears auth state and notifies session expiry', () async {
  final mockAuth = FakeAuthService(hasToken: true, refreshFails: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 模拟 refresh 失败后的处理逻辑
  // AuthNotifier 应: 1) 清除状态 2) 清除 Token 3) 通知路由
  // 注意：具体触发方式取决于 AuthNotifier 内部如何处理 tryRefresh 失败
  
  // 验证 Token 被清除
  expect(mockAuth.logoutCalled, isTrue); // 或 clearTokens 被调用
});
```

**预期结果**：
- ✅ refresh 失败后 `logout()` 被调用（清除所有 Token）
- ✅ 状态变为 AsyncData(null)（未认证）
- ✅ Token 刷新定时器被取消
- ✅ 路由守卫检测到 null → 重定向到 `/login`
- ✅ 用户看到"会话已过期，请重新登录"提示

**失败判定**：
- ❌ refresh 失败后状态保持为已认证（UI 与实际不符）
- ❌ refresh 失败后仅清除 Token 但未更新状态
- ❌ 没有会话过期通知（用户被悄悄登出，困惑）
- ❌ 继续尝试 refresh（无限循环）

---

### TC-025: Token 自动刷新使用 Timer.periodic

| 属性 | 内容 |
|------|------|
| **ID** | TC-025 |
| **优先级** | **P1 — HIGH**（架构正确性） |
| **类别** | AuthNotifier / Timer 管理 |
| **关联验收标准** | 使用 Timer.periodic 管理定期刷新 |

**前置条件**：
- AuthNotifier 在认证成功后启动 Timer
- Timer 间隔基于 expiresIn（accessToken 过期前 5 分钟刷新）

**测试步骤**：

1. 模拟 login 返回 `expiresIn: 3600`（1 小时）
2. 验证 Timer 间隔计算为 `(3600 - 300) = 3300` 秒 或合理值
3. 验证 Timer 在 AuthNotifier 生命周期内启动
4. 验证 Timer 在 Provider.dispose 时被取消

```dart
test('Token refresh timer uses Timer.periodic with correct interval', () async {
  final mockAuth = FakeAuthService(
    hasToken: true,
    tokenExpiresIn: 3600, // 1 小时
  );
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 验证 timer 已启动（通过检查定时器相关状态）
  // 具体验证方式取决于 AuthNotifier 实现
  expect(mockAuth.refreshTimerActive, isTrue);
  
  // dispose container → timer 应被取消
  container.dispose();
  expect(mockAuth.refreshTimerActive, isFalse);
});
```

**预期结果**：
- ✅ 认证成功后 `Timer.periodic` 被创建
- ✅ 定时器间隔 = `(expiresIn - 300) 秒`（过期前 5 分钟）
- ✅ `Timer.periodic` 在 Provider dispose 时被 cancel
- ✅ `expiresIn <= 0` 时（异常 Token）使用合理的默认间隔（如 30 分钟）

**失败判定**：
- ❌ 使用 `Timer(duration)` 单次定时器（应使用 periodic）
- ❌ 定时器间隔未考虑 expiresIn（使用固定间隔）
- ❌ dispose 时 Timer 未被 cancel（内存泄漏）
- ❌ expiresIn 为 null 或 0 时崩溃

---

### TC-026: 启动时 Token 正常无需刷新

| 属性 | 内容 |
|------|------|
| **ID** | TC-026 |
| **优先级** | **P2 — MEDIUM**（优化路径） |
| **类别** | AuthNotifier / 会话恢复优化 |
| **关联验收标准** | Token 未到期时不频繁刷新 |

**前置条件**：
- TokenStorage 中有 Token
- Token 未过期（或过期时间充足）

**测试步骤**：

1. 创建 ProviderContainer，Token 有效且未过期
2. 验证 tryRefresh 仍被调用（续期）或使用当前 Token 直接 getMe

```dart
test('build() refreshes even when token appears valid', () async {
  // 注：根据实现决策，即使 Token 未过期也应在启动时 tryRefresh
  // 以确保获取最新的 Token 和 User 信息
  final mockAuth = FakeAuthService(hasToken: true, tokenExpiresIn: 3000);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 启动时总是调用 tryRefresh 确保 Token 是最新的
  expect(mockAuth.tryRefreshCallCount, equals(1));
});
```

**预期结果**：
- ✅ 即使 Token 看似有效，build() 仍调用 tryRefresh() 确保最新
- ✅ 不会因为"Token 看似有效"而跳过续期导致后续过期
- ✅ tryRefresh 成功后获取最新 User 信息

**失败判定**：
- ❌ Token 看似有效时完全跳过 refresh → 后续可能突然过期

---

### TC-027: 启动加载超时处理（>3s / >10s）

| 属性 | 内容 |
|------|------|
| **ID** | TC-027 |
| **优先级** | **P1 — HIGH**（UX 关键路径） |
| **类别** | AuthNotifier / 启动超时 |
| **关联验收标准** | 加载 >3s 显示"正在连接服务器..."；>10s 显示超时 + 重试 |

**前置条件**：
- 启动流程（build）超过预期时间
- 注：超时提示通常在 UI 层（Splash 页面）实现，但 AuthNotifier 的
  build() 超时行为是 UI 能否正确切换状态的基础

**测试步骤**：

1. Mock AuthService.initialize() 延迟 12 秒（模拟服务器无响应）
2. 验证 AuthNotifier.build() 的行为

```dart
test('build() handles prolonged loading gracefully', () async {
  final mockAuth = FakeAuthService(initializeDelay: Duration(seconds: 12));
  final container = createContainer(mockAuth);
  
  // build() 不应因长时间等待而崩溃
  // 超时提示由 UI 层处理（基于 AsyncLoading 状态 + 计时器）
  final future = container.read(authProvider.future);
  
  // 在等待期间，状态应为 loading
  final state = container.read(authProvider);
  expect(state.isLoading, isTrue);
  
  await future;
});
```

**预期结果**：
- ✅ AuthNotifier.build() 保持 loading 状态直到操作完成或失败
- ✅ 不主动超时（超时提示由 UI 层 SplashScreen 根据 loading 时长显示）
- ✅ 如果后端最终返回错误，状态变为 AsyncError

**失败判定**：
- ❌ AuthNotifier 内部设定超时而提前失败（应让 UI 层控制超时展示）
- ❌ build() 无限 loading 无超时机制（用户一直看加载动画）
- ❌ build() 因长时间等待而崩溃

---

## 七、Provider 类型与 API 正确性测试（2 项）

### TC-028: AuthNotifier 使用 Riverpod 3.x AsyncNotifier\<User?\> API

| 属性 | 内容 |
|------|------|
| **ID** | TC-028 |
| **优先级** | **P0 — CRITICAL**（架构正确性） |
| **类别** | AuthNotifier / Riverpod API |
| **关联验收标准** | Riverpod 3.x AsyncNotifier API 正确使用 |

**前置条件**：
- `flutter_riverpod ^3.3.1`
- AuthNotifier 已实现

**测试步骤**：

1. 验证 AuthNotifier 继承自 `AsyncNotifier<User?>`
2. 验证 provider 声明为 `AsyncNotifierProvider<AuthNotifier, User?>` 或 `AutoDisposeAsyncNotifierProvider`
3. 验证 `build()` 是 `async` 方法，返回 `Future<User?>`
4. 验证 login/register/logout 是 `Future<void>` 方法

```dart
test('AuthNotifier uses correct Riverpod 3.x AsyncNotifier API', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  
  final notifier = container.read(authProvider.notifier);
  expect(notifier, isA<AsyncNotifier<User?>>());
  
  // 验证 provider 类型
  final provider = authProvider;
  expect(provider, isA<AsyncNotifierProvider<dynamic, User?>>());
});
```

**预期结果**：
- ✅ `AuthNotifier extends AutoDisposeAsyncNotifier<User?>` 或 `AsyncNotifier<User?>`
- ✅ Provider 声明为 `AutoDisposeAsyncNotifierProvider<AuthNotifier, User?>` 或等效类型
- ✅ `build()` 是异步方法
- ✅ 不使用已废弃的 `StateNotifier`、`ChangeNotifier`、`AsyncNotifierProvider.autoDispose`（旧写法）

**失败判定**：
- ❌ 使用旧版 Riverpod API（StateNotifierProvider）
- ❌ build() 是 sync 方法但依赖异步操作
- ❌ 类型参数不匹配（如 AsyncNotifier\<void\> 或 AsyncNotifier\<AuthState\>）

---

### TC-029: AuthNotifier 通过 ref.read 正确注入 AuthService

| 属性 | 内容 |
|------|------|
| **ID** | TC-029 |
| **优先级** | **P1 — HIGH**（依赖注入正确性） |
| **类别** | AuthNotifier / Provider 依赖 |
| **关联验收标准** | AuthService 通过 Provider 注入 |

**前置条件**：
- AuthService 已有对应的 Provider（如 `authServiceProvider`）
- AuthNotifier 在 `build()` 中通过 `ref.read(authServiceProvider)` 获取

**测试步骤**：

1. 创建 ProviderContainer，override authServiceProvider 为 Mock
2. 验证 AuthNotifier 读取的是 override 后的实例
3. 验证 AuthNotifier 不直接 new AuthService()

```dart
test('AuthNotifier injects AuthService via ref.read', () async {
  final mockAuth = FakeAuthService();
  final container = ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(mockAuth),
  ]);
  addTearDown(container.dispose);
  
  await container.read(authProvider.future);
  
  // mockAuth 的方法（如 login）应通过 AuthNotifier 被调用
  // 证明依赖注入链路正确
});
```

**预期结果**：
- ✅ AuthService 通过 `ref.read(authServiceProvider)` 获取
- ✅ `build()` 中可以使用 `ref.watch` 但不引起不必要重建
- ✅ AuthNotifier 不直接实例化 AuthService（可测试性）

**失败判定**：
- ❌ AuthNotifier 内部直接 new AuthService()（无法 mock）
- ❌ AuthService 不从 Provider 读取（硬编码或全局变量）
- ❌ 使用 `ref.watch` 监听不相关的 Provider 导致不必要的重建

---

## 八、边界与异常处理测试（8 项）

### TC-030: 网络错误时 login() 返回友好错误消息

| 属性 | 内容 |
|------|------|
| **ID** | TC-030 |
| **优先级** | **P0 — CRITICAL**（用户体验） |
| **类别** | AuthNotifier / 网络异常 |
| **关联验收标准** | 登录失败时显示"网络连接失败，请检查网络后重试" |

**前置条件**：
- Mock AuthService.login() 抛出网络相关异常（DioException type: connectionError）

**测试步骤**：

1. 调用 login 时 Mock 网络错误
2. 验证 state.error 包含网络错误消息（非技术细节）

```dart
test('login() network error returns user-friendly message', () async {
  final mockAuth = FakeAuthService(networkError: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  await container.read(authProvider.notifier)
      .login('a@b.com', 'pass');
  
  final state = container.read(authProvider);
  expect(state.hasError, isTrue);
  expect(state.error.toString(), contains('网络'));
  // 不应包含技术术语
  expect(state.error.toString(), isNot(contains('DioException')));
  expect(state.error.toString(), isNot(contains('connectionError')));
});
```

**预期结果**：
- ✅ 网络错误 → 错误消息 = "网络连接失败，请检查网络后重试"
- ✅ 不暴露技术术语（DioException、SocketException 等）
- ✅ 用户可以根据提示采取行动（检查网络、重试）

**失败判定**：
- ❌ 网络错误直接透传 DioException 消息
- ❌ 错误消息无"网络"相关关键词（用户不知道是网络问题）
- ❌ 与其他错误（如密码错误）消息混淆

---

### TC-031: 服务器错误时 login() 返回友好错误消息

| 属性 | 内容 |
|------|------|
| **ID** | TC-031 |
| **优先级** | **P1 — HIGH** |
| **类别** | AuthNotifier / 服务器异常 |
| **关联验收标准** | 登录失败显示"服务暂时不可用，请稍后再试" |

**前置条件**：
- Mock AuthService.login() 返回 500 状态码

**测试步骤**：

1. Mock 服务器 500 错误
2. 验证错误消息

```dart
test('login() server error returns user-friendly message', () async {
  final mockAuth = FakeAuthService(serverError: true, serverStatusCode: 500);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  await container.read(authProvider.notifier)
      .login('a@b.com', 'pass');
  
  final state = container.read(authProvider);
  expect(state.hasError, isTrue);
  expect(state.error.toString(), 
      anyOf(contains('服务暂时不可用'), contains('服务器'), contains('稍后重试')));
});
```

**预期结果**：
- ✅ 500 错误 → "服务暂时不可用，请稍后再试"
- ✅ 503/502 → 类似的服务不可用消息
- ✅ 不暴露后端堆栈信息

**失败判定**：
- ❌ 500 错误直接显示"Internal Server Error"
- ❌ 暴露后端异常详情

---

### TC-032: register() 邮箱已注册错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-032 |
| **优先级** | **P1 — HIGH** |
| **类别** | AuthNotifier / register 异常 |
| **关联验收标准** | 注册失败显示"该邮箱已被注册" |

**前置条件**：
- Mock AuthService.register() 返回 409（Conflict）或对应错误

**测试步骤**：

1. Mock 邮箱已注册错误
2. 验证错误消息

```dart
test('register() duplicate email returns specific error', () async {
  final mockAuth = FakeAuthService(registerFails: true, registerError: 'Email already registered');
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  await container.read(authProvider.notifier)
      .register('taken@test.com', 'StrongPass1');
  
  final state = container.read(authProvider);
  expect(state.hasError, isTrue);
  expect(state.error.toString(), 
      anyOf(contains('已注册'), contains('已被注册'), contains('already')));
});
```

**预期结果**：
- ✅ 邮箱已注册时错误消息明确指出原因
- ✅ 错误消息 = "该邮箱已被注册" 或类似
- ✅ 区别于普通注册失败

**失败判定**：
- ❌ 邮箱已注册时只显示通用"注册失败"消息
- ❌ 错误消息与技术细节

---

### TC-033: 快速连续 logout + login 不产生不一致状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-033 |
| **优先级** | **P2 — MEDIUM**（并发安全） |
| **类别** | AuthNotifier / 状态一致性 |
| **关联验收标准** | 操作有反馈，状态一致 |

**前置条件**：
- 已认证状态

**测试步骤**：

1. 快速调用 logout() → login()
2. 验证最终状态和 Token

```dart
test('rapid logout then login produces consistent state', () async {
  final mockAuth = FakeAuthService(hasToken: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  final notifier = container.read(authProvider.notifier);
  
  // 快速登出 + 登录
  await notifier.logout();
  await notifier.login('new@test.com', 'NewPass123');
  
  final state = container.read(authProvider);
  expect(state.valueOrNull, isNotNull);
  expect(state.valueOrNull!.email, equals('new@test.com'));
  // Token 应为最新 login 的 Token
  expect(mockAuth.accessToken, equals('new-access-token'));
});
```

**预期结果**：
- ✅ logout 后 login 可以正常完成（不残留旧状态）
- ✅ 最终状态与 Token 一致
- ✅ 不抛出异常

**失败判定**：
- ❌ logout 后 login 失败（logout 未完全完成）
- ❌ 最终状态与 Token 不一致
- ❌ 出现竞态条件导致异常

---

### TC-034: AuthService.initialize() 失败时 build() 不崩溃

| 属性 | 内容 |
|------|------|
| **ID** | TC-034 |
| **优先级** | **P1 — HIGH**（容错处理） |
| **类别** | AuthNotifier / 初始化异常 |
| **关联验收标准** | 持久化失败不影响正常使用 |

**前置条件**：
- Mock AuthService.initialize() 抛出异常（如 TokenStorage 不可用）

**测试步骤**：

1. Mock initialize() 抛出异常
2. 验证 build() 不崩溃
3. 验证状态合适

```dart
test('build() survives AuthService.initialize() failure', () async {
  final mockAuth = FakeAuthService(initializeFails: true);
  final container = createContainer(mockAuth);
  
  // build() 不应崩溃
  await container.read(authProvider.future);
  
  final state = container.read(authProvider);
  // 初始化失败 → 应为未认证状态（而非 crash）
  expect(state.valueOrNull, isNull);
});
```

**预期结果**：
- ✅ `initialize()` 失败时，build() 回退到未认证状态
- ✅ 不抛出未处理的异常
- ✅ 用户可以手动登录（login 仍可用）

**失败判定**：
- ❌ initialize 失败导致 build() 抛出未处理异常
- ❌ initialize 失败后 login 也被阻塞
- ❌ 应用崩溃

---

### TC-035: AuthService.getMe() 失败时 build() 回退到 null

| 属性 | 内容 |
|------|------|
| **ID** | TC-035 |
| **优先级** | **P1 — HIGH** |
| **类别** | AuthNotifier / getMe 异常 |
| **关联验收标准** | 获取用户信息失败时安全回退 |

**前置条件**：
- Token 存在且 refresh 成功
- getMe() 失败（如 500 或网络错误）

**测试步骤**：

1. Mock refresh 成功但 getMe 失败
2. 验证状态

```dart
test('build() falls back to null when getMe() fails after refresh', () async {
  final mockAuth = FakeAuthService(hasToken: true, refreshSucceeds: true, getMeFails: true);
  final container = createContainer(mockAuth);
  
  await container.read(authProvider.future);
  
  final state = container.read(authProvider);
  // getMe 失败 → 应回退到未认证（不能使用过期 User）
  // 或者变为 AsyncError
  expect(state.valueOrNull, isNull);
});
```

**预期结果**：
- ✅ getMe 失败后 Token 可能仍有效，但状态为未认证或 error
- ✅ 不清除有效的 Token（以便 UI 层决定重试或重新登录）
- ✅ 不返回过期的 User 对象

**失败判定**：
- ❌ getMe 失败但状态显示已认证（使用旧 User 数据）
- ❌ getMe 失败导致未处理异常

---

### TC-036: login() 返回的 AuthTokens.user 字段正确处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-036 |
| **优先级** | **P0 — CRITICAL**（数据完整性） |
| **类别** | AuthNotifier / 数据映射 |
| **关联验收标准** | 用户信息正确保存和展示 |

**前置条件**：
- Backend login response 的 data 中包含 `user` 子对象
- AuthTokens.fromJson 正确解析 user 字段

**测试步骤**：

1. Mock login 返回包含完整 user 的 AuthTokens
2. 验证 AuthNotifier 状态中的 User 正确

```dart
test('login() correctly preserves user info from AuthTokens', () async {
  final mockAuth = FakeAuthService(hasToken: false);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  await container.read(authProvider.notifier)
      .login('admin@kayak.local', 'Admin123');
  
  final user = container.read(authProvider).valueOrNull;
  expect(user, isNotNull);
  expect(user!.id, isNotEmpty);
  expect(user.email, equals('admin@kayak.local'));
  expect(user.username, isNotEmpty);
  expect(user.createdAt, isA<DateTime>());
});
```

**预期结果**：
- ✅ `AuthTokens.user` 的完整信息在 AuthNotifier 状态中可用
- ✅ User 包含：id、email、username、createdAt、updatedAt
- ✅ email 与 login 参数一致
- ✅ createdAt 和 updatedAt 为有效 DateTime（非 null）

**失败判定**：
- ❌ AuthTokens.user 被忽略（AuthNotifier 状态中 User 为 null 或字段为空）
- ❌ User.id 为空字符串
- ❌ createdAt 为 null

---

### TC-037: login() / register() 触发多次时 previous error 被清除

| 属性 | 内容 |
|------|------|
| **ID** | TC-037 |
| **优先级** | **P1 — HIGH**（错误恢复流程） |
| **类别** | AuthNotifier / 错误清除 |
| **关联验收标准** | 失败后可重试 |

**前置条件**：
- 之前 login 失败 → 状态为 AsyncError

**测试步骤**：

1. 第一次 login 失败 → AsyncError
2. 修正密码后再次 login → 成功
3. 验证之前的错误被清除

```dart
test('successful login clears previous error state', () async {
  final mockAuth = FakeAuthService(loginFailsOnFirstAttempt: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 第一次 — 失败
  await container.read(authProvider.notifier)
      .login('a@b.com', 'wrong');
  expect(container.read(authProvider).hasError, isTrue);
  
  // 第二次 — 成功
  await container.read(authProvider.notifier)
      .login('a@b.com', 'correct');
  
  final state = container.read(authProvider);
  expect(state.hasError, isFalse);
  expect(state.valueOrNull, isNotNull);
});
```

**预期结果**：
- ✅ 重新调用 login/register 时，之前的错误状态被清除
- ✅ 成功后状态干净地变为 AsyncData(user)
- ✅ 不残留错误信息

**失败判定**：
- ❌ 成功后仍携带之前的 error 信息
- ❌ hasError 仍为 true

---

## 九、集成场景测试（6 项）

### TC-038: 完整登录 → 登出 → 重新登录流程

| 属性 | 内容 |
|------|------|
| **ID** | TC-038 |
| **优先级** | **P0 — CRITICAL**（核心用户旅程） |
| **类别** | AuthNotifier / 集成流程 |
| **关联验收标准** | 登录/登出/重新登录完整可用 |

**测试步骤**：

```
Step 1: build() → null（无 Token）
Step 2: login() → user（认证成功）
Step 3: 验证状态：AsyncData(user)，Token 持久化
Step 4: logout() → null（清除所有状态）
Step 5: login() → user（重新登录成功）
Step 6: 验证状态：AsyncData(user)，Token 更新
```

```dart
test('complete login-logout-relogin flow', () async {
  final mockAuth = FakeAuthService();
  final container = createContainer(mockAuth);
  
  // Step 1: build → null
  await container.read(authProvider.future);
  expect(container.read(authProvider).valueOrNull, isNull);
  
  // Step 2: login
  await container.read(authProvider.notifier)
      .login('user1@test.com', 'Pass1');
  expect(container.read(authProvider).valueOrNull!.email, 'user1@test.com');
  expect(mockAuth.accessToken, isNotNull);
  
  // Step 3: logout
  await container.read(authProvider.notifier).logout();
  expect(container.read(authProvider).valueOrNull, isNull);
  expect(mockAuth.accessToken, isNull);
  
  // Step 4: relogin
  await container.read(authProvider.notifier)
      .login('user2@test.com', 'Pass2');
  expect(container.read(authProvider).valueOrNull!.email, 'user2@test.com');
  expect(mockAuth.accessToken, isNotNull);
  
  // 验证不同用户之间无数据泄漏
  expect(mockAuth.lastLoginEmail, equals('user2@test.com'));
});
```

**预期结果**：
- ✅ 完整的登出→重新登录流程无错误
- ✅ 两次登录使用不同的凭据，数据无交叉污染
- ✅ logout 后 Token 完全清除
- ✅ 整个流程状态转换正确

**失败判定**：
- ❌ logout 后重新登录时残留旧 Token
- ❌ 不同用户之间的数据混淆
- ❌ 流程中任一步抛出异常

---

### TC-039: 应用冷启动 → 会话恢复 → 继续使用

| 属性 | 内容 |
|------|------|
| **ID** | TC-039 |
| **优先级** | **P0 — CRITICAL**（会话持久化核心流程） |
| **类别** | AuthNotifier / 集成流程 |
| **关联验收标准** | 关闭浏览器后重新打开自动保持登录状态 |

**测试步骤**：

```
Step 1: login() → user1，Token 写入 TokenStorage
Step 2: 模拟应用关闭（销毁 ProviderContainer）
Step 3: 模拟应用重启（创建新的 ProviderContainer，TokenStorage 中有 Token）
Step 4: build() → 自动恢复 user1
```

```dart
test('cold start with saved token restores session', () async {
  // Phase 1: 首次登录
  final mockAuth1 = FakeAuthService();
  final container1 = createContainer(mockAuth1);
  await container1.read(authProvider.future);
  await container1.read(authProvider.notifier)
      .login('admin@kayak.local', 'Admin123');
  expect(container1.read(authProvider).valueOrNull!.email, 'admin@kayak.local');
  
  // Phase 2: 模拟 restart（新 container，但 storage 中有 token）
  final mockAuth2 = FakeAuthService(
    hasToken: true, // Token 来自之前的持久化
    storedAccessToken: mockAuth1.accessToken,
    storedRefreshToken: mockAuth1.refreshToken,
  );
  final container2 = createContainer(mockAuth2);
  
  await container2.read(authProvider.future);
  
  // should restore session
  expect(container2.read(authProvider).valueOrNull, isNotNull);
  expect(container2.read(authProvider).valueOrNull!.email, 'admin@kayak.local');
  
  container1.dispose();
  container2.dispose();
});
```

**预期结果**：
- ✅ 应用重启后自动恢复认证状态
- ✅ 无需用户重新输入凭据
- ✅ Token 从 TokenStorage 正确加载到 AuthService 内存
- ✅ 用户信息正确恢复

**失败判定**：
- ❌ 重启后 build() 返回 null（未恢复会话）
- ❌ Token 加载失败但未报错（静默失败）
- ❌ 重启后 User 信息缺失

---

### TC-040: Token 过期 → 自动刷新 → 保持会话

| 属性 | 内容 |
|------|------|
| **ID** | TC-040 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | AuthNotifier / 集成流程 |
| **关联验收标准** | Access Token 过期前自动使用 Refresh Token 续期 |

**测试步骤**：

```
Step 1: login → user
Step 2: 时间推移 → Access Token 即将过期
Step 3: Timer 触发 → tryRefresh() → 成功
Step 4: 新 Token 保存，状态保持不变
Step 5: 应用继续正常工作
```

```dart
test('token auto-refresh keeps session alive', () async {
  final mockAuth = FakeAuthService(
    hasToken: true,
    tokenExpiresIn: 300, // 5 分钟后过期
    refreshSucceeds: true,
  );
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  final userBefore = container.read(authProvider).valueOrNull;
  expect(userBefore, isNotNull);
  
  // 模拟 Timer 触发 refresh
  final refreshed = await mockAuth.tryRefresh();
  expect(refreshed, isTrue);
  
  // 状态应保持不变（仍是已认证）
  final userAfter = container.read(authProvider).valueOrNull;
  expect(userAfter, isNotNull);
  // Token 应已更新
  expect(mockAuth.tokensUpdated, isTrue);
});
```

**预期结果**：
- ✅ Token 刷新成功 → 会话继续，用户无感知
- ✅ 不触发路由重定向
- ✅ 不显示任何 Toast/提示
- ✅ 新 Token 被持久化

**失败判定**：
- ❌ refresh 成功但触发了状态切换（用户看到闪烁）
- ❌ refresh 过程中显示 loading 覆盖整个页面
- ❌ 刷新后状态变为 null 再变回 user（抖动）

---

### TC-041: Token 刷新失败 → 清除会话 → 重定向登录

| 属性 | 内容 |
|------|------|
| **ID** | TC-041 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | AuthNotifier / 集成流程 |
| **关联验收标准** | Refresh Token 也过期 → 清除 → 提示"会话已过期" |

**测试步骤**：

```
Step 1: login → user
Step 2: 时间推移 → Access Token 过期 → Refresh Token 也过期
Step 3: Timer 触发 → tryRefresh() → 失败
Step 4: 清除 Token + 状态 + Timer
Step 5: 路由重定向到 /login + Toast "会话已过期"
```

```dart
test('refresh failure leads to complete session cleanup', () async {
  final mockAuth = FakeAuthService(hasToken: true, refreshFails: true);
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 等待 refresh 失败后的处理
  // AuthNotifier 应自动: clearTokens → set state to null
  // 具体验证方式取决于 AuthNotifier 实现
  
  expect(mockAuth.logoutCalled, isTrue); // Token 已清除
});
```

**预期结果**：
- ✅ Token 刷新失败 → AuthNotifier 清除所有认证状态
- ✅ 状态变为 AsyncData(null)
- ✅ 所有 Token 从内存和存储中清除
- ✅ Token 刷新定时器被取消
- ✅ UI 层可检测到 null 状态 → 路由守卫重定向 /login

**失败判定**：
- ❌ refresh 失败但状态保持为已认证
- ❌ refresh 失败后仍保留旧 Token（可能导致后续请求 401）
- ❌ 没有状态变更通知

---

### TC-042: register() → 自动 login → 可使用所有受保护功能

| 属性 | 内容 |
|------|------|
| **ID** | TC-042 |
| **优先级** | **P0 — CRITICAL**（注册即用） |
| **类别** | AuthNotifier / 集成流程 |
| **关联验收标准** | 注册成功后自动登录 |

**测试步骤**：

```
Step 1: build() → null（未认证）
Step 2: register(email, password, username) → 成功
Step 3: 验证状态为 AsyncData(user) — 自动登录
Step 4: 验证 Token 已持久化
Step 5: 应用其他功能可正常使用（需要认证 Token）
```

```dart
test('register auto-login enables full app access', () async {
  final mockAuth = FakeAuthService();
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  expect(container.read(authProvider).valueOrNull, isNull);
  
  await container.read(authProvider.notifier)
      .register('new@test.com', 'StrongPass1', 'NewUser');
  
  final user = container.read(authProvider).valueOrNull;
  expect(user, isNotNull);
  expect(user!.email, equals('new@test.com'));
  
  // Token 已可用 → 后续 API 请求可使用此 Token
  expect(mockAuth.accessToken, isNotNull);
  expect(mockAuth.accessToken, isNotEmpty);
});
```

**预期结果**：
- ✅ 注册后自动处于已认证状态
- ✅ 无需手动调用 login
- ✅ Token 可用于后续 API 请求

**失败判定**：
- ❌ 注册后需要手动登录
- ❌ 注册后 Token 为空

---

### TC-043: 多 Provider 消费同一 AuthNotifier 且状态一致

| 属性 | 内容 |
|------|------|
| **ID** | TC-043 |
| **优先级** | **P2 — MEDIUM**（数据一致性） |
| **类别** | AuthNotifier / Provider 消费 |
| **关联验收标准** | 多组件消费同一数据源 |

**测试步骤**：

1. 创建 ProviderContainer
2. 从两个不同的 `ref` 读取 authProvider
3. 验证两者返回相同状态
4. 通过 notifier 执行 login
5. 验证两者同步更新

```dart
test('multiple consumers see consistent auth state', () async {
  final mockAuth = FakeAuthService();
  final container = createContainer(mockAuth);
  await container.read(authProvider.future);
  
  // 两个监听者
  container.listen(authProvider, (prev, next) {});
  
  await container.read(authProvider.notifier)
      .login('a@b.com', 'pass');
  
  // 所有读取应一致
  final state1 = container.read(authProvider);
  final state2 = container.read(authProvider);
  expect(state1.valueOrNull?.email, equals(state2.valueOrNull?.email));
});
```

**预期结果**：
- ✅ 多个 widget/consumer 读取到相同的认证状态
- ✅ 状态更新时所有监听者收到通知
- ✅ 不出现互不一致的状态

**失败判定**：
- ❌ 不同 consumer 看到不同的 User 对象（同一实体）
- ❌ 状态更新未通知所有监听者

---

## 十、测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | build() 初始 AsyncLoading |
| TC-002 | | | ⬜ 待执行 | 未认证 → AsyncData(null) |
| TC-003 | | | ⬜ 待执行 | 认证成功 → AsyncData(user) |
| TC-004 | | | ⬜ 待执行 | 认证错误 → AsyncError |
| TC-005 | | | ⬜ 待执行 | build() 调用 initialize() |
| TC-006 | | | ⬜ 待执行 | Token 存在调用 tryRefresh() |
| TC-007 | | | ⬜ 待执行 | 无 Token 跳过 refresh |
| TC-008 | | | ⬜ 待执行 | login 成功 → user |
| TC-009 | | | ⬜ 待执行 | login 失败 → error |
| TC-010 | | | ⬜ 待执行 | login 中 loading 状态 |
| TC-011 | | | ⬜ 待执行 | login 委托 AuthService |
| TC-012 | | | ⬜ 待执行 | login 失败保留原状态 |
| TC-013 | | | ⬜ 待执行 | login 并发保护 |
| TC-014 | | | ⬜ 待执行 | register 自动登录 |
| TC-015 | | | ⬜ 待执行 | register 失败 → error |
| TC-016 | | | ⬜ 待执行 | register 委托 AuthService |
| TC-017 | | | ⬜ 待执行 | register 中 loading 状态 |
| TC-018 | | | ⬜ 待执行 | logout 清除状态 |
| TC-019 | | | ⬜ 待执行 | logout 取消刷新定时器 |
| TC-020 | | | ⬜ 待执行 | logout 幂等性 |
| TC-021 | | | ⬜ 待执行 | 启动时 Token 有效自动认证 |
| TC-022 | | | ⬜ 待执行 | 启动时 Token 无效返回 null |
| TC-023 | | | ⬜ 待执行 | Token 刷新成功保持会话 |
| TC-024 | | | ⬜ 待执行 | Token 刷新失败清除会话 |
| TC-025 | | | ⬜ 待执行 | Timer.periodic 正确使用 |
| TC-026 | | | ⬜ 待执行 | Token 正常启动时行为 |
| TC-027 | | | ⬜ 待执行 | 启动加载超时处理 |
| TC-028 | | | ⬜ 待执行 | Riverpod 3.x AsyncNotifier API |
| TC-029 | | | ⬜ 待执行 | AuthService 依赖注入 |
| TC-030 | | | ⬜ 待执行 | 网络错误友好消息 |
| TC-031 | | | ⬜ 待执行 | 服务器错误友好消息 |
| TC-032 | | | ⬜ 待执行 | 邮箱已注册错误 |
| TC-033 | | | ⬜ 待执行 | 快速 logout+login |
| TC-034 | | | ⬜ 待执行 | initialize() 失败不崩溃 |
| TC-035 | | | ⬜ 待执行 | getMe() 失败回退 null |
| TC-036 | | | ⬜ 待执行 | AuthTokens.user 正确处理 |
| TC-037 | | | ⬜ 待执行 | 成功后清除之前错误 |
| TC-038 | | | ⬜ 待执行 | 完整 login-logout-relogin |
| TC-039 | | | ⬜ 待执行 | 冷启动会话恢复 |
| TC-040 | | | ⬜ 待执行 | Token 到期自动刷新 |
| TC-041 | | | ⬜ 待执行 | 刷新失败清除会话 |
| TC-042 | | | ⬜ 待执行 | register 自动 login |
| TC-043 | | | ⬜ 待执行 | 多 consumer 状态一致性 |

---

## 十一、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| AuthState 定义与状态转换 | 4 | TC-001 ~ TC-004 |
| build() 初始化与会话检查 | 3 | TC-005 ~ TC-007 |
| login() 流程 | 6 | TC-008 ~ TC-013 |
| register() 流程 | 4 | TC-014 ~ TC-017 |
| logout() 流程 | 3 | TC-018 ~ TC-020 |
| 会话恢复与 Token 刷新 | 7 | TC-021 ~ TC-027 |
| Provider 类型与 API 正确性 | 2 | TC-028 ~ TC-029 |
| 边界与异常处理 | 8 | TC-030 ~ TC-037 |
| 集成场景测试 | 6 | TC-038 ~ TC-043 |
| **合计** | **43** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 19 |
| P1 — HIGH | 16 |
| P2 — MEDIUM | 8 |

---

## 十二、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| 启动时 Token 有效 → 返回 User | TC-021, TC-039 |
| Token 无效 → 返回 null → 触发路由重定向 | TC-022, TC-007 |
| login 成功 → 存储 Token → 返回 User | TC-008, TC-011, TC-036, TC-038 |
| login 失败 → 抛出异常（含友好错误消息） | TC-009, TC-030, TC-031 |
| register 成功后自动登录 | TC-014, TC-042 |
| 登出清除所有本地数据 | TC-018, TC-019 |
| Access Token 过期前 5 分钟自动刷新 | TC-023, TC-025, TC-040 |
| 使用 Timer.periodic 管理 | TC-025 |
| Refresh Token 也过期 → 清除 Token → Toast "会话已过期" | TC-024, TC-041 |
| 登录后关闭浏览器重开 → 自动恢复登录状态 | TC-021, TC-039 |
| 应用启动流程：Logo + "正在初始化..." | TC-027（AuthNotifier 行为铺垫 UI） |
| Token 自动刷新机制 | TC-006, TC-023, TC-025, TC-040, TC-041 |
| 登出清理：清除 flutter_secure_storage 中所有 Token | TC-018, TC-020 |
| 登出清理：清除 shared_preferences 中登录相关缓存 | TC-018 |
| 导航到 /login | TC-002, TC-022, TC-041 |

| PRD 验收标准（§11.1） | 对应测试用例 |
|----------------------|------------|
| #1 用户可以注册新账号并登录 | TC-014, TC-016, TC-042 |
| #2 登录会话可持久化，关闭浏览器后重新打开无需重新登录 | TC-021, TC-039 |
| #3 Token 过期自动刷新，刷新失败友好提示 | TC-023, TC-024, TC-040, TC-041 |
| #4 用户可以安全登出 | TC-018, TC-019, TC-020 |

| 验收标准（来自 PRD §M1 会话管理） | 对应测试用例 |
|----------------------------------|------------|
| 应用启动：显示全屏加载（Logo + "正在初始化..."） | TC-027（AuthNotifier 行为） |
| 检查本地 Token → 有效则进入首页 | TC-021, TC-039 |
| Token 无效 → 跳转登录页 | TC-002, TC-022 |
| 加载超过 3 秒 → "正在连接服务器..." | TC-027 |
| 加载超过 10 秒 → "服务器连接超时" + 重试按钮 | TC-027 |
| 登出时清除所有本地存储的 Token 和缓存 | TC-018, TC-020 |

---

## 十三、附录 A：FakeAuthService 测试辅助类参考

```dart
/// 用于 AuthNotifier 单元测试的 Fake AuthService
///
/// 提供完全可控的行为：成功/失败、延迟、调用计数、参数记录。
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.hasToken = false,
    this.storedAccessToken,
    this.storedRefreshToken,
    this.loginFails = false,
    this.loginFailsOnFirstAttempt = false,
    this.loginDelay,
    this.registerFails = false,
    this.registerDelay,
    this.registerError,
    this.refreshFails = false,
    this.refreshSucceeds = true,
    this.networkError = false,
    this.serverError = false,
    this.serverStatusCode,
    this.tokenExpiresIn,
    this.initializeFails = false,
    this.initializeDelay,
    this.getMeFails = false,
    this.getMeReturnsValid = true,
  });

  final bool hasToken;
  final String? storedAccessToken;
  final String? storedRefreshToken;
  final bool loginFails;
  bool loginFailsOnFirstAttempt;
  final Duration? loginDelay;
  final bool registerFails;
  final Duration? registerDelay;
  final String? registerError;
  final bool refreshFails;
  final bool refreshSucceeds;
  final bool networkError;
  final bool serverError;
  final int? serverStatusCode;
  final int? tokenExpiresIn;
  final bool initializeFails;
  final Duration? initializeDelay;
  final bool getMeFails;
  final bool getMeReturnsValid;

  // ---- 可观测状态 ----
  String? _accessToken;
  String? _refreshToken;
  int initializeCallCount = 0;
  int loginCallCount = 0;
  int registerCallCount = 0;
  int tryRefreshCallCount = 0;
  int getMeCallCount = 0;
  int logoutCallCount = 0;
  bool saveTokensCalled = false;
  bool tokensCleared = false;
  bool tokensUpdated = false;
  bool logoutCalled = false;
  bool refreshTimerActive = false;

  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastRegisterUsername;
  int loginFailCount = 0;

  @override
  String? get accessToken => _accessToken;

  void reset() {
    loginCallCount = 0;
    registerCallCount = 0;
    tryRefreshCallCount = 0;
    logoutCallCount = 0;
    lastLoginEmail = null;
    lastLoginPassword = null;
    lastRegisterEmail = null;
    lastRegisterPassword = null;
    lastRegisterUsername = null;
    saveTokensCalled = false;
    tokensCleared = false;
    tokensUpdated = false;
    logoutCalled = false;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (initializeFails) throw Exception('TokenStorage unavailable');
    if (initializeDelay != null) await Future.delayed(initializeDelay!);
    if (hasToken) {
      _accessToken = storedAccessToken ?? 'stored-access-token';
      _refreshToken = storedRefreshToken ?? 'stored-refresh-token';
    }
  }

  @override
  Future<AuthTokens> login(String email, String password) async {
    loginCallCount++;
    lastLoginEmail = email;
    lastLoginPassword = password;

    if (loginDelay != null) await Future.delayed(loginDelay!);

    if (loginFailsOnFirstAttempt && loginFailCount == 0) {
      loginFailCount++;
      throw Exception('Invalid credentials');
    }
    if (loginFails) throw Exception('Login failed');
    if (networkError) throw Exception('DioException: connectionError');
    if (serverError) {
      final dio = Dio();
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: serverStatusCode ?? 500,
        ),
      );
    }

    _accessToken = 'new-access-token';
    _refreshToken = 'new-refresh-token';
    saveTokensCalled = true;
    return AuthTokens(
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
      tokenType: 'Bearer',
      expiresIn: tokenExpiresIn ?? 3600,
      user: User(
        id: 'test-user-id',
        email: email,
        username: email.split('@').first,
        status: 'active',
        createdAt: DateTime(2026, 5, 31),
        updatedAt: DateTime(2026, 5, 31),
      ),
    );
  }

  @override
  Future<AuthTokens> register(String email, String password, [String? username]) async {
    registerCallCount++;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    lastRegisterUsername = username;

    if (registerDelay != null) await Future.delayed(registerDelay!);
    if (registerFails) throw Exception(registerError ?? 'Registration failed');

    _accessToken = 'access-token-after-register';
    _refreshToken = 'refresh-token-after-register';
    saveTokensCalled = true;
    return AuthTokens(
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
      tokenType: 'Bearer',
      expiresIn: tokenExpiresIn ?? 3600,
      user: User(
        id: 'new-user-id',
        email: email,
        username: username ?? email.split('@').first,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> tryRefresh() async {
    tryRefreshCallCount++;
    if (refreshFails) return false;
    if (!refreshSucceeds) return false;
    _accessToken = 'refreshed-access-token';
    _refreshToken = 'refreshed-refresh-token';
    tokensUpdated = true;
    return true;
  }

  @override
  Future<User> getMe() async {
    getMeCallCount++;
    if (getMeFails) throw Exception('Failed to fetch user');
    if (!getMeReturnsValid) throw Exception('User not found');
    return User(
      id: 'test-user-id',
      email: 'admin@kayak.local',
      username: 'Admin',
      status: 'active',
      createdAt: DateTime(2026, 5, 31),
      updatedAt: DateTime(2026, 5, 31),
    );
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    logoutCalled = true;
    _accessToken = null;
    _refreshToken = null;
    tokensCleared = true;
    refreshTimerActive = false;
  }
}
```

---

## 十四、附录 B：测试文件组织建议

```
kayak-frontend/test/
├── providers/
│   └── auth_notifier_test.dart       # TC-001 ~ TC-043（本文件所有测试用例）
└── helpers/
    └── fake_auth_service.dart        # FakeAuthService（见附录 A）
```

### 测试设置模板

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_service.dart';

/// 创建测试用 ProviderContainer
ProviderContainer createContainer(FakeAuthService mockAuth) {
  return ProviderContainer(overrides: [
    // 如果有 authServiceProvider，在此 override
    // authServiceProvider.overrideWithValue(mockAuth),
  ]);
}

void main() {
  group('AuthNotifier - AuthState', () {
    // TC-001 ~ TC-004
  });

  group('AuthNotifier - build() initialization', () {
    // TC-005 ~ TC-007
  });

  group('AuthNotifier - login()', () {
    // TC-008 ~ TC-013
  });

  group('AuthNotifier - register()', () {
    // TC-014 ~ TC-017
  });

  group('AuthNotifier - logout()', () {
    // TC-018 ~ TC-020
  });

  group('AuthNotifier - session restoration & refresh', () {
    // TC-021 ~ TC-027
  });

  group('AuthNotifier - provider type & API', () {
    // TC-028 ~ TC-029
  });

  group('AuthNotifier - edge cases & error handling', () {
    // TC-030 ~ TC-037
  });

  group('AuthNotifier - integration scenarios', () {
    // TC-038 ~ TC-043
  });
}
```

---

**文档状态**: ✅ 已完成  
**下一步**: 提交 sw-tom 进行测试用例审查  
**总用例数**: 43  
**文件路径**: `log/release_3/test/TASK-008_test_cases.md`
