import 'package:darjar/app/localization/app_locale_provider.dart';
import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _communityNotifications = true;
  bool _residenceNotifications = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);

    return SingleChildScrollView(
      key: const Key('settings-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
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
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.language,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'ar',
                          label: Text(localizations.arabic),
                        ),
                        ButtonSegment(
                          value: 'en',
                          label: Text(localizations.english),
                        ),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (selection) {
                        ref
                            .read(appLocaleProvider.notifier)
                            .setLocale(Locale(selection.first));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
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
