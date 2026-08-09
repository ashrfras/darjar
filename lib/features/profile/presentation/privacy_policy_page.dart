import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final sections = [
      (
        localizations.privacyPolicyDataTitle,
        localizations.privacyPolicyDataBody,
      ),
      (localizations.privacyPolicyUseTitle, localizations.privacyPolicyUseBody),
      (
        localizations.privacyPolicySharingTitle,
        localizations.privacyPolicySharingBody,
      ),
      (
        localizations.privacyPolicyRetentionTitle,
        localizations.privacyPolicyRetentionBody,
      ),
      (
        localizations.privacyPolicySecurityTitle,
        localizations.privacyPolicySecurityBody,
      ),
      (
        localizations.privacyPolicyRightsTitle,
        localizations.privacyPolicyRightsBody,
      ),
      (
        localizations.privacyPolicyChildrenTitle,
        localizations.privacyPolicyChildrenBody,
      ),
      (
        localizations.privacyPolicyChangesTitle,
        localizations.privacyPolicyChangesBody,
      ),
      (
        localizations.privacyPolicyContactTitle,
        localizations.privacyPolicyContactBody,
      ),
    ];

    return SingleChildScrollView(
      key: const Key('privacy-policy-page'),
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
                title: localizations.privacyPolicy,
                fallbackLocation: AppRoutes.profile,
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.privacyPolicyIntroduction,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      localizations.privacyPolicyLastUpdated,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    for (final section in sections) ...[
                      const SizedBox(height: AppSpacing.xLarge),
                      Text(
                        section.$1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        section.$2,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.7),
                      ),
                    ],
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
