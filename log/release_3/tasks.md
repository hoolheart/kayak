# Release 3 任务分解

**版本**: 1.0  
**日期**: 2026-05-30  
**作者**: sw-jerry (Software Architect)  
**状态**: Draft — 待 sw-prod 评审  
**Sprint 数**: 1 个 Sprint（1 周，最大 15 个任务）  
**总估算**: ~33 小时

---

## 1. 技术可行性评估总览

| ID | 需求 | 优先级 | 可行性 | 风险 | 估算 |
|----|------|--------|--------|------|------|
| FR-AUTH-001 | 修复登录流程 | 🔴 P0 | ✅ 低风险 | 无 — 后端认证链路已完整实现且测试通过 | ~2h |
| FR-AUTH-002 | 退出登录 UI 入口 | 🔴 P0 | ✅ 低风险 | 无 — `AuthStateNotifier.logout()` 已实现，仅缺 UI 触发 | ~2h |
| FR-AUTH-003 | Web Token 持久化 | 🟡 P1 | ✅ 低风险 | 低 — 方案成熟，`shared_preferences` Web 端稳定 | ~1h |
| FR-DEVICE-001 | 虚拟设备创建入口 | 🟡 P1 | ✅ 中风险 | 中 — 前端需新增对话框 UI + 调用已有创建设备 API | ~5h |
| FR-L10N-001 | 中英文界面修复 | 🟡 P1 | ⚠️ 中风险 | 中 — 硬编码字符串数量可能超出预估 | ~6h |
| FR-UI-001 | 深色主题对比度 | 🟡 P1 | ✅ 低风险 | 低 — 主题系统已存在，仅需调参+消除硬编码 | ~4h |
| FR-DOC-001 | 用户手册更新 | 🟡 P1 | ✅ 低风险 | 低 — 纯文档工作，但需真实截图 | ~5h |
| FR-DASH-001 | Dashboard 统计 | 🟢 P2 | ⚠️ 中风险 | 中 — 设备/数据文件无独立列表 API | ~4h |

### 1.1 关键发现

1. **FR-DASH-001 设备总数**：后端无独立 `GET /api/v1/devices` 端点（设备 API 嵌套在工作台下）。Dashboard 需遍历所有工作台并调用 `GET /api/v1/workbenches/{id}/devices` 来聚合设备数。

2. **FR-DASH-001 数据文件总数**：后端**未实现** `GET /api/v1/data-files` 列表端点（arch.md 文档有列出但代码中不存在）。仅存在 `GET /api/v1/experiments/{id}/data-file`（单个试验的数据文件下载）。在"不新增后端 API"约束下，数据文件统计卡片将采用降级方案（显示为从试验数推导或暂时保持 `"—"`）。

3. **FR-L10N-001 工作量不确定**：PRD 估计硬编码字符串 ~185 个（Dashboard ~15、工作台 ~30、设备管理 ~25、试验 ~40、分析方法 ~10、分析 ~20、团队管理 ~30、设置 ~15）。实际数量需审计后才能确定。若超出预估，按 PRD 风险缓解策略 —— 优先核心页面，次要页面可推迟到后续版本。

4. **无后端代码变更**：根据 PRD 技术约束，本 Release 不新增任何后端 API、不修改数据库 Schema、不改动路由结构。所有修复均在前端完成。

---

## 2. 任务列表

### 2.1 认证修复 (Auth Fixes) — P0 Blockers

#### R3-T1: 修复登录流程（替换模拟登录为真实认证） 🔴 P0

- **关联需求**: FR-AUTH-001
- **负责人**: sw-tom
- **估算**: 2 小时
- **可独立测试**: 是（修复后登录即可验证）

**描述**：
修改 `login_form.dart` 第 71-98 行的 `_submitForm()` 方法：
1. 移除 `Future.delayed` + `loginProvider.setSuccess()` 模拟逻辑
2. 替换为 `await ref.read(authStateProvider.notifier).login(email, password)`
3. 在 `loginProvider` 中正确设置 `loading`/`success`/`error` 状态
4. 捕获异常并显示用户可读的错误信息（如"登录失败，请检查您的凭据"）

**关键文件**:
- `kayak-frontend/lib/features/auth/widgets/login_form.dart` (L71-L98)
- 可选关联: `login_view.dart`（如果 loginProvider 需要调整）

**验收标准**: 见 PRD FR-AUTH-001 验收标准 AC1-AC6

---

