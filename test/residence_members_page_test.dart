import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/presentation/residence_members_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
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
