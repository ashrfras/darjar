import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_like_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final compact in [false, true]) {
    for (final initiallyLiked in [false, true]) {
      testWidgets('optimistic toggle: compact=$compact, liked=$initiallyLiked', (
        tester,
      ) async {
        final pending = Completer<void>();
        var calls = 0;
        Future<void> toggle() {
          calls++;
          return pending.future;
        }

        await _pump(
          tester,
          liked: initiallyLiked,
          compact: compact,
          onLike: toggle,
        );
        final button = find.byType(TextButton);
        final onPressed = tester.widget<TextButton>(button).onPressed!;
        onPressed();
        onPressed();
        await tester.pump();
        final expectedCount = initiallyLiked ? 11 : 13;
        expect(calls, 1);
        expect(find.text('$expectedCount'), findsOneWidget);
        expect(
          find.byIcon(
            initiallyLiked ? Icons.thumb_up_outlined : Icons.thumb_up_rounded,
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester.widget<TextButton>(button).style!.foregroundColor!.resolve({}),
          initiallyLiked ? AppColors.inkMuted : AppColors.danger,
        );
        await tester.pump(const Duration(milliseconds: 250));
        final transforms = tester.widgetList<Transform>(find.byType(Transform));
        expect(
          transforms.any((item) => item.transform.storage[0] > 1.2),
          !initiallyLiked,
        );
        // A completed write with a stale stream must not undo the instant result.
        pending.complete();
        await tester.pumpAndSettle();
        await _pump(
          tester,
          liked: initiallyLiked,
          compact: compact,
          onLike: toggle,
        );
        expect(find.text('$expectedCount'), findsOneWidget);
        await tester.tap(button);
        expect(calls, 1);
        await _pump(
          tester,
          liked: !initiallyLiked,
          likes: expectedCount,
          compact: compact,
          onLike: toggle,
        );
        await tester.pumpAndSettle();
        // No double increment when the stream confirms the optimistic count.
        expect(find.text('$expectedCount'), findsOneWidget);
        expect(
          tester
              .widgetList<Transform>(find.byType(Transform))
              .every((item) => item.transform.storage[0] <= 1),
          isTrue,
        );
      });
    }
  }

  for (final earlySnapshot in [false, true]) {
    testWidgets(
      'failure rolls back count and color, earlySnapshot=$earlySnapshot',
      (tester) async {
        final pending = Completer<void>();
        var calls = 0;
        Future<void> toggle() {
          calls++;
          return pending.future;
        }

        await _pump(tester, onLike: toggle);
        await tester.tap(find.byType(TextButton));
        await tester.pump();
        expect(find.text('13'), findsOneWidget);
        if (earlySnapshot) {
          await _pump(tester, liked: true, likes: 13, onLike: toggle);
        }
        pending.completeError(const CommunityFailure('like-failed'));
        await tester.pumpAndSettle();
        expect(find.text('12'), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
        expect(find.text('تعذّر تنفيذ الإجراء.'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.byType(TextButton))
              .style!
              .foregroundColor!
              .resolve({}),
          AppColors.inkMuted,
        );
        await _pump(tester, onLike: toggle);
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();
        expect(calls, 2);
        expect(find.text('12'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'stream confirmation before request completion keeps count stable',
    (tester) async {
      final pending = Completer<void>();
      await _pump(tester, onLike: () => pending.future);
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      await _pump(tester, liked: true, likes: 13, onLike: () => pending.future);
      expect(find.text('13'), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('13'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);
    },
  );

  testWidgets('reduced motion still updates likes immediately', (tester) async {
    final pending = Completer<void>();
    await _pump(tester, reducedMotion: true, onLike: () => pending.future);
    await tester.tap(find.byType(TextButton));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('13'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('community-like-scale')))
          .transform
          .storage[0],
      1,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving while animation and request run safely disposes both', (
    tester,
  ) async {
    final pending = Completer<void>();
    await _pump(tester, onLike: () => pending.future);
    await tester.tap(find.byType(TextButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.completeError(const CommunityFailure('like-failed'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  bool liked = false,
  int likes = 12,
  bool compact = false,
  bool reducedMotion = false,
  required Future<void> Function() onLike,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Scaffold(
        body: Center(
          child: CommunityLikeButton(
            isLiked: liked,
            likes: likes,
            compact: compact,
            onLike: onLike,
          ),
        ),
      ),
    ),
  ),
);
