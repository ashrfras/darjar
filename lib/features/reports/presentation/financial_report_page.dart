import 'package:darjar/features/reports/domain/monthly_dues_report.dart';
import 'package:darjar/features/reports/presentation/monthly_dues_report_document.dart';
import 'package:darjar/features/reports/data/apartment_dues_report_data.dart';
import 'package:darjar/features/reports/domain/apartment_dues_report.dart';
import 'package:darjar/features/reports/presentation/apartment_dues_report_document.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/reports/data/financial_report_data.dart';
import 'package:darjar/features/reports/domain/financial_report.dart';
import 'package:darjar/features/reports/domain/account_statement.dart';
import 'package:darjar/features/reports/presentation/account_statement_document.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/reports/presentation/financial_report_document.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

class ResidenceReportsPage extends ConsumerWidget {
  const ResidenceReportsPage({
    super.key,
    this.financial = false,
    this.statement = false,
    this.apartmentDues = false,
    this.monthlyDues = false,
  });
  final bool financial;
  final bool statement;
  final bool apartmentDues;
  final bool monthlyDues;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residence = ref
        .watch(residenceContextProvider)
        .value
        ?.activeResidence;
    final copy = FinancialReportCopy(
      Localizations.localeOf(context).languageCode == 'ar',
      statement: statement,
      apartmentDues: apartmentDues,
      monthlyDues: monthlyDues,
    );
    if (residence?.canManageResidence != true) {
      return Center(
        child: Text(
          copy.t(
            'التقارير متاحة لإدارة الإقامة فقط.',
            'Reports are available to residence managers only.',
          ),
        ),
      );
    }
    if (financial || statement || apartmentDues || monthlyDues) {
      return _FinancialReportForm(
        key: ValueKey(
          '${residence!.id}-${copy.locale}-$statement-$apartmentDues-$monthlyDues',
        ),
        copy: copy,
      );
    }
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      key: const Key('residence-reports-page'),
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
                fallbackLocation: AppRoutes.administration,
                title: copy.reports,
                onBack: () => context.go(AppRoutes.administration),
                description: compact ? null : copy.reportsDescription,
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('financial-report-link'),
                  leading: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(copy.title),
                  subtitle: Text(copy.description),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.financialReport),
                ),
              ),
              const SizedBox(height: 12),
              DarJarCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('account-statement-link'),
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(copy.t('كشف الحساب', 'Account statement')),
                  subtitle: Text(
                    FinancialReportCopy(
                      copy.arabic,
                      statement: true,
                    ).description,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.accountStatement),
                ),
              ),
              const SizedBox(height: 12),
              DarJarCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('apartment-dues-report-link'),
                  leading: const Icon(
                    Icons.apartment_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    FinancialReportCopy(copy.arabic, apartmentDues: true).title,
                  ),
                  subtitle: Text(
                    FinancialReportCopy(
                      copy.arabic,
                      apartmentDues: true,
                    ).description,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.apartmentDuesReport),
                ),
              ),
              const SizedBox(height: 12),
              DarJarCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('monthly-dues-report-link'),
                  leading: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    FinancialReportCopy(copy.arabic, monthlyDues: true).title,
                  ),
                  subtitle: Text(
                    FinancialReportCopy(
                      copy.arabic,
                      monthlyDues: true,
                    ).description,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.monthlyDuesReport),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialReportForm extends ConsumerStatefulWidget {
  const _FinancialReportForm({required this.copy, super.key});
  final FinancialReportCopy copy;
  @override
  ConsumerState<_FinancialReportForm> createState() =>
      _FinancialReportFormState();
}

