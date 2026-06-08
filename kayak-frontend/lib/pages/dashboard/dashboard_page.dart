import 'package:flutter/material.dart';

import 'widgets/dashboard_skeleton.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_workbenches_section.dart';
import 'widgets/stats_overview.dart';
import 'widgets/welcome_section.dart';

/// 仪表盘首页组件。
///
/// 包含四个区域，按区域独立容错：
/// 1. 欢迎区域 — 来自 Auth Provider（缓存）
/// 2. 快捷操作卡片 — 静态内容
/// 3. 统计概览 — 来自 Workbench/Experiment API
/// 4. 最近工作台 — 来自 Workbench API
///
/// 路由: `/dashboard` (ShellRoute 内) 或 `/` (重定向)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showSkeleton = true;

  @override
  void initState() {
    super.initState();
    // 显示骨架屏，数据加载完成后自动切换
    _startLoading();
  }

  void _startLoading() async {
    // 模拟最小骨架屏展示时间，避免闪烁
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _showSkeleton = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final padding = isCompact ? 16.0 : (screenWidth < 1200 ? 24.0 : 32.0);
    final maxWidth = screenWidth < 1200 ? double.infinity : 1200.0;

    if (_showSkeleton) {
      return const DashboardSkeleton();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 欢迎区域
              const WelcomeSection(),

              // 2. 快捷操作卡片（静态内容，始终显示）
              const QuickActionsGrid(),

              const SizedBox(height: 24),

              // 3. 统计概览（独立容错）
              const StatsOverview(),

              const SizedBox(height: 24),

              // 4. 最近工作台（独立容错）
              const RecentWorkbenchesSection(),
            ],
          ),
        ),
      ),
    );
  }
}
