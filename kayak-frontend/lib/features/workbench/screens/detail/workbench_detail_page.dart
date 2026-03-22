/// 工作台详情页面
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/workbench.dart';
import '../../models/workbench_detail_state.dart';
import '../../providers/workbench_detail_provider.dart';
import '../../widgets/detail/detail_header.dart';
import '../../widgets/detail/device_list_tab.dart';
import '../../widgets/detail/settings_tab.dart';

/// 工作台详情页面
///
/// 显示工作台详细信息，包含Tab导航到设备列表和设置
class WorkbenchDetailPage extends ConsumerStatefulWidget {
  final String workbenchId;

  const WorkbenchDetailPage({
    super.key,
    required this.workbenchId,
  });

  @override
  ConsumerState<WorkbenchDetailPage> createState() =>
      _WorkbenchDetailPageState();
}

class _WorkbenchDetailPageState extends ConsumerState<WorkbenchDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(workbenchDetailProvider(widget.workbenchId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home/workbench'),
        ),
        title: Text(detailState.workbench?.name ?? '工作台详情'),
      ),
      body: _buildBody(detailState),
    );
  }

  Widget _buildBody(WorkbenchDetailState detailState) {
    if (detailState.isLoading && detailState.workbench == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (detailState.error != null && detailState.workbench == null) {
      return _buildError(context, detailState.error!);
    }

    if (detailState.workbench == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        DetailHeader(workbench: detailState.workbench!),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.devices_outlined), text: '设备列表'),
            Tab(icon: Icon(Icons.settings_outlined), text: '设置'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const DeviceListTab(),
              SettingsTab(workbench: detailState.workbench!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 解析错误信息
    String errorMessage = '加载失败，请重试';
    if (error.contains('404') || error.contains('NotFound')) {
      errorMessage = '工作台不存在或已被删除';
    } else if (error.contains('403') || error.contains('Forbidden')) {
      errorMessage = '无权访问此工作台';
    }

    return Center(
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
            errorMessage,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(workbenchDetailProvider(widget.workbenchId).notifier)
                  .refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