class _FinancialReportFormState extends ConsumerState<_FinancialReportForm> {
  late DateTimeRange _range;
  Uint8List? _pdf;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final reportKey = copy.monthlyDues
        ? 'monthly-dues-report'
        : copy.apartmentDues
        ? 'apartment-dues-report'
        : copy.statement
        ? 'account-statement'
        : 'financial-report';
    if (copy.apartmentDues || copy.monthlyDues) {
      ref.watch(apartmentDuesReportDataProvider);
    } else {
      ref.watch(financialReportDataProvider);
    }
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      key: Key('$reportKey-page'),
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
                fallbackLocation: AppRoutes.reports,
                title: copy.title,
                onBack: () => context.go(AppRoutes.reports),
                description: compact ? null : copy.description,
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy.monthlyDues
                          ? copy.t('السنة المطلوبة', 'Report year')
                          : copy.t('الفترة المطلوبة', 'Report period'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (copy.monthlyDues)
                      DropdownButtonFormField<int>(
                        key: const Key('monthly-dues-report-year'),
                        initialValue: _range.start.year,
                        items: [
                          for (
                            var year = DateTime.now().year;
                            year >= 1900;
                            year--
                          )
                            DropdownMenuItem(value: year, child: Text('$year')),
                        ],
                        onChanged: _busy
                            ? null
                            : (year) {
                                if (year == null) return;
                                setState(() {
                                  _range = DateTimeRange(
                                    start: DateTime(year),
                                    end: DateTime(year, 12, 31),
                                  );
                                  _pdf = null;
                                  _error = null;
                                });
                              },
                      )
                    else
                      OutlinedButton.icon(
                        key: Key('$reportKey-date-range'),
                        onPressed: _busy ? null : _pickRange,
                        icon: const Icon(Icons.date_range_outlined),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '${copy.t('من', 'From')} ${DarJarDateFormat.yMMMd(_range.start, copy.locale)}  ${copy.t('إلى', 'to')} ${DarJarDateFormat.yMMMd(_range.end, copy.locale)}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      copy.monthlyDues
                          ? copy.monthlyDuesBasis
                          : copy.apartmentDues
                          ? copy.apartmentDuesBasis
                          : copy.statement
                          ? copy.basis
                          : copy.duesBasis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    DarJarButton(
                      key: Key('generate-$reportKey'),
                      label: _busy
                          ? copy.t('جارٍ الإعداد…', 'Preparing…')
                          : copy.generate,
                      icon: Icons.description_outlined,
                      onPressed: _busy ? null : _generate,
                    ),
                    if (_busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              if (_pdf != null) ...[
                const SizedBox(height: 20),
                DarJarButton(
                  key: Key('download-$reportKey'),
                  label: copy.download,
                  icon: Icons.download_outlined,
                  onPressed: _busy ? null : _save,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 720,
                  child: PdfPreview(
                    key: ValueKey(_pdf),
                    build: (_) async => _pdf!,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    allowPrinting: false,
                    allowSharing: false,
                    canDebug: false,
                    useActions: false,
                    onError: (_, error) => Center(child: Text(copy.error)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            datePickerTheme: theme.datePickerTheme.copyWith(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.surface,
              headerForegroundColor: AppColors.ink,
              rangePickerBackgroundColor: AppColors.surface,
              rangePickerSurfaceTintColor: Colors.transparent,
              rangePickerHeaderBackgroundColor: AppColors.surface,
              rangePickerHeaderForegroundColor: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = picked;
      _pdf = null;
      _error = null;
    });
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
      _pdf = null;
    });
    try {
      if (widget.copy.monthlyDues) {
        ref.invalidate(apartmentDuesReportDataProvider);
        final data = await ref.read(apartmentDuesReportDataProvider.future);
        final bytes = await buildMonthlyDuesReportPdf(
          report: MonthlyDuesReport(
            year: _range.start.year,
            asOf: DateTime.now(),
            apartments: data.apartments,
            dues: data.dues,
          ),
          residenceName: data.residence.name,
          residenceAddress: data.residence.address,
          residenceCity: data.residence.city,
          localeName: widget.copy.locale,
        );
        if (mounted) setState(() => _pdf = bytes);
        return;
      }
      if (widget.copy.apartmentDues) {
        ref.invalidate(apartmentDuesReportDataProvider);
        final data = await ref.read(apartmentDuesReportDataProvider.future);
        final bytes = await buildApartmentDuesReportPdf(
          report: ApartmentDuesReport(
            from: _range.start,
            to: _range.end,
            apartments: data.apartments,
            dues: data.dues,
          ),
          residenceName: data.residence.name,
          residenceAddress: data.residence.address,
          residenceCity: data.residence.city,
          localeName: widget.copy.locale,
        );
        if (mounted) setState(() => _pdf = bytes);
        return;
      }
      // Fetch fresh records for each export; never silently reuse an old report.
      ref.invalidate(financialReportDataProvider);
      final data = await ref.read(financialReportDataProvider.future);
      final report = FinancialReport(
        from: _range.start,
        to: _range.end,
        transactions: data.finances.transactions,
        dues: data.dues,
      );
      final bytes = widget.copy.statement
          ? await buildAccountStatementPdf(
              statement: AccountStatement(
                from: _range.start,
                to: _range.end,
                transactions: data.finances.transactions,
              ),
              residenceName: data.residence.name,
              residenceAddress: data.residence.address,
              residenceCity: data.residence.city,
              localeName: widget.copy.locale,
            )
          : await buildFinancialReportPdf(
              report: report,
              residenceName: data.residence.name,
              residenceAddress: data.residence.address,
              residenceCity: data.residence.city,
              localeName: widget.copy.locale,
            );
      if (mounted) setState(() => _pdf = bytes);
    } catch (_) {
      if (mounted) setState(() => _error = widget.copy.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final bytes = _pdf;
    if (bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String stamp(DateTime value) => value.toIso8601String().substring(0, 10);
      final filename = widget.copy.monthlyDues
          ? 'darjar-monthly-dues-${_range.start.year}.pdf'
          : 'darjar-${widget.copy.apartmentDues
                ? 'apartment-dues-report'
                : widget.copy.statement
                ? 'account-statement'
                : 'financial-report'}-${stamp(_range.start)}-${stamp(_range.end)}.pdf';
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: filename,
      );
      final mobile =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android);
      if (mobile) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [file],
            fileNameOverrides: [filename],
            subject: widget.copy.title,
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      } else {
        final location = await getSaveLocation(suggestedName: filename);
        if (location != null) await file.saveTo(location.path);
      }
    } catch (_) {
      if (mounted) setState(() => _error = widget.copy.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
