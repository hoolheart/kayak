# S1-014: 工作台管理页面 - 测试用例文档

**版本**: 2.0  
**创建日期**: 2026-03-22  
**任务**: S1-014 工作台管理页面 (Workbench Management Page)  
**技术栈**: Flutter / Riverpod / Material Design 3  
**测试类型**: Widget测试、集成测试、TDD风格

---

## 1. 测试概述

### 1.1 任务描述

实现工作台列表页面(卡片/列表视图切换)，实现工作台创建/编辑对话框，实现工作台删除确认对话框。适配桌面端布局。

### 1.2 验收标准

| # | 标准 | 描述 |
|---|------|------|
| AC1 | 列表展示所有工作台 | 工作台列表页面正确展示用户所有工作台 |
| AC2 | 创建/编辑表单验证完整 | 工作台名称必填、长度限制；描述可选、长度限制 |
| AC3 | 删除操作需要二次确认 | 删除前显示确认对话框，防止误操作 |

### 1.3 依赖关系

| 依赖任务 | 说明 |
|----------|------|
| S1-012 | 认证状态管理与路由守卫 |
| S1-013 | 工作台CRUD API |

### 1.4 测试环境要求

| 环境项 | 说明 |
|--------|------|
| Flutter SDK | 3.16+ |
| 状态管理 | Riverpod |
| UI框架 | Material Design 3 |
| 后端API | S1-013 工作台CRUD API |

---

## 2. 工作台列表页面测试 (AC1)

### TC-S1-014-001: 工作台列表正确显示

**前置条件**: 用户已登录，API返回包含多个工作台的数据

**测试步骤**:
1. 导航到工作台列表页面
2. 等待数据加载完成

**预期结果**:
- 显示所有工作台卡片（卡片视图）或列表项（列表视图）
- 每个工作台显示名称
- 工作台描述正确显示（无描述时显示"暂无描述"）

```dart
testWidgets('displays all workbenches in list', (WidgetTester tester) async {
  // Arrange
  final workbenches = [
    Workbench(id: '1', name: 'Lab A', description: 'Test lab'),
    Workbench(id: '2', name: 'Lab B', description: null),
  ];
  
  // Act & Assert
  await tester.pumpWidget(buildTestWidget(workbenches: workbenches));
  await tester.pumpAndSettle();
  
  expect(find.text('Lab A'), findsOneWidget);
  expect(find.text('Test lab'), findsOneWidget);
  expect(find.text('暂无描述'), findsOneWidget); // null description
});
```

---

### TC-S1-014-002: 列表空状态显示

**前置条件**: 用户已登录，API返回空列表

**测试步骤**:
1. 导航到工作台列表页面

**预期结果**:
- 显示空状态插图
- 显示"暂无工作台"文本
- 显示"创建工作台"操作按钮

```dart
testWidgets('displays empty state when no workbenches', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: []));
  await tester.pumpAndSettle();
  
  expect(find.text('暂无工作台'), findsOneWidget);
  expect(find.text('创建工作台'), findsOneWidget);
  expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
});
```

---

### TC-S1-014-003: 加载状态显示

**前置条件**: API请求进行中

**测试步骤**:
1. 导航到工作台列表页面

**预期结果**:
- 显示加载指示器 (CircularProgressIndicator)
- 不显示空状态或错误状态

