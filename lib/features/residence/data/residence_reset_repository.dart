import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceResetFailure implements Exception {
  const ResidenceResetFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceResetRepository {
  Future<void> reset({
    required String residenceId,
    required AuthUser president,
    required String presidentName,
  });
}

class FirestoreResidenceResetRepository implements ResidenceResetRepository {
  FirestoreResidenceResetRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<void> reset({
    required String residenceId,
    required AuthUser president,
    required String presidentName,
  }) async {
    final phoneNumber = president.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw const ResidenceResetFailure('missing-phone-number');
    }

    final residence = _firestore.collection('residences').doc(residenceId);
    try {
      final presidentMembership = await residence
          .collection('members')
          .doc(president.uid)
          .get();
      if (presidentMembership.data()?['role'] != 'president' &&
          presidentMembership.data()?['role'] != 'owner') {
        throw const ResidenceResetFailure('president-only');
      }

      final posts = await residence.collection('communityPosts').get();
      final members = await residence.collection('members').get();
      final invitations = await residence.collection('invitations').get();
      final dues = await residence.collection('dues').get();
      final duePayments = await residence.collection('duePayments').get();
      final finances = await residence.collection('financeTransactions').get();
      final documents = await residence.collection('documents').get();
      final buildings = await residence.collection('buildings').get();
      final recommendations = await _firestore
          .collection('directoryRecommendations')
          .where('residenceId', isEqualTo: residenceId)
          .get();

      final floorSnapshots = await Future.wait([
        for (final building in buildings.docs)
          building.reference.collection('floors').get(),
      ]);
      final apartmentSnapshots = await Future.wait([
        for (final floors in floorSnapshots)
          for (final floor in floors.docs)
            floor.reference.collection('apartments').get(),
      ]);

      final storagePaths = <String>{
        'residences/$residenceId/profile/image.jpg',
        for (final document in documents.docs)
          if (document.data()['storagePath'] case final String path)
            if (path.isNotEmpty) path,
        for (final payment in duePayments.docs)
          if (payment.data()['attachmentStoragePath'] case final String path)
            if (path.isNotEmpty) path,
        for (final transaction in finances.docs)
          if (transaction.data()['attachmentStoragePath']
              case final String path)
            if (path.isNotEmpty) path,
      };
      for (final path in storagePaths) {
        try {
          await _storage.ref(path).delete();
        } on FirebaseException catch (error) {
          if (error.code != 'object-not-found') rethrow;
        }
      }

      final writer = _ChunkedBatchWriter(_firestore);
      for (final post in posts.docs) {
        if (post.data()['archivedAt'] == null) {
          writer.update(post.reference, {
            'archivedAt': FieldValue.serverTimestamp(),
            'archivedBy': president.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      for (final member in members.docs) {
        if (member.id == president.uid) {
          writer.update(member.reference, {
            'apartmentId': '',
            'hasPresidentPermissions': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          writer.update(member.reference, {
            'apartmentId': '',
            'status': 'removed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      for (final snapshot in [
        invitations,
        dues,
        duePayments,
        finances,
        documents,
        recommendations,
      ]) {
        for (final document in snapshot.docs) {
          writer.delete(document.reference);
        }
      }
      for (final apartments in apartmentSnapshots) {
        for (final apartment in apartments.docs) {
          writer.delete(apartment.reference);
        }
      }
      for (final floors in floorSnapshots) {
        for (final floor in floors.docs) {
          final isInitialGroundFloor =
              floor.reference.parent.parent?.id == 'main' &&
              floor.id == 'ground';
          if (!isInitialGroundFloor) writer.delete(floor.reference);
        }
      }
      for (final building in buildings.docs) {
        if (building.id != 'main') writer.delete(building.reference);
      }

      writer.update(residence, {
        'hasImage': false,
        'joinRequestsEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      writer.set(residence.collection('settings').doc('private'), {
        'managementOrganization': presidentName.trim(),
        'managementPhone': phoneNumber,
        'bankName': '',
        'bankAccount': '',
        'defaultSubscriptionAmount': 150,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final mainBuilding = residence.collection('buildings').doc('main');
      writer.set(mainBuilding, {
        'nameAr': 'المبنى الرئيسي',
        'nameEn': 'Main building',
        'createdAt': FieldValue.serverTimestamp(),
      });
      writer.set(mainBuilding.collection('floors').doc('ground'), {
        'nameAr': 'الطابق الأرضي',
        'nameEn': 'Ground floor',
        'order': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await writer.commit();
    } on ResidenceResetFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceResetFailure(error.code, error.message);
    } catch (error) {
      throw ResidenceResetFailure('unknown', error.toString());
    }
  }
}

class _ChunkedBatchWriter {
  _ChunkedBatchWriter(this._firestore);

  static const _maxOperations = 400;
  final FirebaseFirestore _firestore;
  final List<void Function(WriteBatch)> _operations = [];

  void update(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, Object?> data,
  ) {
    _operations.add((batch) => batch.update(reference, data));
  }

  void set(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    _operations.add((batch) => batch.set(reference, data, options));
  }

  void delete(DocumentReference<Map<String, dynamic>> reference) {
    _operations.add((batch) => batch.delete(reference));
  }

  Future<void> commit() async {
    for (var start = 0; start < _operations.length; start += _maxOperations) {
      final batch = _firestore.batch();
      final end = (start + _maxOperations).clamp(0, _operations.length);
      for (final operation in _operations.sublist(start, end)) {
        operation(batch);
      }
      await batch.commit();
    }
  }
}

final residenceResetRepositoryProvider = Provider<ResidenceResetRepository>(
  (ref) => FirestoreResidenceResetRepository(
    ref.watch(firebaseFirestoreProvider),
    FirebaseStorage.instance,
  ),
);
