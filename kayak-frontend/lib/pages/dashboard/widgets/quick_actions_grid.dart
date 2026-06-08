import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/app_localizations.dart';
import 'quick_action_card.dart';

/// 快捷操作卡片网格组件。
///
/// 渲染 4 张快捷操作卡片，响应式布局：
/// - Desktop: 4 列
/// - Mobile/Tablet: 2 列
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  /// 快捷操作卡片定义
  static const _cards = [
    _QuickActionItem(
      icon: Icons.biotech,
      titleKey: 'quickActionExperimentConsole',
      subtitleKey: 'quickActionExperimentConsoleSub',
      route: '/experiments',
    ),
    _QuickActionItem(
      icon: Icons.science,
      titleKey: 'quickActionMethods',
      subtitleKey: 'quickActionMethodsSub',
      route: '/methods',
    ),
    _QuickActionItem(
      icon: Icons.build,
      titleKey: 'quickActionWorkbenches',
      subtitleKey: 'quickActionWorkbenchesSub',
      route: '/workbenches',
    ),
    _QuickActionItem(
      icon: Icons.analytics,
      titleKey: 'quickActionDataAnalysis',
      subtitleKey: 'quickActionDataAnalysisSub',
      route: '/analysis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final crossAxisCount = screenWidth < 600 ? 2 : 4;
    final gap = screenWidth < 600 ? 8.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            // 移动端用更小的宽高比（=更高的卡片），为文字留出空间
            childAspectRatio: isCompact ? 1.15 : 1.5,
          ),
          itemCount: _cards.length,
          itemBuilder: (context, index) {
            final card = _cards[index];
            return QuickActionCard(
              icon: card.icon,
              title: _getLocalizedTitle(loc, card.titleKey),
              subtitle: _getLocalizedSubtitle(loc, card.subtitleKey),
              onTap: () => context.go(card.route),
              compact: isCompact,
            );
          },
        );
      },
    );
  }

  String _getLocalizedTitle(AppLocalizations loc, String key) {
    switch (key) {
      case 'quickActionExperimentConsole':
        return loc.quickActionExperimentConsole;
      case 'quickActionMethods':
        return loc.quickActionMethods;
      case 'quickActionWorkbenches':
        return loc.quickActionWorkbenches;
      case 'quickActionDataAnalysis':
        return loc.quickActionDataAnalysis;
      default:
        return key;
    }
  }

  String _getLocalizedSubtitle(AppLocalizations loc, String key) {
    switch (key) {
      case 'quickActionExperimentConsoleSub':
        return loc.quickActionExperimentConsoleSub;
      case 'quickActionMethodsSub':
        return loc.quickActionMethodsSub;
      case 'quickActionWorkbenchesSub':
        return loc.quickActionWorkbenchesSub;
      case 'quickActionDataAnalysisSub':
        return loc.quickActionDataAnalysisSub;
      default:
        return key;
    }
  }
}

/// 快捷操作卡片数据定义。
class _QuickActionItem {
  const _QuickActionItem({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.route,
  });

  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String route;
}
