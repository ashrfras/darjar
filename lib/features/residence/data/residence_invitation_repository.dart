import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceGroupInvitation {
  const ResidenceGroupInvitation({
    required this.residenceId,
    required this.joinCode,
    required this.joinRequestsEnabled,
  });

  final String residenceId;
  final String joinCode;
  final bool joinRequestsEnabled;

  String get url => 'https://darjar.app/join/$joinCode';
}

abstract interface class ResidenceInvitationRepository {
  Future<ResidenceGroupInvitation> load(String residenceId);

  Future<void> setJoiningEnabled(String residenceId, bool enabled);
}

class FirestoreResidenceInvitationRepository
    implements ResidenceInvitationRepository {
  FirestoreResidenceInvitationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ResidenceGroupInvitation> load(String residenceId) async {
    final residence = _firestore.collection('residences').doc(residenceId);
    final results = await Future.wait([
      residence.get(),
      residence.collection('settings').doc('private').get(),
    ]);
    final residenceDocument = results[0];
    final settingsDocument = results[1];
    if (!residenceDocument.exists || !settingsDocument.exists) {
      throw StateError('missing-residence-invitation-settings');
    }
    return ResidenceGroupInvitation(
      residenceId: residenceId,
      joinCode: settingsDocument.data()?['joinCode'] as String? ?? '',
      joinRequestsEnabled:
          residenceDocument.data()?['joinRequestsEnabled'] as bool? ?? false,
    );
  }

  @override
  Future<void> setJoiningEnabled(String residenceId, bool enabled) {
    return _firestore.collection('residences').doc(residenceId).update({
      'joinRequestsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final residenceInvitationRepositoryProvider =
    Provider<ResidenceInvitationRepository>(
      (ref) => FirestoreResidenceInvitationRepository(
        ref.watch(firebaseFirestoreProvider),
      ),
    );

class ResidenceInvitationController
    extends AsyncNotifier<ResidenceGroupInvitation> {
  String? _residenceId;

  @override
  Future<ResidenceGroupInvitation> build() async {
    _residenceId = await ref.watch(
      residenceContextProvider.selectAsync(
        (context) => context.activeResidenceId,
      ),
    );
    final residenceId = _residenceId;
    if (residenceId == null) {
      throw StateError('missing-active-residence');
    }
    return ref.read(residenceInvitationRepositoryProvider).load(residenceId);
  }

  Future<void> setJoiningEnabled(bool enabled) async {
    final residenceId = _residenceId;
    final current = state.value;
    if (residenceId == null || current == null) {
      return;
    }
    state = AsyncData(
      ResidenceGroupInvitation(
        residenceId: current.residenceId,
        joinCode: current.joinCode,
        joinRequestsEnabled: enabled,
      ),
    );
    try {
      await ref
          .read(residenceInvitationRepositoryProvider)
          .setJoiningEnabled(residenceId, enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final residenceInvitationProvider =
    AsyncNotifierProvider<
      ResidenceInvitationController,
      ResidenceGroupInvitation
    >(ResidenceInvitationController.new);
