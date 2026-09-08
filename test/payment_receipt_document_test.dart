import 'package:darjar/features/receipts/domain/payment_receipt.dart';
import 'package:darjar/features/receipts/presentation/payment_receipt_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('ar'));

  test('builds an Arabic payment receipt as a PDF', () async {
    final bytes = await buildPaymentReceiptPdf(
      PaymentReceipt(
        id: 'receipt-01',
        residenceId: 'residence-01',
        residenceName: 'ديار الحسنى',
        residenceAddress: 'شارع محمد الخامس',
        residenceCity: '4421010',
        apartmentNumber: '12',
        amount: 300,
        periodKeys: const ['2026-08'],
        paidAt: DateTime(2026, 8, 20),
        note: 'أداء نقدي',
      ),
      localeName: 'ar',
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
