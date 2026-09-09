import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/messages_repository.dart';

/// UC-40 — the conversation list (brief P10 item 5): counterpart avatar, listing thumbnail,
/// last message, time, unread dot. Only reachable by an authenticated user (the shell's
/// guest gate blocks this tab for guests).
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  List<Conversation>? _items;
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
      final items = await ref.read(messagesRepositoryProvider).fetchConversations();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_loading) {
      body = ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const LoadingSkeleton(height: 64),
      );
    } else if (_error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      body = ErrorState(message: message, onRetry: _load);
    } else if (_items!.isEmpty) {
      body = EmptyState(
        icon: Icons.chat_bubble_outline,
        title: l10n.messagesEmptyTitle,
        message: l10n.messagesEmptyMessage,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _items!.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _ConversationRow(conversation: _items![index]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMessages)),
      body: body,
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counterpart = conversation.counterpart;
    final lastMessage = conversation.lastMessage;
    final thumbnail = conversation.listing.coverThumbnail;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push('/conversation/${conversation.id}', extra: conversation),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryTint,
              backgroundImage: counterpart.avatar != null
                  ? NetworkImage(counterpart.avatar!)
                  : null,
              child: counterpart.avatar == null
                  ? Icon(counterpart.role.icon, color: AppColors.primary)
                  : null,
            ),
            if (thumbnail != null)
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(thumbnail)),
                ),
              ),
          ],
        ),
        title: Text(
          counterpart.name,
          style: AppTypography.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${conversation.listing.title} · ${lastMessage?.body ?? ''}',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageAt != null)
              Text(
                RelativeTime.format(l10n, conversation.lastMessageAt!),
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            const SizedBox(height: AppSpacing.xs),
            AppBadge.count(conversation.unreadCount),
          ],
        ),
      ),
    );
  }
}
