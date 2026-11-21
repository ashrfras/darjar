import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'notification_backend.dart';
import 'notification_dispatcher.dart';

const _datastoreScope = 'https://www.googleapis.com/auth/datastore';
const _messagingScope = 'https://www.googleapis.com/auth/firebase.messaging';

class GoogleCloudNotificationBackend implements NotificationBackend {
  GoogleCloudNotificationBackend._(this._projectId, this._client);

  final String _projectId;
  final AutoRefreshingAuthClient _client;

  static Future<GoogleCloudNotificationBackend> create(String projectId) async {
    final client = await clientViaApplicationDefaultCredentials(
      scopes: const [_datastoreScope, _messagingScope],
    );
    return GoogleCloudNotificationBackend._(projectId, client);
  }

  String get _documentsBase =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/'
      'databases/(default)/documents';

  @override
  Future<BackendDocument?> getDocument(String path) async {
    final response = await _client.get(Uri.parse('$_documentsBase/$path'));
    if (response.statusCode == 404) return null;
    _expectSuccess(response, 'get $path');
    return _decodeDocument(jsonDecode(response.body) as Map<String, Object?>);
  }

  @override
  Future<List<BackendDocument>> listDocuments(String collectionPath) async {
    return scanDocuments(collectionPath).toList();
  }

