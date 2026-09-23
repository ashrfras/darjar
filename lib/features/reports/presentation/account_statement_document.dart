import 'package:darjar/features/reports/domain/account_statement.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/reports/presentation/residence_report_template.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/domain/finance_amount.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String accountStatementDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}

String accountStatementDescription(
  FinancialReportCopy copy,
  ResidenceTransaction transaction,
) {
  if (transaction.isOpeningBalance) return copy.introduced;
  if (transaction.source == ResidenceTransactionSource.dues) {
    return '${copy.dues} - ${copy.t('شقة', 'Apartment')} ${transaction.apartmentNumber}'
        '${transaction.periodKey.isEmpty ? '' : '\n${transaction.periodKey}${transaction.periodEndKey.isNotEmpty && transaction.periodEndKey != transaction.periodKey ? ' / ${transaction.periodEndKey}' : ''}'}';
  }
  if (transaction.type == ResidenceTransactionType.income) {
    return transaction.name.isNotEmpty ? transaction.name : copy.otherIncome;
  }

  final category =
      transaction.expenseCategory ?? ResidenceExpenseCategory.custom;
  final categoryLabel = copy.category(category);
  if (category == ResidenceExpenseCategory.maintenance) {
    final note = transaction.note.trim();
    return note.isEmpty ? categoryLabel : '$categoryLabel\n$note';
  }
  if (category != ResidenceExpenseCategory.custom) return categoryLabel;

  final expenseName = transaction.name.trim();
  if (expenseName.isEmpty ||
      expenseName.toLowerCase() == category.name.toLowerCase() ||
      expenseName.toLowerCase() == categoryLabel.toLowerCase()) {
    return categoryLabel;
  }
  return '$categoryLabel\n$expenseName';
}

Future<Uint8List> buildAccountStatementPdf({
  required AccountStatement statement,
  required String residenceName,
  required String residenceAddress,
  required String residenceCity,
  required String localeName,
  DateTime? generatedAt,
}) async {
  final copy = FinancialReportCopy(localeName == 'ar', statement: true);
  final template = await ResidenceReportTemplate.load(
    copy: copy,
    residenceName: residenceName,
    residenceAddress: residenceAddress,
    residenceCity: residenceCity,
    generatedAt: generatedAt,
  );
  final summary = statement.summary;
  String amount(int cents) => formatFinanceAmount(cents / 100, 'en');
  final direction = copy.arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  pw.Widget directed(pw.Widget child) =>
      pw.Directionality(textDirection: direction, child: child);
  pw.Widget total(String label, int cents) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      children: [
        pw.Expanded(child: reportText(label, bold: true)),
        reportText(
          '${amount(cents)} ${copy.t('درهم', 'MAD')}',
          bold: true,
          color: reportTeal,
        ),
      ],
    ),
  );
  pw.Widget cell(
    String value, {
    bool heading = false,
    bool alignRight = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    child: alignRight
        ? pw.Align(
            alignment: pw.Alignment.centerRight,
            child: reportText(
              value,
              size: 8,
              bold: heading,
              color: heading ? PdfColors.white : reportInk,
            ),
          )
        : reportText(
            value,
            size: 8,
            bold: heading,
            color: heading ? PdfColors.white : reportInk,
          ),
  );
  pw.TableRow tableRow(
    List<String> values, {
    bool heading = false,
    bool shaded = false,
  }) {
    final cells = [
      for (var i = 0; i < values.length; i++)
        (value: values[i], isDate: i == 0),
    ];
    return pw.TableRow(
      repeat: heading,
      decoration: pw.BoxDecoration(
        color: heading
            ? reportTeal
            : shaded
            ? const PdfColor.fromInt(0xFFF8F6F2)
            : PdfColors.white,
      ),
      children: (copy.arabic ? cells.reversed : cells)
          .map(
            (entry) =>
                cell(entry.value, heading: heading, alignRight: entry.isDate),
          )
          .toList(),
    );
  }

  template.doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      maxPages: 10000,
      textDirection: direction,
      header: (_) => directed(template.header(summary.from, summary.to)),
      footer: (context) =>
          directed(template.footer(context.pageNumber, context.pagesCount)),
      build: (_) => [
        directed(
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: reportOutline),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              children: [
                total(copy.opening, summary.openingCents),
                total(copy.income, summary.incomeCents),
                total(copy.expenses, summary.expenseCents),
                if (summary.introducedBalanceCents != 0)
                  total(copy.introduced, summary.introducedBalanceCents),
                total(copy.closing, summary.closingCents),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        if (statement.entries.isEmpty)
          reportText(
            copy.t(
              'لا توجد عمليات مسجلة خلال الفترة المختارة.',
              'No transactions recorded in the selected period.',
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: reportOutline, width: 0.5),
            columnWidths: copy.arabic
                ? {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(2.5),
                    4: const pw.FlexColumnWidth(1.3),
                  }
                : {
                    0: const pw.FlexColumnWidth(1.3),
                    1: const pw.FlexColumnWidth(2.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1.2),
                  },
            children: [
              tableRow([
                copy.t('التاريخ', 'Date'),
                copy.t('البيان', 'Description'),
                copy.t('المداخيل', 'Income'),
                copy.t('المصاريف', 'Expenses'),
                copy.t('الرصيد', 'Balance'),
              ], heading: true),
              for (var i = 0; i < statement.entries.length; i++)
                tableRow([
                  accountStatementDate(statement.entries[i].transaction.date),
                  accountStatementDescription(
                    copy,
                    statement.entries[i].transaction,
                  ),
                  statement.entries[i].transaction.type ==
                          ResidenceTransactionType.income
                      ? amount(statement.entries[i].amountCents)
                      : '-',
                  statement.entries[i].transaction.type ==
                          ResidenceTransactionType.expense
                      ? amount(statement.entries[i].amountCents)
                      : '-',
                  amount(statement.entries[i].balanceCents),
                ], shaded: i.isOdd),
            ],
          ),
        pw.SizedBox(height: 14),
        reportText(copy.notes, bold: true, size: 11),
        pw.SizedBox(height: 5),
        for (final note in [
          copy.basis,
          if (summary.introducedBalanceCents != 0)
            copy.t(
              'الرصيد الافتتاحي المسجل داخل الفترة ظاهر في الكشف ولا يدخل ضمن مجموع المداخيل.',
              'Initial balance entries appear in the statement but are excluded from period income.',
            ),
          if (!summary.hasOpeningBalance) copy.missingOpening,
          copy.scope,
        ])
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: reportText(note, size: 8, color: reportMuted),
          ),
      ],
    ),
  );
  return template.doc.save();
}
