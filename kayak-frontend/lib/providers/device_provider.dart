import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import 'services.dart';

// ============================================================
// DeviceTreeNotifier — 设备树状态管理器
// ============================================================

/// DeviceTreeNotifier — 设备树状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API，通过 family 方式按工作台 ID 区分。
/// [workbenchId] 为 family 参数，表示工作台 ID。
///
/// 状态通过 [AsyncValue]<[List]<[DeviceTreeNode]>> 表达设备树生命周期：
/// - [AsyncLoading] — 加载中
/// - [AsyncData] — 加载成功
/// - [AsyncError] — 加载失败
///
/// 职责：
/// 1. 构建设备树（将平铺设备列表转换为嵌套树结构）
/// 2. 刷新设备树
class DeviceTreeNotifier extends AsyncNotifier<List<DeviceTreeNode>> {
  /// 创建 DeviceTreeNotifier 实例
  ///
  /// [workbenchId] 工作台 ID，由 family provider 传入。
  DeviceTreeNotifier(this.workbenchId);

  /// 工作台 ID（由 family 参数传入）
  final String workbenchId;

  @override
  Future<List<DeviceTreeNode>> build() async {
    final service = ref.read(deviceServiceProvider);
    final devices = await service.listByWorkbench(workbenchId);
    return _buildTree(devices);
  }

  /// 刷新设备树
  ///
  /// 重新加载数据并重新构建树结构。
  /// 刷新期间状态为 [AsyncLoading]。
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 将平铺设备列表转换为嵌套树结构
  ///
  /// 按 parentId 分组，递归构建设备树。
  /// 根节点为 parentId 为 null 的设备。
  List<DeviceTreeNode> _buildTree(List<Device> devices) {
    // 1. 按 parentId 分组
    final Map<String?, List<Device>> grouped = {};
    for (final device in devices) {
      grouped.putIfAbsent(device.parentId, () => []).add(device);
    }

    // 2. 递归构建树节点
    List<DeviceTreeNode> buildChildren(String? parentId) {
      final children = grouped[parentId] ?? [];
      return children.map((device) {
        return DeviceTreeNode(
          id: device.id,
          workbenchId: device.workbenchId,
          parentId: device.parentId,
          name: device.name,
          protocolType: device.protocolType,
          protocolParams: device.protocolParams,
          manufacturer: device.manufacturer,
          model: device.model,
          sn: device.sn,
          status: device.status,
          children: buildChildren(device.id),
          createdAt: device.createdAt,
          updatedAt: device.updatedAt,
        );
      }).toList();
    }

    // 3. 从根节点（parentId == null）开始
    return buildChildren(null);
  }
}

/// 设备树 Provider
///
/// 通过 [AsyncNotifierProvider.family] 暴露 [DeviceTreeNotifier]，
/// 提供 [AsyncValue]<[List]<[DeviceTreeNode]>> 类型的树状态，按工作台 ID 区分。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final treeState = ref.watch(deviceTreeProvider('wb-1'));
///
/// // 调用方法
/// ref.read(deviceTreeProvider('wb-1').notifier).refresh();
/// ```
final deviceTreeProvider = AsyncNotifierProvider.family<
  DeviceTreeNotifier,
  List<DeviceTreeNode>,
  String
>(
  DeviceTreeNotifier.new,
);

// ============================================================
// DeviceDetailNotifier — 设备详情状态管理器
// ============================================================

/// DeviceDetailNotifier — 设备详情状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API，通过 family 方式按设备 ID 区分。
/// [deviceId] 为 family 参数，表示设备 ID。
///
/// 状态通过 [AsyncValue]<[Device]> 表达详情生命周期：
/// - [AsyncLoading] — 加载中
/// - [AsyncData] — 加载成功
/// - [AsyncError] — 加载失败
///
/// 职责：
/// 1. 加载设备详情（build）
/// 2. 创建设备（createDevice）— 成功后刷新设备树
/// 3. 更新设备（updateDevice）
/// 4. 删除设备（deleteDevice）— 成功后刷新设备树
/// 5. 连接管理（testConnection / connect / disconnect）
class DeviceDetailNotifier extends AsyncNotifier<Device> {
  /// 创建 DeviceDetailNotifier 实例
  ///
  /// [deviceId] 设备 ID，由 family provider 传入。
  DeviceDetailNotifier(this.deviceId);

  /// 设备 ID（由 family 参数传入）
  final String deviceId;

  /// 操作互斥标志，防止连接/断开/测试连接并发执行
  bool _isOperationInProgress = false;

  /// 当前是否正在执行连接相关操作
  bool get isOperationInProgress => _isOperationInProgress;

  /// 当前设备的工作台 ID（缓存，用于创建/删除后刷新树）
  String? _workbenchId;

  @override
  Future<Device> build() async {
    final service = ref.read(deviceServiceProvider);
    final device = await service.getById(deviceId);
    _workbenchId = device.workbenchId;
    return device;
  }

