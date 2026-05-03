/// 搜索/筛选/排序状态管理
///
/// 管理搜索查询、状态筛选和排序选项
/// 提供过滤后的工作台列表

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench.dart';
import 'workbench_list_provider.dart';

/// 排序选项
enum SortOption {
  default_,
  nameAsc,
  timeDesc,
  deviceCountDesc,
}

/// 排序选项显示名称
extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.default_:
        return '默认排序';
      case SortOption.nameAsc:
        return '名称 A-Z';
      case SortOption.timeDesc:
        return '创建时间 最新';
      case SortOption.deviceCountDesc:
        return '设备数 最多';
    }
  }
}

/// 搜索状态
class SearchState {
  final String query;
  final String? statusFilter;
  final SortOption sortOption;

  const SearchState({
    this.query = '',
    this.statusFilter,
    this.sortOption = SortOption.default_,
  });

  SearchState copyWith({
    String? query,
    String? statusFilter,
    bool clearStatusFilter = false,
    SortOption? sortOption,
  }) {
    return SearchState(
      query: query ?? this.query,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

/// 搜索状态 Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setStatusFilter(String? status) {
    if (status == null || status == '全部') {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void setSort(SortOption sort) {
    state = state.copyWith(sortOption: sort);
  }

  void clear() {
    state = const SearchState();
  }

  /// 过滤并排序工作台列表
  List<Workbench> apply(List<Workbench> workbenches) {
    var filtered = workbenches;

    // 搜索过滤
    if (state.query.isNotEmpty) {
      final query = state.query.toLowerCase();
      filtered = filtered.where((wb) {
        return wb.name.toLowerCase().contains(query) ||
            (wb.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 状态筛选
    if (state.statusFilter != null && state.statusFilter != '全部') {
      filtered = filtered.where((wb) {
        return wb.status.toLowerCase() == state.statusFilter!.toLowerCase();
      }).toList();
    }

    // 排序
    switch (state.sortOption) {
      case SortOption.default_:
        break;
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.timeDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.deviceCountDesc:
        // deviceCount not available, fallback to default
        break;
    }

    return filtered;
  }
}

/// 搜索状态 Provider
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

/// 过滤后的工作台列表 Provider
final filteredWorkbenchesProvider = Provider<List<Workbench>>((ref) {
  final workbenches = ref.watch(workbenchListProvider).workbenches;
  ref.watch(searchProvider); // React to search state changes
  final notifier = ref.read(searchProvider.notifier);
  return notifier.apply(workbenches);
});
