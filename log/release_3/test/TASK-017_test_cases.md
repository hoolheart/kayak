# TASK-017 测试用例 — 设备配置表单 UI

> **任务**: 设备配置表单对话框（三种协议动态切换）
> **测试人员**: sw-mike
> **日期**: 2026-06-01
> **分支**: `fix/task-016-017-critical-issues`
> **实现文件**: `kayak-frontend/lib/widgets/device_config_dialog.dart`

---

## 1. 测试范围

### 1.1 覆盖功能

| # | 功能模块 | 说明 |
|---|---------|------|
| 1 | 协议表单切换 | Virtual / Modbus TCP / Modbus RTU 三种协议配置区动态切换 |
| 2 | 表单验证 | 必填检查、格式验证、范围验证、交叉字段验证 |
| 3 | 协议序列化 | ProtocolType 枚举 → snake_case 字符串 |
| 4 | 保存流程 | Loading → 验证 → API 调用 → Toast → 关闭 → 刷新 |
| 5 | 保存失败处理 | 网络错误/后端错误显示友好消息 |
| 6 | 编辑模式 | 预填现有设备数据，标题切换 |
| 7 | 响应式布局 | Desktop Dialog / Mobile BottomSheet |
| 8 | 高级信息 | ExpansionTile 展开/折叠 |

### 1.2 测试类型

- **Widget 测试**: 表单渲染、交互、验证、状态切换
- **单元测试**: 协议序列化辅助方法

---

## 2. 测试用例详情

### TC-017-01: 创建设备对话框 — 初始渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-01 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- 应用已加载，用户已登录
- 工作台 `wb-test` 存在

**测试步骤**:
1. 渲染 `DeviceConfigDialog`（创建模式，无 device 参数）
2. 等待 pumpAndSettle

**预期结果**:
- [ ] 标题显示 "Add Device"
- [ ] 设备名称输入框存在，值为空
- [ ] 协议类型下拉框存在，值为空
- [ ] 协议配置区域不显示（未选择协议时隐藏）
- [ ] 高级信息 ExpansionTile 存在，默认折叠
- [ ] "Cancel" 按钮存在
- [ ] "Save" 按钮存在
- [ ] 关闭按钮 (×) 存在

---

### TC-017-02: 协议切换 — Virtual 协议

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-02 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开创建设备对话框
2. 点击协议类型下拉框
3. 选择 "Virtual Device"
4. 等待动画完成 (pump 200ms)

**预期结果**:
- [ ] 协议配置区域显示
- [ ] "Virtual Mode" 下拉框存在
- [ ] "Data Type" 下拉框存在
- [ ] "Value Range" (Min/Max) 输入框存在
- [ ] "Update Interval" 输入框存在，默认值为 "1000"
- [ ] AnimatedSwitcher 执行 150ms 淡入动画

---

### TC-017-03: 协议切换 — Modbus TCP 协议

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-03 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开创建设备对话框
2. 点击协议类型下拉框
3. 选择 "Modbus TCP"
4. 等待动画完成

**预期结果**:
- [ ] "Host Address" 输入框存在
- [ ] "Port" 输入框存在，默认值为 "502"
- [ ] "Slave ID" 输入框存在，默认值为 "1"
- [ ] "Timeout" 输入框存在，默认值为 "5000"
- [ ] Virtual 协议字段不再显示

---

### TC-017-04: 协议切换 — Modbus RTU 协议

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-04 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开创建设备对话框
2. 点击协议类型下拉框
3. 选择 "Modbus RTU"
4. 等待动画完成

**预期结果**:
- [ ] "Serial Port" 输入框存在
- [ ] "Baud Rate" 下拉框存在
- [ ] "Data Bits" 下拉框存在
- [ ] "Stop Bits" 下拉框存在
- [ ] "Parity" 下拉框存在
- [ ] "Slave ID" 输入框存在，默认值为 "1"
- [ ] "Timeout" 输入框存在，默认值为 "5000"

---

### TC-017-05: 协议切换时清空专用字段

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-05 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-02 通过

**测试步骤**:
1. 打开对话框，选择 Virtual 协议
2. 在 Min Value 输入 "10"
3. 切换协议为 Modbus TCP
4. 再切换回 Virtual

**预期结果**:
- [ ] 切换为 TCP 后，Virtual 字段消失
- [ ] 切换回 Virtual 后，Min Value 为空（已被清空）
- [ ] 更新间隔恢复默认值 "1000"

---

### TC-017-06: 表单验证 — 设备名称必填

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-06 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开创建设备对话框
2. 选择 Virtual 协议
3. 选择 Virtual Mode 和 Data Type
4. 保持设备名称为空
5. 点击 Save 按钮

