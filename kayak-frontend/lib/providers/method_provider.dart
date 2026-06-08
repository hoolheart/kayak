import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/method.dart';
import '../services/method_service.dart';
import 'services.dart';

// ============================================================
// MethodListNotifier — 方法列表状态管理器
// ============================================================

/// MethodListNotifier — 方法列表状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API。
/// 状态通过 [AsyncValue]<[List]<[Method]>> 表达列表生命周期。
///
/// 职责：
/// 1. 首次加载方法列表（build）
/// 2. 搜索过滤（search）
/// 3. 删除后刷新（deleteMethod）
/// 4. 错误恢复（retry）
class MethodListNotifier extends AsyncNotifier<List<Method>> {
  /// 当前搜索关键字
  String? _search;

  /// 当前搜索关键字
  String? get searchQuery => _search;

  @override
  Future<List<Method>> build() async {
    return _fetchMethods();
  }

  /// 执行方法列表查询
  Future<List<Method>> _fetchMethods() async {
    final service = ref.read(methodServiceProvider);

    if (_search != null && _search!.isNotEmpty) {
      final all = await service.list();
      return all
          .where((m) =>
              m.name.toLowerCase().contains(_search!.toLowerCase()) ||
              (m.description?.toLowerCase().contains(_search!.toLowerCase()) ??
                  false))
          .toList();
    }

    return service.list();
  }

  /// 刷新列表
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 搜索方法
  ///
  /// [query] 搜索关键字。传入空字符串或 null 时清除搜索条件。
  Future<void> search(String query) async {
    _search = query.isEmpty ? null : query;

    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 删除方法
  ///
  /// 调用 [MethodService.delete] 删除方法。
  /// 删除成功后自动刷新列表。
  /// 删除失败时不修改列表状态，保留原有数据。
  Future<void> deleteMethod(String id) async {
    try {
      final service = ref.read(methodServiceProvider);
      await service.delete(id);

      // 删除成功后刷新列表
      state = await AsyncValue.guard(build);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 重试（从错误状态恢复）
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
        return '资源冲突，请检查是否已存在相同名称的方法';
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

/// 方法列表 Provider
final methodListProvider =
    AsyncNotifierProvider<MethodListNotifier, List<Method>>(
  MethodListNotifier.new,
);

// ============================================================
// MethodDetailNotifier — 方法详情状态管理器
// ============================================================

/// MethodDetailNotifier — 方法详情状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API，通过 family 方式按方法 ID 区分。
/// [id] 为 family 参数，表示方法 ID。
///
/// 职责：
/// 1. 加载方法详情（build）
/// 2. 创建方法（createMethod）
/// 3. 更新方法（updateMethod）
class MethodDetailNotifier extends AsyncNotifier<Method> {
  /// 创建 MethodDetailNotifier 实例
  ///
  /// [id] 方法 ID，由 family provider 传入。
  MethodDetailNotifier(this.id);

  /// 方法 ID（由 family 参数传入）
  final String id;

  @override
  Future<Method> build() async {
    final service = ref.read(methodServiceProvider);
    return service.getById(id);
  }

  /// 创建方法
  ///
  /// 调用 [MethodService.create] 创建新方法。
  /// [data] 包含 name, description, processDefinition, parameterSchema
  /// 创建成功后自动更新状态。
  /// 创建失败时状态转为 error。
  Future<Method> createMethod(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(methodServiceProvider);
      final created = await service.create(data);
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
      rethrow;
    }
  }

  /// 更新方法
  ///
  /// 调用 [MethodService.update] 更新方法信息。
  /// [data] 需要更新的字段
  Future<Method> updateMethod(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(methodServiceProvider);
      final updated = await service.update(id, data);
      state = AsyncData(updated);
      return updated;
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
      rethrow;
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
        return '资源冲突，请检查是否已存在相同名称的方法';
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

/// 方法详情 Provider
final methodDetailProvider =
    AsyncNotifierProvider.family<MethodDetailNotifier, Method, String>(
  MethodDetailNotifier.new,
);
