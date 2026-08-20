import 'notification_backend.dart';

class NotificationDispatcher {
  NotificationDispatcher(this._backend, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final NotificationBackend _backend;
  final DateTime Function() _now;

  Future<void> residentJoined({
    required String documentPath,
    required String eventId,
  }) async {
    final path = _parseDocumentPath(documentPath, collection: 'members');
    final joinedMember = await _backend.getDocument(path.fullPath);
    if (joinedMember == null ||
        _string(joinedMember.data['status']) != 'active') {
      return;
    }
    final residentName = _memberName(joinedMember);
    final members = await _activeMembers(path.residenceId);
    for (final member in members) {
      if (member.id == path.documentId) continue;
      await _deliver(
        NotificationPayload(
          id: _safeId('resident-joined-${path.documentId}-$eventId'),
          type: 'residentJoined',
          residenceId: path.residenceId,
          recipientUserId: member.id,
          targetId: path.documentId,
          actorName: residentName,
          title: 'ساكن جديد',
          body: 'انضم $residentName إلى الإقامة.',
          occurredAt: _now().toUtc(),
        ),
      );
    }
  }

  Future<void> postCreated({
    required String documentPath,
    required String eventId,
  }) async {
    final path = _parseDocumentPath(documentPath, collection: 'communityPosts');
    final post = await _backend.getDocument(path.fullPath);
    if (post == null) return;
    final authorId = _string(post.data['authorId']);
    final authorName = _abbreviatedPersonName(
      _string(post.data['authorName'], fallback: authorId),
    );
    if (authorId.isEmpty) return;

    final members = await _activeMembers(path.residenceId);
    for (final member in members) {
      if (member.id == authorId) continue;
      await _deliver(
        NotificationPayload(
          id: _safeId('post-${path.documentId}'),
          type: 'postCreated',
          residenceId: path.residenceId,
          recipientUserId: member.id,
          targetId: path.documentId,
          actorName: authorName,
          title: 'منشور جديد',
          body: 'أضاف $authorName منشورًا جديدًا.',
          occurredAt: _now().toUtc(),
        ),
      );
    }
  }

  Future<void> budgetChanged({
    required String documentPath,
    required String eventId,
  }) async {
    final path = _parseDocumentPath(
      documentPath,
      collection: 'financeTransactions',
    );
    final members = await _activeMembers(path.residenceId);
    for (final member in members) {
      await _deliver(
        NotificationPayload(
          id: _safeId('budget-${path.documentId}-$eventId'),
          type: 'budgetChanged',
          residenceId: path.residenceId,
          recipientUserId: member.id,
          targetId: path.documentId,
          actorName: 'إدارة الإقامة',
          title: 'تحديث الميزانية',
          body: 'تم تحديث ميزانية الإقامة.',
          occurredAt: _now().toUtc(),
        ),
      );
    }
  }

  Future<void> postLiked({
    required String documentPath,
    required String eventId,
    required Iterable<String> addedUserIds,
  }) async {
    final path = _parseDocumentPath(documentPath, collection: 'communityPosts');
    final post = await _backend.getDocument(path.fullPath);
    if (post == null) return;
    final authorId = _string(post.data['authorId']);
    if (authorId.isEmpty) return;
    final members = await _activeMembers(path.residenceId);
    final membersById = {for (final member in members) member.id: member};

    for (final actorId in addedUserIds.toSet()) {
      if (actorId.isEmpty || actorId == authorId) continue;
      final actor = membersById[actorId];
      if (actor == null) continue;
      final actorName = _memberName(actor);
      await _deliver(
        NotificationPayload(
          id: _safeId('post-liked-${path.documentId}-$eventId-$actorId'),
          type: 'postLiked',
          residenceId: path.residenceId,
          recipientUserId: authorId,
          targetId: path.documentId,
          actorName: actorName,
          title: 'إعجاب جديد',
          body: 'أُعجب $actorName بمنشورك.',
          occurredAt: _now().toUtc(),
        ),
      );
    }
  }

  Future<void> commentCreated({
    required String documentPath,
    required String eventId,
  }) async {
    final path = _parseCommentPath(documentPath);
    final comment = await _backend.getDocument(path.fullPath);
    final post = await _backend.getDocument(path.postPath);
    if (comment == null || post == null) return;
    final actorId = _string(comment.data['authorId']);
    final authorId = _string(post.data['authorId']);
    if (actorId.isEmpty || authorId.isEmpty || actorId == authorId) return;
    final actorName = _abbreviatedPersonName(
      _string(comment.data['authorName'], fallback: actorId),
    );
    await _deliver(
      NotificationPayload(
        id: _safeId('post-commented-${path.commentId}'),
        type: 'postCommented',
        residenceId: path.residenceId,
        recipientUserId: authorId,
        targetId: path.postId,
        actorName: actorName,
        title: 'تعليق جديد',
        body: 'علّق $actorName على منشورك.',
        occurredAt: _now().toUtc(),
      ),
    );
  }

  Future<void> duesMarkedPaid({
    required String documentPath,
    required String eventId,
    required bool becamePaid,
  }) async {
    if (!becamePaid) return;
    final path = _parseDocumentPath(documentPath, collection: 'dues');
    final due = await _backend.getDocument(path.fullPath);
    if (due == null) return;
    final apartmentId = _string(due.data['apartmentId']);
    final periodKey = _string(due.data['periodKey']);
    if (apartmentId.isEmpty || periodKey.isEmpty) return;
    final members = await _activeMembers(path.residenceId);
    for (final member in members) {
      if (_string(member.data['apartmentId']) != apartmentId) continue;
      await _deliver(
        NotificationPayload(
          id: _safeId('dues-paid-${path.documentId}'),
          type: 'duesMarkedPaid',
          residenceId: path.residenceId,
          recipientUserId: member.id,
          targetId: path.documentId,
          periodKey: periodKey,
          title: 'تم تسجيل أداء اشتراكك',
          body: 'تم تسجيل اشتراكك عن الفترة $periodKey كمؤدى.',
          occurredAt: _now().toUtc(),
        ),
      );
    }
  }

  Future<void> notifyOverdueDues() async {
    final currentPeriod = _periodKey(_now().toUtc());
    final residences = await _backend.listDocuments('residences');
    for (final residence in residences) {
      final residenceId = residence.id;
      final members = await _activeMembers(residenceId);
      final membersByApartment = <String, List<BackendDocument>>{};
      for (final member in members) {
        final apartmentId = _string(member.data['apartmentId']);
        if (apartmentId.isNotEmpty) {
          membersByApartment.putIfAbsent(apartmentId, () => []).add(member);
        }
      }
      if (membersByApartment.isEmpty) continue;

      final dues = await _backend.listDocuments('residences/$residenceId/dues');
      for (final due in dues) {
        final periodKey = _string(due.data['periodKey']);
        final apartmentId = _string(due.data['apartmentId']);
        final status = _string(due.data['status']);
        final amountDue = _integer(due.data['amountDue']);
        final amountPaid = _integer(due.data['amountPaid']);
        if (periodKey.isEmpty ||
            periodKey.compareTo(currentPeriod) >= 0 ||
            status == 'paid' ||
            amountPaid >= amountDue) {
          continue;
        }
        for (final member
            in membersByApartment[apartmentId] ?? const <BackendDocument>[]) {
          await _deliver(
            NotificationPayload(
              id: _safeId('dues-overdue-${due.id}'),
              type: 'duesOverdue',
              residenceId: residenceId,
              recipientUserId: member.id,
              targetId: due.id,
              periodKey: periodKey,
              title: 'تأخر الأداء',
              body: 'تأخر أداء واجب الفترة $periodKey.',
              occurredAt: _now().toUtc(),
            ),
          );
        }
      }
    }
  }

  Future<List<BackendDocument>> _activeMembers(String residenceId) async {
    final members = await _backend.listDocuments(
      'residences/$residenceId/members',
    );
    return [
      for (final member in members)
        if (_string(member.data['status']) == 'active') member,
    ];
  }

  Future<void> _deliver(NotificationPayload notification) async {
    final created = await _backend.createNotification(notification);
    if (!created) return;
    final tokenDocuments = await _backend.listDocuments(
      'users/${notification.recipientUserId}/pushTokens',
    );
    for (final tokenDocument in tokenDocuments) {
      final token = _string(tokenDocument.data['token']);
      if (token.isEmpty) continue;
      try {
        await _backend.sendPush(
          token: token,
          title: notification.title,
          body: notification.body,
          data: notification.pushData,
        );
      } on InvalidPushToken {
        await _backend.deleteDocument(tokenDocument.path);
      }
    }
  }

  String _memberName(BackendDocument member) {
    final fullName =
        '${_string(member.data['firstName'])} '
                '${_string(member.data['lastName'])}'
            .trim();
    return _abbreviatedPersonName(fullName.isEmpty ? member.id : fullName);
  }
}

String _abbreviatedPersonName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length < 2) return parts.firstOrNull ?? fullName;

  final surnameRunes = parts.last.runes.toList(growable: false);
  final startsWithArticle =
      parts.last.startsWith('ال') && surnameRunes.length > 2;
  final initialIndex = startsWithArticle ? 2 : 0;
  return '${parts.first} ${String.fromCharCode(surnameRunes[initialIndex])}.';
}

