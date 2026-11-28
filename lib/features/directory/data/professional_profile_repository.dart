import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/auth/data/phone_verification_api.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ProfessionalCandidate = ({
  String id,
  String name,
  String profession,
  String categoryId,
});

typedef ProfessionalServiceInput = ({
  String name,
  String categoryId,
  List<String> subcategoryIds,
  String profession,
  String neighborhood,
  String city,
});

typedef PersonalName = ({String firstName, String lastName});

abstract interface class ProfessionalProfileRepository {
  Future<List<ProfessionalCandidate>> discover(AuthUser user);
  Future<void> claim(AuthUser user, String id, PersonalName? name);
  Future<void> create(
    AuthUser user,
    ProfessionalServiceInput input,
    PersonalName? name,
  );
  Future<void> activate(AuthUser user);
  Future<void> setPaused(AuthUser user, String id, {required bool paused});
  Future<void> delete(AuthUser user, String id);
}

class FirebaseProfessionalProfileRepository
    implements ProfessionalProfileRepository {
  FirebaseProfessionalProfileRepository(this._auth, this._firestore, this._api);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PhoneVerificationApi _api;

  @override
  Future<List<ProfessionalCandidate>> discover(AuthUser user) async {
    final response = await _request(user, 'discover', const {});
    return [
      for (final candidate
          in (response['candidates'] as List).cast<Map<String, dynamic>>())
        (
          id: candidate['id'] as String,
          name: candidate['name'] as String,
          profession: candidate['profession'] as String,
          categoryId: candidate['categoryId'] as String,
        ),
    ];
  }

  @override
  Future<void> claim(AuthUser user, String id, PersonalName? name) async {
    await _request(user, 'claim', {'serviceId': id, ..._personalFields(name)});
  }

  @override
  Future<void> create(
    AuthUser user,
    ProfessionalServiceInput input,
    PersonalName? name,
  ) async {
    await _request(user, 'create', {
      'name': input.name,
      'categoryId': input.categoryId,
      'subcategoryIds': input.subcategoryIds,
      'profession': input.profession,
      'neighborhood': input.neighborhood,
      'city': input.city,
      ..._personalFields(name),
    });
  }

  Map<String, String> _personalFields(PersonalName? name) => {
    if (name != null) ...{
      'firstName': name.firstName,
      'lastName': name.lastName,
    },
  };

  @override
  Future<void> activate(AuthUser user) async {
    if (_auth.currentUser?.uid != user.uid) {
      throw const DirectoryFailure('missing-user');
    }
    await _firestore.collection('users').doc(user.uid).update({
      'activeSpaceType': 'professional',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPaused(
    AuthUser user,
    String id, {
    required bool paused,
  }) async {
    await _request(user, 'set-availability', {
      'serviceId': id,
      'paused': paused,
    });
  }

  @override
  Future<void> delete(AuthUser user, String id) async {
    await _request(user, 'delete', {'serviceId': id});
  }

  Future<Map<String, Object?>> _request(
    AuthUser user,
    String action,
    Map<String, Object?> input,
  ) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser?.uid != user.uid) {
      throw const DirectoryFailure('missing-user');
    }
    final token = await firebaseUser!.getIdToken();
    if (token == null || _auth.currentUser?.uid != user.uid) {
      throw const DirectoryFailure('missing-user');
    }
    try {
      return await _api.professionalProfile(action, token, input);
    } on AuthFailure catch (error) {
      throw DirectoryFailure(error.code, error.message);
    }
  }
}

final professionalProfileRepositoryProvider =
    Provider<ProfessionalProfileRepository>(
      (ref) => FirebaseProfessionalProfileRepository(
        ref.watch(firebaseAuthProvider),
        ref.watch(firebaseFirestoreProvider),
        ref.watch(phoneVerificationApiProvider),
      ),
    );

final professionalCandidateProvider = FutureProvider.autoDispose
    .family<List<ProfessionalCandidate>, AuthUser>(
      (ref, user) =>
          ref.watch(professionalProfileRepositoryProvider).discover(user),
      retry: (_, _) => null,
    );

void refreshProfessionalSpace(ProviderContainer container, AuthUser user) {
  container.invalidate(professionalCandidateProvider(user));
  container.invalidate(accountResolutionProvider);
  container.refresh(residenceContextProvider.future).ignore();
}
