import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/widget_finders.dart';

void main() {
  group('WidgetFinderHelpers', () {
    group('findByText', () {
      testWidgets('finds widget with exact text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
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

      testWidgets('finds multiple widgets with same text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
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

      testWidgets('returns empty when text not found',
          (WidgetTester tester) async {
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

    group('findByKey', () {
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
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(
                    key: ValueKey('email_field'),
                    decoration: InputDecoration(hintText: 'Email'),
                  ),
                  TextField(
                    key: ValueKey('password_field'),
                    decoration: InputDecoration(hintText: 'Password'),
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

    group('findByType', () {
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
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
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
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(child: Text('Widget 1')),
                  SizedBox(child: Text('Widget 2')),
                ],
              ),
            ),
          ),
        );

        final finder = WidgetFinderHelpers.findByType<SizedBox>();
        expect(finder, findsNWidgets(2));
      });
    });

    group('findByTypeAndText', () {
      testWidgets('finds ElevatedButton with specific text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Button 1'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Button 2'),
                  ),
                ],
              ),
            ),
          ),
        );

        final finder =
            WidgetFinderHelpers.findByTypeAndText<ElevatedButton>('Button 1');
        expect(finder, findsOneWidget);
      });
    });

    group('findButtonByText', () {
      testWidgets('finds button by text content', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ),
        );

        final finder = WidgetFinderHelpers.findButtonByText('Submit');
        expect(finder, findsOneWidget);
      });
    });

    group('findTextFieldByHint', () {
      testWidgets('finds TextField by hint text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextField(
                decoration: InputDecoration(hintText: 'Enter email'),
              ),
            ),
          ),
        );

        final finder = WidgetFinderHelpers.findTextFieldByHint('Enter email');
        expect(finder, findsOneWidget);
      });
    });

    group('findTextFieldByLabel', () {
      testWidgets('finds TextField by label text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ),
          ),
        );

        final finder = WidgetFinderHelpers.findTextFieldByLabel('Email');
        expect(finder, findsOneWidget);
      });
    });

    group('findAncestor and findDescendant', () {
      testWidgets('finds ancestor correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                key: const ValueKey('parent'),
                child: const Text('Child Text'),
              ),
            ),
          ),
        );

        final ancestor = WidgetFinderHelpers.findAncestor(
          finder: find.text('Child Text'),
          matching: find.byKey(const ValueKey('parent')),
        );
        expect(ancestor, findsOneWidget);
      });

      testWidgets('finds descendant correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                key: const ValueKey('parent'),
                child: const Text('Child Text'),
              ),
            ),
          ),
        );

        final descendant = WidgetFinderHelpers.findDescendant(
          finder: find.byKey(const ValueKey('parent')),
          matching: find.text('Child Text'),
        );
        expect(descendant, findsOneWidget);
      });
    });

    group('findsExactly', () {
      testWidgets('matches exact count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Item'),
                  Text('Item'),
                  Text('Item'),
                ],
              ),
            ),
          ),
        );

        final finder = WidgetFinderHelpers.findByText('Item');
        expect(finder, WidgetFinderHelpers.findsExactly(3));
      });
    });
  });
}
