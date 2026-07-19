import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum DarJarBadgeTone { neutral, success, warning, info }

class DarJarBadge extends StatelessWidget {
  const DarJarBadge({
    required this.label,
    this.tone = DarJarBadgeTone.neutral,
    super.key,
  });

  final String label;
  final DarJarBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      DarJarBadgeTone.neutral => (AppColors.canvas, AppColors.inkMuted),
      DarJarBadgeTone.success => (
        AppColors.marketplaceSoft,
        AppColors.marketplace,
      ),
      DarJarBadgeTone.warning => (AppColors.warningSoft, AppColors.warning),
      DarJarBadgeTone.info => (AppColors.servicesSoft, AppColors.services),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
