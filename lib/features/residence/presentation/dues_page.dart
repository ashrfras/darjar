import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DuesPage extends ConsumerWidget {
  const DuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final activeResidence = ref.watch(
      residenceContextProvider.select((state) => state.value?.activeResidence),
    );
    final duesState = ref.watch(residentDuesProvider);

    return SingleChildScrollView(
      key: const Key('dues-page'),
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
                title: localizations.duesStatus,
                fallbackLocation: AppRoutes.residence,
              ),
              const SizedBox(height: AppSpacing.small),
              _ManualNotice(text: localizations.manualDuesNotice),
              const SizedBox(height: AppSpacing.large),
              if (activeResidence == null ||
                  activeResidence.apartmentId.isEmpty)
                _EmptyState(
                  key: const Key('dues-no-apartment'),
                  icon: Icons.home_work_outlined,
                  message: localizations.duesNoApartment,
                )
              else
                duesState.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxxLarge),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => _EmptyState(
                    key: const Key('dues-load-error'),
                    icon: Icons.error_outline_rounded,
                    message: localizations.duesLoadError,
                    onRetry: () => ref.invalidate(residentDuesProvider),
                  ),
                  data: (overview) => _ResidentDuesContent(overview: overview),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResidentDuesContent extends StatelessWidget {
  const _ResidentDuesContent({required this.overview});

  final ResidenceDuesOverview overview;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (overview.dues.isEmpty) {
      return _EmptyState(
        key: const Key('dues-no-records'),
        icon: Icons.receipt_long_outlined,
        message: localizations.duesNoRecords,
      );
    }
    final totalDue = overview.dues.fold(
      0,
      (total, due) => total + due.amountDue,
    );
    final totalPaid = overview.dues.fold(
      0,
      (total, due) => total + due.amountPaid,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Totals(
          expected: totalDue,
          collected: totalPaid,
          remaining: totalDue - totalPaid,
        ),
        const SizedBox(height: AppSpacing.large),
        for (final due in overview.dues) ...[
          _ResidentDueCard(due: due),
          const SizedBox(height: AppSpacing.medium),
        ],
        const SizedBox(height: AppSpacing.medium),
        Text(
          localizations.duesPaymentHistory,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.medium),
        if (overview.payments.isEmpty)
          _EmptyState(
            icon: Icons.history_rounded,
            message: localizations.duesNoPayments,
          )
        else
          DarJarCard(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < overview.payments.length;
                  index++
                ) ...[
                  _PaymentRow(payment: overview.payments[index]),
                  if (index != overview.payments.length - 1) const Divider(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ResidentDueCard extends StatelessWidget {
  const _ResidentDueCard({required this.due});

  final ResidenceDue due;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      key: ValueKey('resident-due-${due.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.duesPeriod(
                    _periodLabel(context, due.periodKey),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _DueStatusBadge(status: due.status),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Row(
            children: [
              Expanded(
                child: _AmountLabel(
                  label: localizations.duesAmountDue,
                  amount: due.amountDue,
                ),
              ),
              Expanded(
                child: _AmountLabel(
                  label: localizations.duesAmountPaid,
                  amount: due.amountPaid,
                ),
              ),
              Expanded(
                child: _AmountLabel(
                  label: localizations.duesRemaining,
                  amount: due.remainingAmount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.expected,
    required this.collected,
    required this.remaining,
  });

  final int expected;
  final int collected;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = [
          _TotalCard(
            key: const Key('dues-total-expected'),
            label: localizations.duesExpected,
            amount: expected,
            color: AppColors.primary,
          ),
          _TotalCard(
            key: const Key('dues-total-collected'),
            label: localizations.duesCollected,
            amount: collected,
            color: AppColors.residence,
          ),
          _TotalCard(
            key: const Key('dues-total-remaining'),
            label: localizations.duesRemaining,
            amount: remaining,
            color: AppColors.warning,
          ),
        ];
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                items[index],
                if (index != items.length - 1)
                  const SizedBox(height: AppSpacing.small),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(child: items[index]),
              if (index != items.length - 1)
                const SizedBox(width: AppSpacing.medium),
            ],
          ],
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.color,
    super.key,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '${_amount(context, amount)} ${localizations.currency}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          '${_amount(context, amount)} ${AppLocalizations.of(context).currency}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final ResidenceDuePayment payment;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      key: ValueKey('resident-payment-${payment.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.residenceSoft,
            foregroundColor: AppColors.residence,
            child: Icon(Icons.check_rounded),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_amount(context, payment.amount)} ${localizations.currency}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  localizations.duesRecordedOn(
                    DateFormat.yMMMd(
                      localizations.localeName,
                    ).format(payment.paidAt),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (payment.note.isNotEmpty)
                  Text(
                    payment.note,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueStatusBadge extends StatelessWidget {
  const _DueStatusBadge({required this.status});

  final ResidenceDueStatus status;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (label, tone) = switch (status) {
      ResidenceDueStatus.unpaid => (
        localizations.duesStatusUnpaid,
        DarJarBadgeTone.warning,
      ),
      ResidenceDueStatus.partial => (
        localizations.duesStatusPartial,
        DarJarBadgeTone.info,
      ),
      ResidenceDueStatus.paid => (
        localizations.duesStatusPaid,
        DarJarBadgeTone.success,
      ),
    };
    return DarJarBadge(label: label, tone: tone);
  }
}

class _ManualNotice extends StatelessWidget {
  const _ManualNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.warningSoft,
            foregroundColor: AppColors.warning,
            child: Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.onRetry,
    super.key,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.medium),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.medium),
            TextButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).accountResolutionRetry),
            ),
          ],
        ],
      ),
    );
  }
}

String _amount(BuildContext context, int amount) {
  return NumberFormat.decimalPattern(
    AppLocalizations.of(context).localeName,
  ).format(amount);
}

String _periodLabel(BuildContext context, String periodKey) {
  final parts = periodKey.split('-');
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat.yMMMM(AppLocalizations.of(context).localeName).format(date);
}
