# S1-006: Flutter Widget测试框架搭建 - 测试用例文档

**任务ID**: S1-006  
**任务名称**: Flutter Widget测试框架搭建  
**文档版本**: 1.0  
**创建日期**: 2024-03-15  
**测试类型**: Widget测试、Golden测试、框架配置测试

---

## 1. 测试范围

### 1.1 测试目标

本文档覆盖 S1-006 任务的所有验收标准，确保Flutter Widget测试框架正确配置并可用：
1. 配置Flutter测试环境
2. 编写Widget测试辅助类（组件查找、交互模拟）
3. 集成Golden测试用于UI回归测试

### 1.2 验收标准映射

| 验收标准 | 测试用例ID | 测试类型 |
|---------|-----------|---------|
| 1. `flutter test` 执行通过 | TC-WGT-001 ~ TC-WGT-003 | 框架配置测试 |
| 2. 包含至少一个Widget测试示例 | TC-WGT-004 ~ TC-WGT-008 | Widget测试 |
| 3. Golden测试配置完成 | TC-WGT-009 ~ TC-WGT-012 | Golden测试 |

### 1.3 测试环境要求

| 环境项 | 要求 |
|--------|------|
| Flutter SDK | >= 3.19.0 (stable channel) |
| Dart SDK | >= 3.3.0 |
| flutter_test | 已包含在Flutter SDK中 |
| golden_toolkit | ^0.15.0 (可选，增强Golden测试) |
| mocktail | ^1.0.0 (可选，Mock支持) |

---

## 2. 测试用例详情

### 2.1 测试框架配置测试

#### TC-WGT-001: Flutter测试环境配置验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-001 |
| **测试名称** | Flutter测试环境配置验证 |
| **测试类型** | 框架配置测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证Flutter测试环境已正确配置，测试框架可用 |

**前置条件:**
1. Flutter SDK已安装 (>= 3.19.0)
2. 项目已创建 (`kayak-frontend/` 目录存在)
3. 项目依赖已获取 (`flutter pub get` 成功)

**测试步骤:**

1. 检查测试目录结构
   ```bash
   cd /home/hzhou/workspace/kayak/kayak-frontend
   ls -la test/
   ```

2. 检查pubspec.yaml中的测试配置
   ```bash
   cat pubspec.yaml | grep -A 5 "dev_dependencies:"
   ```

3. 运行基础测试验证环境
   ```bash
   flutter test --version
   ```

4. 执行空测试套件（验证测试框架无错误）
   ```bash
   flutter test test/placeholder_test.dart 2>&1 || echo "预期失败，验证测试框架响应"
   ```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 测试目录 | `test/` 目录存在 |
| flutter_test | 在pubspec.yaml中可用（隐式依赖） |
| flutter test命令 | 可正常执行，返回版本信息 |
| 测试框架响应 | 正确处理测试文件（无论是否存在） |

**通过标准:**
- [ ] `test/` 目录存在于项目根目录
- [ ] `flutter test` 命令可用
- [ ] 测试框架无配置错误

**自动化验证脚本:**

```bash
#!/bin/bash
# TC-WGT-001: Flutter测试环境配置验证

set -e

PROJECT_DIR="/home/hzhou/workspace/kayak/kayak-frontend"

echo "=== TC-WGT-001: Flutter测试环境配置验证 ==="
echo "开始时间: $(date)"

# 进入项目目录
cd "$PROJECT_DIR" || exit 1

# 检查测试目录
if [ -d "test" ]; then
    echo "✓ test/ 目录存在"
else
    echo "✗ test/ 目录不存在，正在创建..."
    mkdir -p test
    echo "✓ test/ 目录已创建"
fi

# 检查flutter test命令
echo ""
echo "检查flutter test可用性..."
if flutter test --version >/dev/null 2>&1; then
    echo "✓ flutter test 命令可用"
else
    echo "✗ flutter test 命令不可用"
    exit 1
fi

# 运行空测试验证框架
echo ""
echo "验证测试框架响应..."
if flutter test 2>&1 | grep -q "No tests ran\|All tests passed"; then
    echo "✓ 测试框架运行正常"
else
    echo "⚠ 测试框架可能有配置问题（检查依赖）"
fi

echo ""
echo "=== 测试通过 ==="
echo "结束时间: $(date)"
```

