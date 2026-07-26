import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/profile/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final profile = ref.watch(residentProfileProvider);

    return SingleChildScrollView(
      key: const Key('profile-page'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.small,
        AppSpacing.xLarge,
        AppSpacing.xLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.profile,
                fallbackLocation: AppRoutes.community,
              ),
              const SizedBox(height: AppSpacing.small),
              DarJarCard(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      child: Icon(Icons.person_rounded, size: 44),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    DarJarBadge(
                      label: profile.role,
                      tone: DarJarBadgeTone.info,
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    _ProfileInfo(
                      icon: Icons.phone_outlined,
                      label: localizations.phoneNumber,
                      value: profile.phone,
                      valueTextDirection: TextDirection.ltr,
                    ),
                    const Divider(),
                    _ProfileInfo(
                      icon: Icons.apartment_outlined,
                      label: localizations.residence,
                      value: profile.residence,
                    ),
                    const Divider(),
                    _ProfileInfo(
                      icon: Icons.door_front_door_outlined,
                      label: localizations.unit,
                      value: profile.unit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('settings-link'),
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(localizations.settings),
                      trailing: const _NavigationChevron(),
                      onTap: () => context.go(AppRoutes.settings),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: Text(localizations.replayOnboarding),
                      trailing: const _NavigationChevron(),
                      onTap: () => context.go(AppRoutes.onboarding),
                    ),
                  ],
                ),
              ),
              // TODO: Restore `profile.canManageResidence` once permission
              // assignment is connected to the authenticated user.
              const SizedBox(height: AppSpacing.large),
              Text(
                localizations.residenceAdministration,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarCard(
                key: const Key('residence-management-section'),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ManagementLink(
                      key: const Key('manage-residence-link'),
                      icon: Icons.domain_outlined,
                      title: localizations.residenceSettings,
                      description: localizations.residenceManagementDescription,
                      route: AppRoutes.manageResidence,
                    ),
                    const Divider(),
                    _ManagementLink(
                      key: const Key('manage-apartments-link'),
                      icon: Icons.apartment_outlined,
                      title: localizations.apartments,
                      description:
                          localizations.apartmentsManagementDescription,
                      route: AppRoutes.manageApartments,
                    ),
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

class _ManagementLink extends StatelessWidget {
  const _ManagementLink({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const _NavigationChevron(),
      onTap: () => context.go(route),
    );
  }
}

class _NavigationChevron extends StatelessWidget {
  const _NavigationChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_left_rounded,
      textDirection: TextDirection.ltr,
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.icon,
    required this.label,
    required this.value,
    this.valueTextDirection,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextDirection? valueTextDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  value,
                  textDirection: valueTextDirection,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
