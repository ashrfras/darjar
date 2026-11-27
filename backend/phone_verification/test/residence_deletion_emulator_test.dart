import 'dart:convert';
import 'dart:io';

import 'package:darjar_phone_verification/src/residence_deletion.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _project = 'demo-darjar';
const _root = 'projects/$_project/databases/(default)/documents';
const _owner = 'delete-test-owner';
const _neighbor = 'delete-test-neighbor';
const _phone = '+212600100001';

void main() {
  final host = Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '';
  final local = RegExp(r'^(127\.0\.0\.1|localhost):\d+$').hasMatch(host);
  late _EmulatorClient client;
  late ResidenceDeletion deletion;

  setUp(() {
    client = _EmulatorClient();
    addTearDown(client.close);
    deletion = ResidenceDeletion(
      projectId: _project,
      client: client,
      firestoreOrigin: Uri.http(host),
      storageBucket: 'test-bucket',
    );
  });

  Future<http.Response> commit(
    List<Map<String, Object?>> writes, {
    String authorization = 'owner',
  }) => client.post(
    Uri.http(host, '/v1/$_root:commit'),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $authorization',
    },
    body: jsonEncode({'writes': writes}),
  );

  Future<http.Response> get(String path) =>
      client.get(Uri.http(host, '/v1/$_root/$path'));

  Future<void> seed(
    String id, {
    bool legacy = false,
    String? neighborStatus,
  }) async {
    final base = 'residences/$id';
    final result = await commit([
      _write(base, {
        'name': id,
        if (!legacy) 'createdBy': _owner,
        'joinRequestsEnabled': true,
        'presidentId': null,
      }),
      _write('$base/settings/private', {'createdBy': _owner, 'joinCode': id}),
      _write('$base/members/$_owner', {'userId': _owner, 'status': 'active'}),
      if (neighborStatus != null)
        _write('$base/members/$_neighbor', {
          'userId': _neighbor,
          'status': neighborStatus,
        }),
      _write('$base/invitations/$_phone', {
        'phoneNumber': _phone,
        'role': 'resident',
        'status': 'pending',
      }),
      _write('residenceCodes/$id', {'residenceId': id}),
    ]);
    expect(result.statusCode, 200, reason: result.body);
  }

  group(
    'residence deletion with Firestore rules',
    () {
      for (final status in ['active', 'left', 'removed', 'deletionRequested']) {
        test('blocks deletion when another member is $status', () async {
          final id = 'history-$status';
          await seed(id, neighborStatus: status);
          await expectLater(
            deletion.delete(id, _owner),
            throwsA(
              isA<ResidenceDeletionFailure>().having(
                (error) => error.code,
                'code',
                'residence-has-joined-residents',
              ),
            ),
          );
          expect((await get('residenceCodes/$id')).statusCode, 200);
          expect(
            (await get('residences/$id')).body,
            isNot(contains('deletionStartedBy')),
          );
          expect(client.storageRequests, isEmpty);
        });
      }

      test(
        'only the creator may delete and repeated requests are safe',
        () async {
          const id = 'solo-home';
          const base = 'residences/$id';
          await seed(id);
          final otherData = await commit([
            _write('users/$_owner', {
              'activeResidenceId': id,
              'firstName': 'Amal',
            }),
            _write('users/$_owner/pushTokens/phone', {
              'residenceIds': [id, 'other-home'],
            }),
            _write('users/$_owner/notifications/deletion-notice', {
              'residenceId': id,
            }),
            _write('publicResidences/$id', {'name': id}),
            _write('publicPaymentReceipts/receipt', {'residenceId': id}),
            _write('directoryRecommendations/recommendation', {
              'residenceId': id,
            }),
            _write('services/city-listing', {
              'createdFromResidenceId': id,
              'createdFromResidenceName': 'Home',
              'name': 'Service',
            }),
            _write('appActivityLog/deletion-test', {'residenceId': id}),
            _write('$base/communityPosts/post/comments/comment', {
              'content': 'orphan',
            }),
            _write('$base/buildings/main/floors/ground/apartments/flat', {
              'name': '1',
            }),
          ]);
          expect(otherData.statusCode, 200, reason: otherData.body);
          await expectLater(
            deletion.delete(id, _neighbor),
            throwsA(
              isA<ResidenceDeletionFailure>().having(
                (error) => error.status,
                'status',
                403,
              ),
            ),
          );
          client.storageObjects.add('$base/community/post/image.jpg');

          await deletion.delete(id, _owner);
          await deletion.delete(id, _owner);
          for (final path in [
            base,
            '$base/settings/private',
            '$base/members/$_owner',
            '$base/invitations/$_phone',
            '$base/communityPosts/post/comments/comment',
            '$base/buildings/main/floors/ground/apartments/flat',
            'residenceCodes/$id',
            'publicResidences/$id',
            'publicPaymentReceipts/receipt',
            'directoryRecommendations/recommendation',
            'appActivityLog/deletion-test',
            'users/$_owner/notifications/deletion-notice',
          ]) {
            expect((await get(path)).statusCode, 404, reason: path);
          }
          final user = await get('users/$_owner');
          expect(user.body, isNot(contains('activeResidenceId')));
          expect(user.body, contains('Amal'));
          final token = await get('users/$_owner/pushTokens/phone');
          expect(token.body, isNot(contains(id)));
          expect(token.body, contains('other-home'));
          final service = await get('services/city-listing');
          expect(service.body, isNot(contains('createdFromResidence')));
          expect(service.body, contains('Service'));
          expect(client.storageObjects, isEmpty);
        },
      );

      test(
        'the lock blocks both join paths and cleanup can be retried',
        () async {
          const id = 'retry-home';
          const base = 'residences/$id';
          await seed(id, legacy: true);
          expect(
            (await commit([
              _write('users/$_neighbor', {
                'firstName': 'Amal',
                'lastName': 'Alami',
              }),
            ])).statusCode,
            200,
          );

          final token = _token();
          Map<String, Object?> accept() => _write(
            '$base/invitations/$_phone',
            {
              'suggestedFirstName': 'Amal',
              'suggestedLastName': 'Alami',
              'apartmentId': 'flat',
              'status': 'accepted',
              'acceptedBy': _neighbor,
            },
            merge: true,
            timestamp: 'acceptedAt',
          );

          client.failStorage = true;
          await expectLater(deletion.delete(id, _owner), throwsException);
          expect((await get(base)).body, contains('deletionStartedBy'));
          expect(
            (await commit([_join(id)], authorization: token)).statusCode,
            403,
          );
          expect(
            (await commit([
              accept(),
              _join(id, invitation: true),
            ], authorization: token)).statusCode,
            403,
          );
          expect(
            (await get('$base/invitations/$_phone')).body,
            contains('pending'),
          );

          client.failStorage = false;
          await deletion.delete(id, _owner);
          expect((await get(base)).statusCode, 404);
          expect((await get('$base/invitations/$_phone')).statusCode, 404);
        },
      );
      test('a join racing the deletion cannot be erased', () async {
        const id = 'join-race-home';
        await seed(id);
        final profile = await commit([
          _write('users/$_neighbor', {
            'firstName': 'Amal',
            'lastName': 'Alami',
          }),
        ]);
        expect(profile.statusCode, 200);

        late Future<http.Response> joining;
        client.beforeLock = () async {
          joining = commit([_join(id)], authorization: _token());
          await Future<void>.delayed(const Duration(milliseconds: 40));
        };
        String? failure;
        try {
          await deletion.delete(id, _owner);
        } on ResidenceDeletionFailure catch (error) {
          failure = error.code;
        }
        final joined = await joining;
        if (joined.statusCode == 200) {
          expect(failure, 'residence-has-joined-residents');
          expect(
            (await get('residences/$id/members/$_neighbor')).statusCode,
            200,
          );
        } else {
          expect(joined.statusCode, 403, reason: joined.body);
          expect(failure, isNull);
          expect((await get('residences/$id')).statusCode, 404);
        }
      });
    },
    skip: local ? false : 'Requires a local Firestore emulator',
  );
}

