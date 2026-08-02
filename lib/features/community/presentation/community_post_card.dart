import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CommunityPostKindUi on CommunityPostKind {
  String label(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return switch (this) {
      CommunityPostKind.announcement => ar ? 'إعلان رسمي' : 'Announcement',
      CommunityPostKind.question => ar ? 'سؤال' : 'Question',
      CommunityPostKind.complaint => ar ? 'شكوى' : 'Complaint',
      CommunityPostKind.suggestion => ar ? 'اقتراح' : 'Suggestion',
      CommunityPostKind.alert => ar ? 'تنبيه' : 'Alert',
      CommunityPostKind.general => ar ? 'منشور عام' : 'General',
      CommunityPostKind.poll => ar ? 'استطلاع' : 'Poll',
      CommunityPostKind.event => ar ? 'مناسبة' : 'Event',
    };
  }

  IconData get icon => switch (this) {
    CommunityPostKind.announcement => Icons.campaign_outlined,
    CommunityPostKind.question => Icons.help_outline_rounded,
    CommunityPostKind.complaint => Icons.report_problem_outlined,
    CommunityPostKind.suggestion => Icons.lightbulb_outline_rounded,
    CommunityPostKind.alert => Icons.notifications_active_outlined,
    CommunityPostKind.general => Icons.forum_outlined,
    CommunityPostKind.poll => Icons.poll_outlined,
    CommunityPostKind.event => Icons.celebration_outlined,
  };

  Color get color => switch (this) {
    CommunityPostKind.announcement => const Color(0xFF087F5B),
    CommunityPostKind.question => const Color(0xFF6650D8),
    CommunityPostKind.complaint => const Color(0xFFE76F00),
    CommunityPostKind.suggestion => const Color(0xFF2B8A3E),
    CommunityPostKind.alert => const Color(0xFF2878D4),
    CommunityPostKind.general => const Color(0xFF52606D),
    CommunityPostKind.poll => const Color(0xFF9C36B5),
    CommunityPostKind.event => const Color(0xFFC2255C),
  };
}

class CommunityPostCard extends ConsumerWidget {
  const CommunityPostCard({
    required this.post,
    required this.onOpen,
    required this.onLike,
    required this.onSave,
    required this.onVote,
    this.onArchive,
    this.expanded = false,
    super.key,
  });

  final CommunityPost post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final ValueChanged<String> onVote;
  final VoidCallback? onArchive;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final color = post.kind.color;
    final residenceDirectory = ref.watch(residenceDirectoryProvider).value;
    final apartmentLabel = _communityApartmentLabel(
      context,
      post,
      residenceDirectory,
    );

    return DarJarCard(
      key: ValueKey('community-post-${post.id}'),
      padding: EdgeInsets.zero,
      onTap: expanded ? null : onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3, color: color),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PostHeader(
                  post: post,
                  apartmentLabel: apartmentLabel,
                  onArchive: onArchive,
                ),
                const SizedBox(height: AppSpacing.medium),
                _KindLabel(post: post),
                const SizedBox(height: AppSpacing.small),
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (post.body.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.body,
                    maxLines: expanded || post.isSystem ? null : 3,
                    overflow: expanded || post.isSystem
                        ? null
                        : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                      height: 1.65,
                    ),
                  ),
                ],
                if (post.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.medium),
                  if (post.isSystem)
                    _WelcomePostImage(
                      key: ValueKey('post-images-${post.id}'),
                      path: post.imagePaths.first,
                    )
                  else
                    _PostImages(
                      key: ValueKey('post-images-${post.id}'),
                      imagePaths: post.imagePaths,
                    ),
                ],
                if (post.eventDate != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  _EventDetails(post: post),
                ],
                if (post.pollOptions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.large),
                  PollPanel(post: post, onVote: onVote),
                ],
                if (!post.isSystem) ...[
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xSmall),
                  _PostActions(
                    post: post,
                    onLike: onLike,
                    onComment: onOpen,
                    onSave: onSave,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.apartmentLabel,
    required this.onArchive,
  });

  final CommunityPost post;
  final String? apartmentLabel;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final color = post.kind.color;
    final showRoleBadge =
        !post.isSystem && _showsCommunityRoleBadge(post.authorRole);
    return Row(
      children: [
        if (post.isSystem)
          CircleAvatar(
            key: const Key('darjar-post-avatar'),
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/branding/darjar-logo.png',
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          )
        else
          DarJarUserAvatar(
            userId: post.authorId,
            name: post.author,
            radius: 22,
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
          ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      abbreviatedPersonName(post.author),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: AppColors.ink),
                    ),
                  ),
                  if (showRoleBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: ValueKey('post-author-role-${post.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        communityMemberRoleLabel(context, post.authorRole),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (post.isSystem) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.verified_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              Text(
                [
                  if (post.isSystem)
                    communityMemberRoleLabel(context, post.authorRole)
                  else if (apartmentLabel != null)
                    apartmentLabel,
                  post.timeLabel,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        if (post.isCurrentUser && onArchive != null)
          PopupMenuButton<String>(
            key: ValueKey('post-menu-${post.id}'),
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            color: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              side: const BorderSide(color: AppColors.outline),
            ),
            onSelected: (value) {
              if (value == 'archive') _confirmArchive(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'حذف المنشور'
                          : 'Delete post',
                    ),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_horiz_rounded),
          ),
      ],
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ar ? 'حذف المنشور؟' : 'Delete post?'),
        content: Text(
          ar
              ? 'هل تريد حذف هذا المنشور؟ لن يعود ظاهراً لسكان الإقامة.'
              : 'Delete this post? It will no longer be visible to residents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onArchive?.call();
  }
}

