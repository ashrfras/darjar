import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResidenceExpenseCategory {
  maintenance,
  utilities,
  cleaning,
  security,
  custom,
}

enum ResidenceTransactionType { income, expense }

enum ResidenceTransactionSource { dues, manual }

class ResidenceTransaction {
  const ResidenceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.name,
    required this.source,
    this.expenseCategory,
    this.note = '',
    this.supportingDocument = '',
    this.attachmentStoragePath = '',
    this.attachmentContentType = '',
    this.attachmentSizeBytes = 0,
    this.recordedBy = '',
    this.apartmentNumber = '',
    this.periodKey = '',
    this.periodEndKey = '',
  });

  final String id;
  final ResidenceTransactionType type;
  final int amount;
  final DateTime date;
  final String name;
  final ResidenceTransactionSource source;
  final ResidenceExpenseCategory? expenseCategory;
  final String note;
  final String supportingDocument;
  final String attachmentStoragePath;
  final String attachmentContentType;
  final int attachmentSizeBytes;
  final String recordedBy;
  final String apartmentNumber;
  final String periodKey;
  final String periodEndKey;

  bool get isManual => source == ResidenceTransactionSource.manual;
  bool get hasAttachment =>
      supportingDocument.isNotEmpty && attachmentStoragePath.isNotEmpty;
  String get attachmentName => residenceTransactionAttachmentName(
    source == ResidenceTransactionSource.dues && id.startsWith('dues-')
        ? id.substring('dues-'.length)
        : id,
  );

  ResidenceDocument get attachmentDocument => ResidenceDocument(
    id: 'attachment-$id',
    title: attachmentName,
    originalFileName: attachmentName,
    storagePath: attachmentStoragePath,
    contentType: attachmentContentType,
    sizeBytes: attachmentSizeBytes,
    uploadedBy: recordedBy,
    createdAt: date,
    updatedAt: date,
  );
}

class ResidenceExpenseBreakdown {
  const ResidenceExpenseBreakdown({
    required this.category,
    required this.amount,
  });

  final ResidenceExpenseCategory category;
  final int amount;
}

class ResidenceFinances {
  const ResidenceFinances({
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.paidResidents,
    required this.totalResidents,
    required this.breakdown,
    required this.recentExpenses,
    required this.transactions,
  });

  static const empty = ResidenceFinances(
    totalIncome: 0,
    totalExpenses: 0,
    currentBalance: 0,
    paidResidents: 0,
    totalResidents: 0,
    breakdown: [],
    recentExpenses: [],
    transactions: [],
  );

