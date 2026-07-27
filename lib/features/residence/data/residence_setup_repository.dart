import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateResidenceInput {
  const CreateResidenceInput({
    required this.name,
    required this.address,
    required this.city,
    required this.firstName,
    required this.lastName,
  });

  final String name;
  final String address;
  final String city;
  final String firstName;
  final String lastName;
}

class ResidenceCodeSummary {
  const ResidenceCodeSummary({
    required this.residenceId,
    required this.code,
    required this.name,
    required this.address,
    required this.city,
    required this.joinRequestsEnabled,
  });

  final String residenceId;
  final String code;
  final String name;
  final String address;
  final String city;
  final bool joinRequestsEnabled;
}

class CreatedResidence {
  const CreatedResidence({required this.residenceId, required this.joinCode});

  final String residenceId;
  final String joinCode;
}

class ResidenceSetupFailure implements Exception {
  const ResidenceSetupFailure(this.code);

  final String code;
}

abstract interface class ResidenceSetupRepository {
  Future<CreatedResidence> createResidence({
    required AuthUser user,
    required CreateResidenceInput input,
  });

  Future<ResidenceCodeSummary?> findByCode(String code);

  Future<void> requestToJoin({
    required AuthUser user,
    required ResidenceCodeSummary residence,
    required String firstName,
    required String lastName,
  });
}

class FirestoreResidenceSetupRepository implements ResidenceSetupRepository {
  FirestoreResidenceSetupRepository(this._firestore);

  static const _codeAlphabet = '0123456789';
  static const defaultSubscriptionAmount = 150;

  final FirebaseFirestore _firestore;
  final Random _random = Random.secure();

