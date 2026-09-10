import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_repository.dart';

enum _BroadcastTarget { all, role, user }

/// الإشعارات (UC-3, brief P11 item 7): the broadcast composer — send a notification to
/// every user, everyone with a role, or one user, with a live Arabic preview. Closes the
/// last fully-missing P11 sidebar section — `/admin/notifications/broadcast/` didn't exist
/// anywhere in the backend before this session.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  _BroadcastTarget _target = _BroadcastTarget.all;
  UserRole? _role;
  User? _selectedUser;
  bool _loadingUsers = false;
  List<User> _users = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersIfNeeded() async {
    if (_users.isNotEmpty || _loadingUsers) return;
    setState(() => _loadingUsers = true);
    final users = await ref.read(adminRepositoryProvider).fetchUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loadingUsers = false;
    });
  }

  bool get _canSend {
    if (_titleController.text.trim().isEmpty) return false;
    if (_target == _BroadcastTarget.role && _role == null) return false;
    if (_target == _BroadcastTarget.user && _selectedUser == null) return false;
    return true;
  }

  Future<void> _send() async {
    if (!_canSend) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    try {
      final sent = await ref
          .read(adminRepositoryProvider)
          .sendBroadcast(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
            target: switch (_target) {
              _BroadcastTarget.all => 'all',
              _BroadcastTarget.role => 'role',
              _BroadcastTarget.user => 'user',
            },
            role: _target == _BroadcastTarget.role ? _role : null,
            userId: _target == _BroadcastTarget.user ? _selectedUser?.id : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dashBroadcastSent(sent))));
      setState(() {
        _titleController.clear();
        _bodyController.clear();
        _selectedUser = null;
        _role = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashNavNotifications, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xl),
        // A fixed side-by-side width (e.g. two `SizedBox`s in a `Wrap`) overflows on a
        // narrow viewport, since `SizedBox` forces its width regardless of what's actually
        // available — stacking instead, capped by `ConstrainedBox`, is safe at every width.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildComposerCard(l10n),
              const SizedBox(height: AppSpacing.xl),
              _buildPreviewCard(l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComposerCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: l10n.dashNotificationTitleLabel, controller: _titleController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.dashNotificationBodyLabel,
              controller: _bodyController,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.dashNotificationTargetLabel, style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(l10n.dashNotificationTargetAll),
                  selected: _target == _BroadcastTarget.all,
                  onSelected: (_) => setState(() => _target = _BroadcastTarget.all),
                ),
                ChoiceChip(
                  label: Text(l10n.dashNotificationTargetRole),
                  selected: _target == _BroadcastTarget.role,
                  onSelected: (_) => setState(() => _target = _BroadcastTarget.role),
                ),
                ChoiceChip(
                  label: Text(l10n.dashNotificationTargetUser),
                  selected: _target == _BroadcastTarget.user,
                  onSelected: (_) {
                    setState(() => _target = _BroadcastTarget.user);
                    _loadUsersIfNeeded();
                  },
                ),
              ],
            ),
            if (_target == _BroadcastTarget.role) ...[
              const SizedBox(height: AppSpacing.md),
              AppDropdown<UserRole>(
                label: l10n.dashNotificationRoleLabel,
                value: _role,
                items: UserRole.values,
                labelBuilder: (role) => role.label(l10n),
                onChanged: (value) => setState(() => _role = value),
              ),
            ],
            if (_target == _BroadcastTarget.user) ...[
              const SizedBox(height: AppSpacing.md),
              if (_loadingUsers)
                const Center(child: CircularProgressIndicator())
              else
                AppDropdown<User>(
                  label: l10n.dashNotificationUserLabel,
                  value: _selectedUser,
                  items: _users,
                  labelBuilder: (user) => '${user.name} (${user.phone ?? ''})',
                  onChanged: (value) => setState(() => _selectedUser = value),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: (_canSend && !_sending) ? _send : null,
                icon: const Icon(Icons.send_outlined, size: AppIconSizes.inline),
                label: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.dashSendBroadcast),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(AppLocalizations l10n) {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashNotificationPreviewLabel, style: AppTypography.label),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? l10n.dashNotificationPreviewEmptyTitle : title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: title.isEmpty ? AppColors.textSecondary : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          body.isEmpty ? l10n.dashNotificationPreviewEmptyBody : body,
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
