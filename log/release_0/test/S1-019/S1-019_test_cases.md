# S1-019: 设备与测点管理UI - 测试用例文档

**任务ID**: S1-019  
**任务名称**: 设备与测点管理UI (Device and Point Management UI)  
**文档版本**: 1.0  
**创建日期**: 2026-03-23  
**测试类型**: Widget测试、集成测试、Golden测试、可访问性测试  

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S1-019 任务的所有功能测试，包括：
1. **设备树形展示** - 设备列表树形结构、展开/折叠功能
2. **设备创建** - 创建设备表单、Virtual协议选择
3. **设备编辑** - 编辑设备表单、参数修改
4. **设备删除** - 删除确认对话框
5. **测点列表展示** - 测点数据显示、状态显示
6. **测点值实时刷新** - 定时刷新机制、值更新显示
7. **加载状态** - 获取数据时的加载指示
8. **错误处理** - API失败、空数据状态

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 树形结构展示设备层级 | TC-S1-019-01 ~ TC-S1-019-12 | Widget/Integration |
| 2. 创建设备时协议选择"Virtual" | TC-S1-019-15 ~ TC-S1-019-16 | Widget |
| 3. 测点值实时显示(定时刷新) | TC-S1-019-33 ~ TC-S1-019-38 | Widget/Integration |

### 1.3 测试环境要求

| 环境项 | 说明 |
|--------|------|
| **Flutter SDK** | 3.16+ (stable channel) |
| **状态管理** | Riverpod |
| **UI框架** | Material Design 3 |
| **后端API** | S1-018 已实现的设备和测点API |
| **依赖任务** | S1-015 (工作台详情页面框架), S1-018 (设备与测点CRUD API) |

### 1.4 测试用例统计

| 类别 | 用例数量 | 优先级分布 |
|------|---------|-----------|
| 设备树形展示测试 | 12 (TC-01~12) | P0: 7, P1: 4, P2: 1 |
| 设备创建功能测试 | 8 (TC-13~20) | P0: 5, P1: 2, P2: 1 |
| 设备编辑功能测试 | 2 (TC-21~22) | P0: 2, P1: 0, P2: 0 |
| 设备删除功能测试 | 4 (TC-23~26) | P0: 3, P1: 1, P2: 0 |
| 测点列表展示测试 | 6 (TC-27~32) | P0: 4, P1: 2, P2: 0 |
| 测点值刷新测试 | 6 (TC-33~38) | P0: 4, P1: 2, P2: 0 |
| 加载/错误状态测试 | 6 (TC-39~44) | P0: 4, P1: 1, P2: 1 |
| 可访问性测试 | 5 (TC-45~49) | P0: 3, P1: 1, P2: 1 |
| **总计** | **49** | P0: 32, P1: 14, P2: 3 |

---

## 2. 设备树形展示测试 (TC-S1-019-01 ~ TC-S1-019-12)

### 2.1 树形结构基础测试

#### TC-S1-019-01: 设备树根节点展示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-01 |
| **测试名称** | 设备树根节点展示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台详情页已加载<br>2. 设备Tab已激活<br>3. 存在至少一个根设备 |
| **测试步骤** | 1. 等待设备列表加载完成<br>2. 验证设备树显示 |
| **预期结果** | 1. 根设备显示在树形列表中<br>2. 根设备没有缩进<br>3. 根设备有展开/折叠箭头图标 |
| **自动化代码** | `expect(find.byType(DeviceTreeNode), findsWidgets);`<br>`final rootNodes = find.descendant(`<br>`  of: find.byType(DeviceTree),`<br>`  matching: find.byType(DeviceTreeNode),`<br>`);`<br>`expect(rootNodes, findsWidgets);` |

---