```dart
testWidgets('displays loading indicator while fetching', (WidgetTester tester) async {
  when(() => mockService.getWorkbenches())
      .thenAnswer((_) => Future.delayed(Duration(seconds: 5), () => []));
  
  await tester.pumpWidget(buildTestWidget());
  await tester.pump(); // Start the future but don't settle
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

### TC-S1-014-004: 网络错误状态显示

**前置条件**: API请求失败（网络错误）

**测试步骤**:
1. 导航到工作台列表页面
2. API返回错误

**预期结果**:
- 显示错误图标
- 显示"加载失败"文本
- 显示"重试"按钮

```dart
testWidgets('displays error state on network failure', (WidgetTester tester) async {
  when(() => mockService.getWorkbenches())
      .thenThrow(NetworkException('No connection'));
  
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  expect(find.text('加载失败'), findsOneWidget);
  expect(find.text('重试'), findsOneWidget);
  expect(find.byIcon(Icons.error_outline), findsOneWidget);
});
```

---

### TC-S1-014-005: 点击工作台触发导航

**前置条件**: 工作台列表已加载

**测试步骤**:
1. 点击工作台卡片/列表项

**预期结果**:
- 触发onTap回调（导航到详情页）

```dart
testWidgets('triggers onTap when workbench is tapped', (WidgetTester tester) async {
  Workbench? tappedWorkbench;
  
  await tester.pumpWidget(
    buildTestWidget(
      onWorkbenchTap: (wb) => tappedWorkbench = wb,
    ),
  );
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('Lab A'));
  await tester.pumpAndSettle();
  
  expect(tappedWorkbench?.name, equals('Lab A'));
});
```

---

## 3. 视图模式切换测试

### TC-S1-014-006: 默认显示卡片视图

**前置条件**: 工作台列表已加载

**测试步骤**:
1. 首次打开工作台列表页面

**预期结果**:
- 默认显示卡片网格视图
- 使用WorkbenchCard组件展示

```dart
testWidgets('displays card view by default', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  expect(find.byType(GridView), findsOneWidget);
  expect(find.byType(WorkbenchCard), findsOneWidget);
  expect(find.byType(WorkbenchListTile), findsNothing);
});
```

---

### TC-S1-014-007: 切换到列表视图

**前置条件**: 工作台列表已加载，显示卡片视图

**测试步骤**:
1. 点击列表视图切换按钮（列表图标）

**预期结果**:
- 视图切换为ListView
- 使用WorkbenchListTile组件展示

```dart
testWidgets('switches to list view when list button is tapped', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.list));
  await tester.pumpAndSettle();
  
  expect(find.byType(ListView), findsOneWidget);
  expect(find.byType(WorkbenchListTile), findsOneWidget);
});
```

---

### TC-S1-014-008: 切换回卡片视图

**前置条件**: 当前显示列表视图

**测试步骤**:
1. 点击卡片视图切换按钮（网格图标）

**预期结果**:
- 视图切换为GridView
- 使用WorkbenchCard组件展示

```dart
testWidgets('switches back to card view when grid button is tapped', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  // First switch to list
  await tester.tap(find.byIcon(Icons.list));
  await tester.pumpAndSettle();
  
  // Then switch back to grid
  await tester.tap(find.byIcon(Icons.grid_view));
  await tester.pumpAndSettle();
  
  expect(find.byType(GridView), findsOneWidget);
  expect(find.byType(WorkbenchCard), findsOneWidget);
});
```

---

## 4. 创建工作台对话框测试 (AC2)

### TC-S1-014-009: 打开创建对话框

**前置条件**: 工作台列表页面已加载

**测试步骤**:
1. 点击"创建工作台"按钮

**预期结果**:
- 打开CreateWorkbenchDialog
- 对话框标题为"创建工作台"
- 名称输入框获得焦点
- 显示"取消"和"创建"按钮

```dart
testWidgets('opens create dialog when create button is tapped', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsOneWidget);
  expect(find.text('创建工作台').last, findsOneWidget); // Dialog title
  expect(find.text('创建'), findsOneWidget);
  expect(find.text('取消'), findsOneWidget);
});
```

---

### TC-S1-014-010: 创建对话框-空名称验证

**前置条件**: 创建对话框已打开

**测试步骤**:
1. 直接点击"创建"按钮（名称留空）

**预期结果**:
- 显示错误提示"请输入工作台名称"
- 不关闭对话框
- 不发送API请求

```dart
testWidgets('shows error for empty name on create', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建'));
  await tester.pump();
  
  expect(find.text('请输入工作台名称'), findsOneWidget);
  expect(find.byType(CreateWorkbenchDialog), findsOneWidget);
  verifyNever(() => mockService.createWorkbench(any(), any()));
});
```

---

### TC-S1-014-011: 创建对话框-名称长度验证（超长）

**前置条件**: 创建对话框已打开

**测试步骤**:
1. 输入超过255个字符的名称
2. 点击"创建"按钮

**预期结果**:
- 显示错误提示"名称不能超过255个字符"

```dart
testWidgets('shows error for name exceeding 255 characters', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  await tester.enterText(nameField, 'A' * 256);
  await tester.tap(find.text('创建'));
  await tester.pump();
  
  expect(find.text('名称不能超过255个字符'), findsOneWidget);
});
```

---

### TC-S1-014-012: 创建对话框-名称仅空白字符验证

**前置条件**: 创建对话框已打开

**测试步骤**:
1. 输入仅空白字符（空格、制表符）的名称
2. 点击"创建"按钮

**预期结果**:
- 显示错误提示"请输入工作台名称"

```dart
testWidgets('shows error for whitespace-only name', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  await tester.enterText(nameField, '   \t  ');
  await tester.tap(find.text('创建'));
  await tester.pump();
  
  expect(find.text('请输入工作台名称'), findsOneWidget);
});
```

---

### TC-S1-014-013: 创建对话框-描述长度验证（超长）

**前置条件**: 创建对话框已打开

**测试步骤**:
1. 输入有效名称
2. 输入超过1000个字符的描述
3. 点击"创建"按钮

**预期结果**:
- 显示错误提示"描述不能超过1000个字符"

```dart
testWidgets('shows error for description exceeding 1000 characters', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  final descField = find.byType(TextField).last;
  
  await tester.enterText(nameField, 'Valid Name');
  await tester.enterText(descField, 'A' * 1001);
  await tester.tap(find.text('创建'));
  await tester.pump();
  
  expect(find.text('描述不能超过1000个字符'), findsOneWidget);
});
```

---

### TC-S1-014-014: 创建对话框-成功创建

**前置条件**: 创建对话框已打开，API正常响应

**测试步骤**:
1. 输入有效名称和描述
2. 点击"创建"按钮
3. 等待API响应

**预期结果**:
- 显示加载状态
- 对话框关闭
- 显示成功提示"工作台创建成功"
- 列表刷新显示新工作台

```dart
testWidgets('creates workbench successfully', (WidgetTester tester) async {
  when(() => mockService.createWorkbench(any(), any()))
      .thenAnswer((_) async => workbench1);
  
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  final descField = find.byType(TextField).last;
  
  await tester.enterText(nameField, 'New Lab');
  await tester.enterText(descField, 'New description');
  await tester.tap(find.text('创建'));
  
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsNothing);
  expect(find.text('工作台创建成功'), findsOneWidget);
  verify(() => mockService.createWorkbench('New Lab', 'New description')).called(1);
});
```

---

### TC-S1-014-015: 创建对话框-取消操作

**前置条件**: 创建对话框已打开

**测试步骤**:
1. 输入名称和描述
2. 点击"取消"按钮

**预期结果**:
- 对话框关闭
- 不发送API请求
- 列表无变化

```dart
testWidgets('closes dialog on cancel without creating', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextField).first, 'Test');
  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsNothing);
  verifyNever(() => mockService.createWorkbench(any(), any()));
});
```

---

### TC-S1-014-016: 创建对话框-API错误处理

**前置条件**: 创建对话框已打开，API返回错误

**测试步骤**:
1. 输入有效数据
2. 点击"创建"按钮
3. API返回500错误

**预期结果**:
- 对话框保持打开
- 显示错误提示
- 创建按钮恢复可用

```dart
testWidgets('shows error message when API fails', (WidgetTester tester) async {
  when(() => mockService.createWorkbench(any(), any()))
      .thenThrow(ApiException(500, 'Server error'));
  
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('创建工作台'));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextField).first, 'New Lab');
  await tester.tap(find.text('创建'));
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsOneWidget);
  expect(find.text('创建失败，请重试'), findsOneWidget);
});
```

---

## 5. 编辑工作台对话框测试 (AC2)

### TC-S1-014-017: 打开编辑对话框

**前置条件**: 工作台列表已加载

**测试步骤**:
1. 点击工作台的编辑按钮

**预期结果**:
- 打开CreateWorkbenchDialog（复用创建对话框）
- 对话框标题为"编辑工作台"
- 名称输入框预填充原名称
- 描述输入框预填充原描述

```dart
testWidgets('opens edit dialog with pre-filled data', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  expect(find.text('编辑工作台'), findsOneWidget);
  // Verify pre-filled values via controller
  expect(nameController.text, equals('Lab A'));
  expect(descController.text, equals('Test lab'));
});
```

---

### TC-S1-014-018: 编辑对话框-成功更新

**前置条件**: 编辑对话框已打开，API正常响应

**测试步骤**:
1. 修改名称和描述
2. 点击"保存"按钮

**预期结果**:
- 显示加载状态
- 对话框关闭
- 显示成功提示"工作台更新成功"
- 列表中工作台信息更新

```dart
testWidgets('updates workbench successfully', (WidgetTester tester) async {
  when(() => mockService.updateWorkbench(any(), any(), any()))
      .thenAnswer((_) async => workbench1.copyWith(name: 'Updated Lab'));
  
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextField).first, 'Updated Lab');
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsNothing);
  expect(find.text('工作台更新成功'), findsOneWidget);
});
```

---

### TC-S1-014-019: 编辑对话框-空名称验证

**前置条件**: 编辑对话框已打开

**测试步骤**:
1. 清空名称输入框
2. 点击"保存"按钮

**预期结果**:
- 显示错误提示"请输入工作台名称"
- 不关闭对话框
- 不发送API请求

```dart
testWidgets('shows error for empty name on edit', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  // Clear the name field
  final nameField = find.byType(TextField).first;
  await tester.enterText(nameField, '');
  await tester.tap(find.text('保存'));
  await tester.pump();
  
  expect(find.text('请输入工作台名称'), findsOneWidget);
  expect(find.byType(CreateWorkbenchDialog), findsOneWidget);
  verifyNever(() => mockService.updateWorkbench(any(), any(), any()));
});
```

---

### TC-S1-014-020: 编辑对话框-名称超长验证

**前置条件**: 编辑对话框已打开

**测试步骤**:
1. 输入超过255个字符的名称
2. 点击"保存"按钮

**预期结果**:
- 显示错误提示"名称不能超过255个字符"

```dart
testWidgets('shows error for name exceeding 255 characters on edit', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  await tester.enterText(nameField, 'A' * 256);
  await tester.tap(find.text('保存'));
  await tester.pump();
  
  expect(find.text('名称不能超过255个字符'), findsOneWidget);
});
```

---

### TC-S1-014-021: 编辑对话框-空白字符名称验证

**前置条件**: 编辑对话框已打开

**测试步骤**:
1. 输入仅空白字符（空格、制表符）的名称
2. 点击"保存"按钮

**预期结果**:
- 显示错误提示"请输入工作台名称"

```dart
testWidgets('shows error for whitespace-only name on edit', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  await tester.enterText(nameField, '   \t  ');
  await tester.tap(find.text('保存'));
  await tester.pump();
  
  expect(find.text('请输入工作台名称'), findsOneWidget);
});
```

---

### TC-S1-014-022: 编辑对话框-描述超长验证

**前置条件**: 编辑对话框已打开

**测试步骤**:
1. 输入有效名称
2. 输入超过1000个字符的描述
3. 点击"保存"按钮

**预期结果**:
- 显示错误提示"描述不能超过1000个字符"

```dart
testWidgets('shows error for description exceeding 1000 characters on edit', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  final descField = find.byType(TextField).last;
  
  await tester.enterText(nameField, 'Valid Name');
  await tester.enterText(descField, 'A' * 1001);
  await tester.tap(find.text('保存'));
  await tester.pump();
  
  expect(find.text('描述不能超过1000个字符'), findsOneWidget);
});
```

---

### TC-S1-014-023: 编辑对话框-API错误处理

**前置条件**: 编辑对话框已打开，API返回错误

**测试步骤**:
1. 输入有效数据
2. 点击"保存"按钮
3. API返回500错误

**预期结果**:
- 对话框保持打开
- 显示错误提示"更新失败，请重试"
- 保存按钮恢复可用

```dart
testWidgets('shows error message when API fails on edit', (WidgetTester tester) async {
  when(() => mockService.updateWorkbench(any(), any(), any()))
      .thenThrow(ApiException(500, 'Server error'));
  
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextField).first, 'Updated Lab');
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsOneWidget);
  expect(find.text('更新失败，请重试'), findsOneWidget);
});
```

---

## 6. 删除确认对话框测试 (AC3)

### TC-S1-014-024: 显示删除确认对话框

**前置条件**: 工作台列表已加载

**测试步骤**:
1. 点击工作台的删除按钮

**预期结果**:
- 打开DeleteConfirmationDialog
- 显示警告图标
- 显示"删除"和"取消"按钮
- 显示工作台名称

```dart
testWidgets('shows delete confirmation dialog', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.delete_outlined).first);
  await tester.pumpAndSettle();
  
  expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
  expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  expect(find.text('取消'), findsOneWidget);
  expect(find.text('删除'), findsOneWidget);
});
```

---

### TC-S1-014-025: 取消删除操作

**前置条件**: 删除确认对话框已打开

**测试步骤**:
1. 点击"取消"按钮

**预期结果**:
- 对话框关闭
- 不发送删除API请求
- 工作台仍在列表中

```dart
testWidgets('closes dialog and does not delete on cancel', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.delete_outlined).first);
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();
  
  expect(find.byType(DeleteConfirmationDialog), findsNothing);
  expect(find.text('Lab A'), findsOneWidget);
  verifyNever(() => mockService.deleteWorkbench(any()));
});
```

---

### TC-S1-014-026: 确认删除操作

**前置条件**: 删除确认对话框已打开，API正常响应

**测试步骤**:
1. 点击"删除"按钮

**预期结果**:
- 发送删除API请求
- 工作台从列表移除
- 显示成功提示"工作台已删除"

```dart
testWidgets('deletes workbench when confirm is tapped', (WidgetTester tester) async {
  when(() => mockService.deleteWorkbench(any()))
      .thenAnswer((_) async {});
  
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.delete_outlined).first);
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('删除'));
  await tester.pumpAndSettle();
  
  expect(find.byType(DeleteConfirmationDialog), findsNothing);
  expect(find.text('Lab A'), findsNothing);
  expect(find.text('工作台已删除'), findsOneWidget);
  verify(() => mockService.deleteWorkbench('1')).called(1);
});
```

---

### TC-S1-014-027: 删除失败错误处理

**前置条件**: 删除确认对话框已打开，API返回错误

**测试步骤**:
1. 点击"删除"按钮
2. API返回500错误

**预期结果**:
- 对话框关闭
- 显示错误提示"删除失败，请重试"
- 工作台仍在列表中

```dart
testWidgets('shows error when delete fails', (WidgetTester tester) async {
  when(() => mockService.deleteWorkbench(any()))
      .thenThrow(ApiException(500, 'Server error'));
  
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.delete_outlined).first);
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('删除'));
  await tester.pumpAndSettle();
  
  expect(find.byType(DeleteConfirmationDialog), findsNothing);
  expect(find.text('删除失败，请重试'), findsOneWidget);
  expect(find.text('Lab A'), findsOneWidget);
});
```

---

### TC-S1-014-028: 删除最后一个工作台后显示空状态

**前置条件**: 列表只有一个工作台

**测试步骤**:
1. 删除该工作台

**预期结果**:
- 删除成功后
- 列表显示空状态

```dart
testWidgets('shows empty state after deleting last workbench', (WidgetTester tester) async {
  when(() => mockService.deleteWorkbench(any()))
      .thenAnswer((_) async {});
  
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byIcon(Icons.delete_outlined).first);
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('删除'));
  await tester.pumpAndSettle();
  
  expect(find.text('暂无工作台'), findsOneWidget);
});
```

---

## 7. 错误处理测试

### TC-S1-014-029: 网络断开错误处理

**前置条件**: 应用处于离线状态

**测试步骤**:
1. 尝试加载工作台列表

**预期结果**:
- 显示"网络连接失败，请检查网络后重试"提示
- 显示"重试"按钮

```dart
testWidgets('handles network disconnection gracefully', (WidgetTester tester) async {
  when(() => mockService.getWorkbenches())
      .thenThrow(NetworkException('No connection'));
  
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  expect(find.textContaining('网络'), findsOneWidget);
  expect(find.text('重试'), findsOneWidget);
});
```

---

### TC-S1-014-030: 401未授权错误处理

**前置条件**: Token过期或无效

**测试步骤**:
1. API返回401错误

**预期结果**:
- 跳转到登录页面
- 或显示"登录已过期，请重新登录"

```dart
testWidgets('redirects to login on 401 error', (WidgetTester tester) async {
  when(() => mockService.getWorkbenches())
      .thenThrow(ApiException(401, 'Unauthorized'));
  
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  expect(find.text('重新登录').last, findsOneWidget); // or check router
});
```

---

## 8. 桌面端适配测试

### TC-S1-014-031: 响应式布局测试

**前置条件**: 在桌面窗口尺寸下运行

**测试步骤**:
1. 设置窗口宽度为1200px
2. 加载工作台列表页面

**预期结果**:
- 侧边导航栏正常显示
- 内容区域宽度适配
- 卡片/列表项在合理宽度内展示

```dart
testWidgets('adapts layout for desktop window size', (WidgetTester tester) async {
  // Set desktop window size
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  // Verify side navigation is visible
  expect(find.byType(NavigationRail), findsOneWidget);
  
  // Reset view
  tester.view.resetPhysicalSize();
});
```

---

### TC-S1-014-032: 键盘导航测试

**前置条件**: 工作台列表页面已加载，焦点在页面上

**测试步骤**:
1. 按Tab键在页面元素间导航
2. 找到创建按钮后按Enter键
3. 对话框打开后按Escape键关闭

**预期结果**:
- Tab键可在元素间移动焦点
- Enter键触发对应操作
- Escape键关闭对话框

```dart
testWidgets('supports keyboard navigation', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget());
  await tester.pumpAndSettle();
  
  // Tab to focus on create button
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  
  // Press Enter on create button
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsOneWidget);
  
  // Press Escape to close
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  
  expect(find.byType(CreateWorkbenchDialog), findsNothing);
});
```

---

### TC-S1-014-033: 鼠标交互测试

**前置条件**: 工作台卡片已显示

**测试步骤**:
1. 将鼠标悬停在工作台卡片上
2. 观察卡片状态变化
3. 点击编辑按钮

**预期结果**:
- 悬停时显示hover状态（如阴影加深或边框高亮）
- 点击编辑按钮打开编辑对话框

```dart
testWidgets('shows hover states and handles mouse interactions', (WidgetTester tester) async {
  await tester.pumpWidget(buildTestWidget(workbenches: [workbench1]));
  await tester.pumpAndSettle();
  
  // Find the card
  final card = find.byType(WorkbenchCard);
  expect(card, findsOneWidget);
  
  // Hover over the card
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  
  await gesture.moveTo(tester.getCenter(card));
  await tester.pump();
  
  // Verify card has hover effect (elevation change or similar)
  // Then click edit button
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
  
  expect(find.text('编辑工作台'), findsOneWidget);
});
```

---

## 9. 测试数据

### 8.1 测试对象

```dart
// 标准测试工作台
final workbench1 = Workbench(
  id: '550e8400-e29b-41d4-a716-446655440001',
  name: 'Temperature Lab',
  description: 'Temperature measurement laboratory',
  ownerId: 'user-1',
  status: WorkbenchStatus.active,
  createdAt: DateTime.parse('2026-03-20T10:00:00Z'),
  updatedAt: DateTime.parse('2026-03-20T10:00:00Z'),
);

