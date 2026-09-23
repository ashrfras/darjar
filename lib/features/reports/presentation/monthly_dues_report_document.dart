import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/features/reports/domain/monthly_dues_report.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/reports/presentation/residence_report_template.dart';
import 'package:darjar/features/residence/domain/finance_amount.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String monthlyDuesLabel(MonthlyDuesStatus status, FinancialReportCopy copy) =>
    switch (status) {
      MonthlyDuesStatus.paid => copy.t('مؤدّى', 'Paid'),
      MonthlyDuesStatus.unpaid => copy.t('مستحق', 'Unpaid'),
      MonthlyDuesStatus.partial => copy.t('جزئي', 'Partial'),
      MonthlyDuesStatus.exempt => copy.t('معفى', 'Exempt'),
      MonthlyDuesStatus.notRecorded => copy.t('غير مسجل', 'No record'),
      MonthlyDuesStatus.notStarted => copy.t('لم يبدأ', 'Not started'),
      MonthlyDuesStatus.future => copy.t('لاحق', 'Future'),
    };

/// Compress consecutive months, preserving year boundaries for easy reading.
String monthlyDuesPeriodList(Iterable<MonthlyDuesCell> cells, String locale) {
  final dates =
      cells
          .map(
            (cell) => DateTime(
              int.parse(cell.period.substring(0, 4)),
              int.parse(cell.period.substring(5)),
            ),
          )
          .toList()
        ..sort();
  final ranges = <String>[];
  for (var i = 0; i < dates.length; i++) {
    final start = dates[i];
    var end = start;
    while (i + 1 < dates.length &&
        dates[i + 1].year == end.year &&
        dates[i + 1].month == end.month + 1) {
      end = dates[++i];
    }
    ranges.add(
      start == end
          ? DarJarDateFormat.yMMMM(start, locale)
          : '${DarJarDateFormat.mmmm(start, locale)} - ${DarJarDateFormat.yMMMM(end, locale)}',
    );
  }
  return ranges.join(locale == 'ar' ? '، ' : ', ');
}

