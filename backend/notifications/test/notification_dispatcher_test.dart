import 'package:darjar_notifications/src/notification_backend.dart';
import 'package:darjar_notifications/src/notification_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  test('post notifications exclude the author and inactive members', () async {
    final backend = _FakeBackend()
      ..document('residences/home/communityPosts/post-1', {
        'authorId': 'author',
        'authorName': 'أمينة المريني',
      })
      ..collection('residences/home/members', [
        _document('author', {'status': 'active'}),
        _document('neighbor', {'status': 'active'}),
        _document('former', {'status': 'inactive'}),
      ])
      ..collection('users/neighbor/pushTokens', [
        _document('phone', {'token': 'neighbor-token'}),
      ]);
    final dispatcher = NotificationDispatcher(
      backend,
      now: () => DateTime.utc(2026, 7, 30, 12),
    );

    await dispatcher.postCreated(
      documentPath:
          'projects/raq-darjar/databases/(default)/documents/'
          'residences/home/communityPosts/post-1',
      eventId: 'event-1',
    );

    expect(backend.notifications, hasLength(1));
    expect(backend.notifications.single.recipientUserId, 'neighbor');
    expect(backend.notifications.single.type, 'postCreated');
    expect(backend.notifications.single.targetId, 'post-1');
    expect(backend.notifications.single.actorName, 'أمينة م.');
    expect(backend.notifications.single.body, 'أضاف أمينة م. منشورًا جديدًا.');
    expect(backend.pushes.single.token, 'neighbor-token');
  });

  test(
    'post notifications ignore the Arabic article in surname initials',
    () async {
      final backend = _FakeBackend()
        ..document('residences/home/communityPosts/post-1', {
          'authorId': 'author',
          'authorName': 'كريم المنيعي',
        })
        ..collection('residences/home/members', [
          _document('author', {'status': 'active'}),
          _document('neighbor', {'status': 'active'}),
        ]);
      final dispatcher = NotificationDispatcher(backend);

      await dispatcher.postCreated(
        documentPath: 'residences/home/communityPosts/post-1',
        eventId: 'event-1',
      );

      expect(backend.notifications.single.actorName, 'كريم م.');
    },
  );

  test('duplicate events do not send duplicate pushes', () async {
    final backend = _FakeBackend()
      ..document('residences/home/communityPosts/post-1', {
        'authorId': 'author',
        'authorName': 'أمينة',
      })
      ..collection('residences/home/members', [
        _document('author', {'status': 'active'}),
        _document('neighbor', {'status': 'active'}),
      ])
      ..collection('users/neighbor/pushTokens', [
        _document('phone', {'token': 'neighbor-token'}),
      ]);
    final dispatcher = NotificationDispatcher(backend);

    for (var attempt = 0; attempt < 2; attempt++) {
      await dispatcher.postCreated(
        documentPath: 'residences/home/communityPosts/post-1',
        eventId: 'event-1',
      );
    }

    expect(backend.notifications, hasLength(1));
    expect(backend.pushes, hasLength(1));
  });

  test('budget writes notify every active residence member', () async {
    final backend = _FakeBackend()
      ..collection('residences/home/members', [
        _document('manager', {'status': 'active'}),
        _document('resident', {'status': 'active'}),
      ]);
    final dispatcher = NotificationDispatcher(backend);

    await dispatcher.budgetChanged(
      documentPath: 'residences/home/financeTransactions/expense-1',
      eventId: 'event:budget/1',
    );

    expect(
      backend.notifications.map((notification) => notification.recipientUserId),
      containsAll(['manager', 'resident']),
    );
    expect(
      backend.notifications.every(
        (notification) => notification.type == 'budgetChanged',
      ),
      isTrue,
    );
  });

  test('a new like notifies only the post author', () async {
    final backend = _FakeBackend()
      ..document('residences/home/communityPosts/post-1', {
        'authorId': 'author',
      })
      ..collection('residences/home/members', [
        _document('author', {'status': 'active'}),
        _document('neighbor', {
          'status': 'active',
          'firstName': 'أمينة',
          'lastName': 'المريني',
        }),
      ]);
    final dispatcher = NotificationDispatcher(backend);

    await dispatcher.postLiked(
      documentPath: 'residences/home/communityPosts/post-1',
      eventId: 'like-event-1',
      addedUserIds: const ['neighbor'],
    );

    expect(backend.notifications, hasLength(1));
    expect(backend.notifications.single.recipientUserId, 'author');
    expect(backend.notifications.single.type, 'postLiked');
    expect(backend.notifications.single.targetId, 'post-1');
    expect(backend.notifications.single.actorName, 'أمينة م.');
  });

  test('liking your own post does not create a notification', () async {
    final backend = _FakeBackend()
      ..document('residences/home/communityPosts/post-1', {
        'authorId': 'author',
      })
      ..collection('residences/home/members', [
        _document('author', {'status': 'active'}),
      ]);

    await NotificationDispatcher(backend).postLiked(
      documentPath: 'residences/home/communityPosts/post-1',
      eventId: 'like-event-1',
      addedUserIds: const ['author'],
    );

    expect(backend.notifications, isEmpty);
  });

  test('a new comment notifies the post author', () async {
    final backend = _FakeBackend()
      ..document('residences/home/communityPosts/post-1', {
        'authorId': 'author',
      })
      ..document('residences/home/communityPosts/post-1/comments/comment-1', {
        'authorId': 'neighbor',
        'authorName': 'كريم المنيعي',
      });

    await NotificationDispatcher(backend).commentCreated(
      documentPath: 'residences/home/communityPosts/post-1/comments/comment-1',
      eventId: 'comment-event-1',
    );

    expect(backend.notifications, hasLength(1));
    expect(backend.notifications.single.recipientUserId, 'author');
    expect(backend.notifications.single.type, 'postCommented');
    expect(backend.notifications.single.targetId, 'post-1');
    expect(backend.notifications.single.actorName, 'كريم م.');
  });

  test('paid dues notify active residents assigned to the apartment', () async {
    final backend = _FakeBackend()
      ..document('residences/home/dues/2026-07_apartment-a', {
        'apartmentId': 'apartment-a',
        'periodKey': '2026-07',
      })
      ..collection('residences/home/members', [
        _document('resident-a', {
          'status': 'active',
          'apartmentId': 'apartment-a',
        }),
        _document('resident-b', {
          'status': 'active',
          'apartmentId': 'apartment-b',
        }),
      ]);
    final dispatcher = NotificationDispatcher(backend);

    await dispatcher.duesMarkedPaid(
      documentPath: 'residences/home/dues/2026-07_apartment-a',
      eventId: 'due-event-1',
      becamePaid: true,
    );

    expect(backend.notifications, hasLength(1));
    expect(backend.notifications.single.recipientUserId, 'resident-a');
    expect(backend.notifications.single.type, 'duesMarkedPaid');
    expect(backend.notifications.single.periodKey, '2026-07');
  });

  test(
    'overdue job only notifies residents assigned to unpaid apartments',
    () async {
      final backend = _FakeBackend()
        ..collection('residences', [_document('home', {})])
        ..collection('residences/home/members', [
          _document('resident-a', {
            'status': 'active',
            'apartmentId': 'apartment-a',
          }),
          _document('resident-b', {
            'status': 'active',
            'apartmentId': 'apartment-b',
          }),
        ])
        ..collection('residences/home/dues', [
          _document('2026-06_apartment-a', {
            'apartmentId': 'apartment-a',
            'periodKey': '2026-06',
            'status': 'unpaid',
            'amountDue': 150,
            'amountPaid': 0,
          }),
          _document('2026-06_apartment-b', {
            'apartmentId': 'apartment-b',
            'periodKey': '2026-06',
            'status': 'paid',
            'amountDue': 150,
            'amountPaid': 150,
          }),
        ]);
      final dispatcher = NotificationDispatcher(
        backend,
        now: () => DateTime.utc(2026, 7, 30),
      );

      await dispatcher.notifyOverdueDues();
      await dispatcher.notifyOverdueDues();

      expect(backend.notifications, hasLength(1));
      expect(backend.notifications.single.recipientUserId, 'resident-a');
      expect(backend.notifications.single.type, 'duesOverdue');
      expect(backend.notifications.single.periodKey, '2026-06');
    },
  );
}

