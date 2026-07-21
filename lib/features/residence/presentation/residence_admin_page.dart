import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:flutter/material.dart';

enum ResidenceAdminDestination { apartments, projects, residence }

class ResidenceAdminPage extends StatelessWidget {
  const ResidenceAdminPage.apartments({super.key})
    : destination = ResidenceAdminDestination.apartments;

  const ResidenceAdminPage.projects({super.key})
    : destination = ResidenceAdminDestination.projects;

  const ResidenceAdminPage.residence({super.key})
    : destination = ResidenceAdminDestination.residence;

  final ResidenceAdminDestination destination;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (title, description, pageKey) = switch (destination) {
      ResidenceAdminDestination.apartments => (
        localizations.apartments,
        localizations.apartmentsManagementDescription,
        const Key('apartments-management-page'),
      ),
      ResidenceAdminDestination.projects => (
        localizations.projects,
        localizations.projectsManagementDescription,
        const Key('projects-management-page'),
      ),
      ResidenceAdminDestination.residence => (
        localizations.residence,
        localizations.residenceManagementDescription,
        const Key('residence-management-page'),
      ),
    };

    return SingleChildScrollView(
      key: pageKey,
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: DarJarSubpageHeader(
            title: title,
            description: description,
            fallbackLocation: AppRoutes.profile,
          ),
        ),
      ),
    );
  }
}
