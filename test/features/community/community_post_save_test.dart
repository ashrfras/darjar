import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _post = CommunityPost(
  id: 'neighbor-post',
  author: 'جار',
  timeLabel: '',
  content: 'منشور للاختبار',
  kind: CommunityPostKind.general,
  likes: 0,
  comments: [],
);

void main() {
  for (final initiallySaved in [false, true]) {
    for (final updateBeforeCompletion in [false, true]) {
      testWidgets(
        'save waits for request and state: saved=$initiallySaved, updateFirst=$updateBeforeCompletion',
        (tester) async {
          final pending = Completer<void>();
          var calls = 0;
          Future<void> save() {
            calls++;
            return pending.future;
          }

          await _pumpButton(
            tester,
            _post.copyWith(isSaved: initiallySaved),
            save,
          );
          final button = find.byKey(const ValueKey('save-neighbor-post'));
          final sizeBefore = tester.getSize(button);
          expect(
            find.byIcon(
              initiallySaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
            findsOneWidget,
          );
          final onPressed = tester.widget<IconButton>(button).onPressed!;
          onPressed();
          onPressed();
          await tester.pump();
          expect(calls, 1);
          expect(tester.widget<IconButton>(button).onPressed, isNull);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(tester.getSize(button), sizeBefore);
          final progress = tester.widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          );
          expect(progress.strokeWidth, 2);
          expect(progress.semanticsLabel, 'جارٍ الحفظ…');

          if (updateBeforeCompletion) {
            await _pumpButton(
              tester,
              _post.copyWith(isSaved: !initiallySaved),
              save,
            );
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
            pending.complete();
          } else {
            pending.complete();
            await tester.pump();
            // Even after the request ends, a stale snapshot must keep loading.
            await _pumpButton(
              tester,
              _post.copyWith(isSaved: initiallySaved),
              save,
            );
            await tester.pump(const Duration(seconds: 1));
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
            expect(tester.widget<IconButton>(button).onPressed, isNull);
            expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
            expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
            await _pumpButton(
              tester,
              _post.copyWith(isSaved: !initiallySaved),
              save,
            );
          }
          await tester.pumpAndSettle();
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(tester.widget<IconButton>(button).onPressed, isNotNull);
          expect(
            tester.widget<IconButton>(button).color,
            initiallySaved ? AppColors.inkMuted : AppColors.primary,
          );
          expect(
            find.byIcon(
              initiallySaved
                  ? Icons.bookmark_border_rounded
                  : Icons.bookmark_rounded,
            ),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('save failure stops loading and allows retry', (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await _pumpButton(tester, _post, () async {
      calls++;
      if (calls == 1) await pending.future;
    });
    final button = find.byKey(const ValueKey('save-neighbor-post'));
    await tester.tap(button);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(const CommunityFailure('save-failed'));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تنفيذ الإجراء.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(tester.widget<IconButton>(button).color, AppColors.inkMuted);
    expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('finishing a save after leaving the page is safe', (
    tester,
  ) async {
    final pending = Completer<void>();
    await _pumpButton(tester, _post, () => pending.future);
    await tester.tap(find.byKey(const ValueKey('save-neighbor-post')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpButton(
  WidgetTester tester,
  CommunityPost post,
  Future<void> Function() onSave,
) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CommunityPostSaveButton(post: post, onSave: onSave),
    ),
  ),
);
