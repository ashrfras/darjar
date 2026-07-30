import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ResidenceFinancesPage extends ConsumerWidget {
  const ResidenceFinancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final financesState = ref.watch(residenceFinancesProvider);
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
                description: compact
                    ? null
                    : localizations.residenceFinancesDescription,
              ),
              const SizedBox(height: AppSpacing.large),
              financesState.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxLarge),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => DarJarCard(
                  child: Column(
                    children: [
                      Text(
                        localizations.financeLoadError,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      IconButton(
                        key: const Key('retry-residence-finances'),
                        onPressed: () =>
                            ref.invalidate(residenceFinancesProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                data: (finances) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
        if (constraints.maxWidth >= 300 && constraints.maxWidth < 760) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            childAspectRatio: 1.3,
            children: [
              for (final card in cards) _SummaryCard.compact(card: card),
            ],
          );
        }
        final cardWidth = constraints.maxWidth >= 760
            ? (constraints.maxWidth - AppSpacing.medium * 3) / 4
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
  }) : compact = false;

  _SummaryCard.compact({required _SummaryCard card})
    : label = card.label,
      value = card.value,
      icon = card.icon,
      color = card.color,
      background = card.background,
      compact = true,
      super(key: card.key);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: compact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
          SizedBox(
            width: compact ? 0 : AppSpacing.medium,
            height: compact ? AppSpacing.medium : 0,
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          if (finances.breakdown.isEmpty)
            Text(localizations.noExpensesRecorded, textAlign: TextAlign.center)
          else
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

class _RecentExpensesCard extends ConsumerWidget {
  const _RecentExpensesCard({required this.finances});

  final ResidenceFinances finances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context).recentExpenses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          if (finances.recentExpenses.isEmpty)
            Text(
              AppLocalizations.of(context).noExpensesRecorded,
              textAlign: TextAlign.center,
            )
          else
            for (
              var index = 0;
              index < finances.recentExpenses.length;
              index++
            ) ...[
              _ExpenseRow(
                expense: finances.recentExpenses[index],
                onOpenAttachment: finances.recentExpenses[index].hasAttachment
                    ? () => showResidenceDocumentPreview(
                        context,
                        ref,
                        finances.recentExpenses[index].attachmentDocument,
                      )
                    : null,
              ),
              if (index != finances.recentExpenses.length - 1)
                const Divider(height: AppSpacing.xLarge),
            ],
          const SizedBox(height: AppSpacing.medium),
          DarJarButton(
            key: const Key('view-all-transactions-button'),
            label: AppLocalizations.of(context).viewAllTransactions,
            icon: Icons.receipt_long_outlined,
            variant: DarJarButtonVariant.tertiary,
            onPressed: () => context.push(AppRoutes.financeTransactions),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, this.onOpenAttachment});

  final ResidenceTransaction expense;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context);
    final category = expense.expenseCategory ?? ResidenceExpenseCategory.custom;
    final color = _categoryColor(category);
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
            child: Icon(_categoryIcon(category), color: color, size: 21),
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
                        category == ResidenceExpenseCategory.custom
                            ? expense.name
                            : _categoryLabel(context, category),
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
                      label: _categoryLabel(context, category),
                    ),
                    _Meta(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd(locale).format(expense.date),
                    ),
                  ],
                ),
                if (expense.note.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Row(
                    key: ValueKey('residence-expense-note-${expense.id}'),
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
                          expense.note.trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                if (onOpenAttachment != null) ...[
                  if (expense.note.trim().isEmpty)
                    const SizedBox(height: AppSpacing.xSmall),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      key: ValueKey(
                        'residence-expense-attachment-${expense.id}',
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
                                expense.attachmentName,
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
                ] else ...[
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    localizations.noSupportingDocument,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
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
    ResidenceExpenseCategory.custom => localizations.expenseCategoryCustom,
  };
}

IconData _categoryIcon(ResidenceExpenseCategory category) {
  return switch (category) {
    ResidenceExpenseCategory.maintenance => Icons.handyman_outlined,
    ResidenceExpenseCategory.utilities => Icons.bolt_outlined,
    ResidenceExpenseCategory.cleaning => Icons.cleaning_services_outlined,
    ResidenceExpenseCategory.security => Icons.shield_outlined,
    ResidenceExpenseCategory.custom => Icons.category_outlined,
  };
}

Color _categoryColor(ResidenceExpenseCategory category) {
  return switch (category) {
    ResidenceExpenseCategory.maintenance => const Color(0xFF7657D6),
    ResidenceExpenseCategory.utilities => const Color(0xFF367DDB),
    ResidenceExpenseCategory.cleaning => AppColors.residence,
    ResidenceExpenseCategory.security => AppColors.warning,
    ResidenceExpenseCategory.custom => AppColors.inkMuted,
  };
}