  Stream<BackendDocument> scanDocuments(
    String collectionPath, [
    List<String> fields = const [],
  ]) async* {
    String? pageToken;
    do {
      final query = <String, String>{'pageSize': '300'};
      final parameters = <String, Object>{...query};
      if (pageToken != null) parameters['pageToken'] = pageToken;
      if (fields.isNotEmpty) parameters['mask.fieldPaths'] = fields;
      final uri = Uri.parse(
        '$_documentsBase/$collectionPath',
      ).replace(queryParameters: parameters);
      final response = await _client.get(uri);
      if (response.statusCode == 404) return;
      _expectSuccess(response, 'list $collectionPath');
      final body = jsonDecode(response.body) as Map<String, Object?>;
      final rawDocuments = body['documents'] as List<Object?>? ?? const [];
      for (final raw in rawDocuments) {
        yield _decodeDocument(raw! as Map<String, Object?>);
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
  }

  Future<BackendDocument?> earliestActivityPost(String residencePath) async {
    final response = await _client.post(
      Uri.parse('$_documentsBase/$residencePath:runQuery'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': 'communityPosts'},
          ],
          'select': {
            'fields': [
              {'fieldPath': 'createdAt'},
            ],
          },
          'orderBy': [
            {
              'field': {'fieldPath': 'createdAt'},
              'direction': 'ASCENDING',
            },
          ],
          'limit': 1,
        },
      }),
    );
    _expectSuccess(response, 'find first community post');
    for (final row in jsonDecode(response.body) as List<Object?>) {
      if ((row as Map<String, Object?>)['document']
          case final Map<String, Object?> document) {
        return _decodeDocument(document);
      }
    }
    return null;
  }

  Future<void> saveActivityEvent({
    required String id,
    required Map<String, Object?> fields,
    required bool keepEarliest,
  }) async {
    final uri = Uri.parse('$_documentsBase/appActivityLog/$id');
    for (var attempt = 0; attempt < 5; attempt++) {
      String? updateTime;
      if (keepEarliest) {
        final current = await _client.get(uri);
        if (current.statusCode != 404) {
          _expectSuccess(current, 'read first post activity');
          final document = jsonDecode(current.body) as Map<String, Object?>;
          final recordedAt = _decodeDocument(document).data['occurredAt'];
          if (recordedAt is DateTime &&
              !recordedAt.isAfter(fields['occurredAt']! as DateTime)) {
            return;
          }
          updateTime = document['updateTime']! as String;
        }
      }
      final response = await _client.patch(
        uri.replace(
          queryParameters: {
            if (updateTime == null) 'currentDocument.exists': 'false',
            'currentDocument.updateTime': ?updateTime,
          },
        ),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'fields': fields.map(
            (key, value) => MapEntry(key, _firestoreValue(value)),
          ),
        }),
      );
      final status = response.statusCode >= 400
          ? (jsonDecode(response.body) as Map<String, Object?>)['error']
          : null;
      final code = status is Map ? status['status'] : null;
      if (code == 'ALREADY_EXISTS' ||
          code == 'FAILED_PRECONDITION' ||
          code == 'ABORTED' ||
          (keepEarliest && response.statusCode == 404)) {
        if (keepEarliest) continue;
        if (code == 'ALREADY_EXISTS' || code == 'FAILED_PRECONDITION') return;
      }
      _expectSuccess(response, 'write app activity');
      return;
    }
    throw StateError('Concurrent update to the first post activity.');
  }

  @override
  Future<bool> createNotification(NotificationPayload notification) async {
    final parent = 'users/${notification.recipientUserId}';
    final uri = Uri.parse(
      '$_documentsBase/$parent/notifications',
    ).replace(queryParameters: {'documentId': notification.id});
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'type': _stringValue(notification.type),
          'residenceId': _stringValue(notification.residenceId),
          'recipientUserId': _stringValue(notification.recipientUserId),
          'targetId': _stringValue(notification.targetId),
          'actorName': _stringValue(notification.actorName),
          'periodKey': _stringValue(notification.periodKey),
          if (notification.amount case final amount?)
            'amount': _firestoreValue(amount),
          'occurredAt': {
            'timestampValue': notification.occurredAt.toUtc().toIso8601String(),
          },
          'readAt': {'nullValue': null},
        },
      }),
    );
    if (response.statusCode == 409) return false;
    _expectSuccess(response, 'create notification ${notification.id}');
    return true;
  }

  @override
  Future<bool> createFeedActivity(FeedActivityPayload activity) async {
    final parent = 'residences/${activity.residenceId}';
    final uri = Uri.parse(
      '$_documentsBase/$parent/feedActivities',
    ).replace(queryParameters: {'documentId': activity.id});
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'type': _firestoreValue(activity.type),
          'category': _firestoreValue(activity.category),
          'actorId': _firestoreValue(activity.actorId),
          'actorName': _firestoreValue(activity.actorName),
          'referenceType': _firestoreValue(activity.referenceType),
          'referenceId': _firestoreValue(activity.referenceId),
          'payload': _firestoreValue(activity.payload),
          'likedBy': _firestoreValue(const <String>[]),
          'likesCount': _firestoreValue(0),
          'occurredAt': _firestoreValue(activity.occurredAt.toUtc()),
        },
      }),
    );
    if (response.statusCode == 409) return false;
    _expectSuccess(response, 'create feed activity ${activity.id}');
    return true;
  }

  @override
  Future<void> sendPush({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    final response = await _client.post(
      Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      ),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data': data,
          'android': {'priority': 'high'},
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
          'webpush': {
            'fcm_options': {
              'link': data['type'] == 'paymentRecorded'
                  ? 'https://darjar.app/residence/dues'
                  : '/',
            },
          },
        },
      }),
    );
    if (_isInvalidToken(response)) throw const InvalidPushToken();
    _expectSuccess(response, 'send FCM message');
  }

  @override
  Future<void> deleteDocument(String path) async {
    final response = await _client.delete(Uri.parse('$_documentsBase/$path'));
    if (response.statusCode == 404) return;
    _expectSuccess(response, 'delete $path');
  }

  Future<void> updateDocumentFields(
    String path,
    Map<String, Object?> fields,
  ) async {
    final uri = Uri.parse('$_documentsBase/$path').replace(
      queryParameters: {
        'updateMask.fieldPaths': fields.keys.toList(growable: false),
      },
    );
    final response = await _client.patch(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': {
          for (final entry in fields.entries)
            entry.key: _firestoreValue(entry.value),
        },
      }),
    );
    _expectSuccess(response, 'update $path');
  }

  BackendDocument _decodeDocument(Map<String, Object?> raw) {
    final name = raw['name'] as String;
    final marker = '/documents/';
    final path = name.substring(name.indexOf(marker) + marker.length);
    final fields = raw['fields'] as Map<String, Object?>? ?? const {};
    return BackendDocument(
      id: path.split('/').last,
      path: path,
      createTime: DateTime.tryParse(raw['createTime'] as String? ?? ''),
      data: {
        for (final entry in fields.entries)
          entry.key: _decodeValue(entry.value as Map<String, Object?>),
      },
    );
  }

  Object? _decodeValue(Map<String, Object?> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString()) ?? 0;
    }
    if (value.containsKey('doubleValue')) return value['doubleValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('timestampValue')) {
      return DateTime.tryParse(value['timestampValue'].toString());
    }
    if (value.containsKey('nullValue')) return null;
    if (value['arrayValue'] case final Map<String, Object?> array) {
      final values = array['values'] as List<Object?>? ?? const [];
      return [
        for (final item in values) _decodeValue(item! as Map<String, Object?>),
      ];
    }
    if (value['mapValue'] case final Map<String, Object?> map) {
      final fields = map['fields'] as Map<String, Object?>? ?? const {};
      return {
        for (final entry in fields.entries)
          entry.key: _decodeValue(entry.value as Map<String, Object?>),
      };
    }
    return null;
  }

  bool _isInvalidToken(http.Response response) {
    if (response.statusCode != 400 && response.statusCode != 404) return false;
    return response.body.contains('UNREGISTERED') ||
        response.body.contains('INVALID_ARGUMENT');
  }

  void _expectSuccess(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError(
      '$operation failed (${response.statusCode}): ${response.body}',
    );
  }

  void close() => _client.close();
}

Map<String, Object?> _stringValue(String value) => {'stringValue': value};

Map<String, Object?> _firestoreValue(Object? value) {
  return switch (value) {
    null => {'nullValue': null},
    bool boolean => {'booleanValue': boolean},
    int integer => {'integerValue': '$integer'},
    num number => {'doubleValue': number},
    String text => {'stringValue': text},
    DateTime date => {'timestampValue': date.toUtc().toIso8601String()},
    List<Object?> values => {
      'arrayValue': {
        'values': [for (final item in values) _firestoreValue(item)],
      },
    },
    Map<Object?, Object?> map => {
      'mapValue': {
        'fields': {
          for (final entry in map.entries)
            entry.key.toString(): _firestoreValue(entry.value),
        },
      },
    },
    _ => throw ArgumentError.value(
      value,
      'value',
      'Unsupported Firestore value',
    ),
  };
}
