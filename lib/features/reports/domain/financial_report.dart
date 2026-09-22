import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';

/// Cash movements use payment dates. Monthly dues use their recorded month;
/// collections and arrears are reconstructed as at the inclusive end date.
class FinancialReport {
  FinancialReport({
    required DateTime from,
    required DateTime to,
    required List<ResidenceTransaction> transactions,
    required ResidenceDuesOverview dues,
  }) : from = DateTime(from.year, from.month, from.day),
       to = DateTime(to.year, to.month, to.day) {
    if (this.to.isBefore(this.from)) throw ArgumentError('Invalid date range');
    final end = DateTime(to.year, to.month, to.day + 1);
    for (final transaction in transactions) {
      if (!transaction.date.isBefore(end)) continue;
      final cents = (transaction.amount * 100).round();
      final signed = transaction.type == ResidenceTransactionType.expense
          ? -cents
          : cents;
      if (transaction.date.isBefore(this.from)) {
        openingCents += signed;
      } else if (transaction.isOpeningBalance) {
        introducedBalanceCents += signed;
      } else if (transaction.type == ResidenceTransactionType.expense) {
        expenseCents += cents;
        final category =
            transaction.expenseCategory ?? ResidenceExpenseCategory.custom;
        expenseCategories.update(
          category,
          (value) => value + cents,
          ifAbsent: () => cents,
        );
        transactionCount++;
      } else {
        incomeCents += cents;
        if (transaction.source == ResidenceTransactionSource.dues) {
          duesIncomeCents += cents;
        } else {
          otherIncomeCents += cents;
        }
        transactionCount++;
      }
    }
    final paidByDue = <String, int>{};
    for (final payment in dues.payments) {
      if (payment.paidAt.isBefore(end)) {
        paidByDue.update(
          payment.dueId,
          (value) => value + payment.amount * 100,
          ifAbsent: () => payment.amount * 100,
        );
      }
    }
    final firstMonth = residenceDuesPeriodKey(this.from);
    final lastMonth = residenceDuesPeriodKey(this.to);
    for (final due in dues.dues) {
      if (due.periodKey.compareTo(lastMonth) > 0) continue;
      final dueCents = due.amountDue * 100;
      final paid = (paidByDue[due.id] ?? 0).clamp(0, dueCents);
      arrearsCents += dueCents - paid;
      if (due.periodKey.compareTo(firstMonth) >= 0) {
        expectedCents += dueCents;
        collectedCents += paid;
      }
    }
    hasOpeningBalance = transactions.any(
      (t) => t.isOpeningBalance && t.date.isBefore(end),
    );
  }

  final DateTime from;
  final DateTime to;
  int openingCents = 0;
  int introducedBalanceCents = 0;
  int incomeCents = 0;
  int expenseCents = 0;
  int duesIncomeCents = 0;
  int otherIncomeCents = 0;
  int expectedCents = 0;
  int collectedCents = 0;
  int arrearsCents = 0;
  int transactionCount = 0;
  bool hasOpeningBalance = false;
  final expenseCategories = <ResidenceExpenseCategory, int>{};
  int get closingCents =>
      openingCents + introducedBalanceCents + incomeCents - expenseCents;
  int get netCents => incomeCents - expenseCents;
  int get unpaidCents => expectedCents - collectedCents;
  double? get collectionRate =>
      expectedCents == 0 ? null : collectedCents / expectedCents;
}
