import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'firestore_event_data.dart';
import 'google_cloud_backend.dart';
import 'notification_backend.dart';

class ActivityLogEvent {
  const ActivityLogEvent({
    required this.type,
    required this.occurredAt,
    this.userId,
    this.residenceId,
  });

  final String type;
  final DateTime occurredAt;
  final String? userId;
  final String? residenceId;

  bool get isFirstPost => type == 'firstPostPublished';

  String get id => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            type,
            userId,
            residenceId,
            if (!isFirstPost) occurredAt.toUtc().toIso8601String(),
          ]),
        ),
      )
      .toString();

  Map<String, Object?> get fields => {
    'type': type,
    'occurredAt': occurredAt,
    if (userId != null) 'userId': userId,
    if (residenceId != null) 'residenceId': residenceId,
  };
}

Iterable<ActivityLogEvent> activityEvents({
  required String documentPath,
  required FirestoreDocumentChange change,
  required DateTime observedAt,
  bool historical = false,
}) sync* {
  final path = documentPath.split('/');
  final before = change.oldValue;
  final after = change.value;
  final isCreation = historical || (before.isEmpty && after.isNotEmpty);
  final isDeletion = before.isNotEmpty && after.isEmpty;
  final createdAt = after['createdAt'];
  final creationTime = createdAt is DateTime ? createdAt : observedAt;

  if (path case ['documents', 'users', final userId]) {
    if (isCreation) {
      yield ActivityLogEvent(
        type: 'accountCreated',
        userId: userId,
        occurredAt: creationTime,
      );
    }
    final requestedAt = after['deletionRequestedAt'];
    if (before['accountStatus'] != 'deletionRequested' &&
        after['accountStatus'] == 'deletionRequested' &&
        requestedAt is DateTime) {
      yield ActivityLogEvent(
        type: 'accountDeletionRequested',
        userId: userId,
        occurredAt: requestedAt,
      );
    }
    if (isDeletion) {
      yield ActivityLogEvent(
        type: 'accountDeleted',
        userId: userId,
        occurredAt: observedAt,
      );
    }
  } else if (path case ['documents', 'residences', final residenceId]) {
    if (isCreation || isDeletion) {
      yield ActivityLogEvent(
        type: isCreation ? 'residenceCreated' : 'residenceDeleted',
        residenceId: residenceId,
        occurredAt: isCreation ? creationTime : observedAt,
      );
    }
  } else if (path case [
    'documents',
    'residences',
    final residenceId,
    'members',
    final userId,
  ]) {
    final joinedAt = after['joinedAt'];
    final joined = historical
        ? joinedAt is DateTime
        : before['status'] != 'active' && after['status'] == 'active';
    if (joined) {
      yield ActivityLogEvent(
        type: 'residentJoined',
        userId: userId,
        residenceId: residenceId,
        occurredAt: (historical || isCreation) && joinedAt is DateTime
            ? joinedAt
            : observedAt,
      );
    }
  } else if (path case [
    'documents',
    'residences',
    final residenceId,
    'communityPosts',
    _,
  ]) {
    if (isCreation) {
      yield ActivityLogEvent(
        type: 'firstPostPublished',
        residenceId: residenceId,
        occurredAt: creationTime,
      );
    }
  }
}

class ActivityLogWriter {
  ActivityLogWriter(this._backend);

  final GoogleCloudNotificationBackend _backend;

  Future<void> record({
    required String documentPath,
    required FirestoreDocumentChange change,
    required DateTime observedAt,
  }) async {
    for (final event in activityEvents(
      documentPath: documentPath,
      change: change,
      observedAt: observedAt,
    )) {
      await _save(event);
    }
  }

  Future<int> backfill() async {
    var processed = 0;
    Future<void> recordDocument(BackendDocument document) async {
      final createdAt = document.createTime;
      if (createdAt == null) {
        throw StateError('Missing Firestore document creation timestamp.');
      }
      for (final event in activityEvents(
        documentPath: 'documents/${document.path}',
        change: FirestoreDocumentChange(
          value: document.data,
          oldValue: const {},
        ),
        observedAt: createdAt,
        historical: true,
      )) {
        await _save(event);
        processed++;
      }
    }

    await for (final user in _backend.scanDocuments('users', [
      'createdAt',
      'accountStatus',
      'deletionRequestedAt',
    ])) {
      await recordDocument(user);
    }
    await for (final residence in _backend.scanDocuments('residences', [
      'createdAt',
    ])) {
      await recordDocument(residence);
      await for (final member in _backend.scanDocuments(
        '${residence.path}/members',
        ['joinedAt'],
      )) {
        if (member.data['joinedAt'] is DateTime) await recordDocument(member);
      }
      final firstPost = await _backend.earliestActivityPost(residence.path);
      if (firstPost != null) await recordDocument(firstPost);
    }
    return processed;
  }

  Future<void> _save(ActivityLogEvent event) => _backend.saveActivityEvent(
    id: event.id,
    fields: event.fields,
    keepEarliest: event.isFirstPost,
  );
}