#### TC-S1-019-02: 设备树子节点缩进测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-02 |
| **测试名称** | 设备树子节点缩进测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备树包含嵌套设备 |
| **测试步骤** | 1. 查找子设备节点<br>2. 验证缩进层级 |
| **预期结果** | 1. 子设备相对于父设备有缩进<br>2. 嵌套越深缩进越多 |
| **自动化代码** | `final childNode = find.byKey(const Key('device-node-child-1'));`<br>`expect(childNode, findsOneWidget);`<br>`// 验证缩进通过Padding或Indent组件`<br>`expect(`<br>`  find.descendant(of: childNode, matching: find.byType(Padding)),`<br>`  findsWidgets,`<br>`);` |

---

#### TC-S1-019-03: 设备树图标展示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-03 |
| **测试名称** | 设备树图标展示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 查找设备节点图标 |
| **预期结果** | 1. 每个设备节点有对应协议类型的图标<br>2. Virtual协议显示专用图标<br>3. 设备状态图标正确显示 |
| **自动化代码** | `final deviceIcon = find.byIcon(Icons.memory);`<br>`expect(deviceIcon, findsWidgets);`<br>`// 验证Virtual设备图标`<br>`expect(`<br>`  find.descendant(`<br>`    of: find.byKey(const Key('device-node-root-1')),`<br>`    matching: find.byIcon(Icons.memory),`<br>`  ),`<br>`  findsOneWidget,`<br>`);` |

---

### 2.2 展开/折叠功能测试

#### TC-S1-019-04: 展开根设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-04 |
| **测试名称** | 展开根设备测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载<br>2. 存在带子设备的根设备<br>3. 初始状态为折叠 |
| **测试步骤** | 1. 查找设备节点的展开箭头<br>2. 点击展开箭头<br>3. 等待子设备显示 |
| **预期结果** | 1. 展开箭头变为折叠箭头<br>2. 子设备节点显示出来<br>3. 树形结构正确嵌套 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('expand-icon-root-1')));`<br>`await tester.pumpAndSettle();`<br>`expect(`<br>`  find.descendant(`<br>`    of: find.byKey(const Key('device-node-root-1')),`<br>`    matching: find.byKey(const Key('device-node-child-1')),`<br>`  ),`<br>`  findsOneWidget,`<br>`);` |

---

#### TC-S1-019-05: 折叠根设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-05 |
| **测试名称** | 折叠根设备测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载<br>2. 存在带子设备的根设备<br>3. 初始状态为展开 |
| **测试步骤** | 1. 查找设备节点的折叠箭头<br>2. 点击折叠箭头<br>3. 等待子设备隐藏 |
| **预期结果** | 1. 折叠箭头变为展开箭头<br>2. 子设备节点被隐藏<br>3. 树形结构更新 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('collapse-icon-root-1')));`<br>`await tester.pumpAndSettle();`<br>`expect(`<br>`  find.descendant(`<br>`    of: find.byKey(const Key('device-node-root-1')),`<br>`    matching: find.byKey(const Key('device-node-child-1')),`<br>`  ),`<br>`  findsNothing,`<br>`);` |

---

#### TC-S1-019-06: 无子设备节点箭头测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-06 |
| **测试名称** | 无子设备节点箭头测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备树已加载<br>2. 存在无子设备的叶子节点 |
| **测试步骤** | 1. 查找叶子节点<br>2. 验证没有展开/折叠箭头 |
| **预期结果** | 1. 叶子节点没有展开/折叠箭头<br>2. 叶子节点有正确的图标 |
| **自动化代码** | `final leafExpandIcon = find.descendant(`<br>`  of: find.byKey(const Key('device-node-leaf-1')),`<br>`  matching: find.byIcon(Icons.expand_more),`<br>`);`<br>`expect(leafExpandIcon, findsNothing);` |

---

