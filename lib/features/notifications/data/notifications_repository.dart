import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DarJarNotificationType {
  residentJoined,
  postCreated,
  postLiked,
  postCommented,
  duesOverdue,
  duesMarkedPaid,
  budgetChanged,
}

class DarJarNotification {
  const DarJarNotification({
    required this.id,
    required this.residenceId,
    required this.recipientUserId,
    required this.type,
    required this.occurredAt,
    required this.targetId,
    this.actorName = '',
    this.periodKey = '',
    this.readAt,
  });

  final String id;
  final String residenceId;
  final String recipientUserId;
  final DarJarNotificationType type;
  final DateTime occurredAt;
  final String targetId;
  final String actorName;
  final String periodKey;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  DarJarNotification copyWithReadAt(DateTime value) {
    return DarJarNotification(
      id: id,
      residenceId: residenceId,
      recipientUserId: recipientUserId,
      type: type,
      occurredAt: occurredAt,
      targetId: targetId,
      actorName: actorName,
      periodKey: periodKey,
      readAt: value,
    );
  }
}

abstract interface class NotificationsRepository {
  Stream<List<DarJarNotification>> watch({
    required String residenceId,
    required String userId,
  });

  Future<void> markRead(String notificationId);

  Future<void> markAllRead({
    required String residenceId,
    required String userId,
  });
}

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository({List<DarJarNotification>? seed})
    : _notifications = [...?seed] {
    if (seed == null) {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1);
      _notifications.addAll([
        DarJarNotification(
          id: 'mock-post-created',
          residenceId: '*',
          recipientUserId: '*',
          type: DarJarNotificationType.postCreated,
          occurredAt: now.subtract(const Duration(minutes: 15)),
          targetId: 'darjar-welcome',
          actorName: 'محمد العلوي',
        ),
        DarJarNotification(
          id: 'mock-dues-overdue',
          residenceId: '*',
          recipientUserId: '*',
          type: DarJarNotificationType.duesOverdue,
          occurredAt: now.subtract(const Duration(hours: 2)),
          targetId: '',
          periodKey:
              '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}',
        ),
        DarJarNotification(
          id: 'mock-budget-changed',
          residenceId: '*',
          recipientUserId: '*',
          type: DarJarNotificationType.budgetChanged,
          occurredAt: now.subtract(const Duration(days: 1)),
          targetId: '',
          actorName: 'إدارة الإقامة',
        ),
      ]);
    }
  }

  final List<DarJarNotification> _notifications;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<DarJarNotification>> watch({
    required String residenceId,
    required String userId,
  }) async* {
    yield _visible(residenceId: residenceId, userId: userId);
    await for (final _ in _changes.stream) {
      yield _visible(residenceId: residenceId, userId: userId);
    }
  }

  Future<void> save(DarJarNotification notification) async {
    final index = _notifications.indexWhere(
      (current) => current.id == notification.id,
    );
    if (index == -1) {
      _notifications.add(notification);
    } else {
      _notifications[index] = notification;
    }
    _changes.add(null);
  }

  @override
  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWithReadAt(
      DateTime.now(),
    );
    _changes.add(null);
  }

  @override
  Future<void> markAllRead({
    required String residenceId,
    required String userId,
  }) async {
    final now = DateTime.now();
    for (var index = 0; index < _notifications.length; index++) {
      final notification = _notifications[index];
      if (_matches(notification, residenceId, userId) && !notification.isRead) {
        _notifications[index] = notification.copyWithReadAt(now);
      }
    }
    _changes.add(null);
  }

  List<DarJarNotification> _visible({
    required String residenceId,
    required String userId,
  }) {
    return [
      for (final notification in _notifications)
        if (_matches(notification, residenceId, userId)) notification,
    ]..sort((first, second) => second.occurredAt.compareTo(first.occurredAt));
  }

  bool _matches(
    DarJarNotification notification,
    String residenceId,
    String userId,
  ) {
    return (notification.residenceId == '*' ||
            notification.residenceId == residenceId) &&
        (notification.recipientUserId == '*' ||
            notification.recipientUserId == userId);
  }

  void dispose() => _changes.close();
}

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository(this._firestore, this._authRepository);

  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  @override
  Stream<List<DarJarNotification>> watch({
    required String residenceId,
    required String userId,
  }) {
    return _notifications(
      userId,
    ).where('residenceId', isEqualTo: residenceId).snapshots().map((snapshot) {
      final notifications = [
        for (final document in snapshot.docs) ?_fromDocument(document),
      ]..sort((first, second) => second.occurredAt.compareTo(first.occurredAt));
      return notifications;
    });
  }

  @override
  Future<void> markRead(String notificationId) async {
    final userId = _requiredUserId();
    await _notifications(
      userId,
    ).doc(notificationId).update({'readAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> markAllRead({
    required String residenceId,
    required String userId,
  }) async {
    final snapshot = await _notifications(
      userId,
    ).where('residenceId', isEqualTo: residenceId).get();
    final batch = _firestore.batch();
    var hasChanges = false;
    for (final document in snapshot.docs) {
      if (document.data()['readAt'] == null) {
        batch.update(document.reference, {
          'readAt': FieldValue.serverTimestamp(),
        });
        hasChanges = true;
      }
    }
    if (hasChanges) await batch.commit();
  }

  DarJarNotification? _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final typeName = data['type'] as String?;
    final type = DarJarNotificationType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    final residenceId = data['residenceId'] as String?;
    final recipientUserId = data['recipientUserId'] as String?;
    if (type == null || residenceId == null || recipientUserId == null) {
      return null;
    }
    return DarJarNotification(
      id: document.id,
      residenceId: residenceId,
      recipientUserId: recipientUserId,
      type: type,
      occurredAt:
          (data['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetId: data['targetId'] as String? ?? '',
      actorName: _usesAbbreviatedActorName(type)
          ? abbreviatedPersonName(data['actorName'] as String? ?? '')
          : data['actorName'] as String? ?? '',
      periodKey: data['periodKey'] as String? ?? '',
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  String _requiredUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw StateError('missing-authenticated-user');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _notifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }
}

bool _usesAbbreviatedActorName(DarJarNotificationType type) {
  return type == DarJarNotificationType.residentJoined ||
      type == DarJarNotificationType.postCreated ||
      type == DarJarNotificationType.postLiked ||
      type == DarJarNotificationType.postCommented;
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => FirestoreNotificationsRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(authRepositoryProvider),
  ),
);

final notificationsProvider =
    StreamProvider.autoDispose<List<DarJarNotification>>((ref) async* {
      final context = await ref.watch(residenceContextProvider.future);
      final residence = context.activeResidence;
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (residence == null || user == null) {
        yield const [];
        return;
      }
      yield* ref
          .watch(notificationsRepositoryProvider)
          .watch(residenceId: residence.id, userId: user.uid);
    });

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .value
          ?.where((notification) => !notification.isRead)
          .length ??
      0;
});

final notificationActionsProvider = Provider<NotificationActions>(
  NotificationActions.new,
);

class NotificationActions {
  NotificationActions(this._ref);

  final Ref _ref;

  Future<void> markRead(String notificationId) {
    return _ref.read(notificationsRepositoryProvider).markRead(notificationId);
  }

  Future<void> markAllRead() async {
    final context = await _ref.read(residenceContextProvider.future);
    final residence = context.activeResidence;
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (residence == null || user == null) return;
    await _ref
        .read(notificationsRepositoryProvider)
        .markAllRead(residenceId: residence.id, userId: user.uid);
  }
}
