/// Method list provider
///
/// Manages the state of the method list page
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/method.dart';
import '../services/method_service.dart';

/// Method list state
class MethodListState {
  const MethodListState({
    this.methods = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalItems = 0,
    this.hasMore = false,
  });
  final List<Method> methods;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalItems;
  final bool hasMore;

  MethodListState copyWith({
    List<Method>? methods,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalItems,
    bool? hasMore,
  }) {
    return MethodListState(
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Method list notifier
class MethodListNotifier extends StateNotifier<MethodListState> {
  MethodListNotifier(this._service) : super(const MethodListState());
  final MethodServiceInterface _service;

  Future<void> loadMethods({int page = 1, bool append = false}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await _service.getMethods(page: page);
      final newMethods =
          append ? [...state.methods, ...response.items] : response.items;
      // m5 fix: Use response.items.length to determine hasMore, not newMethods.length
      // which could exceed total after appending with stale data
      final hasMore = response.items.length >= response.size;

      state = state.copyWith(
        methods: newMethods,
        isLoading: false,
        isLoadingMore: false,
        currentPage: page,
        totalItems: response.total,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteMethod(String id) async {
    try {
      await _service.deleteMethod(id);
      // Reload current page
      await loadMethods(page: state.currentPage);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await loadMethods(page: state.currentPage + 1, append: true);
  }

  void clearError() {
    state = state.copyWith();
  }
}

/// Method list provider
final methodListProvider =
    StateNotifierProvider<MethodListNotifier, MethodListState>((ref) {
  final service = ref.watch(methodServiceProvider);
  return MethodListNotifier(service);
});
