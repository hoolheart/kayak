# S1-014: 工作台管理页面 - 测试用例文档

**任务ID**: S1-014  
**任务名称**: 工作台管理页面 (Workbench Management Page)  
**文档版本**: 1.0  
**创建日期**: 2026-03-22  
**测试类型**: Widget测试、集成测试、Golden测试、可访问性测试  

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S1-014 任务的所有功能测试，包括：
1. **工作台列表页面** - 卡片/列表视图切换、数据展示、空状态
2. **创建/编辑对话框** - 表单验证、数据提交、错误处理
3. **删除确认对话框** - 二次确认、取消/确认操作
4. **响应式布局** - 桌面端适配、不同窗口尺寸
5. **可访问性** - 屏幕阅读器支持、键盘导航

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 列表展示所有工作台 | TC-S1-014-01 ~ TC-S1-014-08 | Widget/Integration |
| 2. 创建/编辑表单验证完整 | TC-S1-014-20 ~ TC-S1-014-35 | Widget/Integration |
| 3. 删除操作需要二次确认 | TC-S1-014-36 ~ TC-S1-014-40 | Widget/Integration |

### 1.3 测试环境要求

| 环境项 | 说明 |
|--------|------|
| **Flutter SDK** | 3.16+ (stable channel) |
| **状态管理** | Riverpod |
| **UI框架** | Material Design 3 |
| **后端API** | S1-013 已实现的工作台CRUD API |
| **依赖任务** | S1-012 (认证状态管理), S1-013 (工作台CRUD API) |

### 1.4 测试用例统计

| 类别 | 用例数量 | 优先级分布 |
|------|---------|-----------|
| 工作台列表测试 | 15 | P0: 8, P1: 5, P2: 2 |
| 视图模式切换测试 | 5 | P0: 3, P1: 2 |
| 创建/编辑表单测试 | 20 | P0: 12, P1: 6, P2: 2 |
| 删除确认测试 | 8 | P0: 5, P1: 2, P2: 1 |
| 错误处理测试 | 8 | P0: 4, P1: 3, P2: 1 |
| 响应式布局测试 | 6 | P0: 3, P1: 2, P2: 1 |
| 可访问性测试 | 8 | P0: 4, P1: 3, P2: 1 |
| **总计** | **70** | P0: 39, P1: 23, P2: 8 |

---

## 2. 工作台列表页面测试 (TC-S1-014-01 ~ TC-S1-014-15)

### 2.1 列表展示测试

#### TC-S1-014-01: 工作台列表正常加载测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-01 |
| **测试名称** | 工作台列表正常加载测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 用户已登录<br>2. API返回包含多个工作台的数据 |
| **测试步骤** | 1. 导航到工作台列表页面<br>2. 等待数据加载完成<br>3. 检查列表展示 |
| **预期结果** | 1. 显示所有工作台卡片/列表项<br>2. 每个工作台显示名称和描述<br>3. 无错误提示 |
| **自动化代码** | 见下方代码块 |

```dart
// test/widget/workbench/workbench_list_test.dart
testWidgets('displays workbench list correctly', (WidgetTester tester) async {
  // Arrange
  final workbenches = [
    Workbench(id: '1', name: 'Workbench 1', description: 'Description 1'),
    Workbench(id: '2', name: 'Workbench 2', description: 'Description 2'),
  ];
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workbenchListProvider.overrideWith((ref) => 
          Stream.value(AsyncData(workbenches))),
      ],
      child: const TestApp(child: WorkbenchListPage()),
    ),
  );
  
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Workbench 1'), findsOneWidget);
  expect(find.text('Workbench 2'), findsOneWidget);
  expect(find.text('Description 1'), findsOneWidget);
  expect(find.text('Description 2'), findsOneWidget);
});
```

---

#### TC-S1-014-02: 工作台列表空状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-02 |
| **测试名称** | 工作台列表空状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 用户已登录<br>2. API返回空列表 |
| **测试步骤** | 1. 导航到工作台列表页面<br>2. 等待数据加载完成<br>3. 检查空状态展示 |
| **预期结果** | 1. 显示空状态插图<br>2. 显示"暂无工作台"提示文本<br>3. 显示"创建工作台"引导按钮 |
| **自动化代码** | `expect(find.text('暂无工作台'), findsOneWidget);`<br>`expect(find.byType(EmptyStateIllustration), findsOneWidget);`<br>`expect(find.text('创建工作台'), findsOneWidget);` |

---

#### TC-S1-014-03: 工作台列表加载状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-03 |
| **测试名称** | 工作台列表加载状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 用户已登录<br>2. API请求进行中 |
| **测试步骤** | 1. 导航到工作台列表页面<br>2. 在数据加载过程中检查UI |
| **预期结果** | 1. 显示加载指示器(ProgressIndicator)<br>2. 不显示空状态<br>3. 不显示错误提示 |
| **自动化代码** | `expect(find.byType(CircularProgressIndicator), findsOneWidget);`<br>`expect(find.text('暂无工作台'), findsNothing);` |

---

#### TC-S1-014-04: 工作台列表网络错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-04 |
| **测试名称** | 工作台列表网络错误处理测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 用户已登录<br>2. API请求失败(网络错误) |
| **测试步骤** | 1. 导航到工作台列表页面<br>2. 等待请求失败<br>3. 检查错误状态展示 |
| **预期结果** | 1. 显示错误提示信息<br>2. 显示"重试"按钮<br>3. 可点击重试重新加载 |
| **自动化代码** | `expect(find.text('加载失败，请重试'), findsOneWidget);`<br>`expect(find.text('重试'), findsOneWidget);` |

---

#### TC-S1-014-05: 工作台列表数据刷新测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-05 |
| **测试名称** | 工作台列表数据刷新测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台列表已加载<br>2. 有新工作台在其他端创建 |
| **测试步骤** | 1. 下拉刷新列表<br>2. 等待刷新完成<br>3. 检查新数据是否显示 |
| **预期结果** | 1. 显示刷新指示器<br>2. 刷新后显示最新数据 |
| **自动化代码** | `await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('New Workbench'), findsOneWidget);` |

---

#### TC-S1-014-06: 工作台列表分页加载测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-06 |
| **测试名称** | 工作台列表分页加载测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 用户拥有超过一页的工作台(>20个) |
| **测试步骤** | 1. 滚动到列表底部<br>2. 触发分页加载<br>3. 检查新数据追加 |
| **预期结果** | 1. 滚动到底部触发加载更多<br>2. 新数据追加到列表末尾<br>3. 无重复数据 |
| **自动化代码** | `await tester.scrollUntilVisible(find.text('Workbench 25'), 100);`<br>`expect(find.text('Workbench 25'), findsOneWidget);` |

---

