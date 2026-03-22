# S1-015: 工作台详情页面框架 - 测试用例文档

**任务ID**: S1-015  
**任务名称**: 工作台详情页面框架 (Workbench Detail Page Framework)  
**文档版本**: 1.0  
**创建日期**: 2026-03-22  
**测试类型**: Widget测试、集成测试、Golden测试、可访问性测试  

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S1-015 任务的所有功能测试，包括：
1. **页面导航** - 从工作台列表点击进入详情页
2. **基本信息展示** - 工作台名称、描述、创建日期
3. **Tab导航** - 设备列表、设置Tab切换
4. **Tab内容** - 各Tab内容正确显示
5. **加载状态** - 获取详情时的加载指示
6. **错误处理** - 工作台不存在或API失败
7. **返回导航** - 返回工作台列表
8. **响应式布局** - 不同窗口尺寸适配

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 点击工作台进入详情页 | TC-S1-015-01 ~ TC-S1-015-05 | Widget/Integration |
| 2. Tab导航可用 | TC-S1-015-10 ~ TC-S1-015-16 | Widget/Integration |
| 3. 显示工作台基本信息 | TC-S1-015-20 ~ TC-S1-015-25 | Widget |

### 1.3 测试环境要求

| 环境项 | 说明 |
|--------|------|
| **Flutter SDK** | 3.16+ (stable channel) |
| **状态管理** | Riverpod |
| **UI框架** | Material Design 3 |
| **后端API** | S1-014 已实现的工作台详情API |
| **依赖任务** | S1-014 (工作台管理页面) |

### 1.4 测试用例统计

| 类别 | 用例数量 | 优先级分布 |
|------|---------|-----------|
| 页面导航测试 | 8 | P0: 5, P1: 2, P2: 1 |
| Tab导航测试 | 10 | P0: 6, P1: 3, P2: 1 |
| 基本信息展示测试 | 8 | P0: 5, P1: 2, P2: 1 |
| 加载/错误状态测试 | 8 | P0: 5, P1: 2, P2: 1 |
| 返回导航测试 | 4 | P0: 2, P1: 1, P2: 1 |
| 响应式布局测试 | 5 | P0: 3, P1: 1, P2: 1 |
| 可访问性测试 | 5 | P0: 3, P1: 1, P2: 1 |
| **总计** | **48** | P0: 29, P1: 12, P2: 7 |

---

## 2. 页面导航测试 (TC-S1-015-01 ~ TC-S1-015-08)

### 2.1 从列表页导航到详情页

#### TC-S1-015-01: 点击工作台卡片进入详情页测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-01 |
| **测试名称** | 点击工作台卡片进入详情页测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表页面已加载<br>2. 存在至少一个工作台 |
| **测试步骤** | 1. 点击工作台卡片<br>2. 等待路由跳转完成 |
| **预期结果** | 1. 路由跳转到详情页<br>2. URL包含工作台ID<br>3. 显示该工作台的详情内容 |
| **自动化代码** | `await tester.tap(find.byType(WorkbenchCard).first);`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/workbench/1'));`<br>`expect(find.byType(WorkbenchDetailPage), findsOneWidget);` |

---

#### TC-S1-015-02: 点击工作台列表项进入详情页测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-02 |
| **测试名称** | 点击工作台列表项进入详情页测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表页面以列表视图显示 |
| **测试步骤** | 1. 点击工作台列表项<br>2. 等待路由跳转完成 |
| **预期结果** | 1. 路由跳转到详情页<br>2. 显示正确工作台详情 |
| **自动化代码** | `await tester.tap(find.byType(WorkbenchListTile).first);`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/workbench/1'));` |

---

#### TC-S1-015-03: 详情页URL包含工作台ID测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-03 |
| **测试名称** | 详情页URL包含工作台ID测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 存在ID为"test-id-123"的工作台 |
| **测试步骤** | 1. 点击该工作台进入详情页 |
| **预期结果** | 1. URL格式为 `/workbench/test-id-123`<br>2. 页面正确加载该工作台数据 |
| **自动化代码** | `await tester.tap(find.text('Test Workbench'));`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/workbench/test-id-123'));` |

