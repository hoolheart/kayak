/// 方法编辑Provider测试
///
/// 测试 MethodEditNotifier 类的行为
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/methods/models/method.dart';
import 'package:kayak_frontend/features/methods/providers/method_edit_provider.dart';
import 'package:kayak_frontend/features/methods/services/method_service.dart';
import 'package:mocktail/mocktail.dart';

/// Mock方法服务
class MockMethodService extends Mock implements MethodServiceInterface {}

/// 注册fallback值
class FakeMap extends Fake implements Map<String, dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMap());
    registerFallbackValue(<String, dynamic>{});
  });

  group('MethodEditNotifier', () {
    late MockMethodService mockService;

    setUp(() {
      mockService = MockMethodService();
    });

    group('加载方法', () {
      test('loadMethod加载现有方法', () async {
        final method = createTestMethod(
          description: 'A test method',
          processDefinition: {
            'nodes': [
              {'id': 'start', 'type': 'Start'},
              {'id': 'end', 'type': 'End'},
            ],
          },
          parameterSchema: {
            'param1': {
              'type': 'number',
              'default': 10,
              'unit': 'ms',
              'description': 'A parameter',
            },
          },
        );

        when(() => mockService.getMethod('test-id'))
            .thenAnswer((_) async => method);

        final notifier = MethodEditNotifier(mockService);
        await notifier.loadMethod('test-id');

        expect(notifier.state.id, equals('test-id'));
        expect(notifier.state.name, equals('Test Method'));
        expect(notifier.state.description, equals('A test method'));
        expect(notifier.state.isLoaded, isTrue);
        expect(notifier.state.isDirty, isFalse);
      });

      test('loadMethod处理错误', () async {
        when(() => mockService.getMethod('invalid-id'))
            .thenThrow(Exception('Not found'));

        final notifier = MethodEditNotifier(mockService);
        await notifier.loadMethod('invalid-id');

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.isLoaded, isTrue);
      });
    });

    group('更新方法属性', () {
      test('updateName更新方法名称', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.updateName('New Name');

        expect(notifier.state.name, equals('New Name'));
        expect(notifier.state.isDirty, isTrue);
      });

      test('updateDescription更新方法描述', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.updateDescription('New description');

        expect(notifier.state.description, equals('New description'));
        expect(notifier.state.isDirty, isTrue);
      });

      test('updateProcessDefinition更新过程定义JSON', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.updateProcessDefinition('{"nodes": []}');

        expect(notifier.state.processDefinitionJson, equals('{"nodes": []}'));
        expect(notifier.state.isDirty, isTrue);
      });
    });

    group('参数管理', () {
      test('addParameter添加新参数', () async {
        final notifier = MethodEditNotifier(mockService);
        expect(notifier.state.parameters.length, equals(0));

        notifier.addParameter();

        expect(notifier.state.parameters.length, equals(1));
        expect(
          notifier.state.parameters.containsKey('new_parameter_1'),
          isTrue,
        );
        expect(notifier.state.isDirty, isTrue);
      });

      test('addParameterWithConfig添加带配置的参数', () async {
        final notifier = MethodEditNotifier(mockService);
        const config = ParameterConfig(
          name: 'custom_param',
          type: 'number',
          defaultValue: 42.0,
          unit: 'Hz',
          description: 'Custom parameter',
        );

        notifier.addParameterWithConfig(config);

        expect(notifier.state.parameters.length, equals(1));
        expect(notifier.state.parameters['custom_param'], equals(config));
      });

      test('removeParameter删除参数', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.addParameter();
        expect(notifier.state.parameters.length, equals(1));

        final paramName = notifier.state.parameters.keys.first;
        notifier.removeParameter(paramName);

        expect(notifier.state.parameters.length, equals(0));
        expect(notifier.state.isDirty, isTrue);
      });

      test('updateParameter更新参数', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.addParameter();
        final oldName = notifier.state.parameters.keys.first;

        const newConfig = ParameterConfig(
          name: 'updated_param',
          type: 'integer',
          defaultValue: 100,
        );
        notifier.updateParameter(oldName, newConfig);

        expect(notifier.state.parameters.containsKey('updated_param'), isTrue);
        expect(notifier.state.parameters.containsKey(oldName), isFalse);
      });
    });

    group('验证方法', () {
      test('validateMethod验证有效JSON', () async {
        const validJson = '{"nodes": [{"id": "start", "type": "Start"}]}';
        when(() => mockService.validateMethod(any())).thenAnswer(
          (_) async => const ValidationResult(valid: true, errors: []),
        );

        final notifier = MethodEditNotifier(mockService);
        notifier.updateProcessDefinition(validJson);
        await notifier.validateMethod();

        expect(notifier.state.isValidating, isFalse);
        expect(notifier.state.validationResult?.valid, isTrue);
      });

      test('validateMethod处理无效JSON', () async {
        const invalidJson = 'not valid json';
        when(() => mockService.validateMethod(any())).thenAnswer(
          (_) async => const ValidationResult(valid: true, errors: []),
        );

        final notifier = MethodEditNotifier(mockService);
        notifier.updateProcessDefinition(invalidJson);
        await notifier.validateMethod();

        expect(notifier.state.error, contains('JSON格式错误'));
      });

      test('validateMethod处理验证失败', () async {
        const validJson = '{"nodes": []}';
        when(() => mockService.validateMethod(any())).thenAnswer(
          (_) async => const ValidationResult(
            valid: false,
            errors: ['Missing Start node', 'Missing End node'],
          ),
        );

        final notifier = MethodEditNotifier(mockService);
        notifier.updateProcessDefinition(validJson);
        await notifier.validateMethod();

        expect(notifier.state.validationResult?.valid, isFalse);
        expect(notifier.state.validationResult?.errors.length, equals(2));
      });
    });

    group('保存方法', () {
      test('saveMethod创建新方法', () async {
        when(
          () => mockService.createMethod(
            name: any(named: 'name'),
            description: any(named: 'description'),
            processDefinition: any(named: 'processDefinition'),
            parameterSchema: any(named: 'parameterSchema'),
          ),
        ).thenAnswer((_) async => createTestMethod());

        final notifier = MethodEditNotifier(mockService);
        notifier.updateName('New Method');
        final result = await notifier.saveMethod();

        expect(result, isTrue);
        expect(notifier.state.isSaving, isFalse);
        expect(notifier.state.isDirty, isFalse);
      });

      test('saveMethod更新现有方法', () async {
        when(() => mockService.getMethod('test-id'))
            .thenAnswer((_) async => createTestMethod());
        when(
          () => mockService.updateMethod(
            any(),
            name: any(named: 'name'),
            description: any(named: 'description'),
            processDefinition: any(named: 'processDefinition'),
            parameterSchema: any(named: 'parameterSchema'),
          ),
        ).thenAnswer((_) async => createTestMethod());

        final notifier = MethodEditNotifier(mockService);
        await notifier.loadMethod('test-id');
        notifier.updateName('Updated Name');
        final result = await notifier.saveMethod();

        expect(result, isTrue);
        verify(
          () => mockService.updateMethod(
            'test-id',
            name: 'Updated Name',
            description: any(named: 'description'),
            processDefinition: any(named: 'processDefinition'),
            parameterSchema: any(named: 'parameterSchema'),
          ),
        ).called(1);
      });

      test('saveMethod处理保存失败', () async {
        when(
          () => mockService.createMethod(
            name: any(named: 'name'),
            description: any(named: 'description'),
            processDefinition: any(named: 'processDefinition'),
            parameterSchema: any(named: 'parameterSchema'),
          ),
        ).thenThrow(Exception('Save failed'));

        final notifier = MethodEditNotifier(mockService);
        notifier.updateName('New Method');
        final result = await notifier.saveMethod();

        expect(result, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.isSaving, isFalse);
      });

      test('saveMethod不允许空名称', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.updateName('');

        final result = await notifier.saveMethod();

        expect(result, isFalse);
      });

      test('saveMethod不允许无效JSON', () async {
        final notifier = MethodEditNotifier(mockService);
        notifier.updateName('Valid Name');
        notifier.updateProcessDefinition('not json');

        final result = await notifier.saveMethod();

        expect(result, isFalse);
        expect(notifier.state.error, contains('JSON格式错误'));
      });
    });

    group('错误处理', () {
      test('clearError清除错误消息', () async {
        when(() => mockService.getMethod('invalid'))
            .thenThrow(Exception('Error'));

        final notifier = MethodEditNotifier(mockService);
        await notifier.loadMethod('invalid');

        expect(notifier.state.error, isNotNull);

        notifier.clearError();
        expect(notifier.state.error, isNull);
      });
    });
  });

  group('MethodEditState', () {
    test('默认状态包含默认JSON模板', () {
      const state = MethodEditState();
      expect(state.processDefinitionJson, contains('nodes'));
      expect(state.parameters, isEmpty);
      expect(state.isDirty, isFalse);
      expect(state.isLoaded, isFalse);
    });

    test('canSave需要非空名称', () {
      const state1 = MethodEditState();
      expect(state1.canSave, isFalse);

      const state2 = MethodEditState(name: 'Valid Name');
      expect(state2.canSave, isTrue);
    });

    test('hasJsonError检测无效JSON', () {
      const state1 = MethodEditState(processDefinitionJson: '{"key": "value"}');
      expect(state1.hasJsonError, isFalse);

      const state2 = MethodEditState(processDefinitionJson: 'not json');
      expect(state2.hasJsonError, isTrue);
    });

    test('jsonError返回解析错误消息', () {
      const state = MethodEditState(processDefinitionJson: 'not json');
      expect(state.jsonError, isNotNull);
    });
  });

  group('ParameterConfig', () {
    test('fromJson正确解析参数配置', () {
      final json = {
        'type': 'number',
        'default': 10.5,
        'unit': 'ms',
        'description': 'A parameter',
      };
      final config = ParameterConfig.fromJson('test_param', json);

      expect(config.name, equals('test_param'));
      expect(config.type, equals('number'));
      expect(config.defaultValue, equals(10.5));
      expect(config.unit, equals('ms'));
      expect(config.description, equals('A parameter'));
    });

    test('toJson正确序列化参数配置', () {
      const config = ParameterConfig(
        name: 'param',
        type: 'integer',
        defaultValue: 100,
        unit: 'Hz',
        description: 'Test',
      );
      final json = config.toJson();

      expect(json['type'], equals('integer'));
      expect(json['default'], equals(100));
      expect(json['unit'], equals('Hz'));
      expect(json['description'], equals('Test'));
    });
  });
}

/// 创建测试用方法数据
Method createTestMethod({
  String id = 'test-id',
  String name = 'Test Method',
  String? description,
  Map<String, dynamic>? processDefinition,
  Map<String, dynamic>? parameterSchema,
}) {
  final now = DateTime.now();
  return Method(
    id: id,
    name: name,
    description: description,
    processDefinition: processDefinition ??
        {
          'nodes': [
            {'id': 'start', 'type': 'Start'},
            {'id': 'end', 'type': 'End'},
          ],
        },
    parameterSchema: parameterSchema ?? {},
    version: 1,
    createdBy: 'test-user',
    createdAt: now,
    updatedAt: now,
  );
}
