# R1-S2-001-A Modbus RTU 参数表单 - 测试用例

**任务**: R1-S2-001-A Modbus RTU 表单测试用例
**测试设计者**: sw-mike
**日期**: 2026-05-03
**被测文件**:
- `kayak-frontend/lib/features/workbench/widgets/device/modbus_rtu_form.dart`
- `kayak-frontend/lib/features/workbench/validators/device_validators.dart`
- `kayak-frontend/lib/features/workbench/services/protocol_service.dart`
- `kayak-frontend/lib/features/workbench/models/protocol_config.dart`
- `kayak-frontend/lib/features/workbench/widgets/device/connection_test_widget.dart`

---

## 一、串口扫描测试 (Serial Port Scanning)

### TC-SCAN-001: 创建模式自动触发串口扫描

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 表单以创建模式初始化 (`isEditMode = false`, 无 `initialConfig`) |
| **测试步骤** | 1. 挂载 `ModbusRtuForm` 到 Widget 树<br>2. 等待一帧渲染完成 (addPostFrameCallback 触发)<br>3. 观察扫描按钮状态和下拉框状态 |
| **预期结果** | 1. 扫描按钮显示 `CircularProgressIndicator` 和文字“扫描中...”<br>2. 按钮处于 `onPressed == null` 状态（禁用）<br>3. 下拉框 hint 显示“扫描中...” |
| **覆盖代码** | `initState()` 第 82-83 行: `addPostFrameCallback((_) => _scanPorts())` |

### TC-SCAN-002: 扫描返回多个串口

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 后端 `/api/v1/system/serial-ports` 返回 2+ 个串口 (例如 `/dev/ttyUSB0`, `/dev/ttyUSB1`) |
| **测试步骤** | 1. 点击“扫描串口”按钮触发扫描<br>2. 等待扫描完成<br>3. 展开下拉框<br>4. 选择第二个串口 |
| **预期结果** | 1. 按钮图标变为 `check_circle`，文字变为“扫描完成”<br>2. 下拉框包含所有返回的串口选项，每项显示 `path` 和 `description`<br>3. 第一个串口被自动选中 (`_selectedPort = ports.first.path`)<br>4. 可正常切换到第二个串口 |
| **覆盖代码** | `_scanPorts()` 第 130-136 行 |

### TC-SCAN-003: 扫描返回空列表

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 后端 `/api/v1/system/serial-ports` 返回空数组 `{"data": []}` |
| **测试步骤** | 1. 点击“扫描串口”按钮<br>2. 等待扫描完成<br>3. 观察按钮状态和下拉框状态 |
| **预期结果** | 1. `_scanState` = `ScanState.noDevices`<br>2. 按钮图标变为 `radar` (非 check_circle，也非 error)，文字变为“扫描串口”(重置为非完成态)<br>3. 下拉框 hint 显示“无可用串口”<br>4. 下拉框下方显示错误提示“未检测到串口设备”<br>5. `_selectedPort` 保持 `null` (不自选) |
| **覆盖代码** | `_scanPorts()` 第 132 行: `ports.isEmpty` 分支 |

### TC-SCAN-004: 扫描网络错误 / 后端异常

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 后端 `/api/v1/system/serial-ports` 返回 HTTP 500 或其他异常 |
| **测试步骤** | 1. 点击“扫描串口”按钮<br>2. 等待异常抛出<br>3. 观察按钮和下拉框状态 |
| **预期结果** | 1. `_scanState` = `ScanState.failed`<br>2. 按钮图标变为 `error`，文字变为“扫描失败”<br>3. 下拉框下方显示错误提示“串口扫描失败”<br>4. 按钮恢复可点击状态（允许重试） |
| **覆盖代码** | `_scanPorts()` 第 138-141 行: `catch (e)` 分支 |

### TC-SCAN-005: 扫描进行中按钮禁用

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 扫描已触发且仍在等待后端响应 |
| **测试步骤** | 1. 点击“扫描串口”按钮<br>2. 在响应返回前，尝试再次点击按钮 |
| **预期结果** | 按钮 `onPressed` 为 `null`，无法触发第二次扫描 |
| **覆盖代码** | `_buildScanButton()` 第 331 行: `onPressed: isScanning ? null : _scanPorts` |

