import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in ['ar', 'en', 'zgh']) {
    testWidgets('legacy post types display as posts in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        Localizations(
          locale: Locale(locale),
          delegates: const [
            AppLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);
              for (final kind in CommunityPostKind.values) {
                final isPoll = kind == CommunityPostKind.poll;
                final isEvent = kind == CommunityPostKind.event;
                expect(
                  kind.label(context),
                  isPoll
                      ? localizations.postKindPoll
                      : isEvent
                      ? localizations.postKindEvent
                      : localizations.postKindGeneral,
                );
                if (!isPoll && !isEvent) {
                  expect(kind.icon, CommunityPostKind.general.icon);
                  expect(kind.color, CommunityPostKind.general.color);
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  }

  test('legacy posts use the posts feed category', () {
    final repository = MockCommunityRepository();
    addTearDown(repository.dispose);
    for (final post in repository.getPosts()) {
      expect(
        PostFeedItem(post).category,
        post.kind == CommunityPostKind.poll
            ? FeedCategory.polls
            : FeedCategory.posts,
      );
    }
  });
}
