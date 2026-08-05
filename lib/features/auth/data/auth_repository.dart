import 'dart:async';

import 'package:darjar/features/auth/data/auth_failure.dart';
import 'package:darjar/features/auth/data/phone_verification_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

export 'auth_failure.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.phoneNumber});

  final String uid;
  final String? phoneNumber;
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<void> sendVerificationCode(
    String phoneNumber, {
    required String languageCode,
  });

  Future<void> confirmVerificationCode(String code);

  Future<void> signOut();
}

class BackendAuthRepository implements AuthRepository {
  BackendAuthRepository(this._firebaseAuth, this._verificationApi);

  final FirebaseAuth _firebaseAuth;
  final PhoneVerificationApi _verificationApi;
  String? _verificationSessionId;

  @override
  AuthUser? get currentUser => _toAuthUser(_firebaseAuth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_toAuthUser);
  }

  @override
  Future<void> sendVerificationCode(
    String phoneNumber, {
    required String languageCode,
  }) async {
    try {
      _verificationSessionId = await _verificationApi.start(
        phoneNumber,
        languageCode: languageCode,
      );
    } on AuthFailure {
      rethrow;
    } catch (error) {
      throw _authFailureFromUnknown(error);
    }
  }

  @override
  Future<void> confirmVerificationCode(String code) async {
    try {
      final sessionId = _verificationSessionId;
      if (sessionId == null) {
        throw const AuthFailure('missing-verification-session');
      }
      final customToken = await _verificationApi.check(
        sessionId: sessionId,
        code: code,
      );
      await _firebaseAuth.signInWithCustomToken(customToken);
      _verificationSessionId = null;
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _authFailureFromFirebase(error);
    } catch (error) {
      throw _authFailureFromUnknown(error);
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  AuthUser? _toAuthUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(uid: user.uid, phoneNumber: user.phoneNumber);
  }
}

class LocalhostAuthRepository implements AuthRepository {
  final _authStateController = StreamController<AuthUser?>.broadcast(
    sync: true,
  );
  AuthUser? _currentUser;
  String? _pendingPhoneNumber;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> sendVerificationCode(
    String phoneNumber, {
    required String languageCode,
  }) async {
    _pendingPhoneNumber = phoneNumber;
  }

  @override
  Future<void> confirmVerificationCode(String code) async {
    final phoneNumber = _pendingPhoneNumber;
    if (phoneNumber == null) {
      throw const AuthFailure('missing-verification-session');
    }
    _currentUser = AuthUser(
      uid: 'localhost-${phoneNumber.replaceAll(RegExp(r'\D'), '')}',
      phoneNumber: phoneNumber,
    );
    _pendingPhoneNumber = null;
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _pendingPhoneNumber = null;
    _authStateController.add(null);
  }

  Future<void> dispose() => _authStateController.close();
}

String _firebaseAuthErrorCode(Object error) {
  final match = RegExp(
    r'(?:firebase_auth/|auth/)([a-z0-9_-]+)',
    caseSensitive: false,
  ).firstMatch(error.toString());
  return match?.group(1)?.toLowerCase().replaceAll('_', '-') ?? 'unknown';
}

AuthFailure _authFailureFromFirebase(FirebaseException error) {
  final message = error.message?.trim();
  final parsedCode = _firebaseAuthErrorCode('$message\n$error');
  final reportedCode = error.code.toLowerCase().replaceAll('_', '-');
  final code = parsedCode != 'unknown'
      ? parsedCode
      : reportedCode.isEmpty
      ? 'unknown'
      : reportedCode;
  return AuthFailure(code, message: message ?? error.toString());
}

AuthFailure _authFailureFromUnknown(Object error) {
  final message = error.toString();
  return AuthFailure(_firebaseAuthErrorCode(message), message: message);
}

String normalizeMoroccanPhoneNumber(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00212')) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0')) {
    digits = '212${digits.substring(1)}';
  } else if (!digits.startsWith('212')) {
    digits = '212$digits';
  }
  return '+$digits';
}

bool isValidMoroccanMobileNumber(String phoneNumber) {
  return RegExp(r'^\+212[67]\d{8}$').hasMatch(phoneNumber);
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

const phoneVerificationServiceUrl = String.fromEnvironment(
  'DARJAR_PHONE_VERIFICATION_URL',
);

final phoneVerificationHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final phoneVerificationApiProvider = Provider<PhoneVerificationApi>(
  (ref) => PhoneVerificationApi(
    baseUrl: phoneVerificationServiceUrl,
    client: ref.watch(phoneVerificationHttpClientProvider),
  ),
);

bool isLocalhostAuthSimulation({bool isWeb = kIsWeb, Uri? uri}) {
  if (!isWeb) return false;
  final host = (uri ?? Uri.base).host.toLowerCase();
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

final localhostAuthSimulationProvider = Provider<bool>(
  (ref) => isLocalhostAuthSimulation(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(localhostAuthSimulationProvider)) {
    final repository = LocalhostAuthRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return BackendAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(phoneVerificationApiProvider),
  );
});

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
