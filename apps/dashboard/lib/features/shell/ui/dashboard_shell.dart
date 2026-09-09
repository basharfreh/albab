import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.labelBuilder});

  final String path;
  final IconData icon;
  final String Function(AppLocalizations l10n) labelBuilder;
}

const _navItems = [
  _NavItem(path: '/home', icon: Icons.dashboard_outlined, labelBuilder: _navHome),
  _NavItem(path: '/listings', icon: Icons.home_work_outlined, labelBuilder: _navListings),
  _NavItem(path: '/users', icon: Icons.people_outline, labelBuilder: _navUsers),
  _NavItem(path: '/promotions', icon: Icons.campaign_outlined, labelBuilder: _navPromotions),
  _NavItem(path: '/transactions', icon: Icons.receipt_long_outlined, labelBuilder: _navTx),
  _NavItem(
    path: '/notifications',
    icon: Icons.notifications_outlined,
    labelBuilder: _navNotifications,
  ),
  _NavItem(path: '/reports', icon: Icons.flag_outlined, labelBuilder: _navReports),
  _NavItem(path: '/settings', icon: Icons.settings_outlined, labelBuilder: _navSettings),
];

String _navHome(AppLocalizations l10n) => l10n.dashNavHome;
String _navListings(AppLocalizations l10n) => l10n.dashNavListings;
String _navUsers(AppLocalizations l10n) => l10n.dashNavUsers;
String _navPromotions(AppLocalizations l10n) => l10n.dashNavPromotions;
String _navTx(AppLocalizations l10n) => l10n.dashNavTransactions;
String _navNotifications(AppLocalizations l10n) => l10n.dashNavNotifications;
String _navReports(AppLocalizations l10n) => l10n.dashNavReports;
String _navSettings(AppLocalizations l10n) => l10n.dashNavSettings;

/// The dashboard shell (brief §5/P11 item 1): dark navy sidebar with the brand lockup and
/// eight nav items, collapsible to icon-only under 1100px width, a top bar with search/bell/
/// avatar, and a max-width-1440 content canvas. Wraps every route except `/login` (brief
/// item 2 keeps login on its own unshelled screen).
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final location = GoRouterState.of(context).matchedLocation;
    final isCollapsed = MediaQuery.sizeOf(context).width < 1100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(collapsed: isCollapsed, currentPath: location),
          Expanded(
            child: Column(
              children: [
                _TopBar(userName: user?.name, l10n: l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.collapsed, required this.currentPath});

  final bool collapsed;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: collapsed ? 72 : 240,
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxl,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                  if (!collapsed) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.appName,
                        style: AppTypography.section.copyWith(color: AppColors.surface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in _navItems)
                      _SidebarTile(
                        item: item,
                        collapsed: collapsed,
                        selected: currentPath == item.path,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.collapsed, required this.selected});

  final _NavItem item;
  final bool collapsed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = selected ? AppColors.primary : AppColors.surface.withValues(alpha: 0.72);
    final tile = Material(
      color: selected ? AppColors.surface.withValues(alpha: 0.06) : Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.path),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: collapsed ? AppSpacing.lg : AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon, color: color, size: AppIconSizes.navAndList),
              if (!collapsed) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.labelBuilder(l10n),
                    style: AppTypography.body.copyWith(color: color, height: null),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: item.labelBuilder(l10n), child: tile) : tile;
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.userName, required this.l10n});

  final String? userName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.dashSearchPlaceholder,
                  prefixIcon: const Icon(Icons.search, size: AppIconSizes.inline),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.lg),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') ref.read(authRepositoryProvider).logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'logout', child: Text(l10n.authLogout)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryTint,
                  child: Icon(Icons.person, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(userName ?? '', style: AppTypography.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
