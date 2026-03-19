/// 登录按钮组件测试

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/auth/providers/login_provider.dart';
import 'package:kayak_frontend/features/auth/widgets/login_button.dart';

void main() {
  group('LoginButton', () {
    testWidgets('显示登录文字', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoginButton(),
            ),
          ),
        ),
      );

      expect(find.text('登录'), findsOneWidget);
    });

    testWidgets('在idle状态时按钮存在', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoginButton(),
            ),
          ),
        ),
      );

      // 按钮存在
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('登录'), findsOneWidget);
    });

    testWidgets('在loading状态时显示加载指示器', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoginButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // 触发loading状态
      final container =
          ProviderScope.containerOf(tester.element(find.byType(LoginButton)));
      container.read(loginProvider.notifier).setLoading();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('登录'), findsNothing);
    });
  });
}
