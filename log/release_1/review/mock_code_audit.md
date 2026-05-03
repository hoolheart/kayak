# Flutter 前端 Mock/TODO 代码审计报告

**审计日期**: 2026-05-03  
**审计范围**: `kayak-frontend/lib/` 下所有 `.dart` 文件  
**审计人员**: sw-tom

---

## 审计结果摘要

| 分类 | 数量 | 说明 |
|------|------|------|
| ① 后端已实现，前端需修复 | **4** | Mock/TODO 代码对应的后端 API 已就绪 |
| ② 后端未实现/无关，需加入待办 | **4** | 后端缺失或纯前端导航占位 |
| 非 Mock（误报） | **10** | 平台适配存根、合法 UX 行为等 |
| **总计** | **18** | 原始 grep 命中数 |

---

## 分类 ①：后端已实现 → 前端急需修复（4 项）

> 这些项的对应后端 API 在 `kayak-backend/src/api/routes.rs` 中已注册并实现，前端只需连接即可。

---

### 1. `device_list_tab.dart:255` — Mock 空列表代替真实测点数据

- **文件**: `lib/features/workbench/widgets/detail/device_list_tab.dart`
- **行号**: 255–256
- **代码片段**:
  ```dart
  // Mock data - in production, fetch from PointListProvider
  final points = <Map<String, String>>[];
  ```
- **后端 API**: `GET /api/v1/devices/{device_id}/points` ✅ 已实现
- **前端可用组件**: `PointListProvider` (StateNotifier) 已在 `lib/features/workbench/providers/point_list_provider.dart` 中定义，且 `point_list_panel.dart` 已在使用
- **影响**: 设备详情 Tab 中测点表格永远显示"空数据"，实际 API 可返回真实测点
- **修复建议**: 用 `ref.watch(pointListProvider(deviceId))` 替换硬编码空列表

---

### 2. `workbench_detail_page.dart:70` — TODO: 编辑工作台

- **文件**: `lib/features/workbench/screens/detail/workbench_detail_page.dart`
- **行号**: 70
- **代码片段**:
  ```dart
  OutlinedButton.icon(
    onPressed: () {
      // TODO: Edit workbench
    },
    ...
  )
  ```
- **后端 API**: `PUT /api/v1/workbenches/{id}` ✅ 已实现
- **影响**: 详情页"编辑"按钮点击无响应
- **修复建议**: 实现编辑对话框或导航到编辑页面，调用 workbench update API

---

### 3. `workbench_detail_page.dart:189` — TODO: 显示添加设备对话框

- **文件**: `lib/features/workbench/screens/detail/workbench_detail_page.dart`
- **行号**: 189
- **代码片段**:
  ```dart
  TextButton.icon(
    onPressed: () {
      // TODO: Show add device dialog
    },
    ...
  )
  ```
- **后端 API**: `POST /api/v1/workbenches/{workbench_id}/devices` ✅ 已实现
- **影响**: 工作台详情页"添加设备"按钮点击无任何反应
- **修复建议**: 实现设备添加对话框/表单，调用 device create API

---

### 4. `workbench_detail_page.dart:266` — TODO: 实现删除

- **文件**: `lib/features/workbench/screens/detail/workbench_detail_page.dart`
- **行号**: 266
- **代码片段**:
  ```dart
  FilledButton(
    onPressed: () {
      Navigator.of(ctx).pop();
      // TODO: implement delete
    },
    ...
  )
  ```
- **后端 API**: `DELETE /api/v1/workbenches/{id}` ✅ 已实现
- **影响**: 删除确认对话框点击"删除"后仅关闭对话框，不执行实际删除
- **修复建议**: 调用 workbench delete API，成功后刷新列表并导航返回

---

## 分类 ②：后端未实现/纯前端占位 → 加入待办（4 项）

---

### 5. `device_list_tab.dart:213` — TODO: 切换设备连接状态

- **文件**: `lib/features/workbench/widgets/detail/device_list_tab.dart`
- **行号**: 213
- **代码片段**:
  ```dart
  OutlinedButton(
    onPressed: () {
      // TODO: Toggle connection
    },
    child: const Text('连接', style: TextStyle(fontSize: 12)),
  )
  ```
- **后端 API**: ❌ 无对应的 connect/disconnect 端点
- **注意**: 存在 `DeviceTestService.testConnection()` (仅测试连接可达性，非设备上线/下线)，但无设备连接管理 API
- **需要**: 
  1. 后端添加 `POST /api/v1/devices/{id}/connect` 和 `POST /api/v1/devices/{id}/disconnect` 端点
  2. 前端接入状态管理与 UI 联动

---

### 6. `home_screen.dart:54` — TODO: 导航到工作台

- **文件**: `lib/screens/home/home_screen.dart`
- **行号**: 54
- **代码片段**:
  ```dart
  FilledButton.icon(
    onPressed: () {
      // TODO: 导航到工作台
    },
    ...
  )
  ```
- **后端 API**: 工作台 CRUD API 均已就绪 (`/api/v1/workbenches`)
- **影响**: 首页"进入工作台"按钮无响应，用户无法访问核心功能入口
- **修复建议**: 实现路由跳转 `context.go('/workbenches')`，路由已在 `app_router.dart` 中定义

---

### 7. `home_screen.dart:62` — TODO: 导航到设置

