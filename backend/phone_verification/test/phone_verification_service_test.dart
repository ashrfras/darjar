import 'package:darjar_phone_verification/src/phone_verification_service.dart';
import 'package:test/test.dart';

void main() {
  const regularPhoneNumber = '+212600000002';
  late _FakeSmsGateway sms;
  late _MemorySessions sessions;
  late _FakeIdentity identity;
  late PhoneVerificationService service;

  setUp(() {
    sms = _FakeSmsGateway();
    sessions = _MemorySessions();
    identity = _FakeIdentity();
    service = PhoneVerificationService(
      sms: sms,
      sessions: sessions,
      firebaseIdentity: identity,
      otpHashPepper: 'test-pepper-that-is-at-least-32-characters',
      now: () => DateTime.utc(2026, 8, 4, 12),
      newSessionId: () => 'A' * 43,
      newCode: () => '123456',
    );
  });

  test(
    'stores only a hash and sends the code through the SMS gateway',
    () async {
      final sessionId = await service.start(
        regularPhoneNumber,
        languageCode: 'ar',
      );

      expect(sessionId, 'A' * 43);
      expect(sms.sentPhone, regularPhoneNumber);
      expect(sms.sentCode, '123456');
      expect(sessions.values.values.single.codeHash, isNot(contains('123456')));
      expect(sessions.values.values.single.phoneNumber, regularPhoneNumber);
    },
  );

  test('Google Play review phone uses its fixed code without SMS', () async {
    final sessionId = await service.start(
      googlePlayReviewPhoneNumber,
      languageCode: 'ar',
    );

    expect(sms.sendCount, 0);
    expect(sessions.values.values.single.codeHash, isNot(contains('786345')));

    final token = await service.check(
      sessionId: sessionId,
      code: googlePlayReviewVerificationCode,
    );

    expect(token, 'firebase-custom-token');
    expect(identity.requestedPhone, googlePlayReviewPhoneNumber);
    expect(sessions.values, isEmpty);
  });

  test('Google Play review phone rejects any other code', () async {
    final sessionId = await service.start(
      googlePlayReviewPhoneNumber,
      languageCode: 'en',
    );

    await expectLater(
      service.check(sessionId: sessionId, code: '123456'),
      throwsA(
        isA<VerificationFailure>().having(
          (error) => error.code,
          'code',
          'invalid-verification-code',
        ),
      ),
    );
    expect(sms.sendCount, 0);
    expect(identity.requestedPhone, isNull);
  });

  test('checks the code hash and returns a Firebase custom token', () async {
    final sessionId = await service.start(
      regularPhoneNumber,
      languageCode: 'ar',
    );

    final token = await service.check(sessionId: sessionId, code: '123456');

    expect(token, 'firebase-custom-token');
    expect(identity.requestedPhone, regularPhoneNumber);
    expect(sessions.values, isEmpty);
  });

  test(
    'local development authentication creates a token without SMS',
    () async {
      final token = await service.authenticateWithoutSms('+212708708001');

      expect(token, 'firebase-custom-token');
      expect(identity.requestedPhone, '+212708708001');
      expect(sms.sendCount, 0);
      expect(sessions.values, isEmpty);
    },
  );

  test('decrements attempts when the code is wrong', () async {
    final sessionId = await service.start(
      regularPhoneNumber,
      languageCode: 'ar',
    );

    await expectLater(
      service.check(sessionId: sessionId, code: '654321'),
      throwsA(
        isA<VerificationFailure>().having(
          (error) => error.code,
          'code',
          'invalid-verification-code',
        ),
      ),
    );

    expect(sessions.values[sessionId]!.attemptsRemaining, 4);
    expect(identity.requestedPhone, isNull);
  });

  test('rejects repeated sends to the same number within a minute', () async {
    await service.start(regularPhoneNumber, languageCode: 'ar');

    await expectLater(
      service.start(regularPhoneNumber, languageCode: 'ar'),
      throwsA(
        isA<VerificationFailure>().having(
          (error) => error.code,
          'code',
          'too-many-requests',
        ),
      ),
    );
    expect(sms.sendCount, 1);
  });

  test('rejects an expired session before checking the code', () async {
    sessions.values['B' * 43] = VerificationSession(
      id: 'B' * 43,
      phoneNumber: regularPhoneNumber,
      codeHash: 'expired-hash',
      attemptsRemaining: 5,
      expiresAt: DateTime.utc(2026, 8, 4, 11, 59),
    );

    await expectLater(
      service.check(sessionId: 'B' * 43, code: '123456'),
      throwsA(
        isA<VerificationFailure>().having(
          (error) => error.code,
          'code',
          'session-expired',
        ),
      ),
    );
    expect(sessions.values, isEmpty);
  });
}

class _FakeSmsGateway implements VerificationSmsGateway {
  String? sentPhone;
  String? sentCode;
  int sendCount = 0;

  @override
  Future<void> sendCode({
    required String phoneNumber,
    required String code,
    required String idempotencyKey,
    required String languageCode,
  }) async {
    sentPhone = phoneNumber;
    sentCode = code;
    sendCount += 1;
  }
}

class _MemorySessions implements VerificationSessionStore {
  final values = <String, VerificationSession>{};
  final _sendReservations = <String>{};

  @override
  Future<void> reserveSend(String phoneNumber, DateTime requestedAt) async {
    final key = '$phoneNumber:${requestedAt.millisecondsSinceEpoch ~/ 60000}';
    if (!_sendReservations.add(key)) {
      throw const VerificationFailure('too-many-requests');
    }
  }

  @override
  Future<void> releaseSend(String phoneNumber, DateTime requestedAt) async {
    final key = '$phoneNumber:${requestedAt.millisecondsSinceEpoch ~/ 60000}';
    _sendReservations.remove(key);
  }

  @override
  Future<void> save(VerificationSession session) async {
    values[session.id] = session;
  }

  @override
  Future<void> update(VerificationSession session) async {
    values[session.id] = session;
  }

  @override
  Future<VerificationSession?> get(String id) async => values[id];

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }
}

class _FakeIdentity implements FirebaseIdentityGateway {
  String? requestedPhone;

  @override
  Future<String> findOrCreateUser(String phoneNumber) async {
    requestedPhone = phoneNumber;
    return 'existing-firebase-uid';
  }

  @override
  Future<String> createCustomToken({
    required String uid,
    required String phoneNumber,
  }) async {
    expect(uid, 'existing-firebase-uid');
    expect(phoneNumber, requestedPhone);
    return 'firebase-custom-token';
  }
}
