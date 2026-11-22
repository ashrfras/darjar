import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/presentation/residence_members_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('RTL residents can cancel or confirm leaving', (tester) async {
    final departures = <String>[];
    await _openResidents(tester, onLeave: (id) async => departures.add(id));

    expect(find.textContaining('عدد السكان'), findsNothing);
    final menu = find.byIcon(Icons.more_vert);
    expect(
      tester.getCenter(menu).dx,
      lessThan(tester.getCenter(find.text('سكان الإقامة')).dx),
    );
    await _selectLeave(tester);
    expect(
      find.text(
        'هل أنت متأكد من رغبتك في مغادرة هذه الإقامة؟ ستفقد إمكانية الوصول إلى محتواها ومعلوماتها، مع الاحتفاظ بجميع بيانات الشقة وسجل مدفوعاتها.',
      ),
      findsOneWidget,
    );
    final confirm = find.widgetWithText(FilledButton, 'مغادرة الإقامة');
    expect(
      tester.widget<FilledButton>(confirm).style?.backgroundColor?.resolve({}),
      AppColors.danger,
    );
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(departures, isEmpty);

    await _selectLeave(tester);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('جارٍ مغادرة الإقامة…'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    await tester.pumpAndSettle();
    expect(departures, ['residence-1']);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('leaving progress stays open while the request is pending', (
    tester,
  ) async {
    final departure = Completer<void>();
    await _openResidents(tester, onLeave: (_) => departure.future);
    await _selectLeave(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'مغادرة الإقامة'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    await tester.tapAt(const Offset(10, 10));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('جارٍ مغادرة الإقامة…'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    departure.complete();
    await tester.pumpAndSettle();
    expect(find.text('جارٍ مغادرة الإقامة…'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  for (final (role, delegated) in [
    ('president', false),
    ('deputy', false),
    ('treasurer', false),
    ('resident', true),
  ]) {
    testWidgets('leaving is blocked for $role (delegated: $delegated)', (
      tester,
    ) async {
      await _openResidents(
        tester,
        role: role,
        delegated: delegated,
        onLeave: (_) async => fail('An administrator cannot leave'),
      );
      await _selectLeave(tester);
      expect(find.text('لا يمكنك مغادرة الإقامة'), findsOneWidget);
      expect(
        find.text(
          'لا يمكنك مغادرة الإقامة ما دمت تمتلك صلاحيات إدارية. يرجى التنازل عن صلاحياتك الإدارية أولًا لتتمكن من المغادرة.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('موافق'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('سكان الإقامة'), findsOneWidget);
    });
  }

  testWidgets('a role change during confirmation blocks departure', (
    tester,
  ) async {
    await _openResidents(
      tester,
      onLeave: (_) async =>
          throw const ResidenceContextFailure('administrative-role'),
    );
    await _selectLeave(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'مغادرة الإقامة'));
    await tester.pumpAndSettle();
    expect(find.text('جارٍ مغادرة الإقامة…'), findsNothing);
    expect(find.text('لا يمكنك مغادرة الإقامة'), findsOneWidget);
  });

  testWidgets('each visit refreshes residents cached elsewhere in the app', (
    tester,
  ) async {
    final repository = _MembersRepository();
    final container = ProviderContainer.test(
      overrides: [
        residenceMembersRepositoryProvider.overrideWithValue(repository),
        residenceContextProvider.overrideWith(
          (ref) async => const ResidenceContext(
            residences: [
              UserResidence(
                id: 'residence-1',
                name: 'إقامة النخيل',
                address: '',
                city: '',
                role: 'resident',
                apartmentId: '',
              ),
            ],
            activeResidenceId: 'residence-1',
          ),
        ),
      ],
    );
    // The residence home and feed also listen to this shared provider.
    final subscription = container.listen(
      residenceDirectoryProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(residenceContextProvider.future);
    await container.read(residenceDirectoryProvider.future);
    final initialLoads = repository.loads;

    final router = GoRouter(
      initialLocation: AppRoutes.residence,
      routes: [
        GoRoute(
          path: AppRoutes.residence,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: AppRoutes.residenceResidents,
          builder: (_, _) => const Scaffold(body: ResidenceMembersPage()),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    repository.members = [_member('first'), _member('new-resident')];
    router.go(AppRoutes.residenceResidents);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('residence-member-first')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('residence-member-new-resident')),
      findsOneWidget,
    );
    expect(repository.loads, initialLoads + 1);
    expect(repository.residenceIds, everyElement('residence-1'));
    expect(repository.invitationRequests, everyElement(false));

    router.go(AppRoutes.residence);
    await tester.pumpAndSettle();
    repository.members = [_member('new-resident'), _member('another-resident')];
    router.go(AppRoutes.residenceResidents);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('residence-member-first')), findsNothing);
    expect(
      find.byKey(const ValueKey('residence-member-another-resident')),
      findsOneWidget,
    );
    expect(repository.loads, initialLoads + 2);

    // Ordinary widget rebuilds must not trigger another network request.
    tester.element(find.byType(ResidenceMembersPage)).markNeedsBuild();
    await tester.pumpAndSettle();
    expect(repository.loads, initialLoads + 2);
  });
}

Future<void> _openResidents(
  WidgetTester tester, {
  String role = 'resident',
  bool delegated = false,
  required Future<void> Function(String) onLeave,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.residenceResidents,
    routes: [
      GoRoute(
        path: AppRoutes.residence,
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: AppRoutes.residenceResidents,
        builder: (_, _) => const Scaffold(body: ResidenceMembersPage()),
      ),
    ],
  );
  addTearDown(router.dispose);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        residenceMembersRepositoryProvider.overrideWithValue(
          _MembersRepository(),
        ),
        leaveResidenceProvider.overrideWithValue(onLeave),
        residenceContextProvider.overrideWith((ref) async {
          return ResidenceContext(
            residences: [
              UserResidence(
                id: 'residence-1',
                name: 'إقامة النخيل',
                address: '',
                city: '',
                role: role,
                hasPresidentPermissions: delegated,
                apartmentId: 'apartment-1',
              ),
            ],
            activeResidenceId: 'residence-1',
          );
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectLeave(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('مغادرة الإقامة'));
  await tester.pumpAndSettle();
}

ResidenceMember _member(String id) => ResidenceMember(
  id: id,
  name: id,
  phone: '',
  role: ResidenceMemberRole.resident,
);

class _MembersRepository implements ResidenceMembersRepository {
  List<ResidenceMember> members = [_member('first')];
  int loads = 0;
  final residenceIds = <String>[];
  final invitationRequests = <bool>[];

  @override
  Future<ResidenceMembersData> load(
    String residenceId, {
    bool includeInvitations = true,
  }) async {
    loads++;
    residenceIds.add(residenceId);
    invitationRequests.add(includeInvitations);
    return ResidenceMembersData(buildings: const [], members: [...members]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
