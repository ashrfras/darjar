import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_important_notifications.dart';
import 'package:darjar/features/reports/domain/financial_report.dart';
import 'package:flutter_test/flutter_test.dart';

ResidenceDue due(
  String period, {
  String apartment = 'a',
  ResidenceDueStatus status = ResidenceDueStatus.unpaid,
  int paid = 0,
}) => ResidenceDue(
  id: '${period}_$apartment',
  apartmentId: apartment,
  apartmentNumber: apartment,
  periodKey: period,
  amountDue: 150,
  amountPaid: paid,
  status: status,
);

void main() {
  test(
    'exempts oldest unpaid months, excluding other apartments, partial and paid months',
    () {
      final dues = [
        due('2026-05'),
        due('2026-01', status: ResidenceDueStatus.paid, paid: 150),
        due('2026-02', status: ResidenceDueStatus.partial, paid: 50),
        due('2026-04'),
        due('2026-03'),
        due('2025-01', apartment: 'b'),
        due('2025-02', status: ResidenceDueStatus.exempt),
      ];
      expect(
        selectDuesForExemption(
          dues,
          apartmentId: 'a',
          monthCount: 2,
        ).map((due) => due.periodKey),
        ['2026-03', '2026-04'],
      );
      expect(selectDuesForExemption(dues, apartmentId: 'a').length, 3);
      for (final count in [0, -1, 4]) {
        expect(
          () =>
              selectDuesForExemption(dues, apartmentId: 'a', monthCount: count),
          throwsA(isA<ResidenceDuesFailure>()),
        );
      }
      expect(
        () => selectDuesForExemption([], apartmentId: 'a'),
        throwsA(isA<ResidenceDuesFailure>()),
      );
    },
  );

  test(
    'exempt dues disappear from expectations, arrears, report rates and overdue notices without income',
    () {
      final exempt = due('2026-01').copyWithExemption();
      final overview = ResidenceDuesOverview(
        dues: [
          exempt,
          due('2026-02'),
          due(
            '2026-01',
            apartment: 'b',
            status: ResidenceDueStatus.paid,
            paid: 150,
          ),
        ],
        payments: [
          ResidenceDuePayment(
            id: 'p',
            dueId: '2026-01_b',
            apartmentId: 'b',
            apartmentNumber: 'b',
            amount: 150,
            paidAt: DateTime(2026, 1, 20),
            note: '',
            recordedBy: 'manager',
          ),
        ],
      );
      expect(exempt.amountDue, 150);
      expect(exempt.remainingAmount, 0);
      expect(exempt.amountPaid, 0);
      expect(overview.expectedForPeriod('2026-01'), 150);
      expect(overview.collectedForPeriod('2026-01'), 150);
      expect(overview.debitThroughPeriod('2026-02'), 150);
      expect(overview.creditAfterPeriod('2025-12'), 150);
      final report = FinancialReport(
        from: DateTime(2026, 1),
        to: DateTime(2026, 1, 31),
        dues: overview,
        transactions: [],
      );
      expect(report.expectedCents, 15000);
      expect(report.collectedCents, 15000);
      expect(report.arrearsCents, 0);
      expect(report.collectionRate, 1);
      expect(report.incomeCents, 0);
      final notifications = deriveImportantResidenceNotifications(
        duesOverview: ResidenceDuesOverview(dues: [exempt], payments: []),
        joinedAt: null,
        now: DateTime(2026, 9),
      );
      expect(
        notifications.where(
          (item) =>
              item.kind !=
              ImportantResidenceNotificationKind.membershipApproved,
        ),
        isEmpty,
      );
    },
  );
}
