import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_failure.dart';

class PhoneVerificationApi {
  PhoneVerificationApi({required String baseUrl, http.Client? client})
    : _baseUri = Uri.parse(baseUrl),
      _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Future<String> start(
    String phoneNumber, {
    required String languageCode,
  }) async {
    final body = await _post('/v1/phone-verifications', {
      'phoneNumber': phoneNumber,
      'languageCode': languageCode,
    }, expectedStatus: 201);
    final sessionId = body['sessionId'] as String?;
    if (sessionId == null || sessionId.isEmpty) {
      throw const AuthFailure('authentication-service-error');
    }
    return sessionId;
  }

  Future<String> check({
    required String sessionId,
    required String code,
  }) async {
    final body = await _post(
      '/v1/phone-verifications/${Uri.encodeComponent(sessionId)}/check',
      {'code': code},
      expectedStatus: 200,
    );
    final customToken = body['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw const AuthFailure('authentication-service-error');
    }
    return customToken;
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> requestBody, {
    required int expectedStatus,
  }) async {
    if (!_baseUri.hasScheme || !_baseUri.hasAuthority) {
      throw const AuthFailure('verification-service-not-configured');
    }
    try {
      final response = await _client
          .post(
            _baseUri.resolve(path),
            headers: const {
              'content-type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      final body = _decodeObject(response.body);
      if (response.statusCode != expectedStatus) {
        final code = body['code'] as String? ?? 'authentication-service-error';
        throw AuthFailure(code, message: 'HTTP ${response.statusCode}');
      }
      return body;
    } on AuthFailure {
      rethrow;
    } on TimeoutException catch (error) {
      throw AuthFailure('network-request-failed', message: error.toString());
    } on http.ClientException catch (error) {
      throw AuthFailure('network-request-failed', message: error.message);
    } catch (error) {
      throw AuthFailure('network-request-failed', message: error.toString());
    }
  }
}

Map<String, Object?> _decodeObject(String value) {
  try {
    return jsonDecode(value) as Map<String, Object?>;
  } on Object {
    return const {};
  }
}
