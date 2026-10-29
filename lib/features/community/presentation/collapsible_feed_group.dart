import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:flutter/material.dart';

class CollapsibleFeedGroup extends StatefulWidget {
  const CollapsibleFeedGroup({
    required this.items,
    required this.itemBuilder,
    super.key,
  });

  final List<FeedItem> items;
  final Widget Function(FeedItem) itemBuilder;

  @override
  State<CollapsibleFeedGroup> createState() => _CollapsibleFeedGroupState();
}

class _CollapsibleFeedGroupState extends State<CollapsibleFeedGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canCollapse = widget.items.length >= 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.itemBuilder(widget.items.first),
        if (!canCollapse)
          for (final item in widget.items.skip(1)) ...[
            const SizedBox(height: AppSpacing.medium),
            widget.itemBuilder(item),
          ],
        if (canCollapse) ...[
          const SizedBox(height: AppSpacing.small),
          Container(
            key: const Key('similar-activities-group'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.xSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.inkMuted.withValues(alpha: .035),
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.inkMuted,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.small,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w400),
                    ),
                    child: Text(
                      _expanded
                          ? AppLocalizations.of(context).hideSimilarActivities
                          : AppLocalizations.of(
                              context,
                            ).showSimilarActivities(widget.items.length - 1),
                    ),
                  ),
                ),
                if (_expanded)
                  for (final item in widget.items.skip(1)) ...[
                    const SizedBox(height: AppSpacing.small),
                    widget.itemBuilder(item),
                  ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
