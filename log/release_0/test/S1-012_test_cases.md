# S1-012 测试用例文档 - 认证状态管理与路由守卫

**版本**: 1.0  
**创建日期**: 2026-03-20  
**任务**: S1-012 认证状态管理与路由守卫  
**技术栈**: Flutter / Riverpod / go_router

---

## 1. 测试概述

### 1.1 测试范围

本测试文档涵盖认证状态管理与路由守卫 (S1-012) 的所有功能测试，包括：
- 全局认证状态管理（登录状态、用户信息、Token存储）
- 路由守卫（未登录用户重定向到登录页）
- Token自动刷新机制
- 页面刷新后登录状态保持

### 1.2 测试环境

| 项目 | 说明 |
|------|------|
| **Flutter SDK** | 3.x stable |
| **状态管理** | Riverpod |
| **路由** | go_router |
| **Token存储** | SecureStorage / SharedPreferences |
| **依赖任务** | S1-011 (登录页面UI实现) |

### 1.3 测试用例统计

| 类别 | 用例数量 |
|------|----------|
| 认证状态持久化测试 | 5 |
| 路由守卫测试 | 6 |
| Token自动刷新测试 | 6 |
| 状态管理单元测试 | 4 |
| 集成测试 | 3 |
| **总计** | **24** |

---

## 2. 认证状态持久化测试 (TC-S1-012-01 ~ TC-S1-012-05)

### TC-S1-012-01: 登录成功后Token存储测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-01 |
| **用例名称** | 登录成功后Token存储测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 用户成功登录，获取到Access Token和Refresh Token |
| **测试步骤** | 1. 调用登录方法<br>2. 检查Token存储调用 |
| **预期结果** | Access Token和Refresh Token被正确存储到SecureStorage |
| **自动化代码** | `verify(mockSecureStorage.write('access_token', any)).called(1);`<br>`verify(mockSecureStorage.write('refresh_token', any)).called(1);` |

### TC-S1-012-02: 页面刷新后恢复登录状态测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-02 |
| **用例名称** | 页面刷新后恢复登录状态测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，Token已存储 |
| **测试步骤** | 1. 模拟页面刷新（App重新启动）<br>2. 检查authProvider初始化状态 |
| **预期结果** | authProvider.isAuthenticated = true，用户信息被恢复 |
| **自动化代码** | `await prefs.setString('access_token', 'valid_token');`<br>`await prefs.setString('refresh_token', 'valid_refresh_token');`<br>`await app.restart();`<br>`expect(authProvider.isAuthenticated, isTrue);`<br>`expect(authProvider.user, isNotNull);` |

### TC-S1-012-03: 刷新后恢复用户信息测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-03 |
| **用例名称** | 刷新后恢复用户信息测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，Token和用户信息已存储 |
| **测试步骤** | 1. 模拟应用重启<br>2. 检查用户信息恢复 |
| **预期结果** | 用户ID、邮箱、名称等信息正确恢复 |
| **自动化代码** | `expect(authProvider.user?.id, equals('user_123'));`<br>`expect(authProvider.user?.email, equals('test@example.com'));` |

### TC-S1-012-04: 无Token时初始状态测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-04 |
| **用例名称** | 无Token时初始状态测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 应用首次启动，无任何存储数据 |
| **测试步骤** | 1. 启动应用<br>2. 检查authProvider初始状态 |
| **预期结果** | isAuthenticated = false，user = null |
| **自动化代码** | `expect(authProvider.isAuthenticated, isFalse);`<br>`expect(authProvider.user, isNull);` |

### TC-S1-012-05: 登出后清除Token测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-05 |
| **用例名称** | 登出后清除Token测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，Token已存储 |
| **测试步骤** | 1. 调用logout方法<br>2. 检查Token清除 |
| **预期结果** | Access Token和Refresh Token被清除 |
| **自动化代码** | `await authNotifier.logout();`<br>`verify(mockSecureStorage.delete('access_token')).called(1);`<br>`verify(mockSecureStorage.delete('refresh_token')).called(1);` |

---

## 3. 路由守卫测试 (TC-S1-012-06 ~ TC-S1-012-11)

### TC-S1-012-06: 未登录访问受保护页面重定向测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-06 |
| **用例名称** | 未登录访问受保护页面重定向测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户未登录（无Token） |
| **测试步骤** | 1. 直接导航到受保护页面 /home<br>2. 检查路由变化 |
| **预期结果** | 自动重定向到 /login |
| **自动化代码** | `await router.go('/home');`<br>`await pump();`<br>`expect(router.currentPath, equals('/login'));` |

