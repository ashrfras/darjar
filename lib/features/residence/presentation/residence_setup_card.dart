import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/features/residence/data/residence_setup_progress_provider.dart';
import 'package:darjar/features/residence/data/residence_setup_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResidenceSetupCard extends ConsumerWidget {
  const ResidenceSetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(residenceSetupScopeProvider);
    if (scope == null) return const SizedBox.shrink();

    final preference = residenceSetupVisibilityProvider(scope);
    final visibility = ref.watch(preference);
    if (visibility.value != ResidenceSetupVisibility.visible &&
        !visibility.hasError) {
      return const SizedBox.shrink();
    }
    return _SetupChecklist(
      scope: scope,
      onHide: visibility.isLoading
          ? null
          : () async {
              try {
                await ref
                    .read(preference.notifier)
                    .setVisibility(ResidenceSetupVisibility.hiddenUnread);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).communityActionFailed,
                    ),
                  ),
                );
              }
            },
    );
  }
}

class _SetupChecklist extends ConsumerWidget {
  const _SetupChecklist({required this.scope, required this.onHide});

  final ResidenceSetupScope scope;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(residenceSetupProgressProvider(scope));
    if (progress == null || progress.isComplete) return const SizedBox.shrink();
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final steps = [
      (
        label: strings.setupChecklistCreateResidence,
        icon: Icons.home_outlined,
        complete: true,
        route: null,
      ),
      (
        label: strings.setupChecklistSetFloorCount,
        icon: Icons.layers_outlined,
        complete: progress.hasUpperFloor,
        route: AppRoutes.manageResidence,
      ),
      (
        label: strings.setupChecklistAddApartments,
        icon: Icons.apartment_outlined,
        complete: progress.hasApartment,
        route: AppRoutes.manageApartments,
      ),
      (
        label: strings.setupChecklistInviteNeighbors,
        icon: Icons.people_outline_rounded,
        complete: progress.hasNeighbor,
        route: '${AppRoutes.manageApartments}?view=residents',
      ),
      (
        label: strings.appointResidencePresident,
        icon: Icons.badge_outlined,
        complete: progress.hasPresident,
        route: AppRoutes.appointResidencePresident,
      ),
    ];
    final completed = steps.where((step) => step.complete).length;
    return Padding(
      key: const Key('residence-setup-card'),
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Material(
        color: AppColors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.setupChecklistTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          strings.setupChecklistDescription,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  CircleAvatar(
                    backgroundColor: colors.primary.withValues(alpha: 0.13),
                    foregroundColor: colors.primary,
                    child: const Icon(Icons.fact_check_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    if (index > 0) const SizedBox(width: 4),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: index < completed
                              ? colors.primary
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const SizedBox(height: 5),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.small),
                  Flexible(
                    flex: 3,
                    child: Text(
                      strings.setupChecklistProgress(completed, steps.length),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Material(
                color: colors.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (index, step) in steps.indexed) ...[
                      if (index > 0) const Divider(height: 1),
                      ListTile(
                        dense: true,
                        minTileHeight: 44,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.small,
                        ),
                        leading: Icon(
                          step.complete
                              ? Icons.check_circle_rounded
                              : step.icon,
                          color: step.complete
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          size: 20,
                          semanticLabel: step.complete
                              ? strings.completedLabel
                              : null,
                        ),
                        title: Text(step.label),
                        trailing: step.complete
                            ? null
                            : const Icon(Icons.navigate_next_rounded),
                        onTap: step.complete
                            ? null
                            : () => context.push(step.route!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Center(
                child: TextButton(
                  onPressed: onHide,
                  child: Text(strings.setupChecklistHide),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
