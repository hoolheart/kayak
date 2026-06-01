// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/device.dart';
import 'package:kayak_frontend/models/point.dart';
import 'package:kayak_frontend/models/workbench.dart';
import 'package:kayak_frontend/pages/point/point_list_widget.dart';
import 'package:kayak_frontend/pages/point/point_value_display.dart';
import 'package:kayak_frontend/pages/workbench/workbench_detail_page.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/widgets/toast.dart';

import '../helpers/fake_device_service.dart';
import '../helpers/fake_point_service.dart';
import '../helpers/fake_workbench_service.dart';

// =============================================================================
// WorkbenchDetailPage Integration Tests (TC-WD-001 ~ TC-WD-008)
// =============================================================================

Workbench _createWorkbench({
  required String id,
  required String name,
  String status = 'active',
  String? description,
}) {
  return Workbench(
    id: id,
    name: name,
    status: status,
    description: description,
    ownerType: 'user',
    ownerId: 'user-1',
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

Device _createDevice({
  required String id,
  required String name,
  required String workbenchId,
  ProtocolType protocolType = ProtocolType.virtual,
  String status = 'online',
  Map<String, dynamic>? protocolParams,
}) {
  return Device(
    id: id,
    workbenchId: workbenchId,
    name: name,
    protocolType: protocolType,
    status: status,
    protocolParams: protocolParams,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

Point _createPoint({
  required String id,
  required String deviceId,
  required String name,
  DataType dataType = DataType.number,
  AccessType accessType = AccessType.ro,
  String? unit,
  String status = 'normal',
}) {
  return Point(
    id: id,
    deviceId: deviceId,
    name: name,
    dataType: dataType,
    accessType: accessType,
    unit: unit,
    status: status,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

Widget _wrapWorkbenchPage({
  required Widget child,
  required FakeDeviceService fakeDeviceService,
  required FakePointService fakePointService,
  required FakeWorkbenchService fakeWorkbenchService,
  ThemeMode themeMode = ThemeMode.light,
  Size? screenSize,
}) {
  Widget result = ProviderScope(
    overrides: [
      workbenchServiceProvider.overrideWithValue(fakeWorkbenchService),
      deviceServiceProvider.overrideWithValue(fakeDeviceService),
      pointServiceProvider.overrideWithValue(fakePointService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Builder(
        builder: (context) {
          final mq = MediaQuery.of(context);
          return Toast.init(
            context,
            SizedBox(
              width: mq.size.width,
              height: mq.size.height,
              child: Scaffold(
                body: child,
              ),
            ),
          );
        },
      ),
    ),
  );

  if (screenSize != null) {
    result = MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: result,
    );
  }

  return result;
}

void main() {
  // 禁用无限 shimmer 动画以避免 pumpAndSettle 永远等待
  PointValueDisplay.isTestMode = true;
  PointListWidget.isTestMode = true;

  group('WorkbenchDetailPage — Placeholder (TC-WD-001)', () {
    testWidgets('TC-WD-001: no device selected shows placeholder',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(id: 'dev-1', name: 'Device 1', workbenchId: 'wb-1'),
        ],
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-1', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapWorkbenchPage(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1440, 900),
        child: const WorkbenchDetailPage(id: 'wb-1'),
      ));
      await tester.pumpAndSettle();

      // Placeholder shown (memory icon also in device tree for virtual dev)
      expect(find.byIcon(Icons.memory), findsWidgets);
      expect(find.text('Device Details'), findsWidgets);
      expect(find.text('Select a device to view details'), findsOneWidget);

      // No point list
      expect(find.text('Points'), findsNothing);
    });
  });

  group('WorkbenchDetailPage — Device Selected (TC-WD-002)', () {
    testWidgets('TC-WD-002: selecting device shows details and point list',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Virtual Device',
            workbenchId: 'wb-1',
            protocolType: ProtocolType.virtual,
          ),
        ],
      );
      final pointService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
            unit: '°C',
          ),
          _createPoint(
            id: 'pt-2',
            deviceId: 'dev-1',
            name: 'Pressure',
            dataType: DataType.integer,
            unit: 'MPa',
          ),
        ],
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-1', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapWorkbenchPage(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1440, 900),
        child: const WorkbenchDetailPage(id: 'wb-1'),
      ));
      await tester.pumpAndSettle();

      // Select device from tree
      await tester.tap(find.text('Virtual Device'));
      await tester.pumpAndSettle();

      // Device detail shown
      expect(find.text('Virtual Device'), findsWidgets);
      expect(find.text('Virtual'), findsWidgets);

      // Point list shown (Points text appears in both detail header and table)
      expect(find.text('Points'), findsWidgets);
      expect(find.text('2 points'), findsOneWidget);
      expect(find.text('Temperature Sensor'), findsOneWidget);
      expect(find.text('Pressure'), findsOneWidget);
    });
  });

  group('WorkbenchDetailPage — L10n (TC-WD-003)', () {
    testWidgets('TC-WD-003: all texts from l10n', (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Device 1',
            workbenchId: 'wb-1',
          ),
        ],
      );
      final pointService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
          ),
        ],
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-1', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapWorkbenchPage(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1440, 900),
        child: const WorkbenchDetailPage(id: 'wb-1'),
      ));
      await tester.pumpAndSettle();

      // Select device
      await tester.tap(find.text('Device 1'));
      await tester.pumpAndSettle();

      // l10n texts (not hardcoded Chinese)
      // Note: Edit/Delete in AppBar are IconButton tooltips, not Text widgets
      expect(find.text('Points'), findsWidgets);
      expect(find.text('1 points'), findsOneWidget);
      expect(find.text('Add Point'), findsWidgets);
    });
  });

  group('WorkbenchDetailPage — Modbus Device (TC-WD-006)', () {
    testWidgets('TC-WD-006: Modbus device shows protocol params',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-modbus',
            name: 'Modbus TCP Device',
            workbenchId: 'wb-1',
            protocolType: ProtocolType.modbusTcp,
            protocolParams: {
              'host': '192.168.1.100',
              'port': 502,
            },
          ),
        ],
      );
      final pointService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-m1',
            deviceId: 'dev-modbus',
            name: 'Coil Status',
            dataType: DataType.boolean,
          ),
        ],
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-1', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapWorkbenchPage(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1440, 900),
        child: const WorkbenchDetailPage(id: 'wb-1'),
      ));
      await tester.pumpAndSettle();

      // Select device
      await tester.tap(find.text('Modbus TCP Device'));
      await tester.pumpAndSettle();

      // Protocol icon and label
      expect(find.byIcon(Icons.lan), findsWidgets);
      expect(find.text('Modbus TCP'), findsWidgets);

      // Protocol params
      expect(find.text('host'), findsOneWidget);
      expect(find.text('192.168.1.100'), findsOneWidget);
      expect(find.text('port'), findsOneWidget);
      expect(find.text('502'), findsOneWidget);

      // Point list
      expect(find.text('Points'), findsWidgets);
      expect(find.text('Coil Status'), findsOneWidget);
    });
  });
}
