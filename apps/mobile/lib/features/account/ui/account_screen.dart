import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../data/account_repository.dart';

/// UC-06/UC-07 plus the full row list brief §5's screen inventory describes: avatar, name,
/// phone, role badge, then عقاراتي (count) · المفضلة (count) · الرسائل (badge) ·
/// الإشعارات (badge) · إحصائيات مشاهدات عقاراتي · الإعدادات · تسجيل الخروج. Guests see a
/// sign-in prompt instead of the profile header (brief §5's screen inventory, brief P10 item
/// 1) — normal tab navigation already gates this behind `AppShell`'s guest-gate sheet (brief
/// P5), but a guest can still reach `/account` directly (a deep link, or app state restored
/// mid-session), so the branch is real, not dead code.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  AccountCounts? _counts;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCounts);
  }

  Future<void> _loadCounts() async {
    if (ref.read(authStateProvider) is! AuthStateAuthenticated) return;
    try {
      final counts = await ref.read(accountRepositoryProvider).fetchCounts();
      if (mounted) setState(() => _counts = counts);
    } on ApiException {
      // Row counts are a nice-to-have next to each label — a failed fetch just leaves them
      // blank rather than blocking or erroring the whole screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: user == null ? _GuestPrompt(l10n: l10n) : _buildAuthenticated(context, l10n, user),
    );
  }

  Widget _buildAuthenticated(BuildContext context, AppLocalizations l10n, User user) {
    return RefreshIndicator(
      onRefresh: _loadCounts,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: AppSpacing.xl),
          _AccountRow(
            icon: Icons.home_work_outlined,
            label: l10n.accountMyListings,
            trailing: _counts == null ? null : '${_counts!.myListings}',
            onTap: () => context.push('/my-listings'),
          ),
          _AccountRow(
            icon: Icons.favorite_border,
            label: l10n.accountFavorites,
            trailing: _counts == null ? null : '${_counts!.favorites}',
            onTap: () => context.push('/favorites'),
          ),
          _AccountRow(
            icon: Icons.chat_bubble_outline,
            label: l10n.accountMessages,
            badgeCount: user.unreadMessages,
            onTap: () => context.push('/messages'),
          ),
          _AccountRow(
            icon: Icons.notifications_none,
            label: l10n.accountNotifications,
            badgeCount: user.unreadNotifications,
            onTap: () => context.push('/notifications'),
          ),
          _AccountRow(
            icon: Icons.bar_chart_outlined,
            label: l10n.accountStats,
            onTap: () => context.push('/stats'),
          ),
          _AccountRow(
            icon: Icons.settings_outlined,
            label: l10n.accountSettings,
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: () => _logout(context, ref),
              child: Text(l10n.authLogout),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).logout();
    if (context.mounted) context.go('/welcome');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primaryTint,
          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
          child: user.avatar == null
              ? Icon(user.role.icon, size: 36, color: AppColors.primary)
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(user.name, style: AppTypography.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        if (user.phone != null)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              PhoneFormat.display(user.phone!),
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppBadge(
          label: user.role.label(l10n),
          color: AppColors.primary,
          background: AppColors.primaryTint,
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTypography.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          if (badgeCount != null) ...[
            const SizedBox(width: AppSpacing.sm),
            AppBadge.count(badgeCount!),
          ],
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_left, color: AppColors.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.accountGuestPromptTitle,
              style: AppTypography.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.accountGuestPromptMessage,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: l10n.authLogin, onPressed: () => context.push('/login')),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: l10n.authRegister, onPressed: () => context.push('/register')),
          ],
        ),
      ),
    );
  }
}
