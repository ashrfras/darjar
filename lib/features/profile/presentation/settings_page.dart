import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _communityNotifications = true;
  bool _residenceNotifications = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const Key('settings-page'),
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
                title: localizations.settings,
                fallbackLocation: AppRoutes.profile,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.generalSettings,
                key: const Key('general-settings-title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarCard(
                key: const Key('general-settings-section'),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.large,
                        AppSpacing.large,
                        AppSpacing.large,
                        AppSpacing.small,
                      ),
                      child: Text(
                        localizations.notifications,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    SwitchListTile(
                      title: Text(localizations.communityNotifications),
                      value: _communityNotifications,
                      onChanged: (value) {
                        setState(() => _communityNotifications = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(localizations.residenceNotifications),
                      value: _residenceNotifications,
                      onChanged: (value) {
                        setState(() => _residenceNotifications = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),
              Text(
                localizations.professionalSettings,
                key: const Key('professional-settings-title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarCard(
                key: const Key('professional-settings-section'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        child: Icon(Icons.workspace_premium_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      localizations.professionalAccountDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: DarJarButton(
                        key: const Key('switch-to-professional-button'),
                        label: localizations.switchToProfessionalAccount,
                        icon: Icons.arrow_forward_rounded,
                        iconAtEnd: true,
                        onPressed: () {},
                      ),
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
