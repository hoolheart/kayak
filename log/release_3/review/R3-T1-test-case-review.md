# R3-T1 测试用例审查报告

**审查者**: sw-tom (开发工程师)  
**审查日期**: 2026-05-30  
**审查对象**: `log/release_3/test/R3-T1-test-cases.md`  

---

## 审查结论：✅ 有条件通过

测试用例设计完整、结构清晰，覆盖了所有 6 个验收标准（AC1-AC6），并且额外覆盖了表单验证和 UI 交互细节。发现 4 个需要关注的问题，均为补充性建议，不影响测试用例的核心有效性。

---

## 验收标准覆盖率矩阵

| 验收标准 | 覆盖用例 | 覆盖情况 |
|---------|---------|---------|
| AC1: 表单提交到后端 | TC-001 | ✅ 详细覆盖 |
| AC2: 成功后重定向到 Dashboard | TC-001 | ✅ 详细覆盖 |
| AC3: 失败时显示用户可读错误 | TC-002, TC-003 | ✅ 多场景覆盖（凭据错/网络错） |
| AC4: 按钮加载状态与防重复点击 | TC-004 | ✅ 详细覆盖 |
| AC5: Token 正确存储 | TC-001, TC-008 | ✅ 双重覆盖 |
| AC6: 已登录用户自动跳转 | TC-005, TC-009 | ✅ 双重覆盖（页面访问+刷新） |

**额外覆盖**：TC-006（空邮箱验证）、TC-007（空密码验证）、TC-010（错误横幅关闭）—— 均属于良好的边界和体验补充。

---

## 问题列表

### 问题 1（中）：TC-008/TC-009 隐含依赖 R3-T3（Token 持久化），未显示声明

**严重程度**: ⚠️ 中  
**类型**: 依赖缺失

**描述**:  
TC-R3-T1-008（Token 存储验证）和 TC-R3-T1-009（页面刷新保持登录状态）需要对 Web 平台的 Token 持久化正常工作。当前代码中 `TokenStorage.create()` 在 Web 平台使用 `flutter_secure_storage`（R3-T3 将其改为 `SharedPrefsTokenStorage`）。如果不先完成 R3-T3，这两个测试用例可能失败——`SecureTokenStorage` 在 Web 上会抛异常，导致整个 `login()` 流程在 token 保存阶段崩溃，而不仅仅是 token 不持久。

**建议**:  
在 TC-008 和 TC-009 的"前置条件"中增加一条明确依赖：
```
4. R3-T3（Web Token 持久化修复）已完成并部署
```

### 问题 2（低）：TC-001 Step 5 后端日志检查缺少操作指引

**严重程度**: 🔵 低  
**类型**: 可执行性

**描述**:  
Step 5 要求检查"后端日志显示 `POST /api/v1/auth/login` 被调用"。使用 kimi-webbridge 浏览器测试时，测试人员需要同时查看后端终端输出。测试文档未提供如何捕获或查看后端日志的操作指引。

**建议**:  
在测试步骤中补充后端日志查看方式（可选），例如在"附录"中添加：
```
### 后端日志检查
后端运行在终端中，日志实时输出。启动方式：`./scripts/start-web.sh`
搜索关键词：`POST /api/v1/auth/login` 或 `INFO`
```

或作为 operator note 直接写在步骤 5 的行内说明中。

### 问题 3（低）：TC-001/TC-004 加载状态预期存在细微差异

**严重程度**: 🔵 低  
**类型**: 预期结果精确性

**描述**:  
TC-001 Step 4 描述"按钮文字从'登录'变为加载动画"，TC-004 Step 3 描述"按钮文字变为 CircularProgressIndicator"。实际代码中（`login_button.dart`），加载状态下按钮使用 `AnimatedSwitcher` 将文字区域完全替换为 `CircularProgressIndicator`，**没有文字**。两个用例的描述略有歧义：

- TC-001 说"文字变为加载动画"——暗示文字变为动画（不正确）
- TC-004 说"按钮文字变为 CircularProgressIndicator"——暗示运行指示器替换了文字（正确）

**建议**:  
统一将 TC-001 Step 4 的预期结果 3 修改为与 TC-004 一致的语言：
```
3. 按钮文字被替换为 CircularProgressIndicator（旋转加载指示器）
```