---

#### TC-S1-015-04: 直接访问详情页URL测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-04 |
| **测试名称** | 直接访问详情页URL测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 用户已登录 |
| **测试步骤** | 1. 直接导航到 `/workbench/1`<br>2. 等待页面加载 |
| **预期结果** | 1. 正确显示工作台详情页<br>2. 加载对应ID的工作台数据 |
| **自动化代码** | `await tester.pumpWidget`<br>`(ProviderScope(child: TestApp(path: '/workbench/1')));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(WorkbenchDetailPage), findsOneWidget);` |

---

#### TC-S1-015-05: 详情页正确初始化Provider测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-05 |
| **测试名称** | 详情页正确初始化Provider测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页组件已创建 |
| **测试步骤** | 1. 导航到详情页<br>2. 检查Provider状态 |
| **预期结果** | 1. workbenchDetailProvider被正确初始化<br>2. 发起API请求获取详情 |
| **自动化代码** | `verify(mockService.getWorkbench('1')).called(1);` |

---

#### TC-S1-015-06: 详情页加载时显示加载指示器测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-06 |
| **测试名称** | 详情页加载时显示加载指示器测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台详情API请求进行中 |
| **测试步骤** | 1. 导航到详情页<br>2. 在数据返回前检查UI |
| **预期结果** | 1. 显示CircularProgressIndicator<br>2. 不显示页面主体内容 |
| **自动化代码** | `await tester.pump();`<br>`expect(find.byType(CircularProgressIndicator), findsOneWidget);`<br>`expect(find.text('Workbench Name'), findsNothing);` |

---

#### TC-S1-015-07: 列表页点击后详情页数据匹配测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-07 |
| **测试名称** | 列表页点击后详情页数据匹配测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台列表包含多个工作台 |
| **测试步骤** | 1. 点击任意工作台进入详情页<br>2. 检查详情页显示的工作台信息与列表一致 |
| **预期结果** | 1. 详情页工作台名称与点击的列表项一致<br>2. 详情页工作台描述与点击的列表项一致 |
| **自动化代码** | `await tester.tap(find.text('Workbench 2'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('Workbench 2'), findsOneWidget);`<br>`expect(find.text('Description 2'), findsOneWidget);` |

---

#### TC-S1-015-08: 列表刷新后点击导航正常测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-08 |
| **测试名称** | 列表刷新后点击导航正常测试 |
| **测试类型** | Integration Test |
| **优先级** | P2 |
| **前置条件** | 1. 工作台列表已显示 |
| **测试步骤** | 1. 执行下拉刷新<br>2. 刷新完成后点击工作台 |
| **预期结果** | 1. 刷新成功<br>2. 导航到详情页正常 |
| **自动化代码** | `await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);`<br>`await tester.pumpAndSettle();`<br>`await tester.tap(find.byType(WorkbenchCard).first);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(WorkbenchDetailPage), findsOneWidget);` |

---

## 3. Tab导航测试 (TC-S1-015-10 ~ TC-S1-015-19)

### 3.1 Tab组件基础功能

#### TC-S1-015-10: Tab组件正确渲染测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-10 |
| **测试名称** | Tab组件正确渲染测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 检查Tab组件 |
| **预期结果** | 1. 显示"设备列表"Tab<br>2. 显示"设置"Tab<br>3. Tab有正确的图标和文字 |
| **自动化代码** | `expect(find.text('设备列表'), findsOneWidget);`<br>`expect(find.text('设置'), findsOneWidget);`<br>`expect(find.byIcon(Icons.devices), findsOneWidget);`<br>`expect(find.byIcon(Icons.settings), findsOneWidget);` |

---

#### TC-S1-015-11: 默认显示设备列表Tab测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-11 |
| **测试名称** | 默认显示设备列表Tab测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 检查默认Tab状态 |
| **预期结果** | 1. "设备列表"Tab被选中<br>2. 设备列表内容可见 |
| **自动化代码** | `expect(find.byIcon(Icons.devices), findsOneWidget);`<br>`// 检查设备列表内容区域可见`<br>`expect(find.byType(DeviceListContent), findsOneWidget);` |

