import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

/// TC-FLU-010: Riverpod状态管理集成测试
/// 验证Riverpod状态管理方案已正确配置
void main() {
  group('Riverpod Integration Tests', () {
    testWidgets('App is wrapped with ProviderScope', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const KayakApp());

      expect(
        find.byType(ProviderScope),
        findsOneWidget,
        reason: 'App must be wrapped with ProviderScope for Riverpod to work',
      );
    });

    testWidgets('Can create and read simple provider', (
      WidgetTester tester,
    ) async {
      final testProvider = Provider<String>((ref) => 'Hello Riverpod');

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final value = ref.watch(testProvider);
              return MaterialApp(home: Scaffold(body: Text(value)));
            },
          ),
        ),
      );

      expect(find.text('Hello Riverpod'), findsOneWidget);
    });

    testWidgets('Can create and modify StateProvider', (
      WidgetTester tester,
    ) async {
      final counterProvider = StateProvider<int>((ref) => 0);

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(counterProvider);
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('Count: $count'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(counterProvider.notifier).state++;
                        },
                        child: const Text('Increment'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Tap increment button
      await tester.tap(find.text('Increment'));
      await tester.pump();

      // State should be updated
      expect(find.text('Count: 1'), findsOneWidget);

      // Tap again
      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('Can use FutureProvider', (WidgetTester tester) async {
      final futureProvider = FutureProvider<String>((ref) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'Async Data';
      });

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final asyncValue = ref.watch(futureProvider);
              return MaterialApp(
                home: Scaffold(
                  body: asyncValue.when(
                    data: (data) => Text(data),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for future to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Data should be displayed
      expect(find.text('Async Data'), findsOneWidget);
    });

    testWidgets('ProviderScope can be overridden', (WidgetTester tester) async {
      final configProvider = Provider<String>((ref) => 'default');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [configProvider.overrideWithValue('overridden')],
          child: Consumer(
            builder: (context, ref, child) {
              final value = ref.watch(configProvider);
              return MaterialApp(home: Scaffold(body: Text(value)));
            },
          ),
        ),
      );

      expect(find.text('overridden'), findsOneWidget);
    });

    testWidgets('App structure includes provider accessibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));
      await tester.pumpAndSettle();

      // The app should have loaded without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
