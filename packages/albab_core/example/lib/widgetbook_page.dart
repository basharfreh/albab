import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A gallery of every widget `albab_core` ships (brief P4, item 7) so P5+ can see them
/// running, in both locales, before building any real screen. Every *product* string on
/// this page is localized through [AppLocalizations] and every color comes from
/// [AppColors]/[AppPropertyTypeColors] — the section headings below (`_Section(title: ...)`)
/// are the one exception: they're gallery-only developer labels (like a Storybook category
/// name), not app copy that will ever render in the real product, so they aren't ARB keys.
class WidgetbookPage extends ConsumerStatefulWidget {
  const WidgetbookPage({super.key});

  @override
  ConsumerState<WidgetbookPage> createState() => _WidgetbookPageState();
}

class _WidgetbookPageState extends ConsumerState<WidgetbookPage> {
  int _bedrooms = 2;
  RangeValues _priceRange = const RangeValues(50000, 150000);
  PropertyType? _selectedType = PropertyType.apartment;
  bool _sampleFavorited = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    final sampleListing = Listing(
      id: 1,
      title: 'شقة واسعة في حي الحسين',
      neighborhoodName: 'حي الحسين',
      landmark: 'قرب جامع النور',
      price: '85000.00',
      isNegotiable: true,
      areaSqm: '120.00',
      bedrooms: 3,
      bathrooms: 2,
      imagesCount: 5,
      purpose: ListingPurpose.sale,
      propertyType: PropertyType.apartment,
      isFeatured: true,
      isFavorited: _sampleFavorited,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: locale.languageCode == 'ar' ? 'English' : 'العربية',
            icon: const Icon(Icons.language),
            onPressed: () {
              final next = locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
              ref.read(localeProvider.notifier).setLocale(next);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: 'Buttons',
            children: [
              PrimaryButton(label: l10n.authLogin, onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: l10n.commonLoading, isLoading: true, onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(label: l10n.authRegister, onPressed: () {}),
            ],
          ),
          _Section(
            title: 'Text field',
            children: [AppTextField(label: l10n.authPhone, hint: '+963 987 654 321')],
          ),
          _Section(
            title: 'Dropdown',
            children: [
              AppDropdown<PropertyType>(
                label: l10n.filterPropertyType,
                value: _selectedType,
                items: PropertyType.values,
                labelBuilder: (type) => type.label(l10n),
                onChanged: (value) => setState(() => _selectedType = value),
              ),
            ],
          ),
          _Section(
            title: 'Counter field',
            children: [
              CounterField(
                label: l10n.wizardBedroomsCount,
                value: _bedrooms,
                onChanged: (value) => setState(() => _bedrooms = value),
              ),
            ],
          ),
          _Section(
            title: 'Price range slider',
            children: [
              PriceRangeSlider(
                min: 0,
                max: 300000,
                values: _priceRange,
                labelBuilder: (value) => Money.format(value.toStringAsFixed(0)),
                onChanged: (value) => setState(() => _priceRange = value),
              ),
            ],
          ),
          _Section(
            title: 'Section header',
            children: [
              SectionHeader(
                title: l10n.dashLatestListings,
                actionLabel: l10n.commonViewAll,
                onAction: () {},
              ),
            ],
          ),
          _Section(
            title: 'Badges',
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppBadge(
                    label: l10n.listingStatusPublished,
                    color: AppColors.primary,
                    background: AppColors.primaryTint,
                  ),
                  AppBadge(
                    label: l10n.listingStatusRejected,
                    color: AppColors.danger,
                    background: AppColors.background,
                  ),
                  const AppBadge.count(3),
                ],
              ),
            ],
          ),
          _Section(
            title: 'Empty state',
            children: [SizedBox(height: 220, child: EmptyState(message: l10n.emptyStateDefaultTitle))],
          ),
          _Section(
            title: 'Error state',
            children: [
              SizedBox(
                height: 220,
                child: ErrorState(message: l10n.errorNetwork, onRetry: () {}),
              ),
            ],
          ),
          _Section(
            title: 'Loading skeleton',
            children: const [
              // Row, not the bare widget: `_Section`'s stretched Column would otherwise
              // force this to full width, hiding its actual (explicit) 160px width.
              Row(children: [LoadingSkeleton(width: 160, height: 16)]),
              SizedBox(height: AppSpacing.sm),
              ListingCardSkeleton(),
            ],
          ),
          _Section(
            title: 'Property stats row',
            children: const [
              PropertyStatsRow(areaSqm: '120.00', bedrooms: 3, bathrooms: 2),
            ],
          ),
          _Section(
            title: 'Listing card — vertical (results list / favorites grid)',
            children: [
              SizedBox(
                width: 280,
                child: ListingCard(
                  listing: sampleListing,
                  onFavoriteToggle: () => setState(() => _sampleFavorited = !_sampleFavorited),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Listing card — horizontal (map peek card)',
            children: [
              ListingCard(
                listing: sampleListing,
                layout: ListingCardLayout.horizontal,
                onFavoriteToggle: () => setState(() => _sampleFavorited = !_sampleFavorited),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
