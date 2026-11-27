import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ResidenceDeletionTarget = ({String residenceId, String creatorId});

final activeResidenceDeletionProvider =
    Provider.autoDispose<AsyncValue<ResidenceDeletionTarget?>>((ref) {
      final residence = ref.watch(
        residenceContextProvider.select(
          (context) => context.value?.activeResidence,
        ),
      );
      final creatorId = residence?.createdBy;
      if (residence == null ||
          creatorId == null ||
          ref.watch(authRepositoryProvider).currentUser?.uid != creatorId) {
        return const AsyncData(null);
      }
      final target = (residenceId: residence.id, creatorId: creatorId);
      return ref
          .watch(canDeleteResidenceProvider(target))
          .whenData((allowed) => allowed ? target : null);
    });

final canDeleteResidenceProvider = StreamProvider.autoDispose
    .family<bool, ResidenceDeletionTarget>((ref, target) {
      return ref
          .watch(firebaseFirestoreProvider)
          .collection('residences')
          .doc(target.residenceId)
          .collection('members')
          .limit(2)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) =>
                !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites &&
                snapshot.docs.length == 1 &&
                snapshot.docs.single.id == target.creatorId &&
                snapshot.docs.single.data()['status'] == 'active',
          );
    });

final deleteResidenceProvider = Provider<Future<void> Function(String)>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final api = ref.watch(phoneVerificationApiProvider);
  return (residenceId) async {
    final user = auth.currentUser;
    final token = await user?.getIdToken();
    if (token == null || auth.currentUser?.uid != user?.uid) {
      throw const AuthFailure('invalid-identity');
    }
    await api.deleteResidence(residenceId, token);
  };
});
