# R1-S2-001-A Modbus RTU 表单 — 测试用例审查报告

**审查人**: sw-tom  
**日期**: 2026-05-03  
**审查文件**: `log/release_1/test/R1-S2-001_test_cases.md` (34 用例)  
**审查结论**: ⚠️ 需修改

---

## 一、审查概要

| 审查维度 | 结果 |
|----------|------|
| 覆盖已有实现的所有功能 | ⚠️ 有遗漏 |
| 是否有遗漏场景 | ⚠️ 有 |
| 测试用例是否可执行 | ⚠️ 部分用例预期与实现不符 |
| 与现有组件接口是否一致 | ⚠️ 有差异 |
| **总体结论** | **需修改** |

---

## 二、逐用例审查

### 2.1 串口扫描测试 (TC-SCAN-001 ~ TC-SCAN-006)

| 用例ID | 优先级 | 审查结果 | 问题描述 |
|--------|--------|----------|----------|
| TC-SCAN-001 | High | ✅ 通过 | 创建模式自动扫描：预期与 `initState()` 第 82-83 行、`_scanPorts()` 第 122 行、`_buildScanButton()` 第 322-357 行一致 |
| TC-SCAN-002 | High | ✅ 通过 | 多串口返回：自动选中第一个、可切换。与 `_scanPorts()` 第 130-136 行一致 |
| TC-SCAN-003 | High | ✅ 通过 | 空列表处理：`ScanState.noDevices` 分支覆盖完整。按钮 fallthrough 到雷达图标/“扫描串口”文案，与代码行为一致 |
| TC-SCAN-004 | High | ✅ 通过 | 网络异常：`catch (e)` 分支，`ScanState.failed`，按钮可重试。与第 138-141 行一致 |
| TC-SCAN-005 | Medium | ✅ 通过 | 扫描中按钮禁用：`isScanning ? null : _scanPorts`。与第 331 行一致 |
| TC-SCAN-006 | Medium | 🟡 需关注 | 编辑模式不自动扫描预期正确，但存在**实现隐患**（见第三部分 Issue #1） |

### 2.2 表单字段测试 (TC-FIELD-001 ~ TC-FIELD-014)

| 用例ID | 优先级 | 审查结果 | 问题描述 |
|--------|--------|----------|----------|
| TC-FIELD-001 | High | ✅ 通过 | 创建模式默认值与 `initState()` 第 79-81 行一致 |
| TC-FIELD-002 | High | ✅ 通过 | 编辑模式预填与 `initState()` 第 67-78 行一致 |
| TC-FIELD-003 | Medium | ✅ 通过 | 波特率 5 个选项与 `baudRateOptions` 常量一致 |
| TC-FIELD-004 | Medium | ✅ 通过 | 数据位 2 个选项与 `dataBitsOptions` 常量一致 |
| TC-FIELD-005 | Medium | ✅ 通过 | 停止位 2 个选项与 `stopBitsOptions` 常量一致 |
| TC-FIELD-006 | Medium | ✅ 通过 | 校验 3 个选项与 `parityOptions` 常量一致 |
| TC-FIELD-007 | Medium | ✅ 通过 | 从站ID键盘类型与 `_buildSlaveIdField()` 第 473 行一致 |
| TC-FIELD-008 | Medium | ✅ 通过 | 超时键盘类型和后缀与 `_buildTimeoutField()` 第 487-488 行一致 |
| TC-FIELD-009 | Medium | ✅ 通过 | `onFieldChanged` 回调在各字段 `onChanged` 中均有调用 |
| TC-FIELD-010 | Medium | ✅ 通过 | 连接测试按钮初始状态与 `ConnectionTestWidget` idle 状态一致 |
| TC-FIELD-011 | Medium | ✅ 通过 | 测试中状态与 `ConnectionTestState.testing` 一致 |
| TC-FIELD-012 | Medium | ✅ 通过 | 成功状态：图标、颜色（`AppColorSchemes.success`）、延迟显示、5s 自动恢复均与代码一致 |
| TC-FIELD-013 | Medium | ✅ 通过 | 失败状态：图标、颜色、错误消息与 `_buildButton()` failed 分支一致 |
| TC-FIELD-014 | Medium | ✅ 通过 | 网络异常捕获与 `_testConnection()` 第 177-182 行一致 |

