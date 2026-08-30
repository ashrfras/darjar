import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_loading_skeleton.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Bidi, NumberFormat;

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
                  loading: DarJarLoadingSkeleton.new,
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

class _ResidentDuesContent extends ConsumerStatefulWidget {
  const _ResidentDuesContent({required this.overview});

  final ResidenceDuesOverview overview;

  @override
  ConsumerState<_ResidentDuesContent> createState() =>
      _ResidentDuesContentState();
}

class _ResidentDuesContentState extends ConsumerState<_ResidentDuesContent> {
  static const _duesPageSize = 3;
  static const _paymentsPageSize = 10;

  var _visibleDues = _duesPageSize;
  var _visiblePayments = _paymentsPageSize;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final overview = widget.overview;
    if (overview.dues.isEmpty) {
      return _EmptyState(
        key: const Key('dues-no-records'),
        icon: Icons.receipt_long_outlined,
        message: localizations.duesNoRecords,
      );
    }
    final currentPeriodKey = residenceDuesPeriodKey(DateTime.now());
    final prepaidDues = overview.prepaidDuesAfterPeriod(currentPeriodKey);
    final orderedDues = [...overview.dues]
      ..sort((first, second) => second.periodKey.compareTo(first.periodKey));
    final visibleDues = orderedDues.take(_visibleDues).toList();
    final paymentGroups = overview.paymentGroups;
    final visiblePaymentGroups = paymentGroups.take(_visiblePayments).toList();
    final activeResidence = ref.watch(
      residenceContextProvider.select((state) => state.value?.activeResidence),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Totals(
          debit: overview.debitThroughPeriod(currentPeriodKey),
          credit: overview.creditAfterPeriod(currentPeriodKey),
          prepaidMonths: prepaidDues.length,
        ),
        const SizedBox(height: AppSpacing.large),
        for (final due in visibleDues) ...[
          _ResidentDueCard(due: due),
          const SizedBox(height: AppSpacing.medium),
        ],
        if (visibleDues.length < orderedDues.length)
          Center(
            child: TextButton.icon(
              key: const Key('show-more-dues'),
              onPressed: () => setState(() => _visibleDues += _duesPageSize),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(localizations.showMore),
            ),
          ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          localizations.duesPaymentHistory,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.medium),
        if (paymentGroups.isEmpty)
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
                  index < visiblePaymentGroups.length;
                  index++
                ) ...[
                  _PaymentRow(
                    paymentGroup: visiblePaymentGroups[index],
                    onOpenReceipt: activeResidence == null
                        ? null
                        : () {
                            final receipt = visiblePaymentGroups[index].receipt(
                              residenceId: activeResidence.id,
                              residenceName: activeResidence.name,
                            );
                            context.push(
                              AppRoutes.receipt(receipt.id),
                              extra: receipt,
                            );
                          },
                    onOpenAttachment: visiblePaymentGroups[index].hasAttachment
                        ? () => showResidenceDocumentPreview(
                            context,
                            ref,
                            visiblePaymentGroups[index].attachmentDocument,
                          )
                        : null,
                  ),
                  if (index != visiblePaymentGroups.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        if (visiblePaymentGroups.length < paymentGroups.length)
          Center(
            child: TextButton.icon(
              key: const Key('show-more-due-payments'),
              onPressed: () =>
                  setState(() => _visiblePayments += _paymentsPageSize),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(localizations.showMore),
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
    required this.debit,
    required this.credit,
    required this.prepaidMonths,
  });

  final int debit;
  final int credit;
  final int prepaidMonths;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = [
          _TotalCard(
            key: const Key('dues-total-debit'),
            label: localizations.duesDebitBalance,
            amount: debit,
            suffix: localizations.currency,
            color: AppColors.warning,
          ),
          _TotalCard(
            key: const Key('dues-total-credit'),
            label: localizations.duesCreditBalance,
            amount: credit,
            suffix: localizations.currency,
            color: AppColors.residence,
          ),
          _TotalCard(
            key: const Key('dues-prepaid-months'),
            label: localizations.duesPrepaidMonths,
            amount: prepaidMonths,
            color: AppColors.primary,
          ),
        ];
        if (constraints.maxWidth < 330) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
    this.suffix,
    super.key,
  });

  final String label;
  final int amount;
  final Color color;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              suffix == null
                  ? _amount(context, amount)
                  : '${_amount(context, amount)} $suffix',
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: color),
            ),
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
  const _PaymentRow({
    required this.paymentGroup,
    required this.onOpenReceipt,
    required this.onOpenAttachment,
  });

  final ResidenceDuePaymentGroup paymentGroup;
  final VoidCallback? onOpenReceipt;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final payment = paymentGroup.payments.first;
    return InkWell(
      key: ValueKey('resident-payment-${paymentGroup.id}'),
      onTap: onOpenReceipt,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
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
                    '${_amount(context, paymentGroup.totalAmount)} '
                    '${localizations.currency}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    localizations.duesRecordedOn(
                      DarJarDateFormat.yMMMd(
                        payment.paidAt,
                        localizations.localeName,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (payment.note.isNotEmpty)
                    Text(
                      payment.note,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (onOpenAttachment != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: InkWell(
                        key: ValueKey(
                          'resident-payment-attachment-${paymentGroup.id}',
                        ),
                        onTap: onOpenAttachment,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xSmall,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.attachment_outlined,
                                size: 17,
                                color: AppColors.residence,
                              ),
                              const SizedBox(width: AppSpacing.xSmall),
                              Flexible(
                                child: Text(
                                  payment.attachmentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.residence),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onOpenReceipt != null)
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.inkMuted,
                textDirection: Bidi.isRtlLanguage(localizations.localeName)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
          ],
        ),
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
  return DarJarDateFormat.yMMMM(date, AppLocalizations.of(context).localeName);
}
