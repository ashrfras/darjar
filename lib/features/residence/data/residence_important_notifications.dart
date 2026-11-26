import 'package:darjar/features/residence/data/residence_dues_repository.dart';

enum ImportantResidenceNotificationKind {
  paymentRecorded,
  overdueDues,
  membershipApproved,
  residenceCreated,
}

class ImportantResidenceNotification {
  const ImportantResidenceNotification({
    required this.id,
    required this.kind,
    this.periodKey,
    this.amount,
    this.occurredAt,
  });

  final String id;
  final ImportantResidenceNotificationKind kind;
  final String? periodKey;
  final int? amount;
  final DateTime? occurredAt;
}

List<ImportantResidenceNotification> deriveImportantResidenceNotifications({
  required ResidenceDuesOverview duesOverview,
  required DateTime? joinedAt,
  bool joinedAtCreation = false,
  DateTime? now,
}) {
  final currentPeriodKey = residenceDuesPeriodKey(now ?? DateTime.now());
  final notifications = <ImportantResidenceNotification>[
    ImportantResidenceNotification(
      id: joinedAtCreation ? 'residence-created' : 'membership-approved',
      kind: joinedAtCreation
          ? ImportantResidenceNotificationKind.residenceCreated
          : ImportantResidenceNotificationKind.membershipApproved,
      occurredAt: joinedAt,
    ),
    for (final group in duesOverview.paymentGroups)
      ImportantResidenceNotification(
        id: 'payment-recorded-${group.id}',
        kind: ImportantResidenceNotificationKind.paymentRecorded,
        amount: group.totalAmount,
        occurredAt: group.paidAt,
      ),
  ];

  for (final due in duesOverview.dues) {
    if (due.status != ResidenceDueStatus.paid &&
        due.periodKey.compareTo(currentPeriodKey) < 0 &&
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
