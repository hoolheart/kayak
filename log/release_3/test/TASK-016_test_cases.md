# TASK-016 测试用例 — 设备树组件 UI

> **任务**: TASK-016 — 设备树组件 UI (`lib/widgets/device_tree.dart`)  
> **测试人员**: sw-mike  
> **日期**: 2026-06-01  
> **分支**: `fix/task-016-017-critical-issues`  
> **代码审查状态**: APPROVED (sw-jerry)

---

## 1. 测试范围

本测试用例覆盖 `DeviceTree` 组件的所有关键交互和视觉状态，包括：
- 空状态 / 加载状态 / 数据状态 三态渲染
- 树形结构正确展示（含层级缩进）
- 展开/折叠动画（`AnimatedRotation` + `AnimatedSize`）
- 第一层自动展开
- 节点选中态（背景 + 左边框 + 文字色）
- 上下文菜单（编辑/添加子设备/删除）
- 删除确认流程（ConfirmDialog → Toast → 刷新）
- 状态圆点颜色映射（在线/离线/错误）
- 协议图标映射（Virtual/Modbus TCP/Modbus RTU/CAN/VISA/MQTT）
- Light/Dark 主题适配

---

## 2. 测试环境

| 项目 | 版本/配置 |
|------|----------|
| Flutter | 3.19+ |
| Dart | 3.3+ |
| 目标平台 | Web (Chrome) |
| 测试框架 | `flutter_test` + `flutter_riverpod` |
| 辅助库 | 自定义 `FakeDeviceService` |

---

## 3. 测试用例详情

### TC-016-01: 空状态渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-01 |
| **优先级** | P0 |
| **场景** | 工作台下无任何设备 |

**前置条件**:
- `FakeDeviceService.listByWorkbench('wb-test')` 返回空列表 `[]`

**测试步骤**:
1. 渲染 `DeviceTree(workbenchId: 'wb-test')`
2. 等待 provider 加载完成
3. 观察面板内容

**预期结果**:
- 面板头部显示 "Devices" + 数量标签 `0`
- 树内容区域显示 `EmptyView`（compact 模式）
- EmptyView 包含图标 `Icons.device_hub_outlined`
- EmptyView 标题为 "No devices yet"（英文）
- 不显示骨架屏

---

### TC-016-02: 加载状态渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-02 |
| **优先级** | P0 |
| **场景** | 数据加载中 |

**前置条件**:
- `FakeDeviceService.listByWorkbench('wb-test')` 返回延迟的 Future（模拟加载中）

**测试步骤**:
1. 渲染 `DeviceTree(workbenchId: 'wb-test')`
2. 在 Future 完成前 pump widget
3. 观察面板内容

**预期结果**:
- 面板头部显示 "Devices" + 数量标签 `0`
- 树内容区域显示骨架屏（`_buildTreeSkeleton`）
- 骨架屏包含 5 个占位项
- 每个占位项包含：圆形图标占位 + 圆形状态点占位 + 名称长条占位
- 奇偶行缩进不同（模拟层级）

---

### TC-016-03: 设备树渲染（单层，无子设备）

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-03 |
| **优先级** | P0 |
| **场景** | 有设备，无子设备 |

**前置条件**:
- 提供 3 个根节点设备，状态分别为 online / offline / error
- 协议类型分别为 virtual / modbusTcp / modbusRtu

**测试步骤**:
1. 渲染 `DeviceTree` 并加载数据
2. 等待 `pumpAndSettle`
3. 检查每个节点的渲染内容

**预期结果**:
- 3 个节点均正确渲染
- 每个节点包含：协议图标 + 状态圆点 + 设备名称
- 无子设备的节点不显示展开图标（显示 `SizedBox(width: 20)`）
- 节点高度为 40px
- 名称文字为 `bodyMedium` 样式，单行省略

---

### TC-016-04: 设备树渲染（多层嵌套）

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-04 |
| **优先级** | P0 |
| **场景** | 有父子层级关系 |