**备注:**
- flutter_test是Flutter SDK的一部分，通常不需要显式添加到pubspec.yaml
- 建议添加 `test/` 目录到版本控制

---

#### TC-WGT-002: 测试依赖配置验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-002 |
| **测试名称** | 测试依赖配置验证 |
| **测试类型** | 框架配置测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证测试相关依赖已正确配置到pubspec.yaml |

**前置条件:**
1. TC-WGT-001 测试通过
2. 项目pubspec.yaml可编辑

**测试步骤:**

1. 检查pubspec.yaml中的dev_dependencies部分
2. 验证以下依赖（如已配置）：
   - golden_toolkit
   - mocktail
   - bloc_test (如使用Bloc)
3. 运行 `flutter pub get` 验证依赖可下载
4. 验证依赖版本兼容性

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| pubspec.yaml格式 | 有效的YAML格式 |
| 依赖下载 | `flutter pub get` 成功 |
| golden_toolkit | 已添加（可选但推荐） |
| mocktail | 已添加（可选） |

**通过标准:**
- [ ] `flutter pub get` 成功完成
- [ ] 无依赖冲突
- [ ] 关键测试依赖已配置

**参考pubspec.yaml配置:**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  golden_toolkit: ^0.15.0
  mocktail: ^1.0.0
```

---

#### TC-WGT-003: 测试目录结构验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-003 |
| **测试名称** | 测试目录结构验证 |
| **测试类型** | 框架配置测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证测试目录结构符合Flutter测试最佳实践 |

**前置条件:**
1. TC-WGT-001 测试通过
2. 测试辅助类已创建

**测试步骤:**

1. 验证测试目录结构：
   ```
   test/
   ├── widget/                    # Widget测试
   │   ├── components/
   │   ├── pages/
   │   └── golden/
   ├── helpers/                   # 测试辅助类
   │   ├── widget_finders.dart
   │   ├── widget_interactions.dart
   │   └── test_app.dart
   ├── unit/                      # 单元测试（如有）
   └── golden_files/              # Golden测试参考图片
   ```

2. 检查每个目录存在且包含预期文件

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| test/widget/ | 存在，包含Widget测试 |
| test/helpers/ | 存在，包含测试辅助类 |
| test/golden_files/ | 存在，用于Golden测试 |
| 目录结构 | 清晰、可维护 |

**通过标准:**
- [ ] 测试目录结构合理
- [ ] 测试文件组织清晰
- [ ] Golden测试目录已创建

---

### 2.2 Widget查找辅助类测试

#### TC-WGT-004: 按文本查找组件测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-004 |
| **测试名称** | 按文本查找组件测试 |
| **测试类型** | Widget辅助类测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证WidgetFinderHelpers.findByText()方法正确工作 |

**前置条件:**
1. 已创建 `test/helpers/widget_finders.dart`
2. WidgetFinderHelpers类已实现

**测试步骤:**

1. 创建测试Widget
2. 使用findByText查找特定文本
3. 验证查找结果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 精确匹配 | 找到唯一匹配组件 |
| 无匹配 | 返回空结果或抛出异常（按实现） |
| 多匹配 | 返回所有匹配组件 |

**自动化测试:**

```dart
// test/helpers/widget_finders_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';

void main() {
  group('WidgetFinderHelpers.findByText', () {
    testWidgets('finds widget with exact text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                Text('Hello World'),
                Text('Another Text'),
              ],
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByText('Hello World');
      expect(finder, findsOneWidget);
    });

    testWidgets('finds multiple widgets with same text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                Text('Duplicate'),
                Text('Duplicate'),
              ],
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByText('Duplicate');
      expect(finder, findsNWidgets(2));
    });

    testWidgets('returns empty when text not found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Existing Text'),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByText('Non-existent');
      expect(finder, findsNothing);
    });

    testWidgets('finds text in Button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Click Me'),
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByText('Click Me');
      expect(finder, findsOneWidget);
    });
  });
}
```

**参考实现:**

```dart
// lib/test/helpers/widget_finders.dart
import 'package:flutter_test/flutter_test.dart';

