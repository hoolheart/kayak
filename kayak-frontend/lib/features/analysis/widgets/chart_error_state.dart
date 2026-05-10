/// 图表错误状态组件
///
/// 数据加载失败时显示。
library;

import 'package:flutter/material.dart';

import '../theme/chart_colors.dart';

/// 图表错误状态
class ChartErrorState extends StatelessWidget {
  const ChartErrorState({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: colorScheme.chartCanvasBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '数据加载失败',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                errorMessage ??
                    '无法读取试验数据文件，请检查文件是否存在或稍后重试',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage ?? '未知错误'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text('查看详情'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