### 问题 4（低）：缺少 Token 过期场景测试

**严重程度**: 🔵 低  
**类型**: 边界情况遗漏

**描述**:  
所有测试用例均假设 Token 有效或未过期。缺少 Token 过期后自动刷新的场景：
- 页面刷新时 Token 过期 → `AuthStateNotifier.initialize()` 应调用 refresh API
- 如果 refresh 也失败 → 应清除 Token 并重定向到登录页

该场景涉及 `POST /api/v1/auth/refresh` 端点，虽然不是最核心的登录路径，但在长时间使用场景中会触发。

**建议**:  
（可选）如 Sprint 时间允许，可追加一个 P2 测试用例：
- **TC-R3-T1-011**: 登录后等待 Token 过期（或 mock 过期 Token）→ 刷新页面 → 自动刷新 Token → 保持登录状态
- 或在 TC-009 中添加一个子场景（降级方案）

---

## 代码实现对齐分析

以下是从实际代码角度对测试用例的技术可行性评估：

| 测试用例 | 当前状态 | 说明 |
|---------|---------|------|
| TC-001 (正常登录) | ⚠️ 需 R3-T1 实现 | 当前 `_submitForm()` 使用 `Future.delayed` 模拟。R3-T1 需改为调用 `authStateNotifier.login()` 并通过 `authStateProvider` 触发 GoRouter redirect |
| TC-002 (错误密码) | ⚠️ 需 R3-T1 实现 | `AuthStateNotifier.login()` 当前catch所有异常设 `AuthState.error(raw)`。R3-T1 需在 `_submitForm()` 中捕获 DioException 并映射到 `LoginErrorType.invalidCredentials` |
| TC-003 (网络错误) | ⚠️ 需 R3-T1 实现 | 同上，需映射 `DioExceptionType.connectionTimeout` 等为 `LoginErrorType.networkError` |
| TC-004 (加载状态) | ✅ 已有代码支持 | `login_button.dart` 和 `login_form.dart` 已有 isValid / enabled / loading 逻辑 |
| TC-005 (自动跳转) | ✅ 已有代码支持 | `app_router.dart` 行 138-142 路由守卫已实现，依赖 `authStateProvider` |
| TC-006/007 (表单验证) | ✅ 已有代码支持 | `_submitForm()` 行 73-83 已有验证逻辑，在 API 调用前返回 |
| TC-008 (Token 存储) | ⚠️ 需 R3-T3 | `AuthStateNotifier.login()` 已调用 `saveTokens()`，但 Web 平台可能因 `flutter_secure_storage` 失败 |
| TC-009 (刷新保持) | ⚠️ 需 R3-T3 | 同上，`initialize()` 需要从持久化存储恢复 Token |
| TC-010 (错误横幅关闭) | ✅ 已有代码支持 | `error_banner.dart` + `login_view.dart` 行 87-97 已有关闭逻辑 |

**关键发现**: R3-T1 的实现核心是修改 `login_form.dart` 的 `_submitForm()` —— 移除 mock 逻辑，调用 `authStateNotifier.login()` 并做错误映射。测试用例 TC-002/TC-003 中期望的错误消息（"邮箱或密码错误"、"网络错误，请检查网络连接"）需要 `_submitForm()` 正确地将 Dio 异常映射到 `LoginErrorType`，然后用 `loginProvider.notifier.setError(type)` 设置。该实现方案可行，与测试用例一致。

---

## 总结

| 维度 | 评价 |
|------|------|
| AC 覆盖率 | ✅ 100%（AC1-AC6 全部覆盖） |
| 用例结构 | ✅ 清晰，步骤明确，预期结果具体 |
| 前置条件 | ⚠️ 需补充 R3-T3 依赖声明 |
| 边界覆盖 | ✅ 较全面（空表单、网络错误、防重复点击、横幅关闭） |
| 可实施性 | ✅ 测试用例与当前代码架构一致，实现后即可测试 |
| 测试方法 | ✅ kimi-webbridge + 截图，操作参考附录有用 |
| 优先级划分 | ✅ P0/P1/P2 合理，核心流程优先 |

**审查结论**: ✅ 有条件通过。建议修复问题 1（依赖声明）和问题 2（操作指引），问题 3 和问题 4 视 Sprint 时间酌情处理。

---
*审查结束*
