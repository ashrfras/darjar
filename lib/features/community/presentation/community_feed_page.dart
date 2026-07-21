import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum CommunityFeedFilter { all, official, mine, saved }

class CommunityFeedPage extends ConsumerStatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  ConsumerState<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends ConsumerState<CommunityFeedPage> {
  CommunityFeedFilter _filter = CommunityFeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(communityPostsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final wide = MediaQuery.sizeOf(context).width >= 1180;
    final filtered = posts.where((post) {
      return switch (_filter) {
        CommunityFeedFilter.all => true,
        CommunityFeedFilter.official =>
          post.kind == CommunityPostKind.announcement,
        CommunityFeedFilter.mine => post.isCurrentUser,
        CommunityFeedFilter.saved => post.isSaved,
      };
    }).toList();

    return Scaffold(
      key: const Key('community-feed-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? _CreatePostFloatingButton(
              key: const Key('create-post-fab'),
              onPressed: () => context.go(AppRoutes.createPost),
            )
          : null,
      body: CustomScrollView(
        slivers: [
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
                                onReset: () => setState(
                                  () => _filter = CommunityFeedFilter.all,
                                ),
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

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({
    required this.selected,
    required this.onSelected,
    required this.compact,
    required this.textDirection,
  });

  final CommunityFeedFilter selected;
  final ValueChanged<CommunityFeedFilter> onSelected;
  final bool compact;
  final TextDirection textDirection;

  @override
  double get minExtent => 55;

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
        padding: const EdgeInsets.only(top: 12, bottom: 5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              key: const Key('community-filter-list'),
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 0),
              children: [
                for (final filter in CommunityFeedFilter.values) ...[
                  if (filter != CommunityFeedFilter.all)
                    const SizedBox(width: 6),
                  _FilterChip(
                    key: ValueKey('community-filter-${filter.name}'),
                    label: filter.label(context),
                    icon: filter.icon,
                    selected: selected == filter,
                    color: AppColors.primary,
                    onTap: () => onSelected(filter),
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

extension on CommunityFeedFilter {
  String label(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return switch (this) {
      CommunityFeedFilter.all => ar ? 'الكل' : 'All',
      CommunityFeedFilter.official =>
        ar ? 'المنشورات الرسمية' : 'Official posts',
      CommunityFeedFilter.mine => ar ? 'منشوراتي الشخصية' : 'My posts',
      CommunityFeedFilter.saved => ar ? 'المنشورات المحفوظة' : 'Saved posts',
    };
  }

  IconData get icon => switch (this) {
    CommunityFeedFilter.all => Icons.dynamic_feed_outlined,
    CommunityFeedFilter.official => Icons.verified_outlined,
    CommunityFeedFilter.mine => Icons.person_outline_rounded,
    CommunityFeedFilter.saved => Icons.bookmark_border_rounded,
  };
}

class _CreatePostFloatingButton extends StatelessWidget {
  const _CreatePostFloatingButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).newPost,
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
            child: Icon(Icons.edit_rounded, color: Colors.white, size: 25),
          ),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: .35)
                  : AppColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : AppColors.inkMuted,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10,
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
