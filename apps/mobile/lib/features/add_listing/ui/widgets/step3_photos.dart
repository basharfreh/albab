import 'dart:async';
import 'dart:io';

import 'package:albab_core/albab_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/add_listing_repository.dart';
import '../../data/image_picker_service.dart';
import '../../data/wizard_draft.dart';

const _maxImages = 15;

/// Brief P9 item 4 — up to 15 photos, per-image upload progress, retry on failure, drag to
/// reorder, "تعيين كصورة رئيسية", delete with undo. Every picked file uploads immediately
/// (optimistic entry in [wizardDraftProvider] first, filled in once the request resolves) so
/// step 4's review always shows real, already-uploaded images.
class Step3Photos extends ConsumerStatefulWidget {
  const Step3Photos({super.key});

  @override
  ConsumerState<Step3Photos> createState() => _Step3PhotosState();
}

class _Step3PhotosState extends ConsumerState<Step3Photos> {
  /// Keyed by the deleted image's server id — a delete removes the entry from
  /// [wizardDraftProvider] immediately (so the grid updates right away) but the real `DELETE`
  /// call is deferred behind this timer so "تراجع" can cancel it (brief P9 item 4).
  final Map<int, Timer> _pendingDeletes = {};
  int? _listingId;

  @override
  void dispose() {
    // A pending delete that hasn't fired yet when this step is left (wizard closed, app
    // backgrounded) must still happen — losing track of it would leave an orphaned image on
    // the server that the user believes they deleted.
    final listingId = _listingId;
    if (listingId != null) {
      for (final entry in _pendingDeletes.entries) {
        entry.value.cancel();
        ref
            .read(addListingRepositoryProvider)
            .deleteImage(listingId, entry.key);
      }
    }
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - ref.read(wizardDraftProvider).images.length;
    if (remaining <= 0) {
      _showMaxReached();
      return;
    }
    final picked = await ref
        .read(imagePickerServiceProvider)
        .pickFromGallery(remainingSlots: remaining);
    for (final file in picked) {
      await _addAndUpload(file);
    }
  }

  Future<void> _pickFromCamera() async {
    if (ref.read(wizardDraftProvider).images.length >= _maxImages) {
      _showMaxReached();
      return;
    }
    final file = await ref.read(imagePickerServiceProvider).pickFromCamera();
    if (file != null) await _addAndUpload(file);
  }

