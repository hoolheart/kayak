/// 工作台详情TabBar组件
library;

import 'package:flutter/material.dart';

/// 工作台详情TabBar组件
///
/// 提供设备列表和设置两个Tab
class DetailTabBar extends StatelessWidget {
  const DetailTabBar({
    super.key,
    required this.tabController,
  });
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TabBar(
      controller: tabController,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(
          icon: Icon(Icons.devices_outlined),
          text: '设备列表',
        ),
        Tab(
          icon: Icon(Icons.settings_outlined),
          text: '设置',
        ),
      ],
    );
  }
}
