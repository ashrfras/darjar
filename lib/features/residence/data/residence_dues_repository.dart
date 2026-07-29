import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final DateTime? createdAt;
}

class ResidenceDuePaymentGroup {
  const ResidenceDuePaymentGroup({required this.id, required this.payments});

  final String id;
  final List<ResidenceDuePayment> payments;

  int get totalAmount =>
      payments.fold(0, (total, payment) => total + payment.amount);

  DateTime get paidAt => payments.first.paidAt;
}

class ResidenceDuesOverview {
  const ResidenceDuesOverview({required this.dues, required this.payments});

  static const empty = ResidenceDuesOverview(dues: [], payments: []);

  final List<ResidenceDue> dues;
  final List<ResidenceDuePayment> payments;

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
      final groupId = payment.paymentGroupId.isNotEmpty
          ? payment.paymentGroupId
          : payment.createdAt == null
          ? payment.id
          : [
              'legacy',
              payment.createdAt!.microsecondsSinceEpoch,
              payment.apartmentId,
              payment.recordedBy,
              payment.note,
            ].join('|');
      grouped.putIfAbsent(groupId, () => []).add(payment);
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

  Future<void> ensureResidentPeriod({
    required String residenceId,
    required String apartmentId,
    required String periodKey,
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
  });
}

class FirestoreResidenceDuesRepository implements ResidenceDuesRepository {
  FirestoreResidenceDuesRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
        final start = apartment.createdAt ?? currentPeriod;
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
  Future<void> ensureResidentPeriod({
    required String residenceId,
    required String apartmentId,
    required String periodKey,
  }) async {
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      final apartment = await _loadApartment(residence, apartmentId);
      if (apartment == null) {
        throw const ResidenceDuesFailure('apartment-not-found');
      }
      final privateSettings = residence.collection('settings').doc('private');
      final settingsDocument = await privateSettings.get();
      final defaultAmount =
          settingsDocument.data()?['defaultSubscriptionAmount'] as int?;
      if (defaultAmount == null || defaultAmount < 0) {
        throw const ResidenceDuesFailure('invalid-default-amount');
      }
      final dues = residence.collection('dues');
      final existing = await dues
          .where('apartmentId', isEqualTo: apartmentId)
          .get();
      final existingIds = {for (final document in existing.docs) document.id};
      final currentPeriod = _periodDate(periodKey);
      final start = apartment.createdAt ?? currentPeriod;
      final seeds = [
        for (final missingPeriod in _periodKeys(start, currentPeriod))
          if (!existingIds.contains('${missingPeriod}_$apartmentId'))
            _DueSeed(
              id: '${missingPeriod}_$apartmentId',
              apartmentId: apartmentId,
              apartmentNumber: apartment.number,
              periodKey: missingPeriod,
            ),
      ];
      await _createMissingDues(dues, seeds, defaultAmount);
    } on ResidenceDuesFailure {
      rethrow;
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
              'supportingDocument': supportingDocument.trim(),
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
      paymentGroupId: data['paymentGroupId'] as String? ?? '',
      supportingDocument: data['supportingDocument'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<_ApartmentBillingInfo?> _loadApartment(
    DocumentReference<Map<String, dynamic>> residence,
    String apartmentId,
  ) async {
    final buildings = await residence.collection('buildings').get();
    for (final building in buildings.docs) {
      final floors = await building.reference.collection('floors').get();
      for (final floor in floors.docs) {
        final apartment = await floor.reference
            .collection('apartments')
            .doc(apartmentId)
            .get();
        if (apartment.exists) {
          final data = apartment.data()!;
          return _ApartmentBillingInfo(
            number: data['number']?.toString() ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          );
        }
      }
    }
    return null;
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

class _ApartmentBillingInfo {
  const _ApartmentBillingInfo({required this.number, required this.createdAt});

  final String number;
  final DateTime? createdAt;
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
  (ref) =>
      FirestoreResidenceDuesRepository(ref.watch(firebaseFirestoreProvider)),
);

final residentDuesProvider = FutureProvider.autoDispose<ResidenceDuesOverview>((
  ref,
) async {
  final context = await ref.watch(residenceContextProvider.future);
  final activeResidence = context.activeResidence;
  if (activeResidence == null || activeResidence.apartmentId.isEmpty) {
    return ResidenceDuesOverview.empty;
  }
  final repository = ref.watch(residenceDuesRepositoryProvider);
  await repository.ensureResidentPeriod(
    residenceId: activeResidence.id,
    apartmentId: activeResidence.apartmentId,
    periodKey: residenceDuesPeriodKey(DateTime.now()),
  );
  return repository.load(
    residenceId: activeResidence.id,
    apartmentId: activeResidence.apartmentId,
  );
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
    return repository.load(residenceId: activeResidence.id);
  }

  Future<void> recordPayment({
    required String apartmentId,
    required String apartmentNumber,
    required int amount,
    required DateTime paidAt,
    required String note,
    required String supportingDocument,
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
        );
    ref.invalidate(residentDuesProvider);
    ref.invalidate(residenceFinancesProvider);
    ref.invalidateSelf();
  }
}

final residenceDuesManagementProvider =
    AsyncNotifierProvider.autoDispose<
      ResidenceDuesManagementController,
      ResidenceDuesOverview
    >(ResidenceDuesManagementController.new);