### TC-SCAN-006: 编辑模式不自动扫描

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 表单以编辑模式初始化 (`isEditMode = true`，传入 `initialConfig`) |
| **测试步骤** | 1. 挂载 `ModbusRtuForm` 到 Widget 树<br>2. 等待多帧渲染<br>3. 观察扫描按钮初始状态 |
| **预期结果** | 1. 扫描按钮显示 `Icons.radar` 和文字“扫描串口”<br>2. 不会自动触发 `_scanPorts()`<br>3. 下拉框已预填 `initialConfig.port` 的值 |
| **覆盖代码** | `initState()` 第 82-83 行: 仅 `else` 分支触发 |

---

## 二、表单字段测试 (Form Field Tests)

### TC-FIELD-001: 创建模式默认值验证

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 表单以创建模式初始化 |
| **测试步骤** | 1. 挂载表单<br>2. 检查各字段初始值 |
| **预期结果** | - 波特率默认 `9600`<br>- 数据位默认 `8`<br>- 停止位默认 `1`<br>- 校验默认 `None`<br>- 从站ID输入框默认文本 `'1'`<br>- 超时输入框默认文本 `'1000'`（后缀 `ms`） |
| **覆盖代码** | `initState()` 第 80-81 行: 默认值初始化 |

### TC-FIELD-002: 编辑模式预填 initialConfig

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 传入 `initialConfig`: `port='/dev/ttyUSB0'`, `baudRate=115200`, `dataBits=8`, `stopBits=1`, `parity='Even'`, `slaveId=10`, `timeoutMs=500` |
| **测试步骤** | 1. 以编辑模式挂载表单<br>2. 检查所有字段值 |
| **预期结果** | - 串口下拉框选中 `/dev/ttyUSB0`<br>- 波特率显示 `115200`<br>- 数据位显示 `8`<br>- 停止位显示 `1`<br>- 校验显示 `Even`<br>- 从站ID文本框内容 `'10'`<br>- 超时文本框内容 `'500'` |
| **覆盖代码** | `initState()` 第 67-78 行: `initialConfig` 分支 |

### TC-FIELD-003: 波特率下拉框选项完整性

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **测试步骤** | 1. 展开波特率下拉框<br>2. 列出所有可用选项 |
| **预期结果** | 包含 5 个选项: `9600`, `19200`, `38400`, `57600`, `115200` |
| **覆盖代码** | `baudRateOptions` 常量 (第 59 行) |

### TC-FIELD-004: 数据位下拉框选项完整性

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **测试步骤** | 1. 展开数据位下拉框<br>2. 列出所有可用选项 |
| **预期结果** | 包含 2 个选项: `7`, `8` |
| **覆盖代码** | `dataBitsOptions` 常量 (第 60 行) |

### TC-FIELD-005: 停止位下拉框选项完整性

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **测试步骤** | 1. 展开停止位下拉框<br>2. 列出所有可用选项 |
| **预期结果** | 包含 2 个选项: `1`, `2` |
| **覆盖代码** | `stopBitsOptions` 常量 (第 61 行) |

### TC-FIELD-006: 校验下拉框选项完整性

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **测试步骤** | 1. 展开校验下拉框<br>2. 列出所有可用选项 |
| **预期结果** | 包含 3 个选项: `None`, `Even`, `Odd` |
| **覆盖代码** | `parityOptions` 常量 (第 62 行) |

### TC-FIELD-007: 从站ID字段 - 键盘类型

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **测试步骤** | 1. 点击从站ID输入框<br>2. 观察弹出键盘类型 |
| **预期结果** | 弹出数字键盘 (`TextInputType.number`) |
| **覆盖代码** | `_buildSlaveIdField()` 第 473 行: `keyboardType: TextInputType.number` |

### TC-FIELD-008: 超时字段 - 键盘类型与后缀

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **测试步骤** | 1. 点击超时输入框<br>2. 观察弹出键盘类型<br>3. 观察输入框后缀 |
| **预期结果** | 1. 弹出数字键盘 (`TextInputType.number`)<br>2. 输入框右侧显示 `ms` 后缀 (`suffixText: 'ms'`) |
| **覆盖代码** | `_buildTimeoutField()` 第 487-488 行 |

### TC-FIELD-009: onFieldChanged 回调触发

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 表单已挂载，传入 `onFieldChanged` 回调 |
| **测试步骤** | 1. 修改波特率为 `19200`<br>2. 修改从站ID 为 `5`<br>3. 修改校验为 `Even`<br>4. 每次修改后验证回调是否被调用 |
| **预期结果** | 每次字段变更都会调用 `onFieldChanged` 回调 |
| **覆盖代码** | `onChanged` 回调: 第 309, 380, 404, 429, 454, 474, 489 行 |

