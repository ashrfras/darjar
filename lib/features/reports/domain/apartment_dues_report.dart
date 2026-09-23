import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';

class ApartmentDuesReport {
  ApartmentDuesReport({
    required DateTime from,
    required DateTime to,
    required List<ResidenceApartment> apartments,
    required ResidenceDuesOverview dues,
  }) : from = DateTime(from.year, from.month, from.day),
       to = DateTime(to.year, to.month, to.day) {
    if (this.to.isBefore(this.from)) throw ArgumentError('Invalid date range');
    final end = DateTime(to.year, to.month, to.day + 1);
    final firstMonth = residenceDuesPeriodKey(from);
    final lastMonth = residenceDuesPeriodKey(to);
    final paidByDue = <String, int>{};
    for (final payment in dues.payments) {
      if (payment.paidAt.isBefore(end)) {
        paidByDue.update(
          payment.dueId,
          (sum) => sum + payment.amount,
          ifAbsent: () => payment.amount,
        );
      }
    }
    final byApartment = <String, List<ResidenceDue>>{};
    for (final due in dues.dues) {
      if (due.periodKey.compareTo(lastMonth) <= 0) {
        byApartment.putIfAbsent(due.apartmentId, () => []).add(due);
      }
    }
    final sorted = [...apartments]
      ..sort((a, b) => compareResidenceApartmentNumbers(a.number, b.number));
    for (final apartment in sorted) {
      final row = ApartmentDuesReportRow(apartment);
      for (final due in byApartment[apartment.id] ?? <ResidenceDue>[]) {
        final inPeriod = due.periodKey.compareTo(firstMonth) >= 0;
        if (inPeriod) row.recordedMonths++;
        if (due.isExempt) {
          if (inPeriod) row.exemptMonths++;
          continue;
        }
        final paid = (paidByDue[due.id] ?? 0).clamp(0, due.amountDue);
        if (inPeriod) {
          row.expected += due.amountDue;
          row.collected += paid;
        } else {
          row.previousUnpaid += due.amountDue - paid;
        }
      }
      rows.add(row);
    }
  }

  final DateTime from;
  final DateTime to;
  final List<ApartmentDuesReportRow> rows = [];
  int get expected => rows.fold(0, (sum, row) => sum + row.expected);
  int get collected => rows.fold(0, (sum, row) => sum + row.collected);
  int get unpaid => expected - collected;
  int get previousUnpaid =>
      rows.fold(0, (sum, row) => sum + row.previousUnpaid);
  int get totalUnpaid => previousUnpaid + unpaid;
}

class ApartmentDuesReportRow {
  ApartmentDuesReportRow(this.apartment);
  final ResidenceApartment apartment;
  int recordedMonths = 0;
  int exemptMonths = 0;
  int expected = 0;
  int collected = 0;
  int previousUnpaid = 0;
  int get unpaid => expected - collected;
  int get totalUnpaid => previousUnpaid + unpaid;
}
