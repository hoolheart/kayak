/// Invite member dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/team_role.dart';
import '../providers/team_providers.dart';

/// Invite member dialog
class InviteMemberDialog extends ConsumerStatefulWidget {
  const InviteMemberDialog({
    super.key,
    required this.teamId,
  });
  final String teamId;

  @override
  ConsumerState<InviteMemberDialog> createState() =>
      _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  TeamRole _selectedRole = TeamRole.member;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('邀请成员'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '邮箱地址',
                  hintText: '请输入成员邮箱地址',
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _emailController.text.isNotEmpty &&
                          _isValidEmail(_emailController.text)
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入邮箱地址';
                  }
                  if (!_isValidEmail(value.trim())) {
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TeamRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: '角色',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: TeamRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('发送邀请'),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final invitation = await ref
        .read(teamActionsProvider.notifier)
        .inviteMember(
          widget.teamId,
          email: _emailController.text.trim(),
          role: _selectedRole,
        );

    if (mounted) {
      if (invitation != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSubmitting = false);
        final error = ref.read(teamActionsProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('邀请失败: $error')),
          );
        }
      }
    }
  }
}

/// Show invite member dialog
Future<bool?> showInviteMemberDialog(
  BuildContext context,
  String teamId,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => InviteMemberDialog(teamId: teamId),
  );
}
