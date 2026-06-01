# TASK-017 详细设计 — 设备配置表单

> **作者**: sw-tom (Developer)
> **日期**: 2026-05-31
> **状态**: 已完成
> **关联任务**: TASK-017
> **参考文档**: [tasks.md](../tasks.md), [device_config_spec.md](../ui/specifications/device_config_spec.md), [TASK-016 设计](TASK-016_design.md)
> **实现文件**: `kayak-frontend/lib/widgets/device_config_dialog.dart`

---

## 1. 概述

设备配置表单 (DeviceConfigDialog) 是一个模态对话框/底部 Sheet，用于创建或编辑设备。支持三种协议类型（Virtual / Modbus TCP / Modbus RTU）的动态配置区域切换，具备完整的表单验证、保存流程和错误反馈。

### 核心功能

| # | 功能 | 说明 |
|---|------|------|
| 1 | 双模式 | 添加设备（创建）和编辑设备（更新） |
| 2 | 基础信息 | 设备名称 + 协议类型选择 |
| 3 | 协议切换 | 根据协议类型动态切换配置区域（淡入淡出动画） |
| 4 | Virtual 配置 | 模式/数据类型/取值范围/更新间隔 |
| 5 | Modbus TCP 配置 | 主机地址/端口/从站 ID/超时 |
| 6 | Modbus RTU 配置 | 串口/波特率/数据位/停止位/校验位/从站 ID/超时 |
| 7 | 高级信息 | 制造商/型号/序列号（ExpansionTile 折叠） |
| 8 | 表单验证 | 必填检查、格式验证、范围验证、交叉字段验证 |
| 9 | 响应式适配 | 桌面 Dialog / 移动端 BottomSheet |

---

## 2. 组件结构 & 布局

```
DeviceConfigDialog (ConsumerStatefulWidget)
├── Layout Container (Column, mainAxisSize: min)
│   ├── Header (56px)
│   │   ├── Title: "添加设备" / "编辑设备" (titleMedium, w500)
│   │   ├── Close Button (IconButton, close icon)
│   │   └── Bottom Border (1px OutlineVariant)
│   ├── Content (Flexible → SingleChildScrollView, padding 16px)
│   │   ├── Section: 基础信息
│   │   │   ├── TextFormField "设备名称 *" (必填, max 255)
│   │   │   └── DropdownButtonFormField "协议类型 *" (必填)
│   │   ├── gap: 24px
│   │   ├── Section: 协议配置 (AnimatedSwitcher, 150ms)
│   │   │   ├── [Virtual]
│   │   │   │   ├── Dropdown: 虚拟模式 * (随机/正弦波/固定值/递增)
│   │   │   │   ├── Dropdown: 数据类型 * (int8~int64/float32/float64/bool)
│   │   │   │   ├── Row[TextField min ~ TextField max] 取值范围
│   │   │   │   └── TextField + ms suffix: 更新间隔 (≥100ms)
│   │   │   ├── [Modbus TCP]
│   │   │   │   ├── TextFormField: 主机地址 * (IPv4 格式验证)
│   │   │   │   ├── TextFormField: 端口 * (1-65535, default 502)
│   │   │   │   ├── TextFormField: 从站 ID (1-247, default 1)
│   │   │   │   └── TextField + ms suffix: 超时 (≥100ms, default 5000)
│   │   │   └── [Modbus RTU]
│   │   │       ├── TextFormField: 串口 * (动态列表 / 自由输入)
│   │   │       ├── Dropdown: 波特率 * (9600/19200/38400/57600/115200)
│   │   │       ├── Dropdown: 数据位 * (7/8)
│   │   │       ├── Dropdown: 停止位 * (1/2)
│   │   │       ├── Dropdown: 校验位 * (无/奇/偶)
│   │   │       ├── TextFormField: 从站 ID (1-247, default 1)
│   │   │       └── TextField + ms suffix: 超时 (≥100ms, default 5000)
│   │   ├── gap: 24px
│   │   └── Section: 高级信息 (ExpansionTile, 折叠)
│   │       ├── TextFormField: 制造商 (选填, max 255)
│   │       ├── TextFormField: 型号 (选填, max 255)
│   │       └── TextFormField: 序列号 (选填, max 255)
│   └── Actions (Bottom Border, padding 16px)
│       ├── [Desktop]: Row[TextButton 取消, FilledButton 保存]
│       └── [Mobile]: Column[FilledButton 保存, TextButton 取消] (全宽)
```