---

#### TC-S1-015-12: Tab切换到设置测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-12 |
| **测试名称** | Tab切换到设置测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 点击"设置"Tab |
| **预期结果** | 1. "设置"Tab被选中<br>2. 设置内容显示<br>3. 设备列表内容隐藏 |
| **自动化代码** | `await tester.tap(find.text('设置'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(SettingsContent), findsOneWidget);`<br>`expect(find.byType(DeviceListContent), findsNothing);` |

---

#### TC-S1-015-13: Tab切换回设备列表测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-13 |
| **测试名称** | Tab切换回设备列表测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 当前在设置Tab |
| **测试步骤** | 1. 点击"设备列表"Tab |
| **预期结果** | 1. "设备列表"Tab被选中<br>2. 设备列表内容显示<br>3. 设置内容隐藏 |
| **自动化代码** | `await tester.tap(find.text('设备列表'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(DeviceListContent), findsOneWidget);` |

---

#### TC-S1-015-14: Tab切换动画测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-14 |
| **测试名称** | Tab切换动画测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 点击"设置"Tab<br>2. 立即检查动画状态 |
| **预期结果** | 1. Tab切换有过渡动画<br>2. 动画流畅无卡顿 |
| **自动化代码** | `await tester.tap(find.text('设置'));`<br>`await tester.pump();`<br>`// 动画进行中`<br>`await tester.pump(Duration(milliseconds: 150));`<br>`// 动画完成`<br>`await tester.pumpAndSettle();` |

---

#### TC-S1-015-15: Tab状态保持测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-15 |
| **测试名称** | Tab状态保持测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 切换到设置Tab |
| **测试步骤** | 1. 切换到设置Tab<br>2. 离开详情页<br>3. 返回详情页 |
| **预期结果** | 1. 仍显示设置Tab内容<br>2. Tab状态被保持 |
| **自动化代码** | `await tester.tap(find.text('设置'));`<br>`await tester.pumpAndSettle();`<br>`await tester.pageBack();`<br>`await tester.pumpAndSettle();`<br>`await tester.pageBack(); // 返回详情页`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(SettingsContent), findsOneWidget);` |

---

#### TC-S1-015-16: Tab指示器显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-16 |
| **测试名称** | Tab指示器显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 检查Tab指示器 |
| **预期结果** | 1. 当前Tab下方有指示器<br>2. 指示器颜色符合主题 |
| **自动化代码** | `expect(find.byType(TabIndicator), findsOneWidget);` |

---

### 3.2 设备列表Tab内容

#### TC-S1-015-17: 设备列表Tab空状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-17 |
| **测试名称** | 设备列表Tab空状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台无关联设备 |
| **测试步骤** | 1. 切换到设备列表Tab<br>2. 检查空状态 |
| **预期结果** | 1. 显示"暂无设备"提示<br>2. 显示空状态插图<br>3. 显示"添加设备"引导按钮(预留扩展点) |
| **自动化代码** | `expect(find.text('暂无设备'), findsOneWidget);`<br>`expect(find.text('添加设备'), findsOneWidget);` |

---

#### TC-S1-015-18: 设备列表Tab加载状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-18 |
| **测试名称** | 设备列表Tab加载状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 设备列表API请求进行中 |
| **测试步骤** | 1. 切换到设备列表Tab<br>2. 检查加载状态 |
| **预期结果** | 1. 显示加载指示器 |
| **自动化代码** | `expect(find.byType(CircularProgressIndicator), findsOneWidget);` |

---

### 3.3 设置Tab内容

#### TC-S1-015-19: 设置Tab占位符内容显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-19 |
| **测试名称** | 设置Tab占位符内容显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 切换到设置Tab<br>2. 检查设置内容 |
| **预期结果** | 1. 显示"设置"Tab内容区域<br>2. 显示基本信息展示（如工作台名称、状态等只读信息）<br>3. 显示"功能开发中"或占位符提示（编辑功能为后续扩展） |
| **自动化代码** | `expect(find.byType(SettingsContent), findsOneWidget);`<br>`expect(find.textContaining('设置'), findsWidgets);`<br>`// Settings Tab为框架预留，编辑功能在S1-015范围外`<br>`expect(find.text('功能开发中').finders.any || find.byType(PlaceholderContent).finders.any, isTrue);` |

