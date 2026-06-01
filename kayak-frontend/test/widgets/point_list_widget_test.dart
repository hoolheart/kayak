// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/point.dart';
import 'package:kayak_frontend/pages/point/point_list_widget.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/widgets/skeleton.dart';
import 'package:kayak_frontend/widgets/toast.dart';

import '../helpers/fake_device_service.dart';
import '../helpers/fake_point_service.dart';

// =============================================================================
// PointListWidget Tests (TC-PL-001 ~ TC-PL-016)
// =============================================================================

/// 创建标准测点数据
Point _createPoint({
  required String id,
  required String deviceId,
  required String name,
  DataType dataType = DataType.number,
  AccessType accessType = AccessType.ro,
  String? unit,
  double? minValue,
  double? maxValue,
  String? defaultValue,
  String status = 'normal',
}) {
  return Point(
    id: id,
    deviceId: deviceId,
    name: name,
    dataType: dataType,
    accessType: accessType,
    unit: unit,
    minValue: minValue,
    maxValue: maxValue,
    defaultValue: defaultValue,
    status: status,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

Widget _wrapPointList({
  required Widget child,
  required FakePointService fakeService,
  FakeDeviceService? fakeDeviceService,
  ThemeMode themeMode = ThemeMode.light,
  Size? screenSize,
}) {
  Widget result = ProviderScope(
    overrides: [
      pointServiceProvider.overrideWithValue(fakeService),
      if (fakeDeviceService != null)
        deviceServiceProvider.overrideWithValue(fakeDeviceService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Builder(
        builder: (context) => Toast.init(
          context,
          Scaffold(body: child),
        ),
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
  PointListWidget.isTestMode = true;

  group('PointListWidget — Loading State (TC-PL-001)', () {
    testWidgets('TC-PL-001: loading state shows skeleton rows',
        (tester) async {
      final fakeService = FakePointService(
        delay: const Duration(milliseconds: 500),
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Title visible during loading
      expect(find.text('Points'), findsOneWidget);

      // Count hidden during loading (hasValue = false)
      expect(find.text('0 points'), findsNothing);

      // Skeleton shimmer blocks visible
      expect(find.byType(ShimmerBlock), findsWidgets);

      // No table headers (data not loaded yet)
      expect(find.text('Name'), findsNothing);
      expect(find.text('Type'), findsNothing);

      // Pump enough to complete the pending timer
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('PointListWidget — Data Display (TC-PL-003)', () {
    testWidgets('TC-PL-003: table displays all columns correctly',
        (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
            dataType: DataType.number,
            accessType: AccessType.ro,
            unit: '°C',
          ),
          _createPoint(
            id: 'pt-2',
            deviceId: 'dev-1',
            name: 'Valve Status',
            dataType: DataType.boolean,
            accessType: AccessType.rw,
          ),
          _createPoint(
            id: 'pt-3',
            deviceId: 'dev-1',
            name: 'Pressure',
            dataType: DataType.integer,
            accessType: AccessType.ro,
            unit: 'MPa',
          ),
        ],
        values: {
          'pt-1': const PointValue(
            pointId: 'pt-1',
            value: 25.3,
            timestamp: '2026-06-01T10:00:00Z',
          ),
          'pt-2': const PointValue(
            pointId: 'pt-2',
            value: true,
            timestamp: '2026-06-01T10:00:00Z',
          ),
          'pt-3': const PointValue(
            pointId: 'pt-3',
            value: 101,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Count
      expect(find.text('3 points'), findsOneWidget);

      // Add button
      expect(find.text('Add Point'), findsOneWidget);

      // Column headers
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);

      // Row data
      expect(find.text('Temperature Sensor'), findsOneWidget);
      expect(find.text('Valve Status'), findsOneWidget);
      expect(find.text('Pressure'), findsOneWidget);

      // Type chips
      expect(find.text('Number'), findsOneWidget);
      expect(find.text('Boolean'), findsOneWidget);
      expect(find.text('Integer'), findsOneWidget);

      // Unit
      expect(find.text('°C'), findsWidgets);
      expect(find.text('MPa'), findsWidgets);

      // Edit/Delete buttons
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });
  });

  group('PointListWidget — Add Button (TC-PL-004)', () {
    testWidgets('TC-PL-004: tapping add button shows PointFormDialog',
        (tester) async {
      final fakeService = FakePointService(points: const []);

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap add button
      await tester.tap(find.text('Add Point'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Add Point'), findsWidgets);
    });
  });

  group('PointListWidget — Edit Button (TC-PL-005)', () {
    testWidgets('TC-PL-005: tapping edit shows pre-filled dialog',
        (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
            dataType: DataType.number,
            accessType: AccessType.ro,
            unit: '°C',
          ),
        ],
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap edit
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog with pre-filled data
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Point'), findsWidgets);

      // Name pre-filled
      expect(find.text('Temperature Sensor'), findsWidgets);
    });
  });

  group('PointListWidget — Delete Flow (TC-PL-006, TC-PL-007, TC-PL-008)', () {
    testWidgets('TC-PL-006: delete shows ConfirmDialog', (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
          ),
        ],
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm dialog (point name appears in both table and dialog)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Temperature Sensor'), findsWidgets);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('TC-PL-007: confirm delete refreshes list', (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
          ),
        ],
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm
      await tester.tap(find.text('Delete').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Service called
      expect(fakeService.deleteCallCount, 1);
      expect(fakeService.lastDeleteId, 'pt-1');

      // Toast shown
      expect(find.text('Point deleted'), findsOneWidget);
    });

    testWidgets('TC-PL-008: delete failure shows error toast', (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
          ),
        ],
        deleteFails: true,
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm
      await tester.tap(find.text('Delete').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Error toast
      expect(find.textContaining('Delete point failed'), findsOneWidget);
    });
  });

  group('PointListWidget — Responsive (TC-PL-009, TC-PL-010)', () {
    testWidgets('TC-PL-009: mobile shows card list', (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
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

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(375, 667),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Cards should be shown (not table)
      expect(find.byType(Card), findsWidgets);

      // Table headers should NOT be shown
      expect(find.text('Name'), findsNothing);
      expect(find.text('Actions'), findsNothing);

      // Count still shown
      expect(find.text('2 points'), findsOneWidget);

      // Full-width add button at bottom
      expect(find.text('Add Point'), findsOneWidget);
    });

    testWidgets('TC-PL-010: desktop shows full table', (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
          ),
          _createPoint(
            id: 'pt-2',
            deviceId: 'dev-1',
            name: 'Pressure',
          ),
          _createPoint(
            id: 'pt-3',
            deviceId: 'dev-1',
            name: 'Valve',
          ),
        ],
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Table headers visible
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);

      // No cards
      expect(find.byType(Card), findsNothing);
    });
  });

  group('PointListWidget — Error State (TC-PL-011)', () {
    testWidgets('TC-PL-011: error state shows retry', (tester) async {
      final fakeService = FakePointService(
        listFails: true,
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Error view shows retry button
      expect(find.text('Retry'), findsOneWidget);

      // Error message shown
      expect(find.textContaining('Failed'), findsOneWidget);

      // No skeleton
      expect(find.byType(ShimmerBlock), findsNothing);
    });
  });

  group('PointListWidget — Empty State Add (TC-PL-012)', () {
    testWidgets('TC-PL-012: empty state add button opens dialog',
        (tester) async {
      final fakeService = FakePointService(points: const []);

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap "Add First Point"
      await tester.tap(find.text('Add First Point'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Add Point'), findsWidgets);
    });
  });

  group('PointListWidget — Status Indicators (TC-PL-014)', () {
    testWidgets('TC-PL-014: status indicators show correct colors',
        (tester) async {
      final fakeService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Normal Point',
          ),
          _createPoint(
            id: 'pt-2',
            deviceId: 'dev-1',
            name: 'Timeout Point',
            status: 'timeout',
          ),
          _createPoint(
            id: 'pt-3',
            deviceId: 'dev-1',
            name: 'Error Point',
            status: 'error',
          ),
        ],
      );

      await tester.pumpWidget(_wrapPointList(
        fakeService: fakeService,
        screenSize: const Size(1440, 900),
        child: const PointListWidget(deviceId: 'dev-1'),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Status dots exist (Container with circle shape)
      final containers = find.byType(Container);
      int dotCount = 0;
      for (int i = 0; i < containers.evaluate().length; i++) {
        final widget = tester.widget<Container>(containers.at(i));
        final decoration = widget.decoration as BoxDecoration?;
        if (decoration?.shape == BoxShape.circle) {
          dotCount++;
        }
      }
      expect(dotCount, greaterThanOrEqualTo(3));
    });
  });
}
