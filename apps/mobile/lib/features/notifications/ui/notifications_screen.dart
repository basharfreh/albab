import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/notifications_repository.dart';

/// UC-41 — brief P10 item 6: grouped by day, unread highlighted, tap routes by `kind` and
/// marks it read, "تعليم الكل كمقروء" in the app bar.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<AppNotification>? _items;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(notificationsRepositoryProvider).fetchNotifications();
      if (!mounted) return;
      setState(() {
        // `Paginated.fromJson`'s generated `results` list is unmodifiable (freezed) — `_open`
        // below mutates `_items` by index, so this needs its own growable copy.
        _items = List<AppNotification>.of(items);
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

  Future<void> _markAllRead() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      if (!mounted) return;
      setState(() {
        _items = [
          for (final n in _items!)
            n.readAt != null ? n : n.copyWith(readAt: DateTime.now()),
        ];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    }
  }

  Future<void> _open(AppNotification notification) async {
    if (notification.readAt == null) {
      setState(() {
        final index = _items!.indexWhere((n) => n.id == notification.id);
        _items![index] = notification.copyWith(readAt: DateTime.now());
      });
      unawaited(ref.read(notificationsRepositoryProvider).markRead(notification.id));
    }

    final data = notification.data;
    final listingId = data['listing_id'];
    final conversationId = data['conversation_id'];
    if (notification.kind == 'new_message' && conversationId != null) {
      if (mounted) context.push('/conversation/${conversationId as int}');
    } else if (listingId != null) {
      if (mounted) context.push('/listing/${listingId as int}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_loading) {
      body = ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const LoadingSkeleton(height: 56),
      );
    } else if (_error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      body = ErrorState(message: message, onRetry: _load);
    } else if (_items!.isEmpty) {
      body = EmptyState(
        icon: Icons.notifications_none,
        title: l10n.notificationsEmptyTitle,
        message: l10n.notificationsEmptyMessage,
      );
    } else {
      body = RefreshIndicator(onRefresh: _load, child: _GroupedList(items: _items!, onTap: _open));
    }

    final hasUnread = _items?.any((n) => n.readAt == null) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountNotifications),
        actions: [
          if (hasUnread)
            TextButton(onPressed: _markAllRead, child: Text(l10n.accountMarkAllRead)),
        ],
      ),
      body: body,
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.items, required this.onTap});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final earlier = <AppNotification>[];
    for (final item in items) {
      final days = now.difference(item.createdAt).inDays;
      final sameCalendarDay =
          item.createdAt.year == now.year &&
          item.createdAt.month == now.month &&
          item.createdAt.day == now.day;
      if (sameCalendarDay) {
        today.add(item);
      } else if (days <= 1) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (today.isNotEmpty) ..._section(l10n.notificationsSectionToday, today),
        if (yesterday.isNotEmpty) ..._section(l10n.notificationsSectionYesterday, yesterday),
        if (earlier.isNotEmpty) ..._section(l10n.notificationsSectionEarlier, earlier),
      ],
    );
  }

  List<Widget> _section(String title, List<AppNotification> items) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(title, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ),
      for (final item in items) _NotificationTile(notification: item, onTap: () => onTap(item)),
      const SizedBox(height: AppSpacing.md),
    ];
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon => switch (notification.kind) {
    'listing_approved' => Icons.check_circle_outline,
    'listing_rejected' => Icons.cancel_outlined,
    'new_message' => Icons.chat_bubble_outline,
    'promotion_expiring' => Icons.local_offer_outlined,
    _ => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUnread = notification.readAt == null;
    return Card(
      color: isUnread ? AppColors.primaryTint : AppColors.surface,
      child: ListTile(
        onTap: onTap,
        leading: Icon(_icon, color: AppColors.primary),
        title: Text(
          notification.title,
          style: isUnread
              ? AppTypography.label
              : AppTypography.body.copyWith(color: AppColors.textPrimary),
        ),
        subtitle: notification.body.isEmpty
            ? null
            : Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
        trailing: Text(
          RelativeTime.format(l10n, notification.createdAt),
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
