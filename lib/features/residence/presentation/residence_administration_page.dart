import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/profile/data/profile_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_reset_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResidenceAdministrationPage extends ConsumerStatefulWidget {
  const ResidenceAdministrationPage({super.key});

  @override
  ConsumerState<ResidenceAdministrationPage> createState() =>
      _ResidenceAdministrationPageState();
}

class _ResidenceAdministrationPageState
    extends ConsumerState<ResidenceAdministrationPage> {
  bool _resettingResidence = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final activeResidence = ref
        .watch(residenceContextProvider)
        .value
        ?.activeResidence;
    if (activeResidence?.canManageResidence != true) {
      return const _AdministrationRedirect();
    }
    final isPresident =
        activeResidence!.role == 'president' || activeResidence.role == 'owner';

    return SingleChildScrollView(
      key: const Key('residence-administration-page'),
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
              DarJarPageHeader(
                title: localizations.residenceAdministration,
                description: localizations.residenceAdministrationDescription,
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                key: const Key('residence-management-section'),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ManagementLink(
                      key: const Key('manage-residence-link'),
                      icon: Icons.domain_outlined,
                      title: localizations.residenceSettings,
                      description: localizations.residenceManagementDescription,
                      route: AppRoutes.manageResidence,
                    ),
                    const Divider(),
                    _ManagementLink(
                      key: const Key('manage-apartments-link'),
                      icon: Icons.apartment_outlined,
                      title: localizations.apartments,
                      description:
                          localizations.apartmentsManagementDescription,
                      route: AppRoutes.manageApartments,
                    ),
                    const Divider(),
                    _ManagementLink(
                      key: const Key('manage-dues-link'),
                      icon: Icons.receipt_long_outlined,
                      title: localizations.duesManagement,
                      description: localizations.duesManagementDescription,
                      route: AppRoutes.manageDues,
                    ),
                    const Divider(),
                    _ManagementLink(
                      key: const Key('manage-finances-link'),
                      icon: Icons.account_balance_wallet_outlined,
                      title: localizations.financeManagement,
                      description: localizations.manageFinanceDescription,
                      route: AppRoutes.manageFinances,
                    ),
                    const Divider(),
                    _ManagementLink(
                      key: const Key('manage-documents-link'),
                      icon: Icons.folder_outlined,
                      title: localizations.documentsManagement,
                      description: localizations.documentsManagementDescription,
                      route: AppRoutes.manageDocuments,
                    ),
                  ],
                ),
              ),
              if (isPresident) ...[
                const SizedBox(height: AppSpacing.large),
                DarJarCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    key: const Key('reset-residence-button'),
                    enabled: !_resettingResidence,
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: Text(
                      _resettingResidence
                          ? localizations.resetResidenceInProgress
                          : localizations.resetResidence,
                    ),
                    subtitle: Text(localizations.resetResidenceDescription),
                    trailing: _resettingResidence
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.inkMuted,
                            textDirection: TextDirection.ltr,
                          ),
                    onTap: _resettingResidence
                        ? null
                        : () => _confirmResidenceReset(activeResidence),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmResidenceReset(UserResidence residence) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (context) => AlertDialog(
        key: const Key('reset-residence-confirmation-dialog'),
        title: Text(localizations.resetResidenceConfirmationTitle),
        content: Text(localizations.resetResidenceConfirmationDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton.icon(
            key: const Key('send-reset-verification-code-button'),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.sms_outlined),
            label: Text(localizations.resetResidenceSendCode),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    final phoneNumber = user?.phoneNumber;
    if (user == null || phoneNumber == null || phoneNumber.isEmpty) {
      _showResetFailure(localizations.resetResidenceFailed);
      return;
    }

    setState(() => _resettingResidence = true);
    try {
      await auth.sendVerificationCode(
        phoneNumber,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      final code = await _showResetCodeDialog();
      if (code == null || !mounted) {
        setState(() => _resettingResidence = false);
        return;
      }
      await auth.confirmVerificationCode(code);
      final verifiedUser = auth.currentUser;
      if (verifiedUser == null || verifiedUser.uid != user.uid) {
        throw const ResidenceResetFailure('identity-mismatch');
      }
      final profile = await ref.read(residentProfileProvider.future);
      await ref
          .read(residenceResetRepositoryProvider)
          .reset(
            residenceId: residence.id,
            president: verifiedUser,
            presidentName: profile.fullName,
          );
      ref
        ..invalidate(residenceContextProvider)
        ..invalidate(residenceMembersProvider)
        ..invalidate(residenceDirectoryProvider)
        ..invalidate(residentProfileProvider);
      if (!mounted) return;
      setState(() => _resettingResidence = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.resetResidenceSuccess)),
      );
      context.go(AppRoutes.community);
    } on AuthFailure {
      if (!mounted) return;
      setState(() => _resettingResidence = false);
      _showResetFailure(localizations.resetResidenceInvalidCode);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resettingResidence = false);
      _showResetFailure(localizations.resetResidenceFailed);
    }
  }

  Future<String?> _showResetCodeDialog() async {
    final controller = TextEditingController();
    final localizations = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (dialogContext) => AlertDialog(
        key: const Key('reset-residence-code-dialog'),
        title: Text(localizations.resetResidenceCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(localizations.resetResidenceCodeDescription),
            const SizedBox(height: AppSpacing.medium),
            DarJarTextField(
              key: const Key('reset-residence-code-field'),
              controller: controller,
              label: localizations.resetResidenceCodeHint,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            key: const Key('confirm-residence-reset-button'),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(dialogContext).pop(value);
            },
            child: Text(localizations.resetResidenceConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showResetFailure(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ManagementLink extends StatelessWidget {
  const _ManagementLink({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        textDirection: TextDirection.ltr,
      ),
      onTap: () => context.go(route),
    );
  }
}

class _AdministrationRedirect extends StatefulWidget {
  const _AdministrationRedirect();

  @override
  State<_AdministrationRedirect> createState() =>
      _AdministrationRedirectState();
}

class _AdministrationRedirectState extends State<_AdministrationRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.community);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
