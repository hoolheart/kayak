import 'package:flutter/material.dart';

import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_workbenches_section.dart';
import 'widgets/stats_overview.dart';
import 'widgets/welcome_section.dart';

/// 仪表盘首页组件。
///
/// 各区域独立控制自己的加载状态（通过各自的 Riverpod Provider），
/// 无需全局 Skeleton 延迟。
///
/// 包含四个区域，按区域独立容错：
/// 1. 欢迎区域 — 来自 Auth Provider（缓存）
/// 2. 快捷操作卡片 — 静态内容
/// 3. 统计概览 — 来自 Workbench/Experiment API（独立 loading/error）
/// 4. 最近工作台 — 来自 Workbench API（独立 loading/error）
///
/// 路由: `/dashboard` (ShellRoute 内) 或 `/` (重定向)
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final padding = isCompact ? 16.0 : (screenWidth < 1200 ? 24.0 : 32.0);
    final maxWidth = screenWidth < 1200 ? double.infinity : 1200.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeSection(),
              QuickActionsGrid(),
              SizedBox(height: 24),
              StatsOverview(),
              SizedBox(height: 24),
              RecentWorkbenchesSection(),
            ],
          ),
        ),
      ),
    );
  }
}
