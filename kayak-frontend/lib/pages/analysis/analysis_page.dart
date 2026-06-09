import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import 'widgets/chart_area.dart';
import 'widgets/control_panel.dart';
import 'widgets/data_table_panel.dart';

/// AnalysisPage — 数据分析与可视化页面
///
/// 路由: `/analysis`
///
/// 功能：
/// 1. 试验/设备/测点级联选择
/// 2. 时间范围和降采样配置
/// 3. 时序折线图展示（fl_chart 1.2.0）
/// 4. 图表交互（缩放/平移/悬停）
/// 5. 数据表格（可选）
class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to force page rebuild when language changes.
    ref.watch(localeProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: SafeArea(
        child: isDesktop || isTablet
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  /// 桌面/平板布局 — 左右分栏
  Widget _buildDesktopLayout(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ControlPanel(),
              ChartArea(),
            ],
          ),
        ),
        DataTablePanel(),
      ],
    );
  }

  /// 移动布局 — 上下堆叠
  ///
  /// 只在 screenWidth <= 600 时调用，因此使用固定 flex 值（Issue 7）。
  Widget _buildMobileLayout(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: ControlPanel(),
            ),
          ),
        ),
        Divider(height: 1),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: ChartArea()),
              DataTablePanel(),
            ],
          ),
        ),
      ],
    );
  }
}
