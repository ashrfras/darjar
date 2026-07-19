import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesHomePage extends StatelessWidget {
  const ServicesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final services = [
      (
        title: localizations.maintenanceRequests,
        description: localizations.maintenanceDescription,
        icon: Icons.handyman_outlined,
        color: AppColors.warning,
        route: AppRoutes.maintenance,
      ),
      (
        title: localizations.duesStatus,
        description: localizations.duesDescription,
        icon: Icons.receipt_long_outlined,
        color: AppColors.marketplace,
        route: AppRoutes.dues,
      ),
      (
        title: localizations.managementInformation,
        description: localizations.managementDescription,
        icon: Icons.business_outlined,
        color: AppColors.services,
        route: AppRoutes.management,
      ),
      (
        title: localizations.documents,
        description: localizations.documentsDescription,
        icon: Icons.folder_outlined,
        color: AppColors.community,
        route: '',
      ),
    ];

    return SingleChildScrollView(
      key: const Key('services-home-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarPageHeader(
                title: localizations.services,
                description: localizations.servicesPageDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 2 : 1;
                  final width = columns == 2
                      ? (constraints.maxWidth - AppSpacing.large) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.large,
                    runSpacing: AppSpacing.large,
                    children: [
                      for (final service in services)
                        SizedBox(
                          width: width,
                          child: DarJarCard(
                            onTap: service.route.isEmpty
                                ? null
                                : () => context.go(service.route),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: service.color.withValues(
                                    alpha: 0.10,
                                  ),
                                  foregroundColor: service.color,
                                  child: Icon(service.icon),
                                ),
                                const SizedBox(width: AppSpacing.large),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xSmall),
                                      Text(
                                        service.description,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (service.route.isNotEmpty)
                                  const Icon(Icons.chevron_left_rounded),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
