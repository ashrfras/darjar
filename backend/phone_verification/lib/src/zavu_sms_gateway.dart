import 'dart:convert';

import 'package:http/http.dart' as http;

import 'phone_verification_service.dart';

class HttpZavuSmsGateway implements VerificationSmsGateway {
  HttpZavuSmsGateway({
    required String apiKey,
    String? senderId,
    http.Client? client,
    Uri? apiBase,
  }) : this._(
         apiKey,
         senderId,
         client ?? http.Client(),
         apiBase ?? Uri.parse('https://api.zavu.dev'),
       );

  HttpZavuSmsGateway._(
    this._apiKey,
    this._senderId,
    this._client,
    this._apiBase,
  );

  final String _apiKey;
  final String? _senderId;
  final http.Client _client;
  final Uri _apiBase;

  @override
  Future<void> sendCode({
    required String phoneNumber,
    required String code,
    required String idempotencyKey,
    required String languageCode,
  }) async {
    final headers = {
      'authorization': 'Bearer $_apiKey',
      'content-type': 'application/json',
      'accept': 'application/json',
      'idempotency-key': 'phone-verification-$idempotencyKey',
    };
    final senderId = _senderId;
    if (senderId != null) headers['zavu-sender'] = senderId;
    final response = await _client.post(
      _apiBase.resolve('/v1/messages'),
      headers: headers,
      body: jsonEncode({
        'to': phoneNumber,
        'fallbackEnabled': false,
        'text': languageCode == 'en'
            ? 'DarJar verification code: $code. Valid for 10 minutes.'
            : 'DarJar: رمز التحقق هو $code. صالح لمدة 10 دقائق.',
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw _failure(response);
  }

  VerificationFailure _failure(http.Response response) {
    final body = _jsonObject(response.body);
    final providerMessage =
        body['message'] ?? body['error'] ?? body['detail'] ?? 'unknown';
    final message = 'Zavu ${response.statusCode}: $providerMessage';
    if (response.statusCode == 429) {
      return VerificationFailure('too-many-requests', message: message);
    }
    if (response.statusCode == 400 || response.statusCode == 422) {
      return VerificationFailure('invalid-phone-number', message: message);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return VerificationFailure(
        'authentication-service-error',
        message: message,
      );
    }
    return VerificationFailure('verification-provider-error', message: message);
  }
}

Map<String, Object?> _jsonObject(String value) {
  try {
    return jsonDecode(value) as Map<String, Object?>;
  } on Object {
    return const {};
  }
}