#### R3-T2: 添加退出登录 UI 入口 🔴 P0

- **关联需求**: FR-AUTH-002
- **负责人**: sw-tom
- **估算**: 2 小时
- **可独立测试**: 是（依赖 R3-T1 完成后可验证退出→重新登录流程）

**描述**：
在设置页面（`settings_page.dart`）的"外观"和"关于"之间添加"账户"分区，包含：
1. "退出登录" ListTile（红色警示样式）
2. 点击弹出确认对话框："确定要退出登录吗？"
3. 确认后调用 `ref.read(authStateProvider.notifier).logout()`
4. 退出后跳转到登录页并显示"您已安全退出"提示

**关键文件**:
- `kayak-frontend/lib/screens/settings/settings_page.dart`

**退出行为**：
- GoRouter 路由守卫自动在 `isAuthenticated = false` 时重定向到 `/login`
- 登录页需接收一个可选参数以显示"安全退出"提示

**验收标准**: 见 PRD FR-AUTH-002 验收标准 AC1-AC6

---

#### R3-T3: 修复 Web 环境下 Token 持久化存储 🟡 P1

- **关联需求**: FR-AUTH-003
- **负责人**: sw-tom
- **估算**: 1 小时
- **可独立测试**: 是（依赖 R3-T1，登录后验证 Token 持久性）

**描述**：
修改 `token_storage.dart` 的 `TokenStorageInterface.create()` 方法：
1. Web 平台（`kIsWeb == true`）改用 `SharedPrefsTokenStorage`
2. 桌面平台保持现有 `SharedPrefsTokenStorage`
3. 移除 Web 平台对 `SecureTokenStorage`（`flutter_secure_storage`）的依赖
4. 在 `pubspec.yaml` 中确认 `shared_preferences` 已声明（应已存在，用于主题/语言存储）

**关键文件**:
- `kayak-frontend/lib/core/auth/token_storage.dart`

**回归测试要求**:
- 桌面平台 Token 存储功能不受影响

**验收标准**: 见 PRD FR-AUTH-003 验收标准 AC1-AC5

---

### 2.2 虚拟设备创建 (Virtual Device) — P1 High

#### R3-T4: 实现虚拟设备创建入口 🟡 P1

- **关联需求**: FR-DEVICE-001
- **负责人**: sw-tom
- **估算**: 5 小时
- **可独立测试**: 是（依赖 R3-T1 完成后在 Dashboard 或工作台页面操作）

**描述**：
在工作台详情页（`workbench_detail_page.dart`）的设备列表区域添加"创建虚拟设备"功能入口：
1. **按钮入口**：设备列表顶部添加"创建虚拟设备" FilledButton
2. **创建对话框**：弹出 `AlertDialog` 包含：
   - 设备名称（TextFormField，预填默认名称如"虚拟温度传感器-01"）
   - 设备类型（DropdownButtonFormField，选项列表见下方）
   - 创建按钮
3. **调用已有 API**：`POST /api/v1/workbenches/{workbench_id}/devices`，传入 `protocol_type: "virtual"` 和相应的 `virtual_parameters`
4. **创建成功后**：刷新设备列表，新设备应自动出现在列表中

**虚拟设备类型预设模板**：

| 模板 | protocol_type | virtual_parameters 示例 | 自动创建测点 |
|------|--------------|------------------------|-------------|
| 🌡️ 温度传感器 | `virtual` | `{"mode": "sine", "channels": [{"name": "温度1", "unit": "°C", "min": -50, "max": 150}]}` | 温度测点 |
| 📊 压力传感器 | `virtual` | `{"mode": "random_walk", "channels": [{"name": "压力1", "unit": "MPa", "min": 0, "max": 10}]}` | 压力测点 |
| ⚡ 功率计 | `virtual` | `{"mode": "step", "channels": [{"name": "电压", "unit": "V"}, {"name": "电流", "unit": "A"}, {"name": "功率", "unit": "W"}]}` | 电压/电流/功率测点 |
| 📈 通用传感器 | `virtual` | `{"mode": "random", "channels": [{"name": "通道1"}, {"name": "通道2"}]}` | 通用测点 |

**关键文件**:
- `kayak-frontend/lib/features/workbench/screens/detail/workbench_detail_page.dart`（添加按钮）
- 新建: `kayak-frontend/lib/features/workbench/widgets/virtual_device_dialog.dart`（对话框）
- 可选: 在 Dashboard 的快捷操作卡片中也添加"创建虚拟设备"入口

