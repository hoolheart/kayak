import '../models/common.dart';
import '../models/experiment.dart';
import '../models/workbench.dart';
import 'device_service.dart';
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

  /// 设备数量（可能为 null 表示加载失败或不可用）
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
/// 设备总数暂无后端全局聚合端点，采用逐个工作台遍历聚合策略。
class DashboardService {
  /// 创建 DashboardService 实例
  ///
  /// [workbenchService] 工作台服务
  /// [experimentService] 试验服务
  /// [deviceService] 设备服务
  DashboardService({
    required WorkbenchService workbenchService,
    required ExperimentService experimentService,
    required DeviceService deviceService,
  })  : _workbenchService = workbenchService,
        _experimentService = experimentService,
        _deviceService = deviceService;

  final WorkbenchService _workbenchService;
  final ExperimentService _experimentService;
  final DeviceService _deviceService;

  /// 加载仪表盘统计数据（工作台数/设备数/试验数）。
  ///
  /// 并行获取工作台总数和试验总数。
  /// 设备总数通过遍历工作台获取设备列表累加。
  /// 任何子请求失败时抛出异常，由 provider 层捕获。
  Future<DashboardData> loadDashboardData() async {
    // 并行获取工作台总数和试验总数
    final results = await Future.wait<dynamic>([
      _workbenchService.list(size: 1),
      _experimentService.list(size: 1),
    ]);

    final workbenchResponse =
        results[0] as PaginatedResponse<Workbench>;
    final experimentResponse =
        results[1] as PaginatedResponse<Experiment>;

    // 设备总数：遍历工作台获取设备列表并累加
    final deviceCount = await _aggregateDeviceCount(
      workbenchResponse.total,
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
  /// 每个工作台附带设备数量。
  Future<List<WorkbenchSummary>> loadRecentWorkbenches() async {
    final response = await _workbenchService.list(size: 4);

    final summaries = <WorkbenchSummary>[];
    for (final wb in response.items) {
      int? deviceCount;
      try {
        final devices = await _deviceService.listByWorkbench(wb.id);
        deviceCount = devices.length;
      } catch (_) {
        // 单个工作台设备加载失败时不阻塞整体列表
        deviceCount = null;
      }

      summaries.add(WorkbenchSummary(
        id: wb.id,
        name: wb.name.isNotEmpty ? wb.name : 'Unnamed Workbench',
        deviceCount: deviceCount,
        updatedAt: wb.updatedAt,
      ));
    }

    return summaries;
  }

  /// 聚合所有工作台的设备总数。
  ///
  /// 分批遍历工作台并获取各工作台的设备列表。
  /// 如果遍历失败，返回 0 作为降级值。
  Future<int> _aggregateDeviceCount(int totalWorkbenches) async {
    if (totalWorkbenches <= 0) return 0;

    // 获取所有工作台（限制最大 100 个，避免请求过大）
    final pageSize = totalWorkbenches > 100 ? 100 : totalWorkbenches;
    final allWorkbenches = await _workbenchService.list(size: pageSize);

    int totalDevices = 0;
    for (final wb in allWorkbenches.items) {
      try {
        final devices = await _deviceService.listByWorkbench(wb.id);
        totalDevices += devices.length;
      } catch (_) {
        // 单个工作台设备加载失败，跳过
        continue;
      }
    }

    return totalDevices;
  }
}