**预期结果**:
- [ ] 显示验证错误 "Device name is required"
- [ ] 对话框不关闭
- [ ] API 未被调用

---

### TC-017-07: 表单验证 — 协议类型必填

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-07 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开创建设备对话框
2. 输入设备名称 "Test Device"
3. 不选择协议类型
4. 点击 Save 按钮

**预期结果**:
- [ ] 显示验证错误 "Protocol type is required"
- [ ] 对话框不关闭

---

### TC-017-08: 表单验证 — Virtual 模式必填

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-08 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-02 通过

**测试步骤**:
1. 打开对话框，输入名称
2. 选择 Virtual 协议
3. 不选择 Virtual Mode
4. 选择 Data Type
5. 点击 Save

**预期结果**:
- [ ] 显示验证错误 "Virtual mode is required"

---

### TC-017-09: 表单验证 — TCP 主机地址必填和格式

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-09 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-03 通过

**测试步骤**:
1. 打开对话框，输入名称，选择 Modbus TCP
2. 保持主机地址为空，点击 Save
3. 输入 "invalid" 到主机地址，点击 Save
4. 输入 "192.168.1.1" 到主机地址，点击 Save

**预期结果**:
- [ ] 步骤 2: 显示 "Host address is required"
- [ ] 步骤 3: 显示 "Please enter a valid IPv4 address"
- [ ] 步骤 4: 主机地址验证通过（其他字段仍可能验证失败）

---

### TC-017-10: 表单验证 — TCP 端口范围

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-10 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-03 通过

**测试步骤**:
1. 打开对话框，输入名称，选择 Modbus TCP
2. 输入主机地址
3. 输入端口 "0"，点击 Save
4. 输入端口 "70000"，点击 Save
5. 输入端口 "502"，点击 Save

**预期结果**:
- [ ] 步骤 3: 显示 "Port must be an integer between 1-65535"
- [ ] 步骤 4: 显示相同错误
- [ ] 步骤 5: 端口验证通过

---

### TC-017-11: 表单验证 — 取值范围交叉验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-11 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-02 通过

**测试步骤**:
1. 打开对话框，选择 Virtual 协议
2. 填写所有必填项
3. Min Value 输入 "100"
4. Max Value 输入 "50"
5. 点击 Save

**预期结果**:
- [ ] 显示 "Maximum must be greater than minimum"

---

### TC-017-12: 表单验证 — 间隔/超时最小值

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-12 |
| **优先级** | P1 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-02 通过

**测试步骤**:
1. 选择 Virtual 协议
2. Update Interval 输入 "50"
3. 点击 Save

**预期结果**:
- [ ] 显示 "Interval cannot be less than 100ms"

---

### TC-017-13: 协议序列化 — snake_case 转换

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-13 |
| **优先级** | P0 |
| **类型** | Unit Test |

**前置条件**:
- 无

**测试步骤**:
1. 调用 `_protocolTypeToSnakeCase(ProtocolType.virtual)`
2. 调用 `_protocolTypeToSnakeCase(ProtocolType.modbusTcp)`
3. 调用 `_protocolTypeToSnakeCase(ProtocolType.modbusRtu)`

**预期结果**:
- [ ] 返回 "virtual"
- [ ] 返回 "modbus_tcp"
- [ ] 返回 "modbus_rtu"

---

### TC-017-14: 保存流程 — 成功路径

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-14 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- FakeDeviceService 配置为成功响应

**测试步骤**:
1. 打开创建设备对话框
2. 输入名称 "New Device"
3. 选择 Virtual 协议
4. 选择 Virtual Mode = "random"
5. 选择 Data Type = "float32"
6. 点击 Save
7. 等待异步操作完成

**预期结果**:
- [ ] 点击 Save 后按钮显示 CircularProgressIndicator（loading 状态）
- [ ] FakeDeviceService.create 被调用
- [ ] 调用参数中 protocolType 为 "virtual"
- [ ] 对话框关闭（Navigator.pop）
- [ ] Toast 显示 "Device saved successfully"

---

### TC-017-15: 保存流程 — 失败路径（网络错误）

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-15 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- FakeDeviceService 配置为抛出异常

**测试步骤**:
1. 打开对话框，填写所有必填项
2. 点击 Save
3. 等待异步操作完成

**预期结果**:
- [ ] loading 状态结束后按钮恢复可点击
- [ ] 对话框不关闭
- [ ] Toast 显示错误消息（异常文本）
- [ ] 表单数据保留

---

### TC-017-16: 编辑模式 — 预填数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-16 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- 存在已有设备数据

**测试步骤**:
1. 打开编辑对话框，传入现有 DeviceTreeNode
2. 等待渲染