**注意**：模板的 `virtual_parameters` JSON 结构需与后端 `VirtualConfig` 结构一致。建议先查看 `kayak-backend/src/drivers/virtual.rs` 中的 `VirtualConfig` 定义确认参数格式。

**验收标准**: 见 PRD FR-DEVICE-001 验收标准 AC1-AC6

---

### 2.3 国际化修复 (Localization) — P1 High

#### R3-T5: 国际化审计与字符串提取 🟡 P1

- **关联需求**: FR-L10N-001（准备阶段）
- **负责人**: sw-tom
- **估算**: 2 小时
- **可独立测试**: 是

**描述**：
系统性审计所有前端页面的硬编码字符串：
1. 使用 `grep '[\u4e00-\u9fff]'` 扫描所有 `.dart` 文件中的中文字符串
2. 按页面/模块分类整理待翻译字符串列表
3. 确认当前 `app_zh.arb` 和 `app_en.arb` 中已有的键，避免重复
4. 输出字符串清单（Excel/CSV 格式），标记每个字符串的：
   - 来源文件及行号
   - 建议的 ARB 键名
   - 中文原文
   - 英文翻译（机翻草稿或留空待人工翻译）
5. 确认 `l10n.yaml` 仅声明 `en` 和 `zh`，移除任何法语（`fr`）配置残留

**关键文件**:
- 所有 `kayak-frontend/lib/features/**/*.dart`
- `kayak-frontend/lib/screens/**/*.dart`
- `kayak-frontend/lib/widgets/**/*.dart`
- `kayak-frontend/l10n.yaml`

**产出物**: 字符串清单（保存于 `log/release_3/design/l10n_audit.md`）

---

#### R3-T6: 补齐 ARB 翻译键并测试切换 🟡 P1

- **关联需求**: FR-L10N-001（实现阶段）
- **负责人**: sw-tom
- **估算**: 4 小时
- **可独立测试**: 是（可在 R3-T5 产出的清单基础上直接实现）

**描述**：
基于 R3-T5 产出的字符串清单：
1. **补齐 `app_zh.arb`**：添加所有中文翻译键
2. **补齐 `app_en.arb`**：添加所有英文翻译键
3. **替换硬编码字符串**：在各个 `.dart` 页面文件中，将硬编码中文字符串替换为 `AppLocalizations.of(context)!.keyName`
4. **更新 `translation_service.dart`**：在 `_keyMapping` 中添加模块级映射（Workbench, Devices, Experiments, Methods, Analysis, Teams, Settings）
5. **运行代码生成**：`flutter pub run build_runner build` 重新生成 `l10n.dart`
6. **测试语言切换**：
   - 切换 zh↔en 后各页面文字立即更新
   - 新导航到的页面也使用正确语言
   - 无中英文混排或 `null` 占位符

**翻译覆盖优先级**（按 PRD 风险缓解策略）：
1. 🔴 核心页面（必须完成）：Dashboard、工作台、设备管理、试验、设置
2. 🟡 次要页面（尽力完成）：分析方法、分析页面、团队管理
3. 🟢 后续版本（可推迟）：错误消息细节、Form 验证提示微调

**关键文件**:
- `kayak-frontend/lib/l10n/app_zh.arb`
- `kayak-frontend/lib/l10n/app_en.arb`
- `kayak-frontend/lib/services/translation_service.dart`
- 所有替换了硬编码字符串的 `.dart` 文件

**验收标准**: 见 PRD FR-L10N-001 验收标准 AC1-AC7

---

### 2.4 深色主题修复 (Dark Theme) — P1 High

#### R3-T7: 深色主题对比度修复与硬编码颜色消除 🟡 P1

- **关联需求**: FR-UI-001
- **负责人**: sw-tom
- **估算**: 4 小时
- **可独立测试**: 是（可独立于其他任务进行）

**描述**：
分三个子任务进行：

**子任务 7a — 审计硬编码颜色（1h）**：
1. 扫描所有 `.dart` 文件中的硬编码颜色值（`Color(0x...)`、`Colors.grey[...]`、`Colors.black`、`Colors.white`）
2. 识别应使用主题系统替换的位置（Card、Dialog、BottomSheet、Text 等）
3. 排除合理使用场景（如自定义图标颜色、图表数据系列色）

