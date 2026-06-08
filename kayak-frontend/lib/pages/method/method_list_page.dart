import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../generated/app_localizations.dart';
import '../../models/method.dart';
import '../../providers/method_provider.dart';
import '../../widgets/async_value_widget.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/toast.dart';

// ============================================================
// MethodListPage — 方法列表页
// ============================================================

/// 方法列表页
///
/// 路由：`/methods`
/// 展示所有试验方法的卡片网格，支持搜索、新建、编辑、删除操作。
/// 响应式布局：桌面 3 列、平板 2 列、手机 1 列。
class MethodListPage extends ConsumerStatefulWidget {
  const MethodListPage({super.key});

  @override
  ConsumerState<MethodListPage> createState() => _MethodListPageState();
}

class _MethodListPageState extends ConsumerState<MethodListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(methodListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.methodList),
        actions: [
          _BuildMethodButton(
            onPressed: () => context.push('/methods/new/edit'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _SearchBar(
            controller: _searchController,
            onChanged: (value) {
              ref.read(methodListProvider.notifier).search(value);
            },
          ),
          // 内容区
          Expanded(
            child: AsyncValueWidget<List<Method>>(
              value: listState,
              loadingBuilder: const _MethodListSkeleton(),
              emptyBuilder: _buildEmpty(context),
              errorBuilder: (error, _) => ErrorView(
                title: l10n.loadFailed,
                description: l10n.loadFailedHint,
                onRetry: () =>
                    ref.read(methodListProvider.notifier).retry(),
              ),
              emptyCondition: (data) => data.isEmpty,
              dataBuilder: (methods) {
                // 检查是否搜索状态
                final isSearching = ref
                        .read(methodListProvider.notifier)
                        .searchQuery !=
                    null;
                if (methods.isEmpty && isSearching) {
                  return _buildSearchEmpty(context);
                }
                return _MethodGrid(
                  methods: methods,
                  onEdit: (method) =>
                      context.push('/methods/${method.id}/edit'),
                  onDelete: (method) => _confirmDelete(context, method),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return EmptyView(
      icon: Icons.science_outlined,
      title: '暂无方法',
      description: '点击下方按钮创建您的第一个方法',
      actionButton: FilledButton.icon(
        onPressed: () => context.push('/methods/new/edit'),
        icon: const Icon(Icons.add),
        label: const Text('创建第一个方法'),
      ),
    );
  }

  Widget _buildSearchEmpty(BuildContext context) {
    return EmptyView(
      icon: Icons.search_off,
      title: '未找到匹配的方法',
      description: '请尝试其他关键词',
      actionButton: TextButton(
        onPressed: () {
          _searchController.clear();
          ref.read(methodListProvider.notifier).search('');
        },
        child: const Text('清除搜索'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Method method) async {
    await ConfirmDialog.show(
      context: context,
      title: '删除方法？',
      description:
          '确定要删除方法「${method.name}」吗？此操作不可撤销，关联的试验记录不受影响。',
      onConfirm: () {
        ref
            .read(methodListProvider.notifier)
            .deleteMethod(method.id)
            .then((_) {
          if (context.mounted) {
            Toast.show(
              context: context,
              message: '方法已删除',
              type: ToastType.success,
            );
          }
        }).catchError((error) {
          if (context.mounted) {
            Toast.show(
              context: context,
              message: '删除失败：$error',
              type: ToastType.error,
            );
          }
        });
      },
      isDanger: true,
      dismissible: false,
    );
  }
}

// ============================================================
// 子组件
// ============================================================

/// 新建方法按钮（响应式：桌面显示文字+图标，移动仅图标）
class _BuildMethodButton extends StatelessWidget {
  const _BuildMethodButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return IconButton(
        icon: const Icon(Icons.add),
        tooltip: '新建方法',
        onPressed: onPressed,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('新建方法'),
      ),
    );
  }
}

/// 搜索栏
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '搜索方法名称或描述...',
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

/// 方法卡片网格
class _MethodGrid extends StatelessWidget {
  const _MethodGrid({
    required this.methods,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Method> methods;
  final ValueChanged<Method> onEdit;
  final ValueChanged<Method> onDelete;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 1024
            ? 2
            : 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算卡片宽度：网格总宽度减去间距后除以列数
        const gap = 16.0;
        final cardWidth = (constraints.maxWidth - gap * (crossAxisCount + 1)) /
            crossAxisCount;
        final childAspectRatio = cardWidth / 184;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: methods.length,
          itemBuilder: (context, index) {
            return _MethodCard(
              method: methods[index],
              onEdit: () => onEdit(methods[index]),
              onDelete: () => onDelete(methods[index]),
            );
          },
        );
      },
    );
  }
}

/// 方法卡片
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.onEdit,
    required this.onDelete,
  });

  final Method method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  int get _parameterCount {
    if (method.parameters != null) {
      return method.parameters!.length;
    }
    if (method.parameterSchema.isNotEmpty &&
        method.parameterSchema['properties'] is Map) {
      return (method.parameterSchema['properties'] as Map).length;
    }
    return 0;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      method.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CardActionButton(
                    icon: Icons.edit_outlined,
                    color: colorScheme.primary,
                    tooltip: '编辑',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _CardActionButton(
                    icon: Icons.delete_outlined,
                    color: colorScheme.error,
                    tooltip: '删除',
                    onTap: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 描述
              if (method.description != null &&
                  method.description!.isNotEmpty)
                Expanded(
                  child: Text(
                    method.description!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              const SizedBox(height: 8),
              // 底部信息
              Row(
                children: [
                  // 参数数量徽章
                  if (_parameterCount > 0)
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_parameterCount 参数',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '0 参数',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${_formatDate(method.createdAt)} ${_formatTime(method.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片操作按钮
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }
}

/// 方法列表骨架屏
class _MethodListSkeleton extends StatelessWidget {
  const _MethodListSkeleton();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 1024
            ? 2
            : 3;
    final skeletonCount = screenWidth < 600 ? 3 : (screenWidth < 1024 ? 4 : 6);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: skeletonCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.0,
        ),
        itemBuilder: (context, index) {
          return const _SkeletonMethodCard();
        },
      ),
    );
  }
}

/// 骨架方法卡片
class _SkeletonMethodCard extends StatelessWidget {
  const _SkeletonMethodCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行骨架
            Row(
              children: [
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 16,
                  ),
                ),
                SizedBox(width: 8),
                ShimmerBlock(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
                SizedBox(width: 4),
                ShimmerBlock(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
              ],
            ),
            SizedBox(height: 12),
            // 描述行骨架
            ShimmerBlock(
              width: double.infinity,
              height: 14,
            ),
            SizedBox(height: 6),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: ShimmerBlock(
                width: double.infinity,
                height: 14,
              ),
            ),
            Spacer(),
            // 底部信息骨架
            Row(
              children: [
                ShimmerBlock(
                  width: 80,
                  height: 28,
                  borderRadius: 14,
                ),
                Spacer(),
                ShimmerBlock(
                  width: 100,
                  height: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
