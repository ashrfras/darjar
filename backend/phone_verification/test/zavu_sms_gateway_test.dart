import 'dart:convert';

import 'package:darjar_phone_verification/src/zavu_sms_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('lets the sender route SMS with bearer auth and idempotency', () async {
    late http.Request captured;
    final gateway = HttpZavuSmsGateway(
      apiKey: 'zv_test_key',
      senderId: 'sender_darjar',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'message': {'id': 'message-1', 'status': 'queued'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await gateway.sendCode(
      phoneNumber: '+212600000001',
      code: '123456',
      idempotencyKey: 'session-1',
      languageCode: 'ar',
    );

    expect(captured.url.toString(), 'https://api.zavu.dev/v1/messages');
    expect(captured.headers['authorization'], 'Bearer zv_test_key');
    expect(captured.headers['zavu-sender'], 'sender_darjar');
    expect(captured.headers['idempotency-key'], 'phone-verification-session-1');
    final body = jsonDecode(captured.body) as Map<String, Object?>;
    expect(body['to'], '+212600000001');
    expect(body, isNot(contains('channel')));
    expect(body['fallbackEnabled'], isFalse);
    expect(body['text'], contains('123456'));
  });
}