### TC-S1-012-07: 已登录用户访问受保护页面正常访问测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-07 |
| **用例名称** | 已登录用户访问受保护页面正常访问测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，Token有效 |
| **测试步骤** | 1. 用户已认证状态<br>2. 导航到受保护页面 /home |
| **预期结果** | 正常访问，不重定向 |
| **自动化代码** | `authProvider.setAuthenticated(testUser, 'valid_token');`<br>`await router.go('/home');`<br>`expect(router.currentPath, equals('/home'));` |

### TC-S1-012-08: 已登录用户访问登录页重定向测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-08 |
| **用例名称** | 已登录用户访问登录页重定向测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 用户已认证状态<br>2. 导航到 /login |
| **预期结果** | 重定向到首页 /home |
| **自动化代码** | `authProvider.setAuthenticated(testUser, 'valid_token');`<br>`await router.go('/login');`<br>`expect(router.currentPath, equals('/home'));` |

### TC-S1-012-09: 路由守卫对所有受保护路由生效测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-09 |
| **用例名称** | 路由守卫对所有受保护路由生效测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户未登录 |
| **测试步骤** | 1. 尝试访问 /home<br>2. 尝试访问 /workbench/1<br>3. 尝试访问 /settings |
| **预期结果** | 所有受保护路由都重定向到 /login |
| **自动化代码** | `for (final path in ['/home', '/workbench/1', '/settings']) {`<br>`  await router.go(path);`<br>`  expect(router.currentPath, equals('/login'));`<br>`}` |

### TC-S1-012-10: 公共路由无需认证直接访问测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-10 |
| **用例名称** | 公共路由无需认证直接访问测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 用户未登录 |
| **测试步骤** | 1. 访问公共路由 /login<br>2. 访问公共路由 /register |
| **预期结果** | 可正常访问公共路由 |
| **自动化代码** | `await router.go('/login');`<br>`expect(router.currentPath, equals('/login'));`<br>`await router.go('/register');`<br>`expect(router.currentPath, equals('/register'));` |

### TC-S1-012-11: 登录后返回原始请求页面测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-11 |
| **用例名称** | 登录后返回原始请求页面测试 |
| **测试类型** | Integration Test |
| **优先级** | P2 |
| **前置条件** | 用户未登录，尝试访问 /workbench/1 |
| **测试步骤** | 1. 访问受保护页面被重定向到 /login<br>2. 执行登录<br>3. 检查最终路由 |
| **预期结果** | 登录成功后返回原始请求的 /workbench/1 |
| **自动化代码** | `await router.go('/workbench/1');`<br>`expect(router.currentPath, equals('/login'));`<br>`await authNotifier.login('test@example.com', 'password');`<br>`expect(router.currentPath, equals('/workbench/1'));` |

---

## 4. Token自动刷新测试 (TC-S1-012-12 ~ TC-S1-012-17)

### TC-S1-012-12: Token过期前自动刷新测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-12 |
| **用例名称** | Token过期前自动刷新测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，Access Token即将过期（例如：剩余5分钟） |
| **测试步骤** | 1. 设置Access Token剩余5分钟过期<br>2. 发起API请求<br>3. 检查refreshToken调用 |
| **预期结果** | 自动调用refreshToken接口，获取新Token |
| **自动化代码** | `when(mockAuthApi.refreshToken('refresh_token')).thenAnswer((_) async => NewTokenPair(...));`<br>`await apiClient.request('/protected endpoint');`<br>`verify(mockAuthApi.refreshToken('refresh_token')).called(1);` |

### TC-S1-012-13: Token刷新后重试原请求测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-13 |
| **用例名称** | Token刷新后重试原请求测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | Access Token已过期，Refresh Token有效 |
| **测试步骤** | 1. 发起API请求（401错误）<br>2. 自动刷新Token<br>3. 重试原请求 |
| **预期结果** | 原请求使用新Token成功执行 |
| **自动化代码** | `when(mockApi.get('/data')).thenThrow(UnauthizedException());`<br>`when(mockAuthApi.refreshToken(any)).thenAnswer((_) async => NewTokenPair(...));`<br>`when(mockApi.get('/data')).thenAnswer((_) async => Response200(...));`<br>`await apiClient.request('/data');`<br>`verify(mockApi.get('/data')).called(2);` |

