import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/images/app_image_paths.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String residenceImageStoragePath(String residenceId) =>
    residenceProfileImageStoragePath(residenceId);

class ResidenceImageRepository {
  ResidenceImageRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> upload({
    required String residenceId,
    required String userId,
    required Uint8List bytes,
  }) async {
    final path = residenceImageStoragePath(residenceId);
    await _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'residenceId': residenceId, 'uploadedBy': userId},
          ),
        );
    await _firestore.collection('residences').doc(residenceId).update({
      'hasImage': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String residenceId) async {
    await _firestore.collection('residences').doc(residenceId).update({
      'hasImage': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await _storage.ref(residenceImageStoragePath(residenceId)).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}

final residenceImageRepositoryProvider = Provider<ResidenceImageRepository>(
  (ref) => ResidenceImageRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);