---

## 3. 状态管理

### 3.1 组件内部状态

| 状态 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `_formKey` | `GlobalKey<FormState>` | — | 表单全局验证 key |
| `_selectedProtocol` | `ProtocolType?` | `null` | 当前选择的协议类型 |
| `_virtualMode` | `String?` | `null` | Virtual 模式 |
| `_virtualDataType` | `String?` | `null` | Virtual 数据类型 |
| `_serialPort` | `String?` | `null` | RTU 串口 |
| `_baudRate` | `int?` | `null` | RTU 波特率 |
| `_dataBits` | `int?` | `null` | RTU 数据位 |
| `_stopBits` | `int?` | `null` | RTU 停止位 |
| `_parity` | `String?` | `null` | RTU 校验位 |
| `_isSaving` | `bool` | `false` | 保存中标志 |
| `_advancedExpanded` | `bool` | `false` | 高级信息展开状态 |

此外，每个表单字段都有对应的 `TextEditingController`（共 14 个控制器）。

### 3.2 TextEditingController 列表

| 组 | 控制器 | 用途 |
|----|--------|------|
| 通用 | `_nameController` | 设备名称 |
| 通用 | `_manufacturerController` | 制造商 |
| 通用 | `_modelController` | 型号 |
| 通用 | `_snController` | 序列号 |
| Virtual | `_minController` | 最小值 |
| Virtual | `_maxController` | 最大值 |
| Virtual | `_intervalController` | 更新间隔 |
| TCP | `_hostController` | 主机地址 |
| TCP | `_portController` | 端口 |
| TCP | `_tcpSlaveIdController` | 从站 ID |
| TCP | `_tcpTimeoutController` | 超时 |
| RTU | `_serialPortController` | 串口 |
| RTU | `_rtuSlaveIdController` | 从站 ID |
| RTU | `_rtuTimeoutController` | 超时 |

所有控制器在 `dispose()` 中释放。

### 3.3 外部 Provider 交互

```
  DeviceConfigDialog
       │
       ├─ 读: deviceTreeProvider(workbenchId).notifier
       │    └─ createDevice() / updateDevice() / deleteDevice()
       │
       └─ 写: 操作成功后自动 invalidate deviceTreeProvider
            └─ 触发 DeviceTree 重建刷新
```

---

## 4. 协议切换逻辑

```
协议类型 Dropdown onChange
  → setState { _selectedProtocol = value }
  → _clearProtocolFields()  // 重置所有协议专用字段到初始值
  → AnimatedSwitcher 检测 ValueKey(_selectedProtocol) 变更
  → 执行 150ms 淡入淡出动画
  → 渲染对应的协议配置区块
```

### 切换清空行为

切换协议时调用 `_clearProtocolFields()`，将所有协议专用字段重置为默认值：

- Virtual 字段 → null / 空 / '1000'
- Modbus TCP 字段 → 空 / '502' / '1' / '5000'
- Modbus RTU 字段 → null / '1' / '5000'

通用字段（设备名称、高级信息）不受影响。

---

## 5. 表单验证规则

### 5.1 通用字段

| 字段 | 规则 |
|------|------|
| 设备名称 | 必填，trimmed 非空，最大 255 字符 |
| 协议类型 | 必填，value != null |

### 5.2 Virtual 字段

| 字段 | 规则 |
|------|------|
| 虚拟模式 | 必填 |
| 数据类型 | 必填 |
| 最小值 | 选填，填写时须为有效数字 |
| 最大值 | 选填，填写时须为有效数字 + min < max |
| 更新间隔 | 选填，填写时须为整数 ≥ 100 |

### 5.3 Modbus TCP 字段

| 字段 | 规则 |
|------|------|
| 主机地址 | 必填，IPv4 格式（4 段，每段 0-255） |
| 端口 | 必填，整数 1-65535 |
| 从站 ID | 选填，填写时须为整数 1-247 |
| 超时 | 选填，填写时须为整数 ≥ 100 |

### 5.4 Modbus RTU 字段

