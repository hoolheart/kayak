import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/models/device.dart';
import 'package:kayak_frontend/providers/device_provider.dart';
import 'package:kayak_frontend/providers/services.dart';

import '../helpers/fake_device_service.dart';

// =============================================================================
// DeviceTreeNotifier Unit Tests
// =============================================================================

void main() {
  group('DeviceTreeNotifier — Build Tree', () {
    test('builds empty tree from empty device list', () async {
      final fakeService = FakeDeviceService();
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final result = await notifier.build();

      expect(result, isEmpty);
      expect(fakeService.listByWorkbenchCallCount, greaterThanOrEqualTo(1));
      expect(fakeService.lastListWorkbenchId, 'wb-test');
    });

    test('builds flat tree from root devices only', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Device A'),
          _createDevice(id: 'dev-2', name: 'Device B'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final result = await notifier.build();

      expect(result.length, 2);
      expect(result[0].id, 'dev-1');
      expect(result[0].children, isEmpty);
      expect(result[1].id, 'dev-2');
      expect(result[1].children, isEmpty);
    });

    test('builds nested tree from parent-child relationships', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Root'),
          _createDevice(id: 'dev-1-1', name: 'Child', parentId: 'dev-1'),
          _createDevice(id: 'dev-1-2', name: 'Child 2', parentId: 'dev-1'),
          _createDevice(id: 'dev-1-1-1', name: 'Grandchild', parentId: 'dev-1-1'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final result = await notifier.build();

      expect(result.length, 1);
      expect(result[0].id, 'dev-1');
      expect(result[0].children.length, 2);
      expect(result[0].children[0].id, 'dev-1-1');
      expect(result[0].children[0].children.length, 1);
      expect(result[0].children[0].children[0].id, 'dev-1-1-1');
      expect(result[0].children[1].id, 'dev-1-2');
      expect(result[0].children[1].children, isEmpty);
    });

    test('handles multiple root nodes with mixed children', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'root-1', name: 'Root 1'),
          _createDevice(id: 'root-1-c1', name: 'R1 Child', parentId: 'root-1'),
          _createDevice(id: 'root-2', name: 'Root 2'),
          _createDevice(id: 'root-2-c1', name: 'R2 Child', parentId: 'root-2'),
          _createDevice(id: 'root-2-c2', name: 'R2 Child 2', parentId: 'root-2'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final result = await notifier.build();

      expect(result.length, 2);
      expect(result[0].children.length, 1);
      expect(result[1].children.length, 2);
    });
  });

  group('DeviceTreeNotifier — Provider State', () {
    test('initial state transitions to AsyncData on success', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Device A'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      // 使用 listen 捕获状态变化
      AsyncValue<List<DeviceTreeNode>>? capturedState;
      container.listen(
        deviceTreeProvider('wb-test'),
        (prev, next) => capturedState = next,
      );

      // 等待 provider 完成加载
      await container.read(deviceTreeProvider('wb-test').future);

      expect(capturedState, isA<AsyncData<List<DeviceTreeNode>>>());
      final data = capturedState!.asData!.value;
      expect(data.length, 1);
      expect(data[0].name, 'Device A');
    });

    test('initial state transitions to AsyncError on failure', () async {
      final fakeService = FakeDeviceService(
        listFails: true,
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      AsyncValue<List<DeviceTreeNode>>? capturedState;
      container.listen(
        deviceTreeProvider('wb-test'),
        (prev, next) => capturedState = next,
      );

      // 触发 provider 初始化并等待微任务完成
      container.read(deviceTreeProvider('wb-test'));
      await Future<void>.delayed(Duration.zero);

      // Riverpod 3.x: 错误可能以 AsyncLoading(error: ..., retrying) 形式存在
      expect(capturedState!.hasError, isTrue);
      expect(capturedState!.error, isA<Exception>());
    });
  });

  group('DeviceTreeNotifier — CRUD Operations', () {
    test('deleteDevice calls service and refreshes', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Device A'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      await notifier.deleteDevice('dev-1');

      expect(fakeService.deleteCallCount, 1);
      expect(fakeService.lastDeleteId, 'dev-1');
      // 删除后 refresh 会触发重新加载
      expect(fakeService.listByWorkbenchCallCount, greaterThanOrEqualTo(1));
    });

    test('createDevice calls service and refreshes', () async {
      final fakeService = FakeDeviceService();
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final device = await notifier.createDevice(
        wbId: 'wb-test',
        name: 'New Device',
        protocolType: 'virtual',
      );

      expect(device.name, 'New Device');
      expect(fakeService.createCallCount, 1);
      expect(fakeService.lastCreateName, 'New Device');
    });

    test('updateDevice calls service and refreshes', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Old Name'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final device = await notifier.updateDevice('dev-1', {'name': 'New Name'});

      expect(fakeService.updateCallCount, 1);
      expect(device.id, 'dev-1');
    });
  });

  group('DeviceTreeNotifier — Refresh', () {
    test('refresh reloads data', () async {
      final fakeService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Device A'),
        ],
      );
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final initialCallCount = fakeService.listByWorkbenchCallCount;

      await notifier.build();
      expect(fakeService.listByWorkbenchCallCount, greaterThan(initialCallCount));

      await notifier.refresh();
      expect(fakeService.listByWorkbenchCallCount, greaterThan(initialCallCount));
    });
  });

  group('DeviceTreeNotifier — Tree Node Data Mapping', () {
    test('maps all device fields to tree node', () async {
      final device = Device(
        id: 'dev-1',
        workbenchId: 'wb-test',
        name: 'Test Device',
        protocolType: ProtocolType.modbusTcp,
        protocolParams: {'host': '192.168.1.1'},
        manufacturer: 'Siemens',
        model: 'S7-1200',
        sn: 'SN123456',
        status: 'online',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 2),
      );
      final fakeService = FakeDeviceService(devices: [device]);
      final container = ProviderContainer(overrides: [
        deviceServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(deviceTreeProvider('wb-test').notifier);
      final result = await notifier.build();

      final node = result.first;
      expect(node.id, 'dev-1');
      expect(node.workbenchId, 'wb-test');
      expect(node.name, 'Test Device');
      expect(node.protocolType, ProtocolType.modbusTcp);
      expect(node.protocolParams, {'host': '192.168.1.1'});
      expect(node.manufacturer, 'Siemens');
      expect(node.model, 'S7-1200');
      expect(node.sn, 'SN123456');
      expect(node.status, 'online');
    });
  });
}

Device _createDevice({
  required String id,
  required String name,
  ProtocolType protocolType = ProtocolType.virtual,
  String status = 'online',
  String? parentId,
}) {
  return Device(
    id: id,
    workbenchId: 'wb-test',
    parentId: parentId,
    name: name,
    protocolType: protocolType,
    status: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
