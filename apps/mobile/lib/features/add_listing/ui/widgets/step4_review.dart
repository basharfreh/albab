import 'package:albab_core/albab_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/wizard_draft.dart';

/// Brief P9 item 5 — read-only summary of every field, each section with an edit
/// affordance jumping back to the step that owns it. Submitting itself (`نشر العقار`) is the
/// wizard shell's own bottom button, same as every other step's "التالي" — this widget is
/// display-only.
class Step4Review extends ConsumerWidget {
  const Step4Review({super.key, required this.onEditStep});

  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(wizardDraftProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        _Section(
          title: l10n.wizardStepInfo,
          onEdit: () => onEditStep(0),
          children: [
            Text(draft.title, style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppBadge(
                  label: draft.purpose.label(l10n),
                  color: AppColors.primary,
                  background: AppColors.primaryTint,
                ),
                AppBadge(
                  label: draft.propertyType.label(l10n),
                  color: AppColors.textSecondary,
                  background: AppColors.background,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  Money.format(draft.price ?? '0'),
                  style: AppTypography.section.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (draft.isNegotiable) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.wizardNegotiable, style: AppTypography.caption),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            PropertyStatsRow(
              bedrooms: draft.bedrooms,
              bathrooms: draft.bathrooms,
            ),
            if (draft.description.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(draft.description, style: AppTypography.body),
            ],
          ],
        ),
        _Section(
          title: l10n.wizardStepLocation,
          onEdit: () => onEditStep(1),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: AppIconSizes.inline,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    [
                      if (draft.neighborhoodNameAr != null)
                        draft.neighborhoodNameAr!,
                      if (draft.landmark.trim().isNotEmpty)
                        draft.landmark.trim(),
                    ].join(' - '),
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          ],
        ),
        _Section(
          title: l10n.wizardStepPhotos,
          onEdit: () => onEditStep(2),
          children: [
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: draft.images.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final url = draft.images[index].thumbnailUrl;
                  return ClipRRect(
                    borderRadius: AppRadius.buttonRadius,
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: url == null
                          ? const ColoredBox(color: AppColors.background)
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: title,
              actionLabel: l10n.commonEdit,
              onAction: onEdit,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}
