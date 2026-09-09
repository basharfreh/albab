import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// One row on "عقاراتي" (brief P10 item 2): cover thumb, title, price, a status chip, the
/// listing's own views count, the admin's rejection reason inline when rejected, and the
/// overflow menu (تعديل · تمييز · تعليق · حذف). A dedicated row rather than reusing
/// [ListingCard] — none of those fields (status/views/menu) are part of that card's shape.
class MyListingRow extends StatelessWidget {
  const MyListingRow({
    super.key,
    required this.listing,
    required this.onTap,
    required this.onEdit,
    required this.onPromote,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPromote;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = listing.status;
    // PATCH-editable per brief §7's P2 rule: draft|rejected|published only.
    final canEdit =
        status == ListingStatus.draft ||
        status == ListingStatus.rejected ||
        status == ListingStatus.published;
    final canToggleStatus = status == ListingStatus.published || status == ListingStatus.paused;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.cardRadius,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: listing.coverThumbnail == null
                          ? const ColoredBox(
                              color: AppColors.background,
                              child: Icon(Icons.image_outlined, color: AppColors.textMuted),
                            )
                          : Image.network(listing.coverThumbnail!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
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
                        Text(
                          listing.price == null ? '—' : Money.format(listing.price!),
                          style: AppTypography.body.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (status != null)
                              AppBadge(
                                label: status.label(l10n),
                                color: status.color,
                                background: status.color.withValues(alpha: 0.12),
                              ),
                            if (listing.viewsCount != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.myListingsViewsCount(listing.viewsCount!),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => switch (value) {
                      'edit' => onEdit(),
                      'promote' => onPromote(),
                      'toggle_status' => onToggleStatus(),
                      'delete' => onDelete(),
                      _ => null,
                    },
                    itemBuilder: (context) => [
                      if (canEdit)
                        PopupMenuItem(value: 'edit', child: Text(l10n.myListingsActionEdit)),
                      PopupMenuItem(value: 'promote', child: Text(l10n.myListingsActionPromote)),
                      if (canToggleStatus)
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Text(
                            status == ListingStatus.paused
                                ? l10n.myListingsActionRepublish
                                : l10n.myListingsActionPause,
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.myListingsActionDelete,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (status == ListingStatus.rejected &&
                  (listing.rejectionReason ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Text(
                    '${l10n.myListingsRejectionReasonLabel}: ${listing.rejectionReason}',
                    style: AppTypography.caption.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
