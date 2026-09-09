import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.onboarding);
          }
        },
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final links = Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.small,
                children: [
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.publicPrivacyPolicy),
                    child: Text(localizations.privacyPolicy),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.deleteAccount),
                    child: Text(localizations.landingDeleteAccount),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.support),
                    child: Text(localizations.landingSupport),
                  ),
                ],
              );
              final copyright = Text(
                localizations.appCopyright,
                key: const Key('public-footer-copyright'),
                textAlign: constraints.maxWidth < 700 ? TextAlign.center : null,
                style: Theme.of(context).textTheme.labelMedium,
              );

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    const DarJarBrand(),
                    const SizedBox(height: AppSpacing.large),
                    links,
                    const SizedBox(height: AppSpacing.large),
                    SizedBox(width: double.infinity, child: copyright),
                  ],
                );
              }

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xLarge,
                runSpacing: AppSpacing.large,
                children: [const DarJarBrand(), links, copyright],
              );
            },
          ),
        ),
      ),
    );
  }
}
