import 'package:darjar_phone_verification/src/http_api.dart';
import 'package:test/test.dart';

void main() {
  test('allows configured and local development origins', () {
    const configured = {'https://darjar.app'};

    expect(
      isAllowedPhoneVerificationOrigin('https://darjar.app', configured),
      isTrue,
    );
    expect(
      isAllowedPhoneVerificationOrigin('http://localhost:52741', configured),
      isTrue,
    );
    expect(
      isAllowedPhoneVerificationOrigin('http://127.0.0.1:8080', configured),
      isTrue,
    );
    expect(
      isAllowedPhoneVerificationOrigin('http://[::1]:8080', configured),
      isTrue,
    );
  });

  test('rejects unconfigured and lookalike origins', () {
    const configured = {'https://darjar.app'};

    expect(
      isAllowedPhoneVerificationOrigin(
        'https://localhost.example.com',
        configured,
      ),
      isFalse,
    );
    expect(
      isAllowedPhoneVerificationOrigin('https://example.com', configured),
      isFalse,
    );
    expect(isAllowedPhoneVerificationOrigin(null, configured), isFalse);
  });

  test(
    'local development authentication needs loopback, phone, and secret',
    () {
      const secret = 'a-secret-that-is-longer-than-32-characters';

      expect(
        isLocalDevelopmentAuthRequest(
          origin: 'http://localhost:52741',
          phoneNumber: localDevelopmentPhoneNumber,
        ),
        isTrue,
      );
      expect(
        canUseLocalDevelopmentAuth(
          origin: 'http://localhost:52741',
          phoneNumber: localDevelopmentPhoneNumber,
          providedSecret: secret,
          configuredSecret: secret,
        ),
        isTrue,
      );
      expect(
        canUseLocalDevelopmentAuth(
          origin: 'https://darjar.app',
          phoneNumber: localDevelopmentPhoneNumber,
          providedSecret: secret,
          configuredSecret: secret,
        ),
        isFalse,
      );
      expect(
        canUseLocalDevelopmentAuth(
          origin: 'http://localhost:52741',
          phoneNumber: '+212708708002',
          providedSecret: secret,
          configuredSecret: secret,
        ),
        isFalse,
      );
      expect(
        canUseLocalDevelopmentAuth(
          origin: 'http://localhost:52741',
          phoneNumber: localDevelopmentPhoneNumber,
          providedSecret: 'wrong-secret-that-is-longer-than-32-chars',
          configuredSecret: secret,
        ),
        isFalse,
      );
    },
  );
}
