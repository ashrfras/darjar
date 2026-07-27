import 'dart:ui' as ui;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DuesManagementPage extends ConsumerWidget {
  const DuesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final state = ref.watch(residenceDuesManagementProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final groups = _groupDuesByApartment(state.value?.dues ?? const []);
    return Stack(
      key: const Key('dues-management-page'),
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : AppSpacing.xLarge,
              compact ? 12 : AppSpacing.xLarge,
              compact ? 12 : AppSpacing.xLarge,
              groups.isEmpty ? 28 : 112,
            ),
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DarJarSubpageHeader(
                      title: localizations.duesManagement,
                      fallbackLocation: AppRoutes.profile,
                      description: localizations.duesManagementDescription,
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    DarJarCard(
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                            child: Icon(Icons.auto_awesome_rounded),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: Text(
                              localizations.duesGeneratedNotice,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    state.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxxLarge),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stackTrace) => _ManagementEmptyState(
                        key: const Key('dues-management-error'),
                        message: localizations.duesLoadError,
                        icon: Icons.error_outline_rounded,
                        onRetry: () =>
                            ref.invalidate(residenceDuesManagementProvider),
                      ),
                      data: (overview) =>
                          _ManagementContent(overview: overview),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (groups.isNotEmpty)
          PositionedDirectional(
            start: compact ? 12 : AppSpacing.xLarge,
            end: compact ? 12 : AppSpacing.xLarge,
            bottom: AppSpacing.medium,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 940 : 320),
                  child: DarJarButton(
                    key: const Key('record-payment-button'),
                    label: localizations.duesRecordPayment,
                    icon: Icons.add_card_rounded,
                    expanded: true,
                    onPressed: () => _showRecordPaymentSheet(context, groups),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ManagementContent extends StatelessWidget {
  const _ManagementContent({required this.overview});

  final ResidenceDuesOverview overview;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final groups = _groupDuesByApartment(overview.dues);
    if (groups.isEmpty) {
      return _ManagementEmptyState(
        key: const Key('dues-management-no-apartments'),
        message: localizations.duesNoApartments,
        icon: Icons.apartment_outlined,
      );
    }
    final expected = overview.dues.fold(
      0,
      (total, due) => total + due.amountDue,
    );
    final collected = overview.dues.fold(
      0,
      (total, due) => total + due.amountPaid,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.duesApartmentsSummary,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.medium),
        _ManagementTotals(
          expected: expected,
          collected: collected,
          remaining: expected - collected,
        ),
        const SizedBox(height: AppSpacing.large),
        for (final group in groups) ...[
          _ApartmentDuesCard(group: group),
          const SizedBox(height: AppSpacing.small),
        ],
        const SizedBox(height: AppSpacing.large),
        Text(
          localizations.duesPaymentHistory,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.medium),
        if (overview.payments.isEmpty)
          _ManagementEmptyState(
            message: localizations.duesNoPayments,
            icon: Icons.history_rounded,
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
                  _ManagementPaymentRow(payment: overview.payments[index]),
                  if (index != overview.payments.length - 1) const Divider(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ApartmentDuesCard extends StatelessWidget {
  const _ApartmentDuesCard({required this.group});

  final _ApartmentDuesGroup group;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return DarJarCard(
      key: ValueKey('managed-apartment-${group.apartmentId}'),
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('open-periods-${group.apartmentId}'),
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: () => _showPeriodDetailsSheet(context, group),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.duesApartment(group.apartmentNumber),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      group.outstandingPeriods == 0
                          ? localizations.duesAllPeriodsPaid
                          : localizations.duesOutstandingPeriods(
                              group.outstandingPeriods,
                            ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: group.outstandingPeriods == 0
                            ? AppColors.residence
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_amount(context, group.remainingAmount)} '
                    '${localizations.currency}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: group.remainingAmount == 0
                          ? AppColors.residence
                          : AppColors.warning,
                    ),
                  ),
                  Text(
                    localizations.duesRemaining,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.small),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.inkMuted,
                textDirection: ui.TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showPeriodDetailsSheet(
  BuildContext context,
  _ApartmentDuesGroup group,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PeriodDetailsSheet(group: group),
  );
}

class _PeriodDetailsSheet extends StatelessWidget {
  const _PeriodDetailsSheet({required this.group});

  final _ApartmentDuesGroup group;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Container(
          key: const Key('period-details-sheet'),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.large),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xLarge,
                    AppSpacing.large,
                    AppSpacing.medium,
                    AppSpacing.medium,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.duesPeriodDetailsFor(
                            group.apartmentNumber,
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.xLarge),
                    itemCount: group.dues.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final due = group.dues[index];
                      return Padding(
                        key: ValueKey('managed-due-${due.id}'),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.small,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _periodLabel(context, due.periodKey),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              '${_amount(context, due.remainingAmount)} '
                              '${localizations.currency}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: AppSpacing.medium),
                            _ManagementStatusBadge(status: due.status),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showRecordPaymentSheet(
  BuildContext context,
  List<_ApartmentDuesGroup> groups,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RecordPaymentSheet(groups: groups),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).duesPaymentSaved)),
    );
  }
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet({required this.groups});

  final List<_ApartmentDuesGroup> groups;

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  final _noteController = TextEditingController();
  _ApartmentDuesGroup? _selectedGroup;
  DateTime _paidAt = DateTime.now();
  bool _saving = false;
  bool _invalidApartment = false;
  bool _invalidAmount = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dateController.text.isEmpty) {
      _dateController.text = _formattedDate();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        key: const Key('record-payment-sheet'),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xLarge,
          AppSpacing.xLarge,
          AppSpacing.xLarge,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xLarge,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.duesRecordPayment,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
                DropdownButtonFormField<String>(
                  key: const Key('payment-apartment-field'),
                  initialValue: _selectedGroup?.apartmentId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: localizations.duesSelectApartment,
                    prefixIcon: const Icon(Icons.apartment_rounded),
                    errorText: _invalidApartment
                        ? localizations.duesSelectApartmentError
                        : null,
                  ),
                  items: [
                    for (final group in widget.groups)
                      DropdownMenuItem(
                        value: group.apartmentId,
                        child: Text(
                          localizations.duesApartment(group.apartmentNumber),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (apartmentId) {
                          final group = widget.groups.firstWhere(
                            (item) => item.apartmentId == apartmentId,
                          );
                          final suggestedAmount = group.remainingAmount > 0
                              ? group.remainingAmount
                              : group.defaultAmount;
                          setState(() {
                            _selectedGroup = group;
                            _invalidApartment = false;
                            _invalidAmount = false;
                            _amountController.text = suggestedAmount.toString();
                          });
                        },
                ),
                if (_selectedGroup case final group?) ...[
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    localizations.duesPaymentDistribution,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    localizations.duesAdvancePaymentHint(
                      _amount(context, group.defaultAmount),
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  DarJarTextField(
                    key: const Key('payment-amount-field'),
                    controller: _amountController,
                    label: localizations.duesPaymentAmount,
                    suffixText: localizations.currency,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  if (_invalidAmount) ...[
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      localizations.duesInvalidPayment,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.large),
                  DarJarTextField(
                    key: const Key('payment-date-field'),
                    controller: _dateController,
                    label: localizations.duesPaymentDate,
                    prefixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: _saving ? null : _selectDate,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  DarJarTextField(
                    key: const Key('payment-note-field'),
                    controller: _noteController,
                    label: localizations.duesPaymentNote,
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  DarJarButton(
                    key: const Key('save-payment-button'),
                    label: localizations.duesSavePayment,
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() {
        _paidAt = selected;
        _dateController.text = _formattedDate();
      });
    }
  }

  String _formattedDate() {
    return DateFormat.yMMMd(
      AppLocalizations.of(context).localeName,
    ).format(_paidAt);
  }

  Future<void> _save() async {
    final group = _selectedGroup;
    if (group == null) {
      setState(() => _invalidApartment = true);
      return;
    }
    final amount = int.tryParse(_amountController.text.trim());
    final advanceAmount = amount != null && amount > group.remainingAmount
        ? amount - group.remainingAmount
        : 0;
    if (amount == null ||
        amount <= 0 ||
        (advanceAmount > 0 &&
            (group.defaultAmount == 0 ||
                advanceAmount % group.defaultAmount != 0))) {
      setState(() => _invalidAmount = true);
      return;
    }
    setState(() {
      _invalidAmount = false;
      _saving = true;
    });
    try {
      await ref
          .read(residenceDuesManagementProvider.notifier)
          .recordPayment(
            apartmentId: group.apartmentId,
            apartmentNumber: group.apartmentNumber,
            amount: amount,
            paidAt: _paidAt,
            note: _noteController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ResidenceDuesFailure {
      if (mounted) {
        setState(() {
          _invalidAmount = true;
          _saving = false;
        });
      }
    }
  }
}

class _ManagementTotals extends StatelessWidget {
  const _ManagementTotals({
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
    final items = [
      (
        key: const Key('management-dues-expected'),
        label: localizations.duesExpected,
        amount: expected,
        color: AppColors.primary,
      ),
      (
        key: const Key('management-dues-collected'),
        label: localizations.duesCollected,
        amount: collected,
        color: AppColors.residence,
      ),
      (
        key: const Key('management-dues-remaining'),
        label: localizations.duesRemaining,
        amount: remaining,
        color: AppColors.warning,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.medium * 2) / 3;
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            for (final item in items)
              SizedBox(
                key: item.key,
                width: width,
                child: DarJarCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        '${_amount(context, item.amount)} '
                        '${localizations.currency}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: item.color),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ManagementPaymentRow extends StatelessWidget {
  const _ManagementPaymentRow({required this.payment});

  final ResidenceDuePayment payment;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      key: ValueKey('management-payment-${payment.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.residenceSoft,
            foregroundColor: AppColors.residence,
            child: Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.duesApartment(payment.apartmentNumber),
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
          Text(
            '${_amount(context, payment.amount)} ${localizations.currency}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.residence),
          ),
        ],
      ),
    );
  }
}

class _ManagementStatusBadge extends StatelessWidget {
  const _ManagementStatusBadge({required this.status});

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

class _ManagementEmptyState extends StatelessWidget {
  const _ManagementEmptyState({
    required this.message,
    required this.icon,
    this.onRetry,
    super.key,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.medium),
          Text(message, textAlign: TextAlign.center),
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

class _ApartmentDuesGroup {
  _ApartmentDuesGroup({
    required this.apartmentId,
    required this.apartmentNumber,
    required List<ResidenceDue> dues,
  }) : dues = [...dues]
         ..sort((first, second) => first.periodKey.compareTo(second.periodKey));

  final String apartmentId;
  final String apartmentNumber;
  final List<ResidenceDue> dues;

  int get outstandingPeriods =>
      dues.where((due) => due.remainingAmount > 0).length;

  int get remainingAmount =>
      dues.fold(0, (total, due) => total + due.remainingAmount);

  int get defaultAmount {
    final currentPeriod = residenceDuesPeriodKey(DateTime.now());
    for (final due in dues.reversed) {
      if (due.periodKey == currentPeriod) return due.amountDue;
    }
    return dues.isEmpty ? 0 : dues.last.amountDue;
  }
}

List<_ApartmentDuesGroup> _groupDuesByApartment(List<ResidenceDue> dues) {
  final grouped = <String, List<ResidenceDue>>{};
  for (final due in dues) {
    grouped.putIfAbsent(due.apartmentId, () => []).add(due);
  }
  final groups =
      [
        for (final entry in grouped.entries)
          _ApartmentDuesGroup(
            apartmentId: entry.key,
            apartmentNumber: entry.value.first.apartmentNumber,
            dues: entry.value,
          ),
      ]..sort(
        (first, second) =>
            first.apartmentNumber.compareTo(second.apartmentNumber),
      );
  return groups;
}

String _amount(BuildContext context, int amount) {
  return NumberFormat.decimalPattern(
    AppLocalizations.of(context).localeName,
  ).format(amount);
}

String _periodLabel(BuildContext context, String periodKey) {
  final parts = periodKey.split('-');
  return DateFormat.yMMMM(
    AppLocalizations.of(context).localeName,
  ).format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
}
