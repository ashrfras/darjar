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
  String token(String uid) {
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
    stdout.writeln('All 8 feed deletion security rule checks passed.');
  } finally {
    client.close(force: true);
  }
}
