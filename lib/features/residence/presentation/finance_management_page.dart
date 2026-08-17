import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/documents/presentation/residence_document_picker.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/domain/finance_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FinanceManagementPage extends ConsumerWidget {
  const FinanceManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final state = ref.watch(residenceFinancesProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      key: const Key('finance-management-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
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
                title: localizations.financeManagement,
                fallbackLocation: AppRoutes.administration,
                onBack: () => context.go(AppRoutes.administration),
                description: compact
                    ? null
                    : localizations.financeManagementDescription,
                action: compact
                    ? null
                    : DarJarButton(
                        key: const Key('add-finance-transaction-button'),
                        label: localizations.addFinancialTransaction,
                        icon: Icons.add_rounded,
                        onPressed: () => _addTransaction(context, ref),
                      ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localizations.financeTrackingNotice),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            localizations.financeAutomaticDuesNotice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (compact) ...[
                const SizedBox(height: AppSpacing.medium),
                DarJarButton(
                  key: const Key('add-finance-transaction-button'),
                  label: localizations.addFinancialTransaction,
                  icon: Icons.add_rounded,
                  expanded: true,
                  onPressed: () => _addTransaction(context, ref),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              state.when(
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
                    if (!finances.hasOpeningBalance) ...[
                      _OpeningBalanceAlert(
                        onPressed: () => _addOpeningBalance(context, ref),
                      ),
                      const SizedBox(height: AppSpacing.large),
                    ],
                    _ManagementSummary(finances: finances),
                    const SizedBox(height: AppSpacing.large),
                    DarJarCard(
                      padding: EdgeInsets.zero,
                      child: finances.transactions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.xLarge),
                              child: Text(
                                localizations.noFinancialTransactions,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < finances.transactions.length;
                                  index++
                                ) ...[
                                  _ManagementTransactionRow(
                                    transaction: finances.transactions[index],
                                    onEdit:
                                        finances.transactions[index].isManual
                                        ? () => _editTransaction(
                                            context,
                                            ref,
                                            finances.transactions[index],
                                          )
                                        : null,
                                    onDelete:
                                        finances
                                            .transactions[index]
                                            .isOpeningBalance
                                        ? () => _deleteOpeningBalance(
                                            context,
                                            ref,
                                          )
                                        : finances.transactions[index].isManual
                                        ? () => _deleteTransaction(
                                            context,
                                            ref,
                                            finances.transactions[index],
                                          )
                                        : null,
                                  ),
                                  if (index < finances.transactions.length - 1)
                                    const Divider(),
                                ],
                              ],
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

  Future<void> _addTransaction(BuildContext context, WidgetRef ref) async {
    final input = await _showTransactionSheet(
      context,
      documentPicker: ref.read(residenceDocumentPickerProvider),
    );
    if (input == null || !context.mounted) return;
    try {
      await ref
          .read(residenceFinancesProvider.notifier)
          .addManualTransaction(input);
      if (context.mounted) {
        _showMessage(
          context,
          AppLocalizations.of(context).financeTransactionSaved,
        );
      }
    } on ResidenceFinanceFailure {
      if (context.mounted) {
        _showMessage(context, AppLocalizations.of(context).financeInvalidData);
      }
    }
  }

  Future<void> _addOpeningBalance(BuildContext context, WidgetRef ref) async {
    final input = await _showOpeningBalanceSheet(context);
    if (input == null || !context.mounted) return;
    try {
      await ref
          .read(residenceFinancesProvider.notifier)
          .setOpeningBalance(amount: input.amount, date: input.date);
      if (context.mounted) {
        _showMessage(context, AppLocalizations.of(context).openingBalanceSaved);
      }
    } on ResidenceFinanceFailure {
      if (context.mounted) {
        _showMessage(context, AppLocalizations.of(context).financeInvalidData);
      }
    }
  }

  Future<void> _editTransaction(
    BuildContext context,
    WidgetRef ref,
    ResidenceTransaction transaction,
  ) async {
    final input = await _showTransactionSheet(
      context,
      documentPicker: ref.read(residenceDocumentPickerProvider),
      transaction: transaction,
    );
    if (input == null || !context.mounted) return;
    try {
      await ref
          .read(residenceFinancesProvider.notifier)
          .updateManualTransaction(transactionId: transaction.id, input: input);
      if (context.mounted) {
        _showMessage(
          context,
          AppLocalizations.of(context).financeTransactionUpdated,
        );
      }
    } on ResidenceFinanceFailure {
      if (context.mounted) {
        _showMessage(context, AppLocalizations.of(context).financeInvalidData);
      }
    }
  }

  Future<void> _deleteOpeningBalance(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteOpeningBalance),
        content: Text(localizations.confirmDeleteOpeningBalance),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-opening-balance'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(residenceFinancesProvider.notifier).deleteOpeningBalance();
      if (context.mounted) {
        _showMessage(context, localizations.openingBalanceDeleted);
      }
    } on ResidenceFinanceFailure {
      if (context.mounted) {
        _showMessage(context, localizations.financeInvalidData);
      }
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    ResidenceTransaction transaction,
  ) async {
    final localizations = AppLocalizations.of(context);
    final transactionName =
        transaction.type == ResidenceTransactionType.expense &&
            transaction.expenseCategory != null &&
            transaction.expenseCategory != ResidenceExpenseCategory.custom
        ? _categoryLabel(context, transaction.expenseCategory!)
        : transaction.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteFinancialTransaction),
        content: Text(
          localizations.confirmDeleteFinancialTransaction(transactionName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-finance-transaction'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(residenceFinancesProvider.notifier)
        .deleteManualTransaction(transaction.id);
    if (context.mounted) {
      _showMessage(context, localizations.financeTransactionDeleted);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ManagementSummary extends StatelessWidget {
  const _ManagementSummary({required this.finances});

  final ResidenceFinances finances;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryValue(
            label: localizations.totalIncome,
            value: finances.totalIncome,
            color: AppColors.residence,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: _SummaryValue(
            label: localizations.totalExpenses,
            value: finances.totalExpenses,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: _SummaryValue(
            label: localizations.currentBalance,
            value: finances.currentBalance,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _OpeningBalanceAlert extends StatelessWidget {
  const _OpeningBalanceAlert({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      key: const Key('opening-balance-alert'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.openingBalanceMissingTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  localizations.openingBalanceMissingDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  key: const Key('enter-opening-balance-button'),
                  onPressed: onPressed,
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(localizations.enterOpeningBalance),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.small),
          FittedBox(
            child: Text(
              '${formatFinanceAmount(value, localizations.localeName)} ${localizations.currency}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementTransactionRow extends StatelessWidget {
  const _ManagementTransactionRow({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final ResidenceTransaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isIncome = transaction.type == ResidenceTransactionType.income;
    final title = transaction.isOpeningBalance
        ? localizations.openingBalance
        : transaction.source == ResidenceTransactionSource.dues
        ? _duesIncomeLabel(context, transaction)
        : transaction.type == ResidenceTransactionType.expense &&
              transaction.expenseCategory != null &&
              transaction.expenseCategory != ResidenceExpenseCategory.custom
        ? _categoryLabel(context, transaction.expenseCategory!)
        : transaction.name;
    return Padding(
      key: ValueKey('managed-finance-transaction-${transaction.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: isIncome ? AppColors.residence : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  '${DarJarDateFormat.yMMMd(transaction.date, localizations.localeName)} · '
                  '${transaction.isOpeningBalance
                      ? localizations.openingSettlement
                      : transaction.isManual
                      ? localizations.manualTransaction
                      : localizations.duesIncome}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            '${transaction.isOpeningBalance
                ? ''
                : isIncome
                ? '+'
                : '-'}${formatFinanceAmount(transaction.amount, localizations.localeName)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isIncome ? AppColors.residence : AppColors.warning,
            ),
          ),
          if (onEdit != null)
            IconButton(
              key: ValueKey('edit-finance-transaction-${transaction.id}'),
              tooltip: localizations.edit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onDelete != null)
            IconButton(
              key: ValueKey('delete-finance-transaction-${transaction.id}'),
              tooltip: localizations.delete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}

class _OpeningBalanceInput {
  const _OpeningBalanceInput({required this.amount, required this.date});

  final num amount;
  final DateTime date;
}

Future<_OpeningBalanceInput?> _showOpeningBalanceSheet(BuildContext context) {
  return showModalBottomSheet<_OpeningBalanceInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (context) => const _OpeningBalanceSheet(),
  );
}

class _OpeningBalanceSheet extends StatefulWidget {
  const _OpeningBalanceSheet();

  @override
  State<_OpeningBalanceSheet> createState() => _OpeningBalanceSheetState();
}

class _OpeningBalanceSheetState extends State<_OpeningBalanceSheet> {
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showError = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Material(
      key: const Key('opening-balance-sheet'),
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.large,
          AppSpacing.large,
          AppSpacing.large,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.large,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.openingBalance,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.openingBalanceDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarTextField(
                key: const Key('opening-balance-amount-field'),
                label: localizations.openingBalanceAmount,
                controller: _amountController,
                prefixIcon: Icons.payments_outlined,
                suffixText: localizations.currency,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [financeAmountInputFormatter],
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                localizations.openingBalanceZeroHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton.icon(
                key: const Key('opening-balance-date-field'),
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  '${localizations.openingBalanceDate}: '
                  '${DarJarDateFormat.yMMMd(_date, localizations.localeName)}',
                ),
              ),
              if (_showError) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  localizations.financeInvalidData,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              DarJarButton(
                key: const Key('save-opening-balance-button'),
                label: localizations.saveOpeningBalance,
                icon: Icons.save_outlined,
                expanded: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  void _submit() {
    final amount = parseFinanceAmount(_amountController.text);
    if (amount == null || amount < 0) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, _OpeningBalanceInput(amount: amount, date: _date));
  }
}

Future<ResidenceFinanceInput?> _showTransactionSheet(
  BuildContext context, {
  required ResidenceDocumentPicker documentPicker,
  ResidenceTransaction? transaction,
}) {
  return showModalBottomSheet<ResidenceFinanceInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (context) => _TransactionFormSheet(
      documentPicker: documentPicker,
      transaction: transaction,
    ),
  );
}

class _TransactionFormSheet extends ConsumerStatefulWidget {
  const _TransactionFormSheet({required this.documentPicker, this.transaction});

  final ResidenceDocumentPicker documentPicker;
  final ResidenceTransaction? transaction;

  @override
  ConsumerState<_TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<_TransactionFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late ResidenceTransactionType _type;
  ResidenceExpenseCategory? _category;
  late DateTime _date;
  ResidenceDocumentUpload? _attachmentUpload;
  late String _selectedAttachmentName;
  String? _attachmentError;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _nameController = TextEditingController(text: transaction?.name ?? '');
    _amountController = TextEditingController(
      text: transaction == null
          ? ''
          : formatFinanceAmountForInput(transaction.amount),
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _selectedAttachmentName = transaction?.hasAttachment == true
        ? transaction!.attachmentName
        : '';
    _type = transaction?.type ?? ResidenceTransactionType.expense;
    _category =
        transaction?.expenseCategory ??
        (transaction == null ? ResidenceExpenseCategory.maintenance : null);
    _date = transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Material(
      key: const Key('finance-transaction-sheet'),
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.large,
          AppSpacing.large,
          AppSpacing.large,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.large,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.transaction == null
                    ? localizations.addFinancialTransaction
                    : localizations.editFinancialTransaction,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.large),
              DropdownButtonFormField<ResidenceTransactionType>(
                key: const Key('finance-transaction-type-field'),
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: localizations.transactionType,
                  prefixIcon: const Icon(Icons.swap_vert_rounded),
                ),
                items: [
                  DropdownMenuItem(
                    value: ResidenceTransactionType.income,
                    child: Text(localizations.income),
                  ),
                  DropdownMenuItem(
                    value: ResidenceTransactionType.expense,
                    child: Text(localizations.expense),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    if (_type == ResidenceTransactionType.income) {
                      _category = null;
                    }
                  });
                },
              ),
              if (_type == ResidenceTransactionType.expense) ...[
                const SizedBox(height: AppSpacing.medium),
                DropdownButtonFormField<ResidenceExpenseCategory>(
                  key: const Key('finance-expense-category-field'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: localizations.expenseCategory,
                    prefixIcon: const Icon(Icons.sell_outlined),
                  ),
                  items: [
                    for (final category in ResidenceExpenseCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(_categoryLabel(context, category)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
              ],
              if (_requiresName) ...[
                const SizedBox(height: AppSpacing.medium),
                DarJarTextField(
                  key: const Key('finance-transaction-name-field'),
                  label: localizations.transactionName,
                  controller: _nameController,
                  prefixIcon: Icons.title_rounded,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              DarJarTextField(
                key: const Key('finance-transaction-amount-field'),
                label: localizations.transactionAmount,
                controller: _amountController,
                prefixIcon: Icons.payments_outlined,
                suffixText: localizations.currency,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [financeAmountInputFormatter],
              ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton.icon(
                key: const Key('finance-transaction-date-field'),
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  '${localizations.transactionDate}: '
                  '${DarJarDateFormat.yMMMd(_date, localizations.localeName)}',
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarTextField(
                key: const Key('finance-transaction-note-field'),
                label: localizations.transactionNote,
                controller: _noteController,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton.icon(
                key: const Key('select-finance-attachment-button'),
                onPressed: _pickAttachment,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  _selectedAttachmentName.isEmpty
                      ? localizations.attachSupportingDocument
                      : localizations.replaceAttachment,
                ),
              ),
              if (_selectedAttachmentName.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  _selectedAttachmentName,
                  key: const Key('selected-finance-attachment-name'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.residence),
                ),
              ],
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                _attachmentError ?? localizations.attachmentHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _attachmentError == null
                      ? AppColors.inkMuted
                      : AppColors.danger,
                ),
              ),
              if (_showError) ...[
                const SizedBox(height: AppSpacing.medium),
                Text(
                  localizations.financeInvalidData,
                  key: const Key('finance-transaction-form-error'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              DarJarButton(
                key: const Key('save-finance-transaction-button'),
                label: localizations.saveTransaction,
                icon: Icons.save_outlined,
                expanded: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _pickAttachment() async {
    final file = await widget.documentPicker();
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final contentType = residenceDocumentContentType(file.name, file.mimeType);
    if (bytes.isEmpty ||
        bytes.lengthInBytes > residenceDocumentMaxSizeBytes ||
        contentType.isEmpty) {
      setState(
        () => _attachmentError = AppLocalizations.of(context).attachmentInvalid,
      );
      return;
    }
    setState(() {
      _attachmentUpload = ResidenceDocumentUpload(
        title: file.name,
        originalFileName: file.name,
        contentType: contentType,
        bytes: bytes,
      );
      _selectedAttachmentName = file.name;
      _attachmentError = null;
    });
  }

  void _submit() {
    final amount = parseFinanceAmount(_amountController.text);
    final name = _requiresName
        ? _nameController.text.trim()
        : _category?.name ?? '';
    final valid =
        name.isNotEmpty &&
        amount != null &&
        amount > 0 &&
        (_type == ResidenceTransactionType.income || _category != null);
    if (!valid) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(
      ResidenceFinanceInput(
        type: _type,
        amount: amount,
        date: _date,
        name: name,
        expenseCategory: _category,
        note: _noteController.text,
        supportingDocument: _selectedAttachmentName,
        attachmentUpload: _attachmentUpload,
      ),
    );
  }

  bool get _requiresName =>
      _type == ResidenceTransactionType.income ||
      _category == ResidenceExpenseCategory.custom;
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
