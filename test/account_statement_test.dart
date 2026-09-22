import 'dart:io';

import 'package:darjar/features/reports/domain/account_statement.dart';
import 'package:darjar/features/reports/presentation/account_statement_document.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ResidenceTransaction movement(
  String id,
  DateTime date,
  num amount, {
  bool expense = false,
  bool opening = false,
}) => ResidenceTransaction(
  id: id,
  date: date,
  amount: amount,
  name: expense
      ? 'صيانة المصعد والإنارة المشتركة'
      : 'مداخيل كراء مرافق الإقامة',
  type: expense
      ? ResidenceTransactionType.expense
      : ResidenceTransactionType.income,
  source: opening
      ? ResidenceTransactionSource.openingBalance
      : ResidenceTransactionSource.manual,
);

ResidenceTransaction categorizedExpense(
  String name,
  ResidenceExpenseCategory category,
) => ResidenceTransaction(
  id: '$category-$name',
  date: DateTime(2026),
  amount: 100,
  name: name,
  type: ResidenceTransactionType.expense,
  source: ResidenceTransactionSource.manual,
  expenseCategory: category,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });
  test(
    'expense descriptions use the display language and retain custom names',
    () {
      const arabic = FinancialReportCopy(true, statement: true);
      const english = FinancialReportCopy(false, statement: true);
      final cleaning = categorizedExpense(
        'cleaning',
        ResidenceExpenseCategory.cleaning,
      );
      final custom = categorizedExpense(
        'إصلاح باب المرآب',
        ResidenceExpenseCategory.custom,
      );

      expect(accountStatementDescription(arabic, cleaning), 'النظافة');
      expect(accountStatementDescription(english, cleaning), 'Cleaning');
      expect(
        accountStatementDescription(arabic, custom),
        'مصاريف أخرى\nإصلاح باب المرآب',
      );
      expect(
        accountStatementDescription(english, custom),
        'Other expenses\nإصلاح باب المرآب',
      );
    },
  );
  test(
    'inclusive range, newest-first entries, running balances, and initial balance accounting',
    () {
      final transactions = [
        movement('last', DateTime(2026, 1, 31, 23, 59, 59), 0.2),
        movement('outside', DateTime(2026, 2, 1), 999),
        movement('expense', DateTime(2026, 1, 10), 5.25, expense: true),
        movement('before', DateTime(2025, 12, 31), 10),
        movement('initial', DateTime(2026, 1, 1), 100, opening: true),
        movement('first', DateTime(2026, 1, 2), 0.1),
      ];
      final statement = AccountStatement(
        from: DateTime(2026, 1, 1, 12),
        to: DateTime(2026, 1, 31),
        transactions: transactions,
      );
      expect(statement.entries.map((e) => e.transaction.id), [
        'last',
        'expense',
        'first',
        'initial',
      ]);
      expect(statement.entries.map((e) => e.balanceCents), [
        10505,
        10485,
        11010,
        11000,
      ]);
      expect(statement.summary.incomeCents, 30);
      expect(statement.summary.expenseCents, 525);
      expect(statement.summary.introducedBalanceCents, 10000);
      expect(
        statement.summary.closingCents,
        statement.entries.first.balanceCents,
      );
      expect(transactions.first.id, 'last');
    },
  );
  test('empty period retains earlier balance and invalid periods fail', () {
    final statement = AccountStatement(
      from: DateTime(2026, 1),
      to: DateTime(2026, 1, 31),
      transactions: [movement('old', DateTime(2025), 25)],
    );
    expect(statement.entries, isEmpty);
    expect(statement.summary.closingCents, 2500);
    expect(
      () => AccountStatement(
        from: DateTime(2026, 2),
        to: DateTime(2026, 1),
        transactions: [],
      ),
      throwsArgumentError,
    );
  });
  test('statement dates use a fixed numeric day-month-year format', () {
    expect(accountStatementDate(DateTime(2025, 9, 1)), '01/09/2025');
    expect(accountStatementDate(DateTime(2026, 12, 31)), '31/12/2026');
  });
  for (final locale in ['ar', 'en']) {
    for (final count in [0, 3, 100]) {
      test('PDF $locale with $count entries paginates', () async {
        final statement = AccountStatement(
          from: DateTime(2026, 1),
          to: DateTime(2026, 6, 30),
          transactions: [
            movement('opening', DateTime(2025), 15000, opening: true),
            for (var i = 0; i < count; i++)
              movement(
                't$i',
                DateTime(2026, 1, 1).add(Duration(days: i)),
                120.25,
                expense: i.isOdd,
              ),
          ],
        );
        final bytes = await buildAccountStatementPdf(
          statement: statement,
          residenceName: 'النخيل',
          residenceAddress: 'شارع الحسن الثاني',
          residenceCity: '6141010',
          localeName: locale,
          generatedAt: DateTime(2026, 9, 22),
        );
        final raw = String.fromCharCodes(bytes);
        expect(raw.startsWith('%PDF'), isTrue);
        final pages = RegExp(r'/Type\s*/Page\b').allMatches(raw).length;
        expect(pages, count == 100 ? greaterThan(1) : equals(1));
        const previewDir = String.fromEnvironment('REPORT_PREVIEW_DIR');
        if (previewDir.isNotEmpty) {
          final file = File('$previewDir/account-statement-$locale-$count.pdf');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        }
      });
    }
  }
}
