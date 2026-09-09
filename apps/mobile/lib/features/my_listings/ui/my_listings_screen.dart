import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../add_listing/data/add_listing_repository.dart';
import '../../add_listing/data/wizard_draft.dart';
import '../data/my_listings_repository.dart';
import 'widgets/my_listing_row.dart';
import 'widgets/promotion_sheet.dart';

/// UC-35/UC-36 — "عقاراتي": the status-tabbed list (brief P10 item 2). Five tabs, exactly
/// the mockup's own list ("الكل · منشور · قيد المراجعة · مرفوض · مباع/مؤجر") — `draft` and
/// `paused` listings have no tab of their own and only surface under "الكل" (see
/// [_statusesForTab]), matching the project's precedent of following an itemized brief list
/// literally over the model's fuller status enum (P7 left `bathrooms` out of the filter
/// screen the same way).
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  static const _tabCount = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: _tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.accountMyListings),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.myListingsStatusAll),
              Tab(text: l10n.myListingsStatusPublished),
              Tab(text: l10n.myListingsStatusPending),
              Tab(text: l10n.myListingsStatusRejected),
              Tab(text: l10n.myListingsStatusSoldRented),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyListingsTab(statuses: null),
            _MyListingsTab(statuses: ['published']),
            _MyListingsTab(statuses: ['pending']),
            _MyListingsTab(statuses: ['rejected']),
            _MyListingsTab(statuses: ['sold', 'rented']),
          ],
        ),
      ),
    );
  }
}

class _MyListingsTab extends ConsumerStatefulWidget {
  const _MyListingsTab({required this.statuses});

  /// `null` = "الكل" (no filter). A single entry uses the server's `?status=` filter with
  /// real pagination; two entries (sold/rented) merges one page of each — see
  /// `MyListingsRepository.fetchByStatuses`.
  final List<String>? statuses;

  @override
  ConsumerState<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends ConsumerState<_MyListingsTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _items = <Listing>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool get _isMultiStatus => (widget.statuses?.length ?? 0) > 1;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (mounted) _load(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 1;
        _hasMore = true;
      }
    });
    try {
      final repo = ref.read(myListingsRepositoryProvider);
      if (_isMultiStatus) {
        final results = await repo.fetchByStatuses(widget.statuses!);
        if (!mounted) return;
        setState(() {
          _items
            ..clear()
            ..addAll(results);
          _hasMore = false;
          _loading = false;
        });
        return;
      }
      final result = await repo.fetchMyListings(
        status: widget.statuses?.first,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(result.results);
        _hasMore = result.next != null;
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

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _isMultiStatus) return;
    _page += 1;
    await _load(reset: false);
  }

  Future<void> _delete(Listing listing) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myListingsDeleteConfirmTitle),
        content: Text(l10n.myListingsDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(myListingsRepositoryProvider).deleteListing(listing.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((item) => item.id == listing.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.myListingsDeleted)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    }
  }

  Future<void> _toggleStatus(Listing listing) async {
    final l10n = AppLocalizations.of(context)!;
    final target = listing.status == ListingStatus.paused ? 'published' : 'paused';
    try {
      await ref.read(myListingsRepositoryProvider).setStatus(listing.id, target);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.myListingsStatusUpdated)));
      _load(reset: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    if (_items.isEmpty && _loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const ListingCardSkeleton(),
      );
    }
    if (_items.isEmpty && _error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      return ErrorState(message: message, onRetry: () => _load(reset: true));
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.home_work_outlined,
        title: l10n.myListingsEmptyTitle,
        message: l10n.myListingsEmptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final listing = _items[index];
          return MyListingRow(
            listing: listing,
            onTap: () => context.push('/listing/${listing.id}'),
            onEdit: () => _editListing(listing),
            onPromote: () => showPromotionComingSoonSheet(context),
            onToggleStatus: () => _toggleStatus(listing),
            onDelete: () => _delete(listing),
          );
        },
      ),
    );
  }

  /// Reuses the wizard's own resume mechanism (brief P9): remembering `listing.id` as the
  /// "wizard draft" is what makes an app-restart resume onto it. Loading
  /// `wizardDraftProvider` directly (rather than only writing prefs and trusting
  /// `AddListingWizardScreen._resume()` to re-run) also covers navigating here while `/add`'s
  /// widget is already alive in the shell's `IndexedStack` — its `initState` won't fire a
  /// second time, but this provider write reaches it immediately either way.
  Future<void> _editListing(Listing listing) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(prefsStorageProvider).saveWizardProgress(draftId: listing.id, step: 0);
    try {
      final full = await ref.read(addListingRepositoryProvider).fetchListing(listing.id);
      ref.read(wizardDraftProvider.notifier).load(WizardDraft.fromListing(full));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
      return;
    }
    if (mounted) context.go('/add');
  }
}
