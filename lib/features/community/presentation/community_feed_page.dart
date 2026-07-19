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

    return Scaffold(
      key: const Key('community-feed-page'),
      backgroundColor: Colors.transparent,
      floatingActionButton: MediaQuery.sizeOf(context).width < 600
          ? FloatingActionButton.extended(
              key: const Key('create-post-fab'),
              onPressed: () => context.go(AppRoutes.createPost),
              icon: const Icon(Icons.add_rounded),
              label: Text(localizations.newPost),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarJarPageHeader(
                  title: localizations.community,
                  description: localizations.communityFeedDescription,
                  action: MediaQuery.sizeOf(context).width >= 600
                      ? DarJarButton(
                          key: const Key('create-post-button'),
                          label: localizations.newPost,
                          icon: Icons.add_rounded,
                          onPressed: () => context.go(AppRoutes.createPost),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.xLarge),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.10),
                foregroundColor: accent,
                child: Icon(
                  isAnnouncement
                      ? Icons.campaign_rounded
                      : Icons.person_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      post.timeLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              if (isAnnouncement)
                DarJarBadge(
                  label: localizations.officialAnnouncement,
                  tone: DarJarBadgeTone.info,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.small),
          Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.large),
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
