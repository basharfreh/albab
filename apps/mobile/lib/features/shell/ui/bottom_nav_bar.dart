import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// The five-tab bar from the mockup, RTL-ordered: الرئيسية · الرسائل · [+] · المفضلة ·
/// الحساب, right to left. Built as a plain [Row] rather than [BottomNavigationBar] — `Row`
/// lays its children out starting from the reading-direction start edge (the right in `ar`),
/// so passing tabs in logical order `[home, messages, add, favorites, account]` already
/// produces the mockup's RTL order for free; a stock `BottomNavigationBar` can't host the
/// center tab's raised circular FAB.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, filledIcon: Icons.home, labelKey: _NavLabel.home),
    (icon: Icons.chat_bubble_outline, filledIcon: Icons.chat_bubble, labelKey: _NavLabel.messages),
    null, // center FAB slot
    (icon: Icons.favorite_border, filledIcon: Icons.favorite, labelKey: _NavLabel.favorites),
    (icon: Icons.person_outline, filledIcon: Icons.person, labelKey: _NavLabel.account),
  ];

  String _label(AppLocalizations l10n, _NavLabel key) => switch (key) {
    _NavLabel.home => l10n.navHome,
    _NavLabel.messages => l10n.navMessages,
    _NavLabel.favorites => l10n.navFavorites,
    _NavLabel.account => l10n.navAccount,
  };

  static const _addIndex = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.sheet),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          // A Stack, not a flex child of the Row below: the raised circle is taller than the
          // 64px bar even before its upward offset, so laying it out as a normal Row/Column
          // child overflows. `clipBehavior: Clip.none` lets it paint above the bar instead.
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  for (var index = 0; index < _items.length; index++)
                    Expanded(
                      child: index == _addIndex
                          ? const SizedBox.shrink()
                          : _NavItem(
                              icon: _items[index]!.icon,
                              filledIcon: _items[index]!.filledIcon,
                              label: _label(l10n, _items[index]!.labelKey),
                              selected: currentIndex == index,
                              onTap: () => onTap(index),
                            ),
                    ),
                ],
              ),
              // Only `top` is pinned, so this child's height is unconstrained by the 64px
              // bar (a plain Stack child, or a Positioned pinned on all sides, would still
              // force it into that height and overflow) — it pokes above the bar by design.
              Positioned(
                top: -18,
                child: _AddButton(onTap: () => onTap(_addIndex), label: l10n.navAdd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NavLabel { home, messages, favorites, account }

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? filledIcon : icon, size: AppIconSizes.navAndList, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillRadius,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            child: const Icon(Icons.add, color: AppColors.surface, size: 28),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
