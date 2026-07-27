import 'dart:async';

import 'package:darjar/app/app.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/profile/data/profile_repository.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_invitation_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('design foundation', () {
    test('uses the handoff breakpoints', () {
      expect(windowSizeClassFor(599), WindowSizeClass.compact);
      expect(windowSizeClassFor(600), WindowSizeClass.medium);
      expect(windowSizeClassFor(1023), WindowSizeClass.medium);
      expect(windowSizeClassFor(1024), WindowSizeClass.expanded);
    });

    test('uses the DarJar canvas and primary color', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.canvas);
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    });

    test('uses one short direction-neutral page transition', () {
      final transitions = AppTheme.light.pageTransitionsTheme.builders;

      expect(transitions.keys, containsAll(TargetPlatform.values));
      for (final builder in transitions.values) {
        expect(builder.transitionDuration, const Duration(milliseconds: 180));
        expect(
          builder.reverseTransitionDuration,
          const Duration(milliseconds: 180),
        );
      }
    });
  });

  group('mock repositories', () {
    test('Moroccan city catalog is comprehensive and uses stable IDs', () {
      expect(moroccanCities, hasLength(391));
      expect(
        moroccanCities.map((city) => city.id).toSet(),
        hasLength(moroccanCities.length),
      );
      expect(
        moroccanCities,
        contains(
          const MoroccanCity(
            id: '6141010',
            nameAr: 'الدار البيضاء',
            nameLatin: 'Casablanca',
          ),
        ),
      );
      expect(moroccanCities.any((city) => city.nameAr == 'الداخلة'), isTrue);
      expect(moroccanCities.any((city) => city.nameAr == 'الحسيمة'), isTrue);
    });

    test('create community posts and recommendations', () {
      final community = MockCommunityRepository();
      final directory = MockDirectoryRepository();

      community.createPost(title: 'عنوان', body: 'تفاصيل');
      directory.recommend(id: 'mohamed-electrician', comment: 'خدمة ممتازة');

      expect(community.getPosts().first.title, 'عنوان');
      expect(
        directory.getEntry('mohamed-electrician')!.reviews.first.comment,
        'خدمة ممتازة',
      );
    });

    test('community mock supports every post type and local interactions', () {
      final community = MockCommunityRepository();

      expect(
        community.getPosts().map((post) => post.kind).toSet(),
        containsAll(CommunityPostKind.values),
      );

      final post = community.getPost('poll-garden')!;
      final votesBefore = post.pollOptions.first.votes;
      community.vote(post.id, post.pollOptions.first.id);
      community.toggleLike(post.id);
      community.toggleSaved(post.id);
      community.addComment(post.id, 'سأشارك بالتأكيد');

      final updated = community.getPost(post.id)!;
      expect(updated.selectedPollOptionId, post.pollOptions.first.id);
      expect(updated.pollOptions.first.votes, votesBefore + 1);
      expect(updated.isLiked, isTrue);
      expect(updated.isSaved, isTrue);
      expect(updated.comments.last.body, 'سأشارك بالتأكيد');

      final created = community.createPost(
        title: 'صور الإقامة',
        body: 'أربع صور كحد أقصى',
        imagePaths: const ['1', '2', '3', '4', '5'],
      );
      expect(created.imagePaths, hasLength(4));
    });

    test('residence dashboard mock covers every dashboard section', () {
      final dashboard = MockResidenceRepository().getDashboardData();

      expect(dashboard.monthlyDue, greaterThan(0));
      expect(dashboard.finances.totalIncome, greaterThan(0));
      expect(dashboard.finances.totalExpenses, greaterThan(0));
      expect(dashboard.finances.currentBalance, greaterThanOrEqualTo(0));
      expect(dashboard.finances.collectionRate, closeTo(78 / 96, .001));
      expect(dashboard.finances.breakdown, isNotEmpty);
      expect(dashboard.finances.recentExpenses, isNotEmpty);
      expect(dashboard.notifications, isNotEmpty);
      expect(dashboard.documents, isNotEmpty);
      expect(dashboard.unitCount, greaterThan(0));
    });

    test('residence member assignments reference configured apartments', () {
      final data = _FakeResidenceMembersRepository.initialData;
      final apartmentIds = data.apartments
          .map((apartment) => apartment.id)
          .toSet();

      expect(data.buildings, hasLength(1));
      expect(data.apartments, isNotEmpty);
      expect(data.members, isNotEmpty);
      expect(
        data.members.every((member) => member.phone.startsWith('+')),
        isTrue,
      );
      expect(
        data.members
            .where((member) => member.apartmentId != null)
            .every((member) => apartmentIds.contains(member.apartmentId)),
        isTrue,
      );
    });

    test('residence floors are ordered by their Firestore order field', () {
      final floors = [
        const ResidenceFloor(
          id: 'third',
          nameAr: 'الثالث',
          nameEn: 'Third',
          apartments: [],
          order: 3,
        ),
        const ResidenceFloor(
          id: 'ground',
          nameAr: 'الأرضي',
          nameEn: 'Ground',
          apartments: [],
          order: 0,
        ),
        const ResidenceFloor(
          id: 'without-order',
          nameAr: 'قديم',
          nameEn: 'Legacy',
          apartments: [],
        ),
      ]..sort(compareResidenceFloorsByOrder);

      expect(floors.map((floor) => floor.id), [
        'ground',
        'third',
        'without-order',
      ]);
    });

    test('residence settings repository persists management changes', () async {
      final repository = _FakeResidenceSettingsRepository();
      final original = await repository.load('test-residence');
      expect(original.city, '6141010');
      expect(original.defaultSubscriptionAmount, 150);
      expect(FirestoreResidenceSetupRepository.defaultSubscriptionAmount, 150);

      await repository.save(
        original.copyWith(
          defaultSubscriptionAmount: 450,
          joinRequestsEnabled: false,
        ),
      );

      final updated = await repository.load('test-residence');
      expect(updated.defaultSubscriptionAmount, 450);
      expect(updated.joinRequestsEnabled, isFalse);
      expect(updated.residenceId, original.residenceId);
      expect(updated.invitationUrl, original.invitationUrl);
      expect(updated.buildings.single.floorCount, 3);
      expect(updated.managementOrganization, isNotEmpty);
      expect(updated.bankAccount, isNotEmpty);
    });
  });

  group('authentication foundation', () {
    test('normalizes equivalent international phone formats', () {
      expect(normalizePhoneNumber('+212 6 12-34-56-78'), '+212612345678');
      expect(normalizePhoneNumber('00212 6 12 34 56 78'), '+212612345678');
    });

    test('normalizes supported Moroccan mobile number formats', () {
      expect(normalizeMoroccanPhoneNumber('06 00 00 00 01'), '+212600000001');
      expect(normalizeMoroccanPhoneNumber('+212 600 000 001'), '+212600000001');
      expect(isValidMoroccanMobileNumber('+212600000001'), isTrue);
      expect(isValidMoroccanMobileNumber('+212500000001'), isFalse);
    });

    testWidgets('signed-out resident verifies a phone before residence setup', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(signedIn: false);
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        authRepository: authRepository,
      );

      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-auth-page')), findsOneWidget);
      expect(
        tester.getCenter(find.text('+212')).dx,
        lessThan(
          tester.getCenter(find.byKey(const Key('auth-phone-field'))).dx,
        ),
      );

      await tester.enterText(
        find.byKey(const Key('auth-phone-field')),
        '+212 600 000 001',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('auth-phone-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        '2126000000',
      );
      await tester.enterText(
        find.byKey(const Key('auth-phone-field')),
        '0600000001',
      );
      final phoneField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('auth-phone-field')),
          matching: find.byType(TextField),
        ),
      );
      expect(phoneField.keyboardType, TextInputType.number);
      await tester.tap(find.byKey(const Key('send-verification-code-button')));
      await tester.pumpAndSettle();

      expect(authRepository.requestedPhoneNumber, '+212600000001');
      expect(
        find.byKey(const Key('auth-verification-code-field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('auth-verification-code-field')),
        '123456',
      );
      await tester.tap(
        find.byKey(const Key('confirm-verification-code-button')),
      );
      await tester.pumpAndSettle();

      expect(authRepository.confirmedCode, '123456');
      expect(find.byKey(const Key('residence-setup-page')), findsOneWidget);
    });

    testWidgets('resident accepts selected invitations from multiple homes', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(signedIn: false);
      final accountRepository = _FakeAccountOnboardingRepository(
        resolution: const AccountResolution(
          phoneNumber: '+212600000001',
          profile: null,
          invitations: [
            ResidenceInvitation(
              path: 'residences/yasmine/invitations/invitation-1',
              id: 'invitation-1',
              residenceId: 'yasmine',
              residenceName: 'إقامة الياسمين',
              residenceAddress: 'المعاريف، الدار البيضاء',
              suggestedFirstName: 'أمينة',
              suggestedLastName: 'المريني',
              apartmentId: 'apartment-12',
              role: 'resident',
            ),
            ResidenceInvitation(
              path: 'residences/andalous/invitations/invitation-2',
              id: 'invitation-2',
              residenceId: 'andalous',
              residenceName: 'إقامة الأندلس',
              residenceAddress: 'أكدال، الرباط',
              suggestedFirstName: 'أمينة',
              suggestedLastName: 'المريني',
              apartmentId: 'apartment-5',
              role: 'owner',
            ),
          ],
        ),
      );
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        authRepository: authRepository,
        accountRepository: accountRepository,
      );

      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('auth-phone-field')),
        '0600000001',
      );
      await tester.tap(find.byKey(const Key('send-verification-code-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('auth-verification-code-field')),
        '123456',
      );
      await tester.tap(
        find.byKey(const Key('confirm-verification-code-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('account-resolution-page')), findsOneWidget);
      expect(find.text('أمينة المريني'), findsOneWidget);
      expect(find.text('+212600000001'), findsOneWidget);
      expect(find.text('إقامة الياسمين'), findsOneWidget);
      expect(find.text('إقامة الأندلس'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('residence-invitation-checkbox-invitation-1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('accept-selected-invitations-button')),
      );
      await tester.tap(
        find.byKey(const Key('accept-selected-invitations-button')),
      );
      await tester.pumpAndSettle();

      expect(accountRepository.acceptedInvitations.map((item) => item.id), [
        'invitation-1',
      ]);
      expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
    });

    testWidgets('existing user enters the app without residence setup', (
      tester,
    ) async {
      final accountRepository = _FakeAccountOnboardingRepository(
        resolution: const AccountResolution(
          phoneNumber: '+212600000001',
          profile: UserProfile(
            firstName: 'أمينة',
            lastName: 'المريني',
            phoneNumber: '+212600000001',
          ),
          invitations: [
            ResidenceInvitation(
              path: 'residences/andalous/invitations/invitation-new',
              id: 'invitation-new',
              residenceId: 'andalous',
              residenceName: 'الأندلس',
              residenceAddress: 'أكدال، الرباط',
              suggestedFirstName: 'أمينة',
              suggestedLastName: 'المريني',
              apartmentId: 'apartment-5',
              role: 'resident',
            ),
          ],
        ),
      );
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        accountRepository: accountRepository,
      );

      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
      expect(find.byKey(const Key('residence-setup-page')), findsNothing);
      expect(find.byKey(const Key('account-resolution-page')), findsNothing);
    });
  });

  group('residence setup foundation', () {
    test('removes generic residence prefixes from names', () {
      expect(normalizeResidenceName('إقامة النخيل'), 'النخيل');
      expect(normalizeResidenceName('اقامة النخيل'), 'النخيل');
      expect(normalizeResidenceName('Résidence Les Palmiers'), 'Les Palmiers');
      expect(normalizeResidenceName('residence: Alia'), 'Alia');
      expect(normalizeResidenceName('النخيل'), 'النخيل');
    });

    test('normalizes residence codes before lookup', () {
      expect(normalizeResidenceCode('48 27-31 65'), '48273165');
      expect(isValidResidenceCode('48273165'), isTrue);
      expect(isValidResidenceCode('4827316A'), isFalse);
      expect(isValidResidenceCode('1234'), isFalse);
    });

    testWidgets('resident finds a residence and joins immediately', (
      tester,
    ) async {
      final setupRepository = _FakeResidenceSetupRepository(
        residence: const ResidenceCodeSummary(
          residenceId: 'residence-yasmine',
          code: '48273165',
          name: 'إقامة الياسمين',
          address: 'حي المعاريف',
          city: '6141010',
          joinRequestsEnabled: true,
        ),
      );
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        residenceSetupRepository: setupRepository,
      );

      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('join-my-residence-option')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('join-first-name-field')),
        'أمين',
      );
      await tester.enterText(
        find.byKey(const Key('join-last-name-field')),
        'المريني',
      );
      await tester.enterText(
        find.byKey(const Key('join-residence-code-field')),
        '48273165',
      );
      await tester.tap(find.byKey(const Key('search-residence-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('residence-search-result')), findsOneWidget);
      expect(find.text('إقامة الياسمين'), findsOneWidget);
      expect(find.textContaining('حي المعاريف'), findsOneWidget);

      await tester.tap(find.byKey(const Key('join-found-residence-button')));
      await tester.pumpAndSettle();

      expect(setupRepository.requestedResidence?.code, '48273165');
      expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
    });
  });

  testWidgets('onboarding creates a residence and enters the compact app', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));

    expect(find.byKey(const Key('onboarding-page')), findsOneWidget);
    await _enterResidence(tester);

    expect(find.byKey(const Key('compact-shell')), findsOneWidget);
    expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Arabic onboarding copy and start action follow RTL', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));

    expect(find.text('كل ما يخص إقامتك، في مكان واحد.'), findsOneWidget);
    expect(
      find.text(
        'تابع أخبار إقامتك، واكتشف الخدمات المحلية، واطّلع على الشؤون المالية بكل وضوح وشفافية.',
      ),
      findsOneWidget,
    );

    final button = find.byKey(const Key('start-button'));
    final label = find.descendant(of: button, matching: find.text('ابدأ الآن'));
    final arrow = find.descendant(
      of: button,
      matching: find.byIcon(Icons.arrow_forward_rounded),
    );

    expect(tester.getCenter(arrow).dx, lessThan(tester.getCenter(label).dx));
  });

  testWidgets('compact header keeps identity right and actions left', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    final brand = find.byKey(const Key('compact-brand'));
    final residence = find.byKey(const Key('compact-residence'));
    final notification = find.byKey(const Key('notifications-button'));
    final profile = find.byKey(const Key('profile-button'));

    expect(tester.getCenter(brand).dx, greaterThan(195));
    expect(tester.getCenter(residence).dx, greaterThan(195));
    expect(tester.getCenter(notification).dx, lessThan(195));
    expect(tester.getCenter(profile).dx, lessThan(195));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final notificationButton = tester.widget<IconButton>(notification);
    expect(appBar.toolbarHeight, 58);
    expect(notificationButton.iconSize, 21);
    final brandImage = tester.widget<Image>(brand);
    expect(
      (brandImage.image as AssetImage).assetName,
      'assets/images/branding/darjar-logo.png',
    );
    expect(brandImage.fit, BoxFit.contain);
    expect(
      find.descendant(
        of: brand,
        matching: find.byIcon(Icons.apartment_rounded),
      ),
      findsNothing,
    );

    await tester.tap(notification);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-sheet')), findsOneWidget);
    expect(find.text('انقطاع مبرمج للماء'), findsOneWidget);
    expect(find.text('تذكير بواجبات الإقامة'), findsOneWidget);
    expect(find.text('صيانة المصعد'), findsOneWidget);

    final filter = find.byKey(const ValueKey('community-filter-all'));
    final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(tester.getTopLeft(filter).dy - appBarBottom, 12);
  });

  testWidgets('resident sees feedback for an unknown residence code', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));

    await tester.ensureVisible(find.byKey(const Key('start-button')));
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();
    expect(find.text('الانضمام إلى إقامتي'), findsOneWidget);
    expect(find.text('إنشاء إقامة جديدة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('join-my-residence-option')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join-residence-form')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('join-residence-code-field')),
      '48273165',
    );
    await tester.ensureVisible(
      find.byKey(const Key('search-residence-button')),
    );
    await tester.tap(find.byKey(const Key('search-residence-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('residence-not-found')), findsOneWidget);
    expect(find.text('لم نعثر على إقامة بهذا الرمز'), findsOneWidget);
    expect(
      find.text('تحقّق من الرمز مع الشخص الذي أرسله إليك ثم حاول مجدداً.'),
      findsOneWidget,
    );
  });

  testWidgets('medium and expanded shells remain available', (tester) async {
    await _pumpApp(tester, size: const Size(800, 1000));
    await _enterResidence(tester);
    expect(find.byKey(const Key('medium-shell')), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('residence-selector')),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('residence-selector')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-switcher-sheet')), findsOneWidget);
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(find.text('إقامة الاختبار'), findsWidgets);
    expect(find.textContaining('الدار البيضاء'), findsOneWidget);
    expect(find.textContaining('casablanca'), findsNothing);
    await tester.tap(find.text('إقامة الاختبار').last);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expanded-shell')), findsOneWidget);
    expect(find.text('إقامة الاختبار'), findsWidgets);
  });

  testWidgets(
    'resident switches real residences and accepts a new invitation',
    (tester) async {
      const invitation = ResidenceInvitation(
        path: 'residences/nakheel/invitations/invitation-3',
        id: 'invitation-3',
        residenceId: 'nakheel',
        residenceName: 'إقامة النخيل',
        residenceAddress: 'حي الرياض، الرباط',
        suggestedFirstName: 'أمينة',
        suggestedLastName: 'المريني',
        apartmentId: 'apartment-8',
        role: 'resident',
      );
      const residenceContext = ResidenceContext(
        residences: [
          UserResidence(
            id: 'yasmine',
            name: 'إقامة الياسمين الحقيقية',
            address: 'المعاريف، الدار البيضاء',
            city: '6141010',
            role: 'resident',
            apartmentId: 'apartment-12',
          ),
          UserResidence(
            id: 'andalous',
            name: 'إقامة الأندلس',
            address: 'أكدال، الرباط',
            city: '4421010',
            role: 'owner',
            apartmentId: 'apartment-5',
          ),
        ],
        activeResidenceId: 'yasmine',
        invitations: [invitation],
      );
      final contextRepository = _FakeResidenceContextRepository();
      final accountRepository = _FakeAccountOnboardingRepository(
        resolution: const AccountResolution(
          phoneNumber: '+212600000001',
          profile: UserProfile(
            firstName: 'أمينة',
            lastName: 'المريني',
            phoneNumber: '+212600000001',
            activeResidenceId: 'yasmine',
          ),
          invitations: [invitation],
        ),
      );
      await _pumpApp(
        tester,
        size: const Size(1280, 900),
        accountRepository: accountRepository,
        residenceContextRepository: contextRepository,
        residenceContext: residenceContext,
      );
      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expanded-shell')), findsOneWidget);

      expect(find.text('إقامة الياسمين الحقيقية'), findsOneWidget);
      await tester.tap(find.byKey(const Key('residence-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إقامة الأندلس'));
      await tester.pumpAndSettle();
      expect(contextRepository.selectedResidenceId, 'andalous');

      await tester.tap(find.byKey(const Key('notifications-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('in-app-invitation-invitation-3')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('accept-in-app-invitation-invitation-3')),
      );
      await tester.pumpAndSettle();
      expect(accountRepository.acceptedInvitations, [invitation]);
    },
  );

  testWidgets('residence loading exposes the Firestore error details', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      accountRepository: _FakeAccountOnboardingRepository(
        resolution: const AccountResolution(
          phoneNumber: '+212600000001',
          profile: UserProfile(
            firstName: 'أمينة',
            lastName: 'المريني',
            phoneNumber: '+212600000001',
          ),
          invitations: [],
        ),
      ),
      residenceContextError: const ResidenceContextFailure(
        'failed-precondition',
        'The query requires a collection group index.',
      ),
    );

    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('residence-context-error-details')),
      findsOneWidget,
    );
    expect(find.textContaining('failed-precondition'), findsOneWidget);
    expect(find.textContaining('collection group index'), findsOneWidget);
  });

  testWidgets('resident can create a community post', (tester) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('create-post-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-post-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
    expect(find.byKey(const Key('compact-brand')), findsOneWidget);
    expect(find.byKey(const Key('subpage-back-button')), findsOneWidget);
    expect(find.byKey(const Key('subpage-title')), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'لقاء الجيران');
    await tester.enterText(fields.at(1), 'نلتقي مساء السبت في الحديقة.');
    await tester.ensureVisible(find.byKey(const Key('add-post-images-button')));
    await tester.tap(find.byKey(const Key('add-post-images-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey(
          'mock-gallery-assets/images/community/elevator-maintenance.jpg',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('confirm-post-images-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('publish-post-button')));
    await tester.tap(find.byKey(const Key('publish-post-button')));
    await tester.pumpAndSettle();

    expect(find.text('لقاء الجيران'), findsOneWidget);
  });

  testWidgets('community filters posts and opens details with local comments', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 900));
    await _enterResidence(tester);

    expect(find.text('مجتمعك، صوتك، تفاعلك'), findsNothing);
    expect(
      find.byKey(const ValueKey('post-images-announcement-elevator')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('post-images-alert-water')), findsNothing);

    for (final filter in ['all', 'official', 'mine', 'saved']) {
      expect(find.byKey(ValueKey('community-filter-$filter')), findsOneWidget);
    }

    final mineFilter = find.byKey(const Key('community-filter-mine'));
    await tester.tap(mineFilter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('community-post-question-plumber')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-post-announcement-elevator')),
      findsNothing,
    );

    final savedFilter = find.byKey(const Key('community-filter-saved'));
    await tester.tap(savedFilter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('community-post-suggestion-trees')),
      findsOneWidget,
    );

    final officialFilter = find.byKey(const Key('community-filter-official'));
    await tester.tap(officialFilter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('community-post-announcement-elevator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-post-question-plumber')),
      findsNothing,
    );

    final announcement = find.byKey(
      const ValueKey('community-post-announcement-elevator'),
    );
    await tester.ensureVisible(announcement);
    await tester.tap(announcement);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('community-post-detail-page')), findsOneWidget);
    expect(find.byKey(const Key('subpage-title')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('subpage-back-button'))).height,
      40,
    );

    await tester.enterText(
      find.byKey(const Key('comment-field')),
      'شكراً على التوضيح',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit-comment-button')));
    await tester.tap(find.byKey(const Key('submit-comment-button')));
    await tester.pumpAndSettle();
    expect(find.text('شكراً على التوضيح'), findsOneWidget);
  });

  testWidgets('resident can browse a craftsman profile and recommend it', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.text('الدليل'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('directory-page')), findsOneWidget);

    final craftsman = find.byKey(
      const ValueKey('directory-entry-mohamed-electrician'),
    );
    await tester.ensureVisible(craftsman);
    await tester.tap(craftsman);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('directory-profile-page')), findsOneWidget);
    expect(find.text('محمد الكهربائي'), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
    expect(find.byKey(const Key('subpage-title')), findsNothing);

    await tester.tap(find.byKey(const Key('recommend-entry-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recommendation-comment')),
      'خدمة سريعة وموثوقة',
    );
    await tester.tap(find.byKey(const Key('submit-recommendation-button')));
    await tester.pumpAndSettle();
    expect(find.text('خدمة سريعة وموثوقة'), findsOneWidget);
  });

  testWidgets('residence exposes account, finances, and management routes', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);

    await tester.tap(find.text('حالة الواجبات'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dues-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);

    await tester.ensureVisible(find.text('مالية الإقامة'));
    await tester.tap(find.text('مالية الإقامة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-finances-page')), findsOneWidget);
    expect(find.byKey(const Key('finance-total-income')), findsOneWidget);
    expect(find.byKey(const Key('finance-total-expenses')), findsOneWidget);
    expect(find.byKey(const Key('finance-current-balance')), findsOneWidget);
    expect(find.byKey(const Key('finance-collection-rate')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('residence-expense-elevator-service-july')),
      findsOneWidget,
    );

    final incomeCard = tester.getRect(
      find.byKey(const Key('finance-total-income')),
    );
    final expensesCard = tester.getRect(
      find.byKey(const Key('finance-total-expenses')),
    );
    expect(incomeCard.top, expensesCard.top);
    expect(incomeCard.left, isNot(expensesCard.left));

    await tester.ensureVisible(
      find.byKey(const Key('view-all-transactions-button')),
    );
    await tester.tap(find.byKey(const Key('view-all-transactions-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finance-transactions-page')), findsOneWidget);
    expect(find.byKey(const Key('finance-period-picker')), findsOneWidget);
    expect(find.byKey(const Key('period-income-total')), findsOneWidget);
    expect(find.byKey(const Key('period-expenses-total')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('finance-transaction-dues-july')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('subpage-back-button')));
    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-finances-page')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('subpage-back-button')));
    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('معلومات الإدارة'));
    await tester.tap(find.text('معلومات الإدارة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('management-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
  });

  testWidgets('residence dashboard exposes its five resident modules', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 1100));
    await _enterResidence(tester);
    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();

    expect(find.text('حسابي'), findsWidgets);
    for (final section in [
      'مالية الإقامة',
      'الوثائق',
      'الإشعارات الإدارية',
      'معلومات الإدارة',
    ]) {
      expect(find.text(section), findsOneWidget);
    }
  });

  testWidgets('profile exposes real editable account and residence data', (
    tester,
  ) async {
    final profileRepository = _FakeProfileRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      profileRepository: profileRepository,
    );
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-page')), findsOneWidget);
    expect(find.text('+212 6 12 34 56 78'), findsOneWidget);
    expect(find.text('أمين المريني'), findsOneWidget);
    expect(find.text('الإقامات'), findsOneWidget);
    expect(find.text('إقامة الاختبار'), findsWidgets);
    expect(find.text('الشقة رقم 12'), findsOneWidget);
    expect(find.text('الحالية'), findsOneWidget);
    expect(find.text('الإدارة'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsNothing);
    expect(find.text('الإعدادات'), findsNothing);
    expect(find.text('إعادة عرض البداية'), findsNothing);
    expect(find.byKey(const Key('profile-phone-number')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester.getCenter(find.byKey(const Key('profile-full-name'))).dx,
      closeTo(
        tester.getCenter(find.byKey(const Key('profile-information-card'))).dx,
        1,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('subpage-back-button'))).height,
      40,
    );
    expect(
      tester.getCenter(find.byKey(const Key('subpage-title'))).dy,
      closeTo(
        tester.getCenter(find.byKey(const Key('subpage-back-button'))).dy,
        1,
      ),
    );
    final compactHeader = find.byKey(const Key('title-only-subpage-header'));
    final profileCard = find.byType(DarJarCard).first;
    expect(
      tester.getTopLeft(profileCard).dy -
          tester.getBottomLeft(compactHeader).dy,
      AppSpacing.small,
    );

    await tester.tap(find.byKey(const Key('edit-profile-name-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-profile-name-sheet')), findsOneWidget);
    expect(find.text('تعديل الاسم والنسب'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    final editSheet = tester.widget<DecoratedBox>(
      find.byKey(const Key('edit-profile-name-sheet')),
    );
    expect((editSheet.decoration as BoxDecoration).color, AppColors.surface);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-first-name-field')),
        matching: find.byType(TextField),
      ),
      'يوسف',
    );
    await tester.ensureVisible(find.byKey(const Key('save-profile-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(profileRepository.profile.firstName, 'يوسف');
    expect(find.text('يوسف المريني'), findsOneWidget);
    expect(find.text('تم حفظ معلومات الحساب.'), findsOneWidget);
  });

  testWidgets('residence management is hidden from regular residents', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceContext: const ResidenceContext(
        residences: [
          UserResidence(
            id: 'test-residence',
            name: 'إقامة الاختبار',
            address: 'شارع الاختبار',
            city: '6141010',
            role: 'resident',
            apartmentId: '',
          ),
        ],
        activeResidenceId: 'test-residence',
        invitations: [],
      ),
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('residence-management-section')), findsNothing);
    expect(find.byKey(const Key('manage-residence-link')), findsNothing);
  });

  testWidgets(
    'residence management is visible with delegated president permissions',
    (tester) async {
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        residenceContext: const ResidenceContext(
          residences: [
            UserResidence(
              id: 'test-residence',
              name: 'إقامة الاختبار',
              address: 'شارع الاختبار',
              city: '6141010',
              role: 'resident',
              apartmentId: '',
              hasPresidentPermissions: true,
            ),
          ],
          activeResidenceId: 'test-residence',
          invitations: [],
        ),
      );
      await _enterResidence(tester);
      await tester.tap(find.byKey(const Key('profile-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('residence-management-section')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('manage-residence-link')), findsOneWidget);
    },
  );

  testWidgets('residence management links are visible and navigate', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('residence-management-section')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('residence-management-section')))
          .dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('profile-residences-card'))).dy,
      ),
    );
    expect(find.text('الإدارة'), findsOneWidget);
    expect(find.text('إدارة الشقق وتوزيع السكان داخل الإقامة'), findsOneWidget);
    expect(find.byKey(const Key('manage-projects-link')), findsNothing);
    expect(
      find.text('هيكلة الإقامة، معلومات الإقامة، قيمة الاشتراك'),
      findsOneWidget,
    );
    expect(find.text('إعدادات الإقامة'), findsOneWidget);

    final residenceLink = find.byKey(const Key('manage-residence-link'));
    final apartmentsLink = find.byKey(const Key('manage-apartments-link'));
    expect(
      tester.getTopLeft(residenceLink).dy,
      lessThan(tester.getTopLeft(apartmentsLink).dy),
    );

    final chevrons = find.byIcon(Icons.chevron_left_rounded);
    expect(chevrons, findsNWidgets(2));
    for (final icon in tester.widgetList<Icon>(chevrons)) {
      expect(icon.textDirection, TextDirection.ltr);
    }

    for (final navigation in [
      (link: 'manage-residence-link', page: 'residence-settings-page'),
      (link: 'manage-apartments-link', page: 'apartments-management-page'),
    ]) {
      await tester.ensureVisible(find.byKey(Key(navigation.link)));
      await tester.tap(find.byKey(Key(navigation.link)));
      await tester.pumpAndSettle();
      expect(find.byKey(Key(navigation.page)), findsOneWidget);
      await tester.tap(find.byKey(const Key('subpage-back-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-page')), findsOneWidget);
    }
  });

  testWidgets(
    'residence settings manage details, structure, and subscription',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      final settingsRepository = _FakeResidenceSettingsRepository();
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        authRepository: authRepository,
        residenceSettingsRepository: settingsRepository,
      );
      await _enterResidence(tester);
      await tester.tap(find.byKey(const Key('profile-button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('manage-residence-link')),
      );
      await tester.tap(find.byKey(const Key('manage-residence-link')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('residence-settings-page')), findsOneWidget);
      expect(
        find.byKey(const Key('residence-information-section')),
        findsOneWidget,
      );
      final residenceIdField = find.descendant(
        of: find.byKey(const Key('residence-id-field')),
        matching: find.byType(TextField),
      );
      expect(residenceIdField, findsOneWidget);
      expect(tester.widget<TextField>(residenceIdField).readOnly, isTrue);
      expect(
        tester.widget<TextField>(residenceIdField).controller?.text,
        '48273165',
      );
      expect(
        find.byKey(const Key('settings-residence-city-field')),
        findsOneWidget,
      );
      expect(find.text('الدار البيضاء'), findsOneWidget);
      expect(
        find.byKey(const Key('residence-structure-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('management-information-section')),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(find.byKey(const Key('management-information-section')))
            .dy,
        greaterThan(
          tester
              .getTopLeft(
                find.byKey(const Key('residence-information-section')),
              )
              .dy,
        ),
      );
      for (final fieldKey in [
        'management-organization-field',
        'management-phone-field',
        'management-bank-name-field',
        'management-bank-account-field',
      ]) {
        expect(find.byKey(Key(fieldKey)), findsOneWidget);
      }
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('management-organization-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        'أمين المريني',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('management-phone-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        '+212600000001',
      );
      expect(
        find.byKey(const Key('residence-subscription-section')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('default-subscription-amount-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        '150',
      );
      expect(find.byKey(const Key('sticky-save-bar')), findsOneWidget);
      expect(
        find.byKey(const Key('save-residence-settings-button')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(const Key('save-residence-settings-button')),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('establishment-year-field')),
        '20ab25',
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('establishment-year-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        '2025',
      );
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(const Key('save-residence-settings-button')),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNotNull,
      );

      await tester.ensureVisible(find.byKey(const Key('add-building-button')));
      await tester.tap(find.byKey(const Key('add-building-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('building-editor-dialog')), findsOneWidget);
      expect(find.text('مثال: جناح أ'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('building-name-field')),
        'المبنى B',
      );
      await tester.enterText(
        find.byKey(const Key('building-floor-count-field')),
        '5 طوابق',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('building-floor-count-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        '5',
      );
      await tester.tap(find.byKey(const Key('confirm-building-button')));
      await tester.pumpAndSettle();
      expect(find.text('المبنى B'), findsOneWidget);
      expect(find.text('عدد الطوابق: 5'), findsOneWidget);
      final deleteBuildingButton = find.byTooltip('حذف المبنى').last;
      await tester.ensureVisible(deleteBuildingButton);
      await tester.tap(deleteBuildingButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('delete-building-dialog')), findsOneWidget);
      expect(
        find.text('هل تريد حذف المبنى B من هيكل الإقامة؟'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-delete-building-button')));
      await tester.pumpAndSettle();
      expect(find.text('المبنى B'), findsNothing);

      expect(find.byKey(const Key('residence-joining-section')), findsNothing);
      expect(find.byKey(const Key('permanent-invitation-link')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('management-organization-field')),
        'شركة الإدارة الجديدة',
      );
      await tester.enterText(
        find.byKey(const Key('management-phone-field')),
        '+212 5 22 11 22 33',
      );
      await tester.tap(
        find.byKey(const Key('save-residence-settings-button')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('تم حفظ إعدادات الإقامة.'), findsOneWidget);
      expect(
        settingsRepository.settings.managementOrganization,
        'شركة الإدارة الجديدة',
      );
      expect(settingsRepository.settings.managementPhone, '+212 5 22 11 22 33');
      expect(settingsRepository.settings.defaultSubscriptionAmount, 150);
      expect(authRepository.currentUser?.phoneNumber, '+212600000001');
    },
  );

  testWidgets('residence settings warn before leaving with unsaved changes', (
    tester,
  ) async {
    final settingsRepository = _FakeResidenceSettingsRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceSettingsRepository: settingsRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-residence-link')));
    await tester.tap(find.byKey(const Key('manage-residence-link')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('residence-name-field')),
      'إقامة معدلة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('unsaved-residence-settings-dialog')),
      findsOneWidget,
    );
    expect(find.text('لم يتم حفظ التعديلات'), findsOneWidget);
    expect(find.byKey(const Key('save-before-leaving-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-before-leaving-button')));
    await tester.pumpAndSettle();

    expect(settingsRepository.settings.name, 'إقامة معدلة');
    expect(find.byKey(const Key('profile-page')), findsOneWidget);
  });

  testWidgets('internal component gallery remains navigable', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 844));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('gallery-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('component-gallery')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
  });

  testWidgets('apartments and residents support daily assignments', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-apartments-link')));
    await tester.tap(find.byKey(const Key('manage-apartments-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apartments-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('floor-ground-floor')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('apartment-apartment-12')),
      findsOneWidget,
    );
    expect(find.text('العمارة الرئيسية'), findsNothing);
    expect(find.text('إعدادات الإقامة'), findsNothing);

    await tester.tap(find.byKey(const Key('add-apartment-button')));
    await tester.pumpAndSettle();
    expect(find.text('رقم الشقة'), findsOneWidget);
    expect(find.text('رقم أو اسم الشقة'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('new-apartment-number-field')),
      '03A',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('new-apartment-number-field')),
          )
          .controller
          ?.text,
      '03',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('confirm-add-apartment-button')),
    );
    await tester.tap(find.byKey(const Key('confirm-add-apartment-button')));
    await tester.pumpAndSettle();
    final addedApartment = find.byKey(
      const ValueKey('apartment-apartment-ground-floor-3'),
    );
    expect(addedApartment, findsOneWidget);

    final deleteAddedApartment = find.byKey(
      const ValueKey('delete-apartment-apartment-ground-floor-3'),
    );
    await tester.ensureVisible(deleteAddedApartment);
    await tester.pumpAndSettle();
    await tester.tap(deleteAddedApartment);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle();
    expect(addedApartment, findsNothing);

    final residentsTab = find.text('السكان').last;
    await tester.ensureVisible(residentsTab);
    await tester.pumpAndSettle();
    await tester.tap(residentsTab);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residents-view')), findsOneWidget);
    expect(find.byKey(const Key('residents-search-field')), findsOneWidget);
    expect(find.byType(PopupMenuButton<dynamic>), findsNothing);

    final actions = find.byKey(const ValueKey('resident-actions-member-karim'));
    await tester.ensureVisible(actions);
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعيين الشقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الشقة 22'));
    await tester.pumpAndSettle();

    expect(find.text('تم تحديث تعيين الشقة.'), findsOneWidget);
    await tester.ensureVisible(actions);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('resident-member-karim')),
        matching: find.text('الشقة 22'),
      ),
      findsOneWidget,
    );

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تغيير الدور'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-role-deputy')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('resident-member-karim')),
        matching: find.text('نائب'),
      ),
      findsOneWidget,
    );

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('منح صلاحيات الرئيس'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('resident-member-karim')),
        matching: find.text('صلاحيات الرئيس'),
      ),
      findsOneWidget,
    );

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تغيير الدور'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-role-president')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transfer-presidency-dialog')), findsOneWidget);
    expect(find.textContaining('سيتم نزع صفة الرئيس منك'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('confirm-transfer-presidency-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('resident-member-karim')),
        matching: find.text('رئيس'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('residents data reloads when entering management again', (
    tester,
  ) async {
    final membersRepository = _FakeResidenceMembersRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceMembersRepository: membersRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-apartments-link')));
    await tester.tap(find.byKey(const Key('manage-apartments-link')));
    await tester.pumpAndSettle();
    final firstLoadCount = membersRepository.loadCount;

    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-apartments-link')));
    await tester.tap(find.byKey(const Key('manage-apartments-link')));
    await tester.pumpAndSettle();

    expect(membersRepository.loadCount, greaterThan(firstLoadCount));
  });

  testWidgets('residents use international phones and group invitations', (
    tester,
  ) async {
    final membersRepository = _FakeResidenceMembersRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceMembersRepository: membersRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-apartments-link')));
    await tester.tap(find.byKey(const Key('manage-apartments-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-invitation-button')), findsNothing);
    await tester.tap(find.text('السكان').last);
    await tester.pumpAndSettle();

    expect(find.text('+212 6 12 34 56 78'), findsOneWidget);
    expect(find.textContaining('@example.com'), findsNothing);
    final searchField = find.byKey(const Key('residents-search-field'));
    final addResidentButton = find.byKey(const Key('add-resident-button'));
    final groupInvitationButton = find.byKey(
      const Key('group-invitation-button'),
    );
    expect(
      tester.getBottomLeft(addResidentButton).dy,
      lessThan(tester.getTopLeft(searchField).dy),
    );
    expect(
      tester.getTopLeft(addResidentButton).dy,
      closeTo(tester.getTopLeft(groupInvitationButton).dy, 2),
    );
    await tester.tap(find.byKey(const Key('add-resident-button')));
    await tester.pumpAndSettle();

    expect(
      find
          .byKey(const Key('resident-country-code-field'))
          .evaluate()
          .single
          .widget,
      isA<DropdownButtonFormField<String>>(),
    );
    await tester.enterText(
      find.byKey(const Key('resident-first-name-field')),
      'مريم',
    );
    await tester.enterText(
      find.byKey(const Key('resident-last-name-field')),
      'المنصوري',
    );
    await tester.enterText(
      find.byKey(const Key('resident-phone-field')),
      '06 98 76 54 32',
    );
    tester.testTextInput.hide();
    await tester.tap(find.byKey(const Key('resident-apartment-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الشقة 23 · الطابق الثاني').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('confirm-add-resident-button')),
    );
    await tester.tap(find.byKey(const Key('confirm-add-resident-button')));
    await tester.pumpAndSettle();

    expect(membersRepository.createdInvitations, hasLength(1));
    expect(membersRepository.createdInvitations.single.firstName, 'مريم');
    expect(find.text('تم إنشاء دعوة الساكن.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pending-invitation-+212698765432')),
      findsOneWidget,
    );
    expect(find.text('الدعوة معلّقة'), findsOneWidget);
    expect(find.text('+212698765432'), findsOneWidget);

    await tester.ensureVisible(groupInvitationButton);
    await tester.pumpAndSettle();
    await tester.tap(groupInvitationButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group-invitation-page')), findsOneWidget);
    expect(find.text('الدعوة الجماعية'), findsOneWidget);
    expect(find.byKey(const Key('public-invitation-link')), findsOneWidget);
    expect(find.byKey(const Key('group-invitation-qr-code')), findsOneWidget);
    expect(find.text('السماح بالانضمام عبر الرابط'), findsOneWidget);
    expect(
      find.byKey(const Key('copy-group-invitation-link-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('share-group-invitation-link-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('print-group-invitation-qr-button')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
  AuthRepository? authRepository,
  AccountOnboardingRepository? accountRepository,
  ResidenceSetupRepository? residenceSetupRepository,
  ResidenceContextRepository? residenceContextRepository,
  ResidenceMembersRepository? residenceMembersRepository,
  ResidenceInvitationRepository? residenceInvitationRepository,
  ResidenceSettingsRepository? residenceSettingsRepository,
  ProfileRepository? profileRepository,
  ResidenceContext? residenceContext,
  Object? residenceContextError,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = authRepository ?? _FakeAuthRepository();
  final onboardingRepository =
      accountRepository ?? _FakeAccountOnboardingRepository();
  final setupRepository =
      residenceSetupRepository ?? _FakeResidenceSetupRepository();
  final contextRepository =
      residenceContextRepository ?? _FakeResidenceContextRepository();
  final membersRepository =
      residenceMembersRepository ?? _FakeResidenceMembersRepository();
  final invitationRepository =
      residenceInvitationRepository ?? _FakeResidenceInvitationRepository();
  final settingsRepository =
      residenceSettingsRepository ?? _FakeResidenceSettingsRepository();
  final currentProfileRepository =
      profileRepository ?? _FakeProfileRepository();
  final contextData = residenceContext ?? _defaultResidenceContext;
  if (repository is _FakeAuthRepository) {
    addTearDown(repository.dispose);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        appInitialLocationProvider.overrideWithValue(AppRoutes.onboarding),
        accountOnboardingRepositoryProvider.overrideWithValue(
          onboardingRepository,
        ),
        residenceSetupRepositoryProvider.overrideWithValue(setupRepository),
        residenceContextRepositoryProvider.overrideWithValue(contextRepository),
        residenceMembersRepositoryProvider.overrideWithValue(membersRepository),
        residenceInvitationRepositoryProvider.overrideWithValue(
          invitationRepository,
        ),
        residenceSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
        profileRepositoryProvider.overrideWithValue(currentProfileRepository),
        residenceContextProvider.overrideWith((ref) async {
          if (residenceContextError != null) {
            throw residenceContextError;
          }
          return contextData;
        }),
      ],
      child: const DarJarApp(),
    ),
  );
  await tester.pumpAndSettle();
}

const _defaultResidenceContext = ResidenceContext(
  residences: [
    UserResidence(
      id: 'test-residence',
      name: 'إقامة الاختبار',
      address: 'شارع الاختبار',
      city: '6141010',
      role: 'owner',
      apartmentId: '',
    ),
  ],
  activeResidenceId: 'test-residence',
  invitations: [],
);

Future<void> _enterResidence(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('start-button')));
  await tester.tap(find.byKey(const Key('start-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('residence-setup-page')), findsOneWidget);
  final setupBrand = tester.widget<Text>(
    find.byKey(const Key('setup-brand-title')),
  );
  expect(setupBrand.style?.fontFamily, 'Cairo');
  expect(setupBrand.style?.fontWeight, FontWeight.w800);

  await tester.tap(find.byKey(const Key('create-new-residence-option')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('create-residence-form')), findsOneWidget);
  expect(find.byKey(const Key('residence-name-field')), findsOneWidget);
  expect(find.byKey(const Key('residence-address-field')), findsOneWidget);
  expect(find.byKey(const Key('residence-city-field')), findsOneWidget);
  expect(find.text('معلومات الإقامة'), findsOneWidget);
  expect(find.text('معلوماتك'), findsOneWidget);
  expect(find.byKey(const Key('country-code-field')), findsNothing);
  expect(find.byKey(const Key('resident-phone-field')), findsNothing);
  expect(find.byKey(const Key('resident-first-name-field')), findsOneWidget);
  expect(find.byKey(const Key('resident-last-name-field')), findsOneWidget);

  await tester.enterText(
    find.byKey(const Key('residence-name-field')),
    'إقامة الاختبار',
  );
  await tester.enterText(
    find.byKey(const Key('residence-address-field')),
    'شارع الاختبار',
  );
  await tester.tap(find.byKey(const Key('residence-city-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('الدار البيضاء').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('resident-first-name-field')),
    'أمين',
  );
  await tester.enterText(
    find.byKey(const Key('resident-last-name-field')),
    'المريني',
  );
  await tester.ensureVisible(find.byKey(const Key('enter-residence-button')));
  await tester.tap(find.byKey(const Key('enter-residence-button')));
  await tester.pumpAndSettle();
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({bool signedIn = true})
    : _currentUser = signedIn
          ? const AuthUser(uid: 'test-user', phoneNumber: '+212600000001')
          : null;

  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast(sync: true);
  AuthUser? _currentUser;
  String? requestedPhoneNumber;
  String? confirmedCode;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> sendVerificationCode(String phoneNumber) async {
    requestedPhoneNumber = phoneNumber;
  }

  @override
  Future<void> confirmVerificationCode(String code) async {
    confirmedCode = code;
    _currentUser = const AuthUser(
      uid: 'test-user',
      phoneNumber: '+212600000001',
    );
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> dispose() => _authStateController.close();
}

class _FakeAccountOnboardingRepository implements AccountOnboardingRepository {
  _FakeAccountOnboardingRepository({
    this.resolution = const AccountResolution(
      phoneNumber: '+212600000001',
      profile: null,
      invitations: [],
    ),
  });

  final AccountResolution resolution;
  List<ResidenceInvitation> acceptedInvitations = [];

  @override
  Future<AccountResolution> loadResolution(AuthUser user) async => resolution;

  @override
  Future<void> acceptInvitations({
    required AuthUser user,
    required AccountResolution resolution,
    required List<ResidenceInvitation> invitations,
  }) async {
    acceptedInvitations = invitations;
  }
}

class _FakeProfileRepository implements ProfileRepository {
  ResidentProfile profile = const ResidentProfile(
    firstName: 'أمين',
    lastName: 'المريني',
    phoneNumber: '+212 6 12 34 56 78',
    residences: [
      ProfileResidence(
        id: 'test-residence',
        name: 'إقامة الاختبار',
        apartmentNumber: '12',
      ),
    ],
  );

  @override
  Future<ResidentProfile> load({
    required AuthUser user,
    required ResidenceContext residenceContext,
  }) async {
    return profile;
  }

  @override
  Future<void> updateNames({
    required AuthUser user,
    required List<String> residenceIds,
    required String firstName,
    required String lastName,
  }) async {
    profile = ResidentProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: profile.phoneNumber,
      residences: profile.residences,
    );
  }
}

class _FakeResidenceSetupRepository implements ResidenceSetupRepository {
  _FakeResidenceSetupRepository({this.residence});

  final ResidenceCodeSummary? residence;
  CreateResidenceInput? createdInput;
  ResidenceCodeSummary? requestedResidence;

  @override
  Future<CreatedResidence> createResidence({
    required AuthUser user,
    required CreateResidenceInput input,
  }) async {
    createdInput = input;
    return const CreatedResidence(
      residenceId: 'created-residence',
      joinCode: '48273165',
    );
  }

  @override
  Future<ResidenceCodeSummary?> findByCode(String code) async {
    if (residence?.code == normalizeResidenceCode(code)) {
      return residence;
    }
    return null;
  }

  @override
  Future<void> requestToJoin({
    required AuthUser user,
    required ResidenceCodeSummary residence,
    required String firstName,
    required String lastName,
  }) async {
    requestedResidence = residence;
  }
}

class _CreatedInvitation {
  const _CreatedInvitation({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.apartmentId,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String apartmentId;
}

class _FakeResidenceMembersRepository implements ResidenceMembersRepository {
  static const initialData = ResidenceMembersData(
    buildings: [
      ResidenceBuilding(
        id: 'main-building',
        nameAr: 'العمارة الرئيسية',
        nameEn: 'Main building',
        floors: [
          ResidenceFloor(
            id: 'ground-floor',
            nameAr: 'الطابق الأرضي',
            nameEn: 'Ground floor',
            apartments: [
              ResidenceApartment(
                id: 'apartment-01',
                number: '01',
                floorId: 'ground-floor',
                buildingId: 'main-building',
              ),
              ResidenceApartment(
                id: 'apartment-02',
                number: '02',
                floorId: 'ground-floor',
                buildingId: 'main-building',
              ),
            ],
          ),
          ResidenceFloor(
            id: 'first-floor',
            nameAr: 'الطابق الأول',
            nameEn: 'First floor',
            apartments: [
              ResidenceApartment(
                id: 'apartment-11',
                number: '11',
                floorId: 'first-floor',
                buildingId: 'main-building',
              ),
              ResidenceApartment(
                id: 'apartment-12',
                number: '12',
                floorId: 'first-floor',
                buildingId: 'main-building',
              ),
            ],
          ),
          ResidenceFloor(
            id: 'second-floor',
            nameAr: 'الطابق الثاني',
            nameEn: 'Second floor',
            apartments: [
              ResidenceApartment(
                id: 'apartment-21',
                number: '21',
                floorId: 'second-floor',
                buildingId: 'main-building',
              ),
              ResidenceApartment(
                id: 'apartment-22',
                number: '22',
                floorId: 'second-floor',
                buildingId: 'main-building',
              ),
              ResidenceApartment(
                id: 'apartment-23',
                number: '23',
                floorId: 'second-floor',
                buildingId: 'main-building',
              ),
            ],
          ),
        ],
      ),
    ],
    members: [
      ResidenceMember(
        id: 'test-user',
        name: 'يوسف العلوي',
        phone: '+212 6 12 34 56 78',
        role: ResidenceMemberRole.president,
        apartmentId: 'apartment-12',
      ),
      ResidenceMember(
        id: 'member-karim',
        name: 'كريم التازي',
        phone: '+212 6 56 78 90 12',
        role: ResidenceMemberRole.resident,
      ),
    ],
  );

  ResidenceMembersData data = initialData;
  final List<_CreatedInvitation> createdInvitations = [];
  int loadCount = 0;

  @override
  Future<ResidenceMembersData> load(String residenceId) async {
    loadCount += 1;
    return data;
  }

  @override
  Future<void> createInvitation({
    required String residenceId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String apartmentId,
  }) async {
    createdInvitations.add(
      _CreatedInvitation(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        apartmentId: apartmentId,
      ),
    );
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    data = ResidenceMembersData(
      buildings: data.buildings,
      members: data.members,
      pendingInvitations: [
        ...data.pendingInvitations,
        ResidencePendingInvitation(
          id: normalizedPhone,
          name: '$firstName $lastName'.trim(),
          phone: normalizedPhone,
          apartmentId: apartmentId,
        ),
      ],
    );
  }

  @override
  Future<void> assignApartment({
    required String residenceId,
    required String memberId,
    required String? apartmentId,
  }) async {
    data = ResidenceMembersData(
      buildings: data.buildings,
      pendingInvitations: data.pendingInvitations,
      members: [
        for (final member in data.members)
          ResidenceMember(
            id: member.id,
            name: member.name,
            phone: member.phone,
            role: member.role,
            hasPresidentPermissions: member.hasPresidentPermissions,
            apartmentId: member.id == memberId
                ? apartmentId
                : member.apartmentId,
          ),
      ],
    );
  }

  @override
  Future<void> addApartment({
    required String residenceId,
    required String buildingId,
    required String floorId,
    required String number,
  }) async {
    data = ResidenceMembersData(
      buildings: [
        for (final building in data.buildings)
          ResidenceBuilding(
            id: building.id,
            nameAr: building.nameAr,
            nameEn: building.nameEn,
            floors: [
              for (final floor in building.floors)
                ResidenceFloor(
                  id: floor.id,
                  nameAr: floor.nameAr,
                  nameEn: floor.nameEn,
                  apartments: [
                    ...floor.apartments,
                    if (building.id == buildingId && floor.id == floorId)
                      ResidenceApartment(
                        id: 'apartment-$floorId-$number',
                        number: number,
                        floorId: floorId,
                        buildingId: buildingId,
                      ),
                  ],
                ),
            ],
          ),
      ],
      members: data.members,
      pendingInvitations: data.pendingInvitations,
    );
  }

  @override
  Future<void> deleteApartment({
    required String residenceId,
    required ResidenceApartment apartment,
  }) async {
    data = ResidenceMembersData(
      buildings: [
        for (final building in data.buildings)
          ResidenceBuilding(
            id: building.id,
            nameAr: building.nameAr,
            nameEn: building.nameEn,
            floors: [
              for (final floor in building.floors)
                ResidenceFloor(
                  id: floor.id,
                  nameAr: floor.nameAr,
                  nameEn: floor.nameEn,
                  apartments: floor.apartments
                      .where((item) => item.id != apartment.id)
                      .toList(),
                ),
            ],
          ),
      ],
      members: data.members,
      pendingInvitations: data.pendingInvitations,
    );
  }

  @override
  Future<void> removeMember({
    required String residenceId,
    required String memberId,
  }) async {
    data = ResidenceMembersData(
      buildings: data.buildings,
      pendingInvitations: data.pendingInvitations,
      members: data.members.where((member) => member.id != memberId).toList(),
    );
  }

  @override
  Future<void> changeRole({
    required String residenceId,
    required String memberId,
    required ResidenceMemberRole role,
  }) async {
    data = ResidenceMembersData(
      buildings: data.buildings,
      pendingInvitations: data.pendingInvitations,
      members: [
        for (final member in data.members)
          ResidenceMember(
            id: member.id,
            name: member.name,
            phone: member.phone,
            role: member.id == memberId ? role : member.role,
            hasPresidentPermissions: member.hasPresidentPermissions,
            apartmentId: member.apartmentId,
          ),
      ],
    );
  }

  @override
  Future<void> setPresidentPermissions({
    required String residenceId,
    required String memberId,
    required bool enabled,
  }) async {
    data = ResidenceMembersData(
      buildings: data.buildings,
      pendingInvitations: data.pendingInvitations,
      members: [
        for (final member in data.members)
          ResidenceMember(
            id: member.id,
            name: member.name,
            phone: member.phone,
            role: member.role,
            hasPresidentPermissions: member.id == memberId
                ? enabled
                : member.hasPresidentPermissions,
            apartmentId: member.apartmentId,
          ),
      ],
    );
  }

  @override
  Future<void> transferPresidency({
    required String residenceId,
    required String currentPresidentId,
    required String newPresidentId,
  }) async {
    data = ResidenceMembersData(
      buildings: data.buildings,
      pendingInvitations: data.pendingInvitations,
      members: [
        for (final member in data.members)
          ResidenceMember(
            id: member.id,
            name: member.name,
            phone: member.phone,
            role: member.id == currentPresidentId
                ? ResidenceMemberRole.resident
                : member.id == newPresidentId
                ? ResidenceMemberRole.president
                : member.role,
            hasPresidentPermissions:
                member.id == currentPresidentId || member.id == newPresidentId
                ? false
                : member.hasPresidentPermissions,
            apartmentId: member.apartmentId,
          ),
      ],
    );
  }
}

class _FakeResidenceInvitationRepository
    implements ResidenceInvitationRepository {
  ResidenceGroupInvitation invitation = const ResidenceGroupInvitation(
    residenceId: 'test-residence',
    joinCode: '48273165',
    joinRequestsEnabled: true,
  );

  @override
  Future<ResidenceGroupInvitation> load(String residenceId) async => invitation;

  @override
  Future<void> setJoiningEnabled(String residenceId, bool enabled) async {
    invitation = ResidenceGroupInvitation(
      residenceId: residenceId,
      joinCode: invitation.joinCode,
      joinRequestsEnabled: enabled,
    );
  }
}

class _FakeResidenceSettingsRepository implements ResidenceSettingsRepository {
  ResidenceSettings settings = const ResidenceSettings(
    residenceId: '10284736',
    joinCode: '48273165',
    name: 'إقامة الاختبار',
    address: 'شارع الاختبار',
    city: '6141010',
    establishmentYear: 2018,
    defaultSubscriptionAmount: 150,
    invitationUrl: 'https://darjar.app/join/48273165',
    joinRequestsEnabled: true,
    hasImage: false,
    buildings: [
      ResidenceBuildingConfiguration(
        id: 'main-building',
        name: 'المبنى الرئيسي',
        floorCount: 3,
      ),
    ],
    managementOrganization: 'أمين المريني',
    managementPhone: '+212600000001',
    bankName: 'البنك المغربي',
    bankAccount: '007 810 0000000000000000 00',
  );

  @override
  Future<ResidenceSettings> load(String residenceId) async => settings;

  @override
  Future<void> save(ResidenceSettings settings) async {
    this.settings = settings;
  }
}

class _FakeResidenceContextRepository implements ResidenceContextRepository {
  String? selectedResidenceId;

  @override
  Future<ResidenceContext> load(AuthUser user) async =>
      _defaultResidenceContext;

  @override
  Future<void> setActiveResidence({
    required AuthUser user,
    required String residenceId,
  }) async {
    selectedResidenceId = residenceId;
  }
}
