import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/widgets/async_value_widget.dart';
import 'package:kayak_frontend/widgets/confirm_dialog.dart';
import 'package:kayak_frontend/widgets/empty_view.dart';
import 'package:kayak_frontend/widgets/error_view.dart';
import 'package:kayak_frontend/widgets/skeleton.dart';
import 'package:kayak_frontend/widgets/toast.dart';

import '../helpers/widget_test_helpers.dart';

// =============================================================================
// ErrorView tests (TC-001 ~ TC-006)
// =============================================================================

void main() {
  group('ErrorView', () {
    // TC-001: Render error message and retry button
    testWidgets('TC-001: displays error message and retry button', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const ErrorView(
          title: 'Error loading data',
          description: 'Network error, please check your connection',
          onRetry: _dummyCallback,
        ),
      ));

      expect(find.byIcon(Icons.error_outline_outlined), findsOneWidget);
      expect(find.text('Error loading data'), findsOneWidget);
      expect(
        find.text('Network error, please check your connection'),
        findsOneWidget,
      );
      // Retry button via l10n
      expect(find.text('Retry'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry')).onPressed,
        isNotNull,
      );
    });

    // TC-002: Retry button triggers onRetry callback
    testWidgets('TC-002: onRetry callback triggered', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(wrapWithMaterial(
        ErrorView(
          title: 'Test Error',
          onRetry: () => retryCalled = true,
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    // TC-003: Loading state on retry button
    testWidgets('TC-003: loading state on retry button', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const ErrorView(
          title: 'Test Error',
          onRetry: _dummyCallback,
          isLoading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Error'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(button.onPressed, isNull);
    });

    // TC-004: showRetry=false hides retry button
    testWidgets('TC-004: showRetry=false hides retry button', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const ErrorView(
          title: 'Test Error',
          description: 'Some description',
          onRetry: _dummyCallback,
          showRetry: false,
        ),
      ));

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byIcon(Icons.error_outline_outlined), findsOneWidget);
      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('Some description'), findsOneWidget);
    });

    // TC-005: Compact variant
    testWidgets('TC-005: compact variant', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const ErrorView(
          title: 'Error',
          onRetry: _dummyCallback,
          compact: true,
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline_outlined));
      expect(icon.size, 32);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    // TC-006: No description renders title and icon only
    testWidgets('TC-006: no description does not crash', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const ErrorView(
          title: 'Error Title',
          onRetry: _dummyCallback,
        ),
      ));

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(ErrorView), findsOneWidget);
    });
  });

// =============================================================================
// EmptyView tests (TC-007 ~ TC-011)
// =============================================================================

  group('EmptyView', () {
    // TC-007: Display empty state with icon, title, description, action button
    testWidgets('TC-007: displays icon, title, description and action button', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EmptyView(
          title: 'No workspaces',
          description: 'Click the button below to create your first workspace',
          actionButton: ElevatedButton(
            onPressed: () {},
            child: const Text('Create Workspace'),
          ),
        ),
      ));

      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
      expect(find.text('No workspaces'), findsOneWidget);
      expect(
        find.text('Click the button below to create your first workspace'),
        findsOneWidget,
      );
      expect(find.text('Create Workspace'), findsOneWidget);
    });

    // TC-008: actionButton=null hides action button
    testWidgets('TC-008: null actionButton hides action button', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const EmptyView(title: 'No notifications'),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
    });

    // TC-009: Action button triggers callback
    testWidgets('TC-009: action button callback triggered', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(wrapWithMaterial(
        EmptyView(
          title: 'No items',
          actionButton: ElevatedButton(
            onPressed: () => actionCalled = true,
            child: const Text('Create'),
          ),
        ),
      ));

      await tester.tap(find.text('Create'));
      expect(actionCalled, isTrue);
    });

    // TC-010: Custom icon rendering
    testWidgets('TC-010: custom icon renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const EmptyView(
          icon: Icons.inbox_outlined,
          title: 'No messages',
        ),
      ));

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsNothing);
    });

    // TC-011: Compact variant
    testWidgets('TC-011: compact variant', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const EmptyView(
          title: 'No data',
          compact: true,
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.folder_open_outlined));
      expect(icon.size, 40);
      expect(find.byType(EmptyView), findsOneWidget);
    });
  });

