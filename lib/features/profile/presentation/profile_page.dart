import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/profile/data/profile_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(residentProfileProvider);
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: DarJarButton(
          label: AppLocalizations.of(context).accountResolutionRetry,
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(residentProfileProvider),
        ),
      ),
      data: (data) => _ProfileContent(
        key: ValueKey('${data.firstName}-${data.lastName}'),
        profile: data,
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.profile, super.key});

  final ResidentProfile profile;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final residenceContext = ref.watch(residenceContextProvider).value;
    final activeResidence = residenceContext?.activeResidence;
    final canManageResidence = activeResidence?.canManageResidence ?? false;
    final roleLabel = switch (activeResidence?.role) {
      'president' || 'owner' => localizations.profileRolePresident,
      'deputy' || 'manager' => localizations.profileRoleDeputy,
      'treasurer' || 'moderator' => localizations.profileRoleTreasurer,
      _ => localizations.profileRoleResident,
    };

    return SingleChildScrollView(
      key: const Key('profile-page'),
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
                title: localizations.profile,
                fallbackLocation: AppRoutes.community,
              ),
              const SizedBox(height: AppSpacing.small),
              DarJarCard(
                key: const Key('profile-information-card'),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: DarJarButton(
                        key: const Key('edit-profile-name-button'),
                        label: localizations.edit,
                        icon: Icons.edit_outlined,
                        variant: DarJarButtonVariant.tertiary,
                        onPressed: _showEditNameSheet,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                            child: Icon(Icons.person_rounded, size: 44),
                          ),
                          const SizedBox(height: AppSpacing.large),
                          Text(
                            widget.profile.fullName,
                            key: const Key('profile-full-name'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          DarJarPhoneNumber(
                            widget.profile.phoneNumber,
                            key: const Key('profile-phone-number'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          DarJarBadge(
                            label: roleLabel,
                            tone: DarJarBadgeTone.info,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                localizations.profileResidences,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarCard(
                key: const Key('profile-residences-card'),
                padding: EdgeInsets.zero,
                child: widget.profile.residences.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        child: Text(localizations.profileNoResidences),
                      )
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < widget.profile.residences.length;
                            index++
                          ) ...[
                            _ResidenceItem(
                              residence: widget.profile.residences[index],
                              isCurrent:
                                  widget.profile.residences[index].id ==
                                  residenceContext?.activeResidenceId,
                            ),
                            if (index < widget.profile.residences.length - 1)
                              const Divider(),
                          ],
                        ],
                      ),
              ),
              if (canManageResidence) ...[
                const SizedBox(height: AppSpacing.large),
                Text(
                  localizations.residenceAdministration,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.medium),
                DarJarCard(
                  key: const Key('residence-management-section'),
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ManagementLink(
                        key: const Key('manage-residence-link'),
                        icon: Icons.domain_outlined,
                        title: localizations.residenceSettings,
                        description:
                            localizations.residenceManagementDescription,
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditNameSheet() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => _EditProfileNameSheet(profile: widget.profile),
    );
  }
}

class _ResidenceItem extends StatelessWidget {
  const _ResidenceItem({required this.residence, required this.isCurrent});

  final ProfileResidence residence;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final apartmentNumber = residence.apartmentNumber;
    return ListTile(
      key: ValueKey('profile-residence-${residence.id}'),
      leading: const Icon(Icons.apartment_outlined, color: AppColors.primary),
      title: Row(
        children: [
          Flexible(
            child: Text(
              localizations.residenceDisplayName(
                normalizeResidenceName(residence.name),
              ),
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: AppSpacing.small),
            DarJarBadge(
              key: const Key('current-profile-residence-badge'),
              label: localizations.currentResidence,
              tone: DarJarBadgeTone.info,
            ),
          ],
        ],
      ),
      subtitle: Text(
        apartmentNumber == null || apartmentNumber.isEmpty
            ? localizations.profileApartmentNotAssigned
            : localizations.profileApartmentNumber(apartmentNumber),
      ),
    );
  }
}

class _EditProfileNameSheet extends ConsumerStatefulWidget {
  const _EditProfileNameSheet({required this.profile});

  final ResidentProfile profile;

  @override
  ConsumerState<_EditProfileNameSheet> createState() =>
      _EditProfileNameSheetState();
}

class _EditProfileNameSheetState extends ConsumerState<_EditProfileNameSheet> {
  late final TextEditingController _firstNameController = TextEditingController(
    text: widget.profile.firstName,
  );
  late final TextEditingController _lastNameController = TextEditingController(
    text: widget.profile.lastName,
  );
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.medium,
      ),
      child: DecoratedBox(
        key: const Key('edit-profile-name-sheet'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2417151D),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.editProfileName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          localizations.editProfileNameDescription,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('close-edit-profile-name-sheet'),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.inkMuted,
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Column(
                  children: [
                    DarJarTextField(
                      key: const Key('profile-first-name-field'),
                      label: localizations.firstName,
                      controller: _firstNameController,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    DarJarTextField(
                      key: const Key('profile-last-name-field'),
                      label: localizations.lastName,
                      controller: _lastNameController,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.medium),
                Text(
                  _errorMessage!,
                  key: const Key('edit-profile-name-error'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              Row(
                children: [
                  Expanded(
                    child: DarJarButton(
                      label: localizations.cancel,
                      variant: DarJarButtonVariant.secondary,
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: DarJarButton(
                      key: const Key('save-profile-button'),
                      label: _isSaving
                          ? localizations.profileSaving
                          : localizations.saveChanges,
                      icon: Icons.save_outlined,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final localizations = AppLocalizations.of(context);
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorMessage = localizations.profileNameRequired);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(residentProfileProvider.notifier)
          .updateNames(firstName: firstName, lastName: lastName);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(localizations.profileSaved)));
    } on ProfileFailure {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = localizations.setupUnexpectedError;
        });
      }
    }
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
