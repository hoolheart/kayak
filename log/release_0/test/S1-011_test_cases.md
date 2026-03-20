# S1-011 测试用例文档 - 登录页面UI实现

**版本**: 1.0  
**创建日期**: 2026-03-20  
**任务**: S1-011 登录页面UI实现  
**技术栈**: Flutter / Material Design 3

---

## 1. 测试概述

### 1.1 测试范围

本测试文档涵盖登录页面 (Login Page) 的所有功能测试，包括：
- UI组件渲染
- 表单验证
- 登录状态管理
- 主题切换 (浅色/深色)
- 导航和错误处理
- 无障碍访问

### 1.2 测试环境

| 项目 | 说明 |
|------|------|
| **Flutter SDK** | 3.x stable |
| **状态管理** | Riverpod |
| **路由** | go_router |
| **主题** | Material Design 3 |

### 1.3 测试用例统计

| 类别 | 用例数量 |
|------|----------|
| UI组件测试 | 4 |
| 表单验证测试 | 7 |
| 登录状态测试 | 7 |
| 主题支持测试 | 4 |
| 导航测试 | 3 |
| 错误处理测试 | 5 |
| 无障碍测试 | 5 |
| 登录失败测试 | 1 |
| **总计** | **36** |

---

## 2. UI组件测试 (TC-S1-011-01 ~ TC-S1-011-04)

### TC-S1-011-01: 邮箱输入框渲染测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-01 |
| **用例名称** | 邮箱输入框渲染测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 渲染登录页面<br>2. 查找邮箱输入框 (TextField with email keyboard) |
| **预期结果** | 邮箱输入框正确显示，包含 "Email" 或 "邮箱" label |
| **自动化代码** | `expect(find.byType(TextField).first, findsOneWidget);` |

### TC-S1-011-02: 密码输入框渲染测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-02 |
| **用例名称** | 密码输入框渲染测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 渲染登录页面<br>2. 查找密码输入框 (obscureText: true) |
| **预期结果** | 密码输入框正确显示，文字被遮蔽 |
| **自动化代码** | `expect(passwordField, findsOneWidget);`<br>`expect(passwordField.obscureText, isTrue);` |

### TC-S1-011-03: 登录按钮渲染测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-03 |
| **用例名称** | 登录按钮渲染测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 渲染登录页面<br>2. 查找登录按钮 (Material Design 3 FilledButton) |
| **预期结果** | 登录按钮正确显示，使用 FilledButton 组件，包含 "Login" 或 "登录" 文字 |
| **自动化代码** | `expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);` |

### TC-S1-011-04: Material Design 3样式合规测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-04 |
| **用例名称** | Material Design 3样式合规测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 渲染登录页面<br>2. 检查组件是否使用 MD3 组件 |
| **预期结果** | 使用 FilledButton、TextField 等 MD3 组件 |
| **自动化代码** | `expect(find.byType(FilledButton), findsOneWidget);`<br>`expect(find.byType(TextField), findsNWidgets(2));` |

---

## 3. 表单验证测试 (TC-S1-011-05 ~ TC-S1-011-11)

### TC-S1-011-05: 空邮箱显示验证错误

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-05 |
| **用例名称** | 空邮箱显示验证错误 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 不输入邮箱<br>2. 点击登录按钮 |
| **预期结果** | 显示 "Email is required" 或 "邮箱不能为空" 错误 |
| **自动化代码** | `await tester.tap(loginButton);`<br>`expect(find.text('Email is required'), findsOneWidget);` |

### TC-S1-011-06: 无效邮箱格式显示验证错误

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-06 |
| **用例名称** | 无效邮箱格式显示验证错误 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入无效邮箱 "test@"<br>2. 触发验证 |
| **预期结果** | 显示 "Invalid email format" 或 "邮箱格式无效" 错误 |
| **自动化代码** | `await tester.enterText(emailField, 'test@');`<br>`expect(find.text('Invalid email format'), findsOneWidget);` |

### TC-S1-011-07: 空密码显示验证错误

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-07 |
| **用例名称** | 空密码显示验证错误 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入有效邮箱<br>2. 不输入密码<br>3. 点击登录按钮 |
| **预期结果** | 显示 "Password is required" 或 "密码不能为空" 错误 |
| **自动化代码** | `await tester.tap(loginButton);`<br>`expect(find.text('Password is required'), findsOneWidget);` |

