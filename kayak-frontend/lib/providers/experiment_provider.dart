// ignore_for_file: sort_constructors_first

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/experiment.dart';
import '../models/experiment_message.dart';
import '../services/ws_service.dart';
import 'services.dart';

// ============================================================
// ExperimentListNotifier — 试验列表状态管理器
// ============================================================

/// ExperimentListNotifier — 试验列表状态管理器
///
/// 管理试验列表的完整生命周期，包括：
/// 1. 初始加载（build）
/// 2. 筛选（setFilter）
/// 3. 分页加载（loadMore）
/// 4. 刷新（refresh）
///
/// 内部维护：
/// - [_currentPage] / [_pageSize] — 当前分页状态
/// - [_total] — 总记录数
/// - 筛选参数 — 状态、创建时间范围、范围
class ExperimentListNotifier extends AsyncNotifier<List<Experiment>> {
  /// 当前页码（从 1 开始）
  int _currentPage = 1;

  /// 每页条数（默认与后端一致）
  int _pageSize = 10;

  /// 总记录数
  int _total = 0;

  /// 状态筛选
  ExperimentStatus? _statusFilter;

  /// 创建时间下限
  DateTime? _createdAfter;

  /// 创建时间上限
  DateTime? _createdBefore;

  /// 范围：'personal' | 'team'
  String? _scope;

  /// methodId → methodName 映射缓存
  final Map<String, String> _methodNames = {};

  /// 获取 methodId → methodName 映射（不可变快照）
  Map<String, String> get methodNames => Map.unmodifiable(_methodNames);

  @override
  Future<List<Experiment>> build() async {
    final service = ref.read(experimentServiceProvider);
    final response = await service.list(
      page: _currentPage,
      size: _pageSize,
      status: _statusFilter,
      createdAfter: _createdAfter,
      createdBefore: _createdBefore,
      scope: _scope,
    );
    _total = response.total;
    // 批量拉取方法名称（去重）
    await _fetchMethodNames(response.items);
    return response.items;
  }

  /// 从试验列表中提取不重复的 methodId，批量拉取方法名称。
  Future<void> _fetchMethodNames(List<Experiment> experiments) async {
    final methodIds = experiments
        .map((e) => e.methodId)
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => id!)
        .toSet()
        .difference(_methodNames.keys.toSet());
    if (methodIds.isEmpty) return;

