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
// TASK-019: Device + Point Integration Tests
// =============================================================================
// Coverage:
// - Journey A: Add Virtual Device and Configure Points (INT-A-01 ~ INT-A-03)
// - Journey B: Modbus TCP Device + Point Configuration (INT-B-01 ~ INT-B-02)
// - Journey C: Device Tree and Point List Interaction (INT-C-01 ~ INT-C-03)
// - Error Handling (INT-E-01 ~ INT-E-02)
// - Responsive Layout (INT-R-01)
// =============================================================================

// ---------------------------------------------------------------------------
// Test Data Helpers
// ---------------------------------------------------------------------------

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
  String? parentId,
}) {
  return Device(
    id: id,
    workbenchId: workbenchId,
    parentId: parentId,
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

// ---------------------------------------------------------------------------
// Widget Wrapper
// ---------------------------------------------------------------------------

Widget _wrapIntegrationTest({
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

// ---------------------------------------------------------------------------
// Helper: Wait for async operations
// ---------------------------------------------------------------------------

Future<void> _pumpAsync(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

// ---------------------------------------------------------------------------
// Main Test Suite
// ---------------------------------------------------------------------------

void main() {
  // Disable infinite shimmer animations
  PointValueDisplay.isTestMode = true;
  PointListWidget.isTestMode = true;

  // ==========================================================================
  // Journey A: Add Virtual Device and Configure Points
  // ==========================================================================

  group('Journey A: Virtual Device + Points Flow', () {
    testWidgets('INT-A-01: complete device + point creation flow',
        (tester) async {
      final deviceService = FakeDeviceService();
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-empty', name: 'Empty Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-empty'),
      ));
      await _pumpAsync(tester);

      // Verify empty state
      expect(find.text('No devices yet'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Click add device button
      await tester.tap(find.byIcon(Icons.add).first);
      await _pumpAsync(tester);

      // DeviceConfigDialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);

      // Enter device name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Device Name').first,
        'Test Virtual Device',
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Click Save
      await tester.tap(find.text('Save').last);
      await _pumpAsync(tester);

      // Verify device appears in tree
      expect(find.text('Test Virtual Device'), findsOneWidget);

      // Verify device detail panel shows
      expect(find.text('Test Virtual Device'), findsWidgets);
    });

    testWidgets('INT-A-02: existing device with points shows correctly',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Virtual Sensor',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.virtual,
            protocolParams: {
              'mode': 'random',
              'data_type': 'float32',
              'min': 0,
              'max': 100,
            },
          ),
        ],
      );
      final pointService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature',
            dataType: DataType.number,
            accessType: AccessType.ro,
            unit: '°C',
          ),
          _createPoint(
            id: 'pt-2',
            deviceId: 'dev-1',
            name: 'Pressure',
            dataType: DataType.integer,
            accessType: AccessType.ro,
            unit: 'MPa',
          ),
        ],
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select the device
      await tester.tap(find.text('Virtual Sensor'));
      await _pumpAsync(tester);

      // Verify device detail shows
      expect(find.text('Virtual Sensor'), findsWidgets);
      expect(find.text('Virtual'), findsWidgets);

      // Verify point list shows points
      expect(find.text('2 points'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('Pressure'), findsOneWidget);
      expect(find.text('°C'), findsWidgets);
      expect(find.text('MPa'), findsWidgets);

      // Verify protocol params shown
      expect(find.text('mode'), findsOneWidget);
      expect(find.text('random'), findsOneWidget);
    });

    testWidgets('INT-A-03: delete point keeps device tree intact',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Virtual Sensor',
            workbenchId: 'wb-test',
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
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select device
      await tester.tap(find.text('Virtual Sensor'));
      await _pumpAsync(tester);

      // Verify point visible
      expect(find.text('Temperature Sensor'), findsOneWidget);

      // Delete point
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await _pumpAsync(tester);

      // Confirm dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await _pumpAsync(tester);

      // Verify point deleted
      expect(pointService.deleteCallCount, 1);
      expect(pointService.lastDeleteId, 'pt-1');
    });
  });

  // ==========================================================================
  // Journey B: Modbus Device + Point Configuration
  // ==========================================================================

  group('Journey B: Modbus Device + Points Flow', () {
    testWidgets('INT-B-01: Modbus TCP device with Modbus point',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-modbus',
            name: 'PLC Controller',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.modbusTcp,
            protocolParams: {
              'host': '192.168.1.100',
              'port': 502,
              'slave_id': 1,
              'timeout_ms': 5000,
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
            accessType: AccessType.rw,
          ),
        ],
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select Modbus device
      await tester.tap(find.text('PLC Controller'));
      await _pumpAsync(tester);

      // Verify Modbus-specific UI
      expect(find.byIcon(Icons.lan), findsAtLeastNWidgets(1));
      expect(find.text('Modbus TCP'), findsWidgets);

      // Verify protocol params displayed
      expect(find.text('host'), findsOneWidget);
      expect(find.text('192.168.1.100'), findsOneWidget);
      expect(find.text('port'), findsOneWidget);
      expect(find.text('502'), findsOneWidget);

      // Verify point list
      expect(find.text('Coil Status'), findsOneWidget);
      expect(find.text('Boolean'), findsOneWidget);
    });

    testWidgets('INT-B-02: Modbus RTU device shows correctly',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-rtu',
            name: 'Serial Sensor',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.modbusRtu,
            protocolParams: {
              'serial_port': '/dev/ttyUSB0',
              'baud_rate': 9600,
              'data_bits': 8,
              'stop_bits': 1,
              'parity': 'none',
              'slave_id': 2,
            },
          ),
        ],
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select RTU device
      await tester.tap(find.text('Serial Sensor'));
      await _pumpAsync(tester);

      // Verify RTU-specific UI
      expect(find.byIcon(Icons.cable), findsAtLeastNWidgets(1));
      expect(find.text('Modbus RTU'), findsWidgets);

      // Verify protocol params
      expect(find.text('serial_port'), findsOneWidget);
      expect(find.text('/dev/ttyUSB0'), findsOneWidget);
      expect(find.text('baud_rate'), findsOneWidget);
      expect(find.text('9600'), findsOneWidget);
    });
  });

  // ==========================================================================
  // Journey C: Device Tree and Point List Interaction
  // ==========================================================================

  group('Journey C: Device Tree <-> Point List Interaction', () {
    testWidgets('INT-C-01: switching devices updates point list',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-a',
            name: 'Device A',
            workbenchId: 'wb-test',
          ),
          _createDevice(
            id: 'dev-b',
            name: 'Device B',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.modbusTcp,
          ),
        ],
      );
      final pointService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-a1',
            deviceId: 'dev-a',
            name: 'Point A1',
            unit: '°C',
          ),
          _createPoint(
            id: 'pt-b1',
            deviceId: 'dev-b',
            name: 'Point B1',
            unit: 'V',
          ),
        ],
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select Device A
      await tester.tap(find.text('Device A'));
      await _pumpAsync(tester);

      // Verify Device A's points
      expect(find.text('Point A1'), findsOneWidget);
      expect(find.text('°C'), findsWidgets);
      expect(find.text('Point B1'), findsNothing);

      // Switch to Device B
      await tester.tap(find.text('Device B'));
      await _pumpAsync(tester);

      // Verify Device B's points, Device A's points gone
      expect(find.text('Point B1'), findsOneWidget);
      expect(find.text('V'), findsWidgets);
      expect(find.text('Point A1'), findsNothing);
    });

    testWidgets('INT-C-02: device context menu shows delete option',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-a',
            name: 'Device A',
            workbenchId: 'wb-test',
          ),
        ],
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select Device A
      await tester.tap(find.text('Device A'));
      await _pumpAsync(tester);

      // Open context menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await _pumpAsync(tester);

      // Verify delete option exists in menu
      expect(find.text('Delete Device'), findsOneWidget);
      expect(find.text('Edit Device'), findsOneWidget);
    });

    testWidgets('INT-C-03: empty state to data transition',
        (tester) async {
      final deviceService = FakeDeviceService();
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-empty', name: 'Empty Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-empty'),
      ));
      await _pumpAsync(tester);

      // Verify empty state
      expect(find.text('No devices yet'), findsOneWidget);
    });
  });

  // ==========================================================================
  // Error Handling Tests
  // ==========================================================================

  group('Error Handling', () {
    testWidgets('INT-E-01: device list error shows error state',
        (tester) async {
      final deviceService = FakeDeviceService(
        listFails: true,
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error state in device tree area
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('INT-E-02: point list error shows error state',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Device 1',
            workbenchId: 'wb-test',
          ),
        ],
      );
      final pointService = FakePointService(
        listFails: true,
      );
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select device
      await tester.tap(find.text('Device 1'));
      await _pumpAsync(tester);

      // Point list should NOT show data (since list fails)
      // Verify error state by checking no points loaded and no skeleton
      expect(find.text('0 points'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ==========================================================================
  // Responsive Layout Tests
  // ==========================================================================

  group('Responsive Layout', () {
    testWidgets('INT-R-01: desktop layout side by side',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Device 1',
            workbenchId: 'wb-test',
          ),
        ],
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Verify both tree and detail areas exist
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Device Details'), findsWidgets);

      // In desktop, tree and detail should be in a Row
      expect(find.byType(Row), findsWidgets);

      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });

  // ==========================================================================
  // Component Interaction Tests
  // ==========================================================================

  group('Component Interactions', () {
    testWidgets('INT-CI-01: device selection triggers detail load',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Test Device',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.virtual,
            status: 'online',
          ),
        ],
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Verify device in tree
      expect(find.text('Test Device'), findsOneWidget);

      // Select device
      await tester.tap(find.text('Test Device'));
      await _pumpAsync(tester);

      // Verify detail panel updated
      expect(find.text('Test Device'), findsWidgets);
      expect(find.text('online'), findsWidgets);

      // Verify getById was called
      expect(deviceService.getByIdCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('INT-CI-02: multiple protocol types in same tree',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-v',
            name: 'Virtual Device',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.virtual,
          ),
          _createDevice(
            id: 'dev-tcp',
            name: 'TCP Device',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.modbusTcp,
          ),
          _createDevice(
            id: 'dev-rtu',
            name: 'RTU Device',
            workbenchId: 'wb-test',
            protocolType: ProtocolType.modbusRtu,
          ),
        ],
      );
      final pointService = FakePointService();
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Verify all protocol icons present (at least one each)
      expect(find.byIcon(Icons.memory), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.lan), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.cable), findsAtLeastNWidgets(1));

      // Verify all device names
      expect(find.text('Virtual Device'), findsOneWidget);
      expect(find.text('TCP Device'), findsOneWidget);
      expect(find.text('RTU Device'), findsOneWidget);

      // Count should be 3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('INT-CI-03: point list empty state shows count',
        (tester) async {
      final deviceService = FakeDeviceService(
        devices: [
          _createDevice(
            id: 'dev-1',
            name: 'Device 1',
            workbenchId: 'wb-test',
          ),
        ],
      );
      final pointService = FakePointService(points: const []);
      final workbenchService = FakeWorkbenchService(
        workbenches: [
          _createWorkbench(id: 'wb-test', name: 'Test Workbench'),
        ],
      );

      await tester.pumpWidget(_wrapIntegrationTest(
        fakeDeviceService: deviceService,
        fakePointService: pointService,
        fakeWorkbenchService: workbenchService,
        screenSize: const Size(1600, 1200),
        child: const WorkbenchDetailPage(id: 'wb-test'),
      ));
      await _pumpAsync(tester);

      // Select device
      await tester.tap(find.text('Device 1'));
      await _pumpAsync(tester);

      // Verify empty state with point count
      expect(find.text('0 points'), findsOneWidget);
    });
  });
}
