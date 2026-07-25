import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class GroupInvitationPage extends ConsumerWidget {
  const GroupInvitationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(residenceSettingsProvider);
    final copy = _InvitationCopy.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      key: const Key('group-invitation-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: copy.title,
                description: compact ? null : copy.description,
                fallbackLocation: AppRoutes.manageApartments,
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                key: const Key('group-invitation-section'),
                padding: const EdgeInsets.all(AppSpacing.large),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 620;
                    final qrCode = _InvitationQr(
                      url: settings.invitationUrl,
                      compact: narrow,
                      caption: copy.scanToJoin,
                    );
                    final details = _InvitationDetails(
                      url: settings.invitationUrl,
                      copy: copy,
                      onCopy: () => _copyLink(context, settings.invitationUrl),
                      onShare: () =>
                          _shareLink(context, settings.invitationUrl, copy),
                      onPrintQr: () => _printQr(settings.invitationUrl, copy),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (narrow) ...[
                          qrCode,
                          const SizedBox(height: AppSpacing.large),
                          details,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              qrCode,
                              const SizedBox(width: AppSpacing.xLarge),
                              Expanded(child: details),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.large),
                        const Divider(),
                        SwitchListTile(
                          key: const Key('public-invitation-toggle'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(copy.allowJoiningViaLink),
                          subtitle: Text(
                            settings.joinRequestsEnabled
                                ? copy.joiningEnabled
                                : copy.joiningDisabled,
                          ),
                          value: settings.joinRequestsEnabled,
                          onChanged: ref
                              .read(residenceSettingsProvider.notifier)
                              .setJoinRequestsEnabled,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    final copy = _InvitationCopy.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copy.linkCopied)));
    await Clipboard.setData(ClipboardData(text: url));
  }

  Future<void> _shareLink(
    BuildContext context,
    String url,
    _InvitationCopy copy,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: '${copy.shareMessage}\n$url',
        subject: copy.title,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _printQr(String url, _InvitationCopy copy) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: url,
                width: 260,
                height: 260,
              ),
              pw.SizedBox(height: 24),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(url),
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(
      name: copy.qrFileName,
      onLayout: (_) => document.save(),
    );
  }
}

class _InvitationQr extends StatelessWidget {
  const _InvitationQr({
    required this.url,
    required this.compact,
    required this.caption,
  });

  final String url;
  final bool compact;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const Key('group-invitation-qr-code'),
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: QrImageView(
            data: url,
            version: QrVersions.auto,
            size: compact ? 190 : 200,
            padding: EdgeInsets.zero,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InvitationDetails extends StatelessWidget {
  const _InvitationDetails({
    required this.url,
    required this.copy,
    required this.onCopy,
    required this.onShare,
    required this.onPrintQr,
  });

  final String url;
  final _InvitationCopy copy;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onPrintQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(copy.permanentLink, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.small),
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    url,
                    key: const Key('public-invitation-link'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            DarJarButton(
              key: const Key('copy-group-invitation-link-button'),
              label: copy.copyLink,
              icon: Icons.content_copy_rounded,
              variant: DarJarButtonVariant.secondary,
              onPressed: onCopy,
            ),
            DarJarButton(
              key: const Key('share-group-invitation-link-button'),
              label: copy.shareLink,
              icon: Icons.ios_share_rounded,
              variant: DarJarButtonVariant.secondary,
              onPressed: onShare,
            ),
            DarJarButton(
              key: const Key('print-group-invitation-qr-button'),
              label: copy.printQr,
              icon: Icons.print_outlined,
              variant: DarJarButtonVariant.secondary,
              onPressed: onPrintQr,
            ),
          ],
        ),
      ],
    );
  }
}

class _InvitationCopy {
  const _InvitationCopy(this.arabic);

  factory _InvitationCopy.of(BuildContext context) {
    return _InvitationCopy(
      Localizations.localeOf(context).languageCode == 'ar',
    );
  }

  final bool arabic;

  String get title => arabic ? 'الدعوة الجماعية' : 'Group invitation';
  String get description => arabic
      ? 'شارك رابط الدعوة الدائم مع سكان الإقامة وتحكّم في استقبال طلبات الانضمام.'
      : 'Share the permanent invitation link and control join requests.';
  String get permanentLink =>
      arabic ? 'رابط الدعوة العام الدائم' : 'Permanent public invitation link';
  String get copyLink => arabic ? 'نسخ الرابط' : 'Copy link';
  String get shareLink => arabic ? 'مشاركة الرابط' : 'Share link';
  String get printQr => arabic ? 'تنزيل أو طباعة QR' : 'Download or print QR';
  String get scanToJoin => arabic
      ? 'امسح الرمز لفتح رابط الانضمام'
      : 'Scan to open the joining link';
  String get allowJoiningViaLink =>
      arabic ? 'السماح بالانضمام عبر الرابط' : 'Allow joining via link';
  String get joiningEnabled => arabic
      ? 'يمكن للسكان الجدد إرسال طلب انضمام.'
      : 'New residents can submit a join request.';
  String get joiningDisabled => arabic
      ? 'الرابط ظاهر، لكن إرسال طلبات الانضمام متوقف.'
      : 'The link remains visible, but join requests are paused.';
  String get linkCopied =>
      arabic ? 'تم نسخ رابط الدعوة.' : 'Invitation link copied.';
  String get shareMessage =>
      arabic ? 'انضم إلى إقامتنا على DarJar:' : 'Join our residence on DarJar:';
  String get qrFileName => arabic ? 'دعوة-DarJar' : 'DarJar-invitation';
}
