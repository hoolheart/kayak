import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../generated/app_localizations.dart';
import '../../models/experiment.dart';
import '../../models/method.dart';
import '../../models/workbench.dart';
import '../../providers/services.dart';
import '../../providers/workbench_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/skeleton.dart' show ShimmerPlaceholder;
import '../../widgets/toast.dart';

// ============================================================
// Provider: 方法列表
// ============================================================

/// 方法列表 Provider，在进入步骤 2 时自动加载。
final _methodListProvider =
    FutureProvider.autoDispose<List<Method>>((ref) {
  return ref.read(methodServiceProvider).list();
});

// ============================================================
// ExperimentCreatePage — 4 步创建向导
// ============================================================

/// 试验创建页面 — 4 步 Stepper 向导。
///
/// 步骤：
/// 1. 选择工作台
/// 2. 选择方法
/// 3. 配置参数
/// 4. 确认创建
///
/// 路由：`/experiments/new`
/// 注意：该路由为顶层路由（无 AppShell 包裹），避免底部导航栏冲突。
class ExperimentCreatePage extends ConsumerStatefulWidget {
  const ExperimentCreatePage({super.key});

  @override
  ConsumerState<ExperimentCreatePage> createState() =>
      _ExperimentCreatePageState();
}

class _ExperimentCreatePageState
    extends ConsumerState<ExperimentCreatePage>
    with SingleTickerProviderStateMixin {
  // ---------- 步骤状态 ----------
  int _currentStep = 0;

  // ---------- 选择状态 ----------
  Workbench? _selectedWorkbench;
  Method? _selectedMethod;
  final Map<String, TextEditingController> _textControllers = {};
  bool _autoStopValue = false;
  String? _cycleModeValue;
  bool _isCreating = false;

  // ---------- 表单验证 ----------
  final Map<String, String?> _fieldErrors = {};

  // ---------- 动画 ----------
  late final AnimationController _stepAnimController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeInOut,
    ));
    _stepAnimController.forward();
  }

  @override
  void dispose() {
    _stepAnimController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ---------- 步骤导航 ----------

  bool get _canGoNext {
    switch (_currentStep) {
      case 0:
        return _selectedWorkbench != null;
      case 1:
        return _selectedMethod != null;
      case 2:
        return _selectedMethod?.parameters?.isEmpty ?? true
            ? true
            : _validateParameters();
      case 3:
        return !_isCreating;
      default:
        return false;
    }
  }

  bool get _canGoBack => _currentStep > 0;

  bool get _isLastStep => _currentStep == 3;

  void _goToNextStep() {
    if (!_canGoNext) return;

    if (_isLastStep) {
      _createExperiment();
      return;
    }

    setState(() {
      _currentStep++;
      if (_currentStep == 2 && _selectedMethod != null) {
        _initializeParameterControllers();
      }
    });
    _animateStep();
  }

  void _goToPreviousStep() {
    if (!_canGoBack) return;
    setState(() {
      _currentStep--;
    });
    _animateStep();
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= _currentStep) {
      setState(() {
        _currentStep = step;
      });
      _animateStep();
    }
  }

  void _animateStep() {
    _stepAnimController.reset();
    _stepAnimController.forward();
  }

  // ---------- 参数表单 ----------

  void _initializeParameterControllers() {
    _textControllers.clear();
    _fieldErrors.clear();

    final params = _selectedMethod?.parameters ?? [];
    for (final param in params) {
      if (param.type == 'boolean') {
        if (param.defaultValue is bool) {
          _autoStopValue = param.defaultValue as bool;
        }
      } else if (param.type == 'enum') {
        if (param.defaultValue is String) {
          _cycleModeValue = param.defaultValue as String;
        } else if (param.options != null && param.options!.isNotEmpty) {
          _cycleModeValue = param.options!.first;
        }
      } else {
        final controller = TextEditingController(
          text: param.defaultValue?.toString() ?? '',
        );
        _textControllers[param.key] = controller;
      }
    }
  }

  bool _validateParameters() {
    bool valid = true;
    _fieldErrors.clear();

    final params = _selectedMethod?.parameters ?? [];
    for (final param in params) {
      if (param.type == 'boolean' || param.type == 'enum') continue;

      final value = _textControllers[param.key]?.text ?? '';
      final isEmpty = value.trim().isEmpty;

      // 必填验证
      if (isEmpty && param.isRequired) {
        _fieldErrors[param.key] = 'fieldRequiredValidation';
        valid = false;
        continue;
      }

      if (isEmpty) continue;

      // 类型和范围验证
      if (param.type == 'number' || param.type == 'integer') {
        final numValue = num.tryParse(value.trim());
        if (numValue == null) {
          _fieldErrors[param.key] = 'invalidFormat';
          valid = false;
          continue;
        }

        if (param.type == 'integer' && !_isInteger(value.trim())) {
          _fieldErrors[param.key] = 'mustBeInteger';
          valid = false;
          continue;
        }

        if (param.min != null && numValue < param.min!) {
          _fieldErrors[param.key] = 'cannotBeLessThan';
          valid = false;
          continue;
        }

        if (param.max != null && numValue > param.max!) {
          _fieldErrors[param.key] = 'cannotBeGreaterThan';
          valid = false;
          continue;
        }
      }
    }

    return valid;
  }

  bool _isInteger(String value) {
    final parsed = int.tryParse(value);
    return parsed != null;
  }

  // ---------- 创建试验 ----------

  Future<void> _createExperiment() async {
    if (_selectedWorkbench == null || _selectedMethod == null) return;
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final service = ref.read(experimentServiceProvider);
      final experiment = await service.create(
        CreateExperimentRequest(
          name: '${_selectedWorkbench!.name} - ${_selectedMethod!.name}',
          methodId: _selectedMethod!.id,
        ),
      );

      if (!mounted) return;

      Toast.show(
        context: context,
        message: AppLocalizations.of(context)!.createExperimentSuccess,
        type: ToastType.success,
      );

      // 导航到试验详情
      context.go('/experiments/${experiment.id}');
    } catch (e) {
      if (!mounted) return;

      final errorMsg = e.toString();
      Toast.show(
        context: context,
        message: AppLocalizations.of(context)!
            .createExperimentFailed(errorMsg),
        type: ToastType.error,
      );

      setState(() => _isCreating = false);
    }
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/experiments'),
        ),
        title: Text(l10n.createExperimentTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ---- Stepper Header ----
          _StepperHeader(
            currentStep: _currentStep,
            totalSteps: 4,
            isMobile: isMobile,
            l10n: l10n,
            onStepTap: _goToStep,
            stepStates: _stepStates,
          ),

          // ---- Content Area ----
          Expanded(
            child: AnimatedBuilder(
              animation: _stepAnimController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child!,
                  ),
                );
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: _buildStepContent(l10n, isMobile, isDesktop),
                  ),
                ),
              ),
            ),
          ),

          // ---- Bottom Navigation Bar ----
          _BottomBar(
            currentStep: _currentStep,
            canGoNext: _canGoNext,
            canGoBack: _canGoBack,
            isLastStep: _isLastStep,
            isCreating: _isCreating,
            isMobile: isMobile,
            l10n: l10n,
            onNext: _goToNextStep,
            onBack: _goToPreviousStep,
          ),
        ],
      ),
    );
  }

  List<_StepState> get _stepStates {
    return List.generate(4, (index) {
      if (index < _currentStep) return _StepState.completed;
      if (index == _currentStep) return _StepState.active;
      return _StepState.inactive;
    });
  }

  Widget _buildStepContent(
    AppLocalizations l10n,
    bool isMobile,
    bool isDesktop,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Workbench(l10n, isMobile, isDesktop);
      case 1:
        return _buildStep2Method(l10n, isMobile, isDesktop);
      case 2:
        return _buildStep3Params(l10n, isMobile);
      case 3:
        return _buildStep4Confirm(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // ============ Step 1: 选择工作台 ============

  Widget _buildStep1Workbench(
    AppLocalizations l10n,
    bool isMobile,
    bool isDesktop,
  ) {
    final workbenchState = ref.watch(workbenchListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectWorkbenchTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.selectWorkbenchSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        workbenchState.when(
          loading: () => _buildWorkbenchSkeletons(isMobile),
          error: (error, _) => _buildWorkbenchError(l10n),
          data: (workbenches) {
            if (workbenches.isEmpty) {
              return _buildWorkbenchEmpty(l10n);
            }
            return _buildWorkbenchGrid(
              workbenches,
              isMobile,
              isDesktop,
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkbenchSkeletons(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        isMobile ? 1 : 3,
        (_) => const _WorkbenchCardSkeleton(),
      ),
    );
  }

  Widget _buildWorkbenchError(AppLocalizations l10n) {
    return ErrorView(
      title: l10n.loadWorkbenchesFailed,
      description: l10n.loadWorkbenchesFailedHint,
      onRetry: () =>
          ref.invalidate(workbenchListProvider),
    );
  }

  Widget _buildWorkbenchEmpty(AppLocalizations l10n) {
    return EmptyView(
      icon: Icons.build_outlined,
      title: l10n.noWorkbenchesTitle,
      description: l10n.noWorkbenchesDescription,
      actionButton: ElevatedButton(
        onPressed: () => context.go('/workbenches'),
        child: Text(l10n.createFirstWorkbench),
      ),
    );
  }

  Widget _buildWorkbenchGrid(
    List<Workbench> workbenches,
    bool isMobile,
    bool isDesktop,
  ) {
    // Determine column count
    final columnCount = isMobile ? 1 : (isDesktop ? 3 : 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (columnCount - 1) * 16.0) / columnCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: workbenches.map((workbench) {
            final isSelected = _selectedWorkbench?.id == workbench.id;
            return SizedBox(
              width: cardWidth,
              child: _SelectableWorkbenchCard(
                workbench: workbench,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedWorkbench = workbench;
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============ Step 2: 选择方法 ============

  Widget _buildStep2Method(
    AppLocalizations l10n,
    bool isMobile,
    bool isDesktop,
  ) {
    final methodState = ref.watch(_methodListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectMethodTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.selectMethodSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        methodState.when(
          loading: () => _buildMethodSkeletons(isMobile),
          error: (error, _) => _buildMethodError(l10n),
          data: (methods) {
            if (methods.isEmpty) {
              return _buildMethodEmpty(l10n);
            }
            return _buildMethodGrid(
              methods,
              isMobile,
              isDesktop,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMethodSkeletons(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        isMobile ? 1 : 3,
        (_) => const _MethodCardSkeleton(),
      ),
    );
  }

  Widget _buildMethodError(AppLocalizations l10n) {
    return ErrorView(
      title: l10n.loadMethodsFailed,
      description: l10n.loadMethodsFailedHint,
      onRetry: () => ref.invalidate(_methodListProvider),
    );
  }

  Widget _buildMethodEmpty(AppLocalizations l10n) {
    return EmptyView(
      icon: Icons.science_outlined,
      title: l10n.noMethodsTitle,
      description: l10n.noMethodsDescription,
      actionButton: TextButton(
        onPressed: () => context.go('/methods'),
        child: Text(l10n.goToMethods),
      ),
    );
  }

  Widget _buildMethodGrid(
    List<Method> methods,
    bool isMobile,
    bool isDesktop,
  ) {
    final columnCount = isMobile ? 1 : (isDesktop ? 3 : 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (columnCount - 1) * 16.0) / columnCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: methods.map((method) {
            final isSelected = _selectedMethod?.id == method.id;
            return SizedBox(
              width: cardWidth,
              child: _SelectableMethodCard(
                method: method,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedMethod = method;
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============ Step 3: 配置参数 ============

  Widget _buildStep3Params(AppLocalizations l10n, bool isMobile) {
    final params = _selectedMethod?.parameters ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.configureParamsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.configureParamsSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        if (params.isEmpty)
          _buildNoParamsBanner(l10n)
        else
          _buildParameterForm(params, isMobile),
      ],
    );
  }

  Widget _buildNoParamsBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withAlpha(128),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noParamsRequired,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noParamsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterForm(
    List<MethodParameter> params,
    bool isMobile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = !isMobile && constraints.maxWidth > 600;

        if (useTwoColumns) {
          return _buildParameterColumns(params);
        }
        return _buildParameterList(params);
      },
    );
  }

  Widget _buildParameterList(List<MethodParameter> params) {
    return Column(
      children: params.map((param) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildParameterField(param),
        );
      }).toList(),
    );
  }

  Widget _buildParameterColumns(List<MethodParameter> params) {
    final rows = <Widget>[];
    for (int i = 0; i < params.length; i += 2) {
      final rowChildren = <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildParameterField(params[i]),
          ),
        ),
        if (i + 1 < params.length)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildParameterField(params[i + 1]),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ];
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildParameterField(MethodParameter param) {
    final l10n = AppLocalizations.of(context)!;
    final errorKey = _fieldErrors[param.key];
    final errorText = errorKey != null ? _getErrorText(errorKey, param) : null;

    switch (param.type) {
      case 'boolean':
        return _buildBooleanField(param, l10n);
      case 'enum':
        return _buildEnumField(param, l10n, errorText);
      default:
        return _buildTextField(param, l10n, errorText);
    }
  }

  String? _getErrorText(String errorKey, MethodParameter param) {
    final l10n = AppLocalizations.of(context)!;
    switch (errorKey) {
      case 'fieldRequiredValidation':
        return l10n.fieldRequiredValidation;
      case 'invalidFormat':
        return l10n.invalidFormat;
      case 'mustBeInteger':
        return l10n.mustBeInteger;
      case 'cannotBeLessThan':
        return l10n.cannotBeLessThan(param.min?.toString() ?? '');
      case 'cannotBeGreaterThan':
        return l10n.cannotBeGreaterThan(param.max?.toString() ?? '');
      default:
        return null;
    }
  }

  Widget _buildTextField(
    MethodParameter param,
    AppLocalizations l10n,
    String? errorText,
  ) {
    final controller = _textControllers[param.key]!;
    final keyboardType = param.type == 'number'
        ? const TextInputType.numberWithOptions(decimal: true)
        : param.type == 'integer'
            ? TextInputType.number
            : TextInputType.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(
              param.label ?? param.key,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (param.isRequired)
              Text(
                ' *',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            if (param.unit != null && param.unit!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                param.unit!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            errorText: errorText,
          ),
          onChanged: (_) {
            // Re-validate on change
            _validateParameters();
            setState(() {});
          },
        ),
        if (param.description != null &&
            param.description!.isNotEmpty &&
            errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              param.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildBooleanField(
    MethodParameter param,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          param.label ?? param.key,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                param.description ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Switch(
              value: _autoStopValue,
              onChanged: (value) {
                setState(() => _autoStopValue = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnumField(
    MethodParameter param,
    AppLocalizations l10n,
    String? errorText,
  ) {
    final options = param.options ?? <String>[];
    final currentValue = _cycleModeValue ?? options.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              param.label ?? param.key,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (param.isRequired)
              Text(
                ' *',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            errorText: errorText,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _cycleModeValue = value);
          },
        ),
        if (param.description != null &&
            param.description!.isNotEmpty &&
            errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              param.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  // ============ Step 4: 确认创建 ============

  Widget _buildStep4Confirm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.confirmTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.confirmSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(l10n),
        const SizedBox(height: 16),
        _buildWarningText(l10n),
      ],
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workbench section
          Text(
            l10n.summaryWorkbench,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedWorkbench?.name ?? l10n.unnamedWorkbench,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),

          // Method section
          Text(
            l10n.summaryMethod,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedMethod?.name ?? l10n.unnamedMethod,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),

          // Parameters section
          Text(
            l10n.summaryParams,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryParams(l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryParams(AppLocalizations l10n) {
    final params = _selectedMethod?.parameters ?? [];
    if (params.isEmpty) {
      return Text(
        l10n.noParamsRequired,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: params.map((param) {
        final value = _formatParamValue(param, l10n);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '${param.label ?? param.key} = ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatParamValue(MethodParameter param, AppLocalizations l10n) {
    switch (param.type) {
      case 'boolean':
        return _autoStopValue ? l10n.booleanTrue : l10n.booleanFalse;
      case 'enum':
        return _cycleModeValue ?? '';
      default:
        final controller = _textControllers[param.key];
        final text = controller?.text ?? '';
        if (param.unit != null && text.isNotEmpty) {
          return '$text ${param.unit}';
        }
        return text;
    }
  }

  Widget _buildWarningText(AppLocalizations l10n) {
    return Text(
      l10n.createWarning,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}

// ============================================================
// _StepState — 步骤状态枚举
// ============================================================

enum _StepState { inactive, active, completed }

// ============================================================
// _StepperHeader — 步骤指示器
// ============================================================

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.isMobile,
    required this.l10n,
    required this.onStepTap,
    required this.stepStates,
  });

  final int currentStep;
  final int totalSteps;
  final bool isMobile;
  final AppLocalizations l10n;
  final void Function(int step) onStepTap;
  final List<_StepState> stepStates;

  static const _stepLabels = [
    'stepSelectWorkbench',
    'stepSelectMethod',
    'stepConfigureParams',
    'stepConfirm',
  ];

  static const _stepShortLabels = [
    'stepWorkbenchShort',
    'stepMethodShort',
    'stepParamsShort',
    'stepConfirmShort',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Row(
            children: List.generate(totalSteps, (index) {
              final isLast = index == totalSteps - 1;
              final state = stepStates[index];
              final labelKey = isMobile
                  ? _stepShortLabels[index]
                  : _stepLabels[index];
              final label = _getStepLabel(labelKey);

              return Expanded(
                child: GestureDetector(
                  onTap: state == _StepState.completed
                      ? () => onStepTap(index)
                      : null,
                  child: Row(
                    children: [
                      // Step indicator
                      _buildStepIndicator(
                        index: index,
                        state: state,
                        colorScheme: colorScheme,
                        theme: theme,
                        isMobile: isMobile,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: state == _StepState.active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: state == _StepState.completed
                                  ? colorScheme.primary
                                  : state == _StepState.active
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant
                                          .withAlpha(97),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (isMobile && index <= currentStep) ...[
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: state == _StepState.active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: state == _StepState.completed
                                ? colorScheme.primary
                                : state == _StepState.active
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant
                                        .withAlpha(97),
                          ),
                        ),
                      ],
                      // Connector
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: state == _StepState.completed &&
                                    index < currentStep
                                ? 2
                                : 1,
                            margin: EdgeInsets.symmetric(
                              horizontal: isMobile ? 4 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: index < currentStep
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _getStepLabel(String key) {
    switch (key) {
      case 'stepSelectWorkbench':
        return l10n.stepSelectWorkbench;
      case 'stepSelectMethod':
        return l10n.stepSelectMethod;
      case 'stepConfigureParams':
        return l10n.stepConfigureParams;
      case 'stepConfirm':
        return l10n.stepConfirm;
      case 'stepWorkbenchShort':
        return l10n.stepWorkbenchShort;
      case 'stepMethodShort':
        return l10n.stepMethodShort;
      case 'stepParamsShort':
        return l10n.stepParamsShort;
      case 'stepConfirmShort':
        return l10n.stepConfirmShort;
      default:
        return '';
    }
  }

  Widget _buildStepIndicator({
    required int index,
    required _StepState state,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required bool isMobile,
  }) {
    final size = isMobile ? 28.0 : 32.0;

    if (state == _StepState.completed) {
      return Icon(
        Icons.check_circle,
        size: size,
        color: colorScheme.primary,
      );
    }

    final isActive = state == _StepState.active;
    final bgColor = isActive
        ? colorScheme.primaryContainer
        : Colors.transparent;
    final textColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant.withAlpha(97);
    final borderColor = isActive
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _BottomBar — 底部导航栏
// ============================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentStep,
    required this.canGoNext,
    required this.canGoBack,
    required this.isLastStep,
    required this.isCreating,
    required this.isMobile,
    required this.l10n,
    required this.onNext,
    required this.onBack,
  });

  final int currentStep;
  final bool canGoNext;
  final bool canGoBack;
  final bool isLastStep;
  final bool isCreating;
  final bool isMobile;
  final AppLocalizations l10n;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: isMobile
                ? _buildMobileLayout(colorScheme)
                : _buildDesktopLayout(colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Next/Create button (top in mobile stacked layout)
        SizedBox(
          width: double.infinity,
          child: _buildNextButton(colorScheme),
        ),
        if (canGoBack) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildBackButton(),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(ColorScheme colorScheme) {
    return Row(
      children: [
        if (canGoBack) _buildBackButton(),
        const Spacer(),
        _buildNextButton(colorScheme),
      ],
    );
  }

  Widget _buildBackButton() {
    return OutlinedButton.icon(
      onPressed: canGoBack ? onBack : null,
      icon: const Icon(Icons.arrow_back, size: 18),
      label: Text(l10n.previousStep),
    );
  }

  Widget _buildNextButton(ColorScheme colorScheme) {
    if (isLastStep) {
      // Create button
      return FilledButton.icon(
        onPressed: canGoNext && !isCreating ? onNext : null,
        icon: isCreating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.add, size: 18),
        label: Text(isCreating ? l10n.creating : l10n.createExperiment),
      );
    }

    // Next button
    return FilledButton.icon(
      onPressed: canGoNext ? onNext : null,
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: Text(l10n.nextStep),
    );
  }
}

// ============================================================
// _SelectableWorkbenchCard — 可选工作台卡片
// ============================================================

class _SelectableWorkbenchCard extends StatelessWidget {
  const _SelectableWorkbenchCard({
    required this.workbench,
    required this.isSelected,
    required this.onTap,
  });

  final Workbench workbench;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.build_outlined,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workbench.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deviceCount(0), // We don't have deviceCount on Workbench model
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (workbench.description != null &&
                  workbench.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  workbench.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _SelectableMethodCard — 可选方法卡片
// ============================================================

class _SelectableMethodCard extends StatelessWidget {
  const _SelectableMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final Method method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final paramCount = method.parameters?.length ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
              if (method.description != null &&
                  method.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  method.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.paramCount(paramCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _WorkbenchCardSkeleton — 工作台卡片骨架屏
// ============================================================

class _WorkbenchCardSkeleton extends StatelessWidget {
  const _WorkbenchCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerPlaceholder(
                width: 40,
                height: 40,
                borderRadius: 8,
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShimmerPlaceholder(
                  width: double.infinity,
                  height: 16,
                  widthFraction: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ShimmerPlaceholder(
            width: double.infinity,
            height: 14,
            widthFraction: 0.4,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// _MethodCardSkeleton — 方法卡片骨架屏
// ============================================================

class _MethodCardSkeleton extends StatelessWidget {
  const _MethodCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerPlaceholder(
                width: 40,
                height: 40,
                borderRadius: 8,
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShimmerPlaceholder(
                  width: double.infinity,
                  height: 16,
                  widthFraction: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ShimmerPlaceholder(
            width: double.infinity,
            height: 14,
          ),
          SizedBox(height: 4),
          ShimmerPlaceholder(
            width: double.infinity,
            height: 14,
            widthFraction: 0.7,
          ),
          SizedBox(height: 12),
          ShimmerPlaceholder(
            width: double.infinity,
            height: 14,
            widthFraction: 0.3,
          ),
        ],
      ),
    );
  }
}
