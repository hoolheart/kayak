import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../models/workbench.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services.dart';
import '../../providers/workbench_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/toast.dart';

// ============================================================
// WorkbenchListPage — 工作台列表页面
//
// 展示工作台卡片网格，支持搜索、创建、编辑、删除操作。
// 响应式布局：4 列（>1280px）/ 3 列（1024-1280px）/
// 2 列（600-1024px）/ 1 列（<600px）
// ============================================================

class WorkbenchListPage extends ConsumerStatefulWidget {
  const WorkbenchListPage({super.key});

  @override
  ConsumerState<WorkbenchListPage> createState() => _WorkbenchListPageState();
}

class _WorkbenchListPageState extends ConsumerState<WorkbenchListPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // The WorkbenchListNotifier.build() is called automatically
    // on first access via ref.watch().
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 搜索输入变化时触发 300ms debounce
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(workbenchListProvider.notifier).search(query);
    });
  }

  /// 显示创建工作台对话框
  void _showCreateDialog() {
    final l10n = AppLocalizations.of(context)!;
    _WorkbenchFormDialog.show(
      context: context,
      ref: ref,
      title: l10n.workbenchCreate,
      submitLabel: l10n.create,
      isEdit: false,
    );
  }

  /// 显示编辑工作台对话框
  void _showEditDialog(Workbench workbench) {
    final l10n = AppLocalizations.of(context)!;
    _WorkbenchFormDialog.show(
      context: context,
      ref: ref,
      title: l10n.workbenchEdit,
      submitLabel: l10n.save,
      isEdit: true,
      workbench: workbench,
    );
  }

  /// 显示删除工作台确认对话框
  void _showDeleteConfirm(Workbench workbench) {
    final l10n = AppLocalizations.of(context)!;
    ConfirmDialog.show(
      context: context,
      title: l10n.deleteWorkbenchTitle,
      description: l10n.deleteWorkbenchDescription(workbench.name),
      confirmLabel: l10n.delete,
      isDanger: true,
      onConfirm: () => _handleDelete(workbench),
    );
  }

  /// 执行删除操作
  Future<void> _handleDelete(Workbench workbench) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = ref.read(workbenchServiceProvider);
      await service.delete(workbench.id);

      if (!mounted) return;
      Toast.show(
        context: context,
        message: l10n.deleteWorkbenchSuccess,
        type: ToastType.success,
      );

      // 刷新列表
      ref.read(workbenchListProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  /// 导航到工作台详情页
  void _navigateToDetail(Workbench workbench) {
    context.go('/workbenches/${workbench.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workbenchState = ref.watch(workbenchListProvider);
    final notifier = ref.read(workbenchListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workbenches),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: l10n.create,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            l10n: l10n,
          ),
          Expanded(
            child: workbenchState.when(
              loading: _buildSkeletonGrid,
              error: (error, _) => ErrorView(
                title: error.toString(),
                onRetry: notifier.retry,
              ),
              data: (workbenches) => _buildContent(
                workbenches,
                notifier,
                l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域（空状态或数据网格）
  Widget _buildContent(
    List<Workbench> workbenches,
    WorkbenchListNotifier notifier,
    AppLocalizations l10n,
  ) {
    // 搜索中且无结果 → 搜索空状态
    if (workbenches.isEmpty && _searchController.text.isNotEmpty) {
      return _buildSearchEmptyState(l10n);
    }

    // 无搜索且无数据 → 空状态引导
    if (workbenches.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // 有数据 → 卡片网格 + 分页
    return _buildDataView(workbenches, notifier, l10n);
  }

  /// 骨架屏加载指示器
  Widget _buildSkeletonGrid() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 搜索无结果空状态
  Widget _buildSearchEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withAlpha(153),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.searchNoResults,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.searchNoResultsHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                ref.read(workbenchListProvider.notifier).search('');
              },
              icon: const Icon(Icons.close),
              label: Text(l10n.clearSearch),
            ),
          ],
        ),
      ),
    );
  }

  /// 首次空状态
  Widget _buildEmptyState(AppLocalizations l10n) {
    return EmptyView(
      icon: Icons.folder_open_outlined,
      title: l10n.emptyWorkbenchTitle,
      description: l10n.emptyWorkbenchDescription,
      actionButton: FilledButton.icon(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.emptyWorkbenchAction),
      ),
    );
  }

  /// 数据视图（卡片网格 + 分页栏）
  Widget _buildDataView(
    List<Workbench> workbenches,
    WorkbenchListNotifier notifier,
    AppLocalizations l10n,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnCount = _getColumnCount(screenWidth);
    const padding = 16.0;
    const spacing = 16.0;
    final availableWidth =
        screenWidth - padding * 2 - spacing * (columnCount - 1);
    final itemWidth = availableWidth / columnCount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: workbenches.map((workbench) {
                return SizedBox(
                  width: itemWidth,
                  child: _WorkbenchCard(
                    workbench: workbench,
                    onTap: () => _navigateToDetail(workbench),
                    onEdit: () => _showEditDialog(workbench),
                    onDelete: () => _showDeleteConfirm(workbench),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // 分页栏
        if (notifier.totalCount > 0)
          _PaginationBar(
            totalCount: notifier.totalCount,
            hasMore: notifier.hasMore,
            isLoadingMore: false,
            onLoadMore: () => notifier.loadMore(),
            l10n: l10n,
          ),
      ],
    );
  }

  /// 根据视口宽度获取网格列数
  int _getColumnCount(double width) {
    if (width < 600) return 1;
    if (width < 1024) return 2;
    if (width < 1280) return 3;
    return 4;
  }
}

// ============================================================
// _SearchBar — 搜索栏
// ============================================================

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.l10n,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 8,
      ),
      child: SizedBox(
        width: isMobile ? double.infinity : screenWidth * 0.6,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: l10n.workbenchSearchHint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _PaginationBar — 分页栏
// ============================================================

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.totalCount,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.l10n,
  });

  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.totalCount(totalCount),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (hasMore)
            TextButton(
              onPressed: isLoadingMore ? null : onLoadMore,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: isLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.loadMore,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// _WorkbenchCard — 工作台卡片
//
// 支持 Hover（Elevation + Stroke 变色 + translateY -2px）
// 和 Pressed（Scale 0.98）状态动画。
// ============================================================

class _WorkbenchCard extends StatefulWidget {
  const _WorkbenchCard({
    required this.workbench,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Workbench workbench;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_WorkbenchCard> createState() => _WorkbenchCardState();
}

class _WorkbenchCardState extends State<_WorkbenchCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final workbench = widget.workbench;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: _isPressed ? 100 : 150,
          ),
          curve: _isPressed ? Curves.easeInOut : Curves.easeOut,
          transform: _isPressed
              ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
              : (_isHovered
                  ? Matrix4.translationValues(0.0, -2.0, 0.0)
                  : Matrix4.identity()),
          transformAlignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withAlpha(20)
                    : Colors.black.withAlpha(8),
                blurRadius: _isHovered ? 8 : 2,
                offset: Offset(0, _isHovered ? 4 : 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态标签（右上角）
                Align(
                  alignment: Alignment.topRight,
                  child: _StatusChip(status: workbench.status),
                ),
                const SizedBox(height: 8),
                // 名称（单行省略）
                Text(
                  workbench.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 描述（2 行省略）
                if (workbench.description != null &&
                    workbench.description!.isNotEmpty)
                  Text(
                    workbench.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  // 保持卡片高度一致
                  const SizedBox(height: 18),
                const Spacer(),
                // 分隔线
                const Divider(height: 1),
                const SizedBox(height: 8),
                // 底部行：创建时间 + 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(workbench.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _CardActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: AppLocalizations.of(context)!.edit,
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 4),
                    _CardActionButton(
                      icon: Icons.delete_outlined,
                      tooltip: AppLocalizations.of(context)!.delete,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}

// ============================================================
// _StatusChip — 状态标签
// ============================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color chipColor;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
      case 'running':
        chipColor = colorScheme.primary;
        label = status;
        break;
      case 'inactive':
      case 'stopped':
        chipColor = colorScheme.onSurfaceVariant;
        label = status;
        break;
      case 'error':
      case 'failed':
        chipColor = colorScheme.error;
        label = status;
        break;
      default:
        chipColor = colorScheme.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

// ============================================================
// _CardActionButton — 卡片操作按钮
// ============================================================

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onTap,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }
}

// ============================================================
// _WorkbenchCardSkeleton — 骨架屏卡片占位
// ============================================================

class _WorkbenchCardSkeleton extends StatefulWidget {
  const _WorkbenchCardSkeleton();

  @override
  State<_WorkbenchCardSkeleton> createState() => _WorkbenchCardSkeletonState();
}

class _WorkbenchCardSkeletonState extends State<_WorkbenchCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Defer animation start to avoid layout cycle during initial frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat();
        setState(() => _isAnimating = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final child = Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标签占位
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 名称占位
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(128),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // 描述行 1 占位
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(128),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // 描述行 2 占位
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Spacer(),
          // 分隔线占位
          Container(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          // 底部行占位
          Row(
            children: [
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_isAnimating) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, animatedChild) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  colorScheme.surfaceContainerHighest.withAlpha(128),
                  colorScheme.surfaceContainerHighest.withAlpha(128),
                  colorScheme.surfaceContainerHighest.withAlpha(204),
                  colorScheme.surfaceContainerHighest.withAlpha(128),
                  colorScheme.surfaceContainerHighest.withAlpha(128),
                ],
                stops: [
                  0.0,
                  _controller.value - 0.3,
                  _controller.value,
                  _controller.value + 0.3,
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: animatedChild!,
          );
        },
        child: child,
      );
    }

    return child;
  }
}

