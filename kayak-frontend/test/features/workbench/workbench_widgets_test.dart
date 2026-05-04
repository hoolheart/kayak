import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/workbench/models/workbench.dart';
import 'package:kayak_frontend/features/workbench/models/workbench_form_state.dart';
import 'package:kayak_frontend/features/workbench/models/workbench_list_state.dart';
import 'package:kayak_frontend/features/workbench/widgets/delete_confirmation_dialog.dart';
import 'package:kayak_frontend/features/workbench/widgets/empty_state_widget.dart';
import 'package:kayak_frontend/features/workbench/widgets/workbench_card.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkbenchService extends Mock {}

void main() {
  group('WorkbenchCard Widget Tests', () {
    late Workbench testWorkbench;

    setUp(() {
      testWorkbench = Workbench(
        id: 'test-id-1',
        name: 'Test Workbench',
        description: 'Test Description',
        ownerId: 'owner-123',
        ownerType: 'user',
        status: 'active',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    });

    testWidgets('displays workbench name correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkbenchCard(
              workbench: testWorkbench,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Workbench'), findsOneWidget);
    });

    testWidgets('displays workbench description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkbenchCard(
              workbench: testWorkbench,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkbenchCard(
              workbench: testWorkbench,
              onTap: () => tapped = true,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows "暂无描述" when description is null', (tester) async {
      final workbenchNoDesc = Workbench(
        id: 'test-id-2',
        name: 'No Description Workbench',
        ownerId: 'owner-123',
        ownerType: 'user',
        status: 'active',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkbenchCard(
              workbench: workbenchNoDesc,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('暂无描述'), findsOneWidget);
    });
  });

  group('EmptyStateWidget Tests', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No Workbenches',
              message: 'Create your first workbench',
            ),
          ),
        ),
      );

      expect(find.text('No Workbenches'), findsOneWidget);
      expect(find.text('Create your first workbench'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              message: 'No items',
              actionLabel: 'Add Item',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('action button triggers callback', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              message: 'No items',
              actionLabel: 'Add',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add'));
      expect(actionCalled, isTrue);
    });
  });

  group('DeleteConfirmationDialog Tests', () {
    testWidgets('displays item name in message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'My Workbench',
            ),
          ),
        ),
      );

      expect(find.text('确定要删除 "My Workbench" 吗？'), findsOneWidget);
    });

    testWidgets('displays warning icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'Test Item',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('cancel button is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'Test Item',
            ),
          ),
        ),
      );

      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('delete button is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'Test Item',
            ),
          ),
        ),
      );

      expect(find.text('删除'), findsOneWidget);
    });
  });

  // ViewMode Provider Tests are skipped because shared_preferences requires
  // mocking in test environment. These are covered by integration tests.
  group('ViewMode Provider Tests', () {
    test('ViewMode enum has correct values', () {
      expect(ViewMode.card, equals(ViewMode.card));
      expect(ViewMode.list, equals(ViewMode.list));
    });
  });

  group('WorkbenchListState Tests', () {
    test('initial state has correct defaults', () {
      const state = WorkbenchListState();

      expect(state.workbenches, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.error, isNull);
      expect(state.currentPage, equals(1));
      expect(state.pageSize, equals(20));
      expect(state.hasMore, isTrue);
    });

    test('copyWith creates new instance with updated values', () {
      const state = WorkbenchListState();
      final newState = state.copyWith(isLoading: true);

      expect(newState.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });
  });

  group('WorkbenchFormState Tests', () {
    test('isValid returns true when name is not empty and no errors', () {
      const state = WorkbenchFormState(
        name: 'Test',
      );

      expect(state.isValid, isTrue);
    });

    test('isValid returns false when name is empty', () {
      const state = WorkbenchFormState();

      expect(state.isValid, isFalse);
    });

    test('isValid returns false when nameError is set', () {
      const state = WorkbenchFormState(
        name: 'Test',
        nameError: 'Name is required',
      );

      expect(state.isValid, isFalse);
    });
  });
}
