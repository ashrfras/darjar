import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum ResidenceSetupStep { choice, create, join }

class ResidenceSetupPage extends StatefulWidget {
  const ResidenceSetupPage({super.key});

  @override
  State<ResidenceSetupPage> createState() => _ResidenceSetupPageState();
}

class _ResidenceSetupPageState extends State<ResidenceSetupPage> {
  ResidenceSetupStep _step = ResidenceSetupStep.choice;

  void _goBack() {
    if (_step == ResidenceSetupStep.choice) {
      context.go(AppRoutes.onboarding);
      return;
    }
    setState(() => _step = ResidenceSetupStep.choice);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('residence-setup-page'),
      appBar: AppBar(
        title: Text(
          localizations.appName,
          key: const Key('setup-brand-title'),
          style: AppTypography.brandArabic.copyWith(
            color: AppColors.ink,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          key: const Key('residence-setup-back-button'),
          tooltip: localizations.back,
          onPressed: _goBack,
          icon: const BackButtonIcon(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_step) {
                  ResidenceSetupStep.choice => _ResidenceChoice(
                    key: const ValueKey('residence-choice'),
                    onCreate: () =>
                        setState(() => _step = ResidenceSetupStep.create),
                    onJoin: () =>
                        setState(() => _step = ResidenceSetupStep.join),
                  ),
                  ResidenceSetupStep.create => const _CreateResidenceForm(
                    key: ValueKey('create-residence-form'),
                  ),
                  ResidenceSetupStep.join => const _JoinResidenceForm(
                    key: ValueKey('join-residence-form'),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResidenceChoice extends StatelessWidget {
  const _ResidenceChoice({
    required this.onCreate,
    required this.onJoin,
    super.key,
  });

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntroduction(
          icon: Icons.apartment_rounded,
          title: localizations.residenceSetupTitle,
          description: localizations.residenceSetupDescription,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        _ChoiceCard(
          key: const Key('join-my-residence-option'),
          icon: Icons.password_rounded,
          title: localizations.joinMyResidence,
          description: localizations.joinMyResidenceDescription,
          onTap: onJoin,
        ),
        const SizedBox(height: AppSpacing.large),
        _ChoiceCard(
          key: const Key('create-new-residence-option'),
          icon: Icons.add_home_work_outlined,
          title: localizations.createNewResidence,
          description: localizations.createNewResidenceDescription,
          onTap: onCreate,
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.inkMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateResidenceForm extends ConsumerStatefulWidget {
  const _CreateResidenceForm({super.key});

  @override
  ConsumerState<_CreateResidenceForm> createState() =>
      _CreateResidenceFormState();
}

class _CreateResidenceFormState extends ConsumerState<_CreateResidenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedCity;
  bool _isSubmitting = false;
  String? _errorCode;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final cities = <(String, String)>[
      ('casablanca', localizations.cityCasablanca),
      ('rabat', localizations.cityRabat),
      ('marrakesh', localizations.cityMarrakesh),
      ('tangier', localizations.cityTangier),
      ('agadir', localizations.cityAgadir),
      ('fes', localizations.cityFes),
    ];
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIntroduction(
            icon: Icons.add_home_work_outlined,
            title: localizations.createNewResidence,
            description: localizations.createResidenceFormDescription,
          ),
          const SizedBox(height: AppSpacing.xLarge),
          DarJarCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FormSectionTitle(
                  icon: Icons.apartment_rounded,
                  title: localizations.residenceInformation,
                ),
                const SizedBox(height: AppSpacing.large),
                DarJarTextField(
                  key: const Key('residence-name-field'),
                  controller: _nameController,
                  label: localizations.residenceName,
                  hint: localizations.residenceNameHint,
                  helper: localizations.residenceNameGuidance,
                  prefixIcon: Icons.apartment_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.large),
                DarJarTextField(
                  key: const Key('residence-address-field'),
                  controller: _addressController,
                  label: localizations.address,
                  hint: localizations.residenceAddressHint,
                  prefixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.large),
                DropdownButtonFormField<String>(
                  key: const Key('residence-city-field'),
                  initialValue: _selectedCity,
                  decoration: InputDecoration(
                    labelText: localizations.city,
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                  hint: Text(localizations.citySelectHint),
                  items: [
                    for (final city in cities)
                      DropdownMenuItem(value: city.$1, child: Text(city.$2)),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedCity = value),
                  validator: (value) =>
                      value == null ? localizations.setupFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                const Divider(),
                const SizedBox(height: AppSpacing.xLarge),
                _FormSectionTitle(
                  icon: Icons.person_outline_rounded,
                  title: localizations.yourInformation,
                ),
                const SizedBox(height: AppSpacing.large),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DarJarTextField(
                        key: const Key('resident-first-name-field'),
                        controller: _firstNameController,
                        label: localizations.firstName,
                        hint: localizations.firstNameHint,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: DarJarTextField(
                        key: const Key('resident-last-name-field'),
                        controller: _lastNameController,
                        label: localizations.lastName,
                        hint: localizations.lastNameHint,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                if (_errorCode != null) ...[
                  const SizedBox(height: AppSpacing.large),
                  _SetupError(
                    message: _setupErrorMessage(localizations, _errorCode!),
                  ),
                ],
                const SizedBox(height: AppSpacing.xLarge),
                DarJarButton(
                  key: const Key('enter-residence-button'),
                  label: _isSubmitting
                      ? localizations.creatingResidence
                      : localizations.createAndContinue,
                  icon: Icons.arrow_forward_rounded,
                  iconAtEnd: true,
                  expanded: true,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final missingText = [
      _nameController.text,
      _addressController.text,
      _firstNameController.text,
      _lastNameController.text,
    ].any((value) => value.trim().isEmpty);
    if (missingText || !_formKey.currentState!.validate()) {
      setState(() => _errorCode = 'invalid-data');
      return;
    }
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      setState(() => _errorCode = 'signed-out');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorCode = null;
    });
    try {
      await ref
          .read(residenceSetupRepositoryProvider)
          .createResidence(
            user: user,
            input: CreateResidenceInput(
              name: normalizeResidenceName(_nameController.text),
              address: _addressController.text,
              city: _selectedCity!,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
            ),
          );
      if (mounted) {
        context.go(AppRoutes.community);
      }
    } on ResidenceSetupFailure catch (error) {
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
}

class _JoinResidenceForm extends ConsumerStatefulWidget {
  const _JoinResidenceForm({super.key});

  @override
  ConsumerState<_JoinResidenceForm> createState() => _JoinResidenceFormState();
}

class _JoinResidenceFormState extends ConsumerState<_JoinResidenceForm> {
  final _codeController = TextEditingController();
  ResidenceCodeSummary? _residence;
  bool _isSearching = false;
  bool _isJoining = false;
  bool _requestSent = false;
  String? _errorCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntroduction(
          icon: Icons.password_rounded,
          title: localizations.joinMyResidence,
          description: localizations.joinCodeDescription,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        DarJarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarTextField(
                key: const Key('join-residence-code-field'),
                controller: _codeController,
                label: localizations.invitationCode,
                hint: localizations.invitationCodeHint,
                prefixIcon: Icons.key_rounded,
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.search,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
                  LengthLimitingTextInputFormatter(14),
                ],
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarButton(
                key: const Key('search-residence-button'),
                label: _isSearching
                    ? localizations.searchingResidence
                    : localizations.searchResidence,
                icon: Icons.search_rounded,
                expanded: true,
                onPressed: _isSearching || _isJoining ? null : _search,
              ),
              if (_errorCode != null) ...[
                const SizedBox(height: AppSpacing.large),
                if (_errorCode == 'not-found')
                  const _ResidenceNotFound()
                else
                  _SetupError(
                    message: _setupErrorMessage(localizations, _errorCode!),
                  ),
              ],
              if (_residence != null) ...[
                const SizedBox(height: AppSpacing.xLarge),
                _ResidenceSearchResult(
                  residence: _residence!,
                  isJoining: _isJoining,
                  requestSent: _requestSent,
                  onJoin: _requestSent || !_residence!.joinRequestsEnabled
                      ? null
                      : _join,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _search() async {
    final code = normalizeResidenceCode(_codeController.text);
    if (!isValidResidenceCode(code)) {
      setState(() {
        _residence = null;
        _errorCode = 'invalid-code';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _residence = null;
      _requestSent = false;
      _errorCode = null;
    });
    try {
      final residence = await ref
          .read(residenceSetupRepositoryProvider)
          .findByCode(code);
      if (mounted) {
        setState(() {
          _residence = residence;
          _errorCode = residence == null ? 'not-found' : null;
        });
      }
    } on ResidenceSetupFailure catch (error) {
      if (mounted) {
        setState(() => _errorCode = error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCode = 'unknown');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _join() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final residence = _residence;
    if (user == null || residence == null) {
      setState(() => _errorCode = 'signed-out');
      return;
    }
    setState(() {
      _isJoining = true;
      _errorCode = null;
    });
    try {
      await ref
          .read(residenceSetupRepositoryProvider)
          .requestToJoin(user: user, residence: residence);
      if (mounted) {
        setState(() => _requestSent = true);
      }
    } on ResidenceSetupFailure catch (error) {
      if (mounted) {
        setState(() => _errorCode = error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCode = 'unknown');
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}

class _ResidenceSearchResult extends StatelessWidget {
  const _ResidenceSearchResult({
    required this.residence,
    required this.isJoining,
    required this.requestSent,
    required this.onJoin,
  });

  final ResidenceCodeSummary residence;
  final bool isJoining;
  final bool requestSent;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      key: const Key('residence-search-result'),
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            requestSent
                ? Icons.mark_email_read_outlined
                : Icons.apartment_rounded,
            color: AppColors.primary,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            requestSent ? localizations.joinRequestSent : residence.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            requestSent
                ? localizations.joinRequestSentDescription
                : '${residence.address} · ${_cityName(localizations)}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          if (!requestSent) ...[
            const SizedBox(height: AppSpacing.large),
            DarJarButton(
              key: const Key('join-found-residence-button'),
              label: !residence.joinRequestsEnabled
                  ? localizations.joinRequestsClosed
                  : isJoining
                  ? localizations.sendingJoinRequest
                  : localizations.joinResidence,
              expanded: true,
              onPressed: isJoining ? null : onJoin,
            ),
          ],
        ],
      ),
    );
  }

  String _cityName(AppLocalizations localizations) {
    return switch (residence.city) {
      'casablanca' => localizations.cityCasablanca,
      'rabat' => localizations.cityRabat,
      'marrakesh' => localizations.cityMarrakesh,
      'tangier' => localizations.cityTangier,
      'agadir' => localizations.cityAgadir,
      'fes' => localizations.cityFes,
      _ => residence.city,
    };
  }
}

class _ResidenceNotFound extends StatelessWidget {
  const _ResidenceNotFound();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('residence-not-found'),
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home_work_outlined,
            color: AppColors.warning,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            localizations.residenceCodeNotFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            localizations.residenceCodeNotFoundDescription,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.small),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _StepIntroduction extends StatelessWidget {
  const _StepIntroduction({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: AppSpacing.medium),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.small),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _SetupError extends StatelessWidget {
  const _SetupError({required this.message});

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

String _setupErrorMessage(AppLocalizations localizations, String code) {
  return switch (code) {
    'invalid-data' => localizations.setupCompleteRequiredFields,
    'invalid-code' => localizations.residenceCodeInvalid,
    'permission-denied' => localizations.accountResolutionPermissionDenied,
    'join-requests-disabled' => localizations.joinRequestsClosed,
    'unavailable' => localizations.authNetworkError,
    'signed-out' ||
    'missing-phone-number' => localizations.accountResolutionSignedOut,
    _ => localizations.setupUnexpectedError,
  };
}