**子任务 7b — 修复对比度（2h）**：
1. 调整 `color_schemes.dart` 中的深色主题色板：
   - 确保 `onSurface` vs `surface` 对比度 ≥ 4.5:1
   - 确保 `onPrimary` vs `primary` 对比度充足
   - 调整次要文字色（`onSurfaceVariant`）的对比度
2. 重点修复组件：
   - 侧边导航栏文字（`NavigationRail` 的选中/未选中状态）
   - Dashboard 统计卡片文字
   - 表格内容（DataTable 的行文字）
   - 表单输入框标签和提示文字

**子任务 7c — 消除硬编码颜色（1h）**：
1. 将所有可替换的硬编码颜色改为 `Theme.of(context).colorScheme.*`
2. 确保 Card 使用 `colorScheme.surface` 而非 `Colors.grey[850]` 等硬编码
3. 确保所有页面在深色/浅色切换后无残留颜色

**关键文件**:
- `kayak-frontend/lib/core/theme/color_schemes.dart`
- `kayak-frontend/lib/core/theme/app_theme.dart`
- `kayak-frontend/lib/features/dashboard/screens/dashboard_screen.dart`
- `kayak-frontend/lib/features/experiments/screens/experiment_console_page.dart`（~1016 行，可能有较多硬编码）

**验收标准**: 见 PRD FR-UI-001 验收标准 AC1-AC5

---

### 2.5 Dashboard 统计 (Dashboard Stats) — P2 Medium

#### R3-T8: Dashboard 设备/试验统计连接后端真实数据 🟢 P2

- **关联需求**: FR-DASH-001
- **负责人**: sw-tom
- **估算**: 3 小时
- **可独立测试**: 是（依赖 R3-T1）

**描述**：
修改 `dashboard_screen.dart` 的 `_buildStatsGrid()` 方法：

1. **设备总数**（替代当前 L259-263 的硬编码 `"-"`）：
   - 从已有的工作台列表中获取所有 `workbench_id`
   - 并行调用 `GET /api/v1/workbenches/{id}/devices?size=1` 获取每工作台的设备总数（`PagedDeviceDto.total`）
   - 汇总所有工作台的设备数 —— 使用 `Future.wait` 并行请求
   - 边界处理：工作台为空（0 工作台 → 设备总数为 0）、API 调用失败（显示 `"—"`）

2. **试验总数**（替代当前 L264-268 的硬编码 `"-"`）：
   - 调用 `GET /api/v1/experiments?size=1` 获取 `PagedResponse.total`
   - 边界处理：API 调用失败（显示 `"—"`）、总数为 0（显示 `"0"`）

3. **工作台总数**（当前已连接后端数据，无需修改，但需验证正确性）

**关键文件**:
- `kayak-frontend/lib/features/dashboard/screens/dashboard_screen.dart` (L250-L288)

**后端 API 使用**:

| 统计项 | API 端点 | 获取方式 |
|--------|---------|----------|
| 工作台总数 | `GET /api/v1/workbenches` | 已有实现，使用返回列表长度 |
| 设备总数 | `GET /api/v1/workbenches/{id}/devices?size=1` | 遍历工作台，聚合 `PagedDeviceDto.total` |
| 试验总数 | `GET /api/v1/experiments?size=1` | 使用 `PagedResponse.total` |
| 数据文件 | 无可用 API（见 R3-T9） | 降级方案 |

**验收标准**: 见 PRD FR-DASH-001 验收标准 AC1-AC3、AC5

---

#### R3-T9: Dashboard 数据文件统计降级处理 🟢 P2

- **关联需求**: FR-DASH-001（数据文件统计部分）
- **负责人**: sw-tom
- **估算**: 1 小时
- **可独立测试**: 是（依赖 R3-T8）

**描述**：
处理数据文件统计卡片的降级方案：

**问题背景**：
`GET /api/v1/data-files` 端点虽然在 arch.md 中列出，但代码中**未实际实现**。仅存在 `GET /api/v1/experiments/{id}/data-file`（单试验数据文件下载）。受 PRD 约束"不新增任何后端 API"，无法添加新的列表端点。

**推荐方案（按优先级）**：
1. **方案 A（推荐）**：从试验数推导 —— 已有试验数统计，每个已完成的试验通常有一个数据文件。标注为"试验数据文件"并显示与试验总数关联的值（如 "12 个数据文件（来自 12 次试验）"）。
2. **方案 B**：暂时保持统计卡片显示 `"—"`，待后续版本添加后端 API 后再连接。卡片上添加 tooltip 说明"数据文件统计将在后续版本中提供"。
3. **方案 C（如需后端微调）**：如果 sw-prod 批准极小范围的后端修改，可以在 `experiment_query_service` 中添加一个 `GET /api/v1/experiments/data-files/count` 端点，返回统计总数。仅需 ~0.5h 后端工作。