Map<String, Object?> _join(String id, {bool invitation = false}) =>
    _write('residences/$id/members/$_neighbor', {
      'userId': _neighbor,
      'firstName': 'Amal',
      'lastName': 'Alami',
      'phoneNumber': _phone,
      'apartmentId': 'flat',
      'role': 'resident',
      'hasPresidentPermissions': false,
      'hasProfileImage': false,
      'status': 'active',
      if (invitation) 'sourceInvitationId': _phone else 'source': 'join-code',
      if (!invitation) 'residenceCode': id,
    }, timestamp: 'joinedAt');

Map<String, Object?> _write(
  String path,
  Map<String, Object?> values, {
  bool merge = false,
  String? timestamp,
}) => {
  'update': {
    'name': '$_root/$path',
    'fields': values.map((key, value) => MapEntry(key, _encode(value))),
  },
  if (merge) 'updateMask': {'fieldPaths': values.keys.toList()},
  if (timestamp != null)
    'updateTransforms': [
      {'fieldPath': timestamp, 'setToServerValue': 'REQUEST_TIME'},
    ],
};

Map<String, Object?> _encode(Object? value) => switch (value) {
  final String text => {'stringValue': text},
  final bool flag => {'booleanValue': flag},
  final List<String> items => {
    'arrayValue': {'values': items.map(_encode).toList()},
  },
  null => {'nullValue': null},
  _ => throw ArgumentError.value(value),
};

String _token() {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return '${encode({'alg': 'none', 'typ': 'JWT'})}.${encode({
    'iss': 'https://securetoken.google.com/$_project',
    'aud': _project,
    'sub': _neighbor,
    'user_id': _neighbor,
    'phone_number': _phone,
    'iat': now,
    'exp': now + 3600,
    'firebase': {'sign_in_provider': 'phone', 'identities': {}},
  })}.';
}

class _EmulatorClient extends http.BaseClient {
  final _client = http.Client();
  final storageObjects = <String>[];
  final storageRequests = <Uri>[];
  bool failStorage = false;
  Future<void> Function()? beforeLock;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host == 'storage.googleapis.com') {
      storageRequests.add(request.url);
      if (failStorage) return http.StreamedResponse(Stream.empty(), 500);
      if (request.method == 'DELETE') {
        expect(request.url.queryParameters['generation'], '123');
        expect(storageObjects.remove(request.url.pathSegments.last), isTrue);
        return http.StreamedResponse(Stream.empty(), 204);
      }
      final prefix = request.url.queryParameters['prefix']!;
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'items': [
                for (final name in storageObjects)
                  if (name.startsWith(prefix))
                    {'name': name, 'generation': '123'},
              ],
            }),
          ),
        ),
        200,
      );
    }
    if (request is http.Request &&
        request.url.path.endsWith(':commit') &&
        request.body.contains('deletionStartedBy')) {
      final action = beforeLock;
      beforeLock = null;
      if (action != null) await action();
    }
    request.headers.putIfAbsent('authorization', () => 'Bearer owner');
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
