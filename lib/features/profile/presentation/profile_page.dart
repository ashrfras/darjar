import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/localization/app_locale_controller.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/images/app_image_picker.dart';
import 'package:darjar/core/images/storage_image_provider.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/core/widgets/darjar_sign_out_confirmation_dialog.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/features/profile/data/profile_repository.dart';
import 'package:darjar/features/profile/data/profile_image_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
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
  bool _processingImage = false;
  bool _signingOut = false;
  String? _switchingResidenceId;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final residenceContext = ref.watch(residenceContextProvider).value;
    final activeResidence = residenceContext?.activeResidence;
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
                          _EditableProfileAvatar(
                            imagePath: widget.profile.profileImagePath,
                            processing: _processingImage,
                            onSelect: _selectProfileImage,
                            onRemove: widget.profile.profileImagePath.isEmpty
                                ? null
                                : _removeProfileImage,
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
                              isSwitching:
                                  widget.profile.residences[index].id ==
                                  _switchingResidenceId,
                              onTap: () => _switchResidence(
                                widget.profile.residences[index].id,
                              ),
                            ),
                            if (index < widget.profile.residences.length - 1)
                              const Divider(),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                key: const Key('profile-language-card'),
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('language-selection-link'),
                  leading: const Icon(Icons.language_rounded),
                  title: Text(localizations.chooseLanguage),
                  subtitle: Text(switch (Localizations.localeOf(
                    context,
                  ).languageCode) {
                    'zgh' => localizations.amazigh,
                    'en' => localizations.english,
                    _ => localizations.arabic,
                  }),
                  trailing: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.inkMuted,
                    textDirection: TextDirection.ltr,
                  ),
                  onTap: _showLanguageSheet,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                key: const Key('profile-information-links-card'),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileLink(
                      key: const Key('privacy-policy-link'),
                      icon: Icons.privacy_tip_outlined,
                      title: localizations.privacyPolicy,
                      route: AppRoutes.privacyPolicy,
                    ),
                    const Divider(),
                    _ProfileLink(
                      key: const Key('about-app-link'),
                      icon: Icons.info_outline_rounded,
                      title: localizations.aboutApp,
                      route: AppRoutes.aboutApp,
                    ),
                    const Divider(),
                    ListTile(
                      key: const Key('sign-out-button'),
                      enabled: !_signingOut,
                      leading: const Icon(Icons.logout_rounded),
                      title: Text(
                        _signingOut
                            ? localizations.signingOut
                            : localizations.signOut,
                      ),
                      trailing: _signingOut
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.inkMuted,
                              textDirection: TextDirection.ltr,
                            ),
                      onTap: _signingOut ? null : _confirmSignOut,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                key: const Key('delete-account-card'),
                padding: EdgeInsets.zero,
                child: _ProfileLink(
                  key: const Key('delete-account-link'),
                  icon: Icons.delete_outline_rounded,
                  title: localizations.deleteAccountTitle,
                  route: AppRoutes.deleteAccount,
                  isDestructive: true,
                ),
              ),
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

  Future<void> _showLanguageSheet() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => const _LanguageSelectionSheet(),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (context) => const DarJarSignOutConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).signOutFailed)),
        );
    }
  }

  Future<void> _switchResidence(String residenceId) async {
    final residenceContext = ref.read(residenceContextProvider).value;
    if (_switchingResidenceId != null ||
        residenceId == residenceContext?.activeResidenceId) {
      return;
    }
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _switchingResidenceId = residenceId);
    try {
      await ref
          .read(residenceContextRepositoryProvider)
          .setActiveResidence(user: user, residenceId: residenceId);
      ref.invalidate(residenceContextProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).accountResolutionUnexpectedError,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _switchingResidenceId = null);
    }
  }

  Future<void> _selectProfileImage() async {
    if (_processingImage) return;
    final localizations = AppLocalizations.of(context);
    AppImageSelection? selection;
    try {
      selection = await pickAndCompressAppImage();
    } catch (_) {
      if (mounted) _showImageMessage(localizations.imageProcessingFailed);
      return;
    }
    if (selection == null || !mounted) return;
    setState(() => _processingImage = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw const ProfileFailure('signed-out');
      await ref
          .read(profileImageRepositoryProvider)
          .upload(
            userId: user.uid,
            residenceIds: [
              for (final residence in widget.profile.residences) residence.id,
            ],
            bytes: selection.bytes,
          );
      ref.invalidate(storageImageBytesProvider);
      ref.invalidate(residenceMembersProvider);
      ref.invalidate(residenceDirectoryProvider);
      ref.invalidate(residentProfileProvider);
      if (mounted) _showImageMessage(localizations.profileImageSaved);
    } catch (_) {
      if (mounted) _showImageMessage(localizations.imageUploadFailed);
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  Future<void> _removeProfileImage() async {
    if (_processingImage) return;
    final localizations = AppLocalizations.of(context);
    setState(() => _processingImage = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw const ProfileFailure('signed-out');
      await ref
          .read(profileImageRepositoryProvider)
          .remove(
            userId: user.uid,
            residenceIds: [
              for (final residence in widget.profile.residences) residence.id,
            ],
          );
      ref.invalidate(storageImageBytesProvider);
      ref.invalidate(residenceMembersProvider);
      ref.invalidate(residenceDirectoryProvider);
      ref.invalidate(residentProfileProvider);
      if (mounted) _showImageMessage(localizations.profileImageRemoved);
    } catch (_) {
      if (mounted) _showImageMessage(localizations.imageUploadFailed);
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  void _showImageMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LanguageSelectionSheet extends ConsumerWidget {
  const _LanguageSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final selectedLanguage =
        ref.watch(appLocaleProvider).value?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Material(
      key: const Key('language-selection-sheet'),
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.large,
            AppSpacing.large,
            AppSpacing.xLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.chooseLanguage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.medium),
              _LanguageOption(
                key: const Key('language-option-ar'),
                flag: const _LanguageFlag(
                  key: Key('arabic-language-flag'),
                  painter: _ArabicFlagPainter(),
                ),
                label: localizations.arabic,
                selected: selectedLanguage == 'ar',
                onTap: () => _select(context, ref, const Locale('ar')),
              ),
              _LanguageOption(
                key: const Key('language-option-zgh'),
                flag: const _LanguageFlag(
                  key: Key('amazigh-language-flag'),
                  painter: _AmazighFlagPainter(),
                ),
                label: localizations.amazigh,
                selected: selectedLanguage == 'zgh',
                onTap: () => _select(context, ref, const Locale('zgh')),
              ),
              _LanguageOption(
                key: const Key('language-option-en'),
                flag: const _LanguageFlag(
                  key: Key('english-language-flag'),
                  painter: _BritishFlagPainter(),
                ),
                label: localizations.english,
                selected: selectedLanguage == 'en',
                onTap: () => _select(context, ref, const Locale('en')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, Locale locale) {
    ref.read(appLocaleProvider.notifier).select(locale);
    Navigator.of(context).pop();
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.selected,
    this.onTap,
    super.key,
  });

  final Widget flag;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: onTap != null,
      leading: flag,
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({required this.painter, super.key});

  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 40,
        height: 28,
        child: CustomPaint(painter: painter),
      ),
    );
  }
}

class _ArabicFlagPainter extends CustomPainter {
  const _ArabicFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF178A55),
    );

    final symbol = TextPainter(
      text: const TextSpan(
        text: 'ع',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    symbol.paint(
      canvas,
      Offset(
        (size.width - symbol.width) / 2,
        (size.height - symbol.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ArabicFlagPainter oldDelegate) => false;
}

class _AmazighFlagPainter extends CustomPainter {
  const _AmazighFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bandHeight = size.height / 3;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, bandHeight),
        Paint()..color = const Color(0xFF2F72B7),
      )
      ..drawRect(
        Rect.fromLTWH(0, bandHeight, size.width, bandHeight),
        Paint()..color = const Color(0xFF4BAE4F),
      )
      ..drawRect(
        Rect.fromLTWH(0, bandHeight * 2, size.width, bandHeight),
        Paint()..color = const Color(0xFFF3D64E),
      );

    final symbol = TextPainter(
      text: const TextSpan(
        text: 'ⵣ',
        style: TextStyle(
          color: Color(0xFFD3222A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    symbol.paint(
      canvas,
      Offset(
        (size.width - symbol.width) / 2,
        (size.height - symbol.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AmazighFlagPainter oldDelegate) => false;
}

class _BritishFlagPainter extends CustomPainter {
  const _BritishFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF21468B),
    );

    final whiteDiagonal = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.22
      ..strokeCap = StrokeCap.square;
    final redDiagonal = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = size.height * 0.09
      ..strokeCap = StrokeCap.square;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), whiteDiagonal)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), whiteDiagonal)
      ..drawLine(Offset.zero, Offset(size.width, size.height), redDiagonal)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), redDiagonal);

    canvas
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.36, size.width, size.height * 0.28),
        Paint()..color = Colors.white,
      )
      ..drawRect(
        Rect.fromLTWH(size.width * 0.39, 0, size.width * 0.22, size.height),
        Paint()..color = Colors.white,
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.16),
        Paint()..color = const Color(0xFFC8102E),
      )
      ..drawRect(
        Rect.fromLTWH(size.width * 0.44, 0, size.width * 0.12, size.height),
        Paint()..color = const Color(0xFFC8102E),
      );
  }

  @override
  bool shouldRepaint(covariant _BritishFlagPainter oldDelegate) => false;
}