**前置条件**:
- 提供 1 个根节点，含 2 个子设备
- 子设备 1 含 1 个孙设备

**测试步骤**:
1. 渲染 `DeviceTree` 并加载数据
2. 等待 `pumpAndSettle`
3. 检查层级缩进

**预期结果**:
- 根节点无缩进（left padding = 16px）
- 子节点缩进 24px（left padding = 40px）
- 孙节点缩进 48px（left padding = 64px）
- 有子设备的节点显示展开图标 `chevron_right`

---

### TC-016-05: 第一层自动展开

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-05 |
| **优先级** | P0 |
| **场景** | 数据加载完成后第一层自动展开 |

**前置条件**:
- 提供 2 个根节点，每个根节点含 2 个子设备

**测试步骤**:
1. 渲染 `DeviceTree`
2. 等待数据加载完成并 settle
3. 检查子节点是否可见

**预期结果**:
- 数据加载后，2 个根节点均自动展开
- 所有子节点（4 个）在树中可见
- 展开图标已旋转 90°（`turns: 0.25`）
- 孙节点（如有）保持折叠

---

### TC-016-06: 点击展开/折叠子节点

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-06 |
| **优先级** | P0 |
| **场景** | 用户点击展开图标切换子节点显隐 |

**前置条件**:
- 提供 1 个根节点，含 2 个子设备
- 数据已加载（第一层已自动展开）

**测试步骤**:
1. 渲染 `DeviceTree` 并等待加载
2. 点击根节点的展开图标
3. 等待动画完成（pump + 200ms + pumpAndSettle）
4. 检查子节点是否隐藏
5. 再次点击展开图标
6. 等待动画完成

**预期结果**:
- 第一次点击后，子节点从树中消失
- 展开图标旋转回 0°
- `AnimatedSize` 高度动画过渡（200ms easeInOut）
- 第二次点击后，子节点重新出现
- 展开图标旋转至 90°

---

### TC-016-07: 双击节点展开/折叠

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-07 |
| **优先级** | P1 |
| **场景** | 用户双击节点行展开/折叠 |

**前置条件**:
- 同 TC-016-06

**测试步骤**:
1. 渲染 `DeviceTree` 并等待加载
2. 双击根节点行（非展开图标区域）
3. 检查子节点显隐

**预期结果**:
- 双击后子节点折叠/展开状态切换
- 展开图标同步旋转

---

### TC-016-08: 节点选中态样式

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-08 |
| **优先级** | P0 |
| **场景** | 用户点击节点选中 |

**前置条件**:
- 提供 2 个根节点设备

**测试步骤**:
1. 渲染 `DeviceTree` 并传入 `selectedDeviceId: 'dev-1'`
2. 等待加载
3. 检查选中态样式
4. 点击第二个节点
5. 检查回调是否触发

**预期结果**:
- `dev-1` 节点具有选中样式：
  - 背景色为 `colorScheme.primary.withAlpha(20)`（约 8% 透明度）
  - 左侧 3px `colorScheme.primary` 边框
  - 名称文字颜色为 `colorScheme.primary`
- `dev-2` 节点无选中样式（透明背景，无边框，默认文字色）
- 点击 `dev-2` 时 `onDeviceSelected` 回调被调用，参数为 `'dev-2'`
- 选中节点显示上下文菜单按钮（`more_vert` 图标）
- 未选中节点不显示上下文菜单按钮

---

### TC-016-09: 上下文菜单按钮存在

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-09 |
| **优先级** | P0 |
| **场景** | 选中节点显示上下文菜单 |

**前置条件**:
- 提供 1 个根节点设备
- 节点处于选中状态

**测试步骤**:
1. 渲染 `DeviceTree(selectedDeviceId: 'dev-1')`
2. 等待加载
3. 点击 `more_vert` 图标打开菜单
4. 检查菜单项

