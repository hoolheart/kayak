/// Team widgets tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/team/models/team_role.dart';
import 'package:kayak_frontend/features/team/widgets/create_team_dialog.dart';
import 'package:kayak_frontend/features/team/widgets/member_list_item.dart';
import 'package:kayak_frontend/features/team/widgets/role_badge.dart';
import 'package:kayak_frontend/features/team/widgets/team_card.dart';

import 'helpers/team_test_data.dart';

void main() {
  group('RoleBadge', () {
    testWidgets('renders owner badge with correct colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleBadge(role: TeamRole.owner),
          ),
        ),
      );

      expect(find.text('OWNER'), findsOneWidget);
    });

    testWidgets('renders admin badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleBadge(role: TeamRole.admin),
          ),
        ),
      );

      expect(find.text('ADMIN'), findsOneWidget);
    });

    testWidgets('renders member badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleBadge(role: TeamRole.member),
          ),
        ),
      );

      expect(find.text('MEMBER'), findsOneWidget);
    });
  });

  group('TeamCard', () {
    testWidgets('renders team information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamCard(team: mockTeams.first),
          ),
        ),
      );

      expect(find.text('研发团队'), findsOneWidget);
      expect(find.text('12 位成员'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: mockTeams.first,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('研发团队'));
      expect(tapped, isTrue);
    });
  });

  group('MemberListItem', () {
    testWidgets('renders member information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberListItem(member: mockMembers[0]),
          ),
        ),
      );

      expect(find.text('张三'), findsOneWidget);
      expect(find.text('zhangsan@example.com'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows actions for non-owner when showActions is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberListItem(
              member: mockMembers[2],
              showActions: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('hides actions for owner', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberListItem(
              member: mockMembers[0],
              showActions: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('hides actions when showActions is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberListItem(
              member: mockMembers[2],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('CreateTeamDialog', () {
    testWidgets('validates name is required', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateTeamDialog(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '创建'));
      await tester.pumpAndSettle();

      expect(find.text('团队名称不能为空'), findsOneWidget);
    });

    testWidgets('validates name max length', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateTeamDialog(),
        ),
      );
      await tester.pumpAndSettle();

      final longName = 'A' * 256;
      await tester.enterText(
        find.widgetWithText(TextFormField, '团队名称'),
        longName,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '创建'));
      await tester.pumpAndSettle();

      expect(find.text('团队名称不能超过 255 个字符'), findsOneWidget);
    });

    testWidgets('accepts valid name', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateTeamDialog(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '团队名称'),
        '新团队',
      );
      await tester.pumpAndSettle();

      expect(find.text('团队名称不能为空'), findsNothing);
      expect(find.text('团队名称不能超过 255 个字符'), findsNothing);
    });
  });
}
