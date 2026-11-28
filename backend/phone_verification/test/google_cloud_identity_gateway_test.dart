import 'dart:convert';

import 'package:darjar_phone_verification/src/google_cloud_identity_gateway.dart';
import 'package:darjar_phone_verification/src/http_api.dart';
import 'package:darjar_phone_verification/src/professional_profiles.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  const projectId = 'demo-darjar';
  const uid = 'local-development-user';
  const authTime = 1700000000;
  final claims = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': uid,
        'aud': projectId,
        'iss': 'https://securetoken.google.com/$projectId',
        'auth_time': authTime,
        'phone_number': localDevelopmentPhoneNumber,
        'firebase': {'sign_in_provider': 'custom'},
      }),
    ),
  );
  final token = 'header.$claims.signature';
  final invalidIdentity = isA<ProfessionalFailure>().having(
    (error) => error.code,
    'code',
    'invalid-identity',
  );

  Future<void> withIdentityLookup(
    http.Response response,
    Future<void> Function(GoogleCloudIdentityGateway gateway) verify,
  ) async {
    final client = MockClient((request) async {
      expect(request.url.host, 'identitytoolkit.googleapis.com');
      expect(request.url.path, '/v1/accounts:lookup');
      expect(jsonDecode(request.body), {'idToken': token});
      return response;
    });
    addTearDown(client.close);
    await http.runWithClient(
      () => verify(
        GoogleCloudIdentityGateway(
          projectId: projectId,
          apiKey: 'test-api-key',
          signerEmail: 'signer@example.test',
          client: client,
        ),
      ),
      () => client,
    );
  }

  test(
    'local development identity is accepted for residence deletion',
    () async {
      await withIdentityLookup(
        http.Response(
          jsonEncode({
            'users': [
              {'localId': uid, 'phoneNumber': localDevelopmentPhoneNumber},
            ],
          }),
          200,
        ),
        (gateway) async {
          expect(await gateway.verifyResidenceDeletionToken(token), uid);
          await expectLater(
            gateway.verifyProfessionalToken(token),
            throwsA(invalidIdentity),
          );
        },
      );
    },
  );

  test('residence deletion rejects a token rejected by Firebase', () async {
    await withIdentityLookup(http.Response('{}', 400), (gateway) async {
      await expectLater(
        gateway.verifyResidenceDeletionToken(token),
        throwsA(invalidIdentity),
      );
    });
  });
}
