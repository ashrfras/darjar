import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class VerificationFailure implements Exception {
  const VerificationFailure(this.code, {this.message});

  final String code;
  final String? message;
}

class VerificationSession {
  const VerificationSession({
    required this.id,
    required this.phoneNumber,
    required this.codeHash,
    required this.attemptsRemaining,
    required this.expiresAt,
  });

  final String id;
  final String phoneNumber;
  final String codeHash;
  final int attemptsRemaining;
  final DateTime expiresAt;

  VerificationSession withAttemptsRemaining(int value) {
    return VerificationSession(
      id: id,
      phoneNumber: phoneNumber,
      codeHash: codeHash,
      attemptsRemaining: value,
      expiresAt: expiresAt,
    );
  }
}

abstract interface class VerificationSmsGateway {
  Future<void> sendCode({
    required String phoneNumber,
    required String code,
    required String idempotencyKey,
    required String languageCode,
  });
}

abstract interface class VerificationSessionStore {
  Future<void> reserveSend(String phoneNumber, DateTime requestedAt);

  Future<void> releaseSend(String phoneNumber, DateTime requestedAt);

  Future<void> save(VerificationSession session);

  Future<void> update(VerificationSession session);

  Future<VerificationSession?> get(String id);

  Future<void> delete(String id);
}

abstract interface class FirebaseIdentityGateway {
  Future<String> findOrCreateUser(String phoneNumber);

  Future<String> createCustomToken({
    required String uid,
    required String phoneNumber,
  });
}

class PhoneVerificationService {
  PhoneVerificationService({
    required VerificationSmsGateway sms,
    required VerificationSessionStore sessions,
    required FirebaseIdentityGateway firebaseIdentity,
    required String otpHashPepper,
    DateTime Function()? now,
    String Function()? newSessionId,
    String Function()? newCode,
  }) : this._(
         sms,
         sessions,
         firebaseIdentity,
         otpHashPepper,
         now ?? DateTime.now,
         newSessionId ?? _secureSessionId,
         newCode ?? _secureOtpCode,
       );

  PhoneVerificationService._(
    this._sms,
    this._sessions,
    this._firebaseIdentity,
    this._otpHashPepper,
    this._now,
    this._newSessionId,
    this._newCode,
  );

  final VerificationSmsGateway _sms;
  final VerificationSessionStore _sessions;
  final FirebaseIdentityGateway _firebaseIdentity;
  final String _otpHashPepper;
  final DateTime Function() _now;
  final String Function() _newSessionId;
  final String Function() _newCode;

  Future<String> start(
    String phoneNumber, {
    required String languageCode,
  }) async {
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber)) {
      throw const VerificationFailure('invalid-phone-number');
    }

    final requestedAt = _now().toUtc();
    await _sessions.reserveSend(phoneNumber, requestedAt);
    final sessionId = _newSessionId();
    final code = _newCode();
    final session = VerificationSession(
      id: sessionId,
      phoneNumber: phoneNumber,
      codeHash: _hashCode(sessionId: sessionId, code: code),
      attemptsRemaining: 5,
      expiresAt: requestedAt.add(const Duration(minutes: 10)),
    );
    try {
      await _sessions.save(session);
      await _sms.sendCode(
        phoneNumber: phoneNumber,
        code: code,
        idempotencyKey: sessionId,
        languageCode: languageCode == 'en' ? 'en' : 'ar',
      );
    } catch (_) {
      await _sessions.delete(sessionId);
      await _sessions.releaseSend(phoneNumber, requestedAt);
      rethrow;
    }
    return sessionId;
  }

  Future<String> check({
    required String sessionId,
    required String code,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(sessionId)) {
      throw const VerificationFailure('missing-verification-session');
    }
    if (!RegExp(r'^\d{4,10}$').hasMatch(code)) {
      throw const VerificationFailure('invalid-verification-code');
    }

    final session = await _sessions.get(sessionId);
    if (session == null) {
      throw const VerificationFailure('missing-verification-session');
    }
    if (!session.expiresAt.isAfter(_now().toUtc())) {
      await _sessions.delete(sessionId);
      throw const VerificationFailure('session-expired');
    }
    if (session.attemptsRemaining <= 0) {
      await _sessions.delete(sessionId);
      throw const VerificationFailure('too-many-requests');
    }

    final submittedHash = _hashCode(sessionId: sessionId, code: code);
    if (!_constantTimeEquals(session.codeHash, submittedHash)) {
      final attemptsRemaining = session.attemptsRemaining - 1;
      if (attemptsRemaining <= 0) {
        await _sessions.delete(sessionId);
        throw const VerificationFailure('too-many-requests');
      }
      await _sessions.update(session.withAttemptsRemaining(attemptsRemaining));
      throw const VerificationFailure('invalid-verification-code');
    }

    final uid = await _firebaseIdentity.findOrCreateUser(session.phoneNumber);
    final token = await _firebaseIdentity.createCustomToken(
      uid: uid,
      phoneNumber: session.phoneNumber,
    );
    await _sessions.delete(sessionId);
    return token;
  }

  String _hashCode({required String sessionId, required String code}) {
    final hmac = Hmac(sha256, utf8.encode(_otpHashPepper));
    return hmac.convert(utf8.encode('$sessionId:$code')).toString();
  }
}

String _secureSessionId() {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  final random = Random.secure();
  return List.generate(
    43,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}

String _secureOtpCode() {
  final value = 100000 + Random.secure().nextInt(900000);
  return value.toString();
}

bool _constantTimeEquals(String left, String right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}