    try {
      final methodService = ref.read(methodServiceProvider);
      for (final id in methodIds) {
        try {
          final method = await methodService.getById(id);
          _methodNames[id] = method.name;
        } catch (_) {
          // 单个方法加载失败，不阻塞整体列表，使用 ID 作为 fallback
          _methodNames[id] = id;
        }
      }
    } catch (_) {
      // 整体加载失败，忽略
    }
  }

  /// 刷新列表（回到第 1 页）。
  ///
  /// 刷新期间状态为 [AsyncLoading]。
  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 加载更多（下一页）。
  ///
  /// 将新数据追加到现有列表末尾。
  /// 如果已到最后一页，不发送请求。
  Future<void> loadMore() async {
    if (_currentPage * _pageSize >= _total) return;

    _currentPage++;
    final service = ref.read(experimentServiceProvider);
    try {
      final response = await service.list(
        page: _currentPage,
        size: _pageSize,
        status: _statusFilter,
        createdAfter: _createdAfter,
        createdBefore: _createdBefore,
        scope: _scope,
      );
      _total = response.total;

      // 批量拉取新试验的方法名称
      await _fetchMethodNames(response.items);

      // 追加到现有列表
      if (state.hasValue) {
        state = AsyncData([...state.value!, ...response.items]);
      }
    } catch (e, st) {
      _currentPage--; // 恢复页码
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 设置筛选条件，重置到第 1 页。
  Future<void> setFilter({
    ExperimentStatus? status,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? scope,
  }) async {
    _currentPage = 1;
    _statusFilter = status;
    _createdAfter = createdAfter;
    _createdBefore = createdBefore;
    _scope = scope;

    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

    /// 当前页码
  int get currentPage => _currentPage;

  /// 每页条数
  int get pageSize => _pageSize;

  /// 总记录数
  int get total => _total;

  /// 是否有下一页
  bool get hasNext => _currentPage * _pageSize < _total;

  /// 是否有上一页
  bool get hasPrev => _currentPage > 1;

  /// 跳转到指定页码。
  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _currentPage = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 设置每页条数并重置到第 1 页。
  Future<void> setPageSize(int size) async {
    _pageSize = size;
    _currentPage = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 当前筛选状态（用于 UI 显示）。
  ExperimentStatus? get statusFilter => _statusFilter;

  /// 当前创建时间下限。
  DateTime? get createdAfter => _createdAfter;

  /// 当前创建时间上限。
  DateTime? get createdBefore => _createdBefore;

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
          return _mapStatusCode(error.response?.statusCode);

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
        return '资源冲突，请检查是否已存在相同名称';
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

/// 试验列表 Provider
///
/// 通过 [AsyncNotifierProvider] 暴露 [ExperimentListNotifier]，
/// 提供 [AsyncValue]<[List]<[Experiment]>> 类型的列表状态。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final listState = ref.watch(experimentListProvider);
///
/// // 调用方法
/// ref.read(experimentListProvider.notifier).refresh();
/// ref.read(experimentListProvider.notifier).setFilter(status: ExperimentStatus.running);
/// ref.read(experimentListProvider.notifier).loadMore();
/// ```
final experimentListProvider =
    AsyncNotifierProvider<ExperimentListNotifier, List<Experiment>>(
  ExperimentListNotifier.new,
);

// ============================================================
// ExperimentControlNotifier — 试验控制状态管理器
// ============================================================

/// ExperimentControlNotifier — 试验控制状态管理器
///
/// 管理单个试验的详情和控制操作。
/// 使用 family 方式按 [experimentId] 区分。
///
/// 职责：
/// 1. 加载试验详情（build）
/// 2. 执行生命周期控制操作（load/start/pause/resume/stop）
/// 3. 状态合法性校验（防误操作）
/// 4. 防重复提交
/// 5. 加载状态历史
///
/// 状态校验矩阵（前端快速校验）：
/// | 当前状态 \\ 操作 | load | start | pause | resume | stop |
/// |-----------------|:----:|:-----:|:-----:|:------:|:----:|
/// | IDLE            |  ✅  |  ❌   |  ❌   |  ❌    |  ❌  |
/// | LOADED          |  ❌  |  ✅   |  ❌   |  ❌    |  ❌  |
/// | RUNNING         |  ❌  |  ❌   |  ✅   |  ❌    |  ✅  |
/// | PAUSED          |  ❌  |  ❌   |  ❌   |  ✅    |  ✅  |
/// | COMPLETED       |  ❌  |  ❌   |  ❌   |  ❌    |  ❌  |
/// | ABORTED         |  ❌  |  ❌   |  ❌   |  ❌    |  ❌  |
class ExperimentControlNotifier extends AsyncNotifier<Experiment> {
  /// 创建 ExperimentControlNotifier 实例。
  ///
  /// [experimentId] 试验 ID，由 family provider 传入。
  ExperimentControlNotifier(this._experimentId);

  /// 试验 ID（由 family 参数传入）
  final String _experimentId;

  /// 操作互斥标志，防止并发操作
  bool _isOperationInProgress = false;

  /// 当前是否正在执行控制操作
  bool get isOperationInProgress => _isOperationInProgress;

  @override
  Future<Experiment> build() async {
    final service = ref.read(experimentServiceProvider);
    final experiment = await service.getById(_experimentId);
    return experiment;
  }

  /// 载入试验方法。
  ///
  /// [methodId] 方法 ID
  Future<void> load({required String methodId}) async {
    await _executeControl(
      'load',
      () => ref.read(experimentServiceProvider).load(
            _experimentId,
            methodId: methodId,
          ),
    );
  }

  /// 开始试验。
  Future<void> start() async {
    await _executeControl(
      'start',
      () => ref.read(experimentServiceProvider).start(_experimentId),
    );
  }

  /// 暂停试验。
  Future<void> pause() async {
    await _executeControl(
      'pause',
      () => ref.read(experimentServiceProvider).pause(_experimentId),
    );
  }

  /// 继续试验。
  Future<void> resume() async {
    await _executeControl(
      'resume',
      () => ref.read(experimentServiceProvider).resume(_experimentId),
    );
  }

  /// 停止试验（回到 LOADED 状态）。
  Future<void> stop() async {
    await _executeControl(
      'stop',
      () => ref.read(experimentServiceProvider).stop(_experimentId),
    );
  }

  /// 获取状态变更历史。
  Future<List<StatusChange>> loadHistory() async {
    final service = ref.read(experimentServiceProvider);
    return service.getHistory(_experimentId);
  }

  /// 从 WebSocket 状态变更消息更新试验状态。
  ///
  /// 此方法用于在接收到 WS status_change 消息时，
  /// 从外部更新 ExperimentControlNotifier 的状态，
  /// 而无需重新从后端加载。
  void updateStatus(ExperimentStatus newStatus, {DateTime? startedAt}) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(
        status: newStatus,
        startedAt: startedAt ?? state.value!.startedAt,
      ));
    }
  }

  /// 控制操作通用执行模式。
  ///
  /// 1. 校验状态合法性
  /// 2. 防重复提交检测
  /// 3. 设置 loading 状态
  /// 4. 调用 ExperimentService
  /// 5. 成功后更新本地状态（Experiment 的 status 字段）
  /// 6. 失败后恢复为之前的状态
  Future<void> _executeControl(
    String action,
    Future<ExperimentControlDto> Function() call,
  ) async {
    // 1. 状态校验
    _validateStateTransition(action);

    // 2. 防重复提交
    if (_isOperationInProgress) {
      throw StateError('操作正在进行中，请稍后重试');
    }

    _isOperationInProgress = true;
    final previousState = state;
    state = const AsyncLoading();

    try {
      final controlDto = await call();

      // 3. 使用控制操作返回的 DTO 更新本地状态
      if (state.hasValue || previousState.hasValue) {
        final current = previousState.value ?? state.value;
        if (current != null) {
          final newStatus = ExperimentStatus.values.firstWhere(
            (e) => e.name.toUpperCase() == controlDto.status,
            orElse: () => current.status,
          );
          state = AsyncData(current.copyWith(
            status: newStatus,
            startedAt: controlDto.startedAt != null
                ? DateTime.tryParse(controlDto.startedAt!)
                : current.startedAt,
          ));
        }
      }
    } catch (e, st) {
      // 4. 失败恢复
      state = AsyncError(_mapError(e), st);
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 状态合法性校验。
  ///
  /// 根据当前状态判断是否允许执行指定操作。
  /// 如果不允许，抛出 [StateError]。
  void _validateStateTransition(String action) {
    if (!state.hasValue) return; // 尚未加载，不校验

    final experiment = state.value;
    if (experiment == null) return;

    final currentStatus = experiment.status;

    switch (action) {
      case 'load':
        if (currentStatus != ExperimentStatus.idle) {
          throw StateError('当前状态不允许载入操作（仅 IDLE 状态可执行 load）');
        }
      case 'start':
        if (currentStatus != ExperimentStatus.loaded) {
          throw StateError('当前状态不允许开始操作（仅 LOADED 状态可执行 start）');
        }
      case 'pause':
        if (currentStatus != ExperimentStatus.running) {
          throw StateError('当前状态不允许暂停操作（仅 RUNNING 状态可执行 pause）');
        }
      case 'resume':
        if (currentStatus != ExperimentStatus.paused) {
          throw StateError('当前状态不允许继续操作（仅 PAUSED 状态可执行 resume）');
        }
      case 'stop':
        if (currentStatus != ExperimentStatus.running &&
            currentStatus != ExperimentStatus.paused) {
          throw StateError('当前状态不允许停止操作（仅 RUNNING/PAUSED 状态可执行 stop）');
        }
    }
  }

  /// 将异常映射为用户可读的错误消息。
  String _mapError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络后重试';

        case DioExceptionType.badResponse:
          return _mapStatusCode(error.response?.statusCode);

        default:
          return '网络异常，请稍后重试';
      }
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为用户可读的消息。
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '试验不存在';
      case 409:
        return '资源冲突';
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

/// 试验控制 Provider
///
/// 通过 [AsyncNotifierProvider.family] 暴露 [ExperimentControlNotifier]，
/// 提供 [AsyncValue]<[Experiment]> 类型的详情状态，按试验 ID 区分。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final detailState = ref.watch(experimentControlProvider('exp-123'));
///
/// // 调用方法
/// ref.read(experimentControlProvider('exp-123').notifier).start();
/// ref.read(experimentControlProvider('exp-123').notifier).load(methodId: 'm-001');
/// ```
final experimentControlProvider = AsyncNotifierProvider.family<
  ExperimentControlNotifier,
  Experiment,
  String
>(
  ExperimentControlNotifier.new,
);

// ============================================================
// WebSocket Stream Provider
// ============================================================

/// WebSocket 消息流 Provider（自动连接/断开）。
///
/// 按试验 ID 区分。进入页面时自动连接 WebSocket，
/// 页面销毁时自动断开。
///
/// 读取方式：
/// ```dart
/// final messageStream = ref.watch(experimentWsProvider('exp-123'));
///
/// // 在 Widget 中：
/// ref.listen(experimentWsProvider('exp-123'), (prev, next) {
///   next.whenData((message) {
///     // 处理消息
///   });
/// });
/// ```
final experimentWsProvider =
    StreamProvider.family<ExperimentMessage, String>(
  (ref, experimentId) {
    final wsService = ref.read(wsServiceProvider);
    final authService = ref.read(authServiceProvider);
    final token = authService.accessToken ?? '';

    final stream = wsService.connect(experimentId, token);

    // Provider 销毁时自动断开
    ref.onDispose(wsService.disconnect);

    return stream;
  },
);

/// WebSocket 连接状态 Provider
///
/// 按试验 ID 区分。提供 [WsConnectionState] 流，
/// 用于 UI 连接状态指示。
///
/// 读取方式：
/// ```dart
/// final connState = ref.watch(experimentConnectionStateProvider('exp-123'));
/// ```
final experimentConnectionStateProvider =
    StreamProvider.family<WsConnectionState, String>(
  (ref, experimentId) {
    final wsService = ref.read(wsServiceProvider);
    return wsService.connectionState;
  },
);
