/// 注册页面
///
/// 用户注册功能的主入口页面

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/common/widgets/custom_title_bar.dart';
import 'register_view.dart';

/// 注册页面主入口
class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        CustomTitleBar(),
        Expanded(
          child: Scaffold(
            body: SafeArea(
              child: RegisterView(),
            ),
          ),
        ),
      ],
    );
  }
}
