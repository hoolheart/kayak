/// Experiment console provider
///
/// Manages the state of the experiment console page
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment.dart';
import '../services/experiment_control_service.dart';
import '../services/experiment_ws_client.dart';
import '../../methods/models/method.dart';
import '../../methods/services/method_service.dart';

/// Log entry for experiment console
class ConsoleLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;

  const ConsoleLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  @override
  String toString() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '[$timeStr] [$level] $message';
  }
}

/// Current control operation type (m-04 fix)
enum ControlOperation {
  load,
  start,
  pause,
  resume,
  stop,
}

/// Experiment console state
class ExperimentConsoleState {
  final Experiment? experiment;
  final List<Method> availableMethods;
  final String? selectedMethodId;
  final Map<String, dynamic> parameterValues;
  final List<ConsoleLogEntry> logs;
  final bool isLoading;
  final bool isControlling;
  // m-04 fix: Track which operation is currently in progress
  final ControlOperation? currentOperation;
  final String? error;
  final bool wsConnected;
  // M-04 fix: Auto-scroll state and new logs indicator
  final bool autoScrollEnabled;
  final bool newLogsAvailable;
  // M-01 fix: Parameter validation errors
  final Map<String, String?> parameterErrors;

  const ExperimentConsoleState({
    this.experiment,
    this.availableMethods = const [],
    this.selectedMethodId,
    this.parameterValues = const {},
    this.logs = const [],
    this.isLoading = false,
    this.isControlling = false,
    this.currentOperation,
    this.error,
    this.wsConnected = false,
    this.autoScrollEnabled = true,
    this.newLogsAvailable = false,
    this.parameterErrors = const {},
  });

  ExperimentConsoleState copyWith({
    Experiment? experiment,
    List<Method>? availableMethods,
    String? selectedMethodId,
    Map<String, dynamic>? parameterValues,
    List<ConsoleLogEntry>? logs,
    bool? isLoading,
    bool? isControlling,
    ControlOperation? currentOperation,
    bool clearCurrentOperation = false,
    String? error,
    bool? wsConnected,
    bool? autoScrollEnabled,
    bool? newLogsAvailable,
    Map<String, String?>? parameterErrors,
  }) {
    return ExperimentConsoleState(
      experiment: experiment ?? this.experiment,
      availableMethods: availableMethods ?? this.availableMethods,
      selectedMethodId: selectedMethodId ?? this.selectedMethodId,
      parameterValues: parameterValues ?? this.parameterValues,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isControlling: isControlling ?? this.isControlling,
      currentOperation: clearCurrentOperation
          ? null
          : (currentOperation ?? this.currentOperation),
      error: error,
      wsConnected: wsConnected ?? this.wsConnected,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      newLogsAvailable: newLogsAvailable ?? this.newLogsAvailable,
      parameterErrors: parameterErrors ?? this.parameterErrors,
    );
  }

  /// Whether the load button should be enabled (C-02 fix: allow idle, completed, aborted)
  bool get canLoad =>
      experiment != null &&
      selectedMethodId != null &&
      (experiment!.status == ExperimentStatus.idle ||
          experiment!.status == ExperimentStatus.completed ||
          experiment!.status == ExperimentStatus.aborted);

  /// Whether the start button should be enabled (C-02 fix: only loaded, not paused)
  bool get canStart =>
      experiment != null && experiment!.status == ExperimentStatus.loaded;

  /// Whether the pause button should be enabled
  bool get canPause =>
      experiment != null && experiment!.status == ExperimentStatus.running;

  /// Whether the resume button should be enabled
  bool get canResume =>
      experiment != null && experiment!.status == ExperimentStatus.paused;

  /// Whether the stop button should be enabled
  bool get canStop =>
      experiment != null &&
      (experiment!.status == ExperimentStatus.running ||
          experiment!.status == ExperimentStatus.paused);

  /// Get status label
  String get statusLabel {
    if (experiment == null) return '无试验';
    switch (experiment!.status) {
      case ExperimentStatus.idle:
        return '空闲';
      case ExperimentStatus.loaded:
        return '已载入';
      case ExperimentStatus.running:
        return '运行中';
      case ExperimentStatus.paused:
        return '已暂停';
      case ExperimentStatus.completed:
        return '已完成';
      case ExperimentStatus.aborted:
        return '已中止';
    }
  }
}

/// Experiment console notifier
class ExperimentConsoleNotifier extends StateNotifier<ExperimentConsoleState> {
  final ExperimentControlServiceInterface _controlService;
  final MethodServiceInterface _methodService;
  ExperimentWebSocketClient? _wsClient;