  @override
  Future<CreatedResidence> createResidence({
    required AuthUser user,
    required CreateResidenceInput input,
  }) async {
    final phoneNumber = _verifiedPhone(user);
    final normalizedInput = CreateResidenceInput(
      name: normalizeResidenceName(input.name),
      address: input.address.trim(),
      city: input.city.trim(),
      firstName: input.firstName.trim(),
      lastName: input.lastName.trim(),
    );
    if (normalizedInput.name.isEmpty ||
        normalizedInput.address.isEmpty ||
        normalizedInput.city.isEmpty ||
        normalizedInput.firstName.isEmpty ||
        normalizedInput.lastName.isEmpty) {
      throw const ResidenceSetupFailure('invalid-data');
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      final joinCode = _generateJoinCode();
      final residenceReference = _firestore.collection('residences').doc();
      final codeReference = _firestore
          .collection('residenceCodes')
          .doc(joinCode);
      final userReference = _firestore.collection('users').doc(user.uid);
      final memberReference = residenceReference
          .collection('members')
          .doc(user.uid);
      final privateSettingsReference = residenceReference
          .collection('settings')
          .doc('private');
      final defaultBuildingReference = residenceReference
          .collection('buildings')
          .doc('main');
      final defaultFloorReference = defaultBuildingReference
          .collection('floors')
          .doc('ground');
      try {
        await _firestore.runTransaction((transaction) async {
          final codeDocument = await transaction.get(codeReference);
          if (codeDocument.exists) {
            throw const ResidenceSetupFailure('code-collision');
          }
          final userDocument = await transaction.get(userReference);

          transaction.set(residenceReference, {
            'name': normalizedInput.name,
            'address': normalizedInput.address,
            'city': normalizedInput.city,
            'establishmentYear': DateTime.now().year,
            'hasImage': false,
            'presidentId': user.uid,
            'joinRequestsEnabled': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.set(codeReference, {
            'residenceId': residenceReference.id,
          });
          if (!userDocument.exists) {
            transaction.set(userReference, {
              'firstName': normalizedInput.firstName,
              'lastName': normalizedInput.lastName,
              'phoneNumber': phoneNumber,
              'activeResidenceId': residenceReference.id,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(userReference, {
              'activeResidenceId': residenceReference.id,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          transaction.set(memberReference, {
            'userId': user.uid,
            'firstName': normalizedInput.firstName,
            'lastName': normalizedInput.lastName,
            'phoneNumber': phoneNumber,
            'apartmentId': '',
            'role': 'president',
            'hasPresidentPermissions': false,
            'status': 'active',
            'source': 'residence-creation',
            'joinedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(privateSettingsReference, {
            'createdBy': user.uid,
            'joinCode': joinCode,
            'managementOrganization':
                '${normalizedInput.firstName} ${normalizedInput.lastName}',
            'managementPhone': phoneNumber,
            'bankName': '',
            'bankAccount': '',
            'defaultSubscriptionAmount': defaultSubscriptionAmount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(defaultBuildingReference, {
            'nameAr': 'المبنى الرئيسي',
            'nameEn': 'Main building',
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.set(defaultFloorReference, {
            'nameAr': 'الطابق الأرضي',
            'nameEn': 'Ground floor',
            'order': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        return CreatedResidence(
          residenceId: residenceReference.id,
          joinCode: joinCode,
        );
      } on ResidenceSetupFailure catch (error) {
        if (error.code == 'code-collision') {
          continue;
        }
        rethrow;
      } on FirebaseException catch (error) {
        throw ResidenceSetupFailure(error.code);
      }
    }
    throw const ResidenceSetupFailure('code-generation-failed');
  }

  @override
  Future<ResidenceCodeSummary?> findByCode(String code) async {
    final normalizedCode = normalizeResidenceCode(code);
    if (!isValidResidenceCode(normalizedCode)) {
      throw const ResidenceSetupFailure('invalid-code');
    }
    try {
      final codeDocument = await _firestore
          .collection('residenceCodes')
          .doc(normalizedCode)
          .get();
      if (!codeDocument.exists) {
        return null;
      }
      final residenceId = codeDocument.data()?['residenceId'] as String? ?? '';
      if (residenceId.isEmpty) {
        throw const ResidenceSetupFailure('invalid-code-data');
      }
      final residenceDocument = await _firestore
          .collection('residences')
          .doc(residenceId)
          .get();
      if (!residenceDocument.exists) {
        return null;
      }
      final data = residenceDocument.data()!;
      return ResidenceCodeSummary(
        residenceId: residenceId,
        code: normalizedCode,
        name: data['name'] as String? ?? '',
        address: data['address'] as String? ?? '',
        city: data['city'] as String? ?? '',
        joinRequestsEnabled: data['joinRequestsEnabled'] as bool? ?? false,
      );
    } on ResidenceSetupFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceSetupFailure(error.code);
    }
  }

  @override
  Future<void> requestToJoin({
    required AuthUser user,
    required ResidenceCodeSummary residence,
    required String firstName,
    required String lastName,
  }) async {
    final phoneNumber = _verifiedPhone(user);
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    if (normalizedFirstName.isEmpty || normalizedLastName.isEmpty) {
      throw const ResidenceSetupFailure('invalid-data');
    }
    if (!residence.joinRequestsEnabled) {
      throw const ResidenceSetupFailure('join-requests-disabled');
    }
    try {
      final residenceReference = _firestore
          .collection('residences')
          .doc(residence.residenceId);
      final memberReference = residenceReference
          .collection('members')
          .doc(user.uid);
      final userReference = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final memberDocument = await transaction.get(memberReference);
        if (memberDocument.data()?['status'] == 'active') {
          return;
        }
        final userDocument = await transaction.get(userReference);
        final profile = userDocument.data();
        transaction.set(memberReference, {
          'userId': user.uid,
          'firstName': profile?['firstName'] as String? ?? normalizedFirstName,
          'lastName': profile?['lastName'] as String? ?? normalizedLastName,
          'phoneNumber': phoneNumber,
          'apartmentId': '',
          'role': 'resident',
          'hasPresidentPermissions': false,
          'status': 'active',
          'source': 'join-code',
          'residenceCode': residence.code,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        if (userDocument.exists) {
          transaction.update(userReference, {
            'activeResidenceId': residence.residenceId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(userReference, {
            'firstName': normalizedFirstName,
            'lastName': normalizedLastName,
            'phoneNumber': phoneNumber,
            'activeResidenceId': residence.residenceId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } on FirebaseException catch (error) {
      throw ResidenceSetupFailure(error.code);
    }
  }

  String _verifiedPhone(AuthUser user) {
    final phoneNumber = user.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw const ResidenceSetupFailure('missing-phone-number');
    }
    return phoneNumber;
  }

  String _generateJoinCode() {
    return List.generate(
      8,
      (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
    ).join();
  }
}

String normalizeResidenceCode(String input) {
  return input.replaceAll(RegExp(r'\D'), '');
}

bool isValidResidenceCode(String code) {
  return RegExp(r'^\d{8}$').hasMatch(code);
}

String normalizeResidenceName(String input) {
  var name = input.trim();
  final genericPrefix = RegExp(
    r'^(?:إقامة|اقامة|résidence|residence)\s*[-–—:]?\s*',
    caseSensitive: false,
  );
  while (genericPrefix.hasMatch(name)) {
    name = name.replaceFirst(genericPrefix, '').trim();
  }
  return name;
}

final residenceSetupRepositoryProvider = Provider<ResidenceSetupRepository>(
  (ref) =>
      FirestoreResidenceSetupRepository(ref.watch(firebaseFirestoreProvider)),
);