#### TC-S1-014-07: 工作台列表项操作按钮测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-07 |
| **测试名称** | 工作台列表项操作按钮测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 检查每个工作台卡片/列表项<br>2. 验证操作按钮存在 |
| **预期结果** | 1. 每个工作台显示编辑按钮<br>2. 每个工作台显示删除按钮<br>3. 按钮图标正确 |
| **自动化代码** | `expect(find.byIcon(Icons.edit), findsNWidgets(2));`<br>`expect(find.byIcon(Icons.delete), findsNWidgets(2));` |

---

#### TC-S1-014-08: 工作台列表点击跳转详情测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-08 |
| **测试名称** | 工作台列表点击跳转详情测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 点击工作台卡片/列表项<br>2. 验证路由跳转 |
| **预期结果** | 1. 导航到工作台详情页<br>2. URL包含工作台ID<br>3. 详情页显示正确工作台信息 |
| **自动化代码** | `await tester.tap(find.text('Workbench 1'));`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/workbench/1'));` |

---

### 2.2 视图模式切换测试

#### TC-S1-014-09: 卡片视图模式显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-09 |
| **测试名称** | 卡片视图模式显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 切换到卡片视图<br>2. 检查布局 |
| **预期结果** | 1. 显示为网格布局(多列卡片)<br>2. 卡片包含图标、名称、描述<br>3. 卡片有悬停效果 |
| **自动化代码** | `await tester.tap(find.byIcon(Icons.grid_view));`<br>`await tester.pump();`<br>`expect(find.byType(WorkbenchCard), findsWidgets);` |

---

#### TC-S1-014-10: 列表视图模式显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-10 |
| **测试名称** | 列表视图模式显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 切换到列表视图<br>2. 检查布局 |
| **预期结果** | 1. 显示为列表布局(单列行)<br>2. 每行包含图标、名称、描述、操作按钮<br>3. 列表有分割线 |
| **自动化代码** | `await tester.tap(find.byIcon(Icons.list));`<br>`await tester.pump();`<br>`expect(find.byType(WorkbenchListTile), findsWidgets);` |

---

#### TC-S1-014-11: 视图模式切换持久化测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-11 |
| **测试名称** | 视图模式切换持久化测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 用户已选择列表视图 |
| **测试步骤** | 1. 切换到列表视图<br>2. 刷新页面<br>3. 检查视图模式 |
| **预期结果** | 1. 刷新后仍显示列表视图<br>2. 视图偏好已持久化 |
| **自动化代码** | `// 切换到列表视图`<br>`await tester.tap(find.byIcon(Icons.list));`<br>`await tester.pump();`<br>`// 刷新页面`<br>`await tester.pageBack();`<br>`await tester.pumpAndSettle();`<br>`// 验证仍是列表视图`<br>`expect(find.byType(WorkbenchListTile), findsWidgets);` |

---

#### TC-S1-014-12: 视图模式切换按钮状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-12 |
| **测试名称** | 视图模式切换按钮状态测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 点击视图切换按钮<br>2. 检查按钮状态变化 |
| **预期结果** | 1. 当前视图模式按钮为高亮/选中状态<br>2. 非当前视图模式按钮为普通状态<br>3. 切换时按钮状态正确更新 |
| **自动化代码** | `// 检查初始状态`<br>`expect(tester.widget<IconButton>(cardViewButton).isSelected, isTrue);`<br>`// 切换后检查`<br>`await tester.tap(find.byIcon(Icons.list));`<br>`expect(tester.widget<IconButton>(listViewButton).isSelected, isTrue);` |

---

#### TC-S1-014-13: 不同视图模式下操作功能一致性测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-13 |
| **测试名称** | 不同视图模式下操作功能一致性测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 在卡片视图点击编辑<br>2. 切换到列表视图点击编辑<br>3. 验证两次编辑功能一致 |
| **预期结果** | 1. 两种视图下编辑按钮都正常打开编辑对话框<br>2. 两种视图下删除按钮都正常打开确认对话框<br>3. 功能行为完全一致 |
| **自动化代码** | `// 卡片视图下点击编辑`<br>`await tester.tap(find.byIcon(Icons.grid_view));`<br>`await tester.tap(find.byIcon(Icons.edit).first);`<br>`expect(find.byType(EditWorkbenchDialog), findsOneWidget);`<br>`// 关闭并切换到列表视图`<br>`await tester.tap(find.byIcon(Icons.close));`<br>`await tester.tap(find.byIcon(Icons.list));`<br>`await tester.tap(find.byIcon(Icons.edit).first);`<br>`expect(find.byType(EditWorkbenchDialog), findsOneWidget);` |

---

## 3. 创建/编辑对话框测试 (TC-S1-014-20 ~ TC-S1-014-39)

### 3.1 创建对话框测试

#### TC-S1-014-20: 创建工作台对话框打开测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-20 |
| **测试名称** | 创建工作台对话框打开测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表页面已加载 |
| **测试步骤** | 1. 点击"创建工作台"按钮<br>2. 检查对话框显示 |
| **预期结果** | 1. 打开创建对话框<br>2. 对话框标题为"创建工作台"<br>3. 包含名称输入框<br>4. 包含描述输入框<br>5. 包含创建按钮 |
| **自动化代码** | `await tester.tap(find.text('创建工作台'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('创建工作台'), findsWidgets);`<br>`expect(find.byType(TextField), findsNWidgets(2));`<br>`expect(find.text('创建'), findsOneWidget);` |

---

#### TC-S1-014-21: 创建对话框输入验证-空名称测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-21 |
| **测试名称** | 创建对话框输入验证-空名称测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 名称输入框留空<br>2. 点击创建按钮 |
| **预期结果** | 1. 显示错误提示"工作台名称不能为空"<br>2. 不发送API请求<br>3. 对话框保持打开 |
| **自动化代码** | `await tester.tap(find.text('创建'));`<br>`await tester.pump();`<br>`expect(find.text('工作台名称不能为空'), findsOneWidget);` |

---

#### TC-S1-014-22: 创建对话框输入验证-名称长度超限测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-22 |
| **测试名称** | 创建对话框输入验证-名称长度超限测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入超过255字符的名称<br>2. 点击创建按钮 |
| **预期结果** | 1. 显示错误提示"名称长度不能超过255个字符"<br>2. 不发送API请求 |
| **自动化代码** | `await tester.enterText(nameField, 'a' * 256);`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pump();`<br>`expect(find.text('名称长度不能超过255个字符'), findsOneWidget);` |

---

#### TC-S1-014-23: 创建对话框输入验证-名称仅空白字符测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-23 |
| **测试名称** | 创建对话框输入验证-名称仅空白字符测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 名称输入框仅输入空格/制表符<br>2. 点击创建按钮 |
| **预期结果** | 1. 显示错误提示"工作台名称不能为空"<br>2. 不发送API请求 |
| **自动化代码** | `await tester.enterText(nameField, '   \t\n  ');`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pump();`<br>`expect(find.text('工作台名称不能为空'), findsOneWidget);` |

---

