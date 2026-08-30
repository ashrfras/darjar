import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.activeResidenceId,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? activeResidenceId;

  String get fullName => '$firstName $lastName'.trim();
}

class ResidenceInvitation {
  const ResidenceInvitation({
    required this.path,
    required this.id,
    required this.residenceId,
    required this.residenceName,
    required this.residenceAddress,
    required this.suggestedFirstName,
    required this.suggestedLastName,
    required this.apartmentId,
    required this.role,
  });

  final String path;
  final String id;
  final String residenceId;
  final String residenceName;
  final String residenceAddress;
  final String suggestedFirstName;
  final String suggestedLastName;
  final String apartmentId;
  final String role;

  String get suggestedFullName =>
      '$suggestedFirstName $suggestedLastName'.trim();
}

class AccountResolution {
  const AccountResolution({
    required this.phoneNumber,
    required this.profile,
    required this.invitations,
    this.acceptedResidenceIds = const [],
    this.deletionRequested = false,
  });

  final String phoneNumber;
  final UserProfile? profile;
  final List<ResidenceInvitation> invitations;
  final List<String> acceptedResidenceIds;
  final bool deletionRequested;

  UserProfile? get displayedProfile {
    if (profile != null) {
      return profile;
    }
    if (invitations.isEmpty) {
      return null;
    }
    final invitation = invitations.first;
    return UserProfile(
      firstName: invitation.suggestedFirstName,
      lastName: invitation.suggestedLastName,
      phoneNumber: '',
    );
  }
}

class AccountOnboardingFailure implements Exception {
  const AccountOnboardingFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class AccountOnboardingRepository {
  Future<AccountResolution> loadResolution(AuthUser user);

  Future<ResidenceInvitation?> loadPendingInvitation({
    required AuthUser user,
    required String residenceId,
    required String residenceName,
    required String residenceAddress,
  });

  Future<void> acceptInvitations({
    required AuthUser user,
    required AccountResolution resolution,
    required List<ResidenceInvitation> invitations,
    required String firstName,
    required String lastName,
  });

  Future<void> acceptInvitation({
    required AuthUser user,
    required ResidenceInvitation invitation,
    required String firstName,
    required String lastName,
    required String apartmentId,
  });
}

class FirestoreAccountOnboardingRepository
    implements AccountOnboardingRepository {
  FirestoreAccountOnboardingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<AccountResolution> loadResolution(AuthUser user) async {
    final phoneNumber = _verifiedPhoneNumber(user);
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(user.uid).get(),
        _firestore
            .collectionGroup('invitations')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get(),
      ]);
      final userDocument = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final invitationQuery = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final pendingInvitationDocuments = invitationQuery.docs
          .where((document) => document.data()['status'] == 'pending')
          .toList(growable: false);
      final acceptedResidenceIds = invitationQuery.docs
          .where(
            (document) =>
                document.data()['status'] == 'accepted' &&
                document.data()['acceptedBy'] == user.uid,
          )
          .map((document) => _residenceReference(document).id)
          .toSet()
          .toList(growable: false);
      final residenceDocuments = await Future.wait([
        for (final invitation in pendingInvitationDocuments)
          _residenceReference(invitation).get(),
      ]);
      final invitations =
          <ResidenceInvitation>[
            for (
              var index = 0;
              index < pendingInvitationDocuments.length;
              index++
            )
              _invitationFromDocument(
                pendingInvitationDocuments[index],
                residenceDocuments[index],
              ),
          ]..sort(
            (first, second) =>
                first.residenceName.compareTo(second.residenceName),
          );

