import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
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

    return Scaffold(
      key: const Key('marketplace-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: MediaQuery.sizeOf(context).width < 600
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
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarJarPageHeader(
                  title: localizations.marketplace,
                  description: localizations.marketplacePageDescription,
                  action: MediaQuery.sizeOf(context).width >= 600
                      ? DarJarButton(
                          key: const Key('create-listing-button'),
                          label: localizations.newListing,
                          icon: Icons.add_rounded,
                          onPressed: () => context.go(AppRoutes.createListing),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.xLarge),
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
    return DarJarCard(
      onTap: () => context.go(AppRoutes.listingDetails(listing.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.marketplaceSoft,
                  AppColors.marketplace.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              _listingIcon(listing),
              size: 76,
              color: AppColors.marketplace,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Row(
            children: [
              Expanded(
                child: Text(
                  listing.seller,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              DarJarBadge(
                label: _typeLabel(localizations, listing.type),
                tone: DarJarBadgeTone.success,
              ),
            ],
          ),
          Text(
            listing.timeLabel,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.small),
          Text(
            listing.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            listing.priceLabel,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.marketplace),
          ),
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