  factory ResidenceFinances.fromTransactions({
    required List<ResidenceTransaction> transactions,
    required int paidResidents,
    required int totalResidents,
    DateTime? now,
  }) {
    final currentYear = (now ?? DateTime.now()).year;
    final orderedTransactions = [...transactions]
      ..sort((first, second) => second.date.compareTo(first.date));
    final currentYearTransactions = orderedTransactions.where(
      (transaction) => transaction.date.year == currentYear,
    );
    final totalIncome = currentYearTransactions
        .where(
          (transaction) => transaction.type == ResidenceTransactionType.income,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
    final totalExpenses = currentYearTransactions
        .where(
          (transaction) => transaction.type == ResidenceTransactionType.expense,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
    final allTimeIncome = orderedTransactions
        .where(
          (transaction) => transaction.type == ResidenceTransactionType.income,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
    final allTimeExpenses = orderedTransactions
        .where(
          (transaction) => transaction.type == ResidenceTransactionType.expense,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
    final breakdownAmounts = {
      for (final category in ResidenceExpenseCategory.values) category: 0,
    };
    for (final transaction in currentYearTransactions) {
      if (transaction.type != ResidenceTransactionType.expense) continue;
      final category =
          transaction.expenseCategory ?? ResidenceExpenseCategory.custom;
      breakdownAmounts[category] =
          breakdownAmounts[category]! + transaction.amount;
    }
    final breakdown = [
      for (final category in ResidenceExpenseCategory.values)
        if (breakdownAmounts[category]! > 0)
          ResidenceExpenseBreakdown(
            category: category,
            amount: breakdownAmounts[category]!,
          ),
    ];
    final recentExpenses = orderedTransactions
        .where(
          (transaction) => transaction.type == ResidenceTransactionType.expense,
        )
        .take(4)
        .toList();

    return ResidenceFinances(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      currentBalance: allTimeIncome - allTimeExpenses,
      paidResidents: paidResidents,
      totalResidents: totalResidents,
      breakdown: breakdown,
      recentExpenses: recentExpenses,
      transactions: orderedTransactions,
    );
  }

  final int totalIncome;
  final int totalExpenses;
  final int currentBalance;
  final int paidResidents;
  final int totalResidents;
  final List<ResidenceExpenseBreakdown> breakdown;
  final List<ResidenceTransaction> recentExpenses;
  final List<ResidenceTransaction> transactions;

  double get collectionRate {
    if (totalResidents == 0) return 0;
    return paidResidents / totalResidents;
  }
}

class ResidenceFinanceInput {
  const ResidenceFinanceInput({
    required this.type,
    required this.amount,
    required this.date,
    required this.name,
    this.expenseCategory,
    this.note = '',
    this.supportingDocument = '',
    this.attachmentUpload,
  });

  final ResidenceTransactionType type;
  final int amount;
  final DateTime date;
  final String name;
  final ResidenceExpenseCategory? expenseCategory;
  final String note;
  final String supportingDocument;
  final ResidenceDocumentUpload? attachmentUpload;
}

class ResidenceFinanceFailure implements Exception {
  const ResidenceFinanceFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class ResidenceFinanceRepository {
  Future<ResidenceFinances> load(String residenceId);

  Future<void> addManualTransaction({
    required String residenceId,
    required ResidenceFinanceInput input,
    required String recordedBy,
  });

  Future<void> updateManualTransaction({
    required String residenceId,
    required String transactionId,
    required ResidenceFinanceInput input,
  });

  Future<void> deleteManualTransaction({
    required String residenceId,
    required String transactionId,
  });
}

class FirestoreResidenceFinanceRepository
    implements ResidenceFinanceRepository {
  FirestoreResidenceFinanceRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<ResidenceFinances> load(String residenceId) async {
    final residence = _firestore.collection('residences').doc(residenceId);
    final currentPeriod = _periodKey(DateTime.now());
    try {
      final results = await Future.wait<Object>([
        residence.collection('duePayments').get(),
        residence.collection('financeTransactions').get(),
        residence
            .collection('dues')
            .where('periodKey', isEqualTo: currentPeriod)
            .get(),
        _loadApartmentCount(residence),
      ]);
      final paymentDocuments =
          results[0] as QuerySnapshot<Map<String, dynamic>>;
      final manualDocuments = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final currentDues = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final apartmentCount = results[3] as int;
      final transactions = [
        ..._duesTransactions(paymentDocuments.docs),
        for (final document in manualDocuments.docs)
          _manualTransaction(document),
      ];
      final paidResidents = currentDues.docs.where((document) {
        final data = document.data();
        return data['status'] == 'paid' ||
            (data['amountPaid'] as int? ?? 0) >=
                (data['amountDue'] as int? ?? 0);
      }).length;
      return ResidenceFinances.fromTransactions(
        transactions: transactions,
        paidResidents: paidResidents,
        totalResidents: apartmentCount,
      );
    } on FirebaseException catch (error) {
      throw ResidenceFinanceFailure(error.code, error.message);
    }
  }

  List<ResidenceTransaction> _duesTransactions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final document in documents) {
      final data = document.data();
      final storedGroupId = data['paymentGroupId'] as String? ?? '';
      final groupId = storedGroupId.isNotEmpty
          ? storedGroupId
          : _legacyPaymentGroupKey(data);
      grouped.putIfAbsent(groupId, () => []).add(document);
    }
    return [
      for (final entry in grouped.entries)
        _duesTransaction(entry.key, entry.value),
    ];
  }

  ResidenceTransaction _duesTransaction(
    String groupId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final first = documents.first.data();
    final periods = [
      for (final document in documents)
        if ((document.data()['dueId'] as String? ?? '').length >= 7)
          (document.data()['dueId'] as String).substring(0, 7),
    ]..sort();
    return ResidenceTransaction(
      id: 'dues-$groupId',
      type: ResidenceTransactionType.income,
      amount: documents.fold(
        0,
        (total, document) => total + (document.data()['amount'] as int? ?? 0),
      ),
      date: _dateFrom(first['paidAt']),
      name: '',
      source: ResidenceTransactionSource.dues,
      note: first['note'] as String? ?? '',
      supportingDocument: first['supportingDocument'] as String? ?? '',
      attachmentStoragePath: first['attachmentStoragePath'] as String? ?? '',
      attachmentContentType: first['attachmentContentType'] as String? ?? '',
      attachmentSizeBytes: first['attachmentSizeBytes'] as int? ?? 0,
      recordedBy: first['recordedBy'] as String? ?? '',
      apartmentNumber: first['apartmentNumber'] as String? ?? '',
      periodKey: periods.isEmpty ? '' : periods.first,
      periodEndKey: periods.isEmpty ? '' : periods.last,
    );
  }

  String _legacyPaymentGroupKey(Map<String, dynamic> data) {
    final paidAt = _dateFrom(data['paidAt']).microsecondsSinceEpoch;
    final createdAt = _dateFrom(data['createdAt']).microsecondsSinceEpoch;
    return [
      'legacy',
      paidAt,
      createdAt,
      data['apartmentId'] ?? '',
      data['recordedBy'] ?? '',
      data['note'] ?? '',
    ].join('|');
  }

  Future<int> _loadApartmentCount(
    DocumentReference<Map<String, dynamic>> residence,
  ) async {
    final buildings = await residence.collection('buildings').get();
    var count = 0;
    for (final building in buildings.docs) {
      final floors = await building.reference.collection('floors').get();
      for (final floor in floors.docs) {
        final apartments = await floor.reference.collection('apartments').get();
        count += apartments.size;
      }
    }
    return count;
  }

  ResidenceTransaction _manualTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final categoryName = data['expenseCategory'] as String?;
    return ResidenceTransaction(
      id: document.id,
      type: ResidenceTransactionType.values.byName(data['type'] as String),
      amount: data['amount'] as int,
      date: _dateFrom(data['date']),
      name: data['name'] as String,
      source: ResidenceTransactionSource.manual,
      expenseCategory: categoryName == null
          ? null
          : ResidenceExpenseCategory.values.byName(categoryName),
      note: data['note'] as String? ?? '',
      supportingDocument: data['supportingDocument'] as String? ?? '',
      attachmentStoragePath: data['attachmentStoragePath'] as String? ?? '',
      attachmentContentType: data['attachmentContentType'] as String? ?? '',
      attachmentSizeBytes: data['attachmentSizeBytes'] as int? ?? 0,
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  @override
  Future<void> addManualTransaction({
    required String residenceId,
    required ResidenceFinanceInput input,
    required String recordedBy,
  }) async {
    _validate(input);
    final transaction = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('financeTransactions')
        .doc();
    final attachmentData = await _uploadAttachment(
      residenceId: residenceId,
      transactionKey: 'finance-${transaction.id}',
      uploadedBy: recordedBy,
      upload: input.attachmentUpload,
    );
    try {
      await transaction.set({
        ..._inputData(
          input,
          attachmentName: input.attachmentUpload == null
              ? null
              : residenceTransactionAttachmentName(transaction.id),
        ),
        ...attachmentData,
        'recordedBy': recordedBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw ResidenceFinanceFailure(error.code, error.message);
    }
  }

  @override
  Future<void> updateManualTransaction({
    required String residenceId,
    required String transactionId,
    required ResidenceFinanceInput input,
  }) async {
    _validate(input);
    final reference = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('financeTransactions')
        .doc(transactionId);
    final attachmentData = await _uploadAttachment(
      residenceId: residenceId,
      transactionKey: 'finance-$transactionId',
      uploadedBy: '',
      upload: input.attachmentUpload,
    );
    try {
      await reference.update({
        ..._inputData(
          input,
          attachmentName:
              input.attachmentUpload == null &&
                  input.supportingDocument.trim().isEmpty
              ? null
              : residenceTransactionAttachmentName(transactionId),
        ),
        ...attachmentData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw ResidenceFinanceFailure(error.code, error.message);
    }
  }

  @override
  Future<void> deleteManualTransaction({
    required String residenceId,
    required String transactionId,
  }) async {
    final reference = _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('financeTransactions')
        .doc(transactionId);
    try {
      final snapshot = await reference.get();
      final storagePath =
          snapshot.data()?['attachmentStoragePath'] as String? ?? '';
      await reference.delete();
      if (storagePath.isNotEmpty) {
        try {
          await _storage.ref(storagePath).delete();
        } on FirebaseException catch (error) {
          if (error.code != 'object-not-found') rethrow;
        }
      }
    } on FirebaseException catch (error) {
      throw ResidenceFinanceFailure(error.code, error.message);
    }
  }

  Map<String, Object?> _inputData(
    ResidenceFinanceInput input, {
    String? attachmentName,
  }) {
    return {
      'type': input.type.name,
      'amount': input.amount,
      'date': Timestamp.fromDate(input.date),
      'name': input.name.trim(),
      'expenseCategory': input.expenseCategory?.name,
      'note': input.note.trim(),
      'supportingDocument': attachmentName ?? input.supportingDocument.trim(),
    };
  }

  Future<Map<String, Object>> _uploadAttachment({
    required String residenceId,
    required String transactionKey,
    required String uploadedBy,
    required ResidenceDocumentUpload? upload,
  }) async {
    if (upload == null) return const {};
    if (!residenceDocumentContentTypes.contains(upload.contentType) ||
        upload.bytes.isEmpty ||
        upload.bytes.lengthInBytes > residenceDocumentMaxSizeBytes) {
      throw const ResidenceFinanceFailure('invalid-attachment');
    }
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
                if (uploadedBy.isNotEmpty) 'uploadedBy': uploadedBy,
              },
            ),
          );
      return {
        'attachmentStoragePath': storagePath,
        'attachmentContentType': upload.contentType,
        'attachmentSizeBytes': upload.bytes.lengthInBytes,
      };
    } on FirebaseException catch (error) {
      throw ResidenceFinanceFailure(error.code, error.message);
    }
  }

  void _validate(ResidenceFinanceInput input) {
    if (input.amount <= 0 || input.name.trim().isEmpty) {
      throw const ResidenceFinanceFailure('invalid-data');
    }
    if (input.date.isAfter(DateTime.now())) {
      throw const ResidenceFinanceFailure('future-date');
    }
    if (input.type == ResidenceTransactionType.expense &&
        input.expenseCategory == null) {
      throw const ResidenceFinanceFailure('missing-expense-category');
    }
    if (input.type == ResidenceTransactionType.income &&
        input.expenseCategory != null) {
      throw const ResidenceFinanceFailure('invalid-income-category');
    }
  }

  DateTime _dateFrom(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime date => date,
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
  }

  String _periodKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}

final residenceFinanceRepositoryProvider = Provider<ResidenceFinanceRepository>(
  (ref) => FirestoreResidenceFinanceRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

class ResidenceFinanceController extends AsyncNotifier<ResidenceFinances> {
  String? _residenceId;

  @override
  Future<ResidenceFinances> build() async {
    final context = await ref.watch(residenceContextProvider.future);
    final residence = context.activeResidence;
    if (residence == null) {
      return ResidenceFinances.empty;
    }
    _residenceId = residence.id;
    return ref.read(residenceFinanceRepositoryProvider).load(residence.id);
  }

  Future<void> addManualTransaction(ResidenceFinanceInput input) async {
    final residenceId = _requiredResidenceId();
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      throw const ResidenceFinanceFailure('missing-user');
    }
    await ref
        .read(residenceFinanceRepositoryProvider)
        .addManualTransaction(
          residenceId: residenceId,
          input: input,
          recordedBy: user.uid,
        );
    await _reload();
  }

  Future<void> updateManualTransaction({
    required String transactionId,
    required ResidenceFinanceInput input,
  }) async {
    await ref
        .read(residenceFinanceRepositoryProvider)
        .updateManualTransaction(
          residenceId: _requiredResidenceId(),
          transactionId: transactionId,
          input: input,
        );
    await _reload();
  }

  Future<void> deleteManualTransaction(String transactionId) async {
    await ref
        .read(residenceFinanceRepositoryProvider)
        .deleteManualTransaction(
          residenceId: _requiredResidenceId(),
          transactionId: transactionId,
        );
    await _reload();
  }

  Future<void> _reload() async {
    final residenceId = _requiredResidenceId();
    state = AsyncData(
      await ref.read(residenceFinanceRepositoryProvider).load(residenceId),
    );
  }

  String _requiredResidenceId() {
    final residenceId = _residenceId;
    if (residenceId == null) {
      throw const ResidenceFinanceFailure('missing-active-residence');
    }
    return residenceId;
  }
}

final residenceFinancesProvider =
    AsyncNotifierProvider<ResidenceFinanceController, ResidenceFinances>(
      ResidenceFinanceController.new,
    );