### TC-FIELD-010: 连接测试按钮 - 初始状态

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 表单刚挂载，未执行任何测试 |
| **测试步骤** | 1. 观察 `ConnectionTestWidget` 的初始渲染 |
| **预期结果** | - 按钮显示文字“测试连接”<br>- 按钮图标为 `Icons.bug_report`<br>- 按钮可点击<br>- 无结果消息显示 |
| **覆盖代码** | `ConnectionTestWidget` 的 `ConnectionTestState.idle` 状态 |

### TC-FIELD-011: 连接测试按钮 - 测试中状态

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 表单已挂载，已配置合法参数 |
| **测试步骤** | 1. 点击“测试连接”按钮<br>2. 在响应返回前观察按钮状态 |
| **预期结果** | - 按钮文字变为“测试中...”<br>- 按钮图标变为 `CircularProgressIndicator`<br>- 按钮处于禁用状态 (`onPressed == null`) |
| **覆盖代码** | `_testConnection()` 第 147-149 行: `_testState = ConnectionTestState.testing` |

### TC-FIELD-012: 连接测试按钮 - 成功状态

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 后端返回 `{"success": true, "message": "连接成功", "latency_ms": 15}` |
| **测试步骤** | 1. 点击“测试连接”<br>2. 等待响应返回<br>3. 观察按钮状态和结果消息 |
| **预期结果** | - 按钮文字变为“连接成功”<br>- 按钮图标变为 `Icons.check_circle`，颜色为 `AppColorSchemes.success`<br>- 显示结果消息“连接成功 · 延迟 15ms”<br>- 5 秒后自动恢复到 idle 状态 |
| **覆盖代码** | `_buildButton()` success 分支, `_buildResultMessage()` success 分支 |

### TC-FIELD-013: 连接测试按钮 - 失败状态

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 后端返回 `{"success": false, "message": "串口超时"}` |
| **测试步骤** | 1. 点击“测试连接”<br>2. 等待响应返回<br>3. 观察按钮状态和错误消息 |
| **预期结果** | - 按钮文字变为“连接失败”<br>- 按钮图标变为 `Icons.error`，颜色为 `theme.colorScheme.error`<br>- 显示错误消息“串口超时” |
| **覆盖代码** | `_buildButton()` failed 分支, `_buildResultMessage()` failed 分支 |

### TC-FIELD-014: 连接测试 - 网络异常捕获

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `service.testConnection()` 抛出异常 (如网络不可达) |
| **测试步骤** | 1. 点击“测试连接”<br>2. 等待异常抛出 |
| **预期结果** | - `_testState` = `ConnectionTestState.failed`<br>- `_testMessage` = 异常对象 `.toString()` |
| **覆盖代码** | `_testConnection()` 第 177-182 行: `catch (e)` 分支 |

---

## 三、参数验证测试 (Parameter Validation)

### TC-VALID-001: 串口未选择时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 串口下拉框未选择任何值 (`_selectedPort == null`) |
| **测试步骤** | 1. 调用 `validate()`<br>2. 或尝试提交表单触发器 validator |
| **预期结果** | 返回 `false`，因为 `_selectedPort == null \|\| _selectedPort!.isEmpty` |
| **覆盖代码** | `validate()` 第 99 行 |

### TC-VALID-002: 从站ID为空时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 串口已选择，从站ID输入框为空 `''` |
| **测试步骤** | 1. 清空从站ID输入框<br>2. 调用 `validate()` 或触发 validator |
| **预期结果** | 1. `DeviceValidators.slaveId` 返回 `'请输入从站ID'`<br>2. `validate()` 返回 `false` |
| **覆盖代码** | `DeviceValidators.slaveId()` 第 47-48 行 |

### TC-VALID-003: 从站ID非数字字符时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 串口已选择 |
| **测试步骤** | 1. 输入 `'abc'`, `'12a'`, `'-5'`, `'3.14'` 作为从站ID<br>2. 每次调用 validator |
| **预期结果** | 1. `DeviceValidators.slaveId` 返回 `'请输入有效数字'`<br>2. `validate()` 返回 `false` |
| **覆盖代码** | `DeviceValidators.slaveId()` 第 50 行: `int.tryParse` 返回 null |

