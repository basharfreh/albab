import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// UC-06/brief P10 item 7 — language, notification toggle, edit profile, and the three
/// informational rows (change password / about / contact support / delete account) that hit
/// the same "no endpoint for this in brief §8's fixed list" gap P9 already documented for
/// quota-upgrade/promotion-request — see PROGRESS.md.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final enabled = await ref.read(prefsStorageProvider).readPushEnabled();
      if (mounted) setState(() => _pushEnabled = enabled);
    });
  }

  Future<void> _setPushEnabled(bool value) async {
    setState(() => _pushEnabled = value);
    await ref.read(prefsStorageProvider).savePushEnabled(value);
  }

  void _showNotAvailable() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsNotAvailableMessage)));
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountConfirmTitle),
        content: Text(l10n.settingsDeleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.settingsDeleteAccount),
          ),
        ],
      ),
    );
    if (confirmed == true) _showNotAvailable();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSettings)),
      body: ListView(
        children: [
          _SettingsSectionLabel(l10n.settingsLanguageTitle),
          RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(Locale(value));
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(title: Text(l10n.settingsLanguageArabic), value: 'ar'),
                RadioListTile<String>(title: Text(l10n.settingsLanguageEnglish), value: 'en'),
              ],
            ),
          ),
          const Divider(),
          _SettingsSectionLabel(l10n.settingsNotificationsTitle),
          SwitchListTile(
            title: Text(l10n.settingsPushToggleLabel),
            value: _pushEnabled,
            onChanged: _setPushEnabled,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsEditProfile),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/settings/edit-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.settingsChangePassword),
            trailing: const Icon(Icons.chevron_left),
            onTap: _showNotAvailable,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showAbout(context, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: Text(l10n.settingsContactSupport),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showAbout(context, l10n, message: l10n.settingsContactSupportMessage),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(l10n.settingsDeleteAccount, style: const TextStyle(color: AppColors.danger)),
            onTap: _confirmDeleteAccount,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context, AppLocalizations l10n, {String? message}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appName),
        content: Text(message ?? l10n.settingsAboutBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonDone)),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
    );
  }
}
