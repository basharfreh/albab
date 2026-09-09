import 'package:albab_core/albab_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The full-bleed gallery at the top of the detail screen (brief P8 item 1): a `PageView`
/// of full-resolution images with a `1/15` counter, and back/share/favorite/report icon
/// buttons floating over it. Tapping the image opens [ListingGalleryViewer] at the current
/// page for the full-screen zoomable pager.
class ListingGallery extends StatefulWidget {
  const ListingGallery({
    super.key,
    required this.images,
    required this.isFavorited,
    required this.onBack,
    required this.onShare,
    required this.onFavoriteToggle,
    required this.onReport,
  });

  final List<ListingImage> images;
  final bool isFavorited;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onReport;

  @override
  State<ListingGallery> createState() => _ListingGalleryState();
}

class _ListingGalleryState extends State<ListingGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingGalleryViewer(images: widget.images, initialIndex: _page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = widget.images;

    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const ColoredBox(
              color: AppColors.background,
              child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 48),
            )
          else
            GestureDetector(
              onTap: () => _openViewer(context),
              child: PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => CachedNetworkImage(
                  imageUrl: images[index].image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ColoredBox(color: AppColors.background),
                  errorWidget: (context, url, error) => const ColoredBox(
                    color: AppColors.background,
                    child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GalleryIconButton(
                    icon: Icons.arrow_back,
                    tooltip: l10n.commonBack,
                    onTap: widget.onBack,
                  ),
                  Row(
                    children: [
                      _GalleryIconButton(
                        icon: Icons.share_outlined,
                        tooltip: l10n.commonShare,
                        onTap: widget.onShare,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _GalleryIconButton(
                        icon: widget.isFavorited ? Icons.favorite : Icons.favorite_border,
                        iconColor: widget.isFavorited ? AppColors.danger : Colors.white,
                        tooltip: l10n.accountFavorites,
                        onTap: widget.onFavoriteToggle,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _GalleryOverflowButton(onReport: widget.onReport, tooltip: l10n.commonMore),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (images.isNotEmpty)
            Positioned(
              bottom: AppSpacing.md,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${_page + 1}/${images.length}',
                      style: AppTypography.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryIconButton extends StatelessWidget {
  const _GalleryIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, color: iconColor, size: AppIconSizes.navAndList),
          ),
        ),
      ),
    );
  }
}

/// The floating overflow (⋮) icon — brief P8 item 6: report lives behind it. The single
/// menu item today; a natural place for future per-listing actions to land.
class _GalleryOverflowButton extends StatelessWidget {
  const _GalleryOverflowButton({required this.onReport, required this.tooltip});

  final VoidCallback onReport;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      // A concrete type param (not `PopupMenuButton<void>`) — `Navigator.pop<T>` behaves
      // oddly with `void` as the type argument.
      child: PopupMenuButton<String>(
        tooltip: tooltip,
        icon: const Icon(Icons.more_vert, color: Colors.white, size: AppIconSizes.navAndList),
        onSelected: (_) => onReport(),
        itemBuilder: (context) => [
          PopupMenuItem<String>(value: 'report', child: Text(l10n.listingReport)),
        ],
      ),
    );
  }
}

/// The full-screen zoomable pager (brief P8 item 1) opened by tapping the gallery.
/// `InteractiveViewer` per page needs no extra package beyond what brief §7 already lists.
class ListingGalleryViewer extends StatefulWidget {
  const ListingGalleryViewer({super.key, required this.images, required this.initialIndex});

  final List<ListingImage> images;
  final int initialIndex;

  @override
  State<ListingGalleryViewer> createState() => _ListingGalleryViewerState();
}

class _ListingGalleryViewerState extends State<ListingGalleryViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.images[index].image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GalleryIconButton(
                    icon: Icons.close,
                    tooltip: AppLocalizations.of(context)!.commonBack,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${_page + 1}/${widget.images.length}',
                      style: AppTypography.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
