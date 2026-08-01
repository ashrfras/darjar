import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/images/app_image_paths.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String profileImageStoragePath(String userId) =>
    userProfileImageStoragePath(userId);

class ProfileImageRepository {
  ProfileImageRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> upload({
    required String userId,
    required List<String> residenceIds,
    required Uint8List bytes,
  }) async {
    await _storage
        .ref(profileImageStoragePath(userId))
        .putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'userId': userId, 'uploadedBy': userId},
          ),
        );
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {
      'hasProfileImage': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final residenceId in residenceIds) {
      batch.update(
        _firestore
            .collection('residences')
            .doc(residenceId)
            .collection('members')
            .doc(userId),
        {'hasProfileImage': true, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  Future<void> remove({
    required String userId,
    required List<String> residenceIds,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {
      'hasProfileImage': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final residenceId in residenceIds) {
      batch.update(
        _firestore
            .collection('residences')
            .doc(residenceId)
            .collection('members')
            .doc(userId),
        {'hasProfileImage': false, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
    try {
      await _storage.ref(profileImageStoragePath(userId)).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}

final profileImageRepositoryProvider = Provider<ProfileImageRepository>(
  (ref) => ProfileImageRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);
