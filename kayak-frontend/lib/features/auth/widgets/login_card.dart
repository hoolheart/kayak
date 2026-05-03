/// 登录卡片容器组件
///
/// 统一的登录卡片样式：SurfaceContainerLow 背景，28px 圆角，带阴影
/// 响应式宽度：Desktop 440px, Tablet 400px, Mobile full-width
library;

import 'package:flutter/material.dart';

/// 登录卡片容器组件
class LoginCard extends StatelessWidget {
  const LoginCard({
    super.key,
    required this.child,
  });

  /// 卡片内容（Logo区域 + 表单区域 + 注册链接）
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth;
        final double hPadding;
        final double vPadding;

        if (constraints.maxWidth >= 1280) {
          cardWidth = 440;
          hPadding = 40;
          vPadding = 32;
        } else if (constraints.maxWidth >= 768) {
          cardWidth = 400;
          hPadding = 32;
          vPadding = 24;
        } else {
          cardWidth = constraints.maxWidth - 32;
          hPadding = 24;
          vPadding = 16;
        }

        return Center(
          child: Container(
            width: cardWidth,
            padding: EdgeInsets.symmetric(
              horizontal: hPadding,
              vertical: vPadding,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.32)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isDark ? 4 : 6,
                  offset: Offset(0, isDark ? 2 : 3),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}
