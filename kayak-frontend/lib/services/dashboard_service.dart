import '../models/common.dart';
import '../models/experiment.dart';
import '../models/workbench.dart';
import 'experiment_service.dart';
import 'workbench_service.dart';

// ============================================================
// DashboardData — 仪表盘统计聚合数据
// ============================================================

/// 仪表盘统计概览数据。
///
/// 由 [DashboardService.loadDashboardData] 返回，
/// 包含工作台/设备/试验的计数。
class DashboardData {
  const DashboardData({
    required this.workbenchCount,
    required this.deviceCount,
    required this.experimentCount,
  });

  /// 工作台总数
  final int workbenchCount;

  /// 设备总数（跨所有工作台聚合）
  final int deviceCount;

  /// 试验总数
  final int experimentCount;
}

// ============================================================
// WorkbenchSummary — 最近工作台摘要
// ============================================================

/// 最近工作台卡片使用的摘要数据。
///
/// 由 [DashboardService.loadRecentWorkbenches] 返回。
class WorkbenchSummary {
  const WorkbenchSummary({
    required this.id,
    required this.name,
    this.deviceCount,
    required this.updatedAt,
  });

  /// 工作台 ID
  final String id;

  /// 工作台名称
  final String name;

  /// 设备数量（后端返回，可能为 null 表示旧数据或不可用）
  final int? deviceCount;

  /// 最后更新时间
  final DateTime updatedAt;
}

// ============================================================
// DashboardService — 仪表盘数据聚合服务
// ============================================================

/// 仪表盘数据聚合服务。
///
/// 按区域独立容错 — 统计数据和最近工作台列表分别加载，
/// 各自处理自己的错误，互不影响。
///
/// 设备总数通过后端 WorkbenchDto.device_count 聚合，无需 N+1 查询。
class DashboardService {
  /// 创建 DashboardService 实例
  ///
  /// [workbenchService] 工作台服务
  /// [experimentService] 试验服务
  DashboardService({
    required WorkbenchService workbenchService,
    required ExperimentService experimentService,
  }) : _workbenchService = workbenchService,
       _experimentService = experimentService;

  final WorkbenchService _workbenchService;
  final ExperimentService _experimentService;

  /// 加载仪表盘统计数据（工作台数/设备数/试验数）。
  ///
  /// 并行获取工作台列表（含 device_count）和试验总数。
  /// 设备总数为所有工作台 device_count 之和。
  /// 任何子请求失败时抛出异常，由 provider 层捕获。
  Future<DashboardData> loadDashboardData() async {
    // 并行获取工作台列表（含 device_count）和试验总数
    final results = await Future.wait<dynamic>([
      _workbenchService.list(size: 100),
      _experimentService.list(size: 1),
    ]);

    final workbenchResponse = results[0] as PaginatedResponse<Workbench>;
    final experimentResponse = results[1] as PaginatedResponse<Experiment>;

    // 设备总数：累加各工作台的 device_count，避免 N+1 查询
    final deviceCount = workbenchResponse.items.fold<int>(
      0,
      (sum, wb) => sum + (wb.deviceCount ?? 0),
    );

    return DashboardData(
      workbenchCount: workbenchResponse.total,
      deviceCount: deviceCount,
      experimentCount: experimentResponse.total,
    );
  }

  /// 加载最近工作台列表（最多 4 个）。
  ///
  /// 按 updated_at 降序排列。
  /// 每个工作台直接使用后端返回的 device_count，无需额外查询。
  Future<List<WorkbenchSummary>> loadRecentWorkbenches() async {
    final response = await _workbenchService.list(size: 4);

    return response.items.map((wb) {
      return WorkbenchSummary(
        id: wb.id,
        name: wb.name.isNotEmpty ? wb.name : 'Unnamed Workbench',
        deviceCount: wb.deviceCount,
        updatedAt: wb.updatedAt,
      );
    }).toList();
  }
}