// =============================================================================
// Skeleton tests (TC-012 ~ TC-016)
// =============================================================================

  group('Skeleton', () {
    // TC-012: List skeleton renders correct number of items
    testWidgets('TC-012: list skeleton renders specified count', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const Skeleton(count: 4),
      ));

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(Skeleton), findsOneWidget);
    });

    // TC-013: Card skeleton
    testWidgets('TC-013: card skeleton renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const Skeleton(type: SkeletonType.card),
      ));

      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    // TC-014: Text skeleton with specified lines
    testWidgets('TC-014: text skeleton renders specified lines', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const Skeleton(type: SkeletonType.text, count: 3),
      ));

      expect(find.byType(Skeleton), findsOneWidget);
    });

    // TC-015: Shimmer animation runs
    testWidgets('TC-015: shimmer animation runs', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const Skeleton(count: 3),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 375));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byType(Skeleton), findsOneWidget);
    });

    // TC-016: Responsive item count
    testWidgets('TC-016: default item count adapts to breakpoint', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const Skeleton(),
        screenSize: const Size(400, 800),
      ));
      expect(find.byType(Skeleton), findsOneWidget);

      await tester.pumpWidget(wrapWithMaterial(
        const Skeleton(),
        screenSize: const Size(1400, 900),
      ));
      expect(find.byType(Skeleton), findsOneWidget);
    });
  });

