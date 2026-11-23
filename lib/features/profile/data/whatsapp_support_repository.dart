import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const whatsAppSupportPromptAnsweredAtField = 'supportPromptAnsweredAt';

abstract interface class WhatsAppSupportRepository {
  Stream<bool> watchEnabled(String userId);
  Future<void> setEnabled(String userId, bool enabled);
  Future<void> answerPrompt(String userId, bool enabled);
}

class FirestoreWhatsAppSupportRepository implements WhatsAppSupportRepository {
  FirestoreWhatsAppSupportRepository(this._firestore);

  static const _enabled = 'whatsAppSupportEnabled';
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profile(String userId) =>
      _firestore.collection('users').doc(userId);

  @override
  Stream<bool> watchEnabled(String userId) => _profile(userId)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.hasPendingWrites)
      .map((snapshot) => snapshot.data()?[_enabled] == true)
      .distinct();

  @override
  Future<void> setEnabled(String userId, bool enabled) =>
      _save(userId, enabled);

  @override
  Future<void> answerPrompt(String userId, bool enabled) =>
      _save(userId, enabled, answeringPrompt: true);

  Future<void> _save(
    String userId,
    bool enabled, {
    bool answeringPrompt = false,
  }) {
    final profile = _profile(userId);
    return _firestore.runTransaction((transaction) async {
      final data = (await transaction.get(profile)).data();
      if (answeringPrompt &&
          data?[whatsAppSupportPromptAnsweredAtField] != null) {
        return;
      }
      final previous = data?[_enabled];
      if (!answeringPrompt && previous == enabled) return;

      transaction.update(profile, {
        if (previous != enabled) _enabled: enabled,
        if (answeringPrompt)
          whatsAppSupportPromptAnsweredAtField: FieldValue.serverTimestamp(),
        if (enabled && previous != true)
          'whatsAppSupportConsentedAt': FieldValue.serverTimestamp(),
        if (!enabled && previous == true)
          'whatsAppSupportRevokedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

final whatsAppSupportRepositoryProvider = Provider<WhatsAppSupportRepository>(
  (ref) =>
      FirestoreWhatsAppSupportRepository(ref.watch(firebaseFirestoreProvider)),
);

final whatsAppSupportEnabledProvider = StreamProvider.autoDispose
    .family<bool, String>(
      (ref, userId) =>
          ref.watch(whatsAppSupportRepositoryProvider).watchEnabled(userId),
    );
