import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/profile/presentation/public_legal_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const accountDeletionRequestEmail = 'support@raqmain.ma';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PublicLegalPage(
      pageKey: const Key('delete-account-page'),
      title: localizations.deleteAccountTitle,
      child: DarJarCard(
        key: const Key('delete-account-content'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.deleteAccountIntroduction,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              localizations.deleteAccountRequestTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              localizations.deleteAccountRequestBody(
                accountDeletionRequestEmail,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            const SizedBox(height: AppSpacing.large),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DarJarButton(
                key: const Key('send-delete-account-request'),
                label: localizations.deleteAccountRequestAction,
                icon: Icons.email_outlined,
                onPressed: _sendDeletionRequest,
              ),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              localizations.deleteAccountDeletedDataTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              localizations.deleteAccountDeletedDataBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              localizations.deleteAccountRetentionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              localizations.deleteAccountRetentionBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              localizations.deleteAccountSafetyNotice,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDeletionRequest() async {
    final uri = Uri(
      scheme: 'mailto',
      path: accountDeletionRequestEmail,
      queryParameters: const {
        'subject': 'DarJar account deletion request',
        'body':
            'Registered phone number (including country code):\n\n'
            'Full name:\n\n'
            'I request deletion of my DarJar account and associated data.',
      },
    );
    await launchUrl(uri);
  }
}