**实施**：按方案 A 实现，标注为"暂估"。如果 sw-prod 批准方案 C，升格为 R3-T9 的扩展。

**关键文件**:
- `kayak-frontend/lib/features/dashboard/screens/dashboard_screen.dart` (L269-L273)

**验收标准**:
- AC4: 数据文件统计卡不显示硬编码的 `"-"`（显示推导值或有意义的占位符）
- AC5: 卡片的 tooltip 或副标题说明数据来源

---

### 2.6 用户手册更新 (Documentation) — P1 High

#### R3-T10: 更新用户手册至 v2.0 🟡 P1

- **关联需求**: FR-DOC-001
- **负责人**: sw-tom
- **估算**: 4 小时
- **可独立测试**: 是（纯文档工作，截图工作依赖 R3-T11）

**描述**：
重写 `docs/user-manual/user_manual.md`，覆盖 Release 1-4 全部功能：

**必须包含的章节**：
1. 系统概述（更新架构图引用）
2. 快速开始（含登录流程、默认管理员账号）
3. 工作台管理（含创建虚拟设备引导 → 截图需 R3-T11）
4. 设备管理（虚拟设备、Modbus TCP/RTU 设备、连接测试、状态查询）
5. 测点配置（创建/编辑/读写测点）
6. 试验管理（方法编辑、试验执行控制台、状态机说明）
7. 数据分析（分析页面图表操作）
8. 团队管理（创建团队、邀请成员、团队切换、角色说明）
9. Python SDK 使用入门（`KayakClient` 上下文管理器、`DataAPI`）
10. 设置与账户管理（退出登录、语言切换、主题切换）
11. 常见问题（FAQ：登录失败、Token 丢失、设备连接异常等）

**截图占位符**：手册中预留截图位置，使用 `<!-- TODO:SCREENSHOT:key -->` 标记，待 R3-T11 完成后替换为真实截图。

**关键文件**:
- `docs/user-manual/user_manual.md`

**验收标准**: 见 PRD FR-DOC-001 验收标准 AC1、AC4、AC5、AC7

---

#### R3-T11: 截图捕获与嵌入 🟡 P1

- **关联需求**: FR-DOC-001（截图部分）
- **负责人**: sw-tom（使用 Kimi WebBridge 或手动截图）
- **估算**: 1 小时
- **可独立测试**: 是（依赖 R3-T1、R3-T2、R3-T4 完成后才能有完整的可截图界面）

**描述**：
为 R3-T10 的用户手册捕获实际运行界面的截图：

1. **启动 Kayak 平台**：`./scripts/start-web.sh`
2. **登录** 使用 `admin@kayak.local / Admin123`
3. **按手册章节顺序截取界面截图**，至少包含：
   - 登录页面（含错误状态）
   - Dashboard 首页（含统计卡片）
   - 工作台列表页
   - 工作台详情页（含设备列表 + 创建虚拟设备对话框）
   - 设备详情页
   - 测点配置页
   - 试验列表页
   - 试验控制台（运行中状态）
   - 分析页面
   - 团队管理页面
   - 设置页面（含退出登录确认对话框）
   - 主题切换对比（深色 vs 浅色）
4. **保存截图**到 `docs/screenshots/`，命名规范：`{模块}_{描述}.png`
5. **更新手册**：将 R3-T10 中预留的 `<!-- TODO:SCREENSHOT:key -->` 替换为实际截图引用

**截图工具**：Kimi WebBridge（在浏览器中捕获）、macOS 系统截图或 Flutter DevTools screenshot

**注意**：
- **不截取敏感信息**：确保截图中不含真实密码、Token 等
- **使用演示账号**：`admin@kayak.local`
- **截图分辨率**：建议 1440×900 或 1920×1080，保持一致性

**关键目录**:
- `docs/screenshots/`

**验收标准**: 见 PRD FR-DOC-001 验收标准 AC2、AC3、AC6、AC8

---

### 2.7 集成测试与收尾

#### R3-T12: 全流程集成测试 🔴 P0

- **关联需求**: 所有 FR（端到端验证）
- **负责人**: sw-tom
- **估算**: 2 小时
- **可独立测试**: N/A（依赖所有功能任务完成）

