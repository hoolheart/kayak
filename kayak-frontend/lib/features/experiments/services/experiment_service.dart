/// 试验服务
///
/// 处理试验相关的API调用
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/experiment.dart';
import '../providers/experiment_detail_provider.dart';

/// 试验服务接口
abstract class ExperimentServiceInterface {
  Future<PagedExperimentResponse> getExperiments({
    int page = 1,
    int size = 10,
    ExperimentStatus? status,
    DateTime? startedAfter,
    DateTime? startedBefore,
  });
  Future<Experiment> getExperiment(String id);
  Future<PointHistoryResponse> getPointHistory(
    String experimentId,
    String channel, {
    DateTime? startTime,
    DateTime? endTime,
    int limit = 1000,
  });
}

/// 试验服务实现
class ExperimentService implements ExperimentServiceInterface {
  final ApiClientInterface _apiClient;

  ExperimentService(this._apiClient);

  @override
  Future<PagedExperimentResponse> getExperiments({
    int page = 1,
    int size = 10,
    ExperimentStatus? status,
    DateTime? startedAfter,
    DateTime? startedBefore,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };

    if (status != null) {
      queryParams['status'] = status.value;
    }
    if (startedAfter != null) {
      queryParams['started_after'] = startedAfter.toIso8601String();
    }
    if (startedBefore != null) {
      queryParams['started_before'] = startedBefore.toIso8601String();
    }

    final response = await _apiClient.get(
      '/api/v1/experiments',
      queryParameters: queryParams,
    );

    final data = (response as Map)['data'] as Map<String, dynamic>;
    return PagedExperimentResponse.fromJson(data);
  }

  @override
  Future<Experiment> getExperiment(String id) async {
    final response = await _apiClient.get('/api/v1/experiments/$id');
    return Experiment.fromJson(
        (response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<PointHistoryResponse> getPointHistory(
    String experimentId,
    String channel, {
    DateTime? startTime,
    DateTime? endTime,
    int limit = 1000,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };

    if (startTime != null) {
      queryParams['start_time'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      queryParams['end_time'] = endTime.toIso8601String();
    }

    final response = await _apiClient.get(
      '/api/v1/experiments/$experimentId/points/$channel/history',
      queryParameters: queryParams,
    );

    return PointHistoryResponse.fromJson(response as Map<String, dynamic>);
  }
}

/// Experiment Service Provider
final experimentServiceProvider = Provider<ExperimentServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExperimentService(apiClient);
});
