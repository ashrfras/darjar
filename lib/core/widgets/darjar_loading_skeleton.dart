import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DarJarLoadingSkeleton extends StatelessWidget {
  const DarJarLoadingSkeleton({this.itemCount = 3, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).dataLoading,
      child: Column(
        key: const Key('data-loading-skeleton'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            Container(
              height: index == 0 ? 116 : 88,
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(widthFactor: index == 0 ? 0.5 : 0.36),
                  const SizedBox(height: AppSpacing.medium),
                  const _SkeletonBar(widthFactor: 0.86),
                  if (index == 0) ...[
                    const SizedBox(height: AppSpacing.small),
                    const _SkeletonBar(widthFactor: 0.64),
                  ],
                ],
              ),
            ),
            if (index < itemCount - 1)
              const SizedBox(height: AppSpacing.medium),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.outline,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
    );
  }
}