---

## 4. 基本信息展示测试 (TC-S1-015-20 ~ TC-S1-015-27)

### 4.1 信息展示

#### TC-S1-015-20: 工作台名称显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-20 |
| **测试名称** | 工作台名称显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台详情已加载 |
| **测试步骤** | 1. 检查页面标题区域 |
| **预期结果** | 1. 显示工作台名称<br>2. 名称格式正确 |
| **自动化代码** | `expect(find.text('My Workbench'), findsOneWidget);` |

---

#### TC-S1-015-21: 工作台描述显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-21 |
| **测试名称** | 工作台描述显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台详情已加载<br>2. 工作台有描述 |
| **测试步骤** | 1. 检查描述显示区域 |
| **预期结果** | 1. 显示工作台描述<br>2. 描述内容完整 |
| **自动化代码** | `expect(find.text('This is my workbench description'), findsOneWidget);` |

---

#### TC-S1-015-22: 工作台创建日期显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-22 |
| **测试名称** | 工作台创建日期显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台详情已加载 |
| **测试步骤** | 1. 检查创建日期显示 |
| **预期结果** | 1. 显示创建日期<br>2. 格式符合本地化要求(如: 2026-03-22) |
| **自动化代码** | `expect(find.textContaining('2026'), findsOneWidget);` |

---

#### TC-S1-015-23: 工作台状态显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-23 |
| **测试名称** | 工作台状态显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台详情已加载 |
| **测试步骤** | 1. 检查状态显示区域 |
| **预期结果** | 1. 显示工作台状态<br>2. 状态标签颜色符合状态含义(激活=绿色, 归档=灰色等) |
| **自动化代码** | `expect(find.text('激活'), findsOneWidget);`<br>`expect(find.widgetWithText(Chip, '激活'), findsOneWidget);` |

---

#### TC-S1-015-24: 无描述时显示空提示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-24 |
| **测试名称** | 无描述时显示空提示测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台描述为null或空 |
| **测试步骤** | 1. 检查描述显示区域 |
| **预期结果** | 1. 显示"暂无描述"或留空<br>2. 无异常显示 |
| **自动化代码** | `expect(find.text('暂无描述'), findsOneWidget);` |

---

#### TC-S1-015-25: 基本信息区域布局测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-25 |
| **测试名称** | 基本信息区域布局测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台详情已加载 |
| **测试步骤** | 1. 检查基本信息区域布局 |
| **预期结果** | 1. 信息排列整齐<br>2. 标签与数值对齐<br>3. 响应式适配良好 |
| **自动化代码** | `expect(find.byType(BasicInfoSection), findsOneWidget);` |

---

#### TC-S1-015-26: 长名称截断显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-26 |
| **测试名称** | 长名称截断显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 工作台名称超过显示区域宽度 |
| **测试步骤** | 1. 检查长名称显示 |
| **预期结果** | 1. 名称正确截断显示省略号<br>2. tooltip显示完整名称 |
| **自动化代码** | `expect(find.byType(Tooltip), findsWidgets);` |

---

#### TC-S1-015-27: 创建者信息显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-27 |
| **测试名称** | 创建者信息显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 工作台详情已加载 |
| **测试步骤** | 1. 检查创建者信息 |
| **预期结果** | 1. 显示创建者名称或头像<br>2. 或显示"团队/个人"标识 |
| **自动化代码** | `// 根据实际实现验证` |

---

## 5. 加载/错误状态测试 (TC-S1-015-30 ~ TC-S1-015-37)

### 5.1 加载状态