final workbench2 = Workbench(
  id: '550e8400-e29b-41d4-a716-446655440002',
  name: 'Pressure Station',
  description: 'High pressure testing environment',
  ownerId: 'user-1',
  status: WorkbenchStatus.active,
  createdAt: DateTime.parse('2026-03-20T11:00:00Z'),
  updatedAt: DateTime.parse('2026-03-20T11:00:00Z'),
);
```

### 8.2 边界值测试数据

```dart
// 最小有效名称 (1字符)
final oneCharName = 'A';

// 最大有效名称 (255字符)
final maxLengthName = 'A' * 255;

// 超长名称 (256字符)
final overLengthName = 'A' * 256;

// 最大有效描述 (1000字符)
final maxLengthDesc = 'A' * 1000;

// 超长描述 (1001字符)
final overLengthDesc = 'A' * 1001;
```

---

## 9. 测试辅助工具

### 9.1 测试Widget构建器

```dart
Widget buildTestWidget({
  List<Workbench> workbenches = const [],
  Function(Workbench)? onWorkbenchTap,
}) {
  return ProviderScope(
    overrides: [
      workbenchServiceProvider.overrideWithValue(mockService),
      workbenchListProvider.overrideWith((ref) => 
        Stream.value(AsyncData(WorkbenchListState(workbenches: workbenches)))),
    ],
    child: MaterialApp(
      home: WorkbenchListPage(
        onWorkbenchTap: onWorkbenchTap,
      ),
    ),
  );
}
```

---

## 10. 测试用例统计

| 类别 | 测试数量 | 说明 |
|------|---------|------|
| 列表展示测试 | TC-001 ~ TC-005 | 5个测试 |
| 视图切换测试 | TC-006 ~ TC-008 | 3个测试 |
| 创建对话框测试 | TC-009 ~ TC-016 | 8个测试 |
| 编辑对话框测试 | TC-017 ~ TC-023 | 7个测试 |
| 删除确认测试 | TC-024 ~ TC-028 | 5个测试 |
| 错误处理测试 | TC-029 ~ TC-030 | 2个测试 |
| 桌面端适配测试 | TC-031 ~ TC-033 | 3个测试 |
| **总计** | **33** | |

---

## 11. 验收标准覆盖

| 验收标准 | 测试用例 | 覆盖状态 |
|----------|----------|----------|
| AC1: 列表展示所有工作台 | TC-001, TC-002, TC-003, TC-004, TC-005 | ✅ |
| AC2: 创建/编辑表单验证完整 | TC-009, TC-010, TC-011, TC-012, TC-013, TC-014, TC-015, TC-016, TC-017, TC-018, TC-019, TC-020, TC-021, TC-022, TC-023 | ✅ |
| AC3: 删除操作需要二次确认 | TC-024, TC-025, TC-026, TC-027, TC-028 | ✅ |

---

## 12. 缺陷报告模板

```markdown
## 缺陷报告

**缺陷ID**: BUG-S1-014-XX  
**测试用例**: TC-S1-014-XXX  
**严重程度**: [P0/P1/P2]  
**发现日期**: YYYY-MM-DD

### 问题描述
[描述问题]

### 复现步骤
1. [步骤1]
2. [步骤2]

### 预期结果
[预期行为]

### 实际结果
[实际行为]

### 环境
- Flutter版本: 
- 操作系统: 
```

---

**文档结束**
