import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../listing_detail/data/listing_detail_repository.dart';
import '../data/favorites_repository.dart';

/// UC-18 — the favorites grid (brief P10 item 4): swipe to remove, empty state pointing to
/// the map. Only reachable by an authenticated user (the shell's guest gate blocks this tab
/// for guests), so there's no guest branch to handle here.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Listing>? _items;
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
      final items = await ref.read(favoritesRepositoryProvider).fetchFavorites();
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

  Future<void> _remove(Listing listing) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _items!.removeWhere((item) => item.id == listing.id));
    try {
      await ref.read(listingDetailRepositoryProvider).removeFavorite(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.favoritesRemoved)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _items!.insert(0, listing)); // rollback
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_loading) {
      body = GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ListingCardSkeleton(),
      );
    } else if (_error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      body = ErrorState(message: message, onRetry: _load);
    } else if (_items!.isEmpty) {
      body = EmptyState(
        icon: Icons.favorite_border,
        title: l10n.favoritesEmptyTitle,
        message: l10n.favoritesEmptyMessage,
        actionLabel: l10n.mapViewToggleMap,
        onAction: () => context.go('/map'),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.72,
          ),
          itemCount: _items!.length,
          itemBuilder: (context, index) {
            final listing = _items![index];
            return Dismissible(
              key: ValueKey(listing.id),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _remove(listing),
              background: const ColoredBox(color: AppColors.danger),
              child: ListingCard(
                listing: listing,
                onTap: () => context.push('/listing/${listing.id}'),
                onFavoriteToggle: () => _remove(listing),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navFavorites)),
      body: body,
    );
  }
}