#### TC-S1-015-30: 详情页初始加载状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-30 |
| **测试名称** | 详情页初始加载状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. API请求进行中 |
| **测试步骤** | 1. 导航到详情页 |
| **预期结果** | 1. 显示加载指示器<br>2. 不显示错误信息 |
| **自动化代码** | `await tester.pump();`<br>`expect(find.byType(CircularProgressIndicator), findsOneWidget);` |

---

#### TC-S1-015-31: 详情页加载完成显示内容测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-31 |
| **测试名称** | 详情页加载完成显示内容测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. API请求已完成 |
| **测试步骤** | 1. 等待加载完成 |
| **预期结果** | 1. 隐藏加载指示器<br>2. 显示工作台详情内容 |
| **自动化代码** | `await tester.pumpAndSettle();`<br>`expect(find.byType(CircularProgressIndicator), findsNothing);`<br>`expect(find.text(workbench.name), findsOneWidget);` |

---

### 5.2 错误状态

#### TC-S1-015-32: 工作台不存在错误测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-32 |
| **测试名称** | 工作台不存在错误测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. API返回404错误 |
| **测试步骤** | 1. 导航到不存在的工作台详情页 |
| **预期结果** | 1. 显示错误提示"工作台不存在"<br>2. 显示返回按钮 |
| **自动化代码** | `when(mockService.getWorkbench('non-existent'))`<br>`  .thenThrow(NotFoundException('Workbench not found'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('工作台不存在'), findsOneWidget);`<br>`expect(find.text('返回'), findsOneWidget);` |

---

#### TC-S1-015-33: 网络错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-33 |
| **测试名称** | 网络错误处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 网络请求失败 |
| **测试步骤** | 1. 导航到详情页<br>2. 检查错误处理 |
| **预期结果** | 1. 显示错误提示"网络连接失败"<br>2. 显示"重试"按钮 |
| **自动化代码** | `when(mockService.getWorkbench('1'))`<br>`  .thenThrow(NetworkException());`<br>`expect(find.text('网络连接失败，请检查网络后重试'), findsOneWidget);`<br>`expect(find.text('重试'), findsOneWidget);` |

---

#### TC-S1-015-34: 服务器错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-34 |
| **测试名称** | 服务器错误处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. API返回500错误 |
| **测试步骤** | 1. 导航到详情页<br>2. 检查错误处理 |
| **预期结果** | 1. 显示错误提示"服务器错误"<br>2. 显示"重试"按钮 |
| **自动化代码** | `when(mockService.getWorkbench('1'))`<br>`  .thenThrow(ServerException(500));`<br>`expect(find.text('服务器错误，请稍后重试'), findsOneWidget);` |

---

#### TC-S1-015-35: 401未授权错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-35 |
| **测试名称** | 401未授权错误处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. Token过期或无效 |
| **测试步骤** | 1. 导航到详情页 |
| **预期结果** | 1. 跳转登录页<br>2. 或显示"登录已过期" |
| **自动化代码** | `when(mockService.getWorkbench('1'))`<br>`  .thenThrow(UnauthorizedException());`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/login'));` |

---

#### TC-S1-015-36: 重试按钮功能测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-36 |
| **测试名称** | 重试按钮功能测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 显示错误状态 |
| **测试步骤** | 1. 点击"重试"按钮<br>2. 检查重新加载 |
| **预期结果** | 1. 重新发起API请求<br>2. 显示加载状态<br>3. 请求成功后显示详情 |
| **自动化代码** | `await tester.tap(find.text('重试'));`<br>`await tester.pump();`<br>`verify(mockService.getWorkbench('1')).called(2);` |

---

#### TC-S1-015-37: 请求超时处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-37 |
| **测试名称** | 请求超时处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. API请求超时 |
| **测试步骤** | 1. 导航到详情页<br>2. 等待超时 |
| **预期结果** | 1. 显示"请求超时"提示<br>2. 显示"重试"按钮 |
| **自动化代码** | `when(mockService.getWorkbench('1'))`<br>`  .thenThrow(TimeoutException());`<br>`expect(find.text('请求超时，请重试'), findsOneWidget);` |

