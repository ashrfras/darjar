// firebase emulators:exec --only firestore --project demo-darjar \
//   'dart run tool/test_presidency_rules.dart'
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final host = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  if (host == null ||
      !RegExp(r'^(127\.0\.0\.1|localhost):\d+$').hasMatch(host)) {
    throw StateError('A local Firestore emulator is required.');
  }

  const project = 'demo-darjar';
  const root = 'projects/$project/databases/(default)/documents';
  const residence = 'residences/presidency-rules-test';
  const creator = 'creator';
  const neighbor = 'neighbor';
  const delegated = 'delegated';
  const inactive = 'inactive';
  String member(String id) => '$residence/members/$id';
  String eventPath(String id) => 'appActivityLog/$id';

  final client = HttpClient();
  Map<String, Object?> write(
    String path,
    Map<String, Object?> data, {
    String? timestamp,
    bool patch = false,
  }) => {
    'update': {
      'name': '$root/$path',
      'fields': {
        for (final entry in data.entries)
          entry.key: switch (entry.value) {
            final String value => {'stringValue': value},
            final bool value => {'booleanValue': value},
            null => {'nullValue': null},
            _ => throw ArgumentError.value(entry.value),
          },
      },
    },
    if (patch) 'updateMask': {'fieldPaths': data.keys.toList()},
    if (timestamp != null)
      'updateTransforms': [
        {'fieldPath': timestamp, 'setToServerValue': 'REQUEST_TIME'},
      ],
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
    String scenario,
    List<Map<String, Object?>> writes,
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
      throw StateError(
        '$scenario: expected $expected, got ${response.statusCode}: $body',
      );
    }
  }

  Map<String, Object?> roleWrite(String uid, String role) => write(
    member(uid),
    {'role': role, 'hasPresidentPermissions': false},
    patch: true,
    timestamp: 'updatedAt',
  );

  List<Map<String, Object?>> transition({
    required String actor,
    required String target,
    String? previous,
    required String event,
    bool includeDemotion = true,
    bool includeActivity = true,
  }) => [
    write(
      residence,
      {'presidentId': target, 'presidencyEventId': event},
      patch: true,
      timestamp: 'updatedAt',
    ),
    roleWrite(target, 'president'),
    if (previous != null && includeDemotion) roleWrite(previous, 'resident'),
    if (includeActivity)
      write(eventPath(event), {
        'type': previous == null
            ? 'residencePresidentAppointed'
            : 'residencePresidentChanged',
        'residenceId': 'presidency-rules-test',
        'actorId': actor,
        'userId': target,
        'previousPresidentId': previous,
      }, timestamp: 'occurredAt'),
  ];

  const firstEvent = 'PresidencyEvent00001';
  const secondEvent = 'PresidencyEvent00002';
  const thirdEvent = 'PresidencyEvent00003';
  try {
    await commit(
      'seed',
      [
        write(residence, {'presidentId': null, 'createdBy': creator}),
        for (final uid in [creator, neighbor, delegated, inactive])
          write(member(uid), {
            'role': 'resident',
            'status': uid == inactive ? 'removed' : 'active',
            'hasPresidentPermissions': uid == delegated,
          }),
      ],
      'owner',
      200,
    );

    await commit(
      'ordinary resident cannot appoint themselves',
      transition(actor: neighbor, target: neighbor, event: firstEvent),
      token(neighbor),
      403,
    );
    await commit(
      'inactive resident cannot be appointed',
      transition(actor: creator, target: inactive, event: firstEvent),
      token(creator),
      403,
    );
    final appointment = transition(
      actor: creator,
      target: creator,
      event: firstEvent,
    );
    await commit(
      'audit entry cannot be forged',
      [appointment.last],
      token(creator),
      403,
    );
    await commit('initial self-appointment', appointment, token(creator), 200);
    await commit(
      'initial appointment cannot be repeated',
      appointment,
      token(creator),
      403,
    );
    await commit(
      'transfer requires demotion',
      transition(
        actor: creator,
        target: neighbor,
        previous: creator,
        event: secondEvent,
        includeDemotion: false,
      ),
      token(creator),
      403,
    );
    await commit(
      'transfer requires activity',
      transition(
        actor: creator,
        target: neighbor,
        previous: creator,
        event: secondEvent,
        includeActivity: false,
      ),
      token(creator),
      403,
    );
    await commit(
      'delegate cannot transfer',
      transition(
        actor: delegated,
        target: delegated,
        previous: creator,
        event: secondEvent,
      ),
      token(delegated),
      403,
    );
    await commit(
      'president transfers in one commit',
      transition(
        actor: creator,
        target: neighbor,
        previous: creator,
        event: secondEvent,
      ),
      token(creator),
      200,
    );
    await commit(
      'former president loses transfer permission',
      transition(
        actor: creator,
        target: delegated,
        previous: creator,
        event: thirdEvent,
      ),
      token(creator),
      403,
    );
    await commit(
      'new president can transfer',
      transition(
        actor: neighbor,
        target: creator,
        previous: neighbor,
        event: thirdEvent,
      ),
      token(neighbor),
      200,
    );
    await commit(
      'seed a residence awaiting appointment',
      [
        write(residence, {'presidentId': null, 'createdBy': creator}),
        roleWrite(creator, 'resident'),
      ],
      'owner',
      200,
    );
    await commit(
      'creator may appoint another joined resident',
      transition(
        actor: creator,
        target: neighbor,
        event: 'PresidencyEvent00004',
      ),
      token(creator),
      200,
    );
    stdout.writeln('Presidency security rule checks passed.');
  } finally {
    client.close(force: true);
  }
}
