import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/features/receipts/domain/payment_receipt.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _officialGreen = PdfColor(0.09, 0.42, 0.32);
const _officialInk = PdfColor(0.08, 0.20, 0.17);
const _stampBlue = PdfColor(0.04, 0.25, 0.68, 0.76);

Future<Uint8List> buildPaymentReceiptPdf(
  PaymentReceipt receipt, {
  required String localeName,
}) async {
  final regularFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
  );
  final arabic = localeName == 'ar';
  final residenceName = normalizeResidenceName(receipt.residenceName);
  final address = receipt.residenceAddress.trim();
  final city = moroccanCityNameForLocale(receipt.residenceCity, localeName);
  final addressLine = _addressWithoutTrailingCity(address, city);
  final fullAddress = [
    if (addressLine.isNotEmpty) addressLine,
    if (city.isNotEmpty) city,
  ].join(arabic ? '، ' : ', ');
  final periods = receipt.periodKeys
      .map((key) => _periodLabel(key, localeName))
      .toList(growable: false);
  final period = periods.length == 1
      ? periods.single
      : arabic
      ? 'من ${periods.first} إلى ${periods.last}'
      : '${periods.first} - ${periods.last}';
  final issuedOn = DarJarDateFormat.yMMMd(receipt.paidAt, localeName);
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
  );

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
      build: (context) => pw.Directionality(
        textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(height: 4, color: _officialGreen),
            pw.SizedBox(height: 18),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        arabic ? 'اتحاد الملاك المشتركين' : 'Co-owners Union',
                        style: pw.TextStyle(
                          color: _officialInk,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        arabic ? 'إقامة $residenceName' : residenceName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (addressLine.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          addressLine,
                          style: const pw.TextStyle(
                            color: PdfColor(0.33, 0.39, 0.37),
                            fontSize: 9,
                          ),
                        ),
                      ],
                      if (city.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          city,
                          style: const pw.TextStyle(
                            color: PdfColor(0.33, 0.39, 0.37),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                _receiptQr(receipt),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 13),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColor(0.84, 0.87, 0.86)),
                  bottom: pw.BorderSide(color: PdfColor(0.84, 0.87, 0.86)),
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    arabic
                        ? 'وصل أداء واجبات الملكية المشتركة'
                        : 'Residence Dues Payment Receipt',
                    style: pw.TextStyle(
                      color: _officialInk,
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    arabic
                        ? 'وثيقة إثبات أداء صادرة عن إدارة الإقامة'
                        : 'Proof of payment issued by the residence management',
                    style: const pw.TextStyle(
                      color: PdfColor(0.39, 0.44, 0.42),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 19),
            pw.Text(
              arabic
                  ? 'يشهد السيد وكيل اتحاد الملاك المشتركين أنه تم تسجيل أداء واجبات الإقامة وفق البيانات المبينة أدناه.'
                  : 'The residence management certifies that the dues payment detailed below has been recorded.',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 4),
            ),
            pw.SizedBox(height: 15),
            _amountPanel(receipt.amount, arabic),
            pw.SizedBox(height: 14),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor(0.84, 0.87, 0.86)),
              ),
              child: pw.Column(
                children: [
                  _officialRow(
                    arabic ? 'الإقامة' : 'Residence',
                    arabic ? 'إقامة $residenceName' : residenceName,
                    shaded: true,
                  ),
                  _officialRow(
                    arabic ? 'الشقة' : 'Apartment',
                    receipt.apartmentNumber,
                  ),
                  _officialRow(
                    arabic ? 'الفترة المؤداة' : 'Paid period',
                    period,
                    shaded: true,
                  ),
                  _officialRow(
                    arabic ? 'تاريخ الأداء' : 'Payment date',
                    issuedOn,
                  ),
                  if (receipt.note.isNotEmpty)
                    _officialRow(
                      arabic ? 'ملاحظات' : 'Notes',
                      receipt.note,
                      shaded: true,
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _manualPaymentNotice(arabic),
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _officialStamp(
                  residenceName: residenceName,
                  residenceAddress: fullAddress,
                ),
                _signatureLine(arabic),
              ],
            ),
            pw.SizedBox(height: 15),
            _footer(receipt, arabic),
          ],
        ),
      ),
    ),
  );
  return document.save();
}

pw.Widget _receiptQr(PaymentReceipt receipt) => pw.Directionality(
  textDirection: pw.TextDirection.ltr,
  child: pw.BarcodeWidget(
    barcode: pw.Barcode.qrCode(),
    data: receipt.url,
    width: 70,
    height: 70,
    color: _officialInk,
    drawText: false,
  ),
);