### TC-VALID-004: 从站ID超出范围时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 串口已选择 |
| **测试步骤** | 1. 输入 `0` (小于最小值 1)<br>2. 输入 `248` (大于最大值 247)<br>3. 输入 `-100`<br>4. 输入 `9999`<br>5. 每次调用 validator |
| **预期结果** | 1. `DeviceValidators.slaveId` 返回 `'从站ID范围 1-247'`<br>2. `validate()` 返回 `false` |
| **覆盖代码** | `DeviceValidators.slaveId()` 第 51 行 |

### TC-VALID-005: 从站ID边界值通过验证

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 串口已选择 |
| **测试步骤**> | 1. 输入 `1` (最小值)<br>2. 输入 `247` (最大值)<br>3. 分别调用 `validate()` |
| **预期结果** | `validate()` 返回 `true` (前提: 串口也合法且非 7N1) |
| **覆盖代码** | `DeviceValidators.slaveId()` 边界条件 |

### TC-VALID-006: 超时时间为空时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 串口已选择，从站ID合法 |
| **测试步骤** | 1. 清空超时输入框<br>2. 调用 `validate()` 或触发 validator |
| **预期结果** | 1. `DeviceValidators.timeout` 返回 `'请输入超时时间'`<br>2. `validate()` 返回 `false` |
| **覆盖代码** | `DeviceValidators.timeout()` 第 59 行 |

### TC-VALID-007: 超时时间非数字字符时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 串口已选择，从站ID合法 |
| **测试步骤** | 1. 输入 `'abc'`, `'100ms'`, `'3.5'` 作为超时<br>2. 每次调用 validator |
| **预期结果** | 1. `DeviceValidators.timeout` 返回 `'请输入有效数字'`<br>2. `validate()` 返回 `false` |
| **覆盖代码** | `DeviceValidators.timeout()` 第 61 行 |

### TC-VALID-008: 超时时间超出范围时验证失败

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 串口已选择，从站ID合法 |
| **测试步骤** | 1. 输入 `0` (小于 100ms)<br>2. 输入 `99` (小于 100ms)<br>3. 输入 `60001` (大于 60000ms)<br>4. 每次调用 validator |
| **预期结果** | 1. `DeviceValidators.timeout` 返回 `'超时范围 100-60000ms'`<br>2. validate() 返回 false |
| **覆盖代码** | `DeviceValidators.timeout()` 第 62 行 |

### TC-VALID-009: 超时时间边界值通过验证

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 串口已选择，从站ID合法 |
| **测试步骤** | 1. 输入 `100` (最小值)<br>2. 输入 `60000` (最大值)<br>3. 分别调用 `validate()` |
| **预期结果** | `validate()` 返回 `true` (前提: 非 7N1 组合) |
| **覆盖代码** | `DeviceValidators.timeout()` 边界条件 |

### TC-VALID-010: 7N1 组合验证失败 (数据位7 + 校验None)

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 串口已选择，从站ID合法，超时合法 |
| **测试步骤** | 1. 设置数据位 = `7`, 校验 = `None`<br>2. 调用 `validate()` |
| **预期结果** | `validate()` 返回 `false` (Modbus RTU 不支持 7N1) |
| **覆盖代码** | `validate()` 第 103 行: `_dataBits == 7 && _parity == 'None'`<br>`DeviceValidators.serialParams()` 第 104-109 行 |

### TC-VALID-011: 合法串口参数组合全部通过

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 串口已选择，从站ID=`1`，超时=`1000` |
| **测试步骤** | 测试以下所有合法组合，每次调 `validate()`:<br>- `8N1`: dataBits=8, parity=None, stopBits=1<br>- `8N2`: dataBits=8, parity=None, stopBits=2<br>- `8E1`: dataBits=8, parity=Even, stopBits=1<br>- `8O1`: dataBits=8, parity=Odd, stopBits=1<br>- `7E1`: dataBits=7, parity=Even, stopBits=1<br>- `7O1`: dataBits=7, parity=Odd, stopBits=1<br>- `7E2`: dataBits=7, parity=Even, stopBits=2 |
| **预期结果** | 所有组合 `validate()` 返回 `true` |
| **覆盖代码** | `validate()` 方法全面验证 |

### TC-VALID-012: getConfig 从站ID解析失败时回退为默认值 1

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 从站ID输入框内容为非法数字字符串（例如 `'abc'`） |
| **测试步骤** | 1. 不从表单层面验证直接调用 `getConfig()` |
| **预期结果** | `config.slaveId == 1` (fallback 到默认值) |
| **覆盖代码** | `getConfig()` 第 115 行: `int.tryParse(...) ?? 1` |

