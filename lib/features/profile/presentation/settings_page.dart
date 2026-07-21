import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
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
              DarJarCard(
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
            ],
          ),
        ),
      ),
    );
  }
}
