import 'package:darjar/features/reports/domain/apartment_dues_report.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/reports/presentation/residence_report_template.dart';
import 'package:darjar/features/residence/domain/finance_amount.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String apartmentDuesReportStatus(
  ApartmentDuesReportRow row,
  FinancialReportCopy copy,
) {
  if (row.totalUnpaid > 0) {
    return row.collected > 0
        ? copy.t('أداء جزئي', 'Partially paid')
        : copy.t('مبالغ متبقية', 'Outstanding');
  }
  if (row.recordedMonths == 0) {
    return !row.apartment.isDuesTrackingActive
        ? copy.t('لم يبدأ التتبع', 'Tracking not started')
        : copy.t('لا واجبات مسجلة', 'No recorded dues');
  }
  if (row.exemptMonths == row.recordedMonths) {
    return copy.t('معفاة', 'Exempt');
  }
  return copy.t('مسددة', 'Settled');
}

Future<Uint8List> buildApartmentDuesReportPdf({
  required ApartmentDuesReport report,
  required String residenceName,
  required String residenceAddress,
  required String residenceCity,
  required String localeName,
  DateTime? generatedAt,
}) async {
  final copy = FinancialReportCopy(localeName == 'ar', apartmentDues: true);
  final template = await ResidenceReportTemplate.load(
    copy: copy,
    residenceName: residenceName,
    residenceAddress: residenceAddress,
    residenceCity: residenceCity,
    generatedAt: generatedAt,
  );
  final direction = copy.arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  pw.Widget directed(pw.Widget child) =>
      pw.Directionality(textDirection: direction, child: child);
  String amount(int value) => formatFinanceAmount(value, 'en');
  pw.TableRow tableRow(
    List<String> values, {
    bool heading = false,
    bool total = false,
    bool shaded = false,
  }) {
    return pw.TableRow(
      repeat: heading,
      decoration: pw.BoxDecoration(
        color: heading
            ? reportTeal
            : total
            ? const PdfColor.fromInt(0xFFE5F3F0)
            : shaded
            ? const PdfColor.fromInt(0xFFF8F6F2)
            : PdfColors.white,
      ),
      children: (copy.arabic ? values.reversed : values)
          .map(
            (value) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: pw.Align(
                alignment: pw.Alignment.center,
                child: reportText(
                  value,
                  size: 9,
                  bold: heading || total,
                  color: heading ? PdfColors.white : reportInk,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget metric(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        children: [
          reportText(label, size: 10, color: reportMuted),
          pw.SizedBox(height: 5),
          reportText(value, size: 14, bold: true, color: reportTeal),
        ],
      ),
    ),
  );
  template.doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      maxPages: 10000,
      textDirection: direction,
      header: (_) => directed(template.header(report.from, report.to)),
      footer: (context) =>
          directed(template.footer(context.pageNumber, context.pagesCount)),
      build: (_) => [
        directed(
          pw.Row(
            children: [
              metric(
                copy.t('عدد الشقق', 'Apartments'),
                '${report.rows.length}',
              ),
              metric(
                copy.t('إجمالي المستحق للفترة', 'Total due for period'),
                amount(report.expected),
              ),
              metric(
                copy.t('إجمالي المحصل للفترة', 'Total collected for period'),
                amount(report.collected),
              ),
              metric(
                copy.t('إجمالي المتبقي', 'Total outstanding'),
                amount(report.totalUnpaid),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        reportText(
          copy.t(
            'جميع المبالغ بالدرهم المغربي',
            'All amounts in Moroccan dirhams (MAD)',
          ),
          size: 8,
          color: reportMuted,
        ),
        pw.SizedBox(height: 8),
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
            children: [
              tableRow([
                copy.t('الشقة', 'Apartment'),
                copy.t('الوضعية', 'Status'),
                copy.t('المستحق للفترة', 'Due for period'),
                copy.t('المحصل للفترة', 'Collected for period'),
                copy.t('المتبقي للفترة', 'Outstanding for period'),
                copy.t('متأخرات سابقة', 'Prior arrears'),
                copy.t('إجمالي المتبقي', 'Total outstanding'),
              ], heading: true),
              for (var i = 0; i < report.rows.length; i++)
                tableRow([
                  report.rows[i].apartment.number,
                  apartmentDuesReportStatus(report.rows[i], copy),
                  amount(report.rows[i].expected),
                  amount(report.rows[i].collected),
                  amount(report.rows[i].unpaid),
                  amount(report.rows[i].previousUnpaid),
                  amount(report.rows[i].totalUnpaid),
                ], shaded: i.isOdd),
              tableRow([
                copy.t('الإجمالي', 'Total'),
                '',
                amount(report.expected),
                amount(report.collected),
                amount(report.unpaid),
                amount(report.previousUnpaid),
                amount(report.totalUnpaid),
              ], total: true),
            ],
          ),
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.SizedBox(height: 14),
              reportText(copy.notes, size: 11, bold: true),
              pw.SizedBox(height: 5),
              for (final note in [
                copy.apartmentDuesBasis,
                copy.t(
                  'المسددة تعني تسوية الواجبات المسجلة فقط، ولا تؤكد اكتمال تسجيل جميع الأشهر. الإعفاءات مستبعدة من المبالغ المستحقة.',
                  'Settled refers to recorded dues only and does not confirm that every month has been recorded. Exempt dues are excluded from amounts due.',
                ),
                copy.scope,
              ])
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: reportText(note, size: 8, color: reportMuted),
                ),
            ],
          ),
        ),
      ],
    ),
  );
  return template.doc.save();
}
