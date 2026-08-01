import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter/foundation.dart';
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
    this.hasImage = false,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String role;
  final String apartmentId;
  final bool hasPresidentPermissions;
  final bool hasImage;
  final DateTime? joinedAt;

  bool get canManageResidence =>
      role == 'president' || role == 'owner' || hasPresidentPermissions;
}

class ResidenceContext {
  const ResidenceContext({
    required this.residences,
    required this.activeResidenceId,
    this.invitations = const [],
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
  FirestoreResidenceContextRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ResidenceContext> load(AuthUser user) async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(user.uid).get(),
        _firestore
            .collectionGroup('members')
            .where('userId', isEqualTo: user.uid)
            .get(),
      ]);
      final userDocument = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final membershipQuery = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final storedActiveId =
          userDocument.data()?['activeResidenceId'] as String?;

      // These are already the complete membership documents. Re-reading every
      // membership added an unnecessary network round-trip to every page load.
      final memberships = membershipQuery.docs
          .where(
            (membership) =>
                membership.exists && membership.data()['status'] == 'active',
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
      );
    } on FirebaseException catch (error) {
      throw ResidenceContextFailure(error.code, error.message);
    } catch (error) {
      throw ResidenceContextFailure('unknown', error.toString());
    } finally {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          'DarJar performance: residence context '
          '${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
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
      hasImage: residenceData['hasImage'] as bool? ?? false,
      joinedAt: (membershipData['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}

final residenceContextRepositoryProvider = Provider<ResidenceContextRepository>(
  (ref) {
    return FirestoreResidenceContextRepository(
      ref.watch(firebaseFirestoreProvider),
    );
  },
);

const residenceDataTimeout = Duration(seconds: 12);

final residenceContextProvider = FutureProvider<ResidenceContext>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    throw const ResidenceContextFailure('signed-out');
  }
  return ref
      .watch(residenceContextRepositoryProvider)
      .load(user)
      .timeout(
        residenceDataTimeout,
        onTimeout: () => throw const ResidenceContextFailure('request-timeout'),
      );
});
