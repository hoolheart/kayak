import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/widgets/async_value_widget.dart';
import 'package:kayak_frontend/widgets/confirm_dialog.dart';
import 'package:kayak_frontend/widgets/empty_view.dart';
import 'package:kayak_frontend/widgets/error_view.dart';
import 'package:kayak_frontend/widgets/skeleton.dart';
import 'package:kayak_frontend/widgets/toast.dart';

/// MaterialApp 包装器（带本地化支持），用于需要 l10n 的组件测试。
Widget _localizedApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(useMaterial3: true),
    home: home,
  );
}

void main() {
  // ===========================================================================
  // ErrorView golden tests
  // ===========================================================================
  group('ErrorView golden', () {
    testWidgets('ErrorView with description', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        _localizedApp(
          home: Scaffold(
            body: Center(
              child: ErrorView(
                title: '无法加载数据',
                description: '网络连接异常，请检查网络后点击重试',
                onRetry: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_error_view_with_desc.png'),
      );
    });

    testWidgets('ErrorView compact', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        _localizedApp(
          home: Scaffold(
            body: Center(
              child: ErrorView(
                title: '加载失败',
                onRetry: () {},
                compact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_error_view_compact.png'),
      );
    });
  });

  // ===========================================================================
  // EmptyView golden tests
  // ===========================================================================
  group('EmptyView golden', () {
    testWidgets('EmptyView with action button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: EmptyView(
                title: '暂无工作台',
                description: '点击下方按钮创建您的第一个工作台',
                actionButton: ElevatedButton(
                  onPressed: () {},
                  child: const Text('创建工作台'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_empty_view_with_button.png'),
      );
    });

    testWidgets('EmptyView without action button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(
            body: Center(
              child: EmptyView(
                title: '暂无通知',
                description: '有新通知时会在这里显示',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'golden_files/component_empty_view_no_button.png',
        ),
      );
    });
  });

  // ===========================================================================
  // Skeleton golden tests
  // ===========================================================================
  group('Skeleton golden', () {
    testWidgets('Skeleton list type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(
            body: Center(
              child: Skeleton(count: 3),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_skeleton_list.png'),
      );
    });

    testWidgets('Skeleton card type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 600));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(
            body: Center(
              child: Skeleton(type: SkeletonType.card),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_skeleton_card.png'),
      );
    });
  });

  // ===========================================================================
  // ConfirmDialog golden tests
  // ===========================================================================
  group('ConfirmDialog golden', () {
    testWidgets('ConfirmDialog normal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        _localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmDialog.show(
                  context: context,
                  title: '确认操作',
                  description: '确定要执行此操作吗？',
                  onConfirm: () {},
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_confirm_dialog_normal.png'),
      );
    });

    testWidgets('ConfirmDialog danger', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        _localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmDialog.show(
                  context: context,
                  title: '删除工作台',
                  description: '此操作将永久删除该工作台及其所有数据。',
                  onConfirm: () {},
                  isDanger: true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_confirm_dialog_danger.png'),
      );
    });
  });

  // ===========================================================================
  // Toast golden tests
  // ===========================================================================
  group('Toast golden', () {
    Widget buildToastApp({
      required String message,
      required ToastType type,
    }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Builder(
            builder: (context) => Toast.init(
              context,
              ElevatedButton(
                onPressed: () => Toast.show(
                  context: context,
                  message: message,
                  type: type,
                  duration: const Duration(seconds: 10),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Toast success type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        buildToastApp(
          message: '操作成功完成',
          type: ToastType.success,
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_toast_success.png'),
      );
    });

    testWidgets('Toast error type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        buildToastApp(
          message: '操作失败，请重试',
          type: ToastType.error,
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_toast_error.png'),
      );
    });
  });

  // ===========================================================================
  // AsyncValueWidget golden tests
  // ===========================================================================
  group('AsyncValueWidget golden', () {
    testWidgets('AsyncValueWidget loading state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: AsyncValueWidget<int>(
                value: const AsyncValue.loading(),
                dataBuilder: (data) => Text('Data: $data'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_async_value_loading.png'),
      );
    });

    testWidgets('AsyncValueWidget data state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: AsyncValueWidget<List<String>>(
                value: const AsyncValue.data(['item1', 'item2', 'item3']),
                dataBuilder: (data) => ListView(
                  children: data
                      .map((item) => ListTile(title: Text(item)))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden_files/component_async_value_data.png'),
      );
    });
  });
}
