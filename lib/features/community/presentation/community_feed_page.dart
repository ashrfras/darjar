import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommunityFeedPage extends ConsumerStatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  ConsumerState<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends ConsumerState<CommunityFeedPage> {
  CommunityPostKind? _filter;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(communityPostsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final wide = MediaQuery.sizeOf(context).width >= 1180;
    final filtered = _filter == null
        ? posts
        : posts.where((post) => post.kind == _filter).toList();

    return Scaffold(
      key: const Key('community-feed-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton(
              key: const Key('create-post-fab'),
              tooltip: AppLocalizations.of(context).newPost,
              onPressed: () => context.go(AppRoutes.createPost),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit_rounded),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _CommunityHero(compact: compact)),
          SliverPersistentHeader(
            pinned: compact,
            delegate: _FilterHeaderDelegate(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
              compact: compact,
              textDirection: Directionality.of(context),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : AppSpacing.xLarge,
              AppSpacing.medium,
              compact ? 12 : AppSpacing.xLarge,
              compact ? 96 : AppSpacing.xxLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Composer(
                              onTap: () => context.go(AppRoutes.createPost),
                            ),
                            const SizedBox(height: AppSpacing.large),
                            if (filtered.isEmpty)
                              _EmptyFilter(
                                onReset: () => setState(() => _filter = null),
                              )
                            else
                              for (final post in filtered) ...[
                                CommunityPostCard(
                                  post: post,
                                  onOpen: () => context.go(
                                    AppRoutes.communityPost(post.id),
                                  ),
                                  onLike: () => ref
                                      .read(communityPostsProvider.notifier)
                                      .toggleLike(post.id),
                                  onSave: () => ref
                                      .read(communityPostsProvider.notifier)
                                      .toggleSaved(post.id),
                                  onVote: (optionId) => ref
                                      .read(communityPostsProvider.notifier)
                                      .vote(post.id, optionId),
                                ),
                                const SizedBox(height: AppSpacing.medium),
                              ],
                          ],
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: AppSpacing.xLarge),
                        const SizedBox(width: 300, child: _CommunitySidebar()),
                      ],
                    ],
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

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : AppSpacing.xLarge,
        compact ? 14 : AppSpacing.xLarge,
        compact ? 16 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.large,
      ),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar
                          ? 'مجتمعك، صوتك، تفاعلك'
                          : 'Your community, your voice',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ar
                          ? 'كل ما يهم سكان إقامتك في مكان واحد'
                          : 'Everything happening in your residence, in one place',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                DarJarButton(
                  key: const Key('create-post-button'),
                  label: AppLocalizations.of(context).newPost,
                  icon: Icons.add_rounded,
                  onPressed: () => context.go(AppRoutes.createPost),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({
    required this.selected,
    required this.onSelected,
    required this.compact,
    required this.textDirection,
  });

  final CommunityPostKind? selected;
  final ValueChanged<CommunityPostKind?> onSelected;
  final bool compact;
  final TextDirection textDirection;

  @override
  double get minExtent => compact ? 84 : 96;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Directionality(
      textDirection: textDirection,
      child: Container(
        color: AppColors.canvas,
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 0),
              children: [
                _FilterChip(
                  key: const Key('category-filter-all'),
                  label: AppLocalizations.of(context).all,
                  icon: Icons.dynamic_feed_outlined,
                  selected: selected == null,
                  color: AppColors.primary,
                  onTap: () => onSelected(null),
                ),
                for (final kind in CommunityPostKind.values) ...[
                  const SizedBox(width: AppSpacing.small),
                  _FilterChip(
                    key: ValueKey('category-filter-${kind.name}'),
                    label: kind.label(context),
                    icon: kind.icon,
                    selected: selected == kind,
                    color: kind.color,
                    onTap: () => onSelected(kind),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.compact != compact ||
        oldDelegate.textDirection != textDirection;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: .10) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          width: 94,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: .35)
                  : AppColors.outline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : AppColors.inkMuted,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? color : AppColors.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return DarJarCard(
      key: const Key('community-composer'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      onTap: onTap,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.person_rounded),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(
                ar
                    ? 'بماذا تريد مشاركة السكان؟'
                    : 'What would you like to share?',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          const Icon(
            Icons.add_circle_rounded,
            color: AppColors.primary,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _CommunitySidebar extends StatelessWidget {
  const _CommunitySidebar();

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      children: [
        DarJarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ar ? 'نبض الإقامة' : 'Residence pulse',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.large),
              _Stat(
                icon: Icons.people_rounded,
                value: '128',
                label: ar ? 'ساكناً' : 'residents',
              ),
              const SizedBox(height: AppSpacing.medium),
              _Stat(
                icon: Icons.forum_rounded,
                value: '24',
                label: ar ? 'تفاعلاً هذا الأسبوع' : 'interactions this week',
              ),
              const SizedBox(height: AppSpacing.medium),
              _Stat(
                icon: Icons.event_available_rounded,
                value: '2',
                label: ar ? 'موعدين قادمين' : 'upcoming events',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        DarJarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary, size: 30),
              const SizedBox(height: AppSpacing.small),
              Text(
                ar ? 'مساحة خاصة بسكان الإقامة' : 'Private to your residence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                ar
                    ? 'كن ودوداً، واضحاً، واحترم خصوصية جيرانك.'
                    : 'Be kind, clear, and respect your neighbors’ privacy.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.small),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 5),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return DarJarCard(
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 44, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.medium),
          Text(
            ar ? 'لا توجد منشورات في هذه الفئة' : 'No posts in this category',
          ),
          TextButton(
            onPressed: onReset,
            child: Text(ar ? 'عرض الكل' : 'Show all'),
          ),
        ],
      ),
    );
  }
}
