import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/performance/data_load_timer.dart';
import 'package:darjar/core/providers/provider_cache.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum ResidenceDueStatus { unpaid, partial, paid }

class ResidenceDue {
  const ResidenceDue({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.periodKey,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
  });

  final String id;
  final String apartmentId;
  final String apartmentNumber;
  final String periodKey;
  final int amountDue;
  final int amountPaid;
  final ResidenceDueStatus status;

  int get remainingAmount => amountDue - amountPaid;

  ResidenceDue copyWithPayment(int paymentAmount) {
    final paid = amountPaid + paymentAmount;
    return ResidenceDue(
      id: id,
      apartmentId: apartmentId,
      apartmentNumber: apartmentNumber,
      periodKey: periodKey,
      amountDue: amountDue,
      amountPaid: paid,
      status: paid >= amountDue
          ? ResidenceDueStatus.paid
          : ResidenceDueStatus.partial,
    );
  }
}

class ResidenceDuePayment {
  const ResidenceDuePayment({
    required this.id,
    required this.dueId,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.amount,
    required this.paidAt,
    required this.note,
    required this.recordedBy,
    this.paymentGroupId = '',
    this.supportingDocument = '',
    this.attachmentStoragePath = '',
    this.attachmentContentType = '',
    this.attachmentSizeBytes = 0,
    this.createdAt,
  });

  final String id;
  final String dueId;
  final String apartmentId;
  final String apartmentNumber;
  final int amount;
  final DateTime paidAt;
  final String note;
  final String recordedBy;
  final String paymentGroupId;
  final String supportingDocument;
  final String attachmentStoragePath;
  final String attachmentContentType;
  final int attachmentSizeBytes;
  final DateTime? createdAt;

  bool get hasAttachment =>
      supportingDocument.isNotEmpty && attachmentStoragePath.isNotEmpty;
  String get attachmentName => residenceTransactionAttachmentName(
    paymentGroupId.isEmpty ? id : paymentGroupId,
  );
}

class ResidenceDuePaymentGroup {
  const ResidenceDuePaymentGroup({required this.id, required this.payments});

  final String id;
  final List<ResidenceDuePayment> payments;

  int get totalAmount =>
      payments.fold(0, (total, payment) => total + payment.amount);

  DateTime get paidAt => payments.first.paidAt;
  bool get hasAttachment => payments.first.hasAttachment;

  ResidenceDocument get attachmentDocument {
    final payment = payments.first;
    return ResidenceDocument(
      id: 'attachment-$id',
      title: payment.attachmentName,
      originalFileName: payment.attachmentName,
      storagePath: payment.attachmentStoragePath,
      contentType: payment.attachmentContentType,
      sizeBytes: payment.attachmentSizeBytes,
      uploadedBy: payment.recordedBy,
      createdAt: payment.paidAt,
      updatedAt: payment.createdAt ?? payment.paidAt,
    );
  }
}

class ResidenceDuesOverview {
  const ResidenceDuesOverview({required this.dues, required this.payments});

  static const empty = ResidenceDuesOverview(dues: [], payments: []);

  final List<ResidenceDue> dues;
  final List<ResidenceDuePayment> payments;

  ResidenceDuesOverview forActiveApartments(Iterable<String> apartmentIds) {
    final activeApartmentIds = apartmentIds.toSet();
    return ResidenceDuesOverview(
      dues: dues
          .where((due) => activeApartmentIds.contains(due.apartmentId))
          .toList(growable: false),
      // Payments are financial history and must remain visible after an
      // apartment is deleted. Only current dues drive summaries and choices.
      payments: payments,
    );
  }

  List<ResidenceDue> duesForPeriod(String periodKey) {
    return dues.where((due) => due.periodKey == periodKey).toList();
  }

  int expectedForPeriod(String periodKey) {
    return duesForPeriod(
      periodKey,
    ).fold(0, (total, due) => total + due.amountDue);
  }

  int collectedForPeriod(String periodKey) {
    return duesForPeriod(
      periodKey,
    ).fold(0, (total, due) => total + due.amountPaid);
  }

  int debitThroughPeriod(String periodKey) {
    return dues
        .where((due) => due.periodKey.compareTo(periodKey) <= 0)
        .fold(0, (total, due) => total + due.remainingAmount);
  }

