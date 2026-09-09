import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_repository.dart';

/// المستخدمين (UC-55, brief P11 item 5): a role/search-filterable table, with a row-level
/// details panel for changing role, blocking/unblocking (with a persisted reason — see
/// docs/API.md's P11 addition to `/admin/users/{id}/block/`), and the user's own listings
/// (via `/admin/listings/?owner=`, also a P11 addition).
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  UserRole? _roleFilter;
  String _query = '';
  Timer? _debounce;
  bool _loading = true;
  Object? _error;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ref
          .read(adminRepositoryProvider)
          .fetchUsers(role: _roleFilter, q: _query.isEmpty ? null : _query);
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      _load();
    });
  }

  Future<void> _openDetails(User user) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _UserDetailsDialog(
        user: user,
        onUserUpdated: (updated) {
          setState(() {
            final index = _users.indexWhere((u) => u.id == updated.id);
            if (index != -1) _users[index] = updated;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.dashNavUsers, style: AppTypography.title),
            SizedBox(
              width: 260,
              child: AppTextField(
                label: l10n.dashSearchPlaceholder,
                prefixIcon: Icons.search,
                onChanged: _onSearchChanged,
              ),
            ),
            SizedBox(
              width: 200,
              child: AppDropdown<UserRole?>(
                label: l10n.dashRoleFilterLabel,
                value: _roleFilter,
                items: [null, ...UserRole.values],
                labelBuilder: (role) => role == null ? l10n.dashRoleFilterAll : role.label(l10n),
                onChanged: (value) {
                  setState(() => _roleFilter = value);
                  _load();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Builder(
          builder: (context) {
            if (_loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final error = _error;
            if (error != null) {
              final message = error is ApiException
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnknown;
              return ErrorState(message: message, onRetry: _load);
            }
            if (_users.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: l10n.dashEmptyUsersTitle,
                message: l10n.dashEmptyUsersMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColTitle)),
                    DataColumn(label: Text(l10n.dashColPhone)),
                    DataColumn(label: Text(l10n.dashColRole)),
                    DataColumn(label: Text(l10n.dashColStatus)),
                    DataColumn(label: Text(l10n.dashColDate)),
                    DataColumn(label: Text(l10n.dashColActions)),
                  ],
                  rows: [
                    for (final user in _users)
                      DataRow(
                        cells: [
                          DataCell(Text(user.name)),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(user.phone ?? ''),
                            ),
                          ),
                          DataCell(Text(user.role.label(l10n))),
                          DataCell(_UserStatusChip(user: user, l10n: l10n)),
                          DataCell(
                            Text(
                              user.createdAt == null
                                  ? ''
                                  : RelativeTime.format(l10n, user.createdAt!),
                            ),
                          ),
                          DataCell(
                            TextButton(
                              onPressed: () => _openDetails(user),
                              child: Text(l10n.commonEdit),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UserStatusChip extends StatelessWidget {
  const _UserStatusChip({required this.user, required this.l10n});

  final User user;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final blocked = user.isBlocked ?? false;
    final color = blocked ? AppColors.danger : AppColors.primary;
    return Chip(
      label: Text(blocked ? l10n.dashUserStatusBlocked : l10n.dashUserStatusActive),
      labelStyle: AppTypography.caption.copyWith(color: color),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

/// The brief's "row drawer" (item 5), implemented as a fixed-width modal dialog rather than
/// a persistent `Scaffold.endDrawer` — this screen (like `ListingsScreen`) has no owning
/// `Scaffold` of its own, `DashboardShell` already owns the page's single scroll view, so a
/// dialog is the pragmatic equivalent that still satisfies "row click opens details."
class _UserDetailsDialog extends ConsumerStatefulWidget {
  const _UserDetailsDialog({required this.user, required this.onUserUpdated});

  final User user;
  final ValueChanged<User> onUserUpdated;

  @override
  ConsumerState<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends ConsumerState<_UserDetailsDialog> {
  late User _user;
  bool _acting = false;
  bool _loadingListings = true;
  Object? _listingsError;
  List<Listing> _listings = [];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    Future.microtask(_loadListings);
  }

  Future<void> _loadListings() async {
    setState(() {
      _loadingListings = true;
      _listingsError = null;
    });
    try {
      final listings = await ref
          .read(adminRepositoryProvider)
          .fetchAdminListings(ownerId: _user.id, ordering: '-created_at', pageSize: 50);
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _loadingListings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listingsError = e;
        _loadingListings = false;
      });
    }
  }

  Future<void> _changeRole(UserRole role) async {
    if (role == _user.role) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _acting = true);
    try {
      final updated = await ref.read(adminRepositoryProvider).setUserRole(_user.id, role);
      if (!mounted) return;
      setState(() => _user = updated);
      widget.onUserUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashUserRoleChanged)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _unblock() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _acting = true);
    try {
      final updated = await ref
          .read(adminRepositoryProvider)
          .setUserBlocked(_user.id, blocked: false);
      if (!mounted) return;
      setState(() => _user = updated);
      widget.onUserUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashUserUnblocked)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _block() async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashUserBlock),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: l10n.dashUserBlockReasonLabel),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: Text(l10n.dashUserBlock),
          ),
        ],
      ),
    );
    if (reason == null) return;
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dashUserBlockReasonRequired)));
      return;
    }

    setState(() => _acting = true);
    try {
      final updated = await ref
          .read(adminRepositoryProvider)
          .setUserBlocked(_user.id, blocked: true, reason: reason);
      if (!mounted) return;
      setState(() => _user = updated);
      widget.onUserUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashUserBlocked)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = _user.isBlocked ?? false;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.dashUserDetailsTitle, style: AppTypography.section),
              const SizedBox(height: AppSpacing.md),
              Text(_user.name, style: AppTypography.body),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(_user.phone ?? '', style: AppTypography.caption),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppDropdown<UserRole>(
                label: l10n.dashChangeRoleLabel,
                value: _user.role,
                items: UserRole.values,
                labelBuilder: (role) => role.label(l10n),
                enabled: !_acting,
                onChanged: (role) => role == null ? null : _changeRole(role),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (blocked) ...[
                Text(
                  l10n.dashUserBlockedReason(_user.blockReason ?? ''),
                  style: AppTypography.caption.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _acting ? null : _unblock,
                  child: Text(l10n.dashUserUnblock),
                ),
              ] else
                OutlinedButton(
                  onPressed: _acting ? null : _block,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  child: Text(l10n.dashUserBlock),
                ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.dashUserListingsTitle, style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: Builder(
                  builder: (context) {
                    if (_loadingListings) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final error = _listingsError;
                    if (error != null) {
                      final message = error is ApiException
                          ? error.localizedMessage(l10n)
                          : l10n.errorUnknown;
                      return ErrorState(message: message, onRetry: _loadListings);
                    }
                    if (_listings.isEmpty) {
                      return EmptyState(
                        icon: Icons.home_work_outlined,
                        title: l10n.dashEmptyListingsTitle,
                        message: l10n.dashEmptyListingsMessage,
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: _listings.length,
                      itemBuilder: (context, index) {
                        final listing = _listings[index];
                        return ListTile(
                          dense: true,
                          title: Text(listing.title, overflow: TextOverflow.ellipsis),
                          subtitle: Text(listing.status?.label(l10n) ?? ''),
                          trailing: Text('${listing.viewsCount ?? 0}'),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
