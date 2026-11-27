// Run with the Firestore emulator; this script refuses non-local endpoints.
// firebase emulators:exec --only firestore --project demo-darjar \
//   'dart run tool/test_feed_activity_rules.dart'
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final host = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  if (host == null ||
      !RegExp(r'^(127\.0\.0\.1|localhost):\d+$').hasMatch(host)) {
    throw StateError('A local Firestore emulator is required.');
  }
  const project = 'demo-darjar';
  const database = 'projects/$project/databases/(default)';
  const root = '$database/documents';
  final client = HttpClient();
  Map<String, Object> fields(Map<String, Object> data) => {
    for (final entry in data.entries)
      entry.key: entry.value is int
          ? {'integerValue': '${entry.value}'}
          : entry.value is bool
          ? {'booleanValue': entry.value}
          : {'stringValue': entry.value},
  };
  String token(String uid, {bool developer = false}) {
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '${encode({'alg': 'none', 'typ': 'JWT'})}.${encode({
      'iss': 'https://securetoken.google.com/$project',
      'aud': project,
      'sub': uid,
      'user_id': uid,
      'iat': now,
      'exp': now + 3600,
      if (developer) 'developer': true,
      'firebase': {'sign_in_provider': 'custom', 'identities': {}},
    })}.';
  }

  Future<void> commit(
    List<Map<String, Object>> writes,
    String auth,
    int expected,
  ) async {
    final request = await client.postUrl(
      Uri.parse('http://$host/v1/$root:commit'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $auth');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'writes': writes}));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != expected) {
      throw StateError('Expected $expected, got ${response.statusCode}: $body');
    }
  }

  Map<String, Object> seed(String path, Map<String, Object> data) => {
    'update': {'name': '$root/$path', 'fields': fields(data)},
  };
  try {
    for (final role in [
      'president',
      'owner',
      'delegate',
      'resident',
      'moderator',
      'manager',
      'inactive',
      'outsider',
    ]) {
      await commit(
        [
          seed('residences/feed-delete-test', {'presidentId': 'president'}),
          if (role != 'outsider')
            seed('residences/feed-delete-test/members/$role', {
              'status': role == 'inactive' ? 'inactive' : 'active',
              'role': role == 'delegate'
                  ? 'resident'
                  : role == 'inactive'
                  ? 'president'
                  : role,
              'hasPresidentPermissions': role == 'delegate',
            }),
          seed('residences/feed-delete-test/feedActivities/activity', {
            'type': 'expenseAdded',
          }),
        ],
        'owner',
        200,
      );
      await commit(
        [
          {
            'delete':
                '$root/residences/feed-delete-test/feedActivities/activity',
          },
        ],
        token(role),
        ['president', 'owner', 'delegate'].contains(role) ? 200 : 403,
      );
    }
    const residence = 'residences/support-rules-test';
    for (final (uid, claim, grant, expected) in [
      ('developer', true, true, 200),
      ('claim-only', true, false, 403),
      ('grant-only', false, true, 403),
      ('outsider', false, false, 403),
    ]) {
      await commit(
        [
          seed(residence, {'presidentId': 'president'}),
          seed('$residence/feedActivities/activity', {'type': 'expenseAdded'}),
          seed('$residence/settings/private', {
            'defaultSubscriptionAmount': 100,
          }),
          seed('appPermissions/$uid', {'developer': grant}),
          seed('users/private-account', {'firstName': 'Private'}),
        ],
        'owner',
        200,
      );
      final auth = token(uid, developer: claim);
      Future<void> get(String path, int status) async {
        final request = await client.getUrl(
          Uri.parse('http://$host/v1/$root/$path'),
        );
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $auth');
        final response = await request.close();
        await response.drain<void>();
        if (response.statusCode != status) {
          throw StateError(
            '$uid: expected $status reading $path, got ${response.statusCode}',
          );
        }
      }

      await get('$residence/settings/private', expected);
      await get('users/private-account', 403);
      await get('appPermissions/$uid', 403);
      await commit(
        [
          seed('appPermissions/$uid', {'developer': true}),
        ],
        auth,
        403,
      );
      await commit(
        [
          {'delete': '$root/$residence/feedActivities/activity'},
        ],
        auth,
        expected,
      );
    }
    await commit(
      [
        seed('directoryRecommendations/support-test', {
          'residenceId': 'support-rules-test',
        }),
        seed('residences/removed-residence/settings/private', {
          'defaultSubscriptionAmount': 100,
        }),
        seed('residences/removed-residence/feedActivities/activity', {
          'type': 'expenseAdded',
        }),
      ],
      'owner',
      200,
    );
    await commit(
      [
        {'delete': '$root/directoryRecommendations/support-test'},
      ],
      token('developer', developer: true),
      403,
    );
    await commit(
      [
        {
          'delete':
              '$root/residences/removed-residence/feedActivities/activity',
        },
      ],
      token('developer', developer: true),
      403,
    );
    stdout.writeln('Feed deletion and developer support rule checks passed.');
  } finally {
    client.close(force: true);
  }
}
