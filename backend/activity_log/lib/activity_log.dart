import 'dart:convert';

import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_functions/firebase_functions.dart'
    show Request, Response;
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

class ActivityLog {
  ActivityLog(this._firestore, this._auth);

  final Firestore _firestore;
  final Auth _auth;

  Future<Response> handle(Request request) async {
    if (request.method != 'GET') return _json(405, {});
    final authorization = request.headers['authorization'];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return _json(401, {});
    }

    final DecodedIdToken session;
    try {
      session = await _auth.verifyIdToken(authorization.substring(7));
    } on FirebaseAuthAdminException {
      return _json(401, {});
    }
    if (session.firebase.tenant != null) {
      return _json(403, {});
    }
    final permission = await _firestore
        .doc('appPermissions/${session.uid}')
        .get();
    final grant = permission.data();
    final authCreatedAt = grant?['authCreatedAt'];
    if (grant?['developer'] != true || authCreatedAt is! Timestamp) {
      return _json(403, {});
    }

    // Also enforce account deletion, disabled accounts and revoked sessions.
    final UserRecord user;
    try {
      user = await _auth.getUser(session.uid);
    } on FirebaseAuthAdminException catch (error) {
      if (error.errorCode == AuthClientErrorCode.userNotFound) {
        return _json(403, {});
      }
      rethrow;
    }
    final validAfter = user.tokensValidAfterTime;
    if (user.disabled ||
        authCreatedAt != Timestamp.fromDate(user.metadata.creationTime) ||
        (validAfter != null && session.authTime.isBefore(validAfter))) {
      return _json(403, {});
    }

    final params = request.url.queryParameters;
    if (params['access'] == 'true') return _json(200, {'developer': true});

    const limit = 30;
    final logs = _firestore.collection('appActivityLog');
    var query = logs
        .orderBy('occurredAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit + 1);
    if (params['cursor'] case final String encoded) {
      final cursor = ActivityCursor.tryParse(encoded);
      if (cursor == null) return _json(400, {});
      query = query.startAfter([cursor.time, logs.doc(cursor.id)]);
    }

    final docs = (await query.get()).docs;
    final visible = docs.take(limit).toList();
    final events = [for (final document in visible) document.data()];
    final (residents, residences) = await (
      _readDetails(
        'users',
        {
          for (final event in events)
            if (event['userId'] case final String id) id,
        },
        const ['firstName', 'lastName', 'phoneNumber'],
      ),
      _readDetails(
        'residences',
        {
          for (final event in events)
            if (event['residenceId'] case final String id) id,
        },
        const ['name'],
      ),
    ).wait;

    return _json(200, {
      'events': [
        for (var index = 0; index < events.length; index++)
          _eventDetails(
            visible[index].id,
            events[index],
            residents,
            residences,
          ),
      ],
      'nextCursor': docs.length > limit
          ? ActivityCursor(
              events.last['occurredAt'] as Timestamp,
              visible.last.id,
            ).encode()
          : null,
    });
  }

  Future<Map<String, DocumentData>> _readDetails(
    String collection,
    Set<String> ids,
    List<String> fields,
  ) async {
    if (ids.isEmpty) return {};
    final source = _firestore.collection(collection);
    final documents = await _firestore.getAll([
      for (final id in ids) source.doc(id),
    ], ReadOptions(fieldMask: fields.map(FieldMask.field).toList()));
    return {
      for (final document in documents)
        if (document.data() case final DocumentData data) document.id: data,
    };
  }
}

Map<String, Object?> _eventDetails(
  String id,
  DocumentData event,
  Map<String, DocumentData> residents,
  Map<String, DocumentData> residences,
) {
  final residenceId = event['residenceId'] as String?;
  final resident = residents[event['userId']];
  final residentName = [
    if (_nonEmptyString(resident?['firstName']) case final String first) first,
    if (_nonEmptyString(resident?['lastName']) case final String last) last,
  ].join(' ');

  return {
    'id': id,
    'type': event['type'] as String,
    'occurredAt': (event['occurredAt'] as Timestamp)
        .toDate()
        .toUtc()
        .toIso8601String(),
    if (residentName.isNotEmpty) 'residentName': residentName,
    'phoneNumber': ?_nonEmptyString(resident?['phoneNumber']),
    'residenceId': ?residenceId,
    'residenceName': ?_nonEmptyString(residences[residenceId]?['name']),
  };
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class ActivityCursor {
  ActivityCursor(this.time, this.id);

  final Timestamp time;
  final String id;

  String encode() => base64Url.encode(
    utf8.encode(jsonEncode([time.seconds, time.nanoseconds, id])),
  );

  static ActivityCursor? tryParse(String encoded) {
    if (encoded.length > 256) return null;
    try {
      final values = jsonDecode(utf8.decode(base64Url.decode(encoded)));
      if (values case [
        final int seconds,
        final int nanos,
        final String id,
      ] when RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
        return ActivityCursor(
          Timestamp(seconds: seconds, nanoseconds: nanos),
          id,
        );
      }
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
    return null;
  }
}

Response _json(int status, Map<String, Object?> body) => Response(
  status,
  body: jsonEncode(body),
  headers: {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
  },
);