      return AccountResolution(
        phoneNumber: phoneNumber,
        profile:
            userDocument.exists &&
                userDocument.data()?['accountStatus'] != 'deletionRequested'
            ? _profileFromData(userDocument.data()!, phoneNumber)
            : null,
        invitations:
            userDocument.data()?['accountStatus'] == 'deletionRequested'
            ? const []
            : invitations,
        acceptedResidenceIds: acceptedResidenceIds,
        deletionRequested:
            userDocument.data()?['accountStatus'] == 'deletionRequested',
      );
    } on AccountOnboardingFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AccountOnboardingFailure(error.code, error.message);
    } catch (error) {
      throw AccountOnboardingFailure('unknown', error.toString());
    }
  }

  @override
  Future<ResidenceInvitation?> loadPendingInvitation({
    required AuthUser user,
    required String residenceId,
    required String residenceName,
    required String residenceAddress,
  }) async {
    final phoneNumber = _verifiedPhoneNumber(user);
    try {
      final document = await _firestore
          .collection('residences')
          .doc(residenceId)
          .collection('invitations')
          .doc(phoneNumber)
          .get();
      final data = document.data();
      if (!document.exists || data?['status'] != 'pending') return null;
      return ResidenceInvitation(
        path: document.reference.path,
        id: document.id,
        residenceId: residenceId,
        residenceName: residenceName,
        residenceAddress: residenceAddress,
        suggestedFirstName: data?['suggestedFirstName'] as String? ?? '',
        suggestedLastName: data?['suggestedLastName'] as String? ?? '',
        apartmentId: data?['apartmentId'] as String? ?? '',
        role: data?['role'] as String? ?? 'resident',
      );
    } on FirebaseException catch (error) {
      throw AccountOnboardingFailure(error.code, error.message);
    } catch (error) {
      throw AccountOnboardingFailure('unknown', error.toString());
    }
  }

  @override
  Future<void> acceptInvitations({
    required AuthUser user,
    required AccountResolution resolution,
    required List<ResidenceInvitation> invitations,
    required String firstName,
    required String lastName,
  }) async {
    if (invitations.isEmpty) {
      throw const AccountOnboardingFailure('no-invitations-selected');
    }
    final phoneNumber = _verifiedPhoneNumber(user);
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    if (normalizedFirstName.isEmpty || normalizedLastName.isEmpty) {
      throw const AccountOnboardingFailure('missing-profile-data');
    }
    final profile =
        resolution.profile ??
        UserProfile(
          firstName: normalizedFirstName,
          lastName: normalizedLastName,
          phoneNumber: phoneNumber,
        );

    try {
      final batch = _firestore.batch();
      if (resolution.profile == null) {
        batch.set(_firestore.collection('users').doc(user.uid), {
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'phoneNumber': phoneNumber,
          'activeResidenceId': invitations.first.residenceId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (resolution.profile != null &&
          resolution.profile!.activeResidenceId == null) {
        batch.update(_firestore.collection('users').doc(user.uid), {
          'activeResidenceId': invitations.first.residenceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (final invitation in invitations) {
        final invitationReference = _firestore.doc(invitation.path);
        final membershipReference = _firestore
            .collection('residences')
            .doc(invitation.residenceId)
            .collection('members')
            .doc(user.uid);
        batch.update(invitationReference, {
          'suggestedFirstName': profile.firstName,
          'suggestedLastName': profile.lastName,
          'status': 'accepted',
          'acceptedBy': user.uid,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        batch.set(membershipReference, {
          'userId': user.uid,
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'phoneNumber': phoneNumber,
          'apartmentId': invitation.apartmentId,
          'role': invitation.role,
          'hasPresidentPermissions': false,
          'hasProfileImage': false,
          'status': 'active',
          'sourceInvitationId': invitation.id,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on FirebaseException catch (error) {
      throw AccountOnboardingFailure(error.code, error.message);
    } catch (error) {
      throw AccountOnboardingFailure('unknown', error.toString());
    }
  }

  @override
  Future<void> acceptInvitation({
    required AuthUser user,
    required ResidenceInvitation invitation,
    required String firstName,
    required String lastName,
    required String apartmentId,
  }) async {
    final phoneNumber = _verifiedPhoneNumber(user);
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    final normalizedApartmentId = apartmentId.trim();
    if (normalizedFirstName.isEmpty ||
        normalizedLastName.isEmpty ||
        normalizedApartmentId.isEmpty) {
      throw const AccountOnboardingFailure('missing-profile-data');
    }

    try {
      final userReference = _firestore.collection('users').doc(user.uid);
      final userDocument = await userReference.get();
      final batch = _firestore.batch();
      if (!userDocument.exists) {
        batch.set(userReference, {
          'firstName': normalizedFirstName,
          'lastName': normalizedLastName,
          'phoneNumber': phoneNumber,
          'activeResidenceId': invitation.residenceId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(userReference, {
          'firstName': normalizedFirstName,
          'lastName': normalizedLastName,
          'activeResidenceId': invitation.residenceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final invitationReference = _firestore.doc(invitation.path);
      batch.update(invitationReference, {
        'suggestedFirstName': normalizedFirstName,
        'suggestedLastName': normalizedLastName,
        'apartmentId': normalizedApartmentId,
        'status': 'accepted',
        'acceptedBy': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        _firestore
            .collection('residences')
            .doc(invitation.residenceId)
            .collection('members')
            .doc(user.uid),
        {
          'userId': user.uid,
          'firstName': normalizedFirstName,
          'lastName': normalizedLastName,
          'phoneNumber': phoneNumber,
          'apartmentId': normalizedApartmentId,
          'role': invitation.role,
          'hasPresidentPermissions': false,
          'hasProfileImage': false,
          'status': 'active',
          'sourceInvitationId': invitation.id,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();
    } on FirebaseException catch (error) {
      throw AccountOnboardingFailure(error.code, error.message);
    } catch (error) {
      throw AccountOnboardingFailure('unknown', error.toString());
    }
  }

  String _verifiedPhoneNumber(AuthUser user) {
    final phoneNumber = user.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw const AccountOnboardingFailure('missing-phone-number');
    }
    return normalizePhoneNumber(phoneNumber);
  }

  UserProfile _profileFromData(Map<String, dynamic> data, String phoneNumber) {
    return UserProfile(
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phoneNumber: phoneNumber,
      activeResidenceId: data['activeResidenceId'] as String?,
    );
  }

  ResidenceInvitation _invitationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    DocumentSnapshot<Map<String, dynamic>> residenceDocument,
  ) {
    if (!residenceDocument.exists) {
      throw const AccountOnboardingFailure('missing-residence');
    }
    final data = document.data();
    final residenceData = residenceDocument.data()!;
    return ResidenceInvitation(
      path: document.reference.path,
      id: document.id,
      residenceId: residenceDocument.id,
      residenceName: residenceData['name'] as String? ?? '',
      residenceAddress: residenceData['address'] as String? ?? '',
      suggestedFirstName: data['suggestedFirstName'] as String? ?? '',
      suggestedLastName: data['suggestedLastName'] as String? ?? '',
      apartmentId: data['apartmentId'] as String? ?? '',
      role: data['role'] as String? ?? 'resident',
    );
  }

  DocumentReference<Map<String, dynamic>> _residenceReference(
    QueryDocumentSnapshot<Map<String, dynamic>> invitation,
  ) {
    final residenceReference = invitation.reference.parent.parent;
    if (residenceReference == null) {
      throw const AccountOnboardingFailure('invalid-invitation');
    }
    return residenceReference;
  }
}

final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final accountOnboardingRepositoryProvider =
    Provider<AccountOnboardingRepository>(
      (ref) => FirestoreAccountOnboardingRepository(
        ref.watch(firebaseFirestoreProvider),
      ),
    );

final accountResolutionProvider = FutureProvider.autoDispose<AccountResolution>(
  (ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) {
      throw const AccountOnboardingFailure('signed-out');
    }
    return ref.watch(accountOnboardingRepositoryProvider).loadResolution(user);
  },
);
