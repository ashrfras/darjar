import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_deletion_repository.dart';
import 'package:darjar/features/residence/presentation/residence_administration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const target = (
    residenceId: 'residence',
    creatorId: 'localhost-212600000001',
  );
  const residence = ResidenceContext(
    residences: [
      UserResidence(
        id: 'residence',
        name: 'إقامة الاختبار',
        address: '',
        city: '',
        role: 'president',
        apartmentId: '',
        createdBy: 'localhost-212600000001',
      ),
    ],
    activeResidenceId: 'residence',
  );

  testWidgets(
    'eligible deletion shares the reset card and disappears when ineligible',
    (tester) async {
      final available = StreamController<bool>();
      addTearDown(available.close);
      final auth = await _signedInCreator();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            residenceContextProvider.overrideWith((_) async => residence),
            canDeleteResidenceProvider(
              target,
            ).overrideWith((_) => available.stream),
          ],
          child: _app(),
        ),
      );

      await tester.pumpAndSettle();
      final card = find.byKey(const Key('residence-reset-and-deletion-card'));
      final reset = find.byKey(const Key('reset-residence-button'));
      final dividers = find.descendant(
        of: card,
        matching: find.byType(Divider),
      );
      expect(find.descendant(of: card, matching: reset), findsOneWidget);
      expect(find.text('حذف الإقامة'), findsNothing);
      expect(dividers, findsNothing);
      available.add(true);
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('delete-residence-row'));
      expect(find.descendant(of: card, matching: action), findsOneWidget);
      expect(dividers, findsOneWidget);
      final row = tester.widget<ListTile>(action);
      expect(
        (row.title as Text).style,
        (tester.widget<ListTile>(reset).title as Text).style,
      );
      expect((row.leading as Icon).icon, Icons.delete_outline_rounded);
      expect((row.subtitle as Text).data, 'حذف بيانات الإقامة وإبطال الدعوات');
      expect((row.trailing as Icon).icon, Icons.chevron_left_rounded);
      available.add(false);
      await tester.pumpAndSettle();
      expect(action, findsNothing);
      expect(dividers, findsNothing);
    },
  );

  testWidgets(
    'confirmed deletion opens the feed of the next active residence',
    (tester) async {
      final deletion = Completer<void>();
      final calls = <String>[];
      var contextLoads = 0;
      const nextResidence = UserResidence(
        id: 'next-residence',
        name: 'الإقامة التالية',
        address: '',
        city: '',
        role: 'president',
        apartmentId: '',
      );
      final auth = await _signedInCreator();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          canDeleteResidenceProvider(
            target,
          ).overrideWith((_) => Stream.value(true)),
          deleteResidenceProvider.overrideWithValue((id) {
            calls.add(id);
            return deletion.future;
          }),
          residenceContextProvider.overrideWith((_) async {
            contextLoads++;
            return contextLoads == 1
                ? residence
                : const ResidenceContext(
                    residences: [nextResidence],
                    activeResidenceId: 'next-residence',
                  );
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        residenceContextProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final router = GoRouter(
        initialLocation: AppRoutes.administration,
        routes: [
          GoRoute(
            path: AppRoutes.administration,
            builder: (_, _) =>
                const Scaffold(body: ResidenceAdministrationPage()),
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (_, _) => Consumer(
              builder: (_, ref, _) => Scaffold(
                body: Text(
                  ref
                      .watch(residenceContextProvider)
                      .value!
                      .activeResidence!
                      .name,
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('حذف الإقامة'));
      await tester.tap(find.text('حذف الإقامة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تُبطل الدعوات'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);

      await tester.tap(find.text('حذف الإقامة'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'حذف الإقامة'));
      await tester.pump();
      expect(calls, ['residence']);
      deletion.complete();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(contextLoads, 2);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.community,
      );
      expect(find.text(nextResidence.name), findsOneWidget);
      expect(find.text('تم حذف الإقامة.'), findsOneWidget);
    },
  );
}

Future<LocalhostAuthRepository> _signedInCreator() async {
  final auth = LocalhostAuthRepository();
  addTearDown(auth.dispose);
  await auth.sendVerificationCode('+212600000001', languageCode: 'ar');
  await auth.confirmVerificationCode('123456');
  return auth;
}

Widget _app() => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const Scaffold(body: ResidenceAdministrationPage()),
);