  /// 创建新设备，成功后刷新设备树
  ///
  /// [wbId] 所属工作台 ID
  /// [name] 设备名称
  /// [protocolType] 协议类型字符串
  /// [protocolParams] 协议参数（可选）
  /// [parentId] 父设备 ID（可选）
  Future<void> createDevice({
    required String wbId,
    required String name,
    required String protocolType,
    Map<String, dynamic>? protocolParams,
    String? parentId,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(deviceServiceProvider);
      final device = await service.create(
        workbenchId: wbId,
        name: name,
        protocolType: protocolType,
        protocolParams: protocolParams,
        parentId: parentId,
      );
      state = AsyncData(device);
      _workbenchId = device.workbenchId;

      // 创建成功后刷新设备树
      _refreshDeviceTree(wbId);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 更新设备
  ///
  /// [data] 需要更新的字段，如 `{'name': 'New Name'}`
  /// 更新成功后自动更新状态为最新数据，并刷新设备树。
  Future<void> updateDevice(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(deviceServiceProvider);
      final updated = await service.update(deviceId, data);
      state = AsyncData(updated);

      // 更新后刷新设备树
      if (_workbenchId != null) {
        _refreshDeviceTree(_workbenchId!);
      }
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 删除设备
  ///
  /// 删除成功后保持 loading 状态，由 UI 层导航回列表页。
  /// 同时刷新设备树。
  Future<void> deleteDevice() async {
    state = const AsyncLoading();

    try {
      final service = ref.read(deviceServiceProvider);
      await service.delete(deviceId);

      // 删除成功后刷新设备树
      if (_workbenchId != null) {
        _refreshDeviceTree(_workbenchId!);
      }
      // 删除成功后保持 loading 状态，
      // UI 层监听此状态并在适当时导航回列表
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 测试设备连接
  ///
  /// 返回连接测试结果 Map。
  /// 操作期间状态保持 loading。
  Future<Map<String, dynamic>> testConnection() async {
    if (_isOperationInProgress) {
      throw StateError('设备操作正在进行中，请稍后重试');
    }

    _isOperationInProgress = true;
    state = const AsyncLoading();

    try {
      final service = ref.read(deviceServiceProvider);
      final result = await service.testConnection(deviceId);

      // 重新加载设备详情以获取最新状态
      final device = await service.getById(deviceId);
      state = AsyncData(device);

      return result;
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
      rethrow;
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 连接设备
  ///
  /// 成功后重新加载设备详情，状态更新为 'online'。
  Future<void> connect() async {
    if (_isOperationInProgress) {
      throw StateError('设备操作正在进行中，请稍后重试');
    }

    _isOperationInProgress = true;
    state = const AsyncLoading();

    try {
      final service = ref.read(deviceServiceProvider);
      await service.connect(deviceId);

      // 重新加载设备详情以获取最新状态
      final device = await service.getById(deviceId);
      state = AsyncData(device);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 断开设备
  ///
  /// 成功后重新加载设备详情，状态更新为 'offline'。
  Future<void> disconnect() async {
    if (_isOperationInProgress) {
      throw StateError('设备操作正在进行中，请稍后重试');
    }

    _isOperationInProgress = true;
    state = const AsyncLoading();

    try {
      final service = ref.read(deviceServiceProvider);
      await service.disconnect(deviceId);

      // 重新加载设备详情以获取最新状态
      final device = await service.getById(deviceId);
      state = AsyncData(device);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 刷新指定工作台的设备树
  void _refreshDeviceTree(String wbId) {
    // invalidate 会触发 DeviceTreeNotifier 重建
    ref.invalidate(deviceTreeProvider(wbId));
  }

  /// 将异常映射为用户可读的错误消息
  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络后重试';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _mapStatusCode(statusCode);

        default:
          return '网络异常，请稍后重试';
      }
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为用户可读的消息
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '资源冲突，请检查是否已存在相同名称的设备';
      case 422:
        return '数据验证失败，请检查输入';
      case 500:
      case 502:
      case 503:
        return '服务暂时不可用，请稍后再试';
      default:
        return '操作失败，请重试（错误码: $statusCode）';
    }
  }
}

/// 设备详情 Provider
///
/// 通过 [AsyncNotifierProvider.family] 暴露 [DeviceDetailNotifier]，
/// 提供 [AsyncValue]<[Device]> 类型的详情状态，按设备 ID 区分。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final detailState = ref.watch(deviceDetailProvider('dev-1'));
///
/// // 调用方法
/// ref.read(deviceDetailProvider('dev-1').notifier).updateDevice({'name': 'New'});
/// ref.read(deviceDetailProvider('dev-1').notifier).deleteDevice();
/// ```
final deviceDetailProvider = AsyncNotifierProvider.family<
  DeviceDetailNotifier,
  Device,
  String
>(
  DeviceDetailNotifier.new,
);