**预期结果**:
- 选中节点右侧显示 `more_vert` 图标（32x32）
- 点击后弹出 `PopupMenuButton` 菜单
- 菜单包含 3 项：
  1. "Edit Device"（`edit_outlined` 图标）
  2. "Add Sub-Device"（`add_circle_outline` 图标）
  3. "Delete Device"（`delete_outlined` 图标 + Error 色文字）
- 第 1、2 项与第 3 项之间有分隔线

---

### TC-016-10: 删除流程 — 确认并删除

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-10 |
| **优先级** | P0 |
| **场景** | 用户删除设备 |

**前置条件**:
- 提供 1 个根节点设备 `dev-1`
- `FakeDeviceService.delete('dev-1')` 可正常返回

**测试步骤**:
1. 渲染 `DeviceTree` 并选中 `dev-1`
2. 点击 `more_vert` → 点击 "Delete Device"
3. 等待 ConfirmDialog 弹出
4. 检查对话框内容
5. 点击 "Confirm Delete"
6. 等待删除完成

**预期结果**:
- ConfirmDialog 显示标题 "Delete Device?"
- 描述包含设备名称 `"dev-1-name"`
- 确认按钮为危险样式（Error 色）
- 点击确认后：
  - `FakeDeviceService.delete()` 被调用，参数为 `'dev-1'`
  - Toast 显示 "Device deleted successfully"
  - 设备树自动刷新

---

### TC-016-11: 删除流程 — 取消删除

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-11 |
| **优先级** | P1 |
| **场景** | 用户取消删除 |

**前置条件**:
- 同 TC-016-10

**测试步骤**:
1. 打开删除确认对话框
2. 点击 "Cancel"

**预期结果**:
- 对话框关闭
- `FakeDeviceService.delete()` 未被调用
- 设备树不刷新

---

### TC-016-12: 状态圆点 — 在线（绿色）

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-12 |
| **优先级** | P0 |
| **场景** | Light/Dark 主题下在线状态颜色 |

**前置条件**:
- 设备状态为 `online`

**测试步骤**:
1. 分别在 Light 和 Dark 主题下渲染树
2. 检查状态圆点颜色

**预期结果**:
- Light 主题：圆点颜色为 `#2E7D32`
- Dark 主题：圆点颜色为 `#81C784`
- 圆点尺寸为 8x8，圆形
- 有 1px 白色（Light）/ Surface（Dark）边框

---

### TC-016-13: 状态圆点 — 离线（灰色）

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-13 |
| **优先级** | P0 |
| **场景** | 离线状态颜色 |

**预期结果**:
- Light/Dark 主题下均为 `colorScheme.onSurfaceVariant`

---

### TC-016-14: 状态圆点 — 错误（红色）

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-14 |
| **优先级** | P0 |
| **场景** | 错误状态颜色 |

**预期结果**:
- Light 主题：圆点颜色为 `#BA1A1A`
- Dark 主题：圆点颜色为 `#FFB4AB`

---

### TC-016-15: 协议图标映射

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-15 |
| **优先级** | P0 |
| **场景** | 各协议类型显示正确图标 |

**测试步骤**:
1. 创建设备，协议类型分别为：virtual / modbusTcp / modbusRtu / can / visa / mqtt
2. 检查每个节点的协议图标

**预期结果**:
| 协议类型 | 图标 |
|---------|------|
| virtual | `Icons.memory` |
| modbusTcp | `Icons.lan` |
| modbusRtu | `Icons.cable` |
| can | `Icons.cable` |
| visa | `Icons.usb` |
| mqtt | `Icons.hub` |

---

### TC-016-16: 面板头部 — 数量标签

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-16 |
| **优先级** | P1 |
| **场景** | 头部正确显示设备数量 |

**测试步骤**:
1. 渲染空状态树 → 数量应为 0
2. 渲染有 3 个设备的树 → 数量应为 3

