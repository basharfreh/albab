import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../map/data/listings_repository.dart';
import '../../shell/ui/guest_gate.dart';
import '../data/listing_detail_repository.dart';
import 'widgets/contact_bar.dart';
import 'widgets/listing_gallery.dart';
import 'widgets/owner_block.dart';
import 'widgets/report_sheet.dart';
import 'widgets/similar_listings_strip.dart';

/// UC-15…UC-20 — gallery, badges/price/stats, description, owner block, sticky
/// call/WhatsApp bar, favorite, share, report, and a similar-listings strip. Replaces P6's
/// deliberately minimal placeholder; the route path and the "fire `view` once per open"
/// behavior (brief P6 item 7) carry over unchanged.
class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  late Future<Listing> _future;
  bool _viewEventSent = false;
  Listing? _listing;
  List<Listing> _similar = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Listing> _load() {
    // Fired once per screen open, on the initial load only — not on pull-to-refresh/retry,
    // which would otherwise double-count a single visit.
    if (!_viewEventSent) {
      _viewEventSent = true;
      ref.read(listingsRepositoryProvider).postEvent(widget.listingId, ListingEventKind.view);
    }
    return ref.read(listingsRepositoryProvider).fetchListingDetail(widget.listingId).then((
      listing,
    ) {
      if (mounted) setState(() => _listing = listing);
      unawaited(_loadSimilar(listing));
      return listing;
    });
  }

  Future<void> _loadSimilar(Listing listing) async {
    try {
      final similar = await ref.read(listingDetailRepositoryProvider).fetchSimilar(listing);
      if (mounted) setState(() => _similar = similar);
    } catch (_) {
      // Best-effort, non-critical strip — see SimilarListingsStrip: absence reads as
      // "nothing similar," not an error the user needs to see or retry.
    }
  }

  void _retry() {
    setState(() {
      _listing = null;
      _similar = const [];
      _future = _load();
    });
  }

  Future<void> _toggleFavorite() async {
    if (ref.read(authStateProvider) is! AuthStateAuthenticated) {
      showGuestGateSheet(context);
      return;
    }
    final current = _listing;
    if (current == null) return;
    final next = !current.isFavorited;
    setState(() => _listing = current.copyWith(isFavorited: next));
    final repo = ref.read(listingDetailRepositoryProvider);
    try {
      if (next) {
        await repo.addFavorite(current.id);
      } else {
        await repo.removeFavorite(current.id);
      }
    } catch (_) {
      if (mounted) setState(() => _listing = current); // rollback on failure
    }
  }

  Future<void> _report() async {
    if (ref.read(authStateProvider) is! AuthStateAuthenticated) {
      showGuestGateSheet(context);
      return;
    }
    final result = await showReportSheet(context);
    if (result == null || !mounted) return;
    final (reason, note) = result;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(listingDetailRepositoryProvider)
          .report(widget.listingId, reason: reason, note: note);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
      }
    }
  }

  void _share(Listing listing) {
    ref.read(listingsRepositoryProvider).postEvent(listing.id, ListingEventKind.share);
    final l10n = AppLocalizations.of(context)!;
    final url = 'https://albab.sy/l/${listing.id}';
    SharePlus.instance.share(ShareParams(text: l10n.shareCaption(listing.title, url)));
  }

  void _openListing(int id) => context.push('/listing/$id');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: FutureBuilder<Listing>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _DetailSkeleton();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.localizedMessage(l10n)
                : l10n.errorUnknown;
            return ErrorState(message: message, onRetry: _retry);
          }
          final listing = _listing ?? snapshot.data!;
          return _DetailBody(
            listing: listing,
            similar: _similar,
            onFavoriteToggle: _toggleFavorite,
            onShare: () => _share(listing),
            onReport: _report,
            onOpenSimilar: _openListing,
            onContactEvent: (kind) =>
                ref.read(listingsRepositoryProvider).postEvent(listing.id, kind),
          );
        },
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoadingSkeleton(height: 260, borderRadius: AppRadius.cardRadius),
            const SizedBox(height: AppSpacing.lg),
            const LoadingSkeleton(height: 22, width: 220),
            const SizedBox(height: AppSpacing.sm),
            const LoadingSkeleton(height: 16, width: 140),
            const SizedBox(height: AppSpacing.lg),
            const LoadingSkeleton(height: 28, width: 120),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.listing,
    required this.similar,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onReport,
    required this.onOpenSimilar,
    required this.onContactEvent,
  });

  final Listing listing;
  final List<Listing> similar;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final void Function(int listingId) onOpenSimilar;
  final void Function(ListingEventKind kind) onContactEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final owner = listing.owner;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListingGallery(
                images: listing.images ?? const [],
                isFavorited: listing.isFavorited,
                onBack: () => Navigator.of(context).maybePop(),
                onShare: onShare,
                onFavoriteToggle: onFavoriteToggle,
                onReport: onReport,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        AppBadge(
                          label: listing.purpose.label(l10n),
                          color: AppColors.primaryDark,
                        ),
                        AppBadge(
                          label: listing.propertyType.label(l10n),
                          color: listing.propertyType.pinColor,
                          background: listing.propertyType.pinColor.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(listing.title, style: AppTypography.title),
                    const SizedBox(height: 4),
                    if (listing.neighborhoodName != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                listing.neighborhoodName,
                                if (listing.landmark.isNotEmpty) listing.landmark,
                              ].join(' - '),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Text(
                          listing.price == null ? '—' : Money.format(listing.price!),
                          style: AppTypography.display.copyWith(color: AppColors.primary),
                        ),
                        if (listing.isNegotiable) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.listingNegotiable, style: AppTypography.caption),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PropertyStatsRow(
                      areaSqm: listing.areaSqm,
                      bedrooms: listing.bedrooms,
                      bathrooms: listing.bathrooms,
                    ),
                    if (listing.description != null && listing.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: l10n.listingPropertyInfo),
                      const SizedBox(height: AppSpacing.sm),
                      Text(listing.description!, style: AppTypography.body),
                    ],
                    if (owner != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.lg),
                      OwnerBlock(owner: owner),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SimilarListingsStrip(listings: similar, onTap: onOpenSimilar),
                  ],
                ),
              ),
            ],
          ),
        ),
        ContactBar(listing: listing, onEvent: onContactEvent),
      ],
    );
  }
}
