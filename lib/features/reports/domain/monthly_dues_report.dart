import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';

enum MonthlyDuesStatus {
  paid,
  unpaid,
  partial,
  exempt,
  notRecorded,
  notStarted,
  future,
}

class MonthlyDuesCell {
  const MonthlyDuesCell(this.period, this.status, {this.remaining = 0});
  final String period;
  final MonthlyDuesStatus status;
  final int remaining;
}

class MonthlyDuesRow {
  const MonthlyDuesRow(this.apartment, this.months, this.prior);
  final ResidenceApartment apartment;
  final List<MonthlyDuesCell> months;
  final List<MonthlyDuesCell> prior;
  Iterable<MonthlyDuesCell> get outstanding => [...prior, ...months].where(
    (cell) =>
        cell.status == MonthlyDuesStatus.unpaid ||
        cell.status == MonthlyDuesStatus.partial,
  );
  int get unpaidCount => outstanding
      .where((cell) => cell.status == MonthlyDuesStatus.unpaid)
      .length;
  int get partialCount => outstanding
      .where((cell) => cell.status == MonthlyDuesStatus.partial)
      .length;
  int get remaining => outstanding.fold(0, (sum, cell) => sum + cell.remaining);
}

/// Current payment status for the selected year's months and earlier arrears.
/// Missing records are never inferred to be unpaid; future months are not debt.
class MonthlyDuesReport {
  MonthlyDuesReport({
    required this.year,
    required this.asOf,
    required List<ResidenceApartment> apartments,
    required ResidenceDuesOverview dues,
  }) {
    if (year < 1900 || year > asOf.year) {
      throw ArgumentError('Invalid report year');
    }
    final currentPeriod = residenceDuesPeriodKey(asOf);
    final paid = <String, int>{};
    for (final payment in dues.payments) {
      if (!payment.paidAt.isAfter(asOf)) {
        paid.update(
          payment.dueId,
          (value) => value + payment.amount,
          ifAbsent: () => payment.amount,
        );
      }
    }
    final records = <String, Map<String, List<ResidenceDue>>>{};
    for (final due in dues.dues) {
      records
          .putIfAbsent(due.apartmentId, () => {})
          .putIfAbsent(due.periodKey, () => [])
          .add(due);
    }
    MonthlyDuesCell recorded(String period, List<ResidenceDue> entries) {
      final chargeable = entries.where((due) => !due.isExempt);
      final expected = chargeable.fold(0, (sum, due) => sum + due.amountDue);
      final collected = chargeable.fold(
        0,
        (sum, due) => sum + (paid[due.id] ?? 0).clamp(0, due.amountDue),
      );
      final status = chargeable.isEmpty
          ? MonthlyDuesStatus.exempt
          : collected == expected
          ? MonthlyDuesStatus.paid
          : period.compareTo(currentPeriod) > 0
          ? MonthlyDuesStatus.future
          : collected > 0
          ? MonthlyDuesStatus.partial
          : MonthlyDuesStatus.unpaid;
      return MonthlyDuesCell(
        period,
        status,
        remaining: status == MonthlyDuesStatus.future
            ? 0
            : expected - collected,
      );
    }

    final sorted = [...apartments]
      ..sort((a, b) => compareResidenceApartmentNumbers(a.number, b.number));
    for (final apartment in sorted) {
      final byPeriod = records[apartment.id] ?? {};
      final months = <MonthlyDuesCell>[];
      for (var month = 1; month <= 12; month++) {
        final period = residenceDuesPeriodKey(DateTime(year, month));
        final entries = byPeriod[period];
        if (entries != null) {
          months.add(recorded(period, entries));
        } else {
          final paidBeforeTracking =
              apartment.openingPaidThroughPeriodKey.isNotEmpty &&
              period.compareTo(apartment.openingPaidThroughPeriodKey) <= 0;
          final notStarted =
              !apartment.isDuesTrackingActive ||
              (apartment.duesTrackingStartPeriodKey.isNotEmpty &&
                  period.compareTo(apartment.duesTrackingStartPeriodKey) < 0);
          months.add(
            MonthlyDuesCell(
              period,
              period.compareTo(currentPeriod) > 0
                  ? MonthlyDuesStatus.future
                  : paidBeforeTracking
                  ? MonthlyDuesStatus.paid
                  : notStarted
                  ? MonthlyDuesStatus.notStarted
                  : MonthlyDuesStatus.notRecorded,
            ),
          );
        }
      }
      final prior = <MonthlyDuesCell>[];
      for (final entry in byPeriod.entries) {
        if (entry.key.compareTo('$year-01') < 0) {
          final cell = recorded(entry.key, entry.value);
          if (cell.remaining > 0) prior.add(cell);
        }
      }
      prior.sort((a, b) => a.period.compareTo(b.period));
      rows.add(MonthlyDuesRow(apartment, months, prior));
    }
  }
  final int year;
  final DateTime asOf;
  final List<MonthlyDuesRow> rows = [];
  int get remaining => rows.fold(0, (sum, row) => sum + row.remaining);
}
