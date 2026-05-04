/// Dashboard 欢迎区域组件
///
/// 根据系统时间动态显示问候语：
/// - 5:00-12:00: "早上好"
/// - 12:00-18:00: "下午好"
/// - 18:00-5:00: "晚上好"

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers.dart';
import '../providers/greeting_provider.dart';

/// 欢迎区域组件
class WelcomeSection extends ConsumerWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final userState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final userName = userState.user?.username ?? '用户';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：问候语 + 副标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${greeting.displayName}，$userName',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  greeting.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 右侧：日期时间
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeDisplay(),
              const SizedBox(height: 4),
              Text(
                greeting.dateDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 实时时间显示组件
class _TimeDisplay extends StatefulWidget {
  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  late DateTime _now;
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // 每秒更新一次时间
    _subscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

    return Text(
      timeStr,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFamily: 'monospace',
      ),
    );
  }
}