**描述**：
按照 PRD 第 6 节"修复后的完整用户旅程"执行全流程走查：

**测试场景**：
1. **场景 1：首次登录**
   - 启动 Kayak → 看到登录页
   - 输入 `admin@kayak.local / Admin123` → 点击登录
   - 确认登录按钮显示"登录中..."
   - 确认自动跳转到 Dashboard
   - 确认 Dashboard 统计卡片显示真实数据（或 `"0"`）

2. **场景 2：Token 持久化**
   - 关闭浏览器标签页
   - 重新打开 → 确认直接进入 Dashboard（保持登录状态）

3. **场景 3：错误登录**
   - 退出登录 → 回到登录页
   - 输入错误密码 → 确认显示"登录失败，请检查您的凭据"

4. **场景 4：退出登录**
   - 进入设置页面 → 点击"退出登录" → 确认弹出确认对话框
   - 确认退出 → 确认跳转到登录页，显示"您已安全退出"
   - 手动访问 `/dashboard` → 确认被重定向到登录页

5. **场景 5：虚拟设备创建**
   - 登录后进入工作台详情页
   - 点击"创建虚拟设备" → 选择"温度传感器"
   - 确认设备出现在设备列表中
   - 检查后端日志确认 VirtualDriver 已启动

6. **场景 6：主题切换**
   - 进入设置 → 切换深色/浅色主题
   - 浏览 Dashboard、工作台、设备、试验页面
   - 确认所有文字清晰可读，无残留颜色

7. **场景 7：语言切换**
   - 进入设置 → 切换中/英文
   - 浏览所有页面 → 确认无中英文混排
   - 确认翻译自然流畅

**产出物**: 测试结果报告（保存于 `log/release_3/test/integration_test_report.md`）

---

#### R3-T13: CI 检查与修复 🔴 P0

- **关联需求**: PRD 第 4.4 节质量门禁
- **负责人**: sw-tom
- **估算**: 1 小时
- **可独立测试**: N/A（依赖所有代码修改完成）

**描述**：
运行以下 CI 检查并修复所有失败项：

| 检查项 | 命令 | 标准 |
|--------|------|------|
| 后端编译 | `cargo clippy --all-targets --all-features -- -D warnings` | 零错误零警告 |
| 后端测试 | `cargo test --all-features` | 全部通过 |
| 前端编译 | `flutter build web --release` | Build 成功 |
| 前端分析 | `flutter analyze --fatal-infos` | 零问题 |
| 前端测试 | `flutter test --exclude-tags golden` | 全部通过 |
| 全栈 CI | `./scripts/ci-check.sh` | Green |
| 一键启动 | `./scripts/start-web.sh` | 启动成功，浏览器可访问 |

**关键命令**:
```bash
cd kayak-frontend && flutter pub get && flutter analyze --fatal-infos && flutter test --exclude-tags golden && flutter build web --release
cd kayak-backend && cargo clippy --all-targets --all-features -- -D warnings && cargo test --all-features
./scripts/ci-check.sh
```

**注意**：
- 前端 CI 中 `flutter pub get` 必须在 `dart format` 之前运行（见 AGENTS.md）
- 如果 L10N 代码生成更新了 `.arb` 文件，需运行 `flutter pub run build_runner build`

---

#### R3-T14: Sprint 总结与架构文档更新 🔴 P0

- **关联需求**: Release 完结流程
- **负责人**: sw-jerry
- **估算**: 1 小时
- **可独立测试**: N/A（依赖所有任务完成且验收通过）

**描述**：
1. **更新 `arch.md`**（Release 3 实施后实时架构）：
   - 更新 Token 存储方案（Web → SharedPrefsTokenStorage）
   - 更新前端模块：新增虚拟设备创建对话框、logout UI
   - 更新目录结构中有变化的文件
   - 标注 `GET /api/v1/data-files` 端点**未实现**（与文档的不一致）
   - 移除 `[PLANNED]` 标记
2. **更新修订历史**：添加 Version 1.4 条目
3. **Sprint 回顾**：记录实际完成情况、遗留问题、技术债务

**关键文件**:
- `arch.md`
- `log/release_3/tasks.md`（更新状态）

---

## 3. 依赖关系图