### TC-S1-011-08: 实时验证反馈测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-08 |
| **用例名称** | 实时验证反馈测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入无效邮箱<br>2. 离开邮箱输入框 |
| **预期结果** | 立即显示验证错误，无需提交 |
| **自动化代码** | `await tester.enterText(emailField, 'invalid');`<br>`await tester.testTextField.focusedNode.unfocus();`<br>`expect(find.text('Invalid email format'), findsOneWidget);` |

### TC-S1-011-09: 验证错误时按钮禁用测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-09 |
| **用例名称** | 验证错误时按钮禁用测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成，存在验证错误（例如：邮箱为空或格式错误） |
| **测试步骤** | 1. 清空邮箱输入框<br>2. 检查登录按钮状态 |
| **预期结果** | 登录按钮被禁用 (enabled = false) |
| **自动化代码** | `await tester.enterText(emailField, '');`<br>`expect(tester.widget<FilledButton>(loginButton).enabled, isFalse);` |

### TC-S1-011-10: 有效邮箱通过验证测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-10 |
| **用例名称** | 有效邮箱通过验证测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入有效邮箱 "test@example.com"<br>2. 检查验证状态 |
| **预期结果** | 不显示邮箱错误 |
| **自动化代码** | `await tester.enterText(emailField, 'test@example.com');`<br>`expect(find.text('Invalid email format'), findsNothing);` |

### TC-S1-011-11: 有效密码通过验证测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-11 |
| **用例名称** | 有效密码通过验证测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入密码 "password123"<br>2. 检查验证状态 |
| **预期结果** | 不显示密码错误 |
| **自动化代码** | `await tester.enterText(passwordField, 'password123');`<br>`expect(find.text('Password is required'), findsNothing);` |

---

## 4. 登录状态测试 (TC-S1-011-12 ~ TC-S1-011-18)

### TC-S1-011-12: 空闲状态测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-12 |
| **用例名称** | 空闲状态测试 |
| **测试类型** | State Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 渲染登录页面<br>2. 检查初始状态 |
| **预期结果** | 状态为 idle，不显示加载指示器 |
| **自动化代码** | `expect(loginState, equals(LoginState.idle));`<br>`expect(find.byType(CircularProgressIndicator), findsNothing);` |

### TC-S1-011-13: 加载状态测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-13 |
| **用例名称** | 加载状态测试 |
| **测试类型** | State Test |
| **优先级** | P0 |
| **前置条件** | 登录请求发送 |
| **测试步骤** | 1. 提交有效表单<br>2. 等待响应 |
| **预期结果** | 显示 CircularProgressIndicator |
| **自动化代码** | `await tester.tap(loginButton);`<br>`expect(find.byType(CircularProgressIndicator), findsOneWidget);` |

### TC-S1-011-14: 成功状态导航测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-14 |
| **用例名称** | 成功状态导航测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 登录成功响应 |
| **测试步骤** | 1. 提交有效表单<br>2. 等待登录成功 |
| **预期结果** | 导航到首页 /home |
| **自动化代码** | `await providerContainer.read(loginProvider.notifier).login(...);`<br>`expect(router.currentLocation, equals('/home'));` |

### TC-S1-011-15: 无效凭证错误测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-15 |
| **用例名称** | 无效凭证错误测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入错误邮箱/密码<br>2. 提交表单 |
| **预期结果** | 显示 "Invalid email or password" 或类似错误 |
| **自动化代码** | `expect(find.text('Invalid email or password'), findsOneWidget);` |

### TC-S1-011-16: 网络错误测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-16 |
| **用例名称** | 网络错误测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 网络不可用 |
| **测试步骤** | 1. 模拟网络错误<br>2. 提交表单 |
| **预期结果** | 显示 "Network error. Please try again." |
| **自动化代码** | `expect(find.text('Network error. Please try again.'), findsOneWidget);` |

### TC-S1-011-17: 加载状态按钮禁用测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-17 |
| **用例名称** | 加载状态按钮禁用测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 登录请求进行中（模拟延迟） |
| **测试步骤** | 1. 输入有效邮箱和密码<br>2. 提交表单后立即检查按钮状态 |
| **预期结果** | 登录按钮被禁用，防止重复提交 |
| **自动化代码** | `await tester.tap(loginButton);`<br>`expect(tester.widget<FilledButton>(loginButton).enabled, isFalse);` |

### TC-S1-011-18: 状态转换测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-18 |
| **用例名称** | 状态转换测试 |
| **测试类型** | State Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 提交表单 (idle -> loading)<br>2. 等待响应 (loading -> success/error) |
| **预期结果** | 状态正确转换 |
| **自动化代码** | `expect(loginStateSequence, equals([LoginState.idle, LoginState.loading, LoginState.success]));` |

