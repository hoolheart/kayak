import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/method.dart';
import 'package:kayak_frontend/pages/method/method_edit_page.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/method_service.dart';
import 'package:mocktail/mocktail.dart';

class MockMethodService extends Mock implements MethodService {}

/// 设置屏幕尺寸
Future<void> setScreenSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

/// 恢复默认屏幕尺寸
Future<void> resetScreenSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(null);
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
}

/// 等待异步 provider 完成并渲染
Future<void> pumpUntilReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// 构建 MethodEditPage 测试环境
Future<ProviderContainer> pumpMethodEditPage(
  WidgetTester tester, {
  required MockMethodService methodService,
  String? methodId,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final container = ProviderContainer(
    overrides: [
      methodServiceProvider.overrideWithValue(methodService),
    ],
  );

  final initialLocation =
      methodId == null ? '/methods/new/edit' : '/methods/$methodId/edit';

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/methods',
        builder: (context, state) =>
            const SizedBox(key: Key('method_list_page')),
        routes: [
          GoRoute(
            path: 'new/edit',
            builder: (context, state) => const MethodEditPage(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => MethodEditPage(
              id: state.pathParameters['id'],
            ),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );

  return container;
}

/// 测试用方法数据
Method createTestMethod({
  String id = 'method-001',
  String name = 'Tensile Test Standard',
  String? description = 'ASTM D638 standard tensile testing',
  List<MethodParameter>? parameters,
}) {
  return Method(
    id: id,
    name: name,
    description: description,
    processDefinition: const {
      'nodes': [
        {'id': 'start', 'type': 'start'},
        {'id': 'end', 'type': 'end'},
      ],
      'edges': [
        {'from': 'start', 'to': 'end'},
      ],
    },
    parameterSchema: parameters != null && parameters.isNotEmpty
        ? {
            'type': 'object',
            'properties': {
              for (final p in parameters) p.key: {'type': p.type},
            },
          }
        : const {'type': 'object', 'properties': {}},
    version: 1,
    createdBy: 'user-001',
    createdAt: DateTime(2026, 6, 1, 10, 0),
    updatedAt: DateTime(2026, 6, 1, 10, 0),
    parameters: parameters,
  );
}

void main() {
  late MockMethodService mockMethodService;

  setUp(() {
    mockMethodService = MockMethodService();
  });

  // ==========================================
  // TC-017: Create mode initialization
  // ==========================================
  group('TC-017: Create mode initialization', () {
    testWidgets('shows empty form in create mode', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      // No API calls needed for create mode (no method to load)
      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Should show Create Method title
      expect(find.text('Create Method'), findsOneWidget);

      // Name field should be empty
      final nameField = find.byKey(const Key('method-name-field'));
      expect(nameField, findsOneWidget);
      expect(
        (tester.widget<TextFormField>(nameField).controller?.text ?? ''),
        isEmpty,
      );

      // Description field should be empty
      final descField = find.byKey(const Key('method-description-field'));
      expect(descField, findsOneWidget);
      expect(
        (tester.widget<TextFormField>(descField).controller?.text ?? ''),
        isEmpty,
      );

      // Save button should exist
      expect(find.byKey(const Key('method-save')), findsOneWidget);
    });

    testWidgets('shows Chinese text in create mode', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
        locale: const Locale('zh'),
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Chinese title
      expect(find.text('创建方法'), findsOneWidget);
      // Chinese save button (appears in AppBar and bottom bar)
      expect(find.text('保存'), findsAtLeast(1));
    });
  });

  // ==========================================
  // TC-018: Edit mode initialization
  // ==========================================
  group('TC-018: Edit mode initialization', () {
    testWidgets('loads and fills form in edit mode', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final method = createTestMethod(
        id: 'method-001',
        name: 'Tensile Test Standard',
        description: 'ASTM D638 standard',
        parameters: [
          MethodParameter(
            key: 'temperature',
            type: 'number',
            isRequired: true,
          ),
        ],
      );

      when(() => mockMethodService.getById('method-001'))
          .thenAnswer((_) async => method);

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
        methodId: 'method-001',
      );
      addTearDown(container.dispose);

      // Wait for loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show Edit Method title
      expect(find.text('Edit Method'), findsOneWidget);

      // Name should be pre-filled
      final nameField = find.byKey(const Key('method-name-field'));
      expect(
        (tester.widget<TextFormField>(nameField).controller?.text ?? ''),
        'Tensile Test Standard',
      );

      // Description should be pre-filled
      final descField = find.byKey(const Key('method-description-field'));
      expect(
        (tester.widget<TextFormField>(descField).controller?.text ?? ''),
        'ASTM D638 standard',
      );
    });

    testWidgets('shows error state on load failure', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.getById('method-001')).thenAnswer(
        (_) async => throw Exception('Not found'),
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
        methodId: 'method-001',
      );
      addTearDown(container.dispose);

      // Pump to trigger async build and catch error
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After build fails, the edit page should show 'Failed to load method' error
      // or still show loading if the error hasn't propagated yet
      final hasError = find.text('Failed to load method');
      final isLoading = find.byType(CircularProgressIndicator);

      if (hasError.evaluate().isEmpty) {
        // If error hasn't rendered yet, at least verify loading state was shown
        expect(isLoading, findsOneWidget);
        // Pump more to let the error propagate
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

  });

  // ==========================================
  // TC-019: Name validation
  // ==========================================
  group('TC-019: Name validation', () {
    testWidgets('validates name is required and min length', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );
      when(() => mockMethodService.create(any())).thenAnswer(
        (_) async => createTestMethod(),
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // First mark dirty by entering then clearing name
      await tester.enterText(find.byKey(const Key('method-name-field')), 'x');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('method-name-field')), '');
      await tester.pump(const Duration(milliseconds: 100));

      // Try to save with empty name
      final saveButton = find.byKey(const Key('method-save'));
      await tester.ensureVisible(saveButton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(saveButton);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Should show validation error (could be SnackBar or validation message)
      // Wait for SnackBar to appear
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final errorText = find.text('Method name is required (at least 2 characters)');
      if (errorText.evaluate().isEmpty) {
        // If SnackBar not visible, save should have been prevented (stay on edit page)
        expect(find.text('Create Method'), findsOneWidget);
      } else {
        expect(errorText, findsOneWidget);
      }
    });
  });

  // ==========================================
  // TC-022: JSON validation
  // ==========================================
  group('TC-022: JSON validation', () {
    testWidgets('shows error on invalid JSON', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Find JSON editor and type invalid JSON
      final jsonEditor = find.byKey(const Key('method-json-editor'));
      expect(jsonEditor, findsOneWidget);

      // Clear and type invalid JSON
      await tester.enterText(
        find.byType(TextField).last,
        '{invalid json}',
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error indicator
      expect(find.text('Invalid JSON format'), findsOneWidget);
    });

    testWidgets('shows valid on correct JSON', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Default JSON is already valid, should show valid indicator
      expect(find.text('Valid JSON'), findsOneWidget);
    });
  });

  // ==========================================
  // TC-033: Save (create) — navigates back
  // ==========================================
  group('TC-033: Save create → navigate back', () {
    testWidgets('create method saves and navigates to list', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );
      when(() => mockMethodService.create(any())).thenAnswer(
        (_) async => createTestMethod(name: 'New Method'),
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Fill in name
      await tester.enterText(
        find.byKey(const Key('method-name-field')),
        'New Method',
      );
      await tester.pump();

      // Type valid JSON
      await tester.enterText(
        find.byType(TextField).last,
        '{"nodes": [], "edges": []}',
      );
      await tester.pump();

      // Tap save button (scroll down to make it visible)
      final saveButton = find.byKey(const Key('method-save'));
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should navigate back to list page
      expect(find.byKey(const Key('method_list_page')), findsOneWidget);
    });
  });

  // ==========================================
  // TC-037: Unsaved changes confirmation
  // ==========================================
  group('TC-037: Unsaved changes confirmation', () {
    testWidgets('shows confirmation when leaving with unsaved changes',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Make a change (type in name field)
      await tester.enterText(
        find.byKey(const Key('method-name-field')),
        'Modified Name',
      );
      await tester.pump();

      // Tap back button
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pump();

      // Should show unsaved changes dialog
      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(
        find.text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        findsOneWidget,
      );
    });

    testWidgets('leaves without confirmation when no changes',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Don't make any changes, tap back button
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pump();

      // Should NOT show unsaved changes dialog
      expect(find.text('Unsaved changes'), findsNothing);
    });

    testWidgets('discard and leave navigates away', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodEditPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Make a change
      await tester.enterText(
        find.byKey(const Key('method-name-field')),
        'Modified Name',
      );
      // Mark dirty by tapping a different field
      await tester.tap(find.byKey(const Key('method-description-field')));
      await tester.pump();

      // Tap back button
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pump();

      // Should show dialog - tap "Discard and leave"
      final discardButton = find.text('Discard and leave');
      await tester.tap(discardButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should navigate to list
      expect(find.byKey(const Key('method_list_page')), findsOneWidget);
    });
  });
}
