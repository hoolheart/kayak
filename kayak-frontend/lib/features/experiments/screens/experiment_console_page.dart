/// Experiment console page
///
/// Provides experiment execution console with method selector,
/// parameter config, control buttons, status display, and real-time log
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment.dart';
import '../providers/experiment_console_provider.dart';
import '../services/experiment_ws_client.dart';

/// Experiment console page
class ExperimentConsolePage extends ConsumerStatefulWidget {
  final String? experimentId;

  const ExperimentConsolePage({super.key, this.experimentId});

  @override
  ConsumerState<ExperimentConsolePage> createState() =>
      _ExperimentConsolePageState();
}

class _ExperimentConsolePageState extends ConsumerState<ExperimentConsolePage> {
  ExperimentWebSocketClient? _wsClient;
  final ScrollController _logScrollController = ScrollController();
  // C-03 fix: Store TextEditingControllers in a map to manage lifecycle
  final Map<String, TextEditingController> _parameterControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // C-05 fix: Pass experimentId to initialize if provided
      ref.read(experimentConsoleProvider.notifier).initialize(
            experimentId: widget.experimentId,
          );
      _setupWebSocket();
    });
  }

  void _setupWebSocket() {
    _wsClient = ExperimentWebSocketClient();
    ref.read(experimentConsoleProvider.notifier).setWebSocketClient(_wsClient!);

    // Listen to status changes
    _wsClient!.statusChanges.listen((statusChange) {
      if (mounted) {
        ref
            .read(experimentConsoleProvider.notifier)
            .handleWsStatusChange(statusChange.newStatus);
      }
    });

    // Listen to log entries
    _wsClient!.logEntries.listen((logEntry) {
      if (mounted) {
        ref.read(experimentConsoleProvider.notifier).handleWsLog(logEntry);
      }
    });

    // Listen to connection status
    _wsClient!.connectionStatus.listen((connected) {
      if (mounted) {
        ref.read(experimentConsoleProvider.notifier).setWsConnected(connected);
      }
    });

    // C-05 fix: Connect WebSocket with experiment ID if provided
    // Note: WebSocket URL should include experiment ID for proper routing
    // The actual connection is initiated by the provider when experiment is loaded
  }

  @override
  void dispose() {
    _wsClient?.dispose();
    _logScrollController.dispose();
    // C-03 fix: Dispose all parameter controllers
    for (final controller in _parameterControllers.values) {
      controller.dispose();
    }
    _parameterControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(experimentConsoleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('试验执行控制台'),
        actions: [
          // WebSocket connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.wsConnected ? Icons.wifi : Icons.wifi_off,
                  size: 18,
                  color: state.wsConnected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  state.wsConnected ? '已连接' : '未连接',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: state.wsConnected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.experiment == null
              ? _buildErrorState(context, state.error!)
              : _buildContent(context, state),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(experimentConsoleProvider.notifier).initialize();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExperimentConsoleState state) {
    return Column(
      children: [
        // Experiment info section
        _buildExperimentInfo(context, state),

        // Control buttons
        _buildControlButtons(context, state),

        // Parameter config
        _buildParameterConfig(context, state),

        // Log output
        Expanded(child: _buildLogOutput(context, state)),
      ],
    );
  }

  Widget _buildExperimentInfo(
      BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status display
          Row(
            children: [
              const Text('状态: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildStatusChip(context, state),
            ],
          ),
          const SizedBox(height: 12),

          // Method selector
          Row(
            children: [
              const Text('方法: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('method_selector'),
                  // Note: value is correct here since this is a controlled dropdown
                  value: state.selectedMethodId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: '选择试验方法',
                  ),
                  items: state.availableMethods
                      .map((method) => DropdownMenuItem(
                            value: method.id,
                            child: Text(method.name),
                          ))
                      .toList(),
                  onChanged: state.experiment?.status == ExperimentStatus.idle
                      ? (value) {
                          if (value != null) {
                            ref
                                .read(experimentConsoleProvider.notifier)
                                .selectMethod(value);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = state.experiment?.status;

    Color backgroundColor;
    Color textColor;

    if (status == null) {
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    } else {
      switch (status) {
        case ExperimentStatus.idle:
          backgroundColor = colorScheme.surfaceContainerHighest;
          textColor = colorScheme.onSurfaceVariant;
          break;
        case ExperimentStatus.loaded:
          backgroundColor = colorScheme.secondaryContainer;
          textColor = colorScheme.onSecondaryContainer;
          break;
        case ExperimentStatus.running:
          backgroundColor = colorScheme.primaryContainer;
          textColor = colorScheme.onPrimaryContainer;
          break;
        case ExperimentStatus.paused:
          backgroundColor = colorScheme.tertiaryContainer;
          textColor = colorScheme.onTertiaryContainer;
          break;
        case ExperimentStatus.completed:
          backgroundColor = colorScheme.secondaryContainer;
          textColor = colorScheme.onSecondaryContainer;
          break;
        case ExperimentStatus.aborted:
          backgroundColor = colorScheme.errorContainer;
          textColor = colorScheme.onErrorContainer;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        state.statusLabel,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildControlButtons(
      BuildContext context, ExperimentConsoleState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('btn_load'),
            onPressed: state.canLoad && !state.isControlling
                ? () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .loadExperiment();
                  }
                : null,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('载入'),
          ),
          FilledButton.icon(
            key: const Key('btn_start'),
            onPressed: state.canStart && !state.isControlling
                ? () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .startExperiment();
                  }
                : null,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('开始'),
          ),
          FilledButton.icon(
            key: const Key('btn_pause'),
            onPressed: state.canPause && !state.isControlling
                ? () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .pauseExperiment();
                  }
                : null,
            icon: const Icon(Icons.pause, size: 18),
            label: const Text('暂停'),
          ),
          FilledButton.icon(
            key: const Key('btn_resume'),
            onPressed: state.canResume && !state.isControlling
                ? () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .resumeExperiment();
                  }
                : null,
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('继续'),
          ),
          FilledButton.icon(
            key: const Key('btn_stop'),
            onPressed: state.canStop && !state.isControlling
                ? () {
                    _showStopConfirm(context);
                  }
                : null,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('停止'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
          if (state.isControlling)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParameterConfig(
      BuildContext context, ExperimentConsoleState state) {
    final method = state.availableMethods.firstWhere(
      (m) => m.id == state.selectedMethodId,
      orElse: () => state.availableMethods.isEmpty
          ? throw StateError('No methods')
          : state.availableMethods.first,
    );

    if (method.parameterSchema.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参数配置',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...method.parameterSchema.entries.map((entry) {
            final schema = entry.value as Map<String, dynamic>;
            final type = schema['type'] as String? ?? 'string';
            final unit = schema['unit'] as String?;
            final description = schema['description'] as String?;
            final currentValue = state.parameterValues[entry.key];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: _buildParameterInput(
                      context,
                      entry.key,
                      type,
                      currentValue,
                      state,
                    ),
                  ),
                  if (unit != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(unit,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // C-03 fix: Get or create controller for parameter
  TextEditingController _getParameterController(
      String name, dynamic currentValue) {
    if (!_parameterControllers.containsKey(name)) {
      _parameterControllers[name] = TextEditingController(
        text: currentValue?.toString() ?? '',
      );
    } else {
      // Update text if value changed externally
      final controller = _parameterControllers[name]!;
      final currentText = currentValue?.toString() ?? '';
      if (controller.text != currentText) {
        controller.text = currentText;
      }
    }
    return _parameterControllers[name]!;
  }

  Widget _buildParameterInput(
    BuildContext context,
    String name,
    String type,
    dynamic currentValue,
    ExperimentConsoleState state,
  ) {
    final notifier = ref.read(experimentConsoleProvider.notifier);
    final controller = _getParameterController(name, currentValue);

    switch (type) {
      case 'number':
        return TextField(
          key: Key('param_$name'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          controller: controller,
          onChanged: (value) {
            final num = double.tryParse(value);
            if (num != null) {
              notifier.updateParameter(name, num);
            }
          },
        );
      case 'integer':
        return TextField(
          key: Key('param_$name'),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          controller: controller,
          onChanged: (value) {
            final num = int.tryParse(value);
            if (num != null) {
              notifier.updateParameter(name, num);
            }
          },
        );
      case 'boolean':
        return Switch(
          key: Key('param_$name'),
          value: currentValue == true,
          onChanged: (value) {
            notifier.updateParameter(name, value);
          },
        );
      default:
        return TextField(
          key: Key('param_$name'),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          controller: controller,
          onChanged: (value) {
            notifier.updateParameter(name, value);
          },
        );
    }
  }

  Widget _buildLogOutput(BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Log header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border:
                Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(
                '执行日志',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(experimentConsoleProvider.notifier).clearLogs();
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('清空'),
              ),
            ],
          ),
        ),
        // Log content
        Expanded(
          child: Container(
            color: colorScheme.surfaceContainerLowest,
            child: ListView.builder(
              key: const Key('log_list'),
              controller: _logScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return _buildLogEntry(context, log);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogEntry(BuildContext context, ConsoleLogEntry log) {
    final colorScheme = Theme.of(context).colorScheme;

    Color levelColor;
    switch (log.level.toLowerCase()) {
      case 'error':
        levelColor = colorScheme.error;
        break;
      case 'warn':
        levelColor = colorScheme.tertiary;
        break;
      case 'debug':
        // m-01 fix: Add grey color for debug level
        levelColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        break;
      default:
        levelColor = colorScheme.onSurfaceVariant;
    }

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[$timeStr] ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            '[${log.level.toUpperCase()}] ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
          ),
          Expanded(
            child: Text(
              log.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStopConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('停止试验'),
        content: const Text('确定要停止当前试验吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm_stop'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(experimentConsoleProvider.notifier).stopExperiment();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('停止'),
          ),
        ],
      ),
    );
  }
}
