import 'package:darjar/features/reports/domain/financial_report.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';

class AccountStatementEntry {
  const AccountStatementEntry(this.transaction, this.balanceCents);
  final ResidenceTransaction transaction;
  final int balanceCents;
  int get amountCents => (transaction.amount * 100).round();
}

/// Uses the same cash accounting rules as the financial summary.
class AccountStatement {
  AccountStatement({
    required DateTime from,
    required DateTime to,
    required List<ResidenceTransaction> transactions,
  }) : summary = FinancialReport(
         from: from,
         to: to,
         transactions: transactions,
         dues: ResidenceDuesOverview.empty,
       ) {
    final end = DateTime(summary.to.year, summary.to.month, summary.to.day + 1);
    final ordered =
        transactions
            .where(
              (transaction) =>
                  !transaction.date.isBefore(summary.from) &&
                  transaction.date.isBefore(end),
            )
            .toList()
          ..sort((a, b) {
            final dateOrder = a.date.compareTo(b.date);
            return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
          });
    var balance = summary.openingCents;
    final chronologicalEntries = ordered.map((transaction) {
      final cents = (transaction.amount * 100).round();
      balance += transaction.type == ResidenceTransactionType.expense
          ? -cents
          : cents;
      return AccountStatementEntry(transaction, balance);
    }).toList();
    entries = List.unmodifiable(chronologicalEntries.reversed);
  }
  final FinancialReport summary;
  late final List<AccountStatementEntry> entries;
}
