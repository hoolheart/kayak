import '../models/common.dart';
import '../models/experiment.dart';
import 'api_client.dart';

/// AnalysisService — 分析页专用服务
///
/// 封装数据分析页所需的数据查询 API 调用。
/// 使用 [ApiClient] 发起请求，利用 [ErrorInterceptor] 统一处理错误。
///
/// 所有方法不捕获异常 —— 异常由 ErrorInterceptor 和 Provider 层处理。
class AnalysisService {
  /// 创建 AnalysisService 实例
  ///
  /// [client] ApiClient 实例
  AnalysisService(this._client);

  final ApiClient _client;

  /// 查询试验时序数据
  ///
  /// 调用 `POST /api/v1/experiments/{id}/data/query`。
  ///
  /// [experimentId] 试验 ID
  /// [deviceId] 设备 ID（必填）
  /// [pointIds] 测点 ID 列表
  /// [startTime] 开始时间（可选）
  /// [endTime] 结束时间（可选）
  /// [downsample] 降采样目标点数（可选，默认 1000）
  /// 返回 [TimeSeriesData] 时序数据
  Future<TimeSeriesData> loadChartData({
    required String experimentId,
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
      '/api/v1/experiments/$experimentId/data/query',
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