---

## 6. 返回导航测试 (TC-S1-015-40 ~ TC-S1-015-43)

#### TC-S1-015-40: 返回按钮导航测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-40 |
| **测试名称** | 返回按钮导航测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 点击返回按钮<br>2. 检查路由 |
| **预期结果** | 1. 返回到工作台列表页<br>2. URL不包含工作台ID |
| **自动化代码** | `await tester.tap(find.byType(BackButton));`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/workbenches'));` |

---

#### TC-S1-015-41: 详情页返回后列表保持状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-41 |
| **测试名称** | 详情页返回后列表保持状态测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载并滚动 |
| **测试步骤** | 1. 进入详情页<br>2. 返回列表页 |
| **预期结果** | 1. 列表滚动位置保持<br>2. 列表数据保持 |
| **自动化代码** | `// 滚动到中间位置`<br>`await tester.scrollUntilVisible(find.text('Workbench 10'), 100);`<br>`await tester.tap(find.byType(WorkbenchCard).first);`<br>`await tester.pumpAndSettle();`<br>`await tester.pageBack();`<br>`await tester.pumpAndSettle();`<br>`// 验证滚动位置保持` |

---

#### TC-S1-015-42: Android返回键导航测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-42 |
| **测试名称** | Android返回键导航测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 按系统返回键 |
| **预期结果** | 1. 返回到列表页 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.back);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(WorkbenchListPage), findsOneWidget);` |

---

#### TC-S1-015-43: 面包屑导航测试(如有)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-43 |
| **测试名称** | 面包屑导航测试 |
| **测试类型** | Integration Test |
| **优先级** | P2 |
| **前置条件** | 1. 详情页显示面包屑导航 |
| **测试步骤** | 1. 点击面包屑中的"工作台列表" |
| **预期结果** | 1. 返回到工作台列表页 |
| **自动化代码** | `await tester.tap(find.text('工作台列表'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(WorkbenchListPage), findsOneWidget);` |

---

## 7. 响应式布局测试 (TC-S1-015-50 ~ TC-S1-015-54)

#### TC-S1-015-50: 大屏桌面布局测试 (1920x1080)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-50 |
| **测试名称** | 大屏桌面布局测试 (1920x1080) |
| **测试类型** | Golden Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 设置视口为1920x1080<br>2. 检查布局 |
| **预期结果** | 1. 基本信息区域宽度充足<br>2. Tab显示在一行<br>3. 无水平滚动条 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1920, 1080);`<br>`tester.binding.window.devicePixelRatioTestValue = 1.0;`<br>`await tester.pumpAndSettle();`<br>`await expectLater(find.byType(WorkbenchDetailPage), matchesGoldenFile('detail_1920x1080.png'));` |

---

#### TC-S1-015-51: 中等屏幕布局测试 (1366x768)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-51 |
| **测试名称** | 中等屏幕布局测试 (1366x768) |
| **测试类型** | Golden Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 设置视口为1366x768<br>2. 检查布局 |
| **预期结果** | 1. 布局正常调整<br>2. 内容无错位 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1366, 768);`<br>`await expectLater(find.byType(WorkbenchDetailPage), matchesGoldenFile('detail_1366x768.png'));` |

---

#### TC-S1-015-52: 小屏桌面布局测试 (1024x768)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-52 |
| **测试名称** | 小屏桌面布局测试 (1024x768) |
| **测试类型** | Golden Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 设置视口为1024x768<br>2. 检查布局 |
| **预期结果** | 1. Tab可能换行显示<br>2. 内容区域自适应 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1024, 768);`<br>`await expectLater(find.byType(WorkbenchDetailPage), matchesGoldenFile('detail_1024x768.png'));` |

---

