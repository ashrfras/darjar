import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/features/reports/domain/monthly_dues_report.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/reports/presentation/residence_report_template.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String monthlyDuesLabel(MonthlyDuesStatus status, FinancialReportCopy copy) =>
    switch (status) {
      MonthlyDuesStatus.paid => copy.t('مؤدّى', 'Paid'),
      MonthlyDuesStatus.unpaid ||
      MonthlyDuesStatus.partial => copy.t('متأخر', 'Overdue'),
      MonthlyDuesStatus.exempt => copy.t('معفى', 'Exempt'),
      MonthlyDuesStatus.notRecorded ||
      MonthlyDuesStatus.notStarted ||
      MonthlyDuesStatus.future => copy.t(
        'لاحق أو غير مسجل',
        'Future or no record',
      ),
    };

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
  PdfColor background(MonthlyDuesStatus status) => switch (status) {
    MonthlyDuesStatus.paid => const PdfColor.fromInt(0xFF63B39D),
    MonthlyDuesStatus.unpaid ||
    MonthlyDuesStatus.partial => const PdfColor.fromInt(0xFFE4837B),
    MonthlyDuesStatus.exempt => const PdfColor.fromInt(0xFFA18BCB),
    MonthlyDuesStatus.notRecorded ||
    MonthlyDuesStatus.notStarted ||
    MonthlyDuesStatus.future => PdfColors.white,
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
  final widths = <double>[44, ...List.filled(12, 43), 45, 45];
  final orderedWidths = copy.arabic ? widths.reversed.toList() : widths;
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
        directed(
          pw.Wrap(
            spacing: 18,
            runSpacing: 6,
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            children: [
              reportText(
                copy.t('مفتاح الألوان', 'Color key'),
                size: 9,
                bold: true,
              ),
              for (final status in const [
                MonthlyDuesStatus.paid,
                MonthlyDuesStatus.unpaid,
                MonthlyDuesStatus.exempt,
                MonthlyDuesStatus.future,
              ])
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 11,
                      height: 11,
                      decoration: pw.BoxDecoration(
                        color: background(status),
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 0.5,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    reportText(monthlyDuesLabel(status, copy), size: 8),
                  ],
                ),
            ],
          ),
        ),
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
                cell(copy.t('مستحق', 'Unpaid months'), heading: true),
                cell(copy.t('فائض', 'Prepaid months'), heading: true),
              ], heading: true),
              for (final apartment in report.rows)
                row([
                  cell(apartment.apartment.number),
                  for (final month in apartment.months)
                    pw.Container(height: 27, color: background(month.status)),
                  cell('${apartment.unpaidCount}'),
                  cell('${apartment.prepaidCount}'),
                ]),
            ],
          ),
        pw.SizedBox(height: 10),
        reportText(copy.scope, size: 8, color: reportMuted),
      ],
    ),
  );
  return template.doc.save();
}
