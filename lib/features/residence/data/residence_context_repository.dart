import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserResidence {
  const UserResidence({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.role,
    required this.apartmentId,
    this.hasPresidentPermissions = false,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String role;
  final String apartmentId;
  final bool hasPresidentPermissions;
  final DateTime? joinedAt;

  bool get canManageResidence =>
      role == 'president' || role == 'owner' || hasPresidentPermissions;
}

class ResidenceContext {
  const ResidenceContext({
    required this.residences,
    required this.activeResidenceId,
    required this.invitations,
  });

  final List<UserResidence> residences;
  final String? activeResidenceId;
  final List<ResidenceInvitation> invitations;

  UserResidence? get activeResidence {
    final activeId = activeResidenceId;
    if (activeId == null) {
      return null;
    }
    for (final residence in residences) {
      if (residence.id == activeId) {
        return residence;
      }
    }
    return null;
  }
}

class ResidenceContextFailure implements Exception {
  const ResidenceContextFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceContextRepository {
  Future<ResidenceContext> load(AuthUser user);

  Future<void> setActiveResidence({
    required AuthUser user,
    required String residenceId,
  });
}

class FirestoreResidenceContextRepository
    implements ResidenceContextRepository {
  FirestoreResidenceContextRepository(this._firestore, this._accountRepository);

  final FirebaseFirestore _firestore;
  final AccountOnboardingRepository _accountRepository;

  @override
  Future<ResidenceContext> load(AuthUser user) async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(user.uid).get(),
        _accountRepository.loadResolution(user),
      ]);
      final userDocument = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final resolution = results[1] as AccountResolution;
      final storedActiveId =
          userDocument.data()?['activeResidenceId'] as String?;

      final discoveredResidenceIds = <String>{
        ?storedActiveId,
        ...resolution.acceptedResidenceIds,
      };
      final optionalDiscoveries = await Future.wait([
        _loadMemberResidenceIds(user.uid),
        _loadCreatorResidenceIds(user.uid),
      ]);
      for (final residenceIds in optionalDiscoveries) {
        discoveredResidenceIds.addAll(residenceIds);
      }

      final membershipDocuments = await Future.wait([
        for (final residenceId in discoveredResidenceIds)
          _firestore
              .collection('residences')
              .doc(residenceId)
              .collection('members')
              .doc(user.uid)
              .get(),
      ]);
      final memberships = membershipDocuments
          .where(
            (membership) =>
                membership.exists && membership.data()?['status'] == 'active',
          )
          .toList(growable: false);
      final residenceDocuments = await Future.wait([
        for (final membership in memberships)
          membership.reference.parent.parent!.get(),
      ]);
      final residences = <UserResidence>[
        for (var index = 0; index < memberships.length; index++)
          if (residenceDocuments[index].exists)
            _residenceFromDocuments(
              memberships[index],
              residenceDocuments[index],
            ),
      ]..sort((first, second) => first.name.compareTo(second.name));

      final activeId =
          residences.any((residence) => residence.id == storedActiveId)
          ? storedActiveId
          : residences.firstOrNull?.id;
      if (activeId != null &&
          activeId != storedActiveId &&
          userDocument.exists) {
        await _persistActiveResidence(user.uid, activeId);
      }

      return ResidenceContext(
        residences: residences,
        activeResidenceId: activeId,
        invitations: resolution.invitations,
      );
    } on AccountOnboardingFailure catch (error) {
      throw ResidenceContextFailure(error.code, error.details);
    } on FirebaseException catch (error) {
      throw ResidenceContextFailure(error.code, error.message);
    } catch (error) {
      throw ResidenceContextFailure('unknown', error.toString());
    }
  }

  Future<Set<String>> _loadMemberResidenceIds(String userId) async {
    final query = await _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .get();
    return {
      for (final membership in query.docs) _residenceReference(membership).id,
    };
  }

  Future<Set<String>> _loadCreatorResidenceIds(String userId) async {
    final query = await _firestore
        .collectionGroup('settings')
        .where('createdBy', isEqualTo: userId)
        .get();
    return {
      for (final settings in query.docs)
        if (settings.reference.parent.parent != null)
          settings.reference.parent.parent!.id,
    };
  }

  Future<void> _persistActiveResidence(
    String userId,
    String residenceId,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'activeResidenceId': residenceId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setActiveResidence({
    required AuthUser user,
    required String residenceId,
  }) async {
    try {
      final membership = await _firestore
          .collection('residences')
          .doc(residenceId)
          .collection('members')
          .doc(user.uid)
          .get();
      if (!membership.exists || membership.data()?['status'] != 'active') {
        throw const ResidenceContextFailure('not-a-member');
      }
      await _firestore.collection('users').doc(user.uid).update({
        'activeResidenceId': residenceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on ResidenceContextFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceContextFailure(error.code, error.message);
    }
  }

  DocumentReference<Map<String, dynamic>> _residenceReference(
    QueryDocumentSnapshot<Map<String, dynamic>> membership,
  ) {
    final reference = membership.reference.parent.parent;
    if (reference == null) {
      throw const ResidenceContextFailure('invalid-membership');
    }
    return reference;
  }

  UserResidence _residenceFromDocuments(
    DocumentSnapshot<Map<String, dynamic>> membership,
    DocumentSnapshot<Map<String, dynamic>> residence,
  ) {
    final membershipData = membership.data()!;
    final residenceData = residence.data()!;
    return UserResidence(
      id: residence.id,
      name: residenceData['name'] as String? ?? '',
      address: residenceData['address'] as String? ?? '',
      city: residenceData['city'] as String? ?? '',
      role: membershipData['role'] as String? ?? 'resident',
      apartmentId: membershipData['apartmentId'] as String? ?? '',
      hasPresidentPermissions:
          membershipData['hasPresidentPermissions'] as bool? ?? false,
      joinedAt: (membershipData['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}

final residenceContextRepositoryProvider = Provider<ResidenceContextRepository>(
  (ref) {
    return FirestoreResidenceContextRepository(
      ref.watch(firebaseFirestoreProvider),
      ref.watch(accountOnboardingRepositoryProvider),
    );
  },
);

final residenceContextProvider = FutureProvider.autoDispose<ResidenceContext>((
  ref,
) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    throw const ResidenceContextFailure('signed-out');
  }
  return ref.watch(residenceContextRepositoryProvider).load(user);
});
