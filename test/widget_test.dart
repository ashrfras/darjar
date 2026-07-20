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

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'لقاء الجيران');
    await tester.enterText(fields.at(1), 'نلتقي مساء السبت في الحديقة.');
    await tester.tap(find.byKey(const Key('publish-post-button')));
    await tester.pumpAndSettle();

    expect(find.text('لقاء الجيران'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('new-maintenance-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-maintenance-page')), findsOneWidget);
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

    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('معلومات الإدارة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('management-page')), findsOneWidget);
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
