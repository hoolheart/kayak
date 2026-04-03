/// Experiment control service
///
/// Handles experiment control API calls (load, start, pause, resume, stop)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/experiment.dart';

/// Experiment control service interface
abstract class ExperimentControlServiceInterface {
  Future<Experiment> createExperiment();
  Future<Experiment> loadExperiment(String experimentId, String methodId);
  Future<Experiment> startExperiment(String experimentId);
  Future<Experiment> pauseExperiment(String experimentId);
  Future<Experiment> resumeExperiment(String experimentId);
  Future<Experiment> stopExperiment(String experimentId);
  Future<Experiment> getExperimentStatus(String experimentId);
  Future<List<Experiment>> getExperiments({int page = 1, int size = 10});
}

/// Experiment control service implementation
class ExperimentControlService implements ExperimentControlServiceInterface {
  final ApiClientInterface _apiClient;

  ExperimentControlService(this._apiClient);

  @override
  Future<Experiment> createExperiment() async {
    final response = await _apiClient.post('/api/v1/experiments', data: {});
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Experiment> loadExperiment(
      String experimentId, String methodId) async {
    final response = await _apiClient.post(
      '/api/v1/experiments/$experimentId/load',
      data: {'method_id': methodId},
    );
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Experiment> startExperiment(String experimentId) async {
    final response = await _apiClient.post(
      '/api/v1/experiments/$experimentId/start',
    );
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Experiment> pauseExperiment(String experimentId) async {
    final response = await _apiClient.post(
      '/api/v1/experiments/$experimentId/pause',
    );
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Experiment> resumeExperiment(String experimentId) async {
    final response = await _apiClient.post(
      '/api/v1/experiments/$experimentId/resume',
    );
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Experiment> stopExperiment(String experimentId) async {
    final response = await _apiClient.post(
      '/api/v1/experiments/$experimentId/stop',
    );
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Experiment> getExperimentStatus(String experimentId) async {
    final response = await _apiClient.get(
      '/api/v1/experiments/$experimentId/status',
    );
    final data = response as Map<String, dynamic>;
    return Experiment.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<Experiment>> getExperiments({int page = 1, int size = 10}) async {
    final response = await _apiClient.get(
      '/api/v1/experiments',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response as Map<String, dynamic>;
    final items = data['data']['items'] as List<dynamic>;
    return items
        .map((e) => Experiment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Experiment control service provider
final experimentControlServiceProvider =
    Provider<ExperimentControlServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExperimentControlService(apiClient);
});
