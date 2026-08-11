import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportEmail = 'support@raqmain.ma';

class DarJarPublicAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DarJarPublicAppBar({this.brandKey, this.backButtonKey, super.key});

  final Key? brandKey;
  final Key? backButtonKey;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AppBar(
      title: DarJarBrand(key: brandKey),
      leading: IconButton(
        key: backButtonKey,
        tooltip: localizations.back,
        onPressed: () => context.go(AppRoutes.onboarding),
        icon: const BackButtonIcon(),
      ),
    );
  }
}

class DarJarPublicFooter extends StatelessWidget {
  const DarJarPublicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      key: const Key('landing-footer'),
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xLarge,
            runSpacing: AppSpacing.large,
            children: [
              const DarJarBrand(),
              Wrap(
                spacing: AppSpacing.small,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.publicPrivacyPolicy),
                    child: Text(localizations.privacyPolicy),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.deleteAccount),
                    child: Text(localizations.landingDeleteAccount),
                  ),
                  TextButton(
                    onPressed: () => _showSupportDialog(context),
                    child: Text(localizations.landingSupport),
                  ),
                ],
              ),
              Text(
                localizations.appCopyright,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSupportDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('support-contact-dialog'),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(localizations.landingSupport),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.landingSupportDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.large),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const SelectableText(
                  _supportEmail,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(localizations.close),
          ),
          FilledButton.icon(
            key: const Key('support-email-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              launchUrl(Uri(scheme: 'mailto', path: _supportEmail));
            },
            icon: const Icon(Icons.email_outlined),
            label: Text(localizations.landingSupportEmailAction),
          ),
        ],
      ),
    );
  }
}
