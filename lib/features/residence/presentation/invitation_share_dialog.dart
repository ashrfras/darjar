import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showInvitationShareDialog(
  BuildContext context, {
  required String invitationUrl,
  required String initialMessage,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => InvitationShareDialog(
      invitationUrl: invitationUrl,
      initialMessage: initialMessage,
    ),
  );
}

String residentInvitationMessage(
  BuildContext context, {
  required String residentName,
  required String residenceName,
}) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  final residenceLabel = _residenceLabel(residenceName, arabic: arabic);
  return arabic
      ? 'مرحباً $residentName، لقد تمت إضافتك إلى $residenceLabel على تطبيق دارجار، لتتبّع ميزانية الإقامة ومتابعة شؤونها بسهولة. استخدم الرابط التالي لإكمال الانضمام.'
      : 'Hello $residentName, you have been added to $residenceName on the DarJar app, making it easy to track the residence budget and stay on top of its affairs. Use the following link to finish joining.';
}

String groupInvitationMessage(
  BuildContext context, {
  required String residenceName,
}) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  final residenceLabel = _residenceLabel(residenceName, arabic: arabic);
  return arabic
      ? 'أدعوك للانضمام إلى $residenceLabel على تطبيق دارجار، لتتبّع ميزانية الإقامة ومتابعة شؤونها بسهولة.'
      : 'You are invited to join $residenceName on the DarJar app, making it easy to track the residence budget and stay on top of its affairs.';
}

String _residenceLabel(String name, {required bool arabic}) {
  final trimmedName = name.trim();
  if (!arabic ||
      trimmedName.startsWith('إقامة') ||
      trimmedName.startsWith('الإقامة')) {
    return trimmedName;
  }
  return 'إقامة $trimmedName';
}

class InvitationShareDialog extends StatefulWidget {
  const InvitationShareDialog({
    required this.invitationUrl,
    required this.initialMessage,
    super.key,
  });

  final String invitationUrl;
  final String initialMessage;

  @override
  State<InvitationShareDialog> createState() => _InvitationShareDialogState();
}

class _InvitationShareDialogState extends State<InvitationShareDialog> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _ShareDialogCopy.of(context);
    return Dialog(
      key: const Key('invitation-share-dialog'),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.xLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          copy.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('close-invitation-share-dialog'),
                    tooltip: copy.close,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              TextField(
                key: const Key('invitation-message-field'),
                controller: _messageController,
                minLines: 4,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: copy.messageLabel,
                  alignLabelWithHint: true,
                  helperText: copy.messageHint,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
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
                          widget.invitationUrl,
                          key: const Key('invitation-share-url'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarButton(
                key: const Key('confirm-share-invitation-button'),
                label: copy.share,
                icon: Icons.ios_share_rounded,
                expanded: true,
                onPressed: _share,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final message = _messageController.text.trim();
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: message.isEmpty
            ? widget.invitationUrl
            : '$message\n${widget.invitationUrl}',
        subject: _ShareDialogCopy.of(context).title,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _ShareDialogCopy {
  const _ShareDialogCopy(this.arabic);

  factory _ShareDialogCopy.of(BuildContext context) =>
      _ShareDialogCopy(Localizations.localeOf(context).languageCode == 'ar');

  final bool arabic;

  String get title => arabic ? 'مشاركة الدعوة' : 'Share invitation';
  String get description => arabic
      ? 'يمكنك تعديل نص الدعوة قبل مشاركته.'
      : 'You can edit the invitation message before sharing.';
  String get messageLabel => arabic ? 'نص الدعوة' : 'Invitation message';
  String get messageHint => arabic
      ? 'سيُضاف رابط الانضمام تلقائياً عند المشاركة.'
      : 'The joining link will be added automatically when you share.';
  String get share => arabic ? 'مشاركة' : 'Share';
  String get close => arabic ? 'إغلاق' : 'Close';
}
