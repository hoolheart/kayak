/// Team list page tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/team/models/team_models.dart';
import 'package:kayak_frontend/features/team/providers/team_providers.dart';
import 'package:kayak_frontend/features/team/screens/team_list_page.dart';
import 'package:kayak_frontend/features/team/widgets/empty_team_list_state.dart';
import 'package:kayak_frontend/features/team/widgets/team_card.dart';
import 'package:kayak_frontend/features/team/widgets/team_error_state.dart';

import 'helpers/team_test_data.dart';

void main() {
  group('TeamListPage', () {
    testWidgets('renders team cards when data is loaded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith((ref) async => mockTeams),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('团队管理'), findsOneWidget);
      expect(find.byType(TeamCard), findsNWidgets(3));
      expect(find.text('研发团队'), findsOneWidget);
      expect(find.text('QA 测试团队'), findsOneWidget);
      expect(find.text('产品团队'), findsOneWidget);
    });

    testWidgets('renders empty state when no teams',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith((ref) async => <Team>[]),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyTeamListState), findsOneWidget);
      expect(find.text('暂无团队'), findsOneWidget);
      expect(find.byType(TeamCard), findsNothing);
    });

    testWidgets('renders error state on error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith(
              (ref) async => throw Exception('网络连接失败'),
            ),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeamErrorState), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.byType(TeamCard), findsNothing);
    });

    testWidgets('renders loading state', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              teamsProvider.overrideWith(
                (ref) async {
                  await Future.delayed(const Duration(milliseconds: 50));
                  return mockTeams;
                },
              ),
            ],
            child: const MaterialApp(
              home: TeamListPage(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('create team button opens dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith((ref) async => mockTeams),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '创建团队'));
      await tester.pumpAndSettle();

      expect(find.text('创建团队'), findsWidgets);
      expect(find.text('团队名称'), findsOneWidget);
    });

    testWidgets('responsive grid layout desktop 3 columns',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1080));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith((ref) async => mockTeams),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('responsive grid layout tablet 2 columns',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith((ref) async => mockTeams),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('responsive grid layout mobile 1 column + FAB',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamsProvider.overrideWith((ref) async => mockTeams),
          ],
          child: const MaterialApp(
            home: TeamListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