### TC-S1-012-14: Refresh Token也过期时跳转登录测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-14 |
| **用例名称** | Refresh Token也过期时跳转登录测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | Refresh Token已过期 |
| **测试步骤** | 1. 发起API请求<br>2. 刷新Token失败（401）<br>3. 检查路由变化 |
| **预期结果** | 清除本地Token，重定向到 /login |
| **自动化代码** | `when(mockAuthApi.refreshToken('expired_refresh')).thenThrow(UnauthizedException());`<br>`await apiClient.request('/protected');`<br>`expect(authProvider.isAuthenticated, isFalse);`<br>`expect(router.currentPath, equals('/login'));` |

### TC-S1-012-15: Token刷新间隔限制测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-15 |
| **用例名称** | Token刷新间隔限制测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | Token刷新刚完成 |
| **测试步骤** | 1. 短时间内发起多个API请求<br>2. 检查刷新调用次数 |
| **预期结果** | Token刷新在短时间内只执行一次（防抖） |
| **自动化代码** | `await apiClient.request('/endpoint1');`<br>`await apiClient.request('/endpoint2');`<br>`await Future.delayed(Duration(milliseconds: 100));`<br>`verify(mockAuthApi.refreshToken(any)).called(1);` |

### TC-S1-012-16: 并发请求时Token刷新不重复测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-16 |
| **用例名称** | 并发请求时Token刷新不重复测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 多个并发请求同时触发Token刷新 |
| **测试步骤** | 1. 同时发起5个API请求<br>2. 所有请求都返回401<br>3. 检查刷新调用次数 |
| **预期结果** | Token刷新只执行一次，其他请求等待刷新完成后重试 |
| **自动化代码** | `when(mockApi.get('/data')).thenThrow(UnauthizedException());`<br>`await Future.wait([`<br>`  apiClient.request('/data'),`<br>`  apiClient.request('/data'),`<br>`  apiClient.request('/data'),`<br>`]);`<br>`verify(mockAuthApi.refreshToken(any)).called(1);` |

### TC-S1-012-17: Token刷新时使用最新的Refresh Token测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-17 |
| **用例名称** | Token刷新时使用最新的Refresh Token测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 连续多次刷新Token |
| **测试步骤** | 1. 第一次刷新获取新Token对<br>2. 第二次刷新使用最新的refresh_token |
| **预期结果** | 每次刷新都使用最新的refresh_token |
| **自动化代码** | `when(mockAuthApi.refreshToken('refresh_1')).thenAnswer((_) async => NewTokenPair('access_2', 'refresh_2'));`<br>`when(mockAuthApi.refreshToken('refresh_2')).thenAnswer((_) async => NewTokenPair('access_3', 'refresh_3'));`<br>`await tokenManager.refresh();`<br>`await tokenManager.refresh();`<br>`verifyInOrder([`<br>`  mockAuthApi.refreshToken('refresh_1'),`<br>`  mockAuthApi.refreshToken('refresh_2'),`<br>`]);` |

---

## 5. 状态管理单元测试 (TC-S1-012-18 ~ TC-S1-012-21)

### TC-S1-012-18: AuthProvider初始状态测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-18 |
| **用例名称** | AuthProvider初始状态测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 无 |
| **测试步骤** | 1. 创建AuthProvider实例<br>2. 检查初始状态 |
| **预期结果** | isAuthenticated=false, isLoading=false, user=null, error=null |
| **自动化代码** | `final authProvider = AuthProvider();`<br>`expect(authProvider.isAuthenticated, isFalse);`<br>`expect(authProvider.isLoading, isFalse);`<br>`expect(authProvider.user, isNull);`<br>`expect(authProvider.error, isNull);` |

### TC-S1-012-19: AuthProvider登录状态切换测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-19 |
| **用例名称** | AuthProvider登录状态切换测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | AuthProvider初始化 |
| **测试步骤** | 1. 设置用户已认证状态<br>2. 检查状态变化 |
| **预期结果** | isAuthenticated=true, user=用户信息 |
| **自动化代码** | `await authProvider.setAuthenticated(testUser, 'token');`<br>`expect(authProvider.isAuthenticated, isTrue);`<br>`expect(authProvider.user, equals(testUser));` |

### TC-S1-012-20: AuthProvider登出状态切换测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-20 |
| **用例名称** | AuthProvider登出状态切换测试 |
| **测试类型** | Unit Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 调用logout方法<br>2. 检查状态变化 |
| **预期结果** | isAuthenticated=false, user=null |
| **自动化代码** | `await authProvider.logout();`<br>`expect(authProvider.isAuthenticated, isFalse);`<br>`expect(authProvider.user, isNull);` |