// ============================================================
// _WorkbenchFormDialog — 创建工作台/编辑工作台 对话框
//
// 支持创建和编辑两种模式。响应式适配：
// - 桌面：居中 Dialog，宽度 480px
// - 移动端：BottomSheet，宽度 100%
// ============================================================

class _WorkbenchFormDialog extends StatefulWidget {
  const _WorkbenchFormDialog({
    required this.ref,
    required this.title,
    required this.submitLabel,
    required this.isEdit,
    this.workbench,
  });

  /// 父组件的 ref（用于读取 provider）
  final WidgetRef ref;

  /// 对话框标题
  final String title;

  /// 提交按钮标签（"创建" 或 "保存"）
  final String submitLabel;

  /// 是否为编辑模式
  final bool isEdit;

  /// 编辑模式时的工作台数据
  final Workbench? workbench;

  /// 显示对话框
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String submitLabel,
    required bool isEdit,
    Workbench? workbench,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // 移动端：BottomSheet
      return showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) => _WorkbenchFormDialog(
          ref: ref,
          title: title,
          submitLabel: submitLabel,
          isEdit: isEdit,
          workbench: workbench,
        ),
      );
    }

    // 桌面端：居中 Dialog
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 480,
          child: _WorkbenchFormDialog(
            ref: ref,
            title: title,
            submitLabel: submitLabel,
            isEdit: isEdit,
            workbench: workbench,
          ),
        ),
      ),
    );
  }

  @override
  State<_WorkbenchFormDialog> createState() => _WorkbenchFormDialogState();
}

