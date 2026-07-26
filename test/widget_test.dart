import 'dart:async';

import 'package:darjar/app/app.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
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
      final data = const MockResidenceMembersRepository().getData();
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

    test('residence settings mock persists management changes', () {
      final repository = MockResidenceSettingsRepository();
      final original = repository.getSettings();

      repository.saveSettings(
        original.copyWith(
          defaultSubscriptionAmount: 450,
          joinRequestsEnabled: false,
        ),
      );

      expect(repository.getSettings().defaultSubscriptionAmount, 450);
      expect(repository.getSettings().joinRequestsEnabled, isFalse);
      expect(original.residenceId, matches(RegExp(r'^\d+$')));
      expect(repository.getSettings().residenceId, original.residenceId);
      expect(repository.getSettings().invitationUrl, original.invitationUrl);
      expect(repository.getSettings().buildings.single.floorCount, 3);
      expect(repository.getSettings().managementOrganization, isNotEmpty);
      expect(repository.getSettings().bankAccount, isNotEmpty);
    });
  });

  group('authentication foundation', () {
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

  testWidgets('resident can verify a phone that has no residence', (
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
    expect(find.byKey(const Key('join-phone-field')), findsOneWidget);
    expect(find.text('سيتم إرسال رمز تحقق إلى رقم هاتفك.'), findsOneWidget);
    expect(find.byKey(const Key('verification-code-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('join-phone-field')),
      '0612345678',
    );
    await tester.enterText(
      find.byKey(const Key('verification-code-field')),
      '1234',
    );
    await tester.ensureVisible(find.byKey(const Key('verify-phone-button')));
    await tester.tap(find.byKey(const Key('verify-phone-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('residence-not-found')), findsOneWidget);
    expect(find.text('هذا الرقم غير مسجل في أي إقامة'), findsOneWidget);
    expect(
      find.text(
        'إذا كنت قد حصلت على رابط دعوة، فيرجى الضغط عليه للانضمام إلى الإقامة.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('medium and expanded shells remain available', (tester) async {
    await _pumpApp(tester, size: const Size(800, 1000));
    await _enterResidence(tester);
    expect(find.byKey(const Key('medium-shell')), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expanded-shell')), findsOneWidget);
    expect(find.text('إقامة الياسمين'), findsWidgets);
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

  testWidgets('profile settings expose Arabic notification preferences', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-page')), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('+212 6 12 34 56 78'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsNothing);
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

    await tester.ensureVisible(find.byKey(const Key('settings-link')));
    await tester.tap(find.byKey(const Key('settings-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    expect(find.text('الإعدادات العامة'), findsOneWidget);
    expect(find.byKey(const Key('general-settings-section')), findsOneWidget);
    expect(find.text('اللغة'), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('الإعدادات الاحترافية'), findsOneWidget);
    expect(
      find.text(
        'من أجل إدارة إقامات متعددة، يرجى التبديل إلى الحساب الاحترافي.',
      ),
      findsOneWidget,
    );
    final professionalButton = find.byKey(
      const Key('switch-to-professional-button'),
    );
    expect(professionalButton, findsOneWidget);
    await tester.ensureVisible(professionalButton);
    await tester.tap(professionalButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-page')), findsOneWidget);
  });

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
      greaterThan(tester.getTopLeft(find.byKey(const Key('settings-link'))).dy),
    );
    expect(find.text('إدارة الإقامة'), findsOneWidget);
    expect(
      find.text('إدارة الشقق، إدارة السكان، تعيين الصلاحيات'),
      findsOneWidget,
    );
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
    expect(chevrons, findsNWidgets(4));
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
      await _pumpApp(tester, size: const Size(390, 844));
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
        matches(RegExp(r'^\d+$')),
      );
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
        'management-office-hours-field',
        'management-bank-name-field',
        'management-bank-account-field',
      ]) {
        expect(find.byKey(Key(fieldKey)), findsOneWidget);
      }
      expect(
        find.byKey(const Key('residence-subscription-section')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sticky-save-bar')), findsOneWidget);
      expect(
        find.byKey(const Key('save-residence-settings-button')).hitTestable(),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('establishment-year-field')),
        '20ab25',
      );
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

      await tester.ensureVisible(find.byKey(const Key('add-building-button')));
      await tester.tap(find.byKey(const Key('add-building-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('building-editor-dialog')), findsOneWidget);
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

      await tester.tap(
        find.byKey(const Key('save-residence-settings-button')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('تم حفظ إعدادات الإقامة.'), findsOneWidget);
    },
  );

  testWidgets('internal component gallery remains navigable', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 844));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('gallery-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('component-gallery')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
  });

  testWidgets('apartments and residents support daily assignments and roles', (
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
    await tester.enterText(
      find.byKey(const Key('new-apartment-number-field')),
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
      const ValueKey('apartment-apartment-ground-floor-03'),
    );
    expect(addedApartment, findsOneWidget);

    final deleteAddedApartment = find.byKey(
      const ValueKey('delete-apartment-apartment-ground-floor-03'),
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
    await tester.tap(find.text('نائب').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('resident-member-karim')),
        matching: find.text('نائب'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('residents use international phones and group invitations', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
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

    expect(find.text('مريم المنصوري'), findsOneWidget);
    expect(find.text('+212 6 98 76 54 32'), findsOneWidget);

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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = authRepository ?? _FakeAuthRepository();
  if (repository is _FakeAuthRepository) {
    addTearDown(repository.dispose);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const DarJarApp(),
    ),
  );
  await tester.pumpAndSettle();
}

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
  expect(find.byKey(const Key('country-code-field')), findsOneWidget);
  expect(find.text('+212'), findsOneWidget);
  expect(find.byKey(const Key('resident-phone-field')), findsOneWidget);
  expect(find.byKey(const Key('resident-first-name-field')), findsOneWidget);
  expect(find.byKey(const Key('resident-last-name-field')), findsOneWidget);

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
