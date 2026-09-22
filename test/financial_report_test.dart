import 'dart:io';

import 'package:darjar/features/reports/domain/financial_report.dart';
import 'package:darjar/features/reports/presentation/financial_report_document.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ResidenceTransaction transaction(
  num amount,
  DateTime date, {
  ResidenceTransactionType type = ResidenceTransactionType.income,
  ResidenceTransactionSource source = ResidenceTransactionSource.manual,
  ResidenceExpenseCategory? category,
}) => ResidenceTransaction(
  id: '$date-$amount',
  type: type,
  amount: amount,
  date: date,
  name: '',
  source: source,
  expenseCategory: category,
);

ResidenceDue due(String id, String period, int amount) => ResidenceDue(
  id: id,
  apartmentId: 'a',
  apartmentNumber: '1',
  periodKey: period,
  amountDue: amount,
  amountPaid: amount,
  status: ResidenceDueStatus.paid,
);
ResidenceDuePayment payment(String id, int amount, DateTime paidAt) =>
    ResidenceDuePayment(
      id: '$id-$paidAt',
      dueId: id,
      apartmentId: 'a',
      apartmentNumber: '1',
      amount: amount,
      paidAt: paidAt,
      note: '',
      recordedBy: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  test(
    'inclusive cash dates, cents, and separately introduced initial balance',
    () {
      final report = FinancialReport(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
        dues: ResidenceDuesOverview.empty,
        transactions: [
          transaction(10, DateTime(2025, 12, 31)),
          transaction(
            100,
            DateTime(2026, 1, 1),
            source: ResidenceTransactionSource.openingBalance,
          ),
          transaction(0.1, DateTime(2026, 1, 1)),
          transaction(0.2, DateTime(2026, 1, 31, 23, 59, 59)),
          transaction(
            5.25,
            DateTime(2026, 1, 15),
            type: ResidenceTransactionType.expense,
          ),
          transaction(999, DateTime(2026, 2, 1)),
        ],
      );
      expect(report.openingCents, 1000);
      expect(report.introducedBalanceCents, 10000);
      expect(report.incomeCents, 30);
      expect(report.expenseCents, 525);
      expect(report.closingCents, 10505);
      expect(report.expenseCategories[ResidenceExpenseCategory.custom], 525);
    },
  );

  test(
    'historical collections ignore later payments and include earlier prepayments',
    () {
      final report = FinancialReport(
        from: DateTime(2026, 1, 15),
        to: DateTime(2026, 1, 31),
        transactions: [],
        dues: ResidenceDuesOverview(
          dues: [
            due('old', '2025-12', 200),
            due('jan', '2026-01', 300),
            due('future', '2026-02', 400),
          ],
          payments: [
            payment('old', 50, DateTime(2026, 1, 2)),
            payment('jan', 100, DateTime(2025, 12, 20)),
            payment('jan', 200, DateTime(2026, 2, 2)),
          ],
        ),
      );
      expect(report.expectedCents, 30000);
      expect(report.collectedCents, 10000);
      expect(report.unpaidCents, 20000);
      expect(report.arrearsCents, 35000);
      expect(report.collectionRate, closeTo(1 / 3, 0.001));
    },
  );

  test('empty period has no invented collection rate; invalid dates fail', () {
    final report = FinancialReport(
      from: DateTime(2026),
      to: DateTime(2026),
      transactions: [],
      dues: ResidenceDuesOverview.empty,
    );
    expect(report.closingCents, 0);
    expect(report.collectionRate, isNull);
    expect(report.hasOpeningBalance, isFalse);
    expect(
      () => FinancialReport(
        from: DateTime(2026, 2),
        to: DateTime(2026),
        transactions: [],
        dues: ResidenceDuesOverview.empty,
      ),
      throwsArgumentError,
    );
  });

  for (final locale in ['ar', 'en']) {
    for (final scenario in ['normal', 'empty', 'stress']) {
      test('one-page PDF: $locale $scenario', () async {
        final scale = scenario == 'stress' ? 100000 : 1;
        final report = FinancialReport(
          from: DateTime(2026, 1),
          to: DateTime(2026, 6, 30),
          transactions: scenario == 'empty'
              ? []
              : [
                  transaction(
                    12450 * scale,
                    DateTime(2025, 12, 31),
                    source: ResidenceTransactionSource.openingBalance,
                  ),
                  if (scenario == 'stress')
                    transaction(
                      100,
                      DateTime(2026, 3),
                      source: ResidenceTransactionSource.openingBalance,
                    ),
                  transaction(
                    28000 * scale,
                    DateTime(2026, 3),
                    source: ResidenceTransactionSource.dues,
                  ),
                  transaction(600 * scale, DateTime(2026, 3)),
                  for (final entry in {
                    ResidenceExpenseCategory.cleaning: 8200,
                    ResidenceExpenseCategory.security: 6000,
                    ResidenceExpenseCategory.utilities: 3150,
                    ResidenceExpenseCategory.maintenance: 2800,
                    ResidenceExpenseCategory.custom: 1200,
                  }.entries)
                    transaction(
                      entry.value * scale,
                      DateTime(2026, 4),
                      type: ResidenceTransactionType.expense,
                      category: entry.key,
                    ),
                ],
          dues: scenario == 'empty'
              ? ResidenceDuesOverview.empty
              : ResidenceDuesOverview(
                  dues: [
                    due('jan', '2026-01', 32000 * scale),
                    due('old', '2025-12', 3200 * scale),
                  ],
                  payments: [payment('jan', 28000 * scale, DateTime(2026, 3))],
                ),
        );
        final bytes = await buildFinancialReportPdf(
          report: report,
          residenceName: scenario == 'stress'
              ? 'إقامة الحدائق الجميلة والسكن المشترك بمدينة الدار البيضاء - العمارة الأولى'
              : 'النخيل',
          residenceAddress: 'شارع الحسن الثاني',
          residenceCity: '6141010',
          localeName: locale,
          generatedAt: DateTime(2026, 9, 22),
        );
        final raw = String.fromCharCodes(bytes);
        expect(raw.startsWith('%PDF'), isTrue);
        expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, 1);
        const previewDir = String.fromEnvironment('REPORT_PREVIEW_DIR');
        if (previewDir.isNotEmpty) {
          final file = File(
            '$previewDir/financial-report-$locale-$scenario.pdf',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        }
      });
    }
  }
}
