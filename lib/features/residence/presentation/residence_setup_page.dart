import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ResidenceSetupMode { create, join }

class ResidenceSetupPage extends StatefulWidget {
  const ResidenceSetupPage({super.key});

  @override
  State<ResidenceSetupPage> createState() => _ResidenceSetupPageState();
}

class _ResidenceSetupPageState extends State<ResidenceSetupPage> {
  ResidenceSetupMode _mode = ResidenceSetupMode.create;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('residence-setup-page'),
      appBar: AppBar(
        title: Text(localizations.appName),
        leading: IconButton(
          tooltip: localizations.back,
          onPressed: () => context.go(AppRoutes.onboarding),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.residenceSetupTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  localizations.residenceSetupDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                SegmentedButton<ResidenceSetupMode>(
                  segments: [
                    ButtonSegment(
                      value: ResidenceSetupMode.create,
                      icon: const Icon(Icons.add_home_work_outlined),
                      label: Text(localizations.createResidence),
                    ),
                    ButtonSegment(
                      value: ResidenceSetupMode.join,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(localizations.joinResidence),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
                const SizedBox(height: AppSpacing.xLarge),
                DarJarCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _mode == ResidenceSetupMode.create
                        ? _CreateResidenceForm(
                            key: const ValueKey('create-residence-form'),
                          )
                        : _JoinResidenceForm(
                            key: const ValueKey('join-residence-form'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateResidenceForm extends StatelessWidget {
  const _CreateResidenceForm({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DarJarTextField(
          label: localizations.residenceName,
          hint: localizations.residenceNameHint,
          prefixIcon: Icons.apartment_rounded,
        ),
        const SizedBox(height: AppSpacing.large),
        DarJarTextField(
          label: localizations.city,
          hint: localizations.cityHint,
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: AppSpacing.large),
        DarJarTextField(
          label: localizations.unit,
          hint: localizations.unitHint,
          prefixIcon: Icons.door_front_door_outlined,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        DarJarButton(
          key: const Key('enter-residence-button'),
          label: localizations.createAndContinue,
          expanded: true,
          onPressed: () => context.go(AppRoutes.community),
        ),
      ],
    );
  }
}

class _JoinResidenceForm extends StatelessWidget {
  const _JoinResidenceForm({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DarJarTextField(
          label: localizations.invitationCode,
          hint: localizations.invitationCodeHint,
          prefixIcon: Icons.key_outlined,
        ),
        const SizedBox(height: AppSpacing.large),
        DarJarTextField(
          label: localizations.unit,
          hint: localizations.unitHint,
          prefixIcon: Icons.door_front_door_outlined,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        DarJarButton(
          label: localizations.joinAndContinue,
          expanded: true,
          onPressed: () => context.go(AppRoutes.community),
        ),
      ],
    );
  }
}