class _WorkbenchFormDialogState extends State<_WorkbenchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 编辑模式：预填现有值
    if (widget.isEdit && widget.workbench != null) {
      _nameController.text = widget.workbench!.name;
      _descriptionController.text = widget.workbench!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 提交表单
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context)!;
    final authState = widget.ref.read(authProvider);

    try {
      if (widget.isEdit) {
        // 编辑模式
        final workbench = widget.workbench!;
        final service = widget.ref.read(workbenchServiceProvider);
        await service.update(workbench.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        });

        if (!mounted) return;
        Toast.show(
          context: context,
          message: l10n.updateWorkbenchSuccess,
          type: ToastType.success,
        );
        Navigator.of(context).pop();
        // 刷新列表
        widget.ref.read(workbenchListProvider.notifier).refresh();
      } else {
        // 创建模式
        final user = authState.asData?.value;
        await widget.ref.read(workbenchListProvider.notifier).createWorkbench(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              ownerType: 'user',
              ownerId: user?.id ?? 'unknown',
            );

        if (!mounted) return;

        // 检查创建结果
        final currentState = widget.ref.read(workbenchListProvider);
        if (currentState is AsyncData) {
          Toast.show(
            context: context,
            message: l10n.createWorkbenchSuccess,
            type: ToastType.success,
          );
          Navigator.of(context).pop();
        } else {
          // 创建失败（状态为 AsyncError）
          setState(() => _isSubmitting = false);
          final error = currentState is AsyncError ? currentState.error : null;
          Toast.show(
            context: context,
            message: error?.toString() ?? '创建失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Toast.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final horizontalPadding = isMobile ? 24.0 : 32.0;

    return Padding(
      padding: EdgeInsets.only(
        top: 32,
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!isMobile)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isSubmitting ? null : () => Navigator.of(context).pop(),
                    tooltip: l10n.cancel,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // 名称字段
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.workbenchName,
                hintText: l10n.workbenchNameHint,
              ),
              maxLength: 255,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.workbenchNameRequired;
                }
                if (value.length > 255) {
                  return l10n.workbenchNameMaxLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 描述字段
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.workbenchDescription,
                hintText: l10n.workbenchDescriptionHint,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 1000,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return null; // 不显示字数统计
              },
            ),
            const SizedBox(height: 32),
            // 操作按钮
            Align(
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(widget.submitLabel),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed:
                              _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(widget.submitLabel),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