bool _showsCommunityRoleBadge(String role) => const {
  'president',
  'owner',
  'deputy',
  'manager',
  'treasurer',
  'moderator',
  'platformAdmin',
}.contains(role);

String? _communityApartmentLabel(
  BuildContext context,
  CommunityPost post,
  ResidenceMembersData? directory,
) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  if (post.authorId.isNotEmpty && directory != null) {
    String? apartmentId;
    for (final member in directory.members) {
      if (member.id == post.authorId) {
        apartmentId = member.apartmentId;
        break;
      }
    }
    if (apartmentId != null) {
      for (final apartment in directory.apartments) {
        if (apartment.id == apartmentId) {
          return ar
              ? 'شقة ${apartment.number}'
              : 'Apartment ${apartment.number}';
        }
      }
    }
  }

  final unit = post.authorUnit?.trim();
  if (unit == null || unit.isEmpty) return null;
  final apartmentMatch = RegExp(
    r'(?:شقة|Apartment)\s*([^·،,]+)',
    caseSensitive: false,
  ).firstMatch(unit);
  if (apartmentMatch != null) {
    final number = apartmentMatch.group(1)?.trim();
    if (number != null && number.isNotEmpty) {
      return ar ? 'شقة $number' : 'Apartment $number';
    }
  }
  if (unit.contains('إدارة') || unit.toLowerCase().contains('management')) {
    return unit;
  }
  return null;
}

String communityMemberRoleLabel(BuildContext context, String role) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  return switch (role) {
    'president' || 'owner' => ar ? 'رئيس' : 'President',
    'deputy' || 'manager' => ar ? 'نائب الرئيس' : 'Deputy',
    'treasurer' => ar ? 'أمين المال' : 'Treasurer',
    'moderator' => ar ? 'مشرف' : 'Moderator',
    'platformAdmin' => ar ? 'فريق دارجار' : 'DarJar team',
    _ => ar ? 'ساكن' : 'Resident',
  };
}