Future<Uint8List> buildMonthlyDuesReportPdf({
  required MonthlyDuesReport report,
  required String residenceName,
  required String residenceAddress,
  required String residenceCity,
  required String localeName,
}) async {
  final copy = FinancialReportCopy(localeName == 'ar', monthlyDues: true);
  final template = await ResidenceReportTemplate.load(
    copy: copy,
    residenceName: residenceName,
    residenceAddress: residenceAddress,
    residenceCity: residenceCity,
    generatedAt: report.asOf,
  );
  final direction = copy.arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  pw.Widget directed(pw.Widget child) =>
      pw.Directionality(textDirection: direction, child: child);
  String amount(int value) => formatFinanceAmount(value, 'en');
  PdfColor background(MonthlyDuesStatus status) => switch (status) {
    MonthlyDuesStatus.paid => const PdfColor.fromInt(0xFFE5F3F0),
    MonthlyDuesStatus.unpaid => const PdfColor.fromInt(0xFFFCE8E6),
    MonthlyDuesStatus.partial => const PdfColor.fromInt(0xFFFFF1CE),
    MonthlyDuesStatus.exempt => const PdfColor.fromInt(0xFFECE8F6),
    _ => const PdfColor.fromInt(0xFFF4F4F4),
  };
  pw.Widget cell(String text, {bool heading = false, PdfColor? color}) =>
      pw.Container(
        color: heading ? reportTeal : color,
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        alignment: pw.Alignment.center,
        child: reportText(
          text,
          size: 7.5,
          bold: heading,
          color: heading ? PdfColors.white : reportInk,
        ),
      );
  pw.TableRow row(List<pw.Widget> cells, {bool heading = false}) => pw.TableRow(
    repeat: heading,
    verticalAlignment: pw.TableCellVerticalAlignment.full,
    children: (copy.arabic ? cells.reversed : cells).toList(),
  );
  final widths = <double>[44, ...List.filled(12, 43), 45, 45, 72];
  final orderedWidths = copy.arabic ? widths.reversed.toList() : widths;
  final debtRows = report.rows.where((row) => row.remaining > 0).toList();
  template.doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      maxPages: 10000,
      textDirection: direction,
      header: (_) => directed(
        template.header(DateTime(report.year), DateTime(report.year, 12, 31)),
      ),
      footer: (context) =>
          directed(template.footer(context.pageNumber, context.pagesCount)),
      build: (_) => [
        reportText(
          copy.t(
            'وضعية الأداء بتاريخ ${template.date(report.asOf)} • ${report.rows.length} شقة • المتبقي: ${amount(report.remaining)} درهم',
            'Payment status as of ${template.date(report.asOf)} • ${report.rows.length} apartments • Outstanding: ${amount(report.remaining)} MAD',
          ),
          size: 10,
          bold: true,
          color: reportTeal,
        ),
        pw.SizedBox(height: 8),
        reportText(copy.monthlyDuesBasis, size: 8, color: reportMuted),
        pw.SizedBox(height: 10),
        if (report.rows.isEmpty)
          reportText(
            copy.t(
              'لا توجد شقق مسجلة في الإقامة.',
              'No apartments registered in this residence.',
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: reportOutline, width: 0.5),
            columnWidths: {
              for (var i = 0; i < orderedWidths.length; i++)
                i: pw.FlexColumnWidth(orderedWidths[i]),
            },
            children: [
              row([
                cell(copy.t('الشقة', 'Apt.'), heading: true),
                for (var month = 1; month <= 12; month++)
                  cell(
                    copy.arabic
                        ? DarJarDateFormat.mmmm(
                            DateTime(report.year, month),
                            'ar',
                          )
                        : DarJarDateFormat.mmmm(
                            DateTime(report.year, month),
                            'en',
                          ).substring(0, 3),
                    heading: true,
                  ),
                cell(copy.t('مستحقة', 'Unpaid months'), heading: true),
                cell(copy.t('جزئية', 'Partial months'), heading: true),
                cell(copy.t('المتبقي بالدرهم', 'Balance MAD'), heading: true),
              ], heading: true),
              for (final apartment in report.rows)
                row([
                  cell(apartment.apartment.number),
                  for (final month in apartment.months)
                    cell(
                      '${monthlyDuesLabel(month.status, copy)}${month.status == MonthlyDuesStatus.partial ? '\n${amount(month.remaining)}' : ''}',
                      color: background(month.status),
                    ),
                  cell('${apartment.unpaidCount}'),
                  cell('${apartment.partialCount}'),
                  cell(amount(apartment.remaining)),
                ]),
            ],
          ),
        pw.SizedBox(height: 10),
        reportText(
          copy.t(
            'جزئي: الرقم داخل الخانة هو المبلغ المتبقي بالدرهم. لم يبدأ: قبل بدء التتبع. غير مسجل: لا يوجد واجب مسجل. لاحق: شهر لم يحن بعد. الإعفاءات حسب السجلات الحالية.',
            'Partial: the cell shows the remaining MAD amount. Not started: before tracking began. No record: no recorded charge. Future: month not yet reached. Exemptions reflect current records.',
          ),
          size: 8,
          color: reportMuted,
        ),
        if (debtRows.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          reportText(
            copy.t(
              'تفصيل الأشهر المتبقية، بما فيها السنوات السابقة',
              'Outstanding months, including previous years',
            ),
            size: 14,
            bold: true,
          ),
          pw.SizedBox(height: 10),
          // One table row per apartment keeps long lists readable across pages.
          pw.Table(
            border: pw.TableBorder.all(color: reportOutline, width: 0.5),
            columnWidths: copy.arabic
                ? {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(1),
                  }
                : {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(4),
                  },
            children: [
              row([
                cell(copy.t('الشقة', 'Apartment'), heading: true),
                cell(copy.t('أشهر مستحقة', 'Unpaid months'), heading: true),
                cell(
                  copy.t('أشهر بأداء جزئي', 'Partially paid months'),
                  heading: true,
                ),
              ], heading: true),
              for (final apartment in debtRows)
                row([
                  cell(apartment.apartment.number),
                  cell(
                    monthlyDuesPeriodList(
                          apartment.outstanding.where(
                            (c) => c.status == MonthlyDuesStatus.unpaid,
                          ),
                          copy.locale,
                        ).isEmpty
                        ? '-'
                        : monthlyDuesPeriodList(
                            apartment.outstanding.where(
                              (c) => c.status == MonthlyDuesStatus.unpaid,
                            ),
                            copy.locale,
                          ),
                  ),
                  cell(
                    monthlyDuesPeriodList(
                          apartment.outstanding.where(
                            (c) => c.status == MonthlyDuesStatus.partial,
                          ),
                          copy.locale,
                        ).isEmpty
                        ? '-'
                        : monthlyDuesPeriodList(
                            apartment.outstanding.where(
                              (c) => c.status == MonthlyDuesStatus.partial,
                            ),
                            copy.locale,
                          ),
                  ),
                ]),
            ],
          ),
        ],
        pw.SizedBox(height: 10),
        reportText(copy.scope, size: 8, color: reportMuted),
      ],
    ),
  );
  return template.doc.save();
}
