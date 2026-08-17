import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showDuesReminderShareDialog(
  BuildContext context, {
  required String initialMessage,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        DuesReminderShareDialog(initialMessage: initialMessage),
  );
}

class DuesReminderShareDialog extends StatefulWidget {
  const DuesReminderShareDialog({required this.initialMessage, super.key});

  final String initialMessage;

  @override
  State<DuesReminderShareDialog> createState() =>
      _DuesReminderShareDialogState();
}

class _DuesReminderShareDialogState extends State<DuesReminderShareDialog> {
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
    final localizations = AppLocalizations.of(context);
    return Dialog(
      key: const Key('dues-reminder-share-dialog'),
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
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.duesShareReminderTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          localizations.duesShareReminderDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('close-dues-reminder-share-dialog'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              TextField(
                key: const Key('dues-reminder-message-field'),
                controller: _messageController,
                minLines: 6,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: localizations.duesShareReminderMessageLabel,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarButton(
                key: const Key('confirm-share-dues-reminder-button'),
                label: localizations.duesShareReminderAction,
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
    if (message.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: AppLocalizations.of(context).duesShareReminderTitle,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}
