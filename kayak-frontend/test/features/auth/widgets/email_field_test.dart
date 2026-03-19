/// 邮箱输入框组件测试

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/auth/widgets/email_field.dart';
import 'package:kayak_frontend/validators/validators.dart';

void main() {
  group('EmailField', () {
    testWidgets('显示邮箱输入框', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EmailField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('邮箱'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('失去焦点时验证邮箱格式', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EmailField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // 输入无效邮箱
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.pump();

      // 失去焦点触发验证
      focusNode.unfocus();
      await tester.pump();

      // 验证错误显示
      expect(find.text('邮箱格式无效'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('输入时清除错误', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EmailField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // 先触发错误
      await tester.enterText(find.byType(TextField), 'invalid');
      focusNode.unfocus();
      await tester.pump();
      expect(find.text('邮箱格式无效'), findsOneWidget);

      // 再输入有效邮箱
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      // 错误应该被清除
      expect(find.text('邮箱格式无效'), findsNothing);

      controller.dispose();
    });
  });
}