### 2.3 参数验证测试 (TC-VALID-001 ~ TC-VALID-014)

| 用例ID | 优先级 | 审查结果 | 问题描述 |
|--------|--------|----------|----------|
| TC-VALID-001 | Critical | ✅ 通过 | 串口未选择时 `validate()` 返回 false，与第 99 行一致 |
| TC-VALID-002 | High | ✅ 通过 | 从站ID为空：`DeviceValidators.slaveId` 返回 "请输入从站ID"，`validate()` 返回 false。与第 48 行、第 101 行一致 |
| TC-VALID-003 | High | ✅ 通过 | 从站ID非数字：预期与 `int.tryParse` 返回 null 分支一致 |
| TC-VALID-004 | High | ✅ 通过 | 从站ID超出范围：预期与第 51 行一致 |
| TC-VALID-005 | Medium | ✅ 通过 | 边界值 1, 247 通过验证。与 `slaveId()` 默认范围一致 |
| TC-VALID-006 | High | ❌ **预期错误** | 见第三部分 Issue #2（核心问题） |
| TC-VALID-007 | Medium | ❌ **预期错误** | 同上 — `validate()` 不检查超时字段 |
| TC-VALID-008 | High | ❌ **预期错误** | 同上 — `validate()` 不检查超时字段 |
| TC-VALID-009 | Medium | ❌ **预期错误** | 同上 — `validate()` 不检查超时字段 |
| TC-VALID-010 | Critical | ✅ 通过 | 7N1 组合：`validate()` 返回 false，与第 103 行一致 |
| TC-VALID-011 | High | ✅ 通过 | 7 种合法组合与 `validate()` 逻辑一致 |
| TC-VALID-012 | Medium | ✅ 通过 | `getConfig()` slaveId fallback 与第 115 行一致 |
| TC-VALID-013 | Medium | ✅ 通过 | `getConfig()` timeout fallback 与第 116 行一致 |
| TC-VALID-014 | Medium | ✅ 通过 | `getConfig()` port fallback `''` 与第 110 行一致 |

---

## 三、发现的问题（需修改）

### Issue #1 🟡 编辑模式串口下拉框可能崩溃

**严重程度**: 中  
**涉及用例**: TC-SCAN-006  
**相关代码**: `modbus_rtu_form.dart` 第 264-318 行 (`_buildSerialPortRow`)

**问题描述**:
编辑模式（`isEditMode = true`）下，`initState()` 不会触发 `_scanPorts()`，因此 `_availablePorts` 保持为空列表。但 `DropdownButtonFormField` 的 `initialValue` 被设为 `_selectedPort`（来自 `initialConfig.port`，例如 `/dev/ttyUSB0`），而 `items` 列表（由 `_availablePorts.map(...)` 构建）为空。

在 Flutter 中，当 `DropdownButtonFormField` 的 `value` 不在 `items` 中时，会触发断言失败：
```
'package:flutter/src/material/dropdown.dart': Failed assertion: line 582 pos 15:
'items == null || items.isEmpty || value == null || items.where(
    (DropdownMenuItem<T> item) => item.value == value).length == 1': is not true.
```

**修复建议**:
1. **代码层面**: 在 `initState()` 中，当 `initialConfig.port` 不为空时，向 `_availablePorts` 添加一个synthetic entry 以匹配下拉框的需求；或者在编辑模式也触发扫描。
2. **测试层面**: 新增一个测试用例 TC-SCAN-007，覆盖“编辑模式串口下拉框正常显示已配置端口”。

---