### TC-VALID-013: getConfig 超时解析失败时回退为默认值 1000

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 超时输入框内容为非法数字字符串（例如 `'abc'`） |
| **测试步骤** | 1. 不从表单层面验证直接调用 `getConfig()` |
| **预期结果** | `config.timeoutMs == 1000` (fallback 到默认值) |
| **覆盖代码** | `getConfig()` 第 116 行: `int.tryParse(...) ?? 1000` |

### TC-VALID-014: getConfig 串口未选择时返回空字符串

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | `_selectedPort == null` |
| **测试步骤** | 1. 调用 `getConfig()` |
| **预期结果** | `config.port == ''` (空字符串 fallback) |
| **覆盖代码** | `getConfig()` 第 110 行: `_selectedPort ?? ''` |

---

## 四、汇总表

| 分类 | 用例数 | PASS | FAIL | BLOCKED |
|------|--------|------|------|---------|
| **串口扫描** | 6 | - | - | - |
| **表单字段** | 14 | - | - | - |
| **参数验证** | 14 | - | - | - |
| **总计** | **34** | **0** | **0** | **0** |

### 用例清单

| ID | 分类 | 描述 | 优先级 |
|----|------|------|--------|
| TC-SCAN-001 | 串口扫描 | 创建模式自动触发串口扫描 | High |
| TC-SCAN-002 | 串口扫描 | 扫描返回多个串口 | High |
| TC-SCAN-003 | 串口扫描 | 扫描返回空列表 | High |
| TC-SCAN-004 | 串口扫描 | 扫描网络错误 / 后端异常 | High |
| TC-SCAN-005 | 串口扫描 | 扫描进行中按钮禁用 | Medium |
| TC-SCAN-006 | 串口扫描 | 编辑模式不自动扫描 | Medium |
| TC-FIELD-001 | 表单字段 | 创建模式默认值验证 | High |
| TC-FIELD-002 | 表单字段 | 编辑模式预填 initialConfig | High |
| TC-FIELD-003 | 表单字段 | 波特率下拉框选项完整性 | Medium |
| TC-FIELD-004 | 表单字段 | 数据位下拉框选项完整性 | Medium |
| TC-FIELD-005 | 表单字段 | 停止位下拉框选项完整性 | Medium |
| TC-FIELD-006 | 表单字段 | 校验下拉框选项完整性 | Medium |
| TC-FIELD-007 | 表单字段 | 从站ID键盘类型 | Medium |
| TC-FIELD-008 | 表单字段 | 超时键盘类型与后缀 | Medium |
| TC-FIELD-009 | 表单字段 | onFieldChanged 回调触发 | Medium |
| TC-FIELD-010 | 表单字段 | 连接测试按钮初始状态 | Medium |
| TC-FIELD-011 | 表单字段 | 连接测试测试中状态 | Medium |
| TC-FIELD-012 | 表单字段 | 连接测试成功状态 | Medium |
| TC-FIELD-013 | 表单字段 | 连接测试失败状态 | Medium |
| TC-FIELD-014 | 表单字段 | 连接测试网络异常 | Medium |
| TC-VALID-001 | 参数验证 | 串口未选择时验证失败 | Critical |
| TC-VALID-002 | 参数验证 | 从站ID为空 | High |
| TC-VALID-003 | 参数验证 | 从站ID非数字 | High |
| TC-VALID-004 | 参数验证 | 从站ID超出范围 | High |
| TC-VALID-005 | 参数验证 | 从站ID边界值通过 | Medium |
| TC-VALID-006 | 参数验证 | 超时时间为空 | High |
| TC-VALID-007 | 参数验证 | 超时非数字 | Medium |
| TC-VALID-008 | 参数验证 | 超时超出范围 | High |
| TC-VALID-009 | 参数验证 | 超时边界值通过 | Medium |
| TC-VALID-010 | 参数验证 | 7N1组合失败 | Critical |
| TC-VALID-011 | 参数验证 | 合法组合全部通过 | High |
| TC-VALID-012 | 参数验证 | 从站ID解析fallback | Medium |
| TC-VALID-013 | 参数验证 | 超时解析fallback | Medium |
| TC-VALID-014 | 参数验证 | 端口fallback空串 | Medium |

### 优先级分布

| 优先级 | 数量 | 占比 |
|--------|------|------|
| Critical | 2 | 5.9% |
| High | 13 | 38.2% |
| Medium | 19 | 55.9% |
| Low | 0 | 0% |
| **合计** | **34** | **100%** |
