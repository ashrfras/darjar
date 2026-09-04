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
    return PaymentReceipt(
      id: document.id,
      residenceId: data['residenceId'] as String,
      residenceName: data['residenceName'] as String,
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