| 字段 | 规则 |
|------|------|
| 串口 | 必填，非空 |
| 波特率 | 必填，Dropdown 选择 |
| 数据位 | Dropdown 选择（7/8） |
| 停止位 | Dropdown 选择（1/2） |
| 校验位 | Dropdown 选择（无/奇/偶） |
| 从站 ID | 选填，填写时须为整数 1-247 |
| 超时 | 选填，填写时须为整数 ≥ 100 |

### 5.5 触发时机

- **失焦验证**: `TextFormField.validator` — 用户移出字段时触发
- **提交验证**: `FormState.validate()` — 点击保存时全字段验证
- **失败聚焦**: 首个错误字段自动聚焦

---

## 6. 保存流程

```
用户点击"保存"
  → _isSaving = true (按钮显示 loading 转圈, 禁用)
  → _formKey.currentState!.validate()
      → 失败 → 聚焦首个错误字段 → _isSaving = false → 返回
      → 成功 → 构建请求数据
          → 编辑模式: treeNotifier.updateDevice(id, data)
          → 创建模式: treeNotifier.createDevice(workbenchId, name, protocolType, params, parentId)
              → 后端 API 调用 (DeviceService)
                  → 成功: Navigator.pop() + Toast.success
                  → 失败: Toast.error(后端错误消息)
          → finally: _isSaving = false
```

### 数据构建

`_buildProtocolParams()` 根据当前 `_selectedProtocol` 构建对应的参数字典：

```
Virtual → { mode, data_type, min?, max?, interval_ms? }
Modbus TCP → { host, port, slave_id?, timeout_ms? }
Modbus RTU → { serial_port, baud_rate, data_bits, stop_bits, parity, slave_id?, timeout_ms? }
```

`_buildUpdateData()` 在协议参数基础上增加通用字段（name, protocol_type, manufacturer?, model?, sn?）。

---

## 7. 响应式适配

| 断点 | 布局 |
|------|------|
| Desktop (>= 600px) | 居中 AlertDialog，560px 宽度 |
| Mobile (< 600px) | Modal BottomSheet，100% 宽，maxHeight 90vh |

判断方式：`DeviceConfigDialog.show()` 静态方法中通过 `MediaQuery.of(context).size.width < 600` 区分。

### 布局差异对比

| 元素 | Desktop | Mobile |
|------|---------|--------|
| 容器 | AlertDialog (contentPadding: 0, insetPadding) | ConstrainedBox (maxHeight: 90vh) |
| 按钮布局 | Row (TextButton 取消 → FilledButton 保存) | Column (FilledButton 保存 → TextButton 取消，全宽) |
| 按钮间距 | 12px horizontal | 8px vertical |
| 底部 padding | 16px vertical | 12px vertical |

---

## 8. 错误处理

| 场景 | 处理方式 |
|------|----------|
| 字段级验证失败 | TextField errorText + 红色下划线，失焦时触发 |
| 保存时全字段验证失败 | 聚焦首个错误字段 |
| 后端返回错误 (400/422) | Toast.error 显示后端错误消息 |
| 网络错误 (timeout/connection) | Toast.error "网络连接失败" |
| 未授权 (401) | Toast.error "登录已过期" |
| 服务不可用 (500/502/503) | Toast.error "服务暂时不可用" |

---

## 9. 测试要点

- [ ] 必填字段带 * 标记，有 Label 和 Placeholder
- [ ] 设备名称验证：空值 / 超长 / 合法值
- [ ] 协议类型必填验证
- [ ] 三种协议配置区正确切换，淡入淡出动画
- [ ] 切换协议时清空专用字段
- [ ] IPv4 格式验证（合法/非法/空）
- [ ] 端口范围验证（1-65535 / 空 / 超范围）
- [ ] 取值范围交叉验证（min < max）
- [ ] 间隔/超时验证（≥100ms）
- [ ] 保存时 loading 状态，按钮禁用
- [ ] 保存成功关闭 Dialog 并 Toast
- [ ] 保存失败显示错误信息
- [ ] 编辑模式预填值正确
- [ ] 移动端 BottomSheet 样式正确
- [ ] 高级信息 ExpansionTile 展开/折叠
- [ ] 所有控制器在 dispose 中正确释放