```
                        R3-T1 (登录修复) ★ BLOCKING
                       /    |      |      |        \
                      /     |      |      |         \
               R3-T2    R3-T3   R3-T4   R3-T8    R3-T5
             (退出登录) (Token) (虚拟设备) (Dashboard) (L10N审计)
                |        |       |       |          |
                |        |       |    R3-T9         |
                |        |       |   (数据文件)      |
                |        |       |       |       R3-T6
                |        |       |       |      (ARB补齐)
                \        \       /       /         /
                 \________\_____/_______/_________/
                           |         |
                     R3-T10 (用户手册)  R3-T7 (深色主题)
                           |         |
                     R3-T11 (截图)    |
                           \        /
                            \      /
                          R3-T12 (集成测试)
                               |
                          R3-T13 (CI检查)
                               |
                          R3-T14 (Sprint总结)
```

**关键说明**：
- **R3-T1 是阻塞依赖**：大部分任务需要在登录修复完成后才能进行功能验证
- **R3-T7（深色主题）可独立进行**：不需要登录即可修改主题文件和验证视觉效果
- **R3-T5（L10N审计）可独立进行**：纯代码扫描工作，不需要运行应用
- **并行轨道**：
  - 轨道 A: T1 → T2 → T3（认证链路修复）
  - 轨道 B: T4（虚拟设备，可在 T1 完成后启动）
  - 轨道 C: T5 → T6（L10N，T5 独立，T6 需 T5 + T1）
  - 轨道 D: T7（深色主题，独立）
  - 轨道 E: T8 → T9（Dashboard 统计，需 T1）
  - 轨道 F: T10 → T11（文档+截图，需 T1+T2+T4）

---

## 4. Sprint 排期建议

### Sprint 1（1 周，14 个任务，~33h）

```
Day 1 (6h):  P0 Blockers + 审计准备
  ☐ R3-T1  修复登录流程                (2h)
  ☐ R3-T2  添加退出登录 UI 入口         (2h)
  ☐ R3-T5  L10N 审计与字符串提取       (2h) ← 可并行

Day 2 (7h):  P1 High
  ☐ R3-T3  修复 Web Token 持久化       (1h)
  ☐ R3-T4  虚拟设备创建入口            (5h)
  ☐ R3-T7  深色主题审计（子任务7a）    (1h) ← 可并行

Day 3 (7h):  P1 High + L10N 实现
  ☐ R3-T6  ARB 翻译键补齐             (4h)
  ☐ R3-T7  深色主题修复（子任务7b+7c）(3h)

Day 4 (7h):  P2 Medium + 文档
  ☐ R3-T8  Dashboard 统计连接          (3h)
  ☐ R3-T9  数据文件统计降级处理         (1h)
  ☐ R3-T10 用户手册更新                (3h)  ← 无截图初稿

Day 5 (6h):  集成测试 + 截图 + 收尾
  ☐ R3-T11 截图捕获与嵌入              (1h)
  ☐ R3-T12 全流程集成测试             (2h)
  ☐ R3-T13 CI 检查与修复              (1h)
  ☐ R3-T14 Sprint 总结与架构更新      (1h) ← sw-jerry
  ☐        完成 T10 手册剩余章节       (1h)  ← 嵌入截图后
```

**时间弹性**：
- 预留 ~7h 缓冲（33h/40h 周工时）
- 如果 L10N 工作量超出预估（R3-T6），可从缓冲时间中调配
- 如果时间不足，R3-T9（数据文件统计）降级方案可简化为快速占位符

---

## 5. 风险与缓解

| 风险ID | 描述 | 影响 | 概率 | 缓解策略 |
|--------|------|------|------|----------|
| R3-RISK-01 | L10N 硬编码字符串超过预估 185 个 | R3-T6 任务膨胀至 8h+ | 中 | 按优先级分批处理，核心页面 R3 完成，次要页面推迟至 R4 |
| R3-RISK-02 | 虚拟设备创建 API 参数格式与前端模板不匹配 | R3-T4 需要额外调试时间 | 中 | T4 开始时先检查 `VirtualConfig` 结构，对齐参数格式 |
| R3-RISK-03 | `GET /api/v1/data-files` 不存在导致 Dashboard 统计不完整 | 数据文件卡片无法显示真实数据 | 高（已确认） | R3-T9 采用降级方案（推导或占位符），后续版本添加 API |
| R3-RISK-04 | 深色主题修复引入新视觉不一致 | 部分页面色调变化 | 低 | 每次修改后对比深色/浅色截图，逐个页面验证 |
| R3-RISK-05 | `shared_preferences` 在特定浏览器版本有兼容性问题 | Token 在旧浏览器丢失 | 低 | 在 Chrome/Firefox/Safari/Edge 最新两个版本上测试 |
| R3-RISK-06 | T11 截图依赖所有功能完成，处于关键路径末尾 | 如前面任务延迟，截图时间被压缩 | 中 | T10 先写文字内容+占位符；T11 可延至 Sprint 结束后补充 |

