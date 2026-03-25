import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/widget_interactions.dart';
import '../../helpers/widget_finders.dart';

void main() {
  group('WidgetInteractionHelpers', () {
    group('tap', () {
      testWidgets('taps button by finder', (WidgetTester tester) async {
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

      testWidgets('taps button by text', (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Click Me'),
              ),
            ),
          ),
        );

        await WidgetInteractionHelpers.tapByText(tester, 'Click Me');
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

    group('enterText', () {
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

      testWidgets('enters text by label', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const TextField(
                decoration: InputDecoration(labelText: 'Username'),
              ),
            ),
          ),
        );

        await WidgetInteractionHelpers.enterTextByLabel(
          tester,
          'Username',
          'john_doe',
        );

        expect(find.text('john_doe'), findsOneWidget);
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
      });
    });

    group('scroll', () {
      testWidgets('scrolls list', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ),
        );

        // 初始状态应该能看到Item 0
        expect(find.text('Item 0'), findsOneWidget);

        // 滚动
        await WidgetInteractionHelpers.scroll(
          tester,
          find.byType(ListView),
          500.0,
        );

        // 滚动后Item 0应该不在视图内
        expect(find.text('Item 0'), findsNothing);
      });

      testWidgets('scrollUntilVisible brings item into view',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ),
        );

        // Item 50 初始不可见
        expect(find.text('Item 50'), findsNothing);

        // 滚动直到Item 50可见
        // 注意：ListView内部创建Scrollable，需要使用find.byType(Scrollable)
        await WidgetInteractionHelpers.scrollUntilVisible(
          tester,
          find.text('Item 50'),
          find.byType(Scrollable),
        );

        // 现在应该能看到Item 50
        expect(find.text('Item 50'), findsOneWidget);
      });
    });

    group('longPress', () {
      testWidgets('performs long press', (WidgetTester tester) async {
        bool longPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onLongPress: () => longPressed = true,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        await WidgetInteractionHelpers.longPress(
            tester, find.byType(Container));

        expect(longPressed, isTrue);
      });
    });

    group('drag', () {
      testWidgets('drags widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onPanEnd: (details) {
                  // Drag completed - velocity available in details
                },
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        await WidgetInteractionHelpers.drag(
          tester,
          find.byType(Container),
          const Offset(100, 100),
        );

        // 拖拽完成后，widget应该还在
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('wait and pumpAndSettle', () {
      testWidgets('waits for duration', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('Test'),
            ),
          ),
        );

        // 注意：在Widget测试中，pump(duration)只推进模拟时钟，不等待真实时间
        // 这里测试方法能正常执行而不抛出异常
        await WidgetInteractionHelpers.wait(
            tester, const Duration(milliseconds: 100));

        // 验证widget树仍然正常
        expect(find.text('Test'), findsOneWidget);
      });

      testWidgets('pumpAndSettle waits for animations',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 100),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: const Text('Animated'),
                  );
                },
              ),
            ),
          ),
        );

        await WidgetInteractionHelpers.pumpAndSettle(tester);

        // 动画完成后，文本应该完全可见
        expect(find.text('Animated'), findsOneWidget);
      });
    });

    group('clearTextField', () {
      testWidgets('clears text field', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextField(
                key: const ValueKey('clear_field'),
                controller: TextEditingController(text: 'Initial Text'),
              ),
            ),
          ),
        );

        expect(find.text('Initial Text'), findsOneWidget);

        await WidgetInteractionHelpers.clearTextField(
          tester,
          WidgetFinderHelpers.findByKey('clear_field'),
        );

        expect(find.text('Initial Text'), findsNothing);
      });
    });
  });
}