**预期结果**:
- [ ] 标题显示 "Edit Device"
- [ ] 设备名称输入框预填现有名称
- [ ] 协议类型下拉框预填现有协议（不可更改或显示正确值）
- [ ] 协议配置区预填现有参数
- [ ] 高级信息字段预填现有值（如有）

---

### TC-017-17: 编辑模式 — 更新设备

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-17 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-16 通过
- FakeDeviceService 配置为成功响应

**测试步骤**:
1. 打开编辑对话框
2. 修改设备名称
3. 点击 Save
4. 等待异步操作完成

**预期结果**:
- [ ] FakeDeviceService.update 被调用
- [ ] 调用参数包含更新后的名称
- [ ] 对话框关闭
- [ ] Toast 显示成功消息

---

### TC-017-18: 响应式布局 — Desktop Dialog

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-18 |
| **优先级** | P1 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 在宽度 >= 600px 的视口中渲染对话框

**预期结果**:
- [ ] 使用 `AlertDialog` 容器
- [ ] 宽度为 560px
- [ ] 按钮布局为 Row（Cancel | Save）

---

### TC-017-19: 响应式布局 — Mobile BottomSheet

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-19 |
| **优先级** | P1 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 直接渲染 `DeviceConfigDialog(isMobile: true)`

**预期结果**:
- [ ] 使用 `ConstrainedBox` 容器
- [ ] maxHeight 为 90vh
- [ ] 按钮布局为 Column（Save / Cancel），全宽

---

### TC-017-20: 高级信息 — ExpansionTile 展开/折叠

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-20 |
| **优先级** | P1 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开对话框
2. 点击 "Advanced Information" ExpansionTile
3. 等待展开动画
4. 再次点击折叠

**预期结果**:
- [ ] 展开后显示 Manufacturer、Model、Serial Number 输入框
- [ ] 折叠后字段隐藏
- [ ] 展开/折叠状态通过 setState 管理

---

### TC-017-21: 表单验证 — RTU 串口必填

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-21 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-04 通过

**测试步骤**:
1. 打开对话框，输入名称，选择 Modbus RTU
2. 保持串口为空
3. 选择波特率
4. 点击 Save

**预期结果**:
- [ ] 显示 "Serial port is required"

---

### TC-017-22: 表单验证 — RTU 波特率必填

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-22 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-04 通过

**测试步骤**:
1. 打开对话框，输入名称，选择 Modbus RTU
2. 输入串口 "/dev/ttyUSB0"
3. 不选择波特率
4. 点击 Save

**预期结果**:
- [ ] 显示 "Baud rate is required"

---

### TC-017-23: 取消按钮 — 关闭对话框

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-23 |
| **优先级** | P1 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开对话框
2. 输入一些数据
3. 点击 Cancel 按钮

**预期结果**:
- [ ] 对话框关闭（Navigator.pop）
- [ ] 无 API 调用

---

### TC-017-24: 关闭按钮 — 关闭对话框

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-24 |
| **优先级** | P1 |
| **类型** | Widget Test |

**前置条件**:
- TC-017-01 通过

**测试步骤**:
1. 打开对话框
2. 点击右上角 × 关闭按钮

**预期结果**:
- [ ] 对话框关闭

---

### TC-017-25: 保存时 Loading 状态 — 按钮禁用

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-25 |
| **优先级** | P0 |
| **类型** | Widget Test |

**前置条件**:
- FakeDeviceService 配置为有延迟

**测试步骤**:
1. 打开对话框，填写所有必填项
2. 点击 Save
3. 在异步操作完成前检查按钮状态

**预期结果**:
- [ ] Save 按钮显示 CircularProgressIndicator (20×20, strokeWidth: 2)
- [ ] Cancel 按钮被禁用
- [ ] Save 按钮被禁用（不可重复点击）

---

### TC-017-26: Virtual 设备完整创建数据构建

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-26 |
| **优先级** | P0 |
| **类型** | Widget Test (Integration) |

**前置条件**:
- FakeDeviceService 成功响应

**测试步骤**:
1. 打开创建对话框
2. 名称: "Virtual Test"
3. 协议: Virtual
4. Mode: random
5. Data Type: float32
6. Min: 0, Max: 100
7. Interval: 1000
8. 点击 Save

**预期结果**:
- [ ] createDevice 被调用
- [ ] name = "Virtual Test"
- [ ] protocolType = "virtual"
- [ ] protocolParams 包含 mode, data_type, min, max, interval_ms

---

### TC-017-27: TCP 设备完整创建数据构建

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-27 |
| **优先级** | P0 |
| **类型** | Widget Test (Integration) |

**前置条件**:
- FakeDeviceService 成功响应

**测试步骤**:
1. 打开创建对话框
2. 名称: "TCP Test"
3. 协议: Modbus TCP
4. Host: 192.168.1.100
5. Port: 502
6. Slave ID: 1
7. Timeout: 5000
8. 点击 Save