**预期结果**:
- 数量标签显示为圆角小标签（`surfaceContainerHighest` 背景）
- 数字与标题 "Devices" 间距 8px

---

### TC-016-17: 面板头部 — 添加设备按钮

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-17 |
| **优先级** | P1 |
| **场景** | 点击 + 按钮触发添加对话框 |

**测试步骤**:
1. 渲染 `DeviceTree`
2. 点击头部 `+` 按钮

**预期结果**:
- `DeviceConfigDialog.show()` 被调用
- 按钮颜色为 `colorScheme.primary`
- 按钮尺寸 32x32，图标 20px

---

### TC-016-18: 错误状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-18 |
| **优先级** | P1 |
| **场景** | 数据加载失败 |

**前置条件**:
- `FakeDeviceService.listByWorkbench()` 抛出异常

**测试步骤**:
1. 渲染 `DeviceTree`
2. 等待加载完成

**预期结果**:
- 显示 `ErrorView` 组件
- 包含 "Retry" 按钮
- 点击 Retry 按钮重新加载数据

---

### TC-016-19: 动画参数验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-19 |
| **优先级** | P1 |
| **场景** | 展开/折叠动画时长和曲线 |

**测试步骤**:
1. 展开节点
2. 验证 `AnimatedRotation` 参数
3. 验证 `AnimatedSize` 参数

**预期结果**:
- `AnimatedRotation.duration` = 150ms
- `AnimatedRotation.turns` = 0.25（展开）/ 0.0（折叠）
- `AnimatedSize.duration` = 200ms
- `AnimatedSize.curve` = `Curves.easeInOut`
- `AnimatedSize.alignment` = `Alignment.topCenter`

---

### TC-016-20: Light/Dark 主题适配

| 属性 | 内容 |
|------|------|
| **ID** | TC-016-20 |
| **优先级** | P1 |
| **场景** | 主题切换后颜色正确 |

**测试步骤**:
1. 在 Light 主题下渲染选中节点
2. 在 Dark 主题下渲染选中节点
3. 对比状态圆点边框颜色

**预期结果**:
- Light 主题：状态圆点边框为 `Colors.white`
- Dark 主题：状态圆点边框为 `colorScheme.surface`
- 选中背景均为 `colorScheme.primary.withAlpha(20)`

---

## 4. 测试数据

### 设备数据模板

```dart
// 根节点 1 — Virtual, online
Device(
  id: 'dev-1',
  workbenchId: 'wb-test',
  parentId: null,
  name: 'Virtual Sensor',
  protocolType: ProtocolType.virtual,
  status: 'online',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
)

// 根节点 2 — Modbus TCP, offline
Device(
  id: 'dev-2',
  workbenchId: 'wb-test',
  parentId: null,
  name: 'PLC Controller',
  protocolType: ProtocolType.modbusTcp,
  status: 'offline',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
)

// 子节点 — Modbus RTU, error
Device(
  id: 'dev-2-1',
  workbenchId: 'wb-test',
  parentId: 'dev-2',
  name: 'RTU Sub-device',
  protocolType: ProtocolType.modbusRtu,
  status: 'error',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
)
```

---

## 5. 风险与注意事项

1. **Provider 覆盖**: `deviceTreeProvider` 为 `family` provider，测试中需通过覆盖 `deviceServiceProvider` 间接控制其行为。
2. **Dialog 测试**: `ConfirmDialog` 和 `DeviceConfigDialog` 使用 `showDialog`，测试中需使用 `pumpAndSettle` 等待动画完成。
3. **Toast 测试**: `Toast.show` 依赖 `Toast.init` 上下文，测试中需在 widget 树顶层注入 `Toast.init`。
4. **动画时间**: `AnimatedSize` 200ms + `AnimatedRotation` 150ms，测试中需适当 pump 时长。
5. **静态方法**: `DeviceConfigDialog.show` 为静态方法，测试中难以直接 mock，主要验证按钮存在和点击不崩溃。

---

**文档结束**
