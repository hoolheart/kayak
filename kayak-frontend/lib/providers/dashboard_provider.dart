import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dashboard_service.dart';
import 'services.dart';

// ============================================================
// DashboardService Provider
// ============================================================

/// DashboardService 的 Riverpod Provider。
///
/// 提供全局唯一的 [DashboardService] 实例。
/// 在测试中通过 `overrideWithValue` 注入 FakeDashboardService。
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(
    workbenchService: ref.read(workbenchServiceProvider),
    experimentService: ref.read(experimentServiceProvider),
  );
});

// ============================================================
// Dashboard Stats Provider（按区域独立容错）
// ============================================================

/// 仪表盘统计数据 Provider。
///
/// 管理仪表盘统计概览区域（工作台数/设备数/试验数）的加载状态。
/// 使用 [FutureProvider] 实现，独立于最近工作台列表，
/// 实现按区域独立容错。
///
/// 读取方式：
/// ```dart
/// final statsAsync = ref.watch(dashboardStatsProvider);
/// ```
final dashboardStatsProvider = FutureProvider<DashboardData>((ref) async {
  final service = ref.read(dashboardServiceProvider);
  return service.loadDashboardData();
});

// ============================================================
// Dashboard Recent Workbenches Provider（按区域独立容错）
// ============================================================

/// 仪表盘最近工作台列表 Provider。
///
/// 管理最近工作台区域的加载状态，独立于统计概览区域。
/// 使用 [FutureProvider] 实现。
///
/// 读取方式：
/// ```dart
/// final recentAsync = ref.watch(dashboardRecentProvider);
/// ```
final dashboardRecentProvider = FutureProvider<List<WorkbenchSummary>>((
  ref,
) async {
  final service = ref.read(dashboardServiceProvider);
  return service.loadRecentWorkbenches();
});