  List<ResidenceDue> prepaidDuesAfterPeriod(String periodKey) {
    return dues
        .where(
          (due) => due.periodKey.compareTo(periodKey) > 0 && due.amountPaid > 0,
        )
        .toList();
  }

  int creditAfterPeriod(String periodKey) {
    return prepaidDuesAfterPeriod(
      periodKey,
    ).fold(0, (total, due) => total + due.amountPaid);
  }

  List<ResidenceDuePaymentGroup> get paymentGroups {
    final grouped = <String, List<ResidenceDuePayment>>{};
    for (final payment in payments) {
      grouped.putIfAbsent(payment.paymentGroupId, () => []).add(payment);
    }
    final groups = [
      for (final entry in grouped.entries)
        ResidenceDuePaymentGroup(id: entry.key, payments: entry.value),
    ]..sort((first, second) => second.paidAt.compareTo(first.paidAt));
    return groups;
  }
}

class ResidenceDuesFailure implements Exception {
  const ResidenceDuesFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceDuesRepository {
  Future<ResidenceDuesOverview> load({
    required String residenceId,
    String? apartmentId,
  });

  Future<void> ensurePeriod({
    required String residenceId,
    required String periodKey,
    required int defaultAmount,
    required List<ResidenceApartment> apartments,
  });

  Future<void> recordApartmentPayment({
    required String residenceId,
    required String apartmentId,
    required String apartmentNumber,
    required int amount,
    required int defaultAmount,
    required String currentPeriodKey,
    required DateTime paidAt,
    required String note,
    required String recordedBy,
    String supportingDocument = '',
    ResidenceDocumentUpload? attachmentUpload,
  });

  Future<void> deletePaymentGroup({
    required String residenceId,
    required String paymentGroupId,
  });
}

class FirestoreResidenceDuesRepository implements ResidenceDuesRepository {
  FirestoreResidenceDuesRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<ResidenceDuesOverview> load({
    required String residenceId,
    String? apartmentId,
  }) async {
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      Query<Map<String, dynamic>> duesQuery = residence.collection('dues');
      Query<Map<String, dynamic>> paymentsQuery = residence.collection(
        'duePayments',
      );
      if (apartmentId != null) {
        duesQuery = duesQuery.where('apartmentId', isEqualTo: apartmentId);
        paymentsQuery = paymentsQuery.where(
          'apartmentId',
          isEqualTo: apartmentId,
        );
      }
      final results = await Future.wait([duesQuery.get(), paymentsQuery.get()]);
      final dues =
          [for (final document in results[0].docs) _dueFromDocument(document)]
            ..sort((first, second) {
              final period = second.periodKey.compareTo(first.periodKey);
              return period != 0
                  ? period
                  : first.apartmentNumber.compareTo(second.apartmentNumber);
            });
      final payments = [
        for (final document in results[1].docs) _paymentFromDocument(document),
      ]..sort((first, second) => second.paidAt.compareTo(first.paidAt));
      return ResidenceDuesOverview(dues: dues, payments: payments);
    } on FirebaseException catch (error) {
      throw ResidenceDuesFailure(error.code, error.message);
    } catch (error) {
      throw ResidenceDuesFailure('unknown', error.toString());
    }
  }

  @override
  Future<void> ensurePeriod({
    required String residenceId,
    required String periodKey,
    required int defaultAmount,
    required List<ResidenceApartment> apartments,
  }) async {
    if (apartments.isEmpty) return;
    if (defaultAmount < 0) {
      throw const ResidenceDuesFailure('invalid-default-amount');
    }
    try {
      final dues = _firestore
          .collection('residences')
          .doc(residenceId)
          .collection('dues');
      final existing = await dues.get();
      final existingIds = {for (final document in existing.docs) document.id};
      final seeds = <_DueSeed>[];
      final currentPeriod = _periodDate(periodKey);
      for (final apartment in apartments) {
        if (!apartment.isDuesTrackingActive) continue;
        final start = apartment.duesTrackingStartPeriodKey.isNotEmpty
            ? _periodDate(apartment.duesTrackingStartPeriodKey)
            : apartment.createdAt ?? currentPeriod;
        for (final missingPeriod in _periodKeys(start, currentPeriod)) {
          final id = '${missingPeriod}_${apartment.id}';
          if (existingIds.add(id)) {
            seeds.add(
              _DueSeed(
                id: id,
                apartmentId: apartment.id,
                apartmentNumber: apartment.number,
                periodKey: missingPeriod,
              ),
            );
          }
        }
      }
      await _createMissingDues(dues, seeds, defaultAmount);
    } on FirebaseException catch (error) {
      throw ResidenceDuesFailure(error.code, error.message);
    }
  }