  void _showMaxReached() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.wizardPhotosMaxReached)));
  }

  Future<void> _addAndUpload(PickedImage file) async {
    final notifier = ref.read(wizardDraftProvider.notifier);
    notifier.addImage(WizardImageEntry(localPath: file.path, uploading: true));
    await _upload(path: file.path, filename: file.name);
  }

  Future<void> _upload({required String path, required String filename}) async {
    final notifier = ref.read(wizardDraftProvider.notifier);
    final listingId = ref.read(wizardDraftProvider).listingId!;
    notifier.updateImageByPath(
      path,
      (e) => e.copyWith(uploading: true, error: () => null),
    );
    try {
      final image = await ref
          .read(addListingRepositoryProvider)
          .uploadImage(
            listingId,
            path: path,
            filename: filename,
            onProgress: (p) => notifier.updateImageByPath(
              path,
              (e) => e.copyWith(progress: p),
            ),
          );
      notifier.updateImageByPath(
        path,
        (e) => e.copyWith(
          remoteId: () => image.id,
          thumbnailUrl: () => image.thumbnail ?? image.image,
          isCover: image.isCover,
          uploading: false,
        ),
      );
    } on ApiException {
      notifier.updateImageByPath(
        path,
        (e) => e.copyWith(uploading: false, error: () => 'upload_failed'),
      );
    }
  }

  void _deleteAt(int index) {
    final draft = ref.read(wizardDraftProvider);
    final entry = draft.images[index];
    final notifier = ref.read(wizardDraftProvider.notifier);
    notifier.removeImageAt(index);

    final remoteId = entry.remoteId;
    if (remoteId == null) {
      return; // never reached the server — nothing to undo server-side.
    }

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.wizardPhotoDeleted),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () {
            _pendingDeletes.remove(remoteId)?.cancel();
            final current = ref.read(wizardDraftProvider).images.length;
            ref
                .read(wizardDraftProvider.notifier)
                .insertImageAt(index.clamp(0, current), entry);
          },
        ),
      ),
    );
    _pendingDeletes[remoteId] = Timer(const Duration(seconds: 4), () {
      _pendingDeletes.remove(remoteId);
      ref.read(addListingRepositoryProvider).deleteImage(_listingId!, remoteId);
    });
  }

  Future<void> _setCover(WizardImageEntry entry) async {
    final path = entry.localPath;
    if (path == null) {
      return; // no local bytes to re-upload — see WizardImageEntry doc.
    }
    final notifier = ref.read(wizardDraftProvider.notifier);
    final listingId = ref.read(wizardDraftProvider).listingId!;
    notifier.updateImageByPath(path, (e) => e.copyWith(uploading: true));
    try {
      final updated = await ref
          .read(addListingRepositoryProvider)
          .setCoverPhoto(listingId, entry);
      final images = ref.read(wizardDraftProvider).images.map((e) {
        if (e.localPath == path) {
          return e.copyWith(
            remoteId: () => updated.id,
            isCover: true,
            uploading: false,
          );
        }
        return e.copyWith(isCover: false);
      }).toList();
      notifier.setImages(images);
    } on ApiException {
      notifier.updateImageByPath(
        path,
        (e) => e.copyWith(uploading: false, error: () => 'cover_failed'),
      );
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    final images = [...ref.read(wizardDraftProvider).images];
    final moved = images.removeAt(oldIndex);
    images.insert(newIndex, moved);
    ref.read(wizardDraftProvider.notifier).setImages(images);

    final order = images
        .where((e) => e.remoteId != null)
        .map((e) => e.remoteId!)
        .toList();
    if (order.isEmpty) return;
    ref.read(addListingRepositoryProvider).reorderImages(_listingId!, order);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(wizardDraftProvider);
    _listingId = draft.listingId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.wizardPhotosCount(draft.images.length),
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.wizardTakePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    onPressed: draft.images.length >= _maxImages
                        ? null
                        : _pickFromCamera,
                  ),
                  IconButton(
                    tooltip: l10n.wizardPickFromGallery,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: draft.images.length >= _maxImages
                        ? null
                        : _pickFromGallery,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: draft.images.isEmpty
              ? EmptyState(
                  icon: Icons.add_photo_alternate_outlined,
                  title: l10n.wizardPhotosRequired,
                  actionLabel: l10n.wizardPickFromGallery,
                  onAction: _pickFromGallery,
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  itemCount: draft.images.length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, index) {
                    final entry = draft.images[index];
                    return _PhotoTile(
                      key: ValueKey(entry.localPath ?? entry.remoteId),
                      entry: entry,
                      onDelete: () => _deleteAt(index),
                      onSetCover: entry.localPath == null || entry.isCover
                          ? null
                          : () => _setCover(entry),
                      onRetry: entry.error == null || entry.localPath == null
                          ? null
                          : () => _upload(
                              path: entry.localPath!,
                              filename: entry.localPath!.split('/').last,
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onSetCover,
    required this.onRetry,
  });

  final WizardImageEntry entry;
  final VoidCallback onDelete;
  final VoidCallback? onSetCover;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.buttonRadius,
              child: SizedBox(
                width: 64,
                height: 64,
                child: _PhotoThumbnail(entry: entry),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: entry.uploading
                  ? LinearProgressIndicator(
                      value: entry.progress == 0 ? null : entry.progress,
                    )
                  : entry.error != null
                  ? Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        TextButton(
                          onPressed: onRetry,
                          child: Text(l10n.commonRetry),
                        ),
                      ],
                    )
                  : entry.isCover
                  ? AppBadge(
                      label: l10n.wizardSetCoverPhoto,
                      color: AppColors.primary,
                      background: AppColors.primaryTint,
                    )
                  : onSetCover == null
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: onSetCover,
                      child: Text(l10n.wizardSetCoverPhoto),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.entry});

  final WizardImageEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.thumbnailUrl;
    if (url != null) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }
    final path = entry.localPath;
    if (path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        // A picked file that's been moved/cleared out from under the app (or, in a widget
        // test, a fake path with no real file behind it) shouldn't crash the tile — just
        // fall back to the same placeholder an entry with no path at all gets.
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: AppColors.background),
      );
    }
    return const ColoredBox(color: AppColors.background);
  }
}
