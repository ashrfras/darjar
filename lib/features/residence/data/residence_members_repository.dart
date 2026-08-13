import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/performance/data_load_timer.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResidenceMemberRole { president, deputy, treasurer, resident }

enum ResidenceDuesTrackingStatus { active, notStarted }

int residenceMemberRolePriority(ResidenceMemberRole role) => switch (role) {
  ResidenceMemberRole.president => 0,
  ResidenceMemberRole.deputy => 1,
  ResidenceMemberRole.treasurer => 2,
  ResidenceMemberRole.resident => 3,
};

int compareResidenceMembersByRole(
  ResidenceMember first,
  ResidenceMember second,
) {
  final roleComparison = residenceMemberRolePriority(
    first.role,
  ).compareTo(residenceMemberRolePriority(second.role));
  return roleComparison != 0
      ? roleComparison
      : first.name.compareTo(second.name);
}

class ResidenceMember {
  const ResidenceMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.hasPresidentPermissions = false,
    this.hasProfileImage = false,
    this.apartmentId,
  });

  final String id;
  final String name;
  final String phone;
  final ResidenceMemberRole role;
  final bool hasPresidentPermissions;
  final bool hasProfileImage;
  final String? apartmentId;

  bool get canManageResidence =>
      role == ResidenceMemberRole.president || hasPresidentPermissions;
}

class ResidencePendingInvitation {
  const ResidencePendingInvitation({
    required this.id,
    required this.name,
    required this.phone,
    required this.apartmentId,
  });

  final String id;
  final String name;
  final String phone;
  final String apartmentId;
}

class ResidenceApartment {
  const ResidenceApartment({
    required this.id,
    required this.number,
    required this.floorId,
    this.buildingId = '',
    this.createdAt,
    this.duesTrackingStatus = ResidenceDuesTrackingStatus.active,
    this.duesTrackingStartPeriodKey = '',
    this.openingPaidThroughPeriodKey = '',
  });

  final String id;
  final String number;
  final String floorId;
  final String buildingId;
  final DateTime? createdAt;
  final ResidenceDuesTrackingStatus duesTrackingStatus;
  final String duesTrackingStartPeriodKey;
  final String openingPaidThroughPeriodKey;

  bool get isDuesTrackingActive =>
      duesTrackingStatus == ResidenceDuesTrackingStatus.active;
}

int compareResidenceApartmentNumbers(String first, String second) {
  final firstNumber = int.tryParse(first.trim());
  final secondNumber = int.tryParse(second.trim());
  if (firstNumber != null && secondNumber != null) {
    final numericComparison = firstNumber.compareTo(secondNumber);
    if (numericComparison != 0) return numericComparison;
  }
  return first.compareTo(second);
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
  const ResidenceMembersData({
    required this.buildings,
    required this.members,
    this.pendingInvitations = const [],
  });

  static const empty = ResidenceMembersData(buildings: [], members: []);

  final List<ResidenceBuilding> buildings;
  final List<ResidenceMember> members;
  final List<ResidencePendingInvitation> pendingInvitations;

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
  Future<ResidenceMembersData> load(
    String residenceId, {
    bool includeInvitations = true,
  });

  Future<void> createInvitation({
    required String residenceId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String apartmentId,
  });

  Future<void> deleteInvitation({
    required String residenceId,
    required String invitationId,
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
    required ResidenceDuesTrackingStatus duesTrackingStatus,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
  });

  Future<void> startApartmentDuesTracking({
    required String residenceId,
    required ResidenceApartment apartment,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
  });

  Future<void> moveApartmentToFloor({
    required String residenceId,
    required ResidenceApartment apartment,
    required String floorId,
  });

  Future<void> deleteApartment({
    required String residenceId,
    required ResidenceApartment apartment,
  });

  Future<void> removeMember({
    required String residenceId,
    required String memberId,
  });

  Future<void> changeRole({
    required String residenceId,
    required String memberId,
    required ResidenceMemberRole role,
  });

  Future<void> setPresidentPermissions({
    required String residenceId,
    required String memberId,
    required bool enabled,
  });

  Future<void> transferPresidency({
    required String residenceId,
    required String currentPresidentId,
    required String newPresidentId,
  });
}

