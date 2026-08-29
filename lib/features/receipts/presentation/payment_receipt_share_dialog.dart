import 'dart:ui' as ui;

import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/features/receipts/domain/payment_receipt.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showPaymentReceiptShareDialog(
  BuildContext context, {
  required PaymentReceipt receipt,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => PaymentReceiptShareDialog(receipt: receipt),
  );
}

class PaymentReceiptShareDialog extends StatelessWidget {
  const PaymentReceiptShareDialog({required this.receipt, super.key});

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final copy = _ReceiptShareCopy.of(context);
    final message = paymentReceiptShareMessage(context, receipt);
    return Directionality(
      textDirection: copy.arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: AlertDialog(
        key: const Key('payment-receipt-share-dialog'),
        icon: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.residenceSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.residence,
          ),
        ),
        title: Text(copy.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.description, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.large),
              Container(
                key: const Key('payment-receipt-share-message'),
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.outline),
                ),
                child: SelectableText(message),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('close-payment-receipt-share-dialog'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(copy.later),
          ),
          DarJarButton(
            key: const Key('confirm-share-payment-receipt'),
            label: copy.share,
            icon: Icons.ios_share_rounded,
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: message, subject: copy.title),
            ),
          ),
        ],
      ),
    );
  }
}

String paymentReceiptShareMessage(
  BuildContext context,
  PaymentReceipt receipt,
) {
  final copy = _ReceiptShareCopy.of(context);
  final periods = receipt.periodKeys
      .map((periodKey) => _periodLabel(periodKey, copy.localeName))
      .toList(growable: false);
  final period = periods.length == 1
      ? copy.singlePeriod(periods.single)
      : copy.periodRange(periods.first, periods.last);
  return '${copy.recorded(period, receipt.amount)}\n\n'
      '${copy.receiptLabel}:\n${receipt.url}';
}

String _periodLabel(String periodKey, String localeName) {
  final parts = periodKey.split('-');
  return DarJarDateFormat.yMMMM(
    DateTime(int.parse(parts.first), int.parse(parts.last)),
    localeName,
  );
}

class _ReceiptShareCopy {
  const _ReceiptShareCopy(this.arabic);

  factory _ReceiptShareCopy.of(BuildContext context) =>
      _ReceiptShareCopy(Localizations.localeOf(context).languageCode == 'ar');

  final bool arabic;
  String get localeName => arabic ? 'ar' : 'en';
  String get title => arabic ? 'مشاركة وصل الأداء' : 'Share payment receipt';
  String get description => arabic
      ? 'أصبح الوصل جاهزاً. شاركه مع الساكن عبر واتساب أو أي تطبيق آخر.'
      : 'The receipt is ready. Share it through WhatsApp or another app.';
  String get later => arabic ? 'لاحقاً' : 'Later';
  String get share => arabic ? 'مشاركة الوصل' : 'Share receipt';
  String get receiptLabel => arabic ? 'وصل الأداء' : 'Payment receipt';
  String singlePeriod(String period) => arabic ? 'لشهر $period' : 'for $period';
  String periodRange(String first, String last) => arabic
      ? 'للفترة من $first إلى $last'
      : 'for the period from $first to $last';
  String recorded(String period, int amount) => arabic
      ? 'تم تسجيل أداء واجبات الإقامة $period بقيمة $amount د.'
      : 'A residence dues payment $period for $amount MAD was recorded.';
}
