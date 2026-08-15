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

class FeedActivityPayload {
  const FeedActivityPayload({
    required this.id,
    required this.residenceId,
    required this.type,
    required this.category,
    required this.referenceType,
    required this.referenceId,
    required this.occurredAt,
    required this.payload,
    this.actorId = '',
    this.actorName = '',
  });

  final String id;
  final String residenceId;
  final String type;
  final String category;
  final String actorId;
  final String actorName;
  final String referenceType;
  final String referenceId;
  final DateTime occurredAt;
  final Map<String, Object?> payload;
}

abstract interface class NotificationBackend {
  Future<BackendDocument?> getDocument(String path);

  Future<List<BackendDocument>> listDocuments(String collectionPath);

  /// Returns false when this idempotent notification already exists.
  Future<bool> createNotification(NotificationPayload notification);

  /// Returns false when this idempotent activity already exists.
  Future<bool> createFeedActivity(FeedActivityPayload activity);

  Future<void> sendPush({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  });

  Future<void> deleteDocument(String path);
}