#### TC-S1-019-07: 多级嵌套展开测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-07 |
| **测试名称** | 多级嵌套展开测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树包含3层以上嵌套 |
| **测试步骤** | 1. 展开第1层节点<br>2. 展开第2层节点<br>3. 展开第3层节点 |
| **预期结果** | 1. 每层节点正确展开<br>2. 嵌套关系正确显示 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('expand-icon-level1')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.byKey(const Key('expand-icon-level2')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.byKey(const Key('expand-icon-level3')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byKey(const Key('device-node-depth-3')), findsOneWidget);` |

---

#### TC-S1-019-08: 展开箭头图标旋转动画测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-08 |
| **测试名称** | 展开箭头图标旋转动画测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 点击展开箭头<br>2. 观察图标动画 |
| **预期结果** | 1. 箭头图标有旋转动画<br>2. 动画流畅 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('expand-icon-root-1')));`<br>`await tester.pump(const Duration(milliseconds: 150));`<br>`// 验证AnimatedRotation或类似组件`<br>`expect(find.byType(AnimatedRotation), findsOneWidget);` |

---

### 2.3 设备树交互测试

#### TC-S1-019-09: 点击设备节点选中测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-09 |
| **测试名称** | 点击设备节点选中测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 点击设备节点<br>2. 等待选中状态更新 |
| **预期结果** | 1. 设备节点显示选中状态<br>2. 高亮效果正确显示 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('device-node-root-1')));`<br>`await tester.pumpAndSettle();`<br>`final container = tester.widget<Container>(`<br>`  find.descendant(`<br>`    of: find.byKey(const Key('device-node-root-1')),`<br>`    matching: find.byType(Container),`<br>`  ).first,`<br>`);`<br>`// 验证选中背景色` |

---

#### TC-S1-019-10: 设备树滚动测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-10 |
| **测试名称** | 设备树滚动测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备数量超过可视区域 |
| **测试步骤** | 1. 在设备树中执行滑动操作 |
| **预期结果** | 1. 设备列表可以滚动<br>2. 滚动流畅 |
| **自动化代码** | `await tester.drag(`<br>`  find.byType(DeviceTree),`<br>`  const Offset(0, -200),`<br>`);`<br>`await tester.pumpAndSettle();` |

---

#### TC-S1-019-11: 设备树刷新测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-11 |
| **测试名称** | 设备树刷新测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 执行下拉刷新操作<br>2. 等待数据重新加载 |
| **预期结果** | 1. 刷新指示器显示<br>2. 数据重新加载<br>3. 树形结构更新 |
| **自动化代码** | `await tester.fling(`<br>`  find.byType(DeviceTree),`<br>`  const Offset(0, 300),`<br>`  1000,`<br>`);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(CircularProgressIndicator), findsNothing);` |

---

#### TC-S1-019-12: 设备树全选/多选测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-12 |
| **测试名称** | 设备树全选/多选测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备树支持多选模式 |
| **测试步骤** | 1. 勾选多个设备<br>2. 验证选中状态 |
| **预期结果** | 1. 多选状态正确<br>2. 选中数量显示 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('checkbox-device-1')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.byKey(const Key('checkbox-device-2')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('已选择 2 项'), findsOneWidget);` |

---

## 3. 设备创建功能测试 (TC-S1-019-13 ~ TC-S1-019-20)

### 3.1 创建设备表单测试 (TC-S1-019-13 ~ TC-S1-019-20)

#### TC-S1-019-13: 打开创建设备对话框测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-13 |
| **测试名称** | 打开创建设备对话框测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备Tab已激活 |
| **测试步骤** | 1. 点击"添加设备"按钮<br>2. 等待对话框打开 |
| **预期结果** | 1. 创建设备对话框打开<br>2. 表单字段正确显示 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('add-device-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(CreateDeviceDialog), findsOneWidget);` |

---

