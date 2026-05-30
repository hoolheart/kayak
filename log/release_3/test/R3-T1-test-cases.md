# R3-T1 登录流程修复 — 测试用例

**版本**: 1.1  
**日期**: 2026-05-30  
**作者**: sw-mike (测试工程师)  
**关联任务**: [R3-T1: 修复登录流程（替换模拟登录为真实认证）](../tasks.md#r3-t1-修复登录流程替换模拟登录为真实认证-)  
**关联需求**: FR-AUTH-001  
**测试方法**: 使用 kimi-webbridge 进行浏览器操作 + 截图验证

---

## 测试环境

| 项目 | 值 |
|------|-----|
| 前端 | Flutter Web (Chrome) |
| 后端 | Axum HTTP API (:8080) |
| 测试账号 | admin@kayak.local / Admin123 |
| 测试工具 | kimi-webbridge + 浏览器截图 |
| 截图目录 | `log/release_3/test/screenshots/` |

---

## 测试用例

---

### TC-R3-T1-001: 正常登录流程（Happy Path）

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证用户使用有效凭据（admin@kayak.local / Admin123）能够成功登录并跳转到 Dashboard |
| **前置条件** | 1. 后端服务已启动且运行正常<br>2. 前端 Flutter Web 已启动并可访问<br>3. 浏览器打开登录页面 `/login` |
| **对应验收标准** | AC1, AC2, AC5 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 打开浏览器访问 Kayak 登录页 | 登录页面正常显示，包含 Logo、邮箱输入框、密码输入框、登录按钮 | `TC-R3-T1-001-step1-login-page.png` |
| 2 | 在邮箱输入框输入 `admin@kayak.local` | 输入框显示邮箱地址，无验证错误 | — |
| 3 | 在密码输入框输入 `Admin123` | 输入框显示密码（遮蔽状态），无验证错误 | — |
| 4 | 点击"登录"按钮 | 1. 登录按钮文字替换为旋转加载动画（CircularProgressIndicator）<br>2. 按钮处于禁用状态（不可重复点击）<br>3. 按钮原有"登录"文字不可见，完全被加载指示器替换 | `TC-R3-T1-001-step4-loading-state.png` |
| 5 | 等待后端响应（~1-2秒） | 1. 观察启动后端终端的日志输出，可见 `POST /api/v1/auth/login` 被调用（日志行如 `INFO login: ...`）<br>2. 浏览器自动跳转到 `/dashboard` 页面<br>3. Dashboard 页面正常加载显示 | `TC-R3-T1-001-step5-dashboard.png` |
| 6 | 打开浏览器开发者工具 → Application → Local Storage | 能看到 `access_token` 和 `refresh_token` 已存储 | `TC-R3-T1-001-step6-token-storage.png` |

**预期结果**：
- ✅ 后端 `POST /api/v1/auth/login` 被实际调用（非模拟登录）
- ✅ 登录成功后自动跳转到 `/dashboard`，不再停留在登录页
- ✅ Token 被正确存储到 localStorage

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-001-*.png`

---

### TC-R3-T1-002: 无效凭据处理（错误密码）

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证用户输入错误密码时，页面显示可读的错误提示信息并停留在登录页 |
| **前置条件** | 1. 后端服务已启动且运行正常<br>2. 浏览器打开登录页面 `/login` |
| **对应验收标准** | AC3 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 打开浏览器访问 Kayak 登录页 | 登录页面正常显示 | `TC-R3-T1-002-step1-login-page.png` |
| 2 | 在邮箱输入框输入 `admin@kayak.local` | 输入正常 | — |
| 3 | 在密码输入框输入错误密码 `WrongPassword123` | 输入正常 | — |
| 4 | 点击"登录"按钮 | 按钮显示加载状态，发送 POST 请求到后端 | — |
| 5 | 等待后端返回 401 响应 | 加载状态结束，错误横幅出现在登录卡片下方 | `TC-R3-T1-002-step5-error-message.png` |

**错误横幅验证**：
- 错误横幅使用 `errorContainer` 背景色（红色系）
- 显示错误图标（`Icons.error_outline`）
- 错误文本为用户可读的消息（如"邮箱或密码错误"），**不显示**技术性错误（如 `401 Unauthorized`、堆栈信息等）
- 错误横幅带有关闭按钮（×），点击可关闭
- 用户仍然停留在 `/login` 页面，**未被重定向**

**预期结果**：
- ✅ 页面显示用户可读的错误提示"邮箱或密码错误"
- ✅ 不显示技术性错误信息
- ✅ 用户停留在登录页面

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-002-*.png`

---

### TC-R3-T1-003: 网络错误处理

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证后端不可用时，页面显示网络错误信息并停留在登录页 |
| **前置条件** | 1. 前端已启动<br>2. 后端服务**未启动**（或网络不可达）<br>3. 浏览器打开登录页面 `/login` |
| **对应验收标准** | AC3 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 停止后端服务（或断开网络） | 后端不可用 | — |
| 2 | 打开浏览器访问 Kayak 登录页 | 登录页面正常显示 | `TC-R3-T1-003-step1-login-page.png` |
| 3 | 输入有效凭据 `admin@kayak.local` / `Admin123` | 输入正常 | — |
| 4 | 点击"登录"按钮 | 按钮显示加载状态 | — |
| 5 | 等待请求超时或失败 | 加载状态结束，错误横幅出现在登录卡片下方 | `TC-R3-T1-003-step5-network-error.png` |

**错误横幅验证**：
- 显示网络错误信息，如"网络错误，请检查网络连接"
- 不显示技术性错误（如 `SocketException`、`Connection refused` 等）
- 用户停留在 `/login` 页面
- 错误横幅有关闭按钮

**预期结果**：
- ✅ 页面显示网络错误提示信息
- ✅ 不显示技术性错误信息
- ✅ 用户停留在登录页面

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-003-*.png`

---

### TC-R3-T1-004: 登录加载状态与按钮防重复点击

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证登录过程中按钮正确显示加载状态，且不可重复点击 |
| **前置条件** | 1. 后端服务已启动<br>2. 浏览器打开登录页面 `/login`<br>3. （可选）可在测试环境中模拟慢网络响应以观察加载状态 |
| **对应验收标准** | AC4 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 打开浏览器访问 Kayak 登录页 | 登录页面正常显示，按钮显示"登录"文字 | `TC-R3-T1-004-step1-idle.png` |
| 2 | 输入有效凭据 `admin@kayak.local` / `Admin123` | 输入正常 | — |
| 3 | 点击"登录"按钮 | 1. 按钮文字替换为旋转加载动画（CircularProgressIndicator）<br>2. 按钮背景色可能变为禁用色<br>3. 邮箱和密码输入框变为禁用状态 | `TC-R3-T1-004-step3-loading.png` |
| 4 | 在加载状态下**再次点击**登录按钮 | 按钮 `onPressed` 为 `null`，点击无任何反应 | — |
| 5 | 等待登录完成 | 加载状态结束，页面跳转到 Dashboard | `TC-R3-T1-004-step5-dashboard.png` |

**预期结果**：
- ✅ 登录过程中按钮显示加载指示器（非文字"登录"）
- ✅ 加载期间按钮不可重复点击（disabled 状态）
- ✅ 输入框在加载期间禁用
- ✅ 登录完成后恢复正常/跳转

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-004-*.png`

---

### TC-R3-T1-005: 已登录状态自动跳转

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证已登录用户访问 `/login` 页面时自动重定向到 Dashboard |
| **前置条件** | 1. 用户已完成一次成功登录（Token 已存储在浏览器中）<br>2. Token 未过期 |
| **对应验收标准** | AC6 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 先执行 TC-R3-T1-001 确保已成功登录 | 当前在 Dashboard 页面 | — |
| 2 | 在浏览器地址栏手动输入并访问 `/login` 路径 | 立即重定向到 `/dashboard`，不显示登录页面 | `TC-R3-T1-005-step2-redirect.png` |
| 3 | 查看浏览器地址栏 | 地址栏显示 `/dashboard` 而非 `/login` | — |

**预期结果**：
- ✅ 已登录用户访问 `/login` 时自动跳转至 `/dashboard`
- ✅ 不在登录页停留
- ✅ 不显示任何登录界面

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-005-*.png`

---

### TC-R3-T1-006: 表单验证 — 空邮箱提交

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证用户未输入邮箱时点击登录，表单验证拦截并提示 |
| **前置条件** | 浏览器打开登录页面 `/login` |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 打开浏览器访问 Kayak 登录页 | 登录页面正常显示 | `TC-R3-T1-006-step1-login-page.png` |
| 2 | 在邮箱输入框保持为空 | 无输入 | — |
| 3 | 在密码输入框输入 `Admin123` | 输入正常 | — |
| 4 | 点击"登录"按钮 | 1. **不**发送 POST 请求到后端<br>2. 邮箱输入框下方显示验证错误提示（如"请输入邮箱地址"）<br>3. 登录按钮不显示加载状态<br>4. 页面不跳转 | `TC-R3-T1-006-step4-validation-error.png` |

**预期结果**：
- ✅ 客户端表单验证拦截空邮箱提交
- ✅ 不调用后端 API
- ✅ 显示邮箱验证错误信息
- ✅ 用户停留在登录页

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-006-*.png`

---

### TC-R3-T1-007: 表单验证 — 空密码提交

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证用户未输入密码时点击登录，表单验证拦截并提示 |
| **前置条件** | 浏览器打开登录页面 `/login` |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 打开浏览器访问 Kayak 登录页 | 登录页面正常显示 | `TC-R3-T1-007-step1-login-page.png` |
| 2 | 在邮箱输入框输入 `admin@kayak.local` | 输入正常 | — |
| 3 | 在密码输入框保持为空 | 无输入 | — |
| 4 | 点击"登录"按钮 | 1. **不**发送 POST 请求到后端<br>2. 密码输入框下方显示验证错误提示（如"请输入密码"）<br>3. 登录按钮不显示加载状态<br>4. 页面不跳转 | `TC-R3-T1-007-step4-validation-error.png` |

**预期结果**：
- ✅ 客户端表单验证拦截空密码提交
- ✅ 不调用后端 API
- ✅ 显示密码验证错误信息
- ✅ 用户停留在登录页

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-007-*.png`

---

### TC-R3-T1-008: Token 存储验证

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证登录成功后 access_token 和 refresh_token 被正确存储到浏览器 localStorage |
| **前置条件** | 1. R3-T3 已完成部署<br>2. 后端已启动，前端已加载登录页 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 使用有效凭据成功登录 | 跳转到 Dashboard | `TC-R3-T1-008-step1-dashboard.png` |
| 2 | 打开浏览器开发者工具 → Application → Local Storage | 显示 `http://localhost:8080`（或对应域名）的存储条目 | `TC-R3-T1-008-step2-localstorage.png` |
| 3 | 检查存储条目 | 存在 `access_token` 键，值为 JWT 格式字符串（如 `eyJ...`） | — |
| 4 | 检查存储条目 | 存在 `refresh_token` 键，值为字符串 | — |

**预期结果**：
- ✅ `access_token` 存储在 localStorage 中
- ✅ `refresh_token` 存储在 localStorage 中
- ✅ Token 格式为有效的 JWT（以 `eyJ` 开头）

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-008-*.png`

---

### TC-R3-T1-009: 页面刷新保持登录状态

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证登录后刷新浏览器页面，用户保持登录状态，直接进入 Dashboard |
| **前置条件** | 1. R3-T3 已完成部署<br>2. 已完成一次成功登录（Token 已存储）<br>3. 当前在 Dashboard 页面 |
| **对应验收标准** | AC6 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 先执行 TC-R3-T1-001 确保已成功登录 | 当前在 Dashboard 页面 | `TC-R3-T1-009-step1-dashboard-before-refresh.png` |
| 2 | 按 F5 或点击浏览器刷新按钮 | 页面重新加载，显示加载状态（SplashScreen） | — |
| 3 | 等待应用初始化完成 | 1. `AuthStateNotifier.initialize()` 从 localStorage 读取 Token<br>2. Token 有效，直接进入 Dashboard<br>3. **不显示登录页面** | `TC-R3-T1-009-step3-dashboard-after-refresh.png` |

**预期结果**：
- ✅ 刷新页面后无需重新登录
- ✅ 直接进入 Dashboard 页面
- ✅ 中间不展示登录页面

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-009-*.png`

---

### TC-R3-T1-010: 错误横幅关闭功能

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证登录失败后显示的错误横幅可以通过关闭按钮消除 |
| **前置条件** | 后端已启动 |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 输入错误密码触发登录失败 | 错误横幅显示在登录卡片下方 | `TC-R3-T1-010-step1-error-banner.png` |
| 2 | 点击错误横幅右侧的关闭按钮（×） | 错误横幅消失，回到空闲状态 | `TC-R3-T1-010-step2-banner-dismissed.png` |
| 3 | 再次点击"登录"按钮（不修改输入） | 可再次发送登录请求，错误状态已重置 | — |

**预期结果**：
- ✅ 错误横幅显示关闭按钮
- ✅ 点击关闭后错误横幅消失
- ✅ 登录状态重置为 idle，可再次尝试登录

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-010-*.png`

### TC-R3-T1-011: Token 过期后自动刷新

| 字段 | 内容 |
|------|------|
| **测试描述** | 验证 access_token 过期后，系统自动使用 refresh_token 获取新的 access_token，用户无感知继续操作，不跳转到登录页 |
| **前置条件** | 1. R3-T3 已完成部署<br>2. 后端已启动<br>3. 已完成一次成功登录（Token 已存储在浏览器中） |

**测试步骤**：

| 步骤 | 操作 | 预期结果 | 截图 |
|------|------|----------|------|
| 1 | 使用有效凭据成功登录，进入 Dashboard | Dashboard 页面正常显示 | `TC-R3-T1-011-step1-dashboard.png` |
| 2 | 打开开发者工具 → Application → Local Storage，记录 `access_token` 的当前值 | 记录到 JWT 格式的 access_token | — |
| 3 | 在开发者工具中手动修改 `access_token` 的值（如删除最后 5 个字符），模拟 Token 过期/失效 | access_token 值已被篡改 | — |
| 4 | 保持开发者工具 Network 面板打开，按 F5 刷新页面 | 1. 页面重新加载，显示 SplashScreen 加载状态<br>2. Network 面板中出现 `POST /api/v1/auth/refresh` 请求<br>3. 请求正常返回 200，携带新的 access_token | `TC-R3-T1-011-step4-refresh-request.png` |
| 5 | 刷新完成后，等待页面加载 | 1. 成功进入 Dashboard 页面，**不显示登录页**<br>2. 浏览器控制台无认证相关错误<br>3. Dashboard 功能正常 | `TC-R3-T1-011-step5-dashboard-after-refresh.png` |
| 6 | 检查 localStorage 中 `access_token` 的值 | `access_token` 的值与步骤 2 记录的值不同，已更新为新的有效 token | `TC-R3-T1-011-step6-new-token.png` |

**预期结果**：
- ✅ access_token 过期/失效后，系统自动调用 refresh API 获取新 token
- ✅ 用户无感知，**不跳转到登录页**
- ✅ localStorage 中的 access_token 被更新为新的有效 token
- ✅ Dashboard 正常加载和操作

**实际结果**：（执行时填写）
**截图路径**：`log/release_3/test/screenshots/TC-R3-T1-011-*.png`

---

## 测试用例汇总

| 用例 ID | 测试描述 | 对应 AC | 优先级 | 预计执行时间 |
|---------|---------|---------|--------|------------|
| TC-R3-T1-001 | 正常登录流程（Happy Path） | AC1, AC2, AC5 | 🔴 P0 | 2 min |
| TC-R3-T1-002 | 无效凭据处理（错误密码） | AC3 | 🔴 P0 | 2 min |
| TC-R3-T1-003 | 网络错误处理 | AC3 | 🟡 P1 | 2 min |
| TC-R3-T1-004 | 登录加载状态与按钮防重复点击 | AC4 | 🟡 P1 | 2 min |
| TC-R3-T1-005 | 已登录状态自动跳转 | AC6 | 🔴 P0 | 1 min |
| TC-R3-T1-006 | 表单验证 — 空邮箱提交 | — | 🟡 P1 | 1 min |
| TC-R3-T1-007 | 表单验证 — 空密码提交 | — | 🟡 P1 | 1 min |
| TC-R3-T1-008 | Token 存储验证 | AC5 | 🟡 P1 | 1 min |
| TC-R3-T1-009 | 页面刷新保持登录状态 | AC6 | 🔴 P0 | 1 min |
| TC-R3-T1-010 | 错误横幅关闭功能 | — | 🟢 P2 | 1 min |
| TC-R3-T1-011 | Token 过期后自动刷新 | — | 🟡 P1 | 2 min |

**优先级说明**：
- **P0（Blocker）**：核心登录流程，必须全部通过
- **P1（High）**：重要的用户体验和错误处理场景
- **P2（Medium）**：辅助功能验证

---

## 执行计划

1. **确认 sw-tom 完成 R3-T1 的代码修改并合并到 feature 分支**
2. **启动后端服务**：`./scripts/start-web.sh`
3. **启动 kimi-webbridge** 并连接浏览器
4. **按优先级依次执行测试用例**（P0 → P1 → P2）
5. **每个用例截图保存**到 `screenshots/` 目录
6. **记录实际结果与预期结果的差异**
7. **将发现的 Bug 报告到 `bugs.md`**

---

## 附录：kimi-webbridge 操作参考

### 健康检查
```bash
~/.kimi-webbridge/bin/kimi-webbridge status
```

### 导航到登录页
```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -d '{"action":"navigate","args":{"url":"http://localhost:8080/login","newTab":true},"session":"kayak-test"}'
```

### 输入邮箱
```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -d '{"action":"fill","args":{"selector":"input[type=email]","value":"admin@kayak.local"},"session":"kayak-test"}'
```

（实际 selector 需根据页面 DOM 确定，优先使用 snapshot 获取 @e ref）

### 截图
```bash
bash /Users/edward/.agents/skills/kimi-webbridge/scripts/screenshot.sh \
  -s kayak-test \
  -o /Users/edward/workspace/kayak/log/release_3/test/screenshots/TC-R3-T1-001-step1-login-page.png
```

---

*文档结束*