#### TC-S1-014-24: 创建对话框输入验证-特殊字符测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-24 |
| **测试名称** | 创建对话框输入验证-特殊字符测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入包含特殊字符的名称(如: <script>alert(1)</script>)<br>2. 点击创建按钮 |
| **预期结果** | 1. 允许创建(后端会做转义处理)<br>2. 或显示友好提示要求修改名称 |
| **自动化代码** | `await tester.enterText(nameField, '<script>alert(1)</script>');`<br>`await tester.tap(find.text('创建'));`<br>`// 验证行为符合预期` |

---

#### TC-S1-014-25: 创建对话框输入验证-描述长度超限测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-25 |
| **测试名称** | 创建对话框输入验证-描述长度超限测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 名称输入有效<br>2. 输入超过1000字符的描述<br>3. 点击创建按钮 |
| **预期结果** | 1. 显示错误提示"描述长度不能超过1000个字符"<br>2. 不发送API请求 |
| **自动化代码** | `await tester.enterText(descField, 'a' * 1001);`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pump();`<br>`expect(find.text('描述长度不能超过1000个字符'), findsOneWidget);` |

---

#### TC-S1-014-26: 创建工作台成功测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-26 |
| **测试名称** | 创建工作台成功测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开<br>2. API可正常响应 |
| **测试步骤** | 1. 输入有效名称和描述<br>2. 点击创建按钮<br>3. 等待响应 |
| **预期结果** | 1. 显示加载状态<br>2. 对话框关闭<br>3. 列表刷新显示新工作台<br>4. 显示成功提示"工作台创建成功" |
| **自动化代码** | `await tester.enterText(nameField, 'New Workbench');`<br>`await tester.enterText(descField, 'A test workbench');`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('工作台创建成功'), findsOneWidget);`<br>`expect(find.text('New Workbench'), findsOneWidget);` |

---

#### TC-S1-014-27: 创建工作台API错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-27 |
| **测试名称** | 创建工作台API错误处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开<br>2. API返回500错误 |
| **测试步骤** | 1. 输入有效数据<br>2. 点击创建<br>3. 等待API错误响应 |
| **预期结果** | 1. 对话框保持打开<br>2. 显示错误提示"创建失败，请重试"<br>3. 创建按钮恢复可用状态 |
| **自动化代码** | `when(mockApi.createWorkbench(any)).thenThrow(ApiException(500));`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('创建失败，请重试'), findsOneWidget);`<br>`expect(find.text('创建'), findsOneWidget); // 按钮仍在` |

---

#### TC-S1-014-28: 创建对话框取消操作测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-28 |
| **测试名称** | 创建对话框取消操作测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开<br>2. 已输入部分数据 |
| **测试步骤** | 1. 输入名称<br>2. 点击取消/关闭按钮 |
| **预期结果** | 1. 对话框关闭<br>2. 不发送API请求<br>3. 列表无变化 |
| **自动化代码** | `await tester.enterText(nameField, 'Partial Name');`<br>`await tester.tap(find.byIcon(Icons.close));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(CreateWorkbenchDialog), findsNothing);` |

---

#### TC-S1-014-29: 创建对话框关闭后重新打开清空测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-29 |
| **测试名称** | 创建对话框关闭后重新打开清空测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 之前打开过创建对话框并输入了数据 |
| **测试步骤** | 1. 关闭创建对话框<br>2. 重新打开创建对话框 |
| **预期结果** | 1. 输入框为空<br>2. 无之前的输入残留 |
| **自动化代码** | `// 第一次打开并输入`<br>`await tester.enterText(nameField, 'Test');`<br>`await tester.tap(find.byIcon(Icons.close));`<br>`// 重新打开`<br>`await tester.tap(find.text('创建工作台'));`<br>`expect(nameController.text, isEmpty);` |

---

### 3.2 编辑对话框测试

#### TC-S1-014-30: 编辑工作台对话框数据预填充测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-30 |
| **测试名称** | 编辑工作台对话框数据预填充测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 点击编辑按钮<br>2. 检查对话框数据 |
| **预期结果** | 1. 对话框标题为"编辑工作台"<br>2. 名称输入框预填充原名称<br>3. 描述输入框预填充原描述 |
| **自动化代码** | `await tester.tap(find.byIcon(Icons.edit).first);`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('编辑工作台'), findsOneWidget);`<br>`expect(nameController.text, equals('Workbench 1'));`<br>`expect(descController.text, equals('Description 1'));` |

---

#### TC-S1-014-31: 编辑工作台部分字段更新测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-31 |
| **测试名称** | 编辑工作台部分字段更新测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 编辑对话框已打开 |
| **测试步骤** | 1. 仅修改名称<br>2. 保持描述不变<br>3. 点击保存 |
| **预期结果** | 1. 仅名称更新<br>2. 描述保持原值 |
| **自动化代码** | `await tester.enterText(nameField, 'Updated Name');`<br>`await tester.tap(find.text('保存'));`<br>`await tester.pumpAndSettle();`<br>`verify(mockApi.updateWorkbench('1', name: 'Updated Name', description: 'Description 1'));` |

---

#### TC-S1-014-32: 编辑工作台清空描述测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-32 |
| **测试名称** | 编辑工作台清空描述测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 编辑对话框已打开<br>2. 原工作台有描述 |
| **测试步骤** | 1. 清空描述输入框<br>2. 点击保存 |
| **预期结果** | 1. 描述更新为null/空<br>2. 列表中该工作台不再显示描述 |
| **自动化代码** | `await tester.enterText(descField, '');`<br>`await tester.tap(find.text('保存'));`<br>`await tester.pumpAndSettle();`<br>`// 验证API调用中description为null` |

---

#### TC-S1-014-33: 编辑工作台同名验证测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-33 |
| **测试名称** | 编辑工作台同名验证测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 编辑对话框已打开<br>2. 存在其他同名工作台 |
| **测试步骤** | 1. 修改为与其他工作台相同的名称<br>2. 点击保存 |
| **预期结果** | 1. 允许保存(后端负责唯一性检查)<br>2. 或显示友好提示 |
| **自动化代码** | `// 根据产品需求验证行为` |

---

## 4. 删除确认对话框测试 (TC-S1-014-40 ~ TC-S1-014-47)

