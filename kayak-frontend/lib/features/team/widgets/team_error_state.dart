/// Team error state widget
library;

import 'package:flutter/material.dart';

/// Team error state component
class TeamErrorState extends StatelessWidget {
  const TeamErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.title = '加载失败',
  });
  final Object error;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (onRetry != null)
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
        ],
      ),
    );
  }
}

/// Team access denied widget
class TeamAccessDenied extends StatelessWidget {
  const TeamAccessDenied({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '没有权限访问该团队',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '您不是该团队的成员，无法查看团队信息',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (onBack != null)
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回团队列表'),
            ),
        ],
      ),
    );
  }
}

/// Team not found widget
class TeamNotFound extends StatelessWidget {
  const TeamNotFound({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '团队不存在',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '该团队可能已被删除或您没有访问权限',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (onBack != null)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回团队列表'),
            ),
        ],
      ),
    );
  }
}
