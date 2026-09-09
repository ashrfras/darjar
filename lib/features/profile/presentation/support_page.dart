import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/profile/presentation/public_legal_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const supportEmail = 'support@raqmain.ma';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PublicLegalPage(
      pageKey: const Key('public-support-page'),
      title: localizations.landingSupport,
      child: DarJarCard(
        key: const Key('support-page-content'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.center,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              localizations.landingSupportDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xLarge),
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
                supportEmail,
                key: Key('support-email-address'),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Align(
              alignment: AlignmentDirectional.center,
              child: FilledButton.icon(
                key: const Key('support-email-button'),
                onPressed: () => unawaited(
                  launchUrl(Uri(scheme: 'mailto', path: supportEmail)),
                ),
                icon: const Icon(Icons.email_outlined),
                label: Text(localizations.landingSupportEmailAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