pw.Widget _amountPanel(int amount, bool arabic) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(vertical: 11),
  decoration: pw.BoxDecoration(
    color: const PdfColor(0.95, 0.97, 0.96),
    border: pw.Border.all(color: const PdfColor(0.79, 0.85, 0.82)),
  ),
  child: pw.Column(
    children: [
      pw.Text(
        arabic ? 'المبلغ المؤدى' : 'AMOUNT PAID',
        style: const pw.TextStyle(
          color: PdfColor(0.39, 0.44, 0.42),
          fontSize: 8,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (arabic) ...[
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(
                '$amount',
                style: pw.TextStyle(
                  color: _officialGreen,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 7),
            _currencyLabel('درهم', pw.TextDirection.rtl),
          ] else ...[
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(
                '$amount',
                style: pw.TextStyle(
                  color: _officialGreen,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 7),
            _currencyLabel('MAD', pw.TextDirection.ltr),
          ],
        ],
      ),
    ],
  ),
);

pw.Widget _currencyLabel(String value, pw.TextDirection direction) =>
    pw.Directionality(
      textDirection: direction,
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: _officialGreen,
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

pw.Widget _officialRow(String label, String value, {bool shaded = false}) =>
    pw.Container(
      color: shaded ? const PdfColor(0.97, 0.98, 0.98) : PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                color: PdfColor(0.32, 0.38, 0.36),
                fontSize: 8.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: const PdfColor(0.09, 0.14, 0.12),
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

pw.Widget _manualPaymentNotice(bool arabic) => pw.Container(
  padding: const pw.EdgeInsets.all(8),
  decoration: const pw.BoxDecoration(
    color: PdfColor(0.98, 0.99, 0.99),
    border: pw.Border(right: pw.BorderSide(color: _officialGreen, width: 3)),
  ),
  child: pw.Text(
    arabic
        ? 'ملاحظة: يوثّق هذا الوصل أداءً مسجلاً يدوياً. لا يحتفظ تطبيق دارجار بالأموال ولا يعالج الدفعات.'
        : 'Note: This receipt documents a manually recorded payment. DarJar does not hold money or process payments.',
    style: const pw.TextStyle(color: PdfColor(0.32, 0.38, 0.36), fontSize: 7.5),
  ),
);

pw.Widget _signatureLine(bool arabic) => pw.Container(
  width: 180,
  padding: const pw.EdgeInsets.only(bottom: 7),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: PdfColor(0.60, 0.65, 0.63))),
  ),
  child: pw.Text(
    arabic ? 'توقيع وكيل الاتحاد' : 'Union representative signature',
    textAlign: pw.TextAlign.center,
    style: const pw.TextStyle(color: PdfColor(0.39, 0.44, 0.42), fontSize: 8),
  ),
);

pw.Widget _officialStamp({
  required String residenceName,
  required String residenceAddress,
}) => pw.Transform.rotate(
  angle: -0.035,
  child: pw.SizedBox(
    width: 215,
    height: 114,
    child: pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _stampBlue, width: 2.3),
              borderRadius: pw.BorderRadius.circular(5),
            ),
          ),
        ),
        pw.Positioned(
          left: 4,
          top: 4,
          right: 4,
          bottom: 4,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: const PdfColor(0.04, 0.25, 0.68, 0.43),
              ),
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
        ),
        pw.Positioned(
          left: 8,
          top: 7,
          right: 8,
          bottom: 7,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _stampText('اتحاد الملاك المشتركين', bold: true, size: 10.5),
              pw.SizedBox(height: 3),
              pw.Container(
                height: 0.8,
                color: const PdfColor(0.04, 0.25, 0.68, 0.50),
              ),
              pw.SizedBox(height: 4),
              _stampText('إقامة $residenceName', bold: true, size: 9.5),
              if (residenceAddress.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                _stampText(residenceAddress, size: 7.5),
              ],
              pw.SizedBox(height: 4),
              _stampText('السيد وكيل الاتحاد', bold: true, size: 8.5),
            ],
          ),
        ),
        for (final mark in const [
          (12.0, 16.0, 11.0),
          (179.0, 22.0, 15.0),
          (28.0, 102.0, 8.0),
          (151.0, 107.0, 13.0),
          (94.0, 6.0, 6.0),
        ])
          pw.Positioned(
            left: mark.$1,
            top: mark.$2,
            child: pw.Container(
              width: mark.$3,
              height: 0.7,
              color: const PdfColor(0.04, 0.25, 0.68, 0.25),
            ),
          ),
      ],
    ),
  ),
);

pw.Widget _stampText(String value, {bool bold = false, double size = 9}) =>
    pw.Text(
      value,
      textAlign: pw.TextAlign.center,
      maxLines: 2,
      style: pw.TextStyle(
        color: _stampBlue,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        lineSpacing: 1,
      ),
    );

pw.Widget _footer(PaymentReceipt receipt, bool arabic) => pw.Container(
  padding: const pw.EdgeInsets.only(top: 7),
  decoration: const pw.BoxDecoration(
    border: pw.Border(top: pw.BorderSide(color: PdfColor(0.84, 0.87, 0.86))),
  ),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Directionality(
        textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Text(
          '${arabic ? 'مرجع' : 'Reference'}: ${receipt.id}',
          style: pw.TextStyle(
            color: _officialGreen,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.Text(
        arabic
            ? 'وصل إلكتروني - يحتفظ به للإدلاء عند الحاجة'
            : 'Electronic receipt - retain for your records',
        style: const pw.TextStyle(
          color: PdfColor(0.47, 0.52, 0.50),
          fontSize: 7,
        ),
      ),
    ],
  ),
);

String _addressWithoutTrailingCity(String address, String city) {
  if (address.isEmpty || city.isEmpty || !address.endsWith(city)) {
    return address;
  }
  return address
      .substring(0, address.length - city.length)
      .replaceFirst(RegExp(r'[\s،,]+$'), '')
      .trim();
}

String _periodLabel(String periodKey, String localeName) {
  final parts = periodKey.split('-');
  return DarJarDateFormat.yMMMM(
    DateTime(int.parse(parts.first), int.parse(parts.last)),
    localeName,
  );
}