---

## 5. 主题支持测试 (TC-S1-011-19 ~ TC-S1-011-22)

### TC-S1-011-19: 浅色主题渲染测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-19 |
| **用例名称** | 浅色主题渲染测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 应用使用浅色主题 |
| **测试步骤** | 1. 设置浅色主题<br>2. 渲染登录页面 |
| **预期结果** | 页面使用浅色主题配置 |
| **自动化代码** | `expect(Theme.of(context).brightness, equals(Brightness.light));` |

### TC-S1-011-20: 深色主题渲染测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-20 |
| **用例名称** | 深色主题渲染测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 应用使用深色主题 |
| **测试步骤** | 1. 设置深色主题<br>2. 渲染登录页面 |
| **预期结果** | 页面使用深色主题配置 |
| **自动化代码** | `expect(Theme.of(context).brightness, equals(Brightness.dark));` |

### TC-S1-011-21: 主题切换测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-21 |
| **用例名称** | 主题切换测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成，themeProvider 可用 |
| **测试步骤** | 1. 获取 themeNotifier: `final themeNotifier = ref.read(themeProvider.notifier);`<br>2. 切换主题<br>3. 检查主题变化 |
| **预期结果** | 主题从浅色变为深色或相反 |
| **自动化代码** | `final themeNotifier = ref.read(themeProvider.notifier);`<br>`await themeNotifier.toggleTheme();`<br>`expect(themeNotifier.state.brightness, equals(Brightness.dark));` |

### TC-S1-011-22: 主题持久化测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-22 |
| **用例名称** | 主题持久化测试 |
| **测试类型** | Integration Test |
| **优先级** | P2 |
| **前置条件** | 主题已切换 |
| **测试步骤** | 1. 切换主题<br>2. 重启应用<br>3. 检查主题 |
| **预期结果** | 主题设置保持不变 |
| **自动化代码** | `expect(prefs.getString('theme'), equals('dark'));` |

---

## 6. 导航测试 (TC-S1-011-23 ~ TC-S1-011-25)

### TC-S1-011-23: 登录成功跳转首页测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-23 |
| **用例名称** | 登录成功跳转首页测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 用户已认证 |
| **测试步骤** | 1. 调用登录方法<br>2. 等待导航完成 |
| **预期结果** | 当前路由为 /home |
| **自动化代码** | `await authNotifier.login(email, password);`<br>`expect(router.currentPath, equals('/home'));` |

### TC-S1-011-24: 重定向URL正确性测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-24 |
| **用例名称** | 重定向URL正确性测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 登录成功 |
| **测试步骤** | 1. 登录<br>2. 检查 URL |
| **预期结果** | URL 格式正确: /home |
| **自动化代码** | `expect(uri.path, equals('/home'));` |

### TC-S1-011-25: 登录后返回导航测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-25 |
| **用例名称** | 登录后返回导航测试 |
| **测试类型** | Integration Test |
| **优先级** | P2 |
| **前置条件** | 登录成功后 |
| **测试步骤** | 1. 点击返回按钮<br>2. 检查是否返回登录页 |
| **预期结果** | 无法返回登录页 (已认证用户不能访问) |
| **自动化代码** | `await tester.tap(find.byType(BackButton));`<br>`expect(router.currentPath, equals('/home'));` |

---

## 7. 错误处理测试 (TC-S1-011-26 ~ TC-S1-011-30)

### TC-S1-011-26: 无效凭证优雅处理测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-26 |
| **用例名称** | 无效凭证优雅处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 登录失败 (401) |
| **测试步骤** | 1. 使用错误凭证登录<br>2. 检查错误显示 |
| **预期结果** | 显示用户友好的错误消息，不显示技术细节 |
| **自动化代码** | `expect(find.text('Invalid email or password'), findsOneWidget);`<br>`expect(find.text('401'), findsNothing);` |

### TC-S1-011-27: 网络错误重试选项测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-27 |
| **用例名称** | 网络错误重试选项测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 网络错误发生 |
| **测试步骤** | 1. 模拟网络错误<br>2. 检查是否有重试按钮 |
| **预期结果** | 显示 "Retry" 或 "重试" 按钮 |
| **自动化代码** | `expect(find.text('Retry'), findsOneWidget);` |

