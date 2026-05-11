/// Delete team confirmation dialog
library;

import 'package:flutter/material.dart';

/// Delete team confirmation dialog
class DeleteTeamDialog extends StatelessWidget {
  const DeleteTeamDialog({
    super.key,
    required this.teamName,
  });
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber,
        size: 48,
        color: colorScheme.error,
      ),
      title: const Text('确认删除团队'),
      content: Text(
        '确定要删除团队 $teamName 吗？此操作不可撤销，团队中的所有数据和资源将被永久删除。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('删除'),
        ),
      ],
    );
  }
}

/// Show delete team confirmation dialog
Future<bool?> showDeleteTeamDialog(
  BuildContext context,
  String teamName,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteTeamDialog(teamName: teamName),
  );
}

/// Leave team confirmation dialog
class LeaveTeamDialog extends StatelessWidget {
  const LeaveTeamDialog({
    super.key,
    required this.teamName,
  });
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.logout,
        size: 48,
        color: colorScheme.error,
      ),
      title: const Text('确认离开团队'),
      content: Text(
        '确定要离开团队 $teamName 吗？离开后将失去对该团队资源的访问权限。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('离开'),
        ),
      ],
    );
  }
}

/// Show leave team confirmation dialog
Future<bool?> showLeaveTeamDialog(
  BuildContext context,
  String teamName,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => LeaveTeamDialog(teamName: teamName),
  );
}

/// Remove member confirmation dialog
class RemoveMemberDialog extends StatelessWidget {
  const RemoveMemberDialog({
    super.key,
    required this.memberName,
  });
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.person_remove,
        size: 48,
        color: colorScheme.error,
      ),
      title: const Text('确认移除成员'),
      content: Text(
        '确定要将 $memberName 从团队中移除吗？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('移除'),
        ),
      ],
    );
  }
}

/// Show remove member confirmation dialog
Future<bool?> showRemoveMemberDialog(
  BuildContext context,
  String memberName,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => RemoveMemberDialog(memberName: memberName),
  );
}
