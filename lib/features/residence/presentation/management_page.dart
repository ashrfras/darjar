import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:darjar/features/residence/presentation/residence_president_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagementPage extends ConsumerWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final residence = ref
        .watch(residenceContextProvider)
        .value
        ?.activeResidence;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      key: const Key('management-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
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
                description: compact
                    ? null
                    : localizations.managementPageDescription,
              ),
              if (residence != null) ...[
                const SizedBox(height: AppSpacing.large),
                _PresidentCard(residence: residence),
                const SizedBox(height: AppSpacing.large),
                _BankInformationCard(residenceId: residence.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PresidentCard extends ConsumerWidget {
  const _PresidentCard({required this.residence});

  final UserResidence residence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final directory = ref.watch(residenceDirectoryProvider);
    final hasPresident = hasRecordedResidencePresident(residence);
    final Widget content;
    if (directory.isLoading) {
      content = const LinearProgressIndicator();
    } else if (directory.hasError) {
      content = _LoadError(
        message: hasPresident
            ? strings.residencePresidentProfileUnavailable
            : strings.residencePresidentLoadFailed,
        onRetry: () => ref.invalidate(residenceDirectoryProvider),
      );
    } else {
      final data = directory.requireValue;
      final president = residencePresidentMember(residence, data);
      if (president == null && !hasPresident) {
        content = Text(
          strings.managementPresidentVacantTitle,
          style: Theme.of(context).textTheme.titleMedium,
        );
      } else if (president == null ||
          !hasAvailablePresidentProfile(president)) {
        content = _LoadError(
          message: strings.residencePresidentProfileUnavailable,
          onRetry: () => ref.invalidate(residenceDirectoryProvider),
        );
      } else {
        content = ResidencePresidentProfile(
          president: president,
          apartmentNumber: data.apartments
              .where((apartment) => apartment.id == president.apartmentId)
              .firstOrNull
              ?.number,
        );
      }
    }
    return DarJarCard(child: content);
  }
}

class _BankInformationCard extends ConsumerWidget {
  const _BankInformationCard({required this.residenceId});

  final String residenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(residenceSettingsProvider);
    final settings = state.value;
    final bankName = settings?.bankName.trim() ?? '';
    final bankAccount = settings?.bankAccount.trim() ?? '';
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.bankInformation,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          if (state.isLoading)
            const LinearProgressIndicator()
          else if (state.hasError || settings?.residenceId != residenceId)
            _LoadError(
              message: strings.managementBankLoadFailed,
              onRetry: () => ref.invalidate(residenceSettingsProvider),
            )
          else ...[
            if (bankName.isNotEmpty)
              _InfoRow(
                icon: Icons.account_balance_outlined,
                label: strings.bank,
                value: bankName,
              ),
            if (bankAccount.isEmpty)
              Text(strings.managementBankAccountMissing)
            else ...[
              if (bankName.isNotEmpty) const Divider(),
              _InfoRow(
                icon: Icons.numbers_rounded,
                label: strings.bankAccount,
                value: bankAccount,
                textDirection: TextDirection.ltr,
                valueAction: IconButton(
                  tooltip: strings.managementBankCopyAccount,
                  onPressed: () => _copyBankAccount(context, bankAccount),
                  icon: const Icon(Icons.copy_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                strings.externalTransferNotice,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _copyBankAccount(
    BuildContext context,
    String bankAccount,
  ) async {
    final strings = AppLocalizations.of(context);
    var message = strings.managementBankAccountCopied;
    try {
      await Clipboard.setData(ClipboardData(text: bankAccount));
    } on PlatformException {
      message = strings.managementBankCopyFailed;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.small),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppLocalizations.of(context).accountResolutionRetry),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.textDirection,
    this.valueAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextDirection? textDirection;
  final Widget? valueAction;

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
                Wrap(
                  spacing: AppSpacing.small,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SelectableText(
                      value,
                      textDirection: textDirection,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (valueAction case final Widget action) action,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
