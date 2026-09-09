import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/messages_repository.dart';

/// One optimistically-sent message: shown immediately, replaced by the server's own row once
/// the POST resolves, or offered a retry if it fails (brief P10 item 5: "Sending is
/// optimistic with a failed-state retry").
class _PendingMessage {
  _PendingMessage({required this.body});

  final String body;
  bool failed = false;
}

/// UC-40's chat screen: a listing header banner, bubbles, 15-second polling while open
/// (brief §3 rule: "messages poll on a 15s interval," not WebSockets). [conversation] is the
/// header info the conversation list already had in hand; when navigated to without it (a
/// notification tap, brief P10 item 6) this fetches the conversation list once to recover it
/// — there is no single-conversation detail endpoint (docs/API.md only has the messages
/// sub-resource), so the list is the only source for the counterpart/listing header.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId, this.conversation});

  final int conversationId;
  final Conversation? conversation;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  Conversation? _conversation;
  List<Message>? _messages;
  final _pending = <_PendingMessage>[];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    Future.microtask(_load);
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(messagesRepositoryProvider);
      final futures = <Future>[repo.fetchMessages(widget.conversationId)];
      if (_conversation == null) futures.add(repo.fetchConversations());
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _messages = results[0] as List<Message>;
        if (_conversation == null && results.length > 1) {
          final all = results[1] as List<Conversation>;
          for (final candidate in all) {
            if (candidate.id == widget.conversationId) {
              _conversation = candidate;
              break;
            }
          }
        }
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _poll() async {
    if (!mounted || _loading) return;
    try {
      final messages = await ref.read(messagesRepositoryProvider).fetchMessages(widget.conversationId);
      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (_) {
      // A dropped background poll shouldn't surface an error state over a working screen.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _send([String? retryBody]) async {
    final body = (retryBody ?? _inputController.text).trim();
    if (body.isEmpty) return;

    final pending = retryBody == null
        ? _PendingMessage(body: body)
        : _pending.firstWhere((p) => p.body == retryBody && p.failed);
    setState(() {
      if (retryBody == null) {
        _pending.add(pending);
        _inputController.clear();
      } else {
        pending.failed = false;
      }
    });
    _scrollToBottom();

    try {
      await ref.read(messagesRepositoryProvider).sendMessage(widget.conversationId, body);
      if (!mounted) return;
      setState(() => _pending.remove(pending));
      await _poll();
    } on ApiException {
      if (!mounted) return;
      setState(() => pending.failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final conversation = _conversation;

    return Scaffold(
      appBar: AppBar(
        title: conversation == null
            ? null
            : Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryTint,
                    backgroundImage: conversation.counterpart.avatar != null
                        ? NetworkImage(conversation.counterpart.avatar!)
                        : null,
                    child: conversation.counterpart.avatar == null
                        ? Icon(conversation.counterpart.role.icon, size: 16, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      conversation.counterpart.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          if (conversation != null)
            _ListingBanner(
              conversation: conversation,
              onTap: () => context.push('/listing/${conversation.listing.id}'),
            ),
          Expanded(child: _buildBody(l10n)),
          _MessageInput(controller: _inputController, onSend: () => _send()),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      return ErrorState(message: message, onRetry: _load);
    }
    if (_messages!.isEmpty && _pending.isEmpty) {
      return EmptyState(icon: Icons.forum_outlined, message: l10n.messagesConversationEmpty);
    }
    final myId = switch (ref.read(authStateProvider)) {
      AuthStateAuthenticated(:final user) => user.id,
      _ => null,
    };
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final message in _messages!)
          _MessageBubble(message: message, isMine: message.sender.id == myId),
        for (final pending in _pending)
          _PendingBubble(pending: pending, onRetry: () => _send(pending.body)),
      ],
    );
  }
}

class _ListingBanner extends StatelessWidget {
  const _ListingBanner({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = conversation.listing.coverThumbnail;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        color: AppColors.background,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.buttonRadius,
              child: SizedBox(
                width: 36,
                height: 36,
                child: thumbnail == null
                    ? const ColoredBox(color: AppColors.border)
                    : Image.network(thumbnail, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                conversation.listing.title,
                style: AppTypography.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.body,
              style: AppTypography.body.copyWith(
                color: isMine ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              RelativeTime.format(l10n, message.createdAt),
              style: AppTypography.caption.copyWith(
                color: isMine ? AppColors.surface.withValues(alpha: 0.75) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBubble extends StatelessWidget {
  const _PendingBubble({required this.pending, required this.onRetry});

  final _PendingMessage pending;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: pending.failed ? 1 : 0.55),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pending.body, style: const TextStyle(color: AppColors.surface)),
            if (pending.failed)
              InkWell(
                onTap: onRetry,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 14, color: AppColors.surface),
                      const SizedBox(width: 4),
                      Text(
                        l10n.messageSendFailed,
                        style: AppTypography.caption.copyWith(color: AppColors.surface),
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

class _MessageInput extends StatelessWidget {
  const _MessageInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                label: l10n.messageInputHint,
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