- **文件**: `lib/screens/home/home_screen.dart`
- **行号**: 62
- **代码片段**:
  ```dart
  TextButton.icon(
    onPressed: () {
      // TODO: 导航到设置
    },
    ...
  )
  ```
- **后端 API**: 设置功能后端未实现，设置页面也不存在
- **需要**: 
  1. 创建设置页面
  2. 添加设置路由
  3. 后端添加用户偏好设置 API（如需要）

---

### 8. `protocol_service.dart:19,28,41` — 前端调用不存在的后端 API

- **文件**: `lib/features/workbench/services/protocol_service.dart`
- **行号**: 19, 28, 41
- **代码片段**:
  ```dart
  // 行19: GET /api/v1/protocols
  final response = await _apiClient.get('/api/v1/protocols');
  
  // 行28: GET /api/v1/system/serial-ports
  final response = await _apiClient.get('/api/v1/system/serial-ports');
  
  // 行41: POST /api/v1/devices/$deviceId/test-connection
  final response = await _apiClient.post('/api/v1/devices/$deviceId/test-connection', ...);
  ```
- **后端状态**: 三条路由在 `routes.rs` 中均 **不存在**
- **影响**: 虽然代码本身不是 mock（它确实尝试调用真实 API），但调用时后端返回 404，等同于功能不可用
- **调用方**: `modbus_tcp_form.dart:109` 和 `modbus_rtu_form.dart:154` 调用 `testConnection()`
- **需要**: 后端实现三条缺失的 API 路由

---

## 非 Mock（误报澄清，共 10 项）

### 平台适配存根（3 项）

| 文件 | 说明 |
|------|------|
| `core/common/widgets/stub.dart` | Web 平台的 `window_manager` 存根，通过条件编译 `dart.library.html` 选择，非 mock 数据 |
| `core/platform/desktop_init_stub.dart` | Web 平台的桌面窗口初始化存根，合法平台适配 |
| `main.dart:7` | 条件导入：`if (dart.library.html)` 选择存根实现 |

### 合法 UX 行为（2 项）

| 文件 | 行号 | 说明 |
|------|------|------|
| `modbus_tcp_form.dart` | 126 | `Future.delayed(5s)` 用于测试连接成功后自动重置状态指示器，非 mock 延迟 |
| `modbus_rtu_form.dart` | 171 | 同上，合法的 UI 自动重置逻辑 |

### 设计意图说明（3 项）

| 文件 | 行号 | 说明 |
|------|------|------|
| `protocol_selector.dart` | 30 | "虚拟设备，用于测试和模拟" 是 Virtual 协议类型的功能描述文本，非 mock 代码 |
| `experiment_console_page.dart` | 9 | 国际化的改进建议注释，当前中文字符串是真实内容，非 fake 数据 |
| `method_edit_page.dart` | 291 | "C4 fix" 注释：代码修复记录，说明之前的 placeholder 问题已解决 |

### 代码设计模式（2 项）

| 文件 | 行号 | 说明 |
|------|------|------|
| `translation_service.dart` | 318 | `no-op` 注释：方法的空实现是向后兼容设计，非 mock |
| `kayak_data_table.dart` | 78 | `return []` 是分页边界条件处理，非 mock 数据返回 |

---

## 后端 API 实现对照表

以下为本次审计涉及的后端 API 状态汇总：

| 路由 | 方法 | 已在 `routes.rs` | 前端是否已调用 | 状态 |
|------|------|:---:|:---:|------|
| `/api/v1/workbenches/{id}` | PUT | ✅ | ❌ (TODO) | 前端待接入 |
| `/api/v1/workbenches/{id}` | DELETE | ✅ | ❌ (TODO) | 前端待接入 |
| `/api/v1/workbenches/{id}/devices` | POST | ✅ | ❌ (TODO) | 前端待接入 |
| `/api/v1/devices/{id}/points` | GET | ✅ | ⚠️ (部分) | device_list_tab 未接入 |
| `/api/v1/devices/{id}/connect` | POST | ❌ | ❌ (TODO) | 后端需实现 |
| `/api/v1/devices/{id}/disconnect` | POST | ❌ | ❌ (TODO) | 后端需实现 |
| `/api/v1/protocols` | GET | ❌ | ✅ (调用了但404) | 后端需实现 |
| `/api/v1/system/serial-ports` | GET | ❌ | ✅ (调用了但404) | 后端需实现 |
| `/api/v1/devices/{id}/test-connection` | POST | ❌ | ✅ (调用了但404) | 后端需实现 |

---

## 修复优先级建议

### P0（阻塞用户体验）
1. `home_screen.dart:54` — 首页"进入工作台"按钮无响应（导航）
2. `workbench_detail_page.dart:266` — 删除按钮无效

### P1（功能完整性）
3. `device_list_tab.dart:255` — 设备测点列表永远为空
4. `workbench_detail_page.dart:70` — 编辑工作台按钮无效
5. `workbench_detail_page.dart:189` — 添加设备按钮无效

### P2（后端需先实现）
6. `protocol_service.dart` — 协议列表、串口扫描、连接测试 三条 API 需后端先实现
7. `device_list_tab.dart:213` — 设备连接/断开切换（需后端 API）

### P3（新功能）
8. `home_screen.dart:62` — 设置页面（全新功能）
