import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../models/experiment.dart';
import '../../providers/experiment_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/toast.dart' show Toast, ToastType;

// ============================================================
// ExperimentListPage — 试验列表页
// ============================================================

/// 试验列表页面。
///
/// 展示所有试验记录，支持：
/// - 状态下拉筛选（单选）
/// - 时间范围筛选
/// - 分页导航
/// - 试验停止操作
/// - 响应式布局（桌面表格 / 移动端卡片）
class ExperimentListPage extends ConsumerStatefulWidget {
  const ExperimentListPage({super.key});

  @override
  ConsumerState<ExperimentListPage> createState() =>
      _ExperimentListPageState();
}

class _ExperimentListPageState extends ConsumerState<ExperimentListPage> {
  // ============================================================
  // 筛选状态
  // ============================================================
  ExperimentStatus? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  // ============================================================
  // 分页状态
  // ============================================================
  int _pageSize = 10;

  bool get _hasActiveFilter =>
      _statusFilter != null || _startDate != null || _endDate != null;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // 监听列表状态
    final listAsync = ref.watch(experimentListProvider);
    final notifier = ref.read(experimentListProvider.notifier);

    // 同步分页状态
    final total = notifier.total;
    final currentPage = notifier.currentPage;
    final totalPages =
        total > 0 ? ((total + _pageSize - 1) / _pageSize).ceil() : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.experimentList),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isMobile
                ? IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: l10n.createExperiment,
                    onPressed: () => context.go('/experiments/new'),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.createExperiment),
                    onPressed: () => context.go('/experiments/new'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // —— 筛选栏 ——
          _FilterBar(
            statusFilter: _statusFilter,
            startDate: _startDate,
            endDate: _endDate,
            startDateController: _startDateController,
            endDateController: _endDateController,
            dateFormat: _dateFormat,
            hasActiveFilter: _hasActiveFilter,
            onStatusChanged: (status) {
              setState(() => _statusFilter = status);
              _applyFilter(notifier);
            },
            onStartDateChanged: (date) {
              setState(() => _startDate = date);
              _applyFilter(notifier);
            },
            onEndDateChanged: (date) {
              setState(() => _endDate = date);
              _applyFilter(notifier);
            },
            onReset: () {
              setState(() {
                _statusFilter = null;
                _startDate = null;
                _endDate = null;
                _startDateController.clear();
                _endDateController.clear();
              });
              _applyFilter(notifier);
            },
          ),

          // —— 内容区域 ——
          Expanded(
            child: listAsync.when(
              loading: () => _buildSkeleton(isMobile),
              error: (error, _) => _buildErrorView(l10n, notifier, error),
              data: (experiments) {
                if (experiments.isEmpty) {
                  return _buildEmptyView(l10n, notifier);
                }
                return Column(
                  children: [
                    Expanded(
                      child: isMobile
                          ? _ExperimentCardList(
                              experiments: experiments,
                              methodNames: notifier.methodNames,
                              onStop: _handleStop,
                              onOpenConsole: (id) =>
                                  context.go('/experiments/$id'),
                            )
                        : _ExperimentDataTable(
                            experiments: experiments,
                            methodNames: notifier.methodNames,
                            onStop: _handleStop,
                              onOpenConsole: (id) =>
                                  context.go('/experiments/$id'),
                            ),
                    ),
                    // —— 分页栏 ——
                    _PaginationBar(
                      currentPage: currentPage,
                      totalPages: totalPages,
                      total: total,
                      pageSize: _pageSize,
                      hasNext: notifier.hasNext,
                      hasPrev: notifier.hasPrev,
                      onPageChanged: notifier.goToPage,
                      onPageSizeChanged: (size) {
                        setState(() => _pageSize = size);
                        notifier.setPageSize(size);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter(ExperimentListNotifier notifier) {
    notifier.setFilter(
      status: _statusFilter,
      createdAfter: _startDate,
      createdBefore: _endDate,
    );
  }

  Widget _buildSkeleton(bool isMobile) {
    if (isMobile) {
      return ListView.builder(
        itemCount: 3,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Skeleton(type: SkeletonType.card),
        ),
      );
    }
    return const Skeleton();
  }

  Widget _buildErrorView(
    AppLocalizations l10n,
    ExperimentListNotifier notifier,
    Object error,
  ) {
    return ErrorView(
      title: l10n.loadFailed,
      description: l10n.loadFailedHint,
      onRetry: () => notifier.refresh(),
    );
  }

  Widget _buildEmptyView(
    AppLocalizations l10n,
    ExperimentListNotifier notifier,
  ) {
    if (_hasActiveFilter) {
      // 筛选后无结果
      return EmptyView(
        icon: Icons.filter_list_off,
        title: l10n.noFilteredResults,
        description: l10n.noFilteredResultsHint,
        actionButton: TextButton(
          onPressed: () {
            setState(() {
              _statusFilter = null;
              _startDate = null;
              _endDate = null;
              _startDateController.clear();
              _endDateController.clear();
            });
            notifier.setFilter();
          },
          child: Text(l10n.clearFilter),
        ),
      );
    }
    // 完全空状态
    return EmptyView(
      icon: Icons.science_outlined,
      title: l10n.noExperiments,
      description: l10n.noExperimentsHint,
      actionButton: FilledButton(
        onPressed: () => context.go('/experiments/new'),
        child: Text(l10n.createFirstExperiment),
      ),
    );
  }

  /// 处理停止试验操作（二次确认 + API 调用）。
  Future<void> _handleStop(Experiment experiment) async {
    final l10n = AppLocalizations.of(context)!;
    await ConfirmDialog.show(
      context: context,
      title: l10n.confirmStopTitle,
      description: l10n.confirmStopDesc(experiment.name),
      onConfirm: () async {
        try {
          await ref
              .read(experimentControlProvider(experiment.id).notifier)
              .stop();
          if (mounted) {
            Toast.show(
                  context: context,
                  message: l10n.experimentStopped,
                  type: ToastType.success,
                );
            ref.read(experimentListProvider.notifier).refresh();
          }
        } catch (e) {
          if (mounted) {
            Toast.show(
              context: context,
              message: l10n.stopFailed(e.toString()),
              type: ToastType.error,
            );
          }
        }
      },
      isDanger: true,
      confirmLabel: l10n.stopExperiment,
    );
  }
}

// ============================================================
// _FilterBar — 筛选栏
// ============================================================

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusFilter,
    required this.startDate,
    required this.endDate,
    required this.startDateController,
    required this.endDateController,
    required this.dateFormat,
    required this.hasActiveFilter,
    required this.onStatusChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onReset,
  });

  final ExperimentStatus? statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final DateFormat dateFormat;
  final bool hasActiveFilter;
  final ValueChanged<ExperimentStatus?> onStatusChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusDropdown(context, l10n),
                const SizedBox(height: 12),
                _buildDateRange(context, isMobile),
                if (hasActiveFilter) ...[
                  const SizedBox(height: 12),
                  _buildResetButton(context, l10n),
                ],
              ],
            )
          : Row(
              children: [
                _buildStatusDropdown(context, l10n),
                const SizedBox(width: 24),
                _buildDateRange(context, isMobile),
                if (hasActiveFilter) ...[
                  const Spacer(),
                  _buildResetButton(context, l10n),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<ExperimentStatus?>(
        initialValue: statusFilter,
        decoration: InputDecoration(
          labelText: l10n.filterStatus,
          labelStyle: Theme.of(context).textTheme.labelMedium,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<ExperimentStatus?>(
            child: Text(l10n.allStatuses),
          ),
          ...ExperimentStatus.values.map(
            (status) => DropdownMenuItem<ExperimentStatus?>(
              value: status,
              child: Row(
                children: [
                  _StatusDot(status: status),
                  const SizedBox(width: 8),
                  Text(_statusText(context, status)),
                ],
              ),
            ),
          ),
        ],
        onChanged: onStatusChanged,
        isExpanded: true,
      ),
    );
  }

  Widget _buildDateRange(BuildContext context, bool isMobile) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        SizedBox(
          width: isMobile ? null : 140,
          child: TextField(
            controller: startDateController,
            decoration: InputDecoration(
              labelText: l10n.filterDateRange,
              hintText: 'YYYY-MM-DD',
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            readOnly: true,
            onTap: () => _pickDate(context, (date) {
              startDateController.text = dateFormat.format(date);
              onStartDateChanged(date);
            }),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
          child: Text(
            '~',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        SizedBox(
          width: isMobile ? null : 140,
          child: TextField(
            controller: endDateController,
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            readOnly: true,
            onTap: () => _pickDate(context, (date) {
              endDateController.text = dateFormat.format(date);
              onEndDateChanged(date);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, AppLocalizations l10n) {
    return TextButton(
      onPressed: onReset,
      child: Text(l10n.resetFilter),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  String _statusText(BuildContext context, ExperimentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ExperimentStatus.idle:
        return l10n.statusIdle;
      case ExperimentStatus.loaded:
        return l10n.statusLoaded;
      case ExperimentStatus.running:
        return l10n.statusRunning;
      case ExperimentStatus.paused:
        return l10n.statusPaused;
      case ExperimentStatus.completed:
        return l10n.statusCompleted;
      case ExperimentStatus.aborted:
        return l10n.statusAborted;
    }
  }
}

/// 状态下拉列表中的颜色圆点。
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final ExperimentStatus status;

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case ExperimentStatus.idle:
        return isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575);
      case ExperimentStatus.loaded:
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1976D2);
      case ExperimentStatus.running:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case ExperimentStatus.paused:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFED6C02);
      case ExperimentStatus.completed:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case ExperimentStatus.aborted:
        return isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _color(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================
// _ExperimentDataTable — 桌面端数据表格
// ============================================================

class _ExperimentDataTable extends StatelessWidget {
  const _ExperimentDataTable({
    required this.experiments,
    required this.methodNames,
    required this.onStop,
    required this.onOpenConsole,
  });

  final List<Experiment> experiments;
  final Map<String, String> methodNames;
  final ValueChanged<Experiment> onStop;
  final ValueChanged<String> onOpenConsole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withAlpha(128),
        ),
        columnSpacing: 16,
        horizontalMargin: 16,
        columns: [
          DataColumn(
            label: Text(
              l10n.columnName,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              l10n.columnMethod,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              l10n.columnStatus,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              l10n.columnStartTime,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DataColumn(
            numeric: true,
            label: Text(
              l10n.columnDuration,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DataColumn(
            numeric: true,
            label: Text(
              l10n.columnActions,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        rows: experiments.map((exp) {
          final isRunning = exp.status == ExperimentStatus.running;
          final showStop = exp.status == ExperimentStatus.running ||
              exp.status == ExperimentStatus.paused;

          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered)) {
                return colorScheme.onSurface.withAlpha(10); // ~4%
              }
              if (isRunning) {
                return isDark
                    ? const Color(0xFF2E7D32).withAlpha(20) // ~8%
                    : const Color(0xFF2E7D32).withAlpha(10); // ~4%
              }
              return null;
            }),
            onSelectChanged: (_) => onOpenConsole(exp.id),
            cells: [
              DataCell(
                Tooltip(
                  message: exp.name,
                  child: Text(
                    exp.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              DataCell(
                Text(
                  // TODO: 后端 Experiment 响应暂无 method_name 字段，
                  // 当前通过 MethodService.getById 批量解析；待后端加入
                  // method_name 后可直接使用，移除 batch-fetch 逻辑。
                  exp.methodId != null
                      ? (methodNames[exp.methodId] ?? l10n.methodNotSet)
                      : l10n.methodNotSet,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              DataCell(
                StatusBadge(
                  status: exp.status,
                  label: _statusLabelText(context, exp.status),
                ),
              ),
              DataCell(
                Text(
                  _formatDateTime(context, exp.startedAt, l10n),
                  style: textTheme.bodyMedium,
                ),
              ),
              DataCell(
                Text(
                  _formatDuration(context, exp, l10n),
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: l10n.openConsole,
                      onPressed: () => onOpenConsole(exp.id),
                    ),
                    if (showStop)
                      IconButton(
                        icon: const Icon(Icons.stop, size: 18),
                        tooltip: l10n.stopExperiment,
                        color: colorScheme.error,
                        onPressed: () => onStop(exp),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDateTime(
    BuildContext context,
    DateTime? dateTime,
    AppLocalizations l10n,
  ) {
    if (dateTime == null) return l10n.notStarted;
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'zh'
        ? DateFormat('yyyy-MM-dd HH:mm')
        : DateFormat('MM/dd/yyyy HH:mm', 'en');
    return format.format(dateTime);
  }

  String _formatDuration(
    BuildContext context,
    Experiment exp,
    AppLocalizations l10n,
  ) {
    if (exp.startedAt == null) return l10n.notStarted;

    final now = DateTime.now();
    final end = exp.endedAt ?? now;
    final duration = end.difference(exp.startedAt!);

    if (duration.inSeconds < 0) return l10n.notStarted;

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // 对于较长时间，显示 X 小时 Y 分钟
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

// ============================================================
// _ExperimentCardList — 移动端卡片列表
// ============================================================

class _ExperimentCardList extends StatelessWidget {
  const _ExperimentCardList({
    required this.experiments,
    required this.methodNames,
    required this.onStop,
    required this.onOpenConsole,
  });

  final List<Experiment> experiments;
  final Map<String, String> methodNames;
  final ValueChanged<Experiment> onStop;
  final ValueChanged<String> onOpenConsole;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final exp = experiments[index];
        final isRunning = exp.status == ExperimentStatus.running;
        final showStop = exp.status == ExperimentStatus.running ||
            exp.status == ExperimentStatus.paused;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            // RUNNING 状态：顶部 3px 绿色边框
            margin: EdgeInsets.zero,
            child: DecoratedBox(
              decoration: isRunning
                  ? BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          // RUNNING 状态：绿色边框（匹配 StatusBadge 绿色主题）
                          color: isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF2E7D32),
                          width: 3,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : const BoxDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部：名称 + StatusBadge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exp.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          status: exp.status,
                          label: _statusLabelText(context, exp.status),
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 信息行
                    _InfoRow(
                      label: l10n.columnMethod,
                      // TODO: 后端 Experiment 响应暂无 method_name 字段，
                      // 当前通过 MethodService.getById 批量解析；待后端加入
                      // method_name 后可直接使用，移除 batch-fetch 逻辑。
                      value: exp.methodId != null
                          ? (methodNames[exp.methodId] ?? l10n.methodNotSet)
                          : l10n.methodNotSet,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: l10n.columnStartTime,
                      value: _formatDateTime(
                        context,
                        exp.startedAt,
                        l10n,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: l10n.columnDuration,
                      value: _formatDuration(context, exp, l10n),
                    ),
                    const SizedBox(height: 12),
                    // 操作按钮区
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: Text(l10n.openConsole),
                              onPressed: () => onOpenConsole(exp.id),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showStop) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.stop, size: 16),
                                label: Text(l10n.stopExperiment),
                                onPressed: () => onStop(exp),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(
    BuildContext context,
    DateTime? dateTime,
    AppLocalizations l10n,
  ) {
    if (dateTime == null) return l10n.notStarted;
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'zh'
        ? DateFormat('yyyy-MM-dd HH:mm')
        : DateFormat('MM/dd/yyyy HH:mm', 'en');
    return format.format(dateTime);
  }

  String _formatDuration(
    BuildContext context,
    Experiment exp,
    AppLocalizations l10n,
  ) {
    if (exp.startedAt == null) return l10n.notStarted;
    final now = DateTime.now();
    final end = exp.endedAt ?? now;
    final duration = end.difference(exp.startedAt!);
    if (duration.inSeconds < 0) return l10n.notStarted;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// 获取状态对应的本地化文本。
String _statusLabelText(BuildContext context, ExperimentStatus status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status) {
    case ExperimentStatus.idle:
      return l10n.statusIdle;
    case ExperimentStatus.loaded:
      return l10n.statusLoaded;
    case ExperimentStatus.running:
      return l10n.statusRunning;
    case ExperimentStatus.paused:
      return l10n.statusPaused;
    case ExperimentStatus.completed:
      return l10n.statusCompleted;
    case ExperimentStatus.aborted:
      return l10n.statusAborted;
  }
}

/// 信息行组件（用于卡片内）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

// ============================================================
// _PaginationBar — 分页栏
// ============================================================

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrev,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final bool hasNext;
  final bool hasPrev;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  static const _pageSizeOptions = [10, 20, 50];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 总记录数
          Text(
            l10n.totalRecords(total),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // 页码
          if (!isMobile) ...[
            _buildPageButton(
              icon: Icons.chevron_left,
              enabled: hasPrev,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            const SizedBox(width: 4),
            ..._buildPageNumbers(context),
            const SizedBox(width: 4),
            _buildPageButton(
              icon: Icons.chevron_right,
              enabled: hasNext,
              onTap: () => onPageChanged(currentPage + 1),
            ),
            const SizedBox(width: 16),
          ] else ...[
            // 移动端简化分页
            _buildPageButton(
              icon: Icons.chevron_left,
              enabled: hasPrev,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.pageOf(currentPage, totalPages),
                style: theme.textTheme.bodySmall,
              ),
            ),
            _buildPageButton(
              icon: Icons.chevron_right,
              enabled: hasNext,
              onTap: () => onPageChanged(currentPage + 1),
            ),
            const SizedBox(width: 16),
          ],
          // 每页条数
          if (!isMobile)
            Row(
              children: [
                Text(
                  l10n.recordsPerPage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 64,
                  height: 32,
                  child: DropdownButtonFormField<int>(
                    initialValue: pageSize,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: _pageSizeOptions.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('$size'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) onPageSizeChanged(value);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: enabled ? onTap : null,
      visualDensity: VisualDensity.compact,
      tooltip: enabled ? null : null,
    );
  }

  List<Widget> _buildPageNumbers(BuildContext ctx) {
    final pages = <Widget>[];

    // 计算显示的页码范围
    int start = 1;
    int end = totalPages;
    const maxVisible = 5;

    if (totalPages > maxVisible) {
      if (currentPage <= 3) {
        end = maxVisible;
      } else if (currentPage >= totalPages - 2) {
        start = totalPages - maxVisible + 1;
      } else {
        start = currentPage - 2;
        end = currentPage + 2;
      }
    }

    if (start > 1) {
      pages.add(_buildPageNumber(ctx, 1));
      if (start > 2) {
        pages.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(_buildPageNumber(ctx, i));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) {
        pages.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
      pages.add(_buildPageNumber(ctx, totalPages));
    }

    return pages;
  }

  Widget _buildPageNumber(BuildContext ctx, int page) {
    final isActive = page == currentPage;
    final theme = Theme.of(ctx);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 32,
        height: 32,
        child: TextButton(
          onPressed: isActive ? null : () => onPageChanged(page),
          style: TextButton.styleFrom(
            backgroundColor: isActive ? colorScheme.primary : Colors.transparent,
            foregroundColor:
                isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            '$page',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
