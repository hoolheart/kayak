import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/models/experiment.dart';
import 'package:kayak_frontend/services/api_client.dart';
import 'package:kayak_frontend/services/experiment_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late ExperimentService experimentService;
  late MockApiClient mockClient;

  setUp(() {
    mockClient = MockApiClient();
    experimentService = ExperimentService(mockClient);
  });

  // ==========================================
  // 3.1 列表加载
  // ==========================================

  group('TC-EXP-001 ~ 009: list()', () {
    test('TC-EXP-001: 列表加载 — 正常数据', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'page': 1,
          'size': 10,
          'total': 3,
          'items': [
            {
              'id': 'exp-001',
              'user_id': 'user-001',
              'name': 'Temperature Test',
              'method_id': 'm-001',
              'status': 'RUNNING',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-06-01T10:00:00Z',
              'updated_at': '2026-06-01T10:30:00Z',
              'started_at': '2026-06-01T10:30:00Z',
            },
            {
              'id': 'exp-002',
              'user_id': 'user-001',
              'name': 'Pressure Calibration',
              'method_id': 'm-002',
              'status': 'COMPLETED',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-05-28T08:00:00Z',
              'updated_at': '2026-05-28T11:00:00Z',
              'started_at': '2026-05-28T09:00:00Z',
              'ended_at': '2026-05-28T11:00:00Z',
            },
            {
              'id': 'exp-003',
              'user_id': 'user-001',
              'name': 'Vibration Analysis',
              'method_id': 'm-003',
              'status': 'IDLE',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-05-20T08:00:00Z',
              'updated_at': '2026-05-20T08:00:00Z',
            },
          ],
          'has_next': false,
          'has_prev': false,
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.list();

      // Assert
      expect(result.items.length, 3);
      expect(result.page, 1);
      expect(result.size, 10);
      expect(result.items[0].id, 'exp-001');
      expect(result.items[0].name, 'Temperature Test');
      expect(result.items[0].status, ExperimentStatus.running);
      expect(result.items[1].status, ExperimentStatus.completed);
      expect(result.items[2].status, ExperimentStatus.idle);

      verify(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: {'page': 1, 'size': 10},
          )).called(1);
    });

    test('TC-EXP-002: 列表加载 — 空数据', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'page': 1,
          'size': 10,
          'total': 0,
          'items': [],
          'has_next': false,
          'has_prev': false,
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.list();

      // Assert
      expect(result.items, isEmpty);
      expect(result.total, 0);
      expect(result.hasNext, false);
      expect(result.hasPrev, false);
    });

    test('TC-EXP-003: 列表加载 — 分页参数', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'page': 2,
          'size': 10,
          'total': 25,
          'items': [
            {
              'id': 'exp-011',
              'user_id': 'user-001',
              'name': 'Page 2 Test',
              'status': 'IDLE',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-05-20T08:00:00Z',
              'updated_at': '2026-05-20T08:00:00Z',
            },
          ],
          'has_next': true,
          'has_prev': true,
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.list(page: 2);

      // Assert
      expect(result.page, 2);
      expect(result.hasNext, true);
      expect(result.hasPrev, true);

      verify(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: {'page': 2, 'size': 10},
          )).called(1);
    });

    test('TC-EXP-004: 列表加载 — 状态筛选', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'page': 1,
          'size': 10,
          'total': 2,
          'items': [
            {
              'id': 'exp-001',
              'user_id': 'user-001',
              'name': 'Running Test 1',
              'status': 'RUNNING',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-06-01T10:00:00Z',
              'updated_at': '2026-06-01T10:30:00Z',
              'started_at': '2026-06-01T10:30:00Z',
            },
            {
              'id': 'exp-002',
              'user_id': 'user-001',
              'name': 'Running Test 2',
              'status': 'RUNNING',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-05-28T08:00:00Z',
              'updated_at': '2026-05-28T09:00:00Z',
              'started_at': '2026-05-28T09:00:00Z',
            },
          ],
          'has_next': false,
          'has_prev': false,
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.list(
        status: ExperimentStatus.running,
      );

      // Assert
      expect(result.items.length, 2);
      expect(result.items.every((e) => e.status == ExperimentStatus.running),
          true);

      verify(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: {
              'page': 1,
              'size': 10,
              'status': 'RUNNING',
            },
          )).called(1);
    });

    test('TC-EXP-005: 列表加载 — 时间范围筛选', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'page': 1,
          'size': 10,
          'total': 1,
          'items': [
            {
              'id': 'exp-001',
              'user_id': 'user-001',
              'name': 'Jan Test',
              'status': 'IDLE',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-01-15T08:00:00Z',
              'updated_at': '2026-01-15T08:00:00Z',
            },
          ],
          'has_next': false,
          'has_prev': false,
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final createdAfter = DateTime(2026);
      final createdBefore = DateTime(2026, 1, 31, 23, 59, 59, 999);
      final result = await experimentService.list(
        createdAfter: createdAfter,
        createdBefore: createdBefore,
      );

      // Assert
      expect(result.items.length, 1);

      final captured = verify(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['created_after'], createdAfter.toUtc().toIso8601String());
      expect(
          captured['created_before'], createdBefore.toUtc().toIso8601String());
    });

    test('TC-EXP-006: 列表加载 — 综合筛选 + 分页', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'page': 3,
          'size': 5,
          'total': 15,
          'items': [
            {
              'id': 'exp-013',
              'user_id': 'user-001',
              'name': 'Filtered Test',
              'status': 'COMPLETED',
              'owner_type': 'personal',
              'owner_id': 'user-001',
              'created_at': '2026-01-15T08:00:00Z',
              'updated_at': '2026-01-15T10:00:00Z',
            },
          ],
          'has_next': true,
          'has_prev': true,
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.list(
        scope: 'personal',
        status: ExperimentStatus.completed,
        createdAfter: DateTime(2026),
        createdBefore: DateTime(2026, 1, 31),
        page: 3,
        size: 5,
      );

      // Assert
      expect(result.page, 3);
      expect(result.items.length, 1);

      final captured = verify(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['page'], 3);
      expect(captured['size'], 5);
      expect(captured['scope'], 'personal');
      expect(captured['status'], 'COMPLETED');
      expect(captured.containsKey('created_after'), true);
      expect(captured.containsKey('created_before'), true);
    });

    test('TC-EXP-007: 列表加载 — 网络错误', () async {
      // Arrange
      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.list(),
        throwsA(isA<DioException>()),
      );
    });

    test('TC-EXP-008: 列表加载 — 服务器 500 错误', () async {
      // Arrange
      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.list(),
        throwsA(isA<DioException>()),
      );
    });

    test('TC-EXP-009: 列表加载 — 服务器 401 未授权', () async {
      // Arrange
      when(() => mockClient.get(
            '/api/v1/experiments',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.list(),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ==========================================
  // 3.2 单个试验查询
  // ==========================================

  group('TC-EXP-010 ~ 011: getById()', () {
    test('TC-EXP-010: 根据 ID 获取试验 — 成功', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'id': 'exp-123',
          'user_id': 'user-001',
          'name': 'Temperature Test',
          'method_id': 'm-001',
          'status': 'RUNNING',
          'owner_type': 'personal',
          'owner_id': 'user-001',
          'created_at': '2026-06-01T10:00:00Z',
          'updated_at': '2026-06-01T10:30:00Z',
          'started_at': '2026-06-01T10:30:00Z',
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.get('/api/v1/experiments/exp-123')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.getById('exp-123');

      // Assert
      expect(result.id, 'exp-123');
      expect(result.name, 'Temperature Test');
      expect(result.status, ExperimentStatus.running);
      expect(result.methodId, 'm-001');
    });

    test('TC-EXP-011: 根据 ID 获取试验 — 不存在', () async {
      // Arrange
      when(() => mockClient.get('/api/v1/experiments/nonexistent')).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.getById('nonexistent'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ==========================================
  // 3.3 创建试验
  // ==========================================

  group('TC-EXP-012 ~ 014: create()', () {
    test('TC-EXP-012: 创建试验 — 成功', () async {
      // Arrange
      const request = CreateExperimentRequest(
        name: 'Temperature Test',
        methodId: 'm-1',
        description: 'Optional description',
      );

      final responseData = {
        'code': 201,
        'message': 'success',
        'data': {
          'id': 'exp-new',
          'user_id': 'user-001',
          'name': 'Temperature Test',
          'method_id': 'm-1',
          'description': 'Optional description',
          'status': 'IDLE',
          'owner_type': 'personal',
          'owner_id': 'user-001',
          'created_at': '2026-06-01T10:00:00Z',
          'updated_at': '2026-06-01T10:00:00Z',
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.post(
            '/api/v1/experiments',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.create(request);

      // Assert
      expect(result.id, 'exp-new');
      expect(result.name, 'Temperature Test');
      expect(result.methodId, 'm-1');
      expect(result.userId, 'user-001');

      final captured = verify(() => mockClient.post(
            '/api/v1/experiments',
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['name'], 'Temperature Test');
      expect(captured['method_id'], 'm-1');
      expect(captured['description'], 'Optional description');
      expect(captured.containsKey('workbenchId'), false);
      expect(captured.containsKey('parameters'), false);
    });

    test('TC-EXP-013: 创建试验 — 参数验证失败', () async {
      // Arrange
      const request = CreateExperimentRequest(
        name: '', // 空名称
        methodId: 'm-1',
      );

      when(() => mockClient.post(
            '/api/v1/experiments',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 422,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.create(request),
        throwsA(isA<DioException>()),
      );
    });

    test('TC-EXP-014: 创建试验 — 方法不存在', () async {
      // Arrange
      const request = CreateExperimentRequest(
        name: 'Test',
        methodId: 'nonexistent',
      );

      when(() => mockClient.post(
            '/api/v1/experiments',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 409,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.create(request),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ==========================================
  // 3.4 控制操作
  // ==========================================

  group('TC-EXP-015 ~ 022: 控制操作', () {
    final controlSuccessResponse = {
      'code': 200,
      'message': 'success',
      'data': {
        'id': 'exp-001',
        'name': 'Temperature Test',
        'status': 'RUNNING',
        'method_id': 'm-001',
        'description': 'A temperature calibration test',
        'started_at': '2026-06-01T10:30:00+00:00',
        'ended_at': null,
        'created_at': '2026-06-01T10:00:00+00:00',
        'updated_at': '2026-06-01T10:30:00+00:00',
      },
      'timestamp': '2026-06-01T10:30:00+00:00',
    };

    test('TC-EXP-015: 载入试验 (load) — 成功', () async {
      // Arrange
      final loadResponse = {
        ...controlSuccessResponse,
        'data': {
          ...(controlSuccessResponse['data'] as Map<String, dynamic>),
          'status': 'LOADED',
          'started_at': null,
        },
      };

      when(() => mockClient.post(
            '/api/v1/experiments/exp-123/load',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: loadResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result =
          await experimentService.load('exp-123', methodId: 'm-1');

      // Assert
      expect(result.status, 'LOADED');
      expect(result.methodId, 'm-001');

      final captured = verify(() => mockClient.post(
            '/api/v1/experiments/exp-123/load',
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['method_id'], 'm-1');
    });

    test('TC-EXP-016: 开始试验 (start) — 成功', () async {
      // Arrange
      when(() => mockClient.post('/api/v1/experiments/exp-123/start'))
          .thenAnswer(
        (_) async => Response(
          data: controlSuccessResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.start('exp-123');

      // Assert
      expect(result.status, 'RUNNING');
      expect(result.startedAt, isNotNull);
    });

    test('TC-EXP-017: 暂停试验 (pause) — 成功', () async {
      // Arrange
      final pauseResponse = {
        ...controlSuccessResponse,
        'data': {
          ...(controlSuccessResponse['data'] as Map<String, dynamic>),
          'status': 'PAUSED',
        },
      };

      when(() => mockClient.post('/api/v1/experiments/exp-123/pause'))
          .thenAnswer(
        (_) async => Response(
          data: pauseResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.pause('exp-123');

      // Assert
      expect(result.status, 'PAUSED');
    });

    test('TC-EXP-018: 继续试验 (resume) — 成功', () async {
      // Arrange
      final resumeResponse = {...controlSuccessResponse};

      when(() => mockClient.post('/api/v1/experiments/exp-123/resume'))
          .thenAnswer(
        (_) async => Response(
          data: resumeResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.resume('exp-123');

      // Assert
      expect(result.status, 'RUNNING');
    });

    test('TC-EXP-019: 停止试验 (stop) — 成功', () async {
      // Arrange
      final stopResponse = {
        ...controlSuccessResponse,
        'data': {
          ...(controlSuccessResponse['data'] as Map<String, dynamic>),
          'status': 'LOADED',
        },
      };

      when(() => mockClient.post('/api/v1/experiments/exp-123/stop'))
          .thenAnswer(
        (_) async => Response(
          data: stopResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.stop('exp-123');

      // Assert
      expect(result.status, 'LOADED');
    });

    test('TC-EXP-020: 控制操作 — 试验不存在', () async {
      // Arrange
      when(() => mockClient.post('/api/v1/experiments/nonexistent/start'))
          .thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.start('nonexistent'),
        throwsA(isA<DioException>()),
      );
    });

    test('TC-EXP-021: 控制操作 — 状态不允许', () async {
      // Arrange
      when(() => mockClient.post('/api/v1/experiments/exp-idle/start'))
          .thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.start('exp-idle'),
        throwsA(isA<DioException>()),
      );
    });

    test('TC-EXP-022: 控制操作 — 网络超时', () async {
      // Arrange
      when(() => mockClient.post('/api/v1/experiments/exp-123/start'))
          .thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ),
      );

      // Act & Assert
      expect(
        () => experimentService.start('exp-123'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ==========================================
  // 3.5 状态查询
  // ==========================================

  group('TC-EXP-023 ~ 025: 状态查询', () {
    test('TC-EXP-023: 获取试验状态 — 成功', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'id': 'exp-123',
          'name': 'Temperature Test',
          'status': 'RUNNING',
          'method_id': 'm-001',
          'started_at': '2026-06-01T10:30:00+00:00',
          'ended_at': null,
          'updated_at': '2026-06-01T10:30:00+00:00',
        },
        'timestamp': '2026-06-01T10:30:00+00:00',
      };

      when(() => mockClient.get('/api/v1/experiments/exp-123/status'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.getStatus('exp-123');

      // Assert
      expect(result.id, 'exp-123');
      expect(result.name, 'Temperature Test');
      expect(result.status, 'RUNNING');
      expect(result.methodId, 'm-001');
      expect(result.startedAt, isNotNull);
    });

    test('TC-EXP-024: 获取状态历史 — 成功', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': [
          {
            'id': 'log-001',
            'experiment_id': 'exp-001',
            'previous_state': 'LOADED',
            'new_state': 'RUNNING',
            'operation': 'start',
            'user_id': 'user-001',
            'timestamp': '2026-06-01T10:30:00+00:00',
            'error_message': null,
          },
          {
            'id': 'log-002',
            'experiment_id': 'exp-001',
            'previous_state': 'IDLE',
            'new_state': 'LOADED',
            'operation': 'load',
            'user_id': 'user-001',
            'timestamp': '2026-06-01T10:15:00+00:00',
            'error_message': null,
          },
        ],
        'timestamp': '2026-06-01T10:30:00+00:00',
      };

      when(() => mockClient.get('/api/v1/experiments/exp-123/history'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.getHistory('exp-123');

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'log-001');
      expect(result[0].experimentId, 'exp-001');
      expect(result[0].previousState, 'LOADED');
      expect(result[0].newState, 'RUNNING');
      expect(result[0].operation, 'start');
      expect(result[0].userId, 'user-001');
      expect(result[0].errorMessage, null);
      expect(result[1].operation, 'load');
    });

    test('TC-EXP-025: 获取状态历史 — 空历史', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': [],
        'timestamp': '2026-06-01T10:30:00+00:00',
      };

      when(() => mockClient.get('/api/v1/experiments/exp-123/history'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.getHistory('exp-123');

      // Assert
      expect(result, isEmpty);
    });
  });

  // ==========================================
  // 3.6 数据查询
  // ==========================================

  group('TC-EXP-026 ~ 028: queryData()', () {
    test('TC-EXP-026: 查询试验数据 — 正常时间范围', () async {
      // Arrange
      final t1 = DateTime(2026, 6, 1, 10);
      final t2 = DateTime(2026, 6, 1, 11);

      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'device_id': 'dev-1',
          'timestamps': [
            '2026-06-01T10:00:00Z',
            '2026-06-01T10:30:00Z',
            '2026-06-01T11:00:00Z',
          ],
          'values': {
            'p1': [20.0, 21.0, 22.0],
            'p2': [100.0, 101.0, 102.0],
          },
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.post(
            '/api/v1/experiments/exp-123/data/query',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.queryData(
        'exp-123',
        deviceId: 'dev-1',
        pointIds: ['p1', 'p2'],
        startTime: t1,
        endTime: t2,
      );

      // Assert
      expect(result.deviceId, 'dev-1');
      expect(result.timestamps.length, 3);
      expect(result.values['p1'], [20.0, 21.0, 22.0]);
      expect(result.values['p2'], [100.0, 101.0, 102.0]);

      final captured = verify(() => mockClient.post(
            '/api/v1/experiments/exp-123/data/query',
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['device_id'], 'dev-1');
      expect(captured['point_ids'], ['p1', 'p2']);
      expect(captured.containsKey('start_time'), true);
      expect(captured.containsKey('end_time'), true);
    });

    test('TC-EXP-027: 查询试验数据 — 降采样参数', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'device_id': 'dev-1',
          'timestamps': ['2026-06-01T10:00:00Z'],
          'values': {
            'p1': [20.0],
          },
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.post(
            '/api/v1/experiments/exp-123/data/query',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      await experimentService.queryData(
        'exp-123',
        deviceId: 'dev-1',
        downsample: 1000,
      );

      // Assert
      final captured = verify(() => mockClient.post(
            '/api/v1/experiments/exp-123/data/query',
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['downsample'], 1000);
    });

    test('TC-EXP-028: 查询试验数据 — 无数据', () async {
      // Arrange
      final responseData = {
        'code': 200,
        'message': 'success',
        'data': {
          'device_id': 'dev-1',
          'timestamps': <String>[],
          'values': <String, List<double?>>{},
        },
        'timestamp': '2026-06-01T10:30:00Z',
      };

      when(() => mockClient.post(
            '/api/v1/experiments/exp-123/data/query',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await experimentService.queryData(
        'exp-123',
        deviceId: 'dev-1',
      );

      // Assert
      expect(result.timestamps, isEmpty);
      expect(result.values, isEmpty);
    });
  });
}
