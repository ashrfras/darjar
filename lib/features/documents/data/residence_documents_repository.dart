import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const residenceDocumentMaxSizeBytes = 15 * 1024 * 1024;

const residenceDocumentContentTypes = {
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
};

String residenceTransactionAttachmentName(String transactionId) {
  const codeLength = 12;
  final prime = BigInt.from(1099511628211);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  final codeRange = BigInt.from(1000000) * BigInt.from(1000000);
  var hash = BigInt.parse('14695981039346656037');
  for (final codeUnit in transactionId.codeUnits) {
    hash ^= BigInt.from(codeUnit);
    hash = (hash * prime) & mask;
  }
  final transactionNumber = (hash % codeRange).toString().padLeft(
    codeLength,
    '0',
  );
  return 'مرفق-$transactionNumber';
}

class ResidenceDocument {
  const ResidenceDocument({
    required this.id,
    required this.title,
    required this.originalFileName,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String originalFileName;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPdf => contentType == 'application/pdf';
  bool get isImage => contentType.startsWith('image/');
}

class ResidenceDocumentUpload {
  const ResidenceDocumentUpload({
    required this.title,
    required this.originalFileName,
    required this.contentType,
    required this.bytes,
  });

  final String title;
  final String originalFileName;
  final String contentType;
  final Uint8List bytes;
}

class ResidenceDocumentsFailure implements Exception {
  const ResidenceDocumentsFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceDocumentsRepository {
  Stream<List<ResidenceDocument>> watch(String residenceId);

  Future<void> upload({
    required String residenceId,
    required String uploadedBy,
    required ResidenceDocumentUpload upload,
    void Function(double progress)? onProgress,
  });

  Future<void> updateTitle({
    required String residenceId,
    required String documentId,
    required String title,
  });

  Future<void> delete({
    required String residenceId,
    required ResidenceDocument document,
  });

  Future<Uint8List> download(ResidenceDocument document);
}

class FirebaseResidenceDocumentsRepository
    implements ResidenceDocumentsRepository {
  FirebaseResidenceDocumentsRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Stream<List<ResidenceDocument>> watch(String residenceId) {
    return _documents(residenceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final document in snapshot.docs)
              _documentFromSnapshot(document),
          ],
        )
        .handleError((Object error) {
          throw _failure(error);
        });
  }

  @override
  Future<void> upload({
    required String residenceId,
    required String uploadedBy,
    required ResidenceDocumentUpload upload,
    void Function(double progress)? onProgress,
  }) async {
    final title = upload.title.trim();
    if (title.isEmpty || title.length > 120) {
      throw const ResidenceDocumentsFailure('invalid-title');
    }
    if (upload.originalFileName.isEmpty ||
        upload.originalFileName.length > 255) {
      throw const ResidenceDocumentsFailure('invalid-file-name');
    }
    if (!residenceDocumentContentTypes.contains(upload.contentType)) {
      throw const ResidenceDocumentsFailure('unsupported-type');
    }
    if (upload.bytes.isEmpty ||
        upload.bytes.lengthInBytes > residenceDocumentMaxSizeBytes) {
      throw const ResidenceDocumentsFailure('invalid-size');
    }

    final documentReference = _documents(residenceId).doc();
    final storagePath =
        'residences/$residenceId/documents/${documentReference.id}/content';
    final storageReference = _storage.ref(storagePath);
    var uploaded = false;
    StreamSubscription<TaskSnapshot>? progressSubscription;
    try {
      final uploadTask = storageReference.putData(
        upload.bytes,
        SettableMetadata(
          contentType: upload.contentType,
          cacheControl: 'private,max-age=3600',
          customMetadata: {
            'residenceId': residenceId,
            'documentId': documentReference.id,
            'uploadedBy': uploadedBy,
          },
        ),
      );
      progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes <= 0) return;
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      });
      await uploadTask;
      uploaded = true;
      onProgress?.call(1);
      await documentReference.set({
        'title': title,
        'originalFileName': upload.originalFileName,
        'storagePath': storagePath,
        'contentType': upload.contentType,
        'sizeBytes': upload.bytes.lengthInBytes,
        'uploadedBy': uploadedBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (uploaded) {
        try {
          await storageReference.delete();
        } catch (_) {
          // A later cleanup can remove an orphan if rollback is unavailable.
        }
      }
      throw _failure(error);
    } finally {
      await progressSubscription?.cancel();
    }
  }

  @override
  Future<void> updateTitle({
    required String residenceId,
    required String documentId,
    required String title,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > 120) {
      throw const ResidenceDocumentsFailure('invalid-title');
    }
    try {
      await _documents(residenceId).doc(documentId).update({
        'title': normalizedTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> delete({
    required String residenceId,
    required ResidenceDocument document,
  }) async {
    try {
      try {
        await _storage.ref(document.storagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
      await _documents(residenceId).doc(document.id).delete();
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<Uint8List> download(ResidenceDocument document) async {
    try {
      final bytes = await _storage
          .ref(document.storagePath)
          .getData(residenceDocumentMaxSizeBytes);
      if (bytes == null) {
        throw const ResidenceDocumentsFailure('empty-download');
      }
      return bytes;
    } catch (error) {
      throw _failure(error);
    }
  }

  CollectionReference<Map<String, dynamic>> _documents(String residenceId) {
    return _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('documents');
  }

  ResidenceDocument _documentFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return ResidenceDocument(
      id: document.id,
      title: data['title'] as String? ?? '',
      originalFileName: data['originalFileName'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
      uploadedBy: data['uploadedBy'] as String? ?? '',
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  DateTime _dateFrom(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime date => date,
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
  }

  ResidenceDocumentsFailure _failure(Object error) {
    return switch (error) {
      ResidenceDocumentsFailure failure => failure,
      FirebaseException(:final code, :final message) =>
        ResidenceDocumentsFailure(code, message),
      _ => ResidenceDocumentsFailure('unknown', error.toString()),
    };
  }
}

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final residenceDocumentsRepositoryProvider =
    Provider<ResidenceDocumentsRepository>(
      (ref) => FirebaseResidenceDocumentsRepository(
        ref.watch(firebaseFirestoreProvider),
        ref.watch(firebaseStorageProvider),
      ),
    );

final residenceDocumentsProvider =
    StreamProvider.autoDispose<List<ResidenceDocument>>((ref) async* {
      final context = await ref.watch(residenceContextProvider.future);
      final activeResidence = context.activeResidence;
      if (activeResidence == null) {
        yield const [];
        return;
      }
      yield* ref
          .watch(residenceDocumentsRepositoryProvider)
          .watch(activeResidence.id);
    });

String residenceDocumentContentType(String fileName, String? reportedType) {
  final normalizedReportedType = reportedType?.toLowerCase();
  if (normalizedReportedType != null &&
      residenceDocumentContentTypes.contains(normalizedReportedType)) {
    return normalizedReportedType;
  }
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => '',
  };
}
