import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/services/data/services_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final requests = ref.watch(maintenanceRequestsProvider);

    return SingleChildScrollView(
      key: const Key('maintenance-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarPageHeader(
                title: localizations.maintenanceRequests,
                description: localizations.maintenancePageDescription,
                action: DarJarButton(
                  key: const Key('new-maintenance-button'),
                  label: localizations.newRequest,
                  icon: Icons.add_rounded,
                  onPressed: () => context.go(AppRoutes.createMaintenance),
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),
              for (final request in requests) ...[
                _MaintenanceCard(request: request),
                const SizedBox(height: AppSpacing.medium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.request});

  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final completed = request.status == MaintenanceStatus.completed;
    return DarJarCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: completed
                ? AppColors.marketplaceSoft
                : AppColors.warningSoft,
            foregroundColor: completed
                ? AppColors.marketplace
                : AppColors.warning,
            child: const Icon(Icons.handyman_outlined),
          ),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    DarJarBadge(
                      label: completed
                          ? localizations.completedLabel
                          : localizations.processingLabel,
                      tone: completed
                          ? DarJarBadgeTone.success
                          : DarJarBadgeTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  request.location,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  request.timeLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
