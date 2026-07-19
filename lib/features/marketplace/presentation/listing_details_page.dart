import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/marketplace/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ListingDetailsPage extends ConsumerWidget {
  const ListingDetailsPage({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(marketplaceListingsProvider);
    final listing = ref
        .read(marketplaceListingsProvider.notifier)
        .find(listingId);
    final localizations = AppLocalizations.of(context);

    if (listing == null) {
      return Center(child: Text(localizations.listingNotFound));
    }

    return SingleChildScrollView(
      key: const Key('listing-details-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton.filledTonal(
                  tooltip: localizations.back,
                  onPressed: () => context.go(AppRoutes.marketplace),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.marketplaceSoft,
                            Color(0xFFC7E9DB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Icon(
                        _detailsIcon(listing),
                        size: 116,
                        color: AppColors.marketplace,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        DarJarBadge(
                          label: _detailsTypeLabel(localizations, listing.type),
                          tone: DarJarBadgeTone.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      listing.priceLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.marketplace,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      listing.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    const Divider(),
                    const SizedBox(height: AppSpacing.large),
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person_rounded)),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.seller,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                listing.timeLabel,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    DarJarButton(
                      label: localizations.contactSeller,
                      icon: Icons.chat_bubble_outline_rounded,
                      expanded: true,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _detailsIcon(MarketplaceListing listing) {
  if (listing.id == 'office-chair') return Icons.chair_alt_rounded;
  if (listing.id == 'books') return Icons.auto_stories_rounded;
  return Icons.inventory_2_outlined;
}

String _detailsTypeLabel(AppLocalizations localizations, ListingType type) {
  return switch (type) {
    ListingType.offer => localizations.offer,
    ListingType.giveAway => localizations.giveAway,
    ListingType.request => localizations.request,
  };
}