class _KindLabel extends StatelessWidget {
  const _KindLabel({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final color = post.kind.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(post.kind.icon, size: 19, color: color),
        const SizedBox(width: 6),
        Text(
          post.kind.label(context),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _WelcomePostImage extends StatelessWidget {
  const _WelcomePostImage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      height: compact ? 170 : 210,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        path,
        width: compact ? 120 : 150,
        height: compact ? 120 : 150,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'DarJar',
      ),
    );
  }
}

class _PostImages extends StatelessWidget {
  const _PostImages({required this.imagePaths, super.key});

  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) {
    final images = imagePaths.take(4).toList(growable: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: AspectRatio(
        aspectRatio: images.length == 1 ? 16 / 9 : 3 / 2,
        child: switch (images.length) {
          1 => _ImageTile(path: images[0]),
          2 => Row(
            children: [
              Expanded(child: _ImageTile(path: images[0])),
              const SizedBox(width: 3),
              Expanded(child: _ImageTile(path: images[1])),
            ],
          ),
          3 => Row(
            children: [
              Expanded(flex: 2, child: _ImageTile(path: images[0])),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _ImageTile(path: images[1])),
                    const SizedBox(height: 3),
                    Expanded(child: _ImageTile(path: images[2])),
                  ],
                ),
              ),
            ],
          ),
          _ => Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _ImageTile(path: images[0])),
                    const SizedBox(width: 3),
                    Expanded(child: _ImageTile(path: images[1])),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _ImageTile(path: images[2])),
                    const SizedBox(width: 3),
                    Expanded(child: _ImageTile(path: images[3])),
                  ],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _ImageTile extends ConsumerWidget {
  const _ImageTile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = path.startsWith('assets/')
        ? Image.asset(path, fit: BoxFit.cover)
        : ref
              .watch(communityPostImageProvider(path))
              .when(
                data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              );
    return Material(
      color: AppColors.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  backgroundColor: Colors.black,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          child: Center(
                            child: path.startsWith('assets/')
                                ? Image.asset(path, fit: BoxFit.contain)
                                : ref
                                      .read(communityPostImageProvider(path))
                                      .when(
                                        data: (bytes) => Image.memory(
                                          bytes,
                                          fit: BoxFit.contain,
                                        ),
                                        loading: () =>
                                            const CircularProgressIndicator(),
                                        error: (error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.white,
                                            ),
                                      ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: AppSpacing.large,
                        end: AppSpacing.large,
                        child: SafeArea(
                          child: IconButton.filledTonal(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
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

class _EventDetails extends StatelessWidget {
  const _EventDetails({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: post.kind.color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        children: [
          _EventLine(
            icon: Icons.calendar_today_outlined,
            text: post.eventDate!,
          ),
          if (post.eventLocation != null) ...[
            const SizedBox(height: AppSpacing.small),
            _EventLine(
              icon: Icons.location_on_outlined,
              text: post.eventLocation!,
            ),
          ],
        ],
      ),
    );
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: CommunityPostKind.event.color),
        const SizedBox(width: AppSpacing.small),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class PollPanel extends StatelessWidget {
  const PollPanel({required this.post, required this.onVote, super.key});

  final CommunityPost post;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final total = post.pollOptions.fold<int>(
      0,
      (sum, option) => sum + option.votes,
    );
    final hasVoted = post.selectedPollOptionId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in post.pollOptions) ...[
          _PollOptionTile(
            option: option,
            total: total,
            hasVoted: hasVoted,
            selected: post.selectedPollOptionId == option.id,
            onTap: hasVoted ? null : () => onVote(option.id),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? '$total صوت${hasVoted ? ' · تم تسجيل صوتك' : ''}'
              : '$total votes${hasVoted ? ' · Vote recorded' : ''}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  const _PollOptionTile({
    required this.option,
    required this.total,
    required this.hasVoted,
    required this.selected,
    required this.onTap,
  });

  final PollOption option;
  final int total;
  final bool hasVoted;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : option.votes / total;
    return Semantics(
      button: !hasVoted,
      selected: selected,
      child: InkWell(
        key: ValueKey('poll-option-${option.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? CommunityPostKind.poll.color
                  : AppColors.outline,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasVoted)
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: ratio,
                  child: ColoredBox(
                    color: CommunityPostKind.poll.color.withValues(alpha: .10),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  children: [
                    if (selected) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: CommunityPostKind.poll.color,
                      ),
                      const SizedBox(width: 7),
                    ],
                    Expanded(child: Text(option.label)),
                    if (hasVoted) Text('${(ratio * 100).round()}٪'),
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

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          key: ValueKey('like-${post.id}'),
          icon: post.isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: '${post.likes}',
          color: post.isLiked ? AppColors.danger : AppColors.inkMuted,
          onTap: onLike,
        ),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${post.commentCount}',
          onTap: onComment,
        ),
        const Spacer(),
        IconButton(
          key: ValueKey('save-${post.id}'),
          tooltip: Localizations.localeOf(context).languageCode == 'ar'
              ? 'حفظ'
              : 'Save',
          onPressed: onSave,
          color: post.isSaved ? AppColors.primary : AppColors.inkMuted,
          icon: Icon(
            post.isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.inkMuted,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