  ExperimentConsoleNotifier(
    this._controlService,
    this._methodService,
  ) : super(const ExperimentConsoleState());

  /// Initialize the console - load methods and optionally load/create experiment
  /// C-05 fix: Accept optional experimentId to load existing experiment
  Future<void> initialize({String? experimentId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load available methods
      final methodsResponse =
          await _methodService.getMethods(page: 1, size: 100);
      final methods = methodsResponse.items;

      // Load existing experiment or create new one
      Experiment experiment;
      if (experimentId != null) {
        experiment = await _controlService.getExperimentStatus(experimentId);
        _addLog('info', '已加载试验: ${experiment.name}');
      } else {
        experiment = await _controlService.createExperiment();
        _addLog('info', '试验已创建: ${experiment.name}');
      }

      state = state.copyWith(
        experiment: experiment,
        availableMethods: methods,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select a method (M-05 fix: check experiment state before switching)
  bool selectMethod(String methodId) {
    // M-05 fix: Check if experiment is in a state that allows method switching
    if (state.experiment != null) {
      final status = state.experiment!.status;
      if (status == ExperimentStatus.running ||
          status == ExperimentStatus.paused) {
        // Cannot switch method while experiment is running or paused
        _addLog('warn', '请先停止当前试验再切换方法');
        return false;
      }
    }

    state = state.copyWith(selectedMethodId: methodId);

    // Load parameter defaults from method
    final method = state.availableMethods.firstWhere(
      (m) => m.id == methodId,
      orElse: () => state.availableMethods.first,
    );

    final params = <String, dynamic>{};
    final errors = <String, String?>{};
    for (final entry in method.parameterSchema.entries) {
      final schema = entry.value as Map<String, dynamic>;
      params[entry.key] = schema['default'];
      errors[entry.key] = null; // Clear errors for new method's params
    }
    state = state.copyWith(parameterValues: params, parameterErrors: errors);
    return true;
  }

  /// M-01 fix: Validate a parameter value against its schema
  String? validateParameterValue(
      String name, dynamic value, Map<String, dynamic> schema) {
    final type = schema['type'] as String? ?? 'string';

    switch (type) {
      case 'number':
        if (value is! num) {
          return '必须是有效数字';
        }
        // Check min/max constraints
        if (schema.containsKey('min')) {
          final min = (schema['min'] as num).toDouble();
          if ((value as num).toDouble() < min) {
            return '最小值为$min';
          }
        }
        if (schema.containsKey('max')) {
          final max = (schema['max'] as num).toDouble();
          if ((value as num).toDouble() > max) {
            return '最大值为$max';
          }
        }
        break;
      case 'integer':
        if (value is! int) {
          // Allow num to pass for integers since form returns num
          if (value is num && value.toInt() != value.toDouble()) {
            return '必须是整数';
          }
        }
        if (schema.containsKey('min')) {
          final min = (schema['min'] as num).toInt();
          if ((value as num).toInt() < min) {
            return '最小值为$min';
          }
        }
        if (schema.containsKey('max')) {
          final max = (schema['max'] as num).toInt();
          if ((value as num).toInt() > max) {
            return '最大值为$max';
          }
        }
        break;
      case 'string':
        if (schema['required'] == true &&
            (value == null || value.toString().isEmpty)) {
          return '不能为空';
        }
        if (schema.containsKey('minLength')) {
          final minLen = schema['minLength'] as int;
          if (value.toString().length < minLen) {
            return '最短${minLen}个字符';
          }
        }
        if (schema.containsKey('maxLength')) {
          final maxLen = schema['maxLength'] as int;
          if (value.toString().length > maxLen) {
            return '最长${maxLen}个字符';
          }
        }
        break;
    }
    return null;
  }

  /// Update a parameter value with validation
  void updateParameter(String name, dynamic value) {
    // Get the schema for this parameter
    final method = state.availableMethods.firstWhere(
      (m) => m.id == state.selectedMethodId,
      orElse: () => state.availableMethods.first,
    );
    final schema = method.parameterSchema[name] as Map<String, dynamic>?;

    // Validate if schema exists
    String? error;
    if (schema != null) {
      error = validateParameterValue(name, value, schema);
    }

    // Update value and clear error for this parameter
    final params = Map<String, dynamic>.from(state.parameterValues);
    params[name] = value;
    final errors = Map<String, String?>.from(state.parameterErrors);
    errors[name] = error;

    state = state.copyWith(parameterValues: params, parameterErrors: errors);
  }

  // M-02 fix: Reset all parameters to their default values
  void resetParametersToDefaults() {
    if (state.selectedMethodId == null) return;

    final method = state.availableMethods.firstWhere(
      (m) => m.id == state.selectedMethodId,
      orElse: () => state.availableMethods.first,
    );

    final params = <String, dynamic>{};
    final errors = <String, String?>{};
    for (final entry in method.parameterSchema.entries) {
      final schema = entry.value as Map<String, dynamic>;
      params[entry.key] = schema['default'];
      errors[entry.key] = null; // Clear validation errors
    }
    state = state.copyWith(parameterValues: params, parameterErrors: errors);
  }

  /// Load method into experiment (C-01 fix: now passes parameters)
  Future<void> loadExperiment() async {
    if (state.selectedMethodId == null || state.experiment == null) return;

    // m-04 fix: Set currentOperation to track which operation is in progress
    state = state.copyWith(
        isControlling: true,
        currentOperation: ControlOperation.load,
        error: null);

    try {
      // C-01 fix: pass parameter values to backend
      final experiment = await _controlService.loadExperiment(
        state.experiment!.id,
        state.selectedMethodId!,
        state.parameterValues,
      );

      state = state.copyWith(
          experiment: experiment,
          isControlling: false,
          clearCurrentOperation: true);
      _addLog('info', '方法已载入');
    } catch (e) {
      // m-05 fix: Try to sync state on state conflict error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('state') || errorStr.contains('invalid')) {
        await _syncStateFromServer();
      }
      state = state.copyWith(
          isControlling: false,
          clearCurrentOperation: true,
          error: e.toString());
      _addLog('error', '载入失败: $e');
    }
  }

  /// Start experiment
  Future<void> startExperiment() async {
    if (state.experiment == null) return;

    // m-04 fix: Set currentOperation
    state = state.copyWith(
        isControlling: true,
        currentOperation: ControlOperation.start,
        error: null);

    try {
      final experiment =
          await _controlService.startExperiment(state.experiment!.id);
      state = state.copyWith(
          experiment: experiment,
          isControlling: false,
          clearCurrentOperation: true);
      _addLog('info', '试验开始');
    } catch (e) {
      // m-05 fix: Try to sync state on state conflict error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('state') || errorStr.contains('invalid')) {
        await _syncStateFromServer();
      }
      state = state.copyWith(
          isControlling: false,
          clearCurrentOperation: true,
          error: e.toString());
      _addLog('error', '启动失败: $e');
    }
  }

  /// Pause experiment
  Future<void> pauseExperiment() async {
    if (state.experiment == null) return;

    // m-04 fix: Set currentOperation
    state = state.copyWith(
        isControlling: true,
        currentOperation: ControlOperation.pause,
        error: null);

    try {
      final experiment =
          await _controlService.pauseExperiment(state.experiment!.id);
      state = state.copyWith(
          experiment: experiment,
          isControlling: false,
          clearCurrentOperation: true);
      _addLog('info', '试验已暂停');
    } catch (e) {
      // m-05 fix: Try to sync state on state conflict error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('state') || errorStr.contains('invalid')) {
        await _syncStateFromServer();
      }
      state = state.copyWith(
          isControlling: false,
          clearCurrentOperation: true,
          error: e.toString());
      _addLog('error', '暂停失败: $e');
    }
  }

