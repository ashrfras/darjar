import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateMaintenancePage extends ConsumerStatefulWidget {
  const CreateMaintenancePage({super.key});

  @override
  ConsumerState<CreateMaintenancePage> createState() =>
      _CreateMaintenancePageState();
}

class _CreateMaintenancePageState extends ConsumerState<CreateMaintenancePage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const Key('create-maintenance-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.createMaintenanceRequest,
                fallbackLocation: AppRoutes.maintenance,
                description: localizations.createMaintenanceDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DarJarTextField(
                      label: localizations.issueTitle,
                      hint: localizations.issueTitleHint,
                      controller: _titleController,
                      prefixIcon: Icons.build_outlined,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    DarJarTextField(
                      label: localizations.issueLocation,
                      hint: localizations.issueLocationHint,
                      controller: _locationController,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    DarJarButton(
                      key: const Key('submit-maintenance-button'),
                      label: localizations.submitRequest,
                      expanded: true,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    if (title.isEmpty || location.isEmpty) return;

    ref
        .read(maintenanceRequestsProvider.notifier)
        .create(title: title, location: location);
    context.go(AppRoutes.maintenance);
  }
}