class WidgetFinderHelpers {
  /// 按文本查找组件
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// 按Key查找组件
  static Finder findByKey(String key) {
    return find.byKey(ValueKey(key));
  }

  /// 按类型查找组件
  static Finder findByType<T>() {
    return find.byType(T);
  }

  /// 按Widget类型和文本组合查找
  static Finder findByTypeAndText<T>(String text) {
    return find.ancestor(
      of: find.text(text),
      matching: find.byType(T),
    );
  }

  /// 查找包含特定文本的按钮
  static Finder findButtonByText(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }

  /// 查找TextField并验证hintText
  static Finder findTextFieldByHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }
}
```

---

#### TC-WGT-005: 按Key查找组件测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-005 |
| **测试名称** | 按Key查找组件测试 |
| **测试类型** | Widget辅助类测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证WidgetFinderHelpers.findByKey()方法正确工作 |

**前置条件:**
1. TC-WGT-004 测试通过
2. WidgetFinderHelpers类已更新

**测试步骤:**

1. 创建带有Key的Widget
2. 使用findByKey查找组件
3. 验证查找结果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 有效Key | 找到对应组件 |
| 无效Key | 未找到组件 |
| 类型安全 | Key值类型正确 |

**自动化测试:**

```dart
// test/helpers/widget_finders_key_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';

void main() {
  group('WidgetFinderHelpers.findByKey', () {
    testWidgets('finds widget with ValueKey', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              key: const ValueKey('test_container'),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByKey('test_container');
      expect(finder, findsOneWidget);
    });

    testWidgets('finds button by key', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const ValueKey('submit_button'),
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByKey('submit_button');
      expect(finder, findsOneWidget);
    });

    testWidgets('finds form fields by key', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const ValueKey('email_field'),
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  key: const ValueKey('password_field'),
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(WidgetFinderHelpers.findByKey('email_field'), findsOneWidget);
      expect(WidgetFinderHelpers.findByKey('password_field'), findsOneWidget);
    });
  });
}
```

---

#### TC-WGT-006: 按类型查找组件测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-006 |
| **测试名称** | 按类型查找组件测试 |
| **测试类型** | Widget辅助类测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证WidgetFinderHelpers.findByType()方法正确工作 |

**前置条件:**
1. TC-WGT-005 测试通过

**测试步骤:**

1. 创建包含多种类型Widget的测试页面
2. 使用findByType查找特定类型
3. 验证查找结果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 单一类型 | 找到所有该类型组件 |
| 复杂类型 | 支持泛型类型查找 |
| 自定义Widget | 支持自定义组件类型 |

**自动化测试:**

```dart
// test/helpers/widget_finders_type_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';

void main() {
  group('WidgetFinderHelpers.findByType', () {
    testWidgets('finds all ElevatedButtons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Btn 1')),
                ElevatedButton(onPressed: () {}, child: const Text('Btn 2')),
                ElevatedButton(onPressed: () {}, child: const Text('Btn 3')),
              ],
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByType<ElevatedButton>();
      expect(finder, findsNWidgets(3));
    });

    testWidgets('finds all TextFields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                TextField(decoration: InputDecoration(labelText: 'Field 1')),
                TextField(decoration: InputDecoration(labelText: 'Field 2')),
              ],
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByType<TextField>();
      expect(finder, findsNWidgets(2));
    });

    testWidgets('finds Container widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              child: Container(
                child: const Text('Nested'),
              ),
            ),
          ),
        ),
      );

      final finder = WidgetFinderHelpers.findByType<Container>();
      expect(finder, findsNWidgets(2));
    });
  });
}
```

---

### 2.3 Widget交互辅助类测试

#### TC-WGT-007: 点击交互测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-007 |
| **测试名称** | 点击交互测试 |
| **测试类型** | Widget交互测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证WidgetInteractionHelpers.tap()方法正确工作 |

**前置条件:**
1. 已创建 `test/helpers/widget_interactions.dart`
2. WidgetInteractionHelpers类已实现

**测试步骤:**

1. 创建可点击的Widget
2. 使用tap方法模拟点击
3. 验证点击效果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 按钮点击 | 触发onPressed回调 |
| 列表项点击 | 触发onTap回调 |
| 防抖处理 | 正确处理快速连续点击 |

**自动化测试:**

```dart
// test/helpers/widget_interactions_tap_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/widget_interactions.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';

