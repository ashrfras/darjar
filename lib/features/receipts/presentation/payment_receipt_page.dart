import 'dart:ui' as ui;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/features/onboarding/presentation/android_app_launcher.dart';
import 'package:darjar/features/receipts/data/payment_receipt_repository.dart';
import 'package:darjar/features/receipts/domain/payment_receipt.dart';
import 'package:darjar/features/receipts/presentation/payment_receipt_share_dialog.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentReceiptPage extends ConsumerWidget {
  const PaymentReceiptPage({
    required this.receiptId,
    this.initialReceipt,
    super.key,
  });

  final String receiptId;
  final PaymentReceipt? initialReceipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = initialReceipt;
    final state = initial == null
        ? ref.watch(paymentReceiptProvider(receiptId))
        : AsyncValue.data(initial);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        key: const Key('payment-receipt-page'),
        appBar: AppBar(
          title: const DarJarBrand(),
          leading: IconButton(
            tooltip: AppLocalizations.of(context).back,
            onPressed: context.canPop() ? () => context.pop() : null,
            icon: const BackButtonIcon(),
          ),
        ),
        body: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              key: Key('payment-receipt-loading'),
            ),
          ),
          error: (error, stackTrace) => _ReceiptUnavailable(
            onRetry: () => ref.invalidate(paymentReceiptProvider(receiptId)),
          ),
          data: (receipt) => _ReceiptBody(receipt: receipt),
        ),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt});

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final copy = _ReceiptCopy.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width < 600 ? AppSpacing.large : AppSpacing.xLarge,
        vertical: AppSpacing.xLarge,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const Key('payment-receipt-card'),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.outline),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xLarge),
                      color: AppColors.primarySoft,
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.check_rounded, size: 34),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            copy.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(
                            copy.confirmed,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            copy.residence(receipt.residenceName),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(
                            copy.apartment(receipt.apartmentNumber),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: AppSpacing.xLarge),
                          Text(
                            '${receipt.amount} ${copy.currency}',
                            key: const Key('payment-receipt-amount'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xLarge),
                          const Divider(),
                          _ReceiptDetail(
                            label: copy.period,
                            value: _periodsLabel(
                              receipt.periodKeys,
                              copy.localeName,
                            ),
                          ),
                          _ReceiptDetail(
                            label: copy.date,
                            value: DarJarDateFormat.yMMMd(
                              receipt.paidAt,
                              copy.localeName,
                            ),
                          ),
                          _ReceiptDetail(
                            label: copy.reference,
                            value: receipt.id,
                            ltr: true,
                          ),
                          if (receipt.note.isNotEmpty)
                            _ReceiptDetail(
                              label: copy.note,
                              value: receipt.note,
                            ),
                          const Divider(),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            copy.manualNotice,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarButton(
                key: const Key('share-payment-receipt-button'),
                label: copy.share,
                icon: Icons.ios_share_rounded,
                expanded: true,
                onPressed: () =>
                    showPaymentReceiptShareDialog(context, receipt: receipt),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: AppSpacing.medium),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: Text(copy.installPrompt)),
                      TextButton(
                        key: const Key('install-darjar-from-receipt'),
                        onPressed: () => launchUrl(
                          Uri.parse(darjarGooglePlayUrl),
                          webOnlyWindowName: '_blank',
                        ),
                        child: Text(copy.install),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptDetail extends StatelessWidget {
  const _ReceiptDetail({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? ui.TextDirection.ltr : null,
              textAlign: ltr ? TextAlign.end : null,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptUnavailable extends StatelessWidget {
  const _ReceiptUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = _ReceiptCopy.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                copy.unavailable,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.large),
              OutlinedButton.icon(
                key: const Key('retry-payment-receipt-button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(copy.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _periodsLabel(List<String> periodKeys, String localeName) {
  final labels = periodKeys
      .map((periodKey) {
        final parts = periodKey.split('-');
        return DarJarDateFormat.yMMMM(
          DateTime(int.parse(parts.first), int.parse(parts.last)),
          localeName,
        );
      })
      .toList(growable: false);
  if (labels.length == 1) return labels.single;
  return localeName == 'ar'
      ? 'من ${labels.first} إلى ${labels.last}'
      : '${labels.first} – ${labels.last}';
}

class _ReceiptCopy {
  const _ReceiptCopy(this.arabic);

  factory _ReceiptCopy.of(BuildContext context) =>
      _ReceiptCopy(Localizations.localeOf(context).languageCode == 'ar');

  final bool arabic;
  String get localeName => arabic ? 'ar' : 'en';
  String get title => arabic ? 'وصل الأداء' : 'Payment receipt';
  String get confirmed => arabic ? 'تم تسجيل الأداء' : 'Payment recorded';
  String residence(String name) => arabic
      ? 'إقامة ${normalizeResidenceName(name)}'
      : normalizeResidenceName(name);
  String apartment(String number) =>
      arabic ? 'الشقة رقم $number' : 'Apartment $number';
  String get currency => arabic ? 'د' : 'MAD';
  String get period => arabic ? 'الفترة' : 'Period';
  String get date => arabic ? 'تاريخ الأداء' : 'Payment date';
  String get reference => arabic ? 'مرجع الوصل' : 'Receipt reference';
  String get note => arabic ? 'ملاحظة' : 'Note';
  String get manualNotice => arabic
      ? 'يوثّق هذا الوصل أداءً مسجلاً يدوياً. دارجار لا يحتفظ بالأموال ولا يعالج الدفعات.'
      : 'This receipt documents a manually recorded payment. DarJar does not hold money or process payments.';
  String get share => arabic ? 'مشاركة الوصل' : 'Share receipt';
  String get installPrompt => arabic
      ? 'ثبّت تطبيق دارجار للوصول إلى خدمات إقامتك بسهولة.'
      : 'Install DarJar for easy access to your residence services.';
  String get install => arabic ? 'تثبيت التطبيق' : 'Install app';
  String get unavailable => arabic
      ? 'هذا الوصل غير متاح أو لم يعد صالحاً.'
      : 'This receipt is unavailable or no longer valid.';
  String get retry => arabic ? 'إعادة المحاولة' : 'Try again';
}
