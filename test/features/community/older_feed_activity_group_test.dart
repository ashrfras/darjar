import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/data/feed_repository.dart';
import 'package:darjar/features/community/domain/feed_activity_group.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:darjar/features/community/presentation/collapsible_feed_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 29, 12);

void main() {
  test('seven old expenses retain the first event and six hidden events', () {
    final items = List.generate(7, (i) => _activity('expense-$i'));
    final groups = groupOlderFeedActivities(items, now: _now);

    expect(groups, hasLength(1));
    expect(groups.single, orderedEquals(items));
  });

  test('posts and different event types always break consecutive runs', () {
    final post = PostFeedItem(communityWelcomePost);
    final items = <FeedItem>[
      _activity('expense-1'),
      post,
      _activity('expense-2'),
      _activity('due-1', type: ResidenceActivityType.duePaid),
      _activity('due-2', type: ResidenceActivityType.duePaid),
      _activity('expense-3'),
      post,
    ];

    final groups = groupOlderFeedActivities(items, now: _now);

    expect(groups.map((group) => group.length), [1, 1, 1, 2, 1, 1]);
    expect(groups[1].single, same(post));
    expect(groups.last.single, same(post));
  });

  test('only events strictly older than 30 days can be collapsed', () {
    final cutoff = _now.subtract(const Duration(days: 30));
    final items = [
      _activity('recent-1', occurredAt: _now),
      _activity('recent-2', occurredAt: _now),
      _activity('boundary', occurredAt: cutoff),
      _activity(
        'old-1',
        occurredAt: cutoff.subtract(const Duration(seconds: 1)),
      ),
      _activity('old-2'),
      _activity('unknown', unknownDate: true),
      _activity('old-3'),
    ];

    expect(
      groupOlderFeedActivities(items, now: _now).map((group) => group.length),
      [1, 1, 1, 2, 1, 1],
    );
  });

  test(
    'old dues keep apartment ranges before similar events are collapsed',
    () {
      final old = DateTime.now().subtract(const Duration(days: 45));
      final dues = [
        _activity(
          'due-1',
          type: ResidenceActivityType.duePaid,
          occurredAt: old,
        ),
        _activity(
          'due-2',
          type: ResidenceActivityType.duePaid,
          occurredAt: old,
        ),
        _activity(
          'other-due-1',
          type: ResidenceActivityType.duePaid,
          occurredAt: old,
          apartment: '17',
        ),
        _activity(
          'other-due-2',
          type: ResidenceActivityType.duePaid,
          occurredAt: old,
          apartment: '17',
        ),
      ];
      final combined = combineFeedStates(
        const AsyncData(<CommunityPost>[]),
        AsyncData(dues),
      );

      final activities = combined.requireValue.cast<ResidenceActivity>();
      expect(activities, hasLength(2));
      expect(activities.map((activity) => activity.descriptionAr), [
        'تم تسجيل أداء اشتراك 2026-05 إلى 2026-06 للشقة 16',
        'تم تسجيل أداء اشتراك 2026-05 إلى 2026-06 للشقة 17',
      ]);
      final groups = groupOlderFeedActivities(activities, now: DateTime.now());
      expect(groups, hasLength(1));
      expect(groups.single, orderedEquals(activities));
    },
  );

  testWidgets(
    'revealed events are marked and stay open until the page is recreated',
    (tester) async {
      final items = List.generate(7, (i) => _activity('expense-$i'));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CollapsibleFeedGroup(
              items: items,
              itemBuilder: (item) => Text(item.id),
            ),
          ),
        ),
      );

      expect(find.text('expense-0'), findsOneWidget);
      expect(find.text('expense-1'), findsNothing);
      expect(find.text('عرض 6 أنشطة مشابهة'), findsOneWidget);
      expect(
        tester
            .getCenter(find.widgetWithText(TextButton, 'عرض 6 أنشطة مشابهة'))
            .dx,
        tester.getCenter(find.byType(CollapsibleFeedGroup)).dx,
      );
      await tester.tap(find.text('عرض 6 أنشطة مشابهة'));
      await tester.pump();
      for (final item in items) {
        expect(find.text(item.id), findsOneWidget);
      }
      final revealed = find.byKey(const Key('revealed-similar-activities'));
      expect(find.text('أنشطة مشابهة'), findsOneWidget);
      expect(find.text('عرض 6 أنشطة مشابهة'), findsNothing);
      expect(find.text('إخفاء الأنشطة المشابهة'), findsNothing);
      expect(
        find.descendant(of: revealed, matching: find.text('expense-0')),
        findsNothing,
      );
      for (final item in items.skip(1)) {
        expect(
          find.descendant(of: revealed, matching: find.text(item.id)),
          findsOneWidget,
        );
      }

      // Routine rebuilds preserve the reveal; recreating the page resets it.
      tester.element(find.byType(CollapsibleFeedGroup)).markNeedsBuild();
      await tester.pump();
      expect(find.text('expense-1'), findsOneWidget);
      final page = tester.widget<MaterialApp>(find.byType(MaterialApp));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page);
      expect(find.text('expense-1'), findsNothing);
      expect(find.text('عرض 6 أنشطة مشابهة'), findsOneWidget);
    },
  );

  for (final count in [1, 2, 3]) {
    testWidgets('$count old events collapse only from three onwards', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CollapsibleFeedGroup(
              items: List.generate(
                count,
                (index) => _activity(
                  'due-$index',
                  type: ResidenceActivityType.duePaid,
                ),
              ),
              itemBuilder: (item) => Text(item.id),
            ),
          ),
        ),
      );
      expect(find.text('due-0'), findsOneWidget);
      if (count < 3) {
        for (var index = 1; index < count; index++) {
          expect(find.text('due-$index'), findsOneWidget);
        }
        expect(find.byType(TextButton), findsNothing);
        expect(find.text('أنشطة مشابهة'), findsNothing);
      } else {
        expect(find.text('due-1'), findsNothing);
        expect(find.text('due-2'), findsNothing);
        await tester.tap(find.text('عرض نشاطين مشابهين'));
        await tester.pump();
        expect(find.text('due-1'), findsOneWidget);
        expect(find.text('due-2'), findsOneWidget);
        expect(find.text('أنشطة مشابهة'), findsOneWidget);
      }
    });
  }
}

ResidenceActivity _activity(
  String id, {
  ResidenceActivityType type = ResidenceActivityType.expenseAdded,
  DateTime? occurredAt,
  bool unknownDate = false,
  String apartment = '16',
}) => ResidenceActivity(
  id: id,
  activityType: type,
  category: FeedCategory.finance,
  descriptionAr: id,
  descriptionEn: id,
  descriptionZgh: id,
  timeLabelAr: '',
  timeLabelEn: '',
  timeLabelZgh: '',
  likes: 0,
  apartmentNumber: apartment,
  periodKey: id.endsWith('1') ? '2026-06' : '2026-05',
  occurredAt: unknownDate
      ? null
      : occurredAt ?? _now.subtract(const Duration(days: 45)),
);
