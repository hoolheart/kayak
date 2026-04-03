/// Method edit provider
///
/// Manages the state of the method edit page
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/method.dart';
import '../services/method_service.dart';

/// Method edit state
class MethodEditState {
  final String? id;
  final String name;
  final String? description;
  final String processDefinitionJson;
  final Map<String, ParameterConfig> parameters;
  final bool isSaving;
  final bool isValidating;
  final String? error;
  final ValidationResult? validationResult;
  final bool isDirty;
  final bool isLoaded;

  const MethodEditState({
    this.id,
    this.name = '',
    this.description,
    this.processDefinitionJson =
        '{\n  "nodes": [\n    {"id": "start", "type": "Start"},\n    {"id": "end", "type": "End"}\n  ]\n}',
    this.parameters = const {},
    this.isSaving = false,
    this.isValidating = false,
    this.error,
    this.validationResult,
    this.isDirty = false,
    this.isLoaded = false,
  });

  MethodEditState copyWith({
    String? id,
    String? name,
    String? description,
    String? processDefinitionJson,
    Map<String, ParameterConfig>? parameters,
    bool? isSaving,
    bool? isValidating,
    String? error,
    ValidationResult? validationResult,
    bool? isDirty,
    bool? isLoaded,
  }) {
    return MethodEditState(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      processDefinitionJson:
          processDefinitionJson ?? this.processDefinitionJson,
      parameters: parameters ?? this.parameters,
      isSaving: isSaving ?? this.isSaving,
      isValidating: isValidating ?? this.isValidating,
      error: error,
      validationResult: validationResult,
      isDirty: isDirty ?? this.isDirty,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  bool get canSave => name.trim().isNotEmpty && !isSaving;

  bool get hasJsonError {
    try {
      json.decode(processDefinitionJson);
      return false;
    } catch (_) {
      return true;
    }
  }

  String? get jsonError {
    try {
      json.decode(processDefinitionJson);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Method edit notifier
class MethodEditNotifier extends StateNotifier<MethodEditState> {
  final MethodServiceInterface _service;

  MethodEditNotifier(this._service) : super(const MethodEditState());

  Future<void> loadMethod(String id) async {
    state = state.copyWith(isLoaded: false, error: null);

    try {
      final method = await _service.getMethod(id);
      final prettyJson =
          const JsonEncoder.withIndent('  ').convert(method.processDefinition);

      // Parse parameters from schema
      final params = <String, ParameterConfig>{};
      final schema = method.parameterSchema;
      for (final entry in schema.entries) {
        params[entry.key] = ParameterConfig.fromJson(
            entry.key, entry.value as Map<String, dynamic>);
      }

      state = state.copyWith(
        id: method.id,
        name: method.name,
        description: method.description,
        processDefinitionJson: prettyJson,
        parameters: params,
        isLoaded: true,
        isDirty: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoaded: true);
    }
  }

  void updateName(String name) {
    state = state.copyWith(
        name: name, isDirty: true, error: null, validationResult: null);
  }

  void updateDescription(String? description) {
    state = state.copyWith(description: description, isDirty: true);
  }

  void updateProcessDefinition(String json) {
    state = state.copyWith(
      processDefinitionJson: json,
      isDirty: true,
      error: null,
      validationResult: null,
    );
  }

  void addParameter() {
    final newParam = ParameterConfig(
      name: 'new_parameter_${state.parameters.length + 1}',
      type: 'number',
      defaultValue: 0.0,
      unit: '',
      description: '',
    );
    final params = Map<String, ParameterConfig>.from(state.parameters);
    params[newParam.name] = newParam;
    state = state.copyWith(parameters: params, isDirty: true);
  }

  /// C4 fix: Add parameter with user-specified config (from dialog)
  void addParameterWithConfig(ParameterConfig param) {
    final params = Map<String, ParameterConfig>.from(state.parameters);
    params[param.name] = param;
    state = state.copyWith(parameters: params, isDirty: true);
  }

  void removeParameter(String name) {
    final params = Map<String, ParameterConfig>.from(state.parameters);
    params.remove(name);
    state = state.copyWith(parameters: params, isDirty: true);
  }

  void updateParameter(String oldName, ParameterConfig param) {
    final params = Map<String, ParameterConfig>.from(state.parameters);
    params.remove(oldName);
    params[param.name] = param;
    state = state.copyWith(parameters: params, isDirty: true);
  }

  Future<void> validateMethod() async {
    if (state.hasJsonError) {
      state = state.copyWith(error: 'JSON格式错误: ${state.jsonError}');
      return;
    }

    state =
        state.copyWith(isValidating: true, error: null, validationResult: null);

    try {
      final json =
          jsonDecode(state.processDefinitionJson) as Map<String, dynamic>;
      final result = await _service.validateMethod(json);
      state = state.copyWith(
        isValidating: false,
        validationResult: result,
        error: result.valid ? null : result.errors.join('\n'),
      );
    } catch (e) {
      state = state.copyWith(isValidating: false, error: e.toString());
    }
  }

  Future<bool> saveMethod() async {
    if (!state.canSave) return false;
    if (state.hasJsonError) {
      state = state.copyWith(error: 'JSON格式错误: ${state.jsonError}');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final processDef =
          jsonDecode(state.processDefinitionJson) as Map<String, dynamic>;

      // Build parameter schema from parameters
      final paramSchema = <String, dynamic>{};
      for (final entry in state.parameters.entries) {
        paramSchema[entry.key] = entry.value.toJson();
      }

      if (state.id != null) {
        // Update existing
        await _service.updateMethod(
          state.id!,
          name: state.name,
          description: state.description,
          processDefinition: processDef,
          parameterSchema: paramSchema,
        );
      } else {
        // Create new
        await _service.createMethod(
          name: state.name,
          description: state.description,
          processDefinition: processDef,
          parameterSchema: paramSchema,
        );
      }

      state = state.copyWith(isSaving: false, isDirty: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Method edit provider
final methodEditProvider =
    StateNotifierProvider<MethodEditNotifier, MethodEditState>((ref) {
  final service = ref.watch(methodServiceProvider);
  return MethodEditNotifier(service);
});