**预期结果**:
- [ ] createDevice 被调用
- [ ] protocolType = "modbus_tcp"
- [ ] protocolParams 包含 host, port, slave_id, timeout_ms

---

### TC-017-28: RTU 设备完整创建数据构建

| 属性 | 内容 |
|------|------|
| **ID** | TC-017-28 |
| **优先级** | P0 |
| **类型** | Widget Test (Integration) |

**前置条件**:
- FakeDeviceService 成功响应

**测试步骤**:
1. 打开创建对话框
2. 名称: "RTU Test"
3. 协议: Modbus RTU
4. Serial Port: /dev/ttyUSB0
5. Baud Rate: 9600
6. Data Bits: 8
7. Stop Bits: 1
8. Parity: none
9. Slave ID: 1
10. Timeout: 5000
11. 点击 Save

**预期结果**:
- [ ] createDevice 被调用
- [ ] protocolType = "modbus_rtu"
- [ ] protocolParams 包含 serial_port, baud_rate, data_bits, stop_bits, parity, slave_id, timeout_ms

---

## 3. 测试数据

### 3.1 有效设备数据

```dart
// Virtual Device
final virtualDevice = DeviceTreeNode(
  id: 'dev-virtual',
  workbenchId: 'wb-test',
  name: 'Virtual Sensor',
  protocolType: ProtocolType.virtual,
  protocolParams: {
    'mode': 'random',
    'data_type': 'float32',
    'min': 0.0,
    'max': 100.0,
    'interval_ms': 1000,
  },
  status: 'offline',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

// Modbus TCP Device
final tcpDevice = DeviceTreeNode(
  id: 'dev-tcp',
  workbenchId: 'wb-test',
  name: 'PLC Controller',
  protocolType: ProtocolType.modbusTcp,
  protocolParams: {
    'host': '192.168.1.100',
    'port': 502,
    'slave_id': 1,
    'timeout_ms': 5000,
  },
  status: 'offline',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

// Modbus RTU Device
final rtuDevice = DeviceTreeNode(
  id: 'dev-rtu',
  workbenchId: 'wb-test',
  name: 'Serial Device',
  protocolType: ProtocolType.modbusRtu,
  protocolParams: {
    'serial_port': '/dev/ttyUSB0',
    'baud_rate': 9600,
    'data_bits': 8,
    'stop_bits': 1,
    'parity': 'none',
    'slave_id': 1,
    'timeout_ms': 5000,
  },
  status: 'offline',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
```

### 3.2 无效输入数据

| 字段 | 无效值 | 预期错误 |
|------|--------|---------|
| 设备名称 | "" (空) | "Device name is required" |
| 设备名称 | 256+ 字符 | "Name cannot exceed 255 characters" |
| 协议类型 | null | "Protocol type is required" |
| 主机地址 | "" | "Host address is required" |
| 主机地址 | "invalid" | "Please enter a valid IPv4 address" |
| 端口 | "0" | "Port must be an integer between 1-65535" |
| 端口 | "70000" | "Port must be an integer between 1-65535" |
| 从站 ID | "0" | "Slave ID must be an integer between 1-247" |
| 从站 ID | "248" | "Slave ID must be an integer between 1-247" |
| 最小值 | "abc" | "Please enter a valid number" |
| 最大值 < 最小值 | min=100, max=50 | "Maximum must be greater than minimum" |
| 更新间隔 | "50" | "Interval cannot be less than 100ms" |
| 超时 | "50" | "Timeout cannot be less than 100ms" |
| 串口 | "" | "Serial port is required" |
| 波特率 | null | "Baud rate is required" |

---

## 4. 环境要求

### 4.1 测试环境

- Flutter SDK: 3.19+
- Dart: 3.3+
- 运行命令: `flutter test --exclude-tags golden test/widgets/device_config_dialog_test.dart`

### 4.2 Mock 依赖

- `FakeDeviceService` (已有，位于 `test/helpers/fake_device_service.dart`)
- 需要扩展 FakeDeviceService 以支持 `createFails` 和 `updateFails` 配置

### 4.3 已知限制

- `DropdownButtonFormField` 使用 `initialValue` 而非 `value`（ISS-5，非阻塞）
- RTU data_bits/stop_bits/parity 无 validator（ISS-6，非阻塞）
- Baud rate 无默认值（ISS-7，非阻塞）
- 高级字段在创建时可能被丢弃（ISS-10，非阻塞）

---

## 5. 测试通过标准

- [ ] 所有 P0 测试用例通过
- [ ] 无未预期的异常或崩溃
- [ ] Widget 测试覆盖率 > 80%（针对 device_config_dialog.dart）
- [ ] 所有发现的 bug 已记录到测试报告

---

*文档结束*
