import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/profile/data/account_deletion_repository.dart';
import 'package:darjar/features/profile/presentation/public_legal_page.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _submitting = false;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final user = ref.watch(authRepositoryProvider).currentUser;
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
              localizations.deleteAccountRequestBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            const SizedBox(height: AppSpacing.large),
            if (_submitted)
              _DeletionRequestedNotice(
                message: localizations.deleteAccountRequestSuccess,
              )
            else if (user == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(localizations.deleteAccountSignInRequired),
                  const SizedBox(height: AppSpacing.medium),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DarJarButton(
                      key: const Key('delete-account-sign-in-button'),
                      label: localizations.deleteAccountSignInAction,
                      icon: Icons.login_rounded,
                      onPressed: () => context.go('/auth'),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const Key('request-account-deletion-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitting ? null : () => _confirmDeletion(user),
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    _submitting
                        ? localizations.deleteAccountRequesting
                        : localizations.deleteAccountRequestAction,
                  ),
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

  Future<void> _confirmDeletion(AuthUser user) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (dialogContext) => AlertDialog(
        key: const Key('account-deletion-confirmation-dialog'),
        title: Text(localizations.deleteAccountConfirmationTitle),
        content: Text(localizations.deleteAccountConfirmationBody),
        actions: [
          TextButton(
            key: const Key('cancel-account-deletion-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const Key('confirm-account-deletion-button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizations.deleteAccountConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final residenceContext = await ref.read(residenceContextProvider.future);
      await ref
          .read(accountDeletionRepositoryProvider)
          .requestDeletion(
            user: user,
            residenceIds: [
              for (final residence in residenceContext.residences) residence.id,
            ],
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (_) {
        // The deletion request is already durable. A failed local sign-out
        // must not invite the user to submit a duplicate request.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(localizations.deleteAccountRequestFailed)),
        );
    }
  }
}

class _DeletionRequestedNotice extends StatelessWidget {
  const _DeletionRequestedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('account-deletion-requested-notice'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
