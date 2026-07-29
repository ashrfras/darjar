import 'package:darjar/features/residence/data/residence_dues_repository.dart';

enum ImportantResidenceNotificationKind {
  paymentRecorded,
  overdueDues,
  membershipApproved,
}

class ImportantResidenceNotification {
  const ImportantResidenceNotification({
    required this.id,
    required this.kind,
    this.periodKey,
    this.occurredAt,
  });

  final String id;
  final ImportantResidenceNotificationKind kind;
  final String? periodKey;
  final DateTime? occurredAt;
}

List<ImportantResidenceNotification> deriveImportantResidenceNotifications({
  required ResidenceDuesOverview duesOverview,
  required DateTime? joinedAt,
  DateTime? now,
}) {
  final currentPeriodKey = residenceDuesPeriodKey(now ?? DateTime.now());
  final notifications = <ImportantResidenceNotification>[
    ImportantResidenceNotification(
      id: 'membership-approved',
      kind: ImportantResidenceNotificationKind.membershipApproved,
      occurredAt: joinedAt,
    ),
  ];

  for (final due in duesOverview.dues) {
    if (due.status == ResidenceDueStatus.paid) {
      final matchingPayments =
          duesOverview.payments
              .where((payment) => payment.dueId == due.id)
              .toList()
            ..sort((first, second) => second.paidAt.compareTo(first.paidAt));
      notifications.add(
        ImportantResidenceNotification(
          id: 'payment-recorded-${due.id}',
          kind: ImportantResidenceNotificationKind.paymentRecorded,
          periodKey: due.periodKey,
          occurredAt: matchingPayments.firstOrNull?.paidAt,
        ),
      );
      continue;
    }

    if (due.periodKey.compareTo(currentPeriodKey) < 0 &&
        due.remainingAmount > 0) {
      notifications.add(
        ImportantResidenceNotification(
          id: 'overdue-dues-${due.id}',
          kind: ImportantResidenceNotificationKind.overdueDues,
          periodKey: due.periodKey,
          occurredAt: _overdueAt(due.periodKey),
        ),
      );
    }
  }

  notifications.sort((first, second) {
    final firstDate = first.occurredAt;
    final secondDate = second.occurredAt;
    if (firstDate == null && secondDate == null) {
      return first.id.compareTo(second.id);
    }
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    final dateComparison = secondDate.compareTo(firstDate);
    return dateComparison != 0 ? dateComparison : first.id.compareTo(second.id);
  });

  return notifications.take(3).toList(growable: false);
}

DateTime _overdueAt(String periodKey) {
  final parts = periodKey.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1);
}