---

## 6. 排除项确认

根据 PRD 第 1.3 节，以下内容**明确排除**在本 Release 之外：

| 排除项 | 状态 |
|--------|------|
| 新协议驱动（CAN/VISA/MQTT） | → Release 5+ |
| 完整 UI 重新设计 | → Release 5+ (需 sw-anna) |
| 新功能页面或路由 | → Release 5+ |
| 移动端适配 | → Release 5+ |
| 性能优化 | → Release 5+ |
| 邮件邀请集成 | → Release 5+ |
| 新增后端 API | ✅ 本 Release 不涉及 |
| 数据库 Schema 变更 | ✅ 本 Release 不涉及 |
| GoRouter/路由结构调整 | ✅ 本 Release 不涉及 |

---

## 7. 附录

### 7.1 后端 API 可用性对照表

| arch.md 记录 | 实际实现 | 本 Release 使用 |
|-------------|---------|----------------|
| `POST /api/v1/auth/login` | ✅ 已实现 | R3-T1 |
| `POST /api/v1/auth/refresh` | ✅ 已实现 | Token 自动刷新 |
| `GET /api/v1/workbenches` | ✅ 已实现 | R3-T1 (Dashboard已有) |
| `GET /api/v1/workbenches/{id}/devices` | ✅ 已实现 | R3-T8 (设备统计) |
| `POST /api/v1/workbenches/{id}/devices` | ✅ 已实现 | R3-T4 (创建设备) |
| `GET /api/v1/experiments` | ✅ 已实现 | R3-T8 (试验统计) |
| `GET /api/v1/data-files` | ❌ 未实现 | R3-T9 (降级处理) |
| `GET /api/v1/experiments/{id}/data-file` | ✅ 已实现 | 非列表，不适用 |

### 7.2 受影响的文件总览

| 文件 | 任务 | 修改类型 |
|------|------|----------|
| `lib/features/auth/widgets/login_form.dart` | R3-T1 | 🔧 重构（替换模拟逻辑） |
| `lib/screens/settings/settings_page.dart` | R3-T2 | ➕ 新增（退出登录入口） |
| `lib/core/auth/token_storage.dart` | R3-T3 | 🔧 修改（Web 平台分支） |
| `lib/features/workbench/screens/detail/workbench_detail_page.dart` | R3-T4 | ➕ 新增（虚拟设备按钮） |
| `lib/features/workbench/widgets/virtual_device_dialog.dart` | R3-T4 | ✨ 新建文件 |
| `lib/l10n/app_zh.arb` | R3-T6 | ➕ 大量新增键 |
| `lib/l10n/app_en.arb` | R3-T6 | ➕ 大量新增键 |
| `lib/services/translation_service.dart` | R3-T6 | 🔧 扩展映射表 |
| 各 features/ & screens/ 下的 .dart 文件 | R3-T6 | 🔧 替换硬编码字符串 |
| `lib/core/theme/color_schemes.dart` | R3-T7 | 🔧 调整色板 |
| `lib/features/dashboard/screens/dashboard_screen.dart` | R3-T8, T9 | 🔧 连接 API 数据 |
| `docs/user-manual/user_manual.md` | R3-T10, T11 | ✏️ 重写 |
| `docs/screenshots/*.png` | R3-T11 | ✨ 新增文件 |
| `arch.md` | R3-T14 | ✏️ 更新版本 |

---

**文档结束**

*本任务分解基于以下文件的分析编制：*
- `log/release_3/prd.md` — 产品需求文档
- `log/release_3/clarified_requirements.md` — 澄清需求（用户已确认）
- `arch.md` v1.3 — 当前架构文档
- `kayak-backend/src/api/routes.rs` — 后端 API 路由（验证端点存在性）
- `kayak-backend/src/services/device/types.rs` — 验证 PagedDeviceDto 结构
- `kayak-frontend/lib/features/auth/widgets/login_form.dart` — 确认 Bug 位置
- `kayak-frontend/lib/features/dashboard/screens/dashboard_screen.dart` — 确认硬编码位置
- `kayak-frontend/lib/screens/settings/settings_page.dart` — 确认设置页结构
