import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/marketplace/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MarketplacePage extends ConsumerWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final listings = ref.watch(marketplaceListingsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      key: const Key('marketplace-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              key: const Key('create-listing-fab'),
              backgroundColor: AppColors.marketplace,
              foregroundColor: Colors.white,
              onPressed: () => context.go(AppRoutes.createListing),
              icon: const Icon(Icons.add_rounded),
              label: Text(localizations.newListing),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : AppSpacing.xLarge,
          compact ? 8 : AppSpacing.xLarge,
          compact ? 12 : AppSpacing.xLarge,
          compact ? 96 : AppSpacing.xLarge,
        ),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact) ...[
                  DarJarPageHeader(
                    title: localizations.marketplace,
                    description: localizations.marketplacePageDescription,
                    action: DarJarButton(
                      key: const Key('create-listing-button'),
                      label: localizations.newListing,
                      icon: Icons.add_rounded,
                      onPressed: () => context.go(AppRoutes.createListing),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                ],
                if (compact) ...[
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.createListing),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(localizations.newListing),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.marketplace,
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ابحث في السوق...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _MarketCategories(),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'إعلانات جديدة'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 268,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: listings.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: 178,
                        child: _ListingCard(listing: listings[index]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'خدمات موصى بها'),
                  const SizedBox(height: 8),
                  const _RecommendedServices(),
                ] else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 760 ? 2 : 1;
                      final width = columns == 2
                          ? (constraints.maxWidth - AppSpacing.large) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: AppSpacing.large,
                        runSpacing: AppSpacing.large,
                        children: [
                          for (final listing in listings)
                            SizedBox(
                              width: width,
                              child: _ListingCard(listing: listing),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return DarJarCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go(AppRoutes.listingDetails(listing.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: compact ? 112 : 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.marketplaceSoft,
                  AppColors.marketplace.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.large),
              ),
            ),
            child: Icon(
              _listingIcon(listing),
              size: 76,
              color: AppColors.marketplace,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _typeLabel(localizations, listing.type),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    listing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  listing.priceLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.marketplace,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.timeLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        Text(
          'عرض الكل',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.marketplace),
        ),
      ],
    );
  }
}

class _MarketCategories extends StatelessWidget {
  const _MarketCategories();

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('الكل', Icons.grid_view_rounded),
      ('للبيع', Icons.sell_outlined),
      ('خدمات', Icons.handyman_outlined),
      ('إيجار', Icons.key_outlined),
      ('أدوات', Icons.campaign_outlined),
    ];
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 70,
            decoration: BoxDecoration(
              color: index == 0 ? AppColors.marketplaceSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.$2,
                  size: 22,
                  color: index == 0
                      ? AppColors.marketplace
                      : AppColors.inkMuted,
                ),
                const SizedBox(height: 5),
                Text(
                  category.$1,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecommendedServices extends StatelessWidget {
  const _RecommendedServices();

  @override
  Widget build(BuildContext context) {
    const providers = [
      ('كريم السباك', 'سباكة عامة · تسريبات · سخانات', '4.8'),
      ('نورة للتنظيف', 'تنظيف منازل · شقق · مساحات مشتركة', '4.9'),
      ('أبو طارق كهربائي', 'كهرباء عامة · أعطال · تركيب إنارة', '4.7'),
    ];
    return DarJarCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var index = 0; index < providers.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.marketplaceSoft,
                    foregroundColor: AppColors.marketplace,
                    child: const Icon(Icons.person_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providers[index].$1,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          '★ ${providers[index].$3}  ${providers[index].$2}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () {},
                    icon: const Icon(Icons.call_outlined, size: 18),
                    color: AppColors.marketplace,
                  ),
                ],
              ),
            ),
            if (index != providers.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

IconData _listingIcon(MarketplaceListing listing) {
  if (listing.id == 'office-chair') return Icons.chair_alt_rounded;
  if (listing.id == 'books') return Icons.auto_stories_rounded;
  return Icons.inventory_2_outlined;
}

String _typeLabel(AppLocalizations localizations, ListingType type) {
  return switch (type) {
    ListingType.offer => localizations.offer,
    ListingType.giveAway => localizations.giveAway,
    ListingType.request => localizations.request,
  };
}
