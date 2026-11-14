import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_public_page_chrome.dart';
import 'package:darjar/features/onboarding/presentation/app_store_launcher.dart';
import 'package:flutter/material.dart';

class InstallAppPage extends StatelessWidget {
  const InstallAppPage({this.openStore = openDarjarStore, super.key});

  final Future<bool> Function(Uri) openStore;

  Future<void> _open(BuildContext context, String url) async {
    final opened = await openStore(Uri.parse(url));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).installOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storeButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 80),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xLarge,
        vertical: AppSpacing.large,
      ),
      textStyle: Theme.of(context).textTheme.titleLarge,
    );
    return Scaffold(
      key: const Key('install-app-page'),
      appBar: const DarJarPublicAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxLarge),
                  Icon(
                    Icons.install_mobile_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  Text(
                    l10n.installAppTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Text(l10n.installAppDescription, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxLarge),
                  FilledButton.icon(
                    key: const Key('install-google-play'),
                    style: storeButtonStyle,
                    label: const Text('Google Play'),
                    icon: const Icon(Icons.android_rounded, size: 40),
                    onPressed: () => _open(context, darjarGooglePlayUrl),
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  FilledButton.icon(
                    key: const Key('install-app-store'),
                    style: storeButtonStyle,
                    label: const Text('App Store'),
                    icon: const Icon(Icons.apple_rounded, size: 40),
                    onPressed: () => _open(context, darjarAppStoreUrl),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
