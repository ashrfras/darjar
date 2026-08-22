import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:darjar/features/directory/presentation/service_category_icon.dart';
import 'package:darjar/features/directory/presentation/service_phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DirectoryProfilePage extends ConsumerWidget {
  const DirectoryProfilePage({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(directoryEntriesProvider);
    final entry = ref.read(directoryEntriesProvider.notifier).find(entryId);
    final localizations = AppLocalizations.of(context);
    if (entry == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        children: [
          DarJarSubpageHeader(fallbackLocation: AppRoutes.directory),
          const SizedBox(height: AppSpacing.large),
          Center(child: Text(localizations.directoryProfileNotFound)),
        ],
      );
    }

    final categories =
        ref.watch(serviceCategoriesProvider).value ?? const <ServiceCategory>[];
    final category = categories
        .where((category) => category.id == entry.categoryId)
        .firstOrNull;
    final languageCode = Localizations.localeOf(context).languageCode;
    final serviceTypes = category?.subcategories
        .where((subcategory) => entry.subcategoryIds.contains(subcategory.id))
        .map((subcategory) => subcategory.localizedName(languageCode))
        .toList();
    final compact = MediaQuery.sizeOf(context).width < 600;
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final canEdit =
        entry.createdBy.isNotEmpty && entry.createdBy == currentUser?.uid;
    return SingleChildScrollView(
      key: const Key('directory-profile-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 96 : AppSpacing.xLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(fallbackLocation: AppRoutes.directory),
              const SizedBox(height: AppSpacing.small),
              DarJarCard(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          child: Icon(
                            serviceCategoryIcon(entry.categoryId),
                            size: 58,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          entry.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        if (serviceTypes?.isNotEmpty ?? false) ...[
                          Text(
                            serviceTypes!.join(' · '),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.small),
                        ],
                        Text(
                          entry.profession,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.xLarge,
                          runSpacing: AppSpacing.medium,
                          children: [
                            _Metric(
                              value: entry.score.toStringAsFixed(1),
                              label: localizations.recommendationScore,
                              icon: Icons.star_rounded,
                            ),
                            _Metric(
                              value: '${entry.recommendationCount}',
                              label: localizations.recommendations,
                              icon: Icons.thumb_up_alt_rounded,
                            ),
                            _Metric(
                              value: '${entry.localRecommendationCount}',
                              label: localizations.fromYourResidence,
                              icon: Icons.apartment_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xLarge),
                        Row(
                          children: [
                            Expanded(
                              child: DarJarButton(
                                label: localizations.call,
                                icon: Icons.call_outlined,
                                onPressed: () =>
                                    _call(context, ref, entry.phone),
                                expanded: true,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: DarJarButton(
                                key: const Key('recommend-entry-button'),
                                label: localizations.recommend,
                                icon: Icons.thumb_up_alt_outlined,
                                variant: DarJarButtonVariant.secondary,
                                onPressed: () => _showRecommendationSheet(
                                  context,
                                  ref,
                                  entry,
                                ),
                                expanded: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: AppColors.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            DarJarPhoneNumber(entry.phone),
                          ],
                        ),
                        if (entry.neighborhood.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 17,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  entry.neighborhood,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (canEdit)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          key: const Key('edit-service-button'),
                          tooltip: localizations.editService,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () =>
                              context.push(AppRoutes.editService(entry.id)),
                        ),
                      ),
                  ],
                ),
              ),
              if (entry.workedResidences.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.large),
                _ProfileSection(
                  title: localizations.workedInResidences,
                  icon: Icons.apartment_outlined,
                  child: Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      for (final residence in entry.workedResidences)
                        Chip(
                          avatar: const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            _residenceLabel(localizations, residence),
                          ),
                          backgroundColor: AppColors.primarySoft,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              _ProfileSection(
                title: localizations.recentReviews,
                icon: Icons.chat_bubble_outline_rounded,
                child: entry.reviews.isEmpty
                    ? Text(
                        localizations.noReviewsYet,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < entry.reviews.length;
                            index++
                          ) ...[
                            _ReviewTile(review: entry.reviews[index]),
                            if (index != entry.reviews.length - 1)
                              const Divider(),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.large),
              Container(
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: Text(localizations.cityProfileTrustNotice)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRecommendationSheet(
    BuildContext context,
    WidgetRef ref,
    DirectoryEntry entry,
  ) async {
    var comment = '';
    final localizations = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xLarge,
          AppSpacing.xLarge,
          AppSpacing.xLarge,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.xLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.recommendEntry(entry.name),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(localizations.recommendationPrompt),
            const SizedBox(height: AppSpacing.large),
            TextField(
              key: const Key('recommendation-comment'),
              onChanged: (value) => comment = value,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: localizations.recommendationHint,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            DarJarButton(
              key: const Key('submit-recommendation-button'),
              label: localizations.publishRecommendation,
              icon: Icons.thumb_up_alt_outlined,
              expanded: true,
              onPressed: () async {
                final trimmedComment = comment.trim();
                if (trimmedComment.isEmpty) return;
                try {
                  await ref
                      .read(directoryEntriesProvider.notifier)
                      .recommend(id: entry.id, comment: trimmedComment);
                } on DirectoryRecommendationFailure {
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'تعذّر نشر التوصية.'
                            : 'Could not publish the recommendation.',
                      ),
                    ),
                  );
                  return;
                }
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.recommendationPublished),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context, WidgetRef ref, String phone) async {
    try {
      final launched = await ref.read(servicePhoneLauncherProvider)(phone);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).callFailed)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).callFailed)),
        );
      }
    }
  }

  String _residenceLabel(AppLocalizations localizations, String residenceName) {
    final normalized = residenceName.trim();
    if (normalized.startsWith('إقامة ') || normalized.endsWith(' Residence')) {
      return normalized;
    }
    return localizations.residenceDisplayName(normalized);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          child,
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final DirectoryReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarJarUserAvatar(
            userId: review.userId,
            name: review.author,
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.author,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      review.timeLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                Text(
                  review.residence,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 5),
                Text(review.comment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
