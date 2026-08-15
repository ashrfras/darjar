import 'notification_backend.dart';

class FeedActivityDispatcher {
  FeedActivityDispatcher(this._backend, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final NotificationBackend _backend;
  final DateTime Function() _now;

  static const backfillLimitPerType = 10;

  Future<int> backfillExistingActivities() async {
    var processed = 0;
    final residences = await _backend.listDocuments('residences');
    for (final residence in residences) {
      final residenceId = residence.id;
      final transactions = _latest(
        (await _backend.listDocuments(
              'residences/$residenceId/financeTransactions',
            ))
            .where((transaction) {
              return _string(transaction.data['type']) == 'expense';
            })
            .toList(growable: false),
        dateField: 'createdAt',
      );
      for (final transaction in transactions) {
        await financeTransactionCreated(
          documentPath: transaction.path,
          eventId: 'backfill-finance-$residenceId-${transaction.id}',
          data: transaction.data,
        );
        processed++;
      }

      final paidDues = _latest(
        (await _backend.listDocuments('residences/$residenceId/dues'))
            .where((due) => _string(due.data['status']) == 'paid')
            .toList(growable: false),
        dateField: 'updatedAt',
      );
      for (final due in paidDues) {
        await dueMarkedPaid(
          documentPath: due.path,
          eventId: 'backfill-due-$residenceId-${due.id}',
          data: due.data,
          becamePaid: true,
        );
        processed++;
      }

      final documents = _latest(
        await _backend.listDocuments('residences/$residenceId/documents'),
        dateField: 'createdAt',
      );
      for (final document in documents) {
        await documentCreated(
          documentPath: document.path,
          eventId: 'backfill-document-$residenceId-${document.id}',
          data: document.data,
        );
        processed++;
      }
    }

    final servicesByResidence = <String, List<BackendDocument>>{};
    for (final service in await _backend.listDocuments('services')) {
      final residenceId = _string(service.data['createdFromResidenceId']);
      if (residenceId.isEmpty ||
          _string(service.data['status']) == 'archived') {
        continue;
      }
      servicesByResidence.putIfAbsent(residenceId, () => []).add(service);
    }
    for (final entry in servicesByResidence.entries) {
      for (final service in _latest(entry.value, dateField: 'createdAt')) {
        await serviceCreated(
          documentPath: service.path,
          eventId: 'backfill-service-${entry.key}-${service.id}',
          data: service.data,
        );
        processed++;
      }
    }
    return processed;
  }

  Future<void> financeTransactionCreated({
    required String documentPath,
    required String eventId,
    required Map<String, Object?> data,
  }) async {
    final path = _parseResidenceDocumentPath(
      documentPath,
      collection: 'financeTransactions',
    );
    if (_string(data['type']) != 'expense') return;
    final actorId = _string(data['recordedBy']);
    await _create(
      id: 'expense-$eventId',
      residenceId: path.residenceId,
      type: 'expenseAdded',
      category: 'finance',
      actorId: actorId,
      referenceType: 'transaction',
      referenceId: path.documentId,
      occurredAt: _date(data['createdAt']),
      payload: {
        'title': _string(data['name'], fallback: 'مصروف'),
        'expenseCategory': _string(data['expenseCategory']),
        'amount': _number(data['amount']),
      },
    );
  }

  Future<void> dueMarkedPaid({
    required String documentPath,
    required String eventId,
    required Map<String, Object?> data,
    required bool becamePaid,
  }) async {
    if (!becamePaid) return;
    final path = _parseResidenceDocumentPath(documentPath, collection: 'dues');
    await _create(
      id: 'due-paid-$eventId',
      residenceId: path.residenceId,
      type: 'duePaid',
      category: 'finance',
      referenceType: 'dues',
      referenceId: path.documentId,
      occurredAt: _date(data['updatedAt']),
      payload: {
        'periodKey': _string(data['periodKey']),
        'apartmentNumber': _string(data['apartmentNumber']),
      },
    );
  }

  Future<void> documentCreated({
    required String documentPath,
    required String eventId,
    required Map<String, Object?> data,
  }) async {
    final path = _parseResidenceDocumentPath(
      documentPath,
      collection: 'documents',
    );
    final actorId = _string(data['uploadedBy']);
    await _create(
      id: 'document-$eventId',
      residenceId: path.residenceId,
      type: 'documentAdded',
      category: 'documents',
      actorId: actorId,
      referenceType: 'document',
      referenceId: path.documentId,
      occurredAt: _date(data['createdAt']),
      payload: {'title': _string(data['title'], fallback: 'وثيقة')},
    );
  }

  Future<void> serviceCreated({
    required String documentPath,
    required String eventId,
    required Map<String, Object?> data,
  }) async {
    final segments = _pathSegments(documentPath);
    if (segments.length != 2 || segments.first != 'services') {
      throw FormatException('Unexpected service path: $documentPath');
    }
    final residenceId = _string(data['createdFromResidenceId']);
    if (residenceId.isEmpty) return;
    final actorId = _string(data['createdBy']);
    await _create(
      id: 'service-$eventId',
      residenceId: residenceId,
      type: 'serviceAdded',
      category: 'services',
      actorId: actorId,
      referenceType: 'service',
      referenceId: segments.last,
      occurredAt: _date(data['createdAt']),
      payload: {'title': _string(data['name'], fallback: 'خدمة')},
    );
  }

  Future<void> monthlyDueChanged({
    required String documentPath,
    required String eventId,
    required Map<String, Object?> before,
    required Map<String, Object?> after,
  }) async {
    final segments = _pathSegments(documentPath);
    if (segments.length != 4 ||
        segments[0] != 'residences' ||
        segments[2] != 'settings' ||
        segments[3] != 'private') {
      throw FormatException('Unexpected settings path: $documentPath');
    }
    final previousAmount = _number(before['defaultSubscriptionAmount']);
    final newAmount = _number(after['defaultSubscriptionAmount']);
    if (previousAmount == newAmount) return;
    await _create(
      id: 'monthly-due-$eventId',
      residenceId: segments[1],
      type: 'monthlyDueChanged',
      category: 'finance',
      referenceType: 'dues',
      referenceId: '',
      occurredAt: _date(after['updatedAt']),
      payload: {'previousAmount': previousAmount, 'newAmount': newAmount},
    );
  }

  Future<void> _create({
    required String id,
    required String residenceId,
    required String type,
    required String category,
    required String referenceType,
    required String referenceId,
    required DateTime occurredAt,
    required Map<String, Object?> payload,
    String actorId = '',
  }) async {
    var actorName = '';
    if (actorId.isNotEmpty) {
      final member = await _backend.getDocument(
        'residences/$residenceId/members/$actorId',
      );
      if (member != null) actorName = _memberName(member);
    }
    await _backend.createFeedActivity(
      FeedActivityPayload(
        id: _safeId(id),
        residenceId: residenceId,
        type: type,
        category: category,
        actorId: actorId,
        actorName: actorName,
        referenceType: referenceType,
        referenceId: referenceId,
        occurredAt: occurredAt,
        payload: payload,
      ),
    );
  }

  String _memberName(BackendDocument member) {
    final firstName = _string(member.data['firstName']).trim();
    final lastName = _string(member.data['lastName']).trim();
    if (firstName.isEmpty) return member.id;
    if (lastName.isEmpty) return firstName;
    final surnameRunes = lastName.runes.toList(growable: false);
    final startsWithArticle = lastName.startsWith('ال') && surnameRunes.length > 2;
    final initialIndex = startsWithArticle ? 2 : 0;
    return '$firstName ${String.fromCharCode(surnameRunes[initialIndex])}.';
  }

  DateTime _date(Object? value) => value is DateTime ? value : _now().toUtc();

  List<BackendDocument> _latest(
    List<BackendDocument> documents, {
    required String dateField,
  }) {
    final ordered = [...documents]
      ..sort(
        (first, second) => _dateForSort(
          second.data[dateField],
        ).compareTo(_dateForSort(first.data[dateField])),
      );
    return ordered.take(backfillLimitPerType).toList(growable: false);
  }

  DateTime _dateForSort(Object? value) =>
      value is DateTime ? value : DateTime.fromMillisecondsSinceEpoch(0);
}

({String residenceId, String documentId}) _parseResidenceDocumentPath(
  String value, {
  required String collection,
}) {
  final segments = _pathSegments(value);
  if (segments.length != 4 ||
      segments[0] != 'residences' ||
      segments[2] != collection) {
    throw FormatException('Unexpected Firestore document path: $value');
  }
  return (residenceId: segments[1], documentId: segments[3]);
}

List<String> _pathSegments(String value) {
  var path = value;
  final marker = '/documents/';
  final markerIndex = path.indexOf(marker);
  if (path.contains('/databases/') && markerIndex >= 0) {
    path = path.substring(markerIndex + marker.length);
  }
  if (path.startsWith('documents/')) path = path.substring('documents/'.length);
  return path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
}

String _safeId(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');

String _string(Object? value, {String fallback = ''}) =>
    value is String && value.isNotEmpty ? value : fallback;

num _number(Object? value) => switch (value) {
  num number => number,
  String text => num.tryParse(text) ?? 0,
  _ => 0,
};
