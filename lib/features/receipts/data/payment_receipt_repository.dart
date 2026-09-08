import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/receipts/domain/payment_receipt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentReceiptNotFound implements Exception {
  const PaymentReceiptNotFound();
}

abstract interface class PaymentReceiptRepository {
  Future<PaymentReceipt> load(String receiptId);
}

class FirestorePaymentReceiptRepository implements PaymentReceiptRepository {
  const FirestorePaymentReceiptRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<PaymentReceipt> load(String receiptId) async {
    final document = await _firestore
        .collection('publicPaymentReceipts')
        .doc(receiptId)
        .get();
    final data = document.data();
    if (data == null) throw const PaymentReceiptNotFound();
    final residenceId = data['residenceId'] as String;
    var residenceName = data['residenceName'] as String;
    var residenceAddress = data['residenceAddress'] as String? ?? '';
    var residenceCity = data['residenceCity'] as String? ?? '';
    try {
      final publicResidence = await _firestore
          .collection('publicResidences')
          .doc(residenceId)
          .get();
      final publicData = publicResidence.data();
      residenceName = publicData?['name'] as String? ?? residenceName;
      residenceAddress = publicData?['address'] as String? ?? residenceAddress;
      residenceCity = publicData?['city'] as String? ?? residenceCity;
    } on FirebaseException {
      // Keep legacy receipt links available during a staggered rules rollout.
    }
    return PaymentReceipt(
      id: document.id,
      residenceId: residenceId,
      residenceName: residenceName,
      residenceAddress: residenceAddress,
      residenceCity: residenceCity,
      apartmentNumber: data['apartmentNumber'] as String,
      amount: data['amount'] as int,
      periodKeys: List<String>.from(data['periodKeys'] as List),
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      note: data['note'] as String,
    );
  }
}

final paymentReceiptRepositoryProvider = Provider<PaymentReceiptRepository>(
  (ref) =>
      FirestorePaymentReceiptRepository(ref.watch(firebaseFirestoreProvider)),
);

const paymentReceiptLoadTimeout = Duration(seconds: 15);

final paymentReceiptProvider = FutureProvider.autoDispose
    .family<PaymentReceipt, String>((ref, receiptId) {
      return ref
          .watch(paymentReceiptRepositoryProvider)
          .load(receiptId)
          .timeout(paymentReceiptLoadTimeout);
    });
