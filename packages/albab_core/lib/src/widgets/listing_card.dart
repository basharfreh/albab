import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../format/area.dart';
import '../format/money.dart';
import '../models/listing.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum ListingCardLayout {
  /// The results-list / grid card (brief UC-14).
  vertical,

  /// The map peek card that slides up when a pin is tapped (brief UC-11).
  horizontal,
}

/// The one listing card the whole app reuses — map peek card, results list, favorites grid,
/// "similar properties" strip. Cover photo, title, neighborhood + landmark, price
/// (+ negotiable badge), area/beds/baths, and photo count — everything [ListingCardSerializer]
/// sends, per brief UC-11.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.layout = ListingCardLayout.vertical,
    this.onTap,
    this.onFavoriteToggle,
  });

  final Listing listing;
  final ListingCardLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: layout == ListingCardLayout.horizontal
            ? _HorizontalCard(listing: listing, l10n: l10n, onFavoriteToggle: onFavoriteToggle)
            : _VerticalCard(listing: listing, l10n: l10n, onFavoriteToggle: onFavoriteToggle),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.listing, this.width, required this.height});

  final Listing listing;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = listing.coverThumbnail;
    return SizedBox(
      width: width,
      height: height,
      child: url == null
          ? const ColoredBox(
              color: AppColors.background,
              child: Icon(Icons.image_outlined, color: AppColors.textMuted),
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ColoredBox(color: AppColors.background),
              errorWidget: (context, url, error) => const ColoredBox(
                color: AppColors.background,
                child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
              ),
            ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorited, required this.onToggle});

  final bool isFavorited;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited ? AppColors.danger : Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.listing, required this.l10n});

  final Listing listing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final price = listing.price;
    return Row(
      children: [
        Text(
          price == null ? '—' : Money.format(price),
          style: AppTypography.section.copyWith(color: AppColors.primary),
        ),
        if (listing.isNegotiable) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.listingNegotiable,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _MiniStats extends StatelessWidget {
  const _MiniStats({required this.listing, required this.l10n});

  final Listing listing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final areaSqm = listing.areaSqm;
    return Wrap(
      spacing: AppSpacing.md,
      children: [
        if (areaSqm != null) _MiniStat(Icons.straighten_outlined, Area.format(l10n, num.parse(areaSqm))),
        if (listing.bedrooms != null) _MiniStat(Icons.bed_outlined, '${listing.bedrooms}'),
        if (listing.bathrooms != null) _MiniStat(Icons.bathtub_outlined, '${listing.bathrooms}'),
        _MiniStat(Icons.photo_camera_outlined, '${listing.imagesCount}'),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value);

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.caption),
      ],
    );
  }
}

class _NeighborhoodLine extends StatelessWidget {
  const _NeighborhoodLine({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final neighborhood = listing.neighborhoodName;
    final landmark = listing.landmark;
    final text = [?neighborhood, if (landmark.isNotEmpty) landmark].join(' - ');
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _VerticalCard extends StatelessWidget {
  const _VerticalCard({required this.listing, required this.l10n, this.onFavoriteToggle});

  final Listing listing;
  final AppLocalizations l10n;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            _CoverImage(listing: listing, height: 140),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: _FavoriteButton(
                isFavorited: listing.isFavorited,
                onToggle: onFavoriteToggle,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: AppTypography.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _NeighborhoodLine(listing: listing),
              const SizedBox(height: AppSpacing.sm),
              _PriceLine(listing: listing, l10n: l10n),
              const SizedBox(height: AppSpacing.sm),
              _MiniStats(listing: listing, l10n: l10n),
            ],
          ),
        ),
      ],
    );
  }
}

class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard({required this.listing, required this.l10n, this.onFavoriteToggle});

  final Listing listing;
  final AppLocalizations l10n;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
                child: _CoverImage(listing: listing, width: 110, height: 110),
              ),
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: _FavoriteButton(
                  isFavorited: listing.isFavorited,
                  onToggle: onFavoriteToggle,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    listing.title,
                    style: AppTypography.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _NeighborhoodLine(listing: listing),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceLine(listing: listing, l10n: l10n),
                  const SizedBox(height: 4),
                  _MiniStats(listing: listing, l10n: l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
