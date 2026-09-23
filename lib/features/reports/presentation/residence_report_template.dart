import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const reportTeal = PdfColor.fromInt(0xFF0F766E);
const reportInk = PdfColor.fromInt(0xFF17151D);
const reportMuted = PdfColor.fromInt(0xFF6D6976);
const reportOutline = PdfColor.fromInt(0xFFE7E3EA);

pw.Widget reportText(
  String value, {
  double size = 10,
  bool bold = false,
  PdfColor color = reportInk,
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

class ResidenceReportTemplate {
  ResidenceReportTemplate._(
    this.copy,
    this.displayName,
    this.addressLine,
    this.logo,
    this.doc,
    this.generatedAt,
  );
  final FinancialReportCopy copy;
  final String displayName;
  final String addressLine;
  final pw.MemoryImage logo;
  final pw.Document doc;
  final DateTime generatedAt;
  static Future<ResidenceReportTemplate> load({
    required FinancialReportCopy copy,
    required String residenceName,
    required String residenceAddress,
    required String residenceCity,
    DateTime? generatedAt,
  }) async {
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
      title: '${copy.pdfTitle} - $displayName',
      author: 'DarJar',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    return ResidenceReportTemplate._(
      copy,
      displayName,
      addressLine,
      logo,
      doc,
      generatedAt ?? DateTime.now(),
    );
  }

  String date(DateTime value) => DarJarDateFormat.yMMMd(value, copy.locale);
  pw.Widget header(DateTime from, DateTime to) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(height: 4, color: reportTeal),
      pw.SizedBox(height: 18),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                reportText(displayName, size: 17, bold: true, maxLines: 2),
                if (addressLine.isNotEmpty)
                  reportText(
                    addressLine,
                    size: 9,
                    color: reportMuted,
                    maxLines: 2,
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Image(logo, width: 91, height: 42, fit: pw.BoxFit.contain),
        ],
      ),
      pw.SizedBox(height: 20),
      reportText(copy.pdfTitle, size: 26, bold: true),
      pw.SizedBox(height: 3),
      reportText(
        copy.t(
          'من ${date(from)} إلى ${date(to)}',
          '${date(from)} - ${date(to)}',
        ),
        color: reportMuted,
      ),
      pw.SizedBox(height: 17),
    ],
  );
  pw.Widget footer(int page, int pages) => pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.SizedBox(height: 24),
      pw.Divider(color: reportOutline),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          reportText(
            copy.t(
              'أُنشئ بواسطة دارجار • ${date(generatedAt)}',
              'Created with DarJar • ${date(generatedAt)}',
            ),
            size: 7,
            color: reportMuted,
          ),
          reportText('$page / $pages', size: 7, color: reportMuted),
        ],
      ),
    ],
  );
}
