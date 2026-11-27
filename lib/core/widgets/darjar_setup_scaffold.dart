import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:flutter/material.dart';

class DarJarSetupScaffold extends StatelessWidget {
  const DarJarSetupScaffold({
    required this.onBack,
    required this.child,
    this.backButtonKey,
    super.key,
  });

  final VoidCallback onBack;
  final Widget child;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DarJarBrand(key: Key('setup-brand-title')),
        leading: IconButton(
          key: backButtonKey,
          tooltip: AppLocalizations.of(context).back,
          onPressed: onBack,
          icon: const BackButtonIcon(),
        ),
      ),
      body: SafeArea(top: false, child: child),
    );
  }
}

class DarJarSetupIntroduction extends StatelessWidget {
  const DarJarSetupIntroduction({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: AppSpacing.medium),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.small),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}
