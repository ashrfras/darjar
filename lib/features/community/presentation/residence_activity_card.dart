import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:flutter/material.dart';

class ResidenceActivityCard extends StatelessWidget {
  const ResidenceActivityCard({
    required this.activity,
    required this.onLike,
    this.onOpen,
    super.key,
  });

  final ResidenceActivity activity;
  final VoidCallback onLike;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final visual = _visualFor(activity.activityType);
    final classification = ar
        ? activity.classificationAr
        : activity.classificationEn;

    return DarJarCard(
      key: ValueKey('feed-activity-${activity.id}'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(visual.icon, color: visual.color, size: 21),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar ? activity.descriptionAr : activity.descriptionEn,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      ar ? activity.timeLabelAr : activity.timeLabelEn,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    if (classification != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: visual.color.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          classification,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: visual.color, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _ActivityLikeButton(activity: activity, onPressed: onLike),
          if (onOpen != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2, top: 9),
              child: Icon(
                ar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityLikeButton extends StatelessWidget {
  const _ActivityLikeButton({required this.activity, required this.onPressed});

  final ResidenceActivity activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      selected: activity.isLiked,
      label: ar ? 'إعجاب' : 'Like',
      child: InkWell(
        key: ValueKey('activity-like-${activity.id}'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                activity.isLiked
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                size: 17,
                color: activity.isLiked
                    ? AppColors.primary
                    : AppColors.inkMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${activity.likes}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: activity.isLiked
                      ? AppColors.primary
                      : AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({IconData icon, Color color}) _visualFor(ResidenceActivityType type) {
  return switch (type) {
    ResidenceActivityType.expenseAdded => (
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFFE76F00),
    ),
    ResidenceActivityType.duePaid => (
      icon: Icons.task_alt_rounded,
      color: const Color(0xFF2B8A3E),
    ),
    ResidenceActivityType.monthlyDueChanged => (
      icon: Icons.price_change_outlined,
      color: const Color(0xFF2878D4),
    ),
    ResidenceActivityType.documentAdded => (
      icon: Icons.description_outlined,
      color: const Color(0xFF6650D8),
    ),
    ResidenceActivityType.serviceAdded => (
      icon: Icons.home_repair_service_outlined,
      color: const Color(0xFF087F5B),
    ),
    ResidenceActivityType.announcementPublished => (
      icon: Icons.campaign_outlined,
      color: const Color(0xFFC2255C),
    ),
    ResidenceActivityType.pollCreated => (
      icon: Icons.poll_outlined,
      color: const Color(0xFF9C36B5),
    ),
  };
}