### TC-S1-011-28: 服务器错误处理测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-28 |
| **用例名称** | 服务器错误处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 服务器返回 500 |
| **测试步骤** | 1. 模拟服务器错误<br>2. 检查错误显示 |
| **预期结果** | 显示 "Server error. Please try again later." |
| **自动化代码** | `expect(find.text('Server error. Please try again later.'), findsOneWidget);` |

### TC-S1-011-29: 会话超时处理测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-29 |
| **用例名称** | 会话超时处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | Token 过期 |
| **测试步骤** | 1. 模拟 Token 过期<br>2. 检查处理 |
| **预期结果** | 重定向到登录页并显示超时消息 |
| **自动化代码** | `expect(find.text('Session expired. Please login again.'), findsOneWidget);` |

### TC-S1-011-30: 错误消息用户友好性测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-30 |
| **用例名称** | 错误消息用户友好性测试 |
| **测试类型** | UX Test |
| **优先级** | P1 |
| **前置条件** | 存在错误状态 |
| **测试步骤** | 1. 触发各种错误<br>2. 检查错误消息 |
| **预期结果** | 所有错误消息都是中文的、友好的 |
| **自动化代码** | (Manual verification required)` |

---

## 8. 无障碍测试 (TC-S1-011-31 ~ TC-S1-011-35)

### TC-S1-011-31: 键盘导航测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-31 |
| **用例名称** | 键盘导航测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 使用 Tab 键导航<br>2. 检查焦点顺序 |
| **预期结果** | 焦点顺序: 邮箱 -> 密码 -> 登录按钮 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`expect(focusedWidget, isEmailField);` |

### TC-S1-011-32: Tab焦点顺序测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-32 |
| **用例名称** | Tab焦点顺序测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 检查 focusOrder<br>2. 使用 Tab 测试 |
| **预期结果** | 焦点顺序符合逻辑 |
| **自动化代码** | `expect(focusOrder, equals(['email', 'password', 'login']));` |

### TC-S1-011-33: 屏幕阅读器错误播报测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-33 |
| **用例名称** | 屏幕阅读器错误播报测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 存在验证错误 |
| **测试步骤** | 1. 触发验证错误<br>2. 检查 Semantics |
| **预期结果** | 错误信息被正确标记为 Semantics |
| **自动化代码** | `expect(errorWidget, hasSemantics(label: 'Email is required'));` |

### TC-S1-011-34: 颜色对比度测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-34 |
| **用例名称** | 颜色对比度测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 检查文本颜色对比度 |
| **预期结果** | 符合 WCAG AA 标准 (4.5:1) |
| **自动化代码** | (Manual verification with accessibility scanner)` |

### TC-S1-011-35: 触摸目标大小测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-35 |
| **用例名称** | 触摸目标大小测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 检查按钮和输入框大小 |
| **预期结果** | 触摸目标 >= 48x48 dp |
| **自动化代码** | `expect(loginButton.size, greaterThan(Size(48, 48)));` |

### TC-S1-011-36: 登录失败停留在登录页测试

| 字段 | 内容 |
|------|------|
| **用例ID** | TC-S1-011-36 |
| **用例名称** | 登录失败停留在登录页测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 登录页面加载完成 |
| **测试步骤** | 1. 输入无效凭证<br>2. 提交表单<br>3. 检查当前路由 |
| **预期结果** | 登录失败后仍停留在登录页 (/login)，不跳转到其他页面 |
| **自动化代码** | `await authNotifier.login('invalid@test.com', 'wrongpass');`<br>`expect(router.currentPath, equals('/login'));`<br>`expect(find.byType(LoginPage), findsOneWidget);` |

---

## 9. 测试覆盖率矩阵

| 验收标准 | 相关测试用例 |
|----------|--------------|
| **AC1**: 界面符合Material Design 3规范 | TC-S1-011-04, TC-S1-011-19, TC-S1-011-20 |
| **AC2**: 表单验证即时反馈 | TC-S1-011-05, TC-S1-011-06, TC-S1-011-07, TC-S1-011-08, TC-S1-011-09, TC-S1-011-10, TC-S1-011-11 |
| **AC3**: 登录成功跳转首页 | TC-S1-011-12, TC-S1-011-13, TC-S1-011-14, TC-S1-011-23, TC-S1-011-24 |
| **AC3** (登录失败停留): 登录失败停留在登录页 | TC-S1-011-36 |

---

## 10. 缺陷报告模板

当测试失败时，使用以下模板报告缺陷：

```markdown
## 缺陷报告

**缺陷ID**: BUG-S1-011-XX
**严重级别**: P0/P1/P2/P3
**测试用例**: TC-S1-011-XX
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
