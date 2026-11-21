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
    this.supportResidence,
  });

  final List<UserResidence> residences;
  final String? activeResidenceId;
  final List<ResidenceInvitation> invitations;
  final UserResidence? supportResidence;

  UserResidence? get activeResidence {
    if (supportResidence case final UserResidence residence) return residence;
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

  Future<bool> hasActiveMembership({
    required AuthUser user,
    required String residenceId,
  });

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
  Future<bool> hasActiveMembership({
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
      return membership.exists && membership.data()?['status'] == 'active';
    } on FirebaseException catch (error) {
      throw ResidenceContextFailure(error.code, error.message);
    }
  }

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
      final hasProfileImage =
          userDocument.data()?['hasProfileImage'] as bool? ?? false;

      // These are already the complete membership documents. Re-reading every
      // membership added an unnecessary network round-trip to every page load.
      final memberships = membershipQuery.docs
          .where(
            (membership) =>
                membership.exists && membership.data()['status'] == 'active',
          )
          .toList(growable: false);
      await _syncMembershipProfileImages(
        memberships: memberships,
        hasProfileImage: hasProfileImage,
      );
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

  Future<void> _syncMembershipProfileImages({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> memberships,
    required bool hasProfileImage,
  }) async {
    final staleMemberships = memberships
        .where(
          (membership) => shouldSyncMembershipProfileImage(
            membership.data(),
            hasProfileImage,
          ),
        )
        .toList(growable: false);
    if (staleMemberships.isEmpty) return;

    final batch = _firestore.batch();
    for (final membership in staleMemberships) {
      batch.update(membership.reference, {
        'hasProfileImage': hasProfileImage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
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

bool shouldSyncMembershipProfileImage(
  Map<String, dynamic> membership,
  bool hasProfileImage,
) => membership['hasProfileImage'] != hasProfileImage;

final residenceContextRepositoryProvider = Provider<ResidenceContextRepository>(
  (ref) {
    return FirestoreResidenceContextRepository(
      ref.watch(firebaseFirestoreProvider),
    );
  },
);

const residenceDataTimeout = Duration(seconds: 12);

final residenceSupportProvider =
    NotifierProvider<ResidenceSupportController, UserResidence?>(
      ResidenceSupportController.new,
    );

class ResidenceSupportController extends Notifier<UserResidence?> {
  @override
  UserResidence? build() {
    ref.watch(authStateProvider.select((session) => session.value?.uid));
    return null;
  }

  void open(UserResidence residence) => state = residence;

  void close() => state = null;
}

final residenceForSupportProvider =
    Provider<Future<UserResidence> Function(String)>((ref) {
      final auth = ref.watch(firebaseAuthProvider);
      final firestore = ref.watch(firebaseFirestoreProvider);

      return (id) async {
        final user = auth.currentUser;
        final token = await user?.getIdTokenResult(true);
        if (token?.claims?['developer'] != true ||
            auth.currentUser?.uid != user?.uid) {
          throw const ResidenceContextFailure('permission-denied');
        }
        final document = await firestore
            .collection('residences')
            .doc(id)
            .get(const GetOptions(source: Source.server));
        final data = document.data();
        if (data == null) {
          throw const ResidenceContextFailure('residence-not-found');
        }

        return UserResidence(
          id: id,
          name: data['name'] as String? ?? '',
          address: data['address'] as String? ?? '',
          city: data['city'] as String? ?? '',
          hasImage: data['hasImage'] as bool? ?? false,
          role: 'developer',
          apartmentId: '',
          hasPresidentPermissions: true,
        );
      };
    });

final residenceContextProvider = FutureProvider<ResidenceContext>((ref) async {
  final support = ref.watch(residenceSupportProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    throw const ResidenceContextFailure('signed-out');
  }
  final membership = await ref
      .watch(residenceContextRepositoryProvider)
      .load(user)
      .timeout(
        residenceDataTimeout,
        onTimeout: () => throw const ResidenceContextFailure('request-timeout'),
      );
  if (support == null) return membership;

  return ResidenceContext(
    residences: membership.residences,
    activeResidenceId: support.id,
    invitations: membership.invitations,
    supportResidence: support,
  );
});
