import 'dart:convert';
import 'dart:io';

import 'package:darjar_phone_verification/src/professional_profiles.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _project = 'demo-darjar';
const _root = '/v1/projects/$_project/databases/(default)/documents';

void main() {
  final firestoreHost = Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '';
  final authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'] ?? '';
  final localhost = RegExp(r'^(localhost|127\.0\.0\.1):\d+$');
  final useEmulators =
      localhost.hasMatch(firestoreHost) && localhost.hasMatch(authHost);
  late ProfessionalProfiles profiles;
  late _EmulatorAdminClient admin;

  setUp(() {
    admin = _EmulatorAdminClient();
    profiles = ProfessionalProfiles(
      projectId: _project,
      client: admin,
      firestoreOrigin: Uri.http(firestoreHost),
    );
    addTearDown(admin.close);
  });

  Future<void> put(String path, Map<String, Object?> fields) async {
    final result = await admin.patch(
      Uri.http(firestoreHost, '$_root/$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'fields': fields.map((key, value) => MapEntry(key, _encode(value))),
      }),
    );
    expect(result.statusCode, 200, reason: result.body);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final result = await admin.get(Uri.http(firestoreHost, '$_root/$path'));
    expect(result.statusCode, 200, reason: result.body);
    return (jsonDecode(result.body) as Map<String, dynamic>)['fields']
        as Map<String, dynamic>;
  }

  Future<void> createCategory() => put('serviceCategories/electrical', {
    'subcategoryIds': ['repair'],
  });

  Future<void> seedListing(String id, String phone, {String? owner}) =>
      put('services/$id', {
        'name': 'Existing $id',
        'profession': 'Electrician',
        'phone': phone,
        'city': '6141010',
        'neighborhood': 'District',
        'createdBy': 'resident',
        'categoryId': 'electrical',
        'subcategoryIds': ['repair'],
        'status': 'active',
        'ownerUid': ?owner,
      });

  const personalName = {'firstName': 'Amal', 'lastName': 'Alami'};
  const draft = {
    ...personalName,
    'name': 'Electrical services',
    'categoryId': 'electrical',
    'subcategoryIds': ['repair'],
    'city': '6141010',
    'profession': 'Electrician',
    'phone': '+212600000099',
  };

  test('normalizes directory numbers to E.164 without accepting text', () {
    for (final number in [
      '+212612345678',
      '00212612345678',
      '212612345678',
      '06 12 34 56 78',
      '+212 6 12 34 56 78',
    ]) {
      expect(normalizeDirectoryPhone(number), '+212612345678');
    }
    expect(normalizeDirectoryPhone('+212612345678 ext 1'), isNull);
    expect(normalizeDirectoryPhone('123'), isNull);
  });

  group(
    'professional profiles on Firebase',
    () {
      test(
        'creates a city listing and account atomically without a residence or recommendations',
        () async {
          await createCategory();
          const identity = (uid: 'professional-create', phone: '+212600001010');
          await expectLater(
            profiles.create(identity, {
              ...draft,
              'subcategoryIds': ['invalid'],
            }),
            throwsA(
              isA<ProfessionalFailure>().having(
                (error) => error.code,
                'code',
                'invalid-service',
              ),
            ),
          );
          expect(
            (await admin.get(
              Uri.http(firestoreHost, '$_root/users/${identity.uid}'),
            )).statusCode,
            404,
          );

          final id = await profiles.create(identity, draft);
          final listing = await get('services/$id');
          final user = await get('users/${identity.uid}');
          expect(listing['phone'], _encode(identity.phone));
          expect(listing['source'], _encode('professional'));
          expect(listing['createdFromResidenceId'], isNull);
          expect(listing['recommendationCount'], isNull);
          expect(user['activeResidenceId'], isNull);
          expect(user['activeSpaceType'], _encode('professional'));
          expect(user['professionalServiceId'], _encode(id));
          expect(await profiles.create(identity, draft), id);
        },
      );

      test(
        'keeps the existing ID, fields and reviews, and requires choosing one matching listing',
        () async {
          const identity = (uid: 'professional-claim', phone: '+212600001011');
          await seedListing('claim-a', '06 00 00 10 11');
          await seedListing('claim-b', identity.phone);
          await seedListing(
            'claim-owned',
            identity.phone,
            owner: 'someone-else',
          );
          await put('directoryRecommendations/claim-a_r_resident', {
            'entryId': 'claim-a',
            'comment': 'Original resident review',
          });
          final result = await profiles.discover(identity);
          expect(
            (result['candidates'] as List).map((candidate) => candidate['id']),
            unorderedEquals(['claim-a', 'claim-b']),
          );
          await expectLater(
            profiles.create(identity, draft),
            throwsA(
              isA<ProfessionalFailure>().having(
                (error) => error.code,
                'code',
                'directory-phone-exists',
              ),
            ),
          );
          await expectLater(
            profiles.claim(identity, 'claim-owned', personalName),
            throwsA(
              isA<ProfessionalFailure>().having(
                (error) => error.code,
                'code',
                'service-not-claimable',
              ),
            ),
          );
          expect(
            await profiles.claim(identity, 'claim-a', personalName),
            'claim-a',
          );
          expect(
            await profiles.claim(identity, 'claim-a', personalName),
            'claim-a',
          );
          expect(
            (await get('services/claim-a'))['createdBy'],
            _encode('resident'),
          );
          expect(
            (await get('services/claim-a'))['phone'],
            _encode('06 00 00 10 11'),
          );
          expect(
            (await get(
              'directoryRecommendations/claim-a_r_resident',
            ))['comment'],
            _encode('Original resident review'),
          );
          expect((await get('services/claim-b'))['ownerUid'], isNull);
          expect(
            (await get('services/claim-owned'))['ownerUid'],
            _encode('someone-else'),
          );
          await expectLater(
            profiles.claim(identity, 'claim-b', personalName),
            throwsA(
              isA<ProfessionalFailure>().having(
                (error) => error.code,
                'code',
                'already-owns-service',
              ),
            ),
          );
          expect((await profiles.discover(identity))['candidates'], isEmpty);
        },
      );

      test(
        'serializes competing claims and rejects a nonmatching phone',
        () async {
          const phone = '+212600001012';
          await seedListing('claim-race', phone);
          await expectLater(
            profiles.claim(
              (uid: 'wrong-number', phone: '+212600001013'),
              'claim-race',
              personalName,
            ),
            throwsA(
              isA<ProfessionalFailure>().having(
                (error) => error.code,
                'code',
                'service-not-claimable',
              ),
            ),
          );
          Future<String?> attempt(String uid) async {
            try {
              await profiles.claim(
                (uid: uid, phone: phone),
                'claim-race',
                personalName,
              );
              return uid;
            } on ProfessionalFailure catch (error) {
              expect(
                error.code,
                anyOf('already-owns-service', 'service-not-claimable'),
              );
              return null;
            }
          }

          final results = await Future.wait([
            attempt('race-a'),
            attempt('race-b'),
          ]);
          final winner = results.whereType<String>().single;
          expect(
            (await get('services/claim-race'))['ownerUid'],
            _encode(winner),
          );
        },
      );

      test(
        'only the owner can delete a listing while preserving the account and residences',
        () async {
          const identity = (uid: 'professional-delete', phone: '+212600001015');
          const service = 'delete-claimed-listing';
          const residence = 'delete-test-residence';
          await createCategory();
          await put('users/${identity.uid}', {
            ...personalName,
            'phoneNumber': identity.phone,
            'activeResidenceId': residence,
          });
          await put('residences/$residence/members/${identity.uid}', {
            'status': 'active',
            'role': 'resident',
          });
          await seedListing(service, '06 00 00 10 15');
          await profiles.claim(identity, service, const {});
          await expectLater(
            profiles.delete((
              uid: 'other-user',
              phone: '+212600001016',
            ), service),
            throwsA(
              isA<ProfessionalFailure>()
                  .having((error) => error.code, 'code', 'not-service-owner')
                  .having((error) => error.status, 'status', 403),
            ),
          );
          expect(
            (await get('services/$service'))['ownerUid'],
            _encode(identity.uid),
          );
          await profiles.delete(identity, service);

          for (final path in [
            'services/$service',
            'professionalPhones/${identity.phone}',
          ]) {
            final response = await admin.get(
              Uri.http(firestoreHost, '$_root/$path'),
            );
            expect(response.statusCode, 404, reason: path);
          }
          final account = await get('users/${identity.uid}');
          expect(account['firstName'], _encode('Amal'));
          expect(account['phoneNumber'], _encode(identity.phone));
          expect(account['activeResidenceId'], _encode(residence));
          expect(account, isNot(contains('professionalServiceId')));
          expect(account, isNot(contains('activeSpaceType')));
          final membership = await get(
            'residences/$residence/members/${identity.uid}',
          );
          expect(membership['status'], _encode('active'));
          final newId = await profiles.create(identity, draft);
          await profiles.delete(identity, newId);
          final replacementId = await profiles.create(identity, draft);
          expect(replacementId, isNot(newId));
          await profiles.delete(identity, newId);
          expect(
            (await get('users/${identity.uid}'))['professionalServiceId'],
            _encode(replacementId),
          );
          expect(
            (await get('services/$replacementId'))['ownerUid'],
            _encode(identity.uid),
          );
        },
      );

      test(
        'pauses and reactivates a rated service and refuses its deletion',
        () async {
          const identity = (uid: 'rated-service-owner', phone: '+212600001017');
          const other = (uid: 'nonowner', phone: '+212600001018');
          await createCategory();
          final id = await profiles.create(identity, draft);
          final path = 'services/$id';
          final original = await get(path);
          final failure = throwsA(
            isA<ProfessionalFailure>()
                .having((error) => error.code, 'code', 'service-has-feedback')
                .having((error) => error.status, 'status', 409),
          );
          final score = {'doubleValue': 4.0};
          final setScore = await admin.patch(
            Uri.http(firestoreHost, '$_root/$path', {
              'updateMask.fieldPaths': 'score',
            }),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'fields': {'score': score},
            }),
          );
          expect(setScore.statusCode, 200, reason: setScore.body);
          await expectLater(profiles.delete(identity, id), failure);
          final clearScore = await admin.patch(
            Uri.http(firestoreHost, '$_root/$path', {
              'updateMask.fieldPaths': 'score',
            }),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'fields': <String, Object?>{}}),
          );
          expect(clearScore.statusCode, 200, reason: clearScore.body);
          const reviewPath = 'directoryRecommendations/rated-service-review';
          await put(reviewPath, {
            'entryId': id,
            'comment': 'Original resident review',
          });
          await expectLater(profiles.delete(identity, id), failure);
          await expectLater(
            profiles.setPaused(other, id, paused: true),
            throwsA(
              isA<ProfessionalFailure>().having(
                (error) => error.status,
                'status',
                403,
              ),
            ),
          );
          await profiles.setPaused(identity, id, paused: true);
          expect((await get(path))['status'], _encode('paused'));
          expect(await profiles.create(identity, draft), id);
          expect((await get(path))['status'], _encode('paused'));
          await expectLater(profiles.delete(identity, id), failure);

          Future<List<String>> cityDirectoryIds() async {
            final result = await admin.post(
              Uri.http(firestoreHost, '$_root:runQuery'),
              headers: {'content-type': 'application/json'},
              body: jsonEncode({
                'structuredQuery': {
                  'from': [
                    {'collectionId': 'services'},
                  ],
                  'where': {
                    'compositeFilter': {
                      'op': 'AND',
                      'filters': [
                        for (final (field, value) in [
                          ('city', '6141010'),
                          ('status', 'active'),
                        ])
                          {
                            'fieldFilter': {
                              'field': {'fieldPath': field},
                              'op': 'EQUAL',
                              'value': _encode(value),
                            },
                          },
                      ],
                    },
                  },
                  'orderBy': [
                    {
                      'field': {'fieldPath': 'createdAt'},
                      'direction': 'DESCENDING',
                    },
                  ],
                },
              }),
            );
            expect(result.statusCode, 200, reason: result.body);
            return [
              for (final row in (jsonDecode(result.body) as List))
                if (row['document'] case final Map document)
                  (document['name'] as String).split('/').last,
            ];
          }

          expect(await cityDirectoryIds(), isNot(contains(id)));
          await profiles.setPaused(identity, id, paused: false);
          expect(await cityDirectoryIds(), contains(id));
          expect(
            (await get(reviewPath))['comment'],
            _encode('Original resident review'),
          );
          expect((await get(path))['name'], original['name']);
          expect(
            (await get('users/${identity.uid}'))['professionalServiceId'],
            _encode(id),
          );
        },
      );

      test(
        'rules block direct ownership grants, protect resident reviews and permit owned service edits',
        () async {
          await createCategory();
          const phone = '+212600001014';
          const uid = 'professional-rules';
          final account = await admin.post(
            Uri.http(
              authHost,
              '/identitytoolkit.googleapis.com/v1/projects/$_project/accounts',
            ),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'localId': uid, 'phoneNumber': phone}),
          );
          expect(account.statusCode, 200, reason: account.body);
          final signIn = await admin.post(
            Uri.http(
              authHost,
              '/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken',
              {'key': _project},
            ),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'token': jsonEncode({
                'uid': uid,
                'claims': {'phone_number': phone},
              }),
              'returnSecureToken': true,
            }),
          );
          expect(signIn.statusCode, 200, reason: signIn.body);
          final token = (jsonDecode(signIn.body) as Map)['idToken'] as String;
          final client = http.Client();
          addTearDown(client.close);
          Future<int> update(
            String path,
            Map<String, Object?> fields, {
            String timestamp = 'updatedAt',
          }) async {
            final result = await client.post(
              Uri.http(firestoreHost, '$_root:commit'),
              headers: {
                'authorization': 'Bearer $token',
                'content-type': 'application/json',
              },
              body: jsonEncode({
                'writes': [
                  {
                    'update': {
                      'name':
                          'projects/$_project/databases/(default)/documents/$path',
                      'fields': fields.map(
                        (key, value) => MapEntry(key, _encode(value)),
                      ),
                    },
                    'updateMask': {'fieldPaths': fields.keys.toList()},
                    'updateTransforms': [
                      {
                        'fieldPath': timestamp,
                        'setToServerValue': 'REQUEST_TIME',
                      },
                    ],
                  },
                ],
              }),
            );
            return result.statusCode;
          }

          await seedListing('rules-listing', phone);
          expect(
            await update('services/rules-listing', {'ownerUid': uid}),
            403,
          );
          await profiles.claim(
            (uid: uid, phone: phone),
            'rules-listing',
            personalName,
          );
          expect(
            await update('services/rules-listing', {
              'name': 'Updated listing',
              'city': '4421010',
            }),
            200,
          );
          final directDelete = await client.delete(
            Uri.http(firestoreHost, '$_root/services/rules-listing'),
            headers: {'authorization': 'Bearer $token'},
          );
          expect(directDelete.statusCode, 403);
          expect(
            await update('services/rules-listing', {'phone': '+212600001099'}),
            403,
          );
          expect(
            await update('users/$uid', {'professionalServiceId': 'other'}),
            403,
          );
          expect(
            await update('users/$uid', {
              'activeResidenceId': 'unrelated',
              'activeSpaceType': 'residence',
            }),
            403,
          );
          await put('residences/rules-residence', {'name': 'Residence'});
          await put('residences/rules-residence/members/$uid', {
            'status': 'active',
            'role': 'resident',
          });
          expect(
            await update('users/$uid', {
              'activeResidenceId': 'rules-residence',
              'activeSpaceType': 'residence',
            }),
            200,
          );
          expect(
            await update('services/rules-listing', {'status': 'paused'}),
            403,
          );
          await profiles.setPaused(
            (uid: uid, phone: phone),
            'rules-listing',
            paused: true,
          );
          final paused = await client.get(
            Uri.http(firestoreHost, '$_root/services/rules-listing'),
            headers: {'authorization': 'Bearer $token'},
          );
          expect(paused.statusCode, 200, reason: paused.body);
          expect(
            await update('users/$uid', {'activeSpaceType': 'professional'}),
            200,
          );
          const otherListing = 'rules-other-listing';
          const otherOwner = (uid: 'rules-other-owner', phone: '+212600001019');
          await seedListing(otherListing, otherOwner.phone);
          await profiles.claim(otherOwner, otherListing, personalName);
          final otherReview = {
            'entryId': otherListing,
            'residenceId': 'rules-residence',
            'userId': uid,
            'authorName': 'Resident',
            'residenceName': 'Residence',
            'comment': 'Public review',
          };
          expect(
            await update(
              'directoryRecommendations/rules-other-active-review',
              otherReview,
              timestamp: 'createdAt',
            ),
            200,
          );
          await profiles.setPaused(otherOwner, otherListing, paused: true);
          final hidden = await client.get(
            Uri.http(firestoreHost, '$_root/services/$otherListing'),
            headers: {'authorization': 'Bearer $token'},
          );
          expect(hidden.statusCode, 403, reason: hidden.body);
          expect(
            await update(
              'directoryRecommendations/rules-other-paused-review',
              otherReview,
              timestamp: 'createdAt',
            ),
            403,
          );
          await put('directoryRecommendations/rules-review', {
            'entryId': 'rules-listing',
            'residenceId': 'rules-residence',
            'userId': uid,
            'authorName': 'Original author',
            'residenceName': 'Residence',
            'comment': 'Original review',
          });
          expect(
            await update('directoryRecommendations/rules-review', {
              'comment': 'Changed review',
            }, timestamp: 'createdAt'),
            403,
          );
        },
      );
    },
    skip: useEmulators
        ? false
        : 'Requires local Firebase Auth and Firestore emulators.',
  );
}

Object _encode(Object? value) => switch (value) {
  String text => {'stringValue': text},
  List list => {
    'arrayValue': {'values': list.map(_encode).toList()},
  },
  _ => throw ArgumentError.value(value),
};

class _EmulatorAdminClient extends http.BaseClient {
  final _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('authorization', () => 'Bearer owner');
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
