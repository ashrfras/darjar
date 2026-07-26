import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.phoneNumber});

  final String uid;
  final String? phoneNumber;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final String code;
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<void> sendVerificationCode(String phoneNumber);

  Future<void> confirmVerificationCode(String code);

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;
  ConfirmationResult? _webConfirmationResult;
  String? _nativeVerificationId;

  @override
  AuthUser? get currentUser => _toAuthUser(_firebaseAuth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_toAuthUser);
  }

  @override
  Future<void> sendVerificationCode(String phoneNumber) async {
    try {
      if (kIsWeb) {
        _webConfirmationResult = await _firebaseAuth.signInWithPhoneNumber(
          phoneNumber,
        );
        return;
      }

      final codeSent = Completer<void>();
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          try {
            await _firebaseAuth.signInWithCredential(credential);
            if (!codeSent.isCompleted) {
              codeSent.complete();
            }
          } on FirebaseException catch (error) {
            if (!codeSent.isCompleted) {
              codeSent.completeError(AuthFailure(error.code));
            }
          }
        },
        verificationFailed: (error) {
          if (!codeSent.isCompleted) {
            codeSent.completeError(AuthFailure(error.code));
          }
        },
        codeSent: (verificationId, resendToken) {
          _nativeVerificationId = verificationId;
          if (!codeSent.isCompleted) {
            codeSent.complete();
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _nativeVerificationId = verificationId;
          if (!codeSent.isCompleted) {
            codeSent.complete();
          }
        },
      );
      await codeSent.future;
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AuthFailure(error.code);
    } catch (error) {
      throw AuthFailure(_firebaseAuthErrorCode(error));
    }
  }

  @override
  Future<void> confirmVerificationCode(String code) async {
    try {
      if (kIsWeb) {
        final confirmationResult = _webConfirmationResult;
        if (confirmationResult == null) {
          throw const AuthFailure('missing-verification-session');
        }
        await confirmationResult.confirm(code);
        _webConfirmationResult = null;
        return;
      }

      final verificationId = _nativeVerificationId;
      if (verificationId == null) {
        throw const AuthFailure('missing-verification-session');
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await _firebaseAuth.signInWithCredential(credential);
      _nativeVerificationId = null;
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AuthFailure(error.code);
    } catch (error) {
      throw AuthFailure(_firebaseAuthErrorCode(error));
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

String _firebaseAuthErrorCode(Object error) {
  final match = RegExp(
    r'(?:firebase_auth/|auth/)([a-z0-9-]+)',
  ).firstMatch(error.toString());
  return match?.group(1) ?? 'unknown';
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

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
);

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
