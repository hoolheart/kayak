// ignore_for_file: avoid_redundant_argument_values
import 'package:kayak_frontend/models/common.dart';
import 'package:kayak_frontend/models/workbench.dart';
import 'package:kayak_frontend/services/api_client.dart';
import 'package:kayak_frontend/services/auth_interceptor.dart';
import 'package:kayak_frontend/services/auth_service.dart';
import 'package:kayak_frontend/services/error_interceptor.dart';
import 'package:kayak_frontend/services/workbench_service.dart';

/// FakeWorkbenchService — 用于 Workbench 相关测试的 Fake WorkbenchService
///
/// 提供完全可控的行为：成功/失败、延迟、调用计数、参数记录。
class FakeWorkbenchService extends WorkbenchService {
  FakeWorkbenchService({
    this.workbenches = const [],
    this.delay,
    this.listFails = false,
    this.getByIdFails = false,
    this.createFails = false,
    this.updateFails = false,
    this.deleteFails = false,
  }) : super(_FakeApiClient());

  // ========== 配置参数 ==========
  final List<Workbench> workbenches;
  final Duration? delay;
  final bool listFails;
  final bool getByIdFails;
  final bool createFails;
  final bool updateFails;
  final bool deleteFails;

  // ========== 可观测状态 ==========
  int listCallCount = 0;
  int getByIdCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  String? lastGetById;
  String? lastDeleteId;

  /// 重置可观测状态
  void reset() {
    listCallCount = 0;
    getByIdCallCount = 0;
    createCallCount = 0;
    updateCallCount = 0;
    deleteCallCount = 0;

    lastGetById = null;
    lastDeleteId = null;
  }

  @override
  Future<PaginatedResponse<Workbench>> list({
    int page = 1,
    int size = 20,
    String? search,
  }) async {
    listCallCount++;

    if (delay != null) await Future.delayed(delay!);
    if (listFails) throw Exception('Failed to load workbenches');

    return PaginatedResponse<Workbench>(
      items: workbenches,
      total: workbenches.length,
      page: page,
      size: size,
      hasNext: false,
      hasPrev: false,
    );
  }

  @override
  Future<Workbench> getById(String id) async {
    getByIdCallCount++;
    lastGetById = id;

    if (delay != null) await Future.delayed(delay!);
    if (getByIdFails) throw Exception('Workbench not found');

    return workbenches.firstWhere(
      (w) => w.id == id,
      orElse: () => throw Exception('Workbench not found'),
    );
  }

  @override
  Future<Workbench> create(CreateWorkbenchRequest request) async {
    createCallCount++;

    if (delay != null) await Future.delayed(delay!);
    if (createFails) throw Exception('Create workbench failed');

    return Workbench(
      id: 'wb-new-$createCallCount',
      name: request.name,
      description: request.description,
      ownerType: request.ownerType,
      ownerId: request.ownerId,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Workbench> update(String id, Map<String, dynamic> data) async {
    updateCallCount++;

    if (delay != null) await Future.delayed(delay!);
    if (updateFails) throw Exception('Update workbench failed');

    return getById(id);
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeleteId = id;

    if (delay != null) await Future.delayed(delay!);
    if (deleteFails) throw Exception('Delete workbench failed');
  }
}

/// Dummy interceptors for FakeWorkbenchService
class _FakeAuthInterceptor extends AuthInterceptor {
  _FakeAuthInterceptor() : super(FakeAuthService());
}

class _FakeErrorInterceptor extends ErrorInterceptor {
  _FakeErrorInterceptor() : super();
}

/// Dummy ApiClient for FakeWorkbenchService
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(
    baseUrl: '',
    authInterceptor: _FakeAuthInterceptor(),
    errorInterceptor: _FakeErrorInterceptor(),
  );
}

class FakeAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
