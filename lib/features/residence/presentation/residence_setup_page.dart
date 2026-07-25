import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ResidenceSetupStep { choice, create, join, notFound }

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

    setState(() {
      _step = _step == ResidenceSetupStep.notFound
          ? ResidenceSetupStep.join
          : ResidenceSetupStep.choice;
    });
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
                  ResidenceSetupStep.join => _JoinResidenceForm(
                    key: const ValueKey('join-residence-form'),
                    onVerify: () =>
                        setState(() => _step = ResidenceSetupStep.notFound),
                  ),
                  ResidenceSetupStep.notFound => const _ResidenceNotFound(
                    key: ValueKey('residence-not-found'),
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
          icon: Icons.group_add_outlined,
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

class _CreateResidenceForm extends StatefulWidget {
  const _CreateResidenceForm({super.key});

  @override
  State<_CreateResidenceForm> createState() => _CreateResidenceFormState();
}

class _CreateResidenceFormState extends State<_CreateResidenceForm> {
  String? _selectedCity;
  String _countryCode = '+212';

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

    return Column(
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
                label: localizations.residenceName,
                hint: localizations.residenceNameHint,
                prefixIcon: Icons.apartment_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarTextField(
                key: const Key('residence-address-field'),
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
                onChanged: (value) => setState(() => _selectedCity = value),
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
                  SizedBox(
                    width: 126,
                    child: DropdownButtonFormField<String>(
                      key: const Key('country-code-field'),
                      initialValue: _countryCode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: localizations.countryCode,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '+212',
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text('+212'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _countryCode = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: DarJarTextField(
                      key: const Key('resident-phone-field'),
                      label: localizations.phoneNumber,
                      hint: localizations.localPhoneNumberHint,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DarJarTextField(
                      key: const Key('resident-first-name-field'),
                      label: localizations.firstName,
                      hint: localizations.firstNameHint,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: DarJarTextField(
                      key: const Key('resident-last-name-field'),
                      label: localizations.lastName,
                      hint: localizations.lastNameHint,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarButton(
                key: const Key('enter-residence-button'),
                label: localizations.createAndContinue,
                icon: Icons.arrow_forward_rounded,
                iconAtEnd: true,
                expanded: true,
                onPressed: () => context.go(AppRoutes.community),
              ),
            ],
          ),
        ),
      ],
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

class _JoinResidenceForm extends StatelessWidget {
  const _JoinResidenceForm({required this.onVerify, super.key});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntroduction(
          icon: Icons.phone_android_rounded,
          title: localizations.joinMyResidence,
          description: localizations.joinPhoneDescription,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        DarJarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarTextField(
                key: const Key('join-phone-field'),
                label: localizations.phoneNumber,
                hint: localizations.phoneNumberHint,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.large),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sms_outlined,
                      color: AppColors.primary,
                      size: 21,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        localizations.verificationCodeNotice,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarTextField(
                key: const Key('verification-code-field'),
                label: localizations.verificationCode,
                hint: localizations.verificationCodeHint,
                prefixIcon: Icons.password_rounded,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarButton(
                key: const Key('verify-phone-button'),
                label: localizations.verify,
                expanded: true,
                onPressed: onVerify,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResidenceNotFound extends StatelessWidget {
  const _ResidenceNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxLarge),
        DarJarCard(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: AppColors.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                localizations.phoneNotRegisteredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.phoneNotRegisteredDescription,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
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
