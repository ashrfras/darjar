import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResidenceMemberRole { resident, moderator, manager, owner }

class ResidenceMember {
  const ResidenceMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.apartmentId,
  });

  final String id;
  final String name;
  final String phone;
  final ResidenceMemberRole role;
  final String? apartmentId;
}

class ResidenceApartment {
  const ResidenceApartment({
    required this.id,
    required this.number,
    required this.floorId,
    this.buildingId = '',
  });

  final String id;
  final String number;
  final String floorId;
  final String buildingId;
}

class ResidenceFloor {
  const ResidenceFloor({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.apartments,
    this.order,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<ResidenceApartment> apartments;
  final int? order;
}

int compareResidenceFloorsByOrder(ResidenceFloor first, ResidenceFloor second) {
  const missingOrder = 0x7fffffff;
  final orderComparison = (first.order ?? missingOrder).compareTo(
    second.order ?? missingOrder,
  );
  return orderComparison != 0 ? orderComparison : first.id.compareTo(second.id);
}

class ResidenceBuilding {
  const ResidenceBuilding({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.floors,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<ResidenceFloor> floors;
}

class ResidenceMembersData {
  const ResidenceMembersData({required this.buildings, required this.members});

  static const empty = ResidenceMembersData(buildings: [], members: []);

  final List<ResidenceBuilding> buildings;
  final List<ResidenceMember> members;

  List<ResidenceApartment> get apartments => [
    for (final building in buildings)
      for (final floor in building.floors) ...floor.apartments,
  ];
}

class ResidenceMembersFailure implements Exception {
  const ResidenceMembersFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceMembersRepository {
  Future<ResidenceMembersData> load(String residenceId);

  Future<void> createInvitation({
    required String residenceId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String apartmentId,
  });

  Future<void> assignApartment({
    required String residenceId,
    required String memberId,
    required String? apartmentId,
  });

  Future<void> addApartment({
    required String residenceId,
    required String buildingId,
    required String floorId,
    required String number,
  });

  Future<void> deleteApartment({
    required String residenceId,
    required ResidenceApartment apartment,
  });

  Future<void> removeMember({
    required String residenceId,
    required String memberId,
  });
}

class FirestoreResidenceMembersRepository
    implements ResidenceMembersRepository {
  FirestoreResidenceMembersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ResidenceMembersData> load(String residenceId) async {
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      final results = await Future.wait([
        residence.collection('buildings').get(),
        residence
            .collection('members')
            .where('status', isEqualTo: 'active')
            .get(),
      ]);
      final buildingDocuments = results[0];
      final memberDocuments = results[1];

      final buildings = await Future.wait([
        for (final building in buildingDocuments.docs) _loadBuilding(building),
      ]);
      buildings.sort((a, b) => a.nameAr.compareTo(b.nameAr));

      final members = [
        for (final document in memberDocuments.docs)
          _memberFromDocument(document),
      ]..sort((a, b) => a.name.compareTo(b.name));

      return ResidenceMembersData(buildings: buildings, members: members);
    } on FirebaseException catch (error) {
      throw ResidenceMembersFailure(error.code, error.message);
    } catch (error) {
      throw ResidenceMembersFailure('unknown', error.toString());
    }
  }

  Future<ResidenceBuilding> _loadBuilding(
    QueryDocumentSnapshot<Map<String, dynamic>> building,
  ) async {
    final floorDocuments = await building.reference.collection('floors').get();
    final floors = await Future.wait([
      for (final floor in floorDocuments.docs) _loadFloor(floor),
    ]);
    floors.sort(compareResidenceFloorsByOrder);
    final data = building.data();
    return ResidenceBuilding(
      id: building.id,
      nameAr: data['nameAr'] as String? ?? data['name'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? data['name'] as String? ?? '',
      floors: floors,
    );
  }

  Future<ResidenceFloor> _loadFloor(
    QueryDocumentSnapshot<Map<String, dynamic>> floor,
  ) async {
    final apartmentDocuments = await floor.reference
        .collection('apartments')
        .get();
    final apartments = [
      for (final document in apartmentDocuments.docs)
        ResidenceApartment(
          id: document.id,
          number: document.data()['number']?.toString() ?? '',
          floorId: floor.id,
          buildingId: floor.reference.parent.parent?.id ?? '',
        ),
    ]..sort((a, b) => a.number.compareTo(b.number));
    final data = floor.data();
    return ResidenceFloor(
      id: floor.id,
      nameAr: data['nameAr'] as String? ?? data['name'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? data['name'] as String? ?? '',
      apartments: apartments,
      order: data['order'] as int?,
    );
  }

  ResidenceMember _memberFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final firstName = data['firstName'] as String? ?? '';
    final lastName = data['lastName'] as String? ?? '';
    final apartmentId = data['apartmentId'] as String? ?? '';
    return ResidenceMember(
      id: document.id,
      name: '$firstName $lastName'.trim().isEmpty
          ? document.id
          : '$firstName $lastName'.trim(),
      phone: data['phoneNumber'] as String? ?? '',
      role: ResidenceMemberRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => ResidenceMemberRole.resident,
      ),
      apartmentId: apartmentId.isEmpty ? null : apartmentId,
    );
  }

  @override
  Future<void> createInvitation({
    required String residenceId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String apartmentId,
  }) async {
    try {
      await _firestore
          .collection('residences')
          .doc(residenceId)
          .collection('invitations')
          .add({
            'suggestedFirstName': firstName.trim(),
            'suggestedLastName': lastName.trim(),
            'phoneNumber': phoneNumber.replaceAll(RegExp(r'\s'), ''),
            'apartmentId': apartmentId,
            'role': ResidenceMemberRole.resident.name,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      throw ResidenceMembersFailure(error.code, error.message);
    }
  }

  @override
  Future<void> assignApartment({
    required String residenceId,
    required String memberId,
    required String? apartmentId,
  }) async {
    await _members(residenceId).doc(memberId).update({
      'apartmentId': apartmentId ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addApartment({
    required String residenceId,
    required String buildingId,
    required String floorId,
    required String number,
  }) async {
    await _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('buildings')
        .doc(buildingId)
        .collection('floors')
        .doc(floorId)
        .collection('apartments')
        .add({
          'number': int.parse(number.trim()),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> deleteApartment({
    required String residenceId,
    required ResidenceApartment apartment,
  }) async {
    final residence = _firestore.collection('residences').doc(residenceId);
    final assignedMembers = await residence
        .collection('members')
        .where('apartmentId', isEqualTo: apartment.id)
        .get();
    final batch = _firestore.batch();
    batch.delete(
      residence
          .collection('buildings')
          .doc(apartment.buildingId)
          .collection('floors')
          .doc(apartment.floorId)
          .collection('apartments')
          .doc(apartment.id),
    );
    for (final member in assignedMembers.docs) {
      batch.update(member.reference, {
        'apartmentId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> removeMember({
    required String residenceId,
    required String memberId,
  }) async {
    await _members(residenceId).doc(memberId).update({
      'status': 'removed',
      'apartmentId': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> _members(String residenceId) {
    return _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('members');
  }
}

final residenceMembersRepositoryProvider = Provider<ResidenceMembersRepository>(
  (ref) =>
      FirestoreResidenceMembersRepository(ref.watch(firebaseFirestoreProvider)),
);

class ResidenceMembersController extends AsyncNotifier<ResidenceMembersData> {
  String? _residenceId;

  @override
  Future<ResidenceMembersData> build() async {
    _residenceId = await ref.watch(
      residenceContextProvider.selectAsync(
        (context) => context.activeResidenceId,
      ),
    );
    final residenceId = _residenceId;
    if (residenceId == null) {
      return ResidenceMembersData.empty;
    }
    return ref.read(residenceMembersRepositoryProvider).load(residenceId);
  }

  Future<void> createInvitation({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String apartmentId,
  }) async {
    final residenceId = _requiredResidenceId();
    await ref
        .read(residenceMembersRepositoryProvider)
        .createInvitation(
          residenceId: residenceId,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          apartmentId: apartmentId,
        );
  }

  Future<void> assignApartment(String memberId, String? apartmentId) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .assignApartment(
          residenceId: _requiredResidenceId(),
          memberId: memberId,
          apartmentId: apartmentId,
        );
    ref.invalidateSelf();
  }

  Future<void> addApartment({
    required String buildingId,
    required String floorId,
    required String number,
  }) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .addApartment(
          residenceId: _requiredResidenceId(),
          buildingId: buildingId,
          floorId: floorId,
          number: number,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteApartment(ResidenceApartment apartment) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .deleteApartment(
          residenceId: _requiredResidenceId(),
          apartment: apartment,
        );
    ref.invalidateSelf();
  }

  Future<void> removeMember(String memberId) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .removeMember(residenceId: _requiredResidenceId(), memberId: memberId);
    ref.invalidateSelf();
  }

  String _requiredResidenceId() {
    final residenceId = _residenceId;
    if (residenceId == null) {
      throw const ResidenceMembersFailure('missing-active-residence');
    }
    return residenceId;
  }
}

final residenceMembersProvider =
    AsyncNotifierProvider<ResidenceMembersController, ResidenceMembersData>(
      ResidenceMembersController.new,
    );