#### TC-S1-014-40: 删除确认对话框显示测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-40 |
| **测试名称** | 删除确认对话框显示测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 点击删除按钮 |
| **预期结果** | 1. 打开确认对话框<br>2. 显示警告图标<br>3. 显示"确定要删除此工作台吗?"<br>4. 显示"此操作不可撤销"提示<br>5. 显示"取消"和"删除"按钮 |
| **自动化代码** | `await tester.tap(find.byIcon(Icons.delete).first);`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('确定要删除此工作台吗?'), findsOneWidget);`<br>`expect(find.text('此操作不可撤销'), findsOneWidget);`<br>`expect(find.text('取消'), findsOneWidget);`<br>`expect(find.text('删除'), findsOneWidget);` |

---

#### TC-S1-014-41: 删除确认对话框取消操作测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-41 |
| **测试名称** | 删除确认对话框取消操作测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 删除确认对话框已打开 |
| **测试步骤** | 1. 点击"取消"按钮 |
| **预期结果** | 1. 对话框关闭<br>2. 不发送删除API请求<br>3. 工作台仍在列表中 |
| **自动化代码** | `await tester.tap(find.text('取消'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(DeleteConfirmDialog), findsNothing);`<br>`expect(find.text('Workbench 1'), findsOneWidget);` |

---

#### TC-S1-014-42: 删除确认对话框确认删除测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-42 |
| **测试名称** | 删除确认对话框确认删除测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 删除确认对话框已打开<br>2. API可正常响应 |
| **测试步骤** | 1. 点击"删除"按钮<br>2. 等待API响应 |
| **预期结果** | 1. 显示加载状态<br>2. 对话框关闭<br>3. 工作台从列表中移除<br>4. 显示成功提示"工作台已删除" |
| **自动化代码** | `await tester.tap(find.text('删除'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('Workbench 1'), findsNothing);`<br>`expect(find.text('工作台已删除'), findsOneWidget);` |

---

#### TC-S1-014-43: 删除工作台API错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-43 |
| **测试名称** | 删除工作台API错误处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 删除确认对话框已打开<br>2. API返回500错误 |
| **测试步骤** | 1. 点击"删除"按钮<br>2. 等待API错误 |
| **预期结果** | 1. 对话框关闭<br>2. 显示错误提示"删除失败，请重试"<br>3. 工作台仍在列表中 |
| **自动化代码** | `when(mockApi.deleteWorkbench('1')).thenThrow(ApiException(500));`<br>`await tester.tap(find.text('删除'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('Workbench 1'), findsOneWidget);`<br>`expect(find.text('删除失败，请重试'), findsOneWidget);` |

---

#### TC-S1-014-44: 删除包含设备的工作台警告测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-44 |
| **测试名称** | 删除包含设备的工作台警告测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台包含设备 |
| **测试步骤** | 1. 点击删除按钮 |
| **预期结果** | 1. 确认对话框显示额外警告"此工作台包含X个设备，将一并删除" |
| **自动化代码** | `await tester.tap(find.byIcon(Icons.delete).first);`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('此工作台包含3个设备，将一并删除'), findsOneWidget);` |

---

#### TC-S1-014-45: 删除最后一个工作台后显示空状态测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-45 |
| **测试名称** | 删除最后一个工作台后显示空状态测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 列表中只有一个工作台 |
| **测试步骤** | 1. 删除最后一个工作台 |
| **预期结果** | 1. 工作台删除成功<br>2. 列表显示空状态 |
| **自动化代码** | `await tester.tap(find.byIcon(Icons.delete).first);`<br>`await tester.tap(find.text('删除'));`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('暂无工作台'), findsOneWidget);` |

---

## 5. 表单验证详细测试 (TC-S1-014-50 ~ TC-S1-014-59)

#### TC-S1-014-50: 表单实时验证测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-50 |
| **测试名称** | 表单实时验证测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建/编辑对话框已打开 |
| **测试步骤** | 1. 在名称输入框输入内容后再删除<br>2. 检查验证反馈 |
| **预期结果** | 1. 失去焦点时触发验证<br>2. 显示验证错误信息<br>3. 创建/保存按钮禁用 |
| **自动化代码** | `await tester.enterText(nameField, 'Test');`<br>`await tester.enterText(nameField, '');`<br>`await tester.pump();`<br>`expect(find.text('工作台名称不能为空'), findsOneWidget);`<br>`expect(tester.widget<ElevatedButton>(saveButton).enabled, isFalse);` |

---

#### TC-S1-014-51: 表单边界值-名称最小长度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-51 |
| **测试名称** | 表单边界值-名称最小长度测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入1个字符的名称<br>2. 检查验证结果 |
| **预期结果** | 1. 验证通过<br>2. 可正常创建 |
| **自动化代码** | `await tester.enterText(nameField, 'A');`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pump();`<br>`expect(find.text('工作台名称不能为空'), findsNothing);` |

---

#### TC-S1-014-52: 表单边界值-名称最大长度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-52 |
| **测试名称** | 表单边界值-名称最大长度测试 |
| **测试类型** | Widget Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入255个字符的名称<br>2. 检查验证结果 |
| **预期结果** | 1. 验证通过<br>2. 可正常创建 |
| **自动化代码** | `await tester.enterText(nameField, 'A' * 255);`<br>`expect(find.text('名称长度不能超过255个字符'), findsNothing);` |

---

#### TC-S1-014-53: 表单边界值-描述最大长度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-53 |
| **测试名称** | 表单边界值-描述最大长度测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入1000个字符的描述<br>2. 检查验证结果 |
| **预期结果** | 1. 验证通过 |
| **自动化代码** | `await tester.enterText(descField, 'A' * 1000);`<br>`expect(find.text('描述长度不能超过1000个字符'), findsNothing);` |

---

#### TC-S1-014-54: 表单字符类型-Unicode字符测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-54 |
| **测试名称** | 表单字符类型-Unicode字符测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入包含中文、日文、Emoji的名称<br>2. 检查验证结果 |
| **预期结果** | 1. 验证通过<br>2. 可正常创建 |
| **自动化代码** | `await tester.enterText(nameField, '工作台🔬');`<br>`await tester.tap(find.text('创建'));`<br>`await tester.pump();`<br>`expect(find.text('工作台名称不能为空'), findsNothing);` |

---

#### TC-S1-014-55: 表单字符类型-HTML标签测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-55 |
| **测试名称** | 表单字符类型-HTML标签测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 输入包含HTML标签的名称<br>2. 提交表单 |
| **预期结果** | 1. 输入被正确转义<br>2. 不执行脚本<br>3. 显示原始文本 |
| **自动化代码** | `await tester.enterText(nameField, '<b>Bold</b>');`<br>`// 验证文本显示为原始字符串，而非加粗` |

---

## 6. 错误处理测试 (TC-S1-014-60 ~ TC-S1-014-67)

#### TC-S1-014-60: 网络断开错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-60 |
| **测试名称** | 网络断开错误处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. 应用处于离线状态 |
| **测试步骤** | 1. 尝试加载工作台列表<br>2. 尝试创建工作台 |
| **预期结果** | 1. 显示"网络连接失败"提示<br>2. 提供"重试"按钮<br>3. 不显示技术性错误信息 |
| **自动化代码** | `when(mockApi.getWorkbenches()).thenThrow(NetworkException());`<br>`await tester.pumpAndSettle();`<br>`expect(find.text('网络连接失败，请检查网络后重试'), findsOneWidget);` |

---

#### TC-S1-014-61: 服务器500错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-61 |
| **测试名称** | 服务器500错误处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. API返回500错误 |
| **测试步骤** | 1. 加载工作台列表 |
| **预期结果** | 1. 显示"服务器错误，请稍后重试"<br>2. 提供"重试"按钮 |
| **自动化代码** | `when(mockApi.getWorkbenches()).thenThrow(ApiException(500, 'Internal Server Error'));`<br>`expect(find.text('服务器错误，请稍后重试'), findsOneWidget);` |

---

#### TC-S1-014-62: 401未授权错误处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-62 |
| **测试名称** | 401未授权错误处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P0 |
| **前置条件** | 1. Token过期或无效 |
| **测试步骤** | 1. 加载工作台列表 |
| **预期结果** | 1. 自动跳转登录页<br>2. 或显示"登录已过期，请重新登录" |
| **自动化代码** | `when(mockApi.getWorkbenches()).thenThrow(ApiException(401));`<br>`await tester.pumpAndSettle();`<br>`expect(router.currentPath, equals('/login'));` |

---

#### TC-S1-014-63: 请求超时处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-63 |
| **测试名称** | 请求超时处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. API响应超时 |
| **测试步骤** | 1. 发送请求<br>2. 等待超时 |
| **预期结果** | 1. 显示"请求超时，请重试"<br>2. 提供"重试"按钮 |
| **自动化代码** | `when(mockApi.getWorkbenches()).thenAnswer((_) async {`<br>`  await Future.delayed(Duration(seconds: 30));`<br>`  throw TimeoutException();`<br>`});`<br>`expect(find.text('请求超时，请重试'), findsOneWidget);` |

---

#### TC-S1-014-64: 并发操作冲突处理测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-64 |
| **测试名称** | 并发操作冲突处理测试 |
| **测试类型** | Integration Test |
| **优先级** | P1 |
| **前置条件** | 1. 多用户同时编辑同一工作台 |
| **测试步骤** | 1. 用户A打开编辑对话框<br>2. 用户B在其他地方修改了工作台<br>3. 用户A保存 |
| **预期结果** | 1. 显示"数据已被修改，请刷新后重试"<br>2. 或根据业务策略处理 |
| **自动化代码** | `// 根据实际冲突处理策略编写` |

---

## 7. 响应式布局测试 (TC-S1-014-70 ~ TC-S1-014-75)

#### TC-S1-014-70: 大屏桌面布局测试 (1920x1080)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-70 |
| **测试名称** | 大屏桌面布局测试 (1920x1080) |
| **测试类型** | Golden Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 设置视口为1920x1080<br>2. 检查布局 |
| **预期结果** | 1. 卡片视图显示多列(4-5列)<br>2. 列表视图显示完整信息<br>3. 无水平滚动条 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1920, 1080);`<br>`tester.binding.window.devicePixelRatioTestValue = 1.0;`<br>`await tester.pumpAndSettle();`<br>`await expectLater(find.byType(WorkbenchListPage), matchesGoldenFile('workbench_1920x1080.png'));` |

---

#### TC-S1-014-71: 中等屏幕布局测试 (1366x768)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-71 |
| **测试名称** | 中等屏幕布局测试 (1366x768) |
| **测试类型** | Golden Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 设置视口为1366x768<br>2. 检查布局 |
| **预期结果** | 1. 卡片视图显示3列<br>2. 列表视图正常显示 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1366, 768);`<br>`await expectLater(find.byType(WorkbenchListPage), matchesGoldenFile('workbench_1366x768.png'));` |

---

#### TC-S1-014-72: 小屏桌面布局测试 (1024x768)

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-72 |
| **测试名称** | 小屏桌面布局测试 (1024x768) |
| **测试类型** | Golden Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 设置视口为1024x768<br>2. 检查布局 |
| **预期结果** | 1. 卡片视图显示2列<br>2. 列表视图正常显示<br>3. 适配小屏幕 |
| **自动化代码** | `tester.binding.window.physicalSizeTestValue = Size(1024, 768);`<br>`await expectLater(find.byType(WorkbenchListPage), matchesGoldenFile('workbench_1024x768.png'));` |

---

#### TC-S1-014-73: 窗口大小调整适配测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-73 |
| **测试名称** | 窗口大小调整适配测试 |
| **测试类型** | Widget Test |
| **优先级** | P1 |
| **前置条件** | 1. 工作台列表已加载 |
| **测试步骤** | 1. 从大窗口切换到小窗口<br>2. 检查布局调整 |
| **预期结果** | 1. 卡片列数自动调整<br>2. 无布局错乱 |
| **自动化代码** | `// 初始大屏幕`<br>`tester.binding.window.physicalSizeTestValue = Size(1920, 1080);`<br>`await tester.pumpAndSettle();`<br>`// 调整为小屏幕`<br>`tester.binding.window.physicalSizeTestValue = Size(1024, 768);`<br>`await tester.pumpAndSettle();`<br>`// 验证布局调整` |

---

#### TC-S1-014-74: 对话框响应式布局测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-74 |
| **测试名称** | 对话框响应式布局测试 |
| **测试类型** | Golden Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 在不同尺寸下检查对话框 |
| **预期结果** | 1. 大屏: 对话框居中，固定宽度<br>2. 小屏: 对话框全屏或几乎全屏 |
| **自动化代码** | `// 大屏对话框`<br>`tester.binding.window.physicalSizeTestValue = Size(1920, 1080);`<br>`await tester.pumpAndSettle();`<br>`await expectLater(find.byType(CreateWorkbenchDialog), matchesGoldenFile('dialog_large.png'));`<br>`// 小屏对话框`<br>`tester.binding.window.physicalSizeTestValue = Size(800, 600);`<br>`await expectLater(find.byType(CreateWorkbenchDialog), matchesGoldenFile('dialog_small.png'));` |

---

#### TC-S1-014-75: 侧边栏折叠状态布局测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-75 |
| **测试名称** | 侧边栏折叠状态布局测试 |
| **测试类型** | Widget Test |
| **优先级** | P2 |
| **前置条件** | 1. 工作台列表已加载<br>2. 侧边栏可折叠 |
| **测试步骤** | 1. 折叠侧边栏<br>2. 检查内容区域扩展 |
| **预期结果** | 1. 内容区域扩展填充可用空间<br>2. 卡片列数相应增加 |
| **自动化代码** | `// 触发侧边栏折叠`<br>`await tester.tap(find.byIcon(Icons.menu));`<br>`await tester.pumpAndSettle();`<br>`// 验证内容区域宽度` |

---

## 8. 可访问性测试 (TC-S1-014-80 ~ TC-S1-014-87)

#### TC-S1-014-80: 屏幕阅读器标签测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-80 |
| **测试名称** | 屏幕阅读器标签测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 工作台列表页面已加载 |
| **测试步骤** | 1. 检查所有交互元素的语义标签 |
| **预期结果** | 1. 所有按钮有描述性标签<br>2. 输入框有关联标签<br>3. 图标按钮有tooltip或semanticLabel |
| **自动化代码** | `// 检查语义标签`<br>`expect(tester.semantics.find(label: '创建工作台'), findsOneWidget);`<br>`expect(tester.semantics.find(label: '编辑工作台 Workbench 1'), findsOneWidget);`<br>`expect(tester.semantics.find(label: '删除工作台 Workbench 1'), findsOneWidget);` |

---

#### TC-S1-014-81: 键盘导航-Tab键顺序测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-81 |
| **测试名称** | 键盘导航-Tab键顺序测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 按Tab键遍历所有可聚焦元素 |
| **预期结果** | 1. Tab顺序符合逻辑(从上到下)<br>2. 所有交互元素可聚焦 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`expect(FocusManager.instance.primaryFocus, equals(nameFieldFocus));`<br>`await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`expect(FocusManager.instance.primaryFocus, equals(descFieldFocus));` |

---

#### TC-S1-014-82: 键盘导航-Enter键提交测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-82 |
| **测试名称** | 键盘导航-Enter键提交测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P0 |
| **前置条件** | 1. 创建对话框已打开<br>2. 表单填写完整 |
| **测试步骤** | 1. 在表单中按Enter键 |
| **预期结果** | 1. 表单提交<br>2. 等效于点击创建按钮 |
| **自动化代码** | `await tester.enterText(nameField, 'Test Workbench');`<br>`await tester.sendKeyEvent(LogicalKeyboardKey.enter);`<br>`await tester.pump();`<br>`verify(mockApi.createWorkbench(any)).called(1);` |

---

#### TC-S1-014-83: 键盘导航-Escape键关闭对话框测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-83 |
| **测试名称** | 键盘导航-Escape键关闭对话框测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 按Escape键 |
| **预期结果** | 1. 对话框关闭<br>2. 等效于点击取消 |
| **自动化代码** | `await tester.sendKeyEvent(LogicalKeyboardKey.escape);`<br>`await tester.pumpAndSettle();`<br>`expect(find.byType(CreateWorkbenchDialog), findsNothing);` |

---

#### TC-S1-014-84: 键盘导航-删除确认测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-84 |
| **测试名称** | 键盘导航-删除确认测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 删除确认对话框已打开 |
| **测试步骤** | 1. 使用Tab键聚焦到删除按钮<br>2. 按Enter键 |
| **预期结果** | 1. 执行删除操作 |
| **自动化代码** | `// Tab到删除按钮`<br>`await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`await tester.sendKeyEvent(LogicalKeyboardKey.enter);`<br>`await tester.pumpAndSettle();`<br>`verify(mockApi.deleteWorkbench('1')).called(1);` |

---

#### TC-S1-014-85: 焦点管理-对话框打开时焦点测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-85 |
| **测试名称** | 焦点管理-对话框打开时焦点测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 准备打开创建对话框 |
| **测试步骤** | 1. 打开创建对话框 |
| **预期结果** | 1. 焦点自动设置到第一个输入框(名称) |
| **自动化代码** | `await tester.tap(find.text('创建工作台'));`<br>`await tester.pumpAndSettle();`<br>`expect(FocusManager.instance.primaryFocus, equals(nameFieldFocus));` |

---

#### TC-S1-014-86: 焦点陷阱-对话框内焦点不逃逸测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-86 |
| **测试名称** | 焦点陷阱-对话框内焦点不逃逸测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P1 |
| **前置条件** | 1. 创建对话框已打开 |
| **测试步骤** | 1. 在对话框内不断按Tab键 |
| **预期结果** | 1. 焦点在对话框内循环<br>2. 不会聚焦到对话框外元素 |
| **自动化代码** | `// 多次Tab确保循环`<br>`for (int i = 0; i < 10; i++) {`<br>`  await tester.sendKeyEvent(LogicalKeyboardKey.tab);`<br>`}`<br>`// 验证焦点仍在对话框内` |

---

#### TC-S1-014-87: 颜色对比度测试

| 字段 | 内容 |
|------|------|
| **测试ID** | TC-S1-014-87 |
| **测试名称** | 颜色对比度测试 |
| **测试类型** | Accessibility Test |
| **优先级** | P2 |
| **前置条件** | 1. 工作台列表页面已加载 |
| **测试步骤** | 1. 检查文本与背景对比度 |
| **预期结果** | 1. 所有文本对比度 >= 4.5:1 (WCAG AA)<br>2. 大文本对比度 >= 3:1 |
| **自动化代码** | `// 使用 accessibility_tools 或手动检查`<br>`final result = await tester.checkContrast();`<br>`expect(result.violations, isEmpty);` |

---

## 9. Widget测试示例代码

### 9.1 完整测试文件示例

```dart
// test/widget/workbench/workbench_list_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';
import 'package:kayak_frontend/test/helpers/widget_interactions.dart';
import 'package:kayak_frontend/providers/workbench_provider.dart';
import 'package:kayak_frontend/models/workbench.dart';
import 'package:kayak_frontend/pages/workbench/workbench_list_page.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkbenchRepository extends Mock implements WorkbenchRepository {}

void main() {
  group('WorkbenchListPage', () {
    late MockWorkbenchRepository mockRepository;

    setUp(() {
      mockRepository = MockWorkbenchRepository();
    });

    // TC-S1-014-01: 工作台列表正常加载测试
    testWidgets('displays workbench list correctly', (WidgetTester tester) async {
      // Arrange
      final workbenches = [
        Workbench(id: '1', name: 'Workbench 1', description: 'Description 1'),
        Workbench(id: '2', name: 'Workbench 2', description: 'Description 2'),
      ];
      
      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async => workbenches);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const TestApp(child: WorkbenchListPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Workbench 1'), findsOneWidget);
      expect(find.text('Workbench 2'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
      expect(find.byIcon(Icons.delete), findsNWidgets(2));
    });

    // TC-S1-014-02: 工作台列表空状态测试
    testWidgets('displays empty state when no workbenches', (WidgetTester tester) async {
      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const TestApp(child: WorkbenchListPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('暂无工作台'), findsOneWidget);
      expect(find.text('创建工作台'), findsOneWidget);
    });

    // TC-S1-014-03: 工作台列表加载状态测试
    testWidgets('displays loading state', (WidgetTester tester) async {
      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return [];
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const TestApp(child: WorkbenchListPage()),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // TC-S1-014-09 & TC-S1-014-10: 视图模式切换测试
    testWidgets('toggles between card and list view', (WidgetTester tester) async {
      final workbenches = [
        Workbench(id: '1', name: 'Workbench 1', description: 'Description 1'),
      ];
      
      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async => workbenches);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const TestApp(child: WorkbenchListPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Default should be card view
      expect(find.byType(WorkbenchCard), findsOneWidget);

      // Switch to list view
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.byType(WorkbenchListTile), findsOneWidget);
      expect(find.byType(WorkbenchCard), findsNothing);
    });
  });
}
```

### 9.2 表单验证测试示例

```dart
// test/widget/workbench/workbench_form_test.dart

group('WorkbenchForm Validation', () {
  late TextEditingController nameController;
  late TextEditingController descController;

  setUp(() {
    nameController = TextEditingController();
    descController = TextEditingController();
  });

  tearDown(() {
    nameController.dispose();
    descController.dispose();
  });

  // TC-S1-014-21: 空名称验证
  testWidgets('shows error for empty name', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: WorkbenchForm(
          nameController: nameController,
          descriptionController: descController,
          onSubmit: () {},
        ),
      ),
    );

    // Try to submit with empty name
    await tester.tap(find.text('创建'));
    await tester.pump();

    expect(find.text('工作台名称不能为空'), findsOneWidget);
  });

  // TC-S1-014-22: 名称长度超限验证
  testWidgets('shows error for name exceeding 255 chars', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: WorkbenchForm(
          nameController: nameController,
          descriptionController: descController,
          onSubmit: () {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'A' * 256);
    await tester.tap(find.text('创建'));
    await tester.pump();

    expect(find.text('名称长度不能超过255个字符'), findsOneWidget);
  });

  // TC-S1-014-50: 实时验证
  testWidgets('validates on field blur', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: WorkbenchForm(
          nameController: nameController,
          descriptionController: descController,
          onSubmit: () {},
        ),
      ),
    );

    // Enter and then clear
    await tester.enterText(find.byType(TextField).first, 'Test');
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();

    // Move focus to another field to trigger validation
    await tester.tap(find.byType(TextField).last);
    await tester.pump();

    expect(find.text('工作台名称不能为空'), findsOneWidget);
  });
});
```

### 9.3 删除对话框测试示例

```dart
// test/widget/workbench/delete_dialog_test.dart
group('DeleteWorkbenchDialog', () {
  // TC-S1-014-40: 删除确认对话框显示
  testWidgets('shows delete confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDeleteDialog(
              context,
              workbenchName: 'Test Workbench',
              deviceCount: 3,
            ),
            child: const Text('Delete'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('确定要删除此工作台吗?'), findsOneWidget);
    expect(find.text('此操作不可撤销'), findsOneWidget);
    expect(find.text('此工作台包含3个设备，将一并删除'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });

  // TC-S1-014-41: 取消操作
  testWidgets('closes dialog on cancel', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDeleteDialog(
              context,
              workbenchName: 'Test Workbench',
              onConfirm: () {},
            ),
            child: const Text('Delete'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  // TC-S1-014-42: 确认删除
  testWidgets('calls onConfirm on delete', (WidgetTester tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDeleteDialog(
              context,
              workbenchName: 'Test Workbench',
              onConfirm: () => confirmed = true,
            ),
            child: const Text('Delete'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
});
```

### 9.4 响应式布局测试示例

```dart
// test/widget/workbench/responsive_layout_test.dart
group('Responsive Layout', () {
  final workbenches = List.generate(
    10,
    (i) => Workbench(
      id: '$i',
      name: 'Workbench $i',
      description: 'Description $i',
    ),
  );

  // TC-S1-014-70: 大屏布局
  testWidgets('displays correct columns on large screen', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    when(() => mockRepository.getWorkbenches())
        .thenAnswer((_) async => workbenches);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workbenchRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const TestApp(child: WorkbenchListPage()),
      ),
    );

    await tester.pumpAndSettle();

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final sliverGrid = gridView.childrenDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    
    // Expect 4-5 columns on 1920px width
    expect(sliverGrid.crossAxisCount, greaterThanOrEqualTo(4));
  });

  // TC-S1-014-72: 小屏布局
  testWidgets('displays correct columns on small screen', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    when(() => mockRepository.getWorkbenches())
        .thenAnswer((_) async => workbenches);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workbenchRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const TestApp(child: WorkbenchListPage()),
      ),
    );

    await tester.pumpAndSettle();

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final sliverGrid = gridView.childrenDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    
    // Expect 2 columns on 1024px width
    expect(sliverGrid.crossAxisCount, equals(2));
  });
});
```

### 9.5 可访问性测试示例

```dart
// test/widget/workbench/accessibility_test.dart
group('Accessibility', () {
  // TC-S1-014-80: 语义标签
  testWidgets('has correct semantic labels', (WidgetTester tester) async {
    final workbenches = [
      Workbench(id: '1', name: 'Workbench 1', description: 'Description 1'),
    ];
    
    when(() => mockRepository.getWorkbenches())
        .thenAnswer((_) async => workbenches);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workbenchRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const TestApp(child: WorkbenchListPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Check semantic labels
    final semantics = tester.semantics;
    expect(
      semantics.find(label: '创建工作台'),
      findsOneWidget,
    );
    expect(
      semantics.find(label: '编辑工作台 Workbench 1'),
      findsOneWidget,
    );
    expect(
      semantics.find(label: '删除工作台 Workbench 1'),
      findsOneWidget,
    );
  });

  // TC-S1-014-81: Tab键导航
  testWidgets('supports tab navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: WorkbenchForm(
          nameController: nameController,
          descriptionController: descController,
          onSubmit: () {},
        ),
      ),
    );

    // Initial focus should be on name field
    expect(Focus.of(tester.element(find.byType(TextField).first)).hasFocus, isTrue);

    // Tab to description field
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.byType(TextField).last)).hasFocus, isTrue);

    // Tab to submit button
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.byType(ElevatedButton))).hasFocus, isTrue);
  });

  // TC-S1-014-83: Escape键关闭
  testWidgets('closes dialog on escape key', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCreateWorkbenchDialog(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateWorkbenchDialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(CreateWorkbenchDialog), findsNothing);
  });
});
```

---

## 10. Golden测试示例代码

```dart
// test/widget/golden/workbench_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';
import 'package:kayak_frontend/pages/workbench/workbench_list_page.dart';
import 'package:kayak_frontend/providers/workbench_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkbenchRepository extends Mock implements WorkbenchRepository {}

void main() {
  group('Workbench Golden Tests', () {
    late MockWorkbenchRepository mockRepository;

    setUp(() {
      mockRepository = MockWorkbenchRepository();
    });

    // Golden test for card view - light theme
    testGoldens('Workbench List - Card View - Light Theme', (tester) async {
      final workbenches = [
        Workbench(id: '1', name: 'Temperature Lab', description: 'Temperature measurement lab'),
        Workbench(id: '2', name: 'Pressure Test', description: 'Pressure testing station'),
        Workbench(id: '3', name: 'Vibration Analysis', description: 'Vibration analysis bench'),
        Workbench(id: '4', name: 'Flow Control', description: 'Flow control system'),
      ];

      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async => workbenches);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tablet,
          Device.desktop,
        ])
        ..addScenario(
          name: 'card view',
          widget: ProviderScope(
            overrides: [
              workbenchRepositoryProvider.overrideWithValue(mockRepository),
            ],
            child: TestApp.light(
              child: const WorkbenchListPage(),
            ),
          ),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'workbench_list_card_light');
    });

    // Golden test for list view - dark theme
    testGoldens('Workbench List - List View - Dark Theme', (tester) async {
      final workbenches = [
        Workbench(id: '1', name: 'Temperature Lab', description: 'Temperature measurement lab'),
        Workbench(id: '2', name: 'Pressure Test', description: 'Pressure testing station'),
      ];

      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async => workbenches);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workbenchRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: TestApp.dark(
            child: const WorkbenchListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to list view
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WorkbenchListPage),
        matchesGoldenFile('golden_files/workbench_list_list_dark.png'),
      );
    });

    // Golden test for empty state
    testGoldens('Workbench List - Empty State', (tester) async {
      when(() => mockRepository.getWorkbenches())
          .thenAnswer((_) async => []);

      final builder = DeviceBuilder()
        ..addScenario(
          name: 'empty state',
          widget: ProviderScope(
            overrides: [
              workbenchRepositoryProvider.overrideWithValue(mockRepository),
            ],
            child: TestApp.light(
              child: const WorkbenchListPage(),
            ),
          ),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'workbench_list_empty');
    });

    // Golden test for create dialog
    testGoldens('Create Workbench Dialog', (tester) async {
      await tester.pumpWidget(
        TestApp.light(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showCreateWorkbenchDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CreateWorkbenchDialog),
        matchesGoldenFile('golden_files/create_workbench_dialog.png'),
      );
    });

    // Golden test for delete confirmation dialog
    testGoldens('Delete Confirmation Dialog', (tester) async {
      await tester.pumpWidget(
        TestApp.light(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDeleteDialog(
                context,
                workbenchName: 'Temperature Lab',
                deviceCount: 3,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DeleteConfirmDialog),
        matchesGoldenFile('golden_files/delete_workbench_dialog.png'),
      );
    });
  });
}
```

---

## 11. 测试执行检查清单

### 11.1 执行前准备

- [ ] 确认 S1-013 (工作台CRUD API) 已完成并通过测试
- [ ] 确认 S1-012 (认证状态管理) 已完成并通过测试
- [ ] 确认测试环境配置完成 (flutter test 可用)
- [ ] 确认测试辅助类已创建 (TestApp, WidgetFinderHelpers等)
- [ ] 确认mock/stub数据准备就绪

### 11.2 执行顺序建议

| 阶段 | 测试范围 | 预计时间 |
|------|---------|---------|
| 1 | 基础Widget测试 (TC-S1-014-01 ~ TC-S1-014-15) | 30分钟 |
| 2 | 表单验证测试 (TC-S1-014-20 ~ TC-S1-014-35) | 45分钟 |
| 3 | 删除确认测试 (TC-S1-014-40 ~ TC-S1-014-47) | 20分钟 |
| 4 | 错误处理测试 (TC-S1-014-60 ~ TC-S1-014-67) | 30分钟 |
| 5 | 响应式布局测试 (TC-S1-014-70 ~ TC-S1-014-75) | 30分钟 |
| 6 | 可访问性测试 (TC-S1-014-80 ~ TC-S1-014-87) | 30分钟 |
| 7 | Golden测试 (如适用) | 15分钟 |
| **总计** | | **约3.5小时** |

### 11.3 验收检查清单

- [ ] 所有P0优先级测试通过
- [ ] 代码覆盖率 > 80%
- [ ] 所有Golden测试图片已生成并验证
- [ ] 可访问性检查无严重问题
- [ ] 跨平台测试通过 (Windows/Mac/Linux)
- [ ] 不同主题(浅色/深色)测试通过

---

## 12. 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-014-XX  
**关联测试用例**: TC-S1-014-XX  
**严重程度**: [P0/P1/P2/P3]  
**发现日期**: YYYY-MM-DD  
**报告人**: [姓名]

### 问题描述
[详细描述问题现象]

### 复现步骤
1. [步骤1]
2. [步骤2]
3. [步骤3]

### 预期结果
[描述预期的正确行为]

### 实际结果
[描述实际观察到的行为]

### 环境信息
- Flutter版本: [版本号]
- Dart版本: [版本号]
- 操作系统: [系统版本]
- 分支/提交: [commit hash]
- 屏幕尺寸: [尺寸]
- 主题: [浅色/深色]

### 附件
- [错误日志]
- [截图]
- [Golden对比结果]
- [视频录制]
```

---

## 13. 附录

### 13.1 测试数据模板

```dart
// 标准工作台测试数据
final standardWorkbenches = [
  Workbench(
    id: '550e8400-e29b-41d4-a716-446655440000',
    name: 'Temperature Lab',
    description: 'Temperature measurement laboratory',
    ownerId: 'user-1',
    status: WorkbenchStatus.active,
    createdAt: DateTime.parse('2026-03-20T10:00:00Z'),
    updatedAt: DateTime.parse('2026-03-20T10:00:00Z'),
  ),
  Workbench(
    id: '550e8400-e29b-41d4-a716-446655440001',
    name: 'Pressure Test Station',
    description: 'High pressure testing environment',
    ownerId: 'user-1',
    status: WorkbenchStatus.active,
    createdAt: DateTime.parse('2026-03-20T11:00:00Z'),
    updatedAt: DateTime.parse('2026-03-20T11:00:00Z'),
  ),
];

// 边界值测试数据
final boundaryValueWorkbenches = [
  // 最小名称长度
  Workbench(id: '1', name: 'A', description: ''),
  // 最大名称长度 (255 chars)
  Workbench(id: '2', name: 'A' * 255, description: ''),
  // 最大描述长度 (1000 chars)
  Workbench(id: '3', name: 'Test', description: 'B' * 1000),
  // Unicode字符
  Workbench(id: '4', name: '工作台🔬🧪', description: '日本語テスト'),
];
```

### 13.2 常用命令参考

```bash
# 运行所有工作台相关测试
flutter test test/widget/workbench/

# 运行特定测试
flutter test test/widget/workbench/workbench_list_page_test.dart

# 更新Golden文件
flutter test --update-goldens test/widget/golden/workbench_golden_test.dart

# 生成覆盖率报告
flutter test --coverage test/widget/workbench/
genhtml coverage/lcov.info -o coverage/html

# 运行特定测试用例
flutter test --name "displays workbench list correctly"
```

### 13.3 参考文档

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Golden Testing](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
- [Accessibility Testing](https://docs.flutter.dev/accessibility)
- [Material Design 3 Guidelines](https://m3.material.io/)

---

## 14. 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|--------|---------|
| 1.0 | 2026-03-22 | sw-mike | 初始版本创建 |

---

**文档结束**
