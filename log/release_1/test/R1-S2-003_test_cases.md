# R1-S2-003-A 设备连接测试功能 - 测试用例

**任务**: R1-S2-003-A 设备连接测试功能测试用例设计
**测试设计者**: sw-mike (Software Test Engineer)
**日期**: 2026-05-03
**版本**: 1.0
**状态**: 待审查

**被测文件**:
- `kayak-frontend/lib/features/workbench/widgets/device/connection_test_widget.dart`
- `kayak-frontend/lib/features/workbench/widgets/device/modbus_tcp_form.dart`
- `kayak-frontend/lib/features/workbench/widgets/device/modbus_rtu_form.dart`
- `kayak-frontend/lib/features/workbench/services/protocol_service.dart`
- `kayak-frontend/lib/features/workbench/models/protocol_config.dart`
- `kayak-backend/src/api/handlers/device.rs` (`test_connection` handler)
- `kayak-backend/src/services/device/types.rs` (`TestConnectionResult`)

---

## 目录

1. [一、ConnectionTestWidget 状态渲染测试](#一connectiontestwidget-状态渲染测试)
2. [二、状态机转换测试](#二状态机转换测试)
3. [三、按钮交互测试](#三按钮交互测试)
4. [四、API 集成测试](#四api-集成测试)
5. [五、错误处理测试](#五错误处理测试)
6. [六、跨表单复用测试](#六跨表单复用测试)
7. [七、汇总表](#七汇总表)

---

## 一、ConnectionTestWidget 状态渲染测试

### TC-CONN-001: idle 状态渲染

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | `ConnectionTestWidget` 以 `state = ConnectionTestState.idle` 挂载 |
| **测试步骤** | 1. 构造 Widget：`state=idle`, `onTest=mockCallback`, `message=null`, `latencyMs=null`<br>2. 挂载到 Widget 树<br>3. 检查按钮文字、图标、颜色<br>4. 检查是否存在结果消息容器 |
| **预期结果** | 1. 按钮文字为"测试连接"<br>2. 按钮图标为 `Icons.bug_report`<br>3. 按钮前景色为 `theme.colorScheme.primary`<br>4. 按钮可点击 (`onPressed != null`)<br>5. Column 仅含 1 个 child（无结果消息行） |
| **覆盖代码** | `_buildButton()` idle 分支 (行 78, 88), `build()` 行 33-45 |

### TC-CONN-002: testing 状态渲染

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | `ConnectionTestWidget` 以 `state = ConnectionTestState.testing` 挂载 |
| **测试步骤** | 1. 构造 Widget：`state=testing`, `onTest=mockCallback`<br>2. 挂载到 Widget 树<br>3. 检查按钮文字、图标（应为 CircularProgressIndicator）<br>4. 检查按钮是否禁用<br>5. 检查是否有结果消息 |
| **预期结果** | 1. 按钮文字为"测试中..."<br>2. 按钮 `icon` 为 `SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2))`<br>3. `onPressed` 为 `null`（按钮禁用）<br>4. 无结果消息行（Column 仅 1 个 child） |
| **覆盖代码** | `_buildButton()` testing 分支 (行 49, 66-68, 73, 82-83) |

### TC-CONN-003: success 状态渲染

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | `ConnectionTestWidget` 以 `state = ConnectionTestState.success`, `message='连接成功'`, `latencyMs=23` 挂载 |
| **测试步骤** | 1. 构造 Widget<br>2. 挂载到 Widget 树<br>3. 检查按钮文字、图标、颜色<br>4. 检查结果消息行内容 |
| **预期结果** | 1. 按钮文字为"连接成功"<br>2. 按钮图标为 `Icons.check_circle`<br>3. 按钮前景色为 `AppColorSchemes.success`<br>4. Column 含 2 个 children（按钮 + SizedBox + 结果消息）<br>5. 结果消息行显示文字"连接成功 · 延迟 23ms" |
| **覆盖代码** | `_buildButton()` success 分支 (行 54-55, 74-75, 84-85)<br>`_buildResultMessage()` success 分支 (行 98-100, 115-116, 122-126) |

### TC-CONN-004: failed 状态渲染

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | `ConnectionTestWidget` 以 `state = ConnectionTestState.failed`, `message='串口超时'` 挂载 |
| **测试步骤** | 1. 构造 Widget<br>2. 挂载到 Widget 树<br>3. 检查按钮文字、图标、颜色<br>4. 检查结果消息行内容 |
| **预期结果** | 1. 按钮文字为"连接失败"<br>2. 按钮图标为 `Icons.error`<br>3. 按钮前景色为 `theme.colorScheme.error`<br>4. 结果消息文字为"串口超时"（不包含延迟信息）<br>5. 结果消息行背景为 `theme.colorScheme.errorContainer`<br>6. 结果消息文字颜色为 `theme.colorScheme.error` |
| **覆盖代码** | `_buildButton()` failed 分支 (行 56-57, 76-77, 86-87)<br>`_buildResultMessage()` failed 分支 (行 99, 105, 115-116, 122-126) |

### TC-CONN-005: success 状态 latencyMs 为 null

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `ConnectionTestWidget` 以 `state = ConnectionTestState.success`, `message='连接成功'`, `latencyMs=null` 挂载 |
| **测试步骤** | 1. 构造 Widget<br>2. 挂载到 Widget 树<br>3. 检查结果消息行文字 |
| **预期结果** | 结果消息显示"连接成功 · 延迟 ?ms"（`?` 占位符） |
| **覆盖代码** | `_buildResultMessage()` 行 100: `latencyMs ?? '?'` |

### TC-CONN-006: failed 状态 message 为 null

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `ConnectionTestWidget` 以 `state = ConnectionTestState.failed`, `message=null` 挂载 |
| **测试步骤** | 1. 构造 Widget<br>2. 挂载到 Widget 树<br>3. 检查是否显示结果消息行 |
| **预期结果** | 不显示结果消息行（`message != null` 条件为 false） |
| **覆盖代码** | `build()` 行 36: `if (state == ConnectionTestState.failed && message != null)` |

### TC-CONN-007: success 状态结果消息样式验证

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `state = ConnectionTestState.success`, `message='ok'`, `latencyMs=5` |
| **测试步骤** | 1. 挂载 Widget<br>2. 检查结果容器样式<br>3. 检查图标和文字颜色 |
| **预期结果** | 1. Container 背景色: `AppColorSchemes.success.withValues(alpha: 0.12)`<br>2. Container 圆角: `BorderRadius.circular(8)`<br>3. Container padding: `EdgeInsets.symmetric(horizontal:12, vertical:8)`<br>4. 图标为 `Icons.check_circle`, 大小 16, 颜色 `AppColorSchemes.success`<br>5. Row 中包含图标 (16px) + SizedBox(8px) + Expanded Text |
| **覆盖代码** | `_buildResultMessage()` 行 107-131 |

---

## 二、状态机转换测试

### TC-CONN-008: idle → testing → success 完整正向流程

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | `ModbusTcpForm` 挂载，`deviceId='dev-001'`，已填写合法参数 (host='192.168.1.100', port=502)<br>Mock `ProtocolService.testConnection()` 返回 `ConnectionTestResult(success: true, message: '连接成功', latencyMs: 15)` |
| **测试步骤** | 1. 验证初始状态为 idle（按钮文字"测试连接"）<br>2. 点击"测试连接"按钮<br>3. 验证立即进入 testing 状态（按钮文字"测试中..."，禁用）<br>4. 等待 mock API 返回<br>5. 验证进入 success 状态（按钮文字"连接成功"，check_circle 图标）<br>6. 验证结果显示"连接成功 · 延迟 15ms"<br>7. 等待 5 秒<br>8. 验证自动恢复到 idle 状态 |
| **预期结果** | 状态序列: idle → testing → success → idle (5s后)<br>各状态 UI 与 TC-CONN-001/002/003 一致 |
| **覆盖代码** | `_testConnection()` 行 100-138, `_buildButton()`, `_buildResultMessage()` |

### TC-CONN-009: idle → testing → failed 完整错误流程

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | `ModbusRtuForm` 挂载，`deviceId='dev-002'`，已选择串口<br>Mock `ProtocolService.testConnection()` 返回 `ConnectionTestResult(success: false, message: '串口无响应')` |
| **测试步骤** | 1. 验证初始为 idle<br>2. 点击"测试连接"按钮<br>3. 验证进入 testing 状态<br>4. 等待 mock API 返回<br>5. 验证进入 failed 状态（按钮文字"连接失败"，error 图标）<br>6. 验证错误消息"串口无响应"<br>7. 等待 5 秒<br>8. 验证状态保持 failed（不自动重置） |
| **预期结果** | 状态序列: idle → testing → failed<br>5 秒后状态保持 failed（不自动重置为 idle） |
| **覆盖代码** | `_testConnection()` 行 114-121: failed 分支<br>自动重置逻辑仅 success 分支 (行 125-131) |

### TC-CONN-010: success 自动重置计时器（5 秒）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | Mock API 返回 success，状态已变为 success |
| **测试步骤** | 1. 触发测试并等待 success<br>2. 使用 `tester.pump(Duration(seconds: 3))` 推进 3 秒<br>3. 验证状态仍为 success<br>4. 使用 `tester.pump(Duration(seconds: 3))` 再推进 3 秒（总计 6 秒）<br>5. 验证状态已变为 idle |
| **预期结果** | 1. 3 秒后: 状态仍为 success<br>2. 6 秒后 (5 秒超时已过): 状态变为 idle<br>3. 按钮文字恢复为"测试连接"，结果消息消失 |
| **覆盖代码** | `_testConnection()` 行 125-131: `Future.delayed(Duration(seconds: 5))` |

### TC-CONN-011: 快速连续测试（success → 重新测试 → failed）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 第一次测试返回 success（自动重置计时中）<br>第二次测试返回 failed |
| **测试步骤** | 1. 第一次点击"测试连接"→ success<br>2. 在 5 秒自动重置前（success 状态可见）再次点击"测试连接"<br>3. Mock 返回 failed<br>4. 验证状态变为 failed<br>5. 再等待 6 秒，验证不自动重置 |
| **预期结果** | 1. 第一次 success → 第二次点击可触发测试（success 状态按钮仍可点击）<br>2. 第二次 failed → 不自动重置<br>3. 第一次的 `Future.delayed` 不会错误地将 failed 重置为 idle（`mounted` 和 `_testState` 检查） |
| **覆盖代码** | 行 127-128: `if (mounted)` 内的 `setState` |

### TC-CONN-012: 多次测试间状态正确清理

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 两次测试: 第一次 success (message='A', latencyMs=10), 第二次 failed (message='B') |
| **测试步骤** | 1. 第一次测试→success, 验证消息 'A' 和延迟 10<br>2. 第二次测试→failed, 验证消息变为 'B'<br>3. 验证延迟信息不显示 |
| **预期结果** | 1. `_testMessage` 和 `_testLatencyMs` 在每次 `_testConnection()` 开始时被重置为 null（行 102-104）<br>2. 第二次 failed 不会残留第一次的 latencyMs |
| **覆盖代码** | `_testConnection()` 行 102-104: 状态重置 |

---

## 三、按钮交互测试

### TC-CONN-013: idle 状态按钮可点击

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | `ConnectionTestWidget` 处于 idle 状态 |
| **测试步骤** | 1. 挂载 Widget<br>2. 查找 `connection-test-button` key<br>3. 执行 `tester.tap(find.byKey(...))`<br>4. 验证 `onTest` callback 被调用 |
| **预期结果** | 1. `find.byKey(Key('connection-test-button'))` 存在<br>2. 点击触发 `onTest`<br>3. `onPressed != null` |
| **覆盖代码** | `_buildButton()` 行 66: `onPressed: isTesting ? null : onTest` (idle 分支) |

### TC-CONN-014: testing 状态按钮禁用（不可重复点击）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | `ConnectionTestWidget` 处于 testing 状态 |
| **测试步骤** | 1. 挂载 Widget 于 testing 状态<br>2. 查找按钮<br>3. 验证 onPressed 为 null<br>4. 尝试点击按钮（Flutter 不会触发 null onPressed） |
| **预期结果** | 1. 按钮 `onPressed` 为 `null`<br>2. 点击按钮不会触发任何回调<br>3. 按钮视觉表现灰显/不可交互 |
| **覆盖代码** | `_buildButton()` 行 49: `isTesting = state == ConnectionTestState.testing`<br>行 66: `onPressed: isTesting ? null : onTest` |

### TC-CONN-015: success 状态按钮可点击（允许重新测试）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `ConnectionTestWidget` 处于 success 状态 |
| **测试步骤** | 1. 挂载 Widget 于 success 状态<br>2. 验证按钮可点击<br>3. 点击按钮 |
| **预期结果** | `onTest` callback 被调用，按钮可点击（success 不是 testing） |
| **覆盖代码** | 行 49, 66: `isTesting` 仅为 testing 态为 true |

### TC-CONN-016: failed 状态按钮可点击（允许重试）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `ConnectionTestWidget` 处于 failed 状态 |
| **测试步骤** | 1. 挂载 Widget 于 failed 状态<br>2. 验证按钮可点击<br>3. 点击按钮 |
| **预期结果** | `onTest` callback 被调用（failed 态允许用户重试） |
| **覆盖代码** | 行 49, 66 |

---

## 四、API 集成测试

### TC-CONN-017: ModbusTcpForm 触发 POST /devices/{id}/test-connection

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | `ModbusTcpForm` 挂载，`deviceId='550e8400-...'`，已填写 host='192.168.1.100', port=502, slaveId=1, timeoutMs=5000, poolSize=4 |
| **测试步骤** | 1. 点击"测试连接"按钮<br>2. 验证 `ProtocolService.testConnection()` 被调用<br>3. 验证请求参数 |
| **预期结果** | 1. API 被调用: `POST /api/v1/devices/550e8400-.../test-connection`<br>2. Request body 包含:<br>   `{"host": "192.168.1.100", "port": 502, "slave_id": 1, "timeout_ms": 5000, "connection_pool_size": 4}`<br>3. 使用 `getConfig().toJson()` 生成的 config |
| **覆盖代码** | `_testConnection()` 行 108-112: `service.testConnection(widget.deviceId!, getConfig().toJson())` |

### TC-CONN-018: ModbusRtuForm 触发 POST /devices/{id}/test-connection

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | `ModbusRtuForm` 挂载，`deviceId='dev-rtu-01'`，已选串口='/dev/ttyUSB0', baudRate=115200, dataBits=8, stopBits=1, parity='Even', slaveId=10, timeoutMs=1000 |
| **测试步骤** | 1. 点击"测试连接"<br>2. 验证 API 调用参数 |
| **预期结果** | 1. `POST /api/v1/devices/dev-rtu-01/test-connection`<br>2. Request body: `{"port":"/dev/ttyUSB0","baud_rate":115200,"data_bits":8,"stop_bits":1,"parity":"Even","slave_id":10,"timeout_ms":1000}` |
| **覆盖代码** | `_testConnection()` 行 155-159: `service.testConnection(widget.deviceId!, getConfig().toJson())` |

### TC-CONN-019: 创建模式使用 deviceId='new'

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `ModbusTcpForm` 以创建模式挂载，`widget.deviceId` 为 `null` |
| **测试步骤** | 1. 点击"测试连接"<br>2. 验证 API 调用的 deviceId 参数 |
| **预期结果** | API 路径包含 `'new'` 作为 deviceId: `POST /api/v1/devices/new/test-connection`<br>`_testConnection()` 行 110: `widget.deviceId ?? 'new'` |
| **覆盖代码** | `_testConnection()` 行 110 |

### TC-CONN-020: ConnectionTestResult.fromJson 字段映射

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | Mock API 返回 JSON: `{"data":{"connected":true,"message":"OK","latency_ms":42}}`<br>或 `{"data":{"success":true,"message":"OK","latency_ms":42}}`（取决于后端实现） |
| **测试步骤** | 1. 验证 `ProtocolService.testConnection()` 返回的 `ConnectionTestResult` 各字段<br>2. 确认 `success`/`connected` 字段映射正确 |
| **预期结果** | ⚠️ **已知风险**: 后端 `TestConnectionResult` 字段名为 `connected`，前端 `ConnectionTestResult.fromJson` 读取 `json['success']`。需要验证字段名是否一致，否则 `null as bool` 将导致运行时异常 |
| **覆盖代码** | `ConnectionTestResult.fromJson()` 行 244-249<br>`protocol_service.dart` 行 44-45 |

### TC-CONN-021: API 返回完整 latency_ms 信息

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | Mock API 返回 `{"data":{"connected":true,"message":"连接成功","latency_ms":87}}` |
| **测试步骤** | 1. 触发连接测试<br>2. 验证 `ConnectionTestResult.latencyMs` 值<br>3. 验证 Widget 显示延迟 |
| **预期结果** | 1. `result.latencyMs == 87`<br>2. Widget 显示"连接成功 · 延迟 87ms" |
| **覆盖代码** | `_testConnection()` 行 119-121: `_testLatencyMs = result.latencyMs` |

---

## 五、错误处理测试

### TC-CONN-022: service.testConnection() 抛出异常

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | Mock `ProtocolService.testConnection()` 抛出异常 (如 `Exception('网络不可达')`) |
| **测试步骤** | 1. 点击"测试连接"<br>2. 验证 catch 块捕获异常<br>3. 验证状态和消息 |
| **预期结果** | 1. `_testState` = `ConnectionTestState.failed`<br>2. `_testMessage` = `exception.toString()` (例如 `'Exception: 网络不可达'`)<br>3. 不触发 `Future.delayed` 自动重置 |
| **覆盖代码** | `_testConnection()` 行 132-138: `catch (e)` 分支 |

### TC-CONN-023: widget 已销毁时不过度渲染 ($mounted 检查)

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 触发连接测试后，在 API 返回前从 Widget 树移除 `ModbusTcpForm`<br>Mock API 延迟 500ms 返回 |
| **测试步骤** | 1. 挂载 `ModbusTcpForm`<br>2. 点击"测试连接"<br>3. 在 API 返回前调用 `dispose()` 或从树中移除 Widget<br>4. 等待 API 返回 |
| **预期结果** | 1. 不抛出异常 (no `setState() called after dispose()`)<br>2. 两处 `if (!mounted) return;` 生效（行 114, 127）<br>3. `Future.delayed` 回调同样受 `mounted` 保护（行 127-129） |
| **覆盖代码** | `_testConnection()` 行 114: `if (!mounted) return;`<br>行 127: `if (mounted)` |

### TC-CONN-024: API 返回 404 (设备不存在)

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | Mock `ApiClientInterface.post()` 抛出异常（模拟 HTTP 404 响应→Dart 异常） |
| **测试步骤** | 1. 点击"测试连接"<br>2. 验证错误信息展示 |
| **预期结果** | 1. 状态变为 `ConnectionTestState.failed`<br>2. 消息包含 404 相关信息（通过 `catch (e)` 捕获）<br>3. 按钮显示"连接失败"和 error 图标 |
| **覆盖代码** | `ProtocolService.testConnection()` 行 40-46<br>`_testConnection()` catch 分支 |

### TC-CONN-025: API 返回 400 (无效配置)

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | Mock API 返回 400 Bad Request 异常 |
| **测试步骤** | 1. 填写无效参数（如 port=-1）<br>2. 点击"测试连接"<br>3. 验证状态和消息 |
| **预期结果** | 1. 状态变为 `failed`<br>2. 错误消息可见<br>3. 用户可修复参数后重新测试 |
| **覆盖代码** | `catch (e)` 路径 |

### TC-CONN-026: widget 销毁后自动重置计时器不执行

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 连接测试成功（success 状态），`Future.delayed(5s)` 已注册<br>在 5 秒内销毁 Widget |
| **测试步骤** | 1. 触发测试→成功<br>2. 2 秒后从树中移除 Widget<br>3. 等待超过 5 秒（总计）<br>4. 验证无异常抛出 |
| **预期结果** | 1. `Future.delayed` 回调中的 `if (mounted)` 返回 false<br>2. `setState` 不被调用<br>3. 无 `setState() called after dispose()` 异常 |
| **覆盖代码** | `_testConnection()` 行 127: `if (mounted)` 保护 |

---

## 六、跨表单复用测试

### TC-CONN-027: TCP 和 RTU 表单测试状态独立

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 同一界面同时显示 `ModbusTcpForm` 和 `ModbusRtuForm`（如在 tab 切换场景）<br>两者共享同一个 `ProtocolService` 实例 |
| **测试步骤** | 1. TCP 表单点击"测试连接"→ success<br>2. 切换到 RTU 表单，点击"测试连接"→ failed<br>3. 验证 TCP 表单状态不受 RTU 表单影响<br>4. 切换回 TCP 表单<br>5. 验证 TCP 仍显示 success（或已自动重置为 idle） |
| **预期结果** | 1. TCP 的 `_testState` 和 RTU 的 `_testState` 是独立的实例变量<br>2. TCP success 不影响 RTU 的状态显示<br>3. RTU failed 不影响 TCP 的状态显示 |
| **覆盖代码** | `ModbusTcpFormState._testState` vs `ModbusRtuFormState._testState` 各自独立 |

### TC-CONN-028: ConnectionTestWidget 纯展示组件（无业务逻辑）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `ConnectionTestWidget` 自身为 `StatelessWidget` |
| **测试步骤** | 1. 以不同 state 参数挂载 Widget<br>2. 验证组件不会自行修改状态<br>3. 验证状态变化完全由父组件驱动 |
| **预期结果** | 1. `ConnectionTestWidget` 无内部状态管理<br>2. 点击按钮仅调用 `onTest` 回调，不改变自身 state<br>3. 状态转换逻辑完全属于 `ModbusTcpFormState` / `ModbusRtuFormState` |
| **覆盖代码** | `class ConnectionTestWidget extends StatelessWidget` (行 16) |

---

## 七、汇总表

| 分类 | 用例数 | PASS | FAIL | BLOCKED |
|------|--------|------|------|---------|
| **状态渲染测试** | 7 | - | - | - |
| **状态机转换测试** | 5 | - | - | - |
| **按钮交互测试** | 4 | - | - | - |
| **API 集成测试** | 5 | - | - | - |
| **错误处理测试** | 5 | - | - | - |
| **跨表单复用测试** | 2 | - | - | - |
| **总计** | **28** | **0** | **0** | **0** |

### 用例清单

| ID | 分类 | 描述 | 优先级 |
|----|------|------|--------|
| TC-CONN-001 | 状态渲染 | idle 状态渲染 | High |
| TC-CONN-002 | 状态渲染 | testing 状态渲染 | High |
| TC-CONN-003 | 状态渲染 | success 状态渲染 | High |
| TC-CONN-004 | 状态渲染 | failed 状态渲染 | High |
| TC-CONN-005 | 状态渲染 | latencyMs 为 null 显示 "?" | Medium |
| TC-CONN-006 | 状态渲染 | failed 且 message 为 null 不显消息 | Medium |
| TC-CONN-007 | 状态渲染 | success 结果消息样式验证 | Medium |
| TC-CONN-008 | 状态机转换 | idle→testing→success 正向流程 | Critical |
| TC-CONN-009 | 状态机转换 | idle→testing→failed 错误流程 | Critical |
| TC-CONN-010 | 状态机转换 | success 5秒自动重置 | High |
| TC-CONN-011 | 状态机转换 | success 期间重试→failed | Medium |
| TC-CONN-012 | 状态机转换 | 多次测试间状态正确清理 | Medium |
| TC-CONN-013 | 按钮交互 | idle 状态按钮可点击 | High |
| TC-CONN-014 | 按钮交互 | testing 状态按钮禁用 | High |
| TC-CONN-015 | 按钮交互 | success 状态按钮可点击（重试） | Medium |
| TC-CONN-016 | 按钮交互 | failed 状态按钮可点击（重试） | Medium |
| TC-CONN-017 | API 集成 | TCP 表单触发 test-connection API | Critical |
| TC-CONN-018 | API 集成 | RTU 表单触发 test-connection API | Critical |
| TC-CONN-019 | API 集成 | 创建模式 deviceId='new' | Medium |
| TC-CONN-020 | API 集成 | ConnectionTestResult 字段映射 | Critical |
| TC-CONN-021 | API 集成 | latency_ms 完整传递 | Medium |
| TC-CONN-022 | 错误处理 | service 抛出异常捕获 | Critical |
| TC-CONN-023 | 错误处理 | widget 销毁后 $mounted 检查 | High |
| TC-CONN-024 | 错误处理 | API 返回 404 | High |
| TC-CONN-025 | 错误处理 | API 返回 400 | High |
| TC-CONN-026 | 错误处理 | widget 销毁后定时器不执行 | Medium |
| TC-CONN-027 | 跨表单复用 | TCP/RTU 状态独立 | High |
| TC-CONN-028 | 跨表单复用 | ConnectionTestWidget 纯展示组件 | Medium |

### 优先级分布

| 优先级 | 数量 | 占比 |
|--------|------|------|
| Critical | 6 | 21.4% |
| High | 12 | 42.9% |
| Medium | 10 | 35.7% |
| Low | 0 | 0% |
| **合计** | **28** | **100%** |

---

## 测试执行说明

### 模拟策略

1. **Widget 测试环境**: 使用 `flutter_test` 框架
2. **Mock ProtocolService**: 注入 mock 实现控制 API 返回值
3. **时间推进**: 使用 `tester.pump()` / `tester.pump(Duration(...))` 推进异步操作和定时器
4. **Widget Key 查找**: 使用 `find.byKey(Key('connection-test-button'))` 定位按钮

### 已知风险

| 风险ID | 描述 | 影响用例 |
|--------|------|----------|
| RISK-001 | 后端 `TestConnectionResult.connected` 与前端 `ConnectionTestResult.fromJson` 读取 `json['success']` 字段名不一致，可能导致 `null as bool` 运行时异常 | TC-CONN-020 |
| RISK-002 | `mounted` 检查仅在 `ConsumerState` 中有效，若 API 调用发生在非 widget 上下文中则无效 | TC-CONN-023, TC-CONN-026 |
