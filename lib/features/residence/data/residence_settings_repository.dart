import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceBuildingConfiguration {
  const ResidenceBuildingConfiguration({
    required this.id,
    required this.name,
    required this.floorCount,
  });

  final String id;
  final String name;
  final int floorCount;

  ResidenceBuildingConfiguration copyWith({String? name, int? floorCount}) {
    return ResidenceBuildingConfiguration(
      id: id,
      name: name ?? this.name,
      floorCount: floorCount ?? this.floorCount,
    );
  }
}

class ResidenceSettings {
  const ResidenceSettings({
    required this.residenceId,
    required this.joinCode,
    required this.name,
    required this.address,
    required this.city,
    required this.establishmentYear,
    required this.defaultSubscriptionAmount,
    required this.invitationUrl,
    required this.joinRequestsEnabled,
    required this.hasImage,
    required this.buildings,
    required this.managementOrganization,
    required this.managementPhone,
    required this.bankName,
    required this.bankAccount,
  });

  final String residenceId;
  final String joinCode;
  final String name;
  final String address;
  final String city;
  final int establishmentYear;
  final int defaultSubscriptionAmount;
  final String invitationUrl;
  final bool joinRequestsEnabled;
  final bool hasImage;
  final List<ResidenceBuildingConfiguration> buildings;
  final String managementOrganization;
  final String managementPhone;
  final String bankName;
  final String bankAccount;

  ResidenceSettings copyWith({
    String? name,
    String? address,
    String? city,
    int? establishmentYear,
    int? defaultSubscriptionAmount,
    bool? joinRequestsEnabled,
    bool? hasImage,
    List<ResidenceBuildingConfiguration>? buildings,
    String? managementOrganization,
    String? managementPhone,
    String? bankName,
    String? bankAccount,
  }) {
    return ResidenceSettings(
      residenceId: residenceId,
      joinCode: joinCode,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      establishmentYear: establishmentYear ?? this.establishmentYear,
      defaultSubscriptionAmount:
          defaultSubscriptionAmount ?? this.defaultSubscriptionAmount,
      invitationUrl: invitationUrl,
      joinRequestsEnabled: joinRequestsEnabled ?? this.joinRequestsEnabled,
      hasImage: hasImage ?? this.hasImage,
      buildings: buildings ?? this.buildings,
      managementOrganization:
          managementOrganization ?? this.managementOrganization,
      managementPhone: managementPhone ?? this.managementPhone,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }
}

class ResidenceSettingsFailure implements Exception {
  const ResidenceSettingsFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceSettingsRepository {
  Future<ResidenceSettings> load(String residenceId);

  Future<void> save(ResidenceSettings settings);
}

class FirestoreResidenceSettingsRepository
    implements ResidenceSettingsRepository {
  FirestoreResidenceSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ResidenceSettings> load(String residenceId) async {
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      final results = await Future.wait([
        residence.get(),
        residence.collection('settings').doc('private').get(),
        residence.collection('buildings').get(),
      ]);
      final residenceDocument =
          results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final privateDocument =
          results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final buildingDocuments =
          results[2] as QuerySnapshot<Map<String, dynamic>>;
      if (!residenceDocument.exists) {
        throw const ResidenceSettingsFailure('residence-not-found');
      }
      if (!privateDocument.exists) {
        throw const ResidenceSettingsFailure('settings-not-found');
      }
      final buildings = await Future.wait([
        for (final building in buildingDocuments.docs)
          _buildingConfiguration(building),
      ]);
      buildings.sort((a, b) => a.name.compareTo(b.name));
      final residenceData = residenceDocument.data()!;
      final privateData = privateDocument.data()!;
      final joinCode = privateData['joinCode'] as String;
      return ResidenceSettings(
        residenceId: residenceId,
        joinCode: joinCode,
        name: residenceData['name'] as String,
        address: residenceData['address'] as String,
        city: residenceData['city'] as String,
        establishmentYear: residenceData['establishmentYear'] as int,
        defaultSubscriptionAmount:
            privateData['defaultSubscriptionAmount'] as int,
        invitationUrl: 'https://darjar.app/join/$joinCode',
        joinRequestsEnabled: residenceData['joinRequestsEnabled'] as bool,
        hasImage: residenceData['hasImage'] as bool,
        buildings: buildings,
        managementOrganization: privateData['managementOrganization'] as String,
        managementPhone: privateData['managementPhone'] as String,
        bankName: privateData['bankName'] as String,
        bankAccount: privateData['bankAccount'] as String,
      );
    } on ResidenceSettingsFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceSettingsFailure(error.code, error.message);
    }
  }

  Future<ResidenceBuildingConfiguration> _buildingConfiguration(
    QueryDocumentSnapshot<Map<String, dynamic>> building,
  ) async {
    final floors = await building.reference.collection('floors').get();
    return ResidenceBuildingConfiguration(
      id: building.id,
      name:
          building.data()['nameAr'] as String? ??
          building.data()['name'] as String? ??
          '',
      floorCount: floors.size,
    );
  }

