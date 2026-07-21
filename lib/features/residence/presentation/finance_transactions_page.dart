import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
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
    final transactions = ref.read(residenceFinancesProvider).transactions;
    final latestDate = transactions.isEmpty
        ? DateTime.now()
        : transactions
              .map((transaction) => transaction.date)
              .reduce((latest, date) => date.isAfter(latest) ? date : latest);
    _period = DateTimeRange(
      start: DateTime(latestDate.year),
      end: DateTime(latestDate.year, 12, 31),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final transactions =
        ref
            .watch(residenceFinancesProvider)
            .transactions
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
                description: localizations.financeTransactionsDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
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
                            _TransactionRow(transaction: transactions[index]),
                            if (index != transactions.length - 1)
                              const Divider(height: AppSpacing.xLarge),
                          ],
                        ],
                      ),
              ),
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
  const _TransactionRow({required this.transaction});

  final ResidenceTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
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
                  locale == 'ar'
                      ? transaction.descriptionAr
                      : transaction.descriptionEn,
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
                      label: DateFormat.yMMMd(locale).format(transaction.date),
                    ),
                    if (transaction.expenseCategory case final category?)
                      _Meta(
                        icon: Icons.sell_outlined,
                        label: _categoryLabel(context, category),
                      ),
                  ],
                ),
                if (transaction.supportingDocument case final document?) ...[
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 17,
                        color: AppColors.residence,
                      ),
                      const SizedBox(width: AppSpacing.xSmall),
                      Expanded(
                        child: Text(
                          '${localizations.supportingDocument}: $document',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.residence),
                        ),
                      ),
                    ],
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
  };
}

IconData _categoryIcon(ResidenceExpenseCategory? category) {
  return switch (category) {
    ResidenceExpenseCategory.maintenance => Icons.handyman_outlined,
    ResidenceExpenseCategory.utilities => Icons.bolt_outlined,
    ResidenceExpenseCategory.cleaning => Icons.cleaning_services_outlined,
    ResidenceExpenseCategory.security => Icons.shield_outlined,
    null => Icons.north_east_rounded,
  };
}
