import 'dart:async';

import 'package:darjar/app/app.dart';
import 'package:darjar/app/bootstrap.dart';
import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/images/app_image_processing.dart';
import 'package:darjar/core/images/storage_image_provider.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/core/widgets/darjar_country_code_picker.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:darjar/features/directory/presentation/service_category_icon.dart';
import 'package:darjar/features/directory/presentation/service_phone_launcher.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/documents/presentation/residence_document_picker.dart';
import 'package:darjar/features/documents/presentation/residence_documents_management_page.dart';
import 'package:darjar/features/notifications/data/notification_push_service.dart';
import 'package:darjar/features/notifications/data/notifications_repository.dart';
import 'package:darjar/features/onboarding/presentation/onboarding_page.dart';
import 'package:darjar/features/profile/data/profile_repository.dart';
import 'package:darjar/features/profile/data/app_package_info.dart';
import 'package:darjar/features/profile/presentation/delete_account_page.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/data/residence_important_notifications.dart';
import 'package:darjar/features/residence/data/residence_invitation_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as test_image;

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
      expect(AppTheme.light.dialogTheme.backgroundColor, AppColors.surface);
      expect(AppTheme.light.dialogTheme.surfaceTintColor, Colors.transparent);
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

    testWidgets('profile images preserve aspect ratio and crop to the avatar', (
      tester,
    ) async {
      final source = test_image.Image(width: 120, height: 60);
      final bytes = Uint8List.fromList(test_image.encodeJpg(source));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageImageBytesProvider.overrideWith(
              (ref, storagePath) async => bytes,
            ),
          ],
          child: const MaterialApp(
            home: Center(
              child: DarJarUserAvatar(userId: 'profile-user', radius: 30),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileImage = tester.widget<Image>(find.byType(Image));
      expect(profileImage.width, 60);
      expect(profileImage.height, 60);
      expect(profileImage.fit, BoxFit.cover);
      expect(profileImage.alignment, Alignment.center);
      final resizedImage = profileImage.image as ResizeImage;
      expect(resizedImage.width, 120);
      expect(resizedImage.height, isNull);
      expect(find.byType(ClipOval), findsOneWidget);
    });
  });

  group('application bootstrap', () {
    testWidgets('shows progress before initialization completes', (
      tester,
    ) async {
      final initialization = Completer<void>();

      await tester.pumpWidget(
        DarJarBootstrap(
          initialize: () => initialization.future,
          child: const SizedBox(key: Key('initialized-app')),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('bootstrap-loading')), findsOneWidget);
      expect(find.byKey(const Key('bootstrap-logo')), findsOneWidget);
      expect(find.byKey(const Key('bootstrap-progress-bar')), findsOneWidget);
      expect(find.text('دارجار'), findsNothing);
      expect(find.text('جارٍ تجهيز التطبيق…'), findsNothing);
      expect(find.byKey(const Key('initialized-app')), findsNothing);

      initialization.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('initialized-app')), findsOneWidget);
    });

    testWidgets('offers a retry when initialization fails', (tester) async {
      var attempts = 0;

      await tester.pumpWidget(
        DarJarBootstrap(
          initialize: () async {
            attempts++;
            if (attempts == 1) throw StateError('offline');
          },
          child: const SizedBox(key: Key('initialized-app')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bootstrap-load-error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('bootstrap-retry-button')));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.byKey(const Key('initialized-app')), findsOneWidget);
    });
  });

  group('public web routes', () {
    testWidgets('privacy opens directly without authentication', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        initialLocation: null,
        platformInitialLocation: AppRoutes.publicPrivacyPolicy,
        authRepository: _FakeAuthRepository(signedIn: false),
      );

      expect(find.byKey(const Key('public-privacy-page')), findsOneWidget);
      expect(find.byKey(const Key('privacy-policy-content')), findsOneWidget);
      expect(find.text('البيانات التي نجمعها'), findsOneWidget);
      expect(find.textContaining('support@raqmain.ma'), findsOneWidget);
      expect(find.byKey(const Key('phone-auth-page')), findsNothing);
      expect(find.byKey(const Key('onboarding-page')), findsNothing);
      expect(find.byKey(const Key('subpage-back-button')), findsNothing);
      expect(find.byKey(const Key('public-legal-brand')), findsOneWidget);
      expect(find.byKey(const Key('public-legal-back-button')), findsOneWidget);
      expect(find.byKey(const Key('landing-footer')), findsOneWidget);
    });

    testWidgets('account deletion opens directly without authentication', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        initialLocation: null,
        platformInitialLocation: AppRoutes.deleteAccount,
        authRepository: _FakeAuthRepository(signedIn: false),
      );

      expect(find.byKey(const Key('delete-account-page')), findsOneWidget);
      expect(find.byKey(const Key('delete-account-content')), findsOneWidget);
      expect(find.textContaining(accountDeletionRequestEmail), findsOneWidget);
      expect(
        find.byKey(const Key('send-delete-account-request')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('phone-auth-page')), findsNothing);
      expect(find.byKey(const Key('onboarding-page')), findsNothing);
      expect(find.byKey(const Key('public-legal-brand')), findsOneWidget);
      expect(find.byKey(const Key('public-legal-back-button')), findsOneWidget);
      expect(find.byKey(const Key('landing-footer')), findsOneWidget);
    });
  });

  group('mock repositories', () {
    test('residence members are ordered by role importance then name', () {
      const members = [
        ResidenceMember(
          id: 'resident',
          name: 'زياد السالمي',
          phone: '',
          role: ResidenceMemberRole.resident,
        ),
        ResidenceMember(
          id: 'treasurer',
          name: 'أمينة الكتاني',
          phone: '',
          role: ResidenceMemberRole.treasurer,
        ),
        ResidenceMember(
          id: 'president',
          name: 'يوسف العلوي',
          phone: '',
          role: ResidenceMemberRole.president,
        ),
        ResidenceMember(
          id: 'deputy',
          name: 'سلمى المريني',
          phone: '',
          role: ResidenceMemberRole.deputy,
        ),
      ];

      final sorted = [...members]..sort(compareResidenceMembersByRole);

      expect(sorted.map((member) => member.id), [
        'president',
        'deputy',
        'treasurer',
        'resident',
      ]);
    });

    test('notifications are residence-scoped and persist read state', () async {
      final repository = MockNotificationsRepository(
        seed: [
          DarJarNotification(
            id: 'visible',
            residenceId: 'residence-a',
            recipientUserId: 'user-a',
            type: DarJarNotificationType.postCreated,
            occurredAt: DateTime(2026, 7, 30),
            targetId: 'post-a',
            actorName: 'أمينة',
          ),
          DarJarNotification(
            id: 'other-residence',
            residenceId: 'residence-b',
            recipientUserId: 'user-a',
            type: DarJarNotificationType.budgetChanged,
            occurredAt: DateTime(2026, 7, 29),
            targetId: '',
          ),
        ],
      );
      addTearDown(repository.dispose);

      final initial = await repository
          .watch(residenceId: 'residence-a', userId: 'user-a')
          .first;
      expect(initial.map((notification) => notification.id), ['visible']);
      expect(initial.single.isRead, isFalse);

      await repository.markRead('visible');
      final updated = await repository
          .watch(residenceId: 'residence-a', userId: 'user-a')
          .first;
      expect(updated.single.isRead, isTrue);
    });

    test('interaction and payment notifications open their relevant pages', () {
      DarJarNotification notification(DarJarNotificationType type) {
        return DarJarNotification(
          id: type.name,
          residenceId: 'residence-a',
          recipientUserId: 'user-a',
          type: type,
          occurredAt: DateTime(2026, 8, 2),
          targetId: type == DarJarNotificationType.duesMarkedPaid
              ? '2026-08_apartment-a'
              : 'post-a',
        );
      }

      expect(
        notificationRoute(notification(DarJarNotificationType.postLiked)),
        AppRoutes.communityPost('post-a'),
      );
      expect(
        notificationRoute(notification(DarJarNotificationType.postCommented)),
        AppRoutes.communityPost('post-a'),
      );
      expect(
        notificationRoute(notification(DarJarNotificationType.duesMarkedPaid)),
        AppRoutes.dues,
      );
    });

    test('dues overview exposes debit, credit, and grouped payment totals', () {
      final now = DateTime.now();
      final currentPeriod = residenceDuesPeriodKey(now);
      final nextPeriod = residenceDuesPeriodKey(
        DateTime(now.year, now.month + 1),
      );
      final paidAt = DateTime(now.year, now.month, 10);
      final overview = ResidenceDuesOverview(
        dues: [
          ResidenceDue(
            id: '${currentPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            periodKey: currentPeriod,
            amountDue: 150,
            amountPaid: 100,
            status: ResidenceDueStatus.partial,
          ),
          ResidenceDue(
            id: '${nextPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            periodKey: nextPeriod,
            amountDue: 150,
            amountPaid: 150,
            status: ResidenceDueStatus.paid,
          ),
        ],
        payments: [
          ResidenceDuePayment(
            id: 'payment-2',
            dueId: '${nextPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            amount: 150,
            paidAt: paidAt,
            note: '',
            recordedBy: 'test-user',
            createdAt: paidAt,
          ),
          ResidenceDuePayment(
            id: 'payment-1',
            dueId: '${currentPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            amount: 100,
            paidAt: paidAt,
            note: '',
            recordedBy: 'test-user',
            createdAt: paidAt,
          ),
        ],
      );

      expect(overview.debitThroughPeriod(currentPeriod), 50);
      expect(overview.creditAfterPeriod(currentPeriod), 150);
      expect(overview.prepaidDuesAfterPeriod(currentPeriod), hasLength(1));
      expect(overview.paymentGroups.single.totalAmount, 250);
    });

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

    test('create community posts and directory services', () async {
      final community = MockCommunityRepository();
      final directory = _TestDirectoryRepository();

      await community.createPost(content: 'عنوان وتفاصيل');
      await directory.createService(
        residenceId: 'test-residence',
        userId: 'test-user',
        name: 'خدمة جديدة',
        categoryId: 'home-maintenance',
        subcategoryIds: const ['electrician'],
        profession: 'إصلاح الأعطال',
        phone: '+212612345678',
        neighborhood: 'المعاريف',
      );

      expect(community.getPosts().first.content, 'عنوان وتفاصيل');
      expect(directory.entries.first.name, 'خدمة جديدة');
      await directory.dispose();
    });

    test('directory exposes only services from the selected city', () async {
      final directory = _TestDirectoryRepository();
      directory.entries.add(
        const DirectoryEntry(
          id: 'rabat-service',
          name: 'خدمة الرباط',
          categoryId: 'cleaning-care',
          subcategoryIds: ['home-cleaning'],
          profession: 'تنظيف المنازل',
          phone: '+212612345679',
          score: 0,
          recommendationCount: 0,
          localRecommendationCount: 0,
          workedResidences: [],
          reviews: [],
          city: '4010100',
        ),
      );

      final casablancaServices = await directory
          .watchEntries(city: '6141010', limit: 20)
          .first;

      expect(casablancaServices.map((entry) => entry.id), [
        'mohamed-electrician',
      ]);
      await directory.dispose();
    });

    test('equipment category uses a devices icon', () {
      expect(
        serviceCategoryIcon('appliances-equipment'),
        Icons.devices_other_rounded,
      );
    });

    test(
      'community mock supports every post type and local interactions',
      () async {
        final community = MockCommunityRepository();

        expect(
          community.getPosts().map((post) => post.kind).toSet(),
          containsAll(CommunityPostKind.values),
        );

        final post = community.getPost('poll-garden')!;
        final votesBefore = post.pollOptions.first.votes;
        await community.vote(
          postId: post.id,
          optionId: post.pollOptions.first.id,
        );
        await community.toggleLike(postId: post.id);
        await community.toggleSaved(postId: post.id);
        await community.addComment(postId: post.id, body: 'سأشارك بالتأكيد');

        final updated = community.getPost(post.id)!;
        expect(updated.selectedPollOptionId, post.pollOptions.first.id);
        expect(updated.pollOptions.first.votes, votesBefore + 1);
        expect(updated.isLiked, isTrue);
        expect(updated.isSaved, isTrue);
        expect(updated.comments.last.body, 'سأشارك بالتأكيد');

        final createdId = await community.createPost(
          content: 'صور الإقامة: أربع صور كحد أقصى',
          imagePaths: const ['1', '2', '3', '4', '5'],
        );
        final created = community.getPost(createdId)!;
        expect(created.imagePaths, hasLength(4));
      },
    );

    test('people names abbreviate the family name in Arabic', () {
      expect(abbreviatedPersonName('محمد العيساوي'), 'محمد ع.');
      expect(abbreviatedPersonName('أشرف راس'), 'أشرف ر.');
      expect(abbreviatedPersonName('كريم المنيعي'), 'كريم م.');
      expect(abbreviatedPersonName('أحمد'), 'أحمد');
    });

    test(
      'community feed repository respects the requested page size',
      () async {
        final community = MockCommunityRepository();

        final posts = await community
            .watchPosts(residenceId: 'residence', userId: 'resident', limit: 3)
            .first;

        expect(posts, hasLength(3));
      },
    );

    test('community images are resized and converted for efficient upload', () {
      final source = test_image.Image(width: 2400, height: 1800);
      test_image.fill(source, color: test_image.ColorRgb8(34, 139, 94));
      final compressed = compressCommunityImageBytes(
        test_image.encodePng(source),
      );
      final decoded = test_image.decodeJpg(compressed)!;

      expect(decoded.width, lessThanOrEqualTo(communityImageMaxDimension));
      expect(decoded.height, lessThanOrEqualTo(communityImageMaxDimension));
      expect(
        compressed.lengthInBytes,
        lessThan(communityImageMaxStoredSizeBytes),
      );
    });

    test('profile and residence images use compact display dimensions', () {
      final source = test_image.Image(width: 2200, height: 1600);
      test_image.fill(source, color: test_image.ColorRgb8(34, 139, 94));

      final compressed = compressDisplayImageBytes(
        test_image.encodePng(source),
      );
      final decoded = test_image.decodeJpg(compressed)!;

      expect(decoded.width, lessThanOrEqualTo(displayImageMaxDimension));
      expect(decoded.height, lessThanOrEqualTo(displayImageMaxDimension));
      expect(
        compressed.lengthInBytes,
        lessThan(displayImageMaxStoredSizeBytes),
      );
    });

    test('residence dashboard mock covers every dashboard section', () {
      final dashboard = MockResidenceRepository().getDashboardData();

      expect(dashboard.monthlyDue, greaterThan(0));
    });

    test('residence document types are normalized from safe extensions', () {
      expect(
        residenceDocumentContentType('rules.PDF', null),
        'application/pdf',
      );
      expect(
        residenceDocumentContentType('photo.jpeg', 'image/jpeg'),
        'image/jpeg',
      );
      expect(residenceDocumentContentType('archive.zip', null), isEmpty);
      expect(residenceDocumentMaxSizeBytes, 15 * 1024 * 1024);
    });

    test('transaction attachments use stable low-collision numeric names', () {
      final name = residenceTransactionAttachmentName('transaction-1284');

      expect(name, matches(RegExp(r'^مرفق-[0-9]{12}$')));
      expect(residenceTransactionAttachmentName('transaction-1284'), name);
      expect(
        residenceTransactionAttachmentName('transaction-11284'),
        isNot(name),
      );
      expect(name, isNot(contains('transaction')));
    });

    test(
      'important residence notifications are derived and limited to three',
      () {
        final notifications = deriveImportantResidenceNotifications(
          now: DateTime(2026, 7, 29),
          joinedAt: DateTime(2026, 4, 15),
          duesOverview: ResidenceDuesOverview(
            dues: const [
              ResidenceDue(
                id: '2026-05_apartment-01',
                apartmentId: 'apartment-01',
                apartmentNumber: '01',
                periodKey: '2026-05',
                amountDue: 150,
                amountPaid: 150,
                status: ResidenceDueStatus.paid,
              ),
              ResidenceDue(
                id: '2026-04_apartment-01',
                apartmentId: 'apartment-01',
                apartmentNumber: '01',
                periodKey: '2026-04',
                amountDue: 150,
                amountPaid: 0,
                status: ResidenceDueStatus.unpaid,
              ),
              ResidenceDue(
                id: '2026-03_apartment-01',
                apartmentId: 'apartment-01',
                apartmentNumber: '01',
                periodKey: '2026-03',
                amountDue: 150,
                amountPaid: 0,
                status: ResidenceDueStatus.unpaid,
              ),
            ],
            payments: [
              ResidenceDuePayment(
                id: 'payment-01',
                dueId: '2026-05_apartment-01',
                apartmentId: 'apartment-01',
                apartmentNumber: '01',
                amount: 150,
                paidAt: DateTime(2026, 6, 10),
                note: '',
                recordedBy: 'president',
              ),
            ],
          ),
        );

        expect(notifications, hasLength(3));
        expect(notifications.map((notification) => notification.kind), [
          ImportantResidenceNotificationKind.paymentRecorded,
          ImportantResidenceNotificationKind.overdueDues,
          ImportantResidenceNotificationKind.membershipApproved,
        ]);
      },
    );

    test('membership approval is always an important notification', () {
      final notifications = deriveImportantResidenceNotifications(
        now: DateTime(2026, 7, 29),
        joinedAt: null,
        duesOverview: ResidenceDuesOverview.empty,
      );

      expect(notifications, hasLength(1));
      expect(
        notifications.single.kind,
        ImportantResidenceNotificationKind.membershipApproved,
      );
    });

    test('residence finances derive annual totals and all-time balance', () {
      final finances = ResidenceFinances.fromTransactions(
        now: DateTime(2026, 7),
        paidResidents: 1,
        totalResidents: 2,
        transactions: [
          ResidenceTransaction(
            id: 'current-income',
            type: ResidenceTransactionType.income,
            amount: 100,
            date: DateTime(2026, 7, 1),
            name: 'مدخول',
            source: ResidenceTransactionSource.manual,
          ),
          ResidenceTransaction(
            id: 'maintenance',
            type: ResidenceTransactionType.expense,
            amount: 40,
            date: DateTime(2026, 7, 2),
            name: 'صيانة',
            source: ResidenceTransactionSource.manual,
            expenseCategory: ResidenceExpenseCategory.maintenance,
          ),
          ResidenceTransaction(
            id: 'custom-expense',
            type: ResidenceTransactionType.expense,
            amount: 10,
            date: DateTime(2026, 7, 3),
            name: 'مصروف خاص',
            source: ResidenceTransactionSource.manual,
            expenseCategory: ResidenceExpenseCategory.custom,
          ),
          ResidenceTransaction(
            id: 'previous-income',
            type: ResidenceTransactionType.income,
            amount: 200,
            date: DateTime(2025, 12, 1),
            name: 'مدخول سابق',
            source: ResidenceTransactionSource.manual,
          ),
        ],
      );

      expect(finances.totalIncome, 100);
      expect(finances.totalExpenses, 50);
      expect(finances.currentBalance, 250);
      expect(finances.collectionRate, .5);
      expect(finances.breakdown, hasLength(2));
      expect(finances.recentExpenses, hasLength(2));
    });

    test('opening balance affects balance without becoming income', () {
      final finances = ResidenceFinances.fromTransactions(
        now: DateTime(2026, 8, 6),
        paidResidents: 0,
        totalResidents: 0,
        transactions: [
          ResidenceTransaction(
            id: 'opening-balance',
            type: ResidenceTransactionType.income,
            amount: 1000,
            date: DateTime(2026, 8, 1),
            name: 'openingBalance',
            source: ResidenceTransactionSource.openingBalance,
          ),
          ResidenceTransaction(
            id: 'income',
            type: ResidenceTransactionType.income,
            amount: 150,
            date: DateTime(2026, 8, 2),
            name: 'مدخول',
            source: ResidenceTransactionSource.manual,
          ),
        ],
      );

      expect(finances.hasOpeningBalance, isTrue);
      expect(finances.totalIncome, 150);
      expect(finances.currentBalance, 1150);
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
    test('limits simulated authentication to web loopback hosts', () {
      expect(
        isLocalhostAuthSimulation(
          isWeb: true,
          uri: Uri.parse('http://localhost:8080/auth/phone'),
        ),
        isTrue,
      );
      expect(
        isLocalhostAuthSimulation(
          isWeb: true,
          uri: Uri.parse('http://127.0.0.1:8080/auth/phone'),
        ),
        isTrue,
      );
      expect(
        isLocalhostAuthSimulation(
          isWeb: true,
          uri: Uri.parse('http://[::1]:8080/auth/phone'),
        ),
        isTrue,
      );
      expect(
        isLocalhostAuthSimulation(
          isWeb: true,
          uri: Uri.parse('https://localhost.example.com/auth/phone'),
        ),
        isFalse,
      );
      expect(
        isLocalhostAuthSimulation(
          isWeb: false,
          uri: Uri.parse('http://localhost:8080/auth/phone'),
        ),
        isFalse,
      );
      expect(
        isLocalhostAuthSimulation(
          isWeb: true,
          uri: Uri.parse('http://localhost:8080/auth/phone'),
          enabled: false,
        ),
        isFalse,
      );
    });

    test('localhost repository authenticates without the SMS API', () async {
      final container = ProviderContainer(
        overrides: [
          localhostAuthSimulationProvider.overrideWithValue(true),
          phoneVerificationApiProvider.overrideWith(
            (ref) => throw StateError('SMS API must not be created'),
          ),
          firebaseAuthProvider.overrideWith(
            (ref) => throw StateError('Firebase Auth must not be created'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(authRepositoryProvider);
      expect(repository, isA<LocalhostAuthRepository>());

      await repository.sendVerificationCode('+2121', languageCode: 'ar');
      await repository.confirmVerificationCode('7');

      expect(repository.currentUser?.phoneNumber, '+2121');
      expect(repository.currentUser?.uid, 'localhost-2121');
    });

    test('local real authentication is limited to the dedicated phone', () {
      expect(localDevelopmentPhoneNumber, '+212708708001');
      expect(isLoopbackUri(Uri.parse('http://localhost:8080')), isTrue);
      expect(isLoopbackUri(Uri.parse('https://darjar.app')), isFalse);
    });

    test('normalizes equivalent international phone formats', () {
      expect(normalizePhoneNumber('+212 6 12-34-56-78'), '+212612345678');
      expect(normalizePhoneNumber('00212 6 12 34 56 78'), '+212612345678');
    });

    test('formats phone numbers with a parenthesized country code', () {
      expect(
        formatPhoneNumberForDisplay('+212 6 01 19 13 22'),
        '(212)601191322',
      );
      expect(formatPhoneNumberForDisplay('06 01 19 13 22'), '(212)601191322');
      expect(formatPhoneNumberForDisplay('+33 6 12 34 56 78'), '(33)612345678');
    });

    test('splits and rebuilds international phone numbers', () {
      expect(splitInternationalPhoneNumber('+212 6 00 00 00 01'), (
        countryCode: '+212',
        nationalNumber: '600000001',
      ));
      expect(splitInternationalPhoneNumber('+33 6 12 34 56 78'), (
        countryCode: '+33',
        nationalNumber: '612345678',
      ));
      expect(
        formatInternationalPhoneNumber('+212', '5 22 11 22 33'),
        '+212 5 22 11 22 33',
      );
      expect(splitInternationalPhoneNumber('+353 87 123 4567'), (
        countryCode: '+353',
        nationalNumber: '871234567',
      ));
    });

    test('offers prominent Arab, European, and North American codes', () {
      expect(supportedCountries.length, greaterThanOrEqualTo(30));
      expect(
        supportedCountries.map((country) => country.code).toSet(),
        hasLength(supportedCountries.length),
      );
      expect(
        supportedCountryCallingCodes.toSet(),
        supportedCountries.map((country) => country.code).toSet(),
      );
      expect(
        supportedCountryCallingCodes,
        containsAll(<String>[
          '+212',
          '+966',
          '+971',
          '+33',
          '+44',
          '+49',
          '+1',
        ]),
      );
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
      expect(find.byKey(const Key('phone-auth-brand')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('phone-auth-brand')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(
        tester.getCenter(find.text('+212')).dx,
        lessThan(
          tester.getCenter(find.byKey(const Key('auth-phone-field'))).dx,
        ),
      );
      expect(find.byKey(const Key('auth-country-code-field')), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth-country-code-field')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('country-code-picker-sheet')),
        findsOneWidget,
      );
      expect(find.text('المغرب'), findsOneWidget);
      expect(find.text('الدول العربية'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const Key('country-code-picker-sheet')))
            .height,
        480,
      );
      await tester.scrollUntilVisible(
        find.text('فرنسا'),
        300,
        scrollable: find.descendant(
          of: find.byKey(const Key('country-code-options')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('فرنسا'), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('country-code-picker-sheet')), findsNothing);
      await tester.tap(find.byKey(const Key('auth-country-code-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('country-code-option-+212')));
      await tester.pumpAndSettle();

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
      expect(authRepository.requestedLanguageCode, 'ar');
      expect(find.textContaining('(212)600000001'), findsOneWidget);
      final codeDescription = tester.widget<Text>(
        find.byKey(const Key('auth-step-description')),
      );
      expect(codeDescription.data, contains('\u2066(212)600000001\u2069'));
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

    testWidgets('phone auth exposes safe verification diagnostics', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(
        signedIn: false,
        sendFailure: const AuthFailure(
          'unknown',
          message:
              'An unknown error occurred for +212600000001: '
              'ProviderError (verification/billing-not-enabled).',
        ),
      );
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        authRepository: authRepository,
      );

      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('auth-phone-field')),
        '0600000001',
      );
      await tester.tap(find.byKey(const Key('send-verification-code-button')));
      await tester.pumpAndSettle();

      final details = tester.widget<SelectableText>(
        find.byKey(const Key('auth-error-technical-details')),
      );
      expect(details.data, contains('Verification code: unknown'));
      expect(details.data, contains('verification/billing-not-enabled'));
      expect(details.data, contains('[phone redacted]'));
      expect(details.data, isNot(contains('+212600000001')));
    });

    testWidgets('phone auth enables resending after a visible countdown', (
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
      await tester.enterText(
        find.byKey(const Key('auth-phone-field')),
        '0600000001',
      );
      await tester.tap(find.byKey(const Key('send-verification-code-button')));
      await tester.pump();

      final resendButton = find.byKey(
        const Key('resend-verification-code-button'),
      );
      expect(find.text('إعادة إرسال الرمز بعد 60 ثانية'), findsOneWidget);
      expect(tester.widget<DarJarButton>(resendButton).onPressed, isNull);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('إعادة إرسال الرمز بعد 30 ثانية'), findsOneWidget);
      expect(tester.widget<DarJarButton>(resendButton).onPressed, isNull);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('إعادة إرسال الرمز'), findsOneWidget);
      expect(tester.widget<DarJarButton>(resendButton).onPressed, isNotNull);

      await tester.tap(resendButton);
      await tester.pump();
      expect(authRepository.sendVerificationCodeCallCount, 2);
      expect(find.text('إعادة إرسال الرمز بعد 60 ثانية'), findsOneWidget);
    });

    testWidgets('localhost auth accepts any non-empty phone and code', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(signedIn: false);
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        authRepository: authRepository,
        localhostAuthSimulation: true,
      );

      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('auth-phone-field')), '1');
      await tester.tap(find.byKey(const Key('send-verification-code-button')));
      await tester.pumpAndSettle();

      expect(authRepository.requestedPhoneNumber, '+2121');
      expect(
        find.byKey(const Key('auth-verification-code-field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('auth-verification-code-field')),
        '7local-test',
      );
      await tester.tap(
        find.byKey(const Key('confirm-verification-code-button')),
      );
      await tester.pumpAndSettle();

      expect(authRepository.confirmedCode, '7');
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
      expect(find.byKey(const Key('account-resolution-brand')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('account-resolution-brand')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(find.text('أمينة المريني'), findsOneWidget);
      expect(find.text('(212)600000001'), findsOneWidget);
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
          apartments: [
            ResidenceJoinApartment(
              id: 'apartment-12',
              number: '12',
              buildingNameAr: 'العمارة الرئيسية',
              buildingNameEn: 'Main building',
              floorNameAr: 'الطابق الأول',
              floorNameEn: 'First floor',
            ),
          ],
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
      expect(find.byKey(const Key('join-first-name-field')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('join-residence-code-field')),
        '48273165',
      );
      await tester.tap(find.byKey(const Key('search-residence-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('residence-search-result')), findsOneWidget);
      expect(find.text('إقامة الياسمين'), findsOneWidget);
      expect(find.textContaining('حي المعاريف'), findsOneWidget);
      expect(find.text('لا يتم إظهار النسب للسكان الآخرين.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('join-first-name-field')),
        'أمين',
      );
      await tester.enterText(
        find.byKey(const Key('join-last-name-field')),
        'المريني',
      );
      await tester.tap(find.byKey(const Key('join-apartment-field')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('الشقة 12 · العمارة الرئيسية · الطابق الأول').last,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('join-found-residence-button')),
      );
      await tester.tap(find.byKey(const Key('join-found-residence-button')));
      await tester.pumpAndSettle();

      expect(setupRepository.requestedResidence?.code, '48273165');
      expect(setupRepository.requestedApartmentId, 'apartment-12');
      expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
    });

    testWidgets(
      'invitation link keeps the verified session and searches automatically',
      (tester) async {
        final setupRepository = _FakeResidenceSetupRepository(
          residence: const ResidenceCodeSummary(
            residenceId: 'residence-yasmine',
            code: '48273165',
            name: 'إقامة الياسمين',
            address: 'حي المعاريف',
            city: '6141010',
            joinRequestsEnabled: true,
            apartments: [
              ResidenceJoinApartment(
                id: 'apartment-12',
                number: '12',
                buildingNameAr: 'العمارة الرئيسية',
                buildingNameEn: 'Main building',
                floorNameAr: 'الطابق الأول',
                floorNameEn: 'First floor',
              ),
            ],
          ),
        );

        await _pumpApp(
          tester,
          size: const Size(390, 844),
          initialLocation: null,
          platformInitialLocation: AppRoutes.residenceInvitation('48273165'),
          useBootstrap: true,
          residenceSetupRepository: setupRepository,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('phone-auth-page')), findsNothing);
        expect(
          find.byKey(const Key('residence-search-result')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(const Key('join-residence-code-field')),
                  matching: find.byType(TextField),
                ),
              )
              .controller
              ?.text,
          '48273165',
        );
        expect(find.byKey(const Key('join-first-name-field')), findsOneWidget);
        expect(find.byKey(const Key('join-apartment-field')), findsOneWidget);
      },
    );

    testWidgets('invitation link resumes after the first phone verification', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(signedIn: false);
      final setupRepository = _FakeResidenceSetupRepository(
        residence: const ResidenceCodeSummary(
          residenceId: 'residence-yasmine',
          code: '48273165',
          name: 'إقامة الياسمين',
          address: 'حي المعاريف',
          city: '6141010',
          joinRequestsEnabled: true,
          apartments: [
            ResidenceJoinApartment(
              id: 'apartment-12',
              number: '12',
              buildingNameAr: 'العمارة الرئيسية',
              buildingNameEn: 'Main building',
              floorNameAr: 'الطابق الأول',
              floorNameEn: 'First floor',
            ),
          ],
        ),
      );

      await _pumpApp(
        tester,
        size: const Size(390, 844),
        initialLocation: AppRoutes.residenceInvitation('48273165'),
        authRepository: authRepository,
        residenceSetupRepository: setupRepository,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('phone-auth-page')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('auth-phone-field')),
        '600000001',
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

      expect(find.byKey(const Key('phone-auth-page')), findsNothing);
      expect(find.byKey(const Key('residence-search-result')), findsOneWidget);
      expect(authRepository.confirmedCode, '123456');
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

  testWidgets('Web onboarding extends the existing hero into a landing page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('ar')],
        home: const OnboardingPage(showWebLanding: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web-landing-header')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('web-landing-header'))).height,
      58,
    );
    expect(find.byType(DarJarBrand), findsNWidgets(2));
    final headerBrand = tester.widget<DarJarBrand>(
      find.descendant(
        of: find.byKey(const Key('web-landing-header')),
        matching: find.byType(DarJarBrand),
      ),
    );
    expect(headerBrand.logoSize, 31);
    expect(headerBrand.fontSize, 16);
    expect(find.text('كل ما يخص إقامتك، في مكان واحد.'), findsOneWidget);
    expect(find.byKey(const Key('landing-learn-more-button')), findsOneWidget);
    expect(find.text('تعرّف أكثر'), findsOneWidget);
    expect(find.byKey(const Key('start-button')), findsNothing);
    expect(find.byKey(const Key('landing-darjar-section')), findsOneWidget);
    expect(find.byKey(const Key('landing-finance-section')), findsOneWidget);
    expect(find.byKey(const Key('landing-community-section')), findsOneWidget);
    expect(find.byKey(const Key('landing-services-section')), findsOneWidget);
    expect(find.byKey(const Key('landing-management-section')), findsOneWidget);
    expect(find.byKey(const Key('landing-final-cta')), findsOneWidget);
    expect(find.byKey(const Key('landing-footer')), findsOneWidget);
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
    expect(find.text('حذف الحساب'), findsOneWidget);
    expect(find.textContaining('Raqmain'), findsOneWidget);
    expect(find.text('معاينة من التطبيق'), findsNothing);
    expect(
      find.byKey(const Key('landing-preview-non-interactive')),
      findsNWidgets(5),
    );
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

    await tester.ensureVisible(find.text('الدعم والتواصل'));
    await tester.tap(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support-contact-dialog')), findsOneWidget);
    expect(find.text('support@raqmain.ma'), findsOneWidget);
    expect(find.byKey(const Key('support-email-button')), findsOneWidget);
  });

  testWidgets('native onboarding does not build Web landing sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('ar')],
        home: const OnboardingPage(showWebLanding: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('كل ما يخص إقامتك، في مكان واحد.'), findsOneWidget);
    expect(find.byKey(const Key('start-button')), findsOneWidget);
    expect(find.byKey(const Key('web-landing-header')), findsNothing);
    expect(find.byKey(const Key('landing-darjar-section')), findsNothing);
    expect(find.byKey(const Key('landing-footer')), findsNothing);
  });

  testWidgets('Web landing remains scrollable on compact browser widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('ar')],
        home: const OnboardingPage(showWebLanding: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web-landing-scroll-view')), findsOneWidget);
    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);
    await tester.tap(find.byKey(const Key('landing-learn-more-button')));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    await tester.ensureVisible(find.byKey(const Key('landing-final-cta')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landing-final-start-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(tester.getTopRight(residence).dx, greaterThan(195));
    expect(tester.getCenter(notification).dx, lessThan(195));
    expect(tester.getCenter(profile).dx, lessThan(195));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final notificationButton = tester.widget<IconButton>(notification);
    expect(appBar.toolbarHeight, 58);
    expect(appBar.leadingWidth, 238);
    expect(notificationButton.iconSize, 21);
    final badgePosition = tester.widget<PositionedDirectional>(
      find.byKey(const Key('notifications-unread-badge-position')),
    );
    expect(badgePosition.top, -4);
    expect(badgePosition.end, -5);
    final bell = find.descendant(
      of: notification,
      matching: find.byIcon(Icons.notifications_none_rounded),
    );
    final badge = find.byKey(const Key('notifications-unread-badge'));
    expect(tester.getCenter(badge).dx, lessThan(tester.getCenter(bell).dx));
    expect(tester.getCenter(badge).dy, lessThan(tester.getCenter(bell).dy));
    final brandImage = tester.widget<Image>(brand);
    expect(
      (brandImage.image as AssetImage).assetName,
      'assets/images/branding/darjar-logo-header-compact.png',
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
    expect(find.text('منشور جديد'), findsOneWidget);
    expect(find.text('أضاف محمد ع. منشورًا جديدًا.'), findsOneWidget);
    expect(find.textContaining('محمد العلوي'), findsNothing);
    expect(find.text('تأخر الأداء'), findsOneWidget);
    expect(find.text('تحديث الميزانية'), findsOneWidget);
    final unreadNotification = find.byKey(
      const ValueKey('notification-mock-post-created'),
    );
    final unreadTile = tester.widget<ListTile>(
      find.descendant(of: unreadNotification, matching: find.byType(ListTile)),
    );
    expect(unreadTile.tileColor, AppColors.surface);
    final unreadDot = find.byKey(
      const ValueKey('notification-unread-mock-post-created'),
    );
    expect(unreadDot, findsOneWidget);
    final unreadAvatar = find.descendant(
      of: unreadNotification,
      matching: find.byType(CircleAvatar),
    );
    expect(
      tester.getCenter(unreadDot).dx,
      greaterThan(tester.getCenter(unreadAvatar).dx),
    );

    final filter = find.byKey(const ValueKey('community-filter-all'));
    final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(tester.getTopLeft(filter).dy - appBarBottom, 12);
  });

  testWidgets('header brand navigates back to the community', (tester) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('directory-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('brand-home-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('community-feed-page')), findsOneWidget);
    expect(
      tester
          .widget<MouseRegion>(find.byKey(const Key('brand-home-pointer')))
          .cursor,
      SystemMouseCursors.click,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('brand-home-button')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('notifications sheet shows only the five newest items', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 30, 12);
    final notificationsRepository = MockNotificationsRepository(
      seed: [
        for (var index = 0; index < 7; index++)
          DarJarNotification(
            id: 'preview-$index',
            residenceId: '*',
            recipientUserId: '*',
            type: DarJarNotificationType.postCreated,
            occurredAt: now.subtract(Duration(minutes: index)),
            targetId: 'post-$index',
            actorName: 'أشرف راس',
          ),
      ],
    );
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      notificationsRepository: notificationsRepository,
    );
    await _enterResidence(tester);

    final badge = find.descendant(
      of: find.byKey(const Key('notifications-unread-badge')),
      matching: find.text('7'),
    );
    expect(badge, findsOneWidget);

    await tester.tap(find.byKey(const Key('notifications-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('apartment-not-assigned-notification')),
      findsOneWidget,
    );

    for (var index = 0; index < 5; index++) {
      expect(
        find.byKey(ValueKey('notification-preview-$index')),
        findsOneWidget,
      );
    }
    for (var index = 5; index < 7; index++) {
      expect(find.byKey(ValueKey('notification-preview-$index')), findsNothing);
    }
  });

  testWidgets(
    'notification times respect calendar days and real elapsed time',
    (tester) async {
      final now = DateTime(2026, 8, 2, 12);
      final notificationsRepository = MockNotificationsRepository(
        seed: [
          DarJarNotification(
            id: 'today-five-hours',
            residenceId: '*',
            recipientUserId: '*',
            type: DarJarNotificationType.postCreated,
            occurredAt: DateTime(2026, 8, 2, 7),
            targetId: 'today-post',
            actorName: 'أشرف راس',
          ),
          DarJarNotification(
            id: 'yesterday-two-hours',
            residenceId: '*',
            recipientUserId: '*',
            type: DarJarNotificationType.budgetChanged,
            occurredAt: DateTime(2026, 8, 1, 23, 30),
            targetId: '',
            readAt: now,
          ),
        ],
      );
      await _pumpApp(
        tester,
        size: const Size(390, 844),
        notificationsRepository: notificationsRepository,
        notificationNow: now,
      );
      await _enterResidence(tester);

      await tester.tap(find.byKey(const Key('notifications-button')));
      await tester.pumpAndSettle();

      expect(find.text('منذ 5 س'), findsOneWidget);
      expect(find.text('أمس'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notification-unread-today-five-hours')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-unread-yesterday-two-hours')),
        findsNothing,
      );
      final readNotification = find.byKey(
        const ValueKey('notification-yesterday-two-hours'),
      );
      expect(
        tester
            .widget<ListTile>(
              find.descendant(
                of: readNotification,
                matching: find.byType(ListTile),
              ),
            )
            .tileColor,
        AppColors.surface,
      );
    },
  );

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
    expect(
      tester.widget<Title>(find.byKey(const Key('app-browser-title'))).title,
      'دارجار - إقامتك الرقمية',
    );
    expect(find.byKey(const Key('medium-shell')), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    final residenceSelectorInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('residence-selector')),
        matching: find.byType(InkWell),
      ),
    );
    expect(residenceSelectorInkWell.hoverColor, Colors.transparent);
    expect(residenceSelectorInkWell.mouseCursor, SystemMouseCursors.click);
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
    final switcher = tester.widget<DecoratedBox>(
      find.byKey(const Key('residence-switcher-sheet')),
    );
    expect((switcher.decoration as BoxDecoration).color, AppColors.surface);
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
    'resident switches residences and invitations stay outside notifications',
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
        findsNothing,
      );
      expect(find.text('منشور جديد'), findsOneWidget);
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
    final communityRepository = MockCommunityRepository()
      ..createBarrier = Completer<void>();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      communityRepository: communityRepository,
    );
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('create-post-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-post-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);
    expect(find.byKey(const Key('compact-brand')), findsOneWidget);
    expect(find.byKey(const Key('subpage-back-button')), findsOneWidget);
    expect(find.byKey(const Key('subpage-title')), findsOneWidget);
    expect(find.byKey(const Key('title-only-subpage-header')), findsOneWidget);
    expect(find.textContaining('سيظهر هذا المنشور'), findsNothing);

    final fields = find.byType(TextField);
    expect(find.byKey(const Key('post-content-field')), findsOneWidget);
    expect(fields, findsOneWidget);
    await tester.enterText(fields.at(0), 'لقاء الجيران');
    await tester.ensureVisible(find.byKey(const Key('publish-post-button')));
    await tester.tap(find.byKey(const Key('publish-post-button')));
    await tester.pump();
    expect(find.text('جارٍ نشر المنشور ورفع الصور…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    communityRepository.createBarrier!.complete();
    await tester.pumpAndSettle();

    expect(find.text('لقاء الجيران'), findsOneWidget);
    final shortContent = tester.widget<Text>(find.text('لقاء الجيران'));
    expect(shortContent.style?.fontSize, 21);
  });

  testWidgets('long community content uses a smaller post font', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    final longContent = tester.widget<Text>(
      find.byKey(const ValueKey('post-content-$communityWelcomePostId')),
    );
    expect(longContent.data, communityWelcomePost.content);
    expect(longContent.style?.fontSize, lessThan(21));
  });

  testWidgets('community filters posts and opens details with local comments', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 900));
    await _enterResidence(tester);

    expect(find.text('مجتمعك، صوتك، تفاعلك'), findsNothing);
    expect(
      find.byKey(const ValueKey('community-post-darjar-welcome')),
      findsOneWidget,
    );
    expect(find.textContaining('أهلاً بك في إقامتك الرقمية'), findsOneWidget);
    expect(find.byKey(const Key('darjar-post-avatar')), findsOneWidget);
    final welcomePost = find.byKey(
      const ValueKey('community-post-darjar-welcome'),
    );
    expect(
      find.byKey(const ValueKey('post-author-role-darjar-welcome')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: welcomePost,
        matching: find.byIcon(Icons.verified_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('فريق دارجار · مرحباً بك'), findsOneWidget);
    final presidentPost = find.byKey(
      const ValueKey('community-post-announcement-elevator'),
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('post-author-role-announcement-elevator'),
        ),
        matching: find.text('رئيس'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: presidentPost,
        matching: find.byIcon(Icons.verified_rounded),
      ),
      findsNothing,
    );
    expect(find.textContaining('المجتمع: تواصل مع جيرانك'), findsOneWidget);
    expect(
      find.textContaining('الخدمات: اعثر على مقدمي الخدمات'),
      findsOneWidget,
    );
    expect(find.textContaining('الإقامة: تابع اشتراكاتك'), findsOneWidget);
    final welcomeImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('post-images-darjar-welcome')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (welcomeImage.image as AssetImage).assetName,
      'assets/images/branding/darjar-logo.png',
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('community-post-darjar-welcome')),
          )
          .dy,
      greaterThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('community-post-general-books')),
            )
            .dy,
      ),
    );
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
    await Scrollable.ensureVisible(
      tester.element(announcement),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
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

  testWidgets('author can archive their community post', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 900));
    await _enterResidence(tester);

    await tester.tap(find.byKey(const Key('community-filter-mine')));
    await tester.pumpAndSettle();
    expect(find.text('شقة 12 · منذ ساعة'), findsOneWidget);
    final roleBadge = find.byKey(
      const ValueKey('post-author-role-question-plumber'),
    );
    expect(roleBadge, findsNothing);

    final menu = find.byKey(const ValueKey('post-menu-question-plumber'));
    final popupMenu = tester.widget<PopupMenuButton<String>>(menu);
    expect(popupMenu.color, AppColors.surface);
    expect(popupMenu.surfaceTintColor, Colors.transparent);
    expect(
      (popupMenu.shape as RoundedRectangleBorder).side.color,
      AppColors.outline,
    );
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف المنشور'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'حذف'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('community-post-question-plumber')),
      findsNothing,
    );
  });

  testWidgets('president can archive another resident community post', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 900));
    await _enterResidence(tester);

    final menu = find.byKey(const ValueKey('post-menu-announcement-elevator'));
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف المنشور'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'حذف'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('community-post-announcement-elevator')),
      findsNothing,
    );
  });

  testWidgets(
    'delegated president permissions expose archive for other posts',
    (tester) async {
      await _pumpApp(
        tester,
        size: const Size(1280, 900),
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
        ),
      );
      await _enterResidence(tester);

      expect(
        find.byKey(const ValueKey('post-menu-announcement-elevator')),
        findsOneWidget,
      );
    },
  );

  testWidgets('resident can browse a service profile and recommend it', (
    tester,
  ) async {
    String? calledPhone;
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      servicePhoneLauncher: (phone) async {
        calledPhone = phone;
        return true;
      },
    );
    await _enterResidence(tester);

    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('directory-page')), findsOneWidget);

    expect(find.byKey(const Key('add-service-fab')), findsOneWidget);
    expect(find.text('الصيانة'), findsOneWidget);
    expect(
      find.textContaining('ستظهر هنا الخدمات الأكثر توصية'),
      findsOneWidget,
    );
    expect(find.text('عرض الكل'), findsNothing);

    final service = find.byKey(
      const ValueKey('directory-entry-mohamed-electrician'),
    );
    await tester.ensureVisible(service);
    await tester.tap(service);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('directory-profile-page')), findsOneWidget);
    expect(find.text('محمد الكهربائي'), findsOneWidget);
    expect(find.text('كهربائي · سباك'), findsOneWidget);
    expect(find.text('المعاريف'), findsOneWidget);
    expect(find.byIcon(Icons.handyman_rounded), findsWidgets);
    expect(find.byType(BackButtonIcon), findsOneWidget);
    expect(find.byKey(const Key('subpage-title')), findsNothing);

    await tester.tap(find.text('اتصال'));
    await tester.pump();
    expect(calledPhone, '+212612345678');

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

  testWidgets('resident can add a directory service', (tester) async {
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      directoryRepository: _TestDirectoryRepository(emitCreateChange: false),
    );
    await _enterResidence(tester);

    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-service-fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-service-page')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('service-name-field')),
      'شركة النور',
    );
    await tester.tap(find.byKey(const Key('service-category-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صيانة المنزل').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('service-subcategory-electrician')),
    );
    await tester.tap(find.byKey(const ValueKey('service-subcategory-plumber')));
    await tester.enterText(
      find.byKey(const Key('service-description-field')),
      'إصلاح الأعطال والتركيبات الكهربائية',
    );
    await tester.enterText(
      find.byKey(const Key('service-phone-field')),
      '6 12 34 56 78',
    );
    await tester.enterText(
      find.byKey(const Key('service-neighborhood-field')),
      'المعاريف',
    );
    await tester.ensureVisible(find.byKey(const Key('save-service-button')));
    await tester.tap(find.byKey(const Key('save-service-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('directory-profile-page')), findsOneWidget);
    expect(find.text('شركة النور'), findsOneWidget);
    expect(find.text('كهربائي · سباك'), findsOneWidget);
  });

  testWidgets('service creator can edit their service from its profile', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();
    final service = find.byKey(
      const ValueKey('directory-entry-mohamed-electrician'),
    );
    await tester.ensureVisible(service);
    await tester.tap(service);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-service-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-service-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-service-page')), findsOneWidget);
    expect(find.text('محمد الكهربائي'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('service-description-field')),
      'وصف محدث لخدمة الكهرباء',
    );
    await tester.ensureVisible(find.byKey(const Key('save-service-button')));
    await tester.tap(find.byKey(const Key('save-service-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('directory-profile-page')), findsOneWidget);
    expect(find.text('وصف محدث لخدمة الكهرباء'), findsOneWidget);
  });

  testWidgets('service edit action is hidden from non-creators', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      directoryRepository: _TestDirectoryRepository(ownerId: 'another-user'),
    );
    await _enterResidence(tester);

    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();
    final service = find.byKey(
      const ValueKey('directory-entry-mohamed-electrician'),
    );
    await tester.ensureVisible(service);
    await tester.tap(service);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('directory-profile-page')), findsOneWidget);
    expect(find.byKey(const Key('edit-service-button')), findsNothing);
  });

  testWidgets('residence exposes account, finances, and management routes', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);

    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);
    expect(
      find.byKey(const Key('apartment-not-assigned-alert')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('compact-residence-address-and-city')),
          )
          .data,
      'شارع الاختبار • الدار البيضاء',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('residence-building-count')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('residence-apartment-count')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('residence-construction-year')),
        matching: find.text('2018'),
      ),
      findsOneWidget,
    );

    final directoryCard = find.byKey(const Key('residence-directory-card'));
    expect(
      find.descendant(
        of: directoryCard,
        matching: find.byIcon(Icons.arrow_forward_ios_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(directoryCard);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('residence-members-page')), findsOneWidget);
    expect(find.text('سكان الإقامة'), findsOneWidget);
    expect(find.text('يوسف ع.'), findsOneWidget);
    expect(find.text('كريم ت.'), findsOneWidget);
    expect(find.text('الشقة 12 · الطابق الأول'), findsOneWidget);
    expect(find.text('رئيس'), findsOneWidget);
    expect(find.text('ساكن'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('residence-member-test-user')))
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('residence-member-member-karim')),
            )
            .dy,
      ),
    );

    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);

    await tester.tap(find.text('حالة الواجبات'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dues-page')), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('subpage-back-button')));
    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-home-page')), findsOneWidget);

    await tester.ensureVisible(find.text('مالية الإقامة'));
    await tester.tap(find.text('مالية الإقامة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-finances-page')), findsOneWidget);
    expect(find.byKey(const Key('title-only-subpage-header')), findsOneWidget);
    expect(find.byKey(const Key('finance-total-income')), findsOneWidget);
    expect(find.byKey(const Key('finance-total-expenses')), findsOneWidget);
    expect(find.byKey(const Key('finance-current-balance')), findsOneWidget);
    expect(find.byKey(const Key('finance-collection-rate')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('residence-expense-elevator-service-july')),
      findsOneWidget,
    );
    expect(find.text('تمت صيانة محرك المصعد'), findsOneWidget);
    final recentExpenseAttachment = find.byKey(
      const ValueKey('residence-expense-attachment-elevator-service-july'),
    );
    await tester.ensureVisible(recentExpenseAttachment);
    await tester.tap(recentExpenseAttachment);
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

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
    expect(find.text('تمت صيانة محرك المصعد'), findsOneWidget);
    final transactionAttachment = find.byKey(
      const ValueKey('finance-transaction-attachment-elevator-service-july'),
    );
    await tester.ensureVisible(transactionAttachment);
    await tester.tap(transactionAttachment);
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    final financeStart = DateTime.now();
    final financeEnd = DateTime(financeStart.year, financeStart.month + 3);
    expect(
      find.text(
        'اشتراك الشقة 01 عن '
        '${financeStart.month.toString().padLeft(2, '0')}-${financeStart.year} '
        'إلى '
        '${financeEnd.month.toString().padLeft(2, '0')}-${financeEnd.year}',
      ),
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
    expect(find.byKey(const Key('title-only-subpage-header')), findsOneWidget);
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
      'إشعارات هامة',
      'معلومات الإدارة',
    ]) {
      expect(find.text(section), findsOneWidget);
    }
    expect(
      find.text('وافق الرئيس على طلب انضمامك إلى الإقامة'),
      findsOneWidget,
    );
    expect(find.text('عرض كل الإشعارات'), findsNothing);

    await tester.tap(find.text('الوثائق'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-documents-page')), findsOneWidget);
    expect(find.text('الوثائق الإدارية'), findsOneWidget);
    expect(find.text('الوثائق المرفقة'), findsOneWidget);
    expect(
      find.byKey(const Key('administrative-documents-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('transaction-attachments-section')),
      findsOneWidget,
    );
    expect(find.text('القانون الداخلي'), findsOneWidget);
    expect(find.text('محضر الاجتماع'), findsOneWidget);
    expect(
      find.text(residenceTransactionAttachmentName('elevator-service-july')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('view-all-administrative-documents')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('all-administrative-documents-sheet')),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('view-all-transaction-attachments')),
    );
    await tester.tap(find.byKey(const Key('view-all-transaction-attachments')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('all-transaction-attachments-sheet')),
      findsOneWidget,
    );
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
    expect(find.text('(212)612345678'), findsOneWidget);
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
    expect(find.byKey(const Key('profile-image-menu-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-image-menu-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('select-profile-image-button')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final profilePhone = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('profile-phone-number')),
        matching: find.byType(Text),
      ),
    );
    expect(profilePhone.data, '(212)612345678');
    expect(profilePhone.style?.fontWeight, isNot(FontWeight.w600));
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
    expect(find.text('لا يتم إظهار النسب للسكان الآخرين.'), findsOneWidget);
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

  testWidgets('profile signs out through a DarJar confirmation dialog', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      authRepository: authRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    final signOutButton = find.byKey(const Key('sign-out-button'));
    await tester.ensureVisible(signOutButton);

    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sign-out-confirmation-dialog')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('تسجيل الخروج؟'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-sign-out-button')));
    await tester.pumpAndSettle();

    expect(authRepository.currentUser, isNull);
    expect(find.byKey(const Key('phone-auth-page')), findsOneWidget);
  });

  testWidgets('profile opens privacy policy and about app before sign out', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    final privacyLink = find.byKey(const Key('privacy-policy-link'));
    final aboutLink = find.byKey(const Key('about-app-link'));
    final signOutButton = find.byKey(const Key('sign-out-button'));
    await tester.ensureVisible(signOutButton);

    final informationCard = find.ancestor(
      of: privacyLink,
      matching: find.byType(DarJarCard),
    );
    final signOutCard = find.ancestor(
      of: signOutButton,
      matching: find.byType(DarJarCard),
    );
    expect(
      informationCard.evaluate().single,
      same(signOutCard.evaluate().single),
    );

    expect(
      tester.getTopLeft(privacyLink).dy,
      lessThan(tester.getTopLeft(aboutLink).dy),
    );
    expect(
      tester.getTopLeft(aboutLink).dy,
      lessThan(tester.getTopLeft(signOutButton).dy),
    );

    await tester.tap(privacyLink);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy-policy-page')), findsOneWidget);
    expect(find.text('البيانات التي نجمعها'), findsOneWidget);
    expect(find.text('مشاركة البيانات'), findsOneWidget);

    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(aboutLink);
    await tester.tap(aboutLink);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('about-app-page')), findsOneWidget);
    expect(find.text('0.0.0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Raqmain®'), findsOneWidget);
    final detailsCard = tester.widget<DecoratedBox>(
      find.byKey(const Key('about-details-card')),
    );
    expect((detailsCard.decoration as BoxDecoration).color, AppColors.surface);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('app-publisher-value')))
          .textDirection,
      TextDirection.ltr,
    );
    expect(tester.widget<DarJarBrand>(find.byType(DarJarBrand)).logoSize, 44);
    expect(
      find.text('جميع الحقوق محفوظة © 2026 \u2066Raqmain®\u2069'),
      findsOneWidget,
    );
  });

  testWidgets('resident sees stored dues without creating records while opening', (
    tester,
  ) async {
    final now = DateTime.now();
    final duesRepository = _FakeResidenceDuesRepository()
      ..overview = ResidenceDuesOverview(
        dues: [
          for (var index = 0; index < 3; index++)
            ResidenceDue(
              id:
                  '${residenceDuesPeriodKey(DateTime(now.year, now.month - index))}'
                  '_apartment-01',
              apartmentId: 'apartment-01',
              apartmentNumber: '01',
              periodKey: residenceDuesPeriodKey(
                DateTime(now.year, now.month - index),
              ),
              amountDue: 150,
              amountPaid: 0,
              status: ResidenceDueStatus.unpaid,
            ),
        ],
        payments: const [],
      );
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceDuesRepository: duesRepository,
      residenceContext: const ResidenceContext(
        residences: [
          UserResidence(
            id: 'test-residence',
            name: 'إقامة الاختبار',
            address: 'شارع الاختبار',
            city: '6141010',
            role: 'resident',
            apartmentId: 'apartment-01',
          ),
        ],
        activeResidenceId: 'test-residence',
        invitations: [],
      ),
    );
    await _enterResidence(tester);
    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    expect(duesRepository.overview.dues, hasLength(3));
    await tester.tap(find.text('حالة الواجبات'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dues-page')), findsOneWidget);
    expect(find.byKey(const Key('dues-total-debit')), findsOneWidget);
    final debitCard = find.byKey(const Key('dues-total-debit'));
    final creditCard = find.byKey(const Key('dues-total-credit'));
    final prepaidCard = find.byKey(const Key('dues-prepaid-months'));
    expect(tester.getSize(debitCard).width, lessThan(130));
    expect(tester.getTopLeft(debitCard).dy, tester.getTopLeft(creditCard).dy);
    expect(tester.getTopLeft(debitCard).dy, tester.getTopLeft(prepaidCard).dy);
    tester.view.physicalSize = const Size(300, 844);
    await tester.pumpAndSettle();
    expect(tester.getSize(debitCard).width, greaterThan(250));
    expect(
      tester.getTopLeft(creditCard).dy,
      greaterThan(tester.getBottomLeft(debitCard).dy),
    );
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(
      find.text('عرض مبسط لحالة واجبات السكن المسجلة من الإدارة.'),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey(
          'resident-due-${residenceDuesPeriodKey(DateTime.now())}_apartment-01',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('غير مؤدى'), findsNWidgets(3));
    expect(find.text('لا توجد اشتراكات مسجلة لهذه الشقة بعد.'), findsNothing);
  });

  testWidgets('resident sees prepaid credit and the full last payment total', (
    tester,
  ) async {
    final now = DateTime.now();
    final currentPeriod = residenceDuesPeriodKey(now);
    final nextPeriod = residenceDuesPeriodKey(
      DateTime(now.year, now.month + 1),
    );
    final paidAt = DateTime(now.year, now.month, 10);
    final membersRepository = _FakeResidenceMembersRepository();
    final duesRepository = _FakeResidenceDuesRepository()
      ..overview = ResidenceDuesOverview(
        dues: [
          ResidenceDue(
            id: '${currentPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            periodKey: currentPeriod,
            amountDue: 150,
            amountPaid: 150,
            status: ResidenceDueStatus.paid,
          ),
          ResidenceDue(
            id: '${nextPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            periodKey: nextPeriod,
            amountDue: 150,
            amountPaid: 150,
            status: ResidenceDueStatus.paid,
          ),
        ],
        payments: [
          ResidenceDuePayment(
            id: 'payment-next',
            dueId: '${nextPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            amount: 150,
            paidAt: paidAt,
            note: '',
            recordedBy: 'test-user',
            paymentGroupId: 'payment-group-attachment',
            supportingDocument: 'receipt.pdf',
            attachmentStoragePath:
                'residences/test-residence/attachments/dues-payment-group-attachment/content',
            attachmentContentType: 'application/pdf',
            attachmentSizeBytes: 1024,
            createdAt: paidAt,
          ),
          ResidenceDuePayment(
            id: 'payment-current',
            dueId: '${currentPeriod}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            amount: 150,
            paidAt: paidAt,
            note: '',
            recordedBy: 'test-user',
            paymentGroupId: 'payment-group-attachment',
            supportingDocument: 'receipt.pdf',
            attachmentStoragePath:
                'residences/test-residence/attachments/dues-payment-group-attachment/content',
            attachmentContentType: 'application/pdf',
            attachmentSizeBytes: 1024,
            createdAt: paidAt,
          ),
        ],
      );

    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceDuesRepository: duesRepository,
      residenceMembersRepository: membersRepository,
      residenceContext: const ResidenceContext(
        residences: [
          UserResidence(
            id: 'test-residence',
            name: 'إقامة الاختبار',
            address: 'شارع الاختبار',
            city: '6141010',
            role: 'resident',
            apartmentId: 'apartment-01',
          ),
        ],
        activeResidenceId: 'test-residence',
        invitations: [],
      ),
    );
    await _enterResidence(tester);
    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();

    expect(membersRepository.lastIncludeInvitations, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const Key('residence-apartment-count')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('account-last-payment-total')),
        matching: find.text('300 درهم', findRichText: true),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('حالة الواجبات'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('dues-total-credit')),
        matching: find.text('150 درهم'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dues-prepaid-months')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    final attachmentButton = find.byKey(
      const ValueKey('resident-payment-attachment-payment-group-attachment'),
    );
    await tester.ensureVisible(attachmentButton);
    expect(attachmentButton, findsOneWidget);
    expect(
      find.descendant(of: attachmentButton, matching: find.text('عرض المرفق')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: attachmentButton,
        matching: find.text(
          residenceTransactionAttachmentName('payment-group-attachment'),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(attachmentButton).height, lessThan(36));
    await tester.tap(attachmentButton);
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('subpage-back-button')));
    await tester.tap(find.byKey(const Key('subpage-back-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('مالية الإقامة'));
    await tester.tap(find.text('مالية الإقامة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('residence-finances-page')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('view-all-transactions-button')),
    );
    await tester.tap(find.byKey(const Key('view-all-transactions-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finance-transactions-page')), findsOneWidget);
  });

  testWidgets('dues status initially shows only the latest twelve months', (
    tester,
  ) async {
    final now = DateTime.now();
    final dues = [
      for (var index = 0; index < 13; index++)
        ResidenceDue(
          id:
              '${residenceDuesPeriodKey(DateTime(now.year, now.month - index))}'
              '_apartment-01',
          apartmentId: 'apartment-01',
          apartmentNumber: '01',
          periodKey: residenceDuesPeriodKey(
            DateTime(now.year, now.month - index),
          ),
          amountDue: 150,
          amountPaid: 150,
          status: ResidenceDueStatus.paid,
        ),
    ];
    final duesRepository = _FakeResidenceDuesRepository()
      ..overview = ResidenceDuesOverview(dues: dues, payments: const []);
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceDuesRepository: duesRepository,
      residenceContext: const ResidenceContext(
        residences: [
          UserResidence(
            id: 'test-residence',
            name: 'إقامة الاختبار',
            address: 'شارع الاختبار',
            city: '6141010',
            role: 'resident',
            apartmentId: 'apartment-01',
          ),
        ],
        activeResidenceId: 'test-residence',
        invitations: [],
      ),
    );
    await _enterResidence(tester);
    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حالة الواجبات'));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('resident-due-${dues.last.id}')), findsNothing);
    final showMore = find.byKey(const Key('show-more-dues'));
    expect(showMore, findsOneWidget);
    await tester.ensureVisible(showMore);
    await tester.tap(showMore);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('resident-due-${dues.last.id}')),
      findsOneWidget,
    );
  });

  testWidgets('management allocates arrears first and prepays future months', (
    tester,
  ) async {
    final duesRepository = _FakeResidenceDuesRepository();
    final now = DateTime.now();
    final apartmentOnePeriods = [
      residenceDuesPeriodKey(DateTime(now.year, now.month - 2)),
      residenceDuesPeriodKey(DateTime(now.year, now.month - 1)),
      residenceDuesPeriodKey(now),
    ];
    duesRepository.overview = ResidenceDuesOverview(
      dues: [
        for (final periodKey in apartmentOnePeriods)
          ResidenceDue(
            id: '${periodKey}_apartment-01',
            apartmentId: 'apartment-01',
            apartmentNumber: '01',
            periodKey: periodKey,
            amountDue: 150,
            amountPaid: 0,
            status: ResidenceDueStatus.unpaid,
          ),
        ...duesRepository.overview.dues.where(
          (due) => due.apartmentId == 'apartment-02',
        ),
      ],
      payments: duesRepository.overview.payments,
    );
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceDuesRepository: duesRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('manage-dues-link')));
    await tester.tap(find.byKey(const Key('manage-dues-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dues-management-page')), findsOneWidget);
    expect(find.byKey(const Key('title-only-subpage-header')), findsOneWidget);
    expect(
      find.text('أنشئ واجبات الشهر تلقائياً لكل شقة وسجّل الأداءات اليدوية.'),
      findsNothing,
    );
    expect(find.byKey(const Key('management-dues-expected')), findsOneWidget);
    expect(find.byKey(const Key('management-dues-collected')), findsOneWidget);
    expect(find.byKey(const Key('management-dues-remaining')), findsOneWidget);
    final expectedCard = find.byKey(const Key('management-dues-expected'));
    final collectedCard = find.byKey(const Key('management-dues-collected'));
    final remainingCard = find.byKey(const Key('management-dues-remaining'));
    expect(tester.getSize(expectedCard).width, lessThan(130));
    expect(
      tester.getTopLeft(expectedCard).dy,
      tester.getTopLeft(collectedCard).dy,
    );
    expect(
      tester.getTopLeft(expectedCard).dy,
      tester.getTopLeft(remainingCard).dy,
    );
    tester.view.physicalSize = const Size(300, 844);
    await tester.pumpAndSettle();
    expect(tester.getSize(expectedCard).width, greaterThan(250));
    expect(
      tester.getTopLeft(collectedCard).dy,
      greaterThan(tester.getBottomLeft(expectedCard).dy),
    );
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.text('الأشهر غير المؤداة: 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-periods-apartment-01')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('period-details-sheet')), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('managed-due-${apartmentOnePeriods.first}_apartment-01'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('record-payment-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('record-payment-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('record-payment-sheet')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('payment-amount-field')), findsNothing);
    await tester.tap(find.byKey(const Key('payment-apartment-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الشقة رقم 01').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payment-amount-field')), findsOneWidget);
    expect(
      find.byKey(const Key('payment-supporting-document-field')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('select-payment-attachment-button')),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('payment-amount-field')),
        matching: find.byType(TextField),
      ),
      '500',
    );
    await tester.tap(find.byKey(const Key('save-payment-button')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'أدخل مبلغاً صحيحاً. يجب أن يساوي الجزء المدفوع مسبقاً قيمة شهر كامل أو عدة أشهر.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('record-payment-sheet')), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('payment-amount-field')),
        matching: find.byType(TextField),
      ),
      '750',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('payment-note-field')),
        matching: find.byType(TextField),
      ),
      'أداء نقدي',
    );
    tester
        .widget<DarJarButton>(find.byKey(const Key('save-payment-button')))
        .onPressed
        ?.call();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('تم تسجيل الأداء بنجاح.'), findsOneWidget);
    final apartmentOneDues = duesRepository.overview.dues
        .where((due) => due.apartmentId == 'apartment-01')
        .toList();
    expect(apartmentOneDues, hasLength(5));
    expect(
      apartmentOneDues.every(
        (due) => due.amountPaid == 150 && due.status == ResidenceDueStatus.paid,
      ),
      isTrue,
    );
    expect(
      apartmentOneDues.map((due) => due.periodKey),
      containsAll([
        residenceDuesPeriodKey(DateTime(now.year, now.month + 1)),
        residenceDuesPeriodKey(DateTime(now.year, now.month + 2)),
      ]),
    );
    final apartmentOnePayments = duesRepository.overview.payments
        .where((payment) => payment.apartmentId == 'apartment-01')
        .toList();
    expect(apartmentOnePayments, hasLength(5));
    expect(
      apartmentOnePayments.map((payment) => payment.paymentGroupId).toSet(),
      hasLength(1),
    );
    expect(duesRepository.overview.payments.first.note, 'أداء نقدي');
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey(
            'management-payment-${apartmentOnePayments.first.paymentGroupId}',
          ),
        ),
        matching: find.text('750 درهم'),
      ),
      findsOneWidget,
    );
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
    expect(find.byKey(const Key('manage-documents-link')), findsNothing);
    expect(find.byKey(const Key('reset-residence-button')), findsNothing);
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
      expect(find.byKey(const Key('reset-residence-button')), findsNothing);
    },
  );

  testWidgets('president actions share one neutral account actions group', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    final signOut = find.byKey(const Key('sign-out-button'));
    final reset = find.byKey(const Key('reset-residence-button'));
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    expect(reset, findsOneWidget);
    final signOutCard = find.ancestor(
      of: signOut,
      matching: find.byType(DarJarCard),
    );
    final resetCard = find.ancestor(
      of: reset,
      matching: find.byType(DarJarCard),
    );
    expect(signOutCard.evaluate().single, same(resetCard.evaluate().single));
    final signOutTile = tester.widget<ListTile>(signOut);
    final resetTile = tester.widget<ListTile>(reset);
    expect((signOutTile.title! as Text).style, isNull);
    expect((resetTile.title! as Text).style, isNull);
    expect((signOutTile.leading! as Icon).color, isNull);
    expect((resetTile.leading! as Icon).color, isNull);
    expect(
      tester.getTopLeft(signOut).dy,
      lessThan(tester.getTopLeft(reset).dy),
    );

    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('reset-residence-confirmation-dialog')),
      findsOneWidget,
    );
    expect(find.text('إعادة ضبط الإقامة؟'), findsOneWidget);
    expect(find.textContaining('ستؤرشف جميع المنشورات'), findsOneWidget);
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

    final chevrons = find.descendant(
      of: find.byKey(const Key('residence-management-section')),
      matching: find.byIcon(Icons.chevron_left_rounded),
    );
    expect(chevrons, findsNWidgets(5));
    for (final icon in tester.widgetList<Icon>(chevrons)) {
      expect(icon.textDirection, TextDirection.ltr);
    }

    for (final navigation in [
      (link: 'manage-residence-link', page: 'residence-settings-page'),
      (link: 'manage-apartments-link', page: 'apartments-management-page'),
      (link: 'manage-dues-link', page: 'dues-management-page'),
      (link: 'manage-finances-link', page: 'finance-management-page'),
      (link: 'manage-documents-link', page: 'documents-management-page'),
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

  testWidgets('management uploads, renames, and deletes residence documents', (
    tester,
  ) async {
    final uploadBarrier = Completer<void>();
    final documentsRepository = _FakeResidenceDocumentsRepository(
      uploadBarrier: uploadBarrier,
    );
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceDocumentsRepository: documentsRepository,
      residenceDocumentPicker: () async => XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'application/pdf',
        name: 'budget.pdf',
      ),
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-documents-link')));
    await tester.tap(find.byKey(const Key('manage-documents-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('documents-management-page')), findsOneWidget);
    expect(find.text('القانون الداخلي'), findsOneWidget);

    await tester.tap(find.byKey(const Key('upload-residence-document-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'ميزانية 2026',
    );
    await tester.tap(find.byKey(const Key('select-document-file-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('submit-document-upload-button')),
    );
    await tester.tap(find.byKey(const Key('submit-document-upload-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('document-upload-progress-card')),
      findsOneWidget,
    );
    expect(find.text('50%'), findsOneWidget);

    uploadBarrier.complete();
    await tester.pumpAndSettle();

    expect(documentsRepository.documents.first.title, 'ميزانية 2026');
    final uploadedId = documentsRepository.documents.first.id;
    expect(
      find.byKey(ValueKey('residence-document-$uploadedId')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey('edit-residence-document-$uploadedId')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-document-title-field')),
      'الميزانية السنوية 2026',
    );
    await tester.tap(find.byKey(const Key('save-document-title-button')));
    await tester.pumpAndSettle();
    expect(documentsRepository.documents.first.title, 'الميزانية السنوية 2026');

    await tester.tap(
      find.byKey(ValueKey('delete-residence-document-$uploadedId')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-document-button')));
    await tester.pumpAndSettle();
    expect(
      documentsRepository.documents.any(
        (document) => document.id == uploadedId,
      ),
      isFalse,
    );
  });

  testWidgets('management records, edits, and deletes manual finances', (
    tester,
  ) async {
    final financeRepository = _FakeResidenceFinanceRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceFinanceRepository: financeRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-finances-link')));
    await tester.tap(find.byKey(const Key('manage-finances-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finance-management-page')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit-finance-transaction-dues-july')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('add-finance-transaction-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Material>(find.byKey(const Key('finance-transaction-sheet')))
          .color,
      AppColors.surface,
    );
    await tester.tap(find.byKey(const Key('finance-transaction-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مداخيل').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('finance-supporting-document-field')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('select-finance-attachment-button')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('finance-transaction-name-field')),
      'كراء موقف إضافي',
    );
    await tester.enterText(
      find.byKey(const Key('finance-transaction-amount-field')),
      '300',
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-finance-transaction-button')),
    );
    tester
        .widget<DarJarButton>(
          find.byKey(const Key('save-finance-transaction-button')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(
      financeRepository.transactions.any(
        (transaction) =>
            transaction.name == 'كراء موقف إضافي' &&
            transaction.type == ResidenceTransactionType.income,
      ),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('managed-finance-transaction-manual-1')),
      findsOneWidget,
    );

    final editManualTransactionButton = find.byKey(
      const ValueKey('edit-finance-transaction-manual-1'),
    );
    await tester.ensureVisible(editManualTransactionButton);
    await tester.tap(editManualTransactionButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('finance-transaction-name-field')),
      'كراء موقف',
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-finance-transaction-button')),
    );
    tester
        .widget<DarJarButton>(
          find.byKey(const Key('save-finance-transaction-button')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect(
      financeRepository.transactions
          .singleWhere((transaction) => transaction.id == 'manual-1')
          .name,
      'كراء موقف',
    );

    final deleteManualTransactionButton = find.byKey(
      const ValueKey('delete-finance-transaction-manual-1'),
    );
    await tester.ensureVisible(deleteManualTransactionButton);
    await tester.tap(deleteManualTransactionButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm-delete-finance-transaction')),
    );
    await tester.pumpAndSettle();
    expect(
      financeRepository.transactions.any(
        (transaction) => transaction.id == 'manual-1',
      ),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('add-finance-transaction-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<ResidenceTransactionType>>(
            find.byKey(const Key('finance-transaction-type-field')),
          )
          .value,
      ResidenceTransactionType.expense,
    );
    expect(
      tester
          .state<FormFieldState<ResidenceExpenseCategory>>(
            find.byKey(const Key('finance-expense-category-field')),
          )
          .value,
      ResidenceExpenseCategory.maintenance,
    );
    expect(
      find.byKey(const Key('finance-transaction-name-field')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('finance-expense-category-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مصروف مخصص').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('finance-transaction-name-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('finance-transaction-name-field')),
      'تهيئة الحديقة',
    );
    await tester.enterText(
      find.byKey(const Key('finance-transaction-amount-field')),
      '120',
    );
    tester
        .widget<DarJarButton>(
          find.byKey(const Key('save-finance-transaction-button')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect(
      financeRepository.transactions.any(
        (transaction) =>
            transaction.name == 'تهيئة الحديقة' &&
            transaction.type == ResidenceTransactionType.expense &&
            transaction.expenseCategory == ResidenceExpenseCategory.custom,
      ),
      isTrue,
    );
  });

  testWidgets('management records an opening balance as an adjustment', (
    tester,
  ) async {
    final financeRepository = _FakeResidenceFinanceRepository();
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      residenceFinanceRepository: financeRepository,
    );
    await _enterResidence(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage-finances-link')));
    await tester.tap(find.byKey(const Key('manage-finances-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opening-balance-alert')), findsOneWidget);
    await tester.tap(find.byKey(const Key('enter-opening-balance-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('opening-balance-amount-field')),
      '1000',
    );
    await tester.tap(find.byKey(const Key('save-opening-balance-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opening-balance-alert')), findsNothing);
    expect(
      financeRepository.transactions
          .singleWhere((transaction) => transaction.isOpeningBalance)
          .amount,
      1000,
    );
    final finances = await financeRepository.load('test-residence');
    expect(finances.totalIncome, 200);
    expect(finances.currentBalance, 1120);
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
      final residenceIdValue = find.byKey(const Key('residence-id-field'));
      expect(residenceIdValue, findsOneWidget);
      expect(
        find.descendant(of: residenceIdValue, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(find.text('معرّف الإقامة'), findsOneWidget);
      expect(find.textContaining('للقراءة فقط'), findsNothing);
      expect(find.text('48273165'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('residence-id-value')))
            .textDirection,
        TextDirection.rtl,
      );
      final copyResidenceIdButton = find.byKey(
        const Key('copy-residence-id-button'),
      );
      expect(copyResidenceIdButton, findsOneWidget);
      expect(
        tester.getSize(copyResidenceIdButton).height,
        tester.getSize(residenceIdValue).height,
      );
      String? copiedResidenceId;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedResidenceId =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      await tester.tap(copyResidenceIdButton);
      await tester.pumpAndSettle();
      expect(copiedResidenceId, '48273165');
      expect(find.text('تم نسخ معرّف الإقامة.'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(copyResidenceIdButton),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('settings-residence-city-field')),
        findsOneWidget,
      );
      expect(find.text('الدار البيضاء'), findsOneWidget);
      expect(
        find.byKey(const Key('select-residence-image-button')),
        findsOneWidget,
      );
      expect(
        find.text('يفضّل اختيار صورة مربعة للحصول على أفضل عرض.'),
        findsOneWidget,
      );
      expect(find.text('اختياري، ويمكن تغييره في أي وقت.'), findsNothing);
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
                of: find.byKey(const Key('management-phone-number-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        '600000001',
      );
      final managementPhoneField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('management-phone-number-field')),
          matching: find.byType(TextField),
        ),
      );
      expect(managementPhoneField.textDirection, TextDirection.ltr);
      expect(managementPhoneField.decoration?.labelText, isNull);
      expect(managementPhoneField.decoration?.hintText, 'الهاتف');
      expect(
        Directionality.of(
          tester.element(
            find.descendant(
              of: find.byKey(const Key('management-phone-number-field')),
              matching: find.byType(TextField),
            ),
          ),
        ),
        TextDirection.rtl,
      );
      expect(
        tester
            .widget<DarJarCountryCodePickerField>(
              find.byKey(const Key('management-phone-country-code-field')),
            )
            .value,
        '+212',
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
      final buildingDialog = tester.widget<AlertDialog>(
        find.byKey(const Key('building-editor-dialog')),
      );
      expect(buildingDialog.backgroundColor, AppColors.surface);
      expect(buildingDialog.surfaceTintColor, Colors.transparent);
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
        find.byKey(const Key('management-phone-number-field')),
        '5 22 11 22 33',
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('apartment-apartment-12')),
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('التتبّع مفعّل'), findsNothing);
    expect(find.text('عدد السكان'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('apartment-apartment-12')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('apartment-details-apartment-12')),
      findsOneWidget,
    );
    expect(find.text('معلومات الشقة'), findsOneWidget);
    expect(find.text('عدد السكان'), findsOneWidget);
    expect(find.text('التتبّع مفعّل'), findsOneWidget);
    expect(find.text('يوسف العلوي'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('العمارة الرئيسية'), findsNothing);
    expect(find.text('إعدادات الإقامة'), findsNothing);

    await tester.tap(find.byKey(const Key('add-apartment-button')));
    await tester.pumpAndSettle();
    expect(find.text('رقم الشقة'), findsOneWidget);
    expect(find.text('رقم أو اسم الشقة'), findsNothing);
    expect(find.byKey(const Key('apartment-advanced-options')), findsOneWidget);
    expect(
      find.byKey(const Key('apartment-dues-tracking-field')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('apartment-last-paid-month-field')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('new-apartment-number-field')),
      '03A',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apartment-advanced-options')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('apartment-dues-tracking-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('apartment-last-paid-month-field')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('apartment-last-paid-month-field')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('month-year-picker-dialog')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(find.byKey(const Key('month-year-picker-year')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('month-year-picker-month-1')),
      findsOneWidget,
    );
    await tester.tap(find.text('إلغاء').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('يبدأ التتبّع لاحقًا'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('new-apartment-number-field')),
          )
          .controller
          ?.text,
      '03',
    );
    await tester.ensureVisible(
      find.byKey(const Key('confirm-add-apartment-button')),
    );
    await tester.tap(find.byKey(const Key('confirm-add-apartment-button')));
    await tester.pumpAndSettle();
    final addedApartment = find.byKey(
      const ValueKey('apartment-apartment-ground-floor-3'),
    );
    expect(addedApartment, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('start-dues-tracking-apartment-ground-floor-3'),
      ),
      findsNothing,
    );
    await tester.tap(addedApartment);
    await tester.pumpAndSettle();
    expect(find.text('التتبّع لم يبدأ'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('start-dues-tracking-apartment-ground-floor-3'),
      ),
      findsOneWidget,
    );
    final startTracking = find.byKey(
      const ValueKey('start-dues-tracking-apartment-ground-floor-3'),
    );
    await tester.ensureVisible(startTracking);
    await tester.pumpAndSettle();
    await tester.tap(startTracking);
    await tester.pumpAndSettle();
    final trackingLastPaidMonth = find.byKey(
      const Key('start-tracking-last-paid-month-field'),
    );
    await tester.tap(trackingLastPaidMonth);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('month-year-picker-dialog')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsNothing);
    await tester.tap(find.byKey(const Key('confirm-month-year-picker')));
    await tester.pumpAndSettle();
    final confirmTracking = find.byKey(
      const Key('confirm-start-apartment-dues-tracking'),
    );
    tester.widget<FilledButton>(confirmTracking).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('التتبّع مفعّل'), findsNothing);

    await tester.ensureVisible(addedApartment);
    await tester.tap(addedApartment);
    await tester.pumpAndSettle();
    expect(find.text('التتبّع مفعّل'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('start-dues-tracking-apartment-ground-floor-3'),
      ),
      findsNothing,
    );

    final deleteAddedApartment = find.byKey(
      const ValueKey('delete-apartment-apartment-ground-floor-3'),
    );
    await tester.ensureVisible(deleteAddedApartment);
    await tester.pumpAndSettle();
    tester.widget<OutlinedButton>(deleteAddedApartment).onPressed!();
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
    expect(find.text('إرسال دعوة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('send-resident-invitation-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitation-share-dialog')), findsOneWidget);
    expect(
      find.textContaining(
        'مرحباً كريم، لقد تمت إضافتك إلى إقامة الاختبار على تطبيق دارجار',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('close-invitation-share-dialog')));
    await tester.pumpAndSettle();

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

    expect(find.text('(212)612345678'), findsOneWidget);
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
    expect(find.text('لا يتم إظهار النسب للسكان الآخرين.'), findsOneWidget);

    expect(
      find
          .byKey(const Key('resident-country-code-field'))
          .evaluate()
          .single
          .widget,
      isA<DarJarCountryCodePickerField>(),
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
    expect(find.byKey(const Key('invitation-share-dialog')), findsOneWidget);
    expect(
      find.textContaining(
        'مرحباً مريم، لقد تمت إضافتك إلى إقامة الاختبار على تطبيق دارجار',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('invitation-message-field')), findsOneWidget);
    expect(
      find.byKey(const Key('confirm-share-invitation-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('close-invitation-share-dialog')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-invitation-+212698765432')),
      findsOneWidget,
    );
    expect(find.text('الدعوة معلّقة'), findsOneWidget);
    expect(find.text('(212)698765432'), findsOneWidget);

    final pendingInvitationMenu = find.byKey(
      const ValueKey('pending-invitation-menu-+212698765432'),
    );
    await tester.tap(pendingInvitationMenu);
    await tester.pumpAndSettle();
    expect(find.text('إرسال دعوة'), findsWidgets);
    expect(find.text('حذف الدعوة'), findsOneWidget);
    await tester.tap(find.text('إرسال دعوة').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitation-share-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('close-invitation-share-dialog')));
    await tester.pumpAndSettle();

    await tester.tap(pendingInvitationMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف الدعوة').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('delete-pending-invitation-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('confirm-delete-pending-invitation')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-invitation-+212698765432')),
      findsNothing,
    );
    expect(find.text('تم حذف الدعوة.'), findsOneWidget);

    await tester.ensureVisible(groupInvitationButton);
    await tester.pumpAndSettle();
    await tester.tap(groupInvitationButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group-invitation-page')), findsOneWidget);
    expect(find.text('الدعوة الجماعية'), findsOneWidget);
    expect(find.byKey(const Key('public-invitation-link')), findsOneWidget);
    expect(find.byKey(const Key('group-invitation-qr-code')), findsOneWidget);
    expect(find.text('السماح بالانضمام عبر الرابط'), findsOneWidget);
    expect(find.text('نسخ الرابط'), findsNothing);
    expect(
      find.byKey(const Key('share-group-invitation-link-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('print-group-invitation-qr-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('share-group-invitation-link-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitation-share-dialog')), findsOneWidget);
    expect(
      find.textContaining(
        'أدعوك للانضمام إلى إقامة الاختبار على تطبيق دارجار، لتتبّع ميزانية الإقامة',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('invitation-message-field')),
      'نص دعوة جماعية معدل',
    );
    expect(find.text('نص دعوة جماعية معدل'), findsOneWidget);
  });
}

const _testServiceCategories = <ServiceCategory>[
  ServiceCategory(
    id: 'home-maintenance',
    shortNameAr: 'الصيانة',
    longNameAr: 'صيانة المنزل',
    shortNameEn: 'Maintenance',
    longNameEn: 'Home maintenance',
    order: 1,
    subcategories: [
      ServiceSubcategory(
        id: 'electrician',
        nameAr: 'كهربائي',
        nameEn: 'Electrician',
      ),
      ServiceSubcategory(id: 'plumber', nameAr: 'سباك', nameEn: 'Plumber'),
    ],
  ),
];

class _TestServiceCategoriesRepository implements ServiceCategoriesRepository {
  const _TestServiceCategoriesRepository();

  @override
  Stream<List<ServiceCategory>> watchCategories() async* {
    yield _testServiceCategories;
  }
}

class _TestDirectoryRepository implements DirectoryRepository {
  _TestDirectoryRepository({
    this.ownerId = 'test-user',
    this.emitCreateChange = true,
  });

  final String ownerId;
  final bool emitCreateChange;
  final _changes = StreamController<List<DirectoryEntry>>.broadcast();
  late final entries = <DirectoryEntry>[
    DirectoryEntry(
      id: 'mohamed-electrician',
      name: 'محمد الكهربائي',
      categoryId: 'home-maintenance',
      subcategoryIds: ['electrician', 'plumber'],
      profession: 'كهربائي · إصلاح الأعطال والتركيبات',
      phone: '+212612345678',
      score: 0,
      recommendationCount: 0,
      localRecommendationCount: 0,
      workedResidences: ['إقامة الياسمين'],
      reviews: [],
      createdBy: ownerId,
      city: '6141010',
    ),
  ];

  @override
  Stream<List<DirectoryEntry>> watchEntries({
    required String city,
    required int limit,
  }) async* {
    List<DirectoryEntry> visibleEntries() => entries
        .where((entry) => entry.city == city)
        .take(limit)
        .toList(growable: false);

    yield List.unmodifiable(visibleEntries());
    yield* _changes.stream.map(
      (_) => List<DirectoryEntry>.unmodifiable(visibleEntries()),
    );
  }

  @override
  Future<String> createService({
    required String residenceId,
    required String userId,
    required String name,
    required String categoryId,
    required List<String> subcategoryIds,
    required String profession,
    required String phone,
    required String neighborhood,
  }) async {
    const id = 'created-service';
    entries.insert(
      0,
      DirectoryEntry(
        id: id,
        name: name,
        categoryId: categoryId,
        subcategoryIds: subcategoryIds,
        profession: profession,
        phone: phone,
        score: 0,
        recommendationCount: 0,
        localRecommendationCount: 0,
        workedResidences: const [],
        reviews: const [],
        neighborhood: neighborhood,
        createdBy: userId,
        city: '6141010',
      ),
    );
    if (emitCreateChange) _changes.add(List.unmodifiable(entries));
    return id;
  }

  @override
  Future<void> updateService({
    required String serviceId,
    required String userId,
    required String name,
    required String categoryId,
    required List<String> subcategoryIds,
    required String profession,
    required String phone,
    required String neighborhood,
  }) async {
    final index = entries.indexWhere((entry) => entry.id == serviceId);
    if (index == -1 || entries[index].createdBy != userId) {
      throw const DirectoryFailure('not-service-owner');
    }
    final previous = entries[index];
    entries[index] = DirectoryEntry(
      id: previous.id,
      name: name.trim(),
      categoryId: categoryId,
      subcategoryIds: List.unmodifiable(subcategoryIds),
      profession: profession.trim(),
      phone: phone.trim(),
      score: previous.score,
      recommendationCount: previous.recommendationCount,
      localRecommendationCount: previous.localRecommendationCount,
      workedResidences: previous.workedResidences,
      reviews: previous.reviews,
      neighborhood: neighborhood.trim(),
      createdBy: previous.createdBy,
      city: previous.city,
    );
    _changes.add(List.unmodifiable(entries));
  }

  Future<void> dispose() => _changes.close();
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
  String? initialLocation = AppRoutes.onboarding,
  String? platformInitialLocation,
  bool useBootstrap = false,
  DateTime? notificationNow,
  bool localhostAuthSimulation = false,
  AuthRepository? authRepository,
  AccountOnboardingRepository? accountRepository,
  ResidenceSetupRepository? residenceSetupRepository,
  ResidenceContextRepository? residenceContextRepository,
  ResidenceMembersRepository? residenceMembersRepository,
  ResidenceDuesRepository? residenceDuesRepository,
  ResidenceFinanceRepository? residenceFinanceRepository,
  ResidenceInvitationRepository? residenceInvitationRepository,
  ResidenceSettingsRepository? residenceSettingsRepository,
  ResidenceDocumentsRepository? residenceDocumentsRepository,
  ResidenceDocumentPicker? residenceDocumentPicker,
  CommunityRepository? communityRepository,
  DirectoryRepository? directoryRepository,
  ServiceCategoriesRepository? serviceCategoriesRepository,
  ServicePhoneLauncher? servicePhoneLauncher,
  DirectoryRecommendationsRepository? directoryRecommendationsRepository,
  ProfileRepository? profileRepository,
  NotificationsRepository? notificationsRepository,
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
  final duesRepository =
      residenceDuesRepository ?? _FakeResidenceDuesRepository();
  final financeRepository =
      residenceFinanceRepository ?? _FakeResidenceFinanceRepository();
  final invitationRepository =
      residenceInvitationRepository ?? _FakeResidenceInvitationRepository();
  final settingsRepository =
      residenceSettingsRepository ?? _FakeResidenceSettingsRepository();
  final documentsRepository =
      residenceDocumentsRepository ?? _FakeResidenceDocumentsRepository();
  final currentCommunityRepository =
      communityRepository ?? MockCommunityRepository();
  final currentDirectoryRepository =
      directoryRepository ?? _TestDirectoryRepository();
  final currentServiceCategoriesRepository =
      serviceCategoriesRepository ?? const _TestServiceCategoriesRepository();
  final currentDirectoryRecommendationsRepository =
      directoryRecommendationsRepository ??
      MockDirectoryRecommendationsRepository();
  final currentProfileRepository =
      profileRepository ?? _FakeProfileRepository();
  final currentNotificationsRepository =
      notificationsRepository ?? MockNotificationsRepository();
  final contextData = residenceContext ?? _defaultResidenceContext;
  if (repository is _FakeAuthRepository) {
    addTearDown(repository.dispose);
  }
  if (currentCommunityRepository is MockCommunityRepository) {
    addTearDown(currentCommunityRepository.dispose);
  }
  if (currentDirectoryRepository is _TestDirectoryRepository) {
    addTearDown(currentDirectoryRepository.dispose);
  }
  if (currentDirectoryRecommendationsRepository
      is MockDirectoryRecommendationsRepository) {
    addTearDown(currentDirectoryRecommendationsRepository.dispose);
  }
  if (currentNotificationsRepository is MockNotificationsRepository) {
    addTearDown(currentNotificationsRepository.dispose);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        localhostAuthSimulationProvider.overrideWithValue(
          localhostAuthSimulation,
        ),
        if (initialLocation != null)
          appInitialLocationProvider.overrideWithValue(initialLocation),
        if (platformInitialLocation != null)
          platformInitialLocationProvider.overrideWithValue(
            platformInitialLocation,
          ),
        notificationPushEnabledProvider.overrideWithValue(false),
        if (notificationNow != null)
          notificationTimeNowProvider.overrideWithValue(notificationNow),
        notificationsRepositoryProvider.overrideWithValue(
          currentNotificationsRepository,
        ),
        accountOnboardingRepositoryProvider.overrideWithValue(
          onboardingRepository,
        ),
        residenceSetupRepositoryProvider.overrideWithValue(setupRepository),
        residenceContextRepositoryProvider.overrideWithValue(contextRepository),
        residenceMembersRepositoryProvider.overrideWithValue(membersRepository),
        residenceDuesRepositoryProvider.overrideWithValue(duesRepository),
        residenceFinanceRepositoryProvider.overrideWithValue(financeRepository),
        residenceInvitationRepositoryProvider.overrideWithValue(
          invitationRepository,
        ),
        residenceSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
        residenceDocumentsRepositoryProvider.overrideWithValue(
          documentsRepository,
        ),
        communityRepositoryProvider.overrideWithValue(
          currentCommunityRepository,
        ),
        directoryRepositoryProvider.overrideWithValue(
          currentDirectoryRepository,
        ),
        serviceCategoriesRepositoryProvider.overrideWithValue(
          currentServiceCategoriesRepository,
        ),
        if (servicePhoneLauncher != null)
          servicePhoneLauncherProvider.overrideWithValue(servicePhoneLauncher),
        directoryRecommendationsRepositoryProvider.overrideWithValue(
          currentDirectoryRecommendationsRepository,
        ),
        if (residenceDocumentPicker != null)
          residenceDocumentPickerProvider.overrideWithValue(
            residenceDocumentPicker,
          ),
        profileRepositoryProvider.overrideWithValue(currentProfileRepository),
        appPackageInfoProvider.overrideWith(
          (ref) async =>
              const AppPackageInfo(version: '0.0.0', buildNumber: '1'),
        ),
        residenceContextProvider.overrideWith((ref) async {
          if (residenceContextError != null) {
            throw residenceContextError;
          }
          return contextData;
        }),
      ],
      child: useBootstrap
          ? DarJarBootstrap(initialize: () async {}, child: const DarJarApp())
          : const DarJarApp(),
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
  final setupBrand = find.byKey(const Key('setup-brand-title'));
  expect(
    find.descendant(of: setupBrand, matching: find.byType(Image)),
    findsOneWidget,
  );
  final setupBrandText = tester.widget<Text>(
    find.descendant(of: setupBrand, matching: find.text('دارجار')),
  );
  expect(setupBrandText.style?.fontFamily, 'Cairo');
  expect(setupBrandText.style?.fontWeight, FontWeight.w800);

  await tester.tap(find.byKey(const Key('create-new-residence-option')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('create-residence-form')), findsOneWidget);
  expect(find.byKey(const Key('residence-name-field')), findsOneWidget);
  expect(find.byKey(const Key('residence-address-field')), findsOneWidget);
  expect(find.byKey(const Key('residence-city-field')), findsOneWidget);
  final cityField = find.byKey(const Key('residence-city-field'));
  final cityInputDecorator = tester.widget<InputDecorator>(
    find.descendant(of: cityField, matching: find.byType(InputDecorator)),
  );
  expect(cityInputDecorator.isEmpty, isFalse);
  final cityLabel = find.descendant(
    of: cityField,
    matching: find.text('المدينة'),
  );
  final cityPlaceholder = find.descendant(
    of: cityField,
    matching: find.text('اختر المدينة'),
  );
  expect(
    tester.getCenter(cityLabel).dy,
    lessThan(tester.getCenter(cityPlaceholder).dy),
  );
  expect(find.text('معلومات الإقامة'), findsOneWidget);
  expect(find.text('معلوماتك'), findsOneWidget);
  expect(find.byKey(const Key('country-code-field')), findsNothing);
  expect(find.byKey(const Key('resident-phone-field')), findsNothing);
  expect(find.byKey(const Key('resident-first-name-field')), findsOneWidget);
  expect(find.byKey(const Key('resident-last-name-field')), findsOneWidget);
  expect(find.text('لا يتم إظهار النسب للسكان الآخرين.'), findsOneWidget);

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
  expect(find.byKey(const Key('city-picker-sheet')), findsOneWidget);
  final cityEmptyState = tester.widget<Container>(
    find.byKey(const Key('city-search-empty-state')),
  );
  expect((cityEmptyState.decoration as BoxDecoration).color, AppColors.surface);
  final cityPickerSize = tester.getSize(
    find.byKey(const Key('city-picker-sheet')),
  );
  expect(
    find.text('اكتب اسم المدينة للبحث، مثال: الدار البيضاء'),
    findsOneWidget,
  );
  final citySearchTextField = tester.widget<TextField>(
    find.descendant(
      of: find.byKey(const Key('city-search-field')),
      matching: find.byType(TextField),
    ),
  );
  expect(citySearchTextField.decoration?.labelText, isNull);
  expect(
    citySearchTextField.decoration?.hintText,
    'اكتب اسم المدينة للبحث، مثال: الدار البيضاء',
  );
  expect(citySearchTextField.decoration?.hintMaxLines, 1);
  expect(find.byKey(const ValueKey('city-option-6141010')), findsNothing);
  await tester.enterText(
    find.byKey(const Key('city-search-field')),
    'الدار البيضاء',
  );
  await tester.pumpAndSettle();
  expect(
    tester.getSize(find.byKey(const Key('city-picker-sheet'))),
    cityPickerSize,
  );
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
  _FakeAuthRepository({bool signedIn = true, this.sendFailure})
    : _currentUser = signedIn
          ? const AuthUser(uid: 'test-user', phoneNumber: '+212600000001')
          : null;

  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast(sync: true);
  AuthUser? _currentUser;
  String? requestedPhoneNumber;
  String? requestedLanguageCode;
  String? confirmedCode;
  int sendVerificationCodeCallCount = 0;
  final AuthFailure? sendFailure;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> sendVerificationCode(
    String phoneNumber, {
    required String languageCode,
  }) async {
    sendVerificationCodeCallCount++;
    requestedPhoneNumber = phoneNumber;
    requestedLanguageCode = languageCode;
    final failure = sendFailure;
    if (failure != null) {
      throw failure;
    }
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
  String? requestedApartmentId;

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
    required String apartmentId,
  }) async {
    requestedResidence = residence;
    requestedApartmentId = apartmentId;
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
  bool? lastIncludeInvitations;

  @override
  Future<ResidenceMembersData> load(
    String residenceId, {
    bool includeInvitations = true,
  }) async {
    loadCount += 1;
    lastIncludeInvitations = includeInvitations;
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
  Future<void> deleteInvitation({
    required String residenceId,
    required String invitationId,
  }) async {
    data = ResidenceMembersData(
      buildings: data.buildings,
      members: data.members,
      pendingInvitations: data.pendingInvitations
          .where((invitation) => invitation.id != invitationId)
          .toList(growable: false),
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
    required ResidenceDuesTrackingStatus duesTrackingStatus,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
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
                        duesTrackingStatus: duesTrackingStatus,
                        duesTrackingStartPeriodKey: currentPeriodKey,
                        openingPaidThroughPeriodKey:
                            openingPaidThroughPeriodKey ?? '',
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
  Future<void> startApartmentDuesTracking({
    required String residenceId,
    required ResidenceApartment apartment,
    required String? openingPaidThroughPeriodKey,
    required String currentPeriodKey,
    required int defaultAmount,
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
                    for (final item in floor.apartments)
                      item.id == apartment.id
                          ? ResidenceApartment(
                              id: item.id,
                              number: item.number,
                              floorId: item.floorId,
                              buildingId: item.buildingId,
                              createdAt: item.createdAt,
                              duesTrackingStatus:
                                  ResidenceDuesTrackingStatus.active,
                              duesTrackingStartPeriodKey: currentPeriodKey,
                              openingPaidThroughPeriodKey:
                                  openingPaidThroughPeriodKey ?? '',
                            )
                          : item,
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

class _FakeResidenceFinanceRepository implements ResidenceFinanceRepository {
  _FakeResidenceFinanceRepository() {
    final now = DateTime.now();
    transactions = [
      ResidenceTransaction(
        id: 'dues-july',
        type: ResidenceTransactionType.income,
        amount: 150,
        date: DateTime(now.year, now.month, 5),
        name: '',
        source: ResidenceTransactionSource.dues,
        apartmentNumber: '01',
        periodKey: residenceDuesPeriodKey(now),
        periodEndKey: residenceDuesPeriodKey(DateTime(now.year, now.month + 3)),
        recordedBy: 'test-user',
      ),
      ResidenceTransaction(
        id: 'elevator-service-july',
        type: ResidenceTransactionType.expense,
        amount: 80,
        date: DateTime(now.year, now.month, 4),
        name: 'صيانة المصعد',
        source: ResidenceTransactionSource.manual,
        expenseCategory: ResidenceExpenseCategory.maintenance,
        note: 'تمت صيانة محرك المصعد',
        supportingDocument: 'فاتورة-صيانة.pdf',
        attachmentStoragePath:
            'residences/test-residence/attachments/finance-elevator-service-july/content',
        attachmentContentType: 'application/pdf',
        attachmentSizeBytes: 2048,
        recordedBy: 'test-user',
      ),
      ResidenceTransaction(
        id: 'other-income',
        type: ResidenceTransactionType.income,
        amount: 50,
        date: DateTime(now.year, now.month, 3),
        name: 'كراء السطح',
        source: ResidenceTransactionSource.manual,
        recordedBy: 'test-user',
      ),
    ];
  }

  late List<ResidenceTransaction> transactions;
  var _nextId = 1;

  @override
  Future<ResidenceFinances> load(String residenceId) async {
    return ResidenceFinances.fromTransactions(
      transactions: transactions,
      paidResidents: 1,
      totalResidents: 7,
    );
  }

  @override
  Future<void> addManualTransaction({
    required String residenceId,
    required ResidenceFinanceInput input,
    required String recordedBy,
  }) async {
    transactions = [
      ...transactions,
      _transactionFromInput(
        id: 'manual-${_nextId++}',
        input: input,
        recordedBy: recordedBy,
      ),
    ];
  }

  @override
  Future<void> setOpeningBalance({
    required String residenceId,
    required int amount,
    required DateTime date,
    required String recordedBy,
  }) async {
    transactions = [
      for (final transaction in transactions)
        if (!transaction.isOpeningBalance) transaction,
      ResidenceTransaction(
        id: 'opening-balance',
        type: ResidenceTransactionType.income,
        amount: amount,
        date: date,
        name: 'openingBalance',
        source: ResidenceTransactionSource.openingBalance,
        recordedBy: recordedBy,
      ),
    ];
  }

  @override
  Future<void> updateManualTransaction({
    required String residenceId,
    required String transactionId,
    required ResidenceFinanceInput input,
  }) async {
    transactions = [
      for (final transaction in transactions)
        if (transaction.id == transactionId)
          _transactionFromInput(
            id: transactionId,
            input: input,
            recordedBy: transaction.recordedBy,
          )
        else
          transaction,
    ];
  }

  @override
  Future<void> deleteManualTransaction({
    required String residenceId,
    required String transactionId,
  }) async {
    transactions = [
      for (final transaction in transactions)
        if (transaction.id != transactionId) transaction,
    ];
  }

  ResidenceTransaction _transactionFromInput({
    required String id,
    required ResidenceFinanceInput input,
    required String recordedBy,
  }) {
    return ResidenceTransaction(
      id: id,
      type: input.type,
      amount: input.amount,
      date: input.date,
      name: input.name.trim(),
      source: ResidenceTransactionSource.manual,
      expenseCategory: input.expenseCategory,
      note: input.note.trim(),
      supportingDocument: input.attachmentUpload == null
          ? input.supportingDocument.trim()
          : residenceTransactionAttachmentName(id),
      attachmentStoragePath: input.attachmentUpload == null
          ? ''
          : 'residences/test-residence/attachments/finance-$id/content',
      attachmentContentType: input.attachmentUpload?.contentType ?? '',
      attachmentSizeBytes: input.attachmentUpload?.bytes.lengthInBytes ?? 0,
      recordedBy: recordedBy,
    );
  }
}

class _FakeResidenceDuesRepository implements ResidenceDuesRepository {
  _FakeResidenceDuesRepository() {
    final periodKey = residenceDuesPeriodKey(DateTime.now());
    overview = ResidenceDuesOverview(
      dues: [
        ResidenceDue(
          id: '${periodKey}_apartment-01',
          apartmentId: 'apartment-01',
          apartmentNumber: '01',
          periodKey: periodKey,
          amountDue: 150,
          amountPaid: 0,
          status: ResidenceDueStatus.unpaid,
        ),
        ResidenceDue(
          id: '${periodKey}_apartment-02',
          apartmentId: 'apartment-02',
          apartmentNumber: '02',
          periodKey: periodKey,
          amountDue: 150,
          amountPaid: 150,
          status: ResidenceDueStatus.paid,
        ),
      ],
      payments: [
        ResidenceDuePayment(
          id: 'payment-apartment-02',
          dueId: '${periodKey}_apartment-02',
          apartmentId: 'apartment-02',
          apartmentNumber: '02',
          amount: 150,
          paidAt: DateTime.now(),
          note: '',
          recordedBy: 'test-user',
        ),
      ],
    );
  }

  late ResidenceDuesOverview overview;

  @override
  Future<void> ensurePeriod({
    required String residenceId,
    required String periodKey,
    required int defaultAmount,
    required List<ResidenceApartment> apartments,
  }) async {
    final existingApartmentIds = {
      for (final due in overview.dues)
        if (due.periodKey == periodKey) due.apartmentId,
    };
    overview = ResidenceDuesOverview(
      dues: [
        ...overview.dues,
        for (final apartment in apartments)
          if (!existingApartmentIds.contains(apartment.id))
            ResidenceDue(
              id: '${periodKey}_${apartment.id}',
              apartmentId: apartment.id,
              apartmentNumber: apartment.number,
              periodKey: periodKey,
              amountDue: defaultAmount,
              amountPaid: 0,
              status: ResidenceDueStatus.unpaid,
            ),
      ],
      payments: overview.payments,
    );
  }

  @override
  Future<ResidenceDuesOverview> load({
    required String residenceId,
    String? apartmentId,
  }) async {
    if (apartmentId == null) return overview;
    return ResidenceDuesOverview(
      dues: overview.dues
          .where((due) => due.apartmentId == apartmentId)
          .toList(),
      payments: overview.payments
          .where((payment) => payment.apartmentId == apartmentId)
          .toList(),
    );
  }

  @override
  Future<void> recordApartmentPayment({
    required String residenceId,
    required String apartmentId,
    required String apartmentNumber,
    required int amount,
    required int defaultAmount,
    required String currentPeriodKey,
    required DateTime paidAt,
    required String note,
    required String recordedBy,
    String supportingDocument = '',
    ResidenceDocumentUpload? attachmentUpload,
  }) async {
    final apartmentDues =
        overview.dues.where((due) => due.apartmentId == apartmentId).toList()
          ..sort(
            (first, second) => first.periodKey.compareTo(second.periodKey),
          );
    final remaining = apartmentDues.fold(
      0,
      (total, due) => total + due.remainingAmount,
    );
    final advanceAmount = amount > remaining ? amount - remaining : 0;
    if (advanceAmount > 0 &&
        (defaultAmount == 0 || advanceAmount % defaultAmount != 0)) {
      throw const ResidenceDuesFailure('invalid-advance-amount');
    }
    var lastPeriod = currentPeriodKey;
    for (final due in apartmentDues) {
      if (due.periodKey.compareTo(lastPeriod) > 0) lastPeriod = due.periodKey;
    }
    var futurePeriod = _testPeriodDate(lastPeriod);
    final futureDues = <ResidenceDue>[];
    for (
      var index = 0;
      index < (defaultAmount == 0 ? 0 : advanceAmount ~/ defaultAmount);
      index++
    ) {
      futurePeriod = DateTime(futurePeriod.year, futurePeriod.month + 1);
      final periodKey = residenceDuesPeriodKey(futurePeriod);
      futureDues.add(
        ResidenceDue(
          id: '${periodKey}_$apartmentId',
          apartmentId: apartmentId,
          apartmentNumber: apartmentNumber,
          periodKey: periodKey,
          amountDue: defaultAmount,
          amountPaid: 0,
          status: ResidenceDueStatus.unpaid,
        ),
      );
    }
    var unallocated = amount;
    final updatedById = <String, ResidenceDue>{};
    final payments = <ResidenceDuePayment>[];
    final paymentGroupId = 'payment-group-${overview.payments.length + 1}';
    for (final due in [
      ...apartmentDues.where((due) => due.remainingAmount > 0),
      ...futureDues,
    ]) {
      if (unallocated == 0) break;
      final allocated = unallocated < due.remainingAmount
          ? unallocated
          : due.remainingAmount;
      updatedById[due.id] = due.copyWithPayment(allocated);
      payments.add(
        ResidenceDuePayment(
          id: 'payment-${overview.payments.length + payments.length + 1}',
          dueId: due.id,
          apartmentId: apartmentId,
          apartmentNumber: apartmentNumber,
          amount: allocated,
          paidAt: paidAt,
          note: note,
          recordedBy: recordedBy,
          paymentGroupId: paymentGroupId,
          supportingDocument: attachmentUpload == null
              ? supportingDocument
              : residenceTransactionAttachmentName(paymentGroupId),
          attachmentStoragePath: attachmentUpload == null
              ? ''
              : 'residences/$residenceId/attachments/dues-$paymentGroupId/content',
          attachmentContentType: attachmentUpload?.contentType ?? '',
          attachmentSizeBytes: attachmentUpload?.bytes.lengthInBytes ?? 0,
        ),
      );
      unallocated -= allocated;
    }
    if (unallocated != 0) {
      throw const ResidenceDuesFailure('invalid-payment-amount');
    }
    overview = ResidenceDuesOverview(
      dues: [
        for (final item in overview.dues) updatedById[item.id] ?? item,
        for (final due in futureDues) updatedById[due.id]!,
      ],
      payments: [...payments.reversed, ...overview.payments],
    );
  }
}

DateTime _testPeriodDate(String periodKey) {
  final parts = periodKey.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
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

class _FakeResidenceDocumentsRepository
    implements ResidenceDocumentsRepository {
  _FakeResidenceDocumentsRepository({
    List<ResidenceDocument>? initialDocuments,
    this.uploadBarrier,
  }) : documents =
           initialDocuments ??
           [
             ResidenceDocument(
               id: 'rules',
               title: 'القانون الداخلي',
               originalFileName: 'rules.pdf',
               storagePath: 'residences/test-residence/documents/rules/content',
               contentType: 'application/pdf',
               sizeBytes: 2048,
               uploadedBy: 'test-user',
               createdAt: DateTime(2026, 7, 20),
               updatedAt: DateTime(2026, 7, 20),
             ),
             ResidenceDocument(
               id: 'meeting',
               title: 'محضر الاجتماع',
               originalFileName: 'meeting.png',
               storagePath:
                   'residences/test-residence/documents/meeting/content',
               contentType: 'image/png',
               sizeBytes: 4096,
               uploadedBy: 'test-user',
               createdAt: DateTime(2026, 7, 18),
               updatedAt: DateTime(2026, 7, 18),
             ),
           ];

  final List<ResidenceDocument> documents;
  final Completer<void>? uploadBarrier;
  final _changes = StreamController<List<ResidenceDocument>>.broadcast();

  @override
  Stream<List<ResidenceDocument>> watch(String residenceId) async* {
    yield List.unmodifiable(documents);
    yield* _changes.stream;
  }

  @override
  Future<List<ResidenceTransactionAttachment>> loadAttachments(
    String residenceId,
  ) async {
    final date = DateTime(2026, 7, 19);
    final id = 'elevator-service-july';
    final title = residenceTransactionAttachmentName(id);
    return [
      ResidenceTransactionAttachment(
        id: 'finance-$id',
        isIncome: false,
        date: date,
        document: ResidenceDocument(
          id: 'attachment-$id',
          title: title,
          originalFileName: title,
          storagePath:
              'residences/$residenceId/attachments/finance-$id/content',
          contentType: 'application/pdf',
          sizeBytes: 2048,
          uploadedBy: 'test-user',
          createdAt: date,
          updatedAt: date,
        ),
      ),
    ];
  }

  @override
  Future<void> upload({
    required String residenceId,
    required String uploadedBy,
    required ResidenceDocumentUpload upload,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    await uploadBarrier?.future;
    documents.insert(
      0,
      ResidenceDocument(
        id: 'uploaded-${documents.length + 1}',
        title: upload.title,
        originalFileName: upload.originalFileName,
        storagePath:
            'residences/$residenceId/documents/uploaded-${documents.length + 1}/content',
        contentType: upload.contentType,
        sizeBytes: upload.bytes.lengthInBytes,
        uploadedBy: uploadedBy,
        createdAt: DateTime(2026, 7, 29),
        updatedAt: DateTime(2026, 7, 29),
      ),
    );
    onProgress?.call(1);
    _emit();
  }

  @override
  Future<void> updateTitle({
    required String residenceId,
    required String documentId,
    required String title,
  }) async {
    final index = documents.indexWhere((document) => document.id == documentId);
    final document = documents[index];
    documents[index] = ResidenceDocument(
      id: document.id,
      title: title,
      originalFileName: document.originalFileName,
      storagePath: document.storagePath,
      contentType: document.contentType,
      sizeBytes: document.sizeBytes,
      uploadedBy: document.uploadedBy,
      createdAt: document.createdAt,
      updatedAt: DateTime(2026, 7, 29),
    );
    _emit();
  }

  @override
  Future<void> delete({
    required String residenceId,
    required ResidenceDocument document,
  }) async {
    documents.removeWhere((item) => item.id == document.id);
    _emit();
  }

  @override
  Future<Uint8List> download(ResidenceDocument document) async =>
      Uint8List.fromList([1, 2, 3]);

  void _emit() => _changes.add(List.unmodifiable(documents));
}
