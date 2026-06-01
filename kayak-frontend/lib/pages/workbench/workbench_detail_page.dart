import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../models/device.dart';
import '../../models/workbench.dart';
import '../../providers/device_provider.dart';
import '../../providers/workbench_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/device_tree.dart';
import '../../widgets/error_view.dart';
import '../../widgets/toast.dart';
import '../point/point_list_widget.dart';
import 'workbench_create_dialog.dart';

/// ============================================================
/// WorkbenchDetailPage — 工作台详情页面
///
/// 路由: /workbenches/:id
///
/// 页面包含：
/// - AppBar（返回按钮 + 标题 + 编辑/删除操作按钮）
/// - 信息区（名称、描述、状态标签、创建/修改时间）
/// - 设备树占位区（左侧面板）
/// - 设备详情占位区（右侧面板）
///
/// 响应式布局：
/// - 桌面 (>1024px)：左右分栏（左侧 280px 固定 + 右侧 flex）
/// - 平板 (600-1024px)：上下堆叠，设备树可折叠
/// - 移动端 (<600px)：上下堆叠，设备树默认折叠，操作按钮收入菜单
/// ============================================================

class WorkbenchDetailPage extends ConsumerStatefulWidget {
  const WorkbenchDetailPage({super.key, required this.id});

  /// 工作台 ID（路由参数）
  final String id;

  @override
  ConsumerState<WorkbenchDetailPage> createState() =>
      _WorkbenchDetailPageState();
}

class _WorkbenchDetailPageState extends ConsumerState<WorkbenchDetailPage> {
  /// 设备树面板是否展开（仅 Tablet 和 Mobile 使用）
  bool _treeExpanded = false;

