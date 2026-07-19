import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommunityFeedPage extends ConsumerWidget {
  const CommunityFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final posts = ref.watch(communityPostsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      key: const Key('community-feed-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              key: const Key('create-post-fab'),
              onPressed: () => context.go(AppRoutes.createPost),
              icon: const Icon(Icons.add_rounded),
              label: Text(localizations.newPost),
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
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact) ...[
                  DarJarPageHeader(
                    title: localizations.community,
                    description: localizations.communityFeedDescription,
                    action: DarJarButton(
                      key: const Key('create-post-button'),
                      label: localizations.newPost,
                      icon: Icons.add_rounded,
                      onPressed: () => context.go(AppRoutes.createPost),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                ],
                for (final post in posts) ...[
                  _PostCard(post: post),
                  const SizedBox(height: AppSpacing.medium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isAnnouncement = post.kind == CommunityPostKind.announcement;
    final accent = isAnnouncement ? AppColors.services : AppColors.community;

    return DarJarCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: accent.withValues(alpha: 0.11),
                foregroundColor: accent,
                child: Icon(
                  isAnnouncement
                      ? Icons.water_drop_rounded
                      : Icons.person_rounded,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.author,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        if (isAnnouncement)
                          DarJarBadge(
                            label: localizations.officialAnnouncement,
                            tone: DarJarBadgeTone.info,
                          ),
                      ],
                    ),
                    Text(
                      post.timeLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isAnnouncement)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PostCopy(post: post)),
                const SizedBox(width: 12),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.services,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PostCopy(post: post)),
                const SizedBox(width: 12),
                Container(
                  width: 104,
                  height: 94,
                  decoration: BoxDecoration(
                    color: AppColors.marketplaceSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chair_alt_rounded,
                    size: 48,
                    color: AppColors.marketplace.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Icon(Icons.favorite_border_rounded, color: AppColors.danger),
              const SizedBox(width: AppSpacing.xSmall),
              Text('${post.likes}'),
              const SizedBox(width: AppSpacing.xLarge),
              const Icon(Icons.chat_bubble_outline_rounded),
              const SizedBox(width: AppSpacing.xSmall),
              Text('${post.comments}'),
              const Spacer(),
              const Icon(
                Icons.bookmark_border_rounded,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCopy extends StatelessWidget {
  const _PostCopy({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(post.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(
          post.body,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}
