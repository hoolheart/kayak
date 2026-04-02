/// Method list provider
///
/// Manages the state of the method list page
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/method.dart';
import '../services/method_service.dart';

/// Method list state
class MethodListState {
  final List<Method> methods;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalItems;
  final bool hasMore;

  const MethodListState({
    this.methods = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalItems = 0,
    this.hasMore = false,
  });

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
  final MethodServiceInterface _service;

  MethodListNotifier(this._service) : super(const MethodListState());

  Future<void> loadMethods({int page = 1, bool append = false}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final response = await _service.getMethods(page: page);
      final newMethods =
          append ? [...state.methods, ...response.items] : response.items;
      final hasMore = newMethods.length < response.total;

      state = state.copyWith(
        methods: newMethods,
        isLoading: false,
        isLoadingMore: false,
        currentPage: page,
        totalItems: response.total,
        hasMore: hasMore,
        error: null,
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
    state = state.copyWith(error: null);
  }
}

/// Method list provider
final methodListProvider =
    StateNotifierProvider<MethodListNotifier, MethodListState>((ref) {
  final service = ref.watch(methodServiceProvider);
  return MethodListNotifier(service);
});
