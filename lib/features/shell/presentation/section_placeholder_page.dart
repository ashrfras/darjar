import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:flutter/material.dart';

enum AppSection { community, marketplace, services }

class SectionPlaceholderPage extends StatelessWidget {
  const SectionPlaceholderPage({required this.section, super.key});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final details = switch (section) {
      AppSection.community => (
        title: localizations.community,
        description: localizations.communityDescription,
        icon: Icons.people_rounded,
        color: AppColors.community,
      ),
      AppSection.marketplace => (
        title: localizations.marketplace,
        description: localizations.marketplaceDescription,
        icon: Icons.shopping_bag_rounded,
        color: AppColors.marketplace,
      ),
      AppSection.services => (
        title: localizations.services,
        description: localizations.servicesDescription,
        icon: Icons.home_repair_service_rounded,
        color: AppColors.services,
      ),
    };

    return SingleChildScrollView(
      key: Key('section-${section.name}'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                details.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.shellPreviewDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xLarge,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: details.color.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          details.icon,
                          color: details.color,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Text(
                        details.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        details.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      DarJarBadge(
                        label: localizations.milestoneTwo,
                        tone: DarJarBadgeTone.info,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
