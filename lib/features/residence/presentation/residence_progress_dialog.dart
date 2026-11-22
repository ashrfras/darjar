import 'dart:async';

import 'package:darjar/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

Future<void> showResidenceProgress(
  BuildContext context, {
  required String label,
  required Future<void> Function() run,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: AppSpacing.medium),
            Flexible(child: Semantics(liveRegion: true, child: Text(label))),
          ],
        ),
      ),
    ),
  );
  unawaited(navigator.push(route));

  final minimumVisibility = Completer<void>();
  final timer = Timer(const Duration(seconds: 2), minimumVisibility.complete);
  try {
    await run();
    await minimumVisibility.future;
  } finally {
    timer.cancel();
    if (navigator.mounted && route.isActive) navigator.removeRoute(route);
  }
}