### TC-S1-012-21: AuthProvider错误状态处理测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-21 |
| **用例名称** | AuthProvider错误状态处理测试 |
| **测试类型** | Unit Test |
| **优先级** | P1 |
| **前置条件** | 认证过程中发生错误 |
| **测试步骤** | 1. 模拟认证失败<br>2. 检查error状态 |
| **预期结果** | error=错误信息, isAuthenticated=false |
| **自动化代码** | `await authProvider.login('invalid', 'creds');`<br>`expect(authProvider.error, isNotNull);`<br>`expect(authProvider.isAuthenticated, isFalse);` |

---

## 6. 集成测试 (TC-S1-012-22 ~ TC-S1-012-24)

### TC-S1-012-22: 完整登录流程状态管理测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-22 |
| **用例名称** | 完整登录流程状态管理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 应用启动，未登录 |
| **测试步骤** | 1. 导航到 /login<br>2. 输入有效凭证<br>3. 点击登录<br>4. 检查状态和路由 |
| **预期结果** | 登录成功，authProvider.isAuthenticated=true，路由跳转到 /home |
| **自动化代码** | `await router.go('/login');`<br>`await tester.enterText(emailField, 'test@example.com');`<br>`await tester.enterText(passwordField, 'password123');`<br>`await tester.tap(loginButton);`<br>`expect(authProvider.isAuthenticated, isTrue);`<br>`expect(router.currentPath, equals('/home'));` |

### TC-S1-012-23: 完整登出流程状态管理测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-23 |
| **用例名称** | 完整登出流程状态管理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 在首页点击登出<br>2. 确认登出<br>3. 检查状态和路由 |
| **预期结果** | 登出成功，authProvider.isAuthenticated=false，路由跳转到 /login |
| **自动化代码** | `authProvider.setAuthenticated(testUser, 'token');`<br>`await router.go('/home');`<br>`await tester.tap(logoutButton);`<br>`await tester.tap(confirmLogoutButton);`<br>`expect(authProvider.isAuthenticated, isFalse);`<br>`expect(router.currentPath, equals('/login'));` |

### TC-S1-012-24: Token过期场景完整流程测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-012-24 |
| **用例名称** | Token过期场景完整流程测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已登录，Access Token过期 |
| **测试步骤** | 1. 发起API请求<br>2. 服务器返回401<br>3. 自动刷新Token<br>4. 重试请求<br>5. 验证成功 |
| **预期结果** | 请求自动恢复，用户无感知 |
| **自动化代码** | `when(mockApi.get('/data')).thenThrow(UnauthizedException());`<br>`when(mockAuthApi.refreshToken('refresh')).thenAnswer((_) async => NewTokenPair(...));`<br>`final result = await apiClient.request('/data');`<br>`expect(result, isNotNull);`<br>`expect(authProvider.isAuthenticated, isTrue);` |

---

## 7. 测试覆盖率矩阵

| 验收标准 | 相关测试用例 |
|----------|--------------|
| **AC1**: 刷新页面后保持登录状态 | TC-S1-012-01, TC-S1-012-02, TC-S1-012-03, TC-S1-012-04, TC-S1-012-05 |
| **AC2**: 未登录访问受保护页面自动跳转 | TC-S1-012-06, TC-S1-012-07, TC-S1-012-08, TC-S1-012-09, TC-S1-012-10, TC-S1-012-11 |
| **AC3**: Token过期前自动刷新 | TC-S1-012-12, TC-S1-012-13, TC-S1-012-14, TC-S1-012-15, TC-S1-012-16, TC-S1-012-17 |
| **全局认证状态管理** | TC-S1-012-18, TC-S1-012-19, TC-S1-012-20, TC-S1-012-21 |
| **集成验证** | TC-S1-012-22, TC-S1-012-23, TC-S1-012-24 |

---

## 8. 缺陷报告模板

当测试失败时，使用以下模板报告缺陷：

```markdown
## 缺陷报告

**缺陷ID**: BUG-S1-012-XX
**严重级别**: P0/P1/P2/P3
**测试用例**: TC-S1-012-XX
**摘要**: 
**步骤**:
1. 
2. 
**预期结果**: 
**实际结果**: 
**屏幕截图**: 
**环境**: 
```

---

**文档结束**

(End of file - total 407 lines)
