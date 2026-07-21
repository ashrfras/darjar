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

class ResidenceFinancesPage extends ConsumerWidget {
  const ResidenceFinancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final finances = ref.watch(residenceFinancesProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      key: const Key('residence-finances-page'),
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
                title: localizations.residenceFinances,
                fallbackLocation: AppRoutes.residence,
                description: localizations.residenceFinancesDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              _Summary(finances: finances),
              const SizedBox(height: AppSpacing.large),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BreakdownCard(finances: finances),
                        const SizedBox(height: AppSpacing.large),
                        _RecentExpensesCard(finances: finances),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _BreakdownCard(finances: finances),
                      ),
                      const SizedBox(width: AppSpacing.large),
                      Expanded(
                        flex: 6,
                        child: _RecentExpensesCard(finances: finances),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.finances});

  final ResidenceFinances finances;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final cards = [
      _SummaryCard(
        key: const Key('finance-total-income'),
        label: localizations.totalIncome,
        value:
            '${_amount(context, finances.totalIncome)} ${localizations.currency}',
        icon: Icons.south_west_rounded,
        color: AppColors.residence,
        background: AppColors.residenceSoft,
      ),
      _SummaryCard(
        key: const Key('finance-total-expenses'),
        label: localizations.totalExpenses,
        value:
            '${_amount(context, finances.totalExpenses)} ${localizations.currency}',
        icon: Icons.north_east_rounded,
        color: AppColors.warning,
        background: AppColors.warningSoft,
      ),
      _SummaryCard(
        key: const Key('finance-current-balance'),
        label: localizations.currentBalance,
        value:
            '${_amount(context, finances.currentBalance)} ${localizations.currency}',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF7657D6),
        background: const Color(0xFFF0ECFF),
      ),
      _SummaryCard(
        key: const Key('finance-collection-rate'),
        label: localizations.collectionRate,
        value: '${(finances.collectionRate * 100).round()}%',
        icon: Icons.donut_large_rounded,
        color: const Color(0xFF367DDB),
        background: const Color(0xFFEAF2FF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 760
            ? (constraints.maxWidth - AppSpacing.medium * 3) / 4
            : constraints.maxWidth >= 460
            ? (constraints.maxWidth - AppSpacing.medium) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.finances});

  final ResidenceFinances finances;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.expenseBreakdown,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xLarge),
          for (var index = 0; index < finances.breakdown.length; index++) ...[
            _BreakdownRow(
              item: finances.breakdown[index],
              totalExpenses: finances.totalExpenses,
              color: _categoryColor(finances.breakdown[index].category),
            ),
            if (index != finances.breakdown.length - 1)
              const SizedBox(height: AppSpacing.large),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.item,
    required this.totalExpenses,
    required this.color,
  });

  final ResidenceExpenseBreakdown item;
  final int totalExpenses;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = item.amount / totalExpenses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                _categoryLabel(context, item.category),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              '${_amount(context, item.amount)} ${AppLocalizations.of(context).currency}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 7,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          backgroundColor: AppColors.outline,
          color: color,
        ),
      ],
    );
  }
}

class _RecentExpensesCard extends StatelessWidget {
  const _RecentExpensesCard({required this.finances});

  final ResidenceFinances finances;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context).recentExpenses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          for (
            var index = 0;
            index < finances.recentExpenses.length;
            index++
          ) ...[
            _ExpenseRow(expense: finances.recentExpenses[index]),
            if (index != finances.recentExpenses.length - 1)
              const Divider(height: AppSpacing.xLarge),
          ],
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final ResidenceExpense expense;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context);
    final color = _categoryColor(expense.category);
    return Padding(
      key: ValueKey('residence-expense-${expense.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(
              _categoryIcon(expense.category),
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        locale == 'ar'
                            ? expense.descriptionAr
                            : expense.descriptionEn,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      '${_amount(context, expense.amount)} ${localizations.currency}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.xSmall,
                  children: [
                    _Meta(
                      icon: Icons.sell_outlined,
                      label: _categoryLabel(context, expense.category),
                    ),
                    _Meta(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd(locale).format(expense.date),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                if (expense.supportingDocument case final document?)
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
                  )
                else
                  Text(
                    localizations.noSupportingDocument,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
              ],
            ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xSmall),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
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

IconData _categoryIcon(ResidenceExpenseCategory category) {
  return switch (category) {
    ResidenceExpenseCategory.maintenance => Icons.handyman_outlined,
    ResidenceExpenseCategory.utilities => Icons.bolt_outlined,
    ResidenceExpenseCategory.cleaning => Icons.cleaning_services_outlined,
    ResidenceExpenseCategory.security => Icons.shield_outlined,
  };
}

Color _categoryColor(ResidenceExpenseCategory category) {
  return switch (category) {
    ResidenceExpenseCategory.maintenance => const Color(0xFF7657D6),
    ResidenceExpenseCategory.utilities => const Color(0xFF367DDB),
    ResidenceExpenseCategory.cleaning => AppColors.residence,
    ResidenceExpenseCategory.security => AppColors.warning,
  };
}
