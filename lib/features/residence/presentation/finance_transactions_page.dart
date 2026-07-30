import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FinanceTransactionsPage extends ConsumerStatefulWidget {
  const FinanceTransactionsPage({super.key});

  @override
  ConsumerState<FinanceTransactionsPage> createState() =>
      _FinanceTransactionsPageState();
}

class _FinanceTransactionsPageState
    extends ConsumerState<FinanceTransactionsPage> {
  late DateTimeRange _period;

  @override
  void initState() {
    super.initState();
    final latestDate = DateTime.now();
    _period = DateTimeRange(
      start: DateTime(latestDate.year),
      end: DateTime(latestDate.year, 12, 31),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final financesState = ref.watch(residenceFinancesProvider);
    final transactions =
        (financesState.value?.transactions ?? const <ResidenceTransaction>[])
            .where(_isInSelectedPeriod)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final income = _totalFor(transactions, ResidenceTransactionType.income);
    final expenses = _totalFor(transactions, ResidenceTransactionType.expense);

    return SingleChildScrollView(
      key: const Key('finance-transactions-page'),
      primary: false,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.financeTransactions,
                fallbackLocation: AppRoutes.residenceFinances,
                description: compact
                    ? null
                    : localizations.financeTransactionsDescription,
              ),
              const SizedBox(height: AppSpacing.large),
              if (financesState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxLarge),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (financesState.hasError)
                DarJarCard(
                  child: Column(
                    children: [
                      Text(
                        localizations.financeLoadError,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      IconButton(
                        onPressed: () =>
                            ref.invalidate(residenceFinancesProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                )
              else ...[
                DarJarCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizations.selectPeriod,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      OutlinedButton.icon(
                        key: const Key('finance-period-picker'),
                        onPressed: _selectPeriod,
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(_periodLabel(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _PeriodSummary(income: income, expenses: expenses),
                const SizedBox(height: AppSpacing.large),
                DarJarCard(
                  child: transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xLarge,
                          ),
                          child: Text(
                            localizations.noTransactionsInPeriod,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          children: [
                            for (
                              var index = 0;
                              index < transactions.length;
                              index++
                            ) ...[
                              _TransactionRow(
                                transaction: transactions[index],
                                onOpenAttachment:
                                    transactions[index].hasAttachment
                                    ? () => showResidenceDocumentPreview(
                                        context,
                                        ref,
                                        transactions[index].attachmentDocument,
                                      )
                                    : null,
                              ),
                              if (index != transactions.length - 1)
                                const Divider(height: AppSpacing.xLarge),
                            ],
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

  bool _isInSelectedPeriod(ResidenceTransaction transaction) {
    final date = DateUtils.dateOnly(transaction.date);
    return !date.isBefore(DateUtils.dateOnly(_period.start)) &&
        !date.isAfter(DateUtils.dateOnly(_period.end));
  }

  String _periodLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = DateFormat.yMMMd(locale);
    return AppLocalizations.of(context).periodFromTo(
      formatter.format(_period.start),
      formatter.format(_period.end),
    );
  }

  Future<void> _selectPeriod() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: _period,
      helpText: AppLocalizations.of(context).selectPeriod,
    );
    if (selected != null && mounted) {
      setState(() => _period = selected);
    }
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.income, required this.expenses});

  final int income;
  final int expenses;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PeriodTotal(
            key: const Key('period-income-total'),
            label: AppLocalizations.of(context).periodIncome,
            value: income,
            color: AppColors.residence,
            icon: Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: _PeriodTotal(
            key: const Key('period-expenses-total'),
            label: AppLocalizations.of(context).periodExpenses,
            value: expenses,
            color: AppColors.warning,
            icon: Icons.north_east_rounded,
          ),
        ),
      ],
    );
  }
}

class _PeriodTotal extends StatelessWidget {
  const _PeriodTotal({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    super.key,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.small),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '${_amount(context, value)} ${AppLocalizations.of(context).currency}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, this.onOpenAttachment});

  final ResidenceTransaction transaction;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isIncome = transaction.type == ResidenceTransactionType.income;
    final color = isIncome ? AppColors.residence : AppColors.warning;
    final typeLabel = isIncome ? localizations.income : localizations.expense;

    return Padding(
      key: ValueKey('finance-transaction-${transaction.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(
              isIncome
                  ? Icons.south_west_rounded
                  : _categoryIcon(transaction.expenseCategory),
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.source == ResidenceTransactionSource.dues
                      ? _duesIncomeLabel(context, transaction)
                      : transaction.type == ResidenceTransactionType.expense &&
                            transaction.expenseCategory != null &&
                            transaction.expenseCategory !=
                                ResidenceExpenseCategory.custom
                      ? _categoryLabel(context, transaction.expenseCategory!)
                      : transaction.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.xSmall,
                  children: [
                    _Meta(icon: Icons.swap_vert_rounded, label: typeLabel),
                    _Meta(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd(
                        localizations.localeName,
                      ).format(transaction.date),
                    ),
                    if (transaction.expenseCategory case final category?)
                      _Meta(
                        icon: Icons.sell_outlined,
                        label: _categoryLabel(context, category),
                      ),
                  ],
                ),
                if (transaction.note.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Row(
                    key: ValueKey('finance-transaction-note-${transaction.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 17,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: AppSpacing.xSmall),
                      Expanded(
                        child: Text(
                          transaction.note.trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                if (onOpenAttachment != null) ...[
                  if (transaction.note.trim().isEmpty)
                    const SizedBox(height: AppSpacing.xSmall),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      key: ValueKey(
                        'finance-transaction-attachment-${transaction.id}',
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
                                transaction.attachmentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.residence),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            '${isIncome ? '+' : '-'}${_amount(context, transaction.amount)}\n${localizations.currency}',
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.xSmall),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

int _totalFor(
  List<ResidenceTransaction> transactions,
  ResidenceTransactionType type,
) {
  return transactions
      .where((transaction) => transaction.type == type)
      .fold(0, (total, transaction) => total + transaction.amount);
}

String _amount(BuildContext context, int amount) {
  return NumberFormat.decimalPattern(
    Localizations.localeOf(context).languageCode,
  ).format(amount);
}

String _categoryLabel(BuildContext context, ResidenceExpenseCategory category) {
  final localizations = AppLocalizations.of(context);
  return switch (category) {
    ResidenceExpenseCategory.maintenance =>
      localizations.expenseCategoryMaintenance,
    ResidenceExpenseCategory.utilities =>
      localizations.expenseCategoryUtilities,
    ResidenceExpenseCategory.cleaning => localizations.expenseCategoryCleaning,
    ResidenceExpenseCategory.security => localizations.expenseCategorySecurity,
    ResidenceExpenseCategory.custom => localizations.expenseCategoryCustom,
  };
}

IconData _categoryIcon(ResidenceExpenseCategory? category) {
  return switch (category) {
    ResidenceExpenseCategory.maintenance => Icons.handyman_outlined,
    ResidenceExpenseCategory.utilities => Icons.bolt_outlined,
    ResidenceExpenseCategory.cleaning => Icons.cleaning_services_outlined,
    ResidenceExpenseCategory.security => Icons.shield_outlined,
    ResidenceExpenseCategory.custom => Icons.category_outlined,
    null => Icons.north_east_rounded,
  };
}

String _duesIncomeLabel(
  BuildContext context,
  ResidenceTransaction transaction,
) {
  final localizations = AppLocalizations.of(context);
  final start = _displayPeriodKey(transaction.periodKey);
  final end = _displayPeriodKey(transaction.periodEndKey);
  if (end.isNotEmpty && end != start) {
    return localizations.duesIncomeForApartmentRange(
      transaction.apartmentNumber,
      start,
      end,
    );
  }
  return localizations.duesIncomeForApartment(
    transaction.apartmentNumber,
    start,
  );
}

String _displayPeriodKey(String periodKey) {
  final parts = periodKey.split('-');
  if (parts.length != 2) return periodKey;
  return '${parts[1]}-${parts[0]}';
}
