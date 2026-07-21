import 'package:darjar/app/app.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
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
  });

  group('mock repositories', () {
    test(
      'create community posts, recommendations, and maintenance requests',
      () {
        final community = MockCommunityRepository();
        final directory = MockDirectoryRepository();
        final residence = MockResidenceRepository();

        community.createPost(title: 'عنوان', body: 'تفاصيل');
        directory.recommend(id: 'mohamed-electrician', comment: 'خدمة ممتازة');
        residence.createMaintenanceRequest(
          title: 'عطل جديد',
          location: 'المدخل',
        );

        expect(community.getPosts().first.title, 'عنوان');
        expect(
          directory.getEntry('mohamed-electrician')!.reviews.first.comment,
          'خدمة ممتازة',
        );
        expect(residence.getMaintenanceRequests().first.title, 'عطل جديد');
      },
    );

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
      expect(dashboard.maintenanceCompleted, greaterThan(0));
      expect(dashboard.extraordinaryExpense.progress, inInclusiveRange(0, 1));
      expect(dashboard.notifications, isNotEmpty);
      expect(dashboard.documents, isNotEmpty);
      expect(dashboard.unitCount, greaterThan(0));
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

  testWidgets('compact header keeps identity right and actions left', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    final brand = find.byKey(const Key('compact-brand'));
    final residence = find.byKey(const Key('compact-residence'));
    final notification = find.byKey(const Key('gallery-button'));
    final profile = find.byKey(const Key('profile-button'));

    expect(tester.getCenter(brand).dx, greaterThan(195));
    expect(tester.getCenter(residence).dx, greaterThan(195));
    expect(tester.getCenter(notification).dx, lessThan(195));
    expect(tester.getCenter(profile).dx, lessThan(195));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final notificationButton = tester.widget<IconButton>(notification);
    expect(appBar.toolbarHeight, 58);
    expect(notificationButton.iconSize, 21);

    final filter = find.byKey(const ValueKey('community-filter-all'));
    final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(tester.getTopLeft(filter).dy - appBarBottom, 12);
  });

  testWidgets('resident can choose the invitation-based join flow', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));

    await tester.ensureVisible(find.byKey(const Key('start-button')));
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الانضمام إلى إقامة'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join-residence-form')), findsOneWidget);
    await tester.ensureVisible(find.text('الانضمام والمتابعة'));
    await tester.tap(find.text('الانضمام والمتابعة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
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

  testWidgets('residence exposes maintenance, dues, and management routes', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);

    await tester.tap(find.text('طلبات الصيانة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('maintenance-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-maintenance-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-maintenance-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'تسرب ماء');
    await tester.enterText(fields.at(1), 'الطابق الثاني');
    await tester.ensureVisible(
      find.byKey(const Key('submit-maintenance-button')),
    );
    await tester.tap(find.byKey(const Key('submit-maintenance-button')));
    await tester.pumpAndSettle();
    expect(find.text('تسرب ماء'), findsOneWidget);

    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حالة الواجبات'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dues-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);

    await tester.ensureVisible(find.text('معلومات الإدارة'));
    await tester.tap(find.text('معلومات الإدارة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('management-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
  });

  testWidgets('residence dashboard exposes its six resident modules', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 1100));
    await _enterResidence(tester);
    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();

    for (final section in [
      'المالية',
      'طلبات الصيانة',
      'المصاريف الاستثنائية',
      'الوثائق',
      'الإشعارات الإدارية',
      'معلومات الإدارة',
    ]) {
      expect(find.text(section), findsOneWidget);
    }
  });

  testWidgets('profile settings can switch the app to English', (tester) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('internal component gallery remains navigable', (tester) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('gallery-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('component-gallery')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
  });

  testWidgets('English onboarding is structurally supported', (tester) async {
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
    );

    expect(find.text('Apartment living, all in one place'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.ltr,
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
  Locale? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(ProviderScope(child: DarJarApp(locale: locale)));
  await tester.pumpAndSettle();
}

Future<void> _enterResidence(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('start-button')));
  await tester.tap(find.byKey(const Key('start-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('residence-setup-page')), findsOneWidget);

  await tester.ensureVisible(find.byKey(const Key('enter-residence-button')));
  await tester.tap(find.byKey(const Key('enter-residence-button')));
  await tester.pumpAndSettle();
}
