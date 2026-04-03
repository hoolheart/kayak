/// Method service
///
/// Handles method-related API calls
library;

import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/method.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Method service interface
abstract class MethodServiceInterface {
  Future<MethodListResponse> getMethods({int page = 1, int size = 10});
  Future<Method> getMethod(String id);
  Future<Method> createMethod({
    required String name,
    String? description,
    required Map<String, dynamic> processDefinition,
    required Map<String, dynamic> parameterSchema,
  });
  Future<Method> updateMethod(
    String id, {
    String? name,
    String? description,
    Map<String, dynamic>? processDefinition,
    Map<String, dynamic>? parameterSchema,
  });
  Future<void> deleteMethod(String id);
  Future<ValidationResult> validateMethod(
      Map<String, dynamic> processDefinition);
}

/// Method service implementation
class MethodService implements MethodServiceInterface {
  final ApiClientInterface _apiClient;

  MethodService(this._apiClient);

  @override
  Future<MethodListResponse> getMethods({int page = 1, int size = 10}) async {
    final response = await _apiClient.get(
      '/api/v1/methods',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response as Map<String, dynamic>;
    // C1 fix: Extract data key consistently with other methods
    return MethodListResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Method> getMethod(String id) async {
    final response = await _apiClient.get('/api/v1/methods/$id');
    final data = response as Map<String, dynamic>;
    return Method.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Method> createMethod({
    required String name,
    String? description,
    required Map<String, dynamic> processDefinition,
    required Map<String, dynamic> parameterSchema,
  }) async {
    final body = {
      'name': name,
      if (description != null) 'description': description,
      'process_definition': processDefinition,
      'parameter_schema': parameterSchema,
    };

    final response = await _apiClient.post('/api/v1/methods', data: body);
    final data = response as Map<String, dynamic>;
    return Method.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Method> updateMethod(
    String id, {
    String? name,
    String? description,
    Map<String, dynamic>? processDefinition,
    Map<String, dynamic>? parameterSchema,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (processDefinition != null)
      body['process_definition'] = processDefinition;
    if (parameterSchema != null) body['parameter_schema'] = parameterSchema;

    final response = await _apiClient.put('/api/v1/methods/$id', data: body);
    final data = response as Map<String, dynamic>;
    return Method.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMethod(String id) async {
    await _apiClient.delete('/api/v1/methods/$id');
  }

  @override
  Future<ValidationResult> validateMethod(
      Map<String, dynamic> processDefinition) async {
    final response = await _apiClient.post(
      '/api/v1/methods/validate',
      data: {'process_definition': processDefinition},
    );
    final data = response as Map<String, dynamic>;
    return ValidationResult.fromJson(data);
  }
}

/// Method service provider
final methodServiceProvider = Provider<MethodServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MethodService(apiClient);
});