#### TC-S1-015-53: 窗口大小调整适配测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-53 |
| **测试名称** | 窗口大小调整适配测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 从大窗口切换到小窗口<br>2. 检查布局调整 |
| **预期结果** | 1. 布局自动调整<br>2. 无布局错乱 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1920, 1080);`<br>`await tester.pumpAndSettle();`<br>`tester.binding.window.physicalSizeTestValue = Size(1024, 768);`<br>`await tester.pumpAndSettle();` |

---

#### TC-S1-015-54: 最小窗口宽度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-54 |
| **测试名称** | 最小窗口宽度测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 设置极小窗口宽度(如320px) |
| **预期结果** | 1. 显示水平滚动条<br>2. 或有最小宽度限制<br>3. 核心功能保持可用 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(320, 568);`<br>`await tester.pumpAndSettle();` |

---

## 8. 可访问性测试 (TC-S1-015-60 ~ TC-S1-015-64)

#### TC-S1-015-60: 屏幕阅读器标题测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-60 |
| **测试名称** | 屏幕阅读器标题测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 检查页面标题语义 |
| **预期结果** | 1. 页面标题为"工作台详情 - [工作台名称]"<br>2. 所有交互元素有描述性标签 |
| **自动化代码** | `expect(tester.semantics.getOrCreateLabel(find.byType(AppBar)), contains('工作台详情'));` |

---

#### TC-S1-015-61: Tab键盘导航测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-61 |
| **测试名称** | Tab键盘导航测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 使用Tab键导航 |
| **预期结果** | 1. Tab顺序正确<br>2. 所有Tab可聚焦 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`expect(focusedWidget, isNotNull);` |

---

#### TC-S1-015-62: 返回按钮键盘操作测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-62 |
| **测试名称** | 返回按钮键盘操作测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 聚焦返回按钮<br>2. 按Enter键 |
| **预期结果** | 1. 返回功能正常执行 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`await tester.sendKeyEvent(LogicalKeyboardKey.enter);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(WorkbenchListPage), findsOneWidget);` |

---

#### TC-S1-015-63: 颜色对比度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-63 |
| **测试名称** | 颜色对比度测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 检查文本与背景对比度 |
| **预期结果** | 1. 所有文本对比度 >= 4.5:1 (WCAG AA)<br>2. 大文本对比度 >= 3:1 |
| **自动化代码** | `final result = await tester.checkContrast();`<br>`expect(result.violations, isEmpty);` |

---

#### TC-S1-015-64: Tab焦点指示器可见性测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-015-64 |
| **测试名称** | Tab焦点指示器可见性测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P2 |
| **前置条件** | 1. 详情页已加载 |
| **测试步骤** | 1. 使用Tab键聚焦Tab |
| **预期结果** | 1. 焦点指示器清晰可见<br>2. 符合无障碍要求 |
| **自动化代码** | `await tester.tap(find.byType(Tab).first);`<br>`await tester.pump();` |

---

## 9. Widget测试示例代码

### 9.1 完整测试文件示例