  @override
  Future<void> recordApartmentPayment({
    required String residenceId,
    required String apartmentId,
    required String apartmentNumber,
    required int amount,
    required int defaultAmount,
    required String currentPeriodKey,
    required DateTime paidAt,
    required String note,
    required String recordedBy,
    String supportingDocument = '',
    ResidenceDocumentUpload? attachmentUpload,
  }) async {
    if (amount <= 0 || defaultAmount < 0) {
      throw const ResidenceDuesFailure('invalid-payment-amount');
    }
    final residence = _firestore.collection('residences').doc(residenceId);
    try {
      final duesCollection = residence.collection('dues');
      final existingDocuments = await duesCollection
          .where('apartmentId', isEqualTo: apartmentId)
          .get();
      final existingDues = [
        for (final document in existingDocuments.docs)
          _dueFromDocument(document),
      ]..sort((first, second) => first.periodKey.compareTo(second.periodKey));
      final remainingBeforePayment = existingDues.fold(
        0,
        (total, due) => total + due.remainingAmount,
      );
      final advanceAmount = amount > remainingBeforePayment
          ? amount - remainingBeforePayment
          : 0;
      if (advanceAmount > 0 &&
          (defaultAmount == 0 || advanceAmount % defaultAmount != 0)) {
        throw const ResidenceDuesFailure('invalid-advance-amount');
      }
      final advanceMonths = defaultAmount == 0
          ? 0
          : advanceAmount ~/ defaultAmount;
      var lastPeriod = currentPeriodKey;
      for (final due in existingDues) {
        if (due.periodKey.compareTo(lastPeriod) > 0) {
          lastPeriod = due.periodKey;
        }
      }
      final futureDues = <ResidenceDue>[];
      var futurePeriod = _periodDate(lastPeriod);
      for (var index = 0; index < advanceMonths; index++) {
        futurePeriod = DateTime(futurePeriod.year, futurePeriod.month + 1);
        final periodKey = residenceDuesPeriodKey(futurePeriod);
        futureDues.add(
          ResidenceDue(
            id: '${periodKey}_$apartmentId',
            apartmentId: apartmentId,
            apartmentNumber: apartmentNumber,
            periodKey: periodKey,
            amountDue: defaultAmount,
            amountPaid: 0,
            status: ResidenceDueStatus.unpaid,
          ),
        );
      }
      final allocationTargets = [
        ...existingDues.where((due) => due.remainingAmount > 0),
        ...futureDues,
      ];
      var unallocatedAmount = amount;
      final allocations = <(ResidenceDue, int)>[];
      for (final due in allocationTargets) {
        if (unallocatedAmount == 0) break;
        final allocated = unallocatedAmount < due.remainingAmount
            ? unallocatedAmount
            : due.remainingAmount;
        allocations.add((due, allocated));
        unallocatedAmount -= allocated;
      }
      if (unallocatedAmount != 0) {
        throw const ResidenceDuesFailure('invalid-payment-amount');
      }
      final futureDueIds = {for (final due in futureDues) due.id};
      final paymentGroupId = residence.collection('duePayments').doc().id;
      final attachmentData = await _uploadAttachment(
        residenceId: residenceId,
        paymentGroupId: paymentGroupId,
        uploadedBy: recordedBy,
        upload: attachmentUpload,
      );
      await _firestore.runTransaction((transaction) async {
        final storedDues = <String, ResidenceDue>{};
        for (final allocation in allocations) {
          final due = allocation.$1;
          final document = await transaction.get(duesCollection.doc(due.id));
          if (futureDueIds.contains(due.id)) {
            if (document.exists) {
              throw const ResidenceDuesFailure('due-already-exists');
            }
            continue;
          }
          if (!document.exists) {
            throw const ResidenceDuesFailure('due-not-found');
          }
          storedDues[due.id] = _dueFromDocument(document);
        }
        for (var index = 0; index < allocations.length; index++) {
          final allocation = allocations[index];
          final due = allocation.$1;
          final allocated = allocation.$2;
          final storedDue = storedDues[due.id] ?? due;
          if (allocated > storedDue.remainingAmount) {
            throw const ResidenceDuesFailure('payment-exceeds-remaining');
          }
          final updatedDue = storedDue.copyWithPayment(allocated);
          final dueReference = duesCollection.doc(due.id);
          if (storedDues.containsKey(due.id)) {
            transaction.update(dueReference, {
              'amountPaid': updatedDue.amountPaid,
              'status': updatedDue.status.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(dueReference, {
              'apartmentId': due.apartmentId,
              'apartmentNumber': due.apartmentNumber,
              'periodKey': due.periodKey,
              'amountDue': due.amountDue,
              'amountPaid': updatedDue.amountPaid,
              'status': updatedDue.status.name,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          transaction.set(
            residence
                .collection('duePayments')
                .doc('$paymentGroupId-${index + 1}'),
            {
              'dueId': due.id,
              'paymentGroupId': paymentGroupId,
              'apartmentId': due.apartmentId,
              'apartmentNumber': due.apartmentNumber,
              'amount': allocated,
              'paidAt': Timestamp.fromDate(paidAt),
              'note': note.trim(),
              'supportingDocument': attachmentUpload == null
                  ? supportingDocument.trim()
                  : residenceTransactionAttachmentName(paymentGroupId),
              ...attachmentData,
              'recordedBy': recordedBy,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }
      });
    } on ResidenceDuesFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceDuesFailure(error.code, error.message);
    }
  }

  @override
  Future<void> deletePaymentGroup({
    required String residenceId,
    required String paymentGroupId,
  }) async {
    if (paymentGroupId.isEmpty) {
      throw const ResidenceDuesFailure('invalid-payment-group');
    }
    final residence = _firestore.collection('residences').doc(residenceId);
    final paymentsCollection = residence.collection('duePayments');
    final duesCollection = residence.collection('dues');
    try {
      final paymentDocuments = await paymentsCollection
          .where('paymentGroupId', isEqualTo: paymentGroupId)
          .get();
      if (paymentDocuments.docs.isEmpty) {
        throw const ResidenceDuesFailure('payment-not-found');
      }
      final payments = [
        for (final document in paymentDocuments.docs)
          _paymentFromDocument(document),
      ];
      final amountsByDueId = <String, int>{};
      for (final payment in payments) {
        amountsByDueId.update(
          payment.dueId,
          (amount) => amount + payment.amount,
          ifAbsent: () => payment.amount,
        );
      }
      final currentPeriodKey = residenceDuesPeriodKey(DateTime.now());
      await _firestore.runTransaction((transaction) async {
        final storedDues = <String, ResidenceDue>{};
        for (final dueId in amountsByDueId.keys) {
          final document = await transaction.get(duesCollection.doc(dueId));
          if (!document.exists) {
            throw const ResidenceDuesFailure('due-not-found');
          }
          storedDues[dueId] = _dueFromDocument(document);
        }
        for (final entry in amountsByDueId.entries) {
          final due = storedDues[entry.key]!;
          final amountPaid = due.amountPaid - entry.value;
          if (amountPaid < 0) {
            throw const ResidenceDuesFailure('invalid-payment-balance');
          }
          final dueReference = duesCollection.doc(due.id);
          if (amountPaid == 0 &&
              due.periodKey.compareTo(currentPeriodKey) > 0) {
            transaction.delete(dueReference);
          } else {
            transaction.update(dueReference, {
              'amountPaid': amountPaid,
              'status': amountPaid == 0
                  ? ResidenceDueStatus.unpaid.name
                  : amountPaid == due.amountDue
                  ? ResidenceDueStatus.paid.name
                  : ResidenceDueStatus.partial.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        for (final document in paymentDocuments.docs) {
          transaction.delete(document.reference);
        }
      });
      final attachmentPath = payments.first.attachmentStoragePath;
      if (attachmentPath.isNotEmpty) {
        try {
          await _storage.ref(attachmentPath).delete();
        } on FirebaseException {
          // The payment itself is already deleted. A stale attachment must not
          // make a retry look as though the payment still exists.
        }
      }
    } on ResidenceDuesFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ResidenceDuesFailure(error.code, error.message);
    }
  }

  ResidenceDue _dueFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return ResidenceDue(
      id: document.id,
      apartmentId: data['apartmentId'] as String,
      apartmentNumber: data['apartmentNumber'] as String,
      periodKey: data['periodKey'] as String,
      amountDue: data['amountDue'] as int,
      amountPaid: data['amountPaid'] as int,
      status: ResidenceDueStatus.values.byName(data['status'] as String),
    );
  }

  ResidenceDuePayment _paymentFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return ResidenceDuePayment(
      id: document.id,
      dueId: data['dueId'] as String,
      apartmentId: data['apartmentId'] as String,
      apartmentNumber: data['apartmentNumber'] as String,
      amount: data['amount'] as int,
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      note: data['note'] as String,
      recordedBy: data['recordedBy'] as String,
      paymentGroupId: data['paymentGroupId'] as String,
      supportingDocument: data['supportingDocument'] as String? ?? '',
      attachmentStoragePath: data['attachmentStoragePath'] as String? ?? '',
      attachmentContentType: data['attachmentContentType'] as String? ?? '',
      attachmentSizeBytes: data['attachmentSizeBytes'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<Map<String, Object>> _uploadAttachment({
    required String residenceId,
    required String paymentGroupId,
    required String uploadedBy,
    required ResidenceDocumentUpload? upload,
  }) async {
    if (upload == null) return const {};
    if (!residenceDocumentContentTypes.contains(upload.contentType) ||
        upload.bytes.isEmpty ||
        upload.bytes.lengthInBytes > residenceDocumentMaxSizeBytes) {
      throw const ResidenceDuesFailure('invalid-attachment');
    }
    final transactionKey = 'dues-$paymentGroupId';
    final storagePath =
        'residences/$residenceId/attachments/$transactionKey/content';
    try {
      await _storage
          .ref(storagePath)
          .putData(
            upload.bytes,
            SettableMetadata(
              contentType: upload.contentType,
              cacheControl: 'private,max-age=3600',
              customMetadata: {
                'residenceId': residenceId,
                'transactionKey': transactionKey,
                'uploadedBy': uploadedBy,
              },
            ),
          );
      return {
        'attachmentStoragePath': storagePath,
        'attachmentContentType': upload.contentType,
        'attachmentSizeBytes': upload.bytes.lengthInBytes,
      };
    } on FirebaseException catch (error) {
      throw ResidenceDuesFailure(error.code, error.message);
    }
  }

  Future<void> _createMissingDues(
    CollectionReference<Map<String, dynamic>> dues,
    List<_DueSeed> seeds,
    int defaultAmount,
  ) async {
    const batchLimit = 450;
    for (var offset = 0; offset < seeds.length; offset += batchLimit) {
      final batch = _firestore.batch();
      final end = offset + batchLimit < seeds.length
          ? offset + batchLimit
          : seeds.length;
      for (final seed in seeds.sublist(offset, end)) {
        batch.set(dues.doc(seed.id), {
          'apartmentId': seed.apartmentId,
          'apartmentNumber': seed.apartmentNumber,
          'periodKey': seed.periodKey,
          'amountDue': defaultAmount,
          'amountPaid': 0,
          'status': defaultAmount == 0
              ? ResidenceDueStatus.paid.name
              : ResidenceDueStatus.unpaid.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}

class _DueSeed {
  const _DueSeed({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.periodKey,
  });

  final String id;
  final String apartmentId;
  final String apartmentNumber;
  final String periodKey;
}

DateTime _periodDate(String periodKey) {
  final parts = periodKey.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

Iterable<String> _periodKeys(DateTime start, DateTime through) sync* {
  var period = DateTime(start.year, start.month);
  final last = DateTime(through.year, through.month);
  while (!period.isAfter(last)) {
    yield residenceDuesPeriodKey(period);
    period = DateTime(period.year, period.month + 1);
  }
}

String residenceDuesPeriodKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

final residenceDuesRepositoryProvider = Provider<ResidenceDuesRepository>(
  (ref) => FirestoreResidenceDuesRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

final residentDuesProvider = FutureProvider.autoDispose<ResidenceDuesOverview>((
  ref,
) async {
  return measureDataLoad('resident dues', () async {
    cacheProviderFor(ref);
    final context = await ref.watch(residenceContextProvider.future);
    final activeResidence = context.activeResidence;
    if (activeResidence == null || activeResidence.apartmentId.isEmpty) {
      return ResidenceDuesOverview.empty;
    }
    final repository = ref.watch(residenceDuesRepositoryProvider);
    return repository
        .load(
          residenceId: activeResidence.id,
          apartmentId: activeResidence.apartmentId,
        )
        .timeout(residenceDataTimeout);
  });
});

class ResidenceDuesManagementController
    extends AsyncNotifier<ResidenceDuesOverview> {
  String? _residenceId;
  int? _defaultAmount;

  @override
  Future<ResidenceDuesOverview> build() async {
    final context = await ref.watch(residenceContextProvider.future);
    final activeResidence = context.activeResidence;
    if (activeResidence == null) {
      return ResidenceDuesOverview.empty;
    }
    if (!activeResidence.canManageResidence) {
      throw const ResidenceDuesFailure('permission-denied');
    }
    _residenceId = activeResidence.id;
    final settings = await ref.watch(residenceSettingsProvider.future);
    _defaultAmount = settings.defaultSubscriptionAmount;
    final members = await ref.watch(residenceMembersProvider.future);
    final repository = ref.read(residenceDuesRepositoryProvider);
    await repository.ensurePeriod(
      residenceId: activeResidence.id,
      periodKey: residenceDuesPeriodKey(DateTime.now()),
      defaultAmount: settings.defaultSubscriptionAmount,
      apartments: members.apartments,
    );
    final overview = await repository.load(residenceId: activeResidence.id);
    return overview.forActiveApartments(
      members.apartments.map((apartment) => apartment.id),
    );
  }

  Future<void> recordPayment({
    required String apartmentId,
    required String apartmentNumber,
    required int amount,
    required DateTime paidAt,
    required String note,
    required String supportingDocument,
    ResidenceDocumentUpload? attachmentUpload,
  }) async {
    final residenceId = _residenceId;
    final defaultAmount = _defaultAmount;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (residenceId == null || defaultAmount == null || user == null) {
      throw const ResidenceDuesFailure('missing-context');
    }
    await ref
        .read(residenceDuesRepositoryProvider)
        .recordApartmentPayment(
          residenceId: residenceId,
          apartmentId: apartmentId,
          apartmentNumber: apartmentNumber,
          amount: amount,
          defaultAmount: defaultAmount,
          currentPeriodKey: residenceDuesPeriodKey(DateTime.now()),
          paidAt: paidAt,
          note: note,
          recordedBy: user.uid,
          supportingDocument: supportingDocument,
          attachmentUpload: attachmentUpload,
        );
    ref.invalidate(residentDuesProvider);
    ref.invalidate(residenceFinancesProvider);
    ref.invalidate(residenceTransactionAttachmentsProvider);
    ref.invalidateSelf();
  }

  Future<void> deletePayment(String paymentGroupId) async {
    final residenceId = _residenceId;
    if (residenceId == null) {
      throw const ResidenceDuesFailure('missing-context');
    }
    await ref
        .read(residenceDuesRepositoryProvider)
        .deletePaymentGroup(
          residenceId: residenceId,
          paymentGroupId: paymentGroupId,
        );
    ref.invalidate(residentDuesProvider);
    ref.invalidate(residenceFinancesProvider);
    ref.invalidate(residenceTransactionAttachmentsProvider);
  }
}

final residenceDuesManagementProvider =
    AsyncNotifierProvider.autoDispose<
      ResidenceDuesManagementController,
      ResidenceDuesOverview
    >(ResidenceDuesManagementController.new);