  @override
  Future<void> save(ResidenceSettings settings) async {
    try {
      final residence = _firestore
          .collection('residences')
          .doc(settings.residenceId);
      final existingBuildings = await residence.collection('buildings').get();
      final desiredById = {
        for (final building in settings.buildings) building.id: building,
      };
      final floorsByBuilding =
          <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final building in existingBuildings.docs) {
        final floors = await building.reference.collection('floors').get();
        final floorDocuments = [...floors.docs]
          ..sort(
            (first, second) => ((first.data()['order'] as int?) ?? 0).compareTo(
              (second.data()['order'] as int?) ?? 0,
            ),
          );
        floorsByBuilding[building.id] = floorDocuments;
      }

      final batch = _firestore.batch();
      batch.update(residence, {
        'name': settings.name,
        'address': settings.address,
        'city': settings.city,
        'establishmentYear': settings.establishmentYear,
        'hasImage': settings.hasImage,
        'joinRequestsEnabled': settings.joinRequestsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(residence.collection('settings').doc('private'), {
        'managementOrganization': settings.managementOrganization,
        'managementPhone': settings.managementPhone,
        'bankName': settings.bankName,
        'bankAccount': settings.bankAccount,
        'defaultSubscriptionAmount': settings.defaultSubscriptionAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final existing in existingBuildings.docs) {
        if (desiredById.containsKey(existing.id)) continue;
        final floors = floorsByBuilding[existing.id] ?? const [];
        await _ensureFloorsAreEmpty(floors);
        for (final floor in floors) {
          batch.delete(floor.reference);
        }
        batch.delete(existing.reference);
      }

      for (final desired in settings.buildings) {
        final buildingReference = residence
            .collection('buildings')
            .doc(desired.id);
        batch.set(buildingReference, {
          'nameAr': desired.name,
          'nameEn': desired.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final existingFloors = floorsByBuilding[desired.id] ?? const [];
        if (desired.floorCount < existingFloors.length) {
          final removedFloors = existingFloors
              .skip(desired.floorCount)
              .toList();
          await _ensureFloorsAreEmpty(removedFloors);
          for (final floor in removedFloors) {
            batch.delete(floor.reference);
          }
        }
        for (
          var index = existingFloors.length;
          index < desired.floorCount;
          index++
        ) {
          final floorReference = buildingReference
              .collection('floors')
              .doc('floor-${index + 1}');
          batch.set(floorReference, {
            'nameAr': _arabicFloorName(index),
            'nameEn': _englishFloorName(index),
            'order': index,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
    } on ResidenceSettingsFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceSettingsFailure(error.code, error.message);
    }
  }

  Future<void> _ensureFloorsAreEmpty(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> floors,
  ) async {
    for (final floor in floors) {
      final apartments = await floor.reference
          .collection('apartments')
          .limit(1)
          .get();
      if (apartments.docs.isNotEmpty) {
        throw const ResidenceSettingsFailure('structure-not-empty');
      }
    }
  }

  String _arabicFloorName(int index) {
    const names = [
      'الطابق الأرضي',
      'الطابق الأول',
      'الطابق الثاني',
      'الطابق الثالث',
      'الطابق الرابع',
      'الطابق الخامس',
      'الطابق السادس',
      'الطابق السابع',
      'الطابق الثامن',
      'الطابق التاسع',
    ];
    return index < names.length ? names[index] : 'الطابق ${index + 1}';
  }

  String _englishFloorName(int index) {
    return index == 0 ? 'Ground floor' : 'Floor $index';
  }
}

final residenceSettingsRepositoryProvider =
    Provider<ResidenceSettingsRepository>(
      (ref) => FirestoreResidenceSettingsRepository(
        ref.watch(firebaseFirestoreProvider),
      ),
    );

class ResidenceSettingsController extends AsyncNotifier<ResidenceSettings> {
  String? _residenceId;

  @override
  Future<ResidenceSettings> build() async {
    _residenceId = await ref.watch(
      residenceContextProvider.selectAsync(
        (context) => context.activeResidenceId,
      ),
    );
    final residenceId = _residenceId;
    if (residenceId == null) {
      throw const ResidenceSettingsFailure('missing-active-residence');
    }
    return ref.read(residenceSettingsRepositoryProvider).load(residenceId);
  }

  Future<void> save(ResidenceSettings settings) async {
    await ref.read(residenceSettingsRepositoryProvider).save(settings);
    ref.invalidate(residenceContextProvider);
    state = AsyncData(
      await ref
          .read(residenceSettingsRepositoryProvider)
          .load(settings.residenceId),
    );
  }
}

final residenceSettingsProvider =
    AsyncNotifierProvider<ResidenceSettingsController, ResidenceSettings>(
      ResidenceSettingsController.new,
    );
