import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workbench.dart';
import '../services/workbench_service.dart';
import 'services.dart';

// ============================================================
// WorkbenchListNotifier — 工作台列表状态管理器
// ============================================================

/// WorkbenchListNotifier — 工作台列表状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API。
/// 状态通过 [AsyncValue]<[List]<[Workbench]>> 表达列表生命周期：
/// - [AsyncLoading] — 首次加载中 / 刷新中 / 创建中
/// - [AsyncData] — 加载成功，包含工作台列表
/// - [AsyncError] — 加载失败，包含可读错误消息
///
/// 内部维护分页状态：
/// - [_currentPage] — 当前页码（从 1 开始）
/// - [_totalCount] — 总记录数
/// - [_hasMore] — 是否还有更多数据（用于 loadMore）
/// - [_search] — 当前搜索关键字
///
/// 职责：
/// 1. 首次加载工作台列表（build）
/// 2. 分页加载（loadMore）
/// 3. 搜索过滤（search）
/// 4. 创建后刷新（createWorkbench）
/// 5. 错误恢复（retry）
class WorkbenchListNotifier extends AsyncNotifier<List<Workbench>> {
  /// 当前页码（从 1 开始）
  int _currentPage = 1;

  /// 总记录数
  int _totalCount = 0;

  /// 是否还有更多数据
  bool _hasMore = false;

  /// 当前搜索关键字
  String? _search;

  /// 每页数量（默认 20，不重新赋值）
  final int _pageSize = 20;

  /// loadMore 是否正在执行（防并发）
  bool _isLoadingMore = false;

  /// 当前页码
  int get currentPage => _currentPage;

  /// 总记录数
  int get totalCount => _totalCount;

  /// 是否还有更多数据
  bool get hasMore => _hasMore;

  /// 当前搜索关键字
  String? get searchQuery => _search;

  @override
  Future<List<Workbench>> build() async {
    // 重置分页状态
    _currentPage = 1;
    _hasMore = false;
    _totalCount = 0;

    return _fetchWorkbenches();
  }

  /// 执行工作台列表查询
  ///
  /// 调用 [WorkbenchService.list] 获取数据，并更新分页状态。
  /// 传入 [page] 可指定页码，不传时使用 _currentPage。
  Future<List<Workbench>> _fetchWorkbenches({int? page}) async {
    final service = ref.read(workbenchServiceProvider);

    final response = await service.list(
      page: page ?? _currentPage,
      size: _pageSize,
      search: _search,
    );

    // 更新分页状态
    _totalCount = response.total;
    _currentPage = response.page;
    _hasMore = response.hasNext ??
        (response.page * response.size < response.total);

    return response.items;
  }