  /// Resume experiment
  Future<void> resumeExperiment() async {
    if (state.experiment == null) return;

    // m-04 fix: Set currentOperation
    state = state.copyWith(
        isControlling: true,
        currentOperation: ControlOperation.resume,
        error: null);

    try {
      final experiment =
          await _controlService.resumeExperiment(state.experiment!.id);
      state = state.copyWith(
          experiment: experiment,
          isControlling: false,
          clearCurrentOperation: true);
      _addLog('info', '试验继续');
    } catch (e) {
      // m-05 fix: Try to sync state on state conflict error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('state') || errorStr.contains('invalid')) {
        await _syncStateFromServer();
      }
      state = state.copyWith(
          isControlling: false,
          clearCurrentOperation: true,
          error: e.toString());
      _addLog('error', '继续失败: $e');
    }
  }

  /// Stop experiment
  Future<void> stopExperiment() async {
    if (state.experiment == null) return;

    // m-04 fix: Set currentOperation
    state = state.copyWith(
        isControlling: true,
        currentOperation: ControlOperation.stop,
        error: null);

    try {
      final experiment =
          await _controlService.stopExperiment(state.experiment!.id);
      state = state.copyWith(
          experiment: experiment,
          isControlling: false,
          clearCurrentOperation: true);
      _addLog('info', '试验已停止');
    } catch (e) {
      // m-05 fix: Try to sync state on state conflict error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('state') || errorStr.contains('invalid')) {
        await _syncStateFromServer();
      }
      state = state.copyWith(
          isControlling: false,
          clearCurrentOperation: true,
          error: e.toString());
      _addLog('error', '停止失败: $e');
    }
  }

  /// Clear logs
  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  // m-03 fix: Log entry limit to prevent memory issues
  static const int _maxLogEntries = 5000;

  /// Add a log entry
  void _addLog(String level, String message) {
    final entry = ConsoleLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    // m-03 fix: Keep only the last 5000 entries to prevent memory issues
    final updatedLogs = [...state.logs, entry];
    final trimmedLogs = updatedLogs.length > _maxLogEntries
        ? updatedLogs.sublist(updatedLogs.length - _maxLogEntries)
        : updatedLogs;
    state = state.copyWith(logs: trimmedLogs);
  }

  /// Handle WebSocket status change
  void handleWsStatusChange(String newStatus) {
    if (state.experiment == null) return;
    final oldStatus = state.experiment!.status;
    final status = ExperimentStatus.fromString(newStatus);

    state = state.copyWith(
      experiment: state.experiment!.copyWith(
        status: status,
        startedAt: status == ExperimentStatus.running
            ? (state.experiment!.startedAt ?? DateTime.now())
            : state.experiment!.startedAt,
      ),
    );

    // M-11 fix: Correct string interpolation syntax
    _addLog(
        'info', '状态变更: ${_statusLabel(oldStatus)} -> ${_statusLabel(status)}');
  }

  /// Handle WebSocket log entry
  void handleWsLog(WsLogEntry wsLog) {
    _addLog(wsLog.level, wsLog.message);
  }

  /// Set WebSocket connection status
  void setWsConnected(bool connected) {
    state = state.copyWith(wsConnected: connected);
  }

  /// Set WebSocket client for receiving updates
  void setWebSocketClient(ExperimentWebSocketClient client) {
    _wsClient = client;
  }

  String _statusLabel(ExperimentStatus status) {
    switch (status) {
      case ExperimentStatus.idle:
        return '空闲';
      case ExperimentStatus.loaded:
        return '已载入';
      case ExperimentStatus.running:
        return '运行中';
      case ExperimentStatus.paused:
        return '已暂停';
      case ExperimentStatus.completed:
        return '已完成';
      case ExperimentStatus.aborted:
        return '已中止';
    }
  }

  // m-05 fix: Sync state from server when state conflict occurs
  Future<void> _syncStateFromServer() async {
    if (state.experiment == null) return;
    try {
      final experiment =
          await _controlService.getExperimentStatus(state.experiment!.id);
      state = state.copyWith(experiment: experiment);
      _addLog('info', '状态已同步');
    } catch (e) {
      _addLog('warn', '状态同步失败: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // M-04 fix: Toggle auto-scroll when user manually scrolls
  void setAutoScroll(bool enabled) {
    state = state.copyWith(autoScrollEnabled: enabled, newLogsAvailable: false);
  }

  // M-04 fix: Called when user scrolls to bottom manually
  void onUserScrolledToBottom() {
    state = state.copyWith(autoScrollEnabled: true, newLogsAvailable: false);
  }

  // M-04 fix: Scroll to bottom (called from UI after new log if autoScroll enabled)
  void scrollToBottom() {
    // This is handled by the UI listening to state changes
    if (state.autoScrollEnabled) {
      state = state.copyWith(newLogsAvailable: false);
    } else {
      state = state.copyWith(newLogsAvailable: true);
    }
  }

  // m-07 fix: Expose reconnectWebSocket method for manual reconnect
  Future<void> reconnectWebSocket(String wsUrl) async {
    if (_wsClient != null) {
      _wsClient!.disconnect();
      await _wsClient!.connect(wsUrl, experimentId: state.experiment?.id);
    }
  }

  @override
  void dispose() {
    _wsClient?.dispose();
    super.dispose();
  }
}

/// Experiment console provider
final experimentConsoleProvider =
    StateNotifierProvider<ExperimentConsoleNotifier, ExperimentConsoleState>(
        (ref) {
  final controlService = ref.watch(experimentControlServiceProvider);
  final methodService = ref.watch(methodServiceProvider);
  return ExperimentConsoleNotifier(controlService, methodService);
});
