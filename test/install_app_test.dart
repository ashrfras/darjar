import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/features/onboarding/presentation/app_store_launcher.dart';
import 'package:darjar/features/onboarding/presentation/install_app_page.dart';
import 'package:darjar/features/onboarding/presentation/onboarding_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.linux,
  ]) {
    for (final button in ['header', 'footer']) {
      testWidgets(
        '$platform $button CTA opens store and keeps install fallback',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          final opened = <Uri>[];
          final router = GoRouter(
            initialLocation: AppRoutes.onboarding,
            routes: [
              GoRoute(
                path: AppRoutes.onboarding,
                builder: (_, _) => OnboardingPage(
                  showWebLanding: true,
                  openStore: (uri) async {
                    opened.add(uri);
                    return false;
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.install,
                builder: (_, _) => const InstallAppPage(),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light,
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          );
          await tester.pumpAndSettle();
          final start = button == 'header'
              ? find.descendant(
                  of: find.byKey(const Key('web-landing-header')),
                  matching: find.text('ابدأ الآن'),
                )
              : find.byKey(const Key('landing-final-start-button'));
          await tester.ensureVisible(start);
          await tester.tap(start);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('install-app-page')), findsOneWidget);
          expect(find.text('Google Play'), findsOneWidget);
          expect(find.text('App Store'), findsOneWidget);
          expect(
            Directionality.of(tester.element(find.text('ثبّت تطبيق دارجار'))),
            TextDirection.rtl,
          );
          final expectedStore = switch (platform) {
            TargetPlatform.android => darjarGooglePlayUrl,
            TargetPlatform.iOS => darjarAppStoreUrl,
            _ => null,
          };
          expect(
            opened.map((uri) => uri.toString()),
            expectedStore == null ? isEmpty : [expectedStore],
          );
          expect(tester.takeException(), isNull);
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }

  testWidgets(
    'Both install links work on compact screens and show launch failures',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InstallAppPage(
            openStore: (uri) async {
              opened.add(uri);
              return false;
            },
          ),
        ),
      );
      for (final key in ['install-google-play', 'install-app-store']) {
        final button = find.byKey(Key(key));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(
          find.text('تعذّر فتح المتجر. يرجى المحاولة مرة أخرى.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      }
      expect(opened.map((uri) => uri.toString()), [
        darjarGooglePlayUrl,
        darjarAppStoreUrl,
      ]);
      expect(find.byType(SelectableText), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
