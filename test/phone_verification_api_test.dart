import 'dart:convert';

import 'package:darjar/features/auth/data/phone_verification_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('local start returns a custom token and forwards its secret', () async {
    final client = MockClient((request) async {
      expect(request.headers['x-darjar-local-auth'], 'local-secret');
      expect(
        jsonDecode(request.body),
        containsPair('phoneNumber', '+212708708001'),
      );
      return http.Response(
        jsonEncode({'customToken': 'firebase-custom-token'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = PhoneVerificationApi(
      baseUrl: 'https://verification.example',
      client: client,
    );

    final result = await api.start(
      '+212708708001',
      languageCode: 'ar',
      localDevelopmentSecret: 'local-secret',
    );

    expect(result.customToken, 'firebase-custom-token');
    expect(result.sessionId, isNull);
  });

  test('regular start still returns an SMS verification session', () async {
    final client = MockClient((request) async {
      expect(request.headers, isNot(contains('x-darjar-local-auth')));
      return http.Response(
        jsonEncode({'sessionId': 'verification-session'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = PhoneVerificationApi(
      baseUrl: 'https://verification.example',
      client: client,
    );

    final result = await api.start('+212600000001', languageCode: 'ar');

    expect(result.sessionId, 'verification-session');
    expect(result.customToken, isNull);
  });
}
