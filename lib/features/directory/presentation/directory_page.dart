import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DirectoryPage extends ConsumerStatefulWidget {
  const DirectoryPage({super.key});

  @override
  ConsumerState<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends ConsumerState<DirectoryPage> {
  String? _categoryId;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final entries = ref.watch(directoryEntriesProvider);
    final categories =
        ref.watch(serviceCategoriesProvider).value ?? const <ServiceCategory>[];
    final languageCode = Localizations.localeOf(context).languageCode;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final filtered = entries.where((entry) {
      final matchesCategory =
          _categoryId == null || entry.categoryId == _categoryId;
      final normalized = _query.trim().toLowerCase();
      final category = categories
          .where((category) => category.id == entry.categoryId)
          .firstOrNull;
      final subcategory = category?.subcategories
          .where((subcategory) => subcategory.id == entry.subcategoryId)
          .firstOrNull;
      final matchesQuery =
          normalized.isEmpty ||
          entry.name.toLowerCase().contains(normalized) ||
          entry.profession.toLowerCase().contains(normalized) ||
          entry.neighborhood.toLowerCase().contains(normalized) ||
          (category
                  ?.localizedLongName(languageCode)
                  .toLowerCase()
                  .contains(normalized) ??
              false) ||
          (subcategory
                  ?.localizedName(languageCode)
                  .toLowerCase()
                  .contains(normalized) ??
              false);
      return matchesCategory && matchesQuery;
    }).toList();
    final localFavorites = entries
        .where((entry) => entry.localRecommendationCount >= 18)
        .take(3)
        .toList();
    final topServices =
        filtered.where((entry) => entry.workedResidences.isNotEmpty).toList()
          ..sort(
            (a, b) => b.localRecommendationCount.compareTo(
              a.localRecommendationCount,
            ),
          );
    final highlightedServiceIds = topServices.map((entry) => entry.id).toSet();
    final otherServices = entries
        .where((entry) => !highlightedServiceIds.contains(entry.id))
        .toList();

    return Scaffold(
      key: const Key('directory-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? _AddServiceFloatingButton(
              key: const Key('add-service-fab'),
              onPressed: () => context.go(AppRoutes.createService),
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
                    title: localizations.directory,
                    description: localizations.directoryPageDescription,
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('directory-search'),
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: localizations.directorySearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: compact,
                        ),
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: AppSpacing.small),
                      IconButton.filledTonal(
                        key: const Key('add-service-button'),
                        tooltip: localizations.addService,
                        onPressed: () => context.go(AppRoutes.createService),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                _CategoryStrip(
                  categories: categories,
                  selectedCategoryId: _categoryId,
                  onSelected: (categoryId) =>
                      setState(() => _categoryId = categoryId),
                ),
                const SizedBox(height: AppSpacing.xLarge),
                if (entries.isEmpty) ...[
                  _EmptyResults(message: localizations.noServicesYet),
                ] else if (_query.isNotEmpty || _categoryId != null) ...[
                  _SectionTitle(
                    title: localizations.searchResults,
                    icon: Icons.search_rounded,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (filtered.isEmpty)
                    _EmptyResults(message: localizations.noDirectoryResults)
                  else
                    _EntryGrid(entries: filtered),
                ] else ...[
                  _SectionTitle(
                    title: localizations.recommendedByNeighbors,
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SizedBox(
                    height: compact ? 248 : 272,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: localFavorites.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: compact ? 190 : 250,
                        child: _FeaturedCard(entry: localFavorites[index]),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  _SectionTitle(
                    title: localizations.topRatedServices,
                    icon: Icons.stars_rounded,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  DarJarCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < topServices.length;
                          index++
                        ) ...[
                          _CraftsmanRow(entry: topServices[index]),
                          if (index != topServices.length - 1) const Divider(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  _SectionTitle(
                    title: localizations.exploreOtherServices,
                    icon: Icons.near_me_outlined,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _EntryGrid(entries: otherServices),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddServiceFloatingButton extends StatelessWidget {
  const _AddServiceFloatingButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).addService,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: Colors.white.withValues(alpha: .28)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330F766E),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 27),
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<ServiceCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final items = <(String?, String, IconData)>[
      (null, localizations.all, Icons.grid_view_rounded),
      for (final category in categories)
        (
          category.id,
          category.localizedShortName(languageCode),
          _categoryIcon(category.id),
        ),
    ];
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.$1 == selectedCategoryId;
          return Material(
            color: isSelected ? AppColors.primarySoft : AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: InkWell(
              key: ValueKey('directory-category-${item.$1 ?? 'all'}'),
              onTap: () => onSelected(item.$1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: SizedBox(
                width: 86,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inkMuted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(
          AppLocalizations.of(context).viewAll,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.entry});

  final DirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go(AppRoutes.directoryProfile(entry.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primarySoft, Color(0xFFCFE8DF)],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _categoryIcon(entry.categoryId),
                      size: 68,
                      color: AppColors.primary,
                    ),
                  ),
                  PositionedDirectional(
                    start: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(
                        AppLocalizations.of(context).recommended,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  entry.profession,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                _TrustLine(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CraftsmanRow extends StatelessWidget {
  const _CraftsmanRow({required this.entry});

  final DirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('directory-entry-${entry.id}'),
      onTap: () => context.go(AppRoutes.directoryProfile(entry.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.person_rounded, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    entry.profession,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  _TrustLine(entry: entry),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: AppLocalizations.of(context).phone,
              onPressed: () {},
              color: AppColors.primary,
              icon: const Icon(Icons.call_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.entry});

  final DirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5A623)),
        Text(
          entry.score.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(
          '(${entry.recommendationCount})',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          AppLocalizations.of(
            context,
          ).localRecommendations(entry.localRecommendationCount),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.entries});

  final List<DirectoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.medium) /
            columns;
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            for (final entry in entries)
              SizedBox(
                width: width,
                child: DarJarCard(
                  onTap: () => context.go(AppRoutes.directoryProfile(entry.id)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        child: Icon(_categoryIcon(entry.categoryId)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              entry.neighborhood,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            _TrustLine(entry: entry),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String categoryId) {
  return switch (categoryId) {
    'home-maintenance' => Icons.handyman_rounded,
    'appliances-equipment' => Icons.home_repair_service_rounded,
    'cleaning-care' => Icons.cleaning_services_rounded,
    'transport-delivery' => Icons.local_shipping_rounded,
    'personal-family' => Icons.family_restroom_rounded,
    'other-services' => Icons.more_horiz_rounded,
    _ => Icons.miscellaneous_services_rounded,
  };
}
