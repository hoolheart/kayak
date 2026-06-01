import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/app_localizations.dart';
import '../../models/point.dart';
import '../../providers/point_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/toast.dart';
import 'point_form_dialog.dart';
import 'point_value_display.dart';

// ============================================================
// PointListWidget — 测点列表组件
//
// 嵌入在 _DeviceDetailView 中，替换现有的 _PointListSection。
// 使用 pointListProvider(deviceId) 获取测点列表数据。
//
// 响应式设计：
// - 桌面端 (≥1024px)：完整 DataTable，6 列
// - 平板端 (600-1024px)：DataTable，可横向滚动
// - 移动端 (<600px)：Card 列表
// ============================================================

/// PointListWidget — 测点列表组件
class PointListWidget extends ConsumerStatefulWidget {
  const PointListWidget({super.key, required this.deviceId});

  /// 所属设备 ID
  final String deviceId;

  @override
  ConsumerState<PointListWidget> createState() => _PointListWidgetState();
}

class _PointListWidgetState extends ConsumerState<PointListWidget> {
  /// 打开添加测点对话框
  Future<void> _handleAddPoint() async {
    await PointFormDialog.show(
      context: context,
      ref: ref,
      deviceId: widget.deviceId,
    );
  }

  /// 打开编辑测点对话框
  Future<void> _handleEditPoint(Point point) async {
    await PointFormDialog.show(
      context: context,
      ref: ref,
      deviceId: widget.deviceId,
      existing: point,
    );
  }

  /// 删除测点确认
  Future<void> _handleDeletePoint(Point point) async {
    final l10n = AppLocalizations.of(context)!;
    await ConfirmDialog.show(
      context: context,
      title: l10n.pointDeleteConfirm(point.name),
      description: l10n.pointDeleteWarning,
      confirmLabel: l10n.delete,
      isDanger: true,
      onConfirm: () async {
        try {
          await ref
              .read(pointListProvider(widget.deviceId).notifier)
              .deletePoint(point.id);
          if (!mounted) return;
          Toast.show(
            context: context,
            message: l10n.pointDeleteSuccess,
            type: ToastType.success,
          );
        } catch (e) {
          if (!mounted) return;
          Toast.show(
            context: context,
            message: '$e',
            type: ToastType.error,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsState = ref.watch(pointListProvider(widget.deviceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头部
        _buildHeader(l10n, pointsState),
        const Divider(height: 1),
        // 内容区
        Expanded(
          child: _buildContent(l10n, pointsState),
        ),
      ],
    );
  }

  /// 构建头部（标题 + 计数 + 添加按钮）
  Widget _buildHeader(
    AppLocalizations l10n,
    AsyncValue<List<Point>> pointsState,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // 移动端添加按钮在底部显示
    final showAddInHeader = !isMobile;

    // 加载中时不显示计数
    final showCount = pointsState.hasValue;
    final count = pointsState.value?.length ?? 0;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            l10n.pointListTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (showCount) ...[
            const SizedBox(width: 8),
            Text(
              l10n.pointCount(count),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const Spacer(),
          if (showAddInHeader)
            FilledButton.icon(
              onPressed: pointsState.isLoading ? null : _handleAddPoint,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addPoint),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建内容区（三态）
  Widget _buildContent(
    AppLocalizations l10n,
    AsyncValue<List<Point>> pointsState,
  ) {
    return pointsState.when(
      loading: () => _buildSkeleton(context),
      error: (error, _) => _buildError(context, l10n, error.toString()),
      data: (points) {
        if (points.isEmpty) {
          return _buildEmpty(l10n);
        }
        return _buildDataList(l10n, points);
      },
    );
  }

  /// 骨架屏（5 行 × 6 列）
  Widget _buildSkeleton(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _skeletonBlock(context, height: 16, width: 120),
                ),
                const SizedBox(width: 8),
                _skeletonBlock(context, height: 20, width: 60),
                const SizedBox(width: 8),
                _skeletonBlock(context, height: 16, width: 16, borderRadius: 8),
                const SizedBox(width: 8),
                _skeletonBlock(context, height: 16, width: 40),
                const SizedBox(width: 8),
                _skeletonBlock(context, height: 16, width: 60),
                const SizedBox(width: 8),
                _skeletonBlock(context, height: 32, width: 64),
              ],
            ),
          );
        }),
      );
    }

