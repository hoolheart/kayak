/// 密码输入框组件测试

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/auth/widgets/password_field.dart';

void main() {
  group('PasswordField', () {
    testWidgets('显示密码输入框', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PasswordField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('密码默认被遮蔽', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PasswordField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('点击眼睛图标切换密码可见性', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PasswordField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // 默认是隐藏密码
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // 点击切换
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // 现在应该是显示密码
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('失去焦点时验证密码', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PasswordField(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // 输入短密码
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();

      // 失去焦点触发验证
      focusNode.unfocus();
      await tester.pump();

      // 验证错误显示
      expect(find.text('密码至少6个字符'), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });
  });
}