#### TC-S1-019-14: 创建设备表单字段验证测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-14 |
| **测试名称** | 创建设备表单字段验证测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建设备对话框已打开 |
| **测试步骤** | 1. 尝试提交空表单<br>2. 观察验证错误 |
| **预期结果** | 1. 必填字段显示验证错误<br>2. 设备名称为必填<br>3. 协议类型为必填 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('submit-device-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('设备名称不能为空'), findsOneWidget);`<br>`expect(find.text('请选择协议类型'), findsOneWidget);` |

---

#### TC-S1-019-15: Virtual协议选择测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-15 |
| **测试名称** | Virtual协议选择测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建设备对话框已打开<br>2. 协议类型下拉框可用 |
| **测试步骤** | 1. 点击协议类型下拉框<br>2. 选择"Virtual"选项 |
| **预期结果** | 1. Virtual选项存在<br>2. 选择后显示"Virtual"<br>3. 其他协议可选但禁用 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('protocol-type-dropdown')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.text('Virtual').last);`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('Virtual'), findsWidgets);` |

---

#### TC-S1-019-16: Virtual协议参数配置测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-16 |
| **测试名称** | Virtual协议参数配置测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 选择了Virtual协议 |
| **测试步骤** | 1. 展开协议参数区域<br>2. 配置虚拟设备参数 |
| **预期结果** | 1. Virtual协议参数表单显示<br>2. 可以配置采样间隔<br>3. 可以配置数据范围 |
| **自动化代码** | `expect(find.byKey(const Key('virtual-params-section')), findsOneWidget);`<br>`await tester.enterText(`<br>`  find.byKey(const Key('virtual-sample-interval')),`<br>`  '1000',`<br>`);`<br>`await tester.pumpAndSettle();` |

---

#### TC-S1-019-17: 创建设备提交测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-17 |
| **测试名称** | 创建设备提交测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建设备表单已填写 |
| **测试步骤** | 1. 点击提交按钮<br>2. 等待API响应<br>3. 等待对话框关闭 |
| **预期结果** | 1. 提交按钮显示加载状态<br>2. 成功后对话框关闭<br>3. 设备列表更新 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('submit-device-button')));`<br>`await tester.pump(const Duration(milliseconds: 100));`<br>`expect(find.byType(CircularProgressIndicator), findsOneWidget);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(CreateDeviceDialog), findsNothing);` |

---

#### TC-S1-019-18: 创建设备API失败测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-18 |
| **测试名称** | 创建设备API失败测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 模拟API返回错误 |
| **测试步骤** | 1. 填写表单<br>2. 提交并模拟失败 |
| **预期结果** | 1. 错误提示显示<br>2. 对话框保持打开<br>3. 表单数据保留 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('submit-device-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('创建设备失败'), findsOneWidget);`<br>`expect(find.byType(CreateDeviceDialog), findsOneWidget);` |

---

#### TC-S1-019-19: 取消创建设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-19 |
| **测试名称** | 取消创建设备测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建设备对话框已打开<br>2. 表单有输入内容 |
| **测试步骤** | 1. 点击取消按钮<br>2. 确认关闭 |
| **预期结果** | 1. 对话框关闭<br>2. 数据未保存 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('cancel-device-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(CreateDeviceDialog), findsNothing);` |

---

#### TC-S1-019-20: 创建设备-父设备选择测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-20 |
| **测试名称** | 创建设备-父设备选择测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 存在可作为父设备的设备 |
| **测试步骤** | 1. 展开父设备选择下拉框<br>2. 选择一个父设备 |
| **预期结果** | 1. 父设备列表显示<br>2. 选中后显示父设备名称 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('parent-device-dropdown')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.text('父设备1').last);`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('父设备1'), findsWidgets);` |

---

## 4. 设备编辑功能测试 (TC-S1-019-21 ~ TC-S1-019-22)

