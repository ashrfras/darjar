import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileResidence {
  const ProfileResidence({
    required this.id,
    required this.name,
    required this.apartmentNumber,
    this.hasImage = false,
  });

  final String id;
  final String name;
  final String? apartmentNumber;
  final bool hasImage;
}

class ResidentProfile {
  const ResidentProfile({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.residences,
    this.profileImagePath = '',
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final List<ProfileResidence> residences;
  final String profileImagePath;

  String get fullName => '$firstName $lastName'.trim();
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ProfileRepository {
  Future<ResidentProfile> load({
    required AuthUser user,
    required ResidenceContext residenceContext,
  });

  Future<void> updateNames({
    required AuthUser user,
    required List<String> residenceIds,
    required String firstName,
    required String lastName,
  });
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ResidentProfile> load({
    required AuthUser user,
    required ResidenceContext residenceContext,
  }) async {
    try {
      final userDocument = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDocument.exists) {
        throw const ProfileFailure('profile-not-found');
      }

      final data = userDocument.data()!;
      final apartmentNumbers = await Future.wait([
        for (final residence in residenceContext.residences)
          _loadApartmentNumber(residence),
      ]);

      return ResidentProfile(
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        phoneNumber: user.phoneNumber ?? '',
        profileImagePath: data['hasProfileImage'] == true
            ? 'users/${user.uid}/profile/image.jpg'
            : '',
        residences: [
          for (
            var index = 0;
            index < residenceContext.residences.length;
            index++
          )
            ProfileResidence(
              id: residenceContext.residences[index].id,
              name: residenceContext.residences[index].name,
              apartmentNumber: apartmentNumbers[index],
              hasImage: residenceContext.residences[index].hasImage,
            ),
        ],
      );
    } on ProfileFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ProfileFailure(error.code, error.message);
    } catch (error) {
      throw ProfileFailure('unknown', error.toString());
    }
  }

  Future<String?> _loadApartmentNumber(UserResidence residence) async {
    if (residence.apartmentId.isEmpty) {
      return null;
    }
    final residenceReference = _firestore
        .collection('residences')
        .doc(residence.id);
    final buildings = await residenceReference.collection('buildings').get();
    for (final building in buildings.docs) {
      final floors = await building.reference.collection('floors').get();
      for (final floor in floors.docs) {
        final apartment = await floor.reference
            .collection('apartments')
            .doc(residence.apartmentId)
            .get();
        if (apartment.exists) {
          return apartment.data()?['number']?.toString();
        }
      }
    }
    return null;
  }

  @override
  Future<void> updateNames({
    required AuthUser user,
    required List<String> residenceIds,
    required String firstName,
    required String lastName,
  }) async {
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    if (normalizedFirstName.isEmpty || normalizedLastName.isEmpty) {
      throw const ProfileFailure('invalid-name');
    }

    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(user.uid), {
        'firstName': normalizedFirstName,
        'lastName': normalizedLastName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final residenceId in residenceIds) {
        batch.update(
          _firestore
              .collection('residences')
              .doc(residenceId)
              .collection('members')
              .doc(user.uid),
          {
            'firstName': normalizedFirstName,
            'lastName': normalizedLastName,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      throw ProfileFailure(error.code, error.message);
    } catch (error) {
      throw ProfileFailure('unknown', error.toString());
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirestoreProfileRepository(ref.watch(firebaseFirestoreProvider));
});

class ResidentProfileController extends AsyncNotifier<ResidentProfile> {
  AuthUser? _user;
  ResidenceContext? _residenceContext;

  @override
  Future<ResidentProfile> build() async {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) {
      throw const ProfileFailure('signed-out');
    }
    final residenceContext = await ref.watch(residenceContextProvider.future);
    _user = user;
    _residenceContext = residenceContext;
    return ref
        .watch(profileRepositoryProvider)
        .load(user: user, residenceContext: residenceContext);
  }

  Future<void> updateNames({
    required String firstName,
    required String lastName,
  }) async {
    final user = _user;
    final residenceContext = _residenceContext;
    if (user == null || residenceContext == null) {
      throw const ProfileFailure('profile-not-loaded');
    }
    await ref
        .read(profileRepositoryProvider)
        .updateNames(
          user: user,
          residenceIds: [
            for (final residence in residenceContext.residences) residence.id,
          ],
          firstName: firstName,
          lastName: lastName,
        );
    ref.invalidate(residenceMembersProvider);
    ref.invalidateSelf();
  }
}

final residentProfileProvider =
    AsyncNotifierProvider<ResidentProfileController, ResidentProfile>(
      ResidentProfileController.new,
    );