  /// 刷新列表（重置到第 1 页）
  ///
  /// 重新调用 build() 逻辑，从头加载数据。
  /// 刷新期间状态为 [AsyncLoading]。
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 加载更多（下一页）
  ///
  /// 将下一页数据追加到现有列表末尾。
  /// 如果已在加载中或没有更多数据，则忽略调用。
  Future<void> loadMore() async {
    // 并发控制：防止重复调用
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;

    // 保存当前列表数据，以便在失败时恢复
    final currentItems = state.value ?? <Workbench>[];

    try {
      _currentPage++;
      final moreItems = await _fetchWorkbenches(page: _currentPage);
      state = AsyncData([...currentItems, ...moreItems]);
    } catch (e, st) {
      // 加载下一页失败，回滚页码
      _currentPage--;
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// 搜索工作台
  ///
  /// [query] 搜索关键字。传入空字符串或 null 时清除搜索条件，
  /// 重新加载完整列表。
  ///
  /// 搜索时自动重置分页到第 1 页。
  Future<void> search(String query) async {
    _search = query.isEmpty ? null : query;

    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 创建工作台并刷新列表
  ///
  /// 调用 [WorkbenchService.create] 创建新工作台，
  /// 创建成功后自动刷新列表。
  /// 创建失败时不刷新列表，保留原有数据，状态转为 error。
  Future<void> createWorkbench({
    required String name,
    String? description,
    required String ownerType,
    required String ownerId,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(workbenchServiceProvider);
      await service.create(
        CreateWorkbenchRequest(
          name: name,
          description: description,
          ownerType: ownerType,
          ownerId: ownerId,
        ),
      );

      // 创建成功后刷新列表
      state = await AsyncValue.guard(build);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 重试（从错误状态恢复）
  ///
  /// 等同于 [refresh]，用于用户点击错误重试按钮。
  Future<void> retry() async {
    await refresh();
  }

  /// 将异常映射为用户可读的错误消息
  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络后重试';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _mapStatusCode(statusCode);

        default:
          return '网络异常，请稍后重试';
      }
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为用户可读的消息
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '资源冲突，请检查是否已存在相同名称的工作台';
      case 422:
        return '数据验证失败，请检查输入';
      case 500:
      case 502:
      case 503:
        return '服务暂时不可用，请稍后再试';
      default:
        return '操作失败，请重试（错误码: $statusCode）';
    }
  }
}

/// 工作台列表 Provider
///
/// 通过 [AsyncNotifierProvider] 暴露 [WorkbenchListNotifier]，
/// 提供 [AsyncValue]<[List]<[Workbench]>> 类型的列表状态。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final listState = ref.watch(workbenchListProvider);
///
/// // 调用方法
/// ref.read(workbenchListProvider.notifier).refresh();
/// ref.read(workbenchListProvider.notifier).search('keyword');
/// ref.read(workbenchListProvider.notifier).createWorkbench(name: 'New', ...);
/// ```
final workbenchListProvider =
    AsyncNotifierProvider<WorkbenchListNotifier, List<Workbench>>(
  WorkbenchListNotifier.new,
);

// ============================================================
// WorkbenchDetailNotifier — 工作台详情状态管理器
// ============================================================

/// WorkbenchDetailNotifier — 工作台详情状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API，通过 family 方式按工作台 ID 区分。
/// [id] 为 family 参数，表示工作台 ID。
///
/// 状态通过 [AsyncValue]<[Workbench]> 表达详情生命周期：
/// - [AsyncLoading] — 加载中
/// - [AsyncData] — 加载成功
/// - [AsyncError] — 加载失败
///
/// 职责：
/// 1. 加载工作台详情（build）
/// 2. 更新工作台（updateWorkbench）
/// 3. 删除工作台（deleteWorkbench）
class WorkbenchDetailNotifier extends AsyncNotifier<Workbench> {
  /// 创建 WorkbenchDetailNotifier 实例
  ///
  /// [id] 工作台 ID，由 family provider 传入。
  WorkbenchDetailNotifier(this.id);

  /// 工作台 ID（由 family 参数传入）
  final String id;

  @override
  Future<Workbench> build() async {
    final service = ref.read(workbenchServiceProvider);
    return service.getById(id);
  }

  /// 更新工作台
  ///
  /// 调用 [WorkbenchService.update] 更新工作台信息。
  /// 支持部分更新：只传递需要变更的字段。
  ///
  /// [data] 需要更新的字段，如 `{'name': 'New Name'}`
  /// 更新成功后自动更新状态为最新数据。
  /// 更新失败时状态转为 error。
  Future<void> updateWorkbench(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(workbenchServiceProvider);
      final updated = await service.update(id, data);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 删除工作台
  ///
  /// 调用 [WorkbenchService.delete] 删除工作台。
  /// 删除成功后保持 loading 状态，由 UI 层导航回列表页。
  /// 删除失败时状态转为 error，保留原有数据。
  Future<void> deleteWorkbench() async {
    state = const AsyncLoading();

    try {
      final service = ref.read(workbenchServiceProvider);
      await service.delete(id);
      // 删除成功后保持 loading 状态，
      // UI 层监听此状态并在适当时导航回列表
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 将异常映射为用户可读的错误消息
  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络后重试';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _mapStatusCode(statusCode);

        default:
          return '网络异常，请稍后重试';
      }
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为用户可读的消息
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '资源冲突，请检查是否已存在相同名称的工作台';
      case 422:
        return '数据验证失败，请检查输入';
      case 500:
      case 502:
      case 503:
        return '服务暂时不可用，请稍后再试';
      default:
        return '操作失败，请重试（错误码: $statusCode）';
    }
  }
}

/// 工作台详情 Provider
///
/// 通过 [AsyncNotifierProvider.family] 暴露 [WorkbenchDetailNotifier]，
/// 提供 [AsyncValue]<[Workbench]> 类型的详情状态，按工作台 ID 区分。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final detailState = ref.watch(workbenchDetailProvider('wb-1'));
///
/// // 调用方法
/// ref.read(workbenchDetailProvider('wb-1').notifier).updateWorkbench({'name': 'New'});
/// ref.read(workbenchDetailProvider('wb-1').notifier).deleteWorkbench();
/// ```
final workbenchDetailProvider = AsyncNotifierProvider.family<
  WorkbenchDetailNotifier,
  Workbench,
  String
>(
  WorkbenchDetailNotifier.new,
);
