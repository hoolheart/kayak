import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services.dart';

// ============================================================
// SettingsPage — 个人资料页面
//
// 功能：
// 1. 显示当前用户信息（用户名、邮箱、注册时间）
// 2. 编辑用户名（调用 PUT /api/v1/users/me）
// 3. 修改密码（调用 POST /api/v1/users/me/password）
// ============================================================
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // ---- 编辑资料表单 ----
  final _profileFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  // ---- 修改密码表单 ----
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordSectionExpanded = false;

  // ---- 加载状态 ----
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 本地化
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  // ============================================================
  // 保存资料
  // ============================================================
  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    try {
      final authService = ref.read(authServiceProvider);
      final updatedUser = await authService.updateProfile(
        username: _usernameController.text.trim(),
      );

      // 使用 AuthNotifier.updateUser 局部更新状态，避免全量重建
      if (mounted) {
        ref.read(authProvider.notifier).updateUser(updatedUser);
        _showSnackBar(_l10n.profileUpdateSuccess);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(_mapProfileError(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  // ============================================================
  // 修改密码
  // ============================================================
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        // 清空密码字段
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        // 自动收起密码修改区域
        setState(() => _passwordSectionExpanded = false);
        _showSnackBar(_l10n.passwordChangeSuccess);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(_mapProfileError(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  // ============================================================
  // 提示条
  // ============================================================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 将资料/密码操作中的异常映射为用户可读的错误消息。
  String _mapProfileError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return _l10n.networkError;

        case DioExceptionType.badResponse:
          switch (error.response?.statusCode) {
            case 400:
              return '请求格式不正确，请检查输入';
            case 401:
              return '登录已过期，请重新登录';
            case 422:
              return '输入数据格式不正确';
            case 500:
            case 502:
            case 503:
              return '服务暂时不可用，请稍后重试';
            default:
              return '操作失败，请重试';
          }

        default:
          return _l10n.networkError;
      }
    }
    return _l10n.networkError;
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // 监听 auth 状态变更，自动更新用户名编辑器
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      final nextUser = next.asData?.value;
      if (nextUser?.username != null) {
        if (_usernameController.text != nextUser!.username) {
          _usernameController.text = nextUser.username!;
        }
      }
    });

    final authState = ref.watch(authProvider);
    final user = authState.asData?.value;

    // 同步用户名字段：初始加载时 ref.listen 不触发初始回调，
    // 因此在 build 中直接读取 authState 的初始值同步到编辑器
    if (user?.username != null && _usernameController.text.isEmpty) {
      _usernameController.text = user!.username!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.settings),
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : authState.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        authState.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : user == null
                  ? Center(child: Text(_l10n.noData))
                  : _buildContent(context, user),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 32 : 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- 个人信息卡片 ----
                  _buildProfileCard(context, user),
                  const SizedBox(height: 24),

                  // ---- 修改密码卡片 ----
                  _buildPasswordCard(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 用户信息卡片
  // ============================================================
  Widget _buildProfileCard(BuildContext context, User user) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 区域标题
              Row(
                children: [
                  Icon(Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _l10n.profileInfo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 邮箱（只读显示）
              _buildInfoRow(
                context,
                icon: Icons.email_outlined,
                label: _l10n.email,
                value: user.email,
              ),
              const SizedBox(height: 12),

              // 注册时间（只读显示）
              _buildInfoRow(
                context,
                icon: Icons.calendar_today_outlined,
                label: _l10n.memberSince,
                value: user.createdAt != null
                    ? DateFormat.yMMMd().format(user.createdAt!)
                    : '--',
              ),
              const Divider(height: 24),

              // 编辑用户名
              Text(
                _l10n.editProfile,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: _l10n.username,
                  hintText: _l10n.usernameHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // username is optional
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < 3 || trimmed.length > 30) {
                    return _l10n.usernameLengthError;
                  }
                  final validRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
                  if (!validRegex.hasMatch(trimmed)) {
                    return _l10n.usernameInvalidChars;
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveProfile(),
              ),
              const SizedBox(height: 16),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: _isSavingProfile
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 密码修改卡片
  // ============================================================
  Widget _buildPasswordCard(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 600;
    return Card(
      child: Column(
        children: [
          // 可展开的标题区域
          InkWell(
            onTap: () {
              setState(() {
                _passwordSectionExpanded = !_passwordSectionExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _passwordSectionExpanded
                  ? Radius.zero
                  : const Radius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(narrow ? 16 : 24),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _l10n.changePassword,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _passwordSectionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),

          // 展开的密码表单
          if (_passwordSectionExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(narrow ? 16 : 24, 0, narrow ? 16 : 24, narrow ? 16 : 24),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),

                    // 当前密码
                    TextFormField(
                      controller: _oldPasswordController,
                      decoration: InputDecoration(
                        labelText: _l10n.currentPassword,
                        hintText: _l10n.passwordHint,
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _l10n.currentPasswordRequired;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // 新密码
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: _l10n.newPassword,
                        hintText: _l10n.passwordHint,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _l10n.newPasswordRequired;
                        }
                        if (value.length < 8) {
                          return _l10n.newPasswordMinLength;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // 确认新密码
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: _l10n.confirmPassword,
                        hintText: _l10n.confirmPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _l10n.passwordsDoNotMatch;
                        }
                        if (value != _newPasswordController.text) {
                          return _l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _changePassword(),
                    ),
                    const SizedBox(height: 24),

                    // 提交按钮
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _isChangingPassword ? null : _changePassword,
                        icon: _isChangingPassword
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_l10n.submit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 只读信息行
  // ============================================================
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20,
              color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
