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
      padding: const EdgeInsets.all(AppSpacing.xLarge),
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
              const SizedBox(height: AppSpacing.xLarge),
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
                      icon: Icons.email_outlined,
                      label: localizations.email,
                      value: profile.email,
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
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => context.go(AppRoutes.settings),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: Text(localizations.replayOnboarding),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => context.go(AppRoutes.onboarding),
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

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