    return Column(
      children: [
        // 表头骨架
        _buildSkeletonHeader(context),
        // 行骨架
        ...List.generate(5, (_) => _buildSkeletonRow(context)),
      ],
    );
  }

  Widget _buildSkeletonHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _skeletonBlock(context, height: 14, width: 40)),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 14, width: 30),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 14, width: 30),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 14, width: 30),
          const SizedBox(width: 16),
          Expanded(child: _skeletonBlock(context, height: 14, width: 40)),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 14, width: 50),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(77),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _skeletonBlock(context, height: 14, width: 120)),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 20, width: 60),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 16, width: 16, borderRadius: 8),
          const SizedBox(width: 16),
          _skeletonBlock(context, height: 14, width: 30),
          const SizedBox(width: 16),
          Expanded(child: _skeletonBlock(context, height: 16, width: 80)),
          const SizedBox(width: 16),
          Row(
            children: [
              _skeletonBlock(context, height: 32, width: 32, borderRadius: 16),
              const SizedBox(width: 4),
              _skeletonBlock(context, height: 32, width: 32, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonBlock(
    BuildContext context, {
    required double height,
    required double width,
    double borderRadius = 4,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// 空状态
  Widget _buildEmpty(AppLocalizations l10n) {
    return EmptyView(
      title: l10n.pointListEmpty,
      icon: Icons.point_of_sale_outlined,
      compact: true,
      actionButton: FilledButton.icon(
        onPressed: _handleAddPoint,
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.addFirstPoint),
      ),
    );
  }

  /// 错误状态
  Widget _buildError(
    BuildContext context,
    AppLocalizations l10n,
    String errorMessage,
  ) {
    return ErrorView(
      title: errorMessage,
      compact: true,
      onRetry: () {
        ref.invalidate(pointListProvider(widget.deviceId));
      },
    );
  }

  /// 数据列表（表格/卡片）
  Widget _buildDataList(AppLocalizations l10n, List<Point> points) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildCardList(l10n, points);
        }
        return _buildTable(l10n, points);
      },
    );
  }

  /// 桌面端表格
  Widget _buildTable(AppLocalizations l10n, List<Point> points) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // 表头
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(128),
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: _headerCell(l10n.pointColumnName, textTheme, colorScheme)),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Center(child: _headerCell(l10n.pointColumnType, textTheme, colorScheme)),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Center(child: _headerCell(l10n.pointColumnAccess, textTheme, colorScheme)),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Center(child: _headerCell(l10n.pointColumnUnit, textTheme, colorScheme)),
              ),
              const SizedBox(width: 16),
              Expanded(child: _headerCell(l10n.pointColumnValue, textTheme, colorScheme)),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: Center(child: _headerCell(l10n.pointColumnAction, textTheme, colorScheme)),
              ),
            ],
          ),
        ),
        // 数据行
        Expanded(
          child: ListView.builder(
            itemCount: points.length,
            itemBuilder: (context, index) {
              final point = points[index];
              return _buildTableRow(context, l10n, point, colorScheme, textTheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      text,
      style: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    AppLocalizations l10n,
    Point point,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return InkWell(
      onTap: () {},
      hoverColor: colorScheme.onSurface.withAlpha(10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(77),
            ),
          ),
        ),
        child: Row(
          children: [
            // 名称
            Expanded(
              flex: 2,
              child: Text(
                point.name,
                style: textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            // 类型标签
            SizedBox(
              width: 80,
              child: Center(child: _buildTypeChip(point.dataType, colorScheme, textTheme)),
            ),
            const SizedBox(width: 16),
            // 访问权限
            SizedBox(
              width: 80,
              child: Center(
                child: Tooltip(
                  message: _accessTypeLabel(point.accessType, l10n),
                  child: Icon(
                    _accessTypeIcon(point.accessType),
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 单位
            SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  point.unit ?? '—',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 当前值
            Expanded(
              child: PointValueDisplay(
                pointId: point.id,
                dataType: point.dataType,
                unit: point.unit,
                status: point.status,
              ),
            ),
            const SizedBox(width: 16),
            // 操作按钮
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => _handleEditPoint(point),
                    tooltip: l10n.edit,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      hoverColor: colorScheme.primary.withAlpha(20),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    onPressed: () => _handleDeletePoint(point),
                    tooltip: l10n.delete,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      hoverColor: colorScheme.error.withAlpha(20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 移动端卡片列表
  Widget _buildCardList(AppLocalizations l10n, List<Point> points) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...points.map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(51),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：名称 + 类型标签
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            point.name,
                            style: textTheme.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(point.dataType, colorScheme, textTheme),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 第二行：权限 + 单位
                    Row(
                      children: [
                        Icon(
                          _accessTypeIcon(point.accessType),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _accessTypeLabel(point.accessType, l10n),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          point.unit ?? '—',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 第三行：值 + 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: PointValueDisplay(
                            pointId: point.id,
                            dataType: point.dataType,
                            unit: point.unit,
                            status: point.status,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          onPressed: () => _handleEditPoint(point),
                          tooltip: l10n.edit,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          onPressed: () => _handleDeletePoint(point),
                          tooltip: l10n.delete,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        // 底部添加按钮（移动端）
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _handleAddPoint,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addPoint),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 类型标签
  Widget _buildTypeChip(DataType dataType, ColorScheme colorScheme, TextTheme textTheme) {
    final (Color bgColor, Color textColor) = _typeColors(dataType, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _dataTypeLabel(dataType),
        style: textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 数据类型颜色
  (Color, Color) _typeColors(DataType dataType, ColorScheme colorScheme) {
    switch (dataType) {
      case DataType.number:
        return (colorScheme.primary.withAlpha(31), colorScheme.primary);
      case DataType.integer:
        return (const Color(0xFF7B1FA2).withAlpha(31), const Color(0xFF7B1FA2));
      case DataType.boolean:
        return (const Color(0xFF2E7D32).withAlpha(31), const Color(0xFF2E7D32));
      case DataType.string:
        return (const Color(0xFFED6C02).withAlpha(31), const Color(0xFFED6C02));
    }
  }

  /// 数据类型标签文本
  String _dataTypeLabel(DataType dataType) {
    switch (dataType) {
      case DataType.number:
        return 'Number';
      case DataType.integer:
        return 'Integer';
      case DataType.boolean:
        return 'Boolean';
      case DataType.string:
        return 'String';
    }
  }

  /// 访问权限图标
  IconData _accessTypeIcon(AccessType accessType) {
    switch (accessType) {
      case AccessType.ro:
        return Icons.visibility;
      case AccessType.wo:
        return Icons.edit_off;
      case AccessType.rw:
        return Icons.sync_alt;
    }
  }

  /// 访问权限标签
  String _accessTypeLabel(AccessType accessType, AppLocalizations l10n) {
    switch (accessType) {
      case AccessType.ro:
        return l10n.accessTypeRo;
      case AccessType.wo:
        return l10n.accessTypeWo;
      case AccessType.rw:
        return l10n.accessTypeRw;
    }
  }
}
