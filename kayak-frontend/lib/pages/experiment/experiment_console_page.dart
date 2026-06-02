import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../models/experiment.dart';
import '../../models/experiment_message.dart';
import '../../providers/experiment_provider.dart';
import '../../providers/services.dart';
import '../../services/ws_service.dart';
import '../../utils/error_mapping.dart';
import '../../widgets/async_value_widget.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/toast.dart';

// ============================================================
// Log Level 和 Log Entry — 日志条目数据模型
// ============================================================

/// 日志级别枚举。
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// 日志条目。
class ExperimentLogEntry {
  const ExperimentLogEntry({
    required this.level,
    required this.timestamp,
    required this.message,
  });

  final LogLevel level;
  final String timestamp; // "HH:MM:SS"
  final String message;

  /// 将 StatusChange 转换为日志级别。
  static LogLevel fromStatusChange(StatusChange change) {
    final newStatus = change.newState.toUpperCase();
    if (newStatus == 'ERROR' || newStatus == 'ABORTED') return LogLevel.error;
    if (newStatus == 'WARN' || newStatus == 'PAUSED') return LogLevel.warn;
    if (newStatus == 'RUNNING' || newStatus == 'LOADED') return LogLevel.info;
    return LogLevel.info;
  }

  /// 格式化时间戳。
  static String formatTimestamp(String rfc3339) {
    try {
      final dt = DateTime.parse(rfc3339);
      return '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
    } catch (_) {
      return rfc3339.length >= 8 ? rfc3339.substring(11, 19) : rfc3339;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

// ============================================================
// 控制台骨架屏
// ============================================================

/// 试验控制台的骨架屏（加载状态占位）。
class ExperimentConsoleSkeleton extends StatelessWidget {
  const ExperimentConsoleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerBase = colorScheme.surfaceContainerHighest.withAlpha(128);

    Widget buildShimmer({double? width, double? height}) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: shimmerBase,
          borderRadius: BorderRadius.circular(4),
        ),
        child: SizedBox(
          height: height ?? 16,
          width: width,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 16, height: 48),
            buildShimmer(width: 200, height: 16),
            const SizedBox(width: 8),
            buildShimmer(width: 60, height: 24),
          ],
        ),
      ),
      body: isMobile
          ? _buildMobileSkeleton(context, buildShimmer)
          : _buildDesktopSkeleton(context, buildShimmer),
    );
  }

  Widget _buildDesktopSkeleton(
    BuildContext context,
    Widget Function({double? width, double? height}) buildShimmer,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 38,
            child: _buildPanelSkeleton(context, buildShimmer),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 62,
            child: _buildLogSkeleton(context, buildShimmer),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSkeleton(
    BuildContext context,
    Widget Function({double? width, double? height}) buildShimmer,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPanelSkeleton(context, buildShimmer),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildLogSkeleton(context, buildShimmer),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelSkeleton(
    BuildContext context,
    Widget Function({double? width, double? height}) buildShimmer,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildShimmer(width: 60, height: 12),
                const SizedBox(height: 4),
                buildShimmer(width: 120, height: 16),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(color: colorScheme.outlineVariant),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
                const SizedBox(height: 16),
                buildShimmer(width: 40, height: 12),
                const SizedBox(height: 4),
                buildShimmer(width: 140, height: 16),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(color: colorScheme.outlineVariant),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
                const SizedBox(height: 16),
                buildShimmer(width: 50, height: 12),
                const SizedBox(height: 4),
                buildShimmer(width: 100, height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              buildShimmer(width: 100, height: 40),
              const SizedBox(width: 16),
              buildShimmer(width: 100, height: 40),
              const SizedBox(width: 16),
              buildShimmer(width: 100, height: 40),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              buildShimmer(width: 100, height: 40),
              const SizedBox(width: 16),
              buildShimmer(width: 100, height: 40),
            ],
          ),
          const SizedBox(height: 32),
          const Center(
            child: Column(
              children: [
                SizedBox(height: 40, width: 12),
                SizedBox(height: 8),
                SizedBox(height: 32, width: 120),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogSkeleton(
    BuildContext context,
    Widget Function({double? width, double? height}) buildShimmer,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(8, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      buildShimmer(width: 52, height: 20),
                      const SizedBox(width: 8),
                      buildShimmer(width: 60, height: 16),
                      const SizedBox(width: 8),
                      buildShimmer(width: 200, height: 16),
                    ],
                  ),
                )),
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                buildShimmer(width: 80, height: 32),
                const Spacer(),
                buildShimmer(width: 60, height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ExperimentConsolePage — 试验控制台页面（核心页面）
// ============================================================

/// 试验控制台页面。
///
/// 路由: `/experiments/:id`
///
/// 功能：
/// 1. 控制面板：试验信息展示、控制按钮组（状态机）、计时器
/// 2. 执行日志：等宽字体、级别颜色、自动滚动、筛选、清空
/// 3. WebSocket 连接管理：状态指示、自动连接/断开、重连
class ExperimentConsolePage extends ConsumerStatefulWidget {
  const ExperimentConsolePage({super.key, required this.id});

  /// 试验 ID（来自路由参数）。
  final String id;

  @override
  ConsumerState<ExperimentConsolePage> createState() =>
      _ExperimentConsolePageState();
}

class _ExperimentConsolePageState
    extends ConsumerState<ExperimentConsolePage>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // 常量
  // ============================================================

  /// 日志轮询间隔。
  static const _pollInterval = Duration(seconds: 2);

  /// 最大日志数量。
  static const _maxLogCount = 1000;

  /// 状态颜色映射（Light 主题）。
  static const _statusColors = <ExperimentStatus, Color>{
    ExperimentStatus.idle: Color(0xFF44474E),
    ExperimentStatus.loaded: Color(0xFF1976D2),
    ExperimentStatus.running: Color(0xFF2E7D32),
    ExperimentStatus.paused: Color(0xFFED6C02),
    ExperimentStatus.completed: Color(0xFF2E7D32),
    ExperimentStatus.aborted: Color(0xFFBA1A1A),
  };

  /// 状态颜色映射（Dark 主题）。
  static const _darkStatusColors = <ExperimentStatus, Color>{
    ExperimentStatus.idle: Color(0xFFC4C6CF),
    ExperimentStatus.loaded: Color(0xFF90CAF9),
    ExperimentStatus.running: Color(0xFF81C784),
    ExperimentStatus.paused: Color(0xFFFFB74D),
    ExperimentStatus.completed: Color(0xFF81C784),
    ExperimentStatus.aborted: Color(0xFFFFB4AB),
  };

  /// 日志级别颜色（Light 主题）。
  static const _logLevelColors = <LogLevel, Color>{
    LogLevel.debug: Color(0xFF44474E),
    LogLevel.info: Color(0xFF1976D2),
    LogLevel.warn: Color(0xFFED6C02),
    LogLevel.error: Color(0xFFBA1A1A),
  };

  /// 日志级别颜色（Dark 主题）。
  static const _darkLogLevelColors = <LogLevel, Color>{
    LogLevel.debug: Color(0xFFC4C6CF),
    LogLevel.info: Color(0xFF90CAF9),
    LogLevel.warn: Color(0xFFFFB74D),
    LogLevel.error: Color(0xFFFFB4AB),
  };

  // ============================================================
  // 本地状态
  // ============================================================

  /// 日志条目列表。
  final List<ExperimentLogEntry> _logs = [];

  /// 已处理的状态变更 ID 集合（用于去重）。
  final Set<String> _processedChangeIds = {};

  /// 当前日志级别筛选（null = 全部）。
  LogLevel? _logFilter;

  /// 计时器当前值。
  Duration _elapsed = Duration.zero;

  /// 计时器是否正在运行。
  bool _isTimerRunning = false;

  /// 计时器 Timer 实例。
  Timer? _timer;

  /// 日志轮询 Timer 实例。
  Timer? _pollTimer;

  /// 当前正在进行的操作名称（null = 无操作）。
  String? _activeOperation;

  /// 日志列表滚动控制器。
  late ScrollController _scrollController;

  /// 滚动条是否在底部。
  bool _isAtBottom = true;

  /// 未读新日志数量。
  int _newLogCount = 0;

  /// 缓存的方法名称。
  String? _methodName;

  /// 方法名称是否正在加载。
  bool _methodNameLoading = false;

  /// WebSocket 连接状态。
  WsConnectionState _wsConnectionState = WsConnectionState.disconnected;

  /// WebSocket 重连尝试次数。
  int _wsReconnectAttempts = 0;

  /// 是否为首次 build（用于注册 listener）。
  bool _hasSetupListeners = false;

  /// 筛选后的日志。
  List<ExperimentLogEntry> get _filteredLogs {
    if (_logFilter == null) return _logs;
    return _logs.where((log) => log.level == _logFilter).toList();
  }

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // WS 连接状态监听（在 build 中通过 ref.listen 触发）
  // ============================================================

  void _setupListeners() {
    // 监听 WS 消息
    ref.listen(experimentWsProvider(widget.id), (prev, next) {
      next.whenData(_handleWsMessage);
    });

    // 监听 WS 连接状态
    ref.listen(
      experimentConnectionStateProvider(widget.id),
      (prev, next) {
        next.whenData((state) {
          if (mounted) {
            setState(() {
              _wsConnectionState = state;
              final wsService = ref.read(wsServiceProvider);
              _wsReconnectAttempts = wsService.reconnectAttempts;
            });
          }
        });
      },
    );

    // 监听试验详情变化
    ref.listen(experimentControlProvider(widget.id), (prev, next) {
      next.whenData((experiment) {
        _syncTimerState(experiment);
        _loadMethodName(experiment.methodId);
        _setupLogPolling(experiment);
      });
    });
  }

  // ============================================================
  // WS 消息处理
  // ============================================================

  void _handleWsMessage(ExperimentMessage message) {
    if (message is StatusChangeMessage) {
      _handleStatusChange(message.data);
    } else if (message is WsErrorMessage) {
      _handleWsError(message.data);
    }
  }

  void _handleStatusChange(StatusChangeData data) {
    // 更新试验状态
    final newStatusIndex = ExperimentStatus.values.indexWhere(
      (e) => e.name.toUpperCase() == data.newStatus,
    );
    if (newStatusIndex == -1) {
      debugPrint(
        'Warning: unknown experiment status from WS: ${data.newStatus}',
      );
      return;
    }
    final newStatus = ExperimentStatus.values[newStatusIndex];

    // 通过 notifier 的 updateStatus 方法更新
    ref
        .read(experimentControlProvider(widget.id).notifier)
        .updateStatus(newStatus);

    // 追加状态变更日志
    _addLog(ExperimentLogEntry(
      level: ExperimentLogEntry.fromStatusChange(
        StatusChange(
          id: '',
          experimentId: data.experimentId,
          previousState: data.oldStatus,
          newState: data.newStatus,
          operation: data.operation,
          userId: data.userId,
          timestamp: data.timestamp,
        ),
      ),
      timestamp: ExperimentLogEntry.formatTimestamp(data.timestamp),
      message: '试验状态变更: ${data.oldStatus} → ${data.newStatus}',
    ));
  }

  void _handleWsError(WsErrorData data) {
    _addLog(ExperimentLogEntry(
      level: LogLevel.error,
      timestamp: ExperimentLogEntry.formatTimestamp(
        DateTime.now().toUtc().toIso8601String(),
      ),
      message: '${data.error} (code: ${data.code})',
    ));
  }

  // ============================================================
  // 日志轮询
  // ============================================================

  void _setupLogPolling(Experiment experiment) {
    _pollTimer?.cancel();
    _pollTimer = null;

    if (experiment.status == ExperimentStatus.completed ||
        experiment.status == ExperimentStatus.aborted) {
      // Do one final fetch to capture the last state change entry
      // that may have been recorded at the moment of completion.
      _fetchFinalHistory();
      return;
    }

    if (experiment.status != ExperimentStatus.running &&
        experiment.status != ExperimentStatus.paused) {
      return;
    }

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted) return;
      try {
        final experimentService = ref.read(experimentServiceProvider);
        final history = await experimentService.getHistory(widget.id);
        _processHistory(history);
      } catch (_) {
        // 轮询失败静默处理
      }
    });
  }

  /// 在终止状态时执行一次最终历史拉取，确保最后一条状态变更被捕获。
  Future<void> _fetchFinalHistory() async {
    try {
      final experimentService = ref.read(experimentServiceProvider);
      final history = await experimentService.getHistory(widget.id);
      if (mounted) {
        _processHistory(history);
      }
    } catch (_) {
      // 静默处理
    }
  }

  void _processHistory(List<StatusChange> history) {
    bool hasNew = false;
    for (final change in history) {
      if (_processedChangeIds.contains(change.id)) continue;
      _processedChangeIds.add(change.id);

      _addLogInternal(ExperimentLogEntry(
        level: ExperimentLogEntry.fromStatusChange(change),
        timestamp: ExperimentLogEntry.formatTimestamp(change.timestamp),
        message:
            '${change.previousState} → ${change.newState} (${change.operation})',
      ));
      hasNew = true;
    }

    if (hasNew && mounted) {
      setState(() {});
      if (_isAtBottom) {
        _scrollToBottom();
      }
    }
  }

  void _addLogInternal(ExperimentLogEntry entry) {
    _logs.add(entry);
    if (_logs.length > _maxLogCount) {
      _logs.removeAt(0);
    }
  }

  void _addLog(ExperimentLogEntry entry) {
    if (!mounted) return;
    setState(() {
      _addLogInternal(entry);
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    } else {
      setState(() => _newLogCount++);
    }
  }

  // ============================================================
  // 计时器管理
  // ============================================================

  void _syncTimerState(Experiment experiment) {
    final wasRunning = _isTimerRunning;
    bool shouldRun = false;
    Duration newElapsed = _elapsed;

    switch (experiment.status) {
      case ExperimentStatus.running:
        if (experiment.startedAt != null) {
          newElapsed = DateTime.now().difference(experiment.startedAt!);
          shouldRun = true;
        }
      case ExperimentStatus.paused:
        shouldRun = false;
      case ExperimentStatus.completed:
      case ExperimentStatus.aborted:
        shouldRun = false;
        if (experiment.startedAt != null && experiment.endedAt != null) {
          newElapsed = experiment.endedAt!.difference(experiment.startedAt!);
        }
      case ExperimentStatus.idle:
      case ExperimentStatus.loaded:
        shouldRun = false;
        newElapsed = Duration.zero;
    }

    if (mounted) {
      setState(() {
        _elapsed = newElapsed;
        _isTimerRunning = shouldRun;
      });
    }

    if (shouldRun && !wasRunning) {
      _startTimer();
    } else if (!shouldRun && wasRunning) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final experiment =
        ref.read(experimentControlProvider(widget.id)).asData?.value;
    final startedAt = experiment?.startedAt;
    if (startedAt == null) {
      if (mounted) {
        setState(() {
          _elapsed = Duration.zero;
          _isTimerRunning = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isTimerRunning = true);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _elapsed = DateTime.now().difference(startedAt);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _isTimerRunning = false);
    }
  }

  // ============================================================
  // 方法名称加载
  // ============================================================

  Future<void> _loadMethodName(String? methodId) async {
    if (methodId == null || methodId.isEmpty) {
      setState(() {
        _methodName = null;
        _methodNameLoading = false;
      });
      return;
    }
    if (_methodName != null) return;

    setState(() => _methodNameLoading = true);
    try {
      final methodService = ref.read(methodServiceProvider);
      final method = await methodService.getById(methodId);
      if (mounted) {
        setState(() {
          _methodName = method.name;
          _methodNameLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _methodName = methodId;
          _methodNameLoading = false;
        });
      }
    }
  }

  // ============================================================
  // 控制操作
  // ============================================================

  Future<void> _executeOperation(String operation) async {
    if (_activeOperation != null) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _activeOperation = operation);

    try {
      final notifier = ref.read(experimentControlProvider(widget.id).notifier);
      switch (operation) {
        case 'load':
          final experiment =
              ref.read(experimentControlProvider(widget.id)).asData?.value;
          if (experiment?.methodId == null) {
            _showToast(loc.errorDefault);
            return;
          }
          await notifier.load(methodId: experiment!.methodId!);
          if (mounted) _showToast(loc.methodLoaded);
        case 'start':
          await notifier.start();
          if (mounted) _showToast(loc.experimentStarted);
        case 'pause':
          await notifier.pause();
          if (mounted) _showToast(loc.experimentPaused);
        case 'resume':
          await notifier.resume();
          if (mounted) _showToast(loc.experimentResumed);
        case 'stop':
          await notifier.stop();
          if (mounted) _showToast(loc.experimentStopped);
      }
    } catch (e) {
      if (mounted) {
        _showToast('${loc.operationFailed}: $e');
        // Only invalidate on non-transient errors (auth, not found, conflict)
        // to avoid discarding valid provider state on transient network issues.
        if (ErrorMapping.shouldInvalidate(e)) {
          ref.invalidate(experimentControlProvider(widget.id));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _activeOperation = null);
      }
    }
  }

  Future<void> _onStopPressed() async {
    final loc = AppLocalizations.of(context)!;
    final experiment =
        ref.read(experimentControlProvider(widget.id)).asData?.value;
    await ConfirmDialog.show(
      context: context,
      title: loc.confirmStopTitle,
      description: experiment != null
          ? loc.confirmStopDesc(experiment.name)
          : loc.confirmStopDesc(''),
      confirmLabel: loc.confirmStopAction,
      isDanger: true,
      onConfirm: () => _executeOperation('stop'),
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    Toast.show(context: context, message: message);
  }

  // ============================================================
  // 日志滚动管理
  // ============================================================

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isAtBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        if (isAtBottom) _newLogCount = 0;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    setState(() {
      _newLogCount = 0;
      _isAtBottom = true;
    });
  }

  // ============================================================
  // 按钮状态
  // ============================================================

  bool _isButtonEnabled(String buttonName) {
    if (_activeOperation != null) return false;
    final exp = ref.read(experimentControlProvider(widget.id)).asData?.value;
    if (exp == null) return false;

    switch (exp.status) {
      case ExperimentStatus.idle:
        return buttonName == 'load';
      case ExperimentStatus.loaded:
        return buttonName == 'start';
      case ExperimentStatus.running:
        return buttonName == 'pause' || buttonName == 'stop';
      case ExperimentStatus.paused:
        return buttonName == 'resume' || buttonName == 'stop';
      case ExperimentStatus.completed:
      case ExperimentStatus.aborted:
        return false;
    }
  }

  bool _isButtonLoading(String buttonName) {
    return _activeOperation == buttonName;
  }

  // ============================================================
  // 颜色工具
  // ============================================================

  Color _statusColor(BuildContext context, ExperimentStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark && _darkStatusColors.containsKey(status)) {
      return _darkStatusColors[status]!;
    }
    return _statusColors[status] ?? const Color(0xFF44474E);
  }

  Color _logLevelColor(BuildContext context, LogLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark && _darkLogLevelColors.containsKey(level)) {
      return _darkLogLevelColors[level]!;
    }
    return _logLevelColors[level] ?? const Color(0xFF44474E);
  }

  // ============================================================
  // UI 构建 — 主要入口
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // 设置监听器（仅首次 build 时注册）
    if (!_hasSetupListeners) {
      _hasSetupListeners = true;
      _setupListeners();
    }

    final experimentAsync = ref.watch(experimentControlProvider(widget.id));
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, themeData, colorScheme, experimentAsync),
      body: AsyncValueWidget(
        value: experimentAsync,
        dataBuilder: (e) => _buildContent(context, themeData, colorScheme, e),
        loadingBuilder: const ExperimentConsoleSkeleton(),
        errorBuilder: (error, stack) {
          final loc = AppLocalizations.of(context)!;
          final errorMsg = error.toString();
          final is404 = errorMsg.contains('404') ||
              errorMsg.contains('not found') ||
              errorMsg.contains('不存在');
          final is403 = errorMsg.contains('403') ||
              errorMsg.contains('forbidden') ||
              errorMsg.contains('权限');
          return ErrorView(
            title: is404
                ? loc.experimentNotFound
                : is403
                    ? loc.experimentNoPermission
                    : loc.loadFailed,
            description: is404
                ? loc.experimentNotFoundHint
                : loc.loadFailedHint,
            onRetry: () =>
                ref.invalidate(experimentControlProvider(widget.id)),
          );
        },
        onRetry: () => ref.invalidate(experimentControlProvider(widget.id)),
      ),
    );
  }

  // ============================================================
  // AppBar
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    AsyncValue<Experiment> experimentAsync,
  ) {
    final loc = AppLocalizations.of(context)!;
    final experiment = experimentAsync.asData?.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 400;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: colorScheme.outlineVariant),
      ),
      title: Row(
        children: [
          // 返回按钮
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: loc.backToList,
              onPressed: () => context.go('/experiments'),
            ),
          ),
          const SizedBox(width: 16),
          // 试验名称
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isVerySmall
                    ? 120
                    : isMobile
                        ? 200
                        : 400,
              ),
              child: Text(
                experiment?.name ?? loc.loading,
                style: themeData.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          if (experiment != null) ...[
            const SizedBox(width: 8),
            StatusBadge(
              status: experiment.status,
              compact: isVerySmall || isMobile,
            ),
          ],
          const Spacer(),
          // WS 连接指示器
          _buildWsIndicator(context, colorScheme, loc, isVerySmall),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ============================================================
  // WS 连接指示器
  // ============================================================

  Widget _buildWsIndicator(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations loc,
    bool isVerySmall,
  ) {
    final textTheme = Theme.of(context).textTheme;
    Color dotColor;
    String label;
    bool showReconnect = false;
    bool isBlinking = false;

    switch (_wsConnectionState) {
      case WsConnectionState.disconnected:
        dotColor = colorScheme.error;
        label = loc.wsDisconnected;
      case WsConnectionState.connecting:
        dotColor = colorScheme.tertiary;
        label = loc.wsConnecting;
        isBlinking = true;
      case WsConnectionState.connected:
        dotColor = Colors.green;
        label = loc.wsConnected;
      case WsConnectionState.reconnecting:
        dotColor = colorScheme.tertiary;
        label = '${loc.wsReconnecting} ($_wsReconnectAttempts/5)';
        isBlinking = true;
      case WsConnectionState.failed:
        dotColor = colorScheme.error;
        label = loc.wsFailed;
        showReconnect = true;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBlinking)
          _BlinkingDot(color: dotColor)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        if (!isVerySmall) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: dotColor),
          ),
        ],
        if (showReconnect) ...[
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () {
              final wsService = ref.read(wsServiceProvider);
              wsService.reconnect();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(loc.wsReconnect, style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // 主体内容
  // ============================================================

  Widget _buildContent(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildMobileLayout(context, themeData, colorScheme, experiment);
    }
    return _buildDesktopLayout(context, themeData, colorScheme, experiment);
  }

  // ============================================================
  // 桌面端布局（左右分栏）
  // ============================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200;
    final gap = isTablet ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(isTablet ? 16 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧控制面板
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: isTablet ? 320 : 400,
              maxWidth: isTablet ? 400 : 520,
            ),
            child: _buildControlPanel(
              context, themeData, colorScheme, experiment,
            ),
          ),
          SizedBox(width: gap),
          // 右侧日志区
          Expanded(
            child: _buildLogViewer(context, themeData, colorScheme),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 移动端布局（上下堆叠）
  // ============================================================

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    return Column(
      children: [
        // 控制面板（自适应高度，最多 50vh）
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildControlPanel(
              context, themeData, colorScheme, experiment,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 日志区（剩余空间）
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildLogViewer(context, themeData, colorScheme),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 控制面板
  // ============================================================

  Widget _buildControlPanel(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: isMobile
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 信息卡片
          _buildInfoCard(context, themeData, colorScheme, experiment),
          const SizedBox(height: 24),
          // 控制按钮组
          _buildControlButtons(
            context, themeData, colorScheme, experiment, isMobile,
          ),
          const SizedBox(height: 32),
          // 状态显示
          _buildStatusDisplay(context, themeData, colorScheme, experiment),
          // 计时器
          if (experiment.status != ExperimentStatus.idle &&
              experiment.status != ExperimentStatus.loaded)
            _buildTimerSection(context, themeData, colorScheme, experiment),
          // 终态额外信息
          if (experiment.status == ExperimentStatus.completed ||
              experiment.status == ExperimentStatus.aborted)
            _buildCompletedInfo(context, themeData, colorScheme, experiment),
        ],
      ),
    );
  }

  // ============================================================
  // 信息卡片
  // ============================================================

  Widget _buildInfoCard(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 方法
          _buildInfoRow(
            context, colorScheme,
            label: loc.methodLabel,
            value: _methodNameLoading
                ? null
                : (_methodName ?? experiment.methodId ?? loc.methodNotSet),
          ),
          if (experiment.methodId != null || _methodName != null) ...[
            const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(color: colorScheme.outlineVariant),
                ),
            const SizedBox(height: 16),
          ],
          // 创建时间
          _buildInfoRow(
            context, colorScheme,
            label: loc.createdAt,
            value: _formatDateTime(experiment.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ColorScheme colorScheme, {
    required String label,
    String? value,
  }) {
    final themeData = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeData.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (value != null)
          Text(
            value,
            style: themeData.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          )
        else
          _buildShimmerLine(context, width: 120),
      ],
    );
  }

  Widget _buildShimmerLine(
    BuildContext context, {
    double? width,
    double height = 16,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ============================================================
  // 控制按钮组
  // ============================================================

  Widget _buildControlButtons(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
    bool isMobile,
  ) {
    final loc = AppLocalizations.of(context)!;
    final btnHeight = isMobile ? 48.0 : 40.0;
    final minWidth = isMobile ? 80.0 : 100.0;

    Widget buildCtrlButton({
      required String label,
      required IconData icon,
      required String operation,
      Color? backgroundColor,
      Color? foregroundColor,
    }) {
      final enabled = _isButtonEnabled(operation);
      final loading = _isButtonLoading(operation);
      final opacity = (!enabled && !loading) ? 0.38 : 1.0;

      return Opacity(
        opacity: opacity,
        child: FilledButton.icon(
          onPressed:
              enabled && !loading ? () => _onButtonPressed(operation) : null,
          icon: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? colorScheme.onPrimary,
                    ),
                  ),
                )
              : Icon(icon, size: 20),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.primary,
            foregroundColor: foregroundColor ?? colorScheme.onPrimary,
            minimumSize: Size(minWidth, btnHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    final loadBtn = buildCtrlButton(
      label: loc.actionLoad,
      icon: Icons.download,
      operation: 'load',
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
    final startBtn = buildCtrlButton(
      label: loc.actionStart,
      icon: Icons.play_arrow,
      operation: 'start',
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
    final pauseBtn = buildCtrlButton(
      label: loc.actionPause,
      icon: Icons.pause,
      operation: 'pause',
      backgroundColor: colorScheme.tertiary,
      foregroundColor: colorScheme.onTertiary,
    );
    final resumeBtn = buildCtrlButton(
      label: loc.actionResume,
      icon: Icons.play_arrow,
      operation: 'resume',
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
    final stopBtn = buildCtrlButton(
      label: loc.actionStop,
      icon: Icons.stop,
      operation: 'stop',
      backgroundColor: colorScheme.errorContainer,
      foregroundColor: colorScheme.onErrorContainer,
    );

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [loadBtn, startBtn, pauseBtn, resumeBtn, stopBtn],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            loadBtn,
            const SizedBox(width: 16),
            startBtn,
            const SizedBox(width: 16),
            pauseBtn,
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [resumeBtn, const SizedBox(width: 16), stopBtn],
        ),
      ],
    );
  }

  void _onButtonPressed(String operation) {
    if (operation == 'stop') {
      _onStopPressed();
    } else {
      _executeOperation(operation);
    }
  }

  // ============================================================
  // 状态显示
  // ============================================================

  Widget _buildStatusDisplay(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final statusColor = _statusColor(context, experiment.status);

    // 状态显示文本
    String statusText;
    switch (experiment.status) {
      case ExperimentStatus.idle:
        statusText = 'IDLE';
      case ExperimentStatus.loaded:
        statusText = 'LOADED';
      case ExperimentStatus.running:
        statusText = 'RUNNING';
      case ExperimentStatus.paused:
        statusText = 'PAUSED';
      case ExperimentStatus.completed:
        statusText = 'COMPLETED';
      case ExperimentStatus.aborted:
        statusText = 'ABORTED';
    }

    // 终态副标题
    String? subtitle;
    if (experiment.status == ExperimentStatus.completed) {
      subtitle = loc.statusCompletedHint;
    } else if (experiment.status == ExperimentStatus.aborted) {
      subtitle = loc.statusAbortedHint;
    } else if (experiment.status == ExperimentStatus.running) {
      subtitle = loc.statusRunningHint;
    }

    return Center(
      child: Column(
        children: [
          Text(
            loc.statusLabel,
            style: themeData.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: isMobile ? 28 : 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: statusColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: themeData.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 计时器
  // ============================================================

  Widget _buildTimerSection(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // 计时器颜色：暂停/终态 = On Surface Variant
    final timerColor = experiment.status == ExperimentStatus.running
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    if (experiment.status == ExperimentStatus.completed ||
        experiment.status == ExperimentStatus.aborted) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: Column(
          children: [
            if (experiment.status == ExperimentStatus.paused)
              Text(
                loc.elapsedPaused,
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                loc.elapsedLabel,
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isMobile ? 32 : 36,
                fontWeight: FontWeight.w500,
                color: timerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 完成/中止额外信息
  // ============================================================

  Widget _buildCompletedInfo(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    Experiment experiment,
  ) {
    final loc = AppLocalizations.of(context)!;
    final statusColor = _statusColor(context, experiment.status);
    final isAborted = experiment.status == ExperimentStatus.aborted;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(color: colorScheme.outlineVariant),
          ),
          const SizedBox(height: 24),
          // 开始时间
          _buildInfoRowSmall(
            context, colorScheme,
            label: loc.startedLabel,
            value: experiment.startedAt != null
                ? _formatDateTime(experiment.startedAt!)
                : loc.notStarted,
          ),
          const SizedBox(height: 12),
          // 结束时间
          _buildInfoRowSmall(
            context, colorScheme,
            label: loc.endedLabel,
            value: experiment.endedAt != null
                ? _formatDateTime(experiment.endedAt!)
                : loc.notStarted,
          ),
          const SizedBox(height: 12),
          // 总运行时长
          _buildInfoRowSmall(
            context, colorScheme,
            label: loc.totalDurationLabel,
            value: _formatDuration(_elapsed),
            isMonospace: true,
          ),
          // 错误消息（仅 ABORTED）
          if (isAborted && experiment.errorMessage != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    experiment.errorMessage!,
                    style: themeData.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRowSmall(
    BuildContext context,
    ColorScheme colorScheme, {
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    final themeData = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: themeData.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 日志查看器
  // ============================================================

  Widget _buildLogViewer(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final fontSize = isMobile ? 12.0 : 13.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: isMobile
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        children: [
          // 日志列表区域
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  if (_filteredLogs.isEmpty)
                    _buildLogEmptyState(context, themeData, colorScheme)
                  else
                    ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        return _buildLogEntry(
                          context, themeData, colorScheme,
                          _filteredLogs[index],
                          fontSize: fontSize,
                        );
                      },
                    ),
                  // 浮动"新日志"按钮
                  if (_newLogCount > 0)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _buildFloatingNewLogsButton(
                        context, colorScheme, loc,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 日志控制栏
          _buildLogControlBar(context, themeData, colorScheme, loc),
        ],
      ),
    );
  }

  // ============================================================
  // 日志条目
  // ============================================================

  Widget _buildLogEntry(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    ExperimentLogEntry entry, {
    required double fontSize,
  }) {
    final levelColor = _logLevelColor(context, entry.level);
    final levelBg =
        levelColor.withAlpha(entry.level == LogLevel.error ? 30 : 20);
    final isError = entry.level == LogLevel.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 级别标签
          Container(
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: levelBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _logLevelLabel(entry.level),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize,
                fontWeight: isError ? FontWeight.w600 : FontWeight.w500,
                color: levelColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 时间戳
          Text(
            entry.timestamp,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          // 消息内容（自动换行）
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize,
                color: colorScheme.onSurface,
                fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _logLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warn:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }

  // ============================================================
  // 日志空状态
  // ============================================================

  Widget _buildLogEmptyState(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant.withAlpha(102),
            ),
            const SizedBox(height: 16),
            Text(
              loc.logEmptyTitle,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.logEmptyHint,
              style: themeData.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 浮动"新日志"按钮
  // ============================================================

  Widget _buildFloatingNewLogsButton(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return FilledButton.tonalIcon(
      onPressed: _scrollToBottom,
      icon: const Icon(Icons.arrow_downward, size: 18),
      label: Text(
        '$_newLogCount ${loc.newLogsLabel}',
        style: const TextStyle(fontSize: 12),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 2,
      ),
    );
  }

  // ============================================================
  // 日志控制栏
  // ============================================================

  Widget _buildLogControlBar(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // 级别筛选下拉框
          _buildLogFilter(context, themeData, colorScheme, loc),
          const Spacer(),
          // 清空按钮
          TextButton.icon(
            onPressed: _logs.isEmpty ? null : _clearLogs,
            icon: const Icon(Icons.clear_all, size: 18),
            label: Text(loc.clearLogsLabel),
            style: TextButton.styleFrom(
              foregroundColor: _logs.isEmpty
                  ? colorScheme.onSurface.withAlpha(97)
                  : colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogFilter(
    BuildContext context,
    ThemeData themeData,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogLevel?>(
          value: _logFilter,
          isDense: true,
          hint: Text(loc.filterAllLabel, style: themeData.textTheme.bodySmall),
          style: themeData.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          items: [
            DropdownMenuItem(
              child: Text(loc.filterAllLabel),
            ),
            DropdownMenuItem(
              value: LogLevel.info,
              child: Text(
                '[INFO]',
                style: TextStyle(
                  color: _logLevelColor(context, LogLevel.info),
                ),
              ),
            ),
            DropdownMenuItem(
              value: LogLevel.warn,
              child: Text(
                '[WARN]',
                style: TextStyle(
                  color: _logLevelColor(context, LogLevel.warn),
                ),
              ),
            ),
            DropdownMenuItem(
              value: LogLevel.error,
              child: Text(
                '[ERROR]',
                style: TextStyle(
                  color: _logLevelColor(context, LogLevel.error),
                ),
              ),
            ),
            DropdownMenuItem(
              value: LogLevel.debug,
              child: Text(
                '[DEBUG]',
                style: TextStyle(
                  color: _logLevelColor(context, LogLevel.debug),
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _logFilter = value);
          },
        ),
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _processedChangeIds.clear();
      _newLogCount = 0;
    });
  }

  // ============================================================
  // 工具方法
  // ============================================================

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }
}

// ============================================================
// _BlinkingDot — 闪烁圆点组件
// ============================================================

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot({required this.color});

  final Color color;

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
