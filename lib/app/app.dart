import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/localization/app_locale_controller.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/features/notifications/data/notification_push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DarJarApp extends ConsumerWidget {
  const DarJarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider).value ?? const Locale('ar');
    ref.watch(notificationPushRegistrationProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).siteTitle,
      builder: (context, child) => Title(
        key: const Key('app-browser-title'),
        title: AppLocalizations.of(context).siteTitle,
        color: Theme.of(context).colorScheme.primary,
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      theme: AppTheme.light,
    );
  }
}
