import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kayak_frontend/widgets/empty_view.dart';
import 'package:kayak_frontend/widgets/error_view.dart';
import 'package:kayak_frontend/widgets/skeleton.dart';

/// 统一异步数据状态分发组件。
///
/// 封装异步数据加载的四种状态（Loading / Data / Error / Empty），
/// 其中 Empty 在 Data 状态下根据 [emptyCondition]（默认空列表或空字符串）触发。
/// 消除页面中重复的状态判断逻辑，保证用户体验一致性。
///
/// 用法：
/// ```dart
/// // 基础用法
/// AsyncValueWidget(
///   value: ref.watch(workspacesProvider),
///   dataBuilder: (workspaces) => WorkspaceList(workspaces: workspaces),
///   onRetry: () => ref.invalidate(workspacesProvider),
/// )
///
/// // 自定义 loading 和空状态
/// AsyncValueWidget(
///   value: ref.watch(notificationsProvider),
///   dataBuilder: (notifications) => NotificationList(notifications),
///   loadingBuilder: const DashboardSkeleton(),
///   emptyBuilder: EmptyView(
///     icon: Icons.notifications_none,
///     title: '暂无通知',
///   ),
/// )
/// ```
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.emptyCondition,
    this.onRetry,
    this.skipLoadingOnRefresh = true,
  });

  /// 异步数据状态。
  final AsyncValue<T> value;

  /// 数据就绪时渲染。
  final Widget Function(T data) dataBuilder;

  /// 加载中渲染，默认为 [Skeleton]。
  final Widget? loadingBuilder;

  /// 错误时渲染，默认为 [ErrorView]。
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  /// 数据为空时渲染，默认为 [EmptyView]。
  final Widget? emptyBuilder;

  /// 自定义空数据判断条件。
  ///
  /// 如果返回 true，则渲染 [emptyBuilder]。
  /// 未提供时，默认对空列表 (`data is List && data.isEmpty`) 和空字符串
  /// (`data is String && data.isEmpty`) 触发空状态。
  final bool Function(T data)? emptyCondition;

  /// 重试回调，传给 ErrorView。
  final VoidCallback? onRetry;

  /// 刷新时是否保留旧数据。
  ///
  /// 为 true 时，刷新期间保留旧 dataBuilder 内容，顶部显示进度条。
  /// 为 false 时，刷新期间显示 loadingBuilder。
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => _buildLoading(context),
      error: (error, stackTrace) => _buildError(context, error, stackTrace),
      data: (data) => _buildData(context, data),
    );
  }

  Widget _buildLoading(BuildContext context) {
    // 如果正在刷新且 skipLoadingOnRefresh 为 true，显示旧数据
    if (value.isRefreshing && skipLoadingOnRefresh && value.hasValue) {
      return _buildDataWithRefresh(context, value.requireValue);
    }

    return loadingBuilder ?? const Skeleton();
  }

  Widget _buildError(BuildContext context, Object error, StackTrace? stack) {
    if (errorBuilder != null) {
      return errorBuilder!(error, stack);
    }

    return ErrorView(
      title: error.toString(),
      onRetry: onRetry,
    );
  }

  Widget _buildData(BuildContext context, T data) {
    // 检查空状态条件
    final isEmpty = _checkEmpty(data);

    if (isEmpty) {
      if (value.isRefreshing && skipLoadingOnRefresh) {
        // 刷新时且旧数据为空，显示 loadingBuilder
        return loadingBuilder ?? const Skeleton();
      }
      return emptyBuilder ??
          const EmptyView(
            title: '暂无数据',
          );
    }

    if (value.isRefreshing && skipLoadingOnRefresh) {
      return _buildDataWithRefresh(context, data);
    }

    return dataBuilder(data);
  }

  Widget _buildDataWithRefresh(BuildContext context, T data) {
    return Stack(
      children: [
        dataBuilder(data),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(),
        ),
      ],
    );
  }

  bool _checkEmpty(T data) {
    if (emptyCondition != null) {
      return emptyCondition!(data);
    }
    // 默认对空列表触发空状态
    if (data is List) {
      return data.isEmpty;
    }
    if (data is String) {
      return data.isEmpty;
    }
    return false;
  }
}
