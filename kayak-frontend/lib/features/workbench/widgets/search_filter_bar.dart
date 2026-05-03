/// 搜索筛选栏组件
///
/// 包含搜索输入框、状态筛选下拉和排序下拉
/// 搜索输入使用 300ms debounce

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

/// 状态筛选选项
const statusFilterOptions = ['全部', 'active', 'archived'];
const statusFilterLabels = ['全部', '活跃', '归档'];

/// 搜索筛选栏组件
class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // 搜索输入框
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索工作台...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 状态筛选下拉
          SizedBox(
            height: 36,
            child: _buildFilterDropdown(context),
          ),
          const SizedBox(width: 8),

          // 排序下拉
          SizedBox(
            height: 36,
            child: _buildSortDropdown(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentFilter = ref.watch(searchProvider).statusFilter ?? '全部';
    final currentLabel = currentFilter == 'active'
        ? '活跃'
        : currentFilter == 'archived'
            ? '归档'
            : '全部';

    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(searchProvider.notifier).setStatusFilter(value);
      },
      offset: const Offset(0, 40),
      child: OutlinedButton(
        onPressed: null, // PopupMenuButton handles tap
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.onSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              '筛选 $currentLabel',
              style: const TextStyle(fontSize: 13),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurface),
          ],
        ),
      ),
      itemBuilder: (context) {
        return List.generate(statusFilterOptions.length, (index) {
          final value = statusFilterOptions[index];
          final label = statusFilterLabels[index];
          return PopupMenuItem(
            value: value,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: currentFilter == value
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSort = ref.watch(searchProvider).sortOption;

    return PopupMenuButton<SortOption>(
      onSelected: (value) {
        ref.read(searchProvider.notifier).setSort(value);
      },
      offset: const Offset(0, 40),
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.onSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              '排序 ${currentSort.label}',
              style: const TextStyle(fontSize: 13),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurface),
          ],
        ),
      ),
      itemBuilder: (context) {
        return SortOption.values.map((option) {
          return PopupMenuItem(
            value: option,
            child: Text(
              option.label,
              style: TextStyle(
                fontWeight:
                    currentSort == option ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
    );
  }
}
