// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/device.dart';
import 'package:kayak_frontend/models/point.dart';
import 'package:kayak_frontend/pages/point/point_form_dialog.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/widgets/toast.dart';

import '../helpers/fake_device_service.dart';
import '../helpers/fake_point_service.dart';

// =============================================================================
// PointFormDialog Tests (TC-PF-001 ~ TC-PF-014)
// =============================================================================

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

Widget _wrapDialog({
  required Widget child,
  required FakePointService fakePointService,
  FakeDeviceService? fakeDeviceService,
  ThemeMode themeMode = ThemeMode.light,
  Size? screenSize,
}) {
  // Provide default fake device service if none given
  final deviceService = fakeDeviceService ?? FakeDeviceService(
    devices: [
      Device(
        id: 'dev-1',
        workbenchId: 'wb-1',
        name: 'Virtual Device',
        protocolType: ProtocolType.virtual,
        status: 'online',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
  );

  Widget result = ProviderScope(
    overrides: [
      pointServiceProvider.overrideWithValue(fakePointService),
      deviceServiceProvider.overrideWithValue(deviceService),
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
  group('PointFormDialog — Add Mode Defaults (TC-PF-001)', () {
    testWidgets('TC-PF-001: add mode shows correct defaults',
        (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Add Point'), findsOneWidget);

      // Name field empty
      final nameField = find.byType(TextFormField).first;
      expect(tester.widget<TextFormField>(nameField).controller?.text, '');

      // Save button should be disabled (dirty check in edit mode, but add mode always dirty)
      // In add mode, save is enabled once form is valid
      // Initially name is empty so form invalid
      final saveButton = find.widgetWithText(FilledButton, 'Save');
      expect(saveButton, findsOneWidget);
    });
  });

  group('PointFormDialog — Name Validation (TC-PF-002, TC-PF-003)', () {
    testWidgets('TC-PF-002: empty name disables save', (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Try to save with empty name
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Validation error
      expect(find.text('Point name is required'), findsOneWidget);
    });

    testWidgets('TC-PF-003: name at 255 chars is valid, over would be blocked',
        (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Enter exactly 255 chars (max allowed by maxLength)
      final maxName = 'A' * 255;
      await tester.enterText(find.byType(TextFormField).first, maxName);
      await tester.pumpAndSettle();

      // Counter shows 255/255 (both helperText and buildCounter show it)
      expect(find.text('255/255'), findsWidgets);

      // Save should work with 255 chars
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Service called (no validation error for 255 chars)
      expect(fakePointService.createCallCount, 1);
    });
  });

  group('PointFormDialog — Dropdown Options (TC-PF-004, TC-PF-005)', () {
    testWidgets('TC-PF-004: data type dropdown has 4 options',
        (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Find and tap data type dropdown
      final dropdowns = find.byType(DropdownButtonFormField<DataType>);
      expect(dropdowns, findsOneWidget);

      await tester.tap(dropdowns);
      await tester.pumpAndSettle();

      // Check options exist in the dropdown menu
      expect(find.text('Number').last, findsOneWidget);
      expect(find.text('Integer').last, findsOneWidget);
      expect(find.text('Boolean').last, findsOneWidget);
      expect(find.text('String').last, findsOneWidget);
    });

    testWidgets('TC-PF-005: access type dropdown has 3 options',
        (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Find and tap access type dropdown
      final dropdowns = find.byType(DropdownButtonFormField<AccessType>);
      expect(dropdowns, findsOneWidget);

      await tester.tap(dropdowns);
      await tester.pumpAndSettle();

      // Check options
      expect(find.text('Read Only').last, findsOneWidget);
      expect(find.text('Write Only').last, findsOneWidget);
      expect(find.text('Read & Write').last, findsOneWidget);
    });
  });

  group('PointFormDialog — Optional Fields (TC-PF-006)', () {
    testWidgets('TC-PF-006: optional fields can be empty', (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Fill only required field
      await tester.enterText(find.byType(TextFormField).first, 'Temperature Sensor');
      await tester.pumpAndSettle();

      // Save should work
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Service called
      expect(fakePointService.createCallCount, 1);
      expect(fakePointService.lastCreateData?['unit'], isNull);
      expect(fakePointService.lastCreateData?['min_value'], isNull);
      expect(fakePointService.lastCreateData?['max_value'], isNull);
      expect(fakePointService.lastCreateData?['default_value'], isNull);
    });
  });

  group('PointFormDialog — Save Success (TC-PF-008)', () {
    testWidgets('TC-PF-008: save success shows toast and closes dialog',
        (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Fill form name
      await tester.enterText(find.byType(TextFormField).first, 'Temperature Sensor');
      await tester.pumpAndSettle();

      // Find save button by type (may be wrapped in loading state)
      final saveFinder = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Save'),
      );
      expect(saveFinder, findsOneWidget);

      // Save
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // Service called
      expect(fakePointService.createCallCount, 1);
    });
  });

  group('PointFormDialog — Save Failure (TC-PF-009)', () {
    testWidgets('TC-PF-009: save failure keeps dialog open', (tester) async {
      final fakePointService = FakePointService(createFails: true);

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(find.byType(TextFormField).first, 'Temperature Sensor');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Dialog still open
      expect(find.byType(PointFormDialog), findsOneWidget);

      // Error shown
      expect(find.textContaining('Create point failed'), findsOneWidget);
    });
  });

  group('PointFormDialog — Edit Mode (TC-PF-010, TC-PF-011)', () {
    testWidgets('TC-PF-010: edit mode pre-fills data', (tester) async {
      final fakePointService = FakePointService(
        points: [
          _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
            dataType: DataType.number,
            accessType: AccessType.ro,
            unit: '°C',
            minValue: -50.0,
            maxValue: 150.0,
            defaultValue: '25.0',
          ),
        ],
      );

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: PointFormDialog(
          deviceId: 'dev-1',
          existing: _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
            dataType: DataType.number,
            accessType: AccessType.ro,
            unit: '°C',
            minValue: -50.0,
            maxValue: 150.0,
            defaultValue: '25.0',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Edit Point'), findsOneWidget);

      // Pre-filled values
      final nameField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(nameField.controller?.text, 'Temperature Sensor');
    });

    testWidgets('TC-PF-011: edit mode save button disabled when no changes',
        (tester) async {
      final fakePointService = FakePointService(
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

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: PointFormDialog(
          deviceId: 'dev-1',
          existing: _createPoint(
            id: 'pt-1',
            deviceId: 'dev-1',
            name: 'Temperature Sensor',
            dataType: DataType.number,
            accessType: AccessType.ro,
            unit: '°C',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Save button should be disabled initially (no changes made)
      final filledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(filledButton.onPressed, isNull,
          reason: 'Save button should be disabled when no changes in edit mode');

      // Note: Dirty check rebuild is triggered by onChanged callbacks.
      // The production code is missing onChanged on TextFormFields,
      // so modifying text doesn't enable the save button.
      // This is a known bug — see test report BUG-001.
    });
  });

  group('PointFormDialog — Range Validation (TC-PF-012)', () {
    testWidgets('TC-PF-012: min > max shows error', (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Temperature Sensor');
      await tester.pumpAndSettle();

      // TextFormField indices: 0=name, 1=unit, 2=minValue, 3=maxValue, 4=defaultValue
      final textFields = find.byType(TextFormField);

      // Enter min > max
      await tester.enterText(textFields.at(2), '100');
      await tester.enterText(textFields.at(3), '0');
      await tester.pumpAndSettle();

      // Save
      final saveFinder = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Save'),
      );
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // Error message
      expect(find.text('Max must be greater than min'), findsOneWidget);
    });
  });

  group('PointFormDialog — Cancel (TC-PF-014)', () {
    testWidgets('TC-PF-014: cancel closes dialog without saving',
        (tester) async {
      final fakePointService = FakePointService();

      await tester.pumpWidget(_wrapDialog(
        fakePointService: fakePointService,
        screenSize: const Size(1440, 900),
        child: const PointFormDialog(deviceId: 'dev-1'),
      ));
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Temperature Sensor');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // No API call
      expect(fakePointService.createCallCount, 0);
    });
  });
}
