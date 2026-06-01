import 'package:dio/dio.dart';

import '../models/common.dart';
import '../models/experiment.dart';
import 'api_client.dart';

/// ExperimentService — 试验服务
///
/// 封装试验相关的 HTTP API 调用，提供类型安全的接口。
/// 使用 [ApiClient] 发起请求，利用 [ErrorInterceptor] 统一处理错误。
///
/// 所有方法不捕获异常 —— 异常由 ErrorInterceptor 和 Provider 层处理。
class ExperimentService {
  /// 创建 ExperimentService 实例
  ///
  /// [client] ApiClient 实例，提供 HTTP GET/POST/PUT/DELETE 方法
  ExperimentService(this._client);

  final ApiClient _client;

  /// 获取试验列表（支持分页、筛选）
  ///
  /// 调用 `GET /api/v1/experiments`。
  ///
  /// [page] 页码，从 1 开始，默认 1
  /// [size] 每页条数，默认 10
  /// [status] 状态筛选（单值）
  /// [createdAfter] 创建时间下限
  /// [createdBefore] 创建时间上限
  /// [scope] 范围：'personal' | 'team'
  /// 返回 [PaginatedResponse]<[Experiment]> 包含分页元数据和记录列表
  Future<PaginatedResponse<Experiment>> list({
    int page = 1,
    int size = 10,
    ExperimentStatus? status,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? scope,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };

    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }
    if (createdAfter != null) {
      queryParams['created_after'] =
          createdAfter.toUtc().toIso8601String();
    }
    if (createdBefore != null) {
      queryParams['created_before'] =
          createdBefore.toUtc().toIso8601String();
    }
    if (scope != null && scope.isNotEmpty) {
      queryParams['scope'] = scope;
    }

    final response = await _client.get(
      '/api/v1/experiments',
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse<PaginatedResponse<Experiment>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => PaginatedResponse<Experiment>.fromJson(
        json as Map<String, dynamic>,
        (item) => Experiment.fromJson(item as Map<String, dynamic>),
      ),
    );

    return apiResponse.data;
  }

  /// 根据 ID 获取试验详情
  ///
  /// 调用 `GET /api/v1/experiments/{id}`。
  ///
  /// [id] 试验 ID
  /// 返回 [Experiment] 对象
  /// 如果资源不存在，抛出 404 [DioException]
  Future<Experiment> getById(String id) async {
    final response = await _client.get(
      '/api/v1/experiments/$id',
    );

    final apiResponse = ApiResponse<Experiment>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Experiment.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 创建试验
  ///
  /// 调用 `POST /api/v1/experiments`。
  ///
  /// [request] 创建试验请求
  /// 返回创建的 [Experiment] 对象
  Future<Experiment> create(CreateExperimentRequest request) async {
    final response = await _client.post(
      '/api/v1/experiments',
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<Experiment>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Experiment.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 载入试验方法
  ///
  /// 调用 `POST /api/v1/experiments/{id}/load`。
  ///
  /// [id] 试验 ID
  /// [methodId] 方法 ID
  /// 返回 [ExperimentControlDto] 包含最新的试验状态
  Future<ExperimentControlDto> load(
    String id, {
    required String methodId,
  }) async {
    final response = await _client.post(
      '/api/v1/experiments/$id/load',
      data: {'method_id': methodId},
    );

    final apiResponse = ApiResponse<ExperimentControlDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ExperimentControlDto.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 开始试验
  ///
  /// 调用 `POST /api/v1/experiments/{id}/start`。
  ///
  /// [id] 试验 ID
  /// 返回 [ExperimentControlDto] 包含最新的试验状态
  Future<ExperimentControlDto> start(String id) async {
    final response = await _client.post(
      '/api/v1/experiments/$id/start',
    );

    final apiResponse = ApiResponse<ExperimentControlDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ExperimentControlDto.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 暂停试验
  ///
  /// 调用 `POST /api/v1/experiments/{id}/pause`。
  ///
  /// [id] 试验 ID
  /// 返回 [ExperimentControlDto] 包含最新的试验状态
  Future<ExperimentControlDto> pause(String id) async {
    final response = await _client.post(
      '/api/v1/experiments/$id/pause',
    );

    final apiResponse = ApiResponse<ExperimentControlDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ExperimentControlDto.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 继续试验
  ///
  /// 调用 `POST /api/v1/experiments/{id}/resume`。
  ///
  /// [id] 试验 ID
  /// 返回 [ExperimentControlDto] 包含最新的试验状态
  Future<ExperimentControlDto> resume(String id) async {
    final response = await _client.post(
      '/api/v1/experiments/$id/resume',
    );

    final apiResponse = ApiResponse<ExperimentControlDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ExperimentControlDto.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 停止试验（回到 LOADED 状态）
  ///
  /// 调用 `POST /api/v1/experiments/{id}/stop`。
  ///
  /// [id] 试验 ID
  /// 返回 [ExperimentControlDto] 包含最新的试验状态
  Future<ExperimentControlDto> stop(String id) async {
    final response = await _client.post(
      '/api/v1/experiments/$id/stop',
    );

    final apiResponse = ApiResponse<ExperimentControlDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ExperimentControlDto.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 获取试验当前状态
  ///
  /// 调用 `GET /api/v1/experiments/{id}/status`。
  ///
  /// [id] 试验 ID
  /// 返回 [ExperimentStatusDto]（结构化 DTO，非简单枚举）
  Future<ExperimentStatusDto> getStatus(String id) async {
    final response = await _client.get(
      '/api/v1/experiments/$id/status',
    );

    final apiResponse = ApiResponse<ExperimentStatusDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ExperimentStatusDto.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 获取状态变更历史
  ///
  /// 调用 `GET /api/v1/experiments/{id}/history`。
  ///
  /// [id] 试验 ID
  /// 返回 [List]<[StatusChange]> 按时间倒序排列
  Future<List<StatusChange>> getHistory(String id) async {
    final response = await _client.get(
      '/api/v1/experiments/$id/history',
    );

    final apiResponse = ApiResponse<List<StatusChange>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((e) => StatusChange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// 查询试验时序数据
  ///
  /// 调用 `POST /api/v1/experiments/{id}/data/query`。
  ///
  /// [id] 试验 ID
  /// [deviceId] 设备 ID（必填）
  /// [pointIds] 测点 ID 列表（可选）
  /// [startTime] 开始时间（可选）
  /// [endTime] 结束时间（可选）
  /// [downsample] 降采样点数（可选）
  /// 返回 [TimeSeriesData] 时序数据
  Future<TimeSeriesData> queryData(
    String id, {
    required String deviceId,
    List<String>? pointIds,
    DateTime? startTime,
    DateTime? endTime,
    int? downsample,
  }) async {
    final params = DataQueryParams(
      pointIds: pointIds,
      startTime: startTime,
      endTime: endTime,
      downsample: downsample,
    );

    final response = await _client.post(
      '/api/v1/experiments/$id/data/query',
      data: {
        'device_id': deviceId,
        ...params.toJson(),
      },
    );

    final apiResponse = ApiResponse<TimeSeriesData>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TimeSeriesData.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