BackendDocument _document(String id, Map<String, Object?> data) {
  return BackendDocument(id: id, path: id, data: data);
}

class _Push {
  const _Push(this.token, this.data);

  final String token;
  final Map<String, String> data;
}

class _FakeBackend implements NotificationBackend {
  final Map<String, BackendDocument> _documents = {};
  final Map<String, List<BackendDocument>> _collections = {};
  final Set<String> _notificationKeys = {};
  final List<NotificationPayload> notifications = [];
  final List<_Push> pushes = [];

  void document(String path, Map<String, Object?> data) {
    _documents[path] = BackendDocument(
      id: path.split('/').last,
      path: path,
      data: data,
    );
  }

  void collection(String path, List<BackendDocument> documents) {
    _collections[path] = [
      for (final document in documents)
        BackendDocument(
          id: document.id,
          path: '$path/${document.id}',
          data: document.data,
        ),
    ];
  }

  @override
  Future<bool> createNotification(NotificationPayload notification) async {
    final key = '${notification.recipientUserId}/${notification.id}';
    if (!_notificationKeys.add(key)) return false;
    notifications.add(notification);
    return true;
  }

  @override
  Future<void> deleteDocument(String path) async {
    _documents.remove(path);
  }

  @override
  Future<BackendDocument?> getDocument(String path) async => _documents[path];

  @override
  Future<List<BackendDocument>> listDocuments(String collectionPath) async {
    return _collections[collectionPath] ?? const [];
  }

  @override
  Future<void> sendPush({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    pushes.add(_Push(token, data));
  }
}