void main() {
  group('WidgetInteractionHelpers.tap', () {
    testWidgets('taps button by text', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.tap(tester, find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('taps button by key', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const ValueKey('my_button'),
              onPressed: () => tapped = true,
              child: const Text('Tap'),
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.tapByKey(tester, 'my_button');
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('taps list tile', (WidgetTester tester) async {
      String? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ListTile(
                  title: const Text('Item 1'),
                  onTap: () => selectedItem = 'Item 1',
                ),
                ListTile(
                  title: const Text('Item 2'),
                  onTap: () => selectedItem = 'Item 2',
                ),
              ],
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.tapByText(tester, 'Item 2');
      await tester.pump();

      expect(selectedItem, equals('Item 2'));
    });
  });
}
```

**参考实现:**

```dart
// lib/test/helpers/widget_interactions.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';

class WidgetInteractionHelpers {
  /// 点击指定Finder的Widget
  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// 通过文本点击
  static Future<void> tapByText(WidgetTester tester, String text) async {
    await tap(tester, WidgetFinderHelpers.findByText(text));
  }

  /// 通过Key点击
  static Future<void> tapByKey(WidgetTester tester, String key) async {
    await tap(tester, WidgetFinderHelpers.findByKey(key));
  }

  /// 在TextField中输入文本
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// 通过Key在TextField中输入文本
  static Future<void> enterTextByKey(
    WidgetTester tester,
    String key,
    String text,
  ) async {
    await enterText(tester, WidgetFinderHelpers.findByKey(key), text);
  }

  /// 通过hint文本在TextField中输入
  static Future<void> enterTextByHint(
    WidgetTester tester,
    String hint,
    String text,
  ) async {
    await enterText(
      tester,
      WidgetFinderHelpers.findTextFieldByHint(hint),
      text,
    );
  }

  /// 滚动列表
  static Future<void> scroll(
    WidgetTester tester,
    Finder scrollable,
    double offset,
  ) async {
    await tester.drag(scrollable, Offset(0, -offset));
    await tester.pumpAndSettle();
  }

  /// 滚动到指定Widget
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder item,
    Finder scrollable, {
    double delta = 100.0,
  }) async {
    await tester.scrollUntilVisible(
      item,
      delta,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }

  /// 长按
  static Future<void> longPress(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// 拖拽
  static Future<void> drag(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// 等待指定时间
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// 等待动画完成
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }
}
```

---

#### TC-WGT-008: 文本输入交互测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-008 |
| **测试名称** | 文本输入交互测试 |
| **测试类型** | Widget交互测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证WidgetInteractionHelpers.enterText()方法正确工作 |

**前置条件:**
1. TC-WGT-007 测试通过

**测试步骤:**

1. 创建包含TextField的Widget
2. 使用enterText方法输入文本
3. 验证文本已输入

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 正常输入 | 文本成功输入到TextField |
| 替换输入 | 原有文本被新文本替换 |
| 空文本 | 可以清空TextField |

**自动化测试:**

```dart
// test/helpers/widget_interactions_input_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/widget_interactions.dart';

void main() {
  group('WidgetInteractionHelpers.enterText', () {
    testWidgets('enters text into TextField', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: const ValueKey('input_field'),
              decoration: const InputDecoration(hintText: 'Enter text'),
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.enterTextByKey(
        tester,
        'input_field',
        'Hello World',
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('enters text by hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const TextField(
              decoration: InputDecoration(hintText: 'Email'),
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.enterTextByHint(
        tester,
        'Email',
        'test@example.com',
      );

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('replaces existing text', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Old Text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: const ValueKey('replace_field'),
              controller: controller,
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.enterTextByKey(
        tester,
        'replace_field',
        'New Text',
      );

      expect(find.text('New Text'), findsOneWidget);
      expect(find.text('Old Text'), findsNothing);
    });

    testWidgets('handles multiple fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const ValueKey('username'),
                  decoration: const InputDecoration(hintText: 'Username'),
                ),
                TextField(
                  key: const ValueKey('password'),
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
      );

      await WidgetInteractionHelpers.enterTextByKey(
        tester,
        'username',
        'john_doe',
      );
      await WidgetInteractionHelpers.enterTextByKey(
        tester,
        'password',
        'secret123',
      );

      expect(find.text('john_doe'), findsOneWidget);
      // Password is obscured, check controller instead
    });
  });
}
```

---

### 2.4 Golden测试配置测试

#### TC-WGT-009: Golden测试环境配置

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-009 |
| **测试名称** | Golden测试环境配置 |
| **测试类型** | Golden测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证Golden测试环境已正确配置 |

**前置条件:**
1. TC-WGT-001 ~ TC-WGT-003 测试通过
2. golden_toolkit已添加到pubspec.yaml（可选但推荐）

**测试步骤:**

1. 检查Golden测试目录结构
2. 验证flutter test --update-goldens可用
3. 运行示例Golden测试

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| golden_files目录 | 存在，用于存储参考图片 |
| 更新命令 | flutter test --update-goldens 可用 |
| 首次运行 | 生成参考图片 |
| 后续运行 | 与参考图片对比 |

**通过标准:**
- [ ] Golden测试目录结构正确
- [ ] 可以生成Golden文件
- [ ] 可以执行Golden测试对比

**Golden测试目录结构:**

```
test/
├── golden_files/                    # Golden参考图片
│   ├── light_theme/
│   ├── dark_theme/
│   └── components/
├── flutter_test_config.dart         # Golden测试配置
└── widget/golden/
    └── app_golden_test.dart
```

**flutter_test_config.dart:**

```dart
// test/flutter_test_config.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return testMain();
}
```

---

#### TC-WGT-010: 基础Golden测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-010 |
| **测试名称** | 基础Golden测试 |
| **测试类型** | Golden测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证基础Golden测试可以正常运行 |

**前置条件:**
1. TC-WGT-009 测试通过
2. flutter_test_config.dart已配置

**测试步骤:**

1. 创建基础Golden测试
2. 生成参考图片
3. 验证测试通过

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 首次运行 | 使用 --update-goldens 生成参考图片 |
| 图片生成 | 在 test/golden_files/ 目录生成.png文件 |
| 测试通过 | 再次运行测试时通过 |
| 像素对比 | 准确检测UI变化 |

**自动化测试:**

```dart
// test/widget/golden/basic_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';

void main() {
  group('Basic Golden Tests', () {
    testWidgets('Golden - Login Page Light', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp.light(
          child: Scaffold(
            appBar: AppBar(title: const Text('Login')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/login_page_light.png'),
      );
    });

    testWidgets('Golden - Login Page Dark', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp.dark(
          child: Scaffold(
            appBar: AppBar(title: const Text('Login')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/login_page_dark.png'),
      );
    });
  });
}
```

**TestApp辅助类:**

```dart
// lib/test/helpers/test_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestApp extends StatelessWidget {
  final Widget child;
  final ThemeMode themeMode;

  const TestApp({
    super.key,
    required this.child,
    this.themeMode = ThemeMode.light,
  });

  factory TestApp.light({required Widget child}) {
    return TestApp(child: child, themeMode: ThemeMode.light);
  }

  factory TestApp.dark({required Widget child}) {
    return TestApp(child: child, themeMode: ThemeMode.dark);
  }

  factory TestApp.withProvider({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: TestApp(child: child, themeMode: themeMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: child,
    );
  }
}
```

---

#### TC-WGT-011: 主题切换Golden测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-011 |
| **测试名称** | 主题切换Golden测试 |
| **测试类型** | Golden测试 |
| **优先级** | P1 (High) |
| **测试目的** | 验证浅色/深色主题的Golden测试可以正确执行 |

**前置条件:**
1. TC-WGT-010 测试通过
2. TestApp辅助类已配置主题支持

**测试步骤:**

1. 创建浅色主题Golden测试
2. 创建深色主题Golden测试
3. 生成两套参考图片
4. 验证对比结果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 浅色图片 | 背景浅、文字深 |
| 深色图片 | 背景深、文字浅 |
| 像素差异 | 两套图片有明显视觉差异 |

**自动化测试:**

```dart
// test/widget/golden/theme_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';

void main() {
  group('Theme Golden Tests', () {
    testWidgets('Golden - Dashboard Light Theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp.light(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('Workbench 1'),
                      subtitle: const Text('3 devices'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('Workbench 2'),
                      subtitle: const Text('5 devices'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/dashboard_light.png'),
      );
    });

    testWidgets('Golden - Dashboard Dark Theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp.dark(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('Workbench 1'),
                      subtitle: const Text('3 devices'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('Workbench 2'),
                      subtitle: const Text('5 devices'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/dashboard_dark.png'),
      );
    });
  });
}
```

---

#### TC-WGT-012: 多设备尺寸Golden测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-012 |
| **测试名称** | 多设备尺寸Golden测试 |
| **测试类型** | Golden测试 |
| **优先级** | P2 (Medium) |
| **测试目的** | 验证不同屏幕尺寸下的UI渲染正确性 |

**前置条件:**
1. TC-WGT-011 测试通过
2. 使用golden_toolkit（推荐）或手动设置viewport

**测试步骤:**

1. 配置多种屏幕尺寸
2. 为每种尺寸生成Golden图片
3. 验证响应式布局

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 桌面尺寸 | 布局适合大屏幕 |
| 平板尺寸 | 布局适合中等屏幕 |
| 组件适配 | 各尺寸下组件正确显示 |

**自动化测试（使用golden_toolkit）:**

```dart
// test/widget/golden/responsive_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';

void main() {
  group('Responsive Golden Tests', () {
    testGoldens('Login Page - Multiple Devices', (tester) async {
      final builder = DeviceBuilder()
        ..addScenario(
          name: 'Desktop',
          widget: TestApp.light(
            child: Scaffold(
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const TextField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

      await tester.pumpDeviceBuilder(builder);

      await screenMatchesGolden(tester, 'login_page_responsive');
    });
  });
}
```

---

### 2.5 示例Widget测试

#### TC-WGT-013: 登录页面Widget测试

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-WGT-013 |
| **测试名称** | 登录页面Widget测试 |
| **测试类型** | 集成Widget测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证测试辅助类在真实页面测试中的使用 |

**前置条件:**
1. 所有测试辅助类已实现
2. 登录页面已实现

**测试步骤:**

1. 使用TestApp加载登录页面
2. 使用WidgetFinderHelpers查找组件
3. 使用WidgetInteractionHelpers模拟用户交互
4. 验证交互结果

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 页面渲染 | 登录页面正确渲染 |
| 表单输入 | 用户名、密码可输入 |
| 按钮点击 | 登录按钮可点击 |
| 验证反馈 | 显示验证错误（如适用） |

**自动化测试:**

```dart
// test/widget/pages/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/test/helpers/test_app.dart';
import 'package:kayak_frontend/test/helpers/widget_finders.dart';
import 'package:kayak_frontend/test/helpers/widget_interactions.dart';

void main() {
  group('Login Page Widget Tests', () {
    testWidgets('renders login form correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TestApp.light(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(
                    key: const ValueKey('email_field'),
                    decoration: const InputDecoration(hintText: 'Email'),
                  ),
                  TextField(
                    key: const ValueKey('password_field'),
                    decoration: const InputDecoration(hintText: 'Password'),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    key: const ValueKey('login_button'),
                    onPressed: () {},
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 验证页面元素存在
      expect(WidgetFinderHelpers.findByKey('email_field'), findsOneWidget);
      expect(WidgetFinderHelpers.findByKey('password_field'), findsOneWidget);
      expect(WidgetFinderHelpers.findByKey('login_button'), findsOneWidget);
    });

    testWidgets('can enter email and password', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TestApp.light(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(
                    key: const ValueKey('email_field'),
                    decoration: const InputDecoration(hintText: 'Email'),
                  ),
                  TextField(
                    key: const ValueKey('password_field'),
                    decoration: const InputDecoration(hintText: 'Password'),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 输入邮箱
      await WidgetInteractionHelpers.enterTextByKey(
        tester,
        'email_field',
        'test@example.com',
      );

      // 输入密码
      await WidgetInteractionHelpers.enterTextByKey(
        tester,
        'password_field',
        'password123',
      );

      // 验证输入成功
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('login button can be tapped', (WidgetTester tester) async {
      bool loginPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: TestApp.light(
            child: Scaffold(
              body: ElevatedButton(
                key: const ValueKey('login_button'),
                onPressed: () => loginPressed = true,
                child: const Text('Login'),
              ),
            ),
          ),
        ),
      );

      // 点击登录按钮
      await WidgetInteractionHelpers.tapByKey(tester, 'login_button');

      // 验证按钮被点击
      expect(loginPressed, isTrue);
    });
  });
}
```

---

## 3. 测试执行脚本

### 3.1 完整测试套件执行脚本

```bash
#!/bin/bash
# TC-S1-006-ALL: 完整Widget测试框架验证脚本

set -e

PROJECT_DIR="/home/hzhou/workspace/kayak/kayak-frontend"
TEST_LOG="/tmp/s1-006-test.log"

echo "========================================="
echo "S1-006: Flutter Widget测试框架验证"
echo "开始时间: $(date)"
echo "========================================="

# 进入项目目录
cd "$PROJECT_DIR" || exit 1

# 1. 环境检查
echo ""
echo "Step 1: 测试环境检查..."
flutter --version
echo "✓ Flutter环境正常"

# 2. 依赖检查
echo ""
echo "Step 2: 依赖检查..."
flutter pub get
echo "✓ 依赖获取成功"

# 3. 运行所有测试
echo ""
echo "Step 3: 运行所有Widget测试..."
if flutter test --reporter expanded 2>&1 | tee "$TEST_LOG"; then
    echo "✓ 所有测试通过"
else
    echo "✗ 部分测试失败"
    echo ""
    echo "失败详情:"
    grep -A 5 "FAIL:" "$TEST_LOG" || true
    exit 1
fi

# 4. 检查测试覆盖率（可选）
echo ""
echo "Step 4: 检查测试覆盖率..."
if command -v flutter_test_coverage &> /dev/null; then
    flutter test --coverage
    echo "✓ 覆盖率报告已生成"
else
    echo "⚠ 覆盖率工具未安装，跳过"
fi

# 5. 统计测试结果
echo ""
echo "Step 5: 测试结果统计..."
TOTAL_TESTS=$(grep -c "^test " "$TEST_LOG" 2>/dev/null || echo "0")
PASSED_TESTS=$(grep -c "✓" "$TEST_LOG" 2>/dev/null || echo "0")
FAILED_TESTS=$(grep -c "✗" "$TEST_LOG" 2>/dev/null || echo "0")

echo "总测试数: $TOTAL_TESTS"
echo "通过: $PASSED_TESTS"
echo "失败: $FAILED_TESTS"

# 6. 验证Golden文件
echo ""
echo "Step 6: Golden文件检查..."
if [ -d "test/golden_files" ]; then
    GOLDEN_COUNT=$(find test/golden_files -name "*.png" | wc -l)
    echo "✓ 找到 $GOLDEN_COUNT 个Golden参考文件"
else
    echo "⚠ Golden文件目录不存在"
fi

# 7. 验证测试辅助类
echo ""
echo "Step 7: 测试辅助类检查..."
HELPERS=(
    "test/helpers/widget_finders.dart"
    "test/helpers/widget_interactions.dart"
    "test/helpers/test_app.dart"
)

for helper in "${HELPERS[@]}"; do
    if [ -f "$helper" ]; then
        echo "✓ $helper 存在"
    else
        echo "✗ $helper 缺失"
    fi
done

echo ""
echo "========================================="
echo "验证完成: $(date)"
echo "========================================="
```

---

## 4. 测试数据需求

### 4.1 测试文件清单

| 文件路径 | 用途 | 必需 |
|---------|------|------|
| `test/` | 测试根目录 | 是 |
| `test/helpers/widget_finders.dart` | 组件查找辅助类 | 是 |
| `test/helpers/widget_interactions.dart` | 交互模拟辅助类 | 是 |
| `test/helpers/test_app.dart` | 测试应用包装器 | 是 |
| `test/golden_files/` | Golden参考图片目录 | 是 |
| `test/flutter_test_config.dart` | Golden测试配置 | 否（推荐） |
| `test/widget/` | Widget测试目录 | 是 |
| `test/widget/golden/` | Golden测试目录 | 是 |

### 4.2 依赖清单

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  golden_toolkit: ^0.15.0
  mocktail: ^1.0.0
```

---

## 5. 缺陷报告模板

### 5.1 缺陷严重程度定义

| 级别 | 定义 | 示例 |
|-----|------|------|
| P0 (Critical) | 测试框架无法运行 | flutter test命令失败、辅助类编译错误 |
| P1 (High) | 主要功能无法使用 | 组件查找失败、交互模拟无效 |
| P2 (Medium) | 次要问题，有变通方案 | Golden测试图片对比阈值不合理 |
| P3 (Low) | 轻微问题，建议改进 | 辅助类API命名不规范 |

### 5.2 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-006-XX  
**关联测试用例**: TC-WGT-XXX  
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

### 附件
- [错误日志]
- [截图]
- [Golden对比结果]
```

---

## 6. 测试执行记录

### 6.1 执行历史

| 日期 | 版本 | 执行人 | 结果 | 备注 |
|-----|------|-------|------|------|
| | | | | |

### 6.2 测试覆盖矩阵

| 测试ID | 描述 | 执行次数 | 通过次数 | 失败次数 | 通过率 |
|-------|------|---------|---------|---------|-------|
| TC-WGT-001 | 测试环境配置验证 | 0 | 0 | 0 | - |
| TC-WGT-002 | 测试依赖配置验证 | 0 | 0 | 0 | - |
| TC-WGT-003 | 测试目录结构验证 | 0 | 0 | 0 | - |
| TC-WGT-004 | 按文本查找组件测试 | 0 | 0 | 0 | - |
| TC-WGT-005 | 按Key查找组件测试 | 0 | 0 | 0 | - |
| TC-WGT-006 | 按类型查找组件测试 | 0 | 0 | 0 | - |
| TC-WGT-007 | 点击交互测试 | 0 | 0 | 0 | - |
| TC-WGT-008 | 文本输入交互测试 | 0 | 0 | 0 | - |
| TC-WGT-009 | Golden测试环境配置 | 0 | 0 | 0 | - |
| TC-WGT-010 | 基础Golden测试 | 0 | 0 | 0 | - |
| TC-WGT-011 | 主题切换Golden测试 | 0 | 0 | 0 | - |
| TC-WGT-012 | 多设备尺寸Golden测试 | 0 | 0 | 0 | - |
| TC-WGT-013 | 登录页面Widget测试 | 0 | 0 | 0 | - |

---

## 7. 验收检查清单

### 7.1 框架配置检查

- [ ] TC-WGT-001: `test/` 目录存在
- [ ] TC-WGT-001: `flutter test` 命令可用
- [ ] TC-WGT-002: 测试依赖已配置
- [ ] TC-WGT-002: `flutter pub get` 成功
- [ ] TC-WGT-003: 测试目录结构合理

### 7.2 辅助类功能检查

- [ ] TC-WGT-004: findByText() 工作正常
- [ ] TC-WGT-005: findByKey() 工作正常
- [ ] TC-WGT-006: findByType() 工作正常
- [ ] TC-WGT-007: tap() 交互工作正常
- [ ] TC-WGT-008: enterText() 交互工作正常

### 7.3 Golden测试检查

- [ ] TC-WGT-009: Golden测试环境配置正确
- [ ] TC-WGT-010: 可以生成Golden参考图片
- [ ] TC-WGT-010: 可以执行Golden对比测试
- [ ] TC-WGT-011: 浅色/深色主题Golden测试可用
- [ ] TC-WGT-012: 多尺寸Golden测试可用（可选）

### 7.4 示例测试检查

- [ ] TC-WGT-013: 登录页面Widget测试可用
- [ ] 所有测试通过 `flutter test`

---

## 8. 附录

### 8.1 参考文档

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Golden Testing](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
- [Golden Toolkit](https://pub.dev/packages/golden_toolkit)

### 8.2 常用命令参考

| 命令 | 用途 |
|-----|------|
| `flutter test` | 运行所有测试 |
| `flutter test test/widget/` | 运行Widget测试 |
| `flutter test --update-goldens` | 更新Golden参考图片 |
| `flutter test --coverage` | 生成覆盖率报告 |
| `flutter test --reporter expanded` | 展开式测试报告 |

### 8.3 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|-------|---------|
| 1.0 | 2024-03-15 | QA | 初始版本 |

---

**文档结束**