class _EditableProfileAvatar extends ConsumerWidget {
  const _EditableProfileAvatar({
    required this.imagePath,
    required this.processing,
    required this.onSelect,
    required this.onRemove,
  });

  final String imagePath;
  final bool processing;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final pathParts = imagePath.split('/');
    final userId = pathParts.length > 1 ? pathParts[1] : '';
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DarJarUserAvatar(
            userId: userId,
            radius: 42,
            showImage: imagePath.isNotEmpty,
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: PopupMenuButton<_ProfileImageAction>(
              key: const Key('profile-image-menu-button'),
              tooltip: localizations.edit,
              enabled: !processing,
              onSelected: (action) {
                switch (action) {
                  case _ProfileImageAction.select:
                    onSelect();
                    return;
                  case _ProfileImageAction.remove:
                    onRemove?.call();
                    return;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const Key('select-profile-image-button'),
                  value: _ProfileImageAction.select,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_a_photo_outlined),
                    title: Text(
                      imagePath.isEmpty
                          ? localizations.addImage
                          : localizations.changeImage,
                    ),
                  ),
                ),
                if (onRemove != null)
                  PopupMenuItem(
                    key: const Key('remove-profile-image-button'),
                    value: _ProfileImageAction.remove,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: Text(localizations.removeImage),
                    ),
                  ),
              ],
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                ),
                alignment: Alignment.center,
                child: processing
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.edit_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProfileImageAction { select, remove }

class _ResidenceItem extends StatelessWidget {
  const _ResidenceItem({
    required this.residence,
    required this.isCurrent,
    required this.isSwitching,
    required this.onTap,
  });

  final ProfileResidence residence;
  final bool isCurrent;
  final bool isSwitching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final apartmentNumber = residence.apartmentNumber;
    return ListTile(
      key: ValueKey('profile-residence-${residence.id}'),
      leading: DarJarResidenceAvatar(
        residenceId: residence.id,
        hasImage: residence.hasImage,
        size: 40,
      ),
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
      trailing: isSwitching
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isCurrent
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.inkMuted,
              size: 16,
            ),
      onTap: isCurrent || isSwitching ? null : onTap,
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
                      helper: localizations.lastNamePrivacyHint,
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

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.route,
    this.isDestructive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String route;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.danger : null),
      title: Text(
        title,
        style: isDestructive ? const TextStyle(color: AppColors.danger) : null,
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        color: AppColors.inkMuted,
        textDirection: TextDirection.ltr,
      ),
      onTap: () => context.push(route),
    );
  }
}