  /// 当前选中的设备 ID
  String? _selectedDeviceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailState = ref.watch(workbenchDetailProvider(widget.id));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: _buildAppBar(l10n, detailState, isMobile),
      body: detailState.when(
        loading: _buildSkeleton,
        error: (error, _) => _buildErrorView(error, l10n),
        data: (workbench) => _buildContent(workbench, l10n,
            isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
      ),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar(
    AppLocalizations l10n,
    AsyncValue<Workbench> detailState,
    bool isMobile,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/workbenches'),
        tooltip: l10n.cancel,
      ),
      title: Text(
        isMobile ? l10n.workbenchDetailShort : l10n.workbenchDetail,
      ),
      actions: _buildAppBarActions(l10n, detailState, isMobile),
    );
  }

  /// 构建 AppBar 操作按钮
  List<Widget> _buildAppBarActions(
    AppLocalizations l10n,
    AsyncValue<Workbench> detailState,
    bool isMobile,
  ) {
    // 加载中或错误时不可操作
    if (!detailState.hasValue) {
      return [];
    }

    final workbench = detailState.requireValue;

    if (isMobile) {
      // 移动端：溢出菜单
      return [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(workbench, l10n);
            } else if (value == 'delete') {
              _showDeleteConfirm(workbench, l10n);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.edit),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.delete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ];
    }

    // 桌面/平板：直接显示编辑和删除按钮
    return [
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _showEditDialog(workbench, l10n),
        tooltip: l10n.edit,
      ),
      IconButton(
        icon: const Icon(Icons.delete_outlined),
        onPressed: () => _showDeleteConfirm(workbench, l10n),
        tooltip: l10n.delete,
      ),
    ];
  }

  /// 骨架屏（加载状态）
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 信息区骨架
          _buildInfoSkeleton(),
          const SizedBox(height: 16),
          // 主内容区骨架
          _buildContentSkeleton(),
        ],
      ),
    );
  }

  /// 信息区骨架
  Widget _buildInfoSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标占位（48x48）
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              // 名称 + 状态标签
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 22,
                      width: 200,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 60,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 描述占位行1
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(128),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // 描述占位行2
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 元数据占位
          Container(
            height: 12,
            width: 160,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(128),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// 主内容区骨架
  Widget _buildContentSkeleton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧设备树骨架
          Expanded(
            flex: 280,
            child: _buildTreePanelSkeleton(),
          ),
          const SizedBox(width: 16),
          // 右侧详情面板骨架
          Expanded(
            child: _buildDetailPanelSkeleton(),
          ),
        ],
      );
    }

    // 移动/平板端：上下堆叠
    return Column(
      children: [
        _buildTreePanelSkeleton(),
        const SizedBox(height: 16),
        _buildDetailPanelSkeleton(),
      ],
    );
  }

  /// 设备树面板骨架
  Widget _buildTreePanelSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 添加按钮骨架
          Row(
            children: [
              Container(
                height: 20,
                width: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 32,
                width: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 树节点占位（5-6 个）
          ...List.generate(5, (index) {
            return Padding(
              padding: EdgeInsets.only(
                left: index.isEven ? 0.0 : 24.0,
                bottom: 12,
              ),
              child: Container(
                height: 14,
                width: 120 + (index * 20.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 详情面板骨架
  Widget _buildDetailPanelSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题占位
          Container(
            height: 20,
            width: 100,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(128),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // 内容行占位
          ...List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(Object error, AppLocalizations l10n) {
    final errorMessage = error.toString();
    final isNotFound = errorMessage.contains('404') ||
        errorMessage.contains('not found') ||
        errorMessage.contains('不存在');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNotFound ? Icons.search_off_outlined : Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              isNotFound
                  ? l10n.workbenchNotFound
                  : l10n.networkError,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            if (!isNotFound) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNotFound)
                  TextButton.icon(
                    onPressed: () => context.go('/workbenches'),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.workbenchList),
                  )
                else ...[
                  TextButton.icon(
                    onPressed: () => context.go('/workbenches'),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.workbenchList),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(workbenchDetailProvider(widget.id));
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容区（数据已加载）
  Widget _buildContent(
    Workbench workbench,
    AppLocalizations l10n, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 信息区
          _buildInfoSection(workbench, l10n),
          const SizedBox(height: 16),
          // 主内容区
          if (isDesktop)
            _buildDesktopContent(workbench, l10n)
          else
            _buildMobileContent(workbench, l10n,
                isMobile: isMobile, isTablet: isTablet),
        ],
      ),
    );
  }

  /// 信息区
  Widget _buildInfoSection(Workbench workbench, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标行
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 名称 + 状态标签
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workbench.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StatusChip(status: workbench.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 描述
          if (workbench.description != null &&
              workbench.description!.isNotEmpty)
            Text(
              workbench.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              l10n.workbenchDescriptionHint,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(128),
              ),
            ),
          const SizedBox(height: 8),
          // 元数据
          Text(
            '${l10n.createdAt} ${DateFormat('yyyy-MM-dd').format(workbench.createdAt)}'
            ' · ${l10n.lastModified} ${DateFormat('yyyy-MM-dd').format(workbench.updatedAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 桌面端主内容区（左右分栏）
  Widget _buildDesktopContent(Workbench workbench, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧设备树面板（280px 固定宽度）
        SizedBox(
          width: 280,
          child: _buildDeviceTreePanel(l10n),
        ),
        const SizedBox(width: 16),
        // 右侧设备详情面板（flex: 1）
        Expanded(
          child: _buildDeviceDetailPanel(l10n),
        ),
      ],
    );
  }

  /// 构建设备树面板
  Widget _buildDeviceTreePanel(AppLocalizations l10n) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DeviceTree(
        workbenchId: widget.id,
        selectedDeviceId: _selectedDeviceId,
        onDeviceSelected: (deviceId) {
          setState(() {
            _selectedDeviceId = deviceId;
          });
        },
      ),
    );
  }

  /// 构建设备详情面板
  Widget _buildDeviceDetailPanel(AppLocalizations l10n) {
    if (_selectedDeviceId == null) {
      return _buildDetailPlaceholder(l10n);
    }
    return _DeviceDetailView(
      deviceId: _selectedDeviceId!,
      l10n: l10n,
    );
  }

  /// 设备详情占位（未选中设备时显示）
  Widget _buildDetailPlaceholder(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.deviceDetail,
              style: textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.memory,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withAlpha(153),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.deviceDetail,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.deviceDetailPlaceholder,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 移动/平板端主内容区（上下堆叠）
  Widget _buildMobileContent(
    Workbench workbench,
    AppLocalizations l10n, {
    required bool isMobile,
    required bool isTablet,
  }) {
    return Column(
      children: [
        // 设备树面板（可折叠）
        _buildCollapsibleTreePanel(l10n,
            defaultExpanded: isTablet, isMobile: isMobile),
        const SizedBox(height: 16),
        // 设备详情面板
        _buildDeviceDetailPanel(l10n),
      ],
    );
  }

  /// 可折叠的设备树面板
  Widget _buildCollapsibleTreePanel(
    AppLocalizations l10n, {
    required bool defaultExpanded,
    required bool isMobile,
  }) {
    // 首次构建时根据默认值初始化
    if (!_treeExpanded && defaultExpanded) {
      // 延迟到下一帧设置，避免 build 中 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _treeExpanded = true);
        }
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 标题栏（点击展开/折叠）
          InkWell(
            onTap: () => setState(() => _treeExpanded = !_treeExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deviceTree,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    _treeExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // 展开的内容
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: SizedBox(
              height: 400,
              child: DeviceTree(
                workbenchId: widget.id,
                selectedDeviceId: _selectedDeviceId,
                onDeviceSelected: (deviceId) {
                  setState(() {
                    _selectedDeviceId = deviceId;
                  });
                },
              ),
            ),
            crossFadeState: _treeExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }



  /// 显示编辑对话框
  void _showEditDialog(Workbench workbench, AppLocalizations l10n) {
    WorkbenchFormDialog.show(
      context: context,
      ref: ref,
      title: l10n.workbenchEdit,
      submitLabel: l10n.save,
      isEdit: true,
      workbench: workbench,
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirm(Workbench workbench, AppLocalizations l10n) {
    ConfirmDialog.show(
      context: context,
      title: l10n.deleteWorkbenchTitle,
      description: l10n.deleteWorkbenchDescription(workbench.name),
      confirmLabel: l10n.deleteWorkbenchConfirm,
      isDanger: true,
      onConfirm: () => _handleDelete(workbench, l10n),
    );
  }

  /// 执行删除操作
  Future<void> _handleDelete(
      Workbench workbench, AppLocalizations l10n) async {
    try {
      final notifier = ref.read(
        workbenchDetailProvider(widget.id).notifier,
      );
      await notifier.deleteWorkbench();

      if (!mounted) return;
      Toast.show(
        context: context,
        message: l10n.deleteWorkbenchSuccess,
        type: ToastType.success,
      );

      // 删除成功后导航回列表页
      context.go('/workbenches');
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }
}

// ============================================================
// _DeviceDetailView — 设备详情视图
// ============================================================

/// 设备详情视图，显示设备信息及测点列表。
class _DeviceDetailView extends ConsumerWidget {
  const _DeviceDetailView({
    required this.deviceId,
    required this.l10n,
  });

  final String deviceId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(deviceDetailProvider(deviceId));

    return detailState.when(
      // ignore: unnecessary_lambdas
      loading: () => _buildDetailSkeleton(context),
      // ignore: unnecessary_lambdas
      error: (error, _) => _buildDetailError(context, ref, error),
      // ignore: unnecessary_lambdas
      data: (device) => _buildDetailContent(context, device),
    );
  }

  Widget _buildDetailSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.deviceDetail,
              style: textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildDetailError(BuildContext context, WidgetRef ref, Object error) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ErrorView(
        title: '$error',
        compact: true,
        onRetry: () {
          ref.invalidate(deviceDetailProvider(deviceId));
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, Device device) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备信息头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // 协议图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _protocolIcon(device.protocolType),
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _DeviceStatusChip(status: device.status),
                          const SizedBox(width: 8),
                          Text(
                            _protocolLabel(device.protocolType),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 设备参数信息
          if (device.protocolParams != null &&
              device.protocolParams!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildProtocolParams(context, device.protocolParams!),
            ),
          const Divider(height: 1),
          // 测点列表标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.pointListTitle,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // 测点列表
          Expanded(
            child: PointListWidget(deviceId: deviceId),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolParams(
    BuildContext context,
    Map<String, dynamic> params,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final entries = <Widget>[];
    var index = 0;
    for (final entry in params.entries) {
      entries.add(
        Padding(
          padding: EdgeInsets.only(top: index > 0 ? 8.0 : 0),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  entry.key,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${entry.value ?? '-'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries,
    );
  }

  IconData _protocolIcon(ProtocolType type) {
    switch (type) {
      case ProtocolType.virtual:
        return Icons.memory;
      case ProtocolType.modbusTcp:
        return Icons.lan;
      case ProtocolType.modbusRtu:
        return Icons.cable;
      case ProtocolType.can:
        return Icons.cable;
      case ProtocolType.visa:
        return Icons.usb;
      case ProtocolType.mqtt:
        return Icons.hub;
    }
  }

  String _protocolLabel(ProtocolType type) {
    switch (type) {
      case ProtocolType.virtual:
        return 'Virtual';
      case ProtocolType.modbusTcp:
        return 'Modbus TCP';
      case ProtocolType.modbusRtu:
        return 'Modbus RTU';
      case ProtocolType.can:
        return 'CAN';
      case ProtocolType.visa:
        return 'VISA';
      case ProtocolType.mqtt:
        return 'MQTT';
    }
  }
}

// ============================================================
// _DeviceStatusChip — 设备状态标签
// ============================================================

class _DeviceStatusChip extends StatelessWidget {
  const _DeviceStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
      case 'running':
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case 'offline':
      case 'inactive':
      case 'stopped':
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        break;
      case 'error':
      case 'failed':
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        break;
      default:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
      ),
    );
  }
}

// ============================================================
// _PointListSection and _PointListItem are now in PointListWidget
// (lib/pages/point/point_list_widget.dart)
// ============================================================

// ============================================================
// _StatusChip — 状态标签
// ============================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
      case 'running':
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        label = status;
        break;
      case 'inactive':
      case 'offline':
      case 'stopped':
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = status;
        break;
      case 'error':
      case 'failed':
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        label = status;
        break;
      default:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
