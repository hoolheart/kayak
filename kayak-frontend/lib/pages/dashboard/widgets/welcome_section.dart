import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import 'greeting_text.dart';

/// 欢迎区域组件。
///
/// 显示时间段问候语 + 用户名 + 当前日期。
/// 用户名为空时仅显示问候语。
/// 用户名过长时使用省略号截断。
class WelcomeSection extends ConsumerWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 提取用户名（可能为 null）
    final username = authState.asData?.value?.username;

    final now = DateTime.now();
    final greeting = GreetingText.getGreeting(loc, time: now);

    // 格式化日期
    final localeName = Localizations.localeOf(context).languageCode;
    final dateStr = _formatDate(now, localeName);

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 24),
      child: Semantics(
        label:
            'Welcome section, $greeting${username != null ? ', $username' : ''}, $dateStr',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 问候语 + 用户名
            if (username != null && username.isNotEmpty)
              _GreetingRow(
                greeting: greeting,
                username: username,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              )
            else
              Text(
                greeting,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            const SizedBox(height: 8),
            // 日期
            Text(
              dateStr,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据语言代码格式化当前日期。
  String _formatDate(DateTime date, String localeName) {
    final formatter = DateFormat(
      localeName == 'zh' ? 'yyyy年M月d日 EEEE' : 'EEEE, MMMM d, yyyy',
      localeName,
    );
    return formatter.format(date);
  }
}

/// 问候语 + 用户名行。
///
/// 支持长用户名省略号截断。
class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.greeting,
    required this.username,
    required this.style,
  });

  final String greeting;
  final String username;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: greeting),
                const TextSpan(text: '，'),
                TextSpan(
                  text: username,
                ),
              ],
            ),
            style: style,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