class InvalidPushToken implements Exception {
  const InvalidPushToken();
}

({String fullPath, String residenceId, String documentId}) _parseDocumentPath(
  String value, {
  required String collection,
}) {
  var path = value;
  final marker = '/documents/';
  final markerIndex = path.indexOf(marker);
  if (markerIndex >= 0) path = path.substring(markerIndex + marker.length);
  if (path.startsWith('documents/')) path = path.substring('documents/'.length);
  final segments = path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.length != 4 ||
      segments[0] != 'residences' ||
      segments[2] != collection) {
    throw FormatException('Unexpected Firestore document path: $value');
  }
  return (
    fullPath: segments.join('/'),
    residenceId: segments[1],
    documentId: segments[3],
  );
}

({
  String fullPath,
  String residenceId,
  String postId,
  String postPath,
  String commentId,
})
_parseCommentPath(String value) {
  final segments = _pathSegments(value);
  if (segments.length != 6 ||
      segments[0] != 'residences' ||
      segments[2] != 'communityPosts' ||
      segments[4] != 'comments') {
    throw FormatException('Unexpected Firestore comment path: $value');
  }
  return (
    fullPath: segments.join('/'),
    residenceId: segments[1],
    postId: segments[3],
    postPath: segments.take(4).join('/'),
    commentId: segments[5],
  );
}

List<String> _pathSegments(String value) {
  var path = value;
  final marker = '/documents/';
  final markerIndex = path.indexOf(marker);
  if (markerIndex >= 0) path = path.substring(markerIndex + marker.length);
  if (path.startsWith('documents/')) path = path.substring('documents/'.length);
  return path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
}

String _safeId(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
}

String _periodKey(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}';
}

String _string(Object? value, {String fallback = ''}) {
  return value is String && value.isNotEmpty ? value : fallback;
}

int _integer(Object? value) {
  return switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text) ?? 0,
    _ => 0,
  };
}
