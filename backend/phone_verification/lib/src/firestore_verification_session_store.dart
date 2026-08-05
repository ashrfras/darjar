import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'phone_verification_service.dart';

class FirestoreVerificationSessionStore implements VerificationSessionStore {
  FirestoreVerificationSessionStore({
    required String projectId,
    required AutoRefreshingAuthClient client,
  }) : this._(projectId, client);

  FirestoreVerificationSessionStore._(this._projectId, this._client);

  final String _projectId;
  final AutoRefreshingAuthClient _client;

  String get _collectionBase =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/'
      'databases/(default)/documents/phoneVerificationSessions';

  String get _rateLimitsBase =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/'
      'databases/(default)/documents/phoneVerificationRateLimits';

  @override
  Future<void> reserveSend(String phoneNumber, DateTime requestedAt) async {
    final documentId = _rateLimitDocumentId(phoneNumber, requestedAt);
    final uri = Uri.parse(
      _rateLimitsBase,
    ).replace(queryParameters: {'documentId': documentId});
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'expiresAt': {
            'timestampValue': requestedAt
                .toUtc()
                .add(const Duration(minutes: 2))
                .toIso8601String(),
          },
        },
      }),
    );
    if (response.statusCode == 409) {
      throw const VerificationFailure('too-many-requests');
    }
    _expectSuccess(response.statusCode, response.body, 'reserve SMS send');
  }

  @override
  Future<void> releaseSend(String phoneNumber, DateTime requestedAt) async {
    final documentId = _rateLimitDocumentId(phoneNumber, requestedAt);
    final response = await _client.delete(
      Uri.parse('$_rateLimitsBase/$documentId'),
    );
    if (response.statusCode == 404) return;
    _expectSuccess(response.statusCode, response.body, 'release SMS send');
  }

  @override
  Future<void> save(VerificationSession session) async {
    final uri = Uri.parse(
      _collectionBase,
    ).replace(queryParameters: {'documentId': session.id});
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'phoneNumber': {'stringValue': session.phoneNumber},
          'codeHash': {'stringValue': session.codeHash},
          'attemptsRemaining': {
            'integerValue': session.attemptsRemaining.toString(),
          },
          'expiresAt': {
            'timestampValue': session.expiresAt.toUtc().toIso8601String(),
          },
        },
      }),
    );
    _expectSuccess(response.statusCode, response.body, 'save session');
  }

  @override
  Future<void> update(VerificationSession session) async {
    final uri = Uri.parse(
      '$_collectionBase/${session.id}',
    ).replace(queryParameters: {'updateMask.fieldPaths': 'attemptsRemaining'});
    final response = await _client.patch(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'attemptsRemaining': {
            'integerValue': session.attemptsRemaining.toString(),
          },
        },
      }),
    );
    _expectSuccess(response.statusCode, response.body, 'update session');
  }

  @override
  Future<VerificationSession?> get(String id) async {
    final response = await _client.get(Uri.parse('$_collectionBase/$id'));
    if (response.statusCode == 404) return null;
    _expectSuccess(response.statusCode, response.body, 'get session');
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final fields = body['fields']! as Map<String, Object?>;
    return VerificationSession(
      id: id,
      phoneNumber: _stringField(fields, 'phoneNumber'),
      codeHash: _stringField(fields, 'codeHash'),
      attemptsRemaining: _integerField(fields, 'attemptsRemaining'),
      expiresAt: DateTime.parse(_timestampField(fields, 'expiresAt')).toUtc(),
    );
  }

  @override
  Future<void> delete(String id) async {
    final response = await _client.delete(Uri.parse('$_collectionBase/$id'));
    if (response.statusCode == 404) return;
    _expectSuccess(response.statusCode, response.body, 'delete session');
  }
}

String _rateLimitDocumentId(String phoneNumber, DateTime requestedAt) {
  final minuteBucket = requestedAt.toUtc().millisecondsSinceEpoch ~/ 60000;
  return sha256.convert(utf8.encode('$phoneNumber:$minuteBucket')).toString();
}

String _stringField(Map<String, Object?> fields, String name) {
  return (fields[name]! as Map<String, Object?>)['stringValue'] as String;
}

String _timestampField(Map<String, Object?> fields, String name) {
  return (fields[name]! as Map<String, Object?>)['timestampValue'] as String;
}

int _integerField(Map<String, Object?> fields, String name) {
  final value = (fields[name]! as Map<String, Object?>)['integerValue'];
  return int.parse(value.toString());
}

void _expectSuccess(int statusCode, String body, String operation) {
  if (statusCode >= 200 && statusCode < 300) return;
  throw VerificationFailure(
    'authentication-service-error',
    message: '$operation failed ($statusCode): $body',
  );
}
