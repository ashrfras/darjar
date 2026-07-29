import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityPostDetailPage extends ConsumerStatefulWidget {
  const CommunityPostDetailPage({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<CommunityPostDetailPage> createState() =>
      _CommunityPostDetailPageState();
}

class _CommunityPostDetailPageState
    extends ConsumerState<CommunityPostDetailPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(communityPostProvider(widget.postId));
    final post = postState.value;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (post == null && postState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (post == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xLarge,
          AppSpacing.small,
          AppSpacing.xLarge,
          AppSpacing.xLarge,
        ),
        children: [
          DarJarSubpageHeader(
            title: ar ? 'تفاصيل المنشور' : 'Post details',
            fallbackLocation: AppRoutes.community,
          ),
          const SizedBox(height: AppSpacing.large),
          const Icon(Icons.forum_outlined, size: 48),
          const SizedBox(height: AppSpacing.medium),
          Center(
            child: Text(ar ? 'لم يتم العثور على المنشور' : 'Post not found'),
          ),
        ],
      );
    }

    return Scaffold(
      key: const Key('community-post-detail-page'),
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : AppSpacing.xLarge,
          AppSpacing.large,
          compact ? 12 : AppSpacing.xLarge,
          AppSpacing.xxLarge,
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DarJarSubpageHeader(fallbackLocation: AppRoutes.community),
                  const SizedBox(height: AppSpacing.small),
                  CommunityPostCard(
                    post: post,
                    expanded: true,
                    onOpen: () {},
                    onLike: () => _runAction(
                      () => ref
                          .read(communityActionsProvider)
                          .toggleLike(post.id),
                    ),
                    onSave: () => _runAction(
                      () => ref
                          .read(communityActionsProvider)
                          .toggleSaved(post.id),
                    ),
                    onVote: (optionId) => _runAction(
                      () => ref
                          .read(communityActionsProvider)
                          .vote(post.id, optionId),
                    ),
                    onArchive: () => _archivePost(post.id),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    ar
                        ? 'التعليقات (${post.commentCount})'
                        : 'Comments (${post.commentCount})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _CommentComposer(
                    controller: _commentController,
                    onSubmit: () => _submitComment(post.id),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (post.comments.isEmpty)
                    _NoComments()
                  else
                    for (final comment in post.comments) ...[
                      _CommentTile(comment: comment),
                      const SizedBox(height: AppSpacing.small),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment(String postId) async {
    final value = _commentController.text.trim();
    if (value.isEmpty) return;
    try {
      await ref.read(communityActionsProvider).addComment(postId, value);
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } on CommunityFailure {
      if (!mounted) return;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'تعذّر نشر التعليق.' : 'Could not publish the comment.',
          ),
        ),
      );
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } on CommunityFailure {
      if (!mounted) return;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'تعذّر تنفيذ الإجراء.' : 'Could not complete the action.',
          ),
        ),
      );
    }
  }

  Future<void> _archivePost(String postId) async {
    try {
      await ref.read(communityActionsProvider).archivePost(postId);
      if (mounted) {
        Navigator.of(context).canPop() ? Navigator.of(context).pop() : null;
      }
    } on CommunityFailure {
      if (!mounted) return;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'تعذّر حذف المنشور.' : 'Could not delete the post.',
          ),
        ),
      );
    }
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return DarJarCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.person_rounded, size: 20),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: TextField(
              key: const Key('comment-field'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: ar ? 'اكتب تعليقاً...' : 'Write a comment…',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          IconButton.filled(
            key: const Key('submit-comment-button'),
            tooltip: ar ? 'إرسال' : 'Send',
            onPressed: onSubmit,
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.send_rounded
                  : Icons.send_rounded,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommunityComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: comment.isAuthor ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: comment.isAuthor
                ? AppColors.primary
                : AppColors.canvas,
            foregroundColor: comment.isAuthor
                ? Colors.white
                : AppColors.inkMuted,
            child: Text(comment.author.characters.first),
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
                        abbreviatedCommunityName(comment.author),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      comment.timeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoComments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            ar ? 'كن أول من يعلّق على هذا المنشور' : 'Be the first to comment',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
