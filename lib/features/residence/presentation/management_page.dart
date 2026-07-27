import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagementPage extends ConsumerWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final settingsState = ref.watch(residenceSettingsProvider);
    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final settings = settingsState.value;
    if (settings == null) {
      return Center(
        child: IconButton(
          tooltip: localizations.accountResolutionRetry,
          onPressed: () => ref.invalidate(residenceSettingsProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('management-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.managementInformation,
                fallbackLocation: AppRoutes.residence,
                description: localizations.managementPageDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: localizations.managementCompany,
                      value: settings.managementOrganization,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: localizations.phone,
                      value: settings.managementPhone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.bankInformation,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    _InfoRow(
                      icon: Icons.account_balance_outlined,
                      label: localizations.bank,
                      value: settings.bankName,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.numbers_rounded,
                      label: localizations.bankAccount,
                      value: settings.bankAccount,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      localizations.externalTransferNotice,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                      ),
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        children: [
          Icon(icon, color: AppColors.residence),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xSmall),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