### Issue #2 ❌ `validate()` 方法不验证超时字段 — 4 个用例预期错误

**严重程度**: 高（Critical）  
**涉及用例**: TC-VALID-006, TC-VALID-007, TC-VALID-008, TC-VALID-009  
**相关代码**: `modbus_rtu_form.dart` 第 96-105 行

**问题描述**:
`ModbusRtuFormState.validate()` 的实现如下：
```dart
bool validate() {
    if (_selectedPort == null || _selectedPort!.isEmpty) return false;
    if (DeviceValidators.slaveId(_slaveIdController.text) != null) return false;
    if (_dataBits == 7 && _parity == 'None') return false;
    return true;
}
```

该方法**只检查三项**: 串口选择、从站ID合法性、7N1组合。**完全不检查超时字段**。

但以下 4 个测试用例均预期 `validate()` 返回 `false` 当超时无效时：

| 用例ID | 预期 `validate()` 返回值 | 实际 `validate()` 返回值 | 差异 |
|--------|-------------------------|------------------------|------|
| TC-VALID-006 (超时空) | `false` | `true` | 不符 |
| TC-VALID-007 (超时非数字) | `false` | `true` | 不符 |
| TC-VALID-008 (超时超出范围) | `false` | `true` | 不符 |
| TC-VALID-009 (超时边界) | `true` | `true` | 一致（但理由错误） |

**说明**: 虽然表单字段层面通过 `validator: DeviceValidators.timeout` 可以捕获超时错误（Flutter Form 自动验证），但 `validate()` 作为公开 API 方法被外部（父组件）调用时，超时验证被遗漏。

**修复建议**:
1. **方案 A (代码修复)**: 在 `validate()` 中添加超时检查：
   ```dart
   if (DeviceValidators.timeout(_timeoutController.text) != null) return false;
   ```
   然后测试用例保持现有预期不变。
   
2. **方案 B (测试修正)**: 修改 TC-VALID-006 ~ TC-VALID-009 的预期结果，明确区分“`validate()` 返回值”与“表单字段 validator 行为”，说明当前 `validate()` 不检查超时。

**推荐方案 A**（代码修复 + 测试用例保持不变），因为方法名 `validate()` 暗示完整表单验证。

---

### Issue #3 🟡 `DeviceValidators.serialParams()` 定义了但未被 `validate()` 使用

**严重程度**: 低  
**涉及用例**: TC-VALID-010 提及了 `DeviceValidators.serialParams()`  
**相关代码**: `device_validators.dart` 第 104-109 行, `modbus_rtu_form.dart` 第 103 行

**问题描述**:
`DeviceValidators.serialParams()` 提供了带有详细错误消息的 7N1 组合验证（"数据位7时校验位不能为None（请选择Even或Odd）"），但 `validate()` 方法直接内联了条件检查 `if (_dataBits == 7 && _parity == 'None') return false;`，未调用该静态方法。

这导致：
1. 错误消息不一致：表单文本框的 validator 可能调用 `serialParams()` 显示详细错误，但 `validate()` 仅返回 `false` 无消息。
2. 代码重复：验证逻辑在两处重复。

**修复建议**:
`validate()` 中调用 `DeviceValidators.serialParams(_dataBits, _parity)` 替代硬编码条件：
```dart
if (DeviceValidators.serialParams(_dataBits, _parity) != null) return false;
```

**测试影响**: TC-VALID-010 预期保持不变（仍返回 false）。

---

### Issue #4 🟡 缺少关键场景测试覆盖

**严重程度**: 中  
**涉及用例**: 缺失

以下场景在实现中存在但无对应测试用例：

