import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountResolutionPage extends ConsumerStatefulWidget {
  const AccountResolutionPage({super.key});

  @override
  ConsumerState<AccountResolutionPage> createState() =>
      _AccountResolutionPageState();
}

class _AccountResolutionPageState extends ConsumerState<AccountResolutionPage> {
  final Set<String> _selectedInvitationPaths = {};
  bool _isSubmitting = false;
  String? _errorCode;

  @override
  Widget build(BuildContext context) {
    final resolution = ref.watch(accountResolutionProvider);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('account-resolution-page'),
      appBar: AppBar(
        title: Text(
          localizations.appName,
          style: AppTypography.brandArabic.copyWith(
            color: AppColors.ink,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          key: const Key('account-resolution-sign-out-button'),
          tooltip: localizations.back,
          onPressed: _isSubmitting ? null : _signOut,
          icon: const BackButtonIcon(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: resolution.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _LoadError(
            message: _errorMessage(localizations, error),
            retryLabel: localizations.accountResolutionRetry,
            onRetry: () => ref.invalidate(accountResolutionProvider),
          ),
          data: (data) {
            if (data.profile != null || data.invitations.isEmpty) {
              return _ResolutionRedirect(
                destination: data.profile == null
                    ? AppRoutes.residenceSetup
                    : AppRoutes.community,
              );
            }
            return _InvitationConfirmation(
              resolution: data,
              selectedInvitationPaths: _selectedInvitationPaths,
              isSubmitting: _isSubmitting,
              errorMessage: _errorCode == null
                  ? null
                  : _errorMessage(localizations, _errorCode!),
              onChanged: (path, selected) {
                setState(() {
                  if (selected) {
                    _selectedInvitationPaths.add(path);
                  } else {
                    _selectedInvitationPaths.remove(path);
                  }
                  _errorCode = null;
                });
              },
              onConfirm: _selectedInvitationPaths.isEmpty || _isSubmitting
                  ? null
                  : () => _acceptSelected(data),
            );
          },
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) {
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _acceptSelected(AccountResolution resolution) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      setState(() => _errorCode = 'signed-out');
      return;
    }
    final selected = resolution.invitations
        .where(
          (invitation) => _selectedInvitationPaths.contains(invitation.path),
        )
        .toList(growable: false);

    setState(() {
      _isSubmitting = true;
      _errorCode = null;
    });
    try {
      await ref
          .read(accountOnboardingRepositoryProvider)
          .acceptInvitations(
            user: user,
            resolution: resolution,
            invitations: selected,
          );
      if (mounted) {
        ref.invalidate(accountResolutionProvider);
        context.go(AppRoutes.community);
      }
    } on AccountOnboardingFailure catch (error) {
      if (mounted) {
        setState(() => _errorCode = error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCode = 'unknown');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _errorMessage(AppLocalizations localizations, Object error) {
    final code = switch (error) {
      AccountOnboardingFailure(:final code) => code,
      String value => value,
      _ => 'unknown',
    };
    final message = switch (code) {
      'permission-denied' => localizations.accountResolutionPermissionDenied,
      'failed-precondition' =>
        localizations.accountResolutionFailedPrecondition,
      'unavailable' ||
      'network-request-failed' => localizations.authNetworkError,
      'missing-profile-data' => localizations.accountResolutionMissingProfile,
      'signed-out' ||
      'missing-phone-number' => localizations.accountResolutionSignedOut,
      _ => localizations.accountResolutionUnexpectedError,
    };
    final details = error is AccountOnboardingFailure ? error.details : null;
    if (!kDebugMode) {
      return message;
    }
    final technicalDetails = details == null || details.isEmpty
        ? code
        : '$code: $details';
    return '$message\n[$technicalDetails]';
  }
}

class _ResolutionRedirect extends StatefulWidget {
  const _ResolutionRedirect({required this.destination});

  final String destination;

  @override
  State<_ResolutionRedirect> createState() => _ResolutionRedirectState();
}

class _ResolutionRedirectState extends State<_ResolutionRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(widget.destination);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _InvitationConfirmation extends StatelessWidget {
  const _InvitationConfirmation({
    required this.resolution,
    required this.selectedInvitationPaths,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onChanged,
    required this.onConfirm,
  });

  final AccountResolution resolution;
  final Set<String> selectedInvitationPaths;
  final bool isSubmitting;
  final String? errorMessage;
  final void Function(String path, bool selected) onChanged;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final profile = resolution.displayedProfile!;
    final phoneNumber = resolution.phoneNumber;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.accountResolutionTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.accountResolutionDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                key: const Key('invited-person-summary'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.yourInformation,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _InformationRow(
                      icon: Icons.person_outline_rounded,
                      label: localizations.accountResolutionFullName,
                      value: profile.fullName,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _InformationRow(
                      icon: Icons.phone_outlined,
                      label: localizations.phoneNumber,
                      value: phoneNumber,
                      ltr: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),
              Text(
                localizations.accountResolutionInvitationsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                localizations.accountResolutionInvitationsDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.medium),
              for (final invitation in resolution.invitations) ...[
                _InvitationCard(
                  invitation: invitation,
                  selected: selectedInvitationPaths.contains(invitation.path),
                  onChanged: (selected) => onChanged(invitation.path, selected),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (errorMessage != null) ...[
                _InlineError(message: errorMessage!),
                const SizedBox(height: AppSpacing.medium),
              ],
              DarJarButton(
                key: const Key('accept-selected-invitations-button'),
                label: isSubmitting
                    ? localizations.accountResolutionAccepting
                    : localizations.accountResolutionConfirm,
                icon: Icons.check_circle_outline_rounded,
                expanded: true,
                onPressed: onConfirm,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.accountResolutionPendingNotice,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.selected,
    required this.onChanged,
  });

  final ResidenceInvitation invitation;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      key: ValueKey('residence-invitation-${invitation.id}'),
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        key: ValueKey('residence-invitation-checkbox-${invitation.id}'),
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.all(AppSpacing.medium),
        title: Text(
          invitation.residenceName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invitation.residenceAddress.isNotEmpty)
                Text(invitation.residenceAddress),
              Text(
                localizations.accountResolutionRole(
                  _localizedRole(localizations, invitation.role),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedRole(AppLocalizations localizations, String role) {
    return switch (role) {
      'owner' => localizations.accountRoleOwner,
      'manager' => localizations.accountRoleManager,
      'moderator' => localizations.accountRoleModerator,
      _ => localizations.accountRoleResident,
    };
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
              Directionality(
                textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.large),
              DarJarButton(label: retryLabel, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
