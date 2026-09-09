import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// Brief P8 item 7 — a horizontal "عقارات مشابهة" strip. Renders nothing at all (not even
/// the section header) when there's nothing similar, rather than an empty section — this
/// strip is a convenience, not a state the screen needs to explain.
class SimilarListingsStrip extends StatelessWidget {
  const SimilarListingsStrip({super.key, required this.listings, required this.onTap});

  final List<Listing> listings;
  final void Function(int listingId) onTap;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.listingSimilar),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final listing = listings[index];
              return SizedBox(
                width: 180,
                child: ListingCard(listing: listing, onTap: () => onTap(listing.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}