| 缺失场景 | 相关代码 | 建议用例ID | 优先级 |
|----------|----------|-----------|--------|
| 超时字段通过 `validator`（非 `validate()`）验证 | `_buildTimeoutField()` validator | TC-VALID-015 | High |
| 表单 dispose 后异步回调的 mounted 检查 | `_scanPorts()` 第 128, 139 行; `_testConnection()` 第 159, 172, 178 行 | TC-LIFE-001 | Medium |
| 连接测试时无端口选择的行为 | `_testConnection()` → `getConfig().toJson()` 含空 port | TC-FIELD-015 | Medium |
| 编辑模式下串口下拉框正常渲染 | `_buildSerialPortRow()` + 空 `_availablePorts` | TC-SCAN-007 | High |
| `_scanPorts()` 在 `_selectedPort != null` 时不覆盖 | `_scanPorts()` 第 134 行条件 | TC-SCAN-008 | Low |
| `RtuConfig.toJson()` 键名与后端 API 一致 | `protocol_config.dart` 第 208-216 行 | TC-MODEL-001 | Medium |
| `deviceId` 为 null 时测试连接 API 路径为 `/api/v1/devices/new/test-connection` | `_testConnection()` 第 155 行 | TC-FIELD-016 | Low |

---

### Issue #5 🟢 轻微问题

| 问题 | 涉及用例 | 说明 |
|------|---------|------|
| 测试用例格式为自然语言描述，非自动化测试代码 | 全部 | 如需自动化执行，需额外转换为 Flutter widget test 或 integration test |
| TC-FIELD-012 期望 "`AppColorSchemes.success`" 颜色 | TC-FIELD-012 | 颜色名称正确，但 `ConnectionTestWidget._buildButton()` 使用 `const successFg = AppColorSchemes.success` 作为前景色，`_buildResultMessage()` 还使用了 `AppColorSchemes.success.withValues(alpha: 0.12)` 作为背景色，测试描述不够精确 |
| TC-SCAN-003 按钮 fallthrough 行为 | TC-SCAN-003 | `_buildScanButton()` 对 `noDevices` 状态无显式分支，fallthrough 到默认雷达图标。虽然预期与当前行为一致，但这是代码质量问题，建议在测试文档中注明 |

---

## 四、统计汇总

| 分类 | 用例数 | 通过 | 预期错误 | 需关注 |
|------|--------|------|---------|--------|
| 串口扫描 | 6 | 5 | 0 | 1 |
| 表单字段 | 14 | 14 | 0 | 0 |
| 参数验证 | 14 | 10 | 4 | 0 |
| **总计** | **34** | **29** | **4** | **1** |

- 通过率: 29/34 (85.3%)
- 预期错误的用例: **TC-VALID-006, TC-VALID-007, TC-VALID-008, TC-VALID-009**（4 个，均为超时验证相关）
- 需关注的用例: **TC-SCAN-006**（1 个，编辑模式下拉框潜在崩溃）

---

## 五、审查结论

**结论: ⚠️ 需修改**

### 必须修改（阻塞测试执行）

1. **TC-VALID-006 ~ TC-VALID-009** (4 个用例): 预期 `validate()` 返回 `false` 当超时无效，但 `validate()` 方法不检查超时。需决定：
   - **推荐**: 修复代码（`validate()` 添加超时检查），测试用例保持不变。
   - **备选**: 修改测试用例预期，区分 `validate()` 与 `FormField.validator` 的行为差异。

### 建议修改（提升质量）

2. **TC-SCAN-006**: 编辑模式下 `_availablePorts` 为空 + `_selectedPort` 非空可能导致 Flutter `DropdownButtonFormField` 断言崩溃。建议：
   - 修复代码（编辑模式也填充 `_availablePorts` 或触发扫描）
   - 新增 TC-SCAN-007 覆盖此场景

3. **新增测试用例**: 补充 Issue #4 中列出的 6 个缺失场景（超时 validator 行为、mounted 检查、无端口连接测试等）

### 可选优化

4. `validate()` 调用 `DeviceValidators.serialParams()` 替代硬编码条件（代码去重）
5. 测试文档中补充对自动化测试的说明（当前为手工测试规格）

---

**审查人签名**: sw-tom  
**审查日期**: 2026-05-03