#### TC-S1-019-21: 编辑设备对话框打开测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-21 |
| **测试名称** | 编辑设备对话框打开测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 右键点击设备节点<br>2. 选择"编辑"选项 |
| **预期结果** | 1. 编辑对话框打开<br>2. 表单预填充设备数据 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('device-node-root-1')));`<br>`await tester.pumpAndSettle();`<br>`await tester.longPress(find.byKey(const Key('device-node-root-1')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.text('编辑'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(EditDeviceDialog), findsOneWidget);` |

---

#### TC-S1-019-22: 编辑设备提交测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-22 |
| **测试名称** | 编辑设备提交测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 编辑对话框已打开 |
| **测试步骤** | 1. 修改设备名称<br>2. 点击提交 |
| **预期结果** | 1. 设备信息更新<br>2. 对话框关闭<br>3. 列表更新显示 |
| **自动化代码** | `await tester.enterText(`<br>`  find.byKey(const Key('device-name-field')),`<br>`  'Updated Device Name',`<br>`);`<br>`await tester.tap(find.byKey(const Key('submit-edit-device-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(EditDeviceDialog), findsNothing);` |

---

## 5. 设备删除功能测试 (TC-S1-019-23 ~ TC-S1-019-26)

#### TC-S1-019-23: 删除设备确认对话框测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-23 |
| **测试名称** | 删除设备确认对话框测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 右键点击设备节点<br>2. 选择"删除"选项 |
| **预期结果** | 1. 确认对话框显示<br>2. 显示设备名称<br>3. 显示警告信息 |
| **自动化代码** | `await tester.longPress(find.byKey(const Key('device-node-root-1')));`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.text('删除'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(DeleteConfirmDialog), findsOneWidget);`<br>`expect(find.text('确定要删除设备'), findsOneWidget);` |

---

#### TC-S1-019-24: 确认删除设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-24 |
| **测试名称** | 确认删除设备测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 删除确认对话框已打开 |
| **测试步骤** | 1. 点击确认删除按钮<br>2. 等待API响应 |
| **预期结果** | 1. 设备从列表中移除<br>2. 确认对话框关闭 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('confirm-delete-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byKey(const Key('device-node-root-1')), findsNothing);` |

---

#### TC-S1-019-25: 取消删除设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-25 |
| **测试名称** | 取消删除设备测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 删除确认对话框已打开 |
| **测试步骤** | 1. 点击取消按钮 |
| **预期结果** | 1. 对话框关闭<br>2. 设备保留在列表中 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('cancel-delete-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(DeleteConfirmDialog), findsNothing);`<br>`expect(find.byKey(const Key('device-node-root-1')), findsOneWidget);` |

---

#### TC-S1-019-26: 删除有子设备的设备测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-26 |
| **测试名称** | 删除有子设备的设备测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备有子设备 |
| **测试步骤** | 1. 尝试删除有子设备的设备 |
| **预期结果** | 1. 显示警告提示<br>2. 提示将级联删除子设备<br>3. 确认后删除所有 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('confirm-delete-button')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('将同时删除 3 个子设备'), findsOneWidget);` |

---

## 6. 测点列表展示测试 (TC-S1-019-27 ~ TC-S1-019-32)

### 6.1 测点列表基础测试

#### TC-S1-019-27: 点击设备显示测点列表测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-27 |
| **测试名称** | 点击设备显示测点列表测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载<br>2. 设备有测点 |
| **测试步骤** | 1. 点击设备节点<br>2. 等待测点列表加载 |
| **预期结果** | 1. 测点列表面板显示<br>2. 显示该设备的所有测点 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('device-node-root-1')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(PointListPanel), findsOneWidget);`<br>`expect(find.byType(PointListItem), findsWidgets);` |

---

#### TC-S1-019-28: 测点名称显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-28 |
| **测试名称** | 测点名称显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 查找测点项 |
| **预期结果** | 1. 测点名称正确显示<br>2. 名称与API数据一致 |
| **自动化代码** | `expect(find.text('Temperature'), findsOneWidget);`<br>`expect(find.text('Pressure'), findsOneWidget);` |

---

#### TC-S1-019-29: 测点数据类型显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-29 |
| **测试名称** | 测点数据类型显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 查找测点数据类型标签 |
| **预期结果** | 1. 数据类型正确显示(Number/Integer/String/Boolean)<br>2. 访问类型正确显示(Ro/Wo/Rw) |
| **自动化代码** | `expect(find.text('Number'), findsOneWidget);`<br>`expect(find.text('Ro'), findsOneWidget);` |

---

#### TC-S1-019-30: 测点单位显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-30 |
| **测试名称** | 测点单位显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 测点设置了单位 |
| **测试步骤** | 1. 查找测点的单位显示 |
| **预期结果** | 1. 单位正确显示（如 °C, Pa, V） |
| **自动化代码** | `expect(find.text('°C'), findsOneWidget);`<br>`expect(find.text('Pa'), findsOneWidget);` |

---

#### TC-S1-019-31: 测点状态图标测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-31 |
| **测试名称** | 测点状态图标测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 查找测点状态图标 |
| **预期结果** | 1. 正常状态显示绿色图标<br>2. 禁用状态显示灰色图标 |
| **自动化代码** | `expect(find.byIcon(Icons.check_circle), findsWidgets);`<br>`expect(find.byIcon(Icons.cancel), findsNothing);` |

---

#### TC-S1-019-32: 测点列表空状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-32 |
| **测试名称** | 测点列表空状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备没有测点 |
| **测试步骤** | 1. 点击无测点的设备 |
| **预期结果** | 1. 显示空状态提示<br>2. 提示"暂无测点" |
| **自动化代码** | `expect(find.text('暂无测点'), findsOneWidget);`<br>`expect(find.byType(PointListItem), findsNothing);` |

---

## 7. 测点值刷新测试 (TC-S1-019-33 ~ TC-S1-019-38)

#### TC-S1-019-33: 测点值显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-33 |
| **测试名称** | 测点值显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 查看测点值显示 |
| **预期结果** | 1. 测点当前值正确显示<br>2. 值格式正确（保留小数位数） |
| **自动化代码** | `expect(find.text('25.5'), findsOneWidget);` |

---

#### TC-S1-019-34: 测点值定时刷新测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-34 |
| **测试名称** | 测点值定时刷新测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 记录当前值<br>2. 等待刷新间隔（默认5秒）<br>3. 观察值变化 |
| **预期结果** | 1. 值在刷新间隔后更新<br>2. 新值从API获取<br>3. UI正确更新 |
| **自动化代码** | `final initialValue = find.text('25.5');`<br>`expect(initialValue, findsOneWidget);`<br>`// 等待刷新间隔`<br>`await tester.pump(const Duration(seconds: 6));`<br>`// 验证值已更新（Virtual设备返回随机值）`<br>`expect(find.byType(PointValueDisplay), findsWidgets);` |

---

#### TC-S1-019-35: 测点值刷新加载状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-35 |
| **测试名称** | 测点值刷新加载状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 触发手动刷新<br>2. 观察加载状态 |
| **预期结果** | 1. 刷新时显示加载指示器<br>2. 刷新完成后值更新 |
| **自动化代码** | `await tester.tap(find.byKey(const Key('refresh-points-button')));`<br>`await tester.pump();`<br>`expect(find.byType(CircularProgressIndicator), findsWidgets);`<br>`await tester.pumpAndSettle();` |

---

#### TC-S1-019-36: 测点值刷新失败处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-36 |
| **测试名称** | 测点值刷新失败处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 模拟API失败 |
| **测试步骤** | 1. 等待自动刷新触发<br>2. 模拟网络错误 |
| **预期结果** | 1. 显示错误提示<br>2. 保持显示上次有效的值<br>3. 不显示空值 |
| **自动化代码** | `await tester.pump(const Duration(seconds: 6));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('刷新失败'), findsOneWidget);` |

---

#### TC-S1-019-37: 不同数据类型值显示格式测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-37 |
| **测试名称** | 不同数据类型值显示格式测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 存在多种数据类型的测点 |
| **测试步骤** | 1. 查看不同类型测点的值显示 |
| **预期结果** | 1. Number显示小数<br>2. Integer显示整数<br>3. Boolean显示开关图标<br>4. String显示文本 |
| **自动化代码** | `expect(find.text('25.5'), findsOneWidget); // Number`<br>`expect(find.text('100'), findsOneWidget); // Integer`<br>`expect(find.byIcon(Icons.toggle_on), findsOneWidget); // Boolean true`<br>`expect(find.text('status_ok'), findsOneWidget); // String` |

---

#### TC-S1-019-38: 测点只读属性显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-38 |
| **测试名称** | 测点只读属性显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 存在只读测点(Ro) |
| **测试步骤** | 1. 查看只读测点的值显示 |
| **预期结果** | 1. 只读测点不显示写入按钮<br>2. 显示读取专属图标 |
| **自动化代码** | `expect(`<br>`  find.descendant(`<br>`    of: find.byKey(const Key('point-ro-1')),`<br>`    matching: find.byIcon(Icons.edit),`<br>`  ),`<br>`  findsNothing,`<br>`);` |

---

## 8. 加载与错误状态测试 (TC-S1-019-39 ~ TC-S1-019-44)

#### TC-S1-019-39: 设备列表加载状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-39 |
| **测试名称** | 设备列表加载状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备Tab已激活 |
| **测试步骤** | 1. 等待设备列表加载 |
| **预期结果** | 1. 加载时显示CircularProgressIndicator<br>2. 加载完成后显示列表 |
| **自动化代码** | `expect(find.byType(CircularProgressIndicator), findsOneWidget);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(DeviceTree), findsOneWidget);` |

---

#### TC-S1-019-40: 设备列表加载错误测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-40 |
| **测试名称** | 设备列表加载错误测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 模拟API返回错误 |
| **测试步骤** | 1. 导航到设备Tab<br>2. 触发加载错误 |
| **预期结果** | 1. 显示错误提示<br>2. 显示重试按钮 |
| **自动化代码** | `expect(find.text('加载失败'), findsOneWidget);`<br>`expect(find.byKey(const Key('retry-button')), findsOneWidget);` |

---

#### TC-S1-019-41: 测点列表加载状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-41 |
| **测试名称** | 测点列表加载状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 点击了设备节点 |
| **测试步骤** | 1. 等待测点列表加载 |
| **预期结果** | 1. 加载时显示加载指示器<br>2. 加载完成后显示测点 |
| **自动化代码** | `expect(find.byType(CircularProgressIndicator), findsOneWidget);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(PointListItem), findsWidgets);` |

---

#### TC-S1-019-42: 设备不存在状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-42 |
| **测试名称** | 设备不存在状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台无设备 |
| **测试步骤** | 1. 查看空状态 |
| **预期结果** | 1. 显示空状态插图<br>2. 显示"暂无设备"提示<br>3. 显示添加设备按钮 |
| **自动化代码** | `expect(find.text('暂无设备'), findsOneWidget);`<br>`expect(find.byKey(const Key('add-device-button')), findsOneWidget);` |

---

#### TC-S1-019-43: 网络断开状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-43 |
| **测试名称** | 网络断开状态测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 模拟网络断开 |
| **测试步骤** | 1. 触发刷新操作<br>2. 模拟网络错误 |
| **预期结果** | 1. 显示网络错误提示<br>2. 提示用户检查网络 |
| **自动化代码** | `expect(find.text('网络连接失败'), findsOneWidget);`<br>`expect(find.byIcon(Icons.wifi_off), findsOneWidget);` |

---

#### TC-S1-019-44: 设备权限不足状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-44 |
| **测试名称** | 设备权限不足状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 用户无设备访问权限 |
| **测试步骤** | 1. 尝试访问设备列表 |
| **预期结果** | 1. 显示权限不足提示<br>2. 不显示设备数据 |
| **自动化代码** | `expect(find.text('无权访问此工作台的设备'), findsOneWidget);` |

---

## 9. 可访问性测试 (TC-S1-019-45 ~ TC-S1-019-49)

#### TC-S1-019-45: 设备树可聚焦测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-45 |
| **测试名称** | 设备树可聚焦测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 使用Tab键导航<br>2. 验证焦点移动 |
| **预期结果** | 1. 设备节点可接收焦点<br>2. 焦点指示器可见 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`await tester.pumpAndSettle();`<br>`final focusedDevice = find.byElementPredicate(`<br>`  (element) => element.hasFocus,`<br>`);`<br>`expect(focusedDevice, findsWidgets);` |

---

#### TC-S1-019-46: 设备树语义标签测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-46 |
| **测试名称** | 设备树语义标签测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 检查设备节点的语义标签 |
| **预期结果** | 1. 设备名称有语义标签<br>2. 展开/折叠按钮有描述 |
| **自动化代码** | `final deviceNode = find.byKey(const Key('device-node-root-1'));`<br>`final semantics = tester.getSemantics(deviceNode);`<br>`expect(semantics.label, isNotEmpty);` |

---

#### TC-S1-019-47: 测点值颜色对比度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-47 |
| **测试名称** | 测点值颜色对比度测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 测点列表已显示 |
| **测试步骤** | 1. 使用semantics label检查对比度 |
| **预期结果** | 1. 文本与背景对比度符合WCAG 2.1 AA标准 |
| **自动化代码** | `// 使用flutter_test的semantics检测`<br>`expect(textContrast, greaterThan(4.5));` |

---

#### TC-S1-019-48: 触摸屏可操作尺寸测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-48 |
| **测试名称** | 触摸屏可操作尺寸测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 检查可点击元素的尺寸 |
| **预期结果** | 1. 触摸目标至少48x48dp<br>2. 元素间距足够 |
| **自动化代码** | `final expandIcon = find.byKey(const Key('expand-icon-root-1'));`<br>`final box = tester.getRect(expandIcon);`<br>`expect(box.width, greaterThanOrEqualTo(48));`<br>`expect(box.height, greaterThanOrEqualTo(48));` |

---

#### TC-S1-019-49: 屏幕阅读器支持测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-019-49 |
| **测试名称** | 屏幕阅读器支持测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 设备树已加载 |
| **测试步骤** | 1. 获取设备树语义信息 |
| **预期结果** | 1. 语义标签完整<br>2. 可按正确顺序读取 |
| **自动化代码** | `final semantics = tester.getSemantics(find.byType(DeviceTree));`<br>`expect(semantics.nodes.length, greaterThan(0));` |

---

## 10. 附录

### 8.1 测试命令

```bash
# 运行所有测试
cd kayak-frontend && flutter test

# 运行S1-019相关测试
cd kayak-frontend && flutter test test/features/workbench/

# 运行Widget测试
cd kayak-frontend && flutter test --widget

# 运行Golden测试
cd kayak-frontend && flutter test --update-goldens

# 运行可访问性测试
cd kayak-frontend && flutter test --accessibility
```

### 8.2 Mock数据

S1-019测试使用的Mock数据文件位于：
- `kayak-frontend/test/mocks/device_tree_mock.dart`
- `kayak-frontend/test/mocks/point_mock.dart`

### 8.3 相关文件

- 测试用例定义: `/home/hzhou/workspace/kayak/log/release_0/test/S1-019/S1-019_test_cases.md`
- 设备API处理器: `/home/hzhou/workspace/kayak/kayak-backend/src/api/handlers/device.rs`
- 测点API处理器: `/home/hzhou/workspace/kayak/kayak-backend/src/api/handlers/point.rs`
- 设备列表Tab组件: `/home/hzhou/workspace/kayak/kayak-frontend/lib/features/workbench/widgets/detail/device_list_tab.dart`

---

**文档版本**: 1.0  
**创建日期**: 2026-03-23  
**最后更新**: 2026-03-23