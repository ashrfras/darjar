import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountDeletionFailure implements Exception {
  const AccountDeletionFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class AccountDeletionRepository {
  Future<void> requestDeletion({
    required AuthUser user,
    required List<String> residenceIds,
  });
}

class FirestoreAccountDeletionRepository implements AccountDeletionRepository {
  FirestoreAccountDeletionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> requestDeletion({
    required AuthUser user,
    required List<String> residenceIds,
  }) async {
    try {
      final batch = _firestore.batch();
      final requestedAt = FieldValue.serverTimestamp();
      final deletionDueAt = Timestamp.fromDate(
        DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      batch.update(_firestore.collection('users').doc(user.uid), {
        'accountStatus': 'deletionRequested',
        'deletionRequestedAt': requestedAt,
        'deletionDueAt': deletionDueAt,
        'updatedAt': requestedAt,
      });

      for (final residenceId in residenceIds.toSet()) {
        batch.update(
          _firestore
              .collection('residences')
              .doc(residenceId)
              .collection('members')
              .doc(user.uid),
          {
            'status': 'deletionRequested',
            'hasPresidentPermissions': false,
            'updatedAt': requestedAt,
          },
        );
      }

      await batch.commit();
    } on FirebaseException catch (error) {
      throw AccountDeletionFailure(error.code, error.message);
    } catch (error) {
      throw AccountDeletionFailure('unknown', error.toString());
    }
  }
}

final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository>(
  (ref) =>
      FirestoreAccountDeletionRepository(ref.watch(firebaseFirestoreProvider)),
);
