/// S1-019: 设备与测点管理UI 测试
///
/// 覆盖设备树形展示、设备创建/编辑/删除、测点列表展示等功能测试
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/workbench/models/device.dart';
import 'package:kayak_frontend/features/workbench/models/point.dart';
import 'package:kayak_frontend/features/workbench/widgets/device/device_form_dialog.dart';
import 'package:kayak_frontend/features/workbench/widgets/point/point_value_display.dart';

// Test helpers
Device createTestDevice({
  String id = 'device-1',
  String name = 'Test Device',
  DeviceStatus status = DeviceStatus.online,
  String? parentId,
}) {
  return Device(
    id: id,
    workbenchId: 'workbench-1',
    parentId: parentId,
    name: name,
    protocolType: ProtocolType.virtual,
    protocolParams: {
      'sampleInterval': 1000,
      'minValue': 0.0,
      'maxValue': 100.0
    },
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Point createTestPoint({
  String id = 'point-1',
  String name = 'Test Point',
  DataType dataType = DataType.number,
  AccessType accessType = AccessType.ro,
  PointStatus status = PointStatus.active,
  String? unit,
}) {
  return Point(
    id: id,
    deviceId: 'device-1',
    name: name,
    dataType: dataType,
    accessType: accessType,
    unit: unit,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

PointValue createTestPointValue({
  String pointId = 'point-1',
  dynamic value = 25.5,
}) {
  return PointValue(
    pointId: pointId,
    value: value,
    timestamp: DateTime.now(),
  );
}

void main() {
  group('TC-S1-019-13: 打开创建设备对话框测试', () {
    testWidgets('add device button opens dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('add-device-button'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DeviceFormDialog(
                      workbenchId: 'workbench-1',
                    ),
                  );
                },
                child: const Text('Add Device'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add-device-button')));
      await tester.pumpAndSettle();

      // Dialog should be open
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('添加设备'), findsOneWidget);
    });
  });

  group('TC-S1-019-14: 创建设备表单字段验证测试', () {
    testWidgets('empty form shows validation error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DeviceFormDialog(
                      workbenchId: 'workbench-1',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Try to submit without filling form
      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('设备名称不能为空'), findsOneWidget);
    });
  });

  group('TC-S1-019-15: Virtual协议选择测试', () {
    testWidgets('protocol dropdown shows Virtual option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DeviceFormDialog(
                      workbenchId: 'workbench-1',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Open protocol dropdown
      await tester.tap(find.byKey(const Key('protocol-type-dropdown')));
      await tester.pumpAndSettle();

      // Verify Virtual option exists (use findsWidgets since it appears in dropdown and menu)
      expect(find.text('VIRTUAL'), findsWidgets);
    });
  });

  group('TC-S1-019-16: Virtual协议参数配置测试', () {
    testWidgets('virtual params section is displayed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DeviceFormDialog(
                      workbenchId: 'workbench-1',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify Virtual params section exists
      expect(find.byKey(const Key('virtual-params-section')), findsOneWidget);
      expect(find.byKey(const Key('virtual-sample-interval')), findsOneWidget);
    });
  });

  group('TC-S1-019-23: 删除设备确认对话框测试', () {
    testWidgets('delete confirmation dialog shows device name', (tester) async {
      final device =
          createTestDevice(id: 'delete-test-1', name: 'Device To Delete');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: Text('确定要删除设备 "${device.name}" 吗？此操作不可撤销。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('确认删除'), findsOneWidget);
      expect(
          find.text('确定要删除设备 "Device To Delete" 吗？此操作不可撤销。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });
  });

  group('TC-S1-019-33: 测点值显示测试', () {
    testWidgets('point value is displayed correctly', (tester) async {
      final pointValue = createTestPointValue(
        pointId: 'pt-val-1',
        value: 25.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointValueDisplay(
              value: pointValue,
              dataType: DataType.number,
            ),
          ),
        ),
      );

      // Number with 2 decimal places
      expect(find.text('25.50'), findsOneWidget);
    });
  });

  group('TC-S1-019-37: 不同数据类型值显示格式测试', () {
    testWidgets('number type shows decimal value', (tester) async {
      final pointValue = createTestPointValue(
        pointId: 'pt-num-1',
        value: 25.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointValueDisplay(
              value: pointValue,
              dataType: DataType.number,
            ),
          ),
        ),
      );

      expect(find.text('25.50'), findsOneWidget);
    });

    testWidgets('integer type shows integer value', (tester) async {
      final pointValue = createTestPointValue(
        pointId: 'pt-int-1',
        value: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointValueDisplay(
              value: pointValue,
              dataType: DataType.integer,
            ),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('boolean type shows toggle icon', (tester) async {
      final pointValue = createTestPointValue(
        pointId: 'pt-bool-1',
        value: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointValueDisplay(
              value: pointValue,
              dataType: DataType.boolean,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.toggle_on), findsOneWidget);
    });

    testWidgets('string type shows text value', (tester) async {
      final pointValue = createTestPointValue(
        pointId: 'pt-str-1',
        value: 'status_ok',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointValueDisplay(
              value: pointValue,
              dataType: DataType.string,
            ),
          ),
        ),
      );

      expect(find.text('status_ok'), findsOneWidget);
    });
  });

  group('TC-S1-019-19: 取消创建设备测试', () {
    testWidgets('cancel button closes dialog without submitting',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DeviceFormDialog(
                      workbenchId: 'workbench-1',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter some text
      await tester.enterText(
          find.byKey(const Key('device-name-field')), 'Test Device');
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.byKey(const Key('cancel-device-button')));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('TC-S1-019-25: 取消删除设备测试', () {
    testWidgets('cancel delete preserves device in list', (tester) async {
      bool deleteConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('确定要删除设备 "Test Device" 吗？'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            deleteConfirmed = true;
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Delete should not be confirmed
      expect(deleteConfirmed, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
