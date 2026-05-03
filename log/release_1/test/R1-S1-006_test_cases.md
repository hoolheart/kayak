# R1-S1-006-A 测试用例文档 - 多协议设备配置UI

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S1-006-A |
| 测试类型 | Widget 测试 + 集成测试 |
| 测试范围 | 多协议设备配置UI - 协议选择器、Virtual表单、Modbus TCP表单、Modbus RTU表单、表单验证 |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-03 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [协议选择器测试](#2-协议选择器测试)
3. [Virtual 协议表单测试](#3-virtual-协议表单测试)
4. [Modbus TCP 协议表单测试](#4-modbus-tcp-协议表单测试)
5. [Modbus RTU 协议表单测试](#5-modbus-rtu-协议表单测试)
6. [表单验证测试](#6-表单验证测试)
7. [用户交互流程测试](#7-用户交互流程测试)
8. [测试数据需求](#8-测试数据需求)
9. [测试环境](#9-测试环境)
10. [风险与假设](#10-风险与假设)
11. [测试用例汇总](#11-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证多协议设备配置UI的正确性，确保：
- 协议选择器正确展示 Virtual / Modbus TCP / Modbus RTU 三个选项
- 选择协议后动态加载对应的参数表单，且上一个协议的表单字段完全不可见
- Virtual 协议表单字段完整（模式、数据类型、访问类型、最小值/最大值、固定值）
- Modbus TCP 协议表单字段完整（主机地址、端口、从站ID、超时、连接池大小）
- Modbus RTU 协议表单字段完整（串口选择、波特率、数据位、停止位、校验、从站ID、超时）
- IP地址格式验证、端口范围验证（1-65535）、从站ID验证（1-247）正确生效
- 编辑模式下协议类型不可修改
- 通用字段（设备名称、制造商、型号、序列号）在协议切换时保持不变

### 1.2 涉及的协议类型

| 协议 | 表单字段 | PRD 参考 |
|------|---------|---------|
| Virtual | 模式选择 (Random/Fixed/Sine/Ramp), 数据类型 (Number/Integer/String/Boolean), 访问类型 (RO/WO/RW), 最小值/最大值, 固定值(Fixed模式) | PRD 2.5.3 |
| Modbus TCP | 主机地址 (IP), 端口 (默认502), 从站ID (默认1), 超时时间 (ms), 连接池大小 | PRD 2.5.3 |
| Modbus RTU | 串口选择, 波特率 (9600/19200/38400/57600/115200), 数据位 (7/8), 停止位 (1/2), 校验 (None/Even/Odd), 从站ID, 超时时间 | PRD 2.5.3 |

### 1.3 验证规则

| 规则 | 描述 | PRD 参考 |
|------|------|---------|
| IP格式验证 | IPv4地址格式 (x.x.x.x) | PRD 2.5.5 |
| 端口范围 | 1 - 65535 | PRD 2.5.5 |
| 从站ID范围 | 1 - 247 | PRD 2.5.5 |
| 串口参数组合 | 波特率/数据位/停止位/校验位组合有效性 | PRD 2.5.5 |
| 设备名称 | 必填，不能为空 | PRD 2.5.2 |

### 1.4 测试范围

| 组件 | 测试内容 |
|------|---------|
| 协议选择器 | 下拉选择框渲染、选项列表、切换行为、编辑模式禁用 |
| Virtual 表单 | 模式选择、数据类型选择、访问类型选择、数值输入、固定值输入 |
| Modbus TCP 表单 | IP输入、端口输入、从站ID输入、超时输入、连接池输入 |
| Modbus RTU 表单 | 串口选择、波特率选择、数据位选择、停止位选择、校验选择、从站ID输入 |
| 表单验证 | IP格式、端口范围、从站ID范围、必填字段、数值比较 |
| 通用交互 | 对话框打开/关闭、取消/提交按钮、加载状态、错误提示 |

### 1.5 测试策略

- **Widget 测试**：使用 `flutter_test` 和 `WidgetTester`，将 `DeviceFormDialog` 嵌入 `MaterialApp` 中渲染
- **单元测试**：验证逻辑层（validator/state management/protocol config builder）
- **集成测试**：完整创建/编辑设备流程（需要 mock DeviceService）
- **边界测试**：协议切换边界、字段清空/重置、数值边界、字符串边界

---

## 2. 协议选择器测试

### TC-UI-001: 协议选择器默认显示 Virtual

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-001 |
| **测试名称** | 协议选择器默认显示 Virtual |
| **测试目的** | 验证创建设备时协议选择器默认值为 Virtual |
| **前置条件** | DeviceFormDialog 已实现，protocol-type-dropdown 组件已渲染 |
| **测试步骤** | 1. 打开 Create Device dialog（不传 device 参数）<br>2. 检查 protocol-type-dropdown 组件当前选中的文本<br>3. 验证当前选中的值为 'VIRTUAL' |
| **预期结果** | 1. 下拉框初始选中文本为 'VIRTUAL'<br>2. _protocolType == ProtocolType.virtual |
| **测试数据** | workbenchId: "wb-001"，device: null |
| **优先级** | P0 |

**Flutter 测试代码示例**：
```dart
testWidgets('protocol selector defaults to Virtual', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DeviceFormDialog(workbenchId: 'wb-001'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Verify Virtual is selected by default
  expect(find.text('VIRTUAL'), findsOneWidget);
});
```

---

### TC-UI-002: 协议选择器下拉列表包含所有协议选项

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-002 |
| **测试名称** | 协议选择器下拉列表包含所有协议选项 |
| **测试目的** | 验证下拉列表包含 Virtual / Modbus TCP / Modbus RTU 三个选项 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 点击 protocol-type-dropdown 打开下拉菜单<br>3. 验证下拉列表包含 'VIRTUAL'<br>4. 验证下拉列表包含 'MODBUSTCP' 或 'MODBUS_TCP'<br>5. 验证下拉列表包含 'MODBUSRTU' 或 'MODBUS_RTU' |
| **预期结果** | 1. 下拉列表包含 VIRTUAL 选项<br>2. 下拉列表包含 MODBUS_TCP 选项<br>3. 下拉列表包含 MODBUS_RTU 选项<br>4. 三个选项均处于 enabled 状态（创建模式） |
| **测试数据** | workbenchId: "wb-001"，device: null |
| **优先级** | P0 |

---

### TC-UI-003: 选择 Virtual 协议并验证表单显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-003 |
| **测试名称** | 选择 Virtual 协议并验证表单显示 |
| **测试目的** | 验证选择 Virtual 协议后，Virtual 专用参数字段正确显示 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 Virtual<br>3. 验证 Virtual 参数区域显示<br>4. 验证采样间隔输入框显示<br>5. 验证最小值/最大值输入框显示 |
| **预期结果** | 1. virtual-params-section 组件可见<br>2. virtual-sample-interval 输入框可见<br>3. 最小值/最大值输入框可见<br>4. Virtual 参数标签文本为 'Virtual协议参数' |
| **测试数据** | workbenchId: "wb-001"，protocolType: virtual |
| **优先级** | P0 |

---

### TC-UI-004: 选择 Modbus TCP 协议并验证表单显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-004 |
| **测试名称** | 选择 Modbus TCP 协议并验证表单显示 |
| **测试目的** | 验证选择 Modbus TCP 协议后，TCP 专用参数字段正确显示 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 验证主机地址输入框显示<br>4. 验证端口输入框显示（默认值 502）<br>5. 验证从站ID输入框显示（默认值 1）<br>6. 验证超时时间输入框显示<br>7. 验证连接池大小输入框显示 |
| **预期结果** | 1. 主机地址输入框（IP输入）可见<br>2. 端口输入框可见，默认值 502<br>3. 从站ID输入框可见，默认值 1<br>4. 超时时间输入框可见<br>5. 连接池大小输入框可见 |
| **测试数据** | workbenchId: "wb-001"，protocolType: modbus_tcp |
| **优先级** | P0 |

---

### TC-UI-005: 选择 Modbus RTU 协议并验证表单显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-005 |
| **测试名称** | 选择 Modbus RTU 协议并验证表单显示 |
| **测试目的** | 验证选择 Modbus RTU 协议后，RTU 专用参数字段正确显示 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 验证串口选择下拉框显示<br>4. 验证波特率选择器显示（默认值 9600）<br>5. 验证数据位选择器显示（默认值 8）<br>6. 验证停止位选择器显示（默认值 1）<br>7. 验证校验选择器显示（默认值 None）<br>8. 验证从站ID输入框显示<br>9. 验证超时时间输入框显示 |
| **预期结果** | 1. 串口选择下拉框可见<br>2. 波特率选择器可见，默认值 9600<br>3. 数据位选择器可见，默认值 8<br>4. 停止位选择器可见，默认值 1<br>5. 校验选择器可见，默认值 None<br>6. 从站ID输入框可见<br>7. 超时时间输入框可见 |
| **测试数据** | workbenchId: "wb-001"，protocolType: modbus_rtu |
| **优先级** | P0 |

---

### TC-UI-006: 协议切换 Virtual → Modbus TCP 表单动态更新

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-006 |
| **测试名称** | 协议切换 Virtual → Modbus TCP 表单动态更新 |
| **测试目的** | 验证从 Virtual 切换到 Modbus TCP 后，Virtual 表单字段消失，TCP 表单字段出现 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认 Virtual 表单可见（采样间隔、最小值、最大值）<br>3. 切换协议类型为 modbus_tcp<br>4. 调用 pumpAndSettle 等待动画<br>5. 验证 Virtual 参数字段不再可见<br>6. 验证 TCP 参数字段可见 |
| **预期结果** | 1. virtual-sample-interval 不再可见<br>2. 最小值/最大值输入框不再可见<br>3. 主机地址输入框可见<br>4. 端口输入框可见<br>5. 从站ID输入框可见 |
| **测试数据** | 初始: virtual → 目标: modbus_tcp |
| **优先级** | P0 |

---

### TC-UI-007: 协议切换 Modbus TCP → Modbus RTU 表单动态更新

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-007 |
| **测试名称** | 协议切换 Modbus TCP → Modbus RTU 表单动态更新 |
| **测试目的** | 验证从 Modbus TCP 切换到 Modbus RTU 后，TCP 表单字段消失，RTU 表单字段出现 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 切换协议类型为 modbus_tcp<br>3. 确认 TCP 表单可见<br>4. 切换协议类型为 modbus_rtu<br>5. 验证 TCP 参数字段不再可见<br>6. 验证 RTU 参数字段可见 |
| **预期结果** | 1. 主机地址/端口/连接池输入框不再可见<br>2. 串口选择下拉框可见<br>3. 波特率选择器可见<br>4. 数据位/停止位/校验选择器可见 |
| **测试数据** | 初始: modbus_tcp → 目标: modbus_rtu |
| **优先级** | P0 |

---

### TC-UI-008: 协议切换 Modbus RTU → Virtual 表单动态更新

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-008 |
| **测试名称** | 协议切换 Modbus RTU → Virtual 表单动态更新 |
| **测试目的** | 验证从 Modbus RTU 切换回 Virtual 后，RTU 表单字段消失，Virtual 表单字段出现 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 切换协议类型为 modbus_rtu<br>3. 确认 RTU 表单可见<br>4. 切换协议类型为 virtual<br>5. 验证 RTU 参数字段不再可见<br>6. 验证 Virtual 参数字段可见 |
| **预期结果** | 1. 串口选择/波特率/校验选择器不再可见<br>2. virtual-sample-interval 输入框可见<br>3. 最小值/最大值输入框可见 |
| **测试数据** | 初始: modbus_rtu → 目标: virtual |
| **优先级** | P0 |

---

### TC-UI-009: 协议切换后上一个协议的表单字段完全不可见

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-009 |
| **测试名称** | 协议切换后上一个协议的表单字段完全不可见 |
| **测试目的** | 验证协议切换后不会出现任何前一个协议的残留字段（确保使用 conditional rendering 而非 visibility toggle） |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择 modbus_tcp 并填写主机地址为 "192.168.1.1"<br>3. 切换到 modbus_rtu<br>4. 在 widget tree 中查找 modbus_tcp 专用字段的 key<br>5. 验证这些字段不再存在于 widget tree 中 |
| **预期结果** | 1. tcp-host-field 不存在于 widget tree<br>2. tcp-port-field 不存在于 widget tree<br>3. tcp-pool-size-field 不存在于 widget tree<br>4. rtu 相关字段存在于 widget tree |
| **测试数据** | 协议序列: virtual → modbus_tcp → modbus_rtu |
| **优先级** | P0 |

---

### TC-UI-010: 编辑模式下协议选择器不可修改

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-010 |
| **测试名称** | 编辑模式下协议选择器不可修改 |
| **测试目的** | 验证编辑已有设备时，协议类型下拉框处于禁用/只读状态 |
| **前置条件** | 已存在一个 Modbus TCP 设备 |
| **测试步骤** | 1. 传入 device 参数（modbusTcp 类型）打开 Edit Device dialog<br>2. 尝试点击 protocol-type-dropdown<br>3. 验证下拉框是否响应点击<br>4. 检查 onChanged 为 null（禁用状态） |
| **预期结果** | 1. 协议类型下拉框显示 'MODBUSTCP'<br>2. 下拉框处于 disable 状态，无法点击展开<br>或 onChanged 回调为 null |
| **测试数据** | device: Device(protocolType: ProtocolType.modbusTcp, ...) |
| **优先级** | P0 |

---

### TC-UI-011: 协议切换保留通用字段值

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-011 |
| **测试名称** | 协议切换保留通用字段值 |
| **测试目的** | 验证切换协议类型时，设备名称等通用字段的值不被清空 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 输入设备名称 "Test Device"<br>3. 输入制造商 "Test Mfr"<br>4. 切换协议从 virtual → modbus_tcp<br>5. 验证设备名称输入框仍显示 "Test Device"<br>6. 验证制造商输入框仍显示 "Test Mfr" |
| **预期结果** | 1. device-name-field 文本为 "Test Device"<br>2. 制造商输入框文本为 "Test Mfr"<br>3. 字段值未被协议切换影响 |
| **测试数据** | 设备名称: "Test Device"，制造商: "Test Mfr" |
| **优先级** | P1 |

---

### TC-UI-012: 协议切换重置协议特定字段值

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-UI-012 |
| **测试名称** | 协议切换重置协议特定字段值 |
| **测试目的** | 验证切换协议后，新协议的参数字段使用默认值，不继承上一个协议的数值 |
| **前置条件** | DeviceFormDialog 已实现，处于创建模式 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择 Virtual，修改采样间隔为 2000<br>3. 切换到 Modbus TCP<br>4. 验证端口输入框为默认值 502（非2000）<br>5. 验证从站ID输入框为默认值 1 |
| **预期结果** | 1. TCP 端口为默认值 502<br>2. TCP 从站ID为默认值 1<br>3. TCP 字段使用自身默认值，与 Virtual 字段值无关 |
| **测试数据** | Virtual 采样间隔: 2000 → TCP 默认端口: 502 |
| **优先级** | P1 |

---

## 3. Virtual 协议表单测试

### TC-VF-001: Virtual 协议模式选择器配置

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-001 |
| **测试名称** | Virtual 协议模式选择器配置 |
| **测试目的** | 验证 Virtual 协议下模式选择下拉框包含 Random/Fixed/Sine/Ramp 选项 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议类型为 Virtual<br>3. 打开模式选择下拉框<br>4. 验证下拉列表包含 'Random'<br>5. 验证下拉列表包含 'Fixed'<br>6. 验证下拉列表包含 'Sine'<br>7. 验证下拉列表包含 'Ramp' |
| **预期结果** | 1. 模式选择器显示 4 个选项<br>2. 选项为: Random, Fixed, Sine, Ramp<br>3. 默认选中 Random |
| **测试数据** | 模式列表: [Random, Fixed, Sine, Ramp] |
| **优先级** | P0 |

---

### TC-VF-002: Virtual 协议选择 Random 模式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-002 |
| **测试名称** | Virtual 协议选择 Random 模式 |
| **测试目的** | 验证选择 Random 模式后表单正确响应 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 Virtual<br>3. 选择模式为 Random<br>4. 验证最小值/最大值输入框仍可见<br>5. 验证固定值输入框不可见 |
| **预期结果** | 1. Random 被选中<br>2. 最小值/最大值字段保留<br>3. 固定值字段不显示 |
| **测试数据** | 模式: Random |
| **优先级** | P0 |

---

### TC-VF-003: Virtual 协议选择 Fixed 模式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-003 |
| **测试名称** | Virtual 协议选择 Fixed 模式 |
| **测试目的** | 验证选择 Fixed 模式后显示固定值输入框 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 Virtual<br>3. 选择模式为 Fixed<br>4. 验证固定值输入框出现 |
| **预期结果** | 1. Fixed 被选中<br>2. 固定值输入框（label: '固定值'）可见 |
| **测试数据** | 模式: Fixed |
| **优先级** | P0 |

---

### TC-VF-004: Virtual 协议选择 Sine 模式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-004 |
| **测试名称** | Virtual 协议选择 Sine 模式 |
| **测试目的** | 验证选择 Sine 模式后表单正确响应 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 Virtual<br>3. 选择模式为 Sine<br>4. 验证最小值/最大值输入框仍可见 |
| **预期结果** | 1. Sine 被选中<br>2. 最小值/最大值字段保留<br>3. 固定值字段不显示 |
| **测试数据** | 模式: Sine |
| **优先级** | P1 |

---

### TC-VF-005: Virtual 协议选择 Ramp 模式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-005 |
| **测试名称** | Virtual 协议选择 Ramp 模式 |
| **测试目的** | 验证选择 Ramp 模式后表单正确响应 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 Virtual<br>3. 选择模式为 Ramp<br>4. 验证最小值/最大值输入框仍可见 |
| **预期结果** | 1. Ramp 被选中<br>2. 最小值/最大值字段保留 |
| **测试数据** | 模式: Ramp |
| **优先级** | P1 |

---

### TC-VF-006: Virtual 协议数据类型选择器

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-006 |
| **测试名称** | Virtual 协议数据类型选择器 |
| **测试目的** | 验证数据类型下拉框包含 Number/Integer/String/Boolean |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议类型为 Virtual<br>3. 打开数据类型下拉框<br>4. 验证选项: Number, Integer, String, Boolean |
| **预期结果** | 1. 下拉列表包含 4 个选项<br>2. 选项: Number, Integer, String, Boolean<br>3. 默认选中 Number |
| **测试数据** | 数据类型列表: [Number, Integer, String, Boolean] |
| **优先级** | P0 |

---

### TC-VF-007: Virtual 协议选择 Number 数据类型

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-007 |
| **测试名称** | Virtual 协议选择 Number 数据类型 |
| **测试目的** | 验证选择 Number 数据类型后最小/最大值输入为数字键盘 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择数据类型为 Number<br>3. 验证最小值输入框 keyboardType 为数字类型<br>4. 验证最大值输入框 keyboardType 为数字类型 |
| **预期结果** | 1. Number 被选中<br>2. 数值输入字段使用数字键盘 |
| **测试数据** | 数据类型: Number |
| **优先级** | P1 |

---

### TC-VF-008: Virtual 协议访问类型选择器

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-008 |
| **测试名称** | Virtual 协议访问类型选择器 |
| **测试目的** | 验证访问类型下拉框包含 RO/WO/RW 选项 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议类型为 Virtual<br>3. 打开访问类型下拉框<br>4. 验证选项: RO, WO, RW |
| **预期结果** | 1. 下拉列表包含 3 个选项<br>2. 选项: RO (只读), WO (只写), RW (读写)<br>3. 默认选中 RO |
| **测试数据** | 访问类型列表: [RO, WO, RW] |
| **优先级** | P0 |

---

### TC-VF-009: Virtual 协议最小值输入

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-009 |
| **测试名称** | Virtual 协议最小值输入 |
| **测试目的** | 验证最小值输入框接受有效数值 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议类型为 Virtual<br>3. 在最小值输入框输入 "50"<br>4. 验证输入框显示 "50" |
| **预期结果** | 1. 最小值输入框文本为 "50"<br>2. 数值被正确接受 |
| **测试数据** | 最小值: 50 |
| **优先级** | P0 |

---

### TC-VF-010: Virtual 协议最大值输入

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-010 |
| **测试名称** | Virtual 协议最大值输入 |
| **测试目的** | 验证最大值输入框接受有效数值 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议类型为 Virtual<br>3. 在最大值输入框输入 "200"<br>4. 验证输入框显示 "200" |
| **预期结果** | 1. 最大值输入框文本为 "200"<br>2. 数值被正确接受 |
| **测试数据** | 最大值: 200 |
| **优先级** | P0 |

---

### TC-VF-011: Virtual 协议 Fixed 模式固定值输入

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-011 |
| **测试名称** | Virtual 协议 Fixed 模式固定值输入 |
| **测试目的** | 验证 Fixed 模式下固定值输入框可正确输入 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual，模式选择 Fixed |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 Virtual<br>3. 选择模式为 Fixed<br>4. 验证固定值输入框出现<br>5. 在固定值输入框输入 "42.5"<br>6. 验证输入框显示 "42.5" |
| **预期结果** | 1. 固定值输入框（label: '固定值'）可见<br>2. 输入值 "42.5" 被正确接受 |
| **测试数据** | 模式: Fixed, 固定值: 42.5 |
| **优先级** | P0 |

---

### TC-VF-012: Virtual 协议默认值验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VF-012 |
| **测试名称** | Virtual 协议默认值验证 |
| **测试目的** | 验证 Virtual 协议表单的默认值符合 PRD 规范 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议类型为 Virtual<br>3. 验证采样间隔默认值为 "1000"<br>4. 验证最小值默认值为 "0"<br>5. 验证最大值默认值为 "100" |
| **预期结果** | 1. 采样间隔 = 1000 ms<br>2. 最小值 = 0<br>3. 最大值 = 100 |
| **测试数据** | 默认采样间隔: 1000, 默认最小值: 0, 默认最大值: 100 |
| **优先级** | P1 |

---

## 4. Modbus TCP 协议表单测试

### TC-TCP-001: Modbus TCP 协议表单字段完整显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-001 |
| **测试名称** | Modbus TCP 协议表单字段完整显示 |
| **测试目的** | 验证 Modbus TCP 协议下所有必填和可选字段正确显示 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 验证主机地址输入框可见<br>4. 验证端口输入框可见<br>5. 验证从站ID输入框可见<br>6. 验证超时时间输入框可见<br>7. 验证连接池大小输入框可见 |
| **预期结果** | 1. 主机地址 (label: '主机地址' 或 'Host') 可见<br>2. 端口 (label: '端口' 或 'Port') 可见<br>3. 从站ID (label: '从站ID' 或 'Slave ID') 可见<br>4. 超时时间 (label: '超时 (ms)') 可见<br>5. 连接池大小 (label: '连接池大小') 可见 |
| **测试数据** | 协议: modbus_tcp |
| **优先级** | P0 |

---

### TC-TCP-002: Modbus TCP 主机地址输入框

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-002 |
| **测试名称** | Modbus TCP 主机地址输入框 |
| **测试目的** | 验证主机地址输入框可接受 IP 地址文本输入 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 在主机地址输入框输入 "192.168.1.100"<br>4. 验证输入框显示 "192.168.1.100" |
| **预期结果** | 1. 主机地址输入框文本为 "192.168.1.100"<br>2. 输入被正确接受 |
| **测试数据** | 主机地址: "192.168.1.100" |
| **优先级** | P0 |

---

### TC-TCP-003: Modbus TCP 主机地址默认值

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-003 |
| **测试名称** | Modbus TCP 主机地址默认值 |
| **测试目的** | 验证主机地址输入框默认为空或合理占位符 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 验证主机地址输入框默认值<br>4. 验证占位文本（hint text）是否提示输入格式 |
| **预期结果** | 1. 主机地址输入框为空或显示 hint text "例: 192.168.1.100"<br>2. 不是自动填充的无效值 |
| **测试数据** | 新建设备 |
| **优先级** | P1 |

---

### TC-TCP-004: Modbus TCP 端口输入框默认值 502

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-004 |
| **测试名称** | Modbus TCP 端口输入框默认值 502 |
| **测试目的** | 验证端口输入框的默认值为 Modbus 标准端口 502 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 验证端口输入框默认显示 "502" |
| **预期结果** | 1. 端口输入框文本为 "502" |
| **测试数据** | 默认端口: 502 |
| **优先级** | P0 |

---

### TC-TCP-005: Modbus TCP 端口数字输入

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-005 |
| **测试名称** | Modbus TCP 端口数字输入 |
| **测试目的** | 验证端口输入框接受合法端口号输入 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 清除默认端口值<br>4. 输入 "8080"<br>5. 验证输入框显示 "8080" |
| **预期结果** | 1. 端口输入框文本为 "8080"<br>2. keyboardType 为数字键盘 |
| **测试数据** | 端口: 8080 |
| **优先级** | P0 |

---

### TC-TCP-006: Modbus TCP 从站ID输入框默认值 1

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-006 |
| **测试名称** | Modbus TCP 从站ID输入框默认值 1 |
| **测试目的** | 验证从站ID输入框的默认值为 1 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 验证从站ID输入框默认显示 "1" |
| **预期结果** | 1. 从站ID输入框文本为 "1" |
| **测试数据** | 默认从站ID: 1 |
| **优先级** | P0 |

---

### TC-TCP-007: Modbus TCP 从站ID数字输入

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-007 |
| **测试名称** | Modbus TCP 从站ID数字输入 |
| **测试目的** | 验证从站ID输入框接受合法从站ID |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 清除默认从站ID<br>4. 输入 "10"<br>5. 验证输入框显示 "10" |
| **预期结果** | 1. 从站ID输入框文本为 "10"<br>2. keyboardType 为数字键盘 |
| **测试数据** | 从站ID: 10 |
| **优先级** | P0 |

---

### TC-TCP-008: Modbus TCP 超时时间输入框

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-008 |
| **测试名称** | Modbus TCP 超时时间输入框 |
| **测试目的** | 验证超时时间输入框可接受毫秒值输入 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 在超时时间输入框输入 "5000"<br>4. 验证输入框显示 "5000" |
| **预期结果** | 1. 超时时间输入框文本为 "5000"<br>2. 默认值可能为 5000 ms 或空<br>3. keyboardType 为数字键盘 |
| **测试数据** | 超时时间: 5000 ms |
| **优先级** | P1 |

---

### TC-TCP-009: Modbus TCP 连接池大小输入框

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-009 |
| **测试名称** | Modbus TCP 连接池大小输入框 |
| **测试目的** | 验证连接池大小输入框可接受正整数输入 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 在连接池大小输入框输入 "4"<br>4. 验证输入框显示 "4" |
| **预期结果** | 1. 连接池大小输入框文本为 "4"<br>2. keyboardType 为数字键盘 |
| **测试数据** | 连接池大小: 4 |
| **优先级** | P1 |

---

### TC-TCP-010: Modbus TCP 通用设备字段仍可见

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-010 |
| **测试名称** | Modbus TCP 通用设备字段仍可见 |
| **测试目的** | 验证 Modbus TCP 协议下设备名称、制造商、型号、序列号等通用字段仍可见 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 验证设备名称输入框可见<br>4. 验证制造商输入框可见<br>5. 验证型号输入框可见<br>6. 验证序列号输入框可见 |
| **预期结果** | 1. device-name-field 可见<br>2. 制造商输入框可见<br>3. 型号输入框可见<br>4. 序列号输入框可见<br>5. 协议切换不影响通用字段 |
| **测试数据** | 协议: modbus_tcp |
| **优先级** | P1 |

---

### TC-TCP-011: 切换至 Modbus TCP 时 Virtual 字段不可见

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-TCP-011 |
| **测试名称** | 切换至 Modbus TCP 时 Virtual 字段不可见 |
| **测试目的** | 验证选择 Modbus TCP 后 Virtual 参数字段完全隐藏 |
| **前置条件** | DeviceFormDialog 已实现，当前为 Virtual 协议 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认 Virtual 参数可见<br>3. 切换协议为 modbus_tcp<br>4. 验证 virtual-sample-interval 不可见<br>5. 验证最小值输入框不可见<br>6. 验证最大值输入框不可见<br>7. 验证 virtual-params-section 文本不可见 |
| **预期结果** | 1. Virtual 参数区域完全消失<br>2. 对话框中仅有 TCP 参数和通用字段 |
| **测试数据** | 协议序列: virtual → modbus_tcp |
| **优先级** | P0 |

---

## 5. Modbus RTU 协议表单测试

### TC-RTU-001: Modbus RTU 协议表单字段完整显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-001 |
| **测试名称** | Modbus RTU 协议表单字段完整显示 |
| **测试目的** | 验证 Modbus RTU 协议下所有字段正确显示 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 验证串口选择下拉框可见<br>4. 验证波特率选择器可见<br>5. 验证数据位选择器可见<br>6. 验证停止位选择器可见<br>7. 验证校验选择器可见<br>8. 验证从站ID输入框可见<br>9. 验证超时时间输入框可见 |
| **预期结果** | 1. 串口选择 (label: '串口选择' 或 'Serial Port') 可见<br>2. 波特率 (label: '波特率') 可见<br>3. 数据位 (label: '数据位') 可见<br>4. 停止位 (label: '停止位') 可见<br>5. 校验 (label: '校验') 可见<br>6. 从站ID 输入框可见<br>7. 超时时间 输入框可见 |
| **测试数据** | 协议: modbus_rtu |
| **优先级** | P0 |

---

### TC-RTU-002: Modbus RTU 串口选择下拉框显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-002 |
| **测试名称** | Modbus RTU 串口选择下拉框显示 |
| **测试目的** | 验证串口选择下拉框正确渲染并可展开 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU，串口列表已加载 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 点击串口选择下拉框<br>4. 验证下拉列表展开 |
| **预期结果** | 1. 串口下拉框可点击<br>2. 下拉列表展示可用串口（或空状态提示） |
| **测试数据** | 模拟串口列表: ["/dev/ttyUSB0", "/dev/ttyACM0"] |
| **优先级** | P0 |

---

### TC-RTU-003: Modbus RTU 串口选择下拉框加载串口列表

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-003 |
| **测试名称** | Modbus RTU 串口选择下拉框加载串口列表 |
| **测试目的** | 验证串口选择下拉框从后端 API 正确加载可用串口列表 |
| **前置条件** | 后端 GET /api/v1/system/serial-ports 返回串口列表 |
| **测试步骤** | 1. Mock 串口 API 返回: [{path: "/dev/ttyUSB0", description: "USB Serial"}, {path: "/dev/ttyACM0", description: "USB ACM"}]<br>2. 打开 Create Device dialog<br>3. 选择协议类型为 modbus_rtu<br>4. 打开串口选择下拉框<br>5. 验证下拉列表包含 "/dev/ttyUSB0"<br>6. 验证下拉列表包含 "/dev/ttyACM0" |
| **预期结果** | 1. 下拉列表包含 2 个串口选项<br>2. 选项文本包含串口路径和描述 |
| **测试数据** | 串口列表: ["/dev/ttyUSB0", "/dev/ttyACM0"] |
| **优先级** | P0 |

---

### TC-RTU-004: Modbus RTU 串口选择无可用串口时空状态

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-004 |
| **测试名称** | Modbus RTU 串口选择无可用串口时空状态 |
| **测试目的** | 验证系统无可用串口时，下拉框显示合理的空状态提示 |
| **前置条件** | 后端 GET /api/v1/system/serial-ports 返回空列表 [] |
| **测试步骤** | 1. Mock 串口 API 返回空列表<br>2. 打开 Create Device dialog<br>3. 选择协议类型为 modbus_rtu<br>4. 打开串口选择下拉框<br>5. 验证空状态提示信息显示 |
| **预期结果** | 1. 下拉框显示 "无可用串口" 或类似提示<br>2. 用户可以手动输入串口路径（作为 fallback） |
| **测试数据** | 串口列表: [] (空) |
| **优先级** | P1 |

---

### TC-RTU-005: Modbus RTU 波特率选择器默认值 9600

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-005 |
| **测试名称** | Modbus RTU 波特率选择器默认值 9600 |
| **测试目的** | 验证波特率选择器的默认值为 9600 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 验证波特率选择器当前选中值为 "9600" |
| **预期结果** | 1. 波特率选择器显示 "9600" |
| **测试数据** | 默认波特率: 9600 |
| **优先级** | P0 |

---

### TC-RTU-006: Modbus RTU 波特率选择器包含所有选项

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-006 |
| **测试名称** | Modbus RTU 波特率选择器包含所有选项 |
| **测试目的** | 验证波特率选择器包含所有标准波特率选项 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 打开波特率下拉框<br>4. 验证选项: 9600<br>5. 验证选项: 19200<br>6. 验证选项: 38400<br>7. 验证选项: 57600<br>8. 验证选项: 115200 |
| **预期结果** | 1. 下拉列表包含 5 个波特率<br>2. 选项: [9600, 19200, 38400, 57600, 115200] |
| **测试数据** | 波特率列表: [9600, 19200, 38400, 57600, 115200] |
| **优先级** | P0 |

---

### TC-RTU-007: Modbus RTU 数据位选择器默认值 8

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-007 |
| **测试名称** | Modbus RTU 数据位选择器默认值 8 |
| **测试目的** | 验证数据位选择器默认值为 8，选项包含 7 和 8 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 验证数据位选择器当前选中值为 "8"<br>4. 打开下拉框验证选项: 7, 8 |
| **预期结果** | 1. 默认值为 8<br>2. 选项: [7, 8] |
| **测试数据** | 数据位: 默认 8, 选项 [7, 8] |
| **优先级** | P0 |

---

### TC-RTU-008: Modbus RTU 停止位选择器默认值 1

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-008 |
| **测试名称** | Modbus RTU 停止位选择器默认值 1 |
| **测试目的** | 验证停止位选择器默认值为 1，选项包含 1 和 2 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 验证停止位选择器当前选中值为 "1"<br>4. 打开下拉框验证选项: 1, 2 |
| **预期结果** | 1. 默认值为 1<br>2. 选项: [1, 2] |
| **测试数据** | 停止位: 默认 1, 选项 [1, 2] |
| **优先级** | P0 |

---

### TC-RTU-009: Modbus RTU 校验位选择器默认值 None

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-009 |
| **测试名称** | Modbus RTU 校验位选择器默认值 None |
| **测试目的** | 验证校验位选择器默认值为 None，选项包含 None/Even/Odd |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 验证校验位选择器当前选中值为 "None"<br>4. 打开下拉框验证选项: None, Even, Odd |
| **预期结果** | 1. 默认值为 None<br>2. 选项: [None, Even, Odd] |
| **测试数据** | 校验位: 默认 None, 选项 [None, Even, Odd] |
| **优先级** | P0 |

---

### TC-RTU-010: Modbus RTU 从站ID输入框

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-010 |
| **测试名称** | Modbus RTU 从站ID输入框 |
| **测试目的** | 验证 RTU 表单中的从站ID输入框可接受合法值 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 在从站ID输入框输入 "5"<br>4. 验证输入框显示 "5" |
| **预期结果** | 1. 从站ID输入框文本为 "5"<br>2. 默认值应为 1<br>3. keyboardType 为数字键盘 |
| **测试数据** | 从站ID: 5 |
| **优先级** | P0 |

---

### TC-RTU-011: Modbus RTU 超时时间输入框

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-011 |
| **测试名称** | Modbus RTU 超时时间输入框 |
| **测试目的** | 验证 RTU 表单中的超时时间输入框可接受合法值 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_rtu<br>3. 在超时时间输入框输入 "3000"<br>4. 验证输入框显示 "3000" |
| **预期结果** | 1. 超时时间输入框文本为 "3000"<br>2. keyboardType 为数字键盘 |
| **测试数据** | 超时时间: 3000 ms |
| **优先级** | P1 |

---

### TC-RTU-012: 切换至 Modbus RTU 时 TCP 字段不可见

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-RTU-012 |
| **测试名称** | 切换至 Modbus RTU 时 TCP 字段不可见 |
| **测试目的** | 验证选择 Modbus RTU 后 Modbus TCP 专用字段完全隐藏 |
| **前置条件** | DeviceFormDialog 已实现，当前为 Modbus TCP 协议 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议类型为 modbus_tcp<br>3. 确认 TCP 字段可见<br>4. 切换协议为 modbus_rtu<br>5. 验证主机地址输入框不可见<br>6. 验证端口输入框不可见<br>7. 验证连接池大小输入框不可见 |
| **预期结果** | 1. 主机地址输入框从 widget tree 消失<br>2. 端口输入框从 widget tree 消失<br>3. 连接池大小输入框从 widget tree 消失<br>4. RTU 参数字段正确显示 |
| **测试数据** | 协议序列: modbus_tcp → modbus_rtu |
| **优先级** | P0 |

---

## 6. 表单验证测试

### TC-VAL-001: IP 地址格式验证 - 无效格式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-001 |
| **测试名称** | IP 地址格式验证 - 无效格式 |
| **测试目的** | 验证输入无效 IP 地址格式时显示错误信息 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入无效 IP: "256.1.1.1" (每段不能超过255)<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 主机地址输入框显示错误提示 "IP地址格式无效"<br>3. 对话框未关闭 |
| **测试数据** | 无效IP: "256.1.1.1" |
| **优先级** | P0 |

---

### TC-VAL-002: IP 地址格式验证 - 有效格式

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-002 |
| **测试名称** | IP 地址格式验证 - 有效格式 |
| **测试目的** | 验证输入有效 IP 地址格式时不显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP，设备名称已填写 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入设备名称 "Device1"<br>4. 输入有效 IP: "192.168.1.100"<br>5. 点击提交按钮<br>6. 验证不显示 IP 格式错误 |
| **预期结果** | 1. IP 地址字段无错误提示<br>2. 表单可正常提交（假设其他字段有效） |
| **测试数据** | 有效IP: "192.168.1.100" |
| **优先级** | P0 |

---

### TC-VAL-003: IP 地址格式验证 - 无效格式（非数字）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-003 |
| **测试名称** | IP 地址格式验证 - 无效格式（非数字） |
| **测试目的** | 验证输入非 IP 格式的字符串时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入无效值: "abc.def.ghi.jkl"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 主机地址输入框显示 "IP地址格式无效" |
| **测试数据** | 无效IP: "abc.def.ghi.jkl" |
| **优先级** | P0 |

---

### TC-VAL-004: IP 地址格式验证 - 缺少段

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-004 |
| **测试名称** | IP 地址格式验证 - 缺少段 |
| **测试目的** | 验证输入不完整的 IP 地址时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入不完整 IP: "192.168.1"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 主机地址输入框显示 "IP地址格式无效" |
| **测试数据** | 不完整IP: "192.168.1" |
| **优先级** | P0 |

---

### TC-VAL-005: 端口范围验证 - 超出范围（65536）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-005 |
| **测试名称** | 端口范围验证 - 超出范围（65536） |
| **测试目的** | 验证端口输入超出 65535 时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入端口: "65536"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 端口输入框显示 "端口范围 1-65535" |
| **测试数据** | 端口: 65536 |
| **优先级** | P0 |

---

### TC-VAL-006: 端口范围验证 - 为 0

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-006 |
| **测试名称** | 端口范围验证 - 为 0 |
| **测试目的** | 验证端口输入 0 时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入端口: "0"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 端口输入框显示 "端口范围 1-65535" |
| **测试数据** | 端口: 0 |
| **优先级** | P0 |

---

### TC-VAL-007: 端口范围验证 - 有效范围内

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-007 |
| **测试名称** | 端口范围验证 - 有效范围内 |
| **测试目的** | 验证端口在 1-65535 范围内时不显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP，设备名称已填写，IP地址有效 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入设备名称 "Device1"<br>4. 输入有效 IP "192.168.1.1"<br>5. 输入端口: "8080"<br>6. 点击提交按钮<br>7. 验证端口字段无错误 |
| **预期结果** | 1. 端口字段无错误提示<br>2. 表单可正常提交 |
| **测试数据** | 端口: 8080 |
| **优先级** | P1 |

---

### TC-VAL-008: 从站ID范围验证 - 超出范围（248）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-008 |
| **测试名称** | 从站ID范围验证 - 超出范围（248） |
| **测试目的** | 验证从站ID输入超出 247 时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP 或 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入从站ID: "248"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 从站ID输入框显示 "从站ID范围 1-247" |
| **测试数据** | 从站ID: 248 |
| **优先级** | P0 |

---

### TC-VAL-009: 从站ID范围验证 - 为 0

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-009 |
| **测试名称** | 从站ID范围验证 - 为 0 |
| **测试目的** | 验证从站ID输入 0 时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP 或 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入从站ID: "0"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 从站ID输入框显示 "从站ID范围 1-247" |
| **测试数据** | 从站ID: 0 |
| **优先级** | P0 |

---

### TC-VAL-010: 从站ID范围验证 - 有效范围内（1~247）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-010 |
| **测试名称** | 从站ID范围验证 - 有效范围内（1~247） |
| **测试目的** | 验证从站ID在 1-247 范围内时不显示错误（覆盖边界值） |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP，设备和IP已填写 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入设备名称 "Device1"、有效IP<br>4. 输入从站ID: "1" (下边界)<br>5. 点击提交，验证无错误<br>6. 修改从站ID为 "247" (上边界)<br>7. 点击提交，验证无错误 |
| **预期结果** | 1. 从站ID = 1: 提交无错误<br>2. 从站ID = 247: 提交无错误 |
| **测试数据** | 从站ID: 1, 247 |
| **优先级** | P0 |

---

### TC-VAL-011: 设备名称必填验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-011 |
| **测试名称** | 设备名称必填验证 |
| **测试目的** | 验证设备名称为空时提交被阻止并显示错误 |
| **前置条件** | DeviceFormDialog 已实现 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 不输入设备名称<br>3. 点击提交按钮<br>4. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 设备名称输入框显示 "设备名称不能为空"<br>3. 对话框未关闭 |
| **测试数据** | 设备名称: (空) |
| **优先级** | P0 |

---

### TC-VAL-012: 最小值大于最大值验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-012 |
| **测试名称** | 最小值大于最大值验证 |
| **测试目的** | 验证 Virtual 协议下最小值大于最大值时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Virtual |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议为 Virtual<br>3. 输入最小值: "100"<br>4. 输入最大值: "50"<br>5. 点击提交按钮<br>6. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止 <br>2. 显示 "最小值不能大于最大值" 或类似错误 |
| **测试数据** | 最小值: 100, 最大值: 50 |
| **优先级** | P0 |

---

### TC-VAL-013: 所有字段有效时表单可提交

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-013 |
| **测试名称** | 所有字段有效时表单可提交 |
| **测试目的** | 验证所有验证通过时表单提交成功 |
| **前置条件** | DeviceFormDialog 已实现，DeviceService mock 返回成功 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入设备名称: "TestDevice"<br>4. 输入主机地址: "192.168.1.100"<br>5. 输入端口: "502"<br>6. 输入从站ID: "1"<br>7. 点击提交按钮<br>8. 验证对话框关闭 |
| **预期结果** | 1. 表单提交成功<br>2. 对话框关闭<br>3. 提交按钮显示加载状态（短暂）<br>4. createDevice API 被调用 |
| **测试数据** | 设备名称: "TestDevice", 主机: "192.168.1.100", 端口: 502, 从站ID: 1 |
| **优先级** | P0 |

---

### TC-VAL-014: 串口参数组合验证 - 有效组合

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-014 |
| **测试名称** | 串口参数组合验证 - 有效组合 |
| **测试目的** | 验证常见的有效串口参数组合通过验证 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_rtu<br>3. 配置: 波特率=9600, 数据位=8, 停止位=1, 校验=None<br>4. 输入设备名称 "TestDevice"<br>5. 点击提交<br>6. 验证无验证错误 |
| **预期结果** | 1. 串口参数验证通过<br>2. 表单可提交 |
| **测试数据** | 波特率: 9600, 数据位: 8, 停止位: 1, 校验: None |
| **优先级** | P1 |

---

### TC-VAL-015: 串口参数组合验证 - 无效组合（数据位7 + 校验None）

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-015 |
| **测试名称** | 串口参数组合验证 - 无效组合（数据位7 + 校验None） |
| **测试目的** | 验证 Modbus RTU 不支持 7N1 组合（数据位7+校验None）时显示警告或自动纠正 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus RTU |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_rtu<br>3. 配置: 数据位=7, 校验=None<br>4. 验证是否存在提示信息 |
| **预期结果** | 1. 如果系统不支持 7N1，应显示警告或自动将校验改为 Even<br>2. 或提交时返回验证错误提示 |
| **测试数据** | 数据位: 7, 校验: None |
| **优先级** | P1 |

---

### TC-VAL-016: 端口输入非数字验证

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-VAL-016 |
| **测试名称** | 端口输入非数字验证 |
| **测试目的** | 验证端口输入非数字字符时显示错误 |
| **前置条件** | DeviceFormDialog 已实现，协议类型为 Modbus TCP |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入端口: "abc"<br>4. 点击提交按钮<br>5. 验证错误信息显示 |
| **预期结果** | 1. 提交被阻止<br>2. 端口输入框显示 "请输入有效端口号" 或类似错误 |
| **测试数据** | 端口: "abc" |
| **优先级** | P1 |

---

## 7. 用户交互流程测试

### TC-FLOW-001: 创建 Virtual 设备完整流程

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-001 |
| **测试名称** | 创建 Virtual 设备完整流程 |
| **测试目的** | 验证通过 Virtual 协议创建设备的端到端流程 |
| **前置条件** | DeviceFormDialog 已实现，DeviceService mock 就绪 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 确认协议为 Virtual<br>3. 输入设备名称: "VirtualDevice1"<br>4. 模式选择: Random<br>5. 数据类型: Number<br>6. 访问类型: RW<br>7. 最小值: 0, 最大值: 200<br>8. 采样间隔: 1000<br>9. 点击提交按钮<br>10. 验证对话框关闭<br>11. 验证 createDevice API 被调用且参数正确 |
| **预期结果** | 1. 对话框成功关闭<br>2. createDevice 被调用<br>3. protocolParams 包含: {mode: "random", dataType: "number", accessType: "rw", minValue: 0, maxValue: 200, sampleInterval: 1000} |
| **测试数据** | 设备名称: "VirtualDevice1" |
| **优先级** | P0 |

---

### TC-FLOW-002: 创建 Modbus TCP 设备完整流程

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-002 |
| **测试名称** | 创建 Modbus TCP 设备完整流程 |
| **测试目的** | 验证通过 Modbus TCP 协议创建设备的端到端流程 |
| **前置条件** | DeviceFormDialog 已实现，DeviceService mock 就绪 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_tcp<br>3. 输入设备名称: "ModbusTCPDevice1"<br>4. 输入主机地址: "192.168.1.100"<br>5. 输入端口: "502"<br>6. 输入从站ID: "1"<br>7. 输入超时时间: "5000"<br>8. 输入连接池大小: "4"<br>9. 点击提交按钮<br>10. 验证对话框关闭<br>11. 验证 createDevice API 被调用且参数正确 |
| **预期结果** | 1. 对话框成功关闭<br>2. createDevice 被调用<br>3. protocolType: modbus_tcp<br>4. protocolParams 包含: {host: "192.168.1.100", port: 502, slaveId: 1, timeoutMs: 5000, connectionPoolSize: 4} |
| **测试数据** | 设备名称: "ModbusTCPDevice1" |
| **优先级** | P0 |

---

### TC-FLOW-003: 创建 Modbus RTU 设备完整流程

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-003 |
| **测试名称** | 创建 Modbus RTU 设备完整流程 |
| **测试目的** | 验证通过 Modbus RTU 协议创建设备的端到端流程 |
| **前置条件** | DeviceFormDialog 已实现，DeviceService mock 就绪，串口API mock 返回列表 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 选择协议为 modbus_rtu<br>3. 输入设备名称: "ModbusRTUDevice1"<br>4. 选择串口: "/dev/ttyUSB0"<br>5. 选择波特率: 9600<br>6. 选择数据位: 8<br>7. 选择停止位: 1<br>8. 选择校验: None<br>9. 输入从站ID: "1"<br>10. 输入超时时间: "1000"<br>11. 点击提交按钮<br>12. 验证对话框关闭<br>13. 验证 createDevice API 被调用且参数正确 |
| **预期结果** | 1. 对话框成功关闭<br>2. createDevice 被调用<br>3. protocolType: modbus_rtu<br>4. protocolParams 包含: {port: "/dev/ttyUSB0", baudRate: 9600, dataBits: 8, stopBits: 1, parity: "None", slaveId: 1, timeoutMs: 1000} |
| **测试数据** | 设备名称: "ModbusRTUDevice1" |
| **优先级** | P0 |

---

### TC-FLOW-004: 编辑设备表单预填充

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-004 |
| **测试名称** | 编辑设备表单预填充 |
| **测试目的** | 验证编辑已有设备时表单字段正确预填充现有值 |
| **前置条件** | 已存在一个 Modbus TCP 设备 test-device-1 |
| **测试步骤** | 1. 传入 device 参数（protocolType: modbus_tcp, name: "ExistingDevice", protocolParams: {host: "10.0.0.1", port: "502", slaveId: "1"}）<br>2. 打开 Edit Device dialog<br>3. 验证设备名称输入框预填充 "ExistingDevice"<br>4. 验证主机地址预填充 "10.0.0.1"<br>5. 验证端口预填充 "502"<br>6. 验证协议类型下拉框显示 "MODBUSTCP" 且禁用 |
| **预期结果** | 1. 设备名称: "ExistingDevice"<br>2. 主机地址: "10.0.0.1"（如果是TCP）<br>3. 端口: "502"<br>4. 协议类型不可修改 |
| **测试数据** | 设备: Device(id: "test-device-1", name: "ExistingDevice", protocolType: modbus_tcp) |
| **优先级** | P0 |

---

### TC-FLOW-005: 取消创建设备

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-005 |
| **测试名称** | 取消创建设备 |
| **测试目的** | 验证点击取消按钮后对话框关闭且不调用 API |
| **前置条件** | DeviceFormDialog 已实现 |
| **测试步骤** | 1. 打开 Create Device dialog<br>2. 输入设备名称: "TestDevice"<br>3. 输入一些表单字段值<br>4. 点击取消按钮<br>5. 验证对话框关闭<br>6. 验证 createDevice API 未被调用 |
| **预期结果** | 1. 对话框关闭（pop）<br>2. createDevice API 未被调用<br>3. 返回值为 false 或 null |
| **测试数据** | 设备名称: "TestDevice" |
| **优先级** | P0 |

---

### TC-FLOW-006: 提交失败时显示错误提示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-006 |
| **测试名称** | 提交失败时显示错误提示 |
| **测试目的** | 验证 API 调用失败时正确显示错误 SnackBar |
| **前置条件** | DeviceFormDialog 已实现，DeviceService mock 抛出异常 |
| **测试步骤** | 1. Mock createDevice API 抛出异常 "Network error"<br>2. 打开 Create Device dialog<br>3. 输入设备名称 "TestDevice"<br>4. 选择协议 virtual<br>5. 点击提交按钮<br>6. 验证 SnackBar 显示 "操作失败: Network error"<br>7. 验证对话框未关闭 |
| **预期结果** | 1. SnackBar 显示错误消息<br>2. 对话框保持打开状态<br>3. 提交按钮恢复为可用状态（非 loading） |
| **测试数据** | API 异常: Exception("Network error") |
| **优先级** | P1 |

---

### TC-FLOW-007: 提交时加载状态显示

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-FLOW-007 |
| **测试名称** | 提交时加载状态显示 |
| **测试目的** | 验证提交过程中按钮显示加载动画且禁用 |
| **前置条件** | DeviceFormDialog 已实现，DeviceService mock 延迟响应 |
| **测试步骤** | 1. Mock createDevice API 延迟 500ms 后返回成功<br>2. 打开 Create Device dialog<br>3. 输入设备名称 "TestDevice"<br>4. 选择协议 virtual<br>5. 点击提交按钮<br>6. 验证按钮显示 CircularProgressIndicator<br>7. 验证按钮处于禁用状态<br>8. 等待 API 返回<br>9. 验证对话框关闭 |
| **预期结果** | 1. 按钮显示加载动画（CircularProgressIndicator）<br>2. 按钮文字消失或变为加载指示器<br>3. 取消按钮也应禁用（防止重复操作） |
| **测试数据** | API 延迟: 500ms |
| **优先级** | P1 |

---

## 8. 测试数据需求

### 8.1 协议选择器测试数据

| 参数 | 有效值 | 说明 |
|------|--------|------|
| ProtocolType | virtual, modbus_tcp, modbus_rtu | 三种协议枚举值 |
| workbenchId | "wb-001" | 测试用工作台UUID |

### 8.2 Virtual 协议参数测试数据

| 参数 | 有效值 | 默认值 |
|------|--------|--------|
| mode | Random, Fixed, Sine, Ramp | Random |
| dataType | Number, Integer, String, Boolean | Number |
| accessType | RO, WO, RW | RO |
| minValue | 0, -100, 0.5, 100 | 0 |
| maxValue | 100, 200, 0.5, 1000 | 100 |
| sampleInterval | 100, 1000, 5000, 60000 | 1000 |
| fixedValue (Fixed模式) | 0, 42.5, -10, "hello", true | (空) |

### 8.3 Modbus TCP 参数测试数据

| 参数 | 有效值 | 无效值 | 默认值 |
|------|--------|--------|--------|
| host | "192.168.1.100", "10.0.0.1", "localhost" | "256.1.1.1", "abc", "192.168.1" | (空) |
| port | 1, 502, 8080, 65535 | 0, 65536, -1, "abc" | 502 |
| slaveId | 1, 2, 247 | 0, 248, -1, "abc" | 1 |
| timeoutMs | 1000, 3000, 5000, 10000 | 0, -1 | 5000 |
| connectionPoolSize | 1, 4, 8, 16 | 0, -1 | 4 |

### 8.4 Modbus RTU 参数测试数据

| 参数 | 有效值 | 无效值 | 默认值 |
|------|--------|--------|--------|
| port | "/dev/ttyUSB0", "/dev/ttyACM0", "COM1" | "/dev/null", "" | (空/第一个可用) |
| baudRate | 9600, 19200, 38400, 57600, 115200 | 1000, 0 | 9600 |
| dataBits | 7, 8 | 5, 6, 9 | 8 |
| stopBits | 1, 2 | 0, 1.5, 3 | 1 |
| parity | None, Even, Odd | Mark, Space | None |
| slaveId | 1-247 | 0, 248 | 1 |
| timeoutMs | 1000, 3000, 5000 | 0, -1 | 1000 |

### 8.5 边界值测试数据

| 测试维度 | 边界值 |
|----------|--------|
| IP地址 | 每段0-255边界: "0.0.0.0", "255.255.255.255", "127.0.0.1" |
| 端口 | 下边界: 1, 上边界: 65535, 边界外: 0 和 65536 |
| 从站ID | 下边界: 1, 上边界: 247, 边界外: 0 和 248 |
| 设备名称 | 空字符串, 单字符 "A", 超长字符串 (256字符) |
| 超时时间 | 最小值: 1ms, 典型值: 3000ms, 最大值: 60000ms |
| 连接池 | 最小值: 1, 典型值: 4, 最大值: 32 |

---

## 9. 测试环境

### 9.1 开发环境

| 项目 | 要求 |
|------|------|
| Flutter 版本 | >= 3.x |
| 测试框架 | flutter_test (WidgetTester) |
| 状态管理 | flutter_riverpod (ProviderContainer override) |
| Mock 工具 | mockito 或 自定义 mock |
| 运行命令 | `flutter test test/features/workbench/device_config_test.dart` |

### 9.2 测试命令

```bash
# 运行设备配置 UI Widget 测试
flutter test test/features/workbench/device_config_test.dart

# 运行所有 Widget 测试
flutter test test/widget/

# 带覆盖率运行
flutter test --coverage test/features/workbench/device_config_test.dart

# 生成覆盖率报告
genhtml coverage/lcov.info -o coverage/html
```

### 9.3 Mock 依赖

| 依赖 | 说明 |
|------|------|
| DeviceService | Mock 设备服务，模拟 createDevice/updateDevice API |
| SerialPort API | Mock 串口扫描 API 返回 |
| Protocol API | Mock 协议列表 API 返回 |

---

## 10. 风险与假设

### 10.1 测试假设

| 假设ID | 描述 |
|--------|------|
| ASM-UI-101 | DeviceFormDialog 将在 `kayak-frontend/lib/features/workbench/widgets/device/device_form_dialog.dart` 中扩展 |
| ASM-UI-102 | ProtocolType 枚举已包含 virtual, modbus_tcp, modbus_rtu 变体 |
| ASM-UI-103 | 表单使用 Flutter Form + TextFormField/DropdownButtonFormField 组件 |
| ASM-UI-104 | 状态管理使用 Riverpod (ConsumerStatefulWidget) |
| ASM-UI-105 | 协议切换通过 setState 触发 re-render（conditional rendering） |
| ASM-UI-106 | 验证逻辑在前端执行（即时反馈），后端作为二次验证 |

### 10.2 测试风险

| 风险ID | 风险描述 | 缓解措施 |
|--------|---------|---------|
| RSK-UI-101 | UI 尚未开发完成，测试用例需等待实现 | 测试用例优先设计（TDD），可在开发前完成 |
| RSK-UI-102 | Figma 原型修改导致 UI 结构变化 | 测试用例基于 PRD 而非具体实现，保持通用性 |
| RSK-UI-103 | 串口扫描API在测试环境不可用 | 使用 mock API 返回固定串口列表 |
| RSK-UI-104 | DeviceService 接口可能变更 | 测试用例中 mock service 独立于实际实现 |
| RSK-UI-105 | Widget key 命名可能与实现不一致 | 测试中使用语义化查找（find.text）作为 fallback |

### 10.3 测试阻塞项

| 阻塞项 | 依赖 | 状态 |
|--------|------|------|
| DeviceFormDialog Modbus 扩展实现 | R1-S1-006-B (开发) | 待开发 |
| 协议验证器实现 (IP/Port/SlaveID validators) | R1-S1-006-B (开发) | 待开发 |
| ProtocolType 枚举已就绪 | device.dart (已完成) | 已完成 |
| DeviceService 接口已就绪 | R1-S1-019 (已完成) | 已完成 |

---

## 11. 测试用例汇总

| 测试ID | 测试名称 | 优先级 | 类型 | 状态 |
|--------|---------|--------|------|------|
| TC-UI-001 | 协议选择器默认显示 Virtual | P0 | Widget测试 | 待执行 |
| TC-UI-002 | 协议选择器下拉列表包含所有协议选项 | P0 | Widget测试 | 待执行 |
| TC-UI-003 | 选择 Virtual 协议并验证表单显示 | P0 | Widget测试 | 待执行 |
| TC-UI-004 | 选择 Modbus TCP 协议并验证表单显示 | P0 | Widget测试 | 待执行 |
| TC-UI-005 | 选择 Modbus RTU 协议并验证表单显示 | P0 | Widget测试 | 待执行 |
| TC-UI-006 | 协议切换 Virtual → Modbus TCP 表单动态更新 | P0 | Widget测试 | 待执行 |
| TC-UI-007 | 协议切换 Modbus TCP → Modbus RTU 表单动态更新 | P0 | Widget测试 | 待执行 |
| TC-UI-008 | 协议切换 Modbus RTU → Virtual 表单动态更新 | P0 | Widget测试 | 待执行 |
| TC-UI-009 | 协议切换后上一个协议的表单字段完全不可见 | P0 | Widget测试 | 待执行 |
| TC-UI-010 | 编辑模式下协议选择器不可修改 | P0 | Widget测试 | 待执行 |
| TC-UI-011 | 协议切换保留通用字段值 | P1 | Widget测试 | 待执行 |
| TC-UI-012 | 协议切换重置协议特定字段值 | P1 | Widget测试 | 待执行 |
| TC-VF-001 | Virtual 协议模式选择器配置 | P0 | Widget测试 | 待执行 |
| TC-VF-002 | Virtual 协议选择 Random 模式 | P0 | Widget测试 | 待执行 |
| TC-VF-003 | Virtual 协议选择 Fixed 模式 | P0 | Widget测试 | 待执行 |
| TC-VF-004 | Virtual 协议选择 Sine 模式 | P1 | Widget测试 | 待执行 |
| TC-VF-005 | Virtual 协议选择 Ramp 模式 | P1 | Widget测试 | 待执行 |
| TC-VF-006 | Virtual 协议数据类型选择器 | P0 | Widget测试 | 待执行 |
| TC-VF-007 | Virtual 协议选择 Number 数据类型 | P1 | Widget测试 | 待执行 |
| TC-VF-008 | Virtual 协议访问类型选择器 | P0 | Widget测试 | 待执行 |
| TC-VF-009 | Virtual 协议最小值输入 | P0 | Widget测试 | 待执行 |
| TC-VF-010 | Virtual 协议最大值输入 | P0 | Widget测试 | 待执行 |
| TC-VF-011 | Virtual 协议 Fixed 模式固定值输入 | P0 | Widget测试 | 待执行 |
| TC-VF-012 | Virtual 协议默认值验证 | P1 | Widget测试 | 待执行 |
| TC-TCP-001 | Modbus TCP 协议表单字段完整显示 | P0 | Widget测试 | 待执行 |
| TC-TCP-002 | Modbus TCP 主机地址输入框 | P0 | Widget测试 | 待执行 |
| TC-TCP-003 | Modbus TCP 主机地址默认值 | P1 | Widget测试 | 待执行 |
| TC-TCP-004 | Modbus TCP 端口输入框默认值 502 | P0 | Widget测试 | 待执行 |
| TC-TCP-005 | Modbus TCP 端口数字输入 | P0 | Widget测试 | 待执行 |
| TC-TCP-006 | Modbus TCP 从站ID输入框默认值 1 | P0 | Widget测试 | 待执行 |
| TC-TCP-007 | Modbus TCP 从站ID数字输入 | P0 | Widget测试 | 待执行 |
| TC-TCP-008 | Modbus TCP 超时时间输入框 | P1 | Widget测试 | 待执行 |
| TC-TCP-009 | Modbus TCP 连接池大小输入框 | P1 | Widget测试 | 待执行 |
| TC-TCP-010 | Modbus TCP 通用设备字段仍可见 | P1 | Widget测试 | 待执行 |
| TC-TCP-011 | 切换至 Modbus TCP 时 Virtual 字段不可见 | P0 | Widget测试 | 待执行 |
| TC-RTU-001 | Modbus RTU 协议表单字段完整显示 | P0 | Widget测试 | 待执行 |
| TC-RTU-002 | Modbus RTU 串口选择下拉框显示 | P0 | Widget测试 | 待执行 |
| TC-RTU-003 | Modbus RTU 串口选择下拉框加载串口列表 | P0 | Widget测试 | 待执行 |
| TC-RTU-004 | Modbus RTU 串口选择无可用串口时空状态 | P1 | Widget测试 | 待执行 |
| TC-RTU-005 | Modbus RTU 波特率选择器默认值 9600 | P0 | Widget测试 | 待执行 |
| TC-RTU-006 | Modbus RTU 波特率选择器包含所有选项 | P0 | Widget测试 | 待执行 |
| TC-RTU-007 | Modbus RTU 数据位选择器默认值 8 | P0 | Widget测试 | 待执行 |
| TC-RTU-008 | Modbus RTU 停止位选择器默认值 1 | P0 | Widget测试 | 待执行 |
| TC-RTU-009 | Modbus RTU 校验位选择器默认值 None | P0 | Widget测试 | 待执行 |
| TC-RTU-010 | Modbus RTU 从站ID输入框 | P0 | Widget测试 | 待执行 |
| TC-RTU-011 | Modbus RTU 超时时间输入框 | P1 | Widget测试 | 待执行 |
| TC-RTU-012 | 切换至 Modbus RTU 时 TCP 字段不可见 | P0 | Widget测试 | 待执行 |
| TC-VAL-001 | IP 地址格式验证 - 无效格式（段值>255） | P0 | Widget测试 | 待执行 |
| TC-VAL-002 | IP 地址格式验证 - 有效格式 | P0 | Widget测试 | 待执行 |
| TC-VAL-003 | IP 地址格式验证 - 无效格式（非数字） | P0 | Widget测试 | 待执行 |
| TC-VAL-004 | IP 地址格式验证 - 缺少段 | P0 | Widget测试 | 待执行 |
| TC-VAL-005 | 端口范围验证 - 超出范围（65536） | P0 | Widget测试 | 待执行 |
| TC-VAL-006 | 端口范围验证 - 为 0 | P0 | Widget测试 | 待执行 |
| TC-VAL-007 | 端口范围验证 - 有效范围内（8080） | P1 | Widget测试 | 待执行 |
| TC-VAL-008 | 从站ID范围验证 - 超出范围（248） | P0 | Widget测试 | 待执行 |
| TC-VAL-009 | 从站ID范围验证 - 为 0 | P0 | Widget测试 | 待执行 |
| TC-VAL-010 | 从站ID范围验证 - 有效范围内（1~247） | P0 | Widget测试 | 待执行 |
| TC-VAL-011 | 设备名称必填验证 | P0 | Widget测试 | 待执行 |
| TC-VAL-012 | 最小值大于最大值验证 | P0 | Widget测试 | 待执行 |
| TC-VAL-013 | 所有字段有效时表单可提交 | P0 | Widget测试 | 待执行 |
| TC-VAL-014 | 串口参数组合验证 - 有效组合 | P1 | Widget测试 | 待执行 |
| TC-VAL-015 | 串口参数组合验证 - 无效组合（7N1） | P1 | Widget测试 | 待执行 |
| TC-VAL-016 | 端口输入非数字验证 | P1 | Widget测试 | 待执行 |
| TC-FLOW-001 | 创建 Virtual 设备完整流程 | P0 | 集成测试 | 待执行 |
| TC-FLOW-002 | 创建 Modbus TCP 设备完整流程 | P0 | 集成测试 | 待执行 |
| TC-FLOW-003 | 创建 Modbus RTU 设备完整流程 | P0 | 集成测试 | 待执行 |
| TC-FLOW-004 | 编辑设备表单预填充 | P0 | 集成测试 | 待执行 |
| TC-FLOW-005 | 取消创建设备 | P0 | Widget测试 | 待执行 |
| TC-FLOW-006 | 提交失败时显示错误提示 | P1 | 集成测试 | 待执行 |
| TC-FLOW-007 | 提交时加载状态显示 | P1 | Widget测试 | 待执行 |

**总计: 70 个测试用例**

---

## 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2026-05-03 | sw-mike | 初始版本，包含 70 个设备配置UI测试用例：<br>- Section 2: 协议选择器测试 (12个)<br>- Section 3: Virtual 协议表单测试 (12个)<br>- Section 4: Modbus TCP 协议表单测试 (11个)<br>- Section 5: Modbus RTU 协议表单测试 (12个)<br>- Section 6: 表单验证测试 (16个)<br>- Section 7: 用户交互流程测试 (7个) |

---

*本文档由 Kayak 项目测试团队维护。如有问题，请联系测试工程师 sw-mike。*
