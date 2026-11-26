import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the edit window ends fifteen minutes after the first publish', () {
    final createdAt = DateTime.utc(2026, 11, 26);
    final deadline = createdAt.add(const Duration(minutes: 15));
    expect(
      isCommunityPostEditOpen(
        createdAt,
        deadline.subtract(const Duration(microseconds: 1)),
      ),
      isTrue,
    );
    expect(isCommunityPostEditOpen(createdAt, deadline), isFalse);
    expect(isCommunityPostEditOpen(null, createdAt), isFalse);
  });

  test(
    'only the creator can edit a mock post and the timestamp is kept',
    () async {
      final repository = MockCommunityRepository();
      addTearDown(repository.dispose);
      final postId = await repository.createPost(
        userId: 'author',
        content: 'Original',
        kind: CommunityPostKind.poll,
        pollOptions: ['Yes', 'No'],
      );
      final original = repository.getPost(postId)!;
      await expectLater(
        repository.editPost(
          residenceId: 'mock-residence',
          userId: 'neighbor',
          postId: postId,
          content: 'Unauthorized',
        ),
        throwsA(
          isA<CommunityFailure>().having(
            (error) => error.code,
            'code',
            'post-edit-forbidden',
          ),
        ),
      );
      await repository.editPost(
        residenceId: 'mock-residence',
        userId: 'author',
        postId: postId,
        content: ' Updated ',
      );
      final updated = repository.getPost(postId)!;
      expect(updated.content, 'Updated');
      expect(updated.createdAt, original.createdAt);
      expect(updated.pollOptions, original.pollOptions);
    },
  );

  for (final scenario in ['author', 'expired author', 'manager']) {
    testWidgets('post menu and edit behavior for $scenario', (tester) async {
      final isAuthor = scenario != 'manager';
      final expired = scenario == 'expired author';
      final saved = <String>[];
      final post = CommunityPost(
        id: 'post',
        author: 'أحمد',
        timeLabel: '',
        content: 'النص الأول',
        kind: CommunityPostKind.general,
        likes: 0,
        comments: const [],
        isCurrentUser: isAuthor,
        createdAt: DateTime.now().subtract(Duration(minutes: expired ? 16 : 1)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            residenceDirectoryProvider.overrideWith(
              (ref) async => ResidenceMembersData.empty,
            ),
            communityActionsProvider.overrideWith(
              (ref) => _RecordingCommunityActions(ref, saved),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CommunityPostCard(
                post: post,
                onOpen: () {},
                onLike: () async {},
                onSave: () async {},
                onVote: (_) {},
                onReport: (_) async {},
                onArchive: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('post-menu-post')));
      await tester.pumpAndSettle();

      final edit = find.text('تعديل المنشور');
      final delete = find.text('حذف المنشور');
      expect(delete, findsOneWidget);
      if (!isAuthor) {
        expect(edit, findsNothing);
        return;
      }
      expect(tester.getCenter(edit).dy, lessThan(tester.getCenter(delete).dy));
      final context = tester.element(edit);
      expect(
        tester.widget<Text>(edit).style?.color,
        expired ? Theme.of(context).disabledColor : null,
      );
      await tester.tap(edit);
      await tester.pumpAndSettle();
      if (expired) {
        expect(
          find.text('يمكن تعديل المنشور فقط خلال أول 15 دقيقة من نشره.'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
        expect(saved, isEmpty);
        return;
      }
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).controller?.text, 'النص الأول');
      await tester.enterText(field, 'النص المعدّل');
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();
      expect(saved, ['النص المعدّل']);
      expect(field, findsNothing);
    });
  }
}

class _RecordingCommunityActions extends CommunityActions {
  _RecordingCommunityActions(super.ref, this.saved);

  final List<String> saved;

  @override
  Future<void> editPost(String postId, String content) async {
    expect(postId, 'post');
    saved.add(content);
  }
}
