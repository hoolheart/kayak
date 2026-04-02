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

/// Experiment console state
class ExperimentConsoleState {
  final Experiment? experiment;
  final List<Method> availableMethods;
  final String? selectedMethodId;
  final Map<String, dynamic> parameterValues;
  final List<ConsoleLogEntry> logs;
  final bool isLoading;
  final bool isControlling;
  final String? error;
  final bool wsConnected;

  const ExperimentConsoleState({
    this.experiment,
    this.availableMethods = const [],
    this.selectedMethodId,
    this.parameterValues = const {},
    this.logs = const [],
    this.isLoading = false,
    this.isControlling = false,
    this.error,
    this.wsConnected = false,
  });

  ExperimentConsoleState copyWith({
    Experiment? experiment,
    List<Method>? availableMethods,
    String? selectedMethodId,
    Map<String, dynamic>? parameterValues,
    List<ConsoleLogEntry>? logs,
    bool? isLoading,
    bool? isControlling,
    String? error,
    bool? wsConnected,
  }) {
    return ExperimentConsoleState(
      experiment: experiment ?? this.experiment,
      availableMethods: availableMethods ?? this.availableMethods,
      selectedMethodId: selectedMethodId ?? this.selectedMethodId,
      parameterValues: parameterValues ?? this.parameterValues,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isControlling: isControlling ?? this.isControlling,
      error: error,
      wsConnected: wsConnected ?? this.wsConnected,
    );
  }

  /// Whether the load button should be enabled
  bool get canLoad =>
      experiment != null &&
      selectedMethodId != null &&
      (experiment!.status == ExperimentStatus.idle);

  /// Whether the start button should be enabled
  bool get canStart =>
      experiment != null &&
      (experiment!.status == ExperimentStatus.loaded ||
          experiment!.status == ExperimentStatus.paused);

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

  /// Initialize the console - load methods and create experiment
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load available methods
      final methodsResponse =
          await _methodService.getMethods(page: 1, size: 100);
      final methods = methodsResponse.items;

      // Create new experiment
      final experiment = await _controlService.createExperiment();

      state = state.copyWith(
        experiment: experiment,
        availableMethods: methods,
        isLoading: false,
        error: null,
      );

      // Add initial log
      _addLog('info', '试验已创建: ${experiment.name}');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select a method
  void selectMethod(String methodId) {
    state = state.copyWith(selectedMethodId: methodId);

    // Load parameter defaults from method
    final method = state.availableMethods.firstWhere(
      (m) => m.id == methodId,
      orElse: () => state.availableMethods.first,
    );

    final params = <String, dynamic>{};
    for (final entry in method.parameterSchema.entries) {
      final schema = entry.value as Map<String, dynamic>;
      params[entry.key] = schema['default'];
    }
    state = state.copyWith(parameterValues: params);
  }

  /// Update a parameter value
  void updateParameter(String name, dynamic value) {
    final params = Map<String, dynamic>.from(state.parameterValues);
    params[name] = value;
    state = state.copyWith(parameterValues: params);
  }

  /// Load method into experiment
  Future<void> loadExperiment() async {
    if (state.selectedMethodId == null || state.experiment == null) return;

    state = state.copyWith(isControlling: true, error: null);

    try {
      final experiment = await _controlService.loadExperiment(
        state.experiment!.id,
        state.selectedMethodId!,
      );

      state = state.copyWith(experiment: experiment, isControlling: false);
      _addLog('info', '方法已载入');
    } catch (e) {
      state = state.copyWith(isControlling: false, error: e.toString());
      _addLog('error', '载入失败: $e');
    }
  }

  /// Start experiment
  Future<void> startExperiment() async {
    if (state.experiment == null) return;

    state = state.copyWith(isControlling: true, error: null);

    try {
      final experiment =
          await _controlService.startExperiment(state.experiment!.id);
      state = state.copyWith(experiment: experiment, isControlling: false);
      _addLog('info', '试验开始');
    } catch (e) {
      state = state.copyWith(isControlling: false, error: e.toString());
      _addLog('error', '启动失败: $e');
    }
  }

  /// Pause experiment
  Future<void> pauseExperiment() async {
    if (state.experiment == null) return;

    state = state.copyWith(isControlling: true, error: null);

    try {
      final experiment =
          await _controlService.pauseExperiment(state.experiment!.id);
      state = state.copyWith(experiment: experiment, isControlling: false);
      _addLog('info', '试验已暂停');
    } catch (e) {
      state = state.copyWith(isControlling: false, error: e.toString());
      _addLog('error', '暂停失败: $e');
    }
  }

  /// Resume experiment
  Future<void> resumeExperiment() async {
    if (state.experiment == null) return;

    state = state.copyWith(isControlling: true, error: null);

    try {
      final experiment =
          await _controlService.resumeExperiment(state.experiment!.id);
      state = state.copyWith(experiment: experiment, isControlling: false);
      _addLog('info', '试验继续');
    } catch (e) {
      state = state.copyWith(isControlling: false, error: e.toString());
      _addLog('error', '继续失败: $e');
    }
  }

  /// Stop experiment
  Future<void> stopExperiment() async {
    if (state.experiment == null) return;

    state = state.copyWith(isControlling: true, error: null);

    try {
      final experiment =
          await _controlService.stopExperiment(state.experiment!.id);
      state = state.copyWith(experiment: experiment, isControlling: false);
      _addLog('info', '试验已停止');
    } catch (e) {
      state = state.copyWith(isControlling: false, error: e.toString());
      _addLog('error', '停止失败: $e');
    }
  }

  /// Clear logs
  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  /// Add a log entry
  void _addLog(String level, String message) {
    final entry = ConsoleLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    state = state.copyWith(logs: [...state.logs, entry]);
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

    _addLog(
        'info', '状态变更: ${_statusLabel(oldStatus)} -> $_statusLabel(status)');
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

  void clearError() {
    state = state.copyWith(error: null);
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
