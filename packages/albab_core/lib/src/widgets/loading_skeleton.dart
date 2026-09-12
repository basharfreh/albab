import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A pulsing gray placeholder box — brief §9/§10: "skeleton, not a bare spinner where a
/// shape is known". No new shimmer package (brief §7 doesn't list one); a simple opacity
/// pulse reads just as clearly as a gradient sweep and needs nothing extra.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Brief P12 item 4: "reduced-motion respected" — a static mid-tone box reads just as
    // clearly as a loading placeholder without the pulse a `disableAnimations` user asked not
    // to see.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(opacity: _opacity.value, child: child),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: widget.borderRadius),
      ),
    );
  }
}

/// A [ListingCard]-shaped skeleton for map/list loading states (brief P6).
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoadingSkeleton(
              width: 88,
              height: 88,
              borderRadius: AppRadius.cardRadius,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  LoadingSkeleton(height: 16, width: 140),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 12, width: 100),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 18, width: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
