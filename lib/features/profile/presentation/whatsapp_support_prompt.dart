import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/profile/data/whatsapp_support_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showWhatsAppSupportPrompt(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final auth = ref.read(authRepositoryProvider);
  final strings = AppLocalizations.of(context);
  final choice = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.chat_bubble_outline_rounded),
      title: Text(strings.whatsAppSupportPromptTitle),
      content: Text(strings.whatsAppSupportPromptDescription),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.whatsAppSupportDecline),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.whatsAppSupportAccept),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted || auth.currentUser?.uid != userId) {
    return;
  }

  final repository = ref.read(whatsAppSupportRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  unawaited(() async {
    try {
      await repository.answerPrompt(userId, choice);
    } catch (_) {
      if (messenger.mounted && auth.currentUser?.uid == userId) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.whatsAppSupportSaveError)),
        );
      }
    }
  }());
}
