import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/core/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayak'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          // 主题切换按钮
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            tooltip: '切换主题',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Kayak 科学研究支持平台',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flutter + Rust 跨平台解决方案',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.go('/workbenches');
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('进入工作台'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                context.go('/settings');
              },
              icon: const Icon(Icons.settings),
              label: const Text('设置'),
            ),
          ],
        ),
      ),
    );
  }
}
