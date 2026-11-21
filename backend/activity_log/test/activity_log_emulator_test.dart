import 'dart:convert';
import 'dart:io';

import 'package:darjar_activity_log/activity_log.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:firebase_functions/firebase_functions.dart' show Request;
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:test/test.dart';

void main() {
  const project = 'demo-darjar';
  final environment = Platform.environment;
  final localHost = RegExp(r'^(localhost|127\.0\.0\.1):\d+$');
  final firestoreHost = environment['FIRESTORE_EMULATOR_HOST'] ?? '';
  final authHost = environment['FIREBASE_AUTH_EMULATOR_HOST'] ?? '';
  final useEmulators =
      localHost.hasMatch(firestoreHost) && localHost.hasMatch(authHost);

  test(
    'developer signed in without SMS can read ordered, minimal pages',
    () async {
      final app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: project),
      );
      addTearDown(() => FirebaseApp.deleteApp(app));
      final auth = app.auth();
      final firestore = app.firestore();
      final user = await auth.createUser(
        CreateRequest(
          uid: 'activity-log-test-developer',
          phoneNumber: '+15551234567',
        ),
      );
      final grant = firestore.doc('appPermissions/${user.uid}');
      final handler = ActivityLog(firestore, auth);
      final url = Uri.parse('http://localhost/appactivitylog');

      Request request({String? token, Map<String, String>? query}) => Request(
        'GET',
        url.replace(queryParameters: query),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      );
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final testSession = await _signInWithoutSms(
        client,
        authHost,
        project,
        user,
      );

      expect((await handler.handle(request())).statusCode, 401);
      expect((await handler.handle(request(token: 'invalid'))).statusCode, 401);
      expect(
        (await handler.handle(request(token: testSession))).statusCode,
        403,
      );

      await grant.set({
        'developer': true,
        'authCreatedAt': Timestamp.fromDate(user.metadata.creationTime),
      });
      final access = await handler.handle(
        request(token: testSession, query: {'access': 'true'}),
      );
      expect(jsonDecode(await access.readAsString()), {'developer': true});

      final batch = firestore.batch();
      batch.set(firestore.doc('users/resident'), {
        'firstName': ' فاطمة ',
        'lastName': 'العلمي',
        'phoneNumber': '+212612345678',
        'privateNotes': 'must not be exposed',
      });
      batch.set(firestore.doc('residences/residence'), {
        'name': 'إقامة النخيل',
        'address': 'must not be exposed',
      });
      final occurredAt = Timestamp(seconds: 1795132801, nanoseconds: 123456000);
      final ids = [
        for (var index = 0; index < 31; index++)
          index.toRadixString(16).padLeft(64, '0'),
      ];
      for (final id in ids) {
        batch.set(firestore.doc('appActivityLog/$id'), {
          'type': 'residentJoined',
          'occurredAt': occurredAt,
          'userId': id == ids.first ? 'deleted-profile' : 'resident',
          'residenceId': id == ids.first ? 'deleted-residence' : 'residence',
          'unrecognizedField': 'must not be exposed',
        });
      }
      await batch.commit();
      final firstPage = await handler.handle(request(token: testSession));
      expect(firstPage.statusCode, 200);
      expect(firstPage.headers['cache-control'], 'no-store');
      final first = jsonDecode(await firstPage.readAsString()) as Map;
      final events = first['events'] as List;
      expect(
        events.map((event) => (event as Map)['id']),
        ids.reversed.take(30),
      );
      expect(events.first, {
        'id': ids.last,
        'type': 'residentJoined',
        'occurredAt': occurredAt.toDate().toUtc().toIso8601String(),
        'residentName': 'فاطمة العلمي',
        'phoneNumber': '+212612345678',
        'residenceId': 'residence',
        'residenceName': 'إقامة النخيل',
      });
      final second = await handler.handle(
        request(
          token: testSession,
          query: {'cursor': first['nextCursor'] as String},
        ),
      );
      final body = jsonDecode(await second.readAsString()) as Map;
      final missingDetails = (body['events'] as List).single as Map;
      expect(missingDetails['id'], ids.first);
      expect(missingDetails['residenceId'], 'deleted-residence');
      expect(
        missingDetails.keys,
        unorderedEquals(['id', 'type', 'occurredAt', 'residenceId']),
      );
      expect(body['nextCursor'], isNull);

      const path = '/v1/projects/$project/databases/(default)/documents';
      for (final document in [
        '/appPermissions/${user.uid}',
        '/appActivityLog/${ids.first}',
      ]) {
        for (final method in ['GET', 'PATCH', 'DELETE']) {
          final direct = await client.openUrl(
            method,
            Uri.parse('http://$firestoreHost$path$document'),
          );
          direct.headers.set('authorization', 'Bearer $testSession');
          if (method == 'PATCH') {
            direct.headers.contentType = ContentType.json;
            direct.write('{"fields":{"developer":{"booleanValue":true}}}');
          }
          final response = await direct.close();
          await response.drain<void>();
          expect(response.statusCode, 403, reason: '$method $document');
        }
      }

      await grant.update({'developer': false});
      expect(
        (await handler.handle(request(token: testSession))).statusCode,
        403,
      );
    },
    skip: useEmulators
        ? false
        : 'Requires local Firebase Auth and Firestore emulators.',
  );
}

Future<String> _signInWithoutSms(
  HttpClient client,
  String authHost,
  String project,
  UserRecord user,
) async {
  final request = await client.postUrl(
    Uri.http(
      authHost,
      '/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken',
      {'key': project},
    ),
  );
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'token': jsonEncode({
        'uid': user.uid,
        'claims': {'phone_number': user.phoneNumber, 'phone_verified': true},
      }),
      'returnSecureToken': true,
    }),
  );
  final response = await request.close();
  final body = jsonDecode(await utf8.decoder.bind(response).join()) as Map;
  expect(response.statusCode, 200);
  return body['idToken'] as String;
}
