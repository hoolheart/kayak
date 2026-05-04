/// 工作台服务
///
/// 处理工作台相关的API调用
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/workbench.dart';

/// 工作台服务接口
abstract class WorkbenchServiceInterface {
  Future<PagedWorkbenchResponse> getWorkbenches({int page = 1, int size = 20});
  Future<Workbench> getWorkbench(String id);
  Future<Workbench> createWorkbench(String name, String? description);
  Future<Workbench> updateWorkbench(
    String id,
    String name,
    String? description,
  );
  Future<void> deleteWorkbench(String id);
}

/// 工作台服务实现
class WorkbenchService implements WorkbenchServiceInterface {
  WorkbenchService(this._apiClient);
  final ApiClientInterface _apiClient;

  @override
  Future<PagedWorkbenchResponse> getWorkbenches({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/workbenches',
      queryParameters: {'page': page, 'size': size},
    );

    final data = (response as Map)['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => Workbench.fromJson(e as Map<String, dynamic>))
        .toList();

    return PagedWorkbenchResponse(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['size'] as int,
    );
  }

  @override
  Future<Workbench> getWorkbench(String id) async {
    final response = await _apiClient.get('/api/v1/workbenches/$id');
    return Workbench.fromJson(
      (response as Map)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Workbench> createWorkbench(String name, String? description) async {
    final response = await _apiClient.post(
      '/api/v1/workbenches',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return Workbench.fromJson(
      (response as Map)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Workbench> updateWorkbench(
    String id,
    String name,
    String? description,
  ) async {
    final response = await _apiClient.put(
      '/api/v1/workbenches/$id',
      data: {
        'name': name,
        if (description != null) 'description': description,
      },
    );
    return Workbench.fromJson(
      (response as Map)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteWorkbench(String id) async {
    await _apiClient.delete('/api/v1/workbenches/$id');
  }
}

/// Workbench Service Provider
final workbenchServiceProvider = Provider<WorkbenchServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkbenchService(apiClient);
});
