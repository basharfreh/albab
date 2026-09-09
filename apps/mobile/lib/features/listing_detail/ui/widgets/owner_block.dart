import 'package:albab_core/albab_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The owner block (brief P8 item 2): avatar, name, role badge, member-since. Reads
/// `listing.owner` — present only on `ListingDetailSerializer`'s response, never on the
/// card shape (brief §6), which is exactly why [Listing.owner] is nullable.
class OwnerBlock extends StatelessWidget {
  const OwnerBlock({super.key, required this.owner});

  final User owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final createdAt = owner.createdAt;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryTint,
          backgroundImage: owner.avatar == null
              ? null
              : CachedNetworkImageProvider(owner.avatar!),
          child: owner.avatar == null
              ? const Icon(Icons.person_outline, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(owner.name, style: AppTypography.label),
              const SizedBox(height: 4),
              Row(
                children: [
                  AppBadge(label: owner.role.label(l10n), color: AppColors.primary),
                  if (createdAt != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // Month/year only, kept numeric rather than a localized month name —
                    // no ICU locale-symbol data to initialize, matching how `Money`/
                    // `PhoneFormat`/`Area` are all hand-rolled formatters, not
                    // `intl`-driven. Digits resolve LTR on their own inside the RTL
                    // paragraph via the Unicode bidi algorithm, same as every other
                    // number/price `Text` in this codebase (none wrap in `Directionality`).
                    Text(
                      l10n.listingMemberSince('${createdAt.month}/${createdAt.year}'),
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
