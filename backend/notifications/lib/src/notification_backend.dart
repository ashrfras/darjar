class BackendDocument {
  const BackendDocument({
    required this.id,
    required this.path,
    required this.data,
  });

  final String id;
  final String path;
  final Map<String, Object?> data;
}

class NotificationPayload {
  const NotificationPayload({
    required this.id,
    required this.type,
    required this.residenceId,
    required this.recipientUserId,
    required this.targetId,
    required this.title,
    required this.body,
    required this.occurredAt,
    this.actorName = '',
    this.periodKey = '',
  });

  final String id;
  final String type;
  final String residenceId;
  final String recipientUserId;
  final String targetId;
  final String title;
  final String body;
  final DateTime occurredAt;
  final String actorName;
  final String periodKey;

  Map<String, String> get pushData => {
    'notificationId': id,
    'type': type,
    'residenceId': residenceId,
    'recipientUserId': recipientUserId,
    'targetId': targetId,
    'actorName': actorName,
    'periodKey': periodKey,
  };
}

abstract interface class NotificationBackend {
  Future<BackendDocument?> getDocument(String path);

  Future<List<BackendDocument>> listDocuments(String collectionPath);

  /// Returns false when this idempotent notification already exists.
  Future<bool> createNotification(NotificationPayload notification);

  Future<void> sendPush({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  });

  Future<void> deleteDocument(String path);
}
