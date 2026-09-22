// Run with the Firestore emulator; this script refuses non-local endpoints.
// firebase emulators:exec --only firestore --project demo-darjar \
//   'dart run tool/test_dues_exemption_rules.dart'
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
  Map<String, Object> change(String id, String status, {int? paid}) => {
    'update': {
      'name': '$root/residences/exemption-test/dues/$id',
      'fields': fields({'status': status, 'amountPaid': ?paid}),
    },
    'updateMask': {
      'fieldPaths': ['status', if (paid != null) 'amountPaid'],
    },
    'updateTransforms': [
      {'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'},
    ],
  };
  try {
    await commit(
      [
        seed('residences/exemption-test/members/manager', {
          'status': 'active',
          'role': 'owner',
        }),
        seed('residences/exemption-test/members/resident', {
          'status': 'active',
          'role': 'resident',
          'hasPresidentPermissions': false,
        }),
        for (final status in ['unpaid', 'partial', 'paid', 'exempt'])
          seed('residences/exemption-test/dues/$status', {
            'status': status,
            'apartmentId': 'a',
            'apartmentNumber': '1',
            'periodKey': '2026-01',
            'amountDue': 150,
            'amountPaid': status == 'paid'
                ? 150
                : status == 'partial'
                ? 50
                : 0,
          }),
      ],
      'owner',
      200,
    );
    await commit([change('unpaid', 'exempt')], token('resident'), 403);
    await commit([change('unpaid', 'exempt')], token('outsider'), 403);
    await commit([change('partial', 'exempt', paid: 0)], token('manager'), 403);
    await commit([change('paid', 'exempt', paid: 0)], token('manager'), 403);
    await commit([change('exempt', 'paid', paid: 150)], token('manager'), 403);
    await commit([change('exempt', 'unpaid')], token('manager'), 403);
    await commit([change('unpaid', 'exempt')], token('manager'), 200);
    stdout.writeln('All 7 exemption security rule checks passed.');
  } finally {
    client.close(force: true);
  }
}