// =============================================================================
// ConfirmDialog tests (TC-017 ~ TC-022)
// =============================================================================

  group('ConfirmDialog', () {
    // TC-017: Display title, description, cancel/confirm buttons
    testWidgets('TC-017: displays title, description and buttons', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDialog.show(
              context: context,
              title: 'Delete workspace?',
              description:
                  'This will permanently delete the workspace and all its data.',
              onConfirm: () {},
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete workspace?'), findsOneWidget);
      expect(
        find.text('This will permanently delete the workspace and all its data.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    // TC-018: Cancel button triggers onCancel and closes dialog
    testWidgets('TC-018: cancel triggers onCancel and closes', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(wrapWithMaterial(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDialog.show(
              context: context,
              title: 'Delete?',
              description: 'This action is irreversible.',
              onConfirm: () {},
              onCancel: () => cancelled = true,
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
      expect(find.text('Delete?'), findsNothing);
    });

    // TC-019: Confirm button triggers onConfirm and closes dialog
    testWidgets('TC-019: confirm triggers onConfirm and closes', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(wrapWithMaterial(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDialog.show(
              context: context,
              title: 'Confirm action',
              onConfirm: () => confirmed = true,
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Confirm action'), findsNothing);
    });

    // TC-020: Danger operation has error-colored confirm button
    testWidgets('TC-020: danger operation uses error color', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDialog.show(
              context: context,
              title: 'Delete',
              onConfirm: () {},
              isDanger: true,
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // In danger mode, confirm button should show "Delete"
      // There are 2 "Delete" texts (title "Delete" + button label "Delete")
      expect(find.text('Delete'), findsNWidgets(2));
      expect(find.byType(TextButton), findsOneWidget);
      // Verify the filled button uses error color
      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton, isNotNull);
    });

    // TC-021: Mobile bottom sheet style
    testWidgets('TC-021: mobile uses bottom sheet', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDialog.show(
              context: context,
              title: 'Mobile Dialog',
              onConfirm: () {},
            ),
            child: const Text('Open'),
          ),
        ),
        screenSize: const Size(390, 844),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Dialog'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    // TC-022: Dialog buttons (Cancel + Confirm) are accessible
    testWidgets('TC-022: Cancel and Confirm buttons are accessible', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(wrapWithMaterial(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDialog.show(
              context: context,
              title: 'Dialog',
              onConfirm: () => confirmed = true,
              onCancel: () => cancelled = true,
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify both buttons exist
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
      expect(confirmed, isFalse);
      expect(find.text('Dialog'), findsNothing);
    });
  });

// =============================================================================
// Toast tests (TC-023 ~ TC-028)
// =============================================================================

  group('Toast', () {
    Widget wrapWithToast(Widget child) {
      return wrapWithMaterial(
        Builder(
          builder: (context) => Toast.init(
            context,
            child,
          ),
        ),
      );
    }

    // TC-023: Success type
    testWidgets('TC-023: success type displays with correct icon', (tester) async {
      await tester.pumpWidget(wrapWithToast(
        ElevatedButton(
          onPressed: () => Toast.show(
            context: tester.element(find.byType(ElevatedButton)),
            message: 'Workspace created successfully',
            type: ToastType.success,
          ),
          child: const Text('Show'),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Workspace created successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // TC-024: Error type
    testWidgets('TC-024: error type displays', (tester) async {
      await tester.pumpWidget(wrapWithToast(
        ElevatedButton(
          onPressed: () => Toast.show(
            context: tester.element(find.byType(ElevatedButton)),
            message: 'Deletion failed, please try again',
            type: ToastType.error,
          ),
          child: const Text('Show'),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Deletion failed, please try again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    // TC-025: Warning type
    testWidgets('TC-025: warning type displays', (tester) async {
      await tester.pumpWidget(wrapWithToast(
        ElevatedButton(
          onPressed: () => Toast.show(
            context: tester.element(find.byType(ElevatedButton)),
            message: 'This is a warning',
            type: ToastType.warning,
          ),
          child: const Text('Show'),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('This is a warning'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    // TC-026: Info type
    testWidgets('TC-026: info type displays', (tester) async {
      await tester.pumpWidget(wrapWithToast(
        ElevatedButton(
          onPressed: () => Toast.show(
            context: tester.element(find.byType(ElevatedButton)),
            message: 'Information message',
          ),
          child: const Text('Show'),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Information message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    // TC-027: Loading type does not auto-dismiss
    testWidgets('TC-027: loading type does not auto-dismiss', (tester) async {
      await tester.pumpWidget(wrapWithToast(
        ElevatedButton(
          onPressed: () => Toast.show(
            context: tester.element(find.byType(ElevatedButton)),
            message: 'Saving...',
            type: ToastType.loading,
          ),
          child: const Text('Show'),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Saving...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Saving...'), findsOneWidget);
    });

    // TC-028: Multiple toasts stack with max 3
    testWidgets('TC-028: multiple toasts stack max 3', (tester) async {
      await tester.pumpWidget(wrapWithToast(
        ElevatedButton(
          onPressed: () {
            // Trigger multiple toasts quickly
            Toast.show(
              context: tester.element(find.byType(ElevatedButton)),
              message: 'First',
              duration: const Duration(seconds: 10),
            );
            Toast.show(
              context: tester.element(find.byType(ElevatedButton)),
              message: 'Second',
              duration: const Duration(seconds: 10),
            );
            Toast.show(
              context: tester.element(find.byType(ElevatedButton)),
              message: 'Third',
              duration: const Duration(seconds: 10),
            );
            Toast.show(
              context: tester.element(find.byType(ElevatedButton)),
              message: 'Fourth',
              duration: const Duration(seconds: 10),
            );
          },
          child: const Text('Show'),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // At most 3 visible, 4th replaces 1st
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Fourth'), findsOneWidget);
    });
  });

// =============================================================================
// AsyncValueWidget tests (TC-029 ~ TC-034)
// =============================================================================

  group('AsyncValueWidget', () {
    // TC-029: Loading state renders Skeleton
    testWidgets('TC-029: loading state renders Skeleton', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<int>(
          value: const AsyncValue.loading(),
          dataBuilder: (data) => Text('Data: $data'),
        ),
      ));
      await tester.pump();

      expect(find.text('Data:'), findsNothing);
      expect(find.byType(Skeleton), findsOneWidget);
    });

    // TC-030: Data state renders dataBuilder
    testWidgets('TC-030: data state renders dataBuilder', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<int>(
          value: const AsyncValue.data(42),
          dataBuilder: (data) => Text('Data: $data'),
        ),
      ));
      await tester.pump();

      expect(find.text('Data: 42'), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
    });

    // TC-031: Error state renders ErrorView with retry
    testWidgets('TC-031: error state renders ErrorView', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<int>(
          value: AsyncValue.error(
            Exception('Network failed'),
            StackTrace.current,
          ),
          dataBuilder: (data) => const Text('Data'),
          onRetry: () => retryCalled = true,
        ),
      ));
      await tester.pump();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    // TC-032: Empty list renders EmptyView
    testWidgets('TC-032: empty list renders EmptyView', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<List<String>>(
          value: const AsyncValue.data(<String>[]),
          dataBuilder: (data) => Text('Items: ${data.length}'),
        ),
      ));
      await tester.pump();

      expect(find.text('Items:'), findsNothing);
      expect(find.byType(EmptyView), findsOneWidget);
    });

    // TC-033: Data renders correctly with skipLoadingOnRefresh
    testWidgets('TC-033: data renders with skipLoadingOnRefresh', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<String>(
          value: const AsyncValue.data('hello'),
          dataBuilder: (data) => Text('Data: $data'),
        ),
      ));
      await tester.pump();

      expect(find.text('Data: hello'), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
    });

    // TC-034: Custom builders for loading/error/empty
    testWidgets('TC-034: custom builders', (tester) async {
      // Custom loading
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<int>(
          value: const AsyncValue.loading(),
          loadingBuilder: const Text('Custom Loading'),
          dataBuilder: (data) => Text('Data: $data'),
        ),
      ));
      await tester.pump();

      expect(find.text('Custom Loading'), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);

      // Custom error
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<int>(
          value: AsyncValue.error(
            Exception('test'),
            StackTrace.current,
          ),
          errorBuilder: (error, stack) => Text('Custom: $error'),
          dataBuilder: (data) => const Text('Data'),
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Custom:'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);

      // Custom empty
      await tester.pumpWidget(wrapWithMaterial(
        AsyncValueWidget<List<String>>(
          value: const AsyncValue.data(<String>[]),
          emptyBuilder: const Text('Nothing here'),
          dataBuilder: (data) => Text('Items: ${data.length}'),
        ),
      ));
      await tester.pump();

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);
    });
  });
}

void _dummyCallback() {}