```dart
// test/widget/workbench/workbench_detail_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';
import 'package:kayak_frontend/features/workbench/models/workbench.dart';
import 'package:kayak_frontend/features/workbench/providers/workbench_detail_provider.dart';
import 'package:kayak_frontend/features/workbench/screens/workbench_detail_page.dart';
import 'package:kayak_frontend/features/workbench/services/workbench_service.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkbenchService extends Mock implements WorkbenchServiceInterface {}

void main() {
  group('WorkbenchDetailPage', () {
    late MockWorkbenchService mockService;
    late Workbench testWorkbench;

    setUp(() {
      mockService = MockWorkbenchService();
      testWorkbench = Workbench(
        id: '1',
        name: 'Test Workbench',
        description: 'Test Description',
        ownerId: 'user-1',
        ownerType: 'user',
        status: 'active',
        createdAt: DateTime(2026, 3, 22),
        updatedAt: DateTime(2026, 3, 22),
      );
    });

    // TC-S1-015-01: 点击工作台卡片进入详情页测试
    testWidgets('navigates to detail page on card tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchServiceProvider.overrideWithValue(mockService),
          ],
          child: const TestApp(path: '/workbench/1'),
        ),
      );

      when(() => mockService.getWorkbench('1'))
          .thenAnswer((_) async => testWorkbench);

      await tester.pumpAndSettle();

      expect(find.text('Test Workbench'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    // TC-S1-015-10: Tab组件正确渲染测试
    testWidgets('displays correct tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchServiceProvider.overrideWithValue(mockService),
          ],
          child: const TestApp(path: '/workbench/1'),
        ),
      );

      when(() => mockService.getWorkbench('1'))
          .thenAnswer((_) async => testWorkbench);

      await tester.pumpAndSettle();

      expect(find.text('设备列表'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    // TC-S1-015-12: Tab切换到设置测试
    testWidgets('switches to settings tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchServiceProvider.overrideWithValue(mockService),
          ],
          child: const TestApp(path: '/workbench/1'),
        ),
      );

      when(() => mockService.getWorkbench('1'))
          .thenAnswer((_) async => testWorkbench);

      await tester.pumpAndSettle();

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsContent), findsOneWidget);
    });

    // TC-S1-015-30: 详情页初始加载状态测试
    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      when(() => mockService.getWorkbench('1'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testWorkbench;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchServiceProvider.overrideWithValue(mockService),
          ],
          child: const TestApp(path: '/workbench/1'),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // TC-S1-015-32: 工作台不存在错误测试
    testWidgets('shows error when workbench not found', (WidgetTester tester) async {
      when(() => mockService.getWorkbench('non-existent'))
          .thenThrow(NotFoundException('Workbench not found'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchServiceProvider.overrideWithValue(mockService),
          ],
          child: const TestApp(path: '/workbench/non-existent'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('工作台不存在'), findsOneWidget);
      expect(find.text('返回'), findsOneWidget);
    });

    // TC-S1-015-40: 返回按钮导航测试
    testWidgets('navigates back on back button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchServiceProvider.overrideWithValue(mockService),
          ],
          child: const TestApp(path: '/workbench/1'),
        ),
      );

      when(() => mockService.getWorkbench('1'))
          .thenAnswer((_) async => testWorkbench);

      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(WorkbenchListPage), findsOneWidget);
    });
  });
}
```

### 9.2 集成测试示例

```dart
// test/integration/workbench_detail_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';
import 'package:kayak_frontend/features/workbench/screens/workbench_list_page.dart';
import 'package:kayak_frontend/features/workbench/screens/workbench_detail_page.dart';

void main() {
  group('Workbench Detail Flow', () {
    testWidgets('complete navigation flow from list to detail', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TestApp(
            initialPath: '/workbenches',
          ),
        ),
      );

      // 等待列表页加载
      await tester.pumpAndSettle();

      // 验证列表页显示
      expect(find.byType(WorkbenchListPage), findsOneWidget);

      // 点击工作台卡片 (需要mock数据)
      await tester.tap(find.byType(WorkbenchCard).first);
      await tester.pumpAndSettle();

      // 验证详情页显示
      expect(find.byType(WorkbenchDetailPage), findsOneWidget);

      // 验证Tab显示
      expect(find.text('设备列表'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      // 切换Tab
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 验证设置Tab内容
      expect(find.byType(SettingsContent), findsOneWidget);

      // 返回列表
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 验证返回列表页
      expect(find.byType(WorkbenchListPage), findsOneWidget);
    });
  });
}
```

---

## 10. 测试覆盖矩阵

| 验收标准 | TC覆盖 | 测试类型 |
|---------|--------|---------|
| 点击工作台进入详情页 | TC-S1-015-01 ~ TC-S1-015-08 | Widget/Integration |
| Tab导航可用 | TC-S1-015-10 ~ TC-S1-015-19 | Widget/Integration |
| 显示工作台基本信息 | TC-S1-015-20 ~ TC-S1-015-27 | Widget |

---

## 11. 备注

1. **扩展点预留**: 设备列表Tab的内容测试为预留测试点，实际设备管理功能将在后续S1-016实现后补充
2. **设置Tab**: 当前仅包含基本工作台信息编辑，后续可根据需要扩展更多设置选项
3. **API依赖**: 测试依赖S1-014实现的`getWorkbench(id)` API
4. **路由**: 详情页路由建议为 `/workbench/:id`
