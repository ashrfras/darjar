import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DirectoryPage extends ConsumerStatefulWidget {
  const DirectoryPage({super.key});

  @override
  ConsumerState<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends ConsumerState<DirectoryPage> {
  DirectoryCategory _category = DirectoryCategory.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final entries = ref.watch(directoryEntriesProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final filtered = entries.where((entry) {
      final matchesCategory =
          _category == DirectoryCategory.all || entry.category == _category;
      final normalized = _query.trim().toLowerCase();
      final matchesQuery =
          normalized.isEmpty ||
          entry.name.toLowerCase().contains(normalized) ||
          entry.profession.toLowerCase().contains(normalized) ||
          entry.neighborhood.toLowerCase().contains(normalized);
      return matchesCategory && matchesQuery;
    }).toList();
    final localFavorites = entries
        .where((entry) => entry.localRecommendationCount >= 18)
        .take(3)
        .toList();
    final topCraftspeople =
        filtered
            .where((entry) => entry.category == DirectoryCategory.craftsman)
            .toList()
          ..sort(
            (a, b) => b.localRecommendationCount.compareTo(
              a.localRecommendationCount,
            ),
          );

    return SingleChildScrollView(
      key: const Key('directory-page'),
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
                  const SizedBox(width: AppSpacing.small),
                  IconButton.filledTonal(
                    tooltip: localizations.nearby,
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _CategoryStrip(
                selected: _category,
                onSelected: (category) => setState(() => _category = category),
              ),
              const SizedBox(height: AppSpacing.xLarge),
              if (_query.isNotEmpty || _category != DirectoryCategory.all) ...[
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
                  title: localizations.topRatedCraftspeople,
                  icon: Icons.stars_rounded,
                ),
                const SizedBox(height: AppSpacing.medium),
                DarJarCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < topCraftspeople.length;
                        index++
                      ) ...[
                        _CraftsmanRow(entry: topCraftspeople[index]),
                        if (index != topCraftspeople.length - 1)
                          const Divider(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xLarge),
                _SectionTitle(
                  title: localizations.exploreNearby,
                  icon: Icons.near_me_outlined,
                ),
                const SizedBox(height: AppSpacing.medium),
                _EntryGrid(
                  entries: entries
                      .where(
                        (entry) =>
                            entry.category != DirectoryCategory.craftsman,
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.selected, required this.onSelected});

  final DirectoryCategory selected;
  final ValueChanged<DirectoryCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categories = [
      (DirectoryCategory.all, localizations.all, Icons.grid_view_rounded),
      (
        DirectoryCategory.craftsman,
        localizations.craftspeople,
        Icons.handyman_outlined,
      ),
      (
        DirectoryCategory.restaurant,
        localizations.restaurants,
        Icons.restaurant_outlined,
      ),
      (DirectoryCategory.cafe, localizations.cafes, Icons.local_cafe_outlined),
      (
        DirectoryCategory.pharmacy,
        localizations.pharmacies,
        Icons.medication_outlined,
      ),
      (
        DirectoryCategory.facility,
        localizations.nearbyFacilities,
        Icons.apartment_outlined,
      ),
    ];
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = item.$1 == selected;
          return Material(
            color: isSelected ? AppColors.primarySoft : AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: InkWell(
              key: ValueKey('directory-category-${item.$1.name}'),
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
                      _categoryIcon(entry.category),
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
                        child: Icon(_categoryIcon(entry.category)),
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

IconData _categoryIcon(DirectoryCategory category) {
  return switch (category) {
    DirectoryCategory.all => Icons.grid_view_rounded,
    DirectoryCategory.craftsman => Icons.handyman_rounded,
    DirectoryCategory.restaurant => Icons.restaurant_rounded,
    DirectoryCategory.cafe => Icons.local_cafe_rounded,
    DirectoryCategory.pharmacy => Icons.medication_rounded,
    DirectoryCategory.facility => Icons.apartment_rounded,
  };
}