class FirestoreResidenceMembersRepository
    implements ResidenceMembersRepository {
  FirestoreResidenceMembersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ResidenceMembersData> load(
    String residenceId, {
    bool includeInvitations = true,
  }) async {
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      final results = await Future.wait([
        residence.collection('buildings').get(),
        residence
            .collection('members')
            .where('status', isEqualTo: 'active')
            .get(),
        if (includeInvitations)
          residence
              .collection('invitations')
              .where('status', isEqualTo: 'pending')
              .get(),
      ]);
      final buildingDocuments = results[0];
      final memberDocuments = results[1];
      final invitationDocuments = includeInvitations ? results[2] : null;

      final buildings = await Future.wait([
        for (final building in buildingDocuments.docs) _loadBuilding(building),
      ]);
      buildings.sort((a, b) => a.nameAr.compareTo(b.nameAr));

      final members = [
        for (final document in memberDocuments.docs)
          _memberFromDocument(document),
      ]..sort((a, b) => a.name.compareTo(b.name));
      final pendingInvitations = [
        for (final document in invitationDocuments?.docs ?? const [])
          _pendingInvitationFromDocument(document),
      ]..sort((a, b) => a.name.compareTo(b.name));

      return ResidenceMembersData(
        buildings: buildings,
        members: members,
        pendingInvitations: pendingInvitations,
      );
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
          createdAt: (document.data()['createdAt'] as Timestamp?)?.toDate(),
          duesTrackingStatus: _duesTrackingStatusFromValue(
            document.data()['duesTrackingStatus'] as String?,
          ),
          duesTrackingStartPeriodKey:
              document.data()['duesTrackingStartPeriodKey'] as String? ?? '',
          openingPaidThroughPeriodKey:
              document.data()['openingPaidThroughPeriodKey'] as String? ?? '',
        ),
    ]..sort((a, b) => compareResidenceApartmentNumbers(a.number, b.number));
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
      role: _roleFromValue(data['role'] as String?),
      hasPresidentPermissions:
          data['hasPresidentPermissions'] as bool? ?? false,
      // Legacy memberships predate this field. Trying the deterministic path
      // once lets their already-uploaded photo appear without a migration.
      hasProfileImage: data['hasProfileImage'] as bool? ?? true,
      apartmentId: apartmentId.isEmpty ? null : apartmentId,
    );
  }

  ResidenceMemberRole _roleFromValue(String? value) {
    return switch (value) {
      'president' || 'owner' => ResidenceMemberRole.president,
      'deputy' || 'manager' => ResidenceMemberRole.deputy,
      'treasurer' || 'moderator' => ResidenceMemberRole.treasurer,
      _ => ResidenceMemberRole.resident,
    };
  }

  ResidencePendingInvitation _pendingInvitationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final firstName = data['suggestedFirstName'] as String? ?? '';
    final lastName = data['suggestedLastName'] as String? ?? '';
    return ResidencePendingInvitation(
      id: document.id,
      name: '$firstName $lastName'.trim(),
      phone: data['phoneNumber'] as String? ?? '',
      apartmentId: data['apartmentId'] as String? ?? '',
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
    final normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
    if (normalizedPhoneNumber.isEmpty) {
      throw const ResidenceMembersFailure('invalid-phone-number');
    }
    final invitations = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('invitations');
    try {
      final invitation = invitations.doc(normalizedPhoneNumber);
      await _firestore.runTransaction((transaction) async {
        final existingInvitation = await transaction.get(invitation);
        if (existingInvitation.exists) {
          throw const ResidenceMembersFailure('invitation-already-exists');
        }
        transaction.set(invitation, {
          'suggestedFirstName': firstName.trim(),
          'suggestedLastName': lastName.trim(),
          'phoneNumber': normalizedPhoneNumber,
          'apartmentId': apartmentId,
          'role': ResidenceMemberRole.resident.name,
          'hasPresidentPermissions': false,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on ResidenceMembersFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceMembersFailure(error.code, error.message);
    }
  }

  @override
  Future<void> deleteInvitation({
    required String residenceId,
    required String invitationId,
  }) async {
    try {
      await _firestore
          .collection('residences')
          .doc(residenceId)
          .collection('invitations')
          .doc(invitationId)
          .delete();
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
    required ResidenceDuesTrackingStatus duesTrackingStatus,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
  }) async {
    final apartment = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('buildings')
        .doc(buildingId)
        .collection('floors')
        .doc(floorId)
        .collection('apartments')
        .doc();
    final batch = _firestore.batch();
    final trackingStartPeriodKey = _openingTrackingStartPeriodKey(
      openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
      currentPeriodKey: currentPeriodKey,
    );
    batch.set(apartment, {
      'number': int.parse(number.trim()),
      'duesTrackingStatus': duesTrackingStatus.name,
      'duesTrackingStartPeriodKey':
          duesTrackingStatus == ResidenceDuesTrackingStatus.active
          ? trackingStartPeriodKey
          : '',
      'openingPaidThroughPeriodKey':
          duesTrackingStatus == ResidenceDuesTrackingStatus.active
          ? openingPaidThroughPeriodKey ?? ''
          : '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (duesTrackingStatus == ResidenceDuesTrackingStatus.active) {
      _addOpeningDuesToBatch(
        batch: batch,
        residenceId: residenceId,
        apartmentId: apartment.id,
        apartmentNumber: number.trim(),
        openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
        currentPeriodKey: currentPeriodKey,
        defaultAmount: defaultAmount,
      );
    }
    await batch.commit();
  }

  @override
  Future<void> startApartmentDuesTracking({
    required String residenceId,
    required ResidenceApartment apartment,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
  }) async {
    if (apartment.isDuesTrackingActive) return;
    final apartmentReference = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('buildings')
        .doc(apartment.buildingId)
        .collection('floors')
        .doc(apartment.floorId)
        .collection('apartments')
        .doc(apartment.id);
    final batch = _firestore.batch();
    batch.update(apartmentReference, {
      'duesTrackingStatus': ResidenceDuesTrackingStatus.active.name,
      'duesTrackingStartPeriodKey': _openingTrackingStartPeriodKey(
        openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
        currentPeriodKey: currentPeriodKey,
      ),
      'openingPaidThroughPeriodKey': openingPaidThroughPeriodKey ?? '',
      'duesTrackingStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addOpeningDuesToBatch(
      batch: batch,
      residenceId: residenceId,
      apartmentId: apartment.id,
      apartmentNumber: apartment.number,
      openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
      currentPeriodKey: currentPeriodKey,
      defaultAmount: defaultAmount,
    );
    await batch.commit();
  }

  @override
  Future<void> moveApartmentToFloor({
    required String residenceId,
    required ResidenceApartment apartment,
    required String floorId,
  }) async {
    if (floorId == apartment.floorId) return;
    final building = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('buildings')
        .doc(apartment.buildingId);
    final source = building
        .collection('floors')
        .doc(apartment.floorId)
        .collection('apartments')
        .doc(apartment.id);
    final destination = building
        .collection('floors')
        .doc(floorId)
        .collection('apartments')
        .doc(apartment.id);
    await _firestore.runTransaction((transaction) async {
      final sourceDocument = await transaction.get(source);
      final data = sourceDocument.data();
      if (!sourceDocument.exists || data == null) {
        throw const ResidenceMembersFailure('apartment-not-found');
      }
      transaction.set(destination, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(source);
    });
  }

  void _addOpeningDuesToBatch({
    required WriteBatch batch,
    required String residenceId,
    required String apartmentId,
    required String apartmentNumber,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
  }) {
    final dues = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('dues');
    final paidThroughCurrent =
        openingPaidThroughPeriodKey != null &&
        openingPaidThroughPeriodKey.compareTo(currentPeriodKey) >= 0;
    final start = _openingTrackingStartPeriodKey(
      openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
      currentPeriodKey: currentPeriodKey,
    );
    for (final periodKey in _periodKeysThrough(start, currentPeriodKey)) {
      final paid = paidThroughCurrent && periodKey == currentPeriodKey;
      batch.set(dues.doc('${periodKey}_$apartmentId'), {
        'apartmentId': apartmentId,
        'apartmentNumber': apartmentNumber,
        'periodKey': periodKey,
        'amountDue': defaultAmount,
        'amountPaid': paid ? defaultAmount : 0,
        'status': paid || defaultAmount == 0 ? 'paid' : 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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

  @override
  Future<void> changeRole({
    required String residenceId,
    required String memberId,
    required ResidenceMemberRole role,
  }) async {
    if (role == ResidenceMemberRole.president) {
      throw const ResidenceMembersFailure('presidency-transfer-required');
    }
    await _members(residenceId).doc(memberId).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPresidentPermissions({
    required String residenceId,
    required String memberId,
    required bool enabled,
  }) async {
    await _members(residenceId).doc(memberId).update({
      'hasPresidentPermissions': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> transferPresidency({
    required String residenceId,
    required String currentPresidentId,
    required String newPresidentId,
  }) async {
    final residence = _firestore.collection('residences').doc(residenceId);
    final currentPresident = _members(residenceId).doc(currentPresidentId);
    final newPresident = _members(residenceId).doc(newPresidentId);
    try {
      await _firestore.runTransaction((transaction) async {
        final residenceDocument = await transaction.get(residence);
        final currentDocument = await transaction.get(currentPresident);
        final newDocument = await transaction.get(newPresident);
        final storedPresidentId =
            residenceDocument.data()?['presidentId'] as String?;
        final currentRole = currentDocument.data()?['role'] as String?;
        if (!currentDocument.exists ||
            !newDocument.exists ||
            newDocument.data()?['status'] != 'active' ||
            (storedPresidentId != null &&
                storedPresidentId != currentPresidentId) ||
            (storedPresidentId == null &&
                currentRole != 'president' &&
                currentRole != 'owner')) {
          throw const ResidenceMembersFailure('invalid-presidency-transfer');
        }
        transaction.update(residence, {
          'presidentId': newPresidentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(currentPresident, {
          'role': ResidenceMemberRole.resident.name,
          'hasPresidentPermissions': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(newPresident, {
          'role': ResidenceMemberRole.president.name,
          'hasPresidentPermissions': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on ResidenceMembersFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceMembersFailure(error.code, error.message);
    }
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
    return measureDataLoad('residence members', () async {
      final activeResidence = await ref.watch(
        residenceContextProvider.selectAsync(
          (context) => context.activeResidence,
        ),
      );
      final residenceId = activeResidence?.id;
      _residenceId = residenceId;
      if (residenceId == null) {
        return ResidenceMembersData.empty;
      }
      return ref
          .read(residenceMembersRepositoryProvider)
          .load(
            residenceId,
            includeInvitations: activeResidence!.canManageResidence,
          );
    });
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
    ref.invalidateSelf();
  }

  Future<void> deleteInvitation(String invitationId) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .deleteInvitation(
          residenceId: _requiredResidenceId(),
          invitationId: invitationId,
        );
    ref.invalidateSelf();
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
    required ResidenceDuesTrackingStatus duesTrackingStatus,
    required String? openingPaidThroughPeriodKey,
  }) async {
    final settings = await ref.read(residenceSettingsProvider.future);
    final currentPeriodKey = _periodKey(DateTime.now());
    await measureDataLoad(
      'add apartment write',
      () => ref
          .read(residenceMembersRepositoryProvider)
          .addApartment(
            residenceId: _requiredResidenceId(),
            buildingId: buildingId,
            floorId: floorId,
            number: number,
            duesTrackingStatus: duesTrackingStatus,
            openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
            currentPeriodKey: currentPeriodKey,
            defaultAmount: settings.defaultSubscriptionAmount,
          ),
    );
    ref.invalidateSelf();
  }

  Future<void> startApartmentDuesTracking({
    required ResidenceApartment apartment,
    required String? openingPaidThroughPeriodKey,
  }) async {
    final settings = await ref.read(residenceSettingsProvider.future);
    await ref
        .read(residenceMembersRepositoryProvider)
        .startApartmentDuesTracking(
          residenceId: _requiredResidenceId(),
          apartment: apartment,
          openingPaidThroughPeriodKey: openingPaidThroughPeriodKey,
          currentPeriodKey: _periodKey(DateTime.now()),
          defaultAmount: settings.defaultSubscriptionAmount,
        );
    ref.invalidateSelf();
  }

  Future<void> moveApartmentToFloor({
    required ResidenceApartment apartment,
    required String floorId,
  }) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .moveApartmentToFloor(
          residenceId: _requiredResidenceId(),
          apartment: apartment,
          floorId: floorId,
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

  Future<void> changeRole(String memberId, ResidenceMemberRole role) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .changeRole(
          residenceId: _requiredResidenceId(),
          memberId: memberId,
          role: role,
        );
    ref.invalidateSelf();
  }

  Future<void> setPresidentPermissions(String memberId, bool enabled) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .setPresidentPermissions(
          residenceId: _requiredResidenceId(),
          memberId: memberId,
          enabled: enabled,
        );
    ref.invalidateSelf();
  }

  Future<void> transferPresidency({
    required String currentPresidentId,
    required String newPresidentId,
  }) async {
    await ref
        .read(residenceMembersRepositoryProvider)
        .transferPresidency(
          residenceId: _requiredResidenceId(),
          currentPresidentId: currentPresidentId,
          newPresidentId: newPresidentId,
        );
    ref.invalidate(residenceContextProvider);
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

final residenceDirectoryProvider = FutureProvider<ResidenceMembersData>((ref) {
  final residenceId = ref.watch(
    residenceContextProvider.select(
      (context) => context.value?.activeResidence?.id,
    ),
  );
  if (residenceId == null) return ResidenceMembersData.empty;

  return ref
      .watch(residenceMembersRepositoryProvider)
      .load(residenceId, includeInvitations: false);
});

ResidenceDuesTrackingStatus _duesTrackingStatusFromValue(String? value) {
  return value == ResidenceDuesTrackingStatus.notStarted.name
      ? ResidenceDuesTrackingStatus.notStarted
      : ResidenceDuesTrackingStatus.active;
}

String _openingTrackingStartPeriodKey({
  required String? openingPaidThroughPeriodKey,
  required String currentPeriodKey,
}) {
  if (openingPaidThroughPeriodKey == null ||
      openingPaidThroughPeriodKey.compareTo(currentPeriodKey) >= 0) {
    return currentPeriodKey;
  }
  final paidThrough = _periodDate(openingPaidThroughPeriodKey);
  return _periodKey(DateTime(paidThrough.year, paidThrough.month + 1));
}

Iterable<String> _periodKeysThrough(String startKey, String endKey) sync* {
  var period = _periodDate(startKey);
  final end = _periodDate(endKey);
  while (!period.isAfter(end)) {
    yield _periodKey(period);
    period = DateTime(period.year, period.month + 1);
  }
}

DateTime _periodDate(String periodKey) {
  final parts = periodKey.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

String _periodKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';
