/// Team detail page tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/team/models/team_models.dart';
import 'package:kayak_frontend/features/team/models/team_role.dart';
import 'package:kayak_frontend/features/team/providers/team_providers.dart';
import 'package:kayak_frontend/features/team/screens/team_detail_page.dart';
import 'package:kayak_frontend/features/team/widgets/danger_zone_card.dart';
import 'package:kayak_frontend/features/team/widgets/member_list_item.dart';
import 'package:kayak_frontend/features/team/widgets/team_error_state.dart';

import 'helpers/team_test_data.dart';

void main() {
  group('TeamDetailPage', () {
    testWidgets('renders team info and members for owner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001')
                .overrideWith((ref) async => mockTeamDetail),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => TeamRole.owner),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('研发团队'), findsWidgets);
      expect(find.text('核心产品研发团队'), findsOneWidget);
      expect(find.byType(MemberListItem), findsNWidgets(3));
      expect(find.byIcon(Icons.edit).first, findsOneWidget);
      expect(find.widgetWithText(FilledButton, '邀请成员'), findsOneWidget);
      expect(find.byType(DangerZoneCard), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '删除团队'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '离开团队'), findsNothing);
    });

    testWidgets('renders team info for admin', (WidgetTester tester) async {
      final adminDetail = mockTeamDetail.copyWith(
        currentUserRole: TeamRole.admin,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001')
                .overrideWith((ref) async => adminDetail),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => TeamRole.admin),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit).first, findsOneWidget);
      expect(find.widgetWithText(FilledButton, '邀请成员'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '删除团队'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '离开团队'), findsOneWidget);
    });

    testWidgets('renders team info for member', (WidgetTester tester) async {
      final memberDetail = mockTeamDetail.copyWith(
        currentUserRole: TeamRole.member,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001')
                .overrideWith((ref) async => memberDetail),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => TeamRole.member),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.widgetWithText(FilledButton, '邀请成员'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '删除团队'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '离开团队'), findsOneWidget);
    });

    testWidgets('shows access denied for 403 error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001').overrideWith(
              (ref) async => throw TeamApiException(
                'Forbidden',
                statusCode: 403,
              ),
            ),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('没有权限访问该团队'), findsOneWidget);
      expect(find.byType(TeamErrorState), findsNothing);
    });

    testWidgets('shows not found for 404 error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001').overrideWith(
              (ref) async => throw TeamApiException(
                'Not Found',
                statusCode: 404,
              ),
            ),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('团队不存在'), findsOneWidget);
      expect(find.text('返回团队列表'), findsOneWidget);
    });

    testWidgets('edit button opens edit dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001')
                .overrideWith((ref) async => mockTeamDetail),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => TeamRole.owner),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      expect(find.text('编辑团队信息'), findsOneWidget);
    });

    testWidgets('invite button opens invite dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamDetailProvider('team-001')
                .overrideWith((ref) async => mockTeamDetail),
            membersProvider('team-001')
                .overrideWith((ref) async => mockMembers),
            currentUserRoleProvider('team-001')
                .overrideWith((ref) => TeamRole.owner),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(teamId: 'team-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '邀请成员'));
      await tester.pumpAndSettle();

      expect(find.text('邀请成员'), findsWidgets);
      expect(find.text('邮箱地址'), findsOneWidget);
    });
  });
}
