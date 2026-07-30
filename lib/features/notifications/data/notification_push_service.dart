import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/notifications/data/notifications_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _webPushVapidKey = String.fromEnvironment('DARJAR_WEB_PUSH_VAPID_KEY');

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification payloads are displayed by the operating system. The matching
  // in-app notification is supplied by the trusted sender through Firestore.
}

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final notificationPushEnabledProvider = Provider<bool>((ref) => true);

final notificationPushServiceProvider = Provider<NotificationPushService>((
  ref,
) {
  final service = NotificationPushService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(firebaseFirestoreProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final notificationPushRegistrationProvider = FutureProvider<void>((ref) async {
  if (!ref.watch(notificationPushEnabledProvider)) return;
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return;
  final context = await ref.watch(residenceContextProvider.future);
  final residenceIds = context.residences
      .map((residence) => residence.id)
      .toList(growable: false);
  await ref
      .watch(notificationPushServiceProvider)
      .initialize(
        userId: user.uid,
        residenceIds: residenceIds,
        onOpened: (notification) {
          unawaited(
            ref
                .read(notificationActionsProvider)
                .markRead(notification.id)
                .onError((_, _) {}),
          );
          final route = notificationRoute(notification);
          ref.read(appRouterProvider).go(route);
        },
      );
});

class NotificationPushService {
  NotificationPushService(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _userId;
  List<String> _residenceIds = const [];

  Future<void> initialize({
    required String userId,
    required List<String> residenceIds,
    required ValueChanged<DarJarNotification> onOpened,
  }) async {
    if (_userId == userId) return;
    _userId = userId;
    _residenceIds = residenceIds;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb || _webPushVapidKey.isNotEmpty) {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webPushVapidKey : null,
      );
      if (token != null) await _storeToken(token);
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(_storeToken);

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      // The trusted sender also writes the durable in-app notification.
      _fromRemoteMessage(message);
    });

    await _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      final notification = _fromRemoteMessage(message);
      if (notification == null) return;
      onOpened(notification);
    });

    final initialMessage = await _messaging.getInitialMessage();
    final initialNotification = initialMessage == null
        ? null
        : _fromRemoteMessage(initialMessage);
    if (initialNotification != null) {
      onOpened(initialNotification);
    }
  }

  Future<void> _storeToken(String token) {
    final userId = _userId;
    if (userId == null) return Future.value();
    final tokenDocumentId = token.replaceAll('/', '_');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pushTokens')
        .doc(tokenDocumentId)
        .set({
          'token': token,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'residenceIds': _residenceIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  DarJarNotification? _fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final typeName = data['type'];
    final type = DarJarNotificationType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    final residenceId = data['residenceId'];
    final recipientUserId = data['recipientUserId'] ?? _userId;
    if (type == null ||
        residenceId == null ||
        residenceId.isEmpty ||
        recipientUserId == null) {
      return null;
    }
    return DarJarNotification(
      id:
          data['notificationId'] ??
          message.messageId ??
          '${type.name}-${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
      residenceId: residenceId,
      recipientUserId: recipientUserId,
      type: type,
      occurredAt: message.sentTime ?? DateTime.now(),
      targetId: data['targetId'] ?? '',
      actorName: type == DarJarNotificationType.postCreated
          ? abbreviatedPersonName(data['actorName'] ?? '')
          : data['actorName'] ?? '',
      periodKey: data['periodKey'] ?? '',
    );
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
  }
}

String notificationRoute(DarJarNotification notification) {
  return switch (notification.type) {
    DarJarNotificationType.postCreated when notification.targetId.isNotEmpty =>
      AppRoutes.communityPost(notification.targetId),
    DarJarNotificationType.postCreated => AppRoutes.community,
    DarJarNotificationType.duesOverdue => AppRoutes.dues,
    DarJarNotificationType.budgetChanged => AppRoutes.residenceFinances,
  };
}
