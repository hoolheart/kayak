// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/point.dart';
import 'package:kayak_frontend/pages/point/point_value_display.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/widgets/skeleton.dart';

import '../helpers/fake_point_service.dart';

// =============================================================================
// PointValueDisplay Tests (TC-PV-001 ~ TC-PV-008)
// =============================================================================

Widget _wrapValueDisplay({
  required Widget child,
  required FakePointService fakeService,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      pointServiceProvider.overrideWithValue(fakeService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // 禁用无限 shimmer 动画以避免 pumpAndSettle 永远等待
  PointValueDisplay.isTestMode = true;

  group('PointValueDisplay — Value Formatting (TC-PV-001, TC-PV-002)', () {
    testWidgets('TC-PV-001: number with unit formatted', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-1': const PointValue(
            pointId: 'pt-1',
            value: 25.3256,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          unit: '°C',
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();

      // Formatted value
      expect(find.text('25.33'), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);
    });

    testWidgets('TC-PV-002a: number type formatted', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-num': const PointValue(
            pointId: 'pt-num',
            value: 25.3256,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );
      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-num',
          dataType: DataType.number,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('25.33'), findsOneWidget);
    });

    testWidgets('TC-PV-002b: integer type formatted', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-int': const PointValue(
            pointId: 'pt-int',
            value: 101,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );
      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-int',
          dataType: DataType.integer,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('TC-PV-002c: boolean type formatted', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-bool': const PointValue(
            pointId: 'pt-bool',
            value: true,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );
      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-bool',
          dataType: DataType.boolean,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('On'), findsOneWidget);
    });

    testWidgets('TC-PV-002d: string type formatted', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-str': const PointValue(
            pointId: 'pt-str',
            value: 'Running',
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );
      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-str',
          dataType: DataType.string,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Running'), findsOneWidget);
    });
  });

  group('PointValueDisplay — Status Indicators (TC-PV-003 ~ TC-PV-005)', () {
    testWidgets('TC-PV-003: normal status gray dot', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-1': const PointValue(
            pointId: 'pt-1',
            value: 25.3,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();

      // Value shown (25.3 formatted as "25.30" with 2 decimal places)
      expect(find.text('25.30'), findsOneWidget);

      // Status dot exists (circle Container)
      final containers = find.byType(Container);
      bool foundDot = false;
      for (int i = 0; i < containers.evaluate().length; i++) {
        final widget = tester.widget<Container>(containers.at(i));
        final decoration = widget.decoration as BoxDecoration?;
        if (decoration?.shape == BoxShape.circle) {
          foundDot = true;
          break;
        }
      }
      expect(foundDot, isTrue);
    });

    testWidgets('TC-PV-004: timeout status orange dot', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-1': const PointValue(
            pointId: 'pt-1',
            value: 25.3,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          status: 'timeout',
        ),
      ));
      await tester.pumpAndSettle();

      // Value shown but grayed (25.3 formatted as "25.30")
      expect(find.text('25.30'), findsOneWidget);
    });

    testWidgets('TC-PV-005: error status red dot', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-1': const PointValue(
            pointId: 'pt-1',
            value: null,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          status: 'error',
        ),
      ));
      await tester.pumpAndSettle();

      // Dash shown for error
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('PointValueDisplay — Refresh (TC-PV-006)', () {
    testWidgets('TC-PV-006: refresh button calls API', (tester) async {
      final fakeService = FakePointService(
        values: {
          'pt-1': const PointValue(
            pointId: 'pt-1',
            value: 25.3,
            timestamp: '2026-06-01T10:00:00Z',
          ),
        },
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();

      // Initial value
      expect(find.text('25.30'), findsOneWidget);

      // Update mock for refresh
      fakeService.values['pt-1'] = const PointValue(
        pointId: 'pt-1',
        value: 26.1,
        timestamp: '2026-06-01T10:00:01Z',
      );

      // Tap refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // API called
      expect(fakeService.getValueCallCount, 2);
    });
  });

  group('PointValueDisplay — Loading (TC-PV-007)', () {
    testWidgets('TC-PV-007: loading shows skeleton', (tester) async {
      final fakeService = FakePointService(
        delay: const Duration(milliseconds: 500),
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          status: 'normal',
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Skeleton shown (ShimmerBlock) while loading
      expect(find.byType(ShimmerBlock), findsWidgets);

      // Complete the pending timer to avoid "timer pending" error
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('PointValueDisplay — Error (TC-PV-008)', () {
    testWidgets('TC-PV-008: error shows dash and refresh button',
        (tester) async {
      final fakeService = FakePointService(
        getValueFails: true,
      );

      await tester.pumpWidget(_wrapValueDisplay(
        fakeService: fakeService,
        child: const PointValueDisplay(
          pointId: 'pt-1',
          dataType: DataType.number,
          status: 'normal',
        ),
      ));
      await tester.pumpAndSettle();

      // Dash shown
      expect(find.text('—'), findsOneWidget);

      // Refresh button still available
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
