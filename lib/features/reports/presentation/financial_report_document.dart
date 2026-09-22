import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/features/reports/domain/financial_report.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/residence/domain/finance_amount.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _teal = PdfColor.fromInt(0xFF0F766E);
const _soft = PdfColor.fromInt(0xFFE5F3F1);
const _ink = PdfColor.fromInt(0xFF17151D);
const _muted = PdfColor.fromInt(0xFF6D6976);
const _outline = PdfColor.fromInt(0xFFE7E3EA);
const _canvas = PdfColor.fromInt(0xFFF8F6F2);
const _orange = PdfColor.fromInt(0xFFE97824);

Future<Uint8List> buildFinancialReportPdf({
  required FinancialReport report,
  required String residenceName,
  required String residenceAddress,
  required String residenceCity,
  required String localeName,
  DateTime? generatedAt,
}) async {
  final copy = FinancialReportCopy(localeName == 'ar');
  final name = normalizeResidenceName(residenceName);
  final displayName = copy.t('إقامة $name', '$name Residence');
  final city = moroccanCityNameForLocale(residenceCity, copy.locale);
  final address = residenceAddress.trim();
  final addressLine = [
    if (address.isNotEmpty) address,
    if (city.isNotEmpty && !address.endsWith(city)) city,
  ].join(copy.arabic ? '، ' : ', ');
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
  );
  final logo = pw.MemoryImage(
    (await rootBundle.load(
      'assets/images/branding/3.0x/darjar-logo-header.png',
    )).buffer.asUint8List(),
  );
  final doc = pw.Document(
    title: '${copy.title} - $displayName',
    author: 'DarJar',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  String amount(int cents) => formatFinanceAmount(cents / 100, 'en');
  String date(DateTime value) => DarJarDateFormat.yMMMd(value, copy.locale);
  pw.Widget text(
    String value, {
    double size = 10,
    bool bold = false,
    PdfColor color = _ink,
    int? maxLines,
  }) => pw.Text(
    value,
    maxLines: maxLines,
    textDirection: RegExp(r'[\u0600-\u06ff]').hasMatch(value)
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr,
    style: pw.TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  );
  pw.Widget number(
    int cents, {
    double size = 13,
    PdfColor color = _ink,
    double width = 82,
  }) {
    final value = amount(cents);
    final fittedSize = (width / (value.length * 0.62))
        .clamp(6.0, size)
        .toDouble();
    return pw.SizedBox(
      width: width,
      height: size * 1.3,
      child: pw.Center(
        child: pw.Text(
          value,
          textDirection: pw.TextDirection.ltr,
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: fittedSize,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  pw.Widget row(String label, int cents, {PdfColor color = _ink}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      children: [
        pw.Expanded(flex: 3, child: text(label, size: 9)),
        pw.SizedBox(width: 8),
        number(cents, size: 12, color: color),
      ],
    ),
  );
  pw.Widget panel(String title, List<pw.Widget> children) => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _outline),
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        text(title, size: 13, bold: true, color: _teal),
        pw.SizedBox(height: 10),
        ...children,
      ],
    ),
  );
  pw.Widget metric(String label, int cents, {bool accent = false}) =>
      pw.SizedBox(
        width: (PdfPageFormat.a4.width - 84) / 4,
        child: pw.Container(
          height: 84,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: accent ? _teal : _canvas,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              text(label, size: 8.5, color: accent ? PdfColors.white : _muted),
              pw.SizedBox(height: 7),
              number(
                cents,
                size: 21,
                width: 100,
                color: accent ? PdfColors.white : _ink,
              ),
              text(
                copy.t('درهم', 'MAD'),
                size: 8,
                color: accent ? PdfColors.white : _muted,
              ),
            ],
          ),
        ),
      );
  final expenses = report.expenseCategories.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final notes = [
    copy.basis,
    copy.duesBasis,
    copy.scope,
    if (!report.hasOpeningBalance) copy.missingOpening,
  ];
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (_) => pw.Directionality(
        textDirection: copy.arabic
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        child: pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment.topCenter,
          child: pw.SizedBox(
            width: PdfPageFormat.a4.width - 60,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(height: 4, color: _teal),
                pw.SizedBox(height: 18),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          text(displayName, size: 17, bold: true, maxLines: 2),
                          if (addressLine.isNotEmpty)
                            text(
                              addressLine,
                              size: 9,
                              color: _muted,
                              maxLines: 2,
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 18),
                    pw.Image(
                      logo,
                      width: 91,
                      height: 42,
                      fit: pw.BoxFit.contain,
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                text(copy.title, size: 26, bold: true),
                pw.SizedBox(height: 3),
                text(
                  copy.t(
                    'من ${date(report.from)} إلى ${date(report.to)}',
                    '${date(report.from)} - ${date(report.to)}',
                  ),
                  color: _muted,
                ),
                pw.SizedBox(height: 17),
                pw.Row(
                  children: [
                    metric(copy.opening, report.openingCents),
                    pw.SizedBox(width: 8),
                    metric(copy.income, report.incomeCents),
                    pw.SizedBox(width: 8),
                    metric(copy.expenses, report.expenseCents),
                    pw.SizedBox(width: 8),
                    metric(copy.closing, report.closingCents, accent: true),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _soft,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      row(
                        copy.t('صافي الحركة خلال الفترة', 'Net cash movement'),
                        report.netCents,
                        color: _teal,
                      ),
                      if (report.introducedBalanceCents != 0)
                        row(copy.introduced, report.introducedBalanceCents),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: panel(copy.categories, [
                        if (expenses.isEmpty)
                          text(copy.emptyExpenses, size: 9, color: _muted),
                        for (final entry in expenses) ...[
                          row(copy.category(entry.key), entry.value),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.ClipRRect(
                                  horizontalRadius: 3,
                                  verticalRadius: 3,
                                  child: pw.LinearProgressIndicator(
                                    value: entry.value / report.expenseCents,
                                    minHeight: 5,
                                    valueColor: _teal,
                                    backgroundColor: _soft,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Directionality(
                                textDirection: pw.TextDirection.ltr,
                                child: text(
                                  '${(entry.value * 100 / report.expenseCents).toStringAsFixed(1)}%',
                                  size: 8,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 9),
                        pw.Divider(color: _outline),
                        row(copy.expenses, report.expenseCents),
                      ]),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          panel(copy.dues, [
                            row(copy.expected, report.expectedCents),
                            row(
                              copy.collected,
                              report.collectedCents,
                              color: _teal,
                            ),
                            row(
                              copy.unpaid,
                              report.unpaidCents,
                              color: _orange,
                            ),
                            pw.SizedBox(height: 6),
                            text(
                              '${copy.rate}: ${report.collectionRate == null ? copy.t('غير متاحة', 'N/A') : '${(report.collectionRate! * 100).toStringAsFixed(1)}%'}',
                              size: 10,
                              bold: true,
                              color: _teal,
                            ),
                            pw.SizedBox(height: 8),
                            pw.LinearProgressIndicator(
                              value: report.collectionRate ?? 0,
                              minHeight: 7,
                              valueColor: _teal,
                              backgroundColor: _soft,
                            ),
                            pw.SizedBox(height: 8),
                            pw.Divider(color: _outline),
                            row(copy.arrears, report.arrearsCents),
                          ]),
                          pw.SizedBox(height: 12),
                          panel(copy.sources, [
                            row(copy.dues, report.duesIncomeCents),
                            row(copy.otherIncome, report.otherIncomeCents),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                text(copy.notes, size: 11, bold: true),
                pw.SizedBox(height: 5),
                for (final note in notes)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: text(note, size: 8, color: _muted),
                  ),
                pw.SizedBox(height: 24),
                pw.Divider(color: _outline),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    text(
                      copy.t(
                        'أُنشئ بواسطة دارجار • ${date(generatedAt ?? DateTime.now())}',
                        'Created with DarJar • ${date(generatedAt ?? DateTime.now())}',
                      ),
                      size: 7,
                      color: _muted,
                    ),
                    text('1 / 1', size: 7, color: _muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
